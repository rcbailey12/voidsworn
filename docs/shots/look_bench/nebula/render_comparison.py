"""Compose issue 368's measured route sheet from real Godot captures.

python render_comparison.py --source PATH_TO_ISSUE_368_SHOTS
Keeps native captures in that shared folder. Never invents missing timings.
"""
import argparse
import json
import statistics
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROUTES = ("today", "fog", "cards")
NAMES = ("TODAY", "A: FOG + EDGE CARDS", "B: DENSER CARDS")
MAPS = ("nebula", "storm")
CAMERAS = (170, 60, 26)
HERE = Path(__file__).resolve().parent
BG = "#10141c"
INK = "#e5e9f0"
MUTED = "#a6b1c2"


def font(size):
    return ImageFont.truetype("C:/Windows/Fonts/arial.ttf", size)


def label(draw, xy, value, size=16, fill=INK):
    draw.text(xy, str(value), fill=fill, font=font(size))


def capture(source, case, route, camera):
    path = source / f"{case}_{route}_captures" / f"{case}_{route}_c{camera}.png"
    return Image.open(path).convert("RGB")


def paste_fit(sheet, image, box):
    x, y, w, h = box
    image = image.copy()
    image.thumbnail((w, h), Image.Resampling.LANCZOS)
    sheet.paste(image, (x + (w - image.width) // 2, y + (h - image.height) // 2))


def measured(source):
    rows = []
    for case in MAPS:
        baseline = None
        for route in ROUTES:
            suffix = "keep" if route == "today" else "final_keep"
            path = source / f"{case}_{route}_{suffix}" / "scene_gate.json"
            raw = json.loads(path.read_text(encoding="utf-8"))
            base = raw["modes"]["base"]
            four_k = raw["modes"]["res_2160"]
            assert len(base) == len(four_k) == 3, path
            assert raw["renderer"] == "forward_plus", path
            assert raw["measured_frames"] == 720 and raw["warmup_frames"] == 120, path
            assert all(r["scaling_3d"] == 2 for r in four_k), path
            assert all(r["viewport"] == [1920, 1080] for r in base + four_k), path
            assert all(r["gpu_median"] > 0 and r["frame_median"] > 0 for r in base + four_k), path
            frame = statistics.median(r["frame_median"] for r in base)
            gpu = statistics.median(r["gpu_median"] for r in four_k)
            if route == "today":
                baseline = (frame, gpu)
            row = {
                "map": case, "route": route, "frame_1080p_ms": frame, "gpu_4k_ms": gpu,
                "frame_delta_ms": frame - baseline[0], "gpu_delta_ms": gpu - baseline[1],
                "gate_ms": 12.5, "gate_pass": frame <= 12.5 and gpu <= 12.5,
                "frame_sessions": [r["frame_median"] for r in base],
                "gpu_sessions": [r["gpu_median"] for r in four_k],
                "draw_calls": statistics.median(r["dc_vis_median"] for r in base),
                "visible_primitives": statistics.median(r["prim_vis_median"] for r in base),
                "vram_mb": statistics.median(r["vram_mb"] for r in four_k),
                "patches": base[0]["patches"], "camera": base[0]["camera"],
                "adapter": raw["adapter"], "source": str(path),
                "adapter_sha256": raw["adapter_sha256"], "gate_sha256": raw["probe_sha256"],
            }
            rows.append(row)
    return rows


def validate_capture_poses(source):
    for case in MAPS:
        for route in ROUTES:
            folder = source / f"{case}_{route}_captures"
            records = json.loads((folder / "capture_poses.json").read_text())
            poses = {r["file"]: r for r in records}
            for camera in CAMERAS:
                stem = f"{case}_{route}_c{camera}_4k"
                gas, clear = poses[stem + ".png"], poses[stem + "_clear.png"]
                assert gas["target"] == clear["target"], (case, route, camera)
                for row in (gas, clear):
                    assert row["radius"] == camera and row["screen_shift"] == 0, row
                    assert row["viewport"] == [3840, 2160], row
                    assert abs(row["subject_screen"][0] - 1920) < 0.05, row
                    assert abs(row["subject_screen"][1] - 1080) < 0.05, row
                assert clear["gas_nodes_hidden"] > 0, clear


def overview(source, rows):
    sheet = Image.new("RGB", (1280, 720), BG)
    draw = ImageDraw.Draw(sheet)
    label(draw, (14, 8), "N368 | ROUTE COMPARISON | MAX | RTX 5080", 22)
    label(draw, (14, 36), "Step 1 prototypes. Same real cruiser and fixed clock. Pick the route before final scale and polish.", 15, MUTED)
    for col, (route, name) in enumerate(zip(ROUTES, NAMES)):
        x = 8 + col * 426
        label(draw, (x + 6, 63), name, 18)
        for row_index, case in enumerate(MAPS):
            y = 90 + row_index * 270
            label(draw, (x + 6, y), f"{case.upper()} | CAMERA 170", 15)
            # Full default-camera image first; the near views sit below it.
            paste_fit(sheet, capture(source, case, route, 170), (x + 4, y + 20, 414, 133))
            for j, camera in enumerate((60, 26)):
                paste_fit(sheet, capture(source, case, route, camera), (x + 4 + j * 207, y + 154, 205, 99))
                label(draw, (x + 8 + j * 207, y + 157), camera, 14)
            result = next(r for r in rows if r["map"] == case and r["route"] == route)
            flag = " OVER" if not result["gate_pass"] else ""
            label(draw, (x + 6, y + 253), f"1080 frame {result['frame_1080p_ms']:.2f} | 4K GPU {result['gpu_4k_ms']:.2f} ms{flag}", 16,
                  "#ff8f83" if flag else INK)
    label(draw, (14, 640), "12.50 ms gate on each reading. Median of three session medians, second run kept. Full views linked in README.", 16)
    label(draw, (14, 666), "Camera 26 is the closest playable view. These thumbnails compare routes; native 4K pairs show hull contrast.", 15, MUTED)
    return sheet


def scale_sheets(source):
    artifacts = {}
    meta = json.loads((source / "nebula_cards_captures" / "scale_metadata.json").read_text())
    for row in meta["ships"]:
        cls = row["class"].lower().replace(" ", "_")
        for camera in (170, 60):
            sheet = Image.new("RGB", (1280, 720), BG)
            draw = ImageDraw.Draw(sheet)
            label(draw, (14, 10), f"N368 | SCALE B | {row['class']} ({row['code']}) | C{camera} | {row['length']:.2f} WORLD UNITS", 21)
            for col, case in enumerate(MAPS):
                x = col * 640 + 8
                label(draw, (x, 50), case.upper(), 18)
                path = source / f"{case}_cards_captures" / f"scale_{case}_cards_{cls}_c{camera}.png"
                im = Image.open(path).convert("RGB")
                paste_fit(sheet, im, (x, 80, 624, 351))
                sheet.paste(im.crop((648, 432, 1272, 648)), (x, 447))
            label(draw, (14, 685), "B candidate. Hex corner diameter 20. Full view above, native center crop below. Real generated unit moved for presentation.", 16, MUTED)
            artifacts[f"N368_scale_{cls}_c{camera}.jpg"] = sheet
        sheet = Image.new("RGB", (1280, 720), BG)
        draw = ImageDraw.Draw(sheet)
        label(draw, (14, 10), f"N368 | OTHER TERRAIN | {row['class']} ({row['code']}) | {row['length']:.2f} WORLD UNITS", 21)
        for col, kind in enumerate(("rock", "debris", "hulk")):
            x = col * 426 + 7
            label(draw, (x, 50), kind.upper(), 18)
            for j, camera in enumerate((170, 60)):
                y = 87 + j * 285
                path = source / "nebula_cards_captures" / f"scale_{kind}_cards_{cls}_c{camera}.png"
                paste_fit(sheet, Image.open(path).convert("RGB"), (x, y + 23, 414, 233))
                label(draw, (x, y), f"CAMERA {camera}", 16)
        label(draw, (14, 675), "Current rock, debris and wreck sizes. Ship is one hex beside the sampled terrain. Rocks await issue 369.", 16, MUTED)
        artifacts[f"N368_context_{cls}.jpg"] = sheet
    return artifacts


def camera_sheet(source, case, camera, rows):
    sheet = Image.new("RGB", (1280, 720), BG)
    draw = ImageDraw.Draw(sheet)
    label(draw, (14, 10), f"N368 | {case.upper()} | CAMERA {camera} | TODAY / A / B", 23)
    label(draw, (14, 44), "Full view above. Native 1080p center crop below, with no enlargement.", 17, MUTED)
    for col, (route, name) in enumerate(zip(ROUTES, NAMES)):
        x = col * 426 + 7
        im = capture(source, case, route, camera)
        label(draw, (x, 79), name, 18)
        paste_fit(sheet, im, (x, 105, 414, 233))
        # 414 x 260 native pixels around the shared center, no sharpening or recolouring.
        crop = im.crop((im.width // 2 - 207, im.height // 2 - 130, im.width // 2 + 207, im.height // 2 + 130))
        sheet.paste(crop, (x, 359))
        r = next(r for r in rows if r["map"] == case and r["route"] == route)
        label(draw, (x, 638), f"1080p frame: {r['frame_1080p_ms']:.3f} ms", 17)
        label(draw, (x, 665), f"4K GPU: {r['gpu_4k_ms']:.3f} ms | {'PASS' if r['gate_pass'] else 'OVER GATE'}", 17)
    return sheet


def native_4k_sheet(source):
    sheet = Image.new("RGB", (1280, 720), BG)
    draw = ImageDraw.Draw(sheet)
    label(draw, (14, 10), "N368 | HULL READABILITY | CAMERA 170 | NATIVE 4K PIXELS", 22)
    label(draw, (14, 43), "Gas above, the same locked view with gas hidden below. Crops are neither resized nor sharpened.", 16, MUTED)
    for col, (route, name) in enumerate(zip(ROUTES, NAMES)):
        x = col * 426 + 7
        label(draw, (x, 79), name, 18)
        for j, case in enumerate(MAPS):
            y = 112 + j * 280
            label(draw, (x, y), case.upper(), 16)
            for k, suffix in enumerate(("", "_clear")):
                path = source / f"{case}_{route}_captures" / f"{case}_{route}_c170_4k{suffix}.png"
                im = Image.open(path).convert("RGB")
                assert im.size == (3840, 2160), path
                crop = im.crop((1713, 1020, 2127, 1140))
                sheet.paste(crop, (x, y + 25 + k * 121))
                label(draw, (x + 4, y + 28 + k * 121), "GAS" if k == 0 else "CLEAR", 13)
    label(draw, (14, 686), "Read the plating and hull edges, not the selection ring. This is a visual check, not an automatic crispness score.", 15, MUTED)
    return sheet


def topdown_sheet(source):
    sheet = Image.new("RGB", (1280, 720), BG)
    draw = ImageDraw.Draw(sheet)
    label(draw, (14, 10), "N368 | TOP-DOWN BOARD | SAME GENERATED MAPS", 23)
    for col, (route, name) in enumerate(zip(ROUTES, NAMES)):
        x = col * 426 + 7
        label(draw, (x, 53), name, 18)
        for j, case in enumerate(MAPS):
            y = 89 + j * 286
            path = source / f"{case}_{route}_captures" / f"{case}_{route}_top.png"
            paste_fit(sheet, Image.open(path).convert("RGB"), (x, y + 23, 414, 233))
            label(draw, (x, y), case.upper(), 16)
    label(draw, (14, 675), "Radius 170, the game's top-down angle. A tactical hex samples part of the cloud; it is not the cloud's boundary.", 16, MUTED)
    return sheet


def campaign_sheet(source):
    sheet = Image.new("RGB", (1280, 720), BG)
    draw = ImageDraw.Draw(sheet)
    label(draw, (14, 4), "N368 | CAMPAIGN SECTOR MAP | CURRENT SCALE CONTEXT", 20)
    path = source / "campaign" / "m1_map.png"
    paste_fit(sheet, Image.open(path).convert("RGB"), (25, 28, 1230, 692))
    return sheet


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    args = parser.parse_args()
    validate_capture_poses(args.source)
    rows = measured(args.source)
    (HERE / "measurements.json").write_text(json.dumps(rows, indent=2) + "\n", encoding="ascii")
    artifacts = {"N368_route_comparison.jpg": overview(args.source, rows),
                 "N368_native_4k.png": native_4k_sheet(args.source),
                 "N368_topdown.jpg": topdown_sheet(args.source),
                 "N368_campaign.jpg": campaign_sheet(args.source)}
    for case in MAPS:
        for camera in CAMERAS:
            artifacts[f"N368_{case}_c{camera}.jpg"] = camera_sheet(args.source, case, camera, rows)
    artifacts.update(scale_sheets(args.source))
    for name, sheet in artifacts.items():
        sheet.save(HERE / name, quality=94)
        sheet.save(args.source / name, quality=94)
    print(json.dumps(rows, indent=2))


if __name__ == "__main__":
    main()
