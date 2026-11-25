#!/usr/bin/env python3
"""Issue 1752 Gate 3 (Artoo on PR 1948): check that a stem-split music loop gives a usable calm mix (all stems but drums)
and intense mix (the song), on the same trim points.

  python3 stem_loop_check.py <song.mp3> <stems.zip> [--xfade <seconds>] [--out <folder>]

Prints, for each mix: length, the stems' offset against the song, the loop seam (level and sample jump at the wrap), and the
calm mix's level under the intense one, and a real 2 s calm-to-intense switch (and back) at four points of the loop. --xfade folds that many seconds of each mix's tail into its head (the loop
crossfade mastering applies), on the same samples for both mixes, before the seams are measured. With --out it writes calm.wav and intense.wav cut to the same samples.
Needs ffmpeg and numpy. Exit 0 and STEM LOOP CHECK PASS when every check passes."""
import subprocess, sys, zipfile, tempfile, os
import numpy as np
SR = 48000

def load(p):
    r = subprocess.run(['ffmpeg', '-v', 'error', '-i', p, '-f', 'f32le', '-ac', '2', '-ar', str(SR), '-'], capture_output=True, check=True)
    return np.frombuffer(r.stdout, dtype=np.float32).reshape(-1, 2)

def db(a):
    return 20 * np.log10(np.sqrt((a.astype(np.float64) ** 2).mean()) + 1e-9)

def offset(a, b, maxlag=4800):
    # samples b lags a (positive: b is late), on the first 10 s of the mono sums
    a = a[:10 * SR].mean(1); b = b[:10 * SR].mean(1); n = min(len(a), len(b))
    fa = np.fft.rfft(a[:n], 2 * n); fb = np.fft.rfft(b[:n], 2 * n)
    cc = np.fft.irfft(fb * np.conj(fa))
    cc = np.concatenate([cc[-maxlag:], cc[:maxlag + 1]])
    return int(np.argmax(cc)) - maxlag

def seam(x, name, fails):
    head, tail = x[:SR // 2], x[-SR // 2:]
    jump = float(np.abs(x[-1] - x[0]).max())
    lh, lt = db(head), db(tail)
    ok = abs(lh - lt) <= 3.0 and jump <= 0.1
    print(f'  {name}: {len(x) / SR:.3f} s, first 0.5 s {lh:.1f} dB, last 0.5 s {lt:.1f} dB, wrap jump {jump:.3f}', '' if ok else '  FAIL')
    if not ok: fails.append(name + ' seam')

def main():
    song, zp = sys.argv[1], sys.argv[2]
    out = sys.argv[sys.argv.index('--out') + 1] if '--out' in sys.argv else None
    fails = []
    mix = load(song)
    with tempfile.TemporaryDirectory() as td:
        zipfile.ZipFile(zp).extractall(td)
        stems = {os.path.splitext(f)[0]: load(os.path.join(td, f)) for f in sorted(os.listdir(td)) if f.endswith(('.mp3', '.wav'))}
    live = {k: v for k, v in stems.items() if db(v) > -60}
    print('stems with sound:', ', '.join(f'{k} {db(v):.1f} dB' for k, v in live.items()), '| silent:', ', '.join(k for k in stems if k not in live))
    if 'drums' not in live: fails.append('no drums stem')
    n0 = min(len(v) for v in stems.values())
    total = sum(v[:n0] for v in stems.values())
    off = offset(mix, total)
    print(f'stems sum vs song: offset {off} samples ({off / SR * 1000:.1f} ms), song {len(mix)} samples, stems {n0} samples')
    # align the stems to the song, then cut both mixes to the song's own samples
    def align(v):
        v = v[off:] if off > 0 else np.concatenate([np.zeros((-off, 2), np.float32), v])
        v = v[:len(mix)]
        return np.concatenate([v, np.zeros((len(mix) - len(v), 2), np.float32)]) if len(v) < len(mix) else v
    calm = sum(align(v) for k, v in stems.items() if k != 'drums')
    resid = db(align(total) - mix) - db(mix)
    print(f'stems sum minus song after alignment: {resid:.1f} dB under the song', '' if resid <= -15 else '  FAIL')
    if resid > -15: fails.append('stems do not rebuild the song')
    intense = mix
    xf = float(sys.argv[sys.argv.index('--xfade') + 1]) if '--xfade' in sys.argv else 0.0
    if xf > 0:
        k = int(xf * SR); r = np.linspace(0, 1, k, dtype=np.float32)[:, None]
        def fold(x):
            y = x[:-k].copy(); y[:k] = x[:k] * r + x[-k:] * (1 - r); return y
        calm, intense = fold(calm), fold(intense)
        print(f'loop crossfade {xf} s applied to both mixes (same samples)')
    gap = db(intense) - db(calm)
    print(f'calm mix is {gap:.1f} dB under the intense mix', '' if 1.0 <= gap <= 12 else '  FAIL')
    if not (1.0 <= gap <= 12): fails.append('calm level')
    seam(intense, 'intense (song)', fails)
    seam(calm, 'calm (no drums)', fails)
    # A real calm-to-intense switch (2 s ramp) at each quarter of the loop, and back. Pass: no dip under the softer of the
    # two mixes around the switch (more than 1.5 dB, 50 ms windows) and no step between neighbouring windows larger than the
    # largest step either mix has on its own.
    w = SR // 20
    def env(x):
        m = x.mean(1); n = len(m) // w
        return 10 * np.log10((m[:n * w].reshape(n, w).astype(np.float64) ** 2).mean(1) + 1e-12)
    ec, ei = env(calm), env(intense)
    own = max(np.abs(np.diff(ec)).max(), np.abs(np.diff(ei)).max())
    k = 2 * SR; r = np.linspace(0, 1, k, dtype=np.float32)[:, None]
    for q in (0.125, 0.375, 0.625, 0.875):
        for a, b, label in ((calm, intense, 'calm to intense'), (intense, calm, 'intense to calm')):
            at = int(q * len(intense)); s0, s1 = at - SR, at + k + SR
            seg = np.concatenate([a[s0:at], a[at:at + k] * (1 - r) + b[at:at + k] * r, b[at + k:s1]])
            e = env(seg); floor = np.minimum(env(a[s0:s1]), env(b[s0:s1]))
            n = min(len(e), len(floor)); dip = float((floor[:n] - e[:n]).max()); step = float(np.abs(np.diff(e)).max())
            ok = dip <= 1.5 and step <= own + 1.0
            print(f'  switch {label} at {at / SR:5.1f} s: deepest dip {dip:.2f} dB, largest step {step:.1f} dB (the mixes alone: {own:.1f})', '' if ok else '  FAIL')
            if not ok: fails.append(f'switch at {at / SR:.1f} s')
    if out:
        os.makedirs(out, exist_ok=True)
        for name, x in (('calm', calm), ('intense', intense)):
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ac', '2', '-ar', str(SR), '-i', '-', os.path.join(out, name + '.wav')],
                           input=np.ascontiguousarray(x, dtype=np.float32).tobytes(), check=True)
    print('STEM LOOP CHECK PASS' if not fails else 'STEM LOOP CHECK FAIL: ' + ', '.join(fails))
    return 0 if not fails else 1

if __name__ == '__main__':
    sys.exit(main())
