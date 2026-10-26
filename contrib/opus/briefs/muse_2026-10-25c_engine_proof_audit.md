# Brief for Muse: audit the engine call and the Godot proof (Oct 25, 2026, night)

From Opus. Same house rules as `contrib/opus/briefs/muse_2026-10-25_engine_and_b2.md` (read it first): blind legs (DeepSeek and Qwen do not see each other's answers or Opus's conclusions until the synthesis), primary sources with links, file:line for repo claims, UNSURE tags, plain words, no em dashes, raw returns in `contrib/<model>/`, syntheses in `contrib/muse/reviews/`, no edits under `contrib/opus/`, game code or HANDOFF.md, commit to main.

Context: Ryan picked "Godot, prove it first" (FINDINGS R28). Two helpers are building the proof now:
- effects parity in `contrib/opus/enginetest/godot/` (Babylon's breach, smoke and venting, explosions, trails, shield ripple, board laser rebuilt in Godot; dark Chorus and Deathless hulls fixed);
- rules parity in `contrib/opus/enginetest/godot_rules/` (one seeded battle ported to GDScript, exact PRNG port, per-turn state hash against the Node sim `sim3d.js`, `tools/pc/parity.bat` prints PASS or FAIL).
The goal of this audit is to catch anything that would make the proof pass when it should fail, or fail for a fixable reason, before Opus reports it to Ryan.

Pass bar Opus will use (audit it too): effects pass if Ryan, looking at open side-by-side sheets, calls Godot's effects equal or better; rules pass if every scenario matches turn for turn with zero differences, the first 10,000 PRNG draws match on 3 seeds, and the estimate for porting the rest is not wildly above the port plan's.

## Job 1: check RESULTS.md against the raw data
`contrib/opus/enginetest/RESULTS.md` against the JSONs in `contrib/opus/enginetest/results/final_2026-10-25/` and `run3_2026-10-25/`. Every number: right, wrong, or not traceable. Flag any claim with no measurement behind it (for example the "est. 10x faster" Godot load claim) and anything that favours one engine through how it was measured.

## Job 2: was the blind test fair?
Inputs: `contrib/opus/enginetest/blind/blind.py`, `SPEC.md`, both builds, FINDINGS R18 to R28. Look for: same assets, cameras, clock and exposure in both; depth of field and TAA differences; Babylon always shown as A (FORCE_A); effects polish rounds not equal between builders; anything that would swing Ryan's read. Say which of his conclusions (Godot lighting and detail, Babylon effects) are engine-level and which are build-effort-level.

## Job 3: rules-parity traps (most important)
List what usually breaks exact JS to GDScript parity, and check the game code for each, with file:line in `battle.js`, `core.js`, `data.js`, `sim3d.js`:
- the PRNG: 32-bit math (`Math.imul`, `>>>`, `|0`), seed handling;
- rounding (`Math.round` rounds half toward plus infinity in JS; GDScript `round` rounds half away from zero), `Math.floor` on negatives, `%` on negatives, integer division;
- float order of operations, `Math.min/max` with NaN;
- iteration order (object key order, `Array.sort` stability and comparators), `for...in` over arrays;
- implicit type coercion (strings to numbers, `undefined` as 0, truthiness of 0 and "");
- `Date.now` or `Math.random` anywhere in rules code (would break determinism in both).
Also: is a per-turn hash enough, or should it be per action? What state must be in the hash so a pass means something?

## Job 4: effects parity
Read Babylon's effects in `contrib/opus/enginetest/babylon/index.html` and the Godot build. What makes Babylon's breach, smoke, explosions, trails and laser read better (shader tricks, counts, timing, blending)? The best Godot 4.7 ways to match each (GPUParticles3D, FogVolume, trails, shaders), with Godot docs links. Why might the Godot shield be invisible (likely causes with file:line)?

## Job 5: what the decision missed
Risks of moving to Godot that RESULTS.md and the port plan do not cover (for example GodotSteam licence and update pace, Godot 4.7 bugs on Vulkan with NVIDIA drivers, save-file migration, Ryan's ability to edit in the editor, test tooling replacing the check pack). And the reverse: anything that makes Babylon 9.30 look better than the write-up says. Rank by how likely each is to change the call.

Deliverable: `contrib/muse/reviews/engine_proof_audit_synthesis.md`, with a top list of "fix before the proof is reported" items first, then the rest. Opus applies the edits.
