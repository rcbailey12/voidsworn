# Battle UI and selection process audit - Qwen leg (Oct 29 program)

Chair filing note: Qwen leg for the Oct 29 program battle UI item, run Oct 29, 2026, 4:32-5:38 PM PDT (chat.qwen.ai/c/807d4c91-e06b-4cc8-a99d-54d53e74d729). Both model gates passed (selector set to Qwen3.8-Max before sending; header verified after generation). The send-time Access Verification slider was cleared by the challenge specialist under Ryan's explicit permission after several fresh puzzles. The first send lost its attachments; both files were re-attached in the same chat and the report below was produced from them. Verbatim model text follows; em dashes, en dashes, and arrows in the original are normalized to hyphens and -> in this filed copy, wording otherwise unchanged.

Battle UI & Selection Process Audit - Voidsworn

PROOF OF READING

Sections read:
1. EVIDENCE PACK title line ("battle UI and selection process audit, with external comparison (code slices from the shipped browser build, main 264f441d; the Godot port mirrors this design)")
2. THE COMMISSIONER'S QUESTION
3. CHAIR CENSUS (all bullet points: Selection, Weapons, Movement, Action strip, Keyboard, Camera, Commitment, Comparator set)
4. WHAT TO JUDGE (six numbered questions)
5. Code slices: ui3d.js 105-140 (roster pick, weapon rows, panel assembly), ui3d.js 161 (keysHelp), ui3d.js 388-402 (selectUnit, cancelAction), ui3d.js 413-431 (firing set, click-to-fire flow), ui3d.js 466-500 (move damage preview, hover odds, attackTip, boonMods), ui3d.js 501-535 (onKey, ACT.arm/board/ability), ui3d.js 665-683 (actionStrip, camera keep/restore/show, stripHelp), ui3d.js 642-652 (TIPS array)

Overall verdict: SOUND.

The selection-and-fire loop is coherent, well-instrumented with preview information, and appropriately paced for a desktop hex game at 20 ships. It does not reach BEST IN CLASS because the no-undo commitment model combined with fire-on-click at scale creates a misclick risk that the comparators have solved more gracefully; nor is it FRICTION, because the layered information (ghost preview, per-facing odds, threat map, contextual striphint) genuinely reduces the cognitive load rather than adding to it.

FINDINGS

1. [FIX] Fire-on-click conflates inspection and lethal commitment; at 20 ships the misclick cost scales linearly.
READ: "Clicking an enemy ship while a usable friendly ship is selected FIRES on it (the whole firing set: every bearing weapon, or the single armed weapon if one is armed)." READ: the click flows directly into await act(async()=>{ … for(const i of set){ … await fireWeapon(s,i,u); …} }). There is no intermediate confirmation, no "fire" button press, no drag-to-target. At 20 ships the board is dense; a player Tab-cycling or repositioning the camera can click the wrong hex. INFERRED: BattleTech (2018) requires selecting a weapon group, then a target, then confirming the fire solution before shots animate; XCOM 2 similarly separates target selection from the confirm click. The pack's own cantFireReason toast path (line ~431) shows the designers already anticipate "I clicked but shouldn't have," yet the happy path has no equivalent brake.

2. [FIX] The inspect-vs-fire split is state-dependent and invisible.
READ: "Clicking an enemy with nothing usable selected inspects it instead (ui3d.js 431)." The same physical click (left-button on an enemy hex) means two different things depending on whether B.sel is set and canUse(s) returns true. The only visual cue is the red pulsing ring mentioned in TIPS: "Enemies you can hit have a pulsing red ring." INFERRED: FTL lets you click any enemy ship at any time to inspect without risk; BattleTech shows a targeting reticle only when a weapon is actually selected. A player who deselects (Esc -> Esc -> Esc) and then clicks an enemy expecting to inspect will instead fire if they had Tab-cycled back without realising a ship was still selected. The striphint helps ("Tap a red-ringed enemy to fire") but does not distinguish "you are about to fire" from "you are inspecting."

3. [FIX] No undo and no order-revision window in a game where movement is path-dependent and firing is sequential.
READ: "there is no undo. Orders execute as animations; movement can include mid-move fire; firing is committed click by click." READ: "A stall watchdog skips a hung action after a timeout." INFERRED: Into the Breach permits full turn rewind; XCOM 2's Solace-class and strategy-layer save-scumming culture acknowledge that players need error recovery; Sins of a Solar Empire 2 lets you queue and re-queue fleet orders before they execute. The pack's commitment model is defensible for tension, but the absence of even a short "cancel during animation" window (the 80 ms gaps between weapon shots suggest the game already serialises) means a misclicked move cannot be recalled even in the first 100 ms.

