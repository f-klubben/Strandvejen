from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from json import dumps, load, loads
from sys import argv
from os import O_NONBLOCK, environ, path, system
from typing import IO, Any
from subprocess import Popen, PIPE
from fcntl import F_GETFL, F_SETFL, fcntl
from threading import Lock

script_dir = path.dirname(argv[0])
maintenance_file = environ["MAINTENANCE_FILE"]

processes:list[Popen] = []
output_log_lock = Lock() 
output_log = []

def runProcess(command:str):
    global process
    processes.append(Popen(command, shell=True, stderr=PIPE))

def read(output:IO) -> str:
    fd = output.fileno()
    fl = fcntl(fd, F_GETFL)
    fcntl(fd, F_SETFL, fl | O_NONBLOCK)
    try:
        text = output.read()
        if text is None:
            return ""
        return text.decode()
    except:
        return ""

def readProcess() -> str:
    toBeRemoved:list[Popen] = []
    output = ""
    for process in processes:
        if process.poll() is not None:
            toBeRemoved.append(process)
        else:
            if process.stderr is not None:
                output += read(process.stderr)
            if process.stdout is not None:
                output += read(process.stdout)
    if output_log_lock.acquire(blocking=False): # Don't acquire if its locked
        output_log_lock.locked_lock()
        output += "\n".join(output_log)
        output_log.clear()
    output_log_lock.release()

    for process in toBeRemoved:
        processes.remove(process)
    return output

class Settings:
    def __init__(self) -> None:
        if not path.exists(maintenance_file):
            data = {
                "roomId":1,
                "extraPackages":[],
                "restart":False
            }
        else:
            with open(maintenance_file, "r") as file:
                data:dict[str, Any] = load(file)
        self.roomId:int = data["roomId"]
        self.extraPackages:list[str] = data["extraPackages"]
        self.restart:bool = data["restart"]

    def save(self, fp = None):
        if fp is None:
            with open(maintenance_file, "w") as file:
                file.write(dumps({
                    "roomId":self.roomId,
                    "extraPackages":self.extraPackages,
                    "restart":self.restart
                }))
        else:
            fp.write(dumps({
                "roomId":self.roomId,
                "extraPackages":self.extraPackages,
                "restart":self.restart
            }).encode())

settings = Settings()

def rebuild():
    runProcess(f"{script_dir}/rebuild.sh")

def restart():
    runProcess("reboot")

def switchToTerminal():
    killList = [
        "firefox",
        "qsudo",
        "alacritty"
    ]
    for killTarget in killList:
        system(f"pkill -15 {killTarget}")
    system("alacritty")

class Handler(BaseHTTPRequestHandler):
    def getData(self) -> dict[str, Any]:
        dataSize:int = int(self.headers.get("Content-Length", 0))
        data = self.rfile.read(dataSize).decode()
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
                switchToTerminal()
            case "/stdout":
                self.send_response(200)
                self.end_headers()
                output = readProcess()
                self.wfile.write(output.encode())
            case _:
                with open(f"{script_dir}/frontend/index.html", "rb") as file:
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(file.read())

    def do_POST(self) -> None:
        match self.path:
            case "/save":
                data = self.getData()
                if "roomId" in data:
                    settings.roomId = data["roomId"]
                if "extraPackages" in data:
                    settings.extraPackages = data["extraPackages"]
                if "restart" in data:
                    settings.restart = data["restart"]
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
