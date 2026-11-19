"""Compose and publish the issue 870 sheets: python ion870_compose.py RENDER_DIR.

Pass the contract output directory as the optional second argument.
Pass the completed standing-check log as the optional third argument.
The render driver keeps scratch files outside the repo. Published pictures and
their provenance sidecars live beside the ship's other build-sheet evidence.
"""
import sys
sys.dont_write_bytecode = True
import json
import hashlib
from pathlib import Path
import re

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools'))
from picture_provenance import Review

renders = Path(sys.argv[1])
contracts = Path(sys.argv[2]) if len(sys.argv) > 2 else None
standing = Path(sys.argv[3]) if len(sys.argv) > 3 else None
ink = '#e4ebf5'
blue = '#65bfff'
back = '#121822'


def font(n):
    return ImageFont.truetype('C:/Windows/Fonts/arial.ttf', n)


def canvas(title, subtitle):
    im = Image.new('RGB', (1280, 720), back)
    d = ImageDraw.Draw(im)
    d.text((16, 9), title, font=font(28), fill=ink)
    d.text((16, 43), subtitle, font=font(17), fill='#b2c1d4')
    return im


def tile(target, image, box):
    image = ImageOps.contain(image.convert('RGB'), (box[2] - box[0], box[3] - box[1]), Image.Resampling.LANCZOS)
    target.paste(image, (box[0] + (box[2] - box[0] - image.width) // 2,
                         box[1] + (box[3] - box[1] - image.height) // 2))


for code, label, concept in [
    ('hegemony_H10', 'Dominion H10', 'contrib/muse/design/concept_round7_2026_11/hegemony_H10_beauty.jpg'),
    ('hegemony_IM5', 'Iron Mandate IM5', 'contrib/muse/design/iron_mandate_2026_11/round_2/IM5.jpg'),
]:
    folder = ROOT / 'docs/ship_pipeline/build_sheets' / code
    a, b = [json.loads((renders / code / state / 'checks.json').read_text()) for state in ('before', 'after')]
    assert a['inside'] == b['inside'], 'interiors changed'
    assert not any(b['fit'].values()) and b['weapon_match'] == 'PASS'
    for picture in ('ion_weapon_before_after.jpg', 'ion_weapon_cam170.jpg', 'weapon_ion.jpg'):
        review = Review('sheet built')
        if picture == 'ion_weapon_before_after.jpg':
            im = canvas(label + ' | bow ion weapon | run 2', 'Whole ships at the fitted concept camera; BEFORE is main ' + a['source_revision'][:12])
            d = ImageDraw.Draw(im)
            for i, (title, source, reference) in enumerate([
                ('CONCEPT', ROOT / concept, True),
                ('BEFORE | main', renders / code / 'before/concept.png', False),
                ('AFTER | lit accelerator', renders / code / 'after/concept.png', False),
            ]):
                x = 8 + 424 * i
                d.text((x + 6, 70), title, fill=blue, font=font(20))
                tile(im, review.open(source, reference=reference), (x, 100, x + 416, 365))
            for i, state in enumerate(('before', 'after')):
                x = 8 + 640 * i
                d.text((x + 6, 374), state.upper() + ' | bow detail', fill=blue, font=font(19))
                close = review.open(renders / code / state / 'close.png')
                tile(im, close.crop((0, 115, 1100, 515)), (x, 400, x + 624, 596))
        elif picture == 'ion_weapon_cam170.jpg':
            im = canvas(label + ' | camera 170 | native pixels', 'Sheet built | vertical FOV 45 | SHIP_K 1.6 | centre crops from 1920 x 1080; no enlargement')
            d = ImageDraw.Draw(im)
            for name, title, y, crop in [('cam170', 'Bow quarter, yaw 30', 71, (640, 390, 1280, 710)),
                                          ('beam170', 'Port beam, yaw 90', 416, (640, 460, 1280, 620))]:
                for i, state in enumerate(('before', 'after')):
                    d.text((16 + 640 * i, y), state.upper() + ' | ' + title, fill=blue, font=font(19))
                    image = review.open(renders / code / state / (name + '.png'))
                    im.paste(image.crop(crop).convert('RGB'), (640 * i, y + 24))
        else:
            im = canvas(label + ' | I1 ion cannon | run 2', 'Source-authored blue emitter, fainter field contacts, stepped metal coils and an inset muzzle lip')
            tile(im, review.open(renders / code / 'after/close.png'), (0, 68, 1280, 600))
        review.save(im, folder / picture, quality=94)

    for source, destination in [(renders / code / ('after/' + code + '_fit.json'), folder / 'fit.json'),
                                (renders / code / 'after/weapon_match.json', folder / 'weapon_match.json')]:
        destination.write_text(json.dumps(json.loads(source.read_text()), indent=1) + '\n', newline='\n')
    manifest_path = folder / 'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    feature = next(f for f in b['features'] if f['id'] == 'I1')
    mount = next(f for f in manifest['parts'] if f['id'] == 'I1')
    mount.update(what=feature['what'], source='designed', route='hand-built')
    manifest_path.write_text(json.dumps(manifest, indent=1) + '\n', newline='\n')
    fit_path = folder / 'fit_report.md'
    text = fit_path.read_text()
    text = re.sub(r'Tested: [^\n]+', 'Tested: ' + ', '.join(str(v) + ' ' + k.replace('_', ' ') for k, v in b['tested'].items()) + '.', text)
    fit_path.write_text(text, newline='\n')
    table_path = folder / 'feature_table.md'
    text = table_path.read_text()
    text = re.sub(r'^\| I1 \|.*$', '| I1 | ' + feature['what'] + ' | 1 barrel | ' +
                  ('6.5 | 0.00 | -0.08' if code == 'hegemony_H10' else '8.6 | 0.00 | -0.30') +
                  ' | forward | F ion | designed | R287, R289 run 2: lit blue lens, fainter field contacts, metal coils and muzzle lip; beam origin on the lens |', text, flags=re.M)
    # The source-authored accelerator is hand-built; the other fittings still
    # come from the faction kit. State this in the table as well as the manifest.
    lines, in_features = [], False
    for line in text.splitlines():
        if line.startswith('## '):
            in_features = line.startswith('## Feature table')
        if in_features and line.startswith('|'):
            if line.startswith('| ID |'):
                line = '|' + '|'.join(line.strip('|').split('|')[:10]) + '| Route |'
            elif line.startswith('|---'):
                line = '|---|---|---:|---:|---:|---:|---|---|---|---|---|'
            else:
                cells = line.strip('|').split('|')[:10]
                line = '|' + '|'.join(cells) + '| ' + ('hand-built' if cells[0].strip() == 'I1' else 'kit') + ' |'
        lines.append(line)
    text = '\n'.join(lines) + '\n'
    text = text.split('\n## Issue 870, run 2\n')[0]
    text += '\n## Issue 870, run 2\n\n' + '\n'.join('- **' + change[0] + '** ' + change[1]
               for change in b['changes'] if 'R287' in str(change) or 'R289' in str(change)) + '\n'
    table_path.write_text(text, newline='\n')
    record = dict(issue=870, run=2, baseline=a['source_revision'], stage='sheet built',
                  method='Build-sheet CPU; existing Hegemony hblue and hlining zones with ion-only source light materials; no texture bake',
                  before={k: a[k] for k in ('source_sha256', 'outside', 'inside')},
                  after={k: b[k] for k in ('source_sha256', 'outside', 'inside')},
                  interior_geometry_unchanged=True, fit=b['fit'], tested=b['tested'],
                  weapon_match=b['weapon_match'], cameras=b['cameras'],
                  triangle_total=b['outside']['triangles'] + b['inside']['triangles'],
                  limitations=['Sheet evidence only; no new paint bake, game export, install or scene performance measurement.',
                               'The port-beam camera does not face the front lens; the bow-quarter camera shows its read.'])
    record['design_sources_sha256'] = {name: hashlib.sha256((ROOT / 'tools/blender/build_sheets/ships' / (name + '.py')).read_bytes()).hexdigest()
                                       for name in ('hegemony_H10', code)}
    if contracts:
        contract = json.loads((contracts / code / 'sheet_contract_selftest.json').read_text())
        assert contract['ok'], 'contract failed'
        record['contract'] = contract
    if standing:
        raw = standing.read_bytes()
        log = raw.decode('utf-16') if raw.startswith(b'\xff\xfe') else raw.decode('utf-8-sig')
        rows = re.findall(r'^([^|\n]+) \| (PASS|KNOWN|FAIL|SKIP) \| ([\d.]+) \| (.*)$', log.replace('\r\n', '\n'), re.M)
        assert rows, 'standing checks have not finished'
        record['standing_checks'] = dict(command='node contrib/opus/tools/run_all_checks.js',
                                         counts={state: sum(r[1] == state for r in rows) for state in ('PASS', 'KNOWN', 'FAIL', 'SKIP')},
                                         rows=[dict(check=r[0], result=r[1], seconds=float(r[2]), detail=r[3]) for r in rows])
    (folder / 'ion_weapon_checks.json').write_text(json.dumps(record, indent=2) + '\n', newline='\n')
    print(code, record['triangle_total'], b['fit'], b['weapon_match'])
