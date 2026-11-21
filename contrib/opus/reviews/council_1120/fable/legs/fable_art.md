# Council 1120, graphic design and art seat: Fable leg (blind round)

Build 25adec31, stage of every picture: installed in game, playtest build. Picture names are short forms: `stills/battle_01`
is pack/stills/PT25adec3_battle_01_1_battle_start.jpg, `s10 t007` is pack/run_seed10/PT25adec3_seed10_t007.jpg, `s121 t028`
is pack/run_seed121/PT25adec3_seed121_t028.jpg.

What I looked at: all 8 stills; seed 10 frames t001 to t005, then every odd frame to t037, plus t016, t020, t022, t034, t038;
seed 121 t001, every even frame t002 to t040, plus t037. Read: factions.md, scale.md, ships.md section 0, FINDINGS R319 to
R360, and the headings and readability tables of the two Neon audits.

Limits of this leg, said once so nobody has to find them:

- **Only three factions are in the pack**: Sunward (player), Hegemony (Battle 1 enemy), Hullbreakers (Battle 2 enemy). There
  is no picture of a Chorus, Glasswright or Eclipse ship, so "do the six factions read as six families" cannot be answered
  from this pack. The extra stills pack.md item 4 promised (one battle per faction, map per sector, shop, event, loss, win)
  are not here, and the front-end set failed to capture. I judge nothing I did not see.
- **Ship stages.** Sunward: the pack names V14_23 (Sunward S9) as matching a publish receipt, so the Vigil cruiser is judged
  as an approved revision, installed in game. The pack does not say which revision the Harrow destroyer, Warden frigate,
  Hegemony picket and Cordon destroyer, or Hullbreaker raider and gutship are. H4_11 is a PC snapshot, not an approved
  revision, and may be one of the Hegemony hulls shown: I do not judge any Hegemony hull's surface as finished art. Chorus
  ships (B19_11, B20_11, B21_11) are mid rebuild and do not appear in any frame I saw.
- **The run frames are compressed video stills** at 720 px. Blocky frames (s10 t033, s121 t024) are the encoder caught in a
  camera cut, not the game. I do not judge texture detail from run frames, only shape, value, colour and layout.
- Rulings I checked and do not contest: no dark scrim under the board (R344, scale.md section 5), big clouds with a drawn
  hazard edge (R247, R344), one rose nebula (R353), neutral battle light (R351), gold wordmark (R327), asteroid surface pass
  A and debris A (R359), Sunward spire size and ember (R331, R347, R360), new hulls only (R323), fixes land in shared kits
  (R333). Where a finding touches one I say so.

## Findings, worst first

### 1. The ships are the smallest, darkest and least coloured thing in the battle picture

Pictures: `stills/battle_01`, `s10 t007`, `s10 t011`, `s10 t020`, `s121 t012`, `s121 t016`.

At the default battle view the Sunward flagship is a dark grey smudge about 50 px long inside a ring (`stills/battle_01`:
the ring and the name label are what you find, not the hull). In the same frame the rocks are up to 90 px, lighter and
sharper, and the planet fills a quarter of the screen. In `s10 t011` and `s10 t020` three Sunward ships are dark dashes
inside teal rings on a mid blue-grey sky; hull and sky are close in value. factions.md sets the test: "one clear silhouette,
one main colour, one accent light" at camera 170. No frame at the battle camera shows a Sunward accent light: no ember spire,
no engine glow, no frost-white marking. Friend or foe is read from ring colour (teal, violet) and nothing else. The HUD
silhouette of the ship (about 150 px, `stills/battle_01`) is three times the size of the ship it stands for.

How much a player notices: every turn of every battle. This is the first thing an art director would send back: the game's
most expensive art, the ships, does not show in the main view.

