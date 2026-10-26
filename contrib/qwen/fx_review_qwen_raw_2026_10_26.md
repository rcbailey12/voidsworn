# Effects implementation audit, Qwen leg (raw), 2026-10-26

Filed verbatim from the Qwen leg run 2026-10-26 (Qwen3.8-Max, both gates passed; pack pasted in four parts, submitted once). Method notes are in the chair screening note, not in this file.

---

# Effects Implementation Audit

Blind review. Factual base is the evidence pack and the nine attachment files listed. Every code claim below carries a file:line reference drawn from those attachments. Where the attachments do not settle a question, the item is marked UNSURE.

## A. Per-weapon marks

### A1. Battery (including plasma)

Verdict: PARTIAL

The spec (damage_marks_reference.md line 15) asks battery marks to be the weakest tier and to bake into a per-section scorch layer once a low count is passed. The implementation places individual generic scorch decals at each hit point (fx_weapons_gd.txt line 635), drawn from one of three random scorch textures (fx_death_gd.txt lines 131-151). There is no accumulation into a section-wide layer; each hit is its own decal until the per-ship cap of 10 evicts the oldest (fx_ship_gd.txt lines 816-826). Light battery looks (auto, las, scatter) leave no decal at all (fx_weapons_gd.txt line 635, "light" exclusion at line 590). Plasma adds dripping slag sprites in the weapon colour for 2 to 3 seconds (fx_weapons_gd.txt lines 622-626), but those are transient and do not persist as a distinct mark.

Cost to the player: at fleet distance a battery-battered hull section looks the same as one hit by a lance or a torpedo, because all three leave the same generic scorch decal. The intended "many small hits darken the plate" read is absent; the player cannot distinguish sustained light fire from a few heavy hits unless they watch the transient impacts.

### A2. Lance

Verdict: MISSES SPEC

The spec (damage_marks_reference.md line 26) calls for a persistent lit slot, capped at 2 to 3 per section, with repeats lengthening the slot and a possible far-side exit point. The implementation runs _beam_burn (fx_weapons_gd.txt lines 697-730), which draws a white contact sprite for the burn duration, then a molten trench of 22 cooling-metal sprites dragged across the plate over the burn, plus spark spray, molten droplets and smoke. All of that is transient (sprite life 2.0 to 2.8 s). The only persistent trace is one generic scorch decal at the hit point, size 1.8 times scale, placed when the burn ends (fx_weapons_gd.txt line 729). There is no slot geometry, no lengthening on repeat hits, and no exit mark for beams.

Cost to the player: the lance's signature "burned line through the hull" identity is gone the moment the transient sprites fade. The player cannot look at a ship later and say "that was lanced." The mark reads identically to a battery scorch.

### A3. Ion

Verdict: MISSES SPEC

The spec (damage_marks_reference.md lines 18, 32) specifies a persistent branching tree on the hull, re-energised and extended by repeat hits, scarring as a faint fern etching. The implementation routes ion hull hits through the same _beam_burn path as lance (fx_weapons_gd.txt lines 697-730) and leaves the same generic scorch decal. The one ion-specific extra is a blue static wash on the shield facing after a hull burn, conditional on the target having a shield material (fx_weapons_gd.txt lines 724-726). No branching figure, no fern etch, no re-energise logic exists anywhere in the impact or decal code.

Cost to the player: ion, which the spec positions as the most visually distinctive energy weapon, is indistinguishable from lance in its persistent mark. The branching-tree identity that would let a player read "ion damage" at a glance is entirely absent.

### A4. Torpedo

Verdict: PARTIAL

The spec (damage_marks_reference.md line 29) wants one persistent blast crater per section, denting the outline with plates peeled outward, and a second hit upgrading the crater's stage. The implementation's _big_hit (fx_weapons_gd.txt lines 793-822) delivers a strong transient show: gated pop, raymarched fireball on max quality (fx_death_gd.txt lines 226-250), sympathetic pop at 0.3 s, shockwave ring, distortion, 40 spark streaks, 14 debris shards, embers, the strongest shake and hit pause. The persistent trace is the largest generic scorch decal at 2.6 times scale (fx_weapons_gd.txt line 821). Crater-class geometry (holes with plates bent back) appears only when the section's hit-point fraction crosses stage 3 or 4 thresholds, and then at the section's pre-picked anchor, not at the torpedo's actual hit point (fx_ship_gd.txt lines 472, 562-587).

