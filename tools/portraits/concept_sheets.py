# R64 concept round sheets (sandbox): one phone sheet per species from the c64 renders.
#   python3 tools/portraits/concept_sheets.py <c64_png_dir> <out_dir>
# Each take (A to D) gets a block of six renders: Z-Image seeds 11, 23, 37, 51 and Qwen seeds 11, 51. The two seed 51 renders
# are tagged in gold (Ryan leans to seed 51). Labels are plain words for Ryan's phone; the file names give the exact render.
import os, sys, glob
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from post import font
W = 1080; BG = (14, 14, 18); GAP = 10; COLS = 3; C = (W - GAP * (COLS + 1)) // COLS
CELLS = [('zit', 11), ('zit', 23), ('zit', 37), ('zit', 51), ('qie', 11), ('qie', 51)]
SPECIES = {
 'hb': ('Hullbreakers: "void hunters"', 'Concept round. Pick a take (A to D) and a render; every Hullbreaker gets repainted in it.', [
   ('A', 'Plated hunter', 'jaw closed, split seam down the chin, four amber eyes, grey-black mane'),
   ('B', 'Jaw open', 'jaw halves spread sideways in a snarl, red eyes, black mane'),
   ('C', 'Back to the cold', 'looking back over the shoulder, frosted ridged back plates, rust mane'),
   ('D', 'Old pack-lord', 'scarred face plates, glowing heat pits, violet machine trophies, grey mane')]),
 'gw': ('Glasswrights: "living prism"', 'Concept round. Pick a take (A to D) and a render; every Glasswright gets repainted in it.', [
   ('A', 'Clear vessel', 'long faceted head, colour bands pulsing across it, crystal robes'),
   ('B', 'Prism crown', 'facets rise into a tall crest that fans light into a rainbow'),
   ('C', 'Soft glass', 'milky jellyfish-soft flesh, crystal growing on neck and shoulders'),
   ('D', 'Light-shaper', 'long fingers shaping a glowing shard, colour rippling over the head')]),
}

def find(src, key, model, seed):
    g = glob.glob(os.path.join(src, '%s_%s_s%d_*.png' % (key, model, seed)))
    return g[0] if g else None

def sheet(src, out, sp):
    title, sub, takes = SPECIES[sp]
    lab = 74; blk = lab + 2 * (C + GAP); top = 130
    im = Image.new('RGB', (W, top + len(takes) * blk + GAP), BG); d = ImageDraw.Draw(im)
    d.text((28, 24), title, fill=(240, 240, 240), font=font(40, True)); d.text((28, 78), sub, fill=(170, 170, 170), font=font(22))
    for r, (letter, name, words) in enumerate(takes):
        y0 = top + r * blk; key = '%s_%s' % (sp, letter.lower())
        d.text((GAP, y0 + 4), '%s. %s' % (letter, name), fill=(255, 220, 60), font=font(30, True))
        d.text((GAP, y0 + 42), words, fill=(200, 200, 200), font=font(22))
        for j, (m, s) in enumerate(CELLS):
            x = GAP + (j % COLS) * (C + GAP); y = y0 + lab + (j // COLS) * (C + GAP)
            p = find(src, key, m, s)
            if p: im.paste(Image.open(p).convert('RGB').resize((C, C), Image.LANCZOS), (x, y))
            else: d.rectangle((x, y, x + C, y + C), outline=(80, 80, 80), width=2); d.text((x + 20, y + C // 2), 'not rendered', fill=(150, 150, 150), font=font(22))
            tag = '%s%d' % (letter, j + 1); gold = s == 51
            if gold: d.rectangle((x, y, x + C - 1, y + C - 1), outline=(255, 200, 60), width=5)
            d.text((x + 10, y + 8), tag + ('  s51' if gold else ''), fill=(255, 214, 90) if gold else (255, 255, 255), font=font(24, True), stroke_width=3, stroke_fill=(0, 0, 0))
    p = os.path.join(out, 'c64_%s.webp' % ('hullbreakers' if sp == 'hb' else 'glasswrights'))
    im.save(p, 'WEBP', quality=82, method=6); print(p, im.size)

if __name__ == '__main__':
    src, out = sys.argv[1], sys.argv[2]; os.makedirs(out, exist_ok=True)
    for sp in SPECIES: sheet(src, out, sp)
