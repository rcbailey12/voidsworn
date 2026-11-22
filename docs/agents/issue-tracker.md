# Issue tracker: GitHub (rcbailey12/voidsworn)

What the skills in `.agents/skills/` (to-spec, to-tickets, pocock-code-review and others) need to know about where work
lives (issue 1658). The job board rules win: AGENTS.md "The job board" and RULEBOOK 2.4.

- Every job is an open issue on rcbailey12/voidsworn that opens with the fixed block (Owner, Brief, Deliver to, Branch,
  Base, Effort or Models, Done when). A skill that "publishes to the tracker" writes that block first.
- The label says which seat owns it: `opus`, `codex` (plus `blocked`), `muse`, `neon`, `ryan`, plus `running` while a seat
  works it. There is no `ready-for-agent`, `needs-triage` or other triage label here; never create one.
- Use `gh api` REST, never GraphQL (RULEBOOK 2.5):
  - create: `gh api repos/rcbailey12/voidsworn/issues -f title=... -F body=@body.md -f "labels[]=opus"`
  - read: `gh api repos/rcbailey12/voidsworn/issues/<n>` and `.../issues/<n>/comments`
  - comment: `gh api repos/rcbailey12/voidsworn/issues/<n>/comments -F body=@c.md`
  - blocking: a `Base:` line in the fixed block for a branch the job needs, or a `Blocked by: #<n>` line under it.
- Only the Board relabels, closes or merges. A worker never closes or edits another seat's issue.
- Commits say `Refs #N`, never a closing word before an issue number.
- Pull requests: branch `<seat>/issue-<n>`, the PR body starts with the project attribution lines and carries the evidence
  (RULEBOOK 5.14 for ship builds). The `pr` skill's Summary, Evidence and Merge Danger sections go under those lines.
