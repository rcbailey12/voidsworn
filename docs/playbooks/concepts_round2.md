# Ship concepts, round 2: design sheets and the review gate

Issue 405, ships track. Written by the Board (Fable 5.2), Nov 11 2026, after Ryan's review of the eighteen round 1 direction
pictures (contrib/muse/design/concept_directions_2026_11/). Read docs/playbooks/factions.md first: this page narrows it.

## Image rounds now (Nov 11 2026, R192 to R207): read this first

The gate below still holds for every picture. Rounds 3 to 8 added these rules for how a picture is made and judged:

1. **One concept style (R197).** Ryan: "Generally that style and tone is exactly how we should look at the concepts for our
   ships across fsctions. Pretty realistic and detailed to help with the builds. We should merge what we have already today
   for the factions to match that style of concept so we avoid the same issue we saw with hegemony cartoon since this style
   is how it should look in game." The reference is contrib/muse/design/concept_directions_2026_11/corsair_A.jpg: a
   photograph of a real large built object, many small plates and fittings that give scale, real materials, working
   machinery. Each faction keeps its own palette and character. A picture that reads as an illustration, a toy or a cartoon
   fails, whatever its shape. This is gate line 13.
2. **Ryan judges the style, side by side (R198).** Ryan: "It's semi realistic but not quite." The Board's eye proved looser
   than his: show the picture beside corsair_A.jpg and let him say; never declare a picture in style.
3. **Edit the liked picture; never redescribe it (R192).** Ryan: "Can we use our prior concept from before all these rounds as
   the base? Or just use that?" Six Hullbreaker rounds were lost because a liked picture was described in words and redrawn,
   each copy losing more. When Ryan likes a picture, the next job edits that picture (image to image, the changes listed,
   everything else untouched), and a result that drifted in mass, silhouette or character fails however good it looks.
4. **Find the picture he means before using it (R196).** The Board once took "our prior concept" to mean the wrong picture
   and three rounds were drawn against it. Show the picture with its code name and get his yes first.
5. **Colour alone never sends a picture back (R204).** Ryan: "we can fix color ourselves rather than get stuck in a loop with
   color fixes with image generation." Colour is set in the build sheet's colour notes and the paint stage.
6. **When image to image cannot reach the style without breaking the shape, stop** (R204 (3), R206 (2): H12, S10 and G18).
   The shape goes through the Opus build-sheet route: a blockout locked to the liked shape, dressed in the style.
7. **A filed Muse issue is never edited once Ryan may have started it (R200).** Rey keeps to the list it read; new scope is
   a new issue (round 8b was split from round 8 for this reason).
8. **The picture is not the end (R203, R207).** An accepted picture sets the look; the build sheet (standard.md, made by an
   Opus worker, R205) is what is built from, and the builder corrects what would not work as a built object (Ryan: "Use it
   to guide, not the very final exact design"). docs/playbooks/ships.md carries the build side.
9. **The Glasswrights' first rule (R192, R196)**: "artistic, thoughtful in creation and looking to create beauty with
   function, even in these warships"; lenses grown into one continuous skin, "like a work of art or blown glass, though able
   to rotate". docs/playbooks/factions.md holds the faction sheets and the current picks.

Everything from here down is the round 2 record: the gate is live. The per-faction grammars and variations are history and
moved to docs/archive/playbooks/concepts_round2_grammars.md (the current picks are in docs/playbooks/factions.md).

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
   the Chorus a grown body with no straight line; the Glasswrights a leaf of cut glass on a silver spine and rim (G13, carried
   by G15, R192, R196). A feature that only shows from the side or
   the front (an upright ring, lenses standing across the axis) is lost under the battle camera: lay it flat or turn it up.
9. **Proportions per class.** Length : beam : height is a starting point for the drawing, not identity (RULEBOOK 4.8; R183's
   3 : 1 overrode Hegemony's 4.5 : 1). The round 2 figures are in the archived design sheets
   (docs/archive/playbooks/concepts_round2_grammars.md). The escort is a smaller ship of the same grammar with fewer parts,
   never the capital shrunk.
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
13. **The one concept style (R197).** Realistic and detailed, judged by Ryan beside corsair_A.jpg (R198). See the top of this
    page.

## Round 2 drawing method and design sheets (archived)

How round 2 was drawn and the per-faction grammars and variations moved to
docs/archive/playbooks/concepts_round2_grammars.md on Nov 11 2026 (history: the current picks are in docs/playbooks/factions.md).
