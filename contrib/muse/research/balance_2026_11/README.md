# Balance proposals, 2026-11

Job 3 of the Nov 1, 2026 four-job commission (contrib/opus/briefs/muse_2026-11-01b_four_jobs.md). Question: the shipped full-run simulator shows bot win rates from 34 percent (Sunward Crusade) to 80 percent (the Chorus); explain the spread from the data, then propose small numbers-only data.js changes that close it to roughly 10 points while keeping a human first run very hard (R62) and respecting R63 (Eclipse stronger and more expensive, the Chorus the cheap opposite).

## Files

- synthesis.md: the chair synthesis. Verdict, reconciled diagnosis, the recommended 18-edit package with its measured results, the tested-and-rejected second package, and the four items that need Ryan's call.
- sim_results.md: every measured run behind the synthesis. Baseline (three executions), single-lever isolation runs, and packages v1, v2, and v3.
- legs/rey_leg.md, legs/deepseek_leg.md, legs/qwen_leg.md, legs/argon_leg.md: the four review legs, verbatim. The Argon leg was screened out for invented facts; the reasons are in the synthesis, section 4. DeepSeek and the Rey leg were written against a pack built from the first of three baseline executions, whose fine detail (admiral and sector splits) later proved anomalous; the synthesis follows the agreed execution.

## Headline result

Recommended package v2, measured twice with identical results: Crusade 34 to 64, Hegemony 54 to 70, Hullbreakers 62 to 60, Chorus 80 to 64, Glasswrights 64 to 68, Eclipse 72 to 72. Spread 46 points down to 12. The two levers the legs liked most, softening the torpedo evasion multiplier and trimming Chorus regeneration, both measured at or near zero on their own; the Chorus lever that works is its weapon damage, and the Crusade fix is hull points plus its broadside bonus plus its carrier price.
