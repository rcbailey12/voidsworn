# Outside check: PR 705 (DeepSeek arm, issue 44, run 5 finale board brightens, R78 Q18)

Refs #256. Checked at the PR head, work/issue-44-deepseek 2c145dc3, against issue 44's Done when.

## Verdict: GO WITH CONDITIONS

Council: blind Rey, DeepSeek, Qwen and Flash all GO WITH CONDITIONS, converging on the same two conditions; Grok's seat stayed empty (grok.com bot wall). The delivery does what the Done when asks, with evidence and limits stated plainly: the board brightens sector by sector as the new sun catches, and screenshots of each stage are committed to the repo.

## What was verified

The dawn is one mechanism, verified in the branch's world.gd: finale_stage(n) moves a warm, hex-aligned additive light field's front across the board's actual x extent (the partial branch's 160-unit overshoot on each side, which left stages 4 to 6 indistinguishable, is fixed; the sweep starts from the Hollow Sun's side, flipping when the sun is on the right), and ramps everything else with the same parameter: the new sun light (0 to 2.2), ambient (0.5 to 1.2), the sky's sun brightness, and the Hollow Sun's disc, haze and lens materials and light (collected at build; the chair verified the collection sites). finale_for_round is finale_stage(round - 1) with the clamp inside finale_stage, so round 1 is dark, round 6 is full dawn, and later rounds hold. battle.gd advances it on round events only when the battle is a finale, and passes the flag through battle_api.gd's cfg passthrough. It is pictures only: no rules, view() or save field is touched, no JS twin file changes, and the body evidences standing checks 48 PASS / 0 FAIL (2 KNOWN baselines) and both parity suites passing, including the cross-twin save hand-off. The chair viewed the committed captures for stages 1, 3 and 6 (each exactly 1280x689, as the body states): stage 1 is a dim board with the Hollow Sun showing through its hole, stage 3 is half swept with a soft bright front, stage 6 is full warm dawn. The reach section (callers, saves, twins, UI, CI) is thorough, and the partial-branch start follows the Board's instruction in the issue.

## Conditions

1. **The interim finale trigger will over-fire as the campaign grows.** With no run-5 story in the repo, _api_battle_finale() treats any boss-kind battle at sector 3 or later as the finale. That is exactly the run's final battle in today's three-sector runs, and cfg.finale exists as the explicit seam, but the test is a floor, not an equality: the day runs grow more sectors, or a non-final boss appears at sector 3+, the dawn lights fights it does not belong in, silently. Condition: the Board accepts the heuristic as the interim trigger on the record, and its replacement by the story's own finale marker is tracked with the story work the issue is blocked behind (progression step 12), so the dependency does not close silently with this PR. (All four legs.)

2. **The committed stage captures show a stand-in board, not the battle board.** finale_shots.gd draws a dim hex grid in place of the battle's own board mesh because the world layer has no board mesh and the checkout has no built hulls; the disclosure is honest and the dawn itself is the real world code, driven the same way. But the Done when's "screenshots of each stage" will be read as the finale board, and the one real-scene run the body cites (world_shots --only deadstar --finale, which exercised the actual battle path and printed the finale build notes) produced no committed captures. Condition: when built hulls exist on a Board checkout, the world_shots --finale set is captured and committed over the stand-in set, so the record shows the dawn on the real board, with ships. (All four legs.)

## Notes

- Stage 1 reads dim rather than dark, for two compounding reasons: the harness lights its stage with its own key and fill lights, and the dawn field's gain at stage 0 is 0.85 (not 0) behind a soft 45-unit edge, so a faint warm front sits at the board's edge. Likely intended as first light; the real-scene captures in condition 2 settle the battle's own baseline.
- A finale that ends before round 6 never reaches full dawn; the API documentation states the round mapping and the hold plainly.
- godot/fx/API.md sits outside the issue's Deliver-to (godot/world and the finale battle setup); the change is accurate documentation of the new surface and the runner flagged it in the body. Harmless, noted for scope discipline.
- The body's "six equal sectors" is loose wording for six stages over five intervals of the front's travel; the progression itself is even.
- finale_stage carries a redundant second null guard on the dawn material (the first guard already returns). Cosmetic.
- The PR's base (19d6bd7f) differs from the base the sibling PRs in this queue used; the 13-file diff contains no unrelated changes (the main commit 6501c736 that appears in the branch's ancestry is the siblings' base, not an inclusion).

## Leg records

Two verification questions raised by DeepSeek and Qwen were pack-scope limits, resolved by the chair against the branch file and the committed PNGs: finale_for_round's body (finale_stage(round - 1), clamped) and _sky_sun_base's assignment (1.0 normally, 0.0 on the dead-star board, world.gd lines 481 and 485, as its comment claims). DeepSeek's screenshot-size note is resolved in the delivery's favour (the committed PNGs measure exactly 1280x689). Flash's BLOCKING claim, that a world.gd comment trails off at the end of the file, is a pack artifact: the pack's excerpt was sliced at that comment, and the branch file continues past it.

## Not checked

Stages 2, 4, 5 and the wide shot (the chair viewed 1, 3 and 6); the dawn on non-deadstar boards at runtime (the flip path is in the code; the committed captures are the dead-star case); the effect's frame cost (no figures in the body; the addition is one additive plane, one shadowless directional light and material ramps); the world_shots --finale run output beyond the body's quote.
