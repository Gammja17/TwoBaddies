"""첫 화면 배경: 달밤의 산자락 별장. 위층 손님방 창에만 불이 켜져 있다.

    python tools/title_art.py
"""
import os
import random
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import chars  # noqa: E402

ROOT = os.path.dirname(HERE)
W, H = 480, 270


def hexc(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def main():
    random.seed(7)
    img = Image.new("RGBA", (W, H), hexc("#0e0d1c"))
    d = ImageDraw.Draw(img)
    # 하늘: 띠 모양 그러데이션
    bands = ["#0e0d1c", "#121127", "#16152f", "#1b1937", "#211d3f", "#272247"]
    for i, c in enumerate(bands):
        d.rectangle((0, i * 30, W, i * 30 + 30), fill=hexc(c))
    # 별: 드문드문
    stars = []
    while len(stars) < 22:
        x, y = random.randrange(8, W - 8), random.randrange(6, 120)
        if all(abs(x - a) + abs(y - b) > 30 for a, b in stars) and not (176 < x < 252 and 14 < y < 70):
            stars.append((x, y))
    for x, y in stars:
        d.point((x, y), fill=hexc("#c9c4e0") if random.random() < 0.7 else hexc("#8f8ab0"))
    # 달
    cx, cy, r = 214, 40, 15
    for yy in range(cy - r - 4, cy + r + 5):
        for xx in range(cx - r - 4, cx + r + 5):
            dd = ((xx - cx) ** 2 + (yy - cy) ** 2) ** 0.5
            if dd <= r:
                img.putpixel((xx, yy), hexc("#efe6c4") if dd < r - 1 else hexc("#d8cfab"))
            elif dd <= r + 3:
                img.putpixel((xx, yy), hexc("#2c2750"))
    d.rectangle((cx + 3, cy - 6, cx + 6, cy - 3), fill=hexc("#ddd3ad"))
    d.rectangle((cx - 7, cy + 4, cx - 4, cy + 6), fill=hexc("#ddd3ad"))
    # 먼 산 두 겹
    for layer, (col, base, amp) in enumerate([("#1d1b36", 150, 26), ("#17162c", 172, 18)]):
        pts = []
        h = base
        for x in range(0, W + 8, 8):
            h += random.randint(-6, 6)
            h = max(base - amp, min(base + amp // 2, h))
            pts.append((x, h))
        poly = [(0, H)] + pts + [(W, H)]
        d.polygon(poly, fill=hexc(col))
    # 땅
    d.rectangle((0, 214, W, H), fill=hexc("#1c2a22"))
    d.rectangle((0, 214, W, 215), fill=hexc("#253629"))
    # 별장 (오른쪽)
    hx0, hx1, top2, top1, ground = 262, 452, 128, 170, 222
    wall, wall_d, wall_l = hexc("#b9ab8e"), hexc("#8f8470"), hexc("#d3c6a8")
    roof, roof_d = hexc("#6e4b3a"), hexc("#4e3428")
    # 몸체 2층
    d.rectangle((hx0, top2, hx1, ground), fill=wall)
    d.rectangle((hx0, top2, hx0 + 1, ground), fill=wall_l)
    d.rectangle((hx1 - 1, top2, hx1, ground), fill=wall_d)
    d.rectangle((hx0, top1 - 2, hx1, top1), fill=wall_d)       # 층 사이 띠
    # 지붕 (박공)
    peak = (hx0 + hx1) // 2
    d.polygon([(hx0 - 10, top2), (peak, top2 - 44), (hx1 + 10, top2)], fill=roof)
    for k in range(0, 44, 6):
        d.line([(hx0 - 10 + k * 2, top2 - k // 3), (hx1 + 10 - k * 2, top2 - k // 3)], fill=roof_d)
    d.polygon([(hx0 - 10, top2), (peak, top2 - 44), (hx1 + 10, top2)], outline=hexc("#3a261d"))
    # 굴뚝
    d.rectangle((hx1 - 40, top2 - 40, hx1 - 30, top2 - 18), fill=hexc("#8a5a44"))
    d.rectangle((hx1 - 42, top2 - 42, hx1 - 28, top2 - 39), fill=hexc("#5e3c2e"))

    def window(x, y, lit=False, shutter=False):
        d.rectangle((x - 1, y - 1, x + 14, y + 17), fill=hexc("#6e4f32"))
        if shutter:
            d.rectangle((x, y, x + 13, y + 16), fill=hexc("#6a6a72"))
            for yy in range(y + 1, y + 16, 3):
                d.line([(x, yy), (x + 13, yy)], fill=hexc("#8a8a92"))
            return
        d.rectangle((x, y, x + 13, y + 16), fill=hexc("#f0c870") if lit else hexc("#1e2438"))
        d.line([(x + 6, y), (x + 6, y + 16)], fill=hexc("#6e4f32"))
        d.line([(x, y + 8), (x + 13, y + 8)], fill=hexc("#6e4f32"))
        if lit:
            d.rectangle((x + 1, y + 1, x + 5, y + 7), fill=hexc("#fbe2a0"))
    # 2층 창: 손님방만 불이 켜져 있다 (셔터가 내려오기 전의 한순간)
    for i, x in enumerate(range(hx0 + 16, hx1 - 10, 34)):
        window(x, top2 + 14, lit=(i == 0), shutter=(i > 0))
    # 1층 창과 현관 (철제 셔터)
    for x in (hx0 + 16, hx0 + 50, hx1 - 64, hx1 - 30):
        window(x, top1 + 12, shutter=True)
    door_x = peak - 12
    d.rectangle((door_x - 2, top1 + 6, door_x + 25, ground), fill=hexc("#6e4f32"))
    d.rectangle((door_x, top1 + 8, door_x + 23, ground), fill=hexc("#6a6a72"))
    for yy in range(top1 + 9, ground, 3):
        d.line([(door_x, yy), (door_x + 23, yy)], fill=hexc("#8a8a92"))
    # 빨간 경보등
    d.rectangle((door_x + 28, top1 + 10, door_x + 30, top1 + 12), fill=hexc("#ff4a3a"))
    d.point((door_x + 29, top1 + 9), fill=hexc("#ff9a8a"))
    # 계단과 길
    d.rectangle((door_x - 6, ground, door_x + 29, ground + 3), fill=hexc("#8f8470"))
    d.polygon([(door_x - 4, ground + 4), (door_x + 27, ground + 4), (door_x + 44, H), (door_x - 20, H)], fill=hexc("#4a3c2c"))
    # 나무와 울타리
    def tree(x, y, s=1.0):
        d.rectangle((x - 2, y - 6, x + 1, y), fill=hexc("#3e2c20"))
        for k, col in enumerate(["#1f3a2a", "#244430", "#2b5037"]):
            hh = int((30 - k * 8) * s)
            d.polygon([(x - int((14 - k * 3) * s), y - 6 - k * 8), (x, y - 6 - k * 8 - hh), (x + int((14 - k * 3) * s), y - 6 - k * 8)], fill=hexc(col))
    tree(248, 222, 1.2)
    tree(466, 222, 1.0)
    tree(214, 226, 0.8)
    # 울타리: 한 덩어리로 (작은 동그라미를 줄지어 놓지 않는다)
    for x0, x1 in ((180, door_x - 16), (door_x + 42, W)):
        d.rounded_rectangle((x0, 227, x1, 239), 5, fill=hexc("#243d2c"), outline=hexc("#1a2c20"))
        d.line([(x0 + 4, 229), (x1 - 4, 229)], fill=hexc("#2d4a36"))
    # 앞마당의 도둑 (울타리 뒤에서 몸을 숙이고)
    thief = chars.render(chars.CAST["thief"], "right", 1)
    img.alpha_composite(thief, (206, 214))
    # 전체를 살짝 어둡게, 아래쪽은 더 어둡게 (글씨 읽기 좋게)
    shade = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    for y in range(H):
        a = int(max(0, (y - 150) / 120) * 90)
        sd.line([(0, y), (W, y)], fill=(8, 6, 14, a))
    img.alpha_composite(shade)
    out = os.path.join(ROOT, "assets", "art", "title_bg.png")
    img.save(out)
    print(out)


if __name__ == "__main__":
    main()
