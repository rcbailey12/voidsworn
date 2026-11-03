# Ship surface methods: how studios make detailed hard-surface ships without waves

Issue #112 chair synthesis. Legs: DeepSeek (writer), Qwen (writer), Argon (review and ideas only, per R81). Binding context: FINDINGS R83 (route B remesh plus PBR is out for machine hulls; route A is blocky but open with real detail; the next comparison is the Pyre-Barge, issue #111, three variants), R82 (projected concept paint dropped permanently on all 36 hulls; static kit parts merged at export, turrets separate), R81 (Argon reviews and ideas only).

## 1. Headline and ranked recommendation

Verdict: GO. The research answers Ryan's question and it confirms the shape of issue #111, with one correction to the bake recipe in variant 2 and one sharpening of how the winner should be read.

Ryan's question: is there another way to approach meshing, and would more triangles and detail in the mesh smooth out the waves?

The direct answer, agreed by both writer legs and consistent with every source either leg landed: no. A wave in an AI hull is low-frequency displacement, meaning the surface itself sits in the wrong place. Adding triangles subdivides that wrong surface; the wave gets smoother crests, not a flatter panel. A normal map does not help either, because it changes shading normals, not vertex positions, so it cannot fix a silhouette or a grazing-angle read. Studios do not solve this with resolution. They solve it by construction: build the ship in parts so no single surface is large enough to wave, keep flat panels flat, control shading with bevels and weighted normals, and carry fine detail in baked maps, trim sheets and decals instead of in the hull surface.