4. [NOTE] The armed/all-weapons toggle is fast but shallow; no weapon-group concept exists.
READ: "number keys 1-6 (or clicking a weapon row) arm a single weapon; unarmed means fire everything that bears (firingSet, line 417)." INFERRED: BattleTech groups weapons into fire-control sets and lets the player assign called shots to specific hit locations; Rogue Trader's voidship battles let you toggle broadside vs focused fire per weapon bank. Voidsworn's model is binary: one weapon or all. A ship with six weapons where only two bear and one is a slow torpedo that the player wants to hold back has no intermediate option without arming each desired weapon one at a time.

5. [NOTE] The two-tap Command confirm with a 6-second visible countdown is well-designed but unique in the UI; no other destructive action gets a confirm.
READ: "the admiral Command (gold, two-tap confirm within 6 s, tier dots)." READ: ACT.command shows "Tap again (Xs)" with a setInterval ticking. INFERRED: This is a good pattern. But Ram (which deals and takes significant damage) and Board (which can lose the boarding party) fire on a single button press. If the design logic is "irreversible high-stakes actions get a confirm," Ram qualifies.

6. [NOTE] Ghost-move preview with expected damage is excellent; hover-odds-by-facing is best-in-class for the genre.
READ: "Hovering a gold hex shows a ghost ship and an expected-damage line for the move (moveDmgLine, line 466); hovering a target shows hit odds and expected damage by shield facing (line 491)." READ: attackTip shows per-weapon hit chance, damage multiplier, which shield quad is struck, rear-arc bonuses, boon modifiers, and a "Likely kill" callout. INFERRED: This exceeds FTL's pause-and-read model (FTL shows odds only as a flat percentage, no facing breakdown) and matches BattleTech's per-weapon hit-probability table. It is the single strongest element of the UI.

7. [NOTE] Tab cycling skips dead and done ships but does not announce what it skipped.
READ: nextShip filters ready=list.filter(u=>!isDone(u)) and falls back to the full list. INFERRED: At 20 ships, Tab becomes a slow carousel. XCOM 2 cycles only actionable units and shows a count ("2 soldiers remaining"). BattleTech shows a numbered initiative queue. The pack's striphint says "Nothing left to do: tap Done with ship," but Tab at 14 remaining ships with 11 done is tedious.

8. [NOTE] Camera save/restore respects player agency but the pan-without-zoom rule can disorient at 20-ship scale.
READ: "when an enemy acts off-screen the camera pans most of the way toward it but never changes zoom (camShow, line 680)." READ: camShow moves 75% toward the target. INFERRED: Sins 2's fleet camera zooms out to show the full engagement and lets the player zoom into individual fights; Deadlock uses a cinematic follow-cam. At 20 ships, a fixed-zoom pan means the player may see only a fragment of the enemy activation. The "never zoom" rule protects against jarring scale changes but can leave the player staring at empty hexes while the relevant action is off the visible tile range.

9. [NOTE] The contextual striphint is a genuine innovation but is text-only and can be missed.
READ: the hint variable in actionStrip cycles through at least eight contextual messages ("Wing selected: tap an enemy…", "Ram ready: … is dead ahead", "Tap a gold hex to move, or a red-ringed enemy to fire.", "Nothing left to do: tap Done with ship."). INFERRED: This is more responsive than BattleTech's static tooltips or FTL's pause screen. But it sits in a small div.striphint above the action strip; at 1080p with 20 ships, the player's eyes are on the board, not the strip. No audio or animation cue accompanies the hint change.

10. [NOTE] The stall watchdog is a safety net but its existence implies the animation pipeline can hang.
READ: "A stall watchdog skips a hung action after a timeout and saves a report." INFERRED: No comparator ships a watchdog because their order pipelines are deterministic. This suggests the async act() / await wait(80) chain has edge cases. It is not a UI problem per se, but the player experiences a hang as the game freezing, and "skip and report" is a developer-facing fix, not a player-facing one.

EXPLICIT CHECKS

SELECTION MODEL

The one-ship, click-to-select, click-enemy-to-fire model is the correct skeleton for alternating single-ship activations. It maps one-to-one onto the turn structure: you activate a ship, the enemy activates one, repeat. INFERRED: This is closest to BattleTech's one-mech-at-a-time initiative queue and Rogue Trader's one-voidship activation, and differs from Sins 2 (fleet-level orders) and Deadlock (squadron-level with individual overrides).

