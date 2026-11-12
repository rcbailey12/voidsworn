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
- No gun ever faces backward. Bow guns face forward, side guns face out.
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
  tallest amidships. Symmetric.
- **Shape language:** forged, heavy, vertical. Broadside gun decks in long straight rows. Big engine bells. Plate with rivet
  lines, never rust.
- **Colours:** black iron, frost-white markings, bright ember (windows, engines, and the spires, which glow because they shed
  the reactor's heat).
- **Guns sit:** in broadside rows along both flanks, plus one heavy pair at the bow. Old manual gun decks: many small ports,
  evenly spaced.
- **Engines:** two to four large bells, ember orange, deep-set.
- **How it breaks:** along the gun decks. The hull splits lengthwise between deck rows, and the spire line snaps off as one
  piece. Inside: iron decks, ember-lit, gun crews' galleries. Breach anchors sit on the broadside deck line, evenly spaced.
- **Never:** rust (that is the Hullbreakers), blue light, a ram prow shaped like a ship's stem, cathedral windows so literal
  that it reads as another game's ship. The spires are radiators, not steeples: no crosses, no statues.
- **What the present concepts get wrong:** V1b_r_23 is a cathedral on a boat hull (stem bow, stepped decks): keep its mass and
  spire cluster, redraw the hull as a blade. V14_23 has wheel-like pods and red light: ember orange, and pods become radiator
  blocks.

## Hegemony Navy (`hegemony`)

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
- **Colours:** soot black, rust, dried-blood red, patches of trophy colour (pale Hegemony grey, violet Eclipse plate), dim
  red running lights. No crystal shard: it came off A16 and A17 (R197; Ryan: "Not sure why there is a weird crystal in there
  but we can get rid of that").
- **Guns sit:** wherever they could be bolted: mismatched calibres, off-centre, still never facing backward. Casemates in the
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
- **First rule, ahead of any shape rule (R192).** Ryan, Nov 11: "It doesn't match with how I envision the glasswrights being
  artistic, thoughtful in creation and looking to create beauty with function, even in these warships." Every structural
  part is shaped with care and is also the ornament; the weapons are the centrepieces and must make sense.
- **Lenses are grown in (R196).** Ryan: "The lenses are a littlenweird and don't feel naturally ingrained into the ship like
  you'd expect with their lore. It should feel almost seamless and less bolted on. Like a work of art or blown glass, though
  able to rotate, etc." One continuous skin of glass and metal; no pod, bracket, ring mount or visible seam between lens and
  ship. Forward lenses visibly point forward. G17 (clear bubbles) and G18 (cream tubes) failed this (R201, R206).
- **Shape language:** a leaf of cut glass lit from inside on a silver spine and rim (the G13 base, carried by G15). Rigid,
  symmetric about the long axis. Nothing that reads as a wing, a petal, a sail or a body. No crystal object on a hull and no
  hull shaped like a crystal (R180, R183 (5): every crystal and prism route was scrapped).
- **Colours:** clear glass and polished silver, a rainbow fringe on cut edges, a stored light glowing deep inside.
- **Guns sit:** on the optical axis. The prism lance is the hull's stored light let out through the bow optic: a white core
  with a rainbow fringe. Smaller lenses along the hull are the secondary guns.
- **Engines:** no flame. A soft white bloom at the stern optic.
- **How it breaks:** it shatters. Optics crack and shear off as whole panes or rings, then the hull snaps at a lens bay and the
  stored light spills out. One fewer breach anchor than the base count; each large optic is its own break piece.
- **Never:** paired wings or petals, cloth-like sails, masts and rigging, anything insect-like, rust, smoke, flame.

## Eclipse (`deathless`)

Ryan, Nov 10: "Shapes are the biggest issue. They look like just giant spinning tops, at least capital ships. I like the green
glow but it should be on brand with eclipse". This overrides the lore bible's colour line for ships (white-gold and
violet-white): the green stays, as the light of an eclipse.

**In one line:** a black shade with a thin ring of green-white fire at its edge.

- **Who they are (lore 7.1):** the Starwrights who uploaded. Machine bodies in a system they made dark, each with a small core
  of trapped light, all that is left of their sun.
- **The green, on brand:** a real total eclipse shows a faint green ring in the sun's corona. That is the Eclipse green: a
  thin, cold green-white line along the rim of every shade plate, and the trapped light core seen through gaps. Never a
  pooled glow inside ribs or sockets, which reads as undead.
- **Shape language:** sunshades and heat shields: broad layered plates with the ship sheltering behind them. The shade always
  faces the enemy, like a shield held forward. Wide and flat, or a forward-facing arc or ring.
- **Colours:** dark violet-black plates, the green-white corona line, a small bright core.
- **Guns sit:** behind the shade's rim, firing through gaps between plates.
- **Engines:** no flaming bells. An eclipse ring of pale light.
- **How it breaks:** in layers. Shade plates peel away band by band, then the body behind is bare. Inside: archive vaults,
  dark decks, the core's light. Breach anchors sit on the shade's bands.
- **Never:** a disc or cone on a vertical spindle (the spinning top), a spire through the centre of a disc, bone, ribs,
  skulls, green pooled in hollows, flame.

## The Chorus (`chorus`)

Ryan, Nov 10, picked every fault at once: "Reads as cartoon bugs or grubs", "Metal bits and wrong colours", "Idea is right,
execution is off" and "Start over with a new idea". So: the idea of grown, living ships stays; the grub is gone.

**In one line:** something vast and eyeless that was grown as a weapon and never stopped growing.

- **Who they are (lore 5.1):** not a people: a weapon the Fleshwrights grew to destroy Eclipse, engineered flesh that lives on
  starlight, eats anything, endures the cold and breeds without end. It consumed its makers and became one swarm with one
  appetite. The Fleshwrights were kin to the Glasswrights, so a Chorus ship may echo a Glasswright shape in flesh.
- **Shape language:** grown, not built. Scale and menace first: slow, heavy, deep-sea. Hide, membrane, chitin ridges, light
  inside the body. Symmetric where a body would be, ragged where it has been scarred and regrown.
- **Colours:** dark olive-brown hide, ochre bone and chitin, bile yellow-green light from inside. The C10 and C11 pictures came
  out greyer; the colour is set in the build sheet's colour notes and the paint stage, not by more image rounds (R204; Ryan:
  "we can fix color ourselves rather than get stuck in a loop with color fixes with image generation").
