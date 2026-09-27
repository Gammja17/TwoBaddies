"""Kenney 에 없는 소품과 아이템 그림. 같은 색감(무광, 짙은 갈색 테두리)으로 직접 찍는다."""
from PIL import Image

# Kenney 로그라이크 묶음에서 뽑은 색
WOOD = {"o": "#6e4f32", "d": "#8a6443", "m": "#a87e54", "l": "#b98b5e", "h": "#cfa57a"}
METAL = {"o": "#3f3f47", "d": "#5e5e66", "m": "#7c7c84", "l": "#a2a2aa", "h": "#c6c6cc"}
DARK = {"o": "#1e1e24", "d": "#2c2c33", "m": "#3b3b44", "l": "#50505a", "h": "#6a6a74"}
PAPER = {"o": "#8f8069", "d": "#c9bb9c", "m": "#e6dabf", "l": "#f2eadb", "h": "#fffaf0"}


def hexc(s, a=255):
    s = s.lstrip("#")
    if len(s) == 3:
        s = "".join(ch * 2 for ch in s)
    if len(s) == 8:
        a = int(s[6:8], 16)
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


class Canvas:
    def __init__(self, w, h):
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.w, self.h = w, h

    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((x, y), hexc(c) if isinstance(c, str) else c)

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.px(x, y, c)

    def box(self, x0, y0, x1, y1, pal, top_light=True):
        """테두리(o), 밝은 윗면(l), 몸통(m), 그늘진 아랫줄(d)."""
        self.rect(x0, y0, x1, y1, pal["o"])
        self.rect(x0 + 1, y0 + 1, x1 - 1, y1 - 1, pal["m"])
        if top_light:
            self.rect(x0 + 1, y0 + 1, x1 - 1, y0 + 1, pal["l"])
        self.rect(x0 + 1, y1 - 1, x1 - 1, y1 - 1, pal["d"])

    def hline(self, x0, x1, y, c):
        self.rect(x0, y, x1, y, c)

    def vline(self, x, y0, y1, c):
        self.rect(x, y0, x, y1, c)

    def rows(self, rows, pal, x0=0, y0=0):
        for dy, row in enumerate(rows):
            for dx, ch in enumerate(row):
                if ch != "." and ch in pal:
                    self.px(x0 + dx, y0 + dy, pal[ch])


# ------------------------------------------------------------ 소품 ----

def shutter_h(w=32, h=16):
    """남쪽 벽 출입구를 막은 철제 셔터 (가로 골)."""
    c = Canvas(w, h)
    c.rect(0, 0, w - 1, h - 1, METAL["o"])
    for y in range(1, h - 1):
        col = METAL["l"] if y % 3 == 1 else (METAL["m"] if y % 3 == 2 else METAL["d"])
        c.hline(1, w - 2, y, col)
    c.hline(1, w - 2, h - 2, DARK["m"])
    return c.img


def shutter_v(w=16, h=16):
    """서쪽 벽 뒷문을 막은 철제 셔터 (세로 골)."""
    c = Canvas(w, h)
    c.rect(0, 0, w - 1, h - 1, METAL["o"])
    for x in range(1, w - 1):
        col = METAL["l"] if x % 3 == 1 else (METAL["m"] if x % 3 == 2 else METAL["d"])
        c.vline(x, 1, h - 2, col)
    return c.img


def shutter_window(w=16, h=32):
    """벽면 창문 위에 내려온 셔터."""
    c = Canvas(w, h)
    c.rect(1, 3, w - 2, h - 4, METAL["o"])
    for y in range(4, h - 4):
        col = METAL["l"] if y % 3 == 1 else (METAL["m"] if y % 3 == 2 else METAL["d"])
        c.hline(2, w - 3, y, col)
    return c.img


def door_front_open(w=32, h=16):
    """열린 현관: 어두운 출입구와 발판."""
    c = Canvas(w, h)
    c.rect(0, 0, w - 1, h - 1, "#2a2320")
    c.rect(2, 2, w - 3, h - 1, "#3a302a")
    c.rect(6, 9, w - 7, h - 3, "#7a5a3a")
    c.rect(7, 10, w - 8, h - 4, "#8f6c47")
    return c.img


