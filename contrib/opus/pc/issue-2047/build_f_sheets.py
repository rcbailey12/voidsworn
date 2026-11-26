"""Make one labelled, provenance-checked c170/c26 comparison per Build F case."""

import argparse
import json
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.dont_write_bytecode = True


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def load_run(directory):
    return tuple(json.loads((directory / name).read_text(encoding="utf-8"))
                 for name in ("bench.json", "moments.json"))


def still_index(report):
    return {(s["id"], s["cam"]): s for s in report["stills"] if s["part"] == "moments"}


def cells(pictures, root, still, fixture, cell_size, sha):
    expected = sum(w[2] for w in fixture["windows"])
    if len(still["cells"]) != expected or len(still["impacts"]) != 1 or still["code"] != fixture["expect_code"]:
        raise ValueError(f"{root.name} incomplete or wrong hull for {still['id']} c{still['cam']}")
    file = root / still["file"]
    image = pictures.open(file)
    records = pictures.take_sources()
    for record in records:
        if record["stage"] not in {"pre-merge capture", "installed in game"} or any(
                s["source_commit"] != sha or s["source_dirty"] for s in record["sources"]):
            raise ValueError(f"not a clean game capture of {sha}: {file}")
    width, height = cell_size
    # The raw look bench appends its provenance below the cells, rather than covering them.
    if image.width != expected * width or image.height <= height or records[0]["stamp_box"][1] != height:
        raise ValueError(f"unexpected cell geometry: {file}")
    frames = []
    for i, frame in enumerate(still["cells"]):
        bitmap = image.crop((i * width, 0, (i + 1) * width, height))
        frames.append((bitmap, frame["t"]))
    return frames, records


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("tools", "before", "after", "review", "shots"):
        parser.add_argument(name, type=Path)
    a = parser.parse_args()
    sys.path.insert(0, str(a.tools))
    from picture_provenance import Review, sidecar, verify

    pictures = Review("installed in game")
    before, baseline = load_run(a.before)
    after, fixture = load_run(a.after)
    if baseline != fixture or fixture["cameras"] != [170, 26] or before["commit"] == after["commit"]:
        raise ValueError("expected different pins with the same c170/c26 fixture")
    phases = ("charge", "shaft", "contact")
    cases = {}
    for row in fixture["rows"]:
        cases.setdefault(row["case"], {})[row["phase"]] = row
    if not cases:
        raise ValueError("no comparison cases")

    w, h = fixture["cell"]
    left, top, row_h = 80, 44, h + 6
    content_height = top + 4 * row_h
    title, label, clock = font(19), font(14), font(11)
    outputs = []
    for code, part in cases.items():
        sheet = Image.new("RGB", (left + 4 * w, content_height + 140), (14, 17, 24))
        if sheet.height > 720:
            raise ValueError("review sheet exceeds the 720 px height limit")
        draw = ImageDraw.Draw(sheet)
        draw.text((8, 3), part["shaft"]["label"], font=title, fill="white")
        for i, heading in enumerate(("Charge", "Shaft A", "Shaft B", "Hull contact / scar")):
            draw.text((left + i * w + 5, 25), heading, font=label, fill="#becbdb")
        sources = []
        y = top
        for camera in fixture["cameras"]:
            clocks = []
            for name, directory, report in (("Before", a.before, before), ("After", a.after, after)):
                draw.text((7, y + 36), f"Cam {camera}\n{name}\n{report['commit'][:8]}", font=label, fill="white")
                index = still_index(report)
                frame_times = []
                x = left
                for phase in phases:
                    row = part[phase]
                    images, records = cells(pictures, directory, index[row["id"], camera], row, (w, h), report["commit"])
                    sources.extend(records)
                    for image, t in images:
                        sheet.paste(image, (x, y))
                        draw.text((x + 4, y + h - 12), f"t={t:.3f}s", font=clock,
                                  fill="#dce7f2", stroke_width=1, stroke_fill="black")
                        x += w
                        frame_times.append(t)
                if len(frame_times) != 4:
                    raise ValueError(f"expected four phases for {code} at c{camera}")
                clocks.append(frame_times)
                y += row_h
            if any(abs(x - y) > 0.017 for x, y in zip(*clocks)):
                raise ValueError(f"before and after times do not match for {code} at c{camera}")
        output = a.review / f"{code}.jpg"
        pictures.save(sheet, output, sources=sources, quality=95)
        if verify(output)["stamp_box"][1] < content_height:
            raise ValueError(f"provenance footer covers a camera row in {output}")
        outputs.append(output)

    a.shots.mkdir(parents=True, exist_ok=True)
    for output in outputs:
        shutil.copyfile(output, a.shots / output.name)
        shutil.copyfile(sidecar(output), sidecar(a.shots / output.name))
        verify(a.shots / output.name)
    (a.review / "PASS.txt").write_text(f"PASS: {len(outputs)} matched c170/c26 comparisons with sidecars\n", encoding="utf-8")


if __name__ == "__main__":
    main()
