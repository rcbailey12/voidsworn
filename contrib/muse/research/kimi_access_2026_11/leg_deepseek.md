# Leg: DeepSeek (DeepThink ON, Search OFF, verified before and after; chat https://chat.deepseek.com/a/chat/s/68e84b25-3904-44fb-b44c-ee45c299e066; Nov 13, 2026, 10:53-10:59 CST)

Verification note (read first)

I cannot browse or fetch live vendor pages in this session. I will not invent 2026 prices, quotas, tier names, or model ids. Every number below is either:

- from your trial record, dated 2026-11-12/13 where stated, or
- my arithmetic, explicitly labelled estimate.

Where a vendor pricing/limits page is required, I mark it SOURCE MISSING. I include official entry-point URLs only as places to verify; I have not read them for this answer.

## 6. FIRST: what can be tried on the Kimi Code plan already owned

### 6.1 Models the plan serves

From the keycheck in your trial record (dated before 2026-11-13), the plan serves these exact provider/model ids under the kimicode arm:

| WORK_MODEL value | What the record establishes | Quota draw rate | Context |
|---|---|---|---|
| kimicode/kimi-for-coding | listed by keycheck | unknown | unknown |
| kimicode/kimi-for-coding-highspeed | listed; "highspeed" variant | unknown - do not assume same rate | unknown |
| kimicode/k3-256k | listed; name implies 256K variant | unknown | likely 256K from name; not vendor-verified here |
| kimicode/k3.1-pro-highspeed | listed; highspeed variant of K3.1 Pro | unknown | unknown |
| kimicode/k3 | listed; used in 2026-11-13 trial | unknown | unknown |
| kimicode/k3.1-pro | plan default; 403 showed plan caps it at 256K | unknown | 256K cap observed in trial record |

The record does not establish which of these are non-thinking, preview, older, or faster beyond the names. It also does not establish that highspeed variants or 1M/256K variants draw the 5-hour quota at different rates. That is a vendor quota-rate question; SOURCE MISSING.

### 6.2 Lowering thinking/reasoning effort through OpenCode or provider params

There is no verified evidence in the trial record that the Kimi Code plan exposes a working reasoning_effort or "thinking off" parameter through OpenCode. OpenCode can pass provider/model options generally, but the exact Kimi Code option key is not verified. Do not assume reasoning_effort: "low" works; test it as an experiment, not as a known lever.

How much agent time would that buy per 5 hours? Unknown. The only real measurement is: kimicode/k3 consumed the plan's 5-hour quota after 27.5 minutes of agent work and about 2M tokens on 2026-11-13. That is a partial reference-job run, no PR. There is no measured multiplier for lower reasoning.

### 6.3 Exact trial matrix on the owned plan

Run these as separate one-job trials, same brief, sub-agents disabled, one agent only. Use the context cap where known.

| Priority | WORK_MODEL | Context setting | Why |
|---|---|---|---|
| 1 | kimicode/kimi-for-coding | unknown; set only if provider states cap | Cheapest-looking coding-specific id; least evidence |
| 2 | kimicode/k3-256k | 250000 if it is the 256K variant | Tests the 256K id directly |
| 3 | kimicode/k3 | unknown; do not exceed stated cap | Already measured as failing at 27.5 min |
| 4 | kimicode/k3.1-pro | 250000 | Known 256K cap; already failed context/quota |
| 5 | kimicode/k3.1-pro-highspeed | unknown | Highspeed may or may not cost more quota |
| 6 | kimicode/kimi-for-coding-highspeed | unknown | Highspeed variant |

For the known K3.1 Pro cap, your record says the fix was context limit 250000 on both kimicode models. Use that only where the model is 256K-capped; do not apply a 250K limit to a model whose cap you have not verified.

Expected result from the evidence: the $19 plan is a short-review plan. The 2026-11-13 k3 run hit the 5-hour quota at 27.5 min / ~2M tokens, partial, no PR. The reference job bar is 49 min. So the owned $19 plan is not a credible full-reference-job route unless a variant cuts token burn by roughly half or more. That is an estimate: 49/27.5 ≈ 1.78× the observed partial run's duration, and at the same token rate the full job would be ~2M × 1.78 ≈ 3.56M tokens. Label: estimate.

