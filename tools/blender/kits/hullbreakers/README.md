# Ashfall Hullbreakers parts kit (faction id `corsair`)

Shape language: scavenged and rebuilt. Heavy, squat, over-armoured guns made from salvage. Junky and mismatched on purpose (AGENTS.md:
the Hullbreakers are the haphazard exception), but every surface is crisp hard-surface geometry: flat facets, small bevels, no noise
or displacement, so nothing reads wavy or oversharpened (R147).

| Part | What it is | Concept source |
|---|---|---|
| `casemate` | octagonal armour housing bolted onto the flank (buried behind, so it never floats on a curved bow), a raised frame with a recessed field, ten frame bolts, four corner braces, one or two crooked patch plates and a weld bead (different on every casemate), a dark collar disc with a bolt ring, a copper ball and mantlet ring, the quilted sleeve (tapered, five ring straps and fourteen lengthwise straps), a front cap, twin copper barrels with fat recoil sleeves, clamp rings, muzzle rings and dark bores | C15s bow casemates |
| `bow_battery` | twin heavy guns on the raised forward deck: breech blocks under a slatted armour hood with cheek plates and a weld, ribbed recoil sleeves, long barrels, ribbed muzzle shrouds, glowing bores, welded braces to the deck | C15s orange-muzzled bow guns |
| `drum_rack` / `drum` | missile drums in a welded pipe cradle: quilted and strapped body, two faded ochre bands, framed front with a recessed launch mouth, tapered tail; cross beams, saddles, legs cut to the deck, a low cradle rail; drums in one rack are deliberately mismatched (variant 1: a slipped band and a patch; variant 2: shorter with a salvaged conical nose ring) | C15s drum pairs and the rack of three |
| `turret` | variant 0: a squat welded drum turret with a sloped glacis plate, a patch and one heavy copper barrel; variant 1 ("borrowed"): a clean faceted dome turret from another navy, welded onto a crude ten-sided adapter ring, painted in that navy's blue-grey | C15s aft deck turrets |
| `marking` | thin decal plates seated on the hull: stencilled rectangle frames, yellow tags, a white deck disc, rows of amber lamps | C15s markings |
| helpers | `weld` (bead along a polyline), `patch` (crooked riveted plate), `quilted` (strapped tapered sleeve), `sphere`, `tube` | |

Paint (`paint.py`): the forward hull dark oxide red with broad bright orange rust blooms and a dusty light deck; the aft body,
sponsons and stern gunmetal with rust run-off; drums dark steel with ochre bands; barrels copper; the lower hull grimes to a dark
olive near black; worn bare edges broken up by noise and only in some areas; yellow and black hazard stripes on the ventral pylon
feet; borrowed parts barely weathered. Colours were fitted to region samples of the concept (round 6 README, section 2).

Variants and pairs: a `pair` socket mirrors position, size and aim exactly; `variant` and `variant_s` give the twins different
salvage detail (patches, welds, drum types). Use `variant: 1` on a turret to show a borrowed part.

Turning turrets (issue 560; RULEBOOK 6.17, Ryan R219): the turret's ring and its welds stay on the hull; its body, dome or glacis
plate, patch, recoil sleeve, barrel and muzzle ring turn (`TURRET_TURN` in `kit.py`). Stage 7 marks every `turret` socket from
that list and writes each as its own `turret_<n>` node, so the game turns it to its target (tools/blender/kits/README.md "How a
kit marks a turret"). Casemates, the bow battery and the drum racks are fixed guns and never turn. The build-sheet kit for A16
and A17 (tools/blender/build_sheets/kit.py, issue 532) marks its turrets in the blend the same way, with an empty `<id>_turret`.

Class family parts (issue 633, `parts.py`; used by the A18, A19 and A20 build sheets, built at the hull's detail level like the rest):
`bow_launcher` (a rocket casemate set IN a bow face: armour plate, box housing with a brow, one long braced tube or a short fat
cluster of three, lips, bands, bolts, bores and rocket noses; a machine, R226), `hangar_mouth` (the dressing of a flank hangar
recess: a rim with torn plate teeth, armoured door leaves slid clear on railed brackets (the outer leaf patched with plates at the
hull's plate size, round 2), launch rails, ceiling beams with a dim red
lamp, wall ribs and an inner blast door; structure, it may tear across a seam; `doors=False` (issue 651) leaves out the door
leaves and their rails, for a mouth in a bow face with no face beside it, as A20's) and `craft` (a cobbled fighter at the game's
squadron length, 1.6). `spare_bell` (issue 651): the engine bell carried cold for field repairs, throat and lining dark, kind
`spare` (type engine for the inventory): not a machine and not one of the ship's engines, and the paint stack paints it as a
matte bell that never glows. A sheet whose plates sit on small masses uses the sheet kit's `keep3d` plate option, so a keep-out clears only the
plates it touches. From round 2 (issue 633) the three class sheets lay their plates in courses (the sheet kit's `courses` option: plates at
the hull's plate size both ways, patches over joints and over plates, upward faces terraced; `rivet_r` sizes the rivets to the hull).
