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
- On the loading screen, after ships, lights and world are built: `await fx.warmup(cam)` (draws every effect material once, so the first lance, shield ripple or death never stalls on a shader compile).
- Clean quit: fx releases its GPU resources when its node leaves the tree; `FX.clear_static()` releases every live fx at once (G2's `quit_clean`).
- Safe mode (the Compatibility renderer, `play_godot_safe.bat`): fx and world detect it and drop raymarched volumes, distortion and the lens; everything else plays. Hull damage and every weapon mark draw in safe mode too (they are hull geometry plus an overlay mesh, not Decals); the ion burn uses a cheaper pattern there.
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
  - `meshes`: Array of the hull MeshInstance3Ds. **Pass `sv.meshes` from ShipView** (the default, every MeshInstance3D under `root`, would also take in the selection ring and the footprint marker). fx reads their triangles once (hit points, breach placement, death pieces), never changes their materials, and hides them at the break-up of a death. From damage stage 2 fx swaps in a rebuilt copy of a damaged hull's mesh (same materials, same vertex format, the override materials kept; section 14), so G2 must not cache or reassign `mesh` on these nodes during a battle;
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
| 1 scorched | 0.6 to 0.8 | scorch spreading over the plating round the struck area (an overlay on the hull that glows faintly, then cools dark), a thin wisp of smoke |
| 2 dented | 0.4 to 0.6 | the hull itself dents and wrinkles; a wider blackened patch, sparking wires, a thin gas jet |
| 3 holed | 0.2 to 0.4 | a hole cut in the real hull: plates bent back, the ring round it buckled, a cavity with frames, decks and conduits lit by fire inside; embers, sparks at torn conduits, gas, thin smoke; debris shedding |
| 4 hull breach | below 0.2, or the section is broken | the hole grows, plus a buckled panel and (medium ships up) a bite out of an upper edge, so the silhouette changes; streaming debris, spark showers, dull internal pops |
| 5 wreck | `dead` (after `death`) | see section 5 |

- Thresholds are Claude's starting values (vetoable, tuned on screen).
- A stage that goes up while shots are still flying at that ship waits until they land, so holes open when the hit lands, not before.
- A section whose stage falls back to 1 or 0 (repair) also loses its weapon marks (section 14), so the hull never disagrees with the game.
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
- Every hull hit leaves its weapon's own mark in the hull itself (R43, section 14): a lance burn-through, a light blue plasma splash crater with a droplet fan, a gauss entry with a stress ring and a spalled exit, a torpedo blast hole with plates blown inward, flak pockmarks, Chorus acid pitting with spines, an ion branching burn, a ram crumple (and a smaller one on the rammer's bow). Shield-only hits leave no hull mark.
- Every hit also moves the ship (R50, section 7): mass-scaled, by the weapon's momentum.
- Plasma is light blue whoever fires it (Ryan, Oct 26): bolt, splash and crater.
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
- `var t = fx.board(attacker_id, target_id, result)` on the rules' `board` event: a breach in the target's hull at a plausible boarding point (its side facing the attacker, mid section), venting gas and lit from inside for about 3 s, then a dark gash that stays as a mark. Returns seconds until it has played. (G2: this replaces the stub flash at the board event.)
- `fx.hull_mark(id, look, w, world_p, dir, sec)`: a weapon mark without a volley (look as in volley, plus `board` and `ram`).
- `fx.tick(id, kind)` for turn-start damage (`fire`, `acid`, `tidal`, `storm`): a small flare-up of that kind on the ship.
- `fx.hull_point(id, section, toward)`: `{p, n}` in world space on the hull (section `"prow"`, `"mid"`, `"eng"` or `""`, on the side facing the point `toward`), for anything G2 wants to anchor there.

## 7. Feel: shake and hit pause

- Shake is a trauma model (trauma squared, smooth noise, decays), positional only, applied to `cam.h_offset` and `cam.v_offset`. Battery light, lance and gauss medium, torpedo heavy, capital death heaviest, all inside the A5 ranges (0.15 to 0.30 s normally, 0.35 to 0.45 s only for capital deaths), and smaller with distance from the camera. `setup({"camera": null})` turns it off; then read `fx.shake_offset()` (a Vector2) and apply it yourself.
- Hit pause never blocks input: fx slows its own clock for a few frames (2 to 6 frames on heavy hits, 7 to 12 on kills of big ships). G2 should multiply its own animation delta by `fx.anim_speed()` (1.0 normally, dips during a pause) so ship motion pauses with the effects.