def door_back_open(w=16, h=16):
    c = Canvas(w, h)
    c.rect(0, 0, w - 1, h - 1, "#2a2320")
    c.rect(2, 1, w - 1, h - 2, "#3a302a")
    return c.img


def door_side(state="closed", w=16, h=16):
    """세로 벽에 달린 안쪽 문 (식료품 창고). closed / open / latched."""
    c = Canvas(w, h)
    if state == "open":
        c.rect(0, 0, 3, h - 1, WOOD["o"])
        c.rect(1, 1, 2, h - 2, WOOD["l"])
        return c.img
    c.rect(4, 0, 11, h - 1, WOOD["o"])
    c.rect(5, 1, 10, h - 2, WOOD["m"])
    c.vline(7, 2, h - 3, WOOD["d"])
    c.px(9, 8, "#e0c060")
    if state == "latched":
        c.rect(3, 6, 12, 8, METAL["o"])
        c.hline(4, 11, 7, METAL["l"])
    return c.img


def security_console(w=16, h=24):
    """현관 옆 보안 단말기: 화면, 번호판, 지문 인식기."""
    c = Canvas(w, h)
    c.rect(4, 22, 11, 23, DARK["o"])            # 받침
    c.rect(6, 12, 9, 21, METAL["d"])            # 기둥
    c.vline(6, 12, 21, METAL["o"])
    c.vline(9, 12, 21, METAL["o"])
    c.box(1, 0, 14, 12, METAL)                  # 머리
    c.rect(3, 2, 12, 4, "#1d2b24")              # 화면
    c.hline(4, 8, 3, "#e05a4a")                 # 빨간 글자 (잠김)
    for yy in (6, 8, 10):
        for xx in (3, 5, 7):
            c.px(xx, yy, METAL["h"])
    c.rect(10, 6, 12, 10, "#20303a")            # 지문 창
    c.rect(11, 7, 11, 9, "#4aa0c8")
    return c.img


def security_console_open(w=16, h=24):
    img = security_console(w, h)
    c = Canvas(w, h)
    c.img = img
    c.rect(3, 2, 12, 4, "#1d2b24")
    c.hline(4, 9, 3, "#6ad07a")                 # 초록 (열림)
    return c.img


def cctv_desk(w=32, h=32):
    c = Canvas(w, h)
    c.box(1, 14, 30, 30, WOOD)                   # 책상
    c.rect(2, 26, 29, 29, WOOD["d"])
    for x0 in (3, 17):                           # 모니터 둘
        c.box(x0, 2, x0 + 11, 12, DARK)
        c.rect(x0 + 2, 4, x0 + 9, 10, "#23433a")
        c.hline(x0 + 2, x0 + 9, 6, "#3f6f5c")
        c.hline(x0 + 2, x0 + 9, 9, "#3f6f5c")
        c.rect(x0 + 5, 13, x0 + 6, 14, DARK["o"])
    c.rect(12, 17, 19, 20, PAPER["m"])           # 설명서
    c.rect(12, 17, 19, 17, PAPER["o"])
    return c.img


def cctv_desk_off(w=32, h=32):
    img = cctv_desk(w, h)
    c = Canvas(w, h)
    c.img = img
    for x0 in (3, 17):
        c.rect(x0 + 2, 4, x0 + 9, 10, "#1a1c20")
    return c.img


def tv(on=True, w=16, h=16):
    c = Canvas(w, h)
    c.box(0, 9, 15, 15, WOOD)                    # 장식장
    c.box(1, 1, 14, 10, DARK)                    # 브라운관
    c.rect(3, 3, 12, 8, "#2f5a6e" if on else "#1a1c20")
    if on:
        c.rect(4, 4, 7, 7, "#d9c9a0")            # 뉴스 화면 속 얼굴
        c.hline(8, 11, 5, "#e8e8e8")
        c.hline(8, 11, 7, "#c05050")
    return c.img


