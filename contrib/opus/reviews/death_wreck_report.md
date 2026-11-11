# Wrecks that look blown apart, not sliced (issue 484, effects 366d)

Refs #484. Branch opus/issue-484. Visual code only (godot/fx/fx_death.gd, godot/fx/fx_hull.gd, one check). No rules, saves,
UI flow, data tables or textures changed. Reduce flashing is untouched: no new flash was added.

Ryan, Nov 11: "the wreckage comes out looking too clean at the end. It's like straight lines and even halves. It doesn't
feel like an explosion or major hit happened. It feels like they're just getting sliced in half after everything"

![Cruiser, before above after](../../../docs/shots/look_bench/deaths/cruiser_wreck.jpg)

![Capital, before above after](../../../docs/shots/look_bench/deaths/capital_wreck.jpg)

The same content as four short pictures (each 340 px tall): docs/shots/look_bench/deaths/cruiser_wreck_before.jpg,
cruiser_wreck_after.jpg, capital_wreck_before.jpg, capital_wreck_after.jpg. Cells are the bench's camera 170 frames at 0.73
of true size (true pixels clipped the 6 s wreck, which spreads wider than a 320 px cell). Second pass: "before" is main
4d13a0cb (bench run main_r4), "after" is code commit 66cebf4 (bench run after_r5), the code on this branch's head.

## What Ryan will see

- Cruiser: it breaks about a third of the way from one end, not in the middle, on a slanted, kinked, torn line. The core
  flash goes off in a bite on the side that was hit; four or so chunks of that hull fly out tumbling, glowing and cooling,
  with a cloud of torn plates. At 6 s: one big piece with a ragged red end, one clearly smaller piece, separate fragments
  and plates between them.
- Capital: three pieces of three different sizes (about a half, a third and a fifth), torn rims, dark rust fragments and
  plates thrown from the core, a scorched patch round the wound.

## How it is built (and what I tried)

The old cut gave each hull triangle to its nearest seed: one flat plane square to the length, seeds evenly spaced, so two
near-equal halves that fit back together. Big hulls (cruiser and capital class, not Chorus) now break on a fracture plan
made per ship on the main thread just before the existing worker cut (fx_death.gd `fracture_plan`, `_plan_assign`):

1. Uneven pieces. Cruiser: 31 to 37 percent and the rest, which end is random per ship. Capital: about 50, 30 and 20 percent
   in a random order. Seeded by the ship id, so a replay breaks the same way.
2. No straight line. Each break is tilted 20 to 34 degrees off square in plan and 10 to 22 degrees in pitch, bent into a V
   across the beam (two planes meeting at an angle), and torn by three summed waves (teeth about 3 percent of the length).
   All three are scaled down together when a piece is short, so breaks never cross. The V's shift of the mean line is
   corrected so pieces keep their planned sizes.
3. The bite. Centred on the hull sample furthest out on the side last hit (a per-ship side if there was no recent hit),
   on the core's break, a little into the bigger piece: an ellipsoid 0.12 L long on a cruiser (0.09 L on a capital) and
   about half the beam deep, its rim torn by two waves. It is cut into four (cruiser) or six (capital) fragments. They ride
   with the wreck until the core flash and are then thrown out tumbling (kinematic, no physics bodies). The core flash now
   sits in the bite.
4. Chips: two small wedges per break, thrown with the bite.
5. Ragged rims. Torn cap loops get bent plates peeled outward with a torn tooth (`_cap_petals`; some keep a hot rim) and
   about half their deck ribs run long past the skin. Only loops on a break or in the bite are torn (`_loop_torn`); the
   hull's own open kit edges stay plain.
6. Scorch. The hull damage shader gets up to eight wound spots (fx_scorch): soot black at the wound, a faint heat stain
   further out, sparse embers that cool with the torn faces. Off (count 0) for every live ship.
7. Debris. At the core: 7 small and 3 medium torn plates (capital 10 and 4) from the existing pool, born just outside the
   bite, on top of the plates at the break.

