# Ship pipeline research (board issue 76)

## What this pack is

Research into how shipped space games build fleet ships at a tactical camera (Battlefleet Gothic: Armada, Homeworld 3, Sins of a Solar Empire 2, Battlestar Galactica Deadlock, and Starsector for 2D contrast), how small teams turn AI generated meshes into clean game assets, and what route our 36 hulls should take to kill the four defects from the Nov 2 playtest: waviness, bumps, grid like texture, and odd paint.

## Verdict

GO WITH CONDITIONS. Recommendation: Route C, a tiered hybrid. A universal foundation for all 36 hulls (projected concept paint and runtime box projected UVs deleted, normals never baked from the raw AI mesh, FAC3D the single colour source with baked maps as masks only), an automated planar cage cleanup plus 5 shared faction kit libraries for the 30 machine meshes, SHELL=1 lofted shells reserved for the 5 machine faction flagships and any bow that fails the blob sweep gate, and a dedicated bio branch for the 6 Chorus organic meshes.

The one condition: the flagship split inside Route C is confirmed against the issue 75 bake-off pictures when they land. Issue 75 is blocked and has no results yet. Everything else in the pack is actionable now.

## How to use it

- Input to the issue 75 bake-off judgement: section 8 of the synthesis is the rubric for the three bake-off hulls (Eclipse zenith cruiser, Warlord's Pyre-Barge, Ninefold Maw), with what each outcome changes in the Route C split.
- Input to Opus sequencing: section 6 is the build order (automation first, one calibration hull per branch), and section 7 gives the three leg pricings with their units and assumptions. No measured per-hull number exists yet; the calibration hulls replace the estimates.
- Four owner questions sit at the end of the synthesis, chair pick marked on each.

## Files

- synthesis.md: the chair synthesis. Sections: verdict and recommendation; the problem and settled points; what the five games do and how well it is sourced; the shared cleanup pipeline; Route C in full; defect outcomes per route; build order; effort, honestly; the bake-off rubric; risks; screenings; owner questions; dissents; not checked.
- legs/rey_leg.md: the blind Rey leg, filed as written.
- legs/deepseek_leg.md: the DeepSeek leg, filed raw.
- legs/qwen_leg.md: the Qwen leg, filed as a record. Largely non-responsive to the leg prompt and screened in the synthesis; nothing in the pack rests on it alone.
- legs/argon_leg.md: the Argon leg with its chair screening header. Used selectively (Route C shape, defect table, bake-off rubric); its per-game production specifics are treated as unverified and its effort total is not adopted as the price.
