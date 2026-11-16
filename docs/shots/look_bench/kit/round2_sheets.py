"""Issue 800: real before/after frames, phone views and a whole-kit sweep.

python round2_sheets.py --before DIR --after DIR --out DIR
All sheets are 1280x720 or smaller. No effect pixels are repainted.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw
from make_sheets import font, frame, TIMES


def load(run):
    data = json.loads((run / 'bench.json').read_text())
    assert not data['warnings'], data['warnings']
    return {(r['id'], r['cam']): r for r in data['stills']}


def phone(run, row, time):
    assert 'phone_file' in row, 'Recapture this row with the phone-view adapter'
    return frame(run, dict(row, file=row['phone_file']), time)[0]


def comparison(name, before, after, bm, am, time, out):
    sheet = Image.new('RGB', (1280, 720), '#0b1019')
    d = ImageDraw.Draw(sheet)
    d.text((10, 6), f'KIT 800 / {name} / c170 SOURCE PIXELS + PHONE + c60 DETAIL', font=font(20), fill='#efd7a6')
    for i, (run, rows, label) in enumerate([(before, bm, 'BEFORE'), (after, am, 'AFTER')]):
        y = 38 + i * 346
        im, actual = frame(run, rows[name, 170], time)
        sheet.paste(im.crop((0, 30, 640, 330)), (0, y+26))
        d.text((8, y), f'{label} / c170 / t={actual:.4f}s / source pixels', font=font(16), fill='#cbd9e8')
        ph = phone(run, rows[name, 170], time)
        sheet.paste(ph, (650, y+65))
        d.text((650, y+31), 'Full frame / phone width 390 px', font=font(15), fill='#cbd9e8')
        im, actual = frame(run, rows[name, 60], time, native=True)
        sheet.paste(im.crop((200, 30, 440, 330)), (1040, y+26))
        d.text((1044, y), 'c60 / source pixels', font=font(15), fill='#cbd9e8')
    sheet.save(out / f'{name}.png')


def sequence(name, after, am, out):
    row = am[name, 170]
    impact = row['impacts'][0]
    times = [0.15, 0.35, 0.60, 1.15] if name == 'doom' else [.25, .25+1/60, impact, impact+.15]
    sheet = Image.new('RGB', (1280, 720), '#0b1019')
    d = ImageDraw.Draw(sheet)
    d.text((10, 6), f'KIT 800 / {name} / c170 SOURCE PIXELS / AFTER SEQUENCE', font=font(20), fill='#efd7a6')
    for i, time in enumerate(times):
        im, actual = frame(after, row, time)
        x, y = i % 2 * 640, 36 + i // 2 * 342
        d.text((x+8, y+3), f't={actual:.4f}s / impact={impact:.4f}s', font=font(16), fill='#cbd9e8')
        sheet.paste(im.crop((0, 30, 640, 330)), (x, y+28))
    sheet.save(out / f'{name}_sequence.png')
    # An animation exposes moving packets and forks that a still cannot prove.
    if name == 'doom':
        samples = [c['t'] for c in row['cells'] if .25 <= c['t'] <= 1.45]
        images = []
        for time in samples:
            im, actual = frame(after, row, time)
            canvas = Image.new('RGB', (640, 360), '#0b1019')
            canvas.paste(im.crop((0, 30, 640, 330)), (0, 34))
            ImageDraw.Draw(canvas).text((8, 7), f'KIT 800 / doom / c170 / t={actual:.3f}s', font=font(17), fill='#efd7a6')
            images.append(canvas)
        # GIF clocks use 10 ms ticks. 30/40/30 ms preserves the bench's
        # 30 Hz motion instead of quietly playing the arc at half speed.
        duration = [40 if i % 3 == 1 else 30 for i in range(len(images))]
        images[0].save(out / 'doom_motion.gif', save_all=True, append_images=images[1:], duration=duration, loop=0)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--before', type=Path, required=True)
    p.add_argument('--after', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args()
    a.out.mkdir(parents=True, exist_ok=True)
    bm, am = load(a.before), load(a.after)
    assert set(bm) == set(am)
    sweep = []
    for key in sorted(am):
        b, n = bm[key], am[key]
        before = Image.open(a.before / b['file']).convert('RGB')
        after = Image.open(a.after / n['file']).convert('RGB')
        assert before.size == after.size
        assert [c['t'] for c in b['cells']] == [c['t'] for c in n['cells']]
        assert b.get('capture_batch') == n.get('capture_batch')
        bb, ab = before.tobytes(), after.tobytes()
        histogram = ImageChops.difference(before, after).histogram()
        different = len(bb) - sum(histogram[i*256] for i in range(3))
        above_one = sum(sum(histogram[i*256+2:(i+1)*256]) for i in range(3))
        maximum = max(hi for lo, hi in ImageChops.difference(before, after).getextrema())
        sweep.append(dict(id=key[0], camera=key[1], different_channels=different,
                          different_above_1=above_one, max_channel_delta=maximum,
                          before_sha256=hashlib.sha256(bb).hexdigest(), after_sha256=hashlib.sha256(ab).hexdigest()))
    for name, time in [('doom', .60), ('gauss', .25), ('gflak', .0333)]:
        comparison(name, a.before, a.after, bm, am, time, a.out)
        if name != 'gflak':
            sequence(name, a.after, am, a.out)
    # One normal before/after sheet per other kind, even when pixel identical.
    for name in sorted({key[0] for key in am} - {'doom', 'gauss', 'gflak'}):
        sheet = Image.new('RGB', (1280, 720), '#0b1019')
        d = ImageDraw.Draw(sheet)
        d.text((10, 6), f'KIT 800 / {name} / WHOLE-KIT REGRESSION', font=font(20), fill='#efd7a6')
        for j, camera in enumerate([170, 60]):
            for i, (run, rows, label) in enumerate([(a.before, bm, 'BEFORE'), (a.after, am, 'AFTER')]):
                row = rows[name, camera]
                fallback = row['cells'][min(4, len(row['cells'])-1)]['t'] if name.startswith('p_') else .25
                time = TIMES.get(name, fallback)
                im, actual = frame(run, row, time, native=camera == 60 and 'native_file' in row)
                x, y = i*640, 38+j*340
                d.text((x+8, y), f'{label} / c{camera} / t={actual:.3f}s', font=font(16), fill='#cbd9e8')
                sheet.paste(im.crop((0, 30, 640, 330)), (x, y+26))
        sheet.save(a.out / f'{name}.png')
    (a.out / 'whole_kit_pixels.json').write_text(json.dumps(sweep, indent=1))
    changed = sorted({r['id'] for r in sweep if r['different_above_1']})
    print('Changed rows:', ', '.join(changed))
    print('Rows matching within one 8-bit channel value:', len({r['id'] for r in sweep}) - len(changed))
    for file in a.out.glob('*.png'):
        with Image.open(file) as im:
            assert im.height <= 720 and im.width <= 1280, file


if __name__ == '__main__':
    main()
