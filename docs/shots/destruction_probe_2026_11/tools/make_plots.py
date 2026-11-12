#!/usr/bin/env python
# Issue 234: draws the report plots as PNG (PIL, text included). Reads the probe JSON
# next to this folder. Run from anywhere: python tools/make_plots.py
from __future__ import annotations
import json
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.abspath(os.path.join(HERE, ".."))
OUT = os.path.join(DATA, "plots")
os.makedirs(OUT, exist_ok=True)

BG = (13, 17, 23)
PANEL = (22, 27, 34)
INK = (230, 237, 243)
DIM = (139, 148, 158)
GRID = (48, 54, 61)
A = (88, 166, 255)
B = (255, 170, 80)
C = (63, 185, 80)
D = (219, 97, 162)
WARN = (248, 81, 73)

FONT = "C:/Windows/Fonts/consola.ttf"
if not os.path.exists(FONT):
    FONT = "C:/Windows/Fonts/arial.ttf"


def font(size):
    try:
        return ImageFont.truetype(FONT, size)
    except Exception:
        return ImageFont.load_default()


def text(d, x, y, s, size=14, fill=INK, anchor="la"):
    d.text((x, y), str(s), font=font(size), fill=fill, anchor=anchor)


def box(d, x0, y0, x1, y1, fill=PANEL, outline=None):
    d.rectangle([x0, y0, x1, y1], fill=fill, outline=outline)


def line(d, x0, y0, x1, y1, fill=GRID, width=1):
    d.line([x0, y0, x1, y1], fill=fill, width=width)


def read(name):
    with open(os.path.join(DATA, name), "r", encoding="utf-8") as f:
        return json.load(f)


def axes(d, w, h, title, xlab, ylab, xmax, ymax, ytick=0.2, xtick=None, note=""):
    box(d, 20, 20, w - 20, h - 20)
    text(d, 40, 34, title, 20, INK)
    if note:
        text(d, 40, 62, note, 13, DIM)
    L, R, T, B = 110, w - 50, 100, h - 95
    for i in range(int(round(ymax / ytick)) + 1):
        v = i * ytick
        y = B - (B - T) * v / ymax
        line(d, L, y, R, y, GRID)
        text(d, L - 10, y, f"{v:.2f}", 13, DIM, "rm")
    step = xtick or max(1, int(xmax / 10))
    x = 0
    while x <= xmax + 1e-9:
        px = L + (R - L) * x / xmax
        text(d, px, B + 12, f"{int(x)}", 13, DIM, "ma")
        x += step
    text(d, (L + R) / 2, h - 60, xlab, 14, DIM, "ma")
    if ylab:
        text(d, L, T - 10, ylab, 12, DIM, "la")
    return L, R, T, B


def mx(v, xmax, L, R):
    return L + (R - L) * v / xmax


def my(v, ymax, T, B):
    return B - (B - T) * v / ymax


def save(img, name):
    img.save(os.path.join(OUT, name))
    print("PNG", name)


def physics_plot():
    data = read("physics.json")
    rows = data["rows"]
    counts = data["counts"]
    w, h = 1200, 640
    img = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(img)
    L, R, T, B = axes(d, w, h, "Physics step vs body count (convex wreck colliders, Jolt, fixed 60 Hz)",
                      "rigid bodies (wreck pieces + debris)", "physics step, ms (median)", 720, 1.0, 0.2, 50,
                      "headless, --fixed-fps 60. The R116 gate is 12.5 ms, 31x the 360-body damp 0 median.")
    for damp, col, label in [(0.0, A, "damp 0.0"), (0.3, B, "damp 0.3")]:
        pts = []
        for n in counts:
            r = next(x for x in rows if x["count"] == n and x["damp"] == damp and x["kind"] == "convex")
            pts.append((mx(n, 720, L, R), my(r["median_ms"], 1.0, T, B)))
        d.line(pts, fill=col, width=3)
        for p in pts:
            d.ellipse([p[0] - 3, p[1] - 3, p[0] + 3, p[1] + 3], fill=col)
    # legend inside the plot
    for i, (damp, col, label) in enumerate([(0.0, A, "damp 0.0"), (0.3, B, "damp 0.3")]):
        ly = T + 16 + i * 24
        d.line([L + 12, ly, L + 44, ly], fill=col, width=3)
        text(d, L + 52, ly, label, 14, col, "lm")
    for n in (360, 720):
        px = mx(n, 720, L, R)
        line(d, px, T + 6, px, B, DIM, 1)
        r0 = next(x for x in rows if x["count"] == n and x["damp"] == 0.0 and x["kind"] == "convex")
        r3 = next(x for x in rows if x["count"] == n and x["damp"] == 0.3 and x["kind"] == "convex")
        text(d, px + 6 if n == 360 else px - 6, B - 20, f"n={n} p95 {r0['p95_ms']:.2f} / {r3['p95_ms']:.2f} ms", 12, DIM, "la" if n == 360 else "ra")
    text(d, L, h - 32, "at 360: 0.400 ms damp 0.0, 0.463 ms damp 0.3. at 720 (doubled cap): 0.785 / 0.927 ms.", 13, INK)
    save(img, "physics_step_vs_bodies.png")


