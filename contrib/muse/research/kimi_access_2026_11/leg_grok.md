# Leg: Grok (grok.com, default mode; signed in via Continue with Google completed by Ryan in-browser; this leg read the official Kimi Code docs pages; Nov 13, 2026, 10:53-10:59 CST)

Question 6 first (owned Kimi Code plan access, $19/mo Plus tier).

Official Kimi Code docs (read 2026-11-13 from https://www.kimi.com/code/docs/en/kimi-code/models.html and https://www.kimi.com/code/docs/en/kimi-code/membership.html) list these exact model IDs available on the plan:

Model ID - Version - Context - Notes / quota multiplier - Availability on Plus ($19)
k3.1-pro - K3.1 Pro - Up to 1M (Pro+ only; Plus effectively lower / 256K-class in practice per trials) - Thinking only (reasoning_effort: low/high/max, default high; cannot disable) - Plus+
k3.1-pro-highspeed - K3.1 Pro Highspeed - Up to 1M - ~2-3× speed, ~2× quota - Pro+ only
k3 - K3 - Up to 1M (Pro+ only) - reasoning_effort low/high/max (default high); 1M version ~2× quota of 256K - Plus+
k3-256k - K3 256K - 262,144 fixed - Same quality as k3 within 256K; ~½ the quota of full k3 - Plus+
kimi-for-coding - K2.8 Preview - Up to 1M - Efficient thinking; good for routine coding; default max effort - Plus+
kimi-for-coding-highspeed - K2.7 Code Highspeed - 262,144 - ~5-6× speed, ~3× quota - Pro+ only

Quota behaviour (official): shared rolling 5-hour rate window + monthly total across all devices/clients/API keys. Highspeed and full-1M variants draw more quota. Exact numeric token/request allowances for the 5-hour window are not published (only the existence of the window and that higher tiers give more "agent credits"). Owner trials confirm ~30 min of agent work exhausts the Plus 5-hour window on k3 / k3.1-pro at default settings.

Thinking / reasoning effort can be lowered:
Supported on k3.1-pro, k3, k3-256k, kimi-for-coding via reasoning_effort = low / high / max.
OpenCode / third-party mapping (official): low/minimum/light → low; high/medium → high; ultra/max/xhigh → max. Null uses model default.
K3.1 Pro rejects thinking=off (HTTP 400). Lower effort reduces output tokens and (per vendor guidance) can improve cache hits / lower overall usage, but exact agent-time gain is not quantified by the vendor. Expect meaningful savings on long runs if the harness passes the parameter and the model respects it.

Exact settings for a trial on the owned key (OpenCode kimicode arm, WORK_MODEL):
Prefer: kimicode/k3-256k or kimicode/kimi-for-coding (lower quota burn).
With effort: set reasoning effort to low if the harness exposes it.
Context limit already set to 250000 on the arm (good; keeps under 256K cap).
Sub-agents already disabled (required).
One reference-job estimate on Plus: Owner data shows ~2M tokens / 21 steps exhausted the 5-hour window; a full 60-90 min job will not fit without Extra Usage top-up or a higher tier / different model.

Ranked real routes (best first)

1. Owned Kimi Code Plus + cheapest suitable model + low effort
Cost: $19/mo already paid + possible Extra Usage (billed near Open Platform rates).
Limits: 5-hour rolling window + monthly total; shared. Context 256K on k3-256k / kimi-for-coding.
Fits one reference job? Unlikely on default; possible with k3-256k + low effort + aggressive compaction (estimate: still high risk of hitting window before PR).
Sources: official models/membership pages (2026-11-13).
2. Upgrade to Kimi Code Pro ($39/mo)
Cost: $39/mo (or $31 yearly). Unlocks Highspeed + full 1M on k3/k3.1-pro, higher agent credits (vendor states multiples vs Plus; exact tokens unpublished).
Limits: same 5-hour window structure but larger allowance.
Fits? Higher chance for one 60-90 min job; still not guaranteed without measurement.
Sources: same official pages + secondary plan summaries (2026-10/11).
3. Moonshot Open Platform pay-as-you-go (international API)
Prices (vendor / secondary consistent as of Nov 2026):
kimi-k3.1-pro: $2 / $0.20 cache / $10 out per 1M; 1M context.
kimi-k3: $3 / $0.30 / $15; 1M.
kimi-k2.7-code / kimi-k2.6: $0.95 / ~$0.16-0.19 cache / $4; 256K.
Highspeed variants ~2×.
Rate limits by cumulative recharge (platform.moonshot.ai / platform.kimi.ai docs, various 2026 dates; numbers differ slightly across mirrors): Tier 0 ($1) = 1 concurrent / 3 RPM / 500k TPM / 1.5M TPD - unusable for agents. Practical start: $10 (Tier 1) for usable concurrency/RPM. Higher tiers at $20/$100/$1k/$3k.
One reference job estimate (using owner ~2M tokens, assume ~70% input / 30% output, 50% cache hits): ~$4-12 on K3.1 Pro / K3 depending on exact mix and cache; far less on K2.7 Code. Labelled estimate.
Fits: Yes once past Tier 0. OpenCode can use via custom OpenAI-compatible provider.
Sources: platform docs + BenchLM/LiteLLM/OpenRouter mirrors (Nov 2026). Note: K2 series closing to new users (Oct 31 2026) and planned retirement end-Dec 2026 - prefer K3.1 Pro for new accounts.
4. OpenRouter (or other OpenAI-compatible hosts) of Kimi models
Official Moonshot rates or lower (e.g. Relace etc. on K3.1 Pro down to ~$0.24/$8.4). Context 1M on flagships. Rate limits are host-dependent; OpenRouter has its own. OpenCode has built-in OpenRouter provider + custom OpenAI-compatible support.
One job estimate: similar to or cheaper than direct API.
Sources: openrouter.ai model pages (Nov 2026).
5. Higher Kimi Code tiers (Max $99 / Ultra $199) or Extra Usage on existing plan
Multiples of agent credits (vendor language); same model set as Pro. Extra Usage billed near API rates and shared with web Kimi. Useful as overflow but not a primary long-run solution.

Ways to make a run fit (Q4)
Smaller job slices / more frequent compaction.
Prompt caching: supported on API (cache-hit rates ~1/10th); plan supports it via native endpoints - keep model + effort stable within a session.
Cheaper model for reading (kimi-for-coding / k3-256k) + flagship for writing (if harness supports model switching mid-run).
Disable sub-agents (already done).
Lower reasoning_effort to low.
Context limit already set.

Changes since Nov 12 2026 (Q5)
No major new models or plan renames visible in primary docs on Nov 13. K3.1 Pro fully rolled out earlier (Oct). K2 series retirement still pending end-Dec; new API accounts should avoid depending on it.

ONE pick + one-job trial plan
Pick: Stay on owned Plus key, switch to kimicode/k3-256k (or kimicode/kimi-for-coding) with lowest practical reasoning effort. Lowest new spend, uses existing access, and the 256K variant is explicitly cheaper on quota.
Trial:
Set WORK_MODEL=kimicode/k3-256k (or kimicode/kimi-for-coding).
Ensure sub-agents disabled, context limit 250000, reasoning effort low if the arm exposes the parameter.
Run the exact reference job (same 2-page brief, mid-size Godot rules change, ~30 files, checks + parity).
Success = finishes inside one 5-hour window, produces a clean PR that passes project checks, and diff quality is at least as good as the competitor workhorse (49 min / few cents).
If it still hits the window, immediately fall back to OpenRouter / direct API on moonshotai/kimi-k3.1-pro (or cheapest host) with a $10+ recharge for Tier 1 limits, and re-run the same brief. Measure actual tokens/cost.

What could not be verified
Exact numeric size of the Plus 5-hour quota or monthly total (vendor does not publish tokens/requests). Precise agent-time multiplier from reasoning_effort=low. Exact concurrency numbers on every Open Platform mirror (slight discrepancies across secondary sources; trust the platform.moonshot.ai / platform.kimi.ai pages). Current live OpenRouter rate limits and any temporary queueing on K3.1 Pro. Whether the owner's existing key is on a "new" or "legacy" plan (affects weekly window presence).
