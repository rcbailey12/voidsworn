# Evidence pack: red team of the Voidsworn environment and backdrop gates

Job: a red team of every numeric gate, count, size, density,
resolution, budget, construction rule, and standing constraint
governing how the environment of Embers of the Hollow Sun
(Voidsworn) looks and is built: nebulas and ion storms, planets,
asteroid fields, the backdrop and starfield, and stations as
scenery. Four legs run from this pack: three writer legs (blind
Rey, DeepSeek, Qwen) and one review leg (Argon). The chair
screens every leg before anything is adopted.

This pack is the legs' complete evidence. It is built from
FINDINGS rulings, the board queue in LOOP.md, issues 100, 139,
140, 172, 183, 195, and 199, the terrain fx, backdrops, station
detail, and graphics leap research syntheses, and the shipped
Godot code and Blender station kit read on main on Nov 6, 2026.
Where this pack and a leg disagree, the pack wins. Where a
source document and this pack's summary of it disagree, the
source wins and the disagreement is a finding.

## 1. Framing

### 1.1 The owner's instruction

Ryan Bailey, Nov 6, 2026: after the graphics red team ripped the
assumed and anchored numeric gates out of the ship standards
that morning, and the effects, animation, and sound audit found
the same disease there (55 of 76 items ASSUMED), he asked what
else could be audited along the same lines, naming physics,
motion, backgrounds, and other models such as asteroids,
nebulas, stations, and destruction in general: the things that
make the game feel and look like a high quality game but might
be artificially constricted by arbitrary gates. The chair
proposed the environment and backdrop audit first, because the
builds it governs are next in the queue (issues 139 and 140 at
positions 3 and 4, issue 199 at position 2, terrain fx 2 at
position 14). Ryan's reply: do all of them, and use all the
LLMs. This pack is the environment pass.

### 1.2 Standing owner rulings that govern this audit

These rulings are settled and are NOT inventory items. The legs
apply them; they do not re-litigate them.

- Tests run uncapped. Measurements exist to find where fidelity
  can scale UP and where performance forces scale DOWN.
  Triangles, draw calls, surfaces, and milliseconds are
  reported, never treated as pass or fail gates.
- The measured scene gate in milliseconds on the RTX 5080
  (issue 207, still to run) is the only binding performance
  limit. No environment number in this pack is a substitute for
  it.
- Performance aspiration: 60 fps at 4K, flexible as needed;
  minimum resolution 1440p (ruled Nov 6, 2026 in the fx audit).
- Judgement is the owner's eye on comparison sheets and in
  play, against the stated objective: AAA style graphics.
- Assumed and anchored numeric gates stop binding. A constraint
  earns its way back only by proving itself in builds.
  Replacements are measurements, consolidated specifications,
  or the owner's eye on sheets.
- Settled Nov 6, 2026 and excluded from re-litigation: the tri
  half of the R100 station hard ceiling was REMOVED by the
  owner (graphics red team item C60). Its millisecond figures
  stand as assumed reporting until the station baseline is
  counted. Where this pack inventories a station number, it
  inventories only what still binds after that ruling (see ST5
  for the one place the record disagrees with itself).
- Costs are stated only in agent terms (section 1.5). No human
  hours anywhere (standing rule R99).

### 1.3 This red team's question

For every gate, count, constant, and standing rule in the
environment stack, answer three things:

1. What kind of number or rule is it? MEASURED (produced by an
   instrument, a code verification, or a counted delivery),
   DERIVED (computed from measured or ruled inputs, with the
   arithmetic shown), ASSUMED (a chosen threshold or design
   constant with no measurement or derivation in the record),
   or ANCHORED (the measured property of one incumbent asset,
   one test scene, or one external game, promoted into a rule).
2. What does it cost if it is wrong, in each of the three
   lenses: game dev (performance or gameplay), domain designer
   (the look and feel of the environment itself), agent lead
   (pipeline effort, enforceability, wasted runs)?
3. What measurement, test, or build would settle it, and what
   does that cost in agent terms (section 1.5)?

A gate is artificial, in the owner's sense, when its number
cannot be traced to a measurement or a derivation but it still
binds builds, fails work, or spends review. A standing
qualitative rule counts as a gate when it forbids or mandates a
technique or a construction (additions only, procedural only,
giants unchanged), because those bind builds exactly the way
numbers do.

### 1.4 Relationship to the fx audit (read this before the inventory)

The fx audit pack (~/workspace/voidsworn-fx-audit/PACK.md)
already inventoried the LIGHTING side of this same environment.
Those items are NOT duplicated here. The legs treat them as
settled inventory under their fx numbers:

- E14: fog grid shipped constants (camera near plane 0.5, fog
  length 400, froxel grid 64 by 64). MEASURED baseline.
- E15: fog preparation proposals (near plane 5 to 15 per zoom
  band, fog length toward 250, froxel 128 at max tier). ASSUMED.
- E16: nebula puff counts and sizes. ASSUMED. (This pack's NB1
  and NB2 inventory the parts of that construction E16 did not
  price: the height bands, alphas, mask, and layer structure.)
- E17: faction tint cap about 25 percent. ASSUMED. (NB5 cites
  it for the colour-stop detail E17 did not carry.)
- E18: star occlusion working targets (30 percent body, 60
  percent wisps, 10 to 15 percent storm). ASSUMED.
- E19: patch light cap, one OmniLight3D per patch, energy 0.6
  to 1.0. ASSUMED.
- E20: filament core area target, under 10 percent of patch
  screen area. ASSUMED.
- E21: storm bolt rules (about 1 per 2 hexes, at most 6, first
  4 carry lights). ASSUMED.
- E22: planet bake resolution 4096 by 2048, moons 1024 by 512.
  ASSUMED.
- E23: planet bake time 6 to 9 seconds per battle. MEASURED
  (owner playtest observation, R76).

This pack inventories everything around those items: the
construction, placement, variety, and scenery rules the fx
audit did not touch.

### 1.5 Cost units

Costs in this pack, and in every leg, are stated only in agent
terms: Codex runs (one-hour cap per run), Opus runs, one-time
script builds, per-asset unattended runs, and owner review
rounds. State one-time and recurring costs separately. No
human-time estimates anywhere (R99).

## 2. Evidence base

- FINDINGS (contrib/opus/FINDINGS.md, main, read Nov 6, 2026):
  R79 (planet route, rock cap, two station variants, bake
  resolution), R82 (terrain fx picks), R88 (owner playtest:
  asteroids hollow, nebulas and storms low fidelity, planets
  need much higher quality, 50 to 75 percent jumps), R90
  (graphics leap picks, planet kind order, fog light tiers),
  R94 (station shapes locked), R100 (station detail picks),
  R103 and R104 (paint rejections and station repaint), R109
  (station needs way more surface detail).
- LOOP.md (board state, Nov 5, 2026): queue order. Station
  detail (199) at position 2, nebulas and storms (139) at 3,
  planets (140) at 4, terrain fx 2 (100) at 14.
- Issues read Nov 6, 2026: 139 (nebulas and storms as volumes,
  open, codex, blocked), 140 (rocky and terran planets, open,
  codex, blocked), 100 (terrain fx 2, open, codex, blocked),
  199 (station surface detail, open, codex), 172 (station detail
  brief, closed), 183 (station detail build, closed), 195
  (station repaint, closed).
- Terrain fx synthesis (contrib/muse/research/
  terrain_fx_2026_11/synthesis.md, ruled R82): nebula, storm,
  debris, and dead star well specifications.
- Backdrops synthesis (contrib/muse/research/
  backdrops_2026_11/synthesis.md, ruled R79): scale plan,
  blocker rocks, debris sizes, station kitbash route.
- Station detail synthesis (contrib/muse/research/
  station_detail_2026_11/synthesis.md, ruled R100).
- Graphics leap synthesis (contrib/muse/research/
  vfx_leap_2026_11/synthesis.md, ruled R90): the designs issues
  139 and 140 build. Its frame cost figures are INFERRED by its
  own header; no Godot project was run for it.
- Graphics red team pack and synthesis (Nov 6, 2026): items C39
  and C40 (ship and station close-band floors), C59 and C60
  (station target and ceiling), and the owner's Nov 6 rulings.
- Godot code read on main, Nov 6, 2026: godot/world/world.gd
  (1301 lines), world_sky.gd, world_rocks.gd, world_planet.gd,
  world_bake.gd, world_living.gd, world_shaders.gd,
  godot/render/backdrop.gd, godot/render/board.gd (ZONE_TINT,
  play-area planet, station sizing), godot/world/board_look.gd,
  godot/scenes/battle/battle.gd (quality tiers),
  godot/render/camera_rig.gd.
- Station kit: tools/blender/hs/station_kit.py (962 lines) and
  STATION_KIT.md, read Nov 6, 2026.
- Engine test fixture: asteroids.json (206 rocks), as carried
  in the backdrops research record.

Inventory shape: 74 items. NB (nebulas and storms) 13, PL
(planets) 14, AS (asteroids and fields) 18, BD (backdrop and
starfield) 19, ST (stations as environment) 10. Provenance
tally: MEASURED 1, DERIVED 2, ANCHORED 1, ASSUMED 70. The
environment stack is, by this tally, the least measured stack
audited so far: nearly every number in it is a design constant
that shipped in code or was adopted from a research synthesis
without a capture, a count, or a timing ever being taken
against it.


## 3. Nebulas and storms inventory (NB1 to NB13)

Template per entry: the value or rule and where it lives; its
provenance class with the evidence; what breaks if it is wrong;
what measurement would settle it. Tallies for this section:
13 entries; MEASURED 0, DERIVED 0, ANCHORED 1, ASSUMED 12.
Puff counts and sizes, the tint cap, occlusion targets, the
patch light cap, the filament area target, and the bolt rules
are fx items E16 to E21 and are not repeated here.

NB1. Nebula height bands, shipped: puffs sit in three bands,
y -2.5 to 0.5, 2.5 to 6.5, and 8 to 12 units.
- Lives in: godot/world/world_living.gd (nebula construction),
  as quoted against the terrain fx synthesis section 2.1.
- Provenance: ASSUMED. Evidence: shipped code constants. The
  terrain specification proposed four different bands (-4 to 2,
  1 to 8, 6 to 14, 12 to 18) and the shipped code matches none
  of them exactly; the record shows no ruling that chose the
  shipped set over the specified set, and no capture judged
  either.
- If wrong: the vertical structure decides whether gas reads as
  a volume the battle sits inside or as flat decals under it;
  the wrong bands also decide how much gas crosses ship height,
  which NB9 prices.
- Settles it: one patch built at both band sets under the issue
  139 volume shader, sheeted at battle and close camera, one
  Codex run plus one owner review round.