- **Guns sit:** in throats, spines and sacs: a weapon is an organ. Brood sacs along the flanks for the wings.
- **Engines:** no nozzles. Pulsing vents or trailing membranes with a yellow-green glow.
- **How it breaks:** it bursts and tears. Sacs rupture first, then the body tears open. Inside: flesh and bone (R98), wet and
  lit from within. One more breach anchor than the base count on the big ones.
- **Never:** grub or caterpillar segments, anything cute or round-cheeked, legs, eyes, a face, any metal (no masts, antennas,
  towers or plates), red or magenta flesh.

---

## The concept redo: where each flagship stands (Nov 11 2026, evening, after R215)

The order Ryan set: the build pipeline was proven first (ship rounds 7 and 8, PR 401); then every faction's concepts are redone
from the current lore, direction first ("Direction first, then fleets"), and only then built. Eight rounds of pictures later
(FINDINGS R172 to R206), this is the state. What makes a picture a build reference now:

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
| Eclipse | flagship E11; ring cruiser E12 | ACCEPTED (R206); build sheets next | contrib/muse/design/concept_round8c_2026_11/deathless_E11_beauty.jpg, deathless_E12_beauty.jpg | Keep the Eclipse purple (E10 lost it, R201). The builder adds the struts the E12 ring arcs lack (R207: "Where there are gaps like eclipse rings not all having structural connections... you should build differently"). |
| The Chorus | flagship C10; bladeback cruiser C11 | ACCEPTED (R204); build sheets next | contrib/muse/design/concept_round8b_2026_11/chorus_C10_beauty.jpg, chorus_C11_beauty.jpg | R204: "The chorus ones look good, we can fix color ourselves rather than get stuck in a loop with color fixes with image generation." Bile yellow-green set in the build sheet's colour notes. The two read as two classes (the README's outline sheet). |
| Sunward Crusade | flagship, S8 shape | SHAPE SETTLED, style not reached; Opus build-sheet route | shape: contrib/codex/design/concept_round5_2026_11/voidsworn_S8_sheet.jpg | S8 settled in direction (R185: "Agree with other takes"). S9 and S10 failed the style (R201; R206: S10 "still close to the smooth drawing"). No more image rounds: an Opus build sheet locks the S8 shape and dresses it in the R197 style (R206 (2)). |
| Hegemony Navy | flagship, H10 shape | SHAPE SETTLED, style not reached; Opus build-sheet route | shape: contrib/muse/design/concept_round7_2026_11/hegemony_H10_sheet.jpg | R198: "H10 but I don't think it's in the same style as we see in hullbreakers. It's semi realistic but not quite." H12 failed (R204: "You're right on h12"). A well-kept navy, never rusty. Same route as Sunward (R204 (3)). |
| The Glasswrights | flagship, G15 shape | SHAPE SETTLED, lenses not reached; Opus build-sheet route | shape: contrib/muse/design/concept_round7_2026_11/ithar_G15_sheet.jpg | R196: "I really like g15." Its lenses are grown into the hull (the faction sheet above). G17 and G18 failed on the lenses (R201, R206). Same route (R206 (2)). |
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
flagship needs its build sheet. Then a fleet brief per faction (every class in data.js, each derived from the flagship's
grammar: what it keeps, what it drops, its weapons), pictures in the style, Ryan's yes, build sheets, then builds through
tools/recipe (docs/playbooks/ships.md).

