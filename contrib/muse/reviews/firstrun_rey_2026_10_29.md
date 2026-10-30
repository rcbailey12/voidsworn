# First-run experience audit - Rey leg (Oct 29 program)

Reviewer note: this is a blind leg written from the evidence pack (firstrun_pack.txt, pin 264f441d) plus the reviewer's own direct code reads in the shipped browser build. Where a claim rests on code outside the pack's slices, the finding says so.

## 1. Proof of reading

Pack sections read: the EVIDENCE PACK title line ("first-run experience audit, main 264f441d"); THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE (all five questions); and all three code slices (ui3d.js 654-700, tutorial tips and the action strip; campaign_run.js 1-30, node types and reward labels; core.js 322-340, newRun setup). Code read beyond the slices to test claims: the TIPS array (ui3d.js 642-652), the Nemesis block (campaign_run.js 247-340 and the map card at 71-94), the run-end panel (campaign_meta.js 188-235), runRenown (campaign3d.js 30), the prize modal (campaign_run.js 433-461), the run-options screen (campaign_meta.js 85-105), and the settings handler (campaign3d.js 116-119).

Overall verdict: LOST IN THE VOID - the battle layer is taught passably, but the campaign and meta layers that make this a roguelite have no teacher at all, and the one meeting the first run is designed around teaches nothing when it goes the way it is designed to go.

## 2. Findings

1. [BLOCKER] The tip system structurally cannot teach the campaign layer. READ (pack slice plus code): tutorialCheck returns immediately when there is no battle object, when the app shell is on, or when an intro screen is up, and mapScreen sets B=null. Every tip condition (start, turns, select, move, target, fired, resolve, close, threat, objective) is a battle state. So the map, routing, node choice, command points, patrons, the shipyard, and the run structure get zero contextual teaching, not weak teaching. The game's density lives at least half on the campaign layer, and that half is silent by construction.

2. [BLOCKER] The designed-loss Nemesis meeting teaches nothing on the loss path. READ (code beyond the pack): in nemAfterBattle, the win branch reveals a weakness by name ("His captured logs reveal a weakness"), but the loss branch returns a single line, that he "drove you off" and "will remember this." No weakness is named, nothing the player did is identified, and no adaptation is shown. The commissioner's premise is that run 1 is designed to be lost, so the branch most first players will actually read is the empty one. The one exception is real: weaknesses triggered during the battle itself stay known even in a loss (the finish code merges battle-found weaknesses into the revealed list). A player who loses without accidentally triggering one learns only that the rival exists.

3. [FIX] The map's boon badge hides the mechanic at the moment of choice. READ (pack slice): rewardBadge renders a boon node as a colored circle with the patron's glyph, the patron's short name, and a star when rw.min is set. The word boon (or protocol) never appears on the map, the glyph is unexplained, and the star, which marks a guaranteed minimum rarity, is glossed nowhere a first-run player sees. The boon itself is well explained later, at pick time, where boonLine prints the name, rarity, and full effect text. The failure is at routing time: a new player cannot tell that a Signal node pays a permanent, build-defining upgrade, so the map's main strategic choice is made blind.

4. [FIX] Every tip card carries the kill switch for the whole curriculum. READ (pack slice): each card offers "Hide tips," which sets o.tipsOff permanently. One press on the first card, including a misclick, ends all teaching for the run and beyond. Recovery exists in code (the Settings "Battle tips" row; turning tips back on also clears the seen set so every tip re-fires), but nothing in the game points a player who hid tips toward that row. The defect is discoverability, not absence.

5. [FIX] The opening minute can cascade modal cards, and two tips fire only after the act they teach. READ (pack slice plus TIPS array): tipOk chains the next check after 400 ms, and at battle start the start, turns, select, and resolve conditions can all be true at once, so a new player can face a queue of full cards before making a second decision. Separately, the fired tip requires a weapon to have already fired, and the move tip requires a ship to have spent movement points: both explain a system only after the player has used it untaught.

