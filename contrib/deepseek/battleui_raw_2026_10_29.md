Chair note: filed verbatim from the DeepSeek DeepThink run of Oct 29, 2026 (toggles verified on, clean first chat), except em dashes and en dashes in the model's text are normalized to hyphens.

1. Proof of reading
Read: EVIDENCE PACK title line; THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE; code slices ui3d.js 105-140 (roster/weapon/panel), 161 (keysHelp), 388-402 (selectUnit/cancelAction), 413-431 (firing set/click-to-fire), 466-500 (move damage/hover odds), 501-535 (onKey/arm), 665-683 (actionStrip/camera/help), and 642-652 (TIPS).

Overall verdict: FRICTION - the pre-commit information layer is unusually strong, but one-click irreversible fire-all with no undo is the wrong default for a 20-ship hex battle.

2. Findings
All comparator claims below are INFERRED unless explicitly present in the pack.

[BLOCKER] Fire-all is the default attack gesture and is irreversible. READ: "Clicking an enemy ship while a usable friendly ship is selected FIRES on it"; "there is no undo"; unarmed means "fire everything that bears." At up to 20 ships, a wrong click commits every bearing weapon, runs an 80 ms sequence, and the ship cannot brace afterward. INFERRED: desktop tactics/space games generally separate target selection from irrevocable resolution or provide a confirm/undo step. Fix: require confirmation for fire-all and attack-move, or make single-weapon firing the default and fire-all an explicit command.

[FIX] The inspect-vs-fire split is a modal ambiguity. READ: "Clicking an enemy with nothing usable selected inspects it," but with a usable ship selected the same click fires, attack-moves, or toasts a reason. Roster clicks on enemies clear selection and inspect. INFERRED: at 20 ships, inspecting enemies is constant; a hidden state that turns inspection into irreversible fire is a misclick generator. Fix: make left-click inspect always, and fire via explicit button/second click/confirm.

[FIX] Arm-one-weapon is fast but under-signposted and non-persistent. READ: keys 1-6 or weapon rows arm; selecting clears B.armed; after firing B.armed is cleared; keysHelp says "1-6 pick weapon" but not "no weapon = fire all." INFERRED: desktop weapon-group/called-shot systems expose a persistent mode or groups. Fix: visible Fire All/Single toggle, remember last mode per ship, show armed weapon in cursor/target line, and allow simple weapon groups.

[FIX] Error recovery is inconsistent with the commitment model. READ: Esc layers mode - armed weapon - selection; Command gets a two-tap 6 s confirm; "firing is committed click by click." INFERRED: irreversible multi-weapon fire, ram, and boarding deserve the same confirm discipline as Command. Adopt pre-commit confirmation or undo-before-animation for these; refuse full undo after animations. Tab cycling and Esc layering are good. The question lists right-click cancel, but the code slices do not show it; not verified.

[NOTE] Information is strong but not perfect-information. READ: ghost move with expected shield/hull damage, hover odds by facing, threat map, arc fans, boon modifiers. INFERRED: closest to BattleTech's odds display plus Into the Breach's preview discipline, not FTL's pause-and-inspect. Still hidden: exact enemy activation order, AI target intent, damage/crit tails, overkill allocation. Threat map shows reach, not intent.

[NOTE] The help card undercovers the action strip. READ: actionStrip can carry Done, Ability/Launch, Command, Ram, Board, Wings stance, Brace, Center, and ?; stripHelp "explains six buttons in one text block." INFERRED: context buttons change at 20-ship scale, so static help becomes stale. Fix: dynamic help keyed to visible buttons and tooltips.

[NOTE] Camera is calm but may fight scale. READ: camKeep/camRestore, camShow pans "most of the way toward it but never changes zoom," opening zoom-out then zoom-in. INFERRED: Sins 2 and Deadlock-style fleet cameras need overview plus action readability; at 20 ships plus wings, pan-without-zoom preserves orientation but can leave off-screen action tiny/edge-bound. Camera mostly serves selection via focus/Tab/roster; add optional edge indicators or soft action zoom.

[NOTE] Terminology and shortcut docs drift. READ: action strip says "Done with ship," while keysHelp says "Enter end turn/end activation"; keysHelp omits X ram, G board, F focus, Home reset, T top bar. Minor, but at desktop pace inconsistent labels slow learning.

