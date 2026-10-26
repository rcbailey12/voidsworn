Part 1: GodotSteam licence verdict (X18 claim)

Verdict: CONFIRMED.

The GodotSteam website states plainly that version 4.20 drops the MIT licence for a custom licence similar to GodotSteamKit's. The exact wording is:

"In the upcoming GodotSteam 4.20 (hey-o), we will be dropping the MIT for another custom license similar to GodotSteamKit's. There will be some minor modifications on what you can and cannot do with the tool but for the mass majority of people, nothing will really change."

The same announcement appears on the GodotSteam "Licenses" blog category page. The GitHub repository for GodotSteam has been moved to Codeberg, and the licence text for the new version was not directly retrievable as a standalone file during this review. The claim in the evidence pack is therefore confirmed at the level of the official announcement.

GodotSteamKit licence text (the model for the new licence):

The GodotSteamKit documentation describes its custom GSSL (GodotSteam Software License) as follows:

"you may use the Kit in any free or commerical games or software
you may use the Kit without attribution to Gramps or GodotSteam but keep the license in your project somewhere"

Comparison with MIT:

The MIT licence (which GodotSteam used up to version 4.19) requires that the copyright notice and permission notice be included in all copies or substantial portions of the software. It grants broad rights to use, copy, modify, merge, publish, distribute, sublicense, and sell, with no restriction on how the software is used in games. The new custom licence is described as "similar to GodotSteamKit's", which per the Kit summary allows free and commercial use without attribution, but requires that the licence text be kept "in your project somewhere". It is not a copyleft licence and it does not require source disclosure of the game.

Plain-words consequences for a commercial Steam release:

- What the developer may do: Use GodotSteam in a commercial game sold on Steam. The licence summary for the Kit explicitly permits use in "any free or commerical games or software". The announcement says "for the mass majority of people, nothing will really change".

- What the developer may not do: The custom licence is described as having "some minor modifications on what you can and cannot do with the tool". The exact restrictions are not published in the announcement. Based on the Kit summary, the main restriction is likely about redistribution of the tool itself, not about the game. The Kit is a paid product for the full version, while free components exist. This suggests the licence may restrict sharing the tool outside the project, but does not restrict selling the game.

- Attribution and disclosure: The Kit summary says "you may use the Kit without attribution ... but keep the license in your project somewhere". This means the developer does not need to credit GodotSteam in the game's credits, but must include the licence text in the project files (for example, in a licences screen or a text file shipped with the game).

- Steamworks SDK terms: The GodotSteam licence does not replace the Steamworks SDK terms. The developer must still comply with Valve's Steamworks terms, which are separate. Nothing in the GodotSteam licence blocks selling the game on Steam.

- Fee or approval condition: The GodotSteamKit has a paid version ($20 for the full plug-in) and free piecemeal components. The GodotSteam 4.20 licence itself does not appear to introduce a fee for using the tool in a game, but the paid Kit is a separate product. The announcement does not mention a new fee or approval condition for GodotSteam 4.20 itself.

UNSURE: The full text of the GodotSteam 4.20 licence was not found as a standalone document during this search. The exact wording of the "minor modifications" is therefore not quoted. The conclusion that the licence does not block a commercial Steam release is based on the announcement's statement that "nothing will really change" for most users and on the Kit summary, which is the licence the new one is modelled on. If the full text becomes available, the restrictions should be checked line by line.

Part 2: Godot 4.7 Windows export checklist

Each item below includes the relevant Godot 4.7 documentation link (the "stable" docs correspond to the 4.7 branch) and the failure mode if the step is skipped.

1. Texture compression for 8K ship textures
- What to do: For a Windows desktop release, use S3TC or BPTC compression for the 8K textures. The Godot documentation states: "If you intend to only use desktop, S3TC or BPTC are recommended.". In the texture import settings, enable VRAM compression and choose the appropriate mode.
- Docs link: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html#vram-compression
- Failure mode if skipped: Uncompressed 8K textures consume enormous amounts of VRAM (a single 8K RGBA texture is roughly 256 MB). This can cause out-of-memory crashes on GPUs with limited VRAM, severe stuttering due to texture streaming, and poor performance on the design-floor desktop GPU. The documentation warns that large textures without VRAM compression can crash the GPU driver in extreme cases.

