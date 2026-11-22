# Challenge round: Fable on Muse's blind round

Muse's side: issue 1371, branch muse/issue-1371 at 85c4d8c2. Files read: synthesis.md (Rey chairs), Rey's three blind legs
(UI/UX, art, lore) and the first-time player legs from DeepSeek, Qwen and the Flash seat (run on Gemini Hydrogen). Grok's
seat is empty (bot wall), so nothing is attributed to it.
Checked against: the code on claude/project-thread-8hcjwy at 5ead56fa, live main at 4cf53436 where it matters, the pack
pictures (opened, not trusted from the text), the two traces, docs/RULEBOOK.md, contrib/opus/FINDINGS.md up to R367 on
main, the rename map and docs/playbooks/screens.md. Findings only; nothing but this file and the ranked list was written.

## Answer first

Muse's synthesis holds 26 findings: 12 the legs agree on, 8 single-leg findings the chair keeps, 6 from the lore seat.
15 stand, 7 are wrong in their headline, 2 are ruled, 1 is not felt, 1 is already known. Inside the standing ones, 9
smaller claims or fixes fall (listed under each). 14 of the 15 that stand match something Fable or Neon found blind, which
is the useful part: three more outside models and a second expert chair hit the same first-hour problems. Muse brings
4 things nobody else had: the ship card that keeps showing my spent ship while the enemy acts, the flat 19-row battle
menu, an "enemy want" line for the battle intro, and the credits small print.

| Verdict | Agreed 12 | Single-leg 8 | Lore 6 | Total |
|---|---:|---:|---:|---:|
| Stands | 9 (1, 2, 3, 4, 6, 8, 9, 11, 12) | 4 | 2 | 15 |
| Wrong | 3 (5, 7, 10) | 2 | 2 | 7 |
| Ruled | 0 whole, 2 parts (11 fix, 12 threat map) | 0 | 2 | 2 |
| Not felt | 0 | 1 | 0 | 1 |
| Already fixed, planned or known | 0 whole, 2 parts (9 fix, 11 fix) | 1 | 0 | 1 |
| Bad fix | 0 whole, 4 parts (1 rim and zoom, 2, 4 guaranteed loot, 4 greyed options) | 0 | 0 | 0 |

A limit on Muse's evidence, which explains several misses. The legs used a 15 picture set with its own names
(01_title to 15_defeat). It mixes a quick battle (the six stills, fleet Resolve of the Reach) with the two runs (fleet
Vigilant Ash), so before and after pictures are sometimes two battles apart. Muse also says the front-end set "failed to
capture" and that no Chorus, Eclipse or Glasswright battle is in the pack. Both were added to the pack later
(pack/frontend, 37 pictures; pack/factions, 18 pictures; pack/README.md "Added for the challenge round"). So no Muse seat
judged setup, the faction desks, help, lineage, progression or the three faction battles.

Muse's names against the pack's: 05 to 10 are stills 01 to 06 (battle start, move preview, enemy clicked, tip card and
legend, enemy turn, menu); 03 is s10 t001; 04 is s10 t003; 12 is s10 t022; 13 is s10 t038; 15 is s121 t040.

## The four strongest knockdowns

1. **The "enemy pickets that look like rocks" in battle_03 are rocks.** Rey's UI/UX 1 and art 1 both say the two Hegemony
   pickets "read as grey rocks among the asteroids until the orange hex outlines them". The two orange hexes in still 03
   are the two asteroids that block the shot: the card in the same frame says "Blocked by the asteroid at 9,10, the
   asteroid at 9,12", and battle.gd:2926 draws that outline (`board.show_blockers(_shot_blockers(shot_target))`). The
   target is 21 hexes away and off the screen. The wider finding (ships hard to read) stands on other pictures; this
   picture does not show it. It does show something else: an outline in the intent colour on a rock reads as "enemy" to
   two expert legs, which backs item "Blocked by the asteroid at 9,10" in the ranked list.
