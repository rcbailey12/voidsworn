# Outside check: PR 797 (Eclipse flare rules, R265) and PR 804 (E14 round 2, R269)

Refs #256

## Verdict: GO WITH CONDITIONS

Two conditions, both record-keeping under R214, neither a fault in the rules change or the build: the R256 exception needs writing into factions.md beside the Eclipse Never line, and the stale E14 build note in the Muse design file needs correcting. Everything substantive is verified: the chair read both merged diffs figure for figure, confirmed all four CI check runs green on both merged heads, and confirmed issues 811 and 812 open carrying the two referred items. PR 797 implements R256 and R266 exactly as ruled, R265 settles the disclosed massed-flare band breach, the rules.gd change is the narrow memo-key fix the body describes, and PR 804 builds the E14 Ryan passed in R269.

Council: blind Rey GO WITH CONDITIONS. DeepSeek (DeepThink on, Search off, verified both ends) GO WITH CONDITIONS. Qwen (Qwen3.8-Max, verified both ends) GO WITH CONDITIONS. Grok (Fast, verified both ends) GO WITH CONDITIONS. Flash (Flash-Lite, verified both ends) GO. ChatGPT (chat, GPT-6 at High, verified both ends) GO WITH CONDITIONS.

## The brief

opus_check_804_797: PR 797 (merged 2026-11-15T20:21:08Z, head f2b43a8a), the Eclipse flare rules change for issue 784, and PR 804 (merged 2026-11-15T20:48:03Z, head 760ba1d7), the E14 flare redesign round 2 for issue 782. Board brief at issue 256 comment 6902790668, which frames 804 under R269 and 797 under R265; both PR titles cite R256, and the FINDINGS rows reconcile the chain: R256 set the glass cannon direction, R265 ratified the numbers, R266 ordered the round 1 changes, R269 is Ryan's pass on round 2.

## (a) PR 797: the rules change

**Verified against the merged diff, figure for figure.** data.js gains nlance (Null lance, kind gauss, 3 shots of 15, range 6, opt 4, acc 74, fall 8, pierce 0.6, crit 5) against the old gauss (3 shots of 6, range 5, opt 3). FAC_WTRAIT deathless gains nlance:'gauss', so the half-armour pierce follows the weapon id, as the body explains. d_jackal goes from two gauss (turret and fixed) at hp 110 to [['nlance','F']] at hp 100, armour .25 unchanged: damage ahead 36 to 45, side and rear 18 to 0, range 5 to 6. The Archive guard variant follows R266's "Make it a lance too": d_jackal_h becomes [['nlance','F'],['gsentry','T']] at hp 85 with rewritten text, and unlocks.md carries the same text. weapon_match.py gains the nlance FITS row ({'nullcannon'}, {'fixed'}), so the new shape is guarded by the same self-test regime as the old. Every leg passed this item without reservation.

## (b) The band breach and R265

**Disclosed, escalated, and ruled; nothing further is owed on the numbers.** The body states plainly that the brief's "inside the baseline band" is NOT met for massed flares: others beating Eclipse moves 77.6 to 68.3 (about two standard errors), the Eclipse skirmish row rises 84 to 92, and no damage value in the swept table fits both bands. R265 records Ryan's answer with the breach in front of him: "Keep 15 damage, ship it", accepting 15 damage at hull 100. The council is unanimous that R265 is an acceptance of a disclosed trade-off, not evidence the band was met, and that no further balance approval is required. ChatGPT adds the correct scope note: "no setting keeps both inside the band" is supported among the tested configurations, not as an exhaustive claim about all possible configurations. Nothing rests on the wider reading.

## (c) The rules.gd memo-key change

**A narrow port fix, honestly bounded, not a hidden rules change.** Both memo keys (hitChance and expectedVs) gain the shooter's facing only while silentArchive is in force; when the skill is absent the facing term is 0 and the keys are unchanged, and the key arithmetic multiplies through by 8 with the facing bounds-checked. The comments in the diff name the leak: under Silent Archive the same hex scored at two facings (the JS log showed hit chances of 44% and 29%), so cached aim leaked across facings. The body discloses the fix and its own limit: parity failed on t_ecl_silentarchive before and passes after, but the final numbers also changed that battle, so the passing run does not prove the fix alone cured it. Every leg accepted that caveat as the right one. ChatGPT notes a standalone before/after reproduction with only the memo-key change applied is not in the pack; the 44% against 29% log excerpt is direct evidence of the defect itself, and the chair accepts the body's bounded claim as stated. The scenarios.json changes are seed-only across the 8 named Eclipse fixtures, a consequence of the weapon change, attested in the body and consistent with the diff.

## (d) PR 804: the E14 rebuild

