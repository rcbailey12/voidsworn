# Progressive hull damage: chair synthesis (issue 51)

Verdict: GO. All four legs converge on the same core move, and it is the move the issue brief already points at: keep the hull sealed through stages 1 to 3 and let the open break appear only at stage 4, filled and lit from inside. The shipped ladder cuts its first hole at stage 3 with 20 to 40 percent of the section hull still left, into a single skin mesh with a flat shaded interior. That is the cardboard cut-out in Ryan's Nov 2 playtest shots (ryan_b03, b04, b06 to b08, FINDINGS R70). This synthesis settles the staged spec, the faction variants, the 20 ship budget, and a build order sized as Codex tasks against issue 49, whose item 6 surface damage build has not landed yet (issue 49 still open at grounding, main f506818). This research is the yardstick that build gets measured against.

Legs: DeepSeek (DeepThink and Search on), Qwen (Qwen3.8-Max, both gates passed), Argon (4 Argon, High, both gates passed, drafts only per the issue block, chair rewrote what it used), and a blind Rey leg. Screening notes are at the end.

## 1. What the reference games establish

Across all six comparator games plus EVE Online and Star Citizen, no leg found a shipped fleet game that cuts boolean holes into a live hull during combat. The universal pattern is surface accumulation plus particles while the ship fights, and pre-authored breakup at death. That is the strongest single finding in the pack, and it is unanimous.

Battlefleet Gothic: Armada 1 and 2. Surface charring, emissive fissures, and subsystem loss carry the read; crippled subsystems burn and trail smoke while the hull body stays sealed until death splits it into pre-fractured pieces. Lesson: functional loss and fire read farther than decals.

Homeworld 2 and 3. Homeworld 2 projects scar badges that cool from hot edges to dark soot and ignites fixed smoke and fire hardpoints at crippled thresholds (Simon Schreibt's scar rendering write-up). Homeworld 3 paints impacts into a per-ship damage texture (the Splat Damage system, Blackbird at Unreal Fest 2023 and the O'Connell developer blog). The legs disagree on one point: DeepSeek describes a geometry deformation component, Qwen describes texture-only splats with no mesh deformation. The chair did not resolve that against the primary talk; it does not change this spec, because Voidsworn's equivalent machinery is the breach overlay and mark system, not a splat render target. Lesson either way: cumulative surface damage at fixed cost per ship, independent of hit count.

Sins of a Solar Empire 2. The surface layer is deliberately thin: scorch masks, faction tinted emissive cracks, venting plumes from pre-authored sockets, hull whole until the death explosion. The readable band is the crippled state, not per-hit detail. Lesson: at fleet scale, spend on the crippled read, not on hit fidelity.

Star Wars: Empire at War. Damage is hardpoint based: each targetable hardpoint carries its own decal and particle set, and a destroyed hardpoint swaps to a charred stump with a permanent smoke column and fire. Lesson: per-section emitters anchored to the section, which maps directly onto Voidsworn's three-section hulls.

Nebulous: Fleet Command. A localized armor texture mask records where hits landed; interior fires vent through the penetration marks while the hull stays solid. Lesson: spatial memory of hits is cheap and sells the simulation without cutting the mesh.

EVE Online. Once damage reaches hull, a shader erodes paint to blackened plating and ember seams, and persistent fire is capped by hull class (Job 1 recorded the caps: frigate 1 fire source, cruiser 2, battleship and carrier 3). Lesson: class caps are how a 20 ship board stays in frame budget. This spec adopts EVE style caps, set out in section 4.

Star Citizen (extra entry, close-up game, used for one lesson only). Its damage exposes pre-built interior structure under a worn surface, so a stripped section never shows an empty shell. Lesson for stage 4 only: a break needs something inside it. It is not evidence about fleet scale budgets and the chair does not use it that way.

## 2. The staged damage spec

Thresholds stay as shipped: per-section hull fraction f, stage 1 at f <= 0.8, stage 2 at <= 0.6, stage 3 at <= 0.4, stage 4 at <= 0.2 or broken (fx_ship.gd sync(), about line 748; stage builds in _plan(), about line 839). Camera reference: about 170 units, 7.7 px per unit at 1080p, 15.4 at 4K; the owner plays at 4K. Sizes below are given as diameter where readability is judged, because a scorch reads by its full width.

