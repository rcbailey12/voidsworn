# Voidsworn issue 1006, round 2: review of the chaired HUD concept KEEL

You are one leg of a design council for the game Voidsworn (a hex-based fleet tactics game in Godot, alternating ship activations, fleets of about 6 to 14 ships). In round 1 this council designed concepts to split the battle screen's tall left sidebar into a small top-left cluster and a bottom bar. The chaired pick was KEEL. The game's owner, Ryan, has read the chaired design and the mockup, applied two rulings (below), and now asks for a review round aimed at one target: the bottom bar still reads as unpolished text. Your job is feedback and a concrete revision of the bottom shelf, not a new concept from scratch.

## KEEL as it now stands (after Ryan's round 1 rulings)

Design size 1920 by 1080. A bottom shelf, full width, 216 px tall, its content on a dark gradient veil (no panels). A small top-left veil cluster holds the turn header ("Round 1", "Your turn", "3 of 3 ships to act") and the objective line. Top right is unchanged from the current game (menu label, enemy fleet line and heat, the Nemesis panel). The shelf, left to right:

- Ship block: ship name in a large display face ("UNYIELDING OATH"), class line under it ("Vigil-class cruiser, Move 0 of 4"), hull line ("Hull 135 / 135") as a text figure.
- Shield readout: "Shield 80 / 80" as a text figure in pale blue with a slim filled bar under it, sitting to the right of the hull line.
- Guns table: three text rows (weapon name, arc letter, range band, state or hit chance): "Sear battery P 1-5 out of range", "Sear battery S 1-5 out of range", "Oath lance F 1-7 92%".
- Status line: one sentence under the guns: "The enemy fleet is focusing its fire on this ship."
- Target and odds: "Target FLEET MARSHAL PETRA VALK" (red, she is the Nemesis), "92% to hit with the Oath lance", "About 16 damage: 7 to shields, 8 to hull", all text.
- FIRE box: the one outlined box on the screen, "FIRE THE OATH LANCE".
- Orders row: "Brace, Concentrated fire, Turn" as text. Command row: "Command, Fire for effect, End ship" as text.
- Log: "Log" plus the last two or three log lines, text, at the shelf's right end.
- Fleet strip along the shelf's foot: one text line, ship name plus hull figure per ship, the acting ship marked with an ember bar.

Ryan's two rulings already applied (do not relitigate): (1) shields are ONE pooled value per ship, shown as the single figure and bar above; the old four-facing shield cross is gone; per-side shield coverage is expert detail behind hover. (2) No keyboard shortcut labels anywhere on the HUD; the key list lives under Controls in the menu.

## Ryan's feedback, the reason for this round (Nov 17, 2026)

"The bottom row still seems super unpolished. Hull and shield aren't together and are approached differently. It's mostly just text instead of visual icons. Look at the Sins 2, BattleTech and Gothic Armada 2 UIs as examples, as well as other strategy games."

## What those reference UIs do (chair's summary; correct it if you know better)

- BattleTech (HBS, 2018): the selected mech's status is a picture, not a paragraph: a paper-doll silhouette with per-location armor shown as filled bars on the diagram itself, plus heat and stability as vertical bars. Weapons are a checklist with icons and damage numbers at the right. Abilities are icon buttons. Almost nothing important is a bare sentence.
- Battlefleet Gothic: Armada 2: the selected ship gets hull and shields as two stacked, icon-headed bars (hull integrity, then a segmented blue shield bar) in one status block; squadrons, boarding and abilities are pictorial icon buttons with cooldown sweeps; the top bar carries resources as icon plus number pairs.
- Sins of a Solar Empire 2: selection and empire panels where every value is an icon plus a number or a bar; ship cards carry small icons; abilities are icon tiles. Very little naked text anywhere; text is reserved for names and tooltips.
- The common pattern: status is drawn (bars, diagrams, segments), actions are icons, text carries names and sentences only.

## The game's standing look rules (these bind your revision unless you argue a scoped exception)

- No panels or boxes; words and glyphs sit directly on darkened scene edges (veils). The FIRE box is the single permitted box. Square corners everywhere.
- One accent colour: ember orange. Pale Glacier blue is reserved for shield readouts only. Red is reserved for the Nemesis only. A muted damage colour marks hurt hull figures.
- Faces: a condensed display face for names (never under 28 px at 1080p), a semi-condensed sans for sentences, a mono face for figures. Nothing under 17 px at design size.
- Decision order must survive (an earlier ruling): ship, hull, shields, guns, target, odds, FIRE, orders, Command, fleet at the foot.
- SAY LESS: secondary detail lives one hover or key press away; the standing surface carries only what the current decision needs.
- The tension to resolve honestly: the reference games put their icons inside boxed tiles and chrome. This game does not use boxes. If you propose icon tiles, say exactly what form they take on a veil without becoming panels, or argue for a scoped exception and price it.

## Your leg must deliver

1. A verdict on each of Ryan's three criticisms (unpolished bottom row; hull and shield treated differently and apart; text where icons should be): agree or disagree, and why, in this game's terms.
2. A concrete revised shelf: grouping and layout in words (columns, rows, approximate widths at 1920), in which hull and shield become ONE visual unit with one grammar, and a line-by-line account of every current shelf item: stays text, becomes a bar or diagram, becomes an icon (describe the glyph), moves behind hover, or is cut.
3. Which reference patterns you would borrow and which you would refuse for THIS game (alternating activations, a decision every few seconds, fleets up to about 14 ships, the no-boxes look), with reasons.
4. The icon set your revision needs: list each glyph, what it means, and how state is shown (ready, unavailable, active, cooling down) without colour chaos and within the ember and Glacier discipline.
5. Honest costs and risks: legibility at 1080p, art and build effort in agent terms (never human days), what it does to the fleet strip at 14 ships, and anything your revision breaks.
6. One thing the current KEEL shelf does better than the reference UIs, that your revision must not lose.

Write in plain prose and short lists. No em dashes or en dashes anywhere. Return only your leg text.
