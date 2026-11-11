# #417 concept directions: eighteen pictures, three per faction

Deliverable for issue #417. One direction picture per direction A, B and C in docs/playbooks/factions.md, for the owner's pick: one sheet per faction, three directions side by side, one direction picked per faction (or two mixed). These are direction pictures: identity and silhouette are what is being judged, not counts or fine detail.

How they were made: the chair (Rey) wrote a blind leg first (leg_rey.md: per faction, which direction should be strongest and what could go wrong, written before any picture existed). DeepSeek and Qwen wrote full prompt sets (leg_deepseek.md, leg_qwen.md), Flash and Grok gave ideation and risk lines (leg_flash.md, leg_grok.md). The chair's prompts, cross-checked against all four legs, drove the generation. Model: Muse's image generation pipeline (media.generate_image); the pipeline exposes no underlying model name. prompts.md holds the exact prompt used for each delivered picture. Up to three tries per direction were allowed; 24 generations were made for the 18 pictures. Every delivered picture is 1920 x 1280, landscape, hero capital plus one small same-faction escort, near-black background, lit from the upper left.

No direction failed outright. Three directions needed corrective tries, and the failures are the same three the blind leg and every council leg predicted: the model reaches for aircraft when it hears "drones", for an animal when it hears "pack hunter", and for extra light colours when a faction allows exactly one.

## Sunward Crusade (voidsworn)

- A, Oath Blade (voidsworn_A.jpg, try 2): try 1 framed the ship from behind, stern and engine bells to the viewer, spires reading as masts. Try 2 is the bow-forward dagger: flat ember radiator spires, broadside rows, escort alongside. Delivered clean.
- B, Forge (voidsworn_B.jpg, try 1): blunt slab, stacked flank fins glowing like a forge, escort matching. Delivered clean on the first try.
- C, Reach Militia (voidsworn_C.jpg, try 2): try 1 read clearly as a converted hauler but carried blue-green accent lighting, against the faction's ember-only accent and its no-blue-light rule. Try 2 is ember only throughout. Note: the frost-white names of the dead render as chalk tally groups in try 2 rather than lettering; for a militia conversion the chair judges that a feature, not a miss, but the fleet pass should decide whether Crusade ships get lettering or tallies.

## Hegemony Navy (hegemony)

- A, Clean Wedge (hegemony_A.jpg, try 1): flat pale wedge, one low fin, no yacht tower, blue strips, turret rows, escort. Delivered clean.
- B, Module Line (hegemony_B.jpg, try 1): visibly segmented identical modules along a spine, blue line running through the joints, escort a shorter module ship. Delivered clean.
- C, Drone Mother (hegemony_C.jpg, try 3): the hardest direction in the set. Try 1 drew the drone halo as winged fighter jets with cockpits. Try 2 made the drones finned pods but framed the carrier from directly above. Try 3 specifies the drones' shape (faceted blocks, sensor eye, no wings, no cockpit) and delivers: blocky drones in a geometric halo, open racks visible in the deck, escort a plain wedge. Two kept deviations: the framing is more top-down than the standard front three-quarter, and the escort carries no sensor fin. The direction itself (calm carrier, halo of identical machines) reads at a glance.

## Ashfall Hullbreakers (corsair)

- A, Scrap Brick (corsair_A.jpg, try 1): lopsided rusty brick, bow dishes and scoops, mismatched plate and trophy colours, escort. Delivered clean.
- B, Pack Hunter (corsair_B.jpg, try 2): try 1 took the posture literally and produced a wolf-like animal head with dish ears and jaw claws. Try 2 keeps the forward lean and the shoulder hump as pure machine: dishes mounted flat on the bow block, boarding claws folded underneath, trophy crystal shard on the flank, no face anywhere. Minor kept deviation: two small top turrets sit at odd angles, which for this faction the chair reads as bolted-on character rather than a rule break; no gun reads as aimed at the ship itself.
- C, Den Ship (corsair_C.jpg, try 1): hollowed burned rock, gun pits, bolted deck structures, chained engine cluster glowing red-orange, scrap escort, no sea-ship silhouette. Delivered clean; Grok's flagged risk (rock texture on a boat hull) did not occur.

