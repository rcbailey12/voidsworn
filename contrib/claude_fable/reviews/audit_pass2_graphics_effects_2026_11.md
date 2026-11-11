# Outside audit pass 2: graphics and effects (Nov 10 2026)

Auditor: a fresh Fable 5.2 session with no history on this project (R154). It fixed nothing. It read the repo and made its own captures on Ryan's PC.

## Summary

- The ships, effects, shields and maps are not held back by the graphics card or by Godot. They are held back by what the pictures are made from: almost everything on screen is drawn by maths written in code, or by one very small baked puff, instead of by authored art.
- Biggest single cause for hits and explosions: every explosion picture is a smoke puff simulated at toy size (64 cells, smoke only, no fire) that fills about a fifth of its picture tile. That is the pale square, the pale blob and the beige ball.
- A torpedo hit lasts a quarter of a second as a tan dust cloud. A cruiser dies with a pale puff and no fire. The heaviest moments have the least on screen.
- Ship paint is one flat colour per faction plus computed wear. That is why the Chorus lost its orange sacs and glow, and why round 6 paint reads flatter than the concept.
- At the camera the game is played from, most ships are 60 to 200 pixels long. Dark hulls disappear and the Glasswright hulls burn out to white. Most review sheets are made far closer than that.
- Shields only exist for half a second at a time, as one balloon for all four facings. You cannot see which side is down.
- Maps: the campaign map is the best looking screen. On the battle board the nebula and storm hexes, the station, the board planet and the rocks are the weak points.
- My pick for order: (1) rebake the explosion pictures properly and restage the big hits, (2) concept-driven paint and a readability pass at the battle camera, (3) a shield that hugs the hull and shows its four sides, (4) real volumes for nebulas and real geology for planets. Keep the ship recipe route. Stop polishing the old AI hulls.

## Board verdicts (added by the Board after checking every finding, Nov 10 2026)

Twelve confirmed, three partly (8 on its inference only, 12, 14), none wrong. The auditor's text is unchanged; each finding below ends with its own verdict line.

Where the Board differs from the auditor:
- Fire (findings 1 and 2). The diagnosis stands. The cure must fit Ryan's ruling R88 (fire is "wrong for space"; fireballs "flash and snuff out"): a short hot core, light on the hulls, a glowing wound, venting gas and a longer break-up, not a second of rolling fire. How much fire is Ryan's pick.
- Order. The look bench (finding 8) goes first because it is small and every later round is judged on it. Then the rebake and the big hits (1, 2, 9), then paint and the battle camera pass (3, 4, 13), then shields (6, 15), then lines and beams (5, 7), then maps (10, 11, 12).
- Station (12): one built set piece replaces issue 199 instead of adding to it.
- Materials (14): with the concept redo, not before.
- Old AI hulls: the Board agrees to stop polishing them; that retires issues 198 and 169 if Ryan agrees.

Board's own misses that this audit shows: the weapon bake scripts were dropped from PR 327 by the Board's own scope line (finding 8); the Board accepted the outline number on a hull whose front is wrong (finding 13); the Board's ship review images are closer than the player's camera can go (finding 4).

## How this was done

- Pinned commit: `70e87f2345adf171f4dd7a1a5aa52ac1d43e8338` (main). Every code line cited is from it.
- One exception, as briefed: ship round 6 is read from branch `opus/issue-209-r6` at `8f50c07` (pull request 336). Its sheets are named with that branch.
- Captures: made on Ryan's PC (RTX 5080, Godot 4.7.2, Forward+, quality max) between 00:20 and 00:43 UTC on Nov 10, from a clone at the pinned commit in `Downloads\voidsworn_test\audit2\repo`. They are in `docs/shots/audit_2026_11/` with a README. 41 of the 43 images are fresh captures, one mixes repo concept art with fresh captures, one is built from repo files.
- Tools used: the repo's own gallery reel, scene gate (`--still`), world shots, campaign `mapshots`, battle `--shots` and `--planet-shot`, plus a small probe of mine that copies the pattern of `godot/fx/test/vent_look_probe.gd`. The probe and its sheet maker live only in the PC checkout. They are not in this pull request.
- Older screenshots in `docs/shots/` were not used as evidence. Where I point at an image it is one of mine unless I say otherwise.
- "Closest zoom" means the nearest the game camera allows (`godot/render/camera_rig.gd:15`, `var min_r := 26.0`). "Battle camera" means the default (`godot/render/camera_rig.gd:9`, `var r := 170.0`).
- Image paths below are short for `docs/shots/audit_2026_11/<name>`.

## Findings at a glance

| # | Finding | Area | Seen or reasoned | How sure | Size |
|---|---|---|---|---|---|
| 1 | Every explosion picture is one tiny, coarse smoke puff | weapons and hits | OBSERVED | high | medium |
| 2 | The biggest moments have no fire, no light and no aftermath | weapons and hits | OBSERVED (cause INFERRED) | high | medium |
| 3 | Ship paint is one flat faction colour, so the concept's colours and glow are lost | ships | OBSERVED | high | medium per faction |
| 4 | At the battle camera dark ships vanish and pale ships burn out | ships | OBSERVED | high | small to medium |
| 5 | Thin ruler lines are a basic building block of hits | weapons and hits, shields | OBSERVED | high | small to medium |
| 6 | Shields have no resting state and are one balloon for four facings | shields | OBSERVED | high | medium |
| 7 | Shells, bolts and beams are plain cones, bars and tubes | weapons and hits | OBSERVED | high | small to medium |
| 8 | Looks are tuned as numbers in code and judged from cameras the player does not use | all four | OBSERVED (link to rounds INFERRED) | medium | small |
| 9 | Death puffs are placed off the hull by their own offset | weapons and hits | OBSERVED | high | small |
| 10 | Nebula and ion storm hexes are small flat puffs, not volumes | maps | OBSERVED | high | medium |
| 11 | The board planet and the rocks are smooth noise with no geology | maps | OBSERVED | high | medium |
| 12 | The station reads as a low pale slab | maps | OBSERVED (cause INFERRED) | medium | medium |
| 13 | The ship outline gate passes a hull whose front is wrong | ships | OBSERVED on the branch sheets (cause INFERRED) | medium | small, then medium |
| 14 | Chorus, Glasswrights and Eclipse need their own surface materials | ships | OBSERVED (approach INFERRED) | medium | medium |
| 15 | Shield and shield-hit surfaces read as flat line art | shields | OBSERVED | high | small to medium |

