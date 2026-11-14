# Shield design for issues 371 and 372: a hull-hugging skin with depth

Issue 697 [muse] design pack, chaired by Rey. Council: blind Rey leg first, then DeepSeek, Qwen and Flash design legs; Grok's seat was empty (grok.com bot wall, ninth consecutive muse job). Every leg independently recommended the same resting state, Rim and Gap. Where the legs' numbers differed, this design picks one value and says so; the Board builds from this file. Ryan's resting-state pick is still his to make (the pack recommends Rim and Gap; Face Flash and Veil Then Local are written up in section 3 with why the council rejected them). The build also waits on issue 363's contract shield surface and issue 209 round 7, per issue 371.

What this replaces: today's shield is one ellipsoid bubble per shielded ship (godot/fx/fx_shaders.gd, the SHIELD shader), and fx_ship.gd sums the four facings into one number, so no facing can read, flicker, or break on its own. That sum is the core defect this design removes.

## 1. The surface (issue 371: the model)

One shield surface per shielded ship, built from the ship's own hull shape pushed out a little, carrying all four facings as data on the one surface.

- Recipe ships: the recipe exports the shield surface with the hull: the hull render mesh offset along smoothed vertex normals.
- The 36 legacy hulls: the same surface generated at load from the hull render mesh. Stated plainly, per the brief: all 36 old hulls use a surface made at load from the hull mesh, not the old bubble.
- Offset: offset = clamp(0.05 x half-beam, 0.15, 0.50) world units along the normal; stations may go to 0.80. The bench tunes this once per class at camera 26: the gap between shield and hull must be visible at 26 and must not read as a separate shell at 170. (Legs differed: DeepSeek gave per-class clamps, Qwen a flat 0.6, Flash per-class absolutes. The chair's rule scales with the hull, which is what makes one rule cover a frigate and a carrier.)
- Fallback: if generation fails for a hull (non-manifold mesh, no usable normals, or more than 20k shield vertices after offset), that hull keeps today's ellipsoid bubble scaled as today, with the same facing weights painted into it, and the failure is logged per hull. The fallback is a logged exception, never the silent default.
- Eclipse ships (Chorus, Deathless) have no shields: no surface, no draw. Strike craft stay unshielded, as today.

Facing paint (how the four sides live on one surface):

- For each vertex, score its direction from hull centre against the four facing axes the rules already use. Keep the top two scores. If the second score is at least 0.30 of the first, write both weights (normalised to sum to 1) into the vertex colour; otherwise write 1.0 to the primary facing. This gives a soft border band of about 12 degrees between facings, with no hard quadrant line drawn anywhere.
- The weights are static geometry data, baked once. The four facing STRENGTHS are dynamic and reach the shader as one per-instance vec4 uniform, updated by fx_ship.gd from the real battle state each frame; a second per-instance vec4 carries the four break latches (section 5). (Flash's leg instead rewrote the vertex colours with strengths every frame; the chair rejects that, it re-uploads the vertex buffer per ship per frame for no benefit.)
- A hit near a border: the primary facing is the larger interpolated weight at the hit point; the ripple and pattern may blend up to 50 percent into the neighbour; a break opens only the primary facing.

## 2. What the player sees at rest (the resting state)

Recommended resting state: Rim and Gap.

- At rest, no fill, no whole-surface pattern, no whole-surface glow. Each up facing shows only a faint rim in the faction edge colour at the silhouette, additive scale about 0.12.
- A downed facing shows no rim and no contact glow on its side: a dark gap in the outline. The gap must span at least 18 percent of the visible hull edge on that side at camera 170, with at least 3:1 contrast against a live rim.
- On hover, selection, or zoom: the rim rises to about 0.30 and the contact glow (section 4) appears. Still no fill.
- After a hit: the local hit effects (section 4) play on the struck facing and fade; the rim near the hit stays up about 1.2 s, then settles.
- This keeps the effects playbook's standing line (R163): shields invisible at rest in the sense that nothing covers the ship; the faint rim is the minimum that lets a downed side read at the battle camera, which issue 371's done test demands (Ryan names the open side from the 170 strip). Qwen's leg argued for zero rim at rest with the rim only on hover; the chair does not take it, because the 371 strip is read at rest, not on hover. The tension is real and it is Ryan's pick to settle.

## 3. The rejected resting states

- Face Flash (a whole facing flashes whenever its strength changes): rejected by all four legs. It lights facings outside hits, strobes across a fleet in a volley, hides hull detail at 170, and draws the eye to pattern instead of to the gap.
- Veil Then Local (a whole-shield veil on any hit, localising after): rejected by all four legs. It recreates the exact defect being fixed (the whole bubble responding to a local event), costs a full-surface draw per hit ship, and covers the gap it should reveal.

## 4. A hit (issue 372: the look)

- Where it lands: the battle event's hit position and normal, projected to the nearest point on the shield surface. Up to 6 active hits per ship (the current shader's count). Per hit the shader gets: object-space position, object-space normal, start time, primary facing, impact strength, seed.
- Pattern near the hit only: the faction pattern mask is sampled only inside a radial falloff around the hit: core radius 0.06 and outer radius 0.28 of the hull bounding radius, smoothstep falloff, peak at the centre. The pattern never appears on the whole surface.
- Ripple: 3 rings from the hit point, speed 0.55 hull radii per second, spacing 0.08, thickness 0.02, fading over 0.55 s.
- Background bend: inside the hit mask only, the background bends at the ripple. Mechanism: the shield's refraction pass samples the screen texture with a UV offset driven by the ripple gradient: maximum offset 0.010 UV at the core, 0.004 at the outer ring, alpha cap 0.45, active 0.35 s. The pass runs only while a ship has an active hit. If the bench shows the cost over target, the fallback is Qwen's structure (all ships write bend offsets into one half-resolution target, one full-screen composite samples it); the magnitudes stay as stated.
- Contact glow: where the shield surface passes close to the hull or a rock, a depth fade glows in the faction edge colour: fade width 0.35 world units (frigates, cruisers), 0.45 (carriers), 0.50 (stations); cap 0.30 additive.
- Shield-hit splash: a dedicated energy crackle, never the hull smoke puff. Six jagged arcs drawn on the surface in the hit's tangent plane, length 0.08 to 0.18 hull radii, white-hot faction core, lifetime 0.18 s, no smoke, no grey. Hull hits keep the existing puff; the shield-hit path must not call the hull-hit spawner.
- Brightness caps (additive, linear, before tonemap; faction colour multiplies before the clamp): hit core 0.55; ripple field 0.30; rim 0.35; contact glow 0.30; total shield contribution clamped to 0.65.
- Bench measure for the cap: render the same ship shield-off and shield-lit at cameras 170, 60 and 26 at 1080p; sample 12 points inside the hull silhouette and 8 silhouette edge pairs. Pass if edge contrast is at least 1.25:1 and at least 9 of the 12 interior samples keep at least 30 percent of their unshielded local contrast. If it fails, lower the total cap by 0.05 and retest. The final cap is recorded on the bench.

## 5. Strength language, break, and regen

Per facing, strength s from the real battle state (0 to 1, reached by play, never typed):

- Steady, s >= 0.60: rim and contact glow scale with strength; no flicker. Hits ripple normally.
- Flickering, 0.10 < s < 0.60 (and see the latch rule below): only that facing's rim and contact glow modulate. Amplitude 0.25 x (0.60 - s) / 0.50; frequency 3 + 3 x (0.60 - s) / 0.50 Hz, capped at 6 Hz. Phase is offset per ship (ship_id x 0.37) and per facing (facing_index x 1.57), so no two facings peak together. Hit cores never flicker.
- Fading, latch closed and s <= 0.25: rim and pattern alpha scale by s / 0.25 toward zero, with a faint 0.03 residue so "nearly down" reads differently from "broken".
- Down, s <= 0.10: the break latch opens. Rim, contact glow and pattern off on that facing; the gap stays open until s >= 0.25. While the latch is open the facing shows nothing, whatever the flicker band says.
- Anti-strobe: if more than 6 shielded ships are visible, flicker amplitude halves and frequency caps at 3 Hz; if more than 12 are visible, flicker is replaced by a steady rim at 0.35 scale. Below 30 fps, flicker drops to 3.5 Hz or off (Qwen's aliasing note).

A break:

- Starts at the last hit point on that facing (or the facing centre if none) and expands across the facing over 0.35 s, playing the faction's break behaviour (section 6) along the front, with a residue crackle along the front for 0.30 s capped at 0.30. Faction debris rides the front: small shards or cells (section 6), pooled per ship, gone within 0.6 s. No physical debris field.
- A scorch tint (0.15 alpha, dark, not additive) marks the gap region for 3.0 s after the break, a positive dark mark so the gap reads even on a dark hull (Qwen's addition; if dark hulls still fail the 170 read, add a faint 0.05 border at the gap edge and re-bench).
- Only the struck facing opens. The other three keep their own states. There is no whole-shield break animation (today's 1.45 s whole-bubble break goes away).
- Regen: at s >= 0.25 the latch clears and the gap closes over 0.45 s from the facing borders toward the centre, with a bright seam capped at 0.35 and the facing shown flickering while it closes; the scorch tint fades as it closes. If s falls to 0.10 or below again, a new break opens.

## 6. Per faction

One mechanism for all four shielded factions; identity lives in colour, pattern mask, break behaviour, and edge mode. Colours and edge modes are read from godot/fx/faction_looks.json at build time, never copied into the shader as literals (the values below are the current record, for the bench sheets).

- Voidsworn, gold (1.0, 0.5, 0.18), style 0: ridged fbm crackle veins (3 octaves, threshold 0.62 for thin veins, per-ship seed from ship id so no two ships crackle identically). Edge pale blue-white (0.82, 0.92, 1.0). Break: veil sheets peel.
- Hegemony, steel blue (0.38, 0.68, 1.0), style 1: hex lattice, hard geometric cell edges; on a hit the cells nearest the impact brighten and their edges thicken 1.5x for 0.15 s. Break: hex cells pop.
- Corsair (Hullbreakers), salvage red (0.85, 0.16, 0.1), style 2: patchy flicker blobs (value noise, per-blob phase). Faction character: the Corsair shield never looks fully settled even at steady strength (flicker amplitude 0.15 at steady, 0.45 when flickering); it reads jury-rigged by design. Break: patches sputter.
- Ithar, pale ice (0.82, 0.9, 1.0), style 3: smooth prismatic gradient (simplex, continuous, hue shift about +/- 15 degrees). Edge mode "rainbow": on hover the rim cycles hue over 3.0 s, the only animated rim. Break: the veil sheets away in one smooth piece.
- Chorus and Deathless: shielded false. No surface, no shader, no draw.

## 7. Shader approach in plain steps (Godot 4.7)

Passes:

- Base pass, always drawn for a shielded ship: transparent, unshaded, blend_add, no depth write. Carries rim, contact glow, hit core, ripple field, and crackle.
- Refraction pass, drawn only while the ship has an active hit: blend_mix, samples the screen texture, lower render priority than the base pass. One screen copy per frame while any hit is active, not one per hit.

Steps, base pass:

1. Vertex stage: pass object position, world normal, and the vertex-colour facing weights to the fragment stage.
2. Fragment stage: read the per-instance facing-strength vec4 and break-latch vec4 (set by fx_ship.gd from the battle state). Local strength = dot(facing weights, facing strengths). If the latch for the dominant facing is open, output nothing for this fragment's facing share (the gap).
3. Fresnel rim: pow(1.0 - abs(dot(normal, view)), 3.0) x rim scale (0.12 at rest, 0.30 on hover/selection/zoom, raised locally about 1.2 s after a hit) x local strength x edge colour.
4. Contact glow: read the depth texture, linearise scene depth and fragment depth; contact = 1.0 - smoothstep(0.0, contact width, abs difference); multiply by edge colour, cap 0.30.
5. Strength language: apply the section 5 bands to the rim and contact terms (steady scale, flicker modulation with per-ship and per-facing phase, fading scale, latch discard). Never modulate hit cores.
6. Hits: loop the 6 hit slots. For each active hit, compute the tangent-plane distance from the fragment to the hit point; inside the outer radius, sample the faction pattern mask (the existing four noise styles, reused, not rewritten) and add the core term; add the 3 ripple rings; add the crackle arcs for the first 0.18 s. Multiply pattern terms by local facing strength, so a hit on a weak facing shows dimmer.
7. Clamp the fragment's total additive contribution to 0.65 and output.

Steps, refraction pass:

1. Same facing-weight and strength reads; fragments outside every active hit's outer radius output nothing.
2. For each active hit, accumulate the ripple gradient x falloff; UV offset = gradient direction x (0.010 at the core falling to 0.004 at the outer ring) x hit envelope (0.35 s).
3. Sample the screen texture at screen UV + offset; output with alpha min(0.45, bend mask).

Data in: facing strengths (vec4, per frame), break latches (vec4, on change), hit arrays (position, normal, start time, facing, strength, seed; up to 6, set on hit events), hover/selection state and camera distance (for rim scale and degrade steps), faction style id and colours from faction_looks.

## 8. Cost (against the R116 gate: 12.5 ms scene frame; baselines R118: 6.0 ms frame median at 1080p, 5.45 ms GPU at 4K)

Targets, stated as added GPU cost:

- At rest, 20 shielded ships: 20 draws (one per ship), GPU <= 0.5 ms at 1080p and <= 0.8 ms at 4K; total frame median <= 6.5 ms at 1080p.
- 20 ships hit at once: 40 draws (base + refraction per hit ship), GPU <= 2.5 ms at 1080p and <= 3.5 ms at 4K; total frame <= 8.5 ms at 1080p and <= 9.0 ms at 4K. Inside the 12.5 ms gate with headroom in both cases.
- The bench reports the shield cost on its own (rest, and 20 ships hit at once) next to the whole-frame number, before and after against the R116 gate, per issue 372.

Degrade order if the budget is missed (in this order, and never the rim/gap read, which the 371 done test depends on):

1. Refraction pass off for ships beyond camera distance 60.
2. Active hits per ship 6 to 3.
3. Ripple rings 3 to 2.
4. One noise octave dropped from the faction masks.
5. Contact glow off beyond camera distance 60.

## 9. Bench and proof

- Bench strips for two factions, Voidsworn and Hegemony (the most distinct pair: organic crackle against geometric hex), at cameras 170, 60 and 26. Each strip shows: at rest (one facing down in one frame), a hit landing, a break, and a regen close. At 170 add two stress frames: two facings down, and a 20-ship volley frame for the strobe and brightness read.
- At 170 the strips must show: no whole-surface fill; pattern and ripple only near the hit; exactly one facing open after a break; the faction pattern readable near the hit; the background visibly bent at the ripple; contact glow where shield meets hull or rock; the ship visible through the lit shield at the stated caps; the shield-hit crackle visibly different from the hull smoke puff (show a side-by-side frame).
- The readability test that approves the resting state: 1080p, camera 170, 10 shuffled unlabelled stills of one ship at rest with one facing down. Ryan names the open side at least 9 times out of 10, from the gap alone. If he scores less, first raise the scorch tint (0.15 to 0.25) and widen the border blend (12 to 15 degrees) and retest once; if it still fails, the resting state goes back to the council.
- Cost report on the bench before and after, per section 8, is part of both issues' done tests (371's gate cost report; 372's cost before and after against R116).

## 10. What this design does not decide

- Ryan's resting-state pick (section 2 recommends Rim and Gap; sections 3 records the alternatives). The build starts from the state Ryan picks.
- Issue 363's contract shield surface and issue 209 round 7: if they change the surface contract or the facing data format, sections 1 and 7 are revised before building.
- The exact facing axis source: the builder reads the four facing axes and the battle-state field names from the rules code, the same source fx_ship.gd will write from; the drawn weights and the rules must come from that one source or border hits will disagree with the rules (the council's top risk).
- Audio hooks for hits and breaks: out of scope here; the break and hit events are the hook points.

Council record: blind Rey leg, DeepSeek leg, Qwen leg and Flash leg all landed on Rim and Gap, a hull-offset surface for recipe and legacy hulls alike, per-facing data on one surface, local hits, and a stated brightness cap. Differences the chair settled: the offset rule (section 1), strengths as uniforms rather than rewritten vertex colours (section 1, against Flash), the always-on faint rim over Qwen's hover-only rim (section 2), the additive cap scale 0.65 total (section 4, against Flash's multiplier caps and Qwen's alpha clamp under mix blending; the current shader is blend_add and the faction colours are tuned for it), the primary refraction mechanism (section 4, DeepSeek's in-shader pass with Qwen's composite as the costed fallback), and the deciding readability test (section 9, DeepSeek's 10-still form). Grok's seat was empty (bot wall). Full leg texts are held by the chair.