def boiler(w=32, h=32):
    c = Canvas(w, h)
    c.box(4, 4, 27, 30, METAL)
    c.rect(6, 8, 25, 9, METAL["d"])
    c.rect(10, 16, 21, 25, DARK["m"])            # 아궁이
    c.rect(11, 17, 20, 24, "#3a2418")
    c.rect(13, 21, 18, 24, "#c8642e")
    c.rect(14, 22, 17, 23, "#f0a040")
    c.rect(13, 0, 18, 4, METAL["d"])              # 연통
    c.vline(13, 0, 4, METAL["o"])
    c.vline(18, 0, 4, METAL["o"])
    c.px(24, 12, "#e05a4a")
    return c.img


def chute_grate(open_=False, w=32, h=32):
    """석탄 구멍: 벽 위쪽의 네모난 구멍과 쇠창살."""
    c = Canvas(w, h)
    c.rect(2, 4, 29, 27, DARK["o"])
    c.rect(4, 6, 27, 25, "#0f0f12")
    c.rect(5, 18, 26, 25, "#1c1a1a")            # 비탈진 구멍 안쪽
    if not open_:
        for x in range(5, 27, 4):
            c.vline(x, 5, 26, METAL["m"])
            c.vline(x + 1, 5, 26, METAL["d"])
        for y in (9, 17, 24):
            c.hline(3, 28, y, METAL["l"])
            c.hline(3, 28, y + 1, METAL["d"])
    else:
        c.rect(3, 27, 28, 29, METAL["m"])        # 들어 올려 받쳐 둔 창살
        c.hline(3, 28, 27, METAL["l"])
    return c.img


def tool_cabinet(state="locked", w=16, h=32):
    c = Canvas(w, h)
    c.box(1, 2, 14, 31, METAL)
    c.vline(8, 4, 29, METAL["o"])
    if state == "open":
        c.rect(2, 3, 13, 30, DARK["d"])
        c.rect(3, 8, 12, 9, METAL["l"])          # 선반
        c.rect(3, 18, 12, 19, METAL["l"])
    elif state == "locked":
        c.rect(7, 14, 9, 17, "#c9a040")          # 자물쇠
        c.px(8, 13, "#8a6a20")
    elif state == "broken":
        c.rect(2, 3, 13, 30, DARK["d"])
        c.rect(12, 6, 14, 12, METAL["m"])
    return c.img


def washer(w=16, h=16):
    c = Canvas(w, h)
    c.box(1, 1, 14, 15, {"o": "#8a8a90", "d": "#b8b8bc", "m": "#dcdce0", "l": "#f0f0f2", "h": "#ffffff"})
    c.rect(4, 5, 11, 12, "#5e6f80")
    c.rect(5, 6, 10, 11, "#8fb0c8")
    c.px(12, 3, "#e05a4a")
    return c.img


def bathtub(w=16, h=32):
    c = Canvas(w, h)
    c.box(0, 1, 15, 31, {"o": "#8a8a90", "d": "#b8b8bc", "m": "#e8e8ec", "l": "#f6f6f8", "h": "#ffffff"})
    c.rect(3, 4, 12, 28, "#9fc8d8")
    c.rect(3, 4, 12, 5, "#c8e4ee")
    c.px(8, 3, METAL["l"])
    return c.img


def toilet(w=16, h=16):
    c = Canvas(w, h)
    w_ = {"o": "#8a8a90", "d": "#c8c8cc", "m": "#ececf0", "l": "#f8f8fa", "h": "#ffffff"}
    c.box(3, 0, 12, 5, w_)
    c.rect(4, 6, 11, 14, w_["o"])
    c.rect(5, 7, 10, 13, w_["m"])
    c.rect(6, 8, 9, 12, "#bcd8e0")
    return c.img


def basin(w=16, h=16):
    """욕실 세면대와 그 위 약장."""
    c = Canvas(w, h)
    w_ = {"o": "#8a8a90", "d": "#c8c8cc", "m": "#ececf0", "l": "#f8f8fa", "h": "#ffffff"}
    c.box(2, 6, 13, 13, w_)
    c.rect(4, 8, 11, 11, "#bcd8e0")
    c.px(8, 7, METAL["m"])
    return c.img


