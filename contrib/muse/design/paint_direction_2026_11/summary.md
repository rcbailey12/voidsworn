# Paint direction summary (issue 689, R243)

One pack, four pages: sunward.md, hegemony.md, glasswrights.md, chorus.md in this folder, each with a swatch and mock panel strip sheet (sunward_sheet.jpg, hegemony_sheet.jpg, glasswrights_sheet.jpg, chorus_sheet.jpg). Ryan's yes or no at the swatch review comes before any stack is built (issue brief). Hullbreaker and Eclipse already have worked stacks; this pack writes the direction for the other four factions under FINDINGS R243: surface order follows faction lore. Sunward gets sleek triangular panels, Hegemony stays rigid and clean on an even grid, Glasswrights gets no panels at all (seamless blown glass), Chorus is grown with no plates, and Chorus's page is a translation of the settled issue 670 pack into stack form, not a re-opening.

## The four directions in one view

- Sunward: triangles on the flat fields, rectangles on the curves, patch_warp 0, rivets at .011, black iron pairs around #191615 to #525151, ember glow just under threshold, frost white as decals only under a 6 percent cap. Roughness floor .55.
- Hegemony: the even grid itself, two identical module sizes fleet-wide, a seamline module band at the joints, plate_var .07, steel-blue grey pairs #141c2a to #48505e with a hard cap at #626d7d, implant-blue strips pulsing under threshold. Roughness floor .52.
- Glasswrights: every patch key 0; variation from glass depth tint by AO, silver gradient zones and the rainbow fringe applied last; glass pair #868688 to #d2d1d2 as a hard cap with the rendered median at #9d9c9e; glass roughness floor .30 with rim_soft; no trim, no decals, no running lights. Ryan's review ruling added strength here: a wider, more saturated fringe and prism dispersion through the glass (see the rulings below).
- Chorus: the 670 palette verbatim (#423d27 hide family, bile #77811f / #9dab2c / #c2cf45), patch machinery reused as mottling cells at patch_warp .55, scar furrows as their own line layer, per-tissue roughness floors from 670, metalness 0.0 everywhere.

## Council record

Blind Rey leg first, written from the pack alone. DeepSeek (DeepThink on, Search off, verified both ends): a Sunward leg only, thorough; it did not write the other three factions. Qwen (Qwen3.8-Max in the selector before sending and in the header after, single response): all four factions, the fullest leg. Flash (Gemini, "Quick answers 3.5 Flash-Lite" in the picker before and after): all four factions, compact. Grok: seat empty for the fourth consecutive muse job (670, 643, 675, 689); grok.com showed only "Your request was blocked", waited and reloaded once, pack never sent. Recorded as an empty seat, not substituted.

Chair calls where the legs split:

- Sunward frost lights: Qwen proposed small frost-white running points on the blade's edge (emissive, from the game accent). DeepSeek, Flash and blind Rey kept frost as non-emissive markings and the ember line as the only light, and the chair sided with the majority. Ryan overruled the chair at the review (below): Qwen's version stands, and sunward.md is amended.
- Sunward grime: legs ran .35 to .80. Settled at .55 body: S8 reads sooty, the guide forbids rust, not soot.
- Hegemony seam strength: legs ran .0008 to .0018 wide, seam_dark .88 to .98. Settled at .0016 and .94: the modules must read at mid range (Qwen's argument) without turning Hegemony into Eclipse (.0020 and .95).
- Glasswrights roughness floor: blind Rey and Qwen settled at .30 with rim_soft; Flash wrote .50 as a floor while also writing glass roughness .18, which contradicts itself. Settled at .30 with the probe ladder (raise the floor first if it flares).
- Glasswrights CONCEPT light: Flash's glass pair reached #fcfcfb as a light tone while its own note said to hold the lower half. Settled per Qwen and blind Rey: #d2d1d2 is a hard cap and #f4f3f3 / #fcfcfb are not tones at all.
- Chorus numbers: Flash's flat roughness floor .55 and grime .80, and Qwen's per-zone roughness table, both drift from the 670 settlement (per-tissue floors, grime as #2a2820 at 12 to 18 percent). The chair restored 670's numbers wherever a sketch disagreed. Qwen also restated the hide pair as (#423d27, #57503a), mixing the main tone with the belly tone; chorus.md writes the 670 zones as settled (dorsal #37331f, main #423d27, belly #57503a).
- Chorus patch_warp: Qwen and Flash said .40, blind Rey .80. Settled at .55, the value whose behaviour in the shared stack is proven, on cells that blend by tone.

Leg slips, recorded so nothing rests on them: DeepSeek described S8's plate fields as already triangular; the picture's fields are rectangular riveted plates, and the triangles come from R243, not the picture (its two-region rule stands on R243 and the curve argument, and was adopted on that basis). Flash called the Eclipse 2.2 lift "standard" for all four stacks; no page in this pack states a lift, and the stacks read look.gd per faction.

## Ryan's rulings at the swatch review (Nov 14, 2026)

1. All four pages: yes, with one amendment. Glasswrights carries more rainbow and prism than the chaired pages had: the fringe runs wider and more saturated, the glass throws a low-saturation prism wash where the stored light leaves it at glancing angles, and the bow optic shows a real spectral fan at rest (glasswrights.md sections 1, 5 and 6 amended). The coloured pane fills stay rejected; the colour lives on edges and in dispersion.
2. Sunward frost: Ryan liked Qwen's suggestion. The blade's edge carries small frost-white running points at about 0.72 of threshold (sunward.md section 5 amended). Frost markings stay decals under the 6 percent cap.
3. Hegemony module band: Ryan ruled it does not read as ornament. The band stands as structure (hegemony.md section 1 amended).
4. Hegemony value: Ryan confirmed the H10 sample and the #626d7d cap. No deliberate lightening (hegemony.md section 2 amended).

The pack is approved for stack building on that basis.

## Questions for the Board (build-time)

- Sunward rivet pitch: the builder A/B tests .011 against .013 at camera 170 and reports.
- Glasswrights roughness floor probe at .28 / .30 / .32 before any full paint; and the lens build must hold R196's no-seam rule or glasswrights.md is violated upstream.
- Hegemony symmetry: a port and starboard mirror check for decals and wear is a pipeline need, not a paint value.
- Chorus: the seam layer's fitness for irregular furrow paths, plus 670's six open questions, carried unchanged in chorus.md.
- Sunward and Hegemony stacks should carry the R243 comment at patch_warp 0, so a future editor does not warp their deliberate order (the reverse of the hardening opus_check_675 asked for on Hullbreaker).

Sources for the whole pack: FINDINGS R243, R240, R204, R192, R196; docs/playbooks/factions.md; docs/ship_pipeline/RECIPE.md (stack section); tools/blender/kits/hullbreakers/stack.py and tools/blender/kits/eclipse/stack.py (LAYERS form); the issue 670 pack; chair samples of S8, H10, G15, C10 and C11 (k-means, background excluded); godot/fx/faction_looks.json; godot/render/look.gd (lift read, never stated).
