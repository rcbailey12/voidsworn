# First-time player leg: Qwen (Qwen3.8-Max)

Model gate: selector Qwen3.8-Max verified before each of the three
sends, header after. All 15 pack pictures received (three turns of
five). Chat: https://chat.qwen.ai/c/1307b12d-e6ac-4255-a222-e7acbb8a865d
Chair notes: two items rest on pack artifacts, not the game, and are
flagged where they appear: the "build-stamp overlay" is the capture
stamp the Board burns into pack pictures, and the "two runs
interleaved" confusion comes from the evidence set mixing two runs.
Neither is counted against the game in the synthesis.

## 1. Fun

- 03_flagship_pick: three aspects, three playstyles, one line each.
  Pattern: players praise Hades' weapon aspects because each changes
  how you play, not just numbers. "If the flagship falls, it passes
  to your next-largest ship" removes the fear of committing.
- 04_sector_map: the jump is a decision with the payoff printed
  ("Pays: Signal of Rook"), difficulty pips, and a modifier ("war
  zone: fights pay 20% more"). Pattern: FTL and Slay the Spire
  players praise maps where every node tells you risk and reward
  before you click. The nemesis hunt clock (0 of 4) is visible
  pressure, like FTL's pursuing fleet.
- 05_battle_start: "The enemy fleet is focusing its fire on this
  ship" on round 1 tells me what is about to hit me. Pattern: Into
  the Breach reviews single out showing enemy intent.
- 06_move_preview: hovering a hex answers "what will this do before
  I take it": movement cost, guns bearing, Q/E for facing, and
  "nothing moves yet" so no misclick deaths. Pattern: Battletech
  players love firing-solution previews.
- 07_enemy_clicked: the inspector shows prow shield pool, "this side
  catches 22", armour, evasion, exact range math and which asteroids
  block, by name. Pattern: Star Wars Armada's side arcs only feel
  fair when a tool exposes them; here the failure is explained.
- 11_firing: 82% to hit, expected shield and hull damage, then a
  confirm click, then a letterboxed beam. Pattern: XCOM's hit-roll
  is the drama players quote; the confirm step keeps it drama, not
  wallpaper.
- 12_victory_salvage: per-wreck choices with keyed shortcuts, and
  the lifepod line turns a lost captain into continuity. Pattern:
  FTL's scrap loop plus Hades' "death feeds the run".
- 13_promotions: perks stay with the captain even on a new ship, so
  the roster becomes a story. Pattern: XCOM soldier progression.

## 2. Not fun

- 09_enemy_turn: enemy turns are a watch-only cutscene; nothing
  tells me what they will target next round. Fix: paint enemy intent
  during their turn, Into the Breach style, and auto-speed enemy
  movement after the first battle.
- 06_move_preview: plan-then-resolve plus cinematic sailing makes
  every round paperwork. Fix: keep planning, add instant-resolve
  with undo, and do not default Movement: cinematic past battle 1.
- 07_enemy_clicked: it says "no ready gun can reach it" four times
  and never says what would. Fix: highlight the hexes my guns would
  bear from, or show per-weapon range rings on hover.
- 08_tip_card_legend: tutorial cards park on top of the enemy fleet
  exactly when I am trying to read it. Fix: dock first-run tips to
  an edge or fire them between turns; make the terrain legend a
  hold-key overlay.
- 10_pause_menu: the Threat map (the tool that answers "where can I
  be shot from") is off by default, buried in a list that reads like
  debug options. Fix: default Threat map and Reach hatching on for
  run one, as labelled HUD toggles with one-line explanations.
- 14_battle2_under_fire: during the enemy turn the big card still
  shows my spent ship staring at me with empty bars. Fix: feature
  the acting enemy ship in the card slot, or dim my card with a
  "standing by" tag.
- 15_defeat: I lost and the game recited poetry; nothing says
  whether I failed the relay, the fleet, or a round limit. Fix: a
  three-line cause recap (objective state at end, damage per round,
  the kill shot on each hull) before the flavour quote.
- 04_sector_map: every jump opens with a drift I have to click away.
  Fix: remember skip per save or auto-skip after the first sector.
- 12_victory_salvage: the moment I want to click my loot, a
  paragraph about command points parks beside it. Fix: collapse the
  rewards tip to one line after the first victory; per-option detail
  into tooltips.

## 3. Not rewarding

- 12_victory_salvage: "+44 credits and +36 scrap next to 'Lost: the
  Cold Reckoning and Lucan Ivers' is bus fare for a burial." Fix:
  show one visible sink on this screen (a refit offer with price
  and effect), the way FTL shows upgrade costs, so credits read as
  a step.
- 12_victory_salvage and 04_sector_map: the node promised "Signal of
  Rook"; the victory panel never mentions it. Fix: list the promised
  node reward on the victory panel with a one-line effect.
- 13_promotions: both perks are numeric coupons ("ignore the first
  2 hexes of penalty", "cooldowns -1"). "My captain's promotion was
  a discount voucher." Fix: guarantee one perk per promotion that
  adds or changes a named ability, previewed in battle terms.
- 12_victory_salvage: "Promoted to Commander" never says what a
  Commander does. Fix: one line under the rank listing what it
  grants.
- 15_defeat: the run ends with a quote and Continue; no banked
  protocols, kept captains, or currency shown. "My death paid
  nothing; Hades this is not." Fix: before Continue, show what the
  run banked.

## 4. Confusing

- 04: node glyphs carry no on-map meaning; the Map key sits closed.
- 04/05/14: meters with no visible rule: Command points 6/10, Hunt
  clock 0 of 4, Heat 0 (no clue at all).
- 05/09/14: the ability row (Brace, Focus fire, Fire for effect,
  turn arrows) is icon-only with no tooltips visible, while weapon
  hotkeys P/S/F sit beside it reading like more guns.
- 07: the inspector cites "the asteroid at 9,10" but the grid shows
  no coordinates, so the clue cannot be acted on.
- 06: when planned moves actually execute is never stated; "nothing
  moves yet" leaves me afraid to end a ship mid-plan.
- 12: "Salvage one wreck" above three wrecks each with a scrap key:
  does scrapping count as the one salvage? Unsayable from the
  screen.
- 15: "Continue" leads somewhere unknown.
- 14 vs 05: Retreat appears in battle 2's top bar but not battle
  1's; when fleeing is allowed is invisible.
- 01: "New run / Quick battle / Career / Progression": four doors,
  no hint which is the campaign loop for a first-timer.

## 5. Review

Recommended. "First hour: an aspect pick that changes play, a jump
map that prints its payoffs, and gunnery that shows hit odds and
expected damage before I commit, planning feels like Into the Breach
with ship flanks. Salvage and captain perks hint at a real loop. But
enemy turns are watch-only waits, tips park over the fleet, and my
defeat ended in poetry, not a recap. Fix pace and the loss screen
and this is something special."
