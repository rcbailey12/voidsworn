# Travel sprint Job C: Godot project and shipping review (chair synthesis, Oct 26, 2026)

Three blind legs, all filed and screened: DeepSeek
(contrib/deepseek/sprint_jobC_deepseek_raw_2026_10_26.md), Qwen
(contrib/qwen/sprint_jobC_qwen_raw_2026_10_26.md), and Argon
(contrib/gemini/reviews/gemini_sprint_jobC_argon_high.md). Part 3
in all three legs is pack-bound (tree listing and project.godot
text from the pack); the chair independently confirmed the
project.godot facts against the local copy (no [autoload]
section, no [rendering] section, integer_division=0 at line 20).
Where the legs disagree, this synthesis picks a side and says
why. The licence verdict below is a chair verdict, not a leg
verdict, because the legs split on it and the chair checked the
primary sources directly.

## Part 1: GodotSteam licence (X18) - CHAIR VERDICT

Verdict: for the SHIPPED GodotSteam GDExtension, the X18 claim
is REFUTED. The shipped product is MIT. The announcement behind
X18 was real, but it did not change what shipped.

The two facts, both verified:
- The announcement existed. DeepSeek quoted godotsteam.com:
  "In the upcoming GodotSteam 4.20 (hey-o), we will be dropping
  the MIT for another custom license similar to GodotSteamKit's,"
  with "some minor modifications" and "nothing will really
  change" for most people. The chair confirmed that wording with
  a direct search result from the godotsteam.com GodotSteamKit
  blog category page, which carries the "Dropping MIT" heading
  and the same sentence. DeepSeek did not invent it.
- The shipped GDExtension stayed MIT. The chair read the mirror
  license.md file for the 4.20/4.21 GDExtension package in full:
  it is the standard MIT License text, headed "Copyright (c)
  2015-Current | GP Garcia, Chris Ridenour, and Contributors".
  The current Codeberg repository pages for godotsteam and
  godotsteam-server both carry a "License: MIT license"
  section, and the Codeberg README also carries the No LLM
  Policy notice Argon mentions, corroborating that these are
  current upstream pages. The Godot Asset Library page fetched
  by the chair confirms the current listing is GodotSteam 4.23.2
  with Steamworks SDK 1.65, matching Argon's version pairing
  (the fetched Asset Library text did not itself reproduce a
  licence field, so the MIT verdict rests on the Codeberg
  README lines and the full license.md text, not on that page).

Why the legs split, and why neither leg verdict stands alone:
DeepSeek confirmed the announcement but could not retrieve the
shipped licence text, so it stopped at "confirmed at
announcement level". Argon checked shipped packages and
refuted the drop, but its "Verified Reference Tracks"-style
blanket label overstates one item (see above on the Asset
Library page). Qwen, with no live access and training through
the 4.3/4.4 era, correctly stayed UNSURE and advised not
treating GodotSteam as cleared until someone with live access
checked. That check has now been done by the chair, so Qwen's
caution is answered, not left open as a blocker.

The non-MIT licence belongs to a different product.
GodotSteamKit is Gramps's separate, closed-source, paid
starter-kit product (helper scenes and custom nodes), and
search results confirm its licensing "will not be MIT".
Qwen's guess that the Kit "might refer to a C#-oriented Steam
wrapper or to a community fork" is wrong and is not repeated
here. The Kit's exact licence text remains unquoted and is
irrelevant to Voidsworn unless Opus ever adopts the Kit itself.
Argon's INFERRED theory that a readme link placed the Kit next
to 4.20 and caused the confusion is unnecessary: the
announcement was real, it was a plan for an upcoming version,
and the shipped GDExtension did not follow through on it.

What this means for a commercial Steam release of Voidsworn:
- Nothing in the GodotSteam GDExtension licence blocks selling
  the game on Steam.
- Attribution: include the GodotSteam copyright notice and the
  standard MIT permission/disclaimer notice in shipped
  third-party legal notices (a LICENSES.txt file in the install
  folder or an in-game credits/legal screen), alongside the
  Godot Engine MIT notice. No source disclosure is required;
  MIT is not copyleft. No royalties, no licence fee, no
  commercial approval from GodotSteam's authors.
