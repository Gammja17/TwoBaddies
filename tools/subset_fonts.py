"""갈무리 글꼴을 가볍게 줄인다: 자주 쓰는 한글 2,350자 + 게임 글에 실제로 쓰인 글자 + 기호.

게임 글에 흔치 않은 글자(예: 똠, 뷁)를 새로 넣었으면 다시 돌린다.
    python tools/subset_fonts.py
"""
import glob
import os

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    chars = set()
    for lead in range(0xB0, 0xC9):          # KS X 1001 한글 영역
        for trail in range(0xA1, 0xFF):
            try:
                ch = bytes([lead, trail]).decode("euc_kr")
            except UnicodeDecodeError:
                continue
            if len(ch) == 1 and 0xAC00 <= ord(ch) <= 0xD7A3:
                chars.add(ch)
    for f in glob.glob(os.path.join(ROOT, "scripts", "*.gd")) + glob.glob(os.path.join(ROOT, "data", "*")):
        chars |= {c for c in open(f, encoding="utf-8").read() if ord(c) >= 0x20}
    chars |= {chr(c) for c in range(0x20, 0x7F)}
    chars |= {chr(c) for c in range(0x3131, 0x318F)}
    chars |= set("▶▼▲◀■□…'\"“”‘’")
    text = "".join(sorted(chars))
    for name in ("Galmuri14", "Galmuri11"):
        font = TTFont(os.path.join(ROOT, "_packs", "galmuri", name + ".ttf"))
        opts = subset.Options()
        opts.layout_features = ["*"]
        opts.name_IDs = ["*"]
        opts.notdef_outline = True
        sub = subset.Subsetter(opts)
        sub.populate(text=text)
        sub.subset(font)
        out = os.path.join(ROOT, "assets", "fonts", name + ".ttf")
        font.save(out)
        print(out, os.path.getsize(out), "bytes,", len(chars), "chars")


if __name__ == "__main__":
    main()
