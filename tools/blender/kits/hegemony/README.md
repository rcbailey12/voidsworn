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
| `turbo` | Plasma lance | 2 shots, 9 damage, range 5; plasma | The heavy lance's mount at a smaller size (factions.md: the same parts repeated at different sizes): the same faceted housing, glacis, cheeks, bustle, twin coil barrels. Issue 768: the Iron Mandate's midships bridge turret. |
| `flak` | Picket lasers | 3 shots, 3 damage, range 2, point defence | A small low eight-sided turret on a flush ring, a sensor eye, two short emitter tubes with coil collars and lens tips, elevating high (to 60) for craft. |

How many mounts a slot may show follows the game's volleys (ships.md rule 11, weapon_match.py SPLIT): one twin lance turret a
side for hturbo P and S (3 shots over 2 barrels), one trench for ion F, two twin picket turrets for flak T (3 shots over 4
emitters: both fire every volley).

## Everything else

- `engine_bell`: a rectangular nozzle pod (factions.md: a flat row of rectangular blue-white nozzles): a thick machined lip round
  a rounded-rectangle mouth, inner walls tapering in to a recessed blue-white throat plate, three guide vanes deep in the
  throat, a sleeve of armoured walls with two trim bands (open rings round the walls since R262, so the mouth, the throat and the vanes stay visible) and machined panels, a back block that seats on the hull. The mouth
  carries points along its straight edges so its rim reads all round in the export's open-bell test (check_export.py); keep
  the mouth near square (1.1 by 1.45 passes 12 of 12 sectors; 1.0 by 1.6 does not).
- `antenna`: the one low sensor fin (factions.md: never a tower): a root plinth, a swept fin with sensor windows, a lens strip,
  a trim band. A machine (MACHINES) and a sensor kind for the R240 test (clash.py SENSOR_KINDS), so no gun may fire through it.
- `bay`: flush armoured drone doors (R232): a trim frame, two door leaves with ribs, a centre seam, blue guide lamps.
- `latch`: a module latch row, the four clamp heads that lock two hull modules together across a module band (H10's rows of
  four blocks).
- Canyon plant (issue 768, the Iron Mandate, hegemony_IM5): `pipe`, an armoured power trunk (an eight-sided trunk, trim collars
  at an even pitch, a flange at each end, saddles down to the floor; structure, so it stops at a coupling short of each module
  band); `capbank`, a capacitor bank of identical cells on a plinth with trim caps, blue charge strips and bus bars;
  `exchanger`, a heat exchanger (a housing, a stack of cooling fins in a trim frame, inlet and outlet ports). The bank and the
  exchanger are machines (MACHINES): each sits whole in one module.
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

## Paint (issue 780)

`stack.py` is the Hegemony paint stack: what every zone above is made of (the colours sampled from H10, the even grid in two
module sizes, the module band at each `*_bandseam_*` joint, the blue line and the nozzle glow under the 0.8 threshold, the
stencil decals). The direction is contrib/muse/design/paint_direction_2026_11/hegemony.md; the method is RECIPE.md, "The
Hegemony stack". A sheet that has no `*_bandseam_*` object stops the stack: the direction puts a band at every module joint.

## Squadron craft (issue 793: hegemony_HF1D, the fighter)

A craft is about a twentieth of the Iron Mandate's length, so its parts take every size from their arguments (no fixed world
sizes) and stay bold and simple (fine greeble reads as a shrunken capital ship). Ryan (R254): no canopy, no swept aero wings, no
tail fins, nothing hung under a hull; drives are nozzle clusters inside armoured blocks.

| Part | data.js | What it is |
|---|---|---|
| `gun(..., weapon='guns')` (`_cassette`) | `guns` T, Interceptor guns, 3 shots | three short containment barrels grouped tight in one machined cassette box (coil bands, a trim mouth, blue lenses deep in the bores), on a low flat housing over a flush ring sunk in a framed recess; it turns (arc T) and rests facing forward out of its frame |
| `craft_drive` (`engine_bell(..., craft=True, w=, h=, cells=3)`) | | one wide rectangular slit split by upright guide vanes into a row of cells (the faction's flat row of nozzles), a thick machined lip, a blue lining tapering to a blue-white throat plate, an armoured pod with a trim band |

Scale hooks with unchanged defaults (every capital sheet builds the same): `module_panels(unit=)` (the smallest face that takes
panels and the panels' sink), `panel_slab(sink=)`, `slit(fr=, back=, pane=)`.
