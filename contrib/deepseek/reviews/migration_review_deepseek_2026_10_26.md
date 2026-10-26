# Godot migration review, DeepSeek leg (raw), 2026-10-26

Voidsworn Godot migration review

I worked only from the evidence pack and the four attached files, plus public Godot documentation where the pack makes an engine claim. I have not seen other legs or earlier reviews. The pack's own UNSURE items are respected and extended at the end.

1. Rules port and parity (godot/rules/, jsm.gd)

Verdict: SOUND WITH RISKS. The parity rig is unusually strong: exact doubles, a canonical record at every action point, 23 scenarios, a 200-battle sweep, and campaign parity after every click. But it has three blind spots that match the port's actual failure modes: terrain state, maths edges, and seeding in the shipped shell.

(a) BUGS

1. The campaign stream is never seeded in the shipped shell. This is observed. jsm.gd line 52 starts rng_s at 0. campaign.gd newRun (line 942) draws foe order, patrons, captain names, the starting relic, sector 1 node seeds (line 2095), and the Nemesis with no reseed. main.gd, title.gd, campaign_host.gd, and story.gd contain no rnd_seed call. The standalone campaign scene does seed from the wall clock (campaign_scene.gd line 27), and the browser seeds at load, so the shipped Godot shell is the odd one out. First-run content is a fixed sequence until player choices move the draw count. No existing test can see this because parity and bot runs seed explicitly. Severity: high for every new player, every fresh install.

2. The canonical hash SKIP sets exclude CUT and SOLID module state on both sides (SKIP_B = {units, log, cfg, prog}, SKIP_U = {t, ship}; pack, Rules port). A terrain-state bug passes parity silently. This is observed and was also found by the earlier sprint audit. Severity: high, because terrain bugs are exactly the kind that produce wrong-but-plausible battle outcomes.

3. Unported maths edges return 0.0 and play continues (jsm.gd lines 162 sin/cos argument too large, 225 atan2 infinity, 240 exp range, 317 pow with large exponent, 352 pow subnormal). Each push_error and returns 0.0. In a release build push_error only logs. The rules layer has a NOT PORTED stop; the maths layer does not. An extreme input in live play silently produces a wrong number. Severity: medium, because the inputs are rare, but the failure mode is invisible.

(b) REFINEMENTS

• Add a terrain scenario to the parity set that deliberately exercises CUT and SOLID state, and include those fields in the canonical hash for that scenario only. Cheaper than expanding the global SKIP set: keep the existing hash stable, add a second "terrain hash" written beside it and compared when the scenario flag says so.

• Make the unported maths edges stop the run in parity mode and, before cutover, in release. The rules layer already has a NOT PORTED mechanism; route JSM failures through it instead of returning 0.0. If a hard stop is too blunt for live play, at least count and report them through the battle scene's error list.

• Add a one-line startup seed test to the bot harness: start a fresh process, read the first three campaign draws, assert they are not identical across two launches. This is the only way the seeding bug becomes visible to CI.

(c) ALTERNATIVE APPROACHES

• Instead of a global SKIP set, compute two hashes per record: a "play hash" with the current SKIP sets and a "terrain hash" that includes CUT and SOLID. The cost is roughly double the hash text and a slightly slower compare. The benefit is that terrain regressions stop the run without destabilising every existing golden record. Trade-off: the harness must agree which hash is authoritative for which scenario, and the compare tool grows a mode.

• A property-based test for the maths port would catch the unported edges faster than adding scenarios: generate random doubles across the fdlibm argument ranges and compare against Node on every run, not only in the one-off "hundreds of thousands of inputs" check. Cost: a Node dependency in the normal test path. Benefit: the unported edges become a standing red light instead of a note in jsm.gd.

2. Threading and shared state

Verdict: NEEDS WORK. The current convention works today, but it is enforced only by scene flags and one mutex, and the shared process globals are the weakest point. I would harden the shared state now with a small, local change rather than a redesign.

(a) BUGS

