#!/usr/bin/env python3
"""Read animal atlas alpha bounds; keep the original PNG unchanged."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
image = Image.open(ROOT / "assets/pixel/animals_approved.png")
alpha = image.getchannel("A")
# The first worm and deer touch; explicit row boundaries keep them separate.
ys = [0,140,270,404,536,654,738,897,1024]
xs = [200,500,800,1100,1400]
assert image.size == (1536,1024), "Recalibrate source boundaries for a changed atlas"
rows = []
for row in range(8):
    frames = []
    for col in range(4):
        rect = (xs[col],ys[row],xs[col+1],ys[row+1])
        box = alpha.crop(rect).point(lambda p:255 if p>200 else 0).getbbox()
        assert box
        l = max(rect[0],rect[0]+box[0]-2)
        t = max(rect[1],rect[1]+box[1]-2)
        r = min(rect[2],rect[0]+box[2]+2)
        b = min(rect[3],rect[1]+box[3]+2)
        frames.append([l,t,r-l,b-t,(r-l)/2,b-t-1])
    rows.append(frames)
(ROOT/"scripts/animal_frames.gd").write_text(
    "extends RefCounted\n\n# Read-only alpha bounds; source PNG unchanged. Row boundaries isolate touching silhouettes.\n"
    + "const FRAMES := " + repr(rows) + "\n")
print("Registered 32 animal poses; PNG unchanged.")
