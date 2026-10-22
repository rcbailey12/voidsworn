# Audit synthesis (Oct 22 2026)

Three audits answered `AUDIT_BRIEF.md`:
- `contrib/codex/reviews/ship-model-audit-2026-10-21.md` (ChatGPT/Codex)
- `contrib/rey/reviews/ship-pipeline-audit.md` (Muse/Rey)
- `contrib/gemini/reviews/ship_pipeline_audit.md` (Gemini, plus drop-in code)

Claude checked their factual claims against the audited commit (`2cfbde2`) before weighing them.

## Accuracy

- **Codex: highest.** It reproduced its claims with small tests (loader branches, paint levelling, the planesnap loop) and pinned line
  numbers. Every spot-check held:
  - the jackstaff/bow-chaser clash;
  - the floating window band;
  - the crow rail is a capped disk;
  - the asset files are missing from git;
  - closeshot renders with SwiftShader (software), so our in-game shots say nothing about frame rate.
- **Rey: high, and the most useful on design.** Its spot-checks also held:
  - the bridge drums are on the wrong face;
  - an AI lump survives at the bridge front;
  - the yards run fore-aft;
  - the brace floats;
  - the funnel pair is mismatched;
  - the kit gain of 0.5 is the solver's floor.
- **Gemini: low on facts, some good ideas.** Several headline bugs are false against the real code:
  - "tanks never rebuilt": line 283 builds them;
  - "`cyl(axis=Rn)`": the code passes `rot=Rn`;
  - "kit never gets vertex colours or a join": lines 313-315 do both;
  - "the job passes bare image paths": the job passes full `img|mask|az|el|w` strings;
  - "kit environment intensity 0.6": it is 1.25.

  It also calls the aft-aimed casemate gun a bug, but the owner's rule allows stern guns aft. **Its drop-in `c19_kit.py`,
  `project_paint.py` and `auto_sweep.py` are built on those false premises and are not merged.** `auto_sweep.py` also auto-deletes
  geometry, which the other two audits rightly reject.

## Where all three agree (adopted)

1. Baked colour detail alone can't fix the mismatch. Clean the AI hull's broad flat panels (detection first, then a constrained snap),
   then give hull and parts one shared detail treatment. The game already has a shader plugin for this (`HullFx` in `gfx3d.js`), but it
   is switched off on painted hulls and never attached to parts.
2. A hand-coded script per ship doesn't scale. Move to reusable assemblies (turret, casemate, rack, bridge tier, slab stack, bow loft)
   placed from a short per-ship manifest, with the BVH measuring helpers shared.
3. Split the queue into separate tracks: mechanical, Chorus organic, Ithar sails, small craft. Pilot each before its capitals.
4. Paint: one shared transform for hull and parts, not two separate brightness solves. Remove the 0.3 kit self-light and match
   roughness and environment light.
5. Loading, memory and performance: an untested risk. Load per battle, evict what isn't needed, and decide phone quality per asset.
   Stress-test on the real PC GPU and the Pixel.

## Where they differ, and the pick

- **Paint fix.**
  - Rey: solve one gain over hull and kit texels pooled together.
  - Gemini: level the generated views in 2D before projection.
  - Codex: calibrate on matched material regions.
  - **Pick: Rey's joint solve now** (small, removes the drift by construction), Codex's region calibration later if seams still show.
- **Front armour.**
  - Rey: a stepped "book stack" with near-vertical fronts, widths shrinking 42%, alternating plain and rimmed plates.
  - Gemini: cambered chevron lofts.
  - Codex: planar slabs with inset panels.
  - **Pick: Rey.** It matches the concept close-up best.
- **Bridge top.**
  - Rey: one tall dense masthead cluster at the rear (true cross yards, ladder, a matched funnel pair) plus a front light visor, and
    no radar dish (the concept has none).
  - Gemini: invents a second conning tier.
  - **Pick: Rey, with Codex's caution not to add invented items.**
- **Triangles.**
  - Gemini: cap desktop at 250k with baked normals.
  - Codex and Rey: measure first.
  - **Pick: measure first** (owner said no artificial limits). Real-GPU stress test, then LOD by screen size, with full detail kept for
    close-ups.
- **Blob-sweep automation.**
  - **Pick: Rey's order.** First an exact leftover check that can stop a job, then a waviness report (fix the planesnap visitation bug
    Codex found), then debris candidates. Never auto-delete.

## Verified C19 fixes to make next

- Bow: separate the chasers from the jackstaff; set bollard heights from the deck edge, not the centreline.
- Bridge:
  - replace the floating window band with a visor mounted on the roof edge;
  - move the drums onto the bridge front;
  - extend the bridge cut so the AI lump at the front goes.
- Mast:
  - a brace that lands on real parts at both ends;
  - yards spanning sideways;
  - an open crow rail;
  - a ladder;
  - a matched funnel pair with domed caps.
- Guns: cut the surviving AI base of the front long guns.
- Rocket rack: a second pedestal.
- Front armour: Rey's stepped slab design.

## Engineering items (Codex + Rey)

- Ship assets aren't versioned: the hull files exist only on the PC and in the published artifact. Store them with a manifest.
- Loader:
  - treat hull + kit as one bundle;
  - a missing kit or a bad `.vsm` must fall back to the old whole hull;
  - release kit textures at battle end;
  - apply `AI_HULL_YAW` to kits;
  - attach kits on the station path;
  - split kit parts between the breakup halves.
- The first-battle race is fixed on the waited path only. It's still open on skip/timeout, the showcase, wrecks and background traffic.