NB2. Puff and veil alpha: puff alpha 0.55 to 0.85, broad veil
alpha 0.3 to 0.4, nebula density parameter 0.5, storm density
parameter 1.0.
- Lives in: godot/world/world_living.gd (nebula and storm
  material setup).
- Provenance: ASSUMED. Evidence: shipped constants kept by the
  terrain research while it replaced the shading model; no
  density sweep or readability capture stands behind them.
- If wrong: these four numbers are most of what "low fidelity"
  (R88) means in practice for gas: too light reads as smoke
  decals, too heavy eats the board and the ships behind it.
- Settles it: a three-step alpha and density sweep on one patch
  under the new shader, one Codex run plus one owner review
  round. One-time.

NB3. Nebula mask and clustering: patches cluster inside a
radius of 18 units; mask feather 2.0 units for nebula, 1.5 for
storm; mask texel 1 unit; mask falloff constant SIG2 42;
24-unit margin around the patch footprint; gas render priority
-5.
- Lives in: godot/world/world_living.gd (patch mask build).
- Provenance: ASSUMED. Evidence: shipped code constants; the
  feather values were adopted in the terrain synthesis as
  design values, with no edge-quality capture in the record.
- If wrong: patch edges are where billboard gas betrays itself;
  a hard or blobby edge at the battle camera undoes the volume
  work in issue 139 no matter what the interior shader does.
- Settles it: edge close-ups at two feather and texel settings
  in the issue 139 sheet run, no extra run; judgement is the
  owner's eye on those sheets.

NB4. Nebula colour stops: c_dark (0.006, 0.002, 0.014),
c_shadow (0.055, 0.012, 0.14), c_lit is the legend violet
#b07cff lerped halfway toward the faction colour and scaled by
0.65, with green capped at 0.24 times blue and red at 0.60
times blue; c_glow (0.88, 0.72, 1.0).
- Lives in: godot/world/world_living.gd lines 341 to 348 area
  (material parameter setup); terrain fx synthesis section 2.1
  (the four-stop ramp these implement).
- Provenance: ASSUMED. Evidence: the ramp is a chair design
  adopted in R82; the channel caps (green and red ratios) are
  one synthesis's guard against the mauve and brown failure in
  playtest shots, never re-measured after adoption.
- If wrong: the caps decide whether every nebula in the game
  reads violet-family or drifts muddy; they also cap how much
  faction identity gas can ever carry, on every map, forever.
- Settles it: the ramp sheeted with the caps relaxed in steps
  on a warm and a cool faction sky, one owner review round on
  an existing sheet run.

NB5. Faction tint weight: NEBULA_FACTION_END_WEIGHT 0.25, the
constant behind the R82 cap of about 25 percent faction pull at
the ramp ends. (Fx item E17 carries the cap itself; this item
carries the fact that one global constant applies it to every
nebula, every storm, and every faction with no per-faction or
per-map variation anywhere in the record.)
- Lives in: godot/world/world_living.gd line 37.
- Provenance: ASSUMED. Evidence: same basis as E17; the terrain
  synthesis itself calls the weight "a single tunable constant,
  not structure."
- If wrong: one dial position silently sets the identity range
  of all gas in the game; a per-map need (a dead star sector
  versus a home sector) has no way to exist.
- Settles it: covered by the E17 settlement (three weights on a
  warm faction sky, one owner review round); this item adds
  only the question of whether the winner stays global.

NB6. Fixed violet nebula family: nebulas are one fixed violet
family; faction colour enters only through the capped ramp
ends (NB5), never as the family itself.
- Lives in: FINDINGS R82 Q1 (owner ruling adopting the chair
  pick).
- Provenance: ASSUMED. Evidence: an owner-adopted design pick
  from the terrain research; no alternative family was ever
  sheeted for comparison in the record read.
- If wrong: every nebula map in the game shares one colour
  identity; if the family is the problem behind "still low
  fidelity," no amount of volume work fixes the sameness.
- Settles it: one sheet of the same patch in the violet family
  and one alternative family under the volume shader, one owner
  review round. One-time.

NB7. Gas at ship height: gas alpha at ship height (y 0 to 3)
stays below 0.4; nebula body alpha starts at 0.40 at patch
centre; the densest point of any gas is capped at 0.7, adopted
from EVE Online's nebula density practice.
- Lives in: terrain fx synthesis section 2.1; FINDINGS R82 Q2
  (hulls stay crisp inside gas, gas dims stars and sky only).
- Provenance: ANCHORED. Evidence: the 0.7 figure is one external
  game's measured practice promoted into a design rule, with a
  citation caveat recorded in the synthesis itself; the 0.4
  figures are the synthesis's own working values, unmeasured.
- If wrong: this is the readability contract for ships inside
  terrain; too high and ships drown (the failure R82 Q2 was
  written against), too low and gas never feels entered.
- Settles it: a ship inside a patch at three centre densities,
  sheeted at the battle camera, judged for hull crispness, one
  Codex run plus one owner review round.

NB8. Gas motion: layer motion multipliers (ground haze 0.6x,
body 1x, wisps 1.6x, tying veil 0.4x of one base drift rate)
plus an 8-second breathing oscillation on patch density.
- Lives in: terrain fx synthesis section 2.1.
- Provenance: ASSUMED. Evidence: stated as specification values
  in the research; no recording in the record measures the
  shipped motion against them, and the base drift rate they
  multiply is not itself numbered anywhere in the record read.
- If wrong: motion is the difference between a living volume
  and a static backdrop prop; multipliers on an unnumbered base
  cannot be built to or checked, so each builder invents the
  base.
- Settles it: the 10-second storm and nebula recordings issue
  139 already requires, reviewed against one variant with the
  multipliers flattened, one owner review round.

NB9. Nebula layer structure: four layers (ground haze, main
body, wisps, tying veil), with filament cores running at 3 to
4 times the base noise frequency.
- Lives in: terrain fx synthesis section 2.1; issue 139 carries
  the structure into FogVolumes under a thinned billboard edge
  layer.
- Provenance: ASSUMED. Evidence: a research design; the layer
  count and the frequency ratio were never swept. (The filament
  area target that rides on this structure is fx item E20.)
- If wrong: the layer count is the construction cost of every
  patch and the frequency ratio is its texture scale; both are
  inherited by the volume build before either was tested.
- Settles it: one patch at two layer counts sheeted in the
  issue 139 run, no extra run beyond the variant build.

NB10. Storm colour stops: c_dark (0.003, 0.003, 0.006), c_lit
(0.035, 0.028, 0.06), c_glow (0.3, 0.17, 0.62), glow_from 0.5.
- Lives in: godot/world/world_living.gd (storm material setup).
- Provenance: ASSUMED. Evidence: shipped constants; unlike the
  nebula ramp, no research section in the record derives or
  defends the storm stops, and they sit far darker than the
  nebula family they share maps with.
- If wrong: storms either vanish against the sky (too dark to
  read as terrain a player must respect) or, corrected by eye
  per build, drift inconsistent between maps.
- Settles it: storm sheets at the shipped stops and one lifted
  variant in the issue 139 run, one owner review round.

NB11. Storm between-bolt activity: electric filaments advect
over 3 to 6 seconds; sheet glow extends 1 to 2 hexes from a
bolt; flash response boost 0.3 within about 12 units of a bolt;
shield-tick flare on ships inside the storm.
- Lives in: terrain fx synthesis section 2.2. (Bolt count,
  cadence, and bolt lights are fx item E21.)
- Provenance: ASSUMED. Evidence: specification values from the
  research; no recording in the record checks any of them, and
  the 12-unit boost radius is denominated in units while its
  neighbours are denominated in hexes, with no conversion
  stated.
- If wrong: between bolts is most of a storm's screen time;
  dead air there is the R88 "low fidelity" complaint in its
  storm form.
- Settles it: the issue 139 10-second storm recording, reviewed
  against these numbers as a checklist, one owner review round.

NB12. Storm and explosion lights in fog: at max tier only;
density pulse at high tier; the current path at low tier.
- Lives in: FINDINGS R90 (owner ruling adopting the leap
  synthesis pick); issue 139 done-when carries it.
- Provenance: ASSUMED. Evidence: a chair pick adopted without a
  per-tier frame cost measurement; the tier structure it hangs
  on has no measured cost per tier anywhere in the record (see
  BD18).
- If wrong: the single most atmospheric interaction in the
  environment (light inside gas) is rationed by an unmeasured
  ladder; if max tier costs little, high and low are being
  denied it for nothing.
- Settles it: per-tier fog light cost inside the issue 207
  benchmark's effects isolation run, one Opus run (already
  directed for effects generally; this item names the fog
  case).

NB13. Quality ladder protection rule: when quality drops, puff
counts and bolt light usage are cut first; the colour ramp and
the glow cores are never cut.
- Lives in: terrain fx synthesis section 2.8 area (quality
  ladder); issue 100 carries the ladder as a build task.
- Provenance: ASSUMED. Evidence: a stated priority in the
  research with no per-element cost table behind it; nothing in
  the record prices what a puff, a bolt light, or the ramp
  actually costs at any tier.
- If wrong: the ladder may be protecting the cheap elements and
  cutting the expensive ones, or vice versa; either way the
  low tier's look is decided by an unpriced ranking.
- Settles it: the same per-tier cost table as NB12, one Opus
  run, shared settlement.

## 4. Planets inventory (PL1 to PL14)

Tallies for this section: 14 entries; MEASURED 0, DERIVED 1,
ANCHORED 0, ASSUMED 13. Bake resolution and bake time are fx
items E22 and E23 and are not repeated here.

PL1. Backdrop planet placement: distance DIST 3300 units;
azimuth offset to one side, 0.36 to 0.5 rad; elevation -0.17 to
-0.22 rad; tilt 0.18 to 0.42 rad around z and -0.25 to 0.1 rad
around x.
- Lives in: godot/world/world.gd line 373 (DIST) and the
  backdrop planet placement code around it.
- Provenance: ASSUMED. Evidence: shipped code constants; no
  composition study or sheet comparison in the record chose
  these ranges, and the elevation band keeps every backdrop
  planet below the board's horizon line on every map.
- If wrong: placement ranges are composition law; a narrow band
  means every battle in the game is framed the same way, which
  players read as repetition long before they can name it.
- Settles it: one map sheeted at three placements outside the
  current bands, one owner review round on an existing run.

PL2. Backdrop planet angular size: angular radius 0.15 to 0.18
rad for giants, 0.11 to 0.14 rad for other kinds (diameter 726
to 1180 units at DIST).
- Lives in: godot/world/world.gd (backdrop planet build).
- Provenance: ASSUMED. Evidence: shipped ranges; the backdrops
  research adopted the angular framing (planets read by angle,
  not by distance) but the band edges themselves are unjudged
  in the record.
- If wrong: too small and the planet is wallpaper; too large
  and it dominates every screenshot and fights the battle for
  the eye. The band also interacts with AS1: rocks are capped
  relative to this size (PL8).
