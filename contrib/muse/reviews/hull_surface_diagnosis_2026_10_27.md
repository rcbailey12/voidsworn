# Hull surface diagnosis pack: the V1b prow and the wavy effect (Oct 27 program, item 12)

Pinned to repo HEAD 68b42ce406286eb95ea7df6aaf3f683c1231b51d. Written Oct 27, 2026.
Lane: external point of view only. These are observations from the rendered sheets, for A4 to confirm or overturn in Blender. Ryan's eye is the verdict on both questions.

## The two questions

Q1, the V1b prow. Ryan, on the pass 5 bow sheet: the V1b bow looks okay from the side but different from the top (still pointed from above). Do the top and side outlines of the fixed V1b bow actually disagree?

Q2, the wavy effect. Ryan's words: "there's like a weird wavy effect to the ships, I'm not sure if it's the modeling or what". Is the waviness in the modeling (the hull surface itself undulates) or in the material (the surface is fair, and the shading, normals or paint make it read wavy)?

Short answers, evidence below. Q1: yes, the outlines disagree; the top outline still runs to a point, the side outline ends in a blunt downward hook. Q2: the visible evidence leans geometry, meaning the hull form itself carries broad soft swells, with the painted pass amplifying them; one separate smaller effect, the bright fringe in the underside views, leans material. One Blender check settles Q2 (see Synthesis).

## Sheet inventory

57 image files inventoried. 11 sheets read closely for this pack, plus 3 zoomed crops cut from the pass 5 sheets.

Rollout working copies, ~/workspace/voidsworn-rollout-audit/img/ (12 files):
- bow_before_after_H8_H7_V1b.jpg (the sheet Ryan viewed; read closely)
- bow_before_after_H4_H10_H9.jpg (same sheet also in the pass 5 set; inventoried, not re-read)
- V1b_r_23_sweep_painted.webp and H4_11_sweep_painted.webp (copies of pass 5 sheets)
- voidsworn_lineup.webp, hegemony_lineup.webp, corsair_lineup.webp (copies of pass 5 sheets)
- crests_all.webp (faction crests; not a hull surface sheet)
- 01_frigate_marks_battle_camera_forward_vs_compat.jpg, 02_signatures_close_flak_acid_ion_ram.jpg (G4 damage mark battle shots; not A4 sheets)
- dreadnought_turn_then_burn_after_frames.jpg, frigate_sidestep_after_frames.jpg (G2 motion frame strips; not A4 sheets)

Repo pass 5 set, ~/workspace/voidsworn-fresh/docs/shots/a4/a7c4e0d/ (17 files). Read closely:
- V1b_r_23_sweep_painted.webp, H8_23_sweep_painted.webp, H7_23_sweep_painted.webp, H4_11_sweep_painted.webp, C19_51_sweep_painted.webp, V17_37_sweep_painted.webp
- hegemony_lineup.webp, voidsworn_lineup.webp, corsair_lineup.webp
Inventoried, not read closely: H9_23, H10_23, V14_23, V15_37, V16_37, V18_51 sweep sheets, bow_before_after_H4_H10_H9.jpg.

Repo earlier set, docs/shots/a4/46a89fe/ (12 files): C13s, C14s, C15s, C16s, V14, V15, V16, V17, V18, V1b_r_23 sweep sheets and the corsair and voidsworn lineups. Inventoried; same hulls as the pass 5 set at an earlier step.

Repo set, docs/shots/a4/d8e187e/ (16 files): C16s, C19, H4, H7, H8, H9, H10, I16, V17, V18, V1b_r_23 sweep sheets and the corsair, hegemony, ithar and voidsworn lineups. Read closely: V1b_r_23_sweep_painted.webp, as the cross-check that the surface character repeats outside the pass 5 renders.

Every sweep sheet is a 9-panel grid: rows bow, mid, stern; columns top, side, below. Every sheet header names the pipeline the same way: "blob sweep, painted".

## Per-sheet observations: the waviness

