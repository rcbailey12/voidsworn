# Left rail options (campaign map), Nov 11 2026

Ryan on the map's interface (R174): "there's still something that reads as very much AI generated about the UI" and "I don't want to
stray TOO far from here. I like the actual map itself and where we're going. It's more the lefthand rail, the text, etc."

Three mockups drawn by the Board over the real round 3 capture (docs/shots/ui_redesign/briefing/round3_1080/sector_1.png). The 3D map
is untouched; only the rail, the words and the accent colour change. In all three the neon lime becomes the Hollow Sun's own ember
orange, corners are square, the spaced grey capitals are gone, bars become pips, and the chosen route is the one large thing.

- **R1 keep and correct** (R1_keep_and_correct.jpg): the same panel, layout and typeface (Chakra Petch). The chosen route is expanded,
  the others are one line each. The safest change.
- **R2 orders sheet** (R2_orders_sheet.jpg): no panel; the words sit on the darkened edge of the scene. A condensed titling face
  (Big Shoulders Display, OFL) for names, Barlow (OFL) for sentences, Azeret Mono for figures. A three-leg approach strip replaces
  "Sector I of III". The Board's pick.
- **R3 chart margin** (R3_chart_margin.jpg): a narrow legend column with a chart scale; each choice's details sit beside its stop on
  the map; the action sits at the foot of the chart. Spectral (OFL) throughout. Weakness found while drawing it: where choices sit
  close together the notes crowd the stops.

The map's own labels keep today's typeface in these mockups (they come from the capture); in a build they follow the picked option.
rail_mockup_gen.py regenerates the pictures (it expects the fonts in a local folder; paths at the top).

**Ryan's pick (Nov 10, 21:39 CST): R2, with a readability pass.** The pass is R2b_orders_sheet_readable.jpg (full size:
R2b_orders_sheet_readable_1080.png): larger sentences, three text strengths instead of five greys, the action as the one
outlined box, hull as figures with their word. The build spec is contrib/opus/briefs/campaign_rail_orders_sheet.md.
