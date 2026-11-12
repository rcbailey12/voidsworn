# Nebula and storm motion specification (#230, NB8 and NB11; Opus, Nov 9 2026)

One spec for how the on-board gas moves: the nebula and ion storm on the living path (looks B and C), their storm
activity, the old clouds path (looks today and holo), the far gas wisps, the gravity well and the debris dust. It
settles NB8 of the Nov 6 environment audit (the layer multipliers sat on a base drift rate that was never numbered)
and NB11 (the storm flash radius was given in units beside neighbours given in hexes). Builders of #139 (nebula
volumes) and #100 (terrain fx 2) read this file; the terrain fx synthesis (contrib/muse/research/terrain_fx_2026_11/
synthesis.md sections 2.1 and 2.3) stays as the history of why.

Every number below is the shipped value on main, read from the code named beside it, unless marked otherwise. None of
them has been judged in motion against an alternative yet: the #230 motion capture (section 7) is the first look, and
NB8's flattened-rate variant is part of it. Provenance labels follow the audit: SHIPPED (in code), DERIVED (arithmetic
on shipped values), SPEC (written in the synthesis, not built).

## 0. Units

- One hex is 17.32 world units from a hex centre to its neighbour's centre (hex corner radius HS 10, inner radius
  8.66, godot/render/board.gd). Distances on the board are given in hexes first, units in brackets.
- Rates are given per second of wall clock. The gas runs on its own clock (`gas_time`, world_living.gd `_process`),
  which only advances while the living terrain is visible; the other shaders run on Godot's `TIME`.
- The gas pattern is a world-space noise field sampled at 0.075 cycles per unit (`p = vW * 0.075 + drift`), so a
  noise offset of 1 is 13.33 world units.

## 1. The base drift rate (NB8: the number the multipliers multiply)

Source: `GAS_SHADER`, world_living.gd: `drift = vec3(0.012, 0.004, 0.007) * gas_time * rate`.

| Quantity | Value | Provenance |
|---|---|---|
| Base drift, noise space | (0.012, 0.004, 0.007) a second | SHIPPED |
| Base drift, world space | (0.160, 0.053, 0.093) units a second | DERIVED (divide by 0.075) |
| **Base drift rate** | **0.193 units a second, about 0.011 hex a second (one hex in about 90 s)** | DERIVED |
| Direction | mostly along +x, a little up (+y) and toward +z, the same on every map | SHIPPED |

