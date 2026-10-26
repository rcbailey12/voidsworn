"""Checks that the rival line pools (godot/story/data/rival_lines.json) cover exactly the personas stream B can roll per
faction (data.js NEM_FAC[fac].personas, R42), with a calling card and hail and beaten lines for each.
Run from the repo root: python3 godot/story/test/check_personas.py"""
import json
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parents[3]
data = (root / "data.js").read_text(encoding="utf-8")
rl = json.loads((root / "godot/story/data/rival_lines.json").read_text(encoding="utf-8"))
bad = 0
for fac in ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]:
    m = re.search(r"\b" + fac + r":\{pre:[^}]*?personas:\[([^\]]*)\]", data, re.S)
    if not m:
        print("SKIP", fac, "(no NEM_FAC entry in data.js)")
        continue
    personas = re.findall(r"'(\w+)'", m.group(1))
    have = sorted(rl[fac]["personality"].keys())
    deeds = sorted(rl[fac]["deed"].keys())
    ok = sorted(personas) == have == deeds
    bad += 0 if ok else 1
    print(("ok  " if ok else "FAIL"), fac, "stream B:", personas, "pools:", have)
sys.exit(1 if bad else 0)
