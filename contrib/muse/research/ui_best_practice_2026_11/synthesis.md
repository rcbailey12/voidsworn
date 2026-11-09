# #292 synthesis: UI best practice applied to mockup 2B (chair)

Issue: #292 (R142, Ryan, Nov 8, 2026). Chair: Rey. Legs: blind Rey (legs/blind_rey.md), Flash search (legs/flash.md), Grok search (legs/grok.md, screened), DeepSeek stress (legs/deepseek.md), Qwen stress (legs/qwen.md), chair supplement on Stellaris and Sins of a Solar Empire 2 (supplement.md), pool assembly (pool.md). Argon blocked since Nov 5, 2026; not used. This synthesis feeds #271 mockup round 2, which starts from 2B as revised here.

Screening and corrections the chair owns:
- Grok's leg: rankings converge with the other legs and are used; its citation labels mismatch their links in places and it under-covers the roguelike genre, so its links are leads, not citations. Flash carries the roguelike minimum.
- Flash's leg frames its first pattern as a "deterministic resolution preview" (Monster Train, Into the Breach). Voidsworn combat is odds-based; the deterministic part does not transfer, and both stress legs rule against importing its form. What transfers is the outcome-preview habit, in expected-value language (ruling S1).
- Both stress legs repeat a roster arithmetic slip (dividing the 250 px roster WIDTH by 20 rows). The binding dimension is height: about 980 px usable, about 49 px per row, and the #271 stress_20_ships image already demonstrates the 20-ship fit at one line plus bars. The density caution survives in weaker form; the 12.5 px figure does not.

## 1. The games studied (20, at least five per genre)

Tactics:
1. Into the Breach (Subset). Best for the next action: deterministic telegraphing; every enemy's target and exact damage is pinned to the grid before the player commits, and move undo plus a turn reset make experiments safe. Gets wrong: cascading displacement chains still demand step-by-step mental simulation; no multi-step forecast. Screenshot/source: https://store.steampowered.com/app/590380/Into_the_Breach/
2. BattleTech (Harebrained). Best: the move line projects facing cones, sight lines, and evasion; the fire step breaks out per-weapon odds, heat delta, and threshold warnings before firing. Gets wrong: information density and paper-doll modals that cover the board. https://store.steampowered.com/app/637090/BATTLETECH/
3. Warhammer 40,000: Rogue Trader, voidship battles (Owlcat). Best: quadrant shields and weapon arcs rendered on the plane with rigid turning radii; officer posts split cleanly from propulsion and salvos. Gets wrong: camera tracking and arc readability around huge hulls and debris, widely criticised. https://store.steampowered.com/app/2186680/Warhammer_40000_Rogue_Trader/
4. XCOM 2 (Firaxis). Best: the target preview at the cursor's destination hex, showing which enemies enter line of sight and range before the move commits; the shot modal breaks aim into base, cover, elevation, crit. Gets wrong: line-of-sight visuals occasionally misalign with tile geometry (the "shot through a wall" grievance), and a bare percentage invites grievance on a miss. https://store.steampowered.com/app/268500/XCOM_2/
5. Gears Tactics (Splash Damage). Best: the movement path is subdivided into action-point segments with overwatch cones and hit chances visible along the path before execution. Gets wrong: overlapping overwatch cones clutter the read. https://store.steampowered.com/app/1184050/Gears_Tactics/
6. Phoenix Point (Snapshot). Best: the free-aim reticle's two rings (50% of shots inside the inner ring, 100% inside the outer) communicate distribution without a single-roll abstraction. Gets wrong: barrel-geometry raycasts can collide with low terrain the reticle called clear. https://store.steampowered.com/app/839770/Phoenix_Point/

