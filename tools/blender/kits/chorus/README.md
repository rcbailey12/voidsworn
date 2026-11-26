# The Chorus part kit (`chorus`)

`parts.py` holds every Chorus part shape the build sheets and the build use (RULEBOOK 4.5: every faction its own kit; only the
invisible geometry plumbing in `tools/blender/kits/shared/geom.py` is shared). Made for issue 623 (the C10 and C11 build sheets).
The faction sheet is docs/playbooks/factions.md (The Chorus); the lore is contrib/opus/compute/lore_bible_r8.md section 5.

The Chorus are grown, not built: ridges, pores, veins, glowing sacs, tendrils, brood sacs and regrowing scar tissue. No panels,
no pipes, no metal, no eyes, no face, no legs, no grub segments. Dark olive flesh, ochre bone and chitin, bile yellow-green light
from inside (R204: the colour is fixed in the build). Where a built ship has plate steps, bevels and rivets, a grown one has
creases, fold rolls, growth lines, grip rings and pores: that is how every part carries the hull's detail density (R224), and
the sheet measures it per part type.

## Weapons (R221, RULEBOOK 4.11): a weapon is an organ

| data.js id | Name | What it fires and how | So it looks like |
|---|---|---|---|
| `bioplasma` | Spine volley (Bile spray) | 2 shots, 10 damage, range 4; trait spines (strips armour); the effect: wobbling globs that splash and corrode | A throat, not a barrel (`spinal`): a muscular root grown out of the head, rolled fold lips (`folded`, C10) or a flared rim (`flared`, C11), an inner sphincter that squeezes the shot, a ring of chitin spines (the spines it spits inside each glob), a dark bore and the bile gland glowing at its back. Fixed forward. |
| `tendril` | Acid Thorns (was Boarding tendrils) | 2 shots, 11 damage, range 1; trait acid (through shields and armour); the effect: one built bone thorn a shot that sticks, then crumbles (issue 1877) | On the ship: still the tendril crown or mane below until the hulls' next rebuild grows a thorn gland there (follow-up). The thorn itself is a munition body (tools/blender/build_sheets/munitions/munitions.py `chorus_bolt`), built from this kit's blob, tube, pore and spine_blade with the hull zones. |
| `spores` | Spore cloud (Spore drifts) | 3 shots, 4 damage, range 2; flak, x3 against craft | A spore gland, not a flak gun: a veined sac hanging from a neck collar under the belly, its spout curling forward to a rosette of pores that puff the cloud; it swings on its neck (a turret). |

`WEAPONS` in parts.py holds the same lines (the sheet's weapon row prints them).

## Other parts

| Part | Builder | Sub-parts (SUBPARTS) | Job |
|---|---|---|---|
| pulse vent (engine) | `engine_bell` | root, fold, sphincter, throat, glow, membrane or filament | drive: a muscle cone squeezes bile gas out through a sphincter mouth; membrane veils (C10) or filaments with glowing nodes (C11) trail from the rim, splayed away from the ship's axis so none hangs in a neighbour's jet. No nozzle. |
| siphon | `thruster` | collar, lip, bore | attitude: a puckered jet pore that squirts to swing the body |
| sac | `sac` | root, sac, crease, vein, glow, pore | bile reservoirs and regrowth sacs: a dome in a socket of wrinkle rolls, glow windows where the bile shows through |
| brood sac | `sac(kind='brood')` | root, sac, crease, slit, lip, vein, pore | the hangar: spore swarms grow inside and are born through the slit between two lip rolls (the fit check keeps the slit's opening clear) |
| bone blade | `spine_blade` | collar, blade, growth, edge | ram and guard blades: a raked shard with growth lines and a serrated front edge, growing out of a collar of raw tissue |
| chitin scute | `chitin` | plate, rim, growth | ochre armour trim: a domed plate with a raised rim and growth lines; laid in overlapping rows |
| hide | `plate_slab` | pad, pore | the hide layer the sheet kit lays over the whole hull: irregular callus pads with sense pores (never a panel) |
| hull detail | `welt`, `pore`, `scar`, `blob`, `tube` | ridge, fold, vein, pore, scar (patch, knit), wound (channel, lip, tissue) | laid on the hull by the ship file: fold rolls, wrinkles, veins carrying bile, pore fields (the senses: the Chorus has no eyes), scars knitting shut (regrowth) |

Machines (R226: they ride whole with one piece, never across a seam): `MACHINES = ('gun', 'spinal', 'engine', 'thruster')`.
Sacs, blades, scutes and the hide are structure and tear.

Insides (R209): the sheet kit's `organ_room` (a lumpy organ, never a box that reaches the skin), `hoop` (a bone frame hoop
following the hull) and `septum` (a membrane shelf, the Chorus deck), in tools/blender/build_sheets/kit.py.

Every grown part is smooth shaded (`SMOOTH = True`).

## Squadron craft (issue 793: chorus_CS1BA2, the spore swarm)

A craft is about a seventeenth of the Ninefold Maw's length, so its parts take every size from their arguments. Ryan (R259): the
closed hull, nothing open, no exposed fluid, amber as a matte translucent colour only, never a glow.

| Part | data.js | What it is |
|---|---|---|
| `rocket_rack` (the acid sac, type `acid_sac`) | `sporeb` T, Acid sacs, 2 shots | a sealed gill bladder lying along the upper flank: a long swell of the flank (its outward axis the flank's own normal), raised gill bands across it, a muted matte amber blush in the valleys between them (the `amber` zone in this kit's `MATS`, merged by the ship file), a closed puckered sphincter at its front that squeezes the burst out; fixed (K.launcher asks every kit for `rocket_rack`), a machine |
| `craft_vent` (`engine_bell(..., craft=True)`) | | one orifice of the muscle-ringed orifice cluster: a muscle cone into the hull, radial folds, a sphincter ring, an inner membrane iris, a dark throat, bile glow deep inside |

`MACHINES` now carries `launcher` (an acid sac rides whole with one piece, R226); the C10 and C11 hulls carry no launcher, so they
build as before.
