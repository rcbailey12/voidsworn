# Texture pass: brief for auditors and builders (Oct 22, 2026)

## Why

Owner on Pyre-Barge v14 ("pretty close"): "cleaning up the big blocky and undetailed areas... and adding in fine detail/texture.
Broadly, I think texture of the assets is what is missing. We've forced some of it with paint but I think that is what might help with
the clay/generated looks." Screenshots: `docs/feedback/2026-10-22/`. Current state: `docs/ship_pipeline/c19_example/v14_pyre_barge.webp`.

Today every bit of surface grain is procedural noise baked into the paint (`tools/blender/project_paint.py`, PAINT=proc) plus a
light shader layer (`gfx3d.js`, HullFx). Nothing comes from real material photos.

## The material library

- Source: ambientCG (https://ambientcg.com), license CC0 (free for any use, no credit needed). 2K JPG sets (colour, normal,
  roughness, metalness where present, AO, displacement).
- Downloaded by `tools/pc/tex_dl.ps1` (run through the PC runner with `tools/pc/jobs/tex_download.bat`, or double-click the .ps1)
  into `Downloads\voidsworn_test\textures\<AssetId>\`, with `textures\index.csv` listing each set, the search it came from and its page.
- Searches: painted metal, rust, metal plates, scratched metal, corrugated steel, diamond plate, grime, metal (6 most popular each).
- The sets are not in the repo (size). The index lists them; re-running the script fetches the same sets.

## Plan (Claude's pick, not built yet)

1. Material texture on every surface (first, because it fixes all 36 ships at once): blend 2 to 4 sets (painted metal, rust, worn
   steel, grime) by world position (triplanar) in the HullFx shader. Use them as detail on top of the ship's own paint: the detail
   normal and roughness everywhere, the colour only as a soft overlay. Masks: rust where the paint is rust-coloured, worn steel on raised
   edges (curvature or the baked finish map), grime in cavities. Tile size about 1 to 2 game metres; fade by pixel footprint (no shimmer).
   Alternative: bake the same blend into each ship's paint in Blender (sharper, but bigger downloads and per-ship work).
2. Dress the big plain parts with the detail kit (`tools/blender/hs/detail_lib.py`): sponson boxes and hoods, front armour slabs, the
   side gun tanks and drums, the engine block. Panel seams, access hatches, vents, bolts, weld lines, small dents, chipped edges.
3. Check on a real GPU and the Pixel (all shots so far are SwiftShader).

## Questions for an audit

1. Which 4 to 6 sets from `index.csv` best fit (a) Corsair rusty red plating, (b) bare worn steel, (c) grime, (d) the other factions?
2. Triplanar in the shader vs baked into the paint: which gives the better look per MB on a Pixel 10 XL? Cost of 4 extra 2K textures?
3. How should the detail texture scale relate to ship size so a 6 m frigate and a 26 m barge read the same?
4. How do we keep it from reading as a repeating wallpaper (tiling)? Stochastic tiling, two scales, rotation per plate?
5. What else makes a model read "AI generated" or "clay" that texture alone will not fix? Look at the screenshots.

## Rules for outside agents

Work in `contrib/<your-name>/` only (see `AGENTS.md`). Reviews go in `contrib/<your-name>/reviews/texture_pass.md`. Plain words, give a
pick. Free tools and CC0 assets only.
