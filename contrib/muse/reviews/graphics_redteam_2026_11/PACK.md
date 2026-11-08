# Evidence pack: red team of the Voidsworn graphical standards

Job: a red team of every numeric constraint in the graphical standards
stack of Embers of the Hollow Sun (Voidsworn): the performance
ceiling and test protocol, the readable paint standard (issue 188,
clauses S1 to S12, ruled R105), the close-range surface detail
standard (issue 200, clauses D1 to D25), and the station budgets
(R100, carried in issue 200 clause D20). Four legs run from this
pack: three writer legs (blind Rey, DeepSeek, Qwen) and one review
leg (Argon). The chair screens every leg before anything is adopted.

This pack is the legs' complete evidence. It is built from the
ceiling pressure test synthesis and its source files, the issue 188
and issue 200 syntheses, and FINDINGS entries R96 to R109 as quoted
in those documents. Where this pack and a leg disagree, the pack
wins. Where a standard's own text and this pack's summary of it
disagree, the standard wins and the disagreement is a finding.

## 1. Framing

### 1.1 The owner's instruction

Ryan Bailey, Nov 6, 2026, in substance: for the triangle and other
graphical work, red team it as a game dev, a graphics designer, and
an agent lead. The project keeps forcing artificial constraints. The
job is to make sure that failure is not repeated here, while clearly
documenting the findings, the possible limitations, and the
approaches.

### 1.2 The failure mode, as a worked example: the 306k ceiling

The ceiling pressure test (Nov 6, 2026) established the following
from the project record. It is the pattern this red team exists to
hunt, in three acts.

Act one, the anchor. R96 (ship look round 3, issue 147, chair pick
adopted by the owner) set "a hard round 4 acceptance ceiling near
stage 5's current figures (about 306k triangles, about 3.9 ms at 20
ships in the round 3 test scene)". The synthesis stated the purpose
plainly: stop silent budget creep after round 2 ran to 614k
triangles and 5.69 ms. "The exact ceiling numbers are the owner's
call; stage 5's figures are the anchor." The number was the measured
cost of one incumbent hull (stage 5, 305,857 tris), promoted into a
performance law. The record contains no derivation from a frame-time
budget, no minimum-spec GPU decision, and no hardware capability
test. The ceiling was not fabricated and not useless: it was an
honest cost observation under a defined protocol. Its defect was
scope. It then bit in production: the round 6 README records V1
failing "the strict 306,000-triangle check" and the 3.9 ms ceiling
while rendering at 4.172 ms GPU for 20 copies on the owner's card,
in a scene the record shows is nowhere near a frame wall (below).

Act two, the unit error. The issue 200 detail standard read the
same 306k figure as a fleet total and built a fleet budget under it
(per-class caps summing to 272,000 tris for a 20-ship fleet). R96's
figure is per ship: the round 4 protocol heads its column
"Triangles per ship" and renders 20 copies of one hull (20 x
307,477 = 6,149,540 tris in the anchor scene). Under the fleet-sum
reading, the stage 5 anchor ship itself (305,857 tris) exceeded the
capital cap (60,000) by 5.1x, the shipping hull (256,468) by 4.3x,
and the smallest measured hull, V3 cut (220,524), by 3.7x. Every
measured hull in the project failed the standard, including the hull
the ceiling was anchored on. The chair owned the error: the
fleet-sum construction was the chair's, and the owner's Nov 5, 2026
ruling adopting the fixed mix was made on that premise.

Act three, the replacement that repeated the error. The ceiling
synthesis's first replacement was a per-class per-ship triangle
table in the shape of Sins of a Solar Empire 2's published counts
(1,500 / 12,500 / 25,000 / 75,000, hero 250,000): the same anchoring
move one level up, importing another game's numbers into a metric
the evidence had just discredited. The owner challenged it the same
day ("all of your findings go back to tris when the research said
that wasn't the issue and we had room to scale") and the chair
withdrew it the same day.

The rulings that stand now (ceiling synthesis section 8; issue 200
synthesis section 8): the fleet cap is removed; triangle counts are
reported, not capped; the only binding performance limit is a
measured scene gate in ms on the RTX 5080 (section 3, C3), whose
benchmark is filed as GitHub issue 207 to Opus and has not run yet;
heroes are fine and rare with no triangle limit. Everything else in
the two standards was explicitly left standing by the Nov 6, 2026
correction, including several numbers denominated in triangles
(C54, C59, C60). That residue is part of what this red team prices.

### 1.3 The red team's question

For every numeric constraint in the graphical stack, answer three
things:

1. What kind of number is it? MEASURED (produced by an instrument on
   a real asset, crop, or scene), DERIVED (computed from measured or
   ruled inputs, with the arithmetic shown), ASSUMED (a chosen
   threshold with no measurement or derivation in the record), or
   ANCHORED (the measured property of one incumbent asset, or one
   external game, promoted into a rule).
2. What does it cost if it is wrong, in each of the three lenses:
   game dev (performance or gameplay), graphics designer (look,
   readability, art direction), agent lead (pipeline effort,
   enforceability, wasted runs)?
3. What measurement or build would settle it, and what does that
   cost in agent terms (section 1.5)?

A constraint is an artificial constraint, in the owner's sense, when
its number cannot be traced to a measurement or a derivation but it
still binds builds, fails hulls, or spends review. The red team's
deliverable is not a bonfire: several assumed numbers are honest
chair judgments, labelled INFERRED in the standards themselves, and
the paint standard exists because unmeasured paint failed five
rounds in a row. The deliverable is a stack in which every number's
provenance is stated, the expensive assumptions are named, and each
one has a priced way to become a measurement.

### 1.4 What binds today

Still binding after the Nov 6, 2026 corrections: all of issue 188
(S1 to S12 and the blur test, ruled R105); issue 200 parts A, B, C
and E (D1 to D16, D21 to D25) and the D18 detail share caps and D20
station budgets; the R100 station doctrine; the scene gate as the
sole performance law (pending its benchmark). Withdrawn or retired:
the R96 ceiling as a cap (kept as an anchor measurement), the issue
200 D19 fleet sum and its per-class tri and ms caps (kept as
reporting statistics), and the ceiling synthesis's Sins-shaped
per-class table (withdrawn the day it was proposed). The inventory
in section 3 covers all of these, live and withdrawn, because a
withdrawn number that still sits in a standard's text can be
re-adopted by accident, and two of them (C12, C13) still sit in D19.

### 1.5 Cost units

Costs in this pack, and in every leg, are stated only in agent
terms: Codex runs (one-hour cap per run), Opus runs, one-time
script builds, per-hull unattended runs, and owner review rounds.
No human-time estimates anywhere (standing rule R99: the project's
hour estimates kept missing because they were anchored on human
studio production, not on the agent pipeline that does the work).

## 2. Evidence base

### 2.1 Documents

- Ceiling pressure test chair synthesis (Nov 6, 2026), including
  its section 8 owner pushback and chair correction:
  ~/workspace/voidsworn-ceiling-vet/synthesis.md
- Ceiling pack sources: round 3 synthesis (issue 147), round 4 and
  round 6 build READMEs, FINDINGS R96 to R109:
  ~/workspace/voidsworn-ceiling-vet/src/
- Readable paint standard, issue 188 chair synthesis (S1 to S12,
  the blur test, per-faction notes, screening record):
  ~/workspace/voidsworn-188-work/synthesis.md
- Surface detail standard, issue 200 chair synthesis (D1 to D25,
  the pass/fail check, owner rulings, section 8 correction):
  ~/workspace/voidsworn-200-work/deliver/contrib/muse/research/
  surface_detail_2026_11/synthesis.md

### 2.2 The measurement series (ceiling synthesis, section 3)

Protocol: 20 non-overlapping copies of one hull sharing one mesh and
map set, 5 by 4 layout, RTX 5080, Godot 4.7.2 Forward+, 1920x1080,
MSAA 4x, vsync disabled, compressed mipmapped maps, G4 studio
lights, 100 warm-up frames, 360 measured frames. Isolated rendering
figures, not full-battle frame rates.

| Variant | Tris per ship | Scene tris (x20) | GPU ms | Implied tris/sec | GPU ms per copy |
|---|---|---|---|---|---|
| today | 256,468 | 5,129,360 | 2.877 | about 1.78 billion | 0.144 |
| V2 | 289,047 | 5,780,940 | 3.248 | about 1.78 billion | 0.162 |
| V1 | 307,477 | 6,149,540 | 4.172 | about 1.47 billion | 0.209 |
| V3 cut | 220,524 | 4,410,480 | 2.516 | about 1.75 billion | 0.126 |
| V3 original | 622,570 | 12,451,400 | 5.25 | about 2.37 billion | 0.263 |

Readings the ceiling synthesis established: if raw vertex throughput
bound the scene, throughput would be flat and time proportional to
count; neither holds (today to V1 is +20 percent tris for +45
percent time; V1 to V3 original is +103 percent tris for +26 percent
time; the heaviest variant has the highest throughput). A round 5
paint swap on unchanged meshes moved GPU time about 1.3 percent. The
frame-median-minus-GPU gap is nearly constant (0.218 to 0.244 ms).
At the anchor, the isolated scene's frame median is about 4.4 ms
against a 16.6 ms frame at 60 fps, about 26 percent of the frame,
in a scene with no game logic, effects, planets, nebulas, or UI.
The anchor asset is not a stable rod: V1 measured 3.887 ms in one
session and above 3.9 ms in a later one; the round 4 series lists
4.172 to 4.175 ms, about 7 percent of session variance against the
adopted 3.9 ms figure.

### 2.3 Reference measurements the paint standard stands on

Measured on the Hullbreaker reference art crop and the round 5
candidates, as recorded in the issue 188 synthesis: reference median
luma 30.07 (round 5 V1 41.63, V2 44.26); reference rust share 13.62
percent of the battle crop (V1 4.67 percent); reference red trim
0.97 percent and bright red 0.00 percent (round 5 measured 0.53 and
0.52 percent); reference dark share 85.41 percent (V1 94.76
percent). Camera anchors: battle crop at r = 170 units, 1:1 pixels;
about 7.5 px per unit at 1080p, about 15 px per unit at 4K; the
41.6-unit Pyre-Barge spans about 310 px at 1080p and about 620 px
at 4K. Construction scoring after five rounds: hand-built V3 is 7
of 9 clean cells; every AI hull is 0 of 9.

## 3. Constraint inventory

Every numeric constraint in the graphical stack, live and withdrawn.
Template per entry: the value and where it lives; its provenance
class with the evidence; what breaks if the number is wrong; what
measurement would settle it. Provenance classes are defined in
section 1.3. Tallies: 65 entries; MEASURED 4, DERIVED 11, ASSUMED
44, ANCHORED 6.

### A. Performance ceilings, budgets, and the test protocol

C1. R96 triangle ceiling: about 306,000 tris per ship. RETIRED as a
cap Nov 6, 2026; kept as the anchor measurement.
- Lives in: FINDINGS R96 Q3; issue 147 synthesis section 7, Q3;
  issue 200 D17 to D19 (as the reference ceiling).
- Provenance: ANCHORED. Evidence: the round 3 synthesis states the
  number is stage 5's measured figure (305,857 tris) and "stage 5's
  figures are the anchor"; its stated purpose was anti-creep
  governance after round 2, not a capability finding.
- If wrong: it was, as a cap. Round 6 tooling failed V1 on "the
  strict 306,000-triangle check" (V1: 307,477 tris) while the same
  scene rendered in about a quarter of a 60 fps frame. As a cap it
  taxed every hull for one hull's cost.
- Settles it: nothing to settle; retired. The measurement stands as
  the recorded cost of the stage 5 hull under the protocol.

C2. R96 millisecond ceiling: about 3.9 ms GPU at 20 ships in the
test scene. RETIRED with C1.
- Lives in: FINDINGS R96 Q3; issue 200 D19 (as the ceiling the ms
  caps sum under).
- Provenance: MEASURED, with an anchored selection. Evidence: the
  quantity was measured repeatedly, but the adopted figure matches
  the earlier session: round 5 records V1 at 3.887 ms in one session
  and above 3.9 ms in a later one, and the round 4 series lists V1
  at 4.172 to 4.175 ms. The anchor asset exceeds its own adopted
  ceiling by about 7 percent under the later protocol.
- If wrong: a cap set at one session's reading fails the same asset
  in another session; any cap inside the variance band is a coin
  flip, not a gate.
- Settles it: the multi-session protocol the ceiling synthesis
  adopted as an option (3 sessions, median and range reported);
  one-time script change plus unattended re-runs per variant.

C3. The scene gate (the only binding performance limit, ruled
Nov 6, 2026): one representative mixed-fleet battle scene (distinct
hulls and materials, effects on, planets and nebulas present, UI
up), gated on GPU ms and frame median against a stated share of
the 16.6 ms frame on the RTX 5080.
- Lives in: ceiling synthesis sections 5 and 8; issue 200 synthesis
  section 8; benchmark job filed as GitHub issue 207 to Opus.
- Provenance: ASSUMED, pending. Evidence: the 16.6 ms frame is
  derived from the 60 fps target; the share of that frame the gate
  allows does not exist yet. The ruling states the gate number is
  set from the benchmark's first measurement, not asserted in
  advance. The gate is a ruled mechanism carrying an unchosen
  number, and it is now the single point of failure for every
  performance judgement in the stack.
- If wrong: if the first measurement becomes the gate by default,
  the gate is C1 again with better scenery: one scene's cost
  promoted to law. If the share is set tight, it re-caps fidelity
  through the back door; if loose, it binds nothing and creep
  returns unpriced.
- Settles it: the issue 207 benchmark itself (one Opus run to build
  and measure, per the filed spec), plus an explicit owner ruling
  on the share, plus the isolation runs the ceiling synthesis named
  (shadows off, MSAA 2x and off) so the gate's number is understood,
  not just observed.

C4. Per-ship GPU ms tracking figures: capital 0.25 ms, cruiser
0.12 ms, frigate 0.05 ms, small craft 0.01 ms, in the protocol
scene.
- Lives in: ceiling synthesis section 4, option 55 (adopted as
  tracking numbers under the scene gate; from the Qwen leg's
  section E).
- Provenance: ASSUMED. Evidence: no derivation is shown in the
  record; the chair's reconciliation shows the four figures sum to
  1.36 ms at the 8/6/4/2 reporting mix, and that the same leg's
  5.0 ms fleet figure is an all-capitals worst case, not the mix.
  They are also protocol-scene figures: per-copy GPU ms in the
  measured series runs 0.126 to 0.263 across all five variants, so
  the frigate and small-craft figures sit below every per-copy cost
  ever measured in the scene they describe.
- If wrong: as tracking numbers the damage is soft (reports alarm
  or soothe without cause), but tracking numbers have a history in
  this project of hardening into caps (C1 began as an observation).
- Settles it: the gpu.json pull named in the ceiling synthesis
  (single-ship GPU ms per variant is already retained there), then
  the issue 207 benchmark's per-class figures; one unattended
  analysis run once gpu.json is opened.

C5. Protocol resolution: 1920x1080 is the binding measure for
performance figures.
- Lives in: round 4 and round 6 READMEs (protocol statement);
  issue 188 Q1 (1080p binds paint judgement, ruled R105).
- Provenance: ASSUMED. Evidence: a protocol convention, carried
  across rounds; the record contains no measurement at any other
  resolution for the performance series (4K captures exist as a
  visual record only, round 6 README).
- If wrong: every ms figure in the stack is a 1080p figure; a
  future 4K or ultrawide target reopens every budget at once.
- Settles it: one protocol re-run at a second resolution on the
  existing variants (unattended run), priced before it is needed.

C6. MSAA 4x in the performance protocol.
- Lives in: round 4 and round 6 READMEs (protocol statement).
- Provenance: ASSUMED. Evidence: never sensitivity-tested in the
  record; the ceiling synthesis lists an MSAA 2x/off isolation run
  among the measurements that would settle what binds, and they
  have not run. (The ceiling vet also corrected a leg claim that 4x
  MSAA "quadruples the fragment work": MSAA multiplies coverage
  samples and resolve bandwidth, not fragment shader invocations.)
- If wrong: the protocol's ms figures price an anti-aliasing
  setting no player may ever select, and the scene gate (C3)
  inherits the same setting unexamined.
- Settles it: the MSAA isolation run on the existing scene (one
  unattended run per setting).

C7. Protocol sampling: 100 warm-up frames, 360 measured frames.
- Lives in: round 4 and round 6 READMEs.
- Provenance: ASSUMED. Evidence: a convention, stable across
  rounds; the record's own variance evidence (C2: about 7 percent
  between sessions) was produced across sessions, not within the
  360-frame window, so the window's adequacy for the variance that
  actually bites is untested.
