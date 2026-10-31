# Red Team Audit: UI/UX Seat, Voidsworn "Embers of the Hollow Sun"

Seat: interface, flow, readability, input, onboarding, accessibility sub-lens.
Pack pin: main head b3a3b802, browser code 264f441d.

## Findings, ranked by severity for this seat

### 1. Attack-move fires and relocates on a single unpreviewed click [OBSERVED]

The blocker the FRICTION verdict rests on is confirmed in the pack's evidence. A left-click on an out-of-range enemy does not merely shoot: "attackMovePlan chooses the destination hex" and the ship sails there, then fires. "The player never previews the destination, the arrival facing, or the odds." Hover odds are computed from the ship's current position, so the numbers the player reads before clicking are the wrong numbers for the shot that actually fires. Three of four prongs (DeepSeek, Argon, Rey) agree; the chair concurs.

Phased activation is the ruled direction and I do not relitigate it. I note its cost: the pre-commit information layer (per-weapon hit odds by shield facing, expected damage, likely-kill flag, ghost move preview) is called "the best thing in the battle UI" and "best in class" by the protecting prongs. The phased model preserves this layer in principle ("free rehearsal and inspect-only enemy clicks" in the move beat, "odds computed from the real hex" in the fire beat), but every engagement now requires two explicit beats where the current model requires one gesture. At the 20-ship typical-battle target, that doubles the per-round interaction count. The ruling absorbs the attack-move preview as "a visible ghost," which is correct, but the pack contains no interaction spec for how rehearsal, inspect-only clicks, and the fire beat sequence on a 20-ship board without the hover-tooltip speed the design currently earns its praise from. That spec is the real work, and it is not in the pack.

Cost: the single worst interaction in the game ships today in the browser build. A click the player models as "shoot that" can relocate a ship across the board. Every battle, every player, every session until the Godot phased model lands.

### 2. The campaign layer is structurally untaught; the assembled tips have no delivery surface [OBSERVED]

The firstrun SYSTEMIC TEACHING FAILURE verdict is confirmed. The code is unambiguous: "tutorialCheck returns whenever there is no battle object" and "the map screen nulls the battle object." The map, routing, patrons, command points, and run structure receive zero contextual teaching, "by construction rather than by weak writing." The assembled campaign tips (c_map through c_loss, 16 entries) are good copy. The c_shipyard tip correctly carries the ruled repair principle. The c_boon tip explains rarity and the reroll. But the pack shows no code path that can display them. tutorialCheck gates on battle presence; the campaign layer has no equivalent checker. The tips are a manuscript with no printing press.

I attack the severity grading on one axis: three of four prongs grade this LOST IN THE VOID. The battle layer is taught. Ten tips fire, the hint line teaches where to click, and the "Carried forward" panel itemizes renown and mastery XP on a lost run. The first mastery threshold is 6 XP, reachable in a sector 1 run. The failure is real but concentrated in the campaign and meta layers; the battle layer's teaching works. Qwen's ROUGH EDGES understates the campaign gap; LOST IN THE VOID overstates the total picture. The accurate grade is: the battle is taught, the run is not.

Cost: the game's designed contract (generational runs, loss as curriculum, run 1 near-impossible) is never stated to the player in the first-run path. The player who loses run 1, which is nearly all players, has no frame for why that loss is the point. The "Carried forward" panel shows currencies, not story.

### 3. Fire-all is irreversible and unconfirmed; the rare Command gets a two-tap confirm [OBSERVED]

Confirmed across all four prongs. "One click commits every bearing weapon in sequence; there is no undo, and a ship that fired cannot brace." The one action that receives a two-tap confirm is the admiral Command, "the rarest click in the battle." Fire, ram, and board get none. Three prongs call this "protection allocated backwards." The pack's own TIPS array teaches the player to "click to fire every weapon that bears," which makes the irreversible commitment the default taught behavior.

