Refs #1180

Run 4 is ready as an uncommitted patch against `667932fd`. The runner checkout was missing the run 3 changes, so I tested in a temporary checkout and left the runner checkout untouched. [Run 4 patch](C:/Users/rcbai/AppData/Local/Temp/voidsworn-run-f3dbf944d81e440088426930df7896a3/issue-1180-run4.patch)

Updated `janitor.ps1`, `runner_common.ps1`, `runner_cleanup_tests.js`, and Rulebook 3.3. TEMP cleanup now requires an ownership token or an exact runner status record. All three lookalike fixtures were kept, and two consecutive scans preserved `.git/index` timestamps. The campaign parity checks confirmed both approved outputs are ignored and regenerated.

The Windows dry run proposed **10 removals totaling 52.34 GiB** and removed nothing. It lists each proposal’s size and reason. Live cleanup remains pending Board review. [Dry-run report](C:/Users/rcbai/AppData/Local/Temp/voidsworn-run-f3dbf944d81e440088426930df7896a3/issue-1180-run4-pc-review.txt)

The standing suite recorded **73 passes, 2 known results, and 3 failures**. The new cleanup tests passed. The GPU slot and export tests passed on isolated retries, as did the runner’s lane-lock and accounting fixtures. The full runner self-test remained red. [Standing checks log](C:/Users/rcbai/AppData/Local/Temp/voidsworn-run-f3dbf944d81e440088426930df7896a3/issue-1180-run4-checks.txt)