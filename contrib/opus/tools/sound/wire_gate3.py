"""Wire Wave F from a clean pre-Gate-3 checkout and make Ryan's listening page.

Use master_keepers.py with keepers_gate3.json first.
Then: python wire_gate3.py --mastered <folder> --listen <page folder>
Uses Gate 2's offline level matching. Does not fetch or generate takes.
"""
import argparse
from copy import deepcopy
from html import escape
import json
from pathlib import Path
import shutil
import subprocess

import numpy as np
from master_keepers import write_ogg
from wire_gate2 import G, ROOT, SR, _layers, load, loud, render

AUDIO = Path(G)
SOUND = Path(ROOT) / "contrib/opus/sound"


def mix(cues, index, cue, variant=None, take=0, apply_rate=False):
    c = cues[cue]
    def clip_layers(data):
        rates = {(index[layer["s"]][0], layer["d"]): layer.get("r", 1.0)
                 for layer in data["layers"] if apply_rate and layer.get("s") in index}
        return [(p, g, d, rates.get((Path(p).name, d), 1.0)) for p, g, d in _layers(data, index)]

    layers = clip_layers(c)
    v = c.get("variants", {}).get(variant)
    if v:
        layers_v = clip_layers(dict(c, **v))
        layers = layers_v if v["replace"] and layers_v else layers + layers_v
    if not layers:
        return None
    paths = {}
    for key, names in index.items():
        if len(names) > 1:
            paths[str(AUDIO / "clips" / names[0])] = str(AUDIO / "clips" / names[take % len(names)])
    # Gate 2's loader and envelope measure use a single channel. The review render
    # keeps the captured stereo image of stereo takes.
    from master_keepers import load as stereo_load
    rendered = []
    for p, gain, delay, rate in layers:
        x = stereo_load(paths.get(str(Path(p)), p))
        if rate != 1.0:
            t = np.arange(len(x))
            play_t = np.arange(0, len(x), rate)
            x = np.column_stack([np.interp(play_t, t, channel) for channel in x.T])
        rendered.append((x, gain, round(delay * SR)))
    out = np.zeros((max(delay + len(x) for x, _, delay in rendered), 2), dtype=np.float32)
    for x, gain, delay in rendered:
        out[delay:delay + len(x)] += x * gain * c["g"]
    limit = v.get("duration", c.get("duration")) if v else c.get("duration")
    if limit:
        samples = round(limit * SR)
        if samples < len(out):
            out = out[:samples]
            fade = min(samples, round(0.06 * SR))
            out[-fade:] *= np.linspace(1, 0, fade)[:, None]
    return out


def put_sample(cue, key, gain, keep_tail=False):
    tail = [layer for layer in cue["layers"] if keep_tail and layer.get("s") and layer["d"] > 0.02]
    pitch = cue["layers"][0].get("pj") if str(key).startswith("death_") and cue["layers"] else None
    cue["layers"] = [{"s": key, "g": round(gain, 3), "r": 1, "d": 0, "pj": pitch}] + tail
    cue["synth"] = []


def player(label, file):
    return f'<label>{escape(label)}<audio controls preload="none" src="{escape(file)}"></audio></label>'


def page(out, table):
    (out / "index.html").write_text("""<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sound Gate 3 | Pick by ear</title>
<style>
:root{color-scheme:dark}body{margin:2rem auto;padding:0 1rem;max-width:1100px;background:#111720;color:#e6edf5;font:16px system-ui}
h1,th{text-align:left;color:#f2c28a}p,td{line-height:1.45}table{width:100%;border-collapse:collapse}
td,th{padding:.75rem;border-bottom:1px solid #34404d;vertical-align:top}
label,audio{display:block}audio{width:200px;height:34px;margin:.2rem 0 .5rem}small{display:block;color:#aebed0}
select,button,textarea{font:inherit}textarea{width:100%;min-height:6rem;margin:.75rem 0}
@media(max-width:850px){tr,td{display:block}thead{display:none}td{border:0}tr{border-bottom:1px solid #34404d}}
</style>
<h1>Sound Gate 3</h1><p>Hear the sounds that ship, with the Wave F3 picks and Chorus battle loop first. Each row compares the old cue with the mastered take or takes. A new moment may have no before.</p>
<p>The previews use the cue's mix level, with no battle bus effects or distance. Play one at a time.</p>
<button id="export">Show my picks</button>
<textarea id="picks" readonly aria-label="Picks to send to the Board" placeholder="Your picks will appear here to copy."></textarea>
<table><thead><tr><th>Sound and Neon's note</th><th>Before</th><th>After</th><th>Your pick</th></tr></thead>
<tbody>""" + "\n".join(table) + """</tbody></table>
<script>
document.addEventListener('play', event => {
 for (const audio of document.querySelectorAll('audio')) if (audio !== event.target) audio.pause()
}, true)
const choices = [...document.querySelectorAll('select')]
for (const choice of choices) {
 try { choice.value = localStorage.getItem('gate3:' + choice.id) || '' } catch {}
 choice.onchange = () => { try { localStorage.setItem('gate3:' + choice.id, choice.value) } catch {} }
}
document.querySelector('#export').onclick = () => {
 const field = document.querySelector('#picks')
 field.value = choices.filter(choice => choice.value).map(choice => choice.id + ' = ' + choice.value).join('\\n')
 field.focus()
 field.select()
}
</script></html>
""", encoding="utf-8")
    (out / "LISTEN.bat").write_bytes(b'@echo off\r\nstart "" "%~dp0index.html"\r\n')