3. Explicit checks

SELECTION MODEL. One-ship selection is right for alternating single-ship activation; Tab, roster, and focus make 20 ships manageable. Fire-on-click as default is not right at 20 ships because it is irreversible and hides weapon-level choice. The inspect-vs-fire split fails: the same click means inspect or fire depending on selection state, and inspection is a common, low-risk action. Keep one-ship selection; make fire explicit or confirmed. INFERRED comparator basis: BattleTech/XCOM-style confirmation, Into the Breach-style preview clarity.

ARMING. Keys 1-6 plus rows are fast at desktop pace, better than menu diving. But the armed/all toggle is not discoverable enough: no visible mode, no "fire all" reminder in keysHelp, and arming resets on selection/fire. Single-weapon arming is adequate; weapon groups and a persistent toggle would be better. Avoid deep called-shot submenus; steal weapon-group clarity. INFERRED.

INFORMATION. The previews are closer to BattleTech's odds displays and Into the Breach's pre-commit clarity than to FTL's pause-and-inspect. They still hide exact enemy activation order, target intent, damage distribution/crit tails, and overkill. Threat map is reach, not intent. This is above field average, but not perfect information. INFERRED.

ERROR RECOVERY. No undo is a defensible commitment only if commitment gestures are deliberate. Here fire-all is one click, so no undo is too strict. Esc layering, Tab cycling, and Command's two-tap confirm are good. Adopt pre-commit confirmation for fire-all/attack-move/ram/board; refuse full undo after animation. Right-click cancel not verified in slices. INFERRED.

CAMERA AND SCALE. View save/restore and pan-without-zoom are respectful of player control; opening zoom-out then in gives orientation. At 20 ships plus wings, pan-without-zoom may make off-screen enemy actions hard to read. Sins 2/Deadlock comparisons are INFERRED. Camera mostly serves selection, but scale stress suggests optional edge cues or a brief action zoom.

COMPARATOR VERDICTS. All INFERRED.

- BattleTech (2018): Steal odds/facing readability and weapon clarity; avoid slow confirmation ceremony and camera theatrics.
- Into the Breach: Steal deterministic previews and undo-before-commit; avoid perfect-information puzzle framing that would erase fleet uncertainty.
- FTL: Steal pause-and-inspect clarity and targeting discipline; avoid real-time pause micro that conflicts with alternating activations.
- Battlestar Galactica Deadlock: Steal fleet-scale framing and ordnance readability; avoid cinematic camera that takes control.
- Sins of a Solar Empire 2: Steal zoomable fleet overview and selected-fleet focus; avoid RTS selection-box/command-card logic for single-ship activations.
- Rogue Trader voidship battles: Steal shield-facing/arc presentation and weighty weapon resolution; avoid opaque rule stacking and slow animation commitment.
- XCOM 2: Steal explicit shot confirmation and hit/crit breakdown; avoid excessive miss randomness and surprise activation rules.

Single change that would most improve the battle UI: make fire-all/attack-move a confirmed or undoable pre-commit action, or make single-weapon fire the default. One thing it already does better than the field: contextual expected-damage preview by shield facing plus a threat map - stronger than typical odds-only displays.

4. Not checked
Actual rendering/legibility at 20 ships plus wings; performance and animation timing under load; tutorial/onboarding effectiveness; full input bindings including right-click cancel; all code paths for boarding/ram/abilities; balance and AI quality; audio, localization, accessibility, gamepad; exact shipped versions of comparators; Star Wars: Zero Company comparison (no reliable basis in pack or my shipped-desktop knowledge).

5. Questions for the designer

- In normal play, how often do you expect players to arm a single weapon versus fire-all? Stakes: if fire-all dominates, the weapon-level UI is mostly decorative and the misclick risk dominates.
- Would you accept a pre-commit confirmation or undo-before-animation for fire-all and attack-move? Stakes: this determines whether fire-on-click can remain the default at 20 ships.
- At 20 ships plus wings, when an off-screen enemy acts, is the priority preserving camera orientation or showing the action clearly? Stakes: pan-without-zoom protects orientation but may make the action unreadable.
