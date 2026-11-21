# GA1 Aperture feature table

Revision r1. Generated from the same Blender model as the pictures. Counts outrank pictures.

## Feature table

| ID | Fitting | Count | Weapon arc | Route |
|---|---|---:|---|---|
| L1 | drawn-glass bow lance on the centreline / pulsar | 1 | pulsar F | hand-built |
| O1 | violet grown optic / turret | 1 | turret T | hand-built |
| H1 | hangar lens grown into the port flank, Starlings parked on stored light | 1 | bay flank | hand-built |
| H2 | hangar lens grown into the starboard flank, Starlings parked on stored light | 1 | bay flank | hand-built |
| E1 | grown stern drive optic, white bloom | 1 | engine aft | hand-built |

## Size

Carrier LENGTH 16.5; drawn 26.4 with SHIP_K 1.6. Measured mesh length / beam / height: 16.953 / 5.653 / 4.090.

## Major masses

| Mass | Route |
|---|---|
| Mosaic leaf core | hand-built |

## INSIDE

Two shaped glass decks, open annealed frames and three braided light cores, cut at all three break lines.
5 breach anchors (class base minus the Glasswright one), one core, two RCS and two boarding origins.

| Break line | Station % | What it opens |
|---|---|---|
| B1 | 83.030 | ragged shatter path forward of the stern optic; the drive stays whole |
| B2 | 75.152 | ragged shatter path aft of the hangar lenses, forward of the turret blister |
| B3 | 31.515 | ragged shatter path forward of the hangar lenses; the bow lance stays whole |

Whole parts are listed separately in manifest.json whole_optics.
break_pieces names the hull compartments made by these paths, each with its share of the full interior.

## Changed from the picture

- Opaque pearl ribbons over a glowing mosaic core instead of the sketch's clear glass. R337 (Ryan, Nov 19): the Glasswright finish is opaque reflective pearl with glowing stained-glass panels; nothing see-through.
- Each hangar lens is a shallow well in the mosaic skin with a pearl lip and a stored-light floor, three Starlings parked on it. carrier.md: lenses grown into the skin, not cut openings or pods; Starlings visible; opaque, so the floor is light, not a window.
- The sketch's extra stern and flank lens rings are left out; one large stern optic carries the bloom. Weapon match (R241): only data.js weapons show as lenses (one pulsar F, one turret T); the rings read as more guns.
- Ribbons slide above and below each hangar lens. So the lens stays clear and reads as grown into the skin.
