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
- `info` (all optional):
  - `faction`: `"voidsworn"` (default), `"hegemony"`, `"corsair"`, `"chorus"`, `"ithar"`, `"deathless"`;
  - `meshes`: Array of the hull MeshInstance3Ds. **Pass `sv.meshes` from ShipView** (the default, every MeshInstance3D under `root`, would also take in the selection ring and the footprint marker). fx reads their triangles (hit points, breach placement, death pieces) and hides them at the break-up of a death. From damage stage 2 fx swaps in a rebuilt copy of a damaged hull's mesh (same vertex format; section 14). Damaged surfaces use a private shader material that keeps the hull textures and PBR settings while adding mouth discard and dark back faces, so G2 must not cache or reassign `mesh` on these nodes during a battle;
  - `cls`: the template class (`"Frigate"`, `"Cruiser"`, `"Squadron"`, ...) and `size` (the data.js draw scale); together they pick the effect weight (light, medium, heavy, capital);
  - `squadron`: true for strike-craft wings (no shield bubble, no damage ladder, small death);
  - `shielded`: default true for Voidsworn, Hegemony, Corsair and Ithar, false for Chorus and Deathless (R3: shields keep faction colours). A request for a bubble without a shield colour is skipped with one warning per faction;
  - `flagship`: true adds weight to its death.
