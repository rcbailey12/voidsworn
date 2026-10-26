# Effects implementation audit, Rey leg, 2026-10-26

Chair header: Rey's own audit for the effects implementation review, written blind alongside the DeepSeek, Qwen and Argon legs against the same evidence pack. One chair correction before filing: the B6 flicker rate is stated as a sin(now * 2.0) term (2.0 rad/s in the code), not 2 Hz; logged in the chair screening note. Everything else is as drafted.

Scope: godot/fx/ as built, judged against spec A (damage_marks_reference.md), spec B (the Job A counted-flash rule, a5_effects_sheets_synthesis.md section 8, line 118), and the fx API doc's own claims (fx_api_md.txt lines 128-129). Every code claim below was checked in the fx/*.txt copies and is marked OBSERVED or INFERRED. Spec line numbers for spec A are the reference's own entries and readability rules as numbered in that file.

## A. Per-weapon marks

### A1. Battery (including plasma): PARTIAL

OBSERVED. Battery impacts are transient pops, spark cones and debris (fx_weapons_gd.txt:605-637). The only persistent trace is a generic scorch decal at the real hit point, placed for non-light looks at size 0.9 (weight 2 or under) or 1.4 (weight 3) times scale (fx_weapons_gd.txt:635). Light looks (auto, las, scatter, and also flak and guns) leave no decal at all (fx_weapons_gd.txt:590, 635). Plasma sits in the same generic branch: it gets a 1.3 size multiplier on the transient, a warmer hit colour, and dripping slag sprites in the weapon colour for about 2 to 3 s (fx_weapons_gd.txt:613-626), then the same generic scorch as every other shell.

Against spec A: entry 10 wants battery to bake into a per-section scorch layer past a low count. The code never bakes; it places individual identical decals, and the per-section darkening that exists comes from the stage ladder, not from battery accumulation. Plasma misses entry 2 outright: no splash crater, no droplet fan, and the persistent trace has no plasma identity. INFERRED: whether the weapon colour used for the slag is the ruled light blue depends on faction data outside the attachments (see UNSURE). Cost to the player: battery fire, the most common damage in the game, leaves no readable accumulation of its own; a worked-over section reads only through the ladder.

### A2. Lance: PARTIAL

OBSERVED. The transient is the best beam treatment in the set: a gated white bloom at contact (fx_weapons_gd.txt:702), then a molten trench of 22 cooling sprites dragged across the plate (fx_weapons_gd.txt:705-711), sparks, droplets, smoke. The persistent trace, placed when the burn ends, is one generic scorch decal at 1.8 times scale (fx_weapons_gd.txt:729).

Against spec A entry 1: the lance mark should be a persistent lit slot, the only line-shaped mark, capped at 2 to 3 per section, lengthening on repeats, with a possible far-side exit point. None of that exists. The line shape lives only in the transient trench (sprite life 2.0 to 2.8 s); the scar is the same round scorch other families leave, so a lanced ship and a shelled ship carry the same history.

### A3. Ion: MISSES SPEC

OBSERVED. On a hull hit, ion runs the identical _beam_burn as lance and leaves the identical scorch decal (fx_weapons_gd.txt:601, 697-730). Its one ion-specific extra fires only when the target has a shield material: a blue static wash on the shield facing after the burn (fx_weapons_gd.txt:724-726). That is a shield effect, not a hull mark, and it is transient.

Against spec A: the branching tree is the most settled mark in the whole reference (agreement 8, entry 7): one growing Lichtenberg figure per section, re-energised by repeats, scarred as a faint fern etching. No branching figure exists anywhere in the impact, decal or ladder code. Ion is the faction-defining shield-strip weapon and its hull history is indistinguishable from lance's.

### A4. Torpedo: PARTIAL

OBSERVED. The transient is the heaviest in the game (fx_weapons_gd.txt:793-822): a gated pop at intensity 14, a raymarched fireball on max quality only (fx_death_gd.txt:226-250), a sympathetic second pop, shockwave ring, distortion, 40 spark streaks, 14 shards, the strongest shake and a hit pause. The persistent trace is the largest generic scorch decal, 2.6 times scale (fx_weapons_gd.txt:821).