Fire-on-click as default at 20 ships: It is acceptable but not safe. The density problem is real: 20 ships plus squadrons on a hex grid means adjacent hexes are often occupied. The mitigating factor in this design is that the firing set is computed and displayed before the click (the red pulsing ring, the hover odds table). The player is not firing blind; they are confirming what the tooltip already told them. However, the absence of a confirm step between "I see the odds" and "the guns fire" is a gap. INFERRED: BattleTech solves this with a "Fire" button after target selection; XCOM 2 with a camera confirmation. The pack should add a lightweight confirm - perhaps a 300 ms hold, or a "Fire (3 weapons)" button that appears on the strip when hovering a valid target - without breaking the speed of the current flow.

Inspect-vs-fire split: This is the most fragile part of the selection model. The state machine is: if B.sel exists and canUse(B.sel) is true and firingSet returns non-empty -> fire. Else if attackMovePlan returns a valid plan -> attack-move. Else if a cantFireReason exists -> toast. Else -> inspect. The player must track which branch they are in. The visual language (red ring = fireable, no ring = inspect) is correct, but the transition between states is silent. Deselecting via Esc three times (mode -> weapon -> selection) is not something a player does deliberately in the heat of a 20-ship fight; they are more likely to Tab to the next ship, which calls selectUnit and resets the state. The risk is low but non-zero, and the cost of a misfire (no undo) makes it worth a guard rail.

ARMING

The 1-6 key model is fast and discoverable at desktop pace. The weapon rows in the panel show 1 through 6 with status (Ready / Reloading / Offline / Fired), which is clear. The armed/all toggle (B.armed=B.armed===+i?null:+i) is a clean binary.

INFERRED: Against the comparators:
- BattleTech uses weapon groups (alpha strike, called shots per group) and a called-shot picker for hit locations. More granular, slower.
- Rogue Trader uses broadside toggles (port/starboard/prow) and weapon-slot activation. Similar granularity to Voidsworn.
- FTL lets you toggle individual weapons on/off and set auto-fire targets. More persistent, less per-shot.
- XCOM 2 has no weapon selection; abilities are chosen from a menu.

Voidsworn's model is closest to Rogue Trader's. The gap is the absence of a "hold this weapon back" state: arming is exclusive (one weapon or all), so a player who wants to fire weapons 1, 3, and 5 but not 2, 4, 6 must arm 1, fire, arm 3, fire, arm 5, fire. At 20 ships with 80 ms per shot this is a meaningful time cost. A multi-select (Ctrl+click or Shift+click to add to the firing set) would close this without adding complexity.

The armed/all toggle is discoverable because the weapon rows visually highlight the armed weapon (class="armed") and the striphint does not currently mention it. INFERRED: Adding "Weapon 3 armed. Click an enemy to fire it, or press 3 again to go back to all weapons" to the striphint when a weapon is armed would close the discoverability gap.

INFORMATION

The information suite is:
- Ghost move preview with expected damage (READ: moveDmgLine)
- Hover odds by shield facing with per-weapon breakdown (READ: attackTip)
- Threat map shading enemy-reachable hexes (READ: key R, ACT.threat)
- Arc fans toggled with V (READ: B.showArcs)
- Boon and modifier display in the attack tooltip (READ: boonMods)
- Enemy intent display ("The enemy fleet is focusing its fire on this ship," READ: inspThreat)

INFERRED against the comparators:
- Into the Breach shows perfect information: every enemy attack's target, damage, and push direction before the player acts. Voidsworn's threat map is the closest analogue but is opt-in (R key) and shows hexes, not per-unit attack plans. The pack does not show a per-enemy "this ship will move here and fire at you" overlay. INFERRED: adding a per-enemy intent arrow or target marker (the pack already tracks B.aiFocus and displays it) to the board would close this gap.
- BattleTech shows hit odds per weapon, per target, with called-shot modifiers. Voidsworn matches this and exceeds it with shield-facing breakdown and expected damage numbers. BattleTech also shows heat buildup before firing; Voidsworn does not show cumulative cooldown or heat-equivalent information.
- FTL uses pause-and-inspect: the player can pause at any time, read all ship stats, and queue weapons. Voidsworn is turn-based, so pause is irrelevant, but the "read before committing" philosophy is shared. FTL shows evasion chance as a single number; Voidsworn's per-facing shield and per-weapon table is strictly more informative.

