# Godot game dev seat: Fable leg

Tree judged: main at 92fbab94 (checkout /home/user/pin92). Godot 4.7.2 stable, headless, on a 4 vCPU cloud box with no
`godot/gen` (every hull is the placeholder block, no GPU). Findings only, no game file changed.

## Answer first

1. The worst thing a player feels: **the frame freezes for 0.15 to 0.25 s after every move, shot or order**, the first
   time the mouse moves. The threat map is computed on a worker thread, but the hover tip joins it on the main thread.
   Confirmed by a run. This is in the first minute of the first battle, every action, and the frame-median scene gate
   cannot see it.
2. The battle load and the title's background battle each do several seconds of work in one unbroken main-thread
   stretch. Nothing draws, nothing answers a click, and Windows may mark the window "Not Responding".
3. The game is tuned to one PC. It starts every stranger on Max at native resolution, offers no resolution scale, no
   frame cap and no V-Sync switch, and Low still pays for the costly shadows. Every on-disk cache starts empty.

Not repeated here: the codebase audit 1333 (rules parity, saves, battle state, campaign flow) and Neon's Nov 19 health
audit. I checked Neon's items against this tree: P1 (shield skins now cached on disk, fx_shield_cache.gd), P2 (load
budget now 16 ms a frame, fx.gd:166) and the static-cache list (render/static_caches.gd) have landed. P5 (world shaders
rebuilt every battle) and the timer lambdas are still as Neon described; I did not refile them.

How to read "confirmed": **Run** means I ran it headless and give the numbers. **Read** means the code path is certain
from reading but I could not measure the size on real hardware. **Suspect** means it needs a Windows PC with real ships.
All timings are from the cloud box; Ryan's PC is faster, a laptop is not.

Scratch probes (not in the repo): /tmp/claude-0/godot_seat/hover_probe.gd, time_threat.gd, time_rules.gd,
size_probe.gd, idle_probe.gd, idle_break.gd, idle_series.gd. Each is run as
`godot --headless --path godot --script <probe> -- --scenario <name>`.

---

## Findings, worst first

### 1. Moving the mouse after any action freezes the game (Run)

