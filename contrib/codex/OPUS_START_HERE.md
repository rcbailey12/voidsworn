# Opus: current integration packet

Reconciled against main `355a2ac7`, October 31, 2026. Start with `../muse/OPUS_HANDOFF.md`; its first section is the current work order. This packet proposes technical sequencing and does not create owner rulings.

Muse's price correction, A3 high-n confirmation, canonical corrections and red-team closure are complete. Canonical tool repairs are now on draft PR #1 at `contrib/muse/tools/`, with 24 adversarial checks in `tools/verification_repairs_test.js`. Retired tool/index overlays were removed. Do not restore the old driver copy or old entrypoint copies.

## Ready gameplay candidates

| Candidate | Files after stripping `contrib/codex/proposed/` | Acceptance |
|---|---|---|
| Shipwright companion repair | `campaign_run.js`; combined Godot `godot/campaign/campaign.gd` and corresponding campaign oracle | Capture the upgraded uid before re-sorting. Repair a different damaged companion when one exists. Browser six edge cases pass; TXT-2 alone flips. |
| Elite-map guarantee | `core.js`; same combined Godot campaign file and corresponding oracle | Add the rest-node fallback. All 84 previously failing maps repaired; all 4,416 previously valid maps and final RNG states unchanged. W3-1 alone flips. Field conversion already excludes elites. |

Together the candidates produce 10 PASS / 70 FAIL, changing exactly TXT-2 and W3-1. Evidence is in `reviews/opus_ready_2026_10_31/` and `reviews/godot_validation_2026_10_31/README.md`: 4,500 maps, 1,920 setups, six edge cases, Godot compilation, 30 campaign seeds, 64 Nemesis records and 4,506 focused vectors. The campaign log records 28 seeds in the launcher log plus separate successful comparisons for seeds 29 and 30; see the evidence README. This is scoped campaign proof, not a whole-port clearance.

Apply small diffs against the new target. Full copies are adoption aids, not files to overwrite later Opus changes wholesale. Keep oracle behavior changes explicit. Corrected text/Nemesis assemblies remain candidates requiring a scratch dry run and UI inspection.

## Next useful artifact: a playable phased battle

Use this proposed acceptance checklist with the ruled move/fire direction. Resolve the controls in a wireframe or scratch scene before changing the combat loop; the exact controls below are implementation recommendations.

| State or action | Required behavior to demonstrate |
|---|---|
| Select and inspect | Friendly selection and enemy inspection are explicit. Inspecting an enemy never moves a ship or spends a weapon. Clear active-ship and remaining-action indicators. |
| Rehearse movement | Hover or select a reachable hex to show ghost destination, arrival facing and relevant movement cost. Rehearsal does not mutate authoritative battle state or consume RNG. |
| Commit movement | An explicit commit establishes the actual hex/facing used for subsequent odds. Cancel clears only the preview before commit. State whether committed movement can be undone before fire, then test that contract. |
| Fire | Display ready bearing weapon count and odds from the actual firing hex. An explicit Fire action commits the salvo once. Double activation cannot duplicate damage or spend the action twice. |
| Brace, pass and cancel | Present legal alternatives and remaining movement truthfully. Escape clears previews and wing selection. A hint must not declare a ship finished while a legal action remains. |
| Round progression | Allies and enemies follow the same ruled activation structure. Skipped or destroyed actors cannot stall the round. Existing mid-volley defensive triggers remain covered. |
| Fleet-density check | Show the controls at the intended roughly 20 total ships. Inspect, rehearse, commit, fire and cancel remain legible without covering the approach lane. Keyboard help must match live controls. |

Record a short acceptance trace with initial state, each committed action, resulting state, RNG behavior and a screenshot/capture for Ryan. Include one mistaken enemy click, one canceled movement preview, one brace/pass choice and one full round. This would turn the closed UI audit into evidence of a playable result; another audit round would not.

## Remaining bounded fixes

After the two ready candidates: enforce module kind-fit at mutation time (MOD-3); implement loss learning and adaptation/weakness exclusion (FR-2/NEM-2, one-reveal cap still a chair recommendation); fix boon construction by the ruled policy, then integrate corrected text. See the canonical handoff for acceptance and R33 migration decision limits.

Keep the parity slot NOT RUN until the general battle corpus exists. Preserve the ledger: 72 failing assertions are not automatically 72 accepted bugs. Do not reopen Chorus feed, reapply faction pricing, delete damcon on a dominance premise, or schedule more Qwen legs, price grids or A3 confirmation.
