# Sunward Crusade part kit (`voidsworn`)

`parts.py` holds every Sunward part shape the build sheets use (RULEBOOK 4.5: every faction its own kit; only the invisible
geometry plumbing in `tools/blender/kits/shared/geom.py` is shared). First built for the Daybreak flagship sheet, voidsworn_S8
(issue 738). The faction sheet is docs/playbooks/factions.md (Sunward Crusade): "a black iron blade with burning spires";
forged, heavy, vertical; plate with rivet lines, never rust; black iron, frost-white markings, bright ember; never blue light.
The lore is contrib/opus/compute/lore_bible_r8.md section 2 (2.5: heavy broadside decks, old manual gun decks, tall heat
radiator spires; no AI, unaugmented crews).

## Weapons (R221, RULEBOOK 4.11, ships.md 2c)

Each weapon is built from what it is: the data.js weapon entry (W and FAC_WNAMES.voidsworn; the Sear weapons carry the las
trait, FAC_WTRAIT), its battle look (godot/fx/fx_weapons.gd: hbattery `macro`, turret `las`, flak `flak`), the lore and the
faction sheet. The same lines are `WEAPONS` in parts.py, which the sheet's weapon row prints.

| data.js id | Name | What it fires | So it looks like |
|---|---|---|---|
| `hbattery` | Heavy sear broadside | 5 shots, 7 damage, range 5; las: +4 aim | A heavy short gun in an old manual gun deck: a deep round armoured port standing out of the flank (a forged collar with a rolled lip, a ring of rivets, a square riveted surround), a ball mantlet set back in the port, a heat jacket with three cooling rings, a banded barrel, a flared muzzle, a dark bore glowing ember deep inside. One gun per port; a casemate, never a turret. |
| `turret` | Sear turret | 2 shots, 8 damage, range 5; las (a beam) | A low faceted forged dome on a flush riveted ring (never a battleship's box turret on a tall barbette, R185 (5)), one short heavy focusing emitter out of a block mantlet (jacket, cooling rings, a lens collar, an ember lens in the bore), a radiator bustle with ember fins behind: a las weapon sheds its heat like the ship's spires. |
| `flak` | Spark flak | 3 shots, 3 damage, range 2, point defence | A squat forged drum turret, two short barrels in cooling sleeves ending in squared muzzle brakes, an ammunition drum on each cheek, elevating high (to 60) for craft. |

How many mounts a slot may show follows the game's volleys (ships.md rule 11, weapon_match.py SPLIT): five single broadside
guns a side for hbattery's 5 shots, two single Sear turrets for the turret's 2 shots, two twin flak turrets for flak's 3 shots.

## The radiator spire (`radiator`)

The spires shed the reactor's heat (factions.md), so each is all radiator: a forged root socket, a column (iron posts fore and
aft round a dark core) carrying a stack of horizontal radiator fins out to each side that glow ember, rivet lines down the
posts, a forged cap, gusset braces at the root. Never a steeple, a cross, a statue or a mast; the fins lie flat so the glow
reads from the battle camera's 34 degrees and from above. Four profiles (0 blade, 1 stepped, 2 twin, 3 raked) so neighbours
never match (Ryan, R232: "not exactly the same shape for every ship"). Spires are structure (not in `MACHINES`): the spire
line snaps off as one piece along its own peel seam.

## Everything else

- `engine_bell`: a 16-sided drum of forged plate courses with riveted bands and a studded mount collar, struts to a deep bell
  with stiffener rings at the hull's plate pitch and a riveted lip, an ember lining, a hot throat and a glowing plug cone.
- `hatch` (forged round, studded rim), `hatchbox` (armoured lift head), `vent` (heat louvre over an ember-lit recess), `lamp`
  (frost-white running point), `slit` (ember window slit, never a round porthole), `thruster` (round nozzle throats with
  depth, R244).
- `plate_slab`, `forged_plates`, `panels`: forged plating in ordered rows at the hull's plate size in world units, rows offset
  by half a plate on alternate courses, a reinforcing strip on every fifth plate, rivet lines along each plate's long edge;
  `tri=True` lays sleek triangles instead (R243), used on the spearhead's facets. Forged, never scavenged: no patch warp.

Materials (this kit's own `MATS`, merged into the sheet kit's table by the ship file, so the shared kit.py is untouched): `siron` black iron, `siron2` darker recessed iron, `sworn` worked bright
iron, `embar` ember glow, `frost` frost-white lamps, plus the shared `dark`, `glow`, `ember`; insides add `gallery`.

## Squadron craft (issue 769: voidsworn_SF3 fighter, voidsworn_SB4 bomber)

A craft is about a twelfth of the flagship's length, so its parts take every size from their arguments (no fixed world sizes)
and stay bold and simple (fine greeble reads as a shrunken capital ship). Ryan (R254): no canopy, no swept aero wings, no tail
fins, no bombs hung under the hull; drives are nozzle clusters inside armoured blocks.

| Part | data.js | What it is |
|---|---|---|
| `gun(..., weapon='guns')` (`_interceptor`) | `guns` T, Interceptor guns, 3 shots | three short barrels in one emitter cluster on a shallow traverse ring, in an armoured well with a riveted rim; it turns (arc T) |
| `rocket_rack` (the bomb cassette, type `bomb_tube`) | `bombs` T, Bomb payload, 2 shots | a deep armoured cassette that is the bomber's bow face: round mouths with worked-iron twelve-sided rims and forged lugs, dark bores with the next bomb's nose seated deep inside, the bombardier's sight slit between; fixed forward (K.launcher asks every kit for `rocket_rack`) |
| `craft_drive` (`engine_bell(..., craft=True)`) | | a deep bell sunk in an eight-sided armoured cowl whose face stands proud of the lip: ember lining, hot throat, glowing plug, dim |
| `craft_spire` | | the fighter's one radiator spire: upright and square-topped, ember fins out to each side (never a tail fin) |

Scale hooks with unchanged defaults (the flagship builds the same, its fit check counts are identical): `forged_plates(unit=)`,
`plate_slab(sink=, inmax=)`, `vent(fr=)`, `slit(fr=)`; the louvre's back plate and the slit's pane now stay behind the slats and
frame on a small part. `launcher` is a machine (it rides whole with one piece).

