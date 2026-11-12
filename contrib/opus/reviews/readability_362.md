# Issue 362: battle camera readability pass (Opus worker report, Nov 12 2026)

Branch opus/issue-362, PR 580. Game change: `godot/render/look.gd` (per faction hull numbers, READ; the rim light hook) and
`godot/render/look_rim.gd` (new: the rim light). No rebakes, no change to ship_view.gd or godot/fx/. Evidence:
`docs/shots/look_bench/readability/` (README.md has the band, stated first in commit 18d9dcee before any measurement).

## Answer first

- Every one of the 30 faction ships now sits inside the stated band (lit side 100 to 190) on the darkest sky, the brightest
  sky and the storm map: 101 to 181 after, against 63 to 216 before (18 of 30 were outside). Ryan's R227 lifts
  (Eclipse 2.2 after his second look, Hullbreakers 1.25; job F, ad627af7): Eclipse 101 to 112 and Hullbreakers 115 to 145
  on the darkest sky. Eclipse 2.2 is the darkest setting that keeps every Eclipse ship at 100 or more; 1.8 drops the
  Tomb-ark to 96. Ryan's picture: `eclipse_camera60_r227.jpg` (camera 60, true pixels).
- No hull is lost on the darkest sky: at least 70 percent of every outline is lit (the Eclipse Tomb-ark D22; before: 55
  percent for the Tomb-ark, 63 to 74 for the other Eclipse ships).
- Glasswrights stop burning out: lit side 206 to 216 down to 160 to 180, glow halo 36 down to 17 at most, line detail up
  (spread 10 to 20, now 18 to 26), clipped pixels 1.1 percent at most (rule: 2).
- No effect or shield look changed by accident: outside the hulls the bench moments differ only where a hull itself moved
  (capital death pieces) or where a hull's own glow sits behind a shield bubble (details below).
- Scene gate (R116, 12.5 ms): GPU at 4K 5.44 to 5.45 ms, frame median at 1080p 4.67 to 4.50 ms (run to run noise). No late
  shaders.
- Ryan's eye is the judge of "can tell every faction apart": `phone_world_1.jpg` to `_5.jpg`.

## The band and the rules (stated before any change)

docs/shots/look_bench/readability/README.md, top section: lit side = mean level of the brightest quarter of a hull's
interior pixels (75th to 98th percentile, Rec. 709 luminance of the drawn sRGB values); band 100 to 190; clip at most 2
percent of hull pixels; edge on the darkest sky at least 60 percent of outline pixels 12 levels above the sky just outside.
After the first measurement I added two reported numbers (halo, lines), because the clip rule did not catch the
Glasswright burn-out: their hulls sat at about 215, under the clip level, and the white showed as glow off the hull. That
addition is marked as made after the first measurement.

## How it was measured (real functions, battle camera, true pixel size)

- `pc/readability_probe.gd` extends the look bench script (`godot/bench/look_bench.gd`) and draws its fleet part exactly as
  the bench does (AI_HULLS, ShipView set up as the battle does, camera 170, 400x240 crops at 1 to 1), then one more frame per
  ship with only the hull surfaces drawn unshaded white: the hull mask. Copied into the PC checkout for the run only, never
  committed under godot/.
- `measure.py` reads each still with its mask. `sheets.py` makes the sheets and the table.
- Ryan's PC (RTX 5080, Godot 4.7.2, 1920x1080, `--fixed-fps 60`), hulls copied from `audit2\repo\godot` (the bench
  default). Each commit run twice, the second kept (RULEBOOK 12.5). Before = main b7cacdc4; after = ad7daade (game files as
  5244d3ec). No placeholder hull on any run.

## What was wrong (from the before numbers and the materials)

- Glasswrights: every A4 hull carries the glTF emissive strength 4.0. On most hulls the emissive map is windows and
  engines (about 1 percent of texels over 0.2); on the Glasswright hulls it is the "stored light" over 21 to 32 percent of
  the hull, so the hull glows at 1.2 to 2.4 in linear light, above the glow threshold (0.8): a white hull with a halo. The
  baked finish adds to it (metal about .37, roughness about .30 in the ORM map; bakemat4.py asks .55 and .10).
- Dark hulls: Sunward black iron, Hullbreaker rust and Eclipse violet-black sit at 63 to 118. The old fix (hull_fix in
  fx/faction_looks.json) used Godot's material rim, which Godot multiplies by the albedo
  (scene_forward_clustered.glsl: `diffuse_light *= albedo`), so on a near-black hull it adds almost nothing.