Fix (shared, lands on every ship; no scrim, R344 stands): (a) in the shared ship look (godot/render/look.gd and look_rim.gd)
give every faction a rim light and an emissive floor that grow with camera distance, so each hull keeps a lit edge and its
one accent colour at camera 170 whatever the sky; (b) a minimum on-screen length for the ship up, by a slightly tighter
default framing on the active ship, not by scaling models (scale.md stays). Proof: one still per faction at camera 170 over
the three brightest skies, hull edge clearly lighter than the sky behind it and the accent visible. This is new evidence on
the backdrop audit's R2 (dark hulls blend into bright skies), whose own fix was the scrim Ryan ruled out; the fix has to move
to the ship side.

### 2. Asteroids are the brightest, most repeated thing on screen and they sit on top of the ships

Pictures: `s10 t025`, `s10 t027`, `s10 t029`, `s10 t031`, `s10 t037`, `s121 t028`, `s121 t034`, `s121 t036`.

Three separate problems, all in one object:

- **Value.** The tan rocks are lighter than every ship and every sky they sit on (`s10 t029`: the right third of the frame
  is a pale rubble wall; the flagship behind it is a dark line). The eye goes to rocks first.
- **Repeats.** `s10 t031` and `s10 t037` show a row of five clumps along the bottom that are plainly the same clump, same
  size, same turn, evenly spaced like tiles. `s10 t025` shows the field as a carpet of identical pieces.
- **Two rock looks.** `stills/battle_01` has grey, chiselled, sharp rocks; both runs have soft tan sandstone clumps. They do
  not look like the same game.
- In the close-up cut-ins rocks float between the camera and the ship being shot (`s121 t028`, `s121 t034`: a rock covers
  the middle of the flagship).

How much: every battle with an asteroid field, which is both Battle 2s here.

Fix: R359 already picked asteroid pass A (issue 1361: surface, rock to rock colour and tone, crisper cracks; shapes kept).
This adds three done-when lines to that job rather than a new one: no rock lighter than the lightest hull in the same frame
at camera 170; each blocker hex takes a random turn, scale and library pick so no two neighbours match; one rock family
(pick grey or tan: Ryan picks). Separately, cut-ins hide or fade rocks that sit between camera and subject. All shared world
code, one change for every map.

### 3. A square white lattice is drawn over the hex board and reads as a debug wireframe

Pictures: `s10 t031` (worst: it fills half the screen), `s10 t027`, `s10 t011` (right edge), `stills/battle_01`,
`stills/battle_03` (lower right).

A fine white square grid lies over large parts of the board, on top of the hex grid, at the same brightness. Two grids of
different geometry in one plane. I take it to be the reach hatching (godot/scenes/battle/battle.gd:3066, `danger_on` default
true, "Reach hatching: on" in `stills/battle_06`); if it is something else it is on screen all the same. Nothing about it
says "enemy guns reach here": it is not in a danger colour, it does not follow hex shapes, and its bands (1, 2, 3 enemies)
cannot be told apart in any frame. To a new player it looks like a missing texture.

How much: every player turn in the move step, default settings.

Fix (shared board code): draw reach as a fill or diagonal hatch inside each hex, clipped to the hex, in one warm danger hue
with three clear steps of strength, well under the hex line value. Ryan picks the look from a three-option sheet.

### 4. The hex lines are heavier than the ships, and in close-ups they become fat white bars

Pictures: `s10 t021`, `s10 t016`, `s10 t013`, `s10 t009`, `s121 t028`, `s121 t038`.

On the player's turn the whole board is drawn in bright blue-white lines (`s10 t009`). In the cut-ins the lines scale with
the world, so they are 6 to 8 px wide with blobby three-way joints (`s10 t016`, `s10 t021`), and run straight through the
hull the shot is about (`s121 t038`). The backdrop audit's R5 covered the far zoom ("board-game table"); this is the near
end, and it is the same R70 problem: the plate under the ships comes back.

How much: every cut-in (every lance and torpedo by default), and every player turn.

Fix (shared, godot/world/board_look.gd and the grid shader): constant screen-space line width; hexes outside the active
ship's move range drop to about a third of the strength; in cut-ins the grid fades to a hint and only the two hexes involved
keep an outline.

### 5. Close-up cut-ins put rings, brackets and labels on the ship instead of showing the ship

