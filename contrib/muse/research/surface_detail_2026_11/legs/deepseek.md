# DeepSeek leg (writer), issue 200

Gates: DeepThink ON, Search ON, verified by the browser runner before sending (visual toggle state; the page checkbox field disagreed and the visual state was double-checked by toggling off and on). Chat: chat.deepseek.com, titled "Surface detail standard draft". Filed raw below; superscript citations in the original are shown as [number].

---

Draft Close-Range Surface Detail Standard for Ships and Stations (Issue 200)

0. Camera anchors and derived scales

Battle camera at about 170 units: 7.5 px per unit at 1080p (issue 188 synthesis). The 41.6-unit Pyre-Barge spans 7.5 * 41.6 = 312 px, matching the pack's "about 310 px." Close zoom at 46 units: 7.5 * (170/46) = 27.7 px per unit, matching the pack's "about 28." Close zoom at 30 units: 7.5 * (170/30) = 42.5 px per unit, matching "about 42." A 0.5-unit feature is 0.5 * 27.7 = 13.9 px at 46 units and 0.5 * 42.5 = 21.3 px at 30 units. The standard therefore specifies detail per distance band, not one density for all ranges.

1. Clause set

D1. Detail kinds per distance band.
- Battle band (170 units): only geometry features at least 2 units across. These are silhouette-internal features: mounted equipment pods, antenna arrays, sensor housings, engine bells, docking hatches, heat radiators, armour plate stacks, gun barrels, dishes, scoops, folded claws, rocket clusters. No mesh detail below 1 unit at this band; below 1 unit is trim, decal or normal work only.
- Close band (46 and 30 units): geometry features at least 0.5 units across. This band covers clamp housings, hatch rings, dish and dome tops, dock lip frames, sensor heads, and similar 0.5 to 2 unit elements.
- Below 0.5 units: never mesh at any band; trim sheet, decal or normal only. This matches the pack's read rule and the principle that features smaller than a pixel are wasted. [45]

D2. Minimum feature size at 1080p.
- Battle band: 2 units = 15 px at 170 units. Features smaller than 15 px do not read as shape.
- Close band: 0.5 units = 13.9 px at 46 units and 21.3 px at 30 units. Threshold 0.5 units is INFERRED, chosen because it is the pack's floor for wasted geometry and still gives at least 13 px at the closest judged zoom.

D3. Maximum plain flat area per face.
- Battle band: no single unbroken flat face larger than 6 x 6 units (36 square units, about 45 px across at 170 units). This is INFERRED; no web source gives a 6 x 6 unit flat-area limit.
- Close band: no single unbroken flat face larger than 3 x 3 units (9 square units, about 83 px across at 46 units). INFERRED. This is 1.5 times the S2 floor at close range, forcing at least one break per close-inspected face.
- What breaks a flat face: a construction edge, a trim line at least 0.5 units wide, a mounted detail at least 1 unit proud, a recess at least 0.5 units deep, or a deliberate faction seam. Paint-only value changes do not break a face for this rule.

D4. Detail density and spacing.
- Battle band: at least one detail cluster per 100 square units of hull surface, where a cluster is 3 to 8 elements each at least 2 units across. Minimum spacing between clusters 4 units, matching the pack's 4-unit noise gap.
- Close band: at least one detail element at least 0.5 units across per 25 square units, with a minimum element spacing of 2 units. Cluster evidence is visual grouping of 3 or more features in a 3 x 3 unit area, not scattered singles; this is INFERRED, anchored only on the pack's 4-unit noise gap at battle band.

D5. Interlock with readable-paint clauses S1 to S12.
- D5.1 (S2 plate floor): any geometry detail that creates a paint zone must be at least 2 units across. Detail below 2 units cannot create a new paint zone; it must sit inside an existing zone.
- D5.2 (S5 wear masks): detail geometry provides real edges for curvature and edge-wear masks, but detail must be clustered so wear masks fire in localized bands rather than everywhere. A surface with detail density above D4 is a fail because it melts the masks (issue 188 mechanism 4).
- D5.3 (S9 recesses): recessed detail must be at least 0.5 units deep to produce real geometry AO at least 12 luma below surrounding plate. Shallower recesses are paint only.
- D5.4 (S8 trim and light): geometry detail that carries faction trim must not push trim share above 2 percent of visible hull at battle band. Trim on detail counts toward the 2 percent cap.
- D5.5 (S7 grain dead band): geometry detail is structural (at least 1 unit across) and therefore outside the grain dead band. Trim-sheet content follows common 512 px/m practice unless a documented hero-detail exception applies. [21]
- D5.6 (S11 two distance bands): battle-band detail and close-band detail are separate LOD sets. The battle LOD must drop sub-1-unit features; the close LOD must keep 0.5-unit features. Detail must fade between bands via LOD, not by popping at a single distance.

