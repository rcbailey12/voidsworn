# Red team audit, producer persona: Argon leg

Chair header: Argon (Gemini, Argon High) leg for the Oct 30, 2026 red team audit, run from the producer evidence pack and the persona leg prompt. Text below is the model report verbatim, with em dashes normalized to ASCII where they appeared.

Findings
1. Review and synthesis volume is starving defect resolution and the Godot critical path

What breaks or underperforms: The multi-model review apparatus is generating heavy documentation and synthesis churn while 83 percent of the regression test suite fails against known code defects and the Godot migration has not yet reached a playable run.

Evidence: OBSERVED: The program accumulated "Ten Oct 29 syntheses, plus the Oct 27 and Oct 28 programs, are on file" alongside multiple savings-pass waves, yet confirms the regression ledger verdict with "8 PASS / 40 FAIL at the pin (failures are correct regression tests against unfixed defects)" and a "third silent weapon deletion found Oct 30 (b_razor_s drops bioplasma undisclosed)". INFERRED: Engineering capacity is being consumed by servicing review waves, screenings, and syntheses rather than burning down the 40 failing regression tests or advancing the Godot build through its stated sequence of "rules parity checks, one playable battle, then the full run, effects pass, cutover".

What it costs the game: Known ship weapon data loss (b_razor_s) and 40 verified defects remain live in the oracle codebase, directly delaying rules parity and pushing out the playable Godot milestone and Steam release.

2. Single-threaded implementation bottleneck on Opus with an explicit refusal to sequence work

What breaks or underperforms: The program handoff abdicates scheduling and dumps bug fixing, rules design, engine migration, and tooling onto a single implementation owner (Opus) with no priority order.

Evidence: OBSERVED: The handoff explicitly states, "This document assigns nothing. It does not sequence implementation work, set priorities, or order builds." It names "The barge upgrade is the first commission." while simultaneously leaving Opus to resolve 40 failing tests, the Godot port, telemetry implementation, Eclipse battleship selection ("d_meridian vs d_wraith left to Opus"), ship density gates ("target 20, ceiling 24"), Hegemony flagship anchor ("Anchor definition (which ship anchors, exact radius) is yours"), Glasswrights shield charge ("must specify what sits above the baseline shield regen"), and the Deathless reanimate gate ("The report gate stands, it is not dropped."). INFERRED: Treating unfinished mechanical design specs and verification reports as unsequenced implementation tasks guarantees context-switching thrash and blocks combat rules parity in Godot.

What it costs the game: Four of the six faction asymmetry rulings (Hegemony, Glasswrights, Chorus tuning cap, and Eclipse/Deathless) plus the 20-ship battle density target still require Opus design specs or gate reports before their combat code can be locked for Godot parity.

3. Overturning the Save Audit's Godot cutover scope claim: zero Godot save code or browser-to-desktop bridge was inspected

What breaks or underperforms: The claims register states "saves BLOCKER without the importer (fixtures now built and filed)", and the save audit claims to cover the Godot save scripts, but the audit never inspected a single line of Godot code or addressed how a desktop executable accesses sandboxed browser storage.

Evidence: OBSERVED: The save audit header claims scope over "the Godot save code it would cut over to (godot/campaign/campaign.gd, godot/main/main.gd, godot/scenes/battle/battle.gd, godot/story/career.gd)", yet every single observation in the audit cites only browser JavaScript files (core.js, campaign3d.js, scene3d.js, ui3d.js, campaign_meta.js, main3d.js) where Persist.saveLocal() "writes JSON.stringify({meta:META, run:SAVED_RUN}) to localStorage key voidsworn.v1". INFERRED: This overturns the implied readiness of the Godot save cutover: filing JSON "importer fixtures" tests schema parsing in isolation, but proves nothing about the uninspected .gd files or how a native Godot desktop build reading user:// will extract voidsworn.v1 out of a web browser's localStorage sandbox or cloud path (data/users/<uid>/save).

What it costs the game: The team believes the save blocker is solved by test fixtures, masking an unbuilt transport and .gd integration gap that will break player progression at cutover.

4. Overturning the Desktop Performance Audit's actionability under the Oct 26 browser code freeze

What breaks or underperforms: The claims register promotes "desktop performance two named fixes" and the save audit flags a settings cloud-sync bug (saveOpts()), all targeting the Babylon.js browser build after it was frozen to break fixes only.

