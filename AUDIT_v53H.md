# Voidsworn v53, workstream H: leftovers, visual asset inventory, gallery harness, cleanup and fidelity plan

Audited: `master` at 5d37b55 (v53.3), read-only. Scripts live on branch `v53-H` (worktree `scratchpad/wt-H`). In-flight branches checked so ownership is right: C (perf: hull fetch, scene-graph diet, pooled text, shared ring geometry), E (faceted board rocks `mkFacet`, block tint, Ithar sails and material), G (concept-hull material `aiHullMat` with shader ports, `HullQ` ray casts and `seatOnHull`, no procedural turrets on concept hulls, new procedural craft), F (sound, nothing committed yet).

Line numbers refer to master. "Lines" are source lines, but this codebase packs a lot onto each line, so byte counts are given where they matter.

---

## 0. The short version

1. **The procedural ship build still runs in full for every concept-mesh ship and is then thrown away.** In Chromium on this sandbox, building all 29 classes costs **3.5 s** of main-thread time. The 27 classes with a concept mesh account for **3.3 s**: about **2 M vertices** are built and then disposed by `applyAIHull`, which keeps only the anchor lists (guns, hard points, bays, stacks, arcs, nav, `surf`) plus the plume and flare meshes. In Node with NullEngine, under heavier load, the same work measured 7.7 s (6.9 s thrown away), and 5.3 s with phone settings. Voidsworn and Hegemony are the worst: 150 to 670 ms per class in the browser, from 584 to 2,112 kit parts each. Views are created lazily inside `updateWorld`, so each new class lands as a hitch of hundreds of milliseconds in the first frames of a battle (and again when reinforcements of a new class arrive). The fix is an anchors-only build mode (section 5a, step G2). It needs no new art and removes about 90% of the build cost.
2. **The procedural extras that survive the hull swap are what floats.** These are turrets (`addTurrets`), nav lights (`navList` from procedural stations), plumes and flares (clamped to a box), Corsair stack smoke, Deathless arc points, scorch decals (`hullDecal` uses procedural station widths), fires and sparks (random points in an L×H box), and the v48 port quads (random triangles, random angles). G is already re-seating anchors with ray casts and replacing the quads with shader ports. Decals, fires and sparks are not in G's list yet.
3. **Effects went through three generations and all three are still in the code.** These are the v42 shaders (gfx3d), the v44 sprite pool (vfx3d) and the original mesh, material and ParticleSystem paths (fx3d). The pool now covers flashes, bursts, sparks, fireballs and smoke, but every one of those functions still carries its old fallback, and a dozen effects never moved to a pool. Those still create a mesh plus a material (plus a ParticleSystem or TrailMesh) on every call: muzzle flame streaks, shader fireballs, beams, rifts, torpedoes, lance charge, Deathless arcs, storm lightning, decal embers, ship fires and stack smoke.
4. **About 9.2 MB of unreferenced hull meshes ship with the game**: 15 files in `hulls/` and 15 in `hulls_hi/` from earlier concept rounds, plus a stale `hulls/index.json`.
5. **Dead code with no owner**: the title screen's hidden 2D canvas loop, `drawShipShape`, `runDemo`/`PREVIEW_DEMO` with build.py's preview mode, `loftMesh`, `SB.ring` and the model `anim` loop, `flashers`, `hexTex`, `ripple`, `G.tex.ring`, the `quality==='low'` branches, `M.paint`, the old plume material and its two textures, and three cloud noise textures generated on desktop for a phone fallback.
6. **Fidelity ceiling.** The concept hulls are the best-looking thing in the game at board zoom and the weakest-looking close up. A single soft Hunyuan shape mesh gets a generic 2048 panel texture box-projected onto it (seams wherever the projection axis flips, panels at the wrong scale), plus per-vertex AO, with no UVs and no normal map. The biggest visual win is a per-hull bake: UV unwrap, a normal map from the high-poly Hunyuan output, curvature and AO, and an emissive window mask. After that: CC0 or Blender explosion flipbooks, concept meshes for stations, relays and the two missing hulls, and a shader-drawn board grid.

### Top 15 leftovers by payoff
1. L1 Procedural build thrown away for 27 concept classes: 3.3 s of build and about 2 M vertices per full set. The anchors-only build was prototyped: 98% faster, identical anchors. (G, after G merges)
2. L23 A dozen effects still allocate a mesh and material (plus a ParticleSystem or TrailMesh) on every call: muzzle streaks, fireballs, beams, rifts, torpedoes, arcs, lightning, fires. This is the main remaining source of combat hitches. (C)
3. L8 and L40 Generated plating sets take about 75% of texture memory (about 43 of 56 Mpx in a battle), and 17 materials per faction are built when about 6 are used. (G, fidelity pass)
4. L2 and L3 v48 port quads and the turret height map: the floating windows. (G, in progress)
5. L16 and L17 Decals, fires, sparks and hit points placed with procedural widths or boxes: they float off concept hulls. (G)
6. L19 Wrecks keep glowing ports; wrecks and traffic are full ship builds with turrets. (G and E)
7. L38 30 unreferenced hull files, 9.2 MB on every publish. (none, now)
8. L20 and L21 Sprite-pool and beam fallbacks: the old generation of effects, about 36 lines. (C)
9. L29 Env probe rendered once at boot, so reflections never match the battle's sky. A one-line fix with a visible gain. (C)
10. L5 The concept-hull toggle keeps the whole procedural look supported. (G)
11. L24 Faction materials animated twice per frame. (C)
12. L35 and L36 The hidden 2D title loop running every frame, plus the dead preview demo. (none, now)
13. L14 and L28 The old plume material, its 2 textures and per-frame scroll; 3 cloud textures built on desktop for a phone fallback. (G and C)
14. L39 One material per nebula or storm card. (E)
15. L9 to L13, L22, L25 Small dead code: `loftMesh`, `SB.ring`/`anim`, `flashers`, `buildGeneric`, `M.paint`, `hexTex`, `ripple`, the `low` tier. (none or G)

---

## 1. Measurements

### 1a. Procedural build cost (Node + NullEngine, `scratchpad/nodeprobe/shipcost.js`)
Method: data.js and ships3d.js evaluated under Babylon 8.20 NullEngine, with materials stubbed (so texture generation is excluded). Each class was built twice and the second build timed. `applyAIHull` was run on the decoded `hulls_hi` mesh. The sandbox has 2 cores at load average 4 or more, so absolute times are about 2x a quiet desktop. Use the ratios.

| class | build ms | kit parts | verts built | concept | applyAIHull ms |
|---|---:|---:|---:|---|---:|
| voidsworn Frigate | 316 | 584 | 83,060 | V14_23 | 65 |
| voidsworn Destroyer | 488 | 690 | 97,910 | V15_37 | 35 |
| voidsworn Cruiser | 452 | 1,364 | 154,046 | V16_37 | 67 |
| voidsworn Carrier | 473 | 1,089 | 131,917 | **none (procedural)** | - |
| voidsworn Battleship | 726 | 1,926 | 221,869 | V17_37 | 108 |
| voidsworn Dreadnought | 836 | 2,112 | 243,897 | V1b_r_23 | 155 |
| hegemony Frigate to Super-dreadnought | 357 to 488 | 1,209 to 1,600 | 95k to 145k | H7 to H10, H4 | 43 to 108 |
| corsair Frigate to Carrier | 57 to 290 | 176 to 379 | 24k to 55k | C13s to C16s | 40 to 142 |
| corsair Battle-barge | 270 | 556 | 79,003 | **none (procedural)** | - |
| chorus (5 classes) | 123 to 249 | 131 to 197 | 44k to 60k | B19 to B22, B16 | 38 to 83 |
| ithar (5) | 57 to 144 | 102 to 215 | 19k to 39k | I14, I11, I15, I16, I8 | 27 to 74 |
| deathless (4) | 37 to 67 | 64 to 88 | 12k to 16k | D9, D20, D21, D22 | 26 to 50 |
| **all 29** | **7,676** | 18,274 | 2.19 M | | 3,538 incl. one 1.7 s GC spike |
| **thrown away (27 concept classes)** | **6,933** | | **1.98 M** | | |
| phone settings, all 29 | 5,286 | 17,154 | 1.64 M | | |

