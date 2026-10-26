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
})
```

- fx runs its own `_process`. It keeps its own effect clock (scene_t, a global shader parameter it registers) that slows during hit pause.
- For stills and tests: `fx.manual = true` and then `fx.step(dt)` once per frame; the clock then only moves with `step`.
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
  - `meshes`: Array of the hull MeshInstance3Ds. **Pass `sv.meshes` from ShipView** (the default, every MeshInstance3D under `root`, would also take in the selection ring and the footprint marker). fx reads their triangles once (hit points, breach placement, death pieces), never changes their materials, and hides them at the break-up of a death;
  - `cls`: the template class (`"Frigate"`, `"Cruiser"`, `"Squadron"`, ...) and `size` (the data.js draw scale); together they pick the effect weight (light, medium, heavy, capital);
  - `squadron`: true for strike-craft wings (no shield bubble, no damage ladder, small death);
  - `shielded`: default true for Voidsworn, Hegemony, Corsair and Ithar, false for Chorus and Deathless (R3: shields keep faction colours);
  - `flagship`: true adds weight to its death.
- ShipView's placeholder engine glows (`sv.engines`) should be hidden once fx is on (fx draws the engines).
- Engine trails start automatically: the hot core, the plume and the long cooling trail per faction (Corsair sputters and coughs soot). The trail bends behind a moving ship by itself (fx watches the root's motion). Optional: `fx.set_engine(id, level)` with 0 off, 1 cruise (default), 2 full burn (during a `move`, if G2 wants the extra flare).

### Keeping the damage look in step: `sync_ship`

```gdscript
fx.sync_ship(id, unit)                 # unit = this ship's entry in api.view().units
```

Call it after the events that changed a ship have been animated (or simply after every event batch: it is cheap and only acts on changes). From `hp/maxHp`, `sec` (prow, mid, eng), `sh`, `burning` and `dead`, fx sets the staged damage ladder per section:

| Stage | When (per section, hp fraction) | Look |
|---|---|---|
| 0 intact | above 0.8 | clean hull |
| 1 scorched | 0.6 to 0.8 | lit scorch marks, smoke wisps, faint embers |
| 2 dented | 0.4 to 0.6 | more scorch, cracked plates with glowing seams, sparking wire bursts, thin gas jets |
| 3 exposed structure | 0.2 to 0.4 | open patches with ribs and conduits, first small fires, debris shedding |
| 4 hull breach | below 0.2, or the section is broken | a real hole: glowing torn edge, bent plates, venting gas, streaming debris, licking fire, spark showers, secondary pops |
| 5 wreck | `dead` (after `death`) | see section 5 |

- Thresholds are Claude's starting values (vetoable, tuned on screen).
- A stage that goes up while shots are still flying at that ship waits until they land, so holes open when the hit lands, not before.
- `burning` adds deck fires. A broken `eng` section makes the engines sputter and smoke. Shields rising again (`sh`) play a short faction-coloured regen shimmer.

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
- `impacts` are the moments to show floating numbers; `done` is when G2 may start the next event (G2 can start earlier; effects overlap fine).

Travelling torpedoes (B3; ready now, for when the rules change lands):
- `fx.torp_lane(lane_id, attacker_id, to_point, turns)`: a lane on the board from the attacker's bow to `to_point` (world), chevrons running toward an impact marker that pulses, in the attacker's weapon colour;
- `fx.torp_launch(lane_id)`: the torpedo vents, runs out along the lane and holds there, engine burning, until the next turn;
- `var r = fx.torp_strike(lane_id, target_id, hit)`: the two-stage warning (a dim pulse, then a ramp to white, about 0.8 s, K2 pin), then the torpedo closes and strikes (`hit` as in `volley` hits, or `{}` for a miss); returns `{impacts, done}` like `volley`;
- `fx.torp_lane_clear(lane_id)`: the target got out of the lane; the torpedo runs on past the marker and burns out.
Today's rules still resolve torpedoes at once: `volley(..., "torp", ...)` plays launch, flight and impact in one go.

## 4. Shields

- Shield hits come with `volley` (`hits[i].shield > 0`).
- `fx.shield_break(id, quad)` on the `shield_down` event: that facing collapses in the faction's own way (Voidsworn: the gold veil tears with a crackling flare; Hegemony: the blue hex lattice shatters into cells; Corsair: it sputters, flickers and dies in patches with sparks; Ithar: the mint veil folds and sheets away).

## 5. Death and wrecks

```gdscript
var t = fx.death(id, cause)            # seconds until the break-up has played; the wreck stays after
fx.clear_wreck(id)                     # optional: remove the wreck pieces (e.g. at battle end)
```

- `fx.well` (Vector3): the dead star's position; `world.build` sets it on `fx` when given `"fx": fx` in its options (tidal deaths fall toward it).
- `cause` from the `death` event: `cut` (lance: the hull splits along a glowing cut), `big` (torpedo or ram: the biggest fireball, many pieces), `flay` (gauss: perforated and peeled, many small pieces), `melt` (acid or spines: corrosion glow and sagging, few pieces), `dark` (burn-out: lights die, a quiet dark hulk), `tidal` (the dead star: pieces pulled toward the well), `blast` (anything else).
- The sequence: a held beat with lights and engines stuttering, a cook-off of internal explosions along the hull, then the real hull breaks into pieces (Jolt rigid bodies cut from the ship's own mesh, with glowing cross-sections), a final blast and shockwave for heavy ships, embers and debris. The pieces then drift as burning wrecks (fires, vents, occasional sparks, slowly cooling); the biggest piece stays near the ship's hex (the rules' `wreck` event keeps the hulk as terrain).
- fx hides the ship's own meshes at the break-up. G2 can keep or free the root after `t`; fx keeps its own copies of the meshes.
- `fx.jump_out(id)` for `fled`: a short drive flare and streak, then the ship's meshes are hidden.

## 6. Other events

- `fx.ability(id, ab)` and `fx.command(id, cmd)`: a short faction-coloured pulse on the ship (a stand-in until each ability gets its own look; coming).
- `fx.launch(carrier_id, squadron_id)`: bay flare and craft streaming out toward the new wing.
- `fx.tick(id, kind)` for turn-start damage (`fire`, `acid`, `tidal`, `storm`): a small flare-up of that kind on the ship.
- `fx.hull_point(id, section, toward)`: `{p, n}` in world space on the hull (section `"prow"`, `"mid"`, `"eng"` or `""`, on the side facing the point `toward`), for anything G2 wants to anchor there.

## 7. Feel: shake and hit pause

- Shake is a trauma model (trauma squared, smooth noise, decays), positional only, applied to `cam.h_offset` and `cam.v_offset`. Battery light, lance and gauss medium, torpedo heavy, capital death heaviest, all inside the A5 ranges (0.15 to 0.30 s normally, 0.35 to 0.45 s only for capital deaths), and smaller with distance from the camera. `setup({"camera": null})` turns it off; then read `fx.shake_offset()` (a Vector2) and apply it yourself.
- Hit pause never blocks input: fx slows its own clock for a few frames (2 to 6 frames on heavy hits, 7 to 12 on kills of big ships). G2 should multiply its own animation delta by `fx.anim_speed()` (1.0 normally, dips during a pause) so ship motion pauses with the effects.

## 8. Accessibility

- At most 3 counted flashes per rolling second anywhere on screen (WCAG 2.3.2). Flashes inside 0.33 s merge into one; over the budget, flashes draw as smoke and sparks without the bright core.
- `fx.reduce_flashing = true`: no counted flashes at all. Bright pops become expanding rings, particle bursts and a gentle glow rise; muzzle flashes become smoke-forward; fire flicker becomes slow breathing; effect shake halves.
- `fx.shake_scale` (0..1) at any time.

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
| `ram` | `volley(unit, "torp", target, {weapon_id: "ram", hits: [...]})` (ram impact look: coming) |
| any batch end | `sync_ship(id, unit)` for the units that changed |

## 12. Cost

Measured at 4K max detail on Ryan's PC (RTX 5080) in the effects gallery (`godot/fx/gallery/`); numbers per feature are in `godot/fx/gallery/README.md` when the first PC run lands.
