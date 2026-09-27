"""대화창 얼굴 그림 (32x32 흉상, 표정 4가지).

타원과 몇 줄의 점으로 머리를 그리고, 눈썹, 눈, 입만 바꿔 표정을 만든다.
build_art.py 가 가져다 쓴다.
"""
from PIL import Image

S = 32
OUTLINE = (34, 28, 36, 255)


def hexc(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


def in_ellipse(x, y, cx, cy, rx, ry):
    return ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0


def put(px, x, y, ch):
    if 0 <= x < S and 0 <= y < S:
        px[(x, y)] = ch


def stamp(px, rows, x0, y0, flip=False):
    for dy, row in enumerate(rows):
        n = len(row)
        for dx, ch in enumerate(row):
            if ch != ".":
                put(px, x0 + (n - 1 - dx if flip else dx), y0 + dy, ch)


# 눈썹 (왼쪽 눈 기준, 오른쪽은 뒤집어 찍는다). 4칸 폭.
BROWS = {
    "flat": ["bbbb"],
    "worry": ["...b", ".bb.", "b..."],   # 안쪽이 올라감 (걱정)
    "angry": ["b...", ".bb.", "...b"],   # 안쪽이 내려감 (화남)
    "raise": [".bb.", "b..b"],
    "heavy": ["bbbb", "bbbb"],
    "heavy_angry": ["bb..", "bbbb", "..bb"],
}
# 눈 (왼쪽 눈 기준)
EYES = {
    "dot": ["EW", "EE"],
    "wide": ["WWW", "WEW", "WWW"],
    "narrow": ["EEE"],
    "happy": [".E.", "E.E"],
    "small": ["EE"],
    "soft": ["EEE", ".E."],
}
# 입 (가운데 정렬 기준 폭)
MOUTHS = {
    "line": ["MMM"],
    "smile": ["M...M", ".MMM."],
    "grin": ["MMMMM", "MWWWM", ".MMM."],
    "open": [".MMM.", "MDDDM", ".MMM."],
    "frown": [".MMM.", "M...M"],
    "wavy": ["M.M.M", ".M.M."],
    "flat_wide": ["MMMMM"],
}


def draw(spec, expr):
    px = {}
    cx, cy, rx, ry = spec["head"]
    # 몸통
    for y, (x0, x1) in spec["torso_rows"].items():
        for x in range(x0, x1 + 1):
            put(px, x, y, "T")
    for (x, y, ch) in spec.get("torso_detail", []):
        put(px, x, y, ch)
    # 목
    nx0, nx1, ny0, ny1 = spec["neck"]
    for y in range(ny0, ny1 + 1):
        for x in range(nx0, nx1 + 1):
            put(px, x, y, "s")
    # 귀
    for (x, y) in spec["ears"]:
        put(px, x, y, "S")
    # 머리
    for y in range(S):
        for x in range(S):
            if in_ellipse(x, y, cx, cy, rx, ry):
                shade = x + 0.5 > cx + rx * 0.55 or y + 0.5 > cy + ry * 0.75
                put(px, x, y, "s" if shade else "S")
    # 머리칼, 모자, 수염
    for layer in spec.get("layers", []):
        layer(px)
    # 표정
    e = spec["expr"][expr]
    ey, lx, rxx = spec["eye_y"], spec["eye_lx"], spec["eye_rx"]
    brow = BROWS[e["brow"]]
    stamp(px, brow, lx - 1, ey - 1 - len(brow))
    stamp(px, brow, rxx - 1, ey - 1 - len(brow), flip=True)
    eye = EYES[e["eye"]]
    stamp(px, eye, lx, ey)
    stamp(px, eye, rxx + 2 - len(eye[0]), ey, flip=True)
    mouth = MOUTHS[e["mouth"]]
    stamp(px, mouth, 16 - len(mouth[0]) // 2, spec["mouth_y"])
    for (x, y, ch) in spec.get("nose", []):
        put(px, x, y, ch)
    for (x, y, ch) in e.get("extra", []):
        put(px, x, y, ch)

    pal = {k: hexc(v) for k, v in spec["palette"].items()}
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    for (x, y), ch in px.items():
        if ch in pal:
            img.putpixel((x, y), pal[ch])
    src = img.copy()
    for y in range(S):
        for x in range(S):
            if src.getpixel((x, y))[3]:
                continue
            for qx, qy in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= qx < S and 0 <= qy < S and src.getpixel((qx, qy))[3]:
                    img.putpixel((x, y), OUTLINE)
                    break
    return img


# ------------------------------------------------------------ 인물 ----

def thief_layers():
    def beanie(px):
        for y in range(2, 13):
            for x in range(S):
                if in_ellipse(x, y, 16, 12.5, 9.2, 9.5) and y <= 11:
                    put(px, x, y, "c" if y >= 10 else ("C" if x < 21 else "k"))
        # 비니 아래로 삐져나온 머리칼
        for (x, y) in ((8, 12), (9, 12), (9, 13), (23, 12), (24, 12), (23, 13)):
            put(px, x, y, "H")
    return [beanie]


def crook_layers():
    def buzz(px):
        for y in range(3, 10):
            for x in range(S):
                if in_ellipse(x, y, 16, 15, 9.3, 10.5) and y <= 8:
                    put(px, x, y, "H" if y <= 7 else "h")

    def beard(px):
        for y in range(18, 27):
            for x in range(S):
                if in_ellipse(x, y, 16, 15, 9.3, 10.5):
                    if y >= 21 or (y >= 18 and (x <= 9 or x >= 23)):
                        put(px, x, y, "X" if x < 21 else "x")
        for x in range(12, 21):
            put(px, x, 20, "X")  # 콧수염

    def scar(px):
        for (x, y) in ((10, 11), (11, 12), (11, 13), (12, 14), (12, 16), (13, 17), (13, 18)):
            put(px, x, y, "R")
    return [buzz, beard, scar]


CAST = {
    "thief": {
        "head": (16, 15.5, 7.6, 9.2),
        "neck": (13, 19, 24, 26),
        "ears": [(8, 15), (8, 16), (24, 15), (24, 16)],
        "torso_rows": {25: (10, 22), 26: (7, 25), 27: (5, 27), 28: (4, 28), 29: (3, 29), 30: (3, 29), 31: (3, 29)},
        "torso_detail": [(x, 26, "U") for x in (12, 20)] + [(x, 27, "U") for x in (12, 20)]
                        + [(x, 28, "U") for x in (12, 20)] + [(x, y, "t") for y in (29, 30, 31) for x in range(10, 23)],
        "layers": thief_layers(),
        "eye_y": 16, "eye_lx": 11, "eye_rx": 19, "mouth_y": 21,
        "nose": [(16, 18, "s"), (16, 19, "s")],
        "palette": {"S": "#e8c29a", "s": "#c99d75", "E": "#2a2230", "W": "#f4efe6", "M": "#8c4f45",
                    "D": "#3a1f22", "b": "#3a2c26", "H": "#3a2c26", "C": "#3a3b40", "k": "#2f3034",
                    "c": "#26272b", "T": "#3d4c6e", "t": "#2c3854", "U": "#9aa6bd", "Q": "#9fd4f0"},
        "expr": {
            "normal": {"brow": "flat", "eye": "dot", "mouth": "line"},
            "nervous": {"brow": "worry", "eye": "dot", "mouth": "wavy",
                        "extra": [(24, 11, "Q"), (24, 12, "Q"), (23, 12, "Q")]},
            "smile": {"brow": "flat", "eye": "happy", "mouth": "smile"},
            "shock": {"brow": "raise", "eye": "wide", "mouth": "open"},
        },
    },
    "crook": {
        "head": (16, 15, 9.3, 10.5),
        "neck": (11, 21, 24, 26),
        "ears": [(6, 14), (6, 15), (6, 16), (26, 14), (26, 15), (26, 16)],
        "torso_rows": {25: (8, 24), 26: (4, 28), 27: (2, 30), 28: (1, 31), 29: (0, 31), 30: (0, 31), 31: (0, 31)},
        "torso_detail": [(x, y, "U") for y in range(25, 32) for x in range(16 - (y - 24), 17 + (y - 24)) if y < 29]
                        + [(x, y, "U") for y in range(29, 32) for x in range(12, 21)]
                        + [(x, y, "t") for y in range(26, 32) for x in (9, 10, 22, 23)],
        "layers": crook_layers(),
        "eye_y": 15, "eye_lx": 11, "eye_rx": 19, "mouth_y": 22,
        "nose": [(16, 17, "s"), (16, 18, "s"), (15, 18, "s"), (17, 18, "s")],
        "palette": {"S": "#c9946b", "s": "#a8764f", "E": "#231c1f", "W": "#efe6da", "M": "#5e3029",
                    "D": "#2a1414", "b": "#231c1a", "H": "#2b2422", "h": "#3d302a", "X": "#3b302b",
                    "x": "#2c2420", "R": "#8c4a3e", "T": "#6e4b34", "t": "#523625", "U": "#2e2b2b"},
        "expr": {
            "normal": {"brow": "heavy", "eye": "small", "mouth": "flat_wide"},
            "angry": {"brow": "heavy_angry", "eye": "narrow", "mouth": "frown"},
            "grin": {"brow": "heavy", "eye": "small", "mouth": "grin"},
            "soft": {"brow": "worry", "eye": "small", "mouth": "line"},
        },
    },
}

EXPRS = {"thief": ["normal", "nervous", "smile", "shock"], "crook": ["normal", "angry", "grin", "soft"]}


def sheet():
    """인물마다 한 줄, 표정마다 한 칸."""
    out = Image.new("RGBA", (S * 4, S * len(CAST)), (0, 0, 0, 0))
    for r, name in enumerate(CAST):
        for c, ex in enumerate(EXPRS[name]):
            out.alpha_composite(draw(CAST[name], ex), (c * S, r * S))
    return out


if __name__ == "__main__":
    import sys
    sh = sheet()
    scale = 8
    bg = Image.new("RGBA", (sh.width * scale + 20, sh.height * scale + 20), (60, 58, 70, 255))
    bg.alpha_composite(sh.resize((sh.width * scale, sh.height * scale), Image.NEAREST), (10, 10))
    bg.save(sys.argv[1] if len(sys.argv) > 1 else "portraits_preview.png")
    print("ok", bg.size)
