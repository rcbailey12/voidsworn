"""Compose the R80 captures without changing the original 4K screenshots.

Run with the PC's bundled ComfyUI Python: this uses its existing Pillow.
Arguments: capture folder, output folder, label (baseline/final/safe).
"""
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont

source, output = map(Path, sys.argv[1:3])
label = sys.argv[3] if len(sys.argv) > 3 else "final"
output.mkdir(parents=True, exist_ok=True)
factions = [("hegemony", "Hegemony cruiser"), ("deathless", "Eclipse: D22 at battleship scale"),
            ("chorus", "Chorus cruiser"), ("ithar", "Glasswright cruiser"),
            ("voidsworn", "Crusade cruiser")]
font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 26)
small = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 21)

for zoom in ["battle", "close"]:
    sheet = Image.new("RGB", (3840, 2400), "#111822")
    draw = ImageDraw.Draw(sheet)
    caption = "170-unit battle camera, centre crops" if zoom == "battle" else "close zoom, full hull"
    draw.text((24, 16), f"R80 {label}: stages 0 to 4 | {caption} | originals: 3840 x 2160", font=font, fill="white")
    for stage in range(5):
        draw.text((stage * 768 + 24, 66), f"Stage {stage}", font=font, fill="#e4c58a")
    for row, (faction, name) in enumerate(factions):
        y = 110 + row * 454
        for stage in range(5):
            path = source / f"{faction}_stage{stage}_{zoom}.png"
            if not path.exists():
                continue
            with Image.open(path) as im:
                if zoom == "battle":
                    x, z = im.width // 2, im.height // 2
                    im = im.crop((x - 768, z - 432, x + 768, z + 432))
                sheet.paste(im.resize((768, 432)), (stage * 768, y))
        draw.text((14, y + 4), name, font=small, fill="white", stroke_width=2, stroke_fill="black")
    sheet.save(output / f"{label}_{zoom}_stages.jpg", quality=94)

sheet = Image.new("RGB", (2400, 5 * 510 + 70), "#111822")
draw = ImageDraw.Draw(sheet)
draw.text((18, 12), f"R80 {label}: stage 3 sealed fissure | stage 4 throat | repaired scar", font=font, fill="white")
for row, (faction, name) in enumerate(factions):
    for col, suffix in enumerate(["stage3_detail", "stage4_detail", "repaired"]):
        path = source / f"{faction}_{suffix}.png"
        if not path.exists():
            continue
        with Image.open(path) as im:
            sheet.paste(im.resize((800, 450)), (col * 800, row * 510 + 70))
    draw.text((16, row * 510 + 74), name, font=small, fill="white", stroke_width=2, stroke_fill="black")
sheet.save(output / f"{label}_details_repair.jpg", quality=94)
