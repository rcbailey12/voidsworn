"""The one way a ship build's picture goes to Ryan for a pick or a publish OK (issue 1517).

Nov 21 2026: Navy O2 and O3 went to Ryan for a publish OK while stage 5's detail check reported normal relief 1.54 and 1.45
against a 3.5 floor; Ryan caught the clay look himself ("Just make sure the level of detail is on both so they don't look like
clay"). Nothing on the way to him read that line. This tool builds the pick or publish sheet from a ship job's collected
output and refuses, writing nothing, unless the job passed and its stage 5 surface-detail verdict
(tools/recipe/detail_check.py, in out/recipe/log_detail.txt) is a PASS or a dated opt-out from Ryan. The sheet prints the
three detail numbers and their floors under the pictures, and is saved with its revision and stage
(tools/picture_provenance.py).

usage: python tools/recipe/offer_sheet.py JOB_OUT OUT.jpg [--stage "installed in game"] [--title TEXT] [PICTURE ...]
  JOB_OUT   the ship job's out folder (result.txt and recipe/ inside; a board/pc-out-* relay's <job>_out folder)
  PICTURE   the pictures to show, left to right (a concept, the job's renders or in-game shots); with none, the job's own
            r/CELL_concept_cl.png, r/CELL_hero.png and the first in-game shots (shots/) are used
  --stage   'paint proof' (the recipe's renders) or 'installed in game' (default, the in-game shots)
Exit 0 with "offer sheet written: OUT", or exit 1 with "offer sheet REFUSED: <why>" and no file written.
"""
import argparse
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
from detail_check import detail_line, detail_verdict  # noqa: E402

HEIGHT = 720          # AGENTS.md: pictures for Ryan are no taller than 720 px
CAPTION = 72          # the caption band on top; picture_provenance stamps the bottom left


class Refused(Exception):
    pass


def gate(job_out):
    """the job's result and detail verdict; raises Refused unless the job passed and its detail is a PASS or OPT-OUT"""
    job_out = Path(job_out)
    res = job_out / 'result.txt'
    if not res.is_file():
        raise Refused(f'{res} is missing: not a ship job output folder')
    lines = [l.strip() for l in res.read_text(encoding='utf-8', errors='replace').splitlines() if l.strip()]
    if any(l.startswith('done FAILED') for l in lines) or not any(l.startswith('done PASS') for l in lines):
        raise Refused(f'{res} is not a passed ship job (no done PASS, or a done FAILED)')
    log = job_out / 'recipe' / 'log_detail.txt'
    if not log.is_file():
        raise Refused(f'{log} is missing: this build has no stage 5 surface-detail verdict')
    text = log.read_text(encoding='utf-8', errors='replace')
    verdict = detail_verdict(text)
    if verdict not in ('PASS', 'OPT-OUT'):
        first = next((l for l in text.splitlines() if 'detail check' in l), 'no verdict line')
        raise Refused(f'the surface detail did not pass (issue 1517): {first.strip()}')
    head = lines[0].split() if lines else []
    commit = next((l[len('commit='):] for l in lines if l.startswith('commit=')), '')
    return dict(ship=head[1] if len(head) > 1 else '?', code=head[2] if len(head) > 2 else '?', commit=commit,
                verdict=verdict, line=detail_line(text))


def default_pictures(job_out):
    rec = Path(job_out) / 'recipe'
    pics = sorted((rec / 'r').glob('*_concept_cl.png'))[:1] + [p for p in sorted((rec / 'r').glob('*_hero.png'))[:1]]
    for shots in (Path(job_out) / 'shots', rec / 'shots'):
        pics += sorted(p for p in shots.glob('**/*.png'))[:2] if shots.is_dir() else []
    return pics


def build(job_out, out, pictures=None, stage='installed in game', title=None):
    from PIL import Image, ImageDraw, ImageFont
    from picture_provenance import open_picture, save_picture, verify
    info = gate(job_out)
    pics = [Path(p) for p in (pictures or default_pictures(job_out))]
    if not pics:
        raise Refused('no pictures to show')
    missing = [str(p) for p in pics if not p.is_file()]
    if missing:
        raise Refused('missing pictures: ' + ', '.join(missing))
    h = HEIGHT - CAPTION
    tiles, sources = [], []
    for p in pics:
        im = open_picture(p).convert('RGB')
        tiles.append(im.resize((max(1, round(im.width * h / im.height)), h), Image.LANCZOS))
        try:
            rec = verify(p)
            if rec:
                sources.append(rec)
        except (ValueError, OSError):
            pass
    sheet = Image.new('RGB', (sum(t.width for t in tiles), HEIGHT), (16, 16, 20))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, CAPTION))
        x += t.width
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype('DejaVuSans.ttf', 18)
    except OSError:
        font = ImageFont.load_default()
    name = title or '%s %s (job commit %s)' % (info['ship'], info['code'], info['commit'][:12] or '?')
    numbers = info['line'].split(': ', 1)[-1]
    d.text((10, 8), name + '  |  stage: ' + stage, fill=(235, 235, 235), font=font)
    d.text((10, 36), 'detail %s: %s' % (info['verdict'], numbers[:160]), fill=(170, 230, 170), font=font)
    save_picture(sheet, out, stage, sources=sources or None, repo=HERE.parent.parent, quality=90)
    return info


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('job_out')
    ap.add_argument('out')
    ap.add_argument('pictures', nargs='*')
    ap.add_argument('--stage', default='installed in game')
    ap.add_argument('--title')
    a = ap.parse_args(argv)
    try:
        build(a.job_out, a.out, a.pictures, a.stage, a.title)
    except Refused as e:
        print('offer sheet REFUSED: %s' % e)
        return 1
    print('offer sheet written: %s' % a.out)
    return 0


if __name__ == '__main__':
    sys.exit(main())