def med_cabinet(w=16, h=16):
    c = Canvas(w, h)
    c.box(2, 2, 13, 14, {"o": "#8a8a90", "d": "#b8b8bc", "m": "#dcdce0", "l": "#f0f0f2", "h": "#ffffff"})
    c.rect(4, 4, 11, 12, "#a8c4d0")
    c.rect(5, 5, 7, 7, "#d8eaf0")
    c.rect(7, 8, 9, 8, "#e05a4a")
    c.rect(8, 7, 8, 9, "#e05a4a")
    return c.img


def stairs(kind="up", w=32, h=32):
    """up: 위로 올라가는 나무 계단(벽 쪽으로 좁아짐). down: 어둠 속으로 내려가는 계단."""
    c = Canvas(w, h)
    if kind == "up":
        for i in range(8):
            y = 28 - i * 4
            shade = ["#8a6443", "#a87e54", "#b98b5e", "#cfa57a"][i % 4]
            c.rect(2, y, w - 3, y + 3, WOOD["o"])
            c.rect(3, y + 1, w - 4, y + 2, shade)
        c.vline(0, 0, h - 1, WOOD["o"])
        c.vline(1, 0, h - 1, WOOD["d"])
        c.vline(w - 1, 0, h - 1, WOOD["o"])
        c.vline(w - 2, 0, h - 1, WOOD["d"])
    else:
        c.rect(0, 0, w - 1, h - 1, "#0e0d10")
        cols = ["#b98b5e", "#a07550", "#7d5a3d", "#5c422d", "#3e2d20", "#281e16", "#18120e", "#0e0d10"]
        for i in range(8):
            y = i * 4
            c.rect(2, y, w - 3, y + 3, cols[i])
            c.hline(2, w - 3, y + 3, "#0e0d10")
        c.vline(0, 0, h - 1, WOOD["o"])
        c.vline(w - 1, 0, h - 1, WOOD["o"])
    return c.img


def ceiling_bulb(on=True, w=16, h=16):
    c = Canvas(w, h)
    c.vline(8, 0, 6, DARK["m"])
    c.rect(6, 6, 10, 7, METAL["d"])
    if on:
        c.rect(6, 8, 10, 12, "#fff2b0")
        c.rect(7, 9, 9, 11, "#ffffff")
    else:
        c.rect(6, 8, 10, 8, DARK["l"])
    return c.img


def boxes(w=16, h=16):
    c = Canvas(w, h)
    cb = {"o": "#7a5a3a", "d": "#9a7650", "m": "#b89468", "l": "#cdb084", "h": "#e0c8a0"}
    c.box(0, 5, 10, 15, cb)
    c.hline(1, 9, 10, cb["d"])
    c.box(6, 0, 15, 8, cb)
    c.hline(7, 14, 4, cb["d"])
    return c.img


def coal_pile(w=16, h=16):
    c = Canvas(w, h)
    c.rect(1, 9, 14, 15, "#1c1b1e")
    c.rect(3, 6, 12, 9, "#1c1b1e")
    c.rect(4, 7, 7, 9, "#2e2d33")
    c.rect(9, 10, 12, 12, "#2e2d33")
    c.rect(3, 12, 5, 13, "#2e2d33")
    return c.img


def bag(w=16, h=16):
    """곽두철의 더플백."""
    c = Canvas(w, h)
    g = {"o": "#2e3326", "d": "#3e4533", "m": "#525c43", "l": "#66714f", "h": "#7c8860"}
    c.box(1, 6, 14, 15, g)
    c.rect(5, 3, 10, 6, g["o"])
    c.rect(6, 4, 9, 5, "#00000000")
    c.hline(2, 13, 10, g["d"])
    return c.img


def ramen(w=16, h=16):
    c = Canvas(w, h)
    for x0, y0 in ((2, 7), (9, 9)):
        c.rect(x0, y0, x0 + 4, y0 + 5, "#b04030")
        c.rect(x0 + 1, y0 + 1, x0 + 3, y0 + 1, "#f0e0c0")
        c.hline(x0, x0 + 4, y0 + 3, "#e8d8b0")
    return c.img


