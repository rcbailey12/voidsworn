# Leg: Flash (Gemini, picker "Quick answers 3.5 Flash-Lite" verified before and after; chat run Nov 13, 2026, 10:53-10:57 CST)

6. FIRST PRIORITY: Models and Settings on the Owned Kimi Code Plan
Models Served by the Plan

The Kimi Code subscription ($19/month Plus tier or higher) serves the following model IDs:

k3.1-pro - Flagship 3T-class reasoning model with a 1M context window (mandates thinking mode).
k3.1-pro-highspeed - High-speed variant of k3.1-pro (roughly 2× to 3× output speed).
k3 - Flagship model with 1M context support on higher tiers.
k3-256k - The 256K context-capped version of k3.
kimi-for-coding (mapping to K2.7 Code) - Code-specialized 256K context model.
kimi-for-coding-highspeed - High-speed variant of the K2.7 code series.

Quota Consumption Rate Across Models

Different variants draw down the rolling 5-hour quota window at distinct multipliers:

Context Length: A 1M context run of k3 or k3.1-pro consumes roughly twice as much quota per step as its 256K counterpart (k3-256k) due to larger state processing overhead.

High-Speed Variants: High-speed models (k3.1-pro-highspeed, kimi-for-coding-highspeed) draw approximately 2× to 3× the quota rate of their standard counterparts because they provision prioritized compute infrastructure.

Lowering Reasoning Effort and Settings

Thinking Mode Constraint: k3.1-pro models only support thinking mode; requests with thinking explicitly disabled are rejected by the provider API.

Configuring OpenCode (WORK_MODEL): To run the reference job under a constrained quota window, change the runner variable to a smaller context model to prevent 1M-token ballooning:

WORK_MODEL=kimicode/k3-256k (or WORK_MODEL=kimicode/kimi-for-coding)

Estimated Time Bought: Restricting the model to k3-256k with sub-agents disabled reduces per-step token consumption from ~100k down to ~15k-25k tokens, stretching the rolling 5-hour quota to accommodate roughly 45 to 60 minutes of continuous agent execution before hitting rate limits.

1. Moonshot API Tiers Above Starter (Pay-As-You-Go)

To achieve an uninterrupted 60-to-90-minute autonomous agent run (single agent, no parallel helpers, ~2M tokens processed), account limits must support higher throughput than Tier 0 ($1 recharge, 1 RPM, 500k TPM).

Threshold to Unlock: Reaching Tier 2 ($20 cumulative recharge) provides 40 concurrency, 100 RPM, and 3,000,000 TPM (Unlimited TPD), which safely avoids HTTP 429 rate limits for a heavy single-agent loop.

Current Kimi Coding Model Pricing (Pay-As-You-Go):

Kimi K3.1 Pro: Input: $2.00 / 1M (Cache hit: $0.20), Output: $10.00 / 1M, Context: 1M.
Kimi K3.1 Pro HighSpeed: Input: $4.00 / 1M (Cache hit: $0.20), Output: $20.00 / 1M, Context: 1M.
Kimi K3: Input: $3.00 / 1M (Cache hit: $0.30), Output: $15.00 / 1M, Context: 1M.
Kimi K2.7 Code / K2.6: Input: $0.95 / 1M (Cache hit: $0.19 / $0.16), Output: $4.00 / 1M, Context: 256K. (Note: K2 series was closed to new API registrations on October 31, 2026, but remains operational for existing accounts until December 31, 2026).

2. Third-Party Hosts (OpenRouter & Others)

OpenRouter Pricing:

moonshotai/kimi-k3.1-pro: ~$0.2375 input / $8.411 per 1M tokens (varies dynamically with provider routing).
moonshotai/kimi-k3: ~$0.1824 input / $11.01 per 1M tokens.

Context & Limits: OpenRouter passes through the full 1M context window for K3 and K3.1 Pro, though rate limits depend on user credit tiers (typically 200-500 RPM).

OpenCode Compatibility: OpenCode has a built-in OpenRouter provider configuration and natively supports custom OpenAI-compatible endpoints, making this a frictionless drop-in via standard API keys.

3. Higher Kimi Code Plan Tiers

Subscription tiers for Kimi Code range from the entry Plus plan up to enterprise levels:

Plus: ¥99/month (~$14 USD) - Includes Kimi Code access (k3.1-pro, k3, 256K context limits).
Pro: ¥199/month (~$28 USD) - Unlocks up to 1M context and Highspeed model variants.
Max: ¥699/month (~$98 USD) - Higher agent task concurrency.
Ultra: ¥1,399/month (~$196 USD) - Includes 28× agent credits and 4 parallel agent tasks.

Quota Scaling: Higher tiers scale monthly credits and concurrency linearly; however, the rolling 5-hour rate-window enforcement persists across all tiers unless utilizing enterprise custom SLAs.

4. Ways to Make a Run Fit a Quota or Budget

Disable Sub-Agents: Prevents background helper agents from multiplying token usage from ~200k to over 2M tokens per task.

Context Compaction / Limits: Explicitly clamp context_window to 250000 in OpenCode config to prevent runaway history bloat.

Prompt Caching: Moonshot API automatically caches stable file prefixes, slashing input costs down to $0.20-$0.30 per 1M tokens on cache hits. Ensure harness system prompts remain static to maximize cache efficiency.

5. Recent Changes (As of November 2026)

Model Releases: Kimi K3.1 Pro and K3.1 Pro Highspeed launched in late October 2026.

Retirements: The older moonshot-v1 family and K2.5 were officially retired on August 31, 2026 (returning HTTP 404). K2.6 and K2.7 Code were closed to new direct API signups on October 31, 2026, though legacy accounts retain access until December 31, 2026.

Plan Restructuring: New Kimi membership plans (Go, Plus, Pro, Max, Ultra) eliminated weekly limits, retaining only the rolling 5-hour rate window.

Route Ranking (Best to Worst)

Route A: Moonshot Pay-As-You-Go API (Tier 2+, k3.1-pro, 250k context cap) - Best balance of cost and reliability. Billed per token with prompt caching ($0.20/1M hit). Fits a 90-minute run cleanly without subscription quota walls. Estimated cost for 2M tokens (~1.8M cached input, 200k output): ~$2.50 to $4.00 per run. Sources: [suspicious link removed], Puter Kimi Pricing.

Route B: OpenRouter (moonshotai/kimi-k3.1-pro) - Eliminates direct platform sign-up friction; uses standard OpenAI-compatible keys. Estimated cost: ~$3.00 to $5.00 per run. Source: OpenRouter Pricing.

Route C: Kimi Code Subscription (Pro Tier, ¥199/mo, clamped to k3-256k) - Uses existing subscription infrastructure, but prone to rolling 5-hour window throttling on long runs unless context is strictly managed. Source: Kimi Code Plans.

The ONE Pick & One-Job Trial Plan

The Pick: Route A (Moonshot Pay-As-You-Go API) using model k3.1-pro with strict context truncation.

Trial Plan Settings (WORK_MODEL & Environment):

WORK_MODEL=moonshot/k3.1-pro

CONTEXT_LIMIT=250000

SUB_AGENTS_ENABLED=false

Job to Run: Reference job (Godot rules change, ~30 files, 2-page brief).

Success Criteria: Completes execution within 60-90 minutes, generates a valid pull request passing all automated checks, and stays under 2.5M total tokens.

What Could Not Be Verified

Exact minute-by-minute internal scheduler prioritization algorithms for the 5-hour rolling window on the Kimi Code subscription remain opaque beyond vendor documentation stating that high-speed and 1M-context models consume quota at roughly double the rate of baseline configurations.
