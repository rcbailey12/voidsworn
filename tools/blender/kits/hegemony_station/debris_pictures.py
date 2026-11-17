"""Refs #863. T2 evidence beside its accepted plan, with revision sidecars."""
import json
from collections import Counter
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parents[4]
sys.path.insert(0,str(REPO/'tools'))
from picture_provenance import Review


def main():
    raw,out = map(Path,sys.argv[1:3])
    checks = json.loads((out/'debris_checks.json').read_text())
    baseline = json.loads((REPO/'docs/shots/look_bench/station/production_checks.json').read_text())
    assert checks['pass'], 'Loaded geometry check failed'
    assert checks['base_glb_sha256'] == baseline['glb_sha256'], 'Painted base GLB changed'
    assert checks['base_station_triangles'] == baseline['triangles'], 'Loaded base geometry changed'
    counts = Counter(row['kind'] for row in checks['pieces'])
    inventory = '%s torn plates, %s bent girders, %s cold pods, %s fine fragments' % tuple(
        counts[k] for k in ('plate','girder','pod','chip'))
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
    small = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
    for suffix,title in [('170','CAMERA 170'),('60','CAMERA 60'),('plan','PLAN VIEW')]:
        review = Review('installed in game')
        frame = review.open(raw/('station_T2_debris'+suffix+'.png')).convert('RGB')
        ref = review.open(REPO/'contrib/muse/design/station_concept_2026_11/station_T2_scale.jpg',reference=True)
        sheet = Image.new('RGB',(1280,720),'#080c12')
        sheet.paste(frame.resize((800,450),Image.Resampling.LANCZOS),(0,100))
        ref.thumbnail((480,400),Image.Resampling.LANCZOS)
        sheet.paste(ref,(800,115))
        draw = ImageDraw.Draw(sheet)
        draw.text((16,12),'station_T2 | DEBRIS FIELD / '+title,fill='#ede6d7',font=font)
        draw.text((16,49),'Left: installed station and detached fittings | Right: accepted T2 plan',fill='#c6ced8',font=small)
        draw.text((16,564),inventory+' | Slow tumble',fill='#c6ced8',font=small)
        review.save(sheet,out/('station_T2_debris_compare'+suffix+'.png'))
    for name in ('station_T2_debris60','station_T2_debris60_t600'):
        review = Review('installed in game')
        frame = review.open(raw/(name+'.png')).convert('RGB').resize((1280,720),Image.Resampling.LANCZOS)
        draw = ImageDraw.Draw(frame)
        draw.rectangle((0,0,1280,67),fill='#10161d')
        draw.text((16,10),'station_T2 | DEBRIS / CAMERA 60 / '+('600 SECONDS' if name.endswith('600') else '0 SECONDS'),fill='#ede6d7',font=font)
        review.save(frame,out/(name+'.png'))
    rows = ['# station_T2 debris: measured placement', '',
            'Loaded geometry check: PASS. '+inventory+'.', '',
            'Added triangles: **%s**; unchanged base: **%s**; combined: **%s**.' %
            (checks['triangles'],checks['base_station_triangles'],checks['combined_triangles']), '',
            'Positions are in station-local Godot X/Y/Z, before the board lift of +3 Y. '
            'The broken stub points toward +Z. Gap is the conservative minimum against all seven cells, '
            'over every station bearing and every tumble angle.', '',
            'Live blocked-cell circumcircle: %.3f units. Lowest fitted ship: %s at Y %.3f. '
            'Highest possible debris vertex after board lift: Y %.3f; vertical gap: %.3f units.' %
            (checks['all_bearings_blocked_radius'],checks['lowest_ship'],checks['lowest_fitted_ship_y'],
             checks['maximum_debris_world_y'],checks['lowest_fitted_ship_y']-checks['maximum_debris_world_y']), '',
            '| Piece | Type | X / Y / Z | Tumble radius | Cell gap | Triangles |',
            '|---|---|---|---|---|---|']
    for row in checks['pieces']:
        rows.append('| %s | %s | %.2f / %.2f / %.2f | %.3f | %.3f | %s |' %
                    (row['name'],row['kind'],*row['position'],row['tumble_radius'],
                     row['blocked_cell_clearance'],row['triangles']))
    rows += ['', 'See debris_checks.json for each piece against each of the seven individual axial cells, '
             'all fitted ship measurements, source hashes and the continuous clearance proof.', '']
    (out/'debris_placement.md').write_text('\n'.join(rows),encoding='utf-8')
    print('T2 DEBRIS PICTURES PASS: 170, 60, plan, two tumble poses')


if __name__ == '__main__': main()
