# Voidsworn issue 1006, round 3: iconography - ship silhouettes and an upgraded glyph set

You are one leg of a design council for the game Voidsworn (hex-based fleet tactics, Godot, alternating activations). Rounds 1 and 2 produced KEEL, a battle HUD with a bottom shelf, and then a polish grammar for that shelf: hull and shields as one stacked integrity unit, weapons as a glyph checklist with a drawn range band, orders and commands as bare glyph plus short label on a dark veil, a fleet strip of ship slots. The owner, Ryan, has accepted that grammar. This round is only about the artwork of the glyphs themselves.

## Ryan's direction for this round (Nov 17, 2026)

"I like the ship silhouette addition. The icons are also pretty, pretty simple. Can we look at upgrading those?"

Two commissions follow from that:

1. SHIP SILHOUETTES ARE IN. One silhouette per hull class, side profile, used in two places: as the anchor at the left of the integrity unit (about 40 px tall) and as the ship mark in the fleet strip (about 16 px tall). The game's classes include frigate, destroyer, cruiser, carrier and capital hulls; the example ship in the mockups is a Vigil-class cruiser, long hull, raised spine, engine block at the stern. Silhouettes must be recognisably different per class at 40 px, and still read as distinct blobs at 16 px.

2. UPGRADE THE GLYPH SET. The round 2 mockup drew schematic placeholders: a battery as three plain lines, a lance as a bare triangle, a shield as an empty hexagon, a burst as six plain spokes. Ryan's word for them: pretty, but pretty simple. The upgrade target is the richness the reference games achieve (Battlefleet Gothic: Armada 2's faction-flavoured ability icons, BattleTech's chunky weapon pictograms, Sins 2's crisp detailed icons) translated into this game's discipline.

## The standing discipline (unchanged, binds this round)

- Glyphs sit directly on a dark veil. No boxes, tiles, borders or background fills. Square corners, flat single-weight-or-two-weight line work, no gradients inside glyphs.
- Colour: off-white ink is the default glyph colour. Ember orange is the accent only (active state, the acting ship's marks). Glacier blue is for shield readouts only. Red is for the Nemesis only. A muted damage colour marks hurt hull.
- State is shown by opacity and marks, not new colours: ready at full strength, active takes an ember underline, unavailable dims to about a third, cooldown is a thin ember arc.
- Sizes: action glyphs about 32 px at design size (1920 by 1080), weapon glyphs about 20 px, integrity glyphs about 12 to 20 px, fleet silhouettes about 16 px tall. Nothing may depend on detail that vanishes at those sizes; detail must be layered so the 16 px reading still works.
- The glyph list from round 2 (the working set): hull (keel plate), shield (diamond or hexagon), battery, lance, torpedo, point defence, arc wedge, range band marker, focused fire (status), Brace, Focus fire (order), Turn, Command (star), Fire for effect, End ship, Move (hex arrow), log.

## Your leg must deliver

1. Silhouette construction: for each of frigate, destroyer, cruiser, carrier and a capital hull, describe the side profile in buildable terms (proportions, bow and stern treatment, spine and superstructure, engine block, one signature feature per class) and state what survives at 16 px and what is 40 px only detail. Note how a silhouette takes state (full ink, damage colour creeping, ember for the acting ship) without breaking the colour discipline.
2. Upgraded glyph constructions: for at least the weapon glyphs (battery, lance, torpedo, point defence), the integrity glyphs (hull, shield), and the order glyphs (Brace, Focus fire, Turn, Fire for effect, End ship, Command), describe the upgraded drawing in buildable terms: the base shape, the one signature detail that makes it specific rather than clip-art, line weights, and any interior detail. Keep each glyph drawable as a flat vector in the game's line style.
3. The detail budget: which detail layers drop out as size falls (32 to 20 to 16 to 12 px), and the rule a builder follows so a glyph degrades gracefully instead of turning to mush.
4. What you would refuse: richness that fights this game (faction chrome, skeuomorphic metal, gradients, tiny text inside glyphs, anything that needs a tile to read).
5. Honest costs: the art pass in agent terms (never human days), the risk that richer glyphs read worse at shelf sizes, and how you would test that before the set is adopted.

Write in plain prose and short lists. No em dashes or en dashes anywhere. Return only your leg text.