- **Where:** `godot/scenes/battle/battle.gd:3449-3463` (`_on_hover` calls `hud.show_tip(_tip(), p)` on every mouse
  motion event, not only when the hex changes), `:3877-3878` (`_tip` calls `_api_join()`), `:1060-1067` (`_api_join`
  calls `WorkerThreadPool.wait_for_task_completion(_threat_tid)` on the main thread), `:2841-2843` and `:3054-3061`
  (the threat map is requested whenever the battle is idle in the player's turn and the rules version changed),
  `:125` (`danger_on := true`, so this runs for every player by default, with the threat map off).
  `_battle_info` (`:5179`), `_ui` (`:2577`) and 12 more callers join the same way, so `_refresh_ui` freezes too.
- **What the player feels:** a hitch of several frames after every move, shot, order, and at the start of each of their
  turns, exactly when they reach for the next hex. It reads as "the game stutters when I do anything".
- **How confirmed:** hover_probe.gd runs the real battle scene (scenario s13, 13 units, not the bot), issues a move
  through the scene's own `_cmd`, then sends mouse motion events to `_unhandled_input` each frame. Four actions in a row:
  worst mouse-move handler 214, 237, 148, 145 ms; worst frame 232, 255, 162, 158 ms; one blocking join each. Frames with
  no pending threat map are a few ms. time_threat.gd shows the cost is the threat map itself: `threat_both()` takes 130
  to 540 ms across six scenarios, cold or warm. Bot runs never see it (`_danger_shown` is false for the bot,
  `:3071`), and the scene gate reports a median, so no standing check can catch it.
- **Why it happens:** the worker thread only moves the work off the frame if nothing on the main thread asks the rules
  for anything until it is done. The hover tip asks on every mouse event.
- **Fix:** in `_tip`, `_battle_info`, `_ui`, `_target_info` and the other read-only callers, do not join. If
  `_threat_tid >= 0`, answer from the last cached value (most already keep one: `_info_last`, `_ui_cache`) and refresh
  when `_threat_done` fires. Only commands (`_cmd`, `_confirm`, `_on_click`) need the join, and those can show the
  result one frame late instead. Second step: make the threat map cheaper (it is 130 to 540 ms of GDScript for a
  picture that changes by one ship).

### 2. Battle load is one long main-thread stretch under a static cover (Read, size Suspect)

- **Where:** `battle.gd:495-639` (`_begin`): after two frames for the cover, `board.build` (`:558`), `world.build`
  (`:578`), then every `_make_view(u)` (`:586`) run back to back with no `await` until `_warmup()` (`:639`). Each
  `_make_view` loads its hull with a blocking `load()` (`render/ship_view.gd:124`, `:131`, `:137`). There is no
  `ResourceLoader.load_threaded_request` anywhere in `godot/`. The cover is one line of text on a flat colour with no
  bar and no motion (`main/load_screen.gd:14-27`).
- **What the player feels:** the screen says "Preparing the sector..." and nothing moves. If the unbroken stretch
  passes about 5 s, Windows ghosts the window and shows "Not Responding"; a stranger will think it crashed and close
  it. Worst on the first battle after install, when the disk and every cache are cold.
- **How confirmed:** idle_break.gd, scenario s25 (24 units): `add_child(battle)` blocked 508 ms and the first
  synchronous stretch of `start_default` blocked 2,470 ms; a second battle in the same process blocked 5,002 ms in
  idle_probe.gd. Caveat both ways: headless does the first hull cuts inline (the windowed game defers them,
  `battle.gd:500`), and headless loads no real hull files or textures. The real number on a stranger's PC is unknown.
- **Fix:** request every hull scene with `load_threaded_request` when the battle config is known, then build the views
  one per frame (`await get_tree().process_frame` between ships). Give the cover a progress bar fed by ships done out
  of ships total, or at least a moving mark, so a slow PC reads as slow, not dead.

### 3. The title screen freezes right after it appears, then runs a Max battle behind the menu (Read, size Suspect)

- **Where:** `godot/main/main.gd:268-269` (0.5 s after the title shows, `_start_showcase`), `:325-334` (it instantiates
  the whole battle scene and adds it to the tree; the scene is not `external`, so `_ready` runs `start_default` and the
  same `_begin` stretch as finding 2, on the main thread, with the menu already on screen). `:330` gives it the
  player's quality, Max by default. Only Low skips it (`:268`).
- **What the player feels:** the menu paints, then stops answering for a few seconds, just as they move to click
  "New run". After that a full AI battle renders behind every menu at Max, so a weak GPU is slow in the menus too.
- **How confirmed:** by reading; the stretch is the one measured in finding 2 (2.5 to 5 s headless).
- **Fix:** build the showcase with the same threaded loads as finding 2, and spread it over frames. Run the showcase
  at High with no MSAA whatever the setting; it is behind a veil.

### 4. Every stranger starts on Max at native resolution, and there is no way to fit a weaker PC (Read)

- **Where:** `main/main.gd:21` (`"quality": "max"`, `"fullscreen": true`), `main/title.gd:304` and `:315` (the Display
  page has four entries: UI scale, Full screen, Graphics Max/High/Low, Temporal AA). `project.godot:11`
  (`run/max_fps=0`), `:38` (V-Sync on, not a setting). `render/look.gd:161-162` (soft-high shadow filter and 4 shadow
  splits for every quality, Low included). `battle.gd:357-364` (Low changes MSAA, FXAA and the shadow atlas only).
  No use of `scaling_3d_scale`, `scaling_3d_mode`, `Engine.max_fps`, `window_set_vsync_mode` or
  `RenderingServer.get_video_adapter_name()` in game code (only in benches).
- **What the player feels:** on a laptop or a mid card at 1440p or 4K: a slideshow in the first battle, with 4x MSAA,
  SSAO, a 4096 shadow atlas and 4 soft shadow splits at native pixels. Low does not rescue an integrated GPU, because
  the frame is still native resolution with 4 soft shadow splits. If the driver forces V-Sync off, or on a 240 Hz
  screen, the game runs uncapped, title included: full fan noise for a turn-based game.
- **How confirmed:** by reading every writer of the viewport and environment settings. RULEBOOK 3.9 sets the gate for
  Ryan's PC (1440p and 4K); it does not rule on other PCs, so this is a gap, not a contradiction.
- **Fix:** (a) a resolution scale choice (100, 85, 75, 67, 50 percent) using Godot's own `scaling_3d_scale`, with
  FSR 1 or FSR 2 as the mode; the HUD stays sharp because it is 2D. (b) A frame cap choice and a V-Sync switch.
  (c) On first launch only, pick the starting tier from the adapter name and VRAM
  (`RenderingServer.get_video_adapter_type()`, integrated means Low at 67 percent). (d) Low drops to 2 shadow splits
  and the hard or soft-low filter. Look pictures for Ryan before any default changes: Ryan picks.

### 5. A stranger's first run pays every cost Ryan's PC paid long ago (Read, size Suspect)

- **Where:** no `.gdshader` or shader `.tres` file exists under `godot/` (`find` returns 0). All game shaders are code
  strings built with `Shader.new()` at run time (45 call sites outside tests, benches and captures: `world.gd` 13,
  `world_living.gd` 7, `board.gd` 5, and the fx family through `fx_shaders.gd`, 2,372 lines).
  `export_presets.cfg:28` has `shader_baker/enabled=true`, but the baker only bakes shaders it finds in exported
  resources and scenes, so it can only cover the engine's own material shaders on the imported hulls. The caches that
  hide the rest live in `user://`: shield skins (`fx/fx_shield_cache.gd:5`), world bakes
  (`world/world_bake.gd:7`), and the engine's own shader cache.
- **What the player feels:** the first launch and the first battle in each new setting are far slower than anything
  Ryan sees: every shader is compiled from source, every 4096 by 2048 sky and planet map is baked, every hull's shield
  skin is voxelised (Neon measured 23 s for that step before the cache). After a GPU driver update the shader part
  comes back. `load_screen.settle` gives up after 12 s (`main/load_screen.gd:45-48`), so on a slow PC the cover lifts
  while pipelines are still compiling and the first effects hitch in the fight.
- **How confirmed:** the file counts and the cache paths by reading. I could not run an export here, so how much the
  baker really covers is a suspicion (question 1 for Astra). Issue 1334 (first-launch race, held) is the same family.
- **Fix:** move the shader strings into `.gdshader` files loaded with `preload` (the `#define` variants become
  `shader_defines` or separate include files). The exporter can then bake them, the editor can show errors with line
  numbers, and the hand-kept warm-up list in `fx.gd:1741-1801` shrinks. Ship the shield skins in the build (bake them
  in the asset step, keyed as now) instead of in `user://`. Then measure a first launch with an empty `user://` on a
  second PC and make that a standing check.

### 6. Trying Low once leaves FXAA on for the rest of the session (Run)

- **Where:** `battle.gd:360-361` sets `vp.screen_space_aa = SCREEN_SPACE_AA_FXAA` on the root viewport when the
  quality is Low. Nothing ever sets it back; the only other writer is the campaign map's own sub-viewport
  (`ui/campaign/map3d.gd:142`).
- **What the player feels:** a player who tries Low and goes back to High or Max gets FXAA on top of MSAA: a softer,
  slightly smeared picture until they restart the game. The people who hit this are the ones already unhappy with
  performance.
- **How confirmed:** idle_probe.gd: after a Low battle the root viewport reads `screen_space_aa=1`; a Max battle
  started after it still reads `screen_space_aa=1` with `msaa=2` (4x).
- **Fix:** one line: `vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if q == "low" else Viewport.SCREEN_SPACE_AA_DISABLED`.

### 7. The end of a battle can freeze while unfinished hull cuts are joined (Read, size Suspect)

- **Where:** `fx/fx.gd:183-199` (`_exit_tree` calls `release`, which calls `join_death_cut` for every running cut and
  waits for every shield job, on the main thread). `fx/fx_death.gd:1146-1151` says a damaged ship nearly always has a
  cut refresh running. `:1556-1558` records one A16 cut at 2.8 s headless and 5.4 s on the PC before issue 1232 split
  it. `battle.gd:1070-1076` also waits for the enemy's thinking task and the threat map on exit.
- **What the player feels:** after the last kill, or on "quit to title" mid-fight, the screen hangs for up to a few
  seconds before the debrief or the title appears. Longer on a CPU with few cores, because `cut_lanes`
  (`fx_death.gd:1537-1543`) falls to one lane on 4 threads.
- **How confirmed:** by reading. Placeholder hulls cut in no time, so I could not measure it here.
- **Fix:** on exit, detach instead of join: hand the running tasks and their job dictionaries to a small node on the
  root (as `world_bake.gd` already does with its service node) that joins them over later frames and frees the
  resources then. The G-6 exit crash rule is still met, because the node joins before the process quits.

### 8. Text and buttons shrink below the floor on small screens, and the scale ignores Windows display scaling (Run)

- **Where:** `godot/ui/ui_scale.gd:17-23` and `:30-31`: `k = clamp(height / 1080, 0.6, 2.2)`, so the 17 px text floor
  (RULEBOOK 9.4) only holds at 1080 lines and up. No use of `DisplayServer.screen_get_scale` or `screen_get_dpi`.
- **What the player feels:** on a 1366 by 768 laptop the smallest text is 12 px and the menu button is 21 px tall; at
  1280 by 720 text is 11 px and 10 battle buttons are under 24 px tall (Brace, Stance, both Rotate, Command). On a
  14 inch 1080p laptop set to 150 percent in Windows, the game still draws at k = 1.0, so everything is two thirds of
  the size the rest of the desktop is.
- **How confirmed:** size_probe.gd builds the real battle HUD at nine window sizes and reads the ledger's hit boxes.
  The good news: no box was off screen or negative at any size from 1024 by 768 to 3840 by 2160, 5:4 and 21:9
  included; the compact layout works. Only the two small sizes fail the size floors. (The "Rect2 size is negative"
  errors in CI logs are the headless 64 by 64 window, not a bug.)
- **Fix:** start `ui_scale` on a fresh profile at `max(1.0, screen scale)` clamped to the 1.4 ceiling, and raise the
  floor so `k x player scale` never puts text under about 14 px (below that, tell the player in Settings).
  Reopen: Ryan's call, since R136 set the law for his screens.

### 9. The world bake has no fallback when the compute bake fails on a GPU (Read, failure itself Suspect)

- **Where:** `world/world_bake.gd:94-99`: the raster fallback runs only when `not job.compute`. On Forward+ every job
  has `compute = true` (`:84`), so when `_compute` returns no image (no local device `:355-356`, a compile error
  `:360-363`, a short read-back `:393`) the job ends with a null image and a `push_error`. Callers handle null
  (`world.gd:499-500`, `:653-657`) by leaving the sky without its nebula and the planet without its surface maps.
  Nothing is cached, so the same failing bake is tried again every battle.
- **What the player feels:** on a GPU or driver where the worker's own rendering device fails (old Intel drivers and
  the D3D12 fallback path are the usual suspects), every battle has a plain sky and a flat planet, with a wasted bake
  attempt behind each loading cover. No crash, but the game looks unfinished and nobody is told why.
