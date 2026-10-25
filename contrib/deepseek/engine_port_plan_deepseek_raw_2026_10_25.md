Engine port plan synthesis

Job C, conditional on Godot winning. Also usable if Babylon wins.

This plan is not a ruling. The engine choice synthesis is a two-leg model verdict for Godot 4.7 with two conditions. Condition 1 is the A2 benchmark on the RTX 5080, which both legs defer to. Condition 2, the Steam overlay question, is resolved in favor of native export per X12. A2 can still flip the pick, and the blind stills have not been revealed. As of the pack's check on Oct 25, contrib/opus/enginetest/RESULTS.md does not exist on main, so no A2 numbers are used here and none are predicted. The trimmed A2 scope keeps Babylon as a browser page, so A2 measures rendering and effects, not standalone shipping. A Babylon win on A2 rendering would not by itself solve the X12 native-shell shipping question.

R22 moves the Babylon half of the test from 8.20 to 9.30.0, released Oct 8, 2026. Part 5 below is therefore about an 8.20 to 9.30 move, not about staying on 8.20. The game is PC-only. The phone target is dropped entirely.

Every Godot section is written as "if Godot wins". Part 5 is equally required.

Part 1. File-by-file map to a Godot 4.7 project layout

1.1 Language picks by area

The synthesis does not pick GDScript or C# globally. Godot allows multiple languages in one project, and the docs explicitly describe mixing gameplay logic in GDScript with C# or C++ for complex algorithms and maximum performance (Godot scripting languages, lines 18 to 22). The picks below are provisional recommendations for Opus's spike, not a final ruling.

Area | Pick | Reason tied to this area
Rules and campaign state (battle.js, core.js, campaign_run.js, campaign_meta.js) | C# | This is the largest and most type-sensitive body of code: 245,969 bytes across the four files. The JS rules use object shapes, constants, and integer combat math. C# classes, enums, and static typing catch translation drift at compile time, and C# double matches JavaScript number precision for rule math. Qwen's point that C# is the closer language to JS is strongest here. The cost is a .NET SDK and a compile step, which is acceptable because rules change less often than visuals.
Data loading (data.js tables) | C# loader plus JSON data | The tables are plain data and become JSON. A typed C# loader gives one place to validate ids, required fields, and numeric ranges before the rules read them. This is the same language boundary as the rules, so there is no cross-language data-shape mismatch.
Simulation interface and golden harness | GDScript | The harness is small tooling, not game logic. It runs headless through Godot's --script option, reads JSON fixtures, hashes canonical state, and writes a report. GDScript needs no build step, which keeps the double-click test runner simple. sim3d.js stays in Node and is not ported.
Rendering and effects (ships3d.js, scene3d.js, fx3d.js, wfx3d.js, vfx3d.js, gfx3d.js) | GDScript | This code is mostly scene-tree orchestration: instancing meshes, setting hardpoint transforms, driving shaders and particles, and responding to signals. GDScript has the tightest editor integration and the fastest visual iteration, with no rebuild for every tweak (Godot scripting languages, lines 38 to 39). If profiling later finds a per-frame hot spot, that one routine can become a C# island without rewriting the whole renderer.
UI (ui3d.js) | GDScript | UI is Control nodes, themes, and signal wiring. GDScript is the shortest path from a scene file to a working button, and the editor previews it directly. C# would add a build step for layout changes with no rule-side benefit.
Audio (sfx.js player code, sfx_data.js clips) | GDScript | The player code is only 52,712 bytes and mostly calls AudioStreamPlayer and bus controls. There is no performance reason to use C#. The 482,216 bytes of sfx_data.js are content, not logic, and become audio files.
Campaign presentation (campaign3d.js) | GDScript | The pack describes this as campaign presentation, not pure rules. It belongs on the render/UI side, where GDScript's scene integration is the better fit.

