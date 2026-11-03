# Balance re-check, 2026-11-03 (issue #87)

Chair report for the balance re-check after the Nov 2 landings (effect caps #38, Glasswright tree #63, shadow XP #83, teaching gate), against the balance v2 measurement in contrib/muse/research/balance_2026_11/.

- synthesis.md: the chair report. Verdict GO, no action needed: spread 14 points (was 12), under the issue's over-15 trigger, so no data.js changes are proposed. Five of six factions reproduce v2 exactly; one Hullbreakers run flipped.
- sim_results.md: the shipped runner's full raw output for this re-check (node contrib/opus/tools/run_montecarlo.js --runs 50 --seed 1 on main 23da027), filed in full so the next re-check can isolate per-admiral and per-seed movement.
- legs/deepseek.md: DeepSeek reader leg, filed raw. Its section 3 attribution is screened out in the synthesis (wrong change list); the rest is used.
- legs/qwen.md: Qwen reader leg (Qwen3.8-Max, both gates passed), filed with its gate line. Used in full.
- legs/argon_review.md: Argon ideas leg (Argon High), filed with a chair screening header. Ideas and watch items only, per R81.
