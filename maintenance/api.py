from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write("ok".encode())
        pass
    def do_POST(self):
        match self.path:
            case "/save":
                pass
            case "/rebuild":
                pass
            case "/restart":
                pass

if __name__ == "__main__":
    try:
        server = ThreadingHTTPServer(("0.0.0.0", 8080), Handler)
        server.serve_forever()
    except:
        print("exiting...")