Sizes are in agent terms. Small: one worker run and one Ryan look. Medium: a few runs with a PC bake or capture in the loop and one or two Ryan review rounds. Large: a multi-round job like the ship rounds. No hours are estimated.

## Findings

### 1. Every explosion picture is one tiny, coarse smoke puff

Area: weapons and hits (also deaths and muzzle gas).

What I saw:
- `fx_17_flipbook_atlas_fill_from_repo.jpg`: the two picture sheets the game plays for a weapon impact and for a capital ship's death flash. Each cell is mostly empty. The puff is a small ball in the middle.
- I measured the files. In `godot/fx/atlases/weapons/impact/impact_color.png` the puff covers about 50 by 50 pixels of a 256 pixel cell. In `death/capital/flash_color.png` it covers about 89 by 89 of 512.
- `fx_01_torpedo_hit_30fps_closest_zoom.jpg`, cells 5 to 8: the cloud's edge breaks into square blocks. This is the small picture stretched large.
- `fx_16_gallery_torpedo_hit.jpg`, centre: a flat tan cloud behind the Eclipse flagship. This is the "beige ball".

Code:
- `tools/blender/vfx/bake_death.py:11`: `p.add_argument('--resolution', type=int, default=64)`. The smoke is simulated on a 64 cell grid.
- `tools/blender/vfx/bake_death.py:20`: `ds.use_noise=False`. Blender's fine detail pass is off.
- `tools/blender/vfx/bake_death.py:26`: `fs.flow_type='SMOKE'; fs.flow_behavior='INFLOW'; fs.density=1.5; fs.temperature=0`. Smoke only. No fire, no heat.
- `godot/fx/atlases/weapons/bake_manifest.json:22`: `"resolution": 64,`. The weapon puffs were baked the same way.
- `godot/fx/fx_death.gd:171`: `# The simulation occupies only about a fifth of each baked cell. Sampling`. The code already knows and crops to work round it.

OBSERVED. How sure: high. The files, the bake script and the captures all agree.

Approach: rebake, in Blender on the PC, which is free and already installed.
- Simulate fire and smoke together, not smoke alone, so there is a hot core that cools.
- Raise the grid to 192 or 256 cells and turn the detail noise on. The RTX 5080 has the room.
- Fit the camera to the gas so it fills about four fifths of each cell. Then drop the crop workaround.
- Bake 36 or 64 frames per effect instead of 16, and three or four different seeds per kind, picked at random per hit.
- Bake a heat channel so the game can colour the core white, then orange, then dark smoke, per weapon.
- Give each event its own source shape: a forward jet for muzzles, a flat splash for hull hits, a ring for torpedoes, a long tear for deaths.
- Free references and stopgap sprites for sparks and flares: the Kenney Particle Pack is CC0.

Size: medium. What drives it: GPU bake time per effect, then shader colouring, then one or two Ryan review rounds on sheets.

What Ryan would see: explosions with a white-hot heart and rolling orange fire that hold their detail at the closest zoom, and no two hits that look the same.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED. The Board measured the two picture sheets itself: the gas spans 55 of 256 pixels in the weapon impact cells and 91 of 512 in the capital death flash, and bake_death.py reads as quoted (64 cells, noise off, smoke only). This also means the seven gun smoke runs (issue 281) were tuning how a too-small picture is drawn. The Board takes the rebake (bigger grid, detail on, gas filling the cell, more frames, several seeds, a heat channel, a source shape per event). One change: the fire. Ryan ruled on Nov 3 (R88) that fire "looks more detailed than everything else and wrong for space" and that fireballs "flash and snuff out". So the hot core is a short flash that cools fast, not rolling orange fire that holds. How much fire is Ryan's pick, on a sheet.

### 2. The biggest moments have no fire, no light and no aftermath

Area: weapons and hits (torpedo, heavy hits, ship deaths).

What I saw:
- `fx_01_torpedo_hit_30fps_closest_zoom.jpg`: the heaviest weapon. Cells 3 and 4 are a cream ball. Cells 5 to 8 are a tan cloud. By cell 9 it is gone. That is about a quarter of a second. Cells 9 to 16 show a faint violet disc and a thin arc. The hull looks untouched afterwards at this zoom.
- `fx_08_torpedo_battle_view_crop.jpg`, row 2: from the battle view the same hit is a tan dot in three cells.
- `fx_18_death_cruiser_close.jpg`: a cruiser dies. Cells 4 to 9 (1.0 to 2.2 seconds in) show no change at all. Then a pale lavender puff, and the hull drifts apart in three pieces. There is no fire and no light on the ship.
- `fx_19_death_frigate_battle_view_crop.jpg`: a frigate dies on the right. From the battle view it is almost invisible.
- `fx_20_gallery_deaths.jpg`: three flagship deaths from the repo's own reel. Pieces separate. No fireball in any of the six stills.

Code:
- `godot/fx/fx_weapons.gd:1055`: `_burst(fx,p+n*k,n,T,12.0*k,"flash",0.32,tint,5.2,60.0)`. The torpedo flash lives 0.32 s.
- `godot/fx/fx_weapons.gd:1059` gives the gas 0.42 s: `"impact",0.42,tint,2.0,n*5.0*k,0.85,0.0,0.0,Tg)`.
- `godot/fx/fx_weapons.gd:495`: `Each step is now about a third of`. The comment records run 4 cutting sizes to hide the pale ball.
- `godot/fx/API.md:116`: `then one counted core flash follows 0.28 s later.` A capital death is one short flash.

OBSERVED for what is on screen. The cause is INFERRED: each review round removed a defect by making the effect smaller, shorter or fainter, and the fireball was taken out of deaths (R90) without anything of the same weight replacing it. How sure: high on the picture, medium on the cause.

Approach: stage each heavy event as three beats, with a set length and a set size on screen.
- Flash: one to three frames, white, and it lights the hulls near it.
- Body: fire for half a second to a full second, larger for heavier weapons. Use the new pictures from finding 1.
- Aftermath: a glowing wound that cools, embers, drifting smoke for several seconds. For deaths, a chain of smaller blasts along the break line before the hull parts.
- Fix a ladder so each step is clearly bigger at the battle camera: las, macro, lance, torpedo, ship death.
- Keep the reduce flashing option by swapping the white flash for a slower glow, not by shrinking the event.

