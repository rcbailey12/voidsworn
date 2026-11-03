Both gates passed: the model selector showed Qwen3.8-Max before sending, and the chat header still showed Qwen3.8-Max after generation started.

Qwen returned TWO complete responses with a "Which response do you prefer?" picker. No preference was clicked. Both responses are filed below, labeled Response 1 and Response 2.

---
Response 1

1. LAYOUT SPEC

The screen is a single centred VBox column, minimum width px(720), separation px(10), inside a ScrollContainer with horizontal scroll off, exactly as the current end screen (campaign_ui.gd:1091 to 1093). Scroll height is capped at min(px(1000), viewport height minus px(40)). At 3840x2160 everything doubles via px(); no separate 4K layout.

Panel order, top to bottom, with the reason each sits where it does:

1. Headline block (title, sub line, story line). The player must first read what happened and feel the result before the numbers.
2. Inheritance panel (five rows). The screen's purpose: what this death or victory bought. It follows the headline so the player understands the cause before the reward.
3. Heir naming interaction. A choice the player makes, so it sits after the inheritance is visible but before the recap, so the choice is informed.
4. Stat tiles row. Quick numeric recap, a breath between the inheritance and the fleet detail.
5. Standout ship and surviving fleet. The longest block; the player scans it at leisure.
6. Captains lost. One line, quiet, after the fleet.
7. Exit buttons. Always last; the player leaves forward into the next run or the Progression screens.

Width behaviour: every panel is full column width px(720). Stat tiles flow in a row of min px(120) each, wrapping to two rows when the column narrows below px(720). At that width, the inheritance rows stack with the tag above the body.

Scroll boundary on a rich debrief (all five inheritance rows populated, Nemesis met, cores ticked, heir block, standout ship and six survivors): the column reaches px(1140) tall and scrolls. A minimal debrief (no Nemesis, no cores, no heir, no survivors, loss) fits within roughly px(620) and no scroll appears.

Structural changes by outcome:
Win: headline uses the faction WIN_TITLE. The NEXT RUN suggestion panel (a card naming an unwon faction) appears between the fleet and the exits. Exit buttons are "Play as (faction)" primary plus "Pick a faction" and "Title screen".
Loss: headline is "The fleet is lost". No NEXT RUN panel. Exit button is "New run" primary plus "Title screen". First-ever loss adds a teaching block inside the headline area (see copy section).
Abandon: headline is "Run abandoned". The inheritance panel header reads "Recorded". No NEXT RUN panel, no first-loss teaching block. Exit buttons are "New run" and "Title screen".

Components used: panel for the inheritance block and the CARRIED FORWARD frame; card for the NEXT RUN suggestion; abtn for the exit buttons; bar for the tree progress and core progress bars; choice for the heir naming rows; the existing campaign_ui end page VBox, ScrollContainer and panel patterns are reused, not rebuilt.

2. PANEL INVENTORY

