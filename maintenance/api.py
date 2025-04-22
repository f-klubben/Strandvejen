from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from json import dumps, load, loads
from sys import argv
from os import path, system
from typing import Any
from threading import Lock
from datetime import datetime
from subprocess import check_output

script_dir: str = path.dirname(argv[0])

services: list[str] = ["rebuild.service", "refresh.service", "update.service"]
last_read: datetime = datetime.now()
output_log_lock: Lock = Lock()
output_log: list[str] = []


def read_services() -> str:
    global last_read
    output = ""
    timestamp = last_read.strftime("%Y-%m-%d %H:%M:%S")
    for service in services:
        output += (
            check_output(["journalctl", "-u", service, "--since", timestamp]).decode().replace("-- No entries --\n", "")
        )
    last_read = datetime.now()

    if output_log_lock.acquire(blocking=False):  # Don't acquire if its locked
        output_log_lock.locked_lock()
        output += "\n".join(output_log)
        output_log.clear()
    output_log_lock.release()

    return output


class Settings:
    def __init__(self) -> None:
        self.data: dict[str, Any]
        with open("/var/maintenance/settings.json", "r") as file:
            self.data = load(file)

    def save(self, fp=None):
        if fp is None:
            with open("/var/maintenance/settings.json", "w") as file:
                file.write(dumps(self.data))
        else:
            fp.write(dumps(self.data).encode())


settings: Settings = Settings()


def start(service: str):
    system(f"systemctl start {service}.service")


def restart():
    system("reboot")

class Handler(BaseHTTPRequestHandler):
    def get_data(self) -> dict[str, Any]:
        data_size: int = int(self.headers.get("Content-Length", 0))
        data: str = self.rfile.read(data_size).decode()
        if not data == "":
            return loads(data)
        else:
            return {}

    def do_GET(self) -> None:
        match self.path:
            case "/settings":
                self.send_response(200)
                self.end_headers()
                settings.save(self.wfile)
            case "/stdout":
                self.send_response(200)
                self.end_headers()
                output: str = read_services()
                self.wfile.write(output.encode())
            case _:
                with open(f"{script_dir}/frontend/index.html", "rb") as file:
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(file.read())

    def do_POST(self) -> None:
        match self.path:
            case "/save":
                data: dict[str, Any] = self.get_data()
                for key in data:
                    settings.data[key] = data[key]
                settings.save()
                with output_log_lock:
                    output_log.append("Successfully wrote maintenance file\n")
            case "/rebuild":
                start("rebuild")
            case "/update":
                start("update")
            case "/refresh":
                start("refresh")
            case "/terminal":
                start("terminal")

            case "/restart":
                restart()
            case _:
                self.send_response(404)
                self.end_headers()
                return
        self.send_response(200)
        self.end_headers()


if __name__ == "__main__":
    try:
        server = ThreadingHTTPServer(("0.0.0.0", 8080), Handler)
        server.serve_forever()
    except:
        print("exiting...")