- Steamworks SDK terms are separate and still apply: shipping
  steam_api64.dll is governed by Valve's Steamworks SDK Access
  Agreement, which requires an active Steamworks partner account
  (and an approved App ID), permits redistributing
  steam_api64.dll for the Steam release, and forbids
  redistributing the unpublished SDK source headers to
  non-licensees. The SDK files are under Valve's terms, not
  under GodotSteam's MIT licence, in every version.
- Do not submit AI-generated PRs or issues to the upstream
  GodotSteam repository (its No LLM Policy).
- Residual action, cheap and worth keeping: Opus verifies the
  licence file inside the exact GDExtension version bundled at
  build time, because a contrary announcement once existed.
  That is a build-time glance, not a blocker.

## Part 2: Godot 4.7 Windows export checklist

Docs links below are leg-cited to docs.godotengine.org/en/4.7/.
The chair did not re-verify each docs page line by line; Qwen
flags its 4.7 URLs as INFERRED from the 4.x URL pattern, and
DeepSeek's screening notes the same mapping caveat for its
stable-branch links. Verify any link that 404s against the 4.7
docs index rather than treating a dead link as a dead item.

Item 1: texture compression for 8K ship textures

- Set Compress Mode to VRAM Compressed (the default for 3D
  textures). Enable High Quality (compress/high_quality), which
  on desktop selects BPTC: BC7 for LDR colour/albedo/ORM
  textures, BC6H for HDR textures, instead of older S3TC
  (BC1/BC3). For normal maps keep Normal Map enabled so Godot
  stores two-channel RGTC (BC5) and reconstructs Z in the
  shader. Enable Mipmaps Generate. Keep
  rendering/textures/vram_compression/import_s3tc_bptc enabled
  (true by default on desktop).
- Docs (leg-cited): importing_images.html and
  class_resourceimportertexture.html under
  docs.godotengine.org/en/4.7/.
- Why it matters, with checked arithmetic: one uncompressed 8K
  RGBA8 texture is 8192 x 8192 x 4 = 256 MiB at the base level,
  about 341 MiB with the mip chain. At BPTC (1 byte per pixel)
  the same texture is about 64 MiB base, about 85 MiB with
  mips. With roughly 20 ships on the board each carrying
  albedo, normal, ORM, and emissive maps, skipping VRAM
  compression blows past the desktop GPU budget and risks
  PCIe-upload stalls, thrash to system RAM, or a driver context
  loss. Skipping High Quality falls back to S3TC, with block
  artifacts on dark hulls, banding on Ithar pearl sails, and no
  HDR compression support.
- Compatibility caveat (Argon, docs-quoted): High Quality VRAM
  compression is only supported in Forward+ and Mobile. On the
  Compatibility renderer it is always considered disabled, so
  BPTC-only exports degrade to S3TC or fail to load there.
  Ship an S3TC fallback or accept the degradation on that path.

Item 2: shader pre-compilation to avoid first-use hitches

- Keep the shader cache enabled
  (rendering/shader_compiler/shader_cache/enabled). Enable the
  Shader Baker in the Windows export preset (introduced in
  4.5; documented under Shader baker in
  pipeline_compilations.html), and verify that
  rendering/rendering_device/driver.windows matches the primary
  shipping driver (vulkan or d3d12), because the baker only
  exports shaders matching the configured driver; a mismatch
  means the baked cache is silently ignored.
- Build a warmup step: during the battle loading screen (or 1
  to 2 frames behind a loading curtain), instantiate a hidden
  warmup node containing one tiny mesh for every ship hull
  shader, shield shader, lance beam shader, and weapon
  particle/VFX material, in a viewport matching the battle
  scene's WorldEnvironment, MSAA, and lighting, so the driver
  compiles the exact pipeline combinations before turn 1.
- Verify with the Profiler's pipeline compilation monitors
  (PIPELINE_COMPILATIONS_CANVAS, MESH, SURFACE, DRAW,
  SPECIALIZATION). Any non-zero PIPELINE_COMPILATIONS_DRAW
  during combat means a missed warmup material.
- Failure mode if skipped: the first time a lance beam fires, a
  shield ripples, a ship steps on the damage ladder, or a death
  explosion spawns, the driver stalls to compile that pipeline
  on demand, a visible hitch on the combat climax. The legs
  disagree on magnitude (Argon 15 to 150 ms, Qwen 50 to 300 ms);
  both are leg estimates, neither measured, so this synthesis
  gives no precise figure. Test on a clean machine or after
  deleting the shader cache directory to see the true
  first-run experience.
