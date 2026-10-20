#!/usr/bin/env python3
"""Draw ARISE's original integer-grid pixel artwork. Requires Pillow."""
from pathlib import Path
import json
import random
from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1] / "assets/pixel"
ROOT.mkdir(parents=True, exist_ok=True)
OUTLINE = "#38493e"

def canvas(w, h):
    image = Image.new("RGBA", (w, h))
    return image, ImageDraw.Draw(image)

def box(d, xy, color):
    x, y, w, h = map(int, xy)
    if w > 0 and h > 0:
        d.rectangle((x, y, x + w - 1, y + h - 1), fill=color)

def save(image, name):
    image.save(ROOT / (name + ".png"), optimize=True)

def character(npc=False, role=""):
    atlas, _ = canvas(256, 128)
    for direction in range(4):  # south, west, east, north
        for frame in range(8):
            image, d = canvas(32, 32)
            step = -1 if frame == 1 else (1 if frame == 3 else 0)
            action = frame >= 4
            bob = -1 if frame in (1, 3, 4) else 0
            def b(x, y, w, h, c):
                box(d, (x, y + bob, w, h), c)
            coat = {"merchant":"#b28b5f","smith":"#5b6d77"}.get(role, "#4a8583" if npc else "#b16854")
            light = {"merchant":"#ddc48c","smith":"#a77b62"}.get(role, "#85b3a0" if npc else "#db9b69")
            skin, shadow = "#efc69a", "#c78f70"
            if direction in (1, 2):
                b(12, 25 + step, 4, 5 - step, "#405048")
                b(16, 25 - step, 4, 5 + step, "#4f5750")
                b(11, 29 + step, 6, 1, OUTLINE)
                b(16, 29 - step, 5, 1, OUTLINE)
                b(10, 15, 11, 12, OUTLINE)
                b(11, 16, 9, 10, coat)
                b(12, 17, 2, 8, light)
                b(10, 24, 11, 2, "#d5bd8b")
                b(16, 19 if not action else 15, 4, 6, shadow)
                b(17, 19 if not action else 15, 3, 4, skin)
                b(10, 7, 11, 10, "#51473e")
                b(11, 8, 10, 7, skin)
                b(19, 11, 3, 3, skin)
                b(19, 10, 1, 2, "#393f3a")
                b(11, 7, 8, 3, "#51473e")
                b(10, 9, 3, 7, "#51473e")
                b(13, 15, 6, 2, shadow)
                if not npc:
                    b(7, 6, 18, 3, "#8d6c43")
                    b(7, 5, 18, 2, "#e5c781")
                    b(11, 2, 10, 4, "#f4d891")
                    b(11, 5, 11, 1, "#b78851")
                    b(8, 17, 4, 7, "#6e6c4e")
                    b(8, 17, 4, 1, "#a3aa7b")
                elif role:
                    b(9, 5, 11, 3, "#5b6453" if role=="merchant" else "#544c42")
                    b(10, 4, 8, 2, "#8b9a78" if role=="merchant" else "#8b7560")
                else:
                    b(9, 5, 9, 3, "#44473e")
                    b(9, 3, 5, 3, "#44473e")
                    b(8, 5, 5, 1, "#dfce91")
                    b(19, 14, 1, 2, "#e4c98c")
                if direction == 1:
                    image = ImageOps.mirror(image)
            else:
                b(11, 25 + step, 4, 5 - step, "#46524b")
                b(17, 25 - step, 4, 5 + step, "#46524b")
                b(10, 29 + step, 6, 1, OUTLINE)
                b(17, 29 - step, 5, 1, OUTLINE)
                b(9, 16, 14, 11, OUTLINE)
                b(10, 16, 12, 10, coat)
                b(11, 16, 4, 8, light)
                b(15, 17, 2, 6, "#e2d1a0")
                b(15, 18, 1, 6, "#9d9a6e")
                b(9, 24, 14, 2, "#dbc38b")
                arm_y = 18 if not action else (11 if frame == 4 else 20)
                b(7, arm_y + step, 3, 6, shadow)
                b(8, arm_y + step, 2, 4, skin)
                b(22, arm_y - step, 3, 6, shadow)
                b(22, arm_y - step, 2, 4, skin)
                b(10, 7, 12, 10, "#4a443c")
                if direction == 0:
                    b(11, 8, 10, 8, skin)
                    b(10, 8, 12, 3, "#554940")
                    b(10, 11, 2, 4, "#554940")
                    b(20, 11, 2, 4, "#554940")
                    b(13, 12, 1, 2, "#35413a")
                    b(18, 12, 1, 2, "#35413a")
                    b(14, 16, 4, 1, shadow)
                    b(12, 15, 2, 1, "#dfa886")
                    b(19, 15, 1, 1, "#dfa886")
                else:
                    b(11, 8, 10, 9, "#554940")
                    b(12, 9, 4, 6, "#675346")
                    if not npc:
                        b(11, 18, 10, 8, "#616d50")
                        b(12, 18, 8, 2, "#9aa778")
                        b(14, 21, 4, 3, "#879168")
                if npc and not role:
                    b(12, 4, 7, 4, "#41473e")
                    b(11, 6, 10, 2, "#5b5142")
                    b(10, 6, 13, 1, "#d3c894")
                    b(20, 5, 4, 2, "#a6c2a0")
                elif not npc:
                    b(6, 6, 20, 3, "#8e6b43")
                    b(6, 5, 20, 2, "#ddbd77")
                    b(10, 2, 12, 4, "#eed28c")
                    b(11, 2, 8, 1, "#f6dda2")
                    b(10, 5, 12, 1, "#af8150")
            atlas.alpha_composite(image, (frame * 32, direction * 32))
    save(atlas, role or ("qinghe" if npc else "hero"))

