# Outside check: PR 731 (issue 730, PC runner hot fixes)

Verdict: GO WITH CONDITIONS.

PR 731 is merged (the Board merged it on its own diff review under RULEBOOK 2.2's tools-only exception); this is the after-the-fact outside check the Board queued. All three changes do what they claim. One condition, on the Kimi preflight parse.

## The three changes verify

1. The Git helper runs git.exe. runner_common.ps1's Git function now sets $exe = 'git.exe', with the failure explained in the comment: PowerShell resolves the helper function before the program, so 'git' called itself until the call depth overflowed on the first live runs (issue 730: DeepSeek 720, 721 and Kimi 371 all dead in under a minute), and the test stub path (PC_TEST_GIT) never hit it. The runner_selftest.js assertion discriminates as issue 730's done-when requires: it demands $exe = 'git.exe' present and no $exe = 'git' assignment, so it fails on main's text and passes on the fixed text. The chair verified the negative pattern cannot false-pass on 'git.exe' (it requires a semicolon or whitespace immediately after 'git').
2. The Kimi preflight parse matches Kimi Code's real output. The old line took the whole stdout, trimmed, as the reply; against Kimi's actual format (thinking and answer as bullet lines, then a 'To resume this session' line) that could never equal the probe token. The new code scans lines, strips leading bullet characters, and accepts a line that reduces exactly to RUNNER_READY; no match leaves the reply empty, so it fails closed. This is a readiness probe: the exact token is the correct answer by design, and the opencode branch in the same function exact-matches the same way.
3. CODEX_CAP. codex_issue.bat's hard-coded 3600-second timeout is now an environment override defaulting to 3600 when undefined, so every existing launcher behaves identically unless a launcher sets the cap for a longer GPU or paint job.

## Condition

1. The Kimi parser scans every stdout line, thinking included. A thinking bullet whose whole content reduces exactly to RUNNER_READY would satisfy the probe even if Kimi's answer line said something else. The window is narrow (the thinking line must be the bare token after stripping), but the probe is a gate other work trusts. Condition: restrict the match to the answer line, for example by taking the last matching line before the 'To resume this session' line, or by stopping the scan at that line and using the final match. DeepSeek.

## Notes

- The new selftest assertion covers the Git helper only; nothing tests the Kimi parse. A fixture test feeding a representative Kimi stdout (thinking bullet, answer bullet, resume line) would pin the behaviour the hot fix just bought. DeepSeek.
- The parser is brittle to trailing punctuation or markdown on the token line ("RUNNER_READY." fails). It fails closed, so the cost is a false-negative preflight, not a false pass. DeepSeek.
- CODEX_CAP is unvalidated and expanded unquoted into the tmo.bat call; a malformed value passes straight through. Low risk for an internal override, and the default path is unchanged. Blind Rey leg and DeepSeek.
- The selftest's negative regex could in principle match a comment containing the old assignment text; the positive 'git.exe' requirement is the real discriminator, so this is cosmetic. DeepSeek.
- Flash graded its one finding BLOCKING and it is not adopted: it argued the parser should accept a non-empty answer line rather than requiring the exact token. That inverts the probe (see change 2 above): a readiness probe that accepts any answer proves nothing. Recorded as a leg misread; its other findings concur with this delivery.

## Legs and gates

Blind Rey leg first (chair, no pack): GO, the CODEX_CAP note and the live-run caveat below. DeepSeek (DeepThink on, Search off, verified before and after): GO WITH CONDITIONS, the condition and notes above. Flash (Gemini "Quick answers 3.5 Flash-Lite", verified selected before and after): GO WITH CONDITIONS on the misread above. Qwen: seat empty, the Qwen3.8-Max daily limit was reached earlier in the evening (two confirmed attempts); no substitution was made. Grok: seat empty, bot wall at grok.com, the twenty-sixth consecutive empty seat. Both recorded, never filled.

## Not checked

Issue 730's third done-when (one live job on the PC gets past checkout) is a PC-side fact no pack can verify; the Board's merge presumably rests on it. Also not checked: tmo.bat's handling of cap values, the other agent launchers' .bat files, and runner_common.ps1 outside the patched hunks.
