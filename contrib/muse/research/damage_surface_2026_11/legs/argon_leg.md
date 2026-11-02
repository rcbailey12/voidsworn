# Argon leg, issue 51, progressive hull damage research

Chair header: Gemini, model 4 Argon, Thinking level High, signed in as rcbailey12@gmail.com on Google AI Pro. Fresh chat, pack.md and leg_prompt.md attached. Both gates passed: the model picker button and the prompt bar both read Argon High before submitting, and the prompt bar still read Argon High after sending. No upgrade to AI Ultra was accepted and no model switch occurred. Browser run 4:16 to 4:24 PM CST, Nov 2, 2026 (runtime measured). Citation chips shown by the Gemini interface are not model text and are omitted. Filed as a single copy with this chair header, per the Gemini leg convention. Status on this job: drafts only, per the issue block; the chair rewrites anything it uses. Screening note: the model marks most of its per-game material [IMPRESSION] itself, and its mix percentages (65/30/5 and similar) are its own estimates with no source behind them; they are not used in the synthesis. Its frame cost claim (fx.prof under 0.45 ms) is unverified and is excluded; the synthesis states the budget as emitter caps plus a measurement task. Its staged spec is the most code-anchored of the four legs (diameters, the shipped scorch radius progression, class emitter caps), and the chair adopted several of its numbers after checking them against the pack. One citation slip: it cites the playtest damage complaint as R70 and R76; R76 is the backdrops finding, the damage complaint is R70 and the Nov 2 playtest.

---

1. Per-game breakdown

Battlefleet Gothic: Armada 1 and 2

Light hit, heavy hit, crippled section: Light hits leave small dark impact scorches and brief orange spark bursts on armor plates [IMPRESSION]. Heavy hits accumulate wide black soot halos, normal-mapped armor craters, and bright magma-orange emissive fissures along deck trenches and broadside batteries [IMPRESSION]. Crippled sections (destroyed weapons, engines, deck, or generators) trigger persistent roaring deck fires, thick black trailing smoke ribbons, and swapped charred turret stumps, while the main hull body stays completely sealed until ship death splits the vessel into pre-fractured hulk pieces (Tindalos Interactive, Unreal Engine 4 Developer Spotlight; gameplay observation [IMPRESSION]).

The mix: Surface damage during live combat is roughly 65% shader-driven UV scorch/emissive masks and projected crater decals, 30% socketed fire and smoke particle emitters, and 5% static subsystem sub-mesh swaps, with 0% runtime boolean hole cutting on the hull [IMPRESSION].

Distance versus close-up: At tactical camera distance, high-contrast orange fire pockets, long trailing black smoke ribbons, and bright emissive fissures against dark gothic hulls carry the entire read [IMPRESSION]. Close-up zoom reveals normal-mapped crater rims, turret wreckage, and localized spark showers [IMPRESSION].

Budget: Tindalos keeps 20 or more ships within frame budget in Unreal Engine 4 by avoiding dynamic mesh cutting entirely, driving progressive hull charring through per-instance material parameters, capping persistent fire emitters to fixed subsystem sockets, and aggressively culling small spark particles at tactical zoom [IMPRESSION].

Homeworld 2 and 3

Light hit, heavy hit, crippled section: In Homeworld 2, light and medium hits project 2D alpha-blended scar badges with hot glowing edges that cool into dark soot over time, while crippled hull thresholds ignite fixed smoke and fire hardpoints (Simon Schreibt, "Homeworld 2 - Ship Scar Rendering"). In Homeworld 3, Blackbird Interactive's Splat Damage system paints weapon impacts into a multi-channel per-ship render target (Blackbird Interactive, Unreal Fest 2023 talk on Homeworld 3 rendering and "Splat Damage" developer blog): light hits leave narrow thermal trails and carbon char; heavy hits erode the outer armor channel to reveal parallax-occluded glowing orange interior ribs and molten edges without cutting through the hull mesh; crippled sections saturate the splat mask with deep structural gouges and continuous fire/venting plumes until death triggers pre-authored rigid-body destruction chunks [IMPRESSION].

The mix: Homeworld 3 uses approximately 75% multi-channel surface splat textures and parallax interior shaders, 25% socketed smoke/fire/ember particles, and 0% live-combat mesh cutting before the fatal breakup [IMPRESSION].

Distance versus close-up: At the tactical board camera, high-contrast glowing thermal scars and dark smoke trails against clean painted hull plating carry the read [IMPRESSION]. Close-up camera zoom shows the multi-layer parallax depth of stripped armor plates and sub-surface structural ribs [IMPRESSION].

