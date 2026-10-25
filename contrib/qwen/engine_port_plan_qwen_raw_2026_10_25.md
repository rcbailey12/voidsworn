# Voidsworn Job C: port plan if Godot wins (with the Babylon-stay list)

Status of the decision: the engine call is NOT made. Parts 1 to 4 apply only if Godot wins. Part 5 applies if Babylon wins, and is also the input for the R22 move of the Babylon test half from 8.20 to 9.30.0 either way. Gate: nothing here executes until contrib/opus/enginetest/RESULTS.md lands on main and the blind reveal is done (as of Oct 25, ~3:40 PM CDT it does not exist; X13 says porting and shipping points go into RESULTS.md and the A3 page). No A2 number is used anywhere below.

Version ground used here: Godot latest stable is 4.7.2 (per evidence; corroborated by Godot's own release post, https://godotengine.org/article/maintenance-release-godot-4-7-2/ and the download archive, https://godotengine.org/download/archive/). Babylon 9.30.0 released Oct 8, 2026 (per evidence; the GitHub releases list and CHANGELOG.md are the primary record: https://github.com/BabylonJS/Babylon.js/releases and https://github.com/BabylonJS/Babylon.js/blob/master/CHANGELOG.md; a secondary summary lead is https://gamedev.net/news/6298-babylonjs-9300-released/). Godot's stable docs branch currently serves the 4.7 docs (https://docs.godotengine.org/). No JavaScript runtime inside Godot 4.7 is taken as given (GodotJS is a community effort, https://github.com/godotjs/GodotJS, and the old QuickJS module repo is https://github.com/godotjs/javascript; leads only, status per evidence).

## Part 1. File-by-file map, if Godot wins

Area picks are recommendations for the spike. The synthesis deliberately does not pick GDScript vs C# globally (one leg: GDScript for a non-coder with an AI builder; one leg: C# as closer to JS), and Opus decides on the spike. Godot supports GDScript and C# side by side, including calling across the two (https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html and https://docs.godotengine.org/en/stable/tutorials/scripting/cross_language_scripting.html).

| Today's JS file (bytes) | Godot 4.7 destination | Pick | Reason |
|---|---|---|---|
| battle.js (131,980) | scripts/rules/battle | C# (spike can flip to GDScript) | Integer-heavy rules that must match the Node oracle bit for bit; C# is the closer language to JS per the synthesis leg, gives explicit 64-bit ints and compile-time type checks; golden tests (Part 2) verify fidelity whichever language wins |
| core.js (35,854) | scripts/rules/core | same as battle | Same body of rules logic; keep the whole rules area in ONE language so state types and hashing are shared |
| campaign_run.js (45,992) | scripts/rules/campaign_run | same as battle | Run-loop rules; must consume the same RNG stream as the oracle |
| campaign_meta.js (32,143) | scripts/rules/campaign_meta | same as battle | Meta progression rules; integer state, golden-tested |
| sim3d.js (95,792) | scripts/sim/sim (rewrite); the Node copy stays untouched as oracle | same as battle | The Godot game needs its own sim; the Node sim3d.js is engine-independent and stays as the balance oracle (per evidence) |
| (RNG lives inside the JS rules/sim; location UNSURE) | scripts/rules/rng (exact port of the JS PRNG) | same as battle | Godot's built-in RNG is seedable and reproducible (https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html) but its stream will NOT match the JS sim's stream; the JS PRNG routine itself must be ported, not replaced |
| data.js (57,094) | res://data/*.json + scripts/rules/data_loader | JSON (no language) + loader in the rules language | Tables carry over as JSON (Part 4); loader re-types integers because Godot's JSON parser turns every number into a float (https://docs.godotengine.org/en/stable/classes/class_json.html; lead: https://github.com/godotengine/godot/issues/61464) |
| campaign3d.js (20,442) | scenes glue + scripts/render/campaign_view | GDScript | Thin binding of sim state to a 3D view; pure Godot API work, nothing to preserve from JS |
| ships3d.js (140,145) | scripts/render/ships + hull scenes | GDScript | Rewrite against Godot's GLB import and mesh/material nodes; no JS logic to keep |
| scene3d.js (101,841) | scenes/battle + scripts/render/scene | GDScript | Camera, lights, environment are Godot scene-tree work; rewrite, not port |
| fx3d.js (96,189) | scripts/render/fx | GDScript | Particles and materials rewritten on Godot's particle/material system |
| wfx3d.js (64,707) | scripts/render/wfx | GDScript | Same as fx3d |
| vfx3d.js (33,958) | scripts/render/vfx | GDScript | Same as fx3d |
| gfx3d.js (50,040) | scripts/render/gfx | GDScript | Same as fx3d |
| ui3d.js (114,406) | scenes/ui/.tscn + scripts/ui/ | GDScript | Godot's Control nodes and scene-based UI; GDScript is the engine's built-in language with the deepest docs coverage (https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_languages.html); "closer to JS" buys nothing in a full rewrite |
| sfx.js (52,712) | scripts/audio/sfx | GDScript | Thin glue over AudioStreamPlayer; Godot supports WAV, Ogg Vorbis and MP3 (https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html) |
| sfx_data.js (482,216) | res://audio/*.ogg or *.wav + tools/extract_sfx.js (offline Node tool, not shipped) | none at runtime | Base64 payloads decoded to audio files once; verify checksums (Part 4); licence stays OPEN |
| head.html | dropped | - | Godot's project settings name the main scene; no page shell exists |
| voidsworn-3d.html | stays untouched as the Babylon fallback | - | The playable build during the whole port (Part 3) |

Why GDScript is safe for the rules area too, if the spike flips: GDScript int is stored as a 64-bit value (https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html) and GDScript float is 64-bit double (https://docs.godotengine.org/en/stable/classes/class_float.html), so integer rules stay exact and float64 math can mirror JS. Mixed-language note: a C# rules core plus GDScript render layer is officially supported (cross-language link above), but it adds a .NET toolchain (dotnet build: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-build) that a non-coder must never have to touch; the .bat in Part 2 hides it. Count note: the map produces roughly 15 new Godot scripts plus scenes, consistent with the synthesis figure of 14 to 16 files for the rendering and UI rewrite (estimate).

Precision caveat that shapes the test design: Godot's default builds store object positions as single-precision real_t, while GDScript's own float type is 64-bit (https://docs.godotengine.org/en/4.5/tutorials/physics/large_world_coordinates.html and https://godotengine.org/article/emulating-double-precision-gpu-render-large-worlds/). Golden state therefore keeps any continuous values in plain 64-bit floats or hashes integers only (Part 2).

## Part 2. Golden-file test design, if Godot wins

Oracle: Node sim3d.js untouched. A new small Node runner (tools/golden_node.js) loads the existing sim3d.js, battle.js, core.js and a scenario file, steps the sim, and writes one JSON-lines record per turn to golden/node/. The Godot side runs a harness script (tests/golden_harness, in the rules language) via Godot's headless mode and -s script execution (https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html; --headless is the documented no-GPU mode on the same page). If C# wins the spike, the harness needs a dotnet build step first (https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-build); the exact headless C# invocation on 4.7.2 is UNSURE and is a spike task.

Scenarios and seeds (fixed, committed to the repo, read identically by both sides):
- S1 seed 1001: single battle, baseline fleets
- S2 seed 1002: battle with admirals, boons, relics active
- S3 seed 1003: battle with modules and several enemy waves
- S4 seed 1004: 30-turn campaign run
- S5 seed 1005: full campaign with encounters and meta progression
- S6 seed 1006: edge cases (retreat, defeat, empty choice)

State hashed per turn (integers only, in this canonical order, keys sorted, fixed separators): scenario id; seed; turn index; RNG draw counter; credits and every resource; both rosters (hull ids sorted, per-ship HP, module ids, admiral ids); active boons and relics as sorted id lists; battle events (actor id, target id, damage, crit flag, kill flag); encounter choice; meta flags. Hash = SHA-256 of that canonical text on both sides (Node crypto.createHash: https://nodejs.org/api/crypto.html; Godot HashingContext: https://docs.godotengine.org/en/stable/classes/class_hashingcontext.html). Test 0 runs before all of this: the ported PRNG emits its first 1000 draws from seed 1001 on both sides and the lists must be identical; the JS PRNG's algorithm and location are UNSURE from the evidence and finding them is spike work.

Tolerance: NONE for all integer rules. Any hash mismatch is a fail, full stop. Float tolerance, stated explicitly: 0.0001 absolute per scalar, applied ONLY to continuous fields (positions, velocities, headings) if the sim state exposes them; those fields are compared numerically field by field and are never inside the hash. Rationale: JS numbers are 64-bit while Godot's default builds use single-precision real_t for engine vector types (links above). If the spike shows the sim state is integer or quantized only, the tolerance applies to nothing and the report says so.

The .bat (Windows 10, PowerShell 5.1, double-click, user never types):
- golden_test.bat sits at the repo root. Double-clicking opens one console window; the bat does nothing but launch PowerShell with -NoProfile and -ExecutionPolicy Bypass pointed at golden_test.ps1 (execution policy is the documented gate for running .ps1 files: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies). All logic lives in the .ps1, written to PowerShell 5.1 syntax only (no PS7-only constructs; judgment call, tagged UNSURE until Opus runs it).
- golden_config.txt holds two paths (node.exe, the Godot 4.7.2 executable; the .NET build of Godot if C# wins). Opus fills it once; the user never edits it unless the window tells them to.
- Flow: read config, run the Node runner, (build if C#), run the Godot headless harness, run tools/compare.js (Node, one implementation of compare logic), write golden/REPORT.txt, print the summary in color, wait for a keypress so the window never vanishes.
- PASS looks like: green text "GOLDEN PASS - 6 of 6 scenarios, all turns matched. Report: golden\REPORT.txt", then "Press any key". Exit code 0.
- FAIL looks like: red text "GOLDEN FAIL - S4, turn 17: hash mismatch; first differing field: credits expected 850 got 845", plus the count of failing scenarios, then "Press any key". REPORT.txt holds every mismatch (scenario, turn, field, expected, actual) and, at the top, the tolerance statement. Exit code 1.
- Broken setup looks like: plain white text "Could not find Godot at the path in golden_config.txt. Ask Opus." No stack traces shown to the user.

Drift policy: the Node oracle is frozen. If a golden fails, the Godot side is wrong until proven otherwise; any intentional rules change is made in Node first, re-baselined, then ported (feeds A3: drift cost per change).

## Part 3. Step order, playable at every step, if Godot wins

Rule for the whole ladder: the Babylon build (voidsworn-3d.html) is not touched at any step, so "playable" is always at least the full Babylon game until the Godot build itself goes playable at step 7. Cutover is a separate decision after step 10, feeding A3. Sizes are the JS bytes each step retires (exact, from the ground-truth list, shown as ranges); Godot-side output sizes are unknown until written and are marked estimate.

- Step 0, gate: engine call lands (RESULTS.md plus blind stills). If Babylon wins, jump to Part 5. Playable: Babylon full game. Size touched: 0.
- Step 1, scaffold and data: Godot project opens to a title scene; data.js converted to JSON; loader validates every table headless. Playable: Babylon full game; Godot shows a title screen only. Size: 55,000-60,000 (data.js 57,094).
- Step 2, language spike: port the PRNG plus one battle function both ways (GDScript and C#), stand up the golden harness v0 and the .bat, Opus picks the rules language. Playable: Babylon full game; Godot passes test 0 headless only. Size: 5,000-15,000 exercised (estimate, slice of core/battle).
- Step 3, battle rules: core.js and battle.js ported; golden battle scenarios S1-S3 green. Playable: Babylon full game; Godot resolves battles headless matching the oracle. Size: 165,000-170,000 (core 35,854 + battle 131,980 = 167,834).
- Step 4, sim: sim3d.js logic ported (Node copy untouched); float tolerance applies here if anywhere; S1-S3 green with full per-turn sim state. Playable: Babylon full game; Godot runs whole battles headless. Size: 95,000-100,000 (sim3d.js 95,792).
- Step 5, campaign rules: campaign_run.js and campaign_meta.js ported; S4-S6 green. Playable: Babylon full game; Godot plays a full scripted campaign headless matching the oracle. Size: 75,000-80,000 (45,992 + 32,143 = 78,135). Steps 1-5 together equal the rules plus sim subtotal of 398,855.
- Step 6, assets: sfx_data.js extracted to audio files with per-file checksums; hull GLBs (Blender-authored; GLB is the kit path per evidence) imported and eyeballed in an asset-viewer scene. Playable: Babylon full game; Godot shows all hulls and plays all sounds in a viewer. Size: 480,000-485,000 in (sfx_data.js 482,216); out is roughly three quarters of the base64 size, about 360,000 (arithmetic estimate, UNSURE until extraction); GLB kit sizes not in evidence (UNSURE).
- Step 7, first Godot playable: battle scene, ships, minimal placeholder UI, sound glue; one battle start to finish using steps 3-4 rules and step 6 assets. Playable: Babylon full game AND a Godot single-battle demo. Size: 310,000-320,000 (scene3d 101,841 + ships3d 140,145 + sfx.js 52,712 + campaign3d 20,442 = 315,140; a sliver of ui3d counted in step 9).
- Step 8, effects: fx3d, wfx3d, vfx3d, gfx3d rebuilt on Godot particles and materials. Playable: Godot battle demo with full effects; Babylon full game. Size: 240,000-250,000 (96,189 + 64,707 + 33,958 + 50,040 = 244,894).
- Step 9, full UI and campaign screens: ui3d rebuilt as Control scenes; campaign playable end to end. Playable: Godot full game (feature-parity checklist) plus Babylon full game. Size: 110,000-120,000 (ui3d.js 114,406). Steps 7-9 retire the rendering plus UI band and complete the 1,555,511 total.
- Step 10, parity and export: whole golden suite green; stills comparison against the A2 blind-stills process; Steam overlay check (X12 is RESOLVED in Godot's favor: a native export has no browser-overlay problem, Valve's doc says browsers do not support the overlay model, https://partner.steamgames.com/doc/features/overlay, and Godot exports a native Windows build, https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_windows.html); export the .exe. Playable: exported native Godot build; Babylon stays the fallback until cutover is signed off in A3. Size: 0 retired; export packaging only.

Every step ends by re-running golden_test.bat, so the user's one-click health check is identical from step 2 onward (feeds A3: verification cost is one double-click per step).

## Part 4. What carries over unchanged, if Godot wins

"data.js tables as JSON" - unchanged means: same tables (ships, weapons, admirals, boons, relics, modules, encounters), same keys, same numbers, moved by a mechanical Node conversion script, no hand edits. Must be re-validated: (a) every file parses in Godot (JSON class: https://docs.godotengine.org/en/stable/classes/class_json.html); (b) Godot parses all JSON numbers as float (same doc; lead: https://github.com/godotengine/godot/issues/61464), so the loader re-types integer fields and a table-by-table SHA-256 checksum is compared against the source tables (Node crypto and HashingContext links in Part 2); (c) any value above 2^53 would lose exactness - none expected in game tables, verified by the checksum step.

"sfx files" - unchanged means: the decoded audio bytes are byte-identical to the base64 payloads in sfx_data.js; verified with per-file checksums at extraction. Must be re-validated: container format is one Godot imports (WAV, Ogg Vorbis, MP3: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html; actual formats inside the base64 are UNSURE); loop points, volume and routing lived in sfx.js logic, which is a rewrite, so every sound is re-tuned by ear against the Babylon build. Licence status: OPEN, carried exactly as stated. The field guide says sound files may not be handed to anyone else; the public repo carries the clips as base64 in sfx_data.js; FINDINGS R10 records Ryan's decision that the repo stays public with sound as is, which does not resolve the licence text tension. Extraction into standalone audio files changes nothing about that tension and must not be treated as resolving it. Flag for A3.

"hull assets via glTF" - unchanged means: the same Blender-authored kit, exported as GLB (the kit path per evidence), feeds Godot without re-authoring; Godot's glTF pipeline is documented (https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html; Blender-to-Godot glTF flow: https://docs.godylonengine.org/en/4.1/getting_started/workflow/assets/importing_scenes.html - correct link: https://docs.godotengine.org/en/4.1/getting_started/workflow/assets/importing_scenes.html). Must be re-validated: per-hull import check (scale, orientation, naming conventions); PBR materials will not look identical to Babylon's renderer, so every hull is compared against the A2 blind stills; whether any GLB uses Babylon-specific extensions is UNSURE.

Also carried: the golden scenario and seed files become shared project data (new, but engine-neutral), and the Node toolchain stays installed for the oracle and the extraction tool for as long as the golden suite runs.

## Part 5. Staying on Babylon: the 8.20 to 9.30.0 move (required either way; this is the Babylon-win plan)

Framing: Babylon guarantees no public-API breaking changes between minor versions; breaking changes land at major versions (https://doc.babylonjs.com/setup/frameworkPackages/frameworkVers). The 8.20 to 9.30 move crosses exactly one major boundary, 9.0, so the break surface is the 9.0 changelog plus anything the team logged at minors. Babylon's own running lists: https://doc.babylonjs.com/breaking-changes/ and https://doc.babylonjs.com/whats-new and https://github.com/BabylonJS/Babylon.js/blob/master/CHANGELOG.md.

Sourced breakages and changes:

1. 9.15.0, migration to TC39 Stage 3 decorators: Babylon moved off TypeScript's legacy experimentalDecorators (primary: https://doc.babylonjs.com/breaking-changes/). The same page scopes it: it only affects you if your own code applies Babylon's decorators. Voidsworn ships plain .js files, so expected impact is none; whether any build step in the repo uses decorators is UNSURE.

2. 9.0.0 breaking entries listed on Babylon's What's New page: "Remove WebGPUEngine dependency on Engine" and a thin-instances change adding ArrayBufferView (primary: https://doc.babylonjs.com/whats-new). Impact hinges on whether the game touches WebGPU or thin instances; both UNSURE from the evidence (fx layers could use thin instances; must be checked in code before the move).

3. 9.0 rendering surface changes that force revalidation rather than documented breaks: clustered lighting, textured area lights, node particle editor, particle flow maps and attractors, volumetric lighting, frame graph now a fully realized v1 feature controlling the whole rendering pipeline, Gaussian splat overhaul, rebuilt inspector (primary feature list: https://doc.babylonjs.com/whats-new; frame graph docs: https://doc.babylonjs.com/features/featuresDeepDive/frameGraph/frameGraphBasicConcepts/; team announcement lead: https://forum.babylonjs.com/t/frame-graph-v1-0-is-now-live/62163; Microsoft's 9.0 post: https://blogs.windows.com/windowsdeveloper/2026-03-26/announcing-babylon-js-9-0/). Action: every lighting and FX scene in scene3d, fx3d, wfx3d, vfx3d, gfx3d is revalidated visually against 8.20 stills; whether the default pipeline's output actually changes for this game is UNSURE until compared.

4. 9.30.0 itself is a patch release focused on correctness including particles (secondary summary lead: https://gamedev.net/news/6298-babylonjs-9300-released/; primary record: https://github.com/BabylonJS/Babylon.js/releases). Precedent that particle behavior can shift between minors exists (community lead: https://forum.babylonjs.com/t/why-do-particles-behave-differently-between-babylon-js-v8-8-5-and-v8-9-0/59481); specific 9.x particle breaks: UNSURE.

5. Community-reported behavior changes inside the window, not on the official breaking-changes page (leads only, UNSURE): BoundingBoxRenderer access change reported at 8.22.3 (https://forum.babylonjs.com/t/boundingboxrenderer-breaking-change-in-8-22-3/60081) and a 9.16.x report (https://forum.babylonjs.com/t/breaking-changes-in-version-9-16-x/63772). Action: smoke-check those APIs if the code uses them.

6. Team risk framing for 9.0: "LOW-MEDIUM risk, most v8/v9 breaking changes don't affect the codebase" (team forum announcement, lead: https://forum.babylonjs.com/t/welcome-to-babylon-js-9-0/62940).

Unchanged by the move, still true if Babylon wins:
- Steam overlay (X12, RESOLVED against Babylon): Valve's doc says web browsers do not support the overlay model and the workaround is embedded Chromium in a native app with offscreen rendering, described as "not easy"; the steamworks.js Electron flag is third-party, not Valve-supported (primary: https://partner.steamgames.com/doc/features/overlay). A dependable overlay therefore still needs a native shell (CEF or similar), which the trimmed A2 scope deliberately excludes (Babylon stays a browser page, no Electron build). This is a shipping cost the Babylon path carries and Godot does not (Godot exports natively: https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_windows.html). Feed to A3.
- Licences remain a non-risk: Babylon Apache-2.0 (https://github.com/BabylonJS/Babylon.js/blob/master/license.md), Havok plugin free under MIT (https://doc.babylonjs.com/features/featuresDeepDive/physics/havokPlugin), Godot MIT if the other path wins (https://godotengine.org/license/ and https://github.com/godotengine/godot/blob/master/LICENSE.txt).
- Sfx licence question stays OPEN exactly as recorded (R10 does not resolve the field-guide tension); it is engine-independent and must be carried in RESULTS.md and A3 either way.

Work list if Babylon wins: pin the package to 9.30.0; grep the code for decorators, WebGPUEngine, thin instances, BoundingBoxRenderer; re-run the A2 benchmark half on 9.30.0 per R22 (both engines at latest stable, since Godot runs 4.7.2); recapture blind stills on 9.30.0; revalidate all lighting and particle scenes against 8.20 stills; log every delta into RESULTS.md and the A3 page per X13; do not build an Electron shell for A2 (out of trimmed scope), but cost the native-shell overlay path as a shipping line item in A3.

## Not checked

- A2 results: RESULTS.md did not exist on main as of Oct 25, ~3:40 PM CDT, and the blind reveal is not done; no benchmark or stills claim is used here.
- Game internals not in evidence: which Babylon APIs the game actually calls (WebGPU, thin instances, decorators, bounding box renderer); the JS PRNG algorithm and where it lives; whether sim state contains continuous floats at all; the real audio format inside the sfx_data.js base64; GLB kit contents, sizes and extensions.
- GodotJS 4.7 status beyond the given evidence (WIP, CI disabled, prebuilts target 4.4); repos linked as leads only.
- Exact headless invocation and build flags for a C# Godot 4.7.2 project from a .bat (spike task).
- Full text of Babylon's CHANGELOG.md between 9.0.0 and 9.30.0; only the items surfaced above are sourced, the rest of the window is UNSURE.
- Output sizes of the Godot rewrite (nothing is written yet); all Godot-side sizes here are labeled estimates.
- PowerShell 5.1 compatibility of the planned .ps1 (judgment call until Opus runs it).
- The licence field guide's exact text (only the summary in evidence).

