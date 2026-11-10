# Issue 209 round 7: turn the fire probe's raw frames (godot/fx/test/ship_fire_probe.gd: raw_<label>_<range>/frame_*.rgb plus
# clip.json) into a short clip per camera range. MP4 when imageio-ffmpeg is installed, else an animated GIF (Pillow). Plain
# Python with numpy and Pillow (Blender's own python has both after recipe stage 3).
# usage: python fire_clip.py FIRE_OUT_DIR      writes FIRE_OUT_DIR/clips/<label>_<range>.mp4 or .gif and clips.json
import os, sys, json, glob, subprocess
import numpy as np
from PIL import Image
src = sys.argv[1]; dst = os.path.join(src, 'clips'); os.makedirs(dst, exist_ok=True); out = {}
try:
    import imageio_ffmpeg; FF = imageio_ffmpeg.get_ffmpeg_exe()
except Exception: FF = None
for d in sorted(glob.glob(os.path.join(src, 'raw_*'))):
    mp = os.path.join(d, 'clip.json')
    if not os.path.exists(mp): continue
    m = json.load(open(mp)); w, h, fps = int(m['w']), int(m['h']), int(m['fps']); name = os.path.basename(d)[4:]
    files = sorted(glob.glob(os.path.join(d, 'frame_*.rgb')))
    frames = [np.frombuffer(open(f, 'rb').read(), np.uint8).reshape(h, w, 3) for f in files]
    if not frames: continue
    if FF:
        p = os.path.join(dst, name + '.mp4')
        pr = subprocess.Popen([FF, '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{w}x{h}', '-r', str(fps), '-i', '-', '-an', '-c:v', 'libx264',
                               '-pix_fmt', 'yuv420p', '-crf', '20', p], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for fr in frames: pr.stdin.write(fr.tobytes())
        pr.stdin.close(); pr.wait()
    else:
        p = os.path.join(dst, name + '.gif'); ims = [Image.fromarray(fr) for fr in frames]
        ims[0].save(p, save_all=True, append_images=ims[1:], duration=int(1000 / fps), loop=0)
    out[name] = dict(file=os.path.basename(p), frames=len(frames), bytes=os.path.getsize(p)); print('[clip]', name, out[name], flush=True)
json.dump(out, open(os.path.join(dst, 'clips.json'), 'w'), indent=1)
