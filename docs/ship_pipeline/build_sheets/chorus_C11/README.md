# chorus_C11 build sheet: the bladeback, the Chorus cruiser (first sheet)

The Chorus, class Cruiser, **14.5 world units** throat rim to filament tip (godot/render/hull_table.gd CLS_LEN; data.js `b_razor`,
"Chorus bladeback": tendril T, bioplasma F; ability frenzy; regen 6; no shields). Version 1, 2026-11-12, issue 623. Designer of
record: Opus (R205, R207). Accepted picture: contrib/muse/design/concept_round8b_2026_11/chorus_C11_beauty.jpg and
chorus_C11_sheet.jpg (R204). Built with the Chorus kit, `tools/blender/kits/chorus/`. Rendered in the Opus sandbox (Blender 5.3,
CPU, 20 samples) from the same build.py the PC runs; nothing ran on Ryan's PC.

![chorus_C11 preview](preview.jpg)

**Start here, the whole ship first (R229):** [whole beside whole](../../../shots/issue_623_chorus/c11_whole_compare.jpg), then
[side against side](../../../shots/issue_623_chorus/c11_side_compare.jpg), [plan against plan](../../../shots/issue_623_chorus/c11_top_compare.jpg),
the [bow](../../../shots/issue_623_chorus/c11_bow_compare.jpg) and the [stern](../../../shots/issue_623_chorus/c11_stern_compare.jpg).
The two classes from above at one scale: [c10_c11_classes.jpg](../../../shots/issue_623_chorus/c10_c11_classes.jpg).
Then [side_by_side.jpg](side_by_side.jpg), [cells.jpg](cells.jpg) and [fit_view.jpg](fit_view.jpg).

## What it is

A short, fat hunter that closes fast and chews (Razormaw, blood frenzy). Two open throats side by side at the blunt bow are one
bile battery; a jagged crest of bone ram blades grows out of an open wound down its back, with smaller shards along each
shoulder; behind them a mane of boarding tendrils streams up and aft; three bile sacs a side feed the throats through veins; a
ring of six pulse vents with glowing filaments drives it.

## Two classes (the brief's question)

C10 is long and tapering (hull length to beam 5.9, to height 6.0): a folded double mouth, a tendril crown, hanging brood sacs,
a shoulder trim and a vent crown with membranes. C11 is short and broad (2.5 and 2.8): two open flared throats, a bone blade
crest, a streaming mane, domed sacs and a filament ring. From above at one scale they share nothing but the hide and the
family grammar ([c10_c11_classes.jpg](../../../shots/issue_623_chorus/c10_c11_classes.jpg)).

## The checks

| Check | Result |
|---|---|
| Views agree (side, top, bow): length, beam, height | 0.0, 0.0 and 0.09 percent apart; length 14.54 on the views, 0.1 percent over the class (model 14.51) (checks.json, PASS) |
| Fit check (R217, R219, R221): clash, mount, arc, sweep, exhaust, exit, lane | **0** in all seven ([fit_report.md](fit_report.md), [fit_view.jpg](fit_view.jpg)) |
| Machines on a seam (R226) | **0** of 13 machines (2 throats, the mane, 6 vents, 4 siphons) across 2 seams |
| Insides inside the skin | 0 of 5,764 inside vertices within 0.15 of the skin |
| Inventory (R218, R221) | 14 lines, every one with a job; 0 not present, shaped and detailed ([inventory.md](inventory.md)) |
| Outline overlap at the concept's camera (reported, not a bar) | 82.2 percent ([outline_check.jpg](outline_check.jpg)) |
| Proportions, hull length to beam / to height (concept sheet against build, same measure) | 2.78 / 3.44 against 2.49 / 2.82 (the build is broader and deeper through the middle; see below) |

### Detail density per part type (R224, measured on the blockout; numbers in [density_seams.json](density_seams.json))

**None flagged** (no part type under 0.75 of the hull on either measure).

