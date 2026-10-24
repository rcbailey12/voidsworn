# Pack J adversarial audit: Qwen 3.8-Max report (raw return, unverified archive)

Source: Qwen chat, model Qwen3.8-Max, Thinking mode ON, Web Search OFF. Pack J uploaded as .txt (473.9 KB) on the first attempt (no rename needed, no PDF used). No re-authentication needed; existing session signed in as Ryan Bailey / rcbailey12@gmail.com. No phone approval or CAPTCHA encountered. Report received Oct 24, 2026 via browser task. Filed verbatim below. Rey's screening and the three-way reconciliation are separate documents; nothing in this file is a verdict. This run supersedes the Qwen3.7-Plus run (packJ_qwen_audit.md) as the Qwen leg of the reconciliation.

## PACK J: ADVERSARIAL AUDIT VERDICT

### 1. Engineer
Verdict: GO WITH CONDITIONS
Next Step: Strike all phone-tier text from the corpus and define a hard, measured desktop VRAM and draw-call ceiling before writing any rendering code.
Phone-first ghosts contradict the PC-only ruling.
[ship_kit_upgrade.md] "per-class vertex and triangle ceilings for phone"
OBSERVED. The Oct 24 ruling dropped the phone target, but the kit spec and tool guides still enforce phone budgets and stress gates.
Background plate wiring is unmapped and unbuildable.
[READING_PLAN.md] "18 background plates against five terrain kinds with no mapping"
OBSERVED. The plate system cannot be wired to battle.js terrain kinds without a mapping document.
Desktop VRAM ceiling is entirely unmeasured.
[beauty_corner_spec.md] "desktop ceiling is set by measurement... not by this spec"
OBSERVED. The spec demands budgets but refuses to set a desktop VRAM ceiling, guaranteeing memory bloat.
Kit economics are asserted, not recomputed for the actual scope.
[READING_PLAN.md] "spec never recomputes the queue cost for dressing 35 existing meshes"
OBSERVED. The 69-session estimate assumes hull generation, not the dressing/paint/VSM conversion of existing meshes.
WebGPU fallback path is a maintenance trap.
[visual_expansion_research.md] "existing WebGPU scene cannot be swapped to WebGL afterwards"
OBSERVED. Adding a WebGPU path requires maintaining two completely separate rendering capabilities from boot, doubling QA surface.
TAA pipeline implementation is contradictory.
[verification_sweep.md] "Babylon ships a TAARenderingPipeline, but it is a separate pipeline"
OBSERVED. graphics_craft.md claims TAA doesn't exist in the default pipeline; the sweep corrects this, but the craft doc remains unpatched in the corpus.

### 2. Designer
Verdict: GO WITH CONDITIONS
Next Step: Resolve the Sins of a Solar Empire vs. Rogue Trader fleet-size tension and rewrite the Gold colour law to match faction trims.
The core benchmarks pull in opposite directions.
[READING_PLAN.md] "two benchmarks pull in opposite directions and no target battle size is stated"
OBSERVED. Sins 2 demands spectacle (many ships); Rogue Trader demands decision weight (1-3 ships). The ~20 ship compromise satisfies neither.
The Gold colour law fails on its own text.
[READING_PLAN.md] "Gold rationing fails... Chorus trim is dull gold, Ithar trim is pale gold"
OBSERVED. Rationing gold to Command/Patrons is impossible when two factions use gold-adjacent trims and epic rarity is gold.
Officer post scaling math breaks at 20 ships.
[CONVERSATION_CONTEXT.md] "Six officer posts carry the tactics" (Rogue Trader benchmark)
INFERRED. Applying Rogue Trader's 6-post density to a 20-ship Voidsworn battle creates 120 micro-decisions per turn, destroying pacing.
Shield shape identity fails at fleet zoom.
[visual_qa_pack.md] "shield identity is carried by ripple shape, while... glow is the first thing lost"
OBSERVED. Relying on ripple geometry (hexagons vs arches) for shield faction identity is unreadable when ships are specks at fleet zoom.
Per-faction destruction animations threaten turn resolution time.
[art_direction_rey.md] "no two factions die alike... spires toppling... deflates"
INFERRED. Complex, unique destruction sequences for 20 ships will cause massive animation bloat and stall the turn-based flow.

