#!/usr/bin/env python3
"""Validate authored PCM audio without optional authoring dependencies."""
from array import array
import json
from pathlib import Path
import sys
import wave

root = Path(__file__).resolve().parents[1] / "assets/audio"
catalog = json.loads((root / "catalog.json").read_text())
count = 0
for name in catalog["loops"] + catalog["effects"]:
    with wave.open(str(root / (name + ".wav"))) as source:
        assert source.getsampwidth() == 2 and source.getframerate() == 22050, name
        channels = source.getnchannels()
        frames = source.getnframes()
        samples = array("h", source.readframes(frames))
    if sys.byteorder != "little":
        samples.byteswap()
    peak = max(abs(sample) for sample in samples) / 32768
    rms = (sum(sample * sample for sample in samples) / len(samples)) ** 0.5 / 32768
    mean = sum(samples) / len(samples) / 32768
    assert 0.001 < rms < 0.4 and peak < 0.95, (name, "silence or clipping", rms, peak)
    assert abs(mean) < 0.02, (name, "DC offset", mean)
    if name in catalog["loops"]:
        assert frames == 32 * 22050, name
        for channel in range(channels):
            assert abs(samples[channel] - samples[-channels + channel]) <= 2, (name, "loop discontinuity")
    else:
        assert 0.05 <= frames / 22050 <= 1.0, name
    count += 1
print(f"AUDIO FILE CHECKS: {count} original PCM files passed")
