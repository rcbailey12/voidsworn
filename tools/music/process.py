# Music pipeline (sandbox, ffmpeg with libvorbis):
#   python3 tools/music/process.py prep <raw_dir>            rejoin .partNN splits, unzip packs into <raw_dir>/<zip name>/
#   python3 tools/music/process.py analyse <raw_dir> <out>   per file: length, loudness, brightness, low end, onset rate, tempo,
#                                                            plus a spectrogram strip per file (for picking without ears)
#   python3 tools/music/process.py build <raw_dir>           selection.json -> godot/music/tracks/*.ogg, music.json, CREDITS.md
# Loops that are not seamless get a crossfaded seam (the tail is blended into the head) so they loop without a click or gap.
import os, sys, json, glob, subprocess, zipfile, re, math
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.dirname(os.path.dirname(HERE))
GM = os.path.join(REPO, 'godot', 'music'); TR = os.path.join(GM, 'tracks')
AUD = ('.ogg', '.mp3', '.wav', '.flac')

def sh(cmd, **k): return subprocess.run(cmd, capture_output=True, text=True, **k)

def prep(raw):
    for p0 in sorted(glob.glob(os.path.join(raw, '*.part00'))):
        base = p0[:-7]; parts = sorted(glob.glob(base + '.part*'))
        if not os.path.exists(base) or os.path.getsize(base) != sum(os.path.getsize(p) for p in parts):
            with open(base, 'wb') as o:
                for p in parts: o.write(open(p, 'rb').read())
            print('joined', os.path.basename(base), len(parts), 'parts')
    for z in glob.glob(os.path.join(raw, '*.zip')):
        d = z[:-4]
        if not os.path.isdir(d):
            with zipfile.ZipFile(z) as zf:
                for m in zf.infolist():
                    n = os.path.normpath(m.filename)
                    if n.startswith('..') or os.path.isabs(n): continue
                    if n.lower().endswith(AUD): zf.extract(m, d)
            print('unzipped', os.path.basename(z))

def files(raw):
    out = []
    for r, _, fs in os.walk(raw):
        for f in fs:
            if f.lower().endswith(AUD) and '__MACOSX' not in r: out.append(os.path.join(r, f))
    return sorted(out)

def decode(p, sr=11025, start=0.0, dur=None):
    cmd = ['ffmpeg', '-v', 'error', '-ss', str(start)] + (['-t', str(dur)] if dur else []) + ['-i', p, '-ac', '1', '-ar', str(sr), '-f', 'f32le', '-']
    return np.frombuffer(subprocess.run(cmd, capture_output=True).stdout, dtype=np.float32)

def loudness(p, extra=()):
    r = sh(['ffmpeg', '-hide_banner', '-nostats', '-i', p] + list(extra) + ['-af', 'ebur128=peak=true', '-f', 'null', '-'])
    I = re.findall(r'I:\s+(-?[\d.]+) LUFS', r.stderr); LRA = re.findall(r'LRA:\s+([\d.]+) LU', r.stderr); pk = re.findall(r'Peak:\s+(-?[\d.inf]+) dBFS', r.stderr)
    return (float(I[-1]) if I else None, float(LRA[-1]) if LRA else None, pk[-1] if pk else None)

def feats(x, sr=11025):
    n = 1024; hop = 512
    if len(x) < n * 4: return {}
    frames = np.lib.stride_tricks.sliding_window_view(x, n)[::hop] * np.hanning(n)
    S = np.abs(np.fft.rfft(frames, axis=1)); fr = np.fft.rfftfreq(n, 1 / sr)
    e = S.sum(1) + 1e-9; cent = (S * fr).sum(1) / e
    low = S[:, fr < 180].sum(1) / e
    flux = np.maximum(np.diff(np.log1p(S), axis=0), 0).sum(1)
    fl = (flux - flux.mean()) / (flux.std() + 1e-9)
    thr = 1.5; peaks = np.sum((fl[1:-1] > thr) & (fl[1:-1] > fl[:-2]) & (fl[1:-1] >= fl[2:]))
    fps = sr / hop; onset_rate = peaks / (len(fl) / fps)
    ac = np.correlate(fl, fl, 'full')[len(fl) - 1:]; lo, hi = int(fps * 60 / 180), int(fps * 60 / 60)
    lag = lo + int(np.argmax(ac[lo:hi])) if hi < len(ac) else None
    rms = np.sqrt((frames ** 2).mean(1)); rd = 20 * np.log10(np.percentile(rms, 95) / (np.percentile(rms, 10) + 1e-9) + 1e-9)
    beat = float(ac[lag] / ac[0]) if lag else 0
    # percussive share: median-filter split of the spectrogram (time-smooth = harmonic, frequency-smooth = percussive)
    from scipy.ndimage import median_filter
    P2 = S[:min(len(S), 6000)] ** 2; H = median_filter(P2, size=(17, 1)); Pc = median_filter(P2, size=(1, 17))
    perc = float((Pc ** 2 / (H ** 2 + Pc ** 2 + 1e-12) * P2).sum() / (P2.sum() + 1e-12))
    return {'centroid_hz': round(float(np.median(cent))), 'low_share': round(float(np.median(low)), 3), 'onsets_per_s': round(float(onset_rate), 2),
            'tempo_bpm': round(60 * fps / lag) if lag else None, 'beat_strength': round(beat, 2), 'dyn_db': round(float(rd), 1),
            'perc_share': round(perc, 3)}

