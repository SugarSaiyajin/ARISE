#!/usr/bin/env python3
"""Ensure all production text can render from the bundled font without OS fallback."""
from pathlib import Path
from fontTools.ttLib import TTFont
ROOT=Path(__file__).resolve().parents[1]
font=TTFont(ROOT/'assets/fonts/CloudbridgeTC.otf')
cmap=font.getBestCmap()
missing={}
for path in [*(ROOT/'scripts').rglob('*.gd'),*(ROOT/'data').rglob('*.tres'),ROOT/'project.godot']:
 chars={ch for ch in path.read_text() if ord(ch)>127 and not ch.isspace() and ord(ch) not in cmap}
 if chars:missing[str(path.relative_to(ROOT))]=''.join(sorted(chars))
if missing:raise SystemExit('Missing bundled glyphs: '+repr(missing))
print('FONT COVERAGE: all production text covered')
