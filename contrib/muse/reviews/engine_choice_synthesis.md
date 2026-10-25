# Engine choice synthesis: Godot 4.7 vs Babylon.js 8.20 (chair, TWO LEGS)

Legs: contrib/deepseek/reviews/engine_choice_deepseek_2026_10_25.md (DeepSeek)
and contrib/qwen/reviews/engine_choice_qwen_2026_10_25.md (Qwen, Oct 25 brief Job 1).
Feeds the A3 weigh-in. Nothing in it is a ruling. The A2 benchmark results and blind
stills arrive separately and can still overturn this.

Chair verdict: TWO-LEG AGREEMENT, Godot 4.7, with two conditions. Both legs pick
Godot 4.7 independently, on overlapping but not identical reasons. Condition 1: the
A2 benchmark on the RTX 5080 is the tiebreaker both legs defer to; if Babylon renders
the actual battle scenes materially faster or better, the pick flips. Condition 2: the
Steam overlay question (see below) must be verified against Valve's primary doc
before the A3 weigh-in treats it as the deciding factor, because the legs disagree
on it.

## Verdicts up top

- Pick: Godot 4.7 (practically, start on 4.7.2 and plan to follow minors). Both legs.
- Porting cost: feasible but not cheap. No dependable JS runtime inside Godot 4.7,
so the runtime rules get rewritten in GDScript or C# while the Node sim stays as the
balance oracle with golden-file tests against drift. Rendering and UI is a rewrite,
not a port: 14 to 16 files. Line ranges depend on the bytes-per-line assumption
(DeepSeek 40-60: rules 6,600-10,000, total 25,900-38,900; Qwen 30-40: rules
10,000-13,000, rendering 16,000-20,000, total roughly 25,000-33,000). Byte sums
verified identical in both legs.
- Shipping: Godot has the cleaner Steam path (native export plus GodotSteam).
Babylon needs a desktop wrapper and a JS Steam bridge. The overlay is the open
question: see the disagreement box below.
- Long-term risk: neither licence is a business risk (Godot MIT, Babylon
Apache-2.0, Havok MIT). Godot 4.7 is the current stable branch with a documented
support policy; Babylon 8.20 is a frozen mid-2025 snapshot of a weekly-cadence
project, and staying on it means either freezing with no patches or migrating to 9.x.
- Tools: for Ryan personally, Godot wins clearly (a real visual editor he can open
and explore, versus a code-first web project). For AI-driven automated work it is
close: Godot wins on CLI runs plus deterministic frame capture, Babylon wins only
for logic-level tests via NullEngine.
- Presentation ceiling: on the pinned versions, Godot 4.7 is higher (volumetric fog,
SDFGI, AreaLight3D, HDR, 512-element clustered light budget, Jolt). Babylon 8.20
lacks clustered lighting and true volumetric fog and caps lights per material;
9.x closes the gap but that is a migration.
- What would change the pick: a benchmark win for Babylon (both legs), a spike test
showing the port is worse than modeled (both legs), GodotJS maturing into reliable
4.7/4.8 support with prebuilt binaries (both legs), Valve changing overlay support
for browser-tech games or achievements not mattering at launch (Qwen), or a
commitment to Babylon 9.x rather than 8.20 (DeepSeek).

## 1. Porting cost

Agreement: there is no dependable JavaScript runtime inside Godot 4.7. GodotJS is
the one credible candidate and both legs cite the same repo state: 4.7 support WIP
with CI disabled, prebuilt binaries targeting 4.4, a community fork rather than an
official Godot product. The older QuickJS module is not available for 4.x. So the
in-game rules copy gets rewritten and the Node sim stays as the source of truth.

GDScript versus C#: DeepSeek says GDScript is fastest for a non-coder working with
an AI builder (most examples and docs); Qwen says C# is the closer language to JS
(types, classes, similar syntax) and therefore the more mechanical translation.
Both are viable; the synthesis does not pick between them, and Opus can decide on
the spike. Either way only the runtime-called subset needs porting: Qwen's point
that sim3d.js (95,792 bytes) stays in Node untouched is adopted, since the sim is
engine-independent by construction.

