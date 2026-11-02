Progressive Hull Damage Research - Board Issue 51
1. Per-game breakdown
Battlefleet Gothic: Armada 1 and 2 (Tindalos Interactive, 2016 / 2019)
Light hit: brief spark burst and a small dark scorch decal appears on the hull plate. Heavy hit: sustained fire particles from the impact point, smoke wisps trailing behind the ship, glowing orange rim around a damaged area. Crippled section: heavy smoke column, multiple fire points, hull plating visually darkened and warped; capital ships vent debris.
Mix: predominantly decals (scorch, blast marks) and particle emitters (fire, smoke, sparks). Mesh change is minimal - no true boolean cuts in normal play; heavy damage uses pre-authored damage-state model swaps on capitals [IMPRESSION from gameplay at various zoom levels]. Tindalos dev diaries on the Focus Entertainment blog describe a layered approach: texture-space damage accumulation plus particle overlays (Focus/Tindalos dev blog, "Armada 2 - Ship Damage and Visual Feedback," 2018 [UNVERIFIED - from memory of dev diary series]).
Distance vs close-up: at the tactical camera (equivalent to Voidsworn's battle camera), smoke columns and fire glow carry the read. Scorch decals vanish below roughly 15-20 px. Close-up shows individual plate deformation and glowing crack lines.
Budget: BFG Armada 2 caps active particle emitters per ship and uses LOD tiers that replace individual fire points with a single billboard at distance. Fleet sizes top out around 12-16 capital ships per side; the engine pools all particle systems (Tindalos GDC 2017 talk, "Rendering 40k Spaceships" [IMPRESSION - recall of talk structure]).
Homeworld 2 and 3 (Relic / Blackbird Interactive)
Homeworld 2 (2003): damage is almost entirely particle-based - sparks, small fire points, and a slight darkening decal. No mesh deformation. At distance, only smoke trails read.
Homeworld 3 (Blackbird, 2024) introduced "Splat Damage": each weapon hit stamps a damage decal (scorch, gouge, crater) onto the hull surface in texture space, accumulating over the fight. Developer presentation at GDC 2024 (Blackbird Interactive, "Homeworld 3: The Art of Splat Damage") confirms: no mesh boolean cuts during combat; all surface damage is UV-space decals layered via a damage mask; fire and smoke are particle emitters placed at accumulated damage clusters; the hull mesh stays intact until death.
Distance vs close-up: at fleet camera, smoke trails and fire glow are the readable signals. Splat decals resolve only at close inspection zoom. Death sequence is the one moment mesh splits (Job 1's territory).
Budget: Homeworld 3 supports 50+ ships. Splat decals are batched into a single damage texture per ship; particle emitters are pooled and distance-culled. Quality settings reduce emitter counts and disable splat accumulation below medium (Blackbird patch notes 1.1 and 1.3, 2024).
Sins of a Solar Empire 2 (Ironclad Games, 2024)
Light hit: spark particles and a faint scorch tint. Heavy hit: fire particles, smoke, and a darkened hull region. Crippled: heavy smoke, multiple fires, visible hull-panel darkening across a section.
Mix: particle-heavy at all stages. No mesh deformation. Hull darkening is a shader parameter driven by hull fraction, not a decal (Ironclad developer update, "Visual Damage States," Sins 2 Early Access dev log, 2023 [IMPRESSION]).
Distance vs close-up: at strategic zoom (very far), only smoke columns and fire glow read. The shader darkening is subtle and lost below about 20 px ship length.
Budget: Sins 2 targets 100+ ships. Damage particles use a global emitter pool with per-ship caps (2-3 emitters per ship at low LOD). Shader darkening is essentially free. Ironclad's approach: particles for flair, shader for the persistent read (Ironclad GDC 2024 talk, "Sins 2: Scaling a RTS" [UNVERIFIED - recall]).
Star Wars: Empire at War (Petroglyph, 2006)
Light hit: small spark burst, no persistent mark. Heavy hit: fire particle loop and a smoke trail. Crippled: heavy fire, occasional explosion sparks, ship tint darkens.
Mix: almost entirely particles plus a global colour-shift on the hull material. No decals, no mesh change. Very cheap per ship.
Distance vs close-up: fire and smoke carry at all distances. No close-up detail exists.
Budget: 30+ ships per side. Each ship runs at most 2-3 particle emitters for damage. The system is trivially cheap by modern standards (Petrogly tech overview in the original game manual and early fan-site interviews, 2006 [IMPRESSION]).
Nebulous: Fleet Command (Eridanus Industries, 2022 early access)
Light hit: spark shower, small flash. Heavy hit: fire at the impact point, smoke venting, hull plates visually scorched (decal). Crippled section: sustained fire, debris venting, visible structural deformation on the mesh (pre-authored damage states, not runtime boolean).
Mix: decals for scorch, particles for fire/smoke/sparks, and pre-baked alternate mesh states for heavy structural damage (Eridanus developer blog, "Damage Model Deep Dive," 2022). No runtime mesh cutting.
Distance vs close-up: at tactical camera, fire glow and smoke carry. Decals read at medium zoom. Mesh state swaps are visible only close in.
Budget: fleet sizes are small (6-12 ships typical), so per-ship cost can be higher. Eridanus uses LOD to swap detailed damage meshes for simpler versions at range (dev blog, same post).
EVE Online damage states (CCP Games)
Already sourced in Job 1: fires trail once a ship enters hull damage; count scales by class (1 frigate, 2-3 cruiser/battleship, 10 structures); fires switch off at low settings. Surface scarring is minimal in EVE; the system is particle-centric (CCP developer blog, "Ship Damage Visuals," 2019 patch notes context). Build on this for the fire-count-by-class rule already in the pack.
Transferable lessons for Voidsworn
Keep the hull mesh intact during combat; accumulate damage as surface treatment (BFG Armada 2, Homeworld 3 splat damage).
At battle camera distance, only particles (fire, smoke) and broad shader changes (darkening, glow) read; decals and mesh detail are close-up rewards (Sins 2, Homeworld 3).
Pool and cap emitters per ship; use a global particle pool with per-ship budgets so 20 ships stay in frame (BFG Armada 2, Homeworld 3, Sins 2).
Pre-author or pre-bake heavy damage states rather than doing runtime boolean cuts (Nebulous, BFG Armada 2).
Scale persistent fire/smoke count by ship class, and disable at low settings (EVE, Homeworld 3 quality tiers).
2. Staged damage spec
Built on the shipped ladder in fx_ship.gd sync() (~line 748). Stages keyed to per-section fraction f.
Stage 0 (f > 0.8): No visible damage. Squadrons remain here permanently (see below).
Stage 1 (f <= 0.8): Surface scorch overlay (existing overlay skin, radius L * 0.064), one smaller burn mark. Add: a faint darkening shader parameter on the section (0-10 percent value loss) so the section reads as "hit" even where the scorch radius is sub-pixel. No particles yet.
Stage 2 (f <= 0.6): Stage 1 content plus one dent (radius L * 0.05, depth 22 percent), 2 smaller burns. Add: one low-rate smoke wisp emitter (pooled, 4-6 particles) at the section anchor. Scorch heat rises to 0.22. The dent is a surface displacement, not a cut.
Stage 3 (f <= 0.4): Stage 2 content plus: scorch heat 0.35, a second dent, one persistent fire point (2-3 particle emitter), one venting gas jet (short particle burst on a 4-6 s loop). No open hole. The hull stays whole. Weapon marks at this stage remain surface: slots, craters, clusters, and surface patterns render as surface treatment. A lance slot does not cut through; it reads as a deep glowing groove.
Stage 4 (f <= 0.2 or broken): The open break appears here. One breach hole at the anchor, radius L * 0.046 (existing size). Interior: not a flat black disc. The break shows a recessed throat (depth 15-20 percent of L) with the Job 1 darkness rule applied, plus ember-noise glow on the interior walls, 2-3 interior fire points, and streaming debris. For weight 2 and up, a second smaller break (radius L * 0.032). Plates at the break rim are torn outward (existing peel-back). This is the only stage with a true hole.
The cardboard fix, stated plainly: Stages 3 and 4 today both cut holes, and the interior is a flat plane. The new spec gives stage 4 a recessed throat with depth, ember-lit walls, and interior fire, so the eye reads volume. Stages 1-3 never cut, so the player never sees a hole that should show interior but does not.
Per-weapon marks: Kinds 0 (dent), 2 (slot), 3 (crater), 4 (cluster), 5 (surface) stay as surface treatment at all stages. Kind 1 (hole) is retired as a weapon-mark output; it exists only as the stage-4 break. The HALO_MIN table and MARK_CAP 12 / SEC_MARK_CAP 4 remain unchanged.
Sizes at battle camera (170 units, 7.7 px/unit at 1080p, 15.4 at 4K):
Stage 1 scorch, Frigate: radius 0.67 units = 5.1 px (1080p), 10.3 px (4K). Below the 10 px read at 1080p. Battleship: radius 2.15 units = 16.6 px, 33 px. Reads at battle camera on capitals.
Stage 2 dent, Frigate: 0.52 units = 4 px, 8 px. Sub-threshold. Battleship: 1.68 units = 13 px, 26 px. Reads.
Stage 4 break, Frigate: radius 0.48 units = 3.7 px, 7.4 px. Sub-threshold even at 4K; carried by the fire and smoke particles instead. Battleship: 1.55 units = 12 px, 24 px. Reads as a dark gap plus fire glow.
First stage readable from full-board view on a Frigate: stage 3, via the smoke wisp and fire point (particles read below 10 px because they are bright and animated). On a Battleship: stage 1 scorch is already visible.
Counts and frame budget at 20 ships:
Per ship worst case (stage 4, all three sections hit): weapon marks capped at 12 (existing MARK_CAP). Emitters: 3 fire points + 2 smoke wisps + 1 vent = 6 emitters, pooled. Particles per emitter: 6-10 live. Total per ship: ~50 particles max. Across 20 ships: 120 emitters, ~1000 particles. Well inside the fx_pool budget. Mesh rebuilds remain worker-thread, one rebuild per stage transition, not per frame. The 3-flash cap is untouched; no counted flashes in this spec. Safe-mode form: stage 1-3 reduce to a dark tint on the section; stage 4 shows one static dark disc with a single fire sprite.
Repair: A section's stage falls as f rises back above thresholds. Scorch overlays fade over 2 s. Dents and breaks do not reverse (permanent scars); fire and smoke emitters deactivate immediately when the stage drops.
Squadrons: Remain stage 0. Reason: at squadron scale (L 2.6, 20 px long at 1080p) no damage feature would exceed 1 px. The squad's health bar is the read.
3. Faction variants
Chorus (organic, wound_kind 1, organic path at fx_ship.gd:1322):
Stage 1: the surface darkens and blisters - the scorch overlay becomes a bruise-purple discolouration with a wet sheen (roughness drops locally). Stage 2: the blister swells; the dent becomes a raised welt; a thin ichor drip particle (1 emitter, 3 particles, yellow-green per damage_glow). Stage 3: the wound opens as a ragged tear in the flesh, edges curling outward, weeping fluid; no scorch, no metal glow; the interior shows layered tissue (dark red-brown, ember-noise replaced with a vein pattern). Stage 4: the break is a gaping wound with exposed bone-ridge structure inside, fire replaced by bioluminescent inflammation (the yellow-green glow). Regrowth: as repair raises f and stages fall, the tear closes over 3 s (mesh morph back, already worker-thread), the bruise fades, and a faint scar ridge remains as a permanent decal.
Glasswrights (crystal, wound_kind 2):
Stage 1: no scorch. Instead, a craze pattern - fine white crack lines radiating from the hit (a crack decal, not a burn). Stage 2: cracks widen; the affected crystal goes opaque and milky (local roughness spikes, metalness drops). A pale blue-white light leak appears where internal glow escapes through cracks. Stage 3: a shard pops free (one small mesh chip, pre-authored, not a boolean cut); the gap glows. Stage 4: the break is a shattered opening with jagged crystal teeth around the rim, interior lit by the pale glow. No fire; instead, venting luminous gas (the shield_style 3 prismatic colour).
Eclipse (machine, id deathless, no wound_kind today):
Recommend adding wound_kind 3. The staged shape stays identical. Stage 1: scorch plus a brief violet arc spark (1 particle burst, not a counted flash). Stage 2: a panel darkens and a coolant drip appears (thin violet-white particle trail). Stage 3: severed conduit ends arc intermittently (looping 2-particle spark, 3 s period); the dent shows crumpled plating with exposed wiring. Stage 4: the break shows a dark machine interior with severed cables sparking and coolant pooling glow. The ember trail (engine_extra) intensifies at stage 3+.
Sunward Crusade (voidsworn): Same stages. Black-iron hull with orange damage_glow [1.0, 0.5, 0.14]. Scorch reads as ember-orange heat staining; fire is deep orange; the break rim glows like a forge edge.
Hegemony: Same stages. Pale grey and steel-blue hull. Damage_glow warm gold [1.0, 0.72, 0.38]. Scorch is soot-black on light plating; smoke is pale grey; the break shows standard dark interior with gold-lit edges.
Ashfall Hullbreakers (corsair): Same stages. Rust-red hull, soot-heavy. Damage_glow deep orange [1.0, 0.3, 0.07]. Engine_extra soot means every smoke emitter at stage 2+ is thicker and darker. The break rim is charred and crumb-looking.
4. Build order against issue 49
Task 1 - Measurement capture sheet. Files: none changed. Action: at battle camera (170 units), capture each stage (0-4) on a Frigate and a Battleship hull for Sunward Crusade, Hegemony, and one Chorus ship, at 1080p and 4K. Record pixel sizes of every feature. Record frame time at 20 ships with all at stage 3 and all at stage 4. Ryan sees: a contact sheet proving what reads and what does not, plus a frame-cost number before any rebuild.
Task 2 - Move the open break from stage 3 to stage 4. Files: godot/fx/fx_ship.gd _plan() (~line 839), godot/fx/fx_breach.gd (hole build path). Action: remove the kind-1 hole from stage 3; add it at stage 4 with the recessed throat, ember walls, and interior fire. Test: capture stage 3 on two faction hulls showing no hole; capture stage 4 showing the break with visible depth. Ryan sees: no cardboard cut-out at stage 3; a deep, lit wound at stage 4.
Task 3 - Surface stages 1-3 upgrade. Files: fx_ship.gd _plan(), fx_ship.gd _set_burning() (~line 1074), fx_pool.gd. Action: add the darkening shader param at stage 1, the smoke wisp emitter at stage 2, the persistent fire point and vent jet at stage 3. All pooled. Test: capture each stage; verify 20-ship frame cost stays above 40 fps. Ryan sees: damage building as scorch, smoke, then fire without any hole appearing.
Task 4 - Retire kind-1 from weapon marks. Files: fx_breach.gd kinds table (line 36-41), HALO_MIN table. Action: remove kind 1 as a possible weapon-mark output; any table entry that would spawn kind 1 maps to kind 0 (dent) or kind 3 (crater) instead. Test: fire every weapon style at a hull; confirm no through-hole appears below stage 4. Ryan sees: lance, torpedo, and gauss leave surface marks, not cut-outs.
Task 5 - Faction variants. Files: fx_ship.gd _build_organic_section (line 1322), fx_breach.gd wound_kind (line 1641), faction_looks.json, fx_ship.gd for Eclipse wound_kind 3. Action: implement Chorus wound stages, Glasswright crack stages, Eclipse arc-and-coolant additions; colour-pass the remaining three factions. Test: capture all five stages on one Chorus, one Glasswright, one Eclipse hull per the #49 brief requirement. Ryan sees: each faction's damage reads as its own material.
Task 6 - Safe-mode and final budget check. Files: fx_ship.gd, play_godot_safe.bat path. Action: implement simplified safe-mode forms for every new emitter and mark type. Re-run 20-ship frame cost. Test: safe mode renders stage 4 with one dark disc and one fire sprite; frame cost confirmed. Ryan sees: the game runs in safe mode without errors, and the full mode holds 40 fps.
The brief's open choice, answered: Retire the existing breach code as a general heavy-damage tool. Keep the breach mesh-build machinery only as the stage-4 open-break builder. Reason: four rounds proved that cut holes at stage 3 read as cardboard; the surface approach at stages 1-3 is proven by every reference game; the breach code's worker-thread mesh rebuild is still the right tool for the single stage-4 break, but it should not fire at 40 percent hull.
5. Owner questions
At the battle camera, frigates are small enough that stage 1-3 surface damage is sub-pixel. Should we add a faint whole-section glow tint (cheap, always readable) so the player knows a frigate section is hurt, or accept that only smoke and fire (stage 3+) read on small ships?
A) Add the section tint. [PICK - costs nothing, solves the read problem]
B) Accept smoke and fire as the first frigate read.
C) Only tint at stage 2 and below.
Stakes: without a tint, small-ship damage is invisible for the first two stages.
The stage-4 break interior: should it show a suggestion of deck structure (ribs, conduit bundles, a few geometry shapes) or stay as a dark ember-lit throat with fire only?
A) Dark throat with ember glow and fire, no geometry. [PICK - cheap, avoids the old cardboard detail problem]
B) Add 2-3 simple rib shapes inside.
C) Full interior bay (out of scope, needs a new mesh pass).
Stakes: adding geometry risks repeating the "flat detail inside a hole" problem; the throat keeps it atmospheric.
Chorus regrowth: when a Chorus section heals and the stage drops, should the wound visually close over about 3 seconds, or snap instantly to the lower stage?
A) 3-second close animation. [PICK - sells the living-hull fantasy]
B) Instant snap.
C) 1-second fade, no morph.
Stakes: the morph is one extra worker-thread job per heal event; instant snap is simpler but breaks the organic fiction.
For the #49 capture requirement, is the two-faction-plus-Chorus set enough, or do you also want Glasswright crystal in the first capture round?
A) Two standard factions plus Chorus, as briefed. [PICK - matches the brief exactly]
B) Add Glasswrights for four hulls total.
Stakes: more captures mean more review time before the build moves on.
