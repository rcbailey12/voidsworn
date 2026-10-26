# Ships for Godot (A4 kit rollout)

Every ship here is built by one script chain in `tools/blender/a4/` (see `tools/blender/a4/README.md`) from the game's AI hulls
(`hulls_hi/`), with the hand-built kit, faction surface detail, baked paint, hard points and wreck pieces. Owner of this folder: the A4
ships helper. Decisions behind the format: `tools/blender/a4/K1_DECISIONS.md` (Ryan can veto any of them).

## Where the files live (Oct 26 2026)

The full glb files and maps (about 10 MB a ship) stay **out of the repo** until Ryan decides on large-file storage. Every A4 ship job on
Ryan's PC copies the finished files into the game build at `Downloads\voidsworn_test\build\godot\assets\ships\<CODE>\` (where G2's
asset builder reads them into `gen/ships`, `gen/damage` and `gen/wreck`). The repo carries `manifest.json` here (per ship: name,
faction, class, hard point counts, breach count, every file with its size and sha256, the PC path) and `previews/` (the studio views and
the breach damage review per ship, about 100 KB each), so a review can be matched to the exact build on the PC.

## What is in a ship folder

`godot/assets/ships/<CODE>/`, for example `C13s_23/`:

| File | What |
|---|---|
| `<CODE>.glb` | the ship: one mesh, one material, plus an empty node per hard point (children of the ship node) |
| `<CODE>_wreck.glb` | the death pieces: the same ship cut into 3 to 10 chunks, one node per chunk |
| `<CODE>_damage.glb` | real hull damage per breach anchor (R39): `breach_<n>_hole` and `breach_<n>_heavy` (see below) |
| `<CODE>_base.jpg` | albedo (sRGB), 2048 |
| `<CODE>_orm.jpg` | R occlusion, G roughness, B metal (glTF convention), 2048 |
| `<CODE>_normal.jpg` | tangent-space normal map (MikkTSpace, OpenGL +Y), 2048 |
| `<CODE>_emissive.jpg` | windows, lenses, engine throats (sRGB), 2048; the material sets `KHR_materials_emissive_strength` 4 |