1. jsm.gd line 15 has one process-wide PackedByteArray scratch buffer behind hi(), lo(), words(), hex64(), and from_hex64(). Every float-word conversion in rules, campaign, and the API funnels through it. threat_map() runs on a worker during the player phase (battle.gd lines 650-667; battle_api.gd threat function). Any concurrent float conversion on the main thread writes the same buffer. This is observed mechanism, inferred hazard; it is a data race that single-threaded parity cannot see.

2. threat_map() clears the shared eval caches on the rules instance (rules.gd eval_begin about lines 177-181 clears _los, _guard, _tc, _hc, _lw, _slot) and runs eval_end after. step() holds _mutex (battle_api.gd lines 505-518), but threat_map() does not take that mutex. If threat computation overlaps an enemy think that also uses eval caches, the caches can be cleared mid-use. The pack says this is possible; the current scene flags (_threat_busy, busy, thinking) are the only guard. Severity: high because the symptom is rare, irreproducible battle corruption.

3. step()'s mutex has no failure path (inferred). GDScript has no try/finally, so a runtime error aborting step() mid-activation in a debug or editor build leaves _mutex locked and every later step() blocks forever. The bot hang guard would catch the symptom, not the cause. Severity: low probability, high confusion cost.

(b) REFINEMENTS

• Replace the single static _pb with a per-caller buffer or a small thread-local map keyed by OS.get_thread_caller_id(). The call sites are static functions, so the cleanest form is a static var _pb_by_thread: Dictionary with one PackedByteArray per thread, created lazily. This removes the race without changing any caller.

• Either take _mutex in threat_map() or compute threat from a deep snapshot of the rules state taken under the mutex. Taking the mutex is cheaper and matches the existing convention; the cost is that threat computation and enemy think serialise, which is acceptable because the scene already serialises them with _threat_busy.

• Add a debug assertion in step() and every command that _mutex.try_lock() succeeds, and unlock in a defer-like wrapper if one can be written in GDScript 4.7. If a hard failure path is not practical, at least log the thread id and the last API call before blocking.

(c) ALTERNATIVE APPROACHES

• Run threat computation on the main thread against a copied snapshot. Cost: a deep copy of units, weapons, and terrain on every threat refresh, and the UI loses the off-thread win. Benefit: the shared eval caches never cross threads, and the mutex becomes unnecessary for threat. Trade-off: threat computation is already a cost centre (pack, performance shape); the copy makes it heavier, so this is only attractive if the race proves real in practice.

• Give the threat computation its own rules instance loaded from the same tables. Cost: setup time per battle, and the two instances must be kept in lockstep. Benefit: no shared eval caches, no shared scratch buffer, no mutex. Trade-off: memory and a second source of truth for RUN/B if the threat instance diverges.

3. Campaign logic and saves (godot/campaign/)

Verdict: SOUND WITH RISKS. The save format care is better than most shipped games. The risks are the non-atomic write and the stringly-typed battle hand-off.

(a) BUGS

1. persist_save is not atomic (campaign.gd lines 362-375). It copies the current save to save_path + ".bak" if it differs, then overwrites the main file in place with FileAccess.WRITE. A crash mid-write leaves a torn main file and a backup one save behind. The load side is defensive (sanity checks, keep the sound half), so the worst case is losing the newest save step, not the whole save. This is an observed mechanism. Severity: medium. The Godot community's standard fix is temp file plus rename; rename is atomic on every desktop OS, and Godot's own save tooling uses the same pattern. The pack also notes that a proper fsync before rename matters for power-loss safety, though for a campaign save the larger risk is a process crash, which rename alone covers.

2. The battle hand-off reads B by JS field names with no schema check (pack, Campaign logic). campaign.gd reads B.usage, unit ev fields, nemFlag, wing kills via parent. Parity is the only guard. A rules-side rename or a missing field on a refit unit becomes a null or a silently wrong value. Severity: medium, because parity catches it only when a scenario exercises that exact path.

(b) REFINEMENTS

• Write the save to save_path + ".tmp", close it, then rename over the main file. Keep the existing .bak copy before the rename if the old file parses and differs. This is a small change confined to persist_save, and it removes the torn-file class entirely. Godot's FileAccess flush and DirAccess.rename are enough for desktop; add an explicit fsync only if the team wants power-loss safety.

