# Research pack: running Kimi as a coding worker (Voidsworn issue 653)

You are one leg of a research council. Answer from primary sources (the providers' own pricing, docs and limits pages) wherever you can, date every number, link every claim, and say plainly where a source is missing or two sources disagree. Do not invent prices, quotas or model ids. Where you estimate, show the arithmetic and label it an estimate.

## The job

A game project runs AI coding workers through OpenCode on the owner's Windows PC. Workers take a written brief (an issue), work a branch for 60 to 90 minutes, run the project's checks, and push a pull request. The current cheap workhorse is a competitor model that finished the reference job (below) in 49 minutes of agent time for a few cents of API spend. The owner wants Kimi in that seat if a workable route exists. Your leg ranks the real ways to run Kimi (its current best coding model) as that worker, and ends with ONE pick and a one-job trial plan.

## What was already tried (the project's own trial record; treat as given fact)

Moonshot pay-as-you-go API, starter tier, model K3.1 Pro (trials in November 2026):
- Two starts refused by rate limits; a third hit a one-hour run cap; no merge.
- On a harder head-to-head job: no pull request produced. Its code showed better judgment in places than the workhorse's.
- The owner noted the subscription tier had never been tried; that is what happened next.

Kimi Code plan (the subscription; owner's tier costs $19 a month; key saved on the PC; OpenCode provider arm named kimicode):
- A keycheck listed the models the plan serves: kimi-for-coding, kimi-for-coding-highspeed, k3-256k, k3.1-pro-highspeed, k3, k3.1-pro. The arm's default model is kimicode/k3.1-pro; a later setting pointed it at kimicode/k3.
- Trial 1, a code review job: hit the plan's 5-hour limit in 9 minutes. Cause found afterwards: the run started five parallel helper agents (the top level alone used about 240k tokens). Fix applied: the arm's config disables sub-agent tasks.
- A run on the reference job with the context limit unset failed with HTTP 403: the plan caps k3.1-pro at 256K context and the harness never compacted (1.15M tokens over 10 steps, 43 file reads). Fix applied: context limit 250000 set on both kimicode models.
- Next run on the reference job (Nov 12): hit the 5-hour limit again in about 21 steps and roughly 2M tokens.
- Nov 13 run on the reference job, model k3: hit the plan's 5-hour quota after 27.5 minutes of agent work, partial, no pull request. The Board's conclusion: the $19 plan carries short reviews only, about 30 minutes per 5 hours.
- The plan's quota is a rolling 5-hour window plus a monthly total, shared across the owner's clients and devices.

Reference job (the comparison bar): a mid-size rules change in a Godot project: new behaviour in 2 or 3 scripts, edits across about 30 files, automated checks and a parity run, brief length about 2 pages. The competitor workhorse finished it in 49 minutes for a few cents. A Kimi trial that replaces it must finish the same job inside one quota window or one paid run, and beat or match it on checks and diff quality.

## Questions (answer all; question 6 first)

6. FIRST PRIORITY: the other models and settings on the access already owned (the Kimi Code plan above). Which models does the plan serve (faster or non-thinking variants, preview or older models, highspeed variants, the 256K variant)? Does each model draw the 5-hour quota at a different rate (for example a 1M-context variant costing more quota than its 256K variant, or a highspeed variant costing more)? Can thinking or reasoning effort be lowered through OpenCode or the provider's parameters, and how much agent time would that buy per 5 hours? Give the exact model ids and settings (the runner sets one variable, WORK_MODEL, to a provider/model id) so a trial can run the reference job on the same brief with a different model or setting.

1. Moonshot's own API tiers above the starter: what tier unlocks enough rate and concurrency for one long agent run (60 to 90 minutes, one agent, no parallel helpers), and what does it take to reach it (cumulative recharge thresholds)? Name the per-token prices of the current Kimi coding models on that API, with context sizes and cache pricing.

2. Third-party hosts serving Kimi models through an OpenAI-compatible API (OpenRouter and the providers behind it, plus any others you find): price per million tokens in and out, context size, any rate limits that matter for one agent, and whether OpenCode can use them (OpenCode has a built-in OpenRouter provider and supports custom OpenAI-compatible providers).

3. Higher Kimi Code plan tiers, if any: price, and their quotas expressed against the $19 tier (multiples are acceptable if that is all the vendor states).

4. Ways to make a run fit a quota or a budget: smaller job slices, prompt caching (what does the vendor charge for cache hits, and does the plan/API support it), using a cheaper Kimi model for reading and the flagship for writing, disabling sub-agents, lowering reasoning effort.

5. Anything that changed since Nov 12, 2026: new models, renamed plans, retirements (note any announced retirement of the older K2 API models and what it means for a new API account).

## Numbers discipline

- Mark every price, quota and limit with its source (a link) and the date you read it.
- Vendor-stated figures are vendor-stated until a real run measures them; say so.
- For each route, estimate the cost or quota use of ONE reference job (60 to 90 minutes of agent work). Show the token assumptions you used (the trial record above gives real token counts: about 2M tokens for 21 steps of this work) and label the result an estimate.
- If two sources disagree (for example on a tier's concurrency), report both and say which you trust and why.

## Your deliverable

A ranked list of the real routes (best first), each with: route name, what it costs, limits and context, whether one reference job fits, source links with dates. Then your ONE pick and a one-job trial plan (model id and settings exactly as the runner would set them, the job to run, what success looks like). Then a short section: what you could not verify.
