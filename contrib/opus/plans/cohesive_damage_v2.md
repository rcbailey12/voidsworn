# Cohesive Ship Damage, Lit Authored Interiors, and Capability-Loss Pipeline (Wounds V2, R416)

Issue #1741. Ruling: R416 (Ryan, Nov 22 2026: rejected the 2D painted R402 concept sheet `opus1235wd`, approved picks `1=A, 2=A, 3=A, 4=A`, and mandated one singular cohesive chain from ship build through weapons, weapon effects, weapon damage, ship damage and capability loss, to ship destruction).

Feature flag during review: `VS_WOUNDS_V2=1` (ProjectSettings `rendering/effects/wounds_v2`, default `false` until Ryan approves real 3D camera-170 and camera-26 captures on all six factions and the solo GPU frame-time check passes).

---

## 1. The Single Cohesive Chain (One Source of Truth at Every Seam)

Every stage below must read from the stage before it rather than inventing parallel constants or faction checks:

| Stage | Primary Files | Single Source of Truth Read | What It Produces |
|---|---|---|---|
| 1. Ship build | `tools/blender/kits/<faction>/stack.py`, `tools/recipe/export7.py`, `docs/ship_pipeline/HARDPOINTS.md` | Faction kit + `faction_looks.json` + build sheet `INSIDE` and weapon slots | Exported GLB with `voidsworn_destruct` (`interior_materials`, `seams`, `machines`), `_inside_skin` liner, `hp_w<slot>_*`, `turret_*`, `hp_eng_*`, `hp_breach_*`, `hp_core`, `door_*` |
| 2. Weapons | `godot/rules/data/tables.json`, `godot/fx/fx_weapons.gd`, `godot/fx/fx_hull.gd` | Weapon slot index (`slot`), weapon id (`look`), weight (`w`), `hp_w<slot>_*` / `turret_*` | Firing recoil, muzzle flash, barrel kick, projectile/beam silhouette (Wave 1A #1690, Wave 2A #1692 a/b/c/e) |
| 3. Weapon effects | `godot/fx/fx_weapons.gd`, `godot/fx/faction_looks.json` | Target faction `wound_profile` + `HULL.target_substance(faction)` (Wave 1B #1691 / PR #1736) | Material-accurate impact flash, sparks, shards/droplets, vapor/mist, and felt-hit brownout |
| 4. Weapon damage (marks & hits) | `godot/fx/fx_breach.gd`, `godot/fx/fx_shaders.gd` | Impact `(lp, ln, ldir)`, weapon `look`/`w`, target `wound_profile`, BVH `hull.tm` | Geometry-validated surface scars (light hits / Stage 0-1) or real 3D armor cutouts / edge-shears (heavy hits & Stage 2+ on authored hulls), including folded #1692(d) `prism`, `star`, `nlance` marks |
| 5. Ship damage, interiors & capability loss | `godot/fx/fx_ship.gd`, `godot/fx/fx_hull.gd`, `godot/fx/fx_breach.gd`, `godot/fx/fx_shaders.gd` | `u["sec"]`, `u["weapons"][i]["off"]`, `u["burning"]`, `u["regenLock"]`, engine/shield crits, `s.hull.authored` interiors, `hp_w<slot>_*`, `hp_eng_*`, `turret_*` | Real mid-battle 3D cutouts with thick faction rims, mouth-masked breach-lit authored interiors + `s._hole_lights` cavity lights, exact slot turret/casemate knockouts, tiered faction-safe engine nozzle failure, shield-generator burnout crackles, live vents from open mouths |
| 6. Ship destruction | `godot/fx/fx_death.gd`, `godot/fx/fx_death_beats.gd`, `godot/fx/fx.gd` | `s.current_arrays()` (live breaches carried into pieces), `voidsworn_destruct` seams/machines, unified faction interior shader, `faction_looks.json` death + wound profile | Seamless handoff from wounded living hull -> strain tell -> faction break -> cooling wreck with faction-authentic interiors (no universal black matte `wreck_interior()` soot on glass or flesh) |

---

## 2. Root Causes Fixed (Verified on `main`)

1. **Zero mid-battle cutouts:** `fx_breach.gd:176-177` (`has_cut()`) only cuts `K_HOLE`; `marks_for()` (L1832-1914) creates zero `K_HOLE` entries; `fx_ship.gd:1816-1874` (`_plan()`) opens `K_HOLE` only at Stage 4 (<20% section HP), keeping all 27+ rebuilt ships' authored interiors hidden during most of battle.
2. **Crushed dark unlit interiors:** `tools/blender/kits/{voidsworn,hegemony,hullbreakers,eclipse}/stack.py` crush room albedos to `INSIDE_BASE` (0.01 to 0.035 linear, `INSIDE_TINT` 0.18 to 0.20), and `fx_breach.gd:1823` clears `s._hole_lights` without ever spawning breach cavity lights.
3. **Off-ship and bleed-through projection:** `fx_breach.gd:507-522` (`_in_overlay`) never checks triangle normal alignment (`tri_normal.dot(E.n)`); `_thick()` (L203-209) fires only one center ray; thin structures like `deathless_E12.py` ring arcs (0.14 thick) have open space behind them.
4. **Shared/off-lore wound shaders:** `faction_looks.json` maps Sunward, Directorate, and Hullbreakers all to `wound_kind: 0`; `fx_shaders.gd` `MARK` (L1991-2013) hardcodes orange scorch on all metal factions; Chorus `MARK:2055` and `HOLE:1636` hardcode purple-magenta (violating `factions.md` Never list); Glasswright `MARK:2059-2064` draws radial sine spiderwebs; Eclipse `MARK:2066-2076` draws a black 3x3 neon grid square.
5. **Disconnected capability loss and engine soot leak:** `fx_ship.gd:1596-1643` (`sync`) ignores `u["weapons"][i]["off"]` completely and jams a random turret by section instead of the actual knocked-out weapon slot; `fx_ship.gd:331` (`var corsair = extra == "soot" or _eng_sputter`) forces black Hullbreaker soot onto every faction's damaged engines and disables Chorus spores and Eclipse embers.
6. **Live-to-wreck interior discontinuity:** `fx.gd:1449-1459` (`wreck_interior`) crushes every faction's authored interior surfaces to `WRECK_SOOT` matte black (`roughness = 1.0`) when a ship splits, erasing Glasswright glowing braided light cores and Chorus wet tissue/bone.
7. **Eclipse green interior core leak:** `tools/blender/kits/eclipse/stack.py:81` still defines `CORE_RGB = (44, 255, 24)` (green), which feeds `inside_material()` (routed into the #1422 Eclipse rebake).

---

## 3. Single-Source Faction Data Contract (`godot/fx/faction_looks.json`)

Extend each faction entry in `godot/fx/faction_looks.json` with a `wound` dictionary and distinct `wound_kind` (0..5):

| Faction | `wound_kind` | Substance | Cutout / Rim Geometry | Surface Mark Character | Exposed Interior Look (Live -> Wreck) |
|---|---|---|---|---|---|
| `voidsworn` | `0` | `metal` | Ragged heavy plate tear, thick curled forged-iron lip, bare-steel spall edge | Dark soot streak, bare steel gouge, ember-cooling rim | Riveted iron deck grating, warm ember-lit gunnery galleries & plenum glow -> sooted cooling iron |
| `hegemony` | `1` | `metal` | Clean rectilinear/modular panel shear stepped along panel seams, straight recessed lip | Cool steel scorch, pale-blue electrical burn (zero orange) | Bright pale-grey/white modular corridors, equipment racks, pulsing implant-blue emergency strips -> powered-down pale corridors with failing blue arc |
| `corsair` | `2` | `metal` | Jagged ripped patchwork plates peeled back off welds, torn scrap tabs | Heavy dark soot, rust-brown grime, red-amber slag | Raw rusted girders, scavenged hull framing, crooked conduits, dirty red-amber work glow -> charred scrap girders |
| `chorus` | `3` | `bio` | Splintered horn-bone chitin scute shell edge, curled wet hide margin (zero metal peel) | Cracked chitin flakes over muddy olive-umber / deep maroon-brown hide (**zero magenta**, zero soot) | Curved ivory/ochre bone hoops (ribs), glistening wet dark-umber living tissue, pulsing yellow-green bile sacs -> ruptured wet tissue & dull pale bone (never dry matte black soot) |
| `ithar` | `4` | `glass` | Sharp straight-edged angular mosaic pane cutout, faceted crystalline bevel rim | **Zero soot, zero black holes, zero sine webs.** Straight Voronoi crystal fracture planes catching specular & rainbow caustics | Frosted annealed glass frames and luminous braided amber/violet/emerald waveguide light cores glowing crisp white-gold -> dim frosted shards with fading white-gold light (never sooted black) |
| `deathless` | `5` | `obsidian` | Clean stepped delamination of precision ordered obsidian plates; thin ring arcs shear into exposed dark truss ribs | Zero neon grid squares, zero green, zero soot wash. Crisp stepped obsidian chip with thin cold violet-white seam bleed | Dark machined obsidian archive vaults, ordered frames, subtle trapped violet-white core spill -> cold dark obsidian vaults with fading violet seam |

Add under each faction in `faction_looks.json`:
```json
"wound": {
  "rim_style": "curled | modular | ragged | chitin | facet | stepped",
  "scorch_col": [r, g, b],
  "rim_metal": [r, g, b],
  "interior_lift": [r, g, b],
  "interior_accent": [r, g, b],
  "interior_pattern": 0,
  "interior_rough": 0.65,
  "soot_weight": 1.0,
  "wreck_soot": 0.35
}
```
Every shader (`MARK`, `HOLE`, unified interior shader, `fx_ship.gd` emitters/sparks/cough, `fx_death.gd` wreck interiors) reads from this table. No hardcoded orange or magenta per-faction color literals remain in `fx_shaders.gd`.

---

## 4. Geometry-Locked Placement & Projection (`fx_breach.gd`, `fx_hull.gd`)

### 4.1 Eight-Ray Footprint Validation (`BREACH.validate_footprint`)
Before finalizing any `K_HOLE` cutout or heavy mark of radius `R` at `(c, n)`:
1. Build tangent basis `(t1, t2)` around `n`.
2. Cast 8 perimeter rays from `c + radial_k * (0.85 * R) + n * (R * 0.9)` along `-n` against `hull.tm`.
3. A ray is valid if it hits within depth band `|dot(hit.p - c, n)| < max(R * 0.45, hull.L * 0.025)` and `hit.n.dot(n) > 0.30`.
4. If valid count < 6 (under 75% solid support):
   - Try shrinking `R` down in steps (`0.75 * R`, `0.55 * R`) and nudging `c` toward the average of valid hit points projected back onto `hull.tm`.
   - If still below threshold (or if `R < hull.L * 0.015`), downgrade `K_HOLE` to a **compact surface mark or edge-shear** instead of punching a hole over empty space.
5. **Thickness check for thin exterior structures (`_thick(hull, c, n, R)`):**
   - Cast center + 4 half-radius inward rays (`-n`) from just inside the skin.
   - If median hull thickness `< max(R * 0.40, hull.L * 0.018)` (e.g., Eclipse Zenith 0.14-thick outer shade ring arcs, dorsal fins, narrow struts), mark `e.thin_shear = true`: instead of cutting a deep interior cavity, cleanly delaminate/chip the outer plate layer (shallow recess + crisp structural frame/truss strip backing, zero floating cavity into open space).

### 4.2 Normal-Gated, Depth-Clamped Overlays & Cutouts
- In `fx_breach.gd` `_tri_in_overlay()` and `_surface()`:
  - Compute triangle geometric normal `tn`. Reject triangles where `tn.dot(E.n) < 0.35`.
  - Tighten normal slab to `absf(h) <= maxf(E.R * 0.35, E.depth + E.th * 3.0)` so overlays never bleed onto the opposite face of a ring arc, twin pontoon, or overlapping chitin scute.
- In `fx_hull.gd` `_damage_code()` mouth discard:
  - Keep tight `h` bounds (`h >= -fx_axes[i].w and h <= R * 0.45`) AND require `dot(fx_hull_n, fx_axes[i].xyz) > 0.25` (passing hull-space normal `fx_hull_n` from vertex to fragment) so a hole cut on the top face never discards plating on a perpendicular wall or opposing ring strut.

### 4.3 Turret & Bay-Door Clearance Everywhere
- Apply `fx_ship._off_turrets()` and a new `_clear_of_doors()` check (reading `hull.doors` boxes via `_door_above`) to **every** `K_HOLE` cutout and heavy crater, not only Stage 4 anchors. If a shot hits a turret directly, keep a compact surface scuff/spark on the hull beside its ring rather than cutting a void underneath the rotating turret mesh.

---

## 5. Mid-Battle Cutouts, Thick Rims, Lit Authored Interiors & Folded `#1692(d)` Marks

### 5.1 Damage Progression (Pick 1=A, Updated RULEBOOK 6.14)
On authored-interior hulls (`s.hull.authored`):
- **Stage 0-1 + light hits (`las`, `auto`, `scatter`, `guns`, `flak`, `needle`, light `macro`):** Surface marks only (dents, paint spall, straight crystal fracture facets, cracked chitin scutes, scorched shade panels). Zero polygons removed.
- **Heavy hits on weakened armor (`torp`, `lance`, `nlance`, `star`, `gauss` exit, or `w >= 3` when struck section HP < 80%) AND Stage 2+ section wear (~55% section HP and down):**
  - Open real `K_HOLE` cutouts (radius starting around `0.026 * L` at Stage 2 / first heavy breach, growing through `0.038 * L` at Stage 3 to `0.052 * L` at Stage 4, always clamped by 8-ray `validate_footprint`!).
  - Cut through both exterior plating and `_inside_skin` liner while preserving all `interior: true` surfaces (decks, bulkheads, rooms, organs, bone hoops, braided light cores).
  - Cap simultaneous open cutouts per ship (e.g., max 6 per ship, 2 per section) so performance and silhouette clarity hold even in 20-ship battles.
- **Legacy hollow hulls (`not s.hull.authored`):** Keep RULEBOOK 6.14's existing 20% section HP threshold and procedural `_throat` cavity fallback.

### 5.2 Thick Faction Armor Rims & Gap Framing
- Replace `e.th = R * 0.05` in `fx_breach.gd:229` with real plate depth `clampf(Dt * 0.14, hull.L * 0.008, R * 0.24)` so every cut edge shows chunky, readable armor slab thickness.
- Shape the cut outline and rim lip by `wound.rim_style`:
  - `curled` (Sunward) / `ragged` (Hullbreakers): organic torn petal waves, outward/inward bent tabs.
  - `modular` (Directorate) / `stepped` (Eclipse): snapped rectilinear/orthogonal panel edges (`square` / stepped hull-aligned frame) so panels look cleanly sheared off structural seams.
  - `chitin` (Chorus): jagged layered horn-plate fracture bevel with soft curled hide rim underneath.
  - `facet` (Glasswright): crisp polygonal straight-segment crystal pane edges (6 to 8 straight segments, zero curved metal waves, zero metal bend!).
- For authored hulls where the inward ray behind a `K_HOLE` travels further than `R * 0.45` before hitting a modeled deck or room box, add 2 to 3 minimal faction-styled collar ribs/conduits (or bone strands for Chorus, glass struts for Glasswright) tucked directly inside the rim so grazing camera angles never see empty space between skin and deck.

### 5.3 Unified Breach-Lit & Wreck Interior Shader + Cavity Lights (Pick 2=A)
- Build one shared spatial shader (`SH.INTERIOR` / `HULL.interior_material_v2`, with `fog_disabled`, warmed in `fx.gd` startup) applied to `interior: true` authored surfaces **only once a ship opens its first breach or begins dying** (zero cost on intact ships):
  - Keeps the original surface's baked albedo/emission/roughness inputs.
  - **Live mode (`fx_wreck = 0.0`):** Computes proximity `open_f` to the nearest open `fx_mouths[i]` (same uniform array already maintained by `fx_breach._mouth_uniforms()`).
    - Where `open_f == 0`: surface stays at its dark baked value (zero light leak through closed hull seams).
    - Where `open_f > 0`: lifts the crushed `0.02` albedo toward `wound.interior_lift` (moody structural contrast, never neon portal wash), adds subtle ship-space triplanar detail matching `wound.interior_pattern` (deck grating / riveted iron, modular white corridor panels + pulsing blue emergency strip, rusted scrap ribs, glistening muscle fibers + ivory bone highlight, frosted glass framing + bright white-gold waveguide core boost, dark obsidian vault ribs + thin violet seam), and adds soft depth-attenuated internal illumination from the breach center (`em` clamped so nothing blooms like a portal).
  - **Wreck mode (`fx_wreck = 0.0 -> 1.0`):** Smoothly transitions those exact same interior surfaces during death tell (`fx_flick` / power-down) into settled wreck state using `wound.wreck_soot` (sooted charred iron for metal, dull pale bone & wet dark tissue for Chorus, dim frosted glass & fading light cores for Glasswrights, cold dark obsidian vaults for Eclipse). Replaces `fx.gd:1449` universal matte-black `wreck_interior()`.
- **Cavity point lights (`s._hole_lights`):**
  - Activate `s._hole_lights` using the existing pooled `fx.light(...)` / `OmniLight3D` budget: at most **2 active subtle cavity lights per wounded ship** (strictly capped across the battlefield to protect the 12.5 ms RTX 5080 gate), tucked `0.25 * R` *inside* the largest open breach mouths, tinted by `wound.interior_accent`, radius `R * 2.2`, low energy so real 3D decks and beveled armor rims catch genuine directional specular and shadow contrast.

### 5.4 Folded `#1692` Item (d) Weapon Marks
Implemented cleanly inside the new `fx_breach.gd` `marks_for()` and `SH.MARK`:
- `prism`: `S_PRISM` crystalline star-facet refraction/shatter mark (straight Voronoi cracks + faint spectral glint, never metal `S_SHELL` crater or soot).
- `star`: `S_STAR` radiant heat-bleached sear / white-gold thermal bloom that cools to scorched bright alloy/glazed glass (never black soot `S_BLAST` ring).
- `nlance`: Keep `"nlance"` distinct in `fx_weapons.gd` (stop collapsing to `"lance"` at L1994) and emit `S_NLANCE` triple-parallel cold violet-black void cuts (three narrow offset trenches along `cut_dir` with faint violet-white rim decay).

---

## 6. Capability-Loss Visual Coupling (`fx_ship.gd`, `fx_hull.gd`, `battle.gd`)

Tie visible ship damage directly to the rules engine's actual lost systems (view-only, zero rules changes):

1. **Exact weapon-slot knockouts (`u["weapons"][i]["off"] > 0`):**
   - Add `hull.turrets_for_slot(slot: int) -> Array` and `hull.mounts_for_slot(slot: int) -> Array` in `fx_hull.gd` reading the already-parsed `points["gun"]` (`slot`, `tur`, `p`, `n`, `f`).
   - In `fx_ship.gd` `sync()`, inspect `u["weapons"]`:
     - Any slot `i` with `float(w.get("off", 0)) > 0` (whether temporary crit `off == 2` or section-destroyed `off >= 99`) jams every turret owned by slot `i` (drooped off-axis, thin faction-appropriate smoke/spark wisp within `damage_caps`) and attaches a dead-muzzle smoke/spark marker on fixed casemates/launchers of slot `i`.
     - Repairing (`off == 0`) unjams those exact turrets and clears their wisps.
     - Keep section-stage fallback only when a unit dict has no `weapons` array (e.g., synthetic bench setups).
2. **Tiered engine damage tied to `sec.eng` + engine crits (and fix `fx_ship.gd:331` soot leak):**
   - **Critical bug fix:** Remove `or _eng_sputter` from `var corsair = extra == "soot" or _eng_sputter` (`fx_ship.gd:331`). Keep Hullbreaker soot exclusive to `extra == "soot"`; damaged nozzles of every other faction keep their own faction exhaust/spores/embers/glints and use faction-matched sputter coughs.
   - Track `_eng_damage_tier` (0 healthy, 1 engine crit or `stage[0] == 2`, 2 `stage[0] == 3`, 3 `sec.eng.broken` or `stage[0] == 4`):
     - Tier 1: 1 nozzle gutters (`sick_nozzle`) with reduced plume (~65%) and faction-matched coughs on acceleration.
     - Tier 2: 1 nozzle dead/dark (on multi-nozzle hulls) with thin stern bell smoke/sparks; 1 nozzle guttering.
     - Tier 3 (`sec.eng.broken` / "Engines crippled"): all nozzles except 1 dark/blown out, the last surviving nozzle guttering weakly (~35% plume), plus stern hull breach exposing the engine room (`engroom`).
3. **Midship / shield generator loss (`sec.mid.broken` or `"Shield generator down"`):**
   - Flank mounts (`P`/`S` slots) visibly go dark/smoking via the exact weapon-slot hook above.
   - While `shield_offline` is active on a shielded faction, emit intermittent low-intensity failed-emitter arc crackles on the midship hull surface near `hp_core` or an open midship breach (respecting `reduce_flashing`), making "Shield generator offline" immediately readable on the 3D hull.
4. **Data bridge without touching rules or saved results (R405):**
   - `u["weapons"]` (`off`), `u["sec"]` (`broken`), `u["burning"]`, and `u["regenLock"]` are ALREADY present in `battle_api.gd:_i_view()` (L252-259).
   - For `"Engines hit"` (`st.engine > 0`) and `"Shield generator down"` (`st.shieldOff > 0`), either forward those system events from `battle.gd` (`case "system":` / `section_down`) directly to `gfx.system_damage(id, kind)` (100% zero touch to `godot/rules/`!), OR verify `battle_api.gd` view-only fields leave all 289 battles and 30 campaign runs byte-identical. Forwarding from `battle.gd` (plus reading `sec.eng.broken` / `sec.mid.broken` / `weapons[i].off` in `fx_ship.sync`) is the cleanest zero-risk route.
5. **Anchor live damage emitters inside real open breaches:**
   - When a section has an open `K_HOLE`, place its `fire`, `smoke`, `vent`, and `#1587` blowout emitters inside that actual open breach mouth rather than an unbreached surface point.

---

## 7. Ship-Build Stack Cohesion (Folded into Active Rebakes, Zero Extra Rebakes)

While Wounds V2 works immediately on all 27+ already-installed ships via the runtime breach-lit interior shader, upcoming faction rebakes carry the ship-build side of R416 so Blender assets and runtime FX agree from the ground up:
- **#1422 (Eclipse all-violet repaint):** Flip `CORE_RGB = (44, 255, 24)` in `tools/blender/kits/eclipse/stack.py:81` to Eclipse violet-white (`faction_looks.json`), and lift `INSIDE_TINT` from `0.20` toward `0.50` to `0.55`.
- **#1681 (Navy) and #1684 (Hullbreakers) and future Sunward rebakes:** Lift `INSIDE_TINT` from `0.18` toward `0.55` in the shared faction `stack.py` (`hegemony`, `hullbreakers`, `voidsworn`) whenever that stack is next touched, keeping closed hulls 0 px surface-check clean while giving exposed rooms richer baked material separation.

---

## 8. Proof & Verification Plan (Pick 3=A: Real 3D Renders, No 2D Paint-Overs)

### Headless Checks (`godot/fx/test/wounds_v2_check.gd`, registered in `godot/tools/ci/godot_checks.txt`)
1. Flag-off (`VS_WOUNDS_V2=0`) keeps existing behavior untouched.
2. 8-ray footprint check shrinks/nudges cutouts on a narrow ring-arc stand-in (Eclipse Zenith geometry) and switches thin plates (`thickness < 0.4 * R`) to `thin_shear`, producing zero off-hull vertices or floating overlays.
3. Normal-gated overlay projection produces zero back-face or opposite-strut overlay triangles.
4. Mid-battle cutouts open `K_HOLE` at Stage 2+ and on heavy hits on authored-interior hulls while preserving all `interior: true` triangles and keeping legacy hollow hulls sealed until Stage 4.
5. All 6 `wound_kind` values (0..5) load from `faction_looks.json`, shaders compile with zero warnings, `late_shader_check.gd` reports 0 late shaders, Chorus shaders contain zero magenta literals, and Glasswright/Chorus/Directorate marks emit zero soot or hardcoded orange.
6. Folded `#1692(d)` checks: `prism`, `star`, and `nlance` each emit their own distinct mark styles (`S_PRISM`, `S_STAR`, `S_NLANCE`).
7. Capability-loss checks: disabling `weapons[slot].off > 0` jams that exact slot's turret(s) and unjams on repair; tiered engine degradation shuts down nozzles cleanly and NEVER triggers Hullbreaker black soot on Glasswright, Chorus, Eclipse, or Directorate hulls.
8. Live-to-wreck continuity check: Glasswright and Chorus wreck interiors keep their faction interior shader (never matte black `roughness = 1.0` `WRECK_SOOT`).

### Real 3D GPU Look-Bench Proof (`godot/bench/look_moments_wounds_v2.json`, queued after green CI + passed review per R407)
Capture all 6 reference ships (`V16_37` Sunward Vigil, `H10_23` Directorate Dominion, `C15s_23` Hullbreaker Wrecker, `B21_11` Chorus Bladeback, `I15_11` Glasswright Prism, `D21_23` Eclipse Zenith) at **camera 170** and **camera 26**, before (`VS_WOUNDS_V2=0`) beside after (`VS_WOUNDS_V2=1`), at most 720 px tall with code names and revision stamped:
1. 1 heavy hit (healthy hull -> surface fracture/scuff or small tight breach)
2. Mid-battle 50% hull (real cutouts + lit authored interiors + capability loss: knocked-out turret & guttering engine)
3. Severe 20% hull (crippled engines, open breached compartments, venting live wounds)
4. Death break transition (showing seamless interior continuity from live breach into broken wreck)
5. Solo GPU frame-time gate check (20-ship battle, p99 within the 12.5 ms RTX 5080 gate).
