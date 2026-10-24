# Research batch 3: Nemesis systems and event design for Voidsworn

Read-only synthesis. No posts, votes, messages, or repo writes. Sources are ranked by usefulness to Voidsworn, not by popularity. Sourced claims are tied to a listed source; anything else is labeled [Inference]. Summaries are in my own words; no code and no long passages are pasted. Note on scope: the ship-five items (Nemesis, blue options plus 20 more events, faction verbs) are already ruled YES, so this report covers how to do them well, not whether to do them.

## Priority 1: Nemesis systems and recurring rivals

**1. TheGamer, "Middle-earth: Shadow of War - Nemesis System Complete Guide"**
https://www.thegamer.com/middle-earth-shadow-of-war-orc-nemesis-system-complete-guide/
Substance: Mordor's system is a visible hierarchy (grunts, captains, warchiefs, overlords) that evolves from play. An enemy that kills the player is promoted and gets stronger; a promoted enemy gains a new trait or personality tied to the injury it survived. Named enemies remember previous encounters and comment on them in dynamic voice lines, and a captain's best friend may leap into combat to defend them. The player can check a nemesis menu for intel on strengths and weaknesses.
Relevance: ADAPT. This is the core template for Voidsworn's Nemesis: a named, visible rival with a memory, a hierarchy slot, and player-facing intel. One line why: memory plus a visible record is what turns a random elite into a personal rival.

**2. Shacknews, "Shadow of War - Nemesis System Explained"**
http://www.shacknews.com/article/101634/shadow-of-war---nemesis-system-explained
Substance: A first-person account of the system working as intended: the author defeats a warchief, then is killed by a captain, who is immediately promoted into the vacant warchief slot and becomes a harder, personal target. Separate "nemesis missions" stage feuds between two AI captains; the winner is promoted and can fill vacancies, and the player may watch, intervene for one side, or kill both in the chaos.
Relevance: ADAPT. Two transferable mechanics: vacancy-driven promotion (a kill creates a hole something fills) and feud missions the player can influence. One line why: both give the player agency over the rivalry instead of only reacting to it.

**3. XCOM Wiki (Fandom), "The Chosen"**
https://xcom.fandom.com/wiki/The_Chosen
Substance: XCOM 2's War of the Chosen adds three recurring rivals (Assassin, Hunter, Warlock), each with random strengths and weaknesses per campaign. Each Chosen gradually gains knowledge about XCOM, including by capturing or interrogating soldiers; rising knowledge escalates sabotage (reduced regional income, injured staff, destroyed items, delayed research). At maximum knowledge a Chosen attacks the Avenger, and losing that defense ends the campaign; repelling it drops the Chosen back a knowledge level. A Chosen can only be permanently killed by assaulting its stronghold. Covert actions can reduce a Chosen's knowledge.
Relevance: ADOPT the structure, ADAPT the details. This is the closest tactics analogue to Voidsworn's Nemesis: a recurring rival with a visible escalation meter, between-battle counterplay, and a final-kill condition. One line why: the knowledge bar plus covert-action counterplay is exactly how a once-per-sector ambush stays fair instead of feeling like a scheduled punishment.

**4. Game Developer, "Core System Analysis of Middle-Earth: Shadow of War"**
https://www.gamedeveloper.com/design/core-system-analysis-of-middle-earth-shadow-of-war
Substance: A systems analysis noting the Nemesis system intertwines with nearly every other system in the game. The player discovers captains by finding them or by interrogating lesser enemies; each warchief has bodyguards drawn from other captains; when a captain is killed by the player or by a rival captain, another takes its place in the hierarchy. The author notes no other game had implemented the system at this scale.
Relevance: ADAPT. The lesson is architectural: the Nemesis should plug into existing systems (intel, bodyguards, vacancies) rather than sit beside them. One line why: a rival that only appears in its own ambush mission feels bolted on; one that touches intel and fleet composition feels systemic.

**5. Game Developer, "Why Left 4 Dead Works" (AI Director section)**
https://www.gamedeveloper.com/design/why-i-left-4-dead-i-works
Substance: Left 4 Dead's AI Director tracks each survivor's stress level (damage taken, kills nearby, and similar signals) and throttles the enemy population back when stress gets too high, guaranteeing recovery breaks. Levels have no pre-scripted enemy placement; the Director composes spawns, items, and pacing in real time from player state.
Relevance: ADAPT as the adaptation model, not as a rival. Voidsworn's Nemesis "learns from the last battle" should work like a director: read the player's last battle (which weapons, formations, or doctrines they leaned on) and counter that specifically, while also throttling back after a punishing loss. One line why: adaptation that only escalates is a difficulty slider with a face; adaptation that also relents is a director.