If the C# spike is rejected because the .NET setup is too much friction for Ryan, the fallback is GDScript for rules as well. The synthesis says both are viable. The fallback does not change the test design or the step order, only the language of the rule scripts.

C# is viable for a Windows desktop build. The C# docs state that projects written in C# using Godot 4 cannot be exported to the web, but that is not a blocker because the game is PC-only (Godot C# basics, lines 12 to 13). The same page states .NET 8.0 for the 4.x line and that the .NET SDK is installed separately (lines 20 to 25). The exact .NET SDK version for 4.7 should be checked at spike time and is tagged UNSURE here because the pack does not state it.

1.2 Project layout

If Godot wins, the repository root keeps sim3d.js untouched and gains a Godot project. A workable layout is:

- project.godot and export_presets.cfg at the root, replacing head.html as the page shell.
- res://data/ for tables.json and sfx_manifest.json.
- res://rules/ for the C# rule assembly: battle, core, campaign run, campaign meta, and the data loader.
- res://scripts/render/ for the GDScript ship, scene, effects, weapon effects, VFX, and graphics bridge.
- res://scripts/ui/ for the GDScript HUD and menus.
- res://scripts/audio/ for the GDScript sound player.
- res://scenes/ for .tscn battle, campaign, hangar, and UI scenes.
- res://audio/clips/ for decoded WAV or OGG clips.
- res://assets/hulls/ for GLB or glTF hull assets.
- res://tests/ for fixtures, the headless harness, and expected hashes.
- tools/ for the .bat launcher and the Node comparator.

The built voidsworn-3d.html is replaced by a Windows export (.exe plus .pck). Godot's Windows exporter bundles project files into a data pack and a smaller optimized binary without the editor (Godot exporting for Windows, lines 7 to 12).

1.3 File map

Byte sizes are from the Job C evidence pack, file sizes section. They are ground truth and are not re-estimated.

Today's file | Bytes | Godot 4.7 destination | Language | Notes
battle.js | 131,980 | res://rules/battle/ (battle engine and turn resolver, likely split into two or three C# files) | C# | Largest rules file. Split by concern, not by JS file boundary. Keep integer combat math exact. Do not use Godot physics for rule outcomes.
core.js | 35,854 | res://rules/core/ | C# | Shared rules types, constants, and helpers used by battle and campaign.
data.js | 57,094 | res://data/tables.json plus res://rules/data/DataLoader.cs | C# loader, JSON data | The tables are ships, weapons, admirals, boons, relics, modules, and encounters. Conversion is a format change, not a content change.
campaign_run.js | 45,992 | res://rules/campaign/CampaignRun.cs | C# | Run state, encounters, rewards, and save shape.
campaign_meta.js | 32,143 | res://rules/campaign/CampaignMeta.cs | C# | Meta progression and unlocks.
campaign3d.js | 20,442 | res://scripts/render/campaign_3d.gd | GDScript | Campaign presentation, not pure rules.
sim3d.js | 95,792 | Stays at repository root as sim3d.js | Node | Not ported. Stays the balance oracle. The Godot harness consumes its JSON output.
ships3d.js | 140,145 | res://scripts/render/ships/ (one ship view script plus per-class scripts) | GDScript | Mesh instances, hardpoint transforms, hit feedback.
scene3d.js | 101,841 | res://scripts/render/scene_3d.gd plus res://scenes/battle.tscn | GDScript | Camera, lighting, environment, battle scene assembly.
fx3d.js | 96,189 | res://scripts/render/fx_3d.gd | GDScript | General effects.
wfx3d.js | 64,707 | res://scripts/render/wfx_3d.gd | GDScript | Weapon effects.
vfx3d.js | 33,958 | res://scripts/render/vfx_3d.gd | GDScript | Visual effects.
gfx3d.js | 50,040 | res://scripts/render/gfx_3d.gd | GDScript | Graphics bridge and shared rendering helpers.
ui3d.js | 114,406 | res://scripts/ui/ui_3d.gd plus res://scenes/ui/ | GDScript | HUD, tooltips, buttons, end screen.
sfx.js | 52,712 | res://scripts/audio/sfx.gd | GDScript | Player code and event routing.
sfx_data.js | 482,216 | res://audio/clips/ plus res://data/sfx_manifest.json | Data, GDScript loader | Base64 strings become audio files. Content must not change. Licence question stays open.
head.html | not listed | project.godot and export_presets.cfg | None | Page shell is replaced, not ported.
voidsworn-3d.html | not listed | Windows export .exe plus .pck | None | Built browser page is replaced, not ported.

