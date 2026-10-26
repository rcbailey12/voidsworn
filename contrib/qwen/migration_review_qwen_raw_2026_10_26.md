# Godot migration review, Qwen leg (raw), 2026-10-26

Filed verbatim from the Qwen leg run 2026-10-26 (Qwen3.8-Max, both gates passed; pack pasted in four parts, submitted once; the browser agent rebuilt the staged prompt in correct part order before submitting). Method notes are in the chair screening note, not in this file.

---

Voidsworn Godot Migration Review: Blind Leg
Reviewed against the evidence pack dated Oct 26, 2026, fetched from main. All file and line references below come from the pack unless stated otherwise. Where I rely on my own knowledge of Godot 4.x engine behaviour rather than a cited source, I say so.

1. Rules port and parity (godot/rules/, jsm.gd)
Verdict: SOUND WITH RISKS
The parity rig is genuinely strong. Exact-double comparison with no tolerance, a canonical SHA-256 hash after every action point, 23 scenarios covering all 8 fight types plus a 200-battle sweep with a zero-difference exit bar, and a campaign parity harness that records after every click across 30 seeded runs with save and reload cycles (pack, Architecture as documented, Rules parity section). The PRNG discipline is total: a grep of rules.gd, campaign.gd, battle_api.gd and jsm.gd finds zero uses of Godot's global randf, randi, or RandomNumberGenerator; every rules draw flows through JSM.rnd (pack, Per-area evidence, Rules port). The mulberry32 port is checked over 10,000 draws from three seeds. The V8 fdlibm maths port (sin, cos, atan2, exp, scaled hypot, Math.round, Math.pow) is line-for-line and checked on hundreds of thousands of inputs. The load_tables checksum in both rules.gd and campaign.gd refuses to run on a stale table (pack, Per-area evidence). The documented porting traps (ulp-off decimal literals, int/int truncation, GDScript round-half-away versus JS round-half-toward-positive-infinity, Dictionary == content comparison, unstable sort_custom, JSON floats) are written down in the rules test README. All of this is real and rare in shipped-game practice.

