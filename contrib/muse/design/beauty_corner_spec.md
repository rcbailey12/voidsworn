# Beauty corner test scene: specification

Status: specification, not a task order and not a schedule. Opus may use this scene, change it, or set it aside. Its purpose is narrow: prove one of each thing at target frame rate, in a scene separate from the game, before that thing is integrated into the game. Nothing in this spec assigns implementation sequence or dates.

Basis: art_direction_rey.md (colour laws, silhouette grammars, hero concepts, plate system, effects language), ship_kit_upgrade.md (kit pieces, budgets, gates, acceptance tests), visual_expansion_research.md (cinematic recipes, pipeline settings, phone budget), tool_guides.md (Blender export, Babylon performance, gltfpack tiers, KTX2, Spector.js), graphics_craft.md (tonemapping, bloom discipline, anti-aliasing, VFX timing, readability, overdraw, accessibility). Where those documents disagree, section 7 flags it instead of picking a winner.

## 1. Scene contents

The corner is one Babylon scene, loadable on its own, with no campaign, no turns, and no game logic. Everything in it is scripted: fixed camera paths, fixed ship placements, fixed effect triggers, so two runs are comparable.

### Hulls: six heroes, one per faction

- Voidsworn: Basilica, carrier. Twin spire towers flanking an open launch nave, stained-glass hangar mouths glowing amber.
- Hegemony: Edict, battlecruiser. The perfect wedge, three stepped decks, ion batteries in recessed centreline trenches, sensor dome on the centreline.
- Corsair: Jackdaw, torpedo skiff. Half a stolen picket welded to an oversized engine block, external torpedo rack bigger than the crew hull, mandatory asymmetry.
- Chorus: Lullaby, spore carrier. Gravid brood sac, translucent spore pods clustered under chitin plates, radial knot, no straight edge longer than a plate.
- Ithar: Palinode, sail cruiser. Needle hull, twin vertical sail fins (one dorsal, one ventral) lit jade from behind, gold filigree spars. Vertical fins only; horizontal sail wings are banned.
- Deathless: Cenotaph, tomb carrier. A ribcage at station scale, bone prow plate blank and staring, green light deep in the ribs.

Each hull appears twice in the scene: once lit in its home plate, once on the silhouette sheet (section 5). The six hero plates in img/ (ship_voidsworn_basilica.webp, ship_hegemony_edict.webp, ship_corsair_jackdaw.webp, ship_chorus_lullaby.webp, ship_ithar_palinode.webp, ship_deathless_cenotaph.webp) are the reference targets for the lit shots.

### Background plates: six anchors

One plate per terrain kind, so the corner proves the plate system against the game's actual terrain set: Belt, Storm, Graveyard, Planet, Station, Dead Star. Each plate is built as the four layers from the art direction: far gradient nebula (two colours max, region tinted), one mid feature, near particulate matched to the feature, starfield with per-plate density and colour temperature. The 12 variant and special plates (Belt Core, Crimson Storm, Stellar Nursery and the rest) are out of scope for the first version of the corner, except Stellar Nursery, which serves as the backdrop for the capital event shot in section 2. The plate-to-terrain mapping gap is flagged in section 7; the corner proves plates, it does not settle the mapping.

### Lighting rig

- One key light, the system primary, warm from one side, consistent across all six plates so hulls are comparable.
- Faction glow lights: ember orange (Voidsworn), clean blue (Hegemony), hot red with flicker (Corsair), bile (Chorus), soft jade (Ithar), terminal green (Deathless). Glow is set dressing and engine light, never shield colour.
- Ambient: low, cold, uniform. No fill light strong enough to flatten a silhouette.
- Grading: ACES tone mapping, one fixed exposure per plate (never auto-adapted exposure; an exposure shift that changes which ships read is a gameplay bug, per graphics_craft.md). Bloom threshold and weight are test variables (section 7), starting at threshold 0.7 and weight 0.5.
- Colour source: FAC3D is the single colour source. If a hull in the corner disagrees with FAC3D, the corner is wrong, not the table.

### Cameras and shot list

- Fleet view: the full board framing, the readability test distance. Every faction readability check in section 5 is judged here.
- Hero framing: the boss arrival framing (radius from 1.6x fleet view to hero framing, 3.5 second move, BezierCurveEase biased to a slow finish, letterbox bars in over the first 0.4 seconds).
- Command push-in: 1.2 second push-in of about 15 percent radius on the commanding ship, ease-out, brief bloom weight lift, then release. No letterbox.
- Targeting close-up: single ship, prow quarter, for shield ripple and damage state inspection.
- Silhouette sheet camera: orthographic flat black grid, all six heroes small, for the sheet test in section 5.

