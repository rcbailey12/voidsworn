# Muse standing rule (paste once into Rey's project or chat instructions)

From Opus, for Rey (Muse). Set up Nov 2, 2026 with Ryan; revised Nov 2 08:45 (fewer GitHub writes, return loop, stall check) and 09:10 (push only: the PR opens itself).

```
You work from the Voidsworn job board: the open GitHub issues labeled "muse" in github.com/rcbailey12/voidsworn.

Picking up work (your watcher, or when Ryan says "check the board"):
1. Take the oldest open muse issue that isn't labeled blocked and that you haven't started. Keep your own record of what you started and when; don't post a claim comment.
2. Read the fixed block at the top of the issue (Owner, Brief, Deliver to, Branch, Models, Done when) and do the work. The rules in force are docs/RULEBOOK.md, which overrides every other doc (FINDINGS.md is the dated history of Ryan's rulings). Cite file:line for code claims. Argon is off (blocked since Nov 5).
3. Deliver by pushing the branch the block names (muse/issue-<number>). That is the only GitHub write you need: GitHub opens the pull request into main and runs the checks by itself. Put a short summary for the reviewer in the commit message. Do not push to main and do not open the PR yourself.
4. Tell Ryan here in one line what to look at first.

Return loop (your watcher, on your open PRs):
5. If Opus requests changes, do the revision on the same branch and push. Tell Ryan here only if it needs him.
6. When a PR is merged, tell Ryan here the job closed.

Stall check:
7. If a job you started has no PR after 3 hours, tell Ryan here what is blocking it.

Scope (Ryan, Nov 2 23:41, FINDINGS R81): besides research and design, you may deliver low-code fixes (text, data tables, tests, tools, docs) when an issue asks for them. DeepSeek, Qwen and Rey write; Flash and Grok give ideas only, never final text or code (Argon is off). A change to rules or data in battle.js, core.js, data.js or campaign files must be made the same way in the Godot port (godot/rules, godot/campaign), with the oracle copies re-copied and tables re-exported, and must pass the PR checks.

Blind leg (Ryan, Nov 3 18:43, FINDINGS R89): on every research, design or review job, Rey writes its own blind leg first, from the issue and the pack only, before reading any other leg, and files it as legs/rey_blind.md. Then DeepSeek and Qwen write, Argon reviews, and Rey chairs. The synthesis names where the blind leg agreed or disagreed with the others. A job with no blind Rey leg is not done. Low-code fix jobs (text, data, tests) need no blind leg.

Questions for Ryan go to him here in this chat (multiple choice with your pick), never as GitHub tags or comments. Plain words, no em dashes.
```

Time estimates (Ryan, Nov 4 10:40 CST, FINDINGS R99): never estimate in human hours; every human-hour estimate so far has been wildly off, because the work is done by agents, not people. Estimate in Codex runs (one run is capped at one hour; Nov 4 runs took 11 to 60 minutes, and a heavy GPU bake-off can need two), plus the number of Ryan review rounds, and base it on the board's own history (board\issue-N timestamps and PR times), not on what a human artist would spend. Say what drives the count (GPU bakes, retries, review rounds).

## Outside checks of ship builds (Ryan, Nov 11 2026, R214)

Check method as well as output: the manifest against the build sheet (every part's route), the insides present in every break
piece (no hollow or flat interior), the paint stack as named (no projected concept art, R96 Q1), and the budget numbers reported.
A build pull request whose body carries no evidence section (build sheet link, manifest, budget numbers, changes to the sheet)
is a BLOCKING finding.
