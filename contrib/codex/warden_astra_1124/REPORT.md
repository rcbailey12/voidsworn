# Astra Warden | S9A

[Three-quarter](shots/voidsworn_S9A_three_quarter.png) · [Side](shots/voidsworn_S9A_side.png) · [Top](shots/voidsworn_S9A_top.png) · [Underside](shots/voidsworn_S9A_underside.png) · [Battle 170](shots/voidsworn_S9A_battle_170.png)

I read the Warden as a knife built around its gun. The three barrels sit above a narrow forged point. Ten cross-sections carry that point into a low deck and a broad drive block. The widest part of the pressure hull sits at 72 percent of its length. I would borrow the continuous radiator carrier for the other build. It gives the three spires a common footing and lets them come away together behind the flak pair. [Approved beauty](../../../docs/ship_pipeline/build_sheets/voidsworn_S9/concept_beauty.jpg) · [Concept sheet](../../../docs/ship_pipeline/build_sheets/voidsworn_S9/concept_sheet.jpg)

| Part | Build route |
| --- | --- |
| Pressure shell, gun saddles, dorsal feed rail and radiator carrier | Hand-built. The flanks step inward under the weapon band. The rail has splice straps and the carrier has a stepped command face. |
| Armour, louvres, windows, running lights and steering jets | Sunward kit. Triangular plates run toward the point. Longer riveted courses follow the shoulders. Four shutter banks vent each flank. |
| Bow gun, flak and engines | Sunward Sear repeater at 14 percent, one pair of twin Spark flak tubs at 60 percent, two 0.55-unit bells on 0.40-unit offsets. |
| Radiators | Shared Sunward slatted radiators at 68, 76 and 84 percent. The centre spire stands 0.63 units tall. The count and reduced height follow the table and R331. |
| Belly, decks and machinery | Three Sunward access hatches. Hand-built decks, open frames, magazines, crew spaces, side galleries, reactor, coolant lines and drive feeds. One lengthwise break follows the lower edge of the weapon band. Another releases the spires. |

The feature table resolves the extra tubs and spire in the artwork. I designed the underside around three access points. I used only the two approved pictures from the S9 sheet folder. I did not inspect the accepted build, its files or history, the installed V14_23 hull, the Opus branches, or any PR or issue comment.

**Build and paint** · [Build sheet](../../../tools/blender/build_sheets/ships/voidsworn_S9A.py) · [Parts inventory](../../../tools/blender/build_sheets/ships/voidsworn_S9A_inv.py) · [Recipe](../../../tools/recipe/ships/voidsworn_S9A.json) · [Proof manifest](manifest.json) · [Packed CPU-painted Blender model](S9A_painted.blend)

**Budget.** The 6.5-unit painted exterior has 30,822 triangles. With the two flak turrets articulated, the proof has eight exterior material surfaces, or eight draws per material pass. The interiors add 2,568 triangles. The packed model contains six 2048-square hull and parts maps and a 1024-square engine emission map. The Board's export supplies the final game budget.

The CPU bake used the Picket proof driver with `R209_SHIP` set to the S9A recipe and arguments `OUT unused unused S9A 2048 8`. Battle 170 uses the Picket proof's lens, distance and native pixel scale. [CPU bake driver](../picket_astra_1122/paint_proof.py) · [Five-view renderer](review_views.py)

**Check output**

```text
Blender 4.5.14 LTS, CPU Cycles, Sunward stack, 8 bake samples
Fit         0 problems | 29 fitted parts, 252 close pairs, 266 rays
Weapon      PASS | 3 forward autocannon muzzles, 2 twin flak turrets
Inventory   0 failing
Seams       PASS | 0 machines across a break, 0 floating groups
Outline     73.1% overlap with the beauty cutout at the sheet camera. The drive block reads broader in this view.
```

**Standing checks.** Of 122 checks, 117 passed, two matched known baselines and three failed. The GPU-slot and runner-stall checks both passed on individual retries. The fleet index still needs a Board decision. Its generator lists every recipe for `V14_23`, so adding the required S9A recipe makes `FLEET.md` stale. Updating that page falls outside this job's four permitted recipe and sheet files.

The Board owns recipe stages 1 through 7, in-game captures and the painted comparison with the other Wardens. Refs #1889.
