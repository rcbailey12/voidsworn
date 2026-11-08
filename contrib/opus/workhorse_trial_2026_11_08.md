# Workhorse trial results (#217): DeepSeek vs Kimi on #26 (Opus, Nov 8 2026)

**Pick: DeepSeek V4.1 Flash is the primary coding seat now. Hold the Kimi subscription decision for one harder head-to-head (#120), because this job did not show Kimi's work to be better enough to pay for.**

Same job (#26, Heat after the first loss), same runner (OpenCode 1.19.5 on Ryan's PC, `tools/pc/work_issue.bat`, one-hour cap), same task file.

## Measurements

| | DeepSeek V4.1 Flash | Kimi K3.1 Pro |
|---|---|---|
| Result | PR #241, **merged** on the first review | PR #242 closed: hit the one-hour cap (exit 124) mid-wrap-up |
| Review burden | one pass; no structural comments; one nit (the Heat shadow-pool XP is banked and flows to benched lines on the next run, not this one) | not mergeable as delivered: no screenshots, no report (the PR text is a half-finished thought), CI incomplete when reviewed |
| Real charge (balance before minus after) | **$0.09** | **$4.95** (anchor $3.68: 1.35x, inside the 2x rule) |
| Dispatch to PR | 38 min | 61 min (third attempt) |
| Model calls, tool calls (failed) | 116, 131 (0) | 72, 137 (3) |
| Tokens in, out, cache read | 184k, 18.5k, 15.3M | 567k, 31.7k, 13.9M |
| Checks | standing checks, rules parity, campaign parity 30/30 all PASS; own test in JS and Godot | campaign parity 30/30 PASS; rules parity battles PASS, its math sweep tripped on Node 24 (see friction) and the agent ran out of time re-checking |
| Throttle events | none | two failed starts: Moonshot starter tier (one request at a time, then 3 a minute) until the paid total reached $10 |

## Quality, side by side

Both built the same gate (a real loss opens Heat, abandoned runs do not count, older winners keep it) and the R63 payout (+2 XP per point to the flown line, +1 to the shadow pool), browser and Godot together.

Kimi's version had better judgment in three places: it back-fills `losses` from the run log on load, so a profile that has already lost opens Heat at once; it blocks toggling Heat while locked; and it shows the Heat payout on the debrief screen. It folded the payout into `awardLineageXP`, so the pool XP flows to benched lines the same run. DeepSeek's is plainer but complete, tested and evidenced. The loss back-fill is worth taking; it is a small follow-up (log in LOOP), not a reason to pick Kimi.

## Friction

- Moonshot starter tier blocks agent use outright (concurrency 1, 3 requests a minute); OpenCode exits on a 429 instead of retrying. Needs the $10 paid total before any Kimi run.
- Both agents lost time on a false parity failure: the shell's Node 24 gives 4,048 `pow` differences in the math sweep; the repo's bundled Node 22 gives none. Fix: the runner puts `voidsworn_test\node` first on PATH (done with this note).
- Ryan's top-up had not posted when the first rerun started (balance unchanged), costing one more failed start.

## Decision

Under #217's rules Kimi fails this trial (throttle events, not mergeable in one pass) and DeepSeek passes, so DeepSeek becomes the primary model inside OpenCode.

The subscription rule is revised (Ryan, Nov 8): a Kimi subscription is worth far more than its price in API terms (Ryan cites about $847 of API value a month from Muse's stack review; not checked here), so the old "only above $39 a month of API spend" rule is dropped. The subscription question becomes purely: does Kimi's work beat DeepSeek's by enough to matter? This one bounded job says no: DeepSeek matched it at a fiftieth of the cost and finished in time. One harder job decides it: both arms on #120 (Nemesis registry, multi-file, parity-heavy) with a 90-minute cap, on the balances already loaded (about $11 Moonshot, $1.91 DeepSeek). If Kimi's PR is clearly better there, buy Kimi Code Pro monthly and run the capacity test on its first job (under about 5 percent of the monthly pool); if not, DeepSeek stays primary and Kimi stays pay-as-you-go for second opinions.
