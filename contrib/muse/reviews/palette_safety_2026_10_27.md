# Palette safety check: faction effect colours (Oct 27 program, item 10)

Date: Oct 27, 2026. Basis: `godot/fx/faction_looks.json` at repo HEAD 68b42ce406286eb95ea7df6aaf3f683c1231b51d, read from the live file in the working clone (not the rollout pack copy). Lane: Rey evidence pack. The readings below are OBSERVED (computed from the file); the practical read at the end is INFERRED and is offered as observations for the G4 and A4 lanes, not as orders.

## Purpose

Check whether the six factions' effect colours stay distinguishable from each other, and whether each faction's weapon colour stays distinguishable from its own glow colour, under normal vision and under simulated red-green colour vision deficiency. This is the computed half of palette safety: flat colour values only, no screenshots, no in-engine rendering.

## Method

- The file stores no hex values and has no hull or primary field. Colours are linear RGB triples (0 to 1 floats) for effect fields: weapon, shield, engine, damage_glow, hull_fix, a three-stop nebula ramp, accent, and shield_edge. Hex values quoted here are the sRGB encoding of the stored linear triples. Two stored values exceed 1.0 (Chorus hull_fix blue 1.35, Eclipse hull_fix blue 1.3, HDR rim tints) and were clamped for display hex only.
- Primary colour per faction = the weapon colour, each faction's signature effect colour. Engine colours were run as a sensitivity check.
- Glow colour per faction = the accent field where present. Hegemony and Chorus have accent set to null, so their damage_glow stands in (the file's own doc defines damage_glow as the faction's lit glow colour). Weapon against damage_glow was also computed for all six factions for uniformity.
- Contrast is the WCAG luminance ratio. Because the stored values are already linear, the display-true WCAG luminance is the weighted sum of the stored triple (0.2126 R + 0.7152 G + 0.0722 B). The raw output also prints the values obtained by treating the stored numbers as sRGB; the ranking does not change.
- Colour vision simulation: Machado, Oliveira and Fernandes (2009) matrices at severity 1.0, applied in sRGB space, for protanopia and deuteranopia.
- Distances are Euclidean in 0 to 255 RGB space. The maximum possible distance is about 441.

## Headline numbers

