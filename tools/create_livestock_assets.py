#!/usr/bin/env python3
"""Original pixel coop, two-frame hen and egg icon."""
from create_pixel_assets import canvas, box, save
im,d=canvas(112,48)
for stage in range(2):
    x=56*stage
    d.ellipse((x+2,38,x+53,47),fill='#3b55464d')
    if stage==0:
        for dx in (9,23,38):
            box(d,(x+dx,38,10,6),'#a8ae92');box(d,(x+dx+1,36,8,3),'#d6c7a2')
        box(d,(x+16,33,24,3),'#b08854');box(d,(x+13,30,23,3),'#d0a269')
        continue
    box(d,(x+7,19,43,24),'#987046')
    for y in range(21,43,5):
        box(d,(x+8,y,41,3),'#bf9561');box(d,(x+9,y,40,1),'#d6ad75')
    box(d,(x+11,25,16,18),'#514f3d');box(d,(x+13,26,12,15),'#6c6a4b')
    for row in range(9):
        box(d,(x+21-row*2,3+row*2,13+row*4,3),'#4e7773');box(d,(x+21-row*2,3+row*2,13+row*4,1),'#8baba0')
    box(d,(x+3,20,50,3),'#344f4e')
    box(d,(x+32,25,11,9),'#617c65');box(d,(x+33,26,9,6),'#d9d5a5')
    box(d,(x+37,25,1,9),'#816646')
    box(d,(x+10,42,19,3),'#bea375')
    box(d,(x+32,37,16,8),'#9c794f');box(d,(x+31,36,18,2),'#d5b57b')
    for dx in (34,39,44):box(d,(x+dx,34,3,3),'#d7c495')
save(im,'chicken_coop')
im,d=canvas(32,16)
for frame in range(2):
    x=16*frame
    d.ellipse((x+2,12,x+14,15),fill='#3e57484d')
    box(d,(x+5,12,2,3),'#d4a15c');box(d,(x+10,12,2,3),'#d4a15c')
    d.ellipse((x+3,5,x+13,13),fill='#eee2b6')
    box(d,(x+3,5,3,4),'#fff0d0');box(d,(x+6,8,5,3),'#d3c69d')
    if frame==0:
        box(d,(x+10,3,4,6),'#f4e8c2');box(d,(x+11,1,3,3),'#b56651')
        box(d,(x+13,5,2,2),'#d29b54');box(d,(x+12,4,1,1),'#3a463d')
    else:
        box(d,(x+11,7,4,5),'#f4e8c2');box(d,(x+11,6,3,2),'#b56651')
        box(d,(x+14,11,2,2),'#d29b54');box(d,(x+13,9,1,1),'#3a463d')
save(im,'hen')
im,d=canvas(24,24)
d.ellipse((3,18,22,23),fill='#3e57484d')
d.ellipse((6,4,18,21),fill='#c8b79a');d.ellipse((7,3,17,19),fill='#f6e9c6')
d.ellipse((9,5,13,10),fill='#fff6db');box(d,(15,13,1,4),'#e2d0ab')
save(im,'egg');print('Created original coop, hen and egg sprites.')
