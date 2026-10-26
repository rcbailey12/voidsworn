"""Checks godot/story/outlines.md: every beat body is 100 to 150 words, and no em or en dashes anywhere.
Run from the repo root: python3 godot/story/test/check_outlines.py"""
import re
import sys
import pathlib

p = pathlib.Path(__file__).resolve().parents[1] / "outlines.md"
t = p.read_text(encoding="utf-8")
bad = 0
if "\u2014" in t or "\u2013" in t:
    print("FAIL: em or en dash found")
    bad += 1
beats = re.split(r"^### ", t, flags=re.M)[1:]
for b in beats:
    head, _, rest = b.partition("\n")
    body = rest.strip().split("\n\n")[0]
    words = len(body.split())
    ok = 100 <= words <= 150
    bad += 0 if ok else 1
    print(("ok  " if ok else "FAIL") + f" {words:4d}  {head.strip()}")
print("beats:", len(beats), "fails:", bad)
sys.exit(1 if bad or len(beats) != 18 else 0)
