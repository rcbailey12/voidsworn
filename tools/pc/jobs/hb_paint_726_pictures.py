"""Issue 726: one concept and two real battle-camera captures per ship."""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


def main():
    repo, proof = map(Path, sys.argv[1:3])
    cell, code = sys.argv[3:5]
    config = json.loads((repo / 'tools/recipe/ships' / f'corsair_{cell}.json').read_text())
    concept = Image.open(repo / config['concept']).convert('RGB')
    sources = [proof / 'before' / f'{code}_cam170.jpg',
               proof / cell / 'after' / f'{code}_cam170.jpg']
    bg, fg, dim = (14, 15, 18), (225, 228, 232), (165, 170, 178)
    canvas = Image.new('RGB', (1280, 720), bg)
    draw = ImageDraw.Draw(canvas)
    font = lambda size: ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size)
    draw.text((16, 10), f'{cell} | Hullbreaker paint, issue 726', fill=fg, font=font(24))
    draw.text((16, 43), 'Concept at left. Before and after in the game at camera 170, true pixels.', fill=dim, font=font(17))
    draw.text((16, 82), 'Accepted concept', fill=fg, font=font(18))
    image = ImageOps.contain(concept, (380, 568), Image.Resampling.LANCZOS)
    canvas.paste(image, (12 + (380 - image.width) // 2, 120 + (568 - image.height) // 2))
    for source, top, label in zip(sources, [82, 392], ['BEFORE: installed paint', 'AFTER: current R252 / R274 stack']):
        capture = Image.open(source).convert('RGB')
        if capture.size != (1920, 1080):
            raise ValueError(f'{source}: expected a 1920x1080 capture, got {capture.size}')
        draw.text((410, top), label, fill=fg, font=font(18))
        # Keep actual game pixels. Only remove empty space around the ship.
        crop = capture.crop((524, 404, 1396, 676))
        canvas.paste(crop, (404, top + 28))
    draw.text((410, 704), 'Grey salvaged plate and violet trophies; geometry includes PR 866.', fill=dim, font=font(12))
    output = proof / cell / f'{cell}_726_before_after.jpg'
    canvas.save(output, quality=95)
    print(output)


if __name__ == '__main__':
    main()
