# Godot desktop 3D brief (chair synthesis of the deep research pass, Oct 29, 2026)

Commissioned by Ryan during the wave 5 expansion: with the phone target dropped and the Godot build desktop-only, what does the desktop GPU budget buy, and which techniques should the effects pass plan around? Full research notes sit in the chair's workspace (report plus four source notes); this brief carries the recommendations, the evidence strength, and the costs. Source strength is marked where it matters: official Godot documentation is the strong tier; the one shipped-game performance write-up is single-source and flagged as such.

## 1. Renderer: Forward+, decisively

Official docs (docs.godotengine.org renderer comparison and decal pages) settle the feature matrix for Godot 4.7:

- Decals exist only in Forward+ and Mobile. Compatibility has NO decals in 4.7; they appear only in 4.8 dev snapshots (GH-118070). This confirms the earlier effects audit from the other direction: the Compatibility renderer is not a viable fallback for the effects pass.
- Mobile caps decals at 8 per Mesh resource; a capital ship would exceed that in one salvo. Forward+ clusters decals, and clustered elements (default 512 in view) are a SHARED budget with omni/spot/area lights and reflection probes: damage decals and explosion lights draw from the same pool, which is a budgeting fact the effects pass must plan around.
- Forward+ only: volumetric fog, SSR, SSIL, SDFGI/VoxelGI, TAA, FSR2. Particle trails and depth of field: Forward+ and Mobile only. Glow exists everywhere but Compatibility's is a reduced non-HDR implementation. Light budget: 512 per cluster in Forward+, 8 per mesh elsewhere.
- The docs' own cost profile for Forward+ is "highest base cost, low scaling cost," which matches this workload (few dozen ships, heavy effects).
- Minimum GPU: Forward+ needs Vulkan, D3D12 or Metal. Since 4.4 it auto-falls back to Compatibility when the RenderingDevice is unsupported; that degraded path must be tested or gated (pattern: check RenderingServer.get_current_rendering_method()).
- Audience floor (July 2026 Steam survey reporting): RTX 3060 is the most common Windows GPU, 1080p is about 51 to 53 percent, 8 GB VRAM is the most common. Design the default tier for that, not for the RTX 5080 on Ryan's desk.
- Best shipped-game evidence is a SINGLE dev write-up, treat as a lead: ReBirth (Godot 4.5 strategy game) ships Forward+ on PC with tiered SSAO/SSIL/SSR/volumetric fog/PCSS/DOF, measured on an RTX 4060 Laptop at 566 to 133 FPS Low to Ultra at 1080p and a Radeon 780M iGPU at 82 to 22, with FSR2 LOSING performance on the iGPU versus FSR1. No verifiable statistic exists for what shipped Godot games typically choose; the report states that plainly.

## 2. Space environment: layer by distance

- Sky: a custom shader_type sky shader (hash-grid stars; never a per-pixel star loop; nebula noise rendered in half or quarter resolution passes) or a baked 4K HDR panorama. The sky also drives image-based lighting; align the DirectionalLight to its sun.
- Local nebulae: a few ellipsoid FogVolumes with NoiseTexture3D at 64 cubed or under (Forward+ only; cost scales with screen coverage). Temporal reprojection ghosts on fast-moving lights, so set explosion lights' Volumetric Fog Energy to 0.
- The workhorse for mid-ground gas is fake-volumetric billboard quads, which Godot's own docs recommend.
- Near-camera dust particles give the parallax that sells motion.

## 3. Fleet rendering at 20 to 60 ships

- Individual MeshInstance3D scenes. Forward+ AUTO-INSTANCES identical opaque or alpha-tested MeshInstance3Ds while keeping per-instance frustum culling (Forward+ only). Per-instance variation (shield flash, team tint) comes from instance uniforms via set_instance_shader_parameter, WITHOUT duplicating materials; material duplication kills the instancing.
- MultiMesh is one draw call but has NO per-instance culling (all or nothing), only transform, color and one custom vec4, and no nodes or collision. Reserve it for projectiles, debris, asteroids and visual-only swarm elements in the hundreds.
- Mesh LOD on import plus visibility ranges for detail and effect fade; mesh_lod_threshold is a quality lever. Skip occlusion culling: open space has no occluders.

## 4. Particles: police overdraw, not count

