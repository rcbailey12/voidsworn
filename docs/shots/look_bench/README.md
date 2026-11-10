# Look bench baseline (issue 351)

The accepted baseline of the look bench (`godot/bench/look_bench.tscn`, run by `tools/pc/jobs/look_bench.bat`). Every later
looks job is compared with these sheets (R157). How the bench works: `godot/bench/README.md`.

- Game commit: `499aae8352bbac8158abf38faa8025ecab7f49d8` (main, Nov 10 2026), in `BASELINE.txt` (the .bat compares with it by
  default). Bench script: branch `opus/issue-351`.
- Ryan's PC, RTX 5080, Godot 4.7.2, Forward+, quality max, 1920x1080, `--fixed-fps 60`. PC-built hulls copied from
  `Downloads\voidsworn_test\audit2\repo\godot`. Run `base_e` of Nov 10 2026, made in about 20 minutes (the warm pass included).
- Sheets made on the PC with ComfyUI's portable Python (Pillow); saved here as JPG (quality 80 to 82). The tall weapon sheets are
  split in two (a and b, ten weapons each). The fleet sheets keep their 1 to 1 pixels.

## The sheets

| File | What it shows |
|---|---|
| `m1_weapons_on_a_hull_a.jpg`, `_b.jpg` | The 20 faction weapons on an unshielded hull (an Eclipse cruiser; the Chorus cruiser for the Eclipse guns). One key frame each at camera 170, 60, 26. |
| `m2_weapons_on_a_shield_a.jpg`, `_b.jpg` | The same 20 on a shielded hull (a Hegemony cruiser; a Sunward cruiser for the Hegemony guns). |
| `m3_shield_states.jpg` | Shield hit, shield low (1 of 5 left) and shield break. |
| `m4_deaths.jpg` | Hullbreaker frigate and Hegemony destroyer (small class), Sunward cruiser (big), Hegemony super-dreadnought (capital, cut), Chorus cruiser (rupture), Eclipse cruiser (burn-out hulk). The frigate and capital deaths at the shipped numbers, side by side (from retired issue 233). |
| `m5_one_weapon_every_weight.jpg` | The Sunward battleship's macro battery on an Eclipse frigate, destroyer, cruiser and Tomb-ark (one weapon on every weight, from issue 233). |
| `m6_pr327_looks.jpg` | The eight looks PR 327 changed and nobody had seen: las muzzle, prism muzzle, missile launch, torpedo on a shield, lance burn, Chorus bile hit, gauss exit, crit. |
| `f1_fleet_darkest_sky_world.jpg` | All 36 hulls at the battle camera, true pixel size, over the darkest sky (the world region, sky level 19.7). |
| `f2_fleet_brightest_sky_frontier.jpg` | The same over the brightest plain sky (the frontier region, 50.3). |
| `f3_fleet_storm.jpg` | The same on a storm map (ion storm hexes on the ship; 64.8). |
| `skies.txt` | The measured sky level of all five regions and the storm (0 to 255, the corners of every fleet cell). |

The whole 30 frames a second strips of every moment (61 moments, 12 to 16 frames, three cameras each) are made by every run in
`sheets\<run>\moments\<id>.jpg` on the PC; they are not committed here (about 40 MB).

## Repeatability: the tolerance and the exempt stills

Measured by two runs of the same commit, then a third with one number changed (PC runs 2 to 4, Nov 10). The number per
still is the mean absolute difference of the two pictures over every pixel and colour channel, 0 to 255 levels.

- **Tolerance: 2.0 levels per still.** `tools/pc/jobs/look_bench_sheets.py` uses it by default; a still over it is drawn with a
  red border and listed in `summary.txt`.
- **Runs after the first on a checkout match to the pixel:** `base_f` (second run) and `proof_e` (third run, crit number
  changed) each differ from `base_e` (first run) on the same five stills by the same numbers, and on nothing else outside the
  crit moment. So outside those five and the crit moment, all 2,443 other stills are 0.00 in both comparisons: the 216 fleet
  stills (six skies, the storm included) and every death with its wreck physics.
