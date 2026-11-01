# R64 concept round sheets (sandbox): one phone sheet per species, curated from the c64, c64b and c64c renders.
#   python3 tools/portraits/concept_sheets.py <PORTRAITS_dir> <out_dir>      PORTRAITS_dir holds c64b\ and c64c\ as on the PC
# Round 1 (c64) is not shown: both models drew literal bears, werewolves and skull trophies, and faced, nude Glasswrights.
# Each take (A to D) is one row of three renders; seed 51 renders are tagged in gold (Ryan leans to seed 51). Labels are plain
# words for Ryan's phone: what the take gets right and, honestly, what it misses. Cell tags (A1, A2...) are what Ryan picks by.
import os, sys
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from post import font
W = 1080; BG = (14, 14, 18); GAP = 10; COLS = 3; C = (W - GAP * (COLS + 1)) // COLS
SPECIES = {
 'hullbreakers': ('Hullbreakers: "void hunters"', 'Pick a take and a picture (for example A2). Every Hullbreaker gets repainted in it.', [
   ('A', 'Scaled hunter', ['fur mane and shoulder hump, scaled plated face, row of small eyes', 'clean digital finish, not oil paint'],
    ['c64c/hb_b_qie_s51', 'c64c/hb_d_qie_s51', 'c64c/hb_c_qie_s51']),
   ('B', 'Helmet face', ['smooth plated face like a helmet, four eyes in a row, mane behind', 'reads more reptile than beast'],
    ['c64b/hb_a_qie_s51', 'c64b/hb_b_qie_s51', 'c64b/hb_d_qie_s51']),
   ('C', 'Frilled hunter', ['oil paint like the other portraits, a plated frill for a head, tusks', 'little mane, no seed 51 that worked'],
    ['c64b/hb_d_zit_s37', 'c64b/hb_a_zit_s37', 'c64b/hb_b_zit_s37']),
   ('D', 'Painted maned hunter', ['oil paint, rust mane rimed with frost, heavy hump', 'the face is close to a film monster'],
    ['c64c/hb_c_zit_s51', 'c64c/hb_c_zit_s11', 'c64c/hb_c_zit_s37'])]),
 'glasswrights': ('Glasswrights: "living prism"', 'Pick a take and a picture (for example A1). Every Glasswright gets repainted in it.', [
   ('A', 'Mirror face', ['no face at all: one mirror facet, light running through glass flesh', 'clean digital finish, not oil paint'],
    ['c64c/gw_a_qie_s51', 'c64c/gw_b_qie_s51', 'c64c/gw_d_qie_s51']),
   ('B', 'Warm core', ['faceless too, with a warm light in the chest, so it reads as alive', 'clean digital finish, not oil paint'],
    ['c64c/gw_c_qie_s51', 'c64c/gw_c_qie_s11', 'c64b/gw_c_qie_s51']),
   ('C', 'Painted living glass', ['oil paint like the other portraits, softer and more ethereal', 'a faint face still shows inside the glass head'],
    ['c64b/gw_b_zit_s51', 'c64b/gw_a_zit_s11', 'c64b/gw_d_zit_s11'])]),
}

# R64 check round (k64, k64b) after Ryan's picks (Nov 1 06:02): Hullbreakers A1, Glasswrights A made organic, pushed to oil paint.
#   python3 tools/portraits/concept_sheets.py <PORTRAITS_dir> <out_dir> check      PORTRAITS_dir holds c64c\, k64\ and k64b\
CHECK = {
 'hullbreakers': ('Hullbreakers check: A1 in oil paint', 'Gold = seed 51. Row B is what every Hullbreaker gets repainted in.', [
   ('A', 'Your pick A1, pushed toward oil paint', ['the same creature, brushwork and darker oil tones', 'still a bare grey chest (A1 had it); new paintings cover it'],
    ['c64c/hb_b_qie_s51', 'k64/hb_a1_p55_zi2i_s51', 'k64b/hb_a1_p45_zi2i_s51']),
   ('B', 'The repaint look', ['mane, hunched bulk, plated face, chest under the harness', 'face plates still a bit metallic; split jaw shows only in a snarl'],
    ['k64b/hb_snarl2_qie_s51', 'k64b/hb_snarl2_p50_zi2i_s51', 'k64b/hb_calm2_p50_zi2i_s51']),
   ('C', 'Too far, not used', ['more oil paint than B', 'the head turns into a long domed film-monster head'],
    ['k64/hb_snarl_zit_s51', 'k64/hb_calm_p65_zi2i_s51', 'k64/hb_calm_zit_s51'])]),
 'glasswrights': ('Glasswrights check: organic, not glass', 'Gold = seed 51. Row B is what every Glasswright gets repainted in.', [
   ('A', 'Your pick A, and two misses', ['A (left) is all glass; the fix adds living flesh', 'middle: an elf face under a visor; right: lips under the gem'],
    ['c64c/gw_a_qie_s51', 'k64/gw_speak_p50_zi2i_s51', 'k64b/gw_speak2_qie_s51']),
   ('B', 'The repaint look', ['milky living flesh, pink sinew, glass threads; a faceless gem head', 'seed 51 drew lips under the gem, so the repaint picks clean seeds'],
    ['k64b/gw_speak2_qie_s11', 'k64b/gw_hand2_qie_s11'])]),
}

def sheet(src, out, sp, table=SPECIES, tag='c64'):
    title, sub, takes = table[sp]
    lab = 104; blk = lab + C + GAP; top = 130
    im = Image.new('RGB', (W, top + len(takes) * blk + GAP), BG); d = ImageDraw.Draw(im)
    d.text((28, 24), title, fill=(240, 240, 240), font=font(40, True)); d.text((28, 78), sub, fill=(170, 170, 170), font=font(22))
    for r, (letter, name, words, cells) in enumerate(takes):
        y0 = top + r * blk
        d.text((GAP, y0 + 2), '%s. %s' % (letter, name), fill=(255, 220, 60), font=font(30, True))
        d.text((GAP, y0 + 40), '+ ' + words[0], fill=(200, 230, 200), font=font(21))
        d.text((GAP, y0 + 68), '- ' + words[1], fill=(235, 190, 170), font=font(21))
        for j, stem in enumerate(cells):
            x = GAP + j * (C + GAP); y = y0 + lab
            p = os.path.join(src, stem + '_00001_.png')
            im.paste(Image.open(p).convert('RGB').resize((C, C), Image.LANCZOS), (x, y))
            gold = stem.endswith('_s51')
            if gold: d.rectangle((x, y, x + C - 1, y + C - 1), outline=(255, 200, 60), width=5)
            d.text((x + 10, y + 8), '%s%d' % (letter, j + 1) + ('  s51' if gold else ''), fill=(255, 214, 90) if gold else (255, 255, 255),
                   font=font(24, True), stroke_width=3, stroke_fill=(0, 0, 0))
    p = os.path.join(out, '%s_%s.webp' % (tag, sp))
    im.save(p, 'WEBP', quality=84, method=6); print(p, im.size)

if __name__ == '__main__':
    src, out = sys.argv[1], sys.argv[2]; os.makedirs(out, exist_ok=True)
    if sys.argv[3:] == ['check']:
        for sp in CHECK: sheet(src, out, sp, CHECK, 'k64')
    else:
        for sp in SPECIES: sheet(src, out, sp)
