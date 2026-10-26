# Engine proof audit: synthesis (Oct 25c)

Chair: Rey (Muse). Legs, both blind, both filed verbatim: DeepSeek, contrib/deepseek/engine_proof_audit_deepseek_raw_2026_10_25.md (full evidence pack plus babylon_index.html and godot_fx.gd attached, DeepThink ON, Search ON, 129 pages consulted, run 10:23-10:32 PM CDT); Qwen, contrib/qwen/engine_proof_audit_qwen_raw_2026_10_25.md (condensed pack pasted inline in 3 parts at 10:38 PM CDT, Qwen3.8-Max verified by both gates: selector before submission, header after generation started and after completion; one slider CAPTCHA solved on first attempt; run 10:23-10:45 PM CDT). Screenings: hidden_files/engine_proof_audit_deepseek_screening.md and engine_proof_audit_qwen_screening.md. Chair recomputation: every RESULTS.md number checked against the fetched final and round 3 JSONs, Oct 25 night.

Method weight, stated plainly: Qwen worked from the condensed pack and did not re-derive numbers from raw files; its Job 1 is a consistency check against chair values, not an independent recomputation. Independent recomputation rests on the chair plus DeepSeek, and the two agree on every number. Qwen's independent value is in Jobs 2-5 reasoning and its new items. Neither leg had Godot main.gd camera code, so all Job 2 camera, FOV, exposure, and grading verdicts stay UNSURE for both legs.

## Verdict: DO NOT REPORT THE PROOF YET

The proof has the right structure (effects rebuild plus rules parity), but the evidence it would be reported on does not hold up. RESULTS.md has 7 of 17 quantitative rows wrong by Qwen's count, and the chair and DeepSeek agree on each one. The max-detail comparison is contaminated by a build bug. The blind read is a composite of two sessions, not one untouched run. The rules-parity half does not exist on main yet. None of this overturns Ryan's engine call (R28): the lighting conclusion is engine-level and robust, and the effects gap is build effort, not an engine limit. But reporting the proof now would rest on wrong numbers and a missing half. Opus applies the fix list below, then the proof can be reported.

## Fix before the proof is reported

In the order Opus should take them. Each item states the evidence and the fix.

### 1. Correct RESULTS.md, and label every number by round

The table as written mixes the final round and round 3 without saying so, and several rows match no file. Corrected values, all chair-verified from the fetched JSONs:

- Capped dropped frames, max detail 4K: RESULTS says 2 vs 2,472. Files say fb_max_2160_vsync dropped=8 at refresh 178.571 (NOT 240) vs fg_fp_max_2160_vsync dropped=2,468 at refresh 240.0. The two "capped" runs were not measured the same way, and the Babylon row is not a 240 Hz run at all.
- Capped dropped frames, max detail 1440p: RESULTS says 0 vs 64. Files say 0 vs 192.
- Load with 8K ships: RESULTS says 23 s vs 36 s. No Babylon max file in either round shows 23 s (final 6.596, round 3 6.403, and the final run did not load assets/hi anyway, so no Babylon 8K load was measured in the final round). Godot final max load is 38.033/38.067, not 36. Report Babylon 8K load as not measured in the final round, or re-run it; report Godot as 38 s.
- Graphics memory with 8K ships: RESULTS says about 12.5 GB vs about 13 GB. Godot final max gpu_mem_mb=12,960.9 (about 13 GB, correct). Babylon has no GPU counter in WebGL; its final max notes give an nvidia-smi system-wide delta of about 3.4 GB (1,681 MB before, 5,077 MB peak). The 12.5 GB figure has no measurement behind it. Remove it or replace it with the measured delta, labeled as system-wide, not WebGL-specific.
- Average frame, max detail: RESULTS says 5.8 vs 7.4 ms. No pair matches (final uncapped 5.032 vs 7.54; final vsync 5.617 vs 7.574; round 3 4.994 vs 6.666). Pick one measurement, cite its file, and use it.
- Worst 1 percent uncapped, max detail: RESULTS says 21 vs 11 ms. Final max p99 is 27.288 vs 10.97. The 21 is the STRESS row (fb_stress_2160 p99=20.942), wrong-row pairing.
- Standalone .exe 109 MB and 3.7 s cold: both are ROUND 3 values (round 3 README and godot_exe_cold.json 3.706). Final godot_exe_cold.json says 3.085. Label the round on both.
- "Est. 10x faster" for an imported Godot project: no imported project was built or timed in either round. Mark it as an unmeasured estimate, or build the imported project and measure it.
- Rows that DO check out and stay: capped 6 ships 0 vs 0, capped 24 ships 0 vs 4, average frame 6/24/40 ships (rounds correctly from final 2160 uncapped), "about 135 fps" for Godot max (measured 132.62 uncapped / 132.02 vsync, slightly high but in range), "smooth everywhere at 60 fps" as an inference from averages under 16.67 ms, not a measurement.