### 3. Gamer
Verdict: GO WITH CONDITIONS
Next Step: Prototype a 20-ship Corsair brawl to test asymmetry readability and trail overdraw before locking the silhouette grammars.
Corsair asymmetry is notoriously unreadable in top-down fleet views.
[art_direction_rey.md] "No Corsair hull is symmetrical... bolted donor sections"
INFERRED. Mandatory asymmetry makes it impossible for players to quickly parse ship facing or class at a glance in a 20-ship hex grid.
Deliberate trails in a 20-ship brawl will cause fill-rate death.
[beauty_corner_spec.md] "Trail screen area is budgeted, not trail count"
INFERRED. 20 ships moving simultaneously with "long, faint, and wide" capital trails will cause massive transparent overdraw, tanking the framerate.
The 40% luminance cap will make backgrounds look muddy.
[art_direction_rey.md] "no background pixel... may exceed 40% of the luminance"
INFERRED. Crushing background luminance to 40% of an unlit hull facet to preserve readability will rob the "Sins 2 cinematic" benchmark of its contrast and depth.
Fading UI during spectacle hides tactical data.
[visual_expansion_research.md] "fade non-essential HUD panels to about 30 percent opacity"
INFERRED. Fading the HUD during a capital kill hides the exact damage numbers and status effects the player needs to see to plan their next turn.
Cyan-only shields pose a severe colorblind risk.
[art_direction_rey.md] "Cyan means shields. Nothing else is cyan"
INFERRED. Relying on a single cyan hue for all shield states across all factions will fail deuteranopia/protanopia simulations against white/grey hulls.

### 4. Sci-fi (fiction coherence)
Verdict: GO
Next Step: Clarify if Deathless "bone" is a metaphor for ceramic or literal biological material to resolve the machine/organism contradiction.
Deathless "bone" contradicts their "machine" ruling.
[art_direction_rey.md] "bone white structural ribs... ribcage the size of a station"
OBSERVED. Ryan ruled Deathless are "machine intelligences... robotic", but the art direction uses biological "bone" and "ribcage" terminology.
Voidsworn "cathedrals" violate the "never naval" ruling.
[art_direction_rey.md] "A cathedral that launches fighters... stained-glass"
OBSERVED. Ryan ruled "Space ships, never naval ships", but the Voidsworn Basilica is explicitly described as a gothic cathedral with stained glass.
Razormaw naming contradicts the Chorus anatomy ban.
[CONVERSATION_CONTEXT.md] "Razormaw is a fleet formation whose ring reads as a maw"
OBSERVED. Ryan banned Chorus names based on animal body parts, yet approved "Razormaw" (a maw/mouth).
Vesper propulsion is physically incoherent.
[art_direction_rey.md] "Vesper... no visible engines, light bending"
OBSERVED. A ship with no visible engines or sails cannot maneuver in a vacuum, breaking the hard-sci-fi tactical weight benchmark.
Hegemony "parade finish" contradicts battle damage.
[art_direction_rey.md] "parade finish kept even in battle"
OBSERVED. A faction that takes per-section structural damage (BattleTech benchmark) cannot logically maintain a pristine parade finish in a 20-ship brawl.