Size: medium. What drives it: it depends on finding 1, then captures at three cameras and Ryan's rounds.

What Ryan would see: a torpedo strike that is the biggest thing on screen for a second and leaves a burning crater. A ship death that reads as an event from the default camera.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED on screen (the Board opened fx_01 and fx_18: a tan cloud for a few frames, a cruiser death with a pale puff and almost no light). The cause is the auditor's inference and the Board agrees, with its own part in it: run 4 of issue 281 was told by the Board to make the puff a third of its size. The three-beat staging and the size ladder go to pass 3. Same change as finding 1: under R88 the weight comes from the flash, the light on nearby hulls, the glowing wound that cools, venting gas, sparks and a longer break-up chain, with fire that snuffs out; not from a second of fire.

### 3. Ship paint is one flat faction colour, so the concept's colours and glow are lost

Area: ships.

What I saw:
- `ships_05_concept_vs_game_cruisers.jpg`, row 2 right: the Chorus cruiser concept has a tan shell, orange and pink sacs and a glowing yellow mouth. In the game it is one mustard colour.
- Same sheet, row 2 left: the Hegemony concept's long blue light strips are mostly gone and the white hull has grey blotches.
- Same sheet, row 1 right: the Hullbreaker cruiser in the game today is the old AI hull. Its paint is busy but has none of the concept's clear red front and dark aft.
- Round 6 (branch `opus/issue-209-r6`, `docs/shots/ship_pipeline/route209/round6/paint.jpg`): the concept, top left, has panel by panel variation and dark grime. Ab6, bottom left, has large even red and grey areas with orange specks.

Code:
- `tools/blender/a4/bakemat4.py:4`: `albedo   faction base colour (today's game look), plate-to-plate tone, edge wear and crevice grime`. The colour map starts from one base colour.
- `tools/blender/a4/bakemat4.py:21`: `'chorus': dict(hull='#3b3a22', dark='#17160c', trim='#b5852f',`. One olive for every Chorus hull.
- Round 6 README on the branch, line 50: `round 3's route (procedural masks from the ship's own geometry, baked to`. The new recipe paints the same way.

OBSERVED. How sure: high. One caution: the Glasswright and Eclipse concepts are due to be redone (R138) and the lore changed the Eclipse to violet-black (`bakemat4.py:23`), so for those two some of the mismatch is a decision, not a defect.

Approach: paint from the concept, in layers.
1. A region colour map. Where the concept camera can see the ship, project the concept's own paint onto it (`tools/blender/project_paint.py` is already in the repo). Elsewhere, fill each region with colours sampled from the concept.
2. Real material textures under the colour: painted steel, bare steel, rust, chitin, glass. Free and CC0 from ambientCG (the repo already downloads from it, `tools/pc/jobs/tex_download.bat`) and Poly Haven. Blend them by region.
3. Wear and grime from the ship's own shape, as now. Keep the computed masks for this layer only.
4. A light map from the concept: windows, sacs, strips, engine throats.
5. A few large markings that read from far away.

Size: medium for each faction's first ship, then small per ship. What drives it: one paint recipe per faction and a bake per ship.

What Ryan would see: Chorus ships with glowing orange sacs, Hegemony ships with their blue strips, and Ab6 with the concept's deep red, dark grime and panel variety.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED. bakemat4.py lines 4 and 21 read as quoted, and round 6 says itself that it paints from computed masks. This is the same thing Ryan said on Nov 9 (R156: "now it's a texture and paint pass"). The layered route (concept colours projected or sampled by region, real material textures under them, computed wear only as the top layer, a light map, a few large markings) is sent to the running ship round 7 as the way to do its paint step. Free texture sources need their licence lines checked when used (the auditor says it did not check them online).

### 4. At the battle camera dark ships vanish and pale ships burn out

Area: ships.

What I saw:
- `ships_04_battle_camera_1to1_crops.jpg`: true pixel size at the default camera. A frigate is about 60 to 80 pixels long, a cruiser about 150 to 180. The Eclipse frigate (row 3, right) and the Sunward frigate (row 4, right) can barely be found. The Glasswright cruiser (row 2, middle) is pure white with a halo and no detail.
- `map_01_battle_scene_20_ships_wide.jpg`: twenty ships in the real battle. Most are small dark marks. The name tags do the work.
- `map_16_real_battle_chorus_storm_bot_play.jpg`: in all four cells the ships are small dark shapes inside rings.
- `ships_01_cruisers_closest_zoom.jpg`: even at the closest zoom the six factions look like six different levels of finish. Two are dense and gritty, one is clean white, one is a single colour, one is a white sheet, one is violet with crack lines.

Code:
- `godot/render/camera_rig.gd:9`: `var r := 170.0`. The default distance.
- `godot/render/look.gd:19`: `const KEY_ENERGY := 2.0` and `godot/render/look.gd:52`: `env.glow_hdr_threshold = 0.8`. A bright key light and a low glow threshold.
- `tools/blender/a4/bakemat4.py:22` gives the Glasswrights a near-mirror finish: `met=.55, rgh=.10`.

OBSERVED. How sure: high.

Approach: one readability pass, judged only at the battle camera.
- Set a brightness band for the lit side of every faction, so none sinks into the sky and none clips.
- Add a rim light from behind so dark hulls keep an edge.
- Size windows, trim lights and engine glow for a 70 pixel ship, and bake them into the light map.
- Cap the Glasswright hull's brightness and gloss so it keeps its lines.
- Keep one standing sheet: all 36 ships at true pixel size over the darkest and the brightest sky. Every ship change is judged on it first.

Size: small to medium. What drives it: look data and light rig changes are small. Rebaking light maps for 36 ships is the larger part.

What Ryan would see: at the default zoom he can tell every ship and every faction apart without reading the tags.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED. The Board opened ships_04: frigates are small dark marks, the Glasswright cruiser is a white shape with a halo. camera_rig.gd and look.gd read as quoted. Board's own miss: its review images for ship rounds, including the one sent to Ryan for round 6, are close-ups the player's camera cannot reach. From now on every ship sheet leads with the battle camera at true pixel size. Goes to pass 3 with the standing 36-ship sheet.

