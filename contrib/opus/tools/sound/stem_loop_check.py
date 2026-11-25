#!/usr/bin/env python3
"""Issue 1752 Gate 3 (Artoo on PR 1948): check that a stem-split music loop gives a usable calm mix (all stems but drums)
and intense mix (the song), on the same trim points.

  python3 stem_loop_check.py <song.mp3> <stems.zip> --bpm 96 --bars 16 [--guard-ms 25] [--out <folder>]

Prints, for each mix: length, the stems' offset against the song, the loop seam (level and sample jump at the wrap), and the
calm mix's level under the intense one, and a real 2 s calm-to-intense switch (and back) at four points of the loop.
Cut to the bar grid and apply a short click guard without deleting a beat. With --out write matched calm and intense WAVs.
Needs ffmpeg and numpy. Exit 0 and STEM LOOP CHECK PASS when every check passes."""
import argparse, subprocess, sys, zipfile, tempfile, os
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

def click_guard(x, ms):
    y = x.copy()
    k = round(SR * ms / 1000)
    ramp = (0.5 - 0.5 * np.cos(np.linspace(0, np.pi, k)))[:, None]
    y[:k] *= ramp
    y[-k:] *= ramp[::-1]
    return y


def seam(x, name, fails):
    head, tail = x[:SR // 2], x[-SR // 2:]
    jump = float(np.abs(x[-1] - x[0]).max())
    lh, lt = db(head), db(tail)
    # A loud first downbeat is not a click. The bar grid is checked separately.
    ok = jump <= 0.001
    print(f'  {name}: {len(x) / SR:.3f} s, first 0.5 s {lh:.1f} dB, last 0.5 s {lt:.1f} dB, wrap jump {jump:.3f}', '' if ok else '  FAIL')
    if not ok: fails.append(name + ' seam')

def wrap_level(x, name, fails):
    # A click guard cannot hide an intro build or a large drop at the wrap.
    w = min(5 * SR, len(x) // 2)
    cliff = abs(db(x[-w:]) - db(x[:w]))
    print(f'  {name}: first and last {w / SR:g} s differ by {cliff:.1f} dB', '' if cliff <= 6 else '  FAIL')
    if cliff > 6:
        fails.append(name + ' wrap level')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('song')
    parser.add_argument('stems')
    parser.add_argument('--bpm', required=True, type=float)
    parser.add_argument('--bars', required=True, type=int)
    parser.add_argument('--beats-per-bar', default=4, type=int)
    parser.add_argument('--guard-ms', default=25, type=int, choices=range(20, 31))
    parser.add_argument('--out')
    args = parser.parse_args()
    if min(args.bpm, args.bars, args.beats_per_bar) <= 0:
        parser.error('bar grid values must be positive')
    n_grid = round(SR * 60 * args.bars * args.beats_per_bar / args.bpm)
    fails = []
    mix = load(args.song)
    # M2_test measured -30.5 ms and +50.5 ms despite the correct tempo. This
    # window allows MP3 framing error. The output still uses the exact grid.
    min_ms, max_ms = -50, 120
    if not n_grid + round(SR * min_ms / 1000) <= len(mix) <= n_grid + round(SR * max_ms / 1000):
        print(f'STEM LOOP CHECK FAIL: source has {len(mix)} samples, expected {n_grid} ({min_ms} ms to +{max_ms} ms)')
        return 1
    with tempfile.TemporaryDirectory() as td:
        with zipfile.ZipFile(args.stems) as archive:
            archive.extractall(td)
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
    def on_grid(x):
        if len(x) < n_grid:
            x = np.pad(x, ((0, n_grid - len(x)), (0, 0)))
        return click_guard(x[:n_grid], args.guard_ms)
    calm, intense = on_grid(calm), on_grid(mix)
    print(f'bar grid: {args.bars} bars at {args.bpm:g} BPM, {n_grid} samples, {args.guard_ms} ms click guard')
    gap = db(intense) - db(calm)
    print(f'calm mix is {gap:.1f} dB under the intense mix', '' if 1.0 <= gap <= 12 else '  FAIL')
    if not (1.0 <= gap <= 12): fails.append('calm level')
    seam(intense, 'intense (song)', fails)
    seam(calm, 'calm (no drums)', fails)
    wrap_level(intense, 'intense', fails)
    wrap_level(calm, 'calm', fails)
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
    if args.out and not fails:
        os.makedirs(args.out, exist_ok=True)
        for name, x in (('calm', calm), ('intense', intense)):
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ac', '2', '-ar', str(SR), '-i', '-', os.path.join(args.out, name + '.wav')],
                           input=np.ascontiguousarray(x, dtype=np.float32).tobytes(), check=True)
    print('STEM LOOP CHECK PASS' if not fails else 'STEM LOOP CHECK FAIL: ' + ', '.join(fails))
    return 0 if not fails else 1

if __name__ == '__main__':
    sys.exit(main())
