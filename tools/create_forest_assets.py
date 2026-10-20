#!/usr/bin/env python3
"""Original pixel forest clearing, ruins and renewable forage sprites."""
import random
from create_pixel_assets import canvas, box, save

def ground():
    im,d=canvas(480,270);rng=random.Random(571)
    box(d,(0,0,480,270),'#58774e')
    for i in range(4200):
        x,y=rng.randrange(480),rng.randrange(270)
        box(d,(x,y,2 if i%8==0 else 1,1),rng.choice(['#658854','#73945e','#4c7048','#819d62']))
    # A winding old merchant trail opens onto a mossy gathering clearing.
    for xy in [(0,136,153,22),(125,113,208,73),(182,97,53,17),(329,146,83,47)]:
        x,y,w,h=xy;box(d,(x-2,y-2,w+4,h+4),'#71825b');box(d,xy,'#a89d73')
        for i in range(w*h//18):
            px,py=rng.randrange(x,x+w),rng.randrange(y,y+h)
            box(d,(px,py,rng.randrange(1,4),1),rng.choice(['#bdb18a','#938b65','#c7b98b']))
    # Spring pool, stone banks and an abandoned way shrine.
    d.ellipse((331,53,422,104),fill='#7f8c6c')
    d.ellipse((336,58,417,99),fill='#b0b39a')
    d.ellipse((340,61,413,96),fill='#4e8580')
    d.ellipse((347,64,407,92),fill='#66a19a')
    for i in range(35):
        box(d,(rng.randrange(350,400),rng.randrange(68,88),rng.randrange(2,6),1),'#9bc4ac')
    for x,y in [(339,67),(411,79),(363,96),(400,57)]:
        box(d,(x,y,7,3),'#8a9b7e');box(d,(x+1,y-2,4,3),'#b2b69b')
    box(d,(432,166,21,25),'#738c76');box(d,(429,189,27,5),'#a8ad90')
    box(d,(437,170,11,14),'#425f59');box(d,(440,173,5,8),'#8cb99b')
    d.polygon([(427,166),(442,156),(457,166)],fill='#58786c')
    box(d,(430,166,24,2),'#b0b69a')
    for x,y in [(68,123),(258,107),(304,201),(411,112)]:
        box(d,(x,y,2,9),'#486c43')
        box(d,(x-2,y,6,3),'#d3bd8c')
        box(d,(x-1,y+1,2,1),'#f0dbad')
    # Direction marker at the only exit.
    box(d,(27,119,2,15),'#786047');box(d,(17,116,23,7),'#bd9f6e')
    save(im,'forest_ground')

def forage():
    im,d=canvas(96,64)
    for spent in (False,True):
        y=32 if spent else 0
        if spent:
            d.ellipse((8,y+22,24,y+27),fill='#4b6443')
            box(d,(12,y+21,10,3),'#896a45');box(d,(14,y+21,5,1),'#b89a62')
            box(d,(44,y+23,5,3),'#879780');box(d,(53,y+24,4,2),'#9aaa8f')
            for x in (76,81,86):box(d,(x,y+23,2,4),'#8ba975')
            continue
        d.ellipse((5,23,28,29),fill='#3f594652')
        box(d,(7,17,21,8),'#775136');box(d,(8,16,18,3),'#ba8954')
        box(d,(9,21,16,2),'#94673e');box(d,(10,18,13,1),'#d1a567')
        d.ellipse((4,15,12,25),fill='#d0ae76');d.ellipse((6,17,10,23),fill='#8d633e')
        d.line((21,16,25,12),fill='#b98b54',width=2)
        d.polygon([(36,25),(39,16),(48,10),(57,15),(61,25)],fill='#526959')
        d.polygon([(38,22),(42,15),(49,12),(55,17),(57,23)],fill='#a4b09a')
        d.polygon([(43,15),(49,12),(52,16),(46,18)],fill='#cbd0b2')
        box(d,(41,23,15,2),'#7b927b');box(d,(52,17,2,5),'#728871')
        d.ellipse((70,24,91,29),fill='#3c594650')
        for x,h in [(74,12),(80,8),(86,14)]:
            box(d,(x,h+2,2,15),'#c0d39a')
            d.polygon([(x,21),(x-6,17),(x-5,14),(x,18)],fill='#8fb780')
            d.polygon([(x+1,20),(x+6,15),(x+7,17),(x+1,24)],fill='#a9c38c')
            box(d,(x-2,h,6,4),'#b8a4c6');box(d,(x,h-2,2,7),'#e0c9d5')
    save(im,'forage')

if __name__=='__main__':
    ground();forage();print('Created original forest and forage assets.')