def paper_thing(kind, w=16, h=16):
    """바닥이나 가구 위에 놓인 종이 (신문, 카드, 쪽지)."""
    c = Canvas(w, h)
    if kind == "newspaper":
        c.box(2, 4, 13, 13, PAPER)
        c.hline(4, 11, 6, "#555")
        c.rect(4, 8, 7, 11, "#888")
        c.hline(9, 11, 8, "#777")
        c.hline(9, 11, 10, "#777")
    elif kind == "card":
        c.box(4, 5, 11, 12, {"o": "#9a4a5a", "d": "#c07080", "m": "#e8a0b0", "l": "#f8c8d0", "h": "#fff"})
        c.px(7, 8, "#fff")
        c.px(8, 8, "#fff")
    else:
        c.box(4, 5, 11, 12, PAPER)
        c.hline(5, 10, 7, "#999")
        c.hline(5, 9, 9, "#999")
    return c.img


def calendar(w=16, h=16):
    c = Canvas(w, h)
    c.box(3, 2, 12, 14, PAPER)
    c.rect(4, 3, 11, 5, "#c05050")
    for yy in (7, 9, 11):
        for xx in (5, 7, 9):
            c.px(xx, yy, "#9a8a70")
    c.rect(9, 9, 10, 10, "#d04040")
    return c.img


def photo_frame(kind="wedding", w=16, h=16):
    c = Canvas(w, h)
    c.box(2, 2, 13, 13, {"o": "#6e4f32", "d": "#9a7040", "m": "#c8a060", "l": "#e0c080", "h": "#f0d8a0"})
    c.rect(4, 4, 11, 11, "#e8e0d0" if kind == "wedding" else "#b8d0e0")
    if kind == "wedding":
        c.rect(5, 6, 6, 10, "#2a2a30")           # 신랑
        c.rect(5, 5, 6, 5, "#e0b890")
        c.rect(9, 6, 10, 10, "#ffffff")          # 신부
        c.rect(9, 5, 10, 5, "#e0b890")
        c.rect(8, 7, 11, 11, "#f4f4f4")
    else:
        c.rect(5, 7, 6, 10, "#8a5a6a")
        c.rect(9, 8, 10, 10, "#5a7a9a")
        c.rect(7, 6, 8, 7, "#e0b890")
    return c.img


def drawer_item(kind, w=16, h=16):
    """가구 위에 올려 두는 작은 것들."""
    c = Canvas(w, h)
    if kind == "jewelry_box":
        c.box(4, 7, 11, 12, {"o": "#5a2a3a", "d": "#7a3a4a", "m": "#9a4a5a", "l": "#b86a78", "h": "#d890a0"})
        c.px(7, 9, "#e0c060")
        c.px(8, 9, "#e0c060")
    elif kind == "compact":
        c.rect(5, 8, 10, 12, "#c89aa0")
        c.rect(6, 9, 9, 11, "#f0d8c8")
    elif kind == "glass":
        c.rect(6, 6, 9, 11, "#cfe6ec")
        c.rect(6, 9, 9, 11, "#c88a3a")
        c.vline(6, 6, 11, "#8aa8b0")
        c.vline(9, 6, 11, "#8aa8b0")
        c.hline(6, 9, 12, "#8aa8b0")
    elif kind == "glasses":
        c.rect(4, 9, 6, 11, "#555")
        c.rect(9, 9, 11, 11, "#555")
        c.px(5, 10, "#bcd8e0")
        c.px(10, 10, "#bcd8e0")
        c.hline(7, 8, 9, "#555")
    elif kind == "tape":
        c.rect(5, 8, 10, 13, "#d8d0b0")
        c.rect(7, 10, 8, 11, "#8a7a5a")
    elif kind == "knife_block":
        c.box(5, 6, 11, 14, WOOD)
        for x in (6, 8, 10):
            c.vline(x, 3, 6, "#2a2a2a")
    elif kind == "knife_block_empty":
        c.box(5, 6, 11, 14, WOOD)
        for x in (6, 10):
            c.vline(x, 3, 6, "#2a2a2a")
    elif kind == "oil":
        c.rect(6, 5, 9, 13, "#e8c040")
        c.rect(7, 3, 8, 4, "#c04030")
        c.rect(6, 8, 9, 10, "#f0e0a0")
    elif kind == "gloves":
        c.rect(4, 8, 7, 13, "#e8e0c8")
        c.rect(8, 8, 11, 13, "#e8e0c8")
        c.hline(4, 7, 12, "#d06040")
        c.hline(8, 11, 12, "#d06040")
    elif kind == "rope":
        c.rect(4, 7, 11, 13, "#b89a60")
        c.rect(6, 9, 9, 11, "#00000000")
        c.px(5, 8, "#d8bc80")
    elif kind == "flashlight":
        c.rect(4, 9, 11, 11, "#3a3a40")
        c.rect(11, 8, 12, 12, "#5a5a60")
        c.px(12, 10, "#fff2b0")
    elif kind == "crowbar":
        c.rect(3, 12, 12, 12, "#b03a30")
        c.rect(12, 5, 12, 12, "#b03a30")
        c.px(11, 5, "#b03a30")
    elif kind == "jack":
        c.rect(3, 12, 12, 13, "#c83a30")
        c.rect(6, 7, 9, 11, "#a02a24")
        c.rect(5, 6, 10, 6, "#6a6a70")
    elif kind == "silver_candle":
        c.rect(7, 4, 8, 12, "#c6c6cc")
        c.rect(5, 12, 10, 13, "#a2a2aa")
        c.rect(7, 2, 8, 3, "#fff2b0")
    elif kind == "sandwich":
        c.rect(3, 8, 12, 12, "#e8c890")
        c.hline(3, 12, 10, "#6aa050")
        c.hline(3, 12, 9, "#f0e0c0")
    elif kind == "whiskey":
        c.rect(6, 5, 9, 13, "#a0602a")
        c.rect(7, 2, 8, 4, "#5a3a1a")
        c.rect(6, 8, 9, 10, "#e8d8b0")
    elif kind == "pills":
        c.rect(6, 6, 9, 13, "#e8e8f0")
        c.rect(6, 5, 9, 6, "#4a8ac0")
        c.rect(6, 9, 9, 10, "#c8d8e8")
    return c.img