- Settles it: the same sheet run as PL1, planets at both band
  edges and one step beyond, one owner review round.

PL3. Backdrop planet spin: 0.002 to 0.006 rad per second.
- Lives in: godot/world/world.gd (backdrop planet build).
- Provenance: ASSUMED. Evidence: a shipped range with no
  motion capture or feel ruling behind it in the record.
- If wrong: at these rates a planet turns visibly only over
  minutes; the range decides whether the sky feels alive in a
  long battle or frozen, and nobody has ever watched for it.
- Settles it: one 60-second capture at the top of the range,
  folded into the issue 139 recording round, one owner review
  round.

PL4. Planet looks table: 8 looks across 6 kinds (gas giant,
ice giant, terran, desert or volcanic, barren cratered, ice
world); moons per look 0 to 3, from the same table.
- Lives in: godot/world/world.gd (PLANETS table); issue 140
  rebuilds the terran, rocky, and volcanic desert entries.
- Provenance: ASSUMED. Evidence: the table is shipped content
  design; no variety audit in the record asks whether 8 looks
  across all maps is enough, and the kind mix per campaign is
  not stated anywhere in the record read.
- If wrong: variety is a count before it is a quality; a player
  who has seen all 8 looks has seen the game's whole sky, and
  issue 140 raises the fidelity of a possibly too-small set.
- Settles it: a contact sheet of all 8 looks at the battle
  camera, one script build (one-time) plus one owner review
  round.

PL5. Moon geometry: moon angular radius rolled at 0.03 to 0.04
rad; separation at least 0.04 rad from the planet and 0.05 rad
between moons; moon distance 0.8 to 1.15 times DIST.
- Lives in: godot/world/world.gd (moon placement).
- Provenance: ASSUMED. Evidence: shipped constants; the margins
  are collision-avoidance values for the sky composition, never
  sheeted at their edges.
- If wrong: moons are the backdrop's main scale cue; margins
  too wide scatter them into unrelated dots, too tight and the
  system reads as a diagram.
- Settles it: folded into the PL4 contact sheet with moons at
  both margin extremes, no extra run.

PL6. Moon character: kinds 65 percent barren, 35 percent ice;
spin 0.0 to 0.004; tints drawn from a 4-entry list scaled by
0.8 to 1.1.
- Lives in: godot/world/world.gd (moon build).
- Provenance: ASSUMED. Evidence: shipped distribution values;
  no ruling in the record chose the barren majority or the tint
  list.
- If wrong: a 65/35 split means most moons a player ever sees
  are grey rock; the tint list's narrow 0.8 to 1.1 band caps
  how distinct any of them can look.
- Settles it: folded into the PL4 contact sheet, one owner
  review round.

PL7. Rings: exactly 2 of the 8 looks carry rings.
- Lives in: godot/world/world.gd (PLANETS table).
- Provenance: ASSUMED. Evidence: a table entry; no record of
  the choice or of ring rendering cost at the 4K camera.
- If wrong: ringed planets are the strongest silhouette in any
  space backdrop; rationing them to a quarter of looks, or
  spending them there, is an identity decision made by a table
  default.
- Settles it: one ringed variant sheeted at the battle camera
  in the issue 140 run, one owner review round.

PL8. Planet to rock angular margin: a backdrop rock's angular
size times 4.4 must not exceed twice the planet's angular
radius, enforced by an assert next to the AS1 cap.
- Lives in: godot/world/world.gd (_backdrop_scale asserts);
  FINDINGS R79 (planet at least 4.4 times wider than any rock).
- Provenance: ASSUMED. Evidence: an owner-ruled pick from the
  backdrops research; the 4.4 figure has no sheet comparison
  behind it in the record, and the assert makes a composition
  preference a build failure.
- If wrong: this ratio, with AS1, silently sets the entire
  scale ladder of the sky; if it is too strict, rocks can never
  feel near or large, which is one reading of the R88 "hollow"
  complaint.
- Settles it: one sheet with the margin relaxed to 3x and 2x,
  judged for whether rocks start to read as near objects, one
  Codex run plus one owner review round.

PL9. Play-area planet size: radius = R times 1.5 times HS plus
HS times 0.5 (HS the hex corner radius, 10 units), sunk 78
percent below the board, leaving a cap about 11 units high and
about 63 units across.
- Lives in: godot/render/board.gd (_planet build).
- Provenance: DERIVED. Evidence: the formula is arithmetic on
  the ruled hex geometry (HS 10 from the backdrops scale plan);
  the 78 percent sink and the 1.5 multiplier are the chosen
  inputs, and those inputs are assumed even though the
  resulting radius is derived.
- If wrong: the play-area planet is the one environment object
  ships fight directly over; its cap height and chord decide
  how much of a battle reads as "over a world" versus "next to
  a ball."
- Settles it: one battle sheeted at two sink depths in the
  issue 140 run, one owner review round.

PL10. Play-area planet mesh resolution: sphere of 96 radial
segments by 48 rings.
- Lives in: godot/render/board.gd (_planet build).
- Provenance: ASSUMED. Evidence: a shipped constant; the
  segment count was not chosen against the bake resolution
  (E22) or the close zoom anywhere in the record.
- If wrong: silhouette faceting at close zoom is a mesh
  resolution failure that no texture bake can hide, and this is
  the planet the camera gets closest to.
- Settles it: one close-zoom capture checked for faceting,
  folded into issue 140's close zoom sheets, no extra run.

PL11. Procedural-only planet route: planets stay procedural
and get bake fixes; photo textures are excluded as a route.
- Lives in: FINDINGS R79 (owner ruling); issue 140 stays inside
  it (GPU bake geology plus CC0 micro-detail textures).
- Provenance: ASSUMED. Evidence: an owner ruling on a research
  recommendation; the record read contains no head-to-head of a
  procedural bake against a textured build at the current
  standard, and R88's "much higher quality" demand for terrain
  planets postdates the ruling.
- If wrong: the route is the ceiling on planet quality; if the
  bake cannot reach the bar, the ruling spends issue 140
  discovering it one build at a time.
- Settles it: issue 140's own before and after sheets are the
  test; if the after sheets miss the owner's bar, the route
  question returns with evidence, one owner review round.

PL12. Bake cache and wait: at most 24 cached bakes
(world_bake.gd CACHE_MAX); battle start waits for pending
bakes with a hard cap of 20 seconds.
- Lives in: godot/world/world_bake.gd line 6 (CACHE_MAX 24);
  godot/world/world.gd line 106 (wait_ready, 20000 ms cap).
- Provenance: ASSUMED. Evidence: engineering constants; the 20
  second cap interacts with E23's measured 6 to 9 second bake
  and issue 140's richer bake, and no record prices a cache
  miss at battle start on a cold profile.
- If wrong: a hard wait cap that expires mid-bake ships a
  battle with an unfinished sky, and a 24-bake cache decides
  how often a campaign pays the bake cost at all.
- Settles it: cold-start bake timing on a storm and a planet
  map, reported in issue 140's done-when (cold bake time is
  already required there), no extra run.

