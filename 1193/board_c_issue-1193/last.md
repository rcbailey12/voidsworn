Implemented issue #1193. `tools/pc/gpu_slots.js` now writes claims atomically, archives damaged slot files, and checks PID, start time, and executable name. Claims require an issue, job directory, or script name.

`tools/pc/run_timeout.ps1` records the child before it can use the GPU. A failed kill logs the surviving PIDs and retains the claim until those processes exit. Updated `docs/RULEBOOK.md` §3.4 and added regression coverage in `contrib/opus/tools/gpu_slots_tests.js`.

All 21 GPU slot test groups, 11 runner stall groups, and the CPU-only `tmo.bat` smoke test passed on Windows. The standing suite reported two known baseline results and one sandbox hard-link error. The affected export test passed when rerun with Node in the writable temp folder.

Drain GPU jobs before replacing both tools across the shared copies. Changes are uncommitted.

**Hashwrite output**

```text
9936378fdbc6722fe50b64572a99c55e5038f7b88c418172f610adbb638919ec  gpu_slots.js
e7d4dde95e3b1e046b58067341fc8cac659ed3d62cbb5cb3a1a7c93b39831f4c  run_timeout.ps1
```