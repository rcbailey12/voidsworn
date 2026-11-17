# Issue 880: root causes of the Nov 16 misses and the global fixes

Owner ruling behind this job (R291, Ryan, Nov 16 2026): "I don't want to overly respond to one time issues with patch, I want to address the core underlying issue so it doesn't happen for future threads or work streams. Global fixes."

## Council

Blind Rey leg first, then DeepSeek (DeepThink on, Search off, verified both ends), Qwen (Qwen3.8-Max, selector switched from Qwen3.7-Plus before sending, header verified after), Grok (Fast, verified), ChatGPT (chat only, GPT-6 at High, verified both ends). Rey chairs. The Flash seat did not run: the first attempt's after-reading showed the picker on a different model than the gate requires, so its answer is unverified and not counted; the signed-in re-run stopped at a Google verification step only Ryan can complete, and Ryan directed the chair to proceed without it. No substitution was made.

Verdict: the four lessons stand as ruled (R281, R288, and the two picture lessons from R289). Every leg agreed on the causes below. Two leg proposals were not adopted and are recorded under Dissents.

## Root causes and the adopted global fix, per miss

1. **Merged issues re-queued (780, 781, 783, 824).** Cause: issue state and merge state are separate records, and by design (RULEBOOK 2.5) a merge never closes an issue, so "open" carries no information about done. Queueing read the open list alone. Fix adopted: the same-step close in R288 (close on merge when scope is done; say what remains when a merge is partial), a merged-PR search before any queueing or relabelling, and the dot's dispatch sweep as the audit that catches what the mechanism misses. The sweep is detection, not the mechanism (ChatGPT, Qwen). Scope guard (ChatGPT, adopted): a PR naming an issue does not always complete it, so closure turns on scope done, not on a PR existing.
2. **Run briefs in comments (373 run 3).** Cause: two instruction channels, one executor that reads only one of them, and nothing validates which channel holds the live brief. Fix adopted: one current instruction at the top of the issue body (R281); the runner-side end state the council named is a validated current-brief block the runner refuses to start without (DeepSeek, Qwen), which is a runner change for the Board to file, not a new rule here.
3. **Stale or unlabelled pictures (the A20 slope picture).** Cause: a picture carries no provenance: nothing on the file ties it to a revision or a stage, so any render can be shown as current. Fix adopted: the label rule lands now (revision and stage on every picture shown to Ryan; a stale picture stops the review, Qwen's cross-reference). The structural half is provenance at generation (commit and stage stamped by the tool that renders the file: DeepSeek's manifest, Qwen's stamp, ChatGPT's caption), already a run instruction in 726; it is the tool change that makes the rule cheap to keep.
4. **Visual work passing countable checks while missing the ruling (the painted ships).** Cause: the acceptance path measures countable proxies (fit, weapon match, triangles, density) and the look is judged only when Ryan sees a picture, late. The patchwork rule existed in prose and no measure or comparison stood between the stack and Ryan's eye. Fix adopted: a visual PR merges only after a comparison against the concept and the ruling it answers, recorded in the PR with the misses stated plainly, in a view that actually shows the feature being judged (ChatGPT; a correctly labelled picture can still hide a feature at the wrong camera, as the A20 cheek did). What a ruling can measure is measured on the painted output and reported: the plate-character measure in 875, kept reported, not gated.
5. **Runner fragility (held files, mirror locks, disk).** Cause: the runner assumes a clean machine: no wait on a held file, no coordination between lanes, no bound on kept checkouts, and reporting that can certify a partial run (873). Every incident was that assumption failing a different way. Fix: the runner's own contract, already filed: wait and retry on a held file (882), truthful failure reporting (873), the kept-checkout cap. No rulebook rule beyond the pointer in LOOP "The seats"; a generic instruction to be careful would accomplish nothing (ChatGPT).
6. **Dispatch overlap (872 run by two seats).** Cause: two queues read the same board and the owner label is a convention no tool enforces, so two seats can legitimately start the same job; the collision surfaced only at push time, after both had done the work. Fix adopted in the documents now: claim before running (the running label and status comment of RULEBOOK 2.4, set before work starts, by every seat), and a seat that finds a job claimed or its delivery branch existing does not run it. The council's stronger forms (an atomic lease checked by every dispatcher: DeepSeek, ChatGPT; the runner reading the owner label at fetch: Qwen) are the tooling end state for the Board to file.

## One-off patches, and what retires them

- The 5 and 10 minute gaps between chained jobs: retire when 882 (wait and retry) and lane coordination land. Contention-aware retry replaces fixed spacing (ChatGPT); the gaps are timing superstition until then.
- Hand stops of chain windows: retired by the claim rule and dispatch-time reconciliation (a queued job whose issue completed or is claimed by another seat cancels, not runs).
- STOP edits in the bodies of closed issues 783 and 781: retired by close-on-merge (R288) plus runners refusing closed or claimed issues.
- The hand-run disk cleanup: retired by the kept-checkout cap with automatic pruning.
- Per-incident log notes as the corrective mechanism: retired by truthful reporting (873) and structured job outcomes. Diagnostic logs stay; relying on a human reading them as the fix goes (ChatGPT).

## Dissents recorded, not adopted

- DeepSeek: change RULEBOOK 2.5 itself (closing keywords or automatic closure on any Refs) because a search-before-queueing rule still depends on memory. Not adopted here: 2.5 exists because a commit once closed PR 320 by accident, and R288 as ruled keeps Refs. The same-step close plus the sweep covers the failure without touching the convention. Referred to Ryan and the Board as the open question if re-queues recur.
- Grok: make the plate-character measure a required gate. Not adopted: the Board settled 875 as reported, not gated, and R291 bars new gates beyond what the causes need; a gated aesthetic metric invites gaming the metric.

## What landed in this delivery

- docs/RULEBOOK.md 2.4: the one-current-instruction rule (R281) and the open-is-not-undone rule (R288), each with its reason.
- docs/RULEBOOK.md 2.3 (the review section): picture labels (revision and stage; stale stops the review) and the visual comparison rule, with the 875 measure named as reported.
- AGENTS.md, the job board section: the same two rules in short form, plus claim-before-you-run.
- contrib/opus/LOOP.md "The seats": a Dispatch bullet (the claim, the dot's sweep as standing job, the runner contract pointer, and which patches retire).
- docs/playbooks/PROGRAM.md, "How every item flows": the four standing rules in one short paragraph.
