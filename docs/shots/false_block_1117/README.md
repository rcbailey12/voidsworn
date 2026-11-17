# Issue 1015 PC check timings

Measured on November 17, 2026, using bundled Node 22 from `voidsworn_test\board_d\repo`. Lanes B (issue 1002) and C (issue 946) were running standing checks during all three measurements. The original and final runs overlapped for about 36 seconds, and the lane D standing suite was also running during the final measurement. These are wall-clock times on a busy PC with a changing background load.

| Windows selftest | Start (CST) | Wall time | Result |
| --- | --- | ---: | --- |
| Before, original serial matrix at `802fa1ec` | 16:15:02 | 521.34 s | 44 checks passed |
| Intermediate, fixture watchdog shim with serial cases | 16:17:58 | 263.87 s | 45 checks passed |
| After, fixture watchdog shim with up to six cases at once | 16:23:07 | 37.85 s | 45 checks passed |

The original matrix repeatedly started PowerShell, classified the fake commands and checked GPU slots through `tmo.bat`. The test now copies the real job scripts into its temporary fixture and uses a CMD shim that runs only the fixture executable and returns its exit code. Each case has its own home, logs and counters. All 44 original checks passed with the same case labels, and the added static check covers bundle discovery in all three launchers.

The final run finished 483.49 s faster than the measured original and 562.15 s inside the standing suite's 600 s limit.

The updated stage 5 row also passed in both full standing runs, in 46.51 s and 87.54 s. The separate `runner_selftest` row hit a 90 s fixture limit on the first run and the 600 s row limit on retry. It also failed on lanes B and C during their own standing runs.
