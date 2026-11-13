# Design pack: Hegemony Navy (hegemony)

Issue 622. Everything a build-sheet designer needs to start the
Hegemony sheets with no other reading. Quotes are Ryan's words or the
Board's recorded reading of them, each with its FINDINGS id. Where
sources disagree, FINDINGS outranks the package docs and the faction
sheet, and the disagreement is flagged in section 8.

Status in one line: the H10 shape is picked and settled, but H10 is
not yet in the one concept style, and no Hegemony picture is a build
reference yet. R206 lists the faction as still open: "STILL OPEN:
Sunward flagship (S8 shape), Hegemony (H10 shape), Glasswrights (G15
shape)". The route is the shape-locked build sheet (the method of
issue 532), not another image round (R204 (3)).

## 1. The shape of record

- Accepted shape reference: hegemony_H10_sheet.jpg and
  hegemony_H10_beauty.jpg (in this folder; repo:
  contrib/muse/design/concept_round7_2026_11/). Picked by R198 (1):
  "HEGEMONY FLAGSHIP: H10 (contrib/muse/design/concept_round7_2026_11/hegemony_H10_beauty.jpg and _sheet.jpg); H11 is dropped."
- Dropped alternative: hegemony_H11_beauty.jpg (in this folder). Not
  a failure and not a reference: Ryan picked H10 over it (R198 (1)).
  It is filed here so the designer can see what was passed over.
- Failed concept: hegemony_H12_beauty.jpg (round 8b). Ryan: "You're
  right on h12" (R204). The Board's read, agreed: "HEGEMONY H12 FAILS
  as the Board read it (barely changed from H10, R198 still stands)".
  H12 changed almost nothing, which is the failure: the style gap
  below is still open.
- The style gap, in Ryan's words (R198): "H10 but I don't think it's
  in the same style as we see in hullbreakers. It's semi realistic but
  not quite." Sequence matters: R196 (3) approved round 7's realistic
  rendering as the look direction ("the realistic rendering of round 7
  (H10, H11) is approved as the look"), and R198 (2) then withdrew the
  claim that H10 already matches the style: "H10 is NOT yet in the
  concept style of R197". The sheet's style target is real plate with
  thickness and small fittings, a well-kept navy, never rusty
  (R198 (2)). Per R198 (3), style is judged by Ryan against
  corsair_A.jpg side by side; the Board does not declare a picture in
  style on its own.

## 2. Rulings that bind this faction's sheet designer

- R183 (1), the bow weapon. The old nose-gun gate wording is
  withdrawn. Hegemony's forward weapon is "a recessed emitter trench
  in a blunt bow face", and the general rule is "never a long barrel
  or prongs on the nose tip". Ryan's words behind it: "every ship has
  the guns directly on the nose which feels odd".
- R183 (3), the hull. "Hegemony gets heavy: about 3 : 1, a thick
  wedge, thick rails, big shoulder turrets." Ryan's words: "Hegemony
  also seems a bit too fragile and slender?"
- R185 (4), the guns. Ryan: "The hegemony guns look weird and almost
  cartoonish". The fix: "low mounts sunk into the armour, short thick
  barrels". "Big" in R183 (3) is footprint and mass on the shoulder;
  R185 (4) fixes the profile: low, sunk, short-barrelled. The sheet
  carries both: big shoulder positions, low mount profile.
- R185 (5), the naval pass (gate line 11), every ship: "no boat
  profile, a worked belly, no deck house, no ship's prow, nothing
  hanging off, no battleship turrets". H8's named tells were its
  turrets and bare belly; the belly must be worked.
- R192 (3), the design stands, the picture was wrong. "Hegemony is
  better but maybe it's just the art style that's throwing me off
  compared to the others. It reads as cartoonish" (Ryan). The ruling:
  "the H9 design stands; the picture is wrong, not the ship". H10
  carries that design forward; the sheet fixes presentation, not
  geometry, except where R207 requires.
- R204 (2), colour. "COLOUR IS FIXED IN THE BUILD, NOT IN IMAGE
  ROUNDS": palette corrections go in the sheet's colour notes, never
  a reason to loop a picture.
- R207, the builder's charter. The concept guides; the builder
  corrects what does not work as a built object and lists every
  change on the sheet. Ryan: "Opus should have final decision making
  as the designer. It should follow all of the other guidance we've
  discussed across the faction guides, lore, playbooks, etc. Bring
  questions to me as needed."

## 3. Shared build rules (all three factions in this delivery)

- R203: "no ship is built until it also has a build sheet that passes
  standard.md (true side and top of one design at one scale, plus
  underside and bow-on, the length from the game data, a scale bar, a
  feature table that outranks the pictures)".
- R213: "guns must come from the hull's data.js weapon slots as
  batteries that make sense (paired port and starboard, the same mount
  family per battery, arcs that fit the slot)", and the model must
  carry the concept's massing, tiers and elevation, checked against a
  side view.
- R214 and R215, destruction and insides: "blown apart, never sliced
  (R186; issues 462, 484)", break lines by the faction's rule (below), breach
  anchors by class and faction (issue 363); insides comprehensive
  through the whole hull.
- R217: "Part shape is modelled at the build sheet (engines as bells
  with throats and rings, guns with base, mantlet, breech and muzzle,
  launch tubes with depth, rocket racks with cells)", plus the fit
  check: no part inside another, in a gun's arc, in an exhaust cone or
  blocking a launcher; a clash left in is blocking.
