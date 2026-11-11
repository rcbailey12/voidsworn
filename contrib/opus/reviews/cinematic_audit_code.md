# Cinematic audit, code leg (issue 485)

Opus 5.5 worker, Nov 11 2026. Read-only: no game code, tests or playbooks changed. Pinned to main at 5eee5ea.
Read: docs/playbooks/effects.md, deaths_and_hits.md, sound.md; FINDINGS R49, R50, R55, R73, R76, R88, R122, R123, R131,
R158, R163, R170, R171, R186; godot/fx/ (fx.gd, fx_weapons.gd, fx_ship.gd, fx_death.gd, fx_breach.gd, API.md), godot/audio/
(sfx.gd, death_audio.gd, cues.json, clips/index.json), godot/music/music_player.gd, godot/scenes/battle/battle.gd,
godot/render/camera_rig.gd and ship_view.gd; captures in docs/shots/look_bench/. The wreck break itself (issue 484) is left out.

## Top five in one line each

1. The flash safety limit counts sprites 13 times smaller in area than the rule it comes from, so one capital death spends the whole budget and anything else dying beside it becomes a faint cream puff with no light.
2. The kill cut-in swings the camera away 1.6 s after a kill: before a cruiser's core flash lands and before a capital even breaks.
3. A dreadnought's main battery hits with the same 56 px puff as a frigate's gun; hit size follows the target, never the gun, and is held under the flash bar on purpose.
4. Sound plays one bang per volley, 0.2 s before the first muzzle flash, and every hull hit uses the same generic clip even though weapon-specific hit sounds are already in the game.
5. Every shot, chain blast and secondary explosion goes off on a metronome, at one size and one colour.

Next five: camera shake is under one pixel at the battle camera; light from every effect reaches the same 1.7 hexes; every big
death sounds identical and is cut short; the owner's slow-motion beat (R73) is never triggered; misses vanish in empty space.

---

## 1. The flash budget flattens every crowded moment, and it counts far more than its own standard asks

1. **What the player sees now.** One capital dying alone looks right. But when a torpedo lands or a second ship dies within
   about three seconds of it, those events come out as dim, slow, cream-coloured puffs with no light on the hulls around them.
   Two capitals dying together: the second one is a soft glow.
2. **What a film would do.** Every big blast in a fight reads as a blast. Where real safety demands fewer bright frames, it
   keeps the size, the colour and the fire, and trades only the white peak.
3. **Where the limit lives.**
   - godot/fx/fx.gd:23 `FLASH_CAP := 3` (counted flashes in any rolling second), :22 `FLASH_WINDOW := 0.12`.
   - godot/fx/fx.gd:25 `FLASH_SCREEN := 0.06`: anything at least 6% of the screen height (65 px at 1080) counts as a flash.
   - What a refused flash becomes: fx.gd:361-364 (kind 18 soft lift, brightness `min(i,3) * 0.4`, life stretched to at least
     0.4 s); fx_weapons.gd:1069-1104 (`_staged_hit`: soft torpedo flash intensity 1.25 instead of 5.2); fx_death.gd:1402-1406
     (`_blast`); fx_death.gd:1779-1790 (`_core_flash`).
   - A refused flash also kills every light near it, whatever its size: fx.gd:489-497 (`for f in _refused: ... return`).
   - Death timings sized to the cap: fx_death.gd:52 capital chain `[0.5, 0.85, 1.2, 1.55, 1.9]` and core flash at 2.28. I
     walked the budget by hand: every trailing second from 1.2 s to 2.8 s holds exactly three counted flashes from that one
     death (chain blasts 84 px, core 423 px, first secondaries 78 px, all over 65 px). The 0.35 s spacing is the cap's
     arithmetic, not a look.
