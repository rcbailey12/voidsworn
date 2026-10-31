# Red team audit, vfx persona: Argon leg

Chair header: Argon (Gemini, Argon High) leg for the Oct 30, 2026 red team audit, run from the vfx evidence pack and the persona leg prompt. Text below is the model report verbatim, with em dashes normalized to ASCII where they appeared.

Red Team Audit Report: Visual Effects and Graphic Design Seat

Ranked Findings (Severity 1 to 10)

1. R43 Persistent Damage Marks and Stage Breach Geometry Violate Spec A (Overturning Prior "PARTIAL" and "Exceeds Spec A" Verdicts)

Status: OBSERVED and INFERRED.

What breaks or underperforms: OBSERVED: The prior effects review claims an "Overall verdict: PARTIAL, leaning MISS on the specs as written." and asserts that "the zoom tier's breach geometry exceeds spec A". INFERRED: Both claims understate the failure; the persistent hull mark system is a structural MISS on R43, and the stage breach geometry actively violates Spec A (damage_marks_reference.md) rather than exceeding it.

The evidence: OBSERVED: Out of ten mark entries in Spec A, only Squadron weapons and the Shield-only-hit rule score MEETS SPEC, and both do so by drawing zero persistent marks on target space ship hulls. Four families score MISSES SPEC or NOT IMPLEMENTED (Ion, Flak, Ram, Boarding), while "Light looks (auto, las, scatter, prism) leave no persistent mark at all". Furthermore, Spec A rules that "Ram crumple and the torpedo crater are the only marks all four legs allow" to alter a hull's outline and that "flak never exposes structure in the mark language". In the Godot code, however, "flak chip damage still drives stage 3 and 4 structural breaches", crater geometry is "triggered by any damage source (fx_ship_gd.txt:466-476, 574-586)" at pre-picked anchors rather than impact points, and "the only silhouette change in the build is the stage ladder's edge bite", which any weapon triggers.

What it costs the game: INFERRED: A player looking at a damaged space ship at 20-ship fleet distance cannot read what weapons hit it or where. Flak chip damage carves capital-grade structural craters into hulls, while torpedoes, lances, and rams leave generic round scorch decals instead of silhouette-denting craters, lit slots, or unlit crumples.

2. Faction Effect Palettes Collapse Under HDR Bloom, Color Vision Deficiency, and Unchecked Shield/IFF Collisions (Overturning Prior "Distinguishable on Paper" Verdict)

Status: OBSERVED and INFERRED.

What breaks or underperforms: OBSERVED: The palette audit concludes that "the six primaries stay pairwise distinguishable for red-green colour vision on paper." INFERRED: That flat-sRGB verdict fails in the 3D engine because zero luminance separation, HDR pre-tonemap bloom, and unaudited shield/enemy-IFF violet collisions destroy faction readability in motion.

The evidence: OBSERVED: For weapon-against-glow luminance contrast, "Every faction sits between 1.02:1 and 1.40:1", meaning weapon and glow colors are "never separable by brightness, only by hue." In the pale cluster, "Hegemony, Glasswrights and Eclipse stay within 30 to 61 of each other" out of 441 in RGB distance, closing to 31.6 under protanopia and 30.0 under deuteranopia (with Sunward Crusade against Chorus at 29.7). Worse, "Hegemony against Eclipse engine colours fall to 14.6 under deuteranopia", and the white-gold glows ("Hegemony damage_glow #FFDDA6 and Eclipse accent #FFECBC are only 26.8 apart") are nearly identical even in normal vision. Meanwhile, the A5 spine mandates "Effects are authored scene-linear, glow before tone mapping." Finally, palette_safety_2026_10_27.md never tested the shield or shield_edge fields, even though R3 puts faction colors on 3D shields and fx3d.js sets enemy IFF to "FOE_C=new C3(.62,.22,1)" on the claim that "violet is the colour furthest from all six faction shield colours", while Eclipse's palette is already "violet white #DDC4FF" and #DDBCFF.