### Hit reactions (R50)

A hit no longer just flashes: the ship reacts with its mass. A short shudder runs through the hull, a roll, pitch or yaw kick comes from where the hit lands, and attitude thrusters visibly fire (small gas puffs at the hull's corners, picked so their thrust opposes the motion) until the ship settles. Torpedoes and rams shove, shells and gauss slugs kick, light guns tap, lances and ions are energy and barely move a ship. Mass by class: a frigate takes a real jolt (a torpedo rolls it about 6 degrees and moves it about 3% of its length; settled in under 3 s); a super-dreadnought barely moves (a torpedo: about 1.4 degrees, 0.6% of its length; settles over 4 s). Heavy hits also make the drive stutter. The camera shake (above) scales with the hit and distance and follows `shake_scale`. Measured by `fx/test/fx_react_probe.gd`.

**For G2 (shared root):** fx writes the ship root's `rotation.x` and `rotation.z` (roll and pitch; ShipView never writes them) while a reaction plays and sets them back to 0 when it settles. Yaw and the small drift are added to `rotation.y` and `position` only while `root.busy()` is false (ShipView writes position and yaw itself during a path); fx takes its own offset back out when the ship settles, and drops it when a path starts. G2's weighty movement (R50 part 2) can keep its own RCS puffs for turns and burns; fx's puffs only answer hits. If G2 later wants to own the whole root, `fx.ship(id)._ra` (angles) and `_pd` (drift) are the state to read instead.

## 8. Accessibility

- At most 3 counted flashes in any rolling second anywhere on screen (WCAG 2.3.1). Flashes landing within 0.12 s of each other (a salvo) count as one (`FLASH_WINDOW` in fx.gd). The count is a trailing window: the second up to a flash may hold at most 3 counted flashes, that one included (a flash booked ahead by a volley also keeps its own trailing second within 3). Over the budget, a flash draws as a soft lift, smoke and sparks without the bright core, and draws no light.
- What counts: every short (0.6 s or less), bright (intensity 4 or more) flash-like sprite (flash, fireball core, beam charge, impact flare) that covers at least 6% of the screen height, whoever spawns it (the check sits in `fx.spr`, so muzzle cores, beam contact, secondary pops and death flames are all covered), and every decaying event light with a peak of 8 or more. Smaller flashes and sparks are under the WCAG area threshold at battle zoom and are free; close up they count. `fx.flash_log` lists every counted flash (the smoke test fails if any rolling second holds more than 3).
- `fx.reduce_flashing = true`: no counted flashes at all, and every bright flash-like sprite becomes a soft lift whatever its size (WCAG 2.3.2). Bright pops become expanding rings, particle bursts and a gentle glow rise; muzzle flashes become smoke-forward; fire flicker becomes slow breathing; effect shake halves.
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
| `ram` | `volley(unit, "torp", target, {weapon_id: "ram", hits: [...]})`: the ram's crumple on the target, a smaller one on the rammer, the biggest shove |
| `board` | `board(unit, target, result)` |
| any batch end | `sync_ship(id, unit)` for the units that changed |

## 12. Cost

Ryan's PC (RTX 5080), 4K max detail, the gallery's 26 s reel (`godot/fx/gallery/README.md` has the table): everything 5.78 ms a frame against 4.18 ms with no effects, so the effects layer costs about 1.6 ms; the world 0.5 ms; physics 0.03 ms. High quality saves about 1.75 ms. Call `fx.warmup(cam)` on the loading screen so no shader compiles mid-fight.

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

## 14. Hull damage geometry and weapon marks (generic cut now, A4's pre-cut parts when present)

From stage 2 the hull itself changes (fx_breach.gd). The rebuild runs on a worker thread from the hull's original arrays
(about 0.6 s for a 38k-triangle hull on a desktop CPU, 1.5 to 3 s in the cloud sandbox) and is applied in one frame;
the opening blast covers the gap. The rebuilt mesh keeps the hull's materials and vertex format, so nothing new compiles.
The death pieces are re-cut from the damaged hull afterwards.

**Generic cut (every hull, today).** Per damaged section, at one anchor that stays put as the stage grows:

| Stage | Hull change |
|---|---|
| 2 | dent: the skin pushed in with wrinkles (radius 5% of the ship's length) |
| 3 | hole, radius 3% of length: triangles inside a torn outline removed (radial tears between 4 or 5 petals), the ring round it peeled back as bent plates, a wider ring buckled in; a cavity behind it from the removed skin pushed inward (rubble floor, frames and decks sliced through it, conduits, cables, the plates' backs, the skin's cut thickness), lit by a fire point inside |
| 4 | the hole at 4.6%, a buckled panel elsewhere in the section, and (medium ships up) a 3.2% hole on an upper edge, which through thin hull goes right through and bites the silhouette |

**Weapon marks (R43).** Every hull hit adds a mark entry at the hit point (fx_breach.marks_for, by look and weight), built by the same rebuild as the breaches: the mark changes the hull geometry where its kind needs it and lays an overlay skin with its surface (char, molten metal cooling white to red to black, light blue plasma slag, spall, acid etching, electrical burns, scraped metal).

| Look | Mark | Geometry | Surface |
|---|---|---|---|
| lance, needle, pulsar, las | burn-through | a narrow slot cut across the line of fire with raised molten lips (through thin hull) | molten lips white, then red, then black; temper colours past them |
| plasma (laser, turbo, hturbo) | splash crater | a melted bowl, no hole | light blue slag pockets that set as dark glass, slag runs, a fan of droplets thrown out along the shot |
| macro, battery, rockets | shell crater | a shallow crater | char fan, brief orange slag |
| auto, scatter, guns | chips | small pits, nothing torn through | pockmarks and scratches |
| gauss | entry and exit | a small clean hole; a bigger exit on the far side with plates spalled outward | a pale, broken stress ring with radial cracks round the entry (reads at fleet distance) |
| torp, star | blast hole | a wide hole with its plates blown inward, a cavity with frames and decks, fire inside | char fan |
| flak variants | pockmarks | a stippled patch, never through the hull | grey rash, brief sparkle |
| spine, tendril, spores | acid pitting | pits, a few eaten through; spines stuck in along the shot | wet green-black etching that spreads for a few seconds, then stops and goes matte |
| ion, doom | electrical burn | none | a branching (Lichtenberg) burn, arcs crawling it at first, then a dark etched fern |
| ram | crumple | a deep fold of the plating at the bow or the struck side | scraped bare metal, no glow |
| board | boarding breach | a pried square hatch, plates bent out, lit inside | char |

Budget: at most 4 marks per hull section and 12 per ship (sections 0 eng, 1 mid, 2 prow). A repeat of the same mark close by (anywhere in the section for a torpedo crater or an ion burn) rebuilds the old one bigger and fresh (up to 1.6 times) instead of placing a twin; past the section budget the oldest shell crater or pockmark goes first, then the oldest mark. A section repaired back to stage 1 or 0 loses its marks. The section breaches (stages 2 to 4) and the stage scorch come on top of the budget.

Cost (cloud sandbox CPU, about three times slower than Ryan's PC; the PC numbers are in the gallery README once measured): a single mark rebuilds a 38k-triangle hull in 70 to 260 ms on a worker thread; the main thread only swaps in the meshes built there (a few ms). All rebuilds start from the hull's original arrays and keep its vertex format, so nothing compiles.

**A4 pre-cut parts (agreed with A4, Oct 26; fx wires them in when the first files land).** Per ship:

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
4. Swap: stage 3 shows `breach_<n>_hole` and hides `skin_<n>`; stage 4 shows `breach_<n>_heavy` and hides
   `breach_<n>_hole`, `skin_<n>` and `skin_<n>_heavy`. The anchor is the same n as `hp_breach_<n>`; fx picks the anchor
   for a section from `extras.section`, puts its fire, gas, sparks and embers at `p` along `n`, and keeps the generic
   cut away from that anchor. Stage 2 dents stay generic.
5. **G2's part:** res://gen hulls are a single Mesh today, so the `skin_<n>` children would be lost. fx looks first for
   (a) the hull scene in gen with `skin_<n>` MeshInstance3D children named exactly that, plus
   `res://gen/damage/<CODE>_damage.scn`; then for (b) `res://assets/ships/<CODE>/<CODE>.glb` and `<CODE>_damage.glb`.
6. Death pieces: the wreck is built from the hull as it is at the time of death (intact parts plus whatever is cut).