Fix: either re-run everything in one round under identical conditions, or add a round column to every row. Do not average across rounds.

### 2. Re-run Babylon max with assets/hi, re-shoot the MAX sheets, and re-blind them

The final round README caution states Babylon's max mode did not load assets/hi, so fb_max_* used the old assets and are not comparable. Blind sheets 05-14 (four MAX scenes plus six MAX hero close-ups) were built from those stills. Ryan's "Godot better ship detail" verdict therefore rests, for its MAX portion, on a comparison where Babylon was not using the shared 8K assets. Qualification, not voiding: sheets 01-04 and 15-16 used standard assets on both sides, so the non-MAX portion of the detail verdict is unaffected. Fix: re-run Babylon max with hi=1 and assets/hi loaded, re-shoot the MAX sheets, and re-blind those sheets. If that cannot be done, report the max-detail comparison as not measured and remove the MAX sheets from the blind set.

### 3. Disclose the composite blind, and record the assignment for future blinds

Ryan read sheets 1-6, stopped over Godot's depth of field, both builds changed DoF (off except light on hero shots), Godot's breach was moved onto the hull flank, and sheets were re-shot with the same labels. The final sheets are a composite of two sessions with different settings, and reused labels mean Ryan could in principle remember session 1 images. Separately, blind.py records only the outcome (A = Babylon), not whether FORCE_A was set, and the coin flip uses os.urandom with no recorded seed, so forced vs landed flip is UNKNOWN and unreproducible from the artifacts. Fix: disclose in RESULTS.md that the blind read spans two sessions with a settings change between them. For any future blind, record the seed, log whether FORCE_A was set, hash the key file at creation, and if a setting must change, re-run the entire blind from scratch with new labels. Additional blind hygiene both legs demand: the comparison must use a single uninterrupted session with no settings changes; the shield stills must fall inside the shield's visible window (see item 6); at least two viewers, or Ryan views twice with swapped A/B labels; effects must be compared at equal polish effort.

### 4. Land the rules-parity half before any rules pass is reported

contrib/opus/enginetest/godot_rules/ does NOT exist on main, and tools/pc/ contains no parity.bat (both checked Oct 25 night). The GDScript port, the parity script, and the 10,000-draw test cannot be audited until they land. Fix: land the port, the parity script, and the draw test on main, then audit the port against the Job 3 trap list below. Do not report a rules pass, fail, or "in progress" before that. What CAN be checked now is the JS game-code trap list; what CANNOT is whether the port avoids the traps.

### 5. Strengthen the pass bar before the proof is judged against it

Both legs independently demand the same three changes, and the chair agrees:

