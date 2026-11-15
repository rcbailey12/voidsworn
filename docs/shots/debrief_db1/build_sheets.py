"""Lay out real 1080p captures beside the picked DB1, without changing their content.

Agent reproduction: python docs/shots/debrief_db1/build_sheets.py --raw <capture folder>
Capture source: godot/ui/campaign/test/debrief_ledger_test.gd --shots <capture folder>
"""
import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
MOCK = ROOT / "contrib/muse/design/ui_upgrade_2026_11/debrief/DB1.png"
FONT = ROOT / "godot/ui/theme/fonts/Barlow-Medium.ttf"


def tile(source, label):
    result = Image.new("RGB", (1280, 720), "#0b0e0b")
    image = Image.open(source).convert("RGB")
    assert image.size == (1920, 1080), (source, image.size)
    result.paste(image.resize((1216, 684), Image.Resampling.LANCZOS), (32, 36))
    ImageDraw.Draw(result).text((32, 3), label, font=ImageFont.truetype(str(FONT), 25), fill="#f0eade")
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw", type=Path, required=True)
    args = parser.parse_args()
    mock = tile(MOCK, "DB1 | PICKED MOCKUP")
    for source in sorted(args.raw.glob("DB1_*.png")):
        state = source.stem.removeprefix("DB1_")
        actual = tile(source, "DB1 | GODOT " + state.replace("_", " ").upper())
        actual.save(OUT / (source.stem + ".jpg"), quality=94, subsampling=0)
        if state in ["win", "loss", "first_loss"]:
            sheet = Image.new("RGB", (2560, 720), "#0b0e0b")
            sheet.paste(actual, (0, 0))
            sheet.paste(mock, (1280, 0))
            sheet.save(OUT / (source.stem + "_beside_pick.jpg"), quality=94, subsampling=0)
    print("Saved DB1 review pictures, all 720 px tall, to", OUT)


if __name__ == "__main__":
    main()
