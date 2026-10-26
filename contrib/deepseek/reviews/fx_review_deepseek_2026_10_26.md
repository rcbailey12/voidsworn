# Effects implementation audit, DeepSeek leg (raw), 2026-10-26

Filed verbatim from the DeepSeek chat leg run 2026-10-26 (DeepThink and Search verified ON by the toggle test; pack plus fx_gd.txt, fx_weapons_gd.txt, fx_ship_gd.txt attached). Method notes are in the chair screening note, not in this file.

---

Effects implementation audit, brief 26c Job 3

I read the evidence pack and the attached code files. I also checked the WCAG flash criteria: WCAG 2.3.1 permits no more than three flashes in any one second, or flashes below the general flash and red flash thresholds; WCAG 2.3.2 permits no more than three flashes in any one second regardless of brightness or area. The general flash threshold is a pair of opposing relative-luminance changes of 10 percent or more, with the combined flashing area no more than 0.006 steradians inside a 10 degree visual field. I did not find a named, published post-processing or readability standard that I could rely on beyond general practice, so the distance and zoom judgements below use the specs' own readability rules.

A. Per-weapon marks

A1. Battery, including plasma

Verdict: PARTIAL.

Battery hits that are not “light” looks and not light weight leave a generic scorch decal at the hit point, sized 0.9 times target scale at weight 2 or under and 1.4 at weight 3 (fx_weapons_gd.txt lines 605-637, especially line 635). Light battery looks (auto, las, scatter) leave no decal. Plasma also leaves dripping slag sprites for about 2 to 3 seconds (fx_weapons_gd.txt lines 622-626). The decals are individual projected scorches, not the spec's per-section scorch layer that builds past a low count and becomes the weakest readable battery signature (damage_marks_reference.md line 15). The per-section darkening that exists comes from the stage ladder, not from battery accumulation (fx_ship_gd.txt lines 643-730). Player cost: a ship under sustained battery fire does not build a section-level battery mark; it accumulates separate scorches that can be evicted, so the battery's cumulative pressure is harder to read at fleet distance.

A2. Lance

Verdict: MISSES SPEC.

The lance impact draws a white contact sprite for the burn, then a transient molten trench of 22 cooling-metal sprites dragged across the plate, plus sparks and smoke (fx_weapons_gd.txt lines 697-730). The persistent trace is one generic scorch decal at the hit point, size 1.8 times scale, placed when the burn ends (fx_weapons_gd.txt line 729). There is no persistent lit slot, no slot lengthening on repeats, and no possible far-side exit mark (damage_marks_reference.md line 26). Player cost: lance hits are readable only while the burn plays; after that a lance hit is indistinguishable from a generic scorch, and repeated lance fire does not build the specified lengthening slot.

A3. Ion

Verdict: MISSES SPEC.

Ion uses the beam path with a distinct ribbon and crawling arcs at the emitter (fx_weapons_gd.txt lines 14, 236-256). On a hull hit it draws the same _beam_burn as lance and leaves the same generic scorch decal; it adds only a blue static wash on the shield facing if the target has a shield material (fx_weapons_gd.txt lines 724-726). There is no branching tree geometry, no re-energising or extension on repeats, and no scarred fern etching (damage_marks_reference.md lines 18, 32). Player cost: ion leaves no persistent visual identity. A player cannot tell from marks that a section has been hit by ion rather than lance.

A4. Torpedo

Verdict: MISSES SPEC.

Torpedo impact produces a gated pop, a fireball, a sympathetic pop, shockwave, sparks, debris and embers, and leaves the largest generic scorch decal at 2.6 times scale (fx_weapons_gd.txt lines 793-822, especially line 821). No crater geometry is cut at the torpedo's hit point. Crater-class geometry appears only when the struck section's hit-point fraction crosses the stage 3 or 4 thresholds, and then at the section's pre-picked anchor, not at the torpedo hit point (fx_ship_gd.txt lines 472, 562-587). The spec wants one persistent blast crater per section, denting the outline with plates peeled outward, with a second hit upgrading the crater's stage (damage_marks_reference.md line 29). Player cost: a torpedo hit that does not cross a stage threshold leaves no crater and no outline change, so the heaviest single hit in the game can look like a large scorch rather than a structural breach.

A5. Flak

