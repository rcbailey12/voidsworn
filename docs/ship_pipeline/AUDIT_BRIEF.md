# Audit brief: AI ship models for Voidsworn

For outside models (ChatGPT, Gemini, Argon, Antigravity and others) asked to audit or revise this work. Read this first, then
`README.md` (the pipeline), `BLOB_SWEEP.md` (the "done" check) and `SHIP_QUEUE.md` (status of all 36 hulls). Put your findings in
`contrib/<your-name>/reviews/` (see `/AGENTS.md`). Don't edit anything outside your folder.

## The goal (owner's words)

- Ship models that "look just like the concepts" from every angle. Not simplified boxes.
- "It should look right from all angles."
- Free tools only: "I'd like to skip paid versions."
- "Don't get stuck with the current approach... are we forcing the slim down for artificial constraints? ... be creative and ambitious
  here, not constrained."
- Hosting can move anywhere if needed: "vercel, supabase, github pages, etc or a specific app we create and download."

## History (Oct 21 2026, one long day)

1. **Hunyuan 3D meshes (the original in-game ships).** Owner: "everything still feels pretty low poly". The cause is the meshes
   themselves, soft and lumpy at any triangle count.
2. **Bake-off on the Pyre-Barge and the station:**
   - A, Hunyuan at higher octree: no gain.
   - B, Blender clean-up: no gain.
   - C, TRELLIS.2: picked first.
   - D, pure Blender hard-surface rebuild: owner said "sparser... a bit like the boxy issue".
3. **TRELLIS.2 rejected.** Owner: "trellis is definitely too stubby... significantly off from the concept art in material ways, both in
   length, detail, sharpness, everything." The ragged look in game came from our 38k decimation (proved by A/B tests).
4. **External adversarial review (3 agents).**
   - One image can't pin a ship's length.
   - Generate a true side view instead.
   - Project the concept's own paint onto the model.
   - Free tools can't guarantee concept-sharp close-ups. The fallback is a Blender rebuild of the hero parts on an exact AI shape guide.
5. **Current pipeline.**
   - Qwen-Image-Edit side, front and back views. Owner approved the side: "that new view looks perfect".
   - Pixal3D multi-view mesh at full detail: about 2M triangles, compressed with meshoptimizer.
   - The concept painting and the generated views projected back as paint.
   - Hand-built Blender parts wherever the AI blurs.
6. **Owner feedback on the Pyre-Barge, in order:**
   - "it's certainly much closer... the finer details, e.g. rocket pods or guns are inconsistent in size and scope to each other and get
     sort of mashed together... it's very noticeable here."
   - Picked "Bright and then hand built", then agreed to paint the hand-built parts by projection.
   - "Definitely much better. There's still some blob and soft aspects like near the bridge/top and we should make sure that the weapon
     and other bolt on aspects actually make some sense for the placement. Not as big of a deal for Corsair..."
   - "Some guns can face forward for the prow and stuff but yeah otherwise perfect."
   - "bigger issue is the grey blob of rocket pods that looks like an unpainted model from a tabletop game and the front of the ship still
     being a bit wavy/messy... For Corsair, painting mismatch is actually kind of on theme."
   - "the big guns on the side still seem misshapen and blobby too."
   - "Anything else we missed that's similar to that? We should ensure we catch all of those for all other ships." This led to
     `BLOB_SWEEP.md`.
   - Latest (kit v7): "The front plates look a bit out of place. It's both the color and the size/placement of them. The top of the bridge
     with antennae also looks a bit plain and sparse."
7. **Kit versions:**
   - v3: bridge tier.
   - v4: rebuilt bow and hand-painted rack.
   - v5: side casemates and stern guns.
   - v6: side blocks, front plates, thrusters, stern house, tanks.
   - v7: plates as a dark stack.
   - v8 (draft, **not run on the PC**): bridge-top dressing, which looks better; plates as a 2x3 grid on a red skin, which looks like
     stairs, with AI debris still sitting on top of it.

Renders are in `c19_example/`. Compare them with `concepts/C19_51.webp`.

## Known open issues

- Front armour plates on the forward slope: no design yet that matches the concept. AI debris (thin crossed sticks) still sits on the
  slope above the plates. The v8 draft is in `tools/blender/hs/c19_kit.py`.
- The hull's big flat panels are still the AI surface, so they are a little wavy up close.
- Paint brightness: the kit paint is levelled separately from the hull. Gain is clamped at 0.5 for the kit and 2.35 for the hull, both
  "projected from the same pictures", so the matching rests on a 0.3 self-light fudge in the game material.
- The hand-built parts are positioned with hard-coded coordinates per ship, measured off the AI hull. 35 ships remain, so this needs to
  be faster (automatic detection of mangled regions?).
- Chorus (bio-ships) and Ithar (sails) don't fit a mechanical "bolt-on" kit. No approach yet.
- Performance: no 20-ship stress test yet with 1-2M triangle hulls (desktop .vsm is about 8-14 MB each, phone about 3.5 MB).

## What we'd like audited

1. Is this pipeline the right one for 35 more ships, given free tools only and a non-coder owner? What would you change or replace?
2. `c19_kit.py`: placement mistakes, rule breaks (`BLOB_SWEEP.md` section 3), parts that don't match the concept.
3. A better design for the front armour plates and the bridge top, judged against the concept.
4. Ways to automate the blob sweep and the cut/measure step: find thin debris, wavy regions and blurred parts on an AI mesh.
5. The paint path (`project_paint.py`, `paint_level.py`, kit material in `ships3d.js` `aiKitMat`): a principled fix for matching kit
   and hull brightness.
6. Risks in the in-game path (`ships3d.js`: `decodeVSM`, `decodeKit`, `applyAIHull`) and in the size and performance plan.

## Where things are

- Pipeline scripts:
  - `tools/blender/`: mv_prep, project_paint, fitcam_*, lod_make, pixal_to_game, vsm_pack.mjs, render_multi.
  - `tools/pc/comfy_run.py` and `tools/pc/comfy_custom/`.
- Hand-built parts: `tools/blender/hs/c19_kit.py` and `hs_lib.py`.
- PC job files used: `tools/pc/jobs/`.
- Game loading: `ships3d.js` (search `AI_VSM`, `decodeVSM`, `decodeKit`, `aiKitMat`, `applyAIHull`).
- Project history and decisions: `HANDOFF.md`, `NEXT.md` ("Ship shapes"), `PROGRESS.md`, `CLAUDE.md` / `AGENTS.md`.
- The heavy steps only run on the owner's PC (RTX 5080). Auditors can read and propose, but can't run them.
