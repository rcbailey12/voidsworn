"""Bake issue 876 run 2 pictures from build.py render folders, without moving the camera.

Usage: python r292_review.py RUN0 RUN1 RUN2 REPO OUT [--label-sheet]
Run 0: source at 2ca44f51. Run 1: source at ed59692f (PR 884).
Run 2: current design file; its SHA256 identifies the uncommitted revision.
All three use the saved A17 beauty camera, Cycles CPU and 16 samples.
After publish.py, --label-sheet also labels the rebuilt sheet pictures in OUT.
Run that option once per fresh publication so labels are not added twice.
"""
import hashlib
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

run0, run1, run2, repo, out = map(Path, sys.argv[1:6])
out.mkdir(parents=True, exist_ok=True)
revision = hashlib.sha256((repo / 'tools/blender/build_sheets/ships/corsair_A17.py').read_bytes()).hexdigest()[:8]
BG = (36, 36, 38)
INK = (238, 232, 220)
DIM = (195, 192, 185)
ACCENT = (238, 177, 100)


def font(size):
    for path in ('C:/Windows/Fonts/arial.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            pass
    return ImageFont.load_default()


def flat(path):
    im = Image.open(path).convert('RGBA')
    base = Image.new('RGBA', im.size, BG + (255,))
    base.alpha_composite(im)
    return base.convert('RGB')


def place(canvas, im, box):
    x, y, w, h = box
    im = im.copy()
    im.thumbnail((w, h), Image.Resampling.LANCZOS)
    canvas.paste(im, (x + (w - im.width) // 2, y + (h - im.height) // 2))


concept = flat(repo / 'contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg')
labels = ('Run 0 | 2ca44f51', 'Run 1 | ed59692f', 'Run 2 | ' + revision)
folders = (run0, run1, run2)
sheet = Image.new('RGB', (1280, 720), BG)
d = ImageDraw.Draw(sheet)
d.text((16, 12), 'corsair_A17 | raised rocket spine | issue 876 run 2 / R292', font=font(27), fill=INK)
columns = [('Concept | accepted R201', 'Concept reference', concept)] + [
    (label, 'Unpainted sheet', flat(folder / 'beauty_cam.png')) for label, folder in zip(labels, folders)]
for i, (label, stage, im) in enumerate(columns):
    x = 16 + i * 316
    d.text((x, 55), label, font=font(19), fill=ACCENT)
    d.text((x, 80), stage, font=font(18), fill=DIM)
    place(sheet, im, (x, 108, 300, 230))
    d.text((x, 362), 'Support detail | same window', font=font(18), fill=DIM)
    place(sheet, im.crop((500, 150, 1200, 620)), (x, 395, 300, 255))
d.text((16, 675), 'Same beauty camera and lighting | support roof: run 0 0.90, run 1 1.20, run 2 1.56', font=font(20), fill=INK)
sheet.save(out / 'r292_revisions.jpg', quality=93)

sheet = Image.new('RGB', (1280, 720), BG)
d = ImageDraw.Draw(sheet)
d.text((16, 12), 'corsair_A17 | side and three-quarter | issue 876 run 2 / R292', font=font(27), fill=INK)
for i, (label, folder) in enumerate(zip(labels, folders)):
    x = 16 + i * 422
    d.text((x, 55), label, font=font(21), fill=ACCENT)
    d.text((x, 83), 'Unpainted sheet | true side', font=font(18), fill=DIM)
    place(sheet, flat(folder / 'side.png'), (x, 112, 404, 222))
    d.text((x, 360), 'Unpainted sheet | three-quarter', font=font(18), fill=DIM)
    place(sheet, flat(folder / 'threequarter.png'), (x, 395, 404, 253))
d.text((16, 680), 'One scale per view | fixed weapons and interiors | plated steps join the foredeck and ramp', font=font(20), fill=INK)
sheet.save(out / 'r292_side_threequarter.jpg', quality=93)
if '--label-sheet' in sys.argv[6:]:
    Image.MAX_IMAGE_PIXELS = 150_000_000  # our own full-resolution build sheet
    for name in ('beauty_vs_blockout', 'bow', 'cells', 'cutaway', 'fit_view', 'outline_check', 'preview',
                 'sheet', 'side', 'side_by_side', 'stern', 'threequarter', 'top', 'underside',
                 'weapon_review', 'weapon_flak', 'weapon_scatter'):
        path = out / (name + '.jpg')
        im = Image.open(path).convert('RGB')
        size = max(12, min(120, im.width // 45))
        banner = 2 * size
        labelled = Image.new('RGB', (im.width, im.height + banner), BG)
        labelled.paste(im, (0, banner))
        ImageDraw.Draw(labelled).text((size // 2, size // 2),
                                     'corsair_A17 | run 2 / ' + revision + ' | unpainted sheet',
                                     font=font(size), fill=INK)
        if im.height <= 720 and labelled.height > 720:
            labelled = labelled.resize((round(labelled.width * 720 / labelled.height), 720), Image.Resampling.LANCZOS)
        labelled.save(path, quality=90)
print('WROTE', out / 'r292_revisions.jpg', out / 'r292_side_threequarter.jpg')
