# Issue 209 round 7: turn the fire probe's frames (godot/fx/test/ship_fire_probe.gd: raw_<label>_<range>/frame_*.jpg, or
# frame_*.png, or the old raw frame_*.rgb, plus clip.json) into a short clip per camera range, and its stills into one
# contact strip. Runs in the cloud sandbox after the frames are staged from the PC (round 7 step 5 repair: Blender's own
# Python on the PC has no Pillow, so nothing here runs on the PC). Needs Pillow and numpy; MP4 when ffmpeg is on the PATH
# (or imageio-ffmpeg is installed), else an animated GIF.
# usage: python fire_clip.py FIRE_DIR [OUT_DIR]
#   writes OUT_DIR/<label>_<range>.mp4 (or .gif), OUT_DIR/clips.json and OUT_DIR/fire_strip.jpg (OUT_DIR defaults to FIRE_DIR/clips)
import os, sys, json, glob, shutil, subprocess
import numpy as np
from PIL import Image, ImageDraw

src = sys.argv[1]
dst = sys.argv[2] if len(sys.argv) > 2 else os.path.join(src, 'clips')
os.makedirs(dst, exist_ok=True)
FF = shutil.which('ffmpeg')
if not FF:
    try:
        import imageio_ffmpeg
        FF = imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        FF = None


def frames_of(d, w, h):
    files = sorted(glob.glob(os.path.join(d, 'frame_*.jpg')) + glob.glob(os.path.join(d, 'frame_*.png')))
    if files:
        return [np.asarray(Image.open(f).convert('RGB')) for f in files]
    return [np.frombuffer(open(f, 'rb').read(), np.uint8).reshape(h, w, 3) for f in sorted(glob.glob(os.path.join(d, 'frame_*.rgb')))]


out = {}
for d in sorted(glob.glob(os.path.join(src, 'raw_*'))):
    mp = os.path.join(d, 'clip.json')
    if not os.path.exists(mp):
        continue
    m = json.load(open(mp))
    w, h, fps = int(m['w']), int(m['h']), int(m['fps'])
    name = os.path.basename(d)[4:]
    frames = frames_of(d, w, h)
    if not frames:
        continue
    if FF:
        p = os.path.join(dst, name + '.mp4')
        pr = subprocess.Popen([FF, '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{w}x{h}', '-r', str(fps), '-i', '-', '-an',
                               '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '23', '-vf', 'scale=trunc(min(iw\\,1280)/2)*2:-2', p],
                              stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for fr in frames:
            pr.stdin.write(np.ascontiguousarray(fr).tobytes())
        pr.stdin.close()
        pr.wait()
    else:
        p = os.path.join(dst, name + '.gif')
        ims = [Image.fromarray(fr).resize((w // 2, h // 2)) for fr in frames]
        ims[0].save(p, save_all=True, append_images=ims[1:], duration=int(1000 / fps), loop=0)
    out[name] = dict(file=os.path.basename(p), frames=len(frames), fps=fps, bytes=os.path.getsize(p))
    print('[clip]', name, out[name], flush=True)
json.dump(out, open(os.path.join(dst, 'clips.json'), 'w'), indent=1)

# contact strip: one row per camera range, the stills in firing order (flash, smoke, hit), each with its crop beside it
st = os.path.join(src, 'stills')
rows = []
for rng in ('game', 'battle', 'close'):
    cells = []
    for n in (0, 1):
        for k in ('flash', 'smoke', 'hit'):
            f = glob.glob(os.path.join(st, f'*_{rng}_fire{n}_{k}.png'))
            if f:
                cells.append((f'{rng} broadside {n + 1} {k}', f[0]))
    if cells:
        rows.append(cells)
if rows:
    CW, CH = 640, 360
    ncol = max(len(r) for r in rows)
    sheet = Image.new('RGB', (CW * ncol, (CH + 22) * len(rows)), (12, 12, 16))
    dr = ImageDraw.Draw(sheet)
    for i, r in enumerate(rows):
        for j, (lab, f) in enumerate(r):
            im = Image.open(f).convert('RGB').resize((CW, CH), Image.LANCZOS)
            sheet.paste(im, (j * CW, i * (CH + 22) + 22))
            dr.text((j * CW + 6, i * (CH + 22) + 5), lab, fill=(230, 230, 230))
    sheet.save(os.path.join(dst, 'fire_strip.jpg'), quality=88)
    print('[clip] strip', os.path.join(dst, 'fire_strip.jpg'), sheet.size)