Verdict: MISSES SPEC.

Flak is transient only: four proximity shells burst around the target, the core pop is gated by flash_ok, and a smoke ball hangs for about 2.6 seconds (fx_weapons_gd.txt lines 502-545, especially line 536). A flak hit that reaches _impact is in the “light” set and leaves no decal (fx_weapons_gd.txt lines 590, 635). There is no persistent stippled pockmark patch, no growth in area or density, and no rule that it never exposes structure (damage_marks_reference.md line 30). Player cost: flak has no cumulative visible effect on the hull; a section can be repeatedly flakked and show no persistent evidence of it.

A6. Bio

Verdict: PARTIAL.

Bio is one of only two families with a persistent mark that differs from the generic scorch. _bio_splat creates a corrosion hole decal with the bio flag, size 0.9 times scale, open 0.28, heat 0.5, drawn by the DECAL shader with a green growth fringe (fx_weapons_gd.txt lines 732-752, especially lines 747-751; fx_shaders_gd.txt lines 788, 814, 818). The decal is created at full size with fixed parameters. There is no growth phase, no visible stop, and no scar evolution after the initial decal. The spec wants an irregular eaten patch that keeps spreading briefly, visibly stops, and scars as pitted corrosion with stained streaks (damage_marks_reference.md line 31). Player cost: bio reads as a one-time green hole rather than a process that spreads and then scars, so the player loses the “it is still eating” to “it has stopped” distinction.

A7. Gauss

Verdict: PARTIAL.

Gauss has the strongest zoom read among the weapon marks: entry and exit hole decals with parallax cavity on max quality (fx_weapons_gd.txt lines 754-791, especially lines 781-786; fx_death_gd.txt lines 154-173). It also has a transient exit spray. It lacks the persistent bright companion cue that the spec requires for fleet distance, namely a pale stress ring with radial cracks or a petaled collar (damage_marks_reference.md line 28). The entry hole at 0.6 times scale is smaller than the exit hole at 0.9. Player cost: at fleet distance a gauss hit is nearly invisible once the exit spray fades, because the clean hole is explicitly the zoom read, not the distance read.

A8. Squadron weapons

Verdict: MEETS SPEC.

The marks reference has no separate squadron mark entry, and the Job A sheets give craft hull impacts spark ticks and pinhole scorch at most (a5_effects_sheets_synthesis.md line 82). The implementation gives squadron craft transient strafing effects only, with no persistent mark, and squadron ships themselves never show stage damage because sync() forces their stages to 0,0,0 (fx_weapons_gd.txt lines 547-580; fx_ship_gd.txt lines 481-482). There is no unmet requirement here. Player cost: none relative to the filed spec, though squadron damage is intentionally invisible beyond transient hits.

A9. Ram

Verdict: MISSES SPEC.

Ram is instant in _shot (fx_weapons_gd.txt lines 247-249). Its impact is _big_hit at 1.5 times scale, and its persistent trace is the same 2.6-scale scorch decal as a torpedo (fx_weapons_gd.txt lines 606, 821). There is no ram-specific crumple geometry, no folded plating, no scrape streaks along the impact direction, and no matching smaller crumple on the ramming ship (damage_marks_reference.md line 33). Outline change comes only from the stage ladder's stage-4 edge bite at a pre-picked anchor, which any damage source can trigger (fx_ship_gd.txt lines 580-585). Player cost: ramming, which the spec reserves as one of only two silhouette-changing events, leaves no distinctive silhouette change at the actual impact point and no mark on the attacker.

A10. Boarding

Verdict: MISSES SPEC.

Boarding routes to _bio_splat with the lash flag, whose only difference is a slightly stronger shake (fx_weapons_gd.txt lines 732, 745). The persistent trace is the same corrosion hole decal as bio (fx_weapons_gd.txt lines 747-751). The hit point is a surface sample in the struck section facing the attacker, not a boarding socket (fx_weapons_gd.txt lines 128-152). There is no venting-while-live state, no interior light while the action is live, and no patch-plate scar stage (damage_marks_reference.md line 34). Player cost: boarding leaves a bio-style corrosion hole, so the player cannot distinguish a boarding action from a bioplasma hit, and the live boarding state has no fx-layer visual.

A11. Cross-cutting mark behaviour

Verdict: PARTIAL.