def row_html(row, before, after):
    sid = escape(row["id"])
    review = (f'<select id="{sid}" aria-label="Pick for {sid}"><option value="">Choose</option>'
              '<option>Keep</option><option>Swap</option><option>Cut</option></select>')
    return (f'<tr><td><b>{sid}</b><small>{escape(row["note"])}</small></td>'
            f'<td>{before}</td><td>{after}</td><td>{review}</td></tr>')


def music_row(preview, chorus=False):
    tracks = AUDIO.parent / "music/tracks"
    if chorus:
        row = {"id": "mus_chorus_loop_a_test2",
               "note": "Take 1, 24 bars at 76 BPM. Hear the whole loop in calm (no drums) or intense (full mix)."}
        labels = [("fac_chorus", "Before (Chorus bed excerpt)", 12),
                  ("chorus_loop_a_calm", "t1 calm (no drums)", None),
                  ("chorus_loop_a_full", "t1 intense (full mix)", None)]
    else:
        row = {"id": "mus_battle_sunward_stemloop",
               "note": "Steady, dark Sunward weight. Calm holds up on its own and the two mixes switch cleanly."}
        labels = [("fac_voidsworn", "Today (Sunward theme)", 12),
                  ("sunward_stemloop_calm", "After (calm)", 12),
                  ("sunward_stemloop_full", "After (full)", 12)]
    players = []
    for name, label, seconds in labels:
        file = f"{name}_preview.ogg"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(tracks / f"{name}.ogg"),
                        *(["-t", str(seconds)] if seconds else []),
                        "-c:a", "libvorbis", "-q:a", "5" if seconds else "4", str(preview / file)], check=True)
        players.append(player(label, "audio/" + file))
    return row_html(row, players[0], "".join(players[1:]))


