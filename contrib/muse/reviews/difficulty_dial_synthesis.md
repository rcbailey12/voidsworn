# Difficulty dial synthesis: DeepSeek vs Qwen (chair: Rey)

Basis: the Oct 23 sim matrix (300 fuzz runs clean; sector 1 boss win rates 38% Grax to 98% Maren and Voice; sector 2 elite wall 57% overall; average battle 6.6 rounds; late-fight animation wait 95-120s, a pacing problem, not a difficulty input). Both legs drafted from the same brief: DeepSeek (DeepThink on, Search off; brief uploaded) at contrib/deepseek/reviews/difficulty_dial_deepseek_draft.md, and Qwen3.8-Max (Thinking on, Search off; brief pasted as text) at contrib/qwen/reviews/difficulty_dial_qwen38max_draft.md. Neither leg is verified against code; both are proposals for Opus to verify and for the mega sim to calibrate.

## Chair verdict: GO WITH CONDITIONS

The two drafts agree on the architecture and the numbers that matter. The merged design below is usable as the dial spec skeleton. Conditions: (1) the corrected calibration formulas in this synthesis replace DeepSeek's as-written formulas; (2) the notch-shift vs calibration double-count is resolved by the stacking rule below; (3) nothing is tuned until the mega sim measures the elasticities and Opus confirms whether an Enemy Threat Budget exists in code.

## Consensus (both legs)

- Five notches, middle notch as default, difficulty fully visible to the player (run setup, pause menu, admiral select, pre-battle intel). A hidden dial is a defect; admiral pick must stop being one.
- Standard target 70% for major fights, with an acceptance band around it.
- Per-admiral calibration offsets: Grax gets threat relief, Maren and Voice get threat pressure, shown on the admiral select screen.
- Sector 2 elite gets an explicit fight-specific relief, not a global nerf.
- Battle length stays near 6.6 rounds; difficulty must not be bought with longer fights or more late-fight congestion.
- Late-fight animation wait is out of scope for this dial.

## Merged spec

Notches (labels: DeepSeek's set recommended; Qwen's Recruit / Line Officer / Commander / Flag Officer / Voidsworn noted as the alternative, with "Voidsworn" as a notch name rejected as confusing against the game title):
- Notch 1 Cadet: enemy hull x0.80, damage x0.85, elite strength x0.75.
- Notch 2 Ensign: enemy hull x0.90, damage x0.92, elite strength x0.88.
- Notch 3 Veteran (default): x1.00 across the board.
- Notch 4 Brutal: enemy hull x1.12, damage x1.08, elite strength x1.12, +1 elite escort.
- Notch 5 Nightmare: enemy hull x1.25, damage x1.15, elite strength x1.25, +2 elite escorts.
Qwen's Threat Budget framing is adopted as the mechanism behind these numbers: one visible budget multiplier per notch, translated into hull, damage, elite pressure, and small ship-count offsets (kept within -2 to +2 against ~20-ship battles). Whether a Threat Budget abstraction already exists in code is an open question for Opus; if not, it is a weighted sum of encounter strength, not a new system to invent lightly.

Targets at Standard (notch 3):
- Sector 1 boss overall: 65-75%, target 70%.
- Sector 1 boss per admiral: 60-80% acceptance (DeepSeek's floor), 65-80% aim (Qwen's band). No admiral below 60% or above 80% ships.
- Sector 2 elite overall: 65-75%, target 70%; per-admiral floor 60%.

Calibration (Qwen's math, which checks out; DeepSeek's corrected below):
- C_admiral,A = clamp(1.5 x (0.70 - W_A,S1), -0.30, +0.30); M_admiral,A = 1 - C_admiral,A.
- Oct 23 values: Grax C = +0.30 (M 0.70, 30% relief, capped); Maren and Voice C = -0.30 (M 1.30, 30% pressure, capped). Both hit the caps, which is itself a finding: the 60-point spread cannot be closed by threat scaling alone within ±30%.
- Iterative controller (Qwen): C_new = clamp(C_old + 0.5 x (0.70 - W_measured), -0.30, +0.30), damping 0.5, converge within two iterations to |W - 0.70| <= 0.05.

Sector 2 elite relief (merged): Qwen 19.5% (M 0.805) and DeepSeek's corrected ~16% (M 0.84) bracket the same answer; DeepSeek's draft 0.88 sits just outside. Adopt relief 16-20% at Standard, calibrated by the mega sim, plus a per-admiral sector 2 correction capped at +0.15 for admirals below the 60% floor. Prefer damage reduction over hull reduction when battle length threatens the 6.6 ± 1.0 round constraint (DeepSeek).

Stacking rule (resolves the double-count): notch multipliers and calibration offsets are one mechanism, not two. M_total = clamp(M_dial x M_admiral x M_fight, 0.60, 1.60) (Qwen). C_admiral is derived at Standard and applies unchanged at other notches; the notch win-rate shifts Qwen tabulates (+30/+15/0/-15/-30 pp) are targets for what the notch multipliers should produce, not additional corrections stacked on top of C_admiral.

