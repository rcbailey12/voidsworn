Chair note: the model's original text used em dashes in its Repo Claims table (13 lines). Those have been normalized to hyphens here because no em dashes are allowed in anything shown to Ryan. Wording is otherwise verbatim.

Blind Review: Job C, Godot Project and Shipping (Travel Sprint, 26 Oct 2026)

Blind leg. I worked only from the pack contents, my own training knowledge of Godot 4.x and GodotSteam, and the repo file listing given in section 2. I did not consult or build on any other model's review. Where I could not reach a live source, I say so and tag the item UNSURE.

Part 1: GodotSteam Licence (the X18 claim)

Verdict: UNSURE. I cannot confirm or refute the claim from primary sources.

Why I cannot settle it. I do not have live web access. I cannot open godotsteam.com, and I cannot open the GodotSteam GitHub repository to read the current LICENSE file. My training data covers GodotSteam up through its earlier 4.x releases, during which the project's own binding code was distributed under the MIT licence. I have no training-data record of a version numbered "4.20" or of a licence change away from MIT in the GodotSteam codebase. The claim attributes the information to "DeepSeek reports," which is a second-hand summary, not a primary source.

What I can say from what I do know:

The GodotSteam project (historically at github.com/Gramps/GodotSteam, website godotsteam.com) wraps Valve's Steamworks SDK for use inside Godot. Two separate licences have always been in play:

1. GodotSteam's own GDExtension / GDNative binding code. Through the versions I can recall, this was MIT. MIT text, for reference, is the standard short form: permission is granted to use, copy, modify, merge, publish, distribute, sublicense, and sell copies, provided the copyright notice and permission notice appear in all copies, and the software is provided "as is" without warranty.

2. Valve's Steamworks SDK licence. This is NOT MIT. Valve's SDK licence restricts redistribution of the SDK files themselves, requires that the SDK be used only to build products that ship through Steam (or through Valve-approved channels), and forbids use of the SDK in competing platform software. The steam_api64.dll (or equivalent) that you ship with your game is covered by Valve's terms, not by GodotSteam's MIT licence. This has been true for every version of GodotSteam I am aware of.

On the specific claim that 4.20 "drops MIT for a custom licence similar to GodotSteamKit's":

I do not have the text of a GodotSteam 4.20 licence. I also cannot confirm what "GodotSteamKit" refers to or locate its licence text in my training data. The name might refer to a C#-oriented Steam wrapper or to a community fork, but I cannot verify either its existence or its licence wording from where I sit. I will not invent licence text or guess at terms.

What this means for the commercial Steam release right now:

Because the claim is UNRESOLVED, the team must not treat GodotSteam as cleared for the Steam build. Concretely:

- Do not integrate GodotSteam into the shipping build until someone with live web access reads the actual LICENSE file in the repo for the exact version being used, and reads the licence page on godotsteam.com, and confirms they agree.
- If the two sources disagree, treat the more restrictive reading as governing. The brief says not to resolve a conflict by picking the friendlier source. I agree with that rule.
- Regardless of GodotSteam's own licence, the Steamworks SDK files you bundle are always under Valve's SDK licence. That licence has historically required: (a) the SDK is used only for a product distributed through Steam, (b) you do not redistribute the SDK files outside your shipped product, (c) you comply with the Steam Distribution Agreement, and (d) there is no separate fee to Valve for using the SDK, but you must have a Steamworks partner account and an approved App ID.
- If GodotSteam's own code did move to a custom licence, the questions to answer before shipping are: does it require attribution in your credits or EULA? Does it require you to ship or link GodotSteam's source alongside your binary? Does it restrict commercial use or impose a royalty? Does it require you to pass through any approval before shipping? None of these can be answered without reading the actual text.

Repo tie-in: The brief references FINDINGS.md, item X18, dated 26 Oct 2026. I did not read FINDINGS.md itself; I worked from the quotation in section 3 of this pack. INFERRED: the X18 item is the only place in the pack where the GodotSteam licence question is raised.

