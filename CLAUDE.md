# Voidsworn: working notes for Claude

The rules for every AI agent are in `AGENTS.md` (slimmed Nov 11 2026, issue 492), and every rule in force, with its reason, is
in `docs/RULEBOOK.md`, which wins over every other document. Read both first. This file only keeps what is specific to Claude.

@AGENTS.md


**Claude-specific notes:**
- Then read HANDOFF.md section 0, contrib/opus/LOOP.md ("The seats", the LATEST lines) and the open issues and pull requests
  (the job board, R75). The plan is `docs/playbooks/PROGRAM.md`.
- The findings registry `contrib/opus/FINDINGS.md` is the dated history of rulings; a new ruling lands with its rulebook or
  playbook edit in the same PR (R214). Nothing under `docs/archive/` is followed.
- The Board thread in the Claude Code Project owns the board and its merges (R119, RULEBOOK 2.1); worker threads never merge
  their own PRs. LOOP.md holds the live state.
