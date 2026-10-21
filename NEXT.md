# NEXT: the build queue

Build in this order. Anything not listed here goes to the parking lot at the bottom, not into the current version. Full reasoning: the master review doc (claude.ai artifact aef64607-980c-49ce-977b-ff7b8a32868a).

## v53: solid and readable (publish each workstream as it lands: v53.1, v53.2, ...)

Gate before every publish: `node sim3d.js rulecheck`, `node sim3d.js fuzz 20`, `python3 smoke.py` all pass; one battle on the Pixel for anything visual.

- [x] A. Board readability: drift near zero (coastCap), motion on the model only; side-coloured ring on every occupied hex; contact shadow; move hexes outline-only; nebula dimmed under the board; expected-damage line + ghost ship on first tap.
- [x] B. Correctness and safety: animPath stops writing u.q/u.r/facing (ramUnit gets its own commit); live() checks in rotateUnit and blink; B.seed overwrite in prepBattle removed; floating killUnit calls awaited in order; swarmPhase under stallGuard; weapon spent only after the live check; seeded lifepod roll; cloud-save run vs settings timestamps; save defaults in one place; seed replay check; smoke extended through a sector boss.
- [x] C. Loading and phone performance: parallel awaited hull fetch before the title with progress and a log line naming the live hull path; skip fragmentHull at Medium; pool fxText; full frame rate while animating; shared shield ring geometry; a ?prof=1 profiler capture that exports CSV.
- [x] D. AI that reads: per-weapon target re-pick; shield strippers first; sticky focus; threat ignores fired guns + death cliff; objective terms with round clock; abilities after moving; squadron focus; escort spacing; enemy focus marker on the board (tap, not hover).
- [ ] E. World: asteroid rebuild (tall faceted blockers on a marked hex, sparse dressing off playable hexes, recipe variety, sharper shapes, v51 filler pulled back); Ithar material fix; one Ithar sail card test.
- [x] F. Sound: rebuilt audio graph (buses, reverb, pan, voice limits, volley aggregation) with recorded clips from Kenney (CC0) and the Sonniss GDC 2026 bundle embedded as Opus (~470 KB), synth fallback, hidden sound test.

## v53.5+: cleanup and fidelity (owner decisions Oct 20)
Full audit: AUDIT_v53H.md. Owner chose: full per-ship detail bake; desktop loads the sharp set, phone a lighter set; after ships do explosions and weapons; GPU jobs on the PC may run any time it is on.
- [x] G. Ship close-ups: strays and floating windows gone, shader ports, new meshes (V18 carrier, C19 barge, S1/S2/B23 craft, O1 station, O2 transport, O3 beacon). Follow-ups: squadron end-card soft-lock, stray orange orb, no windows on Chorus, thinner Deathless circuits, hex fill fades on zoom-in.
- [x] H. Cleanup now: dead title animation/preview demo, hexTex, ripple, "low" tier branches, 30 unused hull files.
- [ ] Cleanup after G: points-only ship build (skip the thrown-away procedural hull, ~3.3 s and 2 M vertices), drop the concept-hull toggle, decals/fires on the real hull, wrecks from concept meshes, then delete the procedural builders.
- [ ] Cleanup after C: pool per-call effect meshes/materials, drop old effect fallbacks, refresh the reflection probe per battle.
- [ ] Per-hull bake on the PC (Blender, GPU): UV unwrap each game mesh, bake normal + AO + curvature + window mask from the high-poly Hunyuan output; albedo from faction plating (Hunyuan Paint if it fits in VRAM). Game: hull JSON carries UVs, per-hull texture sidecars (desktop 2K, phone 1K), hull material uses them; replaces the generated plating textures (75% of texture memory).
- [ ] Effects, doubled down (owner: "extremely high quality", "visceral and punchy", plasma must feel nothing like lasers). Starts as soon as C (perf, touches effect pooling) merges. Every weapon family gets its own look, timing and impact:
  - Laser/las: instant coherent beam, hard white core with faction-colour glow, sharp muzzle flash, burn line and spark spray on impact.
  - Plasma: slow fat bolts with a churning molten core and wobbling corona, heat shimmer, splashing impact that leaves glowing slag, drips and smoke; low thump.
  - Autocannon/tracer: rapid stream of small tracers, brass-bright flicker, peppered hull pings.
  - Rail: near-instant streak with a shock ring at the muzzle, delayed punch-through, debris out the far side.
  - Lance/ion: thick charged beam with build-up, crackling arcs; ion leaves a blue static wash on the shield facing.
  - Needle (Ithar): fine glassy shards, prismatic glints. Spine/bio (Chorus): spat organic projectiles, wet bursts.
  - Torpedoes: textured bodies, exhaust trails that curve, big detonation with flipbook fire and shockwave.
  - Game-feel rules (docs/skills/game-feel): importance tiers (small/medium/large presets for every event), trauma-based camera shake (trauma^2, smooth noise, decays; hits add trauma), real-time hit-stop that never blocks input, eased "pop" tweens, 5-8 stacked responses within ~100 ms for a big hit; Settings toggles "reduce screen shake" and "reduce flashing".
  - Punch for everything: hit-stop on big hits, scaled camera kick, flash, hull sparks/debris, shield ripples at the struck point, sound synced (sfx.js).
  - Explosions: Blender-rendered flipbooks (fireball, debris, smoke) on the PC GPU, broken hulls with closed cut faces, staged capital deaths.
    Status Oct 20: tools/blender/fxsim.py runs Mantaflow on the PC (Blender 4.5.14, OptiX) and renders tintable flame/smoke channel frames, but sims at 64 res look blobby and symmetric. Next: res 192+, randomised/noisy emitters (several offset spheres, turbulence force), longer frames, crop+pack into 8x8 atlases; or render a CC0 VDB explosion set (cheaper, higher quality). Effects workstream owns this.
