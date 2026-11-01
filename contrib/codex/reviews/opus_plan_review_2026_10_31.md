# Review of Opus's next-phase recommendation

Reviewed Oct 31, 2026. Main commit: `dbd5f9798b06c78fe96bfd18f1fac2e726a445f5`. Recommendation introduced in `0a375ae00860c76c42dfee642c4480249929626d`. Advisory material checked in draft PR #1 at `adc221994b9852d7f803c67efc9505f481e1979c`.

**My recommendation: support the direction, with the three corrections below before the final recommendation and new-chat handoff.** This is a review of a draft that explicitly awaits helper results, not a rejection of unfinished work. Opus remains the lead technical reviewer and makes the final technical recommendation to Ryan.

The strongest parts are the full-run human playtest first, battle controls before the larger progression slice, use of external work as adopt/adapt/defer/discard material, and clear limits on bot win rates and headless evidence. Sampling the outside reviews is disclosed rather than presented as a full independent verification of every model's output. Deferring Saro to a skill-tree slice is a reasonable scope choice.

It is also correct to replace the old Codex oracle refresh patches with the helpers' current work. Since this draft was written, G1 landed at [a166af8e](https://github.com/rcbailey12/voidsworn/commit/a166af8e5c3f1a696ad4385c46913d71e52c7b61) and G3 at [6033f978](https://github.com/rcbailey12/voidsworn/commit/6033f97894b28d1cea7489288e6876853ab49a9a). Those commits record cloud parity passes. The campaign [record](https://github.com/rcbailey12/voidsworn/blob/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/godot/campaign/test/RECORD.md#L16) still labels the corresponding PC job pending. These are recorded results, not tests rerun by this review. The final draft should refresh its pending/completed rows from the last helper reports.

