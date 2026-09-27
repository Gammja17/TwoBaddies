"""웹 빌드 미리보기 서버. builds/web 을 띄우고, 디버그 빌드가 보내는 화면 캡처를 저장한다.

    python tools/serve.py <port> <캡처 저장 폴더>
게임 디버그 빌드에서 window.gdShot('이름') 을 부르면 <폴더>/이름.png 로 저장된다.
"""
import base64
import http.server
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "builds", "web")
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 18760
SHOTS = sys.argv[2] if len(sys.argv) > 2 else "shots"


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=ROOT, **kw)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_POST(self):
        if not self.path.startswith("/shot/"):
            self.send_error(404)
            return
        name = os.path.basename(self.path[6:]) or "shot"
        n = int(self.headers.get("Content-Length", 0))
        data = self.rfile.read(n)
        os.makedirs(SHOTS, exist_ok=True)
        with open(os.path.join(SHOTS, name + ".png"), "wb") as f:
            f.write(base64.b64decode(data))
        self.send_response(200)
        self.end_headers()

    def log_message(self, *a):
        pass


http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
