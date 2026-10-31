# Red team audit, engineer persona: Argon leg

Chair header: Argon (Gemini, Argon High) leg for the Oct 30, 2026 red team audit, run from the engineer evidence pack and the persona leg prompt. Text below is the model report verbatim, with em dashes normalized to ASCII where they appeared.

Finding 1: Process-Wide Unsynchronized Scratch Buffer and Unlocked Worker Caches (Overturning the "SOUND WITH RISKS" Rules Parity Verdict for Live Play)

What breaks or underperforms:

OBSERVED: The Oct 26 migration synthesis renders an overall verdict of "SOUND WITH RISKS" and claims "The hard part of the migration is done well: exact-double rules parity against a pinned oracle".

OBSERVED: However, inside the Godot rules engine, "step() is the only locked method in battle_api.gd; threat_map() runs eval_begin() on a worker thread" and "clears the six shared eval caches over live units".

OBSERVED: At the bitwise float conversion layer, "jsm.gd:15 keeps one static 8-byte scratch buffer behind every float-word conversion in the process", and the audit notes that "Single-threaded parity cannot see any of this."

INFERRED: This overturns the prior claim that exact-double rules parity is sound for the playable Godot build. Because every float-word conversion in the process mutates a single unsynchronized 8-byte static buffer in jsm.gd:15 and threat_map() wipes shared evaluation caches from a worker thread without acquiring the step() lock, any concurrent main-thread call (view(), ui_info(), or IEEE-hex save serialization) will race at the byte and cache level.

The evidence:

"jsm.gd:15 keeps one static 8-byte scratch buffer behind every float-word conversion in the process."

"threat_map() runs eval_begin() on a worker thread and clears the six shared eval caches over live units"

"Single-threaded parity cannot see any of this."

What it costs the game: Torn 8-byte float-word conversions and mid-evaluation cache wipes during live battles will silently corrupt combat math, targeting previews, and IEEE-hex save floats in ways that single-threaded golden tests can never reproduce or bisect after cutover.

Finding 2: Cutover Save-Loss Blocker Confirmed, But the Importer Lacks a Browser-to-Desktop Transport and Writes Non-Atomically (Confirming and Attacking the Saves Blocker Verdict)

What breaks or underperforms:

OBSERVED: The claims register states "saves BLOCKER without the importer (fixtures now built and filed)", and the Oct 26 migration review rates Campaign logic and saves as "SOUND WITH RISKS".

OBSERVED: The blocker itself is confirmed by the pack's evidence: in the browser build, "Persist.saveLocal() writes JSON.stringify({meta:META, run:SAVED_RUN}) to localStorage key voidsworn.v1", whereas "The Godot campaign writes a fresh format at user://voidsworn_campaign.json" and "its code states browser saves are not carried over (campaign.gd, the persistence section header)."

OBSERVED: However, the filed fixtures only test in-memory transformation: importer_fixtures/README.md instructs to "Point the importer at a fixture's store object as its localStorage input" and defers an edge case to "where fixture 3's decision says otherwise" (whose details are omitted from the pack). In addition, the Godot save layer has a "non-atomic write (copy to .bak, then overwrite in place)."

INFERRED: Filing JSON fixtures does not solve how a standalone desktop Godot executable reading user:// will extract voidsworn.v1 out of a player's sandboxed browser localStorage (whether via the cloud mirror at data/users/<uid>/save, an explicit file export/import UI, or Chromium LevelDB parsing). Even once imported, overwriting user://voidsworn_campaign.json in place rather than via atomic temp-file rename exposes multi-run save files to truncation on crash.

The evidence:

"Persist.saveLocal() writes JSON.stringify({meta:META, run:SAVED_RUN}) to localStorage key voidsworn.v1"

"its code states browser saves are not carried over (campaign.gd, the persistence section header)."

"Point the importer at a fixture's store object as its localStorage input"

"The one clear defect is the non-atomic write (copy to .bak, then overwrite in place)."

