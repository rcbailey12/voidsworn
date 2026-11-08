# Evidence pack: red team of the Voidsworn effects, animation, and sound stacks

Job: a red team of every numeric gate, tier rule, budget figure,
count limit, and standing assumption in three presentation stacks
of Embers of the Hollow Sun (Voidsworn): effects (deaths, weapons,
damage surfaces, nebulas and ion storms, planets, debris),
animation (ship movement, hit reactions, turrets, squadrons, death
choreography, campaign map flight), and sound (the cue system,
music, mixing, licences). Four legs run from this pack: three
writer legs (blind Rey, DeepSeek, Qwen) and one review leg (Argon).
The chair screens every leg before anything is adopted.

This pack is the legs' complete evidence. It is built from
FINDINGS rulings and board records, the graphics leap research
(issue 135 synthesis), the terrain fx research, the damage surface
research, the A5 effects sheets synthesis, the battle sound
synthesis (issue 82 job), issues 100, 101, and 137 to 140, the
engine vet pack, and the ceiling vet record. Where this pack and a
leg disagree, the pack wins. Where a source document and this
pack's summary of it disagree, the source wins and the
disagreement is a finding.

## 1. Framing

### 1.1 The owner's instruction

Ryan Bailey, Nov 6, 2026: having ripped the assumed and anchored
numeric gates out of the graphical standards that morning, he
extended the same suspicion to the rest of the presentation work,
in substance: do not get stuck on example numbers; truly test what
is possible with all of these approaches, aiming at AAA style
graphics; and look at this approach for effects, animation, and
sound too, since he assumes the same issue exists there, random
gates and assumptions that were never measured.

### 1.2 The worked example: the graphical standards red team

The graphics red team (Nov 6, 2026) inventoried 65 numeric
constraints across the performance ceiling, the readable paint
standard (issue 188), the surface detail standard (issue 200), and
the station budgets. Provenance tally: MEASURED 4, DERIVED 11,
ANCHORED 6, ASSUMED 44. The worked failure was the 306k triangle
ceiling: one incumbent hull's measured cost, promoted into a
performance law with no hardware capability test behind it, then
misread as a fleet total one standard later. The owner's rulings
that followed, and that govern this red team too:

- The assumed and anchored numeric gates were ripped out, not
  re-derived one by one. Bars and caps from the model testing era
  (the 7 of 9 paint bar, the detail share cap, the hero cap) are
  removed. A constraint earns its way back only by proving itself
  in builds.
- Tests run uncapped. Measurements exist to find where fidelity
  can scale UP and where performance forces scale DOWN. Numbers
  are reported (triangles, draw calls, surfaces, ms), never
  treated as pass or fail gates.
- Judgement is the owner's eye on sheets and in play, against the
  stated objective: AAA style graphics.
- Build routes are settled by head to head experiment (issue 209:
  hand build against sectioned AI generation, across a scale
  matrix), not by inherited rules about how assets must be made.

### 1.3 This red team's question

For every gate, cap, tier rule, and standing assumption in the
three stacks, answer three things:

1. What kind of number or rule is it? MEASURED (produced by an
   instrument, a code verification, or a counted delivery),
   DERIVED (computed from measured or ruled inputs, with the
   arithmetic or the standard shown), ASSUMED (a chosen threshold
   or design constant with no measurement or derivation in the
   record), or ANCHORED (the measured property of one incumbent
   asset, one test scene, or one external game, promoted into a
   rule).
2. What does it cost if it is wrong, in each of the three lenses:
   game dev (performance or gameplay), domain designer (the look,
   feel, or sound of the effect, animation, or audio itself),
   agent lead (pipeline effort, enforceability, wasted runs)?
3. What measurement, test, or build would settle it, and what does
   that cost in agent terms (section 1.5)?

A gate is artificial, in the owner's sense, when its number cannot
be traced to a measurement or a derivation but it still binds
builds, fails work, or spends review. A standing qualitative rule
counts as a gate for this audit when it forbids or mandates a
technique (a tier rule, a licence rule, a grammar rule), because
those bind builds exactly the way numbers do.

### 1.4 Honest scope notes

The three domains do not have the same shape of record, and the
pack does not pretend otherwise. Effects has a deep written
record: two research syntheses, one build specification, and code
constants quoted to the line. Animation has almost no dedicated
document at all: its record is a series of owner feel rulings in
FINDINGS (R50, R55, R64, R76, R88) plus timing bars from the
engine parity work, and the inventory reflects that thinness.
Sound has one research synthesis, one intake issue (101, closed),
and two code-verified defects; its central fact is a verification
gap, not a number (S15). Where a domain simply has no number for
something a designer would expect one for (turret turn rates,
squadron flight speeds), the pack says so as an inventory item
rather than inventing one.

### 1.5 Cost units

Costs in this pack, and in every leg, are stated only in agent
terms: Codex runs (one-hour cap per run), Opus runs, one-time
script builds, per-asset unattended runs, and owner review rounds
(including owner listen rounds for sound). No human-time estimates
anywhere (standing rule R99: the project's hour estimates kept
missing because they were anchored on human studio production, not
on the agent pipeline that does the work).

## 2. Evidence base

- FINDINGS (repo contrib/opus/FINDINGS.md, read from the ceiling
  vet source copy, current to R109): rulings R1, R3, R10, R16,
  R17, R21, R23, R27 to R31, R37, R40, R50, R51, R55, R64, R73,
  R76, R80, R82, R84, R88, R90, R100, R107; board records G-1,
  G-7, G-8, G-14; defect and decision rows D22, F19, K1, K2.
- LOOP.md (board state, Nov 5, 2026): the build queue order.
  Deaths (issue 137) and weapons (issue 138) are merged; nebulas
  and storms (139) and planets (140) are queued next; terrain fx 2
  (issue 100) sits at position 14, behind the Nemesis builds.
- Graphics leap research, issue 135 chair synthesis
  (contrib/muse/research/vfx_leap_2026_11/synthesis.md): the
  deaths and weapons, nebula and storm, and planet designs that
  issues 137 to 140 build. Its own header warns: no Godot project
  was run for it; every frame cost figure in it is INFERRED.
- Terrain fx research (contrib/muse/research/
  terrain_fx_2026_11/synthesis.md, ruled R82): nebula, storm,
  debris, and dead star well specifications and their constants.
- Damage surface research (contrib/muse/research/
  damage_surface_2026_11/synthesis.md, ruled R80): the staged
  damage spec, its thresholds, caps, and 20 ship budget.
- A5 effects sheets synthesis (contrib/muse/reviews/
  a5_effects_sheets_synthesis.md, Oct 25, 2026): per-weapon timing
  sheets, engine trail spec, the staged damage ladder, the death
  sequence, and the accessibility flash regime. Its SPEC pins are
  the Oct 25 engine test scene's design values. The A5 pass it
  specifies was never scheduled by name (FINDINGS K2, still open).
- Battle sound synthesis (contrib/muse/research/audio_2026_11/
  synthesis.md, the issue 82 job, ruled R82): the cue system, the
  mixing note, the voice caps proposal, and two pack-verified code
  defects. Its own header warns: nobody in the process has
  listened to any audio file.
- Issue 101 (closed; PR trail noted in section 6): the audio
  intake. Synth strip, CC0 packs plus the one approved CC BY
  source, music auditions through the loop tool, and a step 6
  listen pass that is the owner's sign-off and has not run.
- Issues 137 to 140 (137 and 138 closed, 139 and 140 open) and
  issue 100 (open): the build issues carrying the leap designs.
- Engine vet pack (Nov 6, 2026), sections 3.2 and 3.3: the G4
  effects pass state and the Oct 2025 engine test record.
- Graphics red team pack and synthesis (Nov 6, 2026): the method
  and the worked example in section 1.2.

## 3. Effects inventory (E1 to E34)

Template per entry: the value or rule and where it lives; its
provenance class with the evidence; what breaks if it is wrong;
what measurement would settle it. Tallies for this section:
34 entries; MEASURED 4, DERIVED 4, ANCHORED 3, ASSUMED 23.

E1. Effects performance target: 60 fps at 4K, with a lower
setting kept for weaker PCs.
- Lives in: FINDINGS R88 (owner ruling, Nov 3, 2026).
- Provenance: ASSUMED. Evidence: the ruling states the target and
  the headroom logic ("effects may spend the RTX 5080 headroom");
  no frame budget allocation, no minimum spec decision, and no
  measured effects cost stands behind the 60. The record contains
  no minimum spec GPU decision at all (the same gap the ceiling
  test found for hulls).
- If wrong: if real battles cannot hold it, every tier rule below
  is calibrated to a fiction; if it is easily held, effects are
  being underbuilt against the AAA objective.
- Settles it: the issue 207 benchmark extended with effects on
  (already directed Nov 6, 2026: an effects-off isolation run names
  the effects share), one Opus run.

E2. The G4 effects pass figure: 1 percent low of 43 to 65 fps at
20 ships on Forward Plus.
- Lives in: FINDINGS G-14 (2aac0ca); engine vet pack section 3.2.
- Provenance: MEASURED. Evidence: a recorded build figure. Caveat
  carried in the engine pack itself: the source line does not
  state the resolution, so it cannot be quoted as a 4K or 1080p
  figure, and the 43 to 65 range spans builds, not one scene.
- If wrong: it is the only measured effects performance number in
  the record; if its conditions are not what readers assume, E1
  looks closer or farther than it is.
- Settles it: the same benchmark protocol as the hull scene gate,
  with resolution and scene contents stated, one Opus run.

E3. Death budget split: the death frame budget goes to the first
2 seconds; the cooling tail stays a cheap shader.
- Lives in: FINDINGS R90 (adopting the issue 135 synthesis owner
  question 3, chair pick).
- Provenance: ASSUMED. Evidence: the synthesis argues from what
  reads at battle distance ("the break and the first tumble");
  the 2 second figure is a judgement, and the synthesis states no
  Godot project was run and all its frame costs are inferred.
- If wrong: spend lands on the wrong segment of the most judged
  moment in the game; either deaths feel cheap at the beat that
  matters or the tail eats steady budget for nothing.
- Settles it: two death builds at different splits on one hull
  class, sheeted and timed, one Codex run plus one owner review
  round.

E4. Cooling tail length: WRECK_COOL 14.0 seconds.
- Lives in: godot/fx/fx_death.gd (code constant, quoted in the
  issue 135 synthesis anchors); ruled as "the 14 s cooling tail"
  in R90.
