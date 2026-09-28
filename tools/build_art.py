"""게임용 아틀라스를 만든다. 칸은 32px.

그림은 art_src/ (VARCO 로 뽑아 tools/varco_cut.py 로 자른 것)를 먼저 쓰고,
없는 것은 Kenney 원본(_packs/)과 직접 그린 16px 그림을 두 배로 키워 채운다.

결과: assets/art/{tiles,props,items,chars,portraits}.png, title_bg.png, icon.png, atlas.json
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
SRC = os.path.join(ROOT, "art_src")
OUT = os.path.join(ROOT, "assets", "art")
T = 16          # 옛 원본 칸
TT = 32         # 게임 칸


def load(*parts):
    return Image.open(os.path.join(PACKS, *parts)).convert("RGBA")


def src(*parts):
    path = os.path.join(SRC, *parts)
    return Image.open(path).convert("RGBA") if os.path.exists(path) else None


def up(img, k=2):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)


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
    img = Image.new("RGBA", (T, T * len(cells)), (0, 0, 0, 0))
    for i, (c, r) in enumerate(cells):
        img.alpha_composite(tile(sheet, c, r), (0, i * T))
    return img


# ---------------------------------------------------------------- 벽 윗면 ----

WALL_TOPS = {
    "house": {"top": (76, 60, 54), "rim": (104, 84, 72), "line": (30, 22, 24), "face": (52, 40, 38)},
    "cellar": {"top": (70, 70, 78), "rim": (98, 98, 108), "line": (24, 24, 30), "face": (48, 48, 56)},
}


def wall_top(pal, m):
    """m: 이웃 벽 여부 dict(n,e,s,w,ne,se,sw,nw) 와 sface(아래가 벽면인지). 32px."""
    img = Image.new("RGBA", (TT, TT), pal["top"] + (255,))
    p = img.load()

    def fill(x0, y0, x1, y1, col):
        for y in range(max(0, y0), min(TT - 1, y1) + 1):
            for x in range(max(0, x0), min(TT - 1, x1) + 1):
                p[x, y] = col + (255,)
    e = TT - 1
    if not m["n"]:
        fill(0, 2, e, 5, pal["rim"])
    if not m["s"]:
        fill(0, e - 5, e, e - 2, pal["rim"])
    if not m["w"]:
        fill(2, 0, 5, e, pal["rim"])
    if not m["e"]:
        fill(e - 5, 0, e - 2, e, pal["rim"])
    for (a, b, c, x0, y0) in (("n", "w", "nw", 0, 0), ("n", "e", "ne", e - 5, 0),
                              ("s", "w", "sw", 0, e - 5), ("s", "e", "se", e - 5, e - 5)):
        if m[a] and m[b] and not m[c]:
            fill(x0, y0, x0 + 5, y0 + 5, pal["rim"])
    if not m["n"]:
        fill(0, 0, e, 1, pal["line"])
    if not m["s"]:
        fill(0, e - 1, e, e, pal["face"] if m["sface"] else pal["line"])
    if not m["w"]:
        fill(0, 0, 1, e, pal["line"])
    if not m["e"]:
        fill(e - 1, 0, e, e, pal["line"])
    for (a, b, c, x0, y0) in (("n", "w", "nw", 0, 0), ("n", "e", "ne", e - 1, 0),
                              ("s", "w", "sw", 0, e - 1), ("s", "e", "se", e - 1, e - 1)):
        if m[a] and m[b] and not m[c]:
            fill(x0, y0, x0 + 1, y0 + 1, pal["line"])
    return img


# ---------------------------------------------------------------- 그늘 ----

def shade(bits_n, bits_w, bits_e, face=False):
    """바닥 칸: 위(벽면 아래)와 옆 벽 쪽을 어둡게. 벽면 칸: 양 끝을 어둡게."""
    img = Image.new("RGBA", (TT, TT), (0, 0, 0, 0))
    p = img.load()
    for y in range(TT):
        for x in range(TT):
            a = 0
            if face:
                if bits_w:
                    a = max(a, [150, 110, 80, 50, 25][x] if x < 5 else 0)
                if bits_e:
                    xx = TT - 1 - x
                    a = max(a, [150, 110, 80, 50, 25][xx] if xx < 5 else 0)
            else:
                if bits_n and y < 10:
                    a = max(a, int(120 * (1 - y / 10)))
                if bits_w and x < 6:
                    a = max(a, int(90 * (1 - x / 6)))
                if bits_e and x > TT - 7:
                    a = max(a, int(90 * (1 - (TT - 1 - x) / 6)))
            if a:
                p[x, y] = (8, 6, 14, a)
    return img


# ---------------------------------------------------------------- 아틀라스 ----

class Grid:
    """32px 칸 아틀라스 (타일)."""

    def __init__(self, cols, cell=TT):
        self.cols = cols
        self.cell = cell
        self.items = []

    def add(self, name, img):
        self.items.append((name, img))

    def save(self, stem):
        c = self.cell
        rows = (len(self.items) + self.cols - 1) // self.cols
        sheet = Image.new("RGBA", (self.cols * c, rows * c), (0, 0, 0, 0))
        meta = {}
        for i, (name, img) in enumerate(self.items):
            x, y = (i % self.cols) * c, (i // self.cols) * c
            sheet.alpha_composite(img, (x, y))
            meta[name] = [x, y, c, c]
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


# 바닥 무늬 (art_src/tiles/<이름>.png 128x128, 없으면 옛 16px 타일)
FLOORS = {
    "floor_parquet": (RPG, 5, 2), "floor_honey": (RPG, 5, 2), "floor_marble": (RPG, 6, 2),
    "floor_carpet": (RPG, 8, 2), "floor_worn": (RPG, 8, 2), "floor_walnut": (RPG, 8, 2),
    "floor_checker": (RPG, 6, 2), "floor_bath": (RPG, 6, 2), "floor_lino": (RPG, 6, 2),
    "floor_slab": (RPG, 6, 3), "floor_concrete": (RPG, 6, 3), "grass": (RPG, 5, 0), "dirt": (RPG, 6, 0),
}
# 벽면 무늬 (art_src/tiles/<이름>.png 256x64)
WALLS = ["wall_stripe", "wall_burgundy", "wall_beige", "wall_subway", "wall_rose", "wall_green",
         "wall_mustard", "wall_bluetile", "wall_paint", "wall_brick", "wall_soot"]


def floor_pattern(name):
    img = src("tiles", name + ".png")
    if img is not None:
        return img
    sheet, c, r = FLOORS[name]
    one = up(tile(sheet, c, r))
    pat = Image.new("RGBA", (TT * 4, TT * 4))
    for y in range(4):
        for x in range(4):
            pat.alpha_composite(one, (x * TT, y * TT))
    return pat


def wall_pattern(name):
    img = src("tiles", name + ".png")
    if img is not None:
        return img
    # 없으면 밋밋한 벽지와 걸레받이
    pat = Image.new("RGBA", (TT * 8, TT * 2), (150, 132, 112, 255))
    for x in range(TT * 8):
        for y in range(TT * 2 - 12, TT * 2):
            pat.putpixel((x, y), (96, 70, 52, 255))
    return pat


def build_tiles():
    g = Grid(32)
    g.add("void", Image.new("RGBA", (TT, TT), (0, 0, 0, 255)))
    for name in FLOORS:
        pat = floor_pattern(name)
        for i in range(16):
            x, y = (i % 4) * TT, (i // 4) * TT
            g.add("%s_%d" % (name, i), pat.crop((x, y, x + TT, y + TT)))
    for name in WALLS:
        pat = wall_pattern(name)
        for i in range(16):
            x, y = (i % 8) * TT, (i // 8) * TT
            g.add("%s_%d" % (name, i), pat.crop((x, y, x + TT, y + TT)))
    walls = {}
    for set_name, pal in WALL_TOPS.items():
        seen = {}
        for mask in range(512):
            m = {k: bool(mask >> i & 1) for i, k in enumerate(("n", "e", "s", "w", "ne", "se", "sw", "nw", "sface"))}
            img = wall_top(pal, m)
            key = img.tobytes()
            if key not in seen:
                seen[key] = "top_%s_%d" % (set_name, len(seen))
                g.add(seen[key], img)
            walls["%s:%d" % (set_name, mask)] = seen[key]
    for bits in range(1, 8):
        g.add("shade_%d" % bits, shade(bits & 1, bits & 2, bits & 4))
    for bits in range(1, 4):
        g.add("fshade_%d" % bits, shade(0, bits & 1, bits & 2, face=True))
    meta = g.save("tiles")
    meta["_walls"] = walls
    meta["_size"] = TT
    return meta


PROPS_KENNEY = {
    "fireplace": ("rpg", 54, 9, 1, 2), "piano": ("ind", 23, 8, 2, 2), "sofa": ("ind", 23, 11, 2, 3),
    "armchair": ("ind", 25, 11, 1, 2), "armchair_green": ("ind", 25, 15, 1, 2),
    "rug_orange": ("ind", 0, 9, 3, 2), "rug_round": ("ind", 19, 8, 2, 1), "runner": ("ind", 5, 9, 1, 3),
    "runner_green": ("ind", 12, 9, 1, 3), "cuckoo_clock": ("rpg", 26, 8, 1, 1),
    "painting_green": ("ind", 19, 12, 1, 1), "painting_orange": ("ind", 19, 13, 1, 1),
    "painting_teal": ("ind", 19, 14, 1, 1), "painting_wide": ("ind", 20, 12, 2, 1),
    "painting_map": ("ind", 20, 14, 2, 1), "portrait_tall": ("ind", 19, 15, 1, 2),
    "portrait_tall2": ("ind", 20, 15, 1, 2), "mirror_tall": ("ind", 22, 14, 1, 2),
    "plant": ("ind", 16, 0, 1, 1), "plant2": ("ind", 17, 0, 1, 1), "candelabra": ("ind", 20, 0, 1, 1),
    "window": ("rpg", 42, 0, 1, 1), "window_arch": ("rpg", 44, 2, 1, 2),
    "table_long": ("ind", 4, 7, 4, 1), "table_big": ("ind", 0, 0, 3, 2), "table_round": ("ind", 7, 0, 1, 1),
    "table_small": ("ind", 5, 2, 1, 1), "chair_down": ("ind", 0, 2, 1, 1), "chair_up": ("ind", 1, 2, 1, 1),
    "chair_right": ("ind", 2, 2, 1, 1), "chair_left": ("ind", 3, 2, 1, 1), "counter": ("ind", 0, 12, 1, 1),
    "counter_drawers": ("ind", 1, 13, 1, 1), "counter_sink": ("ind", 8, 12, 1, 1),
    "counter_fruit": ("ind", 5, 12, 1, 1), "counter_bottles": ("ind", 6, 12, 1, 1),
    "counter_dishes": ("ind", 7, 12, 1, 1), "stove": ("ind", 14, 14, 1, 2), "hanging_pans": ("rpg", 31, 3, 1, 1),
    "hanging_pan_one": ("rpg", 31, 4, 1, 1), "wardrobe": ("rpg", 28, 3, 1, 2), "vanity": ("rpg", 29, 3, 1, 2),
    "dresser": ("rpg", 24, 5, 1, 1), "nightstand": ("rpg", 23, 6, 1, 1), "cabinet_tall": ("rpg", 26, 5, 1, 2),
    "safe": ("rpg", 26, 7, 1, 1), "globe_statue": ("rpg", 42, 10, 1, 1), "chest": ("rpg", 37, 9, 1, 1),
    "clothesline": ("ind", 16, 1, 3, 2), "hedge": ("rpg", 20, 10, 1, 1), "hedge_l": ("rpg", 19, 10, 1, 1),
    "hedge_r": ("rpg", 21, 10, 1, 1), "bush": ("rpg", 19, 9, 1, 1), "tree": ("rpg", 16, 10, 1, 2),
    "tree_round": ("rpg", 14, 9, 1, 1), "flowers": ("rpg", 28, 9, 1, 1),
}
# VARCO 로만 있는 것 (옛 그림이 없다)
PROPS_NEW = ["floor_lamp", "sconce", "table_lamp", "coat_stand", "shoe_rack", "umbrella_stand", "tv_off",
             "on_notepad"]
# 같은 그림을 쓰는 것
PROP_ALIAS = {"hedge_l": "hedge", "hedge_r": "hedge"}


def old_props():
    out = {}
    for name, (sh, c, r, w, h) in PROPS_KENNEY.items():
        out[name] = block(SHEETS[sh], c, r, w, h)
    out["bookshelf"] = stack(RPG, [(48, 12), (48, 14)])
    out["bookshelf2"] = stack(RPG, [(49, 12), (49, 14)])
    out["shelf_tall"] = stack(RPG, [(48, 13), (48, 13)])
    out.update({
        "shutter_front": draw.shutter_h(), "shutter_back": draw.shutter_v(),
        "shutter_window": draw.shutter_window(), "shutter_window_small": draw.shutter_window(16, 16),
        "door_front_open": draw.door_front_open(),
        "door_side": draw.door_side("closed"), "door_side_open": draw.door_side("open"),
        "door_side_latched": draw.door_side("latched"),
        "console": draw.security_console(), "console_open": draw.security_console_open(),
        "cctv": draw.cctv_desk(), "tv_on": draw.tv(True),
        "boiler": draw.boiler(), "chute": draw.chute_grate(False), "chute_open": draw.chute_grate(True),
        "tool_cabinet": draw.tool_cabinet("locked"), "tool_cabinet_open": draw.tool_cabinet("open"),
        "tool_cabinet_broken": draw.tool_cabinet("broken"),
        "washer": draw.washer(), "bathtub": draw.bathtub(), "toilet": draw.toilet(),
        "basin": draw.basin(), "med_cabinet": draw.med_cabinet(), "fridge": draw.fridge(),
        "stairs_up": draw.stairs("up"), "stairs_down": draw.stairs("down"),
        "bulb_on": draw.ceiling_bulb(True), "bulb_off": draw.ceiling_bulb(False),
        "boxes": draw.boxes(), "coal": draw.coal_pile(), "bag": draw.bag(), "ramen": draw.ramen(),
        "newspaper": draw.paper_thing("newspaper"), "card": draw.paper_thing("card"),
        "photo_wedding": draw.photo_frame("wedding"), "photo_family": draw.photo_frame("family"),
        "bed_double": draw.bed(True, "orange"), "bed_messy": draw.bed(False, "cream", messy=True),
    })
    for k in ("jewelry_box", "glass", "glasses", "tape", "knife_block", "knife_block_empty",
              "oil", "gloves", "rope", "flashlight", "crowbar", "silver_candle"):
        out["on_" + k] = draw.drawer_item(k)
    return out


def build_props():
    s = Shelf(1024)
    names = set()
    olds = old_props()
    fresh = 0
    for name in list(olds) + PROPS_NEW:
        if name in names:
            continue
        names.add(name)
        img = src("props", PROP_ALIAS.get(name, name) + ".png")
        if img is not None:
            fresh += 1
        elif name in olds:
            img = up(olds[name])
        else:
            continue
        s.add(name, img)
    print("props: VARCO %d / %d" % (fresh, len(names)))
    return s.save("props")


ITEMS = ["lockpick", "flashlight", "tape", "compact", "ash", "fingerprint", "knife", "pan", "rope", "gloves",
         "oil", "pills", "sandwich", "whiskey", "crowbar", "jack", "bulb", "diary", "memo", "photo",
         "card", "manual", "newspaper", "necklace", "gold", "cash", "silver_candle", "watch", "notebook"]
ICON = 24


def build_items():
    g = Grid(8, ICON)
    for k in ITEMS:
        img = src("icons", k + ".png")
        if img is None:
            img = Image.new("RGBA", (ICON, ICON), (0, 0, 0, 0))
            img.alpha_composite(draw.item_icon(k if k not in ("ash", "notebook") else {"ash": "compact", "notebook": "memo"}[k]), (4, 4))
        g.add(k, img)
    return g.save("items")


CHAR_W, CHAR_H = 32, 48


def build_chars():
    meta = {}
    cast = ["thief", "crook"]
    sheet = Image.new("RGBA", (CHAR_W * 12, CHAR_H * len(cast)), (0, 0, 0, 0))
    for i, name in enumerate(cast):
        img = src("chars", name + ".png")
        if img is None:
            img = up(chars.sheet(chars.CAST[name]))
        sheet.alpha_composite(img, (0, i * CHAR_H))
        meta[name] = [0, i * CHAR_H, CHAR_W, CHAR_H]
    sheet.save(os.path.join(OUT, "chars.png"))
    return meta


FACE = 84


def build_portraits():
    meta = {}
    names = [(who, ex) for who in portraits.CAST for ex in portraits.EXPRS[who]]
    sheet = Image.new("RGBA", (FACE * 4, FACE * 2), (0, 0, 0, 0))
    for i, (who, ex) in enumerate(names):
        img = src("portraits", "%s_%s.png" % (who, ex))
        if img is None:
            img = portraits.draw(portraits.CAST[who], ex).resize((FACE, FACE), Image.NEAREST)
        x, y = (i % 4) * FACE, (i // 4) * FACE
        sheet.alpha_composite(img, (x, y))
        meta["%s_%s" % (who, ex)] = [x, y, FACE, FACE]
    sheet.save(os.path.join(OUT, "portraits.png"))
    return meta


def build_icon():
    """창 아이콘: 도둑 얼굴."""
    face = src("portraits", "thief_smile.png")
    if face is None:
        face = portraits.draw(portraits.CAST["thief"], "smile")
    icon = Image.new("RGBA", (64, 64), (37, 33, 43, 255))
    icon.alpha_composite(face.resize((64, 64), Image.LANCZOS))
    icon.save(os.path.join(OUT, "icon.png"))


def build_title():
    img = src("title_bg.png")
    if img is not None:
        img.save(os.path.join(OUT, "title_bg.png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    all_meta = {
        "tiles": build_tiles(), "props": build_props(), "items": build_items(),
        "chars": build_chars(), "portraits": build_portraits(),
    }
    build_icon()
    build_title()
    with open(os.path.join(OUT, "atlas.json"), "w", encoding="utf-8") as f:
        json.dump(all_meta, f, ensure_ascii=False, separators=(",", ":"))
    n_tops = len([k for k in all_meta["tiles"] if k.startswith("top_")])
    print("tiles", len(all_meta["tiles"]) - 2, "(wall tops %d)" % n_tops, "props", len(all_meta["props"]),
          "items", len(all_meta["items"]), "chars", len(all_meta["chars"]), "portraits", len(all_meta["portraits"]))


if __name__ == "__main__":
    main()
