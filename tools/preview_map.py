"""지도 미리보기: data/map.txt + data/objects.json 을 게임과 같은 규칙으로 그린다.

    python tools/preview_map.py <out_dir> [--grid]
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = 16
FLOOR_TILE = {".": "floor_wood", ",": "floor_tile", ":": "floor_plank", "_": "floor_stone",
              "g": "grass", "p": "dirt", "B": "floor_tile", "O": "floor_wood"}
WALL_SET = {"1F": "beige", "2F": "beige", "B1": "grey"}


def load_map():
    floors, name = {}, None
    for line in open(os.path.join(ROOT, "data", "map.txt"), encoding="utf-8"):
        line = line.rstrip("\n")
        if line.startswith("[") and line.endswith("]"):
            name = line[1:-1]
            floors[name] = []
        elif name is not None and line.strip() != "" or (name and floors[name] and line == ""):
            floors[name].append(line)
    for k in floors:
        while floors[k] and floors[k][-1].strip() == "":
            floors[k].pop()
        w = max(len(r) for r in floors[k])
        floors[k] = [r.ljust(w) for r in floors[k]]
    return floors


def cell(rows, x, y):
    if 0 <= y < len(rows) and 0 <= x < len(rows[y]):
        return rows[y][x]
    return " "


def floor_for(rows, x, y):
    ch = cell(rows, x, y)
    if ch in FLOOR_TILE:
        return FLOOR_TILE[ch]
    if ch == "D":
        counts = {}
        for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0), (0, 2), (0, -2), (0, 3), (0, -3)):
            c = cell(rows, x + dx, y + dy)
            if c in FLOOR_TILE:
                counts[c] = counts.get(c, 0) + 1
        if counts:
            return FLOOR_TILE[max(counts, key=counts.get)]
        return "floor_wood"
    return None


def wall_mask(rows, x, y):
    def w(dx, dy):
        return cell(rows, x + dx, y + dy) == "#"
    bits = [w(0, -1), w(1, 0), w(0, 1), w(-1, 0), w(1, -1), w(1, 1), w(-1, 1), w(-1, -1),
            cell(rows, x, y + 1) == "F"]
    return sum(1 << i for i, b in enumerate(bits) if b)


def face_name(rows, x, y, set_name):
    lower = cell(rows, x, y - 1) == "F"
    le = cell(rows, x - 1, y) != "F"
    re = cell(rows, x + 1, y) != "F"
    return "face_%s_%s%s%s" % (set_name, "lo" if lower else "up", "_l" if le else "", "_r" if re else "")


def render_floor(fname, rows, atlas, sheets, objects, grid=False):
    tiles = atlas["tiles"]
    h, w = len(rows), len(rows[0])
    img = Image.new("RGBA", (w * T, h * T), (0, 0, 0, 255))
    set_name = WALL_SET[fname]

    def blit(sheet, rect, px, py):
        x, y, ww, hh = rect
        img.alpha_composite(sheets[sheet].crop((x, y, x + ww, y + hh)), (px, py))

    for y in range(h):
        for x in range(w):
            ch = rows[y][x]
            name = floor_for(rows, x, y)
            if ch == "g" and (x * 7 + y * 13) % 5 == 0:
                name = "grass2"
            if name:
                blit("tiles", tiles[name], x * T, y * T)
            elif ch == "#":
                blit("tiles", tiles[tiles["_walls"]["%s:%d" % (set_name, wall_mask(rows, x, y))]], x * T, y * T)
            elif ch == "F":
                blit("tiles", tiles[face_name(rows, x, y, set_name)], x * T, y * T)
    order = {"floor": 0, "wall": 1, "obj": 2, "top": 3}
    objs = [o for o in objects if o["f"] == fname and o.get("s")]
    objs.sort(key=lambda o: (0 if o.get("l") in ("floor", "wall") else 1, order[o.get("l", "obj")] if o.get("l") in ("floor", "wall") else 0,
                             o["y"] + o.get("h", 1), order.get(o.get("l", "obj"), 2)))
    for o in objs:
        rect = atlas["props"].get(o["s"])
        if rect is None:
            print("missing sprite", o["s"])
            continue
        px = o["x"] * T
        py = (o["y"] + o.get("h", 1)) * T - rect[3]
        blit("props", rect, px, py)
    if grid:
        d = ImageDraw.Draw(img)
        try:
            font = ImageFont.truetype("arial.ttf", 7)
        except Exception:
            font = ImageFont.load_default()
        for x in range(0, w, 1):
            d.text((x * T + 2, 1), str(x), fill=(255, 255, 0, 255), font=font)
        for y in range(0, h, 1):
            d.text((1, y * T + 4), str(y), fill=(0, 255, 255, 255), font=font)
    return img


def main():
    out = sys.argv[1]
    grid = "--grid" in sys.argv
    atlas = json.load(open(os.path.join(ROOT, "assets", "art", "atlas.json"), encoding="utf-8"))
    sheets = {k: Image.open(os.path.join(ROOT, "assets", "art", k + ".png")).convert("RGBA") for k in ("tiles", "props")}
    objects = json.load(open(os.path.join(ROOT, "data", "objects.json"), encoding="utf-8"))
    ids = [o["id"] for o in objects]
    dup = {i for i in ids if ids.count(i) > 1}
    if dup:
        print("duplicate ids", dup)
    floors = load_map()
    os.makedirs(out, exist_ok=True)
    for fname, rows in floors.items():
        img = render_floor(fname, rows, atlas, sheets, objects, grid)
        scale = 3
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
        path = os.path.join(out, "map_%s.png" % fname)
        img.save(path)
        print(path, img.size)


if __name__ == "__main__":
    main()
