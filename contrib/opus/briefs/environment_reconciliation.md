# Environment reconciliation record (#230; Opus, Nov 9 2026)

Settlement E-F (1) of the Nov 6 environment audit (contrib/muse/reviews/env_audit_2026_11/synthesis.md section 6;
FINDINGS R124). The audit's finding was "silent disagreement between settled documents": two adopted texts giving
different numbers for the same thing, with code obeying one and no document noticing. This file is the document of
record for the items below; where it and an older synthesis disagree, this file wins until a later FINDINGS row says
otherwise. Item definitions are in the audit's PACK.md. The gas motion half (NB8, NB11) is
contrib/opus/briefs/nebula_motion_spec.md.

Every code value was read on main at a52aaf4 (Nov 8). Provenance: SHIPPED (in code), DERIVED (arithmetic on shipped
values), SPEC (written, not built).

## 1. AS14 and AS10: debris tumble, one figure of record

**Figure of record (provisional): a piece of debris turns at most 0.10 / max(1, scale) radians a second**
(`TUMBLE_K` and `tumble_rate`, godot/world/world_living.gd). Scale 1 is a 2-unit rock or a wreck piece of radius 1.
It binds when the motion capture in section 8 has sheeted it against the terrain synthesis periods and Ryan has
looked at the sheet. The terrain synthesis 2.4 periods (small rocks 20 to 40 s a turn, large rocks 60 to 90 s, wreck
pieces 80 to 120 s) are the alternative, built as the capture variant `VS_TUMBLE=periods`.

What the code actually turns today (found by this pass; the audit read the stored rates, not the shaders):

| What | Turns? | Rate shipped | Period | Provenance |
|---|---|---|---|---|
| Wreck kit pieces on debris hexes (living path) | yes, in WRECK_SHADER | exactly the cap: 0.10 / scale (scale 1.3 to 2.6), hero piece 0.10 / scale (scale 2.6 to 3.8) | 82 to 163 s; hero 163 to 239 s | SHIPPED, DERIVED |
| Painted hull chunks (issue 49, one per debris hex) | yes, on the CPU | the cap at the slot's scale | as their wreck slot | SHIPPED |
| Debris rocks, both paths | **no** | a rate is stored (raw 0.05 to 0.35, held under the cap) but ROCK_SHADER ignores time | held | SHIPPED (world_rocks.gd: "Keep the seeded starting pose, without time-driven tumble") |
| Blockers, edge, deep, belt, mountain and crystal fields (AS10) | **no** | AS10's ranges are stored and never shown | held | SHIPPED |

So the 2 to 3 times disagreement AS14 found is real on paper and almost moot on screen: it is largest for small
rocks, and no rock turns. For wreck pieces the two documents nearly agree (shipped 82 to 163 s against the periods'
80 to 120 s). AS10's "inconsistent spin laws" are also invisible today for the same reason. The open question is
therefore not only which rate but whether rocks should turn at all (section 9). The capture variant
`VS_ROCK_TUMBLE=1` turns every rock at its stored rate, so the sheet can show rocks held against rocks turning.
Why rock tumble was taken out is not in the repo record this thread can read (shallow history); the shader comment
says it was on purpose.

Code changes in this pass (defaults are byte-for-byte the shipped behaviour): `TUMBLE_K` named once and used by the
CPU and the wreck shader (`tumble_k` uniform); `rock_tumble` and `wreck_tumble` hold the two laws; the rock and crystal
shaders gained a `tumble_k` uniform that is 0 (held) unless the capture sets `VS_ROCK_TUMBLE=1`.

## 2. AS16: debris size structure, spec against code, value by value

Spec: terrain fx synthesis 2.4. Code: `_debris` (living path, looks B and C, the default cine look) and
`debris_field` (plain path, looks today and holo), world_living.gd and world.gd. Library rocks are 2.0 units long at
scale 1 (rocks.json `ext`); the wreck kit pieces have radius 1.0 (wreckage/kit.json) and long axes 1.30 to 1.88.

