# Renders the browser's synth ambient bed (sfx.js ambient()) offline into a seamless 120 s loop for Godot:
# godot/audio/synth/ambient_bed.ogg. Run: python3 godot/audio/build/render_ambient_bed.py  (numpy, scipy, ffmpeg)
#
# The browser graph (all into one gain "lg", 0.13 alone or 0.065 under the recorded room tone):
#   brown noise (rate 0.5) x0.5 -> lowpass 150 Hz Q 0.5, cutoff swept +-60 Hz at 0.023 Hz
#   sines 55 Hz x0.05, 55.21 Hz x0.04, 82.6 Hz x0.016
#   pink noise (rate 0.6) -> bandpass 700 Hz Q 0.8, centre swept +-260 Hz at 0.011 Hz, gain 0.012 +- 0.008 at 0.017 Hz
# For a clean loop every rate is snapped to a whole number of cycles in 120 s (0.025, 0.00833, 0.0167 Hz; 55.2083 Hz),
# the noises are shaped in the frequency domain over exactly 120 s (periodic by construction), and the swept filters run
# twice round the loop with the second pass kept. The file is normalised; sfx.gd plays it at BED_GAIN (printed here).
import subprocess, sys, os
import numpy as np
from scipy.signal import lfilter, lfilter_zi

SR = 32000
T = 120.0
N = int(SR * T)
BLOCK = 256
rng = np.random.default_rng(7)
t = np.arange(N) / SR


def shaped_noise(power_exp):
    # periodic noise with power ~ 1/f^power_exp, peak normalised to 0.95 like sfx.js _makeNoise
    spec = rng.normal(size=N // 2 + 1) + 1j * rng.normal(size=N // 2 + 1)
    f = np.fft.rfftfreq(N, 1 / SR)
    f[0] = f[1]
    spec *= f ** (-power_exp / 2.0)
    spec[0] = 0
    x = np.fft.irfft(spec, n=N)
    return x / (np.abs(x).max() * 1.05)


def biquad(kind, f0, q):
    w = 2 * np.pi * f0 / SR
    a = np.sin(w) / (2 * q)
    c = np.cos(w)
    if kind == "lp":
        b = [(1 - c) / 2, 1 - c, (1 - c) / 2]
    else:  # band-pass, constant 0 dB peak (Web Audio "bandpass")
        b = [a, 0, -a]
    A = [1 + a, -2 * c, 1 - a]
    return np.array(b) / A[0], np.array(A) / A[0]


def swept(x, kind, centre, depth, rate, q):
    # time-varying biquad, coefficients per block, run twice round the loop (the second pass is the seamless one)
    out = np.zeros_like(x)
    zi = None
    for rep in range(2):
        for s in range(0, N, BLOCK):
            fc = centre + depth * np.sin(2 * np.pi * rate * (s / SR))
            b, a = biquad(kind, max(fc, 20.0), q)
            if zi is None:
                zi = lfilter_zi(b, a) * x[s]
            y, zi = lfilter(b, a, x[s:s + BLOCK], zi=zi)
            if rep == 1:
                out[s:s + BLOCK] = y
    return out


brown = shaped_noise(2.0)
pink = shaped_noise(1.0)
rumble = swept(brown * 0.5, "lp", 150.0, 60.0, 3 / T, 0.5)
drones = 0.05 * np.sin(2 * np.pi * 55.0 * t) + 0.04 * np.sin(2 * np.pi * (6625 / T) * t) + 0.016 * np.sin(2 * np.pi * 82.6 * t)
air = swept(pink, "bp", 700.0, 260.0, 1 / T, 0.8) * (0.012 + 0.008 * np.sin(2 * np.pi * (2 / T) * t))
bed = rumble + drones + air
peak = np.abs(bed).max()
norm = 0.9 / peak
bed *= norm
# the gain sfx.gd applies so the bed sits where the browser puts it under the room tone (lg 0.065)
bed_gain = 0.065 / norm
print("peak before normalising %.4f, normalised x%.3f, play at linear gain %.5f" % (peak, norm, bed_gain))

here = os.path.dirname(os.path.abspath(__file__))
out = os.path.normpath(os.path.join(here, "..", "synth", "ambient_bed.ogg"))
# a second of overlap on each side: [last 1 s][the loop][first 1 s]. sfx.gd loops from 121 s back to 1 s (loop_offset 1,
# bpm 60, beat_count 121), so the loop point sits inside the audio and away from the encoder's ragged file edges
padded = np.concatenate([bed[-SR:], bed, bed[:SR]])
pcm = (np.clip(padded, -1, 1) * 32767).astype(np.int16).tobytes()
subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "1", "-i", "-", "-c:a", "libvorbis", "-q:a", "3", out], input=pcm, check=True)
print("wrote", out, os.path.getsize(out), "bytes")