Cost to the player: the torpedo impact feels heavy in the moment, but the lasting mark is a scorch decal identical in kind to every other family's. The spec's "one crater per section, upgraded by a second torpedo" identity is not present. A torpedo hit on a healthy section leaves no outline change; the crater appears later at a different spot if accumulated damage crosses a threshold. The player cannot point at a crater and attribute it to a torpedo.

### A5. Flak

Verdict: NOT IMPLEMENTED

The spec (damage_marks_reference.md line 30) calls for a persistent stippled pockmark patch per section that grows in area and density and never exposes structure. The implementation's _flak (fx_weapons_gd.txt lines 502-545) bursts 4 proximity shells with gated core pops and hanging smoke balls lasting about 2.6 seconds. A flak hit that reaches _impact is in the "light" set and leaves no decal (fx_weapons_gd.txt lines 590, 635). No flak-specific persistent mark of any kind exists in the code.

Cost to the player: flak fire, which the spec positions as a slow accumulating texture on the hull, leaves zero lasting evidence. A ship under sustained flak looks identical to an untouched one once the smoke clears. The player has no way to see that flak has been doing its work.

### A6. Bio

Verdict: PARTIAL

The spec (damage_marks_reference.md line 31) wants an irregular eaten patch that keeps spreading briefly, visibly stops, and scars as pitted corrosion with stained streaks. The implementation's _bio_splat (fx_weapons_gd.txt lines 732-752) draws wet splash sprites, drip streaks, fume sprites for 2.5 to 3 seconds, and a low light. The persistent mark is a corrosion hole decal with the bio flag (fx_weapons_gd.txt lines 747-751), rendered by the DECAL shader with a green growth fringe tint (fx_shaders_gd.txt lines 788, 814, 818). The decal is created at full size with fixed parameters (open 0.28, heat 0.5); no growth or stop animation is in the decal creation path. UNSURE whether the DECAL shader's noise animation (fx_shaders_gd.txt lines 792, 803) reads as spreading; the code does not state this intent.

Cost to the player: bio is one of only two families with a visually distinct persistent mark (the other is gauss), which is good. However, the spec's "spreading then stopping" behaviour, which would make bio feel alive and threatening, is absent. The mark appears fully formed. The stained streaks are also missing.

### A7. Gauss

Verdict: PARTIAL

The spec (damage_marks_reference.md line 28) agrees the clean hole cannot read at fleet distance and specifies a bright companion cue: a pale stress ring with radial cracks or a petaled collar for the distance read, with the clean hole as the zoom read. The implementation's _gauss_punch (fx_weapons_gd.txt lines 754-791) provides a gated pop, a tight spark cone, and an exit burst on the far side found by a ray through the ship (lines 766-786). The persistent marks are two hole decals: entry at the hit point (size 0.6 times scale, open 0.3, heat 1.0, line 786) and exit at the far-side point (size 0.9, open 0.35, heat 1.0, line 781), both with parallax cavity on max quality (fx_death_gd.txt lines 154-173). No persistent ring, collar, or crack pattern accompanies the holes. The entry hole is smaller than the exit hole.

Cost to the player: the zoom tier is well served; the parallax hole with ribs and conduits is a strong detail read. But the distance tier, which the spec explicitly addresses because the hole alone is too small to see, gets nothing. At fleet range a gauss hit is invisible once the transient exit spray fades. The player must zoom in to confirm gauss damage occurred.

### A8. Squadron weapons

Verdict: MEETS SPEC

The Job A sheets (a5_effects_sheets_synthesis.md line 82) give craft hull impacts spark ticks and pinhole scorch at most. The implementation's _strafe (fx_weapons_gd.txt lines 547-580) flies craft past with engine sprites, vapour trails, miniature tracers, bombs or spore sacs. No persistent mark is placed. Squadron ships themselves never show stage damage: sync() forces their stages to 0,0,0 (fx_ship_gd.txt lines 481-482), and _plan returns no geometry for squadrons or weight-0 craft (fx_ship_gd.txt line 565). Craft deaths are a single gated pop plus a fire sprite and smoke (fx_death_gd.txt lines 631-642). The marks reference has no separate squadron mark entry.

