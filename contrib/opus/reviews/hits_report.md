# The hits, upgraded (issue 461)

Opus 5.5 worker, Nov 11 2026. Branch opus/issue-461. Visual code only: no rules, saves, UI flow or data exports change.
Ryan (R187): "we sort of have these weird arbitrary, like, guidance on that is making it... more restricted and less
realistic and cinematic than it should be". R193, "Flame only": flame snuffs out in 0.70 s; sparks, debris, gas and
embers live their own longer lives, and scorch stays.

Pictures (docs/shots/look_bench/hits/, every one named on the picture, none taller than 720 px; before is main, after is
this branch, both benched twice on the RTX 5080 with the second run kept):

| Picture | What it shows |
|---|---|
| hits_ladder.jpg | las, macro, lance, torpedo on a hull, torpedo on a shield at the battle camera, before above after |
| hits_gun_size.jpg | the same battery from a frigate and from a battleship on the same cruiser |
| hits_linger_torpedo.jpg, hits_linger_macro.jpg, hits_linger_lance.jpg | what each hit throws and leaves, 0.3 to 6 s, 1 to 1 pixels |
| hits_neighbour_light.jpg | a torpedo hit beside a parked cruiser |
| deaths_core_and_wreck.jpg | the capital's core flash and its smoke; the cruiser's wreck at 6 s |
| deaths_lance_cut.jpg | a lance kill, cameras 60 and 26 |
| hits_fight_before.mp4, hits_fight_after.mp4, hits_fight_strip.jpg | the 20-ship storm battle, the same fixed-clock fight, at the battle camera |

## What was built, against the Done-when

1. **A recipe per weapon family** (fx_weapons.gd `family_of`, `_shell_hit`, `_energy_hit`, `_beam_burn`, `_big_hit`,
   `_bio_splat`, `_gauss_punch`). Shell: a white bite, a spark cone that skips off the plate (the shell's path reflected
   off the plate), torn chips, dust that hangs, embers, a dent that glows and cools. Energy: one or two frames of white,
   a flat splash ring and drops that skate along the plate, a short scorch, no smoke (plasma keeps a little vapour and
   blue slag; prism a rainbow glint). Lance: the contact burn crawls along the hull while the beam dwells (pulses at the
   lance size, molten spray), a third of a second of tail, a line of hot spots that glows about 3 s; ion burns
   blue-white with arcs and no molten metal. Torpedo: the baked fire through gas, then torn plates thrown in a cone,
   sparks, gas and dust for seconds, embers, a 4 s cooling wound. Bio: the wet splash and an acid fume that hangs.
   The check proves the families differ (shell sparks leave the plate at a mean outward share of 0.95, the energy splash
   at 0.12; the lance leaves 8 glowing points along its line; the ion throws no molten spray).
2. **Sized by the gun as well as the target.** Flash = the ladder row (las 40, macro 56, heavy macro 64, lance 78,
   torpedo 140, torpedo on a shield 110 with a 156 px ripple) x the firing hull's band (0.85, 1.0, 1.2) x the hit hull's
   band (0.8, 1.0, 1.2). Measured on the bench (lit blob against the frame before the shot): a frigate's battery hit
   43 px, a battleship's 54 px, on the same cruiser (main: 13 and 19 px). The old F3 sizes chosen to stay under the old
   65 px count (fx_weapons.gd lines 64 to 69) are gone for hull hits.
3. **Matter that is thrown and lingers.** Sparks 0.35 to 0.9 s, debris 1 to 4 s, gas and dust 2 to 4 s, embers 1.4 to
   3 s cooling yellow-white to dark red with no flicker; no hit flash lives past 0.70 s (the check reads every flash's
   life). Sparks, embers and drops keep pixel floors (3 px, trails 7 px) so they read at camera 170. Scars: a ship keeps
   24 marks (8 a section) where it kept 12 (4); the old ones are no longer deleted after a dozen hits.
4. **Light on neighbours.** `fx.light(..., reach)`: a torpedo's light reaches 36 units (about two hexes), a death's core
   flash 26, 35 and 52 (frigate, cruiser, capital), with a slower falloff (`REACH_ATTEN` 0.6 against the standing 1.2).
   Honest result: on the bench a white cruiser parked 15 units from a torpedo hit gets about 1 percent brighter at its
   nearest plating for a tenth of a second (main: about 1 percent less than that). It is visible as a warm tint on its
   bow in hits_neighbour_light.jpg, not as a strong light. A stronger light is a bigger flash on the hulls it lights, and
   the counter does not measure lit hull area (504 report, "What I am unsure of"), so I did not raise the peak past the 8
   that counts. Ryan's call if he wants it stronger.
5. **Direction.** Every thrown piece is lifted off the plate's normal (`_outward`); the check found 0 inward pieces over
   nine weapons.

