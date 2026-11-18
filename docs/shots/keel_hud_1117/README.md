# KEEL battle HUD, issue 1021

Review pictures come from the real Godot battle, seed 7, at 1920 x 1080 and camera distance 170. The review copies fit a
1280 x 720 page, with the fingerprint strip outside the frame. The runner publishes the stamped pictures and originals
under `docs/shots/issue-1021-openai/`.

| Review frame | Native frame | What to look for |
| --- | --- | --- |
| [Main](../issue-1021-openai/main_target.png) | [1080p](../issue-1021-openai/main_target_1080.png) | Main's left rail, the reference for the same opening target. |
| [KEEL with a target](../issue-1021-openai/keel_target.png) | [1080p](../issue-1021-openai/keel_target_1080.png) | The left flank is open. The selected ship and target are both above the shelf. |
| [Enemy turn](../issue-1021-openai/keel_enemy_turn.png) | [1080p](../issue-1021-openai/keel_enemy_turn_1080.png) | Turn and enemy progress stay in the top-left; the fleet strip remains. |
| [Log collapsed](../issue-1021-openai/keel_log_collapsed.png) | [1080p](../issue-1021-openai/keel_log_collapsed_1080.png) | One ticker line, with the newest event. |
| [Log open](../issue-1021-openai/keel_log_open.png) | [1080p](../issue-1021-openai/keel_log_open_1080.png) | Three lines above the shelf after a real shot. |
| [Installed ship silhouettes](../issue-1021-openai/keel_silhouettes_01.png) | 1280 x 720 | Every reviewed ship by its installed asset code and faction. |

## Reproduce

- Stage the installed models and textures, then run the Godot import. Run `godot/ui/battle/keel_shots.gd` with
  `--seed 7 --ui-demo --obj ambush --no-tips --keel-out DIR --keel-raw ORIGINALS`. It uses the battle's click, fire and
  end-ship handlers. For main, use the same script with `--keel-baseline` against a main checkout.
- On the PC, use `tools/pc/tmo.bat` to launch the renderer. To rebuild the silhouettes, run
  `godot/ui/battle/icons/make_silhouettes.gd` with `--rendering-method gl_compatibility`, then pass the installed ship
  directory and an optional review directory after `--`. The script checks each GLB against the ship manifest before
  rendering; it uses a side profile, or top view for a thin profile and for the Glasswrights. Use `--proof-only` after the
  review directory to make the sheet without rewriting the icons. Import again after generating new icons.
- Hover the ship, gun, target, fleet slot, Heat or Nemesis for detail. Menu > Controls shows the shortcuts and the floating
  log switch. Click Log to collapse or expand it; L opens the full history even if the floating log is switched off.