- If wrong: tight comparisons between variants (the round 5 paint
  swap moved GPU time about 1.3 percent) may sit inside sampling
  noise and still drive rulings.
- Settles it: the 3-session median-and-range protocol (see C2);
  cost shared with C2.

C8. Test scene composition: 20 copies of one hull, one shared mesh
and map set, non-overlapping 5 by 4 layout, G4 studio lights.
- Lives in: round 4 README ("These are isolated rendering figures,
  not full-battle frame rates... or a memory test of twenty
  different assets").
- Provenance: ASSUMED (instrument design). Evidence: under Godot
  Forward+, identical MeshInstance3Ds with the same mesh and
  material auto-instance, so the scene is close to a best case for
  draw and material cost, the very costs the ceiling synthesis
  ranks as the suspected binders. The README itself disclaims the
  reading the ceiling later put on it.
- If wrong: it was, as a budget instrument (act one, section 1.2).
  As an A/B instrument for hull variants it remains sound, and the
  ceiling synthesis keeps it in that role.
- Settles it: the mixed-fleet benchmark (C3) replaces it as the
  budget instrument; no further cost.

C9. Fleet size in the ceiling definition: 20 ships.
- Lives in: R96 Q3 ("at 20 ships"); issue 200 D19 (the sum is over
  20 ships).
- Provenance: ANCHORED. Evidence: 20 is the test scene's
  composition (C8) promoted into the fleet the budgets were defined
  over. The project's density position (about 20 as a typical
  battle target, not a cap, with swarm factions as the known
  exception) is a design lean; the record holds no measured
  distribution of real battle sizes to derive 20 from.
- If wrong: budgets sized for 20 misprice every battle that is not
  20; a swarm battle at the design's own exception breaks a sum
  that was only ever a scene description.
- Settles it: nothing in documents; the scene gate (C3) makes the
  count a scene parameter instead of a budget premise, which is
  the fix already ruled. A bot-campaign battle-size distribution
  could be counted from existing sim tooling (one unattended run)
  if a number is ever needed.

C10. Reporting mix: 8 small craft, 6 frigates, 4 cruisers, 2
capitals (the former binding mix, now reporting composition only).
- Lives in: issue 200 D19 and section 8.
- Provenance: ASSUMED. Evidence: labelled INFERRED in D19, "stated
  so the sum is checkable"; no battle-composition data in the
  record supports 8/6/4/2 over any other mix.
- If wrong: low stakes while it only denominates reports; the risk
  is the C1 pattern again, a reporting convenience quietly becoming
  the composition builds are judged against.
- Settles it: the same battle-size and composition count as C9, if
  wanted; otherwise an explicit note wherever the mix is printed
  that it is a reporting convention.

C11. Hero count: at most 2 heroes per battle.
- Lives in: ceiling synthesis section 5 part 1 (withdrawn table);
  restated in section 8 as the owner's ruling that heroes are fine
  and rare, with no triangle limit.
- Provenance: ASSUMED. Evidence: the count of 2 entered with the
  withdrawn Sins-shaped table and survived its withdrawal as a
  qualitative ruling; no measurement or design document in the
  record derives 2.
- If wrong: a hard 2 in encounter design is a gameplay constraint
  wearing a performance costume; the performance record shows two
  hero-scale hulls are nowhere near the tested headroom.
- Settles it: an owner design ruling on whether the cap is a design
  rule (encounter composition) or was only ever budget scaffolding;
  zero build cost. Performance needs no count at all under C3.

C12. Issue 200 per-class triangle caps: small craft 1,500, frigate
10,000, cruiser 20,000, capital 60,000; fleet sum 272,000.
WITHDRAWN Nov 6, 2026; retained in D19's text as reporting
statistics.
- Lives in: issue 200 D19; withdrawn by issue 200 section 8.
- Provenance: ANCHORED. Evidence: built under the fleet-sum unit
  error on the R96 anchor (section 1.2, act two); the capital cap
  is contradicted by every measured hull (anchor 5.1x over,
  shipping hull 4.3x, V3 cut 3.7x).
- If wrong: it was, completely, as a cap. Residual risk: the
  figures still sit in D19's text; a future reader can re-adopt
  them without the section 8 context.
- Settles it: settled (withdrawn). The remaining action is textual:
  one edit pass marking the figures as withdrawn in place wherever
  D19 is quoted (one Opus run at the next FINDINGS pass).