Cost to the player: negligible. The spec sets a low bar for squadron weapons and the implementation meets it. The transient tracers and bomb effects give enough feedback for the moment of impact.

### A9. Ram

Verdict: MISSES SPEC

The spec (damage_marks_reference.md line 33) calls for a crumple: a dent breaking the outline with folded plating and scrape streaks along the impact direction, no glow, permanent until repaired, with a matching smaller crumple on the ramming ship. The implementation treats ram as an instant _big_hit at 1.5 times scale (fx_weapons_gd.txt lines 247-249, 606), leaving the same 2.6-scale generic scorch decal as a torpedo (fx_weapons_gd.txt line 821). No ram-specific geometry, no scrape streaks, no attacker-side mark exists. Outline change comes only from the stage ladder's stage-4 edge bite at a pre-picked anchor (fx_ship_gd.txt lines 580-585), which any damage source can trigger.

Cost to the player: ramming, which the spec reserves as one of only two silhouette-changing events (reference line 16), produces no silhouette change of its own. The player sees a generic scorch and a big transient bang. The physicality of two ships colliding, the folded metal, the directional streaks, the matching damage on the rammer: none of it is present. Ram feels like a slightly bigger torpedo hit rather than a collision.

### A10. Boarding

Verdict: MISSES SPEC

The spec (damage_marks_reference.md line 34) wants a torn gash at a plausible boarding point (airlock, docking collar), venting and interior light while the boarding action is live, and a scar of a dark gash partly covered by a mismatched patch plate. The implementation routes the tendril impact to _bio_splat with a lash flag whose only effect is slightly stronger shake (fx_weapons_gd.txt lines 732, 745). The persistent trace is the same corrosion hole decal as bio (fx_weapons_gd.txt lines 747-751). The hit point is a surface sample in the struck section facing the attacker (fx_weapons_gd.txt lines 128-152), not a boarding socket. No venting-while-live state and no patch plate stage exist in the fx layer. UNSURE whether the rules or UI layer draws any boarding-specific visual; it is not in godot/fx.

Cost to the player: boarding is a tactically significant action (crew transfer, capture attempts) and the spec gives it a unique mark identity. The player currently sees a bio splash, which is the wrong fiction entirely. There is no visual signal that a boarding action is in progress (no venting, no interior light), and no lasting scar that says "someone cut their way in here."

### A11. Cross-cutting mark behaviour

Verdict: PARTIAL

Taken item by item:

Persistence. Hit decals persist until evicted by the 10-per-ship cap or the battle ends (fx_ship_gd.txt lines 816-826). Breach geometry persists until the stage changes. This meets the persistence requirement.

Fresh / cooling / scarred evolution. Hit scorch decals are created at a fixed emission energy (default 0.7, fx_death_gd.txt line 141) and never change. There is no cooling or scar fade for them. Hole decals receive heat as a constant uniform at creation (fx_shaders_gd.txt line 743; fx_death_gd.txt line 167); the shader header comment says heat cools toward 0.15 (fx_shaders_gd.txt line 737), but the fragment code (fx_shaders_gd.txt lines 765-833) uses heat only as a multiplier with no age or birth-time term, and nothing in godot/fx updates a decal's heat after creation. Breach interiors do cool: the HOLE shader computes age from a t0 uniform and decays hot as exp(-age / 10) toward 0.45 times heat (fx_shaders_gd.txt lines 874-876). So the three-stage glow evolution exists only for breach interiors, not for the per-weapon decals that are the spec's primary mark layer.

Caps and repeat handling. The cap is 10 decals per ship, oldest first, enforced only inside add_hit_scorch (fx_ship_gd.txt lines 816-826). Gauss and bio hole decals append to the same array without trimming (fx_weapons_gd.txt lines 751, 781, 786), so the array can exceed 10 between scorch calls. There is no per-section cap. There is no growth or merging of repeat marks: a repeat hit places a new decal at its own hit point. The spec's budget is 3 signature marks per section with repeats growing the existing mark (damage_marks_reference.md line 13). The implementation's cap is 10 per ship with repeats placing new decals.

