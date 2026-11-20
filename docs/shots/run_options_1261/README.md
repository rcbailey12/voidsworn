# Run options keeps the keyboard focus (issue 1261)

Cloud pictures (xvfb, OpenGL, 1920x1080, `--no-showcase`), made by `front_end_shots.gd --only=F3_run --expect=1920x1080`.
Run options is opened from the keyboard (focus its button, Accept), then Tab is pressed three times.

- `RO_focus_1261_before_after.png`: both side by side.
- `before_F3_run_options_keys.png`: main at e15439f9. After the drawer opens no control has focus, so Tab and Accept
  do nothing until the mouse is used.
- `F3_run_options_keys.png`: this branch. Focus starts in the drawer, Tab and Shift+Tab cycle only its controls
  (the test option and Done), and Esc or Done gives focus back to Run options.