### 5. Thin ruler lines are a basic building block of hits

Area: weapons and hits, and shield breaks.

What I saw:
- `fx_03_gauss_hit_30fps_closest_zoom.jpg`: a hairline crosses every cell from the left edge to the ship. From cell 6 on, each hit throws a starburst of thin straight white lines.
- `fx_10_gallery_gauss_lines.jpg`: thin white lines run across the whole scene from the Hegemony flagship, top left of centre.
- `fx_11_gallery_bio_splash_lines.jpg`: thin yellow-green lines fan out from the hit on the left of the barge.
- `sh_06_gallery_break_hegemony.jpg`: thin yellow lines cross the breaking shield.

Code:
- `godot/fx/fx_weapons.gd:352`: `fx.stk(from, tf, 0.4, col.lerp(Color.WHITE, 0.5), 4.5, dist, 0.1 * ka, 5, dir,`. The gauss wake is one line the full length of the shot.
- `godot/fx/fx_weapons.gd:530`: `fx.stk(p, t, life * 0.7, col, 1.8, 0.14 * k, 0.03 * k, 1, v, drag,`. Each spark gets a line.
- `godot/fx/fx_shaders.gd:433`: `float L = max(a3.x * sp * e, 0.05);`. That line's length is a time multiplied by the spark's speed, and both grow with ship size.
- `godot/fx/fx_shaders.gd:457`: `float wf = (k == 0 || k == 4) ? 2.6 :`. Lines are held at about 2 pixels wide however far away they are.

OBSERVED. How sure: high that the lines are there and come from the streak drawing. Medium on which call draws each line in each image.

Approach: stop using the bare line for sparks and wakes.
- Sparks: a bright head with a short, tapered, textured tail that curves as it slows. Cap the tail length in screen pixels.
- Gauss: a brief heat shimmer along the path (the repo has a distortion shader) and a thick tracer for two frames.
- Shield shards: small lit flakes, not lines.
- Keep hard lines only for las bolts, and give those a textured core.

Size: small to medium. What drives it: one new tail shape, then replacing the callers, then captures.

What Ryan would see: no hairlines anywhere. Sparks that look like hot metal thrown off.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED. Hairlines are visible in the Board's own look at sh_01 (cells 2 to 5) and the streak calls read as quoted. Which call draws which line is the auditor's medium-sure part. Goes to pass 3 together with finding 7 (one kit of trails, beams and flares).

### 6. Shields have no resting state and are one balloon for four facings

Area: shields.

What I saw:
- `sh_01_hegemony_hit_and_break.jpg`: cell 1, no shield at all. Cells 2 to 6, the whole bubble lights for a hit on one side. Cell 7, gone again. Cells 8 to 12, the whole bubble comes back and shatters, though only one facing was broken.
- `sh_02_voidsworn_hit_and_break.jpg`: the same, and the orange fill hides the ship inside.
- `sh_05_hegemony_battle_view_crop.jpg`: from the battle view the shield is a pale oval that blinks on and off.
- The bubble is much larger than the ship. It looks like a balloon round it.

Code:
- `godot/fx/fx_ship.gd:315`: `_shield_mi.visible = fx.now < _shield_until`. The shield is only drawn for a moment after a hit.
- `godot/fx/fx_ship.gd:752`: `shs += float(v) if v != null else 0.0`. The four facing values are added into one number. They are never drawn one by one.
- `godot/fx/fx_hull.gd:569`: `return Vector3(L * 0.5 * 1.1 + 0.3,`. The bubble is the ship's bounding box, made 10 to 35 percent larger.
- `godot/fx/fx_ship.gd:466`: `_shield_until = maxf(_shield_until, T + 1.45)`. A break shows the whole bubble for 1.45 s.

OBSERVED. How sure: high.

Approach: a shield that hugs the hull and shows its state.
- Build the shield surface from the ship's own shape, pushed out a little, when the ship is built.
- Split it into the four facings the rules already use. Draw each by its strength: steady when full, flickering when low, dark when down.
- Resting: a faint edge glow only, when zoomed in, hovered, or just hit.
- A hit: a ripple near the impact, not the whole surface.
- A break: only that facing shatters, and it stays open.

Size: medium. What drives it: making the shield surface for 36 ships, the new shader, captures of four styles.

What Ryan would see: at a glance, which side of a ship is open. Hits that splash on a skin close to the hull.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED. sh_01 shows no shield at rest, the whole bubble lighting for one hit and the whole bubble breaking; fx_ship.gd lines 315 and 752 and fx_hull.gd line 569 read as quoted. Goes to pass 3 as an Opus job (new surface per ship, new shader), after the ship recipe can emit the shield surface with the hull.

### 7. Shells, bolts and beams are plain cones, bars and tubes

Area: weapons and hits.

What I saw:
- `fx_02_macro_hit_30fps_closest_zoom.jpg`, cells 1 to 10: each macro shell is a pale cone with a round head, the same every time, and larger than the hit it makes (cells 6 to 12, a small pale puff).
- `fx_12_gallery_prism_bars_on_shield.jpg`, centre: three white bars in a row.
- `fx_13_gallery_ion_beam.jpg`, left: the ion beam is a flat ribbon with candy stripes.
- `fx_06_lance_hit_30fps_closest_zoom.jpg`, rows 2 and 3: the lance is an even cream tube. When it stops, nothing is left to see at this zoom.
- `fx_04_las_hit_30fps_closest_zoom.jpg`: a short bar, then an orange dot.
- `fx_09_macro_muzzle.jpg`, cells 4 and 5: a tan ball at the muzzle.

Code:
- `godot/fx/fx_weapons.gd:216` draws the shell as one line with a fixed length and width: `18.0, 9.0 * ka, 0.75 * ka * (1.2 if w >= 3 else 1.0),`.
- `godot/fx/fx_shaders.gd:291`: `if (r > 1.0) { discard; }`. Every sprite kind is a disc with a soft falloff worked out in the shader.

OBSERVED. How sure: high.

Approach: a small kit of authored parts.
- Beams: two crossed strips with two scrolling textures, a hot core, a soft sheath, a flare at the muzzle and a glow where it lands.
- Shells: a small bright head, a short tapered trail, and a real muzzle flash from finding 1.
- One shape language per faction, so a volley can be read by its look.
- Textures: painted in Krita or GIMP, or baked in Blender. All free.