- R218: whole-ship fidelity: a parts inventory from the concept per
  region, one detail level across the whole ship, a per-cell inventory
  tick beside the concept on every sheet.
- R221: "every part has a job; weapons are each faction's own, from
  the lore and data.js weapon ids; a gun in another weapon's lane or
  backblast is a clash".
- R222: a turret may turn aft only to follow a target its rules arc
  allows; at rest no gun points backward.
- R224: every part type carries the hull's detail density within
  25 percent, measured per sheet.
- R226: "a machine (gun, turret, casemate, launcher, engine, thruster,
  claw, sensor mast) never crosses a seam; the seam moves or kinks
  around it so it rides whole with one piece. Structure (plating,
  frames, ribs, rails, openings such as launch bays) may cross and
  tears."
- R229: build and judge from the whole concept and every sheet view
  first; crops only after the whole view matches.
- R230: "a ship may run a little longer than its class default to
  carry them"; "The Board is told before any increase over about
  15 percent."

## 4. Lore and kit

- In one line (factions.md): "a pale wedge with a line of blue
  light".
- Who they are (package review doc): the fleet of the Registry, a
  vast intelligence at Meridian that links every citizen, ship and
  officer, plans their careers and keeps losses within acceptable
  limits. Hegemony shield and ion technology comes from a captured
  core. Ship prefix HNS. Full lore:
  contrib/opus/compute/lore_bible_r8.md (the lore bible named in
  R207); the faction package at
  contrib/muse/design/faction_packages_2026_11/pkg_hegemony_navy.md
  and its review page in the same folder's review/ subfolder.
- Look: heavy thick wedge on twin rails, about 3 : 1, symmetric, the
  same parts repeated at different sizes across the fleet. Machined,
  modular, horizontal: flush panels, straight seams, repeated modules.
  One low sensor fin, not a tower.
- Colours: pale grey, steel-blue trim, implant-blue light strips that
  pulse in time across the whole fleet.
- Engines: a flat row of rectangular blue-white nozzles.
- Present placeholder faults to design away from (factions.md):
  H7 to H10 read as yachts or submarines (a tall sail-like tower,
  stepped cabin tiers); H4_11 is a sea battleship with a mast tower.
  Keep the wedge and the blue lines; flatten the superstructure into
  one low fin.

## 5. Classes and guns (data.js; lengths from hull_table.gd CLS_LEN)

Weapon display names: laser "Plasma cannon", turbo "Plasma lance",
hturbo "Heavy plasma lance", ion "Ion cannon", flak "Picket lasers".

- Hegemony picket, frigate, 6.5: Plasma cannon (forward), Picket
  lasers (turret); ability evasive.
- Cordon destroyer, 9.5: Ion cannon (forward), Plasma lance (turret);
  ability ionpulse.
- Vanguard cruiser, 14.5: Plasma lance (turret), Plasma lance
  (turret), Ion cannon (forward); ability launch, hangar 1.
