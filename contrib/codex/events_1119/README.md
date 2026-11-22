# Issue 1149 · Chorus and Eclipse campaign events

The Chorus and Eclipse each have their own copy for mercenaries, mutiny, the stranded pilot, deserters, veterans, the reactor, the convoy and the auction. The sabotage card also has faction copy so it follows the defector's tip in either fleet. Other shared cards and reward lines that assigned human roles to the player's fleet now use fleet wording.

| Event | Chorus | Eclipse |
| --- | --- | --- |
| Mercenary | A brood cut loose | A destroyer outside the link |
| Mutiny | A pulse out of step | A divergent copy |
| Pilot | An orphan wing | A recovered flight record |
| Deserters | A Navy pod on the fringe | A Navy pod requests clearance |
| Veterans | A memory in the nursery | An Archive drill cache |
| Reactor | A split light sac | A failing core seal |
| Convoy | Ore haulers in the swarm’s wake | A transit request |
| Auction | Salvage on an open pulse | An open salvage exchange |

The Chorus Nemesis uses **Breach broods** and **Thin aft hide** for the existing `boarders` and `flank` keys. The Dossier, battle notices and debrief resolve those names from the rival's faction. Event variants use the existing Astropath format. The export builds each option array from the original options and substitutes only labels and summaries.

## Standing check

Godot CI runs the test without arguments. It draws every eligible event and the quiet fallback for all six factions and checks that each card shows its choices and writes the expected save keys. It scans Chorus and Eclipse titles, bodies, choices, requirement text and event receipts for human fleet wording. It also checks the existing Nemesis lookups. The standing check reads current requirements and rewards from the event table, so balance changes do not require updating the historical report.

## Historical seeded comparison

Godot 4.7.2 ran **seeds 1 to 64 for each faction, 384 campaigns** on main `a3b9f555` and again with the changes. The driver starts a fresh profile with Vex and no Heat. It uses the real campaign map and click actions with the existing stub battle. It prefers reachable event nodes, chooses among enabled options with a separate seeded random stream, and takes victory through the standard battle reward menus. Each event row records its draw count, saved option keys, event battle count, and the net change from before the choice to completion of the node. Event battle rows include the ordinary gains and losses of the fight as well as its event reward.

The acceptance band is **exact equality** for each faction's per-event counts, option counts, fight routing and every measured reward total. The fixture `godot/campaign/test/fixtures/event_distribution_a3b9f555.json` records the rows that matched main in the original comparison. The opt-in check compares these rows with a fresh run and prints the expected and actual values for each changed faction/event row or total. It also scans receipts reached by the seeded routes for human fleet wording. Hegemony keeps its own bans, the Chorus still skips the infested moon, and Eclipse still gets the dormant hull yard in place of the siphon array.

Both runs produced the following totals. Negative figures are net costs or losses. Hull and Marks include ships added or lost on the event branch. Intel counts Nemesis weaknesses revealed and clock is the net change in Nemesis clock points.

| Faction | Runs completed | Draws | Event fights | Credits | XP | Salvage | Refits | Ships | Hull | Marks | Wing perks | Intel | Clock |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Sunward Crusade | 64 | 186 | 7 | 995 | 1700 | 2 | 15 | -1 | 28 | 5 | 3 | 15 | 17 |
| Hegemony Navy | 64 | 186 | 8 | -160 | 2950 | 13 | 4 | -3 | -300 | 5 | 1 | 13 | 11.5 |
| Ashfall Hullbreakers | 64 | 186 | 5 | 1244 | 2771 | 12 | -3 | 3 | 34 | 11 | 0 | 17 | 13 |
| Chorus | 64 | 178 | 5 | 472 | 1806 | 14 | 7 | 2 | -172 | 8 | 0 | 20 | 12 |
| Glasswrights | 64 | 175 | 13 | 648 | 3708 | 11 | 8 | 2 | -519 | 4 | 0 | 15 | 13.5 |
| Eclipse | 64 | 183 | 2 | 1221 | 1623 | 8 | 20 | 7 | 369 | 15 | 1 | 15 | 10.5 |

