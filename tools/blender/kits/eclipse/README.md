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
shade (curved plates, the corona line on the rim) and fires through the gap in it. One design line per weapon (the same text
is `WEAPONS` in parts.py, which the sheet's weapon row prints):

| data.js id | Name | What it fires and how | So its mount, housing and muzzle look like |
|---|---|---|---|
| `gauss` | Null cannon | 3 shots, 6 damage, range 5, ignores half of armour; the effect: capacitor coils light breech to muzzle in steps, a near invisible slug, a hard white flash and a pale shock ring, a punch-through | A magnetic rail gun: each gun is a pair of flat rails (the slug rides between them) held in square accelerator frames that step down toward the muzzle (the coils the effect lights in steps), ending in an open fork and a flat shock plate, no bore. The rails fire through the slot between two curved shade plates (a crescent with swept horns, the flagship's crescent in miniature, a corona line on its rim); a ribbed capacitor stack behind stores the charge. Twin: two rail pairs. |
| `flak` | Null shredder | 3 shots, 3 damage, range 2, point defence; the effect: instant thin streaks to a spread of airbursts | A fan of five short needle rails splayed side to side so the slugs spread into a screen, out of the slot in a crescent shade on a squat hexagonal drum; a two-fin capacitor pack behind; it elevates high (to 60) for craft. |
| `gsentry` | Null spire | 2 shots, 4 damage, range 3, point defence; the effect: instant thin streaks | A sentry post, not a gun box: a tall tapered hexagonal spire that turns, its head carrying two short needle rails through a small vertical shade fin, green sight slits down its face (the concept's green sights); it stands high to see craft over the hull. |
| `doom` | Corona arc | a lance: 1 shot, 40 damage, range 5, every other turn; the effect: little arcs crawl on the emitter, then a re-striking arc of lightning | An arc emitter, not a barrel: the shaft is a capacitor column (stacked disc banks between its segments, feed conduits along it) that stores the charge for one blow every other turn; the mouth is the faction crest, a black shade disc in a thin corona ring with a small lens, under a crown of six electrode horns curving forward round it where the arcs crawl before the strike. |

Sub-parts the inventory checks per weapon type (`SUBPARTS`): `nullcannon`, `shredder`, `spire`, `corona_arc`. Every turret is
turret-ready (R219): an empty `<id>_turret` at the ring centre with turret, slot, weapon, arc_lo, arc_hi, arc_deg, rest_yaw
and rest_pitch, the turning meshes its children; the hex foot stays on the hull. At rest every gun points forward (R222).

## Other parts

Eclipse engines (faceted ribbed drums, vanes, a short bell, a pale corona ring round a black shade disc, no flame), the caged
core, truss struts, the hex core port, octagonal hatches, shade-generator housings, heat slot panels, corona strip lights, slot
thrusters, machine-cut plates with flush fasteners. Each part's docstring in parts.py says what it is.