`partLib()` is a one-time 98 ms. The anchors that survive are cheap to compute: they come from the builder's parameters, not from the geometry.

**Anchors-only prototype** (`scratchpad/nodeprobe/lite.js`): `SB` methods return transform placeholders when `lite` is set; `loft` records stations only; `part`, `greeble` and `tube` are skipped; `finish` builds root, fore, aft, plumes and flares only. Over all classes, built back to back on a busy box: **full 18.8 s vs lite 0.30 s**, with **identical anchors for every class** (guns, hard points, nav, bays, stacks, arcs, `surf`, plume positions, flare count). The one output lite does not produce is `H` (hull height, taken from mesh bounds). `applyAIHull` should set it from the concept mesh, which is more accurate anyway.

### 1b. The same build in the browser (`scratchpad/probeH.py`: Chromium headless over http, High, hulls loaded, under the smoke lock)
Real materials and textures this time (each faction's materials were built first, so their texture cost is not counted per ship).
- Procedural build of all 29 classes: **3,541 ms**. The 27 concept classes account for **3,316 ms**. `applyAIHull`: 1,187 ms total (10 to 70 ms per class; Chorus Frigate showed one 519 ms spike).
- Per class (build ms / applyAIHull ms): Voidsworn 246/71, 184/41, 672/48, Carrier 159/-, 197/47, 240/47. Hegemony 150/39 to 176/19. Corsair 41 to 75. Chorus 53 to 217. Ithar 22 to 55. Deathless 11 to 33.
- What `applyAIHull` leaves under the prototype: `hull_ai` (fore and aft), `hull_aiwin` (the v48 port quads: 73 to 393 quads per ship), `hull_aitrim`, and the plumes and flares placed for the procedural hull.
- Live ships in a battle: a concept Voidsworn Battleship is 9 meshes and 39.6k vertices (hull, ports, trim, 1 procedural turret, flare, plume). The procedural Voidsworn Carrier is 14 meshes and **132k vertices** (3.3x).

### 1c. Scene census (same probe)
| | meshes (enabled) | materials (unused) | textures | texture Mpx | geometries | lights | particle systems |
|---|---|---|---|---:|---:|---:|---:|
| Title screen (3D showcase battle) | 895 (544) | 204 (17) | 60 | 35.9 | 382 | 13 | 1 |
| Battle (graveyard, Voidsworn vs Corsair, High) | 993 (446) | 326 (**82**) | 94 | **56.3** | 540 | 14 | 1 |

Unused at battle time (no mesh bound): all six factions' `paint` and `flesh` materials, `sail` for the four factions without sails, `plume` (the old StandardMaterial, L14), and each faction's `win`, `tip`, `steel`, `trim` and `dark` where only concept hulls appear. That is 17 materials per faction from `facMats`, of which a concept-hull fleet uses about 6. Unused textures: `ring` (L20), `cloudA` to `cloudC` (L28), `fireSheet` (L26, forced by `warmFx`), `starT3`, `beamT` (L21), `moonTex2`.

Material counts by prefix in the battle: `segM` 68 (shield ring segments, one material per segment per ship, needed for per-facing alpha), `nebM` **46** (34 sky banks plus **one material per nebula-hex card**: `addMat` inside the card loop, scene3d 298; storm cards do the same, 462), `iffM` 21, `prowM` 17, `riftM` 11 and `jumpM` 3 (arrival effects allocated per ship, L23).

Texture memory: the generated plating sets from `facMats` dominate. Per Voidsworn, Hegemony or Corsair faction on desktop: hull and dark albedo at 2048² (8.4 Mpx), normal and ORM at 1024² ×2 (4.2 Mpx), window 512². That is about 12.9 Mpx, around 52 MB as RGBA8 before mips. Chorus, Ithar and Deathless use 512² sets (about 1.6 Mpx). The battle above held Voidsworn, Corsair and Hegemony sets (Hegemony from the title showcase and wreck builds), so **about 43 of the 56 Mpx (around 75%) are plating textures** whose main remaining consumer, box-projected onto concept hulls, is the weakest part of the close-up look (L8, F1).

---

## 2. Deliverable 1: leftovers inventory

Owner key: **C** perf, **E** world, **F** sound, **G** ship close-ups, **none** = unowned. The "When" column says what each item has to wait for (section 5a). Risk is the chance of a visible or functional regression if the item is removed as described.

### 2a. Ship build: procedural work superseded by concept meshes

| # | Where | What it was for | Superseded by | Evidence | Removable | Risk | Owner | When |
|---|---|---|---|---|---|---|---|---|
| L1 | ships3d.js `buildShipModelFresh` 676-679, `buildShipModelProc` 680-691, `SB.finish` 226-238, `bake`, the `GeoBuf` adds, all `build*` and `*Detail` passes 282-560, `greeble` 204-214 | The procedural hulls of v44 | 27 of 29 concept meshes (`AI_HULLS`) | `applyAIHull` 643 disposes every `hull_*` mesh, which is every procedural part (finish merges parts per material as `hull_<mat>`), and the emblems. Sections 1a and 1b: 3.3 s in the browser (6.9 s in Node under load) and about 2 M verts per full set are built and discarded. Surviving outputs are anchor lists plus plume and flare meshes. | Now: an anchors-only mode (`SB.lite`: `push` records a placeholder, `part`/`greeble`/`loftVD`/`add` skip geometry, `finish` builds root, fore, aft, plumes and flares only), about 40 lines changed. Later, once anchors live in the hull sidecars and the last 2 hulls have meshes: delete about 280 lines (29 KB) of builders, keeping `buildCraft`, the station kit and `partLib` for stations and debris. | Low for lite mode (same anchor code paths). Medium for full deletion (needs a sidecar anchor format). | G (C for timing) | After G merges `seatOnHull` (it consumes these anchors) |
| L2 | ships3d.js 658-670, inside `applyAIHull` | v48 "lit ports" quads and spine trim | G's shader ports in `HullFxPlugin` (`HULLFX_AI`) | Random triangle picks, one quad per pick at the triangle normal: this is where the windows floating at random angles come from. G's working tree deletes it. | 13 lines | none | G | In G |
| L3 | ships3d.js 671-674 | Turret heights from a 40×14 height map | G's `HullQ.seat` | Coarse grid, cannot follow the real surface | 4 lines | none | G | In G |
| L4 | vfx3d.js 109-123 `turretProto`, `addTurrets`; fx3d 412 `turretTips`, 462 `aimTurrets` | Procedural dorsal turrets that traverse (v44) | Turrets modelled into the concept meshes | G now skips `addTurrets` when `p.aiHull`. It still runs for the 2 procedural hulls, wrecks and traffic. | Keep for now. About 15 lines go when the last procedural hulls go. | low | G | After L1 full deletion |
| L5 | ships3d.js 632 `aiHullsOn`; ui3d.js 72, 511, 513 (`ACT.aihull`, the button); main3d.js 11 `G.aiHulls` | Settings toggle "Concept-art hulls" from the v46 trial | Concept hulls are the art direction now | This switch is what keeps the whole procedural path a supported look. `ACT.aihull` also orphans `MODEL_CACHE` prototypes (deleted, not disposed). | About 8 lines plus one button | low (a player who turned it off sees concept hulls again) | G or none | After G |
| L6 | ships3d.js 235-236 (emblem planes), 16-25 `emblemMat` | Faction emblems on hull sides | Nothing for concept hulls (disposed in `applyAIHull`) | An emblem texture and material per faction is generated even when every ship of that faction has a concept mesh | Comes with L1 lite mode. Emblems could come back as decals on the baked texture (section 5b). | none | G | With L1 |
| L7 | ships3d.js 52-56 `windowTex`, 69 (hull `emissiveTexture`), fx3d 75 (Deathless emissive scroll) | Window strips painted into the procedural hull texture | Shader ports. G's `aiHullMat` nulls the emissive texture. | Only procedural hulls still use them | 6 lines, plus a 512² texture per faction | low | G | After G |
| L8 | ships3d.js 26-50 `styleTex`/`panelTex` at 2048², 62 `mapsFromCanvas` at 1024² ×2 per faction | Generic tiled plating for lofted hulls | Still used: `aiHullMat` keeps the albedo and bump, box-projected at k=3.2 (`decodeAIHull` 636) | Desktop Voidsworn, Hegemony and Corsair each carry 2×2048² plus 4×1024² generated maps, roughly 65 MB of VRAM per faction with mips. On concept hulls they read as stretched panels with seams. | Not dead, but the strongest candidate for replacement by per-hull baked textures (section 5b, F1) | - | G | Fidelity pass |
| L9 | ships3d.js 92-102 `loftMesh` | The pre-v44 loft | `loftVD` | No call sites | 11 lines | none | none (G's file) | After G |
| L10 | ships3d.js 168-170 `SB.ring`; fx3d 142 and 586 (the `model.anim` loop and dispose) | Spinning rings on hulls | - | `SB.ring` has no callers, so `anim` is always empty and the loop runs on nothing for every ship, every frame | 3 lines plus 2 references | none | G | After G |
| L11 | ships3d.js 302, 366, 479, 553; scene3d 490, 496, 504 (`b.flashers.push`) | Blinking tip lights | `navLights` sprites (vfx3d 159) | `flashers` is never read. The spheres bake into the geometry and never flash. | 7 call sites reduce to plain `sph` calls | none | G or E | After G |
| L12 | ships3d.js 461 `buildGeneric` | Fallback for factions "not in the prototype yet" | All six factions have builders | Only reached for an unknown style | 1 line | none | G | After G |
| L13 | ships3d.js 78 `M.paint` | Painted panels | - | Never read | 1 line, 6 PBR materials | none | G | After G |
| L14 | ships3d.js 82-83 `M.plume` StandardMaterial and `M.plumeOld`; gfx3d.js 184-191 `plumeFadeTex`, `plumeTex`, `plumeMaterial`; gfx3d 277 (`G.tex.plume.vOffset` every frame) | v42 textured plume | v44 `plumeShaderMat` (vfx3d 89) | The shader always compiles on WebGL, so `M.plume` is replaced immediately and the old material is kept only as `plumeOld` (never read) | About 10 lines, 2 textures, 6 materials | low (keep a one-line fallback to `emMat` if the shader throws) | G or C | After G |
| L15 | ships3d.js 640 `loadAIHulls` (the file:// early return); 641 sequential fetch; `delete MODEL_CACHE[k]` | First load of the v46 trial | C's parallel awaited fetch with a progress gate | Under file:// every ship silently becomes procedural, which is why worldshot.py serves over http. C fixes the fetch and orphaned prototypes (`trimModelCache`). | C | - | C | In C |

### 2b. Ship-attached extras still placed by procedural geometry (these float on concept hulls)

| # | Where | What | Evidence | Fix | Owner |
|---|---|---|---|---|---|
| L16 | fx3d.js 391-397 `hullDecal` | Scorch and ember planes on hits | Placed at `side*(st.w+L*.004)`, the procedural station half-width, so on concept hulls they hang in space or sink inside. Each ember also creates its own `emMat` and an observer. | Seat with `HullQ.cast` (G's class), or drop decals on concept hulls: the damage shader (`shipDamageFx`) already burns the surface. Pool the ember material (one per faction). | G |
| L17 | fx3d.js 61-69 `addFire`; vfx3d 101-104 `damageSparks`; fx3d 403 `hitPoint`; fx3d 557 (pre-blast points) | Fires, sparks, hit points and pre-blasts at random points in an L×H×0.1L box | On thin or odd hulls (Deathless crescents, Ithar needles, Chorus) these land off the hull | Sample points on the mesh: a cached list of hull vertex positions per prototype, picking one at random | G |
| L18 | fx3d.js 143 (stack smoke ParticleSystems), 159-162 (Deathless arcs), vfx3d 159-164 (nav lights) | Points from `stacks`, `arcs`, `nav` | G re-seats all three in `seatOnHull` | Done in G | G |
| L19 | scene3d.js 399-402 (`HOLE_BUILD.hulk`), 474-476 (graveyard wrecks), 534-537 `buildTraffic` | Wrecks and distant traffic build full live ships | The wreck material swap checks `Mw.win/eng/tip/sail` but not `aiwin`/`aitrim`, so concept-hull wrecks keep their lit ports and spine trim glowing on master. Turrets are added to wrecks and traffic too. Traffic costs 3 extra full builds per desktop battle. | Build wrecks from the concept mesh in anchors-only mode with the damage shader at dmg=1 (no ports). Traffic uses the merged prototype only. | G and E |

### 2c. Effects: superseded generations, fallbacks and unpooled allocations

| # | Where | What it was for | Superseded by | Evidence | Removable | Risk | Owner |
|---|---|---|---|---|---|---|---|
| L20 | fx3d.js 292-294 (`flash` plane path), 300-304 (`burst` ParticleSystem), 370-373 (`fireball` ParticleSystem with `fireSheet`), 377-379 (`sparks` ParticleSystem), 383 (`muzzleFx` fallback), 615-616 (`shockwave` disc using `G.tex.ring`); vfx3d 22-24 (`fxSprite` plane path), 74-77 (`debrisTrail` ParticleSystem) | The v42/v44 mesh and particle paths | The v44.1 sprite pools (`fxPool`, two SpriteManagers) and `shockRing` | `poolOK()` is true whenever the scene exists, since the SpriteManager is created on first use. A failure is caught and gives `mgr:null`, after which every effect would go back to allocating per call. | About 30 lines. `G.tex.ring` (256²) goes too. | low (if the pool fails, skip the effect) | C |
| L21 | fx3d.js 323 `beamTex` and 330 (a second inline `G.tex.beam` builder), 328 and 331 (the textured-cylinder path), 332 (`G.tex.beam.vOffset` in every beam observer) | v42 textured beam | `beamMaterial` shader | `typeof beamMaterial==='function'` is always true. `G.tex.beam` is still created on the first beam and scrolled every frame for nothing. | About 6 lines | low | C |
| L22 | fx3d.js 351 `hexTex`; 517 `ripple` | Old shield ripple | `shieldDome` shader | No callers | 2 lines | none | none |
| L23 | Allocations per call that never moved to a pool: vfx3d 26 `fxStreak` (a plane plus a StandardMaterial on every `muzzleBlast`, i.e. every lead shot, and on every death streak); gfx3d 237 `fireballFx` (a `ShaderMaterial` per fireball; the mesh is a clone); fx3d 324 `beam` (cylinder plus ShaderMaterial per beam, and per rail shot); gfx3d 346 `warpRift` (plane plus ShaderMaterial per arriving ship); fx3d 477-480 (torpedo: mesh, material, ParticleSystem(240), TrailMesh, head plane plus material, per torpedo); vfx3d 62 `chargeFx` (ParticleSystem per lance shot); fx3d 81 `arcBolt`, 159-162 (Deathless arc tubes every 0.1 to 0.28 s), scene3d 522 `updateStorms` (tube plus material per lightning bolt); fx3d 395 (decal ember material); fx3d 61 `addFire` (2 ParticleSystems per damaged ship); 143 (stack ParticleSystems); vfx3d 106 `craftTrails` (TrailMesh per craft); fx3d 255 `startTrail` | Effects written before pooling | - | v44.1 measured these patterns (about 20 objects per death) as the cause of hitches and recompiles. These remain. | Pool: add a cone and streak cell to the `fxPool` atlas (streaks), pool `fireballFx`, `beam` and `warpRift` meshes with materials (the `fxShPool` pattern already exists), torpedoes as pooled sprites plus a pooled TrailMesh, arcs and lightning as pooled streak sprites, fires and stack smoke through `fxp` smoke | 0 removed, about 60 changed | medium (visual parity checks) | C |
| L24 | fx3d.js 101-103 (in `updateWorld`) **and** 72-80 `animateFactionMats` (called at 163) | Chorus, Deathless and Ithar window and sail pulses | `animateFactionMats` | Both write `M.win.emissiveColor` and `M.sail.alpha` every frame and the second write wins. Only `MATS.chorus.flesh` is unique to the first block. C rewrote 101-102 to `scaleToRef` but kept both blocks. | 3 lines (move the flesh pulse into `animateFactionMats`) | none | C |
| L25 | fx3d.js 255, vfx3d 157, 180 (`G.quality==='low'`) | A "low" quality tier | Tiers are ultra, high and medium (`ACT.quality` cycles 3) | These branches are never taken. If an old save stored `low`, `setQuality` treats it as High. | 3 conditions | none | none |
| L26 | fx3d.js 337-350 `fireSheet` (1024² texture with 4-octave noise per pixel, about 1 M noise evaluations), forced in `warmFx` (vfx3d 199) | Flipbook for ParticleSystem fire | Pool fireballs. Still used by `addFire` only. | Built at every first battle start, on phones too (cached in IndexedDB afterwards) | Goes when `addFire` moves to the pool (L23) | low | C |
| L27 | gfx3d.js 284-293 `shieldShatter` (instances, fine); fx3d 306-321 `shieldDome` (pooled, fine) | - | - | Already pooled. Listed only to say they are OK. | - | - | - |

### 2d. Scene, boot and environment

| # | Where | What | Evidence | Removable | Risk | Owner |
|---|---|---|---|---|---|---|
| L28 | scene3d.js 79 (`nts=[noiseTex(...)×3]`) | 256² cloud textures for the phone fallback | Built on desktop too, where every bank uses `nebulaMaterial`. Phones use them only for banks 6-13. | Build them only when `G.mobile` | none | C |
| L29 | scene3d.js 85-89 `makeEnvProbe` (512 cube, `RENDER_ONCE`) | PBR reflections | Rendered once at boot with the default sky. `applyBiome` and `composeBackdrop` re-tint the sky and swap the planet every battle, but the probe is never refreshed, so hull reflections show the boot sky. | Not dead: a bug. Call `G.probe.cubeTexture.resetRefreshCounter()` after `applyBiome`. | none | C (lighting) |
| L30 | scene3d.js 290-291 (two 8-shape rock sets, `lo` and `hi`), 376-381 `lumpyRock` (flat-shaded, used by the hole asteroid, comet and rock chunks) | v44/v49 rocks | E's `mkFacet` blockers and 4 light dressing shapes | E replaces the board rocks. `lumpyRock` (the "crumpled paper" look) remains for set pieces. | E | E |
| L31 | scene3d.js 32-33 (chromatic aberration and grain configured, then disabled on every tier), 113 | v42 finish | v45 turned both off | Configuration only, nothing renders | 2 lines | none | none |
| L32 | scene3d.js 105 (TAA pipeline, Ultra only, off unless the setting is on); fx3d 445 and scene3d 349 (depth of field in cut-ins, Ultra only) | v42 options | - | Rarely used but valid. Keep. Gallery and smoke never exercise them. | keep | - | none |
| L33 | ui3d.js 685-712 (Diagnostics panel, Shift+D); campaign3d.js 119-123 (P-key perf readout); C's new perf3d profiler | Three overlapping performance readouts | C's profiler | Consolidate into one panel after C merges | about 10 lines | none | C |
| L39 | scene3d.js 297-298 (nebula-hex cards), 462 (storm cards) | One `addMat` per card | - | 12 to 40 extra StandardMaterials per battle (census: `nebM` 46). Each is its own draw state, and all cards share one look per type. | Create one material per colour per battle | none | E (scene3d) |
| L40 | ships3d.js 57-87 `facMats` | 17 materials per faction built eagerly | - | A concept-hull fleet uses about 6 (census: 82 unused materials in battle). Builders reference `M.win`, `M.tip`, `M.steel` and so on only on the procedural path. | Create them lazily through a getter, or drop them with L1 and L13 | low | G |
| L34 | scene3d.js 223-235 `healScene` (v41 safety net) | Recovery from meshes missing bounding info | Root cause fixed (templates `refreshBoundingInfo`) | Keep: cheap insurance, runs only on a frame error | keep | - | none |

### 2e. Legacy 2D, demo and dead UI

| # | Where | What | Evidence | Removable | Risk | Owner |
|---|---|---|---|---|---|---|
| L35 | campaign_meta.js 41-61 (title `titlecv` 2D canvas rAF loop); campaign3d.js 8 `drawShipShape(){}`; head.html `.title canvas{display:none}` and its earlier rule | The 2D-era animated title | The live 3D title showcase | The canvas is `display:none`, so `clientWidth` is 0, but the loop still runs every frame on the title screen (gradients and 260 `fillRect` calls) and calls an empty `drawShipShape` 3 times | About 22 lines | none | none (now) |
| L36 | campaign3d.js 125-145 `runDemo`; build.py `preview` mode (`PREVIEW_DEMO` flag, `voidsworn-3d-preview.html`) | The scripted demo for the deleted preview artifact (removed Oct 11) | Only reached when `window.PREVIEW_DEMO` is set, which only build.py's preview mode does | About 22 lines plus 3 in build.py | none | none (build.py: after C, who edited it) |
| L37 | core.js 48-59 `migrateMeta` (`v<2`, telemetry `backfilled` scan), `migrateRun` (`v<2`) | Saves from before Oct 10 | v53 `normalizeRun` and `saneSave` | Small and harmless. Keep for safety. The `backfilled` telemetry scan could go after a release or two. | keep | - | none |
| L38 | hulls/ and hulls_hi/: B13_23, B15_23, B17_37, B18_11, C9_23 to C16_23 (non-s), D4_37, D7_11, D8_37 (15 in each); hulls/index.json (lists only D22) | Earlier concept rounds | The `AI_HULLS` map (28 ids) | Not referenced anywhere in the code. 3.4 MB plus 5.8 MB. Every publish uploads them as artifact files. | 30 files, 9.2 MB | none (still in git history and the asset lab) | none (now) |

### 2f. Things that look like leftovers but are not
- `gunList` synthesized hull ports (ships3d 216-220). The broadside volley needs them. Under L1 lite mode they stay, since they are computed from stations, not geometry.
- `partLib` and `SB`. Stations, debris, craft (G) and the 2 procedural hulls use them.
- `M.flesh`. Unused on master, but G's new Chorus craft uses it. Keep.
- `G.boltBases`. Instanced bolts, already efficient.
- `warmFx`. Still needed while effects build materials lazily. It shrinks as L23 pools land.

---

## 3. Deliverable 2: visual asset inventory and grades

Grade bar: "high quality, like a modern indie space tactics game" (think *Nebulous: Fleet Command* or *Battlefleet Gothic: Armada* at their zoom ranges). A = holds up in a close-up hero shot. B = good at mid zoom, minor tells close up. C = reads well at board zoom, clearly cheap close up. D = toy or placeholder close up. Grades are close / mid / board.

### 3a. Ships, squadrons and their attachments

| Asset | Built in | Technique | Quality branches | Grade | Weakness close up |
|---|---|---|---|---|---|
| Concept hulls (27 classes: Voidsworn 5, Hegemony 5, Corsair 4, Chorus 5, Ithar 5, Deathless 4) | ships3d `applyAIHull`, data from hulls/*.json and hulls_hi/*.json | FLUX concept, Hunyuan3D 2.1 shape, decimated 16k (phone) and 20-38k (desktop) tris, int16-quantized JSON, per-vertex baked AO and cavity (v52) | `hulls/` on phone and Medium, `hulls_hi/` on High and Ultra | C- / B- / B | Soft, blobby Hunyuan geometry with no hard edges. No UVs: the generic 2048 panel texture is box-projected (k=3.2), so it seams where the axis flips and the panel scale has nothing to do with the hull. No normal map. On master, random-angle port quads float off the surface and procedural turrets, nav lights, plumes and decals float near it (G fixing). Pale Ithar reads flat (E toned the material). Deathless frigate D9 is the old plaque. |
| Procedural hulls (Voidsworn Carrier "Reliquary", Corsair Battle-barge boss; and every ship under file://) | ships3d `buildGothic`, `buildJunk` | Lofted Chaikin hull plus kitbash boxes, cylinders and bevelled slabs, merged per material | Greebles ×0.6 on phone, bevels skipped below 2% of L on phone, 10-sided cylinders on phone | D+ / C / C+ | Kitbash: repeated parts, thin boxes, box windows. Out of family next to the concept hulls in the same fleet. |
| Squadrons (fighter, bomber per faction; Chorus spores) | ships3d `buildCraft` (G rebuilding), `craftInstance` | 5-8 primitives merged and instanced; 3 craft orbit the wing root; TrailMesh per craft on High and Ultra | Trails off on Medium | D / D+ / C | Literal boxes and cones (the owner's "box squadrons"). G's new lofted craft should reach C+/B-. |
| Engines | ships3d `engine`, vfx3d `plumeShaderMat`, `makeWholeProto` (merged plumes) | Shader cone (core, sheath, shock diamonds, flicker) plus billboard flare; engine PointLight for the opening fleets on High and Ultra | One merged flare on phones | C+ / B- / B | The cone silhouette is visible from the side. On concept hulls, flares are shrunk ×0.55 and clamped to a box near the stern (G re-seats them on the nozzles). |
| Nav lights | vfx3d `navLights` | Pooled sprites, blinking | - | C / B / B | Placed from procedural stations, so they float off concept hulls (G re-seats them). |
| Emblems | ships3d `emblemMat` | Canvas-drawn 256² decal planes | - | - / - / - | Disposed on concept hulls. |
| Turrets | vfx3d `addTurrets` | One instanced merged turret per faction (box hood plus 2 barrels) | Desktop only, L ≥ 12 | D / C / C | Generic box turret, floating (removed on concept hulls by G). |
| Transports (Intercept objective) | battle.js startBattle `transport` | The faction's frigate model, weapons stripped | - | as that frigate | Not visually distinct from a frigate. |
| Battle damage | gfx3d `shipDamageFx`, fx3d `addFire`, vfx3d `damageSparks`, fx3d `hullDecal` | Cloned hull material with burn front and glowing cracks (shader); ParticleSystem fire using the procedural `fireSheet`; smoke vents; pooled sparks; scorch plus ember planes | Sparks halved on Medium | C / C+ / B- | Fire sprites are low-res soft blobs. Fires and sparks spawn in a box, not on the hull. Decal planes float on concept hulls. G already damps the burn-front ribbon. |

### 3b. Weapons, shields, explosions

| Asset | Built in | Technique | Quality branches | Grade | Weakness |
|---|---|---|---|---|---|
| Bolts (las, plasma, tracer, spine, needle, glob, rail) | fx3d `shoot`, `boltBase`, vfx3d `boltMat` | Instanced fresnel spheres stretched along flight; trailing instance; pooled halo sprite | Sphere segments 6 on Medium, 10 otherwise; halos only on lead bolts on phones | C+ / B- / B | Stretched spheres look like capsules close up. No motion blur or heat glow. |
| Broadside volleys | fx3d `volleyPlan`, vfx3d `volleyMuzzle`, `volleyImpact` | Up to 42 visual bolts from gun lists; pooled star, glow and streak sprites | Cap 42 Ultra, 30 High, 14 Medium, 9 phone, 6 Reduced | B- / B / B | Gun points come from procedural ports (`gunList`), so on concept hulls bolts start off-hull until G re-seats them. |
| Muzzle flame | vfx3d `muzzleBlast`, `fxStreak` | Pooled star sprite plus a per-shot stretched plane with `coneTex` | Sparks off on Medium | C+ / B- / B | Allocates a mesh and material per shot (L23). |
| Lance beams | fx3d `beam`, gfx3d `beamMaterial` | Shader cylinder (white core, sheath, noise crawl); `chargeFx` ParticleSystem; flash light | 14-sided | B- / B / B | The cylinder end-caps show at grazing angles. Too thin at board zoom (v55 "thicker beams"). |
| Torpedoes and rockets | fx3d `animWeapon` torp branch | Emissive cone or sphere mesh, ParticleSystem smoke trail, TrailMesh, flare head billboard; faction flight curves | TrailMesh 24 segments on Medium | C / C+ / B- | The body is an untextured cone. Everything is allocated per torpedo. |
| Point defence and flak | vfx3d `pdFire` | Pooled tracer streaks and flak pops | Lower rate on phones | C+ / B- / B | Fine. |
| Shield hits | fx3d `shieldDome` | Pooled sphere with hex ripple ShaderMaterial, squashed to an ellipsoid | - | B- / B / B | The ellipsoid does not follow the hull shape. |
| Shield collapse | gfx3d `shieldShatter` | Instanced hex shards plus burst | 10 shards on Medium | C+ / B- / B | - |
| Shield ring (status) | fx3d `makeShieldRing` (C shares the geometry) | Tube arcs per facing, IFF ring, prow chevron | - | C / C+ / B (UI) | It is a UI element. Fine. |
| Explosions (hits) | fx3d `explode` | Pooled flash, star and sprite fireball, plus the shader fireball (`FIRE_GLSL`, noise-displaced sphere) for size ≥ 1.3 (≥ 3 on Medium); sparks; smoke | Shader fireball threshold by quality; phones get fewer sprites | C+ / B- / B | Sprite fire and smoke are procedural soft blobs with no flipbook detail. The shader fireball is a displaced sphere with a visible silhouette. |
| Capital deaths (blast, cut, big, flay, melt, dark) | fx3d `animExplode`, `fragmentHull`, gfx3d `fireballFx`, vfx3d `shockRing`, `debris` | Staged pre-blasts, reactor fireballs (shader plus sprites), shock ring shader, 3-7 jagged sections with wreck materials, thin-instance debris, vent fire | Medium: two-piece split instead of fragments (C) | B- / B / B | Fragment cut faces are open: no cap geometry, and two-sided materials show the inside of the shell. Debris are faceted icospheres. The sprite fire has no flipbook. |
| Hulks (persisting) | fx3d `updateHulks`, vfx3d `hulkCookOff` | Drifting fragments with pooled smoke and cook-offs | - | C+ / B- / B | Wreck material is flat dark PBR. |
| Hyperspace arrival | fx3d `updateWorld` (`jumpStreak` box), gfx3d `warpRift` | Stretched emissive box plus rift ShaderMaterial plane | Rift skipped when Reduced | C / B- / B | The streak is a box. The rift allocates per ship. |

### 3c. World: set pieces, terrain, backdrop

| Asset | Built in | Technique | Quality branches | Grade | Weakness |
|---|---|---|---|---|---|
| Board asteroids (blocking hexes) | scene3d `buildBattleEnv` (master: noise icosphere instances; E: `mkFacet` thin instances) | Master: 8 lo plus 8 hi icosphere noise bodies, RockFx shader, 256² canvas texture with derived normal | subdivisions 6/9/17/24 by tier | Master C- / C / C+. E's rebuild targets C+/B-. | 256² canvas noise texture: smeary close up. Master shapes read as soft potatoes. Specular sparkle (E fixed). |
| Rim fill and dressing | scene3d `buildRimFill` | Thin-instanced light rock shapes, darker material; debris and cloud walls; centrepieces | Fewer on phones | C / C / B- | Repeated three shapes. Cloud-wall cards are billboards. |
| Background belt and ring | scene3d `buildBelt`, ring in `buildBattleEnv` | 2,500 plus 2,500 thin instances of tiny icospheres | subdivision 3/4 | - / C+ / B | Fine at distance. |
| Giant asteroid (hole or rim piece) | scene3d `HOLE_BUILD.asteroid`, `lumpyRock` | Flat-shaded icosphere (subdivision 4) plus 7 chunks | - | D / C- / C | Faceted "crumpled paper" look. |
| Moonlet | `HOLE_BUILD.moon` | Sphere with a 512×256 canvas crater texture | - | D+ / C / C+ | Low-res texture, no normal map. |
| Comet | `HOLE_BUILD.comet` | Lumpy rock plus an additive cylinder tail | - | D / C- / C | The tail is a visible cylinder. |
| Derelict station (hole fill) | `HOLE_BUILD.station` | SB kitbash: cylinders, tube arcs, boxes, ember boxes | - | D / C- / C | Primitive kitbash. |
| Map stations (ring, rig, spire) | scene3d `buildRingStation`, `buildRigStation`, `buildSpireStation` | SB kitbash; emissive box windows; `flashers` that never flash | - | D+ / C / C+ | Primitive shapes, no texture detail, box windows. The ring station is the Hold-the-station objective, so it is in the spotlight. |
| Relay beacon (Relay objective) | fx3d `buildBeacon` | Hegemony materials on a cylinder base, mast, sphere core, 2 tori, zone torus, 3 pips | - | D / C- / C+ | Primitive. Readable as a marker, but not an object. |
| Graveyard wrecks | scene3d `buildTerrainFeatures` (meta.wrecks), `HOLE_BUILD.hulk` | Full ship build, split, wreck materials, merged per material | - | C- / C / B- | An intact silhouette lightly offset. Lit ports stay lit on concept hulls (bug L19). No burn or breach shading. |
| Debris terrain | `buildTerrainFeatures`, `debThinUpdate` | Thin-instanced SB box plates | - | D+ / C / B- | Boxes. |
| Dead star / gravity well | scene3d `buildDeadStar`; fx3d tints (`wellRim`, `wellPull`, `wellSling`) | Black sphere, emissive torus, accretion disc (512 canvas, additive) on a spin node, halo billboard; hex tints | - | C- / C / B- | No lensing. The disc is a flat textured plane. No Doppler or brightness variation. The well bands are plain line tints. |
| Ion storms | `buildTerrainFeatures` storm cards, `updateStorms` | 1-2 additive billboard cards per hex with `G.tex.neb`; lightning as 4-sided tubes | 1 card on phones | D+ / C- / C | Billboard tell (cards rotate with the camera). Lightning is thin tubes allocated per bolt. |
| Nebula hexes | `buildBattleEnv` neb cards | 2-3 additive billboards per hex with `G.tex.neb` (256²) | 2 on phones | D+ / C- / C | Billboard tells, low-res blob texture, no depth fade where cards cut through hulls. |
| Terrain and objective tints, blocked hexes | fx3d `tintHexes`, `refreshBlockTint` (E restyling) | LineSystem outline plus merged additive discs per type | - | - / C / B- (UI) | Aliased 1px lines. Many separate meshes. |
| Near planet (Planet edge maps) | scene3d `buildNearPlanet`, gfx3d `nearPlanetMaterial` | Procedural planet shader (relief on High and Ultra, oceans, 2 cloud decks, city lights, limb scattering), atmosphere shell; gas giant ring disc (512×8 texture) and 2 shader moons | 72 or 128 segments; 6 or 8 octaves | B- / B / B+ | Sphere tessellation visible at the limb up close. The ring is a flat disc, unshaded by the planet. |
| Backdrop planet | scene3d `makePlanet`, gfx3d `PLANET_GLSL` | The same shader on a far sphere, 8 looks, faction-picked | 4 or 6 octaves | B- / B / B | Good. |
| Sky | scene3d `makeSky` | Infinite sphere, domain-warped fbm ShaderMaterial, hashed star cells; re-tinted per faction biome | - | B- / B / B | Fine. It goes stale in reflections (L29). |
| Stars | scene3d `makeStars` | 5,200 point sprites | DPR-scaled size | B- / B / B | - |
| Sun, halo, lens flare, bright stars | scene3d `makeSunAndSky` | Billboards with flare texture; LensFlareSystem with 6 canvas textures; god rays on Ultra | VLS Ultra only | C+ / B- / B | The sun is a flat flare sprite with no corona motion. |
| Galaxy | `makeSunAndSky` | 512² canvas plane | - | C / C+ / B- | Low-res. |
| Nebula banks (sky) | `makeSunAndSky` plus gfx3d `nebulaMaterial` / `bakedNebulaMat` | 34 animated shader cards on desktop; 14 on phones, 6 baked 256² | - | C+ / B- / B | Billboard cards. |
| Dust | `buildBattleEnv` dust ParticleSystem | 700 soft additive particles | - | C / C+ / B | Fine. |
| Distant battle | vfx3d `ambientBattle` | Pooled sprites far off | Slower on phones | - / B- / B | Fine. |
| Distant traffic | scene3d `buildTraffic` | 3 full ship builds, desktop only | - | - / C+ / B | Costs 3 full builds (L19). |

### 3d. Board and UI 3D overlays

| Asset | Built in | Technique | Grade | Weakness |
|---|---|---|---|---|
| Hex grid and frame | scene3d `buildBattleEnv`, `gridFocus` | LineSystem with vertex alpha (1 px), frame LineSystem | C / B- / B | 1-pixel aliased lines that shimmer when the camera moves. Lit by vertex alpha only. |
| Board plate | `boardUnder` merged discs | Smoked glass, alpha | - / B- / B | Fine. |
| Side footprints, contact shadows | ui3d `boardMarks`, `fpRebuild`, `fpShadows` | Thin-instanced hex marks with vertex alpha; thin-instanced soft quads | - / B- / B | Good. |
| Hull gauge | fx3d `hullArcs` | One rebuilt mesh with vertex colours | - / B- / B | - |
| Selection and target rings, arc fans, reach outline, ram lane, aim tube, ghost, threat and inspect tiles, focus brackets | ui3d `refreshOverlays`, `refreshHover`, `tile`, `ringMesh`, `fanMesh`, `reachOutline`, `aimTube`, `focusRetMesh` | Instanced tiles; per-refresh tori, fans and tubes (materials disposed per refresh); ghost as a clone with a depth-prepass material | - / B- / B | `ringMesh` and `fanMesh` create a mesh and a material on every refresh (minor C item). Fine visually. |

---

## 4. Deliverable 3: gallery harness

`gallery.py` (committed on `v53-H`). A Playwright run, served over http so the concept hulls load. The page is seeded (`Math.random` replaced by mulberry32 in an init script, plus `rndSeed` for the rules) so the same `SEED` gives the same fleets, boards and set pieces. It injects a small in-page library `GAL` that does the following:
- snaps the camera (controller and camera together, so nothing eases between frames)
- builds a "studio": a normal battle whose ships are removed, with assets placed on clear hexes through `makeUnit` and `updateWorld`, so they get the real views: plumes, nav lights, rings, damage
- builds set pieces straight into the scene out past the rim (stations, derelict, hulk, giant asteroid, moonlet, comet, beacon, dead star), then removes them
- triggers effects through the game's own functions (`animWeapon`, `animExplode`, `fxShieldBreak`) and catches them at three zooms in quick succession
- generates five real battlefields (belt/dense, graveyard/deadstar, storm, planet, station/breakthrough) and frames the asteroids, rim, belt, dust, black hole, gravity well, wreck, debris, storm, nebula, cloud wall, near planet (plus a gas giant and an ice world rebuilt in place), station and objective zones

Output is `OUT/<group>_<asset>_<zoom>.png` with zooms `close`, `mid` and `board` at 1600x900, `phone_<faction>_mid.png` at 412x915 (phone quality), `index.html` (a contact sheet grouped by asset with a technique note per group; concept vs PROCEDURAL is flagged per ship, along with mesh, vertex and part counts and the WebGL renderer string so you can confirm the RTX was used), and `gallery.json`.

Groups: `ships` (29), `squad` (12), `engines` (6), `damage` (6), `fx_weapon` (about 14), `fx_shield` (7), `fx_death` (6 causes), `board` (1), `ui` (6), `setpiece` (10), `backdrop` (sky, 8 planet looks, nebula), `world` (16), `phone` (6). About 130 assets and about 390 images.

Environment variables: `OUT`, `ONLY` (name prefixes, e.g. `ONLY=ships_voidsworn,fx_death`), `ZOOMS`, `SEED`, `Q`, `PHONE=0`, `LIMIT`, `GPU=auto|1|0` (auto picks the real GPU on Windows and macOS, using Playwright's `chromium` channel, i.e. new headless, which keeps hardware acceleration, and falls back to a plain launch), `SCALE` (render-scale divisor for slow machines), `PAGEFILE`, `HEADLESS=0`. If index_test.html is missing it runs `build.py test`.

Run on the PC: `OUT=gallery python3 gallery.py`. Expected time on the RTX: about 10 s boot, plus 6 battle setups at about 2 s, plus about 390 screenshots at about 0.25 s with short settles, plus effect timings. That is roughly 2.5 to 3 minutes. `PHONE=0` saves about 20 s.

**Smoke test (sandbox, SwiftShader, under the lock):** `ONLY=ships_voidsworn_Frigate,ships_voidsworn_Carrier,setpiece_station_ring PHONE=0 SCALE=2`. Result: 9 images plus index.html and gallery.json, **0 errors**, 28/28 hulls loaded. It took 1,072 s here because the software renderer needs about 180 s to boot and about 70 s per 1600x900 screenshot; on the GPU expect seconds. Output is in `scratchpad/gal_smoke/`. The frames already show the audit's findings: the concept frigate close-up has the scattered orange v48 port quads (L2); the procedural Reliquary carrier is clearly kitbash next to it (grade D+, F2); the ring station is faceted tubes with a box mast (D+, F4). The phone pass, effects, world and UI groups were not run here (each world or effect step is minutes on SwiftShader). Their JS was syntax-checked and goes through the same helpers, but **the first full run should be on the PC**; any step that fails is logged in index.html and the run carries on.

---

## 5. Deliverable 4: plan

### 5a. Cleanup sequence

Order of operations: anything with no owner goes now, in files nobody else is editing. Ship-file cleanups wait for G. Effects and scene cleanups wait for C. Rocks wait for E. Each step is one commit with rulecheck, fuzz 20 and a gallery diff (`ONLY=` the touched groups) before and after.

**Now (no collision):**
1. N1. Delete the 30 unreferenced hull files and the stale `hulls/index.json` (L38). Saves 9.2 MB per publish. Zero code.
2. N2. Remove the title 2D canvas loop and the `drawShipShape` stub (L35; campaign_meta.js, campaign3d.js). Leave the `.title canvas` CSS for later (E edits head.html).
3. N3. Remove `runDemo`/`PREVIEW_DEMO` from campaign3d.js (L36). The build.py preview mode goes after C merges (C edited build.py).
4. N4. Remove `hexTex`, `ripple` and the `quality==='low'` branches (L22, L25). These are small hunks in fx3d and vfx3d; C touches other lines of fx3d, so coordinate or fold this into C.

**After G merges (ships3d, gfx3d, vfx3d turrets and nav):**
1. G1. Remove the concept-hull toggle (L5), the v48 ports and turret height map (L2, L3: G is already removing them), and the dead `loftMesh`, `SB.ring`/`anim`, `flashers`, `buildGeneric`, `M.paint` and old plume material (L9 to L14).
2. G2. **Anchors-only build for concept classes (L1, L6).** Add `SB.lite`. `buildShipModelFresh` passes `lite` when `AI_HULL_DATA[k]` exists. `push` returns a placeholder with position, rotation, scaling and q (callers mutate it). `part`, `greeble`, `add`, `slab`, `loftVD` and `bake` skip geometry. `loft` still records `stations` and `prof`. `finish` makes root, fore and aft, keeps plumes and flares, and skips emblems and merging. Measured with the prototype: about 98% less build time for concept classes (18.8 s to 0.3 s on the loaded sandbox; in the browser that would be about 3.3 s of 3.5 s saved per full set), anchors identical, and no 2 M-vertex churn per battle start. `applyAIHull` must set `p.H` from the mesh bounds. Verify with `shipcost.js` (anchor lists must be identical: diff `guns`, `hard`, `nav`, `bays`, `stacks`, `arcs`, `surf`) and the gallery `ships` group.
3. G3. Seat or remove decals, fires, sparks and hit points on concept hulls (L16, L17): sample from a cached vertex list per prototype.
4. G4. Wrecks from concept meshes with the damage shader at full and no ports; traffic from the merged prototype (L19).
5. G5. Later, once the last two hulls have meshes (section 5b, F2): bake the anchors into the hull JSON (an offline pass running the same `seatOnHull`), then delete the procedural ship builders (about 280 lines, 29 KB) and `addTurrets`. Keep `buildCraft`, the station kit and `partLib`.

**After C merges (fx3d, scene3d, perf3d):**
1. C1. Delete the sprite-pool fallbacks and the beam texture path (L20, L21), and `G.tex.ring`.
2. C2. Merge the duplicate faction-material animation (L24).
3. C3. Pool the remaining per-call allocations (L23): streak cell in the atlas, a `fireballFx` pool, a `beam` pool, a `warpRift` pool, pooled torpedoes, arc and lightning streak sprites, and fires and stack smoke through `fxp`. Then drop `fireSheet` (L26). This is the main remaining hitch source in combat.
4. C4. Desktop skips the phone cloud textures (L28). Refresh the env probe per battle (L29).
5. C5. One performance panel (L33). Remove build.py's preview mode (L36).

**After E merges (scene3d rocks and rim):**
1. E1. Drop the old rock base sets if E has not already. Replace `lumpyRock` in set pieces (giant asteroid, comet, chunks) with `mkFacet` shapes (L30).

**F (sound):** once clips land, the synth voices in `SFX` that F's graph no longer calls should go with it (F's call).

### 5b. Fidelity pass, biggest visual wins first

| # | Asset group | Gap today | Technique to reach high quality | Effort and pipeline | Win |
|---|---|---|---|---|---|
| F1 | **All concept hulls (27)** | Soft geometry, box-projected generic panels, no normal map, ports in shader | **Per-hull bake** on the owner's PC: keep the raw Hunyuan high-poly; decimate to 20-38k (desktop) and 12-16k (phone); UV unwrap (xatlas, or Blender Smart UV); bake from high to low a **normal map** (2048 desktop, 1024 phone) plus **AO, curvature and cavity** packed into one RGB texture, extending scripts/bao.py's BVH ray caster from per-vertex to texel; **albedo from Hunyuan3D-2.1 Paint** (multiview texture synthesis from the same FLUX concept) or, for a uniform faction look, a per-faction **trim and plating material** driven by the UVs plus curvature (edge wear) and cavity (grime) in HullFxPlugin; an **emissive mask** for windows projected from the concept image (replacing G's procedural ports where it reads better). Ship as WebP (or KTX2 later). Weighted normals and hard-edge splits in Blender fix the "melted bevel" look before baking (v55 already lists the per-hull Blender pass). | Script once (Blender CLI plus xatlas), about 2-4 min per hull on the 5080, about 1.5 h for all. About 0.6-1.2 MB per hull desktop. Runtime work: `decodeAIHull` reads real UVs and the material takes 3 textures. | **Largest.** It lifts every ship close-up from C- to B or B+. |
| F2 | Missing and weak meshes | Voidsworn Carrier (Reliquary) and Corsair Battle-barge boss are procedural; Deathless frigate D9 is the plaque; Ithar sails (E testing cards) | FLUX, then Hunyuan, then the F1 bake: Reliquary (enclosed hangars, per the owner's H1a/H2a note), Corsair boss barge, Deathless frigate remesh, Ithar hull cores with sails in engine (v55 plan) | 4 hulls, about 1 h | Removes the last out-of-family ships. Unblocks G5 deletion. |
| F3 | Explosions, fire, smoke | Procedural soft-blob sprites, displaced-sphere fireball | **Flipbooks**: render 3 or 4 volumetric sequences in Blender (Mantaflow fire and smoke: fireball, smoke puff, spark burst, plasma pop) to 8×8 atlases (2048, WebP, about 300 KB each). These are owned outright (no licence question). Feed the existing sprite pool (one more SpriteManager, `cellIndex` animation). Keep the shader fireball only for capital reactors. Add cut-face caps (dark, emissive edge) to `fragmentHull` sections. | Bake: an evening. Code: about 60 lines (C3 pooling makes it simple). | Big. Deaths are the game's hero moments. |
| F4 | Stations, relay beacon, derelicts, transports | Primitive kitbash | Concept meshes via FLUX and Hunyuan: ring hub, mining rig, derelict spire, relay beacon, freighter or transport. F1 bake. Keep emissive masks for lights. Pivot and anchor sidecars for batteries (Hold the station). | 5 meshes, about 1.5 h | Big on station maps and defend missions. Visible every Relay battle. |
| F5 | Asteroids and rocks (after E) | 256² canvas texture | **Triplanar CC0 rock material**: ambientCG Rock 1K sets (colour, normal, roughness; CC0) blended with E's cavity vertex colour; biome tints; the same for hole asteroids and the comet nucleus. Optional: 3-4 Hunyuan hero asteroids for set pieces. | About 1 day code; textures about 1.5 MB WebP total | Medium-big: rocks are on most boards. |
| F6 | Board grid and tints | 1 px LineSystem, many tint meshes | One **analytic hex-grid shader plane**: anti-aliased lines from the hex distance field, a holo glow, focus falloff, and a small data texture per hex (terrain, zone, reach, threat) replacing `tintHexes` discs and most tiles | About 1 day | Crisp board at every zoom; fewer meshes and draws. |
| F7 | Wrecks and hulks | Intact silhouettes, flat dark material, glowing ports | Concept mesh with HullFx `dmg=1` (burned albedo, dim cracks), pre-fragmented with `fragmentHull persist`, capped cut faces, slow ember flicker; graveyard set dressing reuses it | About half a day after G4 | Medium. |
| F8 | Dead star / black hole | Flat disc and torus | Screen-space **gravitational lensing** post-process around the core's projected position (radial UV warp plus Einstein ring); animated accretion disc shader (fbm swirl, Doppler brightening on the approaching side, inner hot edge); photon ring as a thin shader ring; a faint jet | About 1 day | High "wow" per minute spent. |
| F9 | Nebula hexes, storms, cloud walls | Additive billboard cards with a 256 blob texture | Fewer, larger cards using the existing `nebulaMaterial` noise shader with a **depth fade** (soft-particle style: the depth renderer is already there via SSAO) and fade when edge-on or near the camera; world-locked rotation, not billboard spin. Lightning as `beamMaterial` strips plus a flash light. | About 1 day | Medium. Removes the billboard tells. |
| F10 | Lighting and reflections | Stale probe (L29), flat sun | Refresh the probe per battle (cheap); sun corona shader; v55's 4:1 key and rim lighting; consider an HDR CC0 space environment for specular (Poly Haven has no space HDRIs, so generate one from the sky shader at 1024 once per battle) | Small | Small to medium, applies everywhere. |
| F11 | Weapons | Capsule bolts, thin beams, cone torpedoes | Bolts as pooled stretched sprites (core plus glow) with a short trail; thicker beams with end flares (v55); torpedoes with a small modelled body (shared instanced mesh) and pooled trails | About 1 day | Medium. Volleys are on screen constantly. |
| F12 | Squadrons | Boxes (G rebuilding procedural craft) | G's lofted craft first. If still weak close up, 6 tiny Hunyuan craft (they read at board zoom only). | G | Small to medium. |
| F13 | Planets, sky, galaxy | Good already | Higher near-planet tessellation at the limb; ring shader with planet shadow and noise bands; galaxy at 2048 or as a shader | Small | Small. |

Suggested release slicing: v54 is factions and rewards, so fidelity goes into v55 "spectacle". Recommended v55 order: F1 and F2 (ship bakes; the owner's PC pipeline is already proven), F3 flipbooks plus C3 pooling, F4 stations, F6 board shader, F5 rocks, then F7 to F11. The gallery doubles as the before/after record: run it on the PC before each step and diff the contact sheets.
