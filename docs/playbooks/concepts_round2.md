# Ship concepts, round 2: design sheets and the review gate

Issue 405, ships track. Written by the Board (Fable 5.2), Nov 11 2026, after Ryan's review of the eighteen round 1 direction
pictures (contrib/muse/design/concept_directions_2026_11/). Read docs/playbooks/factions.md first: this page narrows it.

## What Ryan said (Nov 10 2026, 20:16 CST)

1. Glasswrights: "Prism is the closest but it still needs a ton of work. It doesn't look like an actual ship, really? We can
   keep going with the prism theme but make it actually a warship and spaceship".
2. Eclipse: "Fan is definitely good but I also really like how distinct Annulus is. I wouldn't mind that being a capital ship
   and a mix of Fan and annulus? Even crescent could be cool if done right and made sense as a ship."
3. Chorus: "A mix of Leviathan and Bloom".
4. Sunward: "Oath Blade is the closest but the top makes no sense? it has way too many random guns?"
5. Hegemony: "I guess a mix of all 3? I don't really love any of these."
6. Ashfall: "Scrap brick and pack hunter are the closest. Scrap for capital maybe."

And the larger point: "The larger issue that I've noticed with Muse is it cannot maintain image generation consistency. Things
look oddly placed, they don't make sense as a spaceship, proportions are off, everything. It's fine as an initial concept but
I need you to do a much more in depth review and refinement before these ever go to actual builds. Use the faction bible and
lore for consistency, look at the issues we've run into with building before and my prior feedback. Come back with another 3
variations for each based on my feedback here and prior."

## The Board's review of round 1: why the pictures did not make sense as ships

- **Guns were decoration.** The Oath Blade carries dozens of small barrels along both edges and across the deck. In the game a
  Crusade battleship has four weapon mounts. No picture was told how many weapons the ship has or where they fire.
- **Nothing said where things go.** No bridge, no engine layout, no hangar, no spine. The model filled every surface evenly,
  which is why "things look oddly placed".
- **A feature was drawn instead of a ship.** The Prism is a crystal with rails; the Beam Line is a telescope; the Annulus is a
  ring with a stock warship parked behind it. Round 1 asked for a silhouette and got an object.
- **Three-quarter beauty shots hide proportion.** One dramatic angle lets length, beam and height drift. Rounds 7 and 8 of the
  build already taught this (R162): a hull could not be fitted from one view.
- **Each picture was made alone**, so the escort beside the hero is a shrunken copy, not a smaller ship of the same family.
- **The game is seen from above.** A design whose identity is in its side view (or its underside) is invisible in play.

## Spaceship logic: the gate every picture passes before Ryan sees it

A picture that breaks any line goes back to be redrawn with the broken line quoted. This list is also the reviewer's
checklist for any model that takes the Board's seat.

1. **Weapons are the game's own, counted.** Each ship shows exactly its mounts from data.js and nothing else that looks like a
   gun. The arcs decide the place: F fires forward on the centre line at the bow; P and S are one battery on each flank,
   amidships, firing outward; T is a turret on the upper centre line with a clear field. Flak is one small cluster on top.
   Each mount is one large, deliberate installation with a visible base, not a row of scattered barrels.
   **And it must read as armed (Ryan on the first round 2 sheets, R176: "It's really hard to tell if there's any guns right
   now so it barely looks like a warship").** A battery or turret shows its barrels, heavy and plain, pointing where it fires;
   the ship looks armed in the top view at thumbnail size. Flak may be drawn as two to four small matching turrets in
   symmetric pairs (still one flak system). Ordered, never scattered; gun ports are dark, never lit like windows.
   **The forward weapon is built the faction's own way, and is never a long barrel on the tip of the nose (Ryan on round 4,
   R183: "same giant gun directly on nose. It's good to have forward facing but it always looks the same across factions").**
   An earlier wording of this line ("the forward gun is the largest object on the bow") caused exactly that and is
   withdrawn. The side and top weapons carry the armed look; the forward weapon is part of the bow's shape:
   - Sunward Crusade: the lance is an ember-lit emitter recessed between the two halves of a split prow; nothing sticks out
     past the prow tips.
   - Hegemony Navy: the ion weapon is a recessed emitter trench across a blunt, armoured bow face. No prongs, no barrels.
   - Eclipse: the doom weapon is a green-lit aperture between the horns of the crescent (flagship) or in the gap of the
     ring (ring cruiser).
   - Ashfall Hullbreakers: the heavy torpedo is tube mouths set low in the bow armour, either side of the ram plate. Their
     rocket racks sit on the top deck (Ryan, R183: "rockets need to be on top to fit the scrapped together theme").
   - The Glasswrights: twin lens apertures in the shoulders of the bow, either side of the centre line.
   - The Chorus: throats inside the bloom.
