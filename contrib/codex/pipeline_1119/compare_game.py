"""Pair the C19_51 battle and close captures from two a4_shots runs."""
import argparse
from pathlib import Path
import sys

from PIL import Image, ImageChops, ImageDraw, ImageStat

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'tools'))
from picture_provenance import Review, verify


VIEWS = {
    'corsair_battle': 'Battle',
    'corsair_battle_near': 'Battle zoom',
    'C19_51_q': 'Bow',
    'C19_51_s': 'Side',
    'C19_51_b': 'Below',
    'C19_51_t': 'Top',
    'C19_51_d': 'Deck',
    'C19_51_u': 'Underside',
}


def compare(main, branch, output):
    for name, title in VIEWS.items():
        review = Review('installed in game')
        left, right = [
            review.open(folder / f'{name}.jpg').convert('RGB')
            for folder in (main, branch)
        ]
        if left.size != right.size:
            raise ValueError(f'{name} captures have different dimensions')
        mae = sum(ImageStat.Stat(ImageChops.difference(left, right)).mean) / 3
        print(f'{name}: mean absolute RGB difference {mae:.4f}/255')

        canvas = Image.new('RGB', (1280, 524), '#11151e')
        draw = ImageDraw.Draw(canvas)
        for x, label, image in [(12, 'Main / JPEG', left), (646, 'Branch / PNG', right)]:
            draw.text((x, 15), f'C19_51  |  {title}  |  {label}', fill='#f1e8d9', font_size=19)
            image.thumbnail((622, 350), Image.Resampling.LANCZOS)
            canvas.paste(image, (x + (622 - image.width) // 2, 44))
        path = output / f'C19_51_game_{name.rsplit("_", 1)[-1]}.png'
        review.save(canvas, path, optimize=True)
        verify(path)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('main', type=Path)
    parser.add_argument('branch', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    compare(args.main, args.branch, args.output)
