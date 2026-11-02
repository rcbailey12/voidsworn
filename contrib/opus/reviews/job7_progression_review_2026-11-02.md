# Opus review of Job 7, the progression plan (issue #4, Nov 2 2026)

Source: contrib/muse/design/progression_plan_2026_11/synthesis.md (84c21fa). Checked against main at 27b2919.

## Code anchors

| Claim | On main | Verdict |
| --- | --- | --- |
| sumFx at core.js:171 | core.js:171 `function sumFx(list)`: plain sum, no cap | Correct |
| derive at core.js:217 | core.js:217 calls sumFx over fleet, modules, perks, aspect | Correct |
| nemAdapt at campaign_run.js:293 | campaign_run.js:293 | Correct |
| nemNodeIs in campaign_run.js | campaign_run.js:289 | Correct |
| Dead admiral shop at campaign_meta.js:143 to 144 | Lines 143 to 144 are HTML closing tags. The shop is live: admiralOwned (campaign_meta.js:60), unlock buttons on admiral cards (line 70), ACT.buyAdmiral (line 149), added by R1 follow-up d039a7a (PROG-6, Nov 1) | Wrong: not dead, and the line numbers drifted |
| "Admirals are ruled style choices, not purchases" (R62 direction) | R62 (FINDINGS line 89) does not say this; it rules admiral leveling with a small skill tree. R1 PROG-6 built admiral ownership on purpose | Not supported by a ruling: goes to Ryan |

The Godot port has its own copies of these functions (godot/rules/rules.gd:295 sumFx, :393 derive; godot/campaign/campaign.gd:486 sumFx). Every step that changes a rule or campaign function must change the browser and the Godot port together, re-pin both oracles and pass rules and campaign parity. The plan does not say this; the issues do.

## Decisions

- Ryan already ruled the five owner questions (synthesis, "Owner rulings").
- Step 9 (remove the admiral shop) is held: it would delete a feature built on purpose on Nov 1, on the strength of a ruling that does not exist. Question for Ryan in chat.
- Step 12 (story writing) goes to Muse, not Codex.
- Order: all steps are posted as issues but blocked until the feel-pass fixes (#16, #17) merge, per Ryan's priority (progression after the feel pass). Unblock one or two at a time, since most steps touch campaign_meta.js and campaign_run.js and would collide if run in parallel.
