## Q1. Workhorse configuration

**Pick: OpenCode on the PC, Kimi Code Pro key ($39/mo) as the primary model, DeepSeek API direct pay-as-you-go as the second model.**

Reasoning from the pack:

- The vacancy is a local execution seat. Only a local agent can run the game, the build, and captures, which eliminates every cloud-agent option and every editor-first IDE subscription (Cursor, Windsurf/Devin Desktop, Copilot) whose centre of gravity is either a human in an editor or a remote machine. Ryan does not sit in an editor; he judges PRs.
- OpenCode is the only candidate that is simultaneously MIT open source, actively shipped (v2, fall 2026), Windows-native across desktop, TUI, and IDE surfaces, multi-provider (75+), and equipped with headless and server modes for programmatic dispatch. Those last two are what the R75 board pattern needs: a job goes in as an issue block, a branch and PR come out.
- Kimi Code Pro is the right primary inside it. K3.1 Pro is the top open-weight model on the independent index (55, one point behind Sonnet), leads SWE Marathon on the vendor table, ties DeepSWE, carries 1M context at Pro tier, and its specialization is long-horizon endurance, which is the shape of board jobs. Decisively, new plans have no weekly limit, only a rolling 5-hour limit plus a monthly pool with pay-as-you-go overflow. The failure mode becomes a meter, never a stall. Both of Ryan's November outages were weekly walls; this plan has none.
- The subscription key is officially usable inside OpenCode through its built-in "Kimi For Coding" provider, so the $39 buys model allowance, not lock-in to Moonshot's CLI. Kimi's own CLI is rejected as the seat for exactly one reason: it is a Kimi-only harness, so the cheap second model would need a second harness and a second workflow.
- DeepSeek direct is the overflow and bulk route: V4 Pro at $1.32/$3.96 peak (half off-peak) and V4.1 Flash at $0.30/$1.20 are an order of magnitude cheaper per task than everything else in the pack (about $1.77 and $0.60 per task against Kimi's $3.68 pay-as-you-go anchor). It lives in the same OpenCode install as a second provider, so switching models per job costs nothing. Going direct avoids OpenRouter's 5.5% credit fee; OpenRouter stays a fallback, not the default path.
- Explicitly avoided inside this pick: OpenCode Go ($10/$40), whose per-model weekly windows recreate the exact failure being engineered away, and OpenCode Zen only as a convenience top-up route, not a plan.

**Strongest argument against this pick:** the harness evidence cuts against it in the only place the evidence rises above noise. The best study found score differences between harnesses mostly within rerun noise, with one above-noise effect: OpenCode trailing up to 9 points on the large task pool, and cost per task varying up to 3x between harnesses on context overhead alone. A second measurement showed one open model scoring 23% versus 52% purely across harnesses, so harness-model fit for open models is a real variable, and Kimi-inside-OpenCode fit has never been measured. There is no Godot or GDScript benchmark for any of this. It is therefore possible that Kimi in its own CLI is materially better or cheaper per accepted PR than Kimi in OpenCode, and the pack contains nothing that rules that out. The trial in Q3 is not a formality; it is the only evidence that will ever exist for this pairing.

## Q2. Claude Max: keep $100

**Keep Max at $100 through the settlement queue. Downgrade to $20 Pro is rejected for now.**

Deciding factor: the reviewer is the board's single point of failure, and its allowance is the one resource every other seat queues behind. The pack's one observed cap event is Opus stalling on Max itself during the Nov 5 sprint week while double-hatted, and the consequence was not a slower week, it was a stalled board that Rey had to pick up without a local environment. Pro is roughly a fifth of the Max 5x allowance. The current queue is the heaviest orchestration load on record: five audit settlement programs, a benchmark, and a build comparison, all landing on the seat that also reviews every workhorse PR. Cutting that seat's allowance to a fifth, in the same month a new unproven workhorse starts generating PRs for it to review, stacks the two risks so they fail together.

The counter-case is real but mistimed: $80/mo is a lot to pay for headroom in a quiet month, and if the workhorse absorbs generation volume, Opus's remaining load is review and judgment, which may genuinely fit Pro later. That is an argument for revisiting the downgrade when the queue drains and Codex returns, with the trial's measured review burden as the input. It is not an argument for downgrading before those numbers exist.

## Q3. Sequence and trial design

**The chair's sequence is right in its ordering, and I would keep it unchanged:** Kimi trial now, Muse free test on its already-scheduled Nov 26/27 track (it is independent of this decision and should not be moved), Claude downgrade last and only on evidence. Each step produces the measurement the next step needs, and no step spends money to save money before the saving is proven.

**Trial job design.** The job must be typical of the codex queue, not a toy, because a toy cannot measure review burden or endurance. Specification:

- One bounded job in the real game repo, written as a standard R75 issue block (Owner, Brief, Deliver to, Branch, Models, Done when), with a fixed branch and a verifiable Done-when.
- Multi-file scope: a self-contained feature or fix touching several GDScript/data files, large enough to require sustained work across the whole job, small enough that a total failure is cheap to discard and rerun.
- It must require local execution as part of Done-when: the agent runs the project or its checks on the PC and the PR carries that evidence. A job that never runs the game does not test the seat's reason for existing.
- Acceptance is by the normal route: workflow checks plus Opus's diff review plus any screenshot or capture the job's Done-when names.

**Measure exactly four things:**

1. **Review burden** (the primary metric): number of Opus review passes and change-request rounds before merge, and whether any fix required a second agent or Ryan's intervention. One clean pass is success; two or more substantive rounds means the seat is generating review debt, not capacity.
2. **Cost actually logged**: the real charge or pool draw for the job, recorded against the pack's anchors (about $3.68/task Kimi pay-as-you-go equivalent). Vendor figures stay unmeasured until this number exists. If the Kimi pool draw per job is visible, extrapolate it to a month of typical board volume; if it is not visible, record that as a finding in itself.
3. **Wall time**: dispatch to open PR, unattended. The seat's value is throughput while Ryan does other things.
4. **Defect count**: workflow/check failures on the PR, plus any post-merge fix attributable to the job within the following week.

Decision rule stated in advance: if the job merges in one review pass at a logged cost near the anchors, the configuration is adopted and a second matched job may be run on DeepSeek V4 Pro through the same harness to price the second route. If review burden is high, the next experiment is the same job class in Kimi's own CLI, because the harness-fit question from Q1 becomes the live suspect.

## Q4. Dispatch architecture

**Endorse the fire-and-forget pattern:** board issue, local headless OpenCode, branch and PR, one Opus review pass. It matches how the board already works with Codex, it keeps every seat's allowance spent on its own job, and it produces exactly the artifact Ryan actually judges.

The in-the-loop alternative is rejected on cost grounds, not taste. A supervisor sitting in the loop (Opus or Rey watching steps and correcting mid-run) spends the reviewer's scarce allowance on babysitting a cheaper model, couples the reviewer's cap to the workhorse's volume, and recreates the double-hat structure that produced the Nov 5 stall. Supervision also does not scale: the seat exists to run while nobody watches.

Two conditions make fire-and-forget safe rather than hopeful:

- **Evidence rides the PR.** Because nobody watched the run, the PR must carry the run's proof: workflow check results, the local execution output the Done-when required, and captures where the job is visual. The reviewer reviews a diff plus evidence, not a diff plus trust.
- **Jobs stay discardable.** Fire-and-forget surfaces defects at review instead of mid-run, so job size is the control: bounded jobs whose total loss is one rerun. Long jobs should be split at the issue stage, not supervised at the run stage.

**On T3 Code:** adopt it later, optionally, and understand what it is. It is free, MIT, adds no caps, and its worktree-per-thread plus one-click PR surface is a genuinely nice observation layer over local agents, OpenCode included. But it supervises interactive threads; it adds no capacity, no dispatch discipline, and nothing the board does not already provide for headless work. It is a window, not a seat. Worth installing when Ryan wants to watch the workhorse work; the architecture does not depend on it either way.

## Q5. Missed risks

1. **The Kimi pool is an unpublished number shared across the whole account.** Moonshot publishes no absolute token count per tier, and the pool is shared across all Kimi features on the account, not reserved for coding. The chair's lean treats $39 as buying a workhorse month; it may buy materially less once non-coding use draws on the same pool, and nobody can know until real jobs log real draws. Falsifiable: the Q3 trial's logged pool draw, extrapolated to typical monthly board volume. If one bounded job consumes a large fraction of the pool, the economics flip toward a pay-as-you-go-first configuration and Kimi drops to the endurance-only route.
2. **Both cheap routes are China-hosted, so the workhorse's failure modes are correlated.** Kimi and DeepSeek are the primary and the overflow. A service outage, a terms change, or a policy shift at either is survivable; the lean assumes they do not move together, and they share a jurisdiction and a regulatory environment. The pack's own constraint (fine for the public repo, never for employer material) is respected, but availability correlation is unpriced. Mitigation is cheap and should be set up before it is needed: an OpenRouter key configured in the same OpenCode install (5.5% on credit purchases, no per-token markup) as a pre-tested third route to the same or substitute models, so a correlated failure is a config change, not a procurement exercise.
3. **The Muse free test lands in the middle of the heaviest chair workload, and its downside is chair quality, not just chair cost.** Rey's measured week containing one four-leg audit already used 32% of the Power weekly allowance. If the Nov 27 check finds the free account serving Muse Spark rather than the rollout Wonder, the chair of every council review, including the settlement syntheses this stack decision feeds, drops a model tier at the exact moment the new workhorse starts producing PRs and trial results to synthesize. Falsifiable on Nov 27 by the scheduled check itself. The lean treats the Muse test as an independent side experiment; it is not independent of this decision's evidence pipeline.

## Recommended stack

- **Orchestrator, coder of record, reviewer, board owner:** Claude Opus on Claude Max, $100/mo, inside Claude Code only (the subscription cannot legally or technically be spent in a third-party harness).
- **Workhorse (the vacant Codex seat):** OpenCode (free, MIT) on the PC; Kimi Code Pro, $39/mo, as primary model via its subscription key; DeepSeek API direct pay-as-you-go as second model (V4 Pro standard jobs, V4.1 Flash bulk).
- **Checker seat:** ChatGPT Plus, $20/mo (returns about Nov 10; Opus covers the seat until then).
- **Chair and personal agent:** Muse Power, $20/mo, paid through Nov 26, with the free-plan test and resubscribe decision proceeding on Nov 27 as already scheduled.
- **Council legs:** Qwen, DeepSeek chat, and Gemini free tiers, unchanged.
- **Optional, later:** T3 Code (free) as a supervision window over the workhorse; OpenRouter key (pay-as-you-go, 5.5% on credit purchases) pre-configured as the third route.

**Total monthly cost: $179/mo plus DeepSeek usage.** Fixed seats are $100 + $39 + $20 + $20 = $179. DeepSeek pay-as-you-go is usage-dependent; the pack's anchors put a typical solo-dev month on the cheapest route in single digits and per-task costs at $0.60 to $1.77, so a realistic planning figure is roughly $185 to $195/mo all-in at board volume, against $140/mo today with the workhorse seat empty.

**Confidence: medium.** The configuration follows from the pack's constraints (local execution, no weekly wall, reviewer protection, terms compliance) with room to spare, but the two load-bearing quantities, Kimi's real pool capacity and Kimi-in-OpenCode harness fit, are unmeasured by anyone, and no Godot-specific benchmark exists to borrow. The one observation that would most change this answer: the trial job's combined result, specifically its Opus review burden and its logged Kimi pool draw. One clean review pass at a pool draw that extrapolates to a comfortable month confirms the whole lean; heavy change-request rounds or a pool draw implying the $39 runs dry mid-month would flip Q1 toward testing Kimi's own CLI and a pay-as-you-go-first routing, and would weaken the case for keeping Max at $100 by raising the review cost the workhorse imposes on it.
