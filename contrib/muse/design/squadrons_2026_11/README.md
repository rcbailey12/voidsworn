# Squadron design spec (issue 70)

The design package Codex builds issue 67 from: per-faction strike craft, formation and movement behaviour, readability at the battle camera, and a frame budget for 20 ships plus wings. Written against the owner complaint in FINDINGS R80 (squadrons look static, some factions show the wrong craft, they need more detail and more views).

Verdict: GO WITH CONDITIONS.

The one condition: Owner Question 1, visible craft count tracking wing HP, needs the owner's ruling before the count piece builds, because it extends the R80 squadron damage ruling. The synthesis carries the chair pick (adopt thinning at 75, 50, and 25 percent HP down to a 2-craft floor) and the objection against it. Everything else in the spec is buildable now.

## Files

- synthesis.md: the full spec. Mesh matrix keyed by (carrier faction, wing role), 10 meshes for the five launching factions plus a fenced Eclipse pair; faction-varied craft counts (4 / 4 / 5 / 6 / 5); role-split sizes; stance-keyed in-hex patrol as the anti-static fix; mesh-flown launch, transit, attack run, dogfight, and scramble; the R80 damage baseline; frame caps with a torture-scene measurement gate; a five-task build order against issue 67; five owner questions with chair picks; dissents; Not checked.
- legs/rey_leg.md: the blind Rey leg, written from the pack only.
- legs/deepseek_leg.md: the DeepSeek leg (DeepThink and Search on).
- legs/qwen_leg.md: the Qwen leg (Qwen3.8-Max, both model gates passed).
- legs/argon_leg.md: the Argon leg (Argon High, both gates passed), filed with a chair header. Drafts only per the issue block; the synthesis rewrites anything it uses and records its screening notes.

Grounding: repo main 7677728. The pack that all four legs worked from stays with the chair's working files for this issue.
