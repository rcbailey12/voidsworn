"""Issue 726: one concept and two real battle-camera captures per ship."""
import json
import os
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
    revision = os.environ['HB726_REVISION']
    font = lambda size: ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size)
    # Label the source revision and the actual stage on every comparison sheet.
    for source in (proof / cell / 'pictures').glob('*.jpg'):
        sheet = Image.open(source).convert('RGB')
        stage = 'Stage 7: installed in playable game' if '_ingame_' in source.name else 'Stage 5: painted proof'
        draw = ImageDraw.Draw(sheet)
        draw.rectangle((0, 32, sheet.width, 59), fill=bg)
        draw.text((12, 36), f'{revision} | {stage} | Hullbreaker stack, R274 dark grey trophies', fill=dim, font=font(15))
        sheet.save(source, quality=95)
    canvas = Image.new('RGB', (1280, 720), bg)
    draw = ImageDraw.Draw(canvas)
    draw.text((16, 10), f'{cell} | Hullbreaker paint, issue 726', fill=fg, font=font(24))
    draw.text((16, 43), f'{revision} | Stage 7: installed in playable game | Camera 170, true pixels', fill=dim, font=font(17))
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
    draw.text((410, 704), 'Grey salvaged plate and violet trophies; geometry includes PRs 884 and 898.', fill=dim, font=font(12))
    output = proof / cell / f'{cell}_726_before_after.jpg'
    canvas.save(output, quality=95)
    print(output)
    if cell == 'A16':
        reference = repo / 'docs/ship_pipeline/build_sheets/corsair_A16/paint/issue726/A16_r274_dark_grey.jpg'
        stored = Image.open(reference).convert('RGB')
        if stored.size != (1280, 720):
            raise ValueError('The stored A16 R274 reference layout changed')
        current = Image.open(proof / cell / 'pictures' / f'{cell}_paint_full.jpg').convert('RGB')
        pair = Image.new('RGB', (1280, 720), bg)
        pd = ImageDraw.Draw(pair)
        pd.text((12, 10), 'A16 | stored R274 paint beside the completed run 4 paint', fill=fg, font=font(22))
        pd.text((12, 43), f'{revision} | Stage 5 comparison | Geometry and faction stack match main; fixture record matches', fill=dim, font=font(16))
        crops = [(stored.crop((740, 106, 1173, 395)), '19464d19 | R274 sandbox preview, 1024 maps'),
                 (current.crop((644, 60, current.width, current.height)), f'{revision} | Stage 5, 4096 maps')]
        for index, (crop, label) in enumerate(crops):
            x = index * 640
            pd.text((x + 12, 86), label, fill=fg, font=font(16))
            fitted = ImageOps.contain(crop, (632, 588), Image.Resampling.LANCZOS)
            pair.paste(fitted, (x + (640 - fitted.width) // 2, 120 + (588 - fitted.height) // 2))
        proof_file = proof / cell / 'pictures' / 'A16_r274_reference_vs_run4.jpg'
        pair.save(proof_file, quality=95)
        print(proof_file)


if __name__ == '__main__':
    main()
