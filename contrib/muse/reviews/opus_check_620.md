# Outside check of PR 620 (issue 618, Eclipse E11 and E12 through the ship recipe)

Refs #256

PR 620 merged on Nov 13, 2026 at 02:40 CST (head 8ec0d74db6) before this check ran, so this is an after-the-fact check, like the checks of PR 524c and PR 611: it grades what the merged changes do. Most of the PR is build-sheet data and pictures for the two ships; this check covers the five shared-tool centres the Board named, which every future ship build runs through.

## Verdict: GO WITH CONDITIONS

One BLOCKING (centre 4). The slot dealing, the multi-seam path, the spinal fix and the stage 3 camera fix are all sound, with NOTEs recorded below.

## Council

Blind Rey leg written first, then four external legs, all gated: DeepSeek (DeepThink on, Search off, verified at both ends of the run), Qwen (selector Qwen3.8-Max verified before submitting and in the chat header after), Flash (Gemini picker label "Quick answers 3.5 Flash-Lite" verified before and after), Grok (default Fast mode; the pack supplied in full as pasted text, Grok has no file upload). Grok's first window died while waiting on its Google sign-in; the leg was relaunched at Ryan's direction and completed. Argon took no seat, per Ryan's Nov 12, 2026 ruling for the #256 queue (its Google AI Pro gate is blocked).

Leg verdicts: DeepSeek GO WITH CONDITIONS, Qwen GO, Flash GO WITH CONDITIONS, Grok GO, blind Rey GO WITH CONDITIONS (NOTEs only). The chair's grades below differ from the blind leg on centre 4, for the reason stated there.

## Centre 1: contract.py slot_map

