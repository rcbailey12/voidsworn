# Blind Rey leg: draft close-range surface detail standard (issue 200)

Written from the issue 200 evidence pack only. This draft is the missing
geometry companion to the readable-paint standard (issue 188, ruled R105).
The paint standard governs colour and value; it does not say how much
geometry detail a surface needs. R109 states the failure this standard
exists to prevent: a repainted station that still "looks super plain and
just like regular shapes." R108 states the ship version: a hand-built hull
can pass the construction bar and the paint standard and still read as a
long box.

How to read the numbers. Every number below is one of three kinds, per the
pack: (a) computed from the pack's camera anchors, with the arithmetic
shown; (b) quoted from a ruling or a filed synthesis named in the pack,
with the source named; (c) my own proposed threshold, marked INFERRED.
Nothing marked INFERRED is presented as derived or ruled.

## 1. Distance bands and scales

Two judgement bands, mirroring S11 (the paint standard's two bands).

Battle band. Judged on the binding test crop: r = 170 units, 1:1 pixels,
1920x1080 (pack section 3). Scale: about 7.5 px per unit at 1080p (pack
section 2). Worked conversions used below:

- 2 units x 7.5 px per unit = 15 px (this matches the S2 plate floor).
- 1 unit x 7.5 = 7.5 px.
- 4 units x 7.5 = 30 px.

Close band. Judged at 46 units and at 30 units for stations (the issue 172
judgement set), and on the nine-cell studio renders for ships (INFERRED
mapping: the nine-cell sweep is the existing close judgement surface for
ships under CLAUDE.md clean-or-rebuild practice). Scale derived in the
pack: at 46 units about 28 px per unit (7.5 x 170/46 = 27.7); at 30 units
about 42 px per unit (7.5 x 170/30 = 42.5). Worked conversions:

- 0.5 units x 28 = 14 px at the 46-unit zoom; 0.5 x 42 = 21 px at the
  30-unit zoom (pack section 2).
- 1 unit = 28 px at 46 units; about 42 px at 30 units.
- 4 units = 112 px at 46 units; 168 px at 30 units.

## 2. Clause set, part A: detail kinds and minimum sizes

D1 (bands judged separately). A feature is specified, built and judged per
band. Passing the battle band does not excuse failing the close band, and
the reverse. This is the geometry side of S11.

D2 (battle band shape floor, 2 units). At the battle band a mesh feature
counts as shape only at 2 units or larger in plan (pack read rule; 15 px
at 1080p, arithmetic above). Shape kinds: equipment pods, sensor housings,
antenna array bases and grouped antenna arrays, dishes and dome tops at
2 units and up, engine bells and engine nozzles, armour plate stacks,
bridge tiers, grouped masts, tanks and drums, docking hatch assemblies,
heat radiator panels, gun mounts and gun barrels, and the round 7 outline
catalogue carried in the pack (dishes, scoops, gun barrels, folded claws,
chains, rocket clusters; issue 198 via pack section 5). The CLAUDE.md blob
sweep rebuild catalogue (pack section 5) is the standing list of forms
that always carry hand detail: guns, bridge tiers, masts, antennas, tanks
and drums, bow, engine nozzles, armour plate stacks, sponsons, thin spiky
sticks rebuilt as grouped forms.

D3 (secondary band, 1 to 2 units). Features of 1 to 2 units are secondary
read at the battle band (pack read rule). Kinds: clamp housings, hatch
rings, dish and dome tops under 2 units, dock lip frames, sensor heads,
coupler assemblies. A secondary feature may support a shape feature or a
cluster. On its own it does not break a plain region at the battle band
(INFERRED: the plain-area rule in D7 requires a shape-scale interruption,
because a 7.5 to 15 px element does not change how a large face reads at
r = 170).

D4 (close band mesh, 0.5 units and up). At the close band, mesh detail is
legal from 0.5 units up (14 px at the 46-unit zoom, 21 px at the 30-unit
zoom, arithmetic above). Kinds, following the issue 172 close-zoom
language in pack section 4: 1 to 2 units, clamp housings, hatch rings,
dish and dome tops, dock lip frames, sensor heads; 0.5 to 1 unit, bolt
rings, coupler collars, raised guide strips, recessed light housings,
vent recesses, conduit runs (grouped, per D10). Below 1 unit at the battle
band and below 0.5 units anywhere, content is trim sheet, decal or normal
work, never mesh (pack read rules).

D5 (never model). No mesh below 0.5 units anywhere on a hull or a station
(pack read rule: below 0.5 units is wasted geometry). No feature between
0.5 and 1 unit may be presented or counted as battle-band detail.
Subdivision of a displaced or wavy generated surface is not detail (issue
112 mechanism, pack section 5: adding triangles subdivides the wrong
surface and does not flatten it). Detail comes from part splitting,
mounted parts, trim sheets, mesh decals and floaters, and baked maps (the
issue 112 method set).

D6 (mounting and facing). Every mounted detail part sits on the real
surface on a visible mount and carries the surface detail level of its
host (CLAUDE.md, pack section 5). Guns face forward or to the side, never
backward (CLAUDE.md). Soft or blobby generated areas near the bridge and
superstructure are rebuilt by hand before detail is judged there (CLAUDE.md
blob sweep).

## 3. Clause set, part B: plain area, density and spacing

A face, for measurement: a contiguous surface region bounded by
construction edges, authored break lines, or major form breaks (INFERRED
definition, needed so Codex can measure the rules below).

D7 (plain area, battle band). On any face, no unbroken flat region may
exceed 10 units in any direction or 100 sq units in area, measured on the
battle crop (both thresholds INFERRED). On the crop that is a run of
10 x 7.5 = 75 px, and an area of 100 x 7.5 x 7.5 = 5,625 sq px. A region
is broken by any of: a shape feature per D2; an outline feature per D2; a
construction edge carrying a major value break (at least 25 luma, S3); a
recess meeting S9 (at least 12 luma below the surrounding plate). Trim
seams, grain and decals do not break a region at the battle band; they are
sub-floor content under S2 and S7.

D8 (plain area, close band). On any primary face, no unbroken flat region
may exceed 4 units in any direction or 16 sq units in area, measured on
the close captures or the nine-cell renders (both thresholds INFERRED;
primary face INFERRED as a face that fills a full cell of the nine-cell
sweep or a full close capture). A region is broken by any D2 or D3
feature, a composed fine cluster per D10, or a recess meeting S9 whose
relief is at least 0.5 units proud or deep (relief floor INFERRED). Trim
seams alone do not break a close-band region (INFERRED: seams at about
1.5-unit spacing are trim content per pack section 4, and a face broken
only by trim is exactly the surface that reads plain in a close capture).

D9 (spacing and the noise gap). At the battle band, elements closer than
4 units edge to edge read as noise (pack read rule; 4 units = 30 px,
arithmetic above). Elements inside 4 units of each other are legal only
as one composed cluster: sharing a mount, sharing a base plate, or
aligned on one construction edge, so the group reads as a single form at
least 2 units across (composition test INFERRED; the 4-unit gap and the
2-unit form floor are the pack's). A cluster or a lone shape feature
keeps at least 4 units clear of the next cluster or feature. Derived
density ceiling: minimum pitch is 2 + 4 = 6 units, so at most one shape
feature or cluster per 6 x 6 = 36 sq units of face at the battle band
(kind (a): arithmetic from the pack's 2-unit floor and 4-unit gap).

D10 (close-band density: clusters, not scatter). Fine detail (0.5 to 1
unit) must sit in clusters anchored on a feature of at least 1 unit or on
a construction edge. Even scatter of fine detail across a face is banned
(INFERRED rule, written from the pack section 3 interlock statement:
detail clusters, not detail scatter). Inside a cluster, minimum edge to
edge spacing is 0.5 units (INFERRED: 0.5 x 42 = 21 px at the 30-unit
zoom, so neighbouring elements stay individually legible instead of
merging into grain). Fine clusters cover at most 30 percent of any single
face (INFERRED), leaving clean plate for S2 zones and S3 value steps to
work on.

D11 (outline requirement, from R108). Surface detail alone cannot pass a
hull. In each cell of the top row and each cell of the side row of the
nine-cell sweep, at least one mounted or outline feature must punctuate
the silhouette or the major outline of that cell's segment (count
INFERRED). This clause answers the R108 failure directly: V3 passed the
construction bar, scored 7 of 9 clean cells, and still read as a long box,
because what it lacked was silhouette-internal mounted detail, not surface
finish. Station outlines are governed by the R100 additions doctrine
(pack section 4) and are not re-judged by this clause; the plain-area
rules D7 and D8 do apply to stations.

## 4. Clause set, part C: interlock with the paint standard (S1 to S12)

D12 (tone budget, with S1 and S2). A detail element that carries its own
tone counts against S1 (at most three base tones plus one recess tone).
Default: detail takes the host plate's tone. An element under 2 units
across may not carry its own tone at the battle band; it takes the
largest neighbour's tone or becomes trim. This applies S2's plate floor
to geometry.

D13 (mask discipline, with S5 and S6). Geometry detail creates edges, and
edges are where the paint masks fire (pack section 3). Every detail edge
is a potential wear edge under S5, so the density caps D9 and D10 are
also paint clauses: they are what stops wear and AO from firing
everywhere, which is the round 5 clutter mechanism (issue 188 mechanism
4, pack section 3: on a melted surface the masks are melted too).
Detail edges are bevelled by default (bevels plus weighted normals, the
issue 112 method set) so wear reads as controlled lines. Detail must not
fragment a rust plate into patches below the S2 floor (S6: patches at or
above the floor, Hullbreaker rust 5 to 15 percent of the battle crop).

D14 (dead band, with S7 and S11). Geometry between 0.5 and 1 unit,
spread outside clusters, produces visible but non-structural grain at the
battle band. S7 bans exactly that band in paint; D10's cluster rule is
the geometry side of the same ban: inside a cluster of at least 2 units
across, the group reads as structure at r = 170 while its internal grain
stays in the close band, and its paint treatment follows the S11 fade
(full strength close, faded at battle distance).

D15 (lights, with S8). Recessed lights are geometry housings; the glow
inside them obeys S8: glow only from real lamps, engine throats and
faction glow features, and a glow element smaller than the S2 floor at
1080p is removed or merged into a strip. Light housings count as detail
elements for D9 spacing and D10 clustering (INFERRED application).

D16 (value mass guard, with S9 and S10). Detail adds AO and wear edges,
and both darken. After any detail pass, the battle crop median luma is
re-measured against S10; a detail pass that pushes the median outside
the faction band fails, however good the detail reads up close. This
guard is written from the R108 outcome: both round 6 hulls came out
nearly all black. Recesses created by detail must meet S9 on the sheet
(at least 12 luma below the surrounding plate), verified by that
measurement, not assumed from recess depth (INFERRED method choice).

Sequencing note (from R105). R105 defers close-range PAINT clauses until
two hulls pass the battle-distance test. Nothing in part C writes those
clauses early. Part C constrains geometry so the existing battle-band
paint clauses still hold, and states how close-band geometry behaves
under the already-ruled S7 and S11 fade. The close-band paint clauses,
when they come, sit on top of D4 and D10 unchanged.

## 5. Clause set, part D: budgets

D17 (all-in budgets). Each class budget below includes everything on the
hull: shell, surface detail, and the R99 break kit (rim bands at break
lines, the decimated dark inner liner, break-piece interiors). Nothing
rides on top of the cap (R99: the intact ship stays inside the R96
ceiling).

D18 (detail share). Of a hull's triangle budget, close-band-only detail
(features under 2 units) may take at most 25 percent on fleet-default
hulls (variant 2, clean shell plus filtered bake) and at most 40 percent
on hero hulls (variant 1, A+ rich surface). Both shares INFERRED; the
variant split itself is the ruled production default from issue 112 (pack
section 5). Battle-band shape detail is not share-capped; D9 spacing caps
it. The share cap exists because close-band detail is invisible as shape
at r = 170: uncapped, it eats the D17 break-kit room and the fleet
reserve while buying nothing at the battle camera.

D19 (fleet budget table). The R96 ceiling is about 306,000 triangles and
3.9 ms at 20 ships in the test scene (quoted, R96). Per-class budgets
inside it are this job's to propose; all per-class figures below are
INFERRED. For scale only, the pack carries Sins of a Solar Empire II
published targets (fighter about 1,500; frigate about 12,500; cruiser
about 25,000; capital about 75,000), explicitly not a Voidsworn budget;
every per-class figure below sits at or under its external counterpart,
which is what a tighter fleet ceiling requires.

Assumed fleet mix (INFERRED, stated so the sum is checkable): 8 small
craft, 6 frigates, 4 cruisers, 2 capitals or flagships. 8 + 6 + 4 + 2 =
20 ships.

Triangles:

- Small craft: 1,500 each x 8 = 12,000
- Frigate: 10,000 each x 6 = 60,000
- Cruiser: 20,000 each x 4 = 80,000
- Capital / flagship: 60,000 each x 2 = 120,000
- Fleet total: 12,000 + 60,000 + 80,000 + 120,000 = 272,000
- R96 ceiling: about 306,000
- Reserve: 306,000 - 272,000 = 34,000 (about 11 percent of the ceiling),
  held for break-state pieces in play and hero-hull escalation inside
  D18.

GPU (ms in the R96 test scene). The ceiling implies an average rate of
3.9 / 306 = about 0.0127 ms per 1,000 triangles. At the budgeted 272,000
triangles that rate predicts 272 x 0.0127 = about 3.47 ms. The per-class
caps below (INFERRED) sum slightly above that prediction, to absorb
per-object overhead on the small classes, and stay under the ceiling:

- Small craft: 0.025 ms each x 8 = 0.20 ms
- Frigate: 0.14 ms each x 6 = 0.84 ms
- Cruiser: 0.27 ms each x 4 = 1.08 ms
- Capital / flagship: 0.75 ms each x 2 = 1.50 ms
- Fleet total: 0.20 + 0.84 + 1.08 + 1.50 = 3.62 ms
- R96 ceiling: 3.9 ms. Reserve: 3.9 - 3.62 = 0.28 ms.

D20 (stations). Per R100 (quoted): design target about 20,000 triangles
and 0.35 ms per station; hard ceiling 40,000 to 45,000 triangles and
1.0 ms. Detail additions spend only the gap between the counted baseline
and the design target; if the counted baseline already exceeds the
target, additions are capped at the hard ceiling minus the baseline
(INFERRED rule; the pack notes no measured triangle count for the current
stations exists yet, and the first Codex detail job counts first).
Station detail follows the additions doctrine (pack section 4): locked
primitives do not move, resize in plan, or get deleted; additions at
least 2 units proud of their surface count as shape; close-zoom mesh
detail lives in the 1 to 2 unit band, below 1 unit is trim sheet and
normal content, nothing below 0.5 units is modelled. Station budgets sit
outside the 20-ship fleet sum, because the R96 ceiling is stated at 20
ships; whether a combined scene needs its own ceiling is owner question
3 below.

## 6. Clause set, part E: break-line fit (R98, R99)

D21 (no crossings). No detail element may cross an authored break line.
Break lines per R98: two or three authored lines per hull, with matching
interior faces and damage textures. Per R99, capital hulls break on two
transverse lines plus one longitudinal line. Per pack section 4, stations
carry two authored break lines per station kind at structural junctions.
Every detail element sits wholly inside one break segment.

D22 (clearance and rim bands). Mounted detail keeps at least 1 unit clear
of a break line, on both sides (INFERRED distance). Rim bands at break
lines and at openings (R99) carry no mounted detail, no trim and no
decals: they are reserved for the hot-edge read. One exception, quoted
from R100: station truss and gantry members get authored damage decals at
break lines instead of interior faces.

D23 (liner and interiors are exempt, by design). The decimated dark inner
liner (R99) and all interior faces take no surface detail, and D7, D8 and
D10 do not apply to them; plain there is correct, because the liner's job
is to never read as empty (R98 game side: every cut and broken piece gets
a solid inside). Full interiors exist only in the break pieces (R99):
their decks and bulkheads are structure, not surface detail, they are
not judged by the density clauses, and their triangles count inside D17.

D24 (damage room). Damage masks live inside the R96 paint graph at the
break lines (R99). The D22 clearance is what leaves them room to read.
In the intact state, detail outside the clearance may carry S5 wear; it
may not carry damage state. A detail element that would be cut in half by
a break is a D21 failure at build time, not a damage effect.

D25 (Chorus). Chorus interiors are flesh and bone (R98), and broken
Chorus pieces show flesh and bone insides with hot edges that cool, as at
every other faction's break lines. For Chorus hulls the close-band
catalogue in D4 is read organically: bone ribs, flesh folds and growth
rings count as breaking features under D8, and panel-seam language does
not apply to Chorus surfaces (INFERRED application of R98). The
plain-area maxima and the cluster rule still apply; only the vocabulary
of what counts as a feature changes.

## 7. Pass/fail check on the existing sheets

The check runs on the sheets that already exist: the ship nine-cell sweep
(bow, midship, stern, each from top, side and below, studio renders, each
cell judged clean or rebuild by hand), the paint standard's binding
battle crop (r = 170, 1080p), and the station judgement set (4K plan
view, battle angle at about 170 units, close zoom at 46 and 30 units,
with a docked battleship and frigate for scale). The issue 194 proposals
in pack section 6 (a screen-space feature filter in the kit assembler,
and automating the measurable half of the paint gate) are design input
for automating the sheet measurements below; they are proposals, not
rulings, and the check does not depend on them.

Sheet-carried measurements (Codex measures on the sheet; a pass is a
number inside the clause limit):

- D2, D3, D4 feature sizes: measure feature widths on the battle crop at
  7.5 px per unit and on close captures at 28 and 42 px per unit. A
  tone-carrying element under 15 px wide on the battle crop fails D12.
- D7 plain area, battle band: largest unbroken run and area on the battle
  crop, px converted at 7.5 px per unit (limits: 75 px run, 5,625 sq px
  area). Caveat: the crop shows projected area; see the mesh list below.
- D8 plain area, close band: largest unbroken region on each nine-cell
  render (ships) and each close capture (stations), converted at the
  capture's px per unit (4-unit limit: 112 px at the 46-unit zoom, 168 px
  at the 30-unit zoom).
- D9 spacing: edge to edge gaps between uncomposed elements on the battle
  crop; any gap under 30 px between elements that do not form one cluster
  fails.
- D10 clustering and coverage: judged on close captures and nine-cell
  renders; scatter outside clusters fails by eye against the clause, and
  cluster coverage per face is estimated from the same captures.
- D11 outline: count per cell on the top and side rows of the nine-cell
  sweep; a cell with no outline or mounted feature fails that cell.
- D12, D15, D16 paint interlock: the existing paint test machinery,
  re-run after the detail pass (tone count, glow audit, median luma
  against S10, recess drops against S9). Detail is judged only on sheets
  whose paint test still passes.

Clauses that honestly need a mesh statistic, not a sheet:

- D17, D18, D19, D20 budgets: triangle counts per hull, per class and per
  part group (shell vs detail vs break kit), plus test-scene timing for
  the ms caps. No sheet shows a triangle count. Cost of the check: a
  one-time script build, then a per-hull unattended run.
- D7 and D8 true area: a sheet shows projected area, and a face seen at
  an angle understates its true plain area. The sheet check above is the
  judgement of record (the owner judges by sheets), but the true largest
  unbroken region per face is a mesh face analysis (same one-time script
  build). If the two disagree, the mesh figure governs the clause and the
  sheet figure governs the sign-off conversation.
- D8 relief floor (0.5 units): relief reads on a sheet only at grazing
  angles. Verify by mesh measurement.
- D21 and D22 break-line fit: crossings and the 1-unit clearance need
  the mesh with break lines marked, or one added render per hull, a
  break-line overlay sheet (one-time script build, per-hull unattended
  run). Not judgeable from the standard sheets, which do not draw the
  break lines.
- D5 sub-floor audit: the smallest modelled feature on a hull is a mesh
  statistic (a per-hull feature-size report from the same script build).

Verdict rule. A hull passes the detail standard when all three hold:
(i) the battle crop checks pass (D2, D7, D9, and the D12 to D16 paint
re-run); (ii) at least 7 of 9 cells of the nine-cell sweep are clean with
the detail clauses applied per cell (the 7 of 9 bar is R105 and S12 for
paint; applying the same bar to detail sign-off is INFERRED); (iii) the
mesh statistics sit inside D17 to D19. A station passes when no capture
in its judgement set fails its band's clauses (INFERRED threshold; the
station set has no cell grid to take a fraction of) and its mesh
statistics sit inside D20. Detail sign-off is separate from paint
sign-off under S12, and a hull needs both: R108 is the proof that one
without the other still ships a plain box.