The ported source total, excluding sim3d.js, is 1,459,719 bytes. The total across all listed files including sim3d.js is 1,555,511 bytes. These sums come from the pack's byte sizes.

Part 2. Golden-file test design

2.1 What the test is for

sim3d.js stays in Node untouched. It is the balance oracle. The Godot rules copy is tested against the oracle, not against hand-written expected outcomes. The test does not try to prove that Godot and Node produce identical floating-point pixels or identical physics. It proves that the integer rule state matches exactly and that float drift stays inside a stated tolerance. This matters because Godot's own docs warn that physics is not deterministic, regardless of physics engine (Godot physics introduction, lines 14 to 17). Rule outcomes must therefore live outside the physics solver, or the test will fail for reasons that have nothing to do with the port.

Two design rules follow from that:

1. Integer rules are authoritative. Damage, hull, armor, shields, heat, ammo, cooldowns, status durations, resources, turn order, and objective scores are integers and must match exactly.

2. Physics and float positions are presentation unless they feed a rule. If a rule check uses position, range, or facing, quantize that value to a fixed integer grid in both Node and Godot before the check. The float position remains presentation only. This keeps the rule input integer and avoids a float-dependent integer outcome.

The RNG is also part of the exact rule state. Do not use Godot's built-in random number generator for rule outcomes if the Node sim uses its own algorithm. Port the Node RNG algorithm exactly, seed it from the fixture, and hash the seed and the draw count. If the RNG algorithms differ, turn outcomes will diverge even when the rules are otherwise correct.

2.2 Fixtures and fixed seeds

Fixtures live in res://tests/fixtures/ as JSON. Each fixture records the scenario id, a fixed integer seed, the number of turns, the input policy, and any starting state overrides. The seeds below are proposed for the plan. They are design choices, not measured results.

Scenario id | Setup | Seed | Turns | Purpose
duel_01 | 1 versus 1, fixed ships and weapons | 1001 | 12 | Smallest exact rules check. Fast enough to run on every step.
squadron_03 | 3 versus 3, mixed weapons | 1002 | 12 | Checks targeting, status effects, and cooldowns with more actors.
fleet_10 | 10 versus 10 | 1003 | 10 | Checks ordering, stacking, and area effects.
stress_40 | 40 ships, matching the A2 stress ship count noted in the pack | 1004 | 5 | Checks turn resolution cost and integer stability at the A2 stress scale.
campaign_seed_2001 | Campaign run with fixed encounter order | 2001 | 5 encounters | Checks campaign run state, rewards, and save shape.
meta_seed_3001 | Campaign meta progression | 3001 | fixed progression | Checks unlocks, resources, and persistence.

Each fixture has a matching Node output and a matching Godot output. The Node output is produced by sim3d.js; the Godot output is produced by the Godot rules copy. The comparator reads both.

2.3 State to hash per turn

The exact hash is computed over a canonical JSON document per turn. Canonical means keys sorted, arrays that represent sets sorted by stable id, and no whitespace differences. The exact hash includes only integer, string, enum, and boolean fields. Float fields are compared separately.

Include in the exact per-turn hash:

- Turn index and phase.
- Active side and any pending choice or reaction window.
- Ship ids, sorted.
- Per-ship integer state: hull, armor, shield, heat, ammo, cooldown turns remaining, status effect ids and integer durations, module states, and destroyed or retreated flags.
- Objective scores, control points, and encounter flags.
- Resource counters, campaign roster ids, injury counters, boons, relics, and module inventory counts.
- RNG seed and draw count.
- Any integer position or range bucket produced by quantizing a float position before a rule check.