Size: small to medium. What drives it: about eight looks to rebuild, each with captures at three cameras.

What Ryan would see: weapons that can be told apart by shape, with a visible muzzle, flight and landing.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED on the code (the shell is one streak call, the sprite shader discards outside a disc). The Board opened one of the six images named here (the shell in fx_01); the rest it takes from the auditor. Goes to pass 3 with finding 5.

### 8. Looks are tuned as numbers in code and judged from cameras the player does not use

Area: all four.

What I saw:
- The repo's effects reel uses a free camera much closer than the game allows (compare `fx_10` with `fx_03`).
- The reel printed an error at start and drew no nebula (`godot/world/world_bake.gd:24`, `tree.root.add_child(node)`, "Parent node is busy setting up children").
- The campaign map tool's last still was the loading screen (`godot/scenes/campaign/campaign_scene.gd:114`, `if C.page["kind"] == "map": await _shot(dir, "m5_sector2")`).
- In the bot battles (`map_15`, `map_16`) the action at the game's own "fire" moments is tiny, and in `map_16` (cell 2, bottom right) the enemy sits at the edge of the right-hand panel.

Code:
- `godot/fx/fx_weapons.gd:382`: `code = code.replace("float frame = mix(age * 15.0, 3.0 + sqrt(age) * 12.0, plasma);",`. The weapon gas shader is made by patching the text of the death shader while the game runs.
- `docs/shots/vent_fx_2026_11/README.md:16` says the weapon puffs were baked with `tools/blender/vfx/bake_weapons.py`. That file is not in `tools/blender/vfx/` at the pinned commit. I searched for it.
- `godot/fx/fx_weapons.gd:495` and the lines round it record run 4, run 5 and run 6 of the same effect in comments.

OBSERVED for each fact. That this is why visual jobs take many rounds is INFERRED. How sure: medium.

Approach: one look bench, used by every visual job.
- A fixed list of moments (each weapon on hull and on shield, each shield state, each death) at three real cameras: default (170), middle (60) and closest (26).
- Contact sheets at 30 frames a second, built by the job, with before and after side by side.
- My probe did all weapons, shields and deaths in under two minutes of GPU time. The pattern is cheap.
- A reference board per effect in the repo: three frames from games Ryan likes. Workers build to it.
- Move the tuning numbers into data files, so a change is a number, not a shader patch.
- Every baked picture keeps its bake script in the repo.

Size: small. What drives it: one scene and one job file.

What Ryan would see: fewer rounds. Every sheet he is sent is at the cameras he plays from.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED on the facts, and one of them is the Board's own miss: tools/blender/vfx/bake_weapons.py and pack_weapons.py are not on main. Runs 5 and 6 of issue 281 carried them; the Board's run 7 brief gave the scope as godot/fx and the shots folder only, so run 7 left them out and PR 327 merged without them. They are being restored from the PC run folder in their own pull request. The link to many review rounds is inference; the Board agrees from first hand. The look bench (fixed moments, the three real cameras, 30 frames a second sheets, before and after) is small and makes every later visual round cheaper, so the Board puts it first in pass 3; it replaces issue 333.

### 9. Death puffs are placed off the hull by their own offset

Area: weapons and hits.

What I saw:
- `fx_18_death_cruiser_close.jpg`, cell 2: a pale ball floats above and left of the cruiser, clear of the hull.
- `map_02_battle_scene_close_dying_ship.jpg`: a pale disc sits beside the ship tagged "Debt of Vesper", top centre. This is the real battle scene.

Code:
- `godot/fx/fx_death.gd:179`: `mi.global_position = p + (n * size * 0.42 if kind == "vent" else Vector3.ZERO)`.
- `godot/fx/fx_death.gd:1045` passes the size: `flipbook(fx, p, n, s.hull.L * 0.85, "vent",`. So the puff's centre is put 0.36 ship lengths away from the hull.
- The stray puff check does not cover it. `record_spawn` is called only from `godot/fx/fx_weapons.gd:456`, `:501` and `godot/fx/fx_ship.gd:709`.

OBSERVED. How sure: high. This is the same kind of defect as R153, in a different place.

Approach: place the picture so the root of the gas, not the middle of the picture, sits on the plating. After the rebake in finding 1, take the offset from the real size of the gas. Add the death puffs to the stray puff check.

Size: small.

