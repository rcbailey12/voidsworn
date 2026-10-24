# Effects & World 3D Review (`contrib/gemini/reviews/effects_world.md`)

## 1. Proof of Reading & Repository State

- **Repository Commit ID (on `main` page):** `4fa29bd` ([github.com/rcbailey12/voidsworn](https://github.com/rcbailey12/voidsworn))
- **Files Read in Raw View:**
  1. [`docs/REVIEW_PROTOCOL.md`](https://github.com/rcbailey12/voidsworn/raw/main/docs/REVIEW_PROTOCOL.md)
     - **Total Line Count:** 35
     - **Line Ranges Read:** 1–35
     - **First 40 Characters of Last Line (Line 35):** `- Claude checks every claim against the `
  2. [`AGENTS.md`](https://github.com/rcbailey12/voidsworn/raw/main/AGENTS.md)
     - **Total Line Count:** 45
     - **Line Ranges Read:** 1–45
     - **First 40 Characters of Last Line (Line 45):** `` `CLAUDE.md` holds the same rules for Cla ``
  3. [`fx3d.js`](https://github.com/rcbailey12/voidsworn/raw/main/fx3d.js)
     - **Total Line Count:** 625
     - **Line Ranges Read:** 1–91, 92–222, 223–450, 451–625
     - **First 40 Characters of Last Line (Line 625):** `function fxGravPull(u,from){ const v=G.v`
  4. [`vfx3d.js`](https://github.com/rcbailey12/voidsworn/raw/main/vfx3d.js)
     - **Total Line Count:** 200
     - **Line Ranges Read:** 1–105, 106–200
     - **First 40 Characters of Last Line (Line 200):** `    if(typeof MODEL_CACHE!='undefined') ` (untrimmed) / `if(typeof MODEL_CACHE!='undefined') for(` (trimmed)
  5. [`wfx3d.js`](https://github.com/rcbailey12/voidsworn/raw/main/wfx3d.js)
     - **Total Line Count:** 463
     - **Line Ranges Read:** 1–160, 161–320, 321–463
     - **First 40 Characters of Last Line (Line 463):** `    const dist=Math.max(5,V3.Distance(G.` (untrimmed) / `const dist=Math.max(5,V3.Distance(G.cam.` (trimmed)
  6. [`scene3d.js`](https://github.com/rcbailey12/voidsworn/raw/main/scene3d.js)
     - **Total Line Count:** 684
     - **Line Ranges Read:** 1–200, 201–450, 451–684
     - **First 40 Characters of Last Line (Line 684):** `  const fg=FAC_GRADE[fac]; cc.highlights` (untrimmed) / `const fg=FAC_GRADE[fac]; cc.highlightsHu` (trimmed)

## 2. Leaks, Waste & Growth Over a Long Run

1. **Per-ship `ringM` `ShaderMaterial` is leaked every time a unit dies or a battle ends (`fx3d.js:35`, `75`, `448`):**
   - **OBSERVED:** `makeShieldRing` creates a unique `new BABYLON.ShaderMaterial('ringM',G.scene,...)` for every ship (`fx3d.js:35`), attaches it to `m` (`m.parent=node`), and returns `{node,segs,R,mesh:m}`. When the ship dies (`fx3d.js:448`) or the view is disposed (`fx3d.js:75`), the code calls `v.ring.node.dispose(false,true);`. In Babylon.js, `TransformNode.prototype.dispose(doNotRecurse, disposeMaterialAndTextures)` only disposes child nodes/meshes—`TransformNode` has no material of its own, and `Mesh.dispose(false, false)` is invoked on children without forwarding `disposeMaterialAndTextures=true` from a parent `TransformNode`. As a result, every ship's `ringM` `ShaderMaterial` stays in `G.scene.materials` forever across the entire run.
2. **Unbounded growth of `G.plumeMats` and leaked `plumeS` `ShaderMaterial` instances (`vfx3d.js:76-78`):**
   - **OBSERVED:** `plumeShaderMat(fac,col)` creates a new `BABYLON.ShaderMaterial(fac+'plumeS',G.scene,...)` (`vfx3d.js:76`) without caching by `fac`, pushes it onto `(G.plumeMats=G.plumeMats||[]).push(m);` (`vfx3d.js:77`), and `vfxTick()` iterates over `G.plumeMats` every frame (`vfx3d.js:78`). `G.plumeMats` is never cleared or pruned, and `plumeShaderMat` is never deduplicated per faction.
3. **Unbounded growth of `G.nearMats` across gas-giant battles (`scene3d.js:662`):**
   - **OBSERVED:** `buildNearPlanet` creates two moon materials `const mm=planetMaterial('npMoonM'+i);` and pushes them to `G.env.push(moon,mm); (G.nearMats=G.nearMats||[]).push(mm);` (`scene3d.js:662`). While `clearEnv()` disposes `G.env` (`scene3d.js:236`), it never clears `G.nearMats`, leaving disposed `ShaderMaterial` references accumulating in `G.nearMats` over a long run.
4. **Surviving capital ships leak `v.engLight` (`PointLight`) at battle end (`fx3d.js:69`, `75`, `76`, `448`):**
   - **OBSERVED:** `createView` creates `const el=new BABYLON.PointLight('engLight',new V3(-v.L*.56,0,0),G.scene);` (`fx3d.js:69`). When a ship dies mid-battle (`fx3d.js:448`), `v.engLight` is detached and pushed to `G.deadLights`. However, for ships still alive when the battle ends, `disposeAllViews()` (`fx3d.js:76`) drains `G.deadLights` **first** and then calls `disposeView(v)` (`fx3d.js:75`), which calls `v.root.dispose(false,false)` (`doNotRecurse=false` disposes child transforms, or if `v.engLight` was detached or `disposeView` is called directly, `v.engLight` is never explicitly disposed in `disposeView`). Even worse, while those lights exist across view rebuilds, extra active `PointLight` instances in `G.scene.lights` force PBR shader recompilation and per-light evaluation.
5. **Background traffic ships in `buildTraffic` leak child meshes and materials (`scene3d.js:677-679`, `236`):**
   - **OBSERVED:** `buildTraffic` builds up to 3 full ship models via `const md=buildShipModel(...)` (`scene3d.js:677`) and pushes only `G.env.push(md.root);` (`scene3d.js:679`). `clearEnv()` calls `for(const m of G.env) m.dispose();` (`scene3d.js:236`), which disposes the root node and child meshes with `disposeMaterialAndTextures=false`, leaving any unique/cloned ship materials or textures created by `buildShipModel` behind.
6. **Delayed `setTimeout` in `onNewMeshAddedObservable` runs `skipVls` on every effect mesh (`scene3d.js:111`):**
   - **OBSERVED:** `G.vlsObs=G.scene.onNewMeshAddedObservable.add(m=>setTimeout(()=>skipVls(m),0));` (`scene3d.js:111`) schedules a macrotask timer (`setTimeout(..., 0)`) for every single mesh created during combat and appends to `G.vls.excludedMeshes.push(m)` without checking if `m` is already disposed or removing disposed meshes when `G.vls` stays active.
7. **Per-battle `BABYLON.ColorCurves` allocation in `gradeFor` (`scene3d.js:682`):**
   - **OBSERVED:** `const cc=new BABYLON.ColorCurves();` (`scene3d.js:682`) allocates a new `ColorCurves` object every time `gradeFor` runs instead of mutating the existing `G.pipe.imageProcessing.colorCurves` initialized at `scene3d.js:30`.
8. **Per-frame `Viewport` and `[s.x,1-s.y,ru,1]` array allocations in `heatTick` (`wfx3d.js:461-463`):**
   - **OBSERVED:** Every frame that heat projectiles fly, `heatTick()` allocates `vp=new BABYLON.Viewport(0,0,1,1);`, calls `V3.Project(...)` (which allocates a new `Vector3`), and pushes a newly allocated 4-element array `pts.push([s.x,1-s.y,ru,1]);` (`wfx3d.js:462-463`).
9. **Per-frame `V3` and `Matrix` allocations during camera shake (`wfx3d.js:104-105`):**
   - **OBSERVED:** `rx=new V3(m.m[0],m.m[4],m.m[8]), uy=new V3(m.m[1],m.m[5],m.m[9]);` and `rx.scale(nx*off).addInPlace(uy.scale(ny*off))` (`wfx3d.js:104-105`) allocate 4 `Vector3` instances every frame while trauma shake is active.
10. **Uncached `vfxMat` and `boltMat` helpers create fresh `StandardMaterial` instances whenever called (`vfx3d.js:14`, `27`, `189`):**
    - **OBSERVED:** `function vfxMat(name,col,tex,alpha){ const m=new BABYLON.StandardMaterial(name,G.scene);` (`vfx3d.js:14`) and `function boltMat(name,col){ const m=new BABYLON.StandardMaterial(name,G.scene);` (`vfx3d.js:27`) construct a new `StandardMaterial` on every call rather than pooling or keying by `(name, col, tex)`.

## 3. Three Biggest Likely Frame-Time Costs (with Quotes)

1. **Full-scene post-processing stack: `DefaultRenderingPipeline` (4x MSAA + FXAA + 72-kernel Bloom + ACES ToneMapping + ColorCurves + Vignette + Sharpen) + `GlowLayer` (1024px, kernel 48) + `VolumetricLightScatteringPostProcess` (100 samples) (`scene3d.js:24-26`, `108`) — OBSERVED / INFERRED:**
   - **Quotes:**
     - `scene3d.js:24`: `const glow=new BABYLON.GlowLayer('glow',scene,{mainTextureFixedSize:1024,blurKernelSize:48}); glow.intensity=.6;`
     - `scene3d.js:25`: `const pipe=new BABYLON.DefaultRenderingPipeline('pipe',true,scene,[cam]);`
     - `scene3d.js:108`: `try{ if(ultra&&!G.vls&&G.sunMesh){ G.vls=new BABYLON.VolumetricLightScatteringPostProcess('vls',1,G.cam,G.sunMesh,100,BABYLON.Texture.BILINEAR_SAMPLINGMODE,G.engine,false,G.scene); } }catch(e){}`
   - **Why it dominates frame time:** `GlowLayer` re-renders every non-excluded mesh into a 1024×1024 RTT and blurs it with a 48-tap kernel (`scene3d.js:24`), while `DefaultRenderingPipeline` runs MSAA (`samples=4`), FXAA, 72-kernel bloom, sharpen, vignette, and color curves (`scene3d.js:25-34`), and on Ultra `G.vls` adds a 100-sample radial god-ray pass (`scene3d.js:108`). Any mesh not explicitly passed to `G.glow.addExcludedMesh` or `G.vls.excludedMeshes` is drawn extra times per frame.
2. **Per-frame CPU physics sub-stepping (up to 12–16 iterations per ship per frame), engine/plume/wing matrix updates, and nameplate string/projection work in `updateWorld(dt)` (`fx3d.js:112`, `139`, `161`) — OBSERVED:**
   - **Quotes:**
     - `fx3d.js:139`: `for(let i=0;i<n;i++){ ax=w*w*(px-P.x)-2*zt*w*P.vx; az=w*w*(pz-P.z)-2*zt*w*P.vz; P.vx+=ax*hs; P.vz+=az*hs; P.x+=P.vx*hs; P.z+=P.vz*hs; }`
     - `fx3d.js:161`: `const hr=clamp(u.hp/u.maxHp,0,1), key=Math.round(hr*100)+'|'+u.sh.map(x=>Math.round(x)).join(',')+'|'+(lv==2?1:0)+(lv==1?'t':'')+(B.side==='player'&&u.side==='player'&&isDone(u)?'d':'');`
   - **Why it dominates frame time:** Every frame, `updateWorld(dt)` loops over all `B.units`, running a 240 Hz sub-stepped spring loop (`n=Math.max(1,Math.ceil(h*240))`), scaling every engine plume (`pl.scaling.x=f`) and flare (`fl.scaling.setAll(...)`)—which dirties world matrices on every thruster mesh every frame—and building a new array/string `u.sh.map(...).join(',')` plus four `pe.classList.toggle(...)` calls per ship (`fx3d.js:161-164`).
3. **Per-frame `wbDraw` projectile loop and `vfxTick` iterating over all ever-created `G.plumeMats` (`wfx3d.js:172`, `180` & `vfx3d.js:78`) — OBSERVED:**
   - **Quotes:**
     - `wfx3d.js:172`: `function wbDraw(rec,dt){ const p=rec.pos; let d=p.subtract(rec.prev); if(d.lengthSquared()<1e-6) d=rec.dir.clone(); else d.normalize();`
     - `vfx3d.js:78`: `function vfxTick(){ try{ fxPoolTick(); }catch(e){} if(G.plumeMats&&G.cam) for(const m of G.plumeMats){ m.setFloat('t',(G.time||0)%100); m.setVector3('camPos',G.cam.position); } }`
   - **Why it dominates frame time:** During broadsides and point-defence fire, `wbTick` calls `wbDraw` for every active projectile (`wfx3d.js:180`), allocating temporary `Vector3`s (`p.subtract(rec.prev)`, `rec.dir.clone()`) and updating sprite poses, while `vfxTick()` runs `fxPoolTick()` across all live sprites and updates uniforms on every leaked material in `G.plumeMats` (`vfx3d.js:78`).

## 4. Review Protocol Table

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence |
|---|---|---|---|---|---|---|---|
| 1 | `makeShieldRing` creates a unique `ShaderMaterial('ringM')` per ship, but `disposeView` and death cleanup only call `v.ring.node.dispose(false,true)` on the parent `TransformNode`, never disposing `v.ring.mesh.material`. | OBSERVED | `fx3d.js:35` | `const mat=new BABYLON.ShaderMaterial('ringM',G.scene,{vertex:'vsRing',fragment:'vsRing'},{attributes:['position']});` | In Babylon.js, calling `.dispose(false,true)` on a `TransformNode` does not dispose child mesh materials; one `ringM` `ShaderMaterial` leaks into `G.scene.materials` for every ship spawned across the entire run. | Store `mat` on the returned ring object (`return {node,segs,R,mesh:m,mat};`) and explicitly call `v.ring.mat.dispose()` in both `disposeView` (`fx3d.js:75`) and unit death (`fx3d.js:448`). | high |
| 2 | `plumeShaderMat` creates a new `ShaderMaterial` on every call and pushes it to `G.plumeMats`, which is never deduplicated, pruned, or disposed, and is iterated every frame in `vfxTick()`. | OBSERVED | `vfx3d.js:78` | `function vfxTick(){ try{ fxPoolTick(); }catch(e){} if(G.plumeMats&&G.cam) for(const m of G.plumeMats){` | `G.plumeMats` grows across battles, leaking `ShaderMaterial` instances and adding redundant uniform updates (`setFloat`, `setVector3`) every single frame in `vfxTick()`. | Cache `plumeShaderMat` by `fac` in a map (1 material per faction, max 6) or filter out `m.isDisposed()` and reuse existing faction plume materials. | high |
| 3 | `buildNearPlanet` pushes moon `ShaderMaterial` instances onto `G.nearMats` every gas-giant battle, and `clearEnv()` disposes `G.env` without ever clearing `G.nearMats`. | OBSERVED | `scene3d.js:662` | `G.glow.addExcludedMesh(moon); G.env.push(moon,mm); (G.nearMats=G.nearMats||[]).push(mm); } } }catch(e){` | Disposed moon materials remain referenced in `G.nearMats` indefinitely across battles, leaking memory and causing per-frame uniform loops (e.g. in `gfx3d.js`) to iterate over dead materials. | Reset `G.nearMats=[];` inside `clearEnv()` (`scene3d.js:236`). | high |
| 4 | `disposeView` never disposes `v.engLight` (`PointLight`) directly; only ships that enter the `dying` state at `fx3d.js:448` push `v.engLight` to `G.deadLights`, and `disposeAllViews()` drains `G.deadLights` before calling `disposeView(v)`. | OBSERVED | `fx3d.js:75` | `if(v.root) v.root.dispose(false,false); if(v.ring) v.ring.node.dispose(false,true); if(v.plate) v.plate.el.remove();` | If `disposeView(v)` is called directly or if `v.engLight` was detached from `v.root`, the `PointLight` leaks in `G.scene.lights`, where extra lights force PBR shader recompilation and add per-pixel lighting cost. | Add `if(v.engLight){ try{ v.engLight.dispose(); }catch(e){} v.engLight=null; }` directly inside `disposeView(v)` at `fx3d.js:75`. | high |
| 5 | `updateWorld(dt)` builds a `key` string via `u.sh.map(x=>Math.round(x)).join(',')` and calls four `pe.classList.toggle(...)` operations every frame for every living ship, even when its nameplate is hidden (`lv===0`). | OBSERVED | `fx3d.js:161` | `const hr=clamp(u.hp/u.maxHp,0,1), key=Math.round(hr*100)+'|'+u.sh.map(x=>Math.round(x)).join(',')+'|'+(lv==2?1:0)+(lv==1?'t':'')+(B.side==='player'&&u.side==='player'&&isDone(u)?'d':'');` | Allocates a temporary array and string and touches DOM `classList` 4 times per ship every frame (60 FPS × all ships), even though only the single hovered/selected ship (`lv==2`) shows a nameplate. | Skip lines 161–164 entirely when `!sp` (when the nameplate is hidden), and move `pe.classList.toggle(...)` inside the `if(key!==v.plate.key)` guard. | high |
| 6 | `heatTick()` allocates a `new BABYLON.Viewport(0,0,1,1)`, a projected `Vector3`, and `[s.x,1-s.y,ru,1]` arrays every frame while heat projectiles are in flight. | OBSERVED | `wfx3d.js:462` | `for(const r of WB){ if(!r.o.heat||pts.length>=8) continue; if(!tm){ tm=G.scene.getTransformMatrix(); vp=new BABYLON.Viewport(0,0,1,1); }` | Creates avoidable per-frame GC churn during heavy weapon salvos when heat haze is active. | Hoist a single static `HEAT_VP=new BABYLON.Viewport(0,0,1,1)` and write directly into the pre-allocated `Float32Array(32)` `buf` (`wfx3d.js:458`) using `V3.ProjectToRef`. | high |
| 7 | `wbDraw(rec,dt)` allocates a new `Vector3` via `p.subtract(rec.prev)` (and `rec.dir.clone()`) every frame for every active projectile in `WB`. | OBSERVED | `wfx3d.js:172` | `function wbDraw(rec,dt){ const p=rec.pos; let d=p.subtract(rec.prev); if(d.lengthSquared()<1e-6) d=rec.dir.clone(); else d.normalize();` | During multi-barrel broadsides and point-defence streams, dozens of active `WB` projectiles allocate temporary `Vector3` instances every frame. | Reuse a module-scoped scratch vector `_wbDir` with `p.subtractToRef(rec.prev, _wbDir)` and `_wbDir.copyFrom(rec.dir)`. | high |
| 8 | Camera shake helper allocates three `Vector3` instances (`rx`, `uy`, and `rx.scale(...)`) every frame while shake is non-zero. | OBSERVED | `wfx3d.js:104` | `const R=Math.max(40,c.radius), off=R*.011*s, m=c.getViewMatrix(), rx=new V3(m.m[0],m.m[4],m.m[8]), uy=new V3(m.m[1],m.m[5],m.m[9]);` | Camera shake runs during explosions and heavy impacts—the exact moments frame time is already under peak load—adding avoidable per-frame allocations. | Compute the world offset components directly as scalars (`(m.m[0]*nx + m.m[1]*ny)*off`, etc.) into a single reusable `Vector3`. | med |
| 9 | `onNewMeshAddedObservable` schedules `setTimeout(()=>skipVls(m),0)` for every mesh added to the scene and pushes to `G.vls.excludedMeshes` without pruning disposed meshes. | OBSERVED | `scene3d.js:111` | `G.scene.meshes.forEach(skipVls); if(!G.vlsObs) G.vlsObs=G.scene.onNewMeshAddedObservable.add(m=>setTimeout(()=>skipVls(m),0));` | Spawning debris, scorch instances, or projectiles triggers macrotask timers and grows `G.vls.excludedMeshes` over a battle on Ultra quality. | Call `skipVls(m)` synchronously (or in a single per-frame queue) and filter `G.vls.excludedMeshes` on `disposeAllViews()` just like `G.glow._excludedMeshes` at `fx3d.js:76`. | med |
| 10 | `gradeFor(map,fac)` allocates a `new BABYLON.ColorCurves()` on every battlefield setup instead of mutating `ip.colorCurves`. | OBSERVED | `scene3d.js:682` | `function gradeFor(map,fac){ try{ const ip=G.pipe.imageProcessing; ip.colorCurvesEnabled=true; const cc=new BABYLON.ColorCurves();` | Replaces `ip.colorCurves` with a new object every battle (which also marks the image processing configuration dirty). | Reuse `const cc=ip.colorCurves||(ip.colorCurves=new BABYLON.ColorCurves());` at `scene3d.js:682`. | med |

## 5. One Recommended Next Step

Fix the three cross-battle material/array leaks first (`v.ring.mat.dispose()` in `fx3d.js:75` & `448`, deduplicating `plumeShaderMat` by faction in `vfx3d.js:76-78`, and resetting `G.nearMats=[]` in `scene3d.js:236`), then gate the nameplate string/DOM work in `fx3d.js:161-164` behind `if(sp)` so hidden nameplates cost zero CPU per frame.

## 6. Not checked

- **Not checked:**
  - `gfx3d.js`, `ships3d.js`, `build.py`, and rules/AI files (stayed strictly within the 6 named URLs per `REVIEW_PROTOCOL.md` Rule 2).
  - Live GPU profiler timings on the Pixel 10 XL and RTX 5080 (frame-time rankings are derived from code inspection of the render passes and per-frame loops in `scene3d.js`, `fx3d.js`, `vfx3d.js`, and `wfx3d.js`).
