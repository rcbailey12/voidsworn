# Design pack: The Glasswrights (ithar)

Issue 622. Everything a build-sheet designer needs to start the
Glasswright sheets with no other reading. Quotes are Ryan's words or
the Board's recorded reading of them, each with its FINDINGS id. Where
sources disagree, FINDINGS outranks the package docs and the faction
sheet, and the disagreement is flagged in section 8.

Status in one line: the G15 shape is liked and settled, its lenses are
not yet what the lore requires, and no Glasswright picture is a build
reference yet. R206 lists the faction as still open: "STILL OPEN:
Sunward flagship (S8 shape), Hegemony (H10 shape), Glasswrights (G15
shape)". The route is the shape-locked build sheet (the method of
issue 532), not another image round (R206).

## 1. The shape of record

- Accepted shape reference: ithar_G15_sheet.jpg and
  ithar_G15_beauty.jpg (in this folder; repo:
  contrib/muse/design/concept_round7_2026_11/). Ryan (R196): "I
  really like g15." G15 carries the G13 base (R192): "a leaf of cut
  glass lit from inside, a silver spine and rim".
- What is still open on G15 is its lenses. Ryan (R196): "The lenses
  are a littlenweird and don't feel naturally ingrained into the ship
  like you'd expect with their lore. It should feel almost seamless
  and less bolted on. Like a work of art or blown glass, though able
  to rotate, etc." The sheet's lens work is specified in R196 (2):
  "no bolted-on pod, bracket, ring mount or visible seam between lens
  and ship", one continuous skin of glass and metal, still able to
  turn. The factions.md table line "its lenses are grown into the
  hull" states the target, not G15's current state.
- Failed concept: ithar_G17_beauty.jpg (round 8). Not passed. The
  Board's read (R201): G17's "lenses became clear bubbles and globes
  that no longer point forward (R192)".
- Failed concept: ithar_G18_beauty.jpg (round 8c). Not passed (R206):
  "the lenses read as bolted-on cream tubes, not grown glass, against
  R196". Both failures are the same failure from two sides: a lens
  that sits on the ship instead of growing in it, and a forward lens
  that does not visibly point forward.

## 2. Rulings that bind this faction's sheet designer

- R192 (1), the first rule, ahead of any shape rule. Ryan: "It doesn't
  match with how I envision the glasswrights being artistic,
  thoughtful in creation and looking to create beauty with function,
  even in these warships." The ruling: "Every structural part is
  shaped with care and is also the ornament; the weapons are the
  centrepieces and must make sense (forward lenses that visibly point
  forward, a top lens that can swing, small guns made by the same
  hand). This is now the Glasswrights' first rule, ahead of any shape
  rule."
- R196 (2), grown-in lenses, quoted in section 1. This is the look
  rule of R192 applied to the weapons.
- R183 (5), the fresh start. Ryan: "Glasswrights looks too basic. I'm
  not sure what's going on with glasswrights but I think we need to
  scrap it and start from fresh with the faction lore and context".
  The ruling: "every crystal and prism route is scrapped (rounds 1 to
  4). Fresh start from the lore: optical engineers, a precision
  instrument built as a warship, polished silver and clear glass,
  stored light inside, lens weapons, fast and fragile." No crystal
  object on a hull and no hull shaped like a crystal (the faction
  sheet, citing R180 and R183 (5)).
- R183 (1), the forward weapon. Glasswrights build theirs as "twin
  lens apertures in the bow shoulders", under the general rule
  "never a long barrel or prongs on the nose tip". See question 1:
  the faction sheet's singular "bow optic" wording and this ruling
  need one reading on the sheet.
- R185 (2), the direction line. The Mirror Deck (G11) made prismatic
  is the line that runs G11 to G13 to G15: a lens in section,
  cut-glass tiles over stored light. The Unfinished (G10) is dropped:
  Ryan: "It just kinda looks like a satellite?" Note the name
  collision in section 5.
- Ryan, Nov 10, on the earlier vaned concepts: "I like the idea-ish
  but it comes off looking as almost insect like. I think we go with
  a different idea but in a similar vane." The paired wing and petal
  vanes are gone for good (factions.md).
- R204 (2), colour. "COLOUR IS FIXED IN THE BUILD, NOT IN IMAGE
  ROUNDS".
- R207, the builder's charter. The concept guides; the builder
  corrects what does not work as a built object (unconnected parts,
  odd proportions, forbidden details) and lists every change on the
  sheet. Ryan: "Opus should have final decision making as the
  designer."

## 3. Shared build rules (all three factions in this delivery)