C13. Issue 200 per-class ms caps: small craft 0.025 ms, frigate
0.14 ms, cruiser 0.27 ms, capital 0.75 ms; fleet total 3.62 ms.
WITHDRAWN with the C12 sum.
- Lives in: issue 200 D19; withdrawn by issue 200 section 8.
- Provenance: DERIVED, from a false premise. Evidence: D19 derives
  them from an implied linear rate (the ceiling implies about
  0.0127 ms per 1,000 tris; a second leg's linear derivation landed
  at 0.0122, and the synthesis took the agreement as support). The
  measured series refutes linearity: implied throughput runs 1.47
  to 2.37 billion tris/sec across the five variants (section 2.2).
  Two derivations agreeing on a rate the data contradicts is the
  pattern to hunt: derivation is not measurement.
- If wrong: it was, as caps; same residue risk as C12.
- Settles it: settled (withdrawn). The lesson is carried in
  section 1.3: a derived number inherits the provenance of its
  weakest premise.

C14. The Sins-shaped per-class table: strikecraft 1,500, frigate
12,500, cruiser 25,000, capital 75,000, hero capital 250,000.
WITHDRAWN the day it was proposed (Nov 6, 2026).
- Lives in: ceiling synthesis section 5 part 1; withdrawn by its
  section 8.
- Provenance: ANCHORED. Evidence: the figures are Sins of a Solar
  Empire 2's published per-ship counts (the only comparable title
  that publishes any, per the ceiling pack's research), imported
  from a game fielding hundreds of ships in a different engine;
  its capital line would have capped a Voidsworn battleship below
  the level the owner's own shipping flagship already renders at
  (256,468 tris).
- If wrong: it was, as a budget. It survives in the record as the
  worked example of anchoring on an external game.
- Settles it: settled (withdrawn). No action.

### B. The paint standard (issue 188, S1 to S12, ruled R105)

C15. S1 tone count: at most 3 base tones, plus 1 recess tone darker
than all three. Trim and glow never count as tones.
- Lives in: issue 188 synthesis, clause S1.
- Provenance: ASSUMED. Evidence: the clause's stated basis is R103
  ("few big plates, two or three tones"); the chair took the top
  of the owner's range. No measurement in the record distinguishes
  3 tones from 2 or 4 at the battle camera.
- If wrong: at 2, palettes like Hegemony's pale grey / steel blue /
  recess lose a needed step; at 4, the round 5 patchwork mechanism
  (many neighbouring shades) re-enters through a legal door. The
  cost lands on the designer's palette freedom first.
- Settles it: a two-way build of one hull at 3 vs 4 tones, judged
  on the existing blur test sheets (one Codex run for the second
  paint pass, one owner review round).

C16. S2 plate floor: no zone carrying its own tone may be smaller
than 2 units across (30 px at 4K, 15 px at 1080p); a smaller region
takes its largest neighbour's tone or becomes trim.
- Lives in: issue 188 clause S2; inherited by issue 200 D2 and D12.
- Provenance: DERIVED. Evidence: the standard labels it derived and
  shows the derivation: 2 units is twice the binding test's blur
  radius (1 unit, C17), so a floor-size zone survives the blur as a
  shape while a 1-unit zone is erased by it. The derivation is
  sound relative to the test; it inherits the test's own premises
  (C17, C31).
- If wrong: if the blur is not the right model of the battle view,
  the floor is calibrated to the instrument, not the eye: plates
  sized to pass the test rather than to read in the game.
- Settles it: an in-game battle capture at the real camera judged
  beside the studio crop of the same hull (one capture run; the
  round 6 run already notes its art comparison is approximate, with
  exposure and histograms unmatched).

C17. Blur radius: 1 unit (about 7.5 px at 1080p, 15 px at 4K),
Gaussian, on Rec. 709 greyscale, in the binding paint test.
- Lives in: issue 188 synthesis section 3, step 3; implemented in
  round 6 (value_structure sheets).
- Provenance: DERIVED. Evidence: set at half the S2 floor so the
  blur "erases exactly what the standard forbids tone zones to be,
  and preserves what it allows". Two open seams: the standard's
  parameter word is "radius" while the round 6 README records the
  implementation as "sigma 7.5 pixels" at 1080p and "sigma 15" at
  4K, and radius and sigma are not the same parameter; and the
  choice of 1 unit (rather than 0.5 or 2) is fixed by the floor it
  is meant to test, which is circular unless the game view agrees
  (see C16).
- If wrong: every S-clause judged through the test inherits the
  error; a too-strong blur passes speckle the game shows, a
  too-weak blur fails plates the game reads fine.
- Settles it: the C16 in-game comparison, plus one script run
  re-blurring an existing crop at radius and at sigma to check
  whether the round 6 sheets used the standard's blur (one-time
  script check, unattended).

C18. S3 neighbour value step: neighbouring plates differ by at
least 12 luma levels (0 to 255 scale), or the zones merge.
- Lives in: issue 188 clause S3; reused by issue 200 D7 (a major
  value break of at least 25, C19) and D16/S9 (C26).
- Provenance: ASSUMED. Evidence: the standard labels the S3
  thresholds INFERRED, "chosen by the chair", and records Argon's
  point that neither number is a pack measurement. The stated basis
  is one leg's judgment that 12 is "the smallest step that reads as
  deliberate after blur".
- If wrong: too small, and plates that pass still merge at battle
  distance (the flat-collapse fail in the test); too large, and
  mid palettes are pushed out of their own colours (the standard's
  own Q2 reasoning against a flat 25). This number does real work:
  D7 counts a region as broken only if an edge carries this step's
  bigger sibling.
- Settles it: a step-ladder crop (one plate pair rendered at steps
  of 6, 9, 12, 18, 25, blurred and unblurred, judged by the owner
  on one sheet): one script build, one unattended render run, one
  owner review round. The same sheet settles C19 and informs C26.

C19. S3 major-break value step: at least 25 luma levels at major
form breaks and the silhouette, or the break is carried by a
recess under S9.
- Lives in: issue 188 clause S3; issue 200 D7 adopts 25 as the
  value break that ends a plain region.
- Provenance: ASSUMED. Evidence: labelled INFERRED; two writer legs
  converged on 25 at breaks, and the chair's two-tier form "takes
  both observations instead of averaging them". Convergence of
  judgements is not a measurement.
- If wrong: too small, and form breaks vanish in the blur (the
  test's third fail condition); too large, and every break demands
  a contrast some factions' palettes cannot pay (Eclipse's two dark
  tones are already directed to spend 25 at "the breaks that
  matter", an unpriced ration).
- Settles it: the C18 step-ladder sheet, which prices both tiers
  in one run.

C20. S6 rust band (Hullbreakers): total rust in the battle crop
stays in the band 5 to 15 percent.
- Lives in: issue 188 clause S6; issue 200 D13 (rust plates must
  not fragment below the S2 floor).
- Provenance: ANCHORED. Evidence: the standard labels the band
  INFERRED and states its anchors: the top sits near the reference
  crop's measured 13.62 percent (C21), the bottom near round 5
  V1's measured 4.67 percent, which "visibly failed to break up its
  ground". The band edges (5, 15) are roundings of two measured
  crops, one of which is a single rejected candidate.
- If wrong: the bottom edge rests on one data point with a
  confound (V1 failed on median luma and patchwork at the same
  time; its rust share may not be why it failed). A band built on
  one pass and one fail can exclude the right answer on both sides.
- Settles it: a rust-share ladder on one hull (sheets at about 3,
  5, 8, 12, 15, 20 percent, other measures held), judged on the
  blur test: one Codex run, one owner review round.

C21. Reference rust share: 13.62 percent of the battle crop.
- Lives in: issue 188 clause S6 (the reference measure the band
  anchors on).
- Provenance: MEASURED. Evidence: classifier measure on the
  reference art crop, the same crop the round 5 colour measurement
  used. One crop, one faction, one framing: the measurement is
  real and its generality is the open question, which is why C20
  is classified ANCHORED rather than MEASURED.
- If wrong: as a fact about that crop it stands; treated as a
  target for other framings or factions it misleads (S10's
  per-faction rule exists precisely to stop that move).
- Settles it: nothing for the crop itself; generality settles only
  per faction, when each faction's own reference crop is measured
  (the standard already requires this before S6/S10 bind a faction
  numerically).

C22. S7 invisible-grain cap: grain with local contrast at or under
8 luma levels is invisible at the battle camera, at any feature
size.
- Lives in: issue 188 clause S7.
- Provenance: ASSUMED. Evidence: labelled an INFERRED cap, from the
  blind leg; the stated logic is relational (below S3's 12 step, so
  grain can never pose as a plate step). The 8 itself is unmeasured,
  and it inherits C18: if 12 is wrong, the cap's rationale moves.
- If wrong: too generous, and high-frequency contrast under the
  cap fizzes across every surface at battle distance (round 5
  mechanism 3) while passing the clause; too strict, and texture
  work is flattened that the close band wanted.
- Settles it: a grain-contrast ladder on one plate at battle
  distance (contrast steps around 4, 6, 8, 10, 12 luma at sub-unit
  feature size): rides the C18 script build, one extra render run,
  judged on the same owner sheet round.

C23. S7 structural-grain floor: visible grain features at least 1
unit across are treated as zones under S2 and S4.
- Lives in: issue 188 clause S7.
- Provenance: ASSUMED. Evidence: the rule's third leg (between the
  C22 invisible end and the banned dead band), stated without a
  measurement. It is also in visible tension with S2: a zone
  carrying its own tone must be at least 2 units (C16), and S2's
  own logic says a 1-unit zone is erased by the test blur; a
  1-unit "structural" grain feature is therefore a zone that
  cannot carry tone and cannot survive the test, which leaves its
  legal status unclear in a way a builder will hit immediately.
