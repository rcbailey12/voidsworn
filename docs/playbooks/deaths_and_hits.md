# Design: big hits and ship deaths

Issue 405, effects track; the design behind issues 365 and 366. Written by the Board (Fable 5.2), Nov 11 2026, at Ryan's ask
("Deaths and hits design"). It says what the player sees, beat by beat. Sizes and times come from Muse's staging table
(contrib/muse/design/hit_staging_2026_11/synthesis.md); how to build and prove an effect is docs/playbooks/effects.md.

Ryan, Nov 10, on the explosion routes: "Far right in both for sure. We need to upgrade the effects a bit but it's the right
approach." This page is the upgrade. Every fire and flash below is route B with the hot core.

## Rulings of Nov 11 that change this page (read first)

- **Wrecks are blown apart, never sliced (R186).** Ryan: "the wreckage comes out looking too clean at the end. It's like
  straight lines and even halves. It doesn't feel like an explosion or major hit happened. It feels like they're just getting
  sliced in half after everything". Every big death: uneven pieces, no straight line across the hull, a missing bite where the
  core went off, ragged scorched rims, fragments between the pieces. A lance kill may stay cleaner along the beam's line.
  Built: issue 484 (contrib/opus/reviews/death_wreck_report.md).
- **The 0.70 s cap is for flame only (R193 (3), "Flame only").** Flame still flashes and snuffs out ("fire is wrong for space"
  stands); sparks, debris, gas and cooling embers get their own longer lives, so hits throw things and leave marks. The cap
  had been applied to all of them, so nothing was thrown and nothing lingered.
- **The kill moment holds and slows (R193 (2), "Hold and slow").** The kill camera stays through the core flash and a short,
  skippable slow-motion beat plays on cruiser, capital and flagship kills. This replaces the Board's old line "the camera is
  never taken for a capital death" (R123). Built: issue 521 (PR 525).
- **The flash counter counts by area (R193 (1), "Count by area").** Still at most three big flashes a second, but "big"
  follows the W3C guideline's combined area inside a 10 degree window, worked from a stated screen size and distance
  (default a 32 inch screen at 24 inches). Reduce flashing is untouched. Built: issue 504 (PR 512,
  contrib/opus/reviews/flash_counter_report.md). The counter protects comfort for everyone; tune inside it.
- **Torpedo on a hull: 140 px, not 154 (R208 (2), "Yes, 140").** A lone 154 px flash was over the counter's limit and pushed
  deaths' core flashes soft.
- **Hits must read at the battle camera (R208 (1), "Merge, then push harder").** The first hits build (issue 461, PR 524) was
  real but subtle at camera 170; a second pass (issue 538) makes thrown debris, sparks and smoke bigger and longer-lived.
- **Light on neighbouring hulls stays faint for now (R208 (3), "Keep it faint for now")**, at the peak the counter need not
  count, until a counter measures lit hull area.
- **Breaks show insides, never a hollow shell (R209, R215).** Ryan: "so we don't run into the issues of before with just empty
  looking husks or anything similar." Hits, wounds, breaks and deaths use the hull's built insides where they exist (decks,
  frames, machinery, lit or burning spaces). docs/playbooks/ships.md, "The insides".

The rest of this page is the Nov 11 morning design; where it disagrees with the lines above, the lines above win.

## What was wrong before the Nov 11 builds (from the sheets)

- A hit is a pale cloud with no fire in it. A death is a faint puff near the stern.
- Nothing announces a death. The ship sits unchanged, then the puff arrives: no lights dying, no tear, no build-up.
- Nothing lights anything else. A torpedo going off beside a cruiser does not touch the cruiser.
- Wrecks go straight to dark. Nothing glows and cools.
- Every faction dies the same way.

## Six rules

1. **Light, then matter, then dark.** A white flash first, fire seen through gas second, cooling coals last. In that order,
   every time, so the eye learns it.
2. **Flash and snuff out: flame only.** No flame lives longer than 0.70 s; no hot core holds full heat longer than 0.25 s
   (owner ruling: fire is wrong for space). The dark gap after a flash is what makes the next one read. Never rolling fire.
   The cap is for flame alone (Ryan, R193, "Flame only"): sparks, debris, gas, dust and cooling embers live their own,
   longer lives, and scorch stays (see "The hits, upgraded"). Ryan's reason (R187): the old guidance made battles "more
   restricted and less realistic and cinematic than it should be".
3. **A bigger ship dies longer, not just larger.** A frigate is gone in under a second. A cruiser takes about three and a
   half. A capital takes about four and a half and leaves a wreck that glows for a quarter of a minute.
4. **It starts on the ship.** Every jet, tear, flash and blast sits on a hard point, a breach anchor or the surface the shot
   hit. Nothing floats beside the hull.