Under phased activation, the fire beat gains "an explicit Fire control," which addresses this. But the browser build ships today with the unconfirmed fire-all, and the pack contains no interim patch. The Qwen remedy ("a contextual 'Fire N weapons' button on the action strip") is noted in the synthesis as one acceptable shape. None is implemented.

Cost: every player who misclicks in the browser build loses a full salvo and the brace option on that ship, with no recovery. In a game with 80 percent loss by design, the punishment stack for a UI misclick is disproportionately severe.

### 4. Accessibility: text size and contrast FAIL, and the worst offender is the controls help line [OBSERVED]

Confirmed. The chair's accessibility synthesis grades text FAIL over Qwen's PARTIAL, and the evidence supports FAIL. "Battle HUD body text is 14-15 px at 1080p against an 18 px PC guideline floor." The scaling floor produces a worst case: "the scaling floor takes the help line to about 7 px." The controls help line, the single line that teaches the player what the keys do, uses colour #7d7768, which "computes to roughly 3.1:1 to 4.2:1" against every plausible background, under the 4.5:1 WCAG 1.4.3 bar. The line that teaches the controls is the worst offender on both size and contrast simultaneously. The fix is identified in the pack: move to BONE2 #b3aa95, which "already passes at about 5.96:1 to 7.82:1." One colour change, one settings entry, one hook (the existing s(v) function).

Cost: the readability floor of the game is below the accessibility bar on the exact element whose job is to make the game legible. A player with moderate low vision cannot read the control instructions.

### 5. The tutorial card teaches a wrong visual cue in every captured state [OBSERVED]

Confirmed from the HUD synthesis. "It says the Command glows gold; in every image Command is dark and Pass or End turn is gold." This contradiction appears in all three capture batches. The card also "covers the approach lane and the carrier plates." The synthesis calls this "the highest-leverage single fix in this audit," and I concur. A first-battle tutorial card that teaches the player to look for a gold glow on the wrong button will produce misclicks in every first battle until corrected, and the misclicks will look like player error rather than a text defect.

Cost: the first battle is the onboarding moment. Teaching a wrong cue there poisons the player's model of the entire activation system, which is the system the phased-activation ruling is trying to rebuild trust in.

### 6. Input remapping is absent; no InputMap, no gamepad path, no rebind surface [OBSERVED]

Confirmed. "No [input] section, no InputMap use, no gamepad references anywhere in the pack." The browser build uses fixed key checks. The Godot build, per the accessibility review, has the same gap. The fix is scoped in the pack: "Define named actions, convert the fixed key checks, store overrides through the existing settings save flow, expose a basic rebind list." This is graded as "the feature the guidelines treat as basic." Additionally, "the help line omits four documented keys (X ram, G board, Space hurry, V firing arcs)."

Cost: players who cannot use the default key layout cannot play. This is a structural exclusion, not a polish gap. The turn-based core and absence of timers mean the game is otherwise well-suited to remapping; the absence is a missing wire, not a design conflict.

### 7. Inspect and fire share one gesture; the roster and the board disagree [OBSERVED]

Confirmed across all four prongs. "The same left click inspects or fires depending on selection state." The roster panel and the board surface assign different meanings to clicking an enemy. The game's own empty panel teaches "click an enemy to see its weapons," which is "the mental model the fire click betrays." The phased activation ruling addresses this: the move beat makes enemy clicks "inspect-only," and the fire beat is explicit. But the browser build ships the conflated gesture today, and the TIPS array reinforces it ("click to fire every weapon that bears").

Cost: every new player must unlearn the inspect mental model the game itself taught them, then relearn the fire model, within the same battle. The confusion is not a learning curve; it is a contradiction.

### 8. The sticky wing selection escapes all cancel paths [OBSERVED]

Confirmed. "Esc, selectUnit, and rosterPick never clear wingSel, so the next board click assigns a wing order instead of selecting or firing." The defect is bounded: "It does clear once an order is assigned (ui3d.js:425), so the defect is the missing cancel, not permanence." But the bounded nature does not reduce the confusion: the player presses Esc expecting to reset, clicks the board expecting to select a ship, and instead issues a wing order. The action is silent and irreversible in the moment.

