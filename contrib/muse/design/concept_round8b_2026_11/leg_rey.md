# Blind leg, Rey, for issue 517 (concepts round 8b)

Written before looking at the round's shape references or any other leg, per the issue block. The set question: what does "a photograph of a real built thing" mean for a ship that is clean and well kept (the Hegemony flagship), and for a ship that is alive (the two Chorus ships), when neither can lean on rust and patches for its realism?

## The general answer first

Rust and patches are only one dialect of realism: damage. The camera does not believe damage, it believes consequence. A photograph reads as real when every part of the object shows the consequences of being made, used, and lit, at a scale consistent with the object's size. Damage is the loudest consequence, not the only one. A clean ship and a living ship each have their own consequence vocabulary, and the style pass fails if it borrows the Hullbreakers' vocabulary (that is how a redraw goes wrong in character while going right in detail) or if it adds detail without consequence (grime decals, random greebles), which reads as decoration, not manufacture.

Three tests apply to all three ships:

1. Scale evidence. Realism at this size is mostly a counting argument: the parts must be small enough, and numerous enough, that the eye divides the ship's length by the part size and gets a big number. One hatch, one pipe run, one panel seam is worth little; forty of them, none larger than a door on the hull's scale, are what make a ship huge. This is the Scrap Brick's real trick and it has nothing to do with rust.
2. Edges and joints. Photographs catch light on edges. A drawn ship has surfaces; a built ship has surfaces that MEET: at seams, steps, overlaps, fasteners, and shadow gaps. Wherever two plates join there is a line of shadow and a line of highlight, and the plate between them sits at a slightly different angle or tone than its neighbour. Flat single tone across a large face is the illustration tell, whatever texture is printed on it.
3. One light, honestly obeyed. A single hard source gives consistent shadow direction, deep blacks in the occluded places, and specular behaviour that agrees across materials. Painted nebula backgrounds and fill light from nowhere are illustration habits. Black space, faint stars, one sun.

## The clean ship (Hegemony): the vocabulary of manufacture and service

A well-kept warship is not a smooth ship. Naval and airforce photographs of maintained equipment show a dense, orderly consequence layer that has nothing to do with damage:

- Panel construction: the hull is visibly ASSEMBLED. Plates with real thickness, stepped overlaps, butt joints with weld or fastener lines, access panels with borders and screw heads, hatches with hinges, dogs and handles. A turret sits in a barbette with a visible race ring; a barrel has a mantlet, a fume extractor bulge, recoil length differences between barrels.
- Stencilled and painted information: markings, numbers, warning bands, walkway lines, rescue arrows, all slightly varied in wear. Paint is not one colour: large painted surfaces vary by panel because they were painted at different times, fade differently, and collect grime in recesses while staying clean on flats. Service wear is POLISH and DARKENING at touch points, exhaust and thruster staining in long faint fans, hydraulic sheen near moving parts, chipped paint only at edges and corners where things actually strike.
- Working fittings at human scale: rails, lights (small, numerous, placed for crew reasons), antennae and sensor housings with brackets and cable runs, pipes that go somewhere, vents and radiators with depth behind the grille, lifeboat or pod housings, docking targets and clamps. Each fitting is small against the hull and there are many.
- Order is the character. The Hegemony version of detail is REGULAR: seams in grids, fittings aligned, markings consistent. The failure to avoid is scrap-yard entropy (random patches, mismatched plates), which belongs to the Hullbreakers, and the opposite failure, showroom smoothness, which is what the shape reference already has and what this pass exists to remove.

Scoring consequence: for H12, count the scale evidence. If the redraw adds fewer, larger details (a few big hatches, a couple of pipes), the ship will still read small and drawn. The pass succeeds when the eye can find door-sized things all over the hull and turret faces broken into real plate.

## The living ship (Chorus): the vocabulary of anatomy

A living ship cannot use manufacture at all. Its realism is biological, and biology has its own consequence layer, as demanding as panel lines:

- Skin is not a surface, it is a terrain. Hide has grain at several scales: large folds and tension lines where the body bends, medium creases and scars, fine pore and scale texture that only resolves up close. In a photograph of a whale or an elephant, no square metre of skin is the same tone as the next, and the variation follows the anatomy (stretched thin and shiny over bone, slack and folded in hollows, callused where the world rubs). A living ship drawn with smooth shaded volumes and a speckle overlay is a toy creature, the biological version of a flat panel.
- Growth leaves records: scars and old wounds with different tissue, barnacle-like or calcified patches, asymmetry between the two sides (a grown body is never perfectly mirrored in its details, even when its plan is symmetric), repaired tears, areas where the hide is thinner and light comes through slightly, areas of pigment change. These are the living equivalent of service wear, and they must sit in anatomically sensible places: at flex points, along the ridge, around mouths and orifices where feeding and fighting happen.
- Wet and tension cues. Living tissue under hard light shows specular behaviour metal never has: broad soft highlights on wet or taut skin, tight bright lines on stretched membranes, matte dryness on old hide and bone. Bone itself reads differently: denser, smoother, with growth lines and a warmer tone, and it emerges from the flesh with a transition zone, not a clean socket line (a socket line is the bolted-on fault in biological dress).
- Organs are machinery. A weapon organ should read the way a mouth, a stinger or a spray apparatus reads in nature photography: an opening with structure inside it (rings, teeth, folded tissue), musculature around it that visibly works it, and wear from use. A smooth tube ending in a hole is a symbol; a sphincter-like mount with folds, sheen and staining from what it fires is an organ.
- Size evidence for a creature is the texture frequency: hide texture, scars and parasite-scale detail small against the body, plus the escort creature beside it grown from the same grammar but not a miniature copy.

Failure modes specific to the Chorus pass: making it prettier (even tones, decorative patterns), making it more monstrous (extra spikes, extra mouths, horror anatomy the reference does not have), softening the light (biology photographs in hard light too), and painting atmosphere behind it. The brief's line is the whole job: the same creature, photographed. Any change to the anatomy is drift, however biological it looks.

## What this means for the chair

1. Score H12 on consequence density and order: panel steps, fastener lines, fittings at door scale, service sheen and staining in the right places, markings. Reject scrap entropy and reject big smooth faces.
2. Score C10 and C11 on anatomy: multi-scale hide, growth records in sensible places, bone emerging through transition tissue, organs with structure and use-wear, wet/taut/matte variation under one hard light. Reject speckle-over-smooth, reject added anatomy.
3. For both: the background stays black with faint stars, the light stays single and hard, and no faction borrows another's consequence vocabulary.
