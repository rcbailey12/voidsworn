# Engine choice: Godot 4.7 vs Babylon.js 8.20 (Qwen leg, Oct 25, 2026)

Filed verbatim from a fresh Qwen chat ("Godot Versus Babylon Engine Comparison").
Run report: Qwen3.8-Max, Thinking ON, Web search ON, session already signed in
(Ryan Bailey, Free plan), Qwen3.8-Max available so no fallback needed, no other chat
opened or reused. No em dashes in the original; none added.

Voidsworn: Godot 4.7 vs Babylon.js 8.20 for a PC-only 3D turn-based fleet tactics roguelite

Scope note: this covers everything your RTX 5080 benchmark cannot show. Version facts as of now: Godot 4.7 shipped stable on 18 June 2026, with 4.7.1 and 4.7.2 maintenance releases since, and 4.8 is at beta 1 as of 15 October 2026. Babylon.js 8.0 shipped 27 March 2025 and 8.20.0 published around late July 2025; the current line is 9.x (9.0 on 26 March 2026, 9.30.0 in October 2026), so your 8.20 is about a year old and two major steps behind the head of the project.

## 1. Porting cost (only relevant if Godot wins)

What can stay as-is. By your own facts, data.js, core.js, battle.js, campaign_run.js, campaign_meta.js and sim3d.js are plain JavaScript with no engine calls. Nothing forces you to touch them. The realistic best-practice path is: keep sim3d.js and the Node harness exactly as they are as the balance/reference simulator, regardless of which engine renders the game. That is engine-independent by construction.

Is there a maintained JS runtime for Godot 4.7? There is one credible candidate and it is not production-ready: GodotJS (github.com/godotjs/GodotJS) adds TypeScript/JavaScript to Godot 4.x using V8, and a new maintainer took over recently. However, its own repo shows "Initial Godot 4.7 support (WIP / CI disabled)", and the companion prebuilt binaries (ialex32x/GodotJS-Build) target Godot 4.4. It is a community fork of the engine, not an official Godot product, and shipping a Steam game on a custom engine fork with WIP support for your exact version is a real risk. UNSURE how stable it is today for a shipped game. The older QuickJS-based godotjs/javascript module explicitly says it is "currently not available for 4.x". So the honest answer: no officially maintained JS runtime for Godot 4.7. You would rewrite the in-game rules copy in GDScript or C#, or bet on GodotJS.

GDScript vs C# for the rules. C# support is official and requires the .NET build of the editor plus the .NET SDK. For porting JS rules code, C# is the closer language (types, classes, similar syntax), so an AI builder can do a mostly mechanical translation; GDScript is fine too but is a bigger syntactic jump. Either way the port is of the runtime copy only: battle rules, core helpers, and the campaign state machines.

Rough work estimate (my arithmetic from your byte counts, at roughly 30-40 bytes per line of JS; treat line counts as estimates, not facts):
- Rules and sim group: 6 files, 398,855 bytes, about 10,000-13,000 lines. Only the subset the game actually calls at runtime needs porting; sim3d.js (95,792 bytes) can stay in Node untouched.
- Rendering, effects and UI group: 8 Babylon-specific files, 621,728 bytes, about 16,000-20,000 lines (ships3d, scene3d, fx3d, wfx3d, vfx3d, gfx3d, ui3d, campaign3d). This is a rewrite, not a port: Babylon mesh/material/post-process/GUI calls have no one-to-one Godot equivalents, and Godot does much of this in scenes, resources and shaders rather than code, so the Godot version will look structurally different.
- Audio: sfx.js (52,712 bytes) maps to Godot's audio nodes; sfx_data.js (482,216 bytes) is data and should become plain asset files, reusable either way.
- Total realistic unit of work: about 14-16 files rewritten, plus new Godot project scaffolding (scenes, materials, input map, export preset). The rendering/UI rewrite dominates; the rules port is the smaller half.

