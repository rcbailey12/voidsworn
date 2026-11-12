# Effects, world and look API (G4, for the G2 battle scene)

G4 owns `godot/fx/`, `godot/world/` and `godot/render/look.gd`. The battle scene (G2) uses them only through the calls below. A change to this contract lands in this file in the same commit, and anything marked "coming" may arrive later without breaking what is here.

Design in one line: G2 plays the rules event stream; for each event it calls one fx function; fx draws everything (projectiles, impacts, shields, damage, fire, death, wrecks, engine trails, shake and hit pause) and tells G2 how long the picture takes, so G2 can pace the next event.

## 1. Setup

```gdscript
const FX = preload("res://fx/fx.gd")
var fx = FX.new()
world.add_child(fx)                    # under the same 3D world as the ships
fx.setup({
    "camera": cam,                     # Camera3D; fx applies shake through cam.h_offset / cam.v_offset (see 7)
    "quality": "max",                  # "max" (PC default), "high", "low"
    "reduce_flashing": false,          # settings toggle, can change any time (see 8)
    "shake": 1.0,                      # settings slider 0..1 ("reduce screen shake" = 0.5, off = 0)
    "unit": 1.0,                       # world units per game unit; 1.0 = the game's scale (HEX_S = 10, hexes 17.3 across)
    "starboard_z": 1,                  # +1: root +Z is starboard (G2's mirrored roots); -1: root +Z is port
    "min_px": 1.0,                     # F3: scale of every effect's minimum on-screen size (1 on, 0 off; see 16)
})
```