## 2. Effects to prove, one by one

Each effect is proven separately, in isolation, before any combined shot. An effect that only works when it is the only thing on screen has not passed.

- **Beam fire.** Stretched additive cylinder or ribbon between muzzle and target, bright core plus soft shell at 1.6x diameter and about 0.25 alpha, noise texture scrolling along the core so the beam boils. Fade in over 40 ms, out over 80 ms. Muzzle flash sprite and impact glow sprite with sub-emitter sparks. Cap: 12 concurrent beams. Faction character per the art direction: Voidsworn lances charge with a rising ember flare; Hegemony ion fire is instant and clinical; Ithar beams are hair-thin and blinding at the core; Deathless gauss fire is a green line that arrives before its glow.
- **Shield ripple and per-facing shield death.** All factions, ice cyan only, per the colour law. Faction identity is carried by ripple shape only: Hegemony perfect hexagons, Voidsworn arch segments, Chorus blistered, Ithar smooth gradient, Deathless cracked glass, Corsair patchy and flickering. Two sub-tests: a ripple on a full shield, and a facing death where one sector dies while the others hold, with the dead sector protecting nothing until restarted.
- **Explosion.** One per faction, following the art direction death signatures: Voidsworn breaks like a burning building with spires toppling inward; Hegemony dies in one white flash and clean halves; Corsairs come apart at the welds with donor sections spinning away intact; Chorus deflates and darkens with pods bursting late; Ithar shatters like glass, sails first; Deathless goes dark in segments, stern to prow, green lights last out.
- **Engine trail.** Deliberate TrailMesh or beam trail, never accidental motion blur. Trails fade by camera distance and fighter trails are dropped entirely at fleet view. Trail screen area is budgeted, not trail count.
- **Torpedo flight.** Multi-turn travel with limited turning, so the salvo herds movement even when it misses. Corsair torpedoes burn dirty and wobble. The corner proves the visual (a slow, visible, turning threat) rather than the game rule.
- **Boarding flash.** The boarding action as a visible event: fires starting on the target hull plus an engine cripple read (dimmed engine glow, slowed plume) for one round. Range, cooldown and consequences belong to the game; the corner proves the read.
- **Capital event.** The full directed beat, in order: HUD fade out, letterbox bars in over 0.4 seconds, 3.5 second arrival move to hero framing, depth of field enabled only for this shot on desktop (dropped on phone, where the move and letterbox carry the shot), bloom weight lift, then release and HUD fade back in. This is the only shot in the corner allowed to use depth of field.
- **Damage states.** One per faction, per the art direction: Voidsworn cracks glowing ember from inside; Hegemony venting blue coolant in clean jets; Corsairs shedding rust and a donor panel; Chorus bleeding bile with the wound knitting visibly; Ithar sails tearing and going dark panel by panel; Deathless losing a rib segment that drifts, then burning green and flying home on reassembly.

## 3. Budget gates per tier

All figures below come from the design documents. Where a document gives an observed range rather than a ceiling, the gate is marked provisional and the corner's job includes turning it into a measured ceiling.

### Phone tier (reference device: the Pixel)

- Frame rate: sustained 60 fps over a 60 second scripted run covering every shot in section 1 and every effect in section 2. Fail if the average drops below 50 fps, or if any 5 second window drops below 40 fps.
- Draw calls: under 300 for the full corner scene at fleet view. Source: community guidance in tool_guides.md (roughly 100 to 300 on mobile browsers at 60 fps), flagged there as community practice, not an engine guarantee. The corner measures it with the Inspector rather than trusting it.
- Hull triangles: per hull within the observed phone range of 1,200 to 16,000 triangles. Provisional scene ceiling: the 6 hero hulls plus background geometry under 200,000 triangles in the corner scene. The full game figure behind this gate: all 36 phone hulls total 512,892 triangles, and all hulls load at boot with no eviction.
- Texture memory: the corner scene under 350 MB of VRAM with KTX2 compression. Derivation: the kit doc puts a 20-ship battle at about 1.32 GB of texture memory uncompressed, and the tool guides put the KTX2 reduction at about 75 percent (one forum case: 286 MB to 73 MB). 350 MB is the provisional ceiling the corner must confirm or correct. Uncompressed textures fail the gate outright: KTX2 is mandatory on the phone tier, not optional.
- Particle systems: 6 to 10 small concurrent systems maximum, per the research memo's working phone budget. Overdraw ratio consistently above about 2.0 (every pixel shaded twice) fails the gate.
- Pipeline on phone: DefaultRenderingPipeline with HDR, ACES grade, bloom at reduced scale, FXAA or MSAA 2, no depth of field, no motion blur, no SSAO. LUT grade, skybox stack and camera easing are never cut: they are nearly free and they are the feel.