4. **Why it is there.** A real reason: WCAG 2.3.1 (photosensitive seizures). But the size bar is far stricter than WCAG's. W3C's
   own text: a flash only counts when "the combined area of flashes occurring concurrently" is more than ".006 steradians
   ... (25% of any 10 degree visual field)", estimated as a quarter of "a 341 x 256 pixel rectangle ... at 1024 x 768". At
   1080 lines that is about 43,000 px², a disc about 234 px across, roughly 22% of screen height. The game counts at 6% of
   height, about 3,300 px² for a disc: about 13 times less area. Chain blasts (80 to 84 px), secondaries (78 px) and torpedo
   hits (154 px) are all under the W3C area alone; only the death cores (302 and 423 px) are clearly over it. (Several small
   blasts at once do add up, which the rule must keep counting.)
5. **The loosening.** Keep FLASH_CAP at 3 and keep reduce flashing exactly as it is. Then:
   (a) raise the count bar from a fixed 6% of height to the W3C area: sum the screen area of every bright sprite inside one
   FLASH_WINDOW and count the group only when it passes about 22% of screen height as a disc (43,000 px² at 1080, scaled with
   resolution);
   (b) a refused flash keeps its size, its fire colour and its light; only the white peak is capped (e.g. peak brightness no
   higher than 1.5x the scene, a 0.1 s rise instead of 2 frames). Today it loses all three;
   (c) drop the "no light near a refused flash" rule (fx.gd:491-493): a hull lit orange for half a second is not a flash by
   the W3C test (it is not a pair of opposing changes over that area at that speed), and it is what makes a fight feel lit;
   (d) once (a) is in, retime the capital chain blasts off the cap's grid (see finding 5).
   Whether to go further for players who have not asked for reduce flashing is Ryan's call.
6. **Size.** Medium (two or three runs): the area sum in `flash_ok`, the soft path in four places, and the salvo flash test of
   issue 232 rerun as the safety proof. No frame cost to speak of; a few more lit sprites.
7. **Picture.** docs/shots/look_bench/deaths/capital_death_beats.jpg shows a lone death at full strength. The missing picture is
   a bench moment with two cruisers dying 0.5 s apart plus a torpedo hit: add it to godot/bench/look_moments.json and shoot
   before and after at camera 170.

## 2. The kill cut-in leaves before the death happens

1. **What the player sees now.** When a cruiser or bigger dies, the camera swings to a side-on, letterboxed view of the
   killer and the victim, then swings back after 1.6 s. A cruiser's core flash is at 1.66 s, so it plays while the camera is
   already leaving. A capital breaks at 2.0 s and flashes at 2.28 s, so the cut-in shows only the tell and returns for the
   real explosion.
2. **What a film would do.** Hold on the kill until the big flash and the first pieces separate, then let go.
3. **Where.** godot/scenes/battle/battle.gd:1967-1970 (`_cine_frame(by, id)` then `create_timer(1.6 * speed)` then
   `_cine_release`); the death beats in godot/fx/fx_death.gd:46-66 (cruiser break 1.38, core 1.66; capital break 2.0, core
   2.28). Default is on: battle.gd:134 `var cine := "key"`; kills qualify at battle.gd:1673-1674 (size 0.6 or bigger, or a
   flagship). The camera eases back at rate 7 a second (render/camera_rig.gd:182), so it is about two thirds of the way back
   0.15 s after release.
4. **Why.** Nothing chosen: the 1.6 s predates the three-beat deaths of issue 462 and nobody retimed it. Note the conflict:
   deaths_and_hits.md and R123 say "the camera is never taken from the player for a death", yet the shipped default takes it.
   One of the two needs Ryan's word.
5. **The loosening.** If cut-ins on kills stay (my pick: yes, for cruisers and up, it is the most film-like thing the game
   already has), release on the death's own clock: `gfx.death()` already returns the death's length; hold until core flash
   plus 0.6 s (about 2.3 s cruiser, 2.9 s capital), and let Enter or Space skip it as hurry does now. Start the cut-in a beat
   early for capitals so the tell is in frame.