What Ryan would see: no pale balls in empty space near a dying ship.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED. fx_18 cell 2 shows the pale ball clear of the hull; fx_death.gd lines 179 and 1045 read as quoted (0.42 times 0.85 of the ship's length), and record_spawn has only the three callers listed. Small job for pass 3: root the gas on the plating and add the death puffs to the stray guard.

### 10. Nebula and ion storm hexes are small flat puffs, not volumes

Area: maps.

What I saw:
- `map_06_nebula_hex_close.jpg`: two purple puffs, top centre. They are smaller than the hexes they mark and look like flat cards.
- `map_07_ion_storm_hex_close.jpg`: dark blobs with a yellow vein pattern, like marble. They read as stickers on the board.
- `map_05_nebula_storm_default_camera.jpg`: from the default camera the terrain is a few small smudges on a large cloudy sky. The sky itself looks more like an overcast day than a nebula.

Code:
- `godot/world/world_living.gd:4`: `nebula      soft gas: billboards that sample one continuous 3D noise field in world space`.
- `godot/world/world_living.gd:8`: `ion storm   the same gas, darker than the sky behind it with yellow-white electric veins`.

OBSERVED. How sure: high.

Approach: real volumes at the top quality tier.
- Use Godot's fog volumes, one per patch, shaped by a baked 3D noise texture. R90 already allows fog volumes at the max tier.
- Make the cloud one to two hexes tall so ships sit inside it, with a soft edge that spills past the hex.
- Lightning as real lights inside the fog.
- Lower tiers: cards rendered from the same volume in Blender.
- Report the cost against the R116 gate.

Size: medium. What drives it: GPU cost testing on the gate scene, and the look at three tiers.

What Ryan would see: ships sliding into glowing gas that has depth, and storms that flash from inside.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED. The nebula in map_11 is a few small purple puffs; world_living.gd reads as quoted. This is open issue 139 already; the fog volume route is allowed at the top tier by R90. Pass 3 rewrites 139 with this approach and a cost report against the R116 gate.

### 11. The board planet and the rocks are smooth noise with no geology

Area: maps.

What I saw:
- `map_11_board_planet.jpg`: the board planet fills the lower half. It is a smooth beige ball with soft dark blotches. No mountains, craters, rivers or cloud detail. Hex lines are drawn across its top.
- `map_08_rocks_close.jpg`: every rock is the same rounded lump in one beige tone with round dents.
- `map_09_backdrops_sheet_a.jpg` and `map_10_backdrops_sheet_b.jpg`: the far planets and moons are better. The ringed giants are flat bands.

Code:
- `godot/world/world_planet.gd:5`: `# Each surface is baked once on the GPU (world_bake.gd) into two equirectangular pictures:`. The surface is worked out by a shader.
- `godot/world/world_rocks.gd:2`: `# F4 asteroids: the rock library (world/rocks/*.glb, made by world/tools/rockgen.py), a material per rock kind, and`.

OBSERVED. How sure: high.

Approach: start from real data, which is free.
- NASA and USGS planet colour and height maps are public domain: Mars, the Moon, Mercury, Io, Europa, Ganymede, Titan, Earth's clouds.
- Mix, warp and recolour two sources per planet type so none is a plain copy.
- Give the board planet an 8K set (colour, relief, roughness), an air glow shell and a moving cloud layer with shadows. It is the largest thing on that map.
- Rocks: eight to twelve scanned CC0 rocks from Poly Haven with detail levels, tinted per biome. Keep the rock generator for dust-size pieces.

Size: medium. What drives it: download and remix jobs on the PC, one planet type at a time, and the cost at 4K.

What Ryan would see: a planet with real terrain when he zooms to it, and asteroid fields with sharp, varied rock.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED. map_11: the board planet is a smooth beige ball with soft blotches. This is open issue 140 already. Starting from public domain planet data and scanned CC0 rocks is new and the Board takes it, with each source's credit line checked when it is downloaded.

### 12. The station reads as a low pale slab

Area: maps.

What I saw:
- `map_03_station_default_camera.jpg`, centre: the station is a pale flat shape about two hexes wide, ringed by rocks, with orange hex outlines on top of it.
- `map_04_station_low_camera.jpg`: from a low camera it is no taller than the rocks beside it.
- `map_15_real_battle_station_map_bot_play.jpg`: in a real battle it is a white lump at the right edge.

Code:
- `godot/world/blocker_visuals.gd:32`: `var station := A4P.station(14.0)`. Each blocked station cell gets a piece 14 units across.
- A cruiser is 23.2 units long: `godot/render/hull_table.gd:26`, `const SHIP_K := 1.6`, times the Cruiser entry 14.5 on line 27.

OBSERVED on the picture. The cause is INFERRED from the code: the station is put together from small pieces, each smaller than a cruiser. How sure: medium. Ryan has said the same of the paint (R109: "it looks super plain and just like regular shapes right now").

Approach: build the station as one set piece with the ship recipe.
- At least three hexes wide and taller than any ship: a core, a ring or docking arms, towers.
- Lights, and one slow moving part.
- Break lines and insides, as R98 asks for ships.
- Size it from the hexes it blocks, so the outlines are not needed to explain it.

Size: medium. What drives it: one recipe run with its own parts kit.

What Ryan would see: a station that looms over the fleets and is worth fighting round.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): PARTLY CONFIRMED. The code facts hold (a station piece is 14 units, a cruiser is 23.2). The Board did not open the three station images, and the cause is the auditor's inference; it matches Ryan's own words in R109. Board pick: build the station as one set piece through the ship recipe, which replaces open issue 199 (a detail pass on the current pieces) instead of adding to it.

### 13. The ship outline gate passes a hull whose front is wrong

Area: ships (round 6, branch `opus/issue-209-r6`).

What I saw, on the branch sheets:
- `route209/round6/paint.jpg`: the concept's front is a long flat-decked wedge. The casemates sit in a flat slab side. Ab6's front is a rounded bulb with a raised block on top.
- `route209/round6/silhouette.jpg`: Ab6 scores 90.1 percent. The red and yellow slivers sit mostly at the front and under the belly.
- `route209/round6/overview.jpg`: the weapons look good in the wide views. I agree with Ryan there.

Text on the branch:
- Round 6 README line 7: `The outline gate holds: 90.1 percent (Ab5 90.3).`
- Round 6 README line 68: `on the side wall of Ab6's raised forward deck, a shape difference from round 5, not paint`. The report itself notes the front is a different shape.

OBSERVED on the sheets. Why the gate lets it through is INFERRED: it compares only the outer outline, from one camera, as one number. A wrong deck line or bow face inside the outline does not move it. How sure: medium. I did not read the scorer's code.

Approach: keep the gate and add three cheap checks.
- Score the front, middle and back thirds separately.
- An inner edge check: draw the hull's main edges (deck edge, chine, bow profile, casemate frames) over the concept and measure how far they sit from the concept's own edges.
- A blink sheet for Ryan: concept and model at the same camera, swapped back and forth.
- Then one hull round for the front only, before more paint.

Size: small for the checks. Medium for the front round, about the size of round 5.

What Ryan would see: Ab6 with the concept's flat wedge front.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED, and against the Board's own review: the Board accepted "90.1 percent" on PR 336 while the front is the wrong shape, which Ryan said the same day (R156: "the front is still very much off from the concept"). One outline number from one camera cannot see a wrong deck line or bow face. The per-third score, the inner edge check and the blink sheet are sent to the running round 7, whose step 3 is the front.

### 14. Chorus, Glasswrights and Eclipse need their own surface materials

Area: ships.

What I saw:
- `ships_05_concept_vs_game_cruisers.jpg`, row 2 right: Chorus flesh reads as painted clay. No wet shine, no light through the skin.
- Same sheet, row 3 left: the Glasswright sail concept is pearly and see-through with a gold root. In the game it is a flat white sheet with lines.
- Same sheet, row 3 right: the Eclipse concept is machined black with small green lights. In the game it is violet with crack lines over a lumpy surface.
- `ships_02_flagships.jpg`: the same three faults on the flagships.

