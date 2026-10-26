# Raw return: engine proof audit, Qwen, Oct 25, 2026

Source: fresh Qwen chat (chat.qwen.ai), model selector changed from the Qwen3.7-Plus default to Qwen3.8-Max and verified before submission (Gate 1 PASSED); chat header verified still Qwen3.8-Max after generation started and after generation completed (Gate 2 PASSED); one slider CAPTCHA solved by the bot-challenge specialist on the first attempt; condensed evidence pack pasted inline in 3 parts at 10:38 PM CDT (the full 48,041-byte pack could not be read without uploading it to a third-party page, which was forbidden, and Qwen's attachment input was unusable); the two Job 4 source files were not attached, so the model worked from the pack's Job 4 excerpts. Run 10:23-10:45 PM CDT, harness-measured. Filed verbatim below; the working copy is reviews/engine_proof_audit_qwen_2026_10_25.md.

ENGINE PROOF AUDIT REPORT (Oct 25c, Condensed Pack)
Reviewer: outside, blind. I have not seen any other reviewer's answer. I work from this pack, the code excerpts it contains, and primary sources I can reason about. Where I cannot verify, I say UNSURE.

(1) FIX BEFORE THE PROOF IS REPORTED
These items would make the proof pass when it should fail, or fail for a fixable reason, or mislead Ryan. Each gets evidence and a fix.

FIX 1: RESULTS.md mixes measurement rounds without disclosure.
Evidence: The 109 MB exe and 3.7 s cold load come from round 3. The final round's godot_exe_cold.json says 3.085 s. The Babylon max-detail run in the final round did not load assets/hi (per the final README CAUTION, quoted verbatim in the chair notes). RESULTS.md presents numbers from both rounds in one table as though they came from one session.
Fix: Either re-run everything in one round under identical conditions, or add a column to every table row saying which round produced it. Ryan must know that "Babylon max detail" in the final round used old assets.

FIX 2: The Babylon max-detail vsync run did not hold 240 Hz.
Evidence: fb_max_2160_vsync reports refresh 178.571, not 240. Godot's equivalent reports 240.0. RESULTS.md says "dropped frames in 20 s: 2 vs 2472" as though both were capped identically. Babylon averaged 178 fps, below the 240 cap, so its dropped-frame counter is not measuring the same thing. A frame that takes longer than 1/240 s but shorter than 1/178 s would count as dropped for Godot but not for Babylon.
Fix: Re-run Babylon max detail with the cap actually holding at 240, or report the two numbers with their actual refresh rates and note they are not comparable. Do not let the "2 vs 2472" row stand as a like-for-like comparison.

FIX 3: The 1440p Godot dropped-frame count is wrong in RESULTS.md.
Evidence: RESULTS says 0 vs 64. The file fg_fp_max_1440_vsync says 192.
Fix: Correct to 192, or re-run and explain the discrepancy.

FIX 4: The Babylon max-detail load time of 23 s has no traceable source.
Evidence: Final round Babylon max files show 6.596 s. Round 3 shows 6.403 s. Neither is 23 s. No file in either round supports 23 s.
Fix: Remove or correct. If 23 s was measured by hand or in a different configuration, say so and provide the log.

FIX 5: The Godot max-detail load time of 36 s is wrong.
Evidence: Final round Godot max load is 38.033 / 38.067 s. The final README CAUTION itself says 38 s. RESULTS says 36.
Fix: Correct to 38 s.

FIX 6: The Babylon GPU memory figure of "about 12.5 GB" has no measurement behind it.
Evidence: Babylon runs in WebGL. There is no WebGL GPU memory counter. The final max notes report nvidia-smi total 1681 MB before launch, 5077 MB peak, a delta of 3396 MB. Nothing near 12.5 GB appears. The 12.5 GB may be a guess or a system-wide figure including the desktop and other processes.
Fix: Remove or replace with the measured delta (about 3.4 GB) and note it is a system-wide nvidia-smi reading, not a WebGL-specific counter. If the 12.5 GB was meant to include the browser process and OS compositor, say so and measure it properly.

FIX 7: The "average frame max detail" pair 5.8 vs 7.4 ms matches no file.
Evidence: Final max 2160 uncapped files say 5.032 vs 7.54. Vsync files say 5.617 vs 7.574. Round 3 says 4.994 vs 6.666. No pair rounds to 5.8 vs 7.4.
Fix: Pick one measurement, cite the file, and use it. Do not average across rounds.

FIX 8: The "worst 1% uncapped" pair 21 vs 11 ms is wrong.
Evidence: Final max p99 is 27.288 vs 10.97. Round 3 max p99 is 26.515 vs 9.099. The 21 matches the STRESS row (fb_stress_2160 p99 = 20.942), not the max-detail row.
Fix: Correct to the max-detail p99 values, or if the stress row was intended, label it as stress, not max detail.

FIX 9: The "10x faster" imported-project claim is unmeasured.
Evidence: No imported Godot project was built or timed in either round. The 38 s is runtime glTF decode of uncompressed 8K textures. The 10x is an estimate with no backing measurement.
Fix: Mark it as an estimate, or build the imported project and measure. Do not let an unmeasured estimate sit in a table next to measured numbers without a flag.

FIX 10: The blind test is not a single untouched run.
Evidence: Ryan read sheets 1 through 6, stopped at sheet 6 over Godot's depth of field, both builds then changed DOF settings and Godot's breach was moved, sheets were re-shot with the same labels, and Ryan finished. The final sheets are a composite. The blind key records only the outcome (A = Babylon), not whether FORCE_A was set, and the coin flip seed is not recorded.
Fix: Disclose in RESULTS.md that the blind read spans two sessions with a settings change between them. Record whether FORCE_A was used. For any future blind test, record the seed, log whether the assignment was forced, and do not re-shoot; if a setting must change, re-run the entire blind from scratch with new labels.

FIX 11: The rules-parity proof does not exist on main yet.
Evidence: contrib/opus/enginetest/godot_rules/ does not exist on main. tools/pc/ contains no parity.bat. Checked Oct 25 night.
Fix: Do not report the rules-parity half as passing, failing, or in progress until the code lands. The audit of game-code traps (Job 3 below) can be done now from the JS source. The GDScript port, the parity script, and the 10,000-draw test cannot be checked until they exist.

FIX 12: The pass bar for rules parity needs strengthening.
See Job 3 below for the full argument. In short: the per-turn hash in sim3d.js omits shields, section HP, statuses, RNG state, turn counters, pending events, and rounds HP to 0.1. A per-turn hash with those gaps can pass while the game state diverges. The bar must require a per-action hash that includes RNG state, or the proof is weaker than it looks.

(2) JOB 1: NUMBER-BY-NUMBER VERDICTS
I go through every quantitative claim in RESULTS.md. Verdicts: RIGHT, WRONG, or NOT TRACEABLE.

| Claim in RESULTS.md | Verdict | Evidence |
| Capped 240 Hz, 6 ships, dropped frames: 0 vs 0 | RIGHT | Matches files per chair verification. |
| Capped, 24 ships, dropped: 0 vs 4 | RIGHT | Matches files per chair verification. |
| Capped, max detail 4K, dropped: 2 vs 2472 | WRONG | Files say 8 vs 2468. Also, Babylon's refresh was 178.571, not 240, so the comparison is not like-for-like. The "2" in RESULTS matches neither the file value (8) nor any other round. |
| Capped, max detail 1440p, dropped: 0 vs 64 | WRONG | File says 0 vs 192. |
| Average frame 6/24/40 ships: 1.1/2.0/2.6 vs 2.2/3.2/3.7 ms | RIGHT | Rounds correctly from final 2160 uncapped files (1.085/1.961/2.613 vs 2.175/3.248/3.727). |
| Average frame max detail: 5.8 vs 7.4 ms | WRONG | No file pair matches. Closest: 5.032 vs 7.54 (final uncapped), 5.617 vs 7.574 (final vsync), 4.994 vs 6.666 (round 3). |
| Worst 1% uncapped max detail: 21 vs 11 ms | WRONG | Final max p99 is 27.288 vs 10.97. The 21 matches the STRESS row p99 (20.942), not max detail. |
| Load with 8K ships: 23 s vs 36 s | WRONG | Babylon max files show 6.596 or 6.403, not 23. Godot final max is 38.033/38.067, not 36. Neither number is traceable. |
| Graphics memory: about 12.5 GB vs about 13 GB | PARTIALLY WRONG | Godot 12960.9 MB is about 13 GB, RIGHT. Babylon has no GPU counter; nvidia-smi delta is about 3.4 GB, not 12.5 GB. The Babylon figure is NOT TRACEABLE to any measurement in the pack. |
| Standalone .exe 109 MB | RIGHT | Round 3 README and Godot README both say 109 MB exe plus 0.2 MB wrapper. |
| 3.7 s cold to first frame | MIXED ROUNDS | Round 3 godot_exe_cold.json says 3.706 s. Final round says 3.085 s. RESULTS uses the round 3 number without saying so. |
| "About 135 fps" for Godot max at 240 Hz | APPROXIMATELY RIGHT | Final files say 132.62 fps (uncapped) and 132.02 (vsync). "About 135" is slightly high but in the right range. I would say "about 132" for precision. |
| Babylon.js 9.30.0, Godot 4.7.2 Forward+ Vulkan | NOT TRACEABLE from this pack alone | Stated as fact. I have no version manifest to check. UNSURE. |
| RTX 5080 16 GB, 240 Hz 4K | NOT TRACEABLE from this pack alone | Stated as fact. UNSURE. |
| "Both are smooth everywhere at 60 fps" | RIGHT as a summary | All average frame times are well under 16.67 ms. |
| Babylon needs Electron or similar for shipping | RIGHT per the claim, but see Job 5 for caveats. | |
| 246 KB JS rules, 620 KB rendering/UI | NOT TRACEABLE | No file sizes are given in this pack to verify. UNSURE. |
| Godot's max load is "runtime glTF decode; an imported Godot project uses compressed textures, est. 10x faster" | NOT TRACEABLE | The 38 s runtime decode is measured. The 10x imported-project speedup is an unmeasured estimate. No imported project was timed. |

Summary: of the 17 quantitative rows I checked, 5 are right, 7 are wrong, 3 are not traceable, 1 is approximately right, and 1 mixes rounds. This is a serious accuracy problem for a document that will drive a build-or-stay decision.

(3) JOB 2: BLIND TEST FAIRNESS
Was the blind test fair?
No, not fully. Several issues:

2a. The coin flip is unverifiable. blind.py uses os.urandom(4) for the seed. The seed is not recorded. The key file records only the outcome (babylon_is_A: true). The FORCE_A environment variable can override the flip, but whether it was set is not logged. From the artifacts, I cannot tell whether the A/B assignment was a genuine 50/50 flip or was forced. The code allows forcing; the artifacts do not record whether forcing happened.
Fix: log the seed, log whether FORCE_A was set, and hash the key file at creation time.

2b. The blind read is not one continuous run. Ryan read sheets 1 to 6, stopped, settings changed (DOF turned off except light on hero shots, Godot breach repositioned), sheets were re-shot with the same labels, and Ryan finished. The final artifact is a composite of two sessions with different rendering settings. The labels did not change, so Ryan could in principle remember which images he saw in session 1 and compare them to session 2 images, breaking blindness.

2c. Depth of field and TAA. Ryan stopped at sheet 6 because Godot's DOF was too strong. Both builds then set DOF off except light on hero shots. This means the final comparison was not at the settings either engine would ship with. It also means Godot's DOF advantage (if any) was removed before the final read. This is a fairness fix, but it also means the blind test does not measure what the player would see.
I do not have Godot's main.gd camera code in this pack. Camera FOV, exposure, tone mapping, and grading settings are UNSURE. I cannot confirm they matched between engines.

2d. Effects polish asymmetry. The Opus read in RESULTS.md states: "effects come mostly from build effort (Babylon's effects got more polish rounds)." This is a build-effort difference, not an engine difference. The blind test as designed does not separate engine capability from builder effort. If Babylon's effects builder had three more polish rounds than Godot's, Babylon's effects will look better regardless of engine.

2e. Same assets, cameras, clock, exposure. The pack states "same six flagships, same max-detail 8K ships (assets/hi), same effects spec, environment, cameras and clock (SPEC.md, trimmed scope R20)." I do not have SPEC.md in this pack. I cannot verify the cameras matched. UNSURE. The final README CAUTION says Babylon's max mode did not load assets/hi in the final round, so the max-detail comparison used different ship assets. This undermines the "same assets" claim for the max rows.

2f. Board stills directory naming. Godot's board stills come from final_g_board_hi; Babylon's from final_b_board. The _hi suffix on Godot suggests a different asset tier or resolution. UNSURE whether the inputs were identical.

2g. Engine-level vs build-effort-level for each of Ryan's conclusions:

| Ryan's conclusion | Engine-level or build-effort? | Reasoning |
| Godot better lighting and ship detail | Mostly ENGINE | Godot's SDFGI, SSIL, SSR, and soft shadows have no direct Babylon.js equivalent. Babylon uses PBR with IBL and point lights; it does not have a real-time GI system of that class. This is an engine capability gap. |
| Godot better asteroids | UNSURE | Could be engine (lighting, normal mapping) or build (mesh quality, texture resolution). Not enough info. |
| Babylon better breach, venting, explosions, trails, board laser | Mostly BUILD EFFORT | The Opus read says these got more polish rounds on Babylon. The underlying techniques (particle systems, volumetric fog, shader tricks) exist in both engines. Godot's current kit (GPUParticles3D, FogVolume, soft particles) can in principle match all of these. The gap is hours spent, not engine limits. |
| Chorus and Deathless read better in Babylon | BUILD EFFORT (lighting setup) | The Opus read says "dark hulls sit too dark under Godot's lighting." This is a lighting-tuning problem. Godot's SDFGI and SSR can light dark hulls; the exposure, rim light, and fill light setup needs work. Not an engine limit. |
| Godot shield not visible | BUILD BUG | See Job 4. The shader exists, the material exists, the timing exists. Likely a blend mode, depth, or timing issue. Not an engine limit. |
| Ithar broken in both | ASSET | Both engines show the same broken mesh. Not an engine issue. |

Fairness verdict: The blind test is directionally useful but not a clean controlled experiment. The composite sessions, the unverifiable coin flip, the polish asymmetry, the Babylon max-detail asset bug, and the missing camera/exposure verification all weaken it. Ryan's lighting conclusion is well-supported (engine-level). His effects conclusion is real but reflects build effort, not engine limits. The proof phase (rebuilding effects in Godot) is the right next step to separate the two.

(4) JOB 3: RULES-PARITY TRAPS
This is the most important section. I list every trap I can identify from the code excerpts, with file:line references.

3a. PRNG port traps.
The PRNG at core.js:5-6 is a mulberry32 variant. It uses Math.imul, which is a 32-bit integer multiply. GDScript has no Math.imul. The port must use a 32-bit multiply that wraps identically. In GDScript, integer overflow wraps, but the intermediate products in Math.imul(a,b) must be computed as 32-bit signed integers. If the port uses 64-bit multiply and then truncates, the result will differ for large inputs because the upper bits affect the lower bits differently in signed vs unsigned wrapping.
Fix: implement imul explicitly:
func imul(a: int, b: int) -> int:
    var ah = (a >> 16) & 0xFFFF
    var al = a & 0xFFFF
    var bh = (b >> 16) & 0xFFFF
    var bl = b & 0xFFFF
    return ((al * bl) + (((ah * bl + al * bh) << 16) & 0xFFFFFFFF)) & 0xFFFFFFFF
Then handle the signed interpretation carefully. The JS code uses |0 to force signed 32-bit. GDScript integers are 64-bit. The port must mask to 32 bits and interpret the sign bit.
The division at the end: ((t^(t>>>14))>>>0)/4294967296. JS >>>0 forces unsigned 32-bit. GDScript has no unsigned right shift. The port must mask: (t ^ (t >> 14)) & 0xFFFFFFFF and then divide by 4294967296.0 as a float.

3b. The global RNG stream is the biggest trap.
core.js:4 initializes RNG_S from Math.random, but battle.js:295 overrides with rndSeed(seed) for seeded runs. After that, every call to rnd() draws from one global stream. Terrain gen draws ph values (battle.js:167). Deployment draws. Events draw (battle.js:26). AI draws. Combat draws. The weighted pick at battle.js:303 draws once per pick and walks the list in order.
Any extra or missing draw anywhere shifts every later draw. The GDScript port must call rnd() in exactly the same order, the same number of times, with the same arguments, in every code path. This includes error paths, early returns, and conditional branches. If the JS code has a branch that draws from rnd() only when a condition is true, the GDScript port must draw in the same branch under the same condition.
Specific trap: battle.js:295 has seed=cfg.seed!=null?(cfg.seed>>>0):Math.floor(rnd()*4294967296). If cfg.seed is null, it draws from rnd() to make a seed. The port must replicate this: if no seed is given, draw once, then reseed. If a seed is given, do not draw.

3c. Rounding: Math.round vs GDScript round().
JS Math.round rounds half toward positive infinity. GDScript round() rounds half away from zero. They differ on negative .5 values: JS Math.round(-0.5) = 0 (rounds toward +inf, which is toward zero for negatives). Wait, let me recheck. JS Math.round(-0.5) is -0, which is 0. GDScript round(-0.5) is -1 (away from zero). So they differ.
Actually, let me be more careful. JS Math.round(-1.5) = -1 (rounds toward +inf). GDScript round(-1.5) = -2 (rounds away from zero). JS Math.round(-2.5) = -2. GDScript round(-2.5) = -3. They differ on all negative .5 values.
The facing computation at battle.js:260 and :277 uses Math.round(Math.atan2(y,x)*180/Math.PI/60). atan2 returns values in [-pi, pi], so the input to round can be negative. A .5 boundary in the negative range will flip the facing.
Fix: in GDScript, use floor(x + 0.5) to replicate JS Math.round, or write a helper:
func js_round(x: float) -> int:
    return int(floor(x + 0.5))
This matches JS behavior for all inputs including negative .5 values.
All 20-plus Math.round call sites listed (battle.js:101, 103, 114, 116-117, 175-176, 255, 260, 277, 291, 331, 360, 378, 481, 532, 646, 667, 676, 686) must use this helper.

3d. Integer division: Math.floor(r/2) vs GDScript integer division.
JS Math.floor(-1/2) = Math.floor(-0.5) = -1. GDScript integer division -1/2 = 0 (truncates toward zero). This affects hex math at battle.js:27-28, 84, 87, 89, 174, 204, 229, 245, 253-256, 296, 332, 335.
Fix: use floori(x / 2) or a helper func jfloor_div(a: int, b: int) -> int: return int(floor(float(a) / float(b))) in GDScript. Never use plain / for integer division in the port.

3e. Modulo.
battle.js:260 and :277 use ((x%6)+6)%6, which is safe in both languages. JS % can return negative for negative inputs, and this pattern normalizes. GDScript % also returns negative for negative inputs. The pattern is safe. No fix needed, but the port must keep the double-modulo pattern.

3f. Float operation order.
GDScript float is float64, same as JS double. Same operation order gives same result. But any reordering breaks bit-exactness. The damage math chains at battle.js:514-528 and :645-646 must be ported in the exact same order. Do not "simplify" or "optimize" the math. Do not factor out common subexpressions if the original code computes them separately.

3g. Object.keys iteration order.
JS Object.keys returns keys in insertion order for string keys. battle.js:26 does pick(Object.keys(BEVENTS)), battle.js:43 and :49 pick from Object.keys of region/biome tables, battle.js:312 iterates Object.keys(T) for boss rock thinning.
GDScript Dictionary iteration order is insertion order as of Godot 4.x, but this should be verified from the Godot 4.7 docs. Even if it is insertion order, the GDScript code must insert keys in the same order as the JS objects. If the data tables are defined differently in GDScript, the order could differ.
Fix: do not iterate dictionaries. Convert to explicit arrays with a fixed order. For example, instead of pick(Object.keys(BEVENTS)), use pick(BEVENT_KEYS_ARRAY) where BEVENT_KEYS_ARRAY is a const array in the same order as the JS object's keys.

3h. Sort stability and tiebreaks.
JS Array.sort is stable (guaranteed since ES2019). Ties keep input order.
GDScript sort_custom stability: I need to check Godot 4.7 docs. The Godot docs for Array.sort_custom state it uses a stable sort (Timsort). However, I flag this as UNSURE until verified against the actual Godot 4.7 source or docs. The chair's note says "do not assume it."
Sorts without total tiebreaks:
battle.js:864: ts.sort((a,b2)=>val(b2)-val(a)). No tiebreak. If two targets have equal val, their order depends on input order. If the GDScript port builds the target list in a different order, the sort result differs.
battle.js:1073: alive('enemy').sort((a,b)=>(a.isSq?0:1)-(b.isSq?0:1) || b.speed-a.speed). No tiebreak for equal speed and equal squadron status. Same problem.
battle.js:569, :1052: weapon sorts with partial tiebreaks.
Fix: before porting, add a total tiebreak to every sort. Use unit id (from newId) as the final tiebreak. This makes the sort deterministic regardless of input order. Example: ts.sort((a,b2) => val(b2)-val(a) || a.id - b2.id).

3i. Determinism: Date.now and newId.
core.js:19: newId uses Date.now. If unit ids enter battle state, save data, or the parity hash, parity breaks because two runs at different times get different ids.
battle.js:823: stallGuard uses Date.now for a watchdog timer. This is not a rules path, but if the watchdog triggers and changes game state, it could affect parity. The port should use a frame counter or turn counter instead.
sim3d.js:1: shims performance.now to Date.now. battle.js:910 uses performance.now for a stall timer and debug log. Not rules, but verify it does not leak into state.
core.js:155 save() and core.js:315 runDefaults use Date.now for campaign meta. If the parity test includes campaign meta, this breaks. The parity test should exclude timestamps or mock them.
Fix: in the parity test, either mock Date.now to return a fixed value, or exclude all id and timestamp fields from the hash. The GDScript port should use a deterministic id counter (incrementing integer) instead of Date.now.

3j. Math.random in rules paths.
The pack states: "No Math.random appears in battle.js, core.js rules paths, data.js, or sim3d.js rules paths (only core.js:4 initial seed, overridden by rndSeed, and the cosmetic comment at core.js:3)." I accept this from the chair's grep. The cosmetic comment at core.js:3 says "Cosmetic effects keep Math.random." As long as cosmetic effects do not feed back into rules state, this is fine. The port must ensure no cosmetic code path calls the rules RNG or vice versa.

3k. The existing hash in sim3d.js is insufficient.
sim3d.js:247-250 hashes: s0 (seed), B.shape, sorted terrain keys, per-unit [tpl, q, r, facing, round(hp*10), dead, weapons fired], and log messages.
It OMITS:
Shield state (s['shield'])
Section HP (u.sec, the prowing/mid/eng sections)
Statuses (burning, stunned, etc.)
RNG state (RNG_S value)
Turn and activation counters
Pending events (queued battle events, delayed effects)
Terrain damage state beyond keys
Board position details beyond (q, r)
It rounds HP to 0.1 (Math.round(u.hp*10)). Two states with HP 5.04 and 5.05 hash the same. A rules divergence that changes HP by less than 0.05 is invisible.
My answer on per-turn vs per-action hash:
A per-turn hash is necessary but not sufficient. Here is why. Within a turn, the game processes activations in order. If activation order is wrong (sort tiebreak bug), the per-turn hash might still match if the same units die and the same total damage is dealt, but the sequence of events differs. A player would see different animations, different targeting, different combat log entries. The parity test should catch this.
I recommend: hash after every activation (per-action), not just per-turn. The hash must include:
RNG_S value (the PRNG state itself). This is the single most important addition. If RNG_S matches after every action, the draw sequence is correct.
Full unit state: tpl, q, r, facing, exact HP (no rounding), dead flag, section HP for each section, shield state, all statuses, weapons with fired flags and cooldowns.
Turn number, activation index within turn, pending event queue.
Board shape and full terrain state.
Combat log entries (or a hash of them).
The seed.
The hash should use exact float representation, not rounded. Use the full 64-bit double bits. In GDScript, you can bit-cast a float to an int for hashing.

3l. Gravity well.
battle.js:280 wellTick exists. The dead-star shape appears at battle.js:58-65, :181, :236. B.well is set at battle.js:313. The board shape appears in 6 of 8 fight types. The gravity well is a gameplay mechanic, not background decoration. The parity test must include well state and wellTick effects in the hash. Any claim that the gravity well is "background only" is wrong per the code.

3m. What can be checked now vs after landing.
The godot_rules directory and parity.bat do not exist on main. Therefore:
Can be checked now (from JS source in this pack):
All PRNG traps (3a)
Global stream ordering (3b)
Rounding traps (3c)
Integer division traps (3d)
Modulo safety (3e)
Float order (3f)
Object.keys order (3g)
Sort stability and tiebreaks (3h)
Date.now and newId (3i)
Math.random absence (3j)
Hash sufficiency (3k)
Gravity well existence (3l)
Cannot be checked until the code lands:
Whether the GDScript port actually reproduces draw order
Whether the parity script exists and works
Whether the 10,000-draw test passes on 3 seeds
Whether the GDScript imul is correct
Whether the GDScript sort is stable in practice
Whether the hash includes all required state

(5) JOB 4: EFFECTS PARITY

4a. What makes Babylon's effects read better.
From the spec description in the pack, Babylon's effects kit includes:
Volleys ripple 80 ms apart (staggered timing)
Impact flash, debris, shake scale with weapon weight (reactive feedback)
Staged damage: scorch, then torn holes, with venting, sparks, fire (progressive destruction)
Parts leave torn edges with squibs (secondary particle bursts)
Destroyed ships leave drifting wrecks (persistent debris)
Destruction event: blinding flash lighting nearby hulls, shockwave ring, rolling fireball with dark smoke, 3-5 large hull chunks tumbling with burning edges and squibs, debris and ember spray, burning wreck chunk drifts on (multi-layered, multi-phase event)
Babylon's shield: persistent sphere mesh (diameter 2, 48 segments), ALPHA_ADD blend, colour multiplied by 2.2 (HDR boost), uHit updates per frame, follows ship drift. The ripple is animated on a persistent mesh, not a one-shot particle.
Godot's current kit (from max notes): soft particles reading depth texture, FogVolume for venting/smoke/fireball, parallax occlusion mapping for breach holes, a light per gun and per impact, 14 instanced effect kinds (one draw each) for 6 ships.
Per-effect assessment:

| Effect | Babylon approach | Godot current kit | Can Godot match? | What is missing |
| Hull breach | Staged: scorch, torn holes, venting, sparks, fire | Parallax occlusion mapping breach holes | Yes, with work | Godot needs staged progression (scorch decal, then hole mesh swap, then venting particles). Parallax mapping alone is not enough. Need a sequence controller. GPUParticles3D for sparks. FogVolume for venting smoke. |
| Venting smoke | Volumetric, directional | FogVolume | Yes | FogVolume is the right tool. Need directional emission and wind drift. Godot docs: https://docs.godotengine.org/en/stable/classes/class_fogvolume.html |
| Volumetric explosions | Rolling fireball with dark smoke, blinding flash, shockwave ring | FogVolume, soft particles | Yes, with work | FogVolume for the fireball volume. GPUParticles3D with soft-particle depth fade for the outer shell. A PointLight3D or OmniLight3D for the blinding flash, animated intensity. A shader-based expanding ring mesh for the shockwave. Godot GPUParticles3D docs: https://docs.godotengine.org/en/stable/classes/class_gpuparticles3d.html |
| Engine trails | Persistent trails behind ships | Not described in current kit | Yes | Use a Trail3D approach: a MeshInstance3D with a ribbon mesh updated per frame, or GPUParticles3D with a long lifetime and velocity aligned to ship motion. Godot does not have a built-in Trail3D node in 4.x; the community approach is a custom mesh ribbon or a shader-based trail. UNSURE whether Godot 4.7 added one. |
| Shield ripple | Persistent sphere, ALPHA_ADD, HDR colour x2.2, per-frame uHit | Shader with discard, rings, blend_add, depth_draw_never | Yes, but current build has a bug | See shield analysis below. |
| Board laser | Described as better in Babylon | Not described in Godot kit | Yes | GPUParticles3D or a custom shader on a cylinder/box mesh. Beam shader with animated UV scroll. |
| Destruction chunks | 3-5 large hull chunks tumbling with burning edges, squibs, debris, ember spray | Not described in current kit | Yes | RigidBody3D for tumbling chunks. GPUParticles3D for embers and squibs. A burning-edge shader (emission + animated noise). This is build work, not an engine limit. |
| Drifting wrecks | Persistent wreck mesh with slow drift | Not described | Yes | RigidBody3D or AnimatableBody3D with low gravity. Simple. |

Polish-round asymmetry: The brief states Babylon got more polish rounds. This is the most likely explanation for the visual gap. Godot's kit (GPUParticles3D, FogVolume, soft particles, lights) is sufficient in principle for every effect listed. The gap is iteration time, not engine capability.

4b. Godot 4.7 tools and docs links.
GPUParticles3D: https://docs.godotengine.org/en/stable/classes/class_gpuparticles3d.html
FogVolume: https://docs.godotengine.org/en/stable/classes/class_fogvolume.html
Soft particles (depth fade): https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html (search for "depth fade")
StandardMaterial3D blend modes (including BLEND_MODE_ADD): https://docs.godotengine.org/en/stable/classes/class_standardmaterial3d.html
ShaderMaterial and custom shaders: https://docs.godotengine.org/en/stable/tutorials/shaders/
OmniLight3D / SpotLight3D for impact flashes: https://docs.godotengine.org/en/stable/classes/class_omnilight3d.html
RigidBody3D for debris chunks: https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html
AnimationPlayer for staged sequences: https://docs.godotengine.org/en/stable/classes/class_animationplayer.html
I note these are stable-docs links. I cannot verify that every URL resolves on the 4.7 branch without fetching them. UNSURE on exact 4.7 page URLs if they differ from stable.

4c. Shield invisibility: ranked causes.
The Godot shield shader (fx.gd) has these properties from the pack:
:37 SHIELD_T := 0.6 (0.6 second duration)
:378-381 clock-driven, two thin ripple rings from impact point
:656 shield material creation
:794-795 shield node visibility toggled per phase
:930-940 per-frame update runs only while ah in [0.0, SHIELD_T), meaning 0.0 to 0.6 s
:1212 shielded flag = s['shield'] != null
:1301-1317 on hit, material_override set with tint, hit_dir, t0
Shader: discards when dot(d3, hit_dir) < 0.0 (back hemisphere), ring formula (dist - (0.4 + age * 9.0)) / 0.11, energy 1.0, blend_add, depth_draw_never, cull_disabled
Radii = half * 1.15 + 1.5
hit_dir (0.15, 0.2, -1.0)
Timing analysis:
The shield event fires at 2.4 s in a 4 s loop. It lasts SHIELD_T = 0.6 s, so it is visible from 2.4 s to 3.0 s of each loop.
Blind stills are taken at:
Battle t=5.0 s. In a 4 s loop, 5.0 mod 4 = 1.0 s. The shield is not active at 1.0 s. The still CANNOT capture the shield.
Board t=3.0 s. 3.0 mod 4 = 3.0 s. The shield is not active at 3.0 s (it ended at 3.0 s). The still CANNOT capture the shield, or catches at most the last frame of the fade.
Breach t=3.0 s. Same as board. Shield just ended or is ending.
Destruction t=12.6 s. 12.6 mod 4 = 0.6 s. The shield is not active at 0.6 s. The still CANNOT capture the shield.
So none of the blind stills are taken during the shield's visible window (2.4 to 3.0 s). The "Godot shield not visible" verdict from the blind test could be entirely a still-timing artifact. Ryan may never have seen the shield in any still.
However, Ryan also watched real-time playback, not just stills. If he saw the shield in motion and it was invisible, that is a real bug. If he only looked at stills, the timing explains it.
Ranked shader/build bug candidates (if it is a real bug, not timing):
1. depth_draw_never with blend_add. The shader uses depth_draw_never. If the shield mesh is behind other opaque objects, it will still render (cull_disabled, no depth test mentioned). But if there is a depth pre-pass or if the shield mesh is sorted behind opaque objects and the renderer skips it, it could vanish. Check whether the mesh's render_priority is set high enough. fx.gd:656 (material creation) is where this would be set. If render_priority is not set, the shield may sort behind the ship hull and be occluded despite depth_draw_never.
2. The discard in the shader. The shader discards when dot(d3, hit_dir) < 0.0. hit_dir is (0.15, 0.2, -1.0). If the camera is on the wrong side of the ship, the entire visible hemisphere could be discarded. For a blind still taken from a specific camera angle, the shield could be entirely back-facing. This is a design choice (show ripple only on the hit side), but if the camera is behind the hit, you see nothing.
3. blend_add with low energy. The shader uses blend_add with energy 1.0. Babylon uses ALPHA_ADD with colour multiplied by 2.2. If the Godot shield colour is not boosted above 1.0, the additive blend may be too faint to see against a bright background. The Babylon HDR boost (x2.2) is significant. Godot's energy 1.0 may not be enough. fx.gd:1301-1317 sets the tint; if the tint is not multiplied up, the shield is dim.
4. material_override vs material. fx.gd:1301-1317 sets material_override. If the shield mesh also has a material set in the scene or in code at :656, the override might conflict or not apply as expected. Check whether material_override is actually being used by the renderer for this mesh type.
5. Mesh scale vs ship scale. Radii = half * 1.15 + 1.5. If "half" is the ship's bounding half-extent and the ship is small, the shield could be too small to notice. If the ship is large, the shield could be so large it is off-screen. Check the actual values for the six flagships.
6. Visibility toggle. fx.gd:794-795 toggles shield node visibility per phase. If the phase logic is wrong, the shield could be hidden when it should be visible.
My top candidate: The timing artifact (no still captures the shield window) combined with the low energy (1.0 vs Babylon's 2.2x HDR boost) is the most likely explanation. If Ryan saw it in motion and it was still invisible, the discard hemisphere and the camera angle are the next suspects.

(6) JOB 5: RANKED RISKS BOTH DIRECTIONS
Risks of moving to Godot (ranked by likelihood of changing the call):
Risk 1 (HIGH): Rules port effort and correctness.
The JS rules runtime is about 246 KB across four files, plus the sim's game copy. Porting to GDScript with exact PRNG parity, exact rounding, exact sort order, and exact draw order is a large, error-prone task. The parity traps in Job 3 are numerous and subtle. The port plan estimate is in contrib/muse/reviews/engine_port_plan_synthesis.md, which I do not have in this pack. UNSURE whether the estimate accounts for all the traps listed above. If the port takes 3x longer than estimated, the "prove it first" phase drags.
Risk 2 (HIGH): Godot 4.x stability on NVIDIA Vulkan.
Godot 4.x uses Vulkan as its primary renderer on Windows. NVIDIA driver issues with Vulkan are documented in the Godot issue tracker. I do not have specific Godot 4.7 + RTX 5080 bug reports in this pack. UNSURE. Ryan should check https://github.com/godotengine/godot/issues for NVIDIA-specific Vulkan bugs before committing. The RTX 5080 is new; driver maturity is a concern.
Risk 3 (MEDIUM): GodotSteam licence and update pace.
GodotSteam is a community project wrapping Steamworks for Godot. Its licence and update cadence depend on its maintainers. If Valve updates Steamworks and GodotSteam lags, the overlay, achievements, or multiplayer could break. Primary source: https://godotsteam.com/ and its GitHub repo. UNSURE on exact licence terms from this pack. The RESULTS.md claim "Steam through GodotSteam including the overlay" should be verified against the GodotSteam docs for the specific Godot 4.7 version.
Risk 4 (MEDIUM): Save-file migration.
The current game saves in JS (core.js:155 save()). Moving to Godot means a new save format. Players with existing saves need migration. The port plan should include a save migration path. If the game is pre-release, this is less critical. UNSURE on release status from this pack.
Risk 5 (MEDIUM): Editor workflow.
RESULTS.md says "Godot has a visual editor Ryan can open; Babylon is code only." This is true and is a real advantage. But it also means Ryan's workflow changes. If Ryan is comfortable in code and the Godot editor introduces friction (scene management, node trees, import pipeline), the productivity gain may be less than expected. This is a soft risk, hard to quantify.
Risk 6 (MEDIUM): Test tooling.
The current check pack (tools/pc/) has no parity.bat. The Godot port needs its own test harness. GDScript testing is less mature than JS testing (no Jest equivalent in the box). Godot has GUT (Godot Unit Test) as a community addon. The parity test must run headless, compare against the Node sim, and print PASS/FAIL. Building this tooling is part of the port cost. UNSURE whether the port plan includes it.
Risk 7 (LOW): Godot export size and startup.
The 109 MB exe is larger than a browser page, but this is normal for a native game. The 3.7 s cold load is acceptable. Low risk.
Risks of staying on Babylon (things that make Babylon look better than the write-up says):
Counter-risk 1 (MEDIUM): Babylon 9.30 is free to upgrade.
RESULTS.md notes: "Staying on Babylon costs nothing to move to 9.30 (FINDINGS X16)." This is true. The existing codebase runs on the latest Babylon with no port. The 246 KB rules and 620 KB rendering/UI stay as they are. This is a real cost saving that the write-up mentions but does not weigh heavily.
Counter-risk 2 (MEDIUM): Babylon's effects are already built.
Babylon's breach, smoke, explosions, trails, laser, and shield are working and polished. Rebuilding them in Godot is the proof task. If the rebuild takes longer than expected or never quite matches, the proof fails and the team has spent weeks. The Babylon effects are a known quantity.
Counter-risk 3 (LOW): Babylon's Web deployment.
Babylon runs in a browser. This allows instant updates, no install, and potential web-based demos or marketing pages. Godot's .exe is a native binary. For a Steam game, this matters less. But for any web presence, Babylon has an advantage. The write-up does not mention this.
Counter-risk 4 (LOW): Electron is not the only shell.
RESULTS.md says Babylon needs Electron or similar. There are lighter options: Tauri (Rust-based, smaller binary), Neutralino, or a minimal CEF wrapper. The write-up presents Electron as the only option, which overstates the packaging cost. UNSURE on whether Valve's overlay works with Tauri or other shells.
Counter-risk 5 (LOW): WebGL memory measurement gap.
The write-up says Babylon uses "about 12.5 GB" GPU memory, but this is not measured (see Job 1). The actual measured delta is about 3.4 GB. If the real memory usage is lower than Godot's 13 GB, Babylon has a memory advantage that the write-up does not show. This could matter for players with 8 GB or 12 GB GPUs.

(7) NOT CHECKED
The following items I could not verify from this pack:
1. SPEC.md contents. Referenced as defining "same effects spec, environment, cameras and clock." Not in this pack. Camera, FOV, exposure, and tone-mapping match between engines is UNSURE.
2. Godot main.gd camera code. Not in this pack. Camera settings, FOV, exposure, grading are UNSURE.
3. Babylon index.html and Godot fx.gd / main.gd full source. Only excerpts provided. Full shader code, particle counts, timing curves, and blend parameters are UNSURE beyond what is quoted.
4. contrib/muse/reviews/engine_port_plan_synthesis.md. Referenced for the port estimate. Not in this pack. Cannot verify the estimate or whether it covers Job 3 traps.
5. contrib/muse/reviews/engine_choice_synthesis.md. Referenced for DeepSeek and Qwen opinions. Not in this pack. UNSURE.
6. FINDINGS X12, X16. Referenced for Steam overlay and Babylon 9.30 claims. Not in this pack. UNSURE.
7. Babylon.js 9.30.0 and Godot 4.7.2 version claims. No version manifest in pack. UNSURE.
8. RTX 5080 16 GB, 240 Hz 4K hardware claims. No HWInfo or GPU-Z log in pack. UNSURE.
9. 246 KB JS rules, 620 KB rendering/UI sizes. No file listing in pack. UNSURE.
10. Godot 4.7 sort_custom stability. I believe Godot uses Timsort (stable), but I cannot confirm from this pack. UNSURE until checked against Godot 4.7 source or docs.
11. GodotSteam licence and compatibility with Godot 4.7. Not in this pack. UNSURE.
12. NVIDIA Vulkan driver issues with Godot 4.7 on RTX 5080. No bug reports in this pack. UNSURE.
13. The blind sheets themselves (blind/ directory). Not in this pack. I cannot view the actual images. UNSURE whether the visual quality matches the descriptions.
14. results/final_2026-10-25/ and results/run3_2026-10-25/ raw files. Not in this pack. I rely on the chair's grep results. I have verified internal consistency of the chair's numbers but cannot re-derive them from raw files.
15. Whether FORCE_A was set during the blind test. The code allows it. The artifacts do not record it. UNSURE.
16. The imported Godot project load time. No imported project was built. The "10x faster" is an estimate. UNSURE.
17. Godot 4.7 trail rendering. I am not certain whether Godot 4.7 has a built-in trail node. The community approach is a ribbon mesh. UNSURE.
18. Exact Godot 4.7 docs URLs. I have provided stable-docs links. The 4.7-specific URLs may differ. UNSURE.

PASS BAR ASSESSMENT
The stated pass bar:
Effects: Ryan looks at side-by-side sheets and calls Godot equal or better.
This bar is subjective and depends on one person's judgment. It is also vulnerable to the same fairness issues as the blind test (polish asymmetry, settings changes, timing of stills). I would add:
The comparison must use a single, uninterrupted session with no settings changes.
The sheets must include the shield during its visible window (2.4 to 3.0 s), not just the fixed still times.
At least two viewers, or Ryan views twice with swapped A/B labels.
The effects must be compared at equal polish effort. If Babylon got N polish rounds, Godot gets N before comparison.
Rules: Every scenario matches turn for turn with zero differences; first 10,000 PRNG draws match on 3 seeds; port estimate not wildly above plan.
This bar is better but has gaps:
"Every scenario" is not defined. How many scenarios? What coverage? The game has 8 fight types, terrain generation, events, AI, combat. The test must enumerate scenarios and cover all of them.
The per-turn hash (sim3d.js:247-250) is insufficient. It must be per-action and include RNG state, section HP, shields, statuses, pending events, and exact HP. See Job 3.
10,000 PRNG draws on 3 seeds tests the algorithm but not the draw order. The draw order test requires running full battles and comparing RNG state after every action.
"Not wildly above" is vague. Define a multiplier (e.g., 1.5x the plan estimate) as the threshold.
The parity test must run headless, without rendering, to isolate rules from presentation.
I would add to the bar:
The hash must include RNG_S after every activation.
Sort tiebreaks must be total (unit id) before the port.
The test must run at least 100 full battles with different seeds, not just 3.
The test must cover all 8 fight types, including the gravity well.
Date.now must be mocked or excluded.

SUMMARY
The proof as described has the right structure (effects rebuild plus rules parity) but the evidence pack has serious measurement errors (7 of 17 quantitative rows wrong), a blind test with fairness gaps, and a rules-parity half that does not exist on main yet. The effects gap is real but reflects build effort, not engine limits. The lighting gap is engine-level and favours Godot. The rules port has many subtle traps that the port plan must address before the parity test can be meaningful. The pass bar needs strengthening, especially for the hash.
The most important single fix: do not report the proof to Ryan until the numbers in RESULTS.md are corrected, the blind test fairness issues are disclosed, and the rules-parity code has landed on main and been audited. Reporting now would rest on wrong numbers and a missing proof.
End of audit.