6. **Size.** Small (one run). No frame cost; a capital kill holds the turn about 1.3 s longer.
7. **Picture.** Not on any bench strip (the bench has no cut-in). A two-frame capture of battle.gd's kill cut-in at 1.5 s and
   2.3 s after the killing blow would show it.

## 3. One hit size for every gun: the target decides, the gun does not

1. **What the player sees now.** A battleship's heavy battery and a frigate's light gun leave the same small cream puff on a
   hull. m5 shows a Sunward battleship's macro battery: the puff on a tomb-ark is the same size as on a frigate.
2. **What a film would do.** A dreadnought's broadside lands like a hammer and lights half the hull; a frigate's gun pecks.
3. **Where.**
   - godot/fx/fx_weapons.gd:1071-1072: macro and torpedo hits are sized by the target's class only
     (`{"small": 0.8, "cruiser": 1.0, "capital": 1.2}` times 56 px or 154 px). The shooter is not an input.
   - fx_weapons.gd:62-69: `HIT_PX := [0, 34, 46, 56]`, comment: "All stay under the 65 px ... so they never wait on the flash
     budget". `HULL_LIGHT := 7.9`, "just under the 8 that counts as a flash". `MUZ_PX := [0, 20, 26, 32]`.
   - The weight table is three steps for 26 weapons (fx_weapons.gd:39-43), and a dreadnought `hbattery` and a cruiser
     `battery` both draw the "macro" look.
4. **Why.** A checkability habit: the sizes were set to dodge the flash count (finding 1), not by eye. The 1.4x ladder in
   effects.md runs across weapon types (las, macro, lance, torpedo, death), never across hull size.
5. **The loosening.** Add the firing ship's class as a second size factor on hit flash, body, sparks and hull light: frigate
   0.8, cruiser 1.0, battleship 1.3, dreadnought and up 1.6 (start values for Ryan's eye). Let heavy hits from capitals pass
   65 px once finding 1's area rule is in. Give `hbattery` and `hturbo` their own heavier row (bigger muzzle, two-stage flash,
   a short shock ring on the plate).
6. **Size.** Small to medium (one or two runs, plus one bench strip).
7. **Picture.** docs/shots/look_bench/m5_one_weapon_every_weight.jpg (same gun on every size); the fix wants the mirror row:
   every size of shooter on one cruiser.

## 4. Gun sounds: one bang per volley, early, and generic hits

1. **What the player hears now.** A four-gun macro ripple sounds like one shot, and the bang comes about a fifth of a second
   before the first muzzle flash. Every hull hit, whether laser, plasma, rail slug, acid or glass needle, makes the same
   "hit" clip; the heavy version plays only on a critical. Every torpedo hit is the same medium boom.
2. **What a film would do.** You hear each gun in the ripple, roughly in time with its flash, and each weapon's impact sounds
   like what it is.
3. **Where.**
   - battle.gd:1786: `sfx.gun(...)` once per volley, at the moment `gfx.volley` is called; the muzzles fire at
     `T0 + 0.2 + i * 0.08` (fx_weapons.gd:212). Las at `T0 + 0.05 + i * 0.12` (233), plasma `+0.12 + i * 0.16` (240).
   - battle.gd:1796: `sfx.hit(_pos(t_id), h["crit"])`; godot/audio/sfx.gd:393-394 plays only "hit" or "hit_heavy".
   - godot/audio/cues.json has `hit_las`, `hit_plasma`, `hit_rail`, `hit_wet`, `hit_glass`, `hit_ion`, `patter_hull`,
     `patter_shield` with clips on disk (lasSear 3, plasmaHit 4, railHit 4, hitWet 4, hitGlass 4, ionZap 3 takes): none is
     played anywhere in the game (grep of godot/**/*.gd outside tests).
   - battle.gd:1773: every torpedo hit `sfx.boom(0.8, ...)`.
   - The salvo thinning (sfx.gd:219-226) and `salvo_tail` were built for one call per shot; with one call per volley the
     tail almost never fires.
