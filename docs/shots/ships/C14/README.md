# C14 brood-sac carrier (B22_11): shots (issue 1155)

All in-game shots come from the PC paint run 3 (shared ship job, wrapper OPUS1155_C14_PAINT3.bat, all seven stages, done PASS
22:39 CST Nov 19, commit fbd9da76, blockout v7 on main's R341 Chorus stack; no PAINT_BASE). Results came back on
board/pc-out-1119zu (450f03cc).

- `C14_concept_vs_ingame.jpg`: the accepted concept beside the installed ship in Godot (three-quarter, side, battle camera near).
- `C14_battle_bench.jpg`: the battle camera (r 170) and the near set.
- `C14_blob_sweep.jpg`: the nine-cell sweep (bow, midship, stern from top, side and below) beside the concept regions, from the
  build sheet (`docs/ship_pipeline/build_sheets/chorus_C14/cells.jpg`). A viewing instrument, not a bar (R121).
- `B22_11_q/s/b/t/d/u.jpg`, `chorus_battle.jpg`, `chorus_battle_near.jpg`: the a4 shots from that run, cut to 720 tall.
- `C14_break_B1..B3_{fore,aft}_piece_cut_face_el30/el60.jpg`: a cut at each authored break line (B-1 the foremost), each piece's
  cut face at elevation 30 (the battle camera's angle) and 60 (camera 60). Decks, frames, the brood chambers, the heart vat and
  the guts show; no hollow or flat interior. Rendered in the cloud with `break_renders.py` (C13's script, generalised to any number
  of lines) from the v7 sheet_hull build.