Persistence exists: hit decals persist until evicted or the battle ends (fx_ship_gd.txt lines 816-826). Shield-only hits leave no hull mark, because _target routes pure shield hits to _shield_impact and returns before any decal code (fx_weapons_gd.txt lines 592-594). That part meets the spec's recommendation. The problems are the following.

Fresh, cooling, scarred evolution is largely missing for hit decals. Scorch decals are created with a fixed emission energy and never change (fx_death_gd.txt line 141). Hole decals take heat as a constant uniform at creation, and the DECAL shader fragment uses heat only as a multiplier with no age or birth-time term (fx_shaders_gd.txt lines 743, 765-833; fx_death_gd.txt line 167). The comment says heat cools over time, but the code does not do it (fx_shaders_gd.txt line 737). Only breach interiors cool, through the HOLE shader's exponential decay (fx_shaders_gd.txt lines 874-876). So the spec's fresh-glow, cooling-settle, scarred-dark sequence is not implemented for the actual hit marks (damage_marks_reference.md line 14).

Caps and repeat handling miss the spec. _hit_decals is trimmed to 10 per ship only inside add_hit_scorch (fx_ship_gd.txt lines 816-826). Gauss and bio append hole decals to the same array without trimming, so the array can pass 10 between scorch calls, and a later scorch call can evict a gauss or bio hole decal as the oldest entry (fx_weapons_gd.txt lines 751, 781, 786). There is no per-section cap and no repeat growth or merging. The spec asks for 3 signature marks per section, with repeats growing the existing mark (damage_marks_reference.md line 13).

Repair reversal is split. Geometry follows repairs because sync() recomputes stages from hit points and _apply_stages rebuilds the section without the stage-up burst, and the hull mesh is recomputed from original arrays with only current stage entries (fx_ship_gd.txt lines 507-520, 589-627). Hit decals are not removed by repair. The spec wants repairs to visibly reverse marks and crumple to remain only where not truly restored (damage_marks_reference.md line 45).

Player cost: the player gets persistence and the shield-only rule, but not the freshness and scar language that makes marks readable over time, not the per-section budget that keeps marks legible, and not the repair behaviour that keeps marks honest.

B. The counted-flash rule

B1. The counted-flash definition

Verdict: PARTIAL.

Spec B defines a counted flash as one brightness transition pair, dark to bright to dark, on a given emitter above a moderate contrast step, with small dim sparks below the step exempt (a5_effects_sheets_synthesis.md line 118). The implementation has no brightness or contrast-step measurement. Any pop() call is one counted flash whatever its size or intensity, and a merged flash draws at full brightness without counting (fx_gd.txt lines 338-344). A flash_ok() call records a time and returns true, regardless of the emitter's actual luminance change (fx_gd.txt lines 315-334). Player cost: the budget can be consumed by a visually small pop while a genuinely bright ungated emitter never counts, so the cap does not track the perceptual flash load the spec is trying to control.

B2. The cap and the counting window

Verdict: PARTIAL.

The cap is implemented: FLASH_CAP is 3 (fx_gd.txt lines 28-29). The counting window is not a rolling one-second counter. It counts recorded flashes within 1.0 second on either side of the query time T (fx_gd.txt lines 319-323). For effects queried in time order the two agree. But volleys schedule future impact times, so a flash can be counted against one up to 1.0 second in its future. Player cost: in a multi-shell volley, a later scheduled flash can suppress an earlier one, or a present flash can be counted against a future flash, which can make the budget over-suppress or under-suppress within the salvo.

B3. The merge window

Verdict: MISSES SPEC.

The code constant is FLASH_WINDOW := 0.12 (fx_gd.txt line 28). The API doc also says 0.12 seconds (fx_api_md.txt line 128). Spec B says 0.33 seconds (a5_effects_sheets_synthesis.md line 118). The comment directly above flash_ok says “Flashes inside 0.33 s of a counted one merge into it (free)” (fx_gd.txt line 314), so the code's own comment contradicts its constant. This is an internal disagreement, and the spec's 0.33 second figure should govern. Player cost: salvos that land between 0.12 and 0.33 seconds apart are treated as separate counted flashes, which can hit the cap earlier than the spec intends and push later impacts into the over-budget fallback. The player sees more dim, ringed impacts and fewer full flashes than a 0.33 second merge would produce.