Exclude from the exact hash:

- Node paths, instance ids, object pointers, and dictionary insertion order.
- Frame times, wall-clock times, FPS, and particle counts.
- Camera state, audio playhead, UI animation state, and shader parameters.
- Raw float positions and velocities. These are compared in the tolerance pass.

Hash algorithm: SHA-256 over the canonical JSON, plus a rolling SHA-256 over the concatenation of all per-turn hashes. Godot provides HashingContext with SHA-256 and a chunked file-hash pattern (Godot HashingContext, lines 5 to 19). Node's crypto module provides the same. The exact hash covers integer rules only, so a single integer mismatch is a fail with no tolerance.

2.4 Float tolerance, explicitly

Float fields are compared in a separate pass. They do not enter the exact hash. The comparator walks the state tree, matches fields by path, and reports the maximum absolute and relative deviation per scenario.

Field group | Tolerance | Where it applies
Positions | 1e-3 game units absolute, 1e-5 relative above 1.0 | Ship positions, projectile spawn points, effect anchors. Presentation only unless quantized for a rule check.
Velocities | 1e-4 units per second absolute, 1e-5 relative above 1.0 | Ship and projectile velocities. Presentation only unless quantized for a rule check.
Facing and aim angles | 1e-4 radians | Ship facing, turret aim, cone checks. If an angle feeds a hit or miss rule, quantize the cone test to an integer bucket first.
Normalized directions | 1e-4 absolute | Direction vectors and camera-facing helpers.
UI and effect scalars | 1e-3 absolute | Fade values, scale curves, and other presentation values.

Integer fields have zero tolerance everywhere. If a float difference changes an integer outcome in the same turn or a later turn, the test fails on the integer field. The float tolerance does not excuse an integer divergence.

If the rules need exact float math rather than quantized integer math, the safer path is C# double for the rule routine and, if necessary, a double-precision Godot build. That is a spike decision. The default plan is to quantize any float that feeds a rule and keep the exact hash integer.

2.5 The .bat runner

The runner is a double-click launcher for Windows 10, PowerShell 5.1, and a user who does not use a terminal. It lives at tools/run_golden.bat. It must set its own working directory to the repository root, so double-clicking it from any location works. It must never close the window immediately on failure.

The .bat runs three stages for each fixture:

1. Node oracle stage. It runs node sim3d.js with the fixture path and an output path under tests/out/node/. It writes the Node per-turn state JSON. The exact sim3d.js command-line flags are not given in the pack and are tagged UNSURE. Opus should expose a small fixture-mode flag if one does not already exist.

2. Godot headless stage. It runs the Godot 4.7.2 Windows executable with --headless, --path pointing at the repository root, --script res://tests/run_golden.gd, and a -- separator followed by the fixture path and output path. --headless sets the display and audio drivers to dummy and is the documented way to run without a GPU or display (Godot command line tutorial, lines 60 to 61). The -- separator passes the remaining arguments to the script (lines 25 to 26). The harness also sets a fixed physics tick and uses --fixed-fps so the run does not depend on wall-clock frame timing (lines 111 to 113).

3. Comparison stage. It runs node tools/compare_golden.js with the Node output, the Godot output, and a report path. The comparator computes the exact per-turn hashes, compares integer fields with zero tolerance, compares float fields with the tolerances above, and writes tests/out/report.txt.

After the comparison, the .bat pauses. The user sees a single result line and a short instruction. If Node or the Godot executable is missing, the .bat prints a plain message naming the missing program and pauses, instead of flashing a console and closing.

Pass looks like this to the user: a line that says PASS, the number of scenarios and turns checked, 0 mismatches, and the report path. The window says the tests passed and can be closed.