Strategy and fleet:
7. Stellaris (Paradox). Best: the Outliner, a persistent right-edge list of planets, fleets, and starbases with status, where every entry is also a jump control; fleet operations run from the list (chair supplement, sourced). Gets wrong: the 2023 rework split the list into category tabs and players revolted, preferring one scrollable combined list; density pressure spawns "tiny outliner" mods (player-reported, supplement). https://store.steampowered.com/news/app/281990/view/687521707909447820
8. Sins of a Solar Empire 2 (Ironclad/Stardock). Best: the Empire Tree as a threat reader (players report judging threats faster in the tree than in the battle view, developer sources in the supplement); Sins II added a customizable Bookmark Bar, a redesigned Selection Window for battle, and Alt-key detailed stats. Gets wrong: the full tree clutters and jumps as the empire grows; players split between full tree, selection-based mode, and off. https://forums.sorcererking.com/528312/video-blog-evolution-of-sins-ii-pt-2-game-changing-rts-features
9. Battlefleet Gothic: Armada 2 (Tindalos). Best: quadrant shields and directional armour drawn on the ship's own ring; arcs and stances in high-contrast trays pinned to the selection. Gets wrong: roster tracking (cooldowns, boarding, casualties) overloads at fleet scale in real time. https://store.steampowered.com/app/573100/Battlefleet_Gothic_Armada_2/
10. Nebulous: Fleet Command (Eridanus). Best: engineering-grade fidelity: EW noise floors, point-defence envelopes, module damage, all in directional vector ribbons. Gets wrong: a punishing learning curve; nested menus and 3D orientation widgets demand extensive manual parsing. https://store.steampowered.com/app/887570/NEBULOUS_Fleet_Command/
11. Battlestar Galactica Deadlock (Black Lab). Best: WEGO planning with a timeline scrubber and posture projections showing collision and firing paths before the turn executes. Gets wrong: vertical-axis planning and trajectory clutter in tight formations. https://store.steampowered.com/app/544610/Battlestar_Galactica_Deadlock/
12. Endless Space 2 (Amplitude). Best: the SCAN overlay (hold Spacebar) wipes decoration and shows a clean data layer: compositions, health pips, range profiles, lane assignments. Gets wrong: abstract iconography forces tooltip digging for exact numbers. https://store.steampowered.com/app/392110/Endless_Space_2/
13. Homeworld Remastered (Gearbox). Best: the Sensors Manager scales from fleet command to strike craft with standard silhouettes and clear movement discs. Gets wrong: sub-targeting modules is finicky at modern resolutions. https://store.steampowered.com/app/244160/Homeworld_Remastered_Collection/
14. Starsector (Fractal Softworks). Best: the tactical map carries doctrine orders, role assignments, and live status callouts (flux soft vs hard, disable timers, shield orientation). Gets wrong: hotkey and weapon-group setup is opaque to new players. https://fractalsoftworks.com/

Roguelikes:
15. FTL: Faster Than Light (Subset). Best: offensive readiness and defensive vulnerability in one eye sweep; power, charge bars, and hazards co-located on the ship diagram, decisions in one fixed place. Gets wrong: crew micro during dual breaches becomes cursor hunting. https://store.steampowered.com/app/212680/FTL_Faster_Than_Light/
16. Slay the Spire (MegaCrit). Best: intent badges over enemies with exact values; keyword definitions one hover deep. Gets wrong: no integrated action history or undo, so misclicks are permanent. https://store.steampowered.com/app/646570/Slay_the_Spire/
17. Cobalt Core (Rocket Rat). Best: every card previews the lane shift, trajectories both ways, shield increments, and heat before energy is spent. Gets wrong: complex drone and collision stacks can push key intent out of the focal area. https://store.steampowered.com/app/2179850/Cobalt_Core/
18. Monster Train (Shiny Shoe). Best: the end-of-turn resolver previews the outcome on every floor before the button is pressed, deaths and remaining HP included. Gets wrong: floor separation fragments global trigger tracking. https://store.steampowered.com/app/1105220/Monster_Train/
19. Darkest Dungeon II (Red Hook). Best: a finite token economy; every status is a readable token under the sprite, no hidden formulas. Gets wrong: token stacking in long boss fights clutters and forces tooltip inspection. https://store.steampowered.com/app/1940340/Darkest_Dungeon_II/
20. Hades (Supergiant; Grok leg, supporting). Best: clear attack telegraphs, damage numbers, resource meters, and contextual tooltips in a fast frame; a readability benchmark rather than a turn-based model. Gets wrong: density in late runs still demands mastery. Source: Grok leg entry, links screened as leads.

## 2. Ranked patterns (tags: MEASURED = observed in the named shipped games from the legs' sources; DERIVED = transferred to Voidsworn's different rules by reasoning; ASSUMED = no shipped analogue verified in this job)

