"""16x24 픽셀 인물 그리기 (Kenney 로그라이크 색감에 맞춘 4방향, 걸음 3칸).

부위(다리, 몸통, 팔, 머리, 머리칼, 모자, 얼굴 장식)를 겹쳐 그린 뒤
바깥 테두리를 자동으로 두른다. build_art.py 가 가져다 쓴다.
"""
from PIL import Image

W, H = 16, 24
DIRS = ["down", "left", "right", "up"]
OUTLINE = (34, 28, 36, 255)


def hexc(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


def stamp(px, rows, x0, y0, flip=False):
    """rows 의 글자를 px[(x, y)] 에 찍는다. '.' 은 건너뛴다."""
    for dy, row in enumerate(rows):
        n = len(row)
        for dx, ch in enumerate(row):
            if ch == ".":
                continue
            x = x0 + (n - 1 - dx if flip else dx)
            px[(x, y0 + dy)] = ch


# ---------------------------------------------------------------- 부위 ----
# 좌표는 16x24 칸 기준. 발바닥이 y=21, 머리 꼭대기가 y=3 근처.

HEAD_FRONT = [
    ".SSSSSS.",
    "SSSSSSSS",
    "SSSSSSSS",
    "SSSSSSSS",
    "SSESSESS",
    "SSSSSSSS",
    "sSSSSSSs",
    ".ssssss.",
]
HEAD_BACK = [
    ".SSSSSS.",
    "SSSSSSSS",
    "SSSSSSSS",
    "SSSSSSSS",
    "SSSSSSSS",
    "SSSSSSSS",
    "sSSSSSSs",
    ".ssssss.",
]
HEAD_SIDE = [  # 왼쪽을 본다
    ".SSSSSS.",
    "SSSSSSSS",
    "SSSSSSSS",
    "SSSSSSSS",
    "SESSSSSS",
    "SSSSSSSS",
    "sSSSSSSs",
    ".ssssss.",
]

TORSO = {
    "slim": {
        "front": [".TTUUTT.", "TTTTTTTT", "TTTTTTTT", "TTTTTTTT", "tttttttt"],
        "back": [".TTTTTT.", "TTTTTTTT", "TTTTTTTT", "TTTTTTTT", "tttttttt"],
        "side": [".TTTT.", "TTTTTT", "TTTTTT", "TTTTTT", "tttttt"],
    },
    "hoodie": {  # 캥거루 주머니가 있는 후드
        "front": [".TTUUTT.", "TTTTTTTT", "TTttttTT", "TTTTTTTT", "tttttttt"],
        "back": [".TTTTTT.", "TTTTTTTT", "TTTTTTTT", "TTTTTTTT", "tttttttt"],
        "side": [".TTTT.", "TTTTTT", "TTTTTT", "TtTTTT", "tttttt"],
    },
    "badge": {  # 경찰 제복 (가슴 배지)
        "front": [".TTTTTT.", "TTTTTTTT", "TTTTTUTT", "TTTTTTTT", "tttttttt"],
        "back": [".TTTTTT.", "TTTTTTTT", "TTTTTTTT", "TTTTTTTT", "tttttttt"],
        "side": [".TTTT.", "TTTTTT", "TTTTTT", "TTTTTT", "tttttt"],
    },
    "big": {  # 앞이 벌어진 점퍼 속으로 검은 티셔츠
        "front": [".TTUUUUTT.", "TTTUUUUTTT", "TTTTUUTTTT", "TTTTUUTTTT", "tttttttttt"],
        "back": [".TTTTTTTT.", "TTTTTTTTTT", "TTTTTTTTTT", "TTTTTTTTTT", "tttttttttt"],
        "side": [".TTTTT.", "TTTTTTT", "TTTTTTT", "TTTTTTT", "ttttttt"],
    },
}


def body_layout(build):
    if build == "big":
        return {"tx": 3, "tw": 10, "arm_l": 2, "arm_r": 13, "leg": (4, 6, 9, 11), "stx": 5}
    return {"tx": 4, "tw": 8, "arm_l": 3, "arm_r": 12, "leg": (5, 6, 9, 10), "stx": 5}


def draw_legs(px, d, phase, build):
    """phase: 0 선 자세, 1 왼발 앞, 2 오른발 앞."""
    L = body_layout(build)
    l0, l1, r0, r1 = L["leg"]
    if d in ("down", "up"):
        for x in range(l0, r1 + 1):
            px[(x, 18)] = "P"
        lf = 21 if phase != 2 else 20  # 발 높이
        rf = 21 if phase != 1 else 20
        for x in range(l0, l1 + 1):
            for y in range(19, lf):
                px[(x, y)] = "p" if (y == lf - 1 and x == l1) else "P"
            px[(x, lf)] = "B"
        for x in range(r0, r1 + 1):
            for y in range(19, rf):
                px[(x, y)] = "p" if (y == rf - 1 and x == r0) else "P"
            px[(x, rf)] = "B"
        return
    # 옆모습 (왼쪽을 본다; 오른쪽은 나중에 뒤집는다)
    cx = 6 if build != "big" else 5
    w = 4 if build != "big" else 5
    if phase == 0:
        for y in (18, 19, 20):
            for x in range(cx, cx + w):
                px[(x, y)] = "P" if x < cx + w - 1 else "p"
        for x in range(cx - 1, cx + w - 1):
            px[(x, 21)] = "B"
        return
    # 걸음: 앞발(왼쪽)과 뒷발(오른쪽)이 벌어진다. phase 에 따라 어느 발이 앞인지 색만 바꾼다.
    for x in range(cx, cx + w):
        px[(x, 18)] = "P"
    front = [(cx - 1, 19), (cx - 1, 20), (cx - 2, 20)]
    back = [(cx + w - 1, 19), (cx + w, 20)]
    mid = [(cx, 19), (cx + 1, 19)] if w == 4 else [(cx, 19), (cx + 1, 19), (cx + 2, 19)]
    for p in mid:
        px[p] = "P"
    for p in front:
        px[p] = "P" if phase == 1 else "p"
    for p in back:
        px[p] = "p" if phase == 1 else "P"
    px[(cx - 2, 21)] = "B"
    px[(cx - 3, 21)] = "B"
    px[(cx - 1, 21)] = "B"
    px[(cx + w, 21)] = "B"
    px[(cx + w + 1, 21)] = "B"


def draw_torso(px, d, phase, build, style):
    L = body_layout(build)
    if d == "down":
        stamp(px, TORSO[style]["front"], L["tx"], 13)
    elif d == "up":
        stamp(px, TORSO[style]["back"], L["tx"], 13)
    else:
        stamp(px, TORSO[style]["side"], L["stx"], 13)
    # 팔
    if d in ("down", "up"):
        for side, ax in (("l", L["arm_l"]), ("r", L["arm_r"])):
            lift = (phase == 1 and side == "l") or (phase == 2 and side == "r")
            top, hand = (13, 16) if lift else (14, 17)
            for y in range(top, hand):
                px[(ax, y)] = "T" if y < hand - 1 else "t"
            px[(ax, hand)] = "S"
    else:
        # 옆모습: 가까운 팔이 몸통 가운데에 겹친다. 걸을 때 앞뒤로 흔든다.
        base = L["stx"] + (2 if build != "big" else 3)
        off = {0: 0, 1: -1, 2: 1}[phase]
        ax = base + off
        for y in (14, 15, 16):
            px[(ax, y)] = "t"
            px[(ax + 1, y)] = "T"
        hx = ax - 1 if phase == 1 else (ax + 1 if phase == 2 else ax)
        px[(hx, 17)] = "S"
        px[(hx + 1, 17)] = "S"


def draw_head(px, d, face):
    rows = {"down": HEAD_FRONT, "up": HEAD_BACK}.get(d, HEAD_SIDE)
    stamp(px, rows, 4, 5)
    if d in ("left", "right"):
        px[(3, 9)] = "S"  # 코
    if d == "down" and face.get("mouth"):
        px[(7, 11)] = "M"
        px[(8, 11)] = "M"


# 머리 모양: 방향별 칸들
HAIR = {
    "short": {
        "down": ["..HHHH..", ".HHHHHH.", "HHHHHHHH", "HhHHHHhH", "H......H", "h......h"],
        "up": ["..HHHH..", ".HHHHHH.", "HHHHHHHH", "HHHHHHHH", "HHHHHHHH", "HHHHHHHH", "hHHHHHHh", "shhhhhhs"],
        "side": ["..HHHHH.", ".HHHHHHH", "HHHHHHHH", "HHHhHHHH", "H...HHHH", "....HHHH", ".....HHh", ".....hh."],
    },
    "buzz": {
        "down": ["..hhhh..", ".hHHHHh.", "hHHHHHHh", "h......h"],
        "up": ["..hhhh..", ".hHHHHh.", "hHHHHHHh", "hHHHHHHh", "hhHHHHhh", ".hhhhhh."],
        "side": ["..hhhhh.", ".hHHHHHh", "hHHHHHHh", "....hHHh", ".....hhh"],
    },
    "bald_sides": {  # 할아버지: 정수리는 맨살, 옆머리만
        "down": ["........", "........", "H......H", "H......H", "h......h"],
        "up": ["........", "........", "HHHHHHHH", "HHHHHHHH", "HHHHHHHH", "hHHHHHHh"],
        "side": ["........", "........", "....HHHH", "....HHHH", ".....HHh", ".....hh."],
    },
    "bun": {  # 할머니: 쪽진 머리
        "down": ["...HH...", "..HHHH..", ".HHHHHH.", "HHHHHHHH", "HhHHHHhH", "H......H", "h......h"],
        "up": ["..HHHH..", "..HhhH..", ".HHHHHH.", "HHHHHHHH", "HHHHHHHH", "HHHHHHHH", "HHHHHHHH", "hHHHHHHh"],
        "side": ["......HH", ".....HHh", ".HHHHHHH", "HHHHHHHH", "H...HHHH", "....HHHH", ".....HHh", ".....hh."],
    },
}

HATS = {
    "beanie": {  # 도둑의 비니
        "down": ["..CCCC..", ".CCCCCC.", "CCCCCCCC", "CCCCCCCC", "cccccccc"],
        "up": ["..CCCC..", ".CCCCCC.", "CCCCCCCC", "CCCCCCCC", "cccccccc"],
        "side": ["..CCCCC.", ".CCCCCCC", "CCCCCCCC", "CCCCCCCC", "cccccccc"],
    },
    "police": {  # 경찰 모자 (챙)
        "down": [".CCCCCC.", "CCCCCCCC", "CCCUUCCC", "cccccccc", ".EEEEEE."],
        "up": [".CCCCCC.", "CCCCCCCC", "CCCCCCCC", "cccccccc"],
        "side": [".CCCCCC.", "CCCCCCCC", "CCCCCCCC", "cccccccc", "EEE....."],
    },
}


def draw_hair(px, d, style, yoff=3):
    if not style:
        return
    rows = HAIR[style]["side" if d in ("left", "right") else d]
    stamp(px, rows, 4, yoff)


def draw_hat(px, d, hat):
    if not hat:
        return
    rows = HATS[hat]["side" if d in ("left", "right") else d]
    y0 = 2 if hat == "police" else 3
    x0 = 4 if hat != "police" or d in ("down", "up") else 3
    stamp(px, rows, x0, y0)


def draw_face_extras(px, d, face):
    if face.get("beard"):
        if d == "down":
            stamp(px, ["X......X", "XxXXXXxX", ".XXXXXX."], 4, 10)
            px[(7, 11)] = "M"
            px[(8, 11)] = "M"
        elif d in ("left", "right"):
            stamp(px, ["X.......", "XXXXX...", ".XXXX..."], 4, 10)
    if face.get("scar") and d == "down":
        px[(9, 8)] = "R"
        px[(10, 9)] = "R"
        px[(9, 10)] = "R"
    if face.get("scar") and d == "left":
        pass
    if face.get("glasses") and d == "down":
        for x in (5, 6, 7, 8, 9, 10):
            px[(x, 9)] = "G"
        px[(6, 9)] = "E"
        px[(9, 9)] = "E"
    if face.get("glasses") and d == "left":
        px[(4, 9)] = "G"
        px[(5, 9)] = "E"
        px[(6, 9)] = "G"


def render(spec, d, phase):
    """spec: dict(build, hair, hat, face, palette). 옆모습 오른쪽은 왼쪽을 뒤집어 만든다."""
    dd = "left" if d == "right" else d
    px = {}
    build = spec.get("build", "slim")
    draw_legs(px, dd, phase, build)
    draw_torso(px, dd, phase, build, spec.get("torso", build))
    draw_head(px, dd, spec.get("face", {}))
    draw_hair(px, dd, spec.get("hair"))
    draw_face_extras(px, dd, spec.get("face", {}))
    draw_hat(px, dd, spec.get("hat"))
    pal = {k: hexc(v) for k, v in spec["palette"].items()}
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for (x, y), ch in px.items():
        if 0 <= x < W and 0 <= y < H and ch in pal:
            img.putpixel((x, y), pal[ch])
    # 테두리
    src = img.copy()
    for y in range(H):
        for x in range(W):
            if src.getpixel((x, y))[3]:
                continue
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < W and 0 <= ny < H and src.getpixel((nx, ny))[3]:
                    img.putpixel((x, y), OUTLINE)
                    break
    if d == "right":
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    return img


def sheet(spec):
    """한 인물의 12칸 (방향 4 x 걸음 3: 선 자세, 왼발, 오른발) 을 가로로 붙인다."""
    out = Image.new("RGBA", (W * 12, H), (0, 0, 0, 0))
    for di, d in enumerate(DIRS):
        for ph in range(3):
            out.alpha_composite(render(spec, d, ph), ((di * 3 + ph) * W, 0))
    return out


CAST = {
    "thief": {  # 오만복: 남색 후드, 검은 비니
        "build": "slim", "torso": "hoodie", "hair": "short", "hat": "beanie", "face": {},
        "palette": {"S": "#e8c29a", "s": "#c99d75", "E": "#2a2230", "M": "#a35f4f",
                    "H": "#3a2c26", "h": "#2a201c", "C": "#2f3033", "c": "#202124",
                    "T": "#3d4c6e", "t": "#2c3854", "U": "#8a96ad",
                    "P": "#34323a", "p": "#27252c", "B": "#bfb8ad"},
    },
    "crook": {  # 곽두철: 가죽 점퍼, 까까머리, 수염, 흉터
        "build": "big", "hair": "buzz", "hat": None,
        "face": {"beard": True, "scar": True},
        "palette": {"S": "#c9946b", "s": "#a8764f", "E": "#231c1f", "M": "#6e3a30",
                    "H": "#2b2422", "h": "#1f1a19", "X": "#3b302b", "x": "#2c2420",
                    "R": "#8c4a3e", "T": "#6e4b34", "t": "#523625", "U": "#2e2b2b",
                    "P": "#3c4a63", "p": "#2d384c", "B": "#3a2a20"},
    },
    "police": {
        "build": "slim", "torso": "badge", "hair": "short", "hat": "police", "face": {},
        "palette": {"S": "#e3bb92", "s": "#c4966d", "E": "#1f1f2a", "M": "#9a5a4a",
                    "H": "#2a2320", "h": "#1d1816", "C": "#2b3a63", "c": "#1f2a4a",
                    "U": "#d8b24a", "T": "#34467a", "t": "#26345c",
                    "P": "#28324f", "p": "#1d253c", "B": "#1b1b20"},
    },
    "grandpa": {
        "build": "slim", "hair": "bald_sides", "hat": None, "face": {"glasses": True},
        "palette": {"S": "#e6c3a0", "s": "#c9a27d", "E": "#2a2230", "M": "#a0645a", "G": "#8a7a6a",
                    "H": "#d6d2cc", "h": "#b3aea6", "T": "#7a6a55", "t": "#5f5242", "U": "#c9b99a",
                    "P": "#4d4a47", "p": "#3b3936", "B": "#3a2e27"},
    },
    "grandma": {
        "build": "slim", "hair": "bun", "hat": None, "face": {"mouth": True},
        "palette": {"S": "#ecc9a8", "s": "#cfa887", "E": "#2a2230", "M": "#b26a64",
                    "H": "#cfcac6", "h": "#aaa49f", "T": "#8e5a6a", "t": "#6e4452", "U": "#e0c8a8",
                    "P": "#5a4a55", "p": "#463a42", "B": "#3a2e27"},
    },
}


if __name__ == "__main__":
    import sys
    scale = 6
    rows = []
    for name, spec in CAST.items():
        rows.append(sheet(spec))
    out = Image.new("RGBA", (W * 12 * scale + 20, (H * scale + 10) * len(rows) + 10), (120, 110, 95, 255))
    for i, r in enumerate(rows):
        out.alpha_composite(r.resize((r.width * scale, r.height * scale), Image.NEAREST), (10, 10 + i * (H * scale + 10)))
    out.save(sys.argv[1] if len(sys.argv) > 1 else "chars_preview.png")
    print("ok", out.size)
