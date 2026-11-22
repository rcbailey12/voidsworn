# Fable (audit): the Nov 22 merges, read blind

Commit read: main at 513731da.

Blind: issue 1723 and contrib/codex/reviews/astra_audit_1122.md were not opened. These findings are evidence for the Board,
not rulings.

Merged PRs read (each as its full merged diff): 1631, 1646, 1666, 1699, 1719, 1709, 1715, 1643, 1698, 1706, 1710, 1714.
PR 1721 is not on main and was not read.

Short answer: nothing crashes and every check tied to these merges passes, but one cross-PR clash should be fixed before the
next playtest build (finding 1: ships that die with dipped lights stay dim through the whole death), and five more are
worth a fix.

## Proof of read

Big files were read as today's merged diffs in full plus the named ranges, not end to end. "Whole" means every line.

| file | lines | last line (first 40 chars) | read |
|---|---|---|---|
| godot/fx/fx_ship.gd | 2574 | `		_dmg_request(fx)` | diffs; 1380-1480, 2100-2150, 2380-2574 |
| godot/fx/fx_hull.gd | 1881 | `				(lb["node"] as Node3D).transform = (` | diffs; 300-360 |
| godot/fx/fx_weapons.gd | 2603 | (blank) | diffs only |
| godot/fx/fx_death.gd | 4243 | `		nd.global_position -= back` | diffs; 850-900, 2480-2540, 3030-3070, 3640-3680 |
| godot/fx/fx_death_beats.gd | 562 | `			_implode(fx, s, p, T - 0.25)` | whole |
| godot/fx/fx.gd | 2264 | `	return hk` | diffs only |
| godot/fx/fx_shaders.gd | 2469 | `"""` | diffs; 1060-1100 |
| godot/scenes/battle/battle.gd | 7036 | `	get_tree().quit(code)` | diffs; 2770-2800 |
| godot/render/build_assets.gd | 577 | `				return` | whole |
| godot/render/ship_view.gd | 1788 | `		ring.rotation.y = -rotation.y` | diffs; 1640-1660 |
| godot/ui/battle/ledger.gd | 1020 | `				act.emit(h.act, h.arg)` | diffs; 250-275 |
| godot/ui/battle/hud.gd | 1530 | `	ledger.mark()` | diffs only |
| godot/audio/sfx.gd | 631 | `	create_tween().tween_property(_amb, "vo` | diffs; 40-65 |
| .claude/hooks/guard.cjs | 452 | `}` | whole |
| .claude/settings.json | 124 | `}` | whole |
| tools/recipe/gamedata.py | 81 | `    print(weapons(sys.argv[1]))` | whole |
| docs/RULEBOOK.md | 652 | `draws meshes at full detail. Set: Ryan, ` | diffs; 285-300 |

## Findings (10, most important first)