1. Threat belongs on the board, in geometry, not prose. MEASURED in Into the Breach, Slay the Spire, Cobalt Core. DERIVED for Voidsworn: enemies do not pre-commit attacks, so the honest form is derived reach and danger shading, recomputed from the same rules functions the game resolves with, plus a danger count badge on threatened roster rows. 2B today carries this as one sentence in the End box only.
2. The resource gauge shows the forward cost of the next action. MEASURED in BattleTech (heat delta per weapon) and Starsector (flux). DERIVED: Heat as a segmented gauge plus a per-weapon heat tag in the fire row, right-aligned at fixed width (Qwen's scan-order fix).
3. Preview at the destination before the move commits. MEASURED in XCOM 2 (target preview), BattleTech (move-line projection), Gears Tactics (path segments). DERIVED: stage it, current-position arcs first, hovered-destination arcs second, always via the rules layer's own arc test so the preview cannot drift from resolution (DeepSeek).
4. Outcome beside odds, in expectation language. MEASURED in Monster Train and Cobalt Core (resolution previews) and BattleTech (salvo breakdown). DERIVED and bounded by ruling S1: expected values plus ghost markers, never certainty language.
5. One fixed decision-order column. MEASURED in FTL and Slay the Spire (fixed decision places); unanimous across all five legs for 2B. Already implemented; the study's job is to protect it from additions that break the scan.
6. The roster is one unsplit list, and every row is a jump control. MEASURED in Stellaris (Outliner; the tab-split backlash is the negative proof) and Sins 2 (Empire Tree threat reading). DERIVED: at 20 ships the failure modes are avoidable by rule: never split, never tab, shrink rows first.
7. End-of-round safety as one conditional counted line. MEASURED as a genre habit (XCOM 2's unacted warnings are the friction version; FTL's jump warning the quiet one). DERIVED: counted line only when non-zero, with its height reserved always (Qwen C5).
8. Keyword help exactly one layer deep, on demand. MEASURED in Slay the Spire and Cobalt Core; the Sins II Alt-for-detail habit agrees. DERIVED: an authored definition pass is part of the build, not polish (DeepSeek: the cost is content, not code).
9. Remaining friendlies as an unordered set, not a sequence. ASSUMED as drawn (no shipped analogue verified); it is DeepSeek's construction to answer the false-order objection, and it is the one genuinely contested item in this study (ruling S4).
10. The log is a secondary channel. MEASURED in FTL; 2B already complies (ticker plus full log on a key). No change.

## 3. Rulings on the splits

S1, preview honesty. Adopt (a) plus (c), extended to shields in the same visual language. Expected value stays the primary number, labelled "about". The target hull bar gains a ghost segment to the expected post-volley level, visually distinct (hatched or outline), labelled "expected" in the panel legend. The target's shield bars take the same ghost treatment for the facing expected to drop (DeepSeek's form, Qwen's scope; Qwen's separate clause is not added, to hold the text budget). Rejected: (b) per-weapon best/worst ranges, any "will do X" wording, and any derived probability-of-kill (the pack does not state the roll model, so deriving one would be inventing precision). Both stress legs concur on (c) and against (b).

S2, undo. This study rules only that post-confirm move undo is a GAME-RULES change, not a UI feature (DeepSeek's analysis: a confirmed move is a spent action; undo interacts with facing, reaction state, and the Nemesis clock). It is referred to Ryan with Opus, with three options costed: (i) status quo, re-plan before confirming only; (ii) undo after confirming until the first weapon fires; (iii) penalty-free undo until any irreversible action (Flash's proposal). If any of (ii) or (iii) is ruled in, the UI cost is one button in the Move step (about 20 px, Qwen) and the slot should be reserved in round 2 mockups so the layout does not move later. The chair does not pick; the downstream UI work is identical under (ii) and (iii).

S3, arc and range text. Keep the text; Flash's CUT is rejected on a locked rule: the bearing highlight is a colour-carried state, and the spec requires a second channel for every colour-carried state; the arc text is that channel on the fire row (DeepSeek). Form: Qwen's compact token (for example "P 1-2") over Grok's added icon; the icon is optional garnish, the text is load-bearing. If width ever forces a demotion, the range number goes to icon-plus-tooltip first; the arc word is never cut (DeepSeek).

S4, turn order. The full strip (c) is rejected by every leg. Two live options remain: (a) status quo, the End box's next-ship line only (Qwen's ruling, on false-model grounds); (b-set) an unordered set under the top bar's acted pips: "N unacted" plus up to three named chips with no arrows, no numbering, no connecting line (DeepSeek's construction). Chair pick: (b-set). Qwen's objection is correct against the sequenced drawing the pack described, and the set form removes exactly that: nothing in it claims an order. What it adds over (a) is the triage answer (which ships are still live) at the moment the player is choosing who acts next, which the pip count alone does not give. It lands on the top bar, not the column. If Ryan prefers (a), nothing else in this study changes.

