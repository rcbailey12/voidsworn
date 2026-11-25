# GP1 Prism feature table

Revision r1. Generated from the same Blender model as the pictures. Counts outrank pictures.

## Feature table

| ID | Fitting | Count | Weapon arc | Route |
|---|---|---:|---|---|
| L1 | grown lens point at the port bow / pulsar | 1 | pulsar F | hand-built |
| E1 | grown stern drive optic, white bloom | 1 | engine aft | hand-built |
| L2 | grown lens point at the stbd bow / pulsar | 1 | pulsar F | hand-built |
| E2 | grown stern drive optic, white bloom | 1 | engine aft | hand-built |
| O1 | violet grown optic / turret | 1 | turret T | hand-built |

## Size

Cruiser LENGTH 14.5; drawn 23.2 with SHIP_K 1.6. Measured mesh length / beam / height: 14.463 / 6.133 / 2.774.

## Major masses

| Mass | Route |
|---|---|
| Port pane hull | hand-built |
| Stbd pane hull | hand-built |
| Arched bridge aft | hand-built |
| Arched bridge fwd | hand-built |

## INSIDE

Each hull: two shaped glass decks, open annealed frames and three braided light cores, cut at both break lines.
3 breach anchors (class base minus the Glasswright one), one core, two RCS and two boarding origins.

| Break line | Station % | What it opens |
|---|---|---|
| B1 | 80.000 | ragged shatter path through both hulls aft of the aft bridge; the stern optics stay whole |
| B2 | 22.069 | ragged shatter path through both hulls forward of the forward bridge; the bow lances stay whole |

Whole parts are listed separately in manifest.json whole_optics.
break_pieces names the hull compartments made by these paths, each with its share of the full interior.

## Changed from the picture

- Opaque panes and pearl instead of the sketch's clear glass. R337 (Ryan, Nov 19): nothing see-through.
- Two arched bridges, the turret blister on the crown of the forward one. The sketch's curved bridges; a blister on the bridge crown clears both hulls through a full turn (turret T, 360).
- Stored light on the hulls' inner flanks and under the bridges, not a pool in open space. The cleft is open space between two hulls; the glow sits on the glass that faces it.
- Each bow lens point is a short drawn-glass lance with a glowing tip on the hull's axis. cruiser.md: keep them points, never tubes; one pulsar per hull.