Rule drift is the top porting risk in both legs, and both independently propose
the same mitigation: golden-file testing (fixed seeds and scenarios run in both
implementations, battle logs or state hashes diffed, any mismatch fails the
build). DeepSeek adds float and RNG discipline (explicit seeded RNG in both);
Qwen adds the secondary risks of GodotJS-style forks lagging engine releases and
of Godot minors moving every 3-6 months.

Byte sums (verified by the chair against the brief's facts, identical in both
legs): rules and sim 398,855; rendering and UI group (8 files) 621,728; audio
534,928 (of which sfx_data.js 482,216 is data, reusable either way); total
1,555,511.

## 2. Shipping a PC game on Steam

Godot route (both legs agree): official Windows export produces an optimized .exe
plus a .pck data file, exportable from the command line with --export-release.
Steam integration is GodotSteam, a third-party GDExtension wrapping the Steamworks
SDK (achievements, stats, leaderboards, cloud files, rich presence, Workshop).
Qwen adds the version detail: GDExtension 4.23.2 works on any Godot 4.4+, and
server builds track Godot 4.7.2 with Steamworks SDK 1.65. Controllers are native
through the SDL controller database (SDL 3 since Godot 4.5). Crash reporting is
Sentry's Godot SDK (third-party, verify exact 4.7 support). No first-party game
self-updater exists, which does not matter on Steam since SteamPipe handles
patching. Install size: both legs rely on community measurements (Qwen cites
around 93 MB for a near-empty export); the structural point is that real size is
dominated by game assets, and every MB figure stays approximate.

Babylon route (both legs agree): the page must be wrapped (Electron bundles
Chromium and Node; Tauri uses system WebView2 and is much smaller; NW.js is the
older option). A plain browser cannot be a Steam SKU. Steam integration is
steamworks.js (and the newer steamworks-ffi-node per Qwen) for achievements,
stats, leaderboards, cloud saves, and Workshop; Greenworks is unsupported.
Controllers go through the browser Gamepad API wrapped by Babylon's Gamepad
classes. Crash reporting is Electron's built-in crashReporter (Crashpad) plus
Sentry's Electron SDK. Auto-update is Electron's autoUpdater, Tauri's updater
plugin, or Steam depots.

DISAGREEMENT BOX: the Steam overlay. This is the one material conflict between
the legs and it matters because Qwen makes it the lead reason for its pick.
- DeepSeek: steamworks.js "documents achievements and enables the Steam overlay
through electronEnableSteamOverlay", implying overlay works on Electron.
- Qwen: Valve's own documentation states the in-game overlay does not support
games built with browser technology on Windows, macOS, or Linux, with the
sanctioned workaround being a custom native Chromium shell; Electron-specific
overlay breakage recurs across versions.
These may both be partly true (a library can attempt an overlay that Valve does
not support and that breaks across Electron versions), but that reading is chair
inference, not a verified fact. Opus must check Valve's overlay doc directly
before the A3 weigh-in treats the overlay as decisive for either side. Qwen's
related caution is also carried: the Godot 4.7 release blog's Steam mention
(alongside Steam Frame and Android XR hardware support) is unconfirmed in
exactly what it covers, and does not change the GodotSteam conclusion.

## 3. Long-term risk

Licences: no business risk on either side. Godot is MIT, free, no royalties, only
requirement is keeping the licence text. Babylon.js is Apache-2.0, also permissive
and free; Havok physics is free under MIT terms. Godot is foundation-governed open
source; Babylon is Microsoft-sponsored.

Godot versions (both legs agree on the baseline): 4.7 stable shipped 18 June 2026,
4.7.1 on 14 July 2026, 4.7.2 on 18 August 2026. Qwen adds the precision the
weigh-in needs: Godot policy supports a stable branch until the successor branch
gets its first patch release, and 4.8 beta 1 shipped 15 October 2026, so 4.7
enters limited support within a few months of 4.8 stable. That is normal and
fine by policy (minors allow only documented classes of change), but the window
for pinning 4.7.2 is months, not years. DeepSeek's framing is compatible: pin
4.7.2, take security patches, plan an upgrade to 4.8 on your own schedule.
Within 4.x the project has been comparatively steady; the big pain event was the
3.x to 4.0 jump.