Code and docs:
- `docs/ship_pipeline/AUDIT_BRIEF.md:80`: `- Chorus (bio-ships) and Ithar (sails) don't fit a mechanical "bolt-on" kit. No approach yet.`
- `tools/blender/a4/bakemat4.py:7`: `normal   the hulls_hi normal map (hull) plus fine procedural relief: panel seams per faction, grit`. Every faction gets the same kind of surface.

OBSERVED on the pictures. The approach is INFERRED. How sure: medium.

Approach: three Godot materials that use the same baked maps.
- Chorus: light passing through thin skin, a wet top coat, sacs that pulse.
- Glasswrights: a colour shift with viewing angle, light through the sail, fine ribs.
- Eclipse: near-black machined metal with thin lines and points of light.
- Settle them together with the concept redo (R138), so paint and material are designed as one.

Size: medium. What drives it: three shaders and their look rounds.

What Ryan would see: three factions that look like different things, not different colours of the same thing.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): PARTLY CONFIRMED. The pictures and the two quoted lines hold; the approach is the auditor's inference. Board on timing: do these three materials with the concept redo for those factions (R138), not before, so paint and material are designed once.

### 15. Shield and shield-hit surfaces read as flat line art

Area: shields.

What I saw:
- `sh_06_gallery_break_hegemony.jpg`: an even hexagon wire over the whole bubble, some hexagons filled white, thin rings, and coloured star glints.
- `sh_07_gallery_break_voidsworn.jpg`: glowing orange cells with a cloudy fill. The ship inside is hard to see.
- `fx_12_gallery_prism_bars_on_shield.jpg`, left of the shield: the hit on a shield is a pale blue puff ball, the same puff as a hull hit.
- `sh_01_hegemony_hit_and_break.jpg`, cells 2 to 6: the ripples are thin oval outlines.

Code:
- `godot/fx/fx_shaders.gd:859`: `render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;`. The shield is flat added light. It does not bend what is behind it or react to what it touches.
- `godot/fx/API.md:320`: `A hit lights the whole bubble faintly in its faction colour and pattern`.

OBSERVED. How sure: high.

Approach, on top of finding 6:
- Show the pattern only near a hit and fade it with distance.
- Add a bend of the background at the ripple (the repo has a distortion shader) and a glow where the shield meets a hull or a rock.
- Cap the brightness so the ship is always visible.
- Give shield hits their own splash picture: an energy crackle, not smoke.
- Keep the four faction patterns as masks.

Size: small to medium once finding 6 is done.

What Ryan would see: a shield that looks like energy with depth, and a ship he can still see through it.

Board verdict (Fable 5.2 Board, Nov 10 2026, checked against the repo and the images): CONFIRMED. sh_01 shows the even hexagon wire and thin ring outlines; the shield shader's render mode reads as quoted. Follows finding 6 in pass 3.

## Best approach, area by area

### Ships

Keep: the recipe route from rounds 1 to 6 (traced hull, faction parts kit, bake, export). The round 6 weapons show it works. Keep the rule of one kit per faction (R151).

Change:
1. Paint from the concept in layers (finding 3). This is what closes "the paint reads flatter than the concept".
2. Judge at the battle camera first (finding 4). A ship has to read at 60 to 200 pixels before close detail matters.
3. Add the inner edge and per-third checks to the gate, then do one front-only round on Ab6 (finding 13).

Drop: more passes on the old AI hulls. All 36 ships in the game today come from them (`godot/assets/ships/README.md:3`, `from the game's AI hulls`). Their wavy surfaces and the line patterns laid over them (`ships_01`, Eclipse cell) will not be fixed by another pass. Spend that effort on the recipe.

Order I would pick: one cruiser per faction through the recipe first, because that sets each kit and each paint recipe. Then frigates and destroyers, because a 20 ship battle is mostly those. Flagships last.

Do not spend time on: triangle counts, 8K sets for small ships, or close-up sheets nearer than the game camera allows.

### Weapon and hit effects

Keep: the effect clock, the event calls from the rules, the hull marks and breach system, the pooled drawing. Keep baked flipbooks as the route (R90, R146). The route is right. The bake is too small.

Change:
1. Rebake the explosion pictures properly (finding 1). Everything else depends on it.
2. Restage the big moments in three beats with a size ladder (finding 2).
3. Replace bare lines and plain bars with a small kit of authored trails, beams and flares (findings 5 and 7).

Then fix the off-hull puffs (finding 9) and put the look bench in place (finding 8) so the next rounds are judged the same way every time.

Drop: tuning by shrinking. Each round since run 3 made something smaller or fainter to hide a defect. The result is hits that are hard to see at all.

Do not spend time on: more code-drawn sprite kinds. The sprite shader already has more than twenty and they are all soft discs.

### Shields

Change the model, not the pattern.
1. A hull-hugging shield surface with four facings and a resting state (finding 6).
2. Hits as local ripples with a background bend and a contact glow (finding 15).
3. A break that opens one facing and leaves it open.

Keep: faction colours and the four pattern ideas (veil, lattice, patches, prism), as masks on the new surface.

Drop: the whole-bubble flash on every hit, and the whole-bubble break.

Do not spend time on: more detail in the current hexagon and cell patterns. They are drawn on the wrong shape.

### Maps and backdrops

Keep: the campaign sector map (`map_12`). It is the strongest screen in this audit. It needs the new UI style, not new art. Keep the dead star, the ringed planets as backdrop, the hex and range drawing, and the rock layout code.

Change:
1. Nebula and storm hexes into real volumes at the top tier (finding 10).
2. The board planet and the rocks from real data and scans (finding 11).
3. The station as one built set piece (finding 12).

Also worth doing, smaller: the sky. The nebula backdrops are soft and low in contrast (`map_05`, `map_10`). Public domain NASA and ESA deep-sky pictures, or the free Spacescape tool, would give sharper skies than the computed clouds. Check each picture's credit line before use.

Do not spend time on: more rock count, or more backdrop planets. The count is fine. The surfaces are the problem.

## Not checked

