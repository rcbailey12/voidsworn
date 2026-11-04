# Issue #135: graphics leaps research (deaths and weapons, nebulas and storms, planets)

Research commissioned by Ryan's Nov 3, 2026 playtest notes (FINDINGS R88): not 10 percent improvements, but 50 to 75 percent jumps in three areas, in his order: ship deaths and weapon hits, nebulas and ion storms, and planets (rocky and terran especially).

## Contents

- synthesis.md: the chair synthesis. Headline leaps, the verdict on Opus's hypothesis (holds for nebulas, half for planets, fails as stated for deaths), the settled design per area with build orders for Codex, the shared art direction section (including the answer to "should fire work like that in space": no, not as the default), screening notes, and five owner questions with chair picks.
- legs/rey_leg.md: the blind Rey leg, run as an addendum at the owner's instruction after the synthesis (see synthesis section 10). It converges with the synthesis on every settled point.
- legs/deepseek.md: DeepSeek writer leg, filed raw. Its bibliography is the verified one (Homeworld 3 damage breakdown, EVE GDC 2024, Elite Dangerous, Star Citizen).
- legs/qwen.md: Qwen writer leg, filed with its gate line. Used where it converges with the pack and the code; its citations were fabricated and are stripped in the synthesis (see the synthesis screening notes).
- legs/argon_review.md: Argon review with a chair screening header. Used in large part: source audit, engine corrections, and three techniques neither writer had.

## Settled in one paragraph

Deaths lose the raymarched fireball entirely and gain baked flipbook gas (optical-flow blended, lightmapped) plus a four-beat choreographed breakup on an extended runtime slicer, all inside fx_death.gd and fx_weapons.gd with the R80 surfaces untouched. Nebulas become hybrid FogVolumes carrying the R82 colours (ramp split across EMISSION and ALBEDO) under a thinned billboard edge layer, with lightning let into the fog at max tier and a froxel preparation fix (camera near plane and fog length) that costs nothing. Planets keep the 4096x2048 GPU bake and gain geology in the shader: Voronoi tectonic plates, domain-warped continents, derivative pseudo-erosion, constant-width coastal shelves, biome ramps and spherical normal maps, terran and rocky first.