Pictures: `s121 t028`, `s121 t034`, `s121 t038`, `s10 t035`, `s10 t016`.

The cut-in is the one moment the ship art fills the screen. In `s121 t034` the flagship carries a red ring, a teal ring, a
white arc glyph across its middle, a second teal ring behind and a name label; the Hullbreakers beside it carry violet
brackets and a white ring. In `s10 t035` two rings overlap over two friendly ships and a tooltip covers the target. The
Sunward hull under all this is unlit dark grey with no ember showing; the only colour in frame is Hullbreaker rust.

How much: every key shot; these are the frames a player would screenshot.

Fix (shared cut-in code): during a cut-in hide selection rings, brackets, arc glyphs and the tooltip (the target card in
the HUD already carries the numbers), keep one thin marker on the target, and add a key light on the two ships involved.
Do not judge the Sunward hull surface from these frames (video stills); the lighting and clutter are the finding.

### 6. One colour means several things, and the nebula legend swatch is the wrong colour

Pictures: `stills/battle_04` (legend), `stills/battle_03`, `stills/battle_05`, `s10 t029`, `s121 t028`, `s121 t030`.

- The Engagement legend shows Nebula with a **violet** swatch (`stills/battle_04`); the nebula on the board is rose (R353,
  same frame). The swatch was not updated with the ruling.
- **Violet** is also the enemy bracket for Hegemony (`stills/battle_05`) and for Hullbreakers (`s10 t029`), and it is
  Eclipse's faction colour. Hegemony's own colour is blue; in `stills/battle_05` a pale Navy hull sits in violet brackets.
- **Orange** is the selected-ship ring, the action button, blocked asteroid hexes (`stills/battle_03`), warning text, the
  Sunward ember and close to the rock colour. The target ring is a red-orange a shade away (`s121 t028`).
- The hazard edge around the storm patch is the same pale tan as the firing arc lines and the rocks (`s121 t030`).

How much: mostly felt as "busy" rather than named; the legend mismatch is a plain error a careful player sees in Battle 1.

Fix (shared palette, one table): rose swatch for nebula now; then one enemy marker colour that no faction owns (a red, kept
apart from the orange by value), orange kept for "yours and active" only, blocked hexes in a neutral. Ryan picks from a
palette sheet.

### 7. The title screen shows none of the game

Picture: `stills/title_1920x1080`.

The wordmark, tagline and orange button are good (kept below). The picture beside them is a soft violet nebula, a dozen grey
pebbles and two tiny blue specks that read as stray pixels. No ship, no fleet, no sun, hollow or otherwise. The left 40
percent is flat black. Nothing tells a new player this is a fleet game with six strange navies.

How much: the first ten seconds of every session; it sets the bar for everything after.

Fix: put one thing from the game in the right-hand field: the accepted Sunward flagship (S8) under way with its ember
spires, or the Hollow Sun itself as a dark disc with a rim. Gold wordmark stays (R327). Ryan picks which, from two mock-ups.

### 8. Too many typefaces, and the same word is set three ways

Pictures: `stills/title_credits_1920x1080`, `s10 t022`, `s10 t037`, `s10 t038`, `s121 t040`, `s10 t002`, `s121 t020`.

The credits name seven faces: Michroma, Oxanium, Big Shoulders Display, Barlow, Barlow Semi Condensed, Azeret Mono and Chakra
Petch. On screen they do not divide the work cleanly:

- "VICTORY" is a wide squared face on the reward card (`s10 t022`), tall condensed orange caps with a dark outline over the
  board (`s10 t037`), and "DEFEAT" is tall condensed white on a black box (`s121 t040`).
- On one screen (`s10 t022`) the card header "VICTORY" is the wide face and the tip header "REWARDS" beside it is the
  condensed face.
- "PROMOTIONS" (`s10 t038`) uses the wide face; every battle header uses the condensed one.

How much: nobody names it, everybody feels "two UI kits". The battle HUD and the title look designed; the cards between
battles look like another project.

