#!/usr/bin/env python3
"""Read-only alpha registration of the seven approved resident identities."""
from register_summer_art import ROOT,resident_frames
from PIL import Image
import json,hashlib
names=['qinghe','luoan','rein','lyria','borin','yunji','qinglin']
frames={}; sizes={}; scales={}; provenance={}
for name in names:
 path=ROOT/'assets/pixel/resident_walk'/f'{name}.png'
 rows=resident_frames(name,4,'resident_walk')
 # Generated source rows visually inspected: blacksmith and elf have E/W reversed.
 if name in ['rein','lyria']: rows[1],rows[2]=rows[2],rows[1]
 frames[name]=rows
 sizes[name]=list(Image.open(path).size)
 scales[name]=max(f[5] for row in rows for f in row)
 provenance[name]={'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'original_size':sizes[name],'source_preserved':True,'approval':'approved resident identities, production walking extension','frames_used':16,'directions':['south','west','east','north']}
text='extends RefCounted\n# Alpha geometry only; source PNGs unchanged.\n'
for key,data in [('FRAMES',frames),('SIZES',sizes),('HEIGHTS',scales)]:text+='const '+key+' := '+json.dumps(data,separators=(',',':'))+'\n'
(ROOT/'scripts/resident_walk_frames.gd').write_text(text)
(ROOT/'docs/resident-walk-provenance-0.27.json').write_text(json.dumps(provenance,indent=2)+'\n')
print('Registered 112 frames in seven original atlases')
