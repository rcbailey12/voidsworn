# Rey leg (blind): the inheritance screen, a design draft

Written from the evidence pack and the leg instruction only.

## 1. Layout spec

Keep the shipped frame: a full-rect CenterContainer holding a ScrollContainer (horizontal scroll off) over a single centred VBox column, custom minimum width px(720), separation 10, scroll height capped at min(px(1000), viewport height minus px(40)). The screen needs a new order inside the column the game already has, not a new layout engine. At 3840x2160 k is 2.0 and every authored value doubles through px(); there is no second layout.

Panel order, top to bottom, with the reason for the order:

1. Headline block (title, sub, story slot). The outcome lands first, in one glance.
2. The inheritance panel: the screen's thesis, read before the recap. A player who closes the screen after two panels has still read its point.
3. The heir panel, when it applies (section 5): an action, placed after the lineage earnings it changes and before the recap pushes it down.
4. The recap block (stat tiles, standout ship, surviving fleet, captains lost): the record of the run, supporting material now, not the headline.
5. Victory or best-sector line, folded into the headline block's foot rather than floating loose as today.
6. NEXT RUN panel (win only, as today).
7. Exit buttons, last in the column, as today.

The inheritance panel is one panel() with the gilt border the CARRIED FORWARD panel already has, titled THE INHERITANCE in the register's 12px small caps dim header, with five rows inside, each headed by its own small caps label: DOCTRINE, LINEAGE, CORE SYNC, THE NEMESIS, THE STORY. Rows are separated by spacing only (vbox separation 8), not nested panels; five nested boxes would read as five forms, and this is one statement. A one-line verdict opens the panel body (copy in section 3).

Scroll behaviour. A rich debrief (sector 3 win, a meeting, core ticks, shadow earnings) puts headline plus inheritance at roughly 620 authored px, inside the scroll cap with the heir panel; the recap scrolls. A short debrief (sector 1 loss, no meeting, no ticks, no benched admirals) totals about 430px and nothing scrolls. Design rule: the inheritance panel never splits across the scroll boundary at 1080p; scrolling starts at the recap.

Structural differences by outcome. Win: NEXT RUN panel present, win verdict form. Loss: no NEXT RUN panel; the best-sector line sits in the headline foot. Abandon: the panel renders in full (the carry is paid identically), abandon verdict form, heir panel still applies, first-loss treatment never fires.

## 2. Panel inventory

Headline block. Title (62px display face, centred), sub line (20px), story text slot (18px gilt) as shipped. Data: WIN_TITLE by faction, RUN.sector, admiral and faction names (pack section 3). Empty state: none; every run end has all three. On the first-ever loss the sub is replaced by the first-loss treatment (section 3) and a teaching panel is inserted after the inheritance panel.

Inheritance panel, verdict line. One sentence, forms in section 3. Data: victory and abandoned flags from endRun (campaign.gd:1386). Empty state: none.

DOCTRINE row. Renown earned with its composition on one dim sub-line (battles, elites, flagships, kills, sectors, Heat note), the new balance, and the affordability line (section 3). Data: runRenown (campaign3d.js:30), endRun Heat multiplier (campaign.gd:1397), META.renown (core.js:50), prices from ADMIRALS, HULL_VARIANTS and LEGACY in data.js, respec price at core.js:382; the affordability summary is a Step 4 build item over those tables. Empty state: a run abandoned before any battle shows "No renown: the fleet never engaged." and no affordability line.

LINEAGE row. The flown line: admiral name, XP gained, the mastery bar, level reached or progress to the next threshold, pending branch picks when any exist; the shadow sub-block sits under it (section 4). Data: META.mastery (core.js:348 to 349), thresholds (data.js:583 and 591, core.js:351), lineageBuild picks (core.js:353), the gain on RUN.carry. Empty state: at the capstone mastery ceiling the row shows "fully deepened" and cap overflow routes to shadow per Q13, stated in the sub-block.

CORE SYNC row. One line per core that ticked this run, in the core's colour, with progress toward its next tier and the tier-up variant when a tier was crossed (formats in section 3). Data: META.favour totals (core.js:389 to 390), FAVOUR_TIERS (data.js:911), PATRONS colours; the per-run tick record is the Step 5 build item. Empty state: the row is omitted entirely. A core that did not move does not appear (ruling 4); a header with "nothing" under it would teach the player the row is decoration.

THE NEMESIS row. The run's lessons: weaknesses revealed or taught, adaptations he gained, raid losses, his death (formats in section 3), each its own line, BLOOD for adaptation and raid lines, gilt for weaknesses learned. Data: RUN.nem state and the nemAfterBattle machinery (campaign.gd:1918, 1893, 1898, 1902); the per-run lesson log is the Steps 4 and 7 build item. Empty state: no meeting resolved and nothing else happened, one dim line: "No meeting this run. He is still out there, learning nothing new about you." If he was already dead before this run, the row is omitted.

THE STORY row. The faction's authored learning payoff line (pack section 7), verbatim, in BONE at 16px rather than gilt (the register has no italic face; colour does the fiction-among-numbers work). Data: the Step 12 files keyed by RUN.fac. Empty state: none; it renders after a loss exactly as after a win.

