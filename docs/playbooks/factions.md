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
- Every hull has real thickness, a few decks and bulkheads inside, and authored break lines with matching inner faces (R98).
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

- **Silhouette:** clean flat wedge, sharp bow, low profile. One low sensor fin, not a tower. Symmetric and identical across the
  fleet: the same parts repeated at different sizes.
- **Shape language:** machined, modular, horizontal. Flush panels, straight seams, repeated modules. Ion prongs at the bow.
- **Colours:** pale grey, steel-blue trim, implant-blue light strips that pulse in time across the whole fleet.
- **Guns sit:** in rows of identical turrets on the upper deck, evenly pitched, plus the bow prongs. Small drone bays in the
  flanks.
- **Engines:** a flat row of rectangular blue-white nozzles.
- **How it breaks:** in modules. It parts cleanly at the bulkhead rings between modules, like a spine coming apart. Inside:
  white corridors, blue emergency light, racks of identical equipment. Breach anchors sit on the module joints.
- **Never:** rust, asymmetry, ornament, warm light. No yacht decks, no conning tower, no tall mast.
- **What the present concepts get wrong:** H7 to H10 read as yachts or submarines (a tall sail-like tower, stepped cabin
  tiers); H4_11 is a sea battleship with a mast tower. Keep the wedge and the blue lines; flatten the superstructure into one
  low fin and turret rows.

## Ashfall Hullbreakers (`corsair`)

**In one line:** a lopsided brick of rust and stolen plate that runs dark.

- **Silhouette:** blunt, heavy-bowed, uneven. Bigger on one side than the other. Listening dishes and wake-sniffer scoops at
  the bow, boarding claws under it. The one faction allowed to be junky.
- **Shape language:** bolted, patched, chained. Hull plates torn from every other faction, kept in their old colours. Chains
  between hull sections.
- **Colours:** soot black, rust, dried-blood red, patches of trophy colour (pale Hegemony grey, a shard of Glasswright
  crystal, violet Eclipse plate), dim red running lights.
- **Guns sit:** wherever they could be bolted: mismatched calibres, off-centre, still never facing backward. Casemates in the
  bow, tube racks on the deck.
- **Engines:** mismatched bells with a red-orange glow, one often larger than the rest.
- **How it breaks:** at the seams. Patch plates tear off first, then the hull parts where sections are chained together, and
  the chains hold the pieces for a moment. Inside: scavenged frames, loot holds, kennel decks. One more breach anchor than
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
- **Shape language:** engineered optics: mirrors, lenses, prisms, rings, trusses. Rigid, geometric, symmetric about the long
  axis. Cut and faceted, never soft. Nothing that reads as a wing, a petal, a sail or a body.
- **Colours:** clear crystal and silver, a rainbow fringe on cut edges, a stored light glowing deep inside.
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
- **Colours:** dark olive-brown hide, ochre bone and chitin, bile yellow-green light from inside.
- **Guns sit:** in throats, spines and sacs: a weapon is an organ. Brood sacs along the flanks for the wings.
- **Engines:** no nozzles. Pulsing vents or trailing membranes with a yellow-green glow.
- **How it breaks:** it bursts and tears. Sacs rupture first, then the body tears open. Inside: flesh and bone (R98), wet and
  lit from within. One more breach anchor than the base count on the big ones.
- **Never:** grub or caterpillar segments, anything cute or round-cheeked, legs, eyes, a face, any metal (no masts, antennas,
  towers or plates), red or magenta flesh.

---

## The concept redo: where each flagship stands (Nov 11 2026)

The order Ryan set: the build pipeline was proven first (ship rounds 7 and 8, PR 401); then every faction's concepts are redone
from the current lore, direction first ("Direction first, then fleets"), and only then built. Four rounds of pictures later
(FINDINGS R172, R176, R178, R180), this is the state. A flagship marked SETTLED is the reference for its whole fleet.