# ------------------------------------------------------------ 아이템 (16x16) ----

def item_icon(kind):
    c = Canvas(16, 16)
    if kind == "lockpick":
        c.rect(3, 11, 6, 13, "#5a5a60")
        c.rect(6, 12, 13, 12, "#c6c6cc")
        c.px(13, 11, "#c6c6cc")
        c.rect(6, 9, 12, 9, "#a2a2aa")
        c.px(12, 8, "#a2a2aa")
    elif kind == "fingerprint":
        c.rect(3, 4, 12, 11, "#e8f2f4")
        c.rect(3, 4, 12, 4, "#b8c8cc")
        for (x, y) in ((6, 6), (7, 6), (8, 6), (5, 7), (9, 7), (5, 8), (7, 8), (9, 8), (6, 9), (8, 9)):
            c.px(x, y, "#5a6a70")
    elif kind == "diary":
        c.box(3, 2, 12, 13, {"o": "#5a2a20", "d": "#7a3a2a", "m": "#9a4a34", "l": "#b86a50", "h": "#d08a6a"})
        c.rect(5, 5, 10, 6, "#e0c080")
    elif kind == "memo":
        c.box(3, 3, 12, 13, {"o": "#9a9050", "d": "#d8cc70", "m": "#f4e890", "l": "#fff4b0", "h": "#fff"})
        c.hline(5, 10, 6, "#8a8040")
        c.hline(5, 9, 8, "#8a8040")
        c.hline(5, 10, 10, "#8a8040")
    elif kind == "manual":
        c.box(3, 2, 12, 13, {"o": "#3a4a5a", "d": "#4a5e72", "m": "#5e7690", "l": "#7a90a8", "h": "#9ab0c8"})
        c.rect(5, 5, 10, 7, "#e8e8e8")
    elif kind == "photo":
        return photo_frame("wedding")
    elif kind == "card":
        return paper_thing("card")
    elif kind == "newspaper":
        return paper_thing("newspaper")
    elif kind == "necklace":
        pts = [(4, 5), (4, 7), (5, 9), (6, 10), (7, 11), (8, 11), (9, 10), (10, 9), (11, 7), (11, 5)]
        for (x, y) in pts:
            c.px(x, y, "#f4f0e8")
        c.px(7, 12, "#f8f8ff")
        c.px(8, 12, "#e0e0f0")
    elif kind == "gold":
        c.rect(2, 9, 13, 13, "#b88a20")
        c.rect(3, 10, 12, 12, "#e8c040")
        c.rect(4, 5, 11, 9, "#b88a20")
        c.rect(5, 6, 10, 8, "#f0d060")
    elif kind == "cash":
        c.box(2, 4, 13, 12, {"o": "#8a7a50", "d": "#c8b880", "m": "#e8dca8", "l": "#f4ecc8", "h": "#fff"})
        c.rect(5, 6, 10, 10, "#9ac080")
        c.rect(7, 7, 8, 9, "#5a8a50")
    elif kind == "watch":
        c.rect(5, 5, 10, 12, "#b88a20")
        c.rect(6, 6, 9, 11, "#f4ecd8")
        c.rect(7, 3, 8, 4, "#b88a20")
        c.px(7, 8, "#333")
        c.px(8, 7, "#333")
    elif kind == "bulb":
        return ceiling_bulb(False)
    elif kind == "knife":
        c.rect(3, 11, 6, 13, "#2a2a2e")
        c.rect(7, 10, 13, 12, "#d8d8de")
        c.hline(7, 12, 10, "#f4f4f8")
        c.px(13, 10, "#00000000")
    elif kind == "pan":
        c.rect(3, 6, 10, 13, "#2e2e34")
        c.rect(4, 7, 9, 12, "#4a4a52")
        c.rect(10, 9, 14, 10, "#6e4f32")
    else:
        return drawer_item(kind)
    return c.img


