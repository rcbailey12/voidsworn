# Eclipse part kit (`deathless`)

`parts.py` holds every Eclipse part shape the build sheets and the build use (RULEBOOK 4.5: every faction its own kit; only
the invisible geometry plumbing in `tools/blender/kits/shared/geom.py` is shared). The faction sheet is
docs/playbooks/factions.md (Eclipse); the lore is contrib/opus/compute/lore_bible_r8.md section 7.

## Weapons (R221, RULEBOOK 4.11, ships.md 2c)

Ryan, Nov 12 2026: "their turrets look the same as hullbreakers. We should have those be more unique per factions and fit the
actual weapons they use per lore Bible and faction rules." So each Eclipse weapon is designed from what it is: the data.js
weapon entry (W and FAC_WNAMES.deathless), its battle effect (godot/fx/fx_weapons.gd), the lore bible (7.5: "Null weapons
ignore half of armour; the Corona arc lands one heavy blow every other turn"; 7.8: the crest, an eclipsed sun) and the
faction sheet ("guns sit behind the shade's rim, firing through gaps between plates"). No Eclipse weapon is a
breech-and-barrel cannon: no round barrel, no breech block, no muzzle brake, no bore. Every turret stands behind its own small
shade (curved plates, the corona line on the rim) and fires through the gap in it.

Second pass (Ryan, Nov 12 07:41: "The eclipse weapons look super blocky in comparison to the rest of the ship"; RULEBOOK 5.16,
one detail level): every weapon is built in the hull's own language, curved, layered and banded like the crescent, the oval
body and its collars: thin bevelled crescent plates with seams and plate courses, round rails and needles with banded collars,
oval shells and round feet, no boxes, square frames or hex drums. Judged at the beauty camera beside the hull. One design line per weapon (the same text
is `WEAPONS` in parts.py, which the sheet's weapon row prints):

| data.js id | Name | What it fires and how | So its mount, housing and muzzle look like |
|---|---|---|---|
| `gauss` | Null cannon | 3 shots, 6 damage, range 5, ignores half of armour; the effect: capacitor coils light breech to muzzle in steps, a near invisible slug, a hard white flash and a pale shock ring, a punch-through | A magnetic rail gun, not a barrel: each gun is a pair of slim round rails (the slug rides between them) banded with round accelerator collars that step down toward the muzzle (the coils the effect lights in steps), reaching well past the shade and ending in a thin shock ring, no bore. They fire through the slot of a thin crescent shade in the hull's language: an arch of three bevelled plates with narrow seams, a second layer stepped in on its face, plate courses at the hull's scale, horns swept back and down, a corona line on the crest. Low layered crescent capacitor fins sit behind it on a small oval shell. Twin: two rail pairs. |
| `flak` | Null shredder | 3 shots, 3 damage, range 2, point defence; the effect: instant thin streaks to a spread of airbursts | A fan of five thin round needle rails, each with two banded collars, splayed side to side so the slugs spread into a screen, out of the slot of a small layered crescent shade on a low oval shell; two crescent capacitor fins behind; it elevates high (to 60) for craft. |
| `gsentry` | Null spire | 2 shots, 4 damage, range 3, point defence; the effect: instant thin streaks | A sentry post, not a gun box: a tall slim round spire with banded collars and green sight slits down its face, turning; at its head a small oval pod with two thin round needle rails through a layered crescent fin; it stands high to see craft over the hull. |
| `doom` | Corona arc | a lance: 1 shot, 40 damage, range 5, every other turn; the effect: little arcs crawl on the emitter, then a re-striking arc of lightning | An arc emitter, not a barrel: the shaft is a capacitor column (stacked disc banks between its segments, feed conduits along it) that stores the charge for one blow every other turn; the mouth is the faction crest, a black shade disc in a thin corona ring with a small lens, under a crown of six electrode horns curving forward round it where the arcs crawl before the strike. |

Sub-parts the inventory checks per weapon type (`SUBPARTS`): `nullcannon`, `shredder`, `spire`, `corona_arc`. Every turret is
turret-ready (R219): an empty `<id>_turret` at the ring centre with turret, slot, weapon, arc_lo, arc_hi, arc_deg, rest_yaw
and rest_pitch, the turning meshes its children; the hex foot stays on the hull. At rest every gun points forward (R222).

## Other parts

Eclipse engines (faceted ribbed drums, vanes, a short bell, a pale corona ring round a black shade disc, no flame), the caged
core, truss struts, the hex core port, octagonal hatches, shade-generator housings, heat slot panels, corona strip lights, slot
thrusters, machine-cut plates with flush fasteners. Each part's docstring in parts.py says what it is.

**Detail by size (issue 618, R224).** `panels()` lays plate courses on a part's flat faces at the hull's own plate size in world
units (`PANEL`), so a part built large keeps the hull's detail density: the engine housings, the corona arc's breech collars,
column and head carry them, and every engine bell gets stiffener rings by its length. The corona arc's hard point is its lens
(the horns' meeting point ahead of it is open space, off the mesh).

## Paint stack (issue 642)

`stack.py` is the Eclipse paint stack for sheet ships (`"bake": "stack"`), on the shared machinery in
`tools/blender/kits/shared/paint_stack.py`: the colours as tones to show under the game's battle lift (2.2, read from
`godot/render/look.gd`), the layers, the patchwork families, the flush-fastener and machining-scratch trim sheet, the decals
(eclipse sigil, archive glyphs, band ticks), the green-white corona and core, the engine ring (`ENGINE_GLOW`,
`engine_glow_nodes`), the dark violet-black liner, and no added running lamps. The design lines and their reasons are in the
file and in docs/playbooks/ships.md section 0 item 2 ("The Eclipse paint").
