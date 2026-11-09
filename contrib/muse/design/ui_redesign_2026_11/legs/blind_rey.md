# Issue #270 blind leg: Rey's own concept directions for the battle screen

Written before any other leg was seen, per the issue block. Constraints honoured throughout, from contrib/opus/briefs/ui_spec.md (which stays underneath the redesign): the colour meanings do not change (GILT is the player's own and the primary action, BONE family is text, BLOOD is threat text, ALERT red is reserved for the Nemesis tag, SHIELD and HULL colours are bars only, FRIEND green and FOE lavender carry the two sides in battle); faction colour enters battle only as the enemy crest in the top bar with the faction name in plain BONE; the scale law, the 12 px text floor and the bone focus ring all stay. What the battle screen must carry: the hex field, nameplates (name, shield and hull bars, flagship star), the fleet roster with captain lines, the selected-ship panel, the action bar, the enemy phase bar, round and phase state, Heat, the battle log, the menu.

What is being replaced, from the current captures: a rounded dark card floating over the field, stacked pill buttons, soft borders, a friendly sans. Every direction below is built to make that language impossible, not just unlikely.

## Direction 1: The Plotting Table

The battlefield is a holographic table and the UI lives on its rim. The hex field sits inside a shallow octagonal well; along the rim, etched brass rails carry the readouts, and the roster stands as a rank of small upright markers along the left rim, each marker lit from below like a table piece. Panels do not float: they rise from the rim as projected light, slightly transparent, with a visible projection source line at their base.

- Frame language: octagonal well, rim rails, chamfered corners, projection cones implied rather than drawn.
- Type: a narrow engraved capitals face for labels, tabular numerals for data; nothing rounded.
- Colour use: the projection glow is VERD-tinted for neutral data, GILT only for the player's own pieces and the primary action; bars keep their palette colours; the enemy crest sits in the top rail as an enamel inlay, its colour the only faction colour on screen.
- Faction accent: crest inlay in the top rail plus a thin enamel strip in the enemy's faction colour under the top rail, on campaign screens only (in battle the strip stays INK).
- What it hides that today shows: the battle log is not a standing panel; it is a ticker etched along the bottom rim, expanding upward only when opened. The selected-ship panel hides until a ship is selected, then rises from the rim nearest the ship's side of the table.
- Variations: restrained (dim projection, hairline rails, data mostly BONE) and bold (brighter volumetric glow, a slow scan sweep across the table, markers casting light).

## Direction 2: The Gun Director

A riveted steel fire-control console frames the viewport, as if the player is seated at the ship's own gun director station. The 3D field is seen through the console's aperture. Readouts are segmented and mechanical: Heat and the round counter are arc gauges with needle analogues drawn as hard wedges; the roster is a column of stamped metal tabs, the selected one physically dropped forward; actions are chunky rectangular keys with engraved labels and a hard GILT backlight on the primary.

- Frame language: bevelled steel plates, visible rivets and seams, stencilled labels, apertures with thick frames.
- Type: stencil capitals for structure, a compact grotesque for data; numerals are tabular and large.
- Colour use: grounds are IRON plates instead of flat INK; text is stamped BONE; GILT is a backlight, not a fill, so the primary action glows from behind its key; ALERT is a single red lamp reserved for the Nemesis tag.
- Faction accent: the enemy crest is a stamped brass plate bolted to the top frame, monochrome brass in battle (faction colour is paint, and paint is for the map).
- What it hides that today shows: the battle log becomes a paper-tape strip along the console's lower edge, printed lines only, scrolling; secondary ship stats hide behind the selected tab's flip side (hover or a second click). The menu is a steel plate that slides over the aperture rather than a card that floats.
- Variations: restrained (clean naval steel, minimal wear) and bold (battle-worn plates, scratched paint, one gauge with a cracked lens).

## Direction 3: The Chart Room

A cold plotting chart that happens to be alive. Everything sits on a strict printed grid: hairline rules, coordinate ticks along every edge, data in monospace columns aligned like a typed ops log. No glow except the field itself; the UI is ink on near-black chart paper. Panels are ruled rectangles with corner registration marks, and every value is where the grid says it should be, every screen, so the eye learns one map.

- Frame language: hairlines, ticks, registration corners, ruled tables; square everything.
- Type: one monospace for data, one small-caps face for headings; the discipline is the style.
- Colour use: almost monochrome BONE on INK; GILT appears only as the chart's single annotation colour (the player's own marks, the primary action); threat is BLOOD as a marginal note colour; bars are drawn as ruled scales with a filled portion, still in SHIELD and HULL colours.
- Faction accent: the crest is printed in the top margin like a chart's compass rose, in BONE line work in battle.
- What it hides that today shows: nearly nothing hides; this direction trades immersion for total legibility. The log is the chart's own margin column, always present. Ship panels are ruled slips pinned at the field's edge nearest the ship.
- Variations: restrained (flat print, no light at all) and bold (the chart gains projected light under the print, grid lines faintly luminous, annotations in stronger GILT).