Part 2: Godot 4.7 Windows Export Checklist

Version caveat up front. The pack says the project uses Godot 4.7.2. My training data covers Godot 4.x architecture through the 4.3/4.4 era. Godot 4.7 would plausibly exist by October 2026 given the project's roughly half-year release cadence, but I may not have 4.7-specific documentation pages in memory. Where I cite a docs URL, I am giving the most likely stable path. If the page has moved or the URL scheme changed for 4.7, the link will 404 and the reader should search the 4.7 docs tree at docs.godotengine.org. I tag any item I am extrapolating from 4.3/4.4 knowledge as INFERRED for 4.7.

2a. Texture compression for 8K ship textures

What to use for a Windows desktop release:

The target renderer is Vulkan (Forward+ by default in Godot 4.x). The desktop GPU compression family is BCn (Block Compression), also called BPTC for the newer members.

- BC7 (BPTC): best quality for RGBA albedo and detail maps. 4:1 compression ratio versus uncompressed RGBA8. Use this for the 8K ship colour/roughness/metalness maps where visual quality is the priority.
- BC1: RGB only, no alpha. Smallest footprint. Use for fully opaque textures where you do not need an alpha channel.
- BC3: RGBA with harder alpha edges than BC7. Use if the ship textures have meaningful transparency and BC7's alpha quality is not enough.
- BC5: two-channel. Use for normal maps (store X and Y, reconstruct Z in the shader). Halves the footprint versus a full RGBA normal map.

In the editor, you set this per-texture in the Import dock: select the texture, set Compress > Mode to "VRAM Compressed," and confirm the platform target is set for Windows/Desktop. For a project-wide default, look under Project Settings > Rendering > Textures (the exact path in 4.7 may differ; check the 4.7 index).

INFERRED docs link for 4.7: https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html. The equivalent stable-page URL is https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html. Flag: I could not confirm the 4.7 URL resolves. Check it.

What breaks if you skip compression:

An 8K RGBA8 texture is 8192 x 8192 x 4 bytes = 256 MB uncompressed. A handful of ship textures at that size will exhaust a mid-range GPU's VRAM (8 to 12 GB is the design floor per section 4). Symptoms: the renderer falls back to lower-resolution streaming or drops textures entirely, frame time spikes from PCIe uploads every frame, and in the worst case the driver kills the context and the game crashes to desktop. Even if VRAM holds, the load-time memory peak (all textures resident during scene load) can exceed system RAM and cause page-file thrashing on 16 GB machines. Compression is not optional for 8K assets.

2b. Shader pre-compilation to avoid first-use hitches

How Godot 4.x handles it (INFERRED for 4.7):

Godot compiles Vulkan pipeline state objects (PSOs) at the moment a shader variant is first used in a render pass. The first frame that draws a new material will hitch while the GPU driver compiles the pipeline. Godot 4.x mitigates this with a shader cache on disk (under the user data directory, shader_cache/), so the second run of the game is smoother. But the very first run, or a run after the cache is cleared, still hitches.

What the developer must do before shipping:

1. Identify every shader and every render-pass configuration the game will hit. For a game with 8K ship materials, this includes the main ship shader under different lighting setups, particle shaders for engine trails, post-processing passes, and the UI shaders.
2. Build a warmup scene or loading sequence that draws every material once off-screen (or behind a loading splash) before the player sees the first frame of gameplay. This forces PSO compilation during the load, not during play.
3. On the export side, check whether Godot 4.7's Windows export preset includes a shader pre-compilation or PSO cache step. In 4.3/4.4, the export template shipped the shader bytecode but not pre-compiled PSOs. If 4.7 added a PSO pre-compilation export option, use it. INFERRED: check Project Settings > Rendering > Shaders and the Windows export preset for any new "precompile" or "warm up" toggle.
4. Test on a clean machine (or after deleting the shader cache directory) to confirm the first-run experience does not hitch.