Against spec A entry 4: one persistent blast crater per section, denting the outline with plates peeled outward, a second hit upgrading the crater. A torpedo hit cuts no crater. Crater-class geometry appears only when the struck section's hit points cross the stage 3 or 4 thresholds, and then at the section's pre-picked anchor, not at the torpedo's hit point (fx_ship_gd.txt:472, 562-587). Cost: the rarest, heaviest weapon leaves the least specific scar, and what scar appears can sit away from where the torpedo landed.

### A5. Flak: NOT IMPLEMENTED (persistent mark)

OBSERVED. Flak is transient only: four proximity airbursts per shot with budget-gated cores (fx_weapons_gd.txt:502-545, gate at 536) and a hanging smoke ball. A flak hit that reaches _impact is in the light set (fx_weapons_gd.txt:590) and the decal call excludes light looks (fx_weapons_gd.txt:635), so no flak mark of any kind persists.

Against spec A entry 5: a stippled pockmark patch per section that grows in area and density and never exposes structure. Absent entirely. The cost is the smallest of any miss here (the spec patch is a texture-level read and flak is a light weapon), but the item is simply not built.

### A6. Bio: PARTIAL

OBSERVED. Bio has one of only two family-specific persistent marks: a corrosion hole decal at the hit point with the bio flag set (fx_weapons_gd.txt:747-751), drawn by the DECAL shader with a green growth fringe tint (fx_shaders_gd.txt:788, 814, 818). The impact itself has no bright flash by design (fx_weapons_gd.txt:732-746), which also matches spec B's rule that bio carries no counted flashes.

Against spec A entry 6: the patch should spread briefly, visibly stop, then scar as pitted corrosion with stained streaks. The decal is created at full size with fixed parameters (open 0.28, heat 0.5) and never changes after creation, so there is no spread, no stop, and no scar transition. UNSURE whether the DECAL shader's animated ember noise (fx_shaders_gd.txt:792, 803) reads as spreading in motion; the code does not say.

### A7. Gauss: PARTIAL (closest to spec of any family)

OBSERVED. Gauss punches through: a gated impact pop, a ray through the hull to the far side, an exit burst with debris (fx_weapons_gd.txt:754-791), and two persistent hole decals, entry at the hit point (0.6 times scale, open 0.3, heat 1.0, fx_weapons_gd.txt:786) and exit on the far side (0.9, open 0.35, heat 1.0, fx_weapons_gd.txt:781), with parallax cavity on max quality (fx_death_gd.txt:154-173).

Against spec A entry 3: all four legs agreed the hole itself cannot read at fleet distance, so the distance read is a bright companion cue, a pale stress ring with radial cracks or a petaled collar. The code builds the zoom read and skips the companion cue entirely; the entry hole is also the smallest persistent mark in the game. Cost: at fleet distance a gauss-killed ship's history is invisible.

### A8. Squadron weapons: MEETS SPEC (thin spec)

OBSERVED. Squadron fire is transient only: _strafe flies craft past with tracers, bombs or spore sacs (fx_weapons_gd.txt:547-580), and a craft death is a single gated pop plus fire and smoke sprites (fx_death_gd.txt:631-642).

Against the specs: spec A has no squadron mark entry, and spec B's sheets ask for spark ticks and pinhole scorch at most (a5 synthesis line 82). The implementation sits inside that allowance. One related flag, scored under C rather than here: squadron ships as targets never show stage damage (fx_ship_gd.txt:481-482).

### A9. Ram: MISSES SPEC

OBSERVED. Ram is instant (impact time equals fire time, fx_weapons_gd.txt:247-249), routes into _big_hit at 1.5 times scale (fx_weapons_gd.txt:606), and its persistent trace is the same 2.6-scale scorch decal a torpedo leaves (fx_weapons_gd.txt:821). No crumple geometry, no scrape streaks along the impact direction, and no mark of any kind on the ramming ship.

