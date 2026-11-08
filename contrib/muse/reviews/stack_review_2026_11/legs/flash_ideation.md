# Flash ideation leg - AI stack review, Nov 7, 2026

- Chair header: this leg ran in the IDEATION seat (Gemini 3.8 Flash; Argon is blocked since the Google AI Pro lapse on Nov 5, 2026). Per the seat rules, its claims are leads and challenges, NOT evidence; nothing in it is adopted unless the chair verifies it against the pack or a primary source.
- Chat: https://gemini.google.com/app/514f91bbe0dfbc8a
- Gates (confirmed by the runner): prompt bar read "Flash" before sending and after generation; picker entry "3.8 Flash"; no Pro or Argon entry selected.
- Filed verbatim below (dash-normalized by the chair).

---

1. Three Strongest Challenges to the Chair's Lean

Challenge 1: Committing to a $39/mo Kimi subscription when pay-as-you-go API is mathematically superior for a trial.
The chair leans toward buying a $39/mo Kimi Code Pro membership key to run inside OpenCode. However, Kimi K3.1 Pro API list prices are $2/1M input ($0.20 cached) and $10/1M output, with an estimated Artificial Analysis task cost of ~$3.68/task. Spending $39 upfront on a subscription pool-which has an unstated token cap, no rollover, and a risk of pay-as-you-go overflow charges anyway-violates Ryan's core cost discipline: "vendor figures are unmeasured until a real transaction logs them; pacing assumptions are not required costs". At pay-as-you-go rates, $39 buys ~19.5M uncached input tokens or roughly 10 full benchmark tasks. If Kimi struggles with Godot 4.7/GDScript during the initial trial jobs, a $39 subscription fee is completely sunk, whereas direct API billing via OpenCode stops the moment a run fails.

Challenge 2: The "Harness Tax" and Godot blind spot in OpenCode.
The chair assumes OpenCode is a neutral pipe driving Kimi and DeepSeek. Yet the pack's strongest empirical harness study (arXiv 2610.04433) reveals two critical vulnerabilities:

1. OpenCode trailed dedicated environments by up to 9 points on large-pool SWE-bench Verified tasks.
2. Cost-per-task differed by up to 3x across harnesses purely due to context overhead per step.
Because the pack explicitly notes that no Godot/GDScript-specific harness or model benchmark exists, routing an unproven model (Kimi K3.1 Pro) through a multi-provider wrapper (OpenCode) on Windows 11 PowerShell compounds two unmeasured variables at once. If OpenCode inflates context overhead by 3x, it will burn through Kimi's monthly pool or DeepSeek's token balance three times faster than expected, while potentially degrading Godot execution quality.

Challenge 3: Keeping the $100 Claude Max seat preserves the exact single-point-of-failure that caused the stall.
The chair defends the $100 Max seat on the premise that Opus must own the board and settlement queue to avoid reviewer bottlenecks. But the pack notes that Opus hit its Max weekly cap specifically when it was forced to double-hat as both orchestrator and local coder when Codex dropped. If a workhorse seat is successfully restored on the PC (handling execution, engine runs, and diff generation), Opus is relegated purely to review-by-diff and board orchestration. Reviewing diffs consumes vastly fewer tokens than agentic iterative coding. Paying $100/mo ($80 premium over Pro) indefinitely out of fear of a cap that only occurred during an emergency double-shift locks Ryan into $140-$179/mo in software subscriptions for a hobby project, without empirically testing whether Claude Pro ($20) plus a disciplined workhorse can clear the queue.

2. Two Alternative Configurations Not Proposed by the Chair
Alternative A: The Pure Pay-As-You-Go "Zero-Subscription Workhorse"

Instead of stacking another recurring monthly fixed cost ($39 Kimi Pro) on top of Claude Max ($100), eliminate the workhorse subscription entirely and use pure meter billing.

Harness: OpenCode (Free, MIT, local headless on Windows).

Primary Workhorse: DeepSeek V4.1 Flash via direct API ($0.30 / $1.20 per 1M tokens peak; half off-peak) for bulk, boilerplate, and initial implementation passes.

Escalation Workhorse: DeepSeek V4 Pro ($1.32 / $3.96 peak) or Kimi K3.1 Pro direct API ($2 / $10) invoked only when Flash fails or when long-horizon context (>100k) is strictly required.

Review/Orchestration: Claude Max ($100/mo) kept temporarily through the November queue.

Monthly Cost: ~$105 - $120/mo ($100 Claude Max + ~$5-$20 real usage across DeepSeek/Kimi API).

Strategic Rationale: DeepSeek V4.1 Flash scores 77.0 on DeepSWE (higher than K3.1 Pro at 75.5 and Opus at 74.2) at an estimated cost of ~$0.60/task (a solo-dev month can run as low as $3.60 to $7.95). This satisfies Ryan's mandate that costs must be logged by real transactions rather than upfront vendor commitments.

Alternative B: The Native Windows / Pure Claude Code Consolidation

Eliminate third-party harness friction and harness licensing mismatch entirely by using the seats Ryan already pays for or free native tooling.

Harness: Claude Code (native binary driving local PowerShell/Godot) OR Crush by Charm (native Windows/PowerShell ergonomics) paired with T3 Code (free MIT local supervision, worktree isolation, one-click PR).

Workhorse Configuration: Drive Claude Code directly using the existing $100 Claude Max entitlement. Anthropic allows Max/Pro usage inside genuine Claude Code. With Codex down, stop searching for an immediate external workhorse and test whether Claude Code running locally with T3 Code supervision can execute jobs directly without hitting the cap, not split across disconnected chat/board seats.

Secondary / Sanity Checker: DeepSeek V4.1 Flash via pay-as-you-go API in Crush/T3 Code.

Monthly Cost: $100 - $105/mo ($100 Claude Max + minor API pennies; drops to $20 - $25/mo if downgraded to Pro once Codex returns or if Claude Code efficiency proves sufficient).

Strategic Rationale: Avoids introducing new subscription vendors (Moonshot) or complex multi-provider harness bugs. Solves Ryan's preference for double-click simplicity and avoids terminal friction on Windows 11.

3. Critical Questions Ryan Should Ask Before Spending Anything

Why buy a $39 Kimi Code Pro subscription before running a $0.50 test on Kimi's direct API?
Since OpenCode supports standard API keys alongside Kimi subscription keys, why commit to a monthly subscription pool with opaque token limits and rolling 5-hour throttles before spending $2.00 on pay-as-you-go API tokens to see if Kimi K3.1 Pro can even parse Voidsworn's Godot 4.7 GDScript repository?

Does OpenCode actually run headless and error-free in Windows 11 PowerShell without manual terminal intervention?
Ryan requires zero terminal babysitting and double-click simplicity. Has OpenCode v2's headless/server mode been verified to launch Godot builds, run capture scripts, and handle Git worktrees natively on Windows without stalling on execution-policy or environment-path traps? If not, is Crush or T3 Code actually the necessary operational baseline?

What is the true cost of an Opus PR review failure?
If a fire-and-forget workhorse pushes a branch that compiles but contains subtle GDScript gameplay bugs or architectural drift, how many Opus review-and-rejection cycles does it take to exhaust the Claude Max allowance? If a cheaper model generates high diff churn, does the "cheap" workhorse actually end up burning the expensive reviewer seat?

When Codex returns (post-reset or fix), what happens to this stack?
Codex is down temporarily as of Nov 6, and ChatGPT Plus ($20) resets around Nov 10. If ChatGPT/Codex returns to service in days, will Ryan be stuck paying for an unneeded Kimi Pro monthly seat alongside a restored Codex seat?