- Provenance: ASSUMED. Evidence: a shipped code constant adopted
  into a ruling without a stated derivation or a comparison
  against other lengths.
- If wrong: wrecks either vanish emotionally before the player
  has registered the kill or linger as visual noise into the next
  activation; it also sets how long the E3 tail shader runs.
- Settles it: the same death sheeted at three tail lengths in a
  playtest build, one owner review round.

E5. Debris cap: 360 pieces in fx_death.gd.
- Lives in: godot/fx/fx_death.gd (quoted in the issue 135
  synthesis anchors).
- Provenance: ASSUMED. Evidence: a code cap with no recorded
  derivation, no stated interaction with the 20 ship worst case,
  and no measurement of when it binds.
- If wrong: either capital deaths visibly starve (pieces culled
  mid-breakup on the showcase event) or the cap never binds and
  debris cost is uncontrolled elsewhere.
- Settles it: a worst-case multi-death capture with the cap
  logged, one script annotation on an existing build run.

E6. Flash budget: at most 3 counted flashes per rolling second,
system-wide.
- Lives in: godot/fx/fx.gd lines 22 to 25 (the flash budget,
  unchanged by the leap); A5 sheets synthesis section 8.
- Provenance: DERIVED. Evidence: the A5 synthesis grounds the cap
  in WCAG 2.3.2, international photosensitive epilepsy guidance,
  Xbox Accessibility Guideline 118, and the Game Accessibility
  Guidelines flicker item; the counting definition (a brightness
  transition pair above a contrast step, merged inside a 0.33 s
  window) is the chair's merged construction on that basis.
- If wrong: too loose, a real photosensitivity risk ships; too
  tight or miscounted, salvos render dimmer than designed and
  the D7 art direction pass cuts legitimate punch.
- Settles it: the worst-case mixed salvo test the A5 synthesis
  itself specifies (every weapon kind plus heavy gauss, heavy
  torp volley, mass squadron deaths, flak screen) run against the
  counting rule before sign-off, one Codex run.

E7. Death choreography shape: a four-beat DeathTimeline (power
loss, vent, structural break, drift and cool) over about
2 seconds, the slicer extended from one cut to two or three
staged cuts.
- Lives in: issue 135 synthesis section 3; issue 137 done-when;
  ruled R90.
- Provenance: ASSUMED. Evidence: a design construction argued
  from reference grammar (Homeworld 3, EVE, The Expanse); the
  beat count itself was contested inside the job (the blind leg
  counted five beats; the chair left the count to whichever reads
  better in screenshots), which is the record admitting the shape
  is untested.
- If wrong: the signature moment of the game is choreographed to
  an unexamined rhythm; beat count and cut count drive the whole
  fx_death build and its bake list.
- Settles it: the D3 screenshots in issue 137 judged by the owner
  against one alternate cut, one owner review round.

E8. Tier rule for fog light: storm and explosion lights enter the
fog volumes at max tier only; a density pulse stands in at high;
none at low.
- Lives in: FINDINGS R90; issue 139 done-when; issue 135
  synthesis section 4.
- Provenance: ASSUMED. Evidence: a tier assignment made in a
  document whose frame costs are all inferred; no tier of the
  game has a measured frame cost anywhere in the record, so the
  assignment of the single largest nebula payoff to the top tier
  rests on an unmeasured cost fear. The current code deliberately
  excludes bolt lights from the fog (world_living.gd lines 473 to
  475), so the rule also reverses a prior deliberate choice at
  exactly one tier.
- If wrong: most players on high never see the effect the whole
  volume switch was bought for, or max tier carries a cost the
  5080 did not need to fear.
- Settles it: the N5 full-battle profile in issue 139, reported
  per tier, one Codex run.

E9. Damage stage thresholds: stage 1 at section hull fraction
f <= 0.8, stage 2 at <= 0.6, stage 3 at <= 0.4, stage 4 at <= 0.2
or broken.
- Lives in: godot/fx/fx_ship.gd sync() about line 748 (shipped);
  damage surface synthesis section 2 ("thresholds stay as
  shipped"); the open-break timing ruled R80.
- Provenance: ASSUMED. Evidence: shipped code constants the
  research explicitly kept without re-derivation; the research
  argued the stage contents at length and the thresholds not at
  all.
- If wrong: ships either look wrecked far too early (the R80
  complaint pattern) or read as untouched until they pop; every
  stage content rule and emitter cap in this section keys off
  these four numbers.
- Settles it: one hull played through a scripted damage ramp with
  captures at fine fraction steps, judged by the owner, one Codex
  run plus one owner review round.

E10. Scorch and heat ladder: primary scorch radius 0.064, 0.098,
0.132, 0.166 times ship length by stage; scorch heat 0.22, 0.35,
0.55, 0.75; dent radius 0.05 times length at 22 percent depth;
stage 4 throat radius 0.032 times length inside a collar of
diameter 0.14 times length; throat recess 15 to 20 percent of
length; 2 to 3 cross members of 12 to 18 triangles.
- Lives in: damage surface synthesis section 2.
- Provenance: DERIVED. Evidence: leg-converged values checked in
  the synthesis against a readability derivation (scorch diameter
  against the 10 px line at 1080p at the 170 unit camera, 7.7 px
  per unit); the parents of that derivation are the assumed
  camera scale and the paint standard's readability line, so the
  derivation is only as strong as they are. Several component
  numbers (recess band, cross member triangle counts) are stated
  without derivation inside the same section.
- If wrong: damage reads too small to see at the owner's 4K
  camera or so large it caricatures the hull; the numbers drive
  the issue 49 build's geometry directly.
- Settles it: the Task 1 contact sheet in the damage build order
  (stages 0 to 4 at battle camera and close zoom, three factions)
  judged by the owner, already specced as the build's first task.

E11. Weapon mark caps: MARK_CAP 12 per ship, SEC_MARK_CAP 4 per
section.
- Lives in: godot/fx/fx_breach.gd (shipped caps, line 63 area);
  damage surface synthesis sections 2 and 4 ("stay").
- Provenance: ASSUMED. Evidence: shipped constants kept by the
  research; the one alternative considered (a baked atlas
  replacement) was screened out partly because these caps sit
  under R80, which is governance, not measurement.
- If wrong: long fights either saturate (later hits leave no
  trace, breaking the spatial memory the spec wants) or the caps
  never bind and per-hit cost is unbounded in the breach rebuild
  path.
- Settles it: a scripted long-fight capture counting marks
  landed against marks shown, one script build.

E12. Persistent emitter caps by weight class: weight 1 hulls at
most 1 fire and 2 smoke; weight 2 at most 2 fires and 3 smoke or
vent; weight 3 and 4 at most 3 fires and 4 smoke or vent, per
ship across all sections.
- Lives in: damage surface synthesis section 4.
- Provenance: ANCHORED. Evidence: the synthesis adopts the table
  from the Argon draft, itself modelled on EVE Online's class
  caps as recorded by Job 1 (frigate 1 fire source, cruiser 2,
  battleship and carrier 3). An external game's per-class counts,
  promoted into this game's budget. The chair screened the Argon
  leg's other numbers hard and adopted this table after checking
  it against the pack, but the pack's own source is EVE.
- If wrong: the burning-ship read at 20 ships is either starved
  (sections beyond the cap show scorch only, so the most damaged
  ships can look quieter than less damaged ones) or the caps are
  set far under what the frame allows.
- Settles it: the Task 4 stress test in the damage build order
  (20 ships all at stage 3 or 4) with caps raised in steps and
  frame cost logged per step, one Codex run.

E13. Board worst case arithmetic: about 34 fire or vent emitters
and 46 smoke emitters board-wide, roughly 80 emitters and on the
order of 1,000 pooled particles, on a 20 ship board.
- Lives in: damage surface synthesis section 4.
- Provenance: DERIVED. Evidence: arithmetic on E12 with an
  assumed fleet mix (10 weight 1, 6 weight 2, 4 weight 3 to 4)
  stated in the text; the competing per-section accounting in the
  same section (up to 180 fire emitters) shows the answer depends
  entirely on which cap reading is implemented. The section
  itself ends by asking the build to "replace the arithmetic with
  measured fx.prof numbers", which has not happened in the record
  read.
- If wrong: the frame budget conversation for the whole damage
  system is anchored on a number nobody measured.
- Settles it: the same Task 4 stress test, reporting measured
  emitter and particle counts (one Codex run, shared with E12).

E14. Fog grid shipped constants: battle camera near plane 0.5
units; volumetric fog length 400 units; froxel grid defaults
volume_size 64, volume_depth 64.
- Lives in: godot/render/camera_rig.gd line 33; godot/render/
  backdrop.gd line 53; issue 135 synthesis section 4 (chair
  verified in code).
- Provenance: MEASURED. Evidence: current code values, verified
  by the chair reading the code; the synthesis's analysis (the
  battle sits about 170 units away, so most of the logarithmic
  froxel depth resolves empty space) is arithmetic on them.
- If wrong: not a risk to correctness of the audit; the values
  are the baseline every fog proposal is measured against.
- Settles it: settled as a baseline; its use is in E15.

E15. Fog preparation proposals: raise the near plane toward 5 to
15 units per zoom band; tighten fog length toward 250; test
volume_size and volume_depth at 128 on max tier with temporal
reprojection on.
- Lives in: issue 135 synthesis section 4; issue 139 (froxel
  preparation first).
- Provenance: ASSUMED. Evidence: reasoned from the E14 geometry
  ("concentrates the slices on the battle plane at zero GPU
  cost"); the zero cost claim is asserted, not profiled, and the
  128 test is a direction, not a result.
- If wrong: the quality ladder for the game's largest spaces is
  built on an unprofiled reshuffle; near plane changes can clip
  close zoom content if the band edges are wrong.
- Settles it: issue 139's own N1 step (froxel preparation with no
  visual change) plus the N5 profile, one Codex run.

E16. Nebula construction constants: 5 puffs per hex (3 at low
quality), puffs sized 24 to 34 units, plus about 1 broad tying
puff per 3 hexes sized 36 to 46 units.
- Lives in: godot/world/world_living.gd lines 231 to 246, as
  quoted in the terrain fx synthesis section 2.1.