PL13. Bake resolution ladder for the sky: sky bake 4096 by
2048 at max, 2048 by 1024 at low, 768 by 384 in the world
preview. (The planet bake's own 4096 by 2048 is fx item E22.)
- Lives in: godot/world/world.gd (_load_sky quality branch).
- Provenance: ASSUMED. Evidence: shipped ladder values; the
  low tier halves resolution twice over with no sheet in the
  record showing what the low sky looks like at 1440p, the
  owner's floor resolution.
- If wrong: the low tier is where the "lower setting for weaker
  PCs" promise (R88) actually lives; an unjudged ladder means
  nobody has seen the game the lower setting shows.
- Settles it: one low-tier capture at 1440p in the issue 139
  sheet run, one owner review round.

PL14. Planet kind build order: terran and barren or rocky
first, then volcanic desert; gas and ice giants unchanged.
- Lives in: FINDINGS R90; issue 140 done-when carries it.
- Provenance: ASSUMED. Evidence: an owner-adopted chair pick;
  "unchanged" for the giants is a standing constraint whose
  basis is that they were not complained about, and no sheet in
  the record compares a giant against the rebuilt kinds at the
  current camera.
- If wrong: after issue 140 the sky has two quality classes;
  if the giants read a generation behind the rebuilt kinds,
  the unchanged rule preserves the gap permanently.
- Settles it: the PL4 contact sheet, taken after issue 140,
  judged for whether the giants still sit in the same sky, one
  owner review round.


## 5. Asteroids and fields inventory (AS1 to AS18)

Tallies for this section: 18 entries; MEASURED 1, DERIVED 1,
ANCHORED 0, ASSUMED 16.

AS1. The backdrop rock angular cap: no single backdrop rock
may exceed 0.05 rad of angular width, enforced by an assert in
_backdrop_scale (angle <= 0.05 + 0.000001), with the length cap
computed per rock from its distance.
- Lives in: godot/world/world.gd line 27 (BACKDROP_ROCK_ANGLE)
  and lines 842 to 845 (cap and assert); FINDINGS R79 (owner
  ruled "the strict rock cap").
- Provenance: ASSUMED. Evidence: an owner-ruled pick from the
  backdrops research, adopted as a strictness preference ("no
  single backdrop rock wider than 0.05 rad"); no size sweep or
  sheet comparison in the record stands behind 0.05 rather than
  0.08 or 0.12, and the assert promotes the preference into a
  build failure.
- If wrong: this one number caps the apparent size of every
  rock in the sky, including the mountain field (AS8), which
  has no other length cap. It is the scale ceiling of the whole
  backdrop, and a candidate root cause for R88's playtest
  verdict that asteroids "look hollow, as if seen from inside":
  a sky where nothing may loom can read as a shell.
- Settles it: one belt and one mountain sheet at 0.05, 0.09,
  and 0.14 rad caps, judged for looming versus clutter, one
  Codex run plus one owner review round. One-time.

AS2. Field counts per map kind: [edge, deep, belt, mountains]
counts of belt [80, 260, 420, 7], open [20, 110, 0, 3], station
[34, 150, 0, 4], planet [26, 120, 0, 3], storm [30, 150, 0, 4],
graveyard [44, 190, 0, 4], default [24, 120, 0, 3], scaled by
the region rocks density value.
- Lives in: godot/world/world.gd (fields function).
- Provenance: ASSUMED. Evidence: shipped table values; no
  density sweep exists in the record for any map kind, and the
  belt's 420 deep rocks against open's 110 is a 4x density
  decision with no sheet behind it.
- If wrong: these counts are the environment's population law;
  every map's richness or emptiness is decided here, before any
  per-rock art runs.
- Settles it: belt and graveyard maps sheeted at 0.6x, 1x, and
  1.6x counts, one Codex run plus one owner review round.

AS3. Low-quality field reduction: deep and belt counts run at
0.6 times on low quality.
- Lives in: godot/world/world.gd (fields function quality
  branch).
- Provenance: ASSUMED. Evidence: a shipped multiplier with no
  per-tier frame cost or look comparison in the record (the
  tier structure is BD18).
- If wrong: either low tier pays for rocks it did not need to
  cut, or cuts 40 percent of the field and still misses its
  frame target for reasons elsewhere.
- Settles it: the per-tier cost table of NB12 and NB13 covers
  this if fields are included, one Opus run, shared settlement.

AS4. Edge scatter sizing: size 1.6 + 7 times pow(randf, 2.5),
plus 8.0 on a 6 percent roll; max length 20 (before the AS1 cap
applies); spin 0.01 to 0.07 scaled by 3 / (2 + size).
- Lives in: godot/world/world.gd (edge scatter build).
- Provenance: ASSUMED. Evidence: shipped distribution formulas;
  the 6 percent large-rock roll is the only mechanism that can
  put a big rock at the field edge, and its rate was never
  judged on a sheet.
- If wrong: the edge field frames every battle; its size
  distribution decides whether the frame reads as rubble, a
  ring, or noise.
- Settles it: folded into the AS2 sweep sheets (edge field is
  visible on every map), one owner review round.

AS5. Edge scatter height bands: far rocks at y -40 to 12, near
rocks at y -140 to -90, side rocks at y -75 to -28.
- Lives in: godot/world/world.gd (edge scatter build).
- Provenance: ASSUMED. Evidence: shipped bands; the near band
  sits entirely below the far band, a vertical layering choice
  no capture in the record examines.
- If wrong: height banding is what makes the field feel like a
  place around the board rather than a ring at its level; wrong
  bands flatten the parallax the backdrop depends on (BD15).
- Settles it: one side-view capture of the field, folded into
  the AS1 cap sweep, one owner review round.

AS6. Deep field: distance 800 to 1500; depth 0.35 to 0.85
times distance; size (3 + depth times 0.035) times (0.5 + 1.6
times pow(randf, 2)); max length 40; spin 0.005 to 0.04.
- Lives in: godot/world/world.gd (deep field build).
- Provenance: ASSUMED. Evidence: shipped formulas; the depth
  fraction is the parallax law for the mid-ground and appears
  in no research document in the record read.
- If wrong: the deep field is most of the visible rocks in most
  battles; its depth law decides whether the sky has middle
  distance at all.
- Settles it: folded into the AS2 density sheets, one owner
  review round.

AS7. Belt stream: depth 150 to 240; span -2600 to 2600 across;
gaussian width sigma 170; tilt -0.06 to 0.06; no rock closer
than 600 units to the centre; size 4 + 30 times pow(randf, 3)
plus a velocity term; max length 30; spin 0.004 to 0.03.
- Lives in: godot/world/world.gd (belt build).
- Provenance: ASSUMED. Evidence: shipped formulas; the 600-unit
  exclusion and the sigma are the belt's whole composition, and
  the belt map is the nebula and storm showcase map in issue
  139's captures, so these numbers sit behind those sheets
  unexamined.
- If wrong: a wrong sigma reads as a wall or a smear; the
  centre exclusion decides whether the belt ever threatens to
  enter the battle's space visually.
- Settles it: belt sheets at sigma 120 and 240 in the AS2 run,
  one owner review round.

AS8. Mountain field: distance 900 to 2300; elevation -0.08 to
-0.6 rad; raw size 70 to 220 scaled by distance over 1600; spin
0.0015 to 0.006; no max-length cap of its own, so AS1's angular
cap is the only ceiling.
- Lives in: godot/world/world.gd line 936 area (mountain
  build).
- Provenance: ASSUMED. Evidence: shipped values; the raw size
  220 at 900 units would subtend about 0.24 rad, roughly five
  times the AS1 cap, so in practice the cap, not this range,
  sizes the largest mountains. The record shows no awareness of
  that interaction.
- If wrong: mountains are the backdrop's only monumental form;
  if the cap silently shrinks them, the "mountain" field is a
  name for mid-size rocks, and the fix (raising AS1) is blocked
  by an assert written for a different purpose.
- Settles it: settled together with AS1; the mountain sheet is
  the deciding capture, one Codex run plus one owner review
  round, shared settlement.

AS9. Crystal fields: 12 clusters; crystal size 2 to 6; max
length 20; spin 0.01 to 0.05.
- Lives in: godot/world/world.gd line 954 area (crystal build).
- Provenance: ASSUMED. Evidence: shipped constants; crystals
  appear in no research synthesis in the record read, so the
  only environment feature with no design document at all is
  governed entirely by four code numbers.
- If wrong: an undocumented feature ships at an unjudged count
  and scale; 12 clusters may be a signature or a rounding
  error, and nobody can tell from the record.
- Settles it: one capture with clusters at 12 and at 24,
  folded into the AS2 run, one owner review round.

AS10. Rock spin ranges by field: edge up to 0.07, deep 0.005
to 0.04, belt 0.004 to 0.03, mountains 0.0015 to 0.006,
crystals 0.01 to 0.05 rad per second.
- Lives in: godot/world/world.gd (per-field build functions).
- Provenance: ASSUMED. Evidence: shipped ranges set per field
  by different formulas with no common motion standard; compare
  AS14, where debris motion does have a (conflicting) standard.
- If wrong: inconsistent spin laws mean the same rock reads
  alive in one field and dead in another; players read relative
  motion, not absolute rates, so the inconsistency itself is
  the artefact.
- Settles it: one 30-second capture across two fields, folded
  into the AS14 settlement, one owner review round.

AS11. Engine test rock fixture: 206 rocks (200 field, 6
large), scale 1.0 to 29.914, spin 0.0093 to 0.1792.
- Lives in: the asteroids engine test fixture (asteroids.json),
  as carried in the backdrops research record.
- Provenance: MEASURED. Evidence: a counted, shipped test
  fixture; the only measured rock population in the record.
  Note its spin range tops at 0.1792 rad per second, faster
  than every shipped field range in AS10 and faster than the
  AS14 debris cap, so the test scene and the game disagree
  about how fast rocks may turn.
- If wrong: not a risk to the game; the risk is quoting it as
  the game's behaviour. It is a fixture, not a field.
- Settles it: settled as a baseline; its use is the comparison
  above.

AS12. Debris field density: living debris 15 to 22 rocks per
hex (8 to 12 at low quality); plain path 8 to 13 per hex; 48
dust motes per debris hex (0 at low).
- Lives in: godot/world/world.gd (debris_field function).
- Provenance: ASSUMED. Evidence: shipped code values; the
  terrain research specified debris by size structure (AS16)
  but the per-hex counts themselves were never swept.
- If wrong: debris hexes are gameplay terrain (they block and
  shelter); their rock density is both a look and a readability
  signal for "this hex is cover," and an unjudged count taxes
  both.
- Settles it: one debris hex sheeted at both count bands in
  the issue 100 run, one owner review round.

AS13. Wreck pieces in debris: 3 to 5 pieces per event plus a
55 percent chance of one extra hero piece; hero scale 2.6 to
3.8, other pieces 1.3 to 2.6.
- Lives in: godot/world/world.gd (debris_field function).
- Provenance: ASSUMED. Evidence: shipped values; the 55 percent
  hero chance and the scale bands are the whole authored
  presence of wrecks in a debris field, unjudged on a sheet in
  the record.
- If wrong: hero pieces are what make a debris field read as a
  graveyard instead of a quarry; rationing them by an unjudged
  coin flip decides the graveyard maps' identity.
- Settles it: graveyard sheets at hero chance 55 and 100
  percent in the issue 100 run, one owner review round.

AS14. Debris tumble cap: tumble_rate = 0.10 / max(1, scale)
rad per second, applied as a cap on all debris spin (plain
debris raw rates 0.06 to 0.35 are clamped by it).
- Lives in: godot/world/world_living.gd lines 747 to 748 and
  764 (tumble_rate and its use in add_debris_rocks); backdrops
  synthesis (the 0.10 rad per second cap, adopted there over a
  leg's near-static 0.01 to 0.05 proposal).
- Provenance: ASSUMED. Evidence: the cap is a synthesis pick;
  and it CONFLICTS with the terrain synthesis, also adopted,
  whose tumble periods (small rocks 20 to 40 seconds, large 60
  to 90, wreck 80 to 120) convert to 0.157 to 0.314, 0.070 to
  0.105, and 0.052 to 0.079 rad per second. For small rocks the
  two settled documents disagree by a factor of about 2 to 3,
  and the code obeys the lower one. No document in the record
  notices the conflict.
- If wrong: one of the two adopted specifications is dead
  letter; debris motion (the destruction audit will inherit
  this) is governed by whichever constant a builder happened to
  implement, and reviews cannot catch it because both values
  are "the spec" somewhere.
- Settles it: reconcile the two documents into one motion
  figure and sheet debris at both rates, one Opus run plus one
  owner review round. One-time.

AS15. Ambient dust: counts by map kind (belt 2600, graveyard
2000, storm 1600, default 1300), divided by 3 at low quality;
spawn box x -750 to 750, y -420 to 70, z -620 to 620; dust
never spawns over the board above y -25.
- Lives in: godot/world/world.gd line 1264 area (dust
  function).
- Provenance: ASSUMED. Evidence: shipped values; the terrain
  synthesis specified dust by colour and alpha for debris hexes
  (AS16) but the ambient counts and box are code-only numbers.
- If wrong: ambient dust is the cheapest depth cue in the game
  and the first thing cut at low quality; an unjudged count
  either wastes the cue or pays for motes nobody sees at 4K.
- Settles it: one capture with dust at shipped counts and at
  half, folded into the AS2 run, one owner review round.

AS16. Debris size structure spec: at least 20 percent of rocks
per hex large (3 to 5 units); at least one wreck piece per 3
hexes clearly larger (6 to 9 units); 2 to 3 sub-clumps per hex;
dust haze tan #d4bf86 at alpha 0.06 to 0.10; clear zone radius
4 units around each ship hex centre.
- Lives in: terrain fx synthesis section 2.4; issue 100 builds
  it.
- Provenance: ASSUMED. Evidence: research specification values;
  the shipped code (AS12, AS13) was written to different
  numbers (per-hex counts and a scale range topping at 3.8), so
  the spec's 6 to 9 unit wreck size has no counterpart in code
  read for this pack.
- If wrong: the spec and the code describe two different debris
  fields; issue 100 will "implement the spec" against code that
  already implements something else, and the review will
  adjudicate the difference by eye without knowing it exists.
- Settles it: one reconciliation pass listing spec versus code
  per value before issue 100 runs, one Opus run. One-time.

AS17. Blocker hero rock: one hero rock 13 to 15 units long per
blocking placement, with 2 to 4 satellites of 2.0 to 4.4 units.
- Lives in: backdrops synthesis (scale plan), via
  godot/world/blocker_visuals.gd and world_rocks.gd placement.
- Provenance: ASSUMED. Evidence: a research design adopted
  without a size sweep; the hero length is denominated in units
  at board distance, unlike the backdrop fields' angular law
  (AS1), so the two rock systems in the same game use two
  different size currencies.
- If wrong: blockers are the rocks nearest the action; their
  size against a ship's length is the game's most-read scale
  comparison, set here by an unswept range.
- Settles it: one battle sheet with a blocker at 13 to 15 and
  at 20 units, judged against the ships beside it, one owner
  review round on an existing run.

AS18. Largest debris piece cap: no debris piece larger than
half the hex flat width, 8.66 units.
- Lives in: backdrops synthesis (debris size rules).
- Provenance: DERIVED. Evidence: arithmetic on the ruled hex
  geometry (HS 10, flat width 17.32); the derivation is sound,
  but the input choice (half the flat width, rather than a
  third or the full width) is a design pick, and AS16's spec
  allows wreck pieces of 6 to 9 units, which crosses this cap
  at its top end. The two adopted documents disagree by 0.34
  units at exactly the size that matters most.
- If wrong: the cap and the spec cannot both be built; a
  builder following AS16 violates AS18 without knowing, and a
  reviewer cannot say which document was disobeyed.
- Settles it: settled by the same reconciliation as AS16, one
  Opus run, shared settlement.

## 6. Backdrop and starfield inventory (BD1 to BD19)

Tallies for this section: 19 entries; MEASURED 0, DERIVED 0,
ANCHORED 0, ASSUMED 19. The fog grid baseline and its proposals
are fx items E14 and E15; star occlusion targets are E18.

BD1. Sky bake resolution: 4096 by 2048 (see PL13 for the
quality ladder below max).
- Lives in: godot/world/world.gd (_load_sky); world_bake.gd
  bake path.
- Provenance: ASSUMED. Evidence: a shipped constant shared with
  the planet bake (E22's canvas); no capture in the record
  compares the sky at two resolutions at the 4K camera, and the
  sky is the largest single surface in every frame.
- If wrong: the sky is half of every screenshot; an undersized
  bake caps the whole game's perceived resolution, an oversized
  one pays memory and bake time (PL12) for invisible texels.
- Settles it: one sky baked at 4096 and 8192 wide, sheeted at
  4K, one Codex run plus one owner review round. One-time.

BD2. Sky march steps: max 48, high 40, low 26 in the loader;
the bake shader runs a uniform 40 steps inside a 64-iteration
loop cap.
- Lives in: godot/world/world.gd (_load_sky); world_shaders.gd
  (sky bake shader).
- Provenance: ASSUMED. Evidence: shipped constants in two
  places that do not obviously agree (the loader's per-tier
  numbers and the shader's uniform 40); no banding or gradient
  quality check exists in the record for any step count.
- If wrong: march steps are the sky's gradient quality; too few
  band the nebula backdrop, and a loader value the shader
  ignores is a dead dial that future tuning will turn in vain.
- Settles it: one bake at 26 and 64 steps compared for banding,
  folded into the BD1 run, one owner review round.

BD3. Radiance bake size: 256.
- Lives in: godot/world/world.gd (_load_sky).
- Provenance: ASSUMED. Evidence: a shipped constant with no
  stated role check; the record does not show what consumes the
  radiance bake at this size or what a larger one buys.
- If wrong: lighting ambience from the sky is set by a number
  nobody has varied; too small washes scene light, too large
  pays bake time per map.
- Settles it: one A/B capture at 256 and 512, folded into the
  BD1 run, one owner review round.

BD4. Sky lamps: up to 6 lamps (2 + round(nebula factor times
4)); lamp strength 0.25 to 0.9, first lamp multiplied by 1.3.
- Lives in: godot/world/world_sky.gd (lamp build).
- Provenance: ASSUMED. Evidence: shipped formulas; lamp count
  scales with the region nebula factor (BD10), a coupling no
  research document in the record describes.
- If wrong: sky lamps are the environment's light on ships; a
  count and strength law set by formula means scene lighting
  varies by region table accident, not by art direction.
- Settles it: one battle sheeted under two region lamp counts,
  folded into an existing run, one owner review round.

BD5. Galaxies: up to 5 (2 + round((1 - nebula factor) times
3)); galaxy angular size 0.004 to 0.012 rad.
- Lives in: godot/world/world_sky.gd (galaxy build).
- Provenance: ASSUMED. Evidence: shipped formulas; the inverse
  coupling to nebula cover (more gas, fewer galaxies) is a
  composition law with no sheet behind it.
- If wrong: galaxies are the deep-sky landmarks; rationing them
  by an inverse formula can leave nebula maps, the showcase
  maps, with the emptiest deep sky.
- Settles it: folded into the BD1 sky sheets, one owner review
  round.

BD6. Star layers: three layers at scales 120, 300, 650;
thresholds 0.955, 0.985, 0.994; gains 1.0, 0.55, 0.35.
- Lives in: godot/world/world_sky.gd (star layer build).
- Provenance: ASSUMED. Evidence: shipped constants; thresholds
  this close to 1.0 mean small changes swing star density
  enormously, and no density count (stars per steradian at the
  battle camera) exists anywhere in the record.
- If wrong: star density is the backdrop's base texture; too
  dense reads as noise and fights the ships, too sparse reads
  as emptiness, and the current settings were never counted,
  only inherited.
- Settles it: a star density count plus one sheet at a relaxed
  threshold set, one script build (one-time) plus one owner
  review round.

BD7. Galaxy band: band density adds 0.03, 0.012, 0.004 across
the star layers; band core width 0.17, wide component 0.42;
rift width 0.06.
- Lives in: godot/world/world_sky.gd and world_shaders.gd (band
  construction).
- Provenance: ASSUMED. Evidence: shipped constants; the band is
  the sky's main structure and its widths were never sheeted at
  alternatives.
- If wrong: the band decides whether the sky has a "milky way"
  or a smudge; its width against the PL1 planet placement band
  decides most compositions.
- Settles it: folded into the BD1 sheets, one owner review
  round.

BD8. Star dimming through gas: star brightness mixes from 0.15
to 1.0 by the nebula alpha factor T.
- Lives in: godot/world/world_sky.gd (star dimming).
- Provenance: ASSUMED. Evidence: the shipped mechanism behind
  R82 Q2 (gas dims stars and sky only); the 0.15 floor is
  unmeasured against the E18 occlusion targets, which are
  denominated in percentages of brightness and may or may not
  describe this same mix.
- If wrong: two documents govern star dimming (this floor and
  E18's targets) without a stated relationship; builders can
  satisfy either and miss the other.
- Settles it: the E18 settlement (density sweep capture with
  star brightness sampled) settles both if this floor is named
  in it, one script annotation on an existing run.

BD9. Bake saturation push: 1.45 applied in the sky bake.
- Lives in: godot/world/world_sky.gd (bake grade).
- Provenance: ASSUMED. Evidence: a shipped grade constant; no
  before and after in the record, and a 45 percent saturation
  push interacts with NB4's channel caps in ways no document
  traces.
- If wrong: a global grade this strong can be the real author
  of the "mauve and brown" failures the NB4 caps were written
  to prevent; fixing the caps while the grade pushes the other
  way wastes builds.
- Settles it: one bake at 1.45 and at 1.15 sheeted side by
  side, folded into the BD1 run, one owner review round.

BD10. Region table: six regions (frontier, nebula, world,
boneyard, deep, deadstar), each carrying nebula, cover, dust,
band, stars, warm, rocks, and tint parameters.
- Lives in: godot/world/world_sky.gd (region table); consumed
  by world.gd field counts (AS2) and sky build.
- Provenance: ASSUMED. Evidence: the table is the single point
  where most of this pack's numbers meet (it feeds AS2 counts,
  BD4 lamps, BD5 galaxies, BD6 stars), and its per-region values
  were never sheeted region by region in the record read.
- If wrong: one table silently art-directs every map in the
  game; an off value does not break one map, it breaks a sixth
  of the campaign's sky.
- Settles it: a six-region contact sheet at the battle camera,
  one script build (one-time) plus one owner review round. This
  is the cheapest high-coverage settlement in the pack.

BD11. Battle sky yaw: the sky is yawed -0.35 to 0.35 rad for
battle.
- Lives in: godot/world/world_sky.gd (battle orientation).
- Provenance: ASSUMED. Evidence: a shipped range; no record of
  what the yaw is for (composition variety, band placement) or
  what breaks outside it.
- If wrong: a small range means near-identical sky orientation
  every battle; an arbitrary one risks the band crossing the
  planet placement zone (PL1) in ways nobody checked.
- Settles it: folded into the BD10 contact sheet (yaw is
  visible there), one owner review round.

BD12. Bake march shell: radius 0.55 to 1.6 in the sky shader.
- Lives in: godot/world/world_shaders.gd (sky bake shader).
- Provenance: ASSUMED. Evidence: shipped shader constants; the
  shell bounds where nebula density can exist in the bake, and
  no document in the record describes the choice.
- If wrong: the shell is the sky nebula's depth range; too thin
  flattens the baked gas into a dome painting, which the volume
  work in issue 139 cannot fix because this is the sky, not the
  patches.
- Settles it: folded into the BD1 bake comparison (shell is a
  bake parameter), one owner review round.

BD13. Sky wisps: count 26 + 34 times the nebula factor; sizes
180 to 520; radius 300 to 1500; depth 80 to 520 below the
board; gain 0.06; off at low quality.
- Lives in: godot/world/world.gd (wisps function).
- Provenance: ASSUMED. Evidence: shipped values; wisps are
  large, faint, and below the board, and no capture in the
  record isolates their contribution, so their gain of 0.06 may
  be invisible or may be the depth cue that matters.
- If wrong: either a whole subsystem pays draw and fill for
  nothing, or the board's underside depth (the battle camera
  looks down) is carried by a 0.06-gain afterthought.
- Settles it: one capture with wisps off, folded into an
  existing run, one owner review round.

BD14. Backdrop fog constants: fog density 0.0001, albedo
(0.42, 0.44, 0.5), anisotropy 0.6, sky affect 0.15.
- Lives in: godot/render/backdrop.gd line 53 area. (Fog length
  400 and the froxel grid are fx item E14.)
- Provenance: ASSUMED. Evidence: shipped constants; the albedo
  is a grey-blue that tints everything distant, and no document
  in the record discusses the backdrop fog's colour as a
  choice.
- If wrong: fog albedo is a colour grade applied to the whole
  environment at distance; a wrong grey here is in every shot
  and attributed to everything else.
- Settles it: one sheet at a warmed and a cooled albedo,
  folded into the BD1 run, one owner review round.

BD15. Interim backdrop dressing formula: ring radius R0 =
board bounds length times 0.62 + 40; radial scale 1.6x; heights
scaled 2x minus 70 (large rocks) or minus 45 (field rocks);
rock scale 1.6x (large) or 1.3x (field); seed 7;
asteroids.json as the source population.
- Lives in: godot/render/backdrop.gd (interim dressing).
- Provenance: ASSUMED. Evidence: the file presents this as
  interim dressing, and it is still the shipped backdrop path
  in the code read; its multipliers are anchored on the board
  bounds, so the dressing rescales itself whenever the board
  does, with no sheet in the record judging the result.
- If wrong: "interim" scaffolding that ships is the design;
  its hidden coupling to board size means map changes retune
  the sky without anyone deciding to.
- Settles it: one capture comparing the interim dressing
  against the world.gd fields on the same map, one Codex run
  plus one owner review round. One-time.

BD16. Tactical zone tints as shipped: nebula alpha 0.075,
debris 0.065, storm 0.065 on the board.
- Lives in: godot/render/board.gd line 325 (ZONE_TINT).
- Provenance: ASSUMED. Evidence: shipped values roughly half
  the terrain synthesis's specified tints (0.16, 0.12, 0.13);
  R82 Q3 ruled "tint reduced, faint tint kept" and a later
  tuning task landed these, but no document records the halving
  as a decision, so spec and code disagree by 2x with the
  ruling covering both readings.
- If wrong: zone tints are how a player reads terrain type at a
  glance; a 2x ambiguity between the spec a builder reads and
  the code that ships is the AS14 pattern in miniature.
- Settles it: reconcile spec text to shipped values in one
  Opus run (documentation settlement; no build), or sheet both
  strengths if the chair prefers, one owner review round.

BD17. Board look parameters, cine default: underlay 0.45,
terrain edge 0.9, gas edge 0.9, gas factor 0.3; living look gas
factor 1.0 and terrain edge 0.3; looks cycle on F8, persisted
to user://board_look.cfg; cine is the owner-picked default
(Nov 1, 2026).
- Lives in: godot/world/board_look.gd.
- Provenance: ASSUMED. Evidence: the default look was an owner
  pick; the per-look parameter values themselves were never
  sheeted against alternatives, and every research capture in
  the record is judged in whichever look the build defaulted
  to, which is not always recorded.
- If wrong: the look multiplies every other number in this
  pack at judgement time; a gas edge of 0.9 in cine versus 0.3
  in living means legs and owners may be judging different
  games from the same build.
- Settles it: state the look on every future sheet (process
  settlement, no cost), plus one cine versus living side by
  side on a nebula map, one owner review round.

BD18. Quality tier table: max (MSAA 4x, shadow atlas 4096, all
features), high (MSAA 2x, smaller shadows, no SSIL), low (no
MSAA, FXAA, shadow atlas 2048, no SSAO or volumetric haze, TAA
off).
- Lives in: godot/scenes/battle/battle.gd (_apply_quality).
- Provenance: ASSUMED. Evidence: shipped tier definitions; as
  the fx pack noted, no tier has a measured frame cost anywhere
  in the record, yet NB12, NB13, AS3, BD13, and PL13 all hang
  real content decisions on these three tiers.
- If wrong: the tiers are the load-bearing structure under at
  least five other inventory items; if the tier costs are
  upside down (a cheap feature cut, an expensive one kept), the
  ladder misallocates on every machine below max.
- Settles it: the issue 207 benchmark run per tier with the
  environment on, one Opus run; the environment share is named
  by the already-directed effects-off isolation run.

BD19. Dead star well specification: core radius 15 units;
lensing ring rotation about 30 seconds; ripples every 3 to 4
seconds travelling inward over 2 seconds at alpha about 0.12;
infalling dust 1 to 2 per hex, size 0.5 to 1, alpha 0.15,
drifting inward at about 1 unit per second at the edge
accelerating to about 3 near the centre with a tangential
component about 20 percent of radial; accretion hint ring
alpha 0.10 to 0.20 rotating once per about 45 seconds; well
light OmniLight3D energy 1.6, range Rsh times 14, attenuation
1.6, colour (1.0, 0.6, 0.3).
- Lives in: terrain fx synthesis section 2.5; FINDINGS R82 Q4
  (structure stated at subtle brightness); issue 100 carries
  the well as a build task.
- Provenance: ASSUMED. Evidence: every figure is a research
  specification value; R82 Q4 ruled only the qualitative point
  (subtle brightness), and no capture of a built well exists in
  the record against which any of these numbers was checked.
- If wrong: the dead star is the campaign's signature location;
  a dozen unmeasured constants decide whether it reads as a
  subtle dread or a screensaver, and issue 100 builds them all
  at once, so a miss cannot be attributed to any one of them.
- Settles it: the issue 100 before and after stills, reviewed
  constant by constant against this list, one owner review
  round; variants cost one Codex run if the first build misses.


## 7. Stations as environment inventory (ST1 to ST10)

Tallies for this section: 10 entries; MEASURED 0, DERIVED 0,
ANCHORED 0, ASSUMED 10. The graphics red team already settled
the station ceiling's status (section 1.2); ST5 inventories the
one place the code has not caught up with that settlement. The
ship versus station close-band asymmetry is graphics red team
item C40 and is background here, not an item.

ST1. Additions-only doctrine: the R94 station shapes are
locked; no locked primitive may be moved, resized, or deleted;
all detail arrives as additions on the locked shapes.
- Lives in: FINDINGS R100 (adopting the station detail brief);
  issue 183 done-when; tools/blender/hs/station_kit.py line 936
  area (the frozen-primitive assert).
- Provenance: ASSUMED. Evidence: an owner-adopted chair pick
  whose basis was protecting an approved silhouette; it has
  never been tested against a rebuild, and R109's complaint
  ("super plain and just like regular shapes") is a complaint
  about exactly the shapes the doctrine freezes.
- If wrong: the doctrine decides every future station job's
  shape space; if the plainness lives in the locked primitives
  rather than the surface, additions can only decorate the
  problem, at full detail-pass cost per attempt.
- Settles it: the issue 199 sheets are the test in progress; if
  they miss the owner's bar, one comparison build with the
  doctrine relaxed on one station, one Codex run plus one owner
  review round.

ST2. Additions at least 2 units proud: height and asymmetry
must come from additions standing at least 2 units off the
locked surface.
- Lives in: issue 183 done-when; station detail synthesis
  section 1; asserted in station_kit.py line 939 (dorsal tops
  minus 2 >= 2).
- Provenance: ASSUMED. Evidence: a brief value with no
  silhouette study behind it; 2 units at the battle camera
  (about 170 units out) is about 1 percent of the frame height,
  and no sheet in the record shows an addition at 1, 2, and 4
  units side by side.
- If wrong: the floor decides whether additions read as
  silhouette or as surface noise from the battle camera; too
  low and the whole detail pass is invisible where it is
  judged, too high and stations grow spikes by rule.
- Settles it: one station sheeted with additions at 2 and 4
  units proud, folded into the issue 199 run, one owner review
  round.

ST3. Frozen geometry assert set: total station length exactly
46 units; dorsal tops exactly [4.5, 5.0, 4.0, 6.5]; gantry
crossbeam top exactly 9; secondary process column under 12;
skyline must rise to z >= 15.
- Lives in: tools/blender/hs/station_kit.py lines 205 to 206
  and 938 to 942.
- Provenance: ASSUMED. Evidence: the values are the R91 and R94
  approval state frozen into asserts; the asserts verify the
  present faithfully (that part is code-checked on every kit
  run), but no measurement or sheet chose 46, 9, or 15 over
  their neighbours, and exact-equality asserts mean any future
  silhouette improvement fails the build by construction.
- If wrong: the kit cannot produce a better station even when a
  builder finds one; the approval of one moment's shapes has
  become a permanent geometry law.
- Settles it: convert exact equalities to reported values
  (triangles and ms are already reported under the Nov 6
  rulings), keeping the R94 shapes as the default build, one
  Opus run. One-time.

ST4. Station design target: about 20k triangles and 0.35 ms
per station.
- Lives in: FINDINGS R100; graphics red team item C59.
- Provenance: ASSUMED. Evidence: the graphics red team's
  finding stands: the target was set over a baseline that has
  never been counted; no triangle count or timing of the
  current stations exists in the record. Under the Nov 6
  rulings the target stands only as assumed reporting.
- If wrong: issue 199's detail pass is briefed to aim "well
  under" a ceiling derived from this target (its done-when
  cites the R96 ship ceiling), so an uncounted baseline steers
  the one station job currently queued.
- Settles it: one unattended count and timing of both current
  stations, one script build (one-time). This is the cheapest
  settlement in the pack relative to what it unblocks.

ST5. The removed ceiling that still asserts: the owner removed
the tri half of the station hard ceiling (40k fleet, 45k
refinery) on Nov 6, 2026; the millisecond half (1.0 ms) stands
as assumed reporting. But station_kit.py line 949 still
asserts triangles_roundtrip <= 40000 (fleet) or 45000
(refinery) on every detail export.
- Lives in: tools/blender/hs/station_kit.py line 949; the
  removal in the graphics red team rulings (issue 208 carries
  them to Opus).
- Provenance: ASSUMED. Evidence: the assert encodes R100's
  ceiling, which the owner has since removed in its tri half;
  the code was read on main on Nov 6, 2026, after the ruling,
  and the assert is still live. The ruling and the build gate
  currently contradict each other.
- If wrong: the first detail build that crosses 40k triangles
  fails its own kit check for a ceiling that no longer exists,
  and the failure will read as a quality problem instead of a
  stale assert; or a builder silently edits the assert and the
  change is never recorded as the ruling it implements.
- Settles it: remove or convert the assert to a reported value
  per the Nov 6 rulings, one Opus run (folds into issue 208's
  settlement program). One-time.

ST6. Tall element bans: no second tall element on the refinery
in this pass; no tall element on the fleet station's working
face.
- Lives in: FINDINGS R100 (two of the five adopted picks);
  issue 183 done-when.
- Provenance: ASSUMED. Evidence: chair picks adopted to protect
  the approved silhouettes' read; "tall" is not given a number
  anywhere in the record, so the ban's boundary is a judgement
  each reviewer makes privately.
- If wrong: silhouette variety is the stations' known weakness
  (R94's own note: they read as flat frames); an unnumbered ban
  on the main remedy can outlive the pass it was scoped to,
  because nothing in its text expires it.
- Settles it: the issue 199 sheets judged with the bans' scope
  stated on them (this pass only), one owner review round;
  expiry costs one line in the issue 208 settlement.

ST7. Break treatment exemption: thin truss and gantry members
get damage decals instead of interior faces at break lines,
exempting them from the breakable-by-design interior rule
(R98).
- Lives in: FINDINGS R100; station detail synthesis.
- Provenance: ASSUMED. Evidence: an adopted pick trading
  break fidelity for build cost on thin members; no broken
  station capture exists in the record to show what the
  exemption looks like when a truss actually breaks.
- If wrong: stations are scenery until they are targets; a
  truss that breaks into a decal-covered shell may read as a
  cheat exactly at the destruction moment the game sells.
- Settles it: one broken-truss capture from the first station
  break test, folded into the destruction work when it runs,
  one owner review round.

ST8. In-game station sizing: a station occupying a cluster of
5 or more hexes sizes to 46 units; below that, 22 + 4 per hex;
the model is lifted 3 units.
- Lives in: godot/render/board.gd lines 716 and 762 to 776
  area (station placement and sizing).
- Provenance: ASSUMED. Evidence: shipped formula; the 46 at 5
  hexes matches the kit's frozen length (ST3) by construction,
  but the sub-5-hex branch (22 + 4 per hex) produces stations
  the Blender kit never builds, and no sheet in the record
  shows a small station.
- If wrong: two sizing systems (kit and board) agree only at
  the one size the kit asserts; every other station size in the
  game is unbuilt, unshot, and unjudged.
- Settles it: one capture of a 3-hex station, folded into an
  existing run, one owner review round.

ST9. Two station variants: exactly two kinds (fleet station
and refinery) from one Blender kit built from the game's own
ship parts, for the whole game.
- Lives in: FINDINGS R79 (owner ruling); station_kit.py.
- Provenance: ASSUMED. Evidence: an owner ruling from the
  backdrops research; the variety question (PL4's pattern in
  miniature) was not revisited when R109 demanded far more
  surface richness, and issue 199 deepens the same two variants
  rather than widening the set.
- If wrong: every station a player ever docks at or fights over
  is one of two silhouettes; depth on two variants may be worth
  less than a third variant at half depth, and no sheet has
  ever priced the trade.
- Settles it: an owner direction question, not a build: whether
  issue 199's depth or a third variant serves the game better
  (carried in the legs' owner questions if they judge it
  ripe). Cost: one owner review round to decide.

ST10. Kit documentation drift: STATION_KIT.md still describes
the kit as an issue 61 proxy gate with the live board
unchanged; the kit has since carried issues 183, 195, and 199.
- Lives in: tools/blender/hs/STATION_KIT.md (56 lines, read
  Nov 6, 2026).
- Provenance: ASSUMED (as a gate: it gates nothing, which is
  the finding). Evidence: the document's framing predates three
  merged station jobs; a builder who trusts it misreads what
  the kit is for and which asserts are current (see ST5).
- If wrong: stale kit documentation is how stale asserts (ST5)
  survive: the doc that would explain the assert no longer
  describes the kit that contains it.
- Settles it: one documentation pass over STATION_KIT.md
  against the current kit, one Opus run. One-time.

## 8. Chair observations (hypotheses for the legs to test)

These are the chair's starting suspicions, recorded so the legs
can attack or confirm them. They are INFERRED, they are not
findings, and a leg that merely repeats them has done no work.

H1. The angular cap is this stack's 306k ceiling. AS1's 0.05
rad was a composition preference adopted for tidiness and then
asserted in code; PL8's 4.4x margin compounds it; AS8 shows the
largest backdrop form (mountains) is actually sized by the cap,
not by its own range. If the R88 "hollow asteroids" verdict has
a single numeric root, this pair is the chair's candidate: a
sky in which nothing may loom reads as a shell seen from
inside.

H2. This stack's disease is not anchored numbers but silent
disagreement between settled documents. AS14 (two adopted
tumble standards differing by 2 to 3x), AS16 against AS18
(wreck size spec crossing the debris cap), BD16 (zone tints at
half the specified strength), NB1 (shipped nebula bands
matching neither the spec's bands nor any ruling), BD8 against
E18 (two star dimming regimes). Each pair is individually
small; together they mean builders and reviewers are routinely
working from different "specs," and the failures surface as
unattributable look problems.

H3. Almost nothing in this stack was ever counted. The tally
(1 MEASURED in 74) is worse than the ship stack (4 in 65) and
the fx stack (13 in 76) because environment work was specified
in research syntheses and then built straight into code
constants, skipping the sheet-and-measure step the ship work
eventually got. The cheapest settlements in the pack (ST4's
station count, BD10's region contact sheet, PL4's looks contact
sheet) are all counts and contact sheets, not builds.

H4. The region table (BD10) is the stack's hidden multiplier.
It feeds field counts, lamp counts, galaxy counts, star
parameters, and dust at once. A single off value does not
break one feature; it tilts every map in a region. No other
single item in the pack has that blast radius, and it is also
the item with the least review surface (its values appear in
no synthesis the chair read).

H5. Tier hangers multiply unmeasured structure. BD18's tiers
have no measured cost per tier, yet NB12, NB13, AS3, BD13, and
PL13 all assign real content to tiers. This is the fx pack's
H4 recurring in the environment stack, with the same settlement
(the issue 207 per-tier benchmark) available.

H6. Variety may be the real gate, and it is a count, not a
constant. 8 planet looks (PL4), 2 station variants (ST9), 1
nebula colour family (NB6), 6 regions (BD10). The owner's
complaints in this domain are consistently about sameness and
plainness (R88, R109), and every queued job raises fidelity
inside the existing counts. No queued job raises a count. The
legs should say whether fidelity inside fixed variety can
reach the AAA objective, or whether the counts themselves are
the constricting gates.

H7. Interim and frozen are the same failure at two ends.
BD15's interim dressing still ships; ST3's frozen asserts
cannot move. Both convert a moment's expedient into permanent
law without a decision. The legs should look for other
instances the chair missed (the pack's own candidate: PL11's
procedural-only route, ruled before the current quality bar
existed).

## 9. Limitations and unverified list

What this red team cannot settle from documents, and claims
the chair could not source:

1. The current build's actual appearance, everywhere. This
   pack is built from code constants, rulings, syntheses, and
   issue texts. No Godot project was run and no capture was
   taken for this pack. A constant inventoried as shipped is a
   code fact, not a look fact.
2. Line numbers are as read on main on Nov 6, 2026. Where the
   chair could verify a line exactly, it is given (world.gd
   27, 373, 842 to 845, 106, 1264; world_bake.gd 6, 10, 11;
   world_living.gd 37, 747 to 748; board.gd 325;
   station_kit.py 205 to 206, 936 to 949). Elsewhere the pack
   names the file and function instead, and legs must not
   invent line numbers the pack does not give.
3. world_rocks.gd was read, but most rock field construction
   lives in world.gd; if a field constant lives only in
   world_rocks.gd or blocker_visuals.gd and is not in this
   inventory, that is an inventory gap for the Argon leg to
   name, not a licence to invent it.
4. The enginetest asteroids.json figures (AS11) are carried
   from the backdrops research record; the JSON file itself was
   not re-read line by line for this pack.
5. Whether issue 139's or 140's branches have already changed
   any inventoried constant: both issues are open and blocked,
   and this pack inventories main. If a branch moved a number,
   the inventory item stands for main and the branch is a
   settlement in progress.
6. STATION_KIT.md's staleness (ST10) is judged from its framing
   text; the chair did not diff every kit function against the
   document.
7. Perceptual questions generally. Whether a 0.09 rad rock
   looms pleasantly or clutters, whether 8 planet looks are
   enough for a campaign, whether the dead star well reads
   subtle or empty: no document settles these. Each needs the
   owner in front of a sheet or a capture, which is the Nov 6
   rulings' whole point.
8. The graphics leap synthesis's frame cost figures are
   INFERRED by its own header (no Godot project was run).
   Nothing in this pack repeats them as measurements.
9. Camera and presentation gates (battle camera distance and
   the 170-unit figure, zoom limits, screen shake) are NOT in
   this pack's scope; they are reserved for the destruction and
   camera pass the owner commissioned in the same instruction.
   Items here that cite the battle camera do so only as the
   environment's judgement distance.

## 10. Leg prompts

Four legs. The three writer legs (blind Rey, DeepSeek, Qwen)
run from this pack alone, in parallel, without seeing each
other. The Argon leg runs after them, as a review leg only.
The chair screens every leg before anything is adopted, per
the standing four-prong rule.

Disposition ground rule, from the owner's Nov 6, 2026 rulings,
binding on every leg: assumed and anchored numeric gates stop
binding. Do not propose re-deriving a number to a new fixed
value as the default settlement. Replacements are
measurements, consolidated specifications, or the owner's eye
on sheets. A leg that proposes a fresh cap must say what
measurement earned it.

The lenses, named by the owner and used identically in every
writer leg:

- Game dev lens: does this number or rule bind real
  performance or gameplay? Is it denominated in the metric the
  engine actually charges for? What happens in a real battle,
  on a real map, not in a specification?
- Domain designer lens: does this number or rule bind the
  craft of environment art? Does it buy real quality,
  readability, or atmosphere, and who pays when it is wrong:
  the sky's depth, the terrain's read, the scene's sameness?
- Agent lead lens: can the build pipeline actually produce work
  against this number or rule and measure the result? Is it
  enforceable in a review, on a sheet or a capture the owner
  judges, or does it hide in a constant nobody runs? Does it
  waste runs: rebuilds, re-reviews, adjudication per asset?

Cost units, the only ones permitted: Codex runs (one-hour cap
per run), Opus runs, one-time script builds, per-asset
unattended runs, owner review rounds. State one-time and
recurring costs separately.

---

### Blind Rey leg (writer)

You are a blind reviewer on a game project's environment and
backdrop standards. One file is your complete evidence and your
complete instruction: PACK.md, the evidence pack for a red team
of the environment and backdrop stack of the game Embers of
the Hollow Sun. You have no other sources. Do not browse, do
not use outside knowledge of this project beyond what the pack
contains, and do not invent facts the pack does not hold.

Task: answer the question in PACK section 1.3 for the inventory
in PACK sections 3 to 7 (NB1 to NB13, PL1 to PL14, AS1 to AS18,
BD1 to BD19, ST1 to ST10), in light of the standing rulings in
PACK section 1.2, the fx audit cross-references in PACK section
1.4, and the limitations in PACK section 9. The chair's
observations in PACK section 8 are hypotheses to test, not
conclusions to repeat.

Produce one report with exactly these parts:

1. Verdict: one of THE STACK HOLDS, THE STACK HOLDS ONLY WITH
   REPLACEMENTS, or THE STACK DOES NOT HOLD, applied to the
   environment stack as a whole, followed by the three
   inventory items your verdict most depends on, named by item
   number (they may be from any domains, but say why those
   three). A verdict of THE STACK HOLDS must state what
   evidence, if it appeared, would change it.
2. Game dev lens: attack every inventory item, NB1 to NB13,
   then PL1 to PL14, then AS1 to AS18, then BD1 to BD19, then
   ST1 to ST10, in order, one entry per item: does it bind real
   performance or gameplay, is it denominated in what the
   engine or the game actually charges for, and what does its
   being wrong cost in a real battle? An entry may be one line
   where the lens genuinely finds nothing; silence on an item
   counts as a miss and the review leg will flag it. Mark each
   entry OBSERVED (present in the pack; cite the pack section)
   or INFERRED (your reasoning; say what it rests on). If the
   pack lacks a fact you need, write NOT IN PACK.
3. Domain designer lens: the same items in the same order, for
   the craft of environment art: which numbers and rules buy
   real atmosphere, depth, and variety, which tax them without
   buying any, and what each error costs on the sheet or in the
   scene.
4. Agent lead lens: the same items in the same order, for
   production: can the pipeline build to it, can a review
   measure it on the owner's sheets or captures or does it hide
   in a constant nobody runs, and where does it waste runs
   (rebuilds, re-reviews, per-asset adjudication)?
5. Disposition table: every item, NB1 to NB13, PL1 to PL14,
   AS1 to AS18, BD1 to BD19, ST1 to ST10, one row each: KEEP,
   RE-DERIVE, REPLACE, or DROP; for RE-DERIVE and REPLACE, the
   replacement approach and its cost in the pack's agent-term
   units only; for DROP, what replaces the protection the item
   was giving, or the statement that none is needed. Apply the
   disposition ground rule in PACK section 10: a fresh cap
   needs a named measurement that earned it. A disposition that
   contradicts one of your own lens entries is an error.
6. Owner questions: at most three, each with your pick and one
   line on the stakes. Questions must be human-direction
   questions, not technical ones.
7. Not checked: what this report could not verify from the
   pack.

Hard constraints: no human-time estimates anywhere (no hours,
days, or weeks of human work); costs only in the units above.
No invented measurements, thresholds, or quotations. No em
dashes. Plain ASCII.

---

### DeepSeek leg (writer)

You are a blind reviewer on a game project's environment and
backdrop standards. One file is your complete evidence and your
complete instruction: PACK.md, the evidence pack for a red team
of the environment and backdrop stack of the game Embers of
the Hollow Sun. You have no other sources. Do not browse, do
not use outside knowledge of this project beyond what the pack
contains, and do not invent facts the pack does not hold.

Task: answer the question in PACK section 1.3 for the inventory
in PACK sections 3 to 7 (NB1 to NB13, PL1 to PL14, AS1 to AS18,
BD1 to BD19, ST1 to ST10), in light of the standing rulings in
PACK section 1.2, the fx audit cross-references in PACK section
1.4, and the limitations in PACK section 9. The chair's
observations in PACK section 8 are hypotheses to test, not
conclusions to repeat.

Produce one report with exactly these parts:

1. Verdict: one of THE STACK HOLDS, THE STACK HOLDS ONLY WITH
   REPLACEMENTS, or THE STACK DOES NOT HOLD, applied to the
   environment stack as a whole, followed by the three
   inventory items your verdict most depends on, named by item
   number (they may be from any domains, but say why those
   three). A verdict of THE STACK HOLDS must state what
   evidence, if it appeared, would change it.
2. Game dev lens: attack every inventory item, NB1 to NB13,
   then PL1 to PL14, then AS1 to AS18, then BD1 to BD19, then
   ST1 to ST10, in order, one entry per item: does it bind real
   performance or gameplay, is it denominated in what the
   engine or the game actually charges for, and what does its
   being wrong cost in a real battle? An entry may be one line
   where the lens genuinely finds nothing; silence on an item
   counts as a miss and the review leg will flag it. Mark each
   entry OBSERVED (present in the pack; cite the pack section)
   or INFERRED (your reasoning; say what it rests on). If the
   pack lacks a fact you need, write NOT IN PACK.
3. Domain designer lens: the same items in the same order, for
   the craft of environment art: which numbers and rules buy
   real atmosphere, depth, and variety, which tax them without
   buying any, and what each error costs on the sheet or in the
   scene.
4. Agent lead lens: the same items in the same order, for
   production: can the pipeline build to it, can a review
   measure it on the owner's sheets or captures or does it hide
   in a constant nobody runs, and where does it waste runs
   (rebuilds, re-reviews, per-asset adjudication)?
5. Disposition table: every item, NB1 to NB13, PL1 to PL14,
   AS1 to AS18, BD1 to BD19, ST1 to ST10, one row each: KEEP,
   RE-DERIVE, REPLACE, or DROP; for RE-DERIVE and REPLACE, the
   replacement approach and its cost in the pack's agent-term
   units only; for DROP, what replaces the protection the item
   was giving, or the statement that none is needed. Apply the
   disposition ground rule in PACK section 10: a fresh cap
   needs a named measurement that earned it. A disposition that
   contradicts one of your own lens entries is an error.
6. Owner questions: at most three, each with your pick and one
   line on the stakes. Questions must be human-direction
   questions, not technical ones.
7. Not checked: what this report could not verify from the
   pack.

Hard constraints: no human-time estimates anywhere (no hours,
days, or weeks of human work); costs only in the units above.
No invented measurements, thresholds, or quotations. No em
dashes. Plain ASCII.

---

### Qwen leg (writer)

You are a blind reviewer on a game project's environment and
backdrop standards. One file is your complete evidence and your
complete instruction: PACK.md, the evidence pack for a red team
of the environment and backdrop stack of the game Embers of
the Hollow Sun. You have no other sources. Do not browse, do
not use outside knowledge of this project beyond what the pack
contains, and do not invent facts the pack does not hold.

Task: answer the question in PACK section 1.3 for the inventory
in PACK sections 3 to 7 (NB1 to NB13, PL1 to PL14, AS1 to AS18,
BD1 to BD19, ST1 to ST10), in light of the standing rulings in
PACK section 1.2, the fx audit cross-references in PACK section
1.4, and the limitations in PACK section 9. The chair's
observations in PACK section 8 are hypotheses to test, not
conclusions to repeat.

Produce one report with exactly these parts:

1. Verdict: one of THE STACK HOLDS, THE STACK HOLDS ONLY WITH
   REPLACEMENTS, or THE STACK DOES NOT HOLD, applied to the
   environment stack as a whole, followed by the three
   inventory items your verdict most depends on, named by item
   number (they may be from any domains, but say why those
   three). A verdict of THE STACK HOLDS must state what
   evidence, if it appeared, would change it.
2. Game dev lens: attack every inventory item, NB1 to NB13,
   then PL1 to PL14, then AS1 to AS18, then BD1 to BD19, then
   ST1 to ST10, in order, one entry per item: does it bind real
   performance or gameplay, is it denominated in what the
   engine or the game actually charges for, and what does its
   being wrong cost in a real battle? An entry may be one line
   where the lens genuinely finds nothing; silence on an item
   counts as a miss and the review leg will flag it. Mark each
   entry OBSERVED (present in the pack; cite the pack section)
   or INFERRED (your reasoning; say what it rests on). If the
   pack lacks a fact you need, write NOT IN PACK.
3. Domain designer lens: the same items in the same order, for
   the craft of environment art: which numbers and rules buy
   real atmosphere, depth, and variety, which tax them without
   buying any, and what each error costs on the sheet or in the
   scene.
4. Agent lead lens: the same items in the same order, for
   production: can the pipeline build to it, can a review
   measure it on the owner's sheets or captures or does it hide
   in a constant nobody runs, and where does it waste runs
   (rebuilds, re-reviews, per-asset adjudication)?
5. Disposition table: every item, NB1 to NB13, PL1 to PL14,
   AS1 to AS18, BD1 to BD19, ST1 to ST10, one row each: KEEP,
   RE-DERIVE, REPLACE, or DROP; for RE-DERIVE and REPLACE, the
   replacement approach and its cost in the pack's agent-term
   units only; for DROP, what replaces the protection the item
   was giving, or the statement that none is needed. Apply the
   disposition ground rule in PACK section 10: a fresh cap
   needs a named measurement that earned it. A disposition that
   contradicts one of your own lens entries is an error.
6. Owner questions: at most three, each with your pick and one
   line on the stakes. Questions must be human-direction
   questions, not technical ones.
7. Not checked: what this report could not verify from the
   pack.

Hard constraints: no human-time estimates anywhere (no hours,
days, or weeks of human work); costs only in the units above.
No invented measurements, thresholds, or quotations. No em
dashes. Plain ASCII.

---

### Argon leg (review only, runs after the writer legs)

You are a review leg, not a writer leg. You receive four files:
PACK.md (the evidence pack) and the three writer leg reports
(blind Rey, DeepSeek, Qwen) for the environment and backdrop
red team on Embers of the Hollow Sun. Do not write a new
verdict of your own. Audit the three reports against the pack.

Produce one report with exactly these parts:

1. Quotation and fact check: for each writer leg, list every
   measurement, threshold, rule, and provenance classification
   it states that does NOT match PACK.md, with the pack location
   (section or item number) that contradicts it or the note
   ABSENT FROM PACK. List every leg statement marked OBSERVED
   whose cited pack section does not contain it. Pay particular
   attention to any leg that reclassifies an item's provenance
   (sections 3 to 7) without evidence the pack contains, to any
   leg that treats a settled Nov 6 ruling (PACK section 1.2) as
   open, and to any leg that duplicates an fx audit item (PACK
   section 1.4) as if it were new inventory.
2. Arithmetic check: recompute every number a leg derives (the
   AS14 tumble period to rad per second conversions, the PL9
   planet cap arithmetic, the AS18 hex width arithmetic, the
   AS8 cap interaction, percentage and ratio claims). List each
   derivation as CONFIRMED or WRONG, with the corrected value
   when wrong.
3. Missed-item check: the pack inventory is NB1 to NB13, PL1 to
   PL14, AS1 to AS18, BD1 to BD19, ST1 to ST10. For each writer
   leg, list every item number absent from any of its three
   lens sections, and every item number absent from its
   disposition table. Also list any numeric gate or standing
   rule a leg relies on that is not in the inventory at all,
   flagged as either a genuine inventory gap (name it) or an
   invention (part 1).
4. Constraint check: flag any human-time estimate, any em dash,
   any cost stated outside the pack's agent-term units, and any
   owner question beyond the three-question cap, per leg. Also
   flag any disposition that contradicts the same leg's own lens
   entries, and any proposed fresh cap that names no measurement
   that earned it (PACK section 10 ground rule).
5. Adopt/cut list: for each writer leg, an exact list: ADOPT
   (finding, lens entry, or disposition identifiers), CUT
   (identifiers, with the reason tied to parts 1 to 4), and FLAG
   (identifiers that are sound only with a correction you
   state).
6. Not checked: what this review could not verify.

Hard constraints: the pack is the sole evidence; do not browse
and do not supply project, environment, or rendering facts of
your own. If a writer leg and the pack disagree, the pack wins
and the disagreement is a finding. No em dashes. Plain ASCII.
