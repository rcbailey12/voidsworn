# Issue 1982 R4STALL job helper (PC job r4stall, not in the repo). Never deletes.
#   r4stall_report.py <job out dir> [records=r4_x09,r4_x05]
# Reads out_old\ft_*\r4stall_frames.json (before: main at efabe897's first parent) and out_new\ft_*\ (after: efabe897),
# writes R4STALL_table.md (per record, side and run: frames, worst ms, p99 ms, the stall frame and its ms, frames over
# 33 ms) and one R4STALL_<record>.png frame-time graph per record (every run of both sides, 33 ms line, R4STALL footer).
import glob, json, os, sys
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.abspath(sys.argv[1])
RECS = (sys.argv[2] if len(sys.argv) > 2 else "r4_x09,r4_x05").split(",")
SIDES = [("old", "before (main 84a2557c, parent of efabe897)"), ("new", "after (main efabe897, PR 2004)")]


def font(size):
    for f in ("C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def runs(side):
    got = []
    for p in sorted(glob.glob(os.path.join(OUT, "out_" + side, "ft_*", "r4stall_frames.json"))):
        try:
            got.append((os.path.basename(os.path.dirname(p)), json.load(open(p, encoding="utf-8"))))
        except Exception as e:
            print("unreadable %s: %s" % (p, e))
    return got


def stats(ms):
    s = sorted(ms)
    n = len(s)
    worst = s[-1] if n else 0.0
    p99 = s[min(n - 1, int(n * 0.99))] if n else 0.0
    k = max(range(n), key=lambda i: ms[i]) if n else -1
    return n, worst, p99, k, sum(1 for x in ms if x > 33.0)


data = {side: runs(side) for side, _ in SIDES}
lines = ["# R4STALL: round 4 Hullbreaker stall, before and after PR 2004", "",
         "Layout: battle.tscn --torp-ft --fac corsair --obj ambush --map open --seed 7 --movement brisk (the 1558A frame-time run), "
         "1920x1080, solo GPU. Every frame of each record, in ms, from battle.gd's own --torp-ft frame list.", "",
         "| record | side | run | frames | worst ms | p99 ms | stall frame (index: ms) | frames over 33 ms |",
         "|---|---|---|---|---|---|---|---|"]
for rec in RECS:
    for side, name in SIDES:
        if not data[side]:
            lines.append("| %s | %s | - | no runs found | | | | |" % (rec, name))
        for run, recs in data[side]:
            ms = [float(x) for x in recs.get(rec, [])]
            if not ms:
                lines.append("| %s | %s | %s | record not fired | | | | |" % (rec, name, run))
                continue
            n, worst, p99, k, over = stats(ms)
            lines.append("| %s | %s | %s | %d | %.1f | %.1f | %d: %.1f | %d |" % (rec, name, run, n, worst, p99, k, ms[k], over))
open(os.path.join(OUT, "R4STALL_table.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("\n".join(lines))

W, H, L, R, T, B = 1600, 760, 90, 30, 70, 120
cols = {"old": [(120, 160, 230), (80, 120, 200), (160, 190, 245)], "new": [(240, 150, 60), (220, 110, 40), (250, 190, 110)]}
for rec in RECS:
    series = []
    for side, name in SIDES:
        for i, (run, recs) in enumerate(data[side]):
            ms = [float(x) for x in recs.get(rec, [])]
            if ms:
                series.append((side, name, run, ms, cols[side][i % 3]))
    im = Image.new("RGB", (W, H), (14, 14, 18))
    d = ImageDraw.Draw(im)
    d.text((L, 18), "R4STALL  %s frame times, before vs after PR 2004 (seed 7 Hullbreakers, round 4)" % rec, fill=(240, 240, 240), font=font(26))
    if series:
        top = max(40.0, max(max(s[3]) for s in series) * 1.08)
        nmax = max(len(s[3]) for s in series)
        y = lambda v: T + (H - T - B) * (1.0 - v / top)
        x = lambda i: L + (W - L - R) * (i / max(1, nmax - 1))
        for v in (0, 16.7, 33.3, 50, 100, 150, 200):
            if v <= top:
                d.line([(L, y(v)), (W - R, y(v))], fill=(60, 60, 70) if v not in (16.7, 33.3) else (120, 60, 60), width=1)
                d.text((10, y(v) - 10), "%g ms" % v, fill=(200, 200, 200), font=font(16))
        for side, name, run, ms, c in series:
            d.line([(x(i), y(v)) for i, v in enumerate(ms)], fill=c, width=2)
        ly = H - B + 34
        for k, (side, name, run, ms, c) in enumerate(series):
            n, worst, p99, idx, over = stats(ms)
            d.rectangle([L + (k % 2) * 760, ly + (k // 2) * 22, L + (k % 2) * 760 + 18, ly + (k // 2) * 22 + 12], fill=c)
            d.text((L + (k % 2) * 760 + 26, ly + (k // 2) * 22 - 5), "%s %s: worst %.1f, p99 %.1f, over 33 ms %d" % (name.split(" (")[0], run, worst, p99, over), fill=(225, 225, 225), font=font(16))
        d.text((L, H - B + 8), "frame index within the record (x), frame time ms (y); red lines 16.7 and 33.3 ms", fill=(170, 170, 170), font=font(16))
    else:
        d.text((L, H // 2), "no frames recorded for %s" % rec, fill=(220, 90, 90), font=font(26))
    d.text((L, H - 24), "R4STALL  issue 1982 / PR 2004  before 84a2557c  after efabe897", fill=(150, 150, 150), font=font(16))
    im.save(os.path.join(OUT, "R4STALL_%s.png" % rec))
print("R4STALL report done")