### Desktop tier

- Frame rate: sustained 60 fps over the same 60 second scripted run, with the desktop pipeline enabled.
- Draw calls: under 1,000 for the full corner scene at fleet view (community guidance: roughly 500 to 1,000 on desktop browsers at 60 fps).
- Hull triangles: per hull within the observed desktop range of 2,400 to 38,000 triangles. All 36 desktop hulls total 930,166 triangles; the corner's six heroes are a subset and must stay within the same per-hull range.
- Texture memory: KTX2 throughout; the desktop ceiling is set by measurement in the corner, not by this spec, because the documents give no desktop VRAM ceiling. Record it; do not guess it.
- Pipeline on desktop: MSAA 4, full bloom, depth of field allowed on the capital event shot only, LUT grade, skybox stack, camera easing.

### Cut order (both tiers, from the research memo)

When the target frame rate cannot be held, cut in this order: fighter trails at distance, shell layers on beams, GlowLayer, bloom weight, then MSAA samples. Never cut the LUT grade, the skybox stack, or camera easing. The corner records which cut was needed, if any, per effect: a gate passed only by cutting is a conditional pass, not a pass.

### What fails the gate

Any of: average frame rate below the tier target; a background pixel inside the board area above the 40 percent luminance cap; a hull that fails the silhouette sheet test; a shield effect that uses any colour other than ice cyan; an effect that only works in isolation and collapses in the combined shot; a per-hull triangle count above its tier range; an uncompressed texture on the phone tier. A conditional pass (gate met only after a cut from the cut order) is recorded as conditional, with the cut named.

## 4. Measurement procedure

Comparability is the whole point. Two runs that cannot be compared are two anecdotes.

- **Scripted run.** One fixed 60 second sequence: fleet view hold (10 seconds), hero arrival (3.5 seconds plus hold), Command push-in (1.2 seconds plus hold), targeting close-up per hull (5 seconds each), one beam volley, one shield ripple per faction, one facing death, one explosion per faction, one torpedo flight, one boarding flash, one capital event, damage state per faction, silhouette sheet hold (10 seconds). Same order, same camera paths, every run.
- **Frame rate and frame time.** Inspector Statistics tab: frames per second, draw calls, active meshes. Record average fps, 1 percent low fps, and the worst 5 second window, per tier, per run. Record device (model, OS version), build identifier, and whether the device was thermally warm (note it; do not control for it beyond recording it).
- **Spector.js capture.** One capture per tier per run, on the combined shot (all six heroes, one plate, one beam volley, one explosion). Steps: open the corner, start Spector capture, run the combined shot, stop capture, inspect the command list for hidden passes and forgotten render targets, and record pass count and any unexpected render target. Spector.js is MIT licensed and lives in the Babylon.js GitHub organization.
- **Run record.** One short text file per run, kept beside the corner: date, device, tier, build identifier, average fps, 1 percent low, worst 5 second window, draw calls at fleet view, triangle counts per hull, texture memory estimate, which cuts (if any) were needed, and the screenshot set from section 5. A run without its record does not count.
- **Regression rule.** A later run that is slower than the recorded baseline by more than 10 percent on any headline number (average fps, draw calls, texture memory) is a regression to investigate, not noise to ignore.

## 5. Acceptance criteria

