# Outside review: PR 2140, first battles teach turns and the relay (issue 1403 items 18 and 23)

Issue 2152. Advice only, the Board decides. Read-only review, no code was changed.
PR 2140 at head 3efe48c31864 (branch work/issue-1403-opus, base main), read in full: the complete diff (5 files) and the full text of godot/scenes/battle/battle.gd at that head (8,199 lines).
Council: Rey blind leg first, then DeepSeek (DeepThink on, Search off), Qwen (Qwen4-Max, the gate as of Nov 25, 2026; this was the first leg under the new gate), Gemini on Hydrogen (the Flash seat). Grok's seat is empty (bot wall on grok.com, Nov 25, 2026, about 11:27 AM CT; nothing was submitted). Legs verbatim in legs/ beside this file.
Protocol: docs/REVIEW_PROTOCOL.md (2,340 bytes, 28 lines, read at commit 3629e733 on main, Nov 25, 2026). Findings below are grouped Blocking, High/Medium and Ready as this issue's fixed block requires; each carries a file:line, an exact quote, OBSERVED or INFERRED, and a one-line fix.

## Artoo's open finding: CONFIRMED, and broader than filed

Artoo: "_attack_tip returns early when a ship sits on the relay hex, so the relay rule and score line disappear." Every leg confirmed it from the code, and the chair confirms it from the full file. One wording correction (Qwen): the early return is in _tip()'s dispatch, not inside _attack_tip itself. The substance is worse than filed: it is not only the enemy case. In _tip() (godot/scenes/battle/battle.gd:5935), line 5948 to 5949 returns _attack_tip for an enemy unit, and lines 5950 to 5951 return _ship_tip for ANY other unit, before the relay line is reached. The relay line exists only on the two empty-hex paths (appended at lines 5967 to 5969 in the move-range branch, prepended at lines 5972 to 5975 in the fallthrough). So any ship, yours, the enemy's, or a fighter, sitting on the relay hex or on any of its six ring hexes makes the rule and the score unreachable on hover. That is finding 1.

## Blocking

1. Occupied relay and ring hexes hide the relay rule and the score line. OBSERVED. godot/scenes/battle/battle.gd:5948-5951, quote: "return _attack_tip(u["id"])" (and the _ship_tip return on the next branch). The relay line is only added at 5967-5969 and 5972-5975, both unreachable once a unit branch returns, and neither _attack_tip (line 6058) nor _ship_tip ever calls _relay_line. Scoring is done by putting a ship on or next to the relay, so the rule and the "you %d/3, them %d/3" score disappear in exactly the board state the objective is about, including the moment a player first parks a ship on the hex and wants to confirm it counts. The same dispatch also puts the nova, ram and board mode tips (lines 5940 to 5947) ahead of the relay line, so even an empty relay hex shows no rule while aiming those modes (Qwen). Fix: compute the relay line before the unit and mode branches in _tip() and append it to those returns when it is non-empty.

## High / Medium

2. The new tests prove the helpers, not the wiring, so the blocking bypass and a call-site regression both pass green. OBSERVED. godot/campaign/test/onboarding_test.gd (C18 and C23 checks) and godot/render/test/hold_beacon_check.gd: the C18 checks call _tip_retire_seen directly, the C23 checks call _relay_line directly, and the label checks inspect the built board; no check drives _tip() with a ship on the relay, and no check drives _end_ship, _next_ship or the activation-complete path. A future edit restoring a direct _tip_retire("fired", ...) at one call site, or another early return in _tip(), would pass every new check while reopening the exact bugs this PR fixes. (All four legs raised this in some form.) Fix: add one dispatch-level check that hovers an occupied relay hex through _tip() and one that ends a ship through _end_ship before the card shows.