- ShipView's placeholder engine glows (`sv.engines`) should be hidden once fx is on (fx draws the engines). Since r13 fx also hides them itself, every frame, for any ship it runs (they sit at fixed spots behind the stern, not on the real nozzles).
- Engine trails start automatically: the hot core, the plume and the long cooling trail per faction (Corsair sputters and coughs soot). The trail bends behind a moving ship by itself (fx watches the root's motion). Optional: `fx.set_engine(id, level)` with 0 off, 1 cruise (default), 2 full burn (during a `move`, if G2 wants the extra flare).
- Where the engines are (r13): on A4 kit ships, from the `hp_eng_<n>` hard points (exit point, `extras.radius`, plume along the node's -Z), so cores, plumes and trails come out of the real bells and follow each bell's own direction; hulls without them keep the stern-face guess. The drive glows full only while the ship thrusts (fx sees the root move, or `set_engine` above 1); a parked ship keeps a dim pilot glow (30% of cruise) and a short faint trail. A level below 1 during a move (G2's braking dim) is kept.
- Where every effect starts on the ship (issue 370, RULEBOOK 6.7): the attach point service at the end of `fx/fx_hull.gd`, reading the hard point contract (docs/ship_pipeline/HARDPOINTS.md). Order of trust for each point type: the authored point (`hp_w<slot>_*` muzzles, `hp_bay_*` launches, `hp_core`, `hp_breach_*` wounds, `hp_rcs_*` jets, `hp_board_*` boarding hatches); else a surface ray onto the hull's triangles; else nothing: the effect is skipped, one `[attach]` line is logged per hull, point type and outcome, and the skip is counted. Nothing is ever placed on the bounding box. Calls: `guns(slot, weapon, target, n, bow_first)`, `bay(i, toward)`, `core_point()`, `breach_point(sec, nth)`, `surface_sample(sec)`, `jet(near, through, out)` (ShipView's braking, stern, side and turning jets and fx's hit-reaction jets), `board_origin(toward)`; `shield_centre()` is the core. The battle passes the weapon's slot with each volley (`opts.slot`, the rules' fire event `weapon`). `fx.attach_report()` returns what each ship's requests got (authored, ray, centre, skip) and prints one line per ship when a ship is removed or the effects system is released. A hull with no `hp_core` uses the centre of volume of its own triangles and logs it once as a load error. Checked by `fx/test/attach_check.gd`.
- Turrets (issue 560, RULEBOOK 6.17): a ship's `turret_<n>` nodes (docs/ship_pipeline/HARDPOINTS.md "Turrets") are read by the attach point service with the `hp_w` muzzles under them. `guns()` turns each turret it uses toward the target before its shots (`turret_aim`: the target bearing clamped to the turret's arc and to the yaws where its barrels stay clear of its own ship) and returns each turret muzzle where the turned barrel puts it, with `arrive` (when the turret gets there) and `tur`; the volley holds that shot until then (its lead) and returns `muzzles` (each shot's start point and turret) beside `impacts` and `fires`. After the last shot `turret_release` holds the aim 0.9 s, then the turret trains back to rest. A turret's pose is a function of the effect clock; `fx_ship.update` writes it on the node every frame (`turret_step`). Fixed guns never move. Tuning values: `TURN_RATE`, `TURN_ACC`, `TURN_MIN`, `TURN_MAX`, `TURN_HOLD` in fx_hull.gd. Checked by `render/test/turret_check.gd`.

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
| 4 hull breach | f <= 0.2, or broken | open break with throat radius 0.048 L, stepped torn collar, recess 0.17 L, three cross members and seated fire; medium hulls up get a second break; transition sparks and debris |
| 5 wreck | `dead` (after `death`) | see section 5 |

- R80 owner rulings govern this ladder. Stage 3 and every weapon mark stay sealed. Squadrons keep stage 0 surfaces and trail pooled smoke below half total HP.
- A stage that goes up while shots are still flying at that ship waits until they land, so holes open when the hit lands, not before.
- Repair seals a stage 4 break with a material-specific patch and keeps dents, scorch and weapon scars. Removed emitters fade within 0.8 effect seconds. Chorus knits over 3 seconds.
- `burning` shares the section emitter allocator. The per-ship caps for fire and smoke/vent are 4 and 8 for light hulls, 8 and 12 for medium hulls, and 12 and 16 for heavy and capital hulls. Persistent emission spends zero counted flashes. Safe mode keeps flat marks and drops deformation, breaks and emitters. A broken `eng` section makes the engines sputter. Shields rising play a short faction-coloured regen shimmer.
- `prepare_battle_hulls()` warms the hull materials during loading. The first brownout or early wear assigns the ship's private damage materials if a damage rebuild has yet to assign them.
- Capability loss (issue 1741 Milestone 3, R416; only with `VS_WOUNDS_V2=1` or `rendering/effects/wounds_v2`): `sync_ship` also reads `weapons[i].off`, `engHit` (the rules' `st.engine` above 0) and `shieldOff` (`st.shieldOff` above 0), view-only fields of `api.view()`. A slot with `off` above 0 jams every turret its `hp_w<slot>_*` muzzles hang under and smokes and sparks one of its fixed mounts (`fx_hull.turrets_for_slot`, `mounts_for_slot`); a hull with no point for the slot jams only a turret no slot owns in the slot's section by its rules arc (F prow, P and S midship), else smokes that section's plating without touching any gun. The flag is read through `godot/fx/fx_wounds_flag.gd` (`WOUNDS.v2()`), shared by every Wounds V2 file. With a `weapons` list the old random section turret pick (issue 1587) is off; without one (a bench unit) it stays. The drive fails in tiers (`engine_tier_for`): an engine hit or engine stage 2 gutters one nozzle (65% plume), stage 3 darkens one more, stage 4 or a broken `eng` leaves one nozzle at 35% with the rest dark, smoking at the bell and sparking as the ship tries to move. Only the Hullbreakers' drive coughs soot. A shielded ship with `shieldOff` or a broken `mid` crackles in its shield colour on the midship plating every 1.4 to 3 s (twice as long and no light under reduce flashing). Flesh throws no sparks. Checked by `godot/fx/test/capability_loss_check.gd`.
- Idle motion (issue 1685, R411 Priority 3; only with `VS_IDLE_MOTION=1` or the project setting `rendering/effects/idle_motion`, default off until Ryan picks from the Pick Sheet; `godot/fx/fx_idle.gd`, `IDLE.enabled()`): a ship (never a squadron) carries one small looping motion for its faction, one batch of soft sprites (kind 18, no peak) under `_dmg_root`, so it rides the hull and costs one draw call and no CPU. Hegemony radar sweep (four blips in turn on the top plating), Sunward furnace-vent ember breath, Hullbreakers smelter flicker, Glasswrights optic shimmer, Eclipse violet corona pulse (all violet, R372), Chorus spore-sac swell. Spots are the hull's own upward `hp_breach_*` points, else plating found by a ray (R 6.7); no geometry is added and no mesh is moved (no kit export carries a named part for it yet). Colours come from `faction_looks.json`. Comfort (RULEBOOK 6.2): every sprite is under the flash counter's intensity line, none lasts under 0.5 s, one ship starts at most 2 pulses a second, and nothing spends the flash counter. Reduce flashing (`fx.reduce_flashing`) rebuilds the batch longer, dimmer and slower; Reduce motion (`ShipView.calm`) leaves the batch but stops the radar sweep (one steady blip). The flag is read when a ship is added. Checked by `godot/fx/test/idle_motion_check.gd`; frame cost and the per-faction sheets by `godot/fx/test/idle_motion_probe.gd` (a solo GPU job, R407).

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
- Guns fire from the weapon slot's authored muzzles (issue 370); a hull without them fires from the plating found on the side facing the target, never backward (CLAUDE.md); a target behind the ship is engaged from the top.
- Every hull hit leaves its weapon's own mark in the hull itself (R43, section 14): a sealed lance trench, a light blue plasma splash crater with a droplet fan, sealed gauss entry and exit craters, a torpedo blast crater, flak pockmarks, Chorus acid pitting with spines, an ion branching burn, a ram crumple (and a smaller one on the rammer's bow). Shield-only hits leave no hull mark.
- Every hit also moves the ship (R50, section 7): mass-scaled, by the weapon's momentum.
- Plasma is light blue whoever fires it (Ryan, Oct 26): bolt, splash and crater.
- Issue 461 (the hits, upgraded; docs/playbooks/deaths_and_hits.md): each weapon family has its own hull-hit recipe (`fx_weapons.family_of`: shell, energy, lance, torpedo, bio), sized by `LADDER_PX` times the firing hull's band (`GUN_K`) times the hit hull's band (`TARGET_K`). What a hit throws lives its own life (`SPARK_LIFE`, `DEBRIS_LIFE`, `GAS_LIFE`, `EMBER_LIFE`; flame keeps the 0.70 s cap, `FLAME_CAP`) and leaves the plate along its outward side. `fx.light(p, t, life, peak, col, shape, reach)`: `reach` (world units) carries a light further and with a slower falloff (`REACH_ATTEN`); torpedo hits (36) and death core flashes (26, 35, 52 by class) use it. Tests: set `fx.dstate["hit_logging"] = true` and read `fx.dstate["hit_log"]` (`fx/test/hit_recipe_check.gd`).
- `impacts` are the moments to show floating numbers; `done` is when G2 may start the next event (G2 can start earlier; effects overlap fine).

Torpedoes (R364, Nov 20 2026): they fire now. `volley(..., "torp", ...)` plays launch, flight and impact in one go; the B3 lane,
parked torpedo and next-turn strike (`torp_lane`, `torp_launch`, `torp_strike`, `torp_lane_clear` and the lane shader) are retired.

## 4. Shields

- Shield hits come with `volley` (`hits[i].shield > 0`). A fully absorbed hit transfers 0.12 of its impulse to the hull.
- `fx.shield_break(id, quad, hit_lp)` handles the `shield_down` event. By default the fitted skin flashes once, then one band closes onto the breaking hit over 1.225 effect seconds. This also works with the optional egg shape. `hit_lp` is the hit point in the shield frame. Omit it to aim the collapse using the facing. The earlier faction-specific failures are selectable for dev comparisons with `VS_SHIELD_FAILURE=today`.

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
- Wrecks retain the existing Jolt bodies and the 24-wreck cap. Issue 1237: a wreck section leaves Jolt 4 s after its release (fx_death.gd WRECK_PHYS_S) and drifts on with the same velocity and turn on the effect clock; debris plates fly 2 s as before, then slow (damping 1.4) and are at rest by 5.5 s (DEBRIS_REST_S), so Jolt has nothing awake about 8 s after a kill. Plates never test each other; hulls and wreck sections still knock them, and a knocked plate rests again 1.5 s later. One-shot pictures (death flipbooks, staged flashes and smoke, weapon gas and hull hit pictures) come from `fx.picture(key, make, name)` and go back with `fx.free_picture(weakref(node), node.get_meta("pic_gen"))`, never `free_effect`. The frame's power-down budget (POWER_BUDGET) is shared by every dying ship. Check: fx/test/multi_death_check.gd. Ribbons and streamers use the existing particle pools and debris ring. Unfinished cuts are polled without blocking the main thread; a finished previous cut is reused when available.
- Authored recipe ships: the version 1 `voidsworn_destruct` GLB extra and interior surfaces are defined in `docs/ship_pipeline/RECIPE.md`, stage 7. `fx_hull.gd` reads them in the installed hull's scaled frame. Damage opens the exterior onto the authored decks, frames and machinery; death carries those surfaces into its pieces. Authored joints guide the irregular fracture, retaining the missing bite, chips, ragged rims and faction matter. Their count follows the build's structure. Ships without that extra keep the #167 procedural cavity and capped-face fallback.
- Main rigid wreck pieces lock linear Y at the altitude where they separated, and their release velocity has zero Y. They can still tumble. This keeps physics contacts from pushing the main wreck below the board where Ryan cannot see it (`death_plane_check.gd`); it is an existing visibility protection, not a restriction on the rotation or every small thrown fragment. Kinematic main pieces also receive zero Y release velocity.
- fx hides the ship's own meshes at the break-up. G2 can keep or free the root after `t`; fx keeps its own copies of the meshes.
- `fx.jump_out(id)` for `fled`: a short drive flare and streak, then the ship's meshes are hidden.

## 6. Other events

- `fx.ability(id, ab)` and `fx.command(id, cmd)`: a short faction-coloured pulse on the ship (a stand-in until each ability gets its own look; coming).
- `fx.launch(carrier_id, squadron_id)`: bay flare and craft streaming out toward the new wing.
- `var t = fx.board(attacker_id, target_id, result)` on the rules' `board` event: a breach in the target's hull at a plausible boarding point (its side facing the attacker, mid section), venting gas and lit from inside for about 3 s, then a dark gash that stays as a mark. Returns seconds until it has played. (G2: this replaces the stub flash at the board event.) Issue 1547: a party from dead ahead or astern breaks in on the side the camera sees; the look Ryan picked (B: a wider hatch, pop ring, burst, vent and amber inside light, and the amber boarding lines in the shared line style) comes from `BOARD`, and `fx.board_hold_ms()` is how long the battle holds on it before the next event.
- `fx.hull_mark(id, look, w, world_p, dir, sec)`: a weapon mark without a volley (look as in volley, plus `board` and `ram`).
- `fx.tick(id, kind)` for turn-start damage (`fire`, `acid`, `tidal`, `storm`): a small flare-up of that kind on the ship.
- `fx.hull_point(id, section, toward)`: `{p, n}` in world space on the hull (section `"prow"`, `"mid"`, `"eng"` or `""`, on the side facing the point `toward`), for anything G2 wants to anchor there.

## 7. Feel: shake and hit pause

- Shake is a trauma model (trauma squared, smooth noise, decays), positional only, applied to `cam.h_offset` and `cam.v_offset`. Battery light, lance and gauss medium, torpedo heavy, capital death heaviest, all inside the A5 ranges (0.15 to 0.30 s normally, 0.35 to 0.45 s only for capital deaths), and smaller with distance from the camera. `setup({"camera": null})` turns it off; then read `fx.shake_offset()` (a Vector2) and apply it yourself.
- Hit pause never blocks input: fx slows its own clock for a few frames on heavy weapon hits. Deaths use a separate R73 beat only for cruiser class and above or flagships, independent of their draw scale. It runs at 0.35 speed for 0.48 real seconds, with a short recovery (measured under 0.64 s total at 30/60/144 Hz). Small kills add no pause. `fx.anim_speed()` reports the presentation speed; wreck velocities follow it without touching `Engine.time_scale`, input or rules.
- `fx.hurry_death()` immediately clears the active beat and suppresses a queued death beat for three effect seconds. The only hook outside `fx/` is four lines in `scenes/battle/battle.gd`: the existing Enter/Space hurry branch calls it, and a death started while already hurrying calls it too. No rule or result logic changes.

### Hit reactions (R50, R412)

A hit no longer just flashes: the ship reacts with its mass, in three beats (r5, after Ryan's "no cartoon push back"; the ship never springs out and back):

1. **Onset.** The kick builds over 0.03 s for craft up to 0.16 s for capital hulls. The structural tremor runs from 6 Hz for craft down to 3.5 Hz for capitals and fades in about 0.22 s. The roll axis sits below mid-hull so one broadside heels the ship consistently. Heavy and capital hulls take half the linear kick.
2. **Arrest.** Attitude corrections oppose the spin and slide over 0.35 s for craft up to 1.2 s for capitals. Sunward and Meridian use cold gas, Ashfall uses warm grey jets, Glasswrights use gold glints and Eclipse uses violet shimmers. Chorus uses no mechanical jets.
3. **Recovery.** The hull eases back onto its hex and returns to its resting angle, including the list of a crippled ship.

**Zoom punch (F3).** `fx.punch(t, amount, pos)`: the camera's field of view narrows by `amount` (0.01 = 1%) over about 0.05 s and eases back over about 0.4 s; smaller far from the camera (amount / (1 + distance / 400)), never more than 6% at once. fx plays it on heavy gauss slugs (0.8%), crits (0.6%), torpedo and ram hits (1.4%) and kills (1% for a light ship up to 3.4% for a capital, more for torpedo kills and flagships). fx writes `camera.fov` only while a punch plays and puts the camera's own value back after; if G2 or the camera rig changes the field of view meanwhile, fx takes the new value as the base. `fx.punch_now()` is the current punch (0 when none).

Torpedoes and rams shove, shells and gauss slugs kick, and lances and ions carry little momentum. Shields pass through 12% of an absorbed impact's impulse. Hull damage, shield breaks, crits and ion hits stutter the drive. Heavy hull hits, crits, gauss punches, lances and ion hits briefly dim deck lights. Batteries, gauss and heavy ordnance kick the shooter back on the shot's fire time. A turret's barrel assembly retracts and recovers on that same clock.

ShipView owns board position and heading. FX moves `hull_pivot`, keeping the hex marker and selection ring on the board. The pivot's translation follows the ShipView heading while the hull yaws under it. ShipView takes idle bob time from the effect clock so it follows hit pause.

Missed projectiles pass the target plane and leave a fading trail. Close misses can spark at the shield edge, and the positional pass-by cue plays on the effect clock. `fx/test/wave_1a_check.gd` covers the hit, recoil and miss behavior.

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
w.finale_stage(n)                      # optional: with opts.finale, move the dawn sweep to stage n (0 dark to 5 full)
```

- The run 5 finale (R78 Q18): `opts.finale` adds a projected warm key light that catches the existing ships, rocks and wrecks sector by sector, plus a warmer sky and Hollow Sun disc. No extra board surface or grid is built. `finale_stage(0..FINALE_STAGES-1)` moves it one sector at a time; the battle calls `finale_for_round(round)` so round 1 preserves the normal battle lighting and round 6 is full dawn, then it holds. The campaign marks only run 5; earlier sector 3 bosses stay dark. It changes pictures only, never `view()` or the rules.
- Capture proof: run `res://world/finale_shots.gd` twice with a 1280x720 window and `-- --out DIR`, retaining the second run. Copy the PC-built hulls and wreck props before importing. The harness uses the real battle with a stated mid-battle placement fixture, camera radius 170 and the placeholder guard. It stops on render errors, saves six named stages and a normal-battle control, and writes their round-1 image difference to `evidence.json`.
- Six clearly named radius-520 overviews accompany the radius-170 pictures, to show the sweep over the parts of the board outside the played camera's frame.

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

Profiling: `fx.prof` holds microseconds of fx's own main-thread work per section (`volley`, `death`, `break_up`, `debris`, `breach_apply`, `hull_gather`, `cut_start`, `piece_meshes`, `power_down` (issue 616: a dying hull's power-down materials, built POWER_BUDGET a frame from the kill frame on; its kill-frame share is inside `death` too), and the per-frame `later`, `ships`, `weap_death`, `lights_pools`) since the last `fx.prof_take()`. The gallery's 20-ship bench lists, for every frame over 33 ms, that breakdown for the frame and the one before, plus process, physics and render times.

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
| 4 | open throat, radius 4.8% of L; stepped curled collar, recess 17% of L, three structural cross members; a second break on medium hulls up |

`wound_kind` in faction_looks.json selects metal (0), living tissue (1), crystal
(2), or Eclipse machine wounds (3). Living hulls use spores and ichor; crystal
uses dust and vapour with no flame; Eclipse uses dead panels, violet circuits,
slow rim arcs, coolant, dark smoke and violet plasma. Repair seals every break.

**Wounds V2 (R416, issue 1741; off unless `VS_WOUNDS_V2=1` or the setting `rendering/effects/wounds_v2`, read by
`fx/fx_wounds_flag.gd` `v2()`).** Each faction's `wound` profile in faction_looks.json (kind 0 Sunward to 5 Eclipse,
rim_style, scorch_col, rim_metal, interior_lift, interior_accent, interior_pattern, interior_rough, soot_weight,
wreck_soot) drives every wound shader. On an authored-interior hull a section opens a real cutout from stage 2 (0.026 L,
0.038 L at stage 3, 0.052 L at stage 4; a second one at stage 3 and up on medium hulls), and a heavy hit (torpedo, lance,
null lance, star, gauss exit, weight 3+) on a section under 80% HP opens one where it struck; at most 6 per ship and 2 per
section, clear of turrets and bay doors (`fx_ship._clear_spot`). Every cutout goes through
`fx_breach.validate_footprint` (8 rays at 0.85 R: shrink to 0.75 R and 0.55 R, slide toward the plating, else a small
surface mark) and `place_hole` (faction rim, plate thickness `clamp(Dt * 0.14, 0.008 L, 0.24 R)`; a plate thinner than
0.4 R chips with `thin_shear` instead of opening; `thickness` marches through stacked plating within 1.2 R to the first
real cavity, so layered armour opens). Overlays skip faces turned more than about 70 degrees from the hit and
sit in a tighter slab; the hull shader's cut skips walls at right angles to it. `fx_breach.dress` puts the faction's own
3D dressing inside each mouth (beams and cables, bone ribs and tendons, crystal shards, obsidian truss and violet bus),
`inside_lights` adds at most 2 soft lights per ship (8 in the battle, `BATTLE_HOLE_LIGHTS`) in `interior_accent`, and
the built interior takes the shared `fx_shaders.INTERIOR` shader (`fx_hull.interior_material_v2`) once a mouth is open.
That shader multiplies the faction pattern over the surface: a surface whose glTF material extras name an
`interior_role` (Interior Kit V2) keeps its own colour and trim maps; an older one keeps only its texture's light and dark
in the faction's `interior_lift`, and its own glow keeps only its brightness, in `interior_accent`
(`fx_hull.interior_role`: wall, bone, core, glass, organ). Walls are held to the faction ceiling (`wound_of(...).wall_max`: 0.11, the Glasswrights 0.45, pale pearl glass; a 1743 `interior.wall_max` wins and must agree) and non-core glow to 0.25 by scaling
the colour, never per channel; cores, rim heat, bus tips and fresh burns pass. `fx.wreck_interior(source, faction)`
hands the same shader to the wreck pieces, settling into the wreck look over 4 s from the death. Over the caps the
oldest cutouts stay open (`cap_holes`). `fx_breach.open_mouths(s)` lists a ship's open mouths ({c, n, R}, hull
frame, after the caps) for vents and embers. With V2 on, prism, star and null lance hits leave `S_PRISM`, `S_STAR` and `S_NLANCE` marks.
Proof: `fx/test/wounds_v2_check.gd`, look-bench rows `bench/look_moments_wounds_v2.json` (cameras 170 and 26).

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

The ship stores up to 8 marks per hull section and 24 per ship (sections 0 eng, 1 mid, 2 prow). A repeat of the same mark close by (anywhere in the section for a torpedo crater or an ion burn) rebuilds the old one bigger and fresh (up to 1.6 times). Past the section budget the oldest light mark goes first, then the oldest mark. Repair retains bounded permanent scars. Stages 0 and 1 draw up to 2 weapon marks per section, stage 2 up to 3, and stages 3 and 4 up to 4, prioritizing heavy and newer marks. Repaired sections can draw the stored scars. Section entries sit outside the weapon-mark budget.

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

The shared faction palette and styles live in `res://fx/faction_looks.json`. `FLOOK.of(faction)` and `fx.faction_info(faction)` return the entry. An unknown id warns once and falls back to Sunward. The palette includes `weapon`, `engine`, `shield` (null for factions without a bubble), `damage_glow` for fire and lit conduits inside damage, and optional `accent` for the engine corona and `shield_edge` for the rim. Sunward, Ashfall and Eclipse have engine accents. Sunward has a tinted shield rim and the Glasswrights have a rainbow rim. Eclipse has dedicated `weapon_core` and `weapon_sheath` fields.

The table also supplies `shield_style` (0 veil, 1 hex lattice, 2 patchy, 3 prismatic), `shielded`, `trail`, `engine_extra` (none, soot, spores, embers), `hull_fix` for the rim and lift on dark hulls, `nebula` for the battle sky, faction death styles and `wound_kind` (0 metal, 1 living tissue, 2 crystal, 3 Eclipse machine).

Code outside fx/ reads the effect colours through `FLOOK.engine(f)`, `FLOOK.weapon(f)` and `FLOOK.shield(f)`. The last returns the weapon colour for a faction without a bubble. `FLOOK.has(f)` checks for a known id. `render/test/faction_colour_source_check.gd` guards the shared source. The json ships in the export (`include_filter="*.json"`). Ids never change.

## 16. Effects at distance (F3, feel pass Nov 1)

Ryan's first playtest: "effects looked very weak, especially at a distance and for smaller ships." Two causes, two fixes (Claude's calls, vetoable; numbers in docs/shots/f3/):

