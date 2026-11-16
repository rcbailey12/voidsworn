# Issue 793 helper (sandbox only, not a standing check): the named 1280 by 720 pictures for the three squadron craft sheets
# (hegemony_HF1D, corsair_KB1CC, chorus_CS1BA2), each with its code name on it: per craft the sheet overview and the whole concept
# beside the build (R229); for the three, each beside its faction's flagship at true game scale, and the battle camera read.
# usage: python pictures.py overview CODE RENDER_DIR
#        python pictures.py scale OUT.jpg HEG.png HB.png CH.png       (game_view.py renders, GV_FULL=1 and GV_ORTHO=$GV_ORTHO)
#        python pictures.py battle OUT.jpg BATTLE.png                  (game_view.py at the battle camera, its middle third)
# Python with Pillow, numpy and scipy. The overview and compare read build.py's render folder (beauty_cam.png from the fitted
# camera) and write into docs/ship_pipeline/build_sheets/CODE/.
import os, sys, json
from PIL import Image, ImageDraw, ImageFont
import numpy as np
from scipy import ndimage

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
GREY = (44, 44, 46); INK = (240, 232, 218); DIM = (190, 186, 178); ACC = (240, 170, 80)
CRAFT = {
    'hegemony_HF1D': dict(con='contrib/muse/design/squadron_concepts_2026_11/hegemony/round_3/HF1D.jpg', cname='HF1D (slim prow)',
                          title='hegemony_HF1D | Spined Shield fighter (data.js fighter), first sheet (issue 793)',
                          lines=['A machined wedge, a slim prow, HF1C\'s depth, no wing', 'Interceptor guns: a three-barrel cassette on a flush ring in the',
                                 '  framed recess at the prow (guns T, turns all round)', 'The flat-topped ridge, the stepped edging, the blue line',
                                 'One drive slit in three cells, in an armoured pod', 'No canopy: a dark sensor slit above the recess'],
                          notes=['Kept: the slim wedge, HF1C\'s ridge from the bow block to the stern block, HF1B\'s stepped edging, the cassette of three',
                                 'grouped muzzles in a framed recess at the prow with the sensor slit above it, one blue drive slit at the stern.',
                                 'Changed: the cassette turns on a flush ring (data.js guns fire all round); the slit stays dark (round 3 notes); the hull',
                                 'keeps HF1C\'s depth. Pale grey, trim and the blue line are the Hegemony stack, applied later (issue 780).']),
    'corsair_KB1CC': dict(con='contrib/muse/design/squadron_concepts_2026_11/hullbreakers/round_3/KB1CC.jpg', cname='KB1C-C',
                          title='corsair_KB1CC | Wide Glacis bomber (data.js bomber), first sheet (issue 793)',
                          lines=['One wide low wedge: the glacis, the lid, the stern housing', 'Bombs: two tubes at the glacis\'s extreme corners, in',
                                 '  dark armoured collars (bombs T, both every volley)', 'The armoured lip, the edge rails, two hoist bays with doors',
                                 'Five mismatched drives in a recessed stern bank', 'Beam 0.6 of the length (the sheet\'s beam guard)'],
                          notes=['Kept: the wide continuous glacis, the two corner mouths in dark collars, the raised edge rails, the recessed side bays',
                                 'with armoured doors, the stern thruster row. Changed: the mouths are dark bomb tubes (the render lights them like',
                                 'engines); an armoured lip and a vision slit end the glacis (never a ramp); the shoulders slope to a thin edge.',
                                 'Rust, soot, trophy colours and the red running lights are the Hullbreaker stack, applied later.']),
    'chorus_CS1BA2': dict(con='contrib/muse/design/squadron_concepts_2026_11/chorus/round_4/CS1BA2.jpg', cname='CS1B-A2',
                          title='chorus_CS1BA2 | Sealed Gills spore swarm (data.js spore), first sheet (issue 793)',
                          lines=['One grown spindle, drawn out and low (sleeker, R259)', 'Acid sacs: two sealed gill bladders, one a flank, a',
                                 '  closed sphincter at each front (sporeb T, both burst)', 'The bone line along the back, a short blunt fork at the bow',
                                 'Four muscle-ringed orifices on the blunt stern', 'Closed hull: no open groove, no fluid, no glow on the sacs'],
                          notes=['Kept: the sleek pod, the bone spine and its fork, the two sealed gill bladders with their band rhythm and muted',
                                 'amber valleys, the spots along the bow ridge, the orifice cluster at the stern. Changed: olive flesh and ochre bone',
                                 '(factions.md, the C10 and C11 hulls), not plum; the spots are sense pores (no eyes); the stern ends blunt behind a',
                                 'full-size cluster; the fork short and low (round 4 notes). The Chorus has no paint stack yet.']),
}