## Direction 4: The Salvaged Console

The console is kitbashed from other ships' hardware, which is this setting's truth: mismatched panels, exposed fasteners, one readout in a different typeface because it came off a different hull, hand-painted labels over stamped ones. It reads warm and used, lit like a workshop. This is the Hullbreakers' aesthetic generalised: trophies and scrap, kept working.

- Frame language: irregular panel seams, mixed frame depths, cable runs along the bottom edge, painted-over labels.
- Type: two faces maximum, one stamped and one hand-lettered for annotations; data stays tabular.
- Colour use: grounds vary slightly panel to panel within the IRON family; a warm work-light tint (EMBER at low strength) rims the console; GILT remains the player's colour and the primary action; nothing else changes meaning.
- Faction accent: the enemy crest is a taken trophy plate, literally bolted over the console's own badge spot, slightly crooked.
- What it hides that today shows: the roster is a parts rack; ships with no orders dim to unlit. The battle log is a chalkboard strip (the setting already writes its choices in chalk at the dark) where the last lines stay legible and older ones smudge.
- Variations: restrained (tidy salvage, everything working, wear at the edges only) and bold (full junkyard cluster, one cracked readout, one panel from an enemy hull in its faction paint, map screens only for the paint).

## Direction 5: The Glass Bridge

The UI is etched onto transparent panes standing at the viewport's edges, like a bridge's glass. Almost nothing is opaque. Data hangs in space with edge-light and faint reflections of the field behind it; panes are tall, thin, and hard-edged, and text is etched rather than printed, glowing where the etch catches light. The field itself carries more of the information load: nameplates become etched tags pinned to ships.

- Frame language: standing panes, mullions, etched rules; depth through parallax between pane layers.
- Type: a light, wide-tracked capitals face; data in the same face at tabular widths; size does the hierarchy, not weight.
- Colour use: panes are near-clear over the INK of space; etched lines in BONE3 brightening to BONE on focus; GILT etches the player's own data; the focus ring becomes an etched corner bracket set, still bone-coloured.
- Faction accent: the crest is etched and back-lit in the top pane, in faction colour (crests are the one place battle allows it).
- What it hides that today shows: panels collapse to their etched header line when idle; the roster is a single etched column that widens only while choosing. The menu is a pane that rotates to face the player. The risk is legibility over bright nebulae, which the spec's panel-over-scenery rule already worries about; this direction must prove itself against the brightest field captures.
- Variations: restrained (one pane layer, faint etch) and bold (three layers, reflections, light play across the glass).

## Wildcard A: Signal and Semaphore

Outside the console family. The UI speaks in light signals: hoists, pennant-like markers and blink codes translated from naval flag practice. Orders are hoisted as signal groups along a yard line at the top; the roster is a set of dressed lines; state changes are announced by signal lamps before text. It is the most distinctive idea in this leg and the least able to carry dense data honestly, so it is offered as a wildcard for its signal language, which a stronger direction could borrow for alerts and phase changes.

## Wildcard B: The Reliquary

Also outside the brief's examples, leaning on the setting instead of the navy. The console is an instrument from a cathedral crossed with a torpedo data computer: dark brushed metal, enamel plaques, gold leaf rather than gilt paint, readouts like altar cards, the roster a row of small reliquary niches with each captain's name engraved. It fits the Sunward Crusade's oath and dawn motifs and the game's grief register better than any naval reference. The danger is kitsch; the restrained variation (enamel and engraving only, no ornament) is the honest test of it.

## Blind chair-lean, recorded before the other legs

Plotting Table and Gun Director feel like the two that can carry the whole game, not just the battle screen: both give the campaign map and the menus a native home. Chart Room is the legibility champion and the one Ryan's phone contact sheet will judge kindly. Glass Bridge is the prettiest and the riskiest. Salvaged Console is the most Voidsworn in flavour. The chair reserves judgement until the ideation and stress-test legs land.