- Docs (leg-cited): pipeline_compilations.html,
  class_renderingdevice.html, class_performance.html under
  docs.godotengine.org/en/4.7/.

Item 3: Vulkan (and D3D12) with a Compatibility fallback

- Forward+ (forward_plus) is the primary desktop renderer,
  powered by the RenderingDevice backend (vulkan or d3d12 on
  Windows). Critical 4.7 nuance, Argon-only and carried because
  it changes a project setting: starting in Godot 4.6 and
  continuing in 4.7, Direct3D 12 (d3d12) is the default
  RenderingDevice driver for new projects on Windows,
  controlled by rendering/rendering_device/driver.windows.
  This project.godot sets no driver.windows (chair-confirmed:
  no [rendering] section at all), so Godot 4.7 will default to
  d3d12 on Windows and only switch to vulkan if D3D12
  initialization fails, unless Opus sets driver.windows
  explicitly. Opus action: set driver.windows deliberately and
  make the shader baker match it.
- Compatibility (gl_compatibility) is the fallback: OpenGL 3.3
  / OpenGL ES 3.0 (opengl3 or opengl3_angle over D3D11 on
  Windows), for older GPUs or drivers that cannot initialize a
  RenderingDevice context.
- Fallback selection: within RenderingDevice, if the primary
  driver fails to initialize, Godot attempts the alternate
  RenderingDevice driver on Windows. But automatic fallback
  from a crashing Forward+ driver to gl_compatibility does not
  reliably catch driver-level initialization crashes on older
  GPUs (issue #120409, below). Ship a Steam Launch Option (or
  launcher wrapper flag) passing --rendering-method
  gl_compatibility so players can force Compatibility mode
  before the engine initializes RenderingDevice. Qwen's
  alternative flag (--rendering-driver opengl3) is the older
  form and is unverified for 4.7; it is not presented as
  equivalent to the method flag.
- What is lost on Compatibility: BPTC High Quality texture
  compression (see Item 1); compute shaders and
  RenderingDevice APIs including CompositorEffect post
  processing; VoxelGI, SDFGI, and screen-space reflections;
  volumetric fog, with lighting switching to multi-pass
  per-object OpenGL lighting with stricter light/shadow
  limits; plus Qwen's VRS loss, shadow quality drop, and
  reduced post-processing fidelity. The game launches in
  Forward+ by default and tests the Compatibility path once to
  confirm it does not crash; it is a safety net, not a design
  target.
- Docs (leg-cited): renderers.html, upgrading_to_godot_4.6.html,
  importing_images.html, compositor.html under
  docs.godotengine.org/en/4.7/.

Item 4: known NVIDIA driver issues for Godot 4.7 on Windows

- There is no dedicated 4.7 NVIDIA driver page in the Godot
  manual (all legs agree). The evidence is issue-tracker
  evidence, not docs-page evidence, and the synthesis presents
  it that way.
- Issue #122828 (in both DeepSeek and Argon, which strengthens
  it): Godot 4.7.2, Compatibility renderer (opengl3 and
  opengl3_angle / D3D11), multi-window or separate game-window
  sessions, access violation followed by NVIDIA 0x141
  (VIDEO_ENGINE_TIMEOUT_DETECTED) display hang, monitors lose
  signal. Related #122221.
- Issue #120409 (Argon-only, leg-stated): Godot 4.7 Forward+ /
  Vulkan initialization crash on older NVIDIA Maxwell/Kepler
  GPUs (GeForce 750M, 920M, where NVIDIA no longer ships newer
  D3D12 Typed UAV Load drivers). Godot 4.7 logs "No support for
  Typed UAV Load Additional Formats has been found on D3D12",
  switches to Vulkan Forward+, and crashes to desktop before
  the window finishes loading. Reported as a regression from
  4.6, present in 4.7.1 and 4.7.2. Workaround: force Mobile or
  Compatibility (--rendering-method gl_compatibility).
- Qwen found no 4.7 NVIDIA issues in its training data and
  refused to invent any. That absence is explained by its
  training cutoff, not by evidence of absence, and Qwen itself
  says so. Its recommendation (check the issue tracker before
  the Steam build) is already satisfied by the two issues above.
- Steam Overlay note (Argon, leg-stated, from GodotSteam docs):
  the Steam Overlay may fail to hook under Vulkan when launched
  from the editor on Windows, though exported builds launched
  via the Steam client hook properly.

## Part 3: project layout and autoload review (current godot/ tree)

