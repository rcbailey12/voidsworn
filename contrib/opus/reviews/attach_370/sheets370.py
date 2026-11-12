"""Issue 370: before and after sheets from the look bench's attach rows (godot/bench/look_moments_attach.json).

python sheets370.py BEFORE_MOMENTS AFTER_MOMENTS OUT_DIR
BEFORE_MOMENTS and AFTER_MOMENTS are the bench's moments folders (the second run of main and of the branch). Writes, per
hull, <hull>_attach_c<cam>.jpg (five moments, main on the left, the branch on the right, one bench cell each, 720 px tall;
camera 60, but 170 for the ring, which fills the frame at 60), jets_c170.jpg (every movement jet on the slab, the ring and
the tower at the battle camera, true pixels) and copies the camera 26 strips (the closest camera) of the slab, the ring and the tower as JPG into OUT_DIR/strips/.
"""
import os
import sys
from PIL import Image, ImageDraw

HULLS = [("slab", "I15_11 Glasswright cruiser (the slab)", 60), ("ring", "D22_23 Eclipse tomb-ark (the ring)", 170),
         ("tower", "D21_23 Eclipse cruiser (the tower)", 60), ("barge", "C19_51 Hullbreaker battle-barge", 60),
         ("recipe", "C15s_23 recipe cruiser (round 7 export)", 60)]
# moment, bench cell shown (the strip's frame index), label
MOMENTS = [("broadside", 7, "guns at a port target"), ("ahead", 5, "forward guns, target ahead"),
           ("jets", 1, "every movement jet"), ("wounds", 1, "wounds, sections at 10%"), ("launch", 3, "wing launch")]
CW, CH = 240, 135
LW = 120
HEAD = 45


def cell(path, i, size=(CW, CH)):
    im = Image.open(path).convert("RGB")
    n = im.width // 384
    i = min(i, n - 1)
    c = im.crop((384 * i, 0, 384 * i + 384, 216))
    return c if size == (384, 216) else c.resize(size, Image.LANCZOS)


def main(before, after, out):
    os.makedirs(os.path.join(out, "strips"), exist_ok=True)
    for key, name, cam in HULLS:
        sheet = Image.new("RGB", (LW + 2 * CW, HEAD + len(MOMENTS) * CH), (16, 16, 20))
        d = ImageDraw.Draw(sheet)
        d.text((6, 4), "%s  camera %d" % (name, cam), fill=(255, 220, 120))
        d.text((LW + 6, 26), "before (main)", fill=(230, 230, 230))
        d.text((LW + CW + 6, 26), "after (issue 370)", fill=(230, 230, 230))
        for r, (m, i, label) in enumerate(MOMENTS):
            f = "a_%s_%s__c%d.png" % (key, m, cam)
            y = HEAD + r * CH
            d.text((6, y + 6), m, fill=(255, 220, 120))
            d.text((6, y + 22), label, fill=(200, 200, 200))
            sheet.paste(cell(os.path.join(before, f), i), (LW, y))
            sheet.paste(cell(os.path.join(after, f), i), (LW + CW, y))
        sheet.save(os.path.join(out, "%s_attach_c%d.jpg" % (key, cam)), quality=88)
        if key not in ("slab", "ring", "tower"):
            continue
        for m, _, _ in MOMENTS:
            f = "a_%s_%s__c26.png" % (key, m)
            for tag, src in (("before", before), ("after", after)):
                Image.open(os.path.join(src, f)).convert("RGB").save(
                    os.path.join(out, "strips", "%s_%s" % (tag, f.replace(".png", ".jpg"))), quality=72)


    # the battle camera first (RULEBOOK 6.1): the jets at camera 170, true pixels (each cell a 1 to 1 crop)
    rows = HULLS[:3]
    sheet = Image.new("RGB", (LW + 2 * 384, HEAD + len(rows) * 216), (16, 16, 20))
    d = ImageDraw.Draw(sheet)
    d.text((6, 4), "every movement jet at the battle camera (170), true pixels", fill=(255, 220, 120))
    d.text((LW + 6, 26), "before (main)", fill=(230, 230, 230))
    d.text((LW + 384 + 6, 26), "after (issue 370)", fill=(230, 230, 230))
    for r, (key, name, _) in enumerate(rows):
        f = "a_%s_jets__c170.png" % key
        y = HEAD + r * 216
        d.text((6, y + 6), name.split(" (")[0], fill=(255, 220, 120))
        d.text((6, y + 22), "(" + name.split(" (")[1], fill=(200, 200, 200))
        sheet.paste(cell(os.path.join(before, f), 1, (384, 216)), (LW, y))
        sheet.paste(cell(os.path.join(after, f), 1, (384, 216)), (LW + 384, y))
    sheet.save(os.path.join(out, "jets_c170.jpg"), quality=90)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
