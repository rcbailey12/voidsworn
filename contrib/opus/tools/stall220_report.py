#!/usr/bin/env python3
"""Issue 220 report: the gate scene's frame stalls before and after the fix.

  python3 contrib/opus/tools/stall220_report.py <out folder> <docs folder>

<out folder> is Downloads\\voidsworn_test\\opus220\\out (or a copy) with t1_1, t1_2 (before, --trace), t2_1, t2_2
(after, --trace) and optionally g1_1, g1_2 (after, base and res_2160). Writes into <docs folder>: summary.json,
tables.md and frames.png (one session's frame times before and after, with the 16.7 ms line).
"""
import glob
import json
import os
import statistics
import sys

SECTIONS = ["piece_meshes", "breach_apply", "volley", "death", "break_up", "L:l_split_vent"]
NAMES = {"piece_meshes": "death pieces built (cut ready)", "breach_apply": "hull damage rebuild shown",
         "volley": "volley fired", "death": "ship death started", "break_up": "ship breaks up",
         "L:l_split_vent": "death vent jet"}


def runs(out, tag):
    rows = []
    for f in sorted(glob.glob(os.path.join(out, tag + "_*", "scene_gate.json"))):
        launch = os.path.basename(os.path.dirname(f))
        d = json.load(open(f))
        for mode, rs in d["modes"].items():
            for r in rs:
                rows.append({"launch": launch, "mode": mode, "session": r["session"], "frame_median": r["frame_median"],
                             "frame_p99": r["frame_p99"], "gpu_median": r["gpu_median"],
                             "over_16_7": (r.get("trace") or {}).get("spikes_over_16_7"),
                             "dir": os.path.dirname(f)})
    return rows


def frames(row):
    p = os.path.join(row["dir"], "trace_%s_s%d.json" % (row["mode"], row["session"]))
    return json.load(open(p)) if os.path.exists(p) else []


def section_stats(rows):
    out = {}
    for row in rows:
        for fr in frames(row):
            for k in SECTIONS:
                if k in fr["fx"]:
                    out.setdefault(k, []).append(fr["fx"][k])
    return {k: {"calls": len(v), "median_ms": round(statistics.median(v), 2), "max_ms": round(max(v), 1)} for k, v in out.items()}


def main():
    out, docs = sys.argv[1], sys.argv[2]
    os.makedirs(docs, exist_ok=True)
    before, after, k4 = runs(out, "t1"), runs(out, "t2"), runs(out, "g1")
    summ = {"before": before, "after": after, "gate_4k": k4,
            "sections_before": section_stats(before), "sections_after": section_stats(after)}
    for r in before + after + k4:
        r.pop("dir", None)
    json.dump(summ, open(os.path.join(docs, "summary.json"), "w"), indent=1)
    before, after = runs(out, "t1"), runs(out, "t2")
    L = ["| Run | Mode | Session | Frame median ms | Frame p99 ms | Frames over 16.7 ms (of 720) | GPU median ms |",
         "|---|---|---:|---:|---:|---:|---:|"]
    for name, rs in [("before", before), ("after", after)]:
        for r in sorted(rs, key=lambda r: (r["mode"], r["launch"], r["session"])):
            L.append("| %s (%s) | %s | %d | %.2f | %.1f | %s | %.2f |" % (name, r["launch"][-1], r["mode"], r["session"],
                     r["frame_median"], r["frame_p99"], r["over_16_7"], r["gpu_median"]))
    L += ["", "| Main-thread step | Before: calls, median, worst ms | After: calls, median, worst ms |", "|---|---:|---:|"]
    sb, sa = summ["sections_before"], summ["sections_after"]
    for k in SECTIONS:
        b, a = sb.get(k), sa.get(k)
        f = lambda s: "%d, %.2f, %.1f" % (s["calls"], s["median_ms"], s["max_ms"]) if s else "none"
        L.append("| %s (`%s`) | %s | %s |" % (NAMES[k], k, f(b), f(a)))
    if k4:
        L += ["", "| Gate run (after) | Mode | Session | Frame median ms | Frame p99 ms | GPU median ms |", "|---|---|---:|---:|---:|---:|"]
        for r in sorted(k4, key=lambda r: (r["mode"], r["launch"], r["session"])):
            L.append("| %s | %s | %d | %.2f | %.1f | %.2f |" % (r["launch"], r["mode"], r["session"], r["frame_median"], r["frame_p99"], r["gpu_median"]))
    open(os.path.join(docs, "tables.md"), "w").write("\n".join(L) + "\n")
    # the one image: the same session (deaths, launch 1, session 2) before and after
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    pick = lambda rs: [r for r in rs if r["mode"] == "deaths" and r["launch"].endswith("_1") and r["session"] == 2][0]
    fb, fa = frames(pick(before)), frames(pick(after))
    ink, ink2, grid = "#0b0b0b", "#52514e", "#e4e3df"
    fig, ax = plt.subplots(figsize=(8, 4.6), dpi=150)
    fig.patch.set_facecolor("#fcfcfb")
    ax.set_facecolor("#fcfcfb")
    ax.plot([r["i"] for r in fb], [r["frame"] for r in fb], color="#2a78d6", lw=1.2, label="Before")
    ax.plot([r["i"] for r in fa], [r["frame"] for r in fa], color="#eb6834", lw=1.2, label="After")
    ax.axhline(16.7, color=ink2, lw=1, ls=(0, (4, 3)))
    ax.text(719, 17.6, "16.7 ms (60 fps)", ha="right", va="bottom", color=ink2, fontsize=9)
    nb = sum(1 for r in fb if r["frame"] > 16.7)
    na = sum(1 for r in fa if r["frame"] > 16.7)
    ax.set_title("Gate scene, 3 deaths, same session: %d stalls before, %d after" % (nb, na), color=ink, fontsize=12, loc="left")
    ax.set_xlabel("Measured frame", color=ink2, fontsize=9)
    ax.set_ylabel("Frame time (ms)", color=ink2, fontsize=9)
    ax.set_xlim(0, 720)
    ax.set_ylim(0, max(90, max(r["frame"] for r in fb) + 5))
    for s in ["top", "right"]:
        ax.spines[s].set_visible(False)
    for s in ["left", "bottom"]:
        ax.spines[s].set_color(grid)
    ax.tick_params(colors=ink2, labelsize=8)
    ax.grid(axis="y", color=grid, lw=0.6)
    ax.legend(frameon=False, fontsize=9, loc="upper left", bbox_to_anchor=(0.0, 0.98))
    fig.tight_layout()
    fig.savefig(os.path.join(docs, "frames.png"), facecolor=fig.get_facecolor())
    print("\n".join(L))


if __name__ == "__main__":
    main()