6. [FIX] The rival's learning loop, the run's signature system, is not demonstrated in sector 1. READ (code): the adaptation budget cap is max(0, sector-1), plus a fast-adapt term for specific factions, so in sector 1 the standard rival cannot adapt at all. Combined with weaknesses that start hidden and a loss branch that reveals none, a first-run player sees a strong enemy with two "unknown" slots and no visible evidence that he learns, adapts, or can be studied. The system the lineage frame depends on is asserted by the map card, never shown working.

7. [NOTE] The Nemesis map card is genuinely good framing and should be protected. READ (code): the card on the map names the rival and his persona, lists his strengths with tooltips, shows both weaknesses as explicit "unknown" slots (a promise they exist and can be learned), and explains the hunting clock in his own voice: every fight won moves the clock, and when it fills the next fight is his. The meeting is also signposted on the map in advance, with the node labeled Nemesis. This is the one campaign system that explains itself; it proves the game can teach on the map when a system gets a panel.

8. [NOTE] The capture prize modal is the best teacher in the run. READ (code beyond the pack): after a boarding win, the prize screen explains the choice in plain terms ("Keep, strip or sell back each one, then confirm once"), shows command points used and after-joining, prices each option on its button, and notes that owners pay less for each successive ransom. A first-run player can make this decision informed. It is the standard the boon badge and the Nemesis loss debrief fail to meet.

9. [NOTE] The debrief pays and itemizes, but never states the lineage frame in fiction. READ (code): endRun pays renown on any run end (battles, elites, bosses, kills, sectors) and mastery XP to the admiral, and the "Carried forward" panel shows both, with a spend instruction ("Spend it on hull variants in Progression") and either the new mastery level and its perk or progress toward it. Fallen captains are named; a next faction is suggested with its blurb. But the panel speaks only in currencies and levels. Nothing on the screen says the next fleet inherits what this one learned, and the rival himself is re-rolled fresh each run, so his memory does not carry either. The inheritance is legible as mechanics, not as the story the design intends.

10. [NOTE] Two systems are honestly signposted rather than silent, which sharpens the contrast. READ (code): Heat is not in run 1 at all; the run-options screen shows a locked card ("Win a run to unlock Heat") and only offers Heat choices after a first victory, so its absence is explained, not mysterious. The faction action is explained by its own map button, which prints the effect and its cost or "Used this sector." Where the game chooses to spend one sentence, the system lands; the silent systems are silent because no surface was given the sentence.

## 3. Explicit checks

### 1. TEACHING ORDER

In the order the code presents them in run 1:

1. Admiral and faction choice (run-options screen): explained in part. Admiral effects, mastery-gated options, and the faction blurb are shown; the locked Heat card explains itself. Patron "sync" and renown are named before they are explained.
2. The map and node types (NODE_INFO): tipped at glossary level. Each node has a name and one honest line ("Free repairs for the whole fleet" against "Every ship patches 20% of its hull" is a genuinely instructive pair). No tip ever fires here.
3. The Nemesis card and faction action (map sidebar): explained, the card by a full panel, the verb by its button text.
4. Battle basics (TIPS: start, turns, select, target): tipped, and early. Selection, alternating activations, movement modifiers, shields, and firing are all covered in the first battle.
5. Command (resolve tip plus the help card): tipped, fires when the Command is ready.
6. Ram and board (close tip, stripHelp): tipped, condition-gated on a ram lane or board target existing.
7. Threat map (threat tip): tipped, but not before round 2.
8. Rewards after battle 1 (boonLine, module choice): explained at pick time, hidden at map time (finding 3).
9. Capture prizes (prize modal): explained, the best in the game (finding 8).
10. Shipyard, drydock, field, and event nodes: tipped at glossary level by NODE_INFO; their screens were outside the pack.
11. The sector flagship and the forced Nemesis meeting (last columns of sector 1): the meeting is signposted; its teaching depends entirely on the result (finding 2).
12. Heat: silent in run 1 by design, and honestly locked (finding 10).
13. Meta-progression (endRun debrief): explained as currencies at the very end; never introduced before it pays out.

The silent system that hurts most: patrons and favour. Boon offers are the run's build decisions, they arrive from the first battle onward, they are routed toward by an unexplained glyph on the map, and the favour relationship behind them (why this patron offers, what the star means, what sync does) is never given a surface in run 1. Command points run a close second: the cap shapes every capture and purchase decision and is only ever shown as a number.

