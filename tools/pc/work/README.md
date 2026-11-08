# Workhorse runner (#217)

OpenCode, headless, on Ryan's PC: one board issue, one model, no one watching. Built and tested by Opus on Nov 7 2026.

Ryan's two double-click files (copies sit in Downloads\voidsworn_test; the scripts they call are in Downloads\voidsworn_test\work217\tools\):
- `WORKHORSE_SETUP.bat` (tools/pc/work_setup.bat): installs OpenCode 1.19.5 with npm, asks once for the DeepSeek and Moonshot
  API keys (saved as user settings DEEPSEEK_API_KEY and MOONSHOT_API_KEY, never in a file), checks each key and balance, then asks
  each model for one word through OpenCode. Result in work217\setup_result.txt.
- `WORKHORSE_TRIAL.bat` (tools/pc/work_trial.bat): issue #26 by the DeepSeek arm, then by the Kimi arm. Summary in
  work217\trial_summary.txt.

One run (tools/pc/work_issue.bat `<issue> <deepseek|kimi> [dryrun]`):
1. Fresh clone of main in work217\issue-N-arm\<date_time>\repo on branch work/issue-N-arm (no deletes; latest.txt names the newest).
2. WORK_TASK.md: runner notes (Git Bash, checks, parity command, Godot path, shot folder) plus the issue body, read live from GitHub.
3. Balance read, then `opencode run --auto --format json -m <model>` under tmo.bat (one hour cap). Events in out\events.jsonl.
4. Balance read again a minute later; out\stats.txt holds steps, tool calls, tokens, OpenCode's own cost estimate, and the real charge
   (balance before minus after).
5. Shots from out\shots are copied to docs/shots/issue-N-arm/, then commit (Ryan's git identity) and push; auto_pr opens the PR with
   the agent's report and the run stats as its description.

Models: arm `deepseek` = deepseek/deepseek-flash (DeepSeek V4.1 Flash); arm `kimi` = moonshotai/kimi-k3.1-pro (Kimi K3.1 Pro). Both are
built into OpenCode's catalog; keys come from the environment.

Things learned on the PC (Nov 7):
- OpenCode 1.19.5 starts fine on this Windows 10 PC (the help-text bug #8233 does not show).
- On Windows its shell falls back to PowerShell 5.1, where `&&`, grep and tail fail. The runner sets SHELL to Git Bash.
- Its shell commands stop after 2 minutes by default; parity takes about 8. The runner sets
  OPENCODE_EXPERIMENTAL_BASH_DEFAULT_TIMEOUT_MS to 30 minutes.
- `opencode.json` here allows everything except `git commit` and `git push` (the runner does those; caught anywhere in a command, and `git -c` too) and recursive deletes (`rm -r`, `rmdir`, `Remove-Item`; Ryan's rule: nothing is deleted on his PC). The dry run proves the push, a chained push and a delete outside the repo are refused.
- OPENCODE_DISABLE_MODELS_FETCH keeps the model list and price table pinned to the installed version.

Free dry run: `work_trial.bat dryrun` swaps in work/mock_llm.js, a stand-in model on port 8765 that drives a fixed script (look, write a
file, standing checks, Godot parity, a refused push, a refused chained push, a refused delete, report), and uses `git push --dry-run`. It costs nothing and checks the whole
Windows path end to end.
