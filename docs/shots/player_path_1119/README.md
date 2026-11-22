# Battles 1 to 3 as a new Sunward player sees them

Both routes start with an isolated fresh profile, Standard difficulty, Vex and the starter fleet. The game uses Key cut-ins, the
danger overlay, teaching cards, the full HUD and target card, the battle log and voice lines, and the usual mesh LOD.
The recordings use a 1920 by 1080 window. The 720p clips preserve the whole frame and carry a provenance strip below it.

| Route | Campaign seed | Battle 1 | Battle 2 | Battle 3 |
| --- | ---: | --- | --- | --- |
| Ashfall Hullbreakers | 31 | Navy, Rout | Hullbreakers, Hold | Hullbreakers, Rout |
| Hegemony Navy | 10 | Navy, Rout | Hullbreakers, Hold | Navy, Flagship |

Seed 31 plays its planned stops (0-0, 1-0, 2-0). Seed 10's planned third stop 2-2 is now an event, so the recorder logs one
route drift and takes 2-1, a Navy flagship battle (godot/main/player_path.gd). Seed 121 is a diagnostic only and is not
recorded here.

## Current recording (Nov 21)

Recorded on Ryan's PC on Nov 21 at 22:06 UTC, during the LOAD13 job for issue 1434. The Board relayed it as
`board/pc-out-1434m` (`fbd20ccd`). Both routes won all three battles.

- Commit `1a8c7b971622133ebd359b5cc5d44195c226f0e1`: main at `0c23901f` (Nov 21 16:18 UTC) plus PR 1445's loading changes.
  **This is not a main commit.** The clips show the game with that loading work in it and without later main merges, such
  as PR 1527 (ram, boarding and command effects). A change judged under RULEBOOK 12 still needs its own recording on a build
  that includes it.
- Build SHA-256 `44eb8c253ac97d94639772a57b4accf2ca6be118b08de5dc39c3b61cf679e173`
- Manifest SHA-256 `ba5a2e0a33127929a1d7ffa0242d5d78a21964b5cee295fcbdd314d700c553c8`

| Route and battle | Contact sheet | Clip parts (48 s each, last part shorter) | Battle length |
| --- | --- | --- | ---: |
| Hullbreakers 1 | [HULLBREAKERS-B1](hullbreakers-b1.jpg) | [1](hullbreakers-b1-p01.mp4) · [2](hullbreakers-b1-p02.mp4) · [3](hullbreakers-b1-p03.mp4) | 1:40 |
| Hullbreakers 2 | [HULLBREAKERS-B2](hullbreakers-b2.jpg) | [1](hullbreakers-b2-p01.mp4) · [2](hullbreakers-b2-p02.mp4) · [3](hullbreakers-b2-p03.mp4) | 1:40 |
| Hullbreakers 3 | [HULLBREAKERS-B3](hullbreakers-b3.jpg) | [1](hullbreakers-b3-p01.mp4) · [2](hullbreakers-b3-p02.mp4) · [3](hullbreakers-b3-p03.mp4) | 2:15 |
| Navy 1 | [NAVY-B1](navy-b1.jpg) | [1](navy-b1-p01.mp4) · [2](navy-b1-p02.mp4) · [3](navy-b1-p03.mp4) · [4](navy-b1-p04.mp4) | 3:02 |
| Navy 2 | [NAVY-B2](navy-b2.jpg) | [1](navy-b2-p01.mp4) · [2](navy-b2-p02.mp4) | 1:25 |
| Navy 3 | [NAVY-B3](navy-b3.jpg) | [1](navy-b3-p01.mp4) · [2](navy-b3-p02.mp4) | 1:24 |

Checks on these files: all 17 MP4 parts and six JPGs pass `tools/picture_provenance.py verify`. Every part decodes with no
errors at 1280 by 720 and 30 fps, carries audible AAC sound and is under 8 MB. The parts of each battle add up to the
battle's full length, start to end. The two traces, [seed-31.jsonl](seed-31.jsonl) and [seed-10.jsonl](seed-10.jsonl), show the
isolated profile, the player defaults and the three wins. The clips are battle only; the map, reward and naming screens
between battles are in the traces, not in the clips. The 1080p AVI masters were not relayed.

