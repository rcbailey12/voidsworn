from PIL import Image, ImageDraw, ImageFont
import sys
sys.path.insert(0, '/home/claude/t559/comp')
O = '/mnt/user-data/uploads/voidsworn_test/opus559/'
C = '/home/claude/t559/comp/'
OUT = '/home/claude/w559/docs/shots/handoff_559/'
F = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 15)
FS = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 13)
def crop(p, w, h, dy=0):
    im = Image.open(p).convert('RGB'); W, H = im.size
    return im.crop(((W - w) // 2, (H - h) // 2 + dy, (W + w) // 2, (H + h) // 2 + dy))
def panel(im, size, label, sub=None):
    im = im.resize(size, Image.LANCZOS) if im.size != size else im
    out = Image.new('RGB', (size[0], size[1] + 22), (18, 18, 22)); out.paste(im, (0, 22))
    d = ImageDraw.Draw(out); d.text((6, 3), label, font=F, fill=(240, 240, 240))
    return out
def grid(panels, cols, gap=0, legend=None, W=1280):
    pw, ph = panels[0].size; rows = (len(panels) + cols - 1) // cols
    lh = 0 if legend is None else 24 * len(legend)
    s = Image.new('RGB', (pw * cols, ph * rows + lh), (10, 10, 12))
    for i, p in enumerate(panels): s.paste(p, ((i % cols) * pw, (i // cols) * ph))
    if legend:
        d = ImageDraw.Draw(s)
        for j, line in enumerate(legend):
            x = 8
            for txt, col in line:
                d.text((x, ph * rows + 4 + 24 * j), txt, font=FS, fill=col); x += d.textlength(txt, font=FS) + 4
    return s
RED, YEL, ORA, CYA, WHI, BLU, MAG, GRN, LIM, GRY = (255,90,90), (255,230,0), (255,160,40), (0,230,255), (255,255,255), (110,160,255), (255,80,255), (60,255,120), (200,255,0), (200,200,200)
P = (640, 326)
# 1. the main sheet
P1 = (640, 314)
s = grid([
    panel(crop(O + 'out_b/C19_51_b60.png', 1222, 600), P1, 'C19_51 Pyre-Barge: Blender (Cycles, game lights), camera 60'),
    panel(crop(O + 'out_g/C19_51_clean60.jpg', 1222, 600), P1, 'C19_51 in the game (main e2ffefce), camera 60: shape and paint ARRIVE'),
    panel(crop(C + 'C19_51_hp60.jpg', 1222, 600), P1, 'Hard points: guns LOST (red authored, yellow used); jets off hull'),
    panel(crop(C + 'C19_51_breach60.jpg', 1222, 600), P1, 'Damage: 8 authored breach anchors (blue) never used (pink = used)'),
], 2, legend=[[('red ring: authored gun muzzle (hp_w)', RED), ('yellow X: where the game fires from', YEL), ('orange ring + cyan dot: engine and plume start (match)', ORA)],
              [('white +: braking and side jet origins (box guesses)', WHI), ('green ring: authored core, lime X: core the game uses', GRN), ('blue ring: hp_breach, pink X: game wound anchor', MAG)]])
print('sheet', s.size); s.save(OUT + 'sheet.jpg', quality=88)
# 2. true pixels at camera 170 (no scaling)
T = (640, 200)
s = grid([
    panel(crop(O + 'out_b/C19_51_b170.png', 640, 200), T, 'C19_51 Blender, camera 170, true 1080p pixels'),
    panel(crop(O + 'out_g/C19_51_clean170.jpg', 640, 200), T, 'C19_51 game, camera 170, true pixels (319 px long)'),
    panel(crop(O + 'out_b/C15s_23_b170.png', 640, 200), T, 'C15s_23 recipe Ab7 Blender, camera 170'),
    panel(crop(O + 'out_g/C15s_23_clean170.jpg', 640, 200), T, 'C15s_23 recipe export in the game, camera 170 (180 px)'),
], 2)
print('170', s.size); s.save(OUT + 'camera170_true_pixels.jpg', quality=90)
# 3. hull lights only
s = grid([
    panel(crop(O + 'out_b/C19_51_blights60.png', 1180, 600), P, 'C19_51 Blender, lights only (no sun), camera 60'),
    panel(crop(O + 'out_g/C19_51_lights60.jpg', 1180, 600), P, 'C19_51 game, lights only: windows ARRIVE, engines re-drawn by fx'),
], 2)
print('lights', s.size); s.save(OUT + 'hull_lights.jpg', quality=88)
# 4. jets and guns
s = grid([
    panel(crop(C + 'C19_51_puffs_mk.jpg', 1180, 600), P, 'C19_51 braking and side jets: start in empty space (white +)'),
    panel(crop(O + 'out_g/C19_51_fire_side.jpg', 1180, 600), P, 'C19_51 broadside: one muzzle flash from a guessed mount'),
    panel(crop(O + 'out_g/C19_51_fire_bow.jpg', 1180, 600), P, 'C19_51 forward heavy torpedo: fires from the bow tip point'),
    panel(crop(C + 'C15s_23_hp60.jpg', 1180, 600), P, 'C15s_23 recipe: 18 barrel points (red) ignored, mounts guessed'),
], 2)
print('guns', s.size); s.save(OUT + 'guns_and_jets.jpg', quality=88)
# 5. shields
s = grid([
    panel(crop(O + 'out_g/C19_51_shield60.jpg', 1300, 662), P, 'C19_51 shield on a hit: an ellipsoid round the box (issue 371)'),
    panel(crop(O + 'out_g/C15s_23_shield60.jpg', 1300, 662), P, 'C15s_23 shield: same ellipsoid, faction colour ARRIVES'),
], 2)
print('shield', s.size); s.save(OUT + 'shields.jpg', quality=88)
# 6. the recipe ship
s = grid([
    panel(crop(O + 'out_b/C15s_23_b60.png', 1000, 510), P, 'C15s_23 Ab7.blend (recipe round 7), camera 60'),
    panel(crop(O + 'out_g/C15s_23_clean60.jpg', 1000, 510), P, 'C15s_23 stage 7 export in the game, camera 60'),
    panel(crop(O + 'out_b/C15s_23_blights60.png', 1000, 510), P, 'C15s_23 Blender lights only: glow strip'),
    panel(crop(C + 'C15s_23_breach60.jpg', 1000, 510), P, 'C15s_23 damage: 6 hp_breach (blue) unused; wounds (pink)'),
], 2)
print('recipe', s.size); s.save(OUT + 'recipe_C15s_23.jpg', quality=88)