What it costs the game: Because an 80 percent loss rate is intended and each generation inherits what the last learned, failing to ship an end-to-end transport from browser localStorage to user:// (or losing the imported file to a non-atomic overwrite) wipes players' generational progression, unlocked admirals, and active fleet runs at cutover.

Finding 3: Multiple Player-Visible Silent Fallbacks and Unported Combat Batches Refute the "Only One Item Is Player-Visible" Verdict (Overturning Migration Visibility Claim)

What breaks or underperforms:

OBSERVED: The Oct 26 migration synthesis claims in its opening verdict that "Three items are high severity, and only one of them (the unseeded campaign stream) is player-visible today."

OBSERVED: Within the same document's area breakdowns, four other defects are directly player-visible: "NOT PORTED clears and plays a partially computed batch in live battles", "ResourceLoader.exists soft dependencies can ship the facts-and-buttons fallback campaign UI with no error anywhere", "fx_stub.gd still runs beside the real fx", and "ship_view.gd falls back silently to a plain BoxMesh".

INFERRED: The headline claim that only the unseeded campaign RNG stream is player-visible is overturned by the migration review's own evidence. Dropping unported combat rule batches mid-battle, rendering space ships as plain BoxMesh primitives, running stub effects alongside real effects, and silently degrading to a fallback campaign UI all directly break the player experience while masking failures from automated tests.

The evidence:

"only one of them (the unseeded campaign stream) is player-visible today."

"NOT PORTED clears and plays a partially computed batch in live battles."

"ResourceLoader.exists soft dependencies can ship the facts-and-buttons fallback campaign UI with no error anywhere"

"ship_view.gd falls back silently to a plain BoxMesh."

What it costs the game: A player or packaged build hitting a missing asset path or an unported combat rule branch experiences truncated battle actions, grey-box space ships, duplicate stub effects, or a debug UI without a single hard error surfacing in QA logs.

Finding 4: Suppressed GDScript Integer-Division and Narrowing Warnings After Abandoning the C# Rules Plan (Attacking Port Execution vs Port Plan)

What breaks or underperforms:

OBSERVED: In engine_port_plan_synthesis.md, both legs chose "C#, with a GDScript fallback if the spike rejects C#" for the four rules files because "C# gives explicit 64-bit ints and compile-time type checks".

OBSERVED: The actual Godot implementation in godot/rules/ used GDScript (rules.gd, jsm.gd, battle_api.gd), and "rules.gd:11, jsm.gd:13 and battle_api.gd:6 each open @warning_ignore_start listing 17 classes".

OBSERVED: Those file-wide suppressions silence the exact 6 warning classes enabled in project.godot, and "two of them (integer_division, narrowing_conversion) are the documented JS-port trap categories", alongside "the five silent maths edges" in the rules port.

INFERRED: Falling back from C# to GDScript removed compile-time static typing, and placing @warning_ignore_start across the core rules files disabled the exact compiler diagnostics (integer_division and narrowing_conversion) needed to catch JavaScript Number (double-precision float) expressions silently truncating to 64-bit integers in GDScript.

The evidence:

"C#, with a GDScript fallback if the spike rejects C#"

"the suppression silences exactly the classes the project deliberately left on"

"two of them (integer_division, narrowing_conversion) are the documented JS-port trap categories."

What it costs the game: Any combat edge case not hit by the 23 golden scenarios or any future balance patch to rules.gd can silently truncate fractional damage, range, or hull math to integers without warning.

Finding 5: Unsubstantiated Claims Register Verdicts and the Paradox of Golden-Testing Against a Frozen Oracle With 40 Failing Regression Tests

What breaks or underperforms:

OBSERVED: The claims register asserts "desktop performance two named fixes, findings-to-tests 8 PASS / 40 FAIL at the pin", "third silent weapon deletion found Oct 30 (b_razor_s drops bioplasma undisclosed)", and "Godot 3D brief: Forward+ decisively, red-teamed twice (DeepSeek BRIEF HAS HOLES, Qwen objections chair-rejected), amended once."

