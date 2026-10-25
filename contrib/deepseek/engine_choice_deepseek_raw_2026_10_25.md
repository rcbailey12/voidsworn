# Raw return: engine choice, DeepSeek, Oct 25, 2026

Source: fresh DeepSeek chat (chat.deepseek.com), DeepThink ON, Search ON, 407 web pages searched, no sign-in needed, no other chat opened or referenced. Filed verbatim below; the working copy is reviews/engine_choice_deepseek_2026_10_25.md.


# Godot 4.7 vs Babylon.js 8.20 for Voidsworn, research verdict

Version baseline: Godot 4.7 is current stable, with 4.7.2 as the latest patch. Babylon.js 8.20 is older than the current 9.x line. That matters throughout.

## 1. Porting cost

**Verdict:** Port the rules and sim to GDScript or C#, port the presentation to Godot nodes, and keep the existing Node sim only as a test oracle. Do not ship JavaScript inside Godot 4.7.

**Size estimate from your byte counts**

Assume 40 to 60 bytes per line. This is rough and tagged UNSURE as a line count.

| Group | Bytes | Rough lines at 40 to 60 bytes |
|---|---|---|
| Rules and sim: battle.js, core.js, data.js, campaign_run.js, campaign_meta.js, sim3d.js | 398,855 | about 6,600 to 10,000 |
| Presentation and audio: ships3d.js, scene3d.js, fx3d.js, wfx3d.js, vfx3d.js, gfx3d.js, ui3d.js, campaign3d.js, sfx.js, sfx_data.js | 1,156,656 | about 19,300 to 28,900 |
| Total | 1,555,511 | about 25,900 to 38,900 |

The sfx_data.js file alone is 482 KB and is probably data rather than logic. So the real code port is smaller than the total suggests. Even so, the rules and sim are a meaningful 6,600 to 10,000 line porting job.

**Path options**