Key risk: rule drift. If the Node sim keeps the JS rules and the game runs a GDScript/C# copy, the two can silently diverge, which corrupts balance work. Mitigation (advice, not an engine fact): golden-file testing. Run fixed seeds/scenarios in both copies and diff the battle logs; any mismatch fails the build. The fact that your rules are already isolated in engine-free files makes this unusually easy for your project. Secondary risks: GodotJS-style forks lagging engine releases, and Godot minor versions moving every 3-6 months so your ported project needs periodic upgrades.

Verdict: Porting is feasible but not cheap: roughly 25,000-33,000 estimated lines across 14-16 files, with the Babylon rendering/UI layer being a true rewrite. There is no dependable JS runtime inside Godot 4.7, so keep the Node sim as the source of truth for balance and guard against drift with golden-file tests.

## 2. Shipping a PC game on Steam

Godot route
- Windows build: one-click export with the official Windows export preset; Godot is self-contained and needs no installer runtime.
- Install size: a default Windows export of a near-empty project measures around 93 MB (community measurement, not an official figure), and the engine publishes a binary size history tracker; real size is dominated by your assets.
- Steam integration: GodotSteam is a mature GDExtension providing "access to the entire Steamworks SDK functionality, from achievements to Workshop"; the current GDExtension (4.23.2) works on any Godot 4.4+, and server builds track Godot 4.7.2 with Steamworks SDK 1.65. Achievements/stats/cloud are standard Steamworks features the plugin wraps. The Steam overlay works normally for native games; Valve even publishes Godot-specific Steam hardware docs.
- Controllers: built into the engine through the input action system, which handles joypads without separate code paths; Steam Input configuration is documented by the GodotSteam community.
- Crash reporting: Sentry publishes an official Godot SDK with native crash and script error capture.
- Auto-update: Steam itself handles player updates through depot uploads (SteamPipe); no in-game updater needed. Godot has no built-in game self-updater, which does not matter if you ship only on Steam.

Babylon.js route
- Windows build: you must wrap the page. Electron bundles Chromium and Node into the app; Tauri uses the system WebView2 and produces much smaller bundles (community measurements: roughly 3-10 MB vs 120-200 MB; treat exact numbers as UNSURE since they are not from official docs). NW.js is the older option. A plain browser cannot be a Steam SKU: Steam needs an executable, and Valve documents that the overlay does not support browser-technology games.
- Install size: Electron apps carry the full Chromium runtime; the same community comparisons put a minimal Electron app around 85 MB installer / 200 MB installed before your assets. UNSURE for exact numbers on your project.
- Steam integration: the practical library is steamworks.js, a Rust/Node binding of the Steamworks SDK for HTML/JS apps; a newer steamworks-ffi-node covers achievements, stats, leaderboards, cloud saves and Workshop. Greenworks, the old standard, is unsupported.
- Overlay: this is the hard blocker. Valve's own documentation states the in-game overlay does not support games built with browser technology on Windows, macOS or Linux, and the suggested workaround is embedding Chromium inside a native D3D application, which is heavy custom engineering. Electron-specific overlay breakage recurs across versions, and Construct's team documented the same problem over WebView2. Whether Valve strictly enforces overlay support at onboarding: UNSURE, but shipping a Steam game whose overlay is officially unsupported is a real risk.
- Controllers: Babylon wraps the browser Gamepad API with its own Gamepad/GamepadManager classes. Steam Input support through steamworks.js: UNSURE, not confirmed in its docs.
- Crash reporting: Electron has a built-in crashReporter (Crashpad) that uploads minidumps, and Sentry maintains an official Electron SDK capturing native crashes in main and renderer processes.
- Auto-update: Electron's autoUpdater (Windows/macOS) or Tauri's updater plugin, or just let Steam depots do it.

Verdict: Godot has a dramatically cleaner Steam path: official-grade native export plus GodotSteam for achievements, cloud, input and a working overlay. The Babylon path works up to the point of Steam overlay support, which Valve documents as unsupported for browser-technology games, leaving you either accepting a degraded Steam presence or building a custom native Chromium shell.