- [ ] Blender world pass (owner approved): asteroid libraries per rock type (20-30 sculpted rocks each, baked maps), wrecks and death pieces fractured from the concept hulls with solid interiors, volumetric nebula/backdrop cloud renders, accretion-disc texture for black holes. Stations/beacon/transport already in the hull bake.
- [ ] Live-shader pass for what Blender can't do: black-hole gravitational lensing (screen-space distortion of the scene behind it) with an animated accretion disc; beams and shields with flowing energy textures (generated once, animated by flowmaps); shader-drawn anti-aliased hex grid; engine plumes as volumetric cones that read from the side; GPU particles for sparks, embers and debris.

- [ ] Music (none today): adaptive score with vertical layers (calm map, tension, combat, boss) crossfaded by battle intensity, segments switching on bar lines (docs/skills/audio-design). Source: generate royalty-free stems on the PC GPU with an open music model (ACE-Step / Stable Audio Open class) or CC0 tracks; owner picks the style.
- [ ] AI polish from docs/skills/ai-behavior-trees-utility-ai: normalised response curves for each consideration, hysteresis on target and move choices, a debug overlay of per-action scores for tuning.

## Ship shapes (owner, Oct 21: "everything still feels pretty low poly", desktop and phone)
Cause: the Hunyuan image-to-3D meshes are soft and lumpy at any triangle count (the station even split into a disc plus a separate ship). Not the engine, not the texture size.
Bake-off on the Pyre-Barge (C19_51) and the station (O1_37), clay renders + in-game (tools/blender/hs/):
- A Hunyuan at octree 512/640: no visible gain (tools/pc/hy_bakeoff.py). Dropped.
- B Blender clean-up of the current mesh (planar dissolve + hard edges): no visible gain. Dropped.
- C TRELLIS.2 (IgorAherne one-click Windows build, tools/pc/trellis_dl.ps1): downloading/untested.
- D Blender hard-surface rebuild, scripted per hull from the concept art (hs_lib.py kit: lofted hulls, frustums, bevels, greebles, tube bundles): crisp in-game on first pass. Recommended.
- [ ] Owner picks. If D: capitals and objectives first, then the rest; per hull: script -> export_json.py (game frame, split normals) -> uvprep -> hullbake (AO/curvature) -> closeshot; red/black paint and decals from the concept.
- [ ] Replace the box/T-shape wreck debris (debBases in buildTerrainFeatures) with real wreck chunks from the rebuilt hulls.
- [ ] The bright gold selection ring on the owner's Pixel shot at close zoom (PC shots show it faded; re-check on the Pixel with v53.8).

## v54: factions and rewards (parallel with v55)

Doctrines (Ithar and Chorus first, then Corsair, Deathless, Hegemony, Voidsworn); boon decline + reroll; rule-changing boons; legendary per patron (Hades style, unlocked at boss/elite after 2-3 of that patron's boons); rarity changes effect; shared refit tracks per class; kill marks and sector chronicle; section consequences; fire damage-control choice; earned Admiral's Command; objectives that change priorities; faction AI behaviours; differentiated admirals.

Decided rules: Ithar fire then move (post-fire move capped at half, no climb/dive); Chorus heals on dealing damage at range 1-2, capped per round, with a will-heal indicator; Voidsworn brace also shields one adjacent same-facing ally; Corsair capture pays a bonus refit/salvage on top of normal rewards, one prize per battle, never a flagship; Deathless one return per battle for the fleet, telegraphed a round ahead, not the flagship, returns low and cannot fire that activation; Hegemony ion stops shield regen on the struck facing for a round. Mid-battle reload replays the same node and enemy fleet.

## v55: spectacle

Ithar remesh (sails erased with Qwen-Image-Edit, hull core via Hunyuan, sails in engine); Corsair variants; Deathless frigate; per-hull Blender pass (weighted normals, curvature, gradient); per-ship tint and hull numbers; finer windows; CC0 explosion flipbooks; death timing by class; ripple broadsides; thicker beams; section smoke; shield quadrant ripple; sinking wreckage; arcing torpedoes; Sonniss + synth sound pass with distinct cues; 4:1 lighting with rim; backdrop pass; parallax dust; bodies above and below the board.

## Still cut (design reasons)

Altitude combat rules and class heights; stances and momentum; undo after a move; ground-first picking; rules/graphics event-queue refactor; gltfpack; tactical view toggle; one-shield small ships (maybe later as an experiment).

## Parking lot

- After v55, revisit the engine (owner agreed to circle back): port to Godot 4 if the phone can't hold frame rate with full-detail art/effects, the web download gets too large, or a native Android/PC app is wanted. Art, baked maps, sounds and flipbooks carry over; rules port; 3D/UI and the test harness are rebuilt.

(new ideas land here first)
- Rulecheck flaked once (1 in 10 runs) after v53-D: find the unseeded check.
- Sector 1 too easy: owner won 4/4 in 3 rounds each with 0 losses on v53.2 (balance pass after AI lands).
