#!/usr/bin/env python3
"""Original fish icon atlas and pixel pond for the fishing interaction."""
import random
from create_pixel_assets import canvas, box, save
im,d=canvas(72,24)
for i,colors in enumerate([('#779c94','#d4dfbb'),('#7b9b9c','#b5d4bf'),('#658c91','#d4cb9d')]):
    x=i*24
    d.ellipse((x+5,6,x+21,18),fill=colors[0])
    d.ellipse((x+7,8,x+20,16),fill=colors[1])
    d.polygon([(x+7,11),(x+2,6),(x+2,18),(x+7,14)],fill=colors[0])
    d.polygon([(x+10,8),(x+13,3),(x+16,8)],fill=colors[0])
    box(d,(x+18,10,2,2),'#364f49');box(d,(x+10,11,3,3),'#8ba89b')
    if i==2:
        box(d,(x+13,7,1,9),'#efdc98');box(d,(x+10,11,7,1),'#efdc98')
save(im,'fish')
im,d=canvas(424,84);rng=random.Random(1024)
box(d,(0,0,424,84),'#3f6d70')
box(d,(0,0,424,10),'#7f9b77')
box(d,(0,7,424,3),'#aeb898')
for i in range(220):
    box(d,(rng.randrange(424),rng.randrange(13,82),rng.randrange(2,9),1),rng.choice(['#5d8d88','#77a599','#416e70']))
for x in range(1,58,9):
    box(d,(x,42,8,42),'#b39365');box(d,(x,44,7,1),'#dfc38a')
box(d,(0,39,61,4),'#806447')
for x,y in [(331,35),(378,54),(303,68)]:
    d.ellipse((x,y,x+13,y+6),fill='#789f7b');box(d,(x+7,y+1,6,2),'#a6bc87')
save(im,'fishing_pond');print('Created original fish icons and fishing pond.')