def collider_plot():
    data = read("physics.json")
    rows = [x for x in data["rows"] if x["damp"] == 0.0]
    counts = data["counts"]
    w, h = 1200, 640
    img = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(img)
    L, R, T, B = axes(d, w, h, "Collider cost vs body count (damp 0.0): convex hull vs no collider",
                      "rigid bodies", "physics step, ms (median)", 720, 0.9, 0.2, 50,
                      f"collider build cost {data['collider_build_ms_per_body']:.2f} ms per piece (one-time, worker side).")
    for kind, col, label in [("convex", A, "convex hull, <=50 points"), ("none", C, "no collision shape")]:
        pts = []
        for n in counts:
            r = next(x for x in rows if x["count"] == n and x["kind"] == kind)
            pts.append((mx(n, 720, L, R), my(r["median_ms"], 0.9, T, B)))
        d.line(pts, fill=col, width=3)
        for p in pts:
            d.ellipse([p[0] - 3, p[1] - 3, p[0] + 3, p[1] + 3], fill=col)
    for i, (kind, col, label) in enumerate([("convex", A, "convex hull, <=50 points"), ("none", C, "no collision shape")]):
        ly = T + 16 + i * 24
        d.line([L + 12, ly, L + 44, ly], fill=col, width=3)
        text(d, L + 52, ly, label, 14, col, "lm")
    boxr = next(x for x in rows if x["count"] == 360 and x["kind"] == "box")
    bx, by = mx(360, 720, L, R), my(boxr["median_ms"], 0.9, T, B)
    d.ellipse([bx - 5, by - 5, bx + 5, by + 5], fill=B)
    text(d, bx + 10, by - 22, f"360 box collider {boxr['median_ms']:.3f} ms", 13, INK)
    text(d, L, h - 32, "step delta (convex - none): 0.124 ms at 360, 0.361 ms at 720; per body 0.00034 / 0.00050 ms.", 13, INK)
    save(img, "collider_cost_vs_bodies.png")


def wreck_plot():
    data = read("wrecks.json")
    counts = data["counts_after_each_death"]
    w, h = 1200, 640
    img = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(img)
    L, R, T, B = axes(d, w, h, "Worst-case wipe: visual wreck list against the 24 cap",
                      "staged death number", "", len(counts), 24, 4, 2,
                      "30 staged deaths. The oldest visual wrecks are evicted at the cap; set-piece hulks are a separate world list.")
    pts = [(mx(i + 1, len(counts), L, R), my(v, 24, T, B)) for i, v in enumerate(counts)]
    d.line(pts, fill=A, width=3)
    for p in pts:
        d.ellipse([p[0] - 3, p[1] - 3, p[0] + 3, p[1] + 3], fill=A)
    y = my(24, 24, T, B)
    for x in range(L, R, 12):
        d.line([x, y, min(x + 6, R), y], fill=WARN, width=2)
    text(d, R - 10, y - 24, "cap 24", 15, WARN, "ra")
    text(d, L, h - 32, f"final list {data['final_count']}; oldest ids evicted; a 20-ship wipe is 20 (4 under), a 27-ship all-sides wipe recycles 3.", 13, INK)
    save(img, "wreck_cap.png")


CLS_ORDER = ["Frigate", "Destroyer", "Cruiser", "Carrier", "Battleship", "Dreadnought",
             "Battle-barge", "Bio-titan", "Ark", "Tomb-ark", "Super-dreadnought"]


