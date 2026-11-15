"""Measure the actual rendered pixels and make a native-pixel tracer sheet."""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


def fwhm(column):
    peak = max(column)
    if peak <= 5:
        return 0
    runs, start = [], None
    for i, value in enumerate(column + [0]):
        if value >= peak * .5 and start is None:
            start = i
        if value < peak * .5 and start is not None:
            runs.append((start, i))
            start = None
    return max((b-a for a, b in runs), default=0)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('run', type=Path)
    args = p.parse_args()
    rows = json.loads((args.run / 'raster_frames.json').read_text())
    measured = []
    for row in rows:
        im = Image.open(args.run / row['file']).convert('RGB')
        mask = im.convert('L').point(lambda v: 255 if v > 5 else 0)
        bbox = mask.getbbox()
        result = dict(row, bbox=bbox, width=0 if bbox is None else bbox[2]-bbox[0],
                      height_lit=0 if bbox is None else bbox[3]-bbox[1])
        if row['test'] in ['lance', 'doom']:
            column = im.crop((im.width//2, 0, im.width//2+1, im.height))
            result['red_fwhm'] = fwhm(list(column.getchannel('R').tobytes()))
            result['green_fwhm'] = fwhm(list(column.getchannel('G').tobytes()))
        if row['test'].startswith('spark'):
            assert bbox and result['width'] <= 18, result
        if row['test'] == 'shell':
            assert bbox and result['width'] <= 24, result
        if row['test'].startswith('gauss'):
            frame_index = int(Path(row['file']).stem.rsplit('_f', 1)[1])
            assert bool(bbox) == (frame_index < 2), result
            assert result['width'] <= 28, result
        measured.append(result)
    (args.run / 'cap_measurements.json').write_text(json.dumps(measured, indent=1))
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 16)
    for height in [1080, 2160]:
        sheet = Image.new('RGB', (1280, 680), '#0b1019')
        d = ImageDraw.Draw(sheet)
        d.text((10, 8), f'KIT 367 / GAUSS / {height} LINES / NATIVE PIXEL CROPS / NO BLOOM', font=font, fill='#efd7a6')
        for ri, cam in enumerate([170, 60, 26]):
            samples = [r for r in measured if r['test'] == 'gauss' and r['height'] == height and r['camera'] == cam]
            for ci, row in enumerate(samples):
                im = Image.open(args.run / row['file'])
                box = row['bbox']
                cx = (box[0]+box[2])//2 if box else im.width//2
                cy = (box[1]+box[3])//2 if box else im.height//2
                crop = im.crop((cx-160, cy-80, cx+160, cy+80))
                x, y = ci*320, 45+ri*205
                sheet.paste(crop, (x, y+27))
                d.text((x+8, y+4), f'c{cam} f{ci} {row["age"]:.4f}s lit={row["width"]}px', font=font, fill='#cbd9e8')
                if box is None:
                    d.text((x+40, y+97), 'Full frame: no lit pixels', font=font, fill='#cbd9e8')
        sheet.save(args.run / f'gauss_two_frames_{height}.png')
    print('RASTER PASS: caps at three cameras, 1080p and 4K; exactly two gauss frames at max and low quality')
    for r in measured:
        if r['test'] in ['lance', 'doom'] and r['height'] == 1080:
            print(r['test'], r['camera'], 'red/green FWHM', r['red_fwhm'], r['green_fwhm'])


if __name__ == '__main__':
    main()