Repair reversal. sync() recomputes stages from current hit points, so a repaired section's stage drops; _apply_stages rebuilds the section without the stage-up burst (fx_ship_gd.txt lines 507-520), and hull geometry is recomputed from the original mesh arrays, so dents and holes close (fx_ship_gd.txt lines 589-627). Hit decals are not removed by repair; they persist until evicted. The spec asks repairs to visibly reverse marks (damage_marks_reference.md line 45). Geometry follows this rule; decals do not.

Shield-only-hit rule. _target routes a pure shield hit (shield damage above 0, hull damage at or below 0) to _shield_impact and returns before any decal code (fx_weapons_gd.txt lines 140, 592-594). Shield-only hits leave no hull mark. This matches the spec's recommendation (damage_marks_reference.md, open question 3).

Cost to the player: the marks layer does not evolve over time the way the spec intends. A fresh mark does not glow and cool; it appears at fixed brightness and stays there. Repeated hits do not grow a mark; they scatter new decals until the cap evicts old ones. Repairs close geometry but leave scorch decals floating on restored hull, which reads as a visual bug. The shield rule is correctly handled and costs the player nothing.

## B. The counted-flash rule

### B1. Counted-flash definition

Verdict: MISSES SPEC

Spec B (a5_effects_sheets_synthesis.md line 118) defines a counted flash as one brightness transition pair (dark to bright to dark) on a given emitter above a moderate contrast step. Small dim sparks below the step do not count. The code has no brightness or contrast-step measurement. Any pop() call is one counted flash regardless of its size, intensity, or visual weight (fx_gd.txt lines 338-344). A merged flash (one landing within FLASH_WINDOW of an already-counted flash) draws at full brightness without counting (fx_gd.txt lines 317-318). The spec's per-emitter tracking and the "moderate contrast step" threshold are both absent.

Cost to the player: the budget treats a tiny spark pop and a full torpedo fireball identically. A salvo of small battery impacts can exhaust the flash budget and suppress a torpedo's bright core, which inverts the intended priority. The spec's contrast-step exemption exists to prevent exactly this. WCAG 2.3.1 (three flashes per second threshold) and 2.3.2 (three flashes per second at any size) are the accessibility standards the spec cites; the code's flat counting is more conservative than WCAG requires for small dim events, but less accurate to the spec's intent.

### B2. Cap and counting window

Verdict: PARTIAL

FLASH_CAP is 3 (fx_gd.txt line 28), matching the spec's cap of 3. The counting window: flash_ok counts recorded flashes with |f - T| under 1.0 s (fx_gd.txt lines 319-323). The spec says a rolling one-second counter (a5_effects_sheets_synthesis.md line 118). For effects queried in strict time order the two agree. However, the code's symmetric window (1.0 s on either side of T) means a flash can be counted against one scheduled up to 1.0 s in its future. Volleys schedule future impact times, so a flash at T can be refused because of a flash that has not happened yet but is scheduled within the next second.

Cost to the player: in practice, the symmetric window is slightly more conservative than a strict rolling window. A player might see a flash suppressed a fraction of a second before the "real" budget window would have required it. The effect is small and errs on the side of reducing flashes, which aligns with the accessibility intent. The cap of 3 is correct.

### B3. Merge window

Verdict: MISSES SPEC (with an internal contradiction)

Three positions exist. The code constant FLASH_WINDOW is 0.12 s (fx_gd.txt line 28). The API doc also claims 0.12 s (fx_api_md.txt line 128). Spec B says 0.33 s (a5_effects_sheets_synthesis.md line 118). The code's own comment directly above flash_ok reads "Flashes inside 0.33 s of a counted one merge into it (free)" (fx_gd.txt line 314), matching the spec number, not the constant.

The code implements 0.12 s. The comment above the function says 0.33 s. The spec says 0.33 s. The API doc says 0.12 s. The code and the API doc agree with each other and disagree with the spec. The code and the spec disagree, and the code's own comment agrees with the spec against the code's own constant.

