# Issue 1360 STB job helper (PC job opus1360storm, not in the repo). Never deletes.
#   stills <ffmpeg> <clip.avi> <outdir> <label> [n=3] [tail_s=12]
#       measures every frame of the clip's last tail_s seconds (ffmpeg signalstats, mean luma at 640 wide), scores each frame
#       by how much brighter it is than the frames around it (a strike), keeps the n best at least 0.6 s apart, and saves
#       each full-size as STB_<label>_<k>.jpg with an "STB" footer (label, clip time, score). Writes STB_<label>_frames.txt.
#   sheet <outdir> <label1,label2,...> [n=3]
#       one before/after sheet STB_sheet.jpg: a row per label (its stills at 640x360), labelled STB.
import os, re, subprocess, sys
from PIL import Image, ImageDraw, ImageFont


def font(size):
    for f in ("C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def stills(ffmpeg, avi, outdir, label, n=3, tail=12.0):
    ffmpeg, avi, outdir = os.path.abspath(ffmpeg), os.path.abspath(avi), os.path.abspath(outdir)
    os.makedirs(outdir, exist_ok=True)
    stats = "STB_%s_luma.txt" % label
    # Godot's --write-movie AVI has no usable duration for -sseof, so the whole clip is measured and only its last tail_s
    # seconds are kept (the build and bake frames come first).
    subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-i", avi, "-vf",
                    "scale=640:-2,signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=" + stats, "-f", "null", "-"],
                   cwd=outdir, check=True)
    rows, t, fn = [], None, None
    for line in open(os.path.join(outdir, stats), encoding="utf-8", errors="replace"):
        m = re.search(r"frame:\s*([0-9]+)\s+pts:\s*\S+\s+pts_time:([0-9.]+)", line)
        if m:
            fn, t = int(m.group(1)), float(m.group(2))
        m = re.search(r"YAVG=([0-9.]+)", line)
        if m and t is not None:
            rows.append((t, float(m.group(1)), fn))
    if not rows:
        raise SystemExit("no frames measured in " + avi)
    start = max(0.0, rows[-1][0] - tail)
    rows = [r for r in rows if r[0] >= start]
    subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-ss", "%.3f" % start, "-i", avi, "-vf", "scale=1280:-2",
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "26", "-an", os.path.join(outdir, "STB_%s.mp4" % label)], check=True)
    scored = []
    for i, (t, y, fn) in enumerate(rows):
        near = sorted(r[1] for r in rows[max(0, i - 30):i + 31])
        scored.append((y - near[len(near) // 2], t, y, fn))
    picks = []
    for s, t, y, fn in sorted(scored, reverse=True):
        if all(abs(t - p[1]) >= 0.6 for p in picks):
            picks.append((s, t, y, fn))
        if len(picks) >= n:
            break
    picks.sort(key=lambda p: p[1])
    with open(os.path.join(outdir, "STB_%s_frames.txt" % label), "w", encoding="utf-8") as f:
        f.write("STB %s: %d frames measured in the last %g s (from %.2f s) of %s; mp4 of that span written; picks (clip time s, luma, score over the local median):\n" % (label, len(rows), tail, start, os.path.basename(avi)))
        # one decode pass for every pick (the AVI has no index to seek on): frames by number, written _raw_1.png ...
        sel = "+".join("eq(n\\,%d)" % p[3] for p in picks)
        subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-i", avi, "-vf", "select='%s'" % sel, "-fps_mode", "passthrough",
                        os.path.join(outdir, "_raw_%d.png")], check=True)
        for k, (s, t, y, fn) in enumerate(picks, 1):
            name = "STB_%s_%d.jpg" % (label, k)
            raw = os.path.join(outdir, "_raw_%d.png" % k)
            im = Image.open(raw).convert("RGB")
            w, h = im.size
            bar = 44
            canvas = Image.new("RGB", (w, h + bar), (12, 12, 16))
            canvas.paste(im, (0, 0))
            ImageDraw.Draw(canvas).text((14, h + 8), "STB  %s  still %d  clip t %.2f s  luma %.1f (+%.1f)" % (label, k, t, y, s), fill=(235, 235, 235), font=font(24))
            canvas.save(os.path.join(outdir, name), quality=90)
            im.close()
            os.replace(raw, os.path.join(outdir, "_raw_%d_kept.png" % k))
            f.write("  %s  t %.3f  luma %.2f  score %.2f\n" % (name, t, y, s))
    print("STB %s: %d stills" % (label, len(picks)))


def sheet(outdir, labels, n=3):
    tw, th, lw, top = 640, 360, 220, 56
    labels = [l for l in labels.split(",") if l]
    out = Image.new("RGB", (lw + tw * n, top + th * len(labels)), (12, 12, 16))
    d = ImageDraw.Draw(out)
    d.text((14, 12), "STB  issue 1360 storm lightning: before (ribbon) / after (baked) / after with Reduced Flashing; brightest strike frames", fill=(240, 240, 240), font=font(26))
    for r, label in enumerate(labels):
        y = top + r * th
        d.text((14, y + th // 2 - 14), "STB " + label, fill=(235, 235, 235), font=font(24))
        for k in range(1, n + 1):
            p = os.path.join(outdir, label, "STB_%s_%d.jpg" % (label, k))
            if os.path.exists(p):
                im = Image.open(p).convert("RGB")
                im = im.crop((0, 0, im.size[0], im.size[1] - 44)).resize((tw, th), Image.LANCZOS)
                out.paste(im, (lw + (k - 1) * tw, y))
            else:
                d.text((lw + (k - 1) * tw + 20, y + th // 2), "missing", fill=(200, 80, 80), font=font(24))
    out.save(os.path.join(outdir, "STB_sheet.jpg"), quality=88)
    print("STB sheet: %d rows" % len(labels))


if __name__ == "__main__":
    a = sys.argv[1:]
    if a and a[0] == "stills":
        stills(a[1], a[2], a[3], a[4], int(a[5]) if len(a) > 5 else 3, float(a[6]) if len(a) > 6 else 12.0)
    elif a and a[0] == "sheet":
        sheet(a[1], a[2], int(a[3]) if len(a) > 3 else 3)
    else:
        raise SystemExit(__doc__ if __doc__ else "usage: stills|sheet ...")
