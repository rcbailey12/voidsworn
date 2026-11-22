# Claude hooks

Claude Code 2.1.295 or later runs these Node hooks on Windows and Linux. Start a fresh Claude session after settings change and check `/hooks` for the registered events.

## Assign a seat before launch

- **Board.** Set `VOIDSWORN_BOARD_SESSION_ID` to the Board session ID in its launch environment, then resume that session. The hook compares the ID in each Claude event. Subagents and other sessions keep worker permissions.
- **Worker.** Set `VOIDSWORN_CLAUDE_SEAT` to the worker's folder name, such as `opus` for `contrib/opus/`. An unset seat has a read-only working tree. Use Claude's file tools for edits and `git add -- <files>` to stage them. Separate worker sessions can have their own values.

## What runs

- **Before a tool call.** Project read-deny permissions and the credential guard cover named credential paths. The worker guard checks the real target of file edits and restricts worker shell commands to a small Git allowlist. Use managed file and shell permissions where credential isolation from arbitrary Board subprocesses is required.
- **Before a push.** Use one named remote and one explicit branch, as in `git push origin <branch>` or `git push origin HEAD:refs/heads/<branch>`. For main, the hook checks the live push remote and every incoming commit. Only the Board can make a fast-forward push whose commits each change only `contrib/opus/LOOP.md` and `contrib/opus/FINDINGS.md`. Reviewed PR merges use the usual Board route.
- **After a Claude file edit.** The edited text is checked for em dashes. A warning on the tool result names the fix. Branch checks also cover shell-written files.
- **At the end of a Godot code turn.** The hook finds changed GDScript, scenes and project settings, including commits since the prompt. It runs Godot's existing headless script-and-scene loader with a temporary profile and blocks on a failed parse. It uses `GODOT_EXE` or `GODOT`, the installed PC console build, or `godot` on PATH.

Run `node .claude/hooks/guard.test.cjs` for the planted-failure checks. It uses only a temporary Git repo and local remote, and runs the real Godot loader on a small test project.
