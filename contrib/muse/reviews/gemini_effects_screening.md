# Screening: Gemini's Effects and World 3D review

Chair: Rey. Source: contrib/gemini/reviews/effects_world.md, a REVIEW_PROTOCOL review of fx3d.js, vfx3d.js, wfx3d.js and scene3d.js at basis 4fa29bd. The four files are byte-identical in length at the current HEAD (625, 200, 463 and 684 lines, matching Gemini's own proof of reading), so every check below ran against the same text Gemini read. Unusually for Gemini, its quotes are nearly all verbatim. Its failures are of a different kind: lifecycle claims that die when you follow the callers, including callers inside the same files.

## Tally

Of the ten protocol-table findings: 3 verified as stated (one with a magnitude correction), 5 partially verified, 2 refuted. Of the three frame-time claims: 1 mostly verified with a misquote inside it, 1 half refuted, 1 verified as code fact with an inferred ranking.

## Verified

- **Table 2 / section 2.2, plume materials (vfx3d.js:76-78).** plumeShaderMat creates a new ShaderMaterial per call, pushes it to G.plumeMats with no deduplication, nothing anywhere clears the array, and vfxTick iterates all of it every frame. Magnitude correction: the only call site is ships3d.js:83, at faction material build, so growth is per rebuild and faction-bounded in practice, not per ship or per battle as the review's framing implies. The fix (cache by faction) is still right and still cheap.
- **Table 7 / section 2.8 area, wbDraw allocations (wfx3d.js:172).** Quote verbatim: p.subtract(rec.prev) allocates per projectile per frame, clone on the fallback path. Real during broadsides.
- **Table 8, camera shake allocations (wfx3d.js:104).** Quote verbatim. Three Vector3 allocations per frame while trauma shake is active, not four as counted (rx.scale returns the third; uy.scale mutates in place through addInPlace). Minor, real, worst-timed as claimed.

## Partially verified

- **Table 1 / section 2.1, the shield-ring material leak (fx3d.js:35, 75, 448).** Code facts verified: makeShieldRing creates a unique ShaderMaterial per ship (quote verbatim), and no path explicitly disposes the ring's material; disposeView, the death path and the withdraw path all call only v.ring.node.dispose(false,true). The leak conclusion rests on Gemini's assertion that TransformNode.dispose does not forward disposeMaterialAndTextures to child meshes. That premise is exactly what is in dispute, and this review offers no runtime evidence. Settle empirically (scene.materials count across battles) or from the shipped Babylon version's Node.dispose source; do not sequence work on the assertion alone. Mitigating fact either way: the shader program is shared via the ShadersStore, so the worst case is material instance accumulation, not recompiles.
- **Table 3 / section 2.3, G.nearMats growth (scene3d.js:662).** The push and clearEnv's silence verified. Two mitigations Gemini missed because they live outside its four files: gfx3d.js:307 resets G.nearMats=[m] on every near-planet material build, bounding the array in most flows, and gfx3d.js:403 guards its per-frame loop with a disposed check. The moon-material pushes at scene3d.js:662 can still accumulate between resets. Real, smaller than stated.
- **Table 5, nameplate string and DOM work (fx3d.js:161-164).** The key string (u.sh.map(...).join(',')) is indeed built every frame for every living ship. But the four classList.toggle calls the review says run every frame are already inside the if(key!==v.plate.key) guard at line 164, which is the review's own proposed fix, already applied. Half a finding: the string allocation is worth gating, the DOM half is done.
- **Table 9 / section 2.6, the VLS new-mesh observer (scene3d.js:111).** The setTimeout(0) per added mesh is real. Missed mitigations, both in the same function Gemini read: skipVls only pushes LinesMesh, points-cloud, stars and sky into excludedMeshes (not every mesh), and the observer is removed when VLS is disposed ("one observer, removed when god rays go"). Growth is bounded by line/point meshes, not by all combat meshes.
- **Table 6 / section 2.8, heatTick allocations (wfx3d.js:461-463).** Verified with a size correction: the Viewport is allocated once per tick that has heat projectiles (behind an if(!tm) guard), the projections and point arrays are capped at 8, and the consumer already writes into a preallocated Float32Array(32). GC churn exists; "every frame" applies only while heat weapons fly.

## Refuted

- **Table 4 / section 2.4, the surviving-ship engine light leak.** Gemini quoted fx3d.js:69 and missed what the line does: el.parent=v.root. The light is parented to the ship's root, disposeView disposes the root recursively (v.root.dispose(false,false)), and a parented light dies with it in every observed path, including the direct disposeView callers (squadron death, capture, withdraw), none of which involve an unparented light. The mid-battle detach to G.deadLights is deliberate, with the author's reason in the comment at fx3d.js:448 (disposing a light mid-fight re-dirties materials; it is drained at battle end in disposeAllViews). The PBR recompile concern is likewise already managed: lights are restricted to opening fleets and includedOnlyMeshes (fx3d.js:69). No leak as stated.
- **Table 10 / section 2.10, uncached vfxMat and boltMat.** vfxMat has exactly one call site (vfx3d.js:195), and that caller disposes the material in its completion callback (vm.dispose()). boltMat has no call sites anywhere in the repo; it is dead code (independently flagged in the compute pack's dead-code list). A helper that is called once and cleaned up, and a helper that is never called, are not a leak.

## Frame-time section

- **Post-processing stack (section 3.1): mostly verified, one misquote.** GlowLayer 1024/48, pipeline samples=4, bloom kernel 72, ACES, sharpen: all verbatim at scene3d.js:24-34. But the VLS quote inflates the numbers: the actual constructor at scene3d.js:108 is ratio .5 with 70 samples, not ratio 1 with 100. The ranking itself (post stack dominates) is plausible and marked INFERRED by Gemini, fairly.
- **updateWorld physics (section 3.2): the sub-step claim is wrong.** There is no 240 Hz loop and no 12 to 16 iterations. fx3d.js computes h=min(dt,1/20) and n=max(1,ceil(dt/h)), which is 1 sub-step at normal frame rates and about 2 when frames run long. Gemini's quoted line 139 shows the integrator body, not the count it claimed. The plume/flare scaling and nameplate observations in the same item are covered above.
- **gradeFor ColorCurves (table 10 in section 2.7 numbering, scene3d.js:682): verified**, one small object per battlefield setup, impact trivial, fix trivial.

## Pattern note

This is Gemini's best-behaved review so far on quotation discipline, and its failures moved to a new place: every refutation and most corrections came from following a lifecycle one step further than the review did (a parent assignment on a line it quoted, a caller's dispose, a reset in a file outside its reading list, a guard already in place below the line it cited). Its protocol confined it to four files; the disposal truth for effects code lives in the callers. Recommendation for future Gemini reviews of this kind: include ships3d.js and gfx3d.js in scope, or treat every leak claim as provisional until the caller graph is checked.

## Routing

Worth Opus's time, in order: the plume material cache (verified, cheap), the ring material question (settle the Babylon premise empirically before fixing), the nameplate string gate (half a fix), wbDraw scratch vectors (verified, small). Not worth scheduling: the engine light (refuted), vfxMat/boltMat (refuted), the traffic-ship materials (section 2.5, plausible mechanism, no evidence of unique materials to leak, since ship models draw on shared faction materials).