| # | level | finding | seen how | file:line | exact quote | why it matters | fix | confidence |
|---|---|---|---|---|---|---|---|---|
| 1 | BLOCKING (before the next playtest build) | PRs 1631 and 1719 against the death code. A hull that dies while its lights are dipped (a recent heavy hit, or a wrecked mid or prow section) keeps the dip for its whole death. The death copies the live surface with the dip in it; the reset that follows only touches the live surfaces, which are no longer on the mesh. | OBSERVED by probe (numbers, not pixels) | godot/fx/fx_death.gd:2512; godot/fx/fx_ship.gd:2424; godot/fx/fx_hull.gd:339 | `mat = source.duplicate()` ; `_write_flick(1.0)` ; `EMISSION *= (1.0 - fx_soot) * clamp(fx_power, 0.0, 1.0) * fx_flick;` | Most ships that die have a wrecked section, so most deaths run with hull lights at about 44 to 50 percent. It flattens the approved death looks, most of all the Navy "all lights on, then blackout" beat. | Set fx_flick to 1.0 on the copied death material (or write the reset before the copy). Add the probe's case to live_wounds_1587_check. | High on the numbers; medium on how strong it looks on screen |
| 2 | SHOULD-FIX | PR 1666. A ram kill now reaches the effects as "ram", so the two "big" branches no longer run for it: one fewer wreck piece, and no shrapnel cone away from the impact. The playbook still promises both. | OBSERVED | godot/scenes/battle/battle.gd:2796; godot/fx/fx_death.gd:875; godot/fx/fx_death.gd:3056; docs/playbooks/deaths_and_hits.md:150 | `return "ram"` ; `if cause == "big" or cause == "flay":` ; `if cause == "big":` ; `Torpedo or ram (big)` | Ram deaths lost part of their look without anyone choosing that. | Treat "ram" like "big" in those two branches. | High |
| 3 | SHOULD-FIX | PRs 1631 and 1666. New debris calls throw the plain metal shard on every faction, Chorus and Glasswright included. That shard glows orange, and the ram sparks are brass on every faction. | OBSERVED in code; not seen on screen | godot/fx/fx_ship.gd:2492; godot/fx/fx_death_beats.gd:190, :374, :183; godot/fx/fx_shaders.gd:1088 | `EMISSION = vec3(1.0, 0.33, 0.06) * vHeat * 1.2 * fx_gain;` ; `var metal := Color(1.0, 0.82, 0.55)` | Hot orange metal off a flesh ship or a glass ship breaks R367 and R402 (each faction breaks in its own material and colours). Older code nearby does branch per faction. | Pick the shard kind and spark colour from the faction, as fx_ship.gd 2132-2140 already does. | High on the code; medium on how visible at camera 170 |
| 4 | SHOULD-FIX | PR 1706. The new guard refuses any shell command with a word ending in `.key`. `board.key(` is in battle.gd 27 times, so ordinary searches of the game code are refused with "Use the masked key installer for credentials". | OBSERVED by running the hook | .claude/hooks/guard.cjs:309 (pattern at :14) | `if (command.split(/[\s"'=|&;<>()[\]{},]+/).some(shellSecret) \|\|` | Workers lose time to false alarms and learn to work around the guard. The Grep tool is not affected. | Match `.key` only on a path-like word (has a slash or is a bare file name that exists), or drop `.key` from the shell check and keep it for file reads. | High |
| 5 | SHOULD-FIX | PR 1710. The rulebook and CLAUDE.md still send ship weapon list and hull edits to data.js "because the ship pipeline still reads it". It no longer does: gamedata.py has no data.js reference and reads the Godot table. | OBSERVED | docs/RULEBOOK.md:296-298; CLAUDE.md:15-16; tools/recipe/gamedata.py (whole file) | `a change to a ship's weapon list or hull entry also goes into data.js,` | A worker following the rule edits a frozen file that nothing reads, and may skip the Godot table. | Remove the exception from both documents in one PR (R214), and tidy the stale data.js comments in tools/recipe/export7.py. | High |
| 6 | NOTE | PR 1714. A time-limited import run starts again at the first ship folder each run and re-hashes it. If hashing the fleet ever takes longer than the limit (120 s in play_godot.bat), later ships are never reached and the version marker is never written. | INFERRED (fleet size and PC speed not measured) | godot/render/build_assets.gd:345-351 | `the version marker stays unset and the next run carries on from here.` | Could leave the tail of the fleet un-refreshed on every launch, quietly. | Remember the last finished folder, or skip the hash when file size and time are unchanged. Time one full pass on the PC first. | Medium |
| 7 | NOTE | PR 1666. The rolling burnout death (about a quarter of small breaking deaths) ends without the core flash. Rule 6.10 says the flash core stays so a death always reads as a death. The playbook documents the new death and Ryan gave the merge go, but the rule text was not changed with it. | INFERRED (rule reading) | godot/fx/fx_death.gd:3663; .claude/rules/godot-battle.md 6.10 | `fx.resolve_death_core(s, true)` | Rule and game disagree; the next auditor will flag it again. | Add one line to 6.10 naming the exception, or give the burnout a small flash. Ryan's eye decides. | Medium |
| 8 | NOTE | PR 1706. The main-branch guard only looks for the literal word push, so a git alias gets a push to main past it. Its README says nothing else ever reaches main. | OBSERVED by running the hook (`git -c alias.p=push p origin HEAD:main` passes) | .claude/hooks/guard.cjs:259 | `if (gitSubcommand(words) !== 'push') continue;` | The guard stops mistakes, not intent. GitHub branch protection is the real lock. | Soften the README claim; rely on branch protection. | High |
| 9 | NOTE | PR 1699. The pass-by sound is one take of a clip named "whoosh", defined in code and not in the cue file. Rule 8.1 bans rising whooshes and 8.4 asks for four takes. | OBSERVED in code; not heard | godot/audio/sfx.gd:48-52 | `"layers": [{"s": "whoosh", "d": 0.0, "g": 1.0, "r": 1.0, "pj": null}],` | Needs Ryan's ear. He also parked new sound wiring on Nov 21. | Move it into cues.json with the other cues and put it on a Pick Sheet with a clip. | Medium |
| 10 | NOTE | PRs 1699 and 1666. Eclipse violet is typed by hand in three places with three different values, not read from faction_looks.json. | OBSERVED | godot/fx/fx_ship.gd:1415; godot/render/ship_view.gd:1652 | `Color(0.59, 0.38, 1.0)` ; `"deathless": Color(0.57, 0.38, 0.96)` | A palette change will miss them (rule 6.10: one faction colour file). | Read them from faction_looks.json. | High |

