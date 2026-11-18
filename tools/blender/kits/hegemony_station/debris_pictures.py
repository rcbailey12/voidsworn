"""Refs #863. Review the loaded debris beside the T2 concept and report clearance."""
import argparse
from collections import Counter
import json
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(REPO/'tools'))
from picture_provenance import Review

REFERENCE = REPO/'contrib/muse/design/station_concept_2026_11'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def pictures(raw, out, inventory):
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 24)
    small = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 18)
    for suffix, title, concept in [('170', 'CAMERA 170', 'beauty'), ('60', 'CAMERA 60', 'scale'),
                                  ('plan', 'PLAN VIEW', 'scale')]:
        review = Review('installed in game')
        stem = 'station_T2_debris' + ('_plan' if suffix == 'plan' else suffix)
        frame = review.open(raw/(stem+'.png')).convert('RGB')
        ref = review.open(REFERENCE/('station_T2_'+concept+'.jpg'), reference=True)
        sheet = Image.new('RGB', (1280, 720), '#080c12')
        sheet.paste(frame.resize((800, 450), Image.Resampling.LANCZOS), (0, 105))
        ref.thumbnail((470, 450), Image.Resampling.LANCZOS)
        sheet.paste(ref, (805, 105 + (450 - ref.height) // 2))
        draw = ImageDraw.Draw(sheet)
        draw.text((16, 12), 'station_T2_debris | '+title, fill='#ede6d7', font=font)
        draw.text((16, 49), 'Installed T2 with detached wreckage', fill='#c6ced8', font=small)
        draw.text((805, 49), 'Accepted T2 '+('plan' if concept == 'scale' else 'beauty'),
                  fill='#c6ced8', font=small)
        draw.text((16, 574), inventory+' | Slow tumble', fill='#c6ced8', font=small)
        review.save(sheet, out/('station_T2_debris_compare'+suffix+'.png'))

    for suffix, title in [('170', 'CAMERA 170'), ('60', 'CAMERA 60'), ('60_t600', 'CAMERA 60 / 600 S')]:
        review = Review('installed in game')
        frame = review.open(raw/('station_T2_debris'+suffix+'.png')).convert('RGB')
        width, height = frame.size
        left, top = (width-1280)//2, (height-720)//2
        frame = frame.crop((left, top, left+1280, top+720))
        draw = ImageDraw.Draw(frame)
        draw.rectangle((0, 0, 1280, 46), fill='#10161d')
        draw.text((16, 9), 'station_T2_debris | '+title+' | NATIVE CROP', fill='#ede6d7', font=font)
        review.save(frame, out/('station_T2_debris_native'+suffix+'.png'))


def placement(out, checks, next_checks, inventory):
    variants = [checks]
    if next_checks:
        variants.append(next_checks)
    rows = ['# station_T2_debris placement', '', 'Loaded geometry check passed. '+inventory+'.', '',
            f"Debris triangles **{checks['triangles']:,}**, base station **{checks['base_station_triangles']:,}**, "
            f"combined **{checks['combined_triangles']:,}**.", '']
    for proof in variants:
        cell_count = len(proof['footprint']['cells'])
        rows += [f"## {cell_count}-cell rules", '',
                 'Positions use station-local Godot X/Y/Z. The stub points toward +Z. Cell gap covers every '
                 'station bearing and tumble angle.', '',
                 f"Blocked-cell bound {proof['all_bearings_blocked_radius']:.3f} world units. "
                 f"Smallest debris gap {proof['minimum_blocked_clearance']:.3f}. "
                 f"Vertical gap to {proof['lowest_ship']} "
                 f"{proof['lowest_fitted_ship_y']-proof['maximum_debris_world_y']:.3f}.", '',
                 '| Piece | X / Y / Z | Tumble radius | Cell gap | Triangles |',
                 '|---|---|---|---|---|']
        for row in proof['pieces']:
            x, y, z = row['position']
            rows.append(f"| {row['name']} | {x:.2f} / {y:.2f} / {z:.2f} | {row['tumble_radius']:.3f} | "
                        f"{row['blocked_cell_clearance']:.3f} | {row['triangles']:,} |")
        rows.append('')
    (out/'debris_placement.md').write_text('\n'.join(rows), encoding='utf-8')


def verify_gate(path, work, pieces):
    gate = read(path)
    ships = sum(row['cls'] != 'Squadron' for row in gate['scene']['ships'])
    assert gate['map'] == 'station' and ships == 20, 'Wrong scene gate setup'
    assert gate['station_T2_instances'] == 1 and gate['station_T2_debris_pieces'] == pieces, 'Debris absent from scene gate'
    frame1080 = [row['frame_median'] for row in gate['modes']['base']]
    gpu4k = [row['gpu_median'] for row in gate['modes']['res_2160']]
    assert len(frame1080) == len(gpu4k) == 3, 'Incomplete scene gate'
    passed = all(0 < time <= 12.5 for time in frame1080 + gpu4k)
    summary = dict(pass_=passed, frame1080_ms=frame1080, gpu4k_ms=gpu4k,
                   ship_count=ships, squadron_count=gate['scene']['ship_count'] - ships,
                   station_T2_debris_pieces=pieces,
                   adapter=gate['adapter'], measured_frames=gate['measured_frames'],
                   warmup_frames=gate['warmup_frames'], probe_sha256=gate['probe_sha256'])
    (work/'debris_gate_summary.json').write_text(json.dumps(summary, indent=2)+'\n', encoding='utf-8')
    assert passed, f'Station debris missed 12.5 ms: frame 1080p {frame1080}, GPU 4K {gpu4k}'
    print('T2 DEBRIS GATE PASS:', frame1080, gpu4k)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('raw', type=Path)
    parser.add_argument('work', type=Path)
    parser.add_argument('out', type=Path)
    parser.add_argument('approved', type=Path)
    parser.add_argument('--gate', type=Path)
    args = parser.parse_args()
    checks = read(args.work/'debris_checks.json')
    alternate = args.work/'debris_checks_983.json'
    next_checks = read(alternate) if alternate.is_file() else None
    approved = read(args.approved)
    for proof in filter(None, (checks, next_checks)):
        assert proof['pass'], 'Loaded geometry check failed'
        assert proof['base_glb_sha256'] == approved['glb_sha256'], 'Approved painted base GLB differs'
        assert proof['base_station_triangles'] == approved['triangles'], 'Loaded base geometry differs'
    counts = Counter(row['kind'] for row in checks['pieces'])
    inventory = '{} torn plates, {} broken trusses, {} pressure pod, {} antenna, {} fine fragments'.format(
        *(counts[k] for k in ('plate', 'girder', 'pod', 'antenna', 'chip')))
    pictures(args.raw, args.out, inventory)
    placement(args.work, checks, next_checks, inventory)
    print('T2 DEBRIS PICTURES PASS: 170, 60 and plan alongside T2, plus native crops')
    if args.gate:
        verify_gate(args.gate, args.work, len(checks['pieces']))


if __name__ == '__main__':
    main()