2. **"Promoted to Commander" then "Captain" is two promotions, not a mismatch (finding 5).** 12_victory_salvage is s10
   t022, after Battle 1. 13_promotions is s10 t038, after Battle 2. The trace shows one perk pick after each battle for
   the same captain (seed-10.jsonl lines 66 and 99). The rank table is Lieutenant, Commander, Captain, Commodore, Fleet
   captain, so Wyndham rose once per battle. The promotions card also does say what a promotion gives: "A promotion lets a
   captain with enough experience pick a perk. Perks stay with the captain, even on a new ship." A real mismatch exists
   for other factions, see "missed" 1.
3. **Three admiral names from three factions are not a collision (lore 4).** Roderic Vex is the Sunward player admiral.
   "High Nadir Essvane" is an Eclipse hunter and "Line Admiral Konrad Steiner" a Hegemony one: the hunter's title and
   name come from a table keyed by faction (tables.json NEM_FAC: Eclipse titles "High Nadir, Eclipse-prime, Archivist";
   Hegemony "First Admiral, Fleet Marshal, Line Admiral, High Commodore"). A rule per faction is what Rey asks for, and
   it is what the data does. The same slip is in lore 2: "High Nadir" is counted as Sunward vocabulary.
4. **The threat map is not buried and hatching by default was ruled out today (finding 12).** R361 (Ryan, Nov 20, PR
   1367): "reach hatching shows only with Z". The threat map has its own key (R) and its own teaching card on round two
   (battle.gd:75, "Press R for the threat map"; onboarding_test.gd:92). screens.md:91 puts speed, threat map, top-down
   and grid in the Esc menu on purpose. The menu grouping half of the finding stands.

Also knocked: the map flight needs no click (it ends by itself after 2.4 s, map3d.gd:79); the node's "Pays: Signal of
Rook" is paid, on the next card, which no still caught; the ability row is not icon-only (Brace, Focus fire, Fire for
effect, Turn, Next ship are written out in stills 03 to 05).

## The 12 findings the legs agree on

### 1. Ships do not read at the battle camera: **Stands** (fix and one picture knocked)

- Agrees with ranked items "ships are dark slivers" (Fable art 1, FTP; Neon blind 1), "the enemy slides off screen"
  (Rey UI/UX 1, still 01) and "tan asteroids are the brightest thing" (Rey art 3). Three more points.
- battle_03 does not show enemy hulls at all (knockdown 1). Use still 05, s10 t011, t020 and s121 t012 instead.
- "Debris" in Battle 2 is the asteroid field (blockers), not the debris terrain. Same complaint, right name.
- Fixes: a kit-level rim on every hull is the fix Neon already knocked down on Fable (a global rim burned out the
  Glasswrights, issue 362). A tighter default framing pushes the enemy further off screen. The list's fix stays: a
  distance-scaled boost on each faction's accent and engine lights, framing kept wide.
- "The enemy fleet starts off-frame": the opening frame does fit both fleets for 1.75 s (battle.gd:678), then the camera
  leaves. Rey's "pan to the enemy line once on entry" is that. The missing half is edge markers (RULEBOOK 10.8).

### 2. The bottom ship card keeps my spent ship during the enemy turn: **Stands** (new; fix adjusted)

- Still 05: top left says "Enemy turn, Hegemony picket"; the shelf shows RESOLVE OF THE REACH, three guns "Out", and
  the right half is empty. The shelf follows my selection, and nothing on it says the enemy is acting.
- Two corrections. The acting ship is named, in small grey text top left (ledger.gd:309 to 313). And "The enemy fleet is
  focusing its fire on this ship" is not stale: it is the current focus flag (battle.gd:4770), the same line as on my
  turn.
- Bad fix: making the card follow the acting enemy hides my own shields and hull at the moment they are being shot.
  Better: keep my ship, grey its orders and guns under a plain "Enemy turn: <ship> is acting" head, and put the acting
  ship in the empty right half (name, class, what it fires). Neon's "empty right half of the shelf" was dropped as not
  felt; this is the felt version of it.

### 3. Defeat explains nothing: **Stands** (one part corrected)

- s121 t040 as described: score line, admiral line, Continue; the cause is in the Log. Matches the ranked item "the
  battle ends and the card does not say why". One more point.
- "Nothing shows what the run banked": Neon's referee check found the run debrief after Continue shows what was earned.
  So the ask is smaller: name what Continue opens, which the list's fix already says.