Fail looks like this to the user: a line that says FAIL, the first mismatch in plain form (scenario, turn, field, expected value, actual value, and whether it was an integer exact check or a float tolerance check), and the report path. The report lists all mismatches, capped at 50. The window stays open until the user presses a key. The .bat returns a non-zero exit code for automation, but the visible result is the console line, not the exit code.

The runner uses PowerShell 5.1 only for a preflight file-exists check if Node is missing. The comparison itself is Node, so the user does not need to learn PowerShell or a terminal.

Part 3. Step order with a playable build at every step

The order below keeps a runnable, double-clickable build at every step. It starts with data and one hull, gets the rules and a scripted duel working before the full renderer, then layers rendering, effects, UI, audio, campaign, and shipping. The golden tests run at the end of every step that touches rule state. Sizes are ranges around the pack's byte sizes, never exact predictions. The ported source total in scope is 1,459,719 bytes; sim3d.js at 95,792 bytes stays in Node and is not counted in these step ranges.

Step | Work | Playable state at the end of the step | Source bytes in scope | Step size range
1 | Create the Godot 4.7 project, import one GLB hull, export data.js tables to JSON, load the tables, build a hangar scene with an orbit camera and table-driven stat labels. | The player can open the project, orbit one hull, and read its real ship and weapon stats from the JSON tables. No combat yet, but the build runs. | 57,094 | 50,000 to 80,000 bytes
2 | Port core.js to C#, build the typed data loader, add a debug panel that resolves one attack or one stat calculation using real table values. | The player can press a button in the debug panel and see one rule calculation resolve with real numbers. The same calculation in the Node oracle matches exactly. | 35,854 | 30,000 to 50,000 bytes
3 | Port battle.js to C#, add the turn engine and the GDScript golden harness, run the duel_01 and squadron_03 fixtures. | The player can step turns and fire in a debug duel with placeholder shapes. Hull, shield, heat, ammo, and status numbers change per turn. The first golden duel passes. | 131,980 | 120,000 to 160,000 bytes
4 | Port ships3d.js, scene3d.js, and gfx3d.js to GDScript, build the battle scene, camera, lighting, and hardpoints. | The player can watch the duel with real hulls, a battle camera, and movement. Effects and full HUD are still missing, but the battle is visually readable. | 292,026 | 270,000 to 330,000 bytes
5 | Port fx3d.js, wfx3d.js, and vfx3d.js. | The player can see weapon fire, impacts, explosions, and screen effects during the duel. The debug UI is still in place. | 194,854 | 175,000 to 225,000 bytes
6 | Port ui3d.js to GDScript, replace debug labels with the real HUD, tooltips, buttons, and end screen. | The player can play a full battle through the real HUD: read stats, choose actions, see results, and reach an end screen. | 114,406 | 105,000 to 135,000 bytes
7 | Port sfx.js, decode sfx_data.js base64 to WAV or OGG, build the manifest, wire event sounds and volume controls. | The player can hear the correct sounds for weapons, impacts, UI, and battle events, and can mute or change volume. | 534,928 | 500,000 to 580,000 bytes
8 | Port campaign_run.js, campaign_meta.js, and campaign3d.js, add the campaign map, encounter flow, rewards, and save/load. | The player can start a campaign, choose an encounter, play it, receive rewards, and reload a saved run and meta progression. | 98,577 | 90,000 to 120,000 bytes
9 | Export the Windows build, integrate GodotSteam, wire the Steam overlay and achievements, and run the exported build from Steam. | The player can launch the exported game from Steam, open the Steam overlay, and unlock an achievement. No browser wrapper is involved. | 0 new game source | 0 to 20,000 bytes of config and integration

The ranges are consistent with the pack's ground truth without predicting an exact total. Step 9 has no new game source because it is packaging and platform integration. The first full rules milestone is step 3. The first visually playable battle is step 4. The first feature-complete battle is step 7. Campaign is step 8. Shipping is step 9.

