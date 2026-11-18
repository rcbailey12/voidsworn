# Nebula and storm motion specification (#230, NB8 and NB11; updated #368 run 6, Nov 17 2026)

One spec for how the on-board gas moves: the nebula and ion storm on the living path (looks B and C), their storm
activity, the old clouds path (looks today and holo), the far gas wisps, the gravity well and the debris dust. It
settles NB8 of the Nov 6 environment audit (the layer multipliers sat on a base drift rate that was never numbered)
and NB11 (the storm flash radius was given in units beside neighbours given in hexes). Builders of #368 (nebula
and storm volumes) and #100 (terrain fx 2) read this file; the terrain fx synthesis (contrib/muse/research/terrain_fx_2026_11/
synthesis.md sections 2.1 and 2.3) stays as the history of why.

Every number below is read from the code named beside it, unless marked otherwise.
R300's current lightning pictures and strike strips are in `docs/shots/look_bench/nebula/RUN6.md`,
pending Ryan's approval. The calm nebula stays at Run 4. Section 7 records the earlier #230 capture route.
Provenance labels follow the audit: SHIPPED (in code), DERIVED (arithmetic on shipped
values), SPEC (written in the synthesis, not built).

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
| Pattern direction | mostly along -x, a little down (-y) and toward -z; the positive noise offset moves fixed noise features in the opposite world direction | DERIVED |