SOUND. The dealing arithmetic (hits[k * len(hits) // len(fids)]) is right for every combination: equal counts deal one slot per mount in build order; more mounts than slots partitions them across the slots in order with no slot starved; a pair listed once gives that slot to every mount (the battery case); fewer mounts than slots and unlisted pairs are refused by name. Turret pivots now take their slot from the same map the muzzles use, and a pivot with no gun record is refused by name, so a pivot and its muzzles can no longer disagree. All five legs concur.

- NOTE 1.1 (blind Rey, DeepSeek concurring): the record returned by to_recipe changes its 'slots' field from a dict keyed by weapon and arc to a list of 'index weapon arc' strings. The change is justified (a dict collapses the duplicated 'gauss T' entries), but any consumer of the old shape breaks silently rather than by name. Not checked: which stage tools read that field.
- NOTE 1.2 (Grok): when mounts outnumber slots, the surplus mounts are batched onto the dealt slots by the floor division without comment; the slot_map docstring spells out only the fewer-mounts refusal. Behaviour matches the battery rule, but the edge deserves the sentence.

## Centre 2: several longitudinal seams

SOUND in the main path. The contract refuses by name a seam whose span strictly contains a transverse station (x0 < t.x < x1) and checks every authored seam; it writes r209_l_lines (all seams, sorted) and keeps r209_l_line as the first for older readers. The audit loops every seam in plumbing.py, and export7 writes every seam into the GLB destruction record. The selftests were genuinely reworked: bad_longitudinal poisons both keys, no_longitudinal deletes both, and sheet_contract_selftest asserts every seam reaches r209_l_lines at its own height and span, asserts every data.js slot has muzzles of its own, and replaces the old two-seams refusal with the crossing refusal.

- NOTE 2.1 (DeepSeek, Qwen, chair verified in fx_death.gd on main): the contract does not refuse two longitudinal seams in the SAME transverse compartment. fx_death.gd applies each span seam to the compartment of its midpoint: it offsets that compartment's seed, appends a half-size piece, and names the original compartment as the break's parent. A second seam in the same compartment applies the same transform to the same seed a second time (double offset, a second half-size piece) after the first seam has already split the piece. No shipped ship does this (E11's two peel seams sit in different compartments), and the stated rule R225 (c) does not forbid sharing. Recommend the contract refuse two seams in one compartment by name, or the Board confirm sharing is intended and the seed handling is correct for it.
- NOTE 2.2 (blind Rey, DeepSeek): audit.py and export7.py prefer r209_l_lines whenever the key exists, including as an empty list; a scene carrying r209_l_lines empty alongside a real r209_l_line would silently test and export no longitudinal seam. The contract never writes that state, so this is a hand-edited-scene hazard only.
- NOTE 2.3 (blind Rey): the contract reduces each seam to [mean z, min x, max x]; a path wandering in z is exported as a level plane at its mean height, and the selftest computes the same mean, so the suite cannot catch the misrepresentation. E11 and E12 author level seams, so this is a format limit to record.
- NOTE 2.4 (DeepSeek): coverage gaps in the reworked tests: with bad_longitudinal poisoning both keys, the r209_l_line-only fallback is no longer exercised; onto_seam moves a part onto the first seam only, so the plumbing loop is untested against a second seam; export7 validates seam length only (len 3), where the audit also checks x0 < x1, so a degenerate seam reaches export if the audit stage is skipped.

## Centre 3: the spinal gun's aim and bore, and the wrong_side fallback

SOUND. kit.py now records aim and bore into the fit record; before this PR the contract read a spinal gun's muzzle radius as float(fd.get('bore', 0)), a hard point of radius 0. The muzzle moved from the horns' meeting point (open space ahead of the emitter, which the export check refuses as off-mesh) to (length - bl * 0.24, 0, 0) on the emitter axis, and bore = brr * 0.82 matches the shade profile radius at the adjacent station (length - bl * 0.25, brr * 0.82) in the same function: the bore is the emitter's real throat radius. The wrong_side fallback mirrors the port boarding origin on ships with no port weapon arc; the expected message is derived from the pristine export, and both candidate messages exist in the real checker (check_export.py line 220, 'a port mount must sit and aim to port'; line 259, 'a port boarding origin sits on the other side'; both chair-verified on main).

- NOTE 3.1 (blind Rey): port_point raises StopIteration if a ship had neither a port weapon point nor a port boarding origin; the selftest would crash rather than fail by name. Theoretical: hp_board is a required point on current ships.
- NOTE 3.2 (DeepSeek): the new muzzle is a point on the axis inside the bore aperture, not on a surface; that the export check's off-mesh test accepts it is not provable from the patch alone. Qwen, Grok, Flash and the blind leg all read the geometry as on-mesh at the shade rim. Recorded as unverified against a live export run, not as a defect.
- NOTE 3.3 (DeepSeek): with the fallback, the weapon-port wrong_side rule is no longer exercised on Eclipse hulls; its coverage now depends on another ship in the suite having a port arc.

## Centre 4: the fixture guard

BLOCKING 4.1 (DeepSeek, Flash; chair upholds): sheet_fixture_hash.py still omits inputs of the fixture it guards. The seven listed files close step 1 (sheet_hull.py imports only kit and contract, both listed, plus the design file, the Hullbreaker parts and A16's ship json). But the fixture itself is the export7 product: death_seam_check.gd's header states the fixture is 'tools/recipe/export7.py unbaked=1 on the A16 build', and the death test reads seams and machine boxes from that export. export7.py imports hardpoints.py, gamedata.py and turrets.py, none of them listed, and uses all three: line 137 writes destruction['machines'] = machine_boxes() into the GLB; lines 91 to 97 mark and collect turret pivots through turrets.py; lines 59 to 64 take WEAPONS, CLS, FAC and HANGAR from gamedata; lines 189, 243 and 414 take breach layout, required points and turret arcs from hardpoints.py. A change to any of the three can change the fixture while all seven hashes stay identical, so --check passes on a stale fixture. That is the same failure the check of PR 611 graded BLOCKING 1. Fix: add hardpoints.py, gamedata.py and turrets.py to FILES in sheet_fixture_hash.py.

Dissents recorded: Qwen and Grok graded the centre sound, reading the three modules as hard-point metadata that contributes no mesh geometry or seam data, within the guard's stated 'sheet geometry' scope. The blind Rey leg flagged the same omission as NOTE 4.1 on that narrower reading. The chair's grade rests on the fixture's own documentation (the fixture is the export, and the test consumes the export's machine boxes), not on the docstring's narrower phrase.

## Centre 5: the Board's stage 3 fix (commit ff16585f)

SOUND. 3_trace_hull.bat clears CAMJ before the read, quotes the fit-branch assignment (the old unquoted set carried a trailing space into the path), and fails by name when no camera file exists after the if/else. The two-ship camera bleed and the silent missing camera are both closed.

- NOTE 5.1 (DeepSeek, Qwen): the failure text's trailing clause ('the camera fit wrote nothing') is accurate only in the fit branch; in the repo-camera branch no fit ran. The clause that names the missing path is right in both branches. Cosmetic.
- NOTE 5.2 (DeepSeek): the new check tests existence, not freshness; a leftover concept_camera.json from an earlier run satisfies it if a later fit fails silently. The fix clears the variable, not the file.

## Not checked

The build-sheet data and pictures for E11 and E12 themselves (outside the five centres). fx_death.gd, which this PR does not change; its span-seam block was read on main only to verify NOTE 2.1's mechanism. No Blender or Godot run was re-executed by the chair; geometry claims rest on the patch text and the verified facts in the pack.
