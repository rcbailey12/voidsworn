# Patch pack addendum: red-team adjudication (Oct 29, 2026)

Chair document amending contrib/muse/reviews/patch_pack_2026_10_29.md after the DeepSeek and Qwen red-team legs (filed under contrib/deepseek/reviews/ and contrib/qwen/reviews/). The Argon red-team leg is still outstanding; if it lands anything new, this addendum gets a dated extension rather than a rewrite.

## Verdict

The pack stands. Five diffs and one clean non-reproduction, confirmed across both legs. One recommended adjustment (section 1), one rationale correction (section 2), and two noted deltas for Opus. No other diff text changes.

## 1. Veteran brace bypass: boarding precedence delta confirmed, legality answered

DeepSeek flagged, and the chair confirms by reading both flows, that the inserted branch changes activation precedence on the mid-move path. In the shipped flow, when a unit has boarding targets the onLate callback returns without firing, volleyP stays null, and the post-move flow reaches the tacticBoard check before the veteran brace decision at battle.js:1396, so boarding is offered first and brace second. The patch's inserted branch sits before moveUnit and returns immediately on a brace call, so on that path the brace now pre-empts a boarding the shipped ordering would have offered first. Whether a braced unit could also board is not reachable in the shipped order, and the patch should not create the question.

Recommended adjustment for Opus: keep the decision where the shipped flow makes it, after the boarding deferral. Concretely, run the brace decision inside the onLate callback after the boardTargets early return (the volley path only), and on a brace call suppress the later tacticBoard check for that activation, mirroring the early return the volleyP path already performs. The invariant to preserve: boarding offered first, brace second, never both in one activation.

The legality half of the concern is answered by Qwen and accepted: giveOrder re-checks canOrder internally (battle.js:1040), so the pre-move evaluation cannot force an illegal brace, and the thresholds are copied verbatim from line 1396. The remaining pre-move versus post-move evaluation difference is the pack's own stated risk and stands as an accepted approximation; the thresholds are wide.

## 2. Hive wings: rationale correction, threshold deltas noted

Qwen's correction is confirmed against derive() in core.js: the derived hangar is t.hangar ? t.hangar+(fx.hangar||0)+(fx.hive||0) : (fx.hive||0). A hull whose only hangar comes from the fitted hangar module therefore derives hangar 0. It does not count toward nCar0 after the patch, and it does not launch wings either. The pack's behavior note ("a hull whose only hangar comes from the fitted hangar module now also counts, which is consistent (it does launch wings)") is wrong in both clauses and is struck. The diff itself does exactly what its defect statement says: hive-derived hangars now count.

DeepSeek's threshold deltas stand as noted behavior, not defects: counting hive hulls can push nCar across 2 (the adaptation arms at all) and across 3 (the refit count goes from half the candidates to all of them, battle.js adaptation block), and the doctrine +1 still requires nCar0 of at least 1. That is the fix working in its intended direction; Opus should just know the step sizes when playtesting carrier-heavy fleets.

## 3. Module kind-fit guard: claim stands, hardening is Opus's call

Both legs note that the "only enforcement point" claim is proven only for the code in the excerpts: ACT.equip (campaign_run.js:140) checks nothing itself, and no other equip surface appears in any code the legs or the chair have read, but an unexcerpted path that pushes to sh.mods directly would bypass the filter. Hardening ACT.equip to re-check modFitsKind is a cheap belt-and-braces step; the chair leaves it to Opus.

Qwen's open point on variant merging is closed by the chair: variants merge into HULLS at data.js:578, so HULLS[s.tpl].w is the fitted weapon list when the fleet screen renders, and modFitsKind reads the right list. DeepSeek's MOD_NEED completeness objection was answered in its screening (chair-verified against data.js:259; the helper's shields branch covers the capacitor and regen case its quote missed).

## 4. Elite guarantee: the undo objection is refuted

Qwen's DIFF RISKY rests on the shipyard guarantee (core.js, the line after the elite guarantee) re-converting the new elite. It cannot: COLS is 7 (core.js:253), the elite guarantee reads cols[COLS-3], which is cols[4], and the shipyard guarantee reads cols[3]. Different columns. Qwen flagged this dependency in its own Not checked (it assumed the two were the same column because COLS was not in the excerpts), and the chair credits the leg for naming its load-bearing assumption; on the actual value the objection does not survive. The pack's own rationale already states the columns differ, and its survival claim (budgets loop and field conversion leave elite nodes alone) was verified in the pack and again in the chair's read of genSector. Section 4 stands unamended.

## 5 and 6. No surviving objections

Section 5 (mobile layer): DIFF SOUND from both legs, no objections. Section 6 (Eclipse carrier preview): NON-REPRODUCTION CONFIRMED by both legs independently; the Oct 28 fights synthesis's last open item stays closed.

## What Opus receives

The patch pack as filed, plus: one recommended adjustment (section 1 insertion point, boarding precedence invariant above), one struck behavior note (section 2), and two judgment calls (ACT.equip hardening in section 3; the nCar step sizes in section 2 when playtesting). Everything else in the pack survived two independent red teams unchanged.