5. **Read it at the battle camera.** Each beat must be told apart at camera 170 without zooming. Detail for camera 26 is a
   bonus.
6. **Each faction breaks its own way** (docs/playbooks/factions.md, "How it breaks"). The beats and sizes are shared; the
   matter is the faction's.

Recipe ships carry authored interiors and weak joints in the GLB (`RECIPE.md`, stage 7, issue 557). The fracture prefers
those joints with the current ragged tear, bite and chips; wounds and pieces expose the authored rooms. Issue 600 (RULEBOOK
5.17): the tear follows each seam's authored plan path from the export, torn by waves, never a straight slice; every
machine rides whole with its piece (its box comes from the export); and the plating and the insides under it tear at the
same ragged line (triangles across the tear are split along it, the narrow strip it runs through is blown away), so no
deck or bulkhead is left whole across a break or sticks out of the wreck. `fx/test/death_seam_check.gd` kills A16 and
counts both: zero (any ship's GLB can be given after `--`; A17 is zero too, issue 532). Its unpainted A16 fixture carries a
record of the sheet files it was exported from, and the check fails when they change until the fixture is regenerated
(`tools/recipe/sheet_fixture_hash.py` lists the steps; opus_check_608 note 3). A ship without
that record keeps the #167 fallback. Main wreck bodies retain their split altitude (linear Y lock, zero Y release
velocity), while tumbling freely, so physics cannot push the readable wreck under the board. This does not constrain all
small fragments; `death_plane_check.gd` protects the existing behavior.

The kill camera holds through the core flash on cruiser, capital and flagship kills, with a short skippable slow beat
(R193 (2)). Reduce flashing keeps every size and swaps each white flash for the
softer rise and fall the staging table gives.

## A death in three beats

Times are seconds from the killing blow. Sizes are at 1080 at the battle camera.

### Cruiser (and any flagship of cruiser size)

| Beat | When | What the player sees |
|---|---|---|
| 1. The tell | 0.0 | The killing hit plays its own row (a torpedo on the hull: 140 px flash, issue 461). |
| | 0.0 to 0.3 | The ship dies inside: engines flare once, about a third brighter for two frames, then go black; running lights go out bow to stern. This must be plain at camera 170. |
| | 0.3 to 1.38 | A glowing tear opens along the break line, growing from the side that was hit, white-hot at its tip and ember behind. Three chain blasts walk along it at about 0.5, 0.8 and 1.1 s, each at least 75 px, each a flash with a hot core that is gone in a quarter second. Narrow jets of fire, then gas, vent from the breach anchors. |
| 2. The break | 1.38 | The hull is blown apart along the tear into uneven pieces with ragged scorched rims and a bite missing where the core went (R186), each starting a slow tumble. |
| | 1.66 | The core flash: 302 px for 0.20 s, at the lip of the torn face, and it lights every hull within about two hexes. |
| | 1.66 to about 5 | The body: 260 px. Fire shows through the gas for at most 0.70 s, then gas alone thins and drifts. Shrapnel streamers leave along the plane of the break. |
| 3. The wreck | 2.1 to 4.9 | Five secondaries on each half, each at least 75 px, staggered, each lighting its own half. |
| | to about 10 | The torn faces show their decks, glowing white, then orange, then dull red, then dark. Gas trails thin out. The halves stay on the board as wreckage. |

### Capital, carrier, barge (and the biggest flagships)

The cruiser's death, longer and heavier:
- The tell runs to about 2.0 s. Lights die deck by deck. Five chain blasts walk the break line. The hull shudders (a small
  shake of the ship itself, not the camera).
