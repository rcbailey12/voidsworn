#!/usr/bin/env python3
"""Issue 207: the one-image sheet for Ryan (phone size): the measured scene, where it sits in a 60 fps frame at
1080p, 1440p and 4K with the gate share options marked, and what each part of the scene costs.

    python3 contrib/opus/tools/scene_gate_sheet.py docs/shots/ship_pipeline/bench207 --shares 50,60,75 --pick 60

Reads <dir>/summary.json (scene_gate_report.py) and <dir>/scene_engagement.webp; writes <dir>/headroom_sheet.png.
Colours: the reference dark palette (dataviz skill): blue for whole-frame time, aqua for GPU time, white for the pick.
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
AQUA = "#199e70"
TRACK = "#2c2c2a"
FRAME = 1000.0 / 60.0

PARTS = [  # mode, label
    ("shadows_off", "Shadows (sun, 4 cascades)"),
    ("msaa_off", "MSAA 4x anti-aliasing"),
    ("post_off", "Post (SSAO, SSIL, glow)"),
    ("ships_off", "The 20 ships (drawn, plus their logic)"),
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
    m = S["engagement"]["modes"]
    base = m["base"]["gpu_ms"]
    shares = [int(x) for x in a.shares.split(",")]
    pick = int(a.pick)

    fig = plt.figure(figsize=(10.8, 15.6), dpi=100, facecolor=PLANE)
    # 1. the scene
    shot = Image.open(os.path.join(a.folder, "scene_engagement.webp")).convert("RGB")
    ax0 = fig.add_axes([0.03, 0.565, 0.94, 0.94 * 1080 / 1920 * 10.8 / 15.6])
    ax0.imshow(shot)
    ax0.set_axis_off()
    fig.text(0.03, 0.988, "Scene gate benchmark, RTX 5080", color=INK, fontsize=26, fontweight="bold", va="top")
    fig.text(0.03, 0.957, "20 ships from all six factions, storm map, planet and nebulas, effects firing, HUD up",
             color=INK2, fontsize=15, va="top")

    # 2. headroom at three screen sizes: frame time (what you feel; the CPU sets it here) and GPU time, per screen size.
    # 1440p and 4K are the 1080p gate numbers plus the paired change the res run measured for that size.
    fb = m["base"]["frame_ms"]
    rows = [("1080p", fb, base)]
    res = S.get("res", {}).get("modes", {})
    for key, lab in [("res_1440", "1440p"), ("res_2160", "4K")]:
        if key in res and res[key].get("delta_gpu_ms") is not None:
            rows.append((lab, fb + res[key]["delta_frame_ms"], base + res[key]["delta_gpu_ms"]))
    ax1 = fig.add_axes([0.13, 0.335, 0.82, 0.165], facecolor=SURFACE)
    fig.text(0.03, 0.552, "Time per frame, against one 60 fps frame (16.7 ms)", color=INK, fontsize=19,
             fontweight="bold", va="top")
    fig.text(0.03, 0.530, "Blue: whole frame (what you feel).  Green: graphics card.  Dashed: gate options, white is my pick.",
             color=INK2, fontsize=13.5, va="top")
    n = len(rows)
    xmax = FRAME * 1.32
    for i, (lab, fr, gp) in enumerate(rows):
        y = n - 1 - i
        for dy, v, col, tag in [(0.17, fr, BLUE, "frame"), (-0.17, gp, AQUA, "GPU")]:
            ax1.barh(y + dy, FRAME, height=0.3, color=TRACK, zorder=1)
            ax1.barh(y + dy, v, height=0.3, color=col, zorder=2)
            ax1.text(v + xmax * 0.012, y + dy, "%s %.1f ms (%d%%)" % (tag, v, round(100 * v / FRAME)), va="center",
                     ha="left", color=INK, fontsize=12.5, zorder=5, bbox=dict(facecolor=SURFACE, edgecolor="none", pad=1.5))
    for sh in shares:
        x = FRAME * sh / 100.0
        c = INK if sh == pick else MUTED
        ax1.axvline(x, color=c, lw=2.2 if sh == pick else 1.3, ls="--", zorder=3)
        ax1.text(x, n - 0.45, "%d%%\n%.1f ms" % (sh, x), color=c, ha="center", va="bottom", fontsize=12.5,
                 fontweight="bold" if sh == pick else "normal")
    ax1.axvline(FRAME, color=INK2, lw=1.2, zorder=3)
    ax1.text(FRAME, n - 0.45, "full frame\n16.7 ms", color=INK2, ha="center", va="bottom", fontsize=12.5)
    ax1.set_yticks([n - 1 - i for i in range(n)])
    ax1.set_yticklabels([r[0] for r in rows], color=INK, fontsize=16)
    ax1.set_xlim(0, xmax)
    ax1.set_ylim(-0.55, n + 0.25)
    ax1.tick_params(axis="x", colors=MUTED, labelsize=12)
    ax1.tick_params(axis="y", length=0)
    for sp in ax1.spines.values():
        sp.set_visible(False)
    ax1.grid(axis="x", color=GRID, lw=0.8, zorder=0)
    ax1.set_axisbelow(True)

    # 3. what each part costs at 1080p: paired, base minus the run without that part; frame (blue) and GPU (green)
    parts = []
    for mode, lab in PARTS:
        if mode in m and m[mode].get("delta_gpu_ms") is not None:
            parts.append((lab, -m[mode]["delta_frame_ms"], -m[mode]["delta_gpu_ms"]))
    parts.sort(key=lambda t: max(t[1], t[2]))
    ax2 = fig.add_axes([0.42, 0.06, 0.53, 0.215], facecolor=SURFACE)
    fig.text(0.03, 0.305, "What each part costs at 1080p (ms saved by turning it off)", color=INK,
             fontsize=19, fontweight="bold", va="top")
    top = max(max(p[1], p[2]) for p in parts)
    for i, (lab, fr, gp) in enumerate(parts):
        for dy, v, col in [(0.18, fr, BLUE), (-0.18, gp, AQUA)]:
            ax2.barh(i + dy, max(v, 0.0), height=0.32, color=col, zorder=2)
            ax2.text(max(v, 0.0) + 0.02 * top, i + dy, "%.1f" % v if v >= 0.05 else "~0", va="center", ha="left",
                     color=INK, fontsize=12)
    ax2.set_yticks(range(len(parts)))
    ax2.set_yticklabels([p[0] for p in parts], color=INK, fontsize=14)
    ax2.set_xlim(0, top * 1.2)
    ax2.tick_params(axis="x", colors=MUTED, labelsize=12)
    ax2.set_xlabel("ms saved (blue: whole frame, green: graphics card)", color=MUTED, fontsize=12)
    ax2.tick_params(axis="y", length=0)
    for sp in ax2.spines.values():
        sp.set_visible(False)
    ax2.grid(axis="x", color=GRID, lw=0.8, zorder=0)
    ax2.set_axisbelow(True)
    fig.text(0.03, 0.014, "Parts overlap (a ship's shadow counts under ships and under shadows), so they do not add up.",
             color=MUTED, fontsize=12)
    out = os.path.join(a.folder, "headroom_sheet.png")
    fig.savefig(out, facecolor=PLANE)
    print(out)


if __name__ == "__main__":
    main()
