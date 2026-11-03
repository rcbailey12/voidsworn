DeepThink and Search were verified ON before sending: each toggle turned white when clicked off and pale blue when restored, and both were left pale blue/active.

Issue 71: Debrief screen design (the inheritance screen)

1. Layout spec

Authored at 1920x1080. The screen stays one centred column built from the existing CenterContainer, ScrollContainer and single VBox (campaign_ui.gd:1091 to 1093), but the column widens from the shipped px(720) to px(960) so the five inheritance rows and the fleet rows have room. Rejected alternative: keep px(720) and stack everything, which cramps the Nemesis and core rows into wrapped lines. VBox separation 10. Scroll height capped at min(px(1000), viewport height minus px(40)). At 3840x2160 everything doubles through px(); no separate 4K layout.

Order top to bottom, with the reading claim:

1. Headline block: kicker on a first loss only (12 small caps GILT), title 62 display, sub 20 body. Reason: the player must register that the run ended and which kind of ending it was before any ledger.

2. Story slot: 18 GILT, centred, when the story layer has a line (campaign_ui.gd:1103 to 1106). Reason: reframes the death as inheritance in fiction before the numbers.

3. Inheritance panel: panel() with gilt border, padding 14, header 12 small caps BONE3 letter-spaced, "WHAT THIS RUN BOUGHT". Five rows, each a VBox with a 12 small caps label and body lines, row separation 10, 1px IRON3 rules between rows. Reason: this is the screen's purpose; what the death bought must be read before remembrance.

4. Heir naming panel: panel(), choice() rows, confirm abtn. Reason: the one decision on the screen, placed after the lineage row it modifies.

5. Recap: stat tiles row (5 tiles, min 120 wide, number 26 GILT semibold, label 13), standout ship card(), surviving fleet rows 15, captains lost line. Reason: remembrance after inheritance, never before.

6. Exit row: abtn primary plus secondary. Reason: last, because reading comes first.

Rich debrief (win, all five rows populated, heir options, full fleet) exceeds px(1000); the fold falls just after the heir panel, so recap and exits need scrolling. Short debrief (sector 1 loss, no Nemesis, no ticks, no benched admirals) fits under px(700) with exits visible. Empty rows never collapse the panel; each shows one dim line.

Structural changes: win uses the faction win title and win sub, and the primary button becomes "Play as (faction)" with "Pick a faction" beside it. Loss uses "The fleet is lost" and loss sub, primary "New run". First loss adds the kicker and a body block above the inheritance panel. Abandon uses "Run abandoned" and its sub, primary "New run", and keeps the inheritance panel and heir prompt (section 5).

2. Panel inventory

Headline block. Title, kicker (first loss only), sub. Data: WIN_TITLE at campaign_meta.js:206 browser and C.WIN_TITLE in Godot; loss and abandon strings shipped. Empty: never empty.

Story slot. The story layer's arc line, 18 GILT. Data: _story_text at campaign_ui.gd:1103 to 1106. Empty: collapses to zero height.

Inheritance panel, row 1, doctrine and renown. Renown earned (RUN.carry.ren, campaign.gd:1397 to 1402), balance META.renown (core.js:50), price fields ADMIRALS, HULL_VARIANTS, LEGACY (data.js), respec lineageRespecCost (core.js:382), plus the affordability build item. Empty: "No renown earned this run" plus distance to the cheapest item. Playtest on: "All unlocks open (playtest)."

Row 2, lineage and tree progress. mxGain, mx0, mx1 (RUN.carry), META.mastery (core.js:348 to 349), thresholds data.js:583 and 591, lineageBuild (core.js:353), pending picks as level minus picks. Empty: "No mastery earned this run" with the admiral's bar at its current value.

Row 3, core sync. Build item per-run tick record (Step 5), META.favour (core.js:389), favourTier (core.js:390), FAVOUR_TIERS (data.js:911). Ruling 4: ticked cores only. Empty: "No protocols taken this run."