Scope: godot/main/ has not landed. This part covers only what
exists now and must be REPEATED when godot/main/ lands. One
stale line appears in two legs and is corrected here: both
Argon and Qwen record godot/fx/API.md as UNSURE because the
pack's tree listing did not show godot/fx/. That was
check-time state. godot/fx/API.md has since been CONFIRMED on
main (13,540 bytes). The re-check list below therefore includes
diffing fx/API.md against the rules event stream, with the file
available.

Current state, agreed by all three legs and chair-confirmed
where noted:
- godot/ contains .gitignore, project.godot, and rules/ only.
  rules/ contains API.md, battle_api.gd, jsm.gd, rules.gd,
  data/tables.json, and test/. godot/main/, godot/campaign/,
  and godot/scenes/battle/ do not exist.
- No [autoload] section in project.godot (chair-confirmed).
  Zero autoloads registered. This is clean: rules.gd and
  battle_api.gd do not depend on global singletons, so they can
  be instantiated deterministically in headless golden tests.
- Every listed GDScript warning is silenced to 0 in the [debug]
  section (17 warnings, chair-confirmed; integer_division=0 at
  line 20). The warning set includes integer_division,
  narrowing_conversion, untyped_declaration,
  inference_on_variant, unsafe_property_access,
  unsafe_method_access, unsafe_cast, unsafe_call_argument,
  and return_value_discarded, among others.
- rules.gd is 117,728 bytes in a single file. All three legs
  give byte-derived line estimates (Argon roughly 2,800 to
  3,500; Qwen roughly 3,000 to 4,000); none is a line count, and
  none is used for any threshold here.
- The scene layer talks to rules/ exclusively through
  battle_api.gd: commands in, view() out, event stream out.
  rules/ has zero dependency on Node3D, SceneTree, cameras,
  shaders, or frame timing.

Verdicts and fixes:

1. Autoloads: keep godot/rules/ strictly out of [autoload].
   A battle session should be instantiated as a RefCounted
   object (or owned by the battle root controller) and passed
   down to godot/scenes/battle/, never reached as a global.
   Restrict any future [autoload] entries to true
   process-lifetime services only (for example, a PlatformSteam
   wrapper so GodotSteam callbacks tick in _process(), and a
   top-level AppRouter or SettingsManager). Qwen's additional
   rule is carried as a recommendation: any first autoload
   needs a written reason (ADR or comment in project.godot),
   a narrow typed interface, and no references to scene nodes.

2. Silenced warnings: UNSAFE as a project-wide setting, by
   unanimous leg verdict. The golden tests cover the current
   code; they do not cover the next person's edit or the scene
   code landing beside the rules, and the silencing hides
   exactly the truncation class the rules port's trap list
   warns against. Fix: re-enable the critical warnings at warn
   level (=1) at the project level: integer_division,
   narrowing_conversion, unsafe_property_access,
   unsafe_method_access, unsafe_call_argument, and
   return_value_discarded (Argon's list, which Qwen's fix
   agrees with in substance). Scope the JS-port suppressions
   to rules.gd and jsm.gd with file-level @warning_ignore
   blocks (or per-line annotations where a single intentional
   division needs it). Do NOT copy Qwen's "=2 (warn)" label:
   on Godot's scale (0 Ignore, 1 Warn, 2 Error), 2 is Error,
   not Warn; warn is =1.

3. Giant script: rules.gd stays a single file while JS parity
   golden testing is active, by unanimous leg verdict. The
   port's stated constraint (preserve JS source order and
   function names for golden-test traceability) outweighs
   file-level modularity at this stage, and splitting now
   would break 1-to-1 diffability against the JS reference.
   When the port is declared stable (golden tests pass, no
   further JS-side changes to track), split along the JS
   subsystem boundaries (combat resolution, movement, ability
   effects, status conditions), with battle_api.gd's public
   interface unchanged and the golden tests still passing
   after the split. Move any large inline constant tables to
   JSON or Resource files during the split; tables.json is
   already extracted. For scripts OUTSIDE godot/rules/, carry
   the legs' recommendation as a guideline, not an approved
   rule: flag any new script over roughly 500 lines, and split
   battle presentation into focused controllers (HexBoardView,
   ShipPawn3D, BattleHudController, BattleCameraRig, FxDirector).