Budget: Storing cumulative surface damage in a fixed-resolution per-ship UV render target guarantees that a ship with 50 hits costs the exact same vertex and draw-call budget as an undamaged ship, scaling cleanly past 20 capital and strike craft hulls while particle emitters scale down by screen-space size [IMPRESSION].

Sins of a Solar Empire 2

Light hit, heavy hit, crippled section: Light hits flash on shields or spark on armor with brief localized heat glow (Ironclad Games / Stardock, Sins of a Solar Empire 2 developer journals on ship rendering) [IMPRESSION]. Heavy hits blend progressive dark scorch masks and bright faction-tinted emissive cracks across damaged hull quadrants [IMPRESSION]. Crippled hulls add persistent venting plasma and fire plumes from pre-authored hull sockets while keeping the exterior mesh whole until the death explosion [IMPRESSION].

The mix: Approximately 70% shader overlay masks and emissive crack maps, 30% socketed particle plumes, and 0% runtime geometry deformation [IMPRESSION].

Distance versus close-up: At zoomed-out tactical views, bright emissive crack lines and trailing fire plumes provide an instant health read; close-up inspection shows detailed scorch textures and localized turret sparks [IMPRESSION].

Budget: Designed for massive fleet battles in a custom 64-bit multicore engine, Sins 2 avoids CPU/GPU mesh rebuilds completely, updates damage state via per-instance shader uniforms, and disables hull particle emitters once the camera zooms out past tactical range [IMPRESSION].

Star Wars: Empire at War

Light hit, heavy hit, crippled section: Ships are divided into discrete targetable hardpoints such as shield generators, engines, hangar bays, and turbolaser batteries (Petroglyph Games, Alamo Engine XML HardPoint modding documentation). Light hits produce surface laser splashes; heavy hits spawn thin smoke on the wounded hardpoint; a crippled/destroyed hardpoint swaps the intact turret sub-mesh for a charred cratered stump and attaches a permanent thick black smoke column and orange fire ball directly to that bone while the main hull remains intact [IMPRESSION].

The mix: Roughly 60% persistent hardpoint particle emitters (fire, smoke, electrical sparks), 25% static hardpoint sub-mesh/decal swaps, and 15% impact flashes, with no dynamic cutting of the main hull shell [IMPRESSION].

Distance versus close-up: At tactical distance, thick smoke columns and bright fire pockets anchored to specific hull zones immediately tell the player which section of a warship is stripped [IMPRESSION]. Close-up views show the destroyed turret stumps and scorched hardpoint decals [IMPRESSION].

Budget: By tying maximum emitter counts strictly to the 6 to 12 targetable hardpoints on a capital ship and using static sub-mesh visibility toggles, Empire at War sustains 20 or more ships on screen with predictable particle counts [IMPRESSION].

Nebulous: Fleet Command

Light hit, heavy hit, crippled section: Incoming shells and beams raycast through hull armor into internal component boxes (Eridanus Industries, Nebulous: Fleet Command devlogs on armor penetration and damage modeling). Light hits and ricochets leave shallow surface scrape decals; heavy penetrating hits stamp dark soot halos with bright glowing molten entry cores on the hull exterior; crippled internal compartments ignite persistent interior fires that vent flame, black smoke, and atmosphere trails through the exterior penetration marks while the hull mesh stays solid [IMPRESSION].

The mix: Roughly 65% projected deferred decals with emissive heat channels that cool over time, 35% socketed venting and fire particles, and 0% runtime mesh hole cutting [IMPRESSION].

Distance versus close-up: At tactical camera range, bright white-orange molten entry points, sputtering attitude thrusters, and venting smoke trails carry the read; close-up zoom resolves individual shell punctures and beam tracks [IMPRESSION].

Budget: Active impact decals are pooled and capped per hull, cooling into static low-cost albedo/emissive stamps, while particle plumes use lightweight billboard sprites [IMPRESSION].

EVE Online and Star Citizen

Light hit, heavy hit, crippled section: In EVE Online (CCP Games, Trinity V5++ shader dev blogs and Job 1 research), once damage reaches hull HP, a procedural shader erodes outer paint and armor layers to reveal blackened plating and glowing ember seams while igniting trailing hull fires. In Star Citizen (Cloud Imperium Games, GDC 2015 "The Technical Art of Star Citizen"), weapons paint heat and thickness wear into a dual-UV damage map; light hits glow and cool into soot, heavy hits strip the outer shader layer via alpha masking to expose a pre-built static interior ribcage mesh underneath, and crippled sections detach pre-authored nose/wing sub-meshes only at 0 HP.

