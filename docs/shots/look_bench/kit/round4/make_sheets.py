"""Issue 849: real-pixel Doom comparisons and a complete kit difference sweep.

python -B make_sheets.py --root <issue-849/shots> --history <issue-815/shots>
The capture adapters in the parent folder supply warmed production frames.
"""
import argparse
import json
from pathlib import Path
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from make_sheets import TIMES, font, frame
from round2_sheets import load, phone
from round3_sheets import comparison, difference_stats


def motion(run, row, out):
    frames = []
    phone_frames = []
    times = [c['t'] for c in row['cells'] if .30 <= c['t'] <= 1.40]
    for t in times:
        im = Image.new('RGB', (1040, 360), '#0b1019')
        d = ImageDraw.Draw(im)
        d.text((8, 7), f'DOOM / KIT 849 / ROUND 4 / c170 / t={t:.3f}s', font=font(19), fill='#efd7a6')
        source, _ = frame(run, row, t)
        im.paste(source.crop((0, 30, 640, 330)), (0, 40))
        ph = phone(run, row, t)
        im.paste(ph, (650, 75))
        d.text((650, 40), 'Full frame / phone 390 px', font=font(16), fill='#cbd9e8')
        frames.append(im)
        phone_im = Image.new('RGB', (390, 249), '#0b1019')
        phone_im.paste(ph, (0, 30))
        ImageDraw.Draw(phone_im).text((8, 5), f'DOOM / ROUND 4 / t={t:.3f}s', font=font(17), fill='#efd7a6')
        phone_frames.append(phone_im)
    ticks = [round((t-times[0])*100) for t in times]
    ticks.append(round((times[-1]-times[0]+times[-1]-times[-2])*100))
    durations = [max(10, (ticks[i+1]-ticks[i])*10) for i in range(len(times))]
    frames[0].save(out/'doom_motion.gif', save_all=True, append_images=frames[1:],
        duration=durations, loop=0)
    phone_frames[0].save(out/'doom_phone_motion.gif', save_all=True,
        append_images=phone_frames[1:], duration=durations, loop=0)
    sequence = Image.new('RGB', (1280, 720), '#0b1019')
    d = ImageDraw.Draw(sequence)
    d.text((10, 5), 'DOOM / KIT 849 / ROUND 4 / c170 SOURCE PIXELS / FLOW AND COOLING', font=font(20), fill='#efd7a6')
    for j, t in enumerate([.40, .60, .80, 1.20]):
        im, actual = frame(run, row, t)
        x, y = j % 2 * 640, 38 + j // 2 * 340
        d.text((x+8, y), f't={actual:.3f}s', font=font(17), fill='#cbd9e8')
        sequence.paste(im.crop((0, 30, 640, 330)), (x, y+25))
    sequence.save(out/'doom_sequence.png')