### 4. Victory salvage is thinner than its fiction: **Stands** (two parts knocked)

- s10 t022 as described: three "Scrap it" rows, and text about strip and tow. Matches "my first loot screen is three
  Scrap it buttons". One more point. Qwen's "show one visible sink" is the same fix as "credits with nothing in sight to
  spend them on": one more point there.
- Wrong: "the promised reward never appears". The trace shows takeSalvage, takeBoon, takePerk within 88 frames after
  Battle 1 (seed-10.jsonl lines 64 to 66): the protocol offer from the node's core is the next card
  (campaign_ui.gd:2373 to 2377). The stills are 8 s apart and missed it. What is left is in "missed" 2.
- Bad fix: "guarantee one non-credit choice per victory" is a balance change, and loot other than credits already
  exists: what a wreck yields depends on how it died (campaign.gd:3271), and seed 10 took a module after Battle 2 (trace
  line 98, "0:mod"; the "battery loaders" line in t038).
- Bad fix: greyed rows for Tow and Ransom. Tow is Hullbreakers only and Ransom belongs to captured prize ships, so a
  Sunward player would see two rows that can never light up in this run. The list's fix (describe only what this card
  offers, and say why this wreck gives only scrap) stays. Ryan picks if he wants the advert.

### 5. Promotions are coupons, and the ranks do not agree: **Wrong** in the headline (two parts stand)

- Ranks: knockdown 2. Not a mismatch on the Sunward runs shown.
- Stands: both perks are small numbers about rules not yet taught (s10 t038). Matches the below-the-line item on
  promotion perks: one more point, which lifts it into the main list.
- Stands: the refit line sits only in the bottom strip (t038). Matches "a stripped refit goes to the hold with one
  toast": one more point.

### 6. The first decision runs on unexplained words: **Stands** (corrected)