def spectro(p, out, dur):
    sh(['ffmpeg', '-v', 'error', '-y', '-i', p, '-lavfi', 'showspectrumpic=s=900x160:legend=0:scale=log:fscale=log:color=intensity', out])

def analyse(raw, out):
    os.makedirs(out, exist_ok=True); rows = []
    for p in files(raw):
        d = sh(['ffprobe', '-v', 'error', '-show_entries', 'format=duration:stream=sample_rate,channels', '-of', 'json', p])
        try: j = json.loads(d.stdout); dur = float(j['format']['duration'])
        except Exception: print('skip', p); continue
        I, LRA, pk = loudness(p)
        x = decode(p, dur=min(dur, 240)); F = feats(x)
        name = os.path.relpath(p, raw); png = os.path.join(out, re.sub(r'[^\w.-]', '_', name) + '.png'); spectro(p, png, dur)
        r = {'file': name, 'sec': round(dur, 1), 'lufs': I, 'lra': LRA, 'peak': pk, **F}; rows.append(r); print(json.dumps(r))
    json.dump(rows, open(os.path.join(out, 'analysis.json'), 'w'), indent=1)

# ---------- loop seam search ----------
def _logspec(x, sr, n=2048, hop=256):
    fr = np.lib.stride_tricks.sliding_window_view(x, n)[::hop] * np.hanning(n)
    S = np.log1p(np.abs(np.fft.rfft(fr, axis=1))[:, 2:400] * 10)
    return S - S.mean(1, keepdims=True), sr / hop

def loopfind(src, start, lo, hi, win=3.0, sr=11025):
    """best loop point E in [lo, hi]: the 'win' seconds after E sound most like the 'win' seconds after start.
    Returns (E, score, runner-ups). The build cuts [start, E + xfade) and blends the tail into the head."""
    x = decode(src, sr); S, fps = _logspec(x, sr); w = int(win * fps); s0 = int(start * fps)
    ref = S[s0:s0 + w].ravel(); ref = ref / (np.linalg.norm(ref) + 1e-9); sc = []
    for e in range(int(lo * fps), min(int(hi * fps), len(S) - w)):
        c = S[e:e + w].ravel(); sc.append((float(ref @ c / (np.linalg.norm(c) + 1e-9)), e / fps))
    sc.sort(reverse=True)
    best = sc[0]; e = best[1]
    # fine-align on the waveform (phase) within +-30 ms
    a = x[int(start * sr):int(start * sr) + int(0.5 * sr)]; k = int(0.03 * sr); i0 = int(e * sr)
    seg = x[i0 - k:i0 + k + len(a)]
    if len(seg) == len(a) + 2 * k:
        cc = np.correlate(seg, a, 'valid'); e = (i0 - k + int(np.argmax(cc))) / sr
    picks = [];
    for s, t in sc:
        if all(abs(t - p) > 1.0 for _, p in picks): picks.append((round(s, 3), round(t, 2)))
        if len(picks) == 4: break
    return round(e, 3), round(best[0], 3), picks

# ---------- build ----------
def seam_loop(src, dst, start, end, xf, lufs, sr=44100):
    """cut [start, end), blend the last xf seconds into the first xf seconds (equal power), loudness-normalise, encode Vorbis"""
    a = ['ffmpeg', '-v', 'error', '-ss', str(start)] + (['-t', str(end - start)] if end else []) + ['-i', src, '-ac', '2', '-ar', str(sr), '-f', 'f32le', '-']
    x = np.frombuffer(subprocess.run(a, capture_output=True).stdout, dtype=np.float32).reshape(-1, 2).copy()
    if xf > 0:
        n = int(xf * sr); t = np.linspace(0, 1, n)[:, None]
        head, tail = x[:n].copy(), x[-n:].copy()
        x[:n] = tail * np.cos(t * math.pi / 2) + head * np.sin(t * math.pi / 2); x = x[:-n]
    return encode(x, dst, lufs, sr)

def cut(src, dst, start, end, lufs, fade_out=0.0, sr=44100):
    a = ['ffmpeg', '-v', 'error', '-ss', str(start)] + (['-t', str(end - start)] if end else []) + ['-i', src, '-ac', '2', '-ar', str(sr), '-f', 'f32le', '-']
    x = np.frombuffer(subprocess.run(a, capture_output=True).stdout, dtype=np.float32).reshape(-1, 2).copy()
    if fade_out > 0:
        n = min(len(x), int(fade_out * sr)); x[-n:] *= np.linspace(1, 0, n)[:, None]
    n = min(len(x), int(0.01 * sr)); x[:n] *= np.linspace(0, 1, n)[:, None]
    return encode(x, dst, lufs, sr)

