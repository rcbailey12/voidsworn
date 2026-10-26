# Godot migration review, Gemini Argon leg, 2026-10-26

Chair header: filed as the single reviews copy for the Gemini leg (house pattern). Model: Gemini 4 Argon, Thinking level High, verified in two places before submitting ("Argon High" on the model-picker button and the prompt bar dropdown, with the picker showing Selected 4 Argon and Thinking level High). Ran 3:10-3:24 PM CDT (runtime measured). Seven files attached (leg prompt, evidence pack, jsm.gd, battle_api.gd, export_presets.cfg, project.godot.txt, music_README.md); file contents were not pasted as text. The response finished in one message and did not stall. Citation badges shown in the Gemini interface are interface elements, not model text, and are omitted. Model text follows verbatim.

---

Area 1: Rules Port and Parity (godot/rules/, jsm.gd)

Verdict: SOUND WITH RISKS

Pack Evidence

- Parity harness and canonical state: godot/rules/rules.gd (3,724 lines, 262 functions) ports the battle engine against the pinned Node oracle in godot/rules/test/oracle/ (battle.js, core.js, data.js, fnames.js). golden.js and parity_main.gd write canonical records with SHA-256 hashes and PRNG state at every action point across scenarios s1 to s23 (covering all 8 fight types, gravity well, carriers, 36 boons, Classic mode, and a think-time worst case) plus a 200-battle random sweep, comparing integers exactly and floats as exact 64-bit IEEE doubles with zero tolerance (Architecture as documented, Rules port and parity).
- Canonical hash SKIP sets: rules.gd excludes CUT and SOLID module state on both sides, and the golden comparison uses SKIP_B = {units, log, cfg, prog} and SKIP_U = {t, ship} (Rules port and parity).
- V8 maths port and unported edges: godot/rules/jsm.gd ports V8's fdlibm sin, cos, atan2, exp, V8 12.4 pow, scaled Kahan hypot, jsround, and stable merge sort ssort, storing fdlibm constants as exact IEEE hex words via words(h, l) because Godot parses long decimal literals up to 1 ulp off (jsm.gd:65-101, Architecture as documented). However, five unported edges call push_error(...) and return 0 or 0.0 while play continues: jsm.gd:162 (_rem_pio2 for sin/cos when ix > 0x413921fb), jsm.gd:225 (atan2 with an infinite operand), jsm.gd:240 (exp when hx >= 0x40862E42), jsm.gd:317 (pow with |y| > 2^31), and jsm.gd:352 (pow subnormal result) (JSM: maths, PRNG, canonical form, Finding 6).
- NOT PORTED handling in live play: While parity_main.gd stops on NOT PORTED, godot/scenes/battle/battle.gd in _think (around line 662) and _cmd (around line 674) records R.not_ported into the scene error list, clears the flag, and plays the partially computed batch (Battle scene glue, Finding 7).
- Shared PRNG stream and startup seeding: jsm.gd:52 defines a single process-global static var rng_s: int = 0 (mulberry32), matching core.js (JSM: maths, PRNG, canonical form). Grep across rules.gd, campaign.gd, battle_api.gd, and jsm.gd confirms zero calls to Godot's randf, randi, or RandomNumberGenerator (Rules port and parity). However, while godot/scenes/campaign/campaign_scene.gd:27 seeds JSM from the wall clock, no rnd_seed call exists in godot/main/main.gd, godot/main/title.gd, godot/main/campaign_host.gd, or godot/story/story.gd, and campaign.gd only seeds on battle paths (campaign.gd:2105, campaign.gd:2291) while rules.gd:1044 seeds inside startBattle from cfg.seed (The seeding question, Finding 1). Consequently, campaign.gd newRun (line 942 onward) draws foes, patrons, ship names, starting relic, sector 1 map generation (genSector(1)), node seeds (campaign.gd:2095), and newNemesis starting from rng_s = 0 on every fresh launch (The seeding question, Finding 1).
- Warning suppression in ported files: project.godot:22-23 sets gdscript/warnings/integer_division=1 and gdscript/warnings/narrowing_conversion=1, which are documented JS-to-GDScript porting traps (Architecture as documented). Yet rules.gd:11, jsm.gd:13, and battle_api.gd:6 open @warning_ignore_start suppressing 17 warning categories including integer_division and narrowing_conversion, whereas campaign.gd has zero warning suppressions (Finding 3).
- Visibility of bug classes to the parity rig: The parity harness catches any single-threaded battle or campaign state divergence on covered paths down to 1 ulp, plus stale data tables via SHA-256 verification in load_tables (Rules port and parity). It cannot see: (1) missing shell startup seeding, because parity and bot runs seed explicitly (The seeding question, Finding 1); (2) terrain-cache corruption in CUT and SOLID, because both are excluded from the canonical hash (Rules port and parity); (3) worker-thread data races, because parity runs single-threaded (Tests: what is covered, what is not, Finding 2); or (4) unexercised Stream B tables or unported math edges not hit by s1 to s23 or the 200-battle sweep (Gaps and UNSURE items).

What I Would Do

Seed JSM.rnd_seed(...) once in main.gd _ready() from the wall clock (matching campaign_scene.gd:27) and store a per-run seed in the campaign save or draw it cleanly on newRun, remove integer_division and narrowing_conversion from @warning_ignore_start in rules.gd:11, jsm.gd:13, and battle_api.gd:6, finish the short fdlibm edge branches in jsm.gd (atan2 infinities and exp overflow/underflow), and include a digest of CUT and SOLID in the canonical state record.

(a) BUGS (Ranked by Severity)

- Unseeded shared PRNG stream at shell startup produces identical first-run campaign content on every launch (High): jsm.gd:52 initializes static var rng_s: int = 0. Because main.gd, title.gd, and campaign_host.gd never call JSM.rnd_seed, campaign.gd newRun (campaign.gd:942) and genSector(1) (campaign.gd:2095) consume draws from rng_s = 0 on every fresh launch until player actions change the draw count (The seeding question, Finding 1). (Whether an unread UI script seeds it is tagged UNSURE in the pack.)
- Unported maths edges in jsm.gd silently return 0.0 (or 1.0 for cos) in release builds instead of halting or returning IEEE limits (Medium): At jsm.gd:162 (_rem_pio2 returning 0 leaves y = [0.0, 0.0], making sin return 0.0 and cos return 1.0), jsm.gd:225 (atan2 infinity), jsm.gd:240 (exp range hx >= 0x40862E42, which returns 0.0 even for positive overflow where JS returns INF), jsm.gd:317 (pow with |y| > 2^31), and jsm.gd:352 (pow subnormal), push_error only logs in release builds while calculation continues with wrong numbers (JSM: maths, PRNG, canonical form, Finding 6).
- Live battle play clears R.not_ported and plays corrupted partial activations (Medium): battle.gd _think (around line 662) and _cmd (around line 674) log R.not_ported, clear the flag, and animate the partial batch (Battle scene glue, Finding 7). If any unported rule path remains at cutover, the battle state silently diverges from rules intent without halting the turn.

(b) REFINEMENTS

- Re-enable integer_division and narrowing_conversion warnings in rules.gd:11, jsm.gd:13, and battle_api.gd:6: Keep the untyped dictionary and variant warnings suppressed, remove "integer_division" and "narrowing_conversion" from the @warning_ignore_start directive in those three files, and fix any flagged lines with explicit float(...) or int(...) casts (Finding 3).
- Include CUT and SOLID in canonical parity hashing: Add canonical serialization of CUT and SOLID to golden.js and parity_main.gd so terrain-destruction and line-of-sight blocker state are verified at every action point (Rules port and parity).
- Port the remaining trivial fdlibm branches in jsm.gd: In jsm.gd:240 (exp), return INF when xsb == 0 and 0.0 when xsb == 1 for hx >= 0x40862E42 (or exact thresholds o_threshold / u_threshold from fdlibm), and in jsm.gd:225 (atan2), add the 8-line fdlibm switch for infinite x or y so those paths never fail (JSM: maths, PRNG, canonical form).

(c) ALTERNATIVE APPROACHES