Cost: in carrier-heavy fleets (the densest formation in the game, already suffering nameplate merge per the HUD audit), the wing-selection leak turns routine board clicks into unintended squadron orders. The player cannot tell this happened until the wing moves.

### 9. The hint line declares a ship finished while options remain [OBSERVED]

Confirmed. "After any movement with nothing currently hittable, the striphint reads 'Nothing left to do: tap Done with ship.' regardless of remaining movement or an unspent Brace." The hint line is otherwise praised as the game's "one strong micro-teacher" that "teaches where to click." This defect inverts that function: the strongest teaching surface tells the player to stop when the ship still has actions. Under phased activation, the hint line must additionally distinguish between the move beat and the fire beat, a state the current hint logic does not model.

Cost: the player trusts the hint line because it is usually right. When it lies, the player learns not to trust it, and the cheapest teaching surface in the game devalues itself.

### 10. Zone colours carry opposite tactical meanings by hue alone at failing contrast [OBSERVED]

The browser build's ZONE_INFO defines exit as #7dff9b (green) and guard as #e07a70 (red). The accessibility review confirms: "Exit green and guard red sit at about 1.46:1 and 1.23:1 composited, a red-green pair carrying opposite meanings by hue alone." This fails WCAG 1.4.1. The fix is scoped: "Add icons or short labels and an edge pattern difference per zone type." The faction crest shapes in crest.gd are noted as "a genuine second channel that currently lives in the career UI" and should be drawn on the selected ship panel and ship markers.

Cost: a colour-blind player (roughly 8 percent of male players) cannot distinguish a safe exit zone from a station perimeter under threat. The meanings are opposite: one is escape, the other is danger. The information is present but the channel is exclusive.

## Verdict

FRICTION CONFIRMED on the battle UI; NOT READY confirmed on HUD readability and player-facing text; SYSTEMIC TEACHING FAILURE confirmed on the campaign layer with the battle layer exempted; accessibility FAIL on text and NOT PRESENT on input remapping. The single most important attack: the browser build ships an interaction model where clicking an enemy to inspect it can silently relocate your ship across the board and fire every weapon, with no preview, no confirm, and no undo, and the game's own tutorial teaches the player to click that way. Phased activation is the correct ruled direction, but the pack contains no interaction spec for how it preserves the hover-tooltip speed at 20 ships, and every session played in the browser build before Godot cutover plays the defect as shipped.

## Not checked

- Drift ROT (3 of 4): the drift synthesis is named in the claims register but its content is not in this pack. I cannot confirm, attack, or grade it from the evidence provided.
- 216 tree texts, 33 event variants, 41 Nemesis lines, 30 firstrun framing units, Eclipse battleship entry (d_meridian vs d_wraith): these are listed as "awaiting a story attack." The pack contains the assembled tutorial tips and the firstrun framing structure but not the tree texts, event variant bodies, or Nemesis line content. I cannot judge their readability, text size fitness, or delivery surface from this pack.
- The Godot build's HUD and battle UI in play: the HUD synthesis is built on nine still images from three G2 commits. No video, no input trace, no session replay is in the pack. I cannot judge flow, timing, or animation-legibility interaction from stills.
- Controller and gamepad flow: the pack confirms no gamepad path exists. I cannot audit what is not there beyond recording its absence (Finding 6).
- Mobile and tablet layout: the browser build references G.mobile in ui3d.js conditional logic, but no mobile capture or layout evidence is in the pack.
- The phased-activation interaction spec: the ruling names the direction (move beat, fire beat, rehearsal, ghost position). No wireframe, flow diagram, or interaction specification for the phased model is in the pack. I can confirm the direction is correct and flag the cost (Finding 1), but I cannot audit the design.
- Sound and caption interaction: the accessibility review notes "no caption or subtitle system exists, and no spoken content is evidenced in the pack." Whether sound cues carry gameplay information exclusively is not determinable from this evidence.
