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

## Recording status

Run 1 won all three battles on both routes. Its AVI masters and frame logs, including the flagship name prompt, sector
map, rewards and Nemesis cards, are in `Downloads\voidsworn_test\board_b\issue-1143\player_path_1080p_delivery`.
The run 1 export included working-tree changes, so its clips and sheets fail the clean-build provenance check.
The verified media set still needs an export from a clean commit. The observations below come from run 1.

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

## What this recording adds

The [F1 trace](../f1/0354234/README.md) showed the move ghost, target odds, player handover and arriving reinforcements.
The [look bench](../look_bench/README.md) showed isolated weapons, shields, deaths and hulls at fixed cameras.
The player path shows when fresh-run cards appear, where the danger hatching falls alongside move and target options,
and how the default cut-ins and story lines interrupt or frame those same decisions in a live campaign.

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