Headline block. Title in Michroma 62px centred. Sub line 20px BONE. Story line 18px GILT centred (story text from the faction's authored beat).
Inheritance panel. A single panel (gilt border, GLASS fill) with a small-caps header 12px BONE3 letter-spaced, five rows. Each row: a 12px font_caps tag on the left, body text 16px-17px BONE on the right, separation px(8).
Shadow earnings sit inside the lineage row as indented sub-lines (15px BONE2) rather than a sixth row, because shadow XP is lineage, not a separate inheritance type.
Heir naming interaction. Appears below the inheritance panel. Uses choice components at full column width, one row per benched same-faction admiral plus a "name no heir" row. The selected row gets a GILT left accent bar.
Stat tiles. Row of tiles: battles won, flagships destroyed, enemy ships destroyed, ships lost, time in run. Numbers 26px GILT semibold, labels 12px BONE2 caps.
Standout ship and surviving fleet. Best ship in a gilt-bordered panel. Fleet rows 15px. Source: campaign_ui.gd:1091 to 1093 and the fleet roster.
Captains lost. One line of names, 15px BONE2. Source: RUN.fallen core.js:66. Empty state: hidden when no captains were lost.
Exit buttons. abtn components. Primary action gilt fill, dark text. Secondary actions standard. Spend routing buttons sit below the inheritance panel as secondary abtn buttons.

3. EXACT COPY

Win headline: the faction WIN_TITLE (e.g. "The crusade endures"). Sub: "Three sectors broken, three more to come" (shipped win sub, with sector count from the run).
Loss headline: "The fleet is lost". Sub: "The last hull goes dark in sector (N). The survivors will carry the line forward."
First-ever loss. Headline: "The fleet is lost". Sub: "The last hull goes dark in sector (N)." Teaching block: "The line continues. Your doctrine, your lineage and your cores are recorded below. Nothing you earned is lost to the next run."
Nemesis lesson lines (faction-neutral, using (Name) and (Title) slots):
Weakness revealed: "(Name), (Title) — Weakness found: (Weakness). Strike it and the hunt turns."
No weakness yet: "(Name), (Title) — No weakness found yet. Survive another encounter to learn more."
Heir naming prompt. Question line: "Name an heir. This line's shadow earnings will double for the chosen admiral's line."
Core sync lines. Normal: "(Core name)" in its PATRONS colour, then "(Current) of (Next threshold) to (Next tier)". Example: "Verd +3 this run. 14 of 20 to Partial sync."
Affordability line for doctrine row: if something new is affordable: "(Item name) is now within reach. (Cost) renown. Balance (B)."
Sunward Crusade first-loss flavour. Teaching block: "The crusade does not end with one fleet. It is carried by the line that follows. The chalk outlasts the hand."

4. THE SIX REQUIRED ELEMENTS

Nemesis lesson. Sits in inheritance panel row 4. Renders as stacked lines, 16px BONE, with the Nemesis name and title in BLOOD semibold, then the lesson line(s) for this run.
Renown. Sits in inheritance panel row 1. Renders as: earned amount in 26px GILT semibold, Heat note 15px BONE2 ("Heat (H) — (Heat note)"), balance after the run, and the affordability line when a new item is affordable.
Tree progress. Sits in inheritance panel row 2. Renders as: XP gained this run (+N), level change if any ("Level (old) to (new)"), and a px(6) progress bar to the next level.
Shadow XP. Sits inside the lineage row as sub-lines. Renders as one line per benched same-faction admiral: "(Admiral name) — +(N) shadow XP this run."
Heir naming. Sits below the inheritance panel as its own block. Renders using choice components: question line, one row per benched same-faction admiral, plus "Name no heir". Selecting a row confirms the heir for the next run.
Core sync. Sits in inheritance panel row 3. Renders one line per ticked core: core name in its PATRONS colour, glyph, "+(N) this run", total and next threshold/tier.

5. INTERACTION FLOW

The player reads top to bottom. The first interactive element is the heir naming choice block. Selecting an heir row marks it selected (GILT accent) and enables the primary exit; "Name no heir" leaves the slot empty.
Pending tree picks: the debrief shows the count ("1 branch pick pending") and a single abtn "Open the tree" that routes to the lineage tree screen for the faction just played.
Spend routing: a row of secondary abtn buttons below the inheritance panel. "Variants" opens the variants tab. "Legacy" opens the Legacy tab. "Admirals" opens the admiral unlock view (per R77, admirals are purchasable). "Tree" opens the flown lineage tree. These appear only when the relevant currency is positive or a purchase is affordable. Under the playtest switch (R69), these buttons are hidden because everything reads as already open; the inheritance panel still reports what the run earned.
Primary exits: win shows "Play as (faction)" primary and "Pick a faction" secondary. Loss and abandon show "New run" primary. All outcomes show "Title screen" secondary.
Abandon case: the screen renders identically to a loss in structure. The inheritance panel header reads "Recorded" (not "Carried forward"), the headline reads "Run abandoned", and no first-loss teaching block appears.

6. OWNER QUESTIONS

Q1. On an abandoned run, should the inheritance panel header read "Recorded" (neutral, acknowledging the run ended early) or "Carried forward" (same as win/loss, emphasising nothing is lost)? Pick "Recorded".
Q2. The heir naming block: should it appear on every eligible debrief, or only when the heir slot is empty? Pick: only when the heir slot is empty; otherwise the block is replaced by a single line naming the current heir.
Q3. Should the affordability line name only the single cheapest newly affordable item, or list up to three? Pick: cheapest only, to keep row 1 to two lines.
Q4. The first-loss teaching block: should it appear only on the literal first loss, or on the first loss per faction? Pick: literal first loss only; later factions get the standard loss sub-line.
Q5. Should the NEXT RUN suggestion name an unwon faction at random, or the faction with the most progress? Pick: most progress, to shorten the path to a new win.

Not in the pack
- The exact action names the shell binds for the spend-routing buttons (the abtn pattern is cited but the shell bindings are not in the pack).
- The exact sector number formatting for the loss sub-line when the run ends in sector 1.
- Whether the heir naming block should also appear after a win when the heir slot is already filled.
- Sting asset names and the sound call pattern.

---
Response 2

1. Layout spec

All values authored at 1920x1080 and passed through px(). At 3840x2160 everything doubles via px() (k = 2.0, campaign_ui.gd:105 to 108). No second layout.

Frame change: the end page keeps CenterContainer > VBox, but that outer VBox now holds two children instead of one: the ScrollContainer (horizontal off, cap min(px(920), viewport height minus px(120))) and a fixed footer HBox.

Order top to bottom, and why:

1. Headline block, no panel, centred, internal separation 6. Overline font_caps 12 GILT2, title 62 display, sub 20 BONE, story 17 BONE.
2. First-loss teaching panel, first-ever loss only. panel(GILT, GLASS, pad 18), full column width. It sits here because the lesson must land before the ledger.
3. INHERITANCE panel. panel(GILT, GLASS, pad 18), full width, header font_caps 12 BONE3. Five rows, each a tag plus body, separation 8.
4. Heir panel. panel(IRON3, GLASS, pad 14), header caps 12, choice rows (choice, campaign_ui.gd:226) full width.
5. Stat tiles. Five card(sel=false, width 196) in an HBox, separation 12 (1028 total). Numbers 26 semibold GILT, labels 12 BONE2 caps.
6. Fleet panel. panel(IRON3, GLASS, 14), standout line 17, ship rows 15, hull bar (bar, campaign_ui.gd:226).
7. Captains lost line 15 BONE2, then the record line 15 BONE2.
8. NEXT RUN panel, panel(IRON3, GLASS, 14).
9. Footer, outside the scroll: HBox separation 10, centred, abtn (campaign_ui.gd:211).

Scroll boundary. Rich debrief (win, five ticked cores, Nemesis met twice, four benched lines, six survivors): the column reaches px(1140) and scrolls; the footer stays fixed. A minimal debrief fits without scrolling.

Structural deltas. Win: faction win title, NEXT RUN suggestion, victories record line. Loss: "The fleet is lost", no NEXT RUN panel, first-loss teaching panel on the first loss only. Abandon: "Run abandoned", inheritance header "Recorded", no first-loss panel, loss sting.

Motion and sound: rows appear, nothing slides. One closing sting on page open, win variant on a win, loss sting on loss/abandon. No sting asset names are in the pack.

2. Panel inventory

Headline block. Title from C.WIN_TITLE (browser campaign_meta.js:206) or the loss/abandon strings; sub from the shipped win/loss sub-lines; story line from the faction's authored beat.
Inheritance row 1, DOCTRINE. Renown earned with the Heat note (RUN.carry.ren, campaign.gd:1397; runRecord), balance, and the affordability line.
Inheritance row 2, LINEAGE. XP gained and level change (RUN.carry.mxGain, mx0, mx1, campaign.gd:1398), plus the shadow XP sub-lines for benched same-faction admirals.
Inheritance row 3, CORE SYNC. One line per ticked core only (ruling 4), from the per-run tick delta, core name in its PATRONS colour.
Inheritance row 4, NEMESIS. Name and title in BLOOD, then this run's lesson lines from the per-run lesson delta.
Inheritance row 5, STORY. The faction's authored beat 3 line, verbatim, keyed by RUN.fac, body 17 BONE.
Heir panel. Question line, one choice per benched same-faction admiral plus a "name no heir" row, confirmation on select.
Recap. Stat tiles from RUN.stats and RUN.sector and RUN.t0 (core.js:66); fleet rows and careers (campaign_ui.gd:1091 to 1093).
Footer. Primary plus "Pick a faction", "Spend renown", "Open tree" when picks pend, "Title screen".

3. Exact copy

Win. Overline caps: "INHERITANCE RECORDED". Title: the shipped faction title, unchanged. Sub: shipped win sub.
Loss. Overline: "INHERITANCE RECORDED". Title: "The fleet is lost". Sub: shipped loss sub. Body 17: "The survivors will carry the line forward."
First-ever loss, faction-neutral. Overline: "FIRST LOSS". Title 62 display: "The line continues". Sub: "The last hull goes dark in sector (N). The line continues in the next fleet."
First-ever loss, Sunward Crusade, full. Overline: "FIRST LOSS". Title: "The chalk outlasts the hand". Sub: "The crusade does not end with one fleet. It is carried by the line that follows."
Nemesis lines. Header: "(Name), (Title)" in BLOOD.
Weakness revealed: "Weakness found: (Weakness). Strike it and the hunt turns."
No weakness yet: "No weakness found yet. Survive another encounter to learn more."
Heir naming. Question 18: "Name the heir of the (Faction) line. The heir's line learns at double rate."
Core sync. Normal: "(Core) +(N) this run. (Total) of (Next) to (NextTier)." Example: "Verd +3 this run. 14 of 20 to Partial sync."
Doctrine affordability. Newly affordable: "Now affordable: (Item), (Cost) renown. Balance (B)."
Nothing newly affordable: no affordability line; the balance line stands alone.

4. The six required elements

Nemesis lesson. Fourth inheritance row. Name and title 17 semibold BLOOD, lesson lines 16 BONE, reason line when a weakness is revealed.
Renown. First inheritance row. "+(Renown)" as 26 semibold GILT, Heat note 15 BONE2, balance and affordability line.
Tree progress. Second inheritance row, first body line plus a bar at px(6) using the mastery pattern.
Shadow XP. Inside the lineage row, lines two and three: "(Count) benched lines of the (Faction) learn at shadow rate" and one line per admiral with its shadow gain.
Heir naming. Its own panel below the ledger, choice components with a GILT left accent bar on the selected row.
Core sync. Third inheritance row, one line per ticked core, core name in its PATRONS colour, glyph, plus gain, total and next tier.

5. Interaction flow

Nothing is clickable above the heir panel. First available action: pick an heir row, which selects on click; "Name no heir" confirms an empty slot.
Pending tree picks are not taken here. The footer "Open tree" routes to the lineage screen for the faction just played, where picks are made.
"Spend renown" opens Progression (career screens, campaign_ui.gd; browser campaign_meta.js:120 to 140). "Variants", "Legacy" and "Admirals" route to their tabs/views when affordable or relevant; under the playtest switch they are hidden.
Abandon: identical panel and full carry, no first-loss treatment, loss sting, primary "New run". The inheritance header reads "Recorded", not "Carried forward".

6. Owner questions

1. Does naming an heir double this run's shadow payout, or only future runs? Options: this run (pick), future only, both. Pick: future only — the heir's line learns at double rate from the next run onward.
[Chair note: the leg's option list and its stated pick disagree in the returned text (options list "this run (pick)", the sentence after says future only). The sentence is the leg's actual position; the synthesis follows the sentence.]

2. Does an abandoned run keep the full inheritance? Options: full (pick), renown only, nothing. Pick: full — abandon is a recorded end, not a forfeit.
3. Does the story row show its full authored line on every run end forever? Options: always (pick), first time only, first win only. Pick: always — the beat is the faction's record, not a one-time reveal.
4. Do Nemesis lessons follow the player to a later, different hunter? Options: this hunter only (pick), all hunters, faction-wide. Pick: this hunter only — lessons are earned against a specific hunter.

Not in the pack
- Which tier name attaches to tier 0 in FAVOUR_TIERS. This design reads 0 Listening, 4 Partial sync, 1... (tier naming beyond the cited thresholds is not settled in the pack).
- Whether killing the Nemesis returns the credits he holds (N.loot).
- Icon art for the five inheritance rows. Until it lands, the px(28) tile holds a 12 font_caps tag.
- Whether any heir or shadow state is readable before Step 3 ships; the rows must degrade to their empty states until then.
- Sting asset names and the sound call pattern.
