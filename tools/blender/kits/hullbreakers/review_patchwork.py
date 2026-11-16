"""Issue 875 proof. Run with ordinary Python: review_patchwork.py OUT [A18 A19 A20 KB1CC].

Scratch bakes and logs go to OUT. Comparison JPGs and a measured report go to
docs/shots/look_bench/hullbreaker_patchwork and the runner's issue-875/shots.
The existing recipe does the paint and the existing sheet renderer sets cameras.
"""
import json
import hashlib
import os
from pathlib import Path
import subprocess
import sys

REPO = Path(__file__).resolve().parents[4]
PC = REPO.parents[1]
OUT = Path(sys.argv[1]).resolve()
CHECK_ONLY = '--check-only' in sys.argv[2:]
CODES = [a for a in sys.argv[2:] if a != '--check-only'] or ['A18', 'A19', 'A20', 'KB1CC']
BLENDER = PC / 'blender/blender-4.5.14-windows-x64/blender.exe'
SHOTS = REPO.parent / 'issue-875/shots'
DEST = REPO / 'docs/shots/look_bench/hullbreaker_patchwork'


def revision():
    files = ['tools/blender/kits/hullbreakers/' + name for name in
             ('stack.py', 'plating.py', 'review_patchwork.py', 'render_patchwork_close.py')]
    files += ['tools/blender/build_sheets/ships/corsair_KB1CC.py']
    sources = {name: hashlib.sha256((REPO / name).read_bytes()).hexdigest() for name in files}
    head = subprocess.check_output(['git', 'rev-parse', '--short=8', 'HEAD'], cwd=REPO, text=True).strip()
    stamp = hashlib.sha256(json.dumps(sources, sort_keys=True).encode()).hexdigest()[:10]
    return dict(label=f'{head}+875-r2-{stamp}', base=head, source_sha256=sources)


def run(label, args, env=None):
    log = OUT / (label + '.log')
    with log.open('w') as stream:
        result = subprocess.run(args, cwd=REPO, env=env, stdout=stream, stderr=subprocess.STDOUT)
    if result.returncode:
        raise RuntimeError(f'{label}: exit {result.returncode}; see {log}')
    print('PASS', label, flush=True)


def blender(label, args, env=None):
    # tmo owns a shared GPU claim and obeys gpu_go.txt for every Blender call.
    run(label, [str(REPO / 'tools/pc/tmo.bat'), '21600', str(BLENDER), '-b',
                '--python-exit-code', '1', *args], env)


