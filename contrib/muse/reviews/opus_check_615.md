# Outside check: PR 615, Claude API workhorse arms opus and sonnet (issue 614)

- Repo: rcbailey12/voidsworn. Delivery branch: muse/issue-256. Refs #256.
- PR head checked: opus/issue-614-sonnet, 2bde34a2f7.
- Chair: Rey, blind. Read the full PR diff (373 lines), work_issue.bat (267 lines)
  and work_issue.ps1 (445 lines) at head, and both OpenCode configs at head.
- Council (Ryan's Nov 12 composition): DeepSeek GO. Qwen seat empty (daily
  Qwen3.8-Max cap; the prompt, pack and diff wait in its chat for a retry).
  Grok GO (ideation seat). Flash GO (ideation seat).
- Verdict: GO WITH CONDITIONS, notes only. No BLOCKING findings.

## The Board's five asks, answered

1. Key naming. PASS. The key is VOIDSWORN_CLAUDE_API_KEY everywhere: setx in the
   new tools/pc/claude_api_key.bat, {env:VOIDSWORN_CLAUDE_API_KEY} in both
   OpenCode configs, read by :getkey from HKCU\Environment in work_issue.bat.
   ANTHROPIC_API_KEY appears only in comments explaining why that name is never
   used. The sonnet and opus arms fail closed before the clone (exit 3) when the
   key is missing, so OpenCode can never fall back to an ANTHROPIC_API_KEY in
   the environment.
2. Keycheck header. PASS. work_issue.ps1 lines 159-160 build x-api-key plus
   anthropic-version headers for the anthropic arms only; every other arm
   keeps the Bearer header.
3. Lean config. PASS, and wider than the body states (NOTE 1). opencode_lean.json
   now serves kimicode, sonnet, opus, deepseek and deepseekpro; opencode_kimi.json
   is deleted. Positive finding: neither opencode.json nor opencode_lean.json
   defines deepseek or moonshotai providers, so the lean routing cannot break
   DeepSeek provider resolution; the only change for the DeepSeek arms is
   helper agents off.
4. Kimi limits. PASS. Context 250000 and a k3 model entry in both configs; the
   mock config carries the k3 stand-in too.
5. Money and leak surface. PASS with notes (NOTEs 2, 3, 4). Dry runs replace
   all four keys with the literal placeholder value and pin every provider to
   the localhost mock with apiKey "dry". The anthropic arms have bal set to
   null, so the balance step writes "plan (no balance)" and makes no call.
   No key value is written to any file or log by the runner.

## Findings

NOTE 1. The PR body understates the lean routing. The body says the lean config
is "used by kimicode and sonnet"; work_issue.bat at head routes five arms to
opencode_lean.json (kimicode, sonnet, opus, deepseek, deepseekpro). The wider
routing is the point of the change (DeepSeek spend control), so the body
should say so.

NOTE 2 (DeepSeek catch, chair verified). WORK_MODEL can point a non-Anthropic
arm at an Anthropic model. work_issue.bat applies "if defined WORK_MODEL set
MODEL=%WORK_MODEL%" before the per-arm key checks, and those checks key on the
arm, not the model. A run started as arm deepseek with WORK_MODEL set to an
anthropic model id would spend Claude credits while only the DeepSeek key was
checked for presence. Operator error only, but the fail-closed property the PR
advertises is arm-shaped, not model-shaped.

NOTE 3. There is no spend cap and no balance read for the anthropic arms. The
only ceilings are the $100 a month credit itself and the run time cap. Whether
exhausted credits hard-stop a run or overflow into organisation billing is a
platform.claude.com organisation setting; nothing in the repo can show which
way it is set. Worth one look at the console before the arms take big jobs.

NOTE 4. All four keys are loaded into every real run's environment. This is the
pre-existing three-key pattern extended to the Claude key: :getkey loads
DEEPSEEK_API_KEY, MOONSHOT_API_KEY, KIMI_CODE_API_KEY and
VOIDSWORN_CLAUDE_API_KEY for every arm, so the agent process holds all four
whatever arm runs. The runner writes no environment dump and no key reaches a
file or log (verified in the bat and ps1 output paths), so the exposure is the
agent process itself, as before this PR.

NOTE 5 (DeepSeek, minor). claude_api_key.bat does not check the setx result;
"Saved" prints whether or not the save worked. The key is also visible on
screen while it sits at the set /p prompt. One-PC tool, small stakes, worth a
result check if the file is touched again.

NOTE 6 (DeepSeek, minor). The work_issue.ps1 header comment (line 15) still
lists only the three older keys and omits VOIDSWORN_CLAUDE_API_KEY, which the
same file now reads for two arms.

NOTE 7 (chair, minor). The fail-closed message in work_issue.bat says "run
CLAUDE_API_KEY.bat" while the file is named claude_api_key.bat. Harmless on
Windows (case-insensitive), untidy in a message meant to be followed exactly.

## Council record

- DeepSeek: GO, notes only. Raised NOTEs 2, 5 and 6. Chat:
  https://chat.deepseek.com/a/chat/s/a8dcb4e9-ce4b-49a9-a45b-d8b562dc88cb
  (DeepThink on, Search off, both verified in the run.)
- Qwen: seat empty. Qwen3.8-Max hit its daily cap before this leg; the selector
  showed Qwen3.8-Max before the attempt and the header after. The prompt, pack
  and pasted diff wait in https://chat.qwen.ai/c/3cbc549a-30d7-4e41-a4d9-f3a1ca3b3b0d
  for a retry after the reset. Fifth empty Qwen seat on Nov 12 (533, 593, 598,
  608, 615).
- Grok: GO, all five asks confirmed, notes only (ideation seat; verdict
  recorded, not adopted as reviewer evidence). The leg ran on pasted text
  (pack plus the full diff) because the browser window had no file upload
  action; work_issue_head.bat was not attached, and its changed sections are
  inside the diff hunks. Grok's claim of no reference to ANTHROPIC_API_KEY in
  the bat is imprecise as written: the string occurs there in a comment saying
  never to use it; zero occurrences as a set, export or read is the true point
  and it holds. Grok missed NOTE 2. Chat:
  https://grok.com/c/afbac2a0-dbc0-483b-a0c7-15dab509b7c1?rid=67bdf444-2d6d-4a37-8df3-36735361479a
- Flash: GO, all five answers graded NOTE, shallow (ideation seat). Its claim
  of zero occurrences of ANTHROPIC_API_KEY in the diff is wrong as written for
  the same reason as Grok's: the string occurs in comments; zero as a set or
  export is correct. Chat: https://gemini.google.com/app/d6034b9818b3e678
- Rey (chair): all five asks verified against the head files as above; NOTEs 1,
  3, 4 and 7 are the chair's.

## Method compliance

The PR body carries its evidence for the key naming, the keycheck header, the
lean rename and the RULEBOOK 2.6 record, and states the 597 carry (Kimi
250000). Its one gap is NOTE 1: the body's lean routing line names two of the
five arms the bat actually routes, so a reader checking method compliance from
the body alone would understate the change. The delivery itself follows the
standing rule: this file is the one write, on muse/issue-256, saying Refs #256.