def bed(double=False, blanket="orange", messy=False):
    """위에서 본 침대: 머리판, 베개, 이불, 발판."""
    w = 32 if double else 16
    h = 32
    c = Canvas(w, h)
    bl = {"orange": {"o": "#8a3a1e", "d": "#b04e28", "m": "#cd6231", "l": "#e0804a", "h": "#f0a070"},
          "cream": {"o": "#9a8a68", "d": "#c8b890", "m": "#e0d2ae", "l": "#eee4c8", "h": "#fff6e0"},
          "green": {"o": "#2a6a44", "d": "#3a8a58", "m": "#48a36a", "l": "#68bc86", "h": "#90d4a8"}}[blanket]
    c.box(0, 0, w - 1, h - 1, WOOD)                      # 틀
    c.rect(0, 0, w - 1, 3, WOOD["o"])                    # 머리판
    c.rect(1, 1, w - 2, 2, WOOD["l"])
    c.rect(2, 4, w - 3, h - 3, "#f2ece0")                # 매트리스
    pw = 11 if double else 10
    for x0 in ((3, 18) if double else (3,)):
        c.rect(x0, 5, x0 + pw - 1, 9, "#fbf7ee")         # 베개
        c.hline(x0, x0 + pw - 1, 9, "#d8d0c0")
    c.rect(1, 11, w - 2, h - 3, bl["o"])                 # 이불
    c.rect(2, 12, w - 3, h - 4, bl["m"])
    c.hline(2, w - 3, 12, bl["l"])
    c.hline(2, w - 3, 14, bl["d"])
    if messy:
        c.rect(3, 16, w - 6, 18, bl["l"])
        c.rect(5, 22, w - 3, 24, bl["d"])
        c.rect(2, 11, 6, 13, "#f2ece0")
    c.rect(0, h - 2, w - 1, h - 1, WOOD["o"])            # 발판
    return c.img


def fridge(w=16, h=32):
    c = Canvas(w, h)
    wh = {"o": "#8a8a90", "d": "#c4c4c8", "m": "#e4e4e8", "l": "#f4f4f6", "h": "#ffffff"}
    c.box(1, 1, 14, 31, wh)
    c.hline(2, 13, 12, wh["o"])
    c.rect(11, 5, 12, 9, METAL["m"])
    c.rect(11, 15, 12, 21, METAL["m"])
    c.rect(4, 4, 7, 7, "#e8c0c0")    # 자석 메모
    return c.img
