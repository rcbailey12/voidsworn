# Design pack: Sunward Crusade (voidsworn)

Issue 622. Everything a build-sheet designer needs to start the Sunward
sheets with no other reading. Quotes are Ryan's words or the Board's
recorded reading of them, each with its FINDINGS id. Where sources
disagree, FINDINGS outranks the package docs and the faction sheet, and
the disagreement is flagged in section 8.

Status in one line: the S8 shape is settled in direction, the style is
not reached, and no Sunward picture is a build reference yet. R206
lists the faction as still open: "STILL OPEN: Sunward flagship (S8
shape), Hegemony (H10 shape), Glasswrights (G15 shape)". The route is
the shape-locked build sheet (the method of issue 532), not another
image round (R206).

## 1. The shape of record

- Accepted shape reference: voidsworn_S8_sheet.jpg (in this folder;
  repo: contrib/codex/design/concept_round5_2026_11/). The forked prow
  is settled in direction by R185 (1): Ryan's words were "Agree with
  other takes", and the ruling records that this "settles SUNWARD S8
  (forked prow)". S8 is the flagship's shape; the
  flagship class in data.js is the Daybreak-class dreadnought.
- Failed concept: voidsworn_S9_beauty.jpg (round 8). Not passed. The
  Board's read, not disputed by Ryan (R201): "S9 still smooth and
  drawn, lighter grey, blue added".
- Failed concept: voidsworn_S10_beauty.jpg (round 8c). Not passed
  (R206): "still close to the smooth drawing". Both failures are style
  failures, not shape failures: the S8 shape stands, its dressing in
  the one concept style does not exist yet. Closing that gap is this
  route's job.

## 2. Rulings that bind this faction's sheet designer

