# Per-weapon effects brief (from NEXT.md)

Archived Nov 8 2026 (issue #265, NR3) when NEXT.md was retired. Moved verbatim from NEXT.md under "Effects, doubled down". It now sits with the current effects work: the #232 stress pack and the FX stack under R122. It replaces the section issue #232 reads from NEXT.md.

- [ ] Effects, doubled down (owner: "extremely high quality", "visceral and punchy", plasma must feel nothing like lasers). Starts as soon as C (perf, touches effect pooling) merges. Every weapon family gets its own look, timing and impact:
  - Laser/las: instant coherent beam, hard white core with faction-colour glow, sharp muzzle flash, burn line and spark spray on impact.
  - Plasma: slow fat bolts with a churning molten core and wobbling corona, heat shimmer, splashing impact that leaves glowing slag, drips and smoke; low thump.
  - Autocannon/tracer: rapid stream of small tracers, brass-bright flicker, peppered hull pings.
  - Rail: near-instant streak with a shock ring at the muzzle, delayed punch-through, debris out the far side.
  - Lance/ion: thick charged beam with build-up, crackling arcs; ion leaves a blue static wash on the shield facing.
  - Needle (Ithar): fine glassy shards, prismatic glints. Spine/bio (Chorus): spat organic projectiles, wet bursts.
  - Torpedoes: textured bodies, exhaust trails that curve, big detonation with flipbook fire and shockwave.
  - Game-feel rules (docs/skills/game-feel): importance tiers (small/medium/large presets for every event), trauma-based camera shake (trauma^2, smooth noise, decays; hits add trauma), real-time hit-stop that never blocks input, eased "pop" tweens, 5-8 stacked responses within ~100 ms for a big hit; Settings toggles "reduce screen shake" and "reduce flashing".
  - Punch for everything: hit-stop on big hits, scaled camera kick, flash, hull sparks/debris, shield ripples at the struck point, sound synced (sfx.js).
  - Explosions: Blender-rendered flipbooks (fireball, debris, smoke) on the PC GPU, broken hulls with closed cut faces, staged capital deaths.
    Status Oct 20: tools/blender/fxsim.py runs Mantaflow on the PC (Blender 4.5.14, OptiX) and renders tintable flame/smoke channel frames, but sims at 64 res look blobby and symmetric. Next: res 192+, randomised/noisy emitters (several offset spheres, turbulence force), longer frames, crop+pack into 8x8 atlases; or render a CC0 VDB explosion set (cheaper, higher quality). Effects workstream owns this.