The whole body pattern and its warp field (`w`, sampled at 0.55 of the frequency) translate together at the layer
rate: the interior slides as one, while the footprint mask stays fixed in world space (synthesis 2.1, "the mask stays
fixed; only the interior moves"). The edge still moves: the mask is read through the moving warp (`foot_at(vW.xz +
wv)`), so the boundary wobbles as the pattern passes it. Churn inside the body comes from the breathing (section 3)
and from the finer filament layer moving at a different speed (section 2).

## 2. Each layer's rate

The layer multipliers are synthesis 2.1's, now built (`rate` in `GAS_SHADER`). Heights are the shader's band windows
(`lo`, `hi`), which are the spec's four bands; the puff centres that feed them are NB1's three shipped bands (y -2.5
to 0.5, 2.5 to 6.5 and 8 to 12, plus the veil at 13.5 to 16.5) and are #139's to judge.

| Layer (band) | Height window (y) | Multiplier | Body drift | Filament drift | Provenance |
|---|---|---|---|---|---|
| Ground haze (0) | -4 to 2 | 0.6 | 0.116 u/s (0.0067 hex/s) | 0.196 u/s | SHIPPED, DERIVED |
| Main body (1) | 1 to 8 | 1.0 | 0.193 u/s (0.011 hex/s) | 0.327 u/s | SHIPPED, DERIVED |
| Wisps (2) | 6 to 14 | 1.6 | 0.308 u/s (0.018 hex/s) | 0.523 u/s | SHIPPED, DERIVED |
| Tying veil (3) | 12 to 18 | 0.4 | 0.077 u/s (0.0045 hex/s) | 0.131 u/s | SHIPPED, DERIVED |

- Filaments (veins and bright knots) are the same field at 3.6 times the frequency with an extra 2.5 times the drift
  (`fine`), which makes them move 1.69 times as fast as the body of their own layer (DERIVED: 6.1 x drift over 0.27
  cycles a unit, against drift over 0.075). This difference is the visible churn.
- Ion storm (`storm` 1): every layer runs 1.7 times faster, and the veil runs backward (-1.7 x 0.4 = -0.68), so the
  top twists against the body (synthesis 2.3: "storm churn is faster than nebula churn and its veil twists against
  the body drift"). Storm body drift 0.328 u/s (0.019 hex/s); storm wisps 0.524 u/s; storm veil 0.131 u/s the other
  way. SHIPPED, DERIVED.
- Capture variant (NB8's settle): `VS_GAS_FLAT=1` sets every layer to the base rate (multiplier 1.0, the storm's 1.7
  and the veil's reversal kept). On a storm map the flat assignment runs before the storm multiplier, so the veil runs
  at -1.7 x base (-0.328 u/s) the other way, not at its shipped storm speed of 0.131 u/s. Shipped play never sets it.

## 3. Breathing and pulses

| Motion | Value | Provenance |
|---|---|---|
| Body breathing (band 1 only) | the density threshold moves by plus or minus 0.025 (about 6 percent of its 0.27 to 0.70 ramp), period 8.0 s (`sin(gas_time * 0.785398 + phase)`) | SHIPPED |
| Breathing phase spread | 0 to 0.9 rad between puffs (`fract(w)` of a 0 to 0.9 roll): the patch breathes almost in step | SHIPPED; flagged for #139 (a full 0 to 6.28 spread would read as churn rather than one breath) |
| Whole-patch alpha pulse | none (synthesis 2.1: pulsing reads as a state change) | SHIPPED |
| Storm glow pulse | plus or minus 10 percent on cores and veins, period 2.0 s (`0.90 + 0.10 * sin(gas_time * 3.14159 + phase)`) | SHIPPED (spec 1.5 to 2.5 s) |

## 4. Storm activity between and during bolts (NB11, now in hexes)

| Element | Value | Provenance |
|---|---|---|
| Electric filaments | always on; the vein pattern moves 0.555 u/s in the storm body and 0.889 u/s in the storm wisps, so one 3.7-unit filament cell passes in about 4 to 7 s | SHIPPED, DERIVED (spec 3 to 6 s) |
| Sheet glow round a bolt | a Gaussian lift `exp(-d^2 / 500)` at weight 0.10: 1/e (about a third) at **1.3 hexes** (22.4 u), a tenth at **2.0 hexes** (33.9 u) | SHIPPED, DERIVED (spec 1 to 2 hexes) |
| Flash response round a bolt | the emissive boost of 0.3 is full within **0.46 hex** (8 u) and gone at **0.69 hex** (12 u) | SHIPPED; **NB11 denomination fixed**: the synthesis's "about 12 units" is 0.7 hex, under one hex, so the flash response is the bolt's own spot and the sheet glow (1.3 to 2 hexes) is what reaches the neighbours |
| Flashes the gas can see at once | 4 (`flashes[4]`) | SHIPPED |
| Bolt count | one per two storm hexes, at least 1 and at most 6 (`clampi(n / 2, 1, 6)`) | SHIPPED |
| Bolt cadence | each bolt waits 2.2 to 6.5 s between flashes | SHIPPED |
| Bolt envelope | 0.42 s (bright 0.05 s, dip, second peak, tail; `_flash`) | SHIPPED |
| Bolt light | energy up to 3.2 (`light_energy = v * 3.2`) | SHIPPED |
| Shield-tick flare | on each presented storm tick (a ship inside the storm, within 10 u of a storm hex centre), the veins gain an extra 1.5 x tick of energy (about double their resting glow) that fades linearly over 0.45 s (`tick` decays by dt / 0.45) | SHIPPED |

## 5. Other gas and on-board motion

| Motion | Value | Provenance |
|---|---|---|
| Old clouds (today and holo looks, `CLOUD_SHADER`, world.gd) | billboard-local noise offset (0.015, 0.008) a second; storm clouds flash at 0.11 to 0.18 cycles a second (one flash every 5.6 to 9.1 s), each lit for about 8 percent of its cycle | SHIPPED (the old path; synthesis 2.8) |
| Far gas wisps (`WISP_SHADER`, world.gd) | texture offset 0.0015 a second along u | SHIPPED |
| Gravity well (`WELL_SHADER`) | the lensing twist sways by 0.04 rad about a 0.06 rad set, period 37 s (`sin(TIME * 0.17)`); it does not rotate | SHIPPED (the synthesis's "one full rotation in about 30 s" is not what ships) |
| Gravity well ripples | run inward at 3.6 u/s (0.21 hex/s), one every 15 u (`sin(d * 0.42 + TIME * 1.5)`) | SHIPPED, DERIVED |
| Debris dust motes (living path) | still; additive motes that never move | SHIPPED (spec: drift at about 20 percent of the gas rate, about 0.039 u/s: #100 builds it) |
| Debris tumble | see contrib/opus/briefs/environment_reconciliation.md section 1 (AS14) | |

## 6. Rules for builders

- The base drift rate is 0.193 world units a second; any new gas layer states its rate as a multiple of it.
- Distances on the board are stated in hexes (17.32 units each) with units in brackets.
- A change to any value in sections 1 to 4 changes this file and `contrib/opus/tools/env_reconcile_tests.js` in the
  same PR; the test fails when the shader and this file disagree (the audit's "silent disagreement" pattern).
- The #139 volume rebuild keeps these rates unless its recordings show a better set; it then records the new set here.

## 7. The motion capture (judges sections 1 to 4 for the first time)

`godot/world/world_shots.gd --motion` holds the camera still on the nearest nebula, ion storm and debris hex and on a
low view of the rock fields, and writes a contact sheet (a frame every 5 s for 30 s) and a first-to-last difference
image per view. Variants come from environment switches; the shipped run sets none. The exact runs are in
`tools/pc/jobs/env230_motion.bat` and the #230 PR body. For NB8 the sheet compares shipped against `VS_GAS_FLAT=1`
on the storm and nebula maps; the question for Ryan's look is whether the layered rates read as depth or as noise.

Refs #520: PC capture results and the named option sheets are in `contrib/opus/reviews/env230_report.md` and
`docs/shots/env230/`. The job runs the merged checkout, checks camera stability and 1920x1080 frames, stops on
placeholder ships, and labels and sizes the final images to at most 720 px tall.
