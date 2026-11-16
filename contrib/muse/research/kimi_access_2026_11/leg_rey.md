# Leg: blind Rey (written first, before any other leg was seen)

Research date: Nov 13, 2026. Sources are the providers' pages as captured by dated third-party trackers where the vendor page itself could not be read directly; every such case is marked. Vendor-stated figures are vendor-stated and unmeasured unless the trial record says otherwise.

## Question 6 first: the models on the plan Ryan already has

The plan's served models (project keycheck, Nov 12, 2026, given fact): kimi-for-coding, kimi-for-coding-highspeed, k3-256k, k3.1-pro-highspeed, k3, k3.1-pro.

What those ids are, from the Kimi Code documentation as summarised by dated secondary sources (logeshwaran.org guide, Oct 2026; tomrochette.com model-access notes, re-verified Nov 7, 2026; membership docs at kimi.com/code/docs):
- kimi-for-coding is K2.8 Preview (since Sep 11, 2026), described as close to K3 with more efficient thinking; 1M context; available at Plus ($19).
- kimi-for-coding-highspeed is K2.7 Code HighSpeed, about 6x faster output; 256K context; needs Pro ($39) and above.
- k3 at full 1M context needs Pro and above; at Plus, K3 runs at 256K context. k3-256k is the explicit 256K variant.
- k3.1-pro is the current flagship API model (released Oct 24, 2026) and the arm's default; the plan caps it at 256K context (the project's 403 incident proves the cap is enforced).

Quota draw differs by model (secondary source, the logeshwaran.org guide, Oct 2026; NOT yet found on a vendor page, so treat as unverified): K3 at 1M context uses about twice the quota of K3-256K, and HighSpeed models about three times. If that holds, the trial record reads differently: the Nov 13 run used k3 (at Plus, so 256K context) and still burned the window in 27.5 minutes, which means the window on Plus is small in absolute terms, and model choice alone may buy 2x at best (k3-256k does not help if k3 at Plus already runs 256K). The unexplored lever is kimi-for-coding: a coding-tuned model with more efficient thinking should burn fewer tokens per step, and steps are what the quota meters.

Reasoning effort: no vendor page found states a reasoning-effort parameter for the Kimi Code endpoint. OpenCode passes provider options through, and the Moonshot API accepts the usual chat parameters, but whether the coding endpoint honours a thinking toggle is unverified. K2.8 Preview's "more efficient thinking" is a model property, not a setting. Mark: unverified, test in the trial by token counts per step.

## Question 1: Moonshot API tiers

