# Codex brief: playtest fixes, batch 3 (Ryan's Nov 2 afternoon run)

Ryan's real 4K screenshots (not phone photos) are in docs/shots/playtest/2026-11-02b/ (ryan_b01 to ryan_b10, right monitor only). House rules: contrib/opus/briefs/feel_pass_2026-11-01.md. Presentation only: no rules or numbers; rules parity must PASS.

1. Move tiles are still bright blue (b02, b04, b07). Cause found: Ryan's saved board look is "living" (user://board_look.cfg), and the soft outlines from #35 only apply to "cine". Apply the soft outline style (thin glowing edges, very faint fill, brighter hover hex, soft path line) to every board look that draws reachable hexes. Also the tiles draw over the hulls (b02: a blue tile shows through the ship): tiles must sit under ships and never tint a hull; fix the render order or depth so a ship always reads on top.

2. Dot or halftone pattern on ship paint (b05 Warlord's Pyre-Barge is the clearest, b02 and b07 too). It shows on most hulls, strongest on the Hullbreakers. Find the cause (likely candidates: a dithered or screen-door alpha fade on hulls near the camera, a shadow or AO dither, a detail or noise texture tiling too small, or mipmaps or texture filtering off on the painted maps) and remove it so the paint reads smooth at every zoom. Show before and after crops of the Pyre-Barge at the same camera.

3. Thrusters disappeared after #35. Ryan: "the ask was more to buff engines, not remove thruster visuals." Bring the manoeuvring thruster visuals back (bright short puffs on turns, small station-keeping flickers while idle), keep the stronger main engine glow and trail, and keep the smooth curves with no sideways shuffle.

4. Text stretched vertically in a story or event card (b10: the title "H-3 Crucible, the Hunger Below" renders one letter per line in a narrow column). A label is getting a near-zero width with autowrap on. Find the panel (event or encounter intro, H3 heading style) and fix its layout so the title spans the card; check every card and modal at 1920x1080 and 3840x2160 with long titles.

5. Sector map backdrop (b01): a red nebula tint covers the right part of the backdrop and stops in a hard edge partway across. Make the sky fill the whole view evenly (no visible cut or seam at any pan or zoom).

6. Damage, new approach (b03, b04, b06, b07, b08: holes look like hollow cardboard cut-outs with flat lines inside, out of place on the detailed hulls). Four rounds of cut-out holes have not worked, so change the method, following Battlefleet Gothic Armada and Homeworld:
   - Normal hits do not cut holes. They leave surface damage on the real hull: dark scorch and burn decals, glowing hot torn-plate rims, small fires and smoke trails from the damaged section, sparks and occasional venting gas. Damage builds up per section as that section's hull drops.
   - A real open break only appears when a section is nearly gone (low section hull) or on death, and then it shows fire inside, not an empty shell.
   - Keep the existing breach code as the heavy-damage stage only, or retire it if the new surface damage covers it.
   Capture each stage on real hulls of two factions plus one Chorus ship.

Tests: parse-check changed .gd; rules parity PASS; the UI check (--ui-shots) passes at 1920x1080 and 3840x2160; destruction checks pass. Report capture file names. Final message: per item what changed (file:line), checks, anything left. Plain ASCII, never the em dash; no commit (the board runner commits and pushes).
