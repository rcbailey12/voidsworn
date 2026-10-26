# Godot migration review, Rey leg, 2026-10-26

Chair header: Rey's own audit for the Godot migration review, written blind alongside the DeepSeek, Qwen and Argon legs against the same evidence pack. Chair-read in full before filing; no corrections were needed. The draft's two corrections to the pack (warning suppression is 6 of 17 project-warn classes, not 17; both oracle READMEs do document a manual re-copy step) and its CUT/SOLID document divergence are carried into the synthesis. The synthesis is contrib/muse/reviews/godot_migration_review.md.

---

Date: Oct 26, 2026. Scope: all Godot work except fx visuals and flash, campaign screen information design, story content, and accessibility settings, except structural intersections. Method: chair evidence pack plus my own read of the fetched sources in the migration folder. Every repo claim below is marked OBSERVED (seen in a fetched source, with file and line) or INFERRED (judgement from an observed pattern), or PACK-STATED (in the pack, not independently re-read by me). Line numbers are from the fetched copies, which the pack states are main as of Oct 26, 2026.

## Verification of the pack's five headline findings

1. Campaign RNG never seeded in the shipped shell: CONFIRMED, with one scope note.
   - OBSERVED jsm.gd:52: `static var rng_s: int = 0`, the one process-global mulberry32 stream.
   - OBSERVED campaign.gd:942: `func newRun(...)` draws shuffled foes (line 946 in the fetched copy, `shuffle(RUN_FACTIONS.filter(...))`), shuffled patrons, a random starting relic via randomRelic(), genSector(1) for the map, and newNemesis() (the fetched copy shows `RUN["map"] = genSector(1)` and `RUN["nem"] = newNemesis()` near the end of newRun, around lines 985-986), with no rnd_seed call anywhere in the function.
   - OBSERVED grep over every fetched .gd file: rnd_seed appears only at jsm.gd:53 (the definition), battle_api.gd:29 (battle setup from a scenario seed), campaign_scene.gd:27 (wall clock seed, with the comment that the browser seeds its PRNG at random on load), campaign_scene.gd:42 and 102 (test paths), rules.gd:1044 (inside startBattle from cfg.seed), and campaign.gd:2105 and 2291 (battle paths only).
   - OBSERVED title.gd, campaign_host.gd and story.gd contain zero rnd_seed and zero JSM references at all (grep returned no hits).
   - PACK-STATED, not independently re-read: main.gd itself was not among the fetched sources (only main/README.md and campaign_host.gd were), so the "no seed in main.gd" part rests on the pack's grep, which covered it. The three shell files I could check directly agree with the pack.
   - Consequence stands: on a fresh process the first run's foes, patrons, captain names, relic, sector 1 map, node seeds and Nemesis come from the same fixed sequence starting at 0, on every launch and every install, until player choices change the draw count. Parity and bot runs seed explicitly, so no existing test sees this.

2. Threading safety is a scene convention, not an API enforcement: CONFIRMED.
   - OBSERVED battle_api.gd:13: one Mutex. OBSERVED battle_api.gd:505-518: step() is the only method that locks it, and its own header comment (lines 501-504 in the fetched copy) states the contract in words: safe on a worker thread "as long as the scene does not call anything else here meanwhile."
   - OBSERVED battle_scene.gd:650-665 (the _think function): a WorkerThreadPool task runs `api.step()` and then `api.view()` inside the same worker closure, so view() executes off the main thread while holding no lock.
   - OBSERVED battle_scene.gd:1677-1709: the threat path runs `api.threat_map()` on a second WorkerThreadPool task, gated only by the scene flags _threat_busy, busy and thinking (line 1679).
   - OBSERVED battle_api.gd:315-323: threat_map() calls R.eval_begin(). OBSERVED rules.gd:177-178: eval_begin() sets _evc and clears all six scratch caches (_los, _guard, _tc, _hc, _lw, _slot, declared rules.gd:168-175). OBSERVED battle_api.gd:192, 323 and 440 also call eval_begin() from other entry points, so the caches are shared mutable state across every API caller.
   - OBSERVED jsm.gd:15: `static var _pb`, one PackedByteArray behind hi(), lo(), words(), hex64() and from_hex64() (jsm.gd:20-33). Any two threads converting a float at the same moment share that buffer.
   - The _runner loop (battle_scene.gd:625-648) does wait for _threat_busy before thinking, which is the convention working as designed today. The hazard is INFERRED for any future or overlooked overlap, exactly as the pack frames it.

