# PC acceptance: remaining execution

Status: **NOT RUN on Windows or the GPU.** The current Codex session exposes no device staging/commit bridge, so the watcher cannot be inspected or safely queued here. This is an execution limit, not a request for a new product decision. No active PC job was changed.

Use the existing runner rules in `HANDOFF.md:124` onward. Give each queued job a fresh staging folder and unique name, use the timeout wrapper, retrieve and compare staged `build/job.bat` before triggering it, and send `run.request` in a later separate call. Do not replace an active watcher job. The standalone launchers below do not stage watcher jobs by themselves.

| Order | Launcher / action | Evidence required |
|---|---|---|
| 1 | `pc/run_checks.bat` (this packet) | Godot version, individual check logs and complete summaries. Preserve any failure. The recorded Linux results are not Windows execution proof. |
| 2 | `../pre_opus/blender/self_test.bat` | Generated fixture detects the deliberately backward tagged weapon, missing texture and unassigned faces; `selfTest: PASS`; 18 actual images; complete `blender.log`. |
| 3 | `../pre_opus/blender/run_qa.bat` on the current Pyre-Barge GLB | Confirm imported forward/up axes; input hash unchanged; report, painted/clay contact sheet and 18 images. Judge all nine regions visually. No source mesh is saved or replaced. |
| 4 | In-game Pyre-Barge and faction fleet views | Screenshots at battle zoom, faction silhouette readability, shield/weapon distinction, material agreement and mount/muzzle inspection. Studio renders alone are insufficient. |
| 5 | Intended roughly 20 total ships, with an effect burst | GPU frame-time evidence, load behavior and legible selection/movement/fire controls. No phone acceptance pass. |
| 6 | One playable phased battle | Capture enemy inspection, a canceled movement preview, committed hex/facing and odds, one fire action that cannot spend twice, brace/pass and one complete round. Record committed actions and RNG/state observations separately from animation playback. |

The Blender tool requires `qa_role`, `qa_forward` and `qa_pair` tags for its direction/pair observations. Untagged production weapons remain unverified. Origin symmetry does not prove matching geometry, muzzle clearance or contact with the hull. The self-test's generated objects do not establish acceptance of the production mesh.

Do not mark cutover complete from these launchers alone. Current-source battle tests, the randomized re-pin sweep, campaign data/oracle reconciliation, migration intent and the actual player-visible result still have their own limits.