## Round 1 directions (Nov 10; kept for the record, not picked: R172)

These eighteen were drawn once by Muse (contrib/muse/design/concept_directions_2026_11/). Read them as history: what was
tried first and why it was not enough.

### Sunward Crusade: three directions

- **A. Oath Blade.** The long black dagger kept and cleaned up: a spine of radiator spires glowing ember, long broadside gun
  decks, the names of the dead chalked in frost white down both flanks.
- **B. Forge.** Blunt and heavy. A slab prow, and the reactor's heat shed through stacked radiator fins along the flanks that
  glow like a forge, with only a few short spires. Broadside-heavy, brutal, less cathedral.
- **C. Reach Militia.** A navy pooled from a written-off frontier: mining and farm-moon haulers rebuilt as warships. Boxy
  cargo-frame bones, black iron plate laid over them, gun decks cut into the sides, radiator towers added. The story shows.

### Hegemony Navy: three directions

- **A. Clean Wedge.** The flat pale wedge with one low fin, rows of identical turrets and blue lines pulsing in time.
- **B. Module Line.** The Registry builds every ship from one kit: identical modules clipped along a spine. A frigate is two
  modules, a capital is eight, with ion prongs on the bow module. The sameness is the point, and it breaks module by module.
- **C. Drone Mother.** A smooth pale hull with open racks along its flanks and a halo of small drones holding perfect
  formation around it. Few guns of its own; the calm is the threat.

### Ashfall Hullbreakers: three directions

- **A. Scrap Brick.** Today's look without the sea-ship parts: a lopsided bolted brick with listening dishes, wake-sniffer
  scoops and boarding claws.
- **B. Pack Hunter.** The ship shaped like its makers: a heavy head with listening dishes for ears and sniffer intakes, a great
  shoulder hump, and boarding jaws at the bow that open sideways. Lean, leaning forward, still plated in stolen hull.
- **C. Den Ship.** A burned-out rock from the Ashfall belt, hollowed and fitted with engines chained to the stone, gun pits
  and kennel decks. Rock and scrap together; it runs dark.

### The Glasswrights: three directions (a new idea in the same vein)

- **A. Collector.** One great forward-facing mirror dish of rigid hexagonal facets, ringed around a slim silver hull, like the
  collectors their ancestors built. The lance fires from the dish's focus.
- **B. Prism.** The hull is the optic: one long cut crystal shard, three-sided, with light moving inside it and small mirror
  fins. No vanes at all. The hardest and most plainly a weapon.
- **C. Beam Line.** A row of three to five lens rings held in a silver truss along one axis, an optical bench in space. Light
  passes ring to ring and leaves as the lance.

### Eclipse: three directions (no spinning tops)

- **A. Crescent.** A huge thin crescent shade, a partial eclipse, with the ship's body tucked inside its curve. Head-on it is
  a black crescent with a green-white rim.
- **B. Fan.** Overlapping shade plates swept back from the bow like a folded parasol or an arrowhead of shields. Wide and
  flat, the ship sheltering behind.
- **C. Annulus.** A monumental broken ring of plates around a bright core, facing forward like a ring eclipse, its pieces
  drifting and being refitted by tiny drones (the lore's "greatest minds"). The body is a slim spar behind the ring.

### The Chorus: three directions (no grubs)

- **A. Leviathan.** Deep-sea scale: a vast, eyeless, smooth-hided body with chitin ridges and light glowing through it from
  inside, long and slow, with its escorts like pilot fish.
- **B. Bloom.** A starlight feeder: a dark core with a crown of membranes that open toward the light, like a sea lily or a
  fungus, bile-green in the throat. The Glasswright collector, grown in flesh by their lost kin.
- **C. Overgrowth.** Flesh and ochre bone grown over the shape of what it ate: the outline of a swallowed warship still
  readable under the hide, with no metal showing anywhere. Ragged, scarred, the most frightening up close.