3. The relay glide runs in every Hold battle's opening, not only where it teaches. OBSERVED code path, INFERRED reach. godot/scenes/battle/battle.gd: _begin resets relay_glided = false per battle and _start_opening glides to the relay (RELAY_GLIDE 1.2 + RELAY_HOLD 1.0 seconds) whenever _relay_hex() is non-null. Item 23's context is the first battles; a forced camera move in every Hold battle for the whole game is a design choice the Board should make on purpose, not inherit. It ends with the opening if the player keys or clicks, which softens it. Fix: gate the glide to the campaign teaching battle (or the player's first Hold battle) and keep the label, key row and hover rule in every Hold battle.

4. The rule sentence's contest wording and win target are worth one check against the scoring code. OBSERVED text, INFERRED risk. godot/scenes/battle/battle.gd, RELAY_RULE (about line 4841), quote: "no enemy ship there to score 1 (fighters do not count); the first side to 3 wins." The word "there" does not say whether an enemy on a ring hex cancels the score or only an enemy on the relay itself, and the target 3 is a literal in both the rule and the "you %d/3" span. If every Hold objective targets 3 and the contest zone is the relay plus ring, the text is right and this closes with a note; if either varies, the hover teaches a wrong rule. The scoring code was outside this review's pack. Fix: verify both against objectiveTick and the objective data, and if the target can vary, format it from the objective instead of the literal.

## Checked and cleared by the chair (one leg finding does not stand)

Three legs flagged the RELAY label being hidden with no restore ("board.relay_label.visible = false   # no board marks behind the menu") as a risk that opening the menu mid-battle removes the label for the rest of the battle. The chair read the surrounding code at the head: that line sits inside the showcase branch of _begin (godot/scenes/battle/battle.gd:982, with the fills and rings hides at 986 to 987 and the label hide at 988 to 989), the title-screen attract build that drifts the camera behind the main menu and returns at line 999 without ever becoming a playable battle. A real battle never passes through it, so there is no mid-battle menu path that hides the label, and nothing needs restoring. The legs worked from a pack that called it "the menu state" without the showcase context; the pack's phrasing, not the legs' reading, caused the flag. No fix needed.

## Ready

- Item 18 is done properly. _tip_retire_seen (battle.gd:7617) retires the "fired" card only when tip_current == id or tip_dismissed.has(id); all three retire paths (next_ship, end_ship, activation_complete) are converted; grep at the head shows the remaining direct _tip_retire calls retire only "select", "target" and "close"; tip_dismissed is cleared per battle in _begin (line 850). Every leg's Q2 answer agrees: no path in the PR still retires "fired" unseen, and normal retirement after the card has shown or been dismissed still works. Two nuances the Board may want as deliberate decisions, neither is the reported hole (Qwen): dismiss alone does not retire, so a card dismissed in a battle that then ends can appear in the next battle; and a card that showed but was superseded without a dismiss is never retired by this helper.
- Item 23's parts are all present and individually tested: the RELAY label (godot/render/board.gd _relay_label; gold, fixed screen size, no depth test, far edge of the hex, built with or without the O3_11 beacon, absent in Rout battles, exactly-one and inside-hex asserted in hold_beacon_check.gd), the map key row gated on _relay_hex() != null, the one-sentence rule (the C23 check asserts RELAY_RULE.count(".") == 1), the live score in the hover line, "Next to the relay" wording on ring hexes, silence two hexes off, the relay hex added to the opening framing points, and the PR body names the captures for the Board to queue for each item, as the run brief required.

## Verdict on teaching

Turns: yes. A first-time player now actually sees the "Taking turns" card at the hand-over after their first shot, because the three actions that used to kill it unseen can no longer retire it first. Item 18 is complete.

The relay: half. A new player can now find the relay (label, opening glide, key row) and can read the rule and the score while the relevant hexes are empty, including in the move preview. But the teaching fails at the decisive moment: once any ship sits on the relay or next to it, which is the whole mechanic, hover shows a ship card or a weapon forecast and nothing about scoring. Item 23 should not be marked done until finding 1 is fixed; the fix is small (append one already-written line in the dispatch) and the rest of the item is solid.

## Council record

- Rey blind leg: legs/leg_rey.md (written before the external legs were run; its menu-label note is superseded by the chair's checked-and-cleared section above).
- DeepSeek: legs/leg_deepseek.md. Chat: https://chat.deepseek.com/a/chat/s/f17589ea-3000-4c18-8b18-29a8622eafea
- Qwen (Qwen4-Max): legs/leg_qwen.md. Chat: https://chat.qwen.ai/c/08d571ec-cc69-4b3e-86f1-0f64c391da1b
- Gemini on Hydrogen (Flash seat): legs/leg_gemini.md. Chat: https://gemini.google.com/app/f2754748708688ee
- Grok: legs/leg_grok.md (seat empty, bot wall).

Not checked:
- The full CI check list state on head 3efe48c31864; the PR body reports the runner's standing checks and parity as PASS, and the complete Godot suite state was not independently pulled.
- The scoring code behind obj.score and obj.escore (objectiveTick), which finding 4 depends on; only the hover text and its tests were read.
- Whether fighters appear in the unit set _unit_at reads; if they do, a fighter on the relay triggers the same occupied-hex blackout in finding 1, which the fix covers either way.
- Any rendered frame: no GPU capture was run, per the run brief, so label legibility at zoom extremes and the glide's feel are unverified; the PR body names the captures for the Board to queue.
- The "Taking turns" card's own copy; the review covers whether it shows, not what it says.