- **Minimum on-screen size.** Every effect sprite, streak, ring and beam had a size in world units only, so a frigate's tracer (0.26 units wide) was 2 px from the battle camera and a third of a pixel fully zoomed out, where it dropped out of the raster. The effect shaders keep each kind at least a few pixels across, counted on a 1080-line screen so it looks the same at any resolution (`px_world` in fx_shaders.gd; the global `fx_px` scales these readability floors): pops and the star torpedo 14 px, fireball cores, beam contact flares and plasma bolts 12 px, beam charges, bio globs and soft glows 10 px, squibs, prism chips and strike craft 9 px, flames 8 px, embers and hot spots 4.5 px, engine cores 3 px; shock rings 12 px. Streak and ribbon widths, and absolute pixel caps, now follow section 17. A grown sprite dims as it grows but by less than its area, so small and far effects read brighter without blowing out. Smoke, soot and gas have no floor (no grey haze at distance). Shield hits keep their core, ripple and spread a few pixels wide too.
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
- `board.show_blockers(hexes)` outlines the intermediate blockers returned by `api.line_blockers(shooter, target)`. Unreachable-hex tips use `api.entry_reason(id, q, r)`. These calls only explain existing rules. Set-piece hole cells now have solid props; planet, station and Hollow Sun exclusion rims show their exact rule footprints. The planet and station models are retained. Missing station assets and uncovered station edge cells get solid fallback docking hardware.
- World bakes persist as RGBA PNGs under `user://world_bakes/v3/`. Keys include seed/settings, shader source and dimensions; parameter order does not cause rebakes. The memory cache holds 24 images. Cold starts draw a 512x256 sky and 256x128 planet first, then refine after three seconds in serialized GPU strips. Full-resolution cache hits load directly without the preview delay. GPU work stays on the render thread; no gameplay waits for a full-resolution bake. Issue 1265: the disk folder is capped at 500 MB (`CACHE_CAP_BYTES`); after each save the least recently used maps go first (last use is kept in `used.json`, refreshed on every disk load), maps the running game holds and the map just saved never go, and `.tmp` files older than a day go; bakes in older version folders (v1, v2) are removed once per run. Checked by `world/test/bake_cache_cap_check.gd`.
- After creating the ship views, call `world.use_ship_debris(views.values())`. It reads one loaded hull per faction, cuts four sealed chunks per hull on a worker, preserves UVs and source paint/PBR materials, adds scorch weathering, and installs up to four instances per debris hex. Geometry stays inside the old footprint. No GLB paths are required. Empty source lists retain the existing debris; battles without debris skip the cutting work. Worker shutdown is joined when the world leaves the tree.
- `fx/test/playtest_batch1_check.gd` checks damage grading/repair, organic rupture and retained wounds, loaded stand-in hull cutting, disk cache invalidation/alpha, and both lane directions. `FB1_SHOTS=DIR` captures the four damage examples, lanes, hull chunks and organic rupture on a renderer. These are stand-in hulls, not full-build ship validation.
- `world/test_blockers.gd` checks the real world/board builders over all 12 shapes, five terrain maps and two seeds. It checks solid geometry at blocking hexes, named entry reasons, and agreement between the blocker query and the sight predicate. Headless rock coverage reads the real submitted batch transforms because the dummy renderer does not retain MultiMesh buffers. No background dressing or exclusion-only outline can satisfy ordinary blocker coverage.
- `fx/test/check_destruction.bat` now includes both checks. Results default to `%TEMP%/voidsworn-destruction-<id>`; `FX_CHECK_OUT` overrides that folder. The existing geometry, staging, smoke, box captures and 20-ship frame probe remain included.