1. Worst primary against own glow contrast: Chorus at 1.02:1 (weapon #DDF176 against damage_glow #D4F66F). Hegemony is nearly as flat at 1.03:1. Every faction sits between 1.02:1 and 1.40:1, so a faction's weapon colour and its own glow colour are never separable by brightness, only by hue.
2. Least distinguishable faction pair in normal vision: Hegemony against Eclipse weapon colours, RGB distance 45.4 of about 441 max (pale steel blue #C4EAFF against violet white #DDC4FF).
3. Under protanopia, Hegemony against Glasswrights closes to 31.6 (both near-white blues).
4. Under deuteranopia, Sunward Crusade against Chorus closes to 29.7 (ember orange against bile yellow-green), with Hegemony against Eclipse close behind at 30.0.
5. No pair fully collapses under either simulation: nothing falls below 29.7 on a scale of about 441, so the six primaries stay pairwise distinguishable for red-green colour vision on paper.
6. The risk zone is the pale cluster: Hegemony, Glasswrights and Eclipse stay within 30 to 61 of each other in every vision type tested (full pairwise values in the tables below).
7. Engine colours are worse than weapon colours. Hegemony against Eclipse engine colours fall to 14.6 under deuteranopia, the smallest distance computed anywhere in this pack. In normal vision the smallest engine pair is Sunward Crusade against Ashfall Hullbreakers at 30.6.
8. The two white-golds: Hegemony damage_glow #FFDDA6 and Eclipse accent #FFECBC are only 26.8 apart in normal vision, the closest cross-faction pair computed anywhere in this pack, and stay close under both simulations (29.0 protanopia, 26.0 deuteranopia). Both are called white-gold in the file's own field doc.

## Per-faction contrast: weapon against own glow

| Faction | Weapon | Glow used | Contrast | Weapon vs damage_glow |
|---|---|---|---|---|
| Sunward Crusade | #FFC47C | accent #E7F3FF | 1.40:1 | 1.06:1 (damage_glow #FFBC69) |
| Hegemony | #C4EAFF | damage_glow #FFDDA6 (accent null) | 1.03:1 | 1.03:1 |
| Ashfall Hullbreakers | #F98159 | accent #FF593F | 1.23:1 | 1.16:1 (damage_glow #FF954B) |
| Chorus | #DDF176 | damage_glow #D4F66F (accent null) | 1.02:1 | 1.02:1 |
| Glasswrights | #F6FAFF | accent #F1F3FA | 1.06:1 | 1.05:1 (damage_glow #EDF6FF) |
| Eclipse | #DDC4FF | accent #FFECBC | 1.35:1 | 1.06:1 (damage_glow #DDBCFF) |

Uniform check: measured against damage_glow for all six, every faction falls between 1.02:1 and 1.16:1.

## Pairwise distances, weapon colours

Normal vision (smallest per vision type in bold):

| Pair | Distance |
|---|---|
| Sunward Crusade vs Hegemony | 149.1 |
| Sunward Crusade vs Ashfall Hullbreakers | 75.2 |
| Sunward Crusade vs Chorus | 57.2 |
| Sunward Crusade vs Glasswrights | 142.7 |
| Sunward Crusade vs Eclipse | 135.9 |
| Hegemony vs Ashfall Hullbreakers | 203.3 |
| Hegemony vs Chorus | 139.8 |
| Hegemony vs Glasswrights | 52.9 |
| Hegemony vs Eclipse | **45.4** |
| Ashfall Hullbreakers vs Chorus | 119.0 |
| Ashfall Hullbreakers vs Glasswrights | 205.6 |
| Ashfall Hullbreakers vs Eclipse | 181.1 |
| Chorus vs Glasswrights | 140.0 |
| Chorus vs Eclipse | 144.7 |
| Glasswrights vs Eclipse | 60.3 |

Protanopia simulation (Machado 2009, severity 1.0): smallest pair Hegemony vs Glasswrights **31.6**; next closest Sunward Crusade vs Chorus 47.9 and Hegemony vs Eclipse 45.1; all other pairs 76.8 or above.

Deuteranopia simulation (Machado 2009, severity 1.0): smallest pair Sunward Crusade vs Chorus **29.7**; next closest Hegemony vs Eclipse 30.0 and Hegemony vs Glasswrights 41.5; all other pairs 71.5 or above.

Sensitivity check, engine colours: smallest pair 30.6 in normal vision (Sunward Crusade vs Ashfall Hullbreakers), 31.7 under protanopia (Hegemony vs Eclipse), 14.6 under deuteranopia (Hegemony vs Eclipse). The pale cluster is also tight on engines: Hegemony vs Glasswrights 61.3 and Glasswrights vs Eclipse 59.5 in normal vision.

## Practical read (observations for the G4 and A4 lanes)

- Faction identity cannot ride on brightness. With weapon against glow contrast between 1.02:1 and 1.40:1 for all six factions, any effect, UI element or readability rule that separates weapon fire from a faction's own glow by brightness alone will fail everywhere. The same-family pairing reads as deliberate design; the constraint is that hue and shape have to do all the separating work.
- The pale cluster needs non-colour support. Hegemony, Glasswrights and Eclipse are three near-white palettes whose weapon, engine and glow colours all sit close together in every vision type tested. Silhouette, iconography, naming on screen, or distinct effect shapes are what will keep them apart in play; colour alone is the weakest channel exactly where three factions share it.
- The white-gold overlap is a concrete on-screen risk. If a Hegemony ship's damage glow and an Eclipse engine corona (accent) are ever on screen together, colour alone will not tell a player which faction either belongs to (26.8 apart, and no better under either simulation).
- Engine tint is a poor faction tell. It is the least separable channel computed, down to 14.6 for Hegemony against Eclipse under deuteranopia, so engine colour should not be the only faction cue in any shot or UI treatment.
- The palette is not broken. No primary pair fully collapses under red-green colour vision simulation, and the saturated factions (Sunward Crusade, Ashfall Hullbreakers, Chorus) separate well from everyone except each other under deuteranopia (29.7 for Crusade against Chorus). The exposure is concentrated: brightness-based distinctions anywhere, and colour-only distinctions inside the pale cluster.

## Scope limits

- Effect colours only. Actual hull paint lives in ship materials and textures, not in faction_looks.json, and was not analysed. The one hull-adjacent field, hull_fix, is a blue rim tint for every faction by design (per the G4 notes) and is not a faction distinguisher.
- Distances are computed on flat colour swatches. In game, effects are small, brief and layered over dark backgrounds, which compresses perceived differences further; treat the pale cluster numbers as optimistic.
- Severity 1.0 is the worst case for both simulations (complete protanopia and deuteranopia). Partial deficiencies will sit between the normal and simulated values.
- Shield colours, shield_edge and the nebula ramps were extracted in the raw output but are not part of the headline comparisons; Chorus and Eclipse have no shield colour at all (shielded: false), which matches their shieldless design.

## Reproducibility

The computation script (palette_analysis.py, Python standard library only) and the full raw output (palette_raw.txt, including every extracted colour field, both luminance readings, and all pairwise tables) live in the Oct 27 program working folder and can be re-run against a revised faction_looks.json. The script's source path points at the working clone copy of the file, so a re-run against a different checkout needs that path updated.