4. **Why.** History: the G4 volley path replaced the stub path (battle.gd:1821-1827, which played a gun cue on every second
   shot) and kept one call. Nothing protects it.
5. **The loosening.** Return per-shot fire times from `fx.volley` next to `impacts` and play the gun cue per shot at those
   times (the gap and voice caps in cues.json already stop pile-ups). Map the hit cue from the weapon look: las and prism to
   hit_las, plasma to hit_plasma, gauss to hit_rail, spine and spores to hit_wet, needle to hit_glass, ion to hit_ion,
   heavy weight (3) to hit_heavy; patter for light guns on shields. Torpedo hits scale with the target (boom_m on a frigate,
   boom_l on a capital).
6. **Size.** Small (one run). No frame cost; a few more voices inside the existing 34-voice cap.
7. **Sound.** Any m1 moment (docs/shots/look_bench/m1_weapons_on_a_hull_a.jpg rows macro, plasma, autocannon) with audio
   recorded; the listening page of sound.md job 2 is the natural place.

## 5. Everything on a metronome, at one size and one colour

1. **What the player sees now.** A battery's shots leave at exactly even intervals, travel at the same speed in dead straight
   lines, and land in an even row. In a death, the chain blasts walk the tear at even steps, all 80 or 84 px, all the same
   orange; the ten secondaries go off in evenly spaced groups, every one 78 px, the same colour, placed by spreading them as
   far apart as possible and all facing up.
2. **What a film would do.** Ragged ripples, a late round, shots with slightly different speeds and a little drift; blasts that
   bunch up, one big one and several small, some going off on the far side and some throwing debris sideways.
3. **Where.**
   - Shot spacing: fx_weapons.gd:212 macro `i * 0.08` (fx.gd:49 `timing.ripple`), 233 las `i * 0.12`, 240 plasma `i * 0.16`,
     280 lance `i * 0.45`, 305 torpedo `i * 0.35`, 335 gauss `i * 0.2`. Only the Chorus spine has any jitter.
   - One shell speed: fx_weapons.gd:44 `SHELL_SPEED := 160.0`, straight `dir * spd` (216).
   - Chain blasts: fx_death.gd:52 and 62 (even times), 1357 (80 or 84 px, one colour).
   - Secondaries: fx_death.gd:1463 (evenly spaced `k / (groups - 1)` plus `j * 0.05`), 1469-1502 (farthest-point spread,
     upward faces only, line 1480), 1510 (78 px, one colour).
4. **Why.** Tidiness and the flash budget: the death comment (fx_death.gd:1447-1449) says groups go off 0.05 s apart "so a
   group counts as one flash". The even timings are the staging table's sample values, never meant as a grid.
5. **The loosening.** Jitter every shot interval by plus or minus 35% (seeded from the battle so replays match), shell speed
   by plus or minus 8%, aim by a small cone so a ripple's impacts scatter across the plate. Chain blasts: keep the order, jitter
   each time by plus or minus 0.12 s, sizes drawn from 60 to 140 px with one "big one" per death, colour drawn between deep
   orange and white-yellow. Secondaries: random times inside the window with clustering (two close, a gap, three close),
   sizes 50 to 160 px, sites anywhere on the piece's plating including the sides and underside, and two of the ten throwing a
   gas jet sideways. Re-check the death against the flash budget after finding 1.
6. **Size.** Medium (two runs: weapons, then deaths; 484 owns fx_death.gd today, so the death half waits for it). No frame
   cost.
7. **Picture.** docs/shots/look_bench/deaths/cruiser_death_beats.jpg and capital_death_beats.jpg (2.10 to 6.0 s frames);
   m1 macro row for the ripple.

## 6. Camera shake is invisible at the battle camera, and the zoom punch is faint

1. **What the player sees now.** Nothing moves the view when a capital dies or a torpedo lands. The shake is there in code but
   at the camera the game is played from it moves the picture by less than a pixel.
2. **What a film would do.** A heavy, low, short shove for a big hit, a longer rumble for a capital breaking, scaled down for
   far events but never to zero.