Stage 1 (0.6 < f <= 0.8). Scorch overlay only, as shipped, radius grows: primary scorch R = 0.064 x L (diameter 0.128 x L: Frigate 1.33 units, 10.2 px at 1080p; Battleship 4.30 units, 33.1 px), scorch heat 0.22, plus one secondary burn. Up to 2 surface weapon marks. No mesh change, no persistent emitters, one-shot spark burst on transition. Chair note: on diameter, stage 1 scorch is already over the 10 px readability line on every class at 1080p and clearly readable at 4K, so no extra readability device is adopted here (see owner question 2 for the rejected tint alternative).

Stage 2 (0.4 < f <= 0.6). Primary scorch R = 0.098 x L, heat 0.35, two secondary burns, up to 3 surface marks. One anchor dent, R = 0.05 x L, depth 22 percent of radius (two legs agree on these numbers). NEW: one persistent smoke trail per damaged section at this stage, length about 0.25 x L, on all weight classes, subject to the class caps in section 4. Stage 2 is the first stage that reads on a small hull from the full board view, because the smoke moves.

Stage 3 (0.2 < f <= 0.4). Primary scorch R = 0.132 x L, heat 0.55, three secondary burns, up to SEC_MARK_CAP 4 surface marks. The shipped stage 3 hole is RETIRED. In its place: one deep buckled fissure crater (crater plus slot lips), R = 0.06 x L, depth 35 percent, over intact dark sub-hull. One persistent fire point and the smoke trail per damaged section; one vent jet on a slow loop for weight 3 and 4 hulls; engine sections sputter. No open break at this stage, with 20 to 40 percent section hull remaining. This single change removes the playtest complaint.