Platform pricing (platform.kimi.ai/docs/pricing/chat as read Sep 29, 2026 by whichdevtool.com; usagepricing.com fact-check Nov 9, 2026):
- kimi-k3: $3.00 in / $15.00 out per 1M; cache-hit input $0.30.
- kimi-k3.1-pro (flagship, Oct 24, 2026): $2.00 in / $10.00 out; its HighSpeed variant $4.00 / $20.00.
- kimi-k2.7-code: $0.95 / $4.00, cache-hit $0.19. kimi-k2.6: $0.95 / $4.00, cache-hit $0.16.
Recharge tiers (same sources; the two trackers disagree on Tier 1's exact numbers, reported both ways): Tier 0 at $1 cumulative: 1 concurrent, 3 RPM, 1.5M tokens/day. Tier 1 at $10 cumulative: no daily token cap; concurrency 15 (whichdevtool) or about 50 (kodus docs, rapidevelopers); RPM 100 (whichdevtool) or 200 (rapidevelopers). Higher tiers at $20, $100, $1,000, $3,000 cumulative recharge. For ONE agent with sub-agents disabled, even the lower reading of Tier 1 (15 concurrent, 100 RPM) is far above what a single OpenCode run needs; the starter-tier refusals in the trial record match Tier 0's 3 RPM and daily cap. So the unlock is $10 of cumulative recharge, not a subscription.
Caveat (usagepricing, Nov 9, 2026): the K2 API models closed to newly registered platform users on Oct 31, 2026 and are expected to retire at the end of December 2026. Whether the project's existing platform account still lists k2.7-code must be checked on the account itself; a brand-new account cannot buy it, which pushes a new API route to k3.1-pro pricing.

## Question 2: third-party hosts

OpenRouter (catalogue snapshots Nov 12 to 13, 2026, via ai-hippo and daily.rclabs, which read OpenRouter's own listings): moonshotai/kimi-k2 at $0.57 in / $2.30 out (131K context), kimi-k2-0905 at $0.60 / $2.50 (262K), kimi-k2-thinking at $0.60 / $2.50 (262K, cached input $0.15), kimi-k2.7-code listed at $0.60 / $3.50, kimi-k2.6 at $0.65 / $3.41. Providers behind the listings include Novita, IO.NET and Prime Intellect at near-identical prices. OpenRouter is OpenAI-compatible and is a built-in OpenCode provider, so the runner needs only a key and a model id. No quota window; the limit is the prepaid balance. Direct-from-Novita pricing matches OpenRouter's for K2 ($0.57 / $2.30), so OpenRouter's cut is not the deciding factor.

## Question 3: higher Kimi Code tiers

Membership ladder (kimi.ai, read Nov 6 to 7, 2026 by thenewway.ai and tomrochette.com): Plus $19, Pro $39, Max $99, Ultra $199 a month (annual billing $15 / $31 / $79 / $159). Agent credits sized only as multiples of Plus: Pro 2x, Max 5x, Ultra 10x. No tier states an absolute quota. New plans: rolling 5-hour window only, no weekly cap; legacy plans (the $19 tier's old name was Moderato, equivalent to Plus) keep a weekly window too. Pro and above also unlock K3 at 1M context and the HighSpeed model. Extra Usage (pay-as-you-go overflow) exists on the China ladder (25 CNY minimum); its USD availability is unverified.

## Question 4: making a run fit

- Sub-agents off (already applied): trial 1's 9-minute burn was five parallel helpers; that fix alone is worth roughly 5x.
- Cache pricing is real on the API (cache-hit input at roughly a tenth of miss price on K3, $0.30 vs $3.00), and agent runs re-read the same files constantly, so the API routes get cheaper than the sticker rate suggests. Whether the Kimi Code plan meters cached tokens at a discount is unverified.
- Cheaper reader, flagship writer: the API and OpenRouter both allow per-job model choice; nothing stops a two-pass brief (K2-class model explores and summarises, K3.1 Pro writes). Untested in this project.
- Slicing the job: the reference job at 30 files is what burned 2M tokens in 21 steps; a half-size slice plausibly fits the Plus window, at the cost of two windows per job.

## Question 5: changes since Nov 12

- K3.1 Pro has been the flagship since Oct 24, 2026, priced a third below K3 ($2/$10 vs $3/$15), with a HighSpeed variant at double.
- K2 API models: closed to new platform accounts Oct 31, 2026; retirement expected late December 2026. This is the biggest change for route planning: K2.7 Code is a wasting asset on the vendor API, though OpenRouter listings persist for now.
- Membership tiers were renamed in October 2026 (musical names to Plus/Pro/Max/Ultra) at unchanged prices; the project's $19 Moderato is a legacy Plus-equivalent.

## Cost of one reference job, per route (estimates, arithmetic shown)

Token assumption, from the trial record: about 2M tokens per 21 steps; a 60 to 90 minute job at the observed pace is roughly 60 to 90 steps of reading-heavy work, so 6M to 10M tokens total; assume 80 percent input, 20 percent output, and half the input served from cache on API routes.
- Moonshot API, k3.1-pro ($2/$10, cache-hit assumed $0.30 by analogy with K3; the exact K3.1 Pro cache price is unverified): input 6.4M tokens at a blended ~$1.15 = ~$7.40; output 1.6M at $10 = $16. Total roughly $20 to $25 per job. No quota window; fits by construction once Tier 1 ($10 recharge) is reached.
- OpenRouter, kimi-k2.7-code ($0.60/$3.50): input 6.4M = $3.84 before cache effects; output 1.6M = $5.60. Roughly $8 to $12 per job. Cheapest paid route; model is a generation behind the flagship and its listing may not outlive the K2 retirement.
- Kimi Code Pro ($39, 2x Plus credits): if the Plus window holds about 30 minutes of k3 work, Pro holds about 60, and kimi-for-coding's leaner thinking plausibly stretches that past 90. Estimate: fits, unmeasured. Max ($99, 5x) fits comfortably on the same arithmetic.

## Ranked routes and pick

1. Existing Plus plan, model switched to kimi-for-coding, sub-agents off, context limit set (zero new spend; answers Question 6 with real data).
2. OpenRouter kimi-k2.7-code pay-as-you-go (no window, ~$10 a job, OpenCode-native; wasting asset if K2 listings retire).
3. Moonshot API Tier 1 with k3.1-pro ($10 recharge unlock; ~$20 to $25 a job at flagship quality; durable route).
4. Kimi Code Pro $39 (only if route 1 shows the plan's models are good and only the window is small).
5. Moonshot API K2.7 Code direct (cheapest per token, but new-account closure and December retirement make it a poor thing to build on).

ONE PICK: route 1 as the trial, because it costs nothing and settles the question Ryan actually asked (the other models on the access he has). Trial plan: WORK_MODEL=kimicode/kimi-for-coding on the kimicode arm, sub-agents off, context limit 250000, run the reference job's brief (issue 42, the same brief the workhorse ran), cap 90 minutes. Success: a pushed PR inside one 5-hour window with checks run, and a token-per-step count visibly below the k3 run's. If it dies on quota like the others, the pick falls to route 2 for cheap work and route 3 for flagship work, and the plan stays a review seat.

## Not verified

- The quota-draw multipliers by model (2x for 1M context, 3x for HighSpeed) rest on one secondary guide; no vendor page states them.
- Whether the coding endpoint accepts a reasoning-effort or thinking parameter.
- K3.1 Pro's exact cache-hit price; Tier 1's exact concurrency and RPM (sources disagree, 15 vs 50 and 100 vs 200).
- Whether the project's existing Moonshot platform account still lists the K2 models after the Oct 31 closure.
- Extra Usage overflow on the USD membership.
