"""헤드리스 크롬으로 웹 빌드를 굴려 화면을 찍는다 (창이 뜨지 않는다).

    python tools/webdrive.py <plan.json>

plan.json 은 명령 목록이다.
  ["goto", url]           페이지 열기
  ["wait", 초]
  ["key", "z"]            키 한 번 (z, x, c, Enter, Escape, ArrowUp ...)
  ["keys", "ArrowUp", 5]  같은 키 여러 번 (한 번에 한 칸씩)
  ["hold", "ArrowRight", 초]
  ["js", "코드"]          페이지에서 자바스크립트 실행 (결과를 찍는다)
  ["cmd", "명령"]         디버그 빌드의 window.gdCmd(명령)
  ["shot", "파일.png"]    화면 찍기
  ["tap", x, y]           터치 한 번 (CSS 픽셀)
  ["click", x, y]         마우스 누르기 한 번 (CSS 픽셀)
  ["text", "글자"]        입력기가 확정해 넣은 글자처럼 넣기
  ["compose", ["ㄱ", "가"]]  한글 조합을 보여 주다가 마지막 글자로 확정
창 크기는 WD_SIZE="너비,높이" (기본 960,540), 터치 화면은 WD_TOUCH=1.
"""
import asyncio
import base64
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request

import websockets

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"


def free_port():
    """다른 프로그램이 쓰지 않는 포트 (다른 세션의 크롬에 붙지 않도록 매번 새로 고른다)."""
    import socket
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


PORT = free_port()
KEYS = {
    "ArrowUp": ("ArrowUp", "ArrowUp", 38), "ArrowDown": ("ArrowDown", "ArrowDown", 40),
    "ArrowLeft": ("ArrowLeft", "ArrowLeft", 37), "ArrowRight": ("ArrowRight", "ArrowRight", 39),
    "Enter": ("Enter", "Enter", 13), "Escape": ("Escape", "Escape", 27), "Shift": ("Shift", "ShiftLeft", 16),
    "Tab": ("Tab", "Tab", 9), "Space": (" ", "Space", 32),
}


def key_info(k):
    if k in KEYS:
        return KEYS[k]
    if len(k) == 1 and k.isalpha():
        return (k, "Key" + k.upper(), ord(k.upper()))
    if len(k) == 1 and k.isdigit():
        return (k, "Digit" + k, ord(k))
    raise ValueError(k)


class CDP:
    def __init__(self, ws):
        self.ws = ws
        self.n = 0

    async def call(self, method, **params):
        self.n += 1
        mid = self.n
        await self.ws.send(json.dumps({"id": mid, "method": method, "params": params}))
        while True:
            msg = json.loads(await self.ws.recv())
            if msg.get("id") == mid:
                if "error" in msg:
                    raise RuntimeError(msg["error"])
                return msg.get("result", {})


async def key(cdp, k, down=True, up=True):
    kk, code, vk = key_info(k)
    text = kk if len(kk) == 1 else ""
    if down:
        await cdp.call("Input.dispatchKeyEvent", type="keyDown", key=kk, code=code,
                       windowsVirtualKeyCode=vk, nativeVirtualKeyCode=vk, text=text)
    if up:
        await asyncio.sleep(0.07)
        await cdp.call("Input.dispatchKeyEvent", type="keyUp", key=kk, code=code,
                       windowsVirtualKeyCode=vk, nativeVirtualKeyCode=vk)


