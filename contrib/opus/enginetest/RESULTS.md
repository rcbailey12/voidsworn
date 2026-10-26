# A2 engine test: results (Oct 25, 2026)

Ryan's PC: RTX 5080 (16 GB), 240 Hz 4K main screen. Babylon.js 9.30.0 in Chromium (Playwright, D3D11) against Godot 4.7.2 Forward+ (Vulkan). Same six flagships, same max-detail 8K ships (assets/hi), same effects spec, environment, cameras and clock (SPEC.md, trimmed scope R20). Raw numbers: `results/final_2026-10-25/` and `results/run3_2026-10-25/`. Blind sheets: `blind/` (key: `results/final_2026-10-25/blind_key.json`: A = Babylon, B = Godot).

## Ryan's blind verdict (R27, R28)

- **Godot (B):** better lighting and ship detail in nearly every scene; better asteroids.
- **Babylon (A):** better effects: hull breach, venting smoke and volumetric explosions, destruction, engine trails, the board laser; Chorus and Deathless read better (dark hulls sit too dark under Godot's lighting).
- **Both:** Ithar is broken by its source mesh (an asset problem, not an engine one). Godot's shield hit is not visible enough (a build bug).

Opus read: lighting and detail come mostly from the engine (Godot's SDFGI, SSIL, SSR and soft shadows have no real Babylon equivalent); effects come mostly from build effort (Babylon's effects got more polish rounds) and can be rebuilt in either engine.

## Smoothness (4K unless noted)

| Test | Babylon | Godot |
|---|---|---|
| Capped to 240 Hz, 6 ships: dropped frames in 20 s | 0 | 0 |
| Capped, 24 ships | 0 | 4 |
| Capped, max detail (8K ships) | 2 | 2,472 (about 135 fps) |
| Capped, max detail at 1440p | 0 | 64 |
| Average frame, 6 / 24 / 40 ships | 1.1 / 2.0 / 2.6 ms | 2.2 / 3.2 / 3.7 ms |
| Average frame, max detail | 5.8 ms | 7.4 ms |
| Worst 1% uncapped, max detail | 21 ms (test-runner back-pressure; smooth when capped) | 11 ms |
| Load with the 8K ships | 23 s | 36 s (runtime glTF decode; an imported Godot project uses compressed textures, est. 10x faster) |
| Graphics memory with the 8K ships | about 12.5 GB | about 13 GB |
| Standalone Windows build | none (browser page; Electron plus a native shell would be needed) | 109 MB .exe, 3.7 s cold to first frame |

Both are smooth everywhere at 60 fps; at 240 Hz Godot's max mode runs about 135 fps.

## Practical side

- **Shipping:** Godot exports a native .exe; Steam through GodotSteam including the overlay. Babylon needs Electron or similar, and Valve's overlay does not support browser-technology games without a native shell (FINDINGS X12).
- **Editor:** Godot has a visual editor Ryan can open; Babylon is code only.
- **Cost:** moving to Godot rewrites the rules runtime (about 246 KB of JS in four files, plus the sim's game copy) and all rendering and UI (about 620 KB), with the Node sim kept as the golden oracle and per-turn parity tests (contrib/muse/reviews/engine_port_plan_synthesis.md). Staying on Babylon costs nothing to move to 9.30 (FINDINGS X16).
- **Outside view:** DeepSeek and Qwen both leaned Godot (contrib/muse/reviews/engine_choice_synthesis.md).

## Decision (R28)

Ryan picked Godot, after a short proof: (1) Babylon-level effects rebuilt in the Godot scene (breach, venting and volumetric smoke, explosions, engine trails, shields, the board laser) plus the dark-hull lighting fix; (2) one slice of the battle rules ported to Godot with a per-turn parity test against the Node sim. If both pass, the game moves to Godot; if either struggles, Babylon stays.
