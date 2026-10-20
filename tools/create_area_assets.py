#!/usr/bin/env python3
"""Original pixel backgrounds and buildings for the farmhouse and Cloudbridge."""
import random
from create_pixel_assets import canvas, box, save

def house():
    image,d=canvas(480,270)
    box(d,(0,0,480,270),"#273e36")
    box(d,(98,50,284,165),"#172f2c")
    box(d,(102,52,276,158),"#6f5840")
    box(d,(108,74,264,134),"#b58b5b")
    rng=random.Random(482)
    for y in range(76,208,8):
        for x in range(108,372,24):
            box(d,(x,y,23,7),rng.choice(["#bc9464","#b58c5c","#c09a69"]))
            box(d,(x,y+7,24,1),"#9d794f")
            box(d,(x+3,y+3,7,1),"#cba775")
    box(d,(104,53,272,22),"#d2c5a0")
    for x in (108,194,282,368):
        box(d,(x,52,4,24),"#816244")
        box(d,(x+1,53,1,22),"#af8e5d")
    box(d,(104,73,272,4),"#765a40")
    for x in (137,228):
        box(d,(x,57,31,15),"#6f6249")
        box(d,(x+2,58,27,11),"#85a79a")
        box(d,(x+4,59,7,9),"#c9d6b6")
        for dx in (9,19):box(d,(x+dx,58,1,13),"#d9c99c")
        box(d,(x+2,64,27,1),"#d9c99c")
    # Journal desk and stool, with a readable open book silhouette.
    box(d,(146,86,49,22),"#7d5b3e")
    box(d,(144,84,53,5),"#d3b17a")
    for x in (149,189):box(d,(x,102,3,8),"#614e39")
    box(d,(162,86,18,8),"#f0e4bf")
    box(d,(170,86,1,8),"#bca574")
    for y in (88,91):
        box(d,(164,y,5,1),"#8e9372");box(d,(173,y,5,1),"#8e9372")
    box(d,(184,86,5,7),"#4f7266")
    box(d,(164,112,16,5),"#91704a")
    # Four-post bed and patterned cover.
    box(d,(305,81,45,30),"#634e3b")
    box(d,(308,82,39,26),"#eadfbd")
    box(d,(311,84,15,7),"#fff0cf")
    box(d,(329,84,15,7),"#f4e6c4")
    box(d,(308,93,39,14),"#b86f56")
    for x in range(311,344,7):
        d.polygon([(x,97),(x+2,95),(x+4,97),(x+2,99)],fill="#e0bd7e")
        box(d,(x,103,3,1),"#d8a16b")
    for x in (304,348):
        box(d,(x,79,3,34),"#856340")
        box(d,(x,78,3,3),"#d0ad72")
    # Hearth, wood pile and a kettle.
    box(d,(112,136,23,33),"#7d806e")
    box(d,(115,140,17,25),"#3b463b")
    box(d,(118,154,11,9),"#d58c4d")
    box(d,(122,152,4,10),"#efbd6e")
    box(d,(111,166,25,4),"#b1b398")
    box(d,(116,134,16,3),"#d2c49e")
    # Rug and tea table.
    box(d,(201,129,67,38),"#617c70")
    box(d,(203,131,63,34),"#adbd93")
    box(d,(205,133,59,30),"#6f9180")
    for x in range(208,264,8):
        box(d,(x,135,4,1),"#d7d2a3");box(d,(x,159,4,1),"#d7d2a3")
    box(d,(218,137,30,18),"#7e5d40")
    box(d,(216,136,34,5),"#d0a56a")
    box(d,(223,138,6,3),"#ece0b8")
    box(d,(235,136,6,5),"#547e70")
    # Door threshold: an actual opening in the lower wall.
    box(d,(105,207,267,5),"#765a40")
    box(d,(226,201,27,12),"#c3a277")
    box(d,(228,204,23,8),"#ddc59a")
    box(d,(225,208,1,6),"#e1bb7e");box(d,(253,208,1,6),"#e1bb7e")
    save(image,"house_interior")