• Add a minimal schema check on the battle result before finish_battle: required keys, types, and a version field. Ten lines of GDScript stop the stringly-typed contract from failing silently.

• Give settings the same backup treatment or at least a version field (main.gd save_settings is a plain JSON write with no backup and no version). A renamed setting currently leaves a stale key forever.

(c) ALTERNATIVE APPROACHES

• Replace the stringly-typed battle result with a typed BattleResult RefCounted object that rules.gd fills and campaign.gd consumes. Cost: a new shared file and a conversion layer for the existing parity harness. Benefit: the compiler and the editor catch field typos, and the contract is documented in one place. Trade-off: the JS-parity test still compares dictionaries, so the typed object must be serialised back to the same dictionary shape for the golden records; otherwise parity and production diverge.

4. Shell and glue (godot/main/, godot/scenes/)

Verdict: SOUND WITH RISKS. The shell is careful: error counting, hang diagnostics, static cleanup on quit, and a fallback campaign UI are all present. The risks are the leftover fx stub and the silent soft-dependency pattern.

(a) BUGS

1. The placeholder fx_stub.gd is still preloaded by the battle scene (battle.gd line 25) while the real fx system is loaded at lines 228-229. The stub's own header says it goes away once fx/API.md exists, and that API exists. Two effects systems currently coexist; which cues each owns is UNSURE because fx internals are out of scope. Severity: medium, because double-playing cues or ownership confusion is a visible bug and a maintenance trap.

2. ResourceLoader.exists soft dependencies can throw instead of falling back (inferred). The pattern is used for the campaign UI, story hook, music player, look.gd, and fx. If a file exists but fails to parse, load(...).new() can throw on some paths rather than falling back to the stub. In an export, a packaging mistake could ship the facts-and-buttons fallback campaign UI with no error anywhere. Severity: medium, because the failure is silent when it matters most.

(b) REFINEMENTS

• Remove the fx_stub preload from battle.gd once the real fx owns all cues, or gate it behind an explicit use_fx_stub flag that defaults to false and is checked by a test. Leaving two systems wired is the kind of transition code that outlives its migration.

• Wrap each soft-dependency load in a function that distinguishes "missing" from "present but broken": use ResourceLoader.exists for the missing case and a load plus null check for the broken case, and increment the shell's error count on broken. A broken file then shows up in bot-run error counts instead of silently degrading.

• Keep the existing error-counting Logger and hang guard exactly as they are; they are the right shape for this stage.

(c) ALTERNATIVE APPROACHES

• Replace ResourceLoader.exists soft dependencies with explicit feature flags in project.godot or a small features.gd table. Cost: a few lines per feature and a build-time decision. Benefit: the shipped build knows which features it has, and a missing file is a configuration error, not a silent degradation. Trade-off: the current pattern lets the same build run with or without the campaign UI, which is useful mid-migration; feature flags remove that flexibility unless the flags are also runtime-editable.

5. Data duplication and drift

Verdict: NEEDS WORK. The generated tables already show the right pattern. The hand-copied render and world constants do not, and the two vendored JS oracles have no sync step.

(a) BUGS

1. The JS oracle is vendored twice (godot/rules/test/oracle/ and godot/campaign/test/oracle/, both pinning battle.js, core.js, and data.js at identical sizes today; pack, Findings 5). There is no documented sync step in either README. A stream B update landing in one folder leaves the two harnesses certifying against different truths. Severity: high for the migration's credibility, because the parity claim depends on both harnesses using the same oracle.

2. render/hull_table.gd and world/world.gd hand-copy renderer facts from ships3d.js and scene3d.js with no generated file and no checksum (pack, Findings 10). FAC3D, AI_HULLS, CLS_LEN, FINISH, ROCK_SET, ROCK_TINT, BIOMES, ROCKS, PLANETS. A JS-side colour or mesh change diverges silently. Severity: medium, because it is a presentation bug, but it undermines the "single colour source" claim in the art direction doc.

(b) REFINEMENTS

• Add a sync script for the two oracle folders: one canonical copy (or a Git submodule) plus a hash check in both test READMEs. A single sync_oracle.sh that copies from one source and writes the SHA-256 into both folders is enough. The cost is a shell script and a CI step; the benefit is that "the oracle" is one thing again.