<details>
<summary>Per-event counts and net rewards, identical before and after</summary>

Each cell gives draws/event fights, followed by the nonzero net changes. A dash means the route did not draw that event.

| Event key | Sunward Crusade | Hegemony Navy | Ashfall Hullbreakers | Chorus | Glasswrights | Eclipse |
| --- | --- | --- | --- | --- | --- | --- |
| astropath | 2/0 · +1 salvage, -1 refits | 7/0 · +4 salvage, -123 hull | 4/0 · +3 salvage, -2 refits, -12 hull | 7/0 · +3 salvage, -1 refits, -77 hull | 5/0 · +3 salvage, -1 refits, -56 hull | 5/0 · +3 salvage, -105 hull |
| auction | 4/0 · -120 credits, +1 salvage | 14/0 · -680 credits, +7 salvage | 5/0 · -320 credits, +3 salvage | 11/0 · -720 credits, +7 salvage | 10/0 · -800 credits, +7 salvage | 4/0 · -200 credits, +2 salvage |
| bait | 7/0 · +480 credits | 6/0 · +160 credits | 4/0 · +240 credits | 4/0 · +160 credits | 3/0 · +160 credits | 8/0 · +480 credits |
| battlefield | 7/0 · +4 refits, -46 hull | 8/0 · +4 refits, -14 hull | 6/0 · +1 refits, -14 hull | 8/0 · +6 refits, -45 hull | 4/0 · +1 refits, -7 hull | 13/0 · +7 refits, -83 hull |
| beacon | 5/0 · +300 credits, +70 XP, +1.5 clock | - | 1/0 · +100 credits, +1 clock | 6/0 · +270 credits, +125 XP, +1 intel, +1 clock | 6/0 · +181 credits, +108 XP, +2 clock | 2/0 |
| broker | 7/0 · -240 credits, +4 intel | 6/0 · -240 credits, +4 intel | 5/0 · -60 credits, +3 intel | 4/0 · -120 credits, +2 intel | 4/0 · -180 credits, +2 intel | 5/0 · -120 credits, +2 intel |
| cache | 10/0 · +315 credits, +4 refits | 5/0 · +135 credits, +2 refits | - | 4/0 · +180 credits, +1 refits | 5/0 · +135 credits, +4 refits | 6/0 · +180 credits, +3 refits |
| convoy | 5/0 · -195 credits, +4 refits | 5/0 · +15 credits, +2 refits | 8/0 · +475 credits, +1 refits, +3.5 clock | 7/0 · +3 refits | 5/0 · -90 credits, +3 refits | 9/0 · +90 credits, +3 refits |
| defector | 6/0 · +210 credits, +3 intel, +3 clock | 7/0 · +140 credits, +100 XP, +5 intel, +1 clock | 10/0 · +350 credits, +5 intel, +4.5 clock | 10/0 · +350 credits, +5 intel, +3.5 clock | 5/0 · +140 credits, +3 intel, +2.5 clock | 9/0 · +230 credits, +4 intel, +4.5 clock |
| derelict | 5/0 · +115 credits, +2 refits | 4/0 · +155 credits, +3 refits | 6/0 · +190 credits, +3 refits | 5/0 · +125 credits, -39 hull | 6/0 · +195 credits, +4 refits | 10/0 · +285 credits, +4 refits, -36 hull |
| deserters | 8/0 · +180 credits, +318 XP | - | 6/0 · +240 credits, +90 XP, +1 intel | 8/0 · +120 credits, +219 XP, +5 intel | 6/0 · +120 credits, +189 XP, +1 intel | 6/0 · +180 credits, +138 XP, +2 intel |
| dock | 8/0 · -360 credits, +331 hull, +3 Marks | 7/0 · -290 credits, +77 hull, +2 Marks | 3/0 · -160 credits, +93 hull, +1 Marks | 7/0 · -330 credits, +158 hull, +3 Marks | 8/0 · -30 credits | 9/0 · -350 credits, +143 hull, +2 Marks |
| haven | 8/3 · +280 credits, +76 XP, -2 ships, -234 hull, -2 Marks, +1 clock | 4/1 · -228 credits, +210 XP, -80 hull | 6/1 · +175 credits, -35 XP, +1 ships, +11 hull, +1 Marks | 8/5 · +447 credits, +613 XP, -275 hull, +5.5 clock | 5/1 · +43 credits, +173 XP, -32 hull, -1 clock | 1/0 · -40 credits, -1 clock |
| lament | 5/0 · +120 credits, +265 XP, -1 salvage, +1 intel | 6/0 · +350 XP | 9/0 · +460 XP | 4/0 · +120 credits, +180 XP, -1 salvage, +1 intel | 4/0 · +120 credits, +160 XP, +1 intel, -1 clock | 4/0 · +195 XP |
| merc | 7/0 · -160 credits, +90 XP, +3 ships, +268 hull, +3 Marks | 5/0 · -80 credits, +30 XP, +1 ships, +74 hull, +1 Marks | 5/0 · -320 credits, +120 XP, +4 ships, +282 hull, +4 Marks | 3/0 · -160 credits, +60 XP, +2 ships, +164 hull, +2 Marks | 5/0 · -240 credits, +90 XP, +3 ships, +180 hull, +3 Marks | 4/0 · -80 credits, +30 XP, +1 ships, +100 hull, +1 Marks |
| moon | 3/1 · +152 credits, -114 XP, -2 ships, -89 hull, -2 Marks, +1 clock | 7/4 · +620 credits, +798 XP, -2 ships, -190 hull, -2 Marks, +3 clock | 8/2 · +463 credits, +689 XP, +2 refits, -124 hull, +1.5 clock | - | 7/3 · +282 credits, +685 XP, -133 hull, +2.5 clock | 7/2 · +218 credits, +584 XP, -61 hull, +1 clock |
| mutiny | 8/0 · -150 credits, -50 XP | 8/0 · -150 credits, -5 XP | 6/0 · -150 credits, -15 XP | 7/0 · -100 credits, -16 XP | 4/0 · -150 credits, +20 XP | 5/0 · -100 credits, +10 XP |
| pilot | 7/0 · +92 XP, +3 wing perks | 4/0 · +80 XP, +1 wing perks | 6/0 · +92 XP | 3/0 | 10/0 · +264 XP | 7/0 · +132 XP, +1 wing perks |
| quiet | - | - | - | - | - | - |
| reactor | 3/0 · -45 credits, -54 hull | 4/0 · -1 refits, -71 hull | 8/0 · -135 credits, -109 hull | 7/0 · -180 credits, -73 hull | 4/0 · -45 credits, -2 refits, -36 hull | 4/0 · -57 hull |
| saboteur | 8/0 · -63 hull, +6 intel, +3 clock | 4/0 · -87 credits, -18 hull, +2 intel, +3 clock | 6/0 · -35 hull, +5 intel, +2 clock | 5/0 · -28 hull, +3 intel | 6/0 · -64 credits, -21 hull, +3 intel, +5 clock | 4/0 · -182 credits, -10 hull, +1 intel, +5 clock |
| scout | 5/0 · +1 intel, +3 clock | 5/0 · -19 hull, +2 intel, +0.5 clock | 3/0 · -16 hull, +3 intel, -3 clock | 3/0 · -65 hull, +3 intel, -2.5 clock | 7/0 · -73 hull, +5 intel, -5 clock | 9/0 · -110 hull, +6 intel, -2.5 clock |
| seer | 4/0 · +3 salvage, -3 refits | 8/0 · +5 salvage, -5 refits | 9/0 · +8 salvage, -8 refits | 8/0 · +5 salvage, -4 refits | 4/0 · +3 salvage, -2 refits | 5/0 · +3 salvage, -1 refits |
| shrine | 8/0 · +178 XP, -2 salvage, +36 hull | 12/0 · -100 credits, +284 XP, -3 salvage, +60 hull | 6/0 · -50 credits, +184 XP, -2 salvage, +92 hull | - | 9/0 · -100 credits, +208 XP, -2 salvage, +182 hull | - |
| spawn | 9/0 · +200 XP, +6 refits | 5/0 · +236 XP, +3 refits | 8/0 · +408 XP, +3 refits | 10/0 · +240 XP, +3 refits, +126 hull | 5/0 · +264 XP, +2 refits | 9/0 · +284 XP, +6 refits |
| squall | 5/0 · -35 credits, -114 hull | 5/0 · -35 credits, +90 XP, -23 hull | 7/0 · -70 credits, +80 XP, -80 hull | 3/0 · -35 credits, -46 hull | 5/0 · -35 credits, -71 hull | 2/0 · -35 credits, -33 hull |
| storm | 8/0 · -200 credits, +69 XP, -45 hull | 11/0 · -120 credits, +130 XP, -144 hull | 5/0 · -120 credits, +30 XP, -21 hull | 5/0 · -80 credits, +70 XP, -27 hull | 9/0 · -200 credits, +79 XP, -75 hull | 2/0 · -65 hull |
| tithe | 4/0 · -2 credits, +1.5 clock | 7/0 · +350 credits, +2 clock | 5/0 · +210 credits, +1.5 clock | 4/0 · +280 credits, +4.5 clock | 5/0 · +140 credits, +2 clock | 6/0 · +350 credits, +3.5 clock |
| tomb | 6/3 · +365 credits, +357 XP, -31 hull, +3 clock | 4/3 · +355 credits, +265 XP, -2 ships, -196 hull, -2 Marks, +2 clock | 3/2 · +241 credits, +96 XP, +2 refits, -2 ships, -91 hull, -2 Marks, +2 clock | 4/0 · +120 credits | 11/9 · +1081 credits, +1336 XP, -1 ships, -393 hull, -1 Marks, +6.5 clock | - |
| tombhome | - | - | - | - | - | 12/0 · +360 credits, +6 ships, +336 hull, +6 Marks |
| veterans | 4/0 · -50 credits, +149 XP | 4/0 · -150 credits, +382 XP | 8/0 · -300 credits, +572 XP | 5/0 · -150 credits, +315 XP | 2/0 · -50 credits, +132 XP | 5/0 · -150 credits, +250 XP |
| well | 2/0 · +35 credits, -10 hull | 2/0 · +70 credits, -28 hull | 10/0 · +245 credits, -103 hull | 9/0 · +175 credits, -84 hull | 3/0 · +35 credits, -14 hull | 4/0 · +105 credits, -49 hull |
| wright | 8/0 · -1 refits, +79 hull, +3 Marks | 12/0 · -4 refits, +395 hull, +6 Marks | 10/0 · -5 refits, +161 hull, +7 Marks | 9/0 · -1 refits, +139 hull, +3 Marks | 3/0 · -1 refits, +30 hull, +2 Marks | 7/0 · -2 refits, +399 hull, +6 Marks |

</details>

From the checkout root, run the standing check and, when reviewing the historical comparison, pass `--compare`. The optional absolute path writes the current full report, including option counts and zero totals. A changed row gives the comparison a nonzero exit status.

```powershell
$godot = "$env:USERPROFILE\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --path godot --script res://campaign/test/event_distribution_test.gd
& $godot --headless --path godot --script res://campaign/test/event_distribution_test.gd -- --compare "$env:TEMP/events-after.json"
```