**Builds what R256 and R266 ordered and Ryan passed in R269.** Ring upright around one big fixed centre gun, no turret. weapon_match.json at the merged head: PASS, slot 0 nlance F, 3 shots, L1 fixed nullcannon, no problems. checks.json: PASS true, model length 9.538 against game length 9.5 (0.4 percent), outline IoU 65.1 percent. The R266 round 1 notes are answered one by one: two-step body 1.0 and 1.12 across with stern block 1.44 (was 0.72 and 1.1), body-width-to-ring 0.19; bow halo ring 2.2 across; twelve chunky ring plates at 5 degree gaps with rim bands, relief and corona lines, the same on every plate (R243); twelve inner lights plus core windows; bore 0.94 deep (was 0.5) in three stages with a lit throat. R269 is Ryan's "Yep, that's perfect" on the round 2 pictures, which is the controlling evidence of visual acceptance. The fit, contract, audit, inventory and R240 figures are PR body claims rather than raw artifacts in the pack; DeepSeek flagged exactly that distinction, and the chair records it here. The claims the pack does carry as artifacts (weapon_match, checks) check out in full. PR 804's diff repeats PR 797's data and Godot changes and says so; there are no hidden data changes. The triangle count rose from the first sheet's 34,128 to 47,376 (+39 percent) on the chunkier body and ring relief R266 ordered, disclosed in the body with its reasons.

## (e) Sequencing and the referred items

**Sequencing landed as prescribed.** PR 797 merged at 20:21:08Z and PR 804 at 20:48:03Z, 27 minutes apart, and PR 804's branch already contained PR 797's head, so its diff carries the rules change with the model. DeepSeek and ChatGPT both raised the 27-minute window as a condition: between the merges, main's data named a lance the old sheet could not slot. The chair answers it rather than carrying it: the window closed the same afternoon, the E14 model is installed in the game at sheet build time rather than read from main at runtime, so main never held a playable build pairing the new data with the old model, and the residual install is the Board's pipeline step, as with every sheet. Qwen made the same point in its sequencing answer. The window is on the record here; no verification action is owed.

**Two referrals are properly parked.** The lift (R266's "Lift the ship", impossible in the model because the game re-centres every hull) is issue 811, open, owner Codex, delivering to godot/ hull_table.gd and ship_view.gd with a battle-cam capture. The guard spire (no per-variant parts in the pipeline; the spire fires from the plating as a disclosed fallback) is issue 812, open, owner Codex. R269 records both. ChatGPT's condition that both issues stay open until implemented restates that tracked state and is not carried as a separate condition.

**Two items are disclosed but untracked; they are conditions 1 and 2.** PR 804 names both in its own design calls (4 and 6), but neither PR amends the file and no open issue carries either. Disclosure in a merged PR body is not the same as parking, as DeepSeek put it.

## Conditions

1. **Record the R256 exception in factions.md.** The Eclipse Never list (line 180 on main) still bans "a spire through the centre of a disc" with no exception, while the accepted E14 build runs its lance through the ring's centre under R256. R214's pattern is that a ruling lands with its document in the same pass. Amend the Never line to carry the E14 exception, or open a tracked issue that does. (Blind Rey, DeepSeek, Qwen, Grok, ChatGPT.)
2. **Correct the stale E14 build note in the Muse design file.** designs.md's E14 entry still describes the flat ring and a rail turret, both superseded by R256 and the accepted rebuild, so a reader of the design file would take the withdrawn design as current. Correct it or mark it superseded, and track the correction. (Blind Rey, DeepSeek, Qwen, Grok, ChatGPT.)

## Notes

- **PR 797's CI citation is stale; the claim holds.** The body cites CI passing on 1234bf2, an earlier commit than the merged head. The chair verified all four check runs (Standing checks, Godot rules parity, Godot game checks, open-pr) successful on the actual merged heads of both PRs via the check-runs API. Noted by Qwen, DeepSeek and ChatGPT; no action owed.
- **The triangle growth is on the record.** 47,376 against the first sheet's 34,128 (+39 percent) and the first redesign's 36,424 (+30 percent), disclosed in the body with the R266 reasons. ChatGPT notes no battle-camera performance result is in the pack; there is no standing triangle ceiling for it to breach, the binding limit being the measured frame-time gate, and nothing in either body claims a performance target.
- **The pierce wording.** ChatGPT cautions that pierce 0.6 is not self-evidently "half-armour". The value is unchanged from the old gauss entry and the trait mapping is added, so there is no regression; the phrase is the ruling's and the PR's language. Noted, nothing rests on it.
- **Flash's clean GO.** Flash returns the round's only GO. Its Q4 answer calls nothing dropped while its own next lines concede the two documentation items are design calls in the PR body with the files unedited; the chair follows the other five legs, whose conditions match the pack's own Section E facts.

## Leg notes and slips

- ChatGPT's pack reached it as 7 consecutive messages in one GPT-6 High chat: a single paste failed at the tool level and composer appends inserted chunks mid-text, so the worker sent single fills in order, each marked continued, and the model held its verdict until the final PACK END message. One preliminary response to the first section alone was stopped. The pack reached the model in full, in order, as text, and the gate was verified before and after. The deviation is recorded here; the leg stands.
- A "130 parts" figure for the contract self-test appears in the Flash and Qwen legs. It traces to the pack rendering, not to the PR; the sheet's own numbers are 315 objects and 43 parts. Nothing rests on it.
- Grok read the fit, contract, audit, inventory and R240 claims as supported by the pack where DeepSeek correctly scoped them as PR body claims. The distinction is recorded in section (d); nothing in the verdict turns on it.

## Not checked

- The sheet pictures at picture level. R269 is Ryan's pass on the round 2 pictures, and the pack carries measurements and check artifacts rather than the images.
- tree_effects_test.js was not re-run by the chair; the seed-only attestation and the green Standing checks run on the merged head are what this check stands on.
- The residual install of the rebuilt E14 in the game, which is the Board's pipeline step.