I weigh this as follows. The spec is the authority the implementation is judged against. The spec says 0.33 s. The code's comment says 0.33 s, suggesting the implementer knew the spec number. The constant is 0.12 s, matching the API doc. Either the constant was written to the API doc's number and the comment was written to the spec's number, or the constant was changed after the comment was written. Either way, the shipped merge window is 0.12 s, not 0.33 s. A 0.12 s window merges fewer concurrent flashes than a 0.33 s window, so more flashes are counted individually, and the budget is hit sooner. In a dense salvo the player sees fewer bright flashes than the spec intends, because flashes that the spec would merge into one counted event are counted separately.

Cost to the player: moderate. In a heavy volley the 0.12 s window lets fewer flashes through before the cap triggers. The visual result is more fallback dim sprites and rings than the spec's 0.33 s window would produce. The player sees a slightly duller battle than the spec intends. The internal contradiction (comment says 0.33, constant says 0.12) is a maintenance hazard.

### B4. Coverage

Verdict: PARTIAL

The flash budget gates: pop() calls (fx_gd.txt lines 338-344), the gauss muzzle sprite (fx_weapons_gd.txt line 293), the beam burn's initial white bloom (fx_weapons_gd.txt line 702), flak airburst cores (fx_weapons_gd.txt line 536), and the death sequence's final blast sprite (fx_death_gd.txt lines 679-682).

The budget does not gate: the battery muzzle blast's bright core, which is a direct sprite at intensity 11 checking only reduce_flashing (fx_weapons_gd.txt lines 317-327); beam ribbons, charge flares and beam sprites drawn directly (fx_weapons_gd.txt lines 236-256); event lights, a separate pooled system with peaks up to 14.0 (fx_gd.txt lines 349-410; fx_weapons_gd.txt line 818); shield ripple hits, which are shader-side (fx_ship_gd.txt lines 383-392); the torpedo fireball volume (fx_death_gd.txt lines 226-250); and the rolling flame sprite train in the death break-up after the first gated blast (fx_death_gd.txt lines 684-690).

Cost to the player: the spec's flash rule is meant to protect the player's eyes and meet WCAG 2.3.2. The ungated emitters are bright. A battery muzzle at intensity 11 (fx_weapons_gd.txt line 317) is a significant brightness event. Event lights peaking at 14.0 (fx_weapons_gd.txt line 818) are the brightest point sources in the system. A torpedo fireball is a large, bright, sustained volume. None of these count toward the cap of 3. In a busy turn with multiple batteries firing, torpedoes impacting, and a ship dying, the actual number of brightness events the player experiences can far exceed 3 per second. The budget gates the wrong subset. WCAG 2.3.2's concern is total flashes reaching the eye, not flashes routed through a particular function.

### B5. Over-budget behaviour

Verdict: PARTIAL

For pop() users, the fallback is a dimmer, longer glow sprite (intensity min(i, 3) times 0.4, life at least 0.4 s) plus an expanding ring (fx_gd.txt lines 341-344). For flak bursts, the code skips only the core sprite and keeps the shrapnel and the hanging smoke ball (fx_weapons_gd.txt lines 535-545). The death sequence's final blast has a dimmer longer fallback sprite when refused (fx_death_gd.txt lines 679-682).

Spec B says over-budget flak bursts render as smoke and sparks without the bright core pop (a5_effects_sheets_synthesis.md line 118). The flak path matches this: shrapnel and smoke survive, the core does not. The pop() fallback, however, keeps a visible glow lift (intensity up to 1.2, life at least 0.4 s) plus a ring. The spec's over-budget language is "smoke and sparks without the bright core," which implies no bright glow. The pop() fallback's glow is dimmer than the full flash but is still a brightness event. This matches the reduce-mode replacement language ("rings and gentle glow," fx_api_md.txt line 129) more than the over-budget language.

Cost to the player: small. The dimmer glow plus ring is a reasonable visual compromise and is clearly less stimulating than the full flash. But it is not what the spec describes for over-budget events. A player relying on the flash rule for comfort might still perceive the fallback glow as a flash, depending on the contrast step. The flak path is correctly implemented.