def tree(autumn=False):
    image, d = canvas(48, 56)
    rng = random.Random(90)
    colors = (["#635b42", "#ac7248", "#d29453", "#e9b76c", "#f0d188"] if autumn else
              ["#335b48", "#42754e", "#5c8c52", "#80a35b", "#a4bc76"])
    d.ellipse((9, 48, 39, 55), fill="#416c494d")
    d.polygon([(20, 34), (27, 34), (28, 49), (33, 52), (17, 52), (21, 48)], fill="#70543d")
    box(d, (23, 34, 3, 15), "#a47d4e")
    d.line([(25, 43), (32, 36)], fill="#70543d", width=3)
    d.line([(23, 39), (17, 33)], fill="#70543d", width=3)
    # Cluster silhouettes instead of a rectangular canopy.
    for x, y, w, h in [(13, 2, 23, 22), (4, 12, 24, 23), (23, 11, 22, 23), (10, 22, 28, 17)]:
        d.ellipse((x, y, x + w, y + h), fill=colors[0])
    for x, y, w, h in [(12, 4, 23, 18), (4, 13, 24, 17), (23, 13, 20, 15), (12, 22, 23, 12)]:
        d.ellipse((x, y, x + w, y + h), fill=colors[1])
    for i in range(100):
        x, y = rng.randrange(6, 42), rng.randrange(5, 34)
        if image.getpixel((x, y))[3] and y < 26 + (x % 4):
            box(d, (x, y, rng.randrange(2, 5), 2), colors[rng.choice([1, 2, 2, 3])])
    for x, y in [(16, 6), (22, 8), (10, 16), (30, 15), (19, 22), (8, 21)]:
        box(d, (x, y, 4, 1), colors[4])
    save(image, "tree_autumn" if autumn else "tree")

