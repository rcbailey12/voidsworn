# Ships for Godot (A4 kit rollout)

Every ship here is built by one script chain in `tools/blender/a4/` (see `tools/blender/a4/README.md`) from the game's AI hulls
(`hulls_hi/`), with the hand-built kit, faction surface detail, baked paint, hard points and wreck pieces. Owner of this folder: the A4
ships helper. Decisions behind the format: `tools/blender/a4/K1_DECISIONS.md` (Ryan can veto any of them).

## What is in a ship folder

`godot/assets/ships/<CODE>/`, for example `C13s_23/`:

| File | What |
|---|---|
| `<CODE>.glb` | the ship: one mesh, one material, plus an empty node per hard point (children of the ship node) |
| `<CODE>_wreck.glb` | the death pieces: the same ship cut into 3 to 10 chunks, one node per chunk |
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

## Import notes for the Godot side

- Godot imports these glb files on its own when the editor opens the project (textures compressed to VRAM formats). The G2 asset builder
  (`render/build_assets.gd`) can instead read them with GLTFDocument at build time, like the A2 flagships; the relative image URIs
  resolve from the glb's folder either way.
- Ship nodes are named by code; mesh and material are named `<CODE>` and `<CODE>_hull`.
- Nothing here depends on the old `hulls_hi` JSON files; the game's Babylon build is untouched.
