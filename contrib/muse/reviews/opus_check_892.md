# Outside check: PR 892 (issue 890, generated live status page, HANDOFF link, ruling-to-document lint)

Checker: Muse (Rey), chair-run with local execution. Refs #256.
PR head checked: 408d44fa9539069c4ef810c63a819ceaab81f3a1 (merged Nov 16 2026 16:35 UTC, merge 9fefabe2).
Method: the full PR file set read at the head SHA; the small files diffed line by line against the base (2ca44f51); both test suites run locally on the complete fixture tree; the FINDINGS changes compared cell by cell; the new lint rule also run against the rows added to main after this PR merged (R293, R294).

## Verdict: GO

Every claim in the PR body checks out, and the machinery it adds has already run end to end since (the nightly regeneration produced PR 902's page, merged; LOOP 17:55 UTC Nov 16).

## What was verified

1. Tests pass. gen_open_work_tests.js: 12 of 12 pass, including the live status test (seats, running, Board queue, merged-PR issues) and the failure tests (a failed list rejects the whole page, no partial Markdown). memory_lint_tests.js: 10 of 10 fixture assertions pass, and the live lint at the PR head is clean: 150 cited ruling ids all have rows, 12 rows from R281 on checked for landings, 0 failures.
2. The workflow (.github/workflows/open_work_nightly.yml) is as described: schedule 09:17 UTC plus manual dispatch; permissions are contents write and pull-requests write only; the branch opus/open-work-nightly is rebuilt from a fresh main checkout and force-pushed each run; a pull request is opened only when none is open; a stamp-only change commits nothing. Its header comment discloses that the workflow token starts no checks on that branch, which is correct GitHub behaviour and acceptable for one generated page the Board reviews before merging.
3. HANDOFF.md changes by exactly one line: the section 0 running-now prose becomes the link to contrib/opus/OPEN_WORK.md. Nothing else in the file moves. AGENTS.md gains exactly one line (the FINDINGS row rule). RULEBOOK gains the row rule in 0.2 and the R291 paragraph in 2.10; Ryan's quoted words in the 2.10 paragraph match the R291 row.
4. FINDINGS: only rows R281 to R292 change, and only in the Evidence column. Ryan's quotes and the decision text are byte-identical to the base (the diff was read row by row; R291's quote keeps its original wording, R292's too). The landing claims are accurate: R281 and R288 name docs/RULEBOOK.md 2.4, AGENTS.md and docs/playbooks/PROGRAM.md, which is where issue 880 landed them; R291 names docs/RULEBOOK.md 2.10 and 0.2, landed by this PR; R289 is recorded as part landed (factions.md, RULEBOOK 2.3) and part one-off, which matches the record. The one-off rows (R282 to R287, R290, R292) are genuinely per-job picks and briefs.
5. The generator's live status section behaves as specified, and the regenerated page in this PR is coherent against that moment's GitHub state (muse seat: 881 and 256 open; the Board queue lists the then-open PRs including 891). The edge fixtures cover the claimed cases: draft PR excluded, a PR number not listed as an issue, a running issue's PR excluded from the Board queue, "#70" not matching issue 7, and titles with pipes, newlines and em dashes sanitised by the plain() helper.
6. The lint rule does not break on today's record: rows R293 (landed in docs/RULEBOOK.md 3.4, AGENTS.md, docs/playbooks/PROGRAM.md, docs/playbooks/ships.md) and R294 (one-off job decision), both added to main after this PR, satisfy check 5 as written.

## Notes (not conditions; for the Board to take or leave at the tools' next touch)

1. The merged-PR naming test counts any "#N" in a PR body, so the standing issue 256 appears in the "open issues that a merged pull request names" section on every regeneration (it is there in this PR's own page, named by PRs 692, 743, 760, 774, 778, 802). The section is advisory and the test matches R288's stated method, so this is noise, not error; if it ever misleads, excluding standing issues or requiring an "Issue N" mention would quiet it.
2. Check 5 passes a row when any one path after "landed in" exists; a row naming one real path and one wrong path would pass. It also reads only up to the next table pipe after "landed in". Fine for a lint whose job is catching rows that name nothing; it is not a proof that every named path is right.
3. R281 and R288's evidence lines omit contrib/opus/LOOP.md, where issue 880 also landed the seats dispatch bullet. A completeness nit in the record only.
4. Local-run caution: the lint suite only passes on a complete tree (its fixtures span several files per fixture root). A partial checkout fails checks 1 to 4 spuriously, as my first run did before the full fixture set was fetched. CI runs it whole, so this affects only hand runs.

Not checked: the nightly workflow's scheduled (not dispatched) run, which first fires Nov 17 09:17 UTC; the dispatched runs since merge are the evidence it works.