Against spec A entry 8: the crumple is one of only two marks allowed to change the silhouette, must read with no glow and no particles, and the rammer takes a matching smaller crumple. The only outline change in the implementation is the stage ladder's stage-4 edge bite (fx_ship_gd.txt:580-585), which sits at a pre-picked anchor, is triggered by any damage source, and has nothing to do with the ram point. Ram currently has neither silhouette nor identity.

### A10. Boarding: NOT IMPLEMENTED (as its own mark)

OBSERVED. The tendril look routes to _bio_splat (fx_weapons_gd.txt:601); the lash flag's only effect is a slightly stronger shake (fx_weapons_gd.txt:745). The persistent trace is the same corrosion hole decal bio leaves (fx_weapons_gd.txt:750), placed at a surface sample in the struck section (fx_weapons_gd.txt:128-152), not at any socket.

Against spec A entry 9: a torn gash at a plausible boarding point (airlock, docking collar), venting and interior light while the action is live, scarred as a dark gash partly covered by a mismatched patch plate. None of these exist in godot/fx. UNSURE whether the rules or UI layer draws any of it; it is not in the fx attachments.

### A11. Cross-cutting mark behaviour: MISSES SPEC (one sub-item meets)

Persistence: PARTIAL. OBSERVED: hit decals persist for the battle, but they carry almost no identity. Every family except gauss and bio leaves the same generic scorch (one of 3 random textures, fx_death_gd.txt:131-151); gauss and bio share one decal shader separated by a tint flag (fx_shaders_gd.txt:788).

Fresh, cooling, scarred evolution: MISSES SPEC for hit decals, MEETS SPEC for stage geometry. OBSERVED: scorch decals are created with a fixed emission energy (0.7, or 1.6 if cracked, fx_death_gd.txt:141) and never change. Hole decals take heat as a constant uniform set at creation (fx_death_gd.txt:167); the DECAL fragment uses heat only as a multiplier and has no age or birth-time term (fx_shaders_gd.txt:765-833), even though the shader's own header comment says heat cools a hole down over time toward 0.15 (fx_shaders_gd.txt:737). Nothing in godot/fx updates a hit hole decal's heat after creation (grep: heat is set at fx_death_gd.txt:167, at fx_breach_gd.txt:754 for breach interiors, and at fx_death_gd.txt:864 for wreck faces only). Breach interiors do cool properly: the HOLE shader computes age from a t0 uniform and decays hot as exp(-age / 10) toward 0.45 times heat (fx_shaders_gd.txt:874-876), t0 is recorded when a stage is applied (fx_ship_gd.txt:554-559), and wreck cut faces cool the same way (fx_death_gd.txt:856-864). So the fresh-to-scarred arc exists, but only in the ladder layer the specs treat as the section state, not in the per-hit marks spec A describes. All cooling runs on fx-clock seconds; no timer is turn-keyed, against spec A's turn-based flag that fresh should mean this turn.

Caps and repeat handling: MISSES SPEC. OBSERVED: the decal cap is 10 per ship, oldest first, and it is enforced only inside add_hit_scorch (fx_ship_gd.txt:816-826). The gauss and bio paths append hole decals to the same array with no trim (fx_weapons_gd.txt:750, 781, 786), so the array can pass 10 between scorch calls, and a later scorch call can evict a gauss or bio hole as the oldest entry. There is no per-section cap and no growth or merging: a repeat hit places a new decal at its own hit point. Spec A budgets 3 signature marks per section with repeats growing the existing mark.

Repair reversal: PARTIAL. OBSERVED: stage geometry reverses, because sync() recomputes stages from current hit points and the hull is rebuilt from the original mesh arrays with only the current stage entries (fx_ship_gd.txt:457-487, 589-627), and a stage drop rebuilds without the stage-up burst (fx_ship_gd.txt:507-520). Hit decals are not removed by repair; they persist until evicted, so a repaired section can still wear its scorch and holes. Spec A readability rule 7 says hull language and game state must not disagree.

Shield-only-hit rule: MEETS SPEC. OBSERVED: a hit counts as a shield hit only when the rules report shield damage above 0 and hull damage at or below 0 (fx_weapons_gd.txt:140); _impact routes shield hits to _shield_impact and returns before any decal code (fx_weapons_gd.txt:592-594). Pure shield hits leave no hull mark, matching spec A's chair recommendation. Through hits light the bubble on the way in, then run the hull impact (fx_weapons_gd.txt:143-145, 595-597).

## B. The counted-flash rule

External standard, cited from the code's own claim and the API doc: WCAG 2.3.1 (Three Flashes or Below Threshold) and 2.3.2 (Three Flashes) both cap content at three flashes in any one-second period; 2.3.2, the one the fx header and API doc cite (fx_gd.txt:4; fx_api_md.txt:128), allows no threshold exception. WCAG counts flashes on screen, not calls into a budget function, which is what makes B4 the load-bearing item.

### B1. The counted-flash definition: MISSES SPEC

OBSERVED. flash_ok keeps only a list of times (fx_gd.txt:71); it measures no brightness, size or contrast. Any pop() call counts as one flash whatever its intensity, and a flash merged by the window draws at full brightness and counts as zero (fx_gd.txt:315-334). Spec B counts per-emitter dark-bright-dark transition pairs above a moderate contrast step and exempts small dim sparks below the step. Cost, both ways: dim sparks the spec exempts can spend the budget early in a salvo, and per-emitter identity is not tracked at all, so the same emitter strobing repeatedly is invisible to the counter as long as each call is spaced out.

### B2. The cap and the counting window: PARTIAL

OBSERVED. The cap is 3 (fx_gd.txt:29) and the count spans 1.0 s (fx_gd.txt:322), but the span is two-sided: a recorded flash counts against T if it sits within 1.0 s on either side of T (fx_gd.txt:319-323). Spec B and the API doc both describe a rolling one-second counter, which is trailing. Because volleys schedule future impact times, an early flash can be refused by flashes that have not happened yet, and whether a given flash passes can depend on the order effects were queried. For effects queried in time order the behaviour approximates the spec, which is why this is PARTIAL rather than a miss.

### B3. The merge window: MISSES SPEC (and the code disagrees with itself)

OBSERVED. Three positions sit within a page of each other: the constant is 0.12 s (fx_gd.txt:28), the comment directly above flash_ok says flashes inside 0.33 s of a counted one merge into it (fx_gd.txt:314), and the API doc says 0.12 s (fx_api_md.txt:128). Spec B says 0.33 s. The practical difference lands exactly on the salvo case the merge exists for: shells landing 0.12 to 0.33 s apart consume separate budget slots under the code, where spec B would merge them into one counted event, leaving budget for the genuinely big flash at the end of the salvo. One number needs picking; the comment suggests 0.33 was the intent and the constant drifted.

### B4. Coverage: MISSES SPEC (the central flash finding)

OBSERVED, gated set: pop() and its callers (fx_gd.txt:338-344), the gauss muzzle sprite (fx_weapons_gd.txt:293), the beam burn's initial white bloom (fx_weapons_gd.txt:702), flak airburst cores (fx_weapons_gd.txt:536), and the death sequence's first blast sprite (fx_death_gd.txt:679-682).

OBSERVED, ungated set, all bright: the battery muzzle blast's core is a direct sprite at intensity 11 that checks only reduce_flashing (fx_weapons_gd.txt:317-327); the beam burn's sustained contact sprite runs at intensity 9.0 for the whole burn and is a separate sprite from the gated bloom (fx_weapons_gd.txt:701); beam ribbons and charge flares are drawn directly (fx_weapons_gd.txt:236-256); event lights are a separate pooled system the budget never sees, with peaks up to 14.0 on a big hit (fx_gd.txt:349-353; fx_weapons_gd.txt:818); shield ripple hits are shader-side, with a code comment stating the beam shield rings are not counted flashes (fx_weapons_gd.txt:665); the torpedo fireball volume is not gated (fx_death_gd.txt:226-250); and in the death break-up only the first blast sprite is gated, while the sprite behind it at 8.0 times the size factor and the rolling train of 10 plus 3 per weight flame sprites are not (fx_death_gd.txt:684-690).

Cost: the flash_log the tests check (fx_gd.txt:72) certifies only the gated subset. A death plus a torpedo plus a beam burn in the same second can put far more than three bright events on screen while the log shows the cap held. Against WCAG 2.3.2, which counts what is on screen, the budget as built cannot support the API doc's claim.

