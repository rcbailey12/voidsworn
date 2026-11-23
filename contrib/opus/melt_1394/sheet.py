"""Issue 1394 acid bench sheets (Wave 0, Fable and Astra Nov 23): one jpg per hull and camera, before on top and after
below, columns in the order they were actually sampled, each labelled with its real time after the kill (from
<tag>_capture.json), and the pin of each row stamped on it. Runs in the cloud on a relay folder:
    python3 sheet.py <relay out folder> <dest folder> <code, e.g. AD1394J>
The relay folder holds out_old/ and out_new/ (each with scratch/), and checkouts.txt naming the two pins."""
import json, os, sys
from PIL import Image, ImageDraw, ImageFont

src, dest, code = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(dest, exist_ok=True)
pins = {}
for line in open(os.path.join(src, "checkouts.txt")):
    parts = line.split()
    if len(parts) >= 2: pins[parts[0]] = parts[1][:8]
F = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
FS = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
W, H = 384, 216
caps = {}
for side, tag in (("old", "old"), ("new", "new")):
    p = os.path.join(src, "out_" + side, "scratch", tag + "_capture.json")
    caps[side] = json.load(open(p))["targets"]
for view in sorted(caps["new"]):
    rows = []
    for side in ("old", "new"):
        row = caps[side].get(view)
        if not row: continue
        stills = sorted(row["stills"].items(), key=lambda kv: kv[1])
        rows.append((side, row, stills))
    if not rows: continue
    n = max(len(r[2]) for r in rows)
    sheet = Image.new("RGB", (W * n, 34 + H * len(rows)), (12, 14, 20))
    d = ImageDraw.Draw(sheet)
    r0 = rows[-1][1]
    d.text((8, 6), "%s %s %s, acid kill, %s. Top: before. Bottom: after. Times are seconds after the kill." % (code, r0["fac"], r0["cls"], view.split("_")[-1]), font=FS, fill="white")
    for ri, (side, row, stills) in enumerate(rows):
        folder = os.path.join(src, "out_" + side, "scratch", "%s_%s" % (side, view))
        for ci, (key, t) in enumerate(stills):
            im = Image.open(os.path.join(folder, key + "_sheet.jpg")).convert("RGB").resize((W, H))
            sheet.paste(im, (ci * W, 34 + ri * H))
            label = "%s %s +%.2f s" % ("before" if side == "old" else "after", key, t)
            d.text((ci * W + 6, 34 + ri * H + 4), label, font=F, fill="yellow", stroke_width=2, stroke_fill="black")
        d.text((6, 34 + ri * H + H - 22), "pin " + pins.get(side, "?"), font=FS, fill="white", stroke_width=2, stroke_fill="black")
    if sheet.height > 720:
        sheet = sheet.resize((sheet.width * 720 // sheet.height, 720))
    sheet.save(os.path.join(dest, "%s_%s.jpg" % (code, view)), quality=88)
    print("sheet", view)