### B6. Reduce-flashing mode

Verdict: PARTIAL

Setting reduce_flashing makes flash_ok always return false (fx_gd.txt lines 315-316), which achieves 0 counted flashes for the gated set. The global shader parameter fx_calm is set to 1 (fx_gd.txt lines 33-36). Shader flicker functions blend fast flicker to slow breathing under fx_calm (fx_shaders_gd.txt lines 38-40). The battery muzzle blast swaps its bright core for a dimmer, longer sprite (fx_weapons_gd.txt lines 318-322). Decay-shape event lights are softened: peak times 0.45, life times 1.8 (fx_gd.txt lines 349-353). Persistent light-source flicker slows to a 2 Hz sine at 0.3 amplitude (fx_gd.txt lines 391-393). Effect shake is halved (fx_gd.txt line 453).

This matches the API doc's reduce claims (fx_api_md.txt line 129) and the Job A reduce target of 0 counted flashes for the gated set. However, the ungated emitters listed in B4 (beam ribbons, charge flares, event lights, shield ripples, torpedo fireball, death flame train) are calmed through the fx_calm and light-softening paths but are not removed. They remain as brightness events. The spec says reduce-flashing mode is 0 counted flashes achieved with named replacement techniques (a5_effects_sheets_synthesis.md line 118). If the ungated emitters produce brightness transitions above the moderate contrast step, they are counted flashes by the spec's definition, and reduce mode does not reach 0.

Cost to the player: a photosensitive player enabling reduce-flashing mode expects 0 counted flashes. The gated set correctly reaches 0. The ungated emitters, particularly event lights at peak 14.0 and beam sprites, may still produce brightness transitions above a moderate contrast step. Whether they do depends on the scene's baseline brightness and the player's display, which the attachments do not settle. The risk is real but the magnitude is UNSURE.

## C. The two-tier read

### Distance tier

Verdict: PARTIAL

The distance tier is the stage ladder. A player at fleet range can see: scorch decal size and emission scaled by stage (emission energy 0.15 at stages 1-2, 0.3 at stages 3-4, fx_ship_gd.txt lines 667-670); smoke wisps at stages 1-2; spark and gas emitters at stage 2 and up; debris shedding at stage 3 and up; breach fire and interior light at stage 4; engine sputter when the engine section reaches stage 3 (fx_ship_gd.txt lines 515-519); and the rules-driven burning state lighting 2 to 3 fire spots across the whole ship (fx_ship_gd.txt lines 781-813). A stage increase fires a burst at the anchor (gated pop, streaks, shards, debris, fx_ship_gd.txt lines 717-727), which serves as the freshness signal.

This answers two of the spec's three one-second-test questions (damage_marks_reference.md line 39): how hurt the ship is (stage 0 through 4 maps to visual density), and which section is worst (the most damaged section has the most smoke, sparks, debris, and the biggest scorch). The third question, roughly what has been hitting it, is not answered. Every family except gauss and bio leaves the same generic scorch decal (fx_weapons_gd.txt line 635; fx_death_gd.txt lines 131-151). Gauss and bio share one decal shader distinguished by a tint flag (fx_shaders_gd.txt line 788). Weapon identity is readable only while the transient impact plays.

The implementation has 3 hull sections: engine, mid, prow, defined as lengthwise thirds (fx_hull_gd.txt lines 8-10, 92-94). The spec assumed roughly 4 to 8 sections (damage_marks_reference.md, open question 2, line 62 area). Three sections coarsen the read. A player can tell "the middle third is worst" but not "the port quarter is worst." The spec's per-section cap of 3 signature marks (line 13) becomes 3 marks across a full third of the ship, which is a much larger area than the spec's assumed section.

The spec's glow ration (at most 2 glowing marks and 1 particle emitter per ship at fleet distance, damage_marks_reference.md line 41) has no counterpart in the code. Persistent emitters per section grow with stage (sparks, gas, debris, breach emitters, fx_ship_gd.txt lines 643-730), and event lights are pooled globally by brightness, not rationed per ship (fx_gd.txt lines 362-410).

