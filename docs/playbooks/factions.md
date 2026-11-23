# Faction theme sheets (ships)

Issue 405, the ships track of docs/playbooks/PROGRAM.md. Written by the Board (Fable 5.2), Nov 10 2026, from the approved lore
(contrib/opus/compute/lore_bible_r8.md, the Look section of each faction), the 36 concepts in docs/ship_pipeline/concepts/, and
the owner's ship rulings in AGENTS.md. One sheet per faction. A concept, a three-view sheet (contrib/muse/design/concept_standard_2026_11/standard.md),
a hull build and a blob sweep are all judged against the sheet for that faction.

Ryan, Nov 10 2026, 18:44 CST: "all the factions shapes and stuff came before we redesigned them so I think it's worth just a full
update and pass based on the current faction lore and story". And earlier the same day: "I think all the concepts need reworking.
Hegemony and Sunward aren't TERRIBLY off, hullbreakers is okay but glasswrights, eclipse and chorus all need serious work. We wanted
to prove the building pipeline worked first and then redo all the concepts and builds." So every concept in
docs/ship_pipeline/concepts/ is history, not a target. The sheets below state what holds for each faction whatever direction is
picked; the section "The concept redo" at the end gives three directions per faction for Ryan to pick from.

Ryan, Nov 10 2026 (R164), on hard points: "It should vary by size of ship, faction, etc. We want things to be on theme."

## Rules for every faction

- Space ships, not sea ships (owner, Oct 22 and Oct 24). No keels or keel fins, raked stems, porthole rows, lattice masts,
  cranes, crossbar masts, funnels, railings or stepped yacht decks. Use the space version: flat armoured bellies with chines,
  sensor housings, antenna arrays, heat radiators, engine bells, docking hatches.
- No gun faces backward at rest; a turret may turn aft only to follow a target its arc allows (RULEBOOK 4.2, R222). Bow guns face forward, side guns face out.
- Matched symmetric pairs at sensible hard points, on visible mounts. The Hullbreakers are the one exception.
- The ship must read at the battle camera (camera 170): one clear silhouette, one main colour, one accent light. Detail that
  only shows up close is a bonus, never the identity.
- Every hull has real thickness and comprehensive insides through the whole hull: decks, frames, spaces and machinery, so a
  hit, break or death never shows an empty husk (R98, R209, R215). Ryan, Nov 11: "Let's ensure we're keeping in mind the
  hits, the breaks, the deaths and everything that affects the internals of the ship so we don't run into the issues of before
  with just empty looking husks". Chorus hulls carry flesh, bone and organs; Glasswrights layered glass and light.