Babylon versions (both legs agree): 8.20 predates 9.0 (26 March 2026) and is a
mid-2025 snapshot of a weekly-minor project with no LTS branch. Qwen adds 8.0 on
27 March 2025, 8.20.0 around late July 2025, and 9.30.0 in October 2026. Pinning
8.20 keeps working (npm packages persist) but gets no new fixes; staying pinned
is safe short-term and stale long-term. The 9.0 announcement rates v8-to-v9 risk
as LOW-MEDIUM for most users, but community reports of behavior breaks inside
9.x minors exist, so "weekly minors plus occasional in-minor breaks" is the real
cadence. The 9.15.0 decorator migration is cited as an example breaking change.

Community (both legs cite the same figures): Godot about 119k GitHub stars and
roughly 4k contributors, plus a large forum and a funded foundation. Babylon
26.2k stars, an active official forum, and Microsoft backing. Both healthy;
Godot's game-dev community is several times larger, Babylon's is stronger in
web and product-viz circles. Exact comparisons depend on how you count and stay
UNSURE.

WebGL2 versus WebGPU: Babylon officially supports WebGL 1.0, WebGL 2.0, and
WebGPU side by side, with WebGPU maintained since 5.0 and a dedicated status
page. Since 8.0 all core shaders ship in both GLSL and WGSL. No announcement
deprecates WebGL2 in the main engine, but the center of gravity is shifting to
WebGPU (Babylon-Lite, launched June 2026, is WebGPU-only). For a pinned 8.20
project this is moot until an upgrade. Godot's official web exports have no
WebGPU support, which is irrelevant for a PC-only plan.

## 4. Tools for a non-coder plus an AI builder

For Ryan personally, both legs agree Godot wins clearly: the editor is a free,
self-contained Windows download (no installer), with scenes, a node tree, an
inspector, and a play button. He can open the project, orbit the 3D view, tweak
lights and particles with sliders, and press play. Babylon today is a browser
tab; the Babylon.js Editor and web GUI Editor exist but do not open the existing
hand-written codebase as a project, so the game stays "code you run in a
browser".

For AI-driven automated work it is close, and the legs divide the same way:
- Godot: first-class command-line operation with --headless designed for CI.
Qwen adds gdUnit4 (and GUT) for headless GDScript and C# tests and Movie Maker
(--write-movie) for deterministic frame capture, which gives an AI builder a
reproducible way to capture what the game looks like. Scenes and project files
are plain text an AI can read and patch without a GUI. DeepSeek's caveat stands:
--headless disables rendering, so a screenshot step under --headless is an
explicit error, not a silent blank image; visual checks need a windowed session
or a software-rendering setup.
- Babylon: NullEngine officially runs the engine in Node with no canvas, for
tests and server-side logic, and the team uses it for end-to-end scene-graph
testing. Visual checks need a real browser (headless Chrome via
Puppeteer/Playwright); on CI without a GPU that means software rendering, which
is slow (how heavy for this scene is UNSURE per Qwen). The existing sim3d.js
Node workflow keeps working either way.
Neither side is perfect for visual testing. Godot's MCP ecosystem (godot-agent
and similar third-party tools) may close the gap but is third-party, not a
first-party engine feature.

## 5. Effects and presentation ceiling

Godot 4.7 on the Forward+ renderer (both legs agree): GPUParticles3D and
CPUParticles3D with process materials, collisions, and attractors; native
volumetric fog plus local fog volumes (Forward+ only, not Mobile or
Compatibility); SDFGI semi-real-time global illumination; Environment
post-processing (glow, SSAO, SSIL, SSR, tonemapping, depth of field, auto
exposure); clustered forward lighting with a default cap of 512 clustered
elements (lights plus reflection probes) per camera view, raisable in project
settings; AreaLight3D (real rectangular area lights, new in 4.7); HDR output on
desktop; Jolt built in and default since 4.6. Hand-written shaders are needed
only beyond the Environment toolbox (custom screen effects, stylized hex-grid
shaders), in Godot's shading language.

