# Issue 1006 round 3, blind Rey leg (written from the pack alone, before the external legs)

## Silhouettes

Construction rule: every silhouette is a side profile built from the same kit (bow wedge, mid hull, spine, engine block) with proportions and one signature feature carrying the class. Lengths at the 40 px anchor size, heights in proportion:

- Frigate: short and sleek, length about 64 px, low spine, bow a clean wedge, single engine block. Signature: a forward sensor spike under the bow. At 16 px: the wedge and the spike survive as a dart shape.
- Destroyer: length about 76 px, spine stepped once, twin engine blocks. Signature: a broadside turret hump amidships. At 16 px: the hump reads as a notch on the top line.
- Cruiser (the Vigil pattern): length about 88 px, raised spine running two thirds of the hull, engine block with twin bells. Signature: the long raised spine itself, with a lance housing ridge on it. At 16 px: a long hull with a raised back, distinct from the destroyer's step.
- Carrier: length about 96 px, hull deepened, spine low and broken by a flat flight deck line. Signature: the deck notch, a rectangular bite out of the top line aft. At 16 px: the deepest hull and the notch survive.
- Capital: length about 104 px, heavy bow, spine terraced twice, triple engine block. Signature: terraced spine plus a keel fin under the bow. At 16 px: sheer mass and the fin.

Interior detail at 40 px only: one spine line, turret ticks (two or three small rectangles on the spine), an engine glow notch (a 2 px gap at the stern, never a colour change). State: the silhouette is ink at full hull; as hull falls the damage colour creeps from the stern forward in proportion (a fill mask, not a tint of the whole shape, so the read is positional); the acting ship's silhouette in the fleet strip takes the ember underline it already has, never an ember fill.

## Upgraded glyphs (base shape, signature detail, weights)

Two weights throughout: a 3 px outer weight and a 1.5 px interior weight at 32 px design size, scaling together.

- Battery: a turret cluster in side view: a housing block with three barrel strokes of stepped lengths, each tipped with a small muzzle notch, and a recoil line under the housing. Signature: the stepped barrels. The three plain lines become a gun you can name.
- Lance: a long spearhead on a short emitter housing, with two cooling fins angled off the housing and a bright core dot at the tip. Signature: the fins.
- Torpedo: a finned dart, tail fins as two angled strokes, a warhead band across the nose third, one exhaust tick. Signature: the warhead band.
- Point defence: a spray fan of five short strokes from a single base nub, lengths falling off from centre. Signature: the fan's asymmetry (centre longest).
- Hull: a keel plate: a horizontal plate with a keel line through its lower third and three rivet ticks. Signature: the rivets.
- Shield: a diamond with a smaller diamond nested inside, the inner one Glacier when standing in a shield readout, ink elsewhere. Signature: the nesting.
- Brace: a hexagon with buttress ticks at its two lower corners and the nested diamond at its centre. It quotes the shield glyph, which is correct: Brace is the shield order.
- Focus fire: a reticle of four corner brackets with a centre dot and one bracket extended (the locked corner). Signature: the extended bracket.
- Turn: a curved arrow whose tail carries a small ship tick (a 4 px wedge), so it reads as a ship turning, not a generic undo. Signature: the ship tick.
- Fire for effect: a burst with a solid shell core at its centre and spokes of two lengths alternating. Signature: the core.
- End ship: a double chevron into a stop bar, the bar carrying a small notch. Keep it the plainest glyph in the set; it is the most pressed and should be the fastest read.
- Command: a four-pointed star inside an open ring segment (the ring broken at the top). Signature: the broken ring.
- Move: a hex outline with an arrow crossing it left to right, arrowhead outside the hex. Unchanged in concept from round 2, redrawn at the two weights.
- Focused fire (status): the reticle family at smaller size with the centre dot filled ember when standing. It shares the Focus fire order's brackets so the player learns one shape for "attention on a target".

## Detail budget

Three layers. Layer 1 (always): the base silhouette of the glyph, readable at 12 px. Layer 2 (20 px and up): the signature detail (fins, band, rivets, core). Layer 3 (32 px only): interior lines (recoil line, keel line, nested shapes' inner strokes). The builder's rule: draw all three layers as separate paths, and the renderer drops layer 3 below 24 px and layer 2 below 16 px. A glyph that only works with all layers on is rejected at review; each glyph must pass a 12 px squint test on layer 1 alone.

## Refusals

Faction chrome and metal textures; gradients or glows inside glyphs; letters inside glyphs (the arc wedge keeps its letter because the letter is the information, and it sits beside the wedge in the checklist, not inside a button); pictograms that need a tile behind them to separate from the background (the veil and the two weights must do that work); and per-faction glyph variants, which would double the set and break the one-language rule. Armada's richness comes from detail inside the silhouette, not from chrome around it; that is the part worth copying.

## Costs

One icon pass in agent terms: the sixteen glyphs at three layers plus five silhouettes at two sizes, then a legibility pass picturing the shelf at 1080p and at the small-window scale over a bright nebula (the worst background). The real risk is the one Ryan's note implies in reverse: richer glyphs can read worse at 20 px if the signature detail competes with the base shape, which is what the layer rule and the squint test exist to catch. If a glyph fails, it falls back to its round 2 simple form without holding the set hostage.