## 17. Textured weapon kit (issue 367)

This branch implements the kit; the comparison pictures and measurements are in
`docs/shots/look_bench/kit/REPORT.md`. Ryan's faction picks and final approval are
still required. Round 1 kept faction colours and impact recipes; section 18
records the Eclipse weapon correction. Faction ids and weapon timing stay
in their existing sources. `docs/playbooks/scale.md` remains the scale table:
weapon geometry uses the firing ship's `scale_k`; readability floors describe
light on screen, not a new world scale.

`textures/make_kit.py` makes all three original masks with free Python and
Pillow. It retains a fixed-seed particle bake for the cooling tail, a periodic
core/sheath flow mask, and a filled faceted chip. There are no downloaded sprite
packs. Materials share the imported textures through `_mat`, including the
attached engine batches; they do not allocate textures per shot.

Build B (issue 2043) uses separate hot-core and tapered-sheath masks in the
existing streak and sprite pools. The shooter palette normally tints the
sheath, but plasma stays light blue from muzzle to impact (R46). Bombs have
their own capsule mask. The shared muzzle kit keeps the approved gas on
cartridge blasts and uses clean apertures for energy and crystal and a wet
plume for bio. Bright muzzle and intercept cores still use the flash counter.
Spark recipes stay separate (issue 2018).

