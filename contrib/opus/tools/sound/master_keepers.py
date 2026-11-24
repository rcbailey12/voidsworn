"""Master the issue 1752 Gate 2 keepers into game-ready ogg files.

Usage: python3 master_keepers.py --keepers contrib/opus/sound/keepers_gate2.json
           --src A2=<dir> --src A3=<dir> ... --out <dir> [--report report.json]
Each <dir> holds a wave's ElevenLabs takes (<id>_<take>.mp3), as relayed on the
voidsworn-relay branch named in the keepers file. Needs ffmpeg and numpy only.

Per keeper: pick the source (fold, one channel, stereo, or a t1+t2 mix), trim the
dead head, high-pass (40 Hz default), optional EQ, gain to the category target
(loudest 50 ms window), keep the peak at or under -1 dBFS, fade the tail, and
write 44.1 kHz Vorbis. Battle sounds come out mono (Ryan's choice B, plan 8.1).
"""
import argparse, json, os, subprocess, tempfile
import numpy as np

SR = 44100
EQ = {
    "presence": "highshelf=f=2000:g=3",
    "air": "highshelf=f=2000:g=2",
    "mid": "equalizer=f=1200:t=q:w=1:g=4",
    "bio": "lowshelf=f=200:g=-6,highshelf=f=1500:g=6",
}

def load(path):
    r = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"],
                       capture_output=True, check=True)
    return np.frombuffer(r.stdout, np.float32).reshape(-1, 2).copy()

def mid_energy(x):
    f = np.abs(np.fft.rfft(x)) ** 2
    fr = np.fft.rfftfreq(len(x), 1 / SR)
    return f[(fr > 500) & (fr < 4000)].sum()

def corr(a):
    L, R = a[:, 0], a[:, 1]
    if L.std() == 0 or R.std() == 0:
        return 1.0
    return float(np.corrcoef(L, R)[0, 1])

def pick_source(a, src):
    if src == "stereo":
        return a, "stereo"
    if src == "L":
        return a[:, :1], "L"
    if src == "R":
        return a[:, 1:2], "R"
    if src == "fold" or (src == "auto" and corr(a) >= 0.3):
        return ((a[:, 0] + a[:, 1]) / 2)[:, None], "fold"
    ch = 0 if mid_energy(a[:, 0]) >= mid_energy(a[:, 1]) else 1
    return a[:, ch:ch + 1], "LR"[ch]

def onset(x, rel_db=-40):
    env = np.abs(x).max(axis=1)
    thr = env.max() * 10 ** (rel_db / 20)
    idx = np.argmax(env > thr)
    return max(0, idx - int(0.002 * SR))

def ffilter(x, chain):
    if not chain:
        return x
    ch = x.shape[1]
    r = subprocess.run(["ffmpeg", "-v", "error", "-f", "f32le", "-ac", str(ch), "-ar", str(SR), "-i", "-",
                        "-af", chain, "-f", "f32le", "-ac", str(ch), "-ar", str(SR), "-"],
                       input=x.astype(np.float32).tobytes(), capture_output=True, check=True)
    return np.frombuffer(r.stdout, np.float32).reshape(-1, ch).copy()

def loud_db(x):
    m = x.mean(axis=1)
    w = int(0.05 * SR)
    if len(m) <= w:
        return 20 * np.log10(np.sqrt((m ** 2).mean()) + 1e-9)
    c = np.convolve(m ** 2, np.ones(w) / w, mode="valid")
    return 10 * np.log10(c.max() + 1e-12)

def master(k, srcdirs, targets):
    d = srcdirs[k["wave"]]
    if k["take"] == "t1+t2":
        a1, a2 = load(os.path.join(d, k["id"] + "_t1.mp3")), load(os.path.join(d, k["id"] + "_t2.mp3"))
        a1, a2 = a1[onset(a1):], a2[onset(a2):]
        n = max(len(a1), len(a2))
        a = np.zeros((n, 2), np.float32)
        a[:len(a1)] += 0.5 * a1
        a[:len(a2)] += 0.5 * a2
    else:
        a = load(os.path.join(d, f'{k["id"]}_{k["take"]}.mp3'))
    c = corr(a)
    x, used = pick_source(a, k.get("src", "auto"))
    # trim_ms: a fixed head trim from a plan note (8.6); otherwise trim to the onset.
    if k.get("notrim"):
        cut = 0
    elif "trim_ms" in k:
        cut = int(k["trim_ms"] / 1000 * SR)
    else:
        cut = onset(x)
    x = x[cut:]
    chain = [f'highpass=f={k.get("hp", 40)}:poles=2']
    if k.get("eq"):
        chain.append(EQ[k["eq"]])
    if k.get("cents"):
        ratio = 2 ** (k["cents"] / 1200)
        chain.append(f"asetrate={SR * ratio:.0f},aresample={SR}")
    x = ffilter(x, ",".join(chain))
    gain = targets[k["cat"]] - loud_db(x)
    if k["cat"] == "amb":
        gain = targets["amb"] - 10 * np.log10((x ** 2).mean() + 1e-12)
    peak = np.abs(x).max() * 10 ** (gain / 20)
    limited = False
    if peak > 10 ** (-1 / 20):
        gain -= 20 * np.log10(peak / 10 ** (-1 / 20))
        limited = True
    x = x * 10 ** (gain / 20)
    # Looping ambience keeps its edges: a fade to zero would dip at every loop seam.
    if k["cat"] != "amb":
        fi, fo = int(0.001 * SR), int(0.015 * SR)
        x[:fi] *= np.linspace(0, 1, fi)[:, None]
        x[-fo:] *= np.linspace(1, 0, fo)[:, None]
    return x, {"corr": round(c, 2), "src": used, "gain_db": round(float(gain), 1), "limited": limited,
               "trim_ms": round(cut / SR * 1000, 1), "seconds": round(len(x) / SR, 2), "loud_db": round(float(loud_db(x)), 1)}

def write_ogg(x, path):
    ch = x.shape[1]
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ac", str(ch), "-ar", str(SR), "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "6", path], input=x.astype(np.float32).tobytes(), check=True)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--keepers", required=True)
    p.add_argument("--src", action="append", default=[])
    p.add_argument("--out", required=True)
    p.add_argument("--report")
    a = p.parse_args()
    cfg = json.load(open(a.keepers))
    srcdirs = dict(s.split("=", 1) for s in a.src)
    os.makedirs(a.out, exist_ok=True)
    rep = {}
    for k in cfg["keepers"]:
        name = k.get("out", k["id"])
        x, info = master(k, srcdirs, cfg["targets_db"])
        write_ogg(x, os.path.join(a.out, name + ".ogg"))
        info.update({"from": f'{k["wave"]} {k["take"]}', "cat": k["cat"]})
        rep[name] = info
        print(name, info)
    if a.report:
        json.dump(rep, open(a.report, "w"), indent=1)
    print(f"MASTER KEEPERS PASS: {len(rep)} files")

if __name__ == "__main__":
    main()
