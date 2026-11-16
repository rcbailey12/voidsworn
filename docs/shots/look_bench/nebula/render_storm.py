"""Issue 368 run 3: real storm before/after sheets and native hull measurements.

python render_storm.py --before DIR --after DIR --output DIR [--repo-output DIR]
Inputs are storm_capture.tscn outputs. No image is sharpened or enlarged.
"""
import argparse
import json
import statistics
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

BG = "#10141c"
INK = "#e5e9f0"


def text(sheet, xy, value, size=19):
    ImageDraw.Draw(sheet).text(xy, value, fill=INK, font=ImageFont.truetype("C:/Windows/Fonts/arial.ttf", size))


def read(folder, name):
    return Image.open(folder / name).convert("RGB")


def fit(sheet, im, xy, size):
    im = im.copy()
    im.thumbnail(size, Image.Resampling.LANCZOS)
    sheet.paste(im, xy)


def pair(before, after, name, title):
    sheet = Image.new("RGB", (1280, 720), BG)
    text(sheet, (16, 10), title, 23)
    for x, root, caption in [(8, before, "BEFORE | PR 717"), (648, after, "AFTER | R282 CHARGED CLOUD")]:
        text(sheet, (x + 8, 52), caption)
        im = read(root, name)
        fit(sheet, im, (x, 84), (624, 351))
        # Native 1080p pixels, same fixed center, no enlargement.
        w, h = im.size
        crop = im.crop((w // 2 - 304, h // 2 - 118, w // 2 + 304, h // 2 + 118))
        sheet.paste(crop, (x + 8, 466))
    text(sheet, (16, 440), "Native center pixels below | real generated ships | same camera and class scale", 17)
    return sheet


def hull_stats(root, radius):
    prefix = f"storm_fog_c{radius}_4k"
    gas = np.asarray(read(root, prefix + ".png"), dtype=float)
    clear = np.asarray(read(root, prefix + "_clear.png"), dtype=float)
    mask = np.asarray(read(root, prefix + "_mask.png")).min(axis=2) > 240
    # Exclude raster edges, whose background coverage changes with the cloud.
    for _ in range(2):
        mask = mask & np.roll(mask, 1, 0) & np.roll(mask, -1, 0) & np.roll(mask, 1, 1) & np.roll(mask, -1, 1)
    if mask.sum() < 100:
        raise ValueError(f"Too few actual hull pixels: {root} camera {radius}")
    weights = np.array([0.2126, 0.7152, 0.0722])
    g, c = gas[mask] @ weights, clear[mask] @ weights
    ys, xs = np.where(mask)
    return {"pixels": int(mask.sum()), "contrast_ratio": float(g.std() / c.std()),
            "mean_luma_delta_255": float((g - c).mean()),
            "p95_abs_rgb_delta_255": float(np.percentile(abs(gas[mask] - clear[mask]), 95)),
            "hull_box": [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]}


def native_sheet(before, after, radius, stats):
    sheet = Image.new("RGB", (1280, 720), BG)
    text(sheet, (16, 10), f"N368A | STORM | C{radius} | NATIVE 4K HULL PIXELS", 23)
    for row, (root, key) in enumerate([(before, "before"), (after, "after")]):
        y = 90 + row * 302
        box = stats[key][str(radius)]["hull_box"]
        cx, cy = (box[0] + box[2]) // 2, (box[1] + box[3]) // 2
        crop = (cx - 300, cy - 110, cx + 300, cy + 110)
        text(sheet, (16, y - 38), f"{key.upper()} | GAS ON", 20)
        text(sheet, (656, y - 38), "SAME HULL | GAS HIDDEN", 20)
        for x, tail in [(16, ".png"), (656, "_clear.png")]:
            sheet.paste(read(root, f"storm_fog_c{radius}_4k" + tail).crop(crop), (x, y))
        value = stats[key][str(radius)]
        text(sheet, (16, y + 229), f"Hull contrast {value['contrast_ratio']:.4f} of clear | p95 RGB difference {value['p95_abs_rgb_delta_255']:.1f}/255", 18)
    return sheet


def charge_stats(root, radius):
    off = np.asarray(read(root, f"storm_fog_c{radius}_charge_off.png"), dtype=float)
    on = np.asarray(read(root, f"storm_fog_c{radius}_charge_on.png"), dtype=float)
    mask = np.asarray(read(root, f"storm_fog_c{radius}_charge_mask.png")).min(axis=2) > 240
    for _ in range(2):
        mask = mask & np.roll(mask, 1, 0) & np.roll(mask, -1, 0) & np.roll(mask, 1, 1) & np.roll(mask, -1, 1)
    delta = (on - off) @ np.array([0.2126, 0.7152, 0.0722])
    return {"hull_mean_luma_delta_255": float(delta[mask].mean()),
            "hull_p95_luma_delta_255": float(np.percentile(delta[mask], 95)),
            "scene_changed_pixels": int((abs(on - off).max(axis=2) > 1).sum()),
            "hull_pixels": int(mask.sum())}


def light_sheet(root, stats):
    sheet = Image.new("RGB", (1280, 720), BG)
    text(sheet, (16, 10), "N368A | STORM LIGHT | C60 | RIBBONS HIDDEN", 23)
    box = stats["after"]["60"]["hull_box"]
    cx, cy = (box[0] + box[2]) // 2, (box[1] + box[3]) // 2
    for x, state in [(8, "off"), (648, "on")]:
        text(sheet, (x + 8, 52), "LIGHT " + state.upper())
        im = read(root, f"storm_fog_c60_charge_{state}.png")
        fit(sheet, im, (x, 84), (624, 351))
        sheet.paste(im.crop((cx - 300, cy - 110, cx + 300, cy + 110)), (x + 8, 466))
    text(sheet, (16, 440), "Native 4K hull pixels | same pose and gas | no ribbons in either frame", 17)
    text(sheet, (16, 694), f"Hull flicker mean {stats['charge_after']['60']['hull_mean_luma_delta_255']:.2f}/255 | actual fog scattering changes {stats['fog_scattering_changed_pixels']} pixels", 17)
    return sheet


def tier_sheet(root, maximum):
    sheet = Image.new("RGB", (1280, 720), BG)
    text(sheet, (16, 10), "N368A | ION STORM | QUALITY FALLBACKS", 23)
    for x, tier, folder in [(8, "MAX | VOLUME + CARDS", maximum),
                             (432, "HIGH | CARDS", root / "run3_after_high_keep"),
                             (856, "LOW | CARDS", root / "run3_after_low_keep")]:
        text(sheet, (x + 4, 55), tier, 18)
        for y, radius in [(88, 170), (402, 60)]:
            text(sheet, (x + 4, y - 4), f"Camera {radius}", 17)
            fit(sheet, read(folder, f"storm_fog_c{radius}.png"), (x, y + 24), (416, 234))
    text(sheet, (16, 692), "Same generated storm map | max uses 3 fog volumes | high and low use none (CPU geometry check)", 17)
    return sheet


def gate_summary(root):
    summary = {"gate_ms": 12.5, "rows": {}, "all_pass": True}
    reports = []
    for tier, folder, sessions in [("before", "run3_gate_before_keep", 3),
                                    ("max", "run3_gate_max_keep", 3),
                                    ("high", "run3_gate_high_keep", 1),
                                    ("low", "run3_gate_low_keep", 1)]:
        data = json.loads((root / folder / "scene_gate.json").read_text())
        reports.append(data)
        base, four_k = data["modes"]["base"], data["modes"]["res_2160"]
        if len(base) != sessions or len(four_k) != sessions:
            raise ValueError(f"Incomplete timing batch: {folder}")
        row = {"sessions": sessions, "frames_per_mode": data["measured_frames"],
               "frame_1080p_ms": statistics.median(r["frame_median"] for r in base),
               "gpu_4k_ms": statistics.median(r["gpu_median"] for r in four_k),
               "base_visible_draw_calls": statistics.median(r["dc_vis_median"] for r in base),
               "base_visible_primitives": statistics.median(r["prim_vis_median"] for r in base),
               "base_shadow_draw_calls": statistics.median(r["dc_sh_median"] for r in base),
               "base_shadow_primitives": statistics.median(r["prim_sh_median"] for r in base),
               "frame_sessions_ms": [r["frame_median"] for r in base],
               "gpu_sessions_ms": [r["gpu_median"] for r in four_k],
               "all_sessions_pass": all(r["gate_pass"] for r in base + four_k),
               "source": folder + "/scene_gate.json"}
        summary["rows"][tier] = row
        summary["all_pass"] &= row["all_sessions_pass"]
    for key in ["adapter", "renderer", "probe_sha256", "adapter_sha256"]:
        values = {r[key] for r in reports}
        if len(values) != 1: raise ValueError(f"Timing inputs differ: {key}")
        summary[key] = values.pop()
    return summary


def main():
    parser = argparse.ArgumentParser()
    for key in ["before", "after", "output"]: parser.add_argument("--" + key, required=True, type=Path)
    parser.add_argument("--repo-output", type=Path)
    parser.add_argument("--tiers", action="store_true")
    parser.add_argument("--measurements", action="store_true")
    args = parser.parse_args()
    outputs = [args.output] + ([args.repo_output] if args.repo_output else [])
    for root in outputs: root.mkdir(parents=True, exist_ok=True)
    stats = {label: {str(r): hull_stats(root, r) for r in [170, 60]} for root, label in [(args.before, "before"), (args.after, "after")]}
    stats["charge_after"] = {str(r): charge_stats(args.after, r) for r in [170, 60]}
    scatter_off = np.asarray(read(args.after, "storm_fog_c60_scattering_off.png"), dtype=float)
    scatter_on = np.asarray(read(args.after, "storm_fog_c60_scattering_on.png"), dtype=float)
    stats["fog_scattering_changed_pixels"] = int((abs(scatter_on - scatter_off).max(axis=2) > 1).sum())
    artifacts = {}
    artifacts["N368A_storm_light_c60.jpg"] = light_sheet(args.after, stats)
    if args.tiers: artifacts["N368A_storm_run3_tiers.jpg"] = tier_sheet(args.output, args.after)
    for radius in [170, 60]:
        artifacts[f"N368A_storm_c{radius}_before_after.jpg"] = pair(args.before, args.after,
            f"storm_fog_c{radius}.png", f"N368A | ION STORM | CAMERA {radius} | BEFORE / AFTER")
        artifacts[f"N368A_storm_c{radius}_native_4k.png"] = native_sheet(args.before, args.after, radius, stats)
    metadata = json.loads((args.after / "scale_metadata.json").read_text())
    for ship in metadata["ships"]:
        cls = ship["class"].lower().replace(" ", "_")
        for radius in [170, 60]:
            artifacts[f"N368A_storm_scale_{cls}_c{radius}.jpg"] = pair(args.before, args.after,
                f"scale_storm_fog_{cls}_c{radius}.png",
                f"N368A | STORM | {ship['class']} ({ship['code']}) | C{radius} | {ship['length']:.2f} units")
    for name, sheet in artifacts.items():
        for root in outputs:
            sheet.save(root / name, **({"quality": 90} if name.endswith(".jpg") else {}))
    for root in outputs: (root / "storm_readability.json").write_text(json.dumps(stats, indent=2) + "\n")
    if args.measurements:
        gates = gate_summary(args.output)
        for root in outputs: (root / "storm_gate_summary.json").write_text(json.dumps(gates, indent=2) + "\n")
        if not gates["all_pass"]: raise ValueError("A storm timing session exceeds 12.5 ms")
    frames = []
    for path in sorted(args.after.glob("storm_fog_c170_motion_*.png")):
        canvas = Image.new("RGB", (960, 580), BG)
        fit(canvas, Image.open(path), (0, 40), (960, 540))
        text(canvas, (12, 10), "N368A | C170 | fixed flash envelope study | 30 fps", 20)
        frames.append(canvas)
    if frames:
        frames[0].save(args.output / "N368A_storm_motion.gif", save_all=True, append_images=frames[1:], duration=33, loop=0)
    print(json.dumps(stats, indent=2))
    print(f"Wrote {len(artifacts)} sheets, all 1280x720. Motion stays in the shared evidence folder.")


if __name__ == "__main__": main()