- GPUParticles3D, pooled. The biggest risk is simultaneous capital explosions with large soft smoke: overdraw, not particle count.
- amount_ratio gives NO performance benefit (allocation is for the total amount), so quality tiers must change amount or swap scenes, not the ratio.
- The default visibility_aabb (8 cubed) causes pop-outs; generate AABBs. fixed_fps 30 is fine as a default.
- Patterns: shield hits as a shader-animated fresnel mesh, not particles; muzzle flash as quad plus sparks plus a shadowless OmniLight; explosions as one-shot pooled emitters with sub-emitters; debris as mesh draw-pass particles, then MultiMesh shader-drift fields; engine and missile trails as Ribbon/TubeTrailMesh (Forward+ and Mobile only).
- Pre-spawn effects at load despite the 4.4 ubershader mitigation.
- Generic budget figures circulating online (500 to 2,000 per effect, about 10,000 on screen) come from a single non-Godot source; treat as orientation only. The real budget gets set by the effects-pass performance budget item using PERFCAP on Ryan's PC.

## 5. Cinematic camera: build a director layer

- Tactics orbit rig for play, plus a priority shot stack for events; shots computed from live ship positions via Tweens. AnimationPlayer is for fully authored cutscenes only.
- Evaluate Phantom Camera first (MIT, v0.11.0.4 Oct 2026 on the Asset Store): group multi-target framing, Path3D dollies, framed mode, per-camera attributes and environment, noise shake. Warning: two unrelated addons are both named CineCam; do not confuse them.
- Depth of field via CameraAttributesPractical, cinematic shots only (expensive at high blur; Forward+ and Mobile only).
- Slow motion via Engine.time_scale, which does NOT affect audio; pair AudioServer.playback_speed_scale and end with an ignore_time_scale timer. In a turn-based resolution phase this is close to free drama.
- Letterboxing has no engine feature; the CanvasLayer plus ColorRect pattern is the way.
- 4.7 adds AreaLight3D (docs position it for cinematics and high-end use) and HDR output.
- This section feeds addendum item 21 (the cinematic camera and event direction block-in before cutover).

## 6. Desktop-only adoptions, ranked, with the SDFGI counter-recommendation

In adoption order: HDR glow with AgX tonemapping and debanding; clustered weapon lights; scaling and FSR quality presets; FogVolumes; SSAO; then SSR and SSIL as garnish. Textures at 2K/4K with BPTC compression, noting Godot has NO texture streaming (import compression and mipmaps only; mipmaps cost about 33 percent more memory).

Counter-recommendation: SDFGI is likely a poor fit here. It is the most demanding GI option, ships do not participate as dynamic occluders or emissives in it, and empty space gives it almost nothing to do. Use sky IBL plus ReflectionProbes; prototype SDFGI only around stations, if ever.

## Red-team corrections (Oct 29, 2026, DeepSeek and Qwen legs, chair-adjudicated)

- VRAM figure corrected: in the July 2026 Steam survey data, 16 GB is now the most common VRAM capacity (25.90 percent) ahead of 8 GB (25.32 percent). The section 1 sentence "8 GB VRAM is the most common" is superseded; the design implication is unchanged (default tier targets the RTX 3060 class at 1080p).
- Phantom Camera caveat corrected: 4.7 compatibility IS evidenced. The addon's v0.11.0.3 release notes fix an issue introduced in Godot 4.7.1 and v0.11.0.4 is current (DeepSeek leg, READ from the repo). The "Not verified" entry below is superseded on this point.
- SDFGI wording trimmed: the docs describe SDFGI as one of the most demanding GI techniques (DeepSeek leg, READ). The counter-recommendation itself stands on the documented limits (no dynamic occluders or dynamic emissive surfaces).
- amount_ratio phrasing refined (Qwen leg): it gives no memory benefit and at most a marginal compute benefit; the practical conclusion (quality tiers must change amounts or swap scenes) is unchanged.
- Two Qwen objections were checked against the primary source and REJECTED: TAA is Forward+ only per the current stable docs' antialiasing table (not in Mobile), and the docs date the Vulkan to D3D12 to Compatibility fallback chain "Since Godot 4.4," matching section 1 as written.
- AreaLight3D's dating as a 4.7 addition remains unverified by either leg (HDR output is confirmed present in stable for Forward+ and Mobile). Treat the 4.7 dating as provisional.

## Not verified by the research

- No shipped-game renderer statistics exist in a verifiable form.
- No Godot-specific particle benchmarks were found.
- Phantom Camera and the CineCam addons have no verified 4.7-specific compatibility statement.
- Letterboxing and texture streaming are confirmed ABSENT as engine features (that absence is itself verified).
