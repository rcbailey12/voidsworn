# Pack for the external legs, Issue #86 (merged PRs of Nov 2, 2026)

For the main chat to launch. This background worker has no live browser, so
no leg was launched from here. Each prompt below carries its gates in full;
restate them verbatim in any resume or continuation.

## Shared pack (all legs)

Repo: github.com/rcbailey12/voidsworn, main at 80307a2. The 15 code PRs
merged on Nov 2, 2026, with the merge commit for each (diff is
`git diff <merge>^1 <merge>`):

- #10 wording (12e5c07): battle.js text, godot/rules/rules.gd, both tables.
- #14 price tests (63da852): contrib/opus/tools/b3_tests.js, r1_tests.js.
- #32 playtest batch 1 (f237d20): godot world, fx and render, 23 files,
  904 insertions, 1569 deletions. Resumed from a partial patch.
- #35 playtest batch 2 (f0dfe37): fx_ship, fx_weapons, board, ship_view,
  battle scene.
- #36 onboarding tests (c9ea1ac): contrib/opus/tools/b1_tests.js.
- #38 effect caps (c19fed2): core.js sumFx and FX_CAPS, both Godot ports,
  new fixture suites.
- #39 b4 flake fix (5f1822a): contrib/opus/tools/b4_tests.js.
- #46 Nemesis clash tests (bc0b7a6): two new test files only.
- #47 export smoke guard (6fb7617): godot/render/ship_view.gd _exit_tree.
- #63 lineage slice (01207cd): campaign_meta.js, core.js, data.js
  LINEAGE_TREES, godot campaign port, campaign_ui. Codex was cut off
  before its own validation on this one.
- #64 free exit tests (8f6a640): two new test files only.
- #68 playtest batch 3 (4163902): fx, render, battle scene, campaign map.
- #69 fx guards (7677728): battle.js typeof guards, oracle copies.
- #83 shadow XP (caf8d9e): campaign_meta.js, core.js defaultMeta, godot
  campaign port, campaign_ui, importer fixtures. Codex validation was
  partial on the batch 1 sibling, not this one; still give it a full read.
- #85 deaths (708cb2d): godot/fx/fx_death.gd, ship_view.gd, new
  death_plane_check.gd.

Chair results the legs should try to break (from synthesis.md in this
folder): all 15 verdicts, the two fixes on branch muse/issue-86 (saneMeta
heirs and shadowPool; godot/fx/API.md stale passages), and the inferred
item on godot/world/blocker_visuals.gd:105 look_at_from_position.
Chair evidence: run_all_checks exits 0 on main; the five new suites pass;
oracle copies byte-identical. Ryan's rulings in contrib/opus/FINDINGS.md
override every other doc (R80 damage staging and R81 Muse scope matter
here).

Output rules for every leg: verdict per PR, clean or findings; cite
file:line for code claims; every finding needs a concrete failure case;
mark each claim OBSERVED or INFERRED; cap 10 findings; end with a
Not checked section. Plain words, no em dashes.

## DeepSeek prompt (code review)

Gates: DeepSeek web chat, DeepThink ON and Search ON, named in this
launch. If the site does not show DeepThink and Search available, stop
and report; do not substitute another mode or model. No self-writing: a
report DeepSeek did not produce is not a leg.

Prompt: paste the shared pack, then: "Review the code of these 15 merged
pull requests like a hostile second reviewer. Read the diffs. Hunt for
real bugs: wrong guards, state that does not persist, browser and Godot
ports that disagree, tests that assert less than their names claim.
Attack the chair's verdicts and fixes where they are wrong. Follow the
output rules in the pack."

## Qwen prompt (code review)

Gates: Qwen web chat on Qwen3.8-Max. Two gates, both required: (1) the
model selector shows Qwen3.8-Max before the prompt is submitted, (2) the
chat header still shows Qwen3.8-Max after generation. If either check
fails, stop and report; never fall back to another model. A header
showing Qwen3.8-Max with nothing contradicting it is the strongest check
the UI allows (per the Oct 25, 2026 lesson in AGENTS.md). No
self-writing.

Prompt: paste the shared pack, then: "Review the code of these 15 merged
pull requests, with your weight on the two progression ports, PR #63
(lineage) and PR #83 (shadow XP): compare the browser and Godot
implementations function by function for divergence, and check the save
and migration paths for ways a field can arrive with the wrong type.
Also re-check the chair's saneMeta fix: is it complete across ports, and
does any other defaultMeta container miss the same treatment? Follow
the output rules in the pack."

## Argon prompt (ideas and risks only, R81)

Gates: Gemini Argon High (the Gemini 4 Argon model at the High thinking
level on Ryan's Google AI Pro account). Check the model and thinking
level before submitting and again after generation; if Argon High is not
what is shown, stop and report. Argon is for briefs and sources only:
ideas and risks, never final text or code; cut anything it cannot back
up with a source or a file:line from the pack.

Prompt: paste the shared pack, then: "List ideas and risks only. Where
could this batch of merges hurt the game or the project next: fragile
spots a future change will trip on, checks that give false confidence,
docs that will drift again, pacing or feel risks in the presentation
changes (torpedo flight clamp in PR #35, death timing in PR #85). Cite
a file:line or a named source for every item; drop anything you cannot
back up. No code, no verdicts."
