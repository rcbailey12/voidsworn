# Effects implementation review, Gemini Argon leg, 2026-10-26

Chair header: filed as the single reviews copy for the Gemini leg (house pattern). Model: Gemini 4 Argon, Thinking level High, verified in two places before submitting ("Argon High" on the model-picker button and the prompt bar dropdown). The leg waited out a stated Argon rate limit (options disabled until 3:10 PM CDT) before running, 3:02-3:21 PM CDT. Five files attached (leg prompt, evidence pack, fx.gd, fx_weapons.gd, fx_ship.gd). Citation chips shown in the Gemini interface are interface elements, not model text, and are omitted. Model text follows verbatim.

---

A. Per-Weapon Marks

1. Battery (including plasma): PARTIAL

Evidence: fx_weapons_gd.txt:25-32, 43-51 maps battery and hbattery to macro; autocannon to auto (or las for Voidsworn); turret to las (or needle for Ithar); laser, turbo, and hturbo to plasma; scatter to scatter; and shard to prism. In _impact (fx_weapons_gd.txt:583-637), auto, las, scatter, and prism are placed in the light set (fx_weapons_gd.txt:590), which skips add_hit_scorch (fx_weapons_gd.txt:634-635) and leaves no hull mark. Ithar needle turrets route to _beam_burn (fx_weapons_gd.txt:45-46, 588, 599-600) and leave a 1.8 * k generic scorch decal (fx_weapons_gd.txt:728-729). Medium and heavy macro and plasma hits call Tg.add_hit_scorch (fx_weapons_gd.txt:634-635) to place one of 3 random scorch textures (fx_death_gd.txt:131-151) of size 0.9 * k (weight 2) or 1.4 * k (weight 3) into the ship-wide _hit_decals array (fx_ship_gd.txt:816-826), rather than baking into a per-section scorch layer (damage_marks_reference.md:15). plasma spawns 4 glowing slag sprites (kind 21, life 2.0 to 3.0 s) and 4 drip streaks (kind 7, life 0.7 s) at fx_weapons_gd.txt:622-626, but leaves the same generic orange-ember scorch decal with no splash crater, no persistent droplet fan, and no light blue core (damage_marks_reference.md:27, 52).

Player cost: Light battery fire leaves no hull record, while macro and plasma hits consume slots in the 10-decal ship cap (fx_ship_gd.txt:821) and evict older gauss or bio holes instead of baking into a section scorch layer. Once plasma's 3-second slag sprites fade, a plasma hit is indistinguishable from a macro shell hit.

2. Lance: PARTIAL

Evidence: lance and needle (along with pulsar and doom) route to _beam_burn (fx_weapons_gd.txt:588, 599-600, 697-730). _beam_burn drags 22 transient cooling-metal sprites (kind 21, life 2.0 to 2.8 s) across 2.6 * k along a tangent vector during the burn (fx_weapons_gd.txt:705-710), and at T + dur places a single circular generic scorch decal of size 1.8 * k at tg["lp"] (fx_weapons_gd.txt:728-729). Spec A (damage_marks_reference.md:26) requires a persistent lit slot capped at 2 to 3 per section, repeat hits that lengthen the slot, and a possible far-side exit point. None of those exist in fx_weapons_gd.txt:697-730.

Player cost: After 2.8 seconds, the molten trench disappears and leaves a round generic scorch spot identical to a heavy battery mark. The player cannot tell on later turns that a ship was raked by lances or see repeat lance hits lengthening a cut.

3. Ion: MISSES SPEC

Evidence: ion uses the beam ribbon path (kind 5, fx_weapons_gd.txt:197-214) and routes hull impacts to _beam_burn (fx_weapons_gd.txt:588, 599-600, 697-730). On a hull hit, it draws the same orange molten trench (Color(1, 0.6, 0.2), fx_weapons_gd.txt:705-710) and places the same 1.8 * k generic scorch decal (fx_weapons_gd.txt:728-729) as a thermal lance, adding only a 1.2 s transient shield-shader wash (Tg.shield_hit at fx_weapons_gd.txt:724-726) if the target has a shield material. Spec A's persistent branching tree figure, repeat extension, and faint fern-like scar etching (damage_marks_reference.md:18, 32) are absent from fx_weapons_gd.txt and fx_shaders_gd.txt.

Player cost: Ion beams leave a thermal melt trench and a generic black-and-orange scorch spot instead of an electrical branching scar, removing all persistent visual distinction between ion and thermal beam weapons.

4. Torpedo: PARTIAL

