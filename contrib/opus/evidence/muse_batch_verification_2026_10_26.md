# Muse batch of Oct 26: independent verification

Verifier: Opus (independent leg, R46 rule: validate before incorporating). Date: Oct 26, 2026, evening.
Tree checked: main at 4b07105. Several helpers committed while this ran; the two G2 commits that landed during the check (26f2bd5 and 916fe9d, 17:32) fixed several items and are cited where they apply. Line numbers are from 4b07105 unless a commit is named.

**Verdicts:**
- CONFIRMED: true in the current tree.
- FIXED in `<commit>`: true when the review was written, fixed since.
- PARTLY: the core is true, a detail is wrong or overstated.
- DISPUTED: false, with the evidence.
- UNVERIFIABLE: cannot be settled from the repo; says what would settle it.

**Owner streams:**
- G1: rules, `godot/rules`.
- G2: battle and integration (`godot/main`, `godot/scenes/battle`, `godot/render`, `godot/ui/battle`).
- G3: campaign, `godot/campaign` and `godot/ui/campaign`.
- G4: fx, `godot/fx` and `godot/world`.
- A4: ships.
- B: the JS rules.
- Story: `godot/story`.
- MP: music and portraits.

Nothing reviewed was edited, and no game code was touched.

---

## 1. Godot migration review (godot_migration_review.md, with the Rey leg)

