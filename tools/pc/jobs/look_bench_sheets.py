"""Look bench sheet maker (issue 351). Turns one or two look bench runs (godot/bench/look_bench.tscn output folders)
into the sheets Ryan reads, and in before and after mode gives one difference number per still.

  python look_bench_sheets.py --after RUN [--before RUN] --out DIR [--tol 2.0] [--label-after X] [--label-before Y]

Writes into DIR:
  moments_overview_<group>.jpg  one row per moment, the key cell at the three cameras (170, 60, 26), side by side
  moments/<id>.jpg              the whole 30 frames a second strip of one moment at the three cameras (before above
                                after, with the difference number under every cell, red over the tolerance)
  fleet_<sky>.jpg               all 36 hulls at the battle camera, 1 to 1 pixels (before and after side by side)
  diffs.csv, diffs.json         before and after mode only: one row per still (a moment cell or a fleet hull)
  summary.txt                   what differs over the tolerance, by moment and by hull

The difference number: the mean absolute difference of the two stills over every pixel and the three colour channels,
in 0 to 255 levels (0 means identical). A still "differs" when its number is over --tol.
Needs Pillow (ComfyUI's portable Python has it; tools/pc/jobs/look_bench.bat finds it).
"""
import argparse
import csv
import json
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageStat

CAMS = [170, 60, 26]
LABEL_H = 22
BG = (14, 15, 18)
FG = (225, 228, 232)
DIM = (150, 155, 162)
RED = (235, 70, 60)
GREEN = (110, 200, 120)


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


F = font(15)
FB = font(20)


def load_run(d):
    with open(os.path.join(d, "bench.json"), encoding="utf-8") as f:
        rep = json.load(f)
    with open(os.path.join(d, "moments.json"), encoding="utf-8") as f:
        mom = json.load(f)
    return rep, mom


