# Arc unlocks: one hull variant per faction (draft for stream B)

Status: DRAFT. Ryan (Oct 26) wants finishing a faction arc to give both a cosmetic reward and a gameplay unlock. The cosmetic side (medal, Chronicle entry, arc title, flagship paint) is built in the story layer (`godot/story/data/arcs.json`). The gameplay unlock below changes rules and balance, so **stream B owns it**: the numbers here are a starting point to be sim-checked (playtest-and-balance skill), not final.

## How it would work

- Each unlock is a row in data.js `HULL_VARIANTS`, in the same shape as today's variants (`base`, `n`, `d`, `w`, `mod`), so the existing variant rails do the rest: once unlocked, it is sold in that faction's shipyards beside the standard hull.
- It is **earned, not bought**: `cost: 0` plus a new field such as `arc: '<faction>'`. The Progression screen's "Hull variants" tab lists it as "Finish the <arc> story", and it cannot be bought with renown.
- Unlocking writes `META.variants[id] = true` (the campaign profile, so the campaign rules see it). The trigger is the arc finishing: beat 3 won, which is the Nemesis's last fight. Stream B and G3 decide where that write lives. The story layer also keeps its own record (`story.arc_unlocks()`), for display only.
- Power target: a **sidegrade** with a clear identity, about as strong as today's variants of the same base. Never strictly better than the base hull.

## The six

| Faction | Unlock (id) | Base hull | What changes | Why it fits the arc | Rough power vs the base |
|---|---|---|---|---|---|
| Voidsworn | **Penitent lantern-cruiser** (`vs_penitent_l`) | Penitent cruiser (cp 3, 120 hull, prow lance + two 6-damage broadsides) | Both broadsides give way to a second prow lance; a flak turret is added. `w: [['lance','F'],['lance','F'],['flak','T']]` | The relit beacon: two beams of light from the prow, like the first oath-fleet. | Twice the prow punch (2 x 20 against 20 + 2 x 6), but every big gun points one way, so it needs good facing and is weak to flankers. Even overall, sharper in skilled hands. |
| Hegemony | **Interdictor column escort** (`h_interdictor_e`) | Interdictor destroyer (cp 2, 74 hull, 18 shields, ion prow + turbolaser turret) | Adds a flak turret; shields 18 to 24; speed 4 to 3. `w: [['ion','F'],['turbo','T'],['flak','T']]`, `mod: {sh: 24, sp: 3}` | The nineteen-year-old lieutenant who held the column: a ship built to stand beside the line, not to chase. | Tougher and better at stopping torpedoes and wings; slower, so worse at interdiction runs. Slightly defensive sidegrade. |
| Corsair | **Gilded marauder** (`c_marauder_g`) | Corsair marauder (cp 3, 120 hull, two scatter broadsides, torpedo, flak) | Swaps the flak for a second prow torpedo; plated in saints' gold: hull 120 to 140, speed 4 to 3. `w: [['scatter','P'],['scatter','S'],['torp','F'],['torp','F']]`, `mod: {hp: 140, sp: 3}` | Bought with the treasure fleet's gold, and far too many torpedoes, as Corsairs like it. | A huge opening salvo and more hull, but no point defense and slower to close. Even; strong against big slow targets, weak against carrier fleets. |
| Chorus | **Sun-eater razorfiend** (`b_razor_e`) | Chorus razorfiend (cp 3, 150 hull, regrows 9 a round, tendril turret + bioplasma prow, speed 4) | Regrowth 9 to 13; a second bioplasma spitter on the prow; speed 4 to 3. `w: [['tendril','T'],['bioplasma','F'],['bioplasma','F']]`, `mod: {regen: 13, sp: 3}` | Fed on the dead star's heart: heavier, hotter, slower. | More staying power and forward damage; loses the speed a razorfiend uses to reach the back line. Sidegrade, better in long brawls. |
| Ithar | **Archive wraithcarrier** (`i_carrier_a`) | Ithar wraithcarrier (cp 5, 140 hull, 28 shields, 2 wings, pulsar lance + turret) | Carries the light-archive instead of its lance: 3 wings instead of 2, shields 28 to 30, the prow lance removed, a flak turret added. `w: [['turret','T'],['flak','T']]`, `mod: {hangar: 3, sh: 30}` | The houses' memory carried home, guarded by starlings (Aelith's arc of wings). | More wings, no lance of its own. Pure carrier: stronger with carrier admirals and wing doctrines, weaker alone. Even. |
| Deathless | **Court guard destroyer** (`d_jackal_h`; the hull is data.js `d_jackal`, which stream B's rename map may rename) | Deathless destroyer (cp 2, 110 hull, gauss turret + gauss prow) | The prow gauss moves to a turret; a gauss sentry is added; hull 110 to 120. `w: [['gauss','T'],['gauss','T'],['gsentry','T']]`, `mod: {hp: 120}` | The first court's honour guard, standing watch on every side. | Fires in every direction and shoots down craft, with a little more hull; no extra damage. Mild defensive upgrade; watch it in sims, since turrets on a cheap hull add up. |

## For stream B (rules side)

1. Add the six rows to `HULL_VARIANTS` with `cost: 0` and `arc: '<faction>'`; keep them out of the renown shop.
2. Unlock trigger: when the arc's beat 3 fight is won, set `META.variants[id] = true` (in the same place the Nemesis's death is decided).
3. Sim-check each against its base (bossmatrix and fmatrix with the variant in the starting fleet). Target: within a few points of the base hull's win rate.
4. Export to Godot through the tables exporter as usual; G1 and G3 pick it up from the data, with no new code paths.

The cosmetic rewards need nothing from stream B.
