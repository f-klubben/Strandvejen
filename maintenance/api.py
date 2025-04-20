from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from json import dumps, load, loads
from sys import argv
from os import O_NONBLOCK, environ, path, system
from typing import IO, Any
from subprocess import Popen, PIPE
from fcntl import F_GETFL, F_SETFL, fcntl
from threading import Lock

script_dir: str = path.dirname(argv[0])
maintenance_file: str = environ["MAINTENANCE_FILE"]

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
        data: dict[str, Any]
        if not path.exists(maintenance_file):
            data = {"room_id": 1, "extra_packages": [], "should_restart": False}
        else:
            with open(maintenance_file, "r") as file:
                data = load(file)
        self.room_id: int = data["room_id"]
        self.extra_packages: list[str] = data["extra_packages"]
        self.should_restart: bool = data["should_restart"]

    def save(self, fp=None):
        if fp is None:
            with open(maintenance_file, "w") as file:
                file.write(
                    dumps(
                        {
                            "room_id": self.room_id,
                            "extra_packages": self.extra_packages,
                            "should_restart": self.should_restart,
                        }
                    )
                )
        else:
            fp.write(
                dumps(
                    {
                        "room_id": self.room_id,
                        "extra_packages": self.extra_packages,
                        "should_restart": self.should_restart,
                    }
                ).encode()
            )


settings: Settings = Settings()


def rebuild():
    run_process(f"{script_dir}/rebuild.sh")


def restart():
    run_process("reboot")


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
                if "room_id" in data:
                    settings.room_id = data["room_id"]
                if "extra_packages" in data:
                    settings.extra_packages = data["extra_packages"]
                if "should_restart" in data:
                    settings.should_restart = data["should_restart"]
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
