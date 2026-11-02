# Onboarding design, 2026-11

Job 4 of the Nov 1, 2026 four-job commission (contrib/opus/briefs/muse_2026-11-01b_four_jobs.md). Question: the owner's first Godot playtest (R65) left him unsure which ship to move, what to do after firing, and when reinforcements arrive. The F1 turn-flow pass answers most of that inside a battle. Design how sector 1's first battles and the moments between them teach the rest, without a wall of text and without softening the game (R62).

## Files

- synthesis.md: the chair synthesis. The final 15-card prompt schedule with exact texts and triggers, fade rules, first battle setup, the campaign delivery mechanism, the off switch, a 10-step build list, and three owner calls.
- legs/rey_leg.md, legs/deepseek_leg.md, legs/qwen_leg.md, legs/argon_leg.md: the four review legs, verbatim. Qwen returned two complete responses; both are in its file, labelled. The Argon leg ran after the Nov 2 rate-limit reset and is filed with its chair header.

## Headline decisions

Battle cards keep their shipped ids and are re-timed so each is earned by an action or an event; the two cards the F1 bottom card makes redundant (start, turns) retire. One new card warns about reinforcements before the first arrival in battle 2. Campaign cards get a delivery path at last, through one small helper sharing the same options file and the same card UI, using the content lint's corrected lines. First battle is Hegemony on an open map with one terrain feature at the edge; no reinforcements in battle 1. A chair code check settled the one factual dispute between legs: a braced ship cannot move or fire again that turn (battle.js:635, 898, 1047), so DeepSeek was right and the shipped tip text understates brace.