### 2. THE TIP SYSTEM

Contextual tips are the right vehicle for the battle layer and the wrong vehicle as the game's only teacher, because they cannot fire anywhere else (finding 1). Within battle, the design is sound in shape: one card at a time, condition-triggered, dismissible per tip, with a contextual hint line and an on-demand help card behind them.

The three tips that matter most: start (selection, movement hexes, firing arcs: the entire interaction model in one card), target (red rings, hover odds, click to fire, and the single-weapon keys, which is the combat verb), and select (the movement modifiers and brace, the least intuitive numbers in the game). All three fire early enough: start and turns are unconditional, target fires the moment a target exists, and select fires on the first selection. The conditions are not the problem; the cascade risk (finding 5) and the two post-action tips are.

### 3. FICTION-FIRST LABELS

Node names mostly help. Shipyard, Drydock, and Field repairs are fiction words whose one-line descriptions state the mechanic exactly, and the drydock/field pair teaches a real distinction. Elite fleet and Sector flagship are plain. Unknown signal is honest about being unknown.

Reward labels split. "Refit" for a module hides the boon/module distinction but the choice screen repairs it. "Credits" and "Repairs" are plain. The worst offender is the boon badge, "Signal of" plus a patron short name: at map scale it reduces to a glyph and a name with an unexplained star, and it conceals that the node pays the run's most important reward class. Fiction helps when the description line carries the mechanic (nodes) and hides when the label is asked to carry it alone (the badge).

### 4. THE NEMESIS IN RUN 1

Lesson for winners, wall for losers. The scaffolding is lesson-shaped: he is introduced on the map before he is met, his card explains the clock and promises two learnable weaknesses, the meeting node is labeled in advance, and triggering a weakness teaches it even in defeat. But the designed outcome of the sector 1 meeting is a loss, and the loss path is informationally empty: no weakness named, no cause identified, no adaptation displayed (none can exist yet under the sector 1 cap). A teaching device that only teaches the students who did not need the lesson is a wall with a syllabus posted beside it.

### 5. RUN 2's PLAN

Concretely known and owned after the designed loss: a renown balance with a named place to spend it (hull variants in Progression); admiral mastery XP with either a new level and its named perk or an exact progress count toward it (the level 1 threshold is 6 XP, and mastery pays battles plus double for elites and five per boss, so a run that dies at the sector 1 flagship will usually, not always, clear it, unlocking the alternate starting fleet); the names of the captains lost; a best-sector mark to beat; and a suggested next faction with its blurb. That is a real plan: same admiral, one level stronger, renown in hand, a variant to buy.

Is the lineage frame legible? As mechanics, yes; as fiction, no. Everything that carries is a number on the debrief, and the debrief's own words are accounting ("Carried forward"), not inheritance. The frame the commissioner describes, a line that learns, is visible only in the Nemesis's memory within a run, and even he is re-rolled for the next one. A new player can start run 2 with a plan; they will describe it as "my admiral leveled up," not as their line learning. Whether that gap matters is a design question, but the gap is real and it is in the shipped text, not the design documents alone.

## 4. Not checked

Event node contents and their choice text; the shipyard and module choice screens beyond their map labels; the sector transition screens (where adaptations earned later are presented); encounter objective briefings beyond the objective tip; the admiral and faction pick screens beyond the run-options code read; how a new player discovers Settings, where tip recovery lives; the Godot port's version of any of this; and any play data on where real first-run players actually stall.

## 5. Questions for the designer

1. Should a lost Nemesis meeting teach one weakness on the debrief, as a win does? Stakes: run 1 is designed to be lost, so the loss branch is the syllabus most first players will ever read, and today it is one line.
2. Should the map get a teaching channel of its own (first-visit cards for patrons, command points, and reward badges)? Stakes: the tip system cannot fire off the battle screen, so without one, half the game stays silent no matter how good the battle tips get.
3. Should the boon badge name the mechanic under the fiction (the word Boon or Protocol under "Signal of")? Stakes: routing is the campaign's core decision, and players currently route toward the run's most important rewards without knowing what they are.