Star corona rays follow the original body after ignition and turn off on
intercept. Rockets add a cold, short smoke layer over the nozzle wake with
its own small pixel floor. A torpedo without its kit model uses the same
tapered wake as a kit round.

Streaks retain their existing pool and API. The mask has a bright compact head,
a short irregular tail, and a soft halo. Spark heads follow drag and a gentle
curved drift; the cooling history bends inside the quad. After the usual length
floor, the shader measures the projected head-to-tail distance and shortens it
with perspective-correct interpolation. The caps are **actual render-target
pixels**, at cameras 170, 60 and 26, at 1080p or 4K, including `min_px = 0`:

| Streak kind | Maximum projected head-to-tail length | Default quad width floor at 1080 |
|---|---|---|
| Spark, bio drop, molten drip, flame tongue | 16 px | 6 px |
| Shell and tracer | 22 px | 8 px |
| Gauss and gauss flak | 26 px | 22 px (issue 800) |
| Las and prism dart | 32 px | 7 px |

These are geometry caps before post-process bloom. They do not cap a halo's
threshold-dependent lit extent. Width floors are the whole textured quad,
not a claim that every pixel of it is bright. The absolute length cap is
independent of `fx_px`; widths still grow with the render scale and world size.

Both gauss emitters use `_gauss_wake`. Its tracer lasts `(2 - 0.001) / 60`
seconds: two drawn samples on the 60 Hz clock, with the small epsilon preventing
a third sample from float rounding at the boundary. It advances along the shot
and carries only a short head/tail. At max quality, ten short distortion puffs
made a 0.10 s shimmer along the path in round 1. Issue 800 replaces those with
two local 0.04 s wakes following the two head positions. Low quality keeps the tracer. A full-length
luminous line is never the wake.

