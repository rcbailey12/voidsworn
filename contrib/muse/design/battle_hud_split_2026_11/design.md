# Battle HUD split: design study for issue 1006

Chair: Rey (Muse). Date: Nov 17, 2026. Code measured against main 1c6378918f (hud.gd, ledger.gd, ui_scale.gd, FINDINGS R210, R218, R191, R177).

Ryan's ask (Nov 17, 2026): the battle sidebar still feels large. Draft concepts that split it vertically, some items in a top bar and some in a bottom bar, so the screen is blocked less, keeping the general approach to the UI and evolving it. He shared three tactics-game layouts as references: turn and objectives top left with menu top right; a bottom strip with the selected unit's card at the left, the fleet as a row in the middle, and the weapon table at the right; slim top bars, small side lists, grouped command buttons along the bottom.

Method: one evidence pack (evidence_pack.md) carrying today's full rail inventory from the E1 capture, the geometry, the scale law, and the rules. Five legs ran under their gates on the cloud browser: blind Rey (pack only, written before the others returned), DeepSeek (DeepThink on, Search off, verified both ends), Qwen (Qwen3.8-Max, selector and header verified), Grok (Fast, verified both ends), Flash (Gemini, "Quick answers 3.5 Flash-Lite" selected and verified both ends). Every leg adopted or refined the seeded Ledger Split except Flash, which evolved the seeded Command Deck. The mockups are the chair's drawings of the three chaired concepts, in the game's real faces (Big Shoulders Display, Barlow Semi Condensed, Azeret Mono) with the palette sampled from the capture itself.

