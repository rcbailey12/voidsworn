# Leg: Rey (blind), issue 2152

Written before the external legs were run. Evidence: PR 2140 full diff at head 3efe48c31864 (branch work/issue-1403-opus), the full text of godot/scenes/battle/battle.gd at that head (8,199 lines, read directly), issue 1403's run brief, and docs/REVIEW_PROTOCOL.md.

## Artoo's finding: CONFIRMED, and it survives this PR

Artoo said _attack_tip returns early when a ship sits on the relay hex, so the relay rule and score line disappear (filed against godot/main/battle.gd; the file now lives at godot/scenes/battle/battle.gd). Reading _tip() at head 3efe48c3 (line 5935): the dispatch returns before the relay line is ever considered whenever the hovered hex holds a unit. Line 5948 to 5949: "if not u.is_empty() and u["side"] == "enemy" and _usable(s):" then "return _attack_tip(u["id"])". Lines 5950 to 5951: any other unit returns _ship_tip(u) plus an entry reason. The relay line is only added on the two empty-hex paths: appended in the move-range branch (line 5967 to 5968, "t += "\n" + rl") and prepended in the fallthrough (lines 5972 to 5974, "return relay + ("\n" + rest if rest != "" else "")"). _attack_tip itself (line 6058) builds the weapon forecast and returns it without touching _relay_line. So the PR adds the relay hover rule everywhere EXCEPT the one state the rule is about: a ship sitting on the relay hex (or on a ring hex). Hovering your own ship holding the relay shows the ship card; hovering the enemy ship holding it shows the attack forecast; neither shows "you 1/3, them 2/3" or the rule. OBSERVED from the code at the pinned head.

## Blocking

1. Occupied relay hex hides the relay rule and score (above). Fix: in _tip(), compute the relay line before the unit branches and append it to the _attack_tip and _ship_tip returns (and to the nova, ram and board tip returns for completeness), or append inside _attack_tip and _ship_tip when the target unit stands within 1 hex of the relay.

## High / Medium

2. The relay glide runs in every Hold battle's opening, not only the teaching battle. _begin resets relay_glided = false per battle (diff, battle.gd _begin) and _start_opening glides whenever _relay_hex() is non-null. Item 23's context is the first battles teaching the relay; a forced 2.2 second camera move (RELAY_GLIDE 1.2 + RELAY_HOLD 1.0) in every Hold battle for the whole campaign, skippable only by ending the opening, is a design choice the Board should make deliberately. INFERRED (the code path is OBSERVED; whether skirmish and later campaign Hold battles all run _start_opening the same way was not traced). Fix: gate the glide to the campaign teaching battle (or the player's first Hold battle) and keep the label, key row and hover for every Hold battle.

3. The item 18 tests call _tip_retire_seen directly rather than driving _end_ship, _next_ship or the activation-complete path, so a future fourth direct _tip_retire("fired", ...) call site would not be caught by the C18 checks. The current code is clean (grep at head: the only _tip_retire call sites for "fired" are the three converted ones; the remaining direct calls retire "select", "target" and "close"). Fix: add one onboarding check that ends a ship through _end_ship before the card shows and asserts "fired" is not retired. OBSERVED.

4. The menu state hides the RELAY label (battle.gd diff: "board.relay_label.visible = false   # no board marks behind the menu") and nothing in the PR sets it visible again; the label is rebuilt by _terrain on the next battle build, so the risk is only within one battle's menu open and close cycle, which was not traced end to end. INFERRED, low. Fix: restore label visibility alongside fills and rings when the menu closes, or confirm the existing restore path covers props children.

## Ready (what the PR gets right)

- Item 18's mechanism is correct and minimal: _tip_retire_seen retires "fired" only when tip_current == id or tip_dismissed.has(id) (battle.gd line 7617 to 7619 at head), all three retire paths (next_ship, end_ship, activation_complete) are converted, and tip_dismissed is cleared per battle (line 850), so a dismissal in an earlier battle cannot retire the card unseen in a later one. Dismissing the card alone does not retire it; ending a ship after it has shown does. Both are tested.
- Item 23's four asks are all present: a RELAY label on the board (gold, fixed screen size, no depth test, at the hex's far edge, works with or without the O3_11 beacon, absent in Rout battles, all tested in hold_beacon_check.gd), a map key row ("Relay (gold hex)" with the rule), a one-sentence hover rule (the test asserts RELAY_RULE.count(".") == 1) with the live score "you %d/3, them %d/3", ring hexes labelled "Next to the relay", silence two hexes off, and one camera glide in the opening. The opening framing (_opening_points) now includes the relay hex as an objective hex.
- The PR body names the captures the Board should queue for each item, as the run brief required (C18: fire once, press Space, capture the next hand-over; C23: three frames).

## Verdict on teaching

Turns: yes. Item 18 closes the exact hole the council found (the Taking turns card could be retired unseen by the actions around it), and the fix is at the right layer. The relay: a new player can now FIND it (label, glide, key row) and can read the rule while the hex is empty. But the rule and the score vanish at the moment of first contact, when the player's own ship is sitting on the hex and the score is about to change, which is when a first-time player most needs "you 1/3, them 2/3" in front of them. With finding 1 fixed, the teaching is complete; without it, the PR teaches where the relay is but not, at the decisive moment, what it does.

Not checked:
- The full CI check list state on head 3efe48c3 (the PR body reports the runner's standing checks and parity as PASS; the complete Godot suite state was not independently pulled).
- Whether _start_opening runs identically in skirmish Hold battles (finding 2's reach).
- The within-battle menu close path for the label visibility (finding 4).
- Any rendered frame: no GPU capture was run, per the brief.