def wire_rows(wires, cues, index, mastered, preview):
    old_cues, old_index = deepcopy(cues), deepcopy(index)
    categories = json.loads((SOUND / "wiring_gate2.json").read_text())["categories"]
    targets = {cat: 10 * np.log10(np.mean([10 ** (render(cues, index, n) / 10) for n in names]))
               for cat, names in categories.items()}
    preview.mkdir(parents=True, exist_ok=True)
    table = []
    for r in wires:
        sid, cue, append = r["id"], r["cue"], r.get("append")
        template = r.get("template", cue)
        vs = r.get("variants") or [None]
        key = append or sid
        source = [mastered / f"{sid}_{i}.ogg" for i in range(r["takes"])]
        f3 = r["group"] == "Wave F3"
        # Use the actual old keeper for variety, the first real weapon variant for a
        # polish swap, and the old base cue for brand-new variants.
        baseline = next((v for v in vs if v in old_cues.get(r["today"], {}).get("variants", {})), None)
        before = mix(old_cues, old_index, r["today"], baseline, apply_rate=f3) if r["today"] and not append else None
        old_takes = len(index[key]) if append else 0
        for i, src in enumerate(source):
            name = f"{sid}_{i}.ogg"
            dst = AUDIO / "clips" / name
            if append:
                from master_keepers import load as stereo_load
                old = load(str(AUDIO / "clips" / index[key][0]))
                if r.get("match_rms"):
                    # F2 variety clips are positional mono and match the existing keeper's whole-take RMS.
                    x = load(str(src))[:, None]
                    gain = np.sqrt(np.mean(old ** 2) / np.mean(x ** 2))
                else:
                    x = stereo_load(src)
                    gain = 10 ** ((loud(old) - loud(x.mean(1))) / 20)
                gain = min(gain, 10 ** (-1 / 20) / np.abs(x).max())
                write_ogg(x * gain, str(dst))
            else:
                shutil.copyfile(src, dst)
            index.setdefault(key, []).append(name)
        if not append:
            if "template" in r:
                cues[cue] = deepcopy(cues[template])
                cues[cue].pop("variants", None)
                cues[cue].pop("duration", None)
            c = cues[cue]
            if f3:
                from master_keepers import load as stereo_load
                target = loud(before.mean(1))
                source_db = loud(stereo_load(source[0]).mean(1))
            else:
                target = render(old_cues, old_index, r["today"], baseline) if before is not None else -27.0
                source_db = loud(load(str(source[0])))
            target += 20 * np.log10(r.get("before_gain", 1.0) / r.get("play_gain", 1.0))
            if "category" in r:
                target = targets[r["category"]]
            if sid == "ui_hover_tick":
                target -= 6.0
            if r.get("bed"):
                c.update(bus="ambient", loop=True, max=1, salvo=None)
                # Preserve the terrain beds' mastering gain and leave room for the bridge.
                g = 0.25 / c["g"]
            else:
                g = 10 ** ((target - source_db) / 20) / c["g"]
            if sid == "ship_engine_loop":
                c["loop"] = True
            for v in vs:
                if v is None:
                    put_sample(c, key, g, r.get("keep_tail", False))
                else:
                    dst = {"replace": True, "layers": []}
                    put_sample(dst, key, g)
                    c.setdefault("variants", {})[v] = dst
        if append:
            # Find the live use of this set rather than trusting the old prompt's
            # generic 'today' label (e.g. the Eclipse hit is hit_obsidian).
            routes = [(c, v) for c, data in cues.items() for v, d in [(None, data), *data.get("variants", {}).items()]
                      if any(layer.get("s") == key for layer in d["layers"])]
            if not routes:
                raise ValueError(f"{key} is not used by a cue")
            cue, variant = routes[0]
            before = mix(old_cues, old_index, cue, variant)
        else:
            variant = vs[0]
        if "hold" in r:
            continue
        before_html = "No cue today"
        if before is not None:
            name = sid + "_before.ogg"
            write_ogg(before * r.get("before_gain", 1.0), str(preview / name))
            before_html = player("Today (reference cue)" if r.get("reference") else "Today", "audio/" + name)
        after_html = ""
        for i in range(r["takes"]):
            x = mix(cues, index, cue, variant, old_takes + i, apply_rate=f3)
            name = f"{sid}_after{i + 1}.ogg"
            write_ogg(x * r.get("play_gain", 1.0), str(preview / name))
            label = f"New take {i + 1}" if r["takes"] > 1 else r["pick"] if sid.endswith(("_f2", "_f3")) else "Mastered pick"
            after_html += player(label, "audio/" + name)
        table.append(row_html(r, before_html, after_html))
    return table


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mastered", type=Path, required=True)
    parser.add_argument("--listen", type=Path, required=True)
    parser.add_argument("--baseline", type=Path, help="folder holding the pre-Gate-3 cues.json and index.json")
    parser.add_argument("--sunward-music", action="store_true", help="add already mastered M1 music previews")
    parser.add_argument("--chorus-music", action="store_true", help="add already mastered Chorus Loop A previews")
    args = parser.parse_args()
    wires = json.loads((SOUND / "wiring_gate3.json").read_text())["wires"]
    cue_file = AUDIO / "cues.json"
    index_file = AUDIO / "clips/index.json"
    cues = json.loads((args.baseline / "cues.json" if args.baseline else cue_file).read_text())
    index = json.loads((args.baseline / "index.json" if args.baseline else index_file).read_text())
    if any(r["template"] == r["cue"] or r["cue"] in cues for r in wires if "template" in r):
        parser.error("start with the pre-Gate-3 cue tables")
    preview = args.listen / "audio"
    table = wire_rows(wires, cues, index, args.mastered, preview)
    if args.chorus_music:
        f3_rows = sum(r["group"] == "Wave F3" for r in wires)
        table.insert(f3_rows, music_row(preview, chorus=True))
    if args.sunward_music:
        table.append(music_row(preview))
    cue_file.write_text(json.dumps(cues, indent=1) + "\n", encoding="utf-8", newline="\n")
    index_file.write_text(json.dumps(index, indent=0), encoding="utf-8", newline="\n")
    page(args.listen, table)
    print(f"WIRE GATE3 PASS: {len(wires)} IDs, {len(table)} listening rows")


if __name__ == "__main__":
    main()