- **The first run after an import is off by up to 1.63 on a few stills:** `base_e` (the first run on this commit) against
  `base_f`: 5 of 2,484 stills over 0.5, largest 1.63 (`d_hulk` at camera 170, three cells at 1.39; `w_bioplasma_chor_hull` at 60,
  two cells at 1.63). Run 3 showed the same on three other moments (macro, torpedo, plasma on a hull, up to 1.63) before the
  warm pass was added. The cause is likely Godot drawing a pipeline that is still compiling with its general shader for a few
  frames; the warm pass (every row once at camera 170, nothing kept) cut it from 16 stills to 5 but not to 0. The tolerance
  sits above it.
- **Exempt stills: none.** Wreck physics (real time in the game, R118) is frame-locked in the bench: `--fixed-fps 60` moves the
  engine and physics clock 1/60 s per drawn frame and the bench draws one frame per effect step, with every worker job waited
  for. The storm repeats since the second world build waits for the frame grid and then a fixed 120 frames (run 2 had all 36
  storm stills off by up to 10.5 levels before that change).
- Not pinned, so not drawn: `render/ship_view.gd` runs the ships' idle bob and station-keeping jets on the wall clock; the bench
  parks ShipView processing, so ships hold still and those jets never appear on the bench.

## The one-number-change proof

`proof_crit_one_number.jpg`: one deliberate one-number change to one effect, the crit flash (`fx/fx_weapons.gd` `_crit`, its
`_burst` size 6.0 to 12.0, changed in the PC checkout only by `bench351\pre_crit.ps1`, never committed), benched against the
baseline. Before on top, after below, the difference number under every cell (the sheet is shrunk to 60 percent here).

- Only the crit moment differs over the tolerance: 12 of its 36 stills (camera 170: 3 cells, up to 6.25; 60: 4, up to 11.08;
  26: 5, up to 25.41). The cells before the crit lands are 0.00.
- Every other still of the 2,484 is under the tolerance: 0.00 except the five first-run stills above (up to 1.63), which
  differ the same way between the two unchanged runs, so they are the baseline's own, not the change's.
- Run 3 gave the same crit numbers to the second decimal on another commit (ad3a99e5).

## What the baseline shows (for the jobs after it)

Read at camera 170 first. These are what the bench shows today, for the jobs that come after it (the audit's findings, now on
one standing sheet):

- **Puffs.** Almost every hit, shield hit and death is a pale smoke ball; at 60 and 26 its edges are cut square (the cruiser
  death in `m4`). This is pass 2 finding 1 (the 64-cell bake), for #353 and #365.
- **Shield hits** leave a grey puff in empty space beside the bubble for most weapons (`m2`); the bubble's own ripple is faint at
  170. Shield low has no look of its own: the row looks like a hit (`m3`). For #371 and #372.
- **Deaths.** The capital (`m4`) is one pale puff beside an intact hull for the first second; small deaths throw orange flame
  bars straight up above the hull. For #354 and #366.
- **Missile launch** (`m6`): the first rocket leaves 0.45 s after the order; at camera 170 the rockets are a few pixels and the
  launch puff hardly reads.
- **Fleet** (`f1` to `f3`): at the battle camera the three craft are 2 to 4 pixels on any sky. On the storm map the dark hulls
  (Sunward destroyer and cruiser, Eclipse frigate) and the craft disappear into the bright storm cloud lattice. The Glasswright
  cruiser and Ark burn out white at the bow. For #362 (battle camera readability).
- **Skies.** By the regions' own numbers the deep region is the faintest, but on screen behind the ships the world region is the
  darkest (19.7) and frontier the brightest (50.3); deep is 32.5 (`skies.txt`).