| # | Claim | Verdict | Evidence | Owner |
|---|---|---|---|---|
| 1.1 | The campaign RNG is never seeded in the shipped shell. newRun draws foes, patrons, relic, map and Nemesis from a stream starting at 0. | FIXED in 26f2bd5 | Before the fix, `jsm.gd:52` set `static var rng_s: int = 0`. The only seeds were battle paths (`campaign.gd:2105, 2291`, `battle_api.gd:29`, `rules.gd:1044`) and the standalone `campaign_scene.gd:27`. `main.gd`, `campaign_host.gd`, `title.gd` and `story.gd` had none. Now `campaign_host.gd:56` calls `_seed_campaign(... randi())` before `persist_load` and `continueRun`. Its fallback (`:93-97`) calls `JSM.rnd_seed` until G3 adds `campaign.seed_rng()`. | G2 (done); G3 (`seed_rng`) |
| 1.1a | Extra, not in the review: shell bot runs did not seed the campaign stream either. | FIXED in 26f2bd5 | Before the fix, `campaign_host.gd` set only `rng.seed` (the bot's choice dice) from `--seed`. The first run of every bot batch therefore drew the same foes, map and Nemesis, and a hang seed could not be replayed alone. Now bot runs seed from `--seed`. | G2 |
| 1.1b | Open question 2: should a loaded run reseed or resume the stream? | Answered | The browser never saves the stream. `core.js:4` sets `let RNG_S=(Math.random()*4294967296)>>>0`, and no save writes RNG_S. A continued run gets fresh draws, and 26f2bd5 matches that. | none |
| 1.2 | Threading is safe by scene convention, not by the API: only `step()` locks, `view()` runs on the worker, `threat_map()` clears shared eval caches, and `jsm.gd` shares one scratch buffer. | PARTLY FIXED in 26f2bd5 | Still true: `battle_api.gd:505-518` is the only `_mutex.lock()`. The worker closure still calls `api.view()` (`battle.gd:655`). `rules.gd:177-182` `eval_begin`/`eval_end` clear the six caches. `jsm.gd:15` `static var _pb` is unchanged. Added by 26f2bd5: main-thread paths call `_api_join()` (`battle.gd:736`), which finishes a running threat map and refuses while the enemy thinks, and `_exit_tree()` (`:746`) drains both tasks. The scene now enforces the rule. The API itself still does not, and the static `_pb` race remains. | G1 (`_pb`, API lock); G2 (done for the scene) |
| 1.3 | Blanket warning suppression in `rules.gd`, `jsm.gd` and `battle_api.gd`; only 6 of the 17 classes are set to warn in the project. | CONFIRMED (with the 6-of-17 correction) | `rules.gd:11`, `jsm.gd:13` and `battle_api.gd:6` list the same 17 classes. `project.godot:14,15,17,23,24,27` set exactly six to 1: unsafe_property_access, unsafe_method_access, unsafe_call_argument, integer_division, narrowing_conversion, return_value_discarded. `campaign.gd` has no warning_ignore. | G1 |
| 1.4 | The export ships the campaign test oracle (about 516 KB of JS plus harness). | FIXED in 916fe9d (and overstated) | The old `export_presets.cfg:11` excluded only `rules/test/*, audio/build/*`. However, `export_filter="all_resources"` plus `include_filter="*.json"` would not pack `.js` files, which Godot does not treat as resources. So the 516 KB JS figure was probably wrong. What did ship were the test `.gd` scripts (`campaign/test`, `fx/test`, `music/test`, `story/test`) and `story/test/fixture_arc.json`. Now the filter excludes `*/test/*` and every named test tree, `main.gd` has `--check-export`, and the version fields are set. | G2 (done) |
| 1.4a | The export path disagrees with FEATURES.md. | DISPUTED | The preset writes `../export/Voidsworn.exe` relative to `build\godot\`, which is `build\export\Voidsworn.exe`. That is the FEATURES path, and `tools/pc/play_godot.bat:17` and `jobs/g2_export.bat:25` use it. 916fe9d now says so in FEATURES.md. | none |
| 1.5 | JSM unported maths edges return 0.0 and play continues (`jsm.gd:162, 225, 240, 317, 352`). | CONFIRMED | All five sites are `push_error(...); return 0` or `0.0`. Line 162 returns quadrant 0 from rem_pio2, so sin and cos then run on the unreduced value. My read: game-scale inputs (hex distances, angles) are unlikely to reach these, but the rules layer's NOT PORTED stop is the safer shape. | G1 |
| 1.6 | NOT PORTED is logged, cleared, and the partial batch plays. | CONFIRMED | `battle.gd:665, 677` log `_error("NOT PORTED")` and continue. 26f2bd5 only moved the read behind `_api_not_ported()`. X20 says only 2 `np()` guards are left (unknown trait, unknown boon). | G1 + G2 |
| 1.7 | `view()` returns `arena` and `shMax` by reference against its read-only contract. | DISPUTED | `B["arena"] = ARENA["kind"]` is a String (`rules.gd:1060, 1096`), and `shMax` is a float from `JSM.jsround` (`rules.gd:381, 1002`). Both are value types in GDScript, so nothing aliases. One small real alias: `"hexes": _hexes` hands out the API's own cache array (`battle_api.gd:100`). | G1 (`_hexes` only, low) |
| 1.8 | The campaign save write is not atomic (copy to .bak, then overwrite in place). | CONFIRMED | `campaign.gd:362-375`, unchanged. Settings are now atomic (916fe9d, `main.gd save_settings`: temp file plus rename). Settings still carry no version field (`main.gd:20`). | G3 (campaign save); G2 (settings version) |
| 1.9 | Soft dependencies degrade silently; `fx_stub` still runs beside the real fx. | CONFIRMED | `campaign_host.gd` still falls back to `Fallback.new()` when the G3 UI is missing. `battle.gd:24` still preloads `fx_stub.gd`. 916fe9d `--check-export` now flags missing real parts in an exported build, so the packaging half is FIXED. See 2.10 for which cues the stub still owns. | G2 |
| 1.10 | The build cannot be reproduced from the repo alone: gen/ absent, A4 sources off-repo, sky and asteroid inputs fall back to `contrib/opus/enginetest`, freshness keyed on GEN_VERSION only, silent BoxMesh fallback. | CONFIRMED | `build_assets.gd:12` (GEN_VERSION 3), `:59, :421-422` (enginetest fallbacks), `:83-84` (`_current` checks version and file existence only), `ship_view.gd:92` (BoxMesh). gen/ is absent by design (`.gitignore` lists `gen/`), and the ships README says the A4 .glb files stay on the PC. | G2 + A4 |
| 1.11 | The music content is missing while docs claim it, and `music_check.gd` cannot pass. | PARTLY FIXED in 916fe9d | `godot/music/` holds only the README, the player and its test. `music_check.gd:35` requires tracks > 0. FEATURES.md now says Music is "partial" (916fe9d). Correction: Job 5 is not empty. `tools/music/catalogue.json` (f73e807) lists the licence of each of 33 candidate OpenGameArt tracks. | MP |
| 1.12 | The dual vendored oracles have a manual re-copy step but no automated cross-check. | CONFIRMED | Both READMEs pin c7b1a78 and have a "Catching up" paragraph. `battle.js`, `core.js` and `data.js` are byte-identical today (cmp). Neither runner compares the two copies. Small doc drift: the rules README calls c7b1a78 "steps 0 to 2", the campaign README "steps 0 to 3". | G1 + G3 |
| 1.13 | The hand-copied render and world constants are unguarded. | CONFIRMED | The `hull_table.gd:1-4` header says AI_HULLS, CLS_LEN, FAC3D and FINISH are "taken from ships3d.js". `world.gd:12` BIOMES is from scene3d.js. There is no diff check. | G2 + G4 |
| 1.14 | CUT/SOLID: does the canonical hash cover them? | FIXED in e83bae2 (before the review) | `golden.js:145` puts `gl={cut:[...CUT].sort(), solid:[...SOLID].sort(), uid:UID}` in the hash. `parity_main.gd:59-63` matches it. The README line is right and the pack was stale. This was already recorded in X20. | none |
| 1.15 | FAC_PRICE has zero GDScript hits; is it JS-only? | Answered | `data.js:541` folds FAC_PRICE into each hull's `cost` at load. The exported tables carry the priced costs, and the name appears in both `tables.json` files. No live gap. | none |
| 1.16 | `ui_info()` does not wrap its weapon loop in `eval_begin`/`eval_end`. | CONFIRMED | `battle_api.gd:279-313` has no `eval_begin`. Its siblings at `:192, :323, :440` do. | G1 |
| 1.17 | Worker tasks are not drained on mid-battle quit. | FIXED in 26f2bd5 | `battle.gd:746` `_exit_tree` waits on both task ids. `main.gd quit_clean` frees the battle first. | G2 |
| 1.18 | A runtime error inside `step()` can leave the mutex locked. | CONFIRMED (inferred risk) | `battle_api.gd:505-518` has no unlock path on error. GDScript has no try/finally. | G1 |
| 1.19 | Hull section count is 3 (engine, mid, prow). | CONFIRMED | `fx_hull.gd:6` ("eng aft third, mid, prow fore third") and the rules section keys (`rules.gd:2184` map). | none |

**Conflicts with FINDINGS, plan or rulings**
- The migration review's item 13 asks for a smoke assertion that the real parts loaded. 916fe9d `--check-export` does that for the exported build. Bot mode does not run it yet.
- X20 already says "CUT, SOLID and UID now hashed". The synthesis carried this as UNSURE, so the registry was ahead of the review.

**Proposed incorporation:** G1 owns 1.2 (`_pb` thread-local or local arrays, and either a lock on every public API entry point or a debug assertion), 1.3, 1.5, 1.16 and 1.18. G1 also proves the NOT PORTED set empty, or turns it into a hard stop at cutover (1.6). G3 owns the atomic campaign save (1.8) and `campaign.seed_rng()`. G2 adds a bot-mode `--check-export`-style assertion and a constants diff check (1.13), and moves the sky and asteroid inputs out of enginetest (1.10). Items 1.7 and 1.4a are closed.

---

## 2. Effects implementation review (fx_implementation_review.md, with the Rey leg)

The fx code is unchanged since ec23549 (13:12), so every line number in the pack still matches.

| # | Claim | Verdict | Evidence | Owner |
|---|---|---|---|---|
| 2.1 | Flash merge window: constant 0.12, comment 0.33, API doc 0.12, spec B 0.33. | CONFIRMED (but see conflicts) | `fx.gd:28` `FLASH_WINDOW := 0.12`, `fx.gd:313` comment "inside 0.33 s", `API.md:128` "within 0.12 s". The 0.33 in a5_effects_sheets_synthesis.md section 8 is a "Chair recommendation (not leg agreement, for Opus to test)". | G4 |
| 2.2 | The counting window is two-sided, not trailing. | CONFIRMED | `fx.gd:319-323` uses `absf(f - T)` both for the merge test and the 1.0 s count. A flash inside the merge window returns true before the cap is checked (`:320-321`). | G4 |
| 2.3 | `flash_ok` measures no brightness, size or emitter. | CONFIRMED | `fx.gd:315-334` takes only T. | G4 |
| 2.4 | Ungated bright emitters inside G4: battery muzzle core (intensity 11), beam contact sprite, event lights, torpedo fireball, death flame train. | CONFIRMED | `fx_weapons.gd:317-322` (muzzle core checks only `reduce_flashing`), `:701`, `fx.gd:349-353` (`light()` attenuates only under `reduce_flashing` and decay shape), and `fx_death.gd:684-690`. | G4 |
| 2.4a | Extra: the G2 placeholder `fx_stub` still draws bright flashes beside G4, outside the budget and reduce mode. | CONFIRMED (new) | `battle.gd` calls `fx.flash` (the stub, `battle.gd:24`) with no `gfx` gate for risen (`:891`, size 16), blink (`:900`, `:904`, size 18), ram (`:990`, size 30) and board (`:1009`, size 14). The stub has no `reduce_flashing` property. | G2 |
| 2.5 | `light()` is not attenuated when `flash_ok` refuses. | CONFIRMED | `fx.gd:349-353`. `pop()` (`:338-345`) never touches lights, and callers fire `fx.light` unconditionally (`fx_weapons.gd:629`). | G4 |
| 2.6 | Sustain-shape event lights keep an 8 Hz flicker in reduce mode. | CONFIRMED | `fx.gd:378` `0.88 + 0.12 * sin(now * 50.0)` is 7.96 Hz with no reduce check. Light sources do slow down (`:391-392`). | G4 |
| 2.7 | Light looks (auto, las, scatter, guns, flak variants, prism) leave no decal; everything except gauss and bio leaves the same generic scorch. | CONFIRMED | `fx_weapons.gd:590`, `:635` (`not light`), `:729` (beam 1.8), `:821` (torp and ram 2.6). Ion runs `_beam_burn` exactly like lance (`:601`). | G4 |
| 2.8 | The decal cap of 10 is enforced only in `add_hit_scorch`; gauss and bio holes bypass it. | CONFIRMED | `fx_ship.gd:816-826`; `fx_weapons.gd:751, 781, 786` append to `_hit_decals` with no trim. | G4 |
| 2.9 | Hole decals do not cool (the header claims they do); breach interiors do. | CONFIRMED | `fx_shaders.gd:737` comment versus the static `heat` uniform set once at `fx_death.gd:167`. There are no other writers (grep: only `fx_death.gd:864` for wreck faces). | G4 |
| 2.10 | Open question 2: does anything outside fx call `set_stages` or update hole heat? | Answered: no | grep over `godot/`: `set_stages` is called only inside fx (`fx_ship.gd:503`), and nothing outside fx writes `heat`. | none |
| 2.11 | Open question 1: what do the fx tests assert on `flash_log`? | Answered | `fx/test/fx_smoke.gd:128-140`: sorts `flash_log` and fails if any 1 s window holds more than 3. It certifies the gated set only, as the review says. | G4 |
| 2.12 | Squadron ships never show stage damage. | CONFIRMED | `fx_ship.gd:481-482` `if squadron: want = [0, 0, 0]`. | G4 |
| 2.13 | Under the Compatibility renderer, scorch and hole decals draw nothing. | CONFIRMED | `fx_death.gd:130-133` `if fx.compat: return Node3D.new()`. `tools/pc/play_godot_safe.bat` exists as a player-facing fallback (G-6). | G4 |
| 2.14 | Open question 3: is plasma light blue? | PARTLY (see 6.D1) | Hegemony plasma bolts and slag use the faction weapon colour `Color(0.55, 0.82, 1.0)` (`fx.gd:20`), which is light blue. The impact pop lerps 40% toward warm (`fx_weapons.gd:610-611`). The persistent mark is the generic orange scorch. | G4 |
| 2.15 | Open question 5: does any boarding visual exist outside fx? | Answered | Only the stub flash at `battle.gd:1009` plus the log line. There is no socket, venting or patch plate. | G4 + A4 |

**Conflicts**
- **Merge window.** The synthesis says "spec B says 0.33 s" and recommends setting the constant to 0.33. The source says: "Chair recommendation (not leg agreement, for Opus to test) ... Merge concurrent flashes inside the same 0.33 s window (Qwen proposal)". So 0.33 is a test proposal, not a spec, and no Ryan ruling covers it. My read: the two-sided window and the uncounted emitters matter far more than 0.12 versus 0.33. The cap of 3 per second holds either way. Merging at 0.33 lets more physical flashes draw at full brightness per counted event, which works against photosensitivity safety. I would keep 0.12, fix the stale comment at `fx.gd:313`, and move 0.33 into the A5 screen test. If Opus prefers 0.33, it should come after the coverage fix, not before.
- **FINDINGS K2 and the plan** list the flash cap and reduce-flashing toggle as A5 inputs only; there is no conflict. The accessibility review's claim that reduce mode is "wired end to end" conflicts with 3.1 below.

**Proposed incorporation:**
1. G2 gates or removes the stub flashes when `gfx` is present (2.4a).
2. G4 gates or calms the ungated emitters, attenuates `light()` on refusal, and makes the window trailing (2.2, 2.4, 2.5, 2.6).
3. G4 fixes the decal trim and cooling (2.8, 2.9).
4. The per-weapon marks (2.7, 2.15) go into the effects pass against damage_marks_reference.md, with the section budget at 3 sections.

---

## 3. Accessibility review (accessibility_review.md, with the Rey leg)

| # | Claim | Verdict | Evidence | Owner |
|---|---|---|---|---|
| 3.1 | "Reduce flashing is wired end to end (settings, panel toggle, live pass into fx)." | DISPUTED (must fix) | `main.gd:190-191` writes `b.fx.reduce_flashing`, but `b.fx` is the placeholder `fx_stub` (`battle.gd:224`), which has no such property, so the `in` check is false. The real G4 fx is set up with hard-coded values: `battle.gd:236` `gfx.setup({... "reduce_flashing": false, "shake": 1.0 ...})`. Nothing else sets `gfx.reduce_flashing` or `gfx.shake_scale`. The Reduce flashing and Screen shake settings therefore do nothing to the live effects. | G2 |
| 3.2 | Title and settings buttons use FOCUS_NONE with an empty focus style. | FIXED in 916fe9d | The old `title.gd:112, 128` (the review said 100 and 116). Now FOCUS_ALL with a visible ring, the first button takes focus, and sliders save on every change. | G2 |
| 3.3 | The help line `#7d7768` fails contrast (about 3.1 to 4.2 to 1). | FIXED in 916fe9d | My computation: 4.05 on INK `#0f1626`, 3.61 on IRON, 3.09 on IRON2, 4.20 on GLASS. Now `#b3aa95` (7.82 on INK) at `hud.gd:470`, and the muted log colour too (`:542`). The help line now lists X, G, Space and V. | G2 |
| 3.4 | Help line text is 12 px at 1080p, about 7 px at the 0.6 clamp; there is no text-size setting. | CONFIRMED | `hud.gd:470` `% s(12)`, `hud.gd:71` `clampf(..., 0.6, 2.2)`. No text scale setting. | G2 |
| 3.5 | Open question 5: does the HUD recompute its scale on resize? | Answered: no | `hud.gd:71` sets `k` once in `_ready`, and nothing listens for size changes. Same in `title.gd:35`. | G2 |
| 3.6 | No InputMap, no [input] section, no gamepad. | CONFIRMED | No `[input]` in `project.godot`. grep finds no InputMap, `is_action` or `JOY_` anywhere in `godot/`. | G2 |
| 3.7 | Open question 1: can a keyboard-only player complete an activation? | Answered: no | Battle keys (`battle.gd`): Q, E, 1-6, B, X, G, Tab, Enter, Space, Esc, T, R, V, F, Home. WASD pans the camera. No key picks a destination hex or cycles targets. | G2 |
| 3.8 | Exit green and guard red: a red-green pair with opposite meanings, colour only. | PARTLY | Zone fills are colour only (`board.gd:176` ZONE_C). But each zone type belongs to one fight type (`battle_api.gd:102`: exit is breakthrough, texit is intercept, guard is defend), so green and red never share a board. Hover text names them (`battle.gd` zone tips). The colour-only fill still deserves an edge or icon. | G2 |
| 3.9 | Crest shapes live only in the career UI. | PARTLY | The battle top bar shows the player admiral's crest (`hud.gd:256-260`, 9cdad32). There are no crests on ship markers or the selected-ship panel. | G2 |
| 3.10 | Speed options are only Normal and Fast (0.45); the toast lasts 3.0 s. | CONFIRMED | `title.gd:177`, `title.gd:138`. | G2 |
| 3.11 | "Consider defaulting AI to Standard." | CONFIRMED, and it is a regression | `main.gd:20` defaults to `"ai": "veteran"`. See conflicts. | G2 |
| 3.12 | No caption system. | CONFIRMED | No caption code. Music is the only audio-only identity channel. | G2 + MP |

**Conflicts**
- **AI default.** The plan says: "1. Standard AI for fresh profiles (today it defaults to Veteran, campaign3d.js:3)" (go-forward-plan.md:353). F25 is FIXED for the browser: "campaign3d.js defaults to Standard; main3d.js keeps Veteran for players with runs played and no saved choice". The Godot shell defaults every fresh profile to Veteran (`main.gd:20`). That breaks a done B1 fix. My read: port the B1 rule (Standard for fresh profiles).
- **Reduce mode.** The synthesis's strength claim 1 is contradicted by the code (3.1), and the fx synthesis's statement "reduce mode zeroes the log, not the screen" is also too generous: in live play the mode never turns on at all.

**Proposed incorporation:**
1. G2 wires `reduce_flashing` and `shake` into `gfx` at setup and on option change (3.1), and ports the Standard default (3.11).
2. G2 adds a text scale in `s()` with a resize hook (3.4, 3.5), then InputMap actions plus a keyboard hex cursor and target cycle (3.6, 3.7), then zone edges or icons (3.8).
3. The photosensitivity measurement goes with the G4 fixes in section 2.

---

## 4. Campaign screen information audit (campaign_map_review.md, with the Rey leg)

| # | Claim | Verdict | Evidence | Owner |
|---|---|---|---|---|
| 4.1 | Route weights are boons 3, relics 4, refits 2, credits 1, shipyards 2, events 1, and they are hidden. | CONFIRMED | `map_intel.gd:112` `st["value"] = ...`. The hover card does not print the weights. | G3 |
| 4.2 | The boss is left out of route danger sums. | CONFIRMED | `map_intel.gd:97` `danger(n) if t != "boss" else {}` (by design, bebda3a). | G3 |
| 4.3 | Danger bands at 0.8, 1.05 and 1.4, from one function. | CONFIRMED | `map_intel.gd:11, 29-58`. | G3 |
| 4.4 | Scars are priced at x1.10 and adaptations at x1.06 in danger. | CONFIRMED | `map_intel.gd:54` `(1 + 0.1*scars) * (1 + 0.06*adapt)`, so each scar adds 10% and each adaptation 6%. | G3 |
| 4.5 | The flat map shows no danger. | CONFIRMED | `map_view.gd` never calls `danger` or `map_intel`. | G3 |
| 4.6 | The sector condition's effect is only in a tooltip on the map page. | CONFIRMED | `campaign_ui.gd:424` passes `cond["d"]` as the box tooltip. The sector modal prints it once (`:900`). | G3 |
| 4.7 | The adaptation's full text appears once, in the sector modal. | CONFIRMED | `campaign_ui.gd:897-899`. The card prints `NEM_ADAPT[a]["n"]` only (`:539`). | G3 |
| 4.8 | Revealed weaknesses print as names, not effects. | CONFIRMED | `campaign_ui.gd:535` prints `NEM_WEAK[w]["n"]`. The `d` field exists in `campaign_tables.json`. | G3 |
| 4.9 | His behaviour text, persona, traits, scar causes, revive state, fed and riches are never surfaced, and NEM_ADAPT_FAC "exists unused by this layer". | PARTLY (root cause misread) | These fields do not exist in the Godot campaign at all. `campaign.gd:1516-1525` `newNemesis` is the B4 shape (no persona, traits, fed, riches, revived, scarList), and `campaign_tables.json` holds only NEM_CLOCK, NEM_WEAK and NEM_ADAPT. They live in the JS: R42 Nemesis v2, 7b313c4 (`campaign_run.js:243-290`, `data.js:446-489`), after the Godot oracle pin c7b1a78. The gap is an unported stream B step, not a card that forgets to print. | G1 + G3 (port R42) |
| 4.10 | Fed does not enter danger, so the estimate understates the Chorus rival. | PARTLY | True in the JS design. In Godot, fed does not exist yet (4.9). | G3 after the R42 port |
| 4.11 | Open question 1: are reveals and strike landings announced? | Answered from the JS | `campaign_run.js:280` prints "His captured logs reveal a weakness: ..." on every win against him. Event reveals print the effect text (`:344`). Strike results return a line from `nemStrike()` into the clock message (`:256-263`). | G3 |

**Conflicts:** none with rulings. R36 and R38 ask for a richer, more useful map, which matches fixes 4 to 6. Visual verdicts still wait for screenshots; cea3af2 now files PC shots of 89fb977, so the visual half of Job 4 can start.

**Proposed incorporation:**
1. Port R42 Nemesis v2 to Godot first: stream B step after c7b1a78, oracle re-pin, parity.
2. Then the card fixes 1 to 3: behaviour line, adaptation text, weakness effects, fed and riches.
3. Then the map page fixes 4 to 6: condition text, Heat rules, progress number, and danger on the flat map.

---

## 5. Story incorporation check (story_incorporation_check.md)

The check read the REVISED outlines (f51fcf8). The story stream has since done round 3 (401edc7, 64fe94f) and filed its own report, `godot/story/review_incorporation.md`, so most PARTLY rows are now done.

| # | Claim | Verdict | Evidence | Owner |
|---|---|---|---|---|
| 5.1 | No Setekh, Petra or Ilyra in the outlines. | CONFIRMED | 0 hits in f51fcf8 and now. "Setekh" is still in `data.js` (X22). | Story; B (data.js) |
| 5.2 | Ithar "elders" used 5 times; warden 6; confess 4. | CONFIRMED for f51fcf8; FIXED in 401edc7 | f51fcf8: elders 5, warden 6, confess 4. Now: elders 1, warden 1 (both inside the What-changed note, `outlines.md:15, 24`), confess 2 (the Voidsworn dilemma line, kept on purpose). | Story |
| 5.3 | Chorus "Dive and eat" (line 182) has no flag. | CONFIRMED for f51fcf8; FIXED in 401edc7 | f51fcf8 line 182 has no flag. Now `outlines.md:204` reads "(flag `ch_dove`, loud)". | Story |
| 5.4 | Fix 1 LANDED. | PARTLY | The story stream's report disputes it: the hails keyed off shared counters, not named flags. Its round 3 added a flag-keyed line per arc. I agree with the story report: PARTLY at f51fcf8, done now. | Story |
| 5.5 | Fix 2: four of six flags reach Beat 3; `it_mercy` and `dd_writ` fall short. | CONFIRMED for f51fcf8; FIXED in 401edc7 | review_incorporation.md section 2 row 2 quotes the new Beat 3 lines ("The writ is marked served", the buoy bracket). | Story |
| 5.6 | Q1: a Chorus Nemesis can roll. | CONFIRMED | `campaign.gd:945` `foes = shuffle(RUN_FACTIONS.filter(...))`, and `newNemesis` takes `foes[3]` (`:1517`). The JS is the same (`campaign_run.js:246`). | none |
| 5.7 | Q2: Beat 3 is followed by more of sector III. | CONFIRMED | `nemNodeIs` (`campaign_run.js:265`) puts him at `col >= cols-3`. A rest stop and the sector flagship follow. | none |
| 5.8 | Q3: arc files do not exist yet (B5 gate). | CONFIRMED | `godot/story/data/` has no `arcs/` folder. | Story |
| 5.9 | `rival_lines.json` is 25,762 bytes. | CONFIRMED at 651e516 | Measured at that commit. It has changed since (401edc7 rebuilt the pools on stream B's persona ids). | Story |
| 5.10 | Pronouns are tokens in `tokens.gd`, with a Chorus neuter default. | CONFIRMED | `tokens.gd pronouns()`. Stream B is still asked for `nem.g`. | Story + B |
| 5.11 | Chronicle row `{t, fac, arc, admiral, rival, choices, won}`. | CONFIRMED | `career.gd:10-12`. Round 3 added `said`, `first_lost` and `rival_fac` per the story report. | Story |
| 5.12 | Job 6 not landed: none of the six unlock ids are in `data.js`. | CONFIRMED | All six ids have 0 hits in `data.js`. `HULL_VARIANTS` (`data.js:545-557`) holds the 12 earlier variants only. | B |

**Conflicts**
- R45 says the reviewers read pre-f51fcf8 text and incorporation reconciles against the revised text. Muse's check read REVISED. The story stream reconciled against REVISED and NOW. The two agree except on fix 1 (5.4), where I side with the story stream.
- R47 (Ryan: Justiciar Halvane fine for now; full naming pass now) supersedes the check's Setekh row.

**Proposed incorporation:** none beyond what 401edc7 and 64fe94f did. Ryan's per-faction read is the gate. Job 6 stays blocked on stream B adding the six variant rows plus a sim pass.

---

## 6. Nemesis review and damage marks reference

### 6A. Nemesis review (nemesis_review.md); evidence is the JS at 7b313c4 (Godot has not ported it, see 4.9)

| # | Claim | Verdict | Evidence | Owner |
|---|---|---|---|---|
| 6.1 | A Deathless revive is used up in sectors 1 and 2, where every Nemesis survives anyway. | CONFIRMED | `campaign_run.js:282-285` checks in this order: `flagDead&&beh.revive&&!N.revived`, then `flagDead&&RUN.sector>=3` (dead), then `flagDead` (lifeboat and scar). This also answers open question 2: the code order matches the notes. | B |
| 6.2 | The Voidsworn challenge is not aimed: `focusFlag` is greedy-only, and Voidsworn personas exclude greedy. | CONFIRMED | `data.js:452-455` (greedy `ai:{focusFlag:1}`), Voidsworn `personas:['zealous','proud','cruel','methodical']`, `battle.js:581` `nemTargetBonus`. | B |
| 6.3 | The Ithar card promises "picks off your weakest ship"; only cunning and cruel focus weak ships. | CONFIRMED | The Ithar `beh.d` text, and `focusWeak` exists only on cunning and cruel. | B |
| 6.4 | Ithar `riches` is a dead variable; `applyNemesis` spends riches only for Corsair. | DISPUTED (worse than stated) | `battle.js:552` spawns `N.riches` cheap hulls for any faction, with no Corsair check. An Ithar who fled gets +1 riches (`campaign_run.js:281`) and then non-elite extra ships after the duel trim to 4 and the elite pass (`battle.js:549-550`). His "small and elite" fleet grows past four. | B |
| 6.5 | He appears once per sector whatever the clock does. | CONFIRMED | `campaign_run.js:265` `N.strike||n.col>=(RUN.map.cols.length-3)`. | B |
| 6.6 | The `{beat}` line and the adaptation come from different pools. | CONFIRMED | `nemBeatOf` (`:289`, ram x3, board x3, torp x2, from that fight) versus `nemAdapt` (`:268-271`, from run-wide `seen`). | B |
| 6.7 | Epithets ignore their cause. | CONFIRMED | `nemScar` (`:277`) picks at random from the faction pool. | B |
| 6.8 | Weaknesses are never revealed by triggering them. | PARTLY | True that triggering does not reveal. But each win against him reveals one ("His captured logs reveal a weakness", `:280`), and nemIntel events reveal one with its effect text (`:344`). The review omits the win reveal. | B |
| 6.9 | Contradictory trait and weakness pairs are not filtered. | CONFIRMED | `newNemesis` filters only anchor (`:247`). Voidsworn traits include boarders (`data.js` NEM_FAC). | B |
| 6.10 | "Wraithbone keel", Matriarch and Brood-queen titles, Petra and Lindqvist, Egyptian-leaning Deathless parts. | CONFIRMED | `data.js:480` (`ithar ... armor:'Wraithbone keel'`), Chorus titles, Hegemony pre and post lists, Deathless pre list. These belong to the R44/R47 rename work. | B (rename) |
| 6.11 | Open question 1: does the tithe have a minimum of 1? | Answered | `campaign_run.js:261` `x.hp=Math.max(1, x.hp - round(maxHp*.06))`. Hull is clamped at 1, so the tithe never destroys a ship (R7 safe). | none |
| 6.12 | Open question 3: Hegemony formation. | Answered | `beh.formation:1` is never read. Only the `formation` special adaptation adds +1 sync radius (`battle.js:566`). There is no double count, but the innate flag is dead data. | B |
| 6.13 | Open question 4: do raid and tithe fire as well as converting the next node? | Answered: both | `nemClockAdd` (`:256-257`) sets `strike` and calls `nemStrike()` at once. | B |
| 6.14 | Open question 5: what do the duel and swarm strikes do? | Answered | duel: trim to the flagship plus the 3 biggest, all elite, +6 aim, +5 crit (`battle.js:549-550`). swarm: no strike effect, only the swarm archetype (light hulls, `battle.js:150`). | B |
| 6.15 | Open question 6: does `ensureNemesis` keep beat, scars and met? | Answered | It keeps weak, revealed, adapt, clock, met, beaten, scars, dead, strike and seen (`:250`). `beat` did not exist in B4 saves. | B |
| 6.16 | The single "again" template is the whole spoken memory. | FIXED on the Godot story side (presentation) | `godot/story/data/rival_lines.json` and `rival.gd` pools (memory, scars, moments). The JS still uses `NEM_LINES` (`data.js:486`). | Story |
| 6.17 | Corsair ship cut is permanent and not recoverable. | CONFIRMED | `nemStrike` raid branch (`:259-260`) removes the ship and adds `N.riches`. Nothing returns it. | B |
| 6.18 | Open question 7: what does the Godot card show? | Answered | Only the B4 fields (4.7, 4.8): name and title, clock, weakness names, adaptation names, portrait. | G3 |

### 6B. Damage marks reference (damage_marks_reference.md) and the plasma amendment

| # | Claim | Verdict | Evidence | Owner |
|---|---|---|---|---|
| 6.D1 | "Plasma is LIGHT BLUE (Ryan, Oct 26)": what the code does today. | PARTLY in place | Hegemony plasma bolts, corona, heat shimmer and slag sprites draw in the Hegemony weapon colour `Color(0.55, 0.82, 1.0)` (`fx.gd:20`; `fx_weapons.gd:191-200, 627-629`), which is light blue. Not yet in place: the impact pop is pulled 40% toward warm white (`fx_weapons.gd:610-611`), the persistent mark is the generic orange scorch, and there is no splash crater or droplet fan. The G4 look keys on weapon id (`fx_weapons.gd:28`: laser, turbo, hturbo give plasma), while the rules trait is Hegemony-only (`data.js:54` FAC_WTRAIT). A non-Hegemony ship with a laser draws a plasma bolt in its own faction colour (inferred; not seen in play). There are no G4 commits since R46. | G4 |
| 6.D2 | The budgets assume 4 to 8 sections. | DISPUTED | There are 3 sections (1.19). The migration synthesis item 10 already re-reads the budgets as 3 per section. | G4 |
| 6.D3 | Shield-only hits leave no hull mark (chair recommendation). | CONFIRMED in code | `fx_weapons.gd:591-593` returns before any decal. | none |
| 6.D4 | "Hegemony plasma-trait batteries." | CONFIRMED | `data.js:54` FAC_WTRAIT hegemony laser, turbo and hturbo give plasma; `data.js:46` trait. | none |

**Conflicts**
- **R46** ("plasma is LIGHT BLUE ... sent to G4 for bolts, impacts and splash marks") against the code: bolts comply, impacts are partly warm, and splash marks do not exist yet. The standing caveat in the reference (light blue sits near the Hegemony shield colour `0.38, 0.68, 1.0` and the cyan interface, so the shape must carry identity) is real: the Hegemony weapon and shield colours differ by only 0.17 in red.
- **6.4** contradicts the synthesis's catch 3. The bug is real, but its shape is the opposite of what the review says.

**Proposed incorporation**
- Stream B (JS first, then port): 6.1 (pick one of the two fixes, which is a design call), 6.2, 6.3, 6.4 (gate riches to `beh.strike==='raid'`), 6.8 and 6.9, plus dead `beh.formation` (6.12).
- 6.10 goes to the R47 naming pass.
- Ryan decides 6.17.
- G4 finishes the plasma impact and splash (6.D1).

---

## 7. Addendum validation synthesis (addendum_validation_synthesis.md): the legs' repo claims

| # | Claim | Verdict | Evidence | Owner |
|---|---|---|---|---|
| 7.1 | Headless export "kills the FEATURES.md path disagreement". | DISPUTED | There was no disagreement (1.4a). | none |
| 7.2 | "Battle cut-ins (already on the FEATURES.md missing list)"; Argon: "Godot build still missing battle cut-ins". | DISPUTED (FEATURES was stale) | Cut-ins landed in 22139d7 (`battle.gd` `_cine_wants` and `_cine_frame`; Key moments, Every attack or Off), and camera follow landed in G-4. FEATURES.md was corrected in 916fe9d. | none |
| 7.3 | Item 21 needs "battle events emitted from the battle code from the start". | PARTLY (already exists) | The rules already emit an event stream that the scene consumes (`battle_api.gd:116` `take_events`; event kinds such as fire, activation, board, ram, risen, blink, ability, torpedo). The camera rig already smooths (`camera_rig.gd:137`). What is missing is the camera state machine and the tuning surface. | G2 |
| 7.4 | Music: "the file's absence is the whole blocker on Job 5". | PARTLY | `tools/music/catalogue.json` (f73e807) already lists the licence for 33 candidates. CREDITS.md and the selected tracks are what is missing. | MP |
| 7.5 | "Boss win rates 38 to 98 percent" (Argon, DeepSeek). | DISPUTED (number and staleness) | The registry has 36% (Grax) and 47% (versus Hegemony) up to 98% (Mending) before B2 (S5, S6). After B2, sector 1 admirals sit at 57 to 89% (S6 FIXED). No 38 appears in FINDINGS. | none |
| 7.6 | GodotSteam's move to Codeberg is "CONFIRMED by the chair's own earlier X18 verification". | UNVERIFIABLE here | X18 and X20 in FINDINGS mention MIT versus the paid GodotSteamKit, not Codeberg. The Codeberg reading is in Muse's sprint_godot_shipping_review.md:35-43, which is Muse's claim, not an Opus verification. A check of codeberg.org/godotsteam at adoption time would settle it. | G2 (Steam) |
| 7.7 | Qwen named the Sins 2 composer "Paul Shuey". | CONFIRMED (the quote is in the leg) | `contrib/qwen/reviews/addendum_validation_qwen_2026_10_26.md:35`. The correct name was not checked here. | none |
| 7.8 | The Godot shell's camera interpolation is UNSURE. | Answered | `camera_rig.gd:2` ("orbit about a target ... smoothed"), with exponential smoothing at `:137`. | none |
| 7.9 | DeepSeek's "settled larger fleet size" is wording drift. | CONFIRMED | R1: "about 10, 14, then 20 ships ... a guide, not a cap". | none |

**Conflicts:** none with rulings. The ordering rule (preconditions before enablers) fits R35 (full migration while Ryan is away), not R33's superseded "one battle first".

**Proposed incorporation:** treat the addendum items as already partly done:
- item 4 (export metadata): 916fe9d;
- item 5 (settings atomic): 916fe9d; the campaign save is still open (1.8);
- item 21: events and camera smoothing exist; the state machine and tuning surface are new.

---

## 8. Customization brainstorm, section 6 (reserve-now items)

| # | Item | What the code does today | Cheap to reserve now? | Owner |
|---|---|---|---|---|
| 8.1 | Instance state separate from hull rows | Partly. A fleet ship is `{uid, tpl, name, mk, hp, mods, cap}` (`campaign.gd:444`). `derive()` and the battle unit resolve weapons from the hull row: `for e in t["w"]` (`rules.gd:379, 1001`; same in core.js and battle.js). There is no per-ship weapon or trim override field. | Yes, if done as a nullable field that is absent by default. It must land in the JS first and then the port, or parity breaks. About two read sites per side. | B then G1 + G3 |
| 8.2 | Variant row schema with base reference, cost and arc unlock | Mostly exists. `HULL_VARIANTS` rows carry `base`, `w`, `mod` and `cost` (`data.js:545-557`), expand into HULLS with `base` and `variant` (`:558`), and reach `tables.json` (`vs_harrow_t.base = harrow`). The render picks meshes by faction and class (`hull_table.gd:51`), so variants inherit the base mesh. Only the `arc` field is missing (unlocks.md asks for it). | Yes, trivial. | B |
| 8.3 | Flagship mount conventions | Mounts exist on every A4 ship: empties `hp_w<slot>_<weapon>_<arc>_<n>` with kind, size, arc and slot extras (ships README section "Hard points"). But each ship is "one mesh, one material", so the gun geometry is baked into the hull. | The naming is already reserved. Separate weapon scenes would mean re-exporting the six flagships now that all 36 hulls are done (G-11), so not free. Cheap alternative: record the convention in the ships README for the next flagship touch. | A4 |
| 8.4 | A sim hook for customized flagships | Partly. sim3d `PATCH='admiral.start=hull,...'` (`sim3d.js:34-36`) fields any hull row, so a temporary variant row can sim a "customized" flagship today. There is no pod or trim argument. | Yes. A PATCH key for one ship's weapon list is small. | B |
| 8.5 | Faction weapon pool tags | No positive tags. `FAC_GATES` has only Corsair `noKind:['lance']` (`data.js:536`). `FAC_WTRAIT` and `FAC_WNAMES` (`data.js:36, 54`) map faction to weapon ids for traits and names, which is a de facto pool. | Yes. FAC_WTRAIT keys are already a pool, and a tag list costs a tables re-export and checksum update in both streams, with no rules effect. | B |
| 8.6 | How Nemesis adaptation counts usage | Fleet-wide, per finished battle. `fireWeapon` counts player use by kind into `B.usage` (`rules.gd:2219-2221`). `nemLearn` adds to `N.seen` (`campaign.gd:1584`; `campaign_run.js:290`). `nemAdapt` picks the top score and resets `seen` to {} (`campaign.gd:1566`), so the memory window runs from the last adaptation: a sector, or each meeting for Chorus. | Nothing to reserve. The section 4 "fleet-wide basis" guardrail already holds, and the "memory window" is one sector, not 3 to 5 battles. | none |

**Conflicts:** none. The R41 arc unlocks are the variant rows in 8.2 and the Job 6 trigger.

---

## Incorporation plan (ordered across all documents)

1. **G2, now (accessibility and safety):**
   - wire `reduce_flashing` and `shake` into the G4 fx at setup and on option change (3.1);
   - gate the stub flashes when G4 is present (2.4a);
   - restore the Standard AI default for fresh profiles (3.11, F25).
2. **G1, before cutover (threading and maths):**
   - thread-local `_pb` (1.2);
   - lock or assert every public battle_api entry point (1.2);
   - add `eval_begin` to `ui_info` (1.16);
   - give `step()` an error path (1.18);
   - harden the maths edges and prove NOT PORTED empty (1.5, 1.6);
   - narrow the six warning classes (1.3).
3. **G3, before cutover:**
   - atomic campaign save (1.8);
   - `campaign.seed_rng()` to retire the 26f2bd5 fallback;
   - an oracle cross-check line in both parity runners (1.12, with G1).
4. **Stream B, then G1 and G3 port: R42 Nemesis v2 into Godot.** Re-pin the oracle past 7b313c4 with parity. Fold in first the stream B fixes that need no ruling: riches gated to raid (6.4), aim for the Voidsworn challenge and fix the Ithar card text (6.2, 6.3), filter contradictory pairs (6.9), and drop dead `beh.formation` (6.12).
5. **G3, after step 4:** Nemesis card and map fixes (4.6 to 4.10, campaign review fixes 1 to 6).
6. **G4, effects pass:**
   - make the flash window trailing, gate or calm the ungated emitters, attenuate `light()` on refusal, remove the 8 Hz term in reduce mode (2.2 to 2.6);
   - fix the decal trim and cooling (2.8, 2.9);
   - plasma impact and splash in light blue (6.D1);
   - per-weapon marks on the 3-section budget (2.7, 6.D2), ion tree first;
   - then a rendered photosensitivity measurement.
7. **G2, before Steam:**
   - text scale with a resize hook (3.4, 3.5);
   - InputMap plus a keyboard hex cursor and target cycle (3.6, 3.7);
   - zone edges or icons (3.8);
   - constants diff check (1.13);
   - sky and asteroid sources moved out of enginetest, and source-hash freshness (1.10);
   - camera state machine and tuning surface on the existing event stream (7.3).
8. **Stream B, small reserve-now items:** the `arc` field on variants (8.2), a nullable weapon-override field (8.1), a PATCH key for one ship's weapons (8.4).
9. **Closed, no action:** 1.4a, 1.7, 1.14, 1.15, 5.x (story round 3), 7.1, 7.2, 7.8, 8.6.

## Questions only Ryan can answer

1. **Deathless revive (6.1).** Should other factions "escape" before sector 3 instead of dying and returning, or should the Deathless revive simply not be used up before sector 3?
2. **Corsair ship cut (6.17).** Make the stolen ship recoverable when he dies, drop the ship cut, or keep it with a clearer warning?
3. **Ithar extra ships (6.4).** Should an Ithar who flees come back with extra ships (today's actual behaviour, not on his card), or stay a four-ship elite duel fleet?
4. **Flash merge window (2.1).** Keep 0.12 s, the safer default and my pick, or test 0.33 s on screen as the Muse spec proposes?
5. **Compatibility renderer (2.13).** Is `play_godot_safe.bat` a shipped option? If yes, damage marks need a fallback there.
6. **Enemy AI default (3.11).** Confirm Standard for new players in Godot, as B1 decided for the browser.
7. **Customization (section 8).** Do you want any reserve-now items done during the migration (they cost little), or should all of it wait for a later design pass?
