"""Issue 353: the explosion routes bench sheet. Today, route A and route B side by side for the torpedo hit and the cruiser
death, each route in its two fire amounts, from look bench runs (godot/bench/look_bench.tscn --only ...).

python explosion_routes_sheet.py --runs today=DIR a_flash=DIR ... --out SHEET.jpg [--cells id=3,6,10 ...] [--notes FILE]
                                 [--strips DIR]

Each row: three moments in time at camera 170 (the battle camera, true pixel size, 1 to 1 crop), then the moment's key
cell at camera 60 and camera 26. The cell times (seconds from the moment's start) are printed under the camera 170 cells.
--strips DIR also writes every camera 170 cell of every run side by side (one picture per moment), to pick the cells.
Needs Pillow (ComfyUI's portable Python on the PC).
"""
import argparse, json, os
from PIL import Image, ImageDraw, ImageFont

BG = (14, 15, 19); FG = (232, 234, 238); DIM = (150, 155, 162)
LABELS = {
    "today": "Today: 64 cells, smoke only",
    "a_flash": "Route A, flash only",
    "a_core": "Route A, flash + hot core",
    "b_flash": "Route B, flash only",
    "b_core": "Route B, flash + hot core",
}
MOMENTS = [("w_torp_void_hull", "Torpedo hit: Sunward torpedo on an Eclipse cruiser"),
           ("d_cruiser", "Cruiser death: Sunward cruiser (big)")]


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
            out[(st["id"], int(st["cam"]))] = (os.path.join(run, st["file"]), st.get("cells", []))
    return out, rows


def cell(path, i, size=(384, 216)):
    im = Image.open(path).convert("RGB")
    i = max(0, min(i, im.width // size[0] - 1))
    return im.crop((i * size[0], 0, (i + 1) * size[0], size[1]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", nargs="+", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--cells", nargs="*", default=[])
    ap.add_argument("--notes")
    ap.add_argument("--strips")
    a = ap.parse_args()
    runs = [r.split("=", 1) for r in a.runs]
    picks = {"w_torp_void_hull": [2, 4, 8], "d_cruiser": [7, 9, 12]}
    for c in a.cells:
        k, v = c.split("=", 1)
        picks[k] = [int(x) for x in v.split(",")]
    data = {name: stills(d) for name, d in runs}
    F, FB, FS = font(17), font(24), font(14)
    LW, CW, CH, GAP = 250, 384, 216, 4
    cols = 5
    W = LW + cols * (CW + GAP)
    notes = open(a.notes, encoding="utf-8").read().splitlines() if a.notes else []
    H = 60 + len(MOMENTS) * (40 + 26 + len(runs) * (CH + GAP)) + 24 * len(notes) + 20
    sheet = Image.new("RGB", (W, H), BG)
    dr = ImageDraw.Draw(sheet)
    dr.text((10, 14), "Explosion routes (issue 353): today, route A (256 cell fire and smoke sim) and route B (128 cell smoke "
            "body + authored hot core and sparks). Pick a route and a fire amount.", font=FB, fill=FG)
    y = 60
    for mid, title in MOMENTS:
        dr.text((10, y + 8), title, font=FB, fill=FG)
        y += 40
        first = data[runs[0][0]][0].get((mid, 170))
        times = first[1] if first else []
        heads = ["camera 170, t = %.2f s" % float(times[i].get("t", 0.0)) if i < len(times) else "camera 170" for i in picks[mid]]
        key = int(data[runs[0][0]][1].get(mid, {}).get("key", 4))
        heads += ["camera 60 (key)", "camera 26 (key)"]
        for k, h in enumerate(heads):
            dr.text((LW + k * (CW + GAP) + 4, y + 4), h, font=FS, fill=DIM)
        y += 26
        for name, _ in runs:
            st, _ = data[name]
            for li, part in enumerate(LABELS.get(name, name).split(", ")):
                dr.text((10, y + 8 + li * 24), part + ("," if li == 0 and ", " in LABELS.get(name, name) else ""), font=F, fill=FG)
            k = 0
            for i in picks[mid]:
                if (mid, 170) in st:
                    sheet.paste(cell(st[(mid, 170)][0], i), (LW + k * (CW + GAP), y))
                k += 1
            for cam in (60, 26):
                if (mid, cam) in st:
                    sheet.paste(cell(st[(mid, cam)][0], key), (LW + k * (CW + GAP), y))
                k += 1
            y += CH + GAP
    for line in notes:
        dr.text((10, y + 4), line, font=FS, fill=DIM)
        y += 24
    sheet.save(a.out, quality=84)
    print("SHEET", a.out, sheet.size)
    if a.strips:
        os.makedirs(a.strips, exist_ok=True)
        for mid, _ in MOMENTS:
            rows = []
            for name, _ in runs:
                st, _ = data[name]
                if (mid, 170) in st:
                    rows.append(Image.open(st[(mid, 170)][0]).convert("RGB"))
            if rows:
                s = Image.new("RGB", (max(r.width for r in rows), sum(r.height for r in rows)), BG)
                yy = 0
                for r in rows:
                    s.paste(r, (0, yy)); yy += r.height
                s.save(os.path.join(a.strips, mid + "_c170_all.jpg"), quality=82)


if __name__ == "__main__":
    main()