2. **Nothing blocks a gun and no gun aims backward or into the ship.**
3. **One thrust axis.** Engines are at the stern, in line with the length of the ship, sized to push it (the engine group
   fills between a quarter and a half of the stern face). Nothing glows like an engine anywhere else.
4. **One spine.** A continuous structural backbone runs from bow to engines; every other part hangs off it. Break lines cross
   the spine at its two or three narrowest places.
5. **One place for the crew and one for the eyes.** A single command block and a single sensor cluster, low and protected,
   never a tower or a mast.
6. **A hangar is a door.** A ship with wings shows one bay mouth per hangar point, on a flank or the belly.
7. **Symmetric about the centre plane.** The Hullbreakers may be lopsided in plating and add-ons; their engines and main
   guns still balance about the thrust axis.
8. **Designed from above first.** The plan view (top) carries the identity, because the battle camera looks down. The side
   view confirms it. Then the beauty view.
   **No two factions share an outline from above (R183).** Round 4 drew four factions as the same long bar with a gun on
   the tip, told apart only by paint. Each faction owns a plan shape: Sunward a broad-shouldered blade with a forked prow;
   Hegemony a heavy, thick wedge on twin rails; Eclipse a crescent or a broken ring; Hullbreakers stepped, lopsided blocks;
   the Chorus a grown body with no straight line; the Glasswrights still open. A feature that only shows from the side or
   the front (an upright ring, lenses standing across the axis) is lost under the battle camera: lay it flat or turn it up.
9. **Fixed proportions per class.** Stated as length : beam : height in each sheet below. The escort is a smaller ship of the
   same grammar with fewer parts, never the capital shrunk.
10. **One scale.** Windows, hatches, plates and lights are the same real size on every ship of a faction, so a capital has
    many more of them than an escort and size reads at a glance.