def town():
    image,d=canvas(480,270)
    rng=random.Random(904)
    box(d,(0,0,480,270),"#80a16a")
    for i in range(1800):
        x,y=rng.randrange(480),rng.randrange(270)
        box(d,(x,y,1,1),rng.choice(["#8eaf73","#72955f","#9fba7f"]))
    for xy in [(0,136,480,22),(169,111,66,79),(322,130,18,72),(96,124,18,32)]:
        x,y,w,h=xy
        box(d,(x-1,y-1,w+2,h+2),"#9e9d7b")
        box(d,xy,"#c3ba94")
        for row in range(y+2,y+h,4):
            for col in range(x+1,x+w,7):
                box(d,(col+(row//4)%2*2,row,5,2),rng.choice(["#d7cda7","#b6ae8a","#cfc59e"]))
    # River divides the cultures; the stone bridge joins their main street.
    box(d,(247,43,38,181),"#627e68")
    box(d,(251,43,30,181),"#a5ad87")
    box(d,(254,43,24,181),"#5b9496")
    box(d,(259,43,11,181),"#6ca5a0")
    for i in range(80):
        box(d,(rng.randrange(255,274),rng.randrange(44,220),rng.randrange(2,6),1),"#9cc2b4")
    box(d,(239,132,55,31),"#7b8979")
    box(d,(239,135,55,24),"#b4b69a")
    for row in range(3):
        for col in range(7):
            box(d,(240+col*8,138+row*6,7,5),"#d6ceb0" if (row+col)%2 else "#c9c3a5")
    box(d,(238,132,57,4),"#e0d5b3")
    box(d,(238,159,57,4),"#d0c7a6")
    for x in (239,291):
        box(d,(x,129,3,8),"#c1bea0");box(d,(x,158,3,8),"#b7b69b")
    # Town notice board.
    box(d,(203,85,27,20),"#775c40")
    box(d,(205,87,23,15),"#cba875")
    box(d,(207,89,7,10),"#e9dfba");box(d,(217,90,8,7),"#d6d2ad")
    for x in (206,225):box(d,(x,103,2,10),"#806444")
    d.polygon([(200,86),(216,78),(233,86)],fill="#4c7267")
    # Flower beds and lantern posts line the plaza.
    for x,y in [(64,180),(84,180),(188,188),(213,188),(437,139)]:
        box(d,(x-5,y,12,4),"#a08255")
        for dx in (-3,1,5):
            box(d,(x+dx,y-5,1,6),"#4c7a4b")
            box(d,(x+dx-1,y-7,3,3),"#e6c28a" if dx==1 else "#d4a18d")
    for x,y in [(184,120),(306,130)]:
        box(d,(x,y-23,2,24),"#816342")
        box(d,(x-3,y-24,8,9),"#a56047")
        box(d,(x-1,y-23,4,7),"#e6ae63")
    save(image,"town_ground")

def smithy():
    image,d=canvas(84,72)
    d.ellipse((4,59,80,70),fill="#3a58444d")
    box(d,(10,28,64,36),"#a6a68e")
    for row in range(5):
        for col in range(8):
            box(d,(11+col*8,32+row*6,7,5),"#b9b59b" if (row+col)%2 else "#969e89")
    box(d,(58,5,10,27),"#838d7d")
    box(d,(56,4,14,4),"#c6c3a5")
    for row in range(9):
        box(d,(26-row*2,12+row*2,32+row*4,3),"#536e72")
        box(d,(26-row*2,12+row*2,32+row*4,1),"#849a95")
    box(d,(5,29,74,3),"#3a5559")
    box(d,(10,39,20,22),"#404a41")
    box(d,(12,47,16,13),"#af6e42")
    box(d,(17,47,6,12),"#edb661")
    box(d,(9,61,22,3),"#cec4a2")
    box(d,(42,40,17,24),"#6d5a42")
    box(d,(44,43,13,19),"#b39261")
    box(d,(53,51,2,2),"#dfca8c")
    box(d,(63,42,8,9),"#668c87")
    box(d,(66,42,1,9),"#d3c69e")
    save(image,"smithy")

def clocktower():
    image,d=canvas(48,72)
    d.ellipse((5,62,44,71),fill="#3b57444d")
    box(d,(11,27,27,39),"#899983")
    for row in range(7):
        for col in range(4):
            box(d,(12+col*6,29+row*5,5,4),"#b9b9a0" if (row+col)%2 else "#a3ad96")
    for row in range(13):
        box(d,(23-row,2+row*2,3+row*2,3),"#8d6557")
        box(d,(23-row,2+row*2,3+row*2,1),"#b28c70")
    box(d,(9,26,31,3),"#5d624f")
    d.ellipse((16,32,33,49),fill="#5f6b5b")
    d.ellipse((18,34,31,47),fill="#e4d8af")
    d.line((25,35,25,41,29,43),fill="#536153",width=1)
    box(d,(21,53,7,13),"#5e6958")
    box(d,(20,51,9,3),"#cbc1a0")
    save(image,"clocktower")

if __name__=="__main__":
    house();town();smithy();clocktower()
    print("Created farmhouse interior and Cloudbridge assets.")
