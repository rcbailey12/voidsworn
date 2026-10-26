# A2 engine test: results (Oct 25, 2026)

Ryan's PC: RTX 5080 (16 GB), 240 Hz 4K main screen. Babylon.js 9.30.0 in Chromium (Playwright, D3D11) against Godot 4.7.2 Forward+ (Vulkan). Same six flagships, same max-detail 8K ships (assets/hi), same effects spec, environment, cameras and clock (SPEC.md, trimmed scope R20). Raw numbers: `results/final_2026-10-25/` (max-detail rows from the 8K rerun files `*_max_hi_*` and `*_board_hi_*`, added to the repo Oct 26 after the audit; the plain `fb_max_*` files predate the Babylon 8K loading fix and are not comparable) and `results/run3_2026-10-25/` (the .exe export). A3 proof results: `results/a3_2026-10-26/` and `results/parity_2026-10-25/`. Blind sheets: `blind/` (key: `results/final_2026-10-25/blind_key.json`: A = Babylon, B = Godot).

## Ryan's blind verdict (R27, R28)

- **Godot (B):** better lighting and ship detail in nearly every scene; better asteroids.
- **Babylon (A):** better effects: hull breach, venting smoke and volumetric explosions, destruction, engine trails, the board laser; Chorus and Deathless read better (dark hulls sit too dark under Godot's lighting).
- **Both:** Ithar is broken by its source mesh (an asset problem, not an engine one). Godot's shield hit is not visible enough (a build bug).

Opus read: lighting and detail come mostly from the engine (Godot's SDFGI, SSIL, SSR and soft shadows have no real Babylon equivalent); effects come mostly from build effort (Babylon's effects got more polish rounds) and can be rebuilt in either engine.

## Smoothness (4K unless noted)

| Test | Babylon | Godot |
|---|---|---|
| Capped to the screen, 6 ships: dropped frames in 20 s | 0 | 0 |
| Capped, 24 ships | 0 | 4 |
| Capped, max detail (8K ships) | 2 dropped, but Chromium paced this run at 144 Hz, not 240 (about 153 fps) | 2,472 dropped at 240 Hz (about 138 fps) |
| Capped, max detail at 1440p | 0 | 64 |
| Average frame, 6 / 24 / 40 ships | 1.1 / 2.0 / 2.6 ms | 2.2 / 3.2 / 3.7 ms |
| Average frame, max detail | 5.8 ms | 7.4 ms |
| Worst 1% uncapped, max detail | 21 ms (test-runner back-pressure; 9 ms when capped) | 11 ms |
| Load with the 8K ships | 23 s | 36 s (runtime glTF decode of uncompressed textures; an imported project with compressed textures should be much faster, UNSURE, not measured) |
| Graphics memory with the 8K ships | about 12.5 GB (nvidia-smi peak rise) | about 13 GB (engine counter) |
| Standalone Windows build | none (browser page; Electron plus a native shell would be needed) | 109 MB .exe (round 3), 3.1 s cold to first frame (final round; 3.7 s in round 3) |

Every average frame time is well under 16.7 ms, so both should hold 60 fps everywhere (inferred from averages). At max detail on the 4K screen both run near 140 to 150 fps; neither holds 240.

## Practical side

- **Shipping:** Godot exports a native .exe; Steam through GodotSteam including the overlay. Babylon needs Electron or similar, and Valve's overlay does not support browser-technology games without a native shell (FINDINGS X12).
- **Editor:** Godot has a visual editor Ryan can open; Babylon is code only.
- **Cost:** moving to Godot rewrites the rules runtime (about 246 KB of JS in four files, plus the sim's game copy) and all rendering and UI (about 620 KB), with the Node sim kept as the golden oracle and per-turn parity tests (contrib/muse/reviews/engine_port_plan_synthesis.md). Staying on Babylon costs nothing to move to 9.30 (FINDINGS X16).
- **Outside view:** DeepSeek and Qwen both leaned Godot (contrib/muse/reviews/engine_choice_synthesis.md).

## Decision (R28)

Ryan picked Godot, after a short proof: (1) Babylon-level effects rebuilt in the Godot scene (breach, venting and volumetric smoke, explosions, engine trails, shields, the board laser) plus the dark-hull lighting fix; (2) one slice of the battle rules ported to Godot with a per-turn parity test against the Node sim. If both pass, the game moves to Godot; if either struggles, Babylon stays.

## Audit corrections (Oct 26)

DeepSeek's blind audit (contrib/deepseek/reviews/engine_proof_audit_deepseek_2026_10_25.md) found the max-detail numbers untraceable: they came from the 8K rerun files, which had not been committed. They are in the repo now. Real fixes from it: the capped max row (Babylon ran at 144 Hz), the .exe round labels, the load-time estimate tagged UNSURE, and the board sheets (Babylon's board stills were standard detail while Godot's were 8K; the A3 sheets now use both at 8K). Also fair: the first blind was not a clean single run (depth of field and the Godot breach changed between reads, labels reused), so the A3 open side-by-side sheets carry the final read.

## Proof (R29 to R32)

- Rules: one seeded battle slice ported to GDScript matched the Node sim at every activation in 5 battles on Ryan's PC, plus 60 of 60 seeds in the cloud (R29). The port carries the PRNG, V8's own maths routines, stable sorts and every JS-to-GDScript trap the audit lists; it hashes the full battle state and the PRNG state after every activation.
- Speed: enemy think in 10-a-side fights, worst 0.33 s, inside the 0.5 s bar (R30).
- Effects: Babylon's effect system ported into Godot; Godot frame times improved to about even with Babylon (R31).
- Ryan, Oct 26, on the open sheets: "Godot seems way better. It's very noticeable now." Effects still have room to improve, to be done in Godot (A5). Decision: move to Godot (R32).
