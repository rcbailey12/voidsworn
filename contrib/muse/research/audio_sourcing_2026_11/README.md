# Audio sourcing 2026-11 (board issue 82)

## What this pack is

The chair synthesis for board issue 82: real recorded or professionally designed sound effects and music for every cue in godot/audio/cues.json and every music slot in godot/music/music.json, from free licences only (CC0, CC BY, royalty-free packs). It follows Job 5 (contrib/muse/research/audio_2026_11/), which deferred per-cue source selection and the full music review to this pass.

Headline finding: the issue premise is corrected in the synthesis. Only 15 of 67 cues are synth-only today; 52 already carry recorded layers, and 24 of those are hybrids that also play a synth layer. The plan is a zero-download synth strip first, a pack-led CC0 core second, and an 8-slot music audition list, with 16 music slots kept as they are.

## Verdict

GO WITH CONDITIONS.

1. Downloads need the owner's OK. This pack lists and sizes only; intake is a separate owner-gated step.
2. Nobody has listened to any candidate file in any leg. Every pick is metadata-level, and an audition and listen pass is a required intake step.
3. Kenney pack sizes are unverified in every leg, so totals are stated as a verified core plus named unverified items; intake records the real sizes and restates the total.

## Files

- synthesis.md: the chair synthesis. Premise correction, the zero-download fix, the SFX sourcing core, the per-cue disposition table for all 67 cues, the music keep and audition lists, the Sonniss settlement, honest totals, the intake build order, leg screenings, dissents, five owner questions with chair picks, and a Not checked section.
- legs/rey_leg.md: the blind Rey leg (primary source for verified sizes).
- legs/deepseek_leg.md: the DeepSeek leg, filed raw (used in part; its per-cue table is screened out in the synthesis, its pack list, totals framing and named files are used).
- legs/qwen_leg.md: the Qwen leg, with its model gate line at the top (used with the caveats stated in the synthesis).
- legs/argon_leg.md: the Argon leg, with the chair screening header on the filed copy (structural findings adopted; sizes and Kenney file names limited as the header states).

## How to use it

Work from the intake build order in section 8 of the synthesis:

1. Zero-download fix first: strip the synth layer from the 24 hybrid cues and wire the existing enemyTurn set into ui_enemy, as cues.json data edits, then run the audio checks.
2. Download the CC0 core packs after the owner's OK (synthesis Q3), record the real sizes, and restate the total in the intake commit.
3. Select per-cue clips, register sets in godot/audio/clips/index.json, point cues.json layers at them, and remove synth takes on replaced cues. Resolve the Freesound CC0 searches in this step.
4. Little Robot intake only if Q1 passes, with its attribution line filed into a new SFX credits text.
5. Run the 8-slot music audition through tools/music/process.py; incumbents stay until a candidate wins.
6. Close with a listen pass over the replaced cues as the sign-off. The owner judges by ear.

## Downloads

No downloads yet. Nothing in this pack was downloaded to produce it, and nothing should be downloaded from it until the owner rules on the five questions in section 11 of the synthesis (Q3 is the download gate for the CC0 core).