### What a new player sees

Times start at the beginning of each battle and match the contact sheets.

| Battle | Danger overlay | Teaching cards | First target card | First Key cut-in | Command and outcome |
| --- | --- | --- | --- | --- | --- |
| Hullbreakers 1 (Navy, Rout) | 00:07.7 | Moving and facing 00:08.2, Shields and hull 00:18.5, Firing 00:34.7, Threat map 00:42.4 | none | Lance 00:29.0, 10 total | Fire for effect 00:50.3; victory 01:36.6 in 3 rounds |
| Hullbreakers 2 (Hullbreakers, Hold) | 00:11.1 | Objectives 00:11.7, More ships are coming 00:36.2, Close action 00:43.8 | Hullbreaker gutship 00:27.7 | Torpedo 00:28.3, 11 total | Fire for effect 00:47.1; arrival: Hullbreaker raider 01:10.2; victory 01:37.4 in 4 rounds |
| Hullbreakers 3 (Hullbreakers, Rout) | 00:10.2 | Admiral's Command 00:10.7, Close action 00:24.7 | Hullbreaker raider 00:17.5 | Lance 00:18.2, 13 total | Fire for effect 00:46.4; victory 02:12.4 in 6 rounds |
| Navy 1 (Navy, Rout) | 00:08.3 | Moving and facing 00:08.8, Shields and hull 00:19.4, Firing 00:37.8, Threat map 00:45.0 | Cordon destroyer 00:55.2 | Lance 00:36.7, 24 total | Fire for effect 00:50.5; victory 02:59.0 in 11 rounds |
| Navy 2 (Hullbreakers, Hold) | 00:10.8 | Objectives 00:11.3, More ships are coming 00:32.5, Close action 00:39.5 | Hullbreaker gutship 00:48.1 | Torpedo 00:22.8, 6 total | Fire for effect 00:42.9; arrival: Hullbreaker raider 01:03.0; victory 01:22.5 in 4 rounds |
| Navy 3 (Navy, Flagship) | 00:08.2 | Admiral's Command 00:08.8 | Cordon destroyer 00:38.9 | Lance 00:26.2, 9 total | Fire for effect 00:34.4; arrival: Hegemony picket 00:55.8; victory 01:20.7 in 5 rounds |

Vex speaks at the start of every battle ("Hold the line" in Battle 1, "Run out the guns" after), on Fire for effect, when a ship
is lost and on the victory card. Both Battle 2s are Hold battles with a scheduled Hullbreaker raider reinforcement and the
"More ships are coming" card before it. The older run 3 media (recorder merge `c267b280`, seeds 121 and 10) stays in this
branch's history at `61611233` as history only, not acceptance of the current route.

## Profile isolation

The launcher gives each seed and retry a new folder under `%TEMP%` and redirects `APPDATA` and `LOCALAPPDATA` for the
game process. Main checks the resolved `user://` path and creates a one-use marker before it loads settings or opens the
title. It refuses a mismatched path or a folder with existing profile files. The campaign, career and teaching history use
their normal save and load routines inside the temporary profile. The recording log reports the resolved folder and the settings.

A Windows headless check reached Battle 1 with the shipped settings, tips, Key cut-ins and voice enabled. It wrote the campaign
save, backup and teaching history into the temporary profile. The normal profile's settings, saves, backups and preferences had
the same hashes or stayed absent. A wrong folder and a folder holding a career backup were both refused before the title opened.
The backup in the test folder was unchanged.

Run 1 used the launcher’s `APPDATA` redirect. Its two completed recordings passed the older profile guard before opening the
title or starting the campaign and story host. The normal campaign save, career file and their backups all have write times
from before run 1. The normal profile has no `settings.json`, and its battle options and map settings have no write time in
the run 1 window. I found no evidence that run 1 changed Ryan’s saves, settings or story state. The old guard ran after settings were loaded,
so the available records cannot rule out a settings read on an earlier aborted launch. Nothing was restored or overwritten.

## History: run 1 (Nov 19), Ashfall Hullbreakers route, seed 121

Times start with each battle. Card times mark the pilot's reading pauses. Vex opens all three battles with
“Hold the line. Let them come to the broadsides.”
His Command and closing line appear in the battle log and result card.