Fix (shared theme, godot/ui/theme): three jobs, three faces. Big Shoulders for every header, Barlow for body, Azeret Mono
for numbers; Michroma for the wordmark only. Retire Oxanium and Chakra Petch from headers. One theme edit lands everywhere.

### 9. "Preparing the sector..." is a placeholder screen, shown at the start of every run

Pictures: `s10 t002`, `s121 t002`, against `s121 t020`.

White text in the engine's default font, sentence case with three dots, on plain near-black, no art. Its sibling
"PREPARING THE BATTLE" (`s121 t020`) is in the game's condensed caps on a warmer black. The code agrees: the label in
godot/main/load_screen.gd:21 sets text and size and never takes the theme font; the battle one passes `font_name`
(godot/ui/battle/hud.gd:1280). Both are bare.

How much: every run, straight after the flagship pick, for several seconds.

Fix: one shared load cover for both: theme face, same wording style, and one still behind it (the sector's planet or the
faction mark). Small job, shared.

### 10. The reward and promotion screens are a small grey card on an empty black screen

Pictures: `s10 t022`, `s10 t038`, `s121 t018`.

Winning a battle leads to a card about 490 px wide in the middle of a 1280 px screen, the map dimmed to nothing behind it.
No wreck, no captured hull, no captain portrait, no ship, though the text is about exactly those things ("Cordon destroyer
... blown apart by the Everwatch"). The card's panel is a green-tinted grey with a thin chamfered outline, unlike the black
and orange of the battle HUD. The help line under "Salvage one wreck" is dark grey on near-black and hard to read
(`s121 t018`). The promotion card (`s10 t038`) is smaller still and has more empty screen.

How much: after every battle. This is where a roguelite pays the player, and it is the plainest screen in the pack.

Fix: use the screen. Wreck or hull render beside each salvage row (the fleet strip silhouettes already exist as a floor),
the captain's name with a portrait or rank mark on promotions, card built from the same panel kit and palette as the HUD.
Shared card kit, so events, shops and yards follow.

### 11. Floating labels and the tooltip cover the fight

Pictures: `s121 t032`, `s10 t017`, `s121 t016`, `s10 t013`.

`s121 t032`: six lines of text ("Torpedo lane: impact next turn", "Shield", "Critical hull", "Critical", two ship names)
stack into one unreadable knot on top of the only ships in the frame. `s10 t013`: the target tooltip sits on the enemy the
lance is hitting. The Neon weapon fx audit already lists the missing vertical stacking of numbers (its section 3); this is
new picture evidence that ship names and status words join the same pile, and that the tooltip is part of it.

How much: most enemy turns once three ships are close.

Fix: fold into that audit's Phase 3 slot queue: names, status words and numbers share one stack per ship, offset to the side
away from the action; the tooltip docks to the HUD target card during a shot.

### 12. The flagship pick shows the ship small, flat lit and off its own colour sheet

Pictures: `s10 t001`, `s121 t001`. Stage: V14_23 (Sunward S9), approved revision, installed.

The player's first look at their flagship: the hull fills under half of its panel, lit evenly from the front on a brown
vignette, so it reads as one mid grey tube with capped ends. factions.md says black iron, frost-white markings, bright
ember. In this picture the spires read as pale copper blocks, the engine as a dull disc, and there is no frost-white. The
lower right half of the screen is empty. I do not contest the hull tone (R256 moved it toward the concept's grey) or the
spire rulings; the ask is to check this screen's light against R347 and R360 ("fins never glow", ember from the core), since
here the fins look lit.

How much: once per run, at the moment the player is asked to care about this ship.

Fix: a three-quarter key light with a dark side, a slow turn, the ship at about twice the size, ember and engine glow
visible. Shared pick-screen stage, so all six factions get it.

### 13. The sector map planet reads as Earth, and the route web is one flat tangle

Pictures: `s10 t003`, `s10 t023`.

The planet at lower right has blue seas, white cloud and yellow city lights on its night side: it reads as Earth from a
stock library, under the heading "CONTESTED WORLD". The route lines are about twenty thin grey strokes of one weight that
cross each other, so the columns of the map do not read; the white glyphs do all the work, and the ship and station props
on the nodes are dark and tiny (the station size is already a KNOWN row in scale.md section 3, issue 373, not repeated).

How much: every map visit; mild each time.

Fix: a planet that belongs to this setting (the holder's colour in its lights, or a dead world), routes from the current
node brighter and the rest fainter (the orange lines in `s10 t023` already start this). Ryan picks the planet.

### 14. Icons are too small and thin to carry meaning

Pictures: `stills/battle_01`, `s10 t031`.

The weapon glyphs before "Sear battery" and "Oath lance" are about 12 px and cannot be told apart at 720 px tall. The action
icons (Brace, Focus fire, Turn, Board, Reload) are hairline glyphs of the same size beside 13 px labels; in `s10 t031` eight
of them share the corner. The legend swatches are 8 px squares (`stills/battle_04`). The ship silhouettes, by contrast, are
clear and differ by class.

How much: low at first, since labels sit beside them; it rises at larger window sizes where the labels are the only read.

Fix: one icon weight and a 20 px floor in the shared theme; weapon glyphs drawn by weapon family (battery, lance, torpedo,
flak) with shapes that differ in outline, not detail.

### 15. The busiest sky stacks four strong colours behind the board

Pictures: `s121 t022`, `s121 t026`, `s121 t030`, `s121 t036`.

Blue storm, rose nebula, orange dust sky and tan rocks, all at high strength, with a pale banded giant above. Each piece is
fine alone (and the rose and the storm blue are rulings); together the ships are lost and the board has no quiet place.
The backdrop audit's R1 and R2 saw this; Ryan ruled out the scrim. New point: the trouble in these frames is the orange
sky, not the hazards. The hazards are rules objects and must stay strong; the sky is free to give way.

How much: on the maps that draw this sky; strongly there.

Fix (sky shader only, no scrim): where a battle has both a storm and a nebula on the board, the sky behind the board drops
in saturation and value so the two hazard colours are the only strong hues. "Reopen: Ryan's call" only if this cannot be
done in the sky and a floor treatment is the only way.

## Good, must be kept

1. **The battle HUD band** (`stills/battle_01`, `s121 t030`): black, bone white and one orange, tall condensed ship names, a
   clear class silhouette per ship, tidy weapon rows. It is the most finished design in the game and should be the pattern
   the cards and load screens are rebuilt to.
2. **The title wordmark and menu** (`stills/title_1920x1080`): gold wide wordmark, short orange rule, one filled orange
   button, a quiet list. Confident and readable. Only the picture beside it is weak.
3. **The planets** (`s121 t012` banded giant, `s10 t007` rust world and moon, `stills/battle_01` violet giant): big, with a
   clean lit limb and a real dark side. They give scale and each battle its own place.
4. **The lance beam and the torpedo trail** (`s10 t013`, `s121 t008`): one clean bright line from shooter to target, the
   lance a white core with a warm edge, the torpedo a dashed track. Who shot whom is never in doubt.
5. **Faction contrast where it can be seen** (`s121 t038`, `s121 t012`): the Hullbreaker's rust red, patched and lopsided,
   against the long dark Sunward blade, and the pale Navy wedges against both. Three factions, three colours, three
   outlines. The rose nebula as one colour (R353) also reads as its own thing in every frame.

## For the Board

- Findings 1, 4, 5 and 12 are one theme: the ship art is not being shown. If only one thing is filed, file finding 1.
- Before the ranked list, the pack needs the missing stills: one battle each as Glasswrights, Chorus, Eclipse and Hegemony
  at camera 170, and the front-end set. Without them the "six families" question stays open and Rey and I are both guessing.

## Addendum: six families

Added after the faction stills landed in pack/factions/ (18 pictures, build 25adec31, installed in game, the game's own
battle camera). Short names: `chorus_05` is pack/factions/PT25adec3_chorus_05_6_enemy_turn.jpg, `deathless_05` and
`ithar_05` likewise. I looked at all 18.

**What the 18 pictures are.** Each set is the same six scripted moments of one Battle 1, played as Sunward against that
faction. Frames 01 to 04 and 06 show only the Sunward fleet, the sky and the rocks. The enemy faction's ships appear in one
frame per set, the enemy turn (`chorus_05`, `deathless_05`, `ithar_05`), small, in the lower right corner, partly under the
Log panel and the HUD fade. So the evidence for each of these three factions is one picture of two or three hulls about 60
to 90 px long. There is still no picture of any of them mid fight, as the player's fleet, or in a cut-in. Stage: Chorus is
mid rebuild (R349, issue 1291; B19_11 and B21_11 are a PC snapshot, not an approved revision; B20_11 is C13 round G) and is
not judged as finished. The pack does not name the Eclipse or Glasswright revisions on screen; I8_37 (Glasswright CD5) is a
flagship and is not in the frame.

### The answer

**Four of six read as their own family at the battle camera. Glasswrights do not. Chorus is too early to call.** And the
families are told apart by outline and overall tone only: no faction's accent light shows at this size.

| Faction | Picture | Reads as its own family at the battle camera? |
|---|---|---|
| Eclipse | `deathless_05` | **Yes, the strongest in the game.** A black ring on a stalk with a violet engine point. Nothing else has that outline. No green corona line is visible at this size (factions.md says it "must read at camera 170"). |
| Hullbreakers | `s121 t030`, `s121 t038` | **Yes.** Rust red and blunt. The only faction whose colour carries at distance. |
| Hegemony | `stills/battle_05`, `s121 t012` | **Yes, by tone.** Pale wedges. No blue light line visible. Surface not judged (possible PC snapshot). |
| Sunward | `stills/battle_01`, `s10 t011` | **Weakly.** A long dark dash. Told from the others because it is the darkest and longest, not by ember or spires. |
| Chorus | `chorus_05` | **Partly; mid rebuild.** Lumpy tan-brown bodies, clearly not built ships, which is the idea. No bile glow visible. Tone sits close to the rocks (finding 18). |
| Glasswrights | `ithar_05` | **No.** Pale slivers on a pale sky, all but invisible; no amber, violet or green panel colour shows (finding 16). |

"Unlike the others": yes for outline, across all six. No two share a shape from above, which is what R183 asked for.
"One family each": cannot be judged. One frame shows two or three hulls of a faction; none shows a whole fleet together.

### Revisions to the findings above

- **Finding 1 widens from Sunward to every faction.** factions.md asks for "one main colour, one accent light" at camera
  170. Across the whole pack the only accents that show are Hullbreaker red and the Eclipse violet engine point. Sunward
  ember, the Hegemony blue strip, the Eclipse green corona, Chorus bile and the Glasswright mosaic panels are all absent at
  the battle camera (`s10 t011`, `s121 t012`, `deathless_05`, `chorus_05`, `ithar_05`). The shared ship-side fix in
  finding 1 (a distance-scaled emissive floor on each faction's one accent) is the same fix for all six.
- **Finding 2, the two rock looks.** All 18 faction stills and the Hegemony stills have the grey chiselled rocks; only the
  two recorded runs have the tan clumps. So the look may follow the map or region rather than being a mistake. The finding
  stands for the tan set: it is the one that is too light, cloned and close to a faction's colour (finding 18).
- **Finding 3, the square lattice.** It is white in `ithar_03`, pink in `deathless_01` and `deathless_03`, and pink over
  the nebula in `ithar_04`. Its colour changes from map to map with no meaning a player could learn.
- **Finding 6, the legend.** The Nebula swatch is violet over a rose nebula in all three new sets too (`chorus_04`,
  `deathless_04`, `ithar_04`).

### New findings (numbered on from 15; where they rank is in each one)

### 16. Glasswright ships vanish against their own sky

Picture: `ithar_05`. Would rank second, after finding 1.

The Glasswright slivers are pale silver-white, about 60 px, sitting on a pale blue-white cloud band. Hull and sky are nearly
the same value; the violet brackets are what you find. One ship is under the Log panel. factions.md (R337) gives them
"glowing amber, violet and green mosaic panels ... like stained glass": none of that colour reaches the camera, so the
faction Ryan called "artistic ... beauty with function" is the least visible in the game. I do not judge the hull finish
(revision not named; the kit is being warmed, issue 1282), only the read.

How much: every Glasswright battle, from the first enemy turn.

Fix (shared Glasswright kit and shared look, R333): the mosaic panels carry the distance-scaled emissive floor from finding
1 so each sliver shows a point of amber, violet or green at camera 170; and a dark rim on pale hulls over pale sky (the
reverse of the light rim dark hulls need). Proof: `ithar_05` retaken, each hull found without its bracket.

### 17. The enemy fleet first appears under the Log panel

Pictures: `chorus_05`, `deathless_05`, `ithar_05`, `stills/battle_05`. Would rank about sixth.

In all four enemy-turn frames the camera puts the enemy fleet in the lower right corner, where the Log panel and the dark
HUD fade sit. Two of three Chorus bodies, one Eclipse ship and one Glasswright are behind the panel; a ring shows through
the HUD band. The middle of the screen holds rocks and sky. The first look a player gets at a new faction's ships is
through a text box.

How much: the first enemy turn of every battle, the exact moment the faction art should land.

Fix (shared camera framing): the enemy-turn framing treats the HUD band and the Log panel as off limits and centres the
acting ship in the clear area. The Log could also fold while the camera follows an enemy.

### 18. Chorus hide is in the same colour family as the tan rocks (flag for the rebuild, not a verdict)

Pictures: `chorus_05` against `s10 t029`, `s121 t036`. Stage: Chorus mid rebuild, not judged as finished. Rank low until
the rebuild lands.

In `chorus_05` the Chorus bodies are lumpy, tan-brown and unlit, among grey rocks, and read fine. The tan asteroid set in
the runs is the same tone and also lumpy. On a map with the tan rocks a Chorus fleet would be brown lumps among brown
lumps, with no bile glow at this size to mark them as alive. The ruled hide colour (olive-brown with dark red veins, R349)
is not contested.

How much: unknown until a Chorus fight on a tan-rock map is captured; likely strong there.

Fix: no change to the Chorus colour. Add one line to the Chorus kit's done-when and one to issue 1361's: a Chorus hull and
a blocker rock side by side at camera 170 must differ clearly in value, and the bile glow must show. The rocks give way,
not the ships.

### 19. The enemy marker disappears on the Eclipse sky

Pictures: `deathless_05`, `deathless_01`. Would rank with finding 6, as its strongest case.

The Eclipse map is violet on violet: violet sky, violet banded planet, violet enemy brackets, violet engine light, and a
violet legend swatch. In `deathless_05` the brackets round the Eclipse ships can barely be seen. The black Eclipse hulls
themselves read well here because the sky is lighter than they are, so the picture works by luck of this sky; the marker
does not work at all.

How much: every Eclipse battle on this sky.

Fix: as finding 6, one enemy marker colour that no faction and no sky owns. This picture is the reason violet cannot be it.

### 20. The Chorus sky fights the nebula, and has a hard-edged shape in it

Pictures: `chorus_01`, `chorus_03`, `chorus_05`. Would rank with finding 15.

The sky is a strong mustard yellow with a rose nebula on top: the loudest colour pair in the pack, and neither is the
ships. On the right of `chorus_01` and in the middle of `chorus_05` a dark olive mass ends in a crisp curved edge against
the yellow, like a dune or a cut-out, where everything else in the sky is soft. It reads as an error in the sky, not a
cloud.

How much: every battle on this sky; the edge is seen once and then always.

Fix (sky shader, shared): soften that edge to match the rest of the sky, and bring the yellow down in strength behind the
board, as in finding 15. Rose stays (R353); no scrim (R344).

### Still missing from the pack

One frame each of Glasswrights, Chorus and Eclipse mid fight at close range, one cut-in each, and one picture of each as
the player's fleet. Until then the table above rests on one small picture per faction, and Rey can fairly say so.
