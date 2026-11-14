# Outside check: PR 665 (issue 652), the Sonnet arm's UI clean-up

Refs #256. Brief: issue 256 comment 6865838018 (the Board, Nov 13, 2026). PR 665 merged, head 0c97b56684866ce658d38c0e31eea291b765636b, 16 files, +82 -1203. This is the first Sonnet-built PR (arm anthropic/claude-sonnet-5-5 via the issue 377 runner).

## Verdict: GO WITH CONDITIONS, no BLOCKING

Full council (R231): blind Rey, DeepSeek, Qwen, Flash, Grok, every gate verified (DeepSeek DeepThink on and Search off at both ends; Qwen3.8-Max in the selector before sending and in the header after; Gemini picker "Quick answers 3.5 Flash-Lite" before and after; Grok signed in with Continue with Google after the owner's phone approval). Four legs say GO WITH CONDITIONS, Grok says GO clean. Nobody found a defect in the merged code. The conditions are governance and completion items, set out below.

## Chair-verified facts (recomputed or read at the merged head)

- hud.gd is 1,386 lines (was about 2,600). 42 function definitions removed (the 34 unreachable Lime functions plus 8 shared helpers only they called). Zero removed names still defined in hud.gd, zero called anywhere in it; TOP_H, BAND_H and FLEET_W have zero remaining references. The signal connections removed in the diff were all internal to the dead builders' own controls.
- Kept members present: _rows, _card_info, _panel_info. contrib/opus/ui_battle_ember/godot/_ember271/ember_overlay.gd reads exactly hud._panel_info (line 61), hud._rows (64) and hud._card_info (65). Live helpers intact: _tipbox, _label, _button, _rich (default size now 17), set_legend, _draw_legend.
- The chair ran the repo's own scanner (godotSizes from ui_constants_diff.js, node) at the merged head: 284 text rows, zero under 17, before and after the ornament exemption, exactly the PR's claimed count. The 17 px floor opus_check_645 verified is intact after this deletion.
- The check edits, read in the diff, each with an inline issue 652 comment: the scan guard 300 to 250 (comment records the scan reads 284 now; slack 34); the hull-low check at least 4 lines at 0.35 to at least 3 (comment: the Lime roster row left, the battle fleet foot is ledger.gd's own hull line); ui_constants_diff.js drops three comparison pairs whose GD sides (TOP_H, the title_lbl call, FLEET_W) no longer exist, the HTML mock side still carrying the values; ledger_readability_test.gd drops its h.legacy skip because the legacy control itself was deleted.
- The ember look, read in show_tipcard: _tipbox near-black square with a hairline edge, the comment states "No frame marks"; title at 28 in Big Shoulders capitals; body _rich at 18 in the second text strength; "Got it" is the primary ember button.
- Placement, read in the diffs: campaign_tips.gd set_context(is_covered, clear) and place_card (two frames later, x at the right margin, y from s(90), up to 6 passes pushing below intersecting keep_clear controls, viewport clamp, visible only when not covered); campaign_ui.gd passes the slide-over state and the shipyard repair bar (_yard_bar, set in _shipyard) on every draw.
- The battle before and after pictures in docs/shots/issue-652-sonnet/ are byte-identical (chair cmp, MD5 3fb9303576f0e4543992ceb1d559865d). Ten shots in the folder.
- Run record: the arm's own suites pass (ledger 129, battle_log_cap 12, wing_cancel, story_beat3, onboarding, ui_spec 170 after the adjustments); onboarding_visual.gd CARD VISUAL FAIL is pre-existing on main and disclosed; the runner's run_all_checks passes everywhere with findings_tests and oracle_drift_guard KNOWN at main's baseline counts; parity.bat timed out at 1500 s in step 4 of 5 with every listed battle PASS to that point.

## Findings by centre

1. The deletion is clean. Unanimous across all five legs on the chair's evidence: nothing a player, a save, a test or another tool reads is gone. The kept and removed partition is exactly right: everything removed was reachable only from the retired builders, and the three members the one outside reader needs were kept. DeepSeek notes the PR body's "34 unreachable" and this check's "42 definitions" are the same head counted two ways (builders plus their shared helpers), not a discrepancy.
2. The card meets the brief. Hide-while-covered covers the Map key and the Dossier; push-below covers the shipyard repair bar (the AFTER shot shows the card under the "Fleet fully repaired" bar). The ember look matches the orders sheet treatment. The arm's choice to hide the card while a slide-over is open rather than place it beside the overlay was stated plainly in its body and every leg accepted it as the safer reading of "kept off".
3. The check edits are sound in substance and self-approved in process. Every leg verified the same facts: the floor is intact at 284 rows, the guard follows the count, the hull-low count follows the deleted roster row, the dropped pairs point at deleted constants, the legacy skip had nothing left to skip. Grok calls that forced upkeep needing nothing further. The other four legs draw the governance line in slightly different places (DeepSeek singles out the hull-low relaxation as the one change resting on the arm's own account; Qwen and Flash ask for a standing process expectation; blind Rey asks for ratification), and the chair adopts the common form as Condition 1 below.
4. The run record is honest and incomplete in one named place. The arm disclosed its unfinished run_all_checks (the runner completed it), the pre-existing onboarding_visual failure, and the processes it left running on the PC. Parity is the one open thread (Condition 2).

## Conditions

1. The Board should ratify the arm's three check edits as standing. Each is substantively correct and commented with its reason, and the chair has independently verified the numbers under the scan guard; but a build arm setting the guard on the same scan the previous check treated as the floor's guarantee should not rest on the arm's own say-so. Ratification also settles the standing expectation Qwen and Flash ask for: future arms flag check edits to the Board, even forced ones. (DeepSeek, Qwen, Flash, blind Rey; Grok dissenting, would ask nothing.)
2. Parity is incomplete, not failed: parity.bat stopped at its 1500 s limit in step 4 of 5 with every listed battle PASS. No JS twins or rules files changed in this PR, so the chair records this as a Board-side acceptance item (accept the record or run parity to completion), not a defect in the PR. (DeepSeek, Qwen, Flash, blind Rey.)

## Notes

- place_card's viewport clamp can still leave the card over a control if a keep_clear stack were taller than the viewport; the shipyard passes exactly one bar, so this is latent only. (All legs.)
- The three dropped ui_constants_diff pairs leave values on the HTML mock side with no GD counterpart to compare against; if the Lime top bar or roster ever returns in ember form, the pairs need re-adding by hand. (DeepSeek.)
- The leftover node and Godot processes on the PC are the runner's cleanup, disclosed by the arm; recorded here so the Board sees it once. (DeepSeek, Qwen, Flash.)
- Leg record: Flash's answer carries one typo of its own ("contrib/opos" for contrib/opus in its Finding 1.2), recorded because the chair quotes legs exactly. During the Flash run, the sign-in agent circulated a longer draft answer that was not what the model displayed; the browser runner caught it against the live page and this delivery uses only the verified text.

## Sonnet vs Opus judgement (the Board asked for this plainly)

The candour is Opus-grade: the unfinished run, the pre-existing failure, the leftover processes and the scope warning are all self-disclosed in the arm's own body, and the kept-members call (the three ember_overlay reads) was exactly right. Three visible differences. First, the arm approved its own check edits where an Opus build would more likely have flagged them for the Board first; the edits are right, the escalation instinct is the difference (Qwen's phrasing: sound code judgement, less process polish). Second, on the card it chose the conservative option, hide rather than reposition beside the slide-over, and stated the trade in its body rather than hiding it. Third, it left its own verification to the runner after the shell limit, where an Opus run usually finishes its own checks. Net, on this pack's evidence: the deliverable's quality is indistinguishable from an Opus build of the same scope; the differences are process caution and self-management, not engineering judgement. Cost and time for the record: 61.8 minutes, 115 steps, estimated $3.23.

## Not checked

The full ui_spec_tests suite was not re-run by the chair in the sandbox (the scanner was run with the repo's own code; the suite's other checks rest on the arm's and runner's reported passes). The ten delivered shots were counted and the battle pair compared byte for byte; the campaign shots were not re-rendered.
