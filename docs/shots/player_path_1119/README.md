# Battles 1 to 3 as a new Sunward player sees them

Both routes start with an isolated fresh profile, Standard difficulty, Vex and the starter fleet. The game uses Key cut-ins, the
danger overlay, teaching cards, the full HUD and target card, the battle log and voice lines, and the usual mesh LOD.
The recordings use a 1920 by 1080 window. The 720p clips preserve the whole frame and carry a provenance strip below it.

| Route | Campaign seed | Battle 1 | Battle 2 | Battle 3 |
| --- | ---: | --- | --- | --- |
| Hegemony Navy | 10 | Navy, Engagement | Hullbreakers, Relay | Navy, Engagement |
| Ashfall Hullbreakers | 121 | Navy, Engagement | Hullbreakers, Relay | Hullbreakers, Engagement |

On a fresh profile, the campaign scripts the Navy first and the Hullbreakers second. The seeds select the Sector I
faction and the Battle 3 opponent. Both second battles have the relay and a scheduled teaching reinforcement.

## Run 3 recordings

Both routes won all three battles on the same Windows export from `c267b2804c67ada75037b0f7f34cf095a79b4d84`,
the recorder merge named in the brief. The export used the shared install's generated ship and world assets.
Each clip and contact sheet shows the commit, build SHA-256 and manifest SHA-256 in its stamp.

- Build SHA-256 `ff4c9e4970dcdc7d453954cd97bbf6192df3440453c12179abf67f9a259b3bd4`
- Manifest SHA-256 `c4e1e188ff3d4cb654e2c5a9c8fcc01f49acf5fc655da84e1ce2d93a351c2a52`

| Route and battle | Contact sheet | Clip parts |
| --- | --- | --- |
| Hullbreakers 1 | [HULLBREAKERS-B1](hullbreakers-b1.jpg) | [1](hullbreakers-b1-p01.mp4) · [2](hullbreakers-b1-p02.mp4) |
| Hullbreakers 2 | [HULLBREAKERS-B2](hullbreakers-b2.jpg) | [1](hullbreakers-b2-p01.mp4) · [2](hullbreakers-b2-p02.mp4) · [3](hullbreakers-b2-p03.mp4) · [4](hullbreakers-b2-p04.mp4) |
| Hullbreakers 3 | [HULLBREAKERS-B3](hullbreakers-b3.jpg) | [1](hullbreakers-b3-p01.mp4) · [2](hullbreakers-b3-p02.mp4) · [3](hullbreakers-b3-p03.mp4) |
| Navy 1 | [NAVY-B1](navy-b1.jpg) | [1](navy-b1-p01.mp4) · [2](navy-b1-p02.mp4) · [3](navy-b1-p03.mp4) |
| Navy 2 | [NAVY-B2](navy-b2.jpg) | [1](navy-b2-p01.mp4) · [2](navy-b2-p02.mp4) · [3](navy-b2-p03.mp4) |
| Navy 3 | [NAVY-B3](navy-b3.jpg) | [1](navy-b3-p01.mp4) · [2](navy-b3-p02.mp4) · [3](navy-b3-p03.mp4) |

Times below start at the beginning of each battle. Parts 1 to 4 start at 00:00, 00:48, 01:36 and 02:24. Each contact sheet
is 1280 by 720. All 18 MP4 parts and six JPGs passed `tools/picture_provenance.py verify`.

## What a new player sees

The early cards come up during normal orders, with danger hatching on the same board as the move ghost. The target card
shows expected damage when the target is in range and an attack-move plan when it is out of range. Default cut-ins can
letterbox the board while a target tooltip is still open. Vex's battle voice appears as text in the battle log and on the result
card. The earlier F1 trace already showed the target card, move ghost, handover and reinforcement arrival. These recordings
show how those cues play alongside the cards, danger overlay, cut-ins and dialogue over three consecutive battles.
[F1 trace](../f1/0354234/README.md) · [Look bench](../look_bench/README.md)

