# Voidsworn: rules for any AI agent (Claude or another model)

**The game.** Embers of the Hollow Sun (repo name voidsworn) is a hex fleet-tactics roguelite. The product is the Godot 4 game in
`godot/`, played on Ryan's Windows PC only; the browser JS game is frozen as the rules oracle and changes only for rules fixes.
The owner is Ryan. He is not a coder: he judges work by pictures. Faction ids never change; their display names do
(contrib/opus/compute/rename_map_final.md): `voidsworn` = Sunward Crusade, `corsair` = Ashfall Hullbreakers, `ithar` = the
Glasswrights, `deathless` = Eclipse, `chorus` = the Chorus, `hegemony` = Hegemony Navy.

**Read first.**
1. `docs/RULEBOOK.md`: every rule in force, each with its reason. **It wins** over this file and every older doc (its section 0.3
   says which document wins after it).
2. HANDOFF.md section 0 and contrib/opus/LOOP.md ("The seats", the LATEST lines): what is running now. They win for status only.
3. The playbook for your area: `docs/playbooks/` (PROGRAM.md first).
4. contrib/opus/FINDINGS.md is the dated history of rulings, not the live source. Anything under `docs/archive/` is history:
   never follow it.

Auditing from outside? Follow `docs/REVIEW_PROTOCOL.md` exactly (RULEBOOK 2.11) and the brief in your issue.

## The job board (Ryan, Nov 2 2026; RULEBOOK 2.4)

- Every job is an open GitHub issue: https://github.com/rcbailey12/voidsworn/issues. The label says who has it: `codex` (Codex on
  Ryan's PC), `muse` (Rey and its models), `opus` (Claude), `ryan` (waiting on Ryan), plus `blocked`. Who does which kind of
  work is RULEBOOK 2.6; which seats are live today is LOOP.md "The seats".
- Agents deliver by pushing a branch named `codex/issue-<number>`, `muse/issue-<number>`, `work/issue-<number>` (or
  `work/issue-<number>-<arm>`) or `opus/issue-<number>`. Never push to main (R75); the only exception is LOOP.md and
  FINDINGS.md, which the Board commits straight to main (R102).
- The push makes GitHub open the pull request by itself (.github/workflows/auto_pr.yml, for those branch shapes) and run the
  checks once (.github/workflows/checks.yml: standing checks, no em dashes in changed files, Godot rules parity, Godot game
  checks). A branch with any other name gets no automatic checks: open its pull request by hand, then start them by hand
  (Actions tab, "checks", "Run workflow"; or `gh workflow run checks.yml --ref <branch>`). The Board reviews and merges;
  nobody merges their own pull request (RULEBOOK 2.2).
- Codex runs locally on the PC only (RULEBOOK 2.7). The Board launches each Codex job itself through the PC queue (LOOP.md
  "The seats" says how), and every `codex` issue also carries `blocked`, so the old board watcher (tools/pc/codex_board.bat)
  cannot run it a second time.
- Every issue opens with this fixed block, so any agent can pick it up without asking:
  ```
  Owner: codex | muse | opus
  Brief: <path to the brief, or "below">
  Deliver to: <folder or files>
  Branch: <agent>/issue-<number>
  Effort (Codex): high | xhigh   or   Models (Muse): <set>
  Done when: <the check that proves it, and what Ryan will see>
  ```
  Muse's Models line for research, design and review jobs: Rey writes a blind leg first, DeepSeek, Qwen, Grok and Flash each
  write a leg, Rey chairs (R89, R231, RULEBOOK 2.8). Muse's standing instructions: `contrib/opus/briefs/muse_standing_rule.md`.
- Ship build issues add four lines to the block (Ryan, Nov 11 2026, R214; template in docs/playbooks/ships.md section 7):
  Route per part, Inside, Paint stack, Budget. Every build pull request body carries its done-when evidence and a method line
  (build sheet link, manifest, budget numbers, changes made to the sheet); the outside check (issue 256) returns a build PR
  without them as BLOCKING (RULEBOOK 5.14).
- **A ruling lands with its document.** A ruling that changes a working method is not landed until the same pull request edits
  the rulebook or the working document a worker reads for that area (the playbook, RECIPE.md, this file) (R214, RULEBOOK 0.2).
- Commits say "Refs #N", never a GitHub closing word before an issue number; use `gh api` REST, never GraphQL (RULEBOOK 2.5).

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
  needs him.
- Heavy work (AI models, Blender, Godot captures) runs on Ryan's PC through the queue, one GPU job at a time; keep your PC folder
  lean; never delete anything on his PC (RULEBOOK section 3).

`CLAUDE.md` is a short pointer to this file plus Claude-only notes. Keep the two in step. The fuller AGENTS.md of Nov 8 to 11
(seat table, ship sections, PC notes) is archived at docs/archive/AGENTS_2026-11-11.md; every rule it held is in the rulebook.