Evidence: torp, rockets (htorp or Corsair torp), star (startorp), and B3 lane strikes (torp_strike, fx_weapons_gd.txt:993) route to _big_hit (fx_weapons_gd.txt:587, 605-606, 793-822). _big_hit plays a large transient blast (gated pop, raymarched DEATH.fireball on "max" quality at fx_weapons_gd.txt:801 and fx_death_gd.txt:226-250, sympathetic pop at T + 0.3, shockwave ring, distortion, 40 streaks, 14 shards, 20 embers, 6 debris pieces, light peak 14.0, shake 0.45, and 4-frame hit pause), but its persistent mark at the hit point is only a generic scorch decal of size 2.6 * k (1.82 * k for rockets, fx_weapons_gd.txt:606, 820-821). Spec A (damage_marks_reference.md:16, 29) reserves silhouette change for ram and torpedo and calls for one persistent blast crater per section with outward-peeled plates that upgrades on a second hit. In code, peeled-plate holes (BREACH.hole, fx_ship_gd.txt:574-586, fx_breach_gd.txt:2-13) and upper-edge silhouette bites (anchor "b", fx_ship_gd.txt:543-549, 580-585) are never cut by _big_hit; they appear only when section HP crosses stage 3 (<= 0.4) or stage 4 (<= 0.2 or broken) in sync() (fx_ship_gd.txt:466-476), at a pre-picked random section anchor rather than the torpedo hit point.

Player cost: A torpedo hit that leaves a section above 40% HP produces only a flat scorch decal with no crater or silhouette dent. When a section does drop below 40% or 20% HP, the crater and silhouette bite open at a random anchor rather than where the torpedo struck, and ordinary gunfire can trigger the same crater and silhouette bite.

5. Flak: NOT IMPLEMENTED

Evidence: _flak (fx_weapons_gd.txt:502-545) bursts 4 proximity shells around the target. When a non-miss flak shot reaches _impact (fx_weapons_gd.txt:258-259, 583-637), flak, pflak, mflak, and gflak are in light (fx_weapons_gd.txt:590) and leave no decal (fx_weapons_gd.txt:634-635). Chorus flak (spores, fx_weapons_gd.txt:49) is included in bio (fx_weapons_gd.txt:589) and routes to _bio_splat (fx_weapons_gd.txt:601-602), leaving a single 0.9 * k bio corrosion hole decal (fx_weapons_gd.txt:747-751). Spec A's persistent stippled pockmark patch per section that grows in area and density and never exposes structure (damage_marks_reference.md:30) is not implemented, and HP loss from flak still triggers stage 3 and 4 structural breaches in sync() (fx_ship_gd.txt:466-476, 574-586).

Player cost: Flak bursts leave no surface pockmark pattern on hulls (while Chorus spores flak leaves an acid hole), and a ship chipped below 40% section HP by flak opens a deep structural hull breach instead of surface peppering.

6. Bio: PARTIAL

Evidence: spine (bioplasma), sporeb, spores, and tendril route to _bio_splat (fx_weapons_gd.txt:589, 601-602, 732-752), which skips any bright flash, spawns wet splash sprites (kind 15), drip streaks (kind 6), green fumes (kind 20), and acid globs (kind 21), and at T + 0.3 appends a DEATH.hole_decal with bio = true, size = 0.9 * k, open = 0.28, and heat = 0.5 (fx_weapons_gd.txt:747-751, fx_death_gd.txt:154-173). The DECAL shader tints the fringe green when bio is set (fx_shaders_gd.txt:788, 814, 818), but creates the decal at full size with constant uniforms (fx_shaders_gd.txt:743, 765-833). Spec A's brief post-impact spreading growth, visible stop, and transition to an unlit pitted/streaked scar (damage_marks_reference.md:31) are not implemented in the decal geometry or uniform updates.

Player cost: Bio hits leave a distinct green corroded cavity at the hit point, but the player never sees the patch expand and halt after impact, and old bio scars keep the same heat = 0.5 shader state as fresh hits.

7. Gauss: PARTIAL

Evidence: _gauss_punch (fx_weapons_gd.txt:754-791) fires an entry pop and tight spark cone, raycasts through the hull (Tg.hull.ray, fx_weapons_gd.txt:766) to spawn a far-side exit spray at T + 0.04 (fx_weapons_gd.txt:767-777), and places two parallax cavity hole decals (DEATH.hole_decal, fx_death_gd.txt:154-173, fx_shaders_gd.txt:746-800): an entry hole of size 0.6 * k (open 0.3, heat 1.0, fx_weapons_gd.txt:786) and an exit hole of size 0.9 * k (open 0.35, heat 1.0, fx_weapons_gd.txt:781). Spec A (damage_marks_reference.md:28) requires a bright distance-tier companion cue (a pale stress ring with radial cracks or a petaled collar) paired with the clean zoom-tier hole. No persistent stress ring or collar exists (evidence_pack_fx.md Section 2).

Player cost: Close zoom shows an accurate entry and larger exit punch-through cavity, but at fleet camera distance the small 0.6 * k entry hole lacks the pale stress ring or collar needed to read at a glance.

8. Squadron weapons: MEETS SPEC

