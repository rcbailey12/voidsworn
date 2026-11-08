#!/usr/bin/env python3
"""Issue 207: the one-image sheet for Ryan (phone size): the measured scene, where it sits in a 60 fps frame at
1080p, 1440p and 4K with the gate share options marked, and what each part of the scene costs.

    python3 contrib/opus/tools/scene_gate_sheet.py docs/shots/ship_pipeline/bench207 --shares 50,60,75 --pick 60

Reads <dir>/summary.json (scene_gate_report.py) and <dir>/scene_base.png; writes <dir>/headroom_sheet.png.
Colours: the reference dark palette (dataviz skill), blue for measured cost, orange for the picked gate line only.
"""
import argparse
import json
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager
from PIL import Image

SURFACE = "#1a1a19"
PLANE = "#0d0d0d"
INK = "#f0efec"
INK2 = "#c3c2b7"
MUTED = "#898781"
GRID = "#2c2c2a"
AXIS = "#383835"
BLUE = "#3987e5"
ORANGE = "#d95926"
TRACK = "#2c2c2a"
FRAME = 1000.0 / 60.0

PARTS = [  # mode, label
    ("shadows_off", "Shadows (sun, 4 cascades)"),
    ("msaa_off", "MSAA 4x anti-aliasing"),
    ("post_off", "Post (SSAO, SSIL, glow)"),
    ("ships_off", "The 20 ships (hulls)"),
    ("fx_off", "Effects (weapons, engines, shields)"),
    ("world_off", "World (planet, rocks, clouds)"),
    ("hud_off", "HUD"),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("folder")
    ap.add_argument("--shares", default="50,60,75")
    ap.add_argument("--pick", default="60")
    a = ap.parse_args()
    for f in ["Inter", "DejaVu Sans"]:
        if any(f in x.name for x in font_manager.fontManager.ttflist):
            plt.rcParams["font.family"] = f
            break
    S = json.load(open(os.path.join(a.folder, "summary.json")))
    m = S["modes"]
    base = S["base"]["gpu_ms"]
    shares = [int(x) for x in a.shares.split(",")]
    pick = int(a.pick)

    fig = plt.figure(figsize=(10.8, 15.6), dpi=100, facecolor=PLANE)
    # 1. the scene
    shot = Image.open(os.path.join(a.folder, "scene_base.png")).convert("RGB")
    ax0 = fig.add_axes([0.03, 0.565, 0.94, 0.94 * 1080 / 1920 * 10.8 / 15.6])
    ax0.imshow(shot)
    ax0.set_axis_off()
    fig.text(0.03, 0.988, "Scene gate benchmark, RTX 5080", color=INK, fontsize=26, fontweight="bold", va="top")
    fig.text(0.03, 0.957, "20 ships from all six factions, storm map, planet and nebulas, effects firing, HUD up",
             color=INK2, fontsize=15, va="top")

    # 2. headroom at three screen sizes
    rows = [("1080p", base)]
    res = S.get("res", {})
    if "res_1440" in res and "base" in res:
        k = base / res["base"]["gpu_ms"]   # pin the res run to this run's base so the three bars share one baseline
        rows.append(("1440p", res["res_1440"]["gpu_ms"] * k))
        if "res_2160" in res:
            rows.append(("4K", res["res_2160"]["gpu_ms"] * k))
    ax1 = fig.add_axes([0.13, 0.345, 0.82, 0.155], facecolor=SURFACE)
    fig.text(0.03, 0.552, "GPU time per frame, against one 60 fps frame (16.7 ms)", color=INK, fontsize=19,
             fontweight="bold", va="top")
    fig.text(0.03, 0.530, "Dashed lines: gate share options for you to pick. Orange: my pick.", color=INK2,
             fontsize=14, va="top")
    ys = list(range(len(rows)))[::-1]
    xmax = max(FRAME, max(v for _, v in rows)) * 1.32
    for y, (lab, v) in zip(ys, rows):
        ax1.barh(y, FRAME, height=0.52, color=TRACK, zorder=1)
        ax1.barh(y, v, height=0.52, color=BLUE, zorder=2)
        ax1.text(v + xmax * 0.012, y, "%.1f ms  (%d%%)" % (v, round(100 * v / FRAME)), va="center", ha="left",
                 color=INK, fontsize=15, zorder=5, bbox=dict(facecolor=SURFACE, edgecolor="none", pad=2.5))
    for s in shares:
        x = FRAME * s / 100.0
        c = ORANGE if s == pick else MUTED
        ax1.axvline(x, color=c, lw=2.2 if s == pick else 1.4, ls="--", zorder=3)
        ax1.text(x, len(rows) - 0.42, "%d%%\n%.1f ms" % (s, x), color=c, ha="center", va="bottom", fontsize=12.5,
                 fontweight="bold" if s == pick else "normal")
    ax1.axvline(FRAME, color=INK2, lw=1.2, zorder=3)
    ax1.text(FRAME, len(rows) - 0.42, "full frame\n16.7 ms", color=INK2, ha="center", va="bottom", fontsize=12.5)
    ax1.set_yticks(ys)
    ax1.set_yticklabels([r[0] for r in rows], color=INK, fontsize=16)
    ax1.set_xlim(0, xmax)
    ax1.set_ylim(-0.5, len(rows) + 0.25)
    ax1.tick_params(axis="x", colors=MUTED, labelsize=12)
    ax1.set_xlabel("GPU ms per frame", color=MUTED, fontsize=12)
    ax1.tick_params(axis="y", length=0)
    for sp in ax1.spines.values():
        sp.set_visible(False)
    ax1.grid(axis="x", color=GRID, lw=0.8, zorder=0)
    ax1.set_axisbelow(True)

    # 3. what each part costs at 1080p (paired: base minus the run without that part)
    parts = []
    for mode, lab in PARTS:
        if mode in m and m[mode].get("delta_gpu_ms") is not None:
            parts.append((lab, -m[mode]["delta_gpu_ms"]))
    parts.sort(key=lambda t: t[1])
    ax2 = fig.add_axes([0.40, 0.06, 0.55, 0.215], facecolor=SURFACE)
    fig.text(0.03, 0.305, "What each part costs (GPU ms at 1080p, measured by turning it off)", color=INK,
             fontsize=19, fontweight="bold", va="top")
    for i, (lab, v) in enumerate(parts):
        ax2.barh(i, max(v, 0.0), height=0.6, color=BLUE, zorder=2)
        ax2.text(max(v, 0.0) + 0.02 * max(p[1] for p in parts), i, "%.2f ms" % v, va="center", ha="left", color=INK,
                 fontsize=14)
    ax2.set_yticks(range(len(parts)))
    ax2.set_yticklabels([p[0] for p in parts], color=INK, fontsize=14.5)
    ax2.set_xlim(0, max(p[1] for p in parts) * 1.28)
    ax2.tick_params(axis="x", colors=MUTED, labelsize=12)
    ax2.set_xlabel("GPU ms saved when turned off", color=MUTED, fontsize=12)
    ax2.tick_params(axis="y", length=0)
    for sp in ax2.spines.values():
        sp.set_visible(False)
    ax2.grid(axis="x", color=GRID, lw=0.8, zorder=0)
    ax2.set_axisbelow(True)
    fig.text(0.03, 0.014, "Parts overlap (shadows of ships count in both), so they do not add up to the total.",
             color=MUTED, fontsize=12)
    out = os.path.join(a.folder, "headroom_sheet.png")
    fig.savefig(out, facecolor=PLANE)
    print(out)


if __name__ == "__main__":
    main()