Ranked recommendation for the Pyre-Barge round 2 (issue #111):

Rank 1, for this ship: Variant 1, A+ rich surface. The Pyre-Barge is a flagship, its sign-off is still withheld pending a much stronger graphical upgrade (R83 context), and the owner judges by screenshots, including close views. Real geometry detail, bevelled edges with weighted normals, a greeble kit, trim panel lines and wear are the highest-control route and the only one of the three that cannot look pasted on up close. This is Qwen's rank 1 and DeepSeek's rank 2; the chair puts it first for the named ship because the Pyre-Barge is the hero case, not the average case.

Rank 2, and first for the fleet: Variant 2, clean shell plus high-pass or cavity-only bake from the AI donor. This is DeepSeek's rank 1 and the closest match to the shipped Sins of a Solar Empire II pipeline (clean quad low poly, bevel and subdivide to a high poly, align, bake). It is the only variant that scales: if its before and after crop test passes, the same clean-shell plus filtered-bake pass is the default method for the other machine hulls, with variant 1 reserved for flagships and any hull where variant 2 reads thin up close (the R82 escalation logic from issue #76 applies the same way).

Rank 3: Variant 3, reused AI chunks as kit parts, with a hard scope limit. Both legs converge here: cut-out chunks are a detail source, not a hull construction method. Safe only for small, hard-edged parts (engine housings, gun mounts, sensor arrays), cleaned, given a flat mounting face, and seated on visible mounts. Large hull sections carried over from the AI mesh carry their waves with them.

One correction to variant 2 as briefed and as written in the Qwen leg: the high-pass step must not re-centre the whole normal map to 0.5 grey. The neutral tangent-space normal is (0.5, 0.5, 1.0) in RGB, so the filter has to remove the low-frequency part of the deviation from that flat normal and then renormalize the result. Done the naive way, the bake would shade wrong even with the waves gone. The Argon review caught this in substance; the chair has verified it against the filed Qwen text and corrected it here and in section 4.

## 2. Per-method table

All artist times are INFERRED planning ranges. No studio publishes per-hull hours; both writer legs label their figures inferred and the chair keeps that label. Triangle anchors are the published Sins II targets the DeepSeek leg cited (fighter about 1,500; frigate about 12,500; cruiser about 25,000; capital about 75,000; titan about 225,000), useful as an upper anchor for a capital hull, not as a Voidsworn budget ruling.

| Method | What it fixes | Cost per hull (INFERRED) | Triangle cost | Free tools |
| --- | --- | --- | --- | --- |
| Part splitting, kit parts, greeble kits | No continuous surface large enough to wave; seams read as structure; scale sold by part density | 0.5 to 2 days for a kitbash pass on an existing kit; 3 to 6 days for a hero build placing 60 to 100 parts | Low per part and reusable; watch draw calls, merge or instance (R82: static parts merge at export) | Blender (Asset Browser, collection instances, snapping) |
| Bevelled mid-poly with weighted normals | Shading waves on flat panels; pinched or melted bevel highlights | Adds about 10 to 20 percent modelling time; 2 to 5 hours as a retrofit pass on a clean hull | Bevels add edge loops; weighted normals add zero | Blender Bevel modifier (Harden Normals), Weighted Normal modifier |
| Authored high poly to low poly bake | Fine detail lives in maps, so the shipping mesh stays clean and light | 2 to 5 days hero; 3 to 7 days where the low poly needs heavy rework | Shipping mesh stays at target; high poly is discarded | Blender Cycles bake (Selected to Active, cage), xNormal |
| Trim sheets | Panel lines, seams, rivet rows and wear with zero added geometry and one shared style | Sheet creation 1 to 2 days once, shared fleet-wide; 0.5 to 1 day UV work per hull | Zero | Blender UV editing, GIMP or Krita for the sheet |
| Mesh decals and floaters | Surface variety and marks without touching the hull surface | 0.5 to 2 days placing 30 to 80 pieces from a kit | About 50 to 500 tris per floater; texture decals near zero | Blender (Shrinkwrap or manual placement) |
| Texture-only detail at distance, geometry up close | Stops resolution being spent where the camera cannot resolve it | 0.5 to 1 day of bake and touch-up per hull | Zero for the texture layer | Blender bake, GIMP or Krita, xNormal |
| Planar flattening | The root cause: vertices off the plane they should sit on | Zero when done by construction; 2 to 6 hours to flatten an existing hull (DeepSeek allows up to a day on a hero hull) | Zero or negative | Blender (Flatten, Make Planar, sculpt Flatten brush) |
| High-pass or cavity-only bake from an AI donor | Transfers fine AI detail while rejecting the low-frequency wave | Adds about 2 to 4 hours per hull over a standard bake, once the clean shell exists | Zero | Blender bake and compositor, xNormal, GIMP or Krita |

## 3. Studio evidence by game

Sins of a Solar Empire II is the strongest evidence in the pack. The Martin Danlos ArtStation breakdown shows high poly modelling baked to a clean low poly (AO and normal), and the Sins II dev journal on baking describes the working order: quad low poly following the silhouette, holding edges, bevel or chamfer, subdivide to the high poly, align low and high, then bake. The bevel is what removes the hard, unrealistic sharp edge, and the journal warns the bake fails where low and high do not match. The original Sins art dump on Polycount shows the same pipeline a generation earlier: high res model, xNormal bake of normal and AO, 2048x4096 textures, and the artist's own reason, that a lot of small details were needed to sell the idea that these ships are huge. Detail that sells scale lives in the bake and the parts, not in hull triangle count.

Battlefleet Gothic: Armada 2: the Tyranid Destroyer Vanguard breakdown the DeepSeek leg found (Segolene Maurice, ArtStation) lists sculpt in ZBrush, retopology in TopoGun, UVs in 3ds Max. Even a miniature-derived, highly organic ship ships as a retopologised low poly with baked detail. The lesson for AI cleanup is direct: sculpt-like or generated detail is a bake source, never the shipping mesh. The Qwen leg found no BFG source and marked the game INFERRED; the DeepSeek source stands, so the chair carries the sculpt, retopo, bake point as sourced and the rest of Qwen's BFG comment as superseded.

Stellaris: two art diaries (Necroid ships, Nomads) cover the front end: theme, reference gathering, wide sketching, narrowing, then an asset sheet with material assignments handed to the 3D artist. Weak on modelling method, strong on production control: detail zones and materials are decided before modelling, which is one reason surface noise does not get invented at the mesh stage. Qwen found no Stellaris source; the diary-level points above are from the DeepSeek leg.

EVE Online: the V3 overhaul redesigned every ship onto a new shader, and the Art of Retribution process runs sketches to 3D block-outs of major sections as separate volumes to finished assets, keeping the silhouette while reworking everything inside it. For the Pyre-Barge this supports variant 2's shape: preserve the donor silhouette and masses in the clean shell, then do the detail work inside that silhouette.

Homeworld 3: the PC Gamer feature is strong on intent (ships as characters, per-weapon scarring, exposed internals on damage) and weak on modelling method, as the pack warned. Both legs use it only for the readability point: surface history and function read at RTS distance. The chair does not carry any specific Homeworld 3 pipeline claim.

Starsector is the control case: painted 2D sprites, no mesh, therefore no mesh waves, with kitbashed sprite pieces used for detail. Both legs raise it and both fence it the same way: not a replacement for a 3D Pyre-Barge, at most a distant LOD or impostor idea. The chair keeps it out of issue #111 (see owner question 5).

Weighted normals have a hard source in the Blender manual (the modifier adjusts normals by face area or corner angle to prevent shading artefacts on hard-surface models), and the Polycount hard-surface thread supports the surrounding practice: model ships as separate parts and panels, not one block, with panel detail ranging from texture-only to modelled high poly to mid-poly floater decals. No studio source names weighted normals verbatim; that studio use is INFERRED in both legs and stays labelled that way here.

## 4. Cleaning up AI-generated meshes in production

The settled pipeline, merged from both writer legs with the chair correction applied:

1. Treat the AI mesh as a donor, never as the shipping surface. Its topology is not authored for holding edges and its low-frequency form is the problem being fixed.
2. Build the clean low shell first, using the AI mesh as the reference for silhouette and mass placement. Flat planes where the hull should be flat, faired curves where it should curve. Flatten stray panels with Blender Flatten or Make Planar before anything is baked.
3. Add holding edges and bevels where the silhouette and panel breaks need to read, and set weighted normals (Face Area) with Harden Normals on bevels, so flat faces shade flat and bevel highlights stay tight.
4. Bake from the AI donor onto the clean shell with Selected to Active and a cage, so ray starts are controlled and edges do not skew.
5. Filter the bake so the waves do not transfer. Two routes, both in the #111 brief: (a) cavity-only or short-distance AO and curvature passes, which capture recesses, seams and edges and by construction exclude broad height change; use them for panel seams, vents, edge wear and grime masks. (b) High-pass the normal bake: work on the deviation from the flat normal (0, 0, 1) in vector terms, subtract a blurred copy of that deviation at a radius matched to the wave length, add the flat normal back, and renormalize every pixel. Do not re-centre all three channels to 0.5 grey; the blue channel of a neutral normal is 1.0, and flattening it destroys the vector. Work at 16-bit depth where the tool supports it so the filter does not quantize gentle gradients into new steps, and renormalize after any channel edit (Argon review, carried as an implementation note, not studio evidence).
6. Prove it with the acceptance crop #111 already requires, strengthened per the DeepSeek leg: the same wavy panel, same lighting, raw bake against filtered bake, viewed head-on and at a grazing angle. If the wave still shows in the grazing read or the silhouette, the shell is still wavy and no filter setting fixes that; go back to step 2.
7. Layer the detail that does not need the bake: trim sheet for repeated panel lines, seams and worn edges; decals for stencils, numbers, hazard marks and rust streaks (R82: decals where they earn it); greeble kit parts on visible mounts for vents, pipes, hatches and mechanical clutter that implies function and scale.
8. For variant 3 salvage, cut only small, hard-edged chunks, clean their edges, flatten the mounting face, and re-seat each on a visible mount. A chunk that needs its surface rebuilt is not salvage; fold its shape into the greeble kit instead.

## 5. What this changes or confirms for issue #111

Confirms: the three-variant structure is the right comparison. All three variants are consistent with how shipped games build clean ships, and the sources give no fourth construction method that beats them. Route B (remesh plus PBR) stays out per R83; nothing in either leg rehabilitates it.

Confirms: variant 2's clean shell is not optional detail. Both legs and the Sins II journal agree the low poly has to be genuinely clean and matched to the bake source, or the bake faithfully transfers the problem.

Changes: the high-pass recipe in variant 2 gets the section 4 correction (filter the deviation from the flat normal, renormalize, never re-centre blue to 0.5). Codex should write the bake steps that way on the #111 sheet.

Changes: variant 3 is reframed in the build notes as a detail-source variant with a size limit (small, hard-edged chunks only), per both legs.

Adds: the grazing-angle half of the acceptance crop (head-on alone can pass a bake that still waves at an angle, per the normal mapping lab result the DeepSeek leg cited: a normal-mapped quad matches real geometry head-on and fails at the silhouette and grazing angles).

Adds: a shared trim sheet is worth building inside #111 rather than after it, if the owner agrees (question 3). It is the one asset all three variants can wear, it costs zero triangles, and it keeps the three sheets comparable on the same detail language.

## 6. Screening notes

DeepSeek leg: used as the primary evidence leg. It landed the sources the pack was missing (Sins II Dev Journal 21, the BFG Armada 2 artist breakdown, two Stellaris art diaries, Starsector sprite posts, Blender manual pages). Two cuts, both caught by the Argon review and verified by the chair against the filed text: reference [61] does not exist in its source list, so the kitbash face range tied to it is dropped; reference [116] points at the original Sins art dump URL, not a trim sheet discussion, so the trim stretching rule is carried as INFERRED practice, not as a sourced claim. All of its artist times are labelled INFERRED in the leg and stay labelled here.

Qwen leg: used. Independent convergence with DeepSeek on the core answer (more triangles do not fix waves), the method set, and variant 3 last. Its cost ranges differ from DeepSeek's in places; the synthesis carries ranges that cover both rather than averaging them. One correction: its high-pass recipe as written (re-centre to 0.5 grey) is wrong for the blue channel and is replaced by the section 4 version. Its honest gaps (no BFG or Stellaris source found) are superseded by the DeepSeek finds, not held against the leg.

Argon leg: used in part, with the screening recorded in full at the top of legs/argon_review.md. It landed two real DeepSeek citation catches and the substance of the high-pass correction, plus the bake hygiene note. Most of its specific Qwen cut list does not match the filed Qwen leg (the quoted claims and bracket citations are not in that text) and is screened out; its Decal Machine idea is excluded as a paid tool under the free-tools-only rule; its Homeworld 3 splat claim rests on a portfolio index page and is not carried as verified.

Rey chair note: there is no separate blind Rey writer leg on this job. The R81 model set for #112 is DeepSeek and Qwen write, Rey chairs, Argon reviews, and the chair work here is the screening, the ranking adjudication in section 1, and the recipe correction in section 4.

## 7. Owner questions (chair picks marked)

Q1. Production default after #111: (A, chair pick) split default: variant 1 A+ for flagships and hero hulls, variant 2 clean shell plus filtered bake as the fleet default for the other machine hulls, escalating any hull that reads thin to A+ per hull. (B) A+ for all machine hulls. (C) Variant 2 for everything, flagships included.
Q2. Variant 3 scope: (A, chair pick) small, hard-edged chunks only, each cleaned and re-seated on a visible mount; anything larger gets rebuilt or folded into the greeble kit. (B) Large hull sections may be reused if they look clean.
Q3. Trim sheet timing: (A, chair pick) build one shared Hullbreaker trim sheet inside #111 so all three variants wear the same detail language. (B) Wait until a variant wins, then build the sheet for the winner only.
Q4. Acceptance test for the #111 sheets: (A, chair pick) require the before and after wavy-panel crop at head-on and grazing angles, plus an in-game screenshot at battle distance and at close zoom, before any variant is called the winner. (B) Turntable renders only.
Q5. The Starsector sprite idea: (A, chair pick) keep it out of #111 and out of the current plan; revisit only if a distant-LOD problem actually shows up in play. (B) Add a painted impostor experiment as a fourth #111 variant.

## 8. Not checked

- The chair did not re-open every URL in the legs; pack seed URLs were verified when the pack was built, DeepSeek citations were spot-checked against its own source list (which is how the [61] and [116] cuts were confirmed), and Qwen's claims were checked against the filed leg text.
- No Blender work was run for this research. The corrected high-pass recipe in section 4 is stated from the normal map encoding and the legs' sources; the #111 crop test is where it gets proven on the actual Pyre-Barge panel.
- Artist times are planning ranges inferred from workflow scope in both legs. No studio publishes per-hull hours, and Codex's recorded per-hull hours on the #111 sheets (per the #76 Q4 ruling) will replace these ranges with real numbers.
- The Sins II triangle targets come through the DeepSeek leg's cited modding summary and dev journal; the chair did not independently re-derive them from Stardock's pages.
