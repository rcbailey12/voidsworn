BRIEF HAS HOLES

1 | HOLDS | READ | Godot 4.7 renderer docs mark Decals as unsupported in Compatibility, and the Godot 4.8 dev 4 release notes add decal support via GH-118070.
2 | HOLDS | READ | Godot 4.7 3D-lights docs define the 512 clustered-element view limit as omni + spot + area lights + decals + reflection probes; the Decal class docs confirm Mobile's 8-per-mesh-resource cap.
3 | HOLDS | READ | Godot 4.7 renderer comparison lists volumetric fog, SSR, SSIL, SDFGI/VoxelGI, TAA and FSR2 as Forward+ only, particle trails and depth of field as Forward+ and Mobile, and Compatibility as RGBA8/LDR with a simplified glow.
4 | HOLDS | READ | Godot 4.7 optimization docs restrict automatic instancing to Forward+ opaque/alpha-tested MeshInstance3D nodes; the MultiMesh docs state there is no per-instance screen or frustum culling.
5 | HOLDS | READ | GPUParticles3D docs explicitly say reducing amount_ratio has no performance benefit because resources are allocated and processed for the total amount.
6 | HOLDS | READ | Engine.time_scale class-reference note states it does not affect audio playback speed and directs use of AudioServer.playback_speed_scale.
7 | HOLDS | READ | Phantom Camera's repo LICENSE is MIT, releases show v0.11.0.4 current in Oct 2026, and README/docs confirm group follow, Path follow, framed follow and noise-shake features; Asset Store installation is documented.
8 | UNVERIFIABLE | READ | No accessible ReBirth devlog or benchmark table surfaced in searches, so the specific 566-133 FPS, 82-22 FPS and FSR2-versus-FSR1 iGPU figures cannot be confirmed; Godot's own docs do independently warn that FSR2 can be too expensive on slow GPUs.
9 | HOLDS | READ | Godot 4.7 SDFGI docs call it "one of the most demanding" GI techniques and explicitly say it does not support dynamic occluders or dynamic emissive surfaces; the "empty space" conclusion is inference but consistent with those limits.
10 | WRONG | READ | July 2026 Steam data still has RTX 3060 as the top GPU and 1080p at 51.10%, but 16 GB VRAM is now the most common capacity at 25.90%, ahead of 8 GB at 25.32%; the brief's "8 GB VRAM is the most common" is stale.

Additional holes

- The brief's "Not verified by the research" section says Phantom Camera has no verified 4.7-specific compatibility statement, but Phantom Camera v0.11.0.3 release notes explicitly fix an issue "introduced in Godot 4.7.1," and v0.11.0.4 is current. That directly contradicts the brief's caveat.
- The SDFGI counter-recommendation overstates the docs slightly: the docs say "one of the most demanding" GI techniques, not uniquely "the most demanding." The practical conclusion still stands, but the absolute wording is not exact.

Not checked

- The original ReBirth devlog and its exact benchmark methodology, because no accessible copy was found.
- The claimed "two unrelated addons both named CineCam" warning, because no primary source was located.
- Whether Phantom Camera is specifically "current on the Godot Asset Store" as opposed to current on GitHub; the GitHub release and README were verified, not the store listing itself.
- The brief's claim that Godot's docs specifically recommend fake-volumetric billboard quads, because the exact recommendation was not located.
- The "mipmaps cost about 33 percent more memory" figure, which was not source-checked.
- Valve's primary Steam Hardware Survey page; July 2026 figures were checked through multiple secondary reports (ixbt, TweakTown, PCMag) rather than the dynamically changing Valve page.