### H7_23 sweep, pass 5 (Picket frigate, light grey)
- OBSERVED: The deck in the top views is tiled with raised plates, and every plate bulges: lit in the middle, soft falloff at the edges, like cushions. A zoomed crop of the stern deck shows the same thing plate by plate. The deck outline itself stays smooth while the surface between the outlines shades in soft humps.
- OBSERVED: The bow side panel shows long horizontal wavy bands running along the hull side, and the mid side panel's lower hull line rises and falls instead of running straight.
- OBSERVED: In the mid below panel, a bright wavy line runs along the hull rim where the edge catches the light.

### H8_23 sweep, pass 5 (Interdictor destroyer, light grey)
- OBSERVED: Same pillowy plate character as H7, across bow, mid and stern decks.
- OBSERVED: A zoomed crop of the mid side panel shows the underside line of the hull sagging down in one broad bulge and rising again; the outline is not straight. The recessed bay in the same crop has a crumpled, folded look, with vertical wavy folds.
- OBSERVED: In the mid below panel, one rim carries a row of regular scallops, evenly spaced rounded bumps along the edge.

### Hegemony lineup, pass 5 (all five Hegemony hulls, perspective views)
- OBSERVED: All five hulls share the soft, lumpy surface character, strongest on the broad flanks of the Vanguard cruiser (H9_23) and the Interdictor (H8_23), where the sides ripple in soft waves. It is not one hull's quirk.
- OBSERVED: At lineup scale the outer silhouettes read mostly clean; the waviness lives mainly in how the surfaces shade.

### H4_11 sweep, pass 5 (Dominion super-dreadnought, light grey)
- OBSERVED: The same raised plates are present but flatter and calmer; broad decks read much fairer than H7 or H8, and the wavy read is weak on this hull.
- INFERRED: Whatever produces the effect varies in strength hull by hull, even inside one faction and one render pass.

### V1b_r_23 sweep, pass 5 (Ascendant dreadnought, dark)
- OBSERVED: The dark hull shows the effect more weakly in the top and side panels, but the below panels show a bright wavy fringe along the hull rims.
- OBSERVED: A zoomed crop of the mid below rim shows the fringe is made of short vertical streaks hanging off the edge, uneven in length, like drips. Along the middle of the same crop the hull edge underneath the streaks runs fairly straight.
- OBSERVED: The bow side panel shows curved ribbed bands wrapping the bow, stacked arcs running down the prow.

### V1b_r_23 sweep, d8e187e set (same hull, different render step)
- OBSERVED: The same surface character appears: pillowy plates on the stern deck, the same bright wavy fringe along the below-view rims. The effect is not specific to the pass 5 renders.

### V17_37 sweep, pass 5 (Cathedral battleship, dark)
- OBSERVED: Surfaces read smoother overall; the stern deck shows fine lengthwise streaks in the paint rather than broad swells. The wing undersides in the mid below panel again show a bright wavy line along the rim.

### C19_51 sweep, pass 5 (Warlord's Pyre-Barge, rust), and the Corsair lineup
- OBSERVED: The Pyre-Barge, the hand-built worked example with hand-placed kit parts, shows chunky, angular surfaces and no broad waviness. The other Corsair hulls in the lineup likewise shade in facets rather than soft waves.
- INFERRED: The waviness is weakest exactly where the most hand work went into the surface, and strongest on the plainest blob-built hulls (H7, H8). That pattern points at the shared hull-building step, not at faction paint.

### Voidsworn lineup, pass 5 (six dark hulls)
- OBSERVED: The dark Crusade hulls read flatter and cleaner than the Hegemony line at the same scale, apart from the Reliquary carrier's wing decks, which show the same quilted raised plates.
- INFERRED: Part of the faction difference is visibility: light grey paint shows shading undulation that dark paint hides. The sheets alone cannot separate "Hegemony hulls are wavier" from "Hegemony paint shows it more". Flagged honestly; the Blender check below separates it.

## Synthesis: which cause the evidence leans toward

There are two different effects in the sheets, and they should not be merged.

