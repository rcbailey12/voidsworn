# Battle rules API (G1, for the G2 scene)

The battle rules live in `godot/rules/` (GDScript, a line-for-line port of the game's `battle.js`). They are golden-tested against the JS game on every turn (`tools/pc/parity.bat`).

The scene talks to the rules through one object, `battle_api.gd`. The scene never writes rules state:
- it sends **commands**;
- it reads **`view()`** to draw;
- it plays the **event stream** to animate.

Everything below is stable. A change to this contract lands in this file in the same commit.

## Setup

```gdscript
const API = preload("res://rules/battle_api.gd")
var api = API.new()
var err = api.load_rules()            # loads res://rules/data/tables.json (the game's data.js, exported); "" when fine
api.new_battle_scenario("s1")         # a test battle from rules/test/scenarios.json (s1 to s5 today), or a dict with the same fields
# or, from the campaign (G3):
api.new_battle(run, cfg)              # run = the campaign run dict (admiral, fac, sector, fleet of ships, relics, boons, flagUid ...)
                                      # cfg = {kind, fac, col, seed, obj, shape, map, dep, arch, mod, enemies?, campaign?, event_force?, alt?}
```

- **Fleet:** without `cfg.enemies`, the enemy fleet is generated exactly as the game does (`genEnemyFleet`: archetype `arch` = swarm, heavy or carrier, `mod` = bounty, the sector ramp, your fleet's power, the AI level and heat). Two or more carriers on your side (a carrier admiral or the hive aspect counts as one more) draw point-defence refits and a fighter screen.
- **Campaign battles:** pass `cfg.campaign = true` as campaign3d.js does. The rules then roll the mid-battle event (reinforcements for either side, or a solar flare) from the seeded generator; `cfg.event_force` forces one (`"reinf_enemy"`, `"reinf_ally"`, `"flare"`), as the campaign does in sectors at war. Both keys are removed from `cfg` before the battle starts.
- **Classic mode:** `cfg.alt = false` plays whole turns instead of alternating activations (the game's setup option). See "Classic mode" below.
- **AI level:** `api.R.AI_LEVEL` is `"veteran"` (the game's default) or `"standard"`. Set it before `new_battle`.
- **Opening state:** after setup, `api.phase` is `"player"`, and the event stream holds `round 1` and `side player`.

## The turn flow (alternating activations, as the game plays by default)

`api.phase` is one of:
- `"player"`: waiting for the player;
- `"enemy"`: call `step()`;
- `"over"`: the battle has ended.

1. **Player phase.** The player picks one of their ships that has not yet acted this round. The first command a ship receives makes it the active ship.
   - The active ship can move, fire each ready gun, use its ability and give an order until it is done.
   - The activation ends by itself when the ship has no movement left and no gun that can fire, or when it dies. Otherwise call `end_activation()` ("End activation").
   - With no ship active, `end_activation(id)` passes that ship ("holds position"). `end_activation()` with no id passes the turn when nothing is pending.
2. **Enemy phase.** `phase` becomes `"enemy"`. Call `api.step()` once per enemy activation; each call runs one enemy ship's whole activation and returns its events.
   - While enemy ships remain but you still have ships to act, the enemy acts once and play returns to you.
   - When your ships are all done, the remaining enemies act one per `step()`.
   - The round change (turn-start ticks: shields regenerate, fires burn, cooldowns tick) happens inside the `step()` that finishes the round, and its events come back with that step.
3. **End.** `phase` becomes `"over"` and the events end with `{t: "end", result: "win" | "loss"}`.

**Thinking during animation:**
- `step()` touches only rules state and returns plain events, so it is safe to run on a worker thread (`WorkerThreadPool`) while the scene is still animating the previous events.
- Don't call anything else on `api` until it returns.
- The rules run ahead of the picture; the scene plays the events at its own pace.
- That hides enemy think time behind the previous ship's animation. Worst think measured so far: 0.35 to 0.69 s per activation in the cloud on 10-against-10 battles; PC numbers come from `parity.bat` step 5.

## Classic mode (whole turns)

With `cfg.alt = false`:
- In the player phase every ship can move, fire, use its ability and take orders in any order; nothing ends by itself and `end_activation` does nothing.
- `end_turn()` ("End turn") ends your turn. `phase` becomes `"enemy"`: the enemy turn-start ticks happen, then call `step()` once per enemy activation, as in alternating mode. The game's `aiTurn` order is kept: the enemy's squadrons first, then each next ship picked by opportunity.
- The step that finishes the enemy turn also runs the new round: `round`, your turn-start ticks, your squadrons' swarm phase, then `side player`.

## Commands (player side, the same path the game UI uses)

All return `true` when the action happened. They do nothing (return `false`) when it is not the player phase, the ship is not the player's, it has already acted, or another ship is the active one.

| Call | What it does |
|---|---|
| `reach(id) -> Array` | Every end state the ship can move to: `{q, r, f, cost, t, path}`. `f` is the facing (0 to 5), `t` the turns used. Pass one of these to `move`. |
| `move(id, state)` | Burn along `state.path` (thruster slips, reverses, climbing over rocks and diving under ships are in the path steps). |
| `can_fire(id, wi, target_id) -> bool` | Range, arc, line of sight, readiness. |
| `preview_fire(id, wi, target_id) -> Dictionary` | `{hit, shield, hull, quad, rear, can}`: hit %, expected shield and hull damage, the target's facing quadrant (0 prow, 1 starboard, 2 rear, 3 port). |
| `fire(id, wi, target_id, called_section = null)` | Fire weapon `wi`. `called_section` is `"prow"`, `"mid"` or `"eng"` for an aimed shot. |
| `ability(id, arg = null)` | The ship's ability. `arg = {hex: {q, r}}` for nova, blink and launch (launch also takes `kind`). |
| `order(id, kind)` | `"brace"`, `"full"` (full ahead), `"lock"` (lock on) or `"helm"` (an extra turn). |
| `ram(id)` | Ram the enemy ship dead ahead (needs a run-up). |
| `board(id, target_id)` | Board an adjacent enemy. |
| `end_activation(id = null)` | End the active ship's activation, or pass ship `id`. Starts the enemy phase. (Alternating mode only.) |
| `end_turn()` | Classic mode only: end your whole turn. |
| `rotate(id, dir)` | Turn in place one step (`dir` = +1 or -1), costing one movement point and one turn (free for ships that pivot). As in the game, the ship becomes the active one even when it cannot turn; returns whether it turned. |
| `can_command() -> bool`, `command()` | The Admiral's Command: once per battle, from round 1, during your phase, no ship needed. The game asks for a confirming second tap; that is UI only. |
| `wing_order(wing_id, target_id)` | A standing order for one of your squadrons: an enemy ship means strike it until it dies, one of your ships means guard it. Works any time before the end. The wing acts on it in its next swarm phase. |
| `hurry()` | Enter or Space. Presentation only: the rules do not change. Play the queued events faster. |

**Selection** is UI state only: there is no rules call for it.

**Squadrons** (`squadron: true` in `view()`) are never activated by the player. Both sides' wings fly in the swarm phases at the start of each round (yours first), and the enemy's also act just before an enemy ship in `step()`. The Scramble Command gives every wing an extra strike at once. Launching a replacement wing is the carrier's `ability` (with `{hex, kind}`, kind `"fighter"` or `"bomber"`).

## Reading state: `view()`

`view()` is a plain copy, safe to keep and to read from any thread after a call returns. Ships move between `view()`s only through events.

```
{round, side, phase, over, arena, terrain: {"q,r": "rock"|"hulk"|"station"|"planet"|"neb"|"debris"|"storm"},
 cut: ["q,r", ...] (hexes cut away from the board), map: {map, shape, station?, planet?, wrecks?, deadstar?, holes?},
 obj: {type, score, escore, ...}, focus: id of the enemy fleet's current focus target or null,
 units: [{id, side, tpl, name, cls, fac, size, squadron, q, r, facing, hp, maxHp, sh: [prow, starboard, rear, port], shMax,
          sec: {prow: {hp, max, broken}, mid: {...}, eng: {...}}, crew, crewMax, dead, fled, activated, active, braced,
          mp, turnsLeft, ab, abCd, abReady, burning, flagship,
          weapons: [{i, id, name, kind, arc, range, ready, cd, off}]}]}
```

- **Hexes** are axial `(q, r)`, pointy-top.
- **Facing** `f` points at `DIRS[f]` = `[[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]]` (0 is +q, screen angle `f * 60` degrees).
- **Hex centre:** `x = HEX_W * (q + r/2)`, `z = -1.5 * HEX_S * r`, with `HEX_S = 10` and `HEX_W = 10 * sqrt(3)` (the game's scene3d spacing).

## The event stream: `take_events()`, and the return of `step()`

Events come in order. Every event has a `t` (type) and plain fields; ids are ship ids from `view()`.

| `t` | Fields | Meaning |
|---|---|---|
| `round` | `round` | A new round begins (turn-start ticks follow as `tick`, `burning`, `death` ...). |
| `side` | `side` | `"player"` or `"enemy"` is now acting. |
| `activation` | `unit, side` | This ship (or squadron, in a swarm phase) starts its activation. |
| `move` | `unit, path, late_fire` | Animate the burn along `path` (steps `{q, r, f, rot?, slip?, rev?, over?}`). With `late_fire`, the ship's shots that follow are fired on the move (start them about two-thirds of the way through the burn). A turn in place is a one-step path with `rot: true`. |
| `fire` | `unit, weapon, weapon_id, kind, arc, name, target, shots: [bool], pd, quad` | One weapon's volley: one entry per shot (hit or miss). `pd` is rockets shot down by point defence; `quad` is the target facing hit. |
| `hit` | `unit, target, quad, section, shield, hull, crit` | One landed shot: shield damage absorbed, hull damage taken, which section, whether it was a critical. `unit` can be null for station guns. |
| `shield_down` | `unit, quad` | That facing's shield is gone. |
| `section_down` | `unit, section` | `"prow"` (forward guns silenced), `"mid"` (broadsides and shield generator), `"eng"` (engines crippled). |
| `system` | `unit, text` | A critical knocked out a system ("Engines hit", "Shield generator down", "<gun> knocked out", "Fire on deck"). |
| `burning` | `unit` | The ship is set on fire. |
| `tick` | `unit, kind, hull` | Turn-start damage: `"fire"`, `"acid"`, `"tidal"` (dead star), `"storm"` (ion storm, shields only). |
| `pulled` | `unit, from, to` | The dead star's gravity dragged the ship one hex. |
| `ability` | `unit, ab, hex` | An ability fired (evasive, reload, focus, phase, frenzy, overburn, regrow, reclaim, ionpulse, blink, surge, launch, nova). |
| `wing` | `unit, parent, kind, q, r` | A squadron appears next to its carrier (opening wings, a launch, Scramble, the enemy's fighter screen). `kind` is the hull id: fighter, bomber or spore. |
| `blink` | `unit, from, to` | An Ithar phase jump: the ship vanishes at `from` and appears at `to` (no path). |
| `order` | `unit, order` | brace, full, lock or helm. |
| `ram` | `unit, target, path, dmg, recoil, soak, section` | The ram run-up and impact. |
| `board` | `unit, target, result, kill, loss` | `result`: `"capture"` (the ship changes side), `"overrun"` (flagships and your ships hold the bridge), or `"raid"`. |
| `command_warning` | `side, id, round, unit` | The enemy flagship announces its Command for next round. |
| `command` | `side, id, tier, unit` | A Command fires (barrage, hunt, iron, restore, surge, scramble). |
| `death` | `unit, cause, by` | Play the death; `cause` picks the look: `cut` (lance), `big` (torpedo, ram), `flay` (gauss), `melt` (acid, spines), `dark` (burn-out, lucky battery hit), `tidal`, `blast`. |
| `wreck` | `unit, q, r` | The hulk stays on the board as blocking terrain. |
| `fled` | `unit` | The ship left the battle (escorts fleeing, a breakthrough, a convoy getting through). |
| `log` | `text, kind` | A battle log line, word for word as the game writes it. `kind` is the game's colour class: `p` (good for you), `e` (bad for you), `s` (a success), `x` (neutral), `ember` (warnings), or null. |
| `end` | `result` | The battle is over. |

**Not events:** the game's floating callouts (`fxText`: "-12 hull", "Shields down", "Critical") are presentation only and carry no rules information beyond the `hit`, `shield_down`, `system` and `log` events, so the scene draws its own from those.

## Determinism (audit items, Oct 26)

- **Ship ids** are deterministic: `x0` followed by a counter that starts at 1 for every battle (the JS oracle pins `Date.now()` to 0, so its ids are the same). No timestamp exists anywhere in rules state or in the hash.
- **Sorting:** every sort in the rules is a stable merge sort with the JS comparator (`JSM.ssort`, matching JS's stable `Array.prototype.sort`). Ties keep their insertion order, which is itself deterministic, so every ordering has a total tiebreak.
- **Randomness:** all rules randomness comes from the game's seeded PRNG (`JSM.rnd`). Cosmetic randomness in the scene must use its own generator, never `JSM.rnd`.
- **Maths:** sin, cos, atan2, exp, hypot and round are V8's exact algorithms, so results are identical on every machine.
