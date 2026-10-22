# Voidsworn backlog (everything planned or discussed, Oct 22, 2026)

One list so nothing is lost between chats. Details live in the linked docs. Order inside each section = suggested order.

## 1. Ships: finish the Pyre-Barge (C19_51), the worked example
- [ ] Real material texture: CC0 scanned sets (downloaded to `Downloads\voidsworn_test\textures`) blended in by world position. `docs/ship_pipeline/TEXTURE_PASS.md`
- [ ] Dress the big plain parts: sponson boxes and hoods, front armour slabs, side gun tanks and drums, engine block (`docs/feedback/2026-10-22/`)
- [ ] Calm the flanks if wanted (fewer small chips, bigger panels lead)
- [ ] Brightness re-tune now that hulls light correctly (pale hulls blow out in full sun)
- [ ] Kit texture atlas uses 15 to 38% of its space: pack better or split (blurry parts up close)
- [ ] Studio renders don't show the finish maps (render_multi.py)
- [ ] Blob sweep sign-off: 9-cell grid in `docs/ship_pipeline/SHIP_QUEUE.md` (`BLOB_SWEEP.md`)

## 2. Ships: the other 35 hulls
- [ ] Real-GPU (not SwiftShader) and Pixel check: speed, anti-aliasing, shadows, 20-ship stress test with an fps counter, loading per battle
- [ ] Publish a test build for the Pixel and PC (live artifact)
- [ ] Ship 2 with the kit: template + per-ship section table, then the rest in `SHIP_QUEUE.md`
- [ ] Ship files in GitHub large-file storage with a manifest (owner pick)
- [ ] Chorus and Ithar approaches (organic and porcelain hulls don't fit the Corsair kit); Ithar sails in engine
- [ ] Engine glows and plumes line up with the modelled engines; turret mounts on the new shapes
- [ ] Ithar big ships oddly oriented (I16, I8: AI_HULL_YAW)
- [ ] Wreck debris and death pieces from the real hulls (replace box/T shapes)
- [ ] Station, transport and beacon objectives get the same treatment
- [ ] Graphics review leftovers: `docs/ship_pipeline/GRAPHICS_REVIEW.md` (items 6, 8, 9)

## 3. World and effects
- [ ] Backdrop oddities: rocks clipping into moons, two identical moons, stray "distant traffic" ships, rim rock wall reads as a slab
- [ ] Asteroid rebuild (faceted blockers, variety), Blender world pass (rock libraries, nebula renders, explosion footage)
- [ ] Effects, doubled down: every weapon family its own look, plasma nothing like lasers, visceral and punchy (`NEXT.md`)
- [ ] Live shaders: black-hole lensing with accretion disc, flowing beams and shields
- [ ] Gold selection ring too bright at close zoom on the Pixel (re-check)
- [ ] Cleanup: points-only ship build, pooled effect meshes, reflection probe per battle

## 4. Game
- [ ] v54 factions and rewards: doctrines (Ithar and Chorus first), boon decline and reroll, rule-changing boons, legendaries per patron, rarity, refit track (`NEXT.md`)
- [ ] AI polish: response curves, hysteresis, debug score overlay
- [ ] Sector 1 balance (owner won 4/4 with no losses on v53.2)
- [ ] Music: adaptive layered score (style still to pick), recorded sound packs are OK

## 4b. Career and story mode (owner, Oct 22: "make it into a mini-career and story mode")
- [ ] Progression that feels rewarding: meta-unlocks between runs, ranks and medals, persistent upgrades, clearer reward moments after battles
- [ ] Characters: an admiral per faction with a portrait, voice/personality lines, and their own goals; recurring rival admirals
- [ ] Personalisation: name your admiral and flagship, ship paint/insignia, crest, title earned by playstyle
- [ ] Story: a short campaign arc per faction (intro, a few key battles, ending), story beats between sectors, choices with consequences
- [ ] Career: the admiral carries over between runs (record, renown, retired captains), with a career screen
- [ ] Scope questions for the owner before building (how long a story, how much text, voice or none, art style for portraits)

## 4c. Whole-game health pass (owner, Oct 22: "optimization, bug fixes like we found with the graphics but more globally")
- [ ] Code-wide audit like the graphics review: every system (battle rules, AI, campaign, UI, save/load, audio, effects), looking for
      hidden bugs, dead code, leaks across battles, things that only work by accident
- [ ] Performance on a real GPU and the Pixel: frame time per system, draw calls, texture memory, load time per battle, battery/heat
- [ ] Automated checks: extend smoke tests (softlocks, every faction and map, long runs), console-error capture on every run
- [ ] Write findings to a review doc with a fixed/open table (same format as GRAPHICS_REVIEW.md)

## 5. Process and tooling
- [ ] Outside audits: texture pass (`TEXTURE_PASS.md`), earlier audits merged (`AUDIT_SYNTHESIS.md`). Outside agents work in `contrib/<name>/`
- [ ] Engine: stay on Babylon; revisit Godot after v55 (parking lot)
- [ ] PC runner: give each job its own staged file name (stale copies re-ran old jobs)

## Open questions for Ryan
- Music style for the adaptive score.
- Calm the Pyre-Barge flanks, or keep the busy ork look?
- Career/story mode: how long a story, how much text, voice lines or none, portrait art style?
