# Outside check: PR #314, issue 271 battle HUD build (Glass Shell bold)

- PR: #314 "Issue 271 build: Glass Shell bold battle HUD (R145)", draft, head opus/issue-271-build @ 307eaaa4e2bf3b9e2df4724fa627f2793b1ade22.
- Asked by: issue #256 board comment, Nov 9, 2026. Read the diff against docs/shots/ui_redesign/mockups_r2/C_glass_shell_bold.png and contrib/opus/briefs/ui_spec.md. GO or NO-GO with reasons.
- Standard: FINDINGS R129 (the diff, an impact sweep, the shots), R141, R145, R148, the #292 rulings S1 to S6, the locked law in ui_spec.md, and the Glass Shell rules in the PR's own ui_style.md.
- Legs: blind Rey (written before the other legs were read), DeepSeek (DeepThink on, search off), Qwen (Qwen3.8-Max, gate pass before and after), Flash (3.8 Flash) and Grok (free Fast), the last two run as checkers under Ryan's Nov 9, 2026 full-council instruction. The Argon seat is empty (Google AI Pro lapsed, renewal unverified).
- Verdict: GO WITH CONDITIONS.

## What holds

- Faithful to the pick: one right shell, seven wells in decision order, fleet list at the spec width, 20 ships at 1080 with no scroll (enforced by a new ui_shots check), the counted line at reserved height, a four-line ticker with round prefix and L for the full log, acted pips, the 9-segment Heat gauge, the unacted set under the top bar, the lavender enemy turn strip.
- S1 to S6 are implemented, verified leg by leg with code evidence: hatched ghost segments labelled "expected" with "to about N" text, no undo, the arc token always present, the unacted set in its ruled form, the counted line's reserved height, and the budget closing without touching the seven blocks.
- Locked law holds: the glass_shell.gd palette reproduces ui_spec 5.1, and the three new entries (SHELL, WELL and WELL_EDGE, SHIELD_TRACK) are registered in 5.1 by the same PR. Faction colour rule 5.4 holds. The scale law and the 12 px floor hold. The 0.35 hull-low threshold from the #269 fix is preserved. The threat fill is recoloured from alarm red to FOE lavender.
- The two new battle_api queries are read-only presentation reads. threat_map's existing output is unchanged: the both flag gates writes to a separate count dictionary and never touches the damage accumulation. Parity is reported pass.
- The R148 pass is present: End ship is the one filled gold button in every state, step confirms are lit, and the hatching is Move-step only at the calmer shader settings. The three sandbox ui_check files end 0 failed (21 to 22 checks each).
- R129 sweep: hud.gd's public API is preserved (one optional trailing parameter added), no save format is touched, the rules twins are untouched, and the UI paths (player, enemy, classic, bot and showcase, menu, end card, tip card, resize) are covered.

## Conditions

1. Text backing (DeepSeek; chair-verified in the diff). ui_style.md section 2 rules every line of text on a solid backing, and section 3 fixes that backing at WELL 94% in a frame or 86% as a strip. Three places break it:
   - The top bar: _build_top applies GS.shell (SHELL at 38%) and adds the title, turn, acted, objective, foe and Heat labels straight to the bare row, with no well or strip behind them.
   - The log head: _build_log adds the LOG header and the Full log button to the log panel's frame, above the well that holds the log text.
   - Roster rows: _roster_row fills at 55% alpha unselected and 30% selected, neither 94 nor 86.
   The PR applies the rule correctly to the banner, with a comment citing it, so this reads as a miss rather than a rival reading. Fix the three places to a well or a strip, or amend ui_style.md to exempt them; if the look changes, rerun the A and B captures before merge.
2. Fire header overwrite (DeepSeek; mechanism chair-verified). _route_card rewrites the first label of the fire well's header row to the step tick or "2" whenever a card is active. _head adds the number label only when one is passed, and _build_fire passes none for an enemy panel, so that first label is the word WEAPONS. Inspecting or hovering an enemy while one of your ships is mid-activation can stamp "2" over WEAPONS. Guard the rewrite: only relabel when the header carries a step number, or find that label by name.
3. "Likely kill" (DeepSeek). _target_info appends "Likely kill." when the expected hull damage reaches the target's current hp. S1 kept the expected value primary and rejected ranges, "will" wording and derived probability-of-kill. The figure here is a threshold on the expected value, not a probability, but the words are a kill prediction in probability language. Board call: ratify it as inside S1, or drop the words; the hatched ghost already shows the hull reaching zero.
4. Focus stylebox duplication (Flash; chair-verified). hud.gd _theme installs GS.make_theme, which sets the glass_shell focus ring, and then sets its own focus stylebox again. The manual block predates the theme layer and implements the same spec, so behaviour is correct today; ui_style.md section 8 says build from glass_shell.gd and do not copy numbers. Remove the duplicate so the ring has one source.