Heir panel. Its own panel() under the inheritance panel, titled NAME THE HEIR, holding the prompt and choice rows (sections 3 and 5). Data: benched same-faction admirals from ADMIRALS filtered by RUN.fac, their META.mastery totals; the heir state is the Step 3 build item. Empty state: no benched admiral of the faction exists; the panel is omitted, not greyed.

Recap block. Stat tiles as shipped, standout ship line, surviving fleet rows, captains lost line. Data: RUN.stats (core.js:66), per-ship career, RUN.fallen. Empty states as shipped; a wiped fleet shows no fleet rows and the captains line carries the weight.

Exit buttons. As shipped, plus this design's two routing buttons (section 5) in a second row above the exit row, so the exits keep their shipped positions.

## 3. Exact copy

Verdict line, win: "Three sectors broken, and everything below came home with the fleet."
Verdict line, loss: "The fleet is gone. Everything below is what it bought before it went."
Verdict line, abandon: "Stood down, and still paid. Everything below was already earned."

Win treatment. Headline: the shipped faction win titles, unchanged. Sub: shipped, unchanged. Body: the verdict line plus the rows; no extra paragraph. A win needs neither consolation nor explanation.

Loss treatment (not the first loss). Headline: "The fleet is lost". Sub: shipped. Body: the loss verdict line, nothing more; a veteran loser wants the numbers.

First-ever loss, full treatment (faction-neutral). The headline stays "The fleet is lost". The sub is replaced: "This is how every line in this war starts: with a fleet that did not come home." After the inheritance panel, a teaching panel titled THE FIRST INHERITANCE carries this body:

"No first fleet takes the Hollow Sun, and this screen is why that is not the end of anything. Read the panel above again. The renown is real, and it spends. The admiral who led this fleet keeps every point of what the fleet learned, and the admirals who waited learned at a shadow rate beside them. If you met the hunter who is learning you, what he took from this fight is written above too, and so is what you took from him. The next fleet launches with all of it. Runs in this war are meant to be lost, early and often. What a run buys is listed before it is mourned, here, every time."

One plain line in dim 14px under that panel (owner question 3 carries this choice): "Plainly: winning your first run is near impossible by design. Losing is the engine, not the failure."

The inheritance rows on a first loss use the same formats as any loss; the teaching panel refers to the panel above rather than repeating its numbers, so the copy cannot disagree with the state.

Nemesis lesson lines (faction-neutral forms; (Name) is title plus name, (he) follows the shipped pronoun machinery):

- Weakness revealed (meeting won): "His captured logs give up a weakness: (Weakness). It stays known from here on."
- Weakness taught (meeting lost): "You lost the meeting, and it still taught you. Your analysts piece together the engagement. Weakness found: (Weakness)."
- Adaptation gained: "What he learned from you: (Adaptation). (Reason, from nemAdaptWhy, in his faction's words.) You see it first here; during the run he kept it to himself."
- Raid loss (Hullbreaker Nemesis, against any faction): "(Name) raided your supply line: (N) credits, held in his hold. Kill him and they come back with the rest of what he holds."
- Nemesis dead: "(Name) is dead, killed in sector (N). The feud is over. What he held comes back: (loot) credits( and the (ship name))."

Heir naming. Panel title: NAME THE HEIR. Prompt: "One line can carry your name forward. While an admiral is your named heir, that line learns from every run at double the shadow rate, flown or not." Choice rows (choice component, one per benched same-faction admiral): title line "(Admiral name)", small line "(Doctrine). Level (N), (XP) XP earned in shadow so far." The current heir's row is tagged HEIR in the tag slot and selected-styled. A final row: "Name no heir", small line "Every line learns at the plain shadow rate." Result line after a pick, replacing the rows: "(Name) is named heir. That line now learns at double shadow rate until you name another." plus a Change button that reopens the rows.

Core sync lines. Normal: "(Core): (total) of (next tier at) toward (next tier name)." Example pattern: "Kharon: 9 of 12 toward Synced." Tier-up: "(Core) reaches (tier name): (tier effect text). (total) of (next at) toward (next tier name)." A core at Full sync that still ticked: "(Core): Full sync. (total) protocols, and still counting."

Affordability lines. Newly affordable exists: "Newly in reach: (item name), (cost) renown, in Progression." Nothing newly affordable: "Next in reach: (cheapest unowned item name), (cost) renown. You are (gap) short." Everything owned: "Your yards and legacy are complete. Renown now feeds respec: (flown line) resets at (price)."

Sunward Crusade first loss, in full. Headline: "The fleet is lost". Sub: "The first crusade ends here. They all do. That is what first crusades are for." Teaching panel, titled THE FIRST INHERITANCE:

"The names go on the Roll, every one, chalked where the next crews can read them from their stations. Read the panel above the way they will read it. The renown spends. The admiral's line keeps what this fleet learned, and the lines that waited learned in shadow beside it. If the hunter found you, what he took is written above, and what your analysts took from him is written above too, because even a lost meeting teaches. The next crusade stands at this same dark and reads what you chose, in chalk, before it chooses. It starts richer than this one did, in named ways, and the names start with this fleet's."

