# Voidsworn: rules for any AI agent (Claude or another model)

**The game.** Embers of the Hollow Sun (repo name voidsworn) is a hex fleet-tactics roguelite. The product is the Godot 4 game in
`godot/`, played on Ryan's Windows PC only. Godot is the only rules source: the browser rules files at the repo root are retired, frozen history, and CI checks Godot against its own saved results (RULEBOOK 3.1, R405, Nov 22 2026).
The owner is Ryan. He is not a coder: he judges work by pictures. Faction ids never change; their display names do
(contrib/opus/compute/rename_map_final.md): `voidsworn` = Sunward Crusade, `corsair` = Ashfall Hullbreakers, `ithar` = the
Glasswrights, `deathless` = Eclipse, `chorus` = the Chorus, `hegemony` = Meridian Directorate.

**Read first.**
1. `docs/RULEBOOK.md`: every rule in force, each with its reason. **It wins** over this file and every older doc (its section 0.3
   says which document wins after it). Sections 3.5 to 9 live in four files under `.claude/rules/` (pc-harness, ships,
   godot-battle, godot-ui); they are plain Markdown and part of the rulebook for every seat, not only Claude (issue 1660).
2. HANDOFF.md section 0 and contrib/opus/LOOP.md ("The seats", the LATEST lines): what is running now. They win for status only.
3. The playbook for your area: `docs/playbooks/` (PROGRAM.md first).
4. contrib/opus/FINDINGS.md is the dated history of rulings, not the live source. Anything under `docs/archive/` is history:
   never follow it.