4. Boundary risks as scenes land (merged from all three legs):
   - View() pass-by-reference mutation (Argon): Dictionary and
     Array values are passed by reference in GDScript. If
     view() returns internal rules dictionaries, or if scene
     code caches a view() dictionary and mutates it for
     selection state or sort order, the scene silently
     corrupts authoritative rules state. Fix: view() returns
     freshly constructed snapshots, or .duplicate(true) /
     .make_read_only() on returned containers.
   - Synchronous signal snapping (Argon): if battle events are
     wired directly to synchronous signals that update UI and
     3D transforms at the same timestamp as view(), health bars
     drop and ship pawns snap before movement, beam, and death
     animations play. Fix: BattleSceneController pulls the
     event stream after each command and drains it through an
     async presentation queue (await fx_director.play_event),
     syncing to the final view() snapshot only once the queue
     drains.
   - Convenience direct reads (Qwen): a scene needing one
     number must not preload rules.gd or jsm.gd and read the
     variable directly. Fix: code review plus a CI lint check
     (no file outside godot/rules/ may reference rules.gd or
     jsm.gd; only battle_api.gd may).
   - Event stream as a second API (Qwen): if scenes parse event
     payloads for data instead of calling view(), the event
     format becomes a second API to keep stable. Fix: keep
     event payloads minimal (event type plus affected entity
     ID); scenes call view() for data after receiving an event.
   - View() grab-bag (Qwen): when scenes need data view() does
     not expose, extend view() with well-typed sub-structures
     (units, board, turn_state), never flat scene-specific
     fields. Camera position and animation timing belong in
     the scene layer, not in the API.
   - Autoload temptation (Qwen and Argon): do not register
     battle_api.gd as an autoload for convenience. Pass the
     battle_api reference explicitly to scenes that need it.

Re-check list when godot/main/ lands (repeat Part 3 against
these, merged from all three legs plus DeepSeek's list):
- Inspect project.godot: run/main_scene, any newly registered
  [autoload] entries, whether rendering/rendering_device/
  driver.windows is explicitly set, and whether GDScript
  warnings remain globally silenced (=0).
- Audit the import/preload graph: no file in godot/rules/
  preloads or references anything in godot/main/, godot/
  scenes/, godot/fx/, or godot/world/, and godot/scenes/battle/
  only imports godot/rules/battle_api.gd (never rules.gd or
  jsm.gd directly).
- Verify view() and event stream consumption in godot/scenes/
  battle/: no mutation of view() containers, and combat events
  sequenced asynchronously rather than resolving visuals and UI
  on the same frame.
- Check scene ownership and cleanup on transition: campaign
  map to battle scene transitions must cleanly free
  WorldEnvironment, 3D ship meshes, and particle emitters
  without orphan nodes or leaked RIDs.
- Check the renderer is still Forward+ and whether new
  rendering features (shaders, post-processing) need the
  shader warmup treatment from Part 2 Item 2.
- Diff godot/fx/API.md (now confirmed on main) against the
  rules event stream: does it define a clean effects boundary,
  or does it reach into rules.gd? Check godot/fx/ and godot/
  world/ coupling to rules the same way.
- Flag any new script over roughly 500 lines.

## Not checked

- Each docs link in Part 2 is leg-cited, not chair-verified
  page by page. Qwen's 4.7 URLs are INFERRED from the 4.x URL
  pattern; DeepSeek asserted a stable-branch mapping the chair
  did not re-verify. A 404 on any link means the page moved,
  not that the item is wrong.
- The exact GodotSteamKit licence text remains unquoted. It is
  irrelevant to the GDExtension verdict above, and the chair
  did not retrieve it as a standalone document.
- Valve's Steamworks SDK Access Agreement text was not read by
  the chair; the SDK summary in Part 1 is leg-stated across
  all three legs and consistent between them, not
  chair-verified against the agreement.
- NVIDIA issues #120409 and #122828 are issue-tracker evidence
  (Argon-only for #120409, two-leg for #122828), not docs-page
  evidence, and neither was re-verified by the chair against
  the live tracker in this synthesis.
- No leg read the GDScript source files line by line; all Part
  3 repo observations are pack-bound (tree listing and
  project.godot text), plus the chair's grep confirmations
  noted above.
- Argon's Part 1 licence clause summaries are paraphrases, not
  the full verbatim MIT text (its page showed a reframing
  footer note). The chair's verification rests on the full
  mirror license.md read and the Codeberg README licence
  lines cited above, not on Argon's paraphrase.
