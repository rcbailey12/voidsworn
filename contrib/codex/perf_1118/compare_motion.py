"""Compare the alpha adapter trial with a repeat of the original look bench."""

import argparse
import json
import sys
from pathlib import Path

from PIL import ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
from picture_provenance import open_picture, verify


def compare(left, right, cell_width=384):
    if left.size != right.size or left.width % cell_width:
        raise ValueError("Look-bench strips disagree on dimensions")
    difference = ImageChops.difference(left, right)
    red, green, blue = difference.split()
    changed = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    return {
        "exact": difference.getbbox() is None,
        "max_channel_delta": max(channel[-1] for channel in difference.getextrema()),
        "mean_rgb_delta": ImageStat.Stat(difference).mean,
        "different_pixels": left.width * left.height - changed.histogram()[0],
        "different_cells": [
            offset // cell_width
            for offset in range(0, left.width, cell_width)
            if difference.crop((offset, 0, offset + cell_width, left.height)).getbbox() is not None
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("work", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    rows = []
    for camera in (170, 26):
        for reduced in (False, True):
            name = "I15_11_macro_fragments" + ("_reduced" if reduced else "") + f"__c{camera}.png"
            paths = [args.work / f"alpha_motion_{arm}_{take}" / "moments" / name
                     for arm, take in (("before", 1), ("before", 2), ("after", 1), ("after", 2))]
            sources = [verify(path) for path in paths]
            repeat, before, trial_repeat, after = [open_picture(path).convert("RGB") for path in paths]
            rows.append({
                "camera": camera,
                "reduced_flashing": reduced,
                "cells": before.width // 384,
                "repeat_vs_original": compare(repeat, before),
                "repeat_vs_trial": compare(trial_repeat, after),
                "original_vs_trial": compare(before, after),
                "source_images_sha256": [source["image_sha256"] for source in sources],
            })
    args.out.write_text(json.dumps(rows, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
