"""Label FL5 captures and put each required resolution beside Ryan's picked FL5.

Run: python docs/shots/ui/fleet_fl5/make_sheets.py SHOTS_DIR
The original GPU captures remain in SHOTS_DIR. Review sheets are at most 720 high.
"""
from pathlib import Path
import argparse
from PIL import Image, ImageDraw, ImageFont


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("shots", type=Path)
    args = parser.parse_args()
    output = Path(__file__).resolve().parent
    repo = output.parents[3]
    font = ImageFont.truetype(str(repo / "godot/ui/theme/fonts/Barlow-Medium.ttf"), 22)
    reference = Image.open(repo / "contrib/muse/design/ui_upgrade_2026_11/fleet/FL5.png").convert("RGB")
    for code, resolution in [("1080", "1920 x 1080"), ("2160", "3840 x 2160")]:
        source = Image.open(args.shots / f"FL5_{code}.png").convert("RGB")
        expected = (1920, 1080) if code == "1080" else (3840, 2160)
        assert source.size == expected, (code, source.size)
        sheet = Image.new("RGB", (1280, 404), "#090b0e")
        draw = ImageDraw.Draw(sheet)
        draw.text((16, 9), "FL5 PICK", font=font, fill="#f0eade")
        draw.text((656, 9), f"FL5 BUILD | {resolution}", font=font, fill="#f0eade")
        sheet.paste(reference.resize((640, 360), Image.Resampling.LANCZOS), (0, 44))
        sheet.paste(source.resize((640, 360), Image.Resampling.LANCZOS), (640, 44))
        filename = f"FL5_compare_{code}.jpg"
        sheet.save(output / filename, quality=94)
        sheet.save(args.shots / filename, quality=94)
    for code in ["1080", "2160", "damaged", "hold", "doctrine", "hover", "busy"]:
        source = Image.open(args.shots / f"FL5_{code}.png").convert("RGB")
        source.thumbnail((1230, 676), Image.Resampling.LANCZOS)
        sheet = Image.new("RGB", (1280, 720), "#090b0e")
        draw = ImageDraw.Draw(sheet)
        draw.text((24, 8), "FL5 | " + code.upper(), font=font, fill="#f0eade")
        sheet.paste(source, ((1280 - source.width) // 2, 44))
        sheet.save(output / f"FL5_{code}.jpg", quality=94)
        sheet.save(args.shots / f"FL5_{code}.jpg", quality=94)


if __name__ == "__main__":
    main()