What it costs the game: INFERRED: Scene-linear bloom before tone mapping pushes high-luminance pastels (#C4EAFF, #F6FAFF, #DDC4FF) toward white cores, erasing the narrow 29.7 to 45.4 sRGB hue gap. Hegemony, Glasswrights, and Eclipse shots, engines, and glows blur into a single pale wash, while Eclipse's violet effects collide directly with the violet enemy IFF ring.

3. Uncooled, Permanent Hit Decals Contradict the Turn-Based Phased Activation Loop and the Repair-Over-Scrap Ruling

Status: OBSERVED and INFERRED.

What breaks or underperforms: OBSERVED: A standing design constraint mandates that "Repair always beats scrap-and-replace per ship by design." in a game of hex-grid turn-based fleet battles with phased activation. INFERRED: The Godot decal implementation breaks both turn-by-turn tactical combat reading and campaign repair feedback because hit decals never cool, stage breaches cool on wall-clock seconds instead of turns, and repaired hulls never clear their hit marks.

The evidence: OBSERVED: Spec A requires fresh marks to glow only on the current turn because "fresh means this turn, so a bright mark also answers "what just got hit"", then cool to unlit scars, and requires that "hull language and game state must not disagree." In godot/fx/, however, hit and hole decals have "fixed emission 0.7 on scorch, fx_death_gd.txt:141", the "DECAL shader's own header comment claims cooling its fragment code does not implement", and for stage breaches "All cooling runs on clock seconds; nothing is turn-keyed." On repair, stage geometry reverses, but "hit decals are never removed, so a repaired section still wears its scorch and holes".

What it costs the game: INFERRED: Because scorch decals stay locked at 0.7 emission permanently, old hits from five turns ago glow as brightly as hits from the current activation phase, while breach heat fades while the player pauses to think. Across a run where players repeatedly repair their fleet, fully repaired space ships look permanently riddled with glowing hot breaches and scorch marks.

4. Forward+ Clustered Element Pool (512 Cap) and Uncapped Decal Appends Collide with 20-to-60 Ship Battles (Attacking the Godot 3D Brief Verdict)

Status: OBSERVED and INFERRED.

What breaks or underperforms: OBSERVED: The Godot 3D brief rules "Renderer: Forward+, decisively" and quotes Godot documentation that its "highest base cost, low scaling cost," profile matches this workload. INFERRED: That scaling claim has an unaddressed arithmetic cliff: pooling decals and dynamic lights into a single 512-element clustered budget while allowing weapons to bypass decal trimming will overflow or cull lighting/decal clusters in full fleet battles, and the automatic Compatibility fallback strips decals completely.

The evidence: OBSERVED: The brief states that in Forward+, "clustered elements (default 512 in view) are a SHARED budget" where "damage decals and explosion lights draw from the same pool". It also plans for "Fleet rendering at 20 to 60 ships" and specifies every "muzzle flash as quad plus sparks plus a shadowless OmniLight". Meanwhile, fx_implementation_review.md proves that decal capping is broken: there is "One ship-wide array capped at 10, trimmed only inside add_hit_scorch (fx_ship_gd.txt:816-826)", while "gauss and bio appends bypass the trim". In addition, Stages 1 and 2 add scorch and dent decals, Spec A budgets 8 to 20 decals per ship, and Godot 4.7 "auto-falls back to Compatibility when the RenderingDevice is unsupported", where "under the Compatibility renderer, scorch and hole decals draw nothing at all".

What it costs the game: INFERRED: At 20 to 60 space ships, 10+ scorch decals per ship plus untrimmed gauss and bio decals consume 200 to 600+ clustered slots before a single rippled salvo spawns dozens of muzzle-flash OmniLights and explosion lights. Hitting the 512 cluster cap causes visible light/decal popping during peak salvos, while any player dropped onto the Compatibility fallback loses 100% of persistent hull marks, particle trails, and HDR glow.

5. The 3-Flashes-Per-Second Accessibility Cap Is Bypassed in Code and Exhausted by Background Wrecks in Spec

Status: OBSERVED and INFERRED.

What breaks or underperforms: OBSERVED: The A5 synthesis sets a mandatory constraint: "Accessibility: hard cap 3 flashes per second, plus a reduce-flashing option." INFERRED: Confirming the fx_implementation_review.md verdict that the code misses spec, the problem is actually twofold: brightest emitters bypass the gate in code, and the A5 damage/wreck spec itself schedules enough ambient explosions on damaged hulls to starve active combat of flash budget.

The evidence: OBSERVED: In godot/fx/, "the budget certifies a gated subset while several of the brightest emitters bypass it", violating the chair rule that "WCAG counts flashes on screen, not calls into a budget function". Simultaneously, the A5 damage ladder specifies for Stage 5 wrecks "internal secondary explosions one per 1 to 3 s (Qwen) with small fireballs" counted against the flash budget, and for dying hulls a "cook-off phase 0.8 to 2.5 s with 3 to 8 internal explosions" (also budget-managed), while Spec A proposes boarding "muzzle-flash strobes from inside (Argon)".

What it costs the game: INFERRED: In a 20-ship battle, just two or three Stage 5 wrecks and one dying space ship generate 3 to 6 budgeted fireballs per second by themselves. Either the flash gate suppresses player weapon impacts so guns fire dark while background wrecks monopolize the 3/s cap, or weapon emitters bypass the gate (as currently coded) and violate photosensitive accessibility rules.

6. Locking "Seven Weapon Kinds Only" in A5 Directly Caused Four Missing Spec A Signatures and Silent Bioplasma Loss

Status: OBSERVED and INFERRED.

What breaks or underperforms: OBSERVED: The A5 synthesis enforces "Seven weapon kinds only: battery, flak, lance, torp, bio, gauss, sq. No eighth kind". INFERRED: Because Spec A (damage_marks_reference.md) requires ten distinct impact and mark grammars (adding Ion, Plasma, Ram, and Boarding), locking A5 to seven weapon sheets directly caused godot/fx/ to alias the other four into wrong effects, compounded by data-level weapon deletion.

The evidence: OBSERVED: Without dedicated A5 sheets, "Ion runs the identical _beam_burn as lance and leaves the identical scorch", so "The branching tree, the most settled mark in the whole reference, is absent." Likewise, "Plasma's persistent trace is the same generic orange-ember scorch", "Ram routes into _big_hit at 1.5 times scale" (leaving a glowing torpedo scorch instead of an unlit structural crumple), and for Boarding "The tendril routes to _bio_splat", leaving a random bio acid hole instead of an airlock breach with a patch-plate scar. On top of this, the claims register records a "third silent weapon deletion found Oct 30 (b_razor_s drops bioplasma undisclosed)".

What it costs the game: INFERRED: Four of the most distinct tactical actions in Voidsworn (shield-stripping ion beams, hull-crushing rams, boarding actions, and plasma batteries/bioplasma) have no distinct persistent visual identity on the hull, collapsing combat readability into generic orange scorch blobs and green bio splats.

7. Procedural Hull Geometry Sag and Cushion Shading Break Silhouette Readability and Miss the Pyre-Barge Benchmark

Status: OBSERVED and INFERRED.

What breaks or underperforms: OBSERVED: Ship sheets across factions exhibit "plates that bulge like cushions across every deck; long wavy bands along hull sides", mismatched bow profiles on V1b, and rim streaks on V1b, V17, and H7. INFERRED: Confirming the diagnosis in hull_surface_diagnosis_2026_10_27.md, unfair loft geometry amplified by dome-like plate shading corrupts the clean hull silhouettes required before any R16/R43 damage pass can work.

The evidence: OBSERVED: On zoomed inspection of H8 mid side, "the hull's own underside outline sags in a broad swell instead of running straight", which "repeats across factions and across render steps (pass 5 and d8e187e)", is "weakest on the hand-kitted Pyre-Barge.", and is worsened because "every plate is shaded as a soft dome". On V1b, the bow fix created a 3D contradiction where the prow is "pointed from above, blunt and drooping from the side.", while below views show "short vertical streaks hanging off rim edges, uneven lengths".

What it costs the game: INFERRED: Spec A relies on clean silhouettes so that ram crumples and torpedo craters read as unmistakable outline breaks. When intact space ships already have sagging outlines, cushion-domed plates, and top-vs-side prow contradictions, battle damage decals and normal-map dents cannot read as intentional structural trauma, and fleet assets fall visibly short of the hand-kitted Pyre-Barge standard.

8. Stage 5 Wreck Multiplication and Persistent Plumes Create an Overdraw Fog Bank on a 20-Ship Hex Grid

Status: OBSERVED and INFERRED.

What breaks or underperforms: OBSERVED: The A5 synthesis mandates that destroyed ships undergo "break-up into 4 to 10 major wreck sections with slow tumble", with each section trailing fire and smoke in a "wreck field persisting 10 to 30 s (or until battle ends)", while Stage 5 wrecks emit "Continuous debris shedding, 4 to 10 fire plumes, atmosphere jets everywhere". INFERRED: This specification directly collides with Spec A's anti-fog rule and the Godot 3D brief's particle overdraw warning.

The evidence: OBSERVED: Spec A (damage_marks_reference.md) explicitly warns to "reserve persistent smoke for the worst ships and sections or 20 ships become a fog bank." The Godot 3D brief likewise warns that "The biggest risk is simultaneous capital explosions with large soft smoke: overdraw, not particle count." Yet A5's only readability mitigation for dead player units is "on losing a player ship, desaturate the wreck slightly so it reads as gone."

What it costs the game: INFERRED: In a 20-ship battle where 8 to 12 space ships are destroyed, spawning 4 to 10 smoking, burning wreck chunks per kill creates 32 to 120 tumbling fire-and-smoke emitters persisting on the hex board. Slight desaturation on hull albedo will not prevent dozens of active fire plumes and smoke trails from obscuring hex occupancy, hiding living ships, and triggering severe alpha-overdraw frame drops.

9. Unresolved Core Visual Parameters (Tonemapper, Rim Light, Timing, and Distance Cues) Block Scene-Linear Authoring

Status: OBSERVED and INFERRED.

What breaks or underperforms: OBSERVED: Despite claiming an agreed spine for the effects pass, a5_effects_sheets_synthesis.md leaves eight foundational visual systems undecided between the legs. INFERRED: Authoring shaders, particle lifetimes, and HDR values before locking the tonemapper, rim lighting, and weapon timing guarantees rework and causes fleet-distance readability failures like the invisible Gauss mark.

The evidence: OBSERVED: Section 7 of A5 states that "Everything in section 2.3 (hitstop, shake, anticipation, rim light, tonemapper) remains open." It also records a 20x spread on "Gauss wind-up: Qwen long (0.5 to 2.0 s) vs DeepSeek short coil sequence" (0.10 to 0.30 s) and a 5x spread on "Torp plume life: Qwen 3 to 8 s ribbon vs DeepSeek 1.5 to 3 s exhaust." Meanwhile, faction_looks.json already hardcodes clamped HDR values ("Chorus hull_fix blue 1.35, Eclipse hull_fix blue 1.3, HDR rim tints"), and in godot/fx/ "the entry hole is the smallest persistent mark in the game", so without its companion stress ring "gauss history is invisible at fleet distance."

What it costs the game: INFERRED: Without a locked tonemapper or rim-light spec, HDR values like 1.35 blue rim tints and 0.7 scorch emission will clip unpredictably, 8-second torpedo ribbons risk saturating the hex grid, and Gauss weapons fail both timing consistency and fleet-distance hit verification.

10. Calibrating the Godot Particle Budget via Babylon PERFCAP on an RTX 5080 Violates the RTX 3060 Target Floor

Status: OBSERVED and INFERRED.

What breaks or underperforms: OBSERVED: The Godot 3D brief establishes that the "RTX 3060 is the most common Windows GPU" at 1080p and warns: "Design the default tier for that, not for the RTX 5080 on Ryan's desk." Four sections later, the same brief contradicts itself: "The real budget gets set by the effects-pass performance budget item using PERFCAP on Ryan's PC." INFERRED: Relying on PERFCAP on Ryan's PC fails both technically (because PERFCAP is Babylon-only) and methodologically (because tuning on an RTX 5080 breaks the RTX 3060 baseline).

The evidence: OBSERVED: In perf3d.js, PERFCAP is hardcoded to Babylon.js strategies ("const S=BABYLON.PerfCollectionStrategy; if(!S||!G.scene.getPerfCollector) return;") and exports via BABYLON.Tools.Download, which does not exist in Godot 4.7. Furthermore, in Godot GPUParticles3D, "amount_ratio gives NO performance benefit (allocation is for the total amount)", requiring hard scene or amount swaps per quality tier.

What it costs the game: INFERRED: If the effects pass calibrates particle counts, FogVolumes, and capital ship explosion overdraw until frame times look acceptable on Ryan's RTX 5080, default-tier players on an RTX 3060 (or integrated GPUs like the Radeon 780M cited at 82 to 22 FPS in the brief) will hit severe frame-time spikes during multi-ship salvos and capital cook-offs.

Verdict

Verdict: The visual and effects architecture is currently a speculative HDR and geometry debt trap: its best-specified systems (R43 weapon marks, faction palettes, and WCAG flash budgets) fail in code or collapse mathematically at the 20-ship battle scale.

Single most important attack: Overturning the prior fx_implementation_review.md claim that the Godot effects build is "PARTIAL" with breach geometry that "exceeds spec A"; in reality, the build fails R43 and R16 by letting any chip damage (including flak) trigger pre-placed structural craters while leaving persistent hit decals permanently glowing at 0.7 emission, unturned to activation phases, and unremoved upon ship repair.

Not checked

Live in-engine motion, shader compilation stutter, and visual framing: This pack contains text specs, synthesis audits, and short excerpts of perf3d.js and fx3d.js, with no rendered screenshots, video captures, or live Godot 4.7 frame-time traces.

Unexcerpted browser and Godot rendering source files: ships3d.js (983 lines), scene3d.js (686 lines), gfx3d.js (489 lines), wfx3d.js (471 lines), vfx3d.js (219 lines), meshopt3d.js (196 lines), ui3d.js (747 lines), and the raw .gd and .gdshader files in godot/fx/ and godot/render/ were referenced only via inventory counts or secondary audit summaries and could not be inspected directly from this pack.

Faction silhouette separation across the six fleets and rear-facing turret discipline: Apart from text descriptions of H8, H7, V1b, V17, and the Pyre-Barge in hull_surface_diagnosis_2026_10_27.md, 3D hull meshes and turret mount orientations (verifying no guns face backward on any space ship) were not present in the pack.

Actual shield and shield_edge RGB triples in godot/fx/faction_looks.json: Because palette_safety_2026_10_27.md omitted the raw linear triples and hex conversions for shield and shield_edge, exact pairwise contrast ratios for 3D faction shields against the violet enemy IFF ring (FOE_C) could not be computed from the pack.