- **Rewrite in GDScript.** This is the fastest path for a non-coder working with an AI assistant. GDScript is built specifically for Godot, is gradually typed, and has the most Godot examples and documentation. Source: [GDScript reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html).
- **Rewrite in C#.** Godot supports C# on Windows, Linux, and macOS, but the standard Godot executable does not include C# support. You must download the .NET version of the editor. C# is a better fit if the sim is CPU-heavy or you want static typing. Source: [Godot C#/.NET](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html).
- **Keep JavaScript running inside Godot.** GodotJS exists and targets Godot 4.x with V8, QuickJS, JavaScriptCore, and browser JS. However, its own repository says the core is "essentially usable but still under testing," and its initial Godot 4.7 support is marked WIP with CI disabled. That is not a shipping-grade runtime for a commercial PC game. Source: [GodotJS repository](https://github.com/godotjs/GodotJS).
- **Keep the headless sim in Node and port only the game.** This is useful as a test oracle, not as the shipped architecture. You can run the same seeded scenarios through the old JavaScript sim and the new Godot rules, then diff state every turn. Shipping a second Node process inside a Steam game adds process management and failure modes for little gain.

**Recommended porting sequence**

1. Freeze the JavaScript rules and sim as the reference implementation.
2. Port core.js, battle.js, data.js, campaign_run.js, and campaign_meta.js to GDScript first. These are the rules that must not drift.
3. Port sim3d.js to a headless Godot scene or a C#/GDScript test harness. Keep the Node version in CI as the oracle.
4. Port presentation files to Godot scenes, resources, particles, UI, and audio streams.
5. Add golden tests: fixed seeds, fixed input scripts, and state hashes after every turn. Run both implementations and fail on any state divergence.

**Main risks**

- **Rule drift.** The biggest risk is two implementations of the same rules diverging in turn order, action resolution, random number generation, floating-point rounding, or campaign meta progression. The existing Node sim is valuable here because it can catch drift before release.
- **Hidden engine assumptions.** You say the rules and sim have no engine calls, which greatly reduces risk. But data structures may still assume JavaScript objects, arrays, or number behavior. GDScript dictionaries and arrays behave differently in edge cases.
- **AI-generated code without a specification.** If the port is written by an AI assistant from the JavaScript code alone, it may copy bugs or invent behavior. The Node oracle plus deterministic tests is the mitigation.
- **Float and RNG differences.** GDScript floats are 64-bit by default, JavaScript numbers are also double-precision, but random APIs and iteration order differ. Use an explicit seeded RNG in both implementations.

## 2. Shipping a PC game

**Verdict:** Godot is the simpler and smaller PC shipping route. Babylon.js works on Steam, but normally through Electron or Tauri, which adds a browser runtime, a separate Steam bridge, and more update surface.

**Godot Windows build route**

- Godot's official Windows export produces an optimized .exe plus a .pck data file. The exporter strips the editor and debugger. You can export from the command line with --export-release. Sources: [Exporting projects](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html), [Exporting for Windows](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html).
- Godot's own system requirements quote 200 MB for the editor, project files, and cache, and 1.3 GB for export templates after installation. The exported game is much smaller because it is only the optimized runtime plus game data. The docs do not quote one "typical game" install size, so exact shipped size is UNSURE, but it is structurally much smaller than an Electron build. Source: [Godot system requirements](https://docs.godotengine.org/en/stable/about/system_requirements.html).
- Steam integration is not built into Godot by design. The standard route is GodotSteam, a long-running third-party Steamworks integration available as a GDExtension plugin or precompiled editor and templates. It covers achievements, stats, leaderboards, the overlay, cloud files, rich presence, and Steam networking. Sources: [GodotSteam User Stats](https://godotsteam.com/classes/user_stats/), [GodotSteam Remote Storage](https://godotsteam.com/classes/remote_storage/), [GodotSteam Friends and overlay](https://godotsteam.com/classes/friends/#activategameoverlay).
- Controller support is native and broad. Godot supports hundreds of controller models through the SDL controller database, and since Godot 4.5 uses SDL 3 for Windows, macOS, and Linux. Source: [Godot controllers](https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html).
- Crash reporting is not built in as a first-party service, but Sentry provides a Godot SDK that captures native crashes and GDScript errors on Windows, Linux, and macOS. Treat it as a third-party dependency and verify the exact Godot 4.7 support level. Source: [Sentry Godot SDK announcement](https://blog.sentry.io/introducing-sentrys-godot-sdk-1-0-alpha/).
- Auto-update: Godot's export docs describe building an executable and PCK, not a first-party game updater. For a Steam release, Steam itself handles patching. Whether Godot has a mature first-party add-on updater is UNSURE. Do not assume one.

**Babylon.js Windows build route**

- Babylon.js is a JavaScript rendering engine. To make a Steam-style Windows build, you wrap it in a desktop shell. Babylon's own docs point to Electron as a desktop option. Source: [Babylon.js multiple platforms](https://doc.babylonjs.com/features/featuresDeepDive/multiplePlatforms).
- Electron is the common route. The first build downloads 120 to 160 MB of Electron runtime, cached after that. Installed size is larger. A SteamDB depot for an Electron-packaged app shows 691.5 MiB on disk. Sources: [gameshipper npm package](https://www.npmjs.com/package/gameshipper), [SteamDB depot example](https://steamdb.info/depot/3976861/).
- Tauri produces a smaller executable but depends on Microsoft WebView2 being present. A community report describes this tradeoff. Exact installed size is UNSURE because it depends on the WebView2 runtime. Source: Babylon.js forum discussion of Electron, Tauri, and NW.js (community).
- Steam integration on Electron is normally done with steamworks.js, a third-party native module for Electron and NW.js. It documents achievements and enables the Steam overlay through electronEnableSteamOverlay. Source: [steamworks.js](https://github.com/ceifa/steamworks.js).
- Steam Cloud can be handled independently of the engine through Steam Auto-Cloud or the Steamworks Cloud API. Source: [Steam Cloud](https://partner.steamgames.com/doc/features/cloud).
- Controller support is through the browser Gamepad API. Babylon has a gamepad manager and generic pad support, but it is browser-level input, not a native SDL-style controller database. Source: [Babylon.js gamepads](https://doc.babylonjs.com/features/featuresDeepDive/input/gamepads).
- Crash reporting on Electron is built in through crashReporter and Crashpad. Source: [Electron crashReporter](https://www.electronjs.org/docs/latest/api/crash-reporter).
- Auto-update on Electron is built in through autoUpdater for Windows and macOS, and through electron-updater for Linux. Source: [Electron autoUpdater](https://www.electronjs.org/docs/latest/api/auto-updater). Tauri also has an official updater plugin. Source: [Tauri updater](https://v2.tauri.app/plugin/updater/).

**Steam cost:** Steam Direct charges a $100 USD fee per new app, recoupable after the game reaches $1,000 adjusted gross revenue. Source: [Steam Direct fee](https://partner.steamgames.com/doc/gettingstarted/appfee).

## 3. Long-term risk

**Verdict:** Godot 4.7 has a clear support window and a stable-branch model. Babylon.js 8.20 is already superseded by 9.x and sits on a weekly minor release cadence with no LTS branch. If you stay on 8.20, you are on an old version with no expectation of patches.

**Godot 4.7 support**

- Godot 4.7 stable was released on 18 June 2026. 4.7.1 shipped on 14 July 2026, and 4.7.2 shipped on 18 August 2026. Godot 4.8 is in development. Source: [Godot versions.json](https://godotengine.org/versions.json).
- Godot's release policy lists 4.7 as supported for bug fixes, security fixes, and platform-support patches. Source: [Godot release policy](https://docs.godotengine.org/en/stable/about/release_policy.html).
- Godot uses semantic versioning loosely. Major versions can break compatibility. Minor versions can have limited breakage in specific areas, but most projects are not affected. Patch releases are backwards compatible and safe to adopt. Source: [Godot release policy](https://docs.godotengine.org/en/stable/about/release_policy.html).
- The upgrade from 4.6 to 4.7 is documented as "relatively safe" for most projects, with a specific list of breaking changes. Source: [Upgrading from Godot 4.6 to 4.7](https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html).
- Licence: MIT, no royalties, commercial use allowed. Source: [Godot License](https://godotengine.org/license/).

**Babylon.js version support**

- Babylon.js 9.0 was released on 26 March 2026. It is the current major line. Babylon.js 8.20 predates 9.0. Source: [Announcing Babylon.js 9.0](https://blogs.windows.com/windowsdeveloper/2026/03/26/announcing-babylon-js-9-0/).
- Babylon.js publishes a new minor version every Thursday from its master branch. It offers preview and stable builds, but no LTS branch. The practical consequence is that 8.20 is an old minor and does not receive ongoing patches once newer minors exist. Source: [Babylon.js Framework Versions](https://doc.babylonjs.com/setup/support/frameworkVersions). No LTS is stated there; the weekly cadence and absence of an LTS table are the evidence.
- Licence: Apache 2.0. Havok physics is also free under MIT terms. Sources: Babylon.js documentation code license; [Using Havok and the Havok Plugin](https://doc.babylonjs.com/features/featuresDeepDive/physics/havokPlugin).
- WebGL2 versus WebGPU: Babylon.js has supported WebGPU since version 5.0, maintained side by side with WebGL for the foreseeable future. Source: [Babylon.js WebGPU support](https://doc.babylonjs.com/features/featuresDeepDive/webGPU/webGPUSupport). Babylon 9.0's Clustered Lighting works on both WebGPU and WebGL 2. Source: [Announcing Babylon.js 9.0](https://blogs.windows.com/windowsdeveloper/2026/03/26/announcing-babylon-js-9-0/). Babylon Lite, a separate newer product, is WebGPU-only, but that is not the same as Babylon.js 8.20.

**Community and cadence**

- Godot has a large open-source community and a predictable feature-release cadence: 4.5 in September 2025, 4.6 in January 2026, 4.7 in June 2026, and 4.8 expected in Q4 2026. Source: [Godot release policy](https://docs.godotengine.org/en/stable/about/release_policy.html).
- Babylon.js has a healthy web 3D ecosystem, but its weekly minor releases mean the API surface moves quickly. That is good for new features and bad for a small team that wants to pin a version for a year. Exact community-size comparisons are UNSURE and depend on how you count contributors, forum users, and shipped games.

**What this means for Voidsworn:** Godot 4.7 is a supported branch. You can pin 4.7.2, take security patches, and plan an upgrade to 4.8 on your own schedule. Babylon 8.20 is not a supported branch. Staying on it means either freezing with no patches or upgrading to 9.x and absorbing the 8-to-9 changes.

## 4. Tools for a non-coder plus an AI builder

**Verdict:** Godot is much easier for a non-technical user to open and inspect. For an AI assistant, Babylon is slightly easier for pure headless logic tests because the whole stack is JavaScript and Node. Godot is stronger for structured CLI and editor automation, but visual screenshot testing is harder because --headless disables rendering.

**Godot**

- Godot has a real editor with scenes, a node tree, an inspector, and a play button. A non-coder can open the project and see the game without writing code. This is the main practical advantage.
- Godot's command line supports --headless, which disables rendering and window management and is useful for scripts and servers. Source: [Godot command line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).
- Screenshot testing under --headless is not a normal rendered screenshot. Godot's headless mode disables rendering, and community test harnesses warn that a screenshot step under --headless is an explicit error, not a silent blank image. Source: godot-qa automated playtest runner (third-party). This means visual checks need a windowed session or a software-rendering setup.
- AI tooling around Godot is growing. There are MCP servers and CLI agents that can create scenes, edit nodes, export builds headlessly, read the runtime scene tree, simulate input, and capture screenshots. Examples: [godot-agent](https://pypi.org/project/godot-agent/) and Godot AI (Asset Store). These are third-party tools, not first-party engine features, but they are directly relevant to an AI-driven workflow.

**Babylon.js**

- Babylon.js has NullEngine, a headless engine that does not require a WebGL-capable device. It is designed for server-side use and testing. Source: [Running Babylon.js on a server](https://doc.babylonjs.com/features/featuresDeepDive/scene/runningBabylonOnAServer).
- Because the game is already JavaScript, an AI assistant can run rules and sim tests directly in Node without any engine GUI. That is a real advantage for automated logic checks.
- Visual checks require a real browser or Electron renderer. NullEngine does not render. So screenshot testing needs browser automation or a desktop shell. That is more setup than Godot's editor play button.
- Babylon.js is a library, not an editor-first engine. A non-coder cannot open a Babylon project the way they open a Godot project. The Babylon.js Editor exists as a separate product, but the core engine is code-first.

**Practical split**

- Non-coder inspection: Godot wins clearly.
- AI headless logic testing: Babylon wins slightly because Node tests are direct.
- AI visual testing: Neither is perfect. Godot needs a rendering context; Babylon needs browser automation. Godot's MCP ecosystem may close the gap, but it is third-party.

## 5. Effects and presentation ceiling

**Verdict:** Godot 4.7 has the higher native ceiling for Voidsworn today. Babylon.js 8.20 can do a lot, but true volumetric fog and clustered many-light rendering are not native in 8.20. Babylon 9.0 closes much of the gap, but that means upgrading.

**Godot 4.7 native features**

- Particles: GPUParticles3D and CPUParticles3D. GPU particles can render hundreds of thousands of particles on modern hardware, support custom particle shaders, and have attractor and collision nodes. Source: [Godot 3D particle systems](https://docs.godotengine.org/en/stable/tutorials/3d/particles/index.html).
- Volumetric fog: Built in, but only on the Forward+ renderer, not Mobile or Compatibility. It supports fog volumes and a FogMaterial, and custom fog shaders if you need more. Source: [Godot volumetric fog](https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html).
- Many dynamic lights: The Forward+ renderer uses a clustering approach. As many lights as performance allows can be added, with a default limit of 512 clustered elements in the camera view. Source: [Godot 3D lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html).
- Area lights: AreaLight3D is new in Godot 4.7 and renders real-time rectangular area lights with soft shadows. Source: [Godot 4.7 release notes](https://godotengine.org/releases/4.7/).
- Global illumination: SDFGI provides semi-real-time global illumination that scales to large worlds and works with procedural levels. Source: [Godot SDFGI](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_sdfgi.html).
- Post-processing: Built-in environment effects include glow, SSAO, depth of field, auto exposure, tonemapping, and adjustments. Source: [Godot Environment class](https://docs.godotengine.org/en/stable/classes/class_environment.html).
- Physics: Jolt is built in and is the default 3D physics engine for new projects since Godot 4.6. It is generally faster and more reliable than GodotPhysics3D. Source: [Using Jolt Physics](https://docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html).
- HDR output: Godot 4.7 adds HDR output on Windows, macOS, Linux Wayland, iOS, and visionOS, with Forward+ or Mobile renderers. Source: [HDR output arrives in Godot 4.7](https://godotengine.org/article/hdr-output-arrives-in-godot-4-7/).

**Babylon.js 8.20 native features**

- Particles: CPU ParticleSystem and GPU particle systems are built in, with emitter shapes, sprite sheets, and sub-emitters. Source: [Babylon.js particle system intro](https://doc.babylonjs.com/features/featuresDeepDive/particles/particle_system/particle_system_intro). Babylon 9.0 adds a Node Particle Editor and flow maps, but those are not in 8.20. Source: [Announcing Babylon.js 9.0](https://blogs.windows.com/windowsdeveloper/2026/03/26/announcing-babylon-js-9-0/).
- Volumetrics: VolumetricLightScatteringPostProcess is a screen-space light-scattering effect, not a full volumetric fog volume system. Source: [Babylon.js Volumetric Light Scattering Post Process](https://doc.babylonjs.com/features/featuresDeepDive/postProcesses/volumetricLightScatteringPostProcess). Babylon 9.0 adds a new volumetric lighting effect, but it is only available with frame graphs. Source: [Babylon.js 9.0 announcement](https://blogs.windows.com/windowsdeveloper/2026/03/26/announcing-babylon-js-9-0/).
- Many dynamic lights: Babylon 9.0 introduces Clustered Lighting, also called Forward+, which bins lights into screen-space tiles and depth slices. It works on WebGPU and WebGL 2. Source: [Announcing Babylon.js 9.0](https://blogs.windows.com/windowsdeveloper/2026/03/26/announcing-babylon-js-9-0/). The current clustered lighting documentation describes ClusteredLightContainer. Source: [Babylon.js Clustered Lighting](https://doc.babylonjs.com/features/featuresDeepDive/lights/clusteredLighting). Because this is a 9.0 feature, 8.20 does not have it.
- Post-processing: Babylon has built-in pipelines including DefaultRenderingPipeline, SSAO2, SSR, lens effects, and TAA. Sources: [Using the Default Rendering Pipeline](https://doc.babylonjs.com/features/featuresDeepDive/postProcesses/usingPostProcesses/defaultRenderingPipeline), [Babylon.js SSAO rendering pipeline](https://doc.babylonjs.com/features/featuresDeepDive/postProcesses/ssao).
- Physics: Havok is available as a free MIT-licensed WebAssembly plugin with a Babylon physics API. Source: [Using Havok and the Havok Plugin](https://doc.babylonjs.com/features/featuresDeepDive/physics/havokPlugin).

**Where each needs plugins or hand-written shaders**

- Godot: Custom fog shaders are supported through the fog shader reference. Custom screen-space effects can use CompositorEffects. Most standard effects are native.
- Babylon 8.20: True volumetric fog beyond screen-space light scattering needs custom shaders or a 9.0 frame-graph setup. Many-light scenes need either 9.0 or careful manual light management. Custom particle behavior often needs custom shaders or the 9.0 Node Particle Editor.
- Both: Anything stylized or unusual will eventually need hand-written shaders. Godot uses its own shading language; Babylon uses GLSL and WGSL, with WGSL being the WebGPU path.

## 6. Your pick

**Pick: Godot 4.7.**

**Two strongest reasons**

1. Shipping and support are simpler and more predictable. Godot exports a native Windows executable and PCK, strips the editor and debugger, and gives you a supported 4.7 branch with patch releases. GodotSteam covers achievements, cloud saves, and the overlay. Babylon 8.20 would need a desktop shell, a Steam bridge, and an upgrade to 9.x to stay current. For a solo non-coder with an AI builder, fewer moving parts matters.
2. The native rendering and physics ceiling is higher for this game today. Voidsworn is a 3D hex-grid fleet-tactics game, which benefits from many lights, volumetric fog, particles, and reliable physics. Godot 4.7 has clustered Forward+ lighting, volumetric fog, GPUParticles3D, Jolt physics, and AreaLight3D built in. Babylon 8.20 lacks clustered lighting and true volumetric fog. Babylon 9.0 closes the gap, but that is a version upgrade and, for volumetrics, a frame-graph workflow.

**What would change my pick**

- The separate benchmark shows Babylon 8.20 already hits your frame target on the RTX 5080 with substantial headroom, and the 6,600 to 10,000 line rules port is judged too expensive or too risky. In that case, staying on Babylon and shipping through Electron or Tauri is rational.
- You commit to Babylon 9.x, not 8.20, and accept the weekly minor release cadence, WebGPU-first rendering, and a desktop shell. Babylon 9.x plus Tauri plus steamworks.js is a viable modern JavaScript PC stack.
- GodotJS becomes production-ready for Godot 4.7 with real shipping evidence. Today it is not there.
- The game turns out to be visually simple enough that Godot's native lighting and volumetrics advantages do not matter, and the team strongly prefers to stay in JavaScript.

**Bottom line:** Godot is the better fit for a non-coder shipping a PC-only 3D tactics game, provided the rules port is treated as a real engineering project with the Node sim kept as a test oracle. Babylon is the better fit only if the benchmark proves the current build is already fast enough and you are willing to keep the JavaScript stack and its desktop wrapper maintained.