Ribbons keep the segmented camera-facing strip, with independent scrolling
core and sheath masks. The transverse profiles have stated full width at half
maximum (FWHM) in render-target pixels. At either camera 170 or 60, the minimum
core FWHM is 3 px (needle 2 px), and the minimum sheath FWHM is 7 px (kind 6 crackle 11 px).
World widths can make them larger. The formulas are core `max(3, quad_px * .17)`
and sheath `max(7, quad_px * .48)`, with the needle and Doom substitutions above.
For Doom, the trunk stays at 3 px core and 11 px sheath; its wider quad holds
forks outside the trunk's bloom. The quad floors below fit both profiles. Actual raster measurements are in the
report, separate from these target profiles.

| Kind | Quad floor, px | Shape and motion |
|---|---|---|
| 0 plume | 12 | Turbulent hot throat and broken cooling sheath, tapered fade |
| 1 idle trail | 10 | Quiet hot centre and slow drifting wisps, fade at both ends |
| 2 lance | 16 | Sustained core, opposing flow in the broad sheath |
| 3 sputter plume | 12 | Irregular coughing throat, softened in reduce flashing |
| 5 ion | 16 | Broken crawling filaments around the core, without diagonal bars |
| 6 electrical crackle | 64 | Legacy forks outside the 3 px trunk and 11 px sheath |
| 7 pulsar | 16 | Travelling packets and a moving spectral fringe |
| 8 needle | 12 | Narrow resolved dart core and moving nodes |
| 9 tendril | 16 | Wriggling tissue path, mottled luminous interior |

