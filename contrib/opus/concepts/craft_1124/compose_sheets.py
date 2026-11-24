"""Issue 1943: lay out the torpedo concept sheets and the strike craft status sheet.

Reads the renders torpedo_sheets.py wrote to a scratch folder, stamps each raw render
('sheet built', new render), then composes 1280 x 720 (or shorter) sheets with a code
name under every option and saves them, stamped, to contrib/opus/concepts/craft_1124/sheets
and to an optional shots folder (picture and sidecar copied unchanged).

Usage: python compose_sheets.py <scratch> [shots_dir]
"""
import json
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
sys.path.insert(0, str(REPO / 'tools'))
import picture_provenance as pp  # noqa: E402

STAGE = 'sheet built'
W = 1280
FOOT = 104          # room for the provenance stamp (about 98 px at this width)
BG = (24, 28, 36)
INK = (236, 230, 218)
DIM = (160, 166, 178)
GOLD = (232, 181, 107)

SHEETS = {
    'hegemony': dict(item=5, title='Meridian Directorate (hegemony) torpedo',
                     note='Concept only: the Directorate has no torpedo in its weapon pool today.'),
    'chorus': dict(item=6, title='Chorus torpedo (bio-munition, no metal)',
                   note='Concept only: the Chorus has no torpedo in its weapon pool today.'),
    'deathless': dict(item=7, title='Eclipse (deathless) torpedo, violet accents only',
                      note='Concept only: Eclipse has no torpedo in its weapon pool today.'),
}
STATUS = ['voidsworn_SF3', 'voidsworn_SB4', 'hegemony_HF1D', 'corsair_KB1CC']
STATUS_ITEM = {'voidsworn_SF3': 1, 'voidsworn_SB4': 2, 'hegemony_HF1D': 3, 'corsair_KB1CC': 4}


def font(size, bold=False):
    for name in (('arialbd.ttf' if bold else 'arial.ttf'), 'DejaVuSans.ttf'):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def fit(img, w, h):
    img = img.convert('RGBA')
    img.thumbnail((w, h), Image.Resampling.LANCZOS)
    return img


def on_white(img):
    """Renders have a transparent or white backdrop; put them on a light card."""
    card = Image.new('RGBA', img.size, (226, 228, 232, 255))
    card.alpha_composite(img)
    return card.convert('RGB')


def centre_text(draw, box, text, fnt, fill):
    x0, y0, x1, _ = box
    tw = draw.textlength(text, font=fnt)
    draw.text((x0 + (x1 - x0 - tw) / 2, y0), text, font=fnt, fill=fill)


def stamped_open(review, path):
    # Stamp a fresh render once. A render that already carries a valid stamp is reused as is:
    # stamping it again would bury the first strip under the second.
    try:
        pp.verify(path)
    except Exception:
        pp.stamp_file(path, STAGE, repo=REPO, new_render=True)
    return review.open(path)


def save(review, sheet, name, out_dirs):
    first = out_dirs[0] / name
    review.save(sheet, first)
    pp.verify(first)
    for extra in out_dirs[1:]:
        extra.mkdir(parents=True, exist_ok=True)
        shutil.copy2(first, extra / name)
        shutil.copy2(pp.sidecar(first), pp.sidecar(extra / name))
        pp.verify(extra / name)
    print('[1943] wrote', name, sheet.size)


def torpedo_sheet(scratch, fac, out_dirs):
    info = SHEETS[fac]
    folder = scratch / fac
    meta = json.loads((folder / 'sheet.json').read_text())
    bodies = json.loads((folder / 'bodies.json').read_text())
    review = pp.Review(STAGE)
    cells = [stamped_open(review, folder / ('close_' + code.replace('-', '_') + '.png')) for code in meta['order']]
    strip = stamped_open(review, folder / 'scale_strip.png')

    H = 720
    sheet = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(sheet)
    d.text((20, 8), 'Item %d: %s' % (info['item'], info['title']), font=font(24, True), fill=GOLD)
    d.text((W - 20 - d.textlength('Issue 1943, pick one', font=font(16)), 14), 'Issue 1943, pick one',
           font=font(16), fill=DIM)

    cw, ch, gap = 380, 270, 30
    x0 = (W - 3 * cw - 2 * gap) // 2
    for i, (code, img) in enumerate(zip(meta['order'], cells)):
        x = x0 + i * (cw + gap)
        card = on_white(fit(img, cw, ch))
        sheet.paste(card, (x + (cw - card.width) // 2, 44))
        label = '%s  %s' % (code, bodies[code]['label'])
        centre_text(d, (x, 44 + ch + 4, x + cw, 0), label, font(20, True), INK)

    lname, llen, ldesc = meta['launcher']
    d.text((20, 346), 'At game size beside its launcher: %s (%s, length %s). Options top to bottom: %s.'
           % (ldesc, lname, llen, ', '.join(meta['order'])), font=font(16), fill=INK)
    band = on_white(fit(strip, W - 40, 616 - 372))
    sheet.paste(band, ((W - band.width) // 2, 370))

    fx = 770
    d.text((fx, H - FOOT + 10), info['note'], font=font(15), fill=DIM)
    d.text((fx, H - FOOT + 32), 'Built from the faction part kit, painted with its hull stack.', font=font(15), fill=DIM)
    d.text((fx, H - FOOT + 54), 'Torpedo length in game about %.2f (launcher %s).' % (meta['game_len'], llen),
           font=font(15), fill=DIM)
    save(review, sheet, 'sheet_1943_item%d_%s_torpedo.png' % (info['item'], fac), out_dirs)


def status_sheet(scratch, out_dirs):
    manifest = json.loads((REPO / 'godot/assets/ships/manifest.json').read_text(encoding='utf-8'))
    review = pp.Review(STAGE)
    imgs = [stamped_open(review, scratch / 'status' / ('status_%s.png' % c)) for c in STATUS]
    cw, ch, gap = 300, 225, 20
    H = 44 + ch + 70 + FOOT
    sheet = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(sheet)
    d.text((20, 8), 'Items 1 to 4: strike craft already built and in the game (no new options needed)',
           font=font(22, True), fill=GOLD)
    x0 = (W - 4 * cw - 3 * gap) // 2
    for i, (code, img) in enumerate(zip(STATUS, imgs)):
        x = x0 + i * (cw + gap)
        card = on_white(fit(img, cw, ch))
        sheet.paste(card, (x + (cw - card.width) // 2, 44))
        row = manifest['ships'][code]
        centre_text(d, (x, 44 + ch + 6, x + cw, 0), 'Item %d  %s' % (STATUS_ITEM[code], code), font(18, True), INK)
        centre_text(d, (x, 44 + ch + 32, x + cw, 0), '%s, length %s' % (row['game_ship'], row['length_world']),
                    font(15), DIM)
    fx = 770
    d.text((fx, H - FOOT + 10), 'Each has a manifest row and installed model.', font=font(15), fill=DIM)
    d.text((fx, H - FOOT + 32), 'Rendered from the installed glb.', font=font(15), fill=DIM)
    save(review, sheet, 'status_1943_items1to4_strike_craft.png', out_dirs)


def main():
    scratch = Path(sys.argv[1])
    out_dirs = [HERE / 'sheets'] + ([Path(sys.argv[2])] if len(sys.argv) > 2 else [])
    out_dirs[0].mkdir(parents=True, exist_ok=True)
    for fac in SHEETS:
        torpedo_sheet(scratch, fac, out_dirs)
    status_sheet(scratch, out_dirs)


if __name__ == '__main__':
    main()