Evidence: Squadron attacks (kind "sq", looks guns, bombs, sporeb) run _strafe (fx_weapons_gd.txt:252-253, 547-580) and _impact (fx_weapons_gd.txt:258-259). guns is in light (fx_weapons_gd.txt:590), producing spark streaks and a small pop while leaving no persistent hull decal (fx_weapons_gd.txt:608-612, 634-635), matching Spec B (a5_effects_sheets_synthesis.md:82, spark ticks and pinhole scorch at most). Squadron units themselves have their section stages forced to [0, 0, 0] in sync() (fx_ship_gd.txt:481-482) and return no cut geometry in _plan() (fx_ship_gd.txt:565). One implementation quirk in _impact: bombs (w = 2, fx_weapons_gd.txt:36) is omitted from light (fx_weapons_gd.txt:590) and leaves a medium 0.9 * k scorch decal (fx_weapons_gd.txt:635), and sporeb is in bio (fx_weapons_gd.txt:589) and leaves a 0.9 * k bio hole decal (fx_weapons_gd.txt:750).

Player cost: Fighter guns runs cleanly avoid cluttering capital ship hulls, though bombs and sporeb bomber runs leave medium 0.9 * k decals identical to ship-mounted medium weapons.

9. Ram: MISSES SPEC

Evidence: In _shot (fx_weapons_gd.txt:216-218), ram impacts immediately (ti = T0) and routes in _impact to _big_hit at 1.5 * k scale (fx_weapons_gd.txt:587, 605-606). _big_hit (fx_weapons_gd.txt:793-821) spawns a fiery explosion (raymarched fireball, sympathetic pop, 40 hot streaks, 20 embers, peak 14.0 light) and places a glowing 3.9 * k (2.6 * 1.5 * k) scorch decal on the target only. Spec A (damage_marks_reference.md:16, 33) requires an unlit structural crumple breaking the outline with folded plating and directional scrape streaks, permanent until repaired, plus a smaller matching crumple on the ramming ship. None of these exist in fx_weapons_gd.txt or fx_ship_gd.txt.

Player cost: A ramming collision renders as an oversized fiery torpedo detonation with a glowing scorch decal rather than a cold metal crunch with directional scrapes, and the ramming ship receives no mark on its bow.

10. Boarding: MISSES SPEC

Evidence: Boarding (wid "tendril", look tendril, fx_weapons_gd.txt:28) fires a 0.9 s lash ribbon (kind 9, fx_weapons_gd.txt:239-243) to a standard facing surface sample (Tg.hull.hit_point, fx_weapons_gd.txt:142) and routes to _bio_splat with lash = true (fx_weapons_gd.txt:589, 601-602, 732-752). lash only raises camera shake from 0.05 to 0.1 (fx_weapons_gd.txt:745), and places the same 0.9 * k green acid hole_decal (fx_weapons_gd.txt:747-751) as bioplasma. Spec A's torn gash at a plausible boarding point (airlock or docking collar), venting and interior light while the boarding action is live, and scarred dark gash with a mismatched patch plate (damage_marks_reference.md:34) are absent from godot/fx.

Player cost: Boarding tendrils look like an acid bio-splat at a random hull point, giving the player no live visual indicator of an ongoing boarding action or a welded patch scar afterward.

11. Cross-cutting mark behaviour (persistence, evolution, caps/repeats, repair reversal, shield-only-hit rule): PARTIAL

Evidence:

Persistence: _hit_decals (fx_ship_gd.txt:52, 816-826) and stage geometry/nodes (_ents, _sec_nodes, fx_ship_gd.txt:56, 521-730) persist across turns, except under the gl_compatibility renderer (fx.compat, fx_gd.txt:126-128), where scorch_decal and hole_decal return empty Node3Ds (fx_death_gd.txt:132-135, 155-158) and draw nothing.

Fresh/cooling/scarred evolution: Spec A (damage_marks_reference.md:14, 56-58) requires marks to glow when fresh, settle while cooling, and turn dark and unlit when scarred, flagging turn-keyed decay. Hit scorch decals have a fixed emission energy (0.7, fx_death_gd.txt:141) that never cools. Hole decals pass heat (1.0 or 0.5) as a static uniform (fx_weapons_gd.txt:750, 781, 786, fx_death_gd.txt:167); despite a comment at fx_shaders_gd.txt:737 claiming heat cools toward 0.15, the shader fragment (fx_shaders_gd.txt:765-833) has no age term and nothing in godot/fx updates heat. Stage 3 and 4 breach interiors (SH.HOLE) cool in real-time seconds via exp(-age / 10) toward 0.45 * heat (fx_shaders_gd.txt:874-876, fx_ship_gd.txt:554-559, fx_breach_gd.txt:754), never reaching an unlit scar state and never keying to turns.

Caps and repeat handling: Spec A (damage_marks_reference.md:13) budgets 3 signature marks per section with repeats growing the existing mark. The code uses one ship-wide _hit_decals array trimmed to 10 only inside add_hit_scorch (fx_ship_gd.txt:821-825). Repeat hits always place a new decal rather than growing an existing mark, and _bio_splat and _gauss_punch append directly to Tg._hit_decals without trimming (fx_weapons_gd.txt:751, 781, 786), so later add_hit_scorch calls evict older gauss and bio hole decals via pop_front().