Row 4, Nemesis lesson. Build item per-run lesson log (Steps 4 and 7), RUN.nem fields, nemAdaptName, nemAdaptDesc, nemAdaptWhy (campaign.gd:1893, 1898, 1902), nemAfterBattle (campaign.gd:1918), N.loot for the raid line. Empty: "No Nemesis meeting this run."

Row 5, story. The six Step 12 lines keyed by RUN.fac, verbatim. Empty: never on a finished run; if it would duplicate the top slot, this row wins and the slot collapses.

Recap. Stat tiles from RUN.stats (core.js:66), RUN.sector, RUN.t0; standout ship from ship career (campaign_ui.gd:1128 to 1142); fleet rows; captains lost from RUN.fallen (core.js:66) and META.fallen (cap 80). Empty: zeros, "No ship stood out", "No ships survived", fallen line collapses.

Exit buttons. abtn bound to shell actions. Empty: not applicable.

Heir naming panel. choice() rows for each benched same-faction admiral plus the current heir and a no-heir row, confirm abtn. Data: heir state build item (Step 3). Empty: "No benched admirals of this faction to name." with no confirm.

3. Exact copy

Win. Title: the faction win title from the table. Sub: "Three sectors broken, three flagships burning behind you. (Admiral) brings the (Faction) home." Panel lead: "What this victory bought:"

Loss (not first). Title: "The fleet is lost". Sub: "The last hull goes dark in sector (N). The survivors will tell it differently." Panel lead: "What this death bought:"

First loss, faction-neutral. Kicker: "THE FIRST RUN ENDS. THE NEXT INHERITS." Title: "The fleet is lost". Sub: "The last hull goes dark in sector (N). This is not the end of the line. What this run earned is already on its way to the next fleet." Body above the panel: "You will lose runs. That is the design, not a verdict. Every death names what the next generation carries: renown in the vault, mastery in the bloodline, and a lesson the enemy taught you at cost. Read the panel below as an inheritance, not a score."

First loss, Sunward Crusade in full. Kicker: "THE FIRST CRUSADE FALLS. THE CHALK REMEMBERS." Title: "The fleet is lost". Sub: "The last hull goes dark in sector (N). The survivors will tell it differently, and the next crusade will read it in chalk before it chooses." Body: "No crusade wins the first dark. That is the oath working, not failing. What this run bought is already written: renown in the vault, mastery in the bloodline, and the weakness the enemy showed you at cost. The next crusade stands at this same dark and reads what you chose. Do not mourn the fleet. Read the record."

Nemesis lines, faction-neutral with (Name) and (Title) slots.
Revealed: "Nemesis lesson: you broke (Name), (Title). Weakness found: (weakness)."
Taught on a loss: "Nemesis lesson: (Name), (Title), beat you and taught you a weakness: (weakness)."
New adaptation: "Nemesis lesson: (Name) adapted. (Adaptation): (reason)."
Hullbreaker raid: "Raided: (Name)'s Hullbreakers took (N) credits this run. One raider line crossed."
Dead: "Nemesis lesson: (Name), (Title), is dead. What he taught you is yours to keep."

Heir prompt. Question: "Name an heir to the (line) line?" Choice row: "(Admiral), (rank). Shadow (n) XP. Double earnings for this line." Current heir row: "(Admiral) is the current heir." No-heir row: "No heir this run." Confirm: "Named: (Admiral). The (line) line earns double shadow until you name another."

Core sync. Normal: "(Core): (n) of (threshold) to (next tier)." Tier-up: "(Core): crossed into (tier) this run at (n) protocols." No ticks: "No protocols taken this run."

Affordability. "Renown: (earned) earned. (balance) in the vault." Then "Now affordable: (cheapest item), (cost) renown." If nothing: "Next: (cheapest item) at (cost). (N) more renown." Playtest on: "Playtest: everything unlocked. Earnings recorded."

4. The six required elements

