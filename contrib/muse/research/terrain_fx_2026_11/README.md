# Terrain effects research (board issue 81)

Chair pack for board issue 81: how the on-board terrain effects (nebula, ion storm, debris, and the dead star well) stop reading as flat smoke and start reading as their gameplay effects at the tactical camera.

Verdict: GO. The fix is shader and colour work on the existing living-terrain system (godot/world/world_living.gd), not new geometry and not a renderer change. The chair synthesis settles the look spec for all four kinds, sequences it as a 10 task build order for Codex with file:line and 4K screenshot judgements, and puts five questions to the owner with chair picks.

## Files

- synthesis.md: the chair synthesis. Start here. Sections: verdict, diagnosis, settled look spec, what the shipped games actually tell us (with sourcing caveats), scope boundary and coordination, screenings, dissents, build order, effort, owner questions, not checked.
- legs/rey_leg.md: the blind Rey leg, filed as written.
- legs/deepseek_leg.md: the DeepSeek leg, filed raw.
- legs/qwen_leg.md: the Qwen leg (Qwen3.8-Max, gates passed), filed as returned, gate line at top.
- legs/argon_leg.md: the Argon leg, SCREENED OUT in full, filed as a record only with the chair screening header on top. Nothing in the synthesis rests on it.

## How to use this pack

Codex builds from the synthesis, section 7, in order: the tasks are sequenced biggest read win first, each names its files and lines, and each is judged on fresh 4K captures at the default camera in the cine look. The owner questions in section 9 of the synthesis carry chair picks; "agree with chair picks" rules all five at once, and none of them blocks task 1.

## Boundary

This pack is terrain only: effects that sit on the board inside the play area. The sky and its baked nebula, the backdrop planet and moons, the backdrop station, and the backdrop rock scale cap are settled Job 10 scope under R79 and are not reopened here.