• Generate hull_table.gd and world.gd constants from the JS sources with the same Node exporter that already produces tables.json, and write the constants as a .gd file with a checksum comment. tables.json already proves this pattern works in this codebase. The generated files can be checked in and verified at load, or regenerated in CI and diffed.

(c) ALTERNATIVE APPROACHES

• Put the render and world constants into a JSON table generated from JS and loaded at runtime, rather than generating GDScript. Cost: a small runtime loader and a small performance hit on first use. Benefit: one generated-data path for rules and presentation, fewer code-generation edge cases, and the same checksum-at-load mechanism as tables.json. Trade-off: the renderer loses compile-time constants, which matters only if these values are used in hot loops; the pack does not show them in hot loops.

6. Asset pipeline and build

Verdict: NEEDS WORK for Steam readiness. The pipeline works on the PC that made it, but the shippable game cannot be built from the repo alone. This is the largest gap between "working migration" and "releasable PC build".

(a) BUGS

1. godot/gen/ has zero files on main (pack, Inventory and Assets). The game loads res://gen/ at runtime, generated by render/build_assets.gd. A fresh clone has no meshes, scenes, rocks, sky, or manifest.

2. The A4 kit ship .glb files (about 10 MB per ship) live off-repo on Ryan's PC in Downloads\voidsworn_test\build\godot\assets\ships\ (pack, Assets; godot/assets/ships/README.md). Only manifest.json and previews are in the repo.

3. Sky and asteroid source paths fall back into contrib/opus/enginetest/, another contributor's scratch folder (build_assets.gd _build_sky, asteroids copy; pack, Findings 9). That folder is not a stable source of truth.

4. Freshness checks only GEN_VERSION and output-file existence (build_assets.gd _current). Editing a hull's source art without bumping GEN_VERSION or passing --force silently ships the old mesh. This is observed.

