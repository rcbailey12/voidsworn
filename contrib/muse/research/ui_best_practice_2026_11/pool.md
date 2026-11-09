# #292 pool: merged patterns and candidate changes for mockup 2B (chair assembly)

Sources: legs/blind_rey.md (chair, blind), legs/flash.md (17 games, gate-verified), legs/grok.md (screened; rankings usable, links are leads). The game and 2B are as described in PACK.md. Locked rules restated for the stress legs: combat is odds-based (weapons show hit percent and expected damage; there is no deterministic resolution); the enemy phase is a phase (all enemies act after all player ships), not interleaved initiative; the Nemesis clock fills across rounds and meetings; palette meanings are fixed; every colour-carried state needs a second channel; text on solid or frosted backing; 12 px floor; the roster must work at 20 ships in 250 px; the scale law and bone focus ring stay.

## Convergent patterns (all three legs, independently)

P1. Telegraph threat on the board, not just in text. (Blind 1, Flash "Direct Spatial Threat Vectors" and its Nemesis change, Grok pattern 1 and 5.) Evidence games: Into the Breach, Slay the Spire, Cobalt Core. Open question for the stress legs: Voidsworn enemies do not pre-commit to specific attacks the way Into the Breach enemies do; what is the honest form of this pattern here (reach/danger shading, per-ship threat counts, Nemesis-only lines)?

P2. Outcome preview beside odds. (Blind 2, Flash pattern 1 and keep, Grok pattern 4.) 2B already pairs hit percent with expected damage per weapon and an aggregate line on the target. Extension candidates: a hull-after marker on the target bar (blind), a live-updating aggregate as weapons are toggled (Grok), per-facing shield depletion in the preview (Flash).

P3. Decision-order fixed column. (Blind 3, Flash keep, Grok pattern 2.) Unanimous keep; no leg defends the following-card layout.

P4. Roster as triage: slim, state words, bars, at scale. (Blind 7, Flash pattern 3 and keep, Grok pattern 3.) Extension candidates: danger badges on roster rows (blind), optional numeric HP on bars (Grok), quick-jump/batch selection (Flash; note Voidsworn activates one ship at a time, so batch selection may not apply).

P5. Resource gauge with forward cost. (Blind 8, Flash heat-delta add, Grok heat change.) Heat as segments, per-weapon heat delta shown before committing (Battletech is the proof game in all three legs).

P6. Arcs and facing drawn on the board during planning. (Blind 9, Flash arc-overlay change, Grok pattern 6.) XCOM 2's target preview at the destination hex is the strongest form: show, at the hovered destination, which enemies each weapon could hit before the move commits.

P7. Keyword help and tooltips, one layer deep. (Blind 6, Grok pattern 8; Flash silent but its DD2-adjacent criticisms point the same way.) Vocabulary at stake: Braced, LOW, Heat, adaptation terms, facing names, state words.

P8. Log as secondary channel. (Blind 10, Grok pattern 7.) 2B already complies (ticker plus full log on a key). No change proposed beyond possible field hit markers (blind, ranked last).

## The splits (stress legs: attack these)

S1. How deterministic can the preview honestly be? Flash ranks "deterministic resolution preview" first, but Voidsworn combat rolls dice: hit percent is real, outcomes are not certain. Options: (a) expected-value only, as now; (b) expected value plus best/worst range on the target line; (c) expected value plus a hull-after-expected marker on the target bar; (d) per-facing shield depletion forecast in the expected case. Which combination informs without lying?

S2. Undo and soft commit. Flash proposes penalty-free move undo until an irreversible action; the blind leg did not propose it (it proposed round-level safety instead). Is move undo a UI feature or a game-rules change? If the current build already lets the player re-plan a move before confirming (2B's move step says click again or Enter to go), what exactly is missing: undo after confirming the move but before firing? Who decides: this study, Opus, or Ryan?

S3. Weapon arc/range text: Flash says CUT the per-weapon arc/range text once a target solution exists (text fatigue); Grok says CHANGE it to text plus a small consistent icon (keep the text). The blind leg is silent. ui_spec content rules may settle what a weapon row must carry; check the spec text in the pack inputs if available, else reason from the locked rules above.

S4. Turn order display. Blind: a compact next-three line. Grok: an attack-order / who-acts-next indicator surfacing the Nemesis clock. Layout 3 (not picked) had a full order strip. Options: (a) nothing beyond the current next-ship line in the end box; (b) next-three under the top bar's acted pips; (c) a full order strip. Note the enemy phase is a block, so any "order" display is really two lists: remaining friendlies in player-chosen order (not fixed), then the enemy block. Does a fixed-looking order display mislead when the player chooses activation order freely?

S5. End-of-round safety. Blind: no per-ship nag; one counted line in the end box when ending would leave ships unacted or unfired. Flash and Grok both endorse the end box as is. Is the counted line worth the column space in every end box, or only when it is non-zero?

S6. Column length budget. Grok warns against anything that pushes the column past one vertical scan and would move secondary stats (crew, evasion) to tooltips; the mock's up-ship panel currently shows ARM/EVA/MOVE/TURNS/CREW in one line. The stress legs should price the full add list (P1 threat block, P5 heat delta, S4 order line, S5 counted line) against a 1080 px column that already holds seven blocks, and say what gives.

## Gap note

Neither search leg gave a full entry to Stellaris or Sins of a Solar Empire 2 (both named by Ryan): Flash omitted both; Grok mentioned Sins 2 in one unexpanded sentence and Stellaris not at all. The chair will add a supplement on those two (the outliner and the empire tree are the relevant patterns) before the synthesis. Stress legs do not need to cover them.