Part 4. What carries over unchanged

"Unchanged" means content is preserved. Format conversion is allowed. A content change is not allowed without an explicit review. Each row below says what unchanged actually means and what must be re-validated after the move.

Item | What "unchanged" means in practice | Format conversion allowed | What must be re-validated
data.js tables as JSON | Every table row, id, name, numeric value, and relationship stays identical: ships, weapons, admirals, boons, relics, modules, and encounters. | Yes. JavaScript object literal to JSON is a format change, not a content change. | Every row that the Node sim and the Godot rules both read. Admiral perk effects (fx) and Command definitions. Any value the golden tests hash. Number precision for integers and floats. Null versus missing keys. Array order where order matters. Duplicate ids. Required fields.
sfx files | The decoded audio content is bit-identical to the base64 payload. No re-encoding, trimming, normalization, resampling, or gain changes. The same clip ids map to the same audio. | Yes. Base64 strings become WAV or OGG files plus a manifest. Godot imports WAV, Ogg Vorbis, and MP3 (Godot importing audio samples, lines 3 to 5). | Decode count matches the base64 count. Duration, sample rate, and channel count match the decoded source. Checksums match the decoded bytes. Every sfx id in sfx.js has a manifest entry and a file. Playback routing and bus assignment. The licence question stays open, as described below.
Hull assets via glTF | Authored geometry, UVs, material assignments, hardpoint and pivot placement, and naming stay identical. The Blender-authored kit can be exported as GLB. | Yes. Blender GLB export is the kit path recorded in the engine comparison. Godot imports glTF 2.0 and can apply import settings (Godot import configuration, lines 3 to 10). | Materials and shaders re-scope from Babylon materials to Godot materials: metallic and roughness, emissive, transparency, double-sided flags, and texture channels. LODs generated on import. Godot auto-generates mesh LOD for imported glTF scenes by default (Godot mesh LOD, lines 30 to 33). VRAM-compressed baked maps. Pivot, scale, and orientation. Hardpoint empties and animation clips. The current export state of any specific hull is UNSURE because the pack does not state it.
sim3d.js | The file stays unchanged in Node. It is the balance oracle. | None. It is not ported. | Node version and CLI flags. Fixture output shape. Any change to sim3d.js is a rules change, not a port change, and must be reviewed as such.
head.html and voidsworn-3d.html | They do not carry over. They are replaced by the Godot project and the Windows export. | Replacement, not conversion. | Export preset, window size, input map, icon, and startup scene.

4.1 The sfx licence question is open

The pack records a real tension. The field guide line 350 says sound files may not be handed to anyone else, while the public repo carries clips as base64 in sfx_data.js. FINDINGS R10 records Ryan's decision that the repo stays public and sound stays as is, Sonniss clips included. That records the sound decision, not a resolution of the licence text. This port plan therefore carries sfx as "carries over in form, licence question stays open for Opus and Ryan". It does not present the sound as cleared, and it does not recommend re-encoding or redistributing the clips until the licence text is resolved.

4.2 What the glTF move needs

The material re-scope is the main risk. Babylon and Godot do not use identical material models, so a hull that looks correct in Babylon may need different roughness, metallic, emissive, or alpha settings in Godot. LOD generation is automatic on glTF import, but the docs warn that automatic LOD can occasionally introduce rendering issues, especially in skinned meshes (Godot mesh LOD, lines 40 to 44). Baked maps that were VRAM-compressed in the Babylon pipeline need a Godot import review. A hull-by-hull visual check against the Babylon reference stills is required. Any claim that a specific hull is already export-ready is UNSURE.

Part 5. If Babylon stays: the 8.20 to 9.30 move