3. **Where.** godot/fx/fx.gd:625 trauma `+= amount / (1 + d / 120)`, :640 decay 2.4 a second, :642-647 offset
   `amp = 0.06 * trauma²` times 10 world units. Worked through for a capital break (fx_death.gd:1620, amount 0.45) at the
   battle camera (about 170 units away, 7.7 px a unit at 1080): trauma 0.19, offset 0.02 units, about 0.16 px. A torpedo hit
   (fx_weapons.gd:1120, amount 0.4): about 0.12 px. Even trauma 1.0 is 0.6 units, about 4.6 px. The shake is translation
   only, from fixed sine frequencies (fx.gd:646-647), so every shake is the same wobble. Punch: fx.gd:663 cap 6% of the field
   of view; the capital break asks 1.8% (fx_death.gd:1619), divided by `1 + d / 400` to about 1.3%.
4. **Why.** Comfort was the intent (shake has its own setting, battle.gd:1029 `shake_scale`, and halves under reduce
   flashing), but the squared trauma times the distance divide times the 0.06 amplitude stacked into nothing. No one measured
   it on screen.
5. **The loosening.** Keep the shake setting and the reduce flashing halving. Make trauma linear, not squared, for the big
   events; let distance divide by `1 + d / 400` instead of `/ 120`; add a small roll (0.3 to 0.6 degrees) and use noise
   instead of fixed sines. Targets for Ryan's eye at camera 170: torpedo hit about 3 px, cruiser death about 6 px, capital
   break about 10 px plus a 0.8 s low rumble, all easing out. Punch for a capital death to about 3%.
6. **Size.** Small (one run, plus a shake strip). No frame cost.
7. **Picture.** Not visible in stills; needs a short clip at camera 170 of the capital death moment (look bench m4 or
   deaths/capital_death_beats at 2.10 s).

## 7. Light reaches the same short distance for everything, and is gone in a blink

1. **What the player sees now.** A capital's core flash lights neighbours no further than a las muzzle flash does: under two
   hexes. The core light lasts a fifth of a second and is a cool blue-white whatever is burning. Torpedo hits light the struck
   hull only faintly (the after frames of w_torp_void_hull_battle.jpg show little light on the plating).
2. **What a film would do.** A big blast lights every hull in the area in its own fire colour, the light falling off as the
   fire cools; a capital lights the whole engagement for a moment.
3. **Where.** godot/fx/fx.gd:204-212: every event light has `omni_range = 30.0 * unit` (hexes are 17.3 units across,
   render/board.gd:10-11, so 1.7 hexes) and `light()` (489) takes no range. Core light: fx_death.gd:1790, life 0.20 or 0.22 s,
   peak 9, fixed `Color(0.65, 0.75, 0.91)`. Blasts: fx_death.gd:1406, 0.25 s, peak 5. Torpedo hull light: fx_weapons.gd:1119,
   0.35 s, peak `HULL_LIGHT` 7.9 (finding 3). deaths_and_hits.md asks for "about two hexes" (cruiser) and "about three hexes"
   (capital): 35 and 52 units, more than the pool can reach.
4. **Why.** Frame rate is the real reason for a pool (64 lights at max, fx.gd:204). The single range and the short life are
   convenience and the flash rule; the blue colour I cannot explain.
5. **The loosening.** Give `light()` a range argument: 25 units for hits, 45 for torpedoes and cruiser cores, 70 for capital
   cores. Split each big light into a short bright peak (inside the flash rule) and a long warm tail: the core light holds
   about 0.6 s in the fire's colour (orange to red) at a third of the peak. Light only, no fire, so the flame cap of the
   playbooks is untouched.
6. **Size.** Small (one run). Frame cost: wider omni lights in Godot's clustered renderer cost more per pixel lit; measure on
   the scene gate (R116, 12.5 ms budget). I expect a fraction of a millisecond with a handful of big lights, but this is not
   measured.