- Dominion dreadnought, battleship, 21.0 (the H10 shape's class):
  Heavy plasma lance (port), Heavy plasma lance (starboard), Ion
  cannon (forward), Picket lasers (turret); ability launch, hangar 1.
- The Iron Mandate, super-dreadnought, 31.0 (boss): Heavy plasma
  lance (port), Heavy plasma lance (starboard), Plasma lance
  (turret), Ion cannon (forward), Picket lasers (turret); ability
  nova. Note: no hangar in data.js, so no drone bays on this class,
  whatever the general faction line says (section 8).

The forward Ion cannon on the destroyer, cruiser, battleship and
super-dreadnought is the recessed emitter trench in the bow face
(R183 (1)), never a barrel or prongs. The turret slots are the
shoulder batteries: plasma lances on the low sunk mounts of R185 (4).

## 6. How it breaks

In modules (factions.md): "It gives way at the bulkhead rings between
modules, like a spine coming apart, the rims torn and scorched
(R186)". Inside: white corridors, blue emergency light, racks of
identical equipment. Breach anchors sit on the module joints. Base
anchor counts by class (issue 363, via R215): frigate 2, destroyer 3,
cruiser 4, capital 6, flagship 8. Under R226, turrets, launchers and
the sensor fin are machines and ride whole with their module; the
module structure tears at the rings.

## 7. Must-keep and must-avoid

Must-keep:
- The H10 wedge: heavy, thick, twin rails, about 3 : 1, symmetric
  (R198 (1); R183 (3)).
- The ion weapon as a recessed emitter trench in a blunt bow face
  (R183 (1)).
- Big shoulder positions with low sunk mounts and short thick barrels
  (R183 (3); R185 (4)).
- One low sensor fin, never a tower (factions.md).
- Pale grey, steel-blue trim, implant-blue strips pulsing in time
  fleet-wide (factions.md).
- Identical parts repeated across the fleet; flush panels, straight
  seams, repeated modules (factions.md).
- A flat row of rectangular blue-white engine nozzles (factions.md).
- Real plate with thickness and small fittings; a well-kept navy,
  never rusty (R198 (2)).

Must-avoid:
- Rust, asymmetry, ornament, warm light (factions.md).
- Prongs or a long barrel on the nose tip (R183 (1); the review doc's
  stale wording, section 8).
- Tall round turrets with long thin barrels; cartoonish guns
  (R185 (4)).
- Yacht decks, stepped cabin tiers, a conning tower, a tall mast; the
  submarine read (factions.md).
- Slender or fragile proportions (R183, Ryan's words).
- A bare, unworked belly (R185 (5)).
- H11 as the shape (dropped, R198 (1)) and H12 as anything but a
  style warning (R204 (3)).
- Any colour fix loop: colour is set in the build (R204 (2)).

## 8. Stale words to ignore

- The package review doc describes Hegemony ships with "ion prongs
  at the bow". That contradicts R183 (1) directly and is stale: the
  bow weapon is the recessed emitter trench. The same doc's "small
  drone escorts" is loose wording for the flank drone bays.
- factions.md says "Small drone bays in the flanks" as a general
  line. data.js gives a hangar only to the Vanguard (1) and the
  Dominion (1); the picket, the Cordon and The Iron Mandate have
  none. Under R213, fittings come from the data: bays only where a
  hangar slot exists.
- factions.md's "present concepts" note lists H10 among the hulls that
  read as yachts or submarines. That note predates the R198 pick: the
  read was about the early concepts' towers and tiers, and the sheet
  route designs them away; H10's wedge is the accepted shape.
- The review doc's campaign questions (its questions 10 to 12: the
  Nemesis, the Registry in battle, refusing an order) are campaign
  decisions with chair picks already printed. They are not sheet
  questions and do not block this route.

## 9. Questions for Ryan (chair picks marked)

1. The Iron Mandate. The super-dreadnought (31.0) is a boss class in
   data.js with no concept of its own; the H10 shape belongs to the
   Dominion (21.0). Does this route derive The Iron Mandate from H10
   at scale?
   A. Yes: derive it from the Dominion sheet, same parts larger,
   flagged as derived on its sheet. (Chair pick.)
   B. No: leave it out until it gets its own design pass.
2. Drone bay doors. The Vanguard and the Dominion carry hangar 1. How
   do the flank bays read on the intact ship?
   A. Flush armoured doors, a seam line only, opening in the break
   state. (Chair pick: keeps the flush-panel language of the faction
   sheet.)
   B. Visible open bay mouths, like the Hullbreaker carrier's.
3. Style sign-off. H10's open item is style, and R198 (3) makes the
   style call Ryan's, judged against corsair_A.jpg.
   A. Ryan judges the H10 build sheet beside corsair_A.jpg before the
   sheet is final. (Chair pick, per R198 (3).)
   B. The sheet proceeds on the Board's eye and style is judged on
   the painted build.