B4. Coverage

Verdict: MISSES SPEC.

Several bright emitters never call flash_ok.

- The battery muzzle blast's bright core is a direct sprite at intensity 11 that checks only reduce_flashing (fx_weapons_gd.txt lines 317-327).
- Beam ribbons, charge flares and beam sprites are drawn directly (fx_weapons_gd.txt lines 236-256).
- Event lights are a separate pooled system with peaks up to 14.0 and the budget does not see them (fx_gd.txt lines 349-410; fx_weapons_gd.txt line 818).
- Shield ripple hits are shader-side and not counted (fx_ship_gd.txt lines 383-392).
- The torpedo fireball volume is not gated (fx_death_gd.txt lines 226-250).
- In the death break-up, only the first blast sprite is gated; the rolling flame sprite train after it is not (fx_death_gd.txt lines 684-690).

Player cost: the cap can be satisfied by the gated set while ungated emitters exceed three flashes in a second. The safety property WCAG 2.3.2 describes is not actually enforced globally.

B5. Over-budget behaviour

Verdict: PARTIAL.

For pop() users, the fallback is a dimmer, longer glow sprite plus a ring (fx_gd.txt lines 341-344). For flak, over-budget bursts skip only the core sprite and keep shrapnel and the hanging smoke ball, which matches the spec's “smoke and sparks without the bright core pop” for flak (fx_weapons_gd.txt lines 535-545; a5_effects_sheets_synthesis.md line 118). The generic pop() fallback still keeps a visible glow lift, which is closer to the reduce-mode replacement language than the over-budget language. Player cost: the flak path is correct, but other over-budget impacts still produce a soft bright lift rather than dropping to smoke and sparks only, so the over-budget state is inconsistent across weapons.

B6. Reduce-flashing mode

Verdict: PARTIAL.

flash_ok() always returns false in reduce mode (fx_gd.txt lines 315-334). The implementation sets fx_calm to 1, slows shader flicker to breathing, dims and lengthens the muzzle blast, softens event-light decay, slows persistent light flicker, and halves effect shake (fx_gd.txt lines 33-36, 349-353, 391-393, 453; fx_weapons_gd.txt lines 318-322; fx_shaders_gd.txt lines 38-40). For the gated set this reaches 0 counted flashes. But the ungated emitters, including beams, ribbons, event lights and the death flame train, are calmed rather than removed or replaced with the named techniques. The spec's reduce target is 0 counted flashes achieved with named replacement techniques such as rings, particle bursts, gentle lift under 20 percent, smoke-forward muzzles and lengthened soft blooms (a5_effects_sheets_synthesis.md line 118). Player cost: reduce mode is safer for the gated set, but a photosensitive player still sees bright beams and event lights that are outside the counted system and outside the full replacement vocabulary.

C. The two-tier read

Distance tier

Verdict: PARTIAL.

The stage ladder answers “how hurt” and “which section is worst.” It has three sections, engine, mid and prow, defined as lengthwise thirds (fx_hull_gd.txt lines 8-10, 92-94). Each section's stage drives scorch size, smoke, sparks, gas, debris and breach fire, and a stage increase fires a freshness burst at the section anchor (fx_ship_gd.txt lines 643-730, 717-727). The whole-ship under-35-percent rule also lifts every section to at least stage 2, which helps the fleet-distance read of a dying ship (fx_ship_gd.txt lines 470-487).

It does not answer “roughly what has been hitting it.” Every family except gauss and bio leaves the same generic scorch decal, and gauss and bio share one decal shader distinguished only by a tint flag (fx_shaders_gd.txt line 788). Weapon identity is readable only while the transient impact plays. The reference's one-second test explicitly asks for how hurt, which section is worst, and roughly what has been hitting the ship (damage_marks_reference.md line 39). The implementation answers the first two but not the third at fleet distance.

The implementation's 3 hull sections are below spec A's assumed 4 to 8 sections (damage_marks_reference.md open question 2, line 62 area). Player cost: with only three sections, “which section is worst” has coarser spatial resolution. A hit on a large third of the hull is less localised, and the player has fewer read points for section-specific damage.

Zoom tier

Verdict: PARTIAL.

