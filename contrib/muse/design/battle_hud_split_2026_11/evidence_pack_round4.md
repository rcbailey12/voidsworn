# Voidsworn issue 1006, round 4: log relocation, shelf expansion, faction silhouettes, odds clarity

You are one leg of a design council for the game Voidsworn (hex-based fleet tactics, Godot, alternating activations). Rounds 1 to 3 produced KEEL, a battle HUD whose bottom shelf (216 design px tall at 1920 by 1080) holds the selected ship, a stacked hull and shield integrity unit with a ship silhouette anchor, a weapon checklist with drawn range bands, figure-led odds, glyph plus label orders, a two-line log at the shelf's right end, and a fleet strip. Ryan, the owner, has accepted all of it. This round has three changes and one fix, all from Ryan (Nov 17, 2026).

## Change 1: move the log out of the shelf, and expand the shelf

Ryan: "Can we move the log up so it sits above the bottom bar on the right with a bit more transparency and it's an optional log? Or top left under the your turn? Then we expand the bottom bar a bit to make it not so cluttered."

Two candidate homes for the log:
- A: a floating log above the shelf on the right side of the screen, on a lighter (more transparent) veil than the shelf, optional in the sense of toggleable or collapsible. The log's content is outcome lines and the occasional spoken line from a character (for example an enemy fleet marshal's taunt at contact).
- B: top left, under the existing turn cluster (Round number, Your turn, ships to act, Objective), growing that cluster downward.
Whichever home loses still needs its cost stated. The log's job: explain what just happened (damage, effects, reinforcements) without the player opening anything.

With the log gone, the shelf expands to declutter: the working assumption is height 216 to about 248 design px, rows taller, order glyphs at their full 32 px spec size, the integrity unit and range bands wider. Your leg must give honest screen share accounting: shelf percentage, top clusters, and the log patch (its area and its opacity, and what that opacity means in veil terms), against today's roughly 33 percent for the current full-width rail.

## Change 2: silhouette detail, per faction

Round 3 set five class silhouettes (frigate, destroyer, cruiser, carrier, capital) in one angular metal language. Ryan: "upgrade the ship icons a bit more so they have more detail, especially for each faction."

The game's factions have settled ship languages in the design record. Four examples: Iron Mandate ships are terraced fortress forms, stepped and massive. Glasswright ships are long leaves of blown glass, curved and lit from within; the one curved family, not metal hulls at all. Dominion hulls are heavy forms built around a prominent ion cannon that must read as a cannon. Hegemony ships are the angular naval standard, close to what round 3 already drew. There are more factions than four; the system matters more than exhaustiveness.

Your leg must deliver: a silhouette kit system (what stays fixed per class, what swaps per faction: bow treatment, spine and superstructure, stern and engines, signature feature, and the anchor-size detail kit such as turret silhouettes, antennae, nozzle segmentation, hangar mouths, stated as contour detail and negative cuts, never interior shading); the cruiser worked in the four languages above as the proof; an honest statement of what faction reading survives at the 16 px fleet size and what the fallback is when it does not; and the cost in agent terms, including a sensible shipping order (which factions first).

## Fix 3: the odds split must explain itself

The current game text (pre-ruling wording) is: "About 16 damage: 7 to its prow shield, 9 to hull." Under Ryan's pooled shield ruling the build will say "to shields" (one pool per ship). The round 2 and 3 mockups compressed this to two bare figures beside glyphs (a Glacier 7, an ink 8, "of 16 damage"); the 8 was the chair's arithmetic error for 9, and Ryan could not tell what the numbers meant. Your leg must propose the clearest standing presentation inside the existing grammar (glyph plus figure plus short word labels allowed; the total and the hit chance stay prominent; the word "About" or an equivalent honesty marker should survive, because these are expected values, not certainties). No new panels, no hover-only meaning.

## Standing discipline (unchanged)

No boxes or tiles except the FIRE box; glyphs and words sit on dark veils; square corners; ember is the accent only, Glacier for shield readouts only, red for the Nemesis only; text floor 17 px for sentences with small mono labels already accepted at 14 to 16 px for readouts like SHIELD and HULL; keyboard shortcut labels stay off the HUD face (ruled round 1, they live under Menu, Controls); shields are one pooled readout per ship (ruled Nov 14, 2026).

Deliver: (1) log verdict with default state and the loser's cost, plus the share accounting; (2) the faction silhouette kit, the cruiser in four languages, 16 px honesty, cost and shipping order; (3) the odds presentation; (4) anything you would refuse and why. Plain prose and short lists. No em dashes or en dashes anywhere. Return only your leg text.
