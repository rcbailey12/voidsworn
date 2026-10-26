# Build the blind A/B sheets from the final round stills. usage: python3 blind.py <results_dir> <out_dir>
import sys, os, json, random
from PIL import Image, ImageDraw, ImageFont
R, OUT = sys.argv[1], sys.argv[2]; os.makedirs(OUT, exist_ok=True)
B = {'main': 'final_b_main', 'max': 'final_b_max_hi', 'board': 'final_b_board'}
G = {'main': 'final_g_main', 'max': 'final_g_max_hi', 'board': 'final_g_board_hi'}
NAMES = {'V1b_r_23': 'Voidsworn', 'H4_11': 'Hegemony', 'C19_51': 'Corsair Pyre-Barge', 'B16_23': 'Chorus', 'I8_37': 'Ithar', 'D22_23': 'Deathless'}
CODES = ['V1b_r_23', 'H4_11', 'C19_51', 'B16_23', 'I8_37', 'D22_23']
PAIRS = [
 ('01 Battle, t=5', 'main', 'battle_05.png', 't05.0_battle.png'),
 ('02 Barge close-up, broadside', 'main', 'close_20.png', 't02.0_barge_closeup.png'),
 ('03 Hull breach close-up', 'main', 'breach_30.png', 't03.0_breach_closeup.png'),
 ('04 Destruction', 'main', 'battle_126.png', 't12.6_destruction.png'),
 ('05 MAX battle, t=5', 'max', 'max_battle_05.png', 'max_t05.0_battle.png'),
 ('06 MAX barge close-up', 'max', 'max_close_20.png', 'max_t02.0_barge_closeup.png'),
 ('07 MAX hull breach', 'max', 'max_breach_30.png', 'max_t03.0_breach_closeup.png'),
 ('08 MAX destruction', 'max', 'max_battle_126.png', 'max_t12.6_destruction.png'),
] + [('%02d MAX close-up: %s' % (9 + i, NAMES[c]), 'max', 'hero_%s.png' % c, 'hero_%s.png' % c) for i, c in enumerate(CODES)] + [
 ('15 Game board view, t=3', 'board', 'board_03.png', 'board_t03.0.png'),
 ('16 Game board view, destruction', 'board', 'board_126.png', 'board_t12.6.png'),
]
rng = random.Random(int.from_bytes(os.urandom(4), 'little'))
babylon_is_A = rng.random() < 0.5
try: F = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 44)
except Exception: F = ImageFont.load_default()
W, H = 1600, 900; made = []
for label, mode, bf, gf in PAIRS:
    pb, pg = os.path.join(R, B[mode], bf), os.path.join(R, G[mode], gf)
    if not (os.path.exists(pb) and os.path.exists(pg)): print('missing', label, pb if not os.path.exists(pb) else pg); continue
    a, b = (pb, pg) if babylon_is_A else (pg, pb)
    s = Image.new('RGB', (W, H * 2 + 70), (14, 14, 18)); d = ImageDraw.Draw(s)
    d.text((20, 12), label, fill=(235, 230, 220), font=F)
    for k, (p, tag) in enumerate(((a, 'A'), (b, 'B'))):
        im = Image.open(p).convert('RGB').resize((W, H), Image.LANCZOS); s.paste(im, (0, 70 + k * H))
        d.rectangle((0, 70 + k * H, 90, 70 + k * H + 70), fill=(0, 0, 0)); d.text((22, 78 + k * H), tag, fill=(255, 210, 60), font=F)
    fn = os.path.join(OUT, label.split(' ')[0] + '.webp'); s.save(fn, quality=88); made.append(fn)
json.dump({'babylon_is_A': babylon_is_A}, open(os.path.join(OUT, '..', 'blind_key.json'), 'w'))
print('made', len(made))