3. Blanket warning suppression in the three most delicate files: CONFIRMED, with a correction to the pack's framing of project settings.
   - OBSERVED rules.gd:11, jsm.gd:13, battle_api.gd:6: each opens @warning_ignore_start listing the same 17 warning classes, including integer_division and narrowing_conversion.
   - OBSERVED campaign.gd: grep count for warning_ignore is 0. The campaign port lives with warnings on, which proves the suppression is a choice, not a necessity of the port style.
   - Correction, OBSERVED project.godot.txt:12-28: the project does not set all of these to warn. Six are set to warn (=1): unsafe_property_access, unsafe_method_access, unsafe_call_argument, integer_division, narrowing_conversion, return_value_discarded. The other eleven are set to ignore (=0) at project level anyway. So the suppression's real cost is narrower and sharper than "opts out wholesale": it silences exactly the six classes the project deliberately left on, and two of those six (integer_division, narrowing_conversion) are the documented JS-port trap categories in the rules test README. The finding stands; the blast radius is six classes, not seventeen.

4. Export ships the campaign test oracle: CONFIRMED.
   - OBSERVED export_presets.cfg:11: `exclude_filter="rules/test/*, audio/build/*"` with export_filter="all_resources" (line 9). Nothing excludes campaign/test/*.
   - OBSERVED inventory.txt via the pack and the oracle READMEs: godot/campaign/test/oracle/ holds battle.js 162,826, ui3d.js 115,653, campaign_run.js 64,891, data.js 80,349, core.js 37,509, campaign_meta.js 32,143, campaign3d.js 22,337 bytes, about 516 KB of JS, plus Node harness files. None of it is loaded at runtime.
   - OBSERVED export_presets.cfg:26 embed_pck=false, 31 codesign/enable=false, 33 application/icon empty, 36-37 file_version and product_version empty, 12 export_path="../export/Voidsworn.exe". PACK-STATED: FEATURES.md gives a different build path (build\export\Voidsworn.exe), so one of the two is stale.

5. JSM unported maths edges return 0.0 and play continues: CONFIRMED, all five sites.
   - OBSERVED jsm.gd:162: sin/cos argument too large, push_error, return 0.
   - OBSERVED jsm.gd:225: atan2 with an infinite operand, push_error, return 0.0.
   - OBSERVED jsm.gd:240: exp range (hx >= 0x40862E42), push_error, return 0.0.
   - OBSERVED jsm.gd:317: pow with |y| over 2^31, push_error, return 0.0.
   - OBSERVED jsm.gd:352: pow subnormal result, push_error, return 0.0.
   - Contrast, OBSERVED rules.gd:8 header and rules_test_README.md: the rules layer stops the run with a NOT PORTED marker so a gap can never pass silently. The maths layer does not use that stop. In a release build push_error only logs, so an extreme input becomes a wrong but plausible number.

## Two corrections to other pack findings

A. Oracle duplication (pack finding 5): PARTLY DISPUTED on the "no documented sync step" wording.
   - OBSERVED rules_oracle_README.md (fetched copy): it pins commit c7b1a78 and has a "Catching up" paragraph: when stream B changes the rules, port the change, then re-copy these files from the new commit and update the note.
   - OBSERVED campaign_oracle_README.md (fetched copy): same pin c7b1a78, same instruction, plus the export_campaign.js refresh step for campaign tables.
   - So a documented manual sync step exists in both places, and both copies are at the same commit today. What does not exist, OBSERVED by absence in both READMEs, is any automated check that the two copies match each other or that a re-pin updated both. The risk is a one-sided manual re-pin, not an undocumented process. Severity drops from the pack's framing; the fix (a compare step in the parity scripts) stays cheap and worth it.

B. CUT and SOLID hash coverage (pack rules section): DIVERGENCE FLAGGED, not resolved.
   - PACK-STATED: the canonical hash inputs exclude CUT and SOLID module state on both sides via matching SKIP sets, so a terrain-state bug can pass parity silently.
   - OBSERVED rules_test_README.md:34 (fetched copy): "Each record holds the whole battle state in canonical form (B, every unit, and the rules state kept outside B: the board cut-outs, the hexes that block sight, the id counter), including the battle log, a SHA-256 of that state, and the PRNG state."
   - OBSERVED rules.gd:27-28: CUT and SOLID are rules instance state outside B; rules.gd:535-640 builds them at setup.
   - The README says the record includes the cut-outs and sight blockers and carries a SHA-256 of that state; the pack says the hash excludes them. Both can be true only if the record text includes them but the hashed subset does not, or if one document is stale. The golden writer (golden.js, parity_main.gd) was not in the fetched sources, so I cannot settle which. This needs a one-line answer from the code owner, because the two readings have opposite risk: if the README is right, this pack finding should be closed; if the pack is right, the README overstates the rig. Marked UNSURE below.

C. One pack UNSURE partly settled: FAC_GATES in the campaign tables.
   - OBSERVED campaign.gd:75: load_tables assigns FAC_GATES = TB.FAC_GATES, and campaign.gd:160 and rules.gd:2789 both read FAC_GATES. So the campaign exporter did pick up FAC_GATES (the port_notes step 1 worry). FAC_PRICE has zero hits in campaign.gd or rules.gd (grep), so whether FAC_PRICE exists in the tables or is still JS-only is UNSURE from the fetched sources.

## Area 1. Rules port and parity (godot/rules/, jsm.gd)

Verdict: SOUND WITH RISKS.

Evidence: exact-double compare with no tolerance, SHA-256 over canonical state at every action point, 23 scenarios across all 8 fight types, a 200-battle sweep exit bar, and checksum-locked tables in both streams (OBSERVED rules.gd:61-67 and campaign.gd:56-62: both load_tables functions recompute JSM.sha256 over the canonical tables and return an error string on mismatch). OBSERVED grep: zero uses of Godot's global randf, randi or RandomNumberGenerator in rules.gd, campaign.gd, battle_api.gd or jsm.gd; every rules draw flows through JSM.rnd. That discipline is the strongest part of the migration.

Bugs:
- B1 (in the ranked list): the seeding gap in finding 1 lives here as much as in the shell. The port faithfully reproduces the JS single-stream design (jsm.gd:52), but the shipped shell never seeds it outside battles.
- B2: the five maths edges returning 0.0 (jsm.gd:162, 225, 240, 317, 352). Wrong numbers in live play, invisible except in logs.
- The CUT/SOLID coverage question (correction B) is either a parity blind spot or a documentation error; one of the two is a bug.

Refinements:
- The parity rig is single-threaded by construction (rules_test_README.md describes one process per side playing in sequence), so it cannot see the threading class in Area 2 at all. A short note in API.md's determinism section saying parity proves sequential determinism only would stop a future reader over-trusting it. OBSERVED rules_API.md:162 covers deterministic ids; PACK-STATED it does not cover threading limits.
- canon and numstr (jsm.gd canonical writer) try up to 17 precisions per number (PACK-STATED). Whether that runs on any live path is UNSURE; if it is test-only, a comment saying so closes the question cheaply.

Alternative approach: none recommended for the core design. Exact parity against a pinned oracle is the right call for a port of this size. The trade-off already accepted is speed of stream B changes (every change is paid twice, once per implementation); the port_notes draw accounting is what makes that survivable, and it is working.

## Area 2. Threading and shared state

Verdict: NEEDS WORK (harden before cutover, not necessarily now).

Evidence is finding 2 above: battle_api.gd:505-518 (only step() locks), battle_scene.gd:650-665 (step plus view on a worker), battle_scene.gd:1677-1709 (threat_map on a worker, flag-gated), rules.gd:177-182 (eval_begin and eval_end clearing shared caches), jsm.gd:15 (one static scratch buffer), jsm.gd:52 (one static stream).

Bugs:
- B3: no enforcement. Any future main-thread API call that overlaps a threat computation or an enemy think can corrupt the eval caches or read half-mutated unit dictionaries. INFERRED symptom class: rare, irreproducible battle bugs that parity cannot reproduce because parity never overlaps calls.
- B4, INFERRED from OBSERVED battle_api.gd:505-518: step() locks, runs, unlocks with no failure path. GDScript has no try/finally, so a runtime error aborting step() mid-activation in a debug or editor build leaves the mutex locked and every later step() blocks. The bot hang guard would report a hang, not this cause. Low probability, high confusion cost. I did not find any unlock-in-error path in the fetched copy.

Refinements:
- Cheapest hardening that keeps the design: make every public battle_api entry point take the same mutex (or a re-entrant guard counter), not just step(). The contention cost is near zero because the scene already serialises calls by flags; the lock becomes the enforcement of a convention that already holds, so behaviour does not change on the happy path.
- The JSM scratch buffer (jsm.gd:15) is the subtler half. OBSERVED: hi, lo, words, hex64 and from_hex64 all write _pb then read it back in the same function, with no await between, so a single call is atomic in GDScript's cooperative threading only if no other thread runs mid-call. Worker threads are real OS threads, so two simultaneous conversions can interleave. Making the buffer thread-local, or doing the byte work on local arrays, removes the whole class. Effort: small, contained in one file. This is the single highest value-per-effort fix in this area.
- view() returning live references (see Area 4) compounds the threading risk: a renderer mutating a shared array while a worker thinks is a write race, not just a logic error.

Alternative approach: move all API calls onto one dedicated rules thread and marshal results back. Honest trade-off: it is the cleanest long-term shape and kills the class permanently, but it rewrites the scene's batch and animation flow mid-migration and risks new timing bugs right before cutover. Not worth it now. The lock-everything plus thread-local buffer version gets most of the safety for a fraction of the cost. Revisit only if a second concurrent caller ever appears.

## Area 3. Campaign logic and saves (godot/campaign/)

Verdict: SOUND WITH RISKS.

Evidence: OBSERVED campaign.gd:348-359 (_enc writes every non-integer float as "#d:" plus exact IEEE hex, drops nulls and Callables), 361 (save envelope format string with v:1), 188 (SAVE_VERSION 2 for meta), 362-375 (persist_save), 377-393 (load_save_text), 56-62 (table checksum).

Bugs:
- B5: persist_save is not atomic. OBSERVED campaign.gd:368-375: if the current file exists, parses and differs, it is copied to save_path + ".bak"; then the main file is opened with FileAccess.WRITE and overwritten in place. A crash or power loss mid-write leaves a torn main file. The load side mitigates well (saneSave and saneRun checks at campaign.gd:340-346 in the fetched copy's ordering, fallback to the backup, keep whichever half is sound), so the worst case is losing the newest save step, not the profile. Still, the fix is standard and cheap: write to a temp file, then rename over the main file, keeping the .bak copy as the second generation.
- B6: the seeding gap (finding 1) lands its user-visible damage here: identical first runs everywhere.

Refinements:
- Settings saves have no backup and no version field and merge keys on load, so a renamed setting leaves a stale key forever (PACK-STATED for main.gd save_settings, which I could not re-read; OBSERVED title.gd:189, 211, 232, 250 call main.save_settings() from the settings panel). Minor, but a version field costs nothing at the next save-format touch.
- The battle hand-off contract is stringly-typed: OBSERVED campaign.gd:34 (B is "the stub's, or the rules' B handed back by finish_battle"), 2151 (finish_battle(result, battle)), 2339-2341 (the stub builds B["usage"] by JS field names), and the pack's note that the campaign reads B.usage, unit ev fields, the nemFlag unit and wing kills via parent. No schema check exists on either side; parity is the only guard. A cheap partial guard: a debug-build assertion in finish_battle that the handful of fields the campaign actually reads are present and of the expected types. It would turn a silent wrong-number bug after a rules rename into a loud test failure.
- persist_save stringifies the full run on every save point (OBSERVED campaign.gd:362-375 calls save_text() unconditionally when persist_on). On campaign-scale data this is fine today; flagging only because save points multiply as story content lands. UNSURE whether any save point sits on a per-click path frequent enough to matter.

Alternative approach: none for the format itself. The IEEE hex encoding is the correct response to a real Godot JSON quirk and the keep-the-sound-half loader is better than most shipped games manage.

## Area 4. Shell and glue (godot/main/, godot/scenes/)

Verdict: SOUND WITH RISKS.

Evidence: OBSERVED campaign_host.gd:47 (campaign loaded by path), 63-64 (story hook gated on ResourceLoader.exists), 78-82 (G3 campaign UI gated on ResourceLoader.exists, else the fallback UI), 60 (persist_load), and the _on_changed run_over edge (campaign_host.gd, the function emitting run_over when the page is title with no modal). OBSERVED battle_scene.gd:25 (fx stub preloaded), 228-229 area in the fetched copy (the real fx loaded alongside when res://fx/fx.gd exists, with the comment that the placeholder stays for anything it lacks).

Bugs:
- B7: NOT PORTED degrades in live play. OBSERVED battle_scene.gd:661-663 (_think) and 673-675 (_cmd): both record the error, clear R.not_ported, and continue with the partially computed batch. Right call mid-migration; before cutover the unported set must be proven empty or this must become a hard stop, because after cutover there is no browser version to compare a wrong battle against.
- B8: view() leaks live references against its own contract. OBSERVED battle_api.gd:86-104: view() duplicates sh, sec, terrain, map and obj, but returns "arena": B["arena"] by reference and "shMax": u["shMax"] by reference, under the API header promise (battle_api.gd:2) that the renderer never writes rules state and the view comment's "never changes behind your back" framing (PACK-STATED wording at lines 113-121 of the pack's copy; the fetched copy shows the same return shape). A renderer that mutates what it is handed writes into live rules state. Duplicate those two fields; the cost is two small copies per view call.
- B9 pattern, INFERRED risk: the ResourceLoader.exists soft-dependency pattern (campaign UI, story hook, music, look in ship_view.gd:118, fx) degrades silently when a file is missing. OBSERVED campaign_host.gd:78-82: a packaging mistake that drops the G3 UI ships the facts-and-buttons fallback with no error anywhere. And a file that exists but fails to parse makes load(...).new() throw on some of these paths instead of falling back (INFERRED from the load pattern; I did not trigger it). For cutover, an exported-build smoke check that asserts the real UI, real fx and story hook all loaded would close this class in one test.

Refinements:
- The fx stub coexistence (battle_scene.gd:25 preload; fx_stub.gd:1-5 header says it goes away when godot/fx/API.md exists, and that API exists) is retired-late transition code. Which cues each system owns is UNSURE (fx internals out of scope). Even without touching fx, a comment in battle.gd naming the split as it stands today beats tribal knowledge.
- campaign_host _on_changed run_over edge (INFERRED, pack-noted and consistent with the fetched code): start() calls titleScreen, then an act that moves off title, then binds and calls _on_changed once. Safe in current flows; any future flow that leaves the page on title at bind time hands back to main's title instantly. A one-line guard (only emit run_over after the campaign has left title at least once) removes a trap for the next flow added.
- Error counting and hang diagnostics are genuinely good (PACK-STATED for main.gd's Logger and hang guard; OBSERVED battle_scene.gd keeps an errors list via _error and the bot loop in campaign_scene.gd:42 seeds deterministic bot runs). Keep them in the exported build's bot mode; they are the only net under the threading and NOT PORTED classes.

## Area 5. Data duplication and drift

Verdict: SOUND WITH RISKS.

Evidence: the two generated tables are the model to copy (OBSERVED rules.gd:61-67, campaign.gd:56-62, checksum verified at load, refuse on mismatch). Against that, OBSERVED hull_table.gd:1-5 header: AI_HULLS, CLS_LEN, FAC3D and FINISH are "taken from ships3d.js" by hand, with no generation or checksum. OBSERVED world.gd:12-27: BIOMES from scene3d.js, ROCKS from battle.js ROCK_KINDS, PLANETS, all hand-copied constants. OBSERVED the two vendored oracles pin the same commit today (both oracle READMEs cite c7b1a78) with a documented manual re-copy step and no automated cross-check (correction A above).

Bugs: none live today that I can evidence. This area is drift risk, not current wrongness. The first JS-side change to FAC3D colours, a class length, or a biome that is not hand-carried over will diverge silently, and nothing in the test suite compares these constants.

Refinements, ranked by value per effort:
- A small Node check script that extracts FAC3D, CLS_LEN, AI_HULLS, BIOMES, ROCKS and PLANETS from the JS sources and diffs them against the GDScript constants, run with the parity scripts. This is the tables.json pattern at a fraction of its weight, and it covers every hand-copied constant in one step. Highest value in this area.
- A one-line compare of the two oracle folders' shared files (battle.js, core.js, data.js) inside the existing parity runners, so a one-sided re-pin fails loudly. Cheap because the files are supposed to be byte-identical.
- Where hand-copying is fine: one-off layout or dressing numbers that exist only on the Godot side, and anything Ryan judges by eye in screenshots (ship scale SHIP_K in hull_table.gd is explicitly an owner read, OBSERVED hull_table.gd comment). Do not generate what has no JS source of truth.

Alternative approach: extend export_data.js to emit a third generated file for render and world constants, checksum-locked like the others. Trade-off: stronger than a diff check (drift becomes impossible, not just detected) but it changes load order and failure modes in the shell for presentational data, and a checksum refusal on a colour table would block the game over a cosmetic. The diff check gets the safety without putting presentation on the critical path. Prefer the check.

## Area 6. Asset pipeline and build

Verdict: NEEDS WORK (for a reproducible Steam build; fine for the current PC workflow).

Evidence: OBSERVED build_assets.gd:12 (GEN_VERSION := 3), 83-84 (_current returns true when not forced, the code is in the manifest table, the output file exists, and its recorded version is >= GEN_VERSION; source art mtimes and hashes are not consulted), 59 (asteroid placements fall back to contrib/opus/enginetest/assets/env/asteroids.json), 421-422 (sky candidates include two paths inside contrib/opus/enginetest/), 313-335 (_build_a4_ships reads res://assets/ships). OBSERVED inventory: godot/gen/ has zero files on main; godot/assets/ holds only a README (PACK-STATED, and ships_README.md describes the A4 files as living on the PC). OBSERVED ship_view.gd:92 area: the final fallback is a plain BoxMesh, silent. OBSERVED export_presets.cfg as in finding 4.

Bugs:
- B10: the shippable game cannot be built from the repo alone. gen/ is PC-generated and absent, A4 ship sources are off-repo, and two content inputs fall back to another contributor's scratch folder (contrib/opus/enginetest). If that folder is cleaned up, the sky and asteroid field silently lose their sources.
- B11: gen/ freshness is version-only. Editing a hull's source art without bumping GEN_VERSION or passing --force ships the old mesh (OBSERVED from _current at build_assets.gd:83-84). Combined with the silent BoxMesh fallback, a stale or missing gen/ presents as wrong-looking ships, not an error, and only Ryan's eye catches it.
- B12: the export preset ships test content (finding 4) and lacks icon, versions and codesign. Not a Steam blocker today, a release blocker at the Steam gate.

Refinements:
- Record a source hash per generated item in manifest.json and have _current compare it. That makes freshness a fact instead of a convention, at the cost of hashing source art on each build_assets run (seconds, on the PC, at build time only).
- Move the sky and asteroids.json sources into a real repo folder (hulls/ or a new assets/env/) and delete the enginetest fallbacks, or keep the fallbacks but log loudly when one is used. Depending on a contrib scratch folder is the kind of thing that breaks a year later with no one remembering why.
- Add an export-content check: after an export, list the .pck contents and fail if any path under rules/test/, campaign/test/ or audio/build/ appears, or if gen/manifest.json is missing. This also covers the Area 4 silent-degradation risk for packaged content.

Alternative approach: commit gen/ to the repo (or to Git LFS) so a checkout builds the game with no generation step. Trade-off: repo grows by the generated resources and every art change produces large binary diffs, but the Steam build becomes checkout, export, ship, and the whole freshness question disappears. Given a small team and a single build PC, either shape works; what does not work is the current middle state where the build depends on PC state that no document fully lists. Pick one and write the build recipe down in one place.

Smallest reproducible-build set: (1) sky and asteroid sources in the repo, (2) A4 ship sources in the repo or a documented fetch step, (3) source-hash freshness in build_assets, (4) an export-content check, (5) the build recipe (Godot version, build_assets command line, export preset) in one README. Items 1, 4 and 5 are hours, not days.

## Area 7. Music and portraits plumbing

Verdict: music plumbing SOUND, content NEEDS WORK (docs overstate state); portraits plumbing SOUND.

Music evidence: OBSERVED music_README.md lists music.json, tracks/*.ogg and CREDITS.md as the folder's contents and describes the player contract in full. OBSERVED inventory: godot/music/ on main holds only README.md, music_player.gd and test/music_check.gd; no music.json, no tracks, no CREDITS.md. OBSERVED music_player.gd:19 (MANIFEST := "res://music/music.json"), 107-123 (loads the manifest's track map, builds paths under res://music/tracks/, skips missing files quietly by design, a behaviour the README also states). OBSERVED music_check.gd:34-39: the check requires tracks.size() > 0 and opens every track, so it cannot pass as written while music.json is absent (INFERRED consequence, directly from the check's own assertions). PACK-STATED: FEATURES.md marks Music done.

Bugs:
- B13: documentation-versus-tree drift as a defect, not a nit. The README describes files that do not exist and FEATURES.md marks the feature done, so the next person (or model) picking up music starts from a false state, and the licence check job has nothing to check. The player code itself is careful and complete; the fix is honesty in the docs plus landing the content, in that order.

Portraits evidence: OBSERVED portraits.gd:11-12 (static _idx and _cache), 28-35 (face() falls back to the crest SVG when no painting is picked), 68-107 (nemesis() composes base, scar variant and overlays, cached per (id, scar list) key), 139-141 (clear_static() clears the caches). Composition cost is paid once per cache key. No bug found in the plumbing. Refinement only: the static caches are exactly the class main.gd's quit_clean has to clear (PACK-STATED it does, via clear_static on the modules that expose one); portraits exposing clear_static keeps it in that contract, which is the right pattern and worth keeping uniform.

Audio intersection, OBSERVED sfx.gd:2 and 55: sfx reaches the imported-file helper through a preload of the battle HUD script (const HUDRes, HUDRes.imported_ok), while music_player.gd:138 defines its own private _imported_ok. Two implementations of one helper owned by two areas. Minor duplication; fold into the Area 5 check-script mindset rather than a refactor: note it, fix it the next time either file is touched. OBSERVED sfx.gd:109, 151, 184, 317 use global randf and randi for round-robin and pitch jitter; safe (never JSM), but the determinism doc should say audio randomness is unseeded by design, one line.

## Area 8. Anything else the pack gives evidence on

Performance shape, INFERRED from OBSERVED code: battle_api.gd view() rebuilds the full unit and weapon view on every call (lines 86-104), and ui_info() (lines 279-313) computes expectedVs, hitChance, los and dmgMult for every weapon against every living enemy per call. On 20-ship boards with carriers these are the obvious cost centres, and the only documented timing bar covers enemy think (rules_test_README.md timing section: aiUnit only, worst under about 0.5 s). No bug claimed; a think-plus-view timing line in the existing timing report would show whether view() matters at s23 scale before anyone optimises blind.

Test coverage gaps, OBSERVED by absence across the fetched READMEs and code: no test covers shell startup seeding (finding 1 is the proof), export contents, gen/ freshness, hand-copied constants, save corruption beyond the one-generation backup (no truncation or fuzz test found), or threading overlap. The covered set (rules parity, campaign parity with save and reload cycles, API smoke, bot full runs with error counting and hang diagnostics, music_check once content lands) is stronger than most shipped games have; the gaps are all in the shell and build layer, which is exactly where the remaining findings cluster.

Documentation drift as a class: music (B13), the campaign UI DRAWN column in FEATURES.md (PACK-STATED stale), the export path disagreement (finding 4), and possibly the CUT/SOLID README line (correction B) are four instances of one pattern: docs written at landing time, never re-checked against the tree. A periodic doc-versus-tree pass is cheaper than the confusion each instance costs. INFERRED as a class; each instance above is evidenced on its own.

## Bugs ranked by severity (all areas)

1. Campaign stream never seeded in the shipped shell. First-run content identical on every launch and install. OBSERVED jsm.gd:52, campaign.gd:942 and its draws, campaign.gd:2105 and 2291 (battle-only seeds), campaign_scene.gd:27 (the standalone scene seeds correctly, proving the shell is the odd one out). Fix is one line plus a decision on continued runs (see UNSURE).
2. Threading by convention: eval caches, the static scratch buffer and half-mutated reads are one future overlapping call away from irreproducible battle corruption. OBSERVED battle_api.gd:505-518, rules.gd:177-182, jsm.gd:15, battle_scene.gd:650-665 and 1677-1709.
3. JSM maths edges return 0.0 in live play instead of stopping. OBSERVED jsm.gd:162, 225, 240, 317, 352.
4. NOT PORTED clears and plays a partially computed batch in live battles. OBSERVED battle_scene.gd:661-663, 673-675. Must be a hard stop or a proven-empty set before cutover.
5. Export ships the campaign test oracle (about 516 KB of JS plus harness) and lacks icon, versions and codesign. OBSERVED export_presets.cfg:9-12, 26, 31, 33, 36-37.
6. Build not reproducible from the repo: gen/ absent, A4 sources off-repo, sky and asteroid sources in a contrib scratch folder, freshness by hand-bumped version only. OBSERVED build_assets.gd:12, 59, 83-84, 421-422; inventory (gen/ zero files).
7. view() returns arena and shMax by reference against its own read-only contract. OBSERVED battle_api.gd:86-104.
8. Save write not atomic (copy to .bak, then overwrite in place). OBSERVED campaign.gd:362-375. Well mitigated on load; worst case is one lost save step.
9. Soft-dependency silent degradation can ship the fallback campaign UI with no error. OBSERVED campaign_host.gd:78-82 and the same pattern at campaign_host.gd:63-64 and ship_view.gd:118.
10. step() mutex has no failure path; a mid-step error in a debug build can lock it forever. INFERRED from OBSERVED battle_api.gd:505-518.
11. Music docs claim content and done-ness that the tree does not have; music_check cannot pass as written. OBSERVED music_README.md, inventory for godot/music/, music_check.gd:34-39.
12. CUT/SOLID parity coverage contradiction between the pack and the rules test README. One of the two documents is wrong; if the pack is right, a terrain-state bug class is invisible to parity. OBSERVED rules_test_README.md:34, rules.gd:27-28.

## Refinements ranked by value per unit of effort

1. Thread-local (or local-array) float conversion in jsm.gd, removing the shared _pb buffer class entirely. One file, small diff, kills half of bug 2's mechanism.
2. Take the existing mutex in every public battle_api entry point, not just step(). The scene already serialises calls, so this is enforcement of current behaviour, not a redesign.
3. A Node diff check for the hand-copied constants (FAC3D, CLS_LEN, AI_HULLS, FINISH, BIOMES, ROCKS, PLANETS) plus a byte-compare of the shared oracle files, run with the parity scripts. Covers Area 5 in one step.
4. Atomic save write (temp file plus rename) in persist_save, keeping the .bak generation. Standard pattern, one function.
5. Duplicate arena and shMax in view(). Two lines.
6. Narrow the three warning suppressions to drop integer_division and narrowing_conversion, and fix or individually suppress what surfaces. The campaign file proves warnings-on is livable; these two classes are the port's own documented traps. (Correction in finding 3 applies: only six classes are project-warn today, so scope the work to those six, not seventeen.)
7. An exported-build smoke assertion that the real campaign UI, real fx, story hook and music player all loaded, failing loudly in bot mode if any fell back. One check, closes a whole silent class.
8. Source hashes in the gen/ manifest so _current checks content, not just a version constant.
9. A debug assertion in finish_battle for the B fields the campaign reads. Turns a future rename into a loud test failure.
10. One line each in the determinism docs: parity proves sequential determinism only; audio randomness is unseeded by design. Plus a settings version field the next time the save format is touched.

## Alternative approaches (with trade-offs)

- Rules threading: single dedicated rules thread with marshalled results. Cleanest, kills the race class permanently. Costs a rewrite of the scene's batch flow mid-migration and risks new timing bugs before cutover. Rejected for now in favour of refinements 1 and 2; revisit if a second concurrent caller appears.
- Render and world constants: full generation with checksum lock, like tables.json. Makes drift impossible rather than detected. Costs load-order and failure-mode changes in the shell, and a cosmetic table mismatch would block the game. Rejected in favour of the diff check (refinement 3).
- Generated assets: commit gen/ (or Git LFS) for a checkout-and-export build. Removes the freshness question and the PC-state dependency. Costs repo size and large binary diffs on every art change. Either this or the hash-based freshness (refinement 8) is defensible; the current undocumented middle state is not.
- Saves: keep the current format and loader as they are. The IEEE hex encoding and keep-the-sound-half load are correct responses to real platform behaviour; only the write needs atomicity.

## Additions before cutover

1. Seed the JSM stream at shell startup (wall clock, as campaign_scene.gd:27 and the browser do), plus the continued-run decision implemented and tested. Reason: bug 1 is user-visible on every first run and no existing test can catch a regression of the fix unless a startup test seeds and compares first-run draws.
2. Threading hardening: refinements 1 and 2, plus one overlapping-call test (threat_map during a worker step) even if it only runs in bot mode. Reason: after cutover, race bugs have no browser build to bisect against.
3. Maths edges and NOT PORTED become hard stops in release builds, or the unported sets are proven empty by a sweep that logs every push_error path. Reason: silent wrong numbers are worse than a stopped battle once the Godot build is the only build.
4. Export preset excludes all test trees, and an export-content check runs on the built .pck. Reason: shipping the JS oracle and harness is avoidable weight and an avoidable confusion source for any future platform review.
5. The exported-build smoke assertion (refinement 7) wired into bot runs. Reason: the fallback UI shipping silently is a cutover-shaped failure, not a polish item.
6. Atomic save write. Reason: save loss reports land in the first week after cutover, when the player base is Ryan plus early players with no other build to fall back on.
7. The CUT/SOLID question answered in writing and, if the pack is right, a scenario that exercises terrain state into the hash. Reason: parity is the migration's core promise; a known blind spot in it should not cross the cutover line unresolved.

## Additions before Steam

1. Icon, file and product versions, and codesign sorted in the export preset, and the export path disagreement with FEATURES.md resolved. Reason: store and installer basics; none of it blocks cutover testing.
2. Reproducible build from the repo alone: sky and asteroid sources in the repo, A4 sources in the repo or behind a documented fetch step, source-hash freshness, and a one-page build recipe. Reason: a Steam depot rebuild on a new PC is exactly when PC state dependencies surface.
3. Music content landed (music.json, tracks, CREDITS.md) or FEATURES.md and the README corrected to say the player ships silent until it does. Reason: the licence check job and the store page both depend on the true state, and a silent game reads as a bug to a buyer.
4. Save corruption test: truncated and bit-flipped saves through load_save_text, asserting the backup path and the keep-the-sound-half behaviour. Reason: cheap insurance on the one file the player cannot replace.
5. A timing line for view() and ui_info() in the existing timing report at s23 scale. Reason: Steam hardware range is wider than the build PC; knowing the presentation cost before launch beats profiling after reviews mention stutter.

## UNSURE list

- Whether any file not fetched for this audit seeds the JSM stream at shell startup. My grep covered every fetched .gd file; main.gd itself (13,779 bytes per inventory) was not fetched, so the pack's grep over main.gd is the only evidence for that one file. PACK-STATED negative.
- Whether the JS save stored PRNG stream state. This decides whether continuing a saved run should reseed or resume the stream after the seeding fix, and nothing in the fetched sources answers it.
- Whether the canonical hash covers CUT and SOLID (correction B). Needs the golden writer or parity_main, neither fetched.
- Whether FAC_PRICE is missing from the generated tables or simply not a Godot-side name. FAC_GATES is confirmed present (campaign.gd:75); FAC_PRICE has zero hits in the fetched GDScript.
- What happens to an in-flight worker step() when the player quits mid-battle. main.gd's quit_clean ordering is PACK-STATED; the worker quiesce order is not described in any fetched doc.
- Which battle cues the fx stub still owns versus the real fx. Fx internals are out of scope for this audit.
- Whether the export preset's gaps are handled at PC build time by tools/pc scripts, which were not fetched.
- Whether gen/ or other build output is committed on another branch or exists only on the PC.
- Whether canon and numstr ever run on a live per-frame path. PACK-STATED as test and load machinery; not traced through every caller.
- Hull section counts per ship. Nothing in the fetched in-scope files states the number; the damage marks work assumed 4 to 8 and the fx audit is the place that can settle it.

## One-sentence verdicts

- Rules port and parity: SOUND WITH RISKS. A genuinely strong exact-parity rig undermined at the edges by an unseeded shell stream, five silent maths edges, and one unresolved coverage question.
- Threading and shared state: NEEDS WORK. Safe today by a stated convention, one ordinary future change away from a bug class nothing else in the project can detect.
- Campaign logic and saves: SOUND WITH RISKS. Careful format work and a defensive loader, with a non-atomic write as the one clear defect.
- Shell and glue: SOUND WITH RISKS. Good diagnostics and bot support, held back by silent degradation paths and a NOT PORTED behaviour that must change at cutover.
- Data duplication and drift: SOUND WITH RISKS. The generated-table pattern is exemplary; the hand-copied constants and the manually synced oracles are unguarded by comparison.
- Asset pipeline and build: NEEDS WORK for reproducibility. The PC workflow functions, but the game cannot yet be built from the repo alone and freshness rests on a hand-bumped constant.
- Music and portraits plumbing: SOUND code, NEEDS WORK state reporting. Both subsystems are well built; the music docs describe content that does not exist yet.
- Tests and documentation: SOUND WITH RISKS. Coverage is deep where the port is delicate and absent exactly where the shell and build findings cluster, and doc drift is a repeating pattern rather than a one-off.

Overall verdict: the migration is in good shape and closer to cutover than its finding list makes it sound, because the hard part (exact rules parity with real discipline) is done well; what remains is a short list of shell, build and honesty fixes, of which the unseeded campaign stream is the only one a player would notice today.
