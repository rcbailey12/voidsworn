"""Wire the issue 1752 Gate 2 mastered keepers into the game's sound tables.

Reads contrib/opus/sound/wiring_gate2.json (where each keeper plays) and a folder of mastered files from
master_keepers.py. Copies each clip into godot/audio/clips as <id>_<take>.ogg, adds its clip set to clips/index.json and
edits godot/audio/cues.json: a "base" wire replaces the cue's own layers, a "variant" wire adds a faction variant
("fac" or "fac.weapon_id", read by sfx.gd), "new_from" makes a new cue from a template cue.

Levels: the clip's layer gain is set so the cue plays as loud (loudest 50 ms) as today's game does. "category" matches
the energy mean of today's cues in that group (so the group stays as even as the mastered files); "own" matches that
cue's own level today (charges, shields, deaths and menus keep their place in the mix).

Run it once on a clean checkout (it measures today's cues before editing them):
  python3 contrib/opus/tools/sound/wire_gate2.py --mastered <folder> [--dry]
Needs numpy and ffmpeg. Prints WIRE GATE2 PASS and the level of every wire.
"""
import argparse, json, os, shutil, subprocess, sys
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
G = os.path.join(ROOT, "godot", "audio")
SR = 44100
_cache = {}


def load(p):
    if p not in _cache:
        r = subprocess.run(["ffmpeg", "-v", "error", "-i", p, "-f", "f32le", "-ac", "1", "-ar", str(SR), "-"],
                           capture_output=True, check=True)
        _cache[p] = np.frombuffer(r.stdout, np.float32)
    return _cache[p]


def loud(x):
    w = int(0.05 * SR)
    x = np.asarray(x, np.float64)
    if len(x) < w:
        return 10 * np.log10((x ** 2).mean() + 1e-12)
    c = np.cumsum(np.concatenate([[0.0], x ** 2]))
    return 10 * np.log10(((c[w:] - c[:-w]) / w).max() + 1e-12)


def _layers(cd, idx):
    out, sampled, sl = [], False, None
    for L in cd["layers"]:
        if "s" in L:
            if L["s"] in idx:
                out.append((os.path.join(G, "clips", idx[L["s"]][0]), float(L["g"]), float(L["d"])))
                sampled = True
        elif "syn" in L:
            sl = L
    sy = cd.get("synth", [])
    if sy and (not sampled or sl):
        out.append((os.path.join(G, "synth", sy[0]), float(sl["g"]) if sampled else 1.0, 0.0))
    return out