## 3. Long-term risk

Licences. Godot is MIT, free, no royalties, only requirement is keeping the licence text. Babylon.js is Apache-2.0, also permissive and free. Babylon's Havok physics WASM plugin is free under MIT. Neither licence is a business risk. Note Godot is foundation-governed open source; Babylon is Microsoft-sponsored.

Release cadence and support for your exact versions.
- Godot aims for a minor release every 3-6 months; its policy actively supports a stable branch until the successor branch gets its first patch release. Godot 4.7 is current stable (4.7.2, August 2026), but 4.8 beta 1 already shipped 15 October 2026, so expect 4.7 to enter limited support within a few months of 4.8 stable. That is normal and fine: Godot minors are upgrade-friendly by policy, with only documented classes of change allowed in minors.
- Babylon publishes a minor every Thursday from master, with a major roughly yearly (8.0 March 2025, 9.0 March 2026). Your 8.20 is a mid-2025 snapshot of a weekly-cadence project; it will keep working (npm packages persist) but gets no new fixes once you pin it. Staying pinned is safe short-term and stale long-term.

Breaking-change history. Babylon maintains a public breaking-changes page (for example the 9.15.0 decorator migration), and the 9.0 announcement itself rates the v8-to-v9 risk as "LOW-MEDIUM" for most users. But there are community reports of behavior breaks inside 9.x minors, so "weekly minors" plus "occasional in-minor breaks" is the real cadence. Godot's policy page constrains what may change in minors and patches; the big pain event was the 3.x to 4.0 jump, and within 4.x the project has been comparatively steady.

Community size and health. Godot: about 119k GitHub stars and roughly 4k contributors, plus a large forum and a funded foundation. Babylon: 26.2k GitHub stars, an active official forum, and corporate backing from Microsoft. Both are healthy; Godot's game-dev community is several times larger, Babylon's is stronger in web/product-viz circles.

WebGL2 vs WebGPU in Babylon. Babylon officially supports WebGL 1.0, WebGL 2.0 and WebGPU side by side; WebGPU has been maintained since 5.0 with a dedicated status page. Since 8.0 all core engine shaders ship in both GLSL and WGSL. The strategic direction leans WebGPU: the team says it is porting main shaders to make WebGPU "a first class citizen", and in June 2026 they launched Babylon-Lite, a WebGPU-exclusive sibling engine. I found no announcement deprecating WebGL2 in the main engine, so WebGL2 is not going away soon, but the center of gravity is shifting; for a pinned 8.20 project this is moot until you upgrade. (Godot, for contrast, still has no WebGPU support in official web exports, with community/foundation work ongoing; irrelevant for your PC-only plan.)

Verdict: Both licences and both projects are safe. Godot 4.7 is the current stable with a documented, conservative support policy and a huge community. Babylon 8.20 is a frozen year-old snapshot of a fast-moving project; the engine's future (9.x clustered lighting, Babylon-Lite) is WebGPU-centric, so staying on 8.20 forever means missing the good stuff, and moving to 9.x means a documented migration.

## 4. Tools for a non-coder plus an AI builder

Claude driving Godot headless:
- Godot has first-class command-line operation, including a --headless mode explicitly designed for CI without GPU access.
- gdUnit4 (and GUT) run unit/integration tests for GDScript and C# from the command line, headless.
- Godot can deterministically record frames to video from the command line (Movie Maker, --write-movie), which gives an AI builder a reproducible way to capture what the game looks like.
- Scenes and project files are plain text resources an AI can read and patch without a GUI.

Claude driving Babylon headless:
- Babylon's NullEngine officially runs the engine in Node with no canvas, for tests and server-side logic; the team themselves use it for end-to-end testing of scene graphs.
- Visual checks need a real browser: headless Chrome via Puppeteer/Playwright with screenshots; Babylon's own test tooling does visual regression this way. On CI without a GPU this means software rendering, which is slow. UNSURE how heavy that is for your scene.
- Your sim3d.js workflow (plain Node, no engine) already works and keeps working either way.