Stage 4 (f <= 0.2 or broken). Primary scorch R = 0.166 x L, heat 0.75. The first and only open break: a tight throat, R = 0.032 x L, inside a wide torn collar of diameter 0.14 x L with stepped, curled plate tabs, so the wall reads as thick armour. The collar is what reads at camera distance (Frigate 1.46 units, 11.2 px at 1080p; Battleship 4.70 units, 36.2 px); the throat is fire lit, not a size read. Weight 2 and up get a second, smaller break at R = 0.032 x L (three legs keep a second break; Argon's draft drops it, chair keeps it). Inside the break, four requirements, all mandatory:
- Darkness rule from Job 1: the cavity is near-black with ember noise, never a flat disc and never the current flat line pattern, which is removed.
- Recess: throat depth 15 to 20 percent of L, walls angled inward.
- Structure: 2 to 3 low-poly cross members or pipe stubs spanning the cavity (12 to 18 triangles), so a close zoom sees structure, not a shell. Qwen's no-geometry throat is the dissent here; the chair sides with the other three legs and the Star Citizen lesson, because an empty dark throat is the cardboard problem one shade darker.
- Fire seated inside: the section fire emitter sits inside the throat, offset inward, so flame and embers come out of the break. Plus streaming debris and spark showers on transition.

Weapon marks. Mark kind 1 (hole) is retired as a weapon mark output at every stage; below stage 4 nothing a weapon does can perforate. The clamp table, adopted from the Argon draft and checked against the pack's kinds table (fx_breach.gd lines 36 to 41): burn builds a slot with raised molten lips over a solid glowing floor; shell, plasma, gauss in and out, and blast build crater bowls; flak, acid, and hatch build shallow cluster pits with no torn-through holes; ram builds a dent; ion builds a surface mark. MARK_CAP 12 per ship and SEC_MARK_CAP 4 per section stay.

Repair. When repair raises a section's stage: fire, smoke, and vent emitters stop or fade within about a second (0.8 s fade adopted). A section repaired out of stage 4 is sealed with a visible patch: welded patch plate on metal hulls, fused seam on Glasswright, regrown scar skin on Chorus. Scorch fades partway and dents, craters, and the patch stay as permanent scars for the rest of the battle. A repaired ship should look like a survivor, not a reset.

Squadrons. Squadrons stay at stage 0 for mesh and scorch (at L = 2.6 every surface feature is sub-threshold). One addition: a pooled smoke ribbon trails a squadron whose total HP drops below half. The health bar remains the primary read. A hull state tint (DeepSeek) is not adopted; doing nothing beyond the health bar (Qwen) is the other option in owner question 5.

Counted flashes: persistent damage fire and molten rims spend zero against the Job 1 cap of 3 counted flashes per rolling second; they are continuous emission, not flashes. Safe mode (play_godot_safe.bat) drops the dent, break geometry, and emitters and keeps flat scorch and mark rings.

## 3. Faction variants

The hooks exist: faction_looks.json carries a damage_glow per faction, the breach shader has wound_kind 0 standard, 1 Chorus, 2 Glasswright (fx_breach.gd lines 1641 and 1653), and Chorus has its organic section builder (_build_organic_section, fx_ship.gd line 1322). Eclipse has no wound variant today; this spec adds one.

Chorus (wound_kind 1). No metal scorch and no dents. Stage 1: bruised contusion halo in dark purple, rimmed by the faction's yellow-green glow [0.66, 0.92, 0.16]. Stage 2: swollen soft-lipped concavity with a wet sheen, weeping spore puffs instead of smoke. Stage 3: deep non-perforating gash exposing striated muscle and pulsing veins, venting bio-mist and spore clouds. Stage 4: oval tear framed by curled dermal lips, curved bone-cartilage ribs inside instead of metal cross members, bioluminescent organ sacs in a crimson-black throat. On regrowth or repair the wound visibly knits closed over about 3 seconds and leaves a pale scar ridge. Chorus fire is spore and ichor venting, never orange flame.

Glasswrights (wound_kind 2). Crystal does not char. Stage 1: frosted white micro-crazing web with radial stress fractures lit from inside by pale blue-white [0.85, 0.92, 1.0]. Stage 2: stepped conchoidal facet chip with sharp polygonal normals, trailing glittering crystal dust instead of smoke. Stage 3: deep non-perforating fault fissure with internal cleavage planes, venting prismatic vapour. Stage 4: polygonal cleavage break into an indigo-black cavity spanned by fractured crystal spire ribs and severed silver conduits, with drifting glass shards. NO fire at any stage on a Glasswright hull: light and vapour only, which keeps the faction's light idiom clean. On repair the break seals with an opaque fused-quartz seam.

Eclipse (NEW wound_kind 3). All four legs ask for a full machine variant, and the hooks are one shader branch away. Stage 1: nearby hull lights go out; angular, panel-aligned dead sectors bordered by violet circuit traces [0.72, 0.5, 1.0]. Stage 2: crushed plate with intermittent violet electrical arcs across the rim and thin coolant leaks. Stage 3: exposed conduit trenches, severed cables sparking violet-white, guttering purple embers, dark dielectric smoke instead of grey. Stage 4: machine-bay cavity with geometric rack ribs and severed bus bars, violet plasma fire and arcing inside the dark throat. On repair, panels reboot in sequence and the patch reads as a replacement panel, slightly cleaner than its neighbours.

The three metal factions keep wound_kind 0 with their shipped glows: Crusade furnace orange on black iron (heavy soot, slag rims, reactor ribs in the stage 4 break), Hegemony amber-gold on pale grey (peeled ablative tiles, crisp grey-white vent jets), Hullbreakers deep orange-red on rust-red salvage plate (greasy soot smears, scrap-girder ribs).

## 4. Counts and frame budget at 20 ships

Marks and meshes stay as shipped: MARK_CAP 12, SEC_MARK_CAP 4, one interior and one overlay mesh per ship, rebuilt on the worker thread at stage transitions and mark landings only.

Persistent emitters are capped per ship across all three sections, EVE style, adopted from the Argon draft's cap table: weight 1 hulls max 1 fire and 2 smoke; weight 2 max 2 fires and 3 smoke or vent; weight 3 and 4 max 3 fires and 4 smoke or vent. Sections beyond the cap show scorch and marks only. On a full 20 ship board (say 10 weight 1, 6 weight 2, 4 weight 3 to 4) the absolute worst case is about 34 fire or vent emitters and 46 smoke emitters board-wide, roughly 80 emitters and on the order of 1,000 pooled particles. DeepSeek's per-section accounting (up to 180 fire emitters board-wide) is rejected as too hot; Qwen's roughly 1,000 particle total lands in the same place as the adopted caps. The chair states this as caps plus arithmetic, not a measured frame cost: no leg measured anything on the actual build, and one draft's specific millisecond claim is excluded as unverified (see screening). Task 1 and Task 6 in the build order exist to replace these numbers with measurements before and after.

## 5. Build order against issue 49

Task 1, measurement baseline. Files: fx_ship.gd, fx.gd profiler, a deterministic capture script writing to docs/shots/playtest/. Capture: stages 0 to 4 contact sheet at battle camera and close zoom, 4K, on a Hegemony Cruiser, an Eclipse Battleship, and a Chorus Cruiser, plus a 20 ship frame profile. Ryan sees: the current cardboard holes and the missing section fires, with baseline frame numbers, before anything changes.

Task 2, re-gate the ladder and the weapon marks. Files: fx_ship.gd _plan() (about line 839), fx_breach.gd kinds table (lines 36 to 41) and caps (line 63). Change: no kind 1 hole while f > 0.2; stage 3 builds the fissure crater instead; weapon marks clamp to the surface table in section 2. Test: re-run the Task 1 sheet; assert zero cut holes in stages 1 to 3. Ryan sees: ships accumulating scorch, dents, and molten craters on a solid hull down to 21 percent section hull.

Task 3, rebuild the stage 4 break. Files: fx_breach.gd interior and hole builder, fx_ship.gd _build_breach(). Change: tight throat plus torn collar, flat interior line pattern removed, recessed ember-noise throat, 2 to 3 cross members, fire emitter seated inside, second smaller break on weight 2 and up. Test: 4K close captures on two factions plus Chorus at stage 4; safe mode fallback check. Ryan sees: a section at 20 percent tearing open into a dark, ribbed, burning cavity instead of an empty shell.

Task 4, persistent section emitters with class caps. Files: fx_ship.gd stage transitions and _set_burning() (about line 1074), fx_pool.gd, fx.gd flash guard. Change: smoke from stage 2, fire and venting from stage 3, stage 4 fire inside the break, per-ship class caps from section 4, emitter fade and patch sealing on repair. Test: 20 ship stress with every ship at stage 3 or 4; frame check against the Task 1 baseline; zero counted flashes spent. Ryan sees: wounded sections smoking, burning, and venting at board distance, and repaired sections going dark and plating over.

Task 5, faction variants. Files: fx_breach.gd wound_kind branch (lines 1641, 1653) extended with wound_kind 3, fx_ship.gd organic builder (line 1322), faction_looks.json. Change: Chorus bruise, gash, knit, and scar ridge; Glasswright crazing, facet chip, fault fissure, no fire; Eclipse dead panels, arcs, coolant, machine cavity. Test: final sign-off sheet, stages 1 to 4, two metal factions plus Glasswright, Eclipse, and Chorus, at battle camera and close zoom. Ryan sees: three non-metal hull types damaging in their own material language.

Task 6, budget and safe mode verification. Files: fx.gd, safe mode path. Change: none expected; verify the section 4 caps hold on the real build, replace the arithmetic with measured fx.prof numbers, and confirm play_godot_safe.bat renders the flat fallback. Ryan sees: the measured 20 ship frame cost next to the Task 1 baseline.

Breach code verdict, unanimous across the legs and adopted: keep fx_breach.gd, but only as the stage 4 break builder and the surface overlay and mark machinery. Do not retire it, and do not let it cut anything above stage 4.

## 6. Owner questions (chair pick marked)

1. When does the first open break appear? A (chair pick, all four legs): stage 4 only, at 20 percent section hull or broken. B: late stage 3 for battleships and dreadnoughts only. C: never during combat, hulls stay sealed until death. Stakes: how long ships read as solid warships versus flying wrecks.

2. Small ship readability at stage 1. A (chair pick): no new device; the scorch diameter already clears the readability line and stage 2 smoke carries small hulls. B: add a faint per-section darkening tint (0 to 10 percent value loss) so a damaged section reads as a block (Qwen). C: design to a class split, stage 1 reads on capitals, stage 2 is the frigate target (DeepSeek). Stakes: a tint is cheap but risks muddying faction paint across the whole board.

3. What repair leaves behind. A (chair pick, three legs): fires out, break sealed with a patch, dents and part of the scorch kept as permanent scars. B: fires out but the hole stays open. C: full clean restore as the stage drops. Stakes: whether a repaired ship carries its history or resets.

4. Eclipse damage variant. A (chair pick, all four legs): build wound_kind 3 now, in the same pass. B: Eclipse stays on the standard metal path with violet glow until a follow-up. Stakes: one extra shader branch against the machine faction reading as plain iron.

5. Squadron damage read. A (chair pick): stage 0 surfaces plus a smoke ribbon below half total HP. B: nothing beyond the health bar. Stakes: a small readability gain against one more pooled system to maintain.

## Owner rulings (Ryan, Nov 2, 2026)

Ryan ruled A on all five questions, adopting the chair pick on each:

1. First open break: A. Stage 4 only, at 20 percent section hull or broken.
2. Small ship readability: A. No section tint; scorch diameter and stage 2 smoke carry the read.
3. Repair: A, with a cost condition. Patch the break and keep the scars, as spec'd in section 2. If the patch build proves too costly inside the issue 49 pass, C (full clean restore as the stage drops) is acceptable to the owner; B (fires out, hole left open) is not.
4. Eclipse variant: A. wound_kind 3 built in this same pass.
5. Squadrons: A. Stage 0 surfaces plus a smoke ribbon below half total HP.

Owner note on squadrons, same ruling pass: the Q5 smoke ribbon is not the whole squadron story. Ryan flags that squadrons need a separate detailing pass of their own: they read as super static in battle, some factions show the wrong craft (regular fighters on Chorus ships is his example), and they need more detailing and more views. That is follow-up scope for Opus beyond this spec and beyond issue 49 item 6; it is recorded here so it reaches the board with the rulings, not folded into the six tasks above.

## Leg screening

Blind Rey leg (spine for the spec's shape): runs long at about 4,800 words against a 1,500 to 2,500 target, and its per-game sourcing is mostly secondary (guides, wikis, reviews); its true developer sources are the Homeworld 3 blog and the Nebulous wiki, and several of its budget claims are marked unverified in the leg itself. The chair weighted its game facts accordingly and used it for structure and the code-side calls, where it is grounded in the pack. Its break radius (grow to R = 0.08 x L) was not adopted; the chair took the tight throat plus wide collar instead, because the collar carries the camera read and a bigger empty throat is the original problem at larger size.

DeepSeek leg (Search on, the best sourced of the four): sound on BFG functional loss, Empire at War hardpoints, Nebulous, and the EVE caps. Its Star Citizen entry is a close-up game and is used only for the internals lesson. Its larger scorch radii and per-section emitter counts were not adopted (see sections 2 and 4). Its Homeworld 3 splat account conflicts with Qwen's on geometry deformation; unresolved, and immaterial to this spec.

Qwen leg (both gates passed): careful and code-close; several of its game citations are marked unverified or from memory in the leg itself, and the chair relied on DeepSeek where they overlap. Its section tint and its no-geometry stage 4 throat are recorded as dissents against owner question 2 and the section 2 interior call. Its particle total corroborates the adopted caps.

Argon leg (drafts only on this job): the model marks most of its game material as impression itself, and its mix percentages have no source behind them; they are not used. Its specific frame cost claim is unverified and excluded. What the chair did adopt, after checking each item against the pack and the shipped code values: the diameter based scorch progression, the stage 3 fissure numbers, the per-ship class emitter caps, the weapon mark clamp table, and the patch plate repair. It also mis-cites the playtest finding once as R76 (backdrops); the damage complaint is R70 and the Nov 2 playtest. Nothing from this leg enters the spec on its word alone.

## Not checked

No code was run and no captures were taken for this research; every size and budget figure is arithmetic from the pack's camera and hull numbers, and Tasks 1 and 6 exist to replace them with measurements. The Homeworld 3 splat conflict between the DeepSeek and Qwen legs is unresolved against the primary talk. Issue 49's build may have moved since grounding (main f506818, Nov 2); if Codex lands item 6 before these tasks start, Task 1's baseline becomes a comparison against that build instead. Flash behaviour of the new interior fire under the reduce flashing setting is asserted from the Job 1 rules, not tested.
