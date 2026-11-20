# Blind Rey leg: graphic design and art seat, council audit 1120

Build judged: playtest build from main 25adec31. Evidence: the pack
stills and the two player-path runs. Stage notes per the pack: the
player fleets are Sunward (Vigilant Ash V16_37, Everwatch V15_37,
Cold Reckoning V14_23, all published revisions); the Chorus ships in
this build are a PC snapshot mid rebuild and no Chorus, Eclipse or
Glasswright battle appears in the pack, so faction-family findings
cover Sunward, Hegemony and the Ashfall Hullbreakers only. Ryan's
taste calls in FINDINGS (nebula colours, battle light, finishes) are
treated as settled; nothing here reopens one without marking it.

## Findings, worst first

1. Enemy ships read as asteroids at the battle camera. In
   battle_03_3_enemy_clicked the two Hegemony pickets are the same
   grey, same value and near the same silhouette family as the
   asteroid field around them; only the selection hex says "ship".
   In battle_01 the whole enemy fleet is a rumour off-frame. The
   Hegemony's identity (registry neat, synchronized) never gets a
   chance to read because the hulls vanish into the scenery. This is
   a shared-kit problem, not a per-ship one: enemy hulls need a value
   or rim treatment that separates hull from rock at camera 170
   before any close-up saves them. Fix at the kit level: a faint
   faction-tinted rim or running-light row on every hull, strongest
   on the small classes that suffer most.

2. The player's own ships are also very small at the default battle
   framing. In battle_01 and across both runs' early frames the
   Sunward hulls are a few dozen pixels inside their selection rings;
   the rings, hexes and name labels carry the read, not the ships.
   The flagship render on the pick screen (seed10 t001) proves the
   models hold up beautifully at size; the battle camera rarely lets
   them. Fix: a slightly tighter default framing on the active ship
   (the cinematic movement mode already visits ships closely), so the
   fleet reads as ships first and tokens second.

3. Battle 2's debris field competes with the fleets. In the seed 10
   and seed 121 Battle 2 frames the tan debris clusters are the
   highest-contrast objects on screen, higher than either fleet, and
   in seed121's late frames the flagship under fire is found by its
   red ring, not by the ship. Debris is terrain and should sit one
   value step behind the actors. Fix: drop debris albedo contrast a
   step in the pink nebula scenes specifically, where pink cloud,
   tan rock and grey hull stack into one mid-tone.

4. The title screen's right half promises a game the menu side does
   not show. title_1920x1080: a lovely nebula and asteroid field,
   and two tiny blue ship silhouettes mid-frame that most players
   will never notice. No hero ship. For a game whose fantasy is
   commanding beautiful fleets, the first impression is a menu over
   a screensaver. This is taste: marked "Ryan picks". Fix if he
   agrees: one hero hull (the flagship of the player's last or
   starter fleet) drifting in the right field at readable size.

5. Sky variety between the two Battle 1s is thinner than the sector
   fiction suggests. Seed 10's Battle 1 is a rich blue nebula with a
   banded rust planet; seed 121's Battle 1 is a near-empty starfield
   with a pale gas giant. Both are handsome; the empty one makes the
   hex board and UI carry the whole frame, and next to Battle 2's
   pink nebula it reads as the plain option. Not a defect per sky;
   the finding is sequencing: a new player's first two battles can
   be plain-then-spectacular or the reverse, and nothing in the run
   structure controls which. Fix: guarantee one featured sky in the
   first two battles of a run.

6. Weapon fire is legible but generic in the frames that show it.
   The seed 10 beam shot (t013 area) is a clean white lance, bright
   and readable against the blue sky; the seed 121 autocannon fire
   is a similar white streak. Against the pink nebula the same
   white reads weaker. No faction colour separates Sunward fire
   from Hullbreaker fire in any frame in the pack. If faction
   weapon colour is a rule elsewhere this leg cannot see it in
   evidence; on these frames, fire is fire. Fix: tint by faction
   at the effect level (shared kit change), keeping the white core.

7. The sector map art undersells its fiction. seed10 t003 and
   seed121 t003: the node web is clean and readable, but the nodes
   are abstract glyphs over a starfield, with one small planet at
   the corner. Next to the flagship pick screen's richness, the map
   (the screen a player returns to most) is the plainest surface in
   the game. Taste: "Ryan picks". Fix if he agrees: give held and
   contested worlds the planet treatment the corner world gets, at
   node scale.

8. UI type and game art are one style, and it works, with one
   exception: the credits screen (title_credits) drops to dense
   small print that belongs to a licence file, not the game's
   typographic voice. Everything else (condensed display type,
   orange accent, black panels) is consistent from title to defeat
   card, which is genuinely rare at this stage and worth protecting.

## Good, keep

- The flagship pick render (seed10 t001): the Vigil-class hull at
  hero size, warm key light, cathedral spires reading instantly as
  Sunward. The single best art asset in the pack.
- The pink nebula Battle 2 sky: dramatic, faction-neutral, and the
  teal storm and rose cloud separation reads clearly at distance.
- The defeat and victory cards' restraint: black panels, one strong
  line, no confetti. The tone is the game's.
- Selection language is consistent everywhere: orange for the
  player's intent, teal rings for friendlies, purple hexes for the
  enemy, in battle, map and menus alike.
- The gas giants. Both planets (rust banded, pale banded) are
  gorgeous and do heavy lifting for scale in every frame they join.
