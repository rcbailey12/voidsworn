"""Make camera-170-first shield sheets and measure the rendered A/B probes.

The source images come from shield_bench.tscn and actual BattleAPI units.
Readability uses 12 interior samples and eight silhouette edge pairs,
selected from the shield-off image and the real hull mask before reading lit.
The cap capture uses the production shader, an unlit black hull, linear tone
mapping, exposure 0.02, no bloom, six overlapping hits and over-range tint.
A shader-written reference at the production light cap calibrates the measurement.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FACTIONS = {"voidsworn": "Sunward Crusade", "hegemony": "Hegemony Navy",
            "corsair": "Ashfall Hullbreakers", "ithar": "Glasswrights"}


def linear(rgb):
    return np.where(rgb <= .04045, rgb / 12.92, ((rgb + .055) / 1.055) ** 2.4)


def pixels(path):
    return np.asarray(Image.open(path).convert("RGB"), dtype=float) / 255


def luma(rgb):
    return linear(rgb) @ np.array([.2126, .7152, .0722])


def patch_range(image, x, y):
    values = image[y-3:y+4, x-3:x+4]
    return float(np.max(values) - np.min(values))


def contrast(a, b):
    return float((max(a, b) + .05) / (min(a, b) + .05))


def readability(folder, name):
    off = luma(pixels(folder / f"{name}_off.png"))
    lit = luma(pixels(folder / f"{name}_lit.png"))
    mask = np.min(pixels(folder / f"{name}_hull_mask.png"), axis=2) > .6
    ys, xs = np.where(mask)
    if not len(xs):
        return {"error": "no rendered hull mask"}
    x0, x1, y0, y1 = int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())
    interior = []
    all_candidates = []
    for row in range(3):
        for column in range(4):
            candidates = []
            for y in range(max(4, y0 + (y1-y0)*row//3), min(off.shape[0]-4, y0 + (y1-y0)*(row+1)//3)):
                for x in range(max(4, x0 + (x1-x0)*column//4), min(off.shape[1]-4, x0 + (x1-x0)*(column+1)//4)):
                    if mask[y-3:y+4, x-3:x+4].all():
                        candidates.append((patch_range(off, x, y), x, y))
            all_candidates.extend(candidates)
            if candidates:
                before, x, y = max(candidates)
                after = patch_range(lit, x, y)
                interior.append({"xy": [x, y], "before": before, "after": after,
                                 "retained": after / max(before, 1e-6)})
    for before, x, y in sorted(all_candidates, reverse=True):
        if len(interior) == 12:
            break
        if any((x-s["xy"][0])**2 + (y-s["xy"][1])**2 < 49 for s in interior):
            continue
        after = patch_range(lit, x, y)
        interior.append({"xy": [x, y], "before": before, "after": after,
                         "retained": after / max(before, 1e-6)})
    edge_candidates = []
    for x in range(max(x0, 4), min(x1, off.shape[1]-4)):
        column = np.flatnonzero(mask[:, x])
        if not len(column):
            continue
        for y, sign in [(int(column[0]), -1), (int(column[-1]), 1)]:
            inside_y, outside_y = y - sign * 3, y + sign * 3
            if min(inside_y, outside_y) < 0 or max(inside_y, outside_y) >= off.shape[0]:
                continue
            if not mask[inside_y, x] or mask[outside_y, x]:
                continue
            before = contrast(off[inside_y, x], off[outside_y, x])
            if before >= 1.25:
                edge_candidates.append({"inside": [x, inside_y], "outside": [x, outside_y],
                                        "before": before,
                                        "after": contrast(lit[inside_y, x], lit[outside_y, x])})
    # Eight evenly spaced baseline-qualified edge pairs, independent of lit.
    edge_candidates.sort(key=lambda e: (e["inside"][0], e["inside"][1]))
    edges = [edge_candidates[int((len(edge_candidates)-1)*i/7)] for i in range(8)] if edge_candidates else []
    return {"interior": interior, "edges": edges,
            "interior_kept_30pct": sum(s["retained"] >= .3 for s in interior),
            "edges_at_least_1_25": sum(s["after"] >= 1.25 for s in edges),
            "minimum_edge_contrast": min((s["after"] for s in edges), default=0),
            "pass": len(interior) == 12 and sum(s["retained"] >= .3 for s in interior) >= 9
                    and len(edges) == 8 and all(s["after"] >= 1.25 for s in edges)}


def delta(a, b):
    d = np.max(np.abs(pixels(a) - pixels(b)), axis=2) * 255
    ys, xs = np.where(d > 1)
    return {"changed_pixels_over_1_level": int((d > 1).sum()), "max_levels": float(d.max()),
            "mean_levels": float(d.mean()),
            "changed_bbox": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())] if len(xs) else None}


def font(size):
    try:
        return ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", size)
    except OSError:
        return ImageFont.load_default()


def versions(args, bursts=False):
    return [("MAIN d32713f / installed reference", args.bursts_before if bursts else args.before),
            ("PR855 run 1 89bb41a / in-game bench", args.bursts_previous if bursts else args.previous),
            ("RUN 3 1c2d3868 / in-game bench", args.bursts_run3 if bursts else args.run3),
            ("RUN 4 " + args.revision + " / in-game bench, pending Ryan", args.bursts if bursts else args.after)]


def sheets(args, stats, metadata):
    before, after, out = args.before, args.after, args.out
    for faction, display in FACTIONS.items():
        for camera in [170, 60, 26]:
            sheet = Image.new("RGB", (1200, 720), "#111318")
            draw = ImageDraw.Draw(sheet)
            code = next(r["code"] for r in metadata["captures"] if r["faction"] == faction)
            draw.text((24, 10), f"SH372 / {code} / {display} / camera {camera}", font=font(23), fill="white")
            for column, label in enumerate(["REST: Rim and Gap", "HIT +0.08 s", "FADE +0.42 s"]):
                draw.text((24+column*384, 33), label, font=font(15), fill="white")
            for row, (label, folder) in enumerate(versions(args)):
                y = 56 + row * 166
                strip = Image.open(folder / f"{faction}_c{camera}_strip.png")
                for index, frame in enumerate([0, 2, 5]):
                    # Trim empty vertical margins, keeping camera 170 at true pixel size.
                    sheet.paste(strip.crop((frame*384, 36, (frame+1)*384, 180)), (24+index*384, y+19))
                draw.text((24, y), label, font=font(16), fill="#ffb26d")
            sheet.save(out / f"SH372_{faction}_c{camera}.jpg", quality=94)
    # Same frozen frame with one mechanism removed: visual evidence of the effect itself.
    for faction in ["voidsworn", "hegemony"]:
        sheet = Image.new("RGB", (1200, 660), "#111318")
        draw = ImageDraw.Draw(sheet)
        draw.text((24, 10), f"SH372 / {FACTIONS[faction]} / RUN 4 {args.revision} / in-game bench / c60 +0.42s", font=font(19), fill="white")
        for index, (suffix, label) in enumerate([("no_bend", "Bend OFF"), ("diagnostic", "Production shield"), ("no_contact", "Contact OFF")]):
            im = Image.open(after / f"{faction}_c60_{suffix}.png").resize((384, 288), Image.Resampling.LANCZOS)
            sheet.paste(im, (24+384*index, 72))
            draw.text((24+384*index, 44), label, font=font(18), fill="#ffb26d")
        for index, (suffix, label) in enumerate([("rock_no_contact", "Rock: contact OFF"), ("rock_contact", "Rock: production contact")]):
            im = Image.open(after / f"{faction}_{suffix}.png").resize((384, 288), Image.Resampling.LANCZOS)
            sheet.paste(im, (24+384*index, 372))
            draw.text((24+384*index, 354), label, font=font(16), fill="white")
        sheet.save(out / f"SH372_{faction}_mechanisms.jpg", quality=94)


def main():
    parser = argparse.ArgumentParser()
    for name in ["before", "after", "out"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--bursts", type=Path)
    parser.add_argument("--previous", type=Path, required=True, help="PR 855 run 1 surface captures")
    parser.add_argument("--bursts-before", type=Path)
    parser.add_argument("--bursts-previous", type=Path)
    parser.add_argument("--run3", type=Path, required=True)
    parser.add_argument("--bursts-run3", type=Path)
    parser.add_argument("--phone-main", type=Path)
    parser.add_argument("--phone-run3", type=Path)
    parser.add_argument("--revision", required=True, help="source hash of the uncommitted production files")
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    metadata = json.loads((args.after / "shield_bench.json").read_text())
    ceiling = float(metadata.get("light_cap", .65))
    stats = {"revision": args.revision, "stage": "in-game bench, pending Ryan", "linear_rgb_ceiling": ceiling,
             "readability": {}, "mechanisms": {}, "cap_stress": {}, "hit_strength": {}, "boundary": {}}
    for faction in FACTIONS:
        cap = linear(pixels(args.after / f"{faction}_linear_cap_stress.png"))
        reference = linear(pixels(args.after / f"{faction}_linear_cap_reference.png"))[0, 0]
        measured = cap / np.maximum(reference, 1e-6) * ceiling
        hull = np.min(pixels(args.after / f"{faction}_linear_cap_hull_mask.png"), axis=2) > .6
        interior_mask = np.asarray(Image.fromarray(hull.astype(np.uint8)*255).filter(ImageFilter.MinFilter(7))) > 0
        stats["cap_stress"][faction] = {"max_channel_linear": float(measured.max()),
                                       "max_channel_over_hull_linear": float(measured[interior_mask].max()) if interior_mask.any() else None,
                                       "reference_srgb": pixels(args.after / f"{faction}_linear_cap_reference.png")[0, 0].tolist(),
                                       "cap_met": bool(measured.max() <= ceiling * 1.015)}
        for camera in [170, 60, 26]:
            name = f"{faction}_c{camera}"
            stats["readability"][name] = readability(args.after, name)
            stats["mechanisms"][name] = {key: delta(args.after / f"{name}_diagnostic.png", args.after / f"{name}_no_{key}.png")
                                         for key in ["bend", "contact", "pattern", "pulse", "boundary"]}
            stats["mechanisms"][name]["crackle"] = delta(args.after / f"{name}_lit.png", args.after / f"{name}_no_crackle.png")
            hull = np.min(pixels(args.after / f"{name}_hull_mask.png"), axis=2) > .6
            shell = np.min(pixels(args.after / f"{name}_shell_mask.png"), axis=2) > .6
            outside = shell & ~hull
            off = luma(pixels(args.after / f"{name}_off.png"))
            lit = luma(pixels(args.after / f"{name}_lit.png"))
            stats["boundary"][name] = {"shell_pixels_outside_hull": int(outside.sum()),
                                       "lit_outside_hull_over_002": int((outside & (lit-off > .02)).sum())}
            stats["hit_strength"][name] = {}
            for version, folder in versions(args):
                strip = luma(pixels(folder / f"{name}_strip.png"))
                rest = strip[:, :384]
                light = np.maximum(strip[:, 2*384:3*384] - rest, 0)
                ys, xs = np.where(light > .02)
                stats["hit_strength"][name][version] = {
                    "added_luminance_sum": float(light.sum()),
                    "peak_added_luminance": float(light.max()),
                    "pixels_above_002": int((light > .02).sum()),
                    "flash_width_px": int(xs.max()-xs.min()+1) if len(xs) else 0}
        stats["mechanisms"][faction + "_rock_contact"] = delta(args.after / f"{faction}_rock_contact.png", args.after / f"{faction}_rock_no_contact.png")
    sheets(args, stats, metadata)
    if args.bursts:
        for camera in [170, 60, 26]:
            sheet = Image.new("RGB", (1200, 720), "#111318")
            draw = ImageDraw.Draw(sheet)
            draw.text((24, 10), f"SH372 / V16_37 / same torpedo, same Sunward cruiser / camera {camera}", font=font(22), fill="white")
            if args.bursts_previous:
                for column, label in enumerate(["SHIELD +0.04 s", "SHIELD +0.27 s", "HULL +0.27 s"]):
                    draw.text((24+column*384, 33), label, font=font(15), fill="white")
                for row, (label, folder) in enumerate(versions(args, bursts=True)):
                    y = 56 + row * 166
                    for column, (on, frame) in enumerate([("shield", 2), ("shield", 9), ("hull", 9)]):
                        strip = Image.open(folder / "moments" / f"w_torp_void_{on}__c{camera}.png")
                        sheet.paste(strip.crop((frame*384, 36, (frame+1)*384, 180)), (24+column*384, y+19))
                    draw.text((24, y), label, font=font(16), fill="#ffb26d")
                sheet.save(args.out / f"SH372_hit_pair_c{camera}.jpg", quality=94)
                continue
            for on, label, y in [("shield", "SHIELD: energy discharge", 100), ("hull", "HULL: hot core, gas and thrown matter", 350)]:
                draw.text((24, y-27), label, font=font(18), fill="#ffb26d")
                strip = Image.open(args.bursts / "moments" / f"w_torp_void_{on}__c{camera}.png")
                for index, frame in enumerate([2, 5, 9]):
                    sheet.paste(strip.crop((frame*384, 0, (frame+1)*384, 216)), (24+384*index, y))
            draw.text((24, 576), "Standing look-bench moments; one shot; source pixels at 170, half at 60, third at 26.", font=font(16), fill="white")
            sheet.save(args.out / f"SH372_hit_pair_c{camera}.jpg", quality=94)
    if args.phone_main and args.phone_run3:
        sheet = Image.new("RGB", (1200, 560), "#111318")
        draw = ImageDraw.Draw(sheet)
        draw.text((10, 8), "SH372 / V16_37 / camera 170 / whole 1920x1080 frames reduced to 390 px wide", font=font(21), fill="white")
        for column, (folder, label) in enumerate([(args.phone_main, "MAIN d32713f / installed reference"),
                                                  (args.phone_run3, "RUN 3 1c2d3868 / in-game bench"),
                                                  (args.bursts, "RUN 4 " + args.revision + " / pending Ryan")]):
            x = 10 + column * 400
            draw.text((x, 40), label, font=font(15), fill="#ffb26d")
            for row, on in enumerate(["shield", "hull"]):
                y = 85 + row * 240
                draw.text((x, y-21), on.upper() + " / impact +0.14 s", font=font(16), fill="white")
                frame = Image.open(folder / f"w_torp_void_{on}_c170_frame5.png")
                sheet.paste(frame.resize((390, 219), Image.Resampling.LANCZOS), (x, y))
        sheet.save(args.out / "SH372_hit_pair_phone.jpg", quality=96)
        # Individual phone cards keep the standing 384-pixel camera crop at 1:1.
        # These are labelled crops, separate from the honest full-frame reduction.
        for folder, label, slug in [(args.phone_main, "MAIN d32713f", "main"),
                                     (args.phone_run3, "RUN 3 1c2d3868", "run3"),
                                     (args.bursts, "RUN 4 " + args.revision, "run4")]:
            card = Image.new("RGB", (390, 570), "#111318")
            ink = ImageDraw.Draw(card)
            ink.text((8, 8), "SH372 / V16_37 / camera 170", font=font(21), fill="white")
            ink.text((8, 35), label + " / in-game bench", font=font(16), fill="#ffb26d")
            ink.text((8, 56), "Source pixels; central crop, no enlargement", font=font(16), fill="white")
            for row, on in enumerate(["shield", "hull"]):
                y = 105 + row * 238
                ink.text((8, y-23), on.upper() + " / impact +0.14 s", font=font(18), fill="white")
                strip = Image.open(folder / "moments" / f"w_torp_void_{on}__c170.png")
                card.paste(strip.crop((5*384, 0, 6*384, 216)), (3, y))
            card.save(args.out / f"SH372_hit_pair_phone_{slug}.jpg", quality=96)
    (args.out / "measurements.json").write_text(json.dumps(stats, indent=2) + "\n")
    print(json.dumps({"cap": stats["cap_stress"], "readability": {k: {x: v.get(x) for x in ["pass", "interior_kept_30pct", "minimum_edge_contrast"]} for k, v in stats["readability"].items()}}, indent=2))


if __name__ == "__main__":
    main()
