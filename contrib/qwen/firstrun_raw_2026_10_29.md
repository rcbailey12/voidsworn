Chair note: filed verbatim from the Qwen3.8-Max run of Oct 29, 2026 (both model gates passed, single response), except em dashes, en dashes, and unicode minus signs in the model's text are normalized to hyphens.

FIRST-RUN EXPERIENCE AUDIT - VOIDSWORN
PROOF OF READING
Sections read:
EVIDENCE PACK title line ("first-run experience audit, code slices from the shipped browser build, main 264f441d; the Godot port mirrors this design")
THE COMMISSIONER'S QUESTION
CHAIR CENSUS (all six bullet points)
WHAT TO JUDGE (questions 1-5)
Code slice: ui3d.js 654-700 (tutorial tip system, help card, action strip, command, camera, watchdog)
Code slice: campaign_run.js 1-30 (node types, reward labels, map screen)
Code slice: core.js 322-340 (newRun setup)
Overall verdict: ROUGH EDGES.
The game builds a coherent loop and the tip system is mechanically sound, but too many ruled systems arrive silent in run 1, the fiction layer obscures the one choice a new player must make with information they don't yet have, and the designed-loss framing has no visible bridge to run 2 in the code provided.
FINDINGS
1. [BLOCKER] Heat, faction drives, boons/patrons, modules, and the Nemesis's hidden weaknesses all enter run 1 with zero in-game explanation. READ. The chair census lists these as "ruled by the designer over Oct 27-28" and present in a first run. The tip-condition object in tutorialCheck contains exactly ten keys: start, turns, threat, select, move, target, fired, resolve, close, objective. None of those keys maps to Heat, faction drives, boon acquisition, module equipping, or Nemesis weakness discovery. No other explanatory surface (codex entry, pre-battle card, map tooltip) appears in any provided slice. A new player will experience these systems as unexplained state changes. INFERRED: because the Godot port "mirrors this design," the silence carries over.
2. [BLOCKER] The Nemesis arrives as a wall, not a lesson. READ. The census states: "forced meeting in sector 1's last columns, two hidden weaknesses, adaptations." The designer states "winning run 1 should be near impossible." No tip condition references the Nemesis. The help card (stripHelp) explains Done/Ability/Command/Ram/Board/Brace/Launch but says nothing about a rival commander, hidden weaknesses, or adaptations. The player meets an enemy that adapts to their play and has two secrets they cannot discover, in a fight they are designed to lose, with no frame that says "this is your teacher." INFERRED: without a framing line, the player reads the loss as punishment, not curriculum.
3. [BLOCKER] The debrief / lineage hand-off is absent from every provided slice. READ. The census says "its debrief is meant to teach the inheritance" and the designer frames meta-progression as "a lineage that learns." No code for a debrief screen, run-end summary, inheritance display, or run-2 onboarding appears in the pack. newRun shows what meta-unlocks feed into a new run (META.unlocked.chest1, cmd1, founder, vets) but nothing shows the player that they earned those or why run 2 differs. INFERRED: the lineage frame currently lives only in design documents.
4. [FIX] "Signal of [patron]" is the worst fiction-first label; it hides the mechanic a new player needs most. READ. rewardLabel returns 'Signal of '+PATRONS[rw.p].short for boons. A new player has no definition of "patron," "boon," or what a "Signal" grants. The node description for event is "Something is out there. Could be anything." The map badge renders a glyph and a short name in the patron's colour. None of this tells the player: this is a passive perk, here is what it does, here is the trade-off. The mechanic is hidden behind a proper noun the player has not been taught.
5. [FIX] The tip system's dismissal model is one-tap-to-forever with no recovery path shown. READ. ACT.tipOk sets o.tips[id]=1 and saves. ACT.tipOff sets o.tipsOff=true. No code in the pack re-enables tips, offers a "re-show tips" option in settings, or gates the dismiss button behind a delay. INFERRED: a player who reflexively taps "Got it" on the start tip or hits "Hide tips" during the first confusing moment permanently loses the only teaching layer.
6. [FIX] The help card is a wall of text behind a "?" button with no contextual trigger. READ. ACT.stripHelp toggles a card listing six button explanations in one <p> block. It is only reachable by tapping ? in the action strip. No tip condition or scripted moment opens it. INFERRED: a new player in their first battle, overwhelmed by hexes and firing arcs, is unlikely to seek out a "?" button; the information exists but is buried at the moment it's needed.
7. [FIX] The command ability's two-tap confirm and growth mechanic are explained only inside the help card, not at the moment of first availability. READ. The resolve tip condition fires when canCommand('player') is true, but the tip text is in the unseen TIPS array. The help card says "it grows each round you wait, and when you lose a ship." The action strip renders cmdTier() pips and a 6-second confirm window with a visible countdown. INFERRED: a player who never opens help will see a gold button, tap it, see a countdown, and not understand why waiting was valuable.
8. [NOTE] The action-strip hint line is the most effective micro-teacher in the pack, but it only covers spatial/tactical state. READ. The hint variable cycles through: wing-selected instructions, ram alignment, firing-range prompts, "nothing left to do." These are clear, contextual, and non-dismissable. They teach where to tap well. They never teach why-no hint explains Heat consequences, faction-drive trade-offs, or why boarding might beat destroying.
9. [NOTE] The start tip fires immediately (cond={start:true,...}) but its content is unknown. READ. The condition is unconditionally true on the first call to tutorialCheck in a battle. The actual text is in the TIPS array, which is not included in the pack. INFERRED: if this tip is generic ("Welcome, Admiral"), it wastes the single highest-attention moment in the game.
10. [NOTE] Camera behaviour is player-respectful but invisible; a new player gets no onboarding for the 3D view. READ. camKeep/camRestore preserve the player's view across enemy turns; camShow pans but never zooms. No tip or hint explains how to rotate, zoom, or re-center. The Center button exists in the strip but is not explained outside the help card. INFERRED: on mobile, a player who accidentally rotates the camera and can't recover will feel lost before the tactics even begin.
EXPLICIT CHECKS
TEACHING ORDER
Systems a new player meets in run 1, in code-presentation order:
Order - System - Where it appears - Status
1 - Admiral + faction choice - newRun entry - Silent - no slice shows a selection screen explaining what the choice changes
2 - Starting fleet composition - adm.start.map(...), newShip - Silent - ships appear; no card says "this is your fleet, here is the roster"
3 - Sector-1 map with node types - mapScreen, NODE_INFO - Explained - each node has a name and one-line description
4 - Reward labels on nodes - rewardLabel, rewardBadge - Silent - "Signal of," "Refit" appear with no definition
5 - Nemesis creation - newNemesis() at run start - Silent - created but no introduction, no "a rival hunts you" card in any slice
6 - First battle: select / move / fire - Tip conditions select, move, target, fired - Tipped - contextual tips fire in sequence
7 - Command ability - Tip condition resolve; action-strip button - Tipped (condition) + help-card text; the tip text itself is unseen
8 - Ram / Board / Capture - Tip condition close; help card - Tipped (condition) + explained in help card
9 - Brace - Action-strip button; help card - Explained only in help card
10 - Faction drives - Chair census - Silent - no tip, no UI slice
11 - Boons and patrons - RUN.patrons, giftBoon, boonLine - Silent - data structures exist; no teaching moment shown
12 - Modules / Refit - rewardLabel returns "Refit" - Silent - label only, no equip screen in pack
13 - Heat - RUN.heat in newRun - Silent - stored, filtered by HEAT[k], never explained
14 - Nemesis weaknesses + adaptations - Chair census - Silent - "two hidden weaknesses" by definition not surfaced
15 - Meta-progression / lineage - META.unlocked.*, META.stats.runs++ - Silent - no debrief or inheritance screen in pack
Which silent system hurts most? The Nemesis's hidden weaknesses. Every other silent system is a passive modifier the player can survive ignoring for one run. The Nemesis is a forced, adaptive, designed-to-kill-you encounter in sector 1. Meeting it with zero information about its weaknesses or adaptation logic, in a run framed as a loss, converts the game's central teaching device into an opaque punishment. The player cannot learn from a fight they don't understand.
THE TIP SYSTEM
Contextual tips are the right vehicle shape for a roguelite: they appear at the moment of need, don't block a cutscene, and can be dismissed. For a game this dense (the census lists seven-plus ruled systems in run 1), they are the wrong vehicle capacity. Ten tip slots cannot carry Heat, faction drives, boon/patron logic, Nemesis weaknesses, capture economics, module equipping, and lineage. The tips teach the tactical layer (move, fire, ram, command) and stop. The strategic and meta layers are silent.
Three tips that matter most:
start - fires unconditionally on the first tutorialCheck call. This is the single highest-attention moment. Its text is not in the pack, so I cannot judge whether it sets expectations ("you will likely lose; here is what to watch") or is generic. Fires early enough: yes, condition is true.
select → move → target → fired - the core combat loop. These fire in the correct order (select a ship → it can move → enemies in range → weapons fired). Fire early enough: yes, they trigger on the first battle's first player turn.
resolve (command ability) - fires when canCommand('player') is true, which should be the first round. Fires early enough: yes, but the mechanic it teaches (growth over rounds, scaling on ship loss) is a strategic concept that a one-line tip cannot carry. The help card carries the real explanation, but the player must seek it.
The pack does not show tips firing for threat (round>=2), close (ram/board), or objective. These are secondary. The critical gap is not timing but coverage: no tip exists for any system outside the tactical battle.
FICTION-FIRST LABELS
Label - Fiction name - Mechanic it hides or reveals - Verdict
Battle - "Battle" - Standard fight - Helps - transparent
Elite fleet - "Elite fleet" - Harder fight, drops salvage - Helps - "elite" signals difficulty; "salvage" is jargon but close to "loot"
Shipyard - "Shipyard" - Buy, repair, upgrade - Helps - real-world anchor
Drydock - "Drydock" - Free full repair - Mostly helps - a new player may not know "drydock" means free repair vs. paid; the description "Free repairs for the whole fleet" saves it
Field repairs - "Field repairs" - 20% hull patch, free - Helps - description is clear
Unknown signal - "Unknown signal" - Random event - Helps - "?" icon and "Could be anything" set expectations
Sector flagship - "Sector flagship" - Boss fight - Helps - clear
Signal of [patron] - "Signal of the Forge-Mother" (example) - Grants a boon (passive perk) from a patron faction - Hides - "Signal" is not a game-mechanic word; "patron" is undefined; the player cannot evaluate whether to path toward this node
Refit - "Refit" - Grants a module (equippable upgrade) - Mildly hides - "Refit" is naval jargon; a new player may not know this means "get a new part for a ship." The description is absent on the map; only the label shows.
Credits - "Credits" - Currency - Helps - universal
Repairs - "Repairs" - Heal - Helps - transparent
Worst offender: "Signal of [patron]." It is the only label that conceals both the category of reward (passive perk vs. consumable vs. currency) and the source (a patron you haven't been introduced to). A player choosing between two map paths cannot evaluate "Signal of the Warden" vs. "Refit" without knowing what a boon does, what rarity means, and whether the patron matters later. The fiction is doing worldbuilding where the player needs a decision aid.
THE NEMESIS IN RUN 1
The census states: "forced meeting in sector 1's last columns, two hidden weaknesses, adaptations." The designer states: "winning run 1 should be near impossible."
This is a wall, not a lesson, as currently implemented in the visible code.
A lesson requires: (a) the player knows they are being taught, (b) the player can identify what they failed to do, (c) the game names what to try next. The pack shows none of these for the Nemesis. There is no pre-battle card ("A rival commander blocks your path; she adapts to your tactics"). There is no tip condition for Nemesis-specific mechanics. The weaknesses are hidden by design. The adaptations are unnamed in the code provided. The player loses to an enemy they cannot read, in a run they cannot win, and the code does not tell them that losing was the point.
The one structural mercy is that the Nemesis is in "sector 1's last columns," so the player has a few battles first to learn the tactical loop. But those battles teach move/fire/brace; they do not teach "this specific enemy has secrets." The jump from "I am learning hexes" to "I am fighting an adaptive rival with hidden weaknesses I am supposed to lose to" is unbridged.
INFERRED: if the debrief screen (absent from the pack) explicitly names the Nemesis's adaptations and says "next time, you will know her weaknesses," the wall becomes a lesson. But that text is not in the evidence.
RUN 2's PLAN
What the player concretely knows after run 1 (from the pack):
How to select, move, fire, brace, ram, board (if tips survived and help card was found).
What the map node types mean (NODE_INFO descriptions).
That a Nemesis exists and beat them (they experienced it, but not why).
The shape of a sector (columns, node choices).
What the player concretely owns going into run 2 (from newRun meta-unlock checks):
Possibly 75-225 extra credits (chest1/2/3).
Possibly +2 to +4 command-point cap (cmd1/2).
Possibly a starting relic (founder).
Possibly veteran starting ships (vets).
META.stats.runs incremented.
Is the lineage frame legible? No, not from the code in this pack. The newRun function reads META.unlocked.* and applies bonuses, but no slice shows the player earning those unlocks, seeing a debrief that says "your admiral's line remembers," or choosing what to carry forward. The phrase "a lineage that learns" appears only in the designer's stance in the census. The word "inherit" does not appear in any code slice. The player who loses run 1 and returns to the menu sees, from this pack's evidence, no concrete bridge. They get a slightly higher number (cpCap) and maybe more credits, with no narration attaching those numbers to the fiction of legacy.
INFERRED: if the debrief screen exists outside this pack and does the narrative work, the lineage frame lands. But the pack's own question asks whether it is "legible from what the game shows," and from the provided code, the answer is no.
NOT CHECKED
The pack does not let me judge:
The actual text of the TIPS array (only the condition keys and the card-rendering code are shown).
The debrief / run-end screen (no code provided).
The admiral and faction selection screen (no code provided).
The Nemesis's specific adaptation logic or how weaknesses are revealed across runs.
The Heat system's mechanical effect or UI.
Faction drives' mechanical effect or UI.
The module/refit equip screen.
The patron/boon acquisition flow beyond the giftBoon line in newRun.
Any audio, animation, or visual feedback that might compensate for text gaps.
The Godot port's implementation (only stated to "mirror this design").
Balance tuning: whether run 1 is actually unwinnable or merely very hard.
Whether a "re-show tips" or settings menu exists outside these slices.
QUESTIONS FOR THE DESIGNER
Where is the debrief screen, and does it name the Nemesis's adaptations in plain language? The entire lineage frame and the "designed loss as teacher" concept depend on a screen that is not in this pack; if it doesn't exist yet, run 1's loss is a wall with no door, and the player has no reason to start run 2 with a plan rather than quit.
What does the start tip actually say, and does it set the expectation that this run is a first draft, not a winnable battle? The highest-attention moment in the game is a single tip card firing on cond.start === true; if that card doesn't reframe the entire session as "you are building a lineage, not winning a war," every subsequent system that kills the player reads as failure rather than curriculum.
Is there a recovery path for a player who taps "Hide tips" in the first ten seconds, and if not, why is the only teaching layer one accidental tap away from permanent silence? The tip system is the sole in-game teacher for the tactical layer; ACT.tipOff is a single boolean with no undo visible in the code, and a confused new player's most likely reflex is to dismiss the unfamiliar UI element.