| Battle | Teaching, overlays and previews | Cut-ins and voice | Hulls |
| --- | --- | --- | --- |
| 1 | Moving and facing and danger 00:07. Move ghost 00:10, Shields and hull 00:17, Threat map 00:35, attack-move 00:38, target odds 00:57. | Fire for effect and Vex's line 00:54. Five cut-ins, 1.60 to 2.70 s. Victory and “The line held” 01:34. | Older Sunward `V16_37`, `V15_37`, `V14_23` and Navy `H7_23`, `H8_23`. |
| 2 | Relay score from the opening. Danger and move ghost 00:08, Close action 00:15, target odds 00:18, warning 01:20. The relay was won before the reinforcement arrived. | Fire for effect 00:47, lost-ship line 01:31, victory 01:50. Eight cut-ins, 0.83 to 2.70 s. | The same older Sunward trio. New Hullbreaker `C13s_23` raiders and `C14s_23` gutship. |
| 3 | Danger, move ghost and Admiral's Command card 00:08. Card read at 00:16, attack-move 00:40, target odds 01:09. | Fire for effect 01:03, lost-ship line 01:34, victory 01:53. Nine cut-ins, 1.60 to 2.70 s. | Older Sunward `V16_37` and `V14_23`. Three new `C14s_23` gutships. |

## History: run 1 (Nov 19), Hegemony Navy route, seed 10

Vex opens Battle 1 with “Hold the line.” He opens Battles 2 and 3 with “Run out the guns. Present the flank.”

| Battle | Teaching, overlays and previews | Cut-ins and voice | Hulls |
| --- | --- | --- | --- |
| 1 | Danger, move ghost and Moving and facing 00:07. Card read at 00:16, Shields and hull 00:24, Threat map 00:34, attack-move odds 00:37. | Seven cut-ins, 1.07 to 3.53 s. Victory and “The line held” 01:50. | Older Sunward `V16_37`, `V15_37`, `V14_23` and Navy `H9_23`. |
| 2 | Relay score from the opening. Danger and move ghost 00:07, target odds 00:22, warning 00:44, Close action 00:50. The raider arrives 01:20. | Fire for effect 00:53, lost-ship line 01:59, victory 02:07. Eleven cut-ins, 1.60 to 3.53 s. | The same older Sunward trio. New `C14s_23` gutships and `C13s_23` raiders, including the arrival. |
| 3 | Danger, move ghost and Admiral's Command card 00:06. Card read at 00:15, attack-move 00:37, Garrison Warden arrival 00:53, target odds 01:14. | Fire for effect 01:09, victory 02:17. Twelve cut-ins, 0.90 to 3.13 s. | Older Sunward `V16_37` and `V15_37`, joined by the older Warden `V14_23`. The Navy's Dominion dreadnought uses the new `H10_23` build. |

Hull build status follows the [installed ship list](../battle_baseline_1118/README.md#installed-hull-contract).

## What this recording adds

The [F1 trace](../f1/0354234/README.md) showed the move ghost, target odds, player handover and arriving reinforcements.
The [look bench](../look_bench/README.md) showed isolated weapons, shields, deaths and hulls at fixed cameras.
The player path shows when fresh-run cards appear, where the danger hatching falls alongside move and target options,
and how the default cut-ins and story lines interrupt or frame those same decisions in a live campaign.

## History: run 1 review notes

- Hullbreakers route, Battle 2 at 01:38. Tab was needed to restore the selected ship after an activation.
- Hullbreakers route, Battle 3 at 00:45. The target hover card stays over the letterboxed lance shot.
- Navy route, Battle 2 at 01:21. The reinforcement banner and the line naming the arriving ship overlap.
- The Windows export falls back to its older rocks when the scanned rock check looks for the raw GLB inside the pack.

## Rerun

Open `tools\pc\jobs\player_path.bat` with a shared installed build that includes the recorder and was exported from a clean
commit. Each clip and sheet carries the source commit, installed pack SHA-256 and the manifest SHA-256 read inside the game.
The launcher verifies each review file. See the [recording notes](../../../contrib/codex/player_path_1119/NOTES.md) for
arguments and output locations.
