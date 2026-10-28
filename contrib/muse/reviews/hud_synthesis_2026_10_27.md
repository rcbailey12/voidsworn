Chair synthesis: battle HUD readability audit (Oct 27 program item 6). Four blind legs on the same nine-image pack pinned to 68b42ce406286eb95ea7df6aaf3f683c1231b51d: DeepSeek (2 BLOCKERs; Start Clear, Move Cluttered, Attack Weak, Top-down Adequate), Qwen (PASS WITH FIXES overall; Top-down FAIL; 1 BLOCKER), Argon (FAIL in all four states; 5 BLOCKERs), and Rey (this chair's own leg, firsthand read of all nine images). One framing correction applies to two legs and is stated up front: all nine shots are Godot G2 captures at three commits (a259c36, b7ca8c1, fa8106d). There is no exe or browser build in the pack, so every "two products disagree" observation is cross-capture drift between G2 builds, and the pack does not say which batch is current.

OVERALL VERDICT: NOT READY on readability. No BLOCKER survives at that weight. Seven FIXes form a tight, convergent core, most of them cheap: the awareness layer of the battle screen (seeing the enemy, reading the board's colours, trusting the tutorial) is weaker than its command layer, which reads well.

TOP FINDINGS

1. The enemy is not visible in the start state or the threat view (FIX, top). Confirmed firsthand in battle_hud_after.jpg, battle_start_after.jpg (narration: 9 Hegemony ships; none in frame), 01_start.png (enemy plates clipped at the top edge behind chrome, ships off-frame) and 04_threat_topdown.png (the threat view shows three friendly ships and no enemy while the narration reports contact). Two legs converged; DeepSeek rated both states fine and never mentioned it, which is the clearest calibration gap in this audit.

2. Nameplates merge in the carrier cluster (FIX). Bomber wing plates overprint into garbled single strings in all five carrier shots, and the tutorial card's buttons cover the flagship's plate. The densest formation in the game is the one whose units cannot be told apart.

3. The Engagement legend is collapsed and unlabeled in all nine images (FIX), including the capture named for it. Four colour systems on the board (gold reach, purple hexes, sector washes, ring colours) have no key anywhere in the pack. The 03 sector overlays run to the board edge past the stated weapon ranges, keyed as neither arcs nor threat.

4. The tutorial card contradicts the screen (FIX, Argon-only, chair-confirmed in all three batches). It says the Command glows gold; in every image Command is dark and Pass or End turn is gold. It also covers the approach lane and the carrier plates. First-battle text teaching a wrong cue is the highest-leverage single fix in this audit.

5. Move preview omits threat, turns and path (FIX). Both move shots give cost and guns-bearing only; 02 adds a tooltip covering the selected ship's own clipped nameplate, and battle_sheet_move_preview.jpg's destination arrow renders in front of a different ship from the one selected.

6. Right-column overflow on boon ships (FIX, Argon-only, chair-confirmed). The Nine Lives card fills the column, crushes or removes the help paragraph, and clips the dark red warning text at the scrollbar; that warning text is also the lowest-contrast text on the card in the PNG batch.

7. Toggles and wing stance show no active state (FIX). Threat and Top-down buttons are indistinguishable from inactive buttons in the very view they activate; wing stance is prose above three identical buttons.

NOTES CARRIED

Help duplication (full hotkey paragraph plus the one-line bottom strip in the same frame), header and wording drift across capture batches (activation vs turn, blackletter vs serif), the section bars that read as shield bars above shield prose, "Turns 2" beside "Movement 4 of 4" with no stated relation, and edge-clipped friendly ships at battle start (01). Qwen's numeric attack half passed on its merits: the tooltip's per-weapon range math is the best information design in the pack, and every leg that engaged with it said so.

WHAT DISSOLVED

- Argon's (G) hotkey collision: read directly in all three cited images, Launch squadron is "(0)" and Board is "(G)". No collision exists. The residue (Concentrated fire, Wings and stance buttons carry no hotkey labels) stands as coverage NOTE inside finding 7's family.
- Qwen's build attribution and finding 8's direction: corrected to cross-capture drift as stated above; the underlying duplication observation survives as a NOTE.
- Argon's shield-bar framing of finding 09: the bars are per-section bars, but the layout invites the misread (the chair's first impression matched the leg's), so it carries as a layout-clarity NOTE rather than dissolving outright.

LEG WEIGHTS

Argon was the strongest leg by catch count (tutorial contradiction, overflow, toggle states, move gaps) under its usual inflation, with one headline claim failing firsthand verification. Qwen was the most balanced leg and the only one to fail the threat view, the audit's worst state; its state grades are the closest to the chair's. DeepSeek corroborates the legibility family (small card text, tooltips over the board, unexplained tinting) and is discounted on state verdicts: it cleared the two states this audit fails hardest.

QUESTIONS FOR RYAN

1. Visual verdicts are yours by standing rule, so one for your playthrough rather than a ruling now: in the threat view, should enemy ships be framed in view by default even at the cost of zooming out past the friendly formation? The fix direction (frame both fleets vs edge indicators) changes what G2 builds; flag it when you test.
2. No other human-direction questions arise from this audit.
