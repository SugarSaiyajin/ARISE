#!/usr/bin/env python3
"""Read original item alpha geometry; write metadata, never alter the PNG."""
from collections import deque
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
im = Image.open(ROOT / "assets/pixel/items_approved.png").convert("RGBA")
w, h = im.size
alpha = im.getchannel("A").tobytes()
seen = bytearray(w*h)
components = []
for start in range(w*h):
    if seen[start] or alpha[start] <= 200:
        continue
    seen[start] = 1
    queue = deque([start])
    points = []
    while queue:
        p = queue.popleft()
        x, y = p % w, p // w
        points.append((x,y))
        for q in (p-1 if x else -1, p+1 if x<w-1 else -1,
                  p-w if y else -1, p+w if y<h-1 else -1):
            if q>=0 and not seen[q] and alpha[q]>200:
                seen[q] = 1
                queue.append(q)
    if len(points)>400:
        components.append(points)

main = [p for p in components if len(p)>4000]
assert len(main)==32, f"Expected 32 main icons, found {len(main)}"
main.sort(key=lambda p:min(y for x,y in p))
ordered = []
for row in range(4):
    ordered.extend(sorted(main[row*8:(row+1)*8],key=lambda p:min(x for x,y in p)))
centers = [((min(x for x,y in p)+max(x for x,y in p))/2,
            (min(y for x,y in p)+max(y for x,y in p))/2) for p in ordered]
# Detached ore chips and furnace smoke belong to the nearest main silhouette.
groups = [list(p) for p in ordered]
for points in components:
    if len(points)>4000:
        continue
    x = sum(x for x,y in points)/len(points)
    y = sum(y for x,y in points)/len(points)
    index = min(range(32),key=lambda i:(x-centers[i][0])**2+(y-centers[i][1])**2)
    groups[index].extend(points)
rows = []
for row in range(4):
    frames = []
    for points in groups[row*8:(row+1)*8]:
        l,t = max(0,min(x for x,y in points)-2),max(0,min(y for x,y in points)-2)
        r,b = min(w,max(x for x,y in points)+3),min(h,max(y for x,y in points)+3)
        frames.append([l,t,r-l,b-t,(r-l)/2,b-t])
    rows.append(frames)
(ROOT/"scripts/item_frames.gd").write_text(
    "extends RefCounted\n\n# Read-only geometry; detached details grouped with main icon. PNG unchanged.\n"
    + "const FRAMES := " + repr(rows) + "\n")
print("Registered 32 item regions, including detached details; PNG unchanged.")
