# Issue 122: Nemesis panel captures (check 122-7)

Taken with godot/campaign/test/nem_panel_shots.gd (Godot 4.7.2, 1920x1080, `--no-tips`) in the cloud sandbox on the software
renderer (Xvfb, Mesa llvmpipe, Compatibility renderer), so the map lighting is plainer than on the PC's Forward Plus. The panel is
the subject. before/ is the #121 branch (cdb36b14) with the same script copied in; after/ is the #122 branch. Same seed and steps.

- p1_first_sector: sector I, the Glasswright commander, one clock step, not met yet (no change expected).
- p2_rotated: sector II after a real sector advance. He fled in sector I; the Chorus commander fed on 3 losses and won its
  meeting. After: the Chorus lesson on the card, "its fleet" (was "his fleet"), and the Glasswright under Earlier hunters.
- p3_return: sector III after a real sector advance; the Glasswright commander is back. After: "He is back: you met him in
  sector I.", and the Chorus commander under Earlier hunters with how it went and its lesson.

Each state has the full screen and the side panel cropped (_panel). contact_sheet.png puts the six panels side by side.
The PC re-shoot: tools/pc/jobs/nem122_checks.bat (pass a #121 clone as its argument for the before set).
