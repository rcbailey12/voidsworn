# Playbook: battle effects

Issue 405. Written by the Board (Fable 5.2), Nov 11 2026. Format: docs/playbooks/PROGRAM.md. Use this to make or change one
effect: a weapon hit, a shield response, a trail, a death.

## 1. Target

- Ryan, Nov 10, on the explosion routes sheet: "Far right in both for sure. We need to upgrade the effects a bit but it's the
  right approach." The far right column is **route B with flash plus hot core** (R170). Every explosion is built that way.
- Sizes and times come from Muse's staging table, contrib/muse/design/hit_staging_2026_11/synthesis.md, measured at 1080 at
  the battle camera: for example a torpedo on a hull flashes 140 px for 0.16 s (154 in the staging table; issue 461 built
  it at 140 so a lone torpedo stays under the flash counter's limit), a cruiser death flashes 302 px for 0.20 s. Each
  step up the ladder reads plainly bigger than the one below (the built steps, deaths_and_hits.md "The hits, upgraded":
  las 40, macro 56, lance 78, torpedo 140, a torpedo on a shield's ripple 156), so a bigger event always reads bigger.
- Flame cap: no flame or hot core lives longer than 0.70 s, and none stays at full heat longer than 0.25 s (owner ruling).
  Flash and snuff out, never rolling fire. Flame only (R193): sparks, debris, gas, dust and embers live longer, and scorch
  stays (deaths_and_hits.md, "The hits, upgraded").
- Numbers in this playbook and the staging table are starting points judged by eye in a moving fight, not gates (R187).
  Checks protect crashes, saves, comfort and frame rate.
- **The flash counter counts by area (R193 (1)):** at most three big flashes a second, "big" by the W3C guideline's combined
  area in a 10 degree window, from a stated screen (default 32 inch at 24 inches); godot/fx/fx.gd, issue 504. Work inside it:
  it is a comfort rule for every player, not only under reduce flashing.
- **Hits must read at camera 170 (R208 (1)).** Ryan picked "Merge, then push harder" on the first hits build; subtle is a
  fail. Light on neighbouring hulls stays faint for now (R208 (3)).
- Shields (R246, Ryan, Nov 14): the resting look is Rim and Gap: a faint rim in the faction edge colour on live sides, a dark
  gap where a side is open, nothing else at rest; shields keep faction colours (R163), with Glacier pale blue only for screen
  readouts (R210). The rules are one pool per ship with per-side coverage and lossy routing (issue 371); the look is issue
  372. A shield hit makes no smoke, only an energy crackle (R271, issue 815). Settled: do not reopen the options sheet.
- Ryan, Nov 18 (issue 1045): the R303 fitted skin replaces the R297 egg default.
  The fitted skin offsets sampled hull surfaces at a uniform gap, preserving
  waists and ring openings. Select the egg with `VS_SHIELD_SHAPE=egg` or
  `rendering/effects/shield_shape="egg"`.
  Its hit collider uses that same mesh. Impact and collapse ripples use the shader's
  hits array, including the soft flash fallback; do not add a separate flat ring.
  Check C15s, H9 and E12 at cameras 170 and 60, plus the fitted skin from the side.
- Shield failure (R340, Ryan Nov 19 2026, issue 1078): every shielded ship fails with the clean collapse, on both shapes:
  one even flash, then one band closes from the far side into the breach in 1.225 s (R358, Ryan Nov 20 2026, issue 1239:
  75% slower than the first 0.7 s, picked on the pace sheet; `COLLAPSE_CLOSE` in fx_ship.gd, the shader's `brk_close`),
  a knot and a flat ring of sparks there, nothing left behind. The collapse closes where the breaking shot struck, and a
  ship killed by that volley keeps it to its end (issue 1239). Faction colour stays (R163); hits are unchanged. It lives only in the shared shield code
  (fx_ship.gd `_break_collapse`, the SHIELD shader), so Sunward, Hegemony, Ashfall and the Glasswrights all pick up any
  change to it; never add a per-ship failure. The old per-faction break (`today`) and the energy shear (`shear`) stay
  only for dev comparisons through `rendering/effects/shield_failure` (or `VS_SHIELD_FAILURE`); they are not game looks.
  The band is drawn by the shader, not a sprite flash, so the flash budget never sees it: under reduce flashing it is
  softer, and the probe's flash pass (`PROBE_FLASH=1`) counts screen flashes with several Glasswright ships, then several Hullbreaker ships, failing at once.
  Sheets, clips, cost and flash: `fx/test/shield_fail_probe.gd`, on the PC `tools/pc/jobs/shield_looks_1078.bat`. Pace and
  hand-off before and after sheets: `fx/test/shield_handoff_probe.gd` (dev pace setting `VS_SHIELD_CLOSE`).
- Issue 1211 (Board brief from the Nov 19 weapon effects audit): every effect shader and every mark on a hull carries
  `fog_disabled`, like the hulls (nebula_hulls.gd, R82), so a nebula never dulls a blast; pixel floors and caps are in
  1080-line pixels (px_world, or the raw size times VIEWPORT_SIZE.y / 1080), so a streak keeps its shape at 4K. A hit's
  sound, HP drop, number and shield break land on that hit's own shot arrival, on the effect clock (battle.gd _land_hit).
- Directions researched for the remaining options sheets (contrib/muse/design/look_references_2026_11/synthesis.md): sky
  Regional Colour Calmed, True Dark One Band, Planet Limb. Trails and beams are being built (issues 367, 800, 815).

## 2. Inputs

- The look bench (godot/bench/, tools/pc/jobs/look_bench.bat, baseline docs/shots/look_bench/). For a death or a deep wound:
  the hull's insides (R209), so a break shows decks and frames, never a hollow shell. Its moments are listed in
  godot/bench/look_moments.json; add a moment there when an effect has none.
- The picked route's bake scripts and pack step (tools/blender/vfx/ on branch opus/issue-353 until issue 419 lands them).
- For anything new in look (not a resize or retime): Ryan's pick from an options sheet. Options first, then build.

## 3. Steps

1. Find the row. Which line of the staging table is this event? If it has none, propose the row (size, time, flash step) in
   the job and get the Board's yes before building.
2. Bench main first: `look_bench.bat` for the moment at cameras 170, 60 and 26. Keep the strip. This is "before".
3. Build to the row: the flash reaches its size inside two frames, the body and aftermath follow the table, the hot core
   obeys the flame cap. An effect starts on the ship (a hard point or a surface hit), never on a guessed box point
   (issue 370).
4. Bench the change twice and keep the second run (the first run of a commit pays for shader warm-up).
5. Measure on the strip at camera 170: the flash's widest lit extent in pixels and how many frames it lasts. Put the
   numbers beside the table's in the report.
6. Make the before and after strip, camera 170 first. That strip is the one image for Ryan.
7. Write what changed into this playbook if it taught anything (a new trap, a new moment).

### Shared effect kind IDs

Pick kind IDs from the [registry in fx.gd](../../godot/fx/fx.gd) before adding an emitter or changing a shader branch
(issue 2176). SPRITE, STREAK, RING, RIBBON, DISTORT and BREACH each have their own number space. Reuse an existing name
only for the same effect. For a new effect, add a name and an unused number there first. Keep shipped IDs, legacy gaps
and reservations for other PRs intact. Use the named ID at new call sites, and keep the shader's vertex and fragment
tests in step with it. A reservation alone does not turn on an effect.

When adding a BREACH style, keep the matching `S_*` constant in `fx_breach.gd` in step too. The headless
`fx_kind_registry_check.gd` in `godot_checks.txt` rejects duplicate numbers within a family, unregistered shader
comparisons, and drift in those breach constants.

## 4. The checks that prove it

- The bench strip at camera 170 shows the effect, with its measured size and time beside the table's row. The row is a
  starting point (R187): a difference judged better by eye in a moving fight is reported, not failed.
- The flash counter (godot/fx/fx.gd) accepts it without softening it; if it refuses, say so with the numbers.
- godot/fx/test/check_destruction.bat and the stray puff guard pass: every spawned picture is recorded and sits on the hull
  (death_spawn_check.gd, PR 404).
- Frame time on the bench is reported against the baseline. Costs are reported; a regression is the Board's call.
- The standing checks pass, and any new script under godot/**/test/ has its line in godot/tools/ci/godot_checks.txt.
- The reduce-flashing variant keeps the same sizes with the softer rise and fall the table gives per row.
- An approved look is live only when the game plays it with no switch set and battle.gd calls it (Ryan, Nov 21 2026:
  "make sure all of the damage, death, hit effects, etc are being appropriately brought in and used").
  godot/fx/test/approved_effects_check.gd fails when an approved default is off, or when a rules event's fx call in
  godot/fx/API.md section 11 is not made by battle.gd. The job that lands an approved effect adds its row to
  godot/fx/test/approved_effects.json (a default to probe, or the API row it wires) in the same pull request; a call
  built but not yet wired sits in that file's "unwired" list with its job, and the check fails once it is wired until the
  row is deleted.

## 5. Traps

- Judging at the close camera. The game is played at camera 170; an effect that is lovely at camera 26 and a smudge at 170
  has failed. Camera 170 rows go first on every sheet.
- Pale blobs. Before route B, a torpedo hit was a large cream cloud with no fire in it (the "today" column of the routes
  sheet). Fire must be visible through the gas at camera 170.
- Deaths are faint in every route (run 3 of issue 353): the route is not the cure. Deaths need their three beats, issue 366.
- Effects that float: the death vent sat 6.7 units off the hull until PR 404 rooted it with the hull ray. Anything that
  spawns near a ship uses the ray or a hard point.
- Small death spin (issue 463): `s.xf()` already follows the spinning mesh. Applying the spin again moves the jet off
  its plating. Keep the hull's analysis pose from the kill frame and apply the spin once; record that frame with each
  trail sample. A one-frame wing spark starts on the next effects step so it cannot expire before its first draw.
- Up to two GPU jobs at once on the PC (R276). Use `tools/pc/tmo.bat <seconds> <exe> [args]` for GPU launches. It claims a
  shared slot for captures and Blender, solo for frame-time scripts, and releases on exit or timeout.
  A solo waiter blocks new GPU work until both shared slots finish; gpu_go.txt must still say `GPU cleared`.
  For a new timing script, set `PC_GPU_MODE=solo` before its tmo call. The watchdog also detects timing code in scripts and
  scenes automatically. Lane C is code only. Never use a GPU-idle timeout as permission to start a measurement.
- Editor .import files beside baked pictures are churn: commit them only when the game needs them to load.

## 6. Worked example

- Death puffs on the plating, issue 354, PR 404: a check that fails on main first, the repair, the before and after strip at
  cameras 170 and 26.
- Explosion routes, issues 353 and 419: two bake routes on one sheet, Ryan's pick of route B with the hot core.
- Small deaths, issue 463: `godot/bench/look_moments_deaths_small.json` captures the wing, frigate, destroyer and cruiser
  with normal and reduced flashes at all three cameras. `godot/bench/death_small_measure.gd` isolates the production
  pictures at 60 Hz for pixel and lifetime measurements.

## 7. Job template (one effect to its row)

```
Owner: codex (GPU bakes and bench runs) or opus/deepseek for code-only changes
Brief: docs/playbooks/effects.md; contrib/muse/design/hit_staging_2026_11/synthesis.md (the row: EVENT); FINDINGS R170
Deliver to: godot/fx/ (the effect), godot/bench/look_moments.json (if a moment is added), docs/shots/look_bench/EFFECT/ (before and after strips)
Branch: codex/issue-<number>
Effort (Codex): high
Done when: the before and after strip at cameras 170, 60 and 26 is committed; the report gives the measured flash size and life beside the table's row; check_destruction and the standing checks pass. What Ryan will see: one strip, before above after, at the battle camera.
```

One effect is one or two Codex runs (a rebake is the long step) plus one Ryan look when the look is new.

## 8. The order of the effects work (PROGRAM.md, track 1)

1. Issue 419: the up-to-date routes sheet, committed. 2. Issue 365: rebake every explosion by route B with the hot core, to
the table. 3. Issue 370: the attach point service (after the hard point contract, issue 363). 4. Issue 366: deaths in three
beats. 5. Shields: Ryan picked Rim and Gap (R246); issues 371 (rules) and 372 (look), smoke off shield hits in 815. 6. Trails,
beams and flares: issue 367, then rounds 2 and 3 (800, 815). 7. Issue 362: every faction readable at the played camera.

## 9. Seat

Codex bakes, benches and builds effects from a row. DeepSeek does code-only parts (services, checks, tables). Muse researches
and checks from outside. The Board makes the options sheets, looks at every strip and brings Ryan one image.