Nemesis lesson. Row 4 of the inheritance panel. The Nemesis name carries a BLOOD accent; body 16 BONE; adaptation lines get a 12 small caps sub-label "ADAPTED". Data is the per-run lesson log build item plus RUN.nem. Empty state is one BONE3 line, "No Nemesis meeting this run."

Renown. Row 1. Earned number semibold 16 GILT, balance BONE2, affordability line BONE3. Data is RUN.carry.ren, META.renown (core.js:50) and the price fields, with the affordability summary as a Step 4 build item. Empty: "No renown earned this run" plus the distance to the cheapest item.

Tree progress. Row 2. A bar() showing current XP to the next threshold (amber fill on an IRON3 track), "mx0 to mx1" text, and a GILT pending-picks line. Data is RUN.carry, META.mastery, the threshold tables, and lineageBuild. Empty: the bar sits at the flown admiral's current value with "No mastery earned this run."

Shadow XP. A sub-line inside row 2, 15 BONE2, one line per benched admiral that earned, with an heir line tagged "double" in GILT. Data is the Step 3 shadow state build item. Empty: "No benched admirals earned shadow this run." I keep it inside lineage rather than its own panel because it is an attribute of the lineage line, not a sixth inheritance track.

Heir naming. Separate panel below inheritance. choice() rows, confirm abtn. Data is the Step 3 heir state build item. Empty: one BONE3 line and no confirm. Ruling 5 governs: offered on any run end, doubles the line's shadow earnings.

Core sync. Row 3. One line per ticked core, core name in its PATRONS colour, progress text, tier-up in GILT. Data is the Step 5 per-run tick record build item plus META.favour and FAVOUR_TIERS. Empty: "No protocols taken this run." Ruling 4: only ticked cores appear.

5. Interaction flow

Clickable in order: heir choice rows, heir confirm, a pending-pick button, spend routing buttons, then exits. Heir naming can be changed on any later debrief; it costs nothing (no cost is established in the pack). Confirming sets the heir and immediately restates the double-earnings line. Pending tree picks route to the lineage screen rather than resolving inline; the branch choice needs the tree's full context and the unchosen-skill lock, and the pack's lineage screen already computes pending picks, so inline picking would duplicate that logic badly. Spend routing: "Open Progression" opens the variants, Legacy and mastery tabs; "Open lineage" appears only when a pick is pending; both use abtn actions the shell can bind. "New run", "Play as (faction)", "Pick a faction" and "Title screen" keep their shipped behaviour.

Playtest switch on (R69): affordability lines read as open ("Playtest: everything unlocked. Earnings recorded."), spend buttons read "View" not "Buy", but heir naming and pending picks still function because progression is intact underneath. Abandon: same inheritance panel, same heir prompt, primary "New run"; I offer the heir on abandon because ruling 5 says any run end and the cost is zero. Rejected alternative: suppress the heir on abandon to make abandoning feel like a forfeit, which the pack leaves as a third case.

6. Owner questions

Q1. Should an abandoned run offer heir naming? (a) Yes, same as a loss (pick). (b) No, abandon forfeits the choice. Reason: ruling 5 says any run end; generosity costs nothing and rewards investment.

Q2. Should a pending tree pick resolve on this screen or route to the lineage screen? (a) Route (pick). (b) Inline. Reason: the branch lock and full tree context live on the lineage screen; inline risks a second implementation.

Q3. Does shadow XP live inside the lineage row or as its own panel? (a) Inside lineage (pick). (b) Own panel. Reason: it is a property of the line, and a sixth panel breaks the five-row frame the synthesis names.

Q4. When the story layer line and the Step 12 payoff line would both render, which wins? (a) The Step 12 row wins and the top slot collapses (pick). (b) The top slot wins. Reason: one canonical learning line avoids a double story beat.

Not in the pack: the exact name-to-threshold mapping of FAVOUR_TIERS (four names, three numbers at data.js:911); the shell action names for the Progression tabs; whether an abandoned run should grant shadow XP from the flown admiral's XP; the per-core PATRONS colour values beyond the fact they exist.