The zoom tier has real detail. Hole decals use a parallax cavity with ribs and conduits on max quality (fx_shaders_gd.txt lines 746-800). Stage 3 and 4 holes use real mesh cutting with peeled petal plates and built interiors (fx_breach_gd.txt lines 2-13, 735-820). Stage decals use crack emission textures (fx_death_gd.txt lines 131-151). That is a credible zoom layer for generic structural damage.

It is incomplete against the per-weapon zoom marks. Lance has no slot, ion has no branching tree, torpedo has no blast crater at the hit point, flak has no pockmark patch, ram has no crumple, and boarding has no gash or patch plate. The zoom layer shows generic damage well but does not show the specific marks the spec asks the player to read when they zoom in. Player cost: zooming in confirms that a section is damaged, but does not confirm what damaged it or show the weapon-specific scar the spec designed.

Ranked fixes, most valuable first

1. Replace the per-ship hit-decal cap with a per-section signature-mark budget of 3, and make repeats grow the existing mark rather than placing a new decal. Area: fx_ship.gd add_hit_scorch and a new per-section mark registry. Repairs A11 and the cap and repeat failures that affect every A verdict.

2. Implement the missing weapon-specific persistent marks at the actual hit point: lance slot, ion branching tree, torpedo crater, flak pockmark patch, ram crumple and boarding gash. Area: fx_weapons.gd _beam_burn, _big_hit, _flak, _bio_splat and the ram path. Repairs A2, A3, A4, A5, A9 and A10.

3. Set the merge window to 0.33 seconds and make the comment and constant agree. Area: fx_gd.gd FLASH_WINDOW and the comment above flash_ok. Repairs B3.

4. Route the ungated bright emitters through flash_ok or an equivalent gate: battery muzzle core, beam ribbons and charge flares, event lights, torpedo fireball volume and the death flame train. Area: fx_weapons.gd _muzzle_blast and beam paths; fx_gd.gd event-light emission; fx_death.gd death break-up. Repairs B4 and makes B6 meaningful for the ungated set.

5. Add a contrast-step test to the counted-flash definition and exempt small dim sparks. Area: fx_gd.gd flash_ok and pop. Repairs B1.

6. Make hit decals cool and scar over time, or explicitly switch to the scarred visual state after a set age, and remove or reverse hit decals on repair. Area: fx_death.gd decal creation and fx_ship.gd repair handling. Repairs the fresh, cooling, scarred and repair parts of A11.

7. Add the gauss distance cue: a persistent pale stress ring or petaled collar around the entry hole. Area: fx_weapons.gd _gauss_punch. Repairs A7.

8. Align the generic over-budget pop() fallback with the spec's smoke-and-sparks language, or document why a soft lift is used for non-flak impacts. Area: fx_gd.gd pop. Repairs B5.

UNSURE list

- Whether any code outside godot/fx calls set_stages and bypasses the sync() thresholds (fx_ship_gd.txt lines 503-504).
- Whether any code outside godot/fx updates a hole decal's heat uniform after creation. The evidence pack's grep covered only godot/fx.
- The screen-space size of hit decals and stage visuals at the game's default tactical camera distance. The camera lives outside godot/fx, so the distance-tier judgement is about the mark system, not measured pixels.
- Whether the flash-budget tests referenced by the flash_log comment exist under godot/fx/test. The directory exists on main but was not fetched for this pack (fx_gd.txt line 72).
- Whether boarding has any visual representation in the rules or UI layer, such as socket placement, venting while live, or patch plates. It is not present in godot/fx.
- Whether the DECAL shader's animated ember noise is intended to read as bio corrosion spreading. The code does not say (fx_shaders_gd.txt lines 792, 803).
- Whether the 0.12 second merge constant is a deliberate late change or a stale value that failed to track the 0.33 second comment and spec.

Overall verdict

PARTIAL. The implementation has a strong transient impact layer, a working three-section staged damage ladder, a correct shield-only-hit rule, and a reduce mode that zeroes the gated flash set. It falls short of both specs in the places that matter most for the filed requirements: persistent per-weapon marks and the per-section mark budget are largely absent, the counted-flash definition and merge window do not match spec B, and several bright emitters sit outside the budget. The player gets a readable “how hurt” and “which section” at fleet distance, but not a reliable “what has been hitting it” or a globally enforced flash cap.
