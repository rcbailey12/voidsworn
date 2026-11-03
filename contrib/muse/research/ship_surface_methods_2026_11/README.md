# Ship surface methods research (issue #112)

How shipped space games and working hard-surface artists make detailed ships that stay clean, with no waves and no blobs, and how to clean up AI-generated meshes in production. Feeds the Pyre-Barge round 2 comparison in issue #111.

## Contents

- synthesis.md: the chair synthesis. Headline and ranked recommendation first, per-method table, studio evidence by game, the AI mesh cleanup pipeline with the corrected high-pass bake recipe, what this changes or confirms for #111, screening notes, five owner questions with chair picks, Not checked.
- legs/deepseek.md: DeepSeek writer leg (DeepThink and Search on), filed as returned.
- legs/qwen.md: Qwen writer leg (Qwen3.8-Max, both model gates passed), filed as returned.
- legs/argon_review.md: Argon review leg (Argon High, reviews and ideas only per R81), filed with the chair screening header that records what was used and what was screened out.

## Headline

More triangles do not smooth out the waves. A wave is the surface sitting in the wrong place; subdivision only gives the wrong surface more resolution. Studios avoid waves by construction: parts, flat panels kept flat, bevels with weighted normals, and detail carried in bakes, trim sheets and decals.

Ranked for the Pyre-Barge round 2: variant 1 (A+ rich surface) first for this flagship, variant 2 (clean shell plus high-pass or cavity-only bake) second for the ship and first as the fleet default if its crop test passes, variant 3 (reused AI chunks) third and limited to small, hard-edged parts.