## The Glasswrights (ithar)

- A, Collector (ithar_A.jpg, try 1): one great hexagonal-faceted mirror dish on a slim silver hull, secondary lenses, escort a smaller collector. The dish reads as rigid optics, not as a wing, petal or satellite aerial. Delivered clean.
- B, Prism (ithar_B.jpg, try 1): one long three-sided crystal shard with light moving inside, escort the same shard smaller. Kept deviation: the shard reads broad and flat from this angle, and the small mirror fins became mounting rails carrying small guns. The identity (the hull is the optic) is unmistakable.
- C, Beam Line (ithar_C.jpg, try 1): four lens rings in a silver truss, light passing ring to ring, escort a two-ring version. Kept deviation: the beam light runs blue-white rather than a pure white core with rainbow fringe; the fringe is present on the lens edges. The fleet pass should hold the lance to white.

## Eclipse (deathless)

- A, Crescent (deathless_A.jpg, try 1): a huge thin crescent of layered plates, rim carrying the thin green-white corona line and nothing else, body tucked inside the curve. Kept deviations: the escort is a plain dark ship with no crescent shade of its own, and the hero's stern eclipse ring sits behind the hull like a separate halo. The hero silhouette is exactly the direction.
- B, Fan (deathless_B.jpg, try 1): overlapping shade plates swept back, green-white line on every plate rim, escort matching. Slight green pooling where the plates meet the body; the line itself stays thin and on the rims. Delivered.
- C, Annulus (deathless_C.jpg, try 1): broken ring of plates with clear gaps, repair drones between the plates, bright core floating at the centre, green-white rims. Kept deviations: the spar body behind the ring reads as a conventional warship rather than a shade-sheltered spar, and its guns fire with orange muzzle flashes, against the faction's no-flame rule. The ring and core, which are the direction, read correctly; if this direction is picked, the fleet pass needs a body built from shade plates and cold gunfire only.

## The Chorus (chorus)

- A, Leviathan (chorus_A.jpg, try 2): try 1 failed twice over: the palette went brassy gold instead of dark olive-brown, fins and membranes stuck out everywhere, and the escort had a fish face with a visible eye. Try 2 is dark, smooth and finless, with organ throats and sacs and a smooth escort. Kept deviation, flagged for the fleet pass: the two large glowing vents at the hero's rear can be misread as eyes at a glance. They sit at the stern and vent green vapour, but the fleet pass should keep rear glow smaller and lower than any bow feature.
- B, Bloom (chorus_B.jpg, try 1): membrane crown opening forward, bile-green throat glow, dark olive-brown hide, escort a smaller bloom, no face. The membrane edges run spiky; the chair reads that as chitin, within the faction's language. Delivered.
- C, Overgrowth (chorus_C.jpg, try 1): the swallowed warship's angular outline is readable in the silhouette under hide and bone, brood sacs along the flanks, no metal showing anywhere, escort the same. Kept deviation: hide and bone run tan-heavy in the light; the palette wants darkening in the fleet pass, not a shape change.

## Legs in this folder

- leg_rey.md: the blind leg, written before any picture was made.
- leg_deepseek.md, leg_qwen.md: writer legs, screened summaries with run records and chat links; full texts live in the linked chats.
- leg_flash.md, leg_grok.md: ideation legs, screened summaries with run records and chat links.
- prompts.md: the exact prompt and try count for each delivered picture.

Chair's closing note: the set holds together as six silhouettes that cannot be confused with each other at the battle camera: black dagger and slab, pale wedge and module line, rust brick and rock, crystal dish and shard and rings, violet crescent and fan and ring, and three grown bodies with no metal in them. The recurring model failures are all in the README above, per direction, so the fleet pass can prompt against them from the start.
