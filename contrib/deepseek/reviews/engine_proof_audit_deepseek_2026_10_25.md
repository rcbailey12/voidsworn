# Raw return: engine proof audit, DeepSeek, Oct 25, 2026

Source: fresh DeepSeek chat (chat.deepseek.com), DeepThink ON and Search ON verified by toggling (DeepThink confirmed by toggling off and back on), all three files attached (evidence_pack_25c.md, babylon_index.html, godot_fx.gd), 69 seconds of DeepThink reasoning, 129 pages consulted. Run 10:23-10:32 PM CDT, harness-measured. Filed verbatim below; the working copy is reviews/engine_proof_audit_deepseek_2026_10_25.md.

Blind Outside Review: Engine Proof Audit, Evidence Pack 25c

I worked only from the pack and the two attached source files, plus primary sources checked online. I did not assume any conclusion from RESULTS.md. Where the pack does not contain the evidence needed, I say so and mark it UNSURE.

## 1. Fix before the proof is reported

These are ordered by how badly they can make the proof pass when it should fail, or fail for a fixable reason.

**1.1 The Babylon max-detail rows are not comparable, and RESULTS.md reports them without the warning.** The final round README itself says: "Babylon's max mode did not load assets/hi in this round (a build bug, being fixed), so fb_max_* used the old assets and are not comparable." The blind sheets include five MAX sheets and six MAX hero close-ups built from those same stills (blind.py PAIRS entries 05 to 14). Ryan's "Godot better ship detail" verdict was made on a comparison where Babylon was not using the shared 8K assets. That is the single biggest threat to the validity of the decision.

Fix: re-run Babylon max with hi=1 and assets/hi loaded, re-shoot the MAX sheets, and re-blind those sheets before reporting. If that cannot be done, report the max-detail comparison as not measured and remove the MAX sheets from the blind set.

**1.2 The blind was not a single untouched run.** Ryan read sheets 1 to 6, stopped over Godot's depth of field, both builds changed DoF (off except light on hero shots), Godot's breach was moved onto the hull flank, and the sheets were re-shot with the same labels. One build changed its breach placement after feedback, and labels were reused across versions. That is not a clean blind comparison.

Fix: run a fresh blind with one version of each sheet, identical post-processing settings, and a key file that records the build hashes and whether FORCE_A was used. Do not reuse labels across versions.

**1.3 The blind key does not record whether FORCE_A was used.** blind.py sets babylon_is_A = (os.environ['FORCE_A'] == 'babylon') if os.environ.get('FORCE_A') else rng.random() < 0.5, and the key file records only the outcome, not whether the environment variable was set. A forced order is not necessarily unfair, but it cannot be verified from the artifacts.

Fix: record FORCE_A in the key file, or run with the coin flip and record the random seed.

**1.4 Godot's board stills use a _hi source directory, Babylon's do not.** blind.py uses B['board'] = 'final_b_board' and G['board'] = 'final_g_board_hi'. The directory name suggests the Godot board stills may use the high-detail ships while the Babylon board stills do not. The pack flags this as a "small asymmetry"; I cannot inspect the images, so I mark the effect UNSURE, but the naming is evidence of a possible bias.

Fix: confirm the asset level of both board stills and use the same level for both engines.

**1.5 RESULTS.md mixes rounds without saying so.** The 109 MB standalone .exe and 3.7 s cold load come from the round 3 README and round 3 godot_exe_cold.json, not from the final round. The final round godot_exe_cold.json says 3.085 s. The 36 s Godot max load is not the final round either (final is 38.033 and 38.067 s), and round 3's 5.495 s max load used standard assets, not 8K ships. The 23 s Babylon max load appears in neither round.

Fix: report one round at a time, state the round and asset set for every number, and do not carry numbers across rounds without a label.

**1.6 The rules-parity half has not landed on main.** contrib/opus/enginetest/godot_rules/ does not exist on main, and tools/pc/ contains no parity.bat (both checked Oct 25 night). The proof cannot be reported as passed for rules parity. What can be checked now is the JS game code traps (Job 3). What cannot be checked is the GDScript port itself, the per-turn hash script, and the 10,000-draw test.

Fix: land the port, the parity script, and the draw test on main, then run the audit on the actual port. Do not report a rules pass before that.

**1.7 The pass bar is not strong enough in two places.** The effects bar is "Ryan calls Godot equal or better", which is a product decision, not a proof. That is acceptable for the decision but it should not be called a proof. The rules bar is stronger on the PRNG draws (10,000 on 3 seeds) but weaker on state coverage: the current sim3d.js hash omits shields, section HP, statuses, RNG state, turn and activation counters, and pending events, and rounds HP to 0.1. A per-turn hash with those omissions can pass while the real state differs. I would add: a per-action hash, RNG state in the hash, exact HP (not rounded), all shields, sections, statuses, weapons fired, pending events, activation order, and a differential fuzzer over random action sequences. See Job 3 for the full list.

## 2. Job 1: RESULTS.md number by number

I checked every number I could trace to results/final_2026-10-25/ and results/run3_2026-10-25/. Where a number appears in neither round, I mark it "not traceable".

