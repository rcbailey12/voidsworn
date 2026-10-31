# Red team audit, uiux persona: Argon leg

Chair header: Argon (Gemini, Argon High) leg for the Oct 30, 2026 red team audit, run from the uiux evidence pack and the persona leg prompt. Text below is the model report verbatim, with em dashes normalized to ASCII where they appeared.

1. Dead-End Meta-Progression UI and Silent Loadout Deletion Miscalibrated as Copy Defects

What breaks or underperforms: INFERRED: The Oct 27 text synthesis verdict ("OVERALL VERDICT: NOT READY as player-facing copy, with no BLOCKER surviving at that weight") is overturned from the UI/UX seat. OBSERVED: Locked admiral cards instruct the player to unlock them "in Legacy", a screen renamed Progression, behind which the purchase buttons do not exist" because "buyAdmiral and buyLegacy have no UI". OBSERVED: Four hull variant cards "delete weapons silently" where "Four variants whose descriptions omit a removed weapon or ability." OBSERVED: In the shipwright event, "The text promises a second ship fully repaired; the index arithmetic heals the wrong one". INFERRED: Treating missing unlock buttons and unannounced weapon removal on space ships as non-blocking prose issues hides broken UI commitment surfaces behind a copy-editing label.

The evidence: text_synthesis_2026_10_27.md Finding 11 ("buyAdmiral and buyLegacy have no UI"), Finding 4 ("Variant cards that delete weapons silently"), and Finding 2 ("the index arithmetic heals the wrong one").

What it costs the game: In a generational roguelite where "about 80 percent of runs are lost by design" and "Renown is the between-runs currency for unlocks and respecs.", players hit a functional dead end when attempting to spend progression currency on admirals or legacy upgrades, and inadvertently strip weapons off their space ships when purchasing hull variants.

2. In-Battle Tip Kill-Switch Lacks an In-Battle Recovery Toggle, and Assembled Campaign Tips Repeat the Modal-Stack Trap

What breaks or underperforms: OBSERVED: firstrun_synthesis_2026_10_29.md claims "DeepSeek's "no shown recovery path" for tips is pack-true and code-false; the Settings row exists." INFERRED: That correction is overturned for the in-battle HUD where the failure actually occurs. OBSERVED: In ui3d.js, ACT.tipOk chains modals via setTimeout(tutorialCheck,400) so "Battle 1 can stack up to five modal tip cards 400 ms apart", while ACT.tipOff sets o.tipsOff=true. OBSERVED: Inspecting buildHud() and refreshTop() (ui3d.js lines 59-83) shows that #setpanel contains 18 buttons (b_arcs through diag) and zero button or row to reset o.tipsOff during battle. INFERRED: Furthermore, following the firstrun recommendation ("let tutorialCheck serve the map layer") using the 16 assembled campaign tips ("The set mirrors the shipped TIPS shape, [id, title, text], ids prefixed c_") will fire a 400 ms modal chain on the first sector map (c_map, c_nodes, c_elite, c_clock, c_credits, c_verb), and clicking "Hide tips" in either layer sets o.tipsOff=true globally.

