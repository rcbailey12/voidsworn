"""Checks the story outlines (godot/story/outlines.md and outlines_variants.md).

Every beat card (a "### " section whose heading starts with "Beat") is measured as the player will see it:
- base: the card text with conditional [brackets] removed and tokens counted at the length they render
  ({rival} 3 words, {rival_deed} 18, {rival_line} 12, other tokens 2, pronoun tokens 1);
- worst: base plus its two longest conditional brackets (at most two earlier choices show on one card).
Rule: base >= 100 and worst <= 150 (the 100 to 150 word limit, R37). Skim lines ("Skim:") must be 40 words or fewer.
Also: no em or en dashes anywhere, and no plain he/him/his/she/her about the rival inside cards (use {he} {him} {his}).

Run from the repo root: python3 godot/story/test/check_outlines.py
"""
import re
import sys
import pathlib

root = pathlib.Path(__file__).resolve().parents[1]
files = [root / "outlines.md", root / "outlines_variants.md"]
W = {"rival": 3, "rival_deed": 18, "rival_line": 12, "he": 1, "him": 1, "his": 1, "He": 1, "His": 1, "Him": 1}


def words(s):
    n = 0
    for tok in s.split():
        m = re.fullmatch(r"\W*\{(\w+)\}(\W*)(\w*)\W*", tok)
        if m:
            n += W.get(m.group(1), 2) + (1 if m.group(3) else 0)
        else:
            n += 1
    return n


bad = 0
cards = 0
for p in files:
    if not p.exists():
        continue
    t = p.read_text(encoding="utf-8")
    if "—" in t or "–" in t:
        print(f"FAIL {p.name}: em or en dash found")
        bad += 1
    for sec in re.split(r"^### ", t, flags=re.M)[1:]:
        head, _, rest = sec.partition("\n")
        if not head.startswith("Beat"):
            continue
        body = rest.strip().split("\n\n")[0]
        if body.startswith("-") or body.startswith("Skim"):
            print(f"FAIL {p.name}: {head.strip()}: no card text")
            bad += 1
            continue
        cards += 1
        brackets = re.findall(r"\[([^\]]*)\]", body)
        base = words(re.sub(r"\[[^\]]*\]", " ", body))
        extra = sorted((words(b.split(":", 1)[1] if ":" in b else b) for b in brackets), reverse=True)[:2]
        worst = base + sum(extra)
        ok = base >= 100 and worst <= 150
        plain = re.findall(r"(?<![\{\w])(he|him|his)(?![\}\w])", re.sub(r"\[[^\]]*\]", " ", body))
        bad += 0 if ok else 1
        print(("ok  " if ok else "FAIL") + f" base {base:3d} worst {worst:3d}  {p.name}: {head.strip()}" + (f"  (plain pronouns: {len(plain)}, check they are not the rival)" if plain else ""))
        for m in re.finditer(r"^Skim: (.*)$", rest, flags=re.M):
            n = words(m.group(1))
            if n > 40:
                print(f"FAIL skim {n} words: {head.strip()}")
                bad += 1
print("cards:", cards, "fails:", bad)
sys.exit(1 if bad else 0)