def buildings():
    image, d = canvas(112, 88)
    # Stone foundations, timber-braced plaster walls and curved Song-style tiles.
    d.ellipse((7, 71, 105, 86), fill="#314e384d")
    box(d, (15, 41, 80, 37), OUTLINE)
    box(d, (18, 43, 74, 31), "#e5d2a6")
    box(d, (18, 63, 74, 12), "#a6a58e")
    for row in range(3):
        for col in range(9):
            box(d, (18 + col * 9 + (row % 2) * 3, 65 + row * 4, 7, 3),
                ["#bcb8a0", "#cac2a6", "#9c9e88"][(col + row) % 3])
    for x in (19, 45, 69, 90):
        box(d, (x, 43, 3, 21), "#755b40")
        box(d, (x, 44, 1, 19), "#a98756")
    for x in (21, 72):
        d.line((x, 45, x + 16, 60), fill="#94724b", width=2)
    box(d, (18, 59, 74, 4), "#7d5d40")
    box(d, (49, 55, 18, 21), "#5b4a3a")
    box(d, (52, 57, 12, 19), "#9b744b")
    for x in (54, 59, 63):
        box(d, (x, 58, 1, 16), "#795c40")
    box(d, (61, 66, 2, 2), "#f0cd7c")
    for x in (27, 75):
        box(d, (x - 1, 48, 13, 11), "#69533e")
        box(d, (x, 49, 11, 8), "#82aaa0")
        box(d, (x + 1, 49, 3, 7), "#b8cec0")
        box(d, (x + 5, 49, 1, 8), "#e4d1a3")
        box(d, (x, 53, 11, 1), "#e4d1a3")
        box(d, (x - 2, 59, 15, 2), "#b38b54")
    box(d, (80, 11, 8, 25), "#b3af99")
    box(d, (78, 10, 12, 4), "#d3ccb0")
    for y in (17, 22):
        box(d, (80, y, 8, 1), "#898e7d")
    for tier in range(10):
        y = 21 + tier * 2
        x = 27 - tier * 2
        w = 56 + tier * 4
        box(d, (x, y, w, 3), "#345650")
        box(d, (x, y, w, 1), "#74958a")
        for col in range(w // 5):
            box(d, (x + col * 5, y + 1, 1, 1), "#496d65")
    d.line([(6, 36), (12, 42), (99, 42), (105, 36)], fill="#2d4a48", width=3)
    d.line([(7, 35), (12, 39), (99, 39), (104, 35)], fill="#92aaa0", width=1)
    box(d, (25, 20, 60, 2), "#47685d")
    box(d, (44, 77, 30, 3), "#b9b49a")
    box(d, (41, 80, 36, 3), "#d6c9a4")
    for x in (68,):
        box(d, (x + 4, 43, 1, 5), "#75583e")
        box(d, (x + 1, 48, 7, 9), "#b95b46")
        box(d, (x + 3, 48, 3, 8), "#ed9c63")
        box(d, (x + 1, 48, 7, 1), "#e5c385")
        box(d, (x + 4, 57, 1, 4), "#e4bd77")
    save(image, "farmhouse")
    image, d = canvas(80, 64)
    d.ellipse((4, 50, 76, 63), fill="#314e384d")
    for x in (10, 67):
        box(d, (x, 19, 3, 36), "#765b40")
        box(d, (x, 19, 1, 35), "#b18e58")
    box(d, (13, 24, 54, 25), "#d8c69b")
    for i in range(9):
        d.polygon([(5+i*8, 13), (13+i*8, 13), (16+i*8, 27), (8+i*8, 27)],
                  fill="#bf7559" if i % 2 == 0 else "#f0d9ab")
        box(d, (8+i*8, 28, 8, 4), "#9e5948" if i % 2 == 0 else "#d0b58b")
    box(d, (18, 5, 44, 7), "#547364")
    for i in range(5):
        box(d, (16+i*10, 38, 7, 8), "#9c9f61")
        box(d, (17+i*10, 37, 5, 2), "#d9cf93")
        box(d, (18+i*10, 40, 3, 3), "#d9ba78")
    box(d, (10, 46, 60, 11), "#9b754c")
    for i in range(6):
        box(d, (12+i*10, 48, 1, 8), "#785e40")
    box(d, (8, 45, 64, 3), "#dbb87c")
    save(image, "market")
    image, d = canvas(64, 64)
    d.ellipse((2, 50, 62, 61), fill="#314e384d")
    box(d, (7, 49, 50, 6), "#a6a991")
    box(d, (5, 55, 54, 3), "#cac7a7")
    for x in (11, 50):
        box(d, (x, 28, 3, 22), "#755a40")
        box(d, (x, 28, 1, 22), "#b99a68")
    for i in range(11):
        box(d, (30-i*2, 10+i*2, 4+i*4, 3), "#3c625b")
        box(d, (30-i*2, 10+i*2, 4+i*4, 1), "#78948a")
    box(d, (23, 43, 21, 3), "#b3905e")
    box(d, (26, 46, 2, 5), "#785d40")
    box(d, (39, 46, 2, 5), "#785d40")
    box(d, (28, 40, 4, 3), "#e8dfb9")
    box(d, (34, 39, 4, 4), "#7e9989")
    save(image, "tea_pavilion")

def terrain():
    image, d = canvas(480, 270)
    rng = random.Random(716)
    box(d, (0, 0, 480, 270), "#83a56b")
    # Soft patches made of stepped pixel clusters, not image scaling or blur.
    for i in range(260):
        x, y = rng.randrange(480), rng.randrange(270)
        d.ellipse((x, y, x+rng.randrange(4, 18), y+rng.randrange(2, 8)),
                  fill=rng.choice(["#80a269", "#86a96e", "#89ac70"]))
    for i in range(1600):
        x, y = rng.randrange(480), rng.randrange(270)
        color = rng.choice(["#75985f", "#94b578", "#a0bd80"])
        box(d, (x, y, 1, 1), color)
        if i % 5 == 0:
            d.line((x-1, y-1, x, y+1, x+1, y-2), fill=color)
    paths = [(0,112,480,10),(279,112,14,105),(65,197,228,12),(76,117,10,87),(322,116,11,63)]
    mask = Image.new("1", image.size)
    md = ImageDraw.Draw(mask)
    for x,y,w,h in paths:
        box(d,(x-1,y-1,w+2,h+2),"#a6a27b")
        box(d,(x,y,w,h),"#c6bd96")
        box(md,(x,y,w,h),1)
    for i in range(4000):
        x,y=rng.randrange(480),rng.randrange(110,218)
        if mask.getpixel((x,y)):
            box(d,(x,y, rng.choice([1,2,3]),1),rng.choice(["#d8cfa7","#b5ad88","#e0d5ae"]))
    # Pond's irregular stepped shoreline, stone bank, deeper blue center.
    shape=[(247,73),(252,68),(266,63),(294,62),(312,67),(324,74),
           (328,85),(321,97),(310,103),(284,107),(264,102),(249,94),(244,83)]
    d.polygon(shape,fill="#637f64")
    for inset,color in [(2,"#b8b18a"),(4,"#557f80"),(6,"#659a98")]:
        d.polygon([(286+(x-286)*(1-inset/45),84+(y-84)*(1-inset/28)) for x,y in shape], fill=color)
    d.polygon([(263,76),(276,70),(300,72),(315,82),(300,90),(275,88),(262,83)], fill="#75a8a2")
    for x,y in [(260,91),(317,75),(308,99)]:
        for j in range(4):
            d.line((x+j*2,y,x+j*2-1,y-5-j%2*3),fill="#557650")
        box(d,(x,y-8,1,4),"#ae8754")
    d.ellipse((292,73,301,77),fill="#4e7c58")
    box(d,(296,71,2,3),"#e6b99d")
    # Flower ribbon and small stones.
    for i in range(22):
        x,y=45+i*4,175+i%3*5
        box(d,(x,y,1,4),"#537b4a")
        box(d,(x-1,y-2,3,3),"#e9c784" if i%2 else "#dcae9a")
        box(d,(x,y-1,1,1),"#fff0bd")
    for x,y in [(135,94),(25,135),(440,208),(339,99)]:
        d.ellipse((x,y,x+7,y+4),fill="#838e76")
        box(d,(x+1,y,4,1),"#b7b9a0")
    save(image,"ground")
    image,d=canvas(51,17)
    for i,color in enumerate(["#7f9c61","#a17a51","#6f5541"]):
        box(d,(i*17,0,17,17),color)
        if i==0:
            box(d,(0,0,17,1),"#76945e")
            box(d,(0,0,1,17),"#76945e")
        if i:
            box(d,(i*17+1,1,15,1),"#bd9463" if i==1 else "#8e6b50")
            for y in (5,9,13):
                box(d,(i*17+2,y,13,1),"#8b6544" if i==1 else "#5e4d3d")
        for n in range(9):
            x,y=rng.randrange(2,15),rng.randrange(2,15)
            box(d,(i*17+x,y,1,1),"#a9b985" if i==0 else ("#c09b68" if i==1 else "#977350"))
    save(image,"soil")

def crops():
    image,d=canvas(96,72)
    for row in range(3):
        for stage in range(4):
            x,y=stage*24+12,row*24+15
            def b(dx,dy,w,h,c):box(d,(x+dx,y+dy,w,h),c)
            if stage==0:
                b(-2,0,4,2,"#c5a66d");b(0,-2,1,2,"#9cb96b")
                continue
            b(0,-6,1,9,"#4f7849")
            if row==0:
                if stage==3:
                    d.ellipse((x-5,y-4,x+5,y+4),fill="#aa9e8c")
                    d.ellipse((x-5,y-5,x+4,y+2),fill="#ede2bc")
                    b(-3,-4,4,2,"#fff2d0");b(0,4,1,3,"#d7ccb0")
                for dx,dy,w,h,c in [(-6,-9,5,3,"#6b9954"),(1,-12,4,5,"#9cbc6c"),(-2,-13,3,6,"#4e8350")]:
                    if stage==1: dy+=5;w=max(2,w-2);h=max(2,h-2)
                    b(dx,dy,w,h,c)
            elif row==1:
                for j in range(3):
                    height=5+stage*3+j%2*2
                    b(-5+j*4,-height,1,height+3,"#b69d56" if stage==3 else "#54814b")
                    b(-6+j*4,-height,3,5,"#ecc46b" if stage==3 else "#90ad61")
                    if stage==3:b(-7+j*4,-height+2,5,1,"#d9b25f")
            else:
                d.ellipse((x-6,y-8-stage,x+6,y+1),fill="#416d49")
                b(-4,-8,5,3,"#729956");b(2,-6,4,2,"#98b56c")
                if stage==3:
                    for dx,dy in [(-5,-3),(2,-7),(1,0)]:
                        b(dx,dy,4,5,"#c47b40");b(dx,dy,3,3,"#f1b55f");b(dx+1,dy,1,2,"#ffe197")
    save(image,"crops")

def props():
    image,d=canvas(128,64)
    # Crate at 0,0,24,24; well at 24,0,32,40; cart at 56,0,32,24.
    box(d,(2,7,20,16),"#5d4c36");box(d,(3,6,18,14),"#a67d4e")
    for y in (9,14,19):box(d,(3,y,18,1),"#785b3b")
    for x in (4,18):box(d,(x,7,2,14),"#d1ad70")
    box(d,(1,4,22,4),"#cba76a");box(d,(9,8,6,4),"#e9d5a1")
    box(d,(29,24,23,12),"#929b86")
    for j in range(3):
        for i in range(3):
            box(d,(30+i*7+j%2*2,25+j*3,5,2),"#b9bda1")
    d.ellipse((28,21,53,29),fill="#d2caaa")
    d.ellipse((33,22,48,26),fill="#496864")
    for x in (29,51):box(d,(x,7,2,17),"#8f714b")
    for i in range(5):
        box(d,(37-i*3,2+i*2,8+i*6,3),"#4a7068")
        box(d,(37-i*3,2+i*2,8+i*6,1),"#91a99a")
    box(d,(66,10,20,9),"#b58c59");box(d,(64,8,24,3),"#d4b37c")
    for x in (66,81):d.ellipse((x,16,x+6,22),fill="#4e4e3d")
    d.line((87,11,95,4),fill="#8a6c48",width=2)
    # Fence tile at 0,40,16,16; planter at 16,40,16,16.
    for y in (45,50):box(d,(0,y,16,2),"#ba975f")
    box(d,(1,41,3,14),"#7a6142");box(d,(1,41,3,2),"#ebca8b")
    box(d,(19,49,10,7),"#ad7952");box(d,(18,48,12,2),"#d5a775")
    d.ellipse((18,42,29,50),fill="#548150");box(d,(21,41,5,3),"#91b36b")
    # Four tool icons and butterflies.
    for i in range(4):
        x=64+i*16
        if i==0:
            d.line((x+4,55,x+11,43),fill="#b79b66",width=2)
            box(d,(x+7,42,8,3),"#728e8a");box(d,(x+8,45,2,3),"#526d6c")
        elif i==1:
            box(d,(x+3,45,10,11),"#cfb078");box(d,(x+4,43,8,3),"#ead29a")
            box(d,(x+6,48,4,5),"#729353")
        elif i==2:
            box(d,(x+3,46,9,8),"#78a2a0");box(d,(x+4,44,6,2),"#a3c7b7")
            d.line((x+10,48,x+14,45),fill="#b7d3c2",width=2)
        else:
            d.arc((x+3,41,x+13,52),0,240,fill="#c4d2b6",width=2)
            d.line((x+4,49,x+10,56),fill="#b38b57",width=2)
    save(image,"props")

if __name__=="__main__":
    character();character(True);character(True,"merchant");character(True,"smith")
    tree();tree(True);buildings();terrain();crops();props()
    (ROOT/"atlas.json").write_text(json.dumps({
        "authoring":"Original ARISE integer-grid artwork, generated by tools/create_pixel_assets.py",
        "character":{"frame_size":[32,32],"columns":8,"directions":["south","west","east","north"],
                     "frames":["idle","walk_a","walk_mid","walk_b","raise","reach","impact","recover"]},
        "hero":{"texture":"hero_eight.png","layout":"scripts/hero_frames.gd",
                "directions":["south","west","east","north","southwest","southeast","northwest","northeast"],
                "frames_per_direction":8,"authoring":"Image generation based on the original ARISE hero; preserved PNG with registered foot pivots"},
        "crop":{"frame_size":[24,24],"columns":4,"rows":["turnip","wheat","berry"]},
        "props":{"crate":[0,0,24,24],"well":[24,0,32,40],"cart":[56,0,40,24],
                 "fence":[0,40,16,16],"planter":[16,40,16,16],
                 "tools":[[64+i*16,40,16,16] for i in range(4)]}
    },indent=2)+"\n")
    print("Created original pixel atlas assets in",ROOT)
