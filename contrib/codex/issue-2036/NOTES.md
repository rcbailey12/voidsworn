# AAA UI concept picks (issue 2036)

My picks are **SY-A, ST-A, CM-A and AR-A**. The shipyard keeps the ship and the change in the same glance. Short standing plates let the board breathe. The comms have one home. The report tells you who stood out before it asks you to pick salvage.

These are concept paint-overs from Muse's [issue 2030 design pack](../../muse/aaa_ui_1124/designs.md). Ryan is picking layouts, not accepting art, balance numbers, or features as built. The runner publishes the pictures under `docs/shots/issue-2036-codex/`.

## 1. Shipyard

- **SY-A, Gantry (recommended).** [Picture](../../../docs/shots/issue-2036-codex/SY-A_gantry.png). Fleet left, lit ship center, inspector right. The cursor over Repair previews Hull 94 to 135 (+41) without changing the one shield pool.
- **SY-B, Flight Deck.** [Picture](../../../docs/shots/issue-2036-codex/SY-B_flight-deck.png). Big bay left, inspector right, and a thumbnail strip at the bottom. The trade is more room for the ship and less room for a long roster.
- **SY-C, Fleet Ledger.** [Picture](../../../docs/shots/issue-2036-codex/SY-C_fleet-ledger.png). Bay left, text roster over the inspector on the right. This makes fleet comparisons faster but gives the ship less width.

## 2. Ship state on the board

- **ST-A, Stacked Plates (recommended).** [Picture](../../../docs/shots/issue-2036-codex/ST-A_stacked-plates.png). Two sizes of plate, with short leaders and clear space between plates. The selected plate spells out the lost prow. Each plate has one shield pool above three hull sections: prow, mid and engines.
- **ST-B, In-place Detail.** [Picture](../../../docs/shots/issue-2036-codex/ST-B_in-place-detail.png). The selected ship's plate opens where it stands. Nearby plates move sideways when they need space. Easier to read locally, but costs more board space.
- **ST-C, Edge Rail.** [Picture](../../../docs/shots/issue-2036-codex/ST-C_edge-rail.png). A left rail gives displaced plates somewhere to go. Best as the fallback when local placement fails, since it moves the readout away from the hull.
- **ST-0, Before.** [Picture](../../../docs/shots/issue-2036-codex/ST-0_crossing-rings.png). Two close ships' rings meet in a real Battle 2 frame. The image is a labeled crop, not a redraw of the game marks.

The selection ring belongs to the selected ship and target brackets belong to the enemy target. These are layout illustrations. In implementation, test actual plate size, loss text, leader endpoints, and ring suppression in a packed fleet at camera 170. The screenshot shelf still shows the capture's original hull and weapon state in these overlays.

## 3. Captain and admiral comms

- **CM-A, Turn Corner (recommended).** [Picture](../../../docs/shots/issue-2036-codex/CM-A_turn-corner.png). The captain banner sits below the turn block. The captain card shows face, callsign, and the existing perk.
- **CM-B, Above the KEEL.** [Picture](../../../docs/shots/issue-2036-codex/CM-B_above-the-keel.png). The admiral banner is close to the ship shelf, but shares the lower-left space with captain identity.
- **CM-C, Safe Slot.** [Picture](../../../docs/shots/issue-2036-codex/CM-C_safe-slot.png). The admiral banner uses a clear slot at the top center. It can avoid both corners, but the player has to look for it if the slot moves.
- **CM-D, Enemy Corner.** [Picture](../../../docs/shots/issue-2036-codex/CM-D_enemy-corner.png). The captain banner sits below the enemy block. It leaves the selected-ship area open, but makes two different kinds of message share the corner.

The captain and admiral speak in separate examples because only one banner is shown at a time. Callsigns drawn from a pool and callsigns earned by deeds use the same visual slot. The face count and selection rules are separate art and design picks.

## 4. After-action report

- **AR-A, Spotlight Report (recommended).** [Picture](../../../docs/shots/issue-2036-codex/AR-A_spotlight-report.png). MVP strip above the per-ship rows, with an open loss card alongside salvage. The illustrated MVP score gives damage taken quarter weight.
- **AR-B, Battle Ledger.** [Picture](../../../docs/shots/issue-2036-codex/AR-B_battle-ledger.png). Inline MVP marker, offense-only scoring, and a right rail for the loss card. The ledger is quieter, and the rail gives the record a fixed home.

Both keep the lost ship in the report. The open card names who killed it, what weapon landed the final blow, the battle and round, final damage, and the assist. The MVP formula is a separate pick from the layout. Keep XP and promotions on the ship row in the build. The legacy XP lines that remain in AR-B are carryover from the source capture.

## Sources and method

- [Shipyard capture](../../../docs/shots/late_run_1178/L1178_late_market.png), source `310105124457`.
- [KEEL target](../../../docs/shots/issue-1021-openai/keel_target_1080.png) and [KEEL collapsed log](../../../docs/shots/issue-1021-openai/keel_log_collapsed_1080.png), source `7c426f028ddf`.
- [Victory capture](../../../docs/shots/issue-1177-codex/V1177_victory.png), source `1c3f2fd08593`.
- [Installed Battle 2 recording](../../../docs/shots/player_path_1119/navy-b2-p02.mp4), source `1a8c7b971622`, part 2 at 00:25.000 (seed 10, round 3).

Built-in Codex ImageGen edited the real screen references. The prompt set held the ember orders sheet, KEEL shelf, and one pool per ship. Per-option prompts changed only the layout being compared: roster position for SY, plate placement for ST, banner placement for CM, and MVP and loss-card placement for AR. The repair delta, section loss, and casualty are staged examples for comparison. The before picture uses a crop and a pointer only. All 13 PNGs are 1280 x 720 and carry the source and stage on the picture and in verified sidecars. No game code changed and no new GPU capture ran.