def heatmap(field, maxv, title, note, name):
    data = read("ram_outcomes.json")
    vals = {}
    for r in data["matrix"]["by_class"]:
        a, b = r["matchup"].split(" -> ")
        vals[(a, b)] = r[field]
    cw, ch = 78, 30
    left, top = 190, 130
    w = left + cw * len(CLS_ORDER) + 30
    h = top + ch * len(CLS_ORDER) + 80
    img = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(img)
    text(d, 24, 26, title, 20, INK)
    text(d, 24, 54, note, 13, DIM)
    SHORT = {"Frigate": "FRIG", "Destroyer": "DEST", "Cruiser": "CRU", "Carrier": "CARR",
             "Battleship": "BB", "Dreadnought": "DN", "Battle-barge": "BARGE", "Bio-titan": "TITAN",
             "Ark": "ARK", "Tomb-ark": "TOMB", "Super-dreadnought": "SDR"}
    for c, cls in enumerate(CLS_ORDER):
        text(d, left + c * cw + cw / 2, top - 10, SHORT[cls], 11, DIM, "ma")
    for r, acls in enumerate(CLS_ORDER):
        text(d, left - 10, top + r * ch + ch / 2, acls, 13, DIM, "rm")
        for c, bcls in enumerate(CLS_ORDER):
            v = vals.get((acls, bcls))
            if v is None:
                continue
            t = max(0.0, min(1.0, v / maxv))
            red = int(30 + 220 * t)
            green = int(70 + 80 * (1 - abs(t - 0.5) * 2))
            blue = int(160 * (1 - t) + 30)
            d.rectangle([left + c * cw, top + r * ch, left + (c + 1) * cw - 2, top + (r + 1) * ch - 2],
                        fill=(red, green, blue))
            text(d, left + c * cw + cw / 2, top + r * ch + ch / 2, f"{v * 100:.0f}", 12,
                 (255, 255, 255) if t > 0.55 else INK, "mm")
    text(d, 24, h - 62, "FRIG Frigate, DEST Destroyer, CRU Cruiser, CARR Carrier, BB Battleship, DN Dreadnought,", 11, DIM)
    text(d, 24, h - 46, "BARGE Battle-barge, TITAN Bio-titan, ARK Ark, TOMB Tomb-ark, SDR Super-dreadnought.", 11, DIM)
    text(d, 24, h - 28, "rows: attacker. columns: target. baseline hulls, no boons; value: mean percent of target max hull (damage) or attacker max hull (recoil).", 11, DIM)
    save(img, name)


def appetite_plot():
    data = read("ram_outcomes.json")
    ap = data["appetite"]
    facs = sorted(ap["opp_by_fac"])
    w, h = 1200, 620
    img = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(img)
    text(d, 30, 28, "Ram appetite in the G3 campaign harness", 20, INK)
    text(d, 30, 56, f"{ap['runs']} runs, {ap['battles']} battles, {ap['rounds']} rounds. "
                    f"{ap['opportunities']} opportunities, {ap['threshold_pass']} threshold passes, {ap['landed']} landed.", 13, DIM)
    L, R, T, B = 100, 820, 120, 500
    maxv = max(ap["opp_by_fac"][f] for f in facs)
    for i in range(5):
        v = maxv * i / 4
        y = B - (B - T) * i / 4
        line(d, L, y, R, y, GRID)
        text(d, L - 10, y, f"{int(v)}", 13, DIM, "rm")
    gw = (R - L) / len(facs)
    bw = gw * 0.24
    for i, f in enumerate(facs):
        x0 = L + i * gw + gw * 0.12
        for j, (key, col) in enumerate([("opp_by_fac", A), ("pass_by_fac", B), ("landed_by_fac", C)]):
            v = ap[key][f]
            hh = (B - T) * v / maxv
            d.rectangle([x0 + j * bw, B - hh, x0 + (j + 1) * bw - 3, B], fill=col)
        text(d, L + i * gw + gw / 2, B + 14, f, 13, DIM, "ma")
    text(d, L, B + 40, "opportunities = a legal run-up; pass = AI threshold; landed = ram resolved", 13, DIM)
    text(d, R + 24, T, "threshold band", 16, INK)
    bands = ap["pass_by_band"]
    items = [("kill", bands["kill"], D), ("ram faction 30%", bands["ram30"], B), ("other 45%", bands["other45"], A)]
    for k, v, col in items:
        text(d, R + 24, 160 + items.index((k, v, col)) * 40, f"{k}: {v} ({100 * v / max(ap['threshold_pass'], 1):.1f}%)", 14, col)
    text(d, R + 24, 300, f"opportunities per battle: {ap['opportunity_rate_per_battle']:.2f}", 14, INK)
    text(d, R + 24, 324, f"pass rate: {100 * ap['pass_rate_of_opportunities']:.1f}%", 14, INK)
    text(d, R + 24, 348, f"by side: enemy {ap['landed_by_side'].get('enemy', 0)}, player {ap['landed_by_side'].get('player', 0)}", 14, INK)
    text(d, 30, h - 24, "source: ram_montecarlo.js on contrib/muse/tools/montecarlo (baseline policy, veteran AI, seed 234000)", 12, DIM)
    save(img, "ram_appetite.png")


physics_plot()
collider_plot()
wreck_plot()
heatmap("mean_dmg_frac", 0.45,
        "Ram damage by class matchup (percent of target max hull)",
        "shipped ramEstimate; shields averaged; run-up 1, 2 and 3+; full and 40 percent target hull. No cell reaches 100 percent: cap is 40.",
        "ram_damage_by_class.png")
heatmap("mean_recoil_frac", 0.65,
        "Ram recoil by class matchup (percent of attacker max hull)",
        "shipped ramEstimate recoil; no boons. RAM_FAC factions use the 0.35 recoil factor, others 0.5.",
        "ram_recoil_by_class.png")
appetite_plot()
print("plots written to", OUT)