- R203: "no ship is built until it also has a build sheet that passes
  standard.md (true side and top of one design at one scale, plus
  underside and bow-on, the length from the game data, a scale bar, a
  feature table that outranks the pictures)".
- R213: "guns must come from the hull's data.js weapon slots as
  batteries that make sense (paired port and starboard, the same mount
  family per battery, arcs that fit the slot)", and the model must
  carry the concept's massing, tiers and elevation, checked against a
  side view. For this faction the batteries are lens groups: the
  slots in section 5 say how many optics of each kind a hull carries,
  and R192 requires them made by the same hand.
- R214 and R215, destruction and insides: "blown apart, never sliced
  (R186; issues 462, 484)", break lines by the faction's rule (below), breach
  anchors by class and faction (issue 363); insides comprehensive
  through the whole hull.
- R217: part shape is modelled at the build sheet, with the fit
  check: no part inside another, in a gun's arc, in an exhaust cone or
  blocking a launcher; a clash left in is blocking. For this faction
  the modelled parts are the optics: each lens gets its grown seat,
  its rotation and its beam lane on the sheet.
- R218: whole-ship fidelity: a parts inventory from the concept per
  region, one detail level across the whole ship, a per-cell inventory
  tick beside the concept on every sheet.
- R221: "every part has a job; weapons are each faction's own, from
  the lore and data.js weapon ids; a gun in another weapon's lane or
  backblast is a clash". A lens in another lens's beam lane is the
  local form of that clash.
- R222: a turret may turn aft only to follow a target its rules arc
  allows; at rest no gun points backward. Grown lenses rotate inside
  their arc and rest forward.
- R224: every part type carries the hull's detail density within
  25 percent, measured per sheet.
- R226: "a machine (gun, turret, casemate, launcher, engine, thruster,
  claw, sensor mast) never crosses a seam; the seam moves or kinks
  around it so it rides whole with one piece." A large optic is a
  machine under this rule, which is exactly the faction's own break
  rule: each large optic is its own break piece (section 6).
- R229: build and judge from the whole concept and every sheet view
  first; crops only after the whole view matches.
- R230: "a ship may run a little longer than its class default to
  carry them"; "The Board is told before any increase over about
  15 percent."

## 4. Lore and kit

- In one line (factions.md): "an instrument for light, built as a
  warship".
- Who they are (factions.md, lore 6.1): "the Starwrights who stayed
  flesh; the finest optical engineers who ever lived. They built the
  collectors, mirrors and beam lines that carried a star's light
  across a system, and watched that machine kill their sun." Full
  lore: contrib/opus/compute/lore_bible_r8.md (the lore bible named
  in R207); the faction package at
  contrib/muse/design/faction_packages_2026_11/pkg_the_glasswrights.md
  and its review page in the same folder's review/ subfolder.
- Shape language: a leaf of cut glass lit from inside on a silver
  spine and rim. Rigid, symmetric about the long axis. Nothing that
  reads as a wing, a petal, a sail or a body.
- Colours: clear glass and polished silver, a rainbow fringe on cut
  edges only, stored light glowing deep inside. The review doc's
  "pale green white" for the stored light is a colour note for the
  build (R204 (2)), not a sheet decision.
- Guns sit on the optical axis. The prism lance is the hull's stored
  light let out through the bow optic: a white core with a rainbow
  fringe. Smaller grown lenses along the hull are the secondary guns.
- Engines: no flame. A soft white bloom at the stern optic.

## 5. Classes and guns (data.js; lengths from hull_table.gd CLS_LEN)

Weapon display names: shard "Prism shards", pulsar "Prism lance",
startorp "Star torpedo", turret "Needle beam", flak "Mirror veil".

- Glasswright sliver, frigate, 6.5: Prism shards (forward); ability
  blink.
- Glasswright lancet, destroyer, 9.5: Prism shards (forward), Star
  torpedo (forward); ability blink.
- Glasswright prism, cruiser, 14.5: Prism lance (forward), Prism
  lance (forward), Needle beam (turret); ability surge.
- Glasswright aperture, carrier, 16.5: Prism lance (forward), Needle
  beam (turret); ability launch, hangar 2.
