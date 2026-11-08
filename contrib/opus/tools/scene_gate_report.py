#!/usr/bin/env python3
"""Issue 207: turn the scene gate benchmark's raw JSON into the summary the report quotes.

    python3 contrib/opus/tools/scene_gate_report.py docs/shots/ship_pipeline/bench207

Reads <dir>/run2.json and run4.json (the gate view, engagement camera: every mode, 3 sessions each), run1.json (the
turn-start camera), run3_res.json (base, res_1440, res_2160 at the engagement camera) and the round 4 record
(docs/shots/ship_pipeline/pyre_round4/gpu.json). Writes <dir>/summary.json and <dir>/tables.md and prints them. Every delta is paired: a mode against the base measured in the same session of the same launch, then the
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


ORDER = ["base", "shadows_off", "msaa_2x", "msaa_off", "fx_off", "post_off", "hud_off", "world_off", "ships_off",
         "half_res", "fleet_x2", "deaths", "floor", "res_1440", "res_2160"]
LABEL = {"base": "Base (everything on)", "shadows_off": "Shadows off", "msaa_2x": "MSAA 2x", "msaa_off": "MSAA off",
         "fx_off": "Effects off", "post_off": "Post off (SSAO, SSIL, glow)", "hud_off": "HUD off",
         "world_off": "World off (planet, rocks, clouds)", "ships_off": "Ships hidden", "half_res": "3D at half size (quarter pixels)",
         "fleet_x2": "Fleet x2 (a copy of every hull)", "deaths": "Three deaths during the frames", "floor": "Floor (board and sky only)",
         "res_1440": "3D at 2560x1440", "res_2160": "3D at 3840x2160"}


def derive(s, scene):
    b = s["base"]
    hull_tris = sum(x["hull_triangles"] for x in scene["ships"])
    d = {"frame_60_ms": FRAME_60, "base_gpu_share_of_60": b["gpu_ms"] / FRAME_60,
         "base_frame_share_of_60": b["frame_ms"] / FRAME_60, "headroom_gpu_ms": FRAME_60 - b["gpu_ms"],
         "headroom_frame_ms": FRAME_60 - b["frame_ms"], "cpu_over_gpu_ms": b["frame_ms"] - b["gpu_ms"],
         "hull_triangles_scene": hull_tris, "hull_copies": len(scene["ships"])}
    if "fleet_x2" in s:
        add = s["fleet_x2"]["delta_gpu_ms"]
        d["fleet_x2_added_gpu_ms"] = add
        d["fleet_x2_added_frame_ms"] = s["fleet_x2"]["delta_frame_ms"]
        d["gpu_ms_per_hull_copy"] = add / max(1, len(scene["ships"]))
        d["frame_ms_per_hull_copy"] = s["fleet_x2"]["delta_frame_ms"] / max(1, len(scene["ships"]))
        d["gpu_ms_per_million_tris"] = add / (hull_tris / 1e6)
    if "half_res" in s:
        q = s["half_res"]["gpu_ms"]
        per_px = (b["gpu_ms"] - q) / (PIX_1080 * 0.75)
        fixed = b["gpu_ms"] - per_px * PIX_1080
        d["pixel_model"] = {"fixed_ms": fixed, "ms_per_megapixel": per_px * 1e6,
                            "pixel_share_at_1080": per_px * PIX_1080 / b["gpu_ms"],
                            "predicted_1440_ms": fixed + per_px * 2560 * 1440,
                            "predicted_2160_ms": fixed + per_px * 3840 * 2160}
    return d


def table(s, ref=None):
    lines = ["| Run | GPU ms | GPU change | Frame median ms | Frame change | Frame p99 ms | Render CPU ms | Draw calls (view + shadow) | Triangles drawn (view + shadow) | Sessions, GPU spread |",
             "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for m in ORDER:
        if m not in s:
            continue
        x = s[m]
        dg = "" if x["delta_gpu_ms"] is None else "%+.2f" % x["delta_gpu_ms"]
        dfr = "" if x["delta_frame_ms"] is None else "%+.2f" % x["delta_frame_ms"]
        lines.append("| %s | %.2f | %s | %.2f | %s | %.1f | %.2f | %d + %d | %.2fM + %.2fM | %d, %.1f%% |" % (
            LABEL.get(m, m), x["gpu_ms"], dg, x["frame_ms"], dfr, x["frame_p99_ms"], x["render_cpu_ms"],
            x["draw_calls_visible"], x["draw_calls_shadow"], x["primitives_visible"] / 1e6, x["primitives_shadow"] / 1e6,
            x["sessions"], x["gpu_spread_pct"]))
    return "\n".join(lines)


def main():
    folder = sys.argv[1]
    sets = {"engagement": ["run2", "run4"], "turn": ["run1"], "res": ["run3_res"]}
    out = {"round4": round4()}
    for name, files in sets.items():
        runs = {}
        for n in files:
            p = os.path.join(folder, n + ".json")
            if os.path.exists(p):
                runs[n] = load(p)
        if not runs:
            continue
        s = summarise(runs)
        first = runs[files[0]] if files[0] in runs else list(runs.values())[0]
        out[name] = {"runs": sorted(runs), "modes": s, "camera": first.get("camera"),
                     "adapter": first["adapter"], "driver": first.get("driver"), "godot": first["godot"]["string"],
                     "frames": first["measured_frames"], "warmup": first["warmup_frames"]}
        if "scene" in first:
            out[name]["scene"] = {k: v for k, v in first["scene"].items() if k != "ships"}
            out[name]["ships"] = first["scene"]["ships"]
            if "base" in s:
                out[name]["derived"] = derive(s, first["scene"])
    with open(os.path.join(folder, "summary.json"), "w") as f:
        json.dump(out, f, indent=2)
        f.write("\n")
    md = []
    for name in ["engagement", "turn", "res"]:
        if name in out:
            md.append("### %s (%s)\n\n%s\n" % (name, ", ".join(out[name]["runs"]), table(out[name]["modes"])))
    with open(os.path.join(folder, "tables.md"), "w") as f:
        f.write("\n".join(md))
    for name in ["engagement", "turn", "res"]:
        if name in out:
            print("==", name, out[name]["runs"])
            print(table(out[name]["modes"]))
            if "derived" in out[name]:
                print(json.dumps(out[name]["derived"], indent=1))


if __name__ == "__main__":
    main()