S5, end-of-round safety. Adopted: the counted line ("N ships still Ready / unfired") shows only when non-zero, and its height is reserved in the End box in all states so the End Ship button never moves (Qwen's C5 condition, which the chair upgrades from note to requirement). A per-ship nag is rejected (all legs). A jump-to-next affordance on the line is welcome if cheap (DeepSeek).

S6, column budget. Priced by both stress legs and the chair: the adds cost about 80 to 100 px of column (heat tags about 60 if they wrap, the counted line 20 reserved, ghost markers 0). The budget closes WITHOUT removing or folding any of 2B's seven blocks: CREW and EVA move to the tooltip layer (about 15 to 20 px freed, Qwen, endorsed by DeepSeek as its second fold), the Heat gauge and the S4 set chips land on the top bar, and P1 and P6 land on the board. DeepSeek's first fold (the Nemesis panel collapsed into a top-bar crest chip) is REJECTED: R142 picked 2B with the Nemesis panel heading the column, and the budget closes without touching it. Reserve demotions if round 2 still overflows, in order: TURNS, then ARM, to tooltips (Qwen); the range number to icon-plus-tooltip (DeepSeek). Hard rule from Grok, adopted: nothing may push the column past one vertical scan, and no new block may be inserted.

## 4. Numbered changes to mockup 2B (for #271 round 2)

Keep:
1. The seven-block decision-order column, unchanged in order and membership (P5 pattern 5).
2. Per-weapon hit percent plus expected damage, and the target aggregate line (pattern 4, status quo half).
3. The End box structure and the End Ship button's fixed bottom-corner position.
4. The four-line ticker and full log on a key (pattern 10).
5. The roster as one unsplit list, one line plus bars per ship at 20 ships (pattern 6).

Change:
6. Heat: bare top-bar number to a segmented gauge in the top bar; per-weapon heat cost as a right-aligned fixed-width tag in each fire row (pattern 2).
7. Weapon-row arc/range text to the compact token form (S3); scan order: keycap, name, arc/range token, hit percent, expected damage, heat tag.
8. The up-ship stat line: CREW and EVA move to the tooltip layer; ARM, MOVE, TURNS stay visible (S6).
9. The End box counted line: conditional on non-zero, height always reserved (S5).

Add:
10. Reach and danger shading on the board during the player phase, passive and low-contrast, computed by the rules layer (pattern 1), with a danger count badge on threatened roster rows.
11. Arc and facing preview on the board: current position first, hovered destination second, on a visual layer above the threat shading and visible only during the Move step (pattern 3; Qwen C3 layering).
12. Ghost expected markers on the target bars: hull bar and the shield bar of the facing expected to drop, labelled "expected" (S1).
13. The unacted set under the acted pips: "N unacted" plus up to three named chips, no arrows or numbers (S4 chair pick; option (a) remains open for Ryan).
14. A one-layer keyword tooltip system over state words, adaptation terms, Heat, Braced, LOW, and facing names, with authored definitions; tooltips anchor beside the hovered element and never cover the column centre (pattern 8; Qwen C6).

Cut (rejected, do not revive in round 2):
15. Per-weapon best/worst damage ranges (S1).
16. Any fixed order strip or sequenced next-three display (S4).
17. A threat text block in the column; threat lives on the board and the roster (S6).
18. Numeric HP on roster rows; the bar plus the badge is the row budget (Qwen over Grok and DeepSeek-optional).

For Ryan (one rules question, from S2): post-confirm move undo, options (i), (ii), (iii) as costed in the S2 ruling. Round 2 mockups can proceed without the answer if the Move-step slot is reserved.

## 5. Campaign map and end-of-run screens (short note)

Campaign map: the same patterns scale up a level. The roster discipline becomes the fleet and sector list: one unsplit list, alert badges for threat, every entry a jump control (Stellaris, Sins 2). The Nemesis clock is drawn as spatial pressure on the map (an encroaching front or shaded approach, Flash and Qwen concur) with its number as the second channel, not the only one. Forward-cost logic applies to jumps, repairs, and refits: show the delta on the resource gauge before the player commits. Keyword help carries sector, adaptation, and upgrade vocabulary at the same one-layer depth.

End of run: the war-diary read. Outcome-versus-expectation is the organising idea (pattern 4 turned backward): damage dealt and taken against expectation, Heat peaks, Nemesis meetings and adaptations faced, per-ship fates in the roster's own state vocabulary (Survived, Lost, Braced at end, Qwen). The full run log is browsable behind it (pattern 10). No new visual language: the palette lock, 12 px floor, and backing rules carry over unchanged.

## Method and limits

Evidence is the five legs plus the chair supplement; per-game claims rest on the search legs' store and developer sources (Flash primary, Grok screened, supplement sourced inline). Pixel figures in the stress legs are DERIVED estimates from the 12 px floor and the mock descriptions, not measurements of a Godot build; #271 round 2 and the R116 performance gate remain the arbiters. Nothing in this study measures the frosted-glass cost; that stays with the #271 README's own warning (measure bold's blur against the 12.5 ms gate before shipping).