Cost to the player: the distance tier tells you a ship is hurt and where, but not what hurt it. In a fleet battle with mixed weapons, the player cannot glance at a cruiser and read "lanced on the prow, torpedo hit mid, flak pockmarks aft." The 3-section granularity also means a ship with damage concentrated in one quarter reads the same as one with damage spread across a full third. The missing glow ration means a heavily damaged ship can have many simultaneous emitters, which may clutter the fleet view.

### Zoom tier

Verdict: PARTIAL

The zoom tier is served by: hole decals with parallax cavity, ribs and conduits on max quality (fx_shaders_gd.txt lines 746-800); real cut geometry with peeled petal plates and built interiors for stage 3-4 holes (fx_breach_gd.txt lines 2-13, 735-820); crack emission textures on stage decals (fx_death_gd.txt lines 131-151); and the HOLE shader's cooling interior glow (fx_shaders_gd.txt lines 874-876). Gauss entry and exit holes are distinct in size and placement (fx_weapons_gd.txt lines 781, 786). Bio corrosion has a green fringe tint (fx_shaders_gd.txt lines 788, 814, 818).

This is strong detail work for the weapons that produce it (gauss, bio, and stage-driven breaches). However, the majority of weapons (battery, lance, ion, torpedo, flak, ram, boarding) leave the same generic scorch decal or nothing at all. The zoom tier's richness is available for two families and the stage ladder, but not for the eight other weapon types the spec gives distinct marks.

Cost to the player: a player who zooms in on a gauss hit is rewarded with a detailed parallax hole. A player who zooms in on a lance hit sees the same scorch decal they would see on a battery hit. The zoom tier's purpose in the spec is to reward closer inspection with weapon-specific detail; that reward exists only for gauss and bio.

## Sources

WCAG 2.3.1 (three flashes or below threshold) and WCAG 2.3.2 (three flashes per second) are the accessibility standards the spec and the API doc cite. I have not accessed the live WCAG documents for this review; I rely on the spec's and API doc's own citations and on the well-established content of those success criteria. The spec's "moderate contrast step" language tracks the WCAG flash definition's contrast requirement. I note that the code implements no contrast measurement at all, which is a gap regardless of the exact threshold value.

The 0.12 s versus 0.33 s merge-window disagreement is a spec-internal matter. I have argued it from the spec text, the code, the code's own comment, and the API doc, as instructed, without appealing to outside authority.

No other external standards or published guidance were relied upon for this review.

## 1. Ranked fixes

1. Add per-weapon decal identity to the generic scorch path. In fx_weapons_gd.txt (impact dispatch, lines 583-637) and fx_death_gd.txt (decal creation, lines 131-173), replace the single generic scorch decal with per-family mark shapes: a slot for lance, a branching figure for ion, a crater for torpedo, a stippled patch for flak, a crumple with streaks for ram, a gash for boarding. Repairs A1 through A5, A9, A10, and the distance-tier weapon-identity gap in C.
2. Gate all bright emitters through flash_ok or an equivalent budget check. In fx_weapons_gd.txt (battery muzzle, lines 317-327; beam sprites, lines 236-256), fx_gd.txt (event lights, lines 349-410), and fx_death_gd.txt (torpedo fireball, lines 226-250; death flame train, lines 684-690), route brightness events through the budget. Repairs B4 and B6.
3. Change FLASH_WINDOW from 0.12 to 0.33 and reconcile the API doc. In fx_gd.txt line 28, set the constant to 0.33 to match the spec and the code's own comment at line 314. Update fx_api_md.txt line 128. Repairs B3.
4. Add a brightness or contrast-step check to the flash definition, or at minimum weight pop() calls by intensity. In fx_gd.txt flash_ok (lines 315-334) and pop (lines 338-344), exempt events below a contrast threshold so small sparks do not consume the cap. Repairs B1.
5. Implement fresh / cooling / scarred emission evolution on hit decals. In fx_death_gd.txt (scorch decal creation, lines 131-151) and the DECAL shader in fx_shaders_gd.txt (lines 737-833), add a birth-time uniform and decay emission from fresh glow to cooling to dark scarred. The HOLE shader's age-based cooling (fx_shaders_gd.txt lines 874-876) is a working model to follow. Repairs A11 (evolution).
6. Change the decal cap from 10 per ship to 3 per section, and make repeat hits grow the existing mark. In fx_ship_gd.txt (add_hit_scorch, lines 816-826) and the gauss/bio append sites (fx_weapons_gd.txt lines 751, 781, 786), enforce a per-section cap and merge repeats. Repairs A11 (caps and repeat handling).
7. Remove hit decals on repair. In fx_ship_gd.txt _apply_stages (lines 507-520) or sync (lines 457-487), clear or fade decals in a section whose hit points have been restored. Repairs A11 (repair reversal).
8. Add a persistent distance-read cue to gauss (stress ring or petaled collar). In fx_weapons_gd.txt _gauss_punch (lines 754-791), add a ring or collar decal alongside the hole decals. Repairs A7 and the distance-tier gap in C.
9. Increase hull sections from 3 to at least 4. In fx_hull_gd.txt (lines 8-10, 92-94), subdivide the lengthwise thirds. This is a structural change with implications for the stage ladder, anchor selection, and breach geometry, so it is ranked lower despite its readability value. Repairs C (distance tier granularity).
10. Add a glow ration: cap persistent glowing marks at 2 and particle emitters at 1 per ship at fleet distance. In fx_ship_gd.txt _build_section (lines 643-730) and fx_gd.txt event-light pooling (lines 362-410), enforce per-ship limits. Repairs C (distance tier clutter).