Carried items:
- **(a) Core flash ring.** The death core flash (and the macro and torpedo hit pictures) always use the lopsided baked
  seed s0, turned at random; the round "flower" seeds s1 and s2 are no longer picked for them. deaths_core_and_wreck.jpg.
- **(b) Lance kills cut clean.** On a lance kill of a big hull the cut is re-planned on the death frame along the beam's
  line (the break nearest the beam lies on it, square-ish to the beam, no kink, almost no teeth, a smaller bite), and the
  cut runs on a worker during the tell; if a damage refresh of the cut is still running it is left to finish and the
  lance cut starts beside it. deaths_lance_cut.jpg: the tear and the break sit further aft, on the beam's point.
  Cost: one extra worker cut per lance kill of a cruiser or capital, and the main-thread mesh gather on the death frame
  (`fx.prof` section `lance_recut`).
- **(c) The cruiser's bow piece at 6 s.** Big pieces tumbled on a random axis and by 6 s showed the key light their dark
  bellies. Main pieces of big hulls now turn mostly about the vertical (roll and pitch a quarter of before), so their
  plated tops stay lit. deaths_core_and_wreck.jpg, the two 6.0 s cells.
- **(d) Engine flicker.** The engine core's fast flicker is 0.95 to 1.0 (was 0.85 to 1.0), kinds 4 and 11; the stale
  comment at fx_ship.gd:239 is fixed. Measured on the bench's engine row (a Hegemony cruiser at full burn, 16 frames,
  the core pixels' screen luminance): camera 26, swing 2.1 percent before, 1.4 percent after; camera 60, 1.3 and 1.0;
  camera 170, 0.9 and 0.8. Far under the 10 percent a general flash needs. The Hullbreaker core's slow "cough"
  (drops to 0.12 about once a second, on purpose) is unchanged: see "For the Board".

## The flash counter in the 20-ship storm gate

The counter itself is unchanged (limit, window, three a second). Every new bright hit flash registers with it, at the size
it is drawn with its bloom (`px / BURST_PX_K`). Two changes in how hits ask:
- The torpedo flash is 140 px, not 154: a lone 154 px flash is over the limit (a disc of about 141 px) and so every
  torpedo spent one of the three flashes a second.
- Gun hits and muzzle flashes never spend the budget (`flash_at(..., yield_last)`): one that would need counting is drawn
  soft (same size and colour, slower rise). Torpedoes and deaths still book normally. Without this, salvos of shell hits
  stacked past the limit were counted, often booked ahead at the volley's fire time, and in two gate rounds a frigate's
  and a cruiser's core flash were turned soft behind them.

Base mode is 12 s of the storm battle with volleys about three a second; deaths mode adds three deaths. Two sessions a
round. "Yielded" is a gun hit drawn soft rather than counted (new); "refused" is the counter turning a flash soft.