## Finding 1: the probe

Script: contrib/fable/reviews/audit_1122_probe/flick_death_probe.gd. Run from the repo root:

`godot --headless --path godot --script ../contrib/fable/reviews/audit_1122_probe/flick_death_probe.gd`

Output on 513731da (Godot 4.7.2 headless):

- Case A, a 0.70 power hit then a kill (Navy and Crusade hulls): live fx_flick before the kill 0.437; the death material on
  the mesh reads 0.437 at 0.05 s, 0.30 s and 0.60 s into the death.
- Case B, mid and prow sections wrecked, then a kill: live fx_flick 0.500 before the kill; the death material stays at
  0.500 at 0.05 s, 0.30 s and 0.60 s.

## Ready / verified

Checks run on 513731da in a cloud container, all PASS: list (227 scripts), plan_commit_check, death_plane_check,
death_variety_1586_check, wave_1a_check, melt_death_check, live_wounds_1587_check, torpedo_flat_flight_check,
install_refresh_check, hold_beacon_check. .claude/hooks/guard.test.cjs also passes.

- PR 1646: each faction's cook-off blasts are back at the break; the melt death skips the beats it should.
- PR 1719: the power step runs before the wound step each frame, so the order is right while the ship lives.
- PR 1709: the prompts are drawn in the turn block before the playback early return, so they are not hidden.
- PR 1715: torpedoes fly flat, with the launch rise capped.
- PR 1643: the can-fire test includes weapon ready, and the ram, board and death event shapes match the rules.
- PR 1699: attachments ride the ship mesh; the marker and ring stay on the root; the Chorus has no thruster jets.
- PR 1706: the rulebook split kept every numbered rule from 3.5 to 9.19, 9.17a included.
- PR 1698: read as code only; nothing found.

## Recommended next step

Fix finding 1 first: one small PR that resets fx_flick on the death material, with the probe case added to
live_wounds_1587_check, then one PC death clip of a Navy capital to confirm the "all lights on" beat by eye.

Not checked: any GPU picture or clip at camera 170 for any PR; the mesh LOD look from PR 1698 (gaps between skin patches,
thin parts); PR 1721; the look bench result files; test files line by line; tools/blender changes beyond their text; the
large files end to end (see the table); the state of Ryan's PC; issue 1723 and Astra's audit (blind by instruction).
