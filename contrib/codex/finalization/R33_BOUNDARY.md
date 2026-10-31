# R33 save boundary: evidence and implementation limit

Source pin: 355a2ac7. No save or transport code is changed by this packet.

The plan provides evidence that was missing from the engineer review's pack. `contrib/opus/go-forward-plan.md:277` explicitly specifies **a fresh Godot save, with old browser saves not carried over unless Ryan asks**. Its containing section labels implementation choices as Claude's technical calls, vetoable (`:267`). `contrib/opus/FINDINGS.md:58` records Ryan's broad R33 migration scope without a separate save-policy quote. R35 (`:60`) supersedes the battle-first schedule, not explicitly the save default.

This supports a recorded fresh-save implementation default. It does not prove Ryan expressly rejected carrying progression, establish permission to delete browser saves, or settle the later audit's request for an importer. No later direct owner statement resolving carryover was recovered in the targeted context check. Keep shipping reconciliation open; do not turn the converter's existence or its test count into authorization.

| Layer | Established behavior | Boundary |
|---|---|---|
| Browser store | The reference expects raw strings keyed by `voidsworn.v1`, `.bak` and `.repaired`. | Reference fixtures are not a transport. |
| Reference converter | Produces `format: "voidsworn-desktop-save"`, `formatVersion: 1`, `meta`, `run` and provenance. | This is a proposed intermediate format, explicitly not the shipping importer. |
| Native writer | `campaign.gd:370` writes `format: "voidsworn-godot-campaign"`, `v: 1`, `uid`, `meta`, `run`, `tel`, with exact-float encoding. | The reference converter's format is not this writer's format. Do not drop its output into the native save path as a shipping integration. |
| Native load/save | `campaign.gd:354` describes a fresh format. Atomic writes and primary/backup load logic exist at `:372` onward. | Existing native saves must remain protected independently of any browser-import decision. |
| Shipping product decision | Plan default and importer audit remain in conflict. | No automatic import, wipe, grant stripping or cloud overwrite is authorized by this packet. |

If carryover is requested, settle the converter's explicit decisions before writing a native save: testing unlock grant strip/keep (including ambiguous earned purchases), unknown meta-id carry/drop, `.repaired` recovery, reward resume presentation, backup precedence and cloud reconciliation. These are documented in `contrib/muse/tools/importer_reference/README.md:235` onward. Its defaults explicitly are not rulings.

Then implement the smallest path: user-selected browser-store export, read-only conversion and accounting preview, explicit native-format mapping, and a new native save written only after the policy and destination are settled. This is a conditional technical recommendation, not an authorized implementation or new owner decision. Do not replace an existing native profile silently.

Safe work now: keep the converter/fixtures as reference evidence, preserve both save lineages, and continue native load/save checks. Opus can report the located plan default and the exact remaining contradiction without reopening the engine decision or conflating import with the battle-rule port.

Not checked: a complete archive of later owner conversations, live browser stores, the user's current native save, cloud accounts, shipping transport or import UI. No player data was accessed or changed.