**2.1 Capped 240 Hz dropped frames, max detail: RESULTS says 2 vs 2472.**
- Babylon final fb_max_2160_vsync says dropped=8, refresh=178.571, not 240. The "2" is wrong.
- Godot final fg_fp_max_2160_vsync says dropped=2468, refresh=240. The "2472" is wrong by 4.
- At 1440p, RESULTS says 0 vs 64. Final fg_fp_max_1440_vsync says dropped=192. The "64" is wrong.
- The 6-ship row (0 vs 0) matches fb_main_2160_vsync and fg_fp_main_2160_vsync. The 24-ship row (0 vs 4) matches fg_fp_stress_2160_vsync. Those two rows are right.
Verdict: partly right. The 6-ship and 24-ship rows are right. The max-detail 4K and 1440p rows are wrong, and the Babylon 4K row is not even a 240 Hz run.

**2.2 Load with 8K ships: RESULTS says 23 s vs 36 s.**
- No Babylon max file in either round shows 23 s. Final fb_max_2160 load_s=6.596; round 3 babylon930_max_2160 load_s=6.403. The 23 s is not traceable.
- Godot final fg_fp_max_2160 load_s=38.033 and fg_fp_max_2160_vsync load_s=38.067, not 36. Round 3 godot3_fp_2160_max load_s=5.495, but round 3 max used standard assets, not 8K ships. The 36 s is not traceable either.
Verdict: both numbers wrong or not traceable.

**2.3 Graphics memory with the 8K ships: RESULTS says about 12.5 GB vs about 13 GB.**
- Godot final fg_fp_max_2160 gpu_mem_mb=12960.9, which is about 13 GB. Right.
- Babylon has no GPU counter (WebGL). The final max notes say nvidia-smi total 1681 MB before launch, 5077 MB peak (+3396 MB). Nothing near 12.5 GB appears for Babylon. The 12.5 GB is not traceable.
Verdict: Godot side right, Babylon side wrong or not traceable.

**2.4 Average frame, max detail: RESULTS says 5.8 vs 7.4 ms.**
- Final max 2160: 5.032 vs 7.54.
- Final max 2160 vsync: 5.617 vs 7.574.
- Round 3 max: 4.994 vs 6.666.
None of these pairs is 5.8 vs 7.4. The 5.617 is close to 5.8 but the Godot side is 7.574, not 7.4. No pair matches.
Verdict: wrong.

**2.5 Worst 1 percent uncapped, max detail: RESULTS says 21 vs 11 ms.**
- Final max 2160 p99 is 27.288 vs 10.97.
- Round 3 max p99 is 26.515 vs 9.099.
- The 21 matches the STRESS row: final fb_stress_2160 p99=20.942. The 11 is close to the final max Godot 10.97 but the Babylon value is from the wrong row.
Verdict: wrong pairing. The Babylon 21 is a stress number, not a max number.

**2.6 Standalone Windows build: RESULTS says 109 MB .exe, 3.7 s cold to first frame.**
- 109 MB appears in the round 3 README and the Godot README ("sandbox export: 109 MB exe plus 0.2 MB wrapper"), not in any JSON.
- 3.706 s matches round 3 godot_exe_cold.json. Final godot_exe_cold.json says 3.085 s.
Verdict: both numbers are traceable to round 3, but RESULTS.md does not say it is mixing rounds. Mark as right for round 3, wrong for the final round.

**2.7 "An imported Godot project uses compressed textures, est. 10x faster" for the 38 s Godot max load.**
- No measurement of an imported project appears in either round. There is no import step, no compressed texture run, and no timing. The 10x is an estimate.
Verdict: not traceable. Mark as an unmeasured estimate, not a result.

**2.8 Average frame, 6 / 24 / 40 ships: RESULTS says 1.1 / 2.0 / 2.6 vs 2.2 / 3.2 / 3.7 ms.**
- Final 2160 uncapped: 1.085 / 1.961 / 2.613 vs 2.175 / 3.248 / 3.727. These round correctly.
Verdict: right.

**2.9 "Both are smooth everywhere at 60 fps; at 240 Hz Godot's max mode runs about 135 fps."**
- The 135 fps is close to final fg_fp_max_2160 fps=132.62 and fg_fp_max_2160_vsync fps=132.02. "About 135" is approximately right.
- "Smooth everywhere at 60 fps" is an inference from average frame times below 16.7 ms, not a measured "smoothness" verdict. It is reasonable but should be labelled as an inference.
Verdict: the 135 is approximately right; the 60 fps smoothness is an inference, not a measurement.

**2.10 The 24-ship capped row (0 vs 4) and the 6-ship capped row (0 vs 0).**
- 6-ship: fb_main_2160_vsync dropped=0; fg_fp_main_2160_vsync dropped=0. Right.
- 24-ship: fg_fp_stress_2160_vsync dropped=4. The table does not say 4K, but the stress 4K file matches. Right if the row is 4K; UNSURE if it is 1440p, because fg_fp_stress_1440_vsync dropped=0.
Verdict: right, with a resolution ambiguity.