| Faction | State | The reference picture | What Ryan said, and what is still to fix |
|---|---|---|---|
| Sunward Crusade | Body SETTLED; bow being redrawn (round 5, S8) | contrib/codex/design/concept_round4_2026_11/voidsworn_S7_sheet.jpg | "I agree with s1bs four flak barrels with s1as heavy barrels." A black iron blade, an organ-pipe bank of ember radiators on the rear spine, seven heavy barrels a side, four flak turrets in pairs. On S7 (R183): "Sunward is getting there but again same giant gun directly on nose." The long lance barrel goes; the lance becomes an ember-lit emitter recessed in a split prow. |
| Hegemony Navy | Plan SETTLED; being made heavier (round 5, H8) | contrib/codex/design/concept_round4_2026_11/hegemony_H7_sheet.jpg | "Agree with h5 redrawn by codex, makes it more unique." A wedge bow, then two parallel rails with the hangar between them; blue light lines; real surface detail. On H7 (R183): "Hegemony looks a bit closer but every ship has the guns directly on the nose which feels odd. Hegemony also seems a bit too fragile and slender?" So: a thick, heavy wedge and thick rails (about 3 : 1 long to wide, never a needle), no prongs on the nose, the ion weapon as a recessed trench in a blunt bow face, big turrets on the shoulders. |
| Eclipse | Flagship SETTLED; ring cruiser being redrawn (round 5, E8) | contrib/codex/design/concept_round2_2026_11/deathless_E4_sheet.jpg (flagship); contrib/muse/design/concept_directions_2026_11/deathless_C.jpg (the ring) | "I like where we're going with Eclipse." The crescent bow with the doom weapon through its focus. "I still really like the Annulus version from before but that can be its own ship too": the cruiser (Eclipse zenith) is a ring ship. Codex's first try (round 4, E7) was a tube with a spoked wheel on its nose and a cannon; Ryan (R183): "Eclipse looks horrible, not sure what happened there". What happened: the brief asked for "a real hull behind the ring", and a ring standing upright is only a bar from above. The redo: the ring IS the ship and lies flat, so the battle camera sees the whole broken ring of separate plates round a green core. |
| The Glasswrights | OPEN: one picture to beat (G9), three fresh routes coming | To beat: contrib/muse/design/concept_round4_2026_11/ithar_G9_sheet.jpg (the Wedge) | Ryan on the full prism bar (R183): "Glasswrights looks too basic... scrap it and start from fresh with the faction lore and context, pending what muse comes back with." Then on Muse's three (R184): "I actually don't mind the last Glasswright on the right. It's the best version". So G9 stands as the best so far: a clear glass wedge, wide at the stern and narrowing to the bow, light running its length, a silver frame. Its faults: gun turrets on a rail, lenses drawn as fans. Three fresh routes from the lore, with no prism in them, are with Muse (issue 476: The Unfinished, the Mirror Deck, the Racing Hull) so Ryan can compare. Whichever wins, Codex draws the final with lens domes for weapons. |
| Ashfall Hullbreakers | OPEN, close: a mix of Muse A7 and A9 | contrib/muse/design/concept_round4_2026_11/corsair_A7_sheet.jpg and corsair_A9_sheet.jpg; the character behind both: docs/ship_pipeline/concepts/C19_51.webp | Ryan (R184): "A mix of a 7 and a9 is where I'm at. I don't like the giant grey block in a7 but rest is good". And (R183): "rockets need to be on top to fit the scrapped together theme." Keep A7's broad body of stacked red oxide slabs and A9's top-deck racks, chains, cages and trophy slab; no single big plain plate anywhere; two rocket launchers on the top deck; torpedo tubes flush and low in the bow; a stepped outline from above. Muse draws the mix two ways (issue 477, A11 and A12); Codex's own take is A10 (issue 475). |
| The Chorus | Flagship SETTLED (C9); second class picked (C8) | contrib/muse/design/concept_round4_2026_11/chorus_C9_sheet.jpg (flagship, the old leviathan); chorus_C8_sheet.jpg (bone through skin) | Ryan (R184): "I really like c8 and c9. C8 would probably need to be changed a bit since it's similar to c9 if it's a second ship but I like them a lot." C9 is The Ninefold Maw: scarred, barnacled hide, one large bloom with two throats, brood sacs of different sizes, a lumpy outline from above. C8's bone plates and spines grown through the hide become the Chorus bladeback (the cruiser): shorter and stockier than the flagship, one throat, the bone ridge as its whole identity, so the two are never confused. Both run lean (about 5 : 1); accepted. Amber is the Chorus glow. |

**The method that works (use it for every later ship).**
1. Write the ship before drawing it: its exact weapons from data.js and where each sits, its engines, its proportions, and the
   twelve-line gate (docs/playbooks/concepts_round2.md). Round 1 failed because no picture was told how many guns the ship has.
2. A design sheet first (top view above side view, flat on, same scale), then the beauty view made FROM that sheet. The battle
   camera looks down, so the identity must read in the top view.
3. It must read as armed from above at thumbnail size: barrels plain to see, ordered, never scattered (R176).
   But each faction mounts its forward weapon its own way, never a long barrel on the tip of the nose, and no two factions
   share an outline from above (R183; gate lines 1 and 8).
4. Codex's built-in image tool holds a layout and a weapon count and keeps one hand across factions; it is the tool for
   finals. Muse's image models give variety and are better at organic subjects, but drift on layout and colour. Use Muse to
   explore, Codex to settle.
5. **Start from what was already liked (R180).** When a faction had a picture Ryan liked (the round 1 Prism, the original
   Pyre-Barge), the new brief starts from that picture and names what to keep. Two rounds were lost by designing the
   Glasswrights and the Hullbreakers afresh and sanding off what made them theirs.
6. The Board reviews every sheet against the gate before Ryan sees it, and says plainly which fail.
7. **Check every feature under the battle camera before briefing it (R183).** The round 4 ring cruiser failed because an
   upright ring is a bar from above. Anything that carries a ship's identity must show in the top view.

**Next.** The finished battle is Sunward against Eclipse (R180), so those two fleets come first: a fleet brief per faction
(every class in data.js, each derived from the flagship's grammar: what it keeps, what it drops, its weapons), drawn as design
sheets by Codex, picked by Ryan, then built through tools/recipe (docs/playbooks/ships.md).

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
