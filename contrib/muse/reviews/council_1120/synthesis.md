# Council audit 1120: Muse seats, Run 1 (blind round) synthesis

Issue 1371. Build judged: playtest build from main 25adec31.
Evidence: the pack stills and the two player-path runs (seed 10,
seed 121), plus the story files for the lore seat. The front-end
screen set (setup, faction desks, settings, help, progression)
failed to capture for this pack, so no leg judged those screens;
findings below cover only what the pack shows. Per the brief, the
Fable folder was not opened in this run.

Seats: blind Rey sat UI/UX, art and lore. The first-time player
seat was sat four times: DeepSeek (14 of 15 pictures; 11_firing
would not attach), Qwen on Qwen3.8-Max (all 15), the Flash seat on
Gemini Hydrogen (14 of 15; 10_pause_menu would not attach; the
picker no longer offers a Flash label, disclosed in its leg), and
Grok, whose seat is empty: grok.com bot-walled the cloud browser
before sign-in, so the brief never reached the model.

## Where the council agrees (two or more legs)

1. Ships do not read at the battle camera. Enemy hulls match the
   asteroids in grey and value (battle_03), the enemy fleet starts
   off-frame (battle_01), Battle 2's debris out-contrasts both
   fleets, and in a brawl the two sides differ only by thin hex
   rings (14_battle2_under_fire). Raised by: blind art 1-3,
   DeepSeek, Hydrogen. Fix at the kit level: a faction-tinted rim
   or running-light row on every hull, strongest on small classes;
   debris one value step behind the actors; tighter default framing
   on the active ship.

2. The bottom ship card lies during the enemy turn. It keeps
   showing the player's spent ship (battle_05, 09_enemy_turn,
   14_battle2_under_fire) while the enemy acts. Raised by: blind
   UI/UX 2, Qwen, Hydrogen. Fix: the card follows the acting ship,
   or dims with a clear "standing by" state.

3. Defeat explains nothing. The defeat card carries a score and a
   strong line, but why the run ended (which ship, which round,
   how close the objective was) lives only in the scrolling log,
   and nothing shows what the run banked. Raised by: blind UI/UX
   9, Qwen, DeepSeek, Hydrogen; the lore leg adds that defeat's
   line is the best writing in the pack, which makes the missing
   recap more visible, not less. Fix: a short cause recap on the
   card (objective state at end, the kill on each hull, banked
   captains and currency) before the flavour line.

4. Victory salvage is thinner than its own fiction. The tip card
   promises strip, scrap, tow and ransom; the buttons offer only
   "Scrap it". The node's promised reward ("Pays: Signal of Rook",
   04_sector_map) never appears on the victory panel. The amounts
   read as bus fare next to a lost ship. Raised by: blind UI/UX 5,
   DeepSeek, Qwen, Hydrogen. Fix: show the gated options greyed
   with their reasons, list the promised node reward with its
   effect, and guarantee one tangible non-credit choice (a module,
   a protocol, a captured fitting) per victory.

5. Promotions are coupons, and the ranks do not agree. Both perk
   choices are numeric nudges; "Promoted to Commander" on the
   victory screen becomes "Captain" on the promotions screen; no
   screen says what a rank grants. A real equipment drop (battery
   loaders, 13_promotions) is buried in the bottom ticker. Raised
   by: Qwen, DeepSeek, Hydrogen. Fix: align the rank titles, one
   line per rank saying what it grants, one perk per promotion
   that adds or changes a named ability, and present salvaged
   modules as loot with an equip prompt.

6. The first decision of the game runs on unexplained words.
   Cores, signals and protocols are load-bearing on the flagship
   pick screen (seed10 t001) and the map (04_sector_map) and are
   defined nowhere a first-hour player reaches; Heat, command
   points and the hunt clock are meters with no visible rule.
   Raised by: blind UI/UX 3, blind lore 6, Qwen, Hydrogen. Fix:
   one plain sentence at the first mention, and let the rival's
   first calling card carry the cores idea attached to a person.

7. Teaching cards park on top of the action. The Engagement legend
   and the ship-up card stack over the enemy flank in
   08_tip_card_legend, and the rewards tip lands beside the salvage
   buttons at the moment of clicking. Raised by: Qwen, Hydrogen
   (the blind UI/UX leg praises the cards' content and their
   permanent off switch; the fight is placement, not existence).
   Fix: dock first-run tips to an edge, one card at a time, or fire
   them between turns.

8. "No ready gun can reach it" nags and does not teach. It repeats
   (four times in 07_enemy_clicked), sits centre-screen, survives
   the tooltip closing, and never says where a gun WOULD bear.
   Raised by: Qwen, Hydrogen. Fix: state it once in the target
   card, and highlight the hexes or range rings from which the
   selected guns would bear.

9. Blocked shots cite coordinates the grid never shows. "Blocked
   by the asteroid at 9,10" is excellent intent (the blind UI/UX
   leg calls the explanation the best line in the card) but the
   hexes carry no coordinates, so the player cannot act on it.
   Raised by: DeepSeek, Qwen, Hydrogen. Fix: highlight the exact
   obstructing asteroid when aiming; keep the words.

10. The arc letters P, S and F are never defined on screen, and
    the icon-only ability row reads like more guns. Raised by:
    DeepSeek, Qwen, Hydrogen. Fix: label the arcs once in the
    first battle's teaching sequence and give the ability row
    tooltips.

11. The sector map's icon language is closed at the moment of
    planning. Node glyphs carry no on-map meaning, the Map key
    sits shut, and the route web reads as a spiderweb until
    hovered. Raised by: blind UI/UX 4, Qwen, DeepSeek. Fix: a
    one-line legend under the map, hover labels for every node
    type, and the available forward paths lit in a distinct
    colour. (The art leg adds, as a taste call for Ryan: the map
    is the plainest surface in the game next to the pick screen's
    richness.)