## 8. Proposed owner questions (five, with chair picks)

Q1. Does the fleet budget bind to a fixed test mix (8 small craft, 6
frigates, 4 cruisers, 2 capitals), or do per-class caps stand alone?
Chair pick: adopt the fixed mix. The R96 ceiling is defined at 20 ships,
and a stated mix is what makes the fleet sum a single checkable number
(272,000 tris, 3.62 ms, section 5). Cost of the other option: per-class
caps alone cannot fail a battle that stacks capitals; every new
composition needs its own sum, which is a one-time checker script build
plus an unattended run per composition, and the standard loses its
single pass figure.

Q2. Are the plain-area maxima right as drafted (battle band 10 units and
100 sq units; close band 4 units and 16 sq units, D7 and D8, both
INFERRED)? Chair pick: adopt as drafted and recalibrate after the first
two hulls pass, mirroring R105's sequencing of close-range paint clauses
after two hulls pass the battle test. Cost of tightening now: more
detail per hull, more unattended build iterations before a hull reaches
its sheet, and more owner review minutes per sheet round. Cost of
loosening: the R109 plain read survives on exactly the large faces the
rule exists to fix.

Q3. Does a scene that fields a station together with 20 ships need a
combined ceiling (fleet 3.9 ms plus station up to 1.0 ms at the R100 hard
ceiling), or is the station judged alone under R100? Chair pick: judge
the station alone for now; write the combined ceiling only when a level
actually fields both at once. Cost of the other option: one combined
test scene (one-time build) plus a timing run per station kind, spent
before any such scene exists.

Q4. Do the close-band detail share caps stand (25 percent fleet default,
40 percent hero, D18, INFERRED)? Chair pick: adopt. Cost of the other
option: nothing to build, but every later hull carries the round 5
clutter risk uncapped and the break kit competes for the same triangles
with no rule to settle the argument.

Q5. Is the break-line clearance 1 unit (D22, INFERRED) or 2 units, to
match the shape floor? Chair pick: 1 unit. Arithmetic on the 41.6-unit
Pyre-Barge with two transverse break lines (R99): clearance sterilizes
2 lines x 2 sides x 1 unit = 4 units of hull length, 4 / 41.6 = about 10
percent; at 2 units it sterilizes 8 units, about 19 percent, before the
longitudinal line's band is counted. Cost of the other option: fewer
legal mounting positions near the middle of the hull and thinner detail
on the midship cells, which are the cells that already read plainest.

End of leg.