| Part type | Triangles per unit2 (vs hull) | Edge features per unit2 (vs hull) |
|---|---|---|
| hull (body, hide pads, pore fields, blades, wound, folds, veins, scars) | 249.9 (1.00) | 169.0 (1.00) |
| spinal (the two throats) | 256.6 (1.03) | 134.0 (0.79) |
| sac (the bile sacs) | 246.0 (0.98) | 135.4 (0.80) |
| gun (the mane) | 450.7 (1.80) | 346.2 (2.05) |
| engine (the six vents and filaments) | 794.6 (3.18) | 457.7 (2.71) |
| thruster (the siphons) | 833.5 (3.34) | 377.0 (2.23) |

## Weapons, each from the lore (R221)

| Slot | Weapon | Built as |
|---|---|---|
| F | Spine volley (bioplasma) | the two throats, one battery: a fat rolled lip with fine radial wrinkles, a lit throat lining, a sphincter, a ring of chitin spines deep in the bore, the bile gland glowing at its back. Fixed forward. |
| T | Boarding tendrils (tendril) | a mane of thirty hooked tendrils on a muscle crest behind the blade row, each with grip rings, a chitin barb and acid pores, streaming up and aft. Fixed: a mane reaches every way at once (not marked as a turret). |

## INSIDE (R209): flesh, bone and organs, never rooms that reach the skin

Bone hoops for frames (10 stations), two membrane septa, and organs: the two bile glands behind the throats, the Node, the ram
muscle under the blade row, six bile stores behind the sacs, the heart vat (the core, hp_core), the fore and aft guts, two
regrowth chambers, the mane's root muscle and the pulse bladder that feeds the six vents. Break lines by the Chorus rule: B-1
behind the head (the throats tear away with the brow), B-2 ahead of the mane (the stern half tears through the heart vat's aft
end, the sacs bursting first); ragged plan paths, no machine on either. Four breach anchors (Cruiser base 4; the Chorus extra
is for the big ones).

## Changed from the picture (R207)

1. **Colour**: bile yellow-green light over dark olive flesh, pale ochre bone (R204, the lore). The picture is green-brown with amber light.
2. **The two throats are one battery**, the Spine volley (bioplasma F): b_razor has one bioplasma slot, both throats fire it. R184's single throat stays a later fleet-sheet question; the accepted picture has two.
3. **The plume on the back is the boarding tendrils** (tendril T), a fixed mane on a muscle crest; its roots stop well forward of the stern so no tendril hangs in a vent's jet.
4. **The bone ridge is a crest of ram blades** in jagged clusters growing out of an open wound channel, with smaller shards lying back along each shoulder (the plan's separate pale plates). The profile is the view of record for the row (README 8b).
5. **The domes are bile sacs** feeding the throats; veins run forward to the throats (every part has a job, R221).
6. **The stern is a ring of six pulse vents**, each with three glowing filaments splayed outward (the picture's amber nodes and filament plume; no nozzles). The filaments are about a third of the picture's so the ship is 14.5.
7. **Siphons added**, a pair forward and a pair aft.
8. **The small spines along the lower stern are cut**: no job (R221).
9. **The brow and chin** are grown masses round the throats, so the throats sit in a rounded head and the head's front stops behind the glands (the throats glow from inside, as the picture).

## What still differs from the concept, and why

- **Broader through the middle** than the concept sheet's median measure (hull length to beam 2.49 against 2.78): the body is
  built to the sheet's widest stations (5.2 across) and the sacs stand proud of the flank. If Ryan wants it leaner, it is one
  scale on the body sections.
- **The bone crest** is cleaner and more regular than the picture's broken, branching bone; the fine breaks and pitting are paint
  and a later pass on the blade shape.
- **The hide's surface** (fine wrinkles, wet sheen, mottling) is paint: recipe stages 4 and 5.
- **No underside view** on the concept sheet: the belly is designed here.

The blockout .blend is not on Ryan's PC (nothing ran there); build.py rebuilds it from `tools/blender/build_sheets/ships/chorus_C11.py`.