- fx runs its own `_process`. It keeps its own effect clock (scene_t, a global shader parameter it registers) that slows during hit pause.
- For stills and tests: `fx.manual = true` and then `fx.step(dt)` once per frame; the clock then only moves with `step`.
- On the loading screen, after ships, lights and world are built: `await fx.warmup(cam)` (draws every effect material once, so the first lance, shield ripple or death never stalls on a shader compile).
- Clean quit: fx releases its GPU resources when its node leaves the tree; `FX.clear_static()` releases every live fx at once (G2's `quit_clean`).
- Safe mode (the Compatibility renderer, `play_godot_safe.bat`): fx and world detect it and drop raymarched volumes, distortion and the lens; everything else plays. Hull damage and every weapon mark draw in safe mode too (they are hull geometry plus an overlay mesh, not Decals, so the Compatibility renderer's lack of decal support does not apply); the ion burn uses a cheaper pattern there. Safe mode's glow is simpler than Forward+'s, so a mark's embers and scorch read a little softer from the battle camera there; the r18 PC run shoots the same frigate marks sheet on both renderers (marks_frigate and marks_frigate_compat) as the record. (Muse audit B4.4 read an older document that described decal-based marks; those were replaced in R43.)
- Physics: fx makes its own Jolt rigid bodies (death chunks, debris) with `gravity_scale = 0`, so it works whatever the project gravity is. Please keep `3d/physics_engine="Jolt Physics"` in project.godot (it is the engine the A3 proof measured).

## 2. Ships

```gdscript
fx.add_ship(id, root, info)            # once, when the ship's model is in the scene
fx.remove_ship(id)                     # removes the ship and its effects at once (no death, no wreck)
```

- `id`: the rules unit id (String) from `view()`.
- `root`: the ship's Node3D. **Ship frame:** bow along local +X, up +Y. G2 mirrors each hull in z under the root (main 680c6ea), so root +Z is **starboard** on screen and -Z is port; fx follows that by default (`setup({"starboard_z": 1})`, the default; pass -1 for an unmirrored root where +Z is port). fx finds every hull point from the real, transformed triangles, so mirroring never puts an effect off the hull; only the facing quads (0 prow, 1 starboard, 2 rear, 3 port) use this setting. G2 turns the root for facing and moves it along paths; fx effects attached to the ship follow it.
- `info` (all optional except `faction`):
  - `faction`: `"voidsworn"`, `"hegemony"`, `"corsair"`, `"chorus"`, `"ithar"`, `"deathless"`;
  - `meshes`: Array of the hull MeshInstance3Ds. **Pass `sv.meshes` from ShipView** (the default, every MeshInstance3D under `root`, would also take in the selection ring and the footprint marker). fx reads their triangles (hit points, breach placement, death pieces) and hides them at the break-up of a death. From damage stage 2 fx swaps in a rebuilt copy of a damaged hull's mesh (same vertex format; section 14). Damaged surfaces use a private shader material that keeps the hull textures and PBR settings while adding mouth discard and dark back faces, so G2 must not cache or reassign `mesh` on these nodes during a battle;
  - `cls`: the template class (`"Frigate"`, `"Cruiser"`, `"Squadron"`, ...) and `size` (the data.js draw scale); together they pick the effect weight (light, medium, heavy, capital);
  - `squadron`: true for strike-craft wings (no shield bubble, no damage ladder, small death);
  - `shielded`: default true for Voidsworn, Hegemony, Corsair and Ithar, false for Chorus and Deathless (R3: shields keep faction colours);
  - `flagship`: true adds weight to its death.
- ShipView's placeholder engine glows (`sv.engines`) should be hidden once fx is on (fx draws the engines). Since r13 fx also hides them itself, every frame, for any ship it runs (they sit at fixed spots behind the stern, not on the real nozzles).
- Engine trails start automatically: the hot core, the plume and the long cooling trail per faction (Corsair sputters and coughs soot). The trail bends behind a moving ship by itself (fx watches the root's motion). Optional: `fx.set_engine(id, level)` with 0 off, 1 cruise (default), 2 full burn (during a `move`, if G2 wants the extra flare).
- Where the engines are (r13): on A4 kit ships, from the `hp_eng_<n>` hard points (exit point, `extras.radius`, plume along the node's -Z), so cores, plumes and trails come out of the real bells and follow each bell's own direction; hulls without them keep the stern-face guess. The drive glows full only while the ship thrusts (fx sees the root move, or `set_engine` above 1); a parked ship keeps a dim pilot glow (30% of cruise) and a short faint trail. A level below 1 during a move (G2's braking dim) is kept.

### Keeping the damage look in step: `sync_ship`

```gdscript
fx.sync_ship(id, unit)                 # unit = this ship's entry in api.view().units
```

Call it after the events that changed a ship have been animated (or simply after every event batch: it is cheap and only acts on changes). From `hp/maxHp`, `sec` (prow, mid, eng), `sh`, `burning` and `dead`, fx sets the staged damage ladder per section:

| Stage | When (per section, hp fraction) | Look |
|---|---|---|
| 0 intact | above 0.8 | clean hull |
| 1 scorched | 0.6 < f <= 0.8 | spreading scorch and secondary burns, up to 2 surface marks; transition sparks, no persistent emitter |
| 2 dented | 0.4 < f <= 0.6 | an anchor dent or material-specific concavity, wider surface damage, up to 3 marks; smoke starts |
| 3 fissured | 0.2 < f <= 0.4 | a deep crater and buckled sealed fissure over intact dark skin; up to 4 marks, fire and smoke, a slow vent on heavy hulls |
| 4 hull breach | f <= 0.2, or broken | the first open break: throat radius 0.032 L, stepped torn collar, recess 0.17 L, three cross members and seated fire; medium hulls up get a second break; transition sparks and debris |
| 5 wreck | `dead` (after `death`) | see section 5 |

- R80 owner rulings govern this ladder. Stage 3 and every weapon mark stay sealed. Squadrons keep stage 0 surfaces and trail pooled smoke below half total HP.
- A stage that goes up while shots are still flying at that ship waits until they land, so holes open when the hit lands, not before.
- Repair seals a stage 4 break with a material-specific patch and keeps dents, scorch and weapon scars. Removed emitters fade within 0.8 effect seconds. Chorus knits over 3 seconds.
- `burning` shares the section emitter allocator. Per-ship caps (fire, smoke/vent): light (1, 2), medium (2, 3), heavy/capital (3, 4). Persistent emission spends zero counted flashes. Safe mode keeps flat marks and drops deformation, breaks and emitters. A broken `eng` section makes the engines sputter. Shields rising play a short faction-coloured regen shimmer.

## 3. Weapons

```gdscript
var r = fx.volley(attacker_id, kind, target_id, opts)
# r = {"impacts": [seconds from now, per shot], "done": seconds until the volley's picture is over}
```

- `kind`: the rules weapon kind, one of `battery`, `flak`, `lance`, `torp`, `bio`, `gauss`, `sq`.
- `opts` (all optional):
  - `weapon_id`: the data.js weapon id from the `fire` event (`weapon_id`: `hbattery`, `ion`, `startorp`, ...). It picks the faction look (Hegemony plasma, Ithar prism needles, Corsair rocket pods, Deathless doom arc ...) and the weight;
  - `shots`: the `fire` event's `shots` (Array of bool, hit or miss). Misses fly past the target and fade;
  - `hits`: the `hit` events of this volley in order, each `{shield, hull, section, crit}` (copy them from the events). `shield > 0` lights the target's shield bubble at the impact (in the target's faction colour); `hull > 0` hits the hull in `section` with sparks, debris, a scorch and (crit) a bigger blast;
  - `quad`: the target facing that was hit (0 prow, 1 starboard, 2 rear, 3 port), from the `fire` event: impacts land on that side;
  - `pd`: rockets shot down by point defence (torp volleys): that many torpedoes are intercepted short of the target with an airburst;
  - `late`: true when the shots are fired on the move (`move.late_fire`); fx fires from where the ship is at that moment.
- The look per kind (A5 sheets, R16): battery ripples gun by gun with muzzle blast, flame tongue, smoke ring and tracer; flak bursts in the air; lance charges, holds a white-hot beam and cuts a molten trench; torpedo vents, flies a trackable body with a long plume and lands as the heaviest blast; bio spits wobbling globs that splash and corrode; gauss charges its coils, crosses almost invisibly and punches through with an exit spray; sq craft fly a strafing run.
- Guns fire from mounts on the side facing the target and never backward (CLAUDE.md); a target behind the ship is engaged by turret mounts on top.
- Every hull hit leaves its weapon's own mark in the hull itself (R43, section 14): a sealed lance trench, a light blue plasma splash crater with a droplet fan, sealed gauss entry and exit craters, a torpedo blast crater, flak pockmarks, Chorus acid pitting with spines, an ion branching burn, a ram crumple (and a smaller one on the rammer's bow). Shield-only hits leave no hull mark.
- Every hit also moves the ship (R50, section 7): mass-scaled, by the weapon's momentum.
- Plasma is light blue whoever fires it (Ryan, Oct 26): bolt, splash and crater.
- Issue 461 (the hits, upgraded; docs/playbooks/deaths_and_hits.md): each weapon family has its own hull-hit recipe (`fx_weapons.family_of`: shell, energy, lance, torpedo, bio), sized by `LADDER_PX` times the firing hull's band (`GUN_K`) times the hit hull's band (`TARGET_K`). What a hit throws lives its own life (`SPARK_LIFE`, `DEBRIS_LIFE`, `GAS_LIFE`, `EMBER_LIFE`; flame keeps the 0.70 s cap, `FLAME_CAP`) and leaves the plate along its outward side. `fx.light(p, t, life, peak, col, shape, reach)`: `reach` (world units) carries a light further and with a slower falloff (`REACH_ATTEN`); torpedo hits (36) and death core flashes (26, 35, 52 by class) use it. Tests: set `fx.dstate["hit_logging"] = true` and read `fx.dstate["hit_log"]` (`fx/test/hit_recipe_check.gd`).
- `impacts` are the moments to show floating numbers; `done` is when G2 may start the next event (G2 can start earlier; effects overlap fine).

Travelling torpedoes (B3; ready now, for when the rules change lands):
- `fx.torp_lane(lane_id, attacker_id, to_point, turns)`: a lane on the board from the attacker's bow to `to_point` (world), chevrons running toward an impact marker that pulses, in the attacker's weapon colour;
- `fx.torp_launch(lane_id)`: the torpedo vents, runs out along the lane and holds there, engine burning, until the next turn;
- `var r = fx.torp_strike(lane_id, target_id, hit)`: the two-stage warning (a dim pulse, then a ramp to white, about 0.8 s, K2 pin), then the torpedo closes and strikes (`hit` as in `volley` hits, or `{}` for a miss); returns `{impacts, done}` like `volley`;
- `fx.torp_lane_clear(lane_id)`: the target got out of the lane; the torpedo runs on past the marker and burns out.
Today's rules still resolve torpedoes at once: `volley(..., "torp", ...)` plays launch, flight and impact in one go.

## 4. Shields

- Shield hits come with `volley` (`hits[i].shield > 0`).
- `fx.shield_break(id, quad)` on the `shield_down` event: the bubble comes apart from the struck facing outward, each faction its own way, and stays see-through while it does (r5): Voidsworn, the gold veil cracks into sheets that flare as they peel loose; Hegemony, the hex lattice shatters cell by cell (each cell fills bright and pops out, shards fly); Corsair, it sputters out in patches that stutter on and off and die (slow breathing with reduce flashing); Ithar, the veil sheets away from the struck side (unchanged while the Ithar look is under review).

## 5. Death and wrecks

```gdscript
var t = fx.death(id, cause)            # seconds until the break-up has played; the wreck stays after
fx.clear_wreck(id)                     # optional: remove the wreck pieces (e.g. at battle end)
```

- `fx.well` (Vector3): the dead star's position; `world.build` sets it on `fx` when given `"fx": fx` in its options (tidal deaths fall toward it).
- `cause` from the `death` event: `cut` (lance: the hull splits along a glowing cut), `big` (torpedo or ram: directional shrapnel), `flay` (gauss: perforated and peeled, many small pieces), `melt` (acid or spines: corrosion glow and sagging, few pieces), `dark` (burn-out: a whole cold drifting hulk), `tidal` (the dead star: pieces pulled toward the well), `blast` (anything else). `hulk` explicitly selects the same whole-hull outcome for a probe or caller.
- Cruiser class and above, plus any flagship: running-light emission and engine glow die over 0.3 s, narrow fire/gas jets start on the future split, one thermal tear grows, the hull breaks into uneven pieces at 1.38 effect seconds for a cruiser (2.0 for a capital), then one counted core flash follows 0.28 s later. The 0.16 s flash sits at the visible lip of a torn face, with a contained 0.42 s volume only when the flash budget allows it. Local debris, smoke and sparks mark the split. The pieces carry edge fires/gas and ten small secondary explosions in total, staggered from 0.7 to 3.5 s after splitting. The split stays visible. Bright secondary pops use the shared flash limiter; reduce flashing substitutes soft lifts. Slow coals cool over about ten seconds after the flames subside.
- Smaller ships: 0.72 s of visible hull spin (0.55 s for craft), a curling smoke/fire ribbon, then an immediate 0.22 s counted pop, shrapnel streamers and tumbling wreck pieces. Smoke has a 44 px floor, ribbon fire 28 px and the core 60 px (all at 1080 lines, scaled by `min_px`). Death fire/core sprites keep their brightness at that floor; explicit smoke/gas floors keep opacity. The ribbon follows the spinning visual mesh and stretches backward before the burst. The surviving chunk keeps fire, smoke and slow-cooling coals. Only visual meshes move during the spin; the shared root and battle outcomes do not change.
- Whole hulks: all `dark`/`hulk` deaths power down, leave a whole copy of the damaged hull at 0.72 s, vent gas from one surface point, and drift cold. No core, fire, secondary explosions, sparks, lights or slow-motion beat. Other explicit causes retain breakup. Returns 1.32 s; the copy survives removal of the original ship root and follows `clear_wreck` and the 24-wreck cap.
- Wrecks retain the existing Jolt bodies and the 24-wreck cap. Ribbons and streamers use the existing particle pools and debris ring. Unfinished cuts are polled without blocking the main thread; a finished previous cut is reused when available.
- Authored recipe ships: the version 1 `voidsworn_destruct` GLB extra and interior surfaces are defined in `docs/ship_pipeline/RECIPE.md`, stage 7. `fx_hull.gd` reads them in the installed hull's scaled frame. Damage opens the exterior onto the authored decks, frames and machinery; death carries those surfaces into its pieces. Authored joints guide the irregular fracture, retaining the missing bite, chips, ragged rims and faction matter. Their count follows the build's structure. Ships without that extra keep the #167 procedural cavity and capped-face fallback.
- Main rigid wreck pieces lock linear Y at the altitude where they separated, and their release velocity has zero Y. They can still tumble. This keeps physics contacts from pushing the main wreck below the board where Ryan cannot see it (`death_plane_check.gd`); it is an existing visibility protection, not a restriction on the rotation or every small thrown fragment. Kinematic main pieces also receive zero Y release velocity.
- fx hides the ship's own meshes at the break-up. G2 can keep or free the root after `t`; fx keeps its own copies of the meshes.
- `fx.jump_out(id)` for `fled`: a short drive flare and streak, then the ship's meshes are hidden.

## 6. Other events

- `fx.ability(id, ab)` and `fx.command(id, cmd)`: a short faction-coloured pulse on the ship (a stand-in until each ability gets its own look; coming).
- `fx.launch(carrier_id, squadron_id)`: bay flare and craft streaming out toward the new wing.
- `var t = fx.board(attacker_id, target_id, result)` on the rules' `board` event: a breach in the target's hull at a plausible boarding point (its side facing the attacker, mid section), venting gas and lit from inside for about 3 s, then a dark gash that stays as a mark. Returns seconds until it has played. (G2: this replaces the stub flash at the board event.)
- `fx.hull_mark(id, look, w, world_p, dir, sec)`: a weapon mark without a volley (look as in volley, plus `board` and `ram`).
- `fx.tick(id, kind)` for turn-start damage (`fire`, `acid`, `tidal`, `storm`): a small flare-up of that kind on the ship.
- `fx.hull_point(id, section, toward)`: `{p, n}` in world space on the hull (section `"prow"`, `"mid"`, `"eng"` or `""`, on the side facing the point `toward`), for anything G2 wants to anchor there.

## 7. Feel: shake and hit pause

- Shake is a trauma model (trauma squared, smooth noise, decays), positional only, applied to `cam.h_offset` and `cam.v_offset`. Battery light, lance and gauss medium, torpedo heavy, capital death heaviest, all inside the A5 ranges (0.15 to 0.30 s normally, 0.35 to 0.45 s only for capital deaths), and smaller with distance from the camera. `setup({"camera": null})` turns it off; then read `fx.shake_offset()` (a Vector2) and apply it yourself.
- Hit pause never blocks input: fx slows its own clock for a few frames on heavy weapon hits. Deaths use a separate R73 beat only for cruiser class and above or flagships, independent of their draw scale. It runs at 0.35 speed for 0.48 real seconds, with a short recovery (measured under 0.64 s total at 30/60/144 Hz). Small kills add no pause. `fx.anim_speed()` reports the presentation speed; wreck velocities follow it without touching `Engine.time_scale`, input or rules.
- `fx.hurry_death()` immediately clears the active beat and suppresses a queued death beat for three effect seconds. The only hook outside `fx/` is four lines in `scenes/battle/battle.gd`: the existing Enter/Space hurry branch calls it, and a death started while already hurrying calls it too. No rule or result logic changes.

### Hit reactions (R50)

A hit no longer just flashes: the ship reacts with its mass, in three beats (r5, after Ryan's "no cartoon push back"; the ship never springs out and back):

1. **Onset:** the kick builds over a few frames (0.03 s for craft up to 0.16 s for a capital hull, whose mass soaks it up) while a structural shudder runs through the hull (lower and longer in big hulls: 11 Hz for craft down to 4 Hz for capital ships; big hulls show more shudder than motion).
2. **Arrest:** a moment later the attitude thrusters fire and brake the spin and the slide at a steady rate, a visible burn of gas puffs at the hull's corners picked to oppose the motion, over 0.35 s (craft) to 1.2 s (capital).
3. **Recovery:** once stopped, the helm brings the ship back level and onto its hex, slowly and without overshoot (critically damped).

**Zoom punch (F3).** `fx.punch(t, amount, pos)`: the camera's field of view narrows by `amount` (0.01 = 1%) over about 0.05 s and eases back over about 0.4 s; smaller far from the camera (amount / (1 + distance / 400)), never more than 6% at once. fx plays it on heavy gauss slugs (0.8%), crits (0.6%), torpedo and ram hits (1.4%) and kills (1% for a light ship up to 3.4% for a capital, more for torpedo kills and flagships). fx writes `camera.fov` only while a punch plays and puts the camera's own value back after; if G2 or the camera rig changes the field of view meanwhile, fx takes the new value as the base. `fx.punch_now()` is the current punch (0 when none).

Torpedoes and rams shove, shells and gauss slugs kick, light guns tap, lances and ions are energy and barely move a ship. Mass by class: a frigate takes a real jolt (a torpedo rolls it about 6.6 degrees at its peak, about 0.6 s after the hit, and slides it 3% of its length; settled in about 3.4 s); a super-dreadnought barely moves (a torpedo: about 1.4 degrees, peaking after 1.3 s; settled in about 5 s). Heavy hits also make the drive stutter. The camera shake (above) scales with the hit and distance and follows `shake_scale`. Measured by `fx/test/fx_react_probe.gd` (it also writes a per-frame trace and, with PROBE_CLIP=1, clips).

**For G2 (shared root):** fx writes the ship root's `rotation.x` and `rotation.z` (roll and pitch; ShipView never writes them) while a reaction plays and sets them back to 0 when it settles. Yaw and the small drift are added to `rotation.y` and `position` only while `root.busy()` is false (ShipView writes position and yaw itself during a path); fx takes its own offset back out when the ship settles, and drops it when a path starts. G2's weighty movement (R50 part 2) can keep its own RCS puffs for turns and burns; fx's puffs only answer hits. If G2 later wants to own the whole root, `fx.ship(id)._ra` (angles) and `_pd` (drift) are the state to read instead.

## 8. Accessibility

- At most 3 counted flashes in any rolling second anywhere on screen (WCAG 2.3.1). Flashes landing within 0.12 s of each other (a salvo) count as one (`FLASH_WINDOW` in fx.gd). The count is a trailing window: the second up to a flash may hold at most 3 counted flashes, that one included (a flash booked ahead by a volley also keeps its own trailing second within 3). Over the budget, a flash draws as a soft lift, smoke and sparks without the bright core, and draws no light.
- What counts: every short (0.6 s or less), bright (intensity 4 or more) flash-like sprite (flash, fireball core, beam charge, impact flare) that covers at least 6% of the screen height, whoever spawns it (the check sits in `fx.spr`, so muzzle cores, beam contact, secondary pops and death flames are all covered), and every decaying event light with a peak of 8 or more. Smaller flashes and sparks are under the WCAG area threshold at battle zoom and are free; close up they count. `fx.flash_log` lists every counted flash (the smoke test fails if any rolling second holds more than 3).
- Issue 504 (Nov 11 2026), counting by area as W3C Understanding SC 2.3.1 does: "the combined area of flashes occurring concurrently" within "any 10 degree visual field" may not pass a quarter of it. `fx.flash_at(p, T, size, px, life)` replaces `_flash_sized(...) and not flash_ok(T)` at every caller: each bright flash is a disc as wide as it is drawn (its pixel floor counts), every bright flash whose bright time overlaps it is added up inside each 10 degree box that could hold it (on a lattice a quarter of the box apart, each tested box one step wider, so areas round up), and only a total over `flash_limit_px2()` is a general flash, counted against the same 3 a second or refused. The limit is the smaller of the guideline's 0.006 steradians and a quarter of its 341 by 256 rectangle estimate, both turned into pixels from one stated set-up, `flash_screen_in` 32 and `flash_view_in` 24 (a 32 inch 16:9 screen at 24 inches: 10 degrees is 289 px at 1080 lines, the limit 15,606 px2); setup opts `screen_in` and `view_in` change it. Flash is gathered in a 10 by 10 degree square, which only gathers more. `flash_ok(T)` still counts unconditionally (vent ignition, death core, lights of 8 or more). A refused flash keeps its size, colour and smoke as before and now keeps its light too, rising softly (shape 3) just under the peak that counts. Reduce flashing is unchanged. Check: `fx/test/flash_area_check.gd`.
- `fx.reduce_flashing = true`: no counted flashes at all, and every bright flash-like sprite becomes a soft lift whatever its size (WCAG 2.3.2). Bright pops become expanding rings, particle bursts and a gentle glow rise; muzzle flashes become smoke-forward; fire flicker becomes slow breathing; effect shake halves.
- `fx.shake_scale` (0..1) at any time.
- The F3 zoom punch (section 7) is halved with reduce flashing and scaled by `shake_scale` (off when shake is off). The F3 on-screen floors (section 16) never add a counted flash: a grown sprite dims as it grows and stays far under the 6%-of-screen size that counts.

## 9. World (`godot/world/`)

```gdscript
const WORLD = preload("res://world/world.gd")
var w = WORLD.new()
world_node.add_child(w)
w.build(view(), {"biome": biome, "fac": enemy_faction, "hex_world": func(q, r) -> Vector3, "camera": cam, "environment": env, "quality": "max", "fx": fx})
w.update(delta)                        # or let it run its own _process (default)
```

- Backdrop per battle: sky with nebula tinted per enemy faction (the game's BIOMES colours), one planet or moon at most (no twin moons), no stray traffic ships, no rocks over moons.
- The dead-star board (`view().map.deadstar`): the black hole at that hex with gravitational lensing of the scene behind it, a photon ring and a turning accretion disc (R2, R24). The gravity-well rules stay as they are; this is only the picture.
- Terrain from `view().terrain`: faceted asteroid blockers on `rock` hexes (tall, sharp, varied per biome rock kind: stone, ice, iron, carbon, crystal), sparse dressing off the playable hexes, debris fields, hulks and wrecks.
- Pass G2's own hex-centre function as `hex_world` (G2 uses `x = HEX_W * (q + r/2)`, `z = +1.5 * HEX_S * r`, which keeps the board the same way round as the browser game); the world never computes hex centres itself.

## 10. Look (`godot/render/look.gd`)

```gdscript
const LOOK = preload("res://render/look.gd")
LOOK.apply(env, key_light, fill_light, {"quality": "max"})   # tonemap, exposure, glow limits, ambient
LOOK.hull(material, faction)                                # per-faction hull material fix (dark hulls: Chorus, Deathless)
```

Tonemapper, exposure, bloom threshold and the dark-hull lift are chosen in look.gd and explained there.

## 11. Rules events to fx calls (the whole mapping)

| Event | fx call |
|---|---|
| (battle start) | `add_ship` for every unit, `world.build(view(), ...)` |
| `move` | animate the root along the path (G2); optional `set_engine(id, 2)` during it, then `set_engine(id, 1)` |
| `fire` + its `hit`s | `volley(unit, kind, target, {weapon_id, shots, hits, quad, pd, late})` |
| `shield_down` | `shield_break(unit, quad)` |
| `section_down`, `system`, `burning`, `tick` | `sync_ship` after it (and `tick(id, kind)` for `tick`) |
| `death` | `death(unit, cause)` |
| `wreck` | nothing: the wreck is already there |
| `fled` | `jump_out(unit)` |
| `ability`, `command` | `ability(unit, ab)`, `command(unit, id)` |
| `ram` | `volley(unit, "torp", target, {weapon_id: "ram", hits: [...]})`: the ram's crumple on the target, a smaller one on the rammer, the biggest shove |
| `board` | `board(unit, target, result)` |
| any batch end | `sync_ship(id, unit)` for the units that changed |

## 12. Cost

Ryan's PC (RTX 5080), 4K max detail, the gallery's 26 s reel (`godot/fx/gallery/README.md` has the table): everything 5.78 ms a frame against 4.18 ms with no effects, so the effects layer costs about 1.6 ms; the world 0.5 ms; physics 0.03 ms. High quality saves about 1.75 ms. Call `fx.warmup(cam)` on the loading screen so no shader compiles mid-fight; it also lights every warmed material once with an omni light (the Compatibility renderer compiles a material's point-light pass on first use) and makes the first Jolt bodies a death uses, off screen.

Profiling: `fx.prof` holds microseconds of fx's own main-thread work per section (`volley`, `death`, `break_up`, `debris`, `breach_apply`, `hull_gather`, `cut_start`, `piece_meshes`, and the per-frame `later`, `ships`, `weap_death`, `lights_pools`) since the last `fx.prof_take()`. The gallery's 20-ship bench lists, for every frame over 33 ms, that breakdown for the frame and the one before, plus process, physics and render times.

## 13. Drop-in event player (a sketch for battle.gd)

```gdscript
func play_event(e: Dictionary) -> float:     # returns how long to wait before the next event
	match e["t"]:
		"fire":
			var hits := []
			for h in pending_hits(e):              # the "hit" events that follow this "fire" in the stream
				hits.append({"shield": h["shield"], "hull": h["hull"], "section": h["section"], "crit": h["crit"]})
			var r: Dictionary = fx.volley(str(e["unit"]), str(e["kind"]), str(e["target"]),
				{"weapon_id": str(e["weapon_id"]), "shots": e["shots"], "hits": hits, "quad": int(e["quad"]), "pd": int(e.get("pd", 0))})
			return r["done"]
		"shield_down":
			fx.shield_break(str(e["unit"]), int(e["quad"]))
			return 0.3
		"death":
			return fx.death(str(e["unit"]), str(e["cause"]))
		"fled":
			fx.jump_out(str(e["unit"]))
			return 0.5
		"ability":
			fx.ability(str(e["unit"]), str(e["ab"]))
		"command":
			fx.command(str(e["unit"]), str(e["id"]))
		"tick":
			fx.tick(str(e["unit"]), str(e["kind"]))
	return 0.0

# after each batch: for u in api.view().units: fx.sync_ship(str(u["id"]), u)
# each frame: your animation delta *= fx.anim_speed()
```

## 14. Hull damage geometry and weapon marks (R80)

From stage 2 the hull itself changes (fx_breach.gd). Rebuilds run on a worker
from the original arrays and retain the hull's vertex format and paint. The main
thread applies the result. Use `test/damage_surface_probe.gd` for measured worker,
apply and frame costs on real hulls; rebuild wall time is not frame cost. Death
pieces are re-cut from the damaged hull afterwards.

**Generic section damage.** Anchors stay put as a wound grows:

| Stage | Hull change |
|---|---|
| 2 | sealed dent/concavity, radius 5% of L, depth 22% of radius |
| 3 | sealed fissure crater, radius 6% of L, depth 35% of radius, raised slot lips over dark intact skin |
| 4 | first open throat, radius 3.2% of L; stepped curled collar about 14% of L across, recess 17% of L, three structural cross members; a second break on medium hulls up |

`wound_kind` in faction_looks.json selects metal (0), living tissue (1), crystal
(2), or Eclipse machine wounds (3). Living hulls use spores and ichor; crystal
uses dust and vapour with no flame; Eclipse uses dead panels, violet circuits,
slow rim arcs, coolant, dark smoke and violet plasma. Repair seals every break.

**Refinement (r5).** Coarse geometry (kit plates and big AI hull panels are a few large triangles) is split locally before a mark is cut: edges longer than the mark needs, near the mark, are split (conforming on both sides, every vertex attribute interpolated, so the vertex format and materials stay), so a hole or crater smaller than a plate is still cut and dented. The overlay skin covers every triangle that reaches into the mark, not only those whose centre does.

**Halo (r5).** Every weapon mark also lays a wide halo in its own signature, at least `HALO_MIN` world units (fx_breach.gd; 0.75 for a lance cut up to 2.1 for a torpedo crater), so it reads from the battle camera 170 units away, where the mark's own detail is a few pixels: soot round shells, torpedo craters and boarding pits; soot with temper colours along a lance cut; dark blue glass freckles with a faint lasting sheen round plasma; a grey rash round flak; green-black etch round acid; a blue-black field round ion burns; bright scraped metal round a ram; a pale spalled field round a gauss exit.

**Weapon marks (R43).** Every hull hit adds a mark entry at the hit point (fx_breach.marks_for, by look and weight), built by the same rebuild as the breaches: the mark changes the hull geometry where its kind needs it and lays an overlay skin with its surface (char, molten metal cooling white to red to black, light blue plasma slag, spall, acid etching, electrical burns, scraped metal).

| Look | Mark | Geometry | Surface |
|---|---|---|---|
| lance, needle, pulsar, las | burn trench | a sealed slot with raised molten lips and a solid floor | molten lips white, then red, then black; temper colours past them |
| plasma (laser, turbo, hturbo) | splash crater | a melted bowl, no hole | light blue slag pockets that set as dark glass, slag runs, a fan of droplets thrown out along the shot |
| macro, battery, rockets | shell crater | a shallow crater | char fan, brief orange slag |
| auto, scatter, guns | chips | small pits, nothing torn through | pockmarks and scratches |
| gauss | entry and exit | small entry crater and larger exit crater, both sealed | a pale, broken stress ring with radial cracks round the entry (reads at fleet distance) |
| torp, star | blast crater | a broad sealed crater bowl | char fan |
| flak variants | pockmarks | a stippled patch, never through the hull | grey rash, brief sparkle |
| spine, tendril, spores | acid pitting | shallow sealed pits; spines stuck in along the shot | wet green-black etching that spreads for a few seconds, then stops and goes matte |
| ion, doom | electrical burn | none | a branching (Lichtenberg) burn, arcs crawling it at first, then a dark etched fern |
| ram | crumple | a deep fold of the plating at the bow or the struck side | scraped bare metal, no glow |
| board | boarding pits | a shallow sealed cluster | char |

Budget: at most 4 marks per hull section and 12 per ship (sections 0 eng, 1 mid, 2 prow). A repeat of the same mark close by (anywhere in the section for a torpedo crater or an ion burn) rebuilds the old one bigger and fresh (up to 1.6 times) instead of placing a twin; past the section budget the oldest shell crater or pockmark goes first, then the oldest mark. Repair retains bounded permanent scars. Fresh stage 1 renders up to 2 weapon marks, stage 2 up to 3, stages 3 and 4 up to 4. Only the stage 4 section entries can cut; section entries sit outside the weapon-mark budget.

Cost (cloud sandbox CPU, about three times slower than Ryan's PC; the PC numbers are in the gallery README once measured): a single mark rebuilds a 38k-triangle hull in 70 to 260 ms on a worker thread; the main thread only swaps in the meshes built there (a few ms). All rebuilds start from the hull's original arrays and keep its vertex format, so nothing compiles.

**Legacy A4 pre-cut part format (Oct 26; not the live R80 ladder).** Per ship:

1. The ship's glb: the root mesh is the hull minus the breach patches; children `skin_<n>` (the patch a hole replaces)
   and `skin_<n>_heavy` (the extra ring the heavy damage tears away), visible by default, identity transform, same
   material as the hull. Root mesh plus all skins is the intact ship. extras: `kind = breach_skin`, `breach = n`, `heavy`.
2. `<CODE>_damage.glb`: root `<CODE>_damage`, children `breach_<n>_hole` and `breach_<n>_heavy`, hidden at first. Up
   to five surfaces by material name: `<CODE>_hull` (the bent plates in the ship's paint; fx gives this surface the
   material the hull's surface 0 really uses at runtime, so it carries the faction look), `damage_interior` (bare
   metal backs, the cavity wall), `damage_frame` (frames, stringers, decks, conduits), `damage_glow` (fire spots, lit
   conduit bands, torn sparking ends; emissive 1, HDR colour in albedo and emission), `damage_edge` (hot torn edges;
   emissive 0.5). fx scales the glow itself against exposure and the flash rules. extras on each node: `kind`
   (`breach_hole` or `breach_heavy`), `breach` n, `section` (prow, mid, eng by x), `p` (anchor point), `n` (outward
   normal), `r` (radius, ship units), `hides` (the skin node names to hide).
3. Everything is in the hull mesh's own frame. fx parents `<CODE>_damage` under the hull mesh's parent with the hull
   mesh's transform, so it inherits G2's scale and mirror.
4. Legacy swap, retired by R80: stage 3 shows `breach_<n>_hole` and hides `skin_<n>`; stage 4 shows `breach_<n>_heavy` and hides
   `breach_<n>_hole`, `skin_<n>` and `skin_<n>_heavy`. The anchor is the same n as `hp_breach_<n>`; fx picks the anchor
   for a section from `extras.section`, puts its fire, gas, sparks and embers at `p` along `n`, and keeps the generic
   cut away from that anchor. Stage 2 dents stay generic.
5. **G2's part:** res://gen hulls are a single Mesh today, so the `skin_<n>` children would be lost. fx looks first for
   (a) the hull scene in gen with `skin_<n>` MeshInstance3D children named exactly that, plus
   `res://gen/damage/<CODE>_damage.scn`; then for (b) `res://assets/ships/<CODE>/<CODE>.glb` and `<CODE>_damage.glb`.
6. Death pieces: the wreck is built from the hull as it is at the time of death (intact parts plus whatever is cut).

## 15. Faction looks as data

Every faction colour and style the effects, hull fix and backdrops use comes from `res://fx/faction_looks.json` (read by `fx/faction_look.gd`; `FLOOK.of(faction)` returns the entry, `fx.faction_info(f)` the same). Fields: `weapon`, `shield` (null: no bubble), `engine`, `shield_style` (0 veil, 1 hex lattice, 2 patchy, 3 prismatic), `trail`, `shielded`, `engine_extra` (none, soot, spores, embers), `damage_glow` (fire inside hull damage), `hull_fix` (look.gd's rim and lift for dark hulls), `nebula` (the battle sky when this faction is the enemy), and two fields ready for the coming lore looks, both null today: `accent` (a second effect colour; when set, a corona glows round each engine core, for example the Deathless white-gold corona) and `shield_edge` (a colour or `"rainbow"` on the shield bubble's rim, for example the Ithar crystal). A repaint is an edit to the json; nothing in code names a faction's colour. The json ships in the export (`include_filter="*.json"`). Ids never change.

## 16. Effects at distance (F3, feel pass Nov 1)

Ryan's first playtest: "effects looked very weak, especially at a distance and for smaller ships." Two causes, two fixes (Claude's calls, vetoable; numbers in docs/shots/f3/):

- **Minimum on-screen size.** Every effect sprite, streak, ring and beam had a size in world units only, so a frigate's tracer (0.26 units wide) was 2 px from the battle camera and a third of a pixel fully zoomed out, where it dropped out of the raster. The effect shaders now keep each kind at least a few pixels across, counted on a 1080-line screen so it looks the same at any resolution (`px_world` in fx_shaders.gd; the global `fx_px` scales them all, `setup({"min_px": 0})` turns them off): pops and the star torpedo 14 px, fireball cores, beam contact flares and plasma bolts 12 px, beam charges, bio globs and soft glows 10 px, squibs, prism glints and strike craft 9 px, flames 8 px, embers and hot spots 4.5 px, engine cores 3 px; tracers and bolts 2.6 by 14 px, sparks and drips 2 by 4 px; beams 3.5 px wide (needle 2.5, engine plumes 2); shock rings 12 px. A grown effect dims as it grows but by less than its area, so small and far effects read brighter without blowing out. Smoke, soot and gas have no floor (no grey haze at distance). Shield hits keep their core, ripple and spread a few pixels wide too.
- **Small ships' effects at a usable size.** Effects scale with the ship (`scale_k`: frigate 0.43, super-dreadnought 2.07). Fire visuals now use at least 0.75 and impact visuals at least 0.85 (`VIS_K_FIRE`, `VIS_K_HIT` in fx_weapons.gd); geometry (gun mounts, hull marks, hit points) keeps the true scale. A small ship's cook-off pops use at least 0.65.
- **Hits that last and land.** Shell and bolt hits pop a little longer (0.16 s) and leave a soft afterglow (about a second, below the flash brightness that counts) and a hot spot cooling on the plate (1.6 s); sparks live 0.4 to 0.9 s (were 0.25 to 0.6); hull lights 7.5 for 0.32 s (were 6 for 0.2; still under the light peak that counts as a flash). Beams leave a glow where they cut; torpedo hits a two-second glow and a longer light; bio splashes a green working glow.
- **Shield hits read as that ship's shield.** A hit lights the whole bubble faintly in its faction colour and pattern for about half a second (stronger when the camera is far out), on top of the hit's ripple; the hit's glow stays on the bubble for most of a second; ripples are 30% stronger.
- **Kills.** The current staged sequence is in section 5. Wreck heat and the brief core carry the aftermath, with a small zoom punch (section 7).
- **Hits land where the camera can see them.** `hull.hit_point` scores each sampled point by facing the shooter and also by facing the camera (`fx.camera`), and the shot strikes the first plating on its line, so a blast never goes off wholly behind the hull (on the Eclipse Tomb-ark's ring a torpedo used to strike the underside, out of view).
- **Glow (look.gd).** A little of the wider glow level 4 (0.25) and a touch more of level 3 (0.6), so a small bright effect far out gets a halo a few pixels wider than itself.
- **Proof tool.** `fx/test/fx_range_probe.gd`: every weapon family from a frigate and from a capital, at a ship of its own size five hexes away, from the default battle camera and fully zoomed out; one sheet per family and size, plus a kill sheet (a torpedo kill: just before, the break-up, 0.6 s and 2 s after). `PROBE_TRACE=1` adds frames round each first impact from three views with every shot's hit point printed (`volley` opt `debug`); `PROBE_QUALITY` picks the quality. The gallery's `--clip DIR` (with `--fleet 20`) films the 20-ship battle from the battle camera. PC jobs that set `PROBE_*` must use `setlocal` (the queue runs every job in one session).

### Round 2 (Nov 1, after Opus's read of round 1 and Ryan's 16:12 note on hollow wrecks)

- **Per-effect sizes on screen.** `fx.spr(..., px)`, `fx.sprx(px, ...)`, `fx.stk(..., wpx, lpx)` and `fx.ring(..., px)` give one effect its own minimum size in pixels (1080 lines), on top of its kind's floor; a sprite or line grown to its own floor dims less (f^-0.5 and f^-0.3), so the moments that must land read as big bright bursts, not big faint ones. A ring's px is its final size: the floor grows with the ring, so a far shock ring still expands. (Sprites carry it in the seed's whole part, streaks in a4.zw, rings in a4.w.)
- **Pops and the flash budget.** `fx.pop` (and every bright sprite) books a counted flash only when it is drawn at 6% of the screen height or more (`_flash_sized` now counts the pixel floor). Before, every pop booked one, so in a busy fight most hits, and a dying ship's cook-off, used up the 3 a second and drew as faint lifts, and the kill's own blast was refused. WCAG 2.3.1 counts flashes by area; the cap is unchanged for big ones and reduce flashing still turns every bright pop into a soft lift.
- **Impacts by weight** (`HIT_PX` in fx_weapons.gd: 34, 46, 56 px for light, medium, heavy; plasma +6, at most 62): the hit flash, a hot core, longer sparks with their own length, glowing debris embers, the afterglow and hot spot at a size you can see, and a hull light at 7.9 (just under the 8 that counts) held 0.42 s, placed further off the plate so it lights a patch of the target's hull. Laser and prism hits flash in their own colour; prism hits throw spectral glints.
- **Muzzles** (`MUZ_PX` 20, 26, 32 px; `_muzzle`): every gun shows a flash and a short light on the firing ship. Autocannon: a four-shot brass stutter with fat short tracers; laser turret: long hard faction-coloured bolts with a white core (4.6 by 30 px); flak: airbursts round the target with a pale burst ring; gauss: a white discharge, a fat shock ring and an instant bright wake, then a punch ring at the hit; prism: needles riding spectral glints.
- **Shield hits:** a faction-coloured ripple ring racing out over the bubble and a coloured glow, 36 to 64 px by weight, on top of round 1's bubble flash.
- **Kills** (fx_death.gd): superseded by the staged sequence in section 5 and destruction round 2 below.
- **Nothing hollow:** the round 2 lit-room treatment is superseded by destruction steps 1 to 3 below. Wreck pieces still vent atmosphere from their torn edges.
- **Proof tool:** `fx/test/fx_inside_probe.gd` (close stills of two breaches, the damaged ship at kill-zoom distance, and the break-up from the battle camera and from close, plus a look into the biggest piece; `PROBE_BOX=1` runs it on a box hull without res://gen).

### Destruction steps 1 to 3

1. **Burnt interior (`fx_hull.gd`).** Live damaged hulls and death pieces draw both sides. Back faces are near-black with sparse, steady warm embers. No lit rooms or ceiling strips. Mirrored hulls keep their exterior facing and lighting. Private surface shaders retain the hull textures, PBR maps and faction rim; shared originals are not edited.
2. **Sealed cuts (`fx_death.gd`).** The existing triangle-bucket breakup is unchanged. Its worker closes exposed mesh edges across surfaces with opaque, layered slag and protruding ribs. Rim heat fades over a few seconds; cold caps stay opaque and follow wreck cleanup. New materials are included in warmup.
3. **Real breaches (`fx_breach.gd`, `fx_hull.gd`).** The actual surface shader discards round, square, slot and cluster mouths and adds soot collars. Hole/slot mouths have recessed, tapered dark throats with opaque backs, even on thin hulls. Embers and subtle smoke start inside through existing batches. Rebuild/repair replaces the cut list; up to 64 mouths, including cluster subholes, with an error on overflow. New shader math is guarded against zero division/normalization and invalid powers. Flash counting, reduce flashing and pools are retained.

Checks: the Forward+ `fx_inside_probe.gd` with `PROBE_BOX=1`; `destruction_steps_check.gd` for sealed edges, mirrors, disconnected pieces, texture retention and cut reset; `fx_smoke.gd` for effects and flash limits (all under `fx/test/`). `DESTRUCTION_OUT` adds isolated hot/cold cap stills to the geometry check. The box probe does not verify real ship assets. From `Downloads\voidsworn_test\build`, `tools\pc\jobs\fx_inside_capture.bat tag` installs `fx_tag.zip`, moves old FX to `..\sync_old\fx_tag`, and captures the three real ships to `..\shots\fx_tag` through `tmo.bat`. Reusing a backup tag fails safely.

### Destruction round 2: cap fans and steps 5/6

- Caps trace welded boundary loops across surfaces, project each outline and ear-clip its polygon. A narrow rim leads to a recessed dark, noise-textured slag face; sparse short ribs do not meet at a centre. Non-planar/self-overlapping imported loops use a boundary-only zipper fallback, never a centre fan. Cold caps remain opaque. The concave, mirrored and disconnected geometry checks cover the sealing contract; real AI hulls still need visual review.
- Capital cuts are prepared as two halves regardless of death cause. Vents and the thermal tear use that same prepared bisector. Hull emission uses the private `fx_power` uniform, including custom hull shaders; detached pieces have no running-light emission. The breach mouth/discard and recessed cavity code is retained.
- The core flash uses `flash_ok`; round 3 below adjusts its timing, visible placement and duration. Heat and particle gates cool smoothly. All new divisors and normalizations are guarded.
- Generated PBR, slag and effect shaders share compiled resources. Weak shader references retain no static GPU objects; `warmup` pins the PBR adapter and actual hull/cap vertex formats until `release`. This removes repeated shader compilation at death. No full-detail hull is decimated.
- `fx/test/check_destruction.bat` runs geometry, staging, smoke, the box capture and a 20-ship Forward+ frame probe. All logs, screenshots and redirected Godot profile/cache files stay under `fx/test/results/`. Pass a Godot executable as the first argument if it is installed elsewhere. `PROBE_CALM=1` and `PROBE_QUALITY=high`/`low` select the visual probe variants; `PROBE_BOX=1` avoids missing real assets.
- `destruction_staging_check.gd` checks class versus draw scale, flagship gating, engine/emission shutdown, small-spin root isolation, two capital halves, a single flash (zero in calm mode), cooling, real-time limits and hurry cancellation. `destruction_fleet_probe.gd` measures 20 box ships at 1920x1080 after warmup; capture readback/file I/O is excluded. This is an effects probe, not a full-detail real-ship battle benchmark.

### Destruction round 3: fire at the split, small kills and hulks

- References copied from `contrib/muse/research/destruction_2026_11/synthesis.md`: Battlefleet Gothic: Armada's readable staged capital split and whole dark hulk; EVE Online's class-capped trailing fires; Star Wars: Squadrons' short death spin with a smoke/fire ribbon; Nebulous: Fleet Command's single gas vent and cold drift. The capital additions implement synthesis step 5's vent, break, contained core and burning aftermath. The 60 px small pop, directional streamers and tumbling ember chunk implement step 6. The hulk implements step 8. Existing Homeworld 3-style breach grading and Highfleet-style opaque backing/caps are retained.
- The core is always counted, even below the ordinary flash-area threshold. Secondary pops call `pop`, so large ones book the existing three-per-second rolling limit and refused/calm ones become soft lifts. No new flash bypasses the limiter. The optional core volume is omitted if the booking is refused or reduce flashing is enabled. Death core kind 24 participates in `FLASH_KINDS`; kind 25 is a sustained narrow fire, without a flash peak.
- Fires, gas, sparks and coals are static batches attached to the drifting pieces. Ribbons, split smoke, shrapnel and secondary pops reuse the existing particle pools; physical debris keeps its capped ring. Per-half fire sites and surface scans are bounded. Piece surface/edge samples are explicitly written back into their packed arrays, retaining their real centres and collider extrema. Geometry, caps, opaque interiors and breach mouths are otherwise unchanged.
- `check_destruction.bat` writes round 3 logs/captures to `fx/test/results/dst4`, captures at 1920x1080, and accepts `FX_CHECK_UNATTENDED=1` to skip its final pause. `PROBE_HULK=1` forces the whole-hulk capture; `PROBE_CALM=1` and `PROBE_QUALITY=high`/`low` remain available. `fx_inside_probe.gd` adds `kill_secondary` (2.25 s) and `kill_embers` (8 s) stills. No Python contact sheets are needed.
- Checks additionally cover retained surface/collider samples, exactly one core before secondaries, the rolling secondary-flash limit, coals that outlast the flames, and hulk vent count, cold drift, independence from the live root and cleanup at both high and low quality.

### Playtest batch 1 (Nov 2)

- Homeworld 3's scar-to-breach grading now follows each section's own remaining hull. Low total ship HP no longer promotes healthy sections to damaged geometry. Weapon marks scale with that section's damage, regrade after later hits, and shrink or clear on repair. Repeat gauss hits retain their original entry frame when rebuilding the exit wound.
- Breach throats are deeper, with opaque recessed backs, internal structure and a continuous lit torn rim. Persistent square chip sprites are replaced by a few soft embers; the plate ejecta use irregular solid shard meshes. Section shard and spark counts are reduced and the shared shard pool holds at most 768 particles on max quality, 384 otherwise.
- Chorus wounds use wet green membranes, curved tissue strands, pulsing faction glow, ichor and spores. Their deaths rupture the skin 0.35 seconds in and spill real hull fragments and spores, with no metal fire, sparks or core flash. Whole hulks retain the independent cavity and scar meshes after the live ship is removed. Glasswright impact chips use the crystal shard tint and spectral light.
- The lane shader's chevrons point and travel from shooter to target. Player torpedo lanes and enemy intent lanes share this shader and UV direction.
- `board.show_blockers(hexes)` outlines the intermediate blockers returned by `api.line_blockers(shooter, target)`. Unreachable-hex tips use `api.entry_reason(id, q, r)`. These calls only explain existing rules. Set-piece hole cells now have solid props; planet, station and Hollow Sun exclusion rims show their exact rule footprints. The planet and station models are retained. Missing station assets and uncovered station edge cells get solid fallback docking hardware.
- World bakes persist as RGBA PNGs under `user://world_bakes/v2/`. Keys include seed/settings, shader source and dimensions; parameter order does not cause rebakes. The memory cache holds 12 images. Cold starts draw a 512x256 sky and 256x128 planet first, then refine after three seconds in serialized GPU strips. Full-resolution cache hits load directly without the preview delay. GPU work stays on the render thread; no gameplay waits for a full-resolution bake.
- After creating the ship views, call `world.use_ship_debris(views.values())`. It reads one loaded hull per faction, cuts four sealed chunks per hull on a worker, preserves UVs and source paint/PBR materials, adds scorch weathering, and installs up to four instances per debris hex. Geometry stays inside the old footprint. No GLB paths are required. Empty source lists retain the existing debris; battles without debris skip the cutting work. Worker shutdown is joined when the world leaves the tree.
- `fx/test/playtest_batch1_check.gd` checks damage grading/repair, organic rupture and retained wounds, loaded stand-in hull cutting, disk cache invalidation/alpha, and both lane directions. `FB1_SHOTS=DIR` captures the four damage examples, lanes, hull chunks and organic rupture on a renderer. These are stand-in hulls, not full-build ship validation.
- `world/test_blockers.gd` checks the real world/board builders over all 12 shapes, five terrain maps and two seeds. It checks solid geometry at blocking hexes, named entry reasons, and agreement between the blocker query and the sight predicate. Headless rock coverage reads the real submitted batch transforms because the dummy renderer does not retain MultiMesh buffers. No background dressing or exclusion-only outline can satisfy ordinary blocker coverage.
- `fx/test/check_destruction.bat` now includes both checks. Results default to `%TEMP%/voidsworn-destruction-<id>`; `FX_CHECK_OUT` overrides that folder. The existing geometry, staging, smoke, box captures and 20-ship frame probe remain included.
