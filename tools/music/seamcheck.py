# Loop seam check (sandbox): how big is the jump where a loop wraps from its end back to its start?
#   python3 tools/music/seamcheck.py <file.ogg> ...           built tracks (whole file is the loop)
#   python3 tools/music/seamcheck.py --raw <file> <s> <e>     a candidate region of a raw file
# Prints, per file: the spectral change across the wrap divided by the track's typical (median) frame-to-frame change
# ("jump", 1 = as smooth as any moment of the music; under about 2.5 is not noticeable; a drum hit landing on the wrap
# can read high), the loudness step in dB across the wrap, and the sample step at the wrap.
import sys, subprocess, numpy as np

def dec(p, sr=22050, ss=0.0, t=None):
    cmd = ['ffmpeg', '-v', 'error', '-ss', str(ss)] + (['-t', str(t)] if t else []) + ['-i', p, '-ac', '1', '-ar', str(sr), '-f', 'f32le', '-']
    return np.frombuffer(subprocess.run(cmd, capture_output=True).stdout, dtype=np.float32)

def spec(x, n=1024, hop=512):
    fr = np.lib.stride_tricks.sliding_window_view(x, n)[::hop] * np.hanning(n)
    return np.log1p(np.abs(np.fft.rfft(fr, axis=1)) * 10)

def check(x, sr=22050):
    S = spec(x); flux = np.abs(np.diff(S, axis=0)).mean(1); med = float(np.median(flux))
    k = int(1.0 * sr)                                  # 1 s either side of the wrap
    j = np.concatenate([x[-k:], x[:k]]); Sj = spec(j); fj = np.abs(np.diff(Sj, axis=0)).mean(1)
    mid = len(fj) // 2; jump = float(fj[mid - 2:mid + 2].max()) / (med + 1e-9)
    rms = lambda a: 20 * np.log10(np.sqrt((a ** 2).mean()) + 1e-9)
    step = rms(x[:int(0.25 * sr)]) - rms(x[-int(0.25 * sr):])
    return round(jump, 2), round(step, 1), round(float(abs(x[0] - x[-1])), 4)

if __name__ == '__main__':
    a = sys.argv[1:]
    if a and a[0] == '--raw':
        s, e = float(a[2]), float(a[3]); x = dec(a[1], ss=s, t=e - s); print(a[1], s, e, 'jump %.2f  step %.1f dB  sample %.4f' % check(x))
    else:
        for p in a:
            print('%-28s jump %5.2f  step %5.1f dB  sample %.4f' % ((p.split('/')[-1],) + check(dec(p))))
