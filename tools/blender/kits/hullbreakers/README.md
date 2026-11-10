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