## Notes, tracked not blocking

- The PR body is stale against its own branch: it never mentions the R148 fix pass or the identity exploration, both of which are in the diff and documented in CAPTURES.md and the identity README. (blind Rey)
- The counted line's Ready count is coloured #7ddc6a, which ui_spec 5.1 assigns to DANGER band 1, not FRIEND #8ff0a0. The mockup uses the same green, so the drift is mockup against palette table; record the use in 5.1 or switch. (blind Rey)
- _panel_info reads w["kind"] for the flak "wings only" reason while rules-side code reads w["k"]; if the view weapon dictionaries carry only "k", that reason silently never appears. One-line board confirmation. (blind Rey)
- Reach counts refresh on enemy move, turn or death, not after your own moves, so the move tip's "now M" figure can be one move stale inside an activation. Disclosed in the PR body; the hatching shows only pre-commit, which bounds the window. (all legs)
- threat_both's count is the enemies with positive expected damage on the hex, which is what the code accumulates. If any board-facing wording describes it as enemies that can bring guns on the hex, align the wording or the count. (DeepSeek; the chair agrees from the code)
- preview_fire_at is called from hover and refresh paths with no threat-busy guard and no last-answer cache, unlike _battle_info and _nem_info; a hover during a threat pass may wait on the rules lock for the cited pass time. (DeepSeek, inferred)
- Heat: _battle_info sums the rule weights unclamped, the label and tooltip print the raw sum ("Heat %d of 9"), and _draw_heat clamps the lit segments to 9. If the data-side weights can sum past 9, clamp the label; if they cannot, no change. Board to confirm against the data. (DeepSeek; mechanism chair-verified, reachability unverified)
- The unacted chips are sorted by danger descending. The chair reads S4's "unordered" as barring turn-order signals, which a danger sort is not; if the board reads it more strictly, drop the sort and keep only the in-reach grouping. (DeepSeek, raised as a question)
- _on_hover rebuilds the whole ship panel per hovered-enemy change, and set_roster passes a zero max height into _fit that _apply_heights later corrects. Polish items, if either shows up in play. (DeepSeek, inferred)
- Flash also asked for the 12 px floor to be documented across plate sub-labels. The smallest plate sub-label in the diff is 13, above the floor, so this is documentation only.
- Grok returned NO-GO. Its nine findings are all positive (no locked-law violation, no parity failure found), and its grounds are the disclosed count staleness it itself calls accepted, the pending PC captures (the board's step under the ask, not this check's), and the pending identity pick (Ryan's call, documents only). The chair treats its findings as evidence and does not adopt its verdict.

Standing steps unchanged: the board runs the PC captures (including the R148 out_r148 set) before merge. The identity pick (1 Graphite Signal, 2 Lime Tactical, Opus's pick, 3 White Frost) is Ryan's, and no theme code changes until he picks.

## Not checked

- Runtime behaviour beyond the reported sandbox checks; the R116 frame-time gate (not re-measured in the PR); 4K (sandbox memory; covered by the PC job).
- Whether the view weapon dictionaries carry "kind" (see notes).
- The data-side maximum of the Heat weights (see notes).
- The main-branch state behind the PR's claim that the one naming_lint_game residual hit predates it.

Refs #256.

## Addendum, Nov 9, 2026: identity pick recorded

Ryan ruled in the main chat on Nov 9, 2026 (12:46 CST): the identity is **2 Lime Tactical** (Chakra Petch / Azeret Mono, black-olive, neon lime accent), which was also Opus's pick. The board can now convert glass_shell.gd (palette and boxes), the fonts, and ui_style.md sections 2 to 5 to the Lime Tactical identity and rerun the PC captures. The README's noted risk stands: lime against the friend green (the identity pushes friend to a cooler spring green; the fallback is mint-teal), so the captures should include a friend/foe readability pass.