What is still hidden:
- INFERRED: The enemy's planned move and fire target for their next activation (beyond the aiFocus tag). Into the Breach shows this explicitly.
- INFERRED: The exact path a move will take. The ghost shows the endpoint and facing, but not the hex-by-hex path. If a mid-move fire is possible (READ: "movement can include mid-move fire"), the player cannot see at which hex the fire will occur.
- INFERRED: Cumulative round damage. The hover shows per-shot expected damage but not "if I fire all three ships at this target this round, it dies." BattleTech's alpha-strike calculator does this; Sins 2's fleet DPS overlay does this.

ERROR RECOVERY

READ: No undo. Esc layers (mode -> weapon -> selection). Two-tap Command confirm. Tab cycling. Right-click cancel is not in the pack (the pack mentions "right-click cancel" in the census but the code shows Esc as the cancel key; I will treat Esc as the cancel mechanism).

INFERRED against desktop tactics practice:
- XCOM 2: No undo in Ironman; in standard mode, F9/F5 save/load is the undo. The community expects save-scumming. Voidsworn's roguelite structure (run-based, permadeath) makes save-scumming inappropriate, and the no-undo stance is consistent with the genre. This is correct.
- BattleTech: Allows undoing movement before confirming the fire phase. Once you fire, it's committed. This is a middle ground Voidsworn does not offer: the pack's movement is animated immediately.
- Into the Breach: Full rewind of the entire turn. Inappropriate for Voidsworn's roguelite stakes.
- Sins 2: Orders are queued and can be re-issued before execution. Fleet movement is not committed until the order is given. This is a real-time model and does not apply directly, but the principle of "preview is not commitment" is relevant.
- Deadlock: Has a rewind timer (a few seconds) after issuing an order. This is the most applicable model: a short window during which the order can be recalled.

What to adopt: A 500 ms to 1-second "cancel during animation" window for movement (not for firing, which is thematically committed). The 80 ms inter-shot gap already serialises weapon fire; a similar gap before the first hex of movement could be cancellable. The two-tap Command confirm is a good pattern and should be extended to Ram (high cost, high variance).
What to refuse: Full undo, rewind, or save-scumming. These are incompatible with the roguelite structure and the alternating-activation tension. The Esc layering is sufficient for pre-commitment cancellation. Do not adopt XCOM's F9/F5 culture.

CAMERA AND SCALE

READ: View save/restore (camKeep/camRestore), pan-without-zoom (camShow moves 75% toward the target, keeps zoom), opening zoom-out-then-in (designer ruling, Oct 28), action-camera setting follows activations.

INFERRED:
- Sins of a Solar Empire 2: The camera is a strategic zoom: the player can zoom from galaxy view to individual ship view seamlessly. Fleet battles at 20+ ships are viewed from a high angle; the player zooms in to watch specific engagements. The camera is player-controlled and never fights the player.
- Deadlock: Uses a cinematic follow-cam during combat resolution, with the option to switch to a tactical overhead. The camera serves spectacle, not information.

Voidsworn's model is closer to Deadlock's tactical overhead but with Sins 2's "don't move the camera unless the player moves it" philosophy. The save/restore is good: the player's view is respected across the enemy turn. The pan-without-zoom is a compromise: it acknowledges that something happened off-screen without disrupting the player's chosen zoom level.

Does the camera serve selection or fight it? At 20 ships plus wings, the fixed-zoom pan is a limitation. The player selects a ship, the reach hexes are computed and displayed, but if the relevant target is at the edge of the board, the pan moves 75% of the way there at the current zoom, which may not be zoomed out enough to show both the selected ship and the target. The opening zoom-out-then-in is a good orientation beat, but the mid-battle camera needs a "zoom to fit engagement" shortcut (the pack has G.ctl.toggleTop on T key, which is a top-down toggle - this helps but is binary, not gradual).

INFERRED: Sins 2's scroll-wheel zoom with smooth interpolation is the gold standard for fleet-scale camera. Voidsworn should ensure the scroll wheel or a key-held zoom is always available and that the "center" button (ACT.center) zooms to fit the selected ship plus its nearest threat, not just the ship.

COMPARATOR VERDICTS

