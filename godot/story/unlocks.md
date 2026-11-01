# Arc unlocks: one hull variant per faction (draft for stream B)

Status: built by stream B (data.js HULL_VARIANTS, arc field); names updated to lore round 8 on Oct 31. Ryan (Oct 26) wants finishing a faction arc to give both a cosmetic reward and a gameplay unlock. The cosmetic side (medal, Chronicle entry, arc title, flagship paint) is built in the story layer (`godot/story/data/arcs.json`). The gameplay unlock below changes rules and balance, so **stream B owns it**: the numbers here are a starting point to be sim-checked (playtest-and-balance skill), not final.

## How it would work

- Each unlock is a row in data.js `HULL_VARIANTS`, in the same shape as today's variants (`base`, `n`, `d`, `w`, `mod`), so the existing variant rails do the rest: once unlocked, it is sold in that faction's shipyards beside the standard hull.
- It is **earned, not bought**: `cost: 0` plus a new field such as `arc: '<faction>'`. The Progression screen's "Hull variants" tab lists it as "Finish the <arc> story", and it cannot be bought with renown.
- Unlocking writes `META.variants[id] = true` (the campaign profile, so the campaign rules see it). The trigger is the arc finishing: beat 3 won, which is the Nemesis's last fight. Stream B and G3 decide where that write lives. The story layer also keeps its own record (`story.arc_unlocks()`), for display only.
- Power target: a **sidegrade** with a clear identity, about as strong as today's variants of the same base. Never strictly better than the base hull.

## The six

Names follow lore round 8 (R59, `contrib/opus/compute/rename_map_final.md` section 8). The live numbers are stream B's rows in data.js `HULL_VARIANTS` (they were sim-tuned after this draft: cb55ec9, 47a101a); this table keeps the idea behind each one.

| Faction | Unlock (id) | Base hull | Idea | Why it fits the arc |
|---|---|---|---|---|
| Sunward Crusade | **Vigil lance-cruiser** (`vs_penitent_l`) | Vigil-class cruiser | Two prow lances and a dorsal battery turret instead of the broadsides: its heavy punch points one way. | The siphon burned out: two beams of fire from the prow. |
| Hegemony | **Cordon column escort** (`h_interdictor_e`) | Cordon destroyer | Adds a flak turret, paid for with a lighter hull and one hex of speed. | The nineteen-year-old lieutenant who held the column: built to stand beside the line, not to chase. |
| Hullbreakers | **Trophy wrecker** (`c_marauder_g`) | Hullbreaker wrecker | A second prow torpedo instead of flak, and one hex slower. | Plated with trophies from the hunt for Rook, and far too many rockets. |
| Chorus | **Sun-eater bladeback** (`b_razor_e`) | Chorus bladeback | Its tendril cluster becomes a second spine volley on a turret; regrows more, one hex slower. | Fed on the warm keys: heavier, hotter, slower. |
| Glasswrights | **Ringing aperture** (`i_carrier_a`) | Glasswright aperture | A third wing, paid for with lighter shields and one hex of speed. | Built from Ringing Field glass on the voyage home with the last lens. |
| Eclipse | **Archive guard flare** (`d_jackal_h`) | Eclipse flare | Both null cannons on turrets and a null spire, 10 less hull. | The array's guard frames, standing watch on every side. |

## For stream B (rules side)

1. Add the six rows to `HULL_VARIANTS` with `cost: 0` and `arc: '<faction>'`; keep them out of the renown shop.
2. Unlock trigger: when the arc's beat 3 fight is won, set `META.variants[id] = true` (in the same place the Nemesis's death is decided).
3. Sim-check each against its base (bossmatrix and fmatrix with the variant in the starting fleet). Target: within a few points of the base hull's win rate.
4. Export to Godot through the tables exporter as usual; G1 and G3 pick it up from the data, with no new code paths.

The cosmetic rewards need nothing from stream B.
