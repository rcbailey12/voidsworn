# Effects stress pack (issue 232, Nov 8 2026)

Settles the Effects stack items left by the Nov 6 FX audit settlement (R121 to R125): the E6/E24 worst-case salvo flash
test, the E12/E13 damage caps, the E31 weapon timing sheet, the pale square effect sprite from the #220 screenshot
verdict, and the review riders E17/NB5, E18/BD8 and E33/CM8. The #232 run used the real battle scene on the RTX 5080.
Raw logs and every still are in `Downloads\voidsworn_test\work217\issue-232-deepseek\20261108_160459\out\shots\`.

## What changed in the branch

- `godot/fx/fx_weapons.gd` (`_weapon_shader`): the pale square fix. A second UV crop (`vec2(0.36, 0.48)`) was applied on
  top of `atlas_rect`, so every weapon flash and muzzle vent sampled only the gas CORE and drew as a flat translucent
  quad. The crop is gone; the quad is grown by 1.45 so the gas keeps the on-screen size the F3 pixel floor was tuned for.
- `godot/fx/fx_ship.gd` (`damage_caps`, `_place_mark`, `_dmg_request`): a `fx.cap_k` stress multiplier (default 1.0) and
  the E12 caps re-based on the measured 4x step.
- `godot/fx/fx.gd`: `cap_k` (the stress multiplier) and `timing` (the E31 pins; defaults are the shipped values).
- `godot/fx/fx_weapons.gd` (`_shot`, `_shield_impact`): the E31 pins read from `fx.timing`, so a sheet can run one
  alternate without editing constants.
- `godot/bench/scene_gate.gd`: `--flash` (the WCAG luminance run), `--capk` and a `caps` mode (the damage stress),
  and `cap_k`/`damage_counts` in every row.
- `godot/fx/test/fx_range_probe.gd`: `PROBE_TIMING` sets the E31 alternate.
- `godot/world/world_living.gd`, `godot/world/world_sky.gd`, `godot/world/world.gd`, `godot/world/world_shots.gd`:
  `VS_NEB_W` (the E17/NB5 faction tint weight), `VS_STAR_FLOOR` (the E18/BD8 star occlusion floor) and `--fac` (a warm
  faction sky for the rider sheets). All defaults are the shipped values.
- No rules, save fields or UI values changed.

## Reproducing the stills

The fresh checkout had no `godot/gen/` (the hull build is gitignored), so every ship drew as a placeholder block. The
run copied the built hulls from `Downloads\voidsworn_test\build\godot\gen` into `godot/gen/` (untracked, the same way
the #220 job did) and imported once. The screenshots below therefore show the real hulls.

```
godot --headless --path godot --import
godot --path godot --rendering-method forward_plus --windowed --resolution 1920x1080 \
  res://bench/scene_gate.tscn -- --out OUT --still
godot --path godot --rendering-method forward_plus --windowed --resolution 1920x1080 \
  res://bench/scene_gate.tscn -- --out OUT --flash --frames 240
godot --path godot --rendering-method forward_plus --windowed --resolution 1920x1080 \
  res://bench/scene_gate.tscn -- --out OUT --modes caps --sessions 2 --warmup 60 --frames 240 --capk 4
