# Issue 231 captures (UI spec, debrief mock)

Ryan's PC, Godot 4.7.2, RTX 5080, commit 9d4ddc7 (branch opus/issue-231), job tools/pc/jobs/ui231_shots.bat.

- debrief_sheet.png: the one image for Ryan's review round. Left, today's end page; right, the debrief laid out by contrib/opus/briefs/debrief_spec.md, for the same run (Sunward Crusade, lost in sector II after 6 battles). 1920x1080, top and scrolled to the bottom.
- today_top_1080.png, today_bottom_1080.png, mock_top_1080.png, mock_bottom_1080.png: the four frames of the sheet, full width.
- mock_first_top_1080.png: the same run as a first-ever loss (kicker and teaching block).
- mock_top_4k_half.png: the mock at Ryan's maximised 4K window (3840x2066, UI scale 1.91), halved.
- battle_menu_focus_4k.png: the battle menu with keyboard focus on Resume (the bone focus ring, AC5), crop of a 3840x2066 frame.

Checks in the same run: parse check of the 12 changed .gd files, exit 0 each; battle UI check 13 of 13 PASS at 3840x2066, including moment 7 (menu focus, row kept after a toggle, Esc releases the keys); debrief mock clean at 1920x1080 and maximised.