### B5. Over-budget behaviour: PARTIAL

OBSERVED. When pop() is refused, the player gets a longer, dimmer sprite (intensity min(i, 3) times 0.4, life at least 0.4 s) plus an expanding ring (fx_gd.txt:341-344). Flak over budget skips only the core sprite and keeps shrapnel and the hanging smoke ball (fx_weapons_gd.txt:535-545), which matches spec B's flak wording (smoke and sparks without the bright core pop) almost word for word. The death blast fallback is a dimmer, longer sprite (fx_death_gd.txt:679-682). The gap: spec B's over-budget language removes the bright core; the pop() fallback keeps a visible glow lift, which reads closer to spec B's reduce-mode replacement than to its over-budget rendering. Minor, but the two modes blur.

### B6. Reduce-flashing mode: PARTIAL

OBSERVED. For the gated set the mode is complete: flash_ok always returns false (fx_gd.txt:316-317), the setter raises the global fx_calm shader parameter (fx_gd.txt:33-36), decay-shape event lights are softened (peak times 0.45, life times 1.8, fx_gd.txt:349-353), persistent light-source flicker slows to a sin(now * 2.0) term at 0.3 amplitude (fx_gd.txt:391-393), effect shake halves (fx_gd.txt:453), and the muzzle blast swaps its bright core for a dimmer, longer sprite (fx_weapons_gd.txt:318-322). That reaches spec B's 0 counted flashes for everything the budget defines as counted, using the named replacement techniques.

The partial: ungated emitters are calmed, not removed, and one is not calmed at all. INFERRED from the code read: _beam_burn's sustained contact sprite (fx_weapons_gd.txt:701) has no reduce check on its own path; only its small initial bloom is gated. A photosensitive player in reduce mode still gets a full-intensity white beam contact for the burn's duration. Event lights are softened only for the decay shape; sustain and ramp lights pass at full peak.

## C. The two-tier read

### Distance tier: PARTIAL

OBSERVED. How hurt and which section is worst read well, through the ladder rather than the marks: stage scorch decals grow and brighten with stage (size hull length times 0.05 plus 0.065 per stage; emission 0.15 at stages 1-2, 0.3 at stages 3-4, fx_ship_gd.txt:667-670), smoke wisps at stages 1-2, spark and gas emitters from stage 2, debris shedding from stage 3, breach fire and interior light at stage 4 (fx_ship_gd.txt:643-730), engine sputter when the engine section reaches stage 3 (fx_ship_gd.txt:515-519), and a gated burst at the anchor the moment a stage rises, which is the freshness signal (fx_ship_gd.txt:717-727). Roughly what has been hitting the ship does not read at all: per section A, persistent marks carry almost no weapon identity once the transient ends.

Two structural notes. First, sections: the implementation has 3 hull sections, lengthwise thirds (fx_hull_gd.txt:8-10, 92-94), against spec A's assumed 4 to 8 (spec A open question 2). The budget maths survives (3 sections at 3 marks is 9 per ship, inside the legs' 8 to 10 per ship), but granularity does not: one stage step is a third of the ship, so the distance read has five states per third and nothing finer. Second, the glow ration in spec A readability rule 3 (at most 2 glowing marks and 1 particle emitter per ship at fleet distance) has no counterpart: persistent emitters per section grow with stage, and event lights are pooled globally by brightness, not rationed per ship (fx_gd.txt:362-410). On a 20-ship board the fog-bank failure spec A warns about is unmitigated in code. Squadron ships are a blind spot of their own: sync() forces their stages to 0,0,0 (fx_ship_gd.txt:481-482), so a half-dead squadron ship reads pristine at any distance.

### Zoom tier: MEETS SPEC

OBSERVED. The close read is the strongest part of the implementation: hole decals with a parallax cavity, ribs and conduits on max quality (fx_shaders_gd.txt:746-800), real cut geometry with plates bent back and built, lit interiors for stage 3 and 4 holes (fx_ship_gd.txt:562-587; fx_breach_gd.txt:735-820), and crack emission textures on stage decals (fx_death_gd.txt:131-151). This tier meets spec A's detail layer and in places exceeds it.