| Round (commit) | counted | refused (px of each) | gun hits yielded | what changed |
|---|---|---|---|---|
| main 057fb93c and 335cf1f2, 8 sessions | 0 to 11 a session | 0 | (none) | before |
| after2 440c72d5, 4 sessions | 2 to 10 | 7: 35, 35, 63, 40, 76, 216, 302 | (none) | hits bigger, booked at drawn size: a frigate's (216) and a cruiser's (302) core flash refused |
| after3 to after5, torpedo 140 px, 12 sessions | 0 to 14 | 11, among them a frigate core (216) and a cruiser core (302) once each | (none) | hits pre-booked at fire time still took the slots |
| after6, after7 d6b700e7, 8 sessions | 0 to 8 | 0 | 2 to 15 a session | gun hits yield |
| after8 ab819b7d, 4 sessions | 0 to 9 | 1: a cruiser core (302) | 2 to 8 | the shield torpedo booked at 169 px (Muse's check of PR 524; fixed in c8a2634) |
| **after9 c8a26348 (the head), 4 sessions** | 0 to 9 | **0** | 2 to 12 | final |

So at the head: the counter refused nothing in the gate, and every death's core flash drew bright. What gave way: 2 to 12
gun hits a session (each 30 to 80 px, a few a shield torpedo's 75 px) were drawn with the soft rise instead of the sharp
one, at full size and colour, inside a salvo. Torpedoes still book the budget like deaths do, so a core flash can still be
refused when several torpedoes and deaths land in the same second; it happened in no session of the final policy.

## Cost

20-ship storm gate, RTX 5080, 1920x1080, Forward+, vsync off. Medians over sessions (main: 4 per mode from two rounds;
branch: 6 per mode from rounds after6, after7, after9). Frame interval is the whole frame; GPU time is the GPU's own.

| Mode | frame median, before / after | frame p99 | GPU median | GPU p99 |
|---|---|---|---|---|
| base | 7.20 / 7.56 ms | 13.93 / 14.89 ms | 2.42 / 2.36 ms | 3.01 / 2.78 ms |
| deaths | 8.06 / 6.72 ms | 13.77 / 11.89 ms | 2.51 / 2.46 ms | 3.10 / 2.83 ms |

Session to session the same commit moved by up to 4 ms of frame interval (other jobs shared the PC; after9 waited 5
minutes for the GPU), so the frame differences above are inside the noise. GPU time did not grow. One more worker cut per
lance kill of a big hull and up to 24 marks a ship are the new CPU costs; neither shows above the noise in the gate.

No new textures: texture memory 1,602 MB before and after. Video memory 2,420 to 2,500 MB in both. The PC was shared
with other jobs during these runs (frame intervals moved by up to 4 ms between sessions of the same commit); the GPU time
is the steadier number.

## Checks

- New: godot/fx/test/hit_recipe_check.gd (in godot_checks.txt and check_destruction.bat). The ladder steps; the gun and
  the target size the hit; nine weapons make their recipe; no flash past 0.70 s; sparks under a second; nothing thrown
  inward; the families differ; torpedo light reach; reduce flashing books and counts nothing; gun hits yield and deaths
  keep the budget; a lance kill re-plans its cut on the beam's line (no kink, on the beam's point, not pitched) even with
  the first cut still running, and breaks up; the engine flicker constant; the scar cap.
- On the PC, headless, at the head c8a26348 (chk_c8): hit_recipe_check, flash_area_check, destruction_staging_check,
  fx_smoke, death_plane_check, destruction_steps_check, damage_surface_check, death_leap_check, playtest_batch1_check,
  playtest_batch3_check, squadron_check: all exit 0. HIT_RECIPE failures=0; "shield torpedo: row 75 px, booked 75 px"
  (box ships: a small gun on a small target, 110 x 0.85 x 0.8). FX_SMOKE stray=0.
- Not run here: the GPU checks (godot_gpu_checks.bat) and death_spawn_check on real hulls; CI runs the headless list.
- Checks changed on purpose: none of the existing checks needed a number changed. The sweep (rules_sweep_checks.md C3, C7)
  found no exact HIT_PX, MUZ_PX or light-range guard; the comfort contracts (three a second, zero in calm) still hold in
  flash_area_check, destruction_staging_check and fx_smoke.

## Reduce flashing

Unchanged: every new flash goes through `_burst` or `_staged_hit`, which draw the soft twin under reduce flashing and book
nothing (the check runs every new hit with reduce flashing on: zero booked, zero counted). The engine core keeps its slow
breathing under reduce flashing (flick() is unchanged).

## What falls short (blunt)

- Light on neighbours is real but faint (above).
- The lingering matter reads gently at camera 170: a puff of dust, a cooling spot and a few embers for 1 to 3 s, gone
  by 4 s except the hull mark. Realistic, not loud. Debris chips are dark and small at 170.
- The las hit's flash sits below the target's hull in the bench row (a shot that lands on the lower edge); it does on
  main too.
- On a lance kill the tear is straighter and on the beam's point, but at camera 60 the difference from a torpedo kill is
  modest; the tell's own shader still draws its tear the same way.
- Gun hits that would need counting are now drawn soft rather than bright: in a dense salvo some shell flashes rise
  slowly (2 to 12 a session in the gate).
- The filmed fight (hits_fight_*.mp4) holds the battle camera on the player's line where the bench's third death is set;
  the deaths themselves happen off that frame, and at camera 170 the hit changes are small in it. The bench strips show
  the hits better.
- Not built: faction-specific deaths and hits beyond the nearest-row rule; shields (waits on Ryan's pick).

## For the Board (and Ryan)

- The Hullbreaker engine core "coughs" (kind 11): about once a second its brightness drops to 0.12 for a fifth of a
  second. That is a deliberate junky look, but it is a large swing on a white core; at the close cameras a few
  Hullbreaker capitals could approach a general flash. Not changed here.
- If Ryan wants the neighbour light stronger, the counter should first learn to measure lit hull area.
- **For Ryan, a table amendment:** the torpedo-on-a-hull flash is built at 140 px, not the playbook's 154 (the playbook
  row now says so). 154 px alone is over the flash counter's limit, so every torpedo spent one of the three flashes a
  second and deaths' core flashes were turned soft behind them. hits_ladder.jpg shows the 140 px torpedo.
- Muse's outside check of the early push (PR 524 at e2c34ab, contrib/muse/reviews/opus_check_524.md on muse/issue-256):
  all five conditions are done (the evidence is in the PR; the shield torpedo is asked at its row and the check proves
  it; the playbooks agree with the build on ion, the 140 px torpedo and the ladder steps; the needle exception and the
  lance cut's limits are written down; faction_look.gd's accent comment is fixed).

## Evidence on the PC

Downloads\voidsworn_test\opus461: lb\runs\main_*, main2_*, after*_ (look bench), gate_* (gate, film, flash events),
chk_c* (headless checks). Job files: run461.bat, chk461.bat, seq461*.bat, zipfilm.bat. Nothing was deleted.