## 4. The six required elements

Nemesis lesson. THE NEMESIS row, fourth: inside the row, weaknesses first (gilt), then adaptations (BLOOD names), then raid, then death, because what the player gained reads before what the hunter gained. Source: the per-run lesson log build item over RUN.nem and the nemAfterBattle machinery. Empty state in section 2. It appears on wins and losses alike; meetings resolve in both.

Renown. DOCTRINE row, first: earned figure in gilt 26px (the tile number size, so the panel's biggest number is the currency), composition in one dim line, balance after it, affordability line last. Sources in section 2. The never-engaged abandon is the only zero.

Tree progress. LINEAGE row, second: flown admiral, XP gained, the mastery bar filled to the new total with this run's segment in gilt against the existing fill in GILT2, level text, and a pending-pick line when lineageBuild shows picks owed: "(Name) has (N) branch picks waiting." Sources: pack section 4. Capped lines show the overflow routing line instead of a bar.

Shadow XP. A sub-block inside the LINEAGE row, headed SHADOW at 11px small caps, one compact line per benched same-faction admiral: "(Name): +(N) shadow XP (Level (N))." The heir's line carries "heir: double rate" in VERD. Source: Step 3 build item; the rates are ruled. Empty state: no benched admiral of the faction, sub-block and heir panel both omitted.

Heir naming. Its own panel under the inheritance panel (copy in section 3), on any run end whenever a benched same-faction admiral exists. State: Step 3 build item. Interaction: section 5. Empty state: omitted when no candidate exists.

Core sync. CORE SYNC row, third: one line per ticked core in its colour, tier-up lines first (they are the news), then ordinary ticks in tick order. Source: Step 5 tick record over META.favour. Empty state: row omitted (ruling 4).

## 5. Interaction flow

Order of action: read, then optionally name an heir, then leave. Nothing is modal and nothing is required; every exit works with no interaction at all.

Heir naming. Tapping a choice row names that heir immediately (no confirm modal: the choice is free and reversible at every later debrief, and a modal would tax a reversible act). The rows collapse to the result line and a Change button. The state write happens at tap time, not at exit, so quitting from this screen cannot lose it.

Tree picks. Not made here. When a pick is pending, the lineage row's button "Choose (Name)'s level (N) skill" routes to that admiral's lineage screen, where the full tree, the locking partner and the respec price are visible; a locking choice deserves its context. Rejected alternative: inline picking in the row, which hides the partner skill that locks.

Spend routing. The DOCTRINE row foot carries one button, "Spend renown", opening Progression on the tab holding the affordability line's named item; when the named item is an admiral, the button reads "Unlock admirals" and routes to the admiral select screen, where admiral unlocks are bought today (R77). Respec is not routed from here; it lives on the lineage screen.

Exits. Shipped exits keep their places: on a win, Play as (suggested faction) primary, Pick a faction, Title screen; on a loss, New run primary, Title screen. Routing buttons sit in their own row above.

Playtest switch on. Affordability lines are suppressed (everything reads open already); the DOCTRINE row shows earnings and balance plus one dim line: "Playtest: everything unlocked. Earnings still recorded." Shadow, heir and tree reporting are unchanged; progression runs underneath the switch.

Abandon. All rows render, the heir panel applies, no first-loss treatment, and the exits are New run and Title screen (no faction suggestion, as today).

## 6. Owner questions

Q1. Heir changes: (a) free at every debrief (my pick; it is a stance about who carries the name, and taxing a change makes players hoard the choice instead of feeling it); (b) changeable only when no heir is named or the heir's line flew this run; (c) changing costs renown.

Q2. Screen order: (a) inheritance first on every outcome (my pick; the screen's one job, and a win's recap is the part a winner skims); (b) recap first on wins, inheritance first on losses; (c) recap first always, as the screen ships today.

Q3. The first-loss teaching panel's plain system line: (a) keep it (my pick; the fiction alone can read as consolation, and this owner's standing preference is plain words); (b) fiction only, no system voice on the screen; (c) plain line only, no teaching panel.

Q4. The NEXT RUN faction suggestion on a win: keep it as the shipped panel above the exits (my pick; the win screen's only forward hook, at the cost of one panel), move it below the exit buttons, or drop it now that the inheritance panel points forward?

Q5. A direct "Launch the next run" button skipping faction and admiral select with the same admiral and faction? (a) no (my pick; admiral choice is where the tree and heir decisions live, and one saved tap is not worth bypassing them); (b) yes, under the exits; (c) yes, and primary on a loss.

## Not in the pack

- Whether an abandoned run counts toward the first-loss derivation is not spelled out in the pack; this draft assumes the first-loss flag is set only by a fought loss, and flags a stored flag as the safe build.
- The full FAVOUR_TIERS effect strings are quoted in the pack only in part; the tier-up line format takes the effect text from data at build time.
