#!/usr/bin/env python3
"""Issue 207: turn the scene gate benchmark's raw JSON into the summary the report quotes.

    python3 contrib/opus/tools/scene_gate_report.py docs/shots/ship_pipeline/bench207

Reads <dir>/run1.json, run2.json (every mode, 3 sessions each) and run3_res.json (base, res_1440, res_2160) when
present, and the round 4 record (docs/shots/ship_pipeline/pyre_round4/gpu.json). Writes <dir>/summary.json and prints
the tables. Every delta is paired: a mode against the base measured in the same session of the same launch, then the
median over sessions (the sessions alternate their order, so drift spreads evenly).
"""
import json
import os
import statistics as st
import sys

FRAME_60 = 1000.0 / 60.0
PIX_1080 = 1920 * 1080
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


def load(path):
    with open(path) as f:
        return json.load(f)


def med(xs):
    return st.median(xs) if xs else None


def rows_by_mode(runs):
    """{mode: [(run, session, row)]}"""
    out = {}
    for name, d in runs.items():
        for mode, rows in d["modes"].items():
            for r in rows:
                out.setdefault(mode, []).append((name, r["session"], r))
    return out


def summarise(runs):
    by = rows_by_mode(runs)
    base = {(n, s): r for n, s, r in by.get("base", [])}
    summary = {}
    for mode, items in by.items():
        g = [r["gpu_median"] for _, _, r in items]
        f = [r["frame_median"] for _, _, r in items]
        p99 = [r["frame_p99"] for _, _, r in items]
        c = [r["cpu_median"] for _, _, r in items]
        dg, df = [], []
        for n, s, r in items:
            b = base.get((n, s))
            if b is not None and mode != "base":
                dg.append(r["gpu_median"] - b["gpu_median"])
                df.append(r["frame_median"] - b["frame_median"])
        r0 = items[0][2]
        summary[mode] = {
            "sessions": len(items),
            "gpu_ms": med(g), "gpu_min": min(g), "gpu_max": max(g),
            "gpu_spread_pct": 100.0 * (max(g) - min(g)) / med(g) if med(g) else None,
            "gpu_stdev": st.pstdev(g) if len(g) > 1 else 0.0,
            "frame_ms": med(f), "frame_min": min(f), "frame_max": max(f),
            "frame_p99_ms": med(p99), "frame_p99_max": max(p99),
            "render_cpu_ms": med(c),
            "process_ms": med([r["proc_median"] for _, _, r in items]),
            "draw_calls_visible": med([r["dc_vis_median"] for _, _, r in items]),
            "draw_calls_shadow": med([r["dc_sh_median"] for _, _, r in items]),
            "primitives_visible": med([r["prim_vis_median"] for _, _, r in items]),
            "primitives_shadow": med([r["prim_sh_median"] for _, _, r in items]),
            "objects_visible": med([r["obj_vis_median"] for _, _, r in items]),
            "objects_shadow": med([r["obj_sh_median"] for _, _, r in items]),
            "vram_mb": med([r["vram_mb"] for _, _, r in items]),
            "volleys_per_s": med([r["volleys"] / max(1e-6, r["seconds"] + 2.5) for _, _, r in items]) if r0.get("volleys") else 0.0,
            "viewport": r0["viewport"], "scaling_3d": r0["scaling_3d"], "msaa_3d": r0["msaa_3d"],
            "delta_gpu_ms": med(dg), "delta_gpu_min": min(dg) if dg else None, "delta_gpu_max": max(dg) if dg else None,
            "delta_frame_ms": med(df),
        }
    return summary


def round4():
    d = load(os.path.join(REPO, "docs/shots/ship_pipeline/pyre_round4/gpu.json"))
    rows = []
    for r in d["rows"]:
        rows.append({"variant": r["route"], "triangles_per_ship": r["geometry"]["triangles"],
                     "fleet20_gpu_ms": r["fleet"]["gpu_median_ms"], "fleet20_frame_ms": r["fleet"]["frame_median_ms"],
                     "fleet20_draw_calls": r["fleet"]["draw_calls"], "fleet20_render_cpu_ms": r["fleet"]["render_cpu_median_ms"],
                     "single_gpu_ms": r["single"]["gpu_median_ms"], "single_frame_ms": r["single"]["frame_median_ms"],
                     "single_draw_calls": r["single"]["draw_calls"], "single_render_cpu_ms": r["single"]["render_cpu_median_ms"],
                     "scene_triangles": r["geometry"]["triangles"] * 20,
                     "implied_btris_per_s": r["geometry"]["triangles"] * 20 / (r["fleet"]["gpu_median_ms"] / 1000.0) / 1e9})
    keys = set()
    for r in d["rows"]:
        keys |= set(r["fleet"].keys())
    return {"empty": {"gpu_ms": d["blank"]["gpu_median_ms"], "frame_ms": d["blank"]["frame_median_ms"],
                      "render_cpu_ms": d["blank"]["render_cpu_median_ms"], "draw_calls": d["blank"]["draw_calls"]},
            "rows": rows, "fields_retained": sorted(keys),
            "per_pass_or_shadow_timing": [k for k in keys if "shadow" in k or "pass" in k]}


