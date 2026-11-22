"""Issue 1679 (fleet lighting, R411): the Pick Sheet pictures from two look bench fleet runs of one commit, one with
VS_FLEET_LIGHTING unset (today's look) and one with VS_FLEET_LIGHTING=1 (the new AO light and reflection gradient).

usage: python fl1679_sheet.py --off RUN_OFF --on RUN_ON --out DIR [--cams 170,110] [--chorus-cams 170,60]
  RUN_*   look bench run folders (bench.json and fleet/<sky>/ inside), made with --part fleet --fleet-cams 170,110,60
Writes into DIR, each picture no taller than 720 px, revision and stage stamped (tools/picture_provenance.py):
  FL1679_c170.jpg      one current ship per faction on the darkest measured sky, today | 1679 side by side, 1 to 1 pixels
  FL1679_c110.jpg      the same at camera 110 (scaled down only if the sheet would pass 720 px)
  FL1679_brightest_c170.jpg  the same six on the brightest sky (the other end of the readability band)
  CH1683_before_<code>.png  each Chorus hull today at --chorus-cams, darkest sky: the "before" for issue 1683's sheet
  summary.txt          which skies were darkest and brightest (corner brightness, as look_bench_sheets.py measures)
Refuses, writing nothing, unless (Artoo on PR 1717): RUN_OFF's bench.json says fleet_lighting false and RUN_ON's true;
both name the same non-empty commit and every input still's provenance names one source commit; every input carries
the same stage, and that stage is "installed in game" (a cloud smoke passes --allow-stage "cloud direction check" and its
sheets keep that stage); every expected still exists (six ships at each camera on the darkest and brightest sky, five
Chorus hulls at each Chorus camera); and DIR is new or empty.
"""
import argparse
import json
import os
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(next(p for p in Path(__file__).resolve().parents if (p / 'tools/picture_provenance.py').is_file()) / 'tools'))
from picture_provenance import Review, open_picture, verify  # noqa: E402
from PIL import Image, ImageDraw, ImageFont, ImageStat  # noqa: E402

PICTURES = None   # set in main from the inputs' own stage (Artoo on PR 1717)
# One new-format build per faction, near cruiser size (docs/ship_pipeline/FLEET.md, Nov 22). Navy's cruiser H9 is
# still an old hull, so the Navy pick is the new battleship H10.
SHIPS = [("voidsworn", "V16_37", "Sunward Vigil"), ("hegemony", "H10_23", "Navy H10"), ("corsair", "C15s_23", "Hullbreaker A17"),
         ("chorus", "B21_11", "Chorus C11"), ("ithar", "I15_11", "Glasswright Prism"), ("deathless", "D21_23", "Eclipse E13")]
CHORUS = ["B19_11", "B20_11", "B21_11", "B22_11", "B16_23"]
MAX_H = 720
BG, FG, DIM = (14, 15, 18), (225, 228, 232), (150, 155, 162)


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


F, FB = font(15), font(20)


def stills(run):
    rep = json.loads((Path(run) / "bench.json").read_text(encoding="utf-8"))
    out = {}
    for s in rep.get("stills", []):
        if s.get("part") in ("fleet", "fleet_cam"):
            out[(s["sky"], s["code"], int(s.get("cam", 170)))] = Path(run) / s["file"]
    return rep, out


def corner_level(paths):
    vals = []
    for p in paths:
        im = open_picture(p, required=True).convert("L")
        w, h = im.size
        for box in [(0, 0, 30, 30), (w - 30, 0, w, 30), (0, h - 30, 30, h), (w - 30, h - 30, w, h)]:
            vals.append(ImageStat.Stat(im.crop(box)).mean[0])
    return sum(vals) / len(vals) if vals else 0.0