INFERRED docs link: https://docs.godotengine.org/en/4.7/tutorials/rendering/shaders.html or the rendering settings page. Flag: I could not confirm the exact 4.7 page. Search the 4.7 docs for "shader cache" and "pipeline."

Failure mode if skipped: Visible one-frame freezes (50 to 300 ms each, depending on shader complexity and driver) the first time each material appears on screen. In a game with large ship models entering view, this will look like stuttering during the first few seconds of any scene. Players will report it as a performance bug.

2c. Vulkan with Compatibility fallback

When each renderer is used (Godot 4.x architecture, INFERRED for 4.7 specifics):

Godot 4.x offers three renderer backends, selected in Project Settings > Rendering > Renderer > Rendering Method:

- Forward+ (Vulkan): the default desktop renderer. Full feature set: SDFGI, volumetric fog, VRS, clustered forward lighting, compute shaders for GPU particles and post effects. This is what the 8K ship textures and the desktop GPU budget in section 4 are designed around.
- Mobile (Vulkan): a lighter Vulkan path originally for mobile but runnable on desktop. Drops some heavy features (SDFGI, some volumetric options). Not the target here, but it is still Vulkan.
- Compatibility (OpenGL 3.3 on desktop, OpenGL ES 3.0 on mobile): the fallback. Runs on hardware without Vulkan support or with broken Vulkan drivers.

How the fallback is selected:

The developer sets the primary renderer in Project Settings. If the player's GPU or driver does not support Vulkan, Godot can fall back to Compatibility. In 4.x, this can also be forced with the command-line flag --rendering-driver opengl3 or by the player editing a setting. INFERRED for 4.7: check whether 4.7 added an automatic runtime fallback (Vulkan fails to initialise, engine retries with OpenGL) or whether it still requires the command-line flag or a project-setting toggle. The 4.3/4.4 behaviour was that the fallback was not fully automatic; the user or a launcher had to select it.

What is lost on Compatibility:

- No SDFGI. Global illumination falls back to lightmaps or probes only.
- No volumetric fog or volumetric lighting.
- No VRS (Variable Rate Shading).
- Compute shaders are unavailable or severely limited. GPU particle systems that rely on compute will fall back to CPU particles or not run.
- Shadow quality may drop (fewer cascades, lower resolution).
- Some post-processing effects may be unavailable or lower fidelity.
- The 8K textures still work, but the rendering pipeline around them is simpler.

For this game (PC-only, desktop GPU budget is the design floor), Compatibility is a safety net for the small fraction of players with very old or broken Vulkan drivers. The game should launch in Forward+ by default. The team should test the Compatibility path once to confirm it does not crash, but should not design for it.

INFERRED docs link: https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html. Flag: verify against the 4.7 docs index.

2d. Known NVIDIA driver issues for Godot 4.7 on Windows

I found none that I can cite. My training data does not contain a documented list of NVIDIA-specific driver issues tagged to Godot 4.7 on Windows. Historical Godot 4.x issues with NVIDIA drivers (across 4.0 through 4.4) included occasional flickering with certain driver branches, Vulkan validation-layer warnings that were cosmetic, and rare crashes tied to threaded rendering on specific driver versions. But I cannot tie any of those to 4.7 specifically, and I will not invent entries.

Recommendation: Before the Steam build, check the Godot GitHub issues tracker (github.com/godotengine/godot/issues) filtered for "NVIDIA" and "Windows," and check the Godot community forums and the r/godot subreddit for any 4.7-specific reports. Also check NVIDIA's own release notes for the driver branch current in October 2026. If nothing is documented, say so in the shipping checklist rather than assuming the absence of evidence is evidence of absence.

UNSURE: no documented NVIDIA-specific issues for Godot 4.7 on Windows found in my training data.

Part 3: Project Layout and Autoload Review (current godot/ tree)

