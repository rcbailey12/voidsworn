Recorded the [Run 3 baseline and raw traces](docs/shots/perf_1118/run2/README.md). High dense-storm GPU time fell from **6.77 to 4.42 ms at 4K** and from **1.91 to 1.28 ms at 1080p**. High was cheaper than Max in every matched session. The captures matched visually at radii 170 and 26. [Storm proof sheet](docs/shots/issue-1070-codex/PERF1070_RUN3_STORM.jpg)

At 1080p Max on main:

- **First fitted shield hit:** The first five frames peaked at **5.46 ms**. The full window peaked at **35.59 ms**, and the no-hit control reproduced the later hitch before game processing.
- **First death:** **10.93 ms** worst.
- **Scene 207:** **3.81 ms** median and **36.33 ms** worst.

Updated the gas shaders, noise bake, and benchmark harness. The published baseline uses the repeat after closing a leftover headless smoke process.

The standing suite had 73 passes and two known exceptions. The picture-provenance test passed on its isolated rerun. Both headless Godot checks passed. No commit or push.