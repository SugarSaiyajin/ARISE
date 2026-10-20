#!/usr/bin/env python3
"""Original four-state pixel drying rack and dried food icons."""
from create_pixel_assets import canvas, box, save

def rack():
    atlas,d=canvas(192,40)
    for stage in range(4):
        x=stage*48
        d.ellipse((x+3,31,x+45,39),fill='#354e3f55')
        if stage==0:
            for dx in (5,38):
                box(d,(x+dx,30,5,6),'#abac8e');box(d,(x+dx+1,29,3,2),'#d6c899')
            box(d,(x+10,31,25,3),'#96704b');box(d,(x+14,28,19,3),'#c39a62')
            continue
        for dx in (6,38):
            box(d,(x+dx,7,4,29),'#765139');box(d,(x+dx,7,1,27),'#bb925e')
        box(d,(x+4,8,40,3),'#d1b07b');box(d,(x+9,12,32,3),'#87633e')
        for y in (19,27):
            box(d,(x+3,y,42,4),'#8e6942');box(d,(x+4,y-1,40,2),'#d7b57a')
            for dx in range(7,42,5):box(d,(x+dx,y,2,3),'#b99a62')
        d.line((x+8,29,x+40,9),fill='#b48855',width=2)
        if stage>=2:
            for dx in (10,19,28,36):
                box(d,(x+dx,15,5,3),'#d9bd7b');box(d,(x+dx,24,5,2),'#c18b57')
        if stage==3:
            box(d,(x+17,28,18,7),'#ad7e4d');box(d,(x+16,27,20,2),'#e2bc77')
            for dx in (19,24,29):box(d,(x+dx,25,3,3),'#e7cc8e')
            box(d,(x+27,4,1,7),'#f9e3a0');box(d,(x+24,7,7,1),'#f9e3a0')
    save(atlas,'drying_rack')

def goods():
    im,d=canvas(72,24)
    for col in range(3):
        x=col*24
        d.ellipse((x+2,17,x+22,22),fill='#38534055')
        if col==0:
            for dx,dy in ((5,7),(11,5),(9,12)):
                box(d,(x+dx,dy,7,5),'#d1b779');box(d,(x+dx+1,dy,5,2),'#efe0ab')
        elif col==1:
            for dx in (7,12,17):
                d.line((x+dx,7,x+12,20),fill='#d0ae69',width=1)
                for y in (5,8,11):box(d,(x+dx-2,y,4,2),'#ead29a')
            box(d,(x+8,15,10,2),'#867451')
        else:
            box(d,(x+5,9,15,11),'#a47b52');box(d,(x+4,8,17,3),'#dfbb7d')
            for dx,dy in ((7,7),(12,6),(16,7),(10,10),(15,11)):
                box(d,(x+dx,dy,3,3),'#a36767');box(d,(x+dx,dy,1,1),'#dba18a')
    save(im,'dried_goods')

if __name__=='__main__':
    rack();goods();print('Created drying rack and dried goods assets.')