Repair reversal: Spec A (damage_marks_reference.md:45) requires repairs to reverse marks. When section HP increases in sync(), _apply_stages lowers stage[i] and rebuilds the hull mesh from _orig, closing stage 2 to 4 dents and breaches (fx_ship_gd.txt:457-520, 589-627), but _hit_decals is never cleared or reduced on repair.

Shield-only-hit rule: Meets Spec A (damage_marks_reference.md Open Question 3). _target marks hits with shield > 0.0 and hull <= 0.0 as on_shield (fx_weapons_gd.txt:140), and _impact routes them to _shield_impact and returns early (fx_weapons_gd.txt:591-593) before any hull decal code runs.

Player cost: Shield-only hits cleanly leave the hull untouched, but hull hit decals never cool from fresh glow to cold scar, clutter up instead of growing on repeat hits, get evicted by routine battery scorches, remain stuck on repaired hulls, and vanish completely in compatibility mode.

B. The Counted-Flash Rule

1. The counted-flash definition: PARTIAL

Evidence: Spec B (a5_effects_sheets_synthesis.md:118) defines a counted flash as one dark-to-bright-to-dark transition pair on a given emitter above a moderate contrast step, exempting dim sparks below the step. This follows W3C WCAG 2.3.1 (Three Flashes or Below Threshold), which defines a general flash as a pair of opposing relative luminance changes of 10% or more of maximum luminance where the darker state is below 0.80 relative luminance (and covering at least 0.006 steradians, or 25% of a 10-degree visual field). In fx_gd.txt:315-334, flash_ok(T: float) accepts only a timestamp T and has no luminance, contrast-step, emitter, or screen-area parameters. Every caller (pop() at fx_gd.txt:338-344, gauss muzzle at fx_weapons_gd.txt:293, flak airburst at fx_weapons_gd.txt:536, beam bloom at fx_weapons_gd.txt:702, and death blast at fx_death_gd.txt:679) counts as one flash whether its intensity is 3.5 (_shield_impact, fx_weapons_gd.txt:668) or 14.0 (_big_hit, fx_weapons_gd.txt:797).

Player cost: Small or distant low-contrast pops consume the same global flash budget slots as massive close-up torpedo detonations, causing heavy impacts later in the same second to lose their bright core.

2. The cap and the counting window (cap 3, rolling one second): MEETS SPEC

Evidence: FLASH_CAP is 3 (fx_gd.txt:29), matching Spec B (a5_effects_sheets_synthesis.md:118), fx_api_md.txt:128, and W3C WCAG 2.3.1 / 2.3.2 (Three Flashes, Level AAA, which removes the screen-area exception and caps flashes at 3 in any 1.0 s period). In flash_ok(T) (fx_gd.txt:318-325), the code counts recorded timestamps f in _flashes where absf(f - T) < 1.0 and refuses the flash when near >= FLASH_CAP. Because _shot pre-schedules future impact times ti = tf + dist / spd during volley() (fx_weapons_gd.txt:109, 134, 259, 608), absf(f - T) < 1.0 checks 1.0 s on both sides of T ((T - 1.0, T + 1.0)), which is conservative: it never permits more than 3 recorded flashes in any rolling 1.0-second window, though pre-scheduled future impacts up to 1.0 s ahead can block an earlier flash.

Player cost: The 3-per-second cap holds for all gated callers, with minor over-throttling when a fast or close impact (or muzzle flash) is evaluated after a slower shot's future impact timestamp (ti up to 1.0 s later) has already been recorded in _flashes.

3. The merge window (0.12 s vs 0.33 s): MISSES SPEC

Evidence: Spec B (a5_effects_sheets_synthesis.md:118) requires merging concurrent flashes inside the same 0.33 s window into one counted event, and the comment directly above flash_ok (fx_gd.txt:314) reads # Flashes inside 0.33 s of a counted one merge into it (free). However, const FLASH_WINDOW := 0.12 (fx_gd.txt:28, checked via if absf(f - T) < FLASH_WINDOW: return true at fx_gd.txt:319-320) and fx_api_md.txt:128 both use 0.12 s. Weighing the three positions from the specs and the code:

Spec B's per-effect rule (a5_effects_sheets_synthesis.md:118) states that "battery muzzle and impact flashes count per shell, merged per salvo," and the comment on fx_gd.txt:28 states # flashes this close are one event (a salvo landing together).

In fx_weapons_gd.txt, salvo shots are staggered by i * 0.08 s for macro (4 shots spanning 0.24 s, fx_weapons_gd.txt:55, 154), i * 0.12 s for las (fx_weapons_gd.txt:169), i * 0.16 s for plasma (fx_weapons_gd.txt:174), i * 0.18 s for gauss (fx_weapons_gd.txt:245), i * 0.22 s for auto (fx_weapons_gd.txt:161), and j * 0.12 + randf() * 0.05 s for Corsair shield_break (fx_ship_gd.txt:421).

