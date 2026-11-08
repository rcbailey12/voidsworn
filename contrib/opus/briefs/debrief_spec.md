# Debrief specification (MN8, MN9; issue #231, feeds #92)

Opus, Nov 8 2026. FINDINGS R136. Part of the consolidated UI specification ([ui_spec.md](ui_spec.md)); its size, colour and focus rules apply here.

The UI audit found no debrief specification: the run's lesson reached the player as paragraphs inside other screens (MN8). Since then the run-end page has grown an inheritance panel (#91 and the progression steps: renown and affordability, lineage, shadow learning, core sync, heir naming), and Ryan ruled the Muse debrief design on Nov 2 (contrib/muse/design/debrief_screen_2026_11/synthesis.md, owner rulings after its section 11). This file is the one statement of what a debrief must show, in what order, against the text that ships today. #92 builds it.

Mock for Ryan: docs/shots/ui231/debrief_sheet.png, today's end page beside this layout for the same run (godot/campaign/test/debrief_mock_shots.gd). The mock is built from the campaign UI's own parts; it is a picture of the spec, not the build.

## 1. What a debrief is for

A run is meant to be lost. The run debrief is where a death stops reading as failure, because it names what the run bought for the next fleet (the Job 7 synthesis calls it the most important screen in the game). So the order is: what happened, then what was inherited, then the record. The battle debrief is shorter: what the fight paid and cost, and anything the enemy taught.

## 2. The run debrief (the end page)

### 2.1 Frame

- The shipped end page frame: a centred scroll column, horizontal scroll off. The column widens from px(720) to px(960) (owner-ruled design); the scroll box is px(1000) wide and at most px(1000) or the window height minus px(40) tall.
- One layout at 1080 design values through the shared scale law; 4K is the same layout at k 2.0.
- Text: campaign base 17; no text below the 12 floor (the first-loss kicker and the row heads sit at 12 and 13). Display face for the page title only; Oxanium small caps for the panel and row heads.
- Motion: rows appear, nothing slides (and nothing moves at all under reduce motion).
- Keyboard: focus starts on the primary exit (New run, or Play as on a win), so Enter continues; Tab walks the buttons in reading order. Every exit works with no other interaction.

### 2.2 Order, top to bottom, on every outcome