| Battle | Danger overlay first appears | Teaching cards | Target card example | First Key cut-in | Vex's battle voice |
| --- | --- | --- | --- | --- | --- |
| Hullbreakers 1 | 00:05.3 | Moving and facing 00:12.4, Shields and hull 00:22.9, Threat map 00:33.2 | Cordon destroyer 00:55.3 | Lance 00:53.0, 5 cut-ins total | Hold the line 00:00.1, Fire for effect 00:52.4, victory 01:32.3 |
| Hullbreakers 2 | 00:07.2 | Close action 00:56.3, More ships are coming 01:28.3 | Hullbreaker raider 00:11.8 | Lance 00:12.5, 15 total | Hold the line 00:00.1, Fire for effect 01:00.1, lost ship 01:45.2, victory 02:42.9 |
| Hullbreakers 3 | 00:07.4 | Admiral's Command 00:15.9 | Hullbreaker gutship 01:08.4 | Lance 00:43.9, 9 total | Hold the line 00:00.1, Fire for effect 01:03.7, lost ship 01:38.1, victory 01:52.1 |
| Navy 1 | 00:06.5 | Moving and facing 00:15.8, Shields and hull 00:23.2, Threat map 00:33.4 | Attack-move forecast for Vanguard cruiser 00:36.7 | Lance 00:43.6, 7 total | Hold the line 00:00.1, victory 01:49.4 |
| Navy 2 | 00:06.9 | More ships are coming 00:44.2, Close action 00:49.9 | Hullbreaker raider 00:21.5 | Torpedo 00:38.7, 11 total | Run out the guns 00:00.1, Fire for effect 00:53.7, lost ship 01:59.4, victory 02:06.8 |
| Navy 3 | 00:05.2 | Admiral's Command 00:14.8 | Dominion dreadnought 01:13.3 | Lance 00:40.7, 12 total | Run out the guns 00:00.1, Fire for effect 01:08.6, victory 02:16.4 |

Battle 2 opens with the relay score on both routes. The enemy raider arrives at 01:49.6 on the Hullbreakers route and 01:20.5
on the Navy route. The Hullbreakers Battle 3 sheet shows the hover card over the letterboxed lance shot at 00:44.5. On the
Navy route the Garrison Warden joins Battle 3 at 00:52.6.

## Current-main attempt

On the runner's clean main revision `f39399f0`, seed 121 won all three battles and its review media verified. Its third battle
was a relay. Seed 10 won the first two battles, then the recorder stopped with `expected route 2-2 is missing after Battle 2`.
The sector map change in PR 1191 made Navy stop `2-2` an event. The six recordings above use the earlier recorder merge,
where that stop is a Hegemony engagement. The two exports used the same shared asset manifest.

## Run 1 recording status

Run 1 won all three battles on both routes. Its AVI masters and frame logs, including the flagship name prompt, sector
map, rewards and Nemesis cards, are in `Downloads\voidsworn_test\board_b\issue-1143\player_path_1080p_delivery`.
The run 1 export included working-tree changes, so its clips and sheets fail the clean-build provenance check.
The historical notes below describe run 1.

## Profile isolation

The launcher gives each seed and retry a new folder under `%TEMP%` and redirects `APPDATA` and `LOCALAPPDATA` for the
game process. Main checks the resolved `user://` path and creates a one-use marker before it loads settings or opens the
title. It refuses a mismatched path or a folder with existing profile files. The campaign, career and teaching history use
their normal save and load routines inside the temporary profile. The recording log reports the resolved folder and the settings.

Both delivered routes passed the profile guard and wrote their own campaign, career and battle options in separate temporary
folders. The normal campaign and career files and their backups kept write times from before the recordings. The normal
`battle_opts.json` was written at 13:11:11 CST, one second after a hull fixture from the overlapping world and bench audit.
That audit opens a battle with the normal profile, which rewrites battle options on entry.

A Windows headless check reached Battle 1 with the shipped settings, tips, Key cut-ins and voice enabled. It wrote the campaign
save, backup and teaching history into the temporary profile. The normal profile's settings, saves, backups and preferences had
the same hashes or stayed absent. A wrong folder and a folder holding a career backup were both refused before the title opened.
The backup in the test folder was unchanged.

