"""Kenney 원본 묶음(_packs/)과 직접 그린 그림을 게임용 아틀라스로 묶는다.

결과: assets/art/{tiles,props,items,chars,portraits}.png 와 같은 이름의 .json
(이름 -> [x, y, w, h]). 게임은 JSON 만 읽는다.

    python tools/build_art.py
"""
import json
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import chars  # noqa: E402
import draw  # noqa: E402
import portraits  # noqa: E402

ROOT = os.path.dirname(HERE)
PACKS = os.path.join(ROOT, "_packs")
OUT = os.path.join(ROOT, "assets", "art")
T = 16


def load(*parts):
    return Image.open(os.path.join(PACKS, *parts)).convert("RGBA")


RPG = load("kenney_roguelike-rpg-pack", "Spritesheet", "roguelikeSheet_transparent.png")
IND = load("kenney_roguelike-indoors", "Tilesheets", "roguelikeIndoor_transparent.png")
SHEETS = {"rpg": RPG, "ind": IND}


def tile(sheet, c, r):
    return sheet.crop((c * 17, r * 17, c * 17 + 16, r * 17 + 16))


def block(sheet, c, r, w=1, h=1):
    """1px 간격이 있는 시트에서 w x h 칸을 이어 붙인다."""
    img = Image.new("RGBA", (w * T, h * T), (0, 0, 0, 0))
    for dy in range(h):
        for dx in range(w):
            img.alpha_composite(tile(sheet, c + dx, r + dy), (dx * T, dy * T))
    return img


def stack(sheet, cells):
    """세로로 쌓는다 (예: 책장 위칸 + 아래칸)."""
    img = Image.new("RGBA", (T, T * len(cells)), (0, 0, 0, 0))
    for i, (c, r) in enumerate(cells):
        img.alpha_composite(tile(sheet, c, r), (0, i * T))
    return img


def darken(img, f):
    px = img.load()
    out = img.copy()
    po = out.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            po[x, y] = (int(r * f), int(g * f), int(b * f), a)
    return out


# ---------------------------------------------------------------- 벽 ----

def wall_palette(set_name):
    """Kenney 벽 타일에서 색을 읽는다. beige 는 13열, grey 는 20열에서 시작한다."""
    base = {"beige": 0, "grey": 7}[set_name]
    top = tile(RPG, 14 + base, 12)       # 가로 벽 윗면
    face_up = tile(RPG, 18 + base, 15)   # 벽면 위칸
    face_end = tile(RPG, 17 + base, 15)  # 벽면 왼쪽 끝
    return {
        "a": top.getpixel((0, 0)), "b": top.getpixel((0, 1)), "c": top.getpixel((0, 5)),
        "d": top.getpixel((0, 15)), "fb": face_up.getpixel((5, 5)), "e": face_end.getpixel((1, 5)),
    }


def wall_top(pal, m):
    """m: 이웃 벽 여부 dict(n,e,s,w,ne,se,sw,nw) 와 sface(아래가 벽면인지)."""
    img = Image.new("RGBA", (T, T), pal["c"])
    p = img.load()

    def fill(x0, y0, x1, y1, col):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                p[x, y] = col
    if not m["n"]:
        fill(0, 1, 15, 2, pal["b"])
    if not m["s"]:
        fill(0, 13, 15, 14, pal["b"])
    if not m["w"]:
        fill(1, 0, 2, 15, pal["b"])
    if not m["e"]:
        fill(13, 0, 14, 15, pal["b"])
    # 안쪽 모서리
    if m["n"] and m["w"] and not m["nw"]:
        fill(0, 0, 2, 2, pal["b"])
    if m["n"] and m["e"] and not m["ne"]:
        fill(13, 0, 15, 2, pal["b"])
    if m["s"] and m["w"] and not m["sw"]:
        fill(0, 13, 2, 15, pal["b"])
    if m["s"] and m["e"] and not m["se"]:
        fill(13, 13, 15, 15, pal["b"])
    # 바깥 선
    if not m["n"]:
        fill(0, 0, 15, 0, pal["a"])
    if not m["s"]:
        fill(0, 15, 15, 15, pal["d"] if m["sface"] else pal["a"])
    if not m["w"]:
        fill(0, 0, 0, 15, pal["a"])
    if not m["e"]:
        fill(15, 0, 15, 15, pal["a"])
    if m["n"] and m["w"] and not m["nw"]:
        p[0, 0] = pal["a"]
    if m["n"] and m["e"] and not m["ne"]:
        p[15, 0] = pal["a"]
    if m["s"] and m["w"] and not m["sw"]:
        p[0, 15] = pal["a"]
    if m["s"] and m["e"] and not m["se"]:
        p[15, 15] = pal["a"]
    return img