| Value | Spec (2.4) | Code (living path unless said) | Status of record |
|---|---|---|---|
| Counts per hex | 15 to 22 rocks plus 3 to 5 wreck pieces | 15 to 22 rocks (8 to 12 low), 3 to 5 wreck pieces plus one more at 55 percent; plain path 8 to 13 rocks | SHIPPED, agree. (AS13 read the 55 percent as an extra hero piece; it is an extra ordinary piece. The first piece of every hex is the hero.) |
| Large rocks | at least 20 percent of rocks per hex at 3 to 5 units | rock length 0.6 to 5.6 (scale 0.3 + 2.5 u^2.4): 21 percent of rocks at 3 to 5 units and 26 percent at 3 or more, on average; 54 percent of hexes meet the 20 percent floor at 3 to 5 units, 74 percent at 3 or more. Plain path 0.7 to 3.9, 14 percent at 3 or more | SHIPPED as an average, not a per-hex floor. Record: "about a fifth of rocks 3 to 5 units long, on average". A per-hex floor is #100's to add if its sheets want it |
| Clearly larger wreck piece | at least one per 3 hexes, 6 to 9 units | one hero piece in every hex, scale 2.6 to 3.8, long axis 4.0 to 7.2 units (never over 7.6) | SHIPPED, record amended: one hero piece per hex, 4 to 7.6 units. The spec's top (9) crosses the AS18 cap (8.66), so 6 to 9 is retired; #100 may grow the hero to at most 8.66 |
| Sub-clumps | 2 to 3 per hex with clear gaps | none: an even scatter over a disc of radius 8.6 (rocks) and 7.0 (wrecks) | SPEC, not built. #100 builds it |
| Ship clear zone | radius 4 units round each ship hex centre | none: rocks reach the hex centre, and ships can stand in debris hexes | SPEC, not built. #100 builds it |
| Height | most pieces below the ship midline; one hero may rise higher | rocks y -3.5 to 4.0, wrecks -2.5 to 3.0 about the hex centre | SHIPPED; the midline comparison is #100's sheet item |
| Dust haze | tan #d4bf86 at low saturation, alpha 0.06 to 0.10, darker low, thinner high, never grey | 48 additive motes per hex (none at low), colour linear (0.62, 0.57, 0.50) (about sRGB #cec7bb, a pale grey tan), brightness 0.3 to 0.9, size 0.08 to 0.25, even in height | SPEC, not built: the shipped dust is additive (no alpha) and near grey. #100 builds the spec's dust |
| Dust drift | about 20 percent of the gas rate | still | SPEC, not built (about 0.039 u/s; nebula_motion_spec.md section 5) |
| Specular glint, hot edges (2 to 3 emissive points a piece) | in 2.4 | wreck metal 0.6, roughness 0.48 and up; 22 percent of pieces use the hot material, emissive by vertex alpha, not counted | look items, judged on #100's sheets; no number to reconcile |
| Tumble | periods by size | see section 1 | section 1 |
| Largest piece | see AS18 | rocks 5.6, wrecks 7.6, plain path 3.9, painted hull chunks 5.2 | SHIPPED, under the cap |

After this table the spec and the code agree in the only sense that matters for #100: every value is either shipped
and recorded here, or marked as #100's to build. #100's brief should cite this table rather than synthesis 2.4.

## 3. AS18: the governing document for the largest debris piece