- Provenance: ASSUMED. Evidence: shipped code constants the
  terrain research explicitly kept ("puff counts, sizes, heights
  and the footprint mask stay as they are") while replacing the
  shading; no density or readability derivation for the counts
  appears in the record.
- If wrong: the volume conversion in issue 139 inherits a
  billboard skeleton whose density was never itself judged; too
  sparse reads as blobs, too dense eats the overdraw the volumes
  were meant to save.
- Settles it: one patch rendered at three densities under the
  new volume shader, sheeted at 4K, one Codex run plus one owner
  review round.

E17. Faction tint cap: faction colour pull capped at about
25 percent at the nebula ramp ends.
- Lives in: FINDINGS R82 Q1; the NEBULA_FACTION_END_WEIGHT
  constant carried into issue 135 synthesis section 4 and issue
  139.
- Provenance: ASSUMED. Evidence: a chair pick adopted by the
  owner; the terrain synthesis says "the build should treat that
  weight as a single tunable constant, not as structure", which
  is the record admitting it is a dial position, not a finding.
- If wrong: nebula identity either washes toward faction colour
  (the mauve and brown failure in the playtest shots) or the
  fixed violet family reads identical on every map.
- Settles it: the ramp rendered at three weights on a warm
  faction sky, one owner review round on an existing sheet run.

E18. Star occlusion working targets: stars read at about
30 percent brightness through the nebula body and about
60 percent through the wisps; about 10 to 15 percent through the
storm body.
- Lives in: terrain fx synthesis sections 2.1 and 2.2.
- Provenance: ASSUMED. Evidence: stated as "working targets" in
  the research; no capture in the record measures achieved
  occlusion against them.
- If wrong: gas either looks pasted over the sky (stars shining
  through untouched) or swallows the backdrop the board look is
  built on.
- Settles it: one density sweep capture with star brightness
  sampled, one script annotation on an existing run.

E19. Patch light cap: at most one low-energy OmniLight3D per
nebula patch, at the largest glow core; working energy estimate
0.6 to 1.0.
- Lives in: terrain fx synthesis section 2.1.
- Provenance: ASSUMED. Evidence: adopted as a middle position
  between two leg positions, with the energy a named leg's
  "working estimate"; the same passage flags the unmeasured
  worst case (a storm map's 2 blobs plus 3 more from a nebula
  sector condition, on top of bolt lights) as something the build
  must report, which it has not yet in the record read.
- If wrong: either gas colour never lands on hulls (emissive
  only, the position the research rejected) or patch lights stack
  past the light budget on exactly the maps that also carry bolt
  lights.
- Settles it: the worst-case light count report the research
  itself demands, attached to issue 139 or 100, one script build.

E20. Filament core area target: bright filament cores under
10 percent of the nebula patch screen area at the default
camera.
- Lives in: terrain fx synthesis section 2.1.
- Provenance: ASSUMED. Evidence: a stated target with no
  measurement method named in the passage and no capture checked
  against it.
- If wrong: cores either sparkle everywhere (the detail
  frequency failure the leap research warns against) or never
  appear, and the storm still test (E21's companion) loses its
  always-on activity signal.
- Settles it: one patch capture with core area measured by a
  threshold pass, one script build.

E21. Storm bolt rules: about 1 bolt per 2 storm hexes, at most
6; cadence one flash every 2.2 to 6.5 seconds on a roughly
one-third second envelope; the first 4 bolts keep an OmniLight3D
at light_energy up to 3.2; a between-bolt glow pulse of period
1.5 to 2.5 seconds.
- Lives in: godot/world/world_living.gd lines 344, 430, 447 to
  465, as quoted in the terrain fx synthesis section 2.2; the
  bolt light budget restated in its build task 4.
- Provenance: ASSUMED. Evidence: shipped code constants the
  terrain research kept unchanged while replacing the storm body;
  the first-4-bolts light rule is a budget cap with no measured
  light cost behind it in the record.
- If wrong: storms either strobe (fighting the E6 flash regime
  the A5 synthesis built) or feel dead between bolts; the light
  cap silently decides which bolts illuminate ships.
- Settles it: a 10 second storm recording (already the build's
  judgement kit) reviewed against a bolt cadence variant, one
  owner review round.

E22. Planet bake resolution: PLANET_SIZE 4096 by 2048; moons
1024 by 512.
- Lives in: godot/world/world_bake.gd line 10; issue 135
  synthesis section 5 anchors.
- Provenance: ASSUMED. Evidence: a code constant; the leap
  research prices the enriched bake at "roughly doubling" load
  time and tens of MB per texture set without revisiting whether
  4096 is the right canvas for the owner's 4K camera.
- If wrong: planet quality (the R88 complaint: terrain planets
  need much higher quality) is capped by a canvas chosen before
  the geology work, or memory is spent on texels no camera sees.
- Settles it: one planet baked at two resolutions and sheeted at
  battle lens and close zoom (issue 140 already sheets both), one
  Codex run.

E23. Planet bake time: 6 to 9 seconds of baking per battle.
- Lives in: FINDINGS R76 (owner playtest, Nov 2, 2026: "6 to 9 s
  planet bakes per battle", sent to a Codex batch fix).
- Provenance: MEASURED. Evidence: an observed cost range from the
  playtest build, recorded as a defect.
- If wrong: it is the only load-time cost in the effects record;
  if the batch fix changed it, the record does not say so, and
  issue 140's richer bake will raise it again by its own
  estimate.
- Settles it: cold bake timing reported in issue 140's done-when
  (already required there), no extra run.

E24. Continuous flicker rules: engine misfire and damaged
sputter stay slow (0.5 to 1.5 Hz) and under 20 percent brightness
step, never counted as flashes, never above 3 Hz; lance
breathing modulation 1.2 to 3.3 Hz under 20 percent.
- Lives in: A5 sheets synthesis sections 4 and 8.
- Provenance: DERIVED. Evidence: applications of the E6
  accessibility regime to continuous emitters, built from the
  same cited bases; the specific Hz and percent figures are the
  merged legs' construction on that basis, not measurements of
  the shipped game (the A5 pass never ran).
- If wrong: damaged ships either strobe against the flash budget
  in spirit while obeying it in letter, or damage states read
  static because the modulation band is too timid to see.
- Settles it: the same worst-case salvo test as E6, with damaged
  ships in frame, one Codex run (shared).

E25. Reduce-flashing mode: 0 counted flashes when the mode is
on, achieved by named replacements (rings and particle bursts
instead of core pops, smoke-forward muzzles, softened blooms of
0.3 to 0.8 s, halved effects camera shake).
- Lives in: A5 sheets synthesis section 8 (merged recommendation,
  chair stated, for Opus to test).
- Provenance: ASSUMED. Evidence: a recommendation the synthesis
  itself flags as untested ("Opus tests readability of the
  0-flash mode before locking it"); the fallback (1 per second
  with 40 to 70 percent reduction) is recorded alongside, which
  is the record admitting the primary may fail.
- If wrong: an accessibility mode that makes the game unreadable
  ships, or the mode quietly never gets built because its
  feasibility was never priced.
- Settles it: one worst-case scene rendered in the mode and
  judged for readability, one Codex run plus one owner review
  round.

E26. Event light counts in the engine proof: 48 event lights in
the Godot proof build against Babylon's 64.
- Lives in: FINDINGS R31 (A3 proof part 1, Oct 26, 2026).
- Provenance: MEASURED. Evidence: counted in the two proof
  builds during the effects parity proof; the same entry records
  breach sparks running 1.2 s late (see A21).
- If wrong: it is the record's only like-for-like light budget
  comparison, and the fog light rules (E8, E19, E21) all spend
  from a budget whose current size is otherwise uncounted.
- Settles it: a light census of the current battle build, one
  script build.

E27. Engine test environment load: a seeded field of about 200
asteroids plus 6 large ones, with debris colliding, in the test
scenes.
- Lives in: FINDINGS R21 (SPEC.md Environment).
- Provenance: ASSUMED. Evidence: test scene design values chosen
  for the Oct 2025 engine comparison; they define what "max" and
  "board" modes meant in every frame time the engine decision
  rests on, and no document re-derives them from the game's real
  boards.
- If wrong: engine headroom conclusions (and E2's context) were
  measured against a field density the game may never field, in
  either direction.
- Settles it: a census of asteroid counts on real battle boards,
  one script build.

E28. Effects build order: after the ship work, deaths and
weapons first, then nebulas and storms, then planets.
- Lives in: FINDINGS R88; executed in the LOOP queue (137 and
  138 merged, 139 and 140 next).
- Provenance: ASSUMED. Evidence: an owner sequencing ruling from
  a playtest reaction; it is a priority judgement, not a measured
  dependency, and it interacts with E8 and E15 (the fog work is
  third in line while its tier rules gate the earlier deaths'
  explosion lights).
- If wrong: sequencing is taste, but the cost is real if the
  deaths' light behaviour has to be rebuilt once fog interaction
  lands.
- Settles it: nothing to measure; the legs should price the
  interaction, not the order.

E29. Ambition rule: quality jumps of 50 to 75 percent, not
10 percent.
- Lives in: FINDINGS R88 ("Wants 50 to 75 percent jumps, not
  10 percent").
- Provenance: ASSUMED. Evidence: an owner-set ambition figure
  with no unit (percent of what is never stated: not frame cost,
  not fidelity, not effort). It functions as a gate on proposals
  (incremental work gets rejected as too small) without a
  measurable referent.
- If wrong: it cannot be wrong numerically, which is the
  problem; it can be invoked to kill any incremental fix and to
  bless any large one, with no sheet able to settle the argument.
- Settles it: nothing measurable; the legs should say what
  replaces it as a decision rule (the Nov 6 answer was the
  owner's eye on head to head sheets).

E30. Death grammar rule: no sustained combustion in vacuum;
fireballs flash and snuff out, venting gas, hot metal cooling,
sparks, momentum-keeping debris.
- Lives in: FINDINGS R88 (deaths and hits go space-real); R90
  (the raymarched fireball leaves deaths entirely); issue 135
  synthesis sections 2 and 3 (The Expanse as grammar anchor).
- Provenance: ASSUMED. Evidence: an art direction ruling from the
  owner's playtest read ("fire looks more detailed than
  everything else and wrong for space") plus a reference-media
  grammar; it is a taste law, stated absolutely (the fireball is
  removed entirely, including its vent-plume type), and the one
  dissenting position in the job (keep the raymarch for rare
  reactor criticals at max tier) was set aside, not tested.
- If wrong: the game's deaths lose a read the owner may actually
  want at the rarest moments, and the rule's absoluteness forbids
  the experiment that would show it.
- Settles it: one capital death sheeted with a rare-critical
  variant, one owner review round.

E31. Weapon timing SPEC pins: battery ripple 80 ms between guns;
shell tracer 160 units per second; impact point 70 units; lance
duration 0.7 s to a point 80 units ahead with a 0.25 s charge-up
flare; shield ripple fade 0.6 s.
- Lives in: A5 sheets synthesis sections 2.2 and 3.1 to 3.3
  ("SPEC effect loop pins, centres for the testing ranges").
- Provenance: ANCHORED. Evidence: the pins are the Oct 25 engine
  test scene's loop design (a 4 second staggered loop built so
  two engines could be compared), carried into the A5
  specification as centres for testing ranges. The A5 pass never
  ran, so the pins were never screen-tested in the game, yet
  they are the only concrete weapon timing numbers the project
  has and downstream work treats them as the spec.
- If wrong: weapon feel across all seven kinds is tuned around
  a demo loop's choreography rather than battle readability;
  several pins interact with rules-visible facts (tracer speed
  against R76's visible torpedo flight demand).
- Settles it: one weapon of each kind fired in the real battle
  scene at pin values and at one alternate, sheeted as short
  recordings, one Codex run plus one owner review round.

E32. Torpedo telegraph: a two-stage warning of about 800 ms
total ramp to white (testing range 700 to 900 ms), the second
stage holding 100 to 200 ms before launch, plus an interception
call if the target has point defence.
- Lives in: FINDINGS K2 (open, scheduled for A5 by name); A5
  sheets synthesis section 3.4.
- Provenance: ASSUMED. Evidence: a single leg's proposal
  (DeepSeek only; the other leg does not cover the item),
  explicitly UNSURE and unscheduled in the record; K2 still lists
  it as an item to schedule, two weeks of builds later.
- If wrong: torpedo counterplay readability (an R76 playtest
  demand: visible flight, clear hit or miss) hangs on a warning
  duration nobody has ever seen rendered.
- Settles it: the telegraph built at two durations in a test
  scene, one owner review round.

E33. Hitstop and camera shake testing ranges: hitstop 2 to
6 frames for normal hits, 7 to 12 frames for kills and
criticals; shake 0.15 to 0.30 s positional on a trauma model,
0.35 to 0.45 s only for capital-scale destruction.
- Lives in: A5 sheets synthesis section 2.3 (batch 7
  disagreements, still open, "screen-tune only").
- Provenance: ASSUMED. Evidence: merged leg ranges recorded as
  disagreements the legs do not resolve; the synthesis states
  plainly that everything in section 2.3 remains open. The
  ranges have sat as the project's only hitstop and shake
  numbers since Oct 25, 2026.
- If wrong: hit feel (the R50 complaint: reactions feel like a
  "simple cartoonish push back") gets tuned inside ranges chosen
  by two documents' compromise rather than by play.
- Settles it: one battle scene with shake and hitstop at range
  ends, played by the owner, one owner review round.

E34. External performance caution: Sins of a Solar Empire II
capital deaths dropped frame rates from a stable 45 to 20 to
25 fps (player record, its Ruins of War update).
- Lives in: issue 135 synthesis section 2.
- Provenance: ANCHORED. Evidence: player-reported figures for
  another game's update, used in the synthesis to argue burst
  versus steady-state budgeting. It is the only death performance
  envelope in the record, and it is not this game, this engine,
  or a measured benchmark.
- If wrong: the burst budgeting argument (E3's split, the
  raymarch removal's performance half) leans on an anecdote; the
  same section's own correction (burst savings do not fund
  steady-state costs) cuts the other way.
- Settles it: a multi-capital-death burst profile in this game
  (shares the E5 and E13 test), one Codex run.


## 4. Animation inventory (A1 to A22)

Template as in section 3. This domain's record is rulings and
bars, not documents; several items are qualitative rules that act
as gates, and two items (A18, A20) inventory a missing number
rather than a present one. Tallies for this section: 22 entries;
MEASURED 3, DERIVED 0, ANCHORED 0, ASSUMED 19. The zero DERIVED
and zero ANCHORED counts are themselves part of the evidence:
nothing in this stack was ever computed from anything else.

A1. Round pace caps, RETIRED: a 12 s round target and a 15 s
round limit.
- Lives in: retired by FINDINGS R64 (Nov 1, 2026: "the 12 s
  target and 15 s round limit are retired").
- Provenance: ASSUMED. Evidence: pace targets from the B2 design
  era; the retirement is recorded, the original derivation never
  was. Included because retired numbers leave ghosts (see A22),
  the same failure the graphics pack inventoried in withdrawn
  constraints.
- If wrong: nothing binds today; the risk is re-adoption from
  stale documents that still cite B2 pace.
- Settles it: a text sweep for pace citations in live build
  briefs, one Opus run.

A2. Round pace measurements: round pace 12.1 s and 14.0 s on the
recorded builds; battle pace under 15 s per round even at
28 ships (G2 exit).
- Lives in: FINDINGS G-14 (e80a6a0); engine vet pack section 3.2
  (G2).
- Provenance: MEASURED. Evidence: timed on real builds. Caveat:
  both predate R64's slower movement (A3), so the current pace
  has no measurement in the record at all.
- If wrong: every pace argument since Nov 1, 2026 argues from
  numbers the game no longer produces.
- Settles it: one timed round on the current playtest build, one
  script annotation.

A3. Movement speed ruling: movement about twice as slow, ships
moving one at a time, longer enemy turns accepted.
- Lives in: FINDINGS R64 (owner ruling, Nov 1, 2026).
- Provenance: ASSUMED. Evidence: an owner feel ruling; "about
  twice" is not tied to a stated baseline speed, a timing
  measurement, or a capture, and no follow-up measurement
  verifies the shipped result against it.
- If wrong: the core feel of every battle (the thing R50, R55,
  and R76 all also rule on) rests on an unverified multiplier;
  one at a time movement multiplies round length by ship count,
  which interacts with A2's now stale pace numbers.
- Settles it: side by side captures at the ruled speed and one
  alternate, one owner review round; plus the A2 timing rerun.

A4. Enemy think bar: 0.5 s per activation.
- Lives in: FINDINGS R30 (A3 speed check, "inside the 0.5 s
  bar").
- Provenance: ASSUMED. Evidence: a bar stated in the parity
  record with no derivation (not from a frame budget, not from a
  pace target that survived; the pace regime it served was
  retired by R64). Measurements were taken against it (A5) but
  the bar itself was never argued.
- If wrong: AI architecture decisions (GDScript versus C# for
  scoring loops, think-during-animation) are gated by an
  unargued half second; under the current one-ship-at-a-time
  presentation the bar may be far stricter than the game needs,
  or carrier fights may already be at its edge.
- Settles it: nothing to measure until someone states what the
  bar protects (pace, responsiveness, or thread budget); the
  legs should price that restatement, not a rerun.

A5. Enemy think measurements: GDScript average 0.10 to 0.14 s,
worst 0.27 to 0.33 s per activation (R30); worst 0.28 to 0.46 s
with the carrier-heavy scenario showing little room (G-7).
- Lives in: FINDINGS R30 and G-7 (timing files cited in both).
- Provenance: MEASURED. Evidence: timed on the owner's PC
  against the Node oracle (Node average 0.03 s, worst 0.06 s;
  GDScript 3 to 4 times slower).
- If wrong: these are the only animation-adjacent timings ever
  measured in the project; everything else in this section is
  feel language.
- Settles it: settled as measurements; their use is in A4 and
  A6.

A6. Think-during-animation rule: plan to think the next enemy
move during the current animation; move only the AI scoring
loops to C# if carrier-heavy fights miss the bar.
- Lives in: FINDINGS R30.
- Provenance: ASSUMED. Evidence: an architecture intention
  recorded at the speed check; the record does not state whether
  it was built, and the trigger ("miss the bar") keys off A4.
- If wrong: either engineering was spent hiding latency the
  current presentation does not have, or carrier fights stall
  visibly at exactly the moments R88 made squadrons automatic
  and therefore common.
- Settles it: a code state check plus the carrier scenario
  timing on the current build, one Opus run.

A7. Hit reaction model: mass-scaled hit reactions (hull shudder,
small roll or yaw kicks corrected by thrusters, flicker, debris,
weight by weapon kind, scaled camera shake).
- Lives in: FINDINGS R50 (sent to G4, from the owner's playtest
  complaint that hits feel like "a simple cartoonish push back"
  that is not "weighty, cinematic or accurate").
- Provenance: ASSUMED. Evidence: a design response to a feel
  complaint; no magnitudes, durations, or comparisons are stated
  in the ruling, and the shake half inherits E33's untested
  ranges.
- If wrong: the complaint that prompted it recurs in the next
  playtest, and the G4 build will have spent itself inside
  unspecified parameters.
- Settles it: one ship hit by three weapon weights at two
  reaction scales, captured, one owner review round.

A8. Movement model: mass-scaled acceleration, banking arcs,
overshoot and settle, engine flare and RCS puffs.
- Lives in: FINDINGS R50 (sent to G2).
- Provenance: ASSUMED. Evidence: a feel specification with no
  numbers; "mass-scaled" names a direction, not a curve, and no
  document in the record supplies the curve or a test that would
  recognise it.
- If wrong: R55 and R76 both re-rule movement after it ("not
  fully right", the stop "too sudden"), which is what an
  untestable specification produces: serial re-rulings, each one
  owner's-eye pass on one build.
- Settles it: a movement test scene with the same move rendered
  at three acceleration curves, one owner review round.

A9. Pace setting rule: a cinematic and brisk setting,
defaulting to cinematic, so animation length does not sacrifice
feel for speed.
- Lives in: FINDINGS R50.
- Provenance: ASSUMED. Evidence: a settings design (two modes,
  one default) with no stated durations for either mode and no
  record in what was read of which mode the shipped builds run.
- If wrong: the default is the game for nearly every player; an
  unexamined default plus unmeasured durations means the pace
  debate (A1 to A3) is being held about an unnamed quantity.
- Settles it: state both modes' measured round times on the
  current build (shares A2's rerun).

A10. Braking rule: an eased braking phase as the default; the
stop reads too sudden.
- Lives in: FINDINGS R55 (sent to G2, status IN PROGRESS).
- Provenance: ASSUMED. Evidence: an owner feel judgement on one
  build (680324c); no braking duration or curve is stated, and
  the item still sits IN PROGRESS in the record.
- If wrong: every arrival in every battle carries the defect the
  owner named; it is also the kind of flaw no sheet can catch,
  only motion can.
- Settles it: one long move captured with and without the eased
  phase, one owner review round.

A11. Flip-and-burn: a test on long runs for big hulls was sent
(R55); flip-and-burn stays off (R64).
- Lives in: FINDINGS R55 and R64.
- Provenance: ASSUMED. Evidence: the later ruling closes the
  question the earlier one opened; the record read does not
  state whether the side by side test ran or what it showed. The
  ruling may rest on a test or on preference; the pack cannot
  tell, and neither could a future reader.
- If wrong: a movement signature the owner explicitly wondered
  about (his Lost Fleet reference) was closed without the
  evidence he asked for, or a test was run and its result was
  never written down, which wastes it either way.
- Settles it: a record check for the test's shots; if absent,
  the test itself is one Codex run plus one owner review round.

A12. Glide rule: movement glides on smooth curves with the main
engine doing the work and small thruster puffs only on turns; no
side-to-side shuffle.
- Lives in: FINDINGS R76 (owner playtest rulings, Nov 2, 2026;
  reference points Homeworld and BFG Armada).
- Provenance: ASSUMED. Evidence: an owner feel ruling from a
  9 battle playtest; it contradicts nothing, but it is the third
  movement model statement in a week (A8, A10), each absolute in
  wording and none with a parameter a builder could be checked
  against.
- If wrong: builders implement three overlapping movement
  rulings by taste, and the next playtest re-rules the sum.
- Settles it: one consolidated movement specification with the
  three rulings merged and its parameters stated, one Opus run;
  the legs should price the consolidation, not another feel
  pass.

A13. Motion class split: strike craft keep agile motion while
capital hulls get weight and eased stops.
- Lives in: FINDINGS R55 (strike craft sentence) with R50.
- Provenance: ASSUMED. Evidence: a sensible split stated in one
  clause; no boundary (which classes count as agile) and no
  parameter difference is stated anywhere in the record read.
- If wrong: carriers and their wings (now automatic, A15) are
  the most animated objects on the board; an undefined split
  shows up exactly there.
- Settles it: the same consolidation as A12, with the class
  boundary named.

A14. Engine rest state: engines glow dimly at rest (owner likes
engines glowing dimly).
- Lives in: FINDINGS R55.
- Provenance: ASSUMED. Evidence: a preference ruling; it
  interacts with the A5 engine trail spec (nozzle glow as a
  throttle and damage signal) in a way no document reconciles:
  a rest glow sets the floor of a signal whose whole point is
  variation.
- If wrong: trivial in cost, but it is the kind of small
  absolute that quietly flattens a designed signal.
- Settles it: one trail sheet at rest and under thrust, one
  owner review round (shares E31's run).

A15. Squadron automation: carriers launch at battle start,
wings fight on their own, an optional target order stays.
- Lives in: FINDINGS R88 (owner ruling after squadrons felt
  "hard to launch and unnecessary and complex").
- Provenance: ASSUMED. Evidence: a rules and presentation ruling
  from playtest frustration; its animation consequences (launch
  choreography at every battle start, wing flight behaviour for
  the whole battle) are nowhere specced in the record read, and
  the A5 SQ sheets (launch streams, 4 to 12 craft per launch
  event, counts marked UNSURE by their own leg) predate it.
- If wrong: the most frequent animation event in the game
  (every carrier, every battle) was created by a ruling whose
  animation design does not exist yet.
- Settles it: a launch and wing behaviour specification with
  counts, one Opus run, judged on one capture round.

A16. Squadron damage presentation: squadrons get stage 0
surfaces, and a smoke ribbon below half total HP.
- Lives in: FINDINGS R80 (damage research rulings).
- Provenance: ASSUMED. Evidence: the half HP threshold is a
  round fraction with no derivation in the research (the damage
  synthesis argues it from feature size at squadron length,
  L = 2.6 units, being sub-threshold, which argues the stage 0
  half, not the ribbon trigger point). The same ruling pass
  flags that squadrons "look static" and need their own
  detailing pass, which is the owner noting the animation
  problem the threshold does not address.
- If wrong: the ribbon fires at a point nobody chose for a
  reason, and wing damage readability rests on a health bar the
  spec itself calls merely the primary read.
- Settles it: one wing fight captured at three ribbon
  thresholds, one owner review round.

A17. Slow-motion beat: a brief slow-motion beat on kills, for
big ships and flagships only; audio does not slow with the
picture (it ducks instead).
- Lives in: FINDINGS R73 (owner ruling, Nov 1, 2026); the audio
  half in the battle sound synthesis section 4.
- Provenance: ASSUMED. Evidence: the ruling scopes the beat
  (which kills) and states no magnitude or duration; the only
  numbers anywhere are A5 leg proposals (50 to 80 percent speed
  for 0.3 to 0.8 s on player kills), written for a different
  death sequence and never tested. R73 also leaves the break-up
  method (clip-and-plug versus plane cuts) to be "decided from
  screenshots and the 1 percent low", tying an animation choice
  to E2's conditions-free figure.
- If wrong: the game's single most theatrical device is tuned
  by nobody, and its performance clause cites a measurement
  whose resolution is unknown.
- Settles it: one flagship kill captured at two beat settings,
  one owner review round.

A18. Turret behaviour: rotating turrets stay separate meshes
from the merged hull; station turrets turn to the last target
fired at, then hold. No turn rate exists.
- Lives in: FINDINGS R82 Q3 (ship pipeline) and R84 (structures:
  station turret behaviour).
- Provenance: ASSUMED. Evidence: two behavioural rulings with no
  slew rate, acceleration, or arc speed anywhere in the record
  read; turret motion is the most continuous animation on a
  station and the most visible idle motion on a ship, and it is
  specified by two clauses and zero numbers.
- If wrong: turrets either swivel like toys or lag like
  statues, and no review can call it wrong, because nothing
  states what right is.
- Settles it: one turret tracking capture at two slew rates,
  one owner review round.

A19. Ship draw scale: 1.6 times class length.
- Lives in: FINDINGS G-1 (Claude call, vetoable, at the first
  playable battle: "ships too small" fixed in part by draw
  scale).
- Provenance: ASSUMED. Evidence: a single corrective multiplier
  chosen against one build's shots; it scales every px-per-unit
  relationship the paint and damage standards derive from (the
  graphics pack's camera scale family), and no document in the
  record re-derives those after it.
- If wrong: readability derivations across two standards are
  quietly off by the same factor, the exact failure shape of the
  graphics pack's C31 (the unconfirmed battle distance).
- Settles it: one in-game capture at the real battle camera with
  a known hull measured in frame (shares the graphics ladder
  work), one script build.

A20. Campaign map flight: the campaign map movement jumps from
event to event instead of flying; the owner wants flight, on a
3D map with the dead star always visible.
- Lives in: FINDINGS R88 (complaint carried in the ruling) and
  R51 (the Sins 2 style 3D map sent to G3).
- Provenance: ASSUMED. Evidence: a standing defect with no
  duration, speed, or path specification anywhere in the record
  read; unlike battle movement it has never even had a feel
  ruling with content, only the complaint.
- If wrong: the map is where the player spends the between
  battle half of the game; its core motion has no design at all,
  which no other item in this pack can say.
- Settles it: a map flight prototype at two durations, one
  owner review round.

A21. Breach spark timing defect: breach sparks run 1.2 s late
in the Godot effects proof.
- Lives in: FINDINGS R31 ("Left: breach sparks 1.2 s late").
- Provenance: MEASURED. Evidence: observed and recorded in the
  A3 proof; the record read does not state whether it was fixed
  in the G4 pass, so a measured defect sits open by silence.
- If wrong: if still live, every breach in the game fires its
  sparks over a second after the event they belong to, which
  reads as randomness, the R88 death complaint in miniature.
- Settles it: one breach capture on the current build, one
  script annotation.

A22. Overlap and hurry rule: keep the pace by overlapping
animations and hurry.
- Lives in: FINDINGS R50 (G2 movement: "keeping the B2 pace by
  overlapping animations and hurry").
- Provenance: ASSUMED. Evidence: a technique instruction whose
  target (the B2 pace) was retired by R64 (A1); the instruction
  survives in the record with its referent gone, so builders are
  told to hurry animations toward a pace nobody is keeping any
  more.
- If wrong: animation overlap is also a readability cost
  (simultaneous motion is harder to parse, and R64 chose one
  ship at a time partly for that); an orphaned hurry rule pushes
  against the current presentation on stale authority.
- Settles it: the A12 consolidation states whether overlap
  survives, and where.

## 5. Sound inventory (S1 to S20)

Template as in section 3. Tallies for this section: 20 entries;
MEASURED 6, DERIVED 1, ANCHORED 0, ASSUMED 13. The zero ANCHORED
count is honest: sound never imported another game's numbers. Its
problems are of two other kinds: starting-shape numbers nobody
tuned (S6, S7), and a verification gate that has never executed
(S15).

S1. Licence gate for audio sources: CC0 or CC BY only; no NC,
ND, or SA material.
- Lives in: licence rule R40 (cited throughout the battle sound
  synthesis); issue 101 ("Free and open-licensed only: CC0
  everywhere except the one approved CC BY source").
- Provenance: ASSUMED. Evidence: a policy ruling, sound in
  itself; inventoried because it binds every sourcing decision
  and because its one exception (S2) and its enforcement surface
  (S16) are both unresolved.
- If wrong: it is not wrong as policy; the risk is drift, where
  the gate is cited while the exception and the missing credits
  surface do the actual deciding.
- Settles it: nothing to measure; the legs should price the
  enforcement (the credits surface, S16), not the rule.

S2. The Sonniss exception: sound stays as is, Sonniss clips
included, in a public repo.
- Lives in: FINDINGS R10; defect row D22 ("files may not be
  handed to others; sfx_data.js carries them as base64"),
  CLOSED by the owner Oct 25, 2026: "Disregard the Sonniss
  thing, we're fine."
- Provenance: ASSUMED. Evidence: an owner decision recorded as
  explicitly not a licence check (D22's own wording). It stands
  permanently against S1: the shipped game carries clips whose
  licence terms, on the record's own account, do not allow
  handing the files to others, inside a public repository.
- If wrong: this is the one item in the pack whose cost of being
  wrong is legal and reputational rather than aesthetic, and it
  cannot be settled by a sheet or a listen pass.
- Settles it: not a measurement; a licence read of the actual
  Sonniss terms against the actual distribution, one Opus run,
  is the only settlement that exists. The legs should say so
  plainly.

S3. Music direction: brass and tactical percussion in battle, a
synth drone on the map, organ and machine sounds only as faction
flavour; text only, no voice.
- Lives in: FINDINGS R37 (muse picks, agreed by the owner).
- Provenance: ASSUMED. Evidence: an art direction with no
  reference tracks named as measured exemplars in the record
  read and no audition behind it (see S16: the incumbent faction
  track's file is absent from the snapshot and nobody has heard
  it).
- If wrong: the entire music intake (S4, S11) sources toward a
  direction that has never been heard in the game, and the first
  time it is heard is the owner's step 6 pass on finished work.
- Settles it: the audition in S16, one owner listen round.

S4. Music sourcing rule: free licensed tracks first (royalty
free or CC0).
- Lives in: FINDINGS R40.
- Provenance: ASSUMED. Evidence: a policy ruling; combined with
  S1 it defines the pool every music slot is filled from, and
  with S11 it defines the pool's quality gate, such as it is.
- If wrong: policy, not measurement; its interaction with S11 is
  the auditable part.
- Settles it: nothing; see S11 for the gate that does the work.

S5. Shipped cue count: cues.json carries 57 cues; the system is
a layered cue dispatch in sfx.gd.
- Lives in: battle sound synthesis, grounding (godot/audio/
  cues.json, 57 cues; sfx.gd dispatch).
- Provenance: MEASURED. Evidence: counted in the shipped file
  during the job's verified coverage work.
- If wrong: it is the baseline the 11 new cue ids (S18's job)
  and the issue 101 replacements were counted against.
- Settles it: settled as a baseline.

S6. Voice caps proposal: a global SFX ceiling near 20
simultaneous voices, with per-family caps of guns 6, hits 6,
deaths 4, UI 3, actions 2, and the quiet cues stolen first.
- Lives in: battle sound synthesis section 4 ("Voice caps at
  20 ships").
- Provenance: ASSUMED. Evidence: the chair's starting shape,
  explicitly bracketed by the legs' 16 (Qwen) and 24 (Rey) and
  explicitly unfinished: "Opus tunes by ear with caps logging
  on." No ear has tuned it (S15), and no caps log appears in the
  record read. Twenty is the midpoint of two guesses, adopted as
  the number builds will use.
- If wrong: at 20 ships the densest salvos either clip and
  steal audibly (the S9 bug's audible cousin) or voices are
  wasted on a ceiling set far above what the mix needs.
- Settles it: the synthesis's own verification pass (build step
  10: a full round at 20 ships with caps logging on, counting
  steals), one Codex run plus one owner listen round.

S7. Gain starting fractions: death stage cues start near two
thirds of boom_l gain; chunk_cool and hulk_vent near one third;
board_grapple and brace_lock near hit_heavy; adapt_shift near
ui_boss; nothing new is louder than boom_l.
- Lives in: battle sound synthesis section 4 ("Gains").
- Provenance: ASSUMED. Evidence: stated as starting points
  ("start near") relative to incumbent cues nobody in the
  process had listened to; the reference cue boom_l is itself an
  un auditioned anchor, which makes these anchored in effect
  though the pack classifies by stated basis: assumption stacked
  on an unheard reference.
- If wrong: every new cue from the feel pass enters at a level
  derived from an unheard baseline, and the first correction
  happens, if at all, in the step 6 pass.
- Settles it: the step 6 listen pass (S15) with the gains sheet
  in hand, one owner listen round.

S8. Defer validation rule: every gun cue's defer window must be
at least 2.5 times its gap.
- Lives in: battle sound synthesis section 4 (adopted form of
  the fix, as a validation rule in cues.json review).
- Provenance: DERIVED. Evidence: derived from the verified
  defect in S9: defer must cover gap times the salvo group size
  the cue is capped at; 2.5 is the adopted safety form of that
  arithmetic.
- If wrong: if the multiplier undershoots the largest legal
  salvo for some cue, S9 recurs cue by cue; the synthesis names
  the test that would prove it (fire the largest legal salvo of
  each gun kind and count started voices against the cap).
- Settles it: that test, one script build.

S9. The salvo defer defect, measured: gun_sq gap .05 against
defer .08; gun_shell gap .045 against defer .14, so later voices
in a capped salvo group never start.
- Lives in: battle sound synthesis section 4 ("the pack verified
  that dense salvos drop cue starts past the defer window").
- Provenance: MEASURED. Evidence: verified against the shipped
  cues.json data in the job's grounding work; it is a defect
  found by reading data, the sound stack's equivalent of a
  measurement.
- If wrong: it is the best-evidenced item in this section; its
  presence proves the cue data was never salvo-tested before it.
- Settles it: settled as a defect; the fix's proof is S8's test.

S10. Mute floor defect, measured: volume zero yields about
minus 98 dB at sfx.gd line 97, not silence; the music bus mutes
properly.
- Lives in: battle sound synthesis section 4.
- Provenance: MEASURED. Evidence: verified in code during the
  job; the fix (set the SFX bus mute flag as the music bus does)
  is specified in the same passage.
- If wrong: a player who chose silence hears a faint game; a
  small defect, but it is the second of exactly two things in
  this stack that were ever verified, and both were defects.
- Settles it: settled as a defect; the fix is one Codex run.

S11. Music loop gate: candidates run through tools/music/
process.py and must score loopfind 0.55 or better; incumbents
kept unless a candidate wins.
- Lives in: issue 101 done-when.
- Provenance: ASSUMED. Evidence: a tool score threshold stated
  in the issue with no derivation, no stated relationship
  between the score and whether a loop is audible as a loop, and
  no listened calibration set. It is the only quality gate in
  the music pipeline, and it is a number about a waveform
  statistic.
- If wrong: tracks with audible loop seams pass (score above
  the line, seam below the tool's notice) or seamless tracks are
  rejected, and either way the decision is made by the statistic
  because no one listens until step 6.
- Settles it: a calibration set of loops with known seams scored
  and listened to, one script build plus one owner listen round.

S12. Clips folder soft cap: if the clips folder grows past
about 30 MB, say so in the PR body instead of trimming quality.
- Lives in: issue 101 body.
- Provenance: ASSUMED. Evidence: a round figure with a sensible
  escape (report, do not trim); no size budget derivation from
  the build's total size appears in the record.
- If wrong: low stakes either way; it is inventoried because it
  is the intake's only size rule and it was set before the
  intake's own delivered size (S14) was known.
- Settles it: the delivered folder size against the build size,
  bookkeeping on the next intake.

S13. Take format rule: every selected take is converted to mono
Ogg and registered.
- Lives in: issue 101 done-when.
- Provenance: ASSUMED. Evidence: a pipeline rule with no stated
  exception path; mono is a real choice for positional game
  audio, but the record does not state whether any cue class
  (music-adjacent stingers, the bass_drop) was considered for
  stereo, and the rule was written before any take was heard.
- If wrong: a small number of cues that want width ship flat,
  and the rule's absoluteness hides the decision.
- Settles it: the step 6 listen pass naming any cue that wants
  stereo, one owner listen round (shared with S15).

S14. Issue 101 delivered counts: every REPLACE and UPGRADE cue
in the sourcing synthesis section 4 got a selected recorded
take: 39 cues, delivered as 40 clip sets and 128 files;
synth-only cue count zero.
- Lives in: issue 101 (closed) and its delivery record.
- Provenance: MEASURED. Evidence: counted delivery figures from
  the closed issue's record. Caveat: see the unverified list in
  section 6; the delivery's paper trail is thinner than the
  counts suggest.
- If wrong: the "recorded takes only" state of the game (the
  synth strip) rests on these counts; if any cue silently kept a
  synth layer (the issue allows single synth layers restorable
  from git), the zero is a headline, not a fact.
- Settles it: a cues.json audit listing each cue's layers and
  their sources, one script build.

S15. The listen pass has never run: issue 101 step 6, the
owner's sign-off listen from the one-page listen sheet, is
still outstanding; the battle sound synthesis states that
nobody in its process listened to any audio file, including the
shipped cues.
- Lives in: issue 101 (step 6, post-merge, the owner's); battle
  sound synthesis header and Not checked.
- Provenance: MEASURED. Evidence: the absence is verified in two
  documents written by the process itself. This is the sound
  stack's central fact: every number in this section (S6, S7,
  S11, S18) is a pre-listening number, and the stack's quality
  gate is an event that has not happened.
- If wrong: it is not wrong; the exposure is that the entire
  domain's judgements are pending a single pass that has been
  outstanding since the intake merged.
- Settles it: the pass itself, one owner listen round, with the
  listen sheet and the S7 gains sheet in hand.

S16. Music credits and audition debt: eight CC BY music tracks
have credit records and no in-game surface reads them; the
incumbent Hullbreaker track (fac_corsair.ogg, defined in
music.json) has its audio file absent from the snapshot, so
nobody has heard the incumbent its replacements are judged
against.
- Lives in: battle sound synthesis sections 3 and 5.
- Provenance: MEASURED. Evidence: verified in the job's
  grounding (the credit records exist; the surface does not; the
  file is absent). The synthesis's recommendation (build the
  credits surface before or alongside further CC BY intake) is a
  chair recommendation, not a ruling.
- If wrong: every further CC BY intake (the S3 direction makes
  faction tracks likely) grows an attribution debt the licence
  gate (S1) exists to prevent, and auditions compare candidates
  against silence.
- Settles it: the credits surface build, one Codex run; the
  audition itself is one owner listen round once the incumbent
  file is present.

S17. Loud death restraint proposal: cap simultaneous boom
voices at one, drop bass_drop, replace boom_l with boom_m at
lower gain, silence chunk_cool; whether it folds into the
reduce flashing setting or ships as a sibling option is an open
owner call.
- Lives in: battle sound synthesis sections 4 and 7.
- Provenance: ASSUMED. Evidence: a three-leg convergence on a
  "starting shape", by its own wording; it is the audio analogue
  of E25 and shares its state (designed, untested, and waiting
  on an owner decision about its settings home).
- If wrong: capital deaths either punish the ear at full
  stacking or the restraint mode guts the moment R73 slows down
  to celebrate.
- Settles it: one staged capital death listened to in both
  modes, in the S15 pass, one owner listen round (shared).

S18. New cue duration targets: ui_plan about 0.12 s;
arrive_jump about 0.45 s; adapt_shift about 0.6 s; chunk_cool
about 1.5 s; the death stage cues re-time existing layers rather
than adding material at stage 4.
- Lives in: battle sound synthesis section 1 (the 11 new cue
  ids).
- Provenance: ASSUMED. Evidence: design targets stated to a
  tenth of a second by legs that had heard none of the existing
  cues they are sized against (ui_plan is "softer and shorter
  than ui_confirm", a cue nobody in the process had played).
- If wrong: each is small; together they are the feel pass's
  entire new vocabulary, sized in the dark.
- Settles it: the S15 listen pass, one owner listen round
  (shared).

S19. Slow-motion audio rule: do not slow the audio with the
picture; duck music and ordinary cues at the beat start, play
the death cues at normal speed inside the beat, land bass_drop
as the beat releases.
- Lives in: battle sound synthesis section 4; the beat itself
  is A17 (R73).
- Provenance: ASSUMED. Evidence: a leg-converged design rule
  ("slowed booms turn to mud") with no listened test behind it;
  it is plausible, standard practice, and entirely unverified in
  this game.
- If wrong: the flagship kill, the one moment two rulings
  converge on, has its audio shaped by an untested rule of
  thumb.
- Settles it: one flagship kill in the S15 pass with the duck
  on and off, one owner listen round (shared).

S20. Adaptation cue frequency cap: adapt_shift fires once per
battle, when Nemesis adaptation is reported; not per round, not
per hit.
- Lives in: battle sound synthesis section 1 (cue 12; the rules
  hook at rules.gd line 1252 verified to have no cue).
- Provenance: ASSUMED. Evidence: a frequency decision made for a
  cue that did not exist, against an event whose in-game
  frequency the synthesis does not state; the restraint is
  sensible and the number (one) is unargued.
- If wrong: either the Nemesis's signature learning moment is
  undersold (adaptation reported more than once in long battles
  would stay silent after the first) or a rarer cue would have
  carried more weight.
- Settles it: the Nemesis battle in the synthesis's own
  verification pass (build step 10), one owner listen round
  (shared with S15).

## 6. Chair observations (hypotheses for the legs to test)

These are the chair's starting suspicions, recorded so the legs
can attack or confirm them. They are INFERRED, they are not
findings, and a leg that merely repeats them has done no work.

H1. The disease differs by domain, and the tally shows it.
Effects has the graphics disease in its classic form: many
numbers, most assumed, several anchored on one test scene (E31)
or one external game (E12, E34). Animation has the opposite
shape: almost no numbers at all, and instead a stack of absolute
feel rulings (A8, A10, A12) that no builder can be checked
against and no measurement can settle, which produces serial
re-rulings instead of false precision. Sound has the fewest bad
numbers and the worst verification state: its only verified items
are two defects (S9, S10), and its quality gate (S15) has never
executed. One remedy will not fit all three.

H2. The Oct 25 test scene is this audit's stage 5. The A5 SPEC
pins (E31) and testing ranges (E33) were designed as a demo
loop's choreography and as centres for ranges, in a pass (A5)
that was never scheduled. Two weeks of later documents cite them
as the specification. That is the anchor pattern exactly: a
measured or designed property of one incumbent scene, promoted
by citation into a standard.

H3. The best-derived regime in the three stacks (the flash
regime, E6 and E24, grounded in WCAG and platform accessibility
guidance) is also untested in situ: the worst-case salvo test
its own synthesis specifies has not run. Derivation is not
verification, and the legs should not let a good pedigree
substitute for the test, especially where the cost of error is a
player's safety rather than a look.

H4. Tier rules multiply assumptions. The tier structure itself
(low, high, max) has no measured frame cost per tier anywhere in
the record, yet at least six rules assign real content to tiers
(E8 fog lights, E15 froxel 128 at max, E16 puff counts at low,
the leap's D5 gating of fracture glow and of vent and sparks,
E25's mode interactions). Each assignment is a separate assumed
number stacked on an unmeasured structure. If the structure's
costs were measured once, most of the assignments would become
arithmetic.

H5. Animation's missing instrument is the capture, not the
number. Movement was ruled on in R50, R55, R64, R76, and R88, each
time from one owner's-eye pass on one build, and the rulings
contradict in scope (A22's hurry rule survives its own pace
target's retirement). There is no standard movement shot, no
timing log, and no consolidated movement specification, so there
is no way for two rulings to be compared or for a builder to be
wrong. The graphics stack had the same gap until its ladder
sheets existed.

H6. Retired and superseded work leaves live ghosts in all three
stacks. The pace caps are retired but their technique rule
survives (A1, A22). Two different death choreographies exist in
the record (the A5 in-game sequence and the issue 137
DeathTimeline) and no document read states which one the current
build plays. The A5 damage ladder (numbered 0 to 5) and the
damage surface ladder (stages 1 to 4 plus stage 0 squadrons) are
parallel stage systems from different jobs, unreconciled in any
document read.

H7. Sound's licence gate and its exception cannot both be the
policy, and the gap is not aesthetic. S1 forbids what S2 keeps,
the credits surface that S1's CC BY half requires does not exist
(S16), and the one settlement available (a licence read) has
never been commissioned. The red team should resist treating
this as one more tuning item: it is the only item in the pack
whose being wrong has consequences outside the game.

H8. Several settlements are nearly free and already specced by
the documents themselves: the damage build's Task 1 baseline and
Task 4 stress test (E10, E12, E13), the audio verification pass
with caps logging (S6), the largest-salvo voice test (S8), the
worst-case salvo flash test (E6), and issue 140's bake timing
(E23). The expensive assumptions are mostly expensive because
their own documents' tests were sequenced behind other work and
then the queue moved on (LOOP: terrain fx 2 sits at position 14,
behind the Nemesis builds).

## 7. Limitations and unverified list

What this red team cannot settle from documents, and claims the
chair could not source:

1. The current build's actual state, everywhere. This pack is
   built from syntheses, rulings, and issue texts. No Godot
   project was run, no cue was played, no capture was taken. Any
   item whose source says a fix was specified (S9, S10) is
   inventoried as a measured defect and a specified fix, not as
   a verified shipped fix.
2. Issue 101's delivered counts (S14). The figures (39 cues, 40
   clip sets, 128 files, synth-only zero) come from the closed
   issue's record as carried in the project record. The PR trail
   read for this pack is tangled: PR 106's body mixes a Codex
   issue 66 description with the muse/issue-101 branch line, and
   no per-cue delivery manifest was re-read. The counts are
   carried as MEASURED with this caveat attached, and the legs
   should treat their verification (a cues.json layer audit) as
   part of the settlement, not as given.
3. The G4 figure's resolution (E2). The source line does not
   state it; no leg may quote the 43 to 65 fps range as a 4K or
   1080p result.
4. The flip-and-burn test (A11). Whether the R55 side by side
   test ran, and what it showed, is not in the record read. R64
   closes the question without citing it.
5. Which death choreography the game plays (H6), whether the A5
   per-weapon sheets were ever built into the G4 pass, and
   whether the think-during-animation plan (A6) was built. The
   record read does not say.
6. Turret turn rates, squadron flight speeds and counts in the
   shipped game, and campaign map flight durations: no numbers
   exist in the record read (A15, A18, A20 inventory the gaps).
7. The quality tier table. Documents name three tiers (low,
   high, max) and cite battle.gd lines 333 to 360 for tier
   definitions, but no leg of this pack read that table; tier
   counts beyond the three named are unverified.
8. Whether the audio synthesis's build list (the 11 cue ids, the
   defer data fix, the true mute, the voice caps) was implemented
   after it was written. The synthesis is a specification; the
   record read does not include its build's delivery.
9. The vfx leap synthesis's frame cost figures are INFERRED by
   its own header (no Godot project was run). Where this pack
   repeats them (E15), they are classified ASSUMED accordingly,
   not as measurements.
10. Perceptual and auditory thresholds generally. Whether a
    2 second death reads better than a 3 second one, whether a
    voice cap of 20 clips audibly, whether a loopfind 0.55 loop
    sounds seamless: no document settles any of these. Each needs
    the owner in front of the artefact (sheets, captures, or the
    listen pass), which is the Nov 6 ruling's whole point.

## 8. Leg prompts

Four legs. The three writer legs (blind Rey, DeepSeek, Qwen) run
from this pack alone, in parallel, without seeing each other.
The Argon leg runs after them, as a review leg only. The chair
screens every leg before anything is adopted, per the standing
four-prong rule.

The lenses, named by the owner and used identically in every
writer leg:

- Game dev lens: does this number or rule bind real performance
  or gameplay? Is it denominated in the metric the engine
  actually charges for? What happens in a real battle at 20
  ships, not in a test scene or a specification?
- Domain designer lens: does this number or rule bind the craft
  of its own domain (effects design for E items, animation for
  A items, sound design for S items)? Does it buy real quality,
  readability, or feel, and who pays when it is wrong: the
  effect's read, the motion's weight, the mix's clarity?
- Agent lead lens: can the build pipeline actually produce work
  against this number or rule and measure the result? Is it
  enforceable in a review, on a sheet, a capture, or a listen
  pass the owner judges, or does it hide in a constant nobody
  runs? Does it waste runs: rebuilds, re-reviews, adjudication
  per asset?

Cost units, the only ones permitted: Codex runs (one-hour cap
per run), Opus runs, one-time script builds, per-asset unattended
runs, owner review rounds, owner listen rounds. State one-time
and recurring costs separately.

---

### Blind Rey leg (writer)

You are a blind reviewer on a game project's effects, animation,
and sound standards. One file is your complete evidence and your
complete instruction: PACK.md, the evidence pack for a red team
of the effects, animation, and sound stacks of the game Embers
of the Hollow Sun. You have no other sources. Do not browse, do
not use outside knowledge of this project beyond what the pack
contains, and do not invent facts the pack does not hold.

Task: answer the question in PACK section 1.3 for the inventory
in PACK sections 3 to 5 (E1 to E34, A1 to A22, S1 to S20), in
light of the worked example in PACK section 1.2 and the
limitations in PACK section 7. The chair's observations in PACK
section 6 are hypotheses to test, not conclusions to repeat.

Produce one report with exactly these parts:

1. Verdict: one of THE STACKS HOLD, THE STACKS HOLD ONLY WITH
   REPLACEMENTS, or THE STACKS DO NOT HOLD, applied to the three
   stacks together, followed by the three inventory items your
   verdict most depends on, named by item number (one may be
   from any domain, but say why those three). A verdict of THE
   STACKS HOLD must state what evidence, if it appeared, would
   change it.
2. Game dev lens: attack every inventory item, E1 to E34, then
   A1 to A22, then S1 to S20, in order, one entry per item: does
   it bind real performance or gameplay, is it denominated in
   what the engine or the game actually charges for, and what
   does its being wrong cost in a real battle? An entry may be
   one line where the lens genuinely finds nothing; silence on
   an item counts as a miss and the review leg will flag it.
   Mark each entry OBSERVED (present in the pack; cite the pack
   section) or INFERRED (your reasoning; say what it rests on).
   If the pack lacks a fact you need, write NOT IN PACK.
3. Domain designer lens: the same items in the same order, for
   the craft of each item's own domain: which numbers and rules
   buy real effect quality, motion weight, or mix clarity,
   which tax them without buying any, and what each error costs
   on the sheet, in motion, or in the mix.
4. Agent lead lens: the same items in the same order, for
   production: can the pipeline build to it, can a review
   measure it on the owner's sheets, captures, or listen pass or
   does it hide in a constant nobody runs, and where does it
   waste runs (rebuilds, re-reviews, per-asset adjudication)?
5. Disposition table: every item, E1 to E34, A1 to A22, S1 to
   S20, one row each: KEEP, RE-DERIVE, REPLACE, or DROP; for
   RE-DERIVE and REPLACE, the replacement approach and its cost
   in the pack's agent-term units only; for DROP, what replaces
   the protection the item was giving, or the statement that
   none is needed. A disposition that contradicts one of your
   own lens entries is an error.
6. Owner questions: at most three, each with your pick and one
   line on the stakes. Questions must be human-direction
   questions, not technical ones.
7. Not checked: what this report could not verify from the pack.

Hard constraints: no human-time estimates anywhere (no hours,
days, or weeks of human work); costs only in the units above. No
invented measurements, thresholds, or quotations. No em dashes.
Plain ASCII.

---

### DeepSeek leg (writer)

You are a blind reviewer on a game project's effects, animation,
and sound standards. One file is your complete evidence and your
complete instruction: PACK.md, the evidence pack for a red team
of the effects, animation, and sound stacks of the game Embers
of the Hollow Sun. You have no other sources. Do not browse, do
not use outside knowledge of this project beyond what the pack
contains, and do not invent facts the pack does not hold.

Task: answer the question in PACK section 1.3 for the inventory
in PACK sections 3 to 5 (E1 to E34, A1 to A22, S1 to S20), in
light of the worked example in PACK section 1.2 and the
limitations in PACK section 7. The chair's observations in PACK
section 6 are hypotheses to test, not conclusions to repeat.

Produce one report with exactly these parts:

1. Verdict: one of THE STACKS HOLD, THE STACKS HOLD ONLY WITH
   REPLACEMENTS, or THE STACKS DO NOT HOLD, applied to the three
   stacks together, followed by the three inventory items your
   verdict most depends on, named by item number (one may be
   from any domain, but say why those three). A verdict of THE
   STACKS HOLD must state what evidence, if it appeared, would
   change it.
2. Game dev lens: attack every inventory item, E1 to E34, then
   A1 to A22, then S1 to S20, in order, one entry per item: does
   it bind real performance or gameplay, is it denominated in
   what the engine or the game actually charges for, and what
   does its being wrong cost in a real battle? An entry may be
   one line where the lens genuinely finds nothing; silence on
   an item counts as a miss and the review leg will flag it.
   Mark each entry OBSERVED (present in the pack; cite the pack
   section) or INFERRED (your reasoning; say what it rests on).
   If the pack lacks a fact you need, write NOT IN PACK.
3. Domain designer lens: the same items in the same order, for
   the craft of each item's own domain: which numbers and rules
   buy real effect quality, motion weight, or mix clarity,
   which tax them without buying any, and what each error costs
   on the sheet, in motion, or in the mix.
4. Agent lead lens: the same items in the same order, for
   production: can the pipeline build to it, can a review
   measure it on the owner's sheets, captures, or listen pass or
   does it hide in a constant nobody runs, and where does it
   waste runs (rebuilds, re-reviews, per-asset adjudication)?
5. Disposition table: every item, E1 to E34, A1 to A22, S1 to
   S20, one row each: KEEP, RE-DERIVE, REPLACE, or DROP; for
   RE-DERIVE and REPLACE, the replacement approach and its cost
   in the pack's agent-term units only; for DROP, what replaces
   the protection the item was giving, or the statement that
   none is needed. A disposition that contradicts one of your
   own lens entries is an error.
6. Owner questions: at most three, each with your pick and one
   line on the stakes. Questions must be human-direction
   questions, not technical ones.
7. Not checked: what this report could not verify from the pack.

Hard constraints: no human-time estimates anywhere (no hours,
days, or weeks of human work); costs only in the units above. No
invented measurements, thresholds, or quotations. No em dashes.
Plain ASCII.

---

### Qwen leg (writer)

You are a blind reviewer on a game project's effects, animation,
and sound standards. One file is your complete evidence and your
complete instruction: PACK.md, the evidence pack for a red team
of the effects, animation, and sound stacks of the game Embers
of the Hollow Sun. You have no other sources. Do not browse, do
not use outside knowledge of this project beyond what the pack
contains, and do not invent facts the pack does not hold.

Task: answer the question in PACK section 1.3 for the inventory
in PACK sections 3 to 5 (E1 to E34, A1 to A22, S1 to S20), in
light of the worked example in PACK section 1.2 and the
limitations in PACK section 7. The chair's observations in PACK
section 6 are hypotheses to test, not conclusions to repeat.

Produce one report with exactly these parts:

1. Verdict: one of THE STACKS HOLD, THE STACKS HOLD ONLY WITH
   REPLACEMENTS, or THE STACKS DO NOT HOLD, applied to the three
   stacks together, followed by the three inventory items your
   verdict most depends on, named by item number (one may be
   from any domain, but say why those three). A verdict of THE
   STACKS HOLD must state what evidence, if it appeared, would
   change it.
2. Game dev lens: attack every inventory item, E1 to E34, then
   A1 to A22, then S1 to S20, in order, one entry per item: does
   it bind real performance or gameplay, is it denominated in
   what the engine or the game actually charges for, and what
   does its being wrong cost in a real battle? An entry may be
   one line where the lens genuinely finds nothing; silence on
   an item counts as a miss and the review leg will flag it.
   Mark each entry OBSERVED (present in the pack; cite the pack
   section) or INFERRED (your reasoning; say what it rests on).
   If the pack lacks a fact you need, write NOT IN PACK.
3. Domain designer lens: the same items in the same order, for
   the craft of each item's own domain: which numbers and rules
   buy real effect quality, motion weight, or mix clarity,
   which tax them without buying any, and what each error costs
   on the sheet, in motion, or in the mix.
4. Agent lead lens: the same items in the same order, for
   production: can the pipeline build to it, can a review
   measure it on the owner's sheets, captures, or listen pass or
   does it hide in a constant nobody runs, and where does it
   waste runs (rebuilds, re-reviews, per-asset adjudication)?
5. Disposition table: every item, E1 to E34, A1 to A22, S1 to
   S20, one row each: KEEP, RE-DERIVE, REPLACE, or DROP; for
   RE-DERIVE and REPLACE, the replacement approach and its cost
   in the pack's agent-term units only; for DROP, what replaces
   the protection the item was giving, or the statement that
   none is needed. A disposition that contradicts one of your
   own lens entries is an error.
6. Owner questions: at most three, each with your pick and one
   line on the stakes. Questions must be human-direction
   questions, not technical ones.
7. Not checked: what this report could not verify from the pack.

Hard constraints: no human-time estimates anywhere (no hours,
days, or weeks of human work); costs only in the units above. No
invented measurements, thresholds, or quotations. No em dashes.
Plain ASCII.

---

### Argon leg (review only, runs after the writer legs)

You are a review leg, not a writer leg. You receive four files:
PACK.md (the evidence pack) and the three writer leg reports
(blind Rey, DeepSeek, Qwen) for the effects, animation, and sound
red team on Embers of the Hollow Sun. Do not write a new verdict
of your own. Audit the three reports against the pack.

Produce one report with exactly these parts:

1. Quotation and fact check: for each writer leg, list every
   measurement, threshold, rule, and provenance classification
   it states that does NOT match PACK.md, with the pack location
   (section or item number) that contradicts it or the note
   ABSENT FROM PACK. List every leg statement marked OBSERVED
   whose cited pack section does not contain it. Pay particular
   attention to any leg that reclassifies an item's provenance
   (sections 3 to 5) without evidence the pack contains, and to
   any leg that quotes the G4 figure (E2) with a resolution the
   pack does not state.
2. Arithmetic check: recompute every number a leg derives (the
   E13 emitter arithmetic, px per unit conversions, salvo and
   defer arithmetic in S8 and S9, percentage and ratio claims).
   List each derivation as CONFIRMED or WRONG, with the
   corrected value when wrong.
3. Missed-item check: the pack inventory is E1 to E34, A1 to
   A22, S1 to S20. For each writer leg, list every item number
   absent from any of its three lens sections, and every item
   number absent from its disposition table. Also list any
   numeric gate or standing rule a leg relies on that is not in
   the inventory at all, flagged as either a genuine inventory
   gap (name it) or an invention (part 1).
4. Constraint check: flag any human-time estimate, any em dash,
   any cost stated outside the pack's agent-term units, and any
   owner question beyond the three-question cap, per leg. Also
   flag any disposition that contradicts the same leg's own lens
   entries.
5. Adopt/cut list: for each writer leg, an exact list: ADOPT
   (finding, lens entry, or disposition identifiers), CUT
   (identifiers, with the reason tied to parts 1 to 4), and FLAG
   (identifiers that are sound only with a correction you
   state).
6. Not checked: what this review could not verify.

Hard constraints: the pack is the sole evidence; do not browse
and do not supply project, effects, animation, or audio facts of
your own. If a writer leg and the pack disagree, the pack wins
and the disagreement is a finding. No em dashes. Plain ASCII.