## Ranked fixes

1. Gate or calm the ungated bright emitters: beam contact sprite, battery muzzle core, event lights, death flame train (fx_weapons_gd.txt:701, 317-327; fx_gd.txt light pool; fx_death_gd.txt:684-690). Repairs B4 and B6.
2. Make the counting window trailing: count only recorded flashes in the 1.0 s before T (fx_gd.txt:319-323). Repairs B2.
3. Settle the merge window on one value, 0.33 s per spec B and the code's own comment, in the constant and the API doc (fx_gd.txt:28, 314). Repairs B3.
4. Add a contrast step to the budget: exempt small dim pops below a set intensity and size from counting (fx_gd.txt:315-344). Repairs B1.
5. Give ion a branching tree decal and lance a slot decal in the hit-mark layer (fx_weapons_gd.txt beam burn end; fx_ship_gd.txt decal paths). Repairs A3 and A2.
6. Torpedo and ram: cut dent and crater geometry at the actual hit point, and put a smaller crumple on the ramming ship (fx_weapons_gd.txt:793-822; fx_ship_gd.txt anchors). Repairs A4 and A9.
7. Add gauss's companion cue: a pale stress ring or petaled collar decal at the entry point (fx_weapons_gd.txt:786). Repairs A7.
8. Per-section mark budget with repeat growth: cap signature marks at 3 per section, grow on repeats, and trim hole decals in the same bookkeeping as scorch (fx_ship_gd.txt:816-826; fx_weapons_gd.txt:750, 781, 786). Repairs A11 and part of A5.
9. Hole decal cooling: record a birth time at creation and decay heat in the DECAL shader, as its header already claims (fx_shaders_gd.txt DECAL; fx_death_gd.txt:154-173). Repairs A11 and A6.
10. Flak pockmark patch decal, and a boarding gash at a socket with a patch-plate scar stage (fx_weapons_gd.txt impact paths). Repairs A5 and A10.
11. Repair removes the repaired section's hit decals (fx_ship_gd.txt sync and _apply_stages). Repairs A11.
12. Let squadron ships show at least the scorch stages of the ladder (fx_ship_gd.txt:481-482). Repairs the C distance tier blind spot.

## UNSURE list

- Whether anything outside godot/fx (rules or UI) calls set_stages (fx_ship_gd.txt:503-504) to drive stages directly, bypassing the sync() thresholds.
- Whether any code outside godot/fx updates a hole decal's heat uniform after creation; the grep for this audit covered godot/fx only.
- The screen-space size of hit decals and stage visuals at the game's default tactical camera distance; the camera lives outside godot/fx, so the distance-tier verdicts are about the mark system, not measured pixels.
- Whether the flash budget tests referenced by the flash_log comment (fx_gd.txt:72) exist under godot/fx/test; the directory exists on main but was not in the attachments.
- Whether boarding has any visual representation in the rules or UI layer (socket placement, venting while live, patch plates); not present in godot/fx.
- Whether the DECAL shader's animated ember noise (fx_shaders_gd.txt:792, 803) is intended to read as bio corrosion spreading; the code does not say.
- Whether plasma's weapon colour in the game's data is the light blue Ryan ruled on Oct 26; the fx layer takes the colour from faction data (fx_weapons_gd.txt:622-626), which is not in the attachments.
- Whether the compatibility renderer path (hit decals draw nothing, fx_death_gd.txt:132-135, 155-158) is a shipping target or a fallback; if it ships, every persistent-mark verdict above weakens on that path.

## Overall verdict

PARTIAL, leaning MISS on the specs as written. The implementation is a strong transient-effects and staged-damage system whose zoom tier exceeds spec A, but the two things the specs actually specify are mostly not built: per-weapon persistent marks (only gauss and bio have their own, and both lack their spec behaviour) and a flash budget that covers what is on screen (the budget certifies a gated subset while the brightest emitters bypass it). The cheapest large wins are in the flash hub, where three of the top four fixes are small, well-bounded changes to fx_gd.txt.