- Hegemony: pale grey at 192 to 211, above the band.

## What changed

1. `look.gd` READ: per faction numbers laid on the hull material in LOOK.hull (lift in linear light, rim, emission scale,
   metal scale, specular). They replace hull_fix for the six factions (hull_fix stays as the fallback). Damaged and dying
   hulls keep them (fx_hull.gd `_exterior` copies albedo, rim, metallic, specular and emission energy; checked headless).
   Final: Sunward lift 1.45; Hegemony 0.4; Hullbreakers 1.25; Chorus 1.9 (about its old 1.35 sRGB lift); Glasswrights
   lift 0.4, glow 0.15 of its baked strength, metal 0.4, specular 0.3; Eclipse lift 2.2, metal 0.7. The dark factions sit
   near the band's low end and the pale ones below its top, so each keeps its value and colour.
   Ryan's ruling (Nov 12, R227), on phone_world_1.jpg: "slightly darker for eclipse, maybe somewhere in the middle? tone it
   slightly down for hullbreakers, again somewhere in the middle-ish?" So Eclipse 4.5 to 3.2 (before: about 1.6 to 1.9 in
   linear light, hull_fix 1.3 sRGB) and Hullbreakers 1.5 to 1.25 (before: 1.0). Picked from the measured slopes (each ship's
   lit side at lift 4.5 and 9 for Eclipse, 1.5 and 3 for Hullbreakers, rim tip 20; calibration 2 and the after run):
   estimated Eclipse 105 to 121 on the darkest sky and 111 to 144 on the storm (the Tomb-ark D9 the lowest, about 105,
   level with Sunward's 105) and Hullbreakers 114 to 144 on both; the worst outline on the darkest sky about 0.82. Eclipse
   3.0 would put D9 at about 103, inside the band by less than the estimate's error, so 3.2 is the darkest middle value I
   trust to stay in. Job E (below) measures it, with Eclipse 3.0 and 3.5 and Hullbreakers 1.2 and 1.3 beside it as
   fallbacks. Measured (job E, e6bfef6c, `data/rows_after_r227.json`): Eclipse 108 to 122 on the darkest sky (D9 the
   lowest, 107.7) and 113 to 146 on the storm; Hullbreakers 115 to 145 on all three skies; worst outline on the darkest
   sky 0.80 (D22). Both in band, so 3.2 and 1.25 stay. The bracket (`data/rows_r227_bracket.json`, darkest sky): Eclipse
   3.0 106 to 121 and 3.5 109 to 125; Hullbreakers 1.2 113 to 143 and 1.3 116 to 146. The other four factions measured
   the same as the ad7daade run (lit side identical, to 0.1).
   Ryan's second look (Nov 12 11:40 CST, R227): "i'd go a bit darker for eclipse but hullbreakers are good." Job F
   (below): Eclipse 2.2 is the darkest lift that keeps every Eclipse ship at 100 or more lit on the darkest sky, so the
   final Eclipse lift is 2.2; Hullbreakers stay 1.25.
2. The rim light (`look_rim.gd`, made by LOOK.apply beside the key light): a back light from the camera's own line of sight
   beyond the ships, tipped up 20 degrees, specular strong (light_specular 8) and diffuse weak (energy 0.35). Only the far
   outline of a hull faces it and the camera at once, at a grazing angle, so the hull gets a bright edge. It follows the
   camera every frame. It lights only render layer 16, which only hull surfaces join (material meta `look_hull`, or a damage
   material made from one): rocks, planet, board and craft keep their light. No shadows, no new shader.
3. KEY_ENERGY (2.0) and the glow threshold (0.8) are unchanged: both move every accepted look at once, and the Glasswright
   halo was the hull's own glow, not the threshold.

## Calibration (two cheap probe runs before the final)

- Calibration 1 (`data/rows_calibration1.json`, 8 variants): a back light from behind and above mirrored on every flat deck
  (Glasswright Ark lit 241 with a halo of 78; Eclipse cruiser 202). Moved to the line of sight.
- Calibration 2 (`data/rows_calibration2.json`, 8 variants): lift scale 0.7, 1, 1.4, 2; rim tip 20, 30, 45 degrees;
  specular 4 and 16. Tip 20 kept every outline at 0.93 or more on the darkest sky while the Ark (185) and the Eclipse fans
  stayed in band; 30 and 45 lit flat faces again. The first lifts put the dark factions mid-band: rust read pink and
  Eclipse lavender in the preview, so the final lifts are lower (step 1 above).

## Per faction (lit side min to max; full per ship table: docs/shots/look_bench/readability/table.md)

After = Eclipse 2.2 and Hullbreakers 1.25: the darkest and storm columns from job F (ad627af7, the e220 setting,
`data/rows_after_r227_e220.json`); the brightest sky (frontier) was not run in job F, so its column is job E (e6bfef6c),
where Eclipse is still 3.2 (frontier read the same as the darkest sky within 0.1 in every run). The earlier after runs
are in `data/rows_after_ad7daade.json` (4.5 and 1.5) and `data/rows_after_r227.json` (3.2 and 1.25).

| Faction | Darkest sky before / after | Brightest before / after | Storm before / after | Edge darkest, worst ship, before / after |
|---|---|---|---|---|
| Hegemony Navy | 192-211 / 156-180 | 192-211 / 156-180 | 192-211 / 156-180 | 0.95 / 0.91 |
| Sunward Crusade | 82-118 / 105-156 | 81-118 / 105-157 | 82-119 / 105-156 | 0.70 / 0.86 |
| Ashfall Hullbreakers | 89-115 / 115-145 | 89-115 / 115-144 | 90-115 / 115-145 | 0.79 / 0.88 |
| Chorus | 128-155 / 134-157 | 128-155 / 134-157 | 128-155 / 133-157 | 0.96 / 0.96 |
| Glasswrights | 206-216 / 160-180 | 206-216 / 160-181 | 204-216 / 159-177 | 1.00 / 1.00 |
| Eclipse | 63-74 / 101-112 | 63-74 / 108-122 (at 3.2) | 70-119 / 101-143 | 0.55 / 0.70 |

Craft and objects (not held to the band): the three craft are drawn by render/squadron_craft.gd in battle (not through
LOOK.hull, so neither change reaches them); the bench draws them with Hegemony numbers, so on the sheet the spore reads
darker (104 to 80). The station is drawn by the board (assets/ships/a4_props.gd), not LOOK.hull, in battle.

## Moments check (no effect or shield changed by accident)

The look bench moments part (61 rows, three cameras, 2,388 cells), main against the branch, each the second run.
- The bench's own compare: 1,850 of 2,388 cells over the 2.0 tolerance, as expected: nearly every cell has a hull in it.
  Sheets on the PC: `opus362\sheets_moments_before_2_vs_moments_after_2\` (Board: open the shield and deaths overviews).
- `pc/moments_diff.py` separates hull from everything else: the hull mask is what differs in each strip's first cell (taken
  before every effect starts), grown 3 pixels; then the difference outside it. Noise floor (main run 1 against run 2):
  0.00 on every cell. After: mean off-hull difference 0.03 (weapon on hull) to 0.69 (capital death beats); 50 of 2,388
  cells over 2.0 off the hull (`data/moments_diff_after_summary.txt`).
- The 50, looked at one by one (`moments_worst_off_hull.jpg`): capital death beats (13.9 at most): the Hegemony
  super-dreadnought's halves drift out of their first-cell place and are the new grey, hull not effect. Torpedo, lance,
  battery and doom hits on a Hegemony shield (4.0 at most): the shield and the hit are drawn the same; the soft glow
  around the bubble is a little dimmer because the hull under the bubble is darker (glow sums everything bright behind it).
  Macro on the Tomb-ark at camera 60 and 26: the Tomb-ark fills the frame, so there is almost no off-hull area.
- Seen on the overviews: fire, smoke, flashes, shells, beams, shield bubbles and shield breaks unchanged; hulls under them
  greyer (Hegemony) or lighter (Eclipse). The Eclipse burn-out hulk still goes dark, from a lighter start.

## Scene gate (R116: 12.5 ms; godot/bench/scene_gate.tscn, modes base and res_2160, 3 sessions, two launches each)

| | GPU ms at 4K (median of 6) | Frame ms at 1080p (median of 6) |
|---|---|---|
| Before (b7cacdc4) | 5.44 | 4.67 |
| After (ad7daade) | 5.45 | 4.50 |

Late shaders after warm-up: 0 in every session. Data: `data/gate/`.

## Checks run

- Headless in the sandbox (Godot 4.7.2 Linux): death_plane_check, fx_smoke, late_shader_check, smoke_lifetime_check,
  playtest_batch1_check, playtest_batch3_check, damage_surface_check, authored_interiors_check, destruction_staging_check,
  kill_slowmo_check, wing_cancel_test, movement_flight_check, nose_first_check, squadron_check, death_leap_check,
  flash_area_check: all PASS (death_leap_check needs `--import` first, as on GitHub). A headless script proved: the rim light
  is made once and reused, hull surfaces join layer 16 and a plain mesh does not, a damage material made from a hull
  material keeps the layer and the capped emission.
- No data.js, battle.js or core.js change: no oracle copies or tables to refresh.

## Self-check (R129)

- Callers: LOOK.apply in battle.gd, look_bench.gd, scene_gate (through battle.gd), fx gallery and three fx probes, a4_shots:
  all get the rim light (opt out: `{"rim": false}`). LOOK.hull in ship_view.gd and the gallery. scenes/battle/lineup.gd
  builds its own lights: its ships get the READ numbers, no rim light.
- Saves: none. Twins: the browser game has no look parity. UI: 2D panels untouched (the rim light lights 3D hulls only).
- GitHub: the standing checks and Godot checks run on the push (PR 580).

## Unsure, and for the Board

1. Faction colour: Eclipse read dark violet-grey rather than violet-black at 4.5, and the Hullbreaker rust lighter (warmer
   pink in places) at 1.5. Ryan ruled on Nov 12 (R227): Hullbreakers 1.25, Eclipse first 3.2, then darker: 2.2 (step 1
   and job F).
2. The rim light at close range: on the Tomb-ark at camera 60 it draws a thin white line along the inner ring ridge. Ryan
   zooms in for effects; worth his look.
3. hull_fix in fx/faction_looks.json is now only the fallback for a faction READ does not name. godot/fx/ was out of my
   scope; folding the two into one place is a small follow-up.
4. Craft (squadron_craft.gd) and the board's station and hulks (a4_props.gd) do not go through LOOK.hull, so they get
   neither change.
5. Window and trim light sizes for a 70 pixel ship stay with the ship recipe (issue 363's line), as the issue says.
6. A playbook line is owed by the Board if this becomes standing practice: "every ship change is judged on the readability
   probe's band first" (docs/playbooks/ships.md or effects.md; outside my Deliver to line).

## Job E (R227 lifts): what the Board queues and what comes back

- Queue: copy `contrib/opus/reviews/readability_362/pc/job_e.bat` from origin/opus/issue-362 into
  `%USERPROFILE%\Downloads\voidsworn_test\opus362\` and put a queue file `q_opus362_e.bat` in the PC queue that runs
  `call "%USERPROFILE%\Downloads\voidsworn_test\opus362\job_e.bat"`. run362.bat there is unchanged; its probe step fetches
  the branch and copies variants_e.json by itself. One GPU job: the probe twice (three skies), then one bracket run (two
  skies, two variants). Writes only under opus362\, deletes nothing.
- Done when status.txt has "job e done". Stage back three zips from `opus362\zips\`: probe_e_2.zip, probe_ealt_1.zip and
  probe_before_2.zip (the newest of each name; zip362 adds a number if the name exists).
- Then in the sandbox (the worker, from contrib/opus/reviews/readability_362, each zip unpacked into its own new folder):
  `python3 -I measure.py E2 --out data/rows_after_r227.json`, `python3 -I measure.py EALT --out data/rows_r227_bracket.json`,
  `python3 -I measure.py BEFORE2 --out /tmp/rows_before_check.json` (must match data/rows_before_main_b7cacdc4.json), then
  `python3 -I sheets.py --before BEFORE2 --after E2 --rows-before data/rows_before_main_b7cacdc4.json --rows-after
  data/rows_after_r227.json --out docs/shots/look_bench/readability/`: the new phone_world_1.jpg (and _2 to _5, the fleet
  sheets and table.md), before (main) against after at camera 170. The per faction table above gets its after column from
  the new rows, all six factions. If Eclipse or Hullbreakers fall out of the band, the bracket rows give the darkest value
  that stays in.

## Job F (Ryan, Nov 12 11:40 CST: Eclipse a bit darker; Hullbreakers stay 1.25)

Ryan, on the job E sheets: "the pictures are super pixelated, it's honestly hard to tell. i'd go a bit darker for eclipse
but hullbreakers are good." What moves what he sees: the lit side (brightest quarter) on Eclipse is held up mostly by the
rim light, so it barely moves with lift (D9 on the darkest sky: 106.4 at 3.0, 107.7 at 3.2, 109.4 at 3.5); the hull's
middle tone moves more (D9 median 60.0, 61.8, 63.6; main 41.6). Job F measures how far lift alone goes and whether the
Eclipse material rim (READ rim, 0.4) moves the look. The rim light itself (RIM) is shared by every faction, so it is not a
per faction knob and is not tried here.

- `pc/variants_f.json`: Eclipse only. e320 (now), e260, e220, e180, e220_rim27 (lift 2.2, material rim 0.27).
- `pc/readability_probe.gd`: new options `--cam` (camera distance), `--cell` (crop size, 1 to 1) and `--factions`; the
  defaults are the old behaviour. `pc/run362.bat`: passes `%PX%` (more probe options) to the probe, empty by default.
- `pc/job_f.bat`: (1) the camera 170 band on the darkest sky and the storm for the five settings, once; (2) the Eclipse
  ships at camera 60 (the bench's middle camera: real game pixels when zoomed in, never scaled), darkest sky, 1440x840
  crops, main twice (keep the second) and the branch with the five settings once. It copies the branch's run362.bat beside
  the old one as run362f.bat (a new file) for step 2.
- Queue: copy `pc/job_f.bat` from origin/opus/issue-362 into `%USERPROFILE%\Downloads\voidsworn_test\opus362\` and put
  `q_opus362_f.bat` in the PC queue with `call "%USERPROFILE%\Downloads\voidsworn_test\opus362\job_f.bat"`. Done when
  status.txt has "job f done"; stage back probe_f_1.zip, probe_f60before_2.zip and probe_f60_1.zip.
- Done here: `measure.py probe_f_1 --out data/rows_f.json`; `eclipse_cam60.py` makes Ryan's one picture
  (docs/shots/look_bench/readability/eclipse_camera60_r227.jpg: main, 3.2, 2.2, 1.8 side by side, camera 60, windows cut at
  1 to 1, camera 170 numbers under each code); `close_sheet.py` makes one page per ship with every setting if the Board
  wants the full set (not committed). The camera 170 sheets and table.md were remade from the e220 setting relabelled as
  the branch (`data/rows_after_r227_e220.json`; files point into probe_f_1/e220).

Result (darkest sky, camera 170; lit side min to max over the four Eclipse ships, worst edge):

| Eclipse setting | Darkest sky | Storm | Edge (darkest) | D9 middle tone |
|---|---|---|---|---|
| main (before) | 63 to 74 | 70 to 119 | 0.55 | 41.6 |
| lift 3.2 (job E) | 108 to 122 | 113 to 146 | 0.80 | 61.8 |
| lift 2.6 | 104 to 116 | 106 to 144 | 0.74 | 57.4 |
| **lift 2.2 (the pick)** | **101 to 112** | **101 to 143** | **0.70** | **54.0** |
| lift 1.8 | 96 to 107 (D22 96, D9 98: out) | 96 to 142 | 0.65 | 50.5 |
| lift 2.2, material rim 0.27 | 101 to 112 | 101 to 143 | 0.67 | 53.7 |

- The pick: 2.2, the darkest lift with every Eclipse ship at 100 or more on the darkest sky (D9 101.0, D22 101.1) and the
  edge at 0.70 (rule: 0.60). The margin is thin but measured, not estimated; the e320 setting re-measured within 0.1 of
  job E, and no other faction moved by more than 0.6 between runs.
- Which knob moves what Ryan sees: lift. From 3.2 to 2.2 the hull's middle tone drops about 8 levels on every Eclipse ship
  (D9 61.8 to 54.0, D22 58.2 to 50.5; main 41.6 and 38.6), which is the darkening Ryan asked for. The material rim does
  nothing visible: 0.4 to 0.27 moves the lit side by 0.2 at most and the middle tone by 0.3. The lit side is held up by
  the rim light, so it is what stops lift going lower; the rim light is shared by every faction, so taking Eclipse further
  down would need a per faction rim light amount (a code change, not proposed here).
- Storm edge 0.34 for the Eclipse frigate is the storm cloud behind its cell (the same 0.35 at 3.2); the edge rule is the
  darkest sky.

## PC

Folder `Downloads\voidsworn_test\opus362` (sparse clone, the hull copies, runs, zips). Queue files used:
q_opus362_a, _z1, _z2, _c2, _b, _c, _d; then _e for job E (R227 lifts) and _f for job F. Nothing deleted.
