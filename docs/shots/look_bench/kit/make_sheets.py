"""Make labelled review sheets from real bench images, never redraw effects."""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

TIMES = dict(doom=.60, macro=.40, auto=.15, las=.13, plasma=.38,
    scatter=.25, prism=.20, needle=.28, lance=.50, ion=.50, pulsar=.50,
    tendril=.60, gauss=.2667, torp=1.0, rockets=.9, star=1.0, flak=.30,
    pflak=.20, mflak=.20, gflak=.05, spores=.60, bioplasma=.50,
    guns=.30, bombs=.30, sporeb=.50, bay=.60, moving_trail=.90,
    torp_lane=.70, torp_intercept=1.15, rocket_intercept=.95, star_intercept=1.25)


def font(size):
    for path in ['C:/Windows/Fonts/consola.ttf', 'C:/Windows/Fonts/arial.ttf']:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def frame(run, record, time, native=False):
    cells = record['cells']
    index = min(range(len(cells)), key=lambda i: abs(cells[i]['t'] - time))
    image = Image.open(run / record.get('native_file', record['file']) if native else run / record['file'])
    cw, ch = image.width // len(cells), image.height
    return image.crop((index*cw, 0, (index+1)*cw, ch)), cells[index]['t']


def tile(sheet, image, x, y, label):
    # Keep the camera-170 source pixels. Only trim 30 empty sky pixels at
    # top and bottom; every kept effect pixel has its original size.
    image = image.crop((0, 30, 640, 330))
    sheet.paste(image, (x, y+26))
    ImageDraw.Draw(sheet).text((x+8, y+4), label, fill='#ced9e8', font=font(15))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--before', type=Path, required=True)
    p.add_argument('--after', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    args = p.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    before = json.loads((args.before / 'bench.json').read_text())
    after = json.loads((args.after / 'bench.json').read_text())
    cfg = json.loads((args.after / 'moments.json').read_text())
    bm = {(r['id'], r['cam']): r for r in before['stills']}
    am = {(r['id'], r['cam']): r for r in after['stills']}
    manifest = []
    for row in cfg['rows']:
        name = row['id']
        if (name, 170) not in am or (name, 170) not in bm:
            continue
        reference = am[(name, 170)]['cells']
        desired = TIMES.get(name, .25 if not name.startswith('p_') else reference[min(row.get('key', 4), len(reference)-1)]['t'])
        sheet = Image.new('RGB', (1280, 716), '#0b1019')
        d = ImageDraw.Draw(sheet)
        d.text((10, 5), f'KIT 367 / {name} / BEFORE AND AFTER / PICK PENDING', fill='#f1d7a0', font=font(20))
        for ci, cam in enumerate([170, 60]):
            for ri, (run, records, label) in enumerate([(args.before, bm, 'BEFORE'), (args.after, am, 'AFTER')]):
                native = cam == 60 and 'native_file' in records[(name, cam)]
                im, actual = frame(run, records[(name, cam)], desired, native=native)
                scale = 'source pixels' if cam == 170 or native else 'full 1920 view / 3'
                tile(sheet, im, ri*640, 34+ci*328, f'{label}  c{cam}  t={actual:.3f}s  {scale}')
        sheet.save(args.out / f'{name}.png')
        build = Image.new('RGB', (1280, 366), '#0b1019')
        ImageDraw.Draw(build).text((10, 5), f'KIT 367 / {name} / CAMERA 26 BUILD CHECK / full view reduced 3x', fill='#f1d7a0', font=font(18))
        for ri, (run, records, label) in enumerate([(args.before, bm, 'BEFORE'), (args.after, am, 'AFTER')]):
            im, actual = frame(run, records[(name, 26)], desired)
            tile(build, im, ri*640, 34, f'{label} c26 t={actual:.3f}s')
        build.save(args.out / f'{name}_c26.png')
        manifest.append(dict(id=name, time=desired, comparison=f'{name}.png', build=f'{name}_c26.png'))
        if name in ['doom', 'lance', 'ion', 'pulsar', 'needle', 'tendril', 'ribbon_0', 'ribbon_1', 'ribbon_3']:
            timeline = Image.new('RGB', (1280, 716), '#0b1019')
            ImageDraw.Draw(timeline).text((10, 5), f'KIT 367 / {name} / AFTER TIMELINE / c170 SOURCE PIXELS', fill='#f1d7a0', font=font(19))
            for i, time in enumerate([.40, .65, 1.10, 1.30]):
                im, actual = frame(args.after, am[(name, 170)], time)
                tile(timeline, im, (i%2)*640, 34+(i//2)*328, f'c170 t={actual:.3f}s')
            timeline.save(args.out / f'{name}_fade.png')
    (args.out / 'sheet_frames.json').write_text(json.dumps(manifest, indent=1))
    print(f'{len(manifest)} comparison sheets; all at most 716 px tall')


if __name__ == '__main__':
    main()
