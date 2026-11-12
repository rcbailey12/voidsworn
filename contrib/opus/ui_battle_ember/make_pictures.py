#!/usr/bin/env python3
"""Issue 271 step 1: turn the PC captures into the pictures for Ryan and the readability numbers.

Usage: python3 make_pictures.py <capture folder> <repo root>
Reads, from the capture folder (ember_shots.gd): before_lime.png, <L>_main.png, <L>_S*.png, <L>_prompt.png,
<L>_bg0..5.png and <L>_items.json for L in E1, E2, E3.
Writes docs/shots/ui_battle_ember/ (named pictures, none taller than 720 px, plus true-size crops and the full 1080 frames)
and docs/shots/ui_battle_ember/readability.json.

The readability checks are the rail spec's (contrib/opus/briefs/campaign_rail_orders_sheet.md), at 1080:
- nothing below 17 px; Big Shoulders never below 28;
- three text strengths (TEXT, TEXT2, TEXT3), TEXT3 only for joining words;
- contrast 4.5 to 1 or better for every word, measured as the WORST pixel under the word's box on the brightest and the
  darkest of six backgrounds (the same veils with no words, the camera turned through a full circle about the same point);
- no word box overlaps another.
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont
import numpy as np

LAYOUTS = {"E1": "LEDGER", "E2": "CROSSING", "E3": "FOOTING"}
SHIELDS = [("S1_cyan", "Cyan", "#3fcbe0"), ("S2_glacier", "Glacier", "#92b8e8"), ("S3_verdigris", "Verdigris", "#63c3a0")]
STRENGTH = {"f0eade": "TEXT", "c4beb0": "TEXT2", "969084": "TEXT3"}

# the selected ship's block in each layout, at 1080 (x0, y0, x1, y1): name, class, hull, shields, guns
PANEL = {"E1": (24, 100, 660, 500), "E2": (24, 100, 540, 490), "E3": (24, 770, 1140, 1064)}


def lum(rgb):
    c = np.asarray(rgb, dtype=np.float64) / 255.0
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[..., 0] + 0.7152 * c[..., 1] + 0.0722 * c[..., 2]


def hex_rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def font(repo, size, name="BigShouldersDisplay-VF.ttf"):
    p = os.path.join(repo, "godot/ui/theme/fonts", name)
    f = ImageFont.truetype(p, size)
    try:
        f.set_variation_by_axes([800])
    except Exception:
        pass
    return f


def label(img, text, repo, scale_note=""):
    """Put the code name on a plain dark strip under the picture (never over it)."""
    W, H = img.size
    out = Image.new("RGB", (W, H + 44), (8, 8, 8))
    out.paste(img, (0, 0))
    d = ImageDraw.Draw(out)
    f = font(repo, 30)
    d.text((16, H + 5), text, font=f, fill=(255, 138, 58))
    return out


def small(img, h=720):
    w = round(img.width * h / img.height)
    return img.resize((w, h), Image.LANCZOS)


def main():
    cap, repo = sys.argv[1], sys.argv[2]
    dst = os.path.join(repo, "docs/shots/ui_battle_ember")
    os.makedirs(os.path.join(dst, "full_1080"), exist_ok=True)
    report = {}
    before = Image.open(os.path.join(cap, "before_lime.png")).convert("RGB")
    before.save(os.path.join(dst, "full_1080", "before_lime_1080.jpg"), quality=93)
    label(small(before, 676), "BEFORE: LIME (today)", repo).save(os.path.join(dst, "before_lime.jpg"), quality=92)
    for L, code in LAYOUTS.items():
        main_p = os.path.join(cap, f"{L}_main.png")
        if not os.path.exists(main_p):
            continue
        frame = Image.open(main_p).convert("RGB")
        assert frame.size == (1920, 1080), f"{L} frame is {frame.size}, not 1920x1080"
        frame.save(os.path.join(dst, "full_1080", f"{L}_{code.lower()}_1080.png"), optimize=True)
        label(small(frame, 676), f"{L} {code}", repo).save(os.path.join(dst, f"{L}_{code.lower()}.jpg"), quality=92)
        pr = Image.open(os.path.join(cap, f"{L}_prompt.png")).convert("RGB")
        pr.save(os.path.join(dst, "full_1080", f"{L}_{code.lower()}_prompt_1080.jpg"), quality=93)
        label(small(pr, 676), f"{L} {code}: TREE PROMPT", repo).save(os.path.join(dst, f"{L}_{code.lower()}_prompt.jpg"), quality=92)
        # the selected ship's panel at true size
        box = PANEL[L]
        crop = frame.crop(box)
        label(crop.copy(), f"{L} {code}: SHIP, TRUE SIZE", repo).save(os.path.join(dst, f"{L}_{code.lower()}_panel_true.png"), optimize=True)
        # the three shield colours side by side, true size, each crop the same box
        crops = [Image.open(os.path.join(cap, f"{L}_{s}.png")).convert("RGB").crop(box) for s, _, _ in SHIELDS]
        cw, chh = crops[0].size
        sheet = Image.new("RGB", (cw * 3 + 40, chh + 60), (8, 8, 8))
        d = ImageDraw.Draw(sheet)
        fb = font(repo, 26, "Barlow-Medium.ttf")
        for i, (c, (_, nm, hx)) in enumerate(zip(crops, SHIELDS)):
            sheet.paste(c, (i * (cw + 20), 60))
            d.text((i * (cw + 20) + 20, 16), f"{nm} {hx}", font=fb, fill=tuple(hex_rgb(hx)))
        if sheet.height > 676:
            sheet = small(sheet, 676)
        label(sheet, f"{L} {code}: SHIELD COLOURS", repo).save(os.path.join(dst, f"{L}_{code.lower()}_shields.png"), optimize=True)

        # readability
        J = json.load(open(os.path.join(cap, f"{L}_items.json")))
        items = [it for it in J["items"] if it.get("role") != "tag"]
        tags = [it for it in J["items"] if it.get("role") == "tag"]
        bgs = [np.asarray(Image.open(os.path.join(cap, f"{L}_bg{i}.png")).convert("RGB")) for i in range(6)]
        mask = np.zeros((1080, 1920), bool)
        for it in items:
            x0, y0 = max(0, int(it["x"])), max(0, int(it["y"]))
            x1, y1 = min(1920, int(it["x"] + it["w"]) + 1), min(1080, int(it["y"] + it["h"]) + 1)
            mask[y0:y1, x0:x1] = True
        means = [float(lum(b)[mask].mean()) for b in bgs]
        bright, dark = int(np.argmax(means)), int(np.argmin(means))
        rows = []
        worst = None
        for it in items:
            x0, y0 = max(0, int(it["x"])), max(0, int(it["y"]))
            x1, y1 = min(1920, int(it["x"] + it["w"]) + 1), min(1080, int(it["y"] + it["h"]) + 1)
            lt = float(lum(np.array(hex_rgb(it["col"]))))
            res = {}
            for nm, bi in (("bright", bright), ("dark", dark)):
                region = lum(bgs[bi][y0:y1, x0:x1]).ravel()
                if region.size == 0:
                    continue
                lb_max = float(region.max())
                lb_p99 = float(np.percentile(region, 99))
                res[nm] = {"worst": round((max(lt, lb_max) + 0.05) / (min(lt, lb_max) + 0.05), 2),
                           "p99": round((max(lt, lb_p99) + 0.05) / (min(lt, lb_p99) + 0.05), 2)}
            c = min(v["worst"] for v in res.values())
            row = {"t": it["t"], "size": it["size"], "face": it["face"], "col": it["col"], "strength": STRENGTH.get(it["col"], it["col"]), "contrast": res, "min_worst": c}
            rows.append(row)
            if worst is None or c < worst["min_worst"]:
                worst = row
        sizes = [it["size"] for it in items]
        bs = [it["size"] for it in items if it["face"] == "BigShoulders"]
        strengths = sorted({STRENGTH[it["col"]] for it in items if it["col"] in STRENGTH})
        overlaps = []
        for i in range(len(items)):
            a = items[i]
            for j in range(i + 1, len(items)):
                c = items[j]
                if a["x"] + 1 < c["x"] + c["w"] - 1 and c["x"] + 1 < a["x"] + a["w"] - 1 and a["y"] + 1 < c["y"] + c["h"] - 1 and c["y"] + 1 < a["y"] + a["h"] - 1:
                    overlaps.append([a["t"], c["t"]])
        # the prompt frame: the same size and overlap checks on its words
        pp = os.path.join(cap, f"{L}_prompt_items.json")
        if os.path.exists(pp):
            pit = [it for it in json.load(open(pp))["items"] if it.get("role") != "tag"]
            for i in range(len(pit)):
                a = pit[i]
                for j in range(i + 1, len(pit)):
                    c = pit[j]
                    if a["x"] + 1 < c["x"] + c["w"] - 1 and c["x"] + 1 < a["x"] + a["w"] - 1 and a["y"] + 1 < c["y"] + c["h"] - 1 and c["y"] + 1 < a["y"] + a["h"] - 1:
                        overlaps.append(["prompt frame", a["t"], c["t"]])
            sizes += [it["size"] for it in pit]
        fails = [r for r in rows if r["min_worst"] < 4.5]
        report[L] = {
            "code": code, "words": len(items), "board_tags": [t["t"] for t in tags],
            "smallest_px": min(sizes), "smallest_big_shoulders_px": min(bs) if bs else None,
            "strengths": strengths, "brightest_bg": f"{L}_bg{bright}.png (mean luminance {means[bright]:.4f})",
            "darkest_bg": f"{L}_bg{dark}.png (mean luminance {means[dark]:.4f})",
            "lowest_contrast": {"word": worst["t"], "strength": worst["strength"], "ratio": worst["min_worst"]},
            "under_4_5": [[r["t"], r["min_worst"]] for r in fails], "overlaps": overlaps,
            "pass": min(sizes) >= 17 and (not bs or min(bs) >= 28) and not fails and not overlaps,
            "words_detail": rows,
        }
        print(f"{L} {code}: {len(items)} words, smallest {min(sizes)} px, Big Shoulders from {min(bs) if bs else '-'} px, "
              f"strengths {strengths}, lowest contrast {worst['min_worst']} ({worst['t']!r}, {worst['strength']}), "
              f"under 4.5: {len(fails)}, overlaps: {len(overlaps)}")
        for f in fails:
            print("   low:", f["t"], f["min_worst"], f["strength"])
        for o in overlaps:
            print("   overlap:", o)
    json.dump(report, open(os.path.join(dst, "readability.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