def encode(x, dst, lufs, sr):
    tmp = dst + '.f32'; x.astype(np.float32).tofile(tmp)
    # measure loudness of the raw float buffer, then apply one static gain (keeps the loop seam intact, unlike dynamic loudnorm)
    r = sh(['ffmpeg', '-hide_banner', '-nostats', '-f', 'f32le', '-ar', str(sr), '-ac', '2', '-i', tmp, '-af', 'ebur128=peak=true', '-f', 'null', '-'])
    I = float(re.findall(r'I:\s+(-?[\d.]+) LUFS', r.stderr)[-1]); pk = float(re.findall(r'Peak:\s+(-?[\d.]+) dBFS', r.stderr)[-1])
    g = lufs - I; g = min(g, -1.0 - pk)        # never push the true peak over -1 dBFS
    sh(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(sr), '-ac', '2', '-i', tmp, '-af', 'volume=%.2fdB' % g, '-c:a', 'libvorbis', '-q:a', '4', dst])
    os.remove(tmp); return {'measured_lufs': round(I, 1), 'gain_applied_db': round(g, 1), 'sec': round(len(x) / sr, 1), 'bytes': os.path.getsize(dst)}

def build(raw):
    S = json.load(open(os.path.join(HERE, 'selection.json'))); os.makedirs(TR, exist_ok=True)
    tracks = {}; total = 0; credits = []
    for tid, t in S['tracks'].items():
        src = os.path.join(raw, t['src']); dst = os.path.join(TR, tid + '.ogg')
        if t.get('loop', True) and t.get('search'):
            e, score, alts = loopfind(src, t.get('start', 0), *t['search'])
            t['end'] = round(e + t.get('xfade', 2.0), 3); t['seam_score'] = score
            print(tid, 'loop point', e, 'score', score, 'others', alts)
        if t.get('loop', True): info = seam_loop(src, dst, t.get('start', 0), t.get('end'), t.get('xfade', 2.0), t.get('lufs', -18))
        else: info = cut(src, dst, t.get('start', 0), t.get('end'), t.get('lufs', -16), t.get('fade_out', 0))
        total += info['bytes']; print(tid, info)
        tracks[tid] = {'file': tid + '.ogg', 'gain_db': t.get('gain_db', 0.0), 'loop_from': 0.0, 'role': t['role'], 'credit': t['credit'],
                       'cut': [t.get('start', 0), t.get('end')], 'sec': info['sec']}
        if t.get('loop', True): tracks[tid]['seam'] = t['seam_score'] if 'seam_score' in t else 'author loop (whole file, 20 ms click guard)'
        credits.append((tid, t))
    man = {'note': 'Generated by tools/music/process.py build from tools/music/selection.json. Edit the selection, not this file.',
           'tracks': tracks, **{k: S[k] for k in ('title', 'map', 'battle', 'stings', 'factions')}}
    json.dump(man, open(os.path.join(GM, 'music.json'), 'w'), indent=1)
    write_credits(S, credits)
    print('total %.1f MB' % (total / 1048576))

def write_credits(S, credits):
    L = ['# Voidsworn music credits', '',
         'Every track below is free to use in a commercial game under the licence named (CC0 needs no credit; CC BY needs the credit line, which the game\'s credits screen shows).',
         'All tracks come from OpenGameArt.org. Files in godot/music/tracks/ are edits (cut, loop seam crossfaded, loudness levelled, re-encoded to Ogg Vorbis): the CC BY credit lines say so.', '',
         '| Track in game | Used for | Title | Author | Licence | Source |', '|---|---|---|---|---|---|']
    for tid, t in credits:
        c = t['credit']
        L.append('| %s | %s | %s | %s | [%s](%s) | %s |' % (tid + '.ogg', t['role'], c['title'], c['author'], c['licence'], c['licence_url'], c['url']))
    L += ['', '## Credit lines for the in-game credits screen', '']
    for tid, t in credits:
        c = t['credit']
        edit = 'Edited for looping and level.' if t.get('loop', True) else 'Trimmed and levelled.'
        note = c.get('courtesy') or c.get('notice')
        if c['licence'].startswith('CC0'): L.append('- "%s" by %s, %s (CC0; credit not required, given anyway).%s' % (c['title'], c['author'], c['url'], (' Note: ' + note) if note else ''))
        else: L.append('- "%s" by %s, %s, licensed %s (%s). %s%s' % (c['title'], c['author'], c['url'], c['licence'], c['licence_url'], edit, (' Note: ' + note) if note else ''))
    L += ['', 'Licence check rules used (R40): CC0 first; CC BY accepted with credits; no NC, ND or SA licences; no source without a clear licence on its page.',
          'Each source page was read on Oct 26 2026 (licence, author, file names, attribution notes) and matched the table above. The Fanfares page lists four licences; the stings use its CC-BY 4.0 option.', '']
    open(os.path.join(GM, 'CREDITS.md'), 'w').write('\n'.join(L))

if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == 'prep': prep(a[1])
    elif a[0] == 'analyse': analyse(a[1], a[2])
    elif a[0] == 'build': build(a[1])
    elif a[0] == 'loopfind': print(loopfind(a[1], float(a[2]), float(a[3]), float(a[4])))