def sheets(code, job, concept, rev):
    from PIL import Image, ImageDraw, ImageFont, ImageOps
    import shutil
    font_path = 'C:/Windows/Fonts/segoeui.ttf'
    font = lambda n: ImageFont.truetype(font_path, n)
    sheet = Image.new('RGB', (1280, 720), (14, 15, 18))
    draw = ImageDraw.Draw(sheet)
    title = 'dark, weathered Hullbreaker armour | R292' if code == 'KB1CC' else 'welded Hullbreaker patchwork | R289'
    draw.text((12, 5), f'{code}: {title}', font=font(23), fill='white')
    draw.text((12, 36), f'PAINT PROOF | Rev {rev["label"]} | Game light, lift 1.25, 2048 maps. Same camera.',
              font=font(16), fill=(177, 181, 188))

    def fit(im, box):
        im = im.convert('RGB'); im.thumbnail((box[2], box[3]), Image.Resampling.LANCZOS)
        sheet.paste(im, (box[0] + (box[2] - im.width) // 2, box[1] + (box[3] - im.height) // 2))

    draw.text((12, 62), code + ' accepted concept', font=font(17), fill=(236, 187, 112))
    draw.text((650, 62), code + ' painted build, same paint_full camera', font=font(17), fill=(236, 187, 112))
    fit(Image.open(concept), (0, 86, 636, 405))
    beauty = Image.open(job / 'paint/paint_beauty.png')
    fit(beauty, (644, 86, 636, 405))
    if code == 'KB1CC':
        draw.text((12, 495), 'A18 accepted paint, PR 883 (unchanged)', font=font(16), fill=(236, 187, 112))
        ref = Image.open(DEST / 'A18_patchwork.jpg')
        fit(ref.crop((644, 86, 1280, 491)), (0, 519, 400, 196))
    else:
        draw.text((12, 495), 'A16 accepted paint reference (unchanged)', font=font(16), fill=(236, 187, 112))
        ref = Image.open(REPO / 'docs/ship_pipeline/build_sheets/corsair_A16/paint/A16_paint_full.jpg')
        fit(ref.crop((644, 62, 1280, ref.height)), (0, 519, 400, 196))
    draw.text((414, 495), code + ' deck: worn edges, soot seams and bedded welded laps', font=font(16), fill=(236, 187, 112))
    deck = ImageOps.fit(Image.open(job / 'close/paint_deck.png').convert('RGB'),
                        (868, 196), method=Image.Resampling.LANCZOS)
    sheet.paste(deck, (410, 519))
    name = code + '_patchwork.jpg'
    sheet.save(DEST / name, quality=93)
    shutil.copy2(DEST / name, SHOTS / name)


def painted_tones(job):
    """Descriptive painted-output values beside the pictures, never a gate."""
    import numpy as np
    from PIL import Image

    def measure(im):
        rgb = np.asarray(im.convert('RGB'), dtype=float)
        # A black sky is shared by these proofs. Drop it with a stated threshold.
        rgb = rgb[rgb.max(axis=2) > 20]
        y = rgb @ np.array([.2126, .7152, .0722])
        red = (rgb[:, 0] > 1.2 * rgb[:, 1]) & (rgb[:, 0] > 1.15 * rgb[:, 2])
        return dict(luma_p10_p50_p90=[round(float(v), 1) for v in np.percentile(y, [10, 50, 90])],
                    red_pixel_percent=round(float(red.mean() * 100), 1))

    ref = Image.open(DEST / 'A18_patchwork.jpg').crop((644, 86, 1280, 491))
    a16 = Image.open(REPO / 'docs/ship_pipeline/build_sheets/corsair_A16/paint/A16_paint_full.jpg')
    return dict(method='sRGB luma 0.2126R+0.7152G+0.0722B, pixels with max(R,G,B)>20; red R>1.2G and R>1.15B. Different shapes and framing: review evidence, no gate.',
                KB1CC=measure(Image.open(job / 'paint/paint_beauty.png')),
                A18_accepted=measure(ref),
                A16_accepted=measure(a16.crop((644, 62, 1280, a16.height))))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    DEST.mkdir(parents=True, exist_ok=True)
    SHOTS.mkdir(parents=True, exist_ok=True)
    report_path = DEST / 'checks.json'
    report = json.loads(report_path.read_text()) if report_path.exists() else {}
    rev = revision()
    env = os.environ.copy()
    env['PYTHONDONTWRITEBYTECODE'] = '1'
    env['PYTHONPYCACHEPREFIX'] = str(OUT / 'pycache')
    env['PC_GPU_ISSUE'] = '875-patchwork'
    # This is a capture job, not a nested model/watchdog session.
    for key in ('TMO_REPO', 'TMO_OUT', 'TMO_LOG', 'TMO_ERR_LOG'):
        env.pop(key, None)
    for code in CODES:
        job = OUT / code; job.mkdir(exist_ok=True)
        ship_json = REPO / f'tools/recipe/ships/corsair_{code}.json'
        ship = json.loads(ship_json.read_text())
        concept = REPO / ship['concept']
        env['R209_SHIP'] = str(ship_json)
        blender(code + '_geometry', ['-P', str(Path(__file__).with_name('check_patchwork.py')), '--',
                                    str(job / 'geometry.json'), code], env)
        if CHECK_ONLY:
            continue
        blender(code + '_bake', ['-P', 'tools/blender/r209/bake_sheet.py', '--', str(job),
                                'none', 'none', code, '2048', '32'], env)
        if code == 'KB1CC':
            # This paint_full uses issue 853's accepted 35/30 preview, not the
            # head-on outline-fit camera. Its saved capture script owns it.
            blender(code + '_paint', [str(job / (code + '.blend')), '-P',
                                     'docs/shots/look_bench/corsair_KB1CC/capture.py',
                                     '--', 'render', str(job / 'paint')], env)
        else:
            blender(code + '_paint', [str(job / (code + '.blend')), '-P', 'tools/blender/build_sheets/paint_sheet.py',
                                     '--', str(job / 'paint'), 'corsair_' + code, str(concept),
                                     'samples=32', 'scale=0.5', 'gpu=1'], env)
        blender(code + '_close', [str(job / (code + '.blend')), '-P', str(Path(__file__).with_name('render_patchwork_close.py')),
                                 '--', str(job / 'close'), 'corsair_' + code, str(concept),
                                 'samples=32', 'scale=0.5', 'only=deck,flank', 'gpu=1'], env)
        blender(code + '_surface', [str(job / (code + '.blend')), '-P', 'tools/recipe/surface_check.py',
                                   '--', str(job / 'surface')], env)
        for check in ('licences', 'lights'):
            run(code + '_' + check, [sys.executable, 'tools/recipe/standing.py', check,
                                    '--ship', str(ship_json), '--job', str(job)], env)
        sheets(code, job, concept, rev)
        data = json.loads((job / (code + '.json')).read_text())
        surface = json.loads((job / 'surface/surface_check.json').read_text())
        assert surface['ok'], f'{code}: exposed unpainted surface or room colour'
        report[code] = dict(geometry=json.loads((job / 'geometry.json').read_text()),
                            triangles=data['triangles'], objects=data['objects'],
                            surfaces=data['surfaces'],
                            paint_device=data['paint']['device'], maps=data['res'],
                            paint_seconds=data['paint']['stack_seconds'],
                            stack_regression='PASS', licences='PASS', lights='PASS',
                            surface=surface)
        report[code]['revision'] = rev
        report[code]['stage'] = 'paint proof, not installed or accepted'
        if code == 'KB1CC':
            report[code]['painted_tones'] = painted_tones(job)
            report[code]['capture'] = json.loads((job / 'paint/capture.json').read_text())
        print('DONE', code, flush=True)
        (DEST / 'checks.json').write_text(json.dumps(report, indent=2))
        (SHOTS / 'checks.json').write_text(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