7. **Picture.** docs/shots/look_bench/rebake/w_torp_void_hull_battle.jpg (little light on the hull after the hit); a new bench
   moment with a capital death beside two parked cruisers would show the reach.

## 8. Every big death sounds exactly the same, and its sounds are cut short

1. **What the player hears now.** Each capital death plays the same five sounds in the same order with no pitch change, and
   several of them stop abruptly. With reduce flashing on, the deep bass of the core flash is removed.
2. **What a film would do.** Each death a little different (a groan here, a second rumble there); a big death with a long low
   tail that settles; under reduce flashing, the sound carries even more of the moment.
3. **Where.**
   - godot/audio/death_audio.gd:21-65: death_powerdown, death_vent, death_crack, bass_drop, wreck at fixed ages.
   - cues.json: `pj` (pitch jitter) is 0 on every death cue (death_powerdown, death_vent, death_crack, death_run, chunk_cool,
     hulk_vent) and on bass_drop; hard `duration` limits death_crack 0.4 s, death_vent 0.5 s, death_powerdown 0.6 s,
     death_run 0.72 s, with a 0.06 s fade (sfx.gd:268-274).
   - Single takes behind them (clips/index.json): whoosh 1, scrape 1, bassDrop 1, ionCharge 1, shieldBig 1, arc 1, launch 1.
     The one whoosh is used by six cues (torp, phase, death_powerdown, death_vent, hulk_vent, arrive_jump).
   - death_audio.gd:58 `if not fx.reduce_flashing:` skips the bass drop.
   - Reverb: sfx.gd:112-118, room 0.35, wet 0.2 to 0.3.
   - sound.md section 1 asks for "Short and dry. Short tails, little echo" and "at least four takes".
4. **Why.** Inherited from the browser cue table; the short durations keep stacked deaths from muddying. The reduce-flashing
   skip looks like an accident (sound is not light).
