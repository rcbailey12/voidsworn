# Leg: DeepSeek (DeepThink on, Search off), issue 2152

Gate record: New chat, account already signed in. DeepThink ON and Search OFF verified before sending (by button state) and again after generation. The first paste became a file chip; the browser removed it and re-pasted in chunks, verifying a single plain-text copy before sending. Chat: "PR 2140 review findings", https://chat.deepseek.com/a/chat/s/f17589ea-3000-4c18-8b18-29a8622eafea

Response verbatim:

CONFIRMED. Artoo is right, and the problem is broader than the filed wording. In godot/scenes/battle/battle.gd:5948-5951, the unit branches return before the relay code at 5973. Exact quote: "return _attack_tip(u["id"])". The other unit branch returns "_ship_tip(u)". Neither _attack_tip nor _ship_tip calls _relay_line. So if the hovered relay hex or a ring hex is occupied by any ship, yours or the enemy's, the relay rule and score line are unreachable.

Q1 Findings

Blocking

1. godot/scenes/battle/battle.gd:5948-5951. Quote: "return _attack_tip(u["id"])". OBSERVED. Any ship on or next to the relay returns a unit tip before _relay_line at 5973, so the relay rule and score vanish in exactly the board states new players will see. Fix: append _relay_line to unit tips or compute and append it after the unit dispatch.
2. godot/scenes/battle/battle.gd, menu state, exact line not in pack. Quote: "board.relay_label.visible = false". OBSERVED assignment, INFERRED runtime effect. The PR shows no code setting it back to true, so after the menu the RELAY label can remain hidden for the whole battle. Fix: set board.relay_label.visible = true when entering play or when the Hold board is built.

High/Medium

3. godot/campaign/test/onboarding_test.gd, C23, exact line not in pack. Quote: "new C23 checks on _relay_line". OBSERVED. The tests call _relay_line directly and do not exercise _tip dispatch with a ship on the relay or a ring hex, so they miss the blocking bypass above. Fix: add a C23 dispatch test with a ship on the relay and on an adjacent hex.
4. godot/render/test/hold_beacon_check.gd, label checks, exact line not in pack. Quote: "board.relay_label points at it". OBSERVED. The check proves the label exists, sits in the hex and draws over ships, but it does not prove visibility after the menu state hides it. Fix: assert the label is visible in the play state after a menu transition.
5. godot/campaign/test/onboarding_test.gd, C18, exact line not in pack. Quote: "calling _tip_retire_seen directly". OBSERVED. The test proves the helper logic in isolation, but it does not prove the three real call sites pass the right reasons at the right times. Fix: add an end-to-end C18 test through next_ship, end_ship and activation_complete.

Ready

No Ready findings from this pack. The item 18 helper itself reads coherently, but the test coverage above is what would earn a Ready.

Q2 Item 18

Yes, _tip_retire_seen closes the stated hole for the "fired" card. It retires only when the card is currently showing (tip_current == id) or has been dismissed (tip_dismissed.has(id)). Before it has shown, neither is true, so the three converted call sites cannot retire it unseen. That preserves the normal path: once it has shown or been dismissed, a later call retires it. No path in this pack still retires "fired" unseen. The remaining direct _tip_retire calls retire other cards ("select", "target", "close"), not "fired".

Q3 Teaching verdict

(a) Turns: better. The "Taking turns" card is no longer retired by End ship, next ship or activation_complete before it shows, so a first-time player can now see it at the next hand-over. (b) Relay: only partly taught. The PR adds a label, key row, hover rule and camera glide, but two failures remain. The relay rule and score disappear when any ship sits on the relay or next to it, and the RELAY label can stay hidden after the menu. So a new player may still not learn the rule at the moment they most need it, when a ship is on or beside the relay, and may not see the label at all.

The strongest objection to the chair's likely synthesis is that item 23's core teaching is not delivered where it matters. The PR's hover rule and label look complete on empty hexes, but in the occupied hexes where a player first asks "what is this, and what do I do here", the rule is unreachable and the label may be hidden, so calling item 23 done would overstate the change.

Not checked:
No rendered frames are in this pack, so label visual placement, readability, camera glide timing and framing, menu-to-play visibility transitions, and the exact menu-state line number cannot be verified from this pack, and the PR body names captures for the Board to queue rather than showing them here.
