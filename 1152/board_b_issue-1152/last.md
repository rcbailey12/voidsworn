C19_51 passed stages 4 through 7 on main and the branch. Both exports installed in isolated Godot projects. The battle views look alike, with small differences in grain and highlights up close.

![C19_51 deck comparison](docs/shots/issue-1152-codex/C19_51_game_d.png)

[Battle](docs/shots/issue-1152-codex/C19_51_game_battle.png) · [Battle zoom](docs/shots/issue-1152-codex/C19_51_game_near.png) · [Bow](docs/shots/issue-1152-codex/C19_51_game_q.png) · [Side](docs/shots/issue-1152-codex/C19_51_game_s.png) · [Below](docs/shots/issue-1152-codex/C19_51_game_b.png) · [Top](docs/shots/issue-1152-codex/C19_51_game_t.png) · [Underside](docs/shots/issue-1152-codex/C19_51_game_u.png)

- The installer and nine PC copy jobs now handle PNG maps. The installer test passed with mixed JPEG and PNG maps and rejected stray names.
- PNG encoding took **1.72 s**, below the 10 s threshold for changing compression. Full stage 7 took **151.2 s on main and 160.6 s on the branch**, excluding the solo GPU wait.
- C19_51’s maps grew from **8.10 to 28.42 MiB**. Across nine saved bakes, the average grew from **7.07 to 20.76 MiB**.

The standing suite finished with 75 passes and two recorded baselines. All 85 headless Godot checks, the bot battle, and the rebaked A16 seam check passed. The A16 model was byte-identical after rebaking, so only its record changed.

The [README](contrib/codex/pipeline_1119/README.md) records the timing estimates for the original GPU waits, the measured retests, and the files changed. Nothing was committed.