Evidence: OBSERVED: The browser build is "frozen to break fixes only since Oct 26, 2026", yet the Oct 29 desktop performance audit inspected only Babylon.js files (scene3d.js, fx3d.js, vfx3d.js) where "No runtime profiling was done; this is a static read." Its second named fix (navLights calling v.root.computeWorldMatrix(true) in vfx3d.js:166) is marked "INFERRED: at 20 ships with kit-built hulls this is one of the largest avoidable CPU costs", and its first fix addresses G.mobile misclassifying touch PCs at boot (scene3d.js:4, main3d.js:11). Similarly, the save audit's Finding 2 ("saveOpts() merges into META.opts and calls Persist.saveLocal() only" in ui3d.js:543) is a non-break cloud sync edge case. INFERRED: Overturning the priority of these browser fixes: vfx3d.js matrix math is unprofiled (PERFCAP was not run) and specific to Babylon.js, and fixing non-break bugs in frozen JS files violates the Oct 26 freeze.

What it costs the game: Every hour spent patching Babylon's vfx3d.js, scene3d.js, or ui3d.js is dead-end maintenance on a deprecated browser engine that delays the Godot migration.

5. Overturning the Godot 3D Brief's "Forward+ decisively" readiness and hardware-budgeting claims

What breaks or underperforms: The claims register marks the Godot 3D brief as settled ("Forward+ decisively, red-teamed twice"), but the brief contains an unresolved renderer fallback contradiction, relies on single-source external claims, and plans to calibrate GPU budgets on an RTX 5080 instead of the target hardware floor.

Evidence: OBSERVED: The brief states "the Compatibility renderer is not a viable fallback for the effects pass" (no decals in 4.7, no particle trails, no volumetric fog) while also admitting Forward+ "auto-falls back to Compatibility when the RenderingDevice is unsupported". Its shipped-game evidence is "a SINGLE dev write-up, treat as a lead" on Godot 4.5 (not 4.7), its particle numbers come from "a single non-Godot source", and it states "The real budget gets set by the effects-pass performance budget item using PERFCAP on Ryan's PC" right after warning "Design the default tier for that, not for the RTX 5080 on Ryan's desk" when targeting the Steam survey floor ("RTX 3060" and "8 GB VRAM"). INFERRED: Profiling PERFCAP on an RTX 5080 cannot validate frame budgets for an RTX 3060, and commissioning three review rounds on late-stage visual effects ("volumetric fog, SSR, SSIL, SDFGI/VoxelGI", "Phantom Camera") before achieving a playable Godot run inverts the migration critical path.

What it costs the game: Prematurely locks in high-overhead Forward+ features that will either silently degrade into a broken Compatibility fallback on unsupported devices or fail frame-time targets on mainstream RTX 3060 hardware.

6. Telemetry specification over-engineering for single-user testing and already-settled simulation math

What breaks or underperforms: The wave 5 telemetry spec (telemetry_spec_2026_10_29.md), reviewed across three models (chair, DeepSeek, Qwen), asks Opus to instrument 13 event schemas and a UI export button in Godot prior to first playable, largely to re-check settled simulation results and deterministic code invariants.

Evidence: OBSERVED: The spec is built for "Ryan's own runs first, wider testing later" to answer Q-A, even though regroup tension already "binds in 0.0 percent of 60,000 modeled regroups (median worst-ship damage 19 HP against a median 737-credit purse)" and was "ruled accept as is". It also instruments nemesis_adaptation to log "the Q4 clash check should make this always false; the log proves it". INFERRED: Building per-ship repair quote reconstruction (regroup_open joined to regroup_choice) so one player's manual runs can check a 737-credit vs 19-HP surplus already proven across 60,000 simulations, or using playtest logs to verify a deterministic boolean rule (Q4) that belongs in the regression test suite, is pure scope bloat.

What it costs the game: Adds custom JSONL file I/O, schema versioning, and UI hook requirements to the Godot campaign port before the campaign loop is even playable. Cut candidate: defer telemetry instrumentation until after the first playable Godot run is complete, and enforce the Q4 clash check via unit test.

7. Content assembly backlog is gated on another review wave while 7 campaign events fail free-exit checks

What breaks or underperforms: Nearly 400 drafted text entries are parked in staging awaiting a "story attack" while core campaign events and progression economy mechanics have unresolved functional failures.

