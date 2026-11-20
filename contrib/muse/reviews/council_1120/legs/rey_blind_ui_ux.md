# Blind Rey leg: UI/UX seat, council audit 1120

Build judged: playtest build from main 25adec31. Evidence: the pack
stills and the two player-path runs (seed 10, seed 121). Scope limit,
stated once: the front-end screen set (setup, faction desks, settings,
help, progression) failed to capture for this pack, so this leg judges
the title, credits, flagship pick, sector map, battle screen, victory,
promotions and defeat screens only. The approved designs in
docs/playbooks/screens.md are treated as the baseline; nothing below
reopens a Ryan pick without saying so.

## Findings, worst first

1. The enemy fleet is not visible at battle start. In
   PT25adec3_battle_01_1_battle_start the player's three ships sit
   circled at left while the five Hegemony ships are off-frame right;
   first contact is a log line ("Contact: Hegemony Navy, 5 ships on
   the scanners"). In battle_03_3_enemy_clicked the two pickets the
   player can click read as grey rocks among the asteroids until the
   orange hex outlines them. A new player's first tactical question,
   "where are they and what are they", has no visual answer on the
   opening screen. Fix: frame both fleets at battle start (or pan to
   the enemy line once on entry), and give unselected enemy ships a
   persistent marker that survives against asteroid grey.

2. The bottom ship card goes stale during the enemy turn. In
   battle_05_6_enemy_turn the card still shows the player's RESOLVE OF
   THE REACH with every gun "Out" while the camera watches the enemy
   activate, and the line "The enemy fleet is focusing its fire on
   this ship" persists from an earlier state. The card should either
   follow the acting ship or blank to a clear "enemy acting" state;
   as it stands it teaches the player to stop trusting the panel.

3. The flagship pick screen front-loads unexplained jargon at the
   first decision of the game. seed10 t001 ("CHOOSE ITS ASPECT") ends
   with "Cores in range: V-2 Vyre, the Storm Queen, R-5 Rook, the
   Breaker, A-4 Astra, the Silent Star, K-1 Kharon, the Unbent. Win
   battles carrying their signal to earn their protocols." Cores,
   signals and protocols are none of them defined on this screen or
   the title's How to play entry point visible in the pack. Fix: one
   plain sentence ("Cores are rival admirals. Beat them while their
   signal is in range and you earn their protocol, a permanent bonus")
   or move the line behind the aspect pick.

4. The sector map's node icons are unexplained on the map itself.
   seed10 t003 shows diamonds, squares, circled crosses and red
   markers with only a "Map key" link at top right to decode them.
   The left panel explains the selected node well, but route planning
   (the map's whole job) needs the icon language at a glance. Fix: a
   one-line legend under the map or icon labels on hover for every
   node type, not just the selected one.

5. Victory salvage wording fights its own buttons. seed10 t022 heads
   the choice "Salvage one wreck" and the tip card explains strip,
   scrap, tow and ransom, but the only buttons offered are "Scrap it"
   (the tow and ransom options are faction or limit gated and the
   screen never says why they are absent). A first-time player reads
   the tip, looks for the other verbs, and finds none. Fix: show the
   unavailable options greyed with the reason ("Tow: fly with the
   Hullbreakers"), which also teaches the faction fantasy for free.

6. Information density in the target card outruns its teaching.
   battle_03_3_enemy_clicked gives hull, armour, evasion, shield pool
   and facing, per-gun range fractions and a blocked-by-asteroid
   explanation in one card. The blocked line is excellent; the rest
   arrives all at once in Battle 1 with no layering. Fix: keep the
   card, but let the first battle's teaching sequence point at it
   once ("this card tells you why a shot cannot be taken"), rather
   than leaving it to be discovered mid-fight.

7. Two different "ships to act" counters can disagree in feel. The
   top-left reads "3 of 3 ships to act" while the bottom strip lists
   the fleet with hull numbers (85 Oathkeeper, 50) partly cut off at
   the panel edge in battle_01. The strip's third ship value is
   clipped by the frame in several stills. Fix: let the strip scroll
   or shrink to fit; a clipped number reads as a bug.

8. The pause menu is a settings page wearing a menu's clothes.
   battle_06_7_menu_focus lists 18 rows mixing session toggles
   (Speed, Movement, Cut-ins) with display and accessibility options
   and quit actions, all at one level. It works, and the focus state
   is clear, but a player hunting "UI scale" mid-battle scrolls past
   gameplay toggles to find it. Fix: group under three headings
   (Gameplay, Display, Game) without adding a screen.

9. Defeat gives no "what beat you" beyond the log. seed121 t040's
   DEFEAT card carries the score and a strong admiral line, but the
   reason the relay defence failed (which ship, which round) lives
   only in the scrolling log at bottom right. Fix: one line on the
   card ("Bright Censure was destroyed in round 7 holding the
   relay"), which the log already knows.

10. Credits text is small and dense at 1080p (title_credits still):
    full URLs in body text at caption size. Attribution is complete
    and correct; this is a legibility note only. Fix: larger body
    size, URLs shortened to the work's page name with the full link
    in a licences file.

## Good, keep

- The move preview tooltip (battle_02): movement cost, guns bearing
  from the hovered hex, facing keys, and "nothing moves yet". This is
  the single best teaching surface in the pack.
- The Engagement legend (battle_04) explains the flee rule and every
  terrain effect in four lines, in the battle, where it is needed.
- Teaching cards with a permanent "Turn off all tips" escape on every
  card, and tips that teach the screen the player is looking at.
- The disabled launch button on the aspect screen states what it is
  waiting for ("Pick an aspect to launch") instead of sitting mute.
- The defeat card's admiral line and the victory screen's named
  captain consequences (a lost captain escapes in a lifepod and takes
  the next hull) make results screens worth reading.