Babylon.js 8.20 (both legs agree): mature CPU particle systems plus
GPUParticleSystem; DefaultRenderingPipeline (MSAA/FXAA, bloom, chromatic
aberration, depth of field, color grading); VolumetricLightScatteringPostProcess
(god rays), which is screen-space light scattering, not true volumetric fog;
Havok via the official plugin, free under MIT, WASM-based. What 8.20 lacks:
clustered lighting (a 9.0 feature) and true volumetric fog (9.0 adds volumetric
lighting behind frame graphs). Qwen adds the concrete cap: each material has a
maxSimultaneousLights cap, default 4, raisable per material. Textured area
lights also arrived in 9.0. Custom work goes through the Node Material Editor
or hand-written GLSL/WGSL (dual-shader since 8.0).

Fit for Voidsworn specifically: a hex fleet-tactics game wants readable ships,
lots of simultaneous weapon-fire lights, glow, fog-of-space atmosphere, and
chunky particles. Godot 4.7 gives all of that natively today. Babylon 8.20 gives
excellent post-processing and particles but a 4-lights-per-material default and
no native volumetric fog; closing the gap means upgrading to 9.x, which is a
migration to perform and re-test. Babylon's ceiling on 9.x is arguably equal or
better, but the brief's question is 8.20, and on 8.20 Godot is higher.

## 6. The picks, side by side

DeepSeek picks Godot 4.7. Two strongest reasons: (1) shipping and support are
simpler and more predictable (native export, supported 4.7 branch, GodotSteam);
(2) the native rendering and physics ceiling is higher today. What would change
it: a benchmark win for Babylon with substantial headroom plus the rules port
judged too expensive or risky; a commitment to Babylon 9.x with its weekly
cadence and desktop shell accepted; GodotJS becoming production-ready for 4.7;
or the game proving visually simple enough that Godot's lighting and volumetric
advantages do not matter.

Qwen picks Godot 4.7 (practically, start on 4.7.2 and plan to follow minors),
assuming the benchmark does not show Babylon winning on frame time. Two
strongest reasons: (1) Steam is the product and Godot ships to Steam cleanly,
with the overlay question as the single fact that outweighs most of the porting
cost; (2) presentation ceiling and tooling match the game and the team
(volumetrics, SDFGI, area lights, HDR, 512-element light budget, plus a real
editor and headless CLI runs with deterministic movie capture). What would
change it: a benchmark win for Babylon on frame time or visual quality; a spike
test showing the 620 KB rendering/UI rewrite is beyond patience and budget
(staying on 8.20 pinned, accepting overlay limitations, is a legitimate
fallback); GodotJS maturing with prebuilt binaries; or Valve changing overlay
support for browser-tech games, or achievements and overlay not mattering at
launch.

## Open items for Opus (A3 weigh-in)

- Verify the Steam overlay question against Valve's primary doc
(partner.steamgames.com/doc/features/overlay) before treating it as decisive.
The legs disagree and the answer changes the weight of Qwen's lead reason.
- Re-check GodotJS status at weigh-in time; it is a moving target (new
maintainer, WIP 4.7 support).
- Treat every install-size MB figure as approximate; all of them are community
measurements, not vendor specs.
- The 4.7 support window closes within a few months of 4.8 stable; the weigh-in
should state whether the plan pins 4.7.2 or follows minors.
- Exact version dates (8.20.0, 9.30.0, 4.8 beta 1) are single-leg claims; they
do not affect the verdict but should not be quoted as verified if the weigh-in
leans on them.

## Sourcing note

Both legs cite primary sources with links for the load-bearing claims (Godot
docs, release policy, release pages; Babylon docs, 9.0 announcement, framework
versions; Valve partner docs; GodotJS repo). Weakest material, carried at low
weight or dropped: DeepSeek's single SteamDB depot Electron figure and its
Babylon forum Tauri note; both legs' community install-size figures; Qwen's
absence-of-evidence claims (Babylon 8.20 lacking volumetric fog, steamworks.js
lacking Steam Input), which Qwen itself tags UNSURE. Neither leg makes repo
claims beyond the brief's facts, and the chair verified all byte sums.
