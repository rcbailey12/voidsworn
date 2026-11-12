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
- Shields: invisible at rest, a faint edge glow on zoom, hover or a recent hit, a downed side reads as a dark gap, and they
  keep faction colours (R163; Oct 24).
- Directions already researched for the next options sheets (contrib/muse/design/look_references_2026_11/synthesis.md):
  shields Rim and Gap, Face Flash, Veil Then Local; trails Ribbons and Bloom, Flare and Dash, Gothic Weight; sky Regional
  Colour Calmed, True Dark One Band, Planet Limb.

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

## 4. The checks that prove it

- The bench strip at camera 170 shows the effect, with its measured size and time beside the table's row. The row is a
  starting point (R187): a difference judged better by eye in a moving fight is reported, not failed.
- The flash counter (godot/fx/fx.gd) accepts it without softening it; if it refuses, say so with the numbers.
- godot/fx/test/check_destruction.bat and the stray puff guard pass: every spawned picture is recorded and sits on the hull
  (death_spawn_check.gd, PR 404).
- Frame time on the bench is reported against the baseline. Costs are reported; a regression is the Board's call.
- The standing checks pass, and any new script under godot/**/test/ has its line in godot/tools/ci/godot_checks.txt.
- The reduce-flashing variant keeps the same sizes with the softer rise and fall the table gives per row.

## 5. Traps

- Judging at the close camera. The game is played at camera 170; an effect that is lovely at camera 26 and a smudge at 170
  has failed. Camera 170 rows go first on every sheet.
- Pale blobs. Before route B, a torpedo hit was a large cream cloud with no fire in it (the "today" column of the routes
  sheet). Fire must be visible through the gas at camera 170.
- Deaths are faint in every route (run 3 of issue 353): the route is not the cure. Deaths need their three beats, issue 366.
- Effects that float: the death vent sat 6.7 units off the hull until PR 404 rooted it with the hull ray. Anything that
  spawns near a ship uses the ray or a hard point.
- One GPU job at a time on the PC, and the queue is single file: a long bake holds every later job.
- Editor .import files beside baked pictures are churn: commit them only when the game needs them to load.

## 6. Worked example

- Death puffs on the plating, issue 354, PR 404: a check that fails on main first, the repair, the before and after strip at
  cameras 170 and 26.
- Explosion routes, issues 353 and 419: two bake routes on one sheet, Ryan's pick of route B with the hot core.

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
beats. 5. Shield options sheet from Muse's three directions, Ryan's pick, then issues 371 and 372. 6. Trails, beams and
flares: options sheet, pick, issue 367. 7. Issue 362: every faction readable at the played camera.

## 9. Seat

Codex bakes, benches and builds effects from a row. DeepSeek does code-only parts (services, checks, tables). Muse researches
and checks from outside. The Board makes the options sheets, looks at every strip and brings Ryan one image.