Because flash_ok does not append merged timestamps to _flashes (fx_gd.txt:319-320), a 0.12 s window only merges shots within 0.12 s of a recorded anchor. In a 4-shot macro salvo (0.00, 0.08, 0.16, 0.24 s), shot 0 (0.00 s) counts, shot 1 (0.08 s) merges, shot 2 (0.16 s) is 0.16 s > 0.12 s from shot 0 and counts as a second flash, and shot 3 (0.24 s) merges with shot 2; for plasma (0.16 s) and gauss (0.18 s), zero shots merge. Under Spec B's 0.33 s window (matching fx_gd.txt:314), all 4 macro shells (0.24 s span) and both plasma bolts (0.16 s span) merge into 1 salvo event as designed, though flash_ok should also guard against permitting more than 1 merged free flash per sub-window if it wants to avoid 3 Hz flash trains.

Player cost: With FLASH_WINDOW set to 0.12 s, a single 4-shot macro battery salvo consumes 2 flash slots and a 3-shot gauss salvo consumes all 3 slots, causing later shells in the same volley to lose their impact flash.

4. Coverage (which bright emitters the budget does and does not gate): PARTIAL

Evidence:

Gated by flash_ok or pop: Generic shell/plasma hull impacts (fx_weapons_gd.txt:608), non-flak shield impacts (fx_weapons_gd.txt:668), shield_break (fx_ship_gd.txt:404, 423), gauss muzzle (fx_weapons_gd.txt:293) and hull impact (fx_weapons_gd.txt:757), beam initial white bloom (fx_weapons_gd.txt:702), torpedo/rocket/star/ram _big_hit (fx_weapons_gd.txt:797), intercepted torpedo airburst (fx_weapons_gd.txt:395), _crit (fx_weapons_gd.txt:826), flak airburst core (fx_weapons_gd.txt:536), section stage-up bursts (fx_ship_gd.txt:720, 769), craft death (fx_death_gd.txt:631-642), and the first blast sprite of ship death (fx_death_gd.txt:679-682).

Ungated bright emitters (MISSES SPEC against a5_effects_sheets_synthesis.md:118):

Battery and flak muzzle flashes: _muzzle_blast (fx_weapons_gd.txt:316-327, called by macro and scatter) emits a kind 0 flash sprite at intensity 11.0 checking only if not fx.reduce_flashing:, bypassing flash_ok. auto (intensity 6.0, 12 bursts per 3-shot salvo, fx_weapons_gd.txt:165), las (intensity 7.0, fx_weapons_gd.txt:171), and flak (intensity 3.0, fx_weapons_gd.txt:524) also emit kind 0 muzzle flashes directly without flash_ok, violating Spec B's rule that battery muzzle flashes count.

Beam flares and contact sprites: Beam charge flares (intensity 9.0, kind 12, fx_weapons_gd.txt:202), firing flares (intensity 7.0, kind 13, fx_weapons_gd.txt:208), beam ribbons (intensity 2.4, fx_weapons_gd.txt:209), and _beam_burn's contact sprite (intensity 9.0, kind 13, fx_weapons_gd.txt:701, emitted unconditionally right before if fx.flash_ok(T): on line 702) are ungated.

Torpedo secondary blasts and fireball: _big_hit unconditionally spawns an intensity 7.0 kind 2 sprite (fx_weapons_gd.txt:798), an ungated sympathetic pop 0.3 s later (intensity 5.0, kind 2, fx_weapons_gd.txt:800), and DEATH.fireball (fx_weapons_gd.txt:801, fx_death_gd.txt:226-250), violating Spec B's rule that a torpedo impact is 1 flash regardless of weight.

Event lights (fx.light): Pooled OmniLight3D nodes (_lev, up to 64 lights, fx_gd.txt:145, 349-410) with peaks up to 14.0 (fx_weapons_gd.txt:818), 8.0 (fx_weapons_gd.txt:833, fx_ship_gd.txt:776), and 7.0 (fx_weapons_gd.txt:158, 787) never check flash_ok.

Death cook-offs and flame train: Only the first final blast sprite is gated (fx_death_gd.txt:679-682), leaving the rolling flame sprite train (fx_death_gd.txt:684-690) ungated.

Player cost: Even when flash_log records at most 3 flashes per second, the screen can flash well over 3 times per second from ungated battery muzzles (intensity 6.0 to 11.0), double-flashing torpedo hits (T and T + 0.3 s), unconditional intensity 9.0 beam contact sprites, and 14.0-peak event lights.

5. Over-budget behaviour: PARTIAL

