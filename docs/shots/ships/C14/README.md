# C14 brood-sac carrier (B22_11): shots (issue 1155)

**Current: round G with armour almost everywhere (issue 1291, R374), PC run H.** Shared ship job at commit 625d3f2a (pin
board/pin-1155-c14h, job dir opus1155c14h), done PASS 17:17 CST Nov 20: stages 3 to 7, readback, interiors and death seam all exit
0; stage 5 detail check gated PASS (normal relief 5.22 deg). 512,449 triangles, 16 surfaces. glb sha256 ea473110...5934d07
(manifest row B22_11). Results on board/pc-out-1155c14h (218024d6).

- `C14_runH_concept_vs_ingame.jpg`: the accepted concept beside run H in Godot (three-quarter, side, top, below, close).
- Published Nov 20 after Ryan's yes ("Yes on all", 6:47 PM CT): publish_ship.bat opus1155c14h B22_11 625d3f2a, receipt 7/7,
  readback PASS (29 nodes). Undo on the PC: build\godot\_replaced\B22_11_20261120_185749\UNDO_B22_11.bat; log in
  publish\B22_11_<stamp>\result.txt.
- `C14_roundG_cloud_preview.jpg`: the first round G cloud preview (before the keel wrap), kept as history.

Everything below is the **R341 baseline** (history, superseded by run H).

**R341 baseline (history).** Ryan rejected the R341 Chorus look in game on Nov 20 (issue 1291 rebuilds the
shared Chorus kit, C13 first, then C10 to C14). These shots prove C14's build, export and seams on the R341 stack at fbd9da76;
the appearance and the shared install are not final. Do not queue another bake of this stack: C14 is re-dressed on 1291's kit
after Ryan accepts C13. No shared C14 install is verified (the run installs into its own clone only).

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