def wall_face(pal, lower, left_end, right_end):
    img = Image.new("RGBA", (T, T), pal["fb"])
    p = img.load()
    if lower:
        for x in range(T):
            p[x, 11] = pal["d"]
            for y in (12, 13, 14):
                p[x, y] = pal["c"]
            p[x, 15] = pal["a"]
    for y in range(T):
        if left_end:
            p[0, y] = pal["a"]
            p[1, y] = pal["e"]
            p[2, y] = pal["e"]
        if right_end:
            p[15, y] = pal["a"]
            p[14, y] = pal["e"]
            p[13, y] = pal["e"]
    if lower:
        if left_end:
            p[1, 15] = pal["a"]
        if right_end:
            p[14, 15] = pal["a"]
    return img


# ---------------------------------------------------------------- 아틀라스 ----

class Grid:
    """16px 칸 아틀라스 (타일, 아이템)."""

    def __init__(self, cols):
        self.cols = cols
        self.items = []

    def add(self, name, img):
        self.items.append((name, img))

    def save(self, stem):
        rows = (len(self.items) + self.cols - 1) // self.cols
        sheet = Image.new("RGBA", (self.cols * T, rows * T), (0, 0, 0, 0))
        meta = {}
        for i, (name, img) in enumerate(self.items):
            x, y = (i % self.cols) * T, (i // self.cols) * T
            sheet.alpha_composite(img, (x, y))
            meta[name] = [x, y, T, T]
        sheet.save(os.path.join(OUT, stem + ".png"))
        return meta


class Shelf:
    """크기가 제각각인 그림을 선반식으로 채운다."""

    def __init__(self, width):
        self.width = width
        self.items = []

    def add(self, name, img):
        self.items.append((name, img))

    def save(self, stem):
        items = sorted(self.items, key=lambda it: (-it[1].height, it[0]))
        x = y = shelf_h = 0
        placed = {}
        for name, img in items:
            if x + img.width > self.width:
                x, y, shelf_h = 0, y + shelf_h, 0
            placed[name] = (x, y, img)
            x += img.width
            shelf_h = max(shelf_h, img.height)
        h = y + shelf_h
        sheet = Image.new("RGBA", (self.width, h), (0, 0, 0, 0))
        meta = {}
        for name, (px, py, img) in placed.items():
            sheet.alpha_composite(img, (px, py))
            meta[name] = [px, py, img.width, img.height]
        sheet.save(os.path.join(OUT, stem + ".png"))
        return meta


def build_tiles():
    g = Grid(16)
    g.add("void", Image.new("RGBA", (T, T), (0, 0, 0, 255)))
    g.add("floor_wood", tile(RPG, 5, 2))
    g.add("floor_tile", tile(RPG, 6, 2))
    g.add("floor_plank", tile(RPG, 8, 2))
    g.add("floor_stone", darken(tile(RPG, 6, 3), 0.62))
    g.add("grass", tile(RPG, 5, 0))
    g.add("grass2", tile(RPG, 5, 1))
    g.add("dirt", tile(RPG, 6, 0))
    walls = {}
    for set_name in ("beige", "grey"):
        pal = wall_palette(set_name)
        seen = {}
        for mask in range(512):
            m = {k: bool(mask >> i & 1) for i, k in enumerate(("n", "e", "s", "w", "ne", "se", "sw", "nw", "sface"))}
            img = wall_top(pal, m)
            key = img.tobytes()
            if key not in seen:
                seen[key] = "wall_%s_%d" % (set_name, len(seen))
                g.add(seen[key], img)
            walls["%s:%d" % (set_name, mask)] = seen[key]
        for lower in (False, True):
            for le in (False, True):
                for re in (False, True):
                    name = "face_%s_%s%s%s" % (set_name, "lo" if lower else "up", "_l" if le else "", "_r" if re else "")
                    g.add(name, wall_face(pal, lower, le, re))
    meta = g.save("tiles")
    meta["_walls"] = walls
    return meta


PROPS_KENNEY = {
    # 거실
    "fireplace": ("rpg", 54, 9, 1, 2),
    "piano": ("ind", 23, 8, 2, 2),
    "sofa": ("ind", 23, 11, 2, 3),
    "armchair": ("ind", 25, 11, 1, 2),
    "armchair_green": ("ind", 25, 15, 1, 2),
    "rug_orange": ("ind", 0, 9, 3, 2),
    "rug_green": ("ind", 7, 9, 3, 2),
    "rug_round": ("ind", 19, 8, 2, 1),
    "rug_round_green": ("ind", 19, 10, 2, 1),
    "runner": ("ind", 5, 9, 1, 3),
    "runner_green": ("ind", 12, 9, 1, 3),
    "cuckoo_clock": ("rpg", 26, 8, 1, 1),
    "painting_green": ("ind", 19, 12, 1, 1),
    "painting_orange": ("ind", 19, 13, 1, 1),
    "painting_teal": ("ind", 19, 14, 1, 1),
    "painting_wide": ("ind", 20, 12, 2, 1),
    "painting_map": ("ind", 20, 14, 2, 1),
    "portrait_tall": ("ind", 19, 15, 1, 2),
    "portrait_tall2": ("ind", 20, 15, 1, 2),
    "mirror_tall": ("ind", 22, 14, 1, 2),
    "plant": ("ind", 16, 0, 1, 1),
    "plant2": ("ind", 17, 0, 1, 1),
    "candelabra": ("ind", 20, 0, 1, 1),
    "window": ("rpg", 42, 0, 1, 1),
    "window_arch": ("rpg", 44, 2, 1, 2),
    # 식당, 주방
    "table_long": ("ind", 4, 7, 4, 1),
    "table_big": ("ind", 0, 0, 3, 2),
    "table_round": ("ind", 7, 0, 1, 1),
    "table_small": ("ind", 5, 2, 1, 1),
    "chair_down": ("ind", 0, 2, 1, 1),
    "chair_up": ("ind", 1, 2, 1, 1),
    "chair_right": ("ind", 2, 2, 1, 1),
    "chair_left": ("ind", 3, 2, 1, 1),
    "counter": ("ind", 0, 12, 1, 1),
    "counter_drawers": ("ind", 1, 13, 1, 1),
    "counter_sink": ("ind", 8, 12, 1, 1),
    "counter_fruit": ("ind", 5, 12, 1, 1),
    "counter_bottles": ("ind", 6, 12, 1, 1),
    "counter_dishes": ("ind", 7, 12, 1, 1),
    "stove": ("ind", 14, 14, 1, 2),
    "hanging_pans": ("rpg", 31, 3, 1, 1),
    "hanging_pan_one": ("rpg", 31, 4, 1, 1),
    "wine_rack": ("rpg", 29, 2, 1, 1),
    # 침실, 서재
    "wardrobe": ("rpg", 28, 3, 1, 2),
    "vanity": ("rpg", 29, 3, 1, 2),
    "dresser": ("rpg", 24, 5, 1, 1),
    "nightstand": ("rpg", 23, 6, 1, 1),
    "cabinet_tall": ("rpg", 26, 5, 1, 2),
    "safe": ("rpg", 26, 7, 1, 1),
    "globe_statue": ("rpg", 42, 10, 1, 1),
    # 창고
    "shelf_empty": ("rpg", 48, 13, 1, 1),
    "shelf_full": ("rpg", 48, 14, 1, 1),
    "chest": ("rpg", 37, 9, 1, 1),
    "clothesline": ("ind", 16, 1, 3, 2),
    # 바깥
    "hedge": ("rpg", 20, 10, 1, 1),
    "hedge_l": ("rpg", 19, 10, 1, 1),
    "hedge_r": ("rpg", 21, 10, 1, 1),
    "bush": ("rpg", 19, 9, 1, 1),
    "tree": ("rpg", 16, 10, 1, 2),
    "tree_round": ("rpg", 14, 9, 1, 1),
    "flowers": ("rpg", 28, 9, 1, 1),
}


def build_props():
    s = Shelf(256)
    for name, (sh, c, r, w, h) in PROPS_KENNEY.items():
        s.add(name, block(SHEETS[sh], c, r, w, h))
    s.add("bookshelf", stack(RPG, [(48, 12), (48, 14)]))
    s.add("bookshelf2", stack(RPG, [(49, 12), (49, 14)]))
    s.add("shelf_tall", stack(RPG, [(48, 13), (48, 13)]))
    drawn = {
        "shutter_front": draw.shutter_h(), "shutter_back": draw.shutter_v(),
        "shutter_window": draw.shutter_window(), "shutter_window_small": draw.shutter_window(16, 16),
        "door_front_open": draw.door_front_open(), "door_back_open": draw.door_back_open(),
        "door_side": draw.door_side("closed"), "door_side_open": draw.door_side("open"),
        "door_side_latched": draw.door_side("latched"),
        "console": draw.security_console(), "console_open": draw.security_console_open(),
        "cctv": draw.cctv_desk(), "cctv_off": draw.cctv_desk_off(),
        "tv_on": draw.tv(True), "tv_off": draw.tv(False),
        "boiler": draw.boiler(), "chute": draw.chute_grate(False), "chute_open": draw.chute_grate(True),
        "tool_cabinet": draw.tool_cabinet("locked"), "tool_cabinet_open": draw.tool_cabinet("open"),
        "tool_cabinet_broken": draw.tool_cabinet("broken"),
        "washer": draw.washer(), "bathtub": draw.bathtub(), "toilet": draw.toilet(),
        "basin": draw.basin(), "med_cabinet": draw.med_cabinet(), "fridge": draw.fridge(),
        "stairs_up": draw.stairs("up"), "stairs_down": draw.stairs("down"),
        "bulb_on": draw.ceiling_bulb(True), "bulb_off": draw.ceiling_bulb(False),
        "boxes": draw.boxes(), "coal": draw.coal_pile(), "bag": draw.bag(), "ramen": draw.ramen(),
        "newspaper": draw.paper_thing("newspaper"), "card": draw.paper_thing("card"),
        "note": draw.paper_thing("note"), "calendar": draw.calendar(),
        "photo_wedding": draw.photo_frame("wedding"), "photo_family": draw.photo_frame("family"),
        "bed": draw.bed(False, "green"), "bed_double": draw.bed(True, "orange"),
        "bed_messy": draw.bed(False, "cream", messy=True),
    }
    for k in ("jewelry_box", "compact", "glass", "glasses", "tape", "knife_block", "knife_block_empty",
              "oil", "gloves", "rope", "flashlight", "crowbar", "jack", "silver_candle", "sandwich",
              "whiskey", "pills"):
        drawn["on_" + k] = draw.drawer_item(k)
    for name, img in drawn.items():
        s.add(name, img)
    return s.save("props")


ITEMS = ["lockpick", "flashlight", "tape", "compact", "fingerprint", "knife", "pan", "rope", "gloves",
         "oil", "pills", "sandwich", "whiskey", "crowbar", "jack", "bulb", "diary", "memo", "photo",
         "card", "manual", "newspaper", "necklace", "gold", "cash", "silver_candle", "watch"]


def build_items():
    g = Grid(8)
    for k in ITEMS:
        g.add(k, draw.item_icon(k))
    return g.save("items")


def build_chars():
    meta = {}
    sheet = Image.new("RGBA", (chars.W * 12, chars.H * len(chars.CAST)), (0, 0, 0, 0))
    for i, (name, spec) in enumerate(chars.CAST.items()):
        sheet.alpha_composite(chars.sheet(spec), (0, i * chars.H))
        meta[name] = [0, i * chars.H, chars.W, chars.H]
    sheet.save(os.path.join(OUT, "chars.png"))
    return meta


def build_portraits():
    sh = portraits.sheet()
    sh.save(os.path.join(OUT, "portraits.png"))
    meta = {}
    for r, name in enumerate(portraits.CAST):
        for c, ex in enumerate(portraits.EXPRS[name]):
            meta["%s_%s" % (name, ex)] = [c * portraits.S, r * portraits.S, portraits.S, portraits.S]
    return meta


def build_icon():
    """창 아이콘: 도둑 얼굴."""
    face = portraits.draw(portraits.CAST["thief"], "smile")
    icon = Image.new("RGBA", (64, 64), (37, 33, 43, 255))
    icon.alpha_composite(face.resize((64, 64), Image.NEAREST))
    icon.save(os.path.join(OUT, "icon.png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    all_meta = {
        "tiles": build_tiles(), "props": build_props(), "items": build_items(),
        "chars": build_chars(), "portraits": build_portraits(),
    }
    build_icon()
    with open(os.path.join(OUT, "atlas.json"), "w", encoding="utf-8") as f:
        json.dump(all_meta, f, ensure_ascii=False, separators=(",", ":"))
    n_walls = len([k for k in all_meta["tiles"] if k.startswith("wall_")])
    print("tiles", len(all_meta["tiles"]) - 1, "(walls %d)" % n_walls, "props", len(all_meta["props"]),
          "items", len(all_meta["items"]), "chars", len(all_meta["chars"]), "portraits", len(all_meta["portraits"]))


if __name__ == "__main__":
    main()