1. **Headline.** Kicker (first loss only, 12 small caps, gilt); title (62 display, centred): the faction's win title, "The fleet is lost" or "Run abandoned"; sub (20); the story arc line (18, gilt, centred) only when it differs from row 5's line (the duplication rule).
2. **First-loss teaching block** (the literal first loss only; ruling Q1 a): a gilt-bordered panel with the teaching body, above the inheritance panel so the lesson frames the ledger. A faction's first loss after that gets its kicker and sub only.
3. **Inheritance panel.** Header "WHAT THIS RUN BOUGHT" (win and loss) or "Recorded" (abandon). Lead line "What this victory bought:" or "What this death bought:" (none on abandon). Five rows, each a 13 small-caps head, then 17 body and 15 secondary lines, separated by 1 px IRON3 rules:
   1. Doctrine and renown
   2. Lineage (shadow learning as sub-lines inside it, never a sixth row)
   3. Core sync
   4. Nemesis lesson
   5. The record (the faction's authored payoff line)
4. **Heir block**, its own panel below.
5. **Recap**: stat tiles, standout ship, surviving fleet rows, captains lost, best sector or victories.
6. **NEXT RUN** panel (wins only).
7. **Exits**, last.

Rows never vanish: an empty row shows its one dim line, so the frame is the same every time and the player learns where each kind of news lives.

### 2.3 The rows against what ships today

What the shipped page (campaign_ui.gd `_end`) shows now, and what changes:

| Spec row | Data today (campaign.gd) | Shipped today | Change for #92 |
|---|---|---|---|
| Headline | WIN_TITLE, shipped subs, `_story_text` | title, sub, then the faction's payoff line in gilt, then the story line | the payoff line moves to row 5; the story line follows the duplication rule; kicker and first-loss sub added |
| First-loss block | META.stats; needs a stored profile flag | none | new: the flag (set when the block first renders; an abandon never sets it), the neutral and Crusade copy (design 4.2) and five more faction kicker and sub pairs (an authoring item) |
| Panel header | | "YOUR INHERITANCE" (24 semibold) and a lead line | "WHAT THIS RUN BOUGHT" or "Recorded" in small caps; the outcome lead line |
| 1 Doctrine and renown | carry.ren, inheritance.balance, inheritance.affordable (with fresh), carry.hl | renown and balance on one line; "Affordable now" list of every affordable item | one lead line ("Renown: +N earned. N in the vault."); a dim composition line (battles x2, elites x4, flagships x15, kills / 4, sectors reached x5); one affordability line naming the cheapest newly affordable item and a count ("and N more within reach"), or the distance line to the cheapest item; one "Spend renown" button (routes to Progression on that item's tab, or admiral select for an admiral unlock). Under the playtest switch: "Playtest: everything unlocked. Earnings recorded." and View buttons |
| 2 Lineage | inheritance.flown (level, xp, next, remaining, pending, chosen, earned), carry.mxGain, mxOverflow, shadowBank, inheritance.shadow | all present as separate lines and a SHADOW LEARNING head | a mastery bar; the pending-picks line becomes the button "Choose (Name)'s level (N) skill" (routes to the lineage screen); shadow rows become sub-lines, the heir's tagged "Heir: double rate."; the Heat XP line (R63 shape) sits here: "Heat (H) paid (2H) XP to (Admiral) and (H) XP to the faction shadow pool." |
| 3 Core sync | inheritance.cores (ticked cores only, tierUp) | present when a core ticked; nothing when none | tier-up lines first, in the core's colour; the empty line "No protocols taken this run." always shows when none ticked |
| 4 Nemesis lesson | the run's hunters (`nemActive`, the #120 commander registry RUN.nems: revealed, adapt, beaten, dead, loot); per-run lesson log not recorded yet | none | new row in the design's line shapes (design 4.4). Weaknesses found or taught, adaptations gained (shown here only, R62), raid losses, his death. Until #24 and #122 record the per-run log, the row reads each hunter met this run (revealed weaknesses, beaten, dead), one line each, hunter-specific (ruling Q4); empty line "No Nemesis meeting this run." |
| 5 The record | TB.STORY_BEAT3[fac].learning | shown at the top in gilt | moves here, in BONE at body size, every run end (ruling Q3) |
| Heir block | META.heirs, shadowAdmirals | "Name an heir" head, a rule line, one button per benched admiral | its own panel: the current-heir line always; the choice rows behind a "Change heir" action; select then confirm; the confirm line restates the effect ("Named: (Admiral). The (line) line earns double shadow until you name another."); empty state when no benched admiral exists |
| Recap | RUN.stats, fleet car, RUN.fallen, META.stats | as specced | tiles wrap inside the 960 column at px(150) min width (was 120) |
| NEXT RUN | nextFacPick | as specced | the suggestion is the unwon faction with the most progress |
| Exits | endActions | at the end | unchanged; focus starts on the primary |

### 2.4 Copy

The exact copy is the design's section 4, unchanged, with these notes from the shipped game:
- Shipped strings win where they differ from the design (design 4.9). The loss sub and the abandon sub are shipped.
- The Heat line takes the R63 shape (Heat now pays XP, #26 and #241). Flag for #92 and the Board: `endRun` still also multiplies renown by 1 + 0.1 x Heat (campaign.gd `endRun`), so today a Heat run pays both. If both stay, the renown line keeps its "Heat (H): renown paid at x(1 + 0.1H)." note as well; if the multiplier was meant to go with #26, that is a rules fix for its own issue, not for the debrief.
- Plain ASCII, no em dashes.

## 3. The battle debrief (the after-battle modal)

Shipped (campaign_ui.gd, the "victory" modal): the title ("Victory" or "Flagship destroyed"), the story beat debrief line in gilt, the result line (kills, rounds, credits in gilt), losses in BLOOD, the extra line, the protocol line, the flag transfer line, then rewards. A loss in battle ends the run and goes to the run debrief.

Spec, top to bottom:
1. Title: the outcome.
2. The result line: kills and rounds, then the pay in gilt.
3. What it cost: ships and captains lost, in BLOOD. Always directly under the pay, never below the story text.
4. What the enemy taught, when a Nemesis was met: one line in the run debrief's row 4 shapes (a weakness found or taught). Adaptations stay hidden until the run debrief (R62).
5. The flag transfer line, when it happened.
6. The protocol line (when no protocol triggered).
7. The story beat debrief line, last before the buttons: it is colour, not information.
8. Continue (focused).

The change for #92: lines 4 and 7 move (the story line from second to last; the Nemesis line is new, from the nemAfterBattle lines the battle already emits). Everything else is shipped.

## 4. Loading (MN9)

What a loading cover must show: one line saying what is being prepared ("Preparing the sector..." today), centred, in the body face at 24 on the shared scale (this PR: it was a fixed 24 at every size). No progress bar, because the cover waits on shader warm-up, which has no known length (load_screen.gd `settle`, capped at 12 s). No tips: a cover that lasts one to three seconds cannot be read, and teaching belongs to the tip cards. No animation under reduce motion; none today.

## 5. Ryan's review round (the Board routes it)

**Ruled (R137, Nov 8 16:53 CST):** Ryan said yes to this layout as #92's target, content and order. The look itself waits for the UI redesign's style guide (#270, #271); #92 builds after it.

One image, docs/shots/ui231/debrief_sheet.png: left, today's end page for a sector II loss; right, the same run laid out by this spec. The questions for that round, each with Opus's pick:
1. Does the inheritance panel read as "what this death bought" before the stats? Pick: yes, the panel above the recap, as ruled Nov 2.
2. Is the 960 column right at 1080 and at 4K? Pick: yes (ruled Nov 2; the mock shows it).
3. Anything to cut? Pick: nothing; empty rows keep the frame stable.

## 6. Not checked

- The mock fills the Nemesis row from the run's own Nemesis record; the per-run lesson log (#24, #122) does not exist yet.
- Spend routing and the heir confirm are drawn, not wired, in the mock.
- The first-loss kicker and sub for the five non-Crusade factions are not authored (an authoring item for #92).