OBSERVED: In the attached evidence pack, the entire body of desktop_performance_audit_2026_10_29.md between Scope and Not checked is omitted as "[...]", and zero source excerpts are provided for the 8 PASS / 40 FAIL regression ledger, data.js (b_razor_s), or the Godot 3D brief.

OBSERVED: Meanwhile, the pack states "the shipped build is a Babylon.js browser game (frozen to break fixes only since Oct 26, 2026)" and "Node sim3d.js stays as the balance oracle with golden-file tests."

INFERRED: First, under the audit rule that confirming a prior verdict requires citing the supporting evidence in the pack, the "two named fixes", the "b_razor_s" deletion, and the "Forward+ decisively" 3D brief verdict cannot be confirmed from this pack because their evidence was stripped. Second, if 40 out of 48 regression tests against unfixed defects fail at the pin while the browser oracle is frozen to break fixes only, enforcing exact SHA-256 parity against the unfixed Node oracle forces the Godot port to preserve 40 known bugs as "correct" parity behavior.

The evidence:

"findings-to-tests 8 PASS / 40 FAIL at the pin (failures are correct regression tests against unfixed defects)"

"third silent weapon deletion found Oct 30 (b_razor_s drops bioplasma undisclosed)."

"the shipped build is a Babylon.js browser game (frozen to break fixes only since Oct 26, 2026)."

What it costs the game: Treating a bug-frozen browser build with 40 failing regression tests as an immutable golden oracle locks known combat, economy, and weapon data defects directly into the Godot codebase, while the omitted desktop performance and Forward+ 3D claims remain unverified.

Finding 6: Vendored Oracle Pin Drift (c7b1a78 vs 264f441d), Missing sim3d.js Port, and Unverified Terrain Hash Coverage (Attacking Parity Completeness)

What breaks or underperforms:

OBSERVED: Both vendored oracle directories (godot/rules/test/oracle/ and godot/campaign/test/oracle/) "pin commit c7b1a78 and both document a manual "Catching up" re-copy step", whereas the audit pack is built at "pin 264f441d state" (and head b3a3b802), and "nothing automatically checks that the two vendored copies (battle.js, core.js, data.js in godot/rules/test/oracle/ and godot/campaign/test/oracle/) match each other".

OBSERVED: Furthermore, whether "the canonical hash excludes CUT and SOLID module state, so a terrain-state bug could pass parity silently" remains an unresolved "DOCUMENT DIVERGENCE, carried as UNSURE" because "The golden writer (golden.js, parity_main.gd) was not fetched by any input".

OBSERVED: Finally, engine_port_plan_synthesis.md ruled that "the Godot game gets its own sim, golden-tested against the oracle" and "A Godot build that only replays Node sim output is not a port", yet the godot/ directory listing shows no ported sim3d.js equivalent outside test folders.

INFERRED: The Godot parity suite is pinned to an older commit (c7b1a78) than the audited browser code (264f441d), can silently diverge between its two manually copied oracle folders, lacks a verified port of sim3d.js in the runtime tree, and may be completely blind to board cut-out (CUT) and sight-blocking (SOLID) hex state mutations.

The evidence:

"both pin commit c7b1a78 and both document a manual "Catching up" re-copy step."

"so a one-sided manual re-pin would drift silently."

"the canonical hash excludes CUT and SOLID module state, so a terrain-state bug could pass parity silently."

"A Godot build that only replays Node sim output is not a port."

What it costs the game: Break fixes landed between c7b1a78 and 264f441d are bypassed by parity tests, battle and campaign rules can test against different JS snapshots, and line-of-sight or terrain destruction bugs can pass every golden test undetected.

Finding 7: Prior Verdict on Missing Music Files Is Overturned by the Oct 30 Repo Listing, Leaving Off-Repo Space Ship and Sky Assets as the True Build Blocker

What breaks or underperforms:

OBSERVED: The Oct 26 migration synthesis claims: "But godot/music/ holds only README.md, music_player.gd and its test: music.json, tracks/*.ogg and CREDITS.md do not exist" and states "godot/gen/ has zero files on main".