Cross-cutting takeaway for priority 1 [Inference, built on sources 1-5]: personal rivals need four visible things: a name and face, a memory the player can inspect, adaptation the player can name ("it brought ion weapons because I leaned on shields last time"), and a counterplay action between battles. Voidsworn already rules the ambush cap (once per sector); the XCOM knowledge-bar pattern is the missing fairness piece, and it fits the sector map naturally.

## Priority 2: Second-in-command succession

**6. Gaming Instincts, "Shadow of Mordor/War - The Nemesis System"**
https://www.gaminginstincts.com/middle-earth-shadow-mordor-whos-nemesis/
Substance: When a warchief is eliminated, the story is not over: the warchief may survive disfigured and return to hunt the player, or a captain is promoted to take the dead chief's place. The author calls the system a hydra: cut off one head and more take its place. Branding (dominating) a captain lets the player install spies and bodyguards who betray their warchief mid-battle.
Relevance: ADOPT the shape. Succession in Mordor is vacancy fill by a known subordinate, not a random respawn. One line why: Voidsworn's "angrier second-in-command" should be a lieutenant the player has already seen, promoted into a visible vacancy.

**7. Twinfinite, "How to Get a Nemesis in Middle-earth: Shadow of War"**
https://twinfinite.net/guides/middle-earth-shadow-of-war-how-get-nemesis/
Substance: Dying to an enemy promotes it to captain status (if it was not already) and buffs it; it is then listed in the captains menu where the player can check its new buffs and weaknesses, interrogate for more intel, track it down, and take revenge to end the feud.
Relevance: ADAPT. The succession beat works because the promotion is announced, inspectable, and reversible by the player. One line why: a successor the player can read about and hunt is a new chapter; one that just appears stronger is a refunded victory.