Evidence: OBSERVED: Confirming the claims register figures from the core pack: "216 tree texts (tiers 1-3 assembled), 33 event variants, 41 Nemesis lines" plus "16 tutorial tips, 30 firstrun framing units, Eclipse battleship entry" are "Content drafts awaiting a story attack". Meanwhile, "event free-exit 26 of 33 pass" (leaving 7 events failing), economy is "MIXED (4 of 4)", and favour exhibits a steep "boon tax staircase (about 15pp at favour tiers 1-2, about 52pp at tier 3)". INFERRED: Subjecting 337 text drafts to another multi-leg editorial audit before integrating them and before fixing the 7 broken free-exit events and the 52pp tier-3 boon tax spike prioritizes prose polish over playable campaign integrity.

What it costs the game: Content sits unintegrated in review folders while over 21 percent of evaluated campaign events violate the free-exit design standard and tier-3 favour heavily taxes player boons.

8. Admiral portrait pipeline deadlock and scope expansion from the Oct 24 standing rule

What breaks or underperforms: The Chorus admiral portrait pass is stalled by an image generator refusal and pending human sign-off, while a new standing ruling expands art alignment requirements across every future admiral in the game.

Evidence: OBSERVED: In the handoff brief, "Matriarch v3 is a candidate awaiting Ryan's verdict, not a final", "Mending v3 generation was refused by the image tool and is NOT being retried in any reworded form", and a "NEW STANDING RULE: admirals should match their special abilities in some way" carries the instruction: "Apply this rule to all future admiral portraits, not just Chorus." INFERRED: The Mending Throng portrait is a hard blocker waiting on fresh human creative direction, and enforcing ability-matched portrait constraints across all six factions adds a recurring art-review gate to the Godot portrait pipeline (godot/portraits).

What it costs the game: Leaves the Chorus faction with an incomplete admiral roster and increases art regeneration churn across all remaining factions before cutover.

9. Settled regroup repair ruling carries dead UI and engineering overhead for a non-binding mechanic

What breaks or underperforms: Accepting the current repair economy as-is means post-boss ship repair never forces a resource trade-off, turning the regroup repair step into a friction tax with zero strategic tension.

Evidence: OBSERVED: Standing rulings dictate "Repair always beats scrap-and-replace per ship by design" and "repair tension binds in 0.0 percent of 60,000 modeled regroups (ruled accept as is)", backed by the telemetry spec's citation of "median worst-ship damage 19 HP against a median 737-credit purse" and full-ship-only quotes ("the shipped design has no partial repair"). INFERRED: While the ruling closes economy retuning for now, porting the per-ship repair quote UI and building custom regroup_open / regroup_choice telemetry around a mechanic that binds in 0.0 percent of 60,000 simulated regroups expends engineering effort on a dead decision node.

What it costs the game: Players click through trivial repair quotes after every boss without facing an allocation choice, and Godot port time is spent replicating and logging a non-binding UI flow.

Verdict

PROGRAM CRITICALLY FRONT-LOADED ON REVIEWS OVER BUILD EXECUTION: Stop commissioning multi-model audits, freeze non-break work on the Babylon.js build, cut pre-playable telemetry and advanced Forward+ effects research, and put Opus strictly on fixing the 40 failing regression tests and shipping one playable Godot run.

Not checked

Actual Godot GDScript implementation state: The pack lists the godot/ directory structure (rules, campaign, fx, render, portraits, music, audio, project.godot) and names four .gd paths in the save audit header (godot/campaign/campaign.gd, godot/main/main.gd, godot/scenes/battle/battle.gd, godot/story/career.gd), but contains zero lines of .gd source code to verify how close "one playable battle" or "the full run" is to completion.

The 40 failing regression tests by specific defect: The pack gives the aggregate "8 PASS / 40 FAIL at the pin" count and names b_razor_s dropping bioplasma, but does not include the findings-to-tests ledger text to rank the 40 unfixed defects by severity.

Runtime frame times and GPU profiling data: No PERFCAP CSV logs or runtime frame-time measurements were included in the pack for either the Babylon.js build or the Godot 4.7 build.

Reading order and task breakdown in READING_PLAN.md: Referenced in OPUS_HANDOFF.md ("Read READING_PLAN.md (same folder) for reading order"), but the file itself is not in the pack.