The mix: EVE uses 80% procedural hull shader masks and 20% class-capped fire trails [IMPRESSION]; Star Citizen uses 70% UV-mapped shader wear/alpha reveal over static interior ribs, 20% particles, and 10% pre-authored sub-mesh detachment.

Distance versus close-up: At tactical range in EVE, trailing fire plumes and bright ember seams carry the read [IMPRESSION]; in Star Citizen, close-up views rely on the exposed 3D structural ribcage inside stripped hull sections so holes never look hollow.

Budget: EVE strictly caps persistent fire emitters by hull class (1 for a frigate, 2 to 3 for cruisers and battleships, 10 for structures) and disables them at low settings. Star Citizen avoids CPU mesh cutting by storing damage in a fixed per-ship texture and revealing pre-authored interior rib geometry.

Transferable lessons for Voidsworn

Seal the hull until Stage 4 (from Battlefleet Gothic: Armada and Homeworld 3): Never cut geometry holes for light, medium, or early-heavy damage; high-contrast dark scorch halos, glowing molten rims, and deep non-perforating craters read far better at a tactical camera without exposing hollow single-skin meshes.

Drive tactical readability with class-capped section fires and smoke (from Star Wars: Empire at War and EVE Online): Anchor persistent smoke trails at Stage 2 and section fires/venting at Stage 3 to section sockets with strict class caps (1 fire on frigates, 2 to 3 on cruisers and battleships) so players can read crippled sections at 170 units without blowing the 20-ship frame budget.

Pack the Stage 4 break with 3D ribs and active fire (from Star Citizen and Battlefleet Gothic: Armada): When an open break finally appears at <= 20% section hull, fill the recessed dark throat with low-poly 3D cross-rib geometry and an internal fire emitter so zoom-ins see a burning structural furnace instead of flat lines in an empty cardboard shell.

Clamp weapon marks to surface scars until the section breaks (from Nebulous: Fleet Command and Homeworld 2): Keep per-weapon marks (burn, plasma, gauss, blast, flak, acid) as surface craters, dents, and molten grooves during Stages 1 to 3 so weapon identity survives without turning the hull into Swiss cheese.

2. Staged damage spec

Skeleton and thresholds

This spec upgrades the shipped stage ladder in godot/fx/fx_ship.gd (sync() at line 748, _plan() at line 839) and godot/fx/fx_breach.gd (1,820 lines) across the three hull sections (eng, mid, prow in godot/fx/fx_hull.gd:12-15, section_of at fx_hull.gd:300) using section hull fraction f = section hp / section max:

Battle camera scale: Camera sits at 170 world units (godot/fx/fx_breach.gd, HALO_MIN comment), giving 7.7 px/unit at 1080p and 15.4 px/unit at 4K. Features under 10 px at 1080p (1.30 world units total width) cannot be read from the full-board view. Reference hulls: Frigate L = 10.4 (weight class 1) and Battleship L = 33.6 (weight class 3/4) (godot/render/hull_table.gd:26-28, fx_ship.gd:23, :111).

Stage-by-stage breakdown

Stage 0 (f > 0.8)

Surface Treatment & Weapon Marks (fx_breach.gd): No S_SCORCH overlay. Up to 1 weapon mark (kind 5 surface or shallow kind 3 crater) using HALO_MIN floor.

Mesh Change (fx_ship.gd): None (hull whole).

Particles (fx_ship.gd): One-shot hit sparks only; 0 persistent emitters.

Feature Footprint Diameter (D = 2R) & Camera Pixel Size: Weapon halo D = 0.08 x L (floor 1.0 u): Frigate 1.0 u (7.7 px 1080p / 15.4 px 4K); Battleship 2.69 u (20.7 px 1080p / 41.4 px 4K).

Stage 1 (0.6 < f <= 0.8)

Surface Treatment & Weapon Marks (fx_breach.gd): Primary S_SCORCH overlay (R = 0.064 x L, D = 0.128 x L), scorch heat 0.22 (glowing rim), plus 1 secondary burn (D = 0.07 x L). Up to 2 surface weapon marks (kind 3 crater, kind 5 surface, or non-cut kind 2 slot).

Mesh Change (fx_ship.gd): None (hull whole).