## Ranked real routes

| Rank | Route | What it costs | Limits / context | Does one reference job fit? | Source status |
|---|---|---|---|---|---|
| 1 | Moonshot first-party pay-as-you-go API above starter, K3.1 Pro, one agent | Per-token; price missing | Starter refused starts and hit a 1-hour run cap in your record. Need a tier with at least ~73k TPM sustained and concurrency ≥1, no 60-min run cap. Context must be verified; plan K3.1 Pro was 256K-capped. | Likely yes if tier is reachable; needs vendor tier check | Trial record 2026-11; vendor pricing/tier page SOURCE MISSING |
| 2 | OpenRouter or another OpenAI-compatible Kimi host | Per-token; price missing | Host-dependent rate limits; need ≥1 concurrency and ~73k TPM. Context model-dependent. OpenCode has built-in OpenRouter and custom OpenAI-compatible provider support (given in your brief). | Possible; no 5-hour subscription window | Vendor model pages SOURCE MISSING |
| 3 | Higher Kimi Code plan tier, if one exists | Unknown; $19 tier exists. Estimate: need 2-3× the $19 quota to fit 60-90 min, so ~$38-$57/mo if linear - not vendor-stated | Still rolling 5-hour + monthly, shared across clients/devices | Possible only if ≥2-3× quota; unverified | Vendor plan page SOURCE MISSING |
| 4 | Current $19 Kimi Code with model/settings variants | $19/mo, already owned | 5-hour rolling quota; measured ~2M tokens / 27.5 min on k3 | No for full job on current evidence; only slices | Trial record 2026-11-12/13 |

Arithmetic for the TPM requirement: the 2026-11-13 k3 run used about 2,000,000 tokens in 27.5 min → 2,000,000 / 27.5 ≈ 72,727 tokens/min. At the same rate, a 49-min job ≈ 3.56M tokens. So a paid API route needs to sustain roughly 73k TPM plus burst, with one concurrent request. Label: estimate from trial record.

## ONE pick

Pick: Moonshot first-party pay-as-you-go API, above the starter tier, running K3.1 Pro as a single agent with no sub-agents.

Why: it is the only route where the exact model family you already tested is first-party, and the failure mode on the starter API was rate/run limits - a tier problem, not a model-capability problem. The $19 subscription has already shown it cannot finish the reference job inside one 5-hour window. Third-party hosts are a valid fallback, but I cannot verify a current Kimi K3.1 Pro listing, price, context, or rate limit.

Caveat: I cannot give you the exact API WORK_MODEL string or tier name from primary sources here. The subscription id kimicode/k3.1-pro is not the API id. Do not guess it. Read the Moonshot console's model id for K3.1 Pro and set:

WORK_MODEL=<moonshot-provider>/<console-model-id-for-K3.1-Pro>

If OpenCode's Moonshot provider id is moonshot, that would be moonshot/<console-id>, but the provider id itself must be confirmed in OpenCode's provider list.

## One-job trial plan

Precondition: in the Moonshot console, find the lowest tier that publishes at least ~73k TPM sustained, concurrency ≥1, and no 60-minute run cap. If the recharge threshold is unacceptable or no such tier is published, stop and use OpenRouter/custom-host route instead.

Model: K3.1 Pro API model id exactly as shown in the console. Do not use the kimicode/ subscription id.

Settings: one agent; sub-agent tasks disabled; no parallel helpers; context limit 250000 only if the API model's context cap is 256K; otherwise use the vendor cap. Set a hard spend cap in the Moonshot console.

Job: the same reference brief - Godot rules change, 2-3 scripts, ~30 files, checks and parity run, ~2 pages.

Success: a PR within 90 minutes of agent time, checks and parity pass, diff quality at least equal to the workhorse, and total API spend recorded. Also record total tokens, TPM, cache-hit tokens, and whether any run cap fired.

Fail condition: any 60-minute cap, repeated rate refusal, or no PR by 90 minutes. Then move to OpenRouter/custom host.

