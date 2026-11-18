# Storm rendering cost, issue 982

Start with [the measured before and after results and pictures](frame_times.md).
[The attribution recorded before editing](profile_before.md) isolates the card,
fog-grid, volume and bolt-light costs. [Validation](validation.md) records checks
and the initial scene-gate timing exception.

Only `godot/world/world_living.gd` changes in the game. Both gas card shaders now
calculate their existing height and footprint support before noise and reject
zero support immediately. The shader declarations are moved from their original
source, so layer dimensions, falloffs and colors keep one home. Surviving samples
use the same noise, lighting and alpha calculations. Max retains its card layout,
fog and electrical effects. Low drops its dim bottom puffs and retains the middle
cores, upper layer, broad veils and color ramps.

`measure.gd` uses the PR 976 seed-4103 storm case. `run.bat` runs three storm
sessions, fixed c170/c60 captures and two three-session launches of the unmodified
scene-207 gate, through the solo watchdog. It requires the installed gen cache and
matching ship textures after import. Scratch logs stay in TEMP. `compose.py`
builds the 1280x720 sheets from stamped native captures without color changes;
`report.py` derives the tables and pass results from raw JSON. The runner publishes
the linked sheets and their sidecars to `docs/shots/issue-982-codex/`.

[Approved-source hashes](approved_source.json) verify the baseline gas builders,
mask, bolt builder and flash envelope against PR 717 commit `ee2e21d9`. The accepted
ion-storm shader and baked noise are unchanged. No rules, oracle, workflow or
ship-asset source changes are included.
