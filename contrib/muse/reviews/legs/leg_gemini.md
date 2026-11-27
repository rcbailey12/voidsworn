# Leg: Gemini on Hydrogen (the Flash seat), issue 2152

Gate record: New chat on gemini.google.com. Model picker showed Hydrogen selected before pasting and the composer still showed Hydrogen after generation. Brief pasted as plain text, no file attached. Chat: "PR 2140 Review Council Evaluation", https://gemini.google.com/app/f2754748708688ee

Response verbatim:

CONFIRMED (expanded): Artoo's finding is confirmed and actually broader than stated. In godot/scenes/battle/battle.gd lines 5948-5951, _tip() checks _unit_at(hover.x, hover.y) and returns early on both enemy units (_attack_tip on line 5949) and friendly or non-attackable units (_ship_tip on line 5951) before _relay_line is ever reached on lines 5967 or 5973. The relay rule and score line disappear whenever any ship - friendly or enemy - occupies the relay hex or any of its 6 adjacent ring hexes.

Q1. Findings

Blocking
None.

High/Medium

1. godot/scenes/battle/battle.gd:5948-5951
Quote: "if not u.is_empty(): return _ship_tip(u)"
Status: OBSERVED
Why it matters: Because scoring requires placing a ship on or next to the relay, the exact hexes a new player hovers during contest are occupied, hiding the relay score and rule when needed most.
Fix: Append "\n" + _relay_line(hover.x, hover.y) (when non-empty) to the returns on lines 5949 and 5951, or inside _attack_tip and _ship_tip.

2. godot/scenes/battle/battle.gd (menu state, line not numbered in pack)
Quote: "The menu state also sets board.relay_label.visible = false ("no board marks behind the menu"); nothing in the PR sets it back to true."
Status: OBSERVED (pack text) / INFERRED (impact depends on whether _terrain rebuilds on resume)
Why it matters: If a player opens and closes the menu mid-battle without _terrain rerunning, the 3D "RELAY" board label stays permanently invisible.
Fix: Set board.relay_label.visible = true when leaving the menu state (guarded by is_instance_valid(board.relay_label)).

Ready

godot/render/board.gd (line not numbered in pack)
Quote: "builds a gold "RELAY" Label3D (font 40, fixed screen size, billboard, no_depth_test, render_priority 2) at the hold hex centre offset (0, 0, -HS * 0.55)"
Status: OBSERVED
Why it matters: Solid placement; offsetting along -Z places the label above/behind the hex center so it avoids overlapping the ship itself while staying readable over hulls via no_depth_test.
Fix: No code fix needed; verify readability against bright backgrounds in rendered frames.

Q2. Item 18 analysis

Yes, _tip_retire_seen closes the premature-retirement hole without breaking normal retirement, based on the facts in this pack.

Before the card shows: tip_current is not "fired" and tip_dismissed does not contain "fired", so calling _tip_retire_seen("fired", why) from next_ship, end_ship, or activation_complete does nothing. The card survives until hand-over.

Once the card shows or is dismissed: when _tutorial displays the card, tip_current becomes "fired"; if the player dismisses it, tip_dismissed gains "fired" (and _tutorial will not show it again this battle because tip_dismissed is only cleared in _begin). On the next next_ship, end_ship, or activation_complete call, tip_current == "fired" or tip_dismissed.has("fired") evaluates true, calling _tip_retire("fired", why) so the card never reappears in future battles.

Paths that still retire "fired" unseen: None exist in the pack (the pack establishes that the three converted sites are the only _tip_retire call sites for "fired"). Note that the pack does not show the full body of _tutorial or where tip_current is cleared, so if tip_current is cleared before one of the three retirement hooks fires AND the player did not dismiss the card, retirement would defer until the next battle (not unseen retirement, just delayed retirement).

Q3. Teaching verdict

(a) How turns work: Yes, mostly. Fixing the premature retirement means the "Taking turns" card now actually reaches the screen at the first hand-over after the player shoots, rather than vanishing silently when the player ends their ship's turn. Whether the card text itself is clear cannot be judged because its copy is not in the pack.

(b) What the relay is and how it scores: Partially, with a major mid-fight blind spot. At battle start, the camera glide, hold, 3D "RELAY" label, and map key row clearly establish where the relay is. However, teaching how it scores fails during active play in two places:

Hovering any ship on or adjacent to the relay suppresses the hover tooltip's relay rule and score line (lines 5948-5951), stripping away scoring feedback right when ships are contesting the zone.

If opening the pause/game menu hides board.relay_label without restoring it on resume, the 3D marker vanishes for the rest of the battle.

Single strongest objection to the chair's likely synthesis

The chair is likely to treat this PR as ready to merge with a minor follow-up because CI checks pass and both issue 1403 items are nominally implemented. The strongest objection is that Item 23's hover rule fails under the exact condition the rule describes: you score by putting ships on or next to the relay, yet _tip() suppresses _relay_line whenever a ship is on or next to the relay. Shipping Item 23 without fixing lines 5948-5951 leaves the scoring rule invisible during the actual contest for the relay.

Not checked:

Exact line numbers and surrounding code for the menu state visibility toggle in godot/scenes/battle/battle.gd (and whether returning from menu rebuilds _terrain or restores board.relay_label.visible).

Exact copy/wording of the "Taking turns" teaching card and where tip_current is set or cleared in _tutorial.

Rendered visual frames (the pack states no rendered frames are included, so label legibility, fixed-size scaling, and camera glide framing on live boards were not verified).

Full diffs of godot/render/board.gd, godot/campaign/test/onboarding_test.gd, godot/render/test/hold_beacon_check.gd, and godot/tools/ci/godot_checks.txt beyond the pack's summary.