Kind 6 forks are drawn inside the wider segmented strip: their hot FWHM is 2 px,
with a 5 px glow. They branch from its live trunk. The trunk re-strikes every
70 ms, or 230 ms in reduce flashing. Every finite ribbon has a soft time fade;
beam endpoints have a muzzle/contact flare and a separate 0.30 s quiet cooling
glow. The real impact still owns the wound, flash and thrown matter. The curved
moving-engine history also has a resolved centre, soft sheath and end fades.

Prism sprite kind 16 is a small filled lit facet rather than a four-armed
cross. Shield chips and impact glints still use it. Build B's prism flight
and muzzle use their own masks. No shield recipe or shard count changes.

Rockets and torpedoes retain the real closed casings, fins and sampled baked
exhaust. Their motor has a 12 px quad floor with distinct core and halo, existing
pulse motion, a short rise off the rail and a fade before impact. The smoke history still cools separately.
Bay flashes, interceptions and all eight shared-helper regression rows are
included in the capture adapter.

Attack-run craft and live squadron wings use their real stern history with
the same textured core and sheath. The luminous centreline ends within 24
render-target pixels of the moving stern and cools over 0.65 s. Its whole
quad has an 8 px absolute floor (10 px with the usual 1080-line readability
floor). `warm_craft_trail` primes the actual ImmediateMesh vertex format.

The battle's aggregate `volley` option `pd` is consumed only by false shot
entries for torpedoes, rockets and star torpedoes. The event has no per-shot PD
identity, so the first eligible false entries are used. Rolled hits are kept.
Every visual body in an intercepted group bursts at 62 percent of its flight;
there is no later hull hit or miss-end glow for that group. This is visual
routing of the existing result, with no rules or damage change.

To add or tune a look, capture that row first, change its recipe, then capture
it twice and retain the second run at all three cameras. Use the scripts in
`docs/shots/look_bench/kit/`; scratch goes to TEMP and evidence goes to the task's
shots folder. Inspect the default camera at source pixel size first. Measure
caps without bloom, and report scene-gate frame time at 1080p plus GPU time at
4K. No headless result stands in for a picture or GPU cost.
`measure_kit.gd` draws all nine ribbon kinds as well as capped streaks;
`analyse_raster.py` records channel FWHM separately from the analytic core
and sheath widths. `verify_evidence.py` checks final source hashes, all 46
rows at all three cameras, sheet dimensions and the scene-gate results.
`trace_audit.py` uses the preserved audit checkout only to attribute sh_06;
it verifies that checkout against the audit pin and records the live callers.
The adapter reaps completed hull cut jobs before removing each fixture ship,
then releases static world and puff resources while the renderer is alive.
Shield-break fixtures require a live shield and fail before capture if it is
missing. Their four styles are Sunward, Hullbreakers, Hegemony and Glasswrights.

## 18. Eclipse weapon correction (issue 800, R263)

The Doom weapon uses ribbon kind 10, `ECLIPSE_ARC`, in its own alpha-blended
pool. Kind 6 remains the kit's small electrical crackle, used by other weapon
recipes. Other beams keep `RIBBON`. This separation lets the violet-black
sheath obscure the sky without changing another faction's beam blending.
The full arc quad is at least 80 actual framebuffer pixels wide at cameras
170 and 60, including room for forks. The dark trunk extends 10 to 15 pixels
either side of its centre. Its deep violet core has analytic FWHM 5.5 pixels,
with a separate 10.5 pixel FWHM packet profile; the
white centre has FWHM 1 pixel. These describe shader profiles before bloom,
not measurements of the final tone-mapped picture.

Three energy packets travel from shooter to target along the held jagged
channel. A separate slower mask moves inside the sheath. Alternating attached
forks grow and die on staggered clocks; reduce flashing slows those clocks and
softens the arc's rise. The real emitter charges before firing. The contact
flare is larger than the emitter flare, and both ends cool in deep violet over
0.45 seconds. Hit times, damage, weapon ids and hull attachment stay on their
existing public paths.

`faction_looks.json` owns two weapon-only Eclipse colours: `weapon_core` and
`weapon_sheath`. The Doom and null cannon recipes use the core colour (deep violet since Nov 21 2026, issue 1503; it was green); the two
alpha materials take their dark sheath from the same data. Existing ship,
engine, shield and backdrop colours retain their separate fields.

