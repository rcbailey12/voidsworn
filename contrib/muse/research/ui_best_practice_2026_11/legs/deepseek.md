# #292 stress-test leg: DeepSeek (DeepThink on, Search off, gate verified)

Run Nov 8, 2026, 21:42-21:44 CST (browser-measured). Gate: DeepThink ON (pale blue), Search OFF, both re-verified after one toggle. Chat: https://chat.deepseek.com/a/chat/s/28cbdb9d-291d-4af2-be92-5bbffce0ff30

CHAIR NOTE: this is the strongest stress leg of the job on its axis. Two chair flags: (1) its P4 roster arithmetic divides the 250 px WIDTH by 20 rows to get 12.5 px per row; the binding dimension is height (about 980 px usable, about 49 px per row), and the #271 stress_20_ships image already demonstrates the 20-ship fit at one line plus bars. The density caution stands in weaker form; the 12.5 px figure does not. (2) Its S6 proposal to fold the Nemesis panel into a top-bar crest chip conflicts with Ryan's R142 framing (the Nemesis panel heads the picked 2B column) and with the blind leg; the chair will rule on it in the synthesis rather than adopt it silently. Everything else is adopted or answered in the synthesis. Leg text verbatim below.

---

Stress-test leg report: buildability and rules-honesty for mockup 2B

Scope note: everything below reasons from PACK_DS.md only. Where the pack does not say (weapon toggling, per-weapon heat cost exposure, the hit-roll model, whether move confirmation restores facing, whether the roster already scrolls, the ui_spec content rules), I mark NOT IN PACK rather than guess.

1. Build verdicts, P1-P8