- s10 t001 and t003 as quoted. Matches "words nobody taught me". One more point.
- Correction: "defined nowhere" should be "defined only on hover". Heat has a hover ("the run's difficulty level, up to
  9", ledger.gd:368), the map has a hover card per stop and a Map key. screens.md lines 85 to 95 chose hover for these
  on purpose, so the fix is a first-mention sentence, not always-on labels.
- Rey's idea that the hunter's first calling card should carry the word "cores" is a good one, but that card is story
  text behind RULEBOOK 11.4 (Ryan's read). Kept as a note on the item.

### 7. Teaching cards park on top of the action: **Wrong**

- Still 04: the two boxes are at the right edge, over rocks and sky. No enemy is in the frame (the fleet is 21 hexes off
  screen). The Engagement box is the terrain key the capture opened by clicking it ("Click to close"), not a card the
  game pushed.
- s10 t022: the Rewards tip is in the top right corner, well clear of the salvage rows.
- "Dock first-run tips to an edge" is what the build does (hud.gd:719 to 735). The real card problems are in the list
  already (five rules on the first card, cards opening in the enemy turn); Muse did not find those, so no point.

### 8. "No ready gun can reach it" nags and does not teach: **Stands**

- Still 03 shows it three times, not four (top centre, target box, and "No ready weapon can reach this target" in the
  card) plus "Out" on each gun. Still 04 confirms the top line stays after the card closes.
- Matches the top ranked item. One more point. Muse missed the worse half: the big button says BURN AND FIRE at the
  same moment in the run frames.
- The fix (show where guns would bear) partly exists: the move preview already says "N of 3 guns bear on an enemy from
  here", which every leg praised.

### 9. Blocked shots cite coordinates the grid never shows: **Stands** (fix already built)

- Still 03, battle.gd:3875. Matches "Blocked by the asteroid at 9,10". One more point.
- "Highlight the exact obstructing asteroid" is already done (the two orange hexes, battle.gd:2926). The fix left is
  the words: "Blocked by the two marked asteroids". And see knockdown 1: the outline uses the intent colour and was read
  as enemy ships.

### 10. Arc letters undefined, ability row icon-only: **Wrong** as a separate finding

- The ability row has words on every button in every still (Brace, Focus fire, Fire for effect, Turn, Next ship,
  Reload). The letters P, S, F are not hotkeys; they are the gun's arc.
- The arc letters do have a hover ("Port, range 1 to 5 hexes. Turn with Q / E to bring it to bear", battle.gd:4744).
  That they are not explained without a hover is part of finding 6 and of "words nobody taught me" (weapon row
  letters), already counted there.

### 11. The sector map's icon language is closed: **Stands** (fix ruled or already there)

- s10 t003: the route web is one grey tangle and the stop marks have no words. Matches the below-the-line item "the
  route web is one flat tangle" (Fable art 13): one more point.
- Already there: every stop has a hover card with its name, kind, enemy and danger (map3d.gd:1084 to 1086), and the
  next jump is drawn in ember (the orange line in t003).
- Ruled: the map is Ryan's pick (R165: Briefing layout, "minus clutter and noise", everything else one hover or one
  click away, campaign_ui.gd:1015 to 1020). A legend under the map and Rey's "planet treatment per world" can only come
  back as reopen: Ryan's call.

### 12. Pause menu: flat list, threat map off: **Stands** for the list, **Ruled** for the defaults

- Still 06 has 19 rows, not 18: Resume, 14 switches (sound, pace, comfort, overlays, view), Controls, Quit to title,
  Copy a problem report, Quit the game, in one list with no groups. New item, below the line. It pairs with the menu
  overflow at Larger text already there: grouping into two columns fixes both.
- Defaults: knockdown 4.

## The 8 single-leg findings

| Finding | Verdict | Why |
|---|---|---|
| Round 1 is an empty approach turn (Hydrogen) | **Stands** | Still 03: 21 hexes apart, guns reach 5 and 7. Same as the ranked item "nothing to shoot on the first turn". One more point. Ryan picks the start distance |
| The firing tooltip covers the beam (Hydrogen) | **Stands** | Same as "the cut-in still has the planning tooltip on top" (hud.gd:1264). One more point. The fix there (hide it in letterbox) is better than moving it sideways |
| Drift skip is manual on every jump (Qwen) | **Wrong** | The line reads "In flight. Click or press Space to skip." The flight ends by itself after 2.4 s (map3d.gd:79, :1249 to 1251). Nothing has to be clicked |
| Enemy turns show no intent for next round (Qwen) | **Wrong** | Sides alternate one ship at a time, and the enemy picks its target when it acts, so there is no plan to paint. What the game has instead: the threat map (R, taught on round two), the "focusing its fire" flag, and danger badges on the fleet list |
| Title screen has no hero ship (Rey art 4) | **Stands** | Same as the ranked title item (Fable art 7, Neon blind 11). One more point. Ryan picks |
| Sky sequencing across the first two battles (Rey art 5) | **Not felt** | The compare is seed 10 against seed 121, two different runs. Inside one run a sector shares one sky per enemy faction by design (world_sky.gd:14 to 15), and a player sees one run |
| Weapon fire has no faction tint (Rey art 6) | **Already known** | Neon's weapon fx audit of Nov 19, section 2 "Faction weapon identity", names the same gap gun by gun. No new evidence here (two frames) |
| Credits are dense small print with full URLs (Rey UI/UX 10, art 8, DeepSeek) | **Stands** | Credits still: about 30 lines, each track listed twice with two URLs. New item, low score (few players open it). The CC-BY lines must stay in the game; a shorter in-game line plus a licences file is fine. DeepSeek's "panel slapped over the title" is the kit's slide-over (RULEBOOK 9.15), not a fault |

## The 6 lore findings (Rey alone)

| Finding | Verdict | Why |
|---|---|---|
| First hour shows little fiction; pull one Beat 1 arc card forward | **Ruled** | The arcs are off until Ryan's read (campaign.gd:44 `arcs_on := false`, RULEBOOK 11.4, story README). And the outline text no longer fits R85 (a new hunter each sector), which the list keeps below the line. Rey read the outlines as ready; they are not |
| 40k echoes in Sunward words | **Ruled**, one part stands | "Crusade" is the ruled faction name (rename_map_final.md:28, RULEBOOK 11.1), chosen in the pass that removed the 40k names (11.2). The spires are the approved Sunward look (R360). "High Nadir" is Eclipse, not Sunward. Left: "Aspect of the X", which Fable lore 9 flagged as a Hades word. One more point on that below-the-line item; Ryan picks |
| Faction wants are invisible in play; add an enemy-want line to the battle intro | **Stands** | The traces show one hail and one contact line per battle, nothing on why the enemy is there. New item, below the line. The line is story text, so it needs Ryan's read (11.4) and must not quote the unapproved outlines |
| Admiral name registers collide | **Wrong** | Knockdown 3 |
| The victory card buries its best line (the lifepod) in the bottom strip | **Stands** | s10 t022. Same card and same fix as the ranked item "Lost: the Cold Reckoning and Lucan Ivers, then the strip says he escaped": put "escaped, wounded" in the card. Hydrogen's "the game breaks its own permadeath promise" is the Ryan pick already on that item. One more point |
| X21 status: rival memory "fixed on paper", dead flags "fixed and verified" | **Wrong** | The memory pools cannot play at all: each sector sends a new hunter and `met` is set every sector (Fable lore 2, confirmed by Neon's referee check). The flag branches sit behind the arcs gate, so nothing a player sees is verified. "Tone holds, do not loosen it" is fair and costs nothing |

## Where Muse disagrees with the list (noted, no score change)

- Rey's art leg calls the flagship pick render "the single best art asset in the pack"; Fable art 12 calls it small and
  flat lit. Both read s10 t001. The ship fills about 40% of the width and the right third below the text is empty. Taste:
  Ryan picks; the item stays where it is.
- Rey's art leg says UI type is "one style, and it works"; the list says seven typefaces and reward cards from another
  game. Rey did not see the front-end set, and t022 against t040 shows two different card styles. The list stands.
- Rey and DeepSeek praise the tip cards and the terrain key. That is praise for having them, not a counter to the
  findings about what the first card says and when cards open.

## What everyone missed (found while checking Muse)

1. **The win card names ranks from the Sunward table for every faction.** campaign_ui.gd:2334 prints "promoted to" plus
   `C.RANKS[...]` (Lieutenant, Commander, Captain, Commodore, Fleet captain). The promotions card two clicks later uses
   `C.rankName` (campaign_ui.gd:2407, campaign.gd:516 to 520), which reads the faction's own ranks: Claw, Fang, Howler
   for Hullbreakers; Spawn-mind, Node, Throat for the Chorus; Glimmer, Glint, Facet for Glasswrights; Shade, Gloam, Umbra
   for Eclipse. So a Chorus captain is "promoted to Commander" and then shown as a "Node". The same shortcut is at
   campaign.gd:2198, where only Chorus and Eclipse get their own rank words. Muse's finding 5 is wrong for the Sunward
   run it looked at and right for four of the other five factions. Read in code, not seen on screen. Fix: use rankName in
   both places. Small, bug.
2. **The win card never says the node's promised reward is the next card.** The map says "Pays Signal of Rook"; the win
   card says nothing about it; the protocol offer follows on its own card. Three outside models concluded the reward was
   never paid, from stills 8 s apart, and a player who clicks fast may not tie the two together either. Fix: one line on
   the win card ("Next: Rook's signal, pick a protocol") and "Signal of Rook" in the head of the protocol card. Small,
   UI. Ties to the Board's open check of RULEBOOK 9.13 (one prize screen) on the reward card item.
3. **On main the battle menu still has a "Reach hatching: on" row.** After R361 the hatching shows only with Z, yet main
   keeps `danger_on := true` (battle.gd:126) and the menu row (battle.gd:4205). A player reads "on" and sees nothing.
   Read, not run: the Board should check what the row now does, and drop it or reword it ("Reach hatching: hold Z").
   This also bears on the hover stutter item, which says the work behind the hatching still runs.
4. **The blocker outline wears the target's colour.** The rocks that block a shot are outlined in the same orange as a
   selection. Two expert legs took them for the enemy ships (knockdown 1). Fix: give blockers the grounded rim R361
   approved for impassable hexes, not the intent colour. Small, UI; belongs with the "9,10" item.
5. **A process gap, not a game fault.** Muse's pictures were a renamed subset that mixes a quick battle with two runs,
   and it missed the front-end and faction sets. Next council: send the pack folder as it is, with its own file names,
   and say in the brief which pictures belong to which run.