def render(cues, idx, cue, variant=None):
    """Today's level of a cue (loudest 50 ms, dB) as sfx.gd _layers plays it: first take of each layer, mono."""
    c = cues[cue]
    lay = _layers(c, idx)
    if variant and variant in c.get("variants", {}):
        vd = c["variants"][variant]
        vc = dict(c)
        vc.update(vd)
        vl = _layers(vc, idx)
        lay = vl if vd.get("replace") and vl else lay + vl
    n = max(int(d * SR) + len(load(p)) for p, _, d in lay)
    x = np.zeros(n)
    for p, g, d in lay:
        a = load(p)
        i = int(d * SR)
        x[i:i + len(a)] += g * a
    return loud(x) + 20 * np.log10(float(c["g"]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mastered", required=True)
    ap.add_argument("--wiring", default=os.path.join(ROOT, "contrib", "opus", "sound", "wiring_gate2.json"))
    ap.add_argument("--dry", action="store_true")
    a = ap.parse_args()
    wiring = json.load(open(a.wiring))
    cues = json.load(open(os.path.join(G, "cues.json")))
    idx = json.load(open(os.path.join(G, "clips", "index.json")))
    # today's levels, measured before anything is edited
    cat_target = {}
    for cat, names in wiring["categories"].items():
        lv = [render(cues, idx, n) for n in names]
        cat_target[cat] = 10 * np.log10(np.mean([10 ** (v / 10) for v in lv]))
        print(f"category {cat}: today {min(lv):.1f} to {max(lv):.1f} dB, energy mean {cat_target[cat]:.1f}")
    cat_of = {n: cat for cat, names in wiring["categories"].items() for n in names}
    plans = []
    for w in wiring["wires"]:
        tmpl = w.get("new_from", w["cue"])
        if w["level"] == "category":
            target = cat_target[cat_of.get(w["cue"], cat_of.get(tmpl))]
        elif w["level"].startswith("category:"):
            target = cat_target[w["level"].split(":", 1)[1]]
        else:
            target = render(cues, idx, w["cue"], w.get("variant"))
        plans.append((w, tmpl, target + float(w.get("offset_db", 0.0))))
    report = []
    for w, tmpl, target in plans:
        sets = w["clips"][0]
        files = []
        for t, cid in enumerate(w["clips"]):
            src = os.path.join(a.mastered, cid + ".ogg")
            if not os.path.isfile(src):
                sys.exit(f"missing mastered file {src}")
            fn = f"{sets}_{t}.ogg"
            files.append(fn)
            if not a.dry:
                shutil.copyfile(src, os.path.join(G, "clips", fn))
        idx[sets] = files
        new = loud(load(os.path.join(a.mastered, w["clips"][0] + ".ogg")))
        if w["cue"] not in cues:
            c = json.loads(json.dumps(cues[tmpl]))
            c.pop("variants", None)
            cues[w["cue"]] = c
        cg = float(cues[w["cue"]]["g"])
        g = round(float(10 ** ((target - new - 20 * np.log10(cg)) / 20)), 3)
        layer = {"s": sets, "g": g, "r": 1, "d": 0, "pj": None}
        if w.get("base") or "new_from" in w:
            c = cues[w["cue"]]
            # keep_tail: the cue's late layers (delay over 20 ms) stay under the new clip (RULEBOOK 8.2: shield breaks and
            # capital hits keep their tails; sound_weight_check.gd measures them)
            tail = [L for L in c["layers"] if w.get("keep_tail") and "s" in L and float(L["d"]) > 0.02]
            c["layers"] = [layer] + tail
            c["synth"] = []
            if "duration" in w:
                c["duration"] = w["duration"]
            where = w["cue"]
        else:
            v = {"replace": w.get("mode", "replace") == "replace", "layers": [layer], "synth": []}
            for k in ("duration", "lead"):
                if k in w:
                    v[k] = w[k]
            cues[w["cue"]].setdefault("variants", {})[w["variant"]] = v
            where = w["cue"] + ":" + w["variant"]
        report.append((where, sets, target, g))
        print(f"  {where:32s} {sets:30s} target {target:6.1f} dB  layer g {g}")
    # the ambient room tone and the missed-shot pass-by are code-side clip sets
    for cid, key in (("amb_bridge_bed", "ambient"), ("evt_pass_by_slug", "evt_pass_by_slug")):
        src = os.path.join(a.mastered, cid + ".ogg")
        old = os.path.join(G, "clips", idx[key][0]) if key in idx else None
        fn = f"{cid}_0.ogg"
        if not a.dry:
            shutil.copyfile(src, os.path.join(G, "clips", fn))
        if old:
            o, n = load(old), load(src)
            db = 10 * np.log10((o ** 2).mean() / (n ** 2).mean())
            pk = loud(o) - loud(n)
            print(f"  {key}: today's clip is {db:+.1f} dB RMS, {pk:+.1f} dB loudest 50 ms, against the new one")
        idx[key] = [fn]
    if not a.dry:
        with open(os.path.join(G, "cues.json"), "w") as f:
            f.write(json.dumps(cues, indent=1) + "\n")
        with open(os.path.join(G, "clips", "index.json"), "w") as f:
            f.write(json.dumps(idx, indent=0))
    print(f"WIRE GATE2 PASS: {len(report)} wires" + (" (dry run, nothing written)" if a.dry else ""))


if __name__ == "__main__":
    main()