P1, Telegraph threat on the board. Needs game-state the UI may not have (each enemy's reachable set under its move + weapon range) plus per-planning computation plus a custom board overlay. First break: Voidsworn enemies do not pre-commit attacks, so there is no per-attack telegraph to draw; the honest overlay is derived reach/danger shading that must be recomputed every time the plan or the hovered ship changes. If the rules layer does not already expose enemy movement/range, the UI has to duplicate that math, and the overlay will drift from the real rules. Verdict: game-state + computation + custom control; do not build it as a new text block (see section 3).

P2, Outcome preview beside odds. 2B already carries hit% and expected damage per weapon and an aggregate. The extensions are arithmetic over state the up-ship and target panels already display (hull, shields by facing), so no new game-state is needed for a hull-after-expected marker or per-facing shield depletion forecast. First break: a live-updating aggregate on weapon toggle presupposes togglable weapons; the mock lists weapons with keycaps but the pack does not say they can be deselected (NOT IN PACK). If they cannot, "live aggregate" is just the current static aggregate and the only add is the ghost marker. Verdict: theme-only plus a small custom control (the target bar with a ghost segment); computation is trivial and local.

P3, Decision-order fixed column. Pure Container layout and theme. No break. Keep.

P4, Roster as triage at 20 ships in 250 px. A reusable custom row control (bars + state word) or themed ProgressBars in a VBox. First break is arithmetic, not code: 250 px divided by 20 rows is about 12.5 px per row, which cannot hold a line of text at the 12 px floor plus two bars plus padding. The roster must scroll, collapse to a compact mode, or paginate; that is a layout-and-state decision the mock has not made. Danger badges and optional numeric HP are cheap once the row control exists, but they worsen the density problem. Verdict: reusable custom control plus a scrolling/compact-mode decision; the 20-ship fit is the open risk. [CHAIR: see the header note; the division uses the wrong dimension.]

P5, Resource gauge with forward cost. Needs a segmented custom gauge control and game-state for per-weapon heat delta. First break: whether each weapon exposes its heat cost to the UI is NOT IN PACK; if the cost lives only inside the fire resolution, the UI cannot show the delta before commit without a rules-layer change. The segmented gauge itself is a standard custom control; the delta is one number appended to each weapon row. Verdict: custom control + game-state exposure; cheap if the data exists.

P6, Arcs and facing on the board during planning. The heaviest item: game-state (weapon arcs, facing, hovered destination, enemy positions) + per-planning computation (simulate the ship at the destination) + a custom overlay. First break: showing which enemies each weapon could hit at the hovered destination requires a projected ship state (position + facing) before the move is confirmed. The move step confirms with click-again/Enter; the pack does not say a preview state exists (NOT IN PACK). If the UI recomputes arc/range itself, previews will eventually disagree with the rules; the honest build calls the same rules function with a hypothetical transform. Verdict: game-state + computation + custom overlay; stage it (current-position arcs first, hovered-destination second).

P7, Keyword help, one layer deep. Godot's built-in tooltip is theme-only; a proper keyword layer (RichTextLabel with meta links over a keyword dictionary) is a small reusable custom control. First break: this is content authoring, not code: Braced, LOW, Heat, adaptation terms, facing names and state words all need definitions, and the mock defines no hover affordance on keycaps or state words. Verdict: theme plus a small custom control plus authored content.

P8, Log as secondary channel. Already compliant (ticker + full log on a key); a scrolling log is a container and theme. No break. Field hit markers would be a small themed addition, not worth column space.

2. Rulings on S1-S6

S1, How deterministic can the preview honestly be. Build (a) plus (c), with strict labelling; reject (b) and (d) as stated.

An odds-based game may honestly show: per-weapon hit percentage (already there), per-weapon expected damage (already there), and an aggregate expected damage that is explicitly an expectation ("about 31"). It may additionally show a hull-after-expected marker on the target bar only if it is visually distinct from the real hull (ghost/hatched segment), carries a text label ("expected"), and appears in a legend, otherwise a single marker reads as a guarantee. That is (c), and it is cheap and honest.

It may not show: a single "will do X" number, a deterministic hull-after state, or a best/worst numeric range on the aggregate. The reason is honesty, not squeamishness: for multiple weapons the aggregate is a distribution, not an interval, and a "worst" that includes every weapon missing is a number the player will read as a floor and plan against. Per-weapon best/worst (hit or miss) is defensible in isolation but adds four numbers per row for little gain; the per-weapon hit% already communicates the variance at its source. Per-facing shield depletion in the expected case (d) has the same guarantee-reading problem as (c) but without the single-marker clarity, so fold it into (c) as part of the ghost marker rather than a separate forecast. One caveat: if each weapon rolls separately, aggregate variance is wider than if the battery rolls once; the pack does not state the model (NOT IN PACK), so keep the aggregate labelled "about" and do not derive a probability-of-kill from it.

S2, Undo and soft commit. Three variants, three rulings:

Re-plan before confirming the move (click again or Enter). UI-only, already in 2B. Keep as is.

Undo after confirming the move but before firing. This is a rules change, not a UI feature. The pack states a ship activates move-then-fire-then-end and the move step confirms; once confirmed, the move is a spent action. Letting the player take it back changes what "committed" means, and it interacts with facing (an undone move must restore facing), with any reaction state, and with the Nemesis clock if movement advances it. The UI can render an undo button, but the button is a rules feature wearing a UI coat.

Penalty-free undo until an irreversible action. Also a rules change: it redefines which actions are irreversible. Not a UI call.

Ruling: build (1) and the round-level safety of S5; do not build (2) or (3) as UI. The decision owner is Ryan (owner) with Opus, because it is a rules/design call; this study can only rule that it is not a UI change and should not be smuggled in as one.

S3, Weapon arc/range text. Keep the text; add a small consistent icon (Grok's change), do not cut (Flash's cut is rejected on a locked-rule ground). The bearing weapon is highlighted, which is a colour-carried state; the locked rules require a second channel for every colour-carried state, and the arc text plus the highlight are that pair. Cutting the arc text makes "bearing" colour-only on the fire row, which the locked rules forbid. The icon is a scanning aid, not a replacement. If column pressure later forces a cut, cut the range number to an icon-plus-tooltip and keep the arc word; never cut the arc. The ui_spec content rules are NOT IN PACK, so this ruling rests on the locked second-channel rule.

S4, Turn order display and the free activation order problem. Build a variant of (b) that is explicitly a set, not a sequence; reject (c); do not settle for (a).

The honesty problem is real: friendlies activate in player-chosen order and the enemy phase is a block, so a fixed-looking order strip would depict a sequence the player is free to violate, and a "next three" list implies a queue that does not exist. The buildable honest form: under the acted pips, show "N unacted" plus up to three chips (crest or name) with no connecting line, no arrows, no numbering across the friendly chips, and keep the enemy-block information ("M enemy ships, K can reach the flagship") where it already lives in the End box. Second channel: chips are named shapes, not just colour. This gives the player the triage value of (b) without the lie of a fixed order. A full strip (c) is both a column cost and a lie; do not build it.

S5, End-of-round safety counted line. Build it conditionally: show the counted line only when ending would leave ships unacted or unfired, with the count and, if cheap, a jump-to-next affordance; render nothing when the count is zero. A permanent "0 unacted" line costs column space every round for no information and trains the player to ignore the line. UI-only, cheap.

S6, Column length budget at 1920x1080. The column is already full: seven blocks (Nemesis, up ship, move, fire, orders, target, end) against roughly 980 px of usable height leave no headroom. Pricing the add list:

P5 heat delta is effectively free in the column: put the segmented gauge in the top bar where the Heat number already sits, and append the per-weapon delta to each weapon row (zero net row height if the row is already two lines). Cost lands on the top bar, not the column.

S4(b) unacted-set chips belong in the top bar under the pips, not the column; the top bar must grow by a line or the objective text must shorten. That is a board-height trade, not a column trade.

S5 counted line is conditional and lives inside the End box: zero cost when zero.

P1 threat block is the only true column pressure, at roughly 80-120 px as a new block. Ruling: do not add a threat block to the column. Put threat on the board (P6 overlay, P1's honest form) and on the roster rows as danger badges (P4 extension), and keep the "can reach the flagship" note in the End box. That removes the column cost entirely.

What gives if something must: first fold the Nemesis panel into a crest chip in the top bar with a tooltip/collapsible strip (its content is largely static per meeting: name, adaptation, known weakness); second move ARM/EVA/MOVE/TURNS/CREW to a tooltip or a second line (Grok's proposal, endorsed); third, only if still forced, drop the range number to an icon-plus-tooltip. Do not cut the End box, the target aggregate, or the fire step's odds/expected pair. With those two folds, the full add list fits inside one vertical scan without pushing secondary stats off-screen.

3. Final ranked change list for mockup 2B

1. Keep the decision-order fixed column (theme-only, zero cost; P3).
2. Keep the fire step's per-weapon hit% + expected damage and the target aggregate line (already built; P2).
3. Keep the ticker plus full-log-on-key and the End box's next-ship + enemy-reach count (already built; P8, S5 base).
4. Change Heat from a bare number to a segmented gauge in the top bar, with per-weapon heat delta appended to each fire row (custom control + game-state exposure; P5).
5. Change arc/range text to text plus a small consistent icon; do not cut the arc (theme + small custom control; S3).
6. Add the board arc/facing overlay at the up ship's current position, then extend to the hovered destination using the rules-layer arc test (game-state + computation + custom overlay; P6, highest value, highest cost; stage it).
7. Add a hull-after-expected ghost marker on the target bar with a text label and legend entry (theme + trivial computation; P2/S1(c)).
8. Change roster rows to carry a danger badge and optional numeric HP, and decide the 20-ship fit (scroll or compact mode) (reusable custom control + layout decision; P4, the 12.5 px/row arithmetic is the open risk). [CHAIR: arithmetic corrected in the header note.]
9. Add "N unacted" plus up to three unacted chips under the acted pips, with no arrows or numbering, and the enemy block noted in the End box (theme/logic; S4(b)-variant).
10. Change the End box to show the unacted/unfired count line only when non-zero (theme/logic; S5).
11. Add a one-layer keyword tooltip system over Braced, LOW, Heat, adaptation terms, facing names and state words, with authored definitions (small custom control + content; P7).
12. Cut/displace the standalone Nemesis column block into a top-bar crest chip with tooltip/collapsible detail, to free column height for the threat work (layout; P1/S6). [CHAIR: contested, see header note.]
13. Change the up-ship stat line: ARM/EVA/MOVE/TURNS/CREW to a tooltip or second line, keeping hull/shield/heat primary (theme; S6).
14. Do not build undo-after-move-confirm or penalty-free undo; refer both to Ryan/Opus as rules changes (S2).
15. Do not build a threat text block in the column, a fixed order strip, a deterministic hull-after, or an aggregate best/worst range (P1, S4(c), S1(b)/(d), rejected on honesty and column-budget grounds).