Succession guidance [Inference, from sources 6 and 7 plus the ruled design]: three rules keep succession from feeling like punishment for winning. First, the successor must be a known quantity (a lieutenant from the Nemesis's fleet, named before the promotion). Second, the successor must differ, not just scale: angrier should mean more aggressive behavior (charges, overextends, favors boarding or ramming) with an exploitable cost, not strictly better stats in every dimension. Third, killing the leader must still pay in full (sector progress, loot or ransom, the flagship path stays open), so the succession reads as a consequence of the world, not a tax on the win. A non-lethal defusal route also helps: Mordor's dominate/shame options let players resolve a rival without killing, and Voidsworn's already-ruled strip-and-ransom capture rule is the same kind of pressure valve.

## Priority 3: Event design for roguelites

**8. FTL Wiki, "Meta:Event Conventions" and "Augmentations" (blue option system)**
https://ftl.fandom.com/wiki/Meta:Event_Conventions
https://ftl.fandom.com/wiki/Augmentations
Substance: FTL's wiki documents blue options as a formal convention: a blue option uses a template and is followed by its requirement in plain text, such as "(Requires level X System)". The Augmentations page lists which augmentations unlock blue options at which events (for example, specific augments gating distinct outcomes at distress calls and stations). Blue options give a no-risk automatic success when the requirement is met, but the requirement itself is the cost: the player paid scrap and an upgrade slot earlier to earn it.
Relevance: ADOPT the convention wholesale. One line why: a blue option that hides its requirement is a guessing game, and one that shows it turns fleet building into event preparation.

**9. Steam FTL discussion, "Blue Events List?" (player strategy thread)**
https://steamcommunity.com/app/212680/discussions/0/611696927924171813/
Substance: Players discuss deliberately upgrading doors, sensors, medbay, and piloting to level 2 early specifically to unlock blue options, and debate the trade-off: that scrap is not going into weapons, shields, or engines, and the strategy has killed many runs. One hard-mode analysis in the same thread works out the economics: of 12 possible civilian distress beacon events, only 2 have medbay-2 blue options, so the investment pays off only across many beacons, not from any single event.
Relevance: ADAPT the economics. One line why: blue options stay balanced when the gate is a real build cost spread across a run, not a free reward for having the right thing once.

**10. Slay the Spire 2 event guides, "Tablet of Truth" and "Crystal Sphere"**
https://gamerblurb.com/articles/slay-the-spire-2-tablet-of-truth-event-guide-best-choice
https://gamerblurb.com/articles/slay-the-spire-2-crystal-sphere-event-guide
Substance: Tablet of Truth offers Decipher (lose 3 Max HP, upgrade a random card) versus Smash (heal 20 HP), and Decipher chains into a repeated commitment: keep deciphering at escalating Max HP costs (3, then 6, 12, 24) for repeated upgrades, with a Give Up exit at each stage. Crystal Sphere offers Uncover Future (pay gold upfront, divine 3 times) versus Payment Plan (take a Debt card, divine 6 times); Debt costs gold every time it is drawn and is expensive to remove, so the extra pulls are rarely worth it unless the run is broke or built around exhaust.
Relevance: ADOPT both templates. One line why: multi-stage commitment with an exit at each step, and a "more pulls at a lingering cost" trade, are the two strongest event shapes for a 20-event deck because the best answer depends on run state, not on memorizing one right pick.

**11. gamedesign.gg, "Roguelike and Roguelite Design: Runs, Variety, and Death as a Teacher"**
https://gamedesign.gg/articles/roguelike-and-roguelite-design/
Substance: Three principles, read in full. First, a fair death (and by extension a fair event outcome) is one the player can reconstruct: they can point to the decision that caused it and form a testable hypothesis; unfairness is about information and readability, not raw difficulty. Second, meaningful choices are ones where you cannot instantly name the best answer (citing Schell); options must be genuinely incomparable, and between-fight decisions (shops priced so you can never buy everything, choice rooms) are the genre's true gameplay. Third, variety comes from combinatorics, not content volume: a small pool of interacting systems out-varies a large inert catalog, and good generation composes hand-vetted chunks under constraints rather than inventing from pure randomness.
Relevance: ADOPT as the design test for all 20 events. One line why: if an event's best option is obvious regardless of fleet state, it is a coin flip or a chore, and adding 20 of those only makes repetition arrive faster.

Quantity versus quality [Inference, from sources 8-11]: 20 events stay distinct when outcomes depend on run state (fleet damage, credits, faction standing, captured hulls, Nemesis status) and when the deck enforces no repeats within a run. A single event skeleton with faction-flavored variants and state-dependent branches will feel fresher than 20 fixed text-and-reward pairs, because the player cannot memorize a fixed answer key. Repetition sets in when outcomes are fixed and the player has seen the answer before; state dependence plus a no-repeat rule is the cheapest defense.

## Priority 4: Faction campaign verbs

**12. Rock Paper Shotgun via GameFAQs mirror, "Here's how the strategy layer works in Menace"**
https://Gamefaqs.gamespot.com/news?id=165614
Substance: Menace (from the Battle Brothers developers) builds its between-battle layer from a small set of actions: pick the next mission, improve squads, handle pop-up story events, appraise standing with each NPC faction, and equip a strike cruiser with auxiliary systems. The strategy layer is described as the bread around the tactical combat: necessary, substantial, but not a second game.
Relevance: ADOPT the menu shape. One line why: Voidsworn's six faction verbs should each be one small action on the sector map (a standing appraisal, a cruiser or fleet upgrade, a mission pick), not a parallel management game.

**13. Story Roll, "How to Run a Space Opera Campaign in a Tabletop RPG"**
https://storyroll.app/blog/how-to-run-a-space-opera-campaign
Substance: A campaign structure in four arcs: contact (meet both rival powers without being forced to choose), entanglement (favors owed and bridges burned quietly raise the cost of staying neutral), escalation (jobs turn out to be symptoms of a larger threat), and finale (accumulated choices decide the aftermath). The load-bearing idea is that neutrality gets more expensive over time, so faction choice emerges from play rather than from a single alignment pick.
Relevance: ADAPT the arc logic. One line why: Voidsworn's faction verbs should make each faction's standing drift with what the player actually does between battles, so the sector 3 flagship fight inherits a history.

**14. Stars Without Number fan-hosted rules summary, "Faction Turn Actions"**
https://wwn.quadrifons.com/6.0%20Factions/Faction%20Turn%20Actions.html
Substance: A tabletop faction system where each faction takes limited actions per turn: Create Asset (buy one asset at a base, capped by the faction's attribute scores), Hide Asset (available only to cunning factions, paying treasure for stealth), and Sell Asset (salvage half the purchase cost, nothing if damaged). Excess assets cost upkeep each turn, so expansion has a carrying cost.
Relevance: ADAPT the constraint pattern. One line why: one faction action per sector, capped by something the player built, with upkeep on overreach, keeps six verbs from becoming six free buffs.

Faction verb leads [Inference, from sources 12-14 plus Voidsworn's ruled faction definers]: each verb should express its faction's existing identity rather than invent a new one. Hegemony's verb should touch synchronized fire or formation (drill, anchor positioning); Chorus's should touch feeding or growth; Ithar's should touch shield charge. Each verb needs a visible cost (credits, a sector action, standing with another faction) and a standing display, per the Menace appraisal pattern. Covert-action style spending against the Nemesis (source 3) doubles as a faction verb if it is faction-flavored: paying one faction for intel on the Nemesis, for example, is both a verb and Nemesis counterplay.

## Priority 5: Anti-patterns and warnings

**15. Techsive, "When Games Are Too Bloated: Shadow of War Case"**
https://techsive.com/when-games-are-too-bloated-shadow-of-war-case/
Substance: Shadow of War's endgame ("Shadow Wars") locked the true ending behind wave after wave of fortress defense missions across regions, turning the loop into a chore; the progression curve was shaped in ways that encouraged spending; and launch microtransactions let players buy orc captains and loot, which undercut the organic rivalry the Nemesis system was built on. Notably, even this critical account treats the Nemesis system itself as the game's star; the failure was the grind wrapped around it.
Relevance: ADOPT as the caution. One line why: the Nemesis loop must stay tight and its payoff must not sit behind repetition, because players will blame the rival system for grind that surrounds it.

Further anti-patterns, with sourcing status marked:
- Win-more rewards (sourced, source 11): rewards that only help already-winning runs create blowouts and feel-bad moments. Blue options and event payouts should enable comebacks or open new lines (a repair, a new hull, a Nemesis intel break), not just pay the strongest fleet more.
- Hidden odds (sourced via secondary synthesis, low weight): a GeekExtreme roundup of Reddit design debates notes FTL's crazy-old-man event shows a 60 percent crew-kill chance up front, and argues that is exactly why it feels fair. https://www.geekextreme.com/game-mechanics-reddit-debates/ Relevance: ADAPT, telegraph every risky event odd or cost before the player commits.
- Choice illusion (sourced, forum discussion, low weight): a Larian forums thread on CRPG choice argues that gating content without a narrative rationale reads as artificial restriction, and that replayability should be a consequence of good flexible design rather than a shortcut achieved by restricting a single playthrough. https://forums.larian.com/ubbthreads.php?ubb=showflat&Number=849537&page=all Relevance: ADAPT, every blue-option gate needs a visible in-fiction reason (the fleet has the gear, the faction owes the favor), not an arbitrary lock.
- The perceived hand (inference, from source 5): once players perceive an adaptive system adjusting against them, tension curdles into distrust. Keep the Nemesis's adaptation readable and its ambush telegraphed (a warning, a territory marker, a scout report) so adaptation reads as a rival thinking, not the game cheating.

## Flagged for live-browser read (top 8, in priority order)

1. https://www.thegamer.com/middle-earth-shadow-of-war-orc-nemesis-system-complete-guide/ - Full promotion chain and memory mechanics; the succession template.
2. http://www.shacknews.com/article/101634/shadow-of-war---nemesis-system-explained - The vacancy-fill anecdote in the author's own run; best single illustration of succession working.
3. https://xcom.fandom.com/wiki/The_Chosen - Knowledge, sabotage, and stronghold mechanics; the closest tactics analogue to Voidsworn's Nemesis.
4. https://www.gamedeveloper.com/design/why-i-left-4-dead-i-works - AI Director stress tracking and throttling; the adaptation model.
5. https://gamedesign.gg/articles/roguelike-and-roguelite-design/ - Fairness as reconstructability, incomparable choices, and variety from combinatorics; the test every event should pass.
6. https://ftl.fandom.com/wiki/Meta:Event_Conventions - Blue option template discipline: requirement shown in plain text.
7. https://gamerblurb.com/articles/slay-the-spire-2-tablet-of-truth-event-guide-best-choice - Multi-stage commitment with an exit at each step; the best event shape found.
8. https://Gamefaqs.gamespot.com/news?id=165614 - Menace strategy layer (RPS article via mirror); campaign verbs in a tactics game from the Battle Brothers team.

## What could NOT be verified or accessed

- No Reddit thread was read in full. Direct text fetch of reddit.com is blocked from this side, and this round's searches surfaced wikis, articles, and forums rather than specific reddit.com threads with verifiable URLs, so no Reddit thread is cited above and none is in the live-read list. A follow-up live-browser search of r/roguelikes and r/gamedesign for nemesis and event-design discussion is still worthwhile, but its URLs are not verified here.
- Succession-specific design writing beyond Mordor's vacancy and promotion chain is thin. Tabletop-style succession conventions (promote the aide at reduced effectiveness, or a one-turn command delay) appeared in search snippets without citable URLs and were excluded rather than asserted.
- The Richard Hartley article on Mordor's Nemesis origins failed to load (the fetch returned unrelated homepage content) and was excluded.
- FTL patterns seen in earlier snippets but not re-verified with a URL this round (the "safe leave option" structure of most events, the Mantis Fugitive exception) are not relied on above.
- Slay the Spire examples here are from Slay the Spire 2 guides, since those were the sources search returned; first-game event numbers were not re-verified this round.
- The Menace article is cited via a GameFAQs mirror of the Rock Paper Shotgun piece; the original RPS URL was not captured.
- The Stars Without Number faction actions are cited via a fan-hosted rules summary, not the official rulebook.
- Quasimorph and Solasta faction-reputation material surfaced only through mirrors of uncertain provenance and was excluded from the source list.
- The WB Nemesis system patent was mentioned in earlier research but was not re-verified this round and is not relied on here.