def strip_cells(path, cell, n):
    im = Image.open(path).convert("RGB")
    return [im.crop((i * cell[0], 0, (i + 1) * cell[0], cell[1])) for i in range(min(n, im.width // cell[0]))]


def diff(a, b):
    if a is None or b is None or a.size != b.size:
        return None
    st = ImageStat.Stat(ImageChops.difference(a, b))
    return sum(st.mean) / 3.0


def sky_level(paths):
    """Mean brightness (0-255, Rec. 601 luma) of the four 30x30 corners of every fleet cell: the sky behind the ships."""
    vals = []
    for p in paths:
        im = Image.open(p).convert("L")
        w, h = im.size
        for box in [(0, 0, 30, 30), (w - 30, 0, w, 30), (0, h - 30, 30, h), (w - 30, h - 30, w, h)]:
            vals.append(ImageStat.Stat(im.crop(box)).mean[0])
    return sum(vals) / len(vals) if vals else 0.0


def text(dr, xy, s, f=F, fill=FG):
    dr.text(xy, s, font=f, fill=fill)


def moment_cells(run, rows_by_id, cell):
    """{(id, cam): [cell images]} plus the cell times."""
    rep, _ = run
    out = {}
    for st in rep.get("stills", []):
        if st.get("part") != "moments":
            continue
        p = os.path.join(run_dir[id(run)], st["file"])
        if not os.path.exists(p):
            continue
        out[(st["id"], int(st["cam"]))] = (strip_cells(p, cell, len(st.get("cells", []))), st.get("cells", []))
    return out


run_dir = {}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--after", required=True)
    ap.add_argument("--before")
    ap.add_argument("--out", required=True)
    ap.add_argument("--tol", type=float, default=2.0)
    ap.add_argument("--label-after", default="")
    ap.add_argument("--label-before", default="")
    ap.add_argument("--quality", type=int, default=88)
    a = ap.parse_args()
    os.makedirs(os.path.join(a.out, "moments"), exist_ok=True)
    after = load_run(a.after)
    run_dir[id(after)] = a.after
    before = None
    if a.before:
        before = load_run(a.before)
        run_dir[id(before)] = a.before
    la = a.label_after or (after[0].get("commit", "")[:8] or "after")
    lb = (a.label_before or (before[0].get("commit", "")[:8] or "before")) if before else ""
    mom = after[1]
    cell = tuple(mom.get("cell", [384, 216]))
    rows = mom["rows"]
    rows_by_id = {r["id"]: r for r in rows}
    A = moment_cells(after, rows_by_id, cell)
    B = moment_cells(before, rows_by_id, cell) if before else {}
    diffs = []

    # ---- per-moment strip pages
    for r in rows:
        rid = r["id"]
        have = [c for c in CAMS if (rid, c) in A]
        if not have:
            continue
        n = max(len(A[(rid, c)][0]) for c in have)
        line_h = cell[1] + LABEL_H + (LABEL_H if before else 0)
        per_cam = (2 if before else 1)
        H = 34 + len(have) * per_cam * line_h
        W = 90 + n * cell[0]
        sheet = Image.new("RGB", (W, H), BG)
        dr = ImageDraw.Draw(sheet)
        text(dr, (8, 6), "%s   [%s]   %s" % (r["label"], r["group"], ("before %s (top) / after %s (bottom)" % (lb, la)) if before else la), FB)
        y = 34
        for c in have:
            ca, times = A[(rid, c)]
            cb = B.get((rid, c), ([], []))[0] if before else []
            for which, cells in ([("before", cb), ("after", ca)] if before else [("", ca)]):
                text(dr, (6, y + cell[1] // 2 - 18), "cam %d" % c, FB)
                if which:
                    text(dr, (6, y + cell[1] // 2 + 6), which, F, DIM)
                for i, im in enumerate(cells):
                    sheet.paste(im, (90 + i * cell[0], y))
                    if which != "before" and i < len(times):
                        text(dr, (92 + i * cell[0], y + cell[1] + 2), "t %+.3f s" % times[i]["t"], F, DIM)
                if which == "after":
                    for i, im in enumerate(cells):
                        d = diff(cb[i] if i < len(cb) else None, im)
                        diffs.append({"part": "moments", "id": rid, "group": r["group"], "cam": c, "cell": i,
                                      "t": times[i]["t"] if i < len(times) else None, "diff": d})
                        if d is not None:
                            col = RED if d > a.tol else GREEN
                            text(dr, (92 + i * cell[0] + 110, y + cell[1] + 2), "diff %.2f" % d, F, col)
                            if d > a.tol:
                                dr.rectangle((90 + i * cell[0], y, 90 + (i + 1) * cell[0] - 1, y + cell[1] - 1), outline=RED, width=3)
                y += line_h
        sheet.save(os.path.join(a.out, "moments", rid + ".jpg"), quality=a.quality)

    # ---- overview: one row per moment, key cell at the three cameras (before and after pairs in compare mode)
    groups = []
    for r in rows:
        if r["group"] not in groups:
            groups.append(r["group"])
    for g in groups:
        grow = [r for r in rows if r["group"] == g and any((r["id"], c) in A for c in CAMS)]
        if not grow:
            continue
        cols = len(CAMS) * (2 if before else 1)
        W = cols * cell[0] + (8 if before else 0) * len(CAMS)
        H = 40 + len(grow) * (cell[1] + LABEL_H + 4)
        sheet = Image.new("RGB", (W, H), BG)
        dr = ImageDraw.Draw(sheet)
        hdr = "Look bench: %s.  Columns: camera %s%s" % (g, ", ".join(str(c) for c in CAMS),
                                                         ("  (each: before %s | after %s)" % (lb, la)) if before else ("   " + la))
        text(dr, (8, 8), hdr, FB)
        y = 40
        for r in grow:
            k = int(r.get("key", 4))
            text(dr, (6, y + 2), r["label"], F)
            y += LABEL_H
            x = 0
            for c in CAMS:
                for which, src in ([("b", B), ("a", A)] if before else [("a", A)]):
                    cells = src.get((r["id"], c), ([], []))[0]
                    if cells:
                        im = cells[min(k, len(cells) - 1)]
                        sheet.paste(im, (x, y))
                        if which == "a" and before:
                            bc = B.get((r["id"], c), ([], []))[0]
                            d = diff(bc[min(k, len(bc) - 1)] if bc else None, im)
                            if d is not None:
                                text(dr, (x + 4, y + 4), "diff %.2f" % d, F, RED if d > a.tol else GREEN)
                    x += cell[0]
                x += 8 if before else 0
            y += cell[1] + 4
        safe = g.replace(" ", "_").replace(",", "")
        sheet.save(os.path.join(a.out, "moments_overview_%s.jpg" % safe), quality=a.quality)

    # ---- fleet sheets: 1 to 1 pixels, 6 a row
    fa = [s for s in after[0].get("stills", []) if s.get("part") == "fleet"]
    fb = {(s["sky"], s["code"]): s for s in (before[0].get("stills", []) if before else []) if s.get("part") == "fleet"}
    skies = []
    for s in fa:
        if s["sky"] not in skies:
            skies.append(s["sky"])
    levels = {sky: sky_level([os.path.join(a.after, s["file"]) for s in fa if s["sky"] == sky]) for sky in skies}
    plain = [k for k in skies if k != "storm"]
    darkest = min(plain, key=lambda k: levels[k]) if plain else ""
    brightest = max(plain, key=lambda k: levels[k]) if plain else ""
    with open(os.path.join(a.out, "skies.txt"), "w", encoding="utf-8") as f:
        f.write("Sky brightness behind the ships at the battle camera (mean of the cell corners, 0-255):\n")
        for k in skies:
            f.write("  %-9s %6.2f%s\n" % (k, levels[k], "   darkest" if k == darkest else ("   brightest" if k == brightest else "")))
    for sky in skies:
        items = [s for s in fa if s["sky"] == sky]
        if not items:
            continue
        im0 = Image.open(os.path.join(a.after, items[0]["file"]))
        cw, ch = im0.size
        per = 6 if not before else 3
        unit_w = cw * (2 if before else 1) + (6 if before else 0)
        rows_n = (len(items) + per - 1) // per
        W = per * (unit_w + 6)
        H = 40 + rows_n * (ch + LABEL_H + 6)
        sheet = Image.new("RGB", (W, H), BG)
        dr = ImageDraw.Draw(sheet)
        region = after[0].get("parts", {}).get("fleet_" + sky, {}).get("region", "")
        tag = " (DARKEST)" if sky == darkest else (" (BRIGHTEST)" if sky == brightest else "")
        text(dr, (8, 8), "Fleet at the battle camera (170), true pixel size, %s sky%s, %s region, sky level %.1f.  %s" % (
            sky, tag, region, levels[sky], ("before %s | after %s" % (lb, la)) if before else la), FB)
        for i, s in enumerate(items):
            x = (i % per) * (unit_w + 6)
            y = 40 + (i // per) * (ch + LABEL_H + 6)
            ia = Image.open(os.path.join(a.after, s["file"])).convert("RGB")
            what = s.get("what", "").replace("|", " ")
            lab = "%s  %s" % (s["code"], what)
            if before and (sky, s["code"]) in fb:
                ib = Image.open(os.path.join(a.before, fb[(sky, s["code"])]["file"])).convert("RGB")
                sheet.paste(ib, (x, y + LABEL_H))
                sheet.paste(ia, (x + cw + 6, y + LABEL_H))
                d = diff(ib, ia)
                diffs.append({"part": "fleet", "id": s["code"], "group": "fleet " + sky, "cam": 170, "cell": 0, "t": None, "diff": d})
                lab += "   diff %.2f" % d if d is not None else ""
                text(dr, (x + 4, y + 2), lab, F, RED if (d is not None and d > a.tol) else FG)
            else:
                sheet.paste(ia, (x, y + LABEL_H))
                text(dr, (x + 4, y + 2), lab, F)
        sheet.save(os.path.join(a.out, "fleet_%s.jpg" % sky), quality=92)

    # ---- numbers
    if before:
        with open(os.path.join(a.out, "diffs.csv"), "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=["part", "group", "id", "cam", "cell", "t", "diff"])
            w.writeheader()
            for d in diffs:
                w.writerow(d)
        with open(os.path.join(a.out, "diffs.json"), "w", encoding="utf-8") as f:
            json.dump({"tol": a.tol, "before": lb, "after": la, "stills": diffs}, f, indent=1)
        over = [d for d in diffs if d["diff"] is not None and d["diff"] > a.tol]
        missing = [d for d in diffs if d["diff"] is None]
        vals = [d["diff"] for d in diffs if d["diff"] is not None]
        by = {}
        for d in over:
            key = (d["part"], d["id"], d["cam"])
            by.setdefault(key, []).append(d["diff"])
        lines = ["Look bench compare: before %s, after %s, tolerance %.2f (mean absolute difference, 0-255 levels)" % (lb, la, a.tol),
                 "stills compared: %d, over the tolerance: %d, missing on one side: %d, largest: %.3f, mean: %.3f" % (
                     len(vals), len(over), len(missing), max(vals) if vals else 0.0, (sum(vals) / len(vals)) if vals else 0.0),
                 ""]
        if not over:
            lines.append("No still differs over the tolerance.")
        for key in sorted(by):
            v = by[key]
            lines.append("DIFFERS %s %s cam %d: %d stills, largest %.2f" % (key[0], key[1], key[2], len(v), max(v)))
        # the largest number for every moment and camera (and hull), so the noise floor is visible
        lines.append("")
        lines.append("Largest difference per moment and camera:")
        mx = {}
        for d in diffs:
            if d["diff"] is None:
                continue
            key = (d["part"], d["group"], d["id"], d["cam"])
            mx[key] = max(mx.get(key, 0.0), d["diff"])
        for key in sorted(mx):
            lines.append("  %-8s %-26s %-28s cam %3d  %.3f" % (key[0], key[1], key[2], key[3], mx[key]))
        with open(os.path.join(a.out, "summary.txt"), "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        print("\n".join(lines[:3]))
    print("SHEETS_DONE %s" % a.out)


if __name__ == "__main__":
    sys.exit(main())
