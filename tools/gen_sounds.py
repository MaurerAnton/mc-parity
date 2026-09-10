#!/usr/bin/env python3
"""Synthesize CC0 mob sounds (ours — no external media).
Python writes WAVs; ffmpeg converts to OGG (the engine plays OGG only).
Run from the repo root:  python3 tools/gen_sounds.py
"""
import math, struct, wave, subprocess, os, random as r

SR = 22050

def write_wav(path, samples):
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        w.writeframes(frames)

def ogg_from(wav, ogg):
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", ogg], check=True)
    os.remove(wav)

def heartbeat():
    # lub-dub: two low thumps (55Hz/48Hz), ~0.22s, then ~0.9s silence
    out = []
    for i in range(int(SR * 1.1)):  # 1.1s per beat, loopable
        t = i / SR
        beat = t % 1.1
        env = 0.0
        if beat < 0.12:
            env = math.exp(-28 * beat) * (1 - beat / 0.12)
            f = 58
        elif 0.14 <= beat < 0.30:
            b2 = beat - 0.14
            env = math.exp(-22 * b2) * (1 - b2 / 0.16) * 0.8
            f = 50
        out.append(math.sin(2 * math.pi * f * t) * env * 0.9)
    return out

def sonic_boom():
    # whoosh: descending noise sweep 700->90Hz with a sharp attack, 0.8s
    out = []
    r.seed(7)  # once: per-sample reseed froze the noise into a DC offset
    for i in range(int(SR * 0.8)):
        t = i / SR
        prog = t / 0.8
        f = 700 * (0.12 ** prog) + 30          # exponential descent
        env = math.sin(math.pi * prog) ** 2    # fade in/out
        noise = (r.random() * 2 - 1) * 0.35
        tone = math.sin(2 * math.pi * f * t) * 0.5
        out.append((noise + tone) * env)
    return out

def _yap(t, dur, f0, f1):
    # one bark syllable: descending chirp, sharp attack, fast decay
    prog = t / dur
    f = f0 + (f1 - f0) * prog
    env = math.exp(-9 * prog) * min(1.0, t / 0.008)
    return (math.sin(2 * math.pi * f * t) * 0.7
            + math.sin(2 * math.pi * 2 * f * t) * 0.25) * env

def fox_bark():
    # 3 quick yaps (MC fox bark rhythm), ~0.5s
    out, durs, gaps = [], [0.10, 0.09, 0.11], [0.07, 0.08]
    seq = [(0.10, 760, 380), (0.09, 700, 360), (0.11, 640, 340)]
    for k, (dur, f0, f1) in enumerate(seq):
        for i in range(int(SR * dur)):
            out.append(_yap(i / SR, dur, f0, f1) * 0.9)
        if k < len(gaps):
            out += [0.0] * int(SR * gaps[k])
    return out

def fox_hurt():
    # short high whine, 0.28s
    dur, out = 0.28, []
    for i in range(int(SR * dur)):
        t = i / SR
        prog = t / dur
        f = 1050 - 500 * prog
        trem = 0.75 + 0.25 * math.sin(2 * math.pi * 30 * t)
        env = math.exp(-4 * prog) * min(1.0, t / 0.01)
        out.append(math.sin(2 * math.pi * f * t) * trem * env * 0.8)
    return out

def bee_buzz():
    # loopable 1.2s wingbeats hum: 185Hz + harmonics, 25Hz AM flutter.
    # All partials complete integer cycles in 1.2s (no loop click).
    dur, out = 1.2, []
    for i in range(int(SR * dur)):
        t = i / SR
        am = 0.6 + 0.4 * math.sin(2 * math.pi * 25 * t)
        s = (math.sin(2 * math.pi * 185 * t) * 0.55
             + math.sin(2 * math.pi * 370 * t) * 0.25
             + math.sin(2 * math.pi * 555 * t) * 0.12)
        out.append(s * am * 0.5)
    return out

def _bleat(dur, f0, f1, vib_rate, vib_depth):
    # goat "maa": vibrato + tremolo on a two-harmonic tone
    out = []
    for i in range(int(SR * dur)):
        t = i / SR
        prog = t / dur
        f = (f0 + (f1 - f0) * prog
             + vib_depth * math.sin(2 * math.pi * vib_rate * t))
        # integrate frequency for phase (avoids FM clicks)
        phase = 2 * math.pi * ((f0 * t + (f1 - f0) * t * t / (2 * dur))
                               - vib_depth / (2 * math.pi * vib_rate)
                               * math.cos(2 * math.pi * vib_rate * t))
        trem = 0.7 + 0.3 * math.sin(2 * math.pi * vib_rate * t)
        env = min(1.0, t / 0.02) * min(1.0, (dur - t) / 0.05)
        out.append((math.sin(phase) * 0.6
                    + math.sin(2 * phase) * 0.25) * trem * env * 0.8)
    return out

def goat_bleat():
    return _bleat(0.75, 360, 300, 5.5, 28)

def goat_hurt():
    return _bleat(0.25, 540, 380, 9.0, 30)

write_wav("/tmp/hb.wav", heartbeat())
write_wav("/tmp/boom.wav", sonic_boom())
ogg_from("/tmp/hb.wav", "sounds/mc_parity_warden_heartbeat.ogg")
ogg_from("/tmp/boom.wav", "sounds/mc_parity_warden_boom.ogg")
write_wav("/tmp/fox_bark.wav", fox_bark())
ogg_from("/tmp/fox_bark.wav", "sounds/mc_parity_fox_bark.ogg")
write_wav("/tmp/fox_hurt.wav", fox_hurt())
ogg_from("/tmp/fox_hurt.wav", "sounds/mc_parity_fox_hurt.ogg")
write_wav("/tmp/bee_buzz.wav", bee_buzz())
ogg_from("/tmp/bee_buzz.wav", "sounds/mc_parity_bee_buzz.ogg")
write_wav("/tmp/goat_bleat.wav", goat_bleat())
ogg_from("/tmp/goat_bleat.wav", "sounds/mc_parity_goat_bleat.ogg")
write_wav("/tmp/goat_hurt.wav", goat_hurt())
ogg_from("/tmp/goat_hurt.wav", "sounds/mc_parity_goat_hurt.ogg")
print("done.")