- The Unfinished, Ark, 26.0 (boss; the flagship class, G15's class):
  Prism lance (forward), Prism lance (forward), Prism lance
  (turret), Needle beam (turret), Mirror veil (turret); ability
  surge.

Name collision, flagged so it costs nobody a round: data.js names the
Ark class "The Unfinished". The dropped G10 concept was also called
The Unfinished (R185 (2), "a satellite"). They are not the same thing:
the class name stands, the dropped concept stays dropped, and nothing
from G10's open-frame look enters these sheets.

## 6. How it breaks

It shatters (factions.md): "Optics crack and shear off as whole panes
or rings, then the hull snaps at a lens bay and the stored light
spills out." One fewer breach anchor than the base count; each large
optic is its own break piece. Base counts by class (issue 363, via
R215): frigate 2, destroyer 3, cruiser 4, carrier 6, flagship 8; the
Glasswright counts are therefore frigate 1, destroyer 2, cruiser 3,
carrier 5, Ark 7.

## 7. Must-keep and must-avoid

Must-keep:
- The first rule: beauty with function; every structural part shaped
  with care and also the ornament; the weapons are the centrepieces
  (R192 (1)).
- G15's leaf of cut glass on a silver spine and rim, lit from inside
  (R192; R196).
- Lenses grown in: one continuous skin of glass and metal, no pod,
  bracket, ring mount or visible seam, still able to rotate
  (R196 (2)).
- Forward lenses visibly pointing forward (R192; R201's failure
  read).
- Clear glass, polished silver, rainbow fringe on cut edges only,
  stored light deep inside (factions.md).
- Guns on the optical axis, from the data.js slots; the prism lance
  as stored light through the bow optic, white core, rainbow fringe
  (factions.md; data.js).
- No flame anywhere: a soft white bloom at the stern optic
  (factions.md).
- Shatter breaks: whole panes and rings, hull snaps at a lens bay,
  one fewer anchor, each large optic its own piece (factions.md;
  R226).

Must-avoid:
- Paired wings or petals, sails, masts and rigging, anything
  insect-like (Ryan, Nov 10; factions.md).
- A crystal object on a hull, or a hull shaped like a crystal
  (R183 (5)).
- Bolted-on lenses in any form: pods, brackets, rings, seams, cream
  tubes (R196; R206 on G18).
- Clear bubbles and globes that no longer point forward (R201 on
  G17).
- The Unfinished concept's open frame (a satellite) and the plain
  silver tube of the dropped Racing Hull route (R185 (2)).
- Rust, smoke, flame (factions.md).
- A boat profile or any naval tell (R185 (5), the naval pass: "no
  boat profile, a worked belly, no deck house, no ship's prow,
  nothing hanging off, no battleship turrets").
- New concepts: this route draws no new shape, it sheets G15 (issue
  622's brief; R206).

## 8. Stale words to ignore

- The package review doc describes Glasswright ships as "clear
  crystal and silver hulls, faceted edges splitting light into
  rainbow fringes, mirrors and lenses that turn to catch light,
  crystal vanes, stored light glowing deep inside". "Crystal vanes"
  and the crystal hull wording contradict R183 (5) and the faction
  sheet ("Nothing that reads as a wing, a petal, a sail or a body")
  and are stale. The grown-lens and rainbow-fringe parts of that
  sentence still stand.
- factions.md's flagship table says G15's "lenses are grown into the
  hull". R196 says they are not yet (section 1). The table states the
  target as the state; this pack carries the correction.
- The review doc's campaign questions (its questions 1 to 3: the
  Nemesis, the portrait look, Astra unthrottled) are campaign and
  portrait decisions with chair picks already printed. They are not
  sheet questions and do not block this route. The portrait rulings in
  that doc (glass in the body, colour as an emotion tell) govern
  portraits, not hulls.

## 9. Questions for Ryan (chair picks marked)

1. The bow optic: one or two? R183 (1) gives the Glasswrights "twin
   lens apertures in the bow shoulders"; the faction sheet describes
   the prism lance as stored light let out "through the bow optic",
   singular. data.js gives the prism and the Ark two forward Prism
   lance slots each.
   A. Twin apertures in the bow shoulders, matching R183 (1) and the
   two forward slots; the two beams read as one lance on the axis.
   (Chair pick.)
   B. One central bow optic; the second forward slot is a shoulder
   lens that fires with it.
   C. Twin apertures that merge into a single beam before leaving the
   hull.
2. G15 at Ark scale. G15 is the flagship's shape and the Ark is
   26.0 long. Do the other four classes derive from G15's language,
   or does the Ark get its own sheet design first?
   A. G15's language scales: the Ark sheets from G15, the four
   smaller classes derive as smaller instruments of the same make.
   (Chair pick.)
   B. The Ark gets a bespoke sheet design from G15's language before
   any class derives.
3. The aperture carrier's hangar 2. A Glasswright hull has no bay
   tradition in any source. Where do its wings launch from on the
   sheet?
   A. Grown lens bays in the flanks: apertures that open like the
   ship's other optics. (Chair pick: keeps every opening an optic,
   per R192.)
   B. A stern aperture under the engine bloom.
   C. No visible bays; the hangar is internal and only the break
   state shows it.
