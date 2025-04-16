from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from json import dumps, load, loads
from sys import argv
from os import path, system
from typing import Any

script_dir = path.dirname(argv[0])

class Settings:
    def __init__(self) -> None:
        if not path.exists(argv[-1]):
            data = {
                "roomId":1,
                "extraPackages":[],
                "restart":False
            }
        else:
            with open(argv[-1], "r") as file:
                data:dict[str, Any] = load(file)
        self.roomId:int = data["roomId"]
        self.extraPackages:list[str] = data["extraPackages"]
        self.restart:bool = data["restart"]

    def save(self, fp = None):
        if fp is None:
            with open(argv[-1], "w") as file:
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
    system(f"{script_dir}/rebuild.sh")

def restart():
    system("reboot")

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