- **Screenshot comparisons.** Every lit hull shot is compared side by side with its concept plate (same angle and lighting where the plate allows it). Pass is judged by eye against the plate: silhouette grammar present, faction palette present, no flat single-colour read. The comparison screenshots are kept with the run record.
- **Readability checks.** At fleet view, each hull must be identifiable as its faction by silhouette and icon without relying on colour. Test method: the fleet view screenshot in grayscale; if two factions merge in grayscale, the pair fails and the distinguishing feature (geometry, icon, trim pattern) must be strengthened. Colour is never the only channel carrying faction identity.
- **Silhouette sheet test (from the kit doc).** All six heroes rendered flat black, small, in a grid. Any two hulls a viewer cannot tell apart, or any hull a viewer assigns to the wrong faction, sends the hull back. This test is run per tier, since phone-size silhouettes are the binding case.
- **40 percent background luminance cap check.** Method: render one unlit hull facet as a reference swatch, measure its luminance, then sample background pixels inside the board area across all six anchor plates. No sampled pixel may exceed 40 percent of the reference luminance. Procedure: sample at least 20 points per plate (corners, centre, brightest visible feature, plate edges), record the maximum per plate, and fail any plate over the cap regardless of beauty. Region tinting (a whisper of home faction glow in the far gradient) is allowed only inside the cap.
- **Shield colour check.** Sample the shield ripple pixels in the targeting close-up: ice cyan family only, all factions. Any faction-coloured shield pixel fails.
- **Gold check.** Sample gold pixels in the lit shots: gold may appear only on patrons and Command UI. Gold or gold-adjacent trim on a hull fails, subject to the open gold question in section 7.
- **Accessibility checks (from graphics_craft.md).** No more than three flashes per second across all simultaneous effects; no full-screen strobe for a capital kill; a reduce-flash setting exists and caps flash brightness and rate. Faction colours must be distinguishable under deuteranopia simulation, and faction identity must survive colour removal entirely (see the grayscale test above).

## 6. How the scene relates to the game without being part of it

The corner is a harness, not a branch of the game. It shares the game's materials, pipeline settings and effect parameters by copy, not by import, so that proving something in the corner does not accidentally change the game, and breaking the game does not break the corner.

What copies over when an item passes: the validated material and pipeline settings, the effect parameters (timings, thresholds, caps), the LOD thresholds, the measured budgets, and the reference screenshots. What stays in the corner: the scripted camera paths, the reference swatches, the measurement rig, the run records, and any test-only geometry (the silhouette sheet grid, the unlit facet swatch).

The corner does not replace the kit doc's Pixel stress gate: no hull 6 until a fully loaded battle passes on the actual phone. The corner is the step before that gate, where individual items are proven cheap enough to deserve a place in the battle that the gate measures.

## 7. Disagreements flagged, not resolved

- **MSAA samples on phone.** The research memo's phone budget lists DefaultRenderingPipeline with samples 4 always on; the tool guides and graphics_craft put the phone at FXAA or MSAA 2, with MSAA 4 reserved for desktop. The corner tests both and records which one holds 60 fps on the Pixel. Do not assume samples 4 on phone.
- **Bloom threshold.** The research memo uses a bloom threshold around 0.85 for beams; graphics_craft starts at threshold 0.7 and weight 0.5. The corner starts at 0.7 and 0.5 and raises the threshold until the background plates stop glowing, recording the chosen pair per tier.
- **Gold on hulls.** The art direction rations gold to patrons and Command only, but Chorus trim is dull gold, Ithar trim is pale gold, and epic rarity stays gold-adjacent. The gold check in section 5 will fail hulls that follow the art direction's own trim values. This is an open design question (raised by the design council audit), not a corner failure: record the failing pixels, do not silently recolour the hulls to pass.
- **Ripple shape as the only shield channel.** The art direction carries shield identity in ripple shape only, while the same document set admits glow is the first thing lost at phone size. The fleet view readability check in section 5 is the test that decides whether shape alone survives; if it does not, the shield language needs a second channel, and that is a design decision, not a corner fix.
- **Plate mapping.** 18 plates exist against five terrain kinds with no mapping in any document. The corner proves the six anchor plates; it does not invent the mapping. Until a mapping exists, the corner's plate shots are labelled by plate name, not by terrain kind.
- **Kit economics.** The kit doc's 69-session figure was the hand-built kit rate. The corner measures dressing, paint and format conversion of existing meshes (see the reading plan errata), not hull creation from nothing. Any cost claim from the corner must state which of those it measured.

## 8. Reference scoring (added Oct 24, 2026, from a technique Ryan flagged)

Score the render against the reference instead of eyeballing it alone. For every lit hull shot and plate shot in section 5, run a programmatic comparison against the matching concept plate: palette and histogram match, light and contrast match, and the 40 percent background luminance cap measurement from section 5. Record the score with the run record.

The score is a tone and lighting gate only. It cannot pass a shot on its own. Silhouette readability, faction identification at fleet zoom, and the owner's screenshot verdict are separate gates, and a high score on a wrong-looking ship is still a fail. The loop discipline that goes with it: change one thing per iteration, keep a side-by-side of render versus reference for each change, and record the change note with the run record.

Auto-fitting a color grade (LUT) to the reference plate as a final step is a legitimate tool, not a cheat, provided the fitted grade is recorded with the shot and the per-region LUT set stays a versioned artifact, not a silent tweak.
