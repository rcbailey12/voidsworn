# Debrief screen design: the inheritance screen (board issue 71)

Chair synthesis of three legs (Rey blind leg, DeepSeek, Qwen with two responses), grounded in the evidence pack at repo main 7677728. The Argon leg was screened out (section 12) and nothing in this design rests on it. This is the design Codex builds progression Step 4 (issue 21) from. FINDINGS rulings override every other doc; the pack is the authority for shipped strings, data sources, and rulings, and where a leg's copy conflicts with a shipped string in the pack, the pack wins (section 4.9).

## Verdict

GO. The design is buildable in the order given in section 10. Cross-step dependencies are named with their owning issues (section 9); until each lands, its row renders the empty state specified here, so Step 4 can ship its slice without waiting. Of the four owner questions in section 11, only Q2 (heir doubling timing) blocks anything: Step 3 (issue 20) needs it answered before its heir logic is final. The rest are non-blocking.

## 1. Current state

A run-end screen already exists in the Godot build (the build target; the browser build is frozen to break fixes). endRun at campaign.gd:1386 computes the carry into RUN.carry (campaign.gd:1397 to 1402: ren, mxGain, mx0, mx1, hl) and calls show_page("end", ...); the page renders at campaign_ui.gd:1089 (_end). It is a recap, not yet an inheritance screen. Top to bottom today: faction win title or "The fleet is lost" or "Run abandoned" (62px display, centred); a one-sentence sub; a story line slot (_story_text, campaign_ui.gd:1103 to 1106); a CARRIED FORWARD panel holding only two tracks (renown earned with the Heat note, and the flown admiral's mastery gain); stat tiles; standout ship and surviving fleet rows; captains lost; a win or best-sector line; a NEXT RUN panel on wins only; exit buttons.

What it does not have: no Nemesis content, no core sync, no shadow earnings, no heir naming, no affordability summary, no tree detail beyond the mastery line, and no first-loss treatment (a first loss gets the same screen as a tenth loss). The Job 7 synthesis calls this "the most important screen in the game": runs are meant to be lost, and the debrief is where a death stops reading as failure because it names the inheritance the run bought. Step 4 as written: an inheritance panel with renown earned, what is now affordable, tree progress on the flown line, shadow earnings on benched lines, and the Nemesis lesson. This design covers the whole finished screen, including the rows Steps 3, 5, and 7 fill, so the steps land in one frame.

## 2. Layout

### 2.1 Frame and scale

The screen stays on the shipped end page frame (campaign_ui.gd:1091 to 1093): a full-rect CenterContainer holding a ScrollContainer (horizontal scroll off) with a single centred VBox column. Two authored changes: the column widens from the shipped px(720) to px(960), so the five inheritance rows, the heir choice rows, and the fleet rows stop wrapping into cramped lines; VBox separation stays 10. Scroll height stays capped at min(px(1000), viewport height minus px(40)).

All sizes go through px() with the single scale factor k = clamp(viewport height / 1080, 0.6, 2.5) (campaign_ui.gd:105, 108). At 3840x2160 k is exactly 2.0, so the 1920x1080 layout doubles with no separate 4K design. There is one layout, authored at 1080p values.

Register (campaign_ui.gd:15 to 27, 60 to 63): INK #0f1626, IRON #182133, IRON2 #222d44, IRON3 #2d3a56, BONE #e6dcc4, BONE2 #b3aa95, BONE3 #7d7768, GILT #d0a64b, GILT2 #8c6d2c, VERD #5fb3a6, BLOOD #e27f74, GLASS panel fill. Body face Barlow Semi Condensed; semibold for numbers, heads, and buttons; Michroma (font_goth) for the title; small caps labels via the Oxanium FontVariation (font_caps). Components: panel (campaign_ui.gd:188), card (:191), bar (:198), abtn (:211), choice (:226). Motion: rows appear, nothing slides. Sound: one quiet closing sting on page open, win version on a win, loss version on a loss or abandon (Job 7 art list ask).

### 2.2 Order

Top to bottom, on every outcome:

1. Headline block: kicker (first loss only), title (62 display, centred), sub (20), story line slot (18, gilt, centred, collapses when empty or when section 4.8's duplication rule fires).
2. First-loss teaching block (first-ever loss only; copy in section 4.2). Sits above the panel so the lesson lands before the ledger.
3. Inheritance panel: panel() with gilt border, padding 14, small caps header (section 2.3). Inside, a lead line (section 4.3), then five rows, each a VBox with a 12px small caps label and body lines at 16 to 17, row separation 10, 1px IRON3 rules between rows. Row order: 1 doctrine and renown; 2 lineage and tree progress (shadow XP as sub-lines); 3 core sync; 4 Nemesis lesson; 5 story payoff.
4. Heir naming block: its own panel() below the inheritance panel (section 3.7).
5. Recap: stat tiles (min px(120) wide, wrapping inside the 960 column; number 26 semibold gilt, label 13), standout ship, surviving fleet rows (15), captains lost line.
6. NEXT RUN panel (win only, shipped behaviour; section 6).
7. Exit buttons, last.

The inheritance panel sits above the recap on every outcome, wins included. A rich debrief (win, all five rows populated, heir options, full fleet) exceeds the px(1000) scroll cap; the fold falls after the heir block, so the recap and exits scroll. A short debrief (sector 1 loss, no meeting, no ticks, no benched admirals) fits under roughly px(700) and nothing scrolls. Rows never vanish to save space: an empty row renders its one dim line (section 3), so the five-row frame is stable and the player learns where each kind of news lives.

### 2.3 Outcome variants

- Win: faction win title and win sub (section 4.1); panel header "WHAT THIS RUN BOUGHT"; NEXT RUN panel present; exits "Play as (faction)" primary, "Pick a faction", "Title screen".
- Loss: title "The fleet is lost", loss sub; panel header "WHAT THIS RUN BOUGHT"; no NEXT RUN panel; the best-sector line stays in the recap as shipped; exits "New run" primary, "Title screen".
- First-ever loss: a loss, plus the kicker in the headline block and the teaching block above the panel (section 4.2).
- Abandon: title "Run abandoned" and its shipped sub; panel header reads "Recorded" instead of "WHAT THIS RUN BOUGHT"; full inheritance panel and heir offer (section 7); no first-loss teaching block; exits "New run" primary, "Title screen".

## 3. Panel inventory

Each entry: content, data source, empty state. Build items (state that does not exist yet) are named as build items, not dressed up as sources.

### 3.1 Headline block

Title, kicker (first loss only), sub, story slot. Sources: WIN_TITLE table (campaign_meta.js:206 browser; C.WIN_TITLE in Godot); loss and abandon titles and subs are shipped strings (section 4.1); RUN.sector; the flown admiral and faction names; _story_text (campaign_ui.gd:1103 to 1106). Empty state: none; every run end has a title and sub. The story slot collapses when the story layer has no line, or under the duplication rule (section 4.8).

### 3.2 Inheritance row 1: doctrine and renown

Renown earned this run, its composition on one dim sub-line, the balance, the Heat note in the shape live at build time (section 8), and the affordability line. Sources: RUN.carry.ren (campaign.gd:1397); runRenown composition (campaign3d.js:30: battles x2 + elites x4 + bosses x15 + kills/4 rounded down + (sector reached minus 1) x5); balance META.renown (core.js:50); prices from ADMIRALS, HULL_VARIANTS, and LEGACY cost fields (data.js), including admiral unlocks at 0, 30, 45, and 80 renown per faction (R77); respec price lineageRespecCost (core.js:382; 25 + 10 per prior respec of that line, the ruled per-line formula, already shipped). The affordability summary itself is a Step 4 build item over those tables. Empty state: a run that never engaged shows "No renown earned this run" plus the distance line to the cheapest item overall (section 4.7).

### 3.3 Inheritance row 2: lineage and tree progress

The flown admiral: name, XP gained, a bar on the mastery pattern filled to the new total, level reached or progress to the next threshold, and a pending-picks line when picks are owed. Shadow XP sits inside this row as sub-lines (section 5), never as a sixth row. Sources: RUN.carry.mxGain, mx0, mx1 (campaign.gd:1398); META.mastery (core.js:348, masteryXP core.js:349); thresholds from data.js:583 (MASTERY_XP) or data.js:591 (LINEAGE_XP), picked at core.js:351; lineageBuild picks (core.js:353); pending picks are level minus picks made (the lineage screen's own computation, browser campaign_meta.js:152). Elite and boss double XP is kept as intended weighting (owner ruling 1) and is already inside the gain formula. Empty state: "No mastery earned this run" with the bar at the admiral's current value. At the level cap, XP past the cap routes into shadow XP rather than vanishing, and the row says so.

### 3.4 Inheritance row 3: core sync

One line per core that ticked this run, and only those (owner ruling 4), each core's name in its PATRONS colour, progress toward the next tier, tier-up lines first when a tier was crossed this run. Sources: META.favour lifetime totals (favourOf, core.js:389), tier from favourTier (core.js:390), FAVOUR_TIERS (data.js:911: tier ups at 4, 12, and 25 protocols; tiers named Listening, Partial sync, Synced, Full sync); core names, colours, and glyphs from PATRONS (data.js), displayed under the UI terms map (campaign_ui.gd:30: patron to core, boon to protocol, favour to sync, relic to salvage). Ticks happen when a protocol is taken (+1 plus rarity: common 1, rare 2, epic 3; duo protocols tick both cores; browser campaign_run.js:521). Build item: the per-run tick record (Step 5, issue 22). META.favour holds lifetime totals only, so ruling 4 cannot be served until Step 5 records which cores ticked this run, as a run-start snapshot or tick log, with the delta computed into RUN.carry at endRun (campaign.gd:1386). Empty state, until Step 5 lands and on any run with no protocols taken: "No protocols taken this run."

### 3.5 Inheritance row 4: Nemesis lesson

The run's lessons, one line each in the formats of section 4.4: weaknesses revealed, weaknesses taught on a lost meeting, adaptations gained this run, raid credit losses, and his death. The Nemesis name and title carry the BLOOD accent. R62 governs: adaptation is shown on the debrief and hidden during the run (the shipped map card listing his adaptations during the run, browser campaign_run.js:79 to 89, contradicts R62 and is owned elsewhere; this screen follows R62), and a lost meeting still teaches a weakness. The panel takes whoever this run's Nemesis was; the Nemesis is being redesigned as a symmetric, variable hunter pool (R78, issue 45), so nothing here is designed around one fixed hunter identity. Sources: RUN.nem (fac, name and title via nemFull, weak, revealed, adapt, beaten, dead, loot, and the rest); adaptation names, descriptions, and reasons from nemAdaptName, nemAdaptDesc, nemAdaptWhy (campaign.gd:1893, 1898, 1902); outcome lines from the nemAfterBattle machinery (campaign.gd:1918). Build item: the per-run lesson log (Steps 4 and 7, issues 21 and 24). RUN.nem is cumulative across the run's meetings and nemAfterBattle lines are emitted per battle and then gone, so the log gathers, per run: meetings fought, weaknesses revealed or taught, adaptations gained, raid losses (R78 Q6, from N.loot and the strike log), and whether he died. Empty state: "No Nemesis meeting this run." If he was already dead before this run, the same line with the death already recorded in an earlier debrief; the row does not repeat old news.

### 3.6 Inheritance row 5: story payoff

The faction's authored Step 12 learning payoff line, verbatim (section 4.8), keyed by RUN.fac, at body size in BONE. It renders after a lost run exactly as after a won one. Empty state: none on a finished run; all six lines exist.

### 3.7 Heir naming block

Its own panel() below the inheritance panel, built from choice() rows (campaign_ui.gd:226). A current-heir line is always present. When the slot is empty, the full choice rows appear: one per benched same-faction admiral, plus a "Name no heir" row, with a confirm abtn. When an heir is already named, the block shows the current-heir line and a change action; the choice rows sit behind that action. Naming is free, and changeable on any later debrief. Offered on any run end, win, loss, or abandon (owner ruling 5). Effect: the named heir's line earns shadow XP at double rate (section 5), subject to Q2's timing answer. Build item: heir state (Step 3, issue 20); no heir field exists today. The design needs, per line: which admiral (if any) is the named heir, set from this screen. Sources for the rows: ADMIRALS filtered by RUN.fac, each candidate's META.mastery totals. Empty state: no benched admiral of the faction exists; the block shows the current-heir line and one dim line, "No benched admirals of this faction to name.", with no rows and no confirm.

### 3.8 Recap

Stat tiles as shipped (battles won, flagships destroyed, enemy ships destroyed, ships lost, time played) from RUN.stats (core.js:66), RUN.sector, and RUN.t0. Standout ship line, then surviving fleet rows (name, hull, captain rank and name, kills and damage) from per-ship career (campaign_ui.gd:1128 to 1142), best ship's panel gilt-bordered. Captains lost this run as one line of names, from RUN.fallen (core.js:66), folded into META.fallen (cap 80) at endRun. Win adds victories count and factions won with; loss adds the new best or best sector line. Empty states as shipped: a wiped fleet shows no fleet rows and the captains line carries the weight.

### 3.9 NEXT RUN panel and exits

NEXT RUN (win only, shipped panel): a card naming a suggested unwon faction with its blurb. The suggestion names the unwon faction with the most progress. Exits are abtn buttons bound to named shell actions (campaign_ui.gd:211), placed last: win gets "Play as (faction)" primary plus "Pick a faction" and "Title screen"; loss and abandon get "New run" primary plus "Title screen". Spend routing buttons sit with the rows they belong to (section 6), not in the exit row.

## 4. Exact copy

Base copy is the DeepSeek leg's set, with chair amendments: all punctuation is plain ASCII (any em dash in a leg template is rendered as a colon or comma); shipped strings from the pack override leg variants (section 4.9); the first-loss teaching body is the long form in section 4.2. Slots are written in parentheses.

### 4.1 Headlines and subs (shipped, unchanged)

Win titles by faction: Crusade "The crusade endures"; Hegemony "The Hegemony stands"; Hullbreakers "Strongest keeps it"; Chorus "The Chorus swells"; Glasswrights "The light is kept"; Eclipse "Noon returns". Loss title: "The fleet is lost". Abandon title: "Run abandoned".

Win sub: "Three sectors broken, three flagships burning behind you. (Admiral) brings the (Faction) home." Loss sub: "The last hull goes dark in sector (N). The survivors will tell it differently." Abandon sub: "The fleet stands down. Its deeds are recorded."

### 4.2 First-ever loss

Detection: a loss where META.stats.finishedRuns becomes 1 and META.stats.wins is 0 (finishedRuns initialised at main3d.js:7, incremented in endRun, campaign.gd:1388). Because abandoned runs also increment finishedRuns, the build uses a stored profile flag, set when this teaching block renders; an abandon never sets it and never shows the block (section 7). It fires once per profile.

Faction-neutral, in full. Kicker (12 small caps, gilt): "THE FIRST RUN ENDS. THE NEXT INHERITS." Title: "The fleet is lost". Sub: "The last hull goes dark in sector (N). This is not the end of the line. What this run earned is already on its way to the next fleet." Teaching body, above the inheritance panel: "You will lose runs. That is the design, not a verdict. Every death names what the next generation carries: renown in the vault, mastery in the bloodline, and a lesson the enemy taught you at cost. Read the panel below as an inheritance, not a score."

Sunward Crusade, in full. Kicker: "THE FIRST CRUSADE FALLS. THE CHALK REMEMBERS." Title: "The fleet is lost". Sub: "The last hull goes dark in sector (N). The survivors will tell it differently, and the next crusade will read it in chalk before it chooses." Body: "No crusade wins the first dark. That is the oath working, not failing. What this run bought is already written: renown in the vault, mastery in the bloodline, and the weakness the enemy showed you at cost. The next crusade stands at this same dark and reads what you chose. Do not mourn the fleet. Read the record."

Per-faction first losses after the literal first loss are Q1's subject (section 11). The Crusade kicker and sub above are the pattern; kickers and subs for the other five factions are an authoring item at build time if Q1's answer needs them.

### 4.3 Panel leads

Under the panel header, one lead line. Win: "What this victory bought:" Loss: "What this death bought:" Abandon: no lead line; the "Recorded" header carries it.

### 4.4 Nemesis lesson lines

- Weakness revealed (meeting won): "Nemesis lesson: you broke (Name), (Title). Weakness found: (weakness)."
- Weakness taught (meeting lost): "Nemesis lesson: (Name), (Title), beat you and taught you a weakness: (weakness)."
- New adaptation: "Nemesis lesson: (Name) adapted. (Adaptation): (reason)." The reason text comes from nemAdaptWhy, in his faction's words.
- Raid loss (a Hullbreaker Nemesis, against any player faction, R78 Q6): "Raided: (Name)'s Hullbreakers took (N) credits this run. One raider line crossed."
- Nemesis dead: "Nemesis lesson: (Name), (Title), is dead. What he taught you is yours to keep."

### 4.5 Heir naming lines

Prompt: "Name an heir to the (line) line?" Choice row per candidate: "(Admiral), (rank). Shadow (n) XP. Double earnings for this line." Current-heir line: "(Admiral) is the current heir." No-heir row: "No heir this run." Confirm line after naming: "Named: (Admiral). The (line) line earns double shadow until you name another."

### 4.6 Core sync lines

Normal: "(Core): (n) of (threshold) to (next tier)." Example of the arithmetic, from FAVOUR_TIERS: a core at 9 protocols reads "9 of 12 to Synced". Tier-up: "(Core): crossed into (tier) this run at (n) protocols." A core at Full sync (25) that still ticked reports its total with no next tier: "(Core): Full sync, (n) protocols." No ticks: "No protocols taken this run."

### 4.7 Affordability lines

Lead: "Renown: (earned) earned. (balance) in the vault." Newly affordable: "Now affordable: (cheapest newly affordable item), (cost) renown." When more than one item is newly affordable, the line names the single cheapest and appends the count: "Now affordable: (item), (cost) renown, and (N) more within reach." Nothing newly affordable: "Next: (cheapest item) at (cost). (N) more renown." The candidate set includes admiral unlocks (R77), hull variants, Legacy items, and the flown line's respec at its per-line price. Under the playtest switch the line reads: "Playtest: everything unlocked. Earnings recorded." (section 7).

### 4.8 Story row: the six authored lines

Row 5 reproduces the Step 12 payoff lines (contrib/muse/design/story_beat3_2026_11/) verbatim, keyed by faction id:

- voidsworn (Sunward Crusade): "Win or lose, the next crusade stands at this same dark and reads what you chose, in chalk, before it chooses."
- hegemony (Hegemony): "Whether you spoke or stayed linked, win or lose, the doctrine file gains an entry with no author. Couriers carry it at courier speed, and it reaches the next fleet late, one sector behind where it was needed, still the best map that fleet has."
- corsair (Ashfall Hullbreakers): "What the pack killed, and what killed the pack, is carried in the open: trophies bolted to hulls, the story told flat in the dens, and the next litter raised on both."
- chorus (Chorus): "Win or lose, the next generation is grown from this choice in its flesh. Broods after this one will be born knowing whether the swarm feeds its memory or eats it."
- ithar (Glasswrights): "Whether this fleet returns through the light or drifts as a shard-field until the gatherers find it, the forge will read the optical replay and recast the next fleet in the procession with the killing flaw corrected, long after everyone who loved this one is gone. That is not comfort. It is focus, which is the Glasswright word for it."
- deathless (Eclipse): "Win or dark, the Archive keeps this fight in full. Eclipse does not send a new fleet out of the dark: it sends this same one again, its minds restored from the Archive with every lesson and correction intact."

Duplication rule: row 5 always carries the authored beat line. The headline story slot shows the story layer's arc line only when it is a different line; if the two would be identical, the slot collapses and row 5 stands alone.

### 4.9 Copy conflicts resolved against the pack

- Win sub: one leg variant read "Three sectors broken, three more to come". The shipped sub (section 4.1) wins.
- Loss sub: one leg variant ended "The survivors will carry the line forward." The shipped ending, "The survivors will tell it differently.", wins for the standard loss. (The first-loss sub in section 4.2 extends the shipped sentence rather than replacing it.)
- First-loss titles: one response replaced the title with "The line continues" (neutral) and "The chalk outlasts the hand" (Crusade). Not adopted: the title stays the shipped "The fleet is lost" on every loss, first included; the faction flavour lives in the kicker and sub.
- Core sync arithmetic: two leg examples read "14 of 20 to Partial sync". That contradicts the pack on both numbers: FAVOUR_TIERS puts tier ups at 4, 12, and 25, and Partial sync is the tier reached at 4. Section 4.6's format and example follow the pack.
- Respec price: the screened-out Argon leg's flat 250 renown contradicts the shipped per-line formula at core.js:382. The formula wins; see section 12.

## 5. The six required elements

- Nemesis lesson: row 4 (section 3.5). Revealed on this screen only, per R62; covers wins and losses alike, because meetings resolve in both.
- Renown: row 1 (section 3.2). Earned figure, composition, balance, Heat note, affordability line.
- Tree progress: row 2 (section 3.3). Flown admiral's gain, bar, level text, pending-picks line. Picks are never resolved on this screen; the line routes to the lineage screen, where the full tree, the locking partner skill, and the respec price are visible.
- Shadow XP: sub-lines inside row 2, one compact line per benched same-faction admiral that earned: "(Name): +(N) shadow XP (Level (N))." The heir's line is tagged as the double-rate line. Rates are ruled: 25 percent of the flown admiral's XP to each benched same-faction admiral; the named heir's line at double that rate; cap overflow routes here. Source is the Step 3 build item (issue 20). Empty state: no benched admiral of the faction earned, the sub-lines are absent and the heir block shows its empty state.
- Heir naming: the block below the panel (section 3.7), on any run end.
- Core sync: row 3 (section 3.4), ticked cores only (ruling 4).

## 6. Interaction flow

Reading order is interaction order. Nothing is modal and nothing is required; every exit works with no interaction at all.

1. Heir block: select a choice row, then the confirm abtn commits the naming and the block restates the confirm line (section 4.5) with the change action available. The state write happens at confirm time, not at exit, so leaving the screen cannot lose it. With an heir already named, the change action reopens the rows.
2. Pending tree picks: the lineage row's button (label shape: "Choose (Name)'s level (N) skill") routes to that admiral's lineage screen. No picking inline.
3. Spend routing: the doctrine row's foot carries a "Spend renown" button opening Progression on the tab holding the affordability line's named item; when the named item is an admiral unlock, the button reads "Unlock admirals" and routes to the admiral select screen, where unlocks are bought today (R77). Respec is not routed from here; it lives on the lineage screen.
4. Exits (section 3.9), last.

NEXT RUN suggestion (win only): the shipped panel, with the suggestion settled as the unwon faction with the most progress, so the forward hook points at the shortest path to a new win.

## 7. Playtest switch and abandon cases

Playtest switch (R69, on by default; owner ruling 3 keeps it on until all six factions have trees and the telemetry pacing check passes): progression runs intact underneath, and this screen still reports what the run earned. Differences: the affordability line reads "Playtest: everything unlocked. Earnings recorded." (section 4.7); spend routing buttons read "View" instead of naming a purchase; admiral unlocks, variants, and perks read as already open, and no line tells a switch-on player to buy what he already has. Earnings, tree progress, shadow reporting, heir naming, and pending picks are unchanged, because the underlying progression is live.

Abandon: endRun pays the same carry today, and the design keeps it. The full inheritance panel renders with the header "Recorded"; the heir offer applies (ruling 5 says any run end; suppressing it to make abandon feel like a forfeit was considered and rejected); exits are "New run" and "Title screen", with no NEXT RUN panel. The first-loss teaching block never fires on an abandon, and an abandon does not set the first-loss flag.

## 8. Heat: two live shapes

The doctrine row reports what the run actually paid, in whichever Heat shape is live at build time. The design specs both line formats and flags the dependency; it does not pick a winner.

- Shipped shape (live now): Heat is a renown multiplier unlocked by a win, applied in endRun at x(1 + 0.1 per Heat level) (campaign.gd:1397; browser campaign_meta.js:96 to 97). Line format: the renown lead of section 4.7, with the Heat note appended: "Heat (H): renown paid at x(1 + 0.1 x (H))." RUN.carry.hl carries the level.
- Step 10 shape (after issue 26 lands): Step 10 re-gates Heat to after the first loss and makes it pay XP per R63: +2 XP per Heat point to the admiral flown, +1 per point to the faction shadow pool. Line formats: the renown lead carries no Heat note; the lineage row gains the line "Heat (H) paid (2H) XP to (Admiral) and (H) XP to the faction shadow pool."

Which format renders is a build-time fact about which Heat implementation is live, not a runtime toggle. Step 4 builds against the shipped shape; when issue 26 lands, the row swaps format with it.

## 9. Dependencies and graceful degradation

Named build prerequisites, each owned by its step's issue:

- Shadow XP state and heir state: Step 3 (issue 20). Until it lands, row 2 renders without shadow sub-lines and the heir block renders its empty state.
- Per-run core tick record: Step 5 (issue 22). Until it lands, row 3 renders "No protocols taken this run." (Strictly, the row cannot distinguish "no ticks" from "not recorded yet"; the empty line is the honest render either way.)
- Per-run Nemesis lesson log: Steps 4 and 7 (issues 21 and 24). Step 4 builds the row against RUN.nem and the nemAfterBattle machinery; the gathered per-run log completes with Step 7.
- Affordability summary: Step 4 (issue 21), over price tables that all exist today.
- First-loss stored flag: Step 4 (issue 21), one line of profile state (section 4.2).

The screen degrades in exactly that order and no row waits on another row's step.

## 10. Build order (Codex, against issue 21)

1. End page restructure at px(960) with the inheritance panel skeleton and rows 1, 2, and 5 (renown and affordability, lineage without shadow sub-lines, story row with the duplication rule). All data for these rows is live today.
2. First-loss detection (stored flag) and the teaching block, with the neutral copy set and the Crusade set.
3. Nemesis row against RUN.nem plus the per-run lesson log (meetings, weaknesses, adaptations, raid losses, death), completed with Step 7 (issue 24).
4. Core row against lifetime favour now; swap to the tick record when Step 5 (issue 22) lands.
5. Heir block and shadow sub-lines when Step 3 (issue 20) lands; empty states until then.
6. Spend routing buttons (Progression tabs, admiral select, lineage screen) and the playtest switch states (View labels, open affordability line).

Test, from the Job 7 synthesis: finishing a run, win or loss, produces a debrief whose panel matches the profile state the run actually created.

## 11. Owner questions

Q1. First-loss scope. (a) The full teaching panel fires on the literal first loss only; a faction's first loss after that gets only its faction kicker and sub, no body panel (chair pick). (b) The full teaching panel fires on every faction's first loss, six times over a profile's life. (c) Literal first loss only, with nothing extra for later factions' first losses. Stakes: (a) teaches the loop once at full strength and still marks each faction's first death in its own words, at the cost of authoring five more kicker and sub pairs; (b) repeats a long panel the player has already read, in six flavours; (c) is cheapest and loses the per-faction moment entirely.

Q2. Heir doubling timing. When an heir is named on this debrief, does the double shadow rate apply from the next run onward (chair pick), or does it also re-pay this run's shadow earnings doubled? Stakes: next-run-onward is the cleaner rule and matches how the naming reads (you name who carries forward); re-paying this run makes the naming moment itself pay out, but reaches backwards into earnings this screen has just reported at the plain rate. This answer also binds Step 3 (issue 20): its heir logic cannot be final until this is ruled. This is the one blocking question.

Q3. Story row frequency. The authored beat line shows on every run end (chair pick), or only the first time each faction's line would appear? Stakes: every-time makes row 5 the faction's standing record, the sentence the next generation is defined by, at the cost of repetition the player will start to skim; first-time-only keeps it an event, but then most debriefs have an empty-feeling fifth row and the screen loses its closing beat.

Q4. Nemesis lesson scope. Lessons (weaknesses revealed or taught) stay attached to the specific hunter they were earned against (chair pick), or follow the player across hunters, so a weakness learned on one hunter informs meetings with the next? Stakes: hunter-specific keeps each feud personal and matches the current RUN.nem shape; following the player rewards accumulated knowledge across the redesigned variable hunter pool (issue 45), but blurs whose lesson it was and needs the redesign to say how lessons transfer.

## 12. Argon leg screening

The Argon leg was screened out as a design source and is filed as the verbatim record only. It designs a different screen than the one the pack specifies: a per-battle summary with invented panels (Debrief Actions, Choice Buttons) and invented mechanics (Accept Legacy, Accept Scar, Retry Battle, Train Commanders) that do not exist in the game. It states a flat 250 renown respec, contradicting the shipped per-line formula at core.js:382 (25 + 10 per prior respec of that line), which is also owner ruling 2. It lists invented items as "Owner Decisions" the owner never made. Nothing in this design rests on it. The only points the chair carries from it are ones other legs reached independently: widening the shipped 720 column (settled at 960 on the DeepSeek position) and scaling 4K purely through px().

## 13. Dissents and rejected positions

- Column width: the Rey leg and Qwen Response 1 keep the shipped px(720). Not adopted; 960 is the settled width (DeepSeek position). Their orders and copy were otherwise largely convergent.
- Fixed footer: Qwen Response 2 takes the exit buttons out of the scroll into a fixed footer, and gives the stat tiles a fixed 1028-wide row of 196px cards. Not adopted: exits stay last in the column as shipped, and tiles wrap inside the 960 column.
- First-loss placement: the Rey leg puts the teaching panel after the inheritance panel and refers back to it. Not adopted; the DeepSeek placement (body block above the panel, kicker in the headline) carries, so the lesson frames the ledger instead of summarising it.
- Empty rows: the Rey leg omits the core row and the heir panel entirely when they would be empty. Not adopted for rows 1 to 4, which render dim empty lines so the frame is stable; the heir block always shows its current-heir line (section 3.7).
- Heir block default: Qwen Response 1 would show the block only when the slot is empty, replaced by a bare current-heir line otherwise. Partly adopted: the compact default carries, but the current-heir line is always present and the rows sit behind a change action (settlement in section 3.7), rather than the block vanishing.
- Heir confirm mechanics: the Rey leg names on tap with no confirm step. Not adopted; the DeepSeek select-then-confirm shape carries, because the confirm line is where the double-rate effect is restated.
- Panel header wording: the shipped header is CARRIED FORWARD. The settled header is "WHAT THIS RUN BOUGHT" for win and loss (DeepSeek), with "Recorded" on abandon (Qwen, both responses). The Rey leg's per-outcome verdict sentences were not adopted; the DeepSeek panel leads (section 4.3) carry instead.
- Everything-owned affordability: the Rey leg's "yards and legacy are complete" line was not adopted; when everything is owned, section 4.7's distance line has no target, and the row falls back to naming the flown line's respec price as the next spend. (Chair note: this fallback is the one affordability case no leg specced in full; it is a small build-time decision for Codex, flagged here rather than hidden.)
- Story duplication: the Rey leg renders the headline slot and row 5 independently, with no collapse rule. Not adopted; section 4.8's rule carries.
- NEXT RUN suggestion: the shipped behaviour suggests an unwon faction without a stated rule. Qwen Response 1's most-progress rule is adopted (section 6); a random pick was the alternative.

## 14. Not checked

- The Godot story layer's _story_text source and the arc end callback (campaign.gd:1404) were located but not read in full during grounding; the design treats the story slot as existing.
- Battle-side accumulation of RUN.stats and per-ship career (car) was not re-read; the recap's use of it is the anchor.
- Whether an abandoned run's flown-admiral XP feeds shadow earnings is not settled by the pack. The design assumes the abandon carry is paid as shipped today; Step 3 (issue 20) owns the shadow-on-abandon call.
- FAVOUR_TIERS effect strings per tier are not in the pack beyond tier names and thresholds; the tier-up line (section 4.6) deliberately carries no effect text. If a tier-up line wants the effect, it reads it from data at build time.
- The exact shell action names for the Progression tabs are not in the pack; section 6 names the destinations, and Codex binds them to the existing abtn actions.
- Rounding of the Heat-adjusted renown figure is existing endRun behaviour and was not re-derived.
- Kicker and sub copy for the five non-Crusade factions' first losses is not authored in any leg; it is a build-time authoring item, needed in full only under Q1 option (a) or (b).
- The frozen browser build's register was not extracted; Godot is the build target and its register is what section 2 cites.