Run 1 used the launcher’s `APPDATA` redirect. Its two completed recordings passed the older profile guard before opening the
title or starting the campaign and story host. The normal campaign save, career file and their backups all have write times
from before run 1. The normal profile has no `settings.json`, and its battle options and map settings have no write time in
the run 1 window. I found no evidence that run 1 changed Ryan’s saves, settings or story state. The old guard ran after settings were loaded,
so the available records cannot rule out a settings read on an earlier aborted launch. Nothing was restored or overwritten.

## Run 1, Ashfall Hullbreakers route, seed 121

Times start with each battle. Card times mark the pilot's reading pauses. Vex opens all three battles with
“Hold the line. Let them come to the broadsides.”
His Command and closing line appear in the battle log and result card.

| Battle | Teaching, overlays and previews | Cut-ins and voice | Hulls |
| --- | --- | --- | --- |
| 1 | Moving and facing and danger 00:07. Move ghost 00:10, Shields and hull 00:17, Threat map 00:35, attack-move 00:38, target odds 00:57. | Fire for effect and Vex's line 00:54. Five cut-ins, 1.60 to 2.70 s. Victory and “The line held” 01:34. | Older Sunward `V16_37`, `V15_37`, `V14_23` and Navy `H7_23`, `H8_23`. |
| 2 | Relay score from the opening. Danger and move ghost 00:08, Close action 00:15, target odds 00:18, warning 01:20. The relay was won before the reinforcement arrived. | Fire for effect 00:47, lost-ship line 01:31, victory 01:50. Eight cut-ins, 0.83 to 2.70 s. | The same older Sunward trio. New Hullbreaker `C13s_23` raiders and `C14s_23` gutship. |
| 3 | Danger, move ghost and Admiral's Command card 00:08. Card read at 00:16, attack-move 00:40, target odds 01:09. | Fire for effect 01:03, lost-ship line 01:34, victory 01:53. Nine cut-ins, 1.60 to 2.70 s. | Older Sunward `V16_37` and `V14_23`. Three new `C14s_23` gutships. |

## Run 1, Hegemony Navy route, seed 10

Vex opens Battle 1 with “Hold the line.” He opens Battles 2 and 3 with “Run out the guns. Present the flank.”

| Battle | Teaching, overlays and previews | Cut-ins and voice | Hulls |
| --- | --- | --- | --- |
| 1 | Danger, move ghost and Moving and facing 00:07. Card read at 00:16, Shields and hull 00:24, Threat map 00:34, attack-move odds 00:37. | Seven cut-ins, 1.07 to 3.53 s. Victory and “The line held” 01:50. | Older Sunward `V16_37`, `V15_37`, `V14_23` and Navy `H9_23`. |
| 2 | Relay score from the opening. Danger and move ghost 00:07, target odds 00:22, warning 00:44, Close action 00:50. The raider arrives 01:20. | Fire for effect 00:53, lost-ship line 01:59, victory 02:07. Eleven cut-ins, 1.60 to 3.53 s. | The same older Sunward trio. New `C14s_23` gutships and `C13s_23` raiders, including the arrival. |
| 3 | Danger, move ghost and Admiral's Command card 00:06. Card read at 00:15, attack-move 00:37, Garrison Warden arrival 00:53, target odds 01:14. | Fire for effect 01:09, victory 02:17. Twelve cut-ins, 0.90 to 3.13 s. | Older Sunward `V16_37` and `V15_37`, joined by the older Warden `V14_23`. The Navy's Dominion dreadnought uses the new `H10_23` build. |

Hull build status follows the [installed ship list](../battle_baseline_1118/README.md#installed-hull-contract).

## Run 1 review notes

- Hullbreakers route, Battle 2 at 01:38. Tab was needed to restore the selected ship after an activation.
- Hullbreakers route, Battle 3 at 00:45. The target hover card stays over the letterboxed lance shot.
- Navy route, Battle 2 at 01:21. The reinforcement banner and the line naming the arriving ship overlap.
- The Windows export falls back to its older rocks when the scanned rock check looks for the raw GLB inside the pack.

## Rerun

Open `tools\pc\jobs\player_path.bat` with a shared installed build that includes the recorder and was exported from a clean
commit. Each clip and sheet carries the source commit, installed pack SHA-256 and the manifest SHA-256 read inside the game.
The launcher verifies each review file. See the [recording notes](../../../contrib/codex/player_path_1119/NOTES.md) for
arguments and output locations.
