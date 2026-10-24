# Procedural ship kit upgrade: work order for Opus

Author: Rey (Muse), Oct 23, 2026. Companion to art_direction_rey.md in this folder (palettes, silhouette grammars, hero concepts, plates). Status: proposal for Ryan's sign-off; implementation is Opus's. Everything below about current code was verified against the repo tonight; line numbers are ships3d.js unless stated.

## Why this is the biggest lever

The audit math has not moved: C19_51 took 8 revisions of hand-measured coordinates to reach "awaiting owner verdict", 35 of 36 queued hulls are not started (docs/ship_pipeline/SHIP_QUEUE.md), and at the C19 rate the queue costs roughly 69 build sessions. Meanwhile the owner's standing complaint about the in-game fleet is massing: stretched polygons with sanded corners, identical boxes in rows, one flat colour. A parametric kit attacks both numbers at once: hulls become data (a manifest plus a faction grammar pack), so the 36-hull queue becomes parameter work instead of 36 art projects, and every hull inherits the same silhouette discipline.

## What exists today (verified)

- Hull bodies are built by loftVD (ships3d.js:149), which lofts stations and then smooths by corner cutting (cut .11, iters 2, sub 3 by default). The corner cutting is the sanding the owner sees: it rounds every deliberate edge into the same soft polygon.
- buildShipModel (ships3d.js:666) assembles procedural hulls per faction and class; exactly one hull, C19_51, exists as a finished VSM asset (AI_VSM, ships3d.js:764).
- Per-part lofts already appear inside faction builders (gothic chunks at ships3d.js:473, fuselage lofts at :579), each with hand-tuned constants. The knowledge exists; it is just copy-pasted per ship instead of factored into a kit.
- Materials and faction colour already flow from FAC3D and the HullFx plugin (ships3d.js:786-796), including on AI-built parts. The kit does not need a new material system; it needs to stop bypassing the one that exists.
- Known load risk from the pipeline audit: all hulls load at boot with no eviction (roughly 252 MB of geometry across 36 hulls, about 714 MB with the capital exception, and a 20-ship battle wants about 1.32 GB of texture memory). The kit must ship with budgets, not discover them at hull 20.

## The kit, in five pieces

**1. Section loft v2 (replaces corner-cut sanding).** A hull is a list of stations; each station carries width, thickness, vertical offset, and a section shape parameter (the cross-section family: round, gothic arch, wedge, slab, rib, bio). The loft interpolates stations with smooth curves and computes true normals, so a gothic section stays gothic from prow to stern instead of being sanded toward an oval. Corner cutting survives only as an explicit per-station bevel parameter, never as a global smoothing pass. Acceptance test: the same station list rendered by loftVD and by loft v2 side by side; v2 must show hard deliberate edges where the grammar wants them (Hegemony wedge, Deathless ribs) and smooth flow where it does not (Chorus, Ithar).

**2. Faction grammar packs.** Each faction's silhouette grammar from the art direction becomes a parameter pack the kit reads: section family, profile curve character (how width and thickness evolve prow to stern), prow treatment, stern treatment, vertical emphasis, and a symmetry rule. In one line each: Voidsworn (gothic sections, vertical emphasis, spire mounts aft), Hegemony (wedge sections, one clean triangular plan, dome on the centreline, symmetry enforced), Corsairs (mixed sections, asymmetry enforced by seed: no mirrored feature placement, donor panels from other packs allowed), Chorus (bio sections, no straight run longer than one station, growth ring segmentation), Ithar (needle profile, vertical fin mounts dorsal and ventral, thinnest sections), Deathless (rib sections: the loft itself is segmented, with a dark core hull under an open rib cage). A new hull that violates its pack should be impossible to express, not merely discouraged.

**3. Feature module library.** The recurring geometry (spires, sensor domes, torpedo racks, spore pods, sail fins, rib arches, donor armour panels, hangar mouths, engine blocks) becomes a library of parametric modules placed by landmarks in the manifest (prow, bridge, hangar, gun deck, engine), scaled from the hull's size class. This is the shared detail block the pipeline audit already called for: detail defined once in gfx3d.js, used by both the procedural and AI-asset paths, baked with DETAIL off. Hand-placing a box per hull is the failure mode being retired.

**4. Hull manifests.** A hull is a small data record: faction pack, size class, station overrides (length, beam, thickness profile), module list with landmark placements, and a seed. Variants (the census found 12 of 45 hulls are same-stat weapon swaps) become manifest diffs, not rebuilds. The manifest is also where the SHIP_QUEUE plugs in: queue entries stop being blank rows and start being manifest stubs Opus or the pipeline can generate from.

**5. Paint and finish, unchanged in principle.** FAC3D is the single colour source (art direction ruling); the kit reads it for hull, dark, trim and glow channels and applies the joint paint solve the audit specified (one gain across hull and kit texels, the 0.3 emissive fudge in aiKitMat deleted), with HullFx providing rim, roughness break-up and wear. Two-tone minimum per hull is enforced by the pack (base plus trim always both present), because one flat colour is half of the Lego read.

## Budgets and gates (non-negotiable)

- Per-class vertex and triangle ceilings for desktop, enforced at build time in the same spirit as the check pack: a hull that exceeds its class budget fails the build, loudly, before it reaches a device. (Phone ceilings struck under the Oct 24, 2026 PC-only ruling.)
- The Pixel stress gate from the pipeline audit is superseded by the Oct 24, 2026 platform ruling (PC-only in Babylon): no hull 6 until a fully loaded battle passes on desktop. There is no phone pass. Budgets plus lazy loading or eviction for off-screen factions still apply if the desktop stress test demands it.
- Screenshot acceptance per hull, two shots at battle zoom on a desktop frame: (a) lit, against its home plate; the hull must read as its faction at a glance; (b) the silhouette sheet: every hull of a faction rendered flat black, small, in a grid; any two hulls a viewer cannot tell apart, or any hull a viewer assigns to the wrong faction, sends the manifest back. The six hero plates in the art pack are the reference targets for the first six kit hulls.

## Rollout

1. Loft v2 plus the Voidsworn grammar pack, proven on one manifest: the Basilica hero from the art pack. Compare directly against the tableau frame.
2. The remaining five grammar packs, one hero manifest each (Edict, Jackdaw, Lullaby, Palinode with vertical fins, Cenotaph). Six heroes = the kit's proof set and the game's new face.
3. The queue in four tracks per the pipeline audit, generated from manifests, silhouette-sheet review per track before paint.
4. In parallel, and independent of the kit: wire the background plates to terrain kinds (art direction Part C and C2). That is the fastest visual win in the whole overhaul and should not wait for hull work.

## Non-goals

No hand-measured coordinates for new hulls. No per-hull materials or one-off shaders. No gameplay numbers touched (this is a rendering and content-pipeline change only). No new hull started outside a grammar pack.