D6. Detail and silhouette.
At least 30 percent of detail clusters at battle band must be silhouette-internal outline features (features that touch or define the ship's outline in the battle view, such as antennae, gun barrels, engine bells and radiators). This threshold is INFERRED. Greeble kits are useful here: a published 70-design greeble pack totals 288,000 tris, averaging about 4,100 tris per design, but clusters assembled from individual pieces can stay far below that. [11]

D7. Station additions rule (R100).
Station detail is additions only: no locked primitive may move, resize in plan, or be deleted. Height and asymmetry come from additions at least 2 units proud of their surface. Detail kinds at close zoom are the 1 to 2 unit band (clamp housings, hatch rings, dish and dome tops, dock lip frames, sensor heads); below 1 unit is trim sheet and normal content. No modelled vehicle props.

D8. LOD set requirement.
Every ship class and station kind must ship with at least three LODs: battle-band LOD (170 units), close-band LOD (46 units), and closest LOD (30 units). Published LOD practice reduces triangles by roughly 50 percent per tier and uses screen-size switch thresholds rather than fixed distances. [2] [5] For Voidsworn, the INFERRED rule is that the battle-band LOD drops sub-1-unit features entirely, and the close-band LOD retains all features at or above 0.5 units.

2. Budget table

Assumed fleet mix for a typical 20-ship battle: 8 fighters, 8 frigates, 3 cruisers, 1 capital ship, plus 2 stations in the scene.
Triangle budgets (INFERRED per class, anchored on Sins of a Solar Empire II published targets for fighter, frigate, cruiser and capital, which are 1,500, 12,500, 25,000 and 75,000 tris respectively):
- Fighter: 1,500 tris
- Frigate: 12,500 tris
- Cruiser: 25,000 tris
- Capital: 75,000 tris
- Station: 20,000 tris design, 40,000 hard ceiling (R100)
Fleet triangle arithmetic:
8 fighters * 1,500 = 12,000
8 frigates * 12,500 = 100,000
3 cruisers * 25,000 = 75,000
1 capital * 75,000 = 75,000
2 stations * 20,000 = 40,000
Total = 302,000 tris, inside the R96 ceiling of about 306,000 tris.
GPU time budget:
R96 ceiling is 3.9 ms at 20 ships. R100 station design target is 0.35 ms per station, two stations = 0.70 ms, leaving 3.20 ms for ships.
Total ship tris = 262,000. Ship ms per tri = 3.2 ms / 262,000 = 0.00001221 ms per tri.
- Fighter: 1,500 * 0.00001221 = 0.018 ms each; 8 = 0.146 ms
- Frigate: 12,500 * 0.00001221 = 0.153 ms each; 8 = 1.221 ms
- Cruiser: 25,000 * 0.00001221 = 0.305 ms each; 3 = 0.916 ms
- Capital: 75,000 * 0.00001221 = 0.916 ms each; 1 = 0.916 ms
Ship total 3.20 ms. Stations 0.70 ms. Grand total 3.90 ms, inside the 3.9 ms ceiling. The GPU time is INFERRED, not measured; R96 states the total ceiling only.

3. Break-line fit (R98, R99)

B1. No new geometry detail may cross an authored break line. Keep a clear band of at least 2 units on each side of a break line. Detail may sit inside the clear band only if it is a rim band (see B2).
B2. Rim bands at break lines are required (R99) and are the one allowed geometry exception inside the clear band. Rim bands must be at least 0.5 units wide and must carry matching interior faces and damage textures.
B3. Inside break pieces, full interiors are allowed and detail density may exceed D4. The intact ship must still pass D1 to D4 before break; break interiors are judged separately.
B4. The decimated dark inner liner is not a detail surface. No D1-D4 geometry detail on the liner; it gets damage textures only.
B5. Chorus flesh and bone interiors: organic break interiors follow the same clear-band rule at break lines, and detail on flesh must be at least 2 units across at battle band and at least 0.5 units at close band. Bone detail follows D1.
B6. Stations: truss and gantry members get authored damage decals at break lines instead of interior faces. No interior geometry detail on stations at break lines.

4. Pass/fail check on existing judgement sheets

The check runs on the nine-cell ship sheets (front, midship, rear; top, side, below; studio renders) and the station judgement set (plan, battle angle, 46, 30).
P1. D1 detail kinds (sheet). For each cell, list every visible geometry feature at battle band. Fail if any feature below 2 units is modelled as mesh at battle band, or if any feature below 0.5 units is modelled as mesh at close band.
P2. D2 minimum feature size (sheet plus mesh statistic). Sheet check that 2-unit features read as shape at battle band. Mesh statistic check that the smallest modelled feature in the battle LOD is at least 2 units and in the close LOD at least 0.5 units.
P3. D3 maximum plain area (sheet plus mesh statistic). Sheet check that no large unbroken flat face dominates a cell. Mesh statistic check that no face exceeds 36 square units at battle band or 9 square units at close band.
P4. D4 density and spacing (sheet plus mesh statistic). Sheet check that detail appears in clusters, not scatter. Mesh statistic check cluster count per 100 square units at battle band and per 25 square units at close band.
P5. D5 paint interlock (sheet): use the R105 battle-crop test at r=170, 1:1 pixels, greyscale, Gaussian blur radius 1 unit. Pass requires that plate zones remain at least 2 units, trim share stays at or below 2 percent, and recess AO is at least 12 luma below surrounding plate where recessed detail is present.
P6. D6 silhouette detail (sheet). At least 30 percent of battle-band detail clusters must be outline features. Count clusters per cell and check outline share.
P7. D7 station additions (sheet). Every station detail must be an addition at least 2 units proud; no locked primitive moved or resized in plan. Fail if any addition is below 2 units proud at battle band.
P8. D8 LOD set (mesh statistic). Confirm three LODs exist and that the battle LOD drops sub-1-unit features. Sheets cannot confirm LOD counts; this is a mesh statistic only.
P9. Budget (mesh statistic). Triangle count per hull and per station, summed against the budget table. Sheets cannot carry this; fail if the fleet mix total exceeds about 306,000 tris or the station exceeds 40,000 tris hard ceiling.
P10. Break-line fit (sheet plus mesh statistic). Sheet check that no detail crosses break lines and that rim bands are present. Mesh statistic check that the clear band is at least 2 units on each side.
Honest limits: the sheet can judge readability, cluster-versus-scatter, paint interlock and silhouette detail. The mesh statistic is required for exact triangle counts, exact feature sizes, exact face areas, exact spacing, and LOD manifest. A hull cannot pass on sheets alone for D2, D3, D4, D8 or P9.

5. Owner questions (at most five, each with a chair pick)

Q1. Battle-band maximum plain flat area: 6 x 6 units (chair pick) or 8 x 8 units? Chair pick is 6 x 6 because it keeps flat faces below 45 px at battle band and forces earlier break-up of large hull faces. The other option is looser and risks large empty faces at battle camera.
Q2. Close-band minimum feature size: 0.5 units (chair pick) or 0.25 units? Chair pick is 0.5 units because 0.5 units is 13.9 px at 46 units and 21.3 px at 30 units, already at the readable limit; 0.25 units would be 7 px at 46 units and is wasted geometry.
Q3. Close-band detail density: one element per 25 square units (chair pick) or one per 50 square units? Chair pick is one element per 25 square units because close zoom shows detail at 28 to 42 px per unit and an empty 50-square-unit area would read as plain at close range. The looser option saves triangles but risks plain close-ups.
Q4. Break-line clear band: 2 units (chair pick) or 3 units? Chair pick is 2 units because it matches the S2 plate floor and leaves room for rim bands. The 3-unit option is safer for break-piece separation but removes detail area from small hulls.
Q5. Pass/fail evidence: require mesh statistics for D2, D3, D4, D8 and P9 (chair pick) or accept sheet-only pass? Chair pick is require mesh statistics because sheets cannot measure triangle counts, feature sizes, plain areas or LOD counts. Sheet-only pass would be a readability check only.
All thresholds marked INFERRED are my proposed starting points for the chair to accept, modify or reject. No human-hour estimates are given because the pack gives no hour data to anchor them. Tools assumed are free or open: Blender, the existing Python kit scripts, and open image analysis for the blur test.