def pick_sheet(off, on, sky, cam, title, commit):
    pairs = []
    for fac, code, name in SHIPS:
        a, b = off[(sky, code, cam)], on[(sky, code, cam)]
        pairs.append((name, code, PICTURES.open(a), PICTURES.open(b)))
    cw, ch = pairs[0][2].size
    lab, head, gap = 22, 48, 8
    cols = 3
    rows = (len(pairs) + cols - 1) // cols
    W = cols * (2 * cw + gap) + (cols - 1) * gap
    H = head + rows * (lab + ch + gap)
    sheet = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(sheet)
    d.text((10, 6), title, font=FB, fill=FG)
    d.text((10, 28), "left of each pair: today (VS_FLEET_LIGHTING off)   right: issue 1679 option (on)   commit %s, sky %s" % (commit, sky), font=F, fill=DIM)
    for i, (name, code, a, b) in enumerate(pairs):
        x = (i % cols) * (2 * cw + 2 * gap)
        y = head + (i // cols) * (lab + ch + gap)
        d.text((x + 4, y + 3), "%s %s c%d   TODAY | 1679" % (name, code, cam), font=F, fill=FG)
        sheet.paste(a.convert("RGB"), (x, y + lab))
        sheet.paste(b.convert("RGB"), (x + cw + gap // 2, y + lab))
    if sheet.height > MAX_H:
        k = MAX_H / sheet.height
        sheet = sheet.resize((round(sheet.width * k), MAX_H), Image.LANCZOS)
    return sheet


def refuse(why):
    print("FL1679 SHEETS REFUSED: " + why)
    raise SystemExit(1)


def main():
    global PICTURES
    ap = argparse.ArgumentParser()
    ap.add_argument("--off", required=True)
    ap.add_argument("--on", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--cams", default="170,110")
    ap.add_argument("--chorus-cams", default="170,60")
    ap.add_argument("--allow-stage", default="installed in game")
    a = ap.parse_args()
    rep_off, off = stills(a.off)
    rep_on, on = stills(a.on)
    if rep_off.get("fleet_lighting") is not False or rep_on.get("fleet_lighting") is not True:
        refuse("--off must be a fleet_lighting false run and --on a true one (bench.json says %r and %r)"
               % (rep_off.get("fleet_lighting"), rep_on.get("fleet_lighting")))
    commit = str(rep_off.get("commit", ""))
    if not commit or commit != str(rep_on.get("commit", "")):
        refuse("the two runs must name the same non-empty commit: %r and %r" % (rep_off.get("commit"), rep_on.get("commit")))
    if Path(a.out).exists() and any(Path(a.out).iterdir()):
        refuse("the output folder is not empty: " + a.out)
    cams = [int(c) for c in a.cams.split(",") if c]
    ccams = [int(c) for c in a.chorus_cams.split(",") if c]
    skies = sorted({k[0] for k in off if k[2] == 170})
    if not skies:
        refuse("no camera 170 fleet stills in --off")
    level = {s: corner_level([p for k, p in off.items() if k[0] == s and k[2] == 170]) for s in skies}
    dark = min(skies, key=lambda s: level[s])
    bright = max(skies, key=lambda s: level[s])
    need = [(dark, code, cam) for _, code, _ in SHIPS for cam in cams] + [(bright, code, 170) for _, code, _ in SHIPS]
    missing = ["%s %s c%d %s" % (name, k[1], k[2], k[0]) for name, run in (("off", off), ("on", on)) for k in need if k not in run]
    missing += ["off %s c%d %s (Chorus before)" % (code, c, dark) for code in CHORUS for c in ccams if (dark, code, c) not in off]
    if missing:
        refuse("missing stills: " + "; ".join(missing))
    used = {off[k] for k in need} | {on[k] for k in need} | {off[(dark, code, c)] for code in CHORUS for c in ccams}
    stages, srcs = set(), set()
    for p in used:
        try:
            r = verify(p)
        except Exception as e:  # noqa: BLE001 - any provenance failure refuses the sheet
            refuse("input provenance does not verify: %s (%s)" % (p, e))
        stages.add(r["stage"])
        srcs.add(r["source_commit"])
    if len(stages) != 1 or stages != {a.allow_stage}:
        refuse("inputs carry stage %s, want only %r" % (sorted(stages), a.allow_stage))
    if len(srcs) != 1 or len(commit) < 7 or not next(iter(srcs)).startswith(commit):
        refuse("input stills come from source commits %s, want one matching %s" % (sorted(srcs), commit))
    PICTURES = Review(a.allow_stage)
    os.makedirs(a.out, exist_ok=True)
    made = []
    for cam in cams:
        sh = pick_sheet(off, on, dark, cam, "FL1679 fleet lighting, camera %d, darkest sky" % cam, commit)
        p = os.path.join(a.out, "FL1679_c%d.jpg" % cam)
        PICTURES.save(sh, p, quality=92)
        made.append(p)
    sh = pick_sheet(off, on, bright, 170, "FL1679 fleet lighting, camera 170, brightest sky", commit)
    p = os.path.join(a.out, "FL1679_brightest_c170.jpg")
    PICTURES.save(sh, p, quality=92)
    made.append(p)
    # the "before" for issue 1683: each Chorus hull as installed today, darkest sky, flag off
    for code in CHORUS:
        ims = [PICTURES.open(off[(dark, code, c)]).convert("RGB") for c in ccams]
        lab = 22
        W = sum(i.width for i in ims) + 8 * (len(ims) - 1)
        H = lab + max(i.height for i in ims)
        sheet = Image.new("RGB", (W, H), BG)
        d = ImageDraw.Draw(sheet)
        d.text((4, 3), "CH1683 BEFORE %s as installed today (build\\godot), cameras %s, sky %s, commit %s" % (code, "/".join(map(str, ccams)), dark, commit), font=F, fill=FG)
        x = 0
        for i in ims:
            sheet.paste(i, (x, lab))
            x += i.width + 8
        if sheet.height > MAX_H:
            k = MAX_H / sheet.height
            sheet = sheet.resize((round(sheet.width * k), MAX_H), Image.LANCZOS)
        p = os.path.join(a.out, "CH1683_before_%s.png" % code)
        PICTURES.save(sheet, p)
        made.append(p)
    with open(os.path.join(a.out, "summary.txt"), "w", encoding="utf-8") as f:
        f.write("commit %s\n" % commit)
        f.write("sky corner brightness (flag off, camera 170): %s\n" % ", ".join("%s %.1f" % (s, level[s]) for s in skies))
        f.write("darkest %s, brightest %s\n" % (dark, bright))
        for p in made:
            f.write("wrote %s\n" % p)
    print("FL1679 SHEETS PASS: %d pictures, darkest sky %s" % (len(made), dark))


if __name__ == "__main__":
    main()