def F(n):
    return ImageFont.truetype(next((f_ for f_ in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf') if os.path.exists(f_)), None), n)


def on_grey(path):
    im = Image.open(path).convert('RGBA'); bg = Image.new('RGBA', im.size, (58, 58, 60, 255)); bg.alpha_composite(im); return bg.convert('RGB')


def alpha_crop(path, pad=16):
    im = Image.open(path).convert('RGBA'); x0, y0, x1, y1 = im.getchannel('A').getbbox()
    im = im.crop((max(0, x0 - pad), max(0, y0 - pad), min(im.width, x1 + pad), min(im.height, y1 + pad)))
    bg = Image.new('RGBA', im.size, (58, 58, 60, 255)); bg.alpha_composite(im); return bg.convert('RGB')


def paste(c, im, x, y, w, h):
    im = im.copy(); im.thumbnail((w, h), Image.Resampling.LANCZOS); c.paste(im, (x + (w - im.width) // 2, y + (h - im.height) // 2))


def overview(code, rd):
    c = CRAFT[code]; D = os.path.join(REPO, 'docs', 'ship_pipeline', 'build_sheets', code)
    im = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(im)
    d.text((18, 10), c['title'], fill=INK, font=F(24))
    d.text((18, 44), 'One Blender blockout, every view at one scale. Fit check 0, weapon match PASS, contract and audit PASS. Unpainted.', fill=DIM, font=F(16))
    paste(im, alpha_crop(rd + '/side.png'), 18, 74, 820, 200); d.text((22, 76), 'TRUE SIDE (bow left)', fill=ACC, font=F(15))
    paste(im, alpha_crop(rd + '/top.png').rotate(90, expand=True), 18, 280, 820, 230); d.text((22, 282), 'TRUE TOP (bow left, port down)', fill=ACC, font=F(15))
    paste(im, alpha_crop(rd + '/cutaway.png'), 18, 516, 820, 190); d.text((22, 518), 'INSIDE (cutaway): small, for the build contract', fill=ACC, font=F(15))
    paste(im, on_grey(rd + '/threequarter.png'), 850, 74, 412, 260); d.text((854, 76), 'THREE-QUARTER', fill=ACC, font=F(15))
    paste(im, alpha_crop(rd + '/stern.png'), 850, 340, 200, 170); d.text((854, 342), 'ENGINE END', fill=ACC, font=F(15))
    paste(im, alpha_crop(rd + '/bow.png'), 1062, 340, 200, 170); d.text((1066, 342), 'BOW-ON', fill=ACC, font=F(15))
    y = 524
    for line in c['lines'] + ['Length 1.6 (drawn 3.84 on the board, scale.md)']:
        d.text((856, y), ('' if line.startswith('  ') else '- ') + line, fill=INK, font=F(13)); y += 26
    im.save(D + '/%s_sheet_overview.jpg' % code, quality=90)
    # the whole concept beside the build (R229): the picture and the blockout at the camera fitted to it, whole
    cam = json.load(open(REPO + '/tools/blender/build_sheets/ships/%s_camera.json' % code))
    im = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(im)
    d.text((18, 10), '%s | the whole concept beside the build (R229)' % code, fill=INK, font=F(26))
    paste(im, Image.open(os.path.join(REPO, c['con'])).convert('RGB'), 18, 90, 615, 420)
    b = Image.open(rd + '/beauty_cam.png').convert('RGBA'); bg = Image.new('RGBA', b.size, (14, 14, 16, 255)); bg.alpha_composite(b)
    paste(im, bg.convert('RGB'), 647, 90, 615, 420)
    d.text((22, 62), '%s (concept of record, R259)' % c['cname'], fill=ACC, font=F(17))
    d.text((651, 62), 'Build, unpainted, at the camera fitted to %s (outline overlap %d%%)' % (c['cname'].split(' (')[0], round(cam['iou'] * 100)), fill=ACC, font=F(15))
    y = 530
    for line in c['notes']:
        d.text((22, y), line, fill=INK, font=F(16)); y += 28
    im.save(D + '/%s_compare.jpg' % code, quality=90)
    print('overview and compare written for', code)


def blobs(path, k=3):
    sc = Image.open(path).convert('RGB'); a = np.asarray(sc).astype(int); bgc = np.median(a.reshape(-1, 3), axis=0)
    fg = ndimage.binary_closing(np.abs(a - bgc).sum(2) > 20, np.ones((5, 5))); lab, n = ndimage.label(fg)
    objs = ndimage.find_objects(lab); sz = ndimage.sum(fg, lab, range(1, n + 1))
    return sc, [objs[i] for i in np.argsort(-sz)[:k]]


def scale(out, paths):
    """the three craft each beside its faction's flagship, orthographic, every length to scale (one ortho width for all three)"""
    ortho = float(os.environ.get('GV_ORTHO', 80))
    im = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(im)
    d.text((18, 8), 'hegemony_HF1D, corsair_KB1CC, chorus_CS1BA2 beside their flagships at true game scale (orthographic, one scale)', fill=INK, font=F(19))
    names = [('hegemony_IM5 (the Iron Mandate, 49.6)', 'hegemony_HF1D wing'), ('corsair_A16 (the Pyre-Barge, 41.6)', 'corsair_KB1CC wing'),
             ('chorus_C10 (the Ninefold Maw, 44.8)', 'chorus_CS1BA2 wing')]
    y = 40; meas = []
    for (fl, cr), p in zip(names, paths):
        sc, big = blobs(p, 6)
        ppu = sc.width / ortho
        ship = max(big, key=lambda o: o[1].stop - o[1].start)
        crafts = [o for o in big if o is not ship and (o[1].stop - o[1].start) / ppu < 6.0]
        Ls = (ship[1].stop - ship[1].start) / ppu
        Lc = max(((o[1].stop - o[1].start) / ppu for o in crafts), default=0.0)
        meas.append((Ls, Lc))
        allo = [ship] + crafts
        y0 = min(o[0].start for o in allo) - 6; y1 = max(o[0].stop for o in allo) + 6
        x0 = min(o[1].start for o in allo) - 10; x1 = max(o[1].stop for o in allo) + 10
        band = sc.crop((max(0, x0), max(0, y0), min(sc.width, x1), min(sc.height, y1)))
        k = 1240 / sc.width   # one scale for all three bands
        band = band.resize((max(1, int(band.width * k)), max(1, int(band.height * k))), Image.Resampling.LANCZOS)
        hmax = 200
        if band.height > hmax:
            band = band.crop((0, (band.height - hmax) // 2, band.width, (band.height - hmax) // 2 + hmax))
        im.paste(band, (20 + int((max(0, x0)) * k), y + 22))
        d.text((22, y), '%s and a %s: measured here %.1f and %.1f long (game: the craft 3.84, scale.md)' % (fl, cr, Ls, Lc), fill=ACC, font=F(15))
        y += 22 + band.height + 12
    d.text((22, 690), 'Unpainted blockouts. A craft is about a twelfth of its flagship\'s length; wings fly in fours (godot/render/squadron_wing.gd).', fill=DIM, font=F(15))
    im.save(out, quality=90)
    print('scale:', meas)


def battle(out, path):
    im = Image.new('RGB', (1280, 720), GREY); d = ImageDraw.Draw(im)
    bt = Image.open(path).convert('RGB')
    d.text((18, 8), 'hegemony_HF1D, corsair_KB1CC, chorus_CS1BA2 | battle camera, game size, wings of four (unpainted)', fill=INK, font=F(21))
    d.text((18, 36), 'The game camera: fov 45, range 170, 34 degrees above the board. Top left: the middle of a 1080p screen at 1:1. The rest: each wing x3.',
           fill=DIM, font=F(14))
    im.paste(bt, (10, 84)); d.rectangle((9, 83, 10 + bt.width, 84 + bt.height), outline=ACC, width=1)
    d.text((12, 62), 'native pixels (1:1)', fill=ACC, font=F(15))
    a = np.asarray(bt).astype(int); bgc = np.median(a.reshape(-1, 3), axis=0); fg = np.abs(a - bgc).sum(2) > 18
    thirds = [slice(0, bt.width // 3), slice(bt.width // 3, 2 * bt.width // 3), slice(2 * bt.width // 3, bt.width)]
    labs = ['hegemony_HF1D fighters, x3', 'corsair_KB1CC bombers, x3', 'chorus_CS1BA2 spore swarm, x3']
    spots = [(668, 62), (668, 316), (14, 470)]
    w, h = 148, 70
    for lab, part, (X, Y) in zip(labs, thirds, spots):
        ys, xs = np.where(fg[:, part]); x0 = xs.min() + part.start; x1 = xs.max() + part.start; y0, y1 = ys.min(), ys.max()
        cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
        crop = bt.crop((cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2)).resize((w * 3, h * 3), Image.Resampling.NEAREST)
        im.paste(crop, (X, Y + 22)); d.rectangle((X - 1, Y + 21, X + crop.width, Y + 22 + crop.height), outline=ACC, width=1)
        d.text((X, Y), lab, fill=ACC, font=F(15))
    y = 572
    for line in ('Hegemony: a pale machined wedge, its blue line along the edge and one blue drive slit.',
                 'Hullbreakers: a broad patched block, two dark corner mouths, five red-orange drives aft.',
                 'Chorus: a grown olive spindle, the sealed bladders swelling either side of the bone line.',
                 'Each reads as its own faction\'s craft; none as a jet, a boat or a ground vehicle.'):
        d.text((480, y), line, fill=INK, font=F(15)); y += 30
    im.save(out, quality=92)
    print('battle written', out)


if __name__ == '__main__':
    mode = sys.argv[1]
    if mode == 'overview':
        overview(sys.argv[2], sys.argv[3])
    elif mode == 'scale':
        scale(sys.argv[2], sys.argv[3:6])
    elif mode == 'battle':
        battle(sys.argv[2], sys.argv[3])