For you, the non-coder, to open and look at:
- Godot: the editor is a free, self-contained Windows download, no install; you can open the project, click any scene and orbit the 3D view, tweak lights and particles with sliders, and press play. This is a real editor built for exactly this.
- Babylon: today, the easiest "look at it" is a browser tab, which you already have. The Babylon.js Editor is an open-source desktop app for scenes and scripts, and there is a web GUI Editor for UI layouts, plus the Playground for snippets. But none of these open your existing hand-written codebase as a project; your game stays "code you run in a browser".

Verdict: For AI-driven automated work, it is close: Godot wins on running the whole game headless from a CLI plus deterministic frame capture; Babylon wins only for logic-level tests via NullEngine, since pixel checks need a browser stack. For you personally, Godot wins clearly: a real visual editor you can open and explore, versus a code-first web project.

## 5. Effects and presentation ceiling

Godot 4.7 (Forward+ renderer):
- Particles: GPU (GPUParticles3D with process materials, collisions, attractors) and CPU particle systems built in.
- Volumetrics: native volumetric fog plus local fog volumes, no plugin needed.
- Global illumination: SDFGI, real-time, works with dynamic lights and procedural levels.
- Post-processing: the Environment resource covers glow, SSAO, SSIL, SSR, tonemapping and more out of the box.
- Lights: clustered forward rendering; the default cap is 512 clustered elements (lights plus reflection probes) per camera view and it can be raised in project settings; renderer docs list per-mesh omni/spot counts and 8 directional lights as the practical defaults. 4.7 adds AreaLight3D (real rectangular area lights) and HDR output on desktop.
- Physics: Jolt is built into the engine since 4.4 and selectable in project settings.
- Where you hand-write shaders: anything beyond the Environment toolbox (custom screen effects, stylized hex-grid shaders) uses Godot's shading language; no paid plugins needed for the above.

Babylon.js 8.20:
- Particles: mature CPU particle systems plus GPUParticleSystem using WebGL2 transform feedback (or compute on WebGPU).
- Post-processing: DefaultRenderingPipeline bundles MSAA/FXAA, bloom, chromatic aberration, depth of field, color grading and more; custom passes are easy.
- Volumetrics: a VolumetricLightScatteringPostProcess (god rays) is built in. True volumetric fog is not in 8.20 as far as I can tell; volumetric lighting is listed as new in the 9.0 announcement coverage, so on 8.20 you would hand-write it. UNSURE (absence claim).
- Lights on 8.20: each material has a maxSimultaneousLights cap (default 4, raisable per material); the clustered lighting system that handles hundreds or thousands of dynamic lights arrived in 9.0, which your pinned version does not have. Textured area lights also arrived in 9.0.
- Physics: Havok via the official plugin, free under MIT, WASM-based.
- Everything else custom goes through the Node Material Editor or hand-written GLSL/WGSL; since 8.0 core shaders are dual GLSL/WGSL.

Fit for Voidsworn specifically: a hex fleet-tactics game wants readable ships, lots of simultaneous weapon-fire lights, glow, fog-of-space atmosphere, chunky particles. Godot 4.7 gives you volumetric fog, SDFGI, area lights, HDR and a 512-element clustered light budget today. Babylon 8.20 gives you excellent post-processing and particles but a 4-lights-per-material default and no native volumetric fog; closing that gap means upgrading to 9.x (clustered lighting, area lights, node particle editor), which is a migration you would have to perform and re-test.

Verdict: For your pinned versions, Godot 4.7 has the higher native ceiling (volumetric fog, GI, area lights, HDR, bigger light budget). Babylon's ceiling is arguably equal or better if you move to 9.x, but on 8.20 you would be hand-writing volumetrics and juggling per-material light caps.

## 6. My pick