- **How confirmed:** the branch logic by reading. Whether any real GPU fails is unknown; Ryan's does not.
- **Fix:** when a compute job returns no image, run the existing `_canvas` path once (drop `not job.compute` from the
  test, keep `raster_done`), and remember for the session that compute is off.

### 10. The exe has the Godot icon, the Godot splash and no signature (Read)

- **Where:** `export_presets.cfg:33` (`application/icon=""`), `:31` (`codesign/enable=false`); `project.godot` has no
  `config/icon` and no `boot_splash` keys.
- **What the player feels:** before the game draws a pixel: Windows SmartScreen says "Windows protected your PC" on
  an unknown publisher, the file and taskbar show the blue Godot robot, and the first screen is the grey Godot logo.
  For a playtest sent to strangers that is the first impression.
- **How confirmed:** by reading the two files.
- **Fix:** an `.ico` from the game's crest in `config/icon` and `application/icon`, a boot splash in the title's own
  colour (`boot_splash/bg_color`, `boot_splash/image`), and a note in the playtest hand-out about the SmartScreen
  "More info, Run anyway" click until the exe is signed.

### 11. About 4 ms of script runs every frame while nothing happens (Run)

- **Where:** per-frame `_process` on every `ship_view.gd` (`:1512`, one per ship), every `squadron_wing.gd` (`:328`),
  `battle.gd:5014-5088` (un-projects every ship, builds a dictionary per ship and a priority dictionary, calls
  `hud.declutter_plates`), `hud.gd:1329-1389` (`_layout` with `reset_size` every frame), `fx.gd:364`,
  `world_living.gd:938`, `board.gd:698`, two `look_rim.gd` lights (`:45`). `main.gd` never calls
  `OS.low_processor_usage_mode`, and nothing slows down when the window loses focus.