def main():
    folder = sys.argv[1]
    runs = {}
    for n in ["run1", "run2"]:
        p = os.path.join(folder, n + ".json")
        if os.path.exists(p):
            runs[n] = load(p)
    s = summarise(runs)
    res = {}
    p3 = os.path.join(folder, "run3_res.json")
    if os.path.exists(p3):
        res = summarise({"run3": load(p3)})
    scene = runs["run1"]["scene"]
    b = s["base"]
    hull_tris = sum(x["hull_triangles"] for x in scene["ships"])
    ship_tris = sum(x["hull_triangles"] for x in scene["ships"] if x["cls"] != "Squadron")
    out = {"base": b, "modes": s, "res": res, "round4": round4(), "scene": {k: v for k, v in scene.items() if k != "ships"},
           "ships": scene["ships"], "adapter": runs["run1"]["adapter"], "driver": runs["run1"].get("driver"),
           "godot": runs["run1"]["godot"]["string"], "frames": runs["run1"]["measured_frames"],
           "warmup": runs["run1"]["warmup_frames"]}
    d = {}
    d["frame_60_ms"] = FRAME_60
    d["base_gpu_share_of_60"] = b["gpu_ms"] / FRAME_60
    d["base_frame_share_of_60"] = b["frame_ms"] / FRAME_60
    d["headroom_gpu_ms"] = FRAME_60 - b["gpu_ms"]
    d["headroom_frame_ms"] = FRAME_60 - b["frame_ms"]
    d["gpu_bound"] = (b["frame_ms"] - b["gpu_ms"]) / b["frame_ms"]
    d["hull_triangles_scene"] = hull_tris
    d["ship_triangles_scene"] = ship_tris
    if "fleet_x2" in s:
        add = s["fleet_x2"]["delta_gpu_ms"]
        d["fleet_x2_added_ms"] = add
        d["ms_per_hull_copy"] = add / max(1, len(scene["ships"]))
        d["ms_per_million_tris"] = add / (hull_tris / 1e6)
        d["extra_hulls_in_headroom"] = d["headroom_gpu_ms"] / d["ms_per_hull_copy"] if d["ms_per_hull_copy"] > 0 else None
        d["extra_million_tris_in_headroom"] = d["headroom_gpu_ms"] / d["ms_per_million_tris"] if d["ms_per_million_tris"] > 0 else None
    if "half_res" in s:
        # GPU ms = fixed + per-pixel cost x 3D pixels, from the full and quarter-pixel points
        q = s["half_res"]["gpu_ms"]
        per_px = (b["gpu_ms"] - q) / (PIX_1080 * 0.75)
        fixed = b["gpu_ms"] - per_px * PIX_1080
        d["pixel_model"] = {"fixed_ms": fixed, "ms_per_megapixel": per_px * 1e6,
                            "pixel_share_at_1080": per_px * PIX_1080 / b["gpu_ms"],
                            "predicted_1440_ms": fixed + per_px * 2560 * 1440,
                            "predicted_2160_ms": fixed + per_px * 3840 * 2160}
    out["derived"] = d
    with open(os.path.join(folder, "summary.json"), "w") as f:
        json.dump(out, f, indent=2)
        f.write("\n")
    order = ["base", "shadows_off", "msaa_2x", "msaa_off", "fx_off", "post_off", "hud_off", "world_off", "ships_off",
             "half_res", "fleet_x2", "deaths", "floor"]
    print("%-12s %7s %7s %7s %7s %6s %8s %6s %6s %10s %10s" % ("mode", "gpu", "dgpu", "frame", "p99", "cpu", "spread%",
                                                          "dcV", "dcS", "primV", "primS"))
    for m in order + [k for k in s if k not in order]:
        if m not in s:
            continue
        x = s[m]
        print("%-12s %7.3f %7s %7.3f %7.3f %6.3f %8.1f %6.0f %6.0f %10.0f %10.0f" % (
            m, x["gpu_ms"], "" if x["delta_gpu_ms"] is None else "%+.3f" % x["delta_gpu_ms"], x["frame_ms"],
            x["frame_p99_ms"], x["render_cpu_ms"], x["gpu_spread_pct"], x["draw_calls_visible"], x["draw_calls_shadow"],
            x["primitives_visible"], x["primitives_shadow"]))
    for m, x in res.items():
        print("res %-8s gpu %.3f d %s frame %.3f p99 %.3f" % (m, x["gpu_ms"], x["delta_gpu_ms"], x["frame_ms"], x["frame_p99_ms"]))
    print(json.dumps(d, indent=1))


if __name__ == "__main__":
    main()
