# Ship Pipeline Audit (`C19_51` and 35-Hull Queue)

**Reviewer:** Gemini (`contrib/gemini/reviews/ship_pipeline_audit.md`)  
**Date:** October 21, 2026  
**Scope:** Answers to the six questions in [`docs/ship_pipeline/AUDIT_BRIEF.md`](https://github.com/rcbailey12/voidsworn/blob/main/docs/ship_pipeline/AUDIT_BRIEF.md), covering [`tools/blender/hs/c19_kit.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/hs/c19_kit.py), [`tools/blender/project_paint.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/project_paint.py), [`tools/blender/paint_level.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/paint_level.py), [`tools/pc/jobs/c19_4_kit_to_game.bat`](https://github.com/rcbailey12/voidsworn/blob/main/tools/pc/jobs/c19_4_kit_to_game.bat), and [`ships3d.js`](https://github.com/rcbailey12/voidsworn/blob/main/ships3d.js).

## Executive Summary Table

| Question | Topic | Recommended Pick | Primary Files Affected |
| :--- | :--- | :--- | :--- |
| **0** | Hull vs. kit detail consistency | **Do both:** move fine grit/seams to one shared triplanar detail shader in `ships3d.js` AND run constrained plane-snapping (`planesnap.py`) on large flat AI hull plates before cutting. | [`ships3d.js`](https://github.com/rcbailey12/voidsworn/blob/main/ships3d.js), [`tools/blender/hs/planesnap.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/hs/planesnap.py), [`tools/blender/project_paint.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/project_paint.py) |
| **1** | Scaling pipeline to 35 more ships | **Keep Qwen + Pixal3D + projection paint, drop per-ship Python coordinate coding.** Split the 35 hulls into 3 faction/size tracks, use a reusable Blender part library with auto-sockets, and bake 2M normals onto a 250k desktop mesh. | [`docs/ship_pipeline/README.md`](https://github.com/rcbailey12/voidsworn/blob/main/docs/ship_pipeline/README.md), [`docs/ship_pipeline/SHIP_QUEUE.md`](https://github.com/rcbailey12/voidsworn/blob/main/docs/ship_pipeline/SHIP_QUEUE.md) |
| **2** | `c19_kit.py` bugs and rule breaks | **Fix 8 concrete bugs:** `casegun` aims backward (`+X` aft instead of `-X` bow), `TANK` is cut out of the hull and never rebuilt, `brace` floats 19 mm above the roof, `longgun` has 0 deg outboard yaw, and `hatch2`/`fun1-2` break symmetry. | [`tools/blender/hs/c19_kit.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/hs/c19_kit.py), [`tools/blender/hs/hs_lib.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/hs/hs_lib.py) |
| **3** | Front armour plates and bridge top | **Replace flat `box()` slabs with cambered 3-point chevron lofts** that wrap the hull's lateral slope, and **add a stepped upper conning tier + tripod mast base + dorsal rangefinder** on the bridge crown. | [`tools/blender/hs/c19_kit.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/hs/c19_kit.py), [`docs/ship_pipeline/concepts/C19_51.webp`](https://github.com/rcbailey12/voidsworn/blob/main/docs/ship_pipeline/concepts/C19_51.webp) |
| **4** | Automating blob sweep and cut/measure | **Build a single `auto_sweep.py` pass** using internal ray diameter (`< 8 mm`) for wire debris, 2-ring vs. 15-ring normal residuals for wavy plates, and bilateral symmetry diff (`Y` vs. `-Y`) + morphological hull opening for protrusion sockets. | `tools/blender/auto_sweep.py`, [`docs/ship_pipeline/BLOB_SWEEP.md`](https://github.com/rcbailey12/voidsworn/blob/main/docs/ship_pipeline/BLOB_SWEEP.md) |
| **5** | Matching kit and hull paint brightness | **Level the Qwen views once in 2D before projection, remove `paint_level.py` from the kit, fix four pipeline bugs** (broken CLI args in `c19_4_kit_to_game.bat`, missing vertex colors in `c19_kit.py`, AgX bake curve, and split `aiKitMat` PBR values). | [`tools/blender/project_paint.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/project_paint.py), [`tools/blender/paint_level.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/paint_level.py), [`ships3d.js`](https://github.com/rcbailey12/voidsworn/blob/main/ships3d.js) |

## 0. Consistency of Detail Between AI Hull and Hand-Built Parts

**My pick:** A baked albedo detail layer on the kit alone is not enough. You need **two changes working together**:
1. **Run a constrained plane-snap pass on the AI hull's large flat plates** before cutting the kit (fixing the **shape** mismatch).
2. **Move fine surface detail (seams and micro-grit) out of `project_paint.py` and into one shared in-game triplanar detail shader** in [`ships3d.js`](https://github.com/rcbailey12/voidsworn/blob/main/ships3d.js) used by both the hull and the kit (fixing the **surface lighting** mismatch).

### Why Kit v10 (`DETAIL=1`) Still Looks Mismatched Up Close
In [`tools/blender/project_paint.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/project_paint.py) (lines 87 to 99), `DETAIL=1` multiplies the kit's **albedo color** by a 3D brick texture (`Scale=38`), noise (`Scale=900`), and a Cycles bevel-normal dot product (`Radius=0.0015`), then bakes that into `kit_albproj.png`. That helped at medium zoom, but fails at close zoom (`0.5`) for three reasons:
* **Albedo-only grit does not bend specular highlights:** In [`ships3d.js`](https://github.com/rcbailey12/voidsworn/blob/main/ships3d.js), kit faces still have mathematically flat vertex normals (`nor`), while the adjacent AI hull has bumpy vertex normals and baked normal ripples (`_n.webp`). When the camera or ship rotates, light glides smoothly across the flat kit planes while breaking up noisily across the AI hull.
* **Uneven UV texel density blurs baked seams:** For hand-built parts, `project_paint.py` (line 20) runs `bpy.ops.uv.smart_project(angle_limit=55, island_margin=0.006)`. Across 200+ small cylinders and boxes, `smart_project` wastes UV space on margins and gives inconsistent texel density, so baked 1-pixel brick mortar lines look crisp on one part and blurry on the next.
* **The AI hull's large flat areas wobble in 3D:** Even with identical textures, a dead-straight bevelled kit box sitting on a pillowy AI deck or flank immediately gives away which part is hand-built and which part is AI.

### The Two-Part Fix
1. **Flatten wavy AI plates with an upgraded [`tools/blender/hs/planesnap.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/hs/planesnap.py) before running the kit script:**
   * You already have `planesnap.py` in the repo from Bake-off Entry E. Right now it snaps every vertex within `TOL=0.006` of any region with `> 5` faces, which was too aggressive on small details.
   * Restrict `planesnap.py` to **macro plates only**: require region area `> 0.0025` (about 4% of hull side area), normal spread `< 10 deg`, and blend vertex displacement smoothly to zero over a `0.005` boundary margin so snapped plates never create hard tears against curved hull sections. Follow with `WEIGHTED_NORMAL` so large hull panels shade flat like the kit.
2. **Share one in-game triplanar detail normal + cavity shader across `aiHullMatFor` and `aiKitMat`:**
   * Turn off `DETAIL=1` in `project_paint.py` (keep baked textures pure albedo).
   * In [`ships3d.js`](https://github.com/rcbailey12/voidsworn/blob/main/ships3d.js), attach a lightweight Babylon `MaterialPluginBase` (or detail map) to both hull and kit materials that samples a single tileable 512x512 panel-seam + micro-grit normal/roughness texture in **ship-local object space** (triplanar projection). Because it runs in the fragment shader in ship space, texel sharpness is identical on a 2M-triangle hull and a 12-triangle kit box at any zoom level.

## 1. Is This Pipeline the Right One for 35 More Ships?

**My pick:** **Keep Steps 1 to 5** (Qwen multi-view generation, Pixal3D mesh, camera fit, and projection painting), **replace Step 6** (hand-coding a custom Python coordinate script like `c19_kit.py` for every ship), **split the 35 hulls into three tracks by faction and size**, and **cap desktop in-game meshes at 250k triangles with a baked 2M normal map**.

### Why the Current Step 6 Will Bottleneck on 35 Ships
`C19_51` took 10 kit versions because writing a 280-line Python script (`c19_kit.py`) with 70+ hard-coded coordinates (`(-.235, -.120, -.150, -.060)`) by trial-and-error takes hours per hull. Across 35 more ships, that is roughly 35 to 50 days of iteration. Worse, the current mechanical bolt-on approach does not work for **11 of the 35 remaining ships** (6 Chorus bio-ships and 5 Ithar sail-ships) and is overkill for **3 tiny squadron craft**.

### What to Change and Replace

| Track | Hulls in [`SHIP_QUEUE.md`](https://github.com/rcbailey12/voidsworn/blob/main/docs/ship_pipeline/SHIP_QUEUE.md) | Pipeline Changes | Est. Time / Hull |
| :--- | :--- | :--- | :--- |
| **Track A: Mechanical Capitals & Escorts (21 hulls)** | Voidsworn (6), Hegemony (5), Corsair (4 remaining), Deathless (4), Station/Transport/Beacon (3) | Replace per-ship Python primitive coding with a **Reusable Prefab Library (`voidsworn_kit_library.blend`)** + **Auto-Socket JSON (`auto_sweep.py`)**. Priority 1 capitals (7 hulls) get full bow/bridge/turret swaps; Priority 2 escorts (14 hulls) get turret/barrel/nozzle prefab swaps + hull plane-snapping only. | ~45 min (Pri 1)<br>~20 min (Pri 2) |
| **Track B: Chorus Bio-Ships (5 hulls) & Ithar Sail-Ships (5 hulls)** | Chorus (`B22`, `B16`, `B19`, `B20`, `B21`), Ithar (`I16`, `I8`, `I14`, `I11`, `I15`) | **No mechanical bolt-on kit.**<br>• **Chorus:** Run wire-debris removal + curvature-preserving Taubin smoothing (`bmesh.ops.smooth_vert`) so sacs/carapaces are crisp and organic, plus auto-extract an **emissive vein/sac mask (`_e.webp`)** from high-chroma concept pixels.<br>• **Ithar:** Auto-extract thin curved solar sails from side/front masks as clean 2-sided lofted sheets; plane-snap and smooth the pale hull body. | ~25 min |
| **Track C: Squadron Craft (3 hulls)** | Fighter (`S1_51`), Bomber (`S2_23`), Spore (`B23_51`) | **Zero hand-built kit.** Tiny on screen. Run Qwen views -> Pixal3D -> automated wire cleanup + centerline symmetry enforcement -> projection paint -> decimate to 25k tris. | ~10 min |

### Fix the Desktop Triangle & Memory Budget Before Doing 35 Ships
* Right now, desktop loads `hulls_hi/C19_51.vsm` at **1.5M to 2M triangles (~11 to 14 MB per hull)** with no kit Merging. In a 20-ship battle, pushing 30M to 40M triangles in JavaScript/WebGL will cause heavy frame drops and sub-pixel triangle aliasing (shimmering edges when zoomed out).
* Earlier TRELLIS tests looked ragged at 38k only because 38k was too low for a complex silhouette and had no high-poly normal bake.
* **The sweet spot:** Use the **250k LOD mesh (`lod_make.py`) for desktop** (`~2.5 to 3.5 MB`), **60k for phone (`~0.8 MB`)**, and bake a **tangent-space normal map (`_n.webp`) + ambient occlusion (`_m.webp`) from the 2M Pixal3D mesh onto the 250k mesh** inside Blender. At 250k triangles + normal map, the silhouette and close-up sharpness at zoom 0.5 are visually identical to 2M triangles at **1/7th the GPU cost**.

## 2. Audit of `c19_kit.py`: Placement Mistakes, Rule Breaks, and Concept Mismatches

Inspecting [`tools/blender/hs/c19_kit.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/hs/c19_kit.py) line by line against [`docs/ship_pipeline/BLOB_SWEEP.md`](https://github.com/rcbailey12/voidsworn/blob/main/docs/ship_pipeline/BLOB_SWEEP.md) Section 3 and [`docs/ship_pipeline/concepts/C19_51.webp`](https://github.com/rcbailey12/voidsworn/blob/main/docs/ship_pipeline/concepts/C19_51.webp) reveals **8 concrete bugs and rule violations**:

| # | Lines in `c19_kit.py` | Part Name(s) | Bug / Rule Violation (`BLOB_SWEEP.md` Sec. 3) | Concrete Fix |
| :--- | :--- | :--- | :--- | :--- |
| **1** | Lines 44-50, 58 | Midship side tanks (`TANK`) | **Cut out of the hull and never rebuilt.** Lines 44-50 measure `TANK[s_]` and line 58 deletes the tank faces from the AI hull (`# side tanks`), and `SHIP_QUEUE.md` claims *"tanks rebuilt"*, but `TANK` is **never referenced again** in `c19_kit.py`. This leaves raw holes in both midship flanks. | Add `cyl(f'sidetank{s_}', (.020, s_ * ty, tz), .014, .095, axis='X', seg=24)` with end caps and two mounting saddle straps at `x = -0.01` and `x = +0.05`. |
| **2** | Line 132 | Aft casemate gun (`casegun`) | **Aimed backward toward the stern instead of forward/outboard.** In this frame, bow is `-X` (`XT = -0.490`) and stern is `+X`. Line 121 says *"aimed outward and slightly forward"*, but line 132 passes direction `(1, s_ * .05, -.01)`, which points **99.8% aft (`+X`)** and only `2.8 deg` outboard, pointing opposite to `longgun` right above it. | Move the gun base to the forward cheek of the casemate (`x = 0.155`) and aim forward and outboard: `barrel(f'casegun{s_}', (.155, s_ * (yf + .018), -.133), (-1, s_ * .28, -.02), .095, .0055)`. |
| **3** | Lines 134-138 | Aft long cannon (`longgun`) | **Zero outboard yaw (aimed parallel to hull centerline).** Built with `axis='X'` and `rot=None` only `8.5 mm` outside `SIDEF[(2, s_)]`, so the forward muzzle at `x = 0.158` grazes the midship hull flare instead of angling clear of the ship. | Yaw `longgun` and its 4 rings outboard by `8 deg` (`Matrix.Rotation(s_ * math.radians(-8), 3, 'Z')`) so the barrel clears the forward flank. |
| **4** | Lines 71-76 | Mast, brace, and rungs (`mast`, `brace`, `rung0..3`) | **Floating parts and missing base mount.** `brace` (line 74) starts at `(-.032, 0, .123)`, which floats in mid-air **19 mm above the bridge roof** (`zt = 0.102`). `mast` has no mounting collar on the roof, and `rung0..3` at `x = 0.038` hang off the back of `mast` (`x = 0.035`, `r = 0.0035`). | Add a stepped mast collar on the bridge roof, anchor the tripod struts from `(0.035, 0, 0.165)` down to the actual roof at `z = 0.104`, and center rungs on `x = 0.035`. |
| **5** | Lines 15-17, 79-87 | Deck guns (`GUNS`, `gunplate`, `gunball`) | **Broken mount rotation call and upward mortar angle.** Line 84 passes `axis=Rn` (a `Matrix`) into `cyl()`, whose signature in `hs_lib.py` (line 25) expects `axis` to be `'X'`, `'Y'`, or `'Z'` (`{'Z': ..., 'X': ..., 'Y': ...}[axis]`) and `rot=Rn`. Also, the aft pair in `GUNS` (`x0=0.248, x1=0.250, z=0.006..0.080`) aims `59 deg` straight up in the air instead of outboard. | Fix line 84 to `cyl(..., axis='Z', rot=Rn)`, make `gunball` a proper hemisphere, and lower the elevation of `GUNS` from `z1 = 0.080` to `z1 = 0.028` so they aim outboard as broadside guns. |
| **6** | Lines 64, 114 | Funnels (`fun1`, `fun2`) and bow hatch (`hatch2`) | **Unintended asymmetry.** `hatch2` (line 114) is placed only on port (`y = +0.045`) with no starboard mate. `fun1` (`y = +0.010`) and `fun2` (`y = -0.012`) are staggered left/right instead of sitting on the centerline `y = 0` as shown in the front/side views. | Center `fun1` and `fun2` on `y = 0.0` (`x = 0.064` and `x = 0.086`), and mirror `hatch2` across `s_ in (1, -1)`. |
| **7** | Lines 56, 122, 127 | Aft open bay (`cut_extra`) and casemates (`casemate`) | **Unfilled hull cut and boxy primitive mismatch.** Line 56 cuts a hole in the aft deck (`0.285 <= x <= 0.36`) that is never covered by a kit part. Line 122 defines `def ellipsoid()` for the curved casemate blisters in `C19_51.webp`, never calls it, and uses an axis-aligned `box()` on line 127 instead. | Remove the unfilled bay cut on line 56 (or cap it with a recessed hatchbay box), and build `casemate` as a tapered frustum/loft faired into the hull side instead of an axis-aligned box. |
| **8** | Lines 267-280 | Kit export block (`OUT_kit.glb`) | **Exports 200+ unjoined objects with `Principled BSDF` materials instead of joined vertex colors.** Never calls `hs_lib.finish('kit')` and never writes `COL` into a mesh color attribute, which breaks `project_paint.py` (see Question 5). | Write `COL[o.name]` to a `BYTE_COLOR` vertex attribute on each part, then call `hs_lib.finish('kit')` before exporting `_kit.glb`. |

## 3. Better Design for the Front Armour Plates and the Bridge Top

### A. Front Armour Plates (Glacis Ahead of Bridge, `x = -0.242` to `-0.112`)
**Why v9 looks out of place:**  
In [`tools/blender/hs/c19_kit.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/hs/c19_kit.py) (lines 252 to 259), v9 stacks four flat rectangular boxes (`frontslab0..3`) rotated only in pitch (`rot=(0, -a_, 0)`). Because the forward hull under the bridge crowns downward toward port and starboard, a flat horizontal box sticks its left and right corners out into thin air. Putting an identical centered rectangle (`frontplaque`) on all four slabs makes them read like four stacked drawers rather than warship armour.

**What [`C19_51.webp`](https://github.com/rcbailey12/voidsworn/blob/main/docs/ship_pipeline/concepts/C19_51.webp) shows and how to build it:**
1. **Cambered Chevron Loft Instead of Flat Boxes:**
   * Sample the hull glacis height at three lateral points for each X station: centerline `z_c = deck0(x, 0)` and shoulders `z_s = 0.5 * (deck0(x, -0.055) + deck0(x, 0.055))` (typically `10 to 14 mm` lower than centerline).
   * Build each of the 4 plates using `hs_lib.loft()` with a **crowned chevron cross-section** (a central spine crease at `y = 0` sloping down by `10 to 12 deg` toward `y = ±w/2`, with side skirts that tuck `6 mm` into the hull surface so no corner ever floats).
2. **Shingled Overlap Profile (Thick Lower Lip, Flush Upper Edge):**
   * Instead of uniform `16 mm` blocks separated by gaps, overlap each upper slab by `4 mm` over the trailing edge of the slab below it, with a thick `14 mm` bevelled lower brow tapering to `5 mm` at the top edge, matching the stepped scale armour in the concept close-up.
3. **Framing Cheek Ribs + Warm Charcoal Base Color:**
   * Replace the 4 identical `frontplaque` boxes with **two continuous longitudinal cheek stringers** (`y = ±0.058`) that lock the plates into the hull slope, plus a central vertical spinal rib.
   * Change `SLATE = (.06, .06, .065)` (cold blue-grey) to warm dark iron `(.075, .058, .050)` and let `project_paint.py` project the concept and front/side views onto the slabs so they inherit the painting's warm rust/soot gradients.

### B. Bridge Top and Antennae (`x = -0.088` to `+0.062`, `z > 0.102`)
**Why v9/v10 looks plain and sparse:**  
The current bridge stops at a single flat slab (`roof` at `z = 0.102`) with a thin handrail, one small cylinder (`rooftank`), and two bare vertical cylinders (`mast`, `mast2`). In [`C19_51.webp`](https://github.com/rcbailey12/voidsworn/blob/main/docs/ship_pipeline/concepts/C19_51.webp), the bridge crown is a **multi-tiered dreadnought superstructure** with an upper conning/rangefinder house, heavy armored brow visors, side signal wings, and a braced lattice mast.

**What to build on top of `tier` (`z = 0.102`):**
1. **Upper Conning Tier (`tier2`) with Armored Visor (`z = 0.102` to `0.126`):**
   * Add a stepped upper deckhouse `frustum('tier2', (-0.012, 0, 0.102), (0.044, 0.034), (0.036, 0.028), 0.024, bevel=0.002)` in `STEEL`, capped with a projecting `RED` sun-visor brow (`x = -0.058`, `y = ±0.036`, `z = 0.122`) and 4 warm amber slit lamps (`LAMP`) tucked under the brow.
2. **Side Signal Sponsons & Roof Vent Louvers:**
   * Add a matched pair of winged rangefinder sponsons (`y = ±0.044`, `z = 0.112`) flanking `tier2`, each holding a short twin AA stub barrel or searchlight drum.
   * Call `hs_lib.vents('brvents', (0.028, 0, 0.105), 5, 0.042, 0.004, 0.006)` (already implemented in `hs_lib.py` line 46!) on the aft bridge deck behind `tier2`.
3. **Braced Tripod Mast & Cross-Tree Sensor Array (`z = 0.126` to `0.245`):**
   * Step the main mast into a heavy octagonal/cylindrical pedestal (`r = 0.009`, `h = 0.018`) on top of `tier2`, with **two rear tripod legs** (`r = 0.0024`) anchored cleanly to the aft corners of `roof` (`(0.048, ±0.026, 0.102)`).
   * Rake the main mast and two side whip aerials aft by `6 deg` (warship rake), widen the lower yardarm (`yard`) to `y = ±0.038` with small cylindrical radar/vox drums at both tips, and mount a glowing orange signal lantern (`LAMP`) in a caged frame at the peak.

## 4. Automating the Blob Sweep and the Cut/Measure Step

**My pick:** Build a single headless Blender preprocessor (`tools/blender/auto_sweep.py`) that runs right after Pixal3D and before kit building. Using `bmesh`, `BVHTree`, and `numpy`, it automatically deletes thin wire debris, flattens wavy hull plates, segments blurred bolt-on protrusions into a `<CODE>_sockets.json` file, and renders the 9-cell [`BLOB_SWEEP.md`](https://github.com/rcbailey12/voidsworn/blob/main/docs/ship_pipeline/BLOB_SWEEP.md) diagnostic grid.

### Step-by-Step Algorithms for `auto_sweep.py`

1. **Auto-Delete Thin Wire Debris ("spiky or crossed sticks"):**
   * **Disconnected islands:** Run a BFS connected-components pass over face adjacency (`adj` in `planesnap.py` line 26) and delete any component with `< 250` faces or `< 0.2%` of total surface area.
   * **Attached spikes and thin stalks:** For every face center $c_i$ with normal $n_i$, cast an **internal thickness ray** along $-n_i$: `hit, _, _, _ = bvh.ray_cast(c_i - 1e-4 * n_i, -n_i, 0.025)`.
   * Flag faces where local diameter $d_i < 0.007$ (`7 mm` in unit ship space) **and** local 2-ring normal variance is high ($\text{Var}(n_{\text{2-ring}}) > 0.45$, meaning it is a thin tube/spike rather than a flat thin wing or sail).
   * Group contiguous flagged faces; if a group's bounding box aspect ratio is elongated or its base loop perimeter on the hull is `< 0.04`, delete the faces and run `bmesh.ops.holes_fill(bm, edges=boundary_edges, sides=30)`.

2. **Auto-Detect and Flatten Wavy Regions on Flat Panels:**
   * Compute two area-weighted vertex normal fields: a local 2-ring normal $N_{\text{fine}}$ and a wide 16-ring macro normal $N_{\text{macro}}$.
   * **Waviness metric:** $W(v) = \|N_{\text{fine}}(v) - N_{\text{macro}}(v)\|$ masked to regions where $N_{\text{macro}}$ is locally planar ($\text{std}(N_{\text{macro}}) < 0.15$). High $W(v)$ (`0.08` to `0.35`) pinpoints AI pillowing on flat decks and armour slabs.
   * **Automatic repair:**
     * On hull flanks and decks, feed high-$W$ planar regions directly into `planesnap.py` (with soft `5 mm` boundary feathering).
     * On the bow (`x < -0.25`), auto-slice the mesh at 16 X-planes (`bmesh.ops.bisect_plane`), average the port and starboard Y-coordinates at each Z-height to enforce bilateral symmetry, fit a clean 6-point piecewise-linear chine hull section, and pass the 16 sections directly to `hs_lib.loft('bow', secs)`. That completely eliminates hand-writing `bow_sec(x)` for the next 35 ships.

3. **Auto-Find Blurred Bolt-On Parts and Measure `BOXES` + Kit Sockets:**
   * **Smooth Base-Hull Extraction ($M_{\text{base}}$):** Duplicate the mesh in memory and apply 40 iterations of Taubin/Laplacian smoothing (`bmesh.ops.smooth_vert`), shrinking bolt-on bumps down to the clean underlying hull envelope $M_{\text{base}}$.
   * **Protrusion Segmentation:** Compute signed outward height $h(v) = (v - \text{nearest}(M_{\text{base}}, v)) \cdot n_{\text{base}}$. Flood-fill connected components where $h(v) > 0.008$. Each connected component is a candidate bolt-on feature (turret, casemate, funnel, bridge tier, side tank, thruster).
   * **Blur & Symmetry Scoring (deciding which protrusions to cut):**
     * **Symmetry error:** Compare each protrusion at $(x, y, z)$ with its mirrored counterpart at $(x, -y, z)$ via `BVH.find_nearest`. High asymmetry on non-Corsair hulls flags mangled pairs.
     * **Projected edge sharpness mismatch:** Compare the high-frequency gradient magnitude of the projected concept/Qwen texture inside the protrusion's UV footprint against the mesh's 3D curvature. High 2D image gradient + low 3D curvature = **blurred/melted detail** (such as rocket pod tubes or gun barrels).
   * **Auto-Measure Output (`<CODE>_sockets.json`):** For every flagged protrusion cluster, automatically record:
     * `cut_box`: `[x0, x1, y0, y1, z0, z1]` (replaces hand-typed `BOXES` in `c19_kit.py`).
     * `mount_pos` and `mount_normal`: centroid and normal of the cluster's base ring on $M_{\text{base}}$ (replaces `surf_down` / `surf_in`).
     * `principal_axis`, `length`, and `radius`: from PCA (SVD of vertex coordinates in the cluster), classifying it automatically as `barrel` (elongated, $L/D > 3.5$), `cylinder/tank/funnel` ($1.2 < L/D \le 3.5$), or `box/turret/tier` ($L/D \le 1.2$).

## 5. Principled Fix for Matching Kit and Hull Paint Brightness

**My pick:** **Stop running `paint_level.py` on the kit and hull separately.** Instead, level the 2D Qwen views to the concept painting **once before projection**, fix four concrete bugs in `c19_4_kit_to_game.bat`, `c19_kit.py`, and `project_paint.py`, and make `aiKitMat` in [`ships3d.js`](https://github.com/rcbailey12/voidsworn/blob/main/ships3d.js) share the exact same PBR lighting parameters as `aiHullMatFor`.

### Why Kit and Hull Brightness Currently Diverge (4 Root Causes Found in Code)

1. **`paint_level.py` Normalizes Two Different UV Distributions Independently and Clamps at `0.5`:**
   * In [`tools/blender/paint_level.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/paint_level.py) (lines 6 to 11), `level()` forces the mean of **all non-black texels in the UV atlas** (`m = a.sum(2) > 6/255`) to equal `0.8 * concept_mean`, bisecting gain `g` inside `lo, hi = 0.5, 8.0`.
   * On the **hull**, a large fraction of the UV atlas covers dark unprojected undersides and occluded cavities where `project_paint.py` blends in `base_img` (Pixal3D's dark baked texture). That drags the hull's global UV mean way down, forcing `paint_level.py` to boost the entire hull by **`g = 2.35`**.
   * On the **kit**, the UV atlas contains mostly exposed top/side parts plus `DETAIL=1` bevel highlights (`ed` up to `1.6x` on line 95 of `project_paint.py`). Its UV mean starts higher than `target`, so the bisection hits the hard floor **`lo = 0.5`**.
   * **Result:** The exact same pixel from `C19_51_left.png` projected onto the hull and onto an adjacent kit plate gets multiplied by `2.35` on the hull and `0.50` on the kit (a **4.7x linear luminance ratio**)!

2. **`c19_4_kit_to_game.bat` Calls `project_paint.py` With Bare Image Paths Missing `|mask|az|el|wt`:**
   * Look at [`tools/blender/project_paint.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/project_paint.py) lines 9 to 13: every view argument in `argv[3:]` must be formatted as `view.png|mask.png|az|el|weight` (`p = a.split('|')`).
   * Now look at [`tools/pc/jobs/c19_4_kit_to_game.bat`](https://github.com/rcbailey12/voidsworn/blob/main/tools/pc/jobs/c19_4_kit_to_game.bat) line 14:
     ```bat
     %BL% -b --factory-startup -P project_paint.py -- "%IO%\kit\E2_kit.glb" "%IO%\kit\kit_albproj.png" 4096 "%V%_left.png" "%V%_right.png" "%V%_top.png" "%V%_front.png" "%V%_back.png" "%CONCEPT%" >> %L% 2>&1
     ```
     Because the `|mask|az|el|weight` fields are missing in `c19_4_kit_to_game.bat`, `p[1]` raises `IndexError: list index out of range` unless called with the exact pipe-delimited view strings used in `c19_2_mesh_fit_paint.bat`!

3. **`c19_kit.py` Never Writes Vertex Colors or Joins the Kit Mesh Before `project_paint.py`:**
   * At the end of [`tools/blender/hs/c19_kit.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/hs/c19_kit.py) (lines 267 to 280), the script assigns `COL` colors to separate `Principled BSDF` materials on 200+ individual objects in `hs_lib.PARTS` and exports `_kit.glb` without calling `hs_lib.finish('kit')` and without creating a Vertex Color layer.
   * When [`tools/blender/project_paint.py`](https://github.com/rcbailey12/voidsworn/blob/main/tools/blender/project_paint.py) runs on `_kit.glb`, line 15 (`o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]`) grabs only the **first object** if not joined, and line 68 (`vc = T.nodes.new('ShaderNodeVertexColor')`) reads an empty vertex color attribute instead of the `Principled BSDF` base colors!

4. **Blender AgX View Transform Distortion + Mismatched `aiKitMat` PBR Settings in `ships3d.js`:**
   * In `project_paint.py` (line 104), `tgt.save()` writes the baked `EMIT` image through Blender 4.5's default **AgX** view transform, which compresses and desaturates values above `0.6` linear.
   * In [`ships3d.js`](https://github.com/rcbailey12/voidsworn/blob/main/ships3d.js), `aiKitMat` uses hardcoded `roughness = 0.68`, `metallic = 0.08`, `environmentIntensity = 0.6`, and `t.level = 0.95 / 1.15` (plus the `0.3` self-light fudge), which respond differently to scene lights than `aiHullMatFor`.

### The 4-Step Principled Fix

1. **Match the 5 Qwen views to the concept painting in 2D inside `mv_prep.py` (before any 3D projection):**
   * The concept painting (`C19_51_cut.png`) is already at the exact target brightness. In `mv_prep.py`, scale each generated Qwen view (`left`, `right`, `top`, `front`, `back`) in linear RGB so its foreground-masked mean luminance equals the concept painting's foreground-masked mean luminance.
   * Once the 2D views match the concept painting, **projected texels on both the hull and the kit are inherently at the exact same brightness** (`gain = 1.0`). Delete `paint_level.py` from the kit pipeline completely (or, if you apply a global artistic tweak `K`, apply the **exact same scalar multiplier `g`** to both textures).

2. **Set `Standard` Color Management and Mean-1.0 Detail Modulation in `project_paint.py`:**
   * Add two lines before `bpy.ops.object.bake(type='EMIT')` in `project_paint.py`:
     ```python
     sc.view_settings.view_transform = 'Standard'
     sc.view_settings.look = 'None'
     ```
   * If `DETAIL=1` is used during baking, center its multiplier around `1.0` (change `br` `Color2` to `1.0`, `gm2` range to `[0.88, 1.12]`, and `ed` range to `[1.25, 0.96]`) so procedural grit does not shift average brightness.

3. **Write Real Vertex Colors and Join `hs_lib.PARTS` in `c19_kit.py` (and Fix `c19_4_kit_to_game.bat`):**
   * At the bottom of `c19_kit.py`, before calling `hs_lib.finish('kit')`, write `COL[o.name]` (calibrated to the linear RGB medians of red armour, dark iron, and steel sampled from `C19_51_cut.png`) into a vertex color attribute (`me.color_attributes.new('Col', 'BYTE_COLOR', 'CORNER')`) on every part, then call `hs_lib.finish('kit')` so `_kit.glb` is a single mesh with valid vertex colors for `KEEP` boxes and unprojected cavities.
   * In `c19_4_kit_to_game.bat` line 14, pass the full `view.png|mask.png|az|el|weight` arguments identical to the hull projection call in `c19_2_mesh_fit_paint.bat`.

4. **Make `aiKitMat` Clone `aiHullMatFor` in `ships3d.js`:**
   * In [`ships3d.js`](https://github.com/rcbailey12/voidsworn/blob/main/ships3d.js), replace the separate `aiKitMat` material setup with a direct clone of `aiHullMatFor(fac, d)` where only `albedoTexture` is swapped to `dir + code + '_kit_a.webp'`. Because both hull and kit now share the exact same projected pixel values and the exact same PBR / self-light shader parameters, their brightness matches at every camera angle and on every map without any manual fudge factors.