- If wrong: builders either model 1-unit features that the sign-off
  test cannot see (wasted geometry, D5's complaint) or are failed
  for grain the standard elsewhere allows.
- Settles it: a chair ruling reconciling S7 with S2 (one sentence:
  either structural grain starts at 2 units, or 1-unit features are
  named as texture-only), zero build cost; optionally confirmed on
  the C22 ladder sheet.

C24. S8 trim cap: the faction trim accent covers at most 2 percent
of the battle crop.
- Lives in: issue 188 clause S8; issue 200 D12 and D15 (trim on
  detail elements and glow count against the same cap).
- Provenance: DERIVED. Evidence: the standard labels it derived
  from the reference measure (0.97 percent red trim, C25) and sets
  the cap at about double the measured share. The doubling is a
  judgment; the measure under it is real.
- If wrong: too tight, and factions whose identity is accent-led
  (Eclipse's corona is directed to be "a full value event", spent
  on a few large features) collide with a cap written for
  Hullbreaker red; too loose, and trim becomes a second base tone,
  the failure S8 exists to prevent.
- Settles it: a trim-share ladder on the C20 pattern (one hull,
  trim at about 1, 2, 3.5, 5 percent), judged with the rust ladder
  in the same owner round; the per-faction question (one cap for
  all factions, or per-faction caps like S10) is an owner pick the
  ladder informs.

C25. S8 trim working target: about 1 percent of the battle crop.
- Lives in: issue 188 clause S8.
- Provenance: MEASURED. Evidence: the reference crop's own red trim
  measures 0.97 percent; the standard also records that round 5's
  0.53 and 0.52 percent still registered, so the target is a
  description of the reference, not a visibility threshold. As
  with C21, the measurement is real and its portability is the
  question.
- If wrong: treated as a floor or a target for other factions, it
  spends accent where a faction's reference would not.
- Settles it: per-faction reference measures, as C21.

C26. S9 recess drop: a recess sits at least 12 luma levels below
its surrounding plate; there is no maximum drop.
- Lives in: issue 188 clause S9; issue 200 D7 and D8 (a recess
  meeting S9 breaks a plain region), D16 (recesses re-verified by
  measurement after a detail pass).
- Provenance: DERIVED. Evidence: set equal to S3's neighbour step
  ("same step as S3"), so its provenance is C18's ASSUMED carried
  through an equality; the no-maximum half is a ruling (a proposed
  40-level cap was rejected because R103 specifies dark recesses).
  Note the asymmetry the red team should price: the floor is a
  borrowed number, the missing ceiling is a deliberate decision.
- If wrong: if 12 is too small for a shadowed recess to read at
  battle distance, D7 and D8 credit regions as "broken" by recesses
  nobody can see, and plain faces pass on paper.
- Settles it: the C18 ladder sheet, with recess pairs added at the
  same steps (same script build, same owner round).

C27. S10 target tolerance: a candidate's battle-crop median luma
within 5 levels of its own faction's reference passes the target.
- Lives in: issue 188 clause S10; issue 200 D16 (the guard re-run
  after any detail pass).
- Provenance: ASSUMED. Evidence: labelled "INFERRED tolerances,
  chair judgment". No measurement in the record maps a median-luma
  distance to a visible difference on a whole hull.
- If wrong: too tight, and normal paint variation between hulls of
  one faction fails sign-off and burns builder runs; too loose,
  and the round 6 failure (both hulls "nearly all black", R108)
  passes the number while failing the eye. Note D16 makes this
  tolerance a hard gate on every detail pass.
- Settles it: a median ladder is not directly renderable (median
  is a whole-crop statistic), but the existing round sheets already
  contain passes and fails at known distances (reference 30.07;
  V1 +11.56 and V2 +14.19 both failed, section 2.3); the first
  hull to pass S10 at a recorded distance starts calibrating the
  band. Cost: bookkeeping only, if distances are printed on every
  sheet from now on (one script change).

C28. S10 fail line: median luma outside 10 levels of the faction
reference fails.
- Lives in: issue 188 clause S10.
- Provenance: ASSUMED. Evidence: same labelling as C27. The only
  observed failures sit at +11.56 and +14.19, just past the line;
  no observed candidate sits between 5 and 11, so both the target
  band and the fail line are untested in the interval where they
  would actually discriminate.
- If wrong: the line is currently a verdict in search of evidence;
  a good hull at +10.5 fails and a dull one at +9.5 passes, with no
  record either way.
- Settles it: same bookkeeping as C27, plus one deliberate
  near-line candidate when the next hull is painted (no extra run:
  record the distance on a variant that lands near the line).

C29. Pyre reference median luma: 30.07.
- Lives in: issue 188 clause S10 (the Hullbreaker anchor).
- Provenance: MEASURED. Evidence: classifier measure on the
  reference crop. As with C21 and C25, a real measurement of one
  crop; the standard correctly refuses to universalise it (a
  universal 25 to 35 window was proposed by a leg and rejected
  because it would fail the Glasswrights' shipped crystal white
  hull on sight).
- If wrong: it is not wrong about the crop; the risk is only in
  reuse, which S10's per-faction structure already guards.
- Settles it: per-faction reference crops, as C21.

C30. Colour classifier pass tolerances: colour bins within 10
percentage points of the reference; brightness within 11 to 14
levels.
- Lives in: the round 5 classifier, described in issue 188 section
  1; still run in the binding test (issue 188 section 3, step 4:
  "the round 5 classifier measures").
- Provenance: ASSUMED. Evidence: legacy settings from the round 5
  pipeline, carried into the standard's test procedure without a
  derivation in the record. The standard itself records their
  known failure mode: both round 5 hulls passed them (all bins
  within tolerance) while the owner rejected the paint on sight;
  the standard demotes them to "a calibration check, not an
  approval", but they still run inside the binding test's step 4,
  where a future reader can mistake a pass for a pass.
- If wrong: mostly a labelling hazard now; the cost is one
  confused review round per new builder who reads the test
  procedure without section 1's warning.
- Settles it: a chair edit either removing the tolerances from the
  test procedure or labelling them in place as calibration-only
  (zero build cost); the tolerances themselves need no defence
  once they gate nothing.

C31. Battle crop radius: r = 170 units.
- Lives in: issue 188 sections 2 and 3 (judgement crop); issue 200
  sections 2 and 3 (the binding crop); the round pipeline's camera
  anchors.
- Provenance: ASSUMED. Evidence: the packs call the camera anchors
  "derived", but what is derived is the px-per-unit scale (C65)
  from the radius and the resolution; the 170 itself is the
  standing judgement distance inherited from the round pipeline,
  and no document in the record traces it to a measured in-game
  battle camera distance or tests the standard at any other radius.
- If wrong: every px-denominated clause in both standards (C16,
  C37, C42, C45, and the test itself) is calibrated to a camera the
  game may not use; if real battles sit closer or further, floors
  and maxima are all shifted by the same factor and no single
  clause looks wrong on its own.
- Settles it: one in-game capture set at the real battle camera
  (the C16 comparison covers this), and if the real distance
  differs, a one-time rescale of the px conversions (the unit
  clauses survive unchanged; only their px readings move).

C32. Capture resolutions: 1920x1080 binding; 3840x2160 kept as the
4K record.
- Lives in: issue 188 section 3, step 1, and Q1 (1080p binds,
  ruled R105).
- Provenance: ASSUMED. Evidence: the chair's stated reason is that
  the round 5 captures and the review sheets are 1920x1080 and a
  plate passing at 1080p passes at 4K automatically. The logic is
  sound and the premise is circular in a way worth naming: the
  standard binds at the resolution the pipeline already produces,
  so the pipeline's habit is doing quiet work in the standard.
- If wrong: if the game is ever judged (by players or reviewers)
  primarily at 4K, sub-floor content the 1080p standard legalises
  becomes visible speckle with a paperwork defence.
- Settles it: one 4K judgement pass on an already-passed hull when
  a 4K sheet exists anyway (round 6 already captures 4K records);
  one owner review round, no new build.

C33. The nine-cell sweep: 9 cells (bow, midship, stern, each from
top, side, and below), each judged clean or rebuild by hand.
- Lives in: the ship pipeline's standing sheet (round 4 and round
  6 READMEs); issue 188 S12; issue 200 sections 2 and 3.
- Provenance: ASSUMED (instrument design). Evidence: a stable
  convention across rounds; no document argues 9 cells over 6 or
  12, or these three viewpoints over others. Its fractions (C34,
  C35) do heavy work in two standards.
- If wrong: the grid decides where scrutiny lands; a defect class
  that lives between cells (the round 6 V3 bow cells are the
  standing example of cells that keep failing) is priced by the
  grid, not by the hull.
- Settles it: nothing cheap; the grid is a review instrument, and
  the honest settlement is the C34/C35 reconciliation (which bar,
  counted how), not a new grid.

C34. Sign-off bar: 7 of 9 clean cells (S12 for paint; issue 200's
verdict rule applies the same bar to detail sign-off).
- Lives in: issue 188 clause S12 and Q5 (chair pick: yes, adopted
  R105); issue 200 section 3, verdict rule (ii) (the extension to
  detail is labelled INFERRED there).
- Provenance: ANCHORED. Evidence: the standard states the basis
  plainly: "V3's seven of nine clean cells is the only observed
  pass point", and no paint rescued a 0 of 9 hull in five rounds.
  The bar is set at the incumbent's score. No hull has ever scored
  8 or 9, so the bar's headroom, and whether 7 is a quality
  threshold or a description of V3, is untested. Issue 188's own
  Not checked adds: the bar "is calibrated on the barge alone".
- If wrong: if V3 is merely the best of a bad field, 7 of 9
  certifies mediocrity fleet-wide and every future hull is built
  to clear V3 rather than to read well; if the true readability
  threshold is higher, paint sign-off keeps blessing geometry
  failures (S12's own stated fear, one notch up).
- Settles it: correlation, over time: record each hull's cell score
  beside its blur-test result and the owner's verdict (bookkeeping
  on existing sheets). The first hull to score 8 or 9, or to read
  well at 6, reprices the bar with evidence. Zero build cost;
  costs patience.

