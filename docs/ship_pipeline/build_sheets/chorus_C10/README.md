# chorus_C10 build sheet: The Ninefold Maw, the Chorus flagship (first sheet)

The Chorus, class Bio-titan, **28.0 world units** mouth to membrane tip (godot/render/hull_table.gd CLS_LEN; data.js `b_boss`:
bioplasma F, bioplasma F, tendril T, spores T; hangar 3; regen 20; no shields). The model is 28.03. Version 1, 2026-11-12,
issue 623. Designer of record: Opus (R205, R207). Accepted picture: contrib/muse/design/concept_round8b_2026_11/chorus_C10_beauty.jpg
and chorus_C10_sheet.jpg (R204). Built with the new Chorus kit, `tools/blender/kits/chorus/` (grown parts; its README says what
each part is and does). The views were rendered in the Opus sandbox (Blender 5.3, CPU, 20 samples) from the same build.py the PC
runs; nothing ran on Ryan's PC.

![chorus_C10 preview](preview.jpg)

**Start here, the whole ship first (R229):** [whole beside whole](../../../shots/issue_623_chorus/c10_whole_compare.jpg), then
[side against side](../../../shots/issue_623_chorus/c10_side_compare.jpg), [plan against plan](../../../shots/issue_623_chorus/c10_top_compare.jpg),
the [bow](../../../shots/issue_623_chorus/c10_bow_compare.jpg) and the [stern](../../../shots/issue_623_chorus/c10_stern_compare.jpg).
The two classes from above at one scale: [c10_c11_classes.jpg](../../../shots/issue_623_chorus/c10_c11_classes.jpg).
Then [side_by_side.jpg](side_by_side.jpg), [cells.jpg](cells.jpg) and [fit_view.jpg](fit_view.jpg).

## What it is

Something vast and eyeless that was grown as a weapon. The double mouth at the bow is its two bile spitters; the tendril crown
on its back boards and holds; five spore glands hang under the belly as its point defence; three brood sacs a side carry the
spore swarms (hangar 3) and give birth to them through slits; a crown of three pulse vents with trailing membranes drives it.
No panels, no pipes, no metal: hide with callus pads and sense pores, fold rolls, an ochre chitin ridge along each shoulder,
veins carrying bile, scars knitting shut.

## The checks

| Check | Result |
|---|---|
| Views agree (side, top, bow): length, beam, height | 0.0, 0.04 and 0.0 percent apart; length 28.05 on the views, 0.1 percent over the class (checks.json, PASS) |
| Fit check (R217, R219, R221): clash, mount, arc, sweep, exhaust, exit, lane | **0** in all seven ([fit_report.md](fit_report.md), [fit_view.jpg](fit_view.jpg)) |
| Machines on a seam (R226) | **0** of 15 machines (2 throats, the crown, 5 spore glands, 3 vents, 4 siphons) across 4 seams |
| Insides inside the skin | 0 of 7,484 inside vertices within 0.15 of the skin |
| Inventory (R218, R221) | 15 lines, every one with a job; 0 not present, shaped and detailed ([inventory.md](inventory.md)) |
| Outline overlap at the concept's camera (reported, not a bar) | 76.8 percent ([outline_check.jpg](outline_check.jpg)) |
| Proportions, hull length to beam / to height (concept sheet against build, same measure) | 5.74 / 6.21 against 5.87 / 6.03 |

### Detail density per part type (R224, measured on the blockout; numbers in [density_seams.json](density_seams.json))

Triangles and edge features (faces meeting at over 30 degrees, or an open rim) per square unit, against the hull's own. Under
0.75 on either is flagged. **None flagged.**

| Part type | Triangles per unit2 (vs hull) | Edge features per unit2 (vs hull) |
|---|---|---|
| hull (the body, hide pads, folds, chitin trim, veins, pores, scars) | 201.5 (1.00) | 116.5 (1.00) |
| spinal (the two throats) | 258.3 (1.28) | 198.2 (1.70) |
| gun (the crown and the spore glands) | 209.4 (1.04) | 113.0 (0.97) |
| brood (the brood sacs) | 202.4 (1.00) | 122.1 (1.05) |
| engine (the pulse vents and membranes) | 287.2 (1.43) | 146.5 (1.26) |
| thruster (the siphons) | 555.2 (2.76) | 252.1 (2.16) |

