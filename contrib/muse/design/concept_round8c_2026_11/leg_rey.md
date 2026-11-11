# Blind Rey leg, issue 522: why the round 8 style pass stayed smooth, and what changes in the method

Written before the council legs, from the round 8 record and the mechanics of the tool. The four ships in this round are the four the owner did not pass in round 8 (his words are R201): Sunward S9 stayed "smooth and drawn, like an illustration" and its grey went lighter with blue added; Eclipse E9 gained "a little more plate" but its broad faces stayed smooth; Eclipse E10's arcs "went grey slate and lost the Eclipse purple" behind nebula dust; Glasswright G17's lenses "became clear glass bubbles and glowing globes that no longer point forward". Round 8b (issue 517, delivered just before this round) added one more data point: an escalated Hegemony pass bought surface detail by spending shape (turrets changed form), and was rejected. So the pattern to explain is consistent: gentle edits polish, hard edits drift, and neither reaches the reference.

## Why it happens

1. An image-to-image edit is anchored by its source. The model treats the first picture as the thing to preserve and spends its change budget at the margins. A smooth source gives it nothing to amplify: there are no seams, edges or fittings in the input to sharpen into structure, so "more realistic" resolves as better polish on the same smooth forms. The flatter the source's lighting, the worse this gets, because flat lighting carries no shadow information for new geometry to hang on. S8, E4 and E8 are all clean, evenly lit renders; that is exactly the input class the edit preserves best.

2. A foreign style reference blends, it does not instruct. When the shape input is a clean illustration and the style input is a photograph of a different ship, the output lands between the two: partly photographed, partly drawn. Every round 8 result reads as that midpoint. The style reference also drags palette with it: when the model re-renders instead of editing, it re-picks colours from its own prior, which is why S9's grey went lighter and blue appeared, and why E10's arcs went grey slate. Colour drift and surface smoothness are the same failure wearing two coats: both mean the model re-rendered rather than edited.

3. Adjectives are satisfied by polish. Round 8's prompts leaned on quality words (realistic, detailed, photographic). The cheapest way for the model to satisfy "detailed" on a smooth hull is finer shading, not more parts. Parts have to be requested as inventory: named fittings, at stated sizes, in stated counts of rows and seams. What is not enumerated does not appear.

4. Some words carry templates. "Lens" summoned the dome: the model's nearest picture of a glass lens on a vehicle is a bubble canopy or a sensor globe, so G17's lenses became clear bubbles whatever the prompt said around them. Fighting a template adjective by adjective loses; the fix is to specify the geometry (a solid swelling of the hull's own glass with a forward-facing aperture) and never lean on the template word alone.

## What changes in the method this round

M1. Section first. Before the full-ship edit, take one tight crop of the source (a single face or quarter of the ship, large in frame) and edit that crop alone into the target surface treatment. At crop scale the model cannot smooth: the frame is all surface, and it must invent plates, seams and fittings at a size that reads. The accepted crop then goes into the full-ship edit as a third input, a same-ship style reference, which is a far stronger style anchor than a foreign ship. If the crop itself will not take the treatment, that is learned cheap, before the full passes.

M2. Style input first. Put corsair_A.jpg before the shape input in the call, so the photographic prior leads and the shape input reads as the thing to be photographed, not the thing to be preserved. (Round 8b's C11, the strongest pass of that round, is weak evidence this ordering helps; it is cheap to keep.)

M3. Prompts as inventory, not adjectives. Every beauty prompt enumerates the surface: plate sizes relative to the hull, seam and fastener rows, fitting types at door scale, and for Eclipse the layered plate construction of the crescent's broad faces specifically, since those faces are the failure. The word budget moves from praise to parts lists.

M4. Colour is specified as a lock, with the source named as the palette authority. Round 8's colour failures are named in the prompts as failures (no lighter grey, no blue on S10; arcs stay dark violet on E12, never grey or slate; no nebula anywhere; background plain black). A colour lock stated as "keep the shape reference's colours" was in round 8's prompts too and failed, so the lock is now stated per surface, not once globally.

M5. Two-pass escalation is licensed and expected. The brief says: if one method keeps the source's smooth look after two tries, say so and try a different method, recording each try. The planned escalation ladder per ship: (a) inventory edit with same-ship crop reference (M1+M3); (b) if still smooth, a harder material pass that accepts fitting-level drift while the prompt holds silhouette, counts and palette, followed by a shape check against the reference; (c) if that still fails, record the failure honestly in the README rather than polishing a third time.

M6. For G18, geometry language only. The bow lenses are forward-facing weapons grown from the hull: solid glass forms with a flat or faceted forward face and an aperture, seated in the hull's glass and bright metal, able to be read as pointing forward from the sheet's top view. The spine turret lens sits on a turning collar grown from the hull and points forward. The flak lenses are small apertures in the skin. The words dome, bubble and globe appear in the prompt only as prohibitions. The faction stays clean and bright; its realism is ribs, inlay, layered glass and fine metalwork, never wear.

## What success looks like, per ship

- voidsworn_S10: S8's exact silhouette and counts (seven organ pipes, seven flank barrels, four dome turrets, two engine bells, radiator bank, escort) rendered as built dark iron, no lighter than S8, no blue anywhere, gun ports dark.
- deathless_E11: the crescent's broad faces become layered, seamed plate with thickness at a scale that makes the ship huge, in E4's own colours, mounts as drawn (two large twin turrets, one smaller turret, one small flak cluster).
- deathless_E12: the flat ring of seven broken arcs on four struts keeps E8's dark violet on the arcs, green only at the core and the razor edges, no nebula, arcs as built plate rather than smooth bands.
- ithar_G18: G15's shape with the changed lens brief (M6), clean and bright, its surface incident coming from fine structure rather than wear.

The chair will score every result against the twelve-line gate and the style line, count tries per ship, and record method changes where they happen.
