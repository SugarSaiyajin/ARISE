#!/usr/bin/env python3
"""Original mossy waystation ruins and a star-marked relic."""
import random
from create_pixel_assets import canvas, box, save
im,d=canvas(480,270);rng=random.Random(937)
box(d,(0,0,480,270),'#607c65')
for i in range(3000):
    box(d,(rng.randrange(480),rng.randrange(270),2 if i%9==0 else 1,1),rng.choice(['#719075','#7f987c','#4e6d5a','#94a380']))
for xy in [(0,136,143,22),(113,116,218,83),(225,70,68,48),(322,148,58,39)]:
    x,y,w,h=xy;box(d,(x-2,y-2,w+4,h+4),'#829181');box(d,xy,'#b0b49a')
    for yy in range(y+1,y+h,7):
        for xx in range(x+1,x+w,11):
            box(d,(xx+(yy//7)%2*3,yy,9,5),rng.choice(['#c4c5ab','#a2ac96','#b9bea1']))
# Broken boundary walls, with a central entrance and mixed roof fragments.
for x,w in [(142,77),(285,55)]:
    box(d,(x,63,w,19),'#687d71')
    for row in range(3):
        for col in range(w//10):box(d,(x+col*10+1,64+row*6,9,5),'#a0ae99' if (row+col)%2 else '#bdc1a6')
    box(d,(x-2,60,w+4,4),'#d0c8a6')
    for i in range(10):box(d,(rng.randrange(x,x+w),rng.randrange(70,82),4,2),'#7f9977')
# Western arch paired with eastern carved posts.
for x in (214,282):
    box(d,(x,70,10,37),'#81998b');box(d,(x+1,72,7,33),'#b4bea3')
    box(d,(x-2,104,14,5),'#d0cbae')
for i in range(7):
    box(d,(221+i*9,54-abs(3-i)*-2,10,9),'#a9b69e')
box(d,(242,48,26,8),'#d2c9aa')
for row in range(5):box(d,(244-row*3,42+row*2,22+row*6,2),'#557d75')
# Main stone altar: its base is separate from the recoverable glow sprite.
box(d,(244,100,32,24),'#778e80');box(d,(242,97,36,5),'#c6c5a7')
box(d,(248,105,24,14),'#98ab92');box(d,(242,122,36,5),'#b9bea0')
for x in (251,263):box(d,(x,108,4,7),'#5f8c81')
# Readable silhouette of an old stele and fallen columns.
box(d,(148,135,24,18),'#7f9885');box(d,(151,131,18,6),'#b7c1a2')
for y in (139,143,147):box(d,(154,y,12 if y!=143 else 8,1),'#5c7c6d')
for x,y in [(98,80),(333,114),(366,198)]:
    box(d,(x,y,18,9),'#a2b19c');box(d,(x+2,y-3,15,4),'#ccd0b1')
    box(d,(x+3,y+6,11,2),'#6d8e76')
d.ellipse((355,66,426,111),fill='#778e7b');d.ellipse((360,71,421,106),fill='#7aaba2')
for i in range(25):box(d,(rng.randrange(370,407),rng.randrange(77,99),5,1),'#b4cec0')
# A cold brazier and the old caravan chest are scenery.
box(d,(352,159,19,15),'#677d73');box(d,(350,156,23,4),'#b1b79a')
box(d,(312,174,22,13),'#926e4a');box(d,(312,173,22,4),'#c2a16d');box(d,(322,174,3,8),'#d7c18c')
save(im,'ruins_ground')
im,d=canvas(24,24)
d.ellipse((2,16,22,23),fill='#699b8870')
d.polygon([(12,1),(19,9),(16,18),(8,20),(4,12)],fill='#3e716f')
d.polygon([(12,3),(17,10),(14,17),(8,17),(6,11)],fill='#a9d2b2')
d.line((11,6,11,14,16,11,8,10),fill='#f6e5a9',width=1)
box(d,(18,2,1,6),'#f1dda3');box(d,(16,4,5,1),'#f1dda3')
save(im,'star_relic');print('Created original waystation ruins and star relic.')
