# Text truth pass, 2026-11-03 (issue #88)

Deliverables for issue #88: every player-facing rule text in data.js, ui3d.js TIPS, and the Godot teaching cards checked against the current code; the mismatches fixed in the browser and Godot together, with oracles re-copied and tables re-exported.

- synthesis.md: the chair report. Three mismatches fixed (Boarding Frenzy's phantom sabotage clause, the Brace sentence in the movement tip in both builds, the Nemesis clock card's first sentence in both builds), one confirmed mismatch deliberately not fixed in text (the Heat XP card states the R63 ruling ahead of the Job 7 step 10 code), and every other leg flag verified against the code with anchors.
- legs/deepseek.md: the DeepSeek writer leg, filed raw.
- legs/qwen.md: the Qwen writer leg, filed with its gate line.
- legs/argon_review.md: the Argon review leg (reviews only, R81), filed with a chair screening header.

The code and text changes themselves are in this branch at their own paths: data.js, ui3d.js, godot/scenes/battle/battle.gd, godot/ui/campaign/campaign_tips.gd, the oracle copies under godot/rules/test/oracle/ and godot/campaign/test/oracle/, and the re-exported godot/rules/data/tables.json and godot/campaign/data/campaign_tables.json. Text only; no numbers or rules changed.