- I did not play the game by hand. All battle captures are from tools or the bot.
- Motion was judged from frame sheets at 30 frames a second, not from video. Timing feel, camera shake and sound were not judged.
- Squadrons, flak, boarding, ramming, the doom arc, star torpedo and rockets were seen only in the repo's reel stills, or not at all.
- The Hullbreaker and Glasswright shield sequences were captured but I did not study them. They are not in the evidence folder.
- The safe mode (Compatibility renderer), the high and low quality tiers, and 4K frame cost were not run.
- I did not read the outline scorer's code, `tools/recipe/`, or `RECIPE.md` on the round 6 branch. Finding 13 rests on the sheets and the README.
- I did not open the ship model files or their texture maps. Paint findings rest on captures and on the bake script.
- Which exact call draws each thin line in each image (finding 5) was not traced line by line.
- Licences: ambientCG, Poly Haven and Kenney are CC0 to my knowledge. NASA material is generally public domain. I had no web access in this run, so each source's terms need a check before use.
- Open pull requests 325, 316, 303, 301, 295, 291, 287 and 286 were ignored as briefed. Issues 139, 140, 199 and 100 were not read. I know them only from FINDINGS.
- The campaign screens other than the sector map were captured but not reviewed. They are UI, not this pass.
- GPU cost of every approach above is unmeasured. Each needs its cost reported against the R116 gate.

## Files read

Commit `70e87f2345adf171f4dd7a1a5aa52ac1d43e8338`. Line counts, the first 40 characters of each file's last line, and the ranges read.

| File | Lines | Last line starts | Read |
|---|---|---|---|
| godot/fx/fx_shaders.gd | 1871 | `"""` | 186-470, 857-900; searched the rest |
| godot/fx/fx_weapons.gd | 1299 | `   (m as ShaderMaterial).set_shader_para` | 115-135, 380-396, 440-560, 878-945, 1018-1081; searched the rest |
| godot/fx/fx_death.gd | 1481 | `   l["base"] = 0.7 * gate` | 150-182, 1030-1050; searched the rest |
| godot/fx/fx_ship.gd | 1322 | `  _dmg_request(fx)` | 308-318, 459-520, 716-760; searched the rest |
| godot/fx/fx_hull.gd | 576 | ` return Vector3(r * cos(an), r * sin(an)` | 568-576; searched the rest |
| godot/fx/fx.gd | 1058 | ` tmp.queue_free()` | 362-374, 664-770; searched the rest |
| godot/fx/fx_pool.gd | 255 | ` return [v, n, idx]` | 1-120 |
| godot/fx/API.md | 373 | `- 'fx/test/check_destruction.bat' now in` | 73-131; searched the rest |
| godot/fx/faction_looks.json | 94 | `}` | all (parsed) |
| godot/fx/atlases/weapons/bake_manifest.json | 54 | `}` | 1-40 |
| godot/fx/atlases/death/bake_manifest.json | 81 | `}` | 1-30; searched the rest |
| godot/fx/gallery/README.md | 118 | `Pipeline compiles during the measured fi` | all |
| godot/fx/gallery/gallery.gd | 708 | ` return RenderingServer.frame_post_draw` | 226-330, 600-690; searched the rest |
| godot/fx/test/vent_look_probe.gd | 330 | ` cam.snap()` | 1-330 |
| godot/render/look.gd | 109 | ` return m` | all |
| godot/render/camera_rig.gd | 194 | ` look_at_from_position(p, tg, up)` | 1-60; searched the rest |
| godot/render/hull_table.gd | 56 | ` return Color(hex).srgb_to_linear()` | all |
| godot/render/ship_view.gd | 1291 | `  ring.rotation.y = -rotation.y` | 62-200; searched the rest |
| godot/scenes/battle/battle.gd | 5095 | ` get_tree().quit(code)` | 176-232, 350-358, 4724-4764; searched the rest |
| godot/scenes/campaign/campaign_scene.gd | 171 | ` get_tree().quit(1 if bad > 0 else 0)` | 1-131 |
| godot/bench/scene_gate.gd | 924 | `   "volumetric_fog": b.env.volumetric_fo` | 1-80 |
| godot/world/world_shots.gd | 320 | ` print("[world_shots] ", p)` | 1-140 |
| godot/world/world_living.gd | 884 | `  _chunk_task = -1` | 4-12; searched the rest |
| godot/world/world_planet.gd | 351 | `"""` | 1-30 |
| godot/world/world_rocks.gd | 462 | `  return n` | 1-12 |
| godot/world/world_sky.gd | 385 | ` return out` | searched only |
| godot/world/blocker_visuals.gd | 189 | ` node.global_position = centre + Vector3` | 30-36; searched the rest |
| godot/assets/ships/README.md | 116 | `- Nothing here depends on the old 'hulls` | 1-90 |
| godot/assets/ships/a4_props.gd | 64 | ` return n` | 34-48 |
| tools/blender/vfx/bake_death.py | 57 | `(out/'bake.json').write_text(json.dumps(` | 3, 11-56 |
| tools/blender/a4/bakemat4.py | 367 | `    return m, dict(albedo=albedo, orm=or` | 1-30; searched the rest |
| tools/blender/a4/README.md | 124 | `- The game's hull JSON (unchanged): x bo` | 1-60 |
| docs/REVIEW_PROTOCOL.md | 35 | `- Claude checks every claim against the ` | all |
| docs/ship_pipeline/AUDIT_BRIEF.md | 105 | `- The heavy steps only run on the owner'` | all (long lines cut at 900 characters) |
| docs/ship_pipeline/GRAPHICS_REVIEW.md | 24 | `  material on the visible clone ('ship.s` | all |
| docs/shots/vent_fx_2026_11/README.md | 44 | `effect clock at 640x360), then 'godot/fx` | searched only (lines 1-25 seen) |
| HANDOFF.md | 31 | `The Oct 26 to Nov 7 history (sections 0a` | section 0 |
| contrib/opus/FINDINGS.md | 327 | `/ X17 / Muse follow-up pass over unasses` | rows R88, R90, R98, R108 to R111, R116, R118, R121, R122, R124, R137 to R155 |

Also read on branch `opus/issue-209-r6` at `8f50c07`: `docs/shots/ship_pipeline/route209/round6/README.md` (all), and the sheets `paint.jpg`, `overview.jpg`, `battle.jpg`, `silhouette.jpg` in that folder. `weapons.jpg` was not opened at full size.

## Self-check

Every cited line was reopened at the pinned commit and each quote compared with the file before hand-in. Names used in the text (`record_spawn`, `min_r`, `KEY_ENERGY`, `shield_radii` values, `A4P.station`, `SHIP_K`, `use_noise`, `flow_type`) were searched for first.
