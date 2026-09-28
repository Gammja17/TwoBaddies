"""VARCO 로 뽑은 시트(_packs/varco/<id>.png)를 게임 크기 그림으로 잘라 art_src/ 에 둔다.

    python tools/varco_cut.py            # 전부
    python tools/varco_cut.py P3 C1      # 몇 장만

자르는 규칙은 tools/art_manifest.py. 결과는 build_art.py 가 아틀라스로 묶는다.
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import art_manifest as M  # noqa: E402

ROOT = os.path.dirname(HERE)
RAW = os.path.join(ROOT, "_packs", "varco")
OUT = os.path.join(ROOT, "art_src")


# ---------------------------------------------------------------- 공통 ----

def load(sid):
    return Image.open(os.path.join(RAW, sid + ".png")).convert("RGB")


def magenta_mask(img):
    """자홍 배경(그리고 자홍이 섞인 가장자리)을 True 로."""
    a = np.asarray(img).astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    return (r > 150) & (b > 150) & (g < 120) & (np.abs(r - b) < 90)


def cut_rgba(img, mask_bg):
    a = np.asarray(img).astype(np.uint8)
    alpha = np.where(mask_bg, 0, 255).astype(np.uint8)
    # 자홍이 번진 테두리: 가까운 불투명 색으로 칠하지 않고 어둡게 눌러 윤곽선처럼 보이게
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    spill = (~mask_bg) & (r > g + 50) & (b > g + 50)
    out = np.dstack([a, alpha])
    out[spill, 0:3] = (out[spill, 0:3] * 0.35).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def shrink(img, w, h):
    """비율대로 줄이고(투명 가장자리 번짐 없이) 알파를 딱 끊는다."""
    small = img.convert("RGBa").resize((max(1, w), max(1, h)), Image.LANCZOS).convert("RGBA")
    a = np.asarray(small).copy()
    a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
    return Image.fromarray(a, "RGBA")


def reduce_colors(img, n=32):
    alpha = img.getchannel("A")
    # MEDIANCUT 는 드문 색을 엉뚱한 색(회색 밑창이 연두색)으로 섞어 버려서 MAXCOVERAGE 를 쓴다
    rgb = img.convert("RGB").quantize(colors=n, method=Image.MAXCOVERAGE, dither=Image.NONE).convert("RGBA")
    rgb.putalpha(alpha)
    a = np.asarray(rgb).copy()
    a[a[..., 3] == 0] = 0
    return Image.fromarray(a, "RGBA")


def components(mask_fg, n_cells, cols, rows, shape):
    """앞면 덩어리를 찾아 격자 칸마다 모은다. 칸 번호 -> 덩어리 bbox 목록."""
    grown = ndimage.binary_dilation(mask_fg, iterations=6)
    lab, n = ndimage.label(grown)
    H, W = shape
    cells = {i: [] for i in range(n_cells)}
    for idx, sl in enumerate(ndimage.find_objects(lab)):
        if sl is None:
            continue
        ys, xs = sl
        area = int((lab[sl] == idx + 1).sum())
        if area < 400:
            continue
        cy = (ys.start + ys.stop) / 2
        cx = (xs.start + xs.stop) / 2
        c = min(cols - 1, int(cx / W * cols))
        r = min(rows - 1, int(cy / H * rows))
        cells[r * cols + c].append((area, xs.start, ys.start, xs.stop, ys.stop))
    return cells


def crop_cell(rgba, boxes):
    """칸에 모인 덩어리를 하나로 묶어 자른다 (가장 큰 덩어리와 그 곁의 것들)."""
    boxes = sorted(boxes, reverse=True)
    _, x0, y0, x1, y1 = boxes[0]
    for _, a0, b0, a1, b1 in boxes[1:]:
        # 큰 덩어리에서 멀리 떨어진 부스러기는 버린다
        if a1 < x0 - 40 or a0 > x1 + 40 or b1 < y0 - 40 or b0 > y1 + 40:
            continue
        x0, y0, x1, y1 = min(x0, a0), min(y0, b0), max(x1, a1), max(y1, b1)
    piece = rgba.crop((x0, y0, x1, y1))
    bb = piece.getbbox()
    return piece.crop(bb) if bb else piece


def place(piece, bw, bh, mode):
    """상자에 넣는다."""
    canvas = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
    pw, ph = piece.size
    if mode == "on":
        s = min(20 / pw, 20 / ph)
        w, h = max(1, round(pw * s)), max(1, round(ph * s))
        small = reduce_colors(shrink(piece, w, h), 24)
        canvas.alpha_composite(small, ((bw - w) // 2, 25 - h))
        return canvas
    if mode == "on_high":
        # 키 큰 가구(세탁기) 윗면에 기대 놓은 것: 윗면 조금 위까지 올라오게 (상자 높이 44 기준)
        small = reduce_colors(shrink(piece, 20, 16), 24)
        canvas.alpha_composite(small, ((bw - 20) // 2, 0))
        return canvas
    if mode == "span":
        s = bw / pw
        w, h = bw, min(bh, max(1, round(ph * s)))
    else:
        s = min(bw / pw, bh / ph)
        w, h = max(1, round(pw * s)), max(1, round(ph * s))
    small = reduce_colors(shrink(piece, w, h), 40)
    x = (bw - w) // 2
    y = bh - h if mode in ("fit", "wall", "span") else (bh - h) // 2
    canvas.alpha_composite(small, (x, y))
    return canvas


def save(img, *parts):
    path = os.path.join(OUT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)


# ---------------------------------------------------------------- 가구, 아이콘 ----

def cut_grid(sid, entries, cols, rows, sub, size_fn):
    img = load(sid)
    bg = magenta_mask(img)
    rgba = cut_rgba(img, bg)
    cells = components(~bg, cols * rows, cols, rows, bg.shape)
    done = 0
    for i, e in enumerate(entries):
        name = e[0] if isinstance(e, tuple) else e
        if name is None:
            continue
        if not cells[i]:
            print("  !! %s 칸 %d (%s) 이 비었다" % (sid, i, name))
            continue
        piece = crop_cell(rgba, cells[i])
        save(size_fn(piece, e), sub, name + ".png")
        done += 1
    print("%s: %d개" % (sid, done))


def cut_props(sid):
    cols, rows = M.GRIDS.get(sid, (4, 3))
    def prop(piece, e):
        if len(e) > 4 and e[4] == "left_half":
            piece = piece.crop((0, 0, piece.width // 2, piece.height))
            piece = piece.crop(piece.getbbox())
        return place(piece, e[1], e[2], e[3])
    cut_grid(sid, M.PROPS[sid], cols, rows, "props", prop)


def cut_icons(sid):
    def icon(piece, _e):
        return place(piece, M.ICON, M.ICON, "floor")
    cut_grid(sid, M.ICONS[sid], 4, 4, "icons", icon)
    # 아이콘 시트에서 세상에 놓을 소품도 자른다
    extra = M.ICON_PROPS.get(sid, [])
    if extra:
        entries = [None] * 16
        for i, name, bw, bh, mode in extra:
            entries[i] = (name, bw, bh, mode)
        cut_grid(sid, entries, 4, 4, "props", lambda p, e: place(p, e[1], e[2], e[3]))


# ---------------------------------------------------------------- 인물 ----

def cut_chars(sid, variant=0):
    """4줄 x 3칸(서기, 왼발, 오른발) 시트 -> 아래, 왼쪽, 오른쪽, 위 순서로 32x48 프레임 12개를 한 줄로."""
    who = M.CHARS[sid]
    name = sid if variant == 0 else "%s_%d" % (sid, variant)
    img = load(name)
    bg = magenta_mask(img)
    rgba = cut_rgba(img, bg)
    cells = components(~bg, 12, 3, 4, bg.shape)
    pieces = []
    for d in ("down", "left", "right", "up"):
        row, flip = M.CHAR_ROWS[sid][d]
        for col in range(3):
            i = row * 3 + col
            if not cells[i]:
                print("  !! %s 칸 %d 이 비었다" % (name, i))
                return
            p = crop_cell(rgba, cells[i])
            pieces.append(p.transpose(Image.FLIP_LEFT_RIGHT) if flip else p)
    # 모든 프레임에 같은 배율 (가장 큰 키를 44px 에 맞춘다)
    tallest = max(p.height for p in pieces)
    s = 44 / tallest
    sheet = Image.new("RGBA", (M.CHAR_W * 12, M.CHAR_H), (0, 0, 0, 0))
    for i, p in enumerate(pieces):
        w, h = max(1, round(p.width * s)), max(1, round(p.height * s))
        small = reduce_colors(shrink(p, w, h), 28)
        # 가운데는 머리와 몸통(위쪽 60%)의 가운데로 맞춰 걸음마다 흔들리지 않게
        a = np.asarray(small)[..., 3]
        top = a[: max(1, int(h * 0.6))]
        xs = np.where(top.max(axis=0) > 0)[0]
        cx = (xs.min() + xs.max()) / 2 if len(xs) else w / 2
        x = int(round(M.CHAR_W / 2 - cx))
        frame = Image.new("RGBA", (M.CHAR_W, M.CHAR_H), (0, 0, 0, 0))
        frame.alpha_composite(small, (max(0, min(M.CHAR_W - w, x)) if w <= M.CHAR_W else 0, M.CHAR_H - h))
        sheet.alpha_composite(frame, (i * M.CHAR_W, 0))
    save(sheet, "chars", who + ".png")
    print("%s: %s 걷기 12프레임" % (name, who))


# ---------------------------------------------------------------- 얼굴 ----

def cut_portraits(sid):
    who, exprs = M.PORTRAITS[sid]
    img = load(sid).convert("RGBA")
    W, H = img.size
    for i, ex in enumerate(exprs):
        c, r = i % 2, i // 2
        cell = img.crop((c * W // 2, r * H // 2, (c + 1) * W // 2, (r + 1) * H // 2))
        m = cell.width // 20
        cell = cell.crop((m, m, cell.width - m, cell.height - m))
        face = reduce_colors(cell.resize((M.FACE, M.FACE), Image.LANCZOS), 40)
        save(face, "portraits", "%s_%s.png" % (who, ex))
    print("%s: %s 얼굴 %d개" % (sid, who, len(exprs)))


# ---------------------------------------------------------------- 바닥, 벽 ----

def cut_floors(sid):
    img = load(sid)
    W, H = img.size
    for i, name in enumerate(M.FLOORS[sid]):
        if name is None:
            continue
        c, r = i % 2, i // 2
        q = img.crop((c * W // 2, r * H // 2, (c + 1) * W // 2, (r + 1) * H // 2))
        m = q.width // 64   # 칸 경계의 이음새를 조금 걷어 낸다
        q = q.crop((m, m, q.width - m, q.height - m))
        t = q.resize((M.FLOOR_PX, M.FLOOR_PX), Image.LANCZOS).convert("RGBA")
        save(reduce_colors(t, 24), "tiles", name + ".png")
    print("%s: 바닥 %d개" % (sid, len([n for n in M.FLOORS[sid] if n])))


def cut_walls(sid):
    img = load(sid)
    W, H = img.size
    names = M.WALLS[sid]
    if sid == "tex_a":
        bands = [img.crop((W // 2, 0, W, H // 2))]
    else:
        bands = [img.crop((0, r * H // 4, W, (r + 1) * H // 4)) for r in range(4)]
    for name, band in zip(names, bands):
        m = band.height // 40
        band = band.crop((0, m, band.width, band.height - m))
        w = round(band.width * M.WALL_H / band.height)
        t = band.resize((w, M.WALL_H), Image.LANCZOS)
        # 가로로 이어 붙일 수 있게 256px 로 자른다
        t = t.crop((0, 0, M.WALL_W, M.WALL_H)) if w >= M.WALL_W else t.resize((M.WALL_W, M.WALL_H), Image.LANCZOS)
        save(reduce_colors(t.convert("RGBA"), 24), "tiles", name + ".png")
    print("%s: 벽 %d개" % (sid, len(names)))


def cut_title():
    # 두 장 가운데 왼쪽 하늘이 넓어 제목 자리가 나는 두 번째 것
    img = load("TITLE_1")
    t = img.resize((640, 360), Image.LANCZOS).convert("RGBA")
    save(reduce_colors(t, 64), "title_bg.png")
    print("TITLE: 첫 화면")


def main():
    want = sys.argv[1:]

    def on(sid):
        return (not want or sid in want) and os.path.exists(os.path.join(RAW, sid + ".png"))

    for sid in M.PROPS:
        if on(sid):
            cut_props(sid)
    for sid in M.ICONS:
        if on(sid):
            cut_icons(sid)
    for sid in M.CHARS:
        if on(sid):
            cut_chars(sid)
    for sid in M.PORTRAITS:
        if on(sid):
            cut_portraits(sid)
    for sid in M.FLOORS:
        if on(sid):
            cut_floors(sid)
    for sid in M.WALLS:
        if on(sid) and sid != "tex_a" or (sid == "tex_a" and on("tex_a")):
            cut_walls(sid)
    if on("TITLE"):
        cut_title()


if __name__ == "__main__":
    main()
