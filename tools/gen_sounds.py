#!/usr/bin/env python3
"""Synthesize the warden's heartbeat + sonic boom sounds (CC0 — ours).
Python writes WAVs; ffmpeg converts to OGG (the engine plays OGG only).
"""
import math, struct, wave, subprocess, os

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
    for i in range(int(SR * 0.8)):
        t = i / SR
        prog = t / 0.8
        f = 700 * (0.12 ** prog) + 30          # exponential descent
        env = math.sin(math.pi * prog) ** 2    # fade in/out
        import random as r
        r.seed(7)
        noise = (r.random() * 2 - 1) * 0.35
        tone = math.sin(2 * math.pi * f * t) * 0.5
        out.append((noise + tone) * env)
    return out

write_wav("/tmp/hb.wav", heartbeat())
write_wav("/tmp/boom.wav", sonic_boom())
ogg_from("/tmp/hb.wav", "sounds/mc_parity_warden_heartbeat.ogg")
ogg_from("/tmp/boom.wav", "sounds/mc_parity_warden_boom.ogg")
print("sounds written:", os.path.getsize("sounds/mc_parity_warden_heartbeat.ogg"),
      os.path.getsize("sounds/mc_parity_warden_boom.ogg"), "bytes")
