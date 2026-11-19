"""Compose one stamped 1280x720 comparison per selected look candidate."""

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
from picture_provenance import Review


CANDIDATES = {
    "msaa_2x": ("gate", "MSAA 2x", "MSAA 4x", "Fitted shield and hull edges"),
    "msaa_off": ("gate", "MSAA off", "MSAA 4x", "Fitted shield and hull edges"),
    "fog_64": ("dense", "Fog grid 64", "Fog grid 128", "Seed 4103 storm during a strike"),
    "lod": ("gate", "Mesh LOD enabled", "Full detail", "Battle ship and fitted shield"),
    "ship_shadows_off": ("gate", "Ship shadows off", "Ship shadows on", "Shadow detail on the ship"),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("candidates", nargs="+", choices=CANDIDATES)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 20)
    small = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 16)
    for candidate in args.candidates:
        fixture, after, before, detail = CANDIDATES[candidate]
        review = Review("installed in game")
        sheet = Image.new("RGB", (1280, 720), "#10151e")
        draw = ImageDraw.Draw(sheet)
        code = f"PERF1070_{candidate.upper()}"
        for row, radius in enumerate((170, 26)):
            y = row * 320
            for col, (variant, name) in enumerate((("base", before), (candidate, after))):
                x = col * 640
                image = review.open(args.input / f"PERF1070_{fixture}_{variant}_c{radius}.png")
                left = x + (64 if radius == 170 else 12)
                draw.text((left, y + 4), f"{name}  |  camera {radius}", font=font, fill="#f1e8d9")
                if radius == 170:
                    sheet.paste(image.resize((512, 288), Image.Resampling.LANCZOS), (left, y + 31))
                    continue
                sheet.paste(image.resize((400, 225), Image.Resampling.LANCZOS), (left, y + 31))
                centre_x, centre_y = image.width // 2, image.height // 2
                crop = image.crop((centre_x - 100, centre_y - 100, centre_x + 100, centre_y + 100))
                sheet.paste(crop, (x + 424, y + 31))
                draw.text((x + 424, y + 235), "1:1 crop", font=small, fill="#dcc7a8")
        draw.text((64, 604), f"{code}  |  {detail}", font=small, fill="#dcc7a8")
        review.save(sheet, args.out / f"{code}.jpg", quality=95)


if __name__ == "__main__":
    main()