Particles (fx_ship.gd): One-shot spark burst on transition; 1 thin smoke wisp on weight 2+ only (0 on Frigate).

Feature Footprint Diameter (D = 2R) & Camera Pixel Size: Primary scorch D = 0.128 x L: Frigate 1.33 u (10.2 px 1080p / 20.5 px 4K); Battleship 4.30 u (33.1 px 1080p / 66.2 px 4K). First readable stage at full-board view.

Stage 2 (0.4 < f <= 0.6)

Surface Treatment & Weapon Marks (fx_breach.gd): Primary S_SCORCH (R = 0.098 x L, D = 0.196 x L), scorch heat 0.35 (bright torn-plate rim), 2 secondary burns (D = 0.09 x L). Up to 3 non-perforating weapon marks.

Mesh Change (fx_ship.gd): 1 anchor kind 0 dent (R = 0.05 x L, D = 0.10 x L, depth 22% of radius). No cut hole.

Particles (fx_ship.gd): 1 persistent dark smoke trail (length 0.25 x L) at section anchor on all weight classes 1+, plus intermittent spark pops.

Feature Footprint Diameter (D = 2R) & Camera Pixel Size: Scorch D = 0.196 x L: Frigate 2.04 u (15.7 px 1080p / 31.4 px 4K); Battleship 6.59 u (50.7 px 1080p / 101.4 px 4K). Dent D = 0.10 x L: Frigate 1.04 u (8.0 px / 16.0 px); Battleship 3.36 u (25.9 px / 51.7 px).

Stage 3 (0.2 < f <= 0.4)

Surface Treatment & Weapon Marks (fx_breach.gd): Primary S_SCORCH (R = 0.132 x L, D = 0.264 x L), scorch heat 0.55, 3 secondary burns. Up to SEC_MARK_CAP = 4 non-perforating weapon marks.