Evidence: Spec B (a5_effects_sheets_synthesis.md:118) specifies that over-budget flak bursts render as smoke and sparks without the bright core pop, and fx_api_md.txt:128 claims over-budget flashes draw as smoke and sparks without the bright core. In _flak (fx_weapons_gd.txt:536-544), when flash_ok(t_b) is false, the intensity 5.0 kind 0 core sprite is skipped while the 10 shrapnel streaks, hanging smoke ball (kind 3), and a secondary intensity 2.5 kind 2 puff remain. For pop() callers (fx_gd.txt:338-344), refusing a flash draws the reduce-mode replacement: a longer, dimmer kind 18 soft glow (intensity minf(i, 3.0) * 0.4 <= 1.2, life maxf(life * 3.0, 0.4)) plus an expanding kind 2 ring (intensity 1.2, life 0.5). However, every impact function that calls fx.pop() also calls fx.light(..., peak, ..., 0) unconditionally (fx_weapons_gd.txt:627, 689, 787, 818, 833, fx_ship_gd.txt:405, 776), and fx.light() only attenuates when reduce_flashing is true (fx_gd.txt:350-352), not when flash_ok(T) returns false.

Player cost: Over-budget flak bursts and sprite pops step down cleanly, but over-budget hull and shield impacts still fire unattenuated OmniLight3D flashes (peak 6.0 to 14.0) onto the ship geometry.

6. Reduce-flashing mode: PARTIAL

Evidence: When reduce_flashing is set (fx_gd.txt:33-36), flash_ok(T) always returns false (fx_gd.txt:316-317, achieving 0 recorded flashes in flash_log), pop() swaps all gated flashes for the kind 18 gentle lift (<= 1.2 intensity) and kind 2 ring (fx_gd.txt:341-343), global shader uniform fx_calm becomes 1.0 to blend shader flicker to slow breathing (fx_shaders_gd.txt:38-40, fx_weapons_gd.txt:888), _muzzle_blast swaps its 11.0 core for a 1.5 soft bloom (fx_weapons_gd.txt:317-322), shape == 0 decay lights scale peak by 0.45 and life by 1.8 (fx_gd.txt:350-352), persistent _lsrc flicker slows to a 2.0 rad/s sine at 0.3 amplitude (fx_gd.txt:391-393), and trauma shake is halved (fx_gd.txt:453). However, several ungated emitters ignore reduce_flashing:

auto (intensity 6.0, 0.05 s, kind 0, 12 flashes per 3-shot salvo at fx_weapons_gd.txt:165), las (intensity 7.0, 0.06 s, kind 0, fx_weapons_gd.txt:171), and flak (intensity 3.0, 0.04 s, kind 0, fx_weapons_gd.txt:524) muzzle flashes emit raw kind 0 flash sprites with no reduce_flashing check.

Beam kind 12 charge (intensity 9.0, fx_weapons_gd.txt:202) and kind 13 firing/contact sprites (intensity 7.0 and 9.0, fx_weapons_gd.txt:208, 701), _big_hit's intensity 7.0 and 5.0 two-stage kind 2 pops (fx_weapons_gd.txt:798, 800), and jump_out's intensity 6.0 nozzle sprites and 10.0 streak (fx_ship_gd.txt:854-857) do not check reduce_flashing.

Event lights with shape == 1 (sustain) are not attenuated at fx_gd.txt:350 and still modulate intensity by 0.88 + 0.12 * sin(now * 50.0) (~8 Hz flicker) at fx_gd.txt:372.

Player cost: Although flash_log records 0 counted flashes, a player using reduce_flashing for photosensitivity or comfort still sees rapid kind 0 muzzle flashes from auto, las, and flak turrets, uncalmed two-stage kind 2 bursts on torpedo impacts, and 8 Hz flicker on shape == 1 sustain lights.

C. The Two-Tier Read

1. Distance Tier Verdict: PARTIAL

Evidence: Spec A's one-second distance test (damage_marks_reference.md:11, 39-44) asks for (a) how hurt a ship is, (b) which section is worst, and (c) roughly what has been hitting it, under a ration of at most 2 glowing marks and 1 particle emitter per ship (damage_marks_reference.md:41) and facing honesty (damage_marks_reference.md:44).

How hurt and which section is worst: Clearly readable via the 5-stage ladder in sync() and _build_section() (fx_ship_gd.txt:457-487, 643-730), where each section progresses through stage 1 (>60% HP: scorch L * 0.115, smoke wisps), stage 2 (>40% HP: dent L * 0.05, scorch L * 0.18, spark emitter, gas jet), stage 3 (>20% HP: cut hole L * 0.03 with peeled plates, scorch L * 0.245 at 0.3 emission, 2 spark emitters, tumbling debris, engine sputter at stage[0] >= 3 on fx_ship_gd.txt:515-519), and stage 4 (<=20% HP or broken: breach L * 0.046, buckled panel anchor "d", upper-edge bite anchor "b", interior fire, streaming debris, 2.3 s spark showers, 3.7 s internal pops at fx_ship_gd.txt:574-586, 735-778).