- Per-action hash, not per-turn only. The sim3d.js:247-250 fingerprint omits shields, section HP, statuses, RNG state, turn and activation counters, and pending events, and rounds HP to 0.1 (HP 5.04 and 5.05 hash the same). A per-turn hash with those gaps can pass while the state diverges, and can miss an activation-order error that cancels out within the turn. Required hash state: RNG_S as an exact 32-bit value after every activation; every unit field (tpl, q, r, facing, exact HP unrounded, dead, section HP, shield, statuses, weapons fired and cooldowns); turn number and activation index; pending event queue; board shape and full terrain state; well state; combat log entries or their hash; the seed. Exact float bits, not rounded values.
- Scenario coverage, defined, not "every scenario". The test must enumerate and cover all 8 fight types including the gravity well, plus terrain generation, events, AI, and combat. Draw-order testing requires full battles with RNG state compared after every action, not just 10,000 draws on 3 seeds (both legs suggest at least 100 full battles with different seeds as the stronger bar).
- A quantified port-estimate threshold. "Not wildly above the port plan" is vague. Both legs suggest 1.5x the port plan's estimate as the threshold. Adopt a number before judging.
- Effects bar additions: sheets must include the shield during its visible window (2.4-3.0 s), not just the fixed still times; effects compared at equal polish effort (if Babylon got N rounds, Godot gets N before comparison); the parity runs must be headless to isolate rules from presentation; Date.now must be mocked or excluded.

### 6. Fix the Godot shield before the effects proof is judged

Both legs converge on the same top causes, merged here into one ranked list (chair-confirmed against the shader source for items 1-3 and 5):

1. Still timing. The shield event fires at 2.4 s in a 4 s loop and lasts SHIELD_T = 0.6 s, so it is visible roughly 2.4-3.0 s of each loop. Qwen computed all four still phases: battle t=5.0 lands at phase 1.0 (inactive); board and breach t=3.0 land at phase 3.0, the exact end of the window (at most the last fade frame); destruction t=12.6 lands at phase 0.6 (inactive). No blind still falls inside the window. If Ryan's read was sheets-only, timing alone explains "Godot shield not visible". Open question, not a fact: Qwen assumes Ryan also watched real-time playback; R27/R28 describe a sheet read, so confirm whether motion was watched. If it was, items 2-4 rank next.
2. Hemisphere discard plus camera side. The Godot shader discards when dot(d3, hit_dir) < 0.0, so only the hit-facing hemisphere draws. The breach still views the Hegemony port flank while the hit is starboard (hit_dir 0.15, 0.2, -1.0). From the wrong side, the visible sphere can be entirely discarded.
3. Thin, dim rings. Ring width 0.11/0.08 in the shader formula (dist - (0.4 + age * 9.0)) / 0.11, at energy 1.0, vs Babylon's colour multiplied by 2.2 (HDR boost, index.html:946). At 4K a 0.11-unit ring on a ship-scale sphere can be sub-pixel, and unboosted.
4. Depth and render order. The shader uses depth_draw_never and cull_disabled; if render_priority is not set high, the shield can sort behind the hull. Check fx.gd:656 (material creation) for the priority.
5. Material override, scale, and phase. material_override set at fx.gd:1301-1317 vs any material set at :656; radii = half * 1.15 + 1.5 (check against the six flagships' actual extents); visibility toggling at fx.gd:794-795 and the per-frame window at :930-940.

Fix: widen the rings, raise the energy toward Babylon's 2.2 boost, soften or remove the hemisphere discard for still cameras, and shoot a still inside 2.4-3.0 s from the hit side. This is build-level, not an engine limit, and the shield verdict must not be used as evidence that Godot cannot do shields. Note the chair correction to DeepSeek's rank 4: depth_draw_never disables depth writes, not the depth test, so occlusion stays a plausible candidate, not a confirmed mechanism.

### 7. Correct the sort-stability record, and use deterministic tiebreaks

MATERIAL CORRECTION to the Qwen leg, which states Godot docs for sort_custom "use a stable sort (Timsort)", hedged as UNSURE. That belief is wrong. Chair-verified Oct 25 night from the Godot docs Array page: both sort and sort_custom carry the note "The sorting algorithm used is not stable" (sort and sort_custom notes). DeepSeek quoted it correctly. Ruling for the port: Godot sorts are NOT stable, so every sort needs a total tiebreak before porting. Affected sorts: battle.js:864 target sort (no tiebreak), battle.js:1073 activation order (no tiebreak for equal speed and squadron status), battle.js:569 and :1052 (partial tiebreaks). Second correction, inside Qwen's own leg: it proposes unit id from newId as the tiebreak while its own 3i shows newId is Date.now-based and non-deterministic. A Date.now id cannot be a deterministic tiebreak. Tiebreak key must be deterministic (spawn or slot order), NOT newId, unless ids are made deterministic first (incrementing counter, as Qwen's 3i itself recommends).