- The core flash is 423 px for 0.22 s and lights hulls within about three hexes. The body is 380 px for about 4.5 s.
- It breaks into three pieces along its authored lines: two halves and one more (a spire line, a module, a shade band: the
  faction's sheet says which).
- Ten secondaries. Coals cool for about 14 s. The pieces drift apart slowly and stay.
- Board proposal for Ryan's eye on the sheet: straight after the core flash the whole scene dims a little for a fifth of a
  second, so the flash feels like it took the light with it. Off under reduce flashing.

### Frigate, escort, destroyer

Fast, because they die often and must not clutter the board:
- 0.0: lights cut at once. One hot jet from the hit point.
- 0.0 to 0.72: the hull spins, trailing a curling ribbon of fire, then gas.
- 0.72: the pop. Frigate: 216 px flash for 0.18 s, 180 px body for about a second. A destroyer sits between frigate and
  cruiser: about 255 px (the same 1.4 step taken half way).
- Two to four chunks and their streamers fly; one surviving chunk keeps coals for about six seconds.

### Small craft (wings)

A single-frame spark and a puff, under 40 px, no wreck. Twenty of them dying must never hide a cruiser.

### What killed it changes the tell and the break (the game already names the cause)

| Cause | The tell | The break |
|---|---|---|
| Lance (cut) | The tear is the cut: a straight white line along the beam's path. | Two clean halves; the cut faces glow longest. |
| Torpedo or ram (big) | Chain blasts walk away from the impact. | Shrapnel leaves in a cone away from the impact. |
| Gauss (flay) | Many small punctures, each a thin gas jet. | More, smaller pieces; no single big half. |
| Acid or spines (melt) | No tear: the hull sags and glows a sick yellow-green. | Few pieces; a soft bloom, pale core, no hard white. |
| Burn-out (dark) | Lights and engines die; one vent of gas. | No break: a whole cold hulk drifts. No fire at all. |
| The dead star (tidal) | The hull stretches toward the well. | Pieces stream toward the star in a curve. |

## How each faction dies

The flash core stays white or near white for everyone, so a death always reads as a death. The faction colours the rim, the
body and the wreck.

- **Sunward Crusade.** Splits lengthwise between its gun decks. Magazines go off as an even row down the broadside, a
  drumbeat a quarter second apart. The spire line snaps off as one piece and tumbles away still glowing ember. Inside: iron
  decks lit orange.
- **Hegemony Navy.** Breaks at the module joints, the rims torn and scorched (R186). Blue-white arcs jump the gap for a third of a second instead of
  fire. Lights die on every module at the same instant. Few secondaries, evenly timed. Its drones go dark and drift.
- **Ashfall Hullbreakers.** Patch plates tear loose during the tell, four to six of them spinning off. The halves part, the
  chains between them hold for about half a second, then snap with a second jolt. Secondaries are uneven and too many. Red
  and orange; loot and frames spill out.
- **The Glasswrights.** It shatters. White fracture lines race across the optics, then the stored light spills: a white core
  with a rainbow fringe, the only coloured flash in the game. Whole panes and rings shear off and tumble, glinting. No fire
  and no smoke: glittering dust. The light inside the shards fades slowly.
- **Eclipse.** It peels. Shade plates lift away band by band, a beat apart, during the tell. The trapped core gutters
  green-white, the scene around it dims for an instant, then one small hard flash and it is out. No fire. The plates drift.
  (In sector 3 the Nemesis's plates drift back together: the comeback.)
- **The Chorus.** It bursts. Sacs rupture in jets of yellow-green; the body tears and trails wet strands; bone shows inside.
  A pale bloom, never a hard white. The pieces twitch for about a second. The glow in the sacs fades last.

Faction deaths need the new hulls' authored break lines, so they are built on the two fleets of the finished battle first.
Until a faction's hulls are rebuilt it uses the shared cruiser, capital and frigate deaths above.

## The hits, upgraded

One ladder, each step plainly bigger than the last at the battle camera: las, macro, lance, torpedo, death. Built in issue
461 (contrib/opus/reviews/hits_report.md). The sizes below are starting points judged by eye in a moving fight, not gates
(R187): checks protect crashes, saves, comfort (reduce flashing, the flash counter) and frame rate, never a look.

| Hit | Flash | Body | What stays |
|---|---|---|---|
| Las | 40 px, one or two frames of white. | A tiny hot spark. No smoke. | A small scorch that glows for about a second and a half. |
| Macro | 56 px. | A punch: a short cone of sparks off the plate and a brief hot spot. No fireball. | A dent that glows and cools over about two and a half seconds. |
| Lance | 78 px each pulse. | A contact burn that stays lit and crawls along the hull while the beam dwells, spraying molten metal; a third of a second of tail when it lifts. | A cut line that glows for about three seconds, then a dark scar. |
| Torpedo on a hull | 140 px for 0.16 s (built at 140, not 154: a lone 154 px flash is over the flash counter's limit and spent the budget deaths need, issue 461), and it lights the hulls near it. | 140 px: fire seen through gas, then gas; debris sprays off the surface. | A wound that glows and cools over about four seconds, then a dark crater that stays. |
| Torpedo on a shield | 110 px. | The ripple: 156 px, the biggest body of any hit. | A shield scar for about a second. (The shield's own look is Ryan's pick from Muse's three directions.) |

Three upgrades run through all of them:
1. **Wounds.** Every hull hit leaves a mark that glows and cools, then stays as a scar. A ship that has been in a fight
   looks like it. (Built: a hot spot that cools over 1.5 s for energy, 2.5 s for shells, 3 s along a lance's line and 4 s
   for a torpedo, over the hull mark of R43; a ship keeps 24 marks, 8 a section, where it kept 12 and 4.)
2. **Light on neighbours.** Torpedo hits and every death light the hulls around them for the length of the flash. (Built:
   a torpedo's light reaches about two hexes, 36 units; a death's core flash 1.5, 2 and 3 hexes for a frigate, cruiser and
   capital; every other light keeps the standing 30 units, about 1.7 hexes.)
3. **Direction.** Sparks and debris leave the surface along its outward side, in a cone. Nothing sprays into the ship.
   (Built: every thrown piece is lifted off the plate's normal; a shell's spark cone follows the shell's own path
   reflected off the plate, so it skips.)

How each family's hit is built (godot/fx/fx_weapons.gd, `family_of`):
- **Shell** (macro, autocannon, scatter, craft guns, flak, gauss): a short white bite, a cone of sparks that skips off the
  plate, torn chips, a puff of dust that hangs, embers, a dent that glows and cools.
- **Energy** (las, plasma, prism): one or two frames of white, a splash that runs out along the plate (a flat ring and
  drops skating over it), a little vapour, a short scorch. Prism adds a rainbow glint; plasma throws blue slag.
- **Lance** (lance, ion, pulsar, doom, needle): the contact burn crawls along the hull while the beam dwells, pulsing at
  the lance size and spraying molten metal; a third of a second of tail when it lifts; the line glows about three
  seconds. The ion beam burns blue-white with crawling arcs and throws no molten metal.
- **Torpedo**: the baked flash and fire through gas, then torn plates thrown in a cone, sparks, gas and dust that hang
  for seconds, embers, a wound that cools over four seconds, light on the hulls about two hexes round.
- **Bio** (Chorus): the wet splash with bile drops and an acid fume that hangs while the acid eats.

The needle (the Glasswright light beam turret) is drawn as a lance burn but sized from the energy row (40 to 52 px): it is
a light gun, and a lance-sized burn would outrank the macro.

A lance kill on a big hull (cruiser class and up, not Chorus) re-cuts the hull on the death frame along the beam's line:
the break nearest the beam lies on the beam's point, square-ish to the beam (within 34 degrees), with no kink and almost
no teeth, and a smaller bite. On a two-piece hull the cut is kept between 0.3 and 0.7 of the length so neither half is a
sliver; with no recent hit on record it falls 0.12 of the length off the middle (an even split reads as sliced). Small
hulls and the Chorus keep their own cuts. Lifting either limit is a look call, not a rule.

Sizes follow the gun as well as the target: a hit's flash is its row's size times the firing hull's band (small 0.85,
cruiser 1.0, capital 1.2) times the hit hull's band (small 0.8, cruiser 1.0, capital 1.2). Matter lives: sparks 0.35 to
0.9 s, debris 1 to 4 s, gas and dust 2 to 4 s, embers 1.4 to 3 s; no flash past 0.70 s.

Faction weapons take the nearest row and their faction's matter: the Glasswright prism lance is a lance with a white core and a
rainbow fringe; the ion beam is a lance burn in blue-white with crawling arcs and no molten metal (built so in issue 461; this line once
said a macro hit); Chorus acid is a torpedo row with the melt
look (built in issue 461 as its own wet splash with bile drops and an acid fume that hangs, at the bio size; the
Glasswright prism shard gun is the energy row with a rainbow glint).

## What Ryan will be shown

1. The hit ladder: one strip at the battle camera, las to torpedo, before above after.
2. A cruiser death: eight frames across its three beats, before above after.
3. A capital death: the same, with the scene-dim proposal on and off.
4. Later, per rebuilt faction: its death beside the shared one.

## Build order (jobs written from docs/playbooks/effects.md's template)

State on Nov 11 evening: 365 (rebake) merged and closed; 366's parts landed (or are landing) as 462 (death beats), 484 (wrecks), 461 (hits, waiting on Muse's re-check:
PR 524) and 521 (kill moment); 366 and 365 closed (R201). Next: 538 (hits pass 2), 463 (small-ship deaths), then faction
deaths on the rebuilt hulls. The list below is the original plan.

1. Issue 365: rebake by route B with the hot core: the death core, the secondary, the chain blast, the torpedo, the macro
   spark, the vent jet, each at the size its row needs so nothing is stretched. Codex, GPU.
2. Issue 366a: the hit ladder with wounds, light on neighbours and direction. Codex.
3. Issue 366b: cruiser and capital deaths in three beats (the tell made visible, the tear, chain blasts, core flash at the
   torn face, secondaries at 75 px, cooling faces). Codex.
4. Issue 366c: frigate, destroyer and small craft deaths. Codex or DeepSeek (resizing and timing).
5. Issue 366d and on: faction deaths, one faction at a time as its hulls are rebuilt.

Each is one or two Codex runs and one look from Ryan.