Auditing from outside? Follow `docs/REVIEW_PROTOCOL.md` exactly (RULEBOOK 2.11) and the brief in your issue.
Artoo (Ryan's ChatGPT dot) reviews on its own, technical problems only, each comment marked "Artoo (technical review):"
and naming the commit it read; general sweeps go on issue 906 (RULEBOOK 2.7, R295).

## The job board (Ryan, Nov 2 2026; RULEBOOK 2.4)

- Every job is an open GitHub issue: https://github.com/rcbailey12/voidsworn/issues. The label says who has it: `codex` (Codex on
  Ryan's PC), `muse` (Rey and its models), `opus` (Claude), `ryan` (waiting on Ryan), plus `neon` (Neon, R363) and `blocked`. Who does which kind of
  work is RULEBOOK 2.6; which seats are live today is LOOP.md "The seats".
- Agents deliver by pushing a branch named `codex/issue-<number>`, `muse/issue-<number>`, `work/issue-<number>` (or
  `work/issue-<number>-<arm>`), `opus/issue-<number>` or `neon/issue-<number>` (Neon, R363). Any other one-level `muse/<name>` branch also gets a pull request (Nov 17 audit);
  Muse names a scratch branch `muse/wip-<name>` to keep it out. Never push to main (R75); the only exception is LOOP.md and
  FINDINGS.md, which the Board commits straight to main (R102).
- The push makes GitHub open the pull request by itself (.github/workflows/auto_pr.yml, for those branch shapes) and run the
  checks once (.github/workflows/checks.yml: standing checks, no em dashes in changed files, Godot rules parity, Godot game
  checks; a docs-only push skips the Godot jobs, "All checks" is the one mark to read, a conflict with main fails, RULEBOOK
  12.3, R386). A branch with any other name gets no automatic checks: open its pull request by hand, then start them by hand
  (Actions tab, "checks", "Run workflow"; or `gh workflow run checks.yml --ref <branch>`). The Board reviews and merges;
  nobody merges their own pull request (RULEBOOK 2.2).
- Codex runs locally on the PC only, in up to six lanes, with C to F code only (RULEBOOK 2.7, issue 2057). Cloud tasks cannot
  pin the model (R268). The Board launches each Codex job itself through the PC queue (LOOP.md "The seats" says how), and
  every `codex` issue also carries `blocked`, so the old board watcher (tools/pc/codex_board.bat)
  cannot run it a second time.
- Every issue opens with this fixed block, so any agent can pick it up without asking:
  ```
  Owner: codex | muse | opus
  Brief: <path to the brief, or "below">
  Deliver to: <folder or files>
  Branch: <agent>/issue-<number>
  Base: <branch>
  Effort (Codex): high | xhigh   or   Models (Muse): <set>
  Done when: <the check that proves it, and what Ryan will see>
  ```
  Muse's Models line for research, design and review jobs: Rey writes a blind leg first, DeepSeek, Qwen, Grok and Flash each
  write a leg, Rey chairs (R89, R231, RULEBOOK 2.8). Muse's standing instructions: `contrib/opus/briefs/muse_standing_rule.md`.
- Use the optional Base line for an earlier branch the job needs. The runner merges `origin/<branch>` and commits the
  merge before the agent starts; a conflict stops the run with the checkout kept. Briefs never ask the agent to merge.
  The PC runners set the running label and one status comment per job branch, edit it on retries and at the end, and
  clear the label at the end. GitHub reporting failures are logged and never fail the job (RULEBOOK 2.4, issue 846).
- Ship concept and build issues carry an "Approved pick:" line copied from the fleet list (docs/ship_pipeline/FLEET.md;
  `node contrib/opus/tools/fleet_list.js --pick "faction|Class"`), so no brief goes out without Ryan's earlier pick (issue 1421).
- Ship build issues add four lines to the block (Ryan, Nov 11 2026, R214; template in docs/playbooks/ships.md section 7):
  Route per part, Inside, Paint stack, Budget. Every build pull request body carries its done-when evidence and a method line
  (build sheet link, manifest, budget numbers, changes made to the sheet); the outside check (issue 256) returns a build PR
  without them as BLOCKING (RULEBOOK 5.14).
- One current instruction per job: the current run brief sits at the top of the issue body under the fixed block, older
  runs marked done. The PC runner reads the body only; a brief in a comment never reaches the worker (R281, RULEBOOK 2.4).
- Before queueing or relabelling an issue, check for a merged pull request that names it; issues stay open after merges
  here, so open is not proof of undone work. Close an issue in the same step as its merge when its scope is done
  (R288, RULEBOOK 2.4).
- Claim before you run: a seat starting a job sets the running label and its status comment first (RULEBOOK 2.4). If a
  job is already claimed, or its delivery branch already exists, do not run it; tell the Board. Two seats ran issue 872
  on the same morning because nothing enforced the owner label.
- **A ruling lands with its document.** A ruling that changes a working method is not landed until the same pull request edits
  the rulebook or the working document a worker reads for that area (the playbook, RECIPE.md, this file) (R214, RULEBOOK 0.2).
  Its FINDINGS row says "landed in <repo path>" or "one-off job decision"; the memory lint fails it otherwise (R291).
- Commits say "Refs #N", never a GitHub closing word before an issue number; use `gh api` REST, never GraphQL (RULEBOOK 2.5).

## Agent skills (issue 1658)

Skills for every seat live in `.agents/skills/` (copied to `.claude/skills/` by `node contrib/opus/tools/sync_skills.js`);
read `.agents/skills/README.md` first, its house notes win over the skill text. Issue tracker: `docs/agents/issue-tracker.md`.
Domain words: `GLOSSARY.md`; decisions are RULEBOOK rules and FINDINGS rows, never ADRs (`docs/agents/domain.md`).

## If you are not the main agent: work in your own folder (RULEBOOK 2.12)

- Put everything you make in `contrib/<your-agent-name>/`. Do not edit files outside it: no game source, no tools, no docs, no
  `hulls*/` assets. Muse is the exception: it may deliver low-code fixes in text, data, tests, tools and docs as pull requests
  (R81).
- Proposing a change to an existing file? Put a copy of the whole changed file in your folder at the same relative path, plus a
  `NOTES.md` that says what changed and why. Reviews go in `contrib/<your-agent-name>/reviews/<topic>.md`.
- The Board merges what works. See `contrib/README.md`.

## Owner preferences that apply to any agent (RULEBOOK section 1)

- Plain words, short, lead with the answer, give your pick and why; no em dashes; no human-hour estimates (estimate in agent
  runs and review rounds, from the board's own history).
- Pictures for anything visual: one per item, its code name on it, no taller than 720 px.
- Anything Ryan runs himself is a double-click `.bat` file (Windows 10, PowerShell 5.1, no Python of his own).
- Before anything bigger than a quick fix, ask 3 to 5 plain multiple-choice scope questions in one batch.
- Questions for Ryan go to him in your own chat, never as GitHub tags or comments; message him only when something lands or
  needs him. Non-urgent picks wait for the Morning or Evening Pick Sheet (RULEBOOK 1.8, R408).
- No paid OpenAI API review where Artoo or Claude code review covers the PR (2.18, R406); no GPU capture on a PR before green
  checks and a passed review (3.12, R407).
- Heavy work (AI models, Blender, Godot captures) runs on Ryan's PC through the queue. GPU work is sized to the job and to
  what the RTX 5080 can hold, not a fixed job count (R293, RULEBOOK 3.4); frame-time measurements claim the GPU solo, lanes C to F
  stay code only, and gpu_go.txt still wins.
  Keep your PC folder lean. Deleting on his PC follows RULEBOOK 3.3: jobs and the cleanup janitor may remove their own
  rebuildable leftovers under its safe rules; nothing else is deleted without Ryan's yes.

`CLAUDE.md` is a short pointer to this file plus Claude-only notes. Keep the two in step. The fuller AGENTS.md of Nov 8 to 11
(seat table, ship sections, PC notes) is archived at docs/archive/AGENTS_2026-11-11.md; every rule it held is in the rulebook.
