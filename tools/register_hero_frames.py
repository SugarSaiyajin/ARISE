#!/usr/bin/env python3
"""Read sprite geometry and write foot-pivot metadata; never modify the PNG.

Requires Pillow. The original generated sheet stays intact. The game uses
texture regions and one shared scale to align all poses at the actor's feet.
"""
from pathlib import Path
from collections import deque
import argparse

from PIL import Image

PROJECT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("image", type=Path)
parser.add_argument("--rows",type=int,default=8)
parser.add_argument("--columns",type=int,default=8)
parser.add_argument("--output",type=Path,default=PROJECT/"scripts/hero_frames.gd")
parser.add_argument("--fit-height",type=float,default=0)
args = parser.parse_args()
im = Image.open(args.image).convert("RGBA")
w, h = im.size
alpha = im.getchannel("A").tobytes()
visited = bytearray(w * h)
components = []
for start in range(w * h):
    if visited[start] or alpha[start] <= 200:
        continue
    visited[start] = 1
    queue = deque([start])
    points = []
    while queue:
        p = queue.popleft()
        points.append((p % w, p // w))
        x, y = p % w, p // w
        for q in (p - 1 if x else -1, p + 1 if x < w-1 else -1,
                  p - w if y else -1, p + w if y < h-1 else -1):
            if q >= 0 and not visited[q] and alpha[q] > 200:
                visited[q] = 1
                queue.append(q)
    if len(points) > 400:
        components.append(points)
assert len(components) == args.rows*args.columns, f"Expected {args.rows*args.columns} separate poses, found {len(components)}"
components.sort(key=lambda ps: min(y for x, y in ps))
rows = []
for row in range(args.rows):
    group = components[row*args.columns:(row+1)*args.columns]
    group.sort(key=lambda ps: min(x for x, y in ps))
    frames = []
    for points in group:
        x0, x1 = min(x for x, y in points), max(x for x, y in points) + 1
        y0, y1 = min(y for x, y in points), max(y for x, y in points) + 1
        feet = [x for x, y in points if y >= y1 - 18]
        pivot_x = (min(feet) + max(feet) + 1) / 2
        left, top, right, bottom = max(0, x0-4), max(0, y0-4), min(w, x1+4), min(h, y1+4)
        frames.append([left, top, right-left, bottom-top, pivot_x-left, y1+1-top])
    rows.append(frames)
heights=sorted(max(y for x,y in ps)-min(y for x,y in ps)+1 for ps in components)
scale=args.fit_height/heights[len(heights)//2] if args.fit_height else 0.2
text = '''extends RefCounted

# Geometry read from the unchanged source PNG by register_hero_frames.py.
# Per-pose source rect and foot pivot keep the character registered in world space.
const PIXEL_SCALE := 0.20
const DIRECTIONS := ["south", "west", "east", "north", "southwest", "southeast", "northwest", "northeast"]
const FRAMES := [
'''
for frames in rows:
    text += "\t[\n"
    for frame in frames:
        text += "\t\t" + repr(frame) + ",\n"
    text += "\t],\n"
text += "]\n"
text=text.replace("const PIXEL_SCALE := 0.20", "const PIXEL_SCALE := "+str(scale))
args.output.write_text(text)
print(f"Registered {len(components)} frame regions and foot pivots from {w}x{h} source; PNG unchanged.")
