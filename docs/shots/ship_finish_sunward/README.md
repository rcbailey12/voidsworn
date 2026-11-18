# Sunward Crusade satin finish

Refs #1036. The Sunward sheet stack uses the approved satin finish with its own black iron,
carbon soot, frost markings and ember lights. The recipe describes the coat, worn edges and tone steps on modeled plates.
[Approved finish](../ship_finish_1118/README.md) · [Paint stack](../../../tools/blender/kits/voidsworn/stack.py) · [Recipe](../../ship_pipeline/RECIPE.md#the-paint-stack-for-sheet-ships-issue-601-shipsmd-section-0-item-2)

## Main baseline

All 42 installed files for these six ships matched main `778a7411` by SHA-256. Each intact export uses one exterior
material. The triangle column counts the intact mesh by its named GLB node. The bytes cover the complete installed bundle,
including the damage and wreck GLBs. Each ORM and emissive map is 2048 × 2048. The paint lint column counts adjacent
pairs at or above 18 dE76. All six baseline hulls passed. [Ship manifest](../../../godot/assets/ships/manifest.json)

| Ship | Intact triangles | Albedo and normal maps | Bundle bytes | Baseline paint lint | Battle-camera change |
|---|---:|---:|---:|---:|---|
| `V1b_r_23` | 132,449 | 4096 × 4096 | 48,853,541 | 68 / 2,647 | Pending |
| `V14_23` | 76,931 | 2048 × 2048 | 34,575,472 | 46 / 1,728 | Pending |
| `V15_37` | 40,611 | 2048 × 2048 | 31,066,961 | 55 / 1,112 | Pending |
| `V16_37` | 60,341 | 2048 × 2048 | 51,604,850 | 32 / 1,002 | Pending |
| `V17_37` | 91,142 | 4096 × 4096 | 58,214,671 | 32 / 1,130 | Pending |
| `V18_51` | 129,915 | 4096 × 4096 | 58,670,229 | 147 / 2,577 | Pending |

## Rebuild status

Main's six exports come from the A4 ship chain. The only matching game code in the current Sunward sheet recipes is
`V1b_r_23`. That recipe builds S8, a different Daybreak model. The sheet describes changes to its prow, hull and fittings.
Using it would change the geometry being compared. The other five codes have no sheet recipe. A shape-preserving rebuild
needs a route from the original A4 meshes and their atlas into the Sunward stack.
[A4 ship chain](../../../tools/blender/a4/README.md) · [S8 build sheet](../../ship_pipeline/build_sheets/voidsworn_S8/README.md)

Lane D is code only under Rulebook 3.4. The stage 5 to 7 exports and isolated install, manifest size changes, new paint lint,
stamped battle-camera and radius-26 sheets, fleet comparison, and solo scene 207 measurement are pending.