## Findings

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence |
|---|---|---|---|---|---|---|---|
| 1 | The boon decision promises compensation that the proposed patch does not provide for a partially filled offer. | OBSERVED | [recommendation:211](https://github.com/rcbailey12/voidsworn/blob/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/contrib/opus/next_phase_recommendation_2026_10_31.md#L211); [campaign_run.js:489](https://github.com/rcbailey12/voidsworn/blob/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/campaign_run.js#L489) | "a short offer pays 60 credits" | The 60-credit path runs only when the offer contains zero choices. One or two choices are displayed without that automatic payment. The reviewed PR patch changes selection, but does not change this payment branch. Ryan would be approving different behavior from the supplied candidate. | Say "an empty offer pays 60 credits; a one- or two-choice offer remains selectable", or explicitly propose and implement a different compensation rule. Restate the 45/55 special-slot tuning from line 86 alongside the 3:1 policy when asking for a decision. | high |
| 2 | The fresh-save recommendation assumes the contents and value of Ryan's browser profile without checking them. | INFERRED | [recommendation:208](https://github.com/rcbailey12/voidsworn/blob/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/contrib/opus/next_phase_recommendation_2026_10_31.md#L208); [core.js:50](https://github.com/rcbailey12/voidsworn/blob/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/core.js#L50); [main3d.js:11](https://github.com/rcbailey12/voidsworn/blob/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/main3d.js#L11) | "nothing else of value lives there." | The boot grant sets legacy and admiral unlocks. The saved profile separately supports earned renown, mastery, favour, hull variants, Heat records, run stats and fallen captains. The grant does not establish that those fields are empty or unimportant. Ryan's actual profile was not inspected here. | Keep "start fresh" as Opus's recommendation if he prefers, but state the possible progress cost and that the profile contents are unverified. Let Ryan decide whether any earned records should carry over. Keep that separate from removing the testing grant. | high |
| 3 | The draft's route to the final commit and the next chat still leads to an old handoff. | OBSERVED | [recommendation:9](https://github.com/rcbailey12/voidsworn/blob/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/contrib/opus/next_phase_recommendation_2026_10_31.md#L9); [HANDOFF.md:3](https://github.com/rcbailey12/voidsworn/blob/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/HANDOFF.md#L3), [15](https://github.com/rcbailey12/voidsworn/blob/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/HANDOFF.md#L15), [184](https://github.com/rcbailey12/voidsworn/blob/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/HANDOFF.md#L184) | "see HANDOFF.md section 0 for the final commit." | At the reviewed main commit, section 0 is still the Oct 27 offline snapshot at 144dc71. Its starter prompt resumes the older migration work. A new Claude chat could repeat completed jobs and miss the reviewed next-phase decisions. This is an expected closeout task while the recommendation remains draft. | After the existing helpers finish, pin the actual closeout commit, refresh the handoff with their final outcomes and remaining PC checks, link the final recommendation, and provide a starter prompt for the new planning chat Ryan requested. | high |

Save-policy context: the earlier [go-forward plan:277](https://github.com/rcbailey12/voidsworn/blob/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/contrib/opus/go-forward-plan.md#L277) already contains a fresh-Godot-save default under "Claude's technical calls, vetoable". That is useful technical history, not evidence that Ryan's actual browser profile has nothing worth keeping.

## One recommended next step

Have Opus finish and reconcile the current helper reports, correct the two decision descriptions, and publish one final recommendation plus a current handoff for the fresh Claude planning chat. Keep the proposed human playtest as the first practical evidence in the next phase. Do not reopen the large audit program or require adoption of every Codex patch.

## Read proof and limits

Files came from pinned raw URLs, not folded GitHub pages:

- Main: `https://raw.githubusercontent.com/rcbailey12/voidsworn/dbd5f9798b06c78fe96bfd18f1fac2e726a445f5/<path>`
- PR candidate: `https://raw.githubusercontent.com/rcbailey12/voidsworn/adc221994b9852d7f803c67efc9505f481e1979c/<path>`

Line counts remove only the terminal newline, not blank content lines. "Last 40" is the exact first 40 characters of the final content line. Partial reads are listed as partial; search hits elsewhere do not count as reading the intervening text. Cited finding lines were fetched again and checked word for word.

| File | Total lines | Read ranges | Last 40 |
|---|---:|---|---|
| ` contrib/opus/next_phase_recommendation_2026_10_31.md ` | 227 | 1-227, full | `    - should Veteran AI be locked for new ` |
| ` HANDOFF.md ` | 185 | 1-64, 168-185, partial | ```` ``` ```` |
| ` core.js ` | 349 | 48-66, 107-123, 175-191, 348-349, partial | ` function findNode(id){ for(const c of RU ` |
| ` main3d.js ` | 20 | 11, 19-20, partial | ` window.addEventListener('pagehide',()=>{ ` |
| ` campaign_meta.js ` | 216 | 130-168, 215-216, partial | ` ACT.nextFac=f=>{ pickedFaction=f; META.o ` |
| ` campaign_run.js ` | 544 | 488-500, 543-544, partial; file is over 60 KB | ` } ` |
| ` contrib/opus/go-forward-plan.md ` | 560 | 263-283, 559-560, partial | ```` ``` ```` |
| ` godot/campaign/test/RECORD.md ` | 118 | Relevant result rows 8, 16-31; 117-118, partial | `` The screens live in `godot/ui/campaign/` `` |
| ` godot/rules/test/README.md ` | 94 | 44, 56, 60, 64, 93-94, partial | ``   - `tr` is taken by `Object.tr`. `` |
| PR ` contrib/codex/pre_opus/patches/integration.patch ` | 529 | 1-156, 454-489, 529, partial; file is over 60 KB | `    lancer:{n:'Aspect of the Spear',d:'Yo ` |

Supporting records inspected in part: `contrib/opus/compute/port_notes.md` (396 lines, 374-396; last 40: `- Checks: check pack 0 FAIL; b1 39, b3 1`); `campaign3d.js` (136 lines, selected telemetry/battle-start matches, final content line empty). Earlier evidence files were retrieved for context, not treated as a fresh audit: `contrib/opus/evidence/syntheses_part2_and_drafts.md` (109 lines, read 1-109; last 40: `- Runtime loading of the hulls, and whet`) and `contrib/opus/evidence/compute_and_review_citations.md` (86 lines, search matches and final line only; last 40: `- The built voidsworn-3d.html was not co`).

Review instructions read in full: `AGENTS.md` (45 lines, last 40: `` `CLAUDE.md` holds the same rules for Cla ``); `docs/REVIEW_PROTOCOL.md` (35 lines, last 40: `- Claude checks every claim against the `); `docs/ship_pipeline/TEXTURE_PASS.md` (43 lines, last 40: `pick. Free tools and CC0 assets only.`); `docs/ship_pipeline/AUDIT_BRIEF.md` (105 lines, last 40: `- The heavy steps only run on the owner'`).

## Not checked

No Windows execution, PC job completion, Blender execution, rendered playthrough, live player save or cloud account inspection. No new parity or balance runs. No fresh audit of every outside-model report, the skill catalogue, the full Godot implementation, or every gameplay fix Opus listed. `PROGRESS.md` was retrieved but not used as reviewed evidence. The source excerpts above support a plan review, not a claim that the game is ready for cutover.