### 8. Add a trig bit-exactness test before claiming zero-difference parity

DeepSeek-only item, carried as INFERENCE, not measurement, and Qwen's silence on it is not disagreement. V8's Math.sin, Math.cos, and Math.atan2 are not guaranteed to produce the same last bit as Godot's math library. A last-bit atan2 difference can flip a .5 facing boundary (battle.js:260, :277); a last-bit sin difference can change terrain noise (battle.js:167). Options are shared polynomial approximations, precomputed values, or tolerance, but tolerance fails a zero-difference bar. Fix: before reporting parity, run bit-comparison tests on boundary inputs (exact .5 facing cases, terrain noise inputs) comparing raw float bits, not just rounded integers. If the libraries diverge on boundary inputs, the port needs the shared-approximation or precompute route, and the pass bar must say so.

## Job 1 synthesis: number by number

Both legs and the chair agree on every verdict. Qwen's count: 5 right, 7 wrong, 3 not traceable, 1 approximately right, 1 mixes rounds.

- Capped 6 ships 0 vs 0: RIGHT. Capped 24 ships 0 vs 4: RIGHT (4K file; 1440p file says 0, so the row needs its resolution labeled).
- Capped max 4K 2 vs 2,472: WRONG, files 8 vs 2,468, and the Babylon run is not a 240 Hz run (178.571). Qwen adds the mechanism: a frame between 1/240 s and 1/178 s counts as dropped for Godot but not for Babylon.
- Capped max 1440p 0 vs 64: WRONG, files 0 vs 192.
- Average frame 6/24/40: RIGHT (rounds correctly).
- Average frame max 5.8 vs 7.4: WRONG, no pair matches.
- Worst 1 percent max 21 vs 11: WRONG, final max 27.288 vs 10.97; 21 is the stress row.
- Load 23 s vs 36 s: WRONG on both sides (Babylon 23 untraceable; Godot 38.033/38.067, not 36).
- Memory about 12.5 GB vs about 13 GB: Godot RIGHT, Babylon NOT TRACEABLE (no WebGL counter; measured system-wide delta about 3.4 GB).
- Standalone 109 MB: RIGHT for round 3. Cold 3.7 s: MIXED ROUNDS (round 3 3.706, final 3.085).
- "About 135 fps": APPROXIMATELY RIGHT (132.62 uncapped / 132.02 vsync).
- "Smooth everywhere at 60 fps": RIGHT as an inference, not a measurement.
- "Est. 10x faster": NOT TRACEABLE, unmeasured estimate.
- Version claims (Babylon 9.30.0, Godot 4.7.2), hardware claims (RTX 5080, 240 Hz 4K), and size claims (246 KB rules, 620 KB rendering/UI): NOT TRACEABLE from the legs' packs. Honest pack limits, not disagreements: the chair holds the build READMEs and the repo files behind those claims, and Opus can confirm them from the repo. The synthesis does not downgrade them, it marks them unchecked by the legs.

## Job 2 synthesis: was the blind fair?