| Comparator | Steal | Avoid |
|---|---|---|
| BattleTech (2018) | INFERRED: Per-weapon hit-probability table with called-shot targeting; the "confirm fire solution" button between target selection and animation. | INFERRED: The slow, menu-heavy UI that makes 12-mech battles tedious; the heat-management spreadsheet. |
| Into the Breach | INFERRED: Perfect enemy-intent display on the board before the player acts (arrows, damage numbers, push directions). | INFERRED: The puzzle-box determinism that removes all probability; Voidsworn's dice are part of its texture. |
| FTL: Faster Than Light | INFERRED: The pause-and-read philosophy; the weapon-toggle persistence across turns. | INFERRED: The real-time-with-pause model, which is wrong for alternating activations; the flat evasion percentage. |
| BSG Deadlock | INFERRED: The cinematic follow-cam for spectacle moments (ram, boarding, kill); the rewind timer for order mistakes. | INFERRED: The squadron-level abstraction that hides individual ship state; the passive combat resolution. |
| Sins of a Solar Empire 2 | INFERRED: The seamless zoom from fleet overview to individual ship; the fleet-DPS overlay for target prioritisation. | INFERRED: The real-time order queue that makes individual ship tactics irrelevant; the UI density at empire scale. |
| WH40K Rogue Trader (voidship battles) | INFERRED: The broadside/port/starboard weapon-bank toggle; the narrative weight of a voidship's crew and morale. | INFERRED: The slow turn timer and the CRPG pacing that makes voidship battles feel like a chore between ground missions. |
| Star Wars: Zero Company | INFERRED: The squad-activation clarity (each unit's action is discrete and visually announced); the turn-order queue display. | INFERRED: The cinematic camera locks that remove player agency during animations. |
| XCOM 2 | INFERRED: The "action available" pips on each unit; the clear "end turn" gate with a confirmation if units have actions left. | INFERRED: The save-scumming culture; the 95%-hit-miss meme (Voidsworn's per-weapon breakdown already mitigates this). |

The single change that would most improve this battle UI:
INFERRED: Add a one-tap "Fire" confirmation to the action strip when hovering a valid target, replacing the direct click-to-fire. The strip already has the button infrastructure; adding a "Fire 3 weapons" button that appears contextually when a target is hovered would preserve the speed of the current flow (one extra click) while eliminating the misclick-to-misfire risk. The hover tooltip already shows "Click to fire 3 weapons"; making that a button instead of a click is a one-line conceptual change.

The one thing it already does better than the field:
READ/INFERRED: The per-facing shield breakdown in the hover tooltip, combined with the expected-damage-by-weapon table and the boon/modifier display, is the most informative pre-fire information screen in any desktop hex tactics game. BattleTech shows hit odds but not shield-facing damage splits. FTL shows a flat percentage. Deadlock shows nothing before resolution. Rogue Trader shows broadside arcs but not per-weapon expected damage. Voidsworn's attackTip function is genuinely best-in-class and should be protected as the design's centrepiece.

NOT CHECKED

- The Godot port's fidelity to the browser build (the pack states "the Godot port mirrors this design" but provides no Godot code).
- Touch/tablet input paths (the pack references touchWords() and G.mobile but the commissioner specifies desktop-only).
- Audio and haptic feedback during selection and firing (no audio code in the pack).
- The Classic whole-fleet mode's UI (the census mentions it exists but all code is for alternating activation).
- Performance at 20 ships with wings (the panelRenders performance tracker is present but no frame-time data).
- Accessibility: colour-blind modes, screen-reader labels, font scaling (the pack has aria-hidden on SVG but no broader accessibility audit).
- The enemy AI's activation order and how it interacts with the player's camera save/restore.
- Multiplayer or asynchronous play (not mentioned).
- The stall watchdog's timeout value and the format of the saved report.

QUESTIONS FOR THE DESIGNER

1. Is the click-to-fire path intentionally irrevocable, or would you accept a 300 ms hold-to-fire or a strip-button confirm? The stakes: at 20 ships, a single misclick that fires all six weapons at the wrong target and braces the ship (firing prevents bracing, READ) can cascade into losing the battle, and the no-undo policy means the player has no recourse.
2. Should the threat map (R) be on by default for the first round of each battle, or at least pulse when a ship is selected? The stakes: the information is critical for positioning but is opt-in behind a key press; a new player in a 20-ship fight may not discover it until they have already moved into a kill zone.
3. What is the intended interaction between Tab cycling and the action strip's "Done with ship" button? The stakes: if Tab skips done ships (READ: ready=list.filter(u=>!isDone(u))), a player who has 17 of 20 ships done will Tab through only 3 ships; but if all 20 are done, Tab falls back to the full list and cycles through dead and finished ships, which is confusing and suggests the "end activation" flow should auto-advance rather than requiring Tab.

End of report.