### 5. QA (verification)
Verdict: NO-GO
Next Step: Halt all AI mesh pipeline integration and mod-scene pattern adoption until TripoSG and FTL Hyperspace licences are explicitly verified.
TripoSG licence is unverified, blocking the AI mesh pipeline.
[verification_sweep.md] "TripoSG licence: STILL UNVERIFIED"
OBSERVED. The entire AI mesh cleanup pipeline relies on a tool whose commercial shipping rights are unknown.
FTL Hyperspace licence is unverified, blocking mod patterns.
[verification_sweep.md] "FTL Hyperspace licence: STILL UNVERIFIED"
OBSERVED. The mod scene field guide recommends stealing Hyperspace's event hooks, but its licence is completely missing.
ESA audio terms are unverified, blocking an audio source.
[verification_sweep.md] "no ESA audio terms page was found... audio still open"
OBSERVED. The field guide recommends NASA/ESA audio, but ESA audio terms remain unverified, posing a legal risk.
Golden save compatibility test cannot run.
[tool_guides.md] "keep one golden save from each shipped version"
INFERRED. The pipeline demands a golden save to block ID-renaming bugs, but no golden save exists yet to test against.
Ryan's manual effort budget contradicts the QA pack.
[CONVERSATION_CONTEXT.md] "Ryan's manual effort is a hard budget"
OBSERVED. The visual QA pack demands massive, multi-shot screenshot batches per hull, which will instantly exhaust Ryan's manual review budget.

### Not checked
The mega-sim balance CSVs: The compute/ folder balance references were not verified because the mega-sim was "still running" when the corpus was written.
Actual Babylon.js WebGPU vs WebGL2 performance deltas: The corpus asserts WebGPU compute shaders will save the phone/desktop fill-rate, but no actual profiling on the target desktop hardware was verified.
Ryan's actual tolerance for the 40% luminance cap: The cap is mathematically defined, but whether Ryan will actually approve "muddy" backgrounds when he sees them in practice is unverified.
The 15 ungenerated admiral portraits: The locked template is defined, but the actual generation and approval of the remaining 15 portraits has not occurred.

### Top 10 Findings Across All Lenses
1. Benchmark Tension (Designer): Sins 2 (spectacle/many ships) and Rogue Trader (weight/few ships) are fundamentally incompatible at the ~20 ship scale.
2. Phone-first Ghosts (Engineer): The PC-only ruling is contradicted by persistent phone-tier budgets, stress gates, and readability checks throughout the corpus.
3. Gold Colour Law Incoherence (Designer): The law rationing gold to Command/Patrons is mathematically broken by Chorus/Ithar trims and epic rarity colours.
4. Background Plate Wiring (Engineer): 18 plates exist against 5 terrain kinds with zero mapping, making the background system unbuildable.
5. TripoSG / Hyperspace Licence Blocks (QA): Core pipeline tools for AI meshes and data-driven modding are legally unverified, risking DMCA or licence violations.
6. Desktop VRAM Ceiling Unmeasured (Engineer): The beauty corner spec refuses to set a desktop VRAM ceiling, guaranteeing memory bloat in a 20-ship battle.
7. Shield Shape Readability (Designer/Gamer): Relying on ripple geometry for shield faction identity is completely unreadable at fleet zoom when glow is lost.
8. Kit Economics Un-recomputed (Engineer): The 69-session queue cost assumes hand-building hulls, not the actual scope of dressing/painting 35 existing meshes.
9. Trail Overdraw in 20-Ship Brawls (Gamer): 20 ships with deliberate, wide capital trails will cause massive transparent overdraw, destroying the cinematic framerate.
10. Corsair Asymmetry Readability (Gamer): Mandatory asymmetry makes it impossible for players to quickly parse ship facing or class at a glance in a hex grid.

### Evidence that would change these verdicts:
- A unified design document explicitly resolving the Sins/RT fleet-size tension (e.g., capping battles at 6 heavy ships).
- A patched art_direction_rey.md that redefines the Gold law to accommodate faction trims.
- A verified TripoSG LICENSE file explicitly granting commercial shipping rights.
- A mapped plate_to_terrain.json wiring the 18 plates to the 5 terrain kinds.
- A profiled Babylon.js desktop build proving that 20 ships with trails and 40% capped backgrounds can hold 60fps without exceeding a stated VRAM ceiling.