What has been hitting it: Fails once transient impacts end. Every weapon family except gauss and bio leaves either the same generic scorch decal (add_hit_scorch, fx_ship_gd.txt:816-826) or no mark (light weapons and flak), and gauss lacks its distance-tier pale stress ring/collar (fx_weapons_gd.txt:780-786). Stage-4 upper-edge silhouette bites (anchor "b", fx_ship_gd.txt:580-585) trigger from any HP loss rather than being reserved for ram and torpedo (damage_marks_reference.md:16).

Glow ration and facing honesty: A damaged ship can carry up to 10 glowing hit decals (emission 0.7, fx_ship_gd.txt:821, fx_death_gd.txt:141), up to 4 stage scorch decals per section (fx_ship_gd.txt:667-672), and 3 batched particle emitters per damaged section (fx_sec_sprites, fx_sec_sparks, fx_sec_debris at fx_ship_gd.txt:714-716) plus breach and burning emitters (fx_ship_gd.txt:735-813), far exceeding Spec A's cap of 2 glowing marks and 1 emitter per ship. Stage geometry sits at pre-picked random anchors (_anchor, fx_ship_gd.txt:537-552) biased upward rather than where shots landed.

Player cost: At fleet distance, the player can read overall ship health and the worst-hit third at a glance, but cannot tell which weapon families caused the damage, sees stage holes open on the top of the hull even when struck from below or abeam, and gets heavy particle/glow clutter on multi-stage damaged ships.

2. Zoom Tier Verdict: PARTIAL

