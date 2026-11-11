"""Issue 353: the explosion routes bench sheet. Today, route A and route B side by side (one column each, each route in
its two fire amounts) for the torpedo hit and the cruiser death, from look bench runs (godot/bench/look_bench.tscn
--only ...).

python explosion_routes_sheet.py --runs today=DIR a_flash=DIR ... --out SHEET.jpg [--cells id=2,4,8 ...] [--key id=4 ...]
                                 [--heads name=TEXT ...] [--notes FILE] [--strips DIR] [--quality 86]

Columns: the runs, in the order given. Rows, per moment: three moments in time at camera 170 first (the battle camera,
true pixel size, a 1 to 1 crop), then one cell at camera 60 and at camera 26 (--key picks it; the moment's own key cell
otherwise). The time of each row is printed at its left: seconds after the hit where the bench recorded one, seconds
from the moment's start otherwise. --heads adds a second line under a column's name (the bake time, say). --notes FILE
prints its lines under the sheet. --strips DIR also writes every camera 170 cell of every run, one run per row (one
picture per moment), to pick the cells. Needs Pillow (ComfyUI's portable Python on the PC).
"""
import argparse, json, os
from PIL import Image, ImageDraw, ImageFont

BG = (14, 15, 19); FG = (232, 234, 238); DIM = (150, 155, 162); LINE = (60, 64, 72)
LABELS = {
    "today": "Today: 64 cells, smoke only",
    "a_flash": "Route A, flash only",
    "a_core": "Route A, flash + hot core",
    "b_flash": "Route B, flash only",
    "b_core": "Route B, flash + hot core",
}
MOMENTS = [("w_torp_void_hull", "Torpedo hit: Sunward torpedo on an Eclipse cruiser"),
           ("d_cruiser", "Cruiser death: Sunward cruiser (big)")]
CAMS = {170: "Battle camera (170)", 60: "Camera 60", 26: "Camera 26 (closest)"}


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def stills(run):
    with open(os.path.join(run, "bench.json"), encoding="utf-8") as f:
        rep = json.load(f)
    with open(os.path.join(run, "moments.json"), encoding="utf-8") as f:
        rows = {r["id"]: r for r in json.load(f)["rows"]}
    out = {}
    for st in rep.get("stills", []):
        if st.get("part") == "moments":
            out[(st["id"], int(st["cam"]))] = (os.path.join(run, st["file"]), st.get("cells", []), st.get("impacts", []))
    return out, rows


def cell(path, i, size=(384, 216)):
    im = Image.open(path).convert("RGB")
    i = max(0, min(i, im.width // size[0] - 1))
    return im.crop((i * size[0], 0, (i + 1) * size[0], size[1]))


def when(still, i):
    cells, impacts = still[1], still[2]
    if i >= len(cells):
        return ""
    t = float(cells[i].get("t", 0.0))
    if impacts:
        return "%.2f s after the hit" % (t - float(impacts[0]))
    return "%.2f s in" % t


def pairs(items):
    return dict(x.split("=", 1) for x in items)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", nargs="+", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--cells", nargs="*", default=[])
    ap.add_argument("--key", nargs="*", default=[])
    ap.add_argument("--heads", nargs="*", default=[])
    ap.add_argument("--notes")
    ap.add_argument("--strips")
    ap.add_argument("--quality", type=int, default=86)
    a = ap.parse_args()
    runs = [r.split("=", 1) for r in a.runs]
    picks = {"w_torp_void_hull": [2, 4, 8], "d_cruiser": [7, 8, 9]}
    for k, v in pairs(a.cells).items():
        picks[k] = [int(x) for x in v.split(",")]
    keys = {k: int(v) for k, v in pairs(a.key).items()}
    heads = pairs(a.heads)
    data = {name: stills(d) for name, d in runs}
    F, FB, FS = font(17), font(24), font(14)
    LW, CW, CH, GAP, HEAD = 200, 384, 216, 4, 52
    W = LW + len(runs) * (CW + GAP)
    notes = open(a.notes, encoding="utf-8").read().splitlines() if a.notes else []
    H = 56 + len(MOMENTS) * (44 + HEAD + 5 * (CH + GAP)) + 24 * len(notes) + 24
    sheet = Image.new("RGB", (W, H), BG)
    dr = ImageDraw.Draw(sheet)
    dr.text((10, 14), "Explosion routes (issue 353): today, route A and route B side by side. Pick a route and a fire amount.",
            font=FB, fill=FG)
    y = 56
    first = data[runs[0][0]]
    for mid, title in MOMENTS:
        dr.text((10, y + 8), title, font=FB, fill=FG)
        y += 44
        for k, (name, _) in enumerate(runs):
            x = LW + k * (CW + GAP)
            dr.text((x + 4, y + 4), LABELS.get(name, name), font=F, fill=FG)
            if name in heads:
                dr.text((x + 4, y + 28), heads[name], font=FS, fill=DIM)
        y += HEAD
        key = keys.get(mid, int(first[1].get(mid, {}).get("key", 4)))
        rows = [(170, i) for i in picks[mid]] + [(60, key), (26, key)]
        for n, (cam, i) in enumerate(rows):
            if n == len(picks[mid]):   # a rule between the battle camera and the close-ups
                dr.line((0, y - GAP // 2, W, y - GAP // 2), fill=LINE, width=1)
            dr.text((10, y + 8), CAMS[cam], font=F, fill=FG)
            if cam == 170:
                dr.text((10, y + 32), "true pixel size", font=FS, fill=DIM)
            st0 = first[0].get((mid, cam))
            if st0:
                dr.text((10, y + 52), when(st0, i), font=FS, fill=DIM)
            for k, (name, _) in enumerate(runs):
                st = data[name][0]
                if (mid, cam) in st:
                    sheet.paste(cell(st[(mid, cam)][0], i), (LW + k * (CW + GAP), y))
            y += CH + GAP
    y += 4
    for line in notes:
        dr.text((10, y + 4), line, font=FS, fill=DIM)
        y += 24
    sheet.save(a.out, quality=a.quality)
    print("SHEET", a.out, sheet.size)
    if a.strips:
        os.makedirs(a.strips, exist_ok=True)
        for mid, _ in MOMENTS:
            for cam in (170, 60, 26):
                rows = []
                for name, _ in runs:
                    st = data[name][0]
                    if (mid, cam) in st:
                        rows.append(Image.open(st[(mid, cam)][0]).convert("RGB"))
                if rows:
                    s = Image.new("RGB", (max(r.width for r in rows), sum(r.height for r in rows)), BG)
                    yy = 0
                    for r in rows:
                        s.paste(r, (0, yy)); yy += r.height
                    s.save(os.path.join(a.strips, "%s_c%d_all.jpg" % (mid, cam)), quality=82)


if __name__ == "__main__":
    main()