R22 moves the Babylon test half to 9.30.0, released Oct 8, 2026. The question is not "stay on 8.20" but "move from 8.20 to 9.30". Babylon's own release material says 9.0 added clustered lighting, textured area lights, the Node Particle Editor, volumetric lighting, the Frame Graph, and advanced Gaussian splat support (Babylon What's New, lines 2 to 9). The 9.30.0 changelog is mostly bug fixes plus one new WebGPU canvas tone mapping and color space option; it lists no breaking changes (Babylon changelog, lines 3 to 27).

5.1 Documented breakages in the 8.20 to 9.30 range

Babylon's Breaking Changes page is the primary source for this list. It lists no 9.0.0 entry. The only 9.x entry is 9.15.0. There is also one breaking change in the 8.5x range before 9.0. I am not inventing a 9.0.0 breakage that Babylon does not document.

Change | Version | What Babylon's own doc says | Likely impact on this game | Source
TC39 Stage 3 decorators | 9.15.0 | Babylon moved from TypeScript legacy experimentalDecorators to standard TC39 Stage 3 decorators. The doc says this only affects code that applies Babylon decorators such as @serialize or @expandToProperty to classes you author. Code that merely uses Babylon classes is unaffected. | If the game is plain JavaScript and does not subclass Babylon types with decorators, this is no break. If it does, the project must compile with TC39 decorators, set experimentalDecorators to false, add the accessor keyword where required, and target ES2015 or later. The game is plain JS, so the likely impact is none, but the codebase has not been grepped for decorators. That check is UNSURE. | Babylon Breaking Changes, lines 2 to 37
NPE texture block .texture updates | 8.54.2 | Marked [Breaking Change] in the What's New entry for the NPE texture block. | Only affects code that uses the Node Particle Editor texture block. The game's effects are custom fx3d, wfx3d, and vfx3d code, not NPE graphs, so the likely impact is none. This is UNSURE until the effect code is checked for NPE usage. | Babylon What's New, lines 211 to 214
Target camera orientation in right-handed scenes | 8.10.1 | Already in the 8.20 baseline. Not a new 8.20 to 9.30 break. | No new action for the move. If the game uses right-handed scenes and target cameras, the behavior was already changed before 8.20. | Babylon Breaking Changes, lines 38 to 48

No other 8.20 to 9.30 breakage is documented on Babylon's Breaking Changes page. In particular, the page has no 9.0.0 section between 9.15.0 and 8.10.1. That is evidence that Babylon did not document a 9.0.0 break, not proof that none exists. Any 9.0 behavior change that is not on that page is tagged UNSURE.

5.2 What the move does not break, as far as Babylon documents

- Clustered lighting, volumetric lighting, and the Frame Graph are new features in 9.0, not documented as breaking changes. They are opt-in. Existing lights and materials should keep working unless the project enables them and changes its render path.
- The 9.30.0 release is a patch-level release. The changelog lists fixes and one new canvas color-management option. No breaking change is listed.
- OpenPBR is an alpha feature. It is opt-in and not a required migration.
- The move is still a jump across many weekly releases. Even when no single API break is documented, the regression surface is large. Rendering, materials, loaders, particles, and audio need a visual and behavioral regression pass against the 8.20 baseline. That is the real cost of staying on Babylon and moving to 9.30, not a long list of documented breaks.

5.3 Shipping caveat for the Babylon-stay path

Staying on Babylon 9.30 does not solve the Steam overlay question. X12 records Valve's own doc as saying web browsers do not support the overlay model. The workaround is an embedded Chromium inside a native app with offscreen rendering, which Valve describes as "not easy". The steamworks.js Electron overlay flag is third-party, not Valve-supported. Valve's overlay doc lists native graphics APIs (DirectX, OpenGL, Metal, Vulkan) as the supported path, not a browser page (Valve Steam Overlay, lines 8 to 10). A Babylon ship build therefore needs a native shell such as CEF or similar for a dependable overlay. Godot exports natively and has GodotSteam for Steamworks integration (GodotSteam, lines 2 to 7). No browser-based overlay path should be presented as Valve-supported.

