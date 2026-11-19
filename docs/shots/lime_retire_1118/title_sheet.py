"""Retake TITLE at 1080p, without the random battle showcase.

Write the capture driver to a scratch directory with `driver PATH.gd`. In
each checkout, stage the same stock gen/manifest.json and gen/sky.res, import
Godot, and run via tools/pc/tmo.bat 90 GODOT --path godot --resolution
1920x1080 --script PATH.gd -- OUTPUT.png. Use an isolated APPDATA directory.
Then run `sheet BEFORE.png AFTER.png OUT/TITLE.png` with both input sidecars.
"""

import argparse
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools"))
from picture_provenance import open_picture, save_picture, verify


DRIVER = """extends SceneTree

const Main := preload("res://main/main.gd")
const Picture := preload("res://tools/picture_provenance.gd")

class CaptureMain extends Main:
\tfunc _ready() -> void:
\t\tpass

func _initialize() -> void:
\t_capture.call_deferred()

func _capture() -> void:
\troot.mode = Window.MODE_WINDOWED
\troot.size = Vector2i(1920, 1080)
\troot.warp_mouse(Vector2(0, 0))
\tvar main := CaptureMain.new()
\tmain.args["no-showcase"] = true
\troot.add_child(main)
\tmain.show_title()
\tfor i in 12:
\t\tawait process_frame
\tawait RenderingServer.frame_post_draw
\tvar image := root.get_texture().get_image()
\tif image.get_size() != Vector2i(1920, 1080) or main.title._bg.texture == null:
\t\tprinterr("FAIL: TITLE needs a 1920x1080 viewport and the stock sky")
\t\tquit(1)
\t\treturn
\tvar path := OS.get_cmdline_user_args()[0]
\tvar err := Picture.save_png(image, path)
\tif err == OK:
\t\tprint("PASS: captured TITLE at 1920x1080")
\tquit(0 if err == OK else 1)
"""


def compose(before, after, output):
    inputs = [before, after]
    sources = [verify(path) for path in inputs]
    result = Image.new("RGB", (1280, 570), "#0c0f11")
    draw = ImageDraw.Draw(result)
    draw.text((18, 14), "TITLE", font=ImageFont.load_default(size=26), fill="#f0eade")
    for x, label, color, path in zip(
        (18, 646), ("BEFORE / MAIN", "AFTER / ORDERS SHEET"),
        ("#c5bfb2", "#ff8a3a"), inputs,
    ):
        image = open_picture(path, required=True).convert("RGB")
        if image.size != (1920, 1080):
            raise ValueError(f"Expected a 1920x1080 capture: {path}")
        draw.text((x, 53), label, font=ImageFont.load_default(size=17), fill=color)
        result.paste(image.resize((616, 347), Image.Resampling.LANCZOS), (x, 85))
    save_picture(result, output, "sheet built", sources=sources)
    verify(output)
    print("PASS: TITLE sheet provenance (1280x570, two 1920x1080 sources)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    driver = commands.add_parser("driver")
    driver.add_argument("path", type=Path)
    sheet = commands.add_parser("sheet")
    for arg in ("before", "after", "output"):
        sheet.add_argument(arg, type=Path)
    args = parser.parse_args()
    if args.command == "driver":
        args.path.write_text(DRIVER, encoding="ascii")
    else:
        compose(args.before, args.after, args.output)