OBSERVED: In the Oct 30 directory listing of ~/workspace/voidsworn-fresh/godot/music, CREDITS.md, music.json, and tracks are all present (~/workspace/voidsworn-fresh/godot/music/CREDITS.md, ~/workspace/voidsworn-fresh/godot/music/music.json, ~/workspace/voidsworn-fresh/godot/music/tracks), while godot/gen does not exist at all and ~/workspace/voidsworn-fresh/godot/assets/ships is present instead.

OBSERVED: Meanwhile, godot_migration_review.md notes that "the A4 ship sources live off-repo on the build PC, sky and asteroid inputs fall back to contrib/opus/enginetest/", and engine_port_plan_synthesis.md notes that the audio "licence question stays OPEN".

INFERRED: The Oct 26 claim that music.json, tracks, and CREDITS.md do not exist is overturned by the Oct 30 repository tree. However, build reproducibility on a clean machine remains broken because space ship source meshes live off-repo on the build PC, environment assets depend on contrib/opus/enginetest/, and audio licensing remains unresolved.

The evidence:

"music.json, tracks/*.ogg and CREDITS.md do not exist, music_check.gd cannot pass as written"

"~/workspace/voidsworn-fresh/godot/music/CREDITS.md"

"~/workspace/voidsworn-fresh/godot/music/music.json"

"the A4 ship sources live off-repo on the build PC, sky and asteroid inputs fall back to contrib/opus/enginetest/"

What it costs the game: Relying on the stale Oct 26 music finding wastes engineering cycles on files that already exist, while a clean git checkout still cannot build the shippable game with real space ship meshes and verified audio licenses.

Finding 8: Telemetry Is Unbuilt in Godot, Ring-Capped at 600 Events in Browser Saves, and Has a Cross-Run Join Flaw for Inherited Weaknesses

What breaks or underperforms:

OBSERVED: Three settled designer rulings (Q-A regroup tension, Q-B Nemesis snowball, Q-C generational payoff) explicitly require playtest telemetry: "three designer rulings end with "revisit with actual play data," and play data does not exist unless the build logs it on purpose."

OBSERVED: telemetry_spec_2026_10_29.md is only a "Chair proposal for Opus to verify and implement", and no telemetry script exists in the godot/ directory tree. In the browser build, telemetry is stored inside META as "tel (last 600 events, campaign3d.js:16)" while "Volume is trivial (a run is hundreds of lines)".

OBSERVED: For auditing Nemesis adaptation clashes (Q4/Q-B), the telemetry spec states: "The clash audit joins this event to the same run's earlier weakness_revealed events", whereas the standing design constraints state "each generation inherits what the last learned" and "Loss to the Nemesis still teaches a weakness."

INFERRED: First, the browser's 600-event ring buffer in META.tel overwrites itself every 1 to 3 runs, making it impossible to measure Q-C across 15 runs ("a first tree pick around run 5 and a capstone around run 14 to 15") until the standalone JSONL logger is actually built in Godot. Second, the spec's clash audit join is flawed: joining nemesis_adaptation only to the same run's earlier weakness_revealed rows will miss weaknesses learned in a prior generation's loss debrief and inherited across runs.

The evidence:

"Chair proposal for Opus to verify and implement."

"tel (last 600 events, campaign3d.js:16)"

"Volume is trivial (a run is hundreds of lines)"

"The clash audit joins this event to the same run's earlier weakness_revealed events"

What it costs the game: Playtesting the Godot build before implementing the JSONL logger loses the data required to validate Q-A, Q-B, and Q-C, and implementing the nemesis_adaptation join as written will produce false negatives on inherited Nemesis weaknesses.

Finding 9: Uncached O(WxE) Line-of-Sight Sweeps in ui_info() and Full-State Rebuilds in view() Under Phased Activation at 20+ Space Ships

What breaks or underperforms:

OBSERVED: godot_migration_review.md rates Performance shape, test gaps, documentation drift as "SOUND WITH RISKS", noting that "view() rebuilds the full view per call and ui_info() computes per weapon against every living enemy" without using the "eval_begin/eval_end caching its sibling methods use", resulting in "90 LOS calls where 15 would do, on a 6-weapon ship facing 15 enemies".

OBSERVED: The standing rulings mandate that "Phased activation is the ruled battle UI direction" and "20 ships is a typical-battle target, not a cap" (plus launched wings).

INFERRED: Under phased activation in battles with 20 or more space ships and launched wings, players cycle through multiple friendly units and target previews per phase; rebuilding the entire view dictionary on every view() call and multiplying redundant line-of-sight checks per weapon in ui_info() creates avoidable main-thread frame hitches and increases the window for cache collisions with worker threads (Finding 1).

The evidence:

"view() rebuilds the full view per call and ui_info() computes per weapon against every living enemy"

"90 LOS calls where 15 would do, on a 6-weapon ship facing 15 enemies"

"20 ships is a typical-battle target, not a cap."

What it costs the game: Main-thread UI stutter during unit selection and weapon targeting previews in 20+ space ship fleet engagements.

Finding 10: Undetected Drift in Hand-Copied Render/World Constants and Unverified .pck Export Contents

What breaks or underperforms:

OBSERVED: While generated gameplay tables are checksum-locked, "the hand-copied render and world constants (FAC3D, AI_HULLS, CLS_LEN, FINISH, BIOMES, ROCKS, PLANETS)" and the manually synced oracle files "have no comparison at all."

OBSERVED: Furthermore, "No test covers shell startup seeding, export contents, gen/ freshness, hand-copied constants, save truncation, or threading overlap".

INFERRED: Without an automated diff check on the hand-copied constants and an automated inspection of the packaged .pck, the desktop export can silently ship with test/oracle bloat, omit dynamically loaded campaign scenes (triggering the silent fallback in Finding 3), or drift on space ship hull lengths (CLS_LEN), AI hull mappings (AI_HULLS), and faction visuals (FAC3D).

The evidence:

"the hand-copied render and world constants (FAC3D, AI_HULLS, CLS_LEN, FINISH, BIOMES, ROCKS, PLANETS)"

"have no comparison at all."

"No test covers shell startup seeding, export contents, gen/ freshness, hand-copied constants, save truncation, or threading overlap."

What it costs the game: Silent visual, hull-scale, or packaging regressions in the standalone desktop .pck build that pass every headless unit test.

Verdict

MIGRATION NOT CUTOVER-READY (BLOCKERS IN CONCURRENCY, SAVE TRANSPORT, AND SILENT FALLBACKS): The single most important attack is that the prior "SOUND WITH RISKS" migration verdict relies on single-threaded parity tests while jsm.gd:15 shares one unsynchronized 8-byte static buffer across every float-word conversion in the process and threat_map() wipes shared evaluation caches on an unlocked worker thread, guaranteeing race-condition corruption in live multi-threaded battles.

Not checked

Actual JS and GDScript source files: None of the raw source files (battle.js, core.js, data.js, rules.gd, jsm.gd, battle_api.gd, campaign.gd, golden.js, parity_main.gd) were included in engineer_pack.txt, so line-level implementations could only be judged through the included audit syntheses and directory listing.

Truncated and omitted claims-register evidence: The findings body of desktop_performance_audit_2026_10_29.md (cut as [...]), the findings-to-tests ledger (8 PASS / 40 FAIL), the b_razor_s bioplasma deletion in data.js, the Godot desktop 3D brief (Forward+), and contrib/opus/enginetest/RESULTS.md were not present in the pack.

Truncated directory tree and fixture details: The ~/workspace/voidsworn-fresh/godot/ directory listing was cut at pack budget after godot/rules, hiding godot/scenes/, godot/story/, and godot/rules/test/, and the specific fixture list (including Fixture 3's decision) was cut from importer_fixtures/README.md.

Runtime frame times, cloud sync, and Steamworks packaging: No live execution, hardware profiling (PERFCAP), cloud save conflict testing (Persist.connect), or .pck export verification was performed.
