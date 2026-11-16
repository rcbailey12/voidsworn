# Running Kimi as a coding worker: synthesis (issue 653)

Council: blind Rey leg first, then DeepSeek, Qwen, Grok and Flash, all gated (R231). Chaired by Rey, Nov 13, 2026. Every price and limit is dated and sourced in the legs; vendor-stated figures are vendor-stated and unmeasured until a real run logs them. The full legs are filed beside this synthesis.

## THE PICK

Run the one-job trial on the Kimi Code plan Ryan already pays for, with the two documented levers no trial has used yet:

- WORK_MODEL=kimicode/kimi-for-coding (K2.8 Preview, the plan's coding-tuned model, available on the $19 Plus tier)
- Reasoning effort set to LOW (the model defaults to max effort; the docs expose reasoning_effort low/high/max, and thinking cannot be switched off, only lowered)
- Sub-agents off and context limit 250000, as already configured on the kimicode arm
- The same brief the workhorse ran: issue 42, same base, cap 90 minutes

Success: a pushed PR inside one 5-hour window, checks passing, tokens per step logged against the k3 run's. Pre-decided fallback if it hits the window anyway: Moonshot API at Tier 1 (a $10 cumulative recharge) running kimi-k3.1-pro, an estimated $10 a job with no quota window at all. Ryan decides; no purchase is made by this job.

Why this pick: every failed trial so far ran the flagship models (k3, k3.1-pro) at their default reasoning effort, which is HIGH on k3 and MAX on kimi-for-coding. The docs the Grok leg read show quota draw is model-dependent and effort is a real parameter, so the cheapest experiment is also the one that answers Ryan's actual question (the other models on the access he has) before any new money moves. Three of five legs put an owned-plan variant first; the other two put the Moonshot API first, and the synthesis adopts that as the fallback rather than the lead because it spends money to learn what the free trial can answer.

## Question 6: the models on the owned plan (the first priority)

From the project's keycheck (Nov 12, 2026) and the official Kimi Code docs (models and membership pages, read Nov 13, 2026 by the Grok leg; secondary guides dated Oct to Nov 2026 agree):

| Model id | What it is | Context | On Plus ($19)? | Quota notes |
|---|---|---|---|---|
| kimi-for-coding | K2.8 Preview, coding-tuned, efficient thinking | up to 1M | Yes | Default reasoning effort is MAX; set it low |
| kimi-for-coding-highspeed | K2.7 Code HighSpeed, ~5-6x output speed | 262,144 | No, Pro and up | Draws ~3x quota |
| k3-256k | K3, fixed 256K variant | 262,144 | Yes | About half the quota of full k3 |
| k3 | K3 flagship | 1M only on Pro and up; 256K-class on Plus | Yes | 1M version ~2x the quota of 256K |
| k3.1-pro | K3.1 Pro flagship (Oct 24, 2026) | 1M on Pro and up; plan caps it at 256K in the trials | Yes | Thinking only; rejects thinking=off (HTTP 400) |
| k3.1-pro-highspeed | K3.1 Pro HighSpeed | 1M | No, Pro and up | ~2x quota |

Settled by the chair:
- kimi-for-coding is K2.8 Preview, not K2.7 Code (two legs with dated sources against the Flash leg's unsourced mapping; the highspeed sibling is the K2.7 Code one).
- Both highspeed models are Pro-only, so any trial plan naming them cannot run on the owned tier. The Qwen leg's first pick (kimi-for-coding-highspeed) is therefore not runnable as stated; its second choice is the pick adopted here.
- Reasoning effort IS a documented lever (reasoning_effort low/high/max with an official OpenCode mapping: low/minimum/light to low, high/medium to high, ultra/max/xhigh to max). The DeepSeek and Qwen legs, which could not browse, correctly marked it unverified from their seats. How much agent time low effort buys is NOT quantified by the vendor; the trial measures it.
- Quota multipliers by model (1M about 2x its 256K variant, highspeed about 2-3x) are consistent across the docs-reading leg and two secondary sources, but the vendor publishes no absolute size for the 5-hour window, so all fit judgements below are estimates built on the trial record: about 2M tokens and 27.5 minutes of k3 work exhausts the Plus window; a full reference job at that rate is roughly 3.5M tokens (DeepSeek leg's arithmetic, adopted).

## Ranked routes

1. **Owned Plus plan, kimi-for-coding, effort low** (the pick). Cost: $0 new. Context up to 1M (arm capped at 250000). Fit: unproven, and that is the point of the trial; the two levers (coding-tuned model, low effort) are exactly the ones the failed runs did not use.
2. **Moonshot API, Tier 1, kimi-k3.1-pro.** Unlock: $10 cumulative recharge (Tier 0 is $1: 1 concurrent, 3 RPM, 1.5M tokens/day, which is what refused the starter trials). Prices (platform pricing page as read Sep 29, 2026; trackers re-checked Nov 9, 2026): k3.1-pro $2.00 in / $10.00 out per 1M, cache-hit input $0.20; k3 $3.00 / $15.00, cache-hit $0.30. Tier 1 lifts the daily cap and gives TPM far above the ~73k a single agent needs (legs disagree on its exact concurrency, 15 vs about 50, and RPM, 100 vs 200; both readings clear the requirement, and the Flash leg's $20 Tier 2 is the conservative alternative if Tier 1's page disagrees). Estimated cost of one reference job (~3.5M tokens, 80 percent input, half the input cache-hit): about $10.
3. **OpenRouter, Kimi models.** Catalogue snapshots Nov 12 to 13, 2026: kimi-k2.7-code listed at $0.60 in / $3.50 out per 1M; kimi-k2-0905 $0.60 / $2.50 (262K); kimi-k2-thinking $0.60 / $2.50 with $0.15 cached input. No quota window, OpenCode has a built-in OpenRouter provider. Estimated cost of one reference job on k2.7-code: about $4.50. Caveat: these are K2-generation models, a step behind the flagship.
4. **Kimi Code Pro, $39 a month** (annual $31). Vendor states 2x the agent credits of Plus (Max $99 is 5x, Ultra $199 is 10x), and Pro unlocks the highspeed models and full 1M context. On the trial record's arithmetic, 2x the window plus a leaner model plausibly fits one job, but nothing about the window is published in absolute terms, so this buys probability, not certainty.
5. **Moonshot API, K2.7 Code direct** ($0.95 / $4.00, cache-hit $0.19, 256K). Cheapest per token on the vendor's own platform, but the K2 API models closed to newly registered accounts on Oct 31, 2026 and are expected to retire at the end of December 2026; whether the project's existing platform account still lists them must be checked on the account. A wasting asset either way.

## The trial plan (Board-ready)

1. Arm: kimicode, as configured (sub-agents off, context limit 250000 on the model).
2. Set WORK_MODEL=kimicode/kimi-for-coding and reasoning effort low (the runner has no reasoning-effort setting yet per LOOP, Nov 13; the Board adds it or sets it in the arm config as part of this trial).
3. Smoke run first (Qwen leg's addition, adopted): a two-step read job to confirm the model id resolves, no 403, and that the effort parameter is accepted (compare token counts with and without).
4. Run issue 42's brief from the same base as the workhorse's run, cap 90 minutes. Log: steps, total tokens, tokens per step, whether the 5-hour warning fires, PR or the step where it stopped.
5. Judge against the workhorse exactly as the Board judged 42 before: checks and parity green, diff read by the Board.
6. If it dies on quota: recharge the Moonshot platform account to Tier 1 ($10 cumulative) and rerun the same brief on kimi-k3.1-pro, logging the real per-job cost. That number, not any estimate here, settles the seat.

## Ways to make a run fit (all legs agree)

Sub-agents off (worth roughly 5x; the 9-minute burn was five parallel helpers). Context limit set (the unset run died at 1.15M tokens with a 403). Prompt caching on the API routes (cache-hit input at about a tenth of miss price) rewards a stable system prompt and repeated file reads. Job slicing works on the plan (three slices of 15 to 20 minutes fit the observed ~30-minutes-per-window budget) but changes the comparison bar and costs the Board three briefs and three merges. A cheaper reader with a flagship writer is an engineering change, not a config toggle, while sub-agents are off.

## Changes since Nov 12

K3.1 Pro has been the flagship since Oct 24, 2026, priced a third below K3. The membership ladder was renamed in October 2026 (the $19 tier's legacy name is Moderato, a Plus equivalent; new plans have no weekly window, legacy plans keep one, and which one Ryan's key sits on is unverified). The K2 API closure (Oct 31, 2026) and expected December retirement are the changes with teeth: they cap the life of routes 3 and 5.

## Not verified

- The absolute size of the Plus 5-hour quota and monthly total (the vendor publishes neither).
- The measured agent-time gain from reasoning effort low (documented as a parameter, unquantified as a saving).
- Whether Ryan's Kimi Code key is on a legacy (weekly window) or new plan, and whether his Moonshot platform account still lists the K2 models.
- Tier 1's exact concurrency and RPM (sources disagree; both readings suffice).
- K3.1 Pro on OpenRouter at the prices one leg quoted from a host page (the catalogue snapshots the chair read list K2 models, not K3.1 Pro; treat that listing as unverified).
