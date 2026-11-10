# The #271 identity sheet: three identities of the C bold layout, labeled, with close-ups that read on a phone.
# Run from the repo root: python3 contrib/opus/ui271_mockups/identity/sheet_id.py <folder with id1.png id2.png id3.png>
import sys
from PIL import Image, ImageDraw, ImageFont
OUT = sys.argv[1] if len(sys.argv) > 1 else '.'
F = 'contrib/opus/ui271_mockups/identity/fonts/'


def vf(name, size, w):
    f = ImageFont.truetype(F + name, size)
    try:
        f.set_variation_by_axes([w] if 'Exo2' in name else [w, 125] if 'Saira-VF' in name else [w])
    except Exception:
        pass
    return f


body = lambda s: ImageFont.truetype(F + 'SairaSemiCondensed-Regular.ttf', s)
semi = lambda s: ImageFont.truetype(F + 'SairaSemiCondensed-SemiBold.ttf', s)
PICK = 2
IDS = [
    (1, 'GRAPHITE SIGNAL', 'A quiet flight-deck instrument: graphite and white, colour only where the data is.',
     'Type: Saira Semi Condensed, wide Saira caps, JetBrains Mono numbers', 'Colour: neutral graphite, white text, white is the one accent',
     'Panels: smoked untinted glass, hairline edges, square corners, a short white index bar',
     lambda s: vf('Saira-VF.ttf', s, 700), (244, 246, 248), (11, 12, 14), (14, 15, 18)),
    (2, 'LIME TACTICAL', 'A combat targeting computer: black-olive slabs, cut corners, lime marks what to do next.',
     'Type: Chakra Petch (angular), Azeret Mono numbers', 'Colour: black-olive, pale sage text, neon lime is the one accent',
     'Panels: matte near-solid with a fine scanline, chamfered corners, lime brackets, slanted strips',
     lambda s: ImageFont.truetype(F + 'ChakraPetch-Bold.ttf', s), (200, 245, 58), (13, 18, 0), (10, 13, 10)),
    (3, 'WHITE FROST', 'Bright near-future glass: white frosted cards, ink text, cobalt for the next action.',
     'Type: Exo 2, Red Hat Mono numbers', 'Colour: frosted white panels, ink text, cobalt is the one accent; board labels stay dark',
     'Panels: frosted white glass, rounded corners, soft shadow, solid white wells',
     lambda s: vf('Exo2-VF.ttf', s, 800), (36, 83, 255), (255, 255, 255), (20, 26, 36)),
]
W, G = 1960, 14
FULL_W = W - 2 * G
FULL_H = round(FULL_W * 1080 / 1920)
CROPS = [(1458, 120, 1908, 560), (1458, 625, 1908, 1065), (250, 380, 700, 820)]
CS = 1.4
CW, CH = round(450 * CS), round(440 * CS)
BLOCK = 230 + FULL_H + 24 + 44 + CH + 70
H = 230 + 3 * BLOCK
sh = Image.new('RGB', (W, H), (8, 9, 11))
d = ImageDraw.Draw(sh)
d.text((G + 6, 22), 'BATTLE SCREEN: THREE IDENTITIES (ISSUE 271)', font=semi(64), fill=(240, 240, 240))
d.text((G + 6, 104), 'Same C bold layout as the build. Each one changes the typeface, the colours and the panel material.',
       font=body(36), fill=(185, 188, 192))
d.text((G + 6, 150), 'Opus picks 2, Lime Tactical. Your pick goes into the game theme.', font=body(36), fill=(185, 188, 192))
y = 230
for n, name, feel, t1, t2, t3, disp, acc, on_acc, bg in IDS:
    d.rectangle((0, y - 14, W, y + BLOCK - 40), fill=bg)
    lab = f'{n}  {name}'
    d.text((G + 6, y), lab, font=disp(70), fill=acc)
    if n == PICK:
        x = G + 16 + d.textlength(lab, font=disp(70)) + 30
        tw = d.textlength('OPUS PICK', font=semi(40))
        d.rectangle((x, y + 14, x + tw + 28, y + 70), fill=acc)
        d.text((x + 14, y + 16), 'OPUS PICK', font=semi(40), fill=on_acc)
    txt = (240, 240, 240) if n != 3 else (225, 230, 238)
    d.text((G + 6, y + 92), feel, font=semi(40), fill=txt)
    d.text((G + 6, y + 146), f'{t1}  |  {t2}', font=body(28), fill=(170, 175, 182))
    d.text((G + 6, y + 182), t3, font=body(28), fill=(170, 175, 182))
    y += 230
    im = Image.open(f'{OUT}/id{n}.png').convert('RGB')
    sh.paste(im.resize((FULL_W, FULL_H), Image.LANCZOS), (G, y))
    d.rectangle((G - 1, y - 1, G + FULL_W, y + FULL_H), outline=acc if n == PICK else (70, 74, 80), width=5 if n == PICK else 1)
    y += FULL_H + 24
    d.text((G + 6, y), 'Close-ups at 1.4x:', font=body(32), fill=(170, 175, 182))
    y += 44
    for j, c in enumerate(CROPS):
        x = G + j * (CW + 20)
        sh.paste(im.crop(c).resize((CW, CH), Image.LANCZOS), (x, y))
        d.rectangle((x - 1, y - 1, x + CW, y + CH), outline=(70, 74, 80), width=1)
    y += CH + 70
sh.save(f'{OUT}/identity_sheet.jpg', quality=88)
print(sh.size)