Mockup base, stated plainly: the pictures are drawn over the Board's own 1080p battle capture (docs/shots/ui_battle_ember/full_1080/E1_ledger_1080.png). In that capture the board's left flank sits under the rail veil, so the region the rail vacates is reconstructed as scene (dark starfield and a soft nebula wash from the capture's own centre nebula). Ship positions in the freed region are indicative, not captured. Everything from x=700 right is the untouched capture, including the real top-right cluster and, where a concept keeps it, the real log.

## Recommendation: KEEL (DeepSeek's leg, chaired as drawn)

Build KEEL. One bottom decision shelf, two small top clusters, no full-width top bar, the log folded into the shelf's right end. It is the only leg that placed every rail item at coordinate level, kept the status line visible, priced its own screen share honestly (hard veil and fade counted separately), and named its real weakness (small windows) instead of waving at it. The full-width top bar in Grok's and Qwen's variants veils the top edge of the board along its whole width to hold two lines of context; KEEL holds the same context in a 560 px cluster and leaves the top middle clear, which is also where its phase banner goes. From WATERLINE, take one detail: at low scale factors the damage-split line collapses behind a hover on the odds figure (SAY LESS), which is KEEL's compact-mode answer for short windows alongside the taller shelf.

What KEEL buys, in the study's terms: the full-height left band is gone. The board's middle is one clear field from y=128 to y=840 at full width, both flanks open for the whole battle, and the decision order survives as a single left-to-right sweep along the bottom with the fleet as the foot of the sweep, where the rail's foot used to be.

## Screen share, one accounting for every concept

Shares are geometric extent of veiled area at the 1920 by 1080 design size (Qwen's leg flagged, correctly, that a gradient veil's opacity-weighted dimming is less than its extent; that caveat applies to today's band and to every concept alike, so the table compares extents like for like). Today: left veil band about 30% plus top-right cluster and log about 3%, total about 33%.

| Concept | Veiled extent | Notes |
| --- | --- | --- |
| Today (E1 Ledger) | about 33% | 30% full-height left band + 3% corners |
| KEEL | 24.5% hard, about 27.9% counting fades | bottom shelf 20.0%, top clusters 4.5% |
| WATERLINE | about 17% | bottom veil 10.7% (fades out by x=1580), top patches about 3.2%, log corner about 3% |
| HORIZON DECK | about 16% | strip 9.0%, pill about 1%, fleet anchor about 1.4%, moved log patch about 2.9%, top-right about 1.9% |

KEEL covers the most of the three concepts and is still the pick: the contest was never only about area. WATERLINE and HORIZON DECK buy their smaller shares with a tighter bar (144 and 130 px against KEEL's 216) and both pay for it in the same places: the status line demoted to a hover, a fleet section too narrow for its own contents, and a log corner squeezed or moved. KEEL's extra height is what keeps every item visible at the 17 px floor without new hiding rules.

## Concept 1: KEEL (the pick)

Picture: mockups/keel.png

Geometry: bottom shelf veil x=0, y=864, w=1920, h=216, fading upward over 24 px. Top-left veil x=40, y=32, w=560, h=96 (turn header and objective). Top-right cluster as today, x=1460, w=420. Clear field about y=128 to y=840 full width, plus the top-centre gap. Columns on the shelf: A ship x=40 w=360; B guns x=416 w=340; C target and odds x=772 w=390; D FIRE, orders, Command x=1180 w=360; log inside the shelf at x=1560 w=320; fleet strip along the shelf's foot, y=1040.

Placement (every rail item):
1. Turn header: top-left veil, "Round 1" then "Your turn" (ember) with "3 of 3 ships to act".
2. Objective: under the turn header, same veil.
3. Ship name: shelf column A, Big Shoulders 34 px.
4. Ship class: column A, under the name.
5. Hull and Move: column A, one line under the class.
6. Shield cross: column A under hull, four facings at 20, Glacier only.
7. Status line: column A under the cross, two lines at 17 px, visible (not hover).
8. Guns table: column B, one row per weapon (three rows in the capture).
9. Target: column C, name in Nemesis red when the target is the Nemesis.
10. Odds and damage split: column C under the target.
11. FIRE box: column D, the one box, ember outline, key Enter.
12. Orders row: column D under the FIRE box.
13. Command row: column D under orders.
14. Fleet: the shelf's foot strip, one horizontal line, acting ship ember-marked.
Tree prompt: a local veil card under the top-left cluster (x=40, y=136, w=560), question and keyed options; the shelf does not move.
Retreat: low-emphasis text control above the log, right aligned, one key.
Phase banner: temporary top-centre veil in the clear gap (x=620, w=820), centred text.
Enemy line, Heat, Menu, Nemesis panel: unchanged, top right. Log: inside the shelf's right end (see the cost below). Hover detail: unchanged (SAY LESS).

Decision order: context at top left, then the eye drops to the shelf's left and sweeps right: ship, hull, shields, status, guns, target, odds, FIRE, then down column D to orders and Command, then the fleet at the foot. No return trips to the left.

1440p and 4K: shares are resolution-independent under the scale law; at 1440p the shelf is about 287 px rendered, at 4K about 432 px, and fine detail (the shield cross at about 80 px at 4K) gets easier. The binding case is the small window near k=0.6, where the 17 px floor stops the shelf shrinking with the window: KEEL needs the compact mode named above (damage split behind hover, or orders and Command in a second small veil). The Board should rule the compact mode as part of adopting KEEL, not discover it later.

Costs: the shelf veils the board's lower edge across the full width (today the left flank pays instead); the shelf is dense, and long target or damage strings wrap at 17 px in column C; the log loses width (320 px inside the shelf against the roughly 600 px strip it has today), so the visible log lines truncate sooner, with the full log still one key away as today. The leg's own coordinates put the status line's second line 4 px into the fleet strip; the mockup resolves it by tightening the status leading, and a build should give the shelf's foot 8 px more.

## Concept 2: WATERLINE (Qwen's leg)

Picture: mockups/waterline.png

Geometry: top bar 72 px with veil only under its two clusters (left cluster x=40 to 460, right cluster as today, the middle 900 px bare). Bottom bar y=936, h=144, its veil fading horizontally to nothing at x=1580 so the log keeps its own corner (x=1600 to 1880). Five sections: ship x=40 w=264; guns, target, odds x=328 w=320; FIRE x=672 w=264 (box 220 by 48); orders and Command x=960 w=300; fleet x=1284 w=256.

Placement differences from KEEL (everything else follows the same sweep): the status line (item 7) is hover-revealed over the ship name, not standing text; Retreat is a standing but dimmed entry in the Command row; the tree prompt centres in the open middle over a radial veil; the phase banner centres in the open middle at 48 px and the shelf dims its actionable rows during the enemy turn; the log is untouched in its corner.

Costs: the slimmest full-coverage bar, and it shows. The shield cross shrinks to 56 px and loses its pause; the fleet section at 256 px cannot hold three ship names side by side at 17 px (the mockup stacks them, against the leg's own horizontal spec; the row needs about 450 px); the status line's demotion changes E1 behaviour, where the line stands on screen; at k below 0.75 the leg itself collapses the damage split behind a hover. Its share figure of about 9% in the leg is opacity-weighted and is not comparable to the geometric table above; on the shared accounting it is about 17%.

## Concept 3: HORIZON DECK (Flash's leg)

Picture: mockups/horizon_deck.png

Geometry: the seeded Command Deck's floating strip anchored to the bottom edge: strip x=240 to 1680, y=920 to 1050 (1440 by 130). A top-left pill (x=40, y=40, drawn 344 by 70; the leg's 320 by 50 does not hold two lines at the floor) carries turn and objective. The fleet anchors separately at the bottom-left corner. Top right unchanged.

Placement differences from KEEL: ship, shields at the strip's left zone; guns, target, odds at its centre; FIRE at the strip's right end with orders and Command under it; the status line (item 7) is hover-only; Retreat moves to a utility cluster beside the log; the tree prompt is a modal card above the strip's centre.

Costs: the strip leaves both lower corners open, its one real advantage, and pays for it three ways. It floats in from both edges, so it veils live board at the lower centre while the corners it frees are the board's least contested ground. Its right end covers the log's corner: the leg says the log stays where it is, but the strip occupies that footprint, so the mockup moves the log above the strip's right end, a relocation the leg did not price. The fleet anchor at 180 px wide cannot hold the fleet's names either (the mockup draws them at natural width, about 260 px). The leg's share arithmetic also slips: its parts sum to about 13.5% on the shared accounting, not the 18% it states (its error runs against itself; the concept is cheaper than the leg claims, and still third).

## Considered and not chaired

Grok's LEDGER SPLIT (improved): a full-width top bar (72 px) plus a 220 px full-width bottom bar with the fleet as a footer. Sound, and the closest cousin to KEEL; the chair takes DeepSeek's cluster argument over it (a full-width top veil buys nothing the two clusters do not) and its geometry is otherwise KEEL's with a taller bottom bar.
Blind Rey's BOOKENDS: slim top strip (64 px) with the fleet as chips in the top strip's centre, bottom strip 144 px. The fleet-in-the-top-bar idea matches Ryan's reference screenshots most literally, and it fails on capacity: chips cap out near eight ships and the top strip then crowds the Nemesis line. Worth revisiting if fleet sizes stay small.
Pure COMMAND DECK (the brief's seed (b), unanchored): rejected by every leg that addressed it, the chair included: four separate cards fragment the reading order and the floating strip veils the board's centre-bottom for no edge benefit.

## Chair notes on the legs (slips recorded, nothing rests on them)

Flash: screen-share percentages inconsistent with its own geometry (corrected in the table above); its phase banner description contradicts itself (sliding from under the top-left pill, and centred); it places the log unchanged inside the strip's footprint. Qwen: its 9% share is opacity-weighted where the pack's figures are geometric (it flags the same point about the pack fairly, and the chair has put every concept on the geometric accounting); its fleet section is under-width for its own spec; its build estimate is stated in human days and the chair does not carry it (estimates in this project are stated in agent terms). DeepSeek: a 4 px overlap between the status line and the fleet strip in its own coordinates, resolved in the mockup. Grok: its bottom bar's internal widths sum past the screen once margins are added; the chair used KEEL's columns instead. Blind Rey: its Ledger Split shares were estimates without coordinate placement; KEEL supersedes them.

## Board follow-ups

1. Rule KEEL's compact mode for small windows (k under about 0.75) as part of the adoption: damage split behind hover first, then orders and Command to a second veil.
2. Confirm the status line stays standing text (KEEL) rather than hover (WATERLINE, HORIZON DECK). The chair reads R177 as permitting hover for secondary detail, and the status line in E1 is primary; this is a Board call.
3. Guns overflow: the shelf holds three weapon rows comfortably and four at a squeeze; a hull with five or more weapons needs the hover expansion the legs assume. Worth one Board picture at five weapons before building.
4. The tree prompt's home differs by concept (docked top-left in KEEL, centred in WATERLINE). The chair recommends KEEL's dock: a centred modal over the board contradicts the point of freeing the middle.