**2.11 Pass bar audit.**
- Effects: "Ryan, looking at open side-by-side sheets, calls Godot's effects equal or better." This is subjective and depends on Ryan's eye. It is a valid product decision but not a repeatable test. It also depends on the sheets being fair, and they are not (see 1.1 to 1.4).
- Rules: "Every scenario matches turn for turn with zero differences, the first 10,000 PRNG draws match on 3 seeds, and the estimate for porting the rest is not wildly above the port plan's." The PRNG draw test is a good smoke test, but 10,000 draws on 3 seeds does not cover the full call order of a long battle. "Every scenario" is only as strong as the scenario set. "Not wildly above" is not quantified.
- What I would add: a fixed adversarial scenario set that covers every fight type, the gravity well, boarding, retreat, and capture; a differential fuzzer that runs thousands of random action sequences and compares per action, not per turn; a per-action hash that includes RNG state; and a hard budget for the remaining port estimate (for example, no more than 1.5x the port plan's estimate).

## 3. Job 2: was the blind test fair?

**3.1 The mechanics of the blind.** blind.py chooses babylon_is_A by coin flip unless FORCE_A is set. The key file records only the outcome. The pack says both builds' READMEs are not in this pack, so I cannot verify the cameras, clock, exposure, DoF, or TAA settings from the builds. I have the Babylon source and the Godot effects source, but not the Godot main.gd camera code. That limits this verdict.

**3.2 Same assets, cameras, clock and exposure.** The spec says the same frame times and a fixed clock. The Babylon build uses battlePose(t) with STILL_POSE forcing the main orbit radius 150 and height 70 for stills, and closePose() and breachPose() for close-ups. The Godot build's camera code is not in the pack. The pack's Job 2 facts say the builds' READMEs are not in the pack. I cannot confirm that the Godot camera poses, FOV, exposure, and grading match Babylon's. UNSURE.

**3.3 Depth of field and TAA.** Babylon's final build enables DoF only on the six hero shots and uses dofNeutral() everywhere else, including close_20 and breach_30. TAA is off because the custom effect shaders do not write the prepass. Godot's DoF and TAA settings are not in the pack. After the focus fix, both builds set DoF off except light on hero shots, but the exact Godot settings are unknown. TAA on Godot could sharpen or blur the image relative to Babylon. UNSURE.

**3.4 Effects polish rounds are not equal.** The brief says Babylon got more polish rounds than Godot's effects build. The Babylon source shows many tuned layers (sprite kinds, streak kinds, ring kinds, ribbon kinds, shard kinds, POM decal, raymarched volumes, event lights, clustered lights). The Godot source also has many kinds and a rich mode, but the brief says it had fewer polish rounds. This is build-effort-level, not engine-level.

**3.5 Which of Ryan's conclusions are engine-level and which are build-effort-level.**
- Godot better lighting: mostly engine-level. Godot's SDFGI, SSIL, SSR and soft shadows are engine features; Babylon 9.30 has SSAO2, SSR, contact shadows, IBL and clustered lighting, but the Godot GI stack is stronger for this scene. The dark Chorus and Deathless hulls under Godot are a build and lighting fix, not an engine limitation, because the same assets can be lit differently. So: lighting advantage engine-level, dark-hull exception build-level.
- Godot better ship detail: UNSURE and contaminated. Both engines use the same 8K assets, so any difference should be rendering, not asset quality. But Babylon's max mode did not load assets/hi in the final round, so Babylon was showing the old assets. That is a build bug, not engine-level. Until Babylon max is re-run with assets/hi, this conclusion cannot be treated as engine-level.
- Babylon better effects: build-effort-level. The pack says Babylon's effects got more polish rounds, and the source shows a deeper effects kit. The same effects can be rebuilt in Godot; the proof is supposed to do that. So this is not an engine-level verdict.
- Better asteroids on Godot: UNSURE. The asteroids are shared assets. If Godot's lighting makes them read better, that is engine-level. If the Godot build places more or larger asteroids, that is build-level. The pack does not give the asteroid counts per build.
- Ithar broken by its source mesh: asset-level, not engine-level.
- Godot shield not visible enough: build-level, not engine-level. See Job 4.
- Chorus and Deathless read better on Babylon: build-level lighting issue on Godot, not engine-level.

**3.6 Fairness verdict.** The blind is not clean. The Babylon max asset bug, the mid-run DoF and breach changes, the reused labels, the unknown FORCE_A, and the Godot board _hi directory asymmetry all weaken it. The lighting conclusion is largely engine-level and is probably robust. The ship-detail conclusion is not robust because of the Babylon max bug. The effects conclusion is build-effort-level and should not be used as an engine-level reason to stay on Babylon. I would not report the blind as a fair engine comparison until the Babylon max assets are fixed and a fresh blind is run.

## 4. Job 3: rules-parity traps

The GDScript port is not on main, so I cannot check the port itself. I checked the JS game code from the pack's grep results and the attached evidence. Every file:line below is from the pack's references to core.js, battle.js, sim3d.js, and data.js. I mark the traps the chair did not mention.

**4.1 The PRNG is one global stream and call order is the whole game.** core.js:5-6 defines rndSeed(s) and rnd(). rnd() uses a 32-bit state, Math.imul, |0, and >>>. The port must reproduce the exact draw order, not just the algorithm. Any extra or missing draw in terrain generation, deployment, events, AI, or combat shifts every later draw. This is the highest-risk trap.

**4.2 32-bit arithmetic is not native in GDScript.** The chair mentions Math.imul but I do not see an explicit warning about |0 and >>> in the pack. This is a trap the chair missed. RNG_S=(RNG_S+0x6D2B79F5)|0 wraps to signed 32-bit. GDScript int is 64-bit and |0 does not exist. >>> is an unsigned shift; GDScript >> on a negative number is arithmetic and fills with ones. The port must implement to_int32(x), u32(x), and imul32(a,b) with masks, and use (u32(x) >> n) for >>>. If the port uses plain int and >>, the PRNG will diverge immediately. This is a must-fix.

**4.3 Math.round vs GDScript round().** JS rounds half toward plus infinity. GDScript round() rounds halfway cases away from zero, per the Godot docs: "Rounds x to the nearest whole number, with halfway cases rounded away from 0." (https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#class-globalscope-method-round). For negative .5 inputs they differ. battle.js:260 and :277 compute facing with Math.round(Math.atan2(y,x)*180/Math.PI/60), and atan2 can return negative angles. A .5 boundary can flip a facing. The port must implement a JS-compatible round: floor(x + 0.5) for finite x, with care for -0.5 (JS gives -0, GDScript floor(-0.5+0.5)=0, which is numerically the same facing).

**4.4 Math.floor(r/2) vs GDScript integer division.** JS Math.floor(-1/2) is -1. GDScript / on integers truncates toward zero, so -1/2 is 0. The pack lists battle.js:27-28, :84, :87, :89, :174, :204, :229, :245, :253-256, :296, :332, :335. The port must use floori(r / 2.0) or @warning_ignore("integer_division") plus a floor, never plain /. The pack notes onBoard guards r<0 at :87, but offToAx is also called from cut-set code, so negative rows can reach these calls.

**4.5 Modulo on negatives.** battle.js:260 and :277 already normalize with ((x%6)+6)%6, which is safe in both languages. Any unnormalized % is a trap, because JS % and GDScript % both return a result with the sign of the dividend, but the values can differ for negative operands. The port should use the same normalization.

**4.6 Float order.** GDScript floats are 64-bit like JS doubles, so the same order gives the same result. Any reordering, including a "simplified" port that changes the order of multiplication, breaks bit exactness. battle.js:514-528 and :645-646 chain damage math. The port must keep the exact order. The pack's note that GDScript does not reassociate is correct, but a human can still reorder. This is a review trap, not a compiler trap.

**4.7 Math.min / Math.max with NaN and empty spreads.** battle.js:488 uses Math.max(0,...near.map(...)), which is safe because of the leading 0. If the port writes max(array) on an empty array, GDScript may error or return a different value. The port should keep the leading 0 and use maxf(0.0, ...). Also check any Math.min with NaN: GDScript min() with NaN may propagate differently. UNSURE without the port.

**4.8 Object.keys order.** JS preserves insertion order for string keys, but integer-like keys are sorted numerically first. GDScript Dictionary preserves insertion order. battle.js:26 uses pick(Object.keys(BEVENTS)); :43 and :49 pick regions and biomes from Object.keys; :312 iterates Object.keys(T) for boss rock thinning. If the port uses a Dictionary and the key set is all strings, the order may match. If any key is integer-like, JS and GDScript may differ. The port must pin the order explicitly with an array, not rely on dictionary iteration. This is a real trap.

**4.9 Sort stability.** JS Array.sort is stable. Godot's Array.sort and sort_custom are not stable, per the Godot docs: "The sorting algorithm used is not stable. This means that values considered equal may have their order changed when calling this method." (https://docs.godotengine.org/en/stable/classes/class_array.html). battle.js:864 target sort uses ts.sort((a,b2)=>val(b2)-val(a)) with no tiebreak. battle.js:1073 activation order uses alive('enemy').sort((a,b)=>(a.isSq?0:1)-(b.isSq?0:1) || b.speed-a.speed) with no tiebreak for equal speed and squadron status. battle.js:569 and :1052 have partial tiebreaks. Equal ties resolve by input order in JS and may resolve differently in GDScript. The port must add a total key (for example unit id) before sorting, or prove stability from the docs. The docs say it is not stable, so add the tiebreak.

**4.10 Date.now in rules paths and ids.** battle.js:823 uses Date.now for stallGuard, a watchdog, not rules. core.js:19 newId uses Date.now for ids. core.js:155 save() and core.js:315 runDefaults t0 use Date.now for campaign meta, not battle rules. sim3d.js:1 shims performance.now to Date.now; battle.js:910 uses performance.now only for a stall timer and a debug log. The question is whether unit ids or timestamps enter battle state, save data, or the parity hash. If newId is used for units, the ids will differ between runs and between engines. The port must replace newId with a deterministic counter or seed-based id. If the hash includes unit ids, parity will fail. Even if the hash does not include ids, ids used as sort tiebreaks will change order. This is a high-risk trap.

**4.11 Math.random in rules paths.** The pack says no Math.random appears in battle.js, core.js rules paths, data.js, or sim3d.js rules paths, only core.js:4 initial seed and the cosmetic comment at core.js:3. I cannot independently grep the full files, but the pack's reasoning is consistent: rndSeed(seed) overrides the initial seed for seeded runs. The port must ban Math.random and use only the seeded stream.

**4.12 Trigonometric functions are not bit-identical across languages.** This is a trap the chair missed. battle.js:167 uses Math.sin and Math.cos for terrain noise; battle.js:260 and :277 use Math.atan2 for facing. V8's Math.sin, Math.cos, and Math.atan2 are not guaranteed to produce the same last bit as Godot's math library. A last-bit difference in atan2 can flip a .5 rounding boundary and change a facing. A last-bit difference in sin can change terrain noise and therefore combat. This is the hardest trap to fix. Options: implement the same polynomial approximations in both languages, precompute the values, or accept a tolerance. But the bar is zero differences, so a tolerance is not a pass. The port should at least test the exact inputs that reach rounding boundaries and compare the raw floating-point bits, not just the rounded integers. I mark this as a serious risk and a likely source of false parity failures or false passes.

**4.13 Array.sort comparator direction.** This is a common porting trap. JS comparators return negative, zero, or positive. GDScript sort_custom expects a bool "less than". battle.js:864 sorts descending with val(b2)-val(a). The GDScript port must write val(a) > val(b) for descending, not val(a) < val(b). If the port copies the JS expression into a bool context, the order may reverse. Check every sort.

**4.14 undefined vs null.** GDScript has no undefined; a missing dictionary key is null. battle.js:295 uses cfg.seed!=null, which treats both null and undefined as absent. In GDScript, a missing key is null, so the check works. But if a JS field is explicitly undefined and the port maps it to null, any != null check changes meaning. The port must map undefined and null consistently and document the mapping.

**4.15 The hash is too thin.** sim3d.js:247-250 hashes: JSON.stringify([s0, B.shape, Object.keys(B.terrain).sort().join(';'), B.units.map(u=>[u.tpl,u.q,u.r,u.facing,Math.round(u.hp*10),u.dead?1:0,u.weapons.map(w=>w.fired?1:0).join('')]), B.log.map(x=>x.m)]). It omits shields, section HP, statuses, RNG state itself, turn and activation counters, pending events, and it rounds HP to 0.1. A per-turn hash with those omissions can pass while the real state differs. For example, a shield value could be wrong, a section could be destroyed, or a status could be missing, and the hash would not see it. The RNG state is especially important: if the RNG state differs but the visible state matches at the end of the turn, the next turn will diverge.

**4.16 Per-turn vs per-action, and what must be in the hash.** Per-action is required. A per-turn hash can miss an error that is corrected within the turn, and it can miss an error in an intermediate state that only affects later turns through RNG consumption. The hash should be computed after every action, not just every turn. Required state:
- RNG state RNG_S as an exact 32-bit value.
- All unit fields: tpl, q, r, facing, exact hp (not rounded), dead, shield, section HP, statuses, weapons[].fired, and any cooldowns.
- Terrain, well state, board shape.
- Turn counter, activation order, pending events, and any flags.
- The action log or a hash of the action sequence, so the same state reached by different actions is distinguishable.
- Unit ids if they are used in sort tiebreaks, or a deterministic id that is part of the state.
The hash must be exact, not rounded, and must include the RNG state. Otherwise a pass does not mean what the proof needs it to mean.

**4.17 What can be checked now and what cannot.** The game code traps above can be checked now from the JS. The GDScript port, the parity script, the per-turn hash, and the 10,000-draw test cannot be checked until godot_rules/ and tools/pc/parity.bat land on main. Do not report a rules pass before that.

## 5. Job 4: effects parity, per effect

Babylon's effects live in the attached babylon_index.html. Godot's effects live in the attached godot_fx.gd. Both are on main. I compare the kits and say what makes Babylon read better, the best Godot 4.7 way to match, and why the Godot shield may be invisible.

**5.1 Breach.** Babylon uses a custom decal shader with parallax occlusion mapping (POM), a jagged hole, a glowing torn edge, a charred ring, soot, torn petals bent outward, venting gas sprites, debris shards, licking fire, spark showers, and a secondary pop (index.html decal shader and per-ship breach block). The POM gives the hole real depth, which reads better than a flat decal. Babylon also uses a depth pass for soft particles and a decal with zOffset = -3.
Godot's default breach uses a Decal node with albedo, emission, and normal textures (fx.gd _build_breach, d.texture_albedo = tex["alb"], d.texture_emission = tex["emi"], d.texture_normal = tex["nrm"]). The normal map gives some depth, but it is not parallax occlusion mapping. Godot's rich mode has a HOLE_SHADER with POM (fx.gd HOLE_SHADER), a FogVolume for venting (VENT_FOG), and torn plates. The rich mode is a closer match to Babylon, but the pack says the Godot effects build had fewer polish rounds.
Best Godot 4.7 way to match: keep the Decal for the scorch and soot, use the POM hole shader for the cavity (Godot shader docs: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html), use GPUParticles3D for debris and sparks (https://docs.godotengine.org/en/stable/classes/class_gpuparticles3d.html), and use a FogVolume with a fog shader for venting (https://docs.godotengine.org/en/stable/classes/class_fogvolume.html and https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/fog_shader.html). Note that Godot Decal is only supported in Forward+ and Mobile, not Compatibility, per the Godot decal docs: https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html. The pack's SCORCH_DISC_SHADER fallback is the right approach for Compatibility.

**5.2 Smoke and venting.** Babylon uses soft particles with depth fade (#ifdef SOFT in the sprite shader), fbm noise, smoke rings, soot coughs, and a 24-step raymarched vent volume in rich mode. The smoke reads better because it has multiple layers: dark smoke, pale vent gas, soot, and a volumetric vent plume. Godot has GPUParticles3D smoke with a SMOKE_SHADER that uses fbm noise and a domed normal, soft particles in rich mode (SOFT in fx.gd), and a FogVolume vent plume in rich mode (VENT_FOG). The gap is mainly polish and layering, not capability.
Best Godot 4.7 way: GPUParticles3D with ParticleProcessMaterial for the smoke puffs, a soft-particle shader that reads the depth texture (Godot particle shaders: https://docs.godotengine.org/en/stable/tutorials/shaders/particle_shaders.html), and a FogVolume for the volumetric vent. Godot's volumetric fog requires Environment.volumetric_fog_enabled = true and is only supported in the Clustered Forward backend, per the Godot docs: https://docs.godotengine.org/en/stable/classes/class_fogvolume.html and the volumetric fog tutorial: https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html.

**5.3 Explosions.** Babylon uses a flash sprite, a fireball core, two shockwave rings, a rolling fireball with dark smoke, embers, debris shards, and a point light. The explosion reads better because of the layered timing and the raymarched fireball volume in rich mode. Godot has fireball particles, smoke, embers, debris, a shockwave shader, a flash glow, and a FogVolume fireball in rich mode (FIREBALL_FOG). The Godot kit can match the parts, but the pack says Babylon's explosions read better, likely because of polish and the volumetric fireball.
Best Godot 4.7 way: GPUParticles3D for the fireball, smoke, embers, and debris; a mesh shader for the shockwave ring; a FogVolume with a fog shader for the fireball volume. The Godot fog shader docs: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/fog_shader.html.

**5.4 Engine trails.** Babylon uses ribbons with noise, waver, flicker, a hot core, and a long cooling trail. Godot uses ribbon MultiMesh instances with a similar shader (RIBBON_SHADER), noise, waver, flicker, and a decay. The kits are close. The pack says Babylon's trails read better, likely because Babylon's ribbon shader has a brighter core and more detailed noise. Best Godot 4.7 way: keep the ribbon MultiMesh, increase the core brightness and the noise detail, and use additive blending with a soft fade. Godot MultiMesh docs: https://docs.godotengine.org/en/stable/classes/class_multimesh.html.

**5.5 Board laser.** Babylon uses a beam ribbon with a white core, a faction glow, a charge flare, an impact flare, and sparks. Godot uses beam_core and beam_glow ribbons, a charge sprite, a beam_end sprite, and beam_sparks particles. The Godot kit is a close match. The pack says Babylon's board laser reads better; the likely gap is the core brightness and the impact flare size. Best Godot 4.7 way: additive ribbons with a high core energy, a bright impact sprite, and sparks. Already implemented; the fix is tuning, not a new feature.

**5.6 Shield.** Babylon's shield is a persistent sphere mesh with a custom shader (index.html :565-570, :938-948, :1389). On a hit, the shader computes a hit glow, three expanding rings, a Fresnel term, and a cell noise mask. The color is multiplied by 2.2 for HDR boost. The shield is a persistent mesh whose ripple is animated. The shader does not discard the back hemisphere; it uses mask = 1.0 - smoothstep(5.0, 15.0, d) around the hit, so it is visible from a range of angles.
Godot's shield is a sphere mesh with a shield shader (fx.gd:37 SHIELD_T := 0.6, :378-381 clock-driven shader, :656 material creation, :794-795 visibility toggle, :930-940 per-frame update, :1212 shielded flag, :1301-1317 on-hit setup). The shader computes two thin ripple rings and a small spot. It discards when dot(d3, hit_dir) < 0.0, so only the hemisphere facing the hit is drawn. The shield is visible only while ah in [0.0, SHIELD_T), which is 0.6 s after the hit at 2.4 s.
Why the Godot shield may be invisible or not visible enough, ranked:
1. Hemisphere discard and camera side. The shader discards the back hemisphere. The breach close-up at t=3.0 looks at the Hegemony's port flank, while the shield hit is on the starboard side (hit_dir is roughly (0.15, 0.2, -1.0)). From the port camera, much of the visible sphere may be the back hemisphere and discarded. This is a timing and camera artifact, not a fundamental engine bug. It is the most likely cause.
2. Rings too thin and too dim at 4K. The rings are (dist - (0.4 + age * 9.0)) / 0.11, a very thin Gaussian. At 4K, a 0.11-unit ring on a ship-scale sphere can be sub-pixel. The shader uses energy = 1.0 and no HDR boost; Babylon uses 2.2. The Godot shield is therefore much dimmer.
3. Timing. The shield is visible only for 0.6 s after the hit at 2.4 s. The battle still at t=5.0, the board still at t=3.0, and the destruction still at t=12.6 do not necessarily catch the shield window for the ship in frame. The Hegemony breach still at t=3.0 should catch it (stagger 0.5, hit at 2.9, age 0.1), but the camera side is wrong. Other stills are likely outside the window. So "Godot shield not visible" could be a still-timing artifact for most shots.
4. Depth test and occlusion. The shield sphere may be occluded by the hull because it is scaled to half * 1.15 + 1.5, which is close to the hull. If the depth test rejects fragments behind the hull, the visible part may be too small.
5. Material override and blend mode. The shield uses material_override with blend_add, depth_draw_never, and cull_disabled. If the material is set but the mesh is not visible, or the strength is zero because the phase is wrong, the shield is invisible. The phase is driven by scene_t and the ship stagger; if the stagger is wrong or the clock is reset, the shield may never show.
The fix is build-level: widen the rings, raise the energy, remove or soften the hemisphere discard for the still camera, and shoot a still at the shield's visible time from the hit side. This is not an engine limitation.

**5.7 What makes Babylon read better overall.** Babylon's effects read better because of build effort and layering: more sprite kinds, streak kinds, ring kinds, ribbon kinds, shard kinds, POM decals, raymarched volumes, and per-event point lights. Godot's kit has equivalents, and the rich mode has FogVolume, POM holes, and soft particles, but the pack says it had fewer polish rounds. The gap is build-level, not engine-level. Godot can match the effects with GPUParticles3D, FogVolume and fog shaders, Decal, ribbon MultiMesh, and shader-based shields. The proof's job is to close that gap, and it has not been shown yet.

## 6. Job 5: ranked risks, both directions

I rank by how likely each is to change the call. I cite primary sources for engine, price, licence, and platform claims.

**6.1 Highest: the Babylon max asset bug invalidates the main visual comparison.** Ryan's "Godot better ship detail" was made on a comparison where Babylon max did not load assets/hi. This is a build bug, not an engine difference. If Babylon max is re-run with the 8K assets, the ship-detail gap may shrink or disappear. This is the most likely risk to change the call because it goes directly to Ryan's stated reason for choosing Godot. Evidence: final round README CAUTION line, and the blind sheets' MAX entries.

**6.2 High: the blind is not clean (DoF change, breach placement change, reused labels, unknown FORCE_A, board _hi asymmetry).** The blind was revised after Ryan saw sheets 1 to 6. Godot's breach was moved after feedback. The final sheets are not a single untouched blind. This weakens the fairness of both the lighting and effects verdicts. Fix: fresh blind with fixed builds and recorded settings.

**6.3 High: Godot's shield invisibility is a build bug, not an engine-level gap.** If the shield is fixed (wider rings, higher energy, visible from the still camera), the effects gap narrows. The decision should not treat "Godot shield not visible" as evidence that Godot cannot do shields. Evidence: fx.gd shield shader and visibility logic.

**6.4 Medium-high: Babylon 9.30's new lighting features are not fully exercised.** Babylon 9.0 added clustered lighting, volumetric lighting, frame graph, and node particles. The Babylon build uses SSAO2, SSR, contact shadows, IBL, TAA, and clustered lights in rich mode, but the pack says Godot's SDFGI, SSIL, SSR and soft shadows have no real Babylon equivalent. That may be true, but Babylon 9.30 is a newer release and its volumetric lighting and frame graph are not obviously used in the max build. If the team gave Babylon the same polish round as Godot, the lighting gap might be smaller. Primary sources: Babylon.js 9.0 announcement https://blogs.windows.com/windowsdeveloper/2026/03/26/announcing-babylon-js-9-0 and What's New https://doc.babylonjs.com/whats-new. The pack's own R22 says Babylon moved from 8.20 to 9.30 because 9.x closes limits; the question is whether the build uses those features. UNSURE on how much of 9.30's lighting stack is enabled.

**6.5 Medium: GodotSteam licence change.** GodotSteam is currently MIT (the Godot asset pages and GitHub list MIT), but the GodotSteam site says: "Dropping MIT in the upcoming GodotSteam 4.20 (hey-o), we will be dropping the MIT for another custom license similar to GodotSteamKit's." Primary source: https://godotsteam.com (the "Dejavu For You" update). If the project relies on MIT terms, the licence change could affect distribution. It is not a reason to avoid Godot, but it should be reviewed before shipping. Also, GodotSteam's update pace tracks Godot versions; the store page says it is used in Godot 4.7, and the tutorials mention an auto-initialize fix for Forward+ overlay issues: https://godotsteam.com/tutorials/. UNSURE on the exact lag for future Godot releases.

**6.6 Medium: Godot 4.7 Vulkan and NVIDIA driver issues.** There are open Godot issues about Forward+ hangs on certain GPUs, hybrid Intel/NVIDIA crashes, and Vulkan device creation failures. Examples: https://github.com/godotengine/godot/issues/121503 (hang on closing Forward+ projects), https://github.com/godotengine/godot/issues/124526 (hybrid Intel/NVIDIA compatibility editor crash), https://github.com/godotengine/godot/issues/124130 (RenderingDevice free crash on Vulkan). These may not affect the RTX 5080 proof machine, but they are a support risk for players on hybrid laptops or older drivers. Likelihood of changing the call: medium, because the team can test the RTX 5080 and ship a Compatibility fallback.

**6.7 Medium: Steam overlay and platform.** The Steam overlay does not support browser-technology games on Windows, macOS, or Linux, including Electron, per the Steam community discussion: https://steamcommunity.com/discussions/forum/1/3805026127094463395/. The Steamworks overlay docs say the overlay supports DirectX 7 to 12, OpenGL, Metal, and Vulkan: https://partner.steamgames.com/doc/features/overlay. Godot exports a native .exe, so the overlay can work; GodotSteam's docs say the exported project should work in the Steam client, and the auto-initialize change fixes Forward+ overlay issues. Babylon would need a native shell, and the overlay still may not work because of the browser multi-process architecture. This is a Godot advantage, not a risk. But GodotSteam's overlay support is not unconditional; test it in the exported build, not the editor.

**6.8 Low-medium: save-file migration.** Moving the rules to Godot means existing JS save files need a migration path. The pack does not provide the save format or the player count. If the game is pre-release, the risk is low. If there are players with saves, the port plan needs a versioned migration and a test that loads old saves. UNSURE on the save format.

**6.9 Low-medium: test tooling and check pack.** The port plan keeps the Node sim as the golden oracle and adds per-turn parity tests, but the pack says tools/pc/parity.bat does not exist yet. The check pack may not cover visual regressions, performance regressions, or save migration. The parity test is necessary but not sufficient. The team should keep the check pack and add the parity harness, not replace one with the other.

**6.10 Low: Ryan's editor workflow.** Godot has a visual editor, which is a benefit. The risk is that editor scenes are harder to diff in git and that Ryan may change scenes without code review. This is manageable with scene text format and review. Likelihood of changing the call: low.

**6.11 Reverse: Babylon 9.30 may look better than the write-up says.** Babylon 9.0 added clustered lighting, volumetric lighting, frame graph, and node particles. The write-up says Godot's lighting features have no real Babylon equivalent, but Babylon 9.30 has SSR, SSAO2, volumetric lighting, and clustered lights. If the Babylon build enabled those and still lost on lighting, that is a stronger result for Godot. But if the Babylon build did not enable them, the comparison is not a ceiling test for Babylon. The write-up should state which Babylon 9.30 lighting features were enabled in max mode. Primary sources: https://blogs.windows.com/windowsdeveloper/2026/03/26/announcing-babylon-js-9-0 and https://doc.babylonjs.com/whats-new. UNSURE on what was enabled.

**6.12 Engine price and licence.** Both engines are free. Godot is MIT: https://godotengine.org/license/. Babylon.js is Apache 2.0: https://doc.babylonjs.com/ (code license) and https://github.com/BabylonJS/Babylon.js/blob/master/license.md. Neither has royalties. The licence risk is GodotSteam, not the engine.

**6.13 Godot 4.7 and Babylon 9.30 release dates.** Godot 4.7 shipped June 18, 2026, and 4.7.2 shipped August 18, 2026: https://godotengine.org/releases/4.7/ and the release metadata. Babylon.js 9.30.0 shipped October 8, 2026: https://github.com/BabylonJS/Babylon.js/releases/tag/9.30.0. Both are current. The pack's R22 says Babylon moved to 9.30 to match Godot's latest stable; that is consistent with the dates.

## 7. Not checked

I could not check the following, and the report should not be read as if I did.

- The GDScript rules port itself. contrib/opus/enginetest/godot_rules/ does not exist on main. I checked the JS game code traps only. The port's PRNG, rounding, sort, and hash implementations are not in the pack, so I cannot say whether the port avoids the traps.
- The parity script and the 10,000-draw test. tools/pc/parity.bat does not exist. The per-turn hash script and the draw test are not on main. The rules-parity half of the proof has not landed.
- The Babylon and Godot build READMEs. The pack says they are not included, and I did not have them. I could not verify the Godot camera poses, FOV, exposure, DoF, TAA, or grading from main.gd. I could not verify the exact asset level of the Godot board stills.
- Whether FORCE_A was used. The key file records only the outcome, not the environment variable. UNSURE.
- The exact effect of the Babylon max asset bug on Ryan's verdict. I know the max stills are not comparable, but I cannot quantify how much the detail gap shrinks with the 8K assets.
- The asteroid counts and placement in each build. The pack does not give per-build asteroid counts, so I cannot separate engine lighting from build placement for the asteroid verdict.
- The save format and the number of existing saves. The pack does not provide them. UNSURE on migration risk.
- GodotSteam's future update pace for Godot 4.8 and later. The current docs say it works with 4.7, but future lag is UNSURE.
- Whether the RTX 5080 proof machine hits the reported Godot Vulkan issues. The issues are reported on other configurations; I did not find a report specific to the RTX 5080. UNSURE.
- Whether Babylon's max mode enables all of Babylon 9.30's new lighting features. The source shows SSAO2, SSR, contact shadows, IBL, TAA, and clustered lights in rich mode, but I cannot confirm that volumetric lighting and frame graph are used in the max benchmark. UNSURE.
- The exact performance of the Godot shield fix. I can identify likely causes, but I did not run the build. The ranking is evidence-based, not measured.

This report is the deliverable. I did not save anything.