- R183 (1), the forward weapon. The old gate wording ("the forward gun
  is the largest object on the bow") is withdrawn. New rule: "each
  faction builds its forward weapon its own way, never a long barrel
  or prongs on the nose tip (Sunward a lance recessed in a split
  prow...)". Ryan's words behind it: "Sunward is getting there but
  again same giant gun directly on nose."
- R183 (2), outline. "no two factions share an outline from above, and
  anything that carries identity must show under the battle camera."
  The blade outline is Sunward's identity; keep it unmistakable from
  above.
- R185 (5), the naval pass (gate line 11), every ship: "no boat
  profile, a worked belly, no deck house, no ship's prow, nothing
  hanging off, no battleship turrets". The same ruling notes "The
  naval pass applies to every later sheet, the Sunward and Eclipse
  fleets first."
- R192 (3) and R206, style. One render style for every faction:
  "realistic materials, wear, small-scale detail, restrained light"
  (R192). S9 and S10 failed against it (section 1). The sheet dresses
  S8 in that style; it does not redraw the shape.
- R204 (2), colour. "COLOUR IS FIXED IN THE BUILD, NOT IN IMAGE
  ROUNDS": a picture whose shape and detail are right is not sent back
  for colour alone. Palette corrections go in the sheet's colour
  notes.
- R207, the builder's charter. Ryan: "use the concept pictures to
  guide the build. Where there are gaps like eclipse rings not all
  having structural connections or if guns look oddly proportioned or
  something similar that, you should build differently." And: "Opus
  should have final decision making as the designer. It should follow
  all of the other guidance we've discussed across the faction guides,
  lore, playbooks, etc. Bring questions to me as needed." Every
  departure from S8 is listed on the sheet with its reason.

## 3. Shared build rules (all three factions in this delivery)

- R203: "no ship is built until it also has a build sheet that passes
  standard.md (true side and top of one design at one scale, plus
  underside and bow-on, the length from the game data, a scale bar, a
  feature table that outranks the pictures)".
- R213: "guns must come from the hull's data.js weapon slots as
  batteries that make sense (paired port and starboard, the same mount
  family per battery, arcs that fit the slot)". The same ruling
  requires the model to carry the concept's massing, tiers and
  elevation, checked against a side view.
- R214 and R215, destruction and insides: "blown apart, never sliced
  (R186; issues 462, 484)", break lines placed by the faction's rule (below) and
  breach anchors by class and faction (issue 363); insides are
  comprehensive through the whole hull, and "interiors stay hidden
  until a piece breaks, so they cost memory and not frame time".
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
  carry them"; for A17 the ruling keeps the hull unchanged and
  extends the arms to their share. "The Board is told before any
  increase over about 15 percent."

## 4. Lore and kit

- In one line (factions.md): "a black iron blade with burning spires".
- Who they are (package review doc): the Vesper Reach made into a
  fleet, forty odd frontier systems the Hegemony wrote off when their
  stars began to dim, bound by one oath to stop the Siphoning. They
  chalk every name on the hull because the Registry deleted theirs.
  Full lore: contrib/opus/compute/lore_bible_r8.md (the lore bible
  named in R207); the faction package at
  contrib/muse/design/faction_packages_2026_11/pkg_sunward_crusade.md
  and its review page in the same folder's review/ subfolder.
- Look: long narrow dagger or spearhead, widest at the stern third,
  symmetric. A row of tall radiator spires along the spine, tallest
  amidships; the spires shed the reactor's heat and glow ember. They
  are radiators, not steeples: no crosses, no statues.
- Colours: black iron, frost-white markings, bright ember (windows,
  engines, spires). Never rust, never blue light.
- Engines: two to four large bells, ember orange, deep-set.
- Present placeholder faults to design away from (factions.md):
  V1b_r_23 is a cathedral on a boat hull; keep its mass and spire
  cluster, redraw the hull as a blade. V14_23 has wheel-like pods and
  red light; pods become radiator blocks, light is ember orange.

## 5. Classes and guns (data.js; lengths from hull_table.gd CLS_LEN)

Weapon display names: autocannon "Sear repeater", battery "Sear
battery", hbattery "Heavy sear broadside", turret "Sear turret",
lance "Oath lance", torp "Cinder torpedo", flak "Spark flak".

- Warden-class frigate, 6.5: Sear repeater (forward), Spark flak
  (turret); ability evasive.
- Harrow-class destroyer, 9.5: Cinder torpedo (forward), Sear turret;
  ability reload.
- Vigil-class cruiser, 14.5: Sear battery (port), Sear battery
  (starboard), Oath lance (forward); ability focus.
- Hearth-class carrier, 16.5: Sear turret, Spark flak (turret);
  ability launch, hangar 2.
- Bastion-class battleship, 21.0: Heavy sear broadside (port), Heavy
  sear broadside (starboard), Oath lance (forward), Spark flak
  (turret); ability surge.
- Daybreak-class dreadnought, 27.0, the flagship class (S8's class):
  Heavy sear broadside (port), Heavy sear broadside (starboard), Sear
  turret, Spark flak (turret); ability nova; unique. Note: the
  dreadnought has no lance slot; see question 1.

Broadside decks are the faction's gun language: long straight rows of
many small, evenly spaced ports along both flanks (factions.md), and
under R213 the ports on the sheet are the data.js batteries above,
drawn as that row, not invented extras.

## 6. How it breaks

Along the gun decks (factions.md): "The hull splits lengthwise between
deck rows, and the spire line snaps off as one piece." Inside: iron
decks, ember-lit, gun crews' galleries. Breach anchors sit on the
broadside deck line, evenly spaced. Base anchor counts by class (issue
363, via R215): frigate 2, destroyer 3, cruiser 4, carrier 6, capital
6, flagship 8. Under R226 the deck's guns are machines: the seam kinks
around each gun so it rides whole with its piece.

## 7. Must-keep and must-avoid

Must-keep:
- The S8 forked-prow blade as the shape; widest at the stern third,
  symmetric (R185 (1); factions.md).
- The forward weapon as a lance recessed in the split prow where the
  class carries a lance (R183 (1); data.js Vigil and Bastion).
- Radiator spires in a row, tallest amidships, glowing ember; no
  crosses, no statues (factions.md).
- Black iron, frost-white markings, bright ember light only
  (factions.md).
- Broadside gun decks in long straight rows, from the data.js slots
  (factions.md; R213).
- Two to four big ember engine bells, deep-set, modelled with throats
  and rings (factions.md; R217).
- Plate with rivet lines; wear and small-scale detail in the one
  render style (factions.md; R192).
- Breaks along the gun decks, spire line off as one piece, anchors on
  the deck line (factions.md; R226).

Must-avoid:
- Rust (that is the Hullbreakers) and blue light (S9's failure, R201)
  (factions.md).
- A long barrel or prongs on the nose tip; a giant gun directly on the
  nose (R183 (1)).
- A ram prow shaped like a ship's stem; cathedral windows so literal
  the ship reads as another game's (factions.md).
- The smooth, drawn look of S9 and S10 (R201; R206).
- A boat profile, deck house, stepped decks, anything hanging off
  (R185 (5)).
- Wheel-like pods and red light (V14_23's faults, factions.md).
- An outline from above that another faction could share (R183 (2)).
- Guns copied from a picture's visible side and invented on the far
  side (R213's named failure).

## 8. Stale words to ignore

- factions.md says the guns sit "in broadside rows along both flanks,
  plus one heavy pair at the bow". R183 (1) and data.js supersede the
  bow half of that line: the forward weapon is the Oath lance in the
  split prow on the classes that carry one. The faction sheet has not
  been corrected; this pack carries the correction.
- The package review doc's campaign questions (its questions 7 to 9:
  the Nemesis, the Roll of Vesper screen, captured hulls) are campaign
  decisions with chair picks already printed. They are not sheet
  questions and do not block this route.

## 9. Questions for Ryan (chair picks marked)

1. The flagship's fork. S8's forked prow is shaped to house the
   recessed lance (R183 (1)), but the Daybreak dreadnought, the
   flagship class, has no lance slot in data.js; its forward fire is
   its turret and flak. What does the flagship's fork carry?
   A. Nothing: the fork is prow shape only on the flagship, and the
   lance recess appears on the Vigil and the Bastion, which carry the
   slot. (Chair pick: the shape stays one family language, the data
   stays untouched.)
   B. A lance: add an Oath lance slot to the Daybreak in data.js so
   the flagship's fork has its weapon.
   C. The flagship's Sear turret, recessed into the fork.
2. Radiator spires on the small classes. The faction sheet gives every
   Sunward ship the spine row. On a 6.5 frigate the row is a large
   share of the hull.
   A. The spire row on every class, scaled, tallest amidships.
   (Chair pick: one silhouette language across the fleet, per
   R183 (2).)
   B. Full spires on cruiser and above; frigate and destroyer carry
   low radiator blocks instead.
3. The Hearth carrier's hangar 2. A blade hull has no obvious bay.
   Where do its squadrons launch from on the sheet?
   A. Low flank sponson bays, both sides, outline kept. (Chair pick.)
   B. A stern bay under the engine bells.
   C. A dorsal bay behind the spire line.