The trimmed A2 scope keeps Babylon as a browser page. A2 therefore measures rendering and effects, not the native-shell shipping path. A Babylon win on A2 would not by itself answer X12.

5.4 What staying on 9.30 means in short

- The documented code break is the 9.15.0 decorator change, and it only matters if the game authors decorated Babylon classes. The likely impact is none, but it is UNSURE until checked.
- The 8.54.2 NPE texture block change only matters if the game uses NPE. The likely impact is none, but it is UNSURE until checked.
- There is no documented 9.0.0 breaking change. Do not invent one. Treat undocumented behavior changes as UNSURE and regression-test them.
- The move gives Babylon clustered lighting, volumetric lighting, Frame Graph, and node particles, which closes the 8.20 feature gap noted by both legs.
- The shipping path still needs a native shell for the overlay. That is the main reason X12 favors native export.
- If Babylon stays, the Node sim3d.js oracle and the golden-file harness still apply unchanged. The port plan's data carryover and test design are not wasted. Only the Godot-specific parts are set aside.

Primary sources cited

Godot:
- Godot 4.7 release notes
- Godot 4.7.2 maintenance release
- Godot command line tutorial
- Godot C# basics
- Godot scripting languages
- Godot import configuration for 3D scenes
- Godot mesh LOD
- Godot JSON class
- Godot HashingContext class
- Godot importing audio samples
- Godot physics introduction
- Godot exporting for Windows
- Godot license
- GodotSteam

Babylon:
- Babylon What's New
- Babylon Breaking Changes
- Babylon 9.30.0 changelog
- Babylon license

Steam:
- Valve Steam Overlay documentation

Pack references:
- Job C evidence pack, file sizes section, for all byte sums.
- Job C evidence pack, R22 and X12 sections, for the 9.30 move and the Steam overlay resolution.
- Job C evidence pack, A2 status section, for the missing RESULTS.md and the trimmed A2 scope.
- Job C evidence pack, carryover flags, for the sfx licence tension, field guide line 350, and FINDINGS R10.
- Job C evidence pack, engine choice synthesis summary, for the per-area language options and the GodotJS state.

Not checked

- A2 benchmark numbers. contrib/opus/enginetest/RESULTS.md does not exist on main as of the pack's check, and the blind reveal has not been done. No A2 result is predicted or used here.
- The exact sim3d.js command-line flags for fixture mode. The pack does not give them. The harness design assumes a fixture input and output flag can be added or already exists.
- GodotJS 4.7 support state beyond the pack. The pack says 4.7 support is WIP, prebuilt binaries target 4.4, the project is a community fork, and the older QuickJS module is not available for 4.x. No primary link in the pack changes that, so it is not planned around.
- Whether any Babylon decorators or NPE texture blocks are used in the current game code. The likely impact is none, but the codebase was not grepped.
- Whether any 9.0 to 9.30 Babylon behavior change exists that Babylon did not document on its Breaking Changes page. Tagged UNSURE. Do not treat the absence of a 9.0.0 entry as proof of no change.
- The exact .NET SDK version required by Godot 4.7 C#. The 4.x C# docs state .NET 8.0, but the 4.7 page was not checked line by line.
- GodotSteam compatibility with the exact Godot 4.7.2 build. The GodotSteam site states Windows support and Steamworks integration, but no version matrix was checked.
- The current glTF export state of any specific hull. The pack records Blender-authored kit work and GLB export as the path, but not per-hull readiness.
- Whether Godot's default single-precision Vector3 is precise enough for every rule check that uses position. The plan avoids the issue by quantizing rule inputs and keeping floats for presentation, but the actual rule code has not been audited.
- Whether the sfx licence tension is resolved. It is not. The field guide line 350 and the public repo base64 clips remain in tension, and FINDINGS R10 records a decision, not a resolution.
- Whether a Babylon 9.30 build of the game actually runs without code changes. No build was run.
- Whether a Godot 4.7.2 export with GodotSteam passes Steamworks review. No export or Steamworks test was run.

