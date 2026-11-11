# Design note: C15s_23, Hullbreaker cruiser (issue 209 round 1 subject)

**Subject.** `C15s_23`, the Ashfall Hullbreakers cruiser (corsair Cruiser in `SHIP_QUEUE.md`, priority 2, not started). It is the only cruiser-class Hullbreaker hull, it is not the flagship, and the Pyre-Barge (`C19_51`) is never a test subject. It is also next in the go-forward plan's build order ("Corsairs first: C13s, C14s, C15s, C16s"). Concept: `docs/ship_pipeline/concepts/C15s_23.webp`.

**Frame.** Same as the A4 ship files: x to the bow, y to port, z up, length 1.0 (stern at x = -0.5, bow at +0.5).

## What the concept says, and what changes (space, not naval)

| Concept feature | Built as | Why |
|---|---|---|
| Wide red armoured bow block with a rounded front | chisel-nosed bow block, flat belly, chines | AGENTS.md: no raked stem or boat bow |
| Twin forward guns with orange muzzles on a raised deck | raised glacis block, twin barrels on mounts, aimed straight ahead | guns forward, matched pair |
| Two octagonal casemates a side with ball mounts and twin barrels | four casemates, matched pairs, barrels aimed forward and out | never backward, never into the ship |
| Missile drums lying on the deck (pair, rack of three, aft pair) | drums with launch ends forward on cradle saddles | |
| Lattice mast on the tower | sensor array (squat tower, dishes, whips) | lattice masts are naval tells |
| Aft lattice mast with stays | radiator pair | crossbar masts become radiators (Oct 24 ruling) |
| Chin fin under the bow | ventral sensor blister | reads as a boat keel (A4 pass 3 cut it too) |
| Dark grey aft body, boxy, cargo blocks on one flank | taller boxy aft body; cargo containers on both flanks | matched pairs (Hullbreakers may be junky, but the pair rule is kept for a fair test) |
| Stern (not shown in the concept) | one big engine bell, two smaller ones, ventral thruster pods | space engines |
| Railings round the decks | left off | naval tell, sub-pixel at battle range |

## Station table (Arm A hull, measured off the TRELLIS.2 whole-hull mesh as massing underlay)

The B0 mesh was turned 19.8 degrees about z (the concept's 3/4 view lies that far off the axis), scaled to length 1.0 and sampled every 0.05 for deck height, chine height, belly height and half-width (percentiles, so masts and the chin fin do not count). Arm A's lofts follow those numbers, squared off where the AI surface wobbles. Columns: x, deck half-width, deck z, flank half-width, chine z, belly half-width, belly z.

| x | deck w | deck z | flank w | chine z | belly w | belly z |
|---:|---:|---:|---:|---:|---:|---:|
| +0.500 | .030 | .020 | .040 | -.030 | .025 | -.070 |
| +0.470 | .072 | .036 | .090 | -.022 | .062 | -.092 |
| +0.420 | .105 | .044 | .126 | -.020 | .092 | -.106 |
| +0.330 | .125 | .052 | .148 | -.020 | .110 | -.115 |
| +0.200 | .135 | .056 | .156 | -.020 | .118 | -.120 |
| +0.100 | .138 | .058 | .156 | -.020 | .118 | -.120 |
| +0.040 | .138 | .066 | .154 | -.020 | .116 | -.122 |
| 0.000 | .136 | .074 | .150 | -.020 | .114 | -.122 |
| -0.120 | .128 | .078 | .142 | -.020 | .108 | -.120 |
| -0.220 | .122 | .078 | .136 | -.018 | .102 | -.116 |
| -0.340 | .116 | .076 | .130 | -.015 | .098 | -.110 |
| -0.460 | .110 | .072 | .124 | -.012 | .094 | -.104 |
| -0.500 | .104 | .066 | .118 | -.012 | .090 | -.098 |

## Hard points (shared by every cell)

| Part | Where (x, y, z) | Size (x, y, z) | Arm A | B1, B2 | B3 |
|---|---|---|---|---|---|
| Glacis and twin bow guns | .30, 0, deck | .19 x .16 x .036; barrels .075 | hand | AI bow-gun part | AI bow-gun part |
| Casemates, 4 | x .300 and .175, both flanks, z 0 | .084 x .05 x .08 | hand | AI part, mirrored for starboard | AI part |
| Command tower and bridge | .02, 0, deck | r .046, h .072 | hand | hand | hand |
| Sensor array | on the bridge | h .085 | hand | hand | hand |
| Drum pair, fore | .145, 0, deck | .07 x .14 x .04 | hand | AI drum rack | AI drum rack |
| Drum rack, mid | -.085, 0, deck | .095 x .165 x .046 | hand | AI drum rack | AI drum rack |
| Drum pair, aft | -.300, 0, deck | .064 x .12 x .036 | hand | AI drum rack | AI drum rack |
| Radiator pair | -.42, 0, deck | .07 long | hand | hand | hand |
| Cargo containers, 2 | -.115, both flanks, z -.06 | .17 x .06 x .066 | hand | AI part, mirrored | AI part |
| Stern engines | -.50, 0, -.02 | bells r .046 and .028 | hand | AI stern block | AI stern block |
| Ventral sensor blister | .30, 0, belly | .11 x .06 x .022 | hand | none | none |

Thin parts (sensor array, radiators) are hand-built in every cell, because generators drop thin parts (#214 note). B0 is the raw whole generation with nothing added: the control.

## Breakable by design (R98, R99), identical in every cell

- Hull thickness: every outer shell gets a 0.005 inner skin (Solidify, inward).
- Break lines: two transverse at x = +0.10 and x = -0.22, one lengthwise at z = -0.02 between them (the mid piece splits into an upper and a lower half). R99: two transverse plus one lengthwise.
- At each transverse line: a rim band (red trim) and a bulkhead on each side with frame ribs, shaped to the hull's own section found by 48 rays. Along the lengthwise line: a rim band on both flanks.
- Two internal decks (z -0.065 and +0.005) in each segment, edges following the hull.
- Parts must not cross a break line (the audit lists any that do).
- Not in round 1: authored damage textures and per-piece flesh or interiors beyond decks and bulkheads.

## Materials

The current best Hullbreaker paint, `tools/blender/hull_repair/round6_material.py` (PR #196, round 6): three coat values on geometric masses, local AO in recesses, thin bevel edge rust, red only on trim, engine glow. Bands are set by geometry the same way for every cell: undersides and the lowest hull darkest, the forward hull one coat, the aft hull the lighter grey coat, parts take the band of the hull face they sit on, rim bands and casemate plates red trim. Round 6 came out nearly black in the game (R108); the studio exposure here is fixed and the same for every cell, and a clay pass sits beside every paint pass so the construction can be judged on its own.

## Build order (Arm A)

1. Hull lofts per break segment (bow, mid, aft), bevel, simple subdivision.
2. Hard-point parts (table above), each recorded for the audit; gun directions recorded.
3. Modest detail: about 16 big plates a flank, 18 on top, 10 on the belly, 16 small fittings (vents, hatches). Fewer, bigger plates on purpose (round 5's busy plating read as clutter).
4. Audit: gaps and floating parts, parts crossing break lines, guns aimed backward.
5. Break structure (above), paint, cost report.