## 2. UNSURE list

Carried forward from the evidence pack, plus items surfaced by this review.

- Whether anything outside godot/fx (rules or UI code) calls set_stages (fx_ship_gd.txt lines 503-504) to drive stages directly, bypassing the sync() thresholds. (Evidence pack UNSURE.)
- Whether any code outside godot/fx updates a hole decal's heat uniform after creation. (Evidence pack UNSURE.)
- The screen-space size of hit decals and stage visuals at the game's default tactical camera distance. The camera lives outside godot/fx. (Evidence pack UNSURE.)
- Whether flash budget tests exist under godot/fx/test. (Evidence pack UNSURE.)
- Whether boarding has any visual representation in the rules or UI layer. (Evidence pack UNSURE.)
- Whether the DECAL shader's animated ember noise (fx_shaders_gd.txt lines 792, 803) is intended to read as bio corrosion spreading. (Evidence pack UNSURE.)
- Whether the ungated emitters in reduce-flashing mode (beam sprites, event lights, torpedo fireball) produce brightness transitions above the WCAG moderate contrast step on typical displays. The attachments show the emitters exist and are calmed but not removed; the actual contrast depends on scene lighting and display settings not present in the attachments. (Raised by this review, B6.)
- Whether the symmetric counting window (|f - T| under 1.0 s, fx_gd.txt lines 319-323) causes visible flash suppression in actual volley scheduling. The attachments describe the mechanism but not the scheduling patterns. (Raised by this review, B2.)
- Whether the 3-section hull layout (fx_hull_gd.txt lines 8-10) was a deliberate design choice or a simplification pending the spec's open question on 4 to 8 sections (damage_marks_reference.md, open question 2). (Raised by this review, C.)

## 3. Overall verdict

The implementation delivers a solid transient-effects layer, a working staged-damage ladder with real mesh cutting, and a flash budget that captures the right architectural idea, but it systematically fails the two specs' core identities. The per-weapon marks spec is met only at the level of "some weapons leave a persistent decal"; nine of the ten weapon families leave either the same generic scorch or nothing, so the player cannot read what hit a ship, and the fresh-cooling-scarred evolution, per-section caps, and repeat-growth rules are absent. The counted-flash rule is implemented with the right cap and the right reduce-mode structure for the gated set, but the merge window contradicts the spec and the code's own comment, the flash definition ignores brightness thresholds, and enough bright emitters bypass the budget that the actual flash load on the player can exceed the cap of 3 per second. Taken together, the implementation is a competent effects system that serves the game's moment-to-moment spectacle well but does not yet deliver the persistent, legible, per-weapon damage narrative and the tight accessibility budget that the two specs were written to guarantee.