Pick: Godot 4.7 (practically: start on 4.7.2 and plan to follow minors), assuming your separate benchmark does not show Babylon winning on frame time for your actual scenes.

Two strongest reasons:
1. Steam is the product, and Godot ships to Steam cleanly. Native Windows export plus GodotSteam (achievements, cloud, Workshop, Steam Input, overlay that actually works) is a solved, documented path. The Babylon path runs into Valve's own statement that the Steam overlay does not support browser-technology games, with the only sanctioned workaround being a custom native Chromium shell. That single fact outweighs most of the porting cost for a PC-only, Steam-style release.
2. Presentation ceiling and tooling match the game and the team. Volumetric fog, SDFGI, area lights, HDR output and a 512-element clustered light budget come free in 4.7, while Babylon 8.20 caps lights per material and lacks native volumetric fog. And for a non-coder plus an AI builder, Godot offers a real visual editor you can open plus headless CLI runs, gdUnit4 tests and deterministic movie capture that Claude can drive end to end.

What would change my pick:
- Your benchmark shows Babylon rendering your actual battle scenes materially faster or with better visual quality on the RTX 5080 than a Godot prototype of the same scene. Frame time wins arguments.
- The port estimate proves worse than modeled: if a spike test (port one ship scene plus one battle effect) suggests the 620 KB rendering/UI rewrite is beyond your patience and budget, staying on Babylon 8.20 pinned, accepting overlay limitations, is a legitimate fallback; pinning a weekly-cadence library is safe for a while.
- GodotJS matures into reliable Godot 4.7/4.8 support with prebuilt binaries. Then you could keep everything in JavaScript, port zero rules code, and the main cost of moving collapses. Today it is WIP with CI disabled for 4.7, so I would not bet the ship date on it.
- Valve changes overlay support for embedded-browser games, or you decide achievements/overlay do not matter for Voidsworn's launch. Then the Babylon/Electron route loses its biggest penalty.

One no-regret action either way: keep sim3d.js and the rules files running headless in Node as the balance source of truth, and add golden-file comparisons against whatever the game engine runs, so rule drift gets caught the day it appears.