- **What the player feels:** nothing on Ryan's PC. On a laptop it is a quarter of the 60 fps frame gone before
  drawing, and more than half of a 144 Hz frame; and the fans run at full speed while the player is reading a tooltip
  or has tabbed away.
- **How confirmed:** idle_series.gd, 1,500 frames with the player idle: script process time median 3.96 ms, p90
  6.44 ms with 24 units (s25); median 1.74 ms with 6 units (s1). Headless, placeholder hulls, so fx costs are low
  estimates. The per-script split (idle_break.gd) was too noisy to rank; ship views and fx were the largest.
- **Fix:** name plates and the declutter pass only when the camera or a ship moved (a dirty flag set by
  `camera_rig` and by `ShipView` motion); `hud._layout` on change, not per frame; ship views switch their own
  `_process` off when parked with no puffs (the idle bob can move to the hull shader's vertex stage). Cap the frame
  rate at 30 when the window is not focused (`NOTIFICATION_APPLICATION_FOCUS_OUT`).

### 12. Scene structure: everything is built in code, in a few very large scripts (Read)

- **Where:** `scenes/battle/battle.gd` 5,898 lines, `campaign/campaign.gd` 3,885, `fx/fx_death.gd` 3,703,
  `ui/campaign/campaign_ui.gd` 2,493, `fx/fx_shaders.gd` 2,372 (GLSL as strings). The 10 `.tscn` files are stubs; the
  HUD, the title and the campaign screens are made with `Control.new()` calls, and the battle HUD is one custom-drawn
  control (`ui/battle/ledger.gd`). Input is raw key codes in `battle.gd:3196-3260` (`_on_key`), not InputMap actions.
- **What it costs:** not felt by a player today. It fights the team: `battle.gd` holds input, camera, HUD feed,
  threading rules, tips, bot and capture modes in one file, and its threading rule ("every main-thread path that
  reads the rules first calls `_api_join`", `:986-990`) is kept by hand at 15 call sites, which is how finding 1 got
  in. Raw key codes mean no key rebinding and no controller without touching every handler. Shaders as strings mean
  no baker (finding 5) and no line numbers on a shader error.
- **Fix, in order of payoff:** (a) put the rules behind one small "rules client" node that owns the worker tasks and
  hands the scene cached answers, so no caller can join by accident; (b) InputMap actions for the 20 or so battle
  keys; (c) shaders to `.gdshader` files; (d) split `battle.gd` by job (input, presentation runner, tips, capture
  modes) as the fx family already is.

### 13. Small ones, one line each (Read)

- **Window flash at start:** the project opens maximised (`project.godot:37`), then `main.gd:215-218` switches to full
  screen a moment later; the player sees the window jump once. Set the start mode from the saved setting with an
  `override.cfg`, or start in full screen.
- **No monitor choice, no windowed size:** full screen always lands on the primary screen; turning it off gives a
  maximised window only (`main.gd:216`).
- **Play logs grow forever:** one JSON per battle in `user://play_logs/` (`battle.gd:4604-4606`), never pruned. Small
  files, but the world bake cache got a cap (issue 1265) and this did not. Keep the newest 200.
- **Showcase list read from disk on every title visit:** `main.gd:297-312` parses the ship manifest each time. Cache
  it in the static beside `_showcase_i`.

---

## What I checked and found sound

- HUD layout across aspect ratios: no off-screen or negative hit box from 1024 by 768 to 3840 by 2160 (finding 8 is
  only about size).
- Reinforcements are built and cut at load, then hidden (`battle.gd:774`, issue 1289), so an arrival does not load a
  hull mid-fight.
- The death break never reads a live worker's result and falls back to the last finished cut (`fx_death.gd:2952-2958`);
  the kill camera's wait is capped (`:2380-2395`).
- Settings and caches are written to a temp file and renamed (`main.gd:180-188`, `fx_shield_cache.gd:40-56`).
- The exit path clears every GPU-holding static through one list (`render/static_caches.gd`).
- `user://` uses a fixed custom folder (`project.godot:7`), no absolute or PC-specific path in game code.

## Questions for the Astra pass

1. **Shader baker coverage.** Export the pinned build and count what the baker really bakes. Does a `Shader.new()`
   with a code string get anything from it? On a clean Windows profile, how long is the first launch to title and the
   first battle load, and how many pipeline compilations happen after the cover lifts?
2. **Finding 1 on real hardware.** With real hulls on Ryan's PC and on one laptop, what is `threat_both()` in ms, and
   what is the worst frame after a move when the mouse is moving? Is a per-version cached answer enough, or should the
   threat map be made incremental (only the ship that moved)?
3. **Unbroken load stretch.** Log the longest single frame during a cold battle load with real hulls. Is any frame over
   5 s (the Windows "Not Responding" line)? Which of `board.build`, `world.build` and the hull loads owns it?
4. **D3D12 fallback.** `project.godot:43-44` picks Vulkan with a D3D12 fallback, and `export_presets.cfg:44` leaves
   `export_d3d12` on automatic. On a PC where Vulkan fails: does the game start, are any shaders baked for that
   driver, and does `RenderingServer.create_local_rendering_device()` (world_bake.gd:355, on a worker thread) work
   there? Same question for an Intel integrated GPU.
5. **Low-core CPUs.** On 4 threads, `cut_lanes` gives one lane and the pool also carries the enemy's thinking, the
   threat map, shield bakes and Jolt. How often does a kill end in the no-pieces pop, and how long is the battle-end
   join in finding 7?
6. **VRAM at Max, 4K.** 4x MSAA at 4K, a 4096 shadow atlas, 4096 by 2048 sky and planet maps (up to 24 kept in
   `world_bake._cache` as Images plus their textures, `world_bake.gd:6`) and the 4K hull textures: what is the peak on
   an 8 GB card, and does anything spill?
7. **World shaders per battle** (Neon P5, still open): with identical code strings, does Godot 4.7 reuse the compiled
   shader and pipelines for a new `Shader` object, or does each battle recompile? This decides whether a static cache
   is needed or the engine already covers it.
8. **Timers and awaits across scene changes.** `battle.gd` awaits `process_frame` inside worker waits
   (`:957`, `:3112`) and many `create_timer` lambdas. If the battle is freed mid-await (quit to title during the
   enemy's turn), does any coroutine resume on a freed node? The bot runs never quit mid-turn.
9. **Uncapped frame rate.** With V-Sync forced off in the driver, what does the title screen draw at, and what is the
   GPU load? Is a default cap (for example the screen's refresh rate) safe for the captures and benches that set
   `Engine.max_fps = 0` themselves?
10. **Idle cost split.** With a real profiler on the PC (not my noisy headless split), which `_process` owns the idle
    4 ms: ship views, fx, name plates or the HUD layout?