12. The pause menu mixes session toggles, display options and
    quit actions in one flat list of 18 rows, and the Threat map
    (the tool that answers "where can I be shot from") defaults
    off inside it. Raised by: blind UI/UX 8, Qwen. Fix: group
    under Gameplay, Display and Game headings; default Threat map
    and Reach hatching on for the first run, as labelled HUD
    toggles.

## Single-leg findings the chair keeps

- Round 1 is an empty approach turn: at battle start every enemy
  is out of range (21/5, 21/7 in 07_enemy_clicked), so the first
  round is movement only. Hydrogen; the blind UI/UX leg's
  off-frame enemy fleet is the same wound from the other side.
  Proposed fix from the leg: tighten deployment so something can
  threaten on round 1.
- Firing's tooltip covers the beam it is celebrating (11_firing):
  offset the combat tooltip to the side of the target hex.
  Hydrogen.
- The drift skip on every jump is manual each time (04): remember
  it per save. Qwen.
- Enemy turns are watch-only, with no intent shown for the next
  round: paint planned targets during their turn, Into the Breach
  style. Qwen. (Every leg praises the intent warning that exists
  on the player's own ship; this asks for the same respect one
  step further.)
- Title screen has no hero ship (blind art 4, taste, marked for
  Ryan), sky sequencing across a run's first two battles is
  uncontrolled (blind art 5), and weapon fire carries no faction
  tint in any frame (blind art 6): tint at the effect level,
  keeping the white core.
- Credits are small dense print with full URLs in body text
  (blind UI/UX 10, blind art 8, DeepSeek): larger body size, short
  link names, full URLs in a licences file.

## Lore seat findings (blind Rey only; no second leg sits lore)

- The first hour shows a fraction of the fiction that exists: one
  admiral line per battle, a dossier, a hunt clock. Pull one Beat
  1 arc card forward so a faction want lands inside the first
  hour.
- 40k echoes persist in the Sunward surface vocabulary (Aspect of
  the Ram/Spear/Admiral, crusade, High Nadir, cathedral spires).
  Rename one of the three first-hour terms into the game's own
  register.
- Faction wants from outlines.md are invisible in play: add an
  enemy-want line to the battle intro card, per faction.
- Admiral name registers collide (Vex, Essvane, Steiner): state a
  naming rule in the story README and pass the 24 names over it.
- The victory screen buries its best line (the lifepod captain) in
  the bottom ticker: promote one fiction line into the card body,
  as defeat already does.
- X21 status: dead flag branches fixed and verified; rival memory
  pools exist on paper but no pack run reaches a rematch, so the
  memory system is unproven in play; Chorus short-line discipline
  intact. Tone holds throughout; do not loosen it.

## Raised but rested on pack artifacts (not findings)

- The build stamp in the corner of the stills is the pack's
  capture scaffolding, not shipped UI (raised by Qwen and
  Hydrogen; the chair does not count it).
- Fleet names change between picture sets because the evidence
  mixes two runs and a quick battle (raised as confusion by Qwen
  and Hydrogen). The underlying ask survives in weaker form: the
  battle HUD shows no run or mode context. Recorded as a note,
  not a finding.
- DeepSeek's guess that a single bad roll wiped the fleet between
  pictures 14 and 15 rests on the same mix; 14 and 15 are
  different runs. Not counted.

## What every leg praised (protect these)

- The move preview: cost, guns bearing, facing keys, "nothing
  moves yet". Unanimous, all four player legs plus blind UI/UX.
- Transparent gunnery maths: hit chance, expected damage, shield
  pools and blockers explained before committing. Unanimous.
- The aspect pick: three genuinely different ways to play from
  the first screen. Unanimous.
- Captain continuity: the lifepod, promotions that persist across
  hulls, named consequences. Unanimous; the fiction promise on
  the title screen is paid here, and one leg (Hydrogen) flags
  that the title wording reads as hard permadeath against it.
  Chair's read: keep the line, sharpen the wording so lifepods
  are inside the promise, not an exception to it.
- The map printing risk and reward per node before the click
  (Qwen, Hydrogen), and the enemy-intent warning on the player's
  ship (Qwen, Hydrogen, blind legs).
- Art: the flagship pick render, the pink nebula Battle 2 sky,
  the gas giants, and a consistent selection language (orange
  intent, teal friendlies, purple enemy) across battle, map and
  menus.

## The player legs' verdicts

- DeepSeek: thumbs up, with caveats.
- Qwen: recommended.
- Hydrogen (Flash seat): thumbs down for now, flips on UI
  legibility and reward punch.
- Grok: seat empty (bot wall).

The spread is the finding in miniature: the tactics core is
already recommendable; the first-hour surfaces around it (ship
legibility, the enemy turn, defeat and salvage) are what a new
player bounces off.

## Chair's fix order

1. Ship legibility at the battle camera (kit-level rim and
   running lights, debris value step, framing).
2. The enemy-turn card follows the acting ship.
3. Defeat recap and banked-run summary on the defeat card.
4. Salvage: gated options shown with reasons, promised node
   reward listed, one tangible non-credit choice.
5. Promotion ranks aligned and explained; one named-ability perk
   per promotion; salvaged modules presented as loot.
6. First-mention definitions for cores, signals, protocols,
   Heat; one Sunward term renamed; enemy-want line on the battle
   intro.
7. Tip placement (dock, one at a time) and the reach hint (where
   guns would bear; highlight the blocking rock).
8. Victory card carries one fiction line in its body.

Findings only, per the brief: nothing outside this folder was
edited, and no sound work is proposed. Refs #1343.