5. **The loosening.** Pitch jitter 4 to 6% on every death cue; at least four takes of whoosh, scrape, bassDrop and the crack
   (sound.md already wants this); lift the duration caps for cruiser and capital deaths and let a capital end on a 2 to 3 s
   low tail (keep "short and dry" for guns and hits, where Ryan's pick fits); keep the bass drop under reduce flashing.
6. **Size.** Small for the code (one run); the new takes ride on the sound redo's sourcing job (Muse, sound.md job 1).
7. **Sound.** Two capital deaths back to back from the bench (deaths/capital_death_beats moment) with audio recorded.

## 9. The owner's slow-motion beat for big kills never plays

1. **What the player sees now.** No slow motion on any kill. Ryan ruled a brief slow-motion beat for big ships and flagships
   (R73, Nov 1: "just do big ships and flagship for slow mo"); it is built but nothing in the game calls it.
2. **What a film would do.** Half a second of slowed time on the killing blow of a capital or flagship, sound dipping with it.
3. **Where.** godot/fx/fx.gd:586-588 `death_slowmo()` (0.35 speed for 0.48 s); API.md:135 describes it as live. The only
   callers are in godot/fx/test/destruction_staging_check.gd (165, 171, 173). Because it never runs, the audio duck in
   death_audio.gd:31 (`sfx.death_beat`, -6 dB on battle sound and music) never runs either.
4. **Why.** Lost in a rewrite (git history is squashed at 682d82b, so I cannot say when). Nothing protects its absence.
5. **The loosening.** Call `fx.death_slowmo()` from the cruiser and capital death path at the core flash (not the killing
   blow, so the slowed moment is the explosion), flagships included; keep `hurry_death` cancelling it. Ryan judges it in one
   clip, since R123 says punch and slow motion are "the only accents".
6. **Size.** Small (one run). No frame cost.
7. **Picture.** Needs a clip; the capital death moment on the bench.

## 10. Misses vanish in empty space

1. **What the player sees now.** A shell or bolt that misses flies to a point a little past the target and disappears there.
   There is no round flying on into the dark, no near-miss burst, no glancing spark. (I have not seen a capture of a miss;
   this is read from code.)
2. **What a film would do.** Misses keep going and fade far beyond; some flak bursts near the hull; some rounds glance off at
   an angle with a spark.
3. **Where.** godot/fx/fx_weapons.gd:176-181 places the miss point beside and beyond the target (`d * L * (0.4 to 1.2)`); the
   tracer's life is exactly the travel time to that point (e.g. 216, `dist / spd`); `_miss_fade` (1132-1135) says "misses
   fly on and fade" but only draws anything for beams.
4. **Why.** Nothing: an unfinished function.
5. **The loosening.** For shells, bolts and needles, extend the tracer's life so it keeps flying 3 to 5 times further and
   fades; a quarter of heavy-gun misses become near-miss bursts (a small grey puff and sparks 1 to 2 hull widths off); 1 in 6
   hits on a shield or glancing angle throws a ricochet streak. Torpedo misses (lane dodges) already have their own path.
6. **Size.** Small (one run). Negligible cost.
7. **Picture.** No bench moment shows a miss: add "macro volley, half misses" to look_moments.json.

## 11. A battered ship looks freshly patched: wounds are capped and every ship snaps back level

1. **What the player sees now.** After a long fight a capital carries at most twelve wounds; older scars are removed to make
   room. After every hit, the ship returns exactly level and exactly onto its hex, so a crippled ship floats as proudly as a
   fresh one.
2. **What a film would do.** Damage accumulates: a hulk late in the fight is covered in scars, lists a few degrees, trails gas,
   and drifts a little.
3. **Where.** godot/fx/fx_breach.gd:57-58 `MARK_CAP := 12`, `SEC_MARK_CAP := 4` ("the lightest old mark goes");
   godot/fx/fx_ship.gd:1121-1123 damage emitter caps 4/8, 8/12, 12/16 by weight; recovery to level and to the hex,
   fx_ship.gd:618-625 and 657-669 (critically damped, no residue).
4. **Why.** Frame rate for the marks (each mark rebuilds the hull on a worker, API.md:283) and for emitters (issue 232 stress
   bench with `cap_k`). The full return to level is a tidiness habit.
5. **The loosening.** Raise MARK_CAP to 20 and SEC_MARK_CAP to 7 for cruisers and up if the 232 stress numbers allow; when
   the cap is hit, merge into the nearest old mark (grow it) rather than delete it. Add a lasting list: below 40% hull, the
   recovery settles 2 to 5 degrees off level (roll or pitch toward the worst section) and a slow drift of a few tenths of a
   unit; the ship still sits on its hex for play.
6. **Size.** Medium (two runs, one measured on the PC). Cost: marks are the known heavy item; measure before raising.
7. **Picture.** docs/shots/look_bench/m3_shield_states.jpg style strip for hull states: a capital at 100%, 50% and 15% hull
   after 30 hits.

## 12. Ships move on rails: a bank nobody can see, engines that switch

1. **What the player sees now.** Ships turn with almost no lean, and the drive plume drops out in about a tenth of a second
   when a move ends. At rest every ship bobs with the same slow sine.
2. **What a film would do.** Bigger ships lean visibly into a hard turn; the plume tails off and the nozzles keep glowing
   hot for a moment; small idle drifts differ ship to ship.
3. **Where.** godot/render/ship_view.gd:1132 bank clamped to 4 degrees, scaled by `sin(PI * gl_p)`; movement_spec.md calls
   these numbers "ASSUMED", to be settled by the capture round of #233. Engine drop: godot/fx/fx_ship.gd:311 (rate 14 a
   second on a drop, "a burn's plume cuts off within about 0.1 s"), 302 (0.4 s hold). Idle bob: ship_view.gd:1287, one
   sine at 0.6 rad/s, 0.25 units, only the phase differs.
4. **Why.** The 4 degrees is a spec number; I could not find a capture that set it. The fast cut-off was a G2 choice for
   readability.