Verdict, both legs in full agreement: directionally useful, not a clean controlled experiment. Composite sessions (item 3 above), unverifiable coin flip (item 3 above), polish asymmetry, Babylon max asset bug (item 2 above), board stills directory naming (Godot final_g_board_hi vs Babylon final_b_board, effect UNSURE), and missing camera verification (neither leg had main.gd; SPEC.md not in either pack). Qwen's invented "three more polish rounds" is dropped: the pack says "more polish rounds", no number.

Engine-level vs build-effort-level, both legs agree:

- Godot better lighting: mostly ENGINE. Godot's SDFGI, SSIL, SSR, and soft shadows have no direct Babylon equivalent. This conclusion is the most robust in the blind read.
- Godot better ship detail: UNSURE and contaminated for the MAX portion (item 2 above); the non-MAX portion stands on standard assets both sides.
- Godot better asteroids: UNSURE in both legs (lighting vs placement cannot be separated without per-build asteroid counts, which neither pack gives).
- Babylon better effects (breach, smoke, explosions, trails, board laser): BUILD EFFORT. Both engines have the techniques (GPUParticles3D, FogVolume, soft particles, lights on the Godot side); the gap is polish rounds, and the proof phase is the right way to separate effort from engine.
- Chorus and Deathless read better in Babylon: BUILD EFFORT (lighting setup on dark hulls, the fix the proof already includes).
- Godot shield not visible: BUILD BUG plus still timing (item 6 above), not an engine limit.
- Ithar broken in both: ASSET, not an engine issue.

## Job 3 synthesis: rules-parity traps

Both legs agree on the trap list, with the two chair corrections from items 7 and 8. Merged list for the port, with file:line:

1. One global RNG stream, call order is the whole game (core.js:5-6, battle.js:295, battle.js:167, battle.js:303, battle.js:26). Any extra or missing draw anywhere shifts every later draw, including in error paths, early returns, and conditional branches. If cfg.seed is null, battle.js:295 draws once from rnd() to make a seed; if a seed is given, it must not draw.
2. 32-bit arithmetic is not native in GDScript. The pack listed Math.imul, >>>, and |0; DeepSeek added the explicit helper mapping (to_int32, u32, imul32), and Qwen added an imul sketch. The sketch is UNTESTED code, carried as a lead: Opus proves it against the 10,000-draw test, including the signed interpretation of |0 results and the unsigned >>>0 division by 4294967296. GDScript ints are 64-bit; mask to 32 bits and interpret the sign bit, never assume plain >> matches >>> on negatives.
3. Rounding: JS Math.round rounds half toward plus infinity, GDScript round() rounds half away from zero. They differ on every negative .5 input. Facing at battle.js:260 and :277 (atan2 can be negative) can flip on a .5 boundary. Port helper: floor(x + 0.5) replicates JS rounding for finite x (Qwen's js_round; -0.5 maps to 0, matching JS -0 numerically). Apply at all 20-plus Math.round sites.
4. Integer division: JS Math.floor(-1/2) = -1, GDScript -1/2 = 0 (truncation toward zero). Hex math sites battle.js:27-28, :84, :87, :89, :174, :204, :229, :245, :253-256, :296, :332, :335. Port must use floordiv, never plain /.
5. Modulo: battle.js:260 and :277 already normalize with ((x%6)+6)%6. Safe pattern; keep it verbatim in the port.
6. Float order: GDScript float64 matches JS doubles, so the same order gives the same result, but any reordering breaks bit-exactness. Damage chains battle.js:514-528 and :645-646 must be ported in exact order, no simplification or factored subexpressions.
7. Object.keys order feeds randomness: battle.js:26 (BEVENTS), :43 and :49 (region/biome), :312 (boss rock thinning). JS sorts integer-like keys numerically first, then insertion order for strings; GDScript dictionary order must not be assumed to match. Port rule: pin order with explicit arrays, never dictionary iteration. for...in sites battle.js:116 (u.sec keys, fixed order) and core.js:52, :68, :70 (migration, not battle rules) need the same treatment where they touch rules.
8. Sort stability: NOT stable in Godot (item 7 above). Add deterministic total tiebreaks (spawn/slot order) to battle.js:864, :1073, :569, :1052 before porting. Also note the porting-direction trap DeepSeek added: JS val(b)-val(a) descending becomes val(a) > val(b) in a GDScript sort_custom bool context, not val(a) < val(b).
9. Date.now and newId: core.js:19 newId (Date.now) for ids, battle.js:823 stallGuard watchdog, core.js:155 save() and :315 runDefaults campaign meta, sim3d.js:1 performance.now shim, battle.js:910 stall timer and debug log. None are battle rules except through ids: if ids enter battle state, save data, the hash, or sort tiebreaks, parity breaks. Port rule: deterministic incrementing id counter, and mock or exclude timestamps in the parity test.
10. Math.random: absent from battle.js, core.js rules paths, data.js, and sim3d.js rules paths (only core.js:4 initial seed, overridden by rndSeed, and the cosmetic comment at core.js:3). Port rule: ban Math.random from rules paths; cosmetic code must not feed the rules RNG or vice versa.
11. Hash: per-action, with the full state list from item 5 above. The existing sim3d.js:247-250 fingerprint is a starting idiom only.
12. Gravity well: a mechanic, not a backdrop. battle.js:280 wellTick, deadstar shape battle.js:58-65, :181, :236, B.well at :313, board shape in 6 of 8 fight types. Well state and wellTick effects belong in the hash. Any "background only" claim about the gravity well is wrong per the code, and re-confirms R24.
13. Trig bit-exactness: DeepSeek-only test item (item 8 above). Qwen silent, not disagreeing.

## Job 4 synthesis: effects parity

Both legs agree the Godot kit can match every Babylon effect in principle, and the gap is polish, not engine capability. Merged per-effect assessment (Godot 4.7 tools, docs links from the legs; legs cite stable-docs URLs, so Opus re-checks each against the 4.7 branch during the proof):

- Breach: Babylon staged scorch, torn holes, venting, sparks, fire, with parallax occlusion mapping depth. Godot needs staged progression (scorch decal, hole swap, venting particles), not parallax mapping alone. Tools: Decal (Forward+/Mobile only, not Compatibility, so the SCORCH_DISC_SHADER fallback stands), POM hole shader, GPUParticles3D for debris and sparks, FogVolume for venting.
- Smoke and venting: Babylon layered soft particles, fbm noise, smoke rings, soot, 24-step raymarched vent volume. Godot: GPUParticles3D with soft-particle depth fade plus FogVolume vent plume. Gap is layering and polish.
- Explosions: Babylon layered timing, raymarched fireball, flash, rings, embers, debris, point light. Godot: FogVolume fireball, GPUParticles3D shell, shader ring, animated light. Matchable.
- Trails: kits close; Babylon brighter core and more noise detail. Godot ribbon MultiMesh tuning, additive blend with soft fade. Note: no built-in Trail3D node in Godot 4.x per Qwen (UNSURE whether 4.7 added one); the community ribbon approach stands.
- Board laser: close match in both legs; tuning (core brightness, impact flare size), not a new feature.
- Destruction chunks and drifting wrecks: RigidBody3D tumbling chunks with burning-edge shader, GPUParticles3D embers and squibs, persistent wreck drift. Build work, not engine limits.
- Shield: item 6 above.

What makes Babylon read better overall, both legs: more sprite, streak, ring, ribbon, and shard kinds, POM decals, raymarched volumes, per-event point lights, and more polish rounds. Godot's rich mode already has FogVolume, POM holes, and soft particles. The proof's job is to close the polish gap, and it has not been shown yet.

## Job 5 synthesis: ranked risks, both directions

All Godot-side risks below are legs' leads, UNSURE-flagged, with no specific evidence in either pack. None is established fact, and none is carried as a reason to change the call on its own. Ranked by likelihood of changing the call:

1. Rules port effort and correctness (HIGH, both legs). The trap list in Job 3 is long and subtle; if the port takes multiples of the plan estimate, the proof phase drags. Mitigation is item 5's quantified threshold.
2. Babylon max asset bug invalidating the detail verdict (HIGH, DeepSeek's top risk; chair agrees it is the single biggest threat to the decision's evidence, though not to the call itself). Covered by item 2 above.
3. Unclean blind (HIGH, both legs). Covered by item 3 above.
4. Babylon 9.30 lighting stack possibly under-exercised (MEDIUM-HIGH, DeepSeek). Babylon 9.0 added clustered lighting, volumetric lighting, frame graph, and node particles; whether the max build enabled volumetric lighting and frame graph is UNSURE. If it did not, the lighting comparison is not a ceiling test for Babylon. Opus states which 9.30 features were enabled in max mode.
5. GodotSteam licence change (MEDIUM, both legs, DeepSeek-sourced). GodotSteam is currently MIT, but its site says it drops MIT in the upcoming 4.20 for a custom licence. Review before shipping; also verify overlay support in the exported build for the exact Godot 4.7 version, not the editor. Overlay non-support for browser-tech games itself rests on the Valve doc (X12); DeepSeek's community-discussion citation is weaker and is NOT carried as the source.
6. Godot 4.7 Vulkan/NVIDIA issues (MEDIUM, both legs, DeepSeek-sourced issues 121503, 124526, 124130). None confirmed on the RTX 5080 proof machine. Test the proof machine and keep a Compatibility fallback in view.
7. Save-file migration (LOW-MEDIUM, both legs). Format and player count unknown; pre-release status would make this low. Port plan needs a versioned migration path if saves exist.
8. Test tooling (LOW-MEDIUM, both legs). parity.bat does not exist yet; the check pack and the parity harness are both needed, not one replacing the other. GDScript testing via GUT is a community addon, not in the box.
9. Editor workflow (LOW, both legs). Visual editor is a real benefit and a workflow change; scene text format and review keep it manageable.
10. Export size and startup (LOW, Qwen). 109 MB and 3.7 s (round 3) are normal for a native game.

Reverse: things that make Babylon 9.30 look better than the write-up says:

- Staying costs nothing to move to 9.30 (X16), and the 246 KB rules plus 620 KB rendering/UI stay as they are. Real cost saving, underweighted in the write-up.
- Babylon's effects are already built and polished; the Godot rebuild is the proof task, and if it drags, the team has spent weeks for parity.
- Lighter shells than Electron exist (Qwen lead, UNSURE on overlay): Tauri, Neutralino, minimal CEF wrapper. The write-up's "Electron or similar" overstates packaging cost, but overlay support for those shells is unproven.
- Web deployment (Qwen lead): instant updates, no install, marketing pages. Matters less for a Steam game, unmentioned in the write-up.
- Memory (Qwen lead): if Babylon's real usage is the measured about 3.4 GB system-wide delta rather than the untraced 12.5 GB, Babylon has a memory advantage the write-up hides. Matters for 8 GB and 12 GB GPUs. Re-measure properly before claiming it.

Both engines are free (Godot MIT, Babylon Apache 2.0), no royalties. Licence risk is GodotSteam, not the engine.

## Agreement and disagreement map

- Job 1 numbers: chair, DeepSeek, Qwen in full agreement on every verdict.
- Job 2 fairness: full agreement, including the composite blind, unverifiable flip, polish asymmetry, board _hi naming, and camera UNSURE.
- Job 3 traps: agreement on the full list except sort stability, where DeepSeek and the chair are correct (not stable, docs-verified) and Qwen's "Timsort stable" belief is wrong, corrected in item 7. Qwen's id-tiebreak proposal is internally contradicted by its own newId finding, corrected in item 7.
- Job 4 shield: convergence on the top causes (timing, discard plus camera side, thin/dim rings). Ordering differs between legs; item 6 merges them.
- Job 5: agreement on GodotSteam, Vulkan/NVIDIA, save migration, editor workflow, and test tooling as UNSURE-flagged leads. Qwen adds the shell, web, and memory counter-risks.
- Pass bar: both legs independently demand per-action hash with RNG state, defined scenario coverage, and a quantified port-estimate threshold (both suggest 1.5x).
- Trig bit-exactness: DeepSeek only, INFERENCE, unmeasured. Qwen silent, not disagreeing.
- DeepSeek's overlay citation (community discussion) is superseded by X12's Valve doc as the source; the conclusion (browser-tech games unsupported without a native shell) is unchanged.
- Qwen's "three more polish rounds" is dropped as invented; the pack says "more polish rounds" with no number.
- Qwen's "Ryan also watched real-time playback" is an assumption, not pack evidence; item 6 carries it as an open question.

## What Opus applies, in order

1. Correct RESULTS.md per item 1 (round labels, corrected values, estimate flags).
2. Re-run Babylon max with assets/hi, re-shoot MAX sheets, re-blind (item 2).
3. Disclose the composite blind and record assignment data going forward (item 3).
4. Land godot_rules and parity.bat, then audit the port against the Job 3 list (item 4).
5. Adopt the strengthened pass bar (item 5) before judging the proof.
6. Fix the Godot shield per item 6 and shoot a shield-visible still.
7. Add deterministic total tiebreaks to every sort before porting (item 7).
8. Run the trig bit-exactness boundary tests (item 8).
9. State which Babylon 9.30 lighting features were enabled in max mode (Job 5 item 4).
10. Review GodotSteam licence and overlay support for the exact 4.7 version before shipping decisions (Job 5 item 5).

## Not checked

- The GDScript port itself, the parity script, and the 10,000-draw test: not on main, cannot be checked yet.
- Godot main.gd camera code, SPEC.md contents, and the build READMEs: not in either leg's pack. Camera, FOV, exposure, grading, and tone-mapping match between engines stay UNSURE.
- Whether FORCE_A was set: unrecorded in the artifacts, UNKNOWN.
- Per-build asteroid counts and placement: not in either pack, so the asteroid verdict cannot be split between engine lighting and build placement.
- Save format and existing save count: unknown, so migration risk stays UNSURE.
- GodotSteam future update pace for 4.8 and later: current docs cover 4.7, future lag UNSURE.
- Whether the RTX 5080 proof machine hits the reported Godot Vulkan issues: no RTX 5080-specific report found, UNSURE.
- Whether Babylon max mode enables all of Babylon 9.30's new lighting features: UNSURE (see item 9 above).
- Performance of the Godot shield fix: identified causes are evidence-based, not measured.
- Qwen's imul sketch: untested code, a lead for the draw test, not verified code.
- Exact Godot 4.7 docs URLs: legs cite stable-docs URLs; Opus re-checks each against the 4.7 branch.

## Sources

- Legs: contrib/deepseek/engine_proof_audit_deepseek_raw_2026_10_25.md and contrib/qwen/engine_proof_audit_qwen_raw_2026_10_25.md, with working copies in their reviews/ folders.
- Chair evidence: results/final_2026-10-25/ and results/run3_2026-10-25/ JSONs and READMEs, blind.py, SPEC.md, game files core.js, battle.js, data.js, sim3d.js, Babylon index.html shield code, Godot fx.gd shield code, all fetched Oct 25 night.
- Prior record: contrib/opus/FINDINGS.md R18-R28, X12, X16; contrib/muse/reviews/engine_port_plan_synthesis.md (port plan, referenced but not re-audited here).
- This synthesis does not edit any filed leg. Corrections to legs live here and in the screening notes only.
