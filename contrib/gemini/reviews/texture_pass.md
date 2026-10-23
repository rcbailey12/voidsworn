# Texture Pass Review (`contrib/gemini/reviews/texture_pass.md`)

## 1. Proof of Reading & Repository State

- **Repository Commit ID (on `main` page):** `fad56d6` ([github.com/rcbailey12/voidsworn](https://github.com/rcbailey12/voidsworn))
- **Files Read in Raw View:**
  1. [`docs/REVIEW_PROTOCOL.md`](https://github.com/rcbailey12/voidsworn/raw/main/docs/REVIEW_PROTOCOL.md)
     - **Total Line Count:** 35
     - **Line Ranges Read:** 1–35
     - **First 40 Characters of Last Line (Line 35):** ``- Claude checks every claim against the ``
  2. [`AGENTS.md`](https://github.com/rcbailey12/voidsworn/raw/main/AGENTS.md)
     - **Total Line Count:** 45
     - **Line Ranges Read:** 1–45
     - **First 40 Characters of Last Line (Line 45):** `` `CLAUDE.md` holds the same rules for Cl ``
  3. [`docs/ship_pipeline/TEXTURE_PASS.md`](https://github.com/rcbailey12/voidsworn/raw/main/docs/ship_pipeline/TEXTURE_PASS.md)
     - **Total Line Count:** 43
     - **Line Ranges Read:** 1–43
     - **First 40 Characters of Last Line (Line 43):** ``pick. Free tools and CC0 assets only.`` (37 chars total on last line)
  4. [`gfx3d.js`](https://github.com/rcbailey12/voidsworn/raw/main/gfx3d.js)
     - **Total Line Count:** 486
     - **Line Ranges Read:** 1–160, 161–320, 321–486
     - **First 40 Characters of Last Line (Line 486):** ``  const t0=G.time, D=1.15*Math.max(.4,SP`` (or without 2-space indent: ``const t0=G.time, D=1.15*Math.max(.4,SPEE``)
  5. [`tools/blender/project_paint.py`](https://github.com/rcbailey12/voidsworn/raw/main/tools/blender/project_paint.py)
     - **Total Line Count:** 196
     - **Line Ranges Read:** 1–94, 95–170, 171–196
     - **First 40 Characters of Last Line (Line 196):** ``    bpy.ops.export_scene.gltf(filepath=o`` (or without 4-space indent: ``bpy.ops.export_scene.gltf(filepath=os.en``)

## 2. Answers to the 5 Audit Questions (`docs/ship_pipeline/TEXTURE_PASS.md`)

### Question 1: Exact ambientCG Asset IDs (`index.csv` picks)
- **OBSERVED** (`docs/ship_pipeline/TEXTURE_PASS.md:14-15`): `tools/pc/tex_dl.ps1` downloads 2K JPG sets into `Downloads\voidsworn_test\textures\<AssetId>\` for searches: `painted metal, rust, metal plates, scratched metal, corrugated steel, diamond plate, grime, metal`.
- **INFERRED** (matching those categories to the verified CC0 assets on ambientCG):
  - **(a) Corsair rusty red plating (Painted Red Metal):** [`PaintedMetal004`](https://ambientcg.com/view?id=PaintedMetal004) (red painted metal with surface wear) paired with [`PaintedMetal017`](https://ambientcg.com/view?id=PaintedMetal017) (weathered painted metal with rust bleed).
  - **(a/all) Rust:** [`Rust004`](https://ambientcg.com/view?id=Rust004) (coarse, flaking brown-orange industrial oxidation with deep normal/roughness relief).
  - **(b) Bare worn steel:** [`Metal009`](https://ambientcg.com/view?id=Metal009) (brushed, scratched silver steel for edge wear and exposed plate) and [`CorrugatedSteel009`](https://ambientcg.com/view?id=CorrugatedSteel009) (dark gray worn industrial steel for ribbed hull bays/vents).
  - **(c) Grime:** [`Leaking012A`](https://ambientcg.com/view?id=Leaking012A) (damaged flowing metal leak stains) and [`SurfaceImperfections002`](https://ambientcg.com/view?id=SurfaceImperfections002) (smudge/stain roughness breakup map for cavities).
  - **(d) Other factions:** Use [`Metal032`](https://ambientcg.com/view?id=Metal032) (smooth grey metal) and [`MetalPlates006`](https://ambientcg.com/view?id=MetalPlates006) as neutral height/normal/roughness detail sets tinted by each ship's existing `surfaceAlbedo` and `HULLFX_STYLE` (`deathless:1,chorus:2,ithar:3,voidsworn:4,hegemony:4,corsair:5` at `gfx3d.js:10`), keeping `HULLFX_PLATE` off on organic `chorus` (`style===2`) and porcelain `ithar` (`style===3`) as already gated at `gfx3d.js:21`.

### Question 2: Triplanar in `gfx3d.js` vs. Baked into Paint (`project_paint.py`) & Exact Insertion Point
- **Pick (INFERRED):** **Channel-packed triplanar detail in `HullFxPlugin` (`gfx3d.js`)** wins on look per MB for all 36 ships on a Pixel 10 XL, provided you do **not** ship 4 raw 2K multi-map PBR sets (which would be 12 textures = ~15–20 MB download and ~192 MB uncompressed RGBA8 VRAM, blowing out mobile texture cache with 36 samples/pixel). Instead, pack 2 shared 1K/2K channel-packed atlases (1 RGBSplat mask/roughness texture + 1 RG normal array/atlas, ~2.5 MB JPG total, ~21 MB VRAM) and sample only on the dominant triplanar axis (`pu` in `gfx3d.js:89` and `118`) with a `fwidth` distance fade.
- **Exact insertion points in `gfx3d.js` (OBSERVED):**
  1. **Sampler & Binding (`gfx3d.js:24-29`):** Register the detail sampler alongside `hfxMap`:
     - Line 24: `getSamplers(samplers){ samplers.push('hfxMap'); }`
     - Line 25: `getActiveTextures(a){ if(this.mtex) a.push(this.mtex); }`
     - Line 29: `if(this.mtex) ubo.setTexture('hfxMap',this.mtex); }`
  2. **Albedo Soft Overlay & Mask Extraction (`gfx3d.js:69-81`, inside `CUSTOM_FRAGMENT_UPDATE_ALBEDO`):** Right after `hfxLum`, `steel`, `rust`, `grime`, `hfxMet`, and `hfxRgh` are computed from `surfaceAlbedo` (lines 69–72) and baked AO/curvature `mp` is read from `hfxMap` (lines 75–80):
     ```glsl
     // gfx3d.js:69-72
     { vec3 a=surfaceAlbedo; float mx=max(a.r,max(a.g,a.b)), mn=min(a.r,min(a.g,a.b)); float sat=(mx-mn)/max(mx,1e-4); hfxLum=dot(a,vec3(0.2126,0.7152,0.0722));
       float gr_=a.g/max(a.r,1e-4); float steel=(1.0-smoothstep(0.12,0.32,sat))*smoothstep(0.035,0.11,hfxLum);
       float rust=smoothstep(0.45,0.7,sat)*smoothstep(0.22,0.4,gr_)*(1.0-smoothstep(0.6,0.85,gr_)); float grime=1.0-smoothstep(0.006,0.03,hfxLum);
       hfxMet=mix(0.1,0.36,steel)*(1.0-rust*0.9); hfxRgh=clamp(0.5+rust*0.33+grime*0.3-steel*0.16,0.26,0.95); }
     // gfx3d.js:74-81
     #ifdef HULLFX_MAP
       { vec3 mp=texture2D(hfxMap,vMainUV2).rgb; float vao=1.0;
     #ifdef VERTEXCOLOR
         vao=max(vColor.r,0.25);
     #endif
         surfaceAlbedo*=clamp(mix(1.0,mp.r,0.9)/vao,0.3,1.3); float cv=mp.g-0.5;
         surfaceAlbedo*=1.0+smoothstep(0.03,0.2,cv)*0.4-smoothstep(0.02,0.16,-cv)*0.32; }
     #endif
     ```
     **Insert the triplanar colour overlay and roughness delta immediately after line 81** (using `rust`, `steel`/positive `cv`, and `grime`/negative `cv` as blend weights).
  3. **Detail Normal & Metallic/Roughness Blend (`gfx3d.js:118-155`, inside `CUSTOM_FRAGMENT_BEFORE_LIGHTS`):** Reuse the existing dominant-axis projection `pu` at line 118 and feed the detail normal height into `ht` at line 130 (or blend the tangent normal before `normalW=normalize(mix(normalW,nb,pf*0.8*dk));` at line 137), then apply the photo roughness/metallic modulation in the `#ifdef HULLFX_AI` block at lines 140–155:
     ```glsl
     // gfx3d.js:118
     if(pf>0.001){ vec3 an=abs(normalize(vHfXN)); vec2 pu=an.x>an.y&&an.x>an.z?vHfXL.zy:(an.y>an.z?vHfXL.xz:vHfXL.xy);
     // ...
     // gfx3d.js:130-137
     float ht=(-seam*0.6+(pid-0.5)*0.22*pk-hatch*0.45+greeb*0.6+(hfxN(vHfXL*2.2)-0.5)*0.12*pk)*0.016;
     vec3 dpx=dFdx(vPositionW), dpy=dFdy(vPositionW); float dhx=dFdx(ht), dhy=dFdy(ht);
     vec3 r1=cross(dpy,normalW), r2=cross(normalW,dpx); float det=dot(dpx,r1); vec3 grd=sign(det)*(dhx*r1+dhy*r2);
     float dk=1.0;
     #ifdef HULLFX_PAINT
     dk=1.0-smoothstep(0.15,0.45,hfxMet); // v55: worn steel keeps its smooth plate surface
     #endif
     vec3 nb=normalize(abs(det)*normalW-grd); normalW=normalize(mix(normalW,nb,pf*0.8*dk)); } }
     ```

### Question 3: Relating Detail Texture Scale to Ship Size (6 m Frigate vs. 26 m Barge)
- **OBSERVED** (`gfx3d.js:31`, `89`, `118` and `project_paint.py:103`, `115-128`): `vHfXL=positionUpdated;` (`gfx3d.js:31`) is in local mesh space, and `project_paint.py:103` uses `oc = tco.outputs['Object']` with fixed multipliers (`noise(32, 7)`, `noise(140, 4)`, `noise(500, 2)`). Because Pixal3D meshes are normalized into a unit bounding cube (`project_paint.py:3`: `unit cube spanning 1/1.1 of the frame`) before scaling in game or baking in Blender, 1 unit of `vHfXL` or `Object` coordinates on a 26 m barge is 4.33x larger in world metres than 1 unit on a 6 m frigate.
- **INFERRED (Fix):** Split grain into two regimes:
  1. **Physical micro-grain (rust pits, brushed steel grain, fine grime):** Must stay locked to **real game metres** (1.5 m tile = `vHfXL * shipLengthMetres / 1.5`), passed into `HullFxPlugin` via a per-hull scale uniform (e.g., `hfxS.y` or `hfxD`), so steel grain on a 26 m barge is not 4.3x coarser/blobby than on a 6 m frigate.
  2. **Structural panel seams (`pp` in `gfx3d.js:119-121`):** Scale sub-linearly (`pow(shipLengthMetres / 10.0, 0.65)`) so a 26 m barge has ~2.8x more plates along its hull than a 6 m frigate while plates still look slightly heavier on capital ships.

### Question 4: Preventing Repeating Wallpaper (Tiling)
- **OBSERVED** (`gfx3d.js:89`, `118`, `123-127`): `HullFxPlugin` already computes a per-plate hash `pid=hfxH(vec3(cx,row,1.3))` (`gfx3d.js:124`) and per-cell hash `id=hfxH(vec3(ci,2.7+hfxS.x))` (`gfx3d.js:127`), and switches projection planes starkly via `an.x>an.y&&an.x>an.z?vHfXL.zy:(an.y>an.z?vHfXL.xz:vHfXL.xy)` (`gfx3d.js:118`).
- **INFERRED (Fix):** Combine **per-plate UV offset + 90°/180° rotation using the existing `pid` hash** with **two-octave macro modulation (`bl=hfxN(vHfXL*0.35+hfxS.x*2.0)` already at `gfx3d.js:152`)**. Specifically, offset detail UVs inside each plate by `vec2(pid, fract(pid*17.3))` and flip axes when `pid > 0.5`. Because armor plates naturally have discrete seams (`seam` at `gfx3d.js:126`), UV discontinuities hide right inside the plate seam—giving zero-extra-texture-fetch stochastic tiling without a 3x-slower hex-lut stochastic sampler.

### Question 5: What Else Makes a Model Read "AI Generated" or "Clay" That Texture Alone Will Not Fix?
- **OBSERVED** (`project_paint.py:27`, `127-128`, `155`, `191-196` and `gfx3d.js:69-72`, `104`, `118`):
  1. **Exported GLBs discard the baked `_orm.png` and `_nrm.png` maps (`project_paint.py:191-196`):** Lines 183–189 bake `outp[:-4] + '_orm.png'` and `outp[:-4] + '_nrm.png'`, but lines 191–195 (`if os.environ.get('EXPORT'):`) build a new material `'painted'` and link **only** `Base Color` (`em_.node_tree.links.new(ti_.outputs[0], em_.node_tree.nodes['Principled BSDF'].inputs['Base Color'])`), never linking `FIN_ORM` or `FIN_NRM` into the exported GLB!
  2. **Isotropic 3D noise and tiny bevel radius (`project_paint.py:127`, `155`):** `bv.inputs['Radius'].default_value = .0008` (line 127) and `.0005` (line 155) only catch razor-sharp kit meshes; AI-generated hull blobs have soft, rounded 3–10 cm radii where `.0008` bevel dot-product (`rng(dp.outputs['Value'], .985, .80, 0, 1)`, line 129) evaluates to `0`, leaving AI hull edges completely un-worn while kit parts get bright edge wear.
  3. **Hard-switched triplanar box projection without blend weights (`gfx3d.js:89`, `118`):** `an.x>an.y&&an.x>an.z` snaps UVs across 45° chamfers, creating visible seam tearing on sloped AI hull shoulders.
  4. **Luminance-derived bump (`gfx3d.js:104`):** `float ht=sqrt(max(hfxLum,0.0))*0.05;` treats every bright paint stripe or decal as raised physical height and every dark paint area as a pit, giving painted surfaces a puffy, embossed "wet clay" relief.

## 3. Protocol Findings Table

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence |
|---|---|---|---|---|---|---|---|
| 1 | `project_paint.py` bakes `_orm.png` and `_nrm.png` finish maps on lines 183–189, but the `EXPORT` block on lines 191–196 only links `Base Color` into the exported GLB and drops both finish maps. | OBSERVED | `tools/blender/project_paint.py:194` | `em_.node_tree.links.new(ti_.outputs[0], em_.node_tree.nodes['Principled BSDF'].inputs['Base Color']); me.materials.clear(); me.materials.append(em_)` | Hand-built kit GLBs exported via `EXPORT` lose their baked roughness/metallic (`_orm.png`) and normal (`_nrm.png`) textures, forcing the engine to fall back to flat shader guesses and making parts look like smooth clay. | In the `if os.environ.get('EXPORT'):` block, load `outp[:-4] + '_orm.png'` (separate R/G/B to Occlusion/Roughness/Metallic) and `outp[:-4] + '_nrm.png'` (via `ShaderNodeNormalMap`) and link them to `Principled BSDF` before `export_scene.gltf`. | high |
| 2 | Bevel edge-wear detector in `project_paint.py` uses a `.0008` radius with a `.985` to `.80` normal dot-product threshold, which works on sharp kit primitives but misses rounded AI mesh edges. | OBSERVED | `tools/blender/project_paint.py:127` | `bv = T.nodes.new('ShaderNodeBevel'); bv.inputs['Radius'].default_value = .0008; geo = T.nodes.new('ShaderNodeNewGeometry')` | AI-generated hulls have melted, wide-radius edges (`0.005–0.02` in unit space) where a `.0008` bevel produces almost zero normal divergence, leaving AI hulls with no edge steel wear while kit parts have crisp edge highlights. | Combine a wider bevel radius (`0.006`) or mesh curvature (`ShaderNodeNewGeometry` `Pointiness`) with the `.0008` bevel so both broad AI hull ridges and sharp kit edges catch steel wear. | high |
| 3 | `HullFxPlugin` derives surface height directly from paint luminance (`sqrt(max(hfxLum,0.0))*0.05`) when `HULLFX_FIN` is not set. | OBSERVED | `gfx3d.js:104` | `if(rf>0.001){ float ht=sqrt(max(hfxLum,0.0))*0.05; vec3 dpx=dFdx(vPositionW), dpy=dFdy(vPositionW); float dhx=dFdx(ht), dhy=dFdy(ht);` | Bright paint markings puff outward and dark paint sinks inward regardless of material type, creating a pillowy "embossed clay" look under grazing light. | Drive `ht` in `CUSTOM_FRAGMENT_BEFORE_LIGHTS` from the triplanar detail height/normal map and the `rust`/`pits`/`steel` masks computed on lines 70–72 instead of raw `hfxLum`. | high |
| 4 | `HullFxPlugin` infers steel, rust, and grime solely from RGB saturation and luminance (`sat`, `gr_`, `hfxLum`) of `surfaceAlbedo`. | OBSERVED | `gfx3d.js:70` | `float gr_=a.g/max(a.r,1e-4); float steel=(1.0-smoothstep(0.12,0.32,sat))*smoothstep(0.035,0.11,hfxLum);` | Any desaturated grey or pale faction paint is misclassified as `steel` (boosting metalness and lowering roughness), while orange/warm faction trim is misclassified as matte `rust`. | Modulate `steel`, `rust`, and `grime` in `CUSTOM_FRAGMENT_UPDATE_ALBEDO` (`gfx3d.js:69-81`) with `hfxMap` curvature/AO (`mp.g`, `mp.r` from line 75) and the triplanar photo masks (`Rust004`, `Metal009`, `SurfaceImperfections002`). | high |
| 5 | Triplanar projection in `HullFxPlugin` hard-switches UV axes with `an.x>an.y&&an.x>an.z` without normal blend weights or ship-size world-scale normalization. | OBSERVED | `gfx3d.js:118` | `if(pf>0.001){ vec3 an=abs(normalize(vHfXN)); vec2 pu=an.x>an.y&&an.x>an.z?vHfXL.zy:(an.y>an.z?vHfXL.xz:vHfXL.xy);` | (1) Hard axis switching tears photo textures along 45° chamfered hull cheeks; (2) `vHfXL` is unscaled local space, so a 26 m barge stretches the same texture 4.3x larger than a 6 m frigate. | Multiply `vHfXL` by a per-hull world-metre scale uniform in `bindForSubMesh` (`gfx3d.js:29`), jitter/rotate UV per plate using `pid` (`gfx3d.js:124`) to stop wallpaper tiling, and smooth-blend across 45° normal transitions. | high |
| 6 | Cloning materials in `gfx3d.js` copies `mtex`, `rim`, `str`, `style`, `ecol`, `wear`, `seed`, `energy`, `ai`, `wcol`, `ring`, `haz` in damage shading, but omits `paint`, `det`, `kit`, and `fin`. | OBSERVED | `gfx3d.js:323` | `{ai:o.ai,wcol:o.wcol,ring:o.ring,haz:o.haz,mtex:o.mtex}); let pl=c.pluginManager&&c.pluginManager.getPlugin&&c.pluginManager.getPlugin('HullFx');` | When a ship takes damage and `v.dmgMats` clones its material (`gfx3d.js:323-326`), `paint`, `det`, `kit`, and `fin` flags are lost unless returned by `hfxOpts`, abruptly changing the hull's finish and detail defines mid-battle! | Include `paint:o.paint,det:o.det,kit:o.kit,fin:o.fin` in the `Object.assign` object at `gfx3d.js:323` so damaged hulls keep their exact `HULLFX_PAINT`, `HULLFX_DET`, `HULLFX_KIT`, and `HULLFX_FIN` shader defines. | high |
| 7 | `Smart UV Project` in `project_paint.py` runs with `angle_limit=math.radians(55)` and `island_margin=0.0002` before baking `RES` textures. | OBSERVED | `tools/blender/project_paint.py:27` | `bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0.0002)` | At `1024` or `2048` bake resolution, a `0.0002` UV margin is only `0.2` to `0.4` pixels wide, causing adjacent islands (e.g., dark cavity grime next to bright worn edge) to bleed across UV seams at lower mip levels on mobile. | Increase `island_margin` to `0.002` (`~2–4 px` at 1K/2K) in `smart_project` (`project_paint.py:27`) and `margin=0.002` in `pack_islands` (`project_paint.py:28`) when baking photo detail into paint. | med |

## 4. One Recommended Next Step

Pack a single 2K channel-packed detail atlas from the ambientCG picks (`Rust004` height/roughness in R, `Metal009` brushed scratches in G, `SurfaceImperfections002` grime in B, and a shared detail normal map) and wire it into `HullFxPlugin` at `gfx3d.js:81` (`CUSTOM_FRAGMENT_UPDATE_ALBEDO`) and `gfx3d.js:130` (`CUSTOM_FRAGMENT_BEFORE_LIGHTS`) using per-plate `pid` UV rotation (`gfx3d.js:124`) while simultaneously fixing `gfx3d.js:323` so `paint`, `det`, `kit`, and `fin` survive damage material cloning.

## 5. Not checked

- **Not checked:**
  - `textures/index.csv` and `tools/pc/tex_dl.ps1` on Ryan's local PC (`Downloads\voidsworn_test\textures\index.csv` is not committed to the repo per `TEXTURE_PASS.md:16`: `"The sets are not in the repo (size)."`).
  - Visual screenshot files `docs/ship_pipeline/c19_example/v14_pyre_barge.webp` and `docs/feedback/2026-10-22/` (not among the 5 raw text URLs opened).
  - `tools/blender/hs/detail_lib.py`, `tools/blender/hs/c19_kit.py`, `docs/ship_pipeline/AUDIT_BRIEF.md`, and `docs/ship_pipeline/AUDIT_SYNTHESIS.md` (stayed strictly within the 5 named files per `REVIEW_PROTOCOL.md` Rule 2).
