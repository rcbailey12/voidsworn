"""Issue 1079: build the wake on/off comparison clip and a still sheet from the capture frames (cloud side; Ryan never
runs this). Frames come from godot/world/nebula_wake_capture.gd. No colour changes: frames are only scaled and labelled.

  python3 compose.py CLIP_DIR OUT_DIR LABEL      e.g. compose.py out/clip docs/shots/nebula_wake_1118 r1
Writes, per camera radius found (max_c170_off + max_c170_on ...):
  wake_<label>_c<radius>.mp4   off on the left, on on the right, 30 fps, 1280 wide (two 640x360 halves), H.264
  wake_<label>_c<radius>_sheet.jpg   frames at 3 moments (frigate passing, capital passing, 2 s after), off over on
and checks each mp4 with ffprobe (frame count, duration) and prints the result.
"""
import json
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFont

clip, out, label = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(out, exist_ok=True)
try:
    FONT = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
except OSError:
    FONT = ImageFont.load_default()


def tag(im, text):
    d = ImageDraw.Draw(im)
    w = d.textlength(text, font=FONT)
    d.rectangle([0, 0, w + 12, 22], fill=(10, 10, 16))
    d.text((6, 3), text, fill=(235, 225, 200), font=FONT)
    return im


radii = sorted({n.split("_")[1] for n in os.listdir(clip) if n.startswith("max_c") and os.path.isdir(os.path.join(clip, n))})
for rad in radii:
    off_dir, on_dir = os.path.join(clip, f"max_{rad}_off"), os.path.join(clip, f"max_{rad}_on")
    meta = json.load(open(os.path.join(clip, f"max_{rad}_on_meta.json")))
    frames = sorted(f for f in os.listdir(off_dir) if f.endswith(".jpg"))
    on_frames = sorted(f for f in os.listdir(on_dir) if f.endswith(".jpg"))
    want = [f"f{k:04d}.jpg" for k in range(int(meta["frames"]))]
    # Artoo on PR 1181: both sides must hold every frame the capture declared, in order, with nothing missing.
    if frames != want or on_frames != want:
        sys.exit(f"{rad}: frames do not match the capture's {meta['frames']} (off {len(frames)}, on {len(on_frames)})")
    stage = "DRAFT (placeholder hulls)" if meta.get("draft") else "prototype, off by default"
    with tempfile.TemporaryDirectory() as tmp:
        for i, f in enumerate(frames):
            a = Image.open(os.path.join(off_dir, f)).convert("RGB").resize((640, 360), Image.LANCZOS)
            b = Image.open(os.path.join(on_dir, f)).convert("RGB").resize((640, 360), Image.LANCZOS)
            tag(a, f"WAKE {label} {rad} OFF | {stage}")
            tag(b, f"WAKE {label} {rad} ON | {stage}")
            s = Image.new("RGB", (1280, 360))
            s.paste(a, (0, 0))
            s.paste(b, (640, 0))
            s.save(os.path.join(tmp, f"s{i:04d}.png"))
        mp4 = os.path.join(out, f"wake_{label}_{rad}.mp4")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "30", "-i", os.path.join(tmp, "s%04d.png"),
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", mp4], check=True)
    probe = subprocess.run(["ffprobe", "-v", "error", "-count_frames", "-select_streams", "v:0", "-show_entries",
                            "stream=nb_read_frames,width,height,duration", "-of", "json", mp4], capture_output=True, text=True, check=True)
    got = json.loads(probe.stdout)["streams"][0]
    if int(got["nb_read_frames"]) != len(want):
        sys.exit(f"{mp4}: encoded {got['nb_read_frames']} frames, the capture declared {len(want)}")
    print(mp4, got, "frames in:", len(frames))
    # the still sheet: the frigate mid-line (f0090), the capital mid-line (f0165), 2 s after the capital stops (f0285)
    picks = [k for k in ("f0090.jpg", "f0165.jpg", "f0285.jpg") if k in frames]
    sheet = Image.new("RGB", (len(picks) * 426, 2 * 240 + 0))
    for j, k in enumerate(picks):
        for row, d in enumerate((off_dir, on_dir)):
            im = Image.open(os.path.join(d, k)).convert("RGB").resize((426, 240), Image.LANCZOS)
            tag(im, f"{rad} {'OFF' if row == 0 else 'ON'} {k[:5]} {label}")
            sheet.paste(im, (j * 426, row * 240))
    sheet.save(os.path.join(out, f"wake_{label}_{rad}_sheet.jpg"), quality=92)
