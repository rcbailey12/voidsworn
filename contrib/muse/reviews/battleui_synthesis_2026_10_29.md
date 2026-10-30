# Battle UI and selection process audit - synthesis (Oct 29 program)

Four prongs: DeepSeek FRICTION, Argon FRICTION, Rey (blind) FRICTION, Qwen SOUND.

## Verdict: FRICTION (3 of 4; Qwen grades the same defects as fixes and notes)

All four prongs agree on the diagnosis and on the protect item. The disagreement is only whether fire-on-click, as shipped, crosses from a sharp edge into a defect. Three of four say it does, and the chair concurs, for the reason Argon and Rey isolate: the worst case is not a wasted shot, it is an unplanned move.

## The blocker complex, in its sharpest form

1. Clicking an out-of-range enemy does not just fire; it attack-moves (DeepSeek, Argon, Rey; Qwen names the branch but does not grade it). attackMovePlan chooses the destination hex; the player never previews the destination, the arrival facing, or the odds from that hex, because hover odds are computed from the ship's current position. A click the player models as "shoot that" can relocate their ship across the board and then fire. No leg defends this, and it is the form of the problem the synthesis carries as the blocker.
2. Fire-all is the unarmed default and is irreversible (4 of 4 in substance). One click commits every bearing weapon in sequence; there is no undo, and a ship that fired cannot brace. The one action that does get a two-tap confirm is the admiral Command, the rarest click in the battle, while fire, ram, and board get none. Three legs call this protection allocated backwards; Qwen agrees on the facts and proposes the same family of remedy.
3. Inspect and fire share one gesture (4 of 4; Rey states it most cleanly). The same left click inspects or fires depending on selection state; the roster and the board disagree about what clicking an enemy means; and the game's own empty panel teaches "click an enemy to see its weapons," the mental model the fire click betrays.

The remedy family the legs converge on (any one suffices as a direction): a confirm on fire-all and attack-move, an undo window that closes when the first animation resolves, a single-weapon default with fire-all as the explicit gesture, or Qwen's concrete form, a contextual "Fire N weapons" button on the action strip when a target is hovered. The attack-move preview (destination ghost with odds computed from the arrival hex) is a sub-decision any of these should include.

## Findings that stand

1. Weapon sequencing is core combat made tedious (Argon, Qwen, Rey). Ion shield-breakers before hull-breakers is the game's own logic, but the armed weapon resets after one shot and on every selection change, so a sequenced salvo is three manual steps per ship. Candidates: persistent arming per ship, weapon groups, or a salvo checklist in the BattleTech style.
2. Sticky wing selection escapes the cancel paths (Argon, Rey; chair verified with one narrowing). Esc, selectUnit, and rosterPick never clear wingSel, so the next board click assigns a wing order instead of selecting or firing. It does clear once an order is assigned (ui3d.js:425), so the defect is the missing cancel, not permanence.
3. The hint line can declare a ship finished while it still has options (Argon, Rey; chair verified). After any movement with nothing currently hittable, the striphint reads "Nothing left to do: tap Done with ship." regardless of remaining movement or an unspent Brace.
4. Help coverage lags the input surface (DeepSeek, Argon, Rey; chair owned a census error here, the pack implied R was listed). keysHelp omits R, X, G, F, T, and Home, several of them core combat inputs. The pack census error is the chair's, recorded in the Argon screening.
5. Auto-facing optimizes gun count only (Rey). bestFacingReach scores arrival states by ready gun count, then cost, then turns; it never weighs which of your own shield facings you present, and arming a single weapon does not recompute it.
6. The expected-damage line for a hovered move does not name its target (Rey): the number is computed against the auto-facing helper's chosen enemy, and the line does not say which.
7. Smaller agreed notes: Tab cycling falls back to the full list when everything is done (Qwen); the pan-without-zoom camera can leave an enemy activation half off-screen at 20 ships, and a zoom-to-fit-engagement Center is Qwen's candidate; edge indicators are not a direction (already ruled, Oct 28), and the soft action zoom variant remains open.

## What the legs protect (4 of 4)

The pre-commit information layer is the best thing in the battle UI and several legs grade it best in class against the comparator field: per-weapon hit odds by shield facing with expected damage, the likely-kill flag, boon attribution by name, the ghost move preview, and the contextual hint line. Qwen calls the hover tooltip the design's centrepiece. Any remedy for the blocker complex must preserve the speed this layer enables; that is why the legs reach for a confirm or a preview rather than a modal redesign. All comparator claims in all four legs are INFERRED by construction and are weighed as design opinion, not evidence.

## Designer questions

One, for Ryan, in the program report: decouple inspect and target from instant fire (which remedy shape), with the attack-move preview as part of the same call. Everything else on this item is a fix list needing no ruling: the wingSel cancel gap, the misleading hint, the keysHelp omissions, the unnamed expected-damage target, and the Tap wording pass the drift legs also flagged.

## Addendum: designer's ruling (Ryan, Oct 29, 2026, evening)

Ryan declined to pick from the remedy patches and directed the chair to bring back solutions modeled on how comparable tactics games structure activation (move-then-fire turns, combined action-point pools). The chair's solutions memo (battleui_activation_models_2026_10_29.md) mapped five field models and three solutions, and Ryan RULED: phased activation is right. The battle UI direction is therefore Solution 1 from the memo: a move beat with free rehearsal and inspect-only enemy clicks, then a fire beat with odds computed from the real hex and an explicit Fire control, the planner's suggested position offered as a visible ghost, and mid-move fire as an explicit declared choice. The action-point pool stays on file as a named Godot-era experiment, not the direction. The minimal patch is superseded as a standalone option; its honest attack-move preview is absorbed into the phased model.
