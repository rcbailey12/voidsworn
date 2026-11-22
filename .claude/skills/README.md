# Skills for every seat

One skills folder for Claude Code, Codex and Antigravity, in the open Agent Skills layout (issue 1658, Ryan Nov 22 2026).
`.agents/skills/` is the source. `.claude/skills/` is a copy for Claude Code, made by
`node contrib/opus/tools/sync_skills.js` (plain copies, not links, because links break on a Windows checkout); the
standing check `skills_mirror_tests.js` fails when the two differ. Edit here, then run the sync.

## What is here

| Skill | From | Use |
| --- | --- | --- |
| playtest-and-balance, screenshot-verdict, ship-kit | this repo | rules and balance checks, picture checks, ship builds |
| grill-with-docs, grilling, domain-modeling | mattpocock/skills (MIT) | interview a plan; keep GLOSSARY.md current |
| wait-what | mattpocock/skills | "say that again, simpler" |
| improve-codebase-architecture, codebase-design | mattpocock/skills | find deepening refactors (run now and then on godot/ and tools/pc/) |
| to-spec, to-tickets | mattpocock/skills | turn a talk into a spec or issues on the job board |
| pocock-code-review | mattpocock/skills (renamed from code-review) | two-axis review: standards and spec |
| pr | mattpocock/skills | PR body: summary, evidence, merge danger |
| retro, writing-for-agents | mattpocock/skills | improve the agents' setup after a session |
| wizard | mattpocock/skills | step-by-step guide for something only a human can do |
| godot-4-api-pitfalls, godot-control-layout, godot-signals, godot-scene-organization, godot-verify | ziva-sh/godot-skills (MIT) | Godot 4 code, UI layout, signals, scenes, and checking from the command line |

Ryan named the first nine Pocock skills and the five Godot skills. grilling, domain-modeling, codebase-design and
writing-for-agents came with them because the named ones call them and do nothing without them. Not installed, by
Ryan's word: Claude-Code-Game-Studios, gd-agentic-skills --all, the full obra/superpowers, godot-tilemaplayer.

## House notes (these win over the skill text)

- **Tracker and domain docs**: `docs/agents/issue-tracker.md` and `docs/agents/domain.md` stand in for
  `/setup-matt-pocock-skills`. No triage labels, no `docs/adr/`: rules go in RULEBOOK with a FINDINGS row.
- **Only Ryan rules.** A skill that says "decide", "record a decision" or "apply" means: propose it. The Board merges.
- **Ryan is not a coder.** Anything he runs is a double-click .bat (RULEBOOK 1.4). The wizard's bash template is for
  cloud threads only; a wizard for Ryan is a .bat with the same stages. Questions to him follow RULEBOOK 1.5 and 1.8.
- **Reports**: improve-codebase-architecture writes its HTML report outside the repo; in a project thread publish it as
  an artifact instead of opening a browser.
- **Reviews**: the built-in `/code-review` stays the default code review seat (R406); pocock-code-review adds the
  spec axis when an issue brief exists.
- **godot-verify** is the habit behind the CI rule that a Godot check greps for `SCRIPT ERROR` instead of trusting exit
  code 0. Run Godot as `godot --headless --path godot ...` from the repo root.
- No em dashes in anything written for this repo (the vendored skill files are copied unchanged).

## Vetting (Nov 22 2026)

Every file was read before it was added. Licences: MIT (Matt Pocock 2026; Zivash, Inc. 2026); each folder carries its
LICENSE and a SOURCE.md with the exact commit. Contents are instructions only: no install steps, no network calls, no
hooks. Two touch the outside world when used: wizard's template.sh opens URLs, writes .env and can set GitHub secrets
(gh secret), and improve-codebase-architecture's report loads Tailwind and Mermaid from public CDNs. The agents/openai.yaml
files are Codex display metadata.