```

## 1. Worst-case salvo flash test (E6, E24): PASS

`scene_gate.gd --flash` builds the real 20-ship storm battle, sets a third of the ships to stage 3/4 and burning (E24),
fires the A5 worst-case mix in three waves inside one WCAG second (every faction's weapon look, heavy gauss, a heavy
torpedo volley, a flak screen), then kills three squadrons and one capital (DS9). Every frame is rendered on the fixed
effect clock, captured, and reduced to a relative-luminance mean and the brightest 1/6-screen block. The counter is WCAG
2.3.1: a pair of opposing relative-luminance changes of 0.10 or more, the darker of the pair below 0.80, merged inside
0.33 s, at most 3 in any rolling second.

| Reading | Result | Cap | |
|---|---:|---:|---|
| WCAG flashes from the screen luminance, brightest 1/6 block | 0 | 3 | pass |
| WCAG flashes from the screen luminance, full-frame mean | 0 | 3 | pass |
| Largest single-frame luminance change (mean or block) | 0.033 | 0.10 | pass, 3x margin |
| Counted effect flashes (the fx budget itself) in any rolling second | 3 | 3 | pass, at the cap |
| Refused effect flashes over the 4 s run | 1 | | the budget did its job |
| Continuous emitters in frame at the end (E24) | 11 fire, 17 smoke, 1 vent, 177 particles | | stage 3/4 ships |

`flash/flash_luma.csv` is the per-frame log (240 rows: time, mean, brightest block, counted and refused effect flashes).
`flash/flash.json` has the verdict and the DS9/HD12 reads.

- **DS9 (capital secondaries), judged from the same log:** the capital death starts at t=5.858 s. Counted flashes after
  it: 5.991, 6.159, 6.419, 7.151, 7.552. The first is the death core; the two at +0.301 s and +0.561 s are the two
  staged secondaries (the secondaries fire 0.08 s after cuts 1 and 2, and the cuts are spaced by the death timeline). No
  per-piece cook-off loop follows; the later two are the wreck's staged cut flashes. The capital therefore does not
  push the flash budget past 3 in any second. No regime change is needed for DS9.
- **HD12 (floating combat text), judged from the same run:** the real HUD labels are in `riders/hd12_float_text.png`
  (`-12 shield`, `-9 hull`, `Critical` over the Pyre-Barge). `make_float` uses `hud.s(16)`, so the Godot size at the
  1080p design height is 16 px semibold; the JS reference is 19 px bold. The port is 3 px (16 percent) smaller. This is
  a typography call for Ryan, not a bug fixed here; the rider records both sizes and the capture.

A screenshot of the run at the death frame is `flash/flash_060_salvo.jpg`.

## 2. Damage stress at raised caps (E12, E13)

`scene_gate.gd --modes caps --capk K` puts every ship at stage 3/4 with a full load of marks and burning, then measures
the real gate scene (1080p, MSAA 4x, 2 sessions, 240 measured frames). K multiplies the old EVE-derived caps. The runs
were taken with the old caps; the new caps are the 4x row.

| Caps | Frame median | Frame p99 | GPU median | GPU p99 | Board emitters at the end | |
|---|---:|---:|---:|---:|---|---|
| 1x (old shipped) | 9.30 / 10.09 ms | 13.60 / 14.04 ms | 2.12 / 2.09 ms | 2.70 / 2.81 ms | 29 fire, 46 smoke, 3 vent, 474 particles | pass |
| 2x | 9.01 / 10.25 ms | 12.11 / 14.57 ms | 2.21 / 2.20 ms | 2.76 / 2.71 ms | 46 fire, 60 smoke, 9 vent, 704 particles | pass |
| 4x | 8.52 / 10.81 ms | 11.40 / 14.20 ms | 2.22 / 2.07 ms | 2.73 / 2.72 ms | 60 fire, 60 smoke, 9 vent, 816 particles | pass |

Gate R116: frame median at 1080p 12.5 ms; every row is under it. The frame p99 never exceeds 14.57 ms (under 16.7 ms).
GPU is unchanged at about 2.1 to 2.2 ms (1080p), so the damage adds no measurable GPU cost.

**The caps, set from the numbers:** the 4x step is the measured-safe ceiling and is now the shipped E12 caps in
`fx_ship.damage_caps` (weight 1: 4 fire, 8 smoke; weight 2: 8, 12; weight 3 and 4: 12, 16). The live count stops rising
after 2x because a ship has only three sections and the current builder emits at most one fire and one smoke per section;
the 4x cap is headroom, not a new art pass. The old caps were the EVE-derived table in the audit and are now retired.
The stress also scaled the E11 mark caps (12 per ship, 4 per section) through the same `cap_k`; the E11 values are kept
as shipped because E11 is its own audit item, so the 4x row is conservative for the emitter caps.
Full rows: `caps/caps_1x.json`, `caps_2x.json`, `caps_4x.json`.

## 3. Weapon timing sheet (E31)

The pins are the shipped values: `fx.timing` = ripple 0.08 s, shell speed 160 u/s, lance 0.7 s, charge 0.25 s, shield
ripple 0.6 s. `fx_range_probe.gd` fires one frigate volley per family at a frigate five hexes away, from the battle
camera and from the camera at its 900-unit limit, and writes a four-column sheet (before firing, in flight, the hit,
0.45 s after). The alternate is `PROBE_TIMING="ripple=0.12,shell_speed=120,lance=1.0,charge=0.35,shield=0.9"`.

| Family | Pin impacts (s) | Alternate impacts (s) | What the sheet shows |
|---|---|---|---|
| macro battery | 0.709, 0.785, 0.894, 0.975 | 0.879, 0.993, 1.152, 1.274 | 80 ms gun ripple at the pin; 120 ms at the alternate |
| lance | 0.280 | 0.380 | 0.25 s charge and 0.7 s lance at the pin; longer at the alternate |
| torpedo | 2.045 | 2.045 | the heavy warhead keeps its flight (speed pin does not apply to the torpedo body) |

Sheets: `weapon_timing/*.jpg` (pins) and `weapon_timing/alternate/*.jpg`. Both passes logged `FLASH_MAX 1`, so a single
family does not spend the flash budget. This is the one-sheet round for Ryan's pick; no timing value was changed. The
target frigate is a fallback block in the deathless and chorus sheets because the built `gen` on the PC has no
`D9_23`/`C13s_23` scene; the shot, trace and burst still read and the timing numbers are unaffected.

## 4. The pale square effect sprite

The square was a weapon muzzle `vent` (the grey secondary puff), not a death effect, so it showed in every run that
fired a volley near the camera. `_weapon_shader` cropped the atlas a second time after `atlas_rect`, sampling only the
centre of the baked gas. The centre is a near-constant plateau, so the quad drew as a flat pale square. The fix removes
the extra crop (the `atlas_rect` already frames the gas) and scales the quad by 1.45 so the gas keeps the size the pixel
floor was tuned for.

Before and after, same fixed effect clock, step 300:
`pale_square/pale_square_before_after.png` (crop) and the full frames in the out folder (`still_before_gen` and
`still_after`). The square is gone and the puff reads as a soft gas cloud; the rest of the frame is unchanged.

## 5. Riders for the same review round

- **E17 with NB5 (faction tint cap):** `riders/e17_nb5_weights.jpg`, the warm Corsair sky on the storm map at weights
  0.10, 0.25 (shipped) and 0.45. The violet family holds at all three; 0.45 pushes a little more warm shift without the
  mauve/brown failure. Pick for Ryan: keep 0.25 or move to 0.45. Env: `VS_NEB_W`.
- **E18 with BD8 (star occlusion):** `riders/e18_bd8_star_floor.jpg`, the same sky with the star floor at 0.05, 0.15
  (shipped) and 0.35. The change is subtle at this framing (the gas covers little sky); the sheet and the env hook
  (`VS_STAR_FLOOR`) let the review round pick a floor against the 30/60/10-15 percent targets.
- **E33 with CM8 (hitstop, shake and death slow):** `riders/e33_cm8.md`. A values sheet, not a capture: hitstop and
  slow motion are temporal and cannot be judged from stills; the three candidate sets are tabled with the source lines
  for the review round's short recording.
- **HD12** is in the flash section and `riders/hd12_float_text.png`.

## Five checks the reviewer asks for

1. **Callers:** `damage_caps()` had one caller (`_refresh_damage_emitters`, updated to pass `fx.cap_k`); `MARK_CAP` and
   `SEC_MARK_CAP` are read only in `fx_ship._place_mark` and `_dmg_request` (both updated). `fx.timing` is read only in
   `fx_weapons._shot` and `_shield_impact`, with the shipped defaults. `faction_end_weight` and `star_floor` are new and
   set at their two material sites. No other callers exist (`grep` over the repo).
2. **Saves:** no player profile or run save field changed. `save_fuzz` (300 seeded rounds plus garbage and round-trip)
   passes in the standing checks.
3. **Twins:** the changes are visual only (fx and world shaders), with no rules twin in `core.js` or
   `campaign_meta.js`. `parity.bat nopause` still prints `PASS: the Godot port matches the game's rules exactly` and
   `PASS: the Godot campaign matches the game on all 30 seeded runs`.
4. **UI:** the HUD reads no new value; the only UI-adjacent item is HD12, which is a measurement of the existing
   `make_float` size (16 px), not a changed value. No campaign map, intel or panel reads the caps or timing.
5. **CI:** no new test file was added. The new checks are Godot bench probes (run by hand, output in this folder), not
   Node tests, so nothing needs adding to `contrib/opus/tools/run_all_checks.js`. GitHub runs the standing checks
   (`run_all_checks.js`: all PASS) plus the no-em-dash and Godot rules-parity workflows on the PR.

## Skipped or not finished, and why

- **E33/CM8 has no capture.** Hitstop and death slow motion are time-based; a still cannot show them. The values sheet
  and the source lines are ready for the one recording Ryan's review round needs. The shipped CM8 depth (0.08) and death
  slow (0.48 s at 0.35 speed) are much heavier than the E33 ranges, so the review should include a third candidate at
  0.35 s and 0.6 speed.
- **E18's star floor is subtle in this framing.** A closer nebula-body crop would read better; the sheet and env hook are
  in place.
- **The 4K GPU row for the caps stress was not re-run.** GPU at 1080p is 2.1 to 2.2 ms and the change adds no GPU work;
  the R116 4K GPU reading from #207/#220 (5.45 ms) still stands.
- **The gen hull for D20_23 (and C13s_23 in the world shots) is not in the built asset folder**; those two ships log a
  missing-texture error and fall back in the frames. It does not affect the effects, but a re-run with a complete
  `godot/gen` will remove the warning.