## 1. Moonshot API tiers above starter

What tier unlocks one 60-90 minute agent run? I cannot name it from primary sources. Your record says the starter tier refused two starts and a third run hit a one-hour cap. So the minimum requirement is:

- concurrency ≥1,
- sustained TPM ≥ ~73k (estimate from 2M tokens / 27.5 min),
- no 60-minute run cap, or a cap ≥90 minutes,
- context ≥256K for K3.1 Pro if the job needs it.

Cumulative recharge thresholds: SOURCE MISSING. I will not invent tier names or thresholds.

Per-token prices, context, cache pricing for current Kimi coding models: SOURCE MISSING. I cannot state K3.1 Pro API input/output/cache prices. The only price-like fact in the record is the $19/month Kimi Code plan, dated by your brief.

## 2. Third-party OpenAI-compatible hosts

OpenCode usability: yes in principle - your brief states OpenCode has a built-in OpenRouter provider and supports custom OpenAI-compatible providers. That is the strongest verified fact for this route.

Prices, context, rate limits: SOURCE MISSING. I cannot verify which hosts serve the current Kimi coding model, at what price, with what context, or whether they allow one long 90-minute agent run. Required minimum: ≥1 concurrent request and ~73k TPM sustained; model context ≥256K if the brief needs it.

Candidate places to verify: OpenRouter model pages, and any first-party Kimi-compatible host you already trust. Do not assume a "Kimi K2" listing is the current K3.1 Pro coding model.

## 3. Higher Kimi Code plan tiers

SOURCE MISSING. Your record establishes only the $19/month tier and its behavior: rolling 5-hour quota plus monthly total, shared across clients/devices; k3 hit the 5-hour quota after 27.5 min and ~2M tokens on 2026-11-13.

If higher tiers exist, the minimum useful multiple is roughly 2-3× the $19 tier's usable agent time, because the reference job is 49 min and the $19 tier gave ~27.5 min partial. At linear pricing that is ~$38-$57/month - estimate, not vendor-stated. The vendor may not price quota linearly.

## 4. Ways to make a run fit a quota or budget

- Slice the job: split the reference job into 2-3 PR-sized slices. This is the most reliable quota fix, but it changes the comparison bar and may increase review overhead.
- Disable sub-agents: already applied in your record; keep it. The first trial hit the 5-hour limit in 9 minutes because five parallel helpers ran.
- Context cap: keep 250000 for 256K-capped models. The unset-context run failed with HTTP 403 after 1.15M tokens over 10 steps and 43 file reads.
- Prompt caching: vendor cache-hit pricing and plan support are SOURCE MISSING. Caching could help because the trial did 43 file reads, but I cannot state a discount or quota effect.
- Cheaper model for reading, flagship for writing: plausible, but OpenCode routing per sub-task is not verified with sub-agents disabled. Treat as an engineering change, not a config toggle.
- Lower reasoning effort: unverified on Kimi Code/OpenCode. Test only as an experiment; no measured time-per-5-hours figure exists.

## 5. Changes since 2026-11-12

SOURCE MISSING. I cannot verify new models, renamed plans, or retirements since 2026-11-12. Specifically, I cannot confirm any announced retirement of older K2 API models. For a new API account: do not build the trial on a K2 model unless the Moonshot deprecation page explicitly says it is current. Use the current K3.1 Pro/K3 ids from the console.

## What I could not verify

- Any live Moonshot pricing, rate-limit tier, recharge threshold, per-token price, cache price, or context cap.
- The exact API model id for K3.1 Pro.
- Whether any Kimi Code model draws the 5-hour quota at a different rate.
- Whether reasoning_effort or "thinking off" works through OpenCode for Kimi Code.
- Any higher Kimi Code plan tier and its quota multiple.
- Any third-party host's current Kimi model id, price, context, or rate limit.
- Any post-2026-11-12 model/plan/retirement change, including K2 API retirement.

No two live sources are compared here because no live sources were fetched; the only source used for measured behavior is your trial record dated 2026-11-12/13.
