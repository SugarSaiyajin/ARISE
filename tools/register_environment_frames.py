#!/usr/bin/env python3
"""Read a regular environment atlas's alpha bounds without editing its PNG."""
import argparse
from pathlib import Path
from PIL import Image

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("image",type=Path)
parser.add_argument("--rows",type=int,required=True)
parser.add_argument("--columns",type=int,required=True)
parser.add_argument("--output",type=Path,required=True)
args = parser.parse_args()
im = Image.open(args.image).convert("RGBA")
alpha = im.getchannel("A")
rows = []
for row in range(args.rows):
    frames = []
    for col in range(args.columns):
        bounds = (col*im.width//args.columns,row*im.height//args.rows,
                  (col+1)*im.width//args.columns,(row+1)*im.height//args.rows)
        box = alpha.crop(bounds).point(lambda p:255 if p>200 else 0).getbbox()
        if box is None:
            raise RuntimeError(f"Empty atlas cell: {row}, {col}")
        left,top = bounds[0]+box[0],bounds[1]+box[1]
        right,bottom = bounds[0]+box[2],bounds[1]+box[3]
        frames.append([left,top,right-left,bottom-top,(right-left)/2,bottom-top])
    rows.append(frames)
args.output.write_text("extends RefCounted\n# Original alpha geometry; PNG unchanged.\nconst FRAMES := "+repr(rows)+"\n")
print(f"Registered {args.rows*args.columns} regions; source PNG unchanged.")