Streak kind 5 routes to `NULL_SLUG` in both gauss emitters. Its dark filled
body encloses a compact bright head, with a 22 pixel whole-quad floor at 1080.
The shared `STREAK_VERTEX` owns its motion and absolute 26 pixel length cap.
It retains the kit's two-frame luminous life. The no-bloom probe measures the
head itself, requiring at least 3 bright pixels across its half-peak profile,
at cameras 170 and 60 at max and low quality. Muzzle and real surface impact
flashes remain separate from the travelling slug.

Both materials are included in the loading-screen warm-up. The round 2
capture adapter also records the entire 1920x1080 camera-170 frame reduced
to 390x219 for the phone view. `round2_sheets.py` pairs that view with native
camera-170 and camera-60 crops, emits a motion GIF, and compares every pixel
of every kit row against the preceding kit. It keeps evidence separate from
the accepted look-bench baseline. Cost is measured by the unchanged #207
scene gate against the kit's historical 2.989 ms at 1080. The initial
0.300 ms absolute frame allowance was not met. A fresh, source-matched
original-kit control in this checkout measures 4.097 ms frame median and
2.420 ms GPU median at 1080; the change measures 4.617 ms and 2.429 ms.
Session frame ranges overlap. The final stated frame allowance against
the historical number is 1.710 ms (4.699 ms ceiling), and GPU changes
must stay within 0.300 ms of the fresh control at both resolutions.
The standing 12.5 ms scene gate remains unchanged. REPORT.md gives the
session values and the 4K pair, without treating CPU frame variation as
a measured shader regression.

Use `capture_round2.py` for the complete 46-row comparison. A long process
stalled at the Glasswright shield row with Jolt's maximum-job warning in
this round. The adapter runs the same selected rows in batches of ten,
using a full row warm-up on the first batch and the bench's material warm-up
on every row. Later batches reuse the warmed disk pipelines. The changed
weapon recipes also get a separate preview before the kept after run.
Before and after use the same batches and time samples. Its aggregate is derived from each
child's saved report and clean process exit, with source hashes checked
between batches. Interrupted output is retained separately and does not
substitute for a completed batch.

The comparison retains raw channel counts. Thirty rows match within one
8-bit channel value; twelve other unchanged looks have sparse differences
in impact puffs, debris and isolated pixels. Their peak-difference crops
are retained for visual review, including the full worst flak and rocket
frames. They are not labelled pixel identical. Four intended changed rows
are Doom, gauss, gauss flak and the gauss exit.

## 19. Cinematic arc, null tracer and shield crackle (issue 815, R271)

This section supersedes section 18's smooth arc profiles and kind-5 two-frame,
26 px limit. Other streak caps and every other beam shader remain unchanged.

Doom keeps its own weapon_core (deep violet since Nov 21 2026, issue 1503; it was green) and weapon_sheath violet-black fields. Its
96-segment channel carries three thin, independently twisting hot filaments.
Only a filament's central subpixel profile is white. Two advected noise scales
and the existing flow mask swell and pinch the body, erode its silhouette and
break up its opacity. There is no clean rim outline. Secondary tendrils expire
in about 3 to 5 frames; reduce flashing slows their clocks and softens the rise.
Packets and eddies move towards the target. Along-channel motes drift and cool;
max quality adds eight small heat lenses. The struck plating retains its real
surface mark and cooling metal, with a local 4.5*k light reach to spare neighbours.
The existing wound/scorch route, hit timing and damage are unchanged.

`null_trace` submits exactly one head/history particle. Its head follows the
existing 650*unit ballistic speed to the existing impact time. The deposited
streak tapers from the muzzle and fades over 0.52 s after impact. A faint ionised
wake persists to 0.70 s. The head fades at contact, so the lingering trace never
becomes another slug. Gauss flak uses the same route with its existing 0.02 s
flight, preserving its burst timing. The existing
faction weapon field supplies violet-white; Doom alone uses weapon_core deep violet.
The sharp muzzle flash, displaced-gas ring and hull impact spark burst remain.
Widths use the game's 1080-line pixel convention, so they scale with resolution;
the tracer's length follows the shot, with no short screen-space length cap.

Stopped shield hits never call a gas atlas, vent or gas-cloud emitter, including
the former baked flash body. They use faction-coloured energy light, brief
electrical branches and spark scatter. The existing ripple, shield pattern and
break look remain owned by issue 372. Hull hits retain their smoke. Flash-area
booking and the reduce-flashing fallback are preserved by `_shield_crackle`.

Proof tools live in docs/shots/look_bench/kit: capture_round3.py renders all 46
existing rows and eight torpedo/beam shield-hit fixtures at cameras 170 and 60.
Every row has a warm render followed by a kept render. The full frame reduced
to 390x219 is saved for every camera-170 row. round3_sheets.py compares every
row, pairs phone and native crops, and films every null flight frame.
check_round3.gd isolates the production shield branch from hit-reaction braking
jets and checks every live shield style at max/low and normal/reduced flashing.
measure_round3.gd rasterises the real tracer without bloom at 1080 and 4K.

The declared round-3 frame allowance is 0.800 ms over round 2's 4.617 ms at 1080,
giving a 5.417 ms ceiling. GPU deltas are also reported against a fresh matching
round-2 control, with a 0.300 ms allowance at each resolution. The unchanged
12.5 ms #207 scene gate remains binding. REPORT.md records measured results;
neither these tools nor their pictures replace the accepted look-bench baseline.
