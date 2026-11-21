"""Build the battle and storm sheets from the second capture of each source."""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageStat

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools"))
from picture_provenance import Review, digest, save_picture, verify

STAGE = "installed in game"
BATTLE = (
    ("battle_170", "Battle view, radius 170"),
    ("battle_26", "Close view, radius 26"),
    ("shield_hit", "First shield hit, radius 26"),
    ("first_wreck", "First wreck frame, radius 26"),
)
STORM = (
    ("storm_high_170", "storm_max_170", "Strike, radius 170"),
    ("storm_high_26", "storm_max_26", "Cloud detail, radius 26"),
)


def load_capture(folder, name, source):
    capture = folder / f"{name}.png"
    marked = folder / f"{name}_source.png"
    capture_date = datetime.fromtimestamp(capture.stat().st_mtime, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    with Image.open(capture) as image:
        save_picture(image, marked, STAGE, sources=[{
            **source, "picture_name": capture.name, "stage": STAGE,
            "date": capture_date, "image_sha256": digest(capture.read_bytes()),
            "sources": [source],
        }])
    return marked


def sheet(title, rows, output, pair_width=376):
    review = Review(STAGE)
    image = Image.new("RGB", (1280, 720), "#10151e")
    draw = ImageDraw.Draw(image)
    title_font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 29)
    label_font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 19)
    code_font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 16)
    draw.text((22, 17), title, font=title_font, fill="#fff0de")
    draw.text((24, 55), output.stem, font=code_font, fill="#ffbe8b")
    for i, (label, pair) in enumerate(rows):
        if len(rows) == 2:
            x, y, width, gap = 194, 80 + i * 264, pair_width, 512
        else:
            x, y, width, gap = 22 + (i % 2) * 630, 100 + (i // 2) * 252, 300, 309
        draw.text((x, y), label, font=label_font, fill="#fff0de")
        for col, (name, path) in enumerate(pair):
            start = x + col * gap
            draw.text((start, y + 27), name, font=code_font, fill="#ffbe8b")
            capture = review.open(path).convert("RGB")
            image.paste(capture.resize((width, round(width * 9 / 16)), Image.Resampling.LANCZOS), (start, y + 49))
    review.save(image, output, quality=96)
    verify(output)


def compare(one, two):
    with Image.open(one) as a, Image.open(two) as b:
        difference = ImageChops.difference(a.convert("RGB"), b.convert("RGB"))
        stats = ImageStat.Stat(difference)
        return {"mean_rgb_of_255": stats.mean, "max_rgb_of_255": [max(v) for v in stats.extrema]}


def provenance(work):
    build = json.loads((work / "godot/build_info.json").read_text(encoding="utf-8-sig"))
    diff = work / "source_diff.sha256"
    source = {"source_commit": build["commit"], "source_dirty": diff.is_file(),
              "source_diff_sha256": diff.read_text().strip() if diff.is_file() else "", "stage": STAGE}
    if not source["source_dirty"]:
        source["source_commit_date"] = build["commit_date"]
    return source


def high_storm_proof(options, before, after):
    rows = []
    differences = {}
    for radius in (170, 26):
        name = f"storm_high_{radius}"
        captures = [work / f"{options.label}_{take}" for work in (options.before, options.after)
                    for take in (1, 2)]
        baseline = load_capture(captures[1], name, before)
        modified = load_capture(captures[3], name, after)
        rows.append((f"Radius {radius}", (("High on main", baseline), ("High after", modified))))
        files = [folder / f"{name}.png" for folder in captures]
        differences[name] = {"before_repeat": compare(files[0], files[1]),
                             "after_repeat": compare(files[2], files[3]),
                             "before_after": compare(files[1], files[3])}
    sheet("Dense storm High   /   seed 4103", rows, options.output / "PERF1070_RUN3_STORM.jpg", pair_width=360)
    return differences


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before", type=Path)
    parser.add_argument("after", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("results", type=Path)
    parser.add_argument("--label", default="proof")
    parser.add_argument("--storm-high-only", action="store_true")
    options = parser.parse_args()
    before = provenance(options.before)
    after = provenance(options.after)
    if options.storm_high_only:
        differences = high_storm_proof(options, before, after)
        options.results.write_text(json.dumps(differences, indent=2) + "\n", encoding="utf-8", newline="\n")
        return
    before_take = options.before / f"{options.label}_2"
    after_take = options.after / f"{options.label}_2"
    battle = []
    differences = {}
    for name, label in BATTLE:
        battle.append((label, (("Before", load_capture(before_take, name, before)),
                               ("After", load_capture(after_take, name, after)))))
        files = [work / f"{options.label}_{take}" / f"{name}.png"
                 for work in (options.before, options.after) for take in (1, 2)]
        differences[name] = {"before_repeat": compare(files[0], files[1]),
                             "after_repeat": compare(files[2], files[3]),
                             "before_after": compare(files[1], files[3])}
    storm = [(label, (("High", load_capture(before_take, a, before)),
                      ("Max", load_capture(before_take, b, before))))
             for a, b, label in STORM]
    sheet("Scene 207   /   V1b_r_23", battle, options.output / "PERF1070_RUN2_BATTLE.jpg")
    sheet("Dense storm   /   seed 4103", storm, options.output / "PERF1070_RUN2_STORM.jpg")
    options.results.write_text(json.dumps(differences, indent=2) + "\n", encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
