#!/usr/bin/env python3
"""Regenerate the bundled Traditional Chinese subset from a local Noto font.

Requires fonttools. Example on Debian:
python3 tools/subset_font.py /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc
"""
import argparse
from pathlib import Path
from fontTools import subset
from fontTools.ttLib import TTFont

parser = argparse.ArgumentParser()
parser.add_argument("font", type=Path)
parser.add_argument("--font-index", type=int, default=3,
                    help="NotoSansCJK TTC: Traditional Chinese is index 3")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
sources = [*(root / "scripts").rglob("*.gd"), *(root / "data").rglob("*.tres"), root / "project.godot"]
text = "".join(p.read_text() for p in sources)
options = subset.Options()
options.name_IDs = ["*"]
font = TTFont(args.font, fontNumber=args.font_index)
subsetter = subset.Subsetter(options=options)
subsetter.populate(unicodes=set(range(32, 127)) | {ord(c) for c in text} | {0xFFFD})
subsetter.subset(font)
font.save(root / "assets/fonts/CloudbridgeTC.otf")
print("Updated CloudbridgeTC.otf; retain NOTO-LICENSE.txt when distributing.")