async def run(plan, out_dir):
    ws_url = None
    for _ in range(50):
        try:
            tabs = json.load(urllib.request.urlopen("http://127.0.0.1:%d/json" % PORT))
            # 방금 띄운 크롬은 about:blank 한 장만 열려 있다
            pages = [t for t in tabs if t.get("type") == "page" and t.get("url") == "about:blank"]
            if pages:
                ws_url = pages[0]["webSocketDebuggerUrl"]
                break
        except Exception:
            pass
        time.sleep(0.2)
    if ws_url is None:
        raise RuntimeError("띄운 크롬을 찾지 못했다 (port %d)" % PORT)
    async with websockets.connect(ws_url, max_size=50_000_000, ping_interval=None) as ws:
        cdp = CDP(ws)
        await cdp.call("Page.enable")
        await cdp.call("Runtime.enable")
        for step in plan:
            op = step[0]
            if op == "goto":
                await cdp.call("Page.navigate", url=step[1])
            elif op == "wait":
                await asyncio.sleep(step[1])
            elif op == "key":
                await key(cdp, step[1])
                await asyncio.sleep(0.12)
            elif op == "keys":
                for _ in range(step[2]):
                    await key(cdp, step[1])
                    await asyncio.sleep(step[3] if len(step) > 3 else 0.28)
            elif op == "hold":
                await key(cdp, step[1], up=False)
                await asyncio.sleep(step[2])
                await key(cdp, step[1], down=False)
            elif op in ("js", "cmd"):
                expr = step[1] if op == "js" else "window.gdCmd(%s)" % json.dumps(step[1])
                r = await cdp.call("Runtime.evaluate", expression=expr, awaitPromise=True, returnByValue=True)
                val = r.get("result", {}).get("value")
                if op == "js":
                    print("js:", val)
                await asyncio.sleep(0.15)
            elif op == "tap":
                for t in ("touchStart", "touchEnd"):
                    pts = [{"x": step[1], "y": step[2]}] if t == "touchStart" else []
                    await cdp.call("Input.dispatchTouchEvent", type=t, touchPoints=pts)
                    await asyncio.sleep(0.08)
            elif op == "click":
                for t in ("mousePressed", "mouseReleased"):
                    await cdp.call("Input.dispatchMouseEvent", type=t, x=step[1], y=step[2], button="left", clickCount=1)
                    await asyncio.sleep(0.08)
            elif op == "text":
                # 입력기가 글자를 확정해 넣은 것처럼 (한글 시험용)
                await cdp.call("Input.insertText", text=step[1])
                await asyncio.sleep(0.2)
            elif op == "compose":
                # 한글 조합 중인 글자를 보여 주다가 확정한다
                for part in step[1]:
                    await cdp.call("Input.imeSetComposition", text=part, selectionStart=len(part), selectionEnd=len(part))
                    await asyncio.sleep(0.12)
                await cdp.call("Input.insertText", text=step[1][-1])
                await asyncio.sleep(0.2)
            elif op == "shot":
                r = await cdp.call("Page.captureScreenshot", format="png")
                path = os.path.join(out_dir, step[1])
                with open(path, "wb") as f:
                    f.write(base64.b64decode(r["data"]))
                print("shot:", path)
        # 콘솔 오류를 모아 보여 준다
        r = await cdp.call("Runtime.evaluate", expression="(window.__errs||[]).join('\\n')", returnByValue=True)
        errs = r.get("result", {}).get("value")
        if errs:
            print("page errors:\n" + errs)


def main():
    plan = json.load(open(sys.argv[1], encoding="utf-8"))
    out_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.dirname(os.path.abspath(sys.argv[1]))
    size = os.environ.get("WD_SIZE", "960,540")
    touch = os.environ.get("WD_TOUCH", "") == "1"
    profile = tempfile.mkdtemp(prefix="wd_")
    args = [CHROME, "--headless=new", "--remote-debugging-port=%d" % PORT, "--user-data-dir=" + profile,
            "--window-size=" + size, "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
            "--autoplay-policy=no-user-gesture-required", "--mute-audio", "--no-first-run",
            "--disable-background-timer-throttling", "--disable-renderer-backgrounding", "about:blank"]
    if touch:
        args.insert(1, "--touch-events=enabled")
    proc = subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        asyncio.run(run(plan, out_dir))
    finally:
        proc.terminate()
        try:
            proc.wait(5)
        except Exception:
            proc.kill()
        shutil.rmtree(profile, ignore_errors=True)


if __name__ == "__main__":
    main()
