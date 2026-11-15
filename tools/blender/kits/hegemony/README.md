# Hegemony Navy part kit (`hegemony`)

`parts.py` holds every Hegemony part shape the build sheets use (RULEBOOK 4.5: every faction its own kit; only the invisible
geometry plumbing in `tools/blender/kits/shared/geom.py` is shared). First built for the Dominion dreadnought sheet,
hegemony_H10 (issue 759). The faction sheet is docs/playbooks/factions.md (Hegemony Navy): "a pale wedge with a line of blue
light"; machined, modular, horizontal; flush panels, straight seams, repeated modules; never rust, asymmetry, ornament or warm
light. The paint direction (contrib/muse/design/paint_direction_2026_11/hegemony.md, approved Nov 14) sets the even grid, two
module sizes, the module band as structure and flush fasteners (no rivet lines). The lore is contrib/opus/compute/lore_bible_r8.md
section 3 (the Registry's fleet: rows of identical turrets, plasma weapons in light blue, ion tech from the captured core Vyre,
drone escorts, retro thrusters).

## Weapons (R221, RULEBOOK 4.11, ships.md 2c)

Each weapon is built from what it is: the data.js weapon entry (W and FAC_WNAMES.hegemony; laser, turbo and hturbo carry the
plasma trait, FAC_WTRAIT), its battle look (godot/fx/fx_weapons.gd: hturbo `plasma`, ion `ion`, flak the Hegemony picket
lasers), the lore and the faction sheet. The same lines are `WEAPONS` in parts.py, which the sheet's weapon row prints.

| data.js id | Name | What it fires | So it looks like |
|---|---|---|---|
| `hturbo` | Heavy plasma lance | 3 shots, 9 damage, range 6; plasma: slow fat bolts with a corona | A low wide armoured mount sunk in a shoulder pit (R185 (4): never a tall round turret with long thin barrels): a flush ring, a faceted housing with a sloped glacis and armoured cheeks, a capacitor bustle with a blue charge strip, a deep mantlet, two short thick containment barrels (a heavy breech sleeve, accelerator coil rings with a blue glow between them, a vented eight-sided muzzle shroud, a blue-lit bore). |
| `ion` | Ion cannon | 1 shot, 12 damage, range 6; strips shields | An emitter trench recessed in the blunt bow face (R183 (1): never a barrel or prongs on the nose): wall liners, stacked field coil plates standing round the trench at an even pitch, an emitter block on the back wall with a blue lens, feed conduits along the floor. `spinal()`, type `ion_trench`; the muzzle is on the lens, the firing lane starts at the mouth. |
| `flak` | Picket lasers | 3 shots, 3 damage, range 2, point defence | A small low eight-sided turret on a flush ring, a sensor eye, two short emitter tubes with coil collars and lens tips, elevating high (to 60) for craft. |

How many mounts a slot may show follows the game's volleys (ships.md rule 11, weapon_match.py SPLIT): one twin lance turret a
side for hturbo P and S (3 shots over 2 barrels), one trench for ion F, two twin picket turrets for flak T (3 shots over 4
emitters: both fire every volley).

## Everything else

- `engine_bell`: a rectangular nozzle pod (factions.md: a flat row of rectangular blue-white nozzles): a thick machined lip round
  a rounded-rectangle mouth, inner walls tapering in to a recessed blue-white throat plate, three guide vanes deep in the
  throat, a sleeve of armoured walls with two trim bands and machined panels, a back block that seats on the hull. The mouth
  carries points along its straight edges so its rim reads all round in the export's open-bell test (check_export.py); keep
  the mouth near square (1.1 by 1.45 passes 12 of 12 sectors; 1.0 by 1.6 does not).
- `antenna`: the one low sensor fin (factions.md: never a tower): a root plinth, a swept fin with sensor windows, a lens strip,
  a trim band. A machine (MACHINES) and a sensor kind for the R240 test (clash.py SENSOR_KINDS), so no gun may fire through it.
- `bay`: flush armoured drone doors (R232): a trim frame, two door leaves with ribs, a centre seam, blue guide lamps.
- `latch`: a module latch row, the four clamp heads that lock two hull modules together across a module band (H10's rows of
  four blocks).
- `hatch` (flush rectangular, a seam and a recessed grip), `hatchbox` (a module housing), `vent` (straight slats over a dark
  recess), `slit` (a blue-white window), `thruster` (rectangular nozzles with depth, R244), `lamp` (a blue strip lamp; sheets
  use the blue line instead, the strips are the running lights).
- `module_panels`: flush panels in an even grid at the hull's module pitch in world units (the ship lays the rings at that
  pitch so seams line up across faces), two module sizes (every third row's cells split in four, symmetric across each face so
  port and starboard match), a machined chamfer on every panel, no rivets. Never warped or banded (R243: "Hegemony also pretty
  rigid and clean").

Materials (this kit's own `MATS`, merged into the sheet kit's table by the ship file, so the shared kit.py is untouched; it is
hashed into the A16 fixture check): `hgrey` hull modules, `hgrey2` recessed fields and seams, `hpanel` the small modules,
`htrim` steel-blue trim, `hmetal` machined metal, `hblue` implant-blue strips, `hlens` weapon lenses, `hnozzle` and `hlining`
the nozzle glow, `hwin` windows; insides add `hcorr` (white corridors), `hrack` (racks of identical equipment) and `hemerg`
(blue emergency light).
