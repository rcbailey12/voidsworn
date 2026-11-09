# Issue #270 stress-test pool: candidate directions for the Voidsworn battle screen

You are stress-testing candidate UI directions for a turn-based hex fleet tactics game (space warships, Godot 4.7, PC, designed at 1920x1080 and scaled by a fixed law up to 4K). The owner ordered a full UI redesign: the current UI "clearly reads as a Claude based UI" (rounded cards, pill buttons, soft shadows, friendly sans). The replacement family is the warship console: bridge readouts, hard edges, metal frames, glowing data, little text. The battle screen is the style test; the winning direction then rolls out to every screen (campaign map, menus, debrief, career).

## Locked constraints (from the game's UI spec, not negotiable in any direction)

- Colour meanings are fixed: GILT gold is the player's own (gains, the current step, the primary action, names worth reading). BONE family is text (primary, secondary, dim). BLOOD muted red is threat and loss text. ALERT red (#ff6b5a) is reserved for exactly one thing, the Nemesis tag. EMBER is heat and fire accents. SHIELD cyan (#62ccff) and HULL amber (#ffae42) are bars only, with HULL_LOW red-orange under 35 percent. In battle, FRIEND green (#8ff0a0) and the FOE lavender family mark the two sides (names, rings, the enemy phase bar).
- Faction colour may not appear on battle nameplates, roster names or the ship panel. In battle the enemy's faction is carried by a crest in the top bar and the faction name in plain BONE text. Crests appear on any screen.
- Every battle nameplate carries the ship's name plus shield and hull bars, and a star for the flagship. The roster (about 250 px wide) carries each ship's name, captain line and hull bar, and must work at 20 ships. The selected-ship panel carries stats and state. The screen also carries: the action bar, the enemy phase bar, round and phase state, a Heat readout, the battle log, the pause menu and the end card (both keyboard-focusable, with a visible bone-coloured focus ring), and modal dialogs.
- Text floor is 12 px at 1080p. Any state carried by colour also needs a second channel (width, dash, shape, label or position). Panels sit over bright 3D scenery (nebulae, explosions); text must survive the brightest field.
- Density reality: fleets cluster on adjacent hexes; nameplates overlap; captain and ship names can be long ("Oath-Captain Malek Draven", "Judgement Bell"); a Nemesis fight adds the ALERT tag, a clock readout and adaptation lines.

## The candidates (pooled from three independent ideation legs, duplicates merged by the chair)

D1. The Plotting Table. The battlefield is a holographic table in a shallow octagonal well; UI lives on the rim as etched brass rails; the roster stands as upright markers along the left rim lit from below; panels rise from the rim as projected light. Engraved capitals and tabular numerals. Log is a ticker along the bottom rim, expanding on demand. Crest as an enamel inlay in the top rail.

D2. The Gun Director. A riveted steel fire-control console frames the viewport; the field is seen through its aperture. Roster is a column of stamped metal tabs, the selected one dropped forward. Actions are chunky rectangular keys, the primary backlit in GILT. Heat and round are arc gauges with wedge needles. Log is a paper-tape strip. Crest a stamped brass plate bolted to the top frame. Menu is a steel plate sliding over the aperture.

D3. The Chart Room. A printed plotting chart that updates: hairline rules, coordinate ticks, registration corners, monospace data columns on a strict grid, almost no glow. Bars drawn as ruled scales. Log is the chart's margin column, always present. Crest printed in the top margin like a compass rose, in BONE line work.

D4. Vector C.I.C. A cathode terminal: bezel-bounded casing, chamfered corners, phosphor bloom, raster sweep, segmented line glyphs, telemetry codes (TRK//04-CRUISER). Bars as stepped segments. Log a single ticker line expanding on toggle. Crest a monochrome vector wire-burn stamp in the top bar. (A bitmap dot-matrix cousin exists but removes nameplate bars, which the locked spec forbids; it is not a candidate.)

D5. The Salvaged Console. Kitbashed hardware: mismatched panels and bezels, exposed fasteners and cable runs, hand-painted labels over stamped ones, one readout in a different face because it came off another hull. Roster is a parts rack; log is a chalkboard strip where older lines smudge. Crest a trophy plate bolted over the console's own badge spot, slightly crooked. A warm work-light (EMBER, low) rims the console.

D6. The Glass Bridge. UI etched onto transparent panes at the viewport edges; almost nothing opaque; etched text glows where it catches light; parallax between pane layers. Panels collapse to their header line when idle; the roster widens only while choosing. Crest etched and back-lit in the top pane.

W1. Wildcard: The Admiralty Table. Brass and blued-steel gimbals around a dark drafting slate; classical engineering serif; gold as inlaid brass lines and the player's illuminated route line; the log a formal war diary in italic serif; ships as brass markers. (A lore cousin dresses the same archaic idea as a reliquary: enamel plaques, engraved niches, gold leaf.)

W2. Wildcard: Living Membrane. Organic membrane panels with pulsing edges and soft internal glow, divided by a strict geometric grid; flowing letterforms for headers, monospace numerals for data; gold as bioluminescent marking. Its own proposer flags that it fights the hard-edged brief.

W3. Wildcard: Signal and Semaphore. UI as light signals: orders hoisted as signal groups along a top yard line, state announced by signal lamps before text, pennant-like markers. Offered mainly for its signal language, which another direction might borrow for alerts and phase changes.
