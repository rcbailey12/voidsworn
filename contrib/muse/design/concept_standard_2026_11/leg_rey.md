# #398 blind leg: concept sheet standard and the C15s trial

Chair's blind leg, written before the other legs and before judging any generated candidate. Sources: docs/ship_pipeline/concepts/C15s_23.webp read directly (OBSERVED notes below), docs/shots/ship_pipeline/route209/round8/README.md, FINDINGS R138, R151, R156, R162 as cited in the issue brief.

## 1. What C15s_23.webp actually shows (OBSERVED)

One three-quarter bow view, port side toward the viewer, bow to the left, light from the upper left, black background with hard pixel fringing on the silhouette edge (a cutout artefact, not part of the design).

- Hull form: long, low hull; the prow is blunt and rounded, not a point; the bow third is the widest, tallest part of the ship and the hull steps down and narrows toward a plain flat stern. The foredeck slopes gently down to the prow tip.
- Colours: bow and foredeck are rusty red-brown with orange rust blotching; the aft hull is dark charcoal grey; the belly under the bow is olive green. The colour break sits roughly amidships.
- Bow casemates: two armoured casemates on the near bow flank, each a short cylinder in an octagonal housing with twin barrels pointing forward. Eyeball positions from this view only: about 15 percent and 35 percent of the length back from the prow tip (APPROXIMATE, a three-quarter view compresses the length axis; the side view exists to replace these numbers).
- Foredeck tubes: twin tubes with orange-lit muzzles lying flat on the foredeck centreline at the prow, pointing forward.
- Amidships: a rack of three large horizontal cylinders with yellow bands on the port deck edge, two smaller cylinders behind the bridge block, and a rounded red-brown casing between them.
- Bridge: a blocky tower just behind amidships carrying a lattice mast with an antenna array; railed walkways along the deck edges.
- Belly: a dark downward fin under the bow, carrying a yellow stripe, like a keel blade. It is the single easiest feature to lose in a side view and the easiest to invent wrongly in a top view, where it must not appear at all.
- Stern: flat transom, an A-frame crane over the aft deck, small fittings. The engine end reads plain in this view; nozzles are not clearly readable, which is itself a finding: the existing concept does not pin the engine end.
- A row of small round portholes along the aft hull side.

## 2. The standard (blind draft)

A concept sheet is three views of one design, drawn to be measured from, not admired.

Views and cameras, all orthographic (no perspective foreshortening):
1. Three-quarter: azimuth 45 degrees off the bow, elevation 20 degrees, port side toward viewer, bow left. This is the identity view.
2. Side: true profile, elevation 0, azimuth exactly abeam, port side, bow left. This is the length and height master.
3. Top: true plan, camera directly overhead, bow pointing up the page. This is the beam and placement master.

One light for all three: a single key light from the upper left at a fixed 45 degrees, neutral grey background (not black, so dark hulls keep their edge), no rim or fill inventions between views.

What each view must show:
- Side: the bow profile and how far the prow overhangs the keel fin; the deck edge line from prow to stern in one unbroken read; every gun's height and which way it points; the belly line and the keel fin; the engine end in profile, nozzles drawn, not implied.
- Top: the beam at its widest and where that falls; every gun's position across the centreline and its pointing direction drawn as the barrel, not a symbol; the deck edge on both sides; the prow outline (the overhang read from above). The keel fin and belly must NOT appear.
- Three-quarter: the colour zones and where their boundaries sit; the material read (rust, plate, glass); the features that give the ship its name in one glance. It is never a measurement source.

Scale: every sheet carries the ship's length in world units from the build data and a scale bar of 5 units on the side and top views.

Consistency rules (a sheet fails if any one fails):
- Silhouette: side and top outlines must be the same ship the three-quarter shows; check by overlay at matched length.
- Counts: gun count, cylinder count, mast and crane are identical in every view that can show them.
- Positions: a feature's position along the length, as a fraction, agrees between side and three-quarter within about 3 percent; across the centreline between top and three-quarter within about 5 percent.
- Colours: zone boundaries fall at the same length fractions in all views; no view invents a colour zone another view contradicts.
- Nothing appears in exactly one view unless that view is the only one that can show it (belly and fin: side and three-quarter only; deck layout: top and three-quarter only).

## 3. When views disagree (blind ruling proposal)

- Lengths, heights, prow overhang, gun heights: the side view wins.
- Beam, lateral gun placement, pointing direction in plan: the top view wins.
- Colour, material, surface detail identity: the three-quarter wins.
- If a feature exists in one view and is absent where another view should show it, the design is undecided, not the drawing: the sheet goes back, it does not go to the build.
- The build takes geometry from side plus top, paint from the three-quarter. Nobody traces a three-quarter for measurements; that is the round 7 and 8 failure this standard exists to end.

## 4. Judging checklist for the C15s trial candidates

For each side and top candidate, score against section 1: hull silhouette (blunt prow, step down aft), two bow casemates with twin barrels (side view: both visible in profile; top view: housings on both flanks), foredeck twin tubes, three banded cylinders, lattice mast, A-frame crane, keel fin (side only, absent in top), colour zones (red-brown bow, charcoal aft, olive belly in side view), porthole row (side), flat stern. Name every disagreement plainly; a candidate that changes the design is a new design, not a view of this one.

## 5. Predictions (to be tested, written blind)

Image models will: turn the side view back into a three-quarter unless the prompt forbids it hard; mirror or duplicate the casemates; drift the cylinder count; paint the whole hull one colour; draw the keel fin into the top view; slim the blunt prow into a point. Image-to-image from the original should hold identity better than text-only, at the cost of the model refusing to truly flatten the view. The trial will show which failure dominates.
