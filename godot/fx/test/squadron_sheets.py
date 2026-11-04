"""Build labelled review sheets and motion clips from the real battle captures."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
try:
    import av
except ImportError:
    av = None

FACTIONS = {
    "voidsworn": "Sunward Crusade",
    "hegemony": "Hegemony Navy",
    "corsair": "Ashfall Hullbreakers",
    "chorus": "The Chorus: spore swarm / acid sacs",
    "ithar": "Glasswrights",
}


def sheet(out, name, rows, columns, width=960):
    height, label = width * 9 // 16, 44
    canvas = Image.new("RGB", (width * columns, (height + label) * len(rows)), "#10151c")
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 25)
    for y, row in enumerate(rows):
        for x, (filename, title) in enumerate(row):
            px, py = x * width, y * (height + label)
            draw.text((px + 14, py + 8), title, fill="#e3e9ef", font=font)
            if filename:
                with Image.open(out / filename) as img:
                    canvas.paste(img.convert("RGB").resize((width, height), Image.Resampling.LANCZOS), (px, py + label))
    canvas.save(out / name, quality=94)


def main():
    out, frames = map(Path, sys.argv[1:3])
    rows = [[(f"{fac}_close.png", title + " / close"), (f"{fac}_battle.png", title + " / battle camera")]
            for fac, title in FACTIONS.items()]
    rows.append([("deathless_battle_no_squadrons.png", "Eclipse / no squadron launch in the rules"),
                 (None, "Eclipse close-up omitted: there are no wings to show")])
    sheet(out, "review_sheet.jpg", rows, 2)
    rows = [[(f"{fac}_{view}.png", title + " / " + view) for view in ["close", "top", "low"]]
            for fac, title in FACTIONS.items()]
    sheet(out, "detail_angles.jpg", rows, 3, 800)
    rows = []
    for fac in ["voidsworn", "hegemony", "ithar"]:
        other = "fighter" if fac == "voidsworn" else "bomber"
        native = "bomber" if fac == "voidsworn" else "fighter"
        rows.append([(f"{fac}_close.png", FACTIONS[fac] + " / " + native),
                     (f"{fac}_{other}_close.png", FACTIONS[fac] + " / " + other)])
    sheet(out, "craft_types.jpg", rows, 2)
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 26)
    for fac, title in FACTIONS.items():
        images = []
        video = None
        if av is not None:
            video = av.open(str(out / (fac + "_motion.mp4")), "w", options={"movflags": "+faststart"})
            stream = video.add_stream("libx264", rate=24)
            stream.width, stream.height = 960, 540
            stream.pix_fmt = "yuv420p"
            stream.options = {"crf": "20", "preset": "veryfast"}
        for path in sorted((frames / fac).glob("*.png")):
            with Image.open(path) as source:
                img = source.convert("RGB").resize((960, 540), Image.Resampling.LANCZOS)
            draw = ImageDraw.Draw(img)
            draw.rectangle((0, 0, 960, 44), fill="#10151c")
            draw.text((14, 6), title + " / launch, formation, bank", font=font, fill="white")
            if video is not None:
                for packet in stream.encode(av.VideoFrame.from_image(img)):
                    video.mux(packet)
            else:
                images.append(img.quantize(colors=160))
        if video is not None:
            for packet in stream.encode():
                video.mux(packet)
            video.close()
        if images:
            images[0].save(out / (fac + "_motion.gif"), save_all=True, append_images=images[1:],
                           duration=[[40, 40, 50][i % 3] for i in range(len(images))], loop=0, disposal=2)
    print("Squadron sheets and motion clips saved to", out)


if __name__ == "__main__":
    main()
