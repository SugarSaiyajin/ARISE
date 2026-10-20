#!/usr/bin/env python3
"""Create original pixel icons for three farmhouse dishes."""
from create_pixel_assets import canvas, box, save

im, d = canvas(72, 24)
for i in range(3):
    x = i * 24
    d.ellipse((x + 2, 9, x + 22, 21), fill="#557e76")
    d.ellipse((x + 3, 8, x + 21, 19), fill="#d6d0a9")
    if i == 0:
        d.ellipse((x + 5, 9, x + 19, 17), fill="#bda46c")
        for a, b in [(8, 11), (14, 13), (11, 15)]:
            box(d, (x + a, b, 3, 2), "#eee0b7")
        box(d, (x + 11, 10, 2, 2), "#72966b")
        box(d, (x + 8, 4, 1, 3), "#a6b7a0")
        box(d, (x + 14, 2, 1, 4), "#a6b7a0")
    elif i == 1:
        d.ellipse((x + 5, 10, x + 19, 17), fill="#b8854d")
        d.ellipse((x + 8, 9, x + 17, 15), fill="#eeead2")
        box(d, (x + 11, 10, 4, 4), "#e1b854")
        box(d, (x + 7, 15, 3, 1), "#7d9965")
    else:
        d.polygon([(x+4, 10), (x+9, 12), (x+16, 9), (x+21, 12), (x+17, 16), (x+10, 15), (x+4, 17)], fill="#ba925d")
        box(d, (x + 17, 11, 1, 1), "#435b4e")
        for a in [11, 14]:
            box(d, (x + a, 12, 1, 3), "#795f44")
        box(d, (x + 8, 9, 5, 1), "#799963")
save(im, "meals")
print("Created original soup, flatbread and grilled fish icons.")