2. Shader pre-compilation (Shader Baker) to avoid first-use hitches
- What to do: In the export preset for Windows, enable the Shader Baker option. The Godot documentation says: "The shader baker is disabled by default, but you can enable it in each export preset in the Export dialog by ticking the ... Shader Baker > Enabled". This compiles shaders at export time and bundles the compiled code into the PCK.
- Docs link: https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html#shader-baker
- Failure mode if skipped: Shaders are compiled at runtime the first time a material is rendered. This causes a visible stutter or hitch when new effects (weapons, explosions, shields) appear for the first time. For a game with many custom effects, this can ruin the first minutes of play. The Shader Baker removes that first-use hitch by pre-compiling the shaders during export.

3. Vulkan with Compatibility fallback
- What to do: Use the Forward+ or Mobile renderer (Vulkan by default) for the main renderer, and ensure that the fallback to Compatibility (OpenGL 3) is enabled. The documentation states: "Since Godot 4.4, when using Forward+ or Mobile, if Vulkan is not supported, the engine will fall back to Direct3D 12 and vice versa. If the attempted fallback driver is not supported either, the engine will then fall back to Compatibility when the RenderingDevice backend is not supported.". The fallback is controlled by the project setting rendering/rendering_device/fallback_to_opengl3 (enabled by default).
- Docs link: https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html#renderer-compatibility
- Failure mode if skipped: On older GPUs or systems where Vulkan is not available (for example, some integrated GPUs or older drivers), the game will fail to launch if no fallback is enabled. With the fallback, the game runs on OpenGL 3, losing advanced features such as some post-processing effects, but it remains playable. Without the fallback, the game simply does not start on those systems.

4. Known NVIDIA driver issues for Godot 4.7 on Windows
- What is documented: There are documented NVIDIA-related issues for Godot 4.7 on Windows. The Godot issue tracker contains a report for Godot 4.7.2 where the editor (and by extension the game) can crash with an NVIDIA "0x141 TDR" and unrecoverable black screens on Windows 11 when using ANGLE/D3D11. The Godot troubleshooting page also notes that the NVIDIA graphics driver can inject an overlay that causes the project manager or editor window to freeze or display glitched visuals; the workaround is to restore the NVIDIA Control Panel settings to default or disable the overlay. Community reports also mention that NVIDIA Vulkan drivers can cause visual corruption in Godot games, with a workaround of switching to Direct3D 12.
- Docs link: https://docs.godotengine.org/en/stable/tutorials/troubleshooting.html (general troubleshooting, including NVIDIA overlay note) and the specific issue: https://github.com/godotengine/godot/issues/122828
- Failure mode if ignored: Players with affected NVIDIA drivers may experience crashes (TDR, black screen) or visual glitches. The developer should be aware of these issues and consider providing a launch option to use Direct3D 12 or advising players to disable NVIDIA overlays. This is not a blocker for release, but it is a known risk to document in the release notes or support page.

Part 3: Layout and autoload review against the current godot/ tree

The review is based on the file list in the evidence pack, the full text of project.godot (provided in project_godot.txt), and the newly confirmed godot/fx/API.md (which does exist on main and was read for this review).

Risk 1: No [autoload] section in project.godot
- Observation: The project_godot.txt file contains no [autoload] section. No autoloads are registered.
- Specific risk: As scenes and game flow are added, there is no designated place for global state (for example, game settings, Steam integration, or a scene manager). Developers may be tempted to use direct references between scenes or to create ad-hoc singletons, which increases coupling and makes testing harder.
- Concrete fix: Decide on a minimal set of autoloads before godot/main/ lands. For example, a GameState autoload for persistent data and a SteamManager autoload for the Steam integration. Register them in project.godot under [autoload]. Keep the list small and document the responsibility of each autoload.

Risk 2: All GDScript warnings silenced, including integer_division
- Observation: project_godot.txt sets gdscript/warnings/integer_division=0 (line 19) along with every other warning. This silences the warning project-wide.
- Specific risk: The rules port (rules.gd) is a port of a JavaScript game and has a known hazard with integer division truncation. The evidence pack notes that the port treats int/int truncation as a known hazard. Silencing integer_division hides exactly the kind of mistake the port must avoid. A silent truncation bug could cause incorrect battle calculations that are hard to trace.
- Concrete fix: Enable integer_division as a warning (set to 1 or 2 for warning or error) for the rules scripts at least. Use per-file warning overrides if necessary, or write explicit float() casts for divisions that must be fractional. The project-wide silencing of all warnings also deserves review: turning off unused_variable and unused_parameter can hide dead code. Consider enabling the most valuable warnings (such as integer_division and unused_variable) and fixing the code rather than silencing everything.