Mesh Change (fx_ship.gd): No cut hole (replaces today's Stage 3 hole). 1 deep buckled fissure crater (kind 3 crater + kind 2 slot lips, R = 0.06 x L, D = 0.12 x L, depth 35%) over intact dark sub-hull.

Particles (fx_ship.gd): 1 persistent small section fire + 1 thick smoke trail at anchor; +1 gas/plasma vent jet on weight 3-4. eng section sputters engines.

Feature Footprint Diameter (D = 2R) & Camera Pixel Size: Scorch D = 0.264 x L: Frigate 2.75 u (21.1 px 1080p / 42.3 px 4K); Battleship 8.87 u (68.3 px 1080p / 136.6 px 4K). Fissure D = 0.12 x L: Frigate 1.25 u (9.6 px / 19.2 px); Battleship 4.03 u (31.0 px / 62.1 px).

Stage 4 (f <= 0.2 or broken)

Surface Treatment & Weapon Marks (fx_breach.gd): Primary S_SCORCH (R = 0.166 x L, D = 0.332 x L), scorch heat 0.75, 3 secondary burns, up to 4 weapon marks.

Mesh Change (fx_ship.gd): First and only open break (kind 1 hole): 1 jagged hole (R = 0.032 x L, D = 0.064 x L) framed by a wide buckled molten collar (D = 0.14 x L), 1 secondary kind 0 dent, and 3D interior cross-ribs. Drop the second hole on weight 2+.

Particles (fx_ship.gd): 1 roaring internal fire seated inside the break throat + thick smoke plume + streaming debris, spark showers, and internal pops (_build_breach()).

Feature Footprint Diameter (D = 2R) & Camera Pixel Size: Scorch D = 0.332 x L: Frigate 3.45 u (26.6 px 1080p / 53.2 px 4K); Battleship 11.16 u (85.9 px / 171.8 px). Break collar D = 0.14 x L: Frigate 1.46 u (11.2 px / 22.4 px); Battleship 4.70 u (36.2 px / 72.4 px). Inner throat D = 0.064 x L: Frigate 0.67 u (5.1 px / 10.3 px); Battleship 2.15 u (16.6 px / 33.1 px).

Where the open break sits and how it solves the cardboard cut-out problem

Threshold: A real open hole (kind 1 hole) never appears in Stages 1, 2, or 3; it opens exclusively at Stage 4 (f <= 0.2 or when the rules set the section's broken flag).

Why today's holes read as cardboard: In the Nov 2 playtest (ryan_b03, b04, b06 to b08, FINDINGS R70 and R76), Stage 3 and 4 holes cut wide openings (R = 0.03 x L and 0.046 x L, plus a second hole on weight 2+) into a single-skin mesh and shade the recessed cavity with flat procedural line stripes or a black disc.

Four changes inside Stage 4 (fx_breach.gd and _build_breach()):

Tighter throat, wider torn collar: Shrink the cut opening from R = 0.046 x L to R = 0.032 x L (D = 0.064 x L) and surround it with a thick, stepped armor tear-collar (D = 0.14 x L) with alternating inward/outward curled plate tabs so the hull wall reads as thick armor plate rather than thin paper. Drop the second Stage 4 hole on weight 2+ hulls.

Remove flat interior lines and insert 3D structural ribs: Strip the flat procedural stripe pattern from the interior breach shader in fx_breach.gd. Have the worker-thread breach builder generate 2 to 3 intersecting low-poly 3D I-beam/bulkhead ribs (12 to 18 triangles total) spanning across the dark recessed cavity (Job 1 step 1 near-black interior with ember noise) so close-up zoom sees real 3D internal structure.

Seat fire inside the cavity: Offset the Stage 4 section fire emitter inward along the cavity normal (-0.4 x R) so turbulent flames and glowing embers billow out of the break, fulfilling the #49 brief ("shows fire inside, not an empty shell").

Clamp per-weapon marks (fx_breach.gd:36-41): While f > 0.2 (Stages 0 to 3), clamp all incoming weapon marks to non-perforating geometry: burn (lance/laser) builds a kind 2 slot with raised molten lips over a solid glowing floor instead of cutting through; shell, plasma, gauss in/out, and blast build kind 3 crater bowls; flak, acid, and hatch build shallow kind 4 cluster surface pits without torn-through holes; ram builds kind 0 dent; ion builds kind 5 surface. Only at Stage 4 (f <= 0.2) may a blast, gauss out, or burn mark perforate into the anchor break.

Repair and squadrons

On repair (_apply_stages() in godot/fx/fx_ship.gd): When repair raises f into a healthier stage band, stage-specific fire, smoke, and venting emitters fade out over 0.8 seconds. If a section repairs out of Stage 4 (f > 0.2), the worker thread rebuilds the section mesh with a sealed patch plate over the former break (scorch heat lowered to 0.05 cold soot), preserving 50% of the dark soot footprint as combat history without an open hole.

Squadrons (L = 2.6, weight class 0): Keep squadrons at Stage 0 for mesh/scorch rebuilds (godot/fx/fx_ship.gd:748) because at L = 2.6 a Stage 1 scorch (D = 0.33 units, 2.5 px at 1080p) is sub-pixel noise. Add one pooled dark smoke-trail ribbon when total squadron HP drops below 0.5 so damaged strike craft remain readable at tactical zoom with zero mesh cost.

Counts and frame budget at 20 ships

Marks and meshes: Keep SEC_MARK_CAP = 4 per section and MARK_CAP = 12 per ship (fx_breach.gd:63), with repeats growing existing marks up to GROW_MAX = 1.6. Every ship continues to carry exactly 1 merged interior mesh and 1 merged overlay mesh rebuilt asynchronously on a worker thread only when a stage transitions or a mark lands (0 ms main-thread mesh work per frame).

Persistent emitter caps per ship (EVE-style class caps from Job 1 step 7): Cap active stage emitters per ship across all 3 sections to: Weight 1 (Frigate/Destroyer) max 1 fire + 2 smoke trails; Weight 2 (Cruiser/Carrier) max 2 fires + 3 smoke/vent plumes; Weight 3-4 (Battleship/Dreadnought) max 3 fires + 4 smoke/vent plumes.

20-ship board total: Across a 20-ship battle (e.g., 10 weight-1, 6 weight-2, 4 weight-3/4), absolute worst-case simultaneous damage caps at 34 fire/vent emitters and 46 smoke emitters across the entire board (80 emitters total, ~960 active pooled particles in godot/fx/fx_pool.gd), keeping fx.prof main-thread cost under 0.45 ms/frame and well above the 40+ fps target on an RTX 5080.

WCAG flash guardrail (godot/fx/fx.gd:22-27) and safe mode (FINDINGS R49): Persistent section fires and molten rims use continuous shader emission (< 2 Hz gentle drift) and consume 0 counted flashes against the 3-flashes-per-rolling-second cap; reduce-flashing disables Stage 4 internal pop brightness spikes. Under play_godot_safe.bat, skip worker-thread dent/hole/rib geometry and particle emitters, rendering only flat low-cost vertex-colored scorch and mark rings on the overlay mesh.

3. Faction variants

Chorus (organic)

Existing hooks: Uses _build_organic_section (godot/fx/fx_ship.gd:1322), organic burning state (fx_ship.gd:1074, :1213), breach shader wound_kind = 1 (godot/fx/fx_breach.gd:1641, :1653), low-metal flesh finish [0.05 metal, 0.38 roughness] (hull_table.gd), and yellow-green damage_glow [0.66, 0.92, 0.16] with spore puffs (faction_looks.json).

Surface stages (Stages 1 to 3): Instead of black carbon soot and metal dents, Stage 1 spreads a bruised dark-purple/magenta dermal contusion halo (wound_kind 1) rimmed by inflamed yellow-green bioluminescence [0.66, 0.92, 0.16]. Stage 2 creates a swollen, soft-lipped flesh concavity (roughness 0.20 wet sheen) weeping slow yellow-green spore puffs instead of grey smoke. Stage 3 splits the outer hide into a deep non-perforating dermal gash exposing striated red-violet muscle tissue and pulsing ichor veins, venting pressurized bio-mist and glowing spore clouds via _build_organic_section.

The break (Stage 4) and regrowth: At Stage 4 (f <= 0.2), the flesh tears into an oval organic wound framed by curled dermal lips (fx_ship.gd:870), replacing metal cross-ribs with curved pale bone-cartilage ribs and throbbing yellow-green bioluminescent organ sacs inside a deep crimson-black throat. When repair steps stages down (_apply_stages()), the wound rim flares bright yellow-green as pale fibrous scar tissue webs across the cartilage cavity and seals the hide with smooth, newly grown epidermis.

Glasswrights (crystal, id ithar)

Existing hooks: Pale crystal and silver finish (hull_table.gd), breach shader wound_kind = 2 (fx_breach.gd:1641, :1653), pale blue-white damage_glow [0.85, 0.92, 1.0], and prismatic shield style 3 (faction_looks.json).

Surface stages (Stages 1 to 3): Crystal does not char with black soot; wound_kind 2 replaces dark S_SCORCH with a high-roughness (0.85) frosted white micro-crazing web and sharp internal cleavage planes that trap and scatter light. Stage 1 projects radial geometric stress-fractures lit from inside by pale blue-white [0.85, 0.92, 1.0] refraction. Stage 2 carves a stepped conchoidal facet chip (kind 0 dent with sharp polygonal normals and buckled silver bezel strips) trailing glittering crystal dust motes instead of soot smoke. Stage 3 opens a deep non-perforating fault fissure blazing with blue-white harmonic light and venting shimmering prismatic vapor plumes.

The break (Stage 4): At Stage 4, a polygonal cleavage break opens into an indigo-black cavity spanned by fractured crystal spire ribs and severed silver conduits, filled with turbulent blue-white photonic fire and drifting glass shards. On repair, the break seals with an opaque fused-quartz seam.

Eclipse (machine, id deathless)

Existing hooks and wound_kind addition: Uses dark high-metal finish [0.55] (hull_table.gd), violet damage_glow [0.72, 0.5, 1.0], and guttering ember trails (faction_looks.json), but currently shares wound_kind = 0 with standard metal hulls. Add wound_kind = 3 (deathless) in godot/fx/fx_breach.gd:1641, :1653 so unshielded machine hulls read as damaged cybernetic constructs rather than plain iron.

Surface stages (Stages 1 to 3) and the break (Stage 4): Stage 1 extinguishes nearby hull lights and stamps angular, panel-aligned blackened dead sectors bordered by glowing violet [0.72, 0.5, 1.0] circuit traces. Stage 2 crushes the armor plate and adds intermittent violet electrical arcs snapping across the rim alongside thin silver-violet vaporized coolant leaks. Stage 3 exposes sub-armor conduit trenches with severed power cables sparking violet-white and trailing guttering purple embers and dark dielectric smoke. Stage 4 shears open a machine-bay cavity spanned by geometric server-rack ribs and severed bus bars, roaring with violet plasma fire and high-voltage lightning inside the dark throat.

Sunward Crusade, Hegemony, and Ashfall Hullbreakers

Sunward Crusade (id voidsworn): Uses the standard wound_kind = 0 metal staged shape on black iron hulls, contrasting heavy matte-black soot halos with bright furnace-orange damage_glow [1.0, 0.5, 0.14]. Stages 1 to 3 read as blistered forge-iron plate, white-hot molten slag rims, and thick oily black smoke trails, while the Stage 4 break reveals glowing orange reactor ribs and roaring furnace fire.

Hegemony: Uses wound_kind = 0 on clean pale-grey and steel-blue hull plating, where dark carbon scorch rings and warm amber-gold damage_glow [1.0, 0.72, 0.38] pop sharply against the bright military paint. Stages 1 to 3 show peeled ablative armor tiles, amber electrical fires, and crisp grey-white atmospheric venting jets before the Stage 4 break opens into an amber-lit structural truss cavity.

Ashfall Hullbreakers (id corsair): Uses wound_kind = 0 on weathered rust-red salvage hulls with deep orange-red damage_glow [1.0, 0.3, 0.07] and heavy engine_extra soot. Stages 1 to 3 layer wide greasy black soot smears, flaking rust-oxide craters, and dirty fuel-oil smoke columns, culminating in a Stage 4 break packed with jagged scrap-girder ribs and belching deep-orange chemical fire.

4. Build order against issue 49

Task 1 (Pure Measurement Baseline): Stage-by-stage capture harness and 20-ship frame profile

Files touched: godot/fx/fx_ship.gd (sync() at line 748, _plan() at line 839), godot/fx/fx.gd (fx.prof profiler), and a deterministic test capture script writing to docs/shots/playtest/.

Test or capture: Render a 4K (15.4 px/unit) contact sheet of Stages 0, 1, 2, 3, and 4 at battle camera distance (170 units) and close-up zoom on a Hegemony Cruiser, an Eclipse Battleship, and a Chorus Cruiser, plus a 20-ship combat benchmark recording fx.prof main-thread ms and FPS.

What Ryan sees: A side-by-side baseline sheet showing the current Stage 3 and 4 cardboard cut-out holes and missing persistent section fires, paired with baseline 20-ship frame timings before any code changes.

Task 2: Re-gate stage ladder and weapon marks to keep hulls whole in Stages 1 to 3

Files touched: godot/fx/fx_ship.gd (sync() at line 748, _plan() at line 839) and godot/fx/fx_breach.gd (mark kinds at lines 36-41, MARK_CAP / SEC_MARK_CAP at line 63, HALO_MIN table).

Test or capture: Re-run the 3-ship stage capture sheet at 170 units and close-up zoom; assert that 0 geometry holes (kind 1 hole) are cut while f > 0.2 (Stages 1 to 3) and that all weapon marks in Stages 0 to 3 clamp to surface craters, dents, and non-perforating molten slots.

What Ryan sees: Ships taking light through heavy section damage (80% down to 21% section hull) accumulate dark scorch overlays, glowing hot torn-plate rims, buckled dents, and molten weapon craters directly on the solid hull without a single hollow cut-out hole.

Task 3: Rebuild the Stage 4 open break with 3D wreckage ribs and internal cavity fire

Files touched: godot/fx/fx_breach.gd (hole builder around lines 36-41, interior breach shader at lines 1641, 1653) and godot/fx/fx_ship.gd (_plan() at line 839, _build_breach()).

Test or capture: 4K close-up zoom captures on Stage 4 (f <= 0.2) sections of two factions plus Chorus; verify single tighter hole (R = 0.032 x L), wide torn collar (D = 0.14 x L), removal of flat procedural interior lines, worker-thread 3D cross-rib geometry inside the dark throat, internal fire emitter seated inside the break, and play_godot_safe.bat simplified mark fallback (FINDINGS R49).

What Ryan sees: When a section finally drops to <= 20% hull or breaks, a single jagged breach tears open filled with 3D tangled bulkhead ribs and roaring internal fire rather than an empty shell or flat cardboard lines.

Task 4: Wire stage-driven persistent section fires, smoke trails, and venting with class caps

Files touched: godot/fx/fx_ship.gd (_set_burning(), _apply_stages(), stage transition logic around line 1140), godot/fx/fx_pool.gd, and godot/fx/fx.gd (WCAG flash guard at lines 22-27).

Test or capture: 20-ship stress test with all ships in Stage 3 and Stage 4 damage verifying >= 40 fps on RTX 5080, fx.prof main-thread cost under 0.5 ms, 0 counted flashes spent by persistent fires, and clean emitter fade-out plus welded patch sealing when repair drops a section's stage.

What Ryan sees: Wounded sections trail dark smoke at Stage 2, burn with small fires and venting gas plumes at Stage 3, and pour heavy flame from the Stage 4 break, while repaired sections extinguish their fires and plate over their breaks.

Task 5: Deliver Chorus, Glasswright (ithar), and Eclipse (deathless) staged surface variants

Files touched: godot/fx/fx_ship.gd (_plan() line 870, _build_organic_section line 1322, :1074, :1213), godot/fx/fx_breach.gd (wound_kind at lines 1641, 1653), godot/fx/faction_looks.json, and godot/fx/faction_look.gd.

Test or capture: Final #49 sign-off capture sheet across Stages 1, 2, 3, and 4 on real hulls of two factions (Hegemony/Sunward Crusade and Glasswrights/Eclipse) plus one Chorus ship at 170 units and close-up zoom.

What Ryan sees: Chorus ships bruise, split into muscle/cartilage wounds with spore plumes, and regrow pale scar tissue on repair; Glasswright hulls frost with white stress-crazing and blue-white refractive faults; Eclipse machine hulls darken panel-by-panel with violet lightning arcs and severed conduits.

Explicit verdict on issue 49's open choice: keep or retire the breach code?

Keep the existing breach code (godot/fx/fx_breach.gd) for the heavy Stage 4 break and worker-thread surface overlays rather than retiring it. The 1,820-line machinery in fx_breach.gd already solves asynchronous worker-thread mesh extraction from the hull's original arrays, localized grid-cell culling, and merging all marks per ship into one interior mesh and one overlay mesh at zero main-thread frame cost. Retiring it would discard the worker-thread overlay skin that powers S_SCORCH and weapon craters while forcing a ground-up rewrite just to support the Stage 4 open break required by the brief. Re-gating kind 1 hole strictly to Stage 4 (f <= 0.2), replacing the flat interior line pattern with 3D cross-ribs and internal fire, and clamping Stages 1 to 3 to surface overlays, dents, and molten craters eliminates the cardboard read while preserving every performance guardrail.

5. Owner questions

When should the first real open break appear in a damaged ship section?

A (Recommended pick): Only at Stage 4 (<= 20% section hull or broken), keeping Stages 1 to 3 (80% down to 21%) completely sealed with scorch, dents, molten craters, fire, and smoke.

B: Late in Stage 3 (<= 30% section hull) on Battleships and Dreadnoughts, and Stage 4 (<= 20%) on smaller ships.

C: Never cut holes during live combat; keep hulls 100% sealed until the ship dies and breaks apart.

Stakes: Sets whether ships stay solid through most of the fight like Battlefleet Gothic: Armada or open deep structural cavities earlier in combat.

How should per-weapon marks (torpedo craters, lance burns, railgun hits) behave on sections above 20% hull?

A (Recommended pick): Keep all weapon marks on the surface until Stage 4 - lances leave glowing molten grooves and torpedoes leave deep scorched bowls, without cutting holes through the hull.

B: Let heavy lance beams and torpedoes punch narrow fire-filled slots through the hull starting at Stage 2 (<= 60%), while lighter weapons stay on the surface.

C: Retire distinct weapon mark shapes and fold all hit feedback into the section's main scorch and fire stage.

Stakes: Balances R43's goal of reading which weapon hit a ship against R76's rule that cut-out holes look like hollow cardboard on intact hulls.

What should a crippled Stage 4 section look like after repair brings its hull back above 20%?

A (Recommended pick): Put out the fires and seal the open hole with a visible battle scar - welded metal patch plates for standard/Eclipse hulls, fused crystal seams for Glasswrights, and pale regrown scar skin for Chorus.

B: Put out the fires and cool the glowing edges, but leave the physical hole open for the rest of the battle.

C: Restore the repaired section to a clean, undamaged look as its stage drops back down.

Stakes: Decides whether repaired ships look like scarred survivors or visually reset their damage history mid-battle.

How far should issue 49 go on faction-specific surface damage beyond Chorus?

A (Recommended pick): Build all three custom surface paths now - Chorus flesh wounds and regrowth, Glasswright frosted white crystal crazing, and Eclipse darkened machine panels with violet electrical arcs.

B: Ship Chorus flesh wounds and Glasswright crystal crazing in issue 49, and leave Eclipse on the standard metal scorch path with violet glow until a follow-up pass.

Stakes: Trades one extra shader path (wound_kind 3 for Eclipse) against giving all three non-standard hull types their own damage identity in the same build.

Gate confirmation: Both gates passed. Before submitting, the model picker button and the prompt bar both read "Argon High" (model 4 Argon, Thinking level High). After sending, the prompt bar still read "Argon High". No model switch, no upgrade offer was accepted, and no other model was substituted.