The whole body pattern and its warp field (`w`, sampled at 0.55 of the frequency) translate together at the layer
rate: the interior slides as one, while the footprint mask stays fixed in world space (synthesis 2.1, "the mask stays
fixed; only the interior moves"). The edge still moves: the mask is read through the moving warp (`foot_at(vW.xz +
wv)`), so the boundary wobbles as the pattern passes it. Churn inside the body comes from the breathing (section 3)
and the layered world-space field. R289 removes the finer electrical-looking filament layer from nebula gas.

## 2. Each layer's rate

The calm nebula uses `GAS_SHADER` in `world_living.gd`. The windows below are before
route A's 1.75 height scale; the patch footprint stays fixed. Max also has the
accepted 38.5-unit-tall volume. Its drift is unchanged by R289.

| Layer (band) | Height window (y) | Multiplier | Body drift | Provenance |
|---|---|---|---|---|
| Ground haze (0) | -4 to 2 | 0.6 | 0.116 u/s (0.0067 hex/s) | SHIPPED, DERIVED |
| Main body (1) | 1 to 8 | 1.0 | 0.193 u/s (0.011 hex/s) | SHIPPED, DERIVED |
| Wisps (2) | 6 to 14 | 1.6 | 0.308 u/s (0.018 hex/s) | SHIPPED, DERIVED |
| Tying veil (3) | 12 to 18 | 0.4 | 0.077 u/s (0.0045 hex/s) | SHIPPED, DERIVED |

- Nebula has no fine filament field or electrical contour lines. Broad soft
  radiance uses the body density, so it moves with the calm gas.
- Storms use `CARDS` and `FOG` in `godot/world/ion_storm.gd`, selected explicitly
  by the world builder. R282 moved storms out of the shared nebula shader;
  R289 keeps that charged cloud and makes it steel-blue/cyan, darker between
  strikes, with three times Run 3's drift.
- Storm card noise is scaled by `(0.055, 0.075, 0.055)` per world unit and drifts
  by `(0.027, 0.009, 0.015)` per second. Dividing each component gives a body
  speed of **0.574 u/s** (0.033 hex/s). Layer multipliers are 0.6, 1.0, 1.6 and
  -0.4: ground 0.344, body 0.574, wisps 0.918 and veil 0.230 u/s backward.
- Storm volume noise is scaled by `(0.016, 0.022, 0.016)` and drifts by
  `(0.0021, 0.00075, 0.0012)` per second: **0.155 u/s** (0.0089 hex/s).
  The calm volume remains at 0.060 u/s. Both storm paths move faster than
  their nebula counterpart; cards and volume have different noise scales.
- Capture variant: `VS_GAS_FLAT=1` flattens nebula cards only. It does not
  override the separate storm module. Shipped play never sets it.

## 3. Breathing and pulses

| Motion | Value | Provenance |
|---|---|---|
| Nebula body breathing (band 1 only) | density threshold moves by plus or minus 0.025, period 8.0 s (`sin(gas_time * 0.785398 + phase)`) | SHIPPED |
| Breathing phase spread | 0 to 0.9 rad between puffs | SHIPPED |
| Whole-patch alpha pulse | none | SHIPPED |
| Storm card charge | broad cloud lobes modulated by 0.35 plus or minus 0.04, period 2.244 s; no persistent electrical filaments | SHIPPED, DERIVED from `sin(gas_time * 2.8 + cloud.y * 6.28)` |
| Storm volume charge | advected cloud density and actual lightning/tick flashes, no idle sine pulse | SHIPPED |

## 4. Storm activity between and during bolts (NB11, in hexes)

R289 replaces the old shared-shader 1.7 multiplier, fine veins, 2-second vein
pulse, Gaussian denominator 500 and 8-to-12-unit spot response. The live storm
module supplies broad charge; only the intermittent bolt meshes draw branches.

| Element | Value | Provenance |
|---|---|---|
| Electric filaments | absent in both gas shaders; only storm has bolt meshes | SHIPPED, R289 |
| Glow around a bolt | `exp(-d^2 / 240)` in cards and volume; 1/e at 0.89 hex (15.5 u), one tenth at 1.36 hex (23.5 u) | SHIPPED, DERIVED |
| Shader response | card flash colour times field and 1.2; volume flash colour times field and 2.5; both use the same Gaussian | SHIPPED, R300 |
| Flashes the gas can see at once | 8 (`flashes[8]`) in each storm shader, none in calm gas | SHIPPED |
| Bolt count | 2 to 4 channels per storm patch, each with 2 to 4 tapered branches | SHIPPED, run 6 |
| Bolt cadence | a patch burst waits 2.2 to 6.5 s; its strikes start 0.075 s apart | SHIPPED, run 6 |
| Bolt envelope | one 0.018 s rise and a cooling tail to 0.52 s; no second peak. Refused or reduced flashes ease up over 0.20 s and fade by 0.9 s at a 0.22 peak | SHIPPED |
| Bolt radiance | HDR near-white cores with separately colored cyan/violet skirts, through the existing battle glow; no scene-wide bloom change | SHIPPED, R300 |
| Bolt comfort | each strike books a conservative 48-unit lit disc through the battle's area counter; Reduce flashing also softens strikes already active | SHIPPED |
| Bolt light | energy up to 1.2 on hulls; first two lights scatter into Max fog at weight 1.4 | SHIPPED, R300 |
| Shield-tick flare | real positioned tick adds 0.12 to card flash or 0.10 to volume flash; fades linearly over 0.45 s (`tick` decays by dt / 0.45) | SHIPPED |

Run 6 lightning uses 2 to 4 channels per storm patch and 2 to 4 direct branches per channel.
Branch tubes and skirts taper to six percent at the tip. Their pulse runs 1.6 times faster than
its trunk, so they vanish sooner. Cyan inner skirts and violet outer skirts retain color before
the existing weapon bloom. These are tuning values judged on the run 6 strips.

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

- The calm card base drift is 0.193 world units a second. Each gas path states its noise scale and derived world speed.
- Distances on the board are stated in hexes (17.32 units each) with units in brackets.
- A change to any value in sections 1 to 4 changes this file and `contrib/opus/tools/env_reconcile_tests.js` in the
  same PR; the test fails when the shader and this file disagree (the audit's "silent disagreement" pattern).
- The #368 R289 captures and motion studies are in `docs/shots/look_bench/nebula/RUN4.md`. Ryan approval is pending.
  No older numerical look target overrides that ruling; the storm module is the active source for storm motion.

## 7. The earlier #230 motion capture

This is the pre-R282/R289 capture route. Current calm/storm evidence uses the
same-board Run 4 harness linked above; the flat-rate variant now affects nebula
cards only.

`godot/world/world_shots.gd --motion` holds the camera still on the nearest nebula, ion storm and debris hex and on a
low view of the rock fields, and writes a contact sheet (a frame every 5 s for 30 s) and a first-to-last difference
image per view. Variants come from environment switches; the shipped run sets none. The exact runs are in
`tools/pc/jobs/env230_motion.bat` and the #230 PR body. For NB8 the sheet compares shipped against `VS_GAS_FLAT=1`
on the storm and nebula maps; the question for Ryan's look is whether the layered rates read as depth or as noise.

Refs #520: PC capture results and the named option sheets are in `contrib/opus/reviews/env230_report.md` and
`docs/shots/env230/`. The job runs the merged checkout, checks camera stability and 1920x1080 frames, stops on
placeholder ships, and labels and sizes the final images to at most 720 px tall.