5. **The loosening.** Bank up to 10 to 12 degrees for hard turns on cruisers and up, less for frigates (they snap round
   instead); a plume that drops in 0.1 s but leaves the nozzle bells glowing and fading over 1.5 s; idle drift with two
   unrelated sines and a slight yaw wander. All presentation only.
6. **Size.** Small (one run).
7. **Picture.** None on the bench shows a turn; the #233 capture round is the place.

## 13. Shields can only show six ripples at once

1. **What the player sees now.** Under a heavy barrage on a shield (a scatter volley plus a lance's repeating rings), the
   seventh ripple wipes the oldest one off mid-fade, so the bubble never looks overwhelmed.
2. **What a film would do.** The shield crawls with overlapping ripples, glowing brighter the more it takes.
3. **Where.** godot/fx/fx_ship.gd:414 and 461: a six-slot ring buffer `(_hit_i + 1) % 6` passed to the shield shader.
4. **Why.** Shader uniform size, a convenience.
5. **The loosening.** 16 slots, plus a load glow (overall brightness rising with hits in the last second). Hold for Ryan's
   pick of the shield direction (issues 371 and 372), and build into that.
6. **Size.** Small (one run, shader plus script).
7. **Picture.** docs/shots/look_bench/m2_weapons_on_a_shield_a.jpg (scatter and lance rows).

## 14. Music does not hear the guns

1. **What the player hears now.** Battle music rises with closeness and damage, but the exchange of fire is never fed to it,
   and a kill does not move it at all.
2. **What a film would do.** The score swells into a big exchange and hits a beat when a capital dies.
3. **Where.** godot/music/music_player.gd:267-283 `feed` gives 0.2 of its range to `shots`; battle.gd:840 never passes
   `shots`. No kill hook exists.
4. **Why.** An omission.
5. **The loosening.** Pass hits this round as `shots`; on a cruiser or capital death, a short intensity spike (plus 0.25 for
   6 s) so the intense layer swells in.
6. **Size.** Small (one run).
7. **Sound.** A recorded battle round with two kills.

## 15. For Ryan's eye only: the flame cap

1. **What the player sees now.** No fire on screen lives longer than 0.70 s, and no hot core holds full heat longer than
   0.25 s. Big blasts are flash, short fire, then grey gas.
2. **What a film would do.** The same, mostly: space fire does snuff out. But a burning breach can glow and spit for seconds.
3. **Where.** docs/playbooks/effects.md section 1 and deaths_and_hits.md rule 2 ("No flame lives longer than 0.70 s; no hot
   core holds full heat longer than 0.25 s (owner ruling)").
4. **Why.** Ryan ruled "flash and snuff out" and against rolling fireballs (R88, R158). The two numbers come from Muse's
   staging table, not from his words.
5. **The loosening.** Do not change the fireball rule. Allow two things outside it: hull wounds and breaches that spit small
   jets of flame and sparks on and off for several seconds (the damage emitters already exist), and coals and molten edges
   that stay bright orange longer. Ryan's call.
6. **Size.** Small, if picked.
7. **Picture.** docs/shots/look_bench/rebake/d_cruiser_c170_all.jpg.

---

## What I could not determine

- How any of this sounds or moves in play: I had no PC and ran no bench, so shake, timing and sound findings are worked from
  code and the numbers above, not watched or heard.
- Whether the shake numbers at the battle camera are exact: I used 170 units to the event and 7.7 px a unit at 1080 (the
  figure in fx_breach.gd:61). Events far from the screen centre will be a little different; the result stays under a pixel.
- My reading of WCAG 2.3.1 (finding 1) is from W3C's Understanding page; the Board should confirm the area rule before it
  changes a safety limit, and the issue 232 salvo test is the proof.
- Why the core flash light is blue-white (fx_death.gd:1790).
- When the slow-motion call was lost (history squashed at 682d82b).
- Frame cost of wider lights (finding 7) and more marks (finding 11): unmeasured; both belong on the scene gate (R116).
