#!/usr/bin/env python3
"""Issue 271 step 2: the before and after pictures for Ryan, from the PC captures (build_shots.gd).

Usage: python3 make_build_pictures.py <capture folder> <repo root> [<before prompt picture>]
Reads before_1_target.png, before_3_enemy.png, after_1_target.png, after_2_prompt.png, after_3_enemy.png (1920x1080).
The before of the prompt moment is PR 533's own picture (docs/shots/tree_prompts/tree529_may_prompt.png on opus/issue-529),
since main has no prompt yet. Writes docs/shots/ui_battle_ember/build/: one moment per picture, 1280 wide, the code name on a
dark strip under the picture (never over it), none taller than 720 px; and full_1080/ with the frames as captured.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

MOMENTS = [("1_target", "your turn, a target"), ("2_prompt", "a 'you may' prompt"), ("3_enemy", "the enemy's turn")]


def font(repo, size):
    f = ImageFont.truetype(os.path.join(repo, "godot/ui/theme/fonts/BigShouldersDisplay-VF.ttf"), size)
    try:
        f.set_variation_by_axes([800])
    except Exception:
        pass
    return f


def picture(src, text, repo, dst):
    img = Image.open(src).convert("RGB")
    # the whole frame, never cropped (opus_check_544: a crop sliced the fleet list): scaled to 676 tall, centred, + the 44 px strip = 720
    img = img.resize((round(img.width * 676 / img.height), 676), Image.LANCZOS)
    out = Image.new("RGB", (1280, img.height + 44), (8, 8, 8))
    out.paste(img, ((1280 - img.width) // 2, 0))
    ImageDraw.Draw(out).text((16, img.height + 5), text, font=font(repo, 30), fill=(255, 138, 58))
    out.save(dst, quality=90)
    return out.size


def main():
    cap, repo = sys.argv[1], sys.argv[2]
    pr533 = sys.argv[3] if len(sys.argv) > 3 else ""
    dst = os.path.join(repo, "docs/shots/ui_battle_ember/build")
    os.makedirs(os.path.join(dst, "full_1080"), exist_ok=True)
    for key, words in MOMENTS:
        for side, name in (("before", "BEFORE LIME"), ("after", "AFTER E1 LEDGER")):
            src = os.path.join(cap, "%s_%s.png" % (side, key))
            if side == "before" and key == "2_prompt":
                src = pr533
            if not src or not os.path.exists(src):
                print("missing", side, key)
                continue
            size = picture(src, "%s   %s" % (name, words.upper()), repo, os.path.join(dst, "%s_%s.jpg" % (side, key)))
            Image.open(src).convert("RGB").save(os.path.join(dst, "full_1080", "%s_%s_1080.jpg" % (side, key)), quality=92)
            print("%s_%s.jpg %s" % (side, key, size))


if __name__ == "__main__":
    main()
