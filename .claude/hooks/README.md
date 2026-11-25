# Claude hooks

Claude Code 2.1.295 or later runs these Node hooks on Windows and Linux. Start a fresh Claude session after settings change
and check `/hooks` for the registered events. Claude Code runs a repo's hooks only in a trusted folder; a cloud thread
with `CLAUDE_CODE_IGNORE_PERSISTED_TRUST=1` may not load them (seen in a nested test session, Nov 22).

## Seats

- **Main seat (default).** No variable to set. The Board and every Opus project thread, and their subagents, are main
  seats: they edit anywhere and run any shell. Setting `VOIDSWORN_CLAUDE_SEAT` to `opus`, `board`, `main` or `claude`
  is the same.
- **Fenced seat.** Set `VOIDSWORN_CLAUDE_SEAT` to another seat name, such as `fable`, at launch. File edits stay under
  `contrib/<seat>/`, shell is limited to `pwd` and a small Git list (status, diff, switch -c to an issue branch,
  `git add -- <own files>`, `git commit -m`, push), and it cannot push to main or write through the GitHub API.

The hooks cannot tell the Board from an Opus worker thread (cloud threads get a fresh session id and no launch variables).
"Only the Board commits LOOP.md and FINDINGS.md to main" stays a written rule (R102); the hook only makes sure nothing
else ever reaches main.

## What runs

- **Before a tool call (every seat).** Project read-deny permissions and the credential guard cover named credential
  paths. A non-secret file whose name matches (for example `hotkeys.key`) cannot be read by Claude: rename it so the name
  no longer ends in a credential pattern (`hotkeys_key.txt`), or ask Ryan to open it.
- **Pushes (every seat).** Use plain `git push` with named refs. Wildcard and matching refspecs, bulk flags, push
  aliases and shell aliases that run push, send-pack, gh api or command substitutions are refused. A push to main must
  be a fast-forward, in a Bash call of its own, whose commits each change only `contrib/opus/LOOP.md` or
  `contrib/opus/FINDINGS.md`. The F9 tip lint switch is off until F6 and the LOOP.md roll land. Once enabled, the checked-out
  tracked files must match the tip, and both the memory and doc lints must pass. Arbitrary scripts are outside the hook's view.
  GitHub's branch protection on main is the real lock (Fable's audit of PR 1706).
- **Key file names in shell commands.** A bare word ending in `.key`, `.pem`, `.p12` or `.pfx` counts as a credential only
  when it is a path (slash, backslash or colon) or names a file that exists, so code such as `board.key(` can be searched.
- **GitHub API writes (every seat).** `push_files`, `create_or_update_file` and similar MCP calls, and `gh api` writes to
  contents or refs, are refused when they target main or name no branch. The direct branch merges endpoint is refused.
- **After a Claude file edit.** The edited text is checked for em dashes. A warning on the tool result names the fix.
- **At the end of a turn that changed Godot code.** The hook finds changed GDScript, scenes and project settings since
  the prompt, and runs Godot's headless loader. A real parse failure blocks once so the model can fix it; if the retry
  ends with the same failure, the turn ends with a visible note instead of looping. If Godot is not installed or cannot
  run, the check is skipped with a note and never blocks. Prompt, stop and session-end hooks never block on their own
  errors.

Run `node .claude/hooks/guard.test.cjs` for the planted checks. It uses only a temporary Git repo and local remote, and
runs the real Godot loader on a small test project.
