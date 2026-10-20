#!/usr/bin/env python3
"""Compose original ARISE music and synthesize effects; requires NumPy."""
from pathlib import Path
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1] / "assets/audio"
ROOT.mkdir(parents=True, exist_ok=True)
RATE = 22050
RNG = np.random.default_rng(530)

def frequency(note):
    return 440 * 2 ** ((note - 69) / 12)

def pluck(note, duration, bright=0.3):
    t = np.arange(round(duration * RATE)) / RATE
    f = frequency(note)
    envelope = np.minimum(t / 0.008, 1) * np.exp(-t * 4 / max(duration, 0.05))
    envelope *= np.minimum((duration - t) / 0.025, 1)
    return (np.sin(2*np.pi*f*t) + bright*np.sin(2*np.pi*f*2*t)*np.exp(-t*6)
            + 0.1*np.sin(2*np.pi*f*3*t)*np.exp(-t*12)) * envelope

def write(name, data, peak=0.7, loop=False):
    maximum = np.abs(data).max()
    if maximum > 0:
        data = data / maximum * peak
    if loop:
        # Match the endpoint to the start over 10 ms, avoiding a loop click.
        n = round(RATE * 0.01)
        fade = np.linspace(0, 1, n)
        if data.ndim == 2:
            fade = fade[:, None]
        data[-n:] = data[-n:] * (1-fade) + data[0] * fade
    pcm = np.round(np.clip(data, -1, 1)*32767).astype("<i2")
    with wave.open(str(ROOT / (name + ".wav")), "wb") as output:
        output.setnchannels(2 if data.ndim == 2 else 1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())

def compose():
    beat = 2/3  # 90 BPM, 16 bars in 3/4 = 32 seconds.
    size = round(32 * RATE)
    mix = np.zeros((size, 2))
    def add(start, signal, volume=1, pan=0):
        index = (round(start*RATE) + np.arange(len(signal))) % size
        mix[index, 0] += signal * volume * (0.75-pan*0.25)
        mix[index, 1] += signal * volume * (0.75+pan*0.25)
    # D pentatonic lead; the accompaniment follows a western waltz pulse.
    melody = [
        [74,78,81], [83,81,78], [76,78,74], [73,69,73],
        [74,78,83], [85,83,81], [78,76,74], [76,73,69],
        [74,81,78], [83,86,85], [81,78,76], [73,76,81],
        [83,81,78], [76,78,74], [73,69,76], [78,76,74],
    ]
    chords = [(50,57,66),(47,54,62),(43,50,59),(45,52,61)] * 4
    for bar, notes in enumerate(melody):
        start = bar * 3 * beat
        for i, note in enumerate(notes):
            add(start+i*beat, pluck(note, beat*1.7, 0.2), 0.24, 0.1)
        bass, middle, top = chords[bar]
        add(start, pluck(bass, beat*2.7, 0.1), 0.22, -0.2)
        for i, note in enumerate([middle,top]):
            add(start+(i+1)*beat, pluck(note, beat*1.8, 0.1), 0.12, -0.4)
        add(start+1.5*beat, pluck(top+12, beat*0.6, 0.45), 0.035, 0.6)
    mix += np.roll(mix, round(RATE*0.18), axis=0)*0.12
    mix += np.roll(mix[:, ::-1], round(RATE*0.31), axis=0)*0.08
    write("cloudbridge_waltz", mix, 0.56, loop=True)

def ambience():
    size = RATE * 32
    wind = RNG.normal(0, 1, size)
    smooth = np.convolve(wind, np.ones(256)/256, mode="same")
    forest = smooth * 0.12
    for start in [2.5, 3, 10.4, 11, 18.5, 19, 26.2]:
        t = np.arange(round(RATE*0.16))/RATE
        phase = 2*np.pi*(1800*t + 1600*t*t)
        tweet = np.sin(phase) * np.sin(np.pi*t/0.16)**2 * 0.08
        offset = round(start*RATE)
        forest[offset:offset+len(t)] += tweet
    write("garden_ambience", forest, 0.16, loop=True)
    hiss = RNG.normal(0, 1, size)
    hiss = np.convolve(hiss, np.ones(3)/3, mode="same") * 0.08
    for i in range(150):
        offset = int(RNG.integers(0, size-1500))
        t = np.arange(1100)/RATE
        drop = np.sin(2*np.pi*(700+int(RNG.integers(800)))*t)*np.exp(-t*100)
        hiss[offset:offset+len(t)] += drop*0.035
    write("rain_ambience", hiss, 0.22, loop=True)

def effects():
    for name, duration, note in [("hoe",0.17,45),("seed",0.14,69),("step",0.08,38),
                                 ("water",0.30,76),("ui",0.10,81)]:
        t = np.arange(round(duration*RATE))/RATE
        noise = RNG.normal(0,1,len(t))
        noise = np.convolve(noise,np.ones(7)/7,mode="same")
        signal = pluck(note,duration,0.12)*0.4
        signal += noise*np.exp(-t*(22 if name=="water" else 48))*(0.8 if name in ["hoe","water","step"] else 0.08)
        write(name,signal,0.20 if name=="step" else 0.48)
    for name, notes in [("harvest",[74,81,86]),("coin",[83,86,90]),("talk",[69,74]),("rest",[62,66,69,74])]:
        duration = 0.9 if name=="rest" else 0.45
        signal = np.zeros(round(duration*RATE))
        for i,note in enumerate(notes):
            part=pluck(note,0.5 if name=="rest" else 0.22,0.35)
            offset=round(i*RATE*(0.1 if name=="rest" else 0.065))
            end=min(len(signal),offset+len(part))
            signal[offset:end]+=part[:end-offset]*0.6
        write(name,signal,0.55)

if __name__=="__main__":
    compose();ambience();effects()
    (ROOT/"catalog.json").write_text(json.dumps({
        "composition":"Cloudbridge Waltz / 雲橋晨曲",
        "authoring":"Original score and procedural sound synthesis for ARISE; no samples or recordings.",
        "music":{"tempo_bpm":90,"meter":"3/4","key":"D major / pentatonic lead","duration_seconds":32},
        "format":{"sample_rate":RATE,"bits":16},
        "loops":["cloudbridge_waltz","garden_ambience","rain_ambience"],
        "effects":["hoe","seed","water","harvest","coin","talk","step","ui","rest"]
    },indent=2,ensure_ascii=False)+"\n")
    print("Created original music, ambience and effects in",ROOT)
