from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from json import dumps, load, loads
from sys import argv
from os import O_NONBLOCK, path, system
from typing import IO, Any
from subprocess import Popen, PIPE
from fcntl import F_GETFL, F_SETFL, fcntl
from threading import Lock

script_dir:str = path.dirname(argv[0])

processes: list[Popen] = []
output_log_lock: Lock = Lock()
output_log: list[str] = []


def run_process(command: str):
    global processes
    processes.append(Popen(command, shell=True, stderr=PIPE))


def read(output: IO) -> str:
    fd: int = output.fileno()
    fl: int = fcntl(fd, F_GETFL)
    fcntl(fd, F_SETFL, fl | O_NONBLOCK)

    text: bytes | None = output.read()
    if text is None:
        return ""
    return text.decode()


def read_process() -> str:
    toBeRemoved: list[Popen] = []
    output: str = ""
    for process in processes:
        if process.poll() is not None:
            toBeRemoved.append(process)
        else:
            if process.stderr is not None:
                output += read(process.stderr)
            if process.stdout is not None:
                output += read(process.stdout)
    if output_log_lock.acquire(blocking=False):  # Don't acquire if its locked
        output_log_lock.locked_lock()
        output += "\n".join(output_log)
        output_log.clear()
    output_log_lock.release()

    for process in toBeRemoved:
        processes.remove(process)
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

def rebuild():
    system(f"systemctl start update.service")


def restart():
    system("reboot")


def switch_to_terminal():
    kill_list: list[str] = ["firefox", "qsudo", "alacritty"]
    for kill_target in kill_list:
        system(f"pkill -15 {kill_target}")
    system("alacritty")


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
            case "/terminal":
                self.send_response(200)
                self.end_headers()
                switch_to_terminal()
            case "/stdout":
                self.send_response(200)
                self.end_headers()
                output = read_process()
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
                rebuild()

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
