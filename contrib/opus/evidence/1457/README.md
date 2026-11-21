# Issue 1457: player path route, cloud evidence

Cloud runs, Godot 4.7.2 headless with `--fixed-fps 30`, a fresh profile per seed, on branch opus/issue-1457.
Headless runs skip the clean-build and window checks, so the PC run on a clean export is still the acceptance proof.

| Seed | Route | Result |
| --- | --- | --- |
| 31 | Hullbreakers, planned stops 0-0, 1-0, 2-0, no drift | Battles 1 to 3 won (3, 3 and 2 rounds) |
| 10 | Navy, drifts once: planned 2-2 is now an event stop, takes 2-1 (Navy flagship battle) | Battles 1 to 3 won (11, 4 and 5 rounds) |
| 121 | Hullbreakers diagnostic, planned stops | Battles 1 and 2 won, Battle 3 lost in 9 rounds |

What was wrong:
- Seed 10: the planned third stop 2-2 is an event stop on today's map, not a battle. The recorder entered it, answered
  the event, then looked for 2-2 again from 2-2 and stopped ("expected route 2-2 is missing"). Not a campaign bug: the
  map content for that seed changed.
- Seed 121: the recorder measured straight-line distance, so in Battle 3 (relay hold, `round` rows in the old run) the
  cruiser and destroyer shuffled behind rocks for 14 rounds. A dropped first-round move cost the cruiser another round.
  Both are fixed; the fleet now reaches and contests the relay, then loses the fight with the hulk-carrier and two
  raiders. That fight is the only battle the map offers at column 2 for this seed, so 121 stays a diagnostic. Whether
  that Battle 3 is harder than intended is a balance question for the Board.
- Title music: the playing title track kept its playback at quit (4 objects, 2 resources: title_war.ogg). quit_clean now
  calls Music.release(). A title-only verbose run in the cloud shows no leak after the fix; music_check passes with a
  new release line.
- Faction crests: on a window too narrow for the faction tab crests (the cloud's 64 by 64 headless window), the crest
  TextureRect was built and never added, so 6 crests and their textures were still in use at exit. It is now freed.
  After both fixes a verbose seed 31 run exits with no leak lines (cloud_seed-31_verbose_after_crest_fix.txt).