Explicit PRNG state object passed into rules.gd and campaign.gd vs. process-global JSM.rng_s:

Current design: One static JSM.rng_s (jsm.gd:52) shared across the process, matching core.js (JSM: maths, PRNG, canonical form).

Alternative: Give rules.gd and campaign.gd their own rng_s integer field on the instance (or pass a lightweight Rng RefCounted instance), seeding the battle instance from the campaign's node seed on battle start.

Trade-offs: Costs a mechanical search-and-replace of JSM.rnd() across rules.gd and campaign.gd and requires verifying whether campaign parity expects battle draws to advance the campaign stream (in external mode, campaign.gd:2105 seeds JSM from the node seed xor 0x5bd1e995 at battle start, which overwrites JSM.rng_s anyway). In exchange, it eliminates the entire class of cross-system RNG contamination bugs documented in port_notes.md (where decorative showcase battles reseeded the global stream and altered subsequent campaign rolls) (Architecture as documented).

Area 2: Threading and Shared State (battle.gd, battle_api.gd, rules.gd, jsm.gd)

Verdict: NEEDS WORK

Pack Evidence

- Worker thread usage in battle.gd: _think (battle.gd:650-667) dispatches a WorkerThreadPool task that runs both api.step() and api.view(); _runner (battle.gd:626 onward) waits for _threat_busy before starting enemy think; and during the player phase, threat overlay updates run api.threat_map() on a worker thread (Battle scene glue, Finding 2).
- Single partially-locked API method: battle_api.gd:556-568 (step(), noted as lines 505-518 in the pack summary and located at lines 556-568 in the attached battle_api.gd) is the only method in battle_api.gd that acquires _mutex. view() (battle_api.gd:98), ui_info() (battle_api.gd:369), threat_map() (battle_api.gd:414), reach() (battle_api.gd:136), preview_fire() (battle_api.gd:143), and all player commands are completely unlocked. Even inside _think, the worker calls api.view() after api.step() has already unlocked _mutex (Battle scene glue, battle_api.gd:556-568).
- Shared mutable eval scratch caches on R: rules.gd stores _los, _guard, _tc, _hc, _lw, and _slot on the rules instance; eval_begin() (rules.gd:177-181) sets _evc and clears all six dictionaries (Rules port and parity, Finding 2). threat_map() (battle_api.gd:422-455) runs R.eval_begin() and R.eval_end() on the worker thread over live unit dictionaries. Meanwhile, ui_info() (battle_api.gd:369-410), preview_fire() (battle_api.gd:143), and in_reach() (battle_api.gd:199) call R.los, R.hitChance, and R.expectedVs on the main thread without locking _mutex. In Godot 4, concurrent read/write access to GDScript Dictionary and Array instances across threads is not thread-safe and causes memory corruption or crashes (from memory of Godot 4 thread-safety rules).
- Process-global static byte buffer in jsm.gd: jsm.gd:15 declares static var _pb: PackedByteArray = _mk_pb() (8 bytes), which hi(), lo(), words(), hex64(), and from_hex64() mutate in place at byte offsets 0 and 4 (jsm.gd:19-35, JSM: maths, PRNG, canonical form, Finding 2). Because JSM.sin, cos, atan2, exp, and pow call hi(), lo(), and words() continuously, any worker thread running threat_map() or step() that overlaps any main-thread call into JSM (such as UI fire previews or save encoding) races on those 8 bytes and corrupts float bit-casts.
- Reference leaks from view(): battle_api.gd:104 and battle_api.gd:117 return each unit's "shMax", B["arena"], and _hexes by direct reference instead of copying (Battle scene glue, Finding 13).
- Mutex failure path and mid-battle quit: step() (battle_api.gd:556-568) has no failure recovery if a runtime error aborts execution while _mutex is locked (Battle scene glue, Finding 15). Furthermore, what happens to an in-flight WorkerThreadPool task when the player quits mid-battle (main.gd frees the battle scene immediately after start_battle returns) is undocumented (Gaps and UNSURE items). Per Godot 4.7 WorkerThreadPool documentation (docs.godotengine.org/en/stable/classes/class_workerthreadpool.html), wait_for_task_completion(task_id) must be called to synchronize and clean up a task before freeing objects it touches.

What I Would Do

