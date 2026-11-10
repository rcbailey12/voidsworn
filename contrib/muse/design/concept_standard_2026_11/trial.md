# The C15s trial (issue 398, done-when items 2 and 3)

The standard in standard.md, tried on the one existing concept: docs/ship_pipeline/concepts/C15s_23.webp, the Hullbreaker cruiser C15s (three-quarter, port bow). Six candidates were generated image-to-image from that concept with the media pipeline: three side views and three top views. A and B are straight view prompts; C is a corrective prompt written after A and B were judged (full prompts and model notes in README.md). Judged against the chair-verified inventory of the original: blunt rounded prow; rusty red-brown bow and foredeck with orange rust blotching; dark charcoal aft hull; olive belly under the bow; two bow casemates with twin forward barrels; twin foredeck tubes; three large banded cylinders amidships and two smaller behind the bridge; lattice mast; A-frame crane at the stern; dark keel fin under the bow with a yellow stripe; a row of portholes aft. The concept does not state the ship's length and does not pin the engine end; both stay open below, on purpose.

## Side view: pick A

Shared failure, all three candidates: the bow casemates are drawn as round frontal faces looking at the viewer, not as cylinders seen in profile. In C the model pushed horizontal barrel stubs through the faces, which is worse. The reference reads the casemate frontally, and the model would not re-render the same fitting from a new aspect in any of three tries, including one prompt that spelled the profile geometry out. Under the standard this is a named fail (wrong aspect), and it is the trial's most useful result.

- Side A (pick): a true flat profile, and the colour read closest to the original, rust blotching and the red-brown to charcoal break both where they belong. One clean row of seven portholes. Disagreements with the original: casemates frontal (shared); the olive belly runs the full length of the hull where the original shows it under the bow; two cylinders out of place (one on the bridge roof, one on the stern deck); the A-frame crane reads as a lattice pylon; the keel fin is oversized with an invented hub.
- Side B: also a true profile and the cleanest drawing of the three, but the portholes inflate into two groups (five and eight), the aft hull goes much blacker than the original, and the fin grows again.
- Side C: the corrective prompt fixed the belly (olive under the bow only) and simplified the fin, then broke the flank: a giant banded cylinder mounted along the hull side that exists in no other view, and the portholes doubled into two full rows.

## Top view: pick B

Shared behaviour: the view discipline is perfect in all three (true plan, no hull sides, and the keel fin never appears, a genuine pass under the standard), and the counts are not held in any of them.

- Top A: two casemate stations, a bow pair pointing forward and a second pair further aft pointing sideways. The second pair contradicts every side candidate: the design carries its casemates on the bow flank, none amidships. Cylinder racks multiply along both deck edges and at the stern.
- Top B (pick): one casemate pair at the bow, barrels pointing forward, at the station the side views support. It invents two red box turrets at the second station instead, plus a three-cylinder rack aft and canisters at the stern corners. Its plan read and colour zones are the cleanest of the three. Its inventions are secondary fittings; A and C duplicate the main battery itself, which is the worse sin.
- Top C: the prompt stated the exact feature counts twice, and the candidate still shows four casemate protrusions (the bow pair plus a sideways second pair) and multiplied cylinders, under a heavy drop shadow that breaks the flat plan read. Explicit counting does not fix counting.

## The honest note (done-when item 3)

What held, across six candidates from one reference: identity, palette and silhouette (every candidate is unmistakably C15s), and the view angles themselves. Profiles came out as profiles, plans as plans, and the fin stayed out of the plans. Image-to-image generation is good at "the same ship, from over there."

What did not hold:

- Counts. Cylinders or portholes inflated in five of six candidates. A prompt that states the counts in words, twice, still failed (top C). A generated sheet cannot be its own parts list.
- Aspect. A fitting the reference shows from one angle is drawn from that angle in every view (casemates, three of three side views). The model holds a picture of the fitting, not a model of it.
- Silence. Where the concept says nothing (the engine end, the stern fittings, the far side), every candidate invents, and they invent differently, so the inventions cannot be averaged into a decision. C15s's engine end is still undesigned after six generations, and the standard now forces that fact onto the sheet instead of letting a picture decide it.

What the build side should do when views disagree, beyond the protocol in standard.md: treat a generated sheet as an identity and proportion reference. Take the silhouette and length fractions from the side view, the beam and lateral placements from the top view, the paint from the three-quarter, and the counts and stations from the written feature table, which the sheet must carry and which outranks every picture. Decide in text, before generating, anything the existing concept cannot show; the generator will otherwise decide it silently and inconsistently. Expect one corrective round to fix one thing and break another (side C fixed the belly and broke the flank), so judge every candidate whole, against the inventory, every time.