Also from the issue 462 list: the cruiser's chain blasts are drawn at 100 px (were 80), and the pale vent puff beside a big
hull is gone (its sparks stay). The Chorus rupture cut is warped by waves so it no longer breaks on flat Voronoi planes.

Tried and changed on the bench: round 1 had three-wave bite rims and wave-picked chips, which holed a capital's deck like
lace; a wide bronze scorch ring that turned white hulls cardboard brown; long white petals; fragments at full white heat.
Round 2 shortened the petals, made the bite one shape and the chips compact, made the scorch darker and smaller, and started
fragments cooler. Round 3 stopped petals on the hull's own kit seams.

## Second pass: look fixes (the Board and Ryan)

- Charred faces (the Board: a capital's middle piece showed a big flat tan grid face, a clean slab again). Torn faces are
  now charred black with the heat in their cracks and seams, and the deck ribs glow a third as much; no face reads as an
  even bright panel whichever way the piece turns. See the capital's 6.0 s cell.
- Secondary smoke (Ryan: "the secondary explosion smoke looks a little too even and weird"). Every blast's smoke, the
  chain blasts', the secondaries' and the core body, is now a clump of two to four pictures, seeded per ship: one large
  and the others a third to two thirds of it, born at staggered times, all on the blast point but drifting at different
  speeds into one side, turned, stretched and toned differently. The big one is always the lopsided baked seed (s0); the
  round seeds (s1, s2, a flower of equal puffs) are only used small and stretched. Secondaries vary 76 to 140 px, land up
  to 40 percent of a step early or late, and pick random plating (clumps and gaps) instead of the most spread out spots.
  The flash limit and reduce flashing are untouched: every flash still books through flash_ok and falls back to its soft
  twin. See the capital's 2.80 s cell.
- The biggest piece of a big hull turns more slowly, so it stays readable as the main wreck.

## What falls short (blunt)

- The capital's 2.32 s cell still shows a ring of round puffs. That one is not the secondaries: it is the approved core
  flash picture itself (death/capital/flash_, route B), which picks one of three baked seeds at random and two of them are
  the round flower. The same fix applies (always the lopsided seed, turned); I did not make it because the bench budget for
  this pass was spent and it changes an approved picture, so it needs its own look.
- Frame time is close to main, not equal: about 0.3 ms a frame more on average and a worst frame up to 5.4 ms (below).
- Open: lance kills are not cleaner. The cut is prepared before the ship dies, when the killing weapon is unknown, so a
  lance kill breaks the same torn way (its tear still draws straight and its faces still cool longest). Doing it properly
  means a second prepared cut per ship (double the worker cost) or a cut on the death frame; left as it is (the Board).
- At camera 60 a capital's deck shows short light sticks after the break. Round 3 removed the petals on kit seams; what
  is left looks like the hull's own kit detail, but I did not prove it on a closer sheet.
- The bite is clear at camera 60 and on the capital at 170; on the cruiser at 170 (hull about 30 px wide) it reads as a
  ragged glowing end and flying chunks more than as a crater shape.
- Not benched: Chorus (no Chorus row on the bench; a missing hull would stop the run) and reduce flashing (unchanged code
  path, no new flashes).
- After the last bench round, the PC death spawn check failed on round 3's code: on one real hull the bite's ray hit a
  part with no plating samples round it, so the core flash, its gas and body sat 4.0 units from the plating (limit 1.86).
  Fixed: the bite centre is now a real hull sample (the second pass's pictures show it). The PC death spawn check now
  passes: 33 pictures, 33 recorded, 0 stray.

## Cost (second pass: profiled, then brought back)

The Board held the merge on frame time. Measured with a profiling copy of the fleet probe (20 box ships, a death every
20 frames, RTX 5080; the fx.pend timer split per frame and every frame over 4 ms), main and the branch in the same PC
session, two runs each.

Where the first pass (7272e94) spent the extra, totals over the 660 measured frames, main against the branch:

| Part | main | 7272e94 | What it was |
|---|---:|---:|---|
| Break-up on the death frame | 21 ms | 37 ms | picking secondary sites (a fracture-plan test for 400 hull samples per piece) on the death frame, plus the fragments |
| Wreck update every frame | 65 ms | 142 ms | setting the heat of every glowing face (now up to a dozen per wreck) and the scorch on every frame, forever |
| Plates (physics bodies) | 6 ms | 11 ms | 17 more plates per cruiser death |
| Throwing fragments | 0 | 5.5 ms | ten small node moves per death, cheap |

Torn-face geometry (about 5x the vertices) did not show up as a cost: it is built on the worker ahead of time and the
probe frames that were slow were all CPU death-frame or per-frame update work.

What changed: secondary sites are picked on the worker cut ahead of the death; faces and scorch are set 15 times a second
and a wreck that has gone cold is never visited again; 10 instead of 17 plates per cruiser at the core (14 instead of 26
on a capital), born just outside the bite; rim plates and long ribs under 1.5 px at camera 170 are not built; fragments
stop drifting after 8 s.

| 20-death fleet probe | avg ms | p99 ms | worst ms | fx p99 ms |
|---|---:|---:|---:|---:|
| main 4d13a0cb, run 1 | 1.353 | 2.973 | 3.525 | 1.621 |
| main 4d13a0cb, run 2 | 1.305 | 2.732 | 2.940 | 1.543 |
| first pass 7272e94 (earlier session) | 1.856 to 2.414 | 4.522 to 6.654 | 6.105 to 14.340 | 3.061 to 3.923 |
| this branch 66cebf4, run 1 | 1.604 | 3.148 | 3.742 | 1.429 |
| this branch 66cebf4, run 2 | 1.819 | 3.917 | 5.413 | 1.639 |
| this branch 66cebf4, check_destruction's own probe | 1.604 | 2.987 | 3.390 | 1.468 |

Death-frame work is now at main's level (break-up 18 ms total against main's 20 to 21). What is left is about 0.3 ms a
frame on average: the wreck update still visits more pieces (100 to 117 ms total against 65 to 68) and the extra pieces,
plates and smoke pictures draw. The worst frame is 3.4 to 5.4 ms against main's 2.9 to 3.5: the 5.4 ms was one run's
frames 467 to 525, a cluster of overlapping wrecks with no single fx cause over 0.65 ms. Nothing of the look was given up
for this except fewer core plates and fragments that come to rest after 8 s.

- Worker cut (sandbox CPU, old cut against new on the same hull): 57 to 99 ms became 128 to 254 ms, plus the secondary
  sites now. It runs on the worker thread ahead of the death, as before.
- Cap geometry per wreck: about 1,400 to 3,200 vertices became 7,700 to 16,800. Under a megabyte per prepared ship; no
  new textures.

## Checks

- Headless in the sandbox (Godot 4.7.2): destruction_staging_check, death_plane_check, death_leap_check,
  destruction_steps_check, fx_smoke (0 stray), playtest_batch1/3, damage_surface_check, squadron_check, load_all: all pass.
  node contrib/opus/tools/run_all_checks.js: exit 0.
- New in destruction_staging_check (`_check_blown_apart`): fails when a big death has no fracture plan, its main pieces
  are near equal (smallest over 0.72 of the largest by side skin; a capital's neighbours within 0.88), the bite is missing
  or under 0.12 of the length, fewer than three fragments fly, or the first piece's torn end is one straight line across
  the beam. Main fails it.
- Look bench on Ryan's PC: three rounds in the first pass and two in the second (cruiser, lance cruiser and capital rows at
  cameras 170 and 60), 0 warnings. Evidence under Downloads\voidsworn_test\opus484\lb\ (runs\main_r1, main_r4,
  after_r1 to after_r5); fleet profiles in opus484\prof_p1 to prof_p3; check_destruction on 66cebf4 in
  opus484\checks_after_c5.txt: all pass, DEATH_SPAWN 33 pictures, 0 stray.
- Known in the PC check log, main too: death_spawn_check reads a missing `directional` uniform as a float (16 script errors
  on main); not from this branch.