Source list (primary unless noted)
- Godot 4.7 release page: https://godotengine.org/releases/4.7/ ; 4.7.2 maintenance: https://godotengine.org/article/maintenance-release-godot-4-7-2/ ; download archive: https://godotengine.org/download/archive/ ; 4.8 beta 1: https://godotengine.org/article/dev-snapshot-godot-4-8-beta-1/
- Godot licence: https://godotengine.org/license/ ; release policy: https://docs.godotengine.org/en/stable/about/release_policy.html
- Godot Windows export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html ; CLI/headless: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html ; Movie Maker: https://docs.godotengine.org/en/latest/tutorials/animation/creating_movies.html
- Godot rendering: lights/shadows limits https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html ; environment/post-processing https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html ; volumetric fog https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html ; SDFGI https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_sdfgi.html ; particles https://docs.godotengine.org/en/stable/tutorials/3d/particles/index.html ; Jolt https://docs.godotengine.org/en/latest/tutorials/physics/using_jolt_physics.html and https://godotengine.org/releases/4.4/ ; controllers https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html ; C# https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html ; no WebGPU for web https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_web.html
- GodotSteam: https://godotsteam.com (org: https://github.com/GodotSteam), GDExtension release "works on any Godot 4.4+": https://codeberg.org/godotsteam/godotsteam/releases ; Sentry Godot SDK: https://github.com/getsentry/sentry-godot , https://docs.sentry.io/platforms/godot/ ; gdUnit4: https://github.com/godot-gdunit-labs/gdUnit4
- GodotJS (community, V8): https://github.com/godotjs/GodotJS (4.7 support WIP/CI disabled), builds: https://github.com/ialex32x/GodotJS-Build/releases ; old QuickJS module: https://github.com/godotjs/javascript
- Godot community size: https://github.com/godotengine/godot (119k stars), https://www.star-history.com/godotengine/godot (secondary)
- Babylon.js: repo/licence https://github.com/BabylonJS/Babylon.js (26.2k stars, Apache-2.0); CHANGELOG (8.20.0) https://github.com/BabylonJS/Babylon.js/blob/master/CHANGELOG.md ; 8.0 announcement https://blogs.windows.com/windowsdeveloper/2025-03-27/announcing-babylon-js-8-0/ ; 9.0 announcement https://blogs.windows.com/windowsdeveloper/2026-03-26/announcing-babylon-js-9-0/ ; breaking changes https://doc.babylonjs.com/breaking-changes/ ; weekly cadence https://doc.babylonjs.com/setup/frameworkPackages/frameworkVers ; features/specs https://www.babylonjs.com/specifications/ ; WebGPU status https://doc.babylonjs.com/setup/support/webGPU/webGPUStatus ; Babylon-Lite (WebGPU-only) https://github.com/BabylonJS/Babylon-Lite and https://forum.babylonjs.com/t/introducing-babylon-lite/63648
- Babylon features: NullEngine/server https://doc.babylonjs.com/setup/support/serverSide/ ; GPU particles https://doc.babylonjs.com/features/featuresDeepDive/particles/particle_system/gpu_particles ; default pipeline https://doc.babylonjs.com/features/featuresDeepDive/postProcesses/defaultRenderingPipeline ; light scattering https://doc.babylonjs.com/features/featuresDeepDive/lights/volumetricLightScattering/ ; lights/maxSimultaneousLights https://doc.babylonjs.com/features/featuresDeepDive/lights/lights_introduction ; Havok https://doc.babylonjs.com/features/featuresDeepDive/physics/havokPlugin and https://www.npmjs.com/package/@babylonjs/havok ; gamepads https://doc.babylonjs.com/features/featuresDeepDive/input/gamepads ; GUI Editor https://doc.babylonjs.com/toolsAndResources/guiEditor ; Editor https://editor.babylonjs.com/ and https://github.com/BabylonJS/Editor ; what's new 9.0 https://doc.babylonjs.com/whats-new
- Steam: overlay not supported for browser-tech games https://partner.steamgames.com/doc/features/overlay and https://steamcommunity.com/discussions/forum/10/591756872987476379/ ; achievements https://partner.steamgames.com/doc/features/achievements ; cloud https://partner.steamgames.com/doc/features/cloud ; depot uploads/updates https://partner.steamgames.com/doc/sdk/uploading ; Godot on Steam hardware https://partner.steamgames.com/doc/steamhardware/steamframe/engines/godot
- Wrappers and JS Steam libs: steamworks.js https://github.com/ceifa/steamworks.js/ ; steamworks-ffi-node https://dev.to/arty_prof/steamworks-ffi-node-a-steamworks-sdk-library-for-javascript-game-frameworks-15h1 (secondary); Electron crashReporter https://electronjs.org/docs/latest/api/crash-reporter ; Electron autoUpdater https://electronjs.org/docs/latest/api/auto-updater ; Sentry Electron https://github.com/getsentry/sentry-electron ; Tauri updater https://v2.tauri.app/plugin/updater/ ; Tauri vs Electron size comparisons (secondary): https://www.gethopp.app/blog/tauri-vs-electron , https://www.levminer.com/blog/tauri-vs-electron
- Godot export size (secondary, community-measured): https://popcar.bearblog.dev/how-to-minify-godots-build-size/ ; official binary size tracker (community): https://godot-size-history.github.io/

Where sources disagree or are weak: install-size figures for Electron/Tauri/Godot all come from community measurements, not vendor specs, so treat every MB number as approximate (UNSURE). Claims that Babylon 8.20 lacks volumetric fog, and that steamworks.js lacks Steam Input, are absence-of-evidence claims (UNSURE). The Godot 4.7 release blog mentions Steam alongside Steam Frame/Android XR hardware support; I did not confirm exactly what that Steam item covers (UNSURE), and it does not change the GodotSteam conclusion.