## Weapons, each from the lore (R221)

| Slot | Weapon | Built as |
|---|---|---|
| F, F | Spine volley (bioplasma) | the two throats of the double mouth: rolled fold lips stacked round each mouth, an inner sphincter, a ring of chitin spines (the spines it spits), a dark bore, the bile gland glowing at its back. Fixed forward. |
| T | Boarding tendrils (tendril) | a crown of thirteen hooked tendrils on a muscle mound, each with grip rings, a chitin barb and acid pores; it turns to lean toward its prey (R219 turret marking) |
| T | Spore cloud (spores) | five spore glands hanging on necks under the belly, veined sacs whose spouts curl forward to a rosette of pores; each swings on its neck |

The weapon pictures are on the sheet (weapon_bioplasma.jpg, weapon_tendril.jpg, weapon_spores.jpg).

## INSIDE (R209): flesh, bone and organs, never rooms that reach the skin

Bone hoops for frames (12 stations), two membrane septa for decks, and organs: the two bile glands behind the throats (the
shot's magazine), the Node (the knot of nerve that steers it; no bridge), the fore and aft guts, the heart vat (the core,
hp_core, lit bile-green), six brood chambers beside the brood sacs, five spore stores over the glands, the crown's root muscle,
four regrowth tissue chambers and the pulse bladder that squeezes the vents (the engine room). Armour by zone in the sheet's
INSIDE list. Break lines by the Chorus rule ("it bursts and tears: sacs rupture first, then the body tears open"): B-1 behind
the head, B-2 behind the crown, B-3 ahead of the tail, and B-4 along the belly through the brood sacs' roots; ragged plan paths,
no machine on any of them. Nine breach anchors (Bio-titan 8, Chorus +1 on the big ones), next to the sacs and the trim.

## Changed from the picture (R207)

1. **Colour**: bile yellow-green light over dark olive flesh and ochre chitin (R204, the lore). The picture is grey with amber light.
2. **The double mouth is the two bile spitters** (bioplasma F, F), each with a sphincter, a spine ring and its gland; the picture shows only the glow.
3. **The tendril cluster is the boarding tendrils** (tendril T), a turning crown on a muscle mound; built as the profile draws it (curling), the tips splayed outward as the plan shows.
4. **The belly row is five spore glands** (spores T); the last two sit about a unit further aft than the picture's so the B-2 seam passes behind the crown and between two glands (R226).
5. **The flank sacs are brood sacs** (hangar 3): the picture's crease on each becomes the birth slit, kept clear by the fit check.
6. **The shoulder ridge is a row of ochre chitin scutes** on a raised welt (the lore's ochre trim; the line the hide tears first).
7. **The tail ends in a crown of three pulse vents** with trailing membrane veils (factions.md: no nozzles). The membranes are about two thirds of the picture's wisps so the ship is 28.0 mouth to membrane tip.
8. **Siphons added** (two pairs): a ship in space must turn, with siphons, not nozzles.
9. **Pore fields, veins and knit scars added**: the Chorus has no eyes and tastes the dark (lore 5.8); the veins carry bile to the throats (README 8b noted C9's vein tracery faded); scars knit shut (regen 20).

## What still differs from the concept, and why

- **The hide's surface** (fine wrinkle grain, mottling, wet sheen, scar colour) is paint: recipe stages 4 and 5. The blockout is schematic colour.
- **The head reads blunter** than the beauty's coiled mouth lobes: the beauty's strong perspective swells the bow, and the fold rolls are modelled at the sheet's true size. The plan and profile widths match the concept sheet (the side and plan compares).
- **The brood sacs sit a little higher** on the flank than the picture's hanging bulges, so their birth slits face out and down clear of the belly glands.
- **No underside view** on the concept sheet: the belly between the sacs is designed here.

The blockout .blend is not on Ryan's PC (nothing ran there); build.py rebuilds it from `tools/blender/build_sheets/ships/chorus_C10.py`.