Harden this now, before cutover, rather than leaving it to scene-flag convention. Specifically: (1) eliminate the shared mutable static var _pb in jsm.gd:15 (or allocate a local 8-byte PackedByteArray per call / use GDScript's built-in type_convert / bytes_to_var / local buffer), (2) acquire _mutex across every public entry point in battle_api.gd (including view(), threat_map(), ui_info(), reach(), preview_fire(), and all commands) or snapshot R before worker tasks, and (3) ensure battle.gd calls WorkerThreadPool.wait_for_task_completion(task_id) in _exit_tree() before freeing the scene.

(a) BUGS (Ranked by Severity)

- Unlocked worker threat_map() and view() share mutable R caches and JSM._pb with the main thread (High): During the player phase, threat_map() runs on a worker thread and mutates R._los, R._guard, R._tc, R._hc, R._lw, and R._slot via R.eval_begin() (rules.gd:177-181, battle_api.gd:422) and JSM._pb (jsm.gd:15-35) while the main thread can call ui_info(), preview_fire(), reach(), or in_reach() on hover or click (Battle scene glue, Finding 2). During enemy think, _think (battle.gd:650-667) calls api.view() on the worker outside _mutex (battle_api.gd:556-568).
- battle_api.gd view() leaks live references to B["arena"], u["shMax"], and _hexes (Low-Medium): battle_api.gd:104 ("shMax": u["shMax"]) and battle_api.gd:117 ("arena": B["arena"], "hexes": _hexes) return mutable rules structures by reference despite the line 97 contract "Safe to keep; never changes behind your back" (Battle scene glue, Finding 13).

(b) REFINEMENTS

- Replace static var _pb in jsm.gd:15 with a local PackedByteArray or thread-safe helper: In jsm.gd:19-35, creating a local 8-byte PackedByteArray inside hi(), lo(), words(), hex64(), and from_hex64() removes the process-wide data race in 10 lines of code.
- Lock _mutex across all battle_api.gd entry points and wrap _think in a single locked API call: Add a combined step_and_view() -> Dictionary method on battle_api.gd that holds _mutex across both step() and view(), and take _mutex in threat_map(), ui_info(), reach(), preview_fire(), and command methods (battle_api.gd:98-568, Finding 2). If the main thread calls ui_info() while threat_map() holds _mutex, or better yet, if threat_map() only runs when requested and the main thread checks _mutex.try_lock() for hover previews, the UI will neither freeze nor race.
- Duplicate shMax and arena in view(): Change battle_api.gd:104 to "shMax": u["shMax"].duplicate() if u["shMax"] is Array else u["shMax"] and battle_api.gd:117 to "arena": B["arena"].duplicate(true) if B.get("arena") is Dictionary else B.get("arena") (Finding 13).
- Drain worker tasks on scene exit: In battle.gd _exit_tree(), if a _think or _threat task ID is active, call WorkerThreadPool.wait_for_task_completion(task_id) before battle.gd and its api reference are torn down (Gaps and UNSURE items, class_workerthreadpool.html).

(c) ALTERNATIVE APPROACHES

Cloned read-only state for threat_map() worker vs. mutex-locking battle_api.gd:

Current design: Worker thread runs api.threat_map() directly on the live R instance (battle_api.gd:414-456), relying on battle.gd's _threat_busy flag to avoid overlapping _think (Battle scene glue).

Alternative: Have threat_map() operate on a lightweight clone of R (or give threat_map() its own local eval cache dictionary passed into los/inArc instead of mutating R._los via R.eval_begin()).

Trade-offs: Passing a local cache dictionary or cloning unit positions costs a small refactoring in rules.gd (eval_begin / _los lookup) and a few kilobytes of dictionary copy per threat calculation. What it buys is that main-thread UI queries (ui_info, preview_fire, reach) never contend on _mutex or stall a frame waiting for a background threat overlay to finish, and a background threat task can never corrupt live battle state.

Area 3: Campaign Logic and Saves (godot/campaign/)

Verdict: SOUND WITH RISKS

Pack Evidence

- Page/acts contract and parity: godot/campaign/campaign.gd (2,353 lines, 244 functions) encapsulates campaign rules and screen flow in one RefCounted object (Inventory summary, Architecture as documented). Every JS show() or modal() becomes {kind, data, acts} with acts ordered as [act, arg, enabled], and campaign.act(name, arg) is the sole state-mutating entry point (Architecture as documented). Parity is verified across 30 seeded full runs with canonical state comparisons after every click, including periodic save, load, and reload cycles (Architecture as documented, Tests: what is covered, what is not).
- Stringly-typed battle hand-off: In external battle mode, campaign_host.gd runs the battle via main.play_api(api, opts) and passes the rules state B into campaign.finish_battle(result, B), where campaign.gd reads B.usage, unit ev fields, the nemFlag unit, and wing kills via parent directly by JS field names (Architecture as documented, Campaign logic and saves).
- Save format care and migrations: campaign.gd:70 verifies campaign_tables.json via SHA-256 on load (Rules port and parity). SAVE_VERSION is 2 for meta (campaign.gd:188) inside envelope {"format": "voidsworn-godot-campaign", "v": 1} (campaign.gd:361), with migrateMeta and migrateRun showing a player-facing toast when legacy items are removed on continue (campaign.gd:1105). _enc (campaign.gd:348-359) encodes every non-integer float as "#d:" plus exact 64-bit IEEE hex (JSM.hex64) so Godot's JSON parser cannot drift by 1 ulp, and load_save_text (campaign.gd:378-393) runs saneSave and saneRun, falls back to .bak, and preserves whichever half (meta or run) is valid (Campaign logic and saves).
- Non-atomic save write and settings write: persist_save (campaign.gd:362-375) checks if save_path exists, parses, and differs, copies it to save_path + ".bak", and then opens save_path directly with FileAccess.WRITE in place (Campaign logic and saves, Finding 11). main.gd save_settings writes user://settings.json directly in place with no .bak and no version field, merging keys on load so renamed keys persist forever (Campaign logic and saves, Finding 11).

What I Would Do

Make persist_save (campaign.gd:362-375) and save_settings (main.gd) atomic by writing to save_path + ".tmp", flushing/closing the file, and renaming over save_path via DirAccess.rename_absolute(...), and add a small schema assertion helper at the top of campaign.finish_battle(result, B) that validates the required keys on B and B["units"].

(a) BUGS (Ranked by Severity)

- Non-atomic in-place overwrite in persist_save (campaign.gd:362-375) and save_settings (main.gd) risks a torn primary file on crash or power loss (Low-Medium): Opening save_path directly with FileAccess.WRITE truncates the target file before writing the new JSON string (Campaign logic and saves, Finding 11). If the process terminates mid-write, save_path is left truncated; while load_save_text (campaign.gd:378-393) recovers the previous turn from .bak, the newest save point is lost, and user://settings.json has no backup at all.

(b) REFINEMENTS

- Atomic write-temp-then-rename for saves and settings: In campaign.gd:362-375 (persist_save) and main.gd (save_settings), write the serialized payload to save_path + ".tmp", call file.flush() and file.close(), copy the existing valid save_path to save_path + ".bak", and call DirAccess.rename_absolute(save_path + ".tmp", save_path) (per Godot 4.7 DirAccess documentation at docs.godotengine.org/en/stable/classes/class_diraccess.html).
- Boundary assertion in finish_battle(result, B): At the entry to campaign.gd finish_battle, assert or check that B is a Dictionary containing "units" (Array) and "usage" (Dictionary), and that each unit entry has "id", "side", and "dead", logging via push_error if any expected key is missing so a future rules.gd field rename fails loudly (Campaign logic and saves).
- Filter unknown keys when loading user://settings.json: In main.gd, only copy keys from the parsed JSON that exist in the default settings dictionary, and write a "v": 1 key on save (Campaign logic and saves).

(c) ALTERNATIVE APPROACHES

Typed BattleSummary DTO vs. passing raw R.B into campaign.finish_battle(result, B):

Current design: campaign_host.gd passes the live R.B dictionary directly into campaign.finish_battle(result, B), matching the JS boundary (Architecture as documented, Campaign logic and saves).

Alternative: Have battle_api.gd expose a outcome_summary() -> Dictionary method that extracts only the exact post-battle fields campaign.gd consumes (usage, unit survival/damage/ev, nemFlag state, wing kills), and have finish_battle consume that summary.

Trade-offs: Costs writing and maintaining an explicit extraction function in battle_api.gd and updating campaign.gd finish_battle (plus the campaign parity harness if it calls finish_battle with raw JS B shapes). Because the 30-run campaign parity harness currently tests finish_battle against the JS oracle's exact B layout (Architecture as documented), changing finish_battle's input shape would break direct JS oracle parity unless mirrored in JS. Keeping raw B with a schema check in finish_battle is cheaper and preserves parity.

Area 4: Shell and Glue (godot/main/, godot/scenes/)

Verdict: SOUND WITH RISKS

Pack Evidence

- ResourceLoader.exists soft-dependency pattern: Used across campaign_host.gd (res://ui/campaign/campaign_ui.gd vs. godot/main/campaign_fallback_ui.gd, plus the story hook in start), main.gd _ready (music player), ship_view.gd _look (render/look.gd), and battle.gd:228-229 (G4 fx) (Main shell and campaign host, Finding 12). If a file is absent from an export .pck, the game silently degrades (for example, shipping the debug facts-and-buttons fallback UI instead of the real campaign UI with zero errors logged). Conversely, if the file exists on disk or in .pck (ResourceLoader.exists returns true, per docs.godotengine.org/en/stable/classes/class_resourceloader.html) but fails to parse or compile, load(...).new() will throw on null instead of falling back (Main shell and campaign host, Finding 12).
- Coexisting fx_stub.gd and real godot/fx/: battle.gd:25 still preloads res://scenes/battle/fx_stub.gd (whose header states it should be removed once godot/fx/API.md exists), while battle.gd:228-229 also loads the real godot/fx/ system alongside it, and main.gd quit_clean still clears statics on both fx_stub and fx (Main shell and campaign host, Battle scene glue, Finding 14).
- Error counting, hang diagnostics, and softlock handling: main.gd registers an ErrCount Logger class to capture engine and script errors during --bot-runs N, runs a 600s hang guard timer that dumps page, modal, battle phase, round, and idle time before exiting with code 2, and converts battle "softlock" results to "loss" in campaign_host.gd (Architecture as documented, Main shell and campaign host).
- Quit and statics cleanup: main.gd quit_clean frees the battle and campaign scenes, awaits two frames, and calls clear_static on ship_view, fx_stub, and any of fx, world, look, campaign_ui, and portraits that expose it, preventing Windows exit crashes caused by static resources outliving RenderingServer (Main shell and campaign host).
- Title return edge in campaign_host.gd: _on_changed emits run_over whenever the campaign page is "title" with no modal up; start() calls titleScreen, immediately executes an act that moves off "title", and then binds the UI and calls _on_changed (Main shell and campaign host).

What I Would Do

Replace the ResourceLoader.exists soft-dependency checks on core shipped systems (campaign_ui.gd, story.gd, look.gd, fx, music_player.gd) with hard preload(...) or a startup self-check that fails loudly if a required module is missing (keeping campaign_fallback_ui.gd behind an explicit --fallback-ui CLI flag), audit and retire fx_stub.gd (battle.gd:25), and make quit_clean wait for any active WorkerThreadPool tasks before freeing nodes and clearing statics.

(a) BUGS (Ranked by Severity)

- Leftover fx_stub.gd preloaded and running alongside real godot/fx/ (battle.gd:25, battle.gd:228-229) (Low-Medium): fx_stub.gd's own removal condition (godot/fx/API.md existing) has been met, yet both systems are loaded in battle.gd and cleaned up in main.gd quit_clean (Battle scene glue, Finding 14). (Which cues each system currently fires is UNSURE, but running two effects layers risks double visuals, wasted nodes, or masked missing effects in the real fx module.)
- ResourceLoader.exists + load(path).new() crashes on parse failure and silently ships fallback UI on packaging omission (campaign_host.gd, main.gd, ship_view.gd, battle.gd:228-229) (Low-Medium): Checking ResourceLoader.exists(path) before calling load(path).new() does not guard against load(path) returning null on a broken script or resource, and silently masks missing files in exported builds (Main shell and campaign host, Finding 12).

(b) REFINEMENTS

- Convert soft dependencies to preload() or explicit CLI fallbacks: Now that ui/campaign/campaign_ui.gd, story/story.gd, render/look.gd, fx/, and music/music_player.gd all exist in godot/ on main (Inventory summary, FEATURES.md gaps), load them unconditionally and only use campaign_fallback_ui.gd when --fallback-ui is passed on the command line. If a helper stays dynamic, check var scr = load(path); if scr != null: ... instead of assuming ResourceLoader.exists(path) guarantees a non-null load(path) (Finding 12).
- Guard campaign_host.gd _on_changed with a _started flag: Set a boolean _entered_run := true only after the campaign has left the "title" page at least once, so binding the UI while still on "title" cannot prematurely emit run_over (Main shell and campaign host).
- Retire scenes/battle/fx_stub.gd: Verify all cues handled by fx_stub.gd are implemented in godot/fx/, remove preload("res://scenes/battle/fx_stub.gd") from battle.gd:25 and main.gd quit_clean, and delete fx_stub.gd (Battle scene glue, Finding 14).

(c) ALTERNATIVE APPROACHES

Registry array for static cleanup vs. ad-hoc list in main.gd quit_clean:

Current design: main.gd quit_clean manually lists ship_view, fx_stub, fx, world, look, campaign_ui, and portraits and calls clear_static on each (Main shell and campaign host).

Alternative: Have any class that allocates static Resource or RID caches register its cleanup Callable into a small StaticClean.register(fn) array on first allocation, and have quit_clean iterate that array in reverse order.

Trade-offs: Costs a 15-line helper script and 1 line per caching module. It prevents new static caches (such as a future UI or shader cache) from being forgotten in main.gd and reintroducing the Windows exit crash (Main shell and campaign host).

Area 5: Data Duplication and Drift

Verdict: NEEDS WORK

Pack Evidence

- Two vendored JS oracles with no sync step: Both godot/rules/test/oracle/ and godot/campaign/test/oracle/ vendor copies of battle.js (162,826 bytes), core.js (37,509 bytes), and data.js (80,349 bytes) (Inventory summary, Export and project settings, Finding 5). Today their byte sizes match, but neither godot/rules/test/README.md nor godot/campaign/ READMEs document a sync step, so a Stream B update applied to one oracle folder can leave rules parity and campaign parity testing against different JS sources (Finding 5).
- Checksum-locked generated tables vs. unchecked hand-copied render/world constants: node/export_data.js generates godot/rules/data/tables.json (91,423 bytes) and export_campaign.js generates godot/campaign/data/campaign_tables.json (120,064 bytes), both verified by SHA-256 in load_tables (Inventory summary, Architecture as documented, Rules port and parity). Whether export_data.js and export_campaign.js picked up FAC_PRICE, FAC_GATES, and the new cost values noted in port_notes.md Step 1 is UNSURE (Architecture as documented, Gaps and UNSURE items). Meanwhile, godot/render/hull_table.gd hand-copies AI_HULLS, CLS_LEN, FAC3D, FINISH, ROCK_SET, and ROCK_TINT from ships3d.js, and godot/world/world.gd hand-copies BIOMES, ROCKS, and PLANETS from scene3d.js and battle.js with zero generation or checksum verification (Render and the asset pipeline, Finding 10).
- Duplicate imported_ok helper: godot/audio/sfx.gd preloads res://ui/battle/hud.gd (const HUDRes) solely to call its imported_ok helper, while godot/music/music_player.gd defines its own private copy of the same check (Audio).

What I Would Do

Unify the two vendored JS oracle directories so godot/campaign/test/oracle/ reads shared battle.js, core.js, and data.js directly from godot/rules/test/oracle/ (or check their SHA-256 equality at the top of both Node test scripts), extend node/export_data.js to emit FAC3D, AI_HULLS, CLS_LEN, FINISH, ROCK_SET, ROCK_TINT, BIOMES, ROCKS, and PLANETS into a generated godot/render/data/render_tables.json (or include them in tables.json), and verify that FAC_PRICE, FAC_GATES, and Step 1 cost values are exported in export_campaign.js / export_data.js. Hand-copying is fine for one-off shader parameters or Godot-specific camera/light tuning that has no JS counterpart (render/look.gd), because the browser version is frozen for visual changes (The game and the task).

(a) BUGS (Ranked by Severity)

- Dual vendored JS copies of battle.js, core.js, and data.js in godot/rules/test/oracle/ and godot/campaign/test/oracle/ have no sync check (Medium): While identical today (battle.js 162,826 bytes, core.js 37,509 bytes, data.js 80,349 bytes), nothing prevents a Stream B balance patch from updating only one directory and invalidating cross-stream parity guarantees (Export and project settings, Finding 5).

(b) REFINEMENTS

- Single oracle source of truth for shared JS files: Have godot/campaign/test/ load battle.js, core.js, and data.js from ../../rules/test/oracle/, keeping only the campaign-specific oracle files (ui3d.js, campaign_run.js, campaign_meta.js, campaign3d.js) in godot/campaign/test/oracle/ (Export and project settings, Finding 5). If both folders must keep physical copies, add a 5-line byte-hash comparison at the start of golden.js and the campaign Node harness that exits non-zero on mismatch.
- Generate faction colours, hull mappings, and biome tables from JS: Because FAC3D in ships3d.js is the documented single source of truth for faction colours and battle.js / scene3d.js own BIOMES, ROCKS, and PLANETS, export those constants via a small Node script (or inside node/export_data.js) into JSON rather than maintaining hand-copied tables in render/hull_table.gd and world/world.gd (Render and the asset pipeline, Finding 10).
- Move imported_ok out of ui/battle/hud.gd: Place imported_ok in a small shared utility (or on main.gd / a res://main/res_util.gd helper) so audio/sfx.gd does not preload the battle HUD (res://ui/battle/hud.gd) and music/music_player.gd does not duplicate it (Audio).

(c) ALTERNATIVE APPROACHES

Retiring the JS oracle after cutover vs. keeping the dual-language Node exporter pipeline:

Current design: Balance and Stream B rule changes land in the JS oracle first, node/export_data.js / export_campaign.js regenerate the JSON tables, and GDScript ports the logic (Architecture as documented).

Alternative: Once the browser version is frozen and cutover to Godot is complete, make godot/rules/data/tables.json, godot/campaign/data/campaign_tables.json, rules.gd, and campaign.gd the primary source of truth, and freeze the Node parity harness as a historical regression snapshot.

Trade-offs: Before cutover, keeping JS-first parity is essential because Stream B tuning is still landing in JS (The game and the task, Architecture as documented). After cutover, however, making every balance or rule tweak in both JS and GDScript doubles engineering effort and keeps the two-oracle drift risk alive. Making cutover the hard line where GDScript becomes authoritative saves half of all future gameplay programming work, at the cost of no longer backporting post-cutover features to the frozen browser version.

Area 6: Asset Pipeline and Build (godot/render/build_assets.gd, godot/assets/, export_presets.cfg, project.godot)

Verdict: NEEDS WORK

Pack Evidence

- Missing godot/gen/ and off-repo assets: godot/gen/ (which holds the runtime hull meshes, 8K flagship scenes, rocks, sky, and manifest.json) has 0 files on main (Inventory summary, Render and the asset pipeline, Finding 9). The A4 kit .glb ship files (~10 MB each) live off-repo on Ryan's PC at Downloads\voidsworn_test\build\godot\assets\ships\ while godot/assets/ships/ on main holds only a README.md (Inventory summary, Render and the asset pipeline, Finding 9). Additionally, build_assets.gd (_build_sky and the asteroids.json copy) falls back to source paths inside contrib/opus/enginetest/, another contributor's scratch directory (Render and the asset pipeline, Finding 9).
- Version-only freshness and silent BoxMesh fallback: tools/pc/play_godot.bat triggers render/build_assets.gd when gen/v<N>.txt (N = GEN_VERSION) is missing, and _current in build_assets.gd checks only GEN_VERSION and output file existence (Render and the asset pipeline, Finding 9). Editing source art without incrementing GEN_VERSION or passing --force silently uses stale generated assets. At runtime, ship_view.gd falls back silently from A4 kit scene -> 8K hi scene -> standard hull mesh -> plain BoxMesh, so a build exported without running build_assets.gd (or with missing ship sources) succeeds with zero errors and renders box ships (Render and the asset pipeline, Finding 9).
- Export preset leaks 516 KB of test oracle files and lacks metadata: godot/export_presets.cfg:11 sets exclude_filter="rules/test/*, audio/build/*" with export_filter="all_resources" and include_filter="*.json". Consequently, godot/campaign/test/ (around 516 KB of JS oracle files: battle.js, ui3d.js, campaign_run.js, data.js, core.js, campaign_meta.js, campaign3d.js, plus Node scripts and parity_campaign.gd), godot/music/test/, and README.md files ship inside the exported .pck (Export and project settings, Finding 4). Furthermore, export_presets.cfg:12 sets export_path="../export/Voidsworn.exe", which disagrees with FEATURES.md's build\export\Voidsworn.exe, while application/icon, application/file_version, application/product_version, application/company_name, and application/copyright (export_presets.cfg:31-38) are all empty (Export and project settings, Finding 4).
- Steam build readiness and smallest reproducible change set: The build is not ready for Steam today because a clean checkout of main cannot produce a playable ship-mesh build without off-repo files from Downloads\voidsworn_test\... and scratch files in contrib/opus/enginetest/, and an export can silently package BoxMesh ships plus 516 KB of test harnesses.
- Smallest set of changes to make the build reproducible from the repo alone:
  - Move the sky and asteroids.json source files out of contrib/opus/enginetest/ into a tracked godot/assets/ subfolder and update build_assets.gd (Render and the asset pipeline).
  - Track the A4 ship .glb files (via Git LFS if repo size is the reason they are in Downloads\) under godot/assets/ships/, or commit the built godot/gen/ artifacts via Git LFS (Render and the asset pipeline).
  - Compute a source-input hash (file paths + sizes/SHA-256 of source hulls, sky, and rocks) in build_assets.gd _current instead of relying only on GEN_VERSION (Render and the asset pipeline).
  - Add a pre-export verification step (or flag in build_assets.gd --check) that asserts res://gen/manifest.json and every required hull mesh exist, failing the build instead of allowing ship_view.gd to fall back to BoxMesh in release exports (Render and the asset pipeline).
  - Update export_presets.cfg:11 exclude_filter to "rules/test/*, campaign/test/*, music/test/*, */test/*, audio/build/*, *.md" (Export and project settings).

(a) BUGS (Ranked by Severity)

- Clean repo checkout cannot build the shippable game (godot/gen/ absent, A4 ships off-repo, sky/asteroids in contrib/opus/enginetest/) (High): godot/gen/ has zero files on main, A4 .glb hulls live only on a local PC path (Downloads\voidsworn_test\build\godot\assets\ships\), and build_assets.gd reads sky and asteroid data from contrib/opus/enginetest/ (Inventory summary, Render and the asset pipeline, Finding 9).
- export_presets.cfg:11 packages godot/campaign/test/* (~516 KB of JS oracle and Node harnesses) and music/test/* into the shipped .pck (Medium): exclude_filter="rules/test/*, audio/build/*" omits campaign/test/* and music/test/* (Export and project settings, Finding 4).
- build_assets.gd _current ignores source art modifications unless GEN_VERSION is manually bumped (Medium): Checking only gen/v<N>.txt and output file existence means updated .glb or sky inputs are silently skipped during incremental PC builds (Render and the asset pipeline, Finding 9).
- export_presets.cfg:12 export_path="../export/Voidsworn.exe" disagrees with FEATURES.md (build\export\Voidsworn.exe), and metadata fields (export_presets.cfg:31-38) are blank (Low): application/icon, file_version, and product_version are "" (Export and project settings, Finding 4). (Whether tools/pc scripts override the export path or metadata on the CLI is UNSURE.)

(b) REFINEMENTS

- Expand exclude_filter in export_presets.cfg:11: Change line 11 to exclude_filter="rules/test/*, campaign/test/*, music/test/*, */test/*, audio/build/*, *.md".
- Hash input file mtimes/sizes in build_assets.gd _current: Write a SHA-256 of (GEN_VERSION + source file paths + file sizes + modified timestamps) into gen/manifest.json so any source art change triggers an automatic rebuild without manual GEN_VERSION bumps (Render and the asset pipeline).
- Gate BoxMesh fallback in ship_view.gd on OS.is_debug_build() or push an error: Keep the BoxMesh fallback so a missing mesh does not crash a dev scene, but call push_error("Missing ship mesh for " + ...) whenever ship_view.gd reaches the BoxMesh tier so --bot-runs (ErrCount Logger) catches missing assets automatically (Main shell and campaign host, Render and the asset pipeline).

(c) ALTERNATIVE APPROACHES

Committing source .glb files via Git LFS + CI/scripted build_assets.gd vs. committing built godot/gen/ resources:

Current design: Raw A4 .glb files live in an untracked local PC folder, godot/gen/ is untracked, and tools/pc/play_godot.bat runs build_assets.gd locally (Render and the asset pipeline).

Alternative A (Track sources in Git LFS, generate gen/ on build): Put the A4 .glb sources in godot/assets/ships/ under Git LFS, promote the contrib/opus/enginetest/ sky/asteroid inputs into godot/assets/env/, and run build_assets.gd as part of the build script.

Alternative B (Commit godot/gen/ in Git LFS): Commit the generated godot/gen/ tree directly so any developer or CI runner can open or export the project immediately without running the headless asset builder first.

Trade-offs: Alternative B makes headless bot tests and exports work immediately after git clone with zero asset-build step, but causes binary churn in Git LFS every time build_assets.gd changes material or mesh settings. Alternative A keeps the repo clean of derived artifacts and avoids binary merge conflicts, at the cost of requiring a mandatory godot --headless --script res://render/build_assets.gd step before running or exporting. Given the small team size and headless workflow, Alternative A plus a mandatory check in the export script is cleaner.

Area 7: Music and Portraits Plumbing (godot/music/, godot/portraits/)

Verdict: SOUND WITH RISKS

Pack Evidence

- Music player plumbing vs. missing content: godot/music/ on main contains only README.md, music_player.gd, and test/music_check.gd (17,336 bytes total across 3 files) (Inventory summary, Music plumbing, Finding 8). music_player.gd is complete: it creates a dedicated music bus sending to Master, runs calm, intense, and faction bed layers with a 2s rise / 4s fall intensity follower (hand-over 0.38 to 0.62), selects enemy faction flavour over player faction flavour, exposes state() for testing, and quietly skips missing track files (Music plumbing, music_README.md). However, music.json, tracks/*.ogg, and CREDITS.md do not exist on main, even though godot/music/README.md lists them as the folder's contents and FEATURES.md marks Music done (Music plumbing, Finding 8). Because music.json is missing, godot/music/test/music_check.gd cannot pass as written (Music plumbing).
- Portraits facade and runtime Nemesis composition: godot/portraits/ (41 files, 1,121,480 bytes) provides a static facade in portraits.gd (Inventory summary, Portraits plumbing). index.json selects painted portraits per admiral with face() falling back to the 24 admiral crest SVGs (Portraits plumbing). portraits.gd loads raw files when editor .import files are absent (enabling fresh headless checkouts) and caches textures in statics (Portraits plumbing). nemesis() composes Nemesis portraits at runtime from a base portrait, a baked first-scar variant when available, scar overlays blended at the face anchor from nemesis/scars/scars.json, and a faction frame, caching the result by (id, scar list) (Portraits plumbing). main.gd quit_clean calls clear_static on portraits on exit (Main shell and campaign host).

What I Would Do

The code plumbing in both music_player.gd and portraits.gd is well-built. To stop the missing music content from breaking music_check.gd or misleading the status tracker: commit a minimal stub godot/music/music.json (with empty track maps {}) and an empty godot/music/CREDITS.md template until the actual .ogg tracks land, update FEATURES.md so Music is marked PLUMBING ONLY / NO TRACKS instead of done, and bound or clear the (id, scar list) static cache in portraits.gd when starting a new campaign run.

(a) BUGS (Ranked by Severity)

- godot/music/test/music_check.gd is broken on main and FEATURES.md falsely reports Music as done because music.json, tracks/*.ogg, and CREDITS.md are missing (Medium): While music_player.gd gracefully degrades to silence when music.json is absent, test/music_check.gd requires music.json and the track files, and FEATURES.md and godot/music/README.md describe files that are not in the tree (Music plumbing, Finding 8). (No bugs were found in the GDScript logic of music_player.gd or portraits.gd themselves.)

(b) REFINEMENTS

- Commit a valid empty godot/music/music.json and CREDITS.md skeleton: Having music.json present with valid schema keys (title, map, battle, stings, factions) lets music_check.gd validate the schema and player initialization even before tracks are selected (Music plumbing, music_README.md).
- Guard duplicate music bus creation in music_player.gd: Ensure music_player.gd checks AudioServer.get_bus_index("music") == -1 before calling AudioServer.add_bus() so instantiating music_player.gd more than once in tests never creates duplicate buses (Music plumbing, music_README.md).
- Clear Nemesis composite cache on campaign exit: In portraits.gd, while quit_clean clears all static textures on application exit (Main shell and campaign host), clearing the runtime-composed (id, scar list) Nemesis ImageTexture cache when returning to title prevents unbounded growth across many consecutive runs in a single session (Portraits plumbing).

(c) ALTERNATIVE APPROACHES

GPU shader / CanvasItem layering for Nemesis scars vs. CPU Image blending cached by (id, scar list):

Current design: portraits.gd nemesis() blends the base painting, scar overlays at scars.json anchor coordinates, and the faction frame on the CPU into a single cached texture per (id, scar list) (Portraits plumbing).

Alternative: Render the base portrait, scar TextureRect children positioned at the anchor offsets, and the frame as stacked UI nodes or a multi-sampler canvas shader.

Trade-offs: Stacking UI nodes avoids CPU image blitting on first view of a new scar combination, but complicates every caller that wants a single Texture2D from portraits.nemesis(...) (such as battle cut-ins, map pins, or modals). Because a single campaign run only mutates one Nemesis through a handful of scars and caches each (id, scar list) result once (Portraits plumbing), the current CPU composition facade is simpler for callers and well-suited to the game's scale.

Area 8: Performance Shape, Test Coverage Gaps, and Documentation-vs-Tree Drift

Verdict: SOUND WITH RISKS

Pack Evidence

- Performance shape in battle_api.gd (view() and ui_info()): view() (battle_api.gd:98-118) allocates and rebuilds dictionaries for every unit, weapon, shield array, section dict, torpedo, and objective zone after every batch (Performance shape, Finding 16). ui_info(id) (battle_api.gd:369-410) computes hdist, expectedVs, canFire, inArc, los, hitChance, and dmgMult for every weapon on ship id against every living enemy on every call (battle_api.gd:401-408, Finding 16). Furthermore, unlike attack_plan (battle_api.gd:290), threat_map (battle_api.gd:422), and _ai_activate (battle_api.gd:510), ui_info(id) (battle_api.gd:369-410) does not call R.eval_begin() and R.eval_end(), so R.los(u, t) is recomputed from scratch for every weapon on the ship against the same enemy instead of reusing R._los. On 20-ship carrier boards, these have no documented frame-time budget while the parity timing bar covers only enemy think (Performance shape, Finding 16).
- Audio startup load: godot/audio/sfx.gd loads 324 audio files synchronously in _ready and prints its load time (Audio).
- Test coverage gaps: No tests currently cover: (1) shell startup PRNG seeding (The seeding question, Tests: what is covered, what is not); (2) .pck export contents or excluded paths (Tests: what is covered, what is not, Finding 4); (3) godot/gen/ freshness against source art (Tests: what is covered, what is not, Finding 9); (4) drift between hand-copied render/world tables (hull_table.gd, world.gd) and JS (Tests: what is covered, what is not, Finding 10); (5) save file truncation or fuzzing (Tests: what is covered, what is not, Finding 11); or (6) concurrent worker-thread threat_map() / step() overlapping main-thread API calls (Tests: what is covered, what is not, Finding 2).
- Documentation-versus-tree drift as a recurring class:
  - FEATURES.md marks Music done and godot/music/README.md lists music.json, tracks/*.ogg, and CREDITS.md as existing files, when none of the three are in godot/music/ (Music plumbing, Finding 8).
  - FEATURES.md lists the DRAWN column as fallback for every campaign screen even though godot/ui/campaign/campaign_ui.gd (79,133 bytes) and map3d.gd are on main (Inventory summary, FEATURES.md gaps).
  - FEATURES.md states the Windows executable is built at build\export\Voidsworn.exe, whereas export_presets.cfg:12 writes to ../export/Voidsworn.exe (Export and project settings, Finding 4).
  - scenes/battle/fx_stub.gd's header comment states it goes away once godot/fx/API.md exists, but both exist on main (Battle scene glue, Finding 14).
  - godot/rules/API.md documents determinism for rules and scene cosmetic randomness, but omits sfx.gd's use of global randf/randi (Audio).

What I Would Do

Wrap the weapon-vs-foe loop in battle_api.gd:401-409 (ui_info) in R.eval_begin() / R.eval_end() (once _mutex is held), add a lightweight check_tree.gd script to the headless test suite that validates doc-claimed files, oracle hash parity, export_presets.cfg exclusions, and save truncation recovery, and add per-call timing telemetry for view() and ui_info() on 20-ship carrier boards.

(a) BUGS (Ranked by Severity)

- Systemic documentation-versus-tree drift across FEATURES.md, godot/music/README.md, export_presets.cfg:12, and fx_stub.gd misleads build and audit gating (Low-Medium): Status checklists (FEATURES.md) both overstate completion (Music marked done with zero tracks) and understate completion (campaign screens marked fallback when campaign_ui.gd is 79 KB on main), while file paths (build\export\Voidsworn.exe vs. ../export/Voidsworn.exe) disagree (FEATURES.md gaps, Music plumbing, Export and project settings, Findings 4, 8, 14).

(b) REFINEMENTS

- Bracket ui_info()'s weapon loop in R.eval_begin() and R.eval_end() (battle_api.gd:400-410): A ship with 6 weapons facing 15 enemies currently calls R.los(u, t) 90 times without caching; wrapping lines 400-410 in R.eval_begin() / R.eval_end() (under _mutex) reduces line-of-sight raycasts to 15 (battle_api.gd:400-410, Finding 16).
- Add a 50-line headless repository hygiene test (test/repo_check.gd or Node script): Check that (1) godot/rules/test/oracle/{battle,core,data}.js and godot/campaign/test/oracle/{battle,core,data}.js have identical SHA-256 hashes, (2) export_presets.cfg excludes all */test/* folders, (3) load_save_text recovers cleanly when the primary save file is truncated to 10 bytes alongside a valid .bak, and (4) JSM.rng_u32() is non-zero after booting main.tscn (Tests: what is covered, what is not).

(c) ALTERNATIVE APPROACHES

Generated feature/status report from test probes vs. hand-edited FEATURES.md table:

Current design: godot/main/FEATURES.md is updated by hand and has drifted behind G3 UI and ahead of Music (FEATURES.md gaps, Finding 8).

Alternative: Have a small script generate the status table in FEATURES.md by inspecting the tree (e.g. checking whether ui/campaign/campaign_ui.gd, music/music.json, assets/ships/*.glb, and gen/manifest.json exist and whether parity/bot tests pass), leaving only a short manual checklist for qualitative items.

Trade-offs: Costs about 40 lines of Node or GDScript, and prevents contributors from treating FEATURES.md as freeform prose. In return, the migration tracker can never claim Music is done when music.json is missing or claim Campaign UI is on fallback when campaign_ui.gd is wired (FEATURES.md gaps, Finding 8).

Closing Summary Lists

(a) All Bugs Ranked by Severity Across All Areas

- [High | Area 1] Shared PRNG stream JSM.rng_s is never seeded in the shipped shell (jsm.gd:52, main.gd, title.gd, campaign_host.gd, campaign.gd:942, 2095): Starts at rng_s = 0 on every launch, producing identical first-run foes, patrons, captain names, starting relic, sector map, node seeds, and Nemesis on every install (The seeding question, Finding 1).
- [High | Area 2] Worker-thread threat_map() and view() race with the main thread on unlocked R eval caches and process-global JSM._pb (battle.gd:650-667, battle_api.gd:98, 369, 414, 556-568, rules.gd:177-181, jsm.gd:15-35): step() is the only method locking _mutex; worker threat_map() clears and mutates R._los/_guard/_tc/_hc/_lw/_slot and writes into the 8-byte JSM._pb buffer while main-thread UI queries (ui_info, preview_fire, reach) can run concurrently (Rules port and parity, JSM: maths, PRNG, canonical form, Battle scene glue, Finding 2).
- [High | Area 6] Shippable game cannot be built from the repo alone (godot/gen/, godot/assets/ships/README.md, render/build_assets.gd): godot/gen/ is empty on main, A4 .glb ship meshes live off-repo in Downloads\voidsworn_test\build\godot\assets\ships\, and sky/asteroid assets fall back to contrib/opus/enginetest/, while ship_view.gd silently falls back to BoxMesh (Inventory summary, Render and the asset pipeline, Finding 9).
- [Medium | Area 1] Unported maths edges in jsm.gd (jsm.gd:162, 225, 240, 317, 352) return 0.0 (or 1.0 for cos) and continue playing: push_error only logs in release builds while returning wrong numeric values (JSM: maths, PRNG, canonical form, Finding 6).
- [Medium | Area 1] Live play clears R.not_ported and plays partially computed batches (battle.gd:662, 674): Hides unported rule hits from the player instead of stopping or surfacing a visible failure (Battle scene glue, Finding 7).
- [Medium | Area 6] export_presets.cfg:11 packages godot/campaign/test/* (~516 KB of JS oracle and Node harnesses) and music/test/* into .pck: exclude_filter only excludes rules/test/* and audio/build/* (Export and project settings, Finding 4).
- [Medium | Area 5] Dual vendored JS oracles (godot/rules/test/oracle/ and godot/campaign/test/oracle/) have no sync check: Both pin battle.js, core.js, and data.js separately with no automated check preventing Stream B divergence (Export and project settings, Finding 5).
- [Medium | Area 6] build_assets.gd _current checks only GEN_VERSION and file existence: Source art edits without bumping GEN_VERSION or passing --force silently ship stale meshes (Render and the asset pipeline, Finding 9).
- [Medium | Area 7] godot/music/ has no music.json, tracks/*.ogg, or CREDITS.md, breaking music/test/music_check.gd while FEATURES.md marks Music done: Code plumbing in music_player.gd works, but content files listed in music/README.md are absent (Music plumbing, Finding 8).
- [Low-Medium | Area 3] Non-atomic in-place save overwrite in persist_save (campaign.gd:362-375) and save_settings (main.gd): Truncates the live save file before writing, risking loss of the latest save step on a mid-write crash (Campaign logic and saves, Finding 11).
- [Low-Medium | Area 4] ResourceLoader.exists soft-dependency checks (campaign_host.gd, main.gd, ship_view.gd, battle.gd:228-229): Silently ship fallback UI if a file is omitted from .pck and crash on .new() if a present script fails to parse (Main shell and campaign host, Finding 12).
- [Low-Medium | Area 4] Leftover fx_stub.gd preloaded and running beside real godot/fx/ (battle.gd:25, 228-229): Transition stub has not been retired despite godot/fx/API.md existing (Battle scene glue, Finding 14).
- [Low-Medium | Area 2] battle_api.gd view() returns B["arena"], u["shMax"], and _hexes by reference (battle_api.gd:104, 117): Violates view()'s read-only copy contract (Battle scene glue, Finding 13).
- [Low | Area 6 & Area 8] export_presets.cfg:12 path (../export/Voidsworn.exe) disagrees with FEATURES.md (build\export\Voidsworn.exe), preset metadata fields (export_presets.cfg:31-38) are empty, and FEATURES.md DRAWN status is stale: Documentation and preset configuration drift (FEATURES.md gaps, Export and project settings, Finding 4).

(b) All Refinements Ranked by Value per Unit of Effort

- Seed JSM.rnd_seed at shell startup in main.gd _ready() (1 line of code; fixes deterministic first-run bug; Area 1, Finding 1).
- Update exclude_filter in export_presets.cfg:11 to "rules/test/*, campaign/test/*, music/test/*, */test/*, audio/build/*, *.md" (1 line of config; strips >516 KB of test JS/GDScript from .pck; Area 6, Finding 4).
- Remove static var _pb in jsm.gd:15-35 in favor of a local 8-byte PackedByteArray per call (10 lines in jsm.gd; eliminates process-wide float bit-cast data race across threads; Area 2, Finding 2).
- Remove "integer_division" and "narrowing_conversion" from @warning_ignore_start in rules.gd:11, jsm.gd:13, and battle_api.gd:6 (3 lines changed plus casts where flagged; restores compiler protection against top JS porting traps; Area 1, Finding 3).
- Wrap ui_info() weapon loop (battle_api.gd:400-410) in R.eval_begin() and R.eval_end() (2 lines in battle_api.gd; cuts repeated line-of-sight checks per weapon on 20-ship boards; Area 8, Finding 16).
- Lock _mutex across view(), threat_map(), ui_info(), reach(), preview_fire(), and commands in battle_api.gd, and drain worker tasks via WorkerThreadPool.wait_for_task_completion on scene exit (~25 lines; eliminates race conditions between worker tasks and main thread; Area 2, Finding 2).
- Duplicate u["shMax"] and B["arena"] in battle_api.gd:104, 117 (2 lines; closes mutable reference leak from view(); Area 2, Finding 13).
- Make persist_save (campaign.gd:362-375) and save_settings (main.gd) atomic via .tmp write + DirAccess.rename_absolute (~15 lines; prevents torn save/settings files on crash; Area 3, Finding 11).
- Point godot/campaign/test/ at godot/rules/test/oracle/ (or assert SHA-256 equality of battle.js, core.js, data.js in test runners) (~10 lines; prevents split-brain JS oracles; Area 5, Finding 5).
- Port the atan2 infinity and exp overflow/underflow branches in jsm.gd:225, 240 (~15 lines; eliminates silent 0.0 returns on valid IEEE float extremes; Area 1, Finding 6).
- Include CUT and SOLID in golden.js and parity_main.gd canonical state hashes (~15 lines; closes the terrain-destruction parity blind spot; Area 1).
- Retire scenes/battle/fx_stub.gd (battle.gd:25, main.gd) and convert core ResourceLoader.exists checks to hard loads (~20 lines; removes dead effects layer and silent fallback UI packaging risk; Area 4, Findings 12, 14).
- Hash source art mtimes/sizes in build_assets.gd _current and export JS presentation tables (FAC3D, AI_HULLS, BIOMES) via node/export_data.js (~50 lines; prevents stale meshes and render constant drift; Area 5 & Area 6, Findings 9, 10).

(c) Additions Before Cutover (and Why Before That Gate)

- Startup PRNG seeding in main.gd (JSM.rnd_seed): Belongs before cutover because cutover makes the Godot build the primary playable game; without it, every tester and player gets the exact same first campaign run (The seeding question, Finding 1).
- Thread synchronization in battle_api.gd (_mutex on all entry points), local _pb in jsm.gd:15, and worker task drain on battle exit: Belongs before cutover because once active development and playtesting move to Godot, rare worker-thread memory corruption in R._los or JSM._pb will cause irreproducible heisenbugs during play (Battle scene glue, Finding 2).
- Self-contained repo asset inputs (moving sky/asteroids out of contrib/opus/enginetest/, tracking A4 .glb ships or godot/gen/, and source-hash freshness in build_assets.gd): Belongs before cutover because cutover freezes the browser version (The game and the task); the primary game must be buildable from main without relying on one developer's Downloads\ folder or another agent's scratch directory (Render and the asset pipeline, Finding 9).
- Proving R.not_ported is unreachable and turning any hit in battle.gd:662, 674 plus jsm.gd math edges into hard test/debug stops: Belongs before cutover because cutover certifies that the GDScript port has completely replaced the JS engine (Battle scene glue, Findings 6, 7).
- Oracle sync verification (rules/test/oracle vs campaign/test/oracle), CUT/SOLID parity hashing, and verifying Step 1 port_notes.md exports (FAC_PRICE, FAC_GATES, cost values): Belongs before cutover because parity against the JS oracle is the exit gate for the migration itself (Architecture as documented, Finding 5).
- Retiring fx_stub.gd (battle.gd:25) and replacing ResourceLoader.exists on campaign_ui.gd with a required load: Belongs before cutover so cutover smoke tests verify the real G3 UI and G4 FX rather than transitional fallbacks (Main shell and campaign host, Battle scene glue, Findings 12, 14).

(d) Additions Before Steam (and Why Before That Gate)

- Atomic save and settings writes (.tmp + DirAccess.rename_absolute) plus save truncation/corruption test: Belongs before Steam because external players losing campaign progress or settings to a power loss or crash triggers immediate negative reviews, whereas internal pre-cutover testing can tolerate the existing .bak fallback (Campaign logic and saves, Finding 11).
- Export preset hardening (export_presets.cfg exclusions for campaign/test/* and music/test/*, application icon, file_version, product_version, company_name, code signing, and automated .pck manifest check asserting no BoxMesh ship fallback): Belongs before Steam because shipping test harnesses, missing executable metadata/icons, or accidentally packaging box meshes directly affects commercial store distribution (Export and project settings, Findings 4, 9).
- Music tracks (tracks/*.ogg), music.json, CREDITS.md, and passing music/test/music_check.gd (plus Job 5 licence verification): Belongs before Steam because the game can be playtested internally without music, but cannot ship commercially on Steam either silent or with unverified CC BY attribution (Music plumbing, Finding 8).
- Completing the FEATURES.md player-facing gaps (functional graphics quality setting, temporal AA toggle, legend/command strip help, 10th onboarding tip, and battle cut-ins/showcase battles): Belongs before Steam because commercial PC players expect working graphics settings and complete onboarding, whereas internal cutover only requires rules, campaign, and core UI stability (FEATURES.md gaps).
- 20-ship carrier board frame-time budgeting for view() and ui_info(): Belongs before Steam to guarantee smooth frame pacing on mid-range PC hardware during late-sector carrier fights (Performance shape, Finding 16).

(e) UNSURE List (Pack's UNSUREs Respected Plus Reviewer Additions)

- UNSURE (from pack): Whether any unread script outside the grep scope (godot/ui/campaign/* or scripts attached inside main.tscn) calls JSM.rnd_seed at startup (The seeding question, Gaps and UNSURE items).
- UNSURE (from pack): Whether the original JS save format persisted PRNG stream state (rng_s), which determines whether continuing a saved run should restore rng_s or seed fresh (Findings list #1, Gaps and UNSURE items).
- UNSURE (from pack): Whether node/export_data.js and export_campaign.js now export all Step 1 additions from port_notes.md (FAC_PRICE, FAC_GATES, and updated cost values) (Architecture as documented, Gaps and UNSURE items).
- UNSURE (from pack): How battle.gd and main.gd quiesce an in-flight WorkerThreadPool task (_think or threat_map) when the player quits mid-battle (Gaps and UNSURE items).
- UNSURE (from pack): Which specific battle cues scenes/battle/fx_stub.gd still fires versus the real godot/fx/ module (Battle scene glue, Gaps and UNSURE items).
- UNSURE (from pack): Whether tools/pc build scripts supply the missing export_presets.cfg fields (icon, version strings, codesign, export path) via command-line flags (Gaps and UNSURE items).
- UNSURE (from pack): Whether godot/gen/ or the A4 ship .glb files are committed on another branch outside main (Gaps and UNSURE items).
- UNSURE (from pack): The exact hull section count per ship (4 to 8 assumed by damage marks work, not stated in in-scope files) (Gaps and UNSURE items).
- UNSURE (added): Whether JSM.canon or JSM.numstr (jsm.gd:391-467, which loops up to 17 decimal precisions per float) is ever called during live gameplay outside load_tables startup verification and parity tests (JSM: maths, PRNG, canonical form).
- UNSURE (added): Whether battle.gd calls api.ui_info() or api.preview_fire() on the main thread while _threat_busy is true (if it does, the race on R._los and JSM._pb in battle_api.gd:369-456 is active today during every player turn).
- UNSURE (added): Whether rules.gd ever invokes step() recursively or triggers a GDScript runtime error inside R.aiUnit(u) that can return early in non-debug builds while _mutex is held (battle_api.gd:556-568, Finding 15).

(f) One-Sentence Verdicts

- Area 1 (Rules port and parity): SOUND WITH RISKS - The exact-double parity harness, fdlibm port, and SHA-256 table locks are remarkably rigorous, but need shell startup PRNG seeding, CUT/SOLID hash coverage, compiler warning restoration for integer_division/narrowing_conversion, and proper handling of the five unported jsm.gd math edges.
- Area 2 (Threading and shared state): NEEDS WORK - Running threat_map() and view() on worker threads without locking _mutex, while sharing R's mutable eval caches and JSM._pb's single 8-byte static buffer with the main thread, creates a real data race that single-threaded parity cannot catch.
- Area 3 (Campaign logic and saves): SOUND WITH RISKS - The single-entry act() architecture, 30-run click-by-click parity, and IEEE-hex save encoding with half-save recovery are strong, needing only atomic .tmp-plus-rename file writes and a light schema check on finish_battle.
- Area 4 (Shell and glue): SOUND WITH RISKS - Error-counting bot runs, hang diagnostics, and two-frame static cleanup are well engineered, but fx_stub.gd needs to be retired and ResourceLoader.exists soft dependencies on core UI/FX modules should become hard loads so broken or omitted files cannot degrade silently.
- Area 5 (Data duplication and drift): NEEDS WORK - Checksum-locked JSON tables in rules and campaign prove the right pattern is already in the repo, so the two vendored JS oracles should be unified and the hand-copied JS constants in hull_table.gd and world.gd should be generated.
- Area 6 (Asset pipeline and build): NEEDS WORK - A clean checkout of main cannot currently build the shippable game because godot/gen/ is absent, A4 ships live in a local Downloads\ folder, sky/asteroid inputs sit in contrib/opus/enginetest/, build_assets.gd ignores source edits without a manual version bump, and export_presets.cfg packages 516 KB of campaign test files.
- Area 7 (Music and portraits plumbing): SOUND WITH RISKS - Both music_player.gd and portraits.gd are cleanly architected and headless-safe, and only need a stub music.json (or actual tracks) committed so music_check.gd and FEATURES.md match reality.
- Area 8 (Performance shape, test gaps, and doc drift): SOUND WITH RISKS - Wrapping ui_info() in eval_begin()/eval_end() and adding a small automated repo-hygiene check will close the main performance and documentation-versus-tree drift gaps before cutover.

Overall Migration Verdict: SOUND WITH RISKS - The core rules and campaign ports have unusually strong deterministic parity foundations, and fixing the three high-severity items (startup PRNG seeding, worker-thread synchronization over R and JSM._pb, and self-contained repo asset building) will make the project ready for cutover.
