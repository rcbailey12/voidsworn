"""Issue #344, UI rollout 1: the contact sheet and the committed stills.

Usage: python3 -I tools/shots/ui344_contact_sheet.py <capture folder with 1080/ and 1440/> <repo root>
Writes docs/shots/ui_redesign/rollout1/1080/*.jpg and 1440/*.jpg (the PC captures, as jpg) and
docs/shots/ui_redesign/rollout1/contact_sheet.jpg: the campaign map as the player sees it first and large, then every
other page at 1080p with its name. Only reads the capture folder; writes only under the rollout1 folder.
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

ORDER = [
    ("01_map", "Campaign map: side panel, fight card, labels, the lime route"),
    ("01b_map_hover", "Map: hover card over a fight"),
    ("01c_side_panel", "Side panel (crop)"),
    ("03_map_elite_card", "Map: elite fight card"),
    ("04_map_boss_card", "Map: sector flagship card"),
    ("02_intro", "Intro"),
    ("05_battle_retreat", "Retreat"),
    ("06_reward_victory", "Reward: victory"),
    ("07_reward_salvage", "Reward: strip the wrecks"),
    ("07_reward_prize", "Reward: prize ships"),
    ("07_reward_boon", "Reward: protocol"),
    ("07_reward_mod", "Reward: refit"),
    ("07_reward_relic", "Reward: salvage vault"),
    ("13_promote", "Promotion"),
    ("08_shipyard", "Shipyard"),
    ("09_fleet", "Fleet"),
    ("10_event", "Event (story)"),
    ("11_event_result", "Event result"),
    ("12_drydock", "Drydock"),
    ("14_sector", "Sector page with the Nemesis adaptation"),
    ("15_map_sector2", "Map: sector II"),
]
BG = (9, 12, 9)
LIME = (200, 245, 58)
SAGE = (232, 238, 224)
DIM = (124, 134, 116)


def main():
    src, root = sys.argv[1], sys.argv[2]
    out = os.path.join(root, "docs", "shots", "ui_redesign", "rollout1")
    fdir = os.path.join(root, "godot", "ui", "theme", "fonts")
    head = ImageFont.truetype(os.path.join(fdir, "ChakraPetch-Bold.ttf"), 40)
    cap = ImageFont.truetype(os.path.join(fdir, "ChakraPetch-SemiBold.ttf"), 22)
    small = ImageFont.truetype(os.path.join(fdir, "ChakraPetch-Regular.ttf"), 20)
    have = {}
    for res in ("1080", "1440"):
        os.makedirs(os.path.join(out, res), exist_ok=True)
        d = os.path.join(src, res)
        if not os.path.isdir(d):
            continue
        for name, _ in ORDER:
            p = os.path.join(d, name + ".png")
            if os.path.exists(p):
                im = Image.open(p).convert("RGB")
                im.save(os.path.join(out, res, name + ".jpg"), quality=84, optimize=True)
                have.setdefault(res, {})[name] = im
    shots = have.get("1080", {})
    if "01_map" not in shots:
        print("no 1080 map capture; no sheet")
        return 1
    W = 2400
    lead = shots["01_map"].resize((W - 80, int((W - 80) * shots["01_map"].height / shots["01_map"].width)))
    rest = [(n, t) for n, t in ORDER[1:] if n in shots]
    cols, gap = 3, 24
    tw = (W - 80 - gap * (cols - 1)) // cols
    th = int(tw * 9 / 16)
    rows = (len(rest) + cols - 1) // cols
    H = 40 + 60 + lead.height + 50 + rows * (th + 50 + gap) + 60
    sheet = Image.new("RGB", (W, H), BG)
    dr = ImageDraw.Draw(sheet)
    dr.text((40, 30), "EMBERS OF THE HOLLOW SUN  UI ROLLOUT 1: CAMPAIGN MAP AND BETWEEN-BATTLE PAGES (LIME TACTICAL)", font=head, fill=SAGE)
    y = 100
    sheet.paste(lead, (40, y))
    dr.rectangle([40, y, 40 + lead.width - 1, y + lead.height - 1], outline=LIME, width=3)
    y += lead.height + 8
    dr.text((40, y), "01_map  The campaign map as the player sees it (1920x1080, real game capture on Ryan's PC)", font=cap, fill=LIME)
    y += 50
    for i, (n, t) in enumerate(rest):
        c, r = i % cols, i // cols
        x = 40 + c * (tw + gap)
        yy = y + r * (th + 50 + gap)
        im = shots[n]
        th_im = im.copy()
        th_im.thumbnail((tw, th))
        sheet.paste(th_im, (x + (tw - th_im.width) // 2, yy + (th - th_im.height) // 2))
        dr.rectangle([x, yy, x + tw - 1, yy + th - 1], outline=(40, 50, 40), width=1)
        dr.text((x, yy + th + 8), n + "  " + t, font=small, fill=SAGE)
    miss = [n for n, _ in ORDER if n not in shots]
    dr.text((40, H - 46), "Not captured on this run: " + (", ".join(miss) if miss else "none") + ".  Every page is also in 1440/ at 2560x1440.", font=small, fill=DIM)
    sheet.save(os.path.join(out, "contact_sheet.jpg"), quality=86, optimize=True)
    print("sheet", sheet.size, "pages", len(shots), "missing", miss)
    return 0


if __name__ == "__main__":
    sys.exit(main())
