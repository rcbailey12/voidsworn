# Issue 728 debrief captures

The run debrief after each required outcome, captured in Godot at 1920x1080 and committed here at 1280x720 (no taller than 720).

- `debrief_92_win_top.png`, `debrief_92_win_lower.png`: a won run. The top shows the gilt headline story slot and the Core sync row with each core name in its PATRONS colour. The lower shot shows the heir choice rows with the candidate rank and the NEXT RUN panel naming the unwon faction with the most progress (Ashfall Hullbreakers in this profile).
- `debrief_92_loss_top.png`, `debrief_92_loss_lower.png`: a normal loss. The same gilt slot and core colours; the lower shot shows the heir rank rows and the loss exits.
- `debrief_92_first_loss_top.png`, `debrief_92_first_loss_lower.png`: a first-ever loss. The top adds the Crusade kicker, first-loss sub and teaching block above the inheritance panel; the lower shot shows the heir rank rows.

Method: `godot/campaign/test/r1_ui_shots.gd` pattern, a real profile, a real Sunward Crusade run through `endRun`, and the shipped end page. The story layer supplies the headline slot line; the capture harness provides a stand-in line so the slot's gilt treatment is visible. The full 1920x1080 originals are in the runner's `out/shots` folder for the reviewer.