11. **Space, not sea, not air.** No keels, masts, cranes, portholes in rows, funnels, railings, stepped decks; no wings, tail
    fins or cockpit canopies.
    **The naval pass (Ryan on round 5, R185: "I don't understand the random things hanging off, it reads as naval. We need
    to do a full pass across all ships and factions so not naval").** A sea ship has a top and a bottom: everything sits on
    a deck, and the hull below is a smooth boat shape. That profile is the tell, more than any single part. So, for every
    ship of every faction:
    - **No boat profile.** In the side view the underside is never a curved hull with a keel line under a flat deck. It is
      a flat armoured belly with hard chines, or the ship is the same above and below its centre line (a blade, a lens, a
      wedge, a ring).
    - **The belly is worked.** Thruster pods, sensor housings, radiators, a hangar door or armour belts sit on the
      underside. If the top view holds every weapon and fitting and the belly is bare, the ship reads as a boat.
    - **No deck house.** No stack of cabins rising from a deck amidships; the command block is low and sunk into the hull.
    - **No ship's prow.** No raked, raised or pointed bow that would cut water. Bows are blunt, forked, wedge-flat or open.
    - **Nothing hangs off the ship.** No chains, cages, anchors, fenders, nets, boats or cargo dangling over the sides or
      under the hull. Cargo and trophies are bolted or strapped flat against the hull.
    - **Turrets are not battleship turrets.** No tall round gun houses with long thin twin barrels standing on a deck
      (Ryan on H8: "the hegemony guns look weird and almost cartoonish"). Guns are low, armoured, sunk into the hull's
      own shape, with short thick barrels in proportion to the ship.
    - Still out, as before: masts, funnels, cranes, railings, portholes in rows, flight decks, lifeboats.
    The Board checks every sheet against this list before Ryan sees it, the side view first.
12. **The faction's sheet holds.** Its colours, its one accent light, and its "Never" list (docs/playbooks/factions.md).

## How round 2 is drawn

For each variation below Muse's image models make **two pictures of the same ship**:
- **The design sheet**: the top view above and the side view below, flat on (no perspective), same scale, on plain dark grey,
  lit evenly, no text. This is the picture that is checked against the gate.
- **The beauty view**: three-quarter from the front and above, the hero with one escort of its family, on near black.

Up to three tries each. The Board reviews every sheet against the twelve lines, sends failures back with the line quoted, and
only then lays out three per faction for Ryan. The design sheet, not the beauty view, is what a build is later traced from.

The hero of each faction is its capital, with its real weapon list:

| Faction | Hero ship (data.js) | Mounts and arcs | Hangar |
|---|---|---|---|
| Sunward Crusade | Bastion-class battleship (`cathedral`) | heavy battery P, heavy battery S, lance F, flak T | none |
| Hegemony Navy | Dominion dreadnought (`h_dominion`) | heavy turbolaser P, heavy turbolaser S, ion cannon F, flak T | 1 |
| Ashfall Hullbreakers | Warlord's Pyre-Barge (`c_boss`) | scatter battery P, scatter battery S, heavy torpedo F, flak T | 2 |
| The Glasswrights | The Unfinished, an Ark (`i_boss`) | pulsar F, pulsar F, pulsar T, turret T, flak T | none |
| Eclipse | The Unsetting, a Tomb-ark (`d_boss`) | gauss T, gauss T, doom F, flak T | none |
| The Chorus | The Ninefold Maw, a Bio-titan (`b_boss`) | bioplasma F, bioplasma F, tendril T, spores T | 3 |

The escort in each beauty view is the faction's frigate, with its one or two mounts.

## The design sheets

Each faction has one grammar (true of all three variations) and three variations.

### Sunward Crusade

Ryan: the Oath Blade is closest, but its top makes no sense and it has far too many guns.

**Grammar.** A black iron blade, length : beam : height about 5 : 1 : 0.7. The two heavy batteries are gun decks inside the
flanks: one long recessed gallery of ports on each side amidships, flush with the hull, no barrels on deck. The lance is one
long weapon on the centre line at the bow. Flak is one cluster on top. The top deck is otherwise bare iron plate with the
names of the dead chalked on it in frost white. The radiators are one orderly bank, never scattered spires. A low armoured
command block sits just ahead of the radiators. Two or three big engine bells, ember orange.

- **S1. Oath Blade, put in order.** The dagger plan kept. One bank of tall radiator fins on the rear third of the spine,
  graded short to tall like organ pipes, glowing ember. Clean deck forward of the command block to the lance.
- **S2. Blade and Hilt.** A sword seen from above: a long narrow blade for the forward two thirds, a wider cross-guard aft
  that holds the two gun decks and the radiator bank, and a short grip that is the engine block. The most readable plan in
  the fleet, and an oath sword is the Crusade's own image.
- **S3. Forge Blade.** The dagger with the radiators moved off the top: stacked glowing fins run along the lower flanks under
  the gun decks, like a forge seen through its grate. The top deck is entirely clean plate and chalk.

### Hegemony Navy

Ryan: a mix of all three; he does not love any. So one mix, and two ideas from the lore that round 1 did not try. The
Registry does not rule by force; it optimises. The horror is being a number in a perfect calculation.

**Grammar.** Pale grey, flush, exact; one continuous implant-blue line of light; no ornament. Length : beam : height about
4.5 : 1 : 0.5 (low and flat). The two heavy turbolasers are identical twin turrets, one on each flank amidships. The ion
cannon is the pair of prongs at the bow. Flak is one low cluster. One hangar door on a flank for the drones. A row of flat
rectangular blue-white engines.

- **H1. Kit Wedge (the mix).** A small sharp wedge at the bow carries the ion prongs and the command block; behind it,
  identical modules clip to a spine, each with one job that can be read from above (a turret module, a drone rack module, a
  reactor module), then an engine module. Drones sit in their rack, a few flying in a grid alongside.
- **H2. Monolith.** No wedge at all. A severe, slab-sided bar with square shoulders, like a server blade or a tombstone laid
  flat: nothing on it but the blue line down each flank, the two turrets, the prongs and the hangar slot. It should feel
  designed by something that does not care how it looks.
- **H3. Twin Rail.** Two long pale hulls side by side, joined by three cross-bridges, a ladder seen from above. Each rail ends
  in one ion prong; the turrets sit on the outer flanks; the drones hold a perfect grid in the gap between the rails.

### Ashfall Hullbreakers

Ryan: Scrap Brick and Pack Hunter are closest; Scrap for the capital, maybe.

**Grammar.** Predators that hunt by trail and sound. Soot and rust, plates stolen from every faction, chains, dim red light.
Length : beam : height about 3.5 : 1 : 0.9 (short and heavy). The heavy torpedo is a cluster of tubes in the blunt bow. The
two scatter batteries are one casemate on each flank. Flak is one cluster on top. Two hangar mouths low on the flanks.
Listening dishes and sniffer scoops sit on the brow; boarding claws fold under the bow. Three mismatched engines, one
larger. Lopsided in plating and add-ons only.

- **A1. The Pyre-Barge as Scrap Brick; the pack as Pack Hunters.** The capital is the heavy bolted brick, laid out as above.
  The escort beside it is a lean, forward-leaning Pack Hunter with its dishes and claws: same parts, different animal.
- **A2. Jaw Brick.** The brick, but the whole bow is the boarding gear: two heavy mandible blocks that open sideways to clamp
  a target, with the torpedo tubes in the throat between them. From above: a brick with a split bow.
- **A3. Trophy Hulk.** The brick built around its kills: a pale Hegemony module and a black Crusade blade section welded into
  the mass and chained, still in their old colours. One heavy blunt silhouette; the story is in the plating.

### The Glasswrights

Ryan: keep the prism theme, but make it an actual warship and spaceship.

**Grammar.** A silver warship built around a crystal. The prism is the ship's stored light and its main gun, so it lies on
the centre line and its forward end is the lance. Around it is a real hull of mirror-silver armour with a spine, a command
block, and engines. Length : beam : height about 5 : 1 : 0.8. The two forward pulsars are two lenses flanking the bow; the
third pulsar and the turret are two lens turrets on the upper centre line; flak is one cluster. The engines are three soft
white drive rings at the stern, no flame. Crystal is about a third of what you see, armour two thirds.

- **G1. Spinal Prism.** A long arrowhead hull with one six-sided crystal lying along its back from amidships to the bow, held
  by silver ribs like a blade in a clamp, its forward face the lance. Light moves inside it.
- **G2. Twin Prism.** A central silver hull with a crystal prism slung along each side as outriggers, three parallel lines
  from above, light arcing from both into a focusing lens at the bow.
- **G3. Cut Hull.** The hull itself is cut like a gemstone, a long kite shape in flat mirror facets, opaque armour with
  crystal showing only in veins, in the bow point and in a window over the light core. The most conventional warship of the
  three, and the easiest to build.

### Eclipse

Ryan: Fan is good; Annulus is distinct and could be the capital; a mix of Fan and Annulus; Crescent only if it makes sense as
a ship. The shade is armour held toward the enemy. The body shelters behind it. The green is a thin green-white line on plate
rims and the small bright core, never pooled.

**Grammar.** Violet-black overlapping shade plates. The doom weapon is the core, on the centre line, firing forward through
the shade. The two gauss turrets sit behind the shade's rim, one each side, firing over it. Flak is one cluster. The engine is
one thin ring of pale light at the stern, no bells. Length : beam : height about 3.5 : 1.6 : 0.6 for the fan (wide and flat).

- **E1. Ring and Fan (the mix).** The Tomb-ark is a fan-plated body whose bow passes through the hub of a great broken ring of
  shade plates standing upright ahead of it, like a shield boss; the core burns at the hub. Its escort is the fan alone. The
  ring faces forward and never lies flat.
- **E2. Crescent, made a ship.** One broad crescent shield lying flat across the bow with its horns swept forward, the body
  joined to the middle of its inner curve by the spine. A gauss turret near each horn. From above it is a crescent with a
  stem; nothing sits loose inside the curve.
- **E3. Double Arc.** Two broken arcs of plates, one inside the other and turned against each other, mounted upright on the
  bow of a short fan-plated wedge, the core between them. Lighter and more open than E1.

### The Chorus

Ryan: a mix of Leviathan and Bloom. Its capital is the Ninefold Maw and its matriarch has nine throats: the bloom is the mouth.

**Grammar.** A vast, smooth, eyeless body, dark olive hide with ochre ridges, lit from inside. Length : beam : height about
3.5 : 1 : 0.9. The two bioplasma weapons are throats at the bow. The tendril weapon is a cluster of long whips on the back.
The spore weapon is a field of pores along the upper flanks. Three brood sacs for the wings bulge low on the flanks. No
nozzles: pulsing vents and trailing membranes at the stern. No segments, no legs, no eyes, no metal.

- **C1. Bloom Mouth.** The leviathan's whole bow opens: thick petal-jaws folded shut in travel, spread wide around two glowing
  throats when it fires. The body behind is plain and heavy.
- **C2. Crowned Leviathan.** The bow is a blunt closed head with the two throats; a third of the way back a wide crown of
  membranes opens toward the light to feed, then the long body and trailing membranes.
- **C3. Nine Throats.** A broad-headed leviathan whose bow is a cluster of nine openings, two of them large and lit (the
  weapons), the rest feeding mouths, ringed by short petals. The most frightening head-on.
