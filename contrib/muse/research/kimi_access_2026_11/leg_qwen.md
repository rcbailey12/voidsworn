# Leg: Qwen (selector Qwen3.8-Max verified before and after; the new chat had defaulted to Qwen3.7-Plus and was switched; Nov 13, 2026, 10:53-10:59 CST)

Research Leg: Running Kimi as a Coding Worker (Voidsworn #653)
Prepared: 14 Nov 2026 · Analyst leg: Qwen3.8
Method note: I do not have live internet access in this session. Every figure below is drawn from (a) the trial record you supplied (treated as ground truth), (b) my training-data knowledge of Moonshot AI / Kimi documentation and OpenRouter listings up to my knowledge cutoff, or (c) arithmetic I perform in-line and label as an estimate. Where I cannot confirm a number against the vendor's live page, I say so explicitly. URLs are given as the canonical locations to check; I mark each "verified" or "unverified - check live."

Q6 (FIRST PRIORITY): Squeezing the Kimi Code Plan Already Owned

Models the plan serves (from the owner's own keycheck - given fact)
The keycheck on the $19/mo Kimi Code plan returned six model ids:
1 kimi-for-coding - Coding-tuned default - Not yet trialled on the reference job
2 kimi-for-coding-highspeed - Faster / lighter coding variant - Not yet trialled
3 k3-256k - K3 with explicit 256 K context cap - Not yet trialled
4 k3.1-pro-highspeed - K3.1-Pro, faster / possibly non-thinking - Not yet trialled
5 k3 - General K3 - Trialled Nov 13: 27.5 min of agent work → hit 5-hr quota, no PR
6 k3.1-pro - Flagship - Trialled multiple times; 256 K context cap enforced by plan
Source: owner's keycheck output, Nov 2026 (given fact). I have no independent Moonshot doc page to cross-check this list; treat the keycheck as the authority.

Does each model draw the 5-hour quota at a different rate?
What the trial record shows (given fact):
k3.1-pro, code-review job: 5 parallel sub-agents, ~240 K tokens at top level → 5-hr limit hit in 9 minutes.
k3.1-pro, reference job, 250 K context cap: ~2 M tokens over ~21 steps → 5-hr limit hit.
k3, reference job: 27.5 min agent time → 5-hr limit hit, partial.
These three data points are consistent with quota being metered in agent-time or tokens consumed, not wall-clock. The 9-minute burn (240 K tokens, 5 sub-agents) vs. the 27.5-minute burn (k3, presumably single-agent) suggests the meter is token-weighted, not purely time-weighted: more tokens in a shorter wall-clock can exhaust the window faster.
What I cannot verify: whether kimi-for-coding-highspeed or k3.1-pro-highspeed draws quota at a lower per-token rate (e.g., because they skip chain-of-thought tokens) or a higher one (because "highspeed" routes to more compute). Moonshot's Kimi Code plan documentation, as far as I can recall from training data, describes the quota as a rolling 5-hour usage window plus a monthly cap, but I do not have a verified page that publishes per-model multipliers.
Missing source. I cannot confirm whether Moonshot publishes a per-model quota-consumption table for the Code plan. Check: the Kimi Code plan settings page inside the Kimi app / web console, or https://platform.moonshot.cn/docs/pricing (unverified URL for the Code plan specifically; the platform docs may only cover pay-as-you-go API).
Practical inference (estimate, not vendor-stated):
If the 5-hr window is token-metered, and k3 burned through it in ~27.5 min of agent work on the reference job, then a "highspeed" variant that omits or shortens reasoning traces could reduce output tokens by 30-60 % (typical for thinking vs. non-thinking modes in comparable models). That might stretch the same 5-hr window from ~27 min to ~40-55 min of agent time. This is an estimate; the only way to confirm is a trial.

Can thinking / reasoning effort be lowered?
Through OpenCode: OpenCode passes whatever the provider's API accepts. If the Kimi Code plan endpoint accepts a parameter like thinking: {type: "disabled"} or reasoning_effort: "low", OpenCode can forward it. As of my training data, Moonshot's K2/K3 API supported a thinking or reasoning parameter on some endpoints, but I cannot confirm whether the Kimi Code plan's proxy endpoint passes it through. The plan may strip or ignore it.
Through model choice: The -highspeed suffix on kimi-for-coding-highspeed and k3.1-pro-highspeed strongly suggests a reduced-reasoning or non-thinking variant. This is the most reliable lever available without knowing whether a parameter is accepted.
Through OpenCode config: The owner already disabled sub-agent tasks in the kimicode arm. This is confirmed to help (the 9-min burn was caused by 5 parallel helpers).

Exact WORK_MODEL settings for a trial matrix
The runner sets one variable. Using the OpenCode provider-arm naming (kimicode/<model>):
Trial A (baseline, already done) kimicode/k3 - 27.5 min, hit quota, no PR
Trial B kimicode/kimi-for-coding - Purpose-built coding model; may be more token-efficient for agentic coding
Trial C kimicode/kimi-for-coding-highspeed - Same but faster / lighter; likely fewer reasoning tokens
Trial D kimicode/k3.1-pro-highspeed - Flagship knowledge, reduced reasoning overhead
Trial E kimicode/k3-256k - Explicit 256 K cap baked into model id; may avoid the 403 the owner hit
Additional OpenCode config for every trial:
{ "provider": "kimicode", "context_limit": 250000, "sub_agents": false, "max_steps": 30 }
If the endpoint accepts a reasoning parameter, add: "extra_body": { "thinking": { "type": "disabled" } } // or "extra_body": { "reasoning_effort": "low" }
I cannot confirm the Kimi Code plan endpoint honours these fields. Test with a 2-step smoke run before the full reference job.

Can the reference job fit in one 5-hr window on this plan? Estimate (labelled):
k3 burned the full 5-hr quota in 27.5 min of agent work on the reference job (~2 M tokens, extrapolating from the 21-step k3.1-pro run).
The reference job needs ~49 min of agent work (the competitor's time).
Even with a 40 % token reduction from a highspeed model: 27.5 min × (1 / 0.6) ≈ 46 min. That is marginal - it might finish, or it might hit the wall at 90 %.
With a 60 % reduction: 27.5 / 0.4 ≈ 69 min. More comfortable, but a 60 % reduction is optimistic.
Verdict: The $19 plan is borderline-to-insufficient for the full reference job in one window, even on the best model variant. It may work for a sliced job (see Q4). The Board's own conclusion ("about 30 minutes per 5 hours") is consistent.

Q1: Moonshot Pay-as-You-Go API - Tiers, Prices, Context
Tier structure (from training-data knowledge): Moonshot's API platform (platform.moonshot.cn) has historically used cumulative-recharge tiers: Starter / Level 1 ~¥0 (free tier), ~3 RPM, low TPM - this is what the owner hit rate limits on; Level 2 ~¥50-100, moderate RPM/TPM; Level 3+ higher thresholds, higher concurrency.
I cannot verify the exact thresholds or the current tier count as of Nov 2026. The structure above is from my training data and may have changed. Check: https://platform.moonshot.cn/docs/intro or the billing/rate-limit page in the console.
What the owner needs for one long agent run (60-90 min, single agent, no parallel helpers): Sustained TPM of roughly 80-120 K tokens/min (based on ~2 M tokens over ~25 min of active generation, plus reads). RPM of ~5-15. No 1-hour run cap (or a cap ≥ 90 min). The starter tier almost certainly fails on the run-cap and possibly TPM. One recharge to the next tier may suffice, but I cannot state the exact amount without the live page.
Per-token prices: Critical honesty note: I do not have verified Nov-2026 per-token prices for K3, K3.1-Pro, or the Kimi-for-Coding models from Moonshot's pricing page. The Kimi K2 pricing I recall from mid-2025 was approximately: Kimi K2 (API): ~$0.60 / M input tokens, ~$2.50 / M output tokens (or ¥4/¥16 per M). Cache-hit input: ~$0.10-0.15 / M. Context: 128 K. These numbers are from training data circa mid-2025 and must not be used for budgeting without checking https://platform.moonshot.cn/docs/pricing live. For K3 / K3.1-Pro, I do not have confident pricing. I will not invent prices.
Context sizes: k3.1-pro (via Code plan) 256 K cap enforced by plan, trial record (403 error, Nov 2026) - given fact. k3 (via Code plan): not explicitly stated; likely 256 K or 1 M, unverified. k3-256k: 256 K (in the name), keycheck - given fact. Kimi K2 (API, 2025): 128 K, training data mid-2025. Whether the pay-as-you-go API serves a 1 M context variant of K3/K3.1 and what it costs - I cannot verify.

Q2: Third-Party Hosts (OpenRouter and Others)
OpenRouter (openrouter.ai) aggregates many models behind an OpenAI-compatible API. As of my training data: OpenRouter does list Moonshot / Kimi models. The model id format is typically moonshotai/kimi-k2 or similar. Whether K3, K3.1-Pro, or the Kimi-for-Coding variants are listed as of Nov 2026 - I cannot verify without live access. Pricing pattern on OpenRouter (general, not Kimi-specific): OpenRouter adds a small markup (typically ~5 %) over the provider's direct price. Pricing is per-token, in/out, listed on each model's page. Rate limits depend on the upstream provider and the user's OpenRouter credit balance. OpenCode integration: OpenCode has a built-in OpenRouter provider (given in the question). Setting WORK_MODEL=openrouter/moonshotai/kimi-k3 (or whatever the exact slug is) should work. Alternatively, any OpenAI-compatible endpoint can be added as a custom provider. I am not inventing a per-token price for Kimi models on OpenRouter. Check the live listing.
Other third-party hosts: Together AI, Fireworks, Groq, DeepInfra, etc.: I do not have evidence from training data that these serve Kimi/Moonshot models. Chinese cloud providers (Alibaba Cloud / Bailian, Tencent Cloud, etc.): some may host Kimi models, but I cannot confirm. SiliconFlow: may have hosted some Moonshot models, but I cannot confirm K3/K3.1 availability or pricing as of Nov 2026. Missing source. The owner should check OpenRouter's live model list first, as OpenCode's integration is already built.

Q3: Higher Kimi Code Plan Tiers
The owner's tier: $19/month, 5-hour rolling window + monthly cap, shared across devices. Do higher tiers exist? I cannot verify. From my training data, I recall the Kimi Code / Kimi subscription having at least one tier, but I do not have confirmed details of a higher tier (e.g., $39 or $49) with a larger quota window or higher monthly cap. If a higher tier exists and offers, say, 2× the quota: the reference job might fit. But without a confirmed price and quota, I will not speculate a number. Where to check: The Kimi app → Settings → Subscription, or https://kimi.moonshot.cn.

Q4: Making a Run Fit
4a. Smaller job slices: Slice 1: core behaviour change in the 2-3 scripts (~10 files touched). Slice 2: propagation edits across remaining ~20 files. Slice 3: automated checks + parity run + PR assembly. Each slice could target ~15-20 min of agent time, fitting within the ~30-min-per-window budget the Board observed. Three slices × 3 windows = 3 × 5 hr = 15 hr wall-clock, but only ~45 min of quota consumption. Trade-off: the brief is split, so the agent loses whole-job context. The owner would need to write three sub-briefs and merge PRs manually.
4b. Prompt caching: Moonshot API (pay-as-you-go): Kimi K2 supported cached-token pricing at a significant discount (I recall ~75-85 % cheaper than fresh input tokens for cache hits). Whether K3/K3.1-Pro and the Code plan endpoint support this - unverified. Kimi Code plan: the plan is a flat subscription; caching would reduce token consumption against the 5-hr quota if the meter is token-based. Whether the plan's proxy endpoint sends cache-control headers - unknown. OpenCode support: OpenCode may or may not send cache_control blocks depending on the provider arm implementation.
4c. Cheaper model for reading, flagship for writing: Use kimi-for-coding-highspeed or k3 for file-read / grep / exploration steps. Switch to k3.1-pro for the actual code-writing steps. In OpenCode: this would require either (a) two provider arms and manual switching, or (b) a custom routing layer. OpenCode may not natively support per-step model switching within one session.
4d. Disabling sub-agents: Already done. Confirmed to prevent the 9-minute quota burn. Keep this setting.
4e. Lowering reasoning effort: See Q6. The -highspeed model variants are the most reliable lever. A thinking: disabled or reasoning_effort: low parameter may work if the endpoint accepts it - test with a smoke run first.

Q5: Changes Since 12 Nov 2026
I cannot verify real-time changes. My training data has a cutoff, and I do not have live access. Specific things to check: K2 API model retirement (check https://platform.moonshot.cn/docs for deprecation notices); new models or renames (re-run the keycheck); plan changes (check the Kimi Code plan page). I will not assert any specific change without a source.

Ranked Routes (Best First)
1. Kimi Code $19 plan → kimicode/kimi-for-coding-highspeed or kimicode/k3.1-pro-highspeed, sub-agents off, context 250 K, reasoning reduced. $19/mo (sunk). 5-hr rolling window + monthly cap; 256 K context. Borderline. Estimate: ~40-55 min agent time if highspeed cuts tokens 30-60 %. May need job sliced in two. Trial record (given); model list from keycheck. Quota mechanics unverified against vendor docs.
2. Kimi Code $19 plan → sliced job (2-3 slices), model kimicode/k3 or kimi-for-coding. $19/mo (sunk). Same limits. Yes, if sliced. Each slice ~15-20 min fits in the ~30-min budget. Trial record: k3 did 27.5 min before quota hit.
3. Moonshot pay-as-you-go API, recharged to Level 2+. Unknown per-token until checked; est. a few dollars for ~2-4 M tokens. Higher RPM/TPM; no 5-hr window; likely 128 K or 256 K context. Yes, if rate limits and run cap allow 60-90 min. platform.moonshot.cn/docs/pricing - unverified, check live. Starter tier failed (trial record).
4. OpenRouter → Kimi model (if listed). Per-token, ~5 % markup over direct. Depends on upstream. Probably yes, if the model is listed and context is sufficient. openrouter.ai/models - unverified, check live. OpenCode has built-in OpenRouter provider.
5. Higher Kimi Code plan tier (if it exists). Unknown. Presumably larger quota. Maybe, if quota is 2×+. Unverified. Check Kimi app subscription page.

ONE Pick: Route 1: Kimi Code $19 plan, model kimi-for-coding-highspeed, single-agent, 250 K context.
Rationale: the cost is already sunk; the -highspeed variant is the best available lever to reduce token burn; no new account, API key, or recharge is needed; and it tests whether the plan can stretch to the full reference job before committing money to the pay-as-you-go API.
If it fails (quota exhausted before the PR), fall back to Route 2 (sliced job) on the same plan, then to Route 3 (pay-as-you-go API).

One-Job Trial Plan
Setup (on the owner's Windows PC, in OpenCode): WORK_MODEL=kimicode/kimi-for-coding-highspeed
OpenCode kimicode provider arm config: { "provider": "kimicode", "model": "kimi-for-coding-highspeed", "context_limit": 250000, "sub_agents": false, "max_steps": 35 } // Optional - test in smoke run first: "extra_body": { "thinking": { "type": "disabled" } }
Smoke run (5 min, before the real trial): Job: "Read the file project.godot and list the autoloads." (Trivial, ~2 steps.) Purpose: confirm the model id resolves, the endpoint responds, no 403, and check whether the extra_body thinking parameter is accepted (look at response headers / token usage). Abort if: 403, model-not-found, or the parameter is silently ignored (compare token counts with and without).
Reference-job run: Job: the same mid-size Godot rules-change brief (~2 pages, 2-3 scripts, ~30 files, automated checks + parity run). Branch: fresh branch from the same base commit as the competitor's run. Checks: the project's own automated checks + parity run. What to log: wall-clock time, agent steps, total tokens (input + output), whether the 5-hr quota warning fires, whether a PR is produced.
Success criteria: PR produced, yes, with compilable diff. Agent time ≤ 55 min (inside the estimated quota envelope). Quota does NOT hit the 5-hr wall before PR is pushed. Checks pass at parity with the competitor workhorse's run. Diff quality ≥ the competitor's diff (judged by the owner).
If it fails: Note the step count and token total at quota exhaustion. Re-run with WORK_MODEL=kimicode/k3-256k (explicit context cap may avoid overhead). If still failing, slice the brief into two and run two windows. If the plan is exhausted for the month, move to Route 3 (pay-as-you-go API, recharged).

What I Could Not Verify
- Exact per-token prices for K3, K3.1-Pro, kimi-for-coding on Moonshot's pay-as-you-go API (Nov 2026): no live access to platform.moonshot.cn/docs/pricing. Training-data prices for K2 are from mid-2025 and may not apply.
- Cumulative-recharge thresholds for API tiers above starter: no live access. The tier structure I described is from training data and may have changed.
- Whether the Kimi Code plan meters quota differently per model (e.g., highspeed at 0.5×, 1 M context at 2×): no vendor doc found in training data. The trial record is suggestive but not conclusive.
- Whether thinking / reasoning_effort parameters are accepted by the Code plan endpoint: no doc reference. Must be tested empirically.
- Whether OpenRouter lists K3 / K3.1-Pro / kimi-for-coding as of Nov 2026: no live access to openrouter.ai/models.
- Existence, price, and quota of higher Kimi Code plan tiers: no source.
- Any model releases, renames, or retirements between 12 Nov and 14 Nov 2026: no live access.
- Whether Moonshot's API has a 1 M context variant of K3/K3.1 and its pricing: the trial record's 1.15 M token run suggests >256 K is possible, but the plan capped it. The API may or may not offer it. Unverified.
- Cache-hit pricing for K3/K3.1 on the API or Code plan: training data suggests K2 had cache pricing; K3 specifics unverified.
Where two sources might disagree: I have no concrete disagreement to report because I could only draw on one source per claim (training data or the trial record). The main risk is that training-data pricing/limits are stale relative to the live vendor pages. Every number I gave that comes from training data should be re-checked against the live page before any money is spent.
End of research leg. All estimates are labelled. All gaps are flagged. The next step is the smoke run on kimicode/kimi-for-coding-highspeed.

(Chair note: the model stated it had no live internet access in this session; that limitation is part of the leg. Its header date "14 Nov 2026" is the model's own error; the leg ran Nov 13, 2026.)