C35. The pipeline's full nine-cell shipping gate: 9 of 9.
- Lives in: round 6 README ("the latest standard's seven-cell
  paint sign-off floor does not waive the pipeline's full
  nine-cell shipping gate").
- Provenance: ASSUMED. Evidence: a pipeline gate stated in a build
  README; no document in either standard reconciles it with C34.
  Two bars over the same grid coexist: a hull at 7 or 8 of 9 can
  hold paint sign-off and still not ship, and neither standard
  says which bar a builder is building to.
- If wrong: builders optimise for the bar they were last quoted;
  review rounds burn on the gap between the two (the round 6 V3
  sits exactly in it: 7 of 9, sign-off floor met, shipping gate
  unmet, two bow cells named for rebuild).
- Settles it: one chair or owner sentence naming the relationship
  (for example: 7 of 9 signs off paint, 9 of 9 ships, and the
  rebuild list for the missing cells is part of the sign-off
  sheet). Zero build cost.

C36. Two-hull sequencing threshold: close-range paint clauses are
written only after two hulls pass the battle-distance test (R105
sequencing); issue 200's plain-area maxima recalibrate after the
first two hulls pass (Q2 ruling).
- Lives in: issue 188 Q4 and S11; issue 200 D-sequencing note and
  section 7, Q2.
- Provenance: ASSUMED. Evidence: a sequencing judgment ("close-band
  numbers written before any hull has passed the battle test would
  be guesses stacked on guesses"); the count of two is unargued in
  the record. One hull would prove a recipe; two proves it
  transfers, presumably, but the record does not say so.
- If wrong: at two, low cost either way; the risk is the pattern,
  small round numbers hardening into doctrine (compare C11).
- Settles it: nothing to measure; an owner or chair note stating
  the reason for two, so a future reader can tell doctrine from
  arithmetic. Zero build cost.

### C. The detail standard (issue 200, D1 to D25)

C37. D2 battle-band shape floor: a mesh feature counts as shape at
the battle band only at 2 units or larger (largest dimension);
station additions count by proud height, at least 2 units proud of
their surface.
- Lives in: issue 200 clause D2 (station form per the issue 172
  additions doctrine).
- Provenance: DERIVED. Evidence: set equal to the S2 plate floor
  (C16) and carries its derivation (15 px at the battle camera);
  the station proud-height form is the same number read in the
  other axis.
- If wrong: inherits C16's exposure entirely; additionally, a
  largest-dimension rule prices long thin features (gun barrels,
  masts) as shape at lengths where their width is sub-floor, which
  the clause's own catalogue includes.
- Settles it: the C16 in-game comparison; the thin-feature question
  settles on the same sheets by inspection.

C38. D3 secondary band: features of 1 to 2 units are secondary read
at the battle band; alone, they do not break a plain region.
- Lives in: issue 200 clause D3.
- Provenance: ASSUMED. Evidence: the band edges are inherited (C37
  above, the 1-unit line below), but the functional claim is
  labelled INFERRED in the clause: "a 7.5 to 15 px element does not
  change how a large face reads at r = 170" (blind leg). No sheet
  in the record isolates a 1 to 2 unit element's effect on a face.
- If wrong: if a lone 12 px element does break a face's read (a
  hatch ring on a bare plate is the plausible case), D7's breaker
  list undercounts and plain faces fail that should pass; if it
  never does, builders still spend parts there that D10 then
  regulates as clusters.
- Settles it: one A/B sheet pair (same face, with and without a
  lone secondary feature), judged in the C18 owner round; one
  render run on an existing hull.

C39. D4 close-band mesh floor, ships: mesh detail is legal from 0.5
units up (about 14 px at the 46-unit zoom, about 21 px at the
30-unit zoom).
- Lives in: issue 200 clause D4.
- Provenance: DERIVED. Evidence: the synthesis shows the px
  arithmetic from the camera anchors and calls the 0.5 to 1 unit
  ship band "an INFERRED extension proposed by the blind leg and
  adopted by the chair", resting on the pack's derivation that
  0.5-unit geometry is fully legible at the judged close zooms.
  The number is derived; the extension of mesh (rather than trim
  or normal content) into that band is the judgement inside it.
- If wrong: if 0.5-unit mesh does not read even at the 30-unit
  zoom in the real renderer (lighting, AA, and motion all differ
  from the studio captures), hulls accumulate invisible geometry
  that D18 then rations as if it were visible.
- Settles it: one close capture from the actual game build at the
  judged zooms beside the studio capture (rides the C16
  comparison; no separate run).

C40. D4 station close band: mesh detail lives in the 1 to 2 unit
band; below 1 unit is trim sheet and normal content.
- Lives in: issue 200 clause D4 (issue 172 language, binding
  unchanged for stations).
- Provenance: ASSUMED. Evidence: carried from the station brief
  without derivation, and asymmetric with the ship rule (C39: 0.5
  units) for no reason stated in the record. The two judgement sets
  use the same close zooms (C62), so the asymmetry is not explained
  by the cameras.
- If wrong: stations are denied a half-unit of legal mesh detail
  that ships get at the same zoom, or ships are legalising waste
  that stations correctly refuse; one of the two rules is
  mispriced, and builders working both asset classes carry both.
- Settles it: a chair ruling aligning the two floors or stating
  the reason for the difference (zero build cost), optionally
  evidenced by the C39 game capture, where a station and a ship
  share the frame at the docked-scale captures.

C41. D5 never-model floor: no mesh below 0.5 units anywhere on a
hull or a station.
- Lives in: issue 200 clause D5 (pack read rule: wasted geometry).
- Provenance: DERIVED. Evidence: the floor of C39's derivation,
  applied universally. Note it binds stations at 0.5 while C40
  already confines station mesh to 1 unit and up, so for stations
  the binding floor is C40's and C41 is redundant there; for ships
  it is the only sub-floor rule.
- If wrong: as a waste rule it is cheap insurance; the failure
  mode is auditing cost (the sub-floor audit is a mesh statistic
  from the one-time script build, per issue 200 section 3), spent
  hunting geometry that costs nothing at the measured throughputs
  (section 2.2).
- Settles it: nothing needed unless a builder is failed on it; the
  red team may reasonably price whether a waste rule denominated
  in size, on a project whose measured problem is not triangle
  count, earns its audit.

C42. D7 plain-area maxima, battle band: on any face, no unbroken
flat region may exceed 6 units in any direction or 36 sq units in
area, measured on the battle crop (45 px run; 36 sq units = 2,025
sq px).
- Lives in: issue 200 clause D7; ruled standing in section 7, Q2,
  with recalibration after the first two hulls pass (C36).
- Provenance: ASSUMED. Evidence: labelled INFERRED in the clause;
  the figures are the DeepSeek leg's, adopted by the chair over
  the blind leg's looser 10 units and 100 sq units, "because R109's
  complaint is precisely that large faces read plain". The ruling
  direction (tighter, because the complaint was plainness) is
  reasoned; the values 6 and 36 are one leg's proposal with no
  sheet behind them. No hull has yet been measured against D7
  (issue 200 section 6).
- If wrong: too tight, and every large face (a carrier deck, a
  station spine) must be interrupted at 6-unit intervals whether
  or not it reads plain, spending detail and D10 cluster budget on
  a metronome; too loose, and R109's "regular shapes" read survives
  inside the standard that was written to kill it.
- Settles it: the promised recalibration, made real: judge the
  first two hulls' sheets with the largest unbroken regions marked
  at both 6/36 and 10/100, and let the owner's eye pick the line
  (one script annotation on the existing measurement build, owner
  judgement inside an already-scheduled review round).

C43. D8 plain-area maxima, close band: on any primary face, no
unbroken flat region may exceed 3 units in any direction or 9 sq
units, measured on close captures and nine-cell renders.
- Lives in: issue 200 clause D8; ruled standing with C42.
- Provenance: ASSUMED. Evidence: labelled INFERRED; again the
  DeepSeek leg's figures over the blind leg's 4 units and 16 sq
  units. Compounds C42's status, and adds one of its own: the ship
  nine-cell renders' camera scale is not stated in any source
  (issue 200 section 6), so the ship-side px conversions for this
  clause inherit an inference the station side does not have.
- If wrong: as C42, one band closer; a too-tight close maximum is
  the direct cause of the round 5 clutter failure if it forces
  interruption density the paint cannot support (D13's warning
  runs both ways).
- Settles it: the C42 recalibration covers both bands if the close
  captures are annotated the same way (same script build).

C44. D8 relief floor: a recess breaks a close-band region only if
its relief is at least 0.5 units proud or deep.
- Lives in: issue 200 clause D8 (parenthetical).
- Provenance: ASSUMED. Evidence: labelled INFERRED (blind leg);
  the synthesis concedes the verification problem in its own check
  section: "relief reads on a sheet only at grazing angles; verify
  by mesh measurement". The clause therefore runs on a mesh
  statistic, not on the sheets the owner judges by.
- If wrong: small either way; the cost is a mesh-check line item
  and occasional disputes a sheet cannot settle.
- Settles it: the one-time mesh-analysis script build already
  specified in issue 200 section 3 prices it per hull at an
  unattended run; no separate settlement needed.

C45. D9 noise gap: at the battle band, elements closer than 4
units edge to edge read as noise (4 units = 30 px); elements inside
4 units are legal only as one composed cluster.
- Lives in: issue 200 clause D9.
- Provenance: ASSUMED. Evidence: stated as a "pack read rule" with
  no measurement or derivation cited in the pack or the synthesis.
  It is one of the stack's most load-bearing perceptual claims: it
  sets the density ceiling (C46), legitimises the cluster system
  (C47 to C52), and defines the clutter boundary the whole detail
  standard patrols.
- If wrong: if composed groups at 3-unit gaps still read as noise,
  the cluster system legalises the round 5 failure in geometry; if
  elements at 2 to 3 units read fine uncomposed, the rule forbids
  ordinary fittings layouts and forces cluster theatre (shared base
  plates added to satisfy a definition).
- Settles it: a spacing ladder on one face (identical elements at
  gaps of 1, 2, 3, 4, 6 units, uncomposed, battle crop, blurred
  and unblurred): one script build shared with C18, one render run,
  judged in the same owner round.

C46. Density ceiling (derived from D9): minimum pitch is 2 + 4 = 6
units, so at most one shape feature or cluster per 36 sq units of
face at the battle band.
- Lives in: issue 200 clause D9 (final sentence).
- Provenance: DERIVED. Evidence: the arithmetic is shown in the
  clause and is correct; it inherits C37 and C45 in full, so its
  certainty is exactly the noise gap's. It is the cleanest example
  in the stack of a derived number whose provenance is one assumed
  parent.
- If wrong: it fails exactly as C45 fails, with the extra cost
  that a computed ceiling feels more settled than a stated one and
  is less likely to be questioned in review.
- Settles it: C45's ladder, read at the cluster scale.

C47. D10 battle density floor: at least one detail cluster per 100
sq units of face, a cluster being 3 to 8 elements (C48).
- Lives in: issue 200 clause D10.
- Provenance: ASSUMED. Evidence: labelled INFERRED (DeepSeek leg).
  Read against C46, the legal density band at the battle band is
  between 1 cluster per 100 sq units and 1 per 36: a factor of
  about 2.8 between floor and ceiling, set by two different legs'
  proposals adopted into adjacent clauses, with no sheet testing
  either edge.
- If wrong: too high a floor and quiet hull designs (Eclipse's
  smooth archival aesthetic, per issue 188 section 4) are failed
  for restraint; combined with C42's maxima, the floor and the
  plain-area rule can jointly mandate a density the faction's art
  direction refuses.
- Settles it: the C42 recalibration sheets, with cluster density
  printed per face; the owner's pass/fail on the same hulls prices
  the floor as a by-product. No separate run.

C48. D10 cluster composition: a cluster is 3 to 8 elements, each at
least 2 units across.
- Lives in: issue 200 clause D10.
- Provenance: ASSUMED. Evidence: counts labelled within the
  INFERRED D10; the element size inherits C37. Neither 3 nor 8 is
  argued in the record; the composition test they serve (sharing a
  mount, a base plate, or one construction edge) is itself marked
  INFERRED in D9.
- If wrong: mostly bookkeeping risk; a 2-element group that reads
  as one form fails the definition, and a 9-element group must be
  split on paper. Costs land in review friction, not in the look.
- Settles it: chair discretion at recalibration (C42); flag any
  cluster dispute from the first two hulls and price the counts
  from real cases.

C49. D10 close density floor: at least one detail element of 0.5
units or larger per 25 sq units of face.
- Lives in: issue 200 clause D10.
- Provenance: ASSUMED. Evidence: labelled INFERRED. The 25 sq units
  figure has no stated relation to C43's 9 sq unit maximum plain
  area (a face exactly at the plain maximum would need an element
  every 25 sq units, which the maximum already forces sooner), so
  the floor may be redundant with C43, binding only through the
  cluster-anchoring rule.
- If wrong: redundancy is the benign case; the malign case is two
  near-duplicate rules disagreeing at an edge and a builder
  satisfying the wrong one.
- Settles it: the chair's recalibration pass (C42) can test
  redundancy directly from the first hulls' mesh statistics: if
  C43 compliance implies C49 compliance on both hulls, the floor
  is a note, not a clause. Bookkeeping cost only.

C50. D10 inside-cluster spacing: minimum edge-to-edge spacing 0.5
units inside a composed cluster (about 21 px at the 30-unit zoom).
- Lives in: issue 200 clause D10.
- Provenance: ASSUMED. Evidence: labelled INFERRED, with the px
  rationale stated; the claim underneath (that elements closer
  than about 21 px merge into grain at the closest judged zoom) is
  unmeasured, and sits one step from C22's grain logic without
  citing it.
- If wrong: cosmetic either way at current scales; merged elements
  read as one bigger element, which the standard elsewhere accepts.
- Settles it: inspectable on any existing close capture; no run
  needed unless a dispute arises.

C51. D10 uncomposed close spacing: uncomposed elements keep at
least 2 units spacing at the close band.
- Lives in: issue 200 clause D10.
- Provenance: ASSUMED. Evidence: part of the INFERRED cluster
  discipline; note it equals C37's shape floor numerically, which
  may be a deliberate rhyme or a borrowed number; the record does
  not say.
- If wrong: as C50, review friction more than look.
- Settles it: as C48, priced from real disputes at recalibration.

C52. D10 fine-cluster coverage cap: fine clusters cover at most 30
percent of any single face.
- Lives in: issue 200 clause D10.
- Provenance: ASSUMED. Evidence: labelled INFERRED; the synthesis
  concedes the exact figure is a mesh statistic, not a sheet
  judgement (section 3 splits it: sheet estimate for sign-off,
  mesh figure for the clause). A cap the owner cannot see on the
  sheet he signs is enforced by a script he does not run, which is
  an agent-lead cost regardless of the number's merit.
- If wrong: too low, and rich close-band faces (the hero variant's
  selling point, C54) are flattened; too high, and the S2/S3 paint
  zones lose the clean plate the clause exists to protect.
- Settles it: print the mesh coverage figure on the sign-off sheet
  for the first two hulls (the script build exists in the check
  spec) and let the recalibration set the cap from seen values.

C53. D12 sub-floor tone rule: an element under 2 units across may
not carry its own tone at the battle band; trim carried on detail
elements counts toward the S8 cap.
- Lives in: issue 200 clause D12.
- Provenance: DERIVED. Evidence: a direct application of S2's floor
  (C16) and S8's cap (C24) to detail elements; no new number is
  introduced. Its provenance is exactly its parents'.
- If wrong: only as its parents are wrong.
- Settles it: nothing separate.

C54. D18 detail share caps: close-band-only detail (features under
2 units) may take at most 25 percent of a hull's triangle budget on
fleet-default hulls and at most 40 percent on hero hulls.
- Lives in: issue 200 clause D18; ruled standing Nov 5, 2026 (Q4)
  and explicitly left standing by the Nov 6 correction (section 8:
  Q2 to Q5 rulings stand).
- Provenance: ASSUMED. Evidence: the shares are labelled INFERRED
  (blind leg). The deeper problem is the unit: the cap is a share
  of a triangle budget, set three days before the ceiling test
  established that triangle count does not predict GPU time in the
  measured series and the owner withdrew triangle caps for
  exactly that reason; D18 survived the correction because it was
  a Q-ruling, not because its denomination was re-examined. The
  clause's stated purpose is not really frame cost: it is that
  close detail "eats the D17 break-kit room and the fleet reserve
  while buying nothing at the battle camera", which is an argument
  about build effort and asset composition, denominated in the one
  unit the project just retired.
- If wrong: if the share binds in tris, builders hit it by
  spending triangles the hardware does not charge for, and strip
  close detail that costs nothing measurable; if the real scarcity
  is builder iterations or break-kit complexity, the cap measures
  neither and the scarcity stays unpriced.
- Settles it: an owner ruling on what the share is actually
  rationing (frame cost, build effort, or break-kit room), then
  re-denomination: under the scene gate, a share of the hull's
  measured ms is available from the C3 benchmark at no extra run;
  a share of build runs is bookkeeping. Zero to one run, plus the
  ruling.

C55. D22 break-line clearance: mounted detail keeps at least 1 unit
clear of a break line, on both sides; rim bands carry no mounted
detail, trim, or decals (one exception: station truss and gantry
damage decals, R100).
- Lives in: issue 200 clause D22; ruled Nov 5, 2026 (Q5, chair pick
  over a leg's 2 units).
- Provenance: ASSUMED. Evidence: the distance is labelled INFERRED
  (blind leg). The chair's pick was argued on derived arithmetic:
  on the 41.6-unit Pyre-Barge with two transverse lines, 1 unit
  sterilises 4 units of hull length (about 10 percent) against
  2 units' 8 (about 19 percent), before the longitudinal band. The
  cost side is derived; the benefit side (how much clearance the
  hot-edge read and the damage masks need) is unmeasured, so the
  pick priced the cost of the rule and assumed its benefit.
- If wrong: too small, and detail crowds the break read the
  clearance exists to protect (R98: broken pieces must never look
  empty, and the break moment is the worst place for clutter);
  too large, and midship cells (already the plainest, per the Q5
  record) lose a fifth of their length to a sterile band.
- Settles it: one break-test render on an existing hull at both
  clearances during the breakable-Barge job (issue 169, already
  queued behind the round 7 pick): the broken-state sheets judge
  it at no extra build, one owner look inside an existing round.

C56. Break lines per hull: two or three authored lines per hull
(R98); capital hulls break on two transverse lines plus one
longitudinal line (R99).
- Lives in: issue 200 clause D21 (restating R98/R99).
- Provenance: ASSUMED. Evidence: ruled design counts from the
  breakable-ships research, adopted as rulings; no structural or
  performance measurement derives 2, 3, or the capital pattern.
  These are design rules, and are priced as such: their defence is
  gameplay and read, not cost.
- If wrong: too few lines and capital break-ups read coarse; too
  many and the break kit (interiors, rim bands, liners under D17's
  all-in counting) multiplies build and audit surface per hull.
- Settles it: the breakable-Barge job (issue 169) is the first
  full test of the capital pattern; its sheets are the settlement
  instrument, already queued.

C57. Chorus break composition: the first Chorus hull gets bone ribs
and membranes throughout plus one flesh mass per break piece
(R99 Q4).
- Lives in: FINDINGS R99 Q4; issue 200 clause D25 (the Chorus
  reading of the detail clauses).
- Provenance: ASSUMED. Evidence: a ruled starting composition
  whose ruling text ends "then measure"; no Chorus hull has been
  built or measured yet, and D25's organic reading of the plain-area
  and cluster clauses (bone ribs, flesh folds, growth rings as
  breaking features) is labelled an INFERRED application.
- If wrong: the count of one flesh mass is a guess at an organic
  read no one has seen; the wider risk is D25 itself: area and
  density clauses written for plated hulls may not survive contact
  with a grown one, and the first Chorus hull will be judged by
  them anyway.
- Settles it: the first Chorus hull build, which the ruling already
  schedules as the measurement; the red team's ask is that its
  sheet record which D-clauses were waived or bent, so the waiver
  list becomes the Chorus amendment (bookkeeping on an existing
  job).

C58. D11 outline count: in each cell of the top row and each cell
of the side row of the nine-cell sweep, at least one mounted or
outline feature must punctuate the silhouette or major outline.
- Lives in: issue 200 clause D11 (from R108).
- Provenance: ASSUMED. Evidence: the direction is ruled (R108: V3
  read as a long box for lack of outline features; round 7 adds
  them back). The per-cell count of one is the standard's
  formulation: a leg's alternative (at least 30 percent of
  battle-band clusters being outline features) was considered and
  rejected for double bookkeeping, not on evidence.
- If wrong: one feature per cell is a low bar that a token dish
  can satisfy while the silhouette still reads plain; the clause
  can be passed by the letter on the exact failure it was written
  against.
- Settles it: round 7 (issue 198, in flight) is the live test: its
  sheets show V3 with the outline catalogue restored, judged by
  the owner; if the long-box read persists with D11 satisfied, the
  count or the clause form is wrong, and that is observable at no
  extra cost.

### D. Stations (R100 and the issue 172 brief, carried in issue 200)

C59. Station design target: about 20,000 tris and 0.35 ms per
station.
- Lives in: FINDINGS R100; issue 200 clause D20.
- Provenance: ASSUMED. Evidence: chair picks from the station
  detail brief (issue 172), adopted by the owner as R100. The
  blocking fact is in issue 200's own Not checked: "No measured
  triangle count exists for the current stations", so the target
  has never been compared with the thing it targets; D20's
  gap-spend rule (additions spend only the gap between the counted
  baseline and the target) cannot bite until a baseline is counted.
- If wrong: the station detail pass (issue 199, queued) is being
  scoped against a target with no baseline: if the current
  stations already exceed 20,000 tris, the pass is a reduction job
  mislabelled as an additions job; if they sit at 5,000, the target
  licenses a 4x growth nobody chose on evidence.
- Settles it: counting the current stations (the first Codex detail
  job already counts first, per D20): one unattended script run,
  and it should land before the detail pass is scoped, not inside
  it.

C60. Station hard ceiling: 40,000 to 45,000 tris and 1.0 ms per
station.
- Lives in: FINDINGS R100; issue 200 clause D20; left standing by
  the Nov 6 correction ("D20's station budget stands under R100").
- Provenance: ASSUMED. Evidence: same provenance as C59, with one
  addition: this is now the last hard triangle cap in the stack.
  Ship triangle caps were withdrawn on Nov 6, 2026 because
  triangles do not predict GPU time in the measured series; the
  station cap survived without its denomination being re-argued.
  Its ms half (1.0 ms) is at least in the unit the project now
  prices in, but it was set against the retired protocol, not
  against any station scene measurement.
- If wrong: a station programme capped in a retired unit will
  either be cut for no performance reason or waived so often the
  ceiling stops meaning anything, and both outcomes cost review
  rounds.
- Settles it: the C59 count plus one timing run of a station scene
  under the C3 benchmark when stations enter it (the ceiling
  synthesis lists baked lighting for stations as a benchmark
  follow-on); then an owner ruling re-denominating or retiring the
  tri half. One unattended run plus a ruling.

C61. Station break lines: two authored break lines per station
kind, at structural junctions.
- Lives in: issue 200 clause D21 (per the issue 172 brief).
- Provenance: ASSUMED. Evidence: brief language, parallel to the
  hull rule (C56) with its own count; stations get damage decals
  at break lines instead of interior faces (R100), so the count
  prices decal work, not interiors.
- If wrong: cheap either way relative to hulls; the count is a
  design rule and should be defended as one.
- Settles it: the station detail pass sheets (issue 199).

C62. Station judgement distances: battle angle at about 170 units;
close zooms at 46 and 30 units; 4K plan view (with a docked
battleship and frigate for scale).
- Lives in: issue 200 section 3 (the station judgement set, from
  the issue 172 brief).
- Provenance: ASSUMED. Evidence: brief-chosen distances; the px
  scales at the zooms (C65) are derived from them. The 46-unit
  figure also appears inside the station asset itself (the current
  station's spine is 46 units long, per issue 200 section 1), a
  coincidence the record does not remark on: whether the close
  zoom was chosen from the asset's size or independently is
  unstated, and if it was chosen from the asset, the judgement
  distance is anchored on the incumbent station exactly as C1 was
  anchored on the incumbent hull.
- If wrong: station detail is sized for cameras chosen around one
  station's dimensions; a larger or smaller station kind inherits
  zooms that frame it wrongly.
- Settles it: one line in the station brief record stating the
  zooms' basis (chair note, zero build cost); the zooms themselves
  are review conveniences and cheap to change per kind.

C63. Trim seam spacing: about 1.5 units (the spacing at which trim
seams sit, cited as trim content that does not break a close-band
region).
- Lives in: issue 200 clause D8 (per issue 172).
- Provenance: ASSUMED. Evidence: a brief figure used inside D8's
  reasoning ("seams at about 1.5-unit spacing are trim content");
  it does quiet definitional work: without it, a face seamed at
  1.5-unit intervals might argue it is broken every 1.5 units and
  pass C43 without any feature.
- If wrong: if production trim sheets land at a different spacing,
  D8's example stops matching the asset and the argument reopens
  per hull.
- Settles it: read the spacing off the first station detail build
  (issue 199) and correct the example to the built value
  (bookkeeping).

C64. Tall element counts (R100): the refinery gets no second tall
element in this pass (at most one); the fleet station's working
face gets no tall element (zero).
- Lives in: FINDINGS R100.
- Provenance: ASSUMED. Evidence: owner-adopted chair picks from the
  station shapes review; aesthetic judgements about silhouette,
  stated as counts. They are design rules and are honestly formed;
  they are in the inventory because counts are what this red team
  audits, and because "in this pass" makes the refinery's one a
  deferred decision, not a settled one (R100: a one-part follow-up
  if it still reads flat).
- If wrong: the failure mode is the inverse of the ceiling's: an
  under-build rule. If the refinery reads flat, the follow-up
  spends a second pass that a braver first pass would not need.
- Settles it: the station detail pass sheets, judged by the owner;
  the follow-up trigger ("if it still reads flat") is already the
  ruling's own words.

### E. Derived scales the other clauses stand on

C65. Px-per-unit scales: about 7.5 px per unit at 1080p at the
battle crop (r = 170); 15 px per unit at 4K; about 27.7 px per unit
at the 46-unit zoom; about 42.5 px per unit at the 30-unit zoom.
- Lives in: issue 188 section 2 (camera anchors); issue 200
  section 2 (scales, with the arithmetic shown: 7.5 x 170/46 and
  7.5 x 170/30).
- Provenance: DERIVED. Evidence: the arithmetic is correct and
  shown. Two inherited exposures: every scale descends from C31's
  r = 170, and the ship nine-cell renders' camera scale is not
  stated in any source (issue 200 section 6), so ship close-band
  conversions (C43, C50) are computed from station zooms and
  applied to ship renders whose scale is inferred, a gap the
  detail synthesis flags itself.
- If wrong: the unit clauses (floors, maxima in units) are
  unaffected; every px reading of them shifts. Reviews that argue
  in px (the sheet measurements in issue 200 section 3 are
  specified in px) would be arguing from a wrong ruler.
- Settles it: state the nine-cell render camera scale in the
  pipeline record (one line from the existing capture tooling) and
  re-derive the ship conversions; zero build cost, one script
  annotation.

## 4. Chair observations (hypotheses for the legs to test)

These are the chair's starting suspicions, recorded so the legs can
attack or confirm them. They are INFERRED, they are not findings,
and a leg that merely repeats them has done no work.

H1. The provenance tally is the headline: of 65 numeric constraints,
4 are MEASURED, 11 DERIVED, 6 ANCHORED, and 44 ASSUMED. Many of the
44 are honestly labelled INFERRED in the standards; the question is
not honesty but load: several assumed numbers (C18, C19, C42, C45)
gate sign-off today, while the only measured performance law (C3)
does not have its number yet.

H2. The Nov 6 correction retired triangle caps for ships but left
two triangle-denominated rules standing untouched: the D18 detail
shares (C54) and the station hard ceiling's tri half (C60). The
correction's logic (triangles do not predict GPU time in the
measured series) applies to both or to neither; the record shows
it was applied to neither because both were rulings, not because
their units were re-argued.

H3. Derived numbers inherit their weakest parent, and the stack
rarely says so: C46 (density ceiling) is arithmetic on C45 (an
assumed read rule); C26 (recess drop) is an equality with C18 (an
assumed step); C16 and C37 are sound derivations whose root is the
test's own blur (C17), which is calibrated to the floor it tests.

H4. Two bars over one grid (C34 at 7 of 9, C35 at 9 of 9) and two
close-band mesh floors over one judgement set (C39 at 0.5 units for
ships, C40 at 1 unit for stations) suggest the stack has accreted
parallel rules at seams between jobs (188 vs the pipeline, 172 vs
200) that no single document reconciles.

H5. The blur test's parameter is named "radius" in the standard and
recorded as "sigma" in the only implementation on record (round 6).
If those differ in effect, the standard's first full run may not
have run the standard's test (C17).

H6. Several settlements are nearly free and already scheduled: the
station baseline count rides the first detail job (C59), the
break-clearance test rides issue 169 (C55), the outline clause is
being tested by round 7 in flight (C58), and the luma ladders
(C18, C19, C22, C26) share one script build. The expensive
assumptions are mostly expensive because nobody has yet put their
settlement on a sheet that was already being rendered.

## 5. Limitations: what this red team cannot settle from documents

1. Whether anything binds performance in a real battle. Every ms
   figure in the record comes from the isolated protocol scene
   (C8). The issue 207 benchmark has not run; until it does, the
   scene gate (C3) has no number and no leg can price a performance
   constraint against a real frame.
2. The contents of gpu.json. The ceiling synthesis names what it
   retains (draw calls per variant, single-ship GPU ms, empty-scene
   figures, render CPU ms) and states it was not opened. Every
   claim in the record about draw or surface structure binding is
   inference from the throughput table until that file is pulled.
3. Any perceptual threshold. S3's steps (C18, C19), the grain band
   (C22), the noise gap (C45), and the plain-area maxima (C42, C43)
   are claims about what an eye does at a specific camera. No
   document settles them; each needs a ladder sheet or an A/B build
   (priced per entry in section 3) and the owner's judgement.
4. Whether the studio instruments match the game. The blur test,
   the nine-cell sweep, and the station judgement set are studio
   constructs; the round 6 README records that its art comparison
   used approximate camera and painted lighting with exposure and
   histograms unmatched. In-game captures at the real battle camera
   do not exist in the record.
5. Faction generality. The paint numbers are anchored on one
   Hullbreaker reference crop (C21, C25, C29); no other faction has
   a measured reference, no Chorus hull has tested D25 or C57, and
   no hull of any faction has been measured against D7 or D8.
   Documents cannot extend a measurement to factions it was never
   taken on.
6. Station baselines. No counted triangle figure exists for the
   current stations (C59), so the station target and ceiling
   cannot even be compared with their subject yet.
7. Variance. Single-session figures carry about 7 percent of
   session movement on the anchor asset (C2). Any cap or gate
   tighter than the variance band cannot be validated from the
   existing series, however the documents argue.
8. MSAA and shadow sensitivity. The isolation runs that would price
   C6 (MSAA 2x and off, shadows off) are named in the ceiling
   synthesis and have not run.
9. This pack's own basis. The pack is built from syntheses and
   build READMEs, not from raw captures or meshes: no sheet was
   re-rendered and no mesh was measured for this job. A leg that
   needs a fact the syntheses do not carry must write NOT IN PACK
   rather than supply it.

## 6. Leg prompts

Four legs. The three writer legs (blind Rey, DeepSeek, Qwen) run
from this pack alone, in parallel, without seeing each other. The
Argon leg runs after them, as a review leg only. The chair screens
every leg before anything is adopted, per the standing four-prong
rule.

The lenses, named by the owner and used identically in every writer
leg:

- Game dev lens: does this number bind real performance or
  gameplay? Is it denominated in the metric the engine actually
  charges for? What happens in a real battle, not the protocol
  scene?
- Graphics designer lens: does this number bind the look,
  readability, or art direction? Is the aesthetic cost real, and
  who pays it: the palette, the faction identity, the silhouette?
- Agent lead lens: can the build pipeline actually produce work
  against this number and measure the result? Is it enforceable in
  a review, on a sheet the owner judges, or does it need a mesh
  statistic nobody runs? Does it waste runs: rebuilds, re-reviews,
  adjudication per hull?

Cost units, the only ones permitted: Codex runs (one-hour cap per
run), Opus runs, one-time script builds, per-hull unattended runs,
owner review rounds. State one-time and recurring costs separately.

---

### Blind Rey leg (writer)

You are a blind reviewer on a game project's graphical standards.
One file is your complete evidence and your complete instruction:
PACK.md, the evidence pack for a red team of the graphical
standards of the game Embers of the Hollow Sun. You have no other
sources. Do not browse, do not use outside knowledge of this project
beyond what the pack contains, and do not invent facts the pack does
not hold.

Task: answer the question in PACK section 1.3 for the constraint
inventory in PACK section 3 (C1 to C65), in light of the worked
example in PACK section 1.2 and the limitations in PACK section 5.
The chair's observations in PACK section 4 are hypotheses to test,
not conclusions to repeat.

Produce one report with exactly these parts:

1. Verdict: one of THE STACK HOLDS, THE STACK HOLDS ONLY WITH
   REPLACEMENTS, or THE STACK DOES NOT HOLD, applied to the
   standards stack as a whole, followed by the three constraints
   your verdict most depends on, named by C-number. A verdict of
   THE STACK HOLDS must state what evidence, if it appeared, would
   change it.
2. Game dev lens: attack every inventory constraint, C1 to C65, in
   order, one entry per constraint: does it bind real performance
   or gameplay, is it denominated in what the engine charges for,
   and what does its being wrong cost in a real battle? An entry
   may be one line where the lens genuinely finds nothing; silence
   on a constraint counts as a miss and the review leg will flag
   it. Mark each entry OBSERVED (present in the pack; cite the pack
   section) or INFERRED (your reasoning; say what it rests on). If
   the pack lacks a fact you need, write NOT IN PACK.
3. Graphics designer lens: the same, C1 to C65 in order, for the
   look, readability, and art direction: which numbers buy real
   readability, which tax the palette, faction identity, or
   silhouette without buying any, and what each error costs on the
   sheet.
4. Agent lead lens: the same, C1 to C65 in order, for production:
   can the pipeline build to it, can a review measure it on the
   owner's sheets or does it hide in a mesh statistic, and where
   does it waste runs (rebuilds, re-reviews, per-hull adjudication)?
5. Disposition table: every constraint, C1 to C65, one row each:
   KEEP, RE-DERIVE, REPLACE, or DROP; for RE-DERIVE and REPLACE,
   the replacement approach and its cost in the pack's agent-term
   units only; for DROP, what replaces the protection the number
   was giving, or the statement that none is needed. A disposition
   that contradicts one of your own lens entries is an error.
6. Owner questions: at most three, each with your pick and one line
   on the stakes. Questions must be human-direction questions, not
   technical ones.
7. Not checked: what this report could not verify from the pack.

Hard constraints: no human-time estimates anywhere (no hours, days,
or weeks of human work); costs only in the units above. No invented
measurements, thresholds, or quotations. No em dashes. Plain ASCII.

---

### DeepSeek leg (writer)

You are a blind reviewer on a game project's graphical standards.
One file is your complete evidence and your complete instruction:
PACK.md, the evidence pack for a red team of the graphical
standards of the game Embers of the Hollow Sun. You have no other
sources. Do not browse, do not use outside knowledge of this project
beyond what the pack contains, and do not invent facts the pack does
not hold.

Task: answer the question in PACK section 1.3 for the constraint
inventory in PACK section 3 (C1 to C65), in light of the worked
example in PACK section 1.2 and the limitations in PACK section 5.
The chair's observations in PACK section 4 are hypotheses to test,
not conclusions to repeat.

Produce one report with exactly these parts:

1. Verdict: one of THE STACK HOLDS, THE STACK HOLDS ONLY WITH
   REPLACEMENTS, or THE STACK DOES NOT HOLD, applied to the
   standards stack as a whole, followed by the three constraints
   your verdict most depends on, named by C-number. A verdict of
   THE STACK HOLDS must state what evidence, if it appeared, would
   change it.
2. Game dev lens: attack every inventory constraint, C1 to C65, in
   order, one entry per constraint: does it bind real performance
   or gameplay, is it denominated in what the engine charges for,
   and what does its being wrong cost in a real battle? An entry
   may be one line where the lens genuinely finds nothing; silence
   on a constraint counts as a miss and the review leg will flag
   it. Mark each entry OBSERVED (present in the pack; cite the pack
   section) or INFERRED (your reasoning; say what it rests on). If
   the pack lacks a fact you need, write NOT IN PACK.
3. Graphics designer lens: the same, C1 to C65 in order, for the
   look, readability, and art direction: which numbers buy real
   readability, which tax the palette, faction identity, or
   silhouette without buying any, and what each error costs on the
   sheet.
4. Agent lead lens: the same, C1 to C65 in order, for production:
   can the pipeline build to it, can a review measure it on the
   owner's sheets or does it hide in a mesh statistic, and where
   does it waste runs (rebuilds, re-reviews, per-hull adjudication)?
5. Disposition table: every constraint, C1 to C65, one row each:
   KEEP, RE-DERIVE, REPLACE, or DROP; for RE-DERIVE and REPLACE,
   the replacement approach and its cost in the pack's agent-term
   units only; for DROP, what replaces the protection the number
   was giving, or the statement that none is needed. A disposition
   that contradicts one of your own lens entries is an error.
6. Owner questions: at most three, each with your pick and one line
   on the stakes. Questions must be human-direction questions, not
   technical ones.
7. Not checked: what this report could not verify from the pack.

Hard constraints: no human-time estimates anywhere (no hours, days,
or weeks of human work); costs only in the units above. No invented
measurements, thresholds, or quotations. No em dashes. Plain ASCII.

---

### Qwen leg (writer)

You are a blind reviewer on a game project's graphical standards.
One file is your complete evidence and your complete instruction:
PACK.md, the evidence pack for a red team of the graphical
standards of the game Embers of the Hollow Sun. You have no other
sources. Do not browse, do not use outside knowledge of this project
beyond what the pack contains, and do not invent facts the pack does
not hold.

Task: answer the question in PACK section 1.3 for the constraint
inventory in PACK section 3 (C1 to C65), in light of the worked
example in PACK section 1.2 and the limitations in PACK section 5.
The chair's observations in PACK section 4 are hypotheses to test,
not conclusions to repeat.

Produce one report with exactly these parts:

1. Verdict: one of THE STACK HOLDS, THE STACK HOLDS ONLY WITH
   REPLACEMENTS, or THE STACK DOES NOT HOLD, applied to the
   standards stack as a whole, followed by the three constraints
   your verdict most depends on, named by C-number. A verdict of
   THE STACK HOLDS must state what evidence, if it appeared, would
   change it.
2. Game dev lens: attack every inventory constraint, C1 to C65, in
   order, one entry per constraint: does it bind real performance
   or gameplay, is it denominated in what the engine charges for,
   and what does its being wrong cost in a real battle? An entry
   may be one line where the lens genuinely finds nothing; silence
   on a constraint counts as a miss and the review leg will flag
   it. Mark each entry OBSERVED (present in the pack; cite the pack
   section) or INFERRED (your reasoning; say what it rests on). If
   the pack lacks a fact you need, write NOT IN PACK.
3. Graphics designer lens: the same, C1 to C65 in order, for the
   look, readability, and art direction: which numbers buy real
   readability, which tax the palette, faction identity, or
   silhouette without buying any, and what each error costs on the
   sheet.
4. Agent lead lens: the same, C1 to C65 in order, for production:
   can the pipeline build to it, can a review measure it on the
   owner's sheets or does it hide in a mesh statistic, and where
   does it waste runs (rebuilds, re-reviews, per-hull adjudication)?
5. Disposition table: every constraint, C1 to C65, one row each:
   KEEP, RE-DERIVE, REPLACE, or DROP; for RE-DERIVE and REPLACE,
   the replacement approach and its cost in the pack's agent-term
   units only; for DROP, what replaces the protection the number
   was giving, or the statement that none is needed. A disposition
   that contradicts one of your own lens entries is an error.
6. Owner questions: at most three, each with your pick and one line
   on the stakes. Questions must be human-direction questions, not
   technical ones.
7. Not checked: what this report could not verify from the pack.

Hard constraints: no human-time estimates anywhere (no hours, days,
or weeks of human work); costs only in the units above. No invented
measurements, thresholds, or quotations. No em dashes. Plain ASCII.

---

### Argon leg (review only, runs after the writer legs)

You are a review leg, not a writer leg. You receive four files:
PACK.md (the evidence pack) and the three writer leg reports (blind
Rey, DeepSeek, Qwen) for the graphical standards red team on Embers
of the Hollow Sun. Do not write a new verdict of your own. Audit the
three reports against the pack.

Produce one report with exactly these parts:

1. Quotation and fact check: for each writer leg, list every
   measurement, threshold, and provenance classification it states
   that does NOT match PACK.md, with the pack location (section or
   C-number) that contradicts it or the note ABSENT FROM PACK. List
   every leg statement marked OBSERVED whose cited pack section
   does not contain it. Pay particular attention to any leg that
   reclassifies a constraint's provenance (section 3) without
   evidence the pack contains.
2. Arithmetic check: recompute every number a leg derives (sums,
   ratios, percentages, sterilisation and density arithmetic, px
   conversions). List each derivation as CONFIRMED or WRONG, with
   the corrected value when wrong.
3. Missed-constraint check: the pack inventory is C1 to C65. For
   each writer leg, list every C-number absent from any of its
   three lens sections, and every C-number absent from its
   disposition table. Also list any numeric constraint a leg relies
   on that is not in the inventory at all, flagged as either a
   genuine inventory gap (name it) or an invention (part 1).
4. Constraint check: flag any human-time estimate, any em dash, any
   cost stated outside the pack's agent-term units, and any owner
   question beyond the three-question cap, per leg. Also flag any
   disposition that contradicts the same leg's own lens entries.
5. Adopt/cut list: for each writer leg, an exact list: ADOPT
   (finding, lens entry, or disposition identifiers), CUT
   (identifiers, with the reason tied to parts 1 to 4), and FLAG
   (identifiers that are sound only with a correction you state).
6. Not checked: what this review could not verify.

Hard constraints: the pack is the sole evidence; do not browse and
do not supply project or graphics facts of your own. If a writer leg
and the pack disagree, the pack wins and the disagreement is a
finding. No em dashes. Plain ASCII.