(a) BUGS
B1. The canonical hash cannot see terrain-state corruption. The SKIP sets for the golden hash are SKIP_B = {units, log, cfg, prog} and SKIP_U = {t, ship}. The pack states explicitly: "a terrain-state bug can pass parity silently" (pack, Per-area evidence, Rules port, first bullet; also noted as found by the earlier sprint audit). If a port bug mutates CUT or SOLID module state on a unit, or corrupts the arena terrain dictionary, the hash will not catch it. This is the single most dangerous blind spot in an otherwise thorough rig. Severity: high, because terrain state feeds into targeting, line-of-sight, and gravity wells, and a silent corruption there would produce wrong-but-plausible battle outcomes that no test flags.
B2. Unported maths edges return 0.0 and play continues. jsm.gd lines 162, 225, 240, 317, 352 each push_error and return 0.0 for out-of-range or special-case inputs (sin/cos argument too large, atan2 with an infinite operand, exp range, pow with |y| over 2^31, pow subnormal result). The rules layer has a proper NOT PORTED stop mechanism; the maths layer does not use it (pack, Per-area evidence, JSM section). In a release build, push_error only logs. A 0.0 where the JS would produce NaN, Infinity, or a specific subnormal is a wrong-but-plausible number that silently propagates through the rest of the turn. Severity: medium. The inputs are extreme and unlikely in normal play, but the failure mode is silent corruption rather than a stop, which contradicts the rest of the port's discipline.
B3. The shared PRNG stream is never seeded in the shipped shell. jsm.gd line 52 declares static var rng_s with no initialisation beyond 0. campaign.gd newRun (line 942 onward) draws heavily from the stream with no reseed: shuffled foe order, shuffled patrons, captain names via newShip, a random starting relic, genSector(1) map generation with node seeds drawn at line 2095, and newNemesis. The only seeds in campaign.gd are on battle paths (line 2105 for battle start, line 2291 for stub battle), and rules.gd line 1044 seeds inside startBattle from cfg.seed. The pack grep-verified that main.gd, title.gd, campaign_host.gd, and story.gd contain no rnd_seed call. The standalone campaign scene (campaign_scene.gd line 27) seeds from the wall clock, matching the browser, but that scene is not the shipped shell path. Result: on a fresh process, rng_s starts at 0, and the first campaign run draws from the same fixed sequence on every launch and every install, until the player's own choices change how many draws are consumed. No existing test can see this because parity and bot runs seed explicitly (pack, Findings list, item 1). Severity: high for player experience, not a crash.
UNSURE: whether any file not read for the pack (the campaign UI scripts, main.tscn's attached scripts) seeds the stream at startup. The pack's grep covered main.gd, title.gd, campaign_host.gd, campaign.gd, story.gd, battle_api.gd, rules.gd, and the standalone campaign scene. Respect this gap.
UNSURE: whether the JS save stored PRNG stream state, which determines what continuing a saved run should do after the seeding fix.

(b) REFINEMENTS
R1. Give the maths layer the same NOT PORTED stop the rules layer has. The five unported edges in jsm.gd should call the same halt mechanism the rules layer uses, or at minimum push a structured error that the battle scene's error counter picks up and treats as a stop rather than a continue. The current push_error-and-return-0.0 is the one place in the port where the "exact parity or stop" contract is silently relaxed.
R2. Add terrain state to the golden hash inputs, or add a separate terrain parity check. The SKIP sets are deliberate (they exclude fields that legitimately differ between the two implementations' internal bookkeeping), but CUT and SOLID module state and arena terrain are gameplay-relevant. Either narrow the SKIP sets to exclude only the truly internal fields, or add a second hash that covers terrain specifically. The cost is a small change to golden.js and parity_main.gd.
R3. The canonical writer (canon and numstr in jsm.gd) tries up to 17 precisions per number. This is test and load-check machinery. UNSURE whether it ever runs on a live per-frame path. If it does, that is a performance concern. If it does not, no action needed, but a one-line comment saying "test-only, not called in the live path" would prevent a future contributor from accidentally wiring it into a hot loop.

(c) ALTERNATIVE APPROACHES
A1. Property-based or fuzz testing on top of the golden harness. The current rig is scenario-driven: 23 hand-built scenarios plus 200 random battles. A complementary approach would be a fuzzer that generates random fleet compositions, random terrain, and random action sequences, then checks invariants (unit counts never go negative, damage is non-negative, the PRNG stream is consumed monotonically, the hash is stable across replays of the same seed). Trade-off: building the fuzzer costs a week or two of scenario-authoring time, and it will not catch port-versus-JS divergence the way exact-double parity does. It would catch internal consistency bugs that a scenario might not exercise. Worth doing before Steam, not before cutover.
A2. Splitting rules.gd. At 3,724 lines and 262 functions, it is a single file by design, mirroring the JS oracle's structure. Splitting it would make the file easier to navigate but would break the one-to-one correspondence with the JS source that makes the port auditable. The trade-off is real: the single file is harder to read but much easier to diff against the oracle. I would leave it as-is for the migration and revisit only after cutover, if at all.

2. Threading and shared state
Verdict: SOUND WITH RISKS
The current design works because the scene enforces a strict call-order convention: _think (battle.gd lines 650-667) runs api.step() and api.view() on a WorkerThreadPool task; _runner (line 626 onward) waits for _threat_busy before thinking; threat fills run api.threat_map() on a worker during the player phase. battle_api.gd step() (lines 505-518) is the only API method that takes _mutex, and its own comment states the real contract: safe on a worker thread as long as the scene calls nothing else meanwhile. view(), ui_info(), threat_map(), and every command are unlocked. The scene's busy, thinking, and _threat_busy flags are the only enforcement (pack, Per-area evidence, Battle scene glue).

(a) BUGS
B4. No enforcement beyond scene-level flags. The pack states the mechanism clearly: any future main-thread API call overlapping a threat computation or an enemy think can corrupt eval caches or read half-mutated units (pack, Findings list, item 2). Specifically: eval_begin() in rules.gd (about lines 177-181) sets _evc and clears all six scratch caches (_los, _guard, _tc, _hc, _lw, _slot). threat_map() in battle_api.gd runs eval_begin and eval_end over live unit dictionaries, so a threat computation is not read-only with respect to the rules instance. If the main thread calls any method that touches those caches while a worker threat fill is in flight, the caches are clobbered. jsm.gd line 15 (one static PackedByteArray scratch buffer for all float-word conversion) and line 52 (one static PRNG stream) are process-global and unprotected. Severity: low probability today because the scene's flag discipline holds, but high consequence if it breaks: rare, irreproducible battle bugs that single-threaded parity cannot see.
B5. The mutex has no failure path. GDScript has no try/finally (this is from my knowledge of the language; Godot's GDScript does not support exception handling as of 4.x). A runtime error aborting step() mid-activation in a debug or editor build leaves _mutex locked, and every later step() blocks forever. The symptom would be a bot-run HANG report (pack, Findings list, item 15; Per-area evidence, Battle scene glue). Severity: low probability, high confusion cost when it happens.

(b) REFINEMENTS
R4. Add a debug-only assertion or counter that detects concurrent access. A simple atomic counter incremented on entry to any API method and decremented on exit, checked to never exceed 1, would turn the convention into a detectable violation in debug builds. Cost: a few lines in battle_api.gd. This does not fix the underlying design but converts the "future contributor breaks the convention" failure from a silent corruption into a loud error.
R5. Guard the static scratch buffer in jsm.gd. The one PackedByteArray at line 15 is used by hi(), lo(), words(), hex64(), and from_hex64() for the whole process. If any two threads call these concurrently, the buffer is corrupted. The cheapest guard is a comment and a debug assertion that the calling thread is the one that owns the rules instance. A thread-local buffer would be the proper fix but costs more and may not be worth it if the convention holds.

(c) ALTERNATIVE APPROACHES
A3. Lock every public API method, not just step(). This is the textbook answer and the safest option. Trade-off: it serialises all API access, which removes the benefit of running threat computation on a worker thread during the player phase. On 20-ship boards the threat computation is a meaningful cost centre (pack, Findings list, item 16, notes ui_info computes expected damage for every weapon against every living enemy per call). Locking everything would push that cost back onto the main thread and could cause visible hitches. The current convention is faster. I would not lock everything now; I would add the debug assertion from R4 and revisit if the team grows or the call graph gets more complex.
A4. Move threat computation to a copy of the state rather than live dictionaries. threat_map() currently runs eval_begin and eval_end over live unit dictionaries. If it operated on a deep copy of the units, it would be genuinely read-only and could run without any lock. Trade-off: copying 20 ships' full unit state per threat fill is not free, and the copy itself must be taken under a brief lock. But it eliminates the entire class of cache-clobbering bugs. Worth considering before Steam if the threading model gets any more complex.
Would I harden it now or leave it with a guard? Leave it with a guard for cutover. The convention is documented in battle_api.gd's own comment, the scene enforces it, and the parity rig is single-threaded by construction so it cannot regress silently. Add the debug assertion (R4) and the scratch-buffer comment (R5) now. Revisit the lock-everything or copy-for-threat approaches before Steam if the call graph has grown.

3. Campaign logic and saves (godot/campaign/)
Verdict: SOUND WITH RISKS
The page and acts contract is clean: every JS show() or modal() becomes a page {kind, data, acts} or modal; acts are [act, arg, enabled] in browser order; campaign.act(name, arg) is the only state-changing entry point (pack, Architecture as documented, Campaign parity). Parity is 30 seeded full runs with a scripted player clicking buttons read from the JS game's own HTML, a canonical record after every click, exact-double compare, and periodic save, load, and reload cycles. The save format care is genuinely good: IEEE hex encoding for non-integers, sanity checks, migrations with a player-facing explanation.

(a) BUGS
B6. The save write is not atomic. persist_save (campaign.gd lines 362-375): if the current save file exists, parses, and differs, it is copied to save_path + ".bak" first; then the new save overwrites the main file in place with FileAccess WRITE. There is no temp-file-plus-rename step. A crash mid-write leaves a torn main file and a backup one save behind (pack, Per-area evidence, Campaign logic; Findings list, item 11). The load side is well defended (saneSave and saneRun checks, fall back to the backup, keep whichever half is sound), so the worst case is losing the newest save step. Severity: medium. Not a crash, but a data-loss path that the fix cost (write to temp, rename) would eliminate.
B7. Settings have no backup and no version field. main.gd save_settings is a plain JSON write. Keys are merged on load, so a renamed setting leaves a stale key behind forever (pack, Per-area evidence, Campaign logic). Severity: low, cosmetic.

(b) REFINEMENTS
R6. Make the save write atomic. Write to save_path + ".tmp", then rename over the main file. God's FileAccess does not have a rename method, but DirAccess.rename_absolute() or OS-level rename works. The one-generation backup (.bak) is a good safety net and should stay. Cost: about ten lines.
R7. Add a schema check or at least a field-name constant table for the battle hand-off. The campaign reads the battle's B dictionary by JS field names after finish_battle, including B.usage, unit ev fields, the nemFlag unit, and wing kills via parent. This is a stringly-typed contract between campaign.gd and rules.gd with no schema check on either side; parity is the only guard (pack, Per-area evidence, Campaign logic). A const dictionary of expected field names, checked once at the start of finish_battle, would turn a typo or a stream-B field rename into an immediate error instead of a silent null. Cost: small.
R8. Add a save-format version field to the envelope. The envelope is {"format": "voidsworn-godot-campaign", "v": 1} (campaign.gd line 361), and SAVE_VERSION is 2 for meta (line 188). The two version numbers track different things. A comment explaining which version gates what would help the next person who touches migration logic.

(c) ALTERNATIVE APPROACHES
A5. Typed save format instead of JSON with hex-encoded floats. God's Resource system or a binary format would avoid the ulp problem entirely. Trade-off: the current JSON-plus-hex approach is human-readable, debuggable, and matches the JS save's structure, which matters during the migration when saves might need to be compared across implementations. Switching to binary would save bytes and eliminate the hex encoding but would make debugging harder and break the "read the save in a text editor" workflow. Not worth it now. Revisit after cutover if save size becomes a concern.
A6. Store the PRNG stream state in the save. This is tied to the seeding bug (B3). The browser resumes the stream on load; whether the JS save stored stream state is UNSURE. If the Godot save does not store it, a loaded run will draw from a different point in the stream than the original run did, which could change captain names, patron order, or node contents on the next draw. Decide the policy (store and restore, or reseed from a stored seed) and implement it alongside the B3 fix.

4. Shell and glue (godot/main/, godot/scenes/)
Verdict: SOUND WITH RISKS
The shell is a code-built scene tree (6 .tscn files totalling 1,010 bytes; scenes are built in code). main.gd owns title, settings, quick battle, and the campaign/battle hand-off. campaign_host.gd loads tables and the save, sets battle_mode to external, plays battles via main.play_api(api, opts), then calls campaign.finish_battle. The bot-run infrastructure with engine-error counting, softlock detection, and hang diagnostics is a real strength.

(a) BUGS
B8. ResourceLoader.exists soft-dependency can throw instead of falling back. The pattern gates the G3 campaign UI versus the fallback UI, the story hook, the music player, render/look.gd, and G4 fx on ResourceLoader.exists. A missing file degrades silently. But a file that exists but fails to parse makes load(...).new() throw on some of these paths instead of falling back (pack, Per-area evidence, Main shell, marked INFERRED). In an export, a packaging mistake could ship the facts-and-buttons fallback campaign UI with no error anywhere (pack, Findings list, item 12). Severity: medium for the silent degradation path, low for the throw path (which at least crashes loudly).
B9. The fx stub is still preloaded alongside the real fx. battle.gd line 25 preloads fx_stub.gd; battle.gd lines 228-229 load the real fx via ResourceLoader.exists. The stub's own header says it goes away when godot/fx/API.md exists. That API exists. Two effects systems currently coexist; which cues each owns is UNSURE (pack, Per-area evidence, Battle scene glue; Findings list, item 14). Severity: low for correctness (the stub presumably does nothing harmful), but it is dead weight and a confusion source.
B10. NOT PORTED during live play degrades instead of stopping. battle.gd _think (about line 662) and _cmd (about line 674) record the error in the scene's error list, clear R.not_ported, and continue playing the batch that was partially computed. The player sees no stop; the error surfaces only via the in-battle Report a problem menu or bot runs (pack, Per-area evidence, Battle scene glue; Findings list, item 7). Severity: acceptable during migration, a bug at cutover.

(b) REFINEMENTS
R9. Wrap the ResourceLoader.exists + load + new pattern in a helper that catches parse failures. A single function, try_load_scene(path) -> Node or null, that checks exists, attempts load, checks for null, and returns null on any failure, would replace the five or six call sites and eliminate the throw-on-parse-failure path. Cost: one function, small refactor.
R10. Retire fx_stub.gd. The real fx API exists. Remove the preload at battle.gd line 25, remove the stub file, and verify that no cue is lost. The UNSURE about which cues the stub still owns needs resolving first; that is a question for the fx owner (out of scope here, but the intersection should be flagged).
R11. The _on_changed edge in campaign_host.gd. _on_changed emits run_over whenever the campaign page returns to title with no modal up. start() calls titleScreen, then an act that moves off title, then binds the UI and calls _on_changed once. The normal flows are safe, but any future flow that leaves the page on title at bind time would hand back to main's title instantly (pack, Per-area evidence, Main shell, INFERRED). A guard flag that suppresses the first _on_changed after bind would close this. Cost: two lines.

(c) ALTERNATIVE APPROACHES
A7. A scene manifest instead of soft ResourceLoader.exists checks. Instead of scattering exists() calls, a single manifest dictionary at startup could declare which optional modules are present and which are absent, and log the result. Trade-off: it adds one more thing to keep in sync, but it converts the "silent degradation" failure mode into a visible startup log line. Worth doing before Steam when the set of optional modules stabilises.

5. Data duplication and drift
Verdict: NEEDS WORK
This is the area with the clearest gap between the safety the codebase already knows how to provide and the safety it actually applies.

(a) BUGS
B11. The JS oracle is vendored twice with no sync step. godot/rules/test/oracle/ and godot/campaign/test/oracle/ both pin battle.js, core.js, and data.js at identical sizes today. No documented sync step exists in either README. A stream B update landing in one folder leaves the two harnesses certifying against different truths (pack, Findings list, item 5; INFERRED consequence). Severity: medium. Today the files match. The bug is the absence of a process, not a current mismatch, but the consequence of a future mismatch is that rules parity and campaign parity silently disagree about what the game does.
B12. Hand-copied render and world constants have no drift check. render/hull_table.gd hand-copies AI_HULLS, CLS_LEN, FAC3D, FINISH, ROCK_SET, and ROCK_TINT from ships3d.js. world/world.gd does the same for BIOMES, ROCKS, and PLANETS from scene3d.js and battle.js. The art direction doc names FAC3D in ships3d.js as the single colour source. Unlike tables.json, none of this is generated or checksum-checked, so a JS-side change diverges silently (pack, Per-area evidence, Render and asset pipeline; Findings list, item 10). Severity: medium. These are presentation constants, not rules, so a drift produces wrong colours or wrong mesh assignments rather than wrong gameplay. But the pack notes that the safer pattern (generated plus SHA-256 at load) already exists in the same codebase for tables.json.

(b) REFINEMENTS
R12. Add a sync check for the two vendored oracles. The cheapest version: a script (or a CI step, if CI exists) that diffs the two oracle folders and fails if they differ. A slightly more robust version: store a single oracle copy and symlink or copy it into both test trees at test-run time. Cost: a shell script or a GDScript check. This is the highest-value-per-effort item in this area.
R13. Generate hull_table.gd and world.gd constants from the JS sources, or at minimum checksum them. The tables.json pipeline (node/export_data.js generates, Godot loader verifies SHA-256) is the model. Extend export_data.js to emit the render and world constants, or write a small check script that hashes the relevant JS source sections and compares against a pinned hash in the GDScript files. The hand-copied constants are small (a few dozen entries each), so the check script is simpler than a full generator.

(c) ALTERNATIVE APPROACHES
A8. A single oracle directory with both test harnesses referencing it. Instead of vendoring twice, have one godot/test_oracle/ directory and have both parity harnesses point at it. Trade-off: the current two-directory layout keeps each test tree self-contained, which matters if someone runs only the campaign tests without the rules tests. A single directory is simpler but couples the two test trees. The sync check (R12) gets most of the safety without the coupling.
Where is hand-copying fine? For constants that change rarely and are visually obvious when wrong (e.g., FINISH names, ROCK_TINT colours), hand-copying with a periodic manual check is acceptable. The generated-file or check step is worth spending on AI_HULLS (mesh assignment per faction and class, where a wrong entry produces a missing or wrong ship model that might not be noticed in a quick test), CLS_LEN (used for layout math), and the FAC3D colour table (the art direction doc names it as the single source of truth, so a silent divergence contradicts the documented intent).

6. Asset pipeline and build (godot/render/build_assets.gd, godot/assets/, export_presets.cfg, project.godot)
Verdict: NEEDS WORK
This is the area furthest from Steam-ready. The pack's evidence is unambiguous.

(a) BUGS
B13. The shippable game cannot be built from the repo alone. godot/gen/ (the built ship, rock, and sky resources the game loads at runtime) has zero files on main. It is generated on the PC by render/build_assets.gd. The A4 kit ship .glb files (about 10 MB per ship) live off-repo on Ryan's PC in Downloads\voidsworn_test\build\godot\assets\ships, with only manifest.json and previews in the repo. The sky and asteroid field placements fall back to paths inside contrib/opus/enginetest/, another agent's scratch folder (pack, Per-area evidence, Render and asset pipeline; Findings list, item 9). Severity: high for reproducibility and for any build that is not on Ryan's specific PC.
B14. gen/ freshness rests on a hand-bumped version constant plus output existence. build_assets.gd _current checks only the GEN_VERSION constant and that the output file exists. Editing a hull's source art without bumping GEN_VERSION or passing --force silently ships the old mesh (pack, Per-area evidence, Render and asset pipeline). Severity: medium. The failure mode is a stale asset, not a crash, but it is the kind of bug that produces "why does the ship look wrong" debugging sessions.
B15. The export preset ships test and harness files. export_presets.cfg line 11: exclude_filter = "rules/test/, audio/build/" only, with export_filter all_resources. godot/campaign/test/ ships in the .pck: its oracle is about 516 KB of JS (battle.js 162,826; ui3d.js 115,653; campaign_run.js 64,891; data.js 80,349; core.js 37,509; campaign_meta.js 32,143; campaign3d.js 22,337) plus Node harness files and parity_campaign.gd. Nothing in it is needed at runtime (pack, Per-area evidence, Export and project settings; Findings list, item 4). Severity: low for correctness, medium for professionalism and build size.
B16. The export preset has no icon, no version strings, codesign off, and an export path that disagrees with FEATURES.md. export_path is "../export/Voidsworn.exe" (outside the project folder), while FEATURES.md says the exe is built at build\export\Voidsworn.exe on the PC. One of the two is stale (pack, Findings list, item 4). Severity: medium for Steam readiness.

(b) REFINEMENTS
R14. Add campaign/test to the exclude filter. One line in export_presets.cfg. Immediate.
R15. Fix the export path or the FEATURES.md reference. Determine which is correct and align them. If the tools/pc job scripts handle the path at build time, document that. UNSURE: whether the tools/pc job scripts override the preset's export_path.
R16. Add a source-art hash check to build_assets.gd. Instead of checking only GEN_VERSION and file existence, hash the source art files (or at least their modification times) and include that in the freshness check. This catches the "edited the hull but forgot to bump GEN_VERSION" case. Cost: moderate.

(c) ALTERNATIVE APPROACHES
A9. Commit gen/ to the repo, or at least to a release branch. Trade-off: gen/ contains binary meshes and textures that could be large (the 8K flagship scenes, hull meshes, rocks, sky). Committing them bloats the repo and creates merge conflicts on binary files. But it makes the game buildable from the repo alone, which is a hard requirement for Steam (Valve's build pipeline needs to produce the game from a checkout). Alternative: a build script that runs build_assets.gd as a pre-export step, with all source art in the repo. This requires moving the A4 .glb files and the sky/asteroid sources out of contrib/opus/enginetest/ and off Ryan's Downloads folder.
A10. A content-addressable asset store or LFS for the large files. Godot projects with large binary assets typically use Git LFS or a separate asset server. Trade-off: LFS adds a dependency and a hosting cost. For a small team, committing the gen/ output to a release branch and keeping the source art in the repo (with LFS for the .glb files) is the pragmatic middle ground.
Smallest set of changes for a reproducible build from the repo alone:
Move the A4 .glb files into godot/assets/ships/ in the repo (or into LFS).
Move the sky and asteroid placement sources out of contrib/opus/enginetest/ into godot/render/sources/ or similar.
Add a pre-export step (script or CI) that runs build_assets.gd headless and produces gen/ before the export.
Add campaign/test to the exclude filter.
Set the icon, file_version, and product_version in export_presets.cfg.
Align the export path with FEATURES.md or the build script.

7. Music and portraits plumbing
Verdict: SOUND (plumbing only, as instructed)
Music
The plumbing is complete and careful. music_player.gd implements adaptive layers (calm, intense, bed, sting), an intensity follower fed per activation, faction flavour with the enemy's colour winning, a dedicated music bus created at runtime, and a state() method for tests (pack, Per-area evidence, Music plumbing). The player skips missing files quietly by design. The content (music.json, tracks/*.ogg, CREDITS.md) is absent from main. The README lists all three as the folder's contents. FEATURES.md marks Music done. test/music_check.gd, which loads music.json and opens every track, cannot pass as written because music.json does not exist (pack, Findings list, item 8; INFERRED).

(a) BUGS
B17. Documentation-versus-tree drift: the music README and FEATURES.md describe content that does not exist. The README lists music.json, tracks/, and CREDITS.md. None exist. FEATURES.md marks Music done. The player's quiet-skip design means nothing complains at runtime (pack, Findings list, item 8). Severity: low for runtime, medium for project tracking and for the sprint brief's Job 5 (music licence check), which cannot start.

(b) REFINEMENTS
R17. Add a startup check that logs whether music content is present. The player already skips missing files. A one-line log at startup ("music: 0 of N tracks found, playing silent") would make the absence visible without changing the quiet-skip behaviour. This is the same class of fix as the ResourceLoader.exists soft-dependency pattern: the plumbing is fine, the visibility is not.
Portraits
portraits.gd is a static facade: index.json picks one painting per admiral, face() falls back to the crest SVG when no painting is picked, textures are cached in statics, and raw files load when the import is missing (fresh checkout, headless). Nemesis portraits are composed at runtime: the picked base, a baked first-scar variant when one exists, then scar overlays blended at the portrait's face anchor from scars.json placements, then a faction frame. Composition cost is paid once per (id, scar list) cache key (pack, Per-area evidence, Portraits plumbing). The crest set is complete (24 admirals).

(a) BUGS
None found in the portraits plumbing. The static cache is appropriate for a facade that loads once and holds.

(b) REFINEMENTS
R18. The static texture cache in portraits.gd has no eviction path. For 24 admirals plus a handful of Nemesis variants, this is fine. If the portrait count grows significantly (post-cutover content), the cache could hold more textures than necessary. Not a problem now. A comment noting the assumption would suffice.

(c) ALTERNATIVE APPROACHES
A11. Pre-bake Nemesis portrait compositions offline instead of composing at runtime. Trade-off: runtime composition is flexible (scar combinations are generated, not enumerated) and the cache key means each composition is computed once. Pre-baking would require enumerating all (base, scar list, faction frame) combinations, which grows combinatorially. The current approach is correct for the content model. No change recommended.

8. Other evidence from the pack
Performance shape
Verdict: SOUND WITH RISKS (INFERRED, limited evidence)
The pack notes: view() rebuilds the full unit and weapon view after every batch, and ui_info() computes expected damage for every weapon against every living enemy per call. On 20-ship boards with carriers these are cost centres with no documented budget, while the parity timing bar covers only enemy think (pack, Findings list, item 16). UNSURE: whether this is actually a problem at the game's target fleet sizes. The pack does not include frame timing data or profiling results. The bot-run hang guard (600 s default) would catch a pathological case but not a slow one.
REFINEMENT R19: Add a frame-time budget comment or a debug overlay showing view() and ui_info() costs during bot runs. This converts the INFERRED risk into a measured one. Cost: small.
Test coverage gaps
The pack lists these explicitly (pack, Tests: what is covered, what is not):
Shell startup seeding (see B3).
Export contents (no check lists what lands in the .pck).
gen/ freshness (no check compares gen/ against source art).
Hand-copied render constants versus their JS sources.
Save corruption beyond the one-generation backup (no fuzz or truncation test).
Threading overlap between threat computation and any other API caller (parity is single-threaded by construction).
These are gaps, not bugs. The coverage that exists is strong. The gaps are the edges that a small team reasonably defers.
Documentation-versus-tree drift as a class
The pack identifies this pattern in multiple places: the music README versus the empty folder (B17), the FEATURES.md DRAWN column versus the actual campaign UI files on main (pack, Architecture as documented, FEATURES.md gaps), the export path versus FEATURES.md (B16), and the fx stub's header saying it goes away when fx/API.md exists, which it does (B9). This is a class, not a set of isolated incidents. The common cause is that documentation is written at the time of implementation and not updated when the tree changes.
REFINEMENT R20: A lightweight "tree versus docs" check script that verifies: every file mentioned in a README exists, every folder mentioned in FEATURES.md's status table exists or is explicitly marked absent, and the export path matches the actual preset. Run it as part of the bot-run suite or as a pre-commit check. Cost: moderate. Value: high, because this class of drift erodes trust in the documentation, which is the migration's primary coordination tool.
Audio
sfx.gd ports sfx.js faithfully: same cue table, voice cap 34, per-cue caps with stealing, salvo thinning, gap and defer rules, same bus chain. It loads 324 audio files at _ready and prints its load time. It uses God's global randf and randi for round-robin and pitch jitter, which is safe (never touches JSM.rnd) but means audio randomness is unseeded per run (pack, Per-area evidence, Audio). INFERRED: harmless for sound. Worth a line in the determinism doc.
sfx.gd reaches the imported-file helper through the battle HUD script (const HUDRes preload of res://ui/battle/hud.gd, used for imported_ok), while music_player.gd defines its own private copy of the same check. Two implementations of one helper, owned by two areas (pack, Per-area evidence, Audio). Minor.
REFINEMENT R21: Extract the imported_ok helper into a shared utility. Cost: trivial. Do it whenever one of the two files is next touched.
Warning suppression
rules.gd line 11, jsm.gd line 13, and battle_api.gd line 6 each open @warning_ignore_start listing 17 warning classes including integer_division and narrowing_conversion, the two documented JS-port trap categories. project.godot was deliberately set to warn during the sprint; these files opt out wholesale. campaign.gd carries no suppression (grep count 0), which shows the port can live with warnings on (pack, Findings list, item 3).
REFINEMENT R22: Audit the 17 suppressed warnings in rules.gd, jsm.gd, and battle_api.gd. integer_division and narrowing_conversion are the two categories most likely to hide real port bugs. Suppress them individually at the specific lines where the JS behaviour is being deliberately reproduced, rather than blanket-suppressing the whole file. campaign.gd's zero-suppression existence proves this is feasible. Cost: moderate, tedious. Value: high, because the blanket suppression defeats the safety net that project.godot's warn setting was meant to provide.

Final ranked lists
(a) Bugs ranked by severity across all areas
B3. PRNG stream never seeded in the shipped shell. (jsm.gd line 52, campaign.gd line 942 onward, grep of main.gd/title.gd/campaign_host.gd/story.gd). Every fresh-process campaign run draws from the same fixed sequence. High severity because it affects every player's first run and no test can see it.
B1. Canonical hash SKIP sets exclude terrain state. (rules.gd SKIP_B and SKIP_U sets). A terrain-state bug passes parity silently. High severity because it defeats the primary safety mechanism.
B13. Game cannot be built from the repo alone. (gen/ zero files on main, A4 .glb off-repo, sky/asteroid sources in contrib/opus/enginetest/). High severity for any build that is not on one specific PC.
B4. Threading safety by convention only. (battle.gd lines 650-667, battle_api.gd lines 505-518, rules.gd eval_begin lines 177-181, jsm.gd lines 15 and 52). Low probability today, high consequence if the convention breaks.
B6. Non-atomic save write. (campaign.gd persist_save lines 362-375). Medium severity; the load side mitigates but does not eliminate.
B2. Unported maths edges return 0.0 silently. (jsm.gd lines 162, 225, 240, 317, 352). Medium severity; extreme inputs, silent wrong answers.
B11. Two vendored oracles with no sync step. (godot/rules/test/oracle/ and godot/campaign/test/oracle/). Medium severity; no mismatch today, no process to prevent one.
B12. Hand-copied render and world constants with no drift check. (render/hull_table.gd, world/world.gd). Medium severity; silent visual divergence.
B10. NOT PORTED degrades instead of stopping in live play. (battle.gd _think line 662, _cmd line 674). Acceptable during migration, a bug at cutover.
B8. ResourceLoader.exists can throw on parse failure instead of falling back. (campaign_host.gd, main.gd, ship_view.gd, battle.gd lines 228-229). Medium for silent degradation, low for the throw path.
B14. gen/ freshness by version constant and file existence only. (build_assets.gd _current). Medium; stale assets ship silently.
B15. Export ships campaign test oracle and harness. (export_presets.cfg line 11). Low for correctness, medium for professionalism.
B16. Export preset missing icon, versions, codesign; path disagrees with FEATURES.md. (export_presets.cfg). Medium for Steam readiness.
B9. fx_stub.gd still preloaded alongside real fx. (battle.gd line 25, lines 228-229). Low; dead weight and confusion.
B17. Music README and FEATURES.md describe absent content. (godot/music/). Low for runtime, medium for tracking.
B5. Mutex has no failure path; GDScript lacks try/finally. (battle_api.gd lines 505-518). Low probability, high confusion cost.
B7. Settings have no backup and no version field. (main.gd save_settings). Low, cosmetic.

(b) Refinements ranked by value per unit of effort
R12. Sync check for the two vendored oracles. A diff script. One hour of work. Prevents the two harnesses from certifying against different truths.
R14. Add campaign/test to the export exclude filter. One line in export_presets.cfg. Immediate.
R1. Give the maths layer the NOT PORTED stop. Five call sites in jsm.gd, small change each. Converts silent wrong answers into loud stops.
R6. Atomic save write. Ten lines in persist_save. Eliminates the torn-file path.
R22. Audit the 17 blanket-suppressed warnings in rules.gd, jsm.gd, battle_api.gd. Tedious but high-value. integer_division and narrowing_conversion are the two categories most likely to hide port bugs. campaign.gd proves zero suppression is feasible.
R9. Wrap ResourceLoader.exists + load + new in a helper. One function, small refactor, five call sites. Closes the throw-on-parse-failure path.
R7. Field-name constant table for the campaign-to-battle hand-off. Small. Converts a stringly-typed contract into a checked one.
R4. Debug assertion for concurrent API access. A few lines in battle_api.gd. Converts the threading convention violation from silent corruption to a loud error.
R2. Add terrain state to the golden hash or add a separate terrain check. Small change to golden.js and parity_main.gd. Closes the parity rig's biggest blind spot.
R13. Checksum or generate hull_table.gd and world.gd constants. Moderate. The tables.json pattern already exists as the model.
R16. Source-art hash check in build_assets.gd. Moderate. Catches the forgot-to-bump-GEN_VERSION case.
R20. Tree-versus-docs check script. Moderate. Addresses the drift class.
R10. Retire fx_stub.gd. Small, but blocked on resolving the UNSURE about which cues the stub owns.
R5. Guard the static scratch buffer in jsm.gd. A comment and a debug assertion. Small.
R11. Guard flag for the first _on_changed after bind. Two lines. Closes an INFERRED edge.
R17. Startup log line for music content presence. One line.
R19. Frame-time budget overlay for view() and ui_info() during bot runs. Small. Converts INFERRED performance risk to measured.
R21. Extract imported_ok helper into a shared utility. Trivial. Do it when one of the two files is next touched.
R3. Comment on canon/numstr confirming it is test-only. One line, if the UNSURE resolves that way.
R8. Comment explaining the two version numbers in the save envelope. One line.
R18. Comment on the portrait cache size assumption. One line.

(c) Additions before cutover (browser version frozen, Godot becomes the game)
Fix B3: seed the PRNG stream in the shipped shell. One line in main.gd or campaign_host.gd at startup, plus the decision about save-and-resume versus reseed. Without this, every player's first campaign run is identical.
Close the terrain-state blind spot in the parity hash (R2). Cutover means the parity rig is the last line of defence. A terrain bug that passes parity silently is unacceptable at that point.
Prove the NOT PORTED set is empty, or make it a hard stop (B10). The degrade-and-continue path is right for mid-migration. At cutover, every rule must be ported, and the stop must be hard.
Add campaign/test to the export exclude filter (R14). Shipping 516 KB of test JS and Node harnesses in the player's .pck is not acceptable at cutover.
Retire fx_stub.gd (R10, pending the UNSURE resolution). Two effects systems coexisting is acceptable during migration, not at cutover.
Atomic save write (R6). Players will be making real saves. The torn-file path must be closed.
Maths-layer NOT PORTED stop (R1). Same reasoning as item 3: silent wrong answers are acceptable during migration, not at cutover.

(d) Additions before Steam
Make the game buildable from the repo alone (B13). Move A4 .glb files into the repo or LFS. Move sky and asteroid sources out of contrib/opus/enginetest/. Add a pre-export step that runs build_assets.gd. Valve's build pipeline must produce the game from a checkout.
Set the export preset's icon, file_version, product_version, and codesign (B16). Steam requires these. UNSURE whether the tools/pc job scripts handle any of them; verify.
Sync step for the two vendored oracles (R12). By Steam, stream B changes will have landed multiple times. The two harnesses must certify against the same truth.
Drift check for hand-copied render and world constants (R13). By Steam, the JS side will have changed. The hand-copied constants must not silently diverge.
Export content check: a script that lists what lands in the .pck and fails on unexpected files. The campaign/test shipping is the known instance; a general check prevents the next one.
Warning suppression audit (R22). Before the codebase grows further, the blanket suppression in the three most delicate files should be narrowed to line-level suppressions for genuinely deliberate JS-parity constructs.
Tree-versus-docs check (R20). By Steam the documentation must be trustworthy for the store page, the build process, and any future contributors.
Save corruption fuzz test. The one-generation backup is good. A truncation or corruption test that verifies the load-side defence actually works would be worth having before thousands of players are making saves.
gen/ freshness: source-art hash check (R16). By Steam, artists will be editing source art. The hand-bumped version constant will not survive contact with a real art pipeline.

(e) UNSURE list
Respecting the pack's own UNSURE items and adding my own:
From the pack:
UNSURE: whether any file not read for the pack seeds the JSM stream at shell startup (the campaign UI files and main.tscn's attached scripts were not read line by line).
UNSURE: whether the JS save stored PRNG stream state (decides what continuing a run should do after the seeding fix).
UNSURE: whether node/export_data.js and export_campaign.js now include everything stream B added after the port_notes step 1 note (FAC_PRICE, FAC_GATES, cost values).
UNSURE: what happens to an in-flight worker step() when the player quits mid-battle. The quiesce order for a running worker task is not described in any doc read.
UNSURE: which battle cues the fx stub still owns versus the real fx (fx internals out of scope).
UNSURE: whether the export preset's gaps (icon, versions, codesign) are handled at PC build time by the tools/pc job scripts, which were not read.
UNSURE: whether gen/ or any build output is committed anywhere outside main (another branch or the PC only).
UNSURE: hull section counts per ship (the damage marks work assumes 4 to 8; nothing in the in-scope files states the real number).
My additions:
9. UNSURE: whether the canon/numstr canonical writer in jsm.gd ever runs on a live per-frame path or is strictly test and load-check machinery. The pack raises this and does not resolve it.
10. UNSURE: whether the 20-ship board performance shape for view() and ui_info() is actually a problem at the game's target fleet sizes. The pack infers the risk but has no frame timing data.
11. UNSURE: whether the A4 .glb files are versioned anywhere (a DCC tool's project file, a shared drive) such that they could be recovered if Ryan's Downloads folder is lost. The pack says they live only on the PC.
12. UNSURE: whether Godot 4.7's WorkerThreadPool guarantees that a task's closure has finished before the pool is destroyed at shutdown, which bears on the quit-mid-battle question (item 4 above). From my knowledge of Godot 4.x, WorkerThreadPool.wait_for_task_completion() exists and the pool does wait on outstanding tasks at shutdown, but the battle scene is freed by main.gd before that point, and the interaction between freeing the scene and a still-running task that references it is not something I can confirm from the pack.
13. UNSURE: whether the contrib/opus/enginetest/ paths used by build_assets.gd for sky and asteroid sources are stable across that contributor's working sessions, or whether they could be deleted or moved at any time.

(f) One-sentence verdict per area, plus overall
Rules port and parity: SOUND WITH RISKS. The exact-double parity rig is stronger than most shipped games have, but the terrain-state blind spot in the hash and the unseeded PRNG stream in the shipped shell are two real gaps that must be closed before cutover.
Threading and shared state: SOUND WITH RISKS. The convention holds today and is documented in the code, but it is one careless future API call away from irreproducible corruption; add the debug assertion now and revisit the design before Steam.
Campaign logic and saves: SOUND WITH RISKS. The parity coverage, save format care, and migration handling are genuinely good; the non-atomic write and the stringly-typed battle hand-off are the two items to fix.
Shell and glue: SOUND WITH RISKS. The code-built shell, the bot-run infrastructure, and the quit_clean statics teardown are solid; the soft-dependency pattern needs a parse-failure guard and the fx stub needs retiring.
Data duplication and drift: NEEDS WORK. The safe pattern (generated plus checksum) exists in the codebase for tables.json but is not applied to the vendored oracles, the render constants, or the world constants; the sync and check steps are cheap and overdue.
Asset pipeline and build: NEEDS WORK. The game cannot be built from the repo alone, gen/ freshness is a hand-bumped constant, the export preset ships test files and lacks icon and version strings; this is the area furthest from Steam-ready.
Music and portraits plumbing: SOUND. The music player and portrait composition code are complete and careful; the music content is absent and the docs say done, which is a tracking bug, not a plumbing bug.
Other (performance, test gaps, doc drift): SOUND WITH RISKS. Performance shape is inferred but unmeasured, test coverage is strong where it exists and the gaps are the edges a small team reasonably defers, and the documentation-versus-tree drift is a class that needs a systematic check.
Overall verdict: SOUND WITH RISKS, trending toward SOUND. The rules port, the parity rig, the save format, and the bot-run infrastructure are well above the bar for a small-team mid-migration project. The two items that must be fixed before cutover are the unseeded PRNG stream and the terrain-state blind spot in the parity hash. The items that must be fixed before Steam are the asset pipeline's repo-independence, the export preset's professionalism, and the data drift checks. None of these are architectural problems; they are all bounded, well-understood fixes to a codebase that is in good shape.