def three_rounds(versions, out):
    sheet = Image.new('RGB', (1280, 720), '#0b1019')
    d = ImageDraw.Draw(sheet)
    d.text((10, 5), 'DOOM / KIT 849 / VIOLET SHEATH / t=0.600s', font=font(21), fill='#efd7a6')
    for i, (run, label) in enumerate(versions):
        records = load(run)
        x = i * 426 + 5
        d.text((x, 36), label, font=font(18), fill='#efd7a6')
        im, _ = frame(run, records['doom', 170], .60)
        im = im.resize((416, 234), Image.Resampling.LANCZOS)
        sheet.paste(im, (x, 82))
        d.text((x, 62), 'c170 / source view at 65%', font=font(15), fill='#cbd9e8')
        sheet.paste(phone(run, records['doom', 170], .60), (x + 8, 342))
        d.text((x, 320), 'Full frame / phone width 390 px', font=font(15), fill='#cbd9e8')
        im, _ = frame(run, records['doom', 60], .60, native=True)
        sheet.paste(im.crop((110, 100, 526, 230)), (x, 586))
        d.text((x, 565), 'c60 / source-pixel detail', font=font(15), fill='#cbd9e8')
    sheet.save(out / 'doom.png')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--root', type=Path, required=True)
    p.add_argument('--history', type=Path, required=True)
    a = p.parse_args()
    out = a.root / 'sheets'
    out.mkdir(exist_ok=True)
    before, after = a.root / 'before', a.root / 'after'
    bm, am = load(before), load(after)
    assert set(bm) == set(am) and len(am) == 108
    metrics = []
    for key in sorted(am):
        b, n = bm[key], am[key]
        assert [c['t'] for c in b['cells']] == [c['t'] for c in n['cells']]
        assert b['capture_batch'] == n['capture_batch']
        for field in ['file', 'native_file', 'phone_file']:
            assert (field in b) == (field in n)
            if field in b:
                bi = Image.open(before / b[field]).convert('RGB')
                ni = Image.open(after / n[field]).convert('RGB')
                metrics.append(dict(id=key[0], camera=key[1], view=field,
                    **difference_stats(bi, ni)))
    for name in sorted({k[0] for k in am}):
        row = am[name, 170]
        time = row['impacts'][0] + .20 if name.startswith('shield_') or name == 'p_torp_shield' else TIMES.get(name, row['cells'][4]['t'])
        if name == 'gauss':
            time = (row['fires'][0] + row['impacts'][0]) * .5
        comparison(name, before, after, bm, am, time, out)
    # The shared comparison helper's old labels name rounds 2 and 3.
    # Replace only its labels, leaving every captured effect pixel intact.
    for path in out.glob('*.png'):
        im = Image.open(path).convert('RGB')
        d = ImageDraw.Draw(im)
        d.rectangle((0, 0, 1279, 36), fill='#0b1019')
        d.text((10, 6), f'KIT 849 / {path.stem} / c170 + PHONE + c60', font=font(20), fill='#efd7a6')
        for i, label in enumerate(['ROUND 3 CONTROL', 'ROUND 4']):
            y = 38 + i * 346
            d.rectangle((0, y, 640, y + 24), fill='#0b1019')
            d.text((8, y), label + ' / c170 source pixels', font=font(16), fill='#cbd9e8')
        im.save(path)
    (out / 'doom.png').replace(out / 'doom_before_after.png')
    three_rounds([(a.history / 'before', 'ROUND 2 / violet reference'),
        (before, 'ROUND 3 / fresh control'), (after, 'ROUND 4 / R277')], out)
    motion(after, am['doom', 170], out)
    bc, ac = a.root / 'before_contact', a.root / 'after_contact'
    bcm, acm = load(bc), load(ac)
    comparison('doom_contact', bc, ac, bcm, acm, .60, out)
    contact = Image.open(out/'doom_contact.png').convert('RGB')
    d = ImageDraw.Draw(contact)
    d.rectangle((0, 0, 1279, 36), fill='#0b1019')
    d.text((10, 6), 'DOOM CONTACT / KIT 849 / c170 + PHONE + c60', font=font(20), fill='#efd7a6')
    for i, label in enumerate(['ROUND 3 CONTROL', 'ROUND 4']):
        y = 38 + i * 346
        d.rectangle((0, y, 640, y + 24), fill='#0b1019')
        d.text((8, y), label + ' / c170 source pixels', font=font(16), fill='#cbd9e8')
    contact.save(out/'doom_contact.png')
    cooling = Image.new('RGB', (1280, 720), '#0b1019')
    d = ImageDraw.Draw(cooling)
    d.text((10, 5), 'DOOM / KIT 849 / ROUND 4 / c60 / PLATING LIGHT TO SCORCH', font=font(20), fill='#efd7a6')
    for j, time in enumerate([.60, 1.10, 2.0, 3.5]):
        im, actual = frame(ac, acm['doom_contact', 60], time, native=True)
        x, y = j % 2 * 640, 38 + j // 2 * 340
        d.text((x + 8, y), f't={actual:.3f}s / source pixels', font=font(17), fill='#cbd9e8')
        cooling.paste(im.crop((0, 30, 640, 330)), (x, y + 25))
    cooling.save(out / 'doom_cooling.png')
    (out / 'whole_kit_pixels.json').write_text(json.dumps(metrics, indent=1))
    unchanged = [r for r in metrics if r['id'] not in {'doom', 'shield_doom_voidsworn',
        'shield_doom_hegemony', 'shield_doom_ithar', 'shield_doom_corsair'}]
    summary = dict(rows=len(am)//2, unchanged_rows=len({r['id'] for r in unchanged}),
        unchanged_max_delta=max(r['max_delta'] for r in unchanged),
        unchanged_peak_rms=max(r['rms'] for r in unchanged),
        differences_over_one=[r for r in unchanged if r['different_above_1']])
    (out / 'regression_summary.json').write_text(json.dumps(summary, indent=1))
    for path in out.iterdir():
        if path.suffix.lower() in ['.png', '.gif']:
            with Image.open(path) as im:
                assert im.width <= 1280 and im.height <= 720, path
    print('ROUND4_SHEETS', json.dumps(summary))


if __name__ == '__main__':
    main()
