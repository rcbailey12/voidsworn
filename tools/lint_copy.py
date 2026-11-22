#!/usr/bin/env python3
"""Automated copy hygiene, IP-alignment & anti-AI-slop lint for Embers of the Hollow Sun."""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
STORY_FILES = [
    ROOT / "godot/story/data/voices.json",
    ROOT / "godot/story/data/situations.json",
    ROOT / "godot/story/data/rival_lines.json",
    ROOT / "godot/story/data/arcs.json",
    ROOT / "godot/story/data/medals.json",
    ROOT / "godot/story/data/titles.json",
]

HARD_BANS = [
    ("em/en dash", r"[\u2014\u2013]"),
    ("UK spelling", r"\b(armour\w*|defence|colour\w*|synchronis\w*|stabilis\w*|favourable|neutralis\w*|fervour|judgement|labelled)\b"),
    ("wet-navy leak", r"\b(sink the|drydock|anchorage|over the rail|rush the rail|below decks|deck crew|every deck)\b"),
    ("stale/IP term", r"\b(Hegemony Navy|HNS |Malek Draven|Oathkeeper|Sun-eater|Endless Swarm|Razormaw|K-1 Kharon|H-3 Crucible|nova cannon|nova shell|deep throat|spit spits|new flesh is angry|Ryan's helpers|the Eclipse)\b"),
    ("double-the flagship", r"\bThe \{flagship\}"),
    ("AI negation-contrast", r"\b(it is not [a-z]+\. it is|that is not [a-z]+\. it is|not because [a-z ]+\. because|is a [a-z]+, not a)\b"),
    ("AI fake-deep definition", r"\b(is (?:also )?a (?:kind|form) of|word for it\.)\b"),
    ("anatomy break", r"\b(tracker's nose|wipes his muzzle|weeping at their stations|in tears|keeper smiles|many-limbed|lost a limb)\b"),
]

CONTR_RE = re.compile(
    r"\b(?:don't|won't|can't|didn't|doesn't|isn't|aren't|haven't|hasn't|it's|we're|they're|you're|i'm|i've|i'll|that's|let's)\b",
    re.I,
)


def strings_of(obj, skip=("_about",)):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k not in skip:
                yield from strings_of(v, skip)
    elif isinstance(obj, list):
        for x in obj:
            yield from strings_of(x, skip)
    elif isinstance(obj, str):
        yield obj


def main() -> int:
    errors = []
    for p in STORY_FILES:
        data = json.loads(p.read_text(encoding="utf-8"))
        lines = list(strings_of(data))
        for s in lines:
            for name, pat in HARD_BANS:
                m = re.search(pat, s, re.I)
                if m:
                    errors.append(f"{p.name}: [{name} '{m.group(0)}'] {s[:110]}")
        if p.name in ("voices.json", "situations.json", "rival_lines.json"):
            contr = sum(len(CONTR_RE.findall(s)) for s in lines)
            if contr < 15:
                errors.append(
                    f"{p.name}: only {contr} contractions across {len(lines)} lines (stiff AI-voice smell; expected >= 15)"
                )

    if errors:
        print("COPY LINT FAILED:")
        for e in errors:
            print("  -", e)
        return 1
    print(f"copy_lint: PASS ({len(STORY_FILES)} story files checked, 0 issues)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
