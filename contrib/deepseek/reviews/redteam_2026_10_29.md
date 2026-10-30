# DeepSeek red-team leg: chair open-check answers and ruled-fix spec (Oct 29, 2026)

Filed verbatim from the model report (chat "Redteam review", chat.deepseek.com, run Oct 29, 2026, 8:08-8:13 PM CDT, harness measured; DeepThink and Search verified ON by the toggle test). Em dashes in the original are normalized to hyphens in this copy; wording is otherwise unchanged. The chair screening note lives in the goal workspace (oct29_savings_redteam_deepseek_screening.md).

CHAIR ANSWERS MOSTLY HOLD

Answer verification

1. NOMIDFIRE - CONFIRMED. Pack census lists the guard, the built page, and two Godot oracle copies; it states "nothing assigns it." Chair's repo-scoped claim holds. External harnesses remain outside the pack, but the chair says so. Quote: "process.env.NOMIDFIRE".

2. h_board sabotage - REFUTED (material detail). The broader overpromise is real: partial boarding sabotage is rnd()<.5||(u.fx&&u.fx.boardPct), and fx carries only boardPct. But chair's "promise is kept only on the partial-outcome branch" is false: the bridge-holds branch fires const s1=systemDamage(t), s2=systemDamage(t) unconditionally. So non-capture sabotage is not partial-only. Chair reasoning here goes beyond and against the pack.

3. Weapon-kind modules - CONFIRMED for no guard; "silently does nothing" INFERRED. Pack shows exactly "one only field at data.js:165" and "no fit-check hits above." That supports no browser fit guard. The install-and-silently-do-nothing consequence is inferred from absence, not shown by an install path.

4. battery versus hbattery - CANNOT DECIDE FROM PACK. Table dominance is confirmed: hbattery has higher shots/dmg/crit at identical range/opt/acc/fall. But the mount-separation claim is not in the pack: only the penitent line is shown with w:[['battery','P'],['battery','S'],['lance','F']]; no cathedral/ascendant hbattery mount is quoted. "No hull offers a choice" is beyond the pack.

5. Hive wing sources - CONFIRMED mechanically; some scope INFERRED. Pack shows u.ab==='launch'||(u.fx&&u.fx.hive) in canStance, and core folds fx.hive||0 into hangar even absent base hangar. Pack also shows the carrier-response comment that a hive flagship counts as a second carrier. The "8 launch hulls" and "not capped" count are inferred, not enumerated in the pack.

6. Ceiling fill loop - CONFIRMED. Pack shows while(budget>=1 && list.length<Math.max(4,ceil) with budget subtraction inside. Hitting the ceiling exits with budget remaining by construction. Chair correctly limits itself to mechanism, not magnitude.

7. Godot oracle boot grant - CONFIRMED for presence; no-.gd execution INFERRED. Pack says unlockAll appears only in godot/campaign/test/oracle/campaign3d.js and no .gd. That supports the parity-oracle exposure. "Port's own code does not execute it" is inferred from absence of .gd hits.

Spec review

Fix 1 - rollBoonOffer spillover: CANNOT DECIDE FROM PACK for current behavior; change is coherent. Pack gives rollRarity(minR,s,p) and the start of rollBoonOffer(p,minR), plus campaign call sites, but not the offer-building body. The spec's "off-patron backfill only when pool short" and "backfill rolls without patron argument" are chair code-read claims outside this pack. The equal-rarity part matches the shown rollRarity signature taking p and the tier-3 floor; implementation should pass the same patron input to every roll. Acceptance (a) needs a seeded RNG and an explicit non-empty on-patron fixture, otherwise it is nondeterministic.

Fix 2 - nemAfterBattle loss reveal: CANNOT DECIDE FROM PACK for current behavior. Pack shows only the nemAfterBattle(result,flagDead,o) opening, not the win/loss branches, weakness creation, or adaptation clash check. The proposed loss reveal is coherent and single-sourced if it writes the same revealed set, but acceptance (e) depends on code absent from the pack. Wording issue: the "neutral" complete-file variant says "his file is complete," which is not neutral.

Findings

1. [FIX] (READ) Item 2's "only partial-outcome branch" is refuted by the bridge-holds branch's unconditional const s1=systemDamage(t), s2=systemDamage(t).
2. [NOTE] (READ/INFERRED) Item 4's mount separation is not supported by the pack; only the penitent battery mount is quoted. Table dominance is read; "no hull offers a choice" is inferred.
3. [NOTE] (INFERRED) Item 3's "can be installed ... and silently does nothing" follows from no fit-check hits, but the install path is not in the pack.
4. [NOTE] (INFERRED) Item 5's "not capped by the 8 launch hulls" is a count claim not enumerated in the pack; the canStance/fold mechanism is read.
5. [FIX] (READ) Spec Fix 1's current-behavior description depends on rollBoonOffer body absent from the pack; include the body or mark it as chair code-read evidence.
6. [NOTE] (INFERRED) Fix 1 acceptance (a) needs a seeded RNG and a concrete non-empty on-patron fixture to be reproducible.
7. [FIX] (READ) Spec Fix 2's current-behavior and acceptance (e) depend on nemAfterBattle branches, weakness creation, and clash-check code not in the pack.
8. [NOTE] (READ) Fix 2's "neutral" complete-file wording uses "his file"; change to "the file" or the Nemesis name.

Not checked

External harnesses outside the repo; full hull mount table beyond the penitent line; rollBoonOffer body; nemAfterBattle win/loss branches; weakness creation and adaptation clash check; Godot runtime behavior beyond presence searches; CP/repair sims.

Designer questions

1. For h_board: Does "failed boarding" mean all non-capture outcomes, including bridge-holds, or only the partial outcome? Stakes: whether the boon text/fx guarantee should cover bridge-holds and whether capture should ever sabotage.
2. For Fix 2: Should a loss-debrief weakness reveal count as "revealed" for the adaptation clash check, as the spec assumes? Stakes: intel-state consistency and whether the loss reveal can directly constrain later adaptation selection.