Effect 1, the main wavy read (the one that dominates the Hegemony sheets). OBSERVED components: plates that bulge like cushions across every deck; long wavy bands along hull sides; at least one zoomed case (H8 mid side) where the hull's own underside outline sags in a broad swell instead of running straight; strength that varies hull by hull, repeats across factions and across render steps (pass 5 and d8e187e), and is weakest on the hand-kitted Pyre-Barge. INFERRED: this leans geometry. A pure shading or paint effect would leave every silhouette straight; the H8 underside outline is not straight, and the crumpled folds in its recessed bay are outline features, not shading. The wavelength is broad and irregular (a few swells per hull section, unevenly spaced), which fits a loft or sweep surface that is not fully fair, the hull form carrying gentle scallops from its cross-sections, rather than a fine regular procedural ripple. The painted pass then amplifies it: every plate is shaded as a soft dome, so a slightly unfair surface reads even wavier once painted. Pick: geometry first, paint as amplifier. If A4 fixes only the material, the sag in the outline stays.

Effect 2, the bright fringe in the below views (V1b, V17, and the H7 rim line). OBSERVED: short vertical streaks hanging off rim edges, uneven lengths, while the hull edge underneath runs fairly straight (V1b mid below crop). INFERRED: this one leans material: a streaky rim or weathering treatment catching grazing light, not a wavy mesh edge. It is a separate, smaller item; A4 may judge it intentional weathering. It is listed here only because in the full sheets it blends visually into Effect 1.

The single Blender check that would settle Effect 1 (proposal for A4, not an order): re-render H8_23 from the same mid side camera as the pass 5 sheet, with the painted material bypassed and a single flat workbench color on the bare mesh. If the underside still sags and the flanks still swell with no texture, no normals and no paint involved, the wave is in the mesh and the fix belongs in the loft; if the bare mesh runs fair and straight, the wave is in the material pass and the fix belongs there. The same render on H7_23 would confirm it is not one hull.

## The V1b prow read

Source: bow_before_after_H8_H7_V1b.jpg (the sheet Ryan viewed) and the V1b_r_23 pass 5 sweep sheet.

- OBSERVED, before: from the top, the V1b bow tapers to a clean point, a triangular prow tip with a round port near the tip. From the side, the bow slopes down to a rounded, drooping point.
- OBSERVED, after, top view: the outline still tapers to a point. The deck narrows steadily to a tip, with a small protruding nib at the very front. From above, this bow still reads pointed, the same family of outline as the before shot, only slightly softened.
- OBSERVED, after, side view: the bow no longer slopes to a point. The profile runs out and then hooks downward, ending in a blunt, drooping snout. From the side, this bow reads blunt, but it droops.
- OBSERVED, the pass 5 sweep sheet agrees: bow top panel pointed with the nib; bow side panel blunt and downward-hooked, with the ribbed bands wrapping it.
- Read, in plain words: Ryan's read is what the sheets show. The fix changed the side profile and left the top profile pointed, so the two outlines now tell different stories: pointed from above, blunt and drooping from the side. H8 and H7 on the same sheet show what a matched pair looks like: after their fix, the bow is a flat vertical face in both the top and the side views. V1b is the only one of the three whose top and side disagree.

## Limits

- Stills cannot show temporal shimmer. If part of what Ryan saw moves or crawls when the ship rotates in game, no sheet in this pack can confirm or rule that out; only a turntable render or in-game capture can.
- This pack works from rendered sheets, not source meshes. Every geometry claim above is an inference from silhouettes and shading in renders; the bare-mesh check proposed in the synthesis is the first direct look at the mesh itself.
- Sheet resolution caps the detail: panels are roughly 500 px wide in the source sheets, so very fine ripples, if any exist, are below what these renders can show.
- Three sheet sets were inventoried (46a89fe, a7c4e0d, d8e187e). Only the pass 5 set (a7c4e0d) was read panel by panel, with the d8e187e V1b sheet as a cross-check; the earlier 46a89fe set was inventoried but not re-read, and nine pass 5 sweep sheets were inventoried without a panel-by-panel read (listed above).
- Paint visibility confound: light grey Hegemony paint reveals shading that dark Crusade paint hides, so cross-faction strength comparisons from these sheets are provisional until the bare-mesh check runs.