Scope note. godot/main/ has not landed. The brief says to repeat this part when it does. What follows covers only what exists on main as of the 26 Oct 2026 check described in section 2.

3a. What exists

Per section 2, the tree is:

godot/
  .gitignore
  project.godot
  rules/
    API.md
    battle_api.gd
    jsm.gd
    rules.gd
    data/
      tables.json
    test/

godot/main/, godot/campaign/, godot/scenes/battle/ do not exist. godot/fx/ and godot/world/ did not appear in the tree listing at check time, despite commit f45852c8 mentioning godot/fx/API.md. UNSURE: I cannot confirm whether godot/fx/API.md landed after the check. The commit message references it, but the tree listing does not show it. If it exists, it should be included in this review. I could not verify.

3b. No autoloads registered

project.godot has no [autoload] section. This is clean for now. There are no global singletons, no scene-tree-persistent managers, no hidden coupling through autoloaded scripts.

Risk when scenes land: The first autoload someone adds (a GameManager, an AudioManager, a SaveSystem) becomes invisible coupling. Every scene that references it by name is coupled to its lifecycle and its API. If the autoload is renamed or removed, every referencing scene breaks with no compile-time warning in GDScript.

Concrete fix: When the first autoload is proposed, require that (1) it is listed in a short ADR or comment in project.godot explaining why it must be global, (2) scenes access it through a narrow typed interface rather than poking its internals, and (3) the autoload does not hold references to scene nodes (it should not know about the scene tree's contents). Re-check this when godot/main/ lands, because that is the most likely place an autoload will first appear.

3c. Every GDScript warning is silenced

The [debug] section of project.godot (926 bytes, full text in section 2) sets every listed warning to 0. That includes:

- integer_division=0
- unsafe_property_access=0, unsafe_method_access=0, unsafe_cast=0, unsafe_call_argument=0
- unused_variable=0, unused_parameter=0
- shadowed_variable=0, shadowed_variable_base_class=0, shadowed_global_identifier=0
- return_value_discarded=0
- narrowing_conversion=0
- untyped_declaration=0, inference_on_variant=0

The integer_division question the brief asks about:

The rules port's own trap list treats int/int truncation as a known hazard. GDScript's / operator on two ints truncates toward zero. If the port has a spot where the JS source did a / b expecting a float result and the GDScript port does a / b on two ints, the result silently truncates. The integer_division warning exists to flag exactly this. Silencing it project-wide means the compiler will not catch a new instance of this bug if someone edits rules.gd or writes a new gameplay script.

Verdict on the silencing: It is not safe as a project-wide setting, even if the current port has been golden-tested. The golden tests cover the current code. They do not cover the next person's edit, or the scene code that will land beside the rules. The silencing hides exactly the class of mistake the port must avoid.

Concrete fix:

1. Re-enable integer_division=2 (warn) at the project level. If the port's existing code produces warnings at every intentional int/int division, add a targeted @warning_ignore("integer_division") annotation on each intentional line in rules.gd rather than silencing the whole project. This is tedious but correct. It keeps the warning live for new code.
2. Re-enable unsafe_property_access, unsafe_method_access, and unsafe_call_argument at warn level. These catch the class of bug where a scene script calls a method on a Variant that might not have that method. With battle_api.gd as the boundary, unsafe access warnings in scene code are a signal that a scene is reaching past the API.
3. unused_variable=0 and unused_parameter=0 are less dangerous but still worth re-enabling at warn level once the port stabilises. Dead code in a 117 KB file is hard to spot by eye.
4. return_value_discarded=0 matters for the event stream. If battle_api.gd returns a status or an event token and a caller ignores it, that is a silent bug. Re-enable at warn.

Repo tie-in: project.godot, [debug] section, lines setting each warning to 0. The file is 926 bytes total per section 2.

3d. rules.gd is 117,728 bytes

Does it count as a giant script? Yes, by any reasonable measure. 117 KB of GDScript is roughly 3,000 to 4,000 lines (INFERRED, based on typical GDScript line lengths). Most Godot style guidance suggests keeping scripts under a few hundred lines. A single file this large is hard to navigate, hard to diff in code review, and slow to parse in the editor.

However, the port has a stated constraint: it keeps the JS source's order and names for golden-test traceability. Splitting rules.gd into multiple files would break the line-by-line correspondence with the JS original, making it harder to verify that the port is faithful.

What should split, and when:

- Not now, while the port is the only consumer and the golden tests are the primary verification tool. The 1:1 mapping with the JS source is more valuable than file-level modularity at this stage.
- When the port is declared stable (golden tests pass, no further JS-side changes to track), split rules.gd along the natural subsystem boundaries that the JS source already has (e.g., combat resolution, movement, ability effects, status conditions). Each subsystem becomes its own .gd file. battle_api.gd remains the single entry point and does not change its public interface. The golden tests should still pass after the split because the logic is unchanged.
- data/tables.json is already extracted. That is good. If any large constant tables remain inline in rules.gd, move them to additional JSON or Resource files during the split.
- INFERRED: jsm.gd likely contains the JS-to-GDScript mapping layer or helper utilities. If it grows, split it the same way.

Risk if it is never split: As scenes land in godot/scenes/battle/ and features land in godot/main/, developers will need to read rules.gd to understand behaviour. A 117 KB file with no internal navigation (assuming no inner classes or clear section headers) will slow every future change and increase the chance of a bad merge.

3e. The battle_api.gd boundary (coupling story)

What is good about it:

The boundary described in section 2 is: scenes send commands into battle_api.gd, call view() to get a read-only snapshot of game state, and subscribe to an event stream for changes. This is a clean facade pattern. Scenes do not import rules.gd directly. They do not reach into rules.gd's internal variables. The rules engine does not know about the scene tree. This means:

- The rules can be tested headlessly (no rendering, no scene tree) through the golden tests. This is already happening via godot/rules/test/.
- The rules can be swapped or refactored without touching scene code, as long as battle_api.gd's interface (commands, view(), events) stays stable.
- Multiple scene implementations (a 2D placeholder, the final 3D battle scene, a replay viewer) can all talk to the same API.

What could break it as scenes land:

1. Convenience reads. A scene developer needs one number from the rules state (say, a unit's current HP for a health bar). Instead of going through view(), they get_node or preload rules.gd and read the variable directly. This bypasses the API and couples the scene to rules.gd's internal variable names. Fix: enforce in code review that no file outside godot/rules/ imports or references rules.gd or jsm.gd directly. Only battle_api.gd may do so. A grep or a CI lint check (grep -r "rules.gd" godot/scenes/ godot/main/ should return nothing) would catch violations.
2. Event stream misuse. The event stream out of battle_api.gd is meant for "something changed, re-read the view." If a scene starts parsing the event payload for data it should get from view() instead, the event format becomes a second API that must be kept stable. Fix: keep event payloads minimal (event type and affected entity ID). Scenes call view() for the actual data after receiving an event.
3. Missing view() coverage. When godot/scenes/battle/ lands, the scene will need data that view() does not yet expose (animation state, timing hints, camera positions). The temptation will be to add scene-specific fields to view(), making it a grab-bag. Fix: extend view() with well-typed sub-structures (e.g., view().units, view().board, view().turn_state) rather than flat fields. If the scene needs something that is not game state (camera position, animation timing), that belongs in the scene layer, not in the API.
4. Autoload temptation. If someone registers battle_api.gd as an autoload to make it easy to call from any scene, they create a hidden global dependency. Fix: pass the battle_api reference explicitly to scenes that need it (through scene instantiation arguments or a typed setter), rather than relying on a global name.

3f. godot/fx/API.md status

Commit f45852c8 ("G4: effects, world and look API for the G2 battle scene (godot/fx/API.md)") references the file, but the tree listing in section 2 does not show godot/fx/. UNSURE: the file may have been added in a commit after the tree was listed, or the commit message may reference a planned path. I cannot resolve this without repo access. If godot/fx/API.md does exist, it should be reviewed here for the same coupling questions: does it define a clean boundary for effects, or does it reach into rules.gd? Re-check when the tree is refreshed.

3g. What to re-check when godot/main/ lands

Per the brief, part 3 must be repeated. When godot/main/ appears, check:

1. Whether an [autoload] section has been added to project.godot. If so, audit each autoload for the coupling risks in 3b.
2. Whether any new script exceeds roughly 500 lines. Flag it.
3. Whether godot/main/ or any scene file imports rules.gd or jsm.gd directly, bypassing battle_api.gd.
4. Whether the GDScript warning silencing is still in place. If new code has landed, the silenced warnings are now hiding bugs in untested code.
5. Whether the renderer is still set to Forward+ and whether any new rendering features (shaders, post-processing) have been added that need the shader warmup treatment from part 2b.
6. Whether godot/fx/ and godot/world/ have landed and what their coupling to rules looks like.

Not Checked

1. GodotSteam licence text for version 4.20. I could not access godotsteam.com or the GodotSteam GitHub repository. The X18 claim remains UNSURE. No licence text is quoted because I could not read any.
2. GodotSteamKit licence text. I could not identify or locate this project's licence. UNSURE.
3. Whether godot/fx/API.md exists on main. The commit message references it; the tree listing does not show it. UNSURE. Needs a fresh git ls-tree or repo browser check.
4. Godot 4.7-specific documentation pages. All docs URLs in part 2 are INFERRED from the 4.x URL pattern. I could not confirm they resolve for 4.7 specifically. The rendering and compression architecture descriptions are drawn from 4.3/4.4 knowledge and extrapolated.
5. NVIDIA driver issues specific to Godot 4.7 on Windows. None found in my training data. I did not invent any. UNSURE whether none exist or whether they post-date my training data.
6. The actual contents of rules.gd, battle_api.gd, jsm.gd, and API.md. I reviewed the project structure and the project.godot file as given in section 2. I did not read the GDScript source files themselves. The coupling and size assessments are based on the file listing, the file size, and the architectural description in the pack, not on line-by-line code reading.
7. The golden test suite in godot/rules/test/. I did not inspect the tests. The claim that the port is golden-tested is taken from the pack's description.
8. FINDINGS.md itself. I worked from the X18 quotation in section 3. I did not read the full FINDINGS.md file.

Repo Claims and Their Sources

Claim / Source in this pack:

- godot/ contains .gitignore, project.godot, rules/ - Section 2, tree listing
- godot/rules/ contains API.md, battle_api.gd, jsm.gd, rules.gd, data/tables.json, test/ - Section 2, tree listing
- godot/main/, godot/campaign/, godot/scenes/battle/ do not exist - Section 2, explicit statement
- godot/fx/, godot/world/ did not list on main - Section 2, explicit statement
- Commit f45852c8 mentions godot/fx/API.md - Section 2, commit reference
- project.godot is 926 bytes, config_version=5, no [autoload], all warnings set to 0 - Section 2, full project.godot text
- rules.gd is 117,728 bytes - Section 2, notes for part 3
- battle_api.gd is the sole scene-to-rules boundary (commands in, view() out, event stream out) - Section 2, notes for part 3
- The port keeps JS order and names - Section 2, notes for part 3
- The port's trap list treats int/int truncation as a known hazard - Section 2, notes for part 3
- Godot version is 4.7.2 - Section 4, per the parity README (not independently verified)
- Game is PC-only, desktop GPU budget is design floor, textures up to 8K - Section 4, stated as context, not verified
- Steam build is the end goal - Section 4, stated as context

Items marked INFERRED appear inline in the text above. Items marked UNSURE appear inline and are collected in the Not Checked section.