Risk 3: rules.gd is a giant script (117,728 bytes)
- Observation: The evidence pack states rules.gd is 117,728 bytes. This is a very large single GDScript file.
- Specific risk: A file of this size is hard to navigate, increases merge conflicts if multiple developers touch it, and makes it difficult to isolate changes. However, the port has a stated rule to keep the JavaScript order and names. Splitting the file prematurely could break that correspondence and make golden-test comparisons harder.
- Concrete fix: For now, keep rules.gd as a single file while the port is being verified against the JavaScript golden tests. Once godot/main/ lands and the rules are stable, consider splitting along clear boundaries: for example, separate files for unit stats, combat resolution, and turn sequence. Each split must preserve the JS order and names within each module, and the golden tests must continue to pass. Do not split purely for line count; split when the file becomes a bottleneck for editing or review.

Risk 4: Scene coupling via battle_api.gd (the current boundary)
- Observation: The evidence pack states that "the scene talks to the rules only through battle_api.gd (commands in, view() out, event stream out)". This is a good boundary: it hides the internal complexity of rules.gd and provides a clear contract for scenes.
- Specific risk: As more scenes land (godot/main/, godot/campaign/, godot/scenes/battle/), developers may be tempted to call rules.gd directly for convenience, bypassing battle_api.gd. This would break the boundary and make the rules harder to test and change. The new godot/fx/API.md also describes a contract for effects, but it is a separate boundary. If the battle scene starts calling fx functions directly without going through an interface, the coupling between the scene and fx could grow.
- Concrete fix: Enforce that battle_api.gd is the only entry point to the rules. Add a code review rule or a lint check that forbids preload("res://rules/rules.gd") outside battle_api.gd. For fx, treat fx/API.md as a contract: the battle scene should call only the functions listed there, and fx should not reach back into the scene except through the documented callbacks (for example, returning durations). Document both boundaries in the project README.

Risk 5: godot/fx/API.md exists and defines a wide surface
- Observation: godot/fx/API.md is present and describes a detailed API for effects, including setup, ship management, weapons, shields, death, and feel (shake and hit pause). It is a 164-line contract.
- Specific risk: The API is broad, and the battle scene (G2) will call many fx functions. If the API is not kept stable, changes to fx will ripple into the battle scene. Conversely, if the battle scene starts relying on internal fx details (for example, reading fx nodes directly), the boundary breaks.
- Concrete fix: Treat fx/API.md as a versioned interface. Any change to the contract must be recorded in the file and reviewed by both the fx owner and the battle scene owner. Use signals or callbacks for asynchronous events (for example, fx.volley returns timing data, but the scene should not poll fx internals). Keep the fx implementation hidden behind the API.

What to re-check when godot/main/ lands:
- Whether the [autoload] section has been added and what autoloads are registered.
- Whether battle_api.gd remains the only entry point to rules.gd, or whether scenes have started calling rules directly.
- Whether the godot/main/ scene uses the fx/API.md contract as written, or whether it reaches into fx internals.
- Whether rules.gd is still a single file or has been split, and whether the golden tests still pass.
- Whether the integer_division warning is still silenced project-wide, or whether it has been enabled for rules scripts.

Not checked
- The full licence text for GodotSteam 4.20 (and for GodotSteamKit) was not retrieved as a standalone document. Only the official announcement and the Kit licence summary were available. The exact wording of the "minor modifications" in the GodotSteam 4.20 licence is therefore UNSURE.
- The files godot/rules/rules.gd and godot/rules/battle_api.gd could not be fetched directly during this review (the GitHub links returned errors, likely because the files are large or the fetch was blocked). The statements about rules.gd size and the battle_api.gd boundary are based on the evidence pack's description, not on a line-by-line reading of those files.
- No specific Godot 4.7 documentation page dedicated to NVIDIA driver issues was found. The information comes from the general troubleshooting page and the Godot issue tracker. The issue #122828 is for Godot 4.7.2, which matches the version in use.
- The GodotSteam GitHub repository has moved to Codeberg. The Codeberg repository was not fully inspected for the licence file. The licence conclusion is based on the godotsteam.com blog posts.