5. export_presets.cfg excludes only rules/test/*, audio/build/* (line 11). godot/campaign/test/ ships in the .pck: about 516 KB of JS oracle, Node harness files, and parity_campaign.gd. It is not needed at runtime. The preset also has an empty icon, empty file and product versions, codesign/enable=false, and an export path (../export/Voidsworn.exe) that disagrees with FEATURES.md (build\export\Voidsworn.exe).

6. ship_view.gd falls back silently through A4 kit, 8K hi scene, standard hull, and BoxMesh (pack, Render). A missing or stale gen/ shows up as box ships, not an error. The fallback itself is good design for a work in progress; the silence is the bug.

(b) REFINEMENTS

• Hash the source art (or its manifest) and store the hash in the gen/v<N>.txt marker. Freshness then depends on content, not only GEN_VERSION. The generator already knows the source paths; the marker can carry the hash.

• Move the sky and asteroid sources out of contrib/opus/enginetest/ into a repo-owned folder, or copy them into gen/ at build time with a pinned hash. The pack's own evidence shows this is another agent's scratch folder, which is not a build input.

• Add campaign/test/* to exclude_filter, set an icon, set file_version and product_version, and align the export path with FEATURES.md. These are small config changes with a large readiness payoff.

(c) ALTERNATIVE APPROACHES

• Commit gen/ to the repo, or generate it in CI with the same sources. Cost: a large binary tree in Git, or a CI runner with the art pipeline. Benefit: the repo alone builds the game. Trade-off: generated binaries in version control are painful to diff and merge; a CI generation step is cleaner but requires the source art and the generator to be in the repo, which is the real fix.

• Vendor the A4 .glb files with Git LFS, or replace them with a lower-poly in-repo kit for the shippable build. Cost: LFS bandwidth and storage, or art time. Benefit: no off-repo dependency for a Steam build. Trade-off: LFS adds a hosting dependency; a lower-poly kit loses visual fidelity.

• Make the export preset use an explicit include list for runtime resources instead of export_filter="all_resources" plus an exclude list. Cost: maintaining the include list. Benefit: test files cannot ship by omission, which is the current failure mode. Trade-off: every new runtime resource must be added to the list, and a missing one is a runtime error, so the include list must be tested.

Smallest set of changes that makes the build reproducible from the repo alone:

1. Put the A4 ship sources in the repo (Git LFS is acceptable).

2. Move the sky and asteroid sources out of contrib/opus/enginetest/ into a repo-owned folder.

3. Commit gen/ or add a CI step that runs build_assets.gd from repo-owned sources and fails on a missing input.

4. Hash source art into the freshness marker.

5. Add campaign/test/* to exclude_filter.

6. Set the icon and version strings, and fix the export path.

These are six concrete changes, each independently useful.

7. Music and portraits plumbing

Verdict: SOUND for plumbing, with a content gap that the plumbing already handles quietly. The music player and portrait facade are well built. The problem is that the folder is missing the content its README lists, and FEATURES.md marks music done while the game runs silent.

(a) BUGS

1. godot/music/ has no music.json, no tracks/, and no CREDITS.md (pack, Music plumbing; music_README.md lists all three as the folder's contents). The player skips missing files by design, so nothing complains. test/music_check.gd cannot pass as written because it loads music.json. Severity: medium for release, because a Steam build with no music and a "done" checklist is a credibility problem; low for the plumbing itself.

(b) REFINEMENTS

• Make music_check.gd fail with a clear message that names the missing files, rather than failing on a parse or load error. A content-presence check belongs in the same script.

• Keep the player's quiet-skip behaviour for runtime, but add a one-line startup warning when music.json is absent and music is enabled. The warning should be visible in bot runs and logs, not to the player.

• The portrait plumbing is sound: static facade, cache by (id, scar list), runtime composition once per key, crest fallback. No changes needed beyond a content-presence check for index.json.

(c) ALTERNATIVE APPROACHES

• None worth the churn here. The music player's design is already right: adaptive layers, separate bus, per-instance streams, no static leaks. The portrait composition is also right: lazy, cached, and fallback-safe. The only alternative worth naming is to defer music entirely until content exists and mark it explicitly as "content missing" in FEATURES.md, which is a documentation change, not a code change.

8. Anything else the pack gives evidence on

Verdict: SOUND WITH RISKS. The pack's strengths are real: RNG discipline, checksum-locked tables, bot runs with error counting, save format care. The gaps are test coverage and documentation drift.

(a) BUGS

• No new code bug in this area beyond what is listed above. The performance shape is a risk, not an observed bug: view() rebuilds the full unit and weapon view after every batch, and ui_info() computes expected damage for every weapon against every living enemy per call. The pack calls these cost centres with no documented budget. I tag them as UNSURE performance risks, not defects, because the pack gives no frame-time evidence.

(b) REFINEMENTS

• Add an export-contents check: list what lands in the .pck and compare against an allowlist. The current preset ships campaign/test/ because no check exists. A simple post-export script that opens the .pck and greps for test/oracle/ would catch this class.

• Add a gen-freshness check to the normal test path: hash the source art, compare to the marker. The bot run already exercises the game; it could fail early if gen/ is stale.

• Add a startup-seed test to the bot harness, as described in Area 1.

• Add a documentation-versus-tree check for the class the pack identifies: music README lists files that do not exist, FEATURES.md says music done, the export path disagrees. A small CI step that parses the READMEs' file lists and checks existence would catch this class cheaply.

(c) ALTERNATIVE APPROACHES

• Make FEATURES.md generated from the tree and the tests where possible. Cost: a small generator and a convention for which lines are machine-checkable. Benefit: the "done" column cannot drift from reality. Trade-off: not every feature can be inferred from a file's existence, so the generated file needs a hand-maintained overlay, which can itself drift.

(a) Bugs ranked by severity across all areas

1. Campaign stream unseeded in the shipped shell (jsm.gd line 52; campaign.gd newRun line 942; no rnd_seed in main.gd, title.gd, campaign_host.gd, story.gd). Every fresh install gets the same first-run content. High severity, one-line fix plus a test.

2. Two vendored JS oracles with no sync step (pack, Findings 5). The parity claim is only as strong as the oracle both harnesses use; today they can diverge silently. High severity for migration confidence.

3. Shared static scratch buffer _pb across threads (jsm.gd line 15) and threat_map() clearing shared eval caches without the mutex (rules.gd about lines 177-181; battle_api.gd threat function). Rare, irreproducible battle corruption that single-threaded parity cannot see. High severity because it is invisible.

4. SKIP_B and SKIP_U exclude CUT and SOLID (pack, Rules port). Terrain-state bugs pass parity. High severity for a tactics game where terrain matters.

5. The shippable game cannot be built from the repo alone (gen/ absent, A4 files off-repo, sky and asteroid sources in contrib/opus/enginetest/; pack, Findings 9). High severity for Steam readiness.

6. export_presets.cfg ships campaign/test/ (line 11 excludes only rules/test and audio/build), and has no icon and no version strings. Medium-high severity for release hygiene.

7. persist_save is not atomic (campaign.gd lines 362-375). A crash mid-write loses the newest save step. Medium severity; the load side limits the damage to one save.

8. Unported maths edges return 0.0 and continue (jsm.gd lines 162, 225, 240, 317, 352). Rare inputs produce wrong-but-plausible numbers. Medium severity.

9. fx_stub.gd still preloaded alongside the real fx (battle.gd line 25 and lines 228-229). Two effects systems coexist; cue ownership is UNSURE. Medium severity.

10. Stringly-typed battle hand-off with no schema check (campaign.gd reads B by JS field names; pack, Campaign logic). Medium severity, because parity only covers scenarios that exercise the field.

11. Soft dependencies can throw instead of falling back when a file exists but fails to parse (ResourceLoader.exists pattern; pack, Findings 12). Medium severity, silent in export.

12. Hand-copied hull_table.gd and world.gd constants with no check (pack, Findings 10). Medium severity, presentation drift.

13. step()'s mutex has no failure path (battle_api.gd lines 505-518; inferred). Low probability, high confusion cost.

14. Settings have no backup and no version field (main.gd save_settings; pack, Campaign logic). Low severity.

15. Music content absent while docs say done (pack, Findings 8). Medium for release credibility, low for code correctness.

(b) Refinements ranked by value per unit of effort

1. Seed the campaign stream at shell startup (one line, plus a bot test). Highest value per minute.

2. Add campaign/test/* to exclude_filter, set icon and version strings, fix export path (one config change). High value, minutes of work.

3. Write saves to a temp file then rename (campaign.gd persist_save). Small change, removes a whole corruption class.

4. Per-thread scratch buffer in jsm.gd (lazy dictionary keyed by thread id). Small change, removes the _pb race.

5. Take _mutex in threat_map() or compute from a snapshot. Small change, removes the eval-cache race.

6. Remove or flag the fx_stub preload. Small change, ends the two-system ambiguity.

7. Add a terrain hash mode to the parity harness. Medium effort, closes the CUT/SOLID blind spot.

8. Add a sync script and hash check for the two oracles. Medium effort, restores the "one oracle" claim.

9. Generate hull_table.gd and world.gd constants from JS with a checksum. Medium effort, matches the proven tables.json pattern.

10. Add a startup-seed test and an export-contents check to CI. Medium effort, makes the top two bugs permanently visible.

11. Route unported maths edges through the rules layer's NOT PORTED stop. Medium effort, turns silent wrong numbers into a stop.

12. Add a schema check on the battle result before finish_battle. Small effort, documents the stringly-typed contract.

(c) Additions before cutover

1. Seed the campaign stream in the shell and test it. Cutover means players start fresh; the fixed first run is the first thing they will see.

2. Make gen/ and the A4 ship sources buildable from the repo alone. Without this, the cutover build is not reproducible by anyone but Ryan's PC.

3. Close the CUT/SOLID parity blind spot. Cutover is the last moment to trust the parity rig; after cutover, terrain bugs become player-visible.

4. Decide and enforce the unported maths policy. Before cutover, prove the unported set is empty, or make it a hard stop. The rules layer already has a stop; the maths layer should use it.

5. Retire fx_stub. Two effects systems at cutover is a bug waiting for a cue conflict.

6. Fix the export preset exclusions, icon, and versions. A cutover build should not ship test oracles or an empty icon.

7. Make saves atomic. Cutover increases the cost of a lost save because players start trusting the build.

(d) Additions before Steam

1. A reproducible build from the repo alone (same as cutover, but Steam makes it non-negotiable).

2. An export-contents allowlist and a CI check that the .pck matches it. Steam builds are the ones you cannot patch instantly.

3. Icon, version strings, product name, and code-signing decision. Steam expects these; an unsigned build warns every player.

4. A music content decision. Ship tracks with credits, or mark music explicitly as out of scope for 1.0. The current state (plumbing done, content absent, checklist says done) is the worst of both.

5. A save-corruption fuzz test around the atomic write and the backup fallback. The load side is defensive; prove the write side now.

6. A threading overlap stress test: run threat_map() on a worker while a scripted enemy step() runs, and assert the battle state is identical to a single-threaded run. This is the only way the shared-state risks become visible before players see them.

(e) UNSURE list

The pack's items:

• Whether any file not read for the pack seeds JSM at shell startup (the campaign UI files and main.tscn's attached scripts were not read line by line).

• Whether the JS save stored PRNG stream state, which decides what continuing a run should do after the seeding fix.

• Whether node/export_data.js and export_campaign.js now include everything stream B added after the port_notes step 1 note (FAC_PRICE, FAC_GATES, cost values).

• What happens to an in-flight worker step() when the player quits mid-battle; the quiesce order for a running worker task is not described.

• Which battle cues the fx stub still owns versus the real fx.

• Whether the export preset's gaps (icon, versions, codesign) are handled at PC build time by the tools/pc job scripts.

• Whether gen/ or any build output is committed outside main.

• Hull section counts per ship (the damage marks work assumes 4 to 8; no in-scope file states the real number).

• godot/ui/ internals, godot/fx/ internals, godot/story/ content, tools/pc job scripts, and the JS oracle files beyond their sizes and roles were NOT CHECKED.

My additions:

• UNSURE: whether threat_map() can actually overlap step() in the current scene, or whether _threat_busy and the player-phase gating make the race impossible today. The mechanism is observed; the actual overlap is inferred. I would add the stress test before calling it a live bug.

• UNSURE: whether the Godot 4.7 Mutex has any built-in timeout or debug leak detection that changes the "no failure path" assessment. My knowledge is from memory that GDScript has no try/finally; I did not open a 4.7-specific page on Mutex failure semantics.

• UNSURE: whether FileAccess in Godot 4.7 flushes to disk on close() or only to the OS buffer. The atomic-write sources say rename is enough for process crashes but not power loss without fsync; I did not verify the exact Godot 4.7 close() behaviour.

• UNSURE: whether the two oracle folders are currently byte-identical or only same-size. The pack says identical sizes today, not identical hashes.

• UNSURE: whether the A4 .glb files can be licensed for redistribution if moved into the repo. That is a legal question, not a code question, but it gates the "reproducible from repo alone" fix.

(f) One-sentence verdict per area

1. Rules port and parity: SOUND WITH RISKS. The rig is excellent but blind to terrain, maths edges, and shell seeding.

2. Threading and shared state: NEEDS WORK. The convention works today, but the static scratch buffer and unlocked threat path are races waiting for a second caller.

3. Campaign logic and saves: SOUND WITH RISKS. Save care is strong; the non-atomic write and stringly-typed hand-off are the weak points.

4. Shell and glue: SOUND WITH RISKS. Error counting and cleanup are good; the leftover fx stub and silent fallbacks need attention.

5. Data duplication and drift: NEEDS WORK. The generated-table pattern exists and should be extended to the hand-copied constants and the duplicated oracles.

6. Asset pipeline and build: NEEDS WORK. The build is reproducible on one PC, not from the repo, and the export preset is not Steam-ready.

7. Music and portraits plumbing: SOUND. The code is careful; the missing music content is a release problem, not a plumbing problem.

8. Anything else: SOUND WITH RISKS. Test coverage is strong in parity and bots, thin in startup seeding, export contents, gen freshness, and threading overlap.

Overall verdict: SOUND WITH RISKS, and the risks are concentrated in reproducibility and shared-state discipline. The migration is in good shape technically; the gap to a safe cutover is a short list of concrete fixes, not a redesign.