Both glb files point at the same four images by relative URI, so the paint is stored once. The glb files carry no tangents: Godot's
importer generates MikkTSpace tangents (the method the bake used). A 4096 set of the same files lives on Ryan's PC in
`Downloads\voidsworn_test\a4\godot_hi\` for a max-detail option (too big for the repo).

`ships.json` lists every ship: name, faction, class, size band, game length (world units), file paths, triangles, wreck chunks and hard
point counts.

## Frame and scale (K1 decision 2)

- **+X is the bow, +Y is up, -Z is port, +Z is starboard** (standard glTF, right-handed, true chirality: the ship looks exactly as it does
  in the Babylon game). Godot's own forward is -Z, so a ship node that should fly along its parent's -Z needs a 90 degree turn about Y.
- Length is about 1.0 (x from about -0.5 to +0.5). Scale by the class length (`length_world` in the glb's extras and in `ships.json`;
  `render/hull_table.gd` CLS_LEN times SHIP_K on the board).
- Colours: `asset.extras.palette` holds the faction's engine and window colours (FAC3D `eng` and `win`, linear). Weapon colours stay in
  FAC3D `bolt` and `beam`, shields in `shield` (K1 decision 3).

## Hard points (K1 decision 7)

Empty nodes under the ship node, each with glTF `extras` (Godot imports them as node metadata):

| Name | Meaning | Orientation |
|---|---|---|
| `hp_w<slot>_<weapon>_<arc>_<n>` | a weapon mount for slot `<slot>` of the ship's data.js weapon list (0-based), e.g. `hp_w0_autocannon_T_0`; the muzzle point | -Z = rest firing direction, +Y = away from the hull |
| `hp_eng_<n>` | an engine exit (the plume starts here) | -Z = plume direction (aft); `extras.radius` = bell radius |
| `hp_bay_<n>` | a hangar mouth (carriers) | -Z = launch direction |
| `hp_breach_<n>` | breach anchor candidates spread over open hull (no parts there) | +Y = outward surface normal |
| `hp_core` | the hull's centre of mass (death explosion origin) | identity |

`extras` on weapon mounts: `kind`, `size` (S, M, L, XL), `arc` (F, T, P, S as in data.js), `arc_deg` (half angle of the firing arc),
`slot`, `weapon` (data.js weapon kind), `radius` (mount radius, ship units). No mount ever rests aimed backward (CLAUDE.md), and the build
refuses one: port (P) mounts sit at z < 0 and starboard (S) mounts at z > 0 (checked when the file is written).

## Wreck and death pieces

`<CODE>_wreck.glb` has one root node `<CODE>_wreck` and children `chunk_00`, `chunk_01`, ... Each chunk:

- is placed so that, with every chunk at its stored translation, the pieces reassemble the intact ship exactly;
- has its node origin at the chunk's own centre of mass (spin it about its origin and it tumbles naturally);
- carries `extras.volume` (ship units cubed; scale by length cubed for mass) and `extras.tris`;
- has two surfaces: the hull skin (the ship's own material, a lighter mesh than the live hull) and the cut faces (`wreck_interior`: dark
  scorched metal with a faint ember emission, for the effects helper to glow, char or swap).

Chunk counts by size band: S 4 (craft 3), M 6, L 8, XL 10. Cuts run mostly across the hull, some along it or at a slant, so a ship
breaks like a ship. Suggested use (for the G4 effects helper): on death hide the live ship, spawn the wreck at the same transform, give each
chunk a rigid body with mass from volume, an outward impulse from `hp_core` plus the ship's velocity and a little spin, and fade or drift
them as hulks.

## Breach damage (R39, format agreed with G4; godot/fx/API.md section 14)

- The ship glb's root mesh is the hull minus the breach patches; its children `skin_<n>` (the patch a hole replaces) and
  `skin_<n>_heavy` (the wider patch heavy damage also tears away, reaching through thin hull so the silhouette loses a bite) complete
  the intact ship. Same material as the hull, identity transforms. `n` matches `hp_breach_<n>`.
- `<CODE>_damage.glb`: root `<CODE>_damage` (parent it under the hull mesh's parent with the hull mesh's transform; everything is in the
  hull's own frame). Children `breach_<n>_hole` and `breach_<n>_heavy`, hidden at start. Surfaces by material: `<CODE>_hull` (torn
  plates bent outward, in the ship's own paint), `damage_interior` (bare plate backs, cavity wall), `damage_frame` (frame rings,
  stringers, deck layers, conduits), `damage_glow` (fire glow, lit conduit bands, sparking torn conduit ends; emissive strength 1, G4
  scales it), `damage_edge` (hot torn plate edges; strength 0.5). Chorus guts are flesh and bone; Ithar and Deathless glow jade and green.
- Node extras: `kind` (breach_hole, breach_heavy), `breach`, `section` (prow, mid, eng), `p`, `n` (anchor point and outward normal),
  `r` (radius), `hides` (skin nodes to hide).
- Swap: ladder stage 3 shows `breach_<n>_hole` and hides `skin_<n>`; stage 4 shows `breach_<n>_heavy` and hides the hole, `skin_<n>`
  and `skin_<n>_heavy`. Squadron craft have no breaches. Generator: `tools/blender/a4/damage.py` (numpy, from the exported arrays).
- Per-weapon damage (R43), on one anchor per section (prow, mid, eng): `breach_<n>_lance` (clean round burn-through, molten lip,
  glowing bore), `breach_<n>_torp` (blast crater: plating dished inward over the wide patch, ragged blown centre, guts),
  `breach_<n>_splash` (plasma: no hole, a melted dimple with a glowing pool and spatter), `breach_<n>_gauss` (small punched hole,
  petals flicked outward). extras `kind` = `hit_<kind>` plus `breach`, `section`, `p`, `n`, `r`, `hides`.
- Ram: `ram_bow` (the first tenth of the ship squashed back and folded, in its own paint) replaces the ship glb's `skin_bow` child
  (and any breach skins in that zone, listed in `hides`).

## Ithar sails

Ithar sail membranes are a second surface of the ship mesh with the material `<CODE>_sail` (alpha blend, double-sided, the same maps).

## Import notes for the Godot side

- **Texture rule for this folder (Muse's Godot shipping review, adopted):** every map imports as VRAM Compressed, High Quality (BC7) for
  `_base`, `_orm` and `_emissive`; `_normal` as BC5 with Normal Map on; mipmaps on for all. Nothing here is HDR, so no BC6H. `*.import`
  files are git-ignored in this project, so the rule has to live in the importer that reads the folder: the G2 asset builder
  (`render/build_assets.gd`, which already compresses to S3TC/RGTC) or a project-level import default. Never ship them uncompressed:
  an uncompressed 8K map is about 341 MiB with mips; at the repo's 2048 a ship's four maps are about 85 MiB uncompressed against about
  21 MiB as BC7/BC5.
- Godot imports these glb files on its own when the editor opens the project. The G2 asset builder
  (`render/build_assets.gd`) can instead read them with GLTFDocument at build time, like the A2 flagships; the relative image URIs
  resolve from the glb's folder either way.
- Ship nodes are named by code; mesh and material are named `<CODE>` and `<CODE>_hull`.
- Nothing here depends on the old `hulls_hi` JSON files; the game's Babylon build is untouched.