**Governing document: this file.** Rule (from the backdrops synthesis section 2, R79's adopted text): no debris
piece longer than 8.66 units, the hex inner radius, half the 17.32 flat width. Shipped maximum 7.6 (the hero wreck
at scale 3.8). AS16's "6 to 9 units" is amended to "up to 8.66" (section 2). `contrib/opus/tools/env_reconcile_tests.js`
checks the code's scale ranges against 8.66 on every PR. Blocker rocks (AS17, up to about 15 long) are rock-hex
terrain, not debris, and stay outside this rule.

## 4. BD16: tactical zone tints

**Figures of record: nebula alpha 0.075, debris 0.065, ion storm 0.065** (`ZONE_TINT`, godot/render/board.gd:325;
colours violet (0.69, 0.49, 1.0), sand (0.83, 0.75, 0.53), yellow (1.0, 0.91, 0.4)). These implement R82 Q3
("tactical hex tint reduced, faint tint kept"). The 0.16, 0.12 and 0.13 that the audit read as the specified tints
are the values synthesis 2.7 listed as "current values" before the reduction; 2.7 left the new values to a
screenshot step, and that step landed these. So there is no 2x disagreement, only a missing record, now written.

Where they show: the fills draw only in the today look and in look C with the tactical view on (Z or the Grid
button), where the gas is also dimmed to 0.3 (board_look.gd `spec()`). The default cine view and looks A and B draw
no zone fill. Any sheet of tints states its look (BD17).

## 5. NB11: storm flash radius in hexes

Fixed in nebula_motion_spec.md section 4: the flash response is full within 0.46 hex (8 units) and gone at 0.69 hex
(12 units); the sheet glow reaches 1.3 to 2.0 hexes. Synthesis 2.3 gains a pointer.

## 6. Stations: ST3, ST5, ST10

- **ST3 converted to reported values** (tools/blender/hs/station_kit.py). The exact-equality asserts (total length 46,
  skyline at least 15, fleet dorsal tops 4.5, 5.0, 4.0 and 6.5, gantry crossbeam top 9, refinery process column under
  12) now go into the audit JSON as `r94_shape` and `r94_heights` with `matches_r94`, and a differing build prints a
  `REPORT:` line instead of failing. The R94 shapes stay the default. Kept as asserts: disconnected parts, backward
  guns, blocked battery lanes, finite bounds, the GLB round trip, the break checks, and the R94 locked-primitive
  hashes (R100's additions-only doctrine, which R113 kept; it is not part of ST3).
- **ST5 was done in #208** (PR #226): the triangle ceiling is a printed value (R113).
- **ST10 documented**: tools/blender/hs/STATION_KIT.md rewritten against the kit as it is after #183, #195 and the
  #199 re-spec: stages, which checks fail and which report, how each run starts.

## 7. AS1 and PL8: the backdrop rock asserts stay

The two asserts in `_backdrop_scale` (world.gd: no backdrop rock over 0.05 rad, and 4.4 times a rock's angle within
twice the planet's angular radius) stay unchanged until the loom turntable (#236 E-B, R124) picks a profile. They
check the clamp written just above them, so they cannot fire unless the clamp is edited; a comment now says so.

## 8. The motion capture the board runs on the PC (AS10, AS14, NB8)

`godot/world/world_shots.gd --motion 30 --every 5`, look C (cine), 1920x1080, through
`tools/pc/jobs/env230_motion.bat`. Cases: boneyard_graveyard (40 debris hexes: debris, nebula, fields views),
nebula_storm and deep_storm (nebula, storm, fields), frontier_belt (belt fields). Variants:

| Run | Switches | Answers |
|---|---|---|
| shipped | none | the baseline |
| periods | `VS_TUMBLE=periods` | AS14: wreck pieces at 80 to 120 s |
| cap_rocks | `VS_ROCK_TUMBLE=1` | AS14 and AS10: rocks turning under the cap law, fields at their AS10 rates |
| periods_rocks | `VS_TUMBLE=periods VS_ROCK_TUMBLE=1` | AS14: rocks and wrecks at the terrain periods |
| gas_flat | `VS_GAS_FLAT=1` | NB8: every gas layer at the base rate |

Each view gives `<case>_<run>_cine_m_<view>_sheet.jpg` (7 frames, 5 s apart, left to right, top to bottom),
`_diff.jpg` (first against last frame, brightened; the log gives the share of pixels that changed) and `_first.jpg`.

## 9. The question for Ryan (after the capture; the board asks it with the sheets)

Debris rocks and the backdrop rock fields never turn today; only wreck pieces turn, slowly. Which should ship?
A) keep it: rocks still, wrecks turning once every 1.4 to 4 minutes; B) rocks turn too, at the same slow law (debris
rocks once every 1 to 3 minutes, far fields slower); C) the faster terrain periods (small rocks every 20 to 40 s).
**Opus pick: B**, if the sheet shows no shimmer or swimming craters. The backdrops synthesis Ryan adopted (R79)
promised debris "drifting slowly" and rejected a near-static field as frozen, and today's field is fully static; C's
20 to 40 s turns read busy at battle distance. The answer sets `TUMBLE_K` and the rock shader default, and closes
AS14 and AS10.

## 10. Not checked

- No in-game frame was looked at by this pass (cloud thread, R135): every look claim waits on section 8.
- Why rock tumble was removed from ROCK_SHADER (the history before Nov 8 is not in this clone).
- The plain path's look in today and holo (rarely seen; cine is the default).
- `TIME` wraps every hour in Godot by default (rendering/limits/time/time_rollover_secs), so a shader tumble jumps
  pose once an hour; the wreck shader has this today, and rock tumble would too. Low priority, noted for #100.
