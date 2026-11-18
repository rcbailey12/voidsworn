# Issue 1006 round 2, blind Rey leg (written from the pack alone, before the external legs)

## Verdicts on Ryan's three criticisms

All three land. (1) Unpolished: yes. KEEL's shelf is the old rail's column laid sideways; it inherited the rail's text-first grammar and only rearranged it. The two-row balance pass fixed the depths, not the grammar. (2) Hull and shield apart and different: yes, and it is the clearest tell. Hull is a naked figure on its own line; the shield is a figure plus a bar, parked to the right like an afterthought. They are the same kind of fact (how much of this ship is left, in two layers) and the shelf treats them as unrelated facts in unrelated forms. (3) Text instead of icons: yes for actions and weapons. Orders and Command are verb phrases in a row; the guns table is a spreadsheet. Names and the status sentence should stay text; almost everything else on the shelf is a state or an action, and states and actions read faster as glyphs and bars.

## The revision: one integrity block, one grammar

The shelf keeps KEEL's geometry and decision order. What changes is the visual grammar: every status becomes label glyph plus bar plus figure, every action becomes a glyph with its word under it, and text survives only where the words are the information (names, the status sentence, the odds sentence, the log).

Ship block (about 400 px wide), top to bottom:
- Name (display face, as now) and class line (as now, Move stays on the class line).
- THE INTEGRITY BLOCK, one unit with two identical rows: a small glyph, a slim bar (about 150 px), the figure at the bar's right end. Row one: hull glyph (a plating chevron), bar in warm ink, figure "135 / 135"; the bar and figure take the damage colour as hull falls. Row two directly under it: shield glyph (a diamond, the in-space shield ring's shape), bar in Glacier, figure "80 / 80". Same widths, same heights, same alignment: two layers of one thing, read in one glance, shields on top of hull in the order damage arrives if the Board prefers; my pick is shield row first (it is spent first), hull second.
- Under the block, the expert shield detail stays behind hover, as ruled: coverage per side and routing state on a small top-down facing diagram in the hover, never standing numbers.

Guns (about 380 px): each weapon becomes glyph plus name plus state. A weapon-class glyph at the row's left (lance: a long spearhead; battery: a three-shot burst; torpedo: a finned dart; point defence: a spray fan), the name in sentence face, then the range band as a small drawn band (a line with its near and far ticks) instead of "1-5", and the state as one figure: the hit chance in ember when in range, or a dimmed "out of range" with a range glyph. The arc letter becomes a tiny facing wedge (a top-down ship tick with the firing arc shaded) at the row's right; P, S, F letters go behind hover. Three rows as now; a fourth weapon pushes the status line behind hover rather than shrinking anything.

Target and odds (about 360 px): the target name stays text, red for the Nemesis as now. The odds become a figure-led line: a reticle glyph, "92%", then the sentence shortened to "to hit with the Oath lance" only while learning matters; the damage split becomes a drawn split bar: one slim bar divided into a Glacier segment (to shields) and an ink segment (to hull) with the two figures at its ends. The split is the one place a bar teaches something a sentence cannot: proportion at a glance.

FIRE (about 320 px): the one box stays, with a lance glyph at its left inside the box. It remains the shelf's single piece of chrome and the eye's terminus.

Orders and Command (about 340 px, two rows as now): each becomes a glyph button drawn directly on the veil, no tile, no outline: the glyph at 24 px with its word under it at 15 to 17 px in the sentence face. Brace: a shield diamond over a chevron. Concentrated fire: a reticle with a centre dot. Turn: two curved arrows. Fire for effect: a burst with radiating ticks. End ship: a right-pointing chevron pair (next). Command (the resource) is not a button: it becomes a small standing figure at the rows' left, a star glyph plus its number, since it is a resource, not an action. State without colour chaos: ready is full strength ink; unavailable is dimmed to the third text strength with the glyph struck by nothing (dimming only); active or chosen takes an ember underline bar, the same mark the fleet strip uses for the acting ship; cooldown, where an order has one, is a thin ember line draining under the glyph, never a sweeping pie in a box.

Status line: stays a sentence, stays on the second row under the guns. It is the one piece of prose the shelf needs; a sentence is the right form for "the enemy fleet is focusing its fire on this ship."

Log: unchanged. Text is correct there; it is a record, not a control.

Fleet strip: each ship becomes a miniature of the integrity block's grammar: name, then one slim combined bar (Glacier segment for shield over ink for hull, stacked in the same two-row form at 8 px total height), hull figure at the right. At 14 ships the strip wraps to two rows inside the shelf's foot or scrolls by hover; the grammar does not change, only the count.

## Borrow and refuse

Borrow from Armada 2: the stacked icon-headed bars as one status block (that is the hull and shield fix, almost exactly), and cooldown as a draining element on the action itself. Refuse its chrome: boxed tiles, portraits in frames, and its density; Armada can afford density because its decisions are slower.
Borrow from BattleTech: the principle that status is a picture, and specifically a diagram for spatial facts (its paper doll). Our spatial shield fact (coverage by facing) becomes the hover facing diagram. Refuse the paper doll itself as a standing element: our facings carry coverage, not health, since the Nov 14 ruling, so a standing doll would advertise per-side health we no longer have. That is exactly the confusion Ryan caught in round 1.
Borrow from Sins 2: the discipline that every value pairs an icon with a number, and its selection-card economy (one card, everything about the selection, nothing scattered). Refuse its top-bar resource sprawl and its tooltip dependence; our shelf must read without hovering.
Refuse from all three: hotkey badges on the glyphs (Ryan has ruled key labels off the HUD; the glyphs carry words, not keys), and rarity-colour coding of states.

## Icon set needed

Hull (plating chevron), shield (diamond), lance (spearhead), battery (burst), torpedo (finned dart), point defence (spray fan), arc wedge (top-down tick with shaded arc), reticle (hit chance and Concentrated fire share the reticle family, distinguished by the centre dot), Brace (diamond over chevron), Turn (curved arrows), Fire for effect (burst with ticks), End ship (double chevron), Command (star), range (a measured line with end ticks, for out-of-range state). Fourteen glyphs, all drawable in the game's existing line style; one icon pass in agent terms, plus a legibility check at 1080p and at the small-window scale factor before the Board builds the rest.

## Costs and risks

Legibility is the real risk: glyphs at 24 px on a veil over a moving starfield must survive the worst background, so each glyph needs the same dark halo discipline the text gets from the veil, and the Board should picture the shelf over a bright nebula before adopting. The guns table loses its spreadsheet scanability for players who read numbers first; the figures stay, but a player comparing three weapons' bands now reads three drawn bands, which is faster once learned and slower on day one. Build effort in agent terms: one icon set and one shelf rebuild, larger than the text-only KEEL build, smaller than any new screen. At 14 ships the fleet strip is the pressure point, as noted. The revision does not touch the top clusters, the Nemesis panel, or the log's behaviour.

## What KEEL already does better, to keep

KEEL's decision order is a single left-to-right sweep that ends at the one box. The reference UIs scatter the decision (BattleTech splits weapons right and abilities centre; Armada rings the ship card with systems). The revision keeps every element in KEEL's order and changes only its form; if an icon ever has to move to earn its place, the order wins and the icon goes behind hover instead.