## Corrections to the legs (verified by arithmetic)

1. DeepSeek's three calibration formulas are misstated as written (missing the 0.10 factor, since k is gain per +10% strength). As written, R1 gives g = 5.4, R2 gives m = -2.6, R3 gives e = -0.6. Corrected forms: g = 1 + 0.10 x (0.22/k); m = 1 - 0.10 x (0.18/k); e = 1 - 0.10 x (0.08/k_e). DeepSeek's example values (g 1.44, m 0.64, e ~0.84-0.88) are correct under the corrected forms and are the values to carry forward. Do not quote the as-written formulas.
2. DeepSeek's R3 components do not multiply to its stated e: hull x0.90 times damage x0.95 is about 0.855, not 0.88. Treat 0.855-0.88 as the draft range, not a precise value.
3. Qwen's "maximum admiral spread 0.20 percentage points" is a unit error: it means 20 percentage points (0.20 as a fraction).
4. DeepSeek's Grax cap (g capped at 1.30, remainder covered by a kit buff such as Grax flagship +10% hull) and Maren/Voice kit trims (Maren one fewer upgrade choice, Voice signature cooldown +1 round) are fallback proposals for when the ±30% caps bind, which they do at Oct 23 values. The kit details are invented (no kit data was in the brief) and need a data.js check before they mean anything.

## Adopted from one leg only

From Qwen: sector 2 entry attrition guard (P_entry = player fleet power at sector 2 entry vs expected; refit relief R = clamp(0.85 - P_entry, 0, 0.15) as a visible pre-battle resource) - this is the best explanation candidate if the wall is attrition rather than elite strength, and the mega sim must measure P_entry before choosing between threat relief and refit relief. Smooth sector ramp (T_n = max(0.55, 0.70 - 0.04 x (n - 2)); no mandatory fight more than 0.05 below the previous target unless labeled optional/challenge). Identity caps (no ability/stat changed more than 5% solely for spread correction; resource offsets at most 15% of baseline fleet power; correction order: threat budget, sector modifier, pre-battle resource, ability tweak last). Projected difficulty tags (Easy >= 0.80, Standard 0.65-0.80, Hard 0.50-0.65, Brutal < 0.50) on admiral select, map nodes, pre-battle intel, and encounters, with tag accuracy (±0.10) as a measured criterion. Sim logging requirement (notch, M_dial, C_admiral, C_fight, M_total, modifiers, composition per run).

From DeepSeek: the 6.6 ± 1.0 round battle-length constraint as a hard guardrail, and the damage-before-hull preference for protecting it. The explicit statement that notch 3 is the calibration baseline (all recommendations are at default notch 3).

## Contested or open (not settled by either leg)

- Whether an Enemy Threat Budget, sector modifiers, or a "fleet power" definition already exist in code. Both legs assume or invent them; Opus must report what exists before the dial is implementable.
- Whether intentional admiral power variance should survive as labeled "challenge admirals" (Qwen raises it; DeepSeek assumes full flattening to the band). Ryan's call.
- Notch labels (DeepSeek's set recommended above).
- Final numbers for every notch, gain, and cap: all pending mega-sim calibration (k, k_e, per-admiral per-notch win rates, P_entry, battle length by notch).

## Mega-sim measurements requested (union of both legs)

- Per-admiral sector 1 boss win rate by notch; per-admiral sector 2 elite win rate by notch.
- Win-rate elasticities: k (win-rate points per +10% starting fleet strength, per admiral) and k_e (per 10% elite-strength change).
- Battle length in rounds (mean and p95) by notch; entity count by notch (pacing guardrail).
- P_entry (player fleet power at sector 2 entry, relative) and sector 1 loss ratio by admiral.
- Stability by notch: zero exceptions, zero invariant breaks (Oct 23 clean baseline).
- Identity preservation: ability usage rates and fleet composition distributions pre- vs post-tuning (divergence at most 10% by the chosen measure); no ability/stat moved more than 5% for spread correction.
- Tag accuracy: displayed projected win-rate band vs measured, within ±0.10.

## Not checked

- Code mapping of every proposed mechanism (Threat Budget, sector modifiers, fleet power, admiral kits, upgrade choices, signature cooldowns).
- Playtest: whether visible calibration changes player admiral choice, and whether projected tags match player experience.
- Any tuning: all numbers above are draft values pending the mega sim.

## Recommended next step

Opus reports, in one pass: (1) does an encounter/threat budget, sector modifier list, or fleet-power definition exist in code, and (2) what the Grax, Maren, and Voice kits actually contain (to ground or kill DeepSeek's kit trims). Then the mega sim measures k, k_e, and P_entry, and the dial is calibrated by the iterative controller. No numbers are locked before that.