- Breaks look blown apart, never sliced (R186; Ryan: "It's like straight lines and even halves. It doesn't feel like an
  explosion or major hit happened"). The faction's "How it breaks" line says where the hull gives way, not that it parts
  cleanly.
- Squadron craft are per faction (R253, Ryan, Nov 14: "Own models per faction"): each launching faction has its own
  fighter-role and bomber-role model in its own shape language (contrib/muse/design/squadrons_2026_11/), never one shared
  shape repainted.
- Hard points are not a fixed count (R164). Gun and engine points come from the hull's own weapon slots and engines. Breach
  anchors (where the hull opens when it dies) scale with class and follow the faction's own way of breaking, below.

### Breach anchors by class (the base count; each faction's sheet says how they are placed)

| Class | Base breach anchors | Authored break lines |
|---|---|---|
| Escort, frigate | 2 | 1 |
| Destroyer | 3 | 2 |
| Cruiser | 4 | 2 |
| Capital, carrier, barge | 6 | 3 |
| Flagship, station | 8 | 3 or 4 |

A faction may add or remove one where its sheet says so. tools/recipe/check_export.py reads the expected count from the hull's
class and faction (issue 363), never from a constant.

---

## Sunward Crusade (`voidsworn`)

**In one line:** a black iron blade with burning spires.

- **Silhouette:** long, narrow dagger or spearhead, widest at the stern third. A row of tall radiator spires along the spine,
  tallest amidships. Symmetric. The spires stand at about 70 percent of the concept table heights, with the same count,
  stations and profiles, and the ember shows in the fin slats, never as a whole lit tower: every Sunward build makes them
  with the one shared spire option, `radiator(..., glow='slats')` in tools/blender/kits/voidsworn/parts.py: the heat
  core glows ember the full height of the column and dark iron ribs, 0.15 apart, cross it, so the glow shows between the
  ribs as on the concepts; the fins themselves never glow. Why: Ryan, Nov 19 2026 (R331), on the Sunward concepts: "can we
  scale down the giant radiator/orange towers on each ship a bit too?"; S8 first (issue 1158), then Warden, Vigil, Harrow,
  Hearth and Bastion (R333). Ryan, Nov 20 2026, on the Warden's lit fins reading as copper: "fix ember glow" (issue 1156).
  The ember is bright: the whole core sits near the tip's level (stack.py SPIRE, root .70 of the tip), the tip still under
  the 0.8 glow threshold. Why: Ryan, Nov 20 2026 13:43 UTC, on S8 in game beside a brighter mock-up: "A bit brighter".
- **Shape language:** forged, heavy, vertical. Recessed lateral weapon galleries in long straight rows. Big engine bells. Plate with rivet
  lines, never rust.
- **Colours:** black iron, frost-white markings, bright ember (windows, engines, and the spires, which glow because they shed
  the reactor's heat).
- **Guns sit:** in armored flank casemates along both sides, plus one heavy pair at the bow. Manual optical fire-control blisters and recessed gun ports,
  evenly spaced.
- **Engines:** two to four large bells, ember orange, deep-set.
- **How it breaks:** along the lateral weapon galleries. The hull splits lengthwise between flank casemate runs, and the spire line snaps off as one
  piece. Inside: iron corridors, ember-lit, armored flank gunnery galleries. Breach anchors sit along the flank belt, evenly spaced.
- **Never:** rust (that is the Hullbreakers), blue light, a ram prow shaped like a ship's stem, cathedral windows so literal
  that it reads as another game's ship. The spires are radiators, not steeples: no crosses, no statues.
- **What the present concepts get wrong:** V1b_r_23 is a cathedral on a boat hull (stem bow, stepped decks): keep its mass and
  spire cluster, redraw the hull as a blade. V14_23 has wheel-like pods and red light: ember orange, and pods become radiator
  blocks.

## Meridian Directorate (`hegemony`)

**In one line:** a pale wedge with a line of blue light.

- **Silhouette:** a heavy, thick wedge on twin rails, about 3 : 1, with big shoulder turrets (R183 (3); Ryan on round 4:
  "Hegemony also seems a bit too fragile and slender?"). One low sensor fin, not a tower. Symmetric and identical across the
  fleet: the same parts repeated at different sizes.
- **Shape language:** machined, modular, horizontal. Flush panels, straight seams, repeated modules. The ion weapon is a
  recessed emitter trench in a blunt bow face, never prongs (R183 (1); Ryan: "every ship has the guns directly on the nose
  which feels odd").
- **Colours:** pale grey, steel-blue trim, implant-blue light strips that pulse in time across the whole fleet.
- **Guns sit:** low armoured mounts sunk into the shoulder armour, short thick barrels, never tall round turrets with long
  thin barrels (R185 (4); Ryan: "The hegemony guns look weird and almost cartoonish"); plus the bow emitter trench. Small
  drone bays in the flanks.
- **Engines:** a flat row of rectangular blue-white nozzles.
- **How it breaks:** in modules. It gives way at the bulkhead rings between modules, like a spine coming apart, the rims torn and scorched (R186). Inside:
  white corridors, blue emergency light, racks of identical equipment. Breach anchors sit on the module joints.
- **Never:** rust, asymmetry, ornament, warm light. No yacht decks, no conning tower, no tall mast.
- **What the present concepts get wrong:** H7 to H10 read as yachts or submarines (a tall sail-like tower, stepped cabin
  tiers); H4_11 is a sea battleship with a mast tower. Keep the wedge and the blue lines; flatten the superstructure into one
  low fin and turret rows.

## Ashfall Hullbreakers (`corsair`)

**In one line:** a lopsided brick of rust and stolen plate that runs dark.

- **Silhouette:** blunt, heavy-bowed, uneven. Bigger on one side than the other. Listening dishes and wake-sniffer scoops at
  the bow, boarding claws under it. The one faction allowed to be junky.
- **Shape language:** bolted, patched. Hull plates torn from every other faction, kept in their old colours. Nothing hangs
  off the ship: no loose chains, cages or dangling cargo; trophies and cargo are bolted flat (R185 (3); Ryan: "I don't
  understand the random things hanging off, it reads as naval"). Rocket racks sit on the top deck as big mismatched
  bolted-on launchers (R183 (4); Ryan: "rockets need to be on top to fit the scrapped together theme").
- **Patch size (R252, Ryan, Nov 14: "agree"):** the trophy patches read big like the A20 concept, not small dark plates; still
  uneven in size, rows and offsets (R240). **Their tone (R274, Ryan, Nov 15: "those should be a global rule for all of the bigger
  paler patches too. The white looks unfinished"):** dark grey salvaged metal, clearly lighter than the soot plate, never white or
  chalky; the violet Eclipse trophy plates stay. SUPERSEDED, kept so nobody follows it: "big and pale" (R252's tone, ended by R274). In the stack: `TROPHY` in `tools/blender/kits/hullbreakers/stack.py`
  (issue 726; RECIPE.md, the paint stack).
- **Patchwork cause and repair (R289, issue 875):** A16 and A17 have real mixed-size slabs, varied thickness and stacked
  patches in their design files, on the shared sheet kit's original plater. A18 to A20 selected the later `courses=True`
  builder (issue 633): small rectangular plates in brick rows and stepped terraces. The same paint stack could not remove
  that ordered geometry; R240 changed shader cells, not those slabs. KB1CC already split faces without courses, but its
  shallow slabs, small turns and reduced craft paint wear still read as flat notes. Those four sheets now use `kits/hullbreakers/plating.py`:
  mixed-size cuts across each face, skewed corners, turned and overlapping slabs, thickness steps and welded lap joints.
  Material weights, the trophy share and the R274 dark grey palette stay unchanged. Grey trophies keep their low wear.
  **KB1CC follow-up (R292, issue 875 run 2):** the craft-only palette from issue 853 mapped even `soot` and `soot2` to bright
  red, and its reduced grime and occlusion left broad clean salmon faces. The first repair's thicker relief made the small
  patches look loose. Craft zones now read their colours from the same `CONCEPT` palette as the capitals: dark iron under
  varied rust red, blood red and salvaged plates. Stronger seam occlusion, grime, scuffs and broken edge wear weather the real
  geometry without another tile grid. KB1CC keeps mixed sizes and welded overlaps, with lower relief bedded against the skin.
  Trophy colour and share stay unchanged. A16, A17, capital paint settings and the shared kit stay unchanged,
  including the A16 fixture record. Judge the painted result beside its concept and the accepted capital reference
  (A18 for KB1CC, A16 for the capitals) at the saved
  `paint_full` camera, not by plate counts. Proof and the repeatable bake script are linked in
  `docs/shots/look_bench/hullbreaker_patchwork/README.md`.
- **Colours:** soot black, rust, dried-blood red, patches of trophy colour (dark grey salvaged metal, R274; violet Eclipse plate), dim
  red running lights. No crystal shard: it came off A16 and A17 (R197; Ryan: "Not sure why there is a weird crystal in there
  but we can get rid of that").
- **Guns sit:** wherever they could be bolted: mismatched calibres, off-centre, never facing backward at rest (RULEBOOK 4.2). Casemates in the
  bow, tube racks on the deck.
- **Engines:** mismatched bells with a red-orange glow, one often larger than the rest.
- **How it breaks:** at the seams. Patch plates tear off first, then the hull parts where sections are welded together,
  ragged and uneven, never a clean cut (R186). Inside: scavenged frames, loot holds, kennel decks. One more breach anchor than
  the base count, placed unevenly.
- **Never:** clean symmetry, bright light, fresh paint. And still no sea-ship parts: junk is allowed, a boat is not.
- **What the present concepts get wrong:** all five carry lattice masts, cranes, porthole rows and keel fins (Muse's C15s trial
  shows them plainly). The masts become listening dishes and antenna clusters, the cranes become boarding claws and grapple
  arms, portholes go, and the keel fin becomes a ventral scoop or goes.

## The Glasswrights (`ithar`)

Ryan, Nov 10: "I like the idea-ish but it comes off looking as almost insect like. I think we go with a different idea but in a
similar vane." So the paired wing and petal vanes go. What stays is the idea underneath: a people of optical engineers whose
ships catch, store and release light.

**In one line:** an instrument for light, built as a warship.

- **Who they are (lore 6.1):** the Starwrights who stayed flesh; the finest optical engineers who ever lived. They built the
  collectors, mirrors and beam lines that carried a star's light across a system, and watched that machine kill their sun.
- **A small elite fleet, never a swarm (Ryan, Nov 20, issue 1298).** "Glasswrights aren't supposed to be a swarm faction like
  chorus or even hullbreakers. A little more elite." Few ships, each worth more: balance them with more hull on the
  four fleet hulls (sliver, lancet, prism, aperture; player and enemy copies alike, "so it's consistent"), not with cheaper
  or more numerous ships. The boss, The Unfinished, is not a fleet hull and keeps its own hull (470). They stay
  glassy: no armour added, evasion and shields still carry them.
- **First rule, ahead of any shape rule (R192).** Ryan, Nov 11: "It doesn't match with how I envision the glasswrights being
  artistic, thoughtful in creation and looking to create beauty with function, even in these warships." Every structural
  part is shaped with care and is also the ornament; the weapons are the centrepieces and must make sense.
- **Lenses are grown in (R196).** Ryan: "The lenses are a littlenweird and don't feel naturally ingrained into the ship like
  you'd expect with their lore. It should feel almost seamless and less bolted on. Like a work of art or blown glass, though
  able to rotate, etc." One continuous skin of glass and metal; no pod, bracket, ring mount or visible seam between lens and
  ship. Forward lenses visibly point forward. G17 (clear bubbles) and G18 (cream tubes) failed this (R201, R206).
- **Shape language:** a long leaf of flowing, twisted pearl ribbons (CD5, R298; it grew from the G13 and G15 base). Rigid,
  symmetric about the long axis. Nothing that reads as a wing, a petal, a sail or a body. No crystal object on a hull and no
  hull shaped like a crystal (R180, R183 (5): every crystal and prism route was scrapped).
- **Colours (R337, Ryan Nov 19):** opaque, reflective pearl ribbons with silver edges, and glowing amber, violet and green
  mosaic panels between them, like stained glass. Nothing is see-through: nothing inside an intact hull shows. This replaces
  the clear, lit-from-inside glass direction (issue 1058 runs 2 to 6 for CD5); issue 1183 rebuilds CD5 to it.
  Each leaf-shaped seam panel is ONE colour, deep at its leading and hot in its middle, running into the next leaf's
  colour only at its ends, as on I8_37 (R431, Ryan Nov 23 2026: "the top is how we want it to look across the board";
  tools/blender/kits/ithar/parts.py MIX 'blocks', stack.py TILE_SWAP 0). This reverses the Nov 21 marbled veins and tile
  swaps (look test D, issue 1415, "rectangle after rectangle of same color"), which read in game as pastel confetti;
  GW_MIX=marble brings them back for a comparison only. The pearl is I8_37's too (Ryan Nov 23: "ensure that white material
  also matches i8_37 ... more detailed and wrapping"): warm white with a rose and lilac sheen, never gold, laid as the Ark's
  fine spiralling ribbons with crossing leaves on every hull (kit hull.i8_field, hull.i8_shell). Ryan Nov 21 1:45 PM CT on the in-game sheets: "tone down
  red and amber with a bit more blue and green and purple": amber is about a third of the panels and golden, not red;
  violet and green rise, and a sapphire blue joins the palette (stack.py PALETTE, WEIGHTS 32/26/22/20, TONES). Ryan Nov 21 on the
  strike craft, then 8:29 PM CT for the big ships too: the stones are 25% more saturated on every Glasswright hull ("a little,
  nothing crazy"; stack.py SATURATION 1.25, applied once in the shared mosaic).
  The pearl is the shell and the glass is the seams (R431, Ryan Nov 23 2026, I8_37 against I15_11: "the top is how we want
  it to look ascross the board"): every Glasswright hull, craft included, shows the coloured glass only in the leaf-shaped
  seams and openings between pearl ribbons, never as a whole-hull mosaic; the kit review fails a hull above stack.MOSAIC_MAX
  (0.42) bare glass from above or the battle camera. Each seam carries its one colour per leaf, as above.
- **Guns sit:** on the optical axis. The prism lance is the hull's stored light let out through the bow optic: a white core
  with a rainbow fringe. Smaller lenses along the hull are the secondary guns.
- **Engines:** no flame. A soft white bloom at the stern optic.
- **How it breaks:** it shatters. Optics crack and shear off as whole panes or rings, then the hull snaps at a lens bay and the
  stored light spills out. One fewer breach anchor than the base count; each large optic is its own break piece.
- **Never:** paired wings or petals, cloth-like sails, masts and rigging, anything insect-like, rust, smoke, flame.

## Eclipse (`deathless`)

Ryan, Nov 10: "Shapes are the biggest issue. They look like just giant spinning tops, at least capital ships." His colour
line that day ("I like the green glow but it should be on brand with eclipse") kept a green corona on the hulls. **Superseded
Nov 20 2026 (issue 1419):** asked "the rim is written as green and the weapons as violet ... my pick is all violet, to match
the deaths and the color file", Ryan answered "yes ... agree with you". Eclipse is all violet: no green on the hulls.

**In one line:** a black shade with a thin ring of violet-white fire at its edge.

- **Who they are (lore 7.1):** the Starwrights who uploaded. Machine bodies in a system they made dark, each with a small core
  of trapped light, all that is left of their sun.
- **The corona:** a thin, cold violet-white line along the rim of every shade plate, white-gold at its hottest arcs, and the
  trapped light core seen through gaps, violet-white grading to violet. Never a pooled glow inside ribs or sockets, which
  reads as undead.
- **Shape language:** sunshades and heat shields: broad layered plates with the ship sheltering behind them. The shade always
  faces the enemy, like a shield held forward. Wide and flat, or a forward-facing arc or ring. The shade sits over the ship
  as a sunshade, the ship's heart and guns under and behind it, as E13 is built (R256, Ryan Nov 15). Guns never fire through
  slots in a shade. E14 is the exception being redesigned: its ring stands upright as in the concept, built around one larger
  gun at its centre, "like a glass cannon" (R256, Ryan Nov 15 07:02).
- **Colours:** dark violet-black plates, the violet-white corona line, a small bright violet-white core, white-gold accents.
  Engines, weapon bolts, damage glow and deaths come from godot/fx/faction_looks.json `deathless`, the one faction colour
  file (issue 1205 removed the all-green hull_table FAC3D override). The Doom gun's `weapon_core` is deep violet too (Ryan
  Nov 21 2026, "Yes make it a violet core", issue 1503; replaces R263's green core): no green is left in that file. The hull paint lives in
  tools/blender/kits/eclipse/stack.py: until that stack is repainted and the hulls rebaked (contrib/opus/plans/eclipse_1419.md),
  the installed E11 to E14 hulls still show the old green corona.
- **Panels (R243, Ryan Nov 13):** precise, dead even, ordered and aligned across hull and shade, with recessed seams and
  slight relief. Keep E11's accepted dark violet-black colour. This is machine precision; the Hullbreakers' irregular
  patchwork is their own. The thin uneven corona must read at camera 170, including E12's ring segments. The core glows
  violet-white (Nov 20, all violet), white-hot only at its very centre, and reads at camera 170.
- **Guns sit (R256, Ryan Nov 15):** clear of the shades: on mounts at the shade's heart or root firing over its plates (E13),
  or at the centre of a ring (E14, being redesigned). This replaces "behind the shade's rim, firing through gaps between plates".
- **Engines:** no flaming bells. An eclipse ring of pale violet light.
- **How it breaks:** in layers. Shade plates peel away band by band, then the body behind is bare. Inside: archive vaults,
  dark decks, the core's light. Breach anchors sit on the shade's bands.
- **Never:** a disc or cone on a vertical spindle (the spinning top), a spire through the centre of a disc, bone, ribs,
  skulls, any green on the hull, glow pooled in hollows, flame.
- **The E14 exception (R256, PR 804):** E14 is the accepted flare redesign, its ring standing upright around one fixed lance through the centre.

## The Chorus (`chorus`)

Ryan, Nov 10, picked every fault at once: "Reads as cartoon bugs or grubs", "Metal bits and wrong colours", "Idea is right,
execution is off" and "Start over with a new idea". So: the idea of grown, living ships stays; the grub is gone.

**In one line:** something vast and eyeless that was grown as a weapon and never stopped growing.

- **Who they are (lore 5.1):** not a people: a weapon the Fleshwrights grew to destroy Eclipse, engineered flesh that lives on
  starlight, eats anything, endures the cold and breeds without end. It consumed its makers and became one swarm with one
  appetite. The Fleshwrights were kin to the Glasswrights, so a Chorus ship may echo a Glasswright shape in flesh.
- **Shape language:** grown, not built. Scale and menace first: slow, heavy, deep-sea. Hide, membrane, chitin ridges, light
  inside the body. Symmetric where a body would be, ragged where it has been scarred and regrown.
- **Colours:** muddy olive-brown hide with dark red veins, pores and wrinkles (never maroon, never "red clay"), chitin a bone to
  horn tone, bile yellow-green light from inside at the veil roots and bile slits. The colour lives in the shared Chorus paint
  stack (tools/blender/kits/chorus/stack.py) and the build sheet's colour notes, not in more image rounds (R204; Ryan: "we can
  fix color ourselves rather than get stuck in a loop with color fixes with image generation"). Veils are satin (roughness
  0.6), not gloss, so they show no white hot spots.
- **Body and armour (R349, Ryan Nov 20; C13 round G accepted in game Nov 20, PR 1308):** a full body of lumpy fused swellings,
  deep folds and wrinkles grown into the skin (kit `body.field`), never a smooth tube with plates on top. Armour is grown
  chitin almost everywhere (Ryan, Nov 20 4:18 PM CT: "cover the chorus ships in armor almost everywhere"): armadillo bands
  that wrap down both flanks to the keel (kit `plates.armadillo`, its default `plates.WRAP`; a sheet never stops them
  higher), banded and ridged, lips aft, hide rolled up into their edges, broken only round the organs; where a fitting cuts
  a band, a half band still grows on its clear side (`fill`), so the shell hugs each fitting. Sacs and pods show dark veins and
  no lit spots at all: each sac's crown is cut open into a dark pore with a bore going down and a fleshy lip, never a round lit window, a glowing slit or
  glowing veins (kit `parts.sac` default window 'slit'; Ryan Nov 20: "random yellow circles on the pods ... looks odd", Nov 21:
  "the same weird yellow circle or patch on the sacs"). Gland vents are real openings: the knoll's crown is cut away under
  the puckered lip and a matte dark bore runs down into it (kit `parts.spinal` style 'gland', zone 'pit'; Ryan Nov 21: "no actual
  holes like the concept", then on dark discs: "these are clearly not holes"). Never a dark disc on a closed dome. An organ whose bore runs down into the body (C14's launch mouths) cuts the hull and any
  band open under it, and keeps the inside rooms clear of the bore (`K.open_hull` with depth, after the armour and rooms; Ryan Nov 21: "There are no actual holes, it's just caps"). A launch
  mouth carries a lobed flesh door, shut between launches, plain flesh, opening from the middle (`launch_mouth(door=6)`, issue
  1543; Ryan Nov 21: "Closer and plain flesh"); the lobes are their own hinged nodes and the game opens them on launch
  (docs/ship_pipeline/HARDPOINTS.md "Doors").
  Flank and brood sacs wear flat chitin caps, two rings of thin plates lying close with the slit open at the crown (kit
  `plates.dome_caps(flat=True)`; Ryan: "caps, but flatter"). The belly is banded too, so `plates.fused_patches` is only for a spot
  the bands cannot reach. No flat stone tiles: the R341 shell (`plates.armour`) is retired for new builds.
  Every Chorus hull uses these kit calls, so a fix in the kit reaches C10 to C14 at once (R333). The grown paint is the
  stack's default for every Chorus ship (a recipe opts out only with "chorus_look": "r341"), and every ship of every faction is
  gated by the stage 5 detail check (issue 1517; ships.md section 0, rule 16). Surface detail must read at
  camera 26 and still give texture at 170; stage 5's detail check (tools/recipe/detail_check.py) fails a flat clay skin.
- **Guns sit:** in throats, spines and sacs: a weapon is an organ. Brood sacs along the flanks for the wings.
- **Engines:** no nozzles. Pulsing vents or trailing membranes with a yellow-green glow.
- **How it breaks:** it bursts and tears. Sacs rupture first, then the body tears open. Inside: flesh and bone (R98), wet and
  lit from within: deep wet crimson-umber tissue, dry weathered ochre-ivory bone with no glow, and only a few dim olive-amber
  pores alight (R420, Ryan Nov 22; this holds for the insides only, the hide keeps its olive-brown and "never red" stands there). One more breach anchor than the base count on the big ones.
- **Never:** grub or caterpillar segments, anything cute or round-cheeked, legs, eyes, a face, any metal (no masts, antennas,
  towers or plates), red or magenta flesh.

---

## The concept redo: where each flagship stands (Nov 11 2026, evening, after R215)

The order Ryan set: the build pipeline was proven first (ship rounds 7 and 8, PR 401); then every faction's concepts are redone
from the current lore, direction first ("Direction first, then fleets"), and only then built. Eight rounds of pictures later
(the FINDINGS rows on the concept rounds), this is the state. What makes a picture a build reference now:

- **It is in the one concept style (R197).** Ryan, Nov 11: "Generally that style and tone is exactly how we should look at the
  concepts for our ships across fsctions. Pretty realistic and detailed to help with the builds... this style is how it should
  look in game." The style reference is contrib/muse/design/concept_directions_2026_11/corsair_A.jpg. Ryan judges it, side by
  side; the Board does not declare a picture in style on its own (R198).
- **Ryan has accepted that picture.** No concept is a build reference until he does (R199 (2)).
- **It still needs a build sheet before anything is built (R203).** Ryan: "I want to make sure that they are good enough to
  actually hand build from in blender." The sheet passes contrib/muse/design/concept_standard_2026_11/standard.md and is made by
  an Opus worker (R205). docs/playbooks/ships.md says how.

| Faction | Ship | State | Reference picture | Ryan's words, and what is left |
|---|---|---|---|---|
| Ashfall Hullbreakers | flagship (Warlord's Pyre-Barge) A16; cruiser (Pack Hunter) A17 | ACCEPTED (R201); build sheets round 2 running (issue 532) | contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg, corsair_A17_beauty.jpg (from round 1 corsair_A.jpg and corsair_B.jpg) | R197: "Yes! Scrap brick as the primary and pack hunter as like a cruiser or something." Round 1 sheets failed (R213: "The guns look randomly placed and don't make sense... the builds look like square blocks basically. It barely looks like the concepts."). A17: "Keep it lean" (length to beam about 3.0). |
| Eclipse | flagship E11; ring cruiser E12 | ACCEPTED (R206); sheets built and both in the game (issues 618, 642, 1057) | contrib/muse/design/concept_round8c_2026_11/deathless_E11_beauty.jpg, deathless_E12_beauty.jpg | Keep the Eclipse purple (E10 lost it, R201). The builder adds the struts the E12 ring arcs lack (R207: "Where there are gaps like eclipse rings not all having structural connections... you should build differently"). |
| The Chorus | flagship C10; bladeback cruiser C11 | ACCEPTED (R204); sheets built and through the recipe (issue 623; C10 relief, issue 921) | contrib/muse/design/concept_round8b_2026_11/chorus_C10_beauty.jpg, chorus_C11_beauty.jpg | R204: "The chorus ones look good, we can fix color ourselves rather than get stuck in a loop with color fixes with image generation." Bile yellow-green set in the build sheet's colour notes. The two read as two classes (the README's outline sheet). |
| Sunward Crusade | flagship, S8 shape; fighter SF3, bomber SB4 | FLAGSHIP SHEET ACCEPTED (R254); painted in the sandbox (PR 772), hull to come up a step lighter toward the concept's grey before the PC recipe run (R256); craft SF3 and SB4 confirmed (R256), sheets built (PR 776) | docs/ship_pipeline/build_sheets/voidsworn_S8/ (build sheet); craft: contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/SF3.jpg, SB4.jpg | R254: "Everything for sunward flagship is good. The fighters and bombers need a ton of work, new concepts to come." R255: "Agree on sf3 and sb4". Round 1 craft read as jets (no canopies, aero wings or tail fins). |
| Meridian Directorate | Dominion (h_dominion), H10 shape; Iron Mandate (h_boss), IM5 | BOTH SHEETS ACCEPTED (R256): Dominion (PR 767) and Iron Mandate (PR 775); the Hegemony paint stack is next | docs/ship_pipeline/build_sheets/hegemony_H10/ (build sheet); Iron Mandate: contrib/muse/design/iron_mandate_2026_11/round_2/IM5.jpg | R198: "H10 but I don't think it's in the same style as we see in hullbreakers. It's semi realistic but not quite." R254: "Can we do a mix of im2 and im3"; R255: "Im5 is my preference". A well-kept navy, never rusty; guns low, sunk in and real (R185). |
| The Glasswrights | flagship CD5 (Flowing Integrated Optics) | ACCEPTED (R298); build sheet done (issue 912); look restarting from the concept (R337, issue 1183) | Downloads\voidsworn_test\concepts\glasswright_r9\Glasswright_CD5_flowing_integrated_optics.png on the PC; the build sheet (issue 912) copies it into its own folder as concept.jpg | R298: "I love the overall design and the forward lances. The three other optics look somewhat left-heavy and randomly spaced, so clean up their placement in Blender while keeping them integrated into the flowing glass and consistent with their all-direction firing arcs. Treat the picture as a reference, not a literal placement guide." Made in ChatGPT image generation from G15's base (R296). |
| Station | Vesper Reach, damaged | ACCEPTED (R206: "T2 damaged"); build sheet, then issue 373 | contrib/muse/design/station_concept_2026_11/station_T2_beauty.jpg | Concept picture first, then the build (R201 (3)). |

History, not targets: every earlier pick (S8's own render, S9, S10, E4, E8, E9, E10, H8, H9, H11, H12, A10 to A15, G9 to G14,
G16 to G18, C8, C9). A10 to A15 were drawn against the wrong reference (R196: the Board read "our prior concept" as
docs/ship_pipeline/concepts/C19_51.webp; Ryan meant round 1 Scrap Brick).

**The method that works (use it for every later ship; each line names the ruling it comes from).**
1. Write the ship before drawing it: its exact weapons from data.js and where each sits, its engines, its proportions, and the
   thirteen-line gate (docs/playbooks/concepts_round2.md). Round 1 failed because no picture was told how many guns the ship has.
2. Draw in the one concept style (R197). A picture that reads as an illustration, a toy or a cartoon fails, whatever its shape.
   Each faction keeps its own palette and character ("realistic" does not mean rusty).
3. It must read as armed from above at thumbnail size (R176). Each faction mounts its forward weapon its own way, never a long
   barrel on the tip of the nose, and no two factions share an outline from above (R183; gate lines 1 and 8).
4. **When Ryan likes a picture, the next image job edits that picture (R192).** Image to image, the changes listed, everything
   else untouched; a result that drifted in mass, silhouette or character fails. Ryan: "Can we use our prior concept from
   before all these rounds as the base? Or just use that?" Six Hullbreaker rounds were lost redescribing a liked picture in
   words.
5. **Colour alone never sends a picture back (R204).** Colour is fixed in the build.
6. **When image rounds cannot reach the style without breaking the shape, stop the image rounds** and send the shape through
   the Opus build-sheet route (R204 (3), R206 (2)): a blockout locked to the liked shape, dressed in the style.
7. **The accepted picture guides the build; it is not traced (R207, R213).** Ryan: "Use it to guide, not the very final exact
   design." And: "The concept should inform and guide but it's not a final play by play guide." The Opus builder is the
   designer of record: it keeps the picture's identity (mass, outline from above, character, palette, where the big features
   sit), fixes what would not work as a built object, takes guns from data.js slots as batteries that make sense, and lists
   every change with its reason on the build sheet.
8. **Start from what was already liked (R180), and find it first (R196).** When Ryan points at a picture from memory, find it,
   show it with its name on it, and get a yes before building on it.
9. Check every feature under the battle camera before briefing it (R183), and run the naval pass on every sheet, side view
   first (R185; gate line 11). Image models drift to sea ships whenever a brief says "deck", "hull", "prow" or "barge": use
   "upper surface", "body", "bow face" and "block" in prompts instead.
10. Put the code name on every picture sent to Ryan (R185: "I can't tell which one is a11").
11. The Board reviews every sheet against the gate before Ryan sees it, and says plainly which fail.

Retired from this list: "Codex's built-in image tool is the tool for finals" (the Codex-drawn picks were the ones off the
style, R197 (3); concept rounds now run through Muse's image to image, and every Blender step is Opus's, R205).

**Next.** The finished battle is Sunward against Eclipse (R180). Eclipse's flagship and cruiser are accepted; Sunward's
flagship sheet is accepted (R254) and painted (R258). Then a fleet brief per faction (every class in data.js, each derived from the flagship's
grammar: what it keeps, what it drops, its weapons), pictures in the style, Ryan's yes, build sheets, then builds through
tools/recipe (docs/playbooks/ships.md).

## Round 1 directions (archived)

The eighteen round 1 direction write-ups (Nov 10, not picked: R172) moved to docs/archive/playbooks/factions_round1_directions.md
on Nov 11 2026. The pictures stay in contrib/muse/design/concept_directions_2026_11/.
