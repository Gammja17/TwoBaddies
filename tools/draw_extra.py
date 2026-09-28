"""VARCO 로 못 뽑은 작은 그림을 가구 색에 맞춰 직접 찍는다 (art_src/ 에 둔다).

    python tools/draw_extra.py
"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art_src")

# 작은 탁자 그림에서 뽑은 나무 색
LINE = (43, 26, 12, 255)
DARK = (72, 40, 20, 255)
MID = (147, 85, 35, 255)
LIGHT = (164, 99, 43, 255)
HI = (186, 124, 62, 255)


def rect(p, x0, y0, x1, y1, col):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            p[x, y] = col


def box(p, x0, y0, x1, y1, top, face):
    """윤곽선이 있는 나무 판: 윗면(밝게)과 앞면."""
    rect(p, x0, y0, x1, y1, LINE)
    rect(p, x0 + 1, y0 + 1, x1 - 1, y0 + 1 + top, HI)
    rect(p, x0 + 1, y0 + 2 + top, x1 - 1, y1 - 1, face)


def stool(w, h, s):
    """두 칸짜리 나무 발판. s: 크기 배율 (32px 칸은 1, 아이콘은 0.75)."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    p = img.load()

    def S(v):
        return int(round(v * s))
    ox = (w - S(24)) // 2
    oy = h - S(26)
    # 다리 넷
    for lx in (2, 19):
        rect(p, ox + S(lx), oy + S(10), ox + S(lx) + S(3), oy + S(25), LINE)
        rect(p, ox + S(lx) + 1, oy + S(11), ox + S(lx) + S(3) - 1, oy + S(24), DARK)
    # 뒤 칸 (높은 칸)
    box(p, ox + S(4), oy, ox + S(20), oy + S(8), max(1, S(2)), MID)
    # 앞 칸 (낮은 칸)
    box(p, ox, oy + S(12), ox + S(24), oy + S(20), max(1, S(2)), LIGHT)
    # 앞 칸 앞면의 나뭇결 한 줄
    rect(p, ox + S(3), oy + S(17), ox + S(21), oy + S(17), MID)
    return img


def main():
    os.makedirs(os.path.join(SRC, "props"), exist_ok=True)
    os.makedirs(os.path.join(SRC, "icons"), exist_ok=True)
    stool(32, 32, 1.0).save(os.path.join(SRC, "props", "stool.png"))
    stool(24, 24, 0.75).save(os.path.join(SRC, "icons", "stool.png"))
    print("stool ok")


if __name__ == "__main__":
    main()
