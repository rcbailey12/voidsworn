"""Refs #368 run 6. Compose stamped game frames; no recoloring or sharpening."""
import argparse
import json
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont
ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools"))
from picture_provenance import Review

def font(n):
    return ImageFont.truetype("C:/Windows/Fonts/arial.ttf", n)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--before", type=Path, required=True)
    parser.add_argument("--deliver", type=Path, default=Path(__file__).parent)
    args = parser.parse_args()
    args.deliver.mkdir(parents=True, exist_ok=True)
    after = args.source / "after_keep"
    for radius in [170, 60]:
        review = Review("installed in game")
        sheet = Image.new("RGB", (1280,720), "#0b0d12")
        draw = ImageDraw.Draw(sheet)
        name = f"N368A_R6_lightning_c{radius}"
        draw.text((12,10), f"{name} | forks, colored glow and staggered strikes", font=font(23), fill="white")
        for col, (folder, kind, label) in enumerate([(args.before,"storm","Run 5 storm"),(after,"storm","Run 6 storm"),(after,"neb","Calm nebula unchanged")]):
            im = review.open(folder / f"{kind}_c{radius}_peak.png")
            x=col*426
            draw.text((x+8,48),label,font=font(20),fill="white")
            sheet.paste(im.resize((426,240),Image.Resampling.LANCZOS),(x,76))
            # Fixed native crop at the standard camera, close view crops the cloud.
            box = (700,250,1126,450) if radius == 170 else (1080,360,1506,560)
            if col==2: box=(747,380,1173,580)
            sheet.paste(im.crop(box),(x,342))
            draw.text((x+8,318),"Native 1080p pixels",font=font(17),fill="#b8b8c0")
        review.save(sheet,args.deliver/(name+".jpg"),quality=94)
        review = Review("installed in game")
        sheet=Image.new("RGB",(1280,720),"#0b0d12"); draw=ImageDraw.Draw(sheet)
        name=f"N368A_R6_strike_c{radius}"
        draw.text((12,10),f"{name} | one production burst | fixed view, reduced to fit",font=font(23),fill="white")
        samples=json.loads((after/"lightning_metadata.json").read_text())["samples"]
        for index,sample in enumerate(samples):
            im=review.open(after/f"storm_c{radius}_strike_{index:02d}.png")
            x=(index%3)*426; y=50+(index//3)*270
            active=sum((b["radiance"] or 0)>0.04 for b in sample["bolts"])
            draw.text((x+8,y),f'{sample["time"]-0.6:+.2f} s | {active} strikes active',font=font(19),fill="white")
            box=(640,270,1280,630) if radius==170 else (0,0,1920,1080)
            sheet.paste(im.crop(box).resize((426,240),Image.Resampling.LANCZOS),(x,y+25))
        review.save(sheet,args.deliver/(name+".jpg"),quality=94)


    if all((args.source / (tier + "_keep/lightning_metadata.json")).exists() for tier in ["high", "low"]):
        review=Review("installed in game")
        sheet=Image.new("RGB",(1280,720),"#0b0d12"); draw=ImageDraw.Draw(sheet)
        name="N368A_R6_quality_tiers"
        draw.text((12,10),f"{name} | actual Graphics settings | same generated board",font=font(23),fill="white")
        for row,radius in enumerate([170,60]):
            for col,(folder,label) in enumerate([("after_keep","Max: fog + cards"),("high_keep","High: cards"),("low_keep","Low: cards")]):
                im=review.open(args.source/folder/f"storm_c{radius}_peak.png")
                x=col*426; y=52+row*245
                draw.text((x+8,y),f"{label} | camera {radius}",font=font(20),fill="white")
                im.thumbnail((426,210),Image.Resampling.LANCZOS)
                sheet.paste(im,(x+(426-im.width)//2,y+25))
        review.save(sheet,args.deliver/(name+".jpg"),quality=94)

if __name__ == "__main__": main()
