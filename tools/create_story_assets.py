#!/usr/bin/env python3
"""Original pixel vignette: two cups beside a window overlooking Cloudbridge."""
from create_pixel_assets import canvas, box, save
im,d=canvas(320,64)
box(d,(0,0,320,64),'#394d42')
box(d,(5,3,310,57),'#c6b78e')
# Open window: eastern roofs, river, stone bridge and a western clock tower.
box(d,(30,5,260,43),'#afc6a3');box(d,(30,29,260,19),'#7c9a6b')
for x,y in [(45,18),(219,16),(263,19)]:
    box(d,(x,y,23,22),'#c9bd96')
    for row in range(6):box(d,(x+7-row*2,y-7+row*2,10+row*4,2),'#52786b')
    box(d,(x+8,y+11,8,11),'#8d6e4e')
box(d,(158,4,24,44),'#679e9c');box(d,(163,7,4,33),'#9bc4b0')
box(d,(144,29,51,11),'#d1c9a6');box(d,(143,28,53,2),'#e9d8ac')
for x in range(146,193,9):box(d,(x,32,7,4),'#afba9b')
box(d,(106,15,15,28),'#b2b29a')
d.polygon([(102,15),(113,2),(125,15)],fill='#8b695b')
d.ellipse((108,18,119,29),fill='#e8dbb2');d.line((113,20,113,24,117,25),fill='#67715c',width=1)
for x in (25,151,286):box(d,(x,3,5,48),'#7c6147');box(d,(x,3,1,48),'#e2c799')
box(d,(23,46,272,4),'#d9bd87')
# The warm table and two cups in the foreground.
box(d,(0,52,320,12),'#8b6747');box(d,(0,50,320,3),'#c9a474')
for x in (113,190):
    d.ellipse((x-7,56,x+16,62),fill='#d6c69d')
    box(d,(x-1,49,12,9),'#739d8b');box(d,(x-2,48,14,3),'#dce1be')
    box(d,(x,49,10,1),'#a4754d');box(d,(x+11,51,4,5),'#95b49b')
    for dx in (2,7):box(d,(x+dx,43,1,3),'#e8e0bb')
box(d,(246,43,30,16),'#bb9360');box(d,(244,42,34,4),'#e2bd80')
for x in (249,256,263,270):box(d,(x,40,4,4),'#bd9ab1')
save(im,'tea_memory');print('Created original Cloudbridge tea memory illustration.')