The evidence: ui3d.js lines 62-63 (#setpanel button inventory), line 654 (if(o.tipsOff) return;), line 661 (setTimeout(tutorialCheck,400);), line 662 (o.tipsOff=true;), and tutorial_assembled_2026_10_29.md.

What it costs the game: A single reflexive click on "Hide tips" during Battle 1's 400 ms modal burst permanently silences all 10 battle tips and all 16 campaign tips with no recovery control inside the battle #setpanel menu.

3. Assembled Campaign Tutorial Tips Still Fail to Decode the Map's Boon Badge or Frame Run 1 Before Defeat

What breaks or underperforms: INFERRED: The claim in tutorial_assembled_2026_10_29.md that the 16 c_ tips provide "the copy half of the answer" to the first-run teaching failure is refuted by comparing the assembled copy against the exact blockers in firstrun_synthesis_2026_10_29.md. OBSERVED: The firstrun synthesis established that the map's boon badge "strips a node to a glyph, a patron short name, and an unexplained star", so routing choices "are made blind, even though the pick screen itself explains everything". OBSERVED: In tutorial_assembled_2026_10_29.md, c_nodes states "The map shows node kinds at a glance: battles, elites, the boss, events, rest, and shipyards." (omitting boons and patrons), while c_boon ("Boon offers") explains the reward pick screen ("Boons are a patron's permanent in-run gifts. Rarity is strength. Declining pays credits") without mentioning the map glyph or star. OBSERVED: Similarly, while firstrun_synthesis faults the opening because "Nothing in the first minutes frames the game's actual contract", the assembled set places that framing in c_loss ("Losing the fleet ends the run, not the war."), which only triggers after the fleet is lost.

The evidence: firstrun_synthesis_2026_10_29.md ("never printing the word "Boon" or what the star means") versus tutorial_assembled_2026_10_29.md (c_nodes, c_boon, and c_loss).

What it costs the game: Even after wiring the 16 assembled campaign tips, first-run players still route blindly past unexplained patron-star nodes on the map and receive zero generational framing until after their first run ends in defeat.

4. Phased Activation Ruling Compounds Multi-Weapon Sequencing Friction and Invalidates Shipped Battle TIPS

What breaks or underperforms: OBSERVED: The settled battle UI ruling establishes phased activation: "a move beat with free rehearsal and inspect-only enemy clicks, then a fire beat" with "an explicit Fire control" and "mid-move fire as an explicit declared choice". OBSERVED: battleui_synthesis_2026_10_29.md Finding 1 documents that "the armed weapon resets after one shot and on every selection change", making shield-breaker-before-hull-breaker salvos "three manual steps per ship", while ui3d.js line 647 (target tip) still instructs players: "Hover one for hit odds and expected damage, then click to fire every weapon that bears." INFERRED: Under phased activation, a space ship that wants to fire before moving or while stationary must explicitly transition out of the move beat (or declare mid-move fire) and then manually re-arm individual weapons across resets for every activation across "20 ships is a typical-battle target, not a cap.", while the shipped target tip teaches a left-click fire gesture that now only inspects during the move beat.

The evidence: battleui_synthesis_2026_10_29.md (Addendum ruling and Finding 1) and ui3d.js line 647 (TIPS target entry).

What it costs the game: Implementing phased activation without fixing weapon-arming persistence and rewriting the battle TIPS replaces accidental attack-moves with severe click inflation per ship activation and actively misleads new players on how firing works.

5. Opening Camera Zoom-Out Ruling Does Not Fix Off-Screen Enemies in Threat View on Round 2+

What breaks or underperforms: INFERRED: The claim in hud_synthesis_2026_10_27.md that Ryan's Oct 28 camera ruling "settles the framing question in the wider form: not only the threat view but the battle start itself" is overturned. OBSERVED: The ruling specifies: "The opening camera shows the whole battlefield and the enemy fleet, then zooms in on the player's fleet." and "Edge indicators are not the chosen direction." OBSERVED: hud_synthesis_2026_10_27.md Finding 1 states that in 04_threat_topdown.png, "the threat view shows three friendly ships and no enemy while the narration reports contact", and ui3d.js line 655 gates the threat tutorial tip to threat:(B.round||1)>=2. INFERRED: Because the opening camera zooms back in on the player's fleet before play starts, and G.follow ("Camera moves to each ship as it activates", ui3d.js line 63) pans without zooming out ("the pan-without-zoom camera can leave an enemy activation half off-screen at 20 ships"), toggling Threat (R) on Round 2 or later still leaves distant enemy space ships outside the viewport with no edge indicators.

The evidence: hud_synthesis_2026_10_27.md (Finding 1 and Oct 28 ruling), battleui_synthesis_2026_10_29.md (Finding 7), and ui3d.js lines 63 and 655.

What it costs the game: When players press R in Round 2+ as taught by the tutorial, they see shaded threat hexes ("the darker the hex, the more damage is waiting there") without seeing which enemy space ships project that threat.

6. Browser Battle Settings Menu Exposes Developer Debug Harnesses and Phone Copy in a Flat 18-Button Dump

What breaks or underperforms: OBSERVED: The shared core pack states "PC only" and "the browser build is the playable truth today", yet none of the prior syntheses flagged the contents of #setpanel in ui3d.js. OBSERVED: In ui3d.js lines 62-63 (buildHud), clicking #b_set (Settings) opens #setpanel, an ungrouped 18-button container headed only by "Battle view" that mixes view toggles with raw developer and LLM debug controls: "Copy your recent play data to paste to Claude", "Save a snapshot of the game state for debugging", "Render diagnostics (Shift+D)", and "Test hulls made from the concept art (Hegemony dreadnought for now)". OBSERVED: The same panel also ships phone-specific copy on a PC-only build: "Show the battle log over the board (phones)" and "Medium: tuned for phones". INFERRED: Mixing 18 uncategorized camera, graphics, AI difficulty, accessibility, mobile, and developer-debug buttons into one flat popover degrades scannability and interface trust.

The evidence: ui3d.js lines 62-63 (#setpanel markup) and lines 70-78 (refreshTop button labels).

What it costs the game: Players opening Settings during combat to adjust animation speed or photosensitivity toggles (Reduce flashing, Reduce screen shake) must scan past internal Claude telemetry buttons, concept-hull test toggles, and phone tooltips.

7. Identical Hex Colors for Distinct Board Zones and Color-Only State Signals Across Browser and Godot Builds

What breaks or underperforms: OBSERVED: accessibility_review.md confirmed PARTIAL (board FAIL) on color-blindness in Godot because "Exit green and guard red sit at about 1.46:1 and 1.23:1 composited, a red-green pair". OBSERVED: Auditing ui3d.js line 89 (ZONE_INFO) in the browser build reveals an even sharper defect: exit uses col:'#7dff9b', while texit ("Transport exit") and guard ("Station perimeter") both use the exact same color string, col:'#e07a70'. OBSERVED: In addition, hud_synthesis_2026_10_27.md Finding 3 confirms "The Engagement legend is collapsed and unlabeled in all nine images", ui3d.js TIPS (lines 643-652) identify states by color ("green ring", "Gold hexes", "cyan bars", "Amber is hull", "pulsing red ring", "glows gold"), and objectiveLabel() (line 85) signals critical station damage (o.hp<=2?'blood':'dim') by color class alone. INFERRED: Assigning #e07a70 to both texit and guard makes the two zones visually identical by color even for players with normal color vision.

The evidence: ui3d.js line 85 (objectiveLabel), line 89 (ZONE_INFO), lines 643-652 (TIPS), hud_synthesis_2026_10_27.md Finding 3, and accessibility_review.md Ranked Fix 3.

What it costs the game: Color-blind players cannot reliably separate green friendly selection rings from red enemy target rings or green exit hexes from red perimeter hexes, and no player can distinguish "Transport exit" from "Station perimeter" by hex color when the legend is collapsed.

8. Turn-Versus-Activation Wording Drift and Four-Way Commit Button Mutation in Live Browser Code

What breaks or underperforms: OBSERVED: hud_synthesis_2026_10_27.md noted "header and wording drift across capture batches (activation vs turn, blackletter vs serif)" in Godot captures; ui3d.js proves this drift is hardcoded in the browser HUD. OBSERVED: In ui3d.js, refreshTop() sets $('turnlbl').textContent=B.over?'':B.side==='player'?'Your turn':'Enemy turn' on line 69, then overwrites #turnlbl on line 80 with `Your activation (${pendingP().length} ready)` (or `Your move (${pendingP().length})` on G.mobile). OBSERVED: On line 79, #endbtn mutates between four labels ('End activation', 'Pass', 'Continue', 'End turn'), while the fired tip (line 648) instructs "press End activation (Enter) and the enemy moves one of theirs.", the action strip hint (battleui_synthesis Finding 3) says "Nothing left to do: tap Done with ship.", and TIPS use "turn" to mean both one ship's activation ("hit next turn", line 651) and a full round ("recharge each turn", line 646). INFERRED: Calling the same unit commitment action "End activation", "End turn", "Pass", "Continue", and "Done with ship" across adjacent UI elements fractures the player's mental model of alternating activations.

The evidence: ui3d.js lines 69, 79, 80, 644, 646, 648, 651, and battleui_synthesis_2026_10_29.md Finding 3.

What it costs the game: Players cannot tell whether effects that "recharge each turn" or show "Where the enemy can hit next turn" trigger after the next ship activates or at the start of the next round.

9. Core Combat Hotkeys and Fleet-Wide Retreat Penalty Hidden in Mouse-Only title Attributes

What breaks or underperforms: OBSERVED: accessibility_review.md Ranked Fix 4 and battleui_synthesis_2026_10_29.md Finding 4 flag missing hotkey documentation; inspecting ui3d.js reveals how the browser build hides both hotkeys and destructive action costs. OBSERVED: In ui3d.js line 65, #camhint lists only Right-drag, Left-drag, WASD, Wheel, F, and T, while R (Threat), V (Arcs), Space (Speed), and Shift+D (Diagnostics) appear only in HTML title attributes on buttons inside #btop and #setpanel.hidden (lines 61-63), and Q, E, 1-6, X, G, and Enter appear only inside transient TIPS cards (lines 645-650). OBSERVED: In ui3d.js line 64, <button data-act="c3retreat" id="b_retreat" title="Jump the fleet out. Every surviving ship loses 10% hull.">Retreat</button> sits directly beside <button class="primary" data-act="endTurn" id="endbtn">End turn</button>, hides "Every surviving ship loses 10% hull." in its title tooltip, and on line 82 sets $('b_retreat').disabled=B.busy||!!B.over without checking B.side!=='player'. INFERRED: Relying on hover title attributes makes hotkeys and the 10% hull retreat penalty invisible to keyboard-only users, while placing an unconfirmed Retreat button next to End turn creates a severe misclick hazard.

The evidence: ui3d.js lines 61-65 (#btop, #setpanel, #camhint) and lines 81-82 (endbtn and b_retreat disabled logic).

What it costs the game: A single misclick adjacent to End turn aborts a campaign battle and inflicts a 10% hull penalty on every surviving space ship without an on-button warning or confirmation step.

10. Admiral's Command Visual Cue and Growth Rules Contradict Between Screen, Top Bar, and Tutorial Card

What breaks or underperforms: OBSERVED: hud_synthesis_2026_10_27.md Finding 4 confirmed in Godot captures that the tutorial card "says the Command glows gold; in every image Command is dark and Pass or End turn is gold". OBSERVED: ui3d.js shows the exact mechanism and an additional text contradiction in the browser build: the resolve tip (line 649) states "Your admiral's signature move is ready: it glows gold on the strip." and "It grows each round you wait and when you lose a ship". OBSERVED: However, in ui3d.js lines 61 and 77, the gilt gold styling (<span class="gilt">Command</span>) is applied to #resolvelbl, a non-button <span> in #btop whose title tooltip says "growing each round you hold it" (omitting ship loss), while the clickable primary button glowing gold on the HUD is #endbtn (<button class="primary" data-act="endTurn" id="endbtn">). INFERRED: Rendering the gold indicator on a non-interactive top-bar <span> while telling the player "it glows gold on the strip" directs the player's eye to the gold Pass or End turn button instead of the dark Command button.

The evidence: hud_synthesis_2026_10_27.md Finding 4 and ui3d.js lines 61, 64, 77, and 649.

What it costs the game: When Admiral's Command becomes ready, players following the tutorial cue click the only gold button (Pass or End turn), ending their activation instead of firing their once-per-battle signature ability.

Verdict

Seat verdict: CRITICAL COMMITMENT AND ONBOARDING FRICTION across both browser and Godot builds: the pre-commit tactical hover math is strong, but the commitment surfaces, recovery controls, and teaching hooks repeatedly betray player intent.

Single most important attack: Overturning both the firstrun synthesis claim that in-battle tip recovery is merely a discoverability issue (ui3d.js #setpanel has 18 buttons including developer Claude debuggers and zero control to re-enable o.tipsOff) and the assumption that the 16 assembled c_ tips solve campaign onboarding (they still omit the map's blind patron-star badge, delay generational framing until c_loss after defeat, and will trigger a 400 ms modal stack on the map screen tied to the same global Hide tips kill switch).

Not checked

Action strip, roster, and panel implementation below line 90 and line 665 of ui3d.js: The pack excerpts ui3d.js lines 58-102 and 642-665; the body of refreshRoster(), refreshPanel(), actionStrip(u) after line 665, and wingSel handling at ui3d.js:425 could not be inspected directly from code.

CSS stylesheet and computed contrast in the browser build: No CSS file is included in the pack, so exact luminance contrast ratios for browser classes (.gilt, .blood, .dim, .muted, .primary, .on) and focus outlines in the Babylon.js build could not be measured firsthand.

Godot hud.gd, title.gd, and crest.gd source files and the nine Oct 27 PNG/JPG captures: These were evaluated through the synthesis filings in the pack rather than direct source or image inspection because the raw .gd files and screenshots are not attached in uiux_pack.txt.

Unattached content assemblies: The 216 skill-tree texts, 33 event variants, 41 Nemesis lines, 30 firstrun framing units, and the Eclipse battleship entry listed in the claims register are not included in uiux_pack.txt and could not be audited line by line.