Evidence: On zoom, stage 2 to 4 worker-thread mesh cutting (fx_ship_gd.txt:589-640, fx_breach_gd.txt:2-13, 735-820) cuts real dents and holes with peeled metal petals (SH.PETAL) and 3D breach interiors (SH.HOLE) featuring ribs, conduits, fire, gas, sparks, and crack emission overlays (fx_death_gd.txt:131-151). For persistent weapon marks at hit points, DEATH.hole_decal (fx_death_gd.txt:154-173, fx_shaders_gd.txt:746-800) provides parallax occlusion cavities (#define POM on "max" quality, fx_gd.txt:545) for gauss (entry 0.6 * k and raycast exit 0.9 * k, fx_weapons_gd.txt:766-786) and bio (green corrosion tint, fx_weapons_gd.txt:747-751, fx_shaders_gd.txt:788, 814, 818). However, the other 7 weapon mark families (battery, plasma, lance, ion, torp, flak, ram, boarding) lack their spec zoom geometry and shaders (damage_marks_reference.md:26-35), falling back to the 3 generic scorch textures, the bio hole (tendril/spores), or nothing (flak/light).

Player cost: Zooming in rewards the player with deep 3D breach interiors and parallax gauss/bio holes, but close inspection of lance, ion, plasma, torpedo, flak, ram, or boarding hits reveals only generic flat scorch textures (or acid holes for boarding).

3. Hull Sections Note (3 implemented vs 4 to 8 in Spec A)

Evidence: fx_hull_gd.txt:8-10, 92-94 and fx_ship_gd.txt:45, 462 divide every hull into 3 lengthwise thirds (eng, mid, prow), whereas Spec A (damage_marks_reference.md:13, 62) assumed 4 to 8 sections per ship with 3 signature marks per section.

Impact: Because each of the 3 sections spans the full width and height of a third of the ship and picks only one main anchor "a" (fx_ship_gd.txt:537-552), stage-ladder holes cannot distinguish port from starboard hits. At the same time, the 10-decal ship cap (fx_ship_gd.txt:821) would match a 3-section hull (3 * 3 = 9 signature marks) if it were partitioned per section and excluded battery scorches, but because it is pooled ship-wide and fed by battery hits, sustained fire on one section evicts signature marks on the other two sections.

Ranked Fixes

Gate all remaining bright emitters and reduce_flashing paths: Route _muzzle_blast (fx_weapons_gd.txt:317), auto/las/flak muzzle sprites (fx_weapons_gd.txt:165, 171, 524), beam charge/contact sprites (fx_weapons_gd.txt:202, 208, 701), and _big_hit's secondary kind 2 pops (fx_weapons_gd.txt:798, 800) through flash_ok(T) / reduce_flashing, attenuate fx.light() when flash_ok fails (fx_gd.txt:349-353), and calm the sin(now * 50.0) flicker on shape == 1 sustain lights under reduce_flashing (fx_gd.txt:372); repairs B.4, B.5, and B.6.

Align FLASH_WINDOW with Spec B and its own doc comment: Change FLASH_WINDOW from 0.12 to 0.33 in fx_gd.txt:28 (and update fx_api_md.txt:128) so salvo shells (0.08 s to 0.22 s spacing) merge per salvo as written at fx_gd.txt:314 and a5_effects_sheets_synthesis.md:118; repairs B.3.

Partition _hit_decals into a 3-per-section signature mark cap, grow repeat hits, and clear decals on repair: Replace the flat 10-decal array in fx_ship_gd.txt:52, 816-826 with per-section signature slots (eng, mid, prow), bake battery scorches into the section scorch decal (fx_ship_gd.txt:667) instead of _hit_decals, scale up existing section marks on repeat family hits, and clear section decals when sync() lowers a section's stage (fx_ship_gd.txt:507-520); repairs A.1, A.11, and C.1.

Implement turn-keyed (or age-keyed) fresh/cooling/scarred decay for hit and hole decals: Add birth timestamp t0 to DECAL and scorch decals in fx_shaders_gd.txt:743, 765-833 and fx_death_gd.txt:131-173 (and decay SH.HOLE at fx_shaders_gd.txt:874-876 all the way to 0.0 instead of 0.45 * heat), ideally stepped by turn ticks; repairs A.6, A.11, and C.1.

Add distinct persistent weapon mark shapes and shaders: Add a dragged slot decal for lance (fx_weapons_gd.txt:729), a branching Lichtenberg texture/shader for ion (fx_weapons_gd.txt:724-729), a pale stress ring/collar around gauss entry holes (fx_weapons_gd.txt:786), a stippled pockmark decal for flak (and remove spores from bio at fx_weapons_gd.txt:589), a blue-core splash decal for plasma (fx_weapons_gd.txt:622-635), and a patched airlock gash for tendril (fx_weapons_gd.txt:601, 747-751); repairs A.1, A.2, A.3, A.5, A.7, A.10, C.1, and C.2.

Tie silhouette bites and cold crumples to torpedo and ram impacts: Reserve anchor "b" silhouette edge bites (fx_ship_gd.txt:580-585) and impact-point BREACH.hole/BREACH.dent cuts for torp and ram hits (at tg["lp"] on both target and attacker bow for ram, suppressing the fireball in fx_weapons_gd.txt:606, 793-821); repairs A.4, A.9, and C.1.

Enforce the per-ship glow and emitter ration at fleet distance: Cap active persistent particle batches and glowing decals per ship in fx_ship_gd.txt:667-716 to Spec A's limit of 2 glowing marks and 1 emitter at fleet distance (damage_marks_reference.md:41); repairs C.1.

Weight flash_ok by intensity/scale and fix bombs/sporeb squadron decal sizing: Ignore low-intensity dim sparks/pops below the contrast threshold in fx_gd.txt:315-344 and put squadron bombs and sporeb in the pinhole/no-decal impact path (fx_weapons_gd.txt:589-590); repairs B.1 and A.8.

UNSURE List

Files cited via the chair's evidence pack: Only leg_prompt_fx.md, evidence_pack_fx.md, fx_gd.txt, fx_weapons_gd.txt, and fx_ship_gd.txt were attached as full text in this chat message; fx_shaders_gd.txt, fx_hull_gd.txt, fx_breach_gd.txt, fx_death_gd.txt, fx_pool_gd.txt, damage_marks_reference.md, a5_effects_sheets_synthesis.md, and fx_api_md.txt were not attached as separate files, so any code details in those files beyond evidence_pack_fx.md cannot be independently verified.

External callers of set_stages: UNSURE whether rules or UI code outside godot/fx ever calls set_stages (fx_ship_gd.txt:503-504) to drive damage stages directly outside sync().

External updates to hole_decal heat uniform: UNSURE whether any script outside godot/fx updates a hole decal's heat shader parameter after creation.

Screen-space pixel sizes at default tactical camera zoom: UNSURE how large 0.6 * k to 2.6 * k decals and stage cuts measure in screen pixels at the default fleet camera distance, since camera setup lives outside godot/fx.

Flash budget test suite contents: UNSURE what assertions godot/fx/test runs against flash_log (fx_gd.txt:72), as that directory is not in the attachments.

Boarding visuals outside godot/fx: UNSURE whether the rules or UI layer renders boarding socket markers, live venting, or patch plates outside godot/fx.

Visual read of DECAL shader ember noise: UNSURE whether the scene_t ember noise animation in fx_shaders_gd.txt:792, 803 visually reads as bio corrosion spreading in motion.

Overall Verdict

Overall Verdict: PARTIAL. The implementation builds a solid technical foundation with real worker-thread hull mesh cutting (fx_ship_gd.txt:589-640), parallax cavity shaders for gauss and bio hits (fx_weapons_gd.txt:747-786), clean shield-only hit gating (fx_weapons_gd.txt:591-593), and a central flash_ok / reduce_flashing hub (fx_gd.txt:315-344). However, it misses key commitments of both specs: persistent weapon identity collapses because 7 of 9 weapon families leave generic scorch decals (or nothing) while structural craters and silhouette bites are driven by HP thresholds at random section anchors rather than torpedo or ram hits, and the flash budget is bypassed by ungated battery/auto/las/flak muzzle flashes, unattenuated event lights, two-stage torpedo pops, and a 0.12 s merge constant that contradicts Spec B's 0.33 s rule and its own line 314 comment.
