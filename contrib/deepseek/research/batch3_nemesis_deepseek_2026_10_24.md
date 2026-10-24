# DeepSeek independent research leg: Nemesis systems, succession, event design, faction hooks (Oct 24, 2026)

Filing note: this is DeepSeek's independent research leg on the batch 3 themes (recurring rivals, succession, blue options and event design, faction campaign verbs, anti-patterns), run blind to the first leg, with DeepThink ON and Search ON, no files granted, no code written, returned through the browser task. The ADOPT/ADAPT/SKIP decisions below are the leg's own. Em dashes in the returned text have been normalized to hyphens; wording is otherwise verbatim. Chair screening is separate.

## (a) RECURRING RIVALS: NEMESIS SYSTEMS, XCOM 2 CHOSEN, ROGUELIKE EQUIVALENTS

FINDING 1 - Shadow of Mordor: persistent memory, revenge, promotion, return.
Source: "Middle-Earth Shadow of Mordor USA," Internet Archive - https://archive.org/details/Middle-Earth_Shadow_of_Mordor_USA#1
SOURCED: The Nemesis system remembers Talion's interactions with enemies and adapts their later behavior; a defeated orc may seek revenge, try to humiliate Talion the same way, and wear scars from the previous fight. The system generates bodyguards, captains, and warchiefs in a hierarchy; captains who beat Talion grow stronger and are promoted. Captains can be permanently killed (usually by a beheading finisher) or return later after a regular kill. Branding lets the player influence the hierarchy from inside.
MY INFERENCE: For a 20-ship fleet game this maps to a compact per-rival "battle record": fleet composition, preferred range band, focus-fire target class, ability timing, and whether the player won by attrition, alpha strike, or boarding.
DECISION: ADOPT - a small, legible memory record per battle is enough to create a named rival with personal stakes at 20-ship scale.
FLAG: The Archive item is a game-description/manual-style source, not a design postmortem.

FINDING 2 - Shadow of War: injury-specific adaptation and "cheat death."
Sources: "Middle-Earth: Shadow Of War - Nemesis System Complete Guide," TheGamer - https://www.thegamer.com/middle-earth-shadow-of-war-orc-nemesis-system-complete-guide/#1 ; "Every Game Should Have Shadow Of Mordor's Nemesis System," TheGamer - https://www.thegamer.com/shadow-of-mordor-nemesis-system-every-game/#threads#1
SOURCED: When an orc cheats death, the system changes it based on injury parameters: new appearance, trait, personality, and voice line; orcs that killed the player multiple times cheat death more often. A defeated-but-not-executed orc may return immune to the bow that shot it; bosses may become immune to stealth if killed from the shadows. Snowball problem: a repeatedly victorious warlord can become immune to practically everything.
MY INFERENCE: The useful mechanic is "adapt to the specific tactic that killed it," not absolute immunity; for fleet combat this should be resistance/accuracy debuffs, never hard immunity.
DECISION: ADAPT - copy "adapt to the specific tactic that killed it" but cap at one adaptation per return and always leave at least two clear counter-tools.
FLAG: "Immune" in Shadow of War is often absolute; verify counters exist before shipping any adaptation.

FINDING 3 - Shadow of War: hierarchy promotion and replacement.
Source: "Core System Analysis of Middle-Earth: Shadow of War," Game Developer - https://www.gamedeveloper.com/design/core-system-analysis-of-middle-earth-shadow-of-war#1
SOURCED: Ranks run captains, veteran captains, warchiefs, overlord; each warchief has bodyguard captains; a killed captain is replaced; orcs level 1-60 by killing the player or completing encounters; a regular orc that kills the player becomes a captain.
MY INFERENCE: The fleet hierarchy can be tiny: Nemesis, second-in-command, two or three named escorts.
DECISION: ADOPT - a tiny named hierarchy is manageable for a small fleet and makes promotion/succession readable.

FINDING 4 - Why the Nemesis system is compelling.
Sources: "Middle-earth: Shadow of Mordor," Wikipedia - https://en.wikipedia.org/w/index.php?title=Middle-earth:_Shadow_of_Mordor&oldid=867537962#2 ; "How the Nemesis system got an indie makeover in Star Renegades," Game Developer - https://www.gamedeveloper.com/design/how-the-nemesis-system-got-an-indie-makeover-in-i-star-renegades-i-#
SOURCED: Monolith wanted NPCs responding to player actions, players creating their own villain, organic story, tension like multiplayer, and death treated as canonical. The Star Renegades piece describes the system as rewarding exploration, research, and manipulation over brute force, with procedurally generated hierarchies that update as the player kills, controls, or loses to them.
MY INFERENCE: The compelling part is player-authored villainy and legible memory, not AI sophistication.
DECISION: ADOPT - invest in presentation and legibility of the memory, not in a deep learning model.

FINDING 5 - Shadow of War: intel and pre-fight counterplay.
Source: "Middle-Earth: Shadow Of War - Nemesis System Complete Guide," TheGamer - https://www.thegamer.com/middle-earth-shadow-of-war-orc-nemesis-system-complete-guide/#1
SOURCED: "Worm" orcs reveal an undiscovered captain's name, level, strengths, and weaknesses; death threats raise a captain's level for a harder fight and better gear; the player can command a recruited captain to become a warchief's bodyguard and betray the warchief.
MY INFERENCE: The sector ambush should never be a blind counter; the player should see the rival's strengths, adaptation, and succession order beforehand.
DECISION: ADOPT - expose the rival's current strengths, adaptation, and succession order before the sector ambush.

FINDING 6 - XCOM 2 Chosen: recurrence and resurrection until the stronghold falls.
Sources: "The Chosen," XCOM Wiki - https://xcom.fandom.com/wiki/The_Chosen?curid=14384&diff=59399&oldid=59398 ; "XCOM 2 War of the Chosen: The Death and Resurrection of The Chosen," Gamepressure - https://www.gamepressure.com/xcom2/the-death-and-resurrection/z3a189#1
SOURCED: A Chosen killed on a mission resurrects at its Citadel and reappears until the Citadel Assault; it can daze, kidnap, and interrogate soldiers and assault the Avenger with enough information. A field kill removes it only for a couple of days; permanent removal requires a Stronghold Assault and destroying the reincarnation crystal.
MY INFERENCE: This is recurrence without meaningful death; the brief's early-kill succession hook is stronger.
DECISION: ADAPT - borrow the "rival keeps returning" pressure but replace resurrection with permanent death plus succession.

FINDING 7 - XCOM 2 Chosen "Knowledge" is a strategic intel clock, not a documented tactical-learning model.
Sources: "XCOM 2," Steam news - https://store.steampowered.com/news/posts/?appids=593380&enddate=1498039137#1 ; "XCOM 2: War of the Chosen abilities, gear, factions, enemies - everything we know," PCGamesN - https://www.pcgamesn.com/xcom-2/xcom-2-war-of-the-chosen-release-date-factions-units-strategy#1 ; "XCOM 2: War of the Chosen," Steam news - https://store.steampowered.com/news/posts/?appids=593380&enddate=1502911636#2
SOURCED: The Chosen hunt "knowledge" by kidnapping/imprisoning soldiers; more knowledge makes them more powerful and lets them find the Avenger. PCGamesN describes them as inspired by the Nemesis system, "morph and react," with a slightly different skill set each encounter. A Steam post calls them Firaxis' take on the Nemesis system, "smart enemies that adapt to your playstyle," but the concrete examples given are fixed abilities/weaknesses (e.g., the Assassin is immune to reaction shots, takes bonus damage from multiple hits in one turn, takes extra damage from Reapers).
MY INFERENCE: Public language says "adapt to playstyle," but the detailed mechanics found are knowledge-gated power growth plus random strengths and fixed weaknesses - not a per-tactic learning model.
DECISION: ADAPT - use a visible intel clock that unlocks the sector ambush and flagship upgrades, but do not claim it "learns tactics" unless the memory is concrete and inspectable.
FLAG: The exact Chosen adaptation algorithm is not publicly documented in the sources found; "adapts to playstyle" reads as developer/marketing framing.

FINDING 8 - XCOM 2 Chosen: strengths grow; weaknesses are fixed and exploitable.
Source: "The Chosen," XCOM Wiki - https://xcom.fandom.com/wiki/The_Chosen?curid=14384&diff=59399&oldid=59398
SOURCED: Each Chosen starts with two strengths and gains more over time (up to five), but always starts with two weaknesses that do not change through the campaign; at least one weakness is tied to a Resistance faction.
MY INFERENCE: Right shape for a fleet rival: fixed, discoverable weaknesses plus one new strength per sector - adaptation stays legible and counterable.
DECISION: ADAPT - use 2 fixed weaknesses plus 1 new strength per sector; avoid the Shadow of War snowball to immunity.
FLAG: Sources differ slightly on exact numbers of strengths/weaknesses.

FINDING 9 - XCOM 2: permanent kill gated behind a stronghold undercuts early-kill consequence.
Source: "XCOM 2 War of the Chosen: The Death and Resurrection of The Chosen," Gamepressure - https://www.gamepressure.com/xcom2/the-death-and-resurrection/z3a189#1
SOURCED: A field kill removes a Chosen only for a few days; permanent removal requires a Stronghold Assault and destroying the reincarnation crystal.
MY INFERENCE: This makes an early kill feel like a delay rather than a victory - exactly what the brief's succession hook should avoid.
DECISION: SKIP - do not copy "field kill is temporary, stronghold kill is permanent."

FINDING 10 - Star Renegades: the closest roguelite analogue.
Sources: "Star Renegades," Wikipedia - https://en.m.wikipedia.org/wiki/Star_Renegades#1 ; "Ranking of Roguelikes #10: Star Renegades," Giant Bomb - https://giantbomb.com/users/12002/articles/ranking-of-roguelikes-10-star-renegades#1 ; "How the Nemesis system got an indie makeover in Star Renegades," Game Developer - https://www.gamedeveloper.com/design/how-the-nemesis-system-got-an-indie-makeover-in-i-star-renegades-i-#
SOURCED: Tactical RPG/roguelite; enemies surviving battles are tracked like the Nemesis system and can gain advantages/disadvantages based on player gameplay. Named elites persist run to run; if they kill the player's team they get stronger and gain abilities (one author built a team specifically to destroy an elite that had killed three of their teams); bosses level up if they defeat the player or can be resurrected if the player defeats them. The hierarchy's strengths/weaknesses intersect with party builds and reward exploration, research, and manipulation.
MY INFERENCE: Compress its cross-run memory into per-sector memory within a single run.
DECISION: ADOPT - best roguelite precedent for named, persistent, mechanically growing rivals.
FLAG: Cross-run persistence does not by itself prove within-run adaptation is fun.

FINDING 11 - Hades: bosses remember narratively, not mechanically.
Source: "Hades," TV Tropes - https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/Hades#4
SOURCED: Bosses defeated in a run return next run, resurrected by Hades; sentient bosses comment on it (Asterius relishes rematches; Megaera acknowledges beating her without mirror upgrades); situational dialogue triggers fire from rare previous-run encounters or unusual deaths.
MY INFERENCE: Hades' memory is characterization and relationship continuity, not tactical adaptation; boss patterns are largely fixed.
DECISION: ADAPT - borrow dialogue callbacks and recurring-boss familiarity; do not treat Hades as a mechanical-learning model.
FLAG: TV Tropes is a secondary fan wiki; dialogue triggers are not a formal adaptive-AI system.

FINDING 12 - Slay the Spire: fixed patterns, no rival memory.
Sources: "Donu and Deca," Slay the Spire Wiki - https://slay-the-spire.fandom.com/wiki/Donu_and_Deca ; "Nemesis," Slay the Spire Wiki - https://slay-the-spire.fandom.com/wiki/Nemesis
SOURCED: Donu always starts with Circle of Power then alternates Beam/Circle of Power; Deca always starts with Beam then alternates Square of Protection/Beam - consistent, predictable patterns. The "Nemesis" is an Act 3 elite with Intangible (damage reduced to 1 on alternate turns) and a probabilistic but constrained move pattern (cannot use Debuff or Scythe twice in a row or Attack three times in a row); its attacks do not increase in power.
MY INFERENCE: Fixed patterns support mastery, not a learning rival.
DECISION: SKIP - excellent for deck-building mastery but does not create an "it remembers me" rival.
FLAG: Slay the Spire's "Nemesis" is just an enemy name, not a rival system.

FINDING 13 - Monster Train: global scaling, not memory.
Source: "Pact Shards," Monster Train Wiki - https://monster-train.fandom.com/wiki/Pact_Shards?diff=9193&oldid=9191
SOURCED: The more Pact Shards the player collects, the harder enemies become; more shards upgrade more enemies before the boss and make the boss stronger with bonus stats, status effects, and abilities; 100 shards unlocks a final battle.
MY INFERENCE: Run-level difficulty scaling punishes engaging with optional systems; it does not create a personal rival.
DECISION: SKIP - global scaling is not memory and can feel like punishment for optional power gains.
FLAG: No Monster Train enemy-memory system was found.

FINDING 14 - Darkest Dungeon II: memory belongs to heroes, not enemies.
Source: "Altar of Hope/The Timeless Wood," Darkest Dungeon Wiki - https://darkestdungeon.wiki.gg/wiki/Altar_of_Hope/The_Timeless_Wood?diff=prev&oldid=21372
SOURCED: Memories are small stat buffs letting a hero persist across runs; heroes with memories reappear at the Crossroads retaining attributes, quirks, and diseases; one Memory slot per Confession Boss defeated, up to five; lost on death or on abandoning a run while not at an Inn.
MY INFERENCE: Persistence is on the player side, not the rival side - not applicable to a Nemesis.
DECISION: SKIP.
FLAG: This is Darkest Dungeon II, not Darkest Dungeon I, whose enemy roster is mostly fixed.

## (b) SECOND-IN-COMMAND SUCCESSION

FINDING 15 - Shadow of War: bodyguard succession is deterministic.
Source: "Uruks," Shadow of War Wiki - https://shadowofwar.fandom.com/wiki/Uruks?direction=prev&oldid=61257
SOURCED: Warchiefs gather bodyguard captains; on a warchief's death, those captains take the warchief's place; if two or more living bodyguards exist, the one with the highest Power becomes the new warchief.
MY INFERENCE: A deterministic "highest-power lieutenant inherits" rule is ideal for a tactics game because the player can plan around it.
DECISION: ADOPT - use a legible succession order based on rank/power and show it in the intel screen.
FLAG: Sources differ - Fandom says the highest-Power bodyguard automatically becomes warchief, while Wikipedia says captains battle each other for the position (possible patch, difficulty, or version difference).

FINDING 16 - Shadow of War: the player can pre-engineer succession.
Sources: "Middle-Earth: Shadow Of War - Nemesis System Complete Guide," TheGamer - https://www.thegamer.com/middle-earth-shadow-of-war-orc-nemesis-system-complete-guide/#1 ; "Middle-earth: Shadow of War," Wikipedia - https://en.wikipedia.org/w/index.php?diff=1135221132#7
SOURCED: Players can recruit a captain serving as a warchief's bodyguard, allowing betrayal; after a warchief's death captains battle for the position and the player unlocks a Nemesis mission to assist followers and ensure promotion.
MY INFERENCE: This is the key to making succession feel like consequence rather than punishment: let the player influence succession before the kill (bribe, recruit, cripple, or expose the second-in-command); the angrier lieutenant inherits by default only if the player does nothing.
DECISION: ADOPT - give the player pre-kill tools to shape succession; the default successor is the angrier lieutenant, but the player should have agency over whether that happens.
FLAG: This is a design translation of Shadow of War's mechanics, not a feature that exists in a fleet game.

FINDING 17 - Dead captains are replaced so the hierarchy never empties.
Source: "Middle-Earth: Shadow Of War - Nemesis System Complete Guide," TheGamer - https://www.thegamer.com/middle-earth-shadow-of-war-orc-nemesis-system-complete-guide/#1
SOURCED: When the player dies, time moves forward and dead captains are replaced; if region slots are taken, orcs challenge captains for spots.
MY INFERENCE: Always fill the Nemesis slot immediately with a named successor inheriting one scar, one adaptation, and one grudge - a vacuum is less interesting than a new named rival.
DECISION: ADAPT - replace the killed Nemesis in the same beat with a named, connected successor rather than a generic respawn.
FLAG: Some replacement behavior is housekeeping spawn logic, not narrative succession.

FINDING 18 - XCOM 2 does not model Chosen succession.
Source: "The Chosen," XCOM Wiki - https://xcom.fandom.com/wiki/The_Chosen?curid=14384&diff=59399&oldid=59398
SOURCED: The Chosen are three individuals; a killed Chosen is resurrected at its Citadel until the Citadel Assault; no lieutenant, bodyguard, or successor promotion is described.
MY INFERENCE: XCOM 2 is not a useful reference for the "angrier second-in-command" pillar; using it would confuse resurrection with succession.
DECISION: SKIP - no Chosen succession mechanic to borrow.
FLAG: Absence of evidence - no source describing a Chosen second-in-command or succession system was found.

FINDING 19 - Assassin's Creed Odyssey: player climbs the mercenary ladder, not enemy lieutenant succession.
Source: "Assassin's Creed Odyssey," Steam news - https://store.steampowered.com/news/posts/?appids=812140&enddate=1538776115#2
SOURCED: A pecking order ranks all mercenaries; killing mercenaries ranked above the player is the only way to climb the ladder; mercenary identities are secret; the player finds clues by killing lower-ranked mercenaries who come for bounties.
MY INFERENCE: This models the player climbing a hierarchy, not a rival's command structure changing after an assassination.
DECISION: SKIP.

SYNTHESIS (leg's inference, built on Findings 15-17): to make succession feel like a consequence rather than punishment for winning: (1) telegraph the succession order before the kill; (2) give the player pre-kill tools to shape succession (intel, covert action, or battlefield objective to recruit, cripple, expose, or discredit the second-in-command), with the angrier lieutenant inheriting by default if the player does nothing; (3) make the successor inherit one specific thing from the dead Nemesis (e.g., its adaptation against long-range missiles, plus a new "vengeance" trait making it more aggressive at close range but less patient at long range); (4) reward the early kill immediately (unique flagship module, sector relief, or morale boost) while changing the long-term problem, not resurrecting the same Nemesis; (5) avoid hard immunity snowballing - cap and rotate adaptations and always leave a clear counter-build; (6) do not use resurrection as the default recurrence model - permanent death plus a new successor is the stronger hook for this brief.

## (c) EVENT DESIGN: BLUE OPTIONS, MEANINGFUL CHOICES, CHAINS

FINDING 20 - FTL blue options are conditional buttons gated on ship build.
Source: "Blue Options," FTL Wiki - https://ftl.fandom.com/wiki/Blue_Options?curid=6058&oldid=73216
SOURCED: Blue Options are choices inside Random Encounters and Events that can be selected only if the ship has the required equipment, crew, or system upgrades; blue options "often have more favorable outcomes than their counterparts." The wiki lists them by requirement: Augmentations (e.g., Long-Ranged Scanners, Engi Med-bot Dispersal), Crew races (Engi, Rock, Slug, Crystal, Lanius), Drones (Anti-Personnel, Beam), and Systems (Sensors, Medbay, Teleporter, Cloaking, Hacking). A blue option can be equivalent to another blue option (e.g., Lifeform Scanner or Sensors-3 for "Rebel ship in nebula"), and some are explicitly inferior to a different blue option.
MY INFERENCE: The blue option is not "a better choice" - it is a visible reward for the build the player already committed to. The fleet equivalent is a ship/system/faction tag on the event: "Boarding doctrine: send marines" appears only with a marine module; "Long-range sensors: scan the derelict first" appears only with a scout squadron. The option should change what resource is spent or what risk is taken, not simply remove the event.
DECISION: ADOPT - blue options are the cleanest way to make 20+ events feel personalized without writing 300 events.
FLAG: The FTL Wiki is a fan wiki; per-event outcomes are community-documented, not developer-sourced.

FINDING 21 - Blue options can be trap options, and an all-blue event breaks the engine.
Sources: "Questions here: an inquiry thread!" Subset Games forum - https://www.subsetgames.com/forum/viewtopic.php?f=11&t=16907#1 ; "Blue Options," FTL Wiki - https://ftl.fandom.com/wiki/Blue_Options?curid=6058&oldid=73216
SOURCED: A forum answer notes that events consisting only of blue options "tend to cause problems" because the event can become unselectable; the FTL Wiki notes some blue options are "inferior" to other blue options in the same event.
MY INFERENCE: Always include a non-blue fallback ("leave," "fight," "pay"), and do not make every blue option strictly the best - give blue options real costs so the choice stays interesting.
DECISION: ADAPT - use blue options as conditional alternatives with real costs, and always include a non-blue exit.
FLAG: The all-blue engine limitation is specific to FTL's event scripting, not a universal rule - but the design lesson (never strand the player) is general.

FINDING 22 - FTL's event structure is linear; "chains" are separate linked events.
Source: "Event Loops," Subset Games forum - https://www.subsetgames.com/forum/viewtopic.php?f=11&t=17113#1
SOURCED: A modder explains that FTL events have to progress in a linear fashion; loops are faked by creating chains of separate linked events.
MY INFERENCE: FTL is not a good model for true multi-stage branching; its chains are sequential events with a carried flag between them.
DECISION: ADAPT - use short linear chains with one carried flag, not deep branching; 20+ events is enough if each chain has 2-3 beats.
FLAG: This is a modding-forum description of FTL's engine, not an official design document.

FINDING 23 - Slay the Spire events are costed trades, not free rewards.
Sources: "Cursed Tome," Slay the Spire Wiki - https://slaythespire.wiki.gg/wiki/Cursed_Tome?diff=prev&oldid=14356 ; "Mind Bloom," Slay the Spire Wiki - https://slay-the-spire.fandom.com/wiki/Mind_Bloom
SOURCED: The Cursed Tome event lets the player leave immediately and lose 0 HP, or continue three times and lose a total of 9 HP to obtain the book; the player can commit to the full HP loss or leave with nothing. Mind Bloom offers [I am War] (fight an Act 1 boss), [I am Awake] (upgrade all cards but obtain Mark of the Bloom, which prohibits healing), and [I am Healthy] (heal to full HP).
MY INFERENCE: The meaningful part is that every option has a different cost in a different currency - HP, a curse, a future prohibition, or a fight. The player is not choosing "good vs. bad"; they are choosing which resource to spend. For the fleet game, event options should trade hull, fuel, intel, a ship module, a future ambush timer, or faction standing - never just "pay 20 credits for +10 reputation."
DECISION: ADOPT - cost every option in a different currency, and make the cost visible before the choice.

FINDING 24 - Sunless Sea storylets are modular, self-contained, and state-aware.
Sources: "Sunless Sea, 80 Days and the rise of modular storytelling," Game Developer - https://www.gamedeveloper.com/design/-i-sunless-sea-i-i-80-days-i-and-the-rise-of-modular-storytelli ; "Monstrosities and Nemeses," Failbetter Games - https://www.failbettergames.com/monstrosities-and-nemeses/
SOURCED: Sunless Sea uses modular storytelling: each island has its own history and events. Failbetter's story engine tracks the first meeting and the choices made; the next time the player encounters the same entity, it remembers.
MY INFERENCE: This is the right production model for a small team: write events as self-contained modules against a small global flag set, so 20+ events stay authorable and combinable.
DECISION: ADOPT - modular storylets with a small global flag set; this is how to get 20+ events with a small team.
FLAG: The Failbetter blog is from 2013 and describes the Fallen London/Sunless Sea engine; specifics may have changed.

FINDING 25 - Crying Suns players explicitly asked for non-deterministic event outcomes.
Source: "Update 46: Crying Suns Roadmap," Kickstarter comment - https://www.kickstarter.com/projects/106952529/crying-suns/posts/2636004
SOURCED: A backer wrote that the most important thing for replayability is to make event outcomes non-deterministic, with multiple branching outcomes so the player cannot simply learn the optimal answer.
MY INFERENCE: This is the clearest statement of the repetition problem: if an event always gives the same outcome, the second run is a solved puzzle, not a choice.
DECISION: ADOPT - build variance into outcomes, not just into option text; otherwise the second run solves every event.
FLAG: This is a single backer's opinion, not a sales or review dataset.

## (d) EVENT DECK SIZE AND DELAYING REPETITION

FINDING 26 - FTL's standard event pool is roughly 320 events.
Source: "Advice on winning hard mode consistently," Steam Community - https://steamcommunity.com/app/212680/discussions/0/558749824086798445/
SOURCED: A player states there are "very roughly 320 events in the standard event pool."
MY INFERENCE: FTL's pool is large because it is a short-run game with many sectors and many repeat runs; a fleet roguelite with 3 sectors and ~20 events per run does not need 320 flat events - it needs 20 core modules with variants and state gates.
DECISION: ADAPT - use 20 core event modules with variants and state gates, not 20 flat unique events.
FLAG: The 320 figure is a player estimate, not an official count; it includes many ship-encounter variants.

FINDING 27 - Slay the Spire has 52 events, with internal no-repeat rules.
Sources: "Slay the Spire - Spire Archive" - https://spire-archive.com/ ; "Events," Slay the Spire Wiki - https://slaythespire.wiki.gg/wiki/Events?diff=prev&oldid=14356 ; "Slay the Spire/Event," Namu Wiki - https://en.namu.wiki/w/%EC%8A%AC%EB%A0%88%EC%9D%B4%20%EB%8D%94%20%EC%8A%A4%ED%8C%8C%EC%9D%B4%EC%96%B4
SOURCED: The Spire Archive lists 52 events. Internally there are three event types: Act Events (common, restricted to an act, repeatable) and others; most events, like relics, cannot be encountered again in the same run once encountered, with some exceptions.
MY INFERENCE: 52 events is enough for Slay the Spire because a run sees maybe 10-15 events and the no-repeat pool keeps them fresh; the same ratio works for a 3-sector fleet run.
DECISION: ADOPT - enforce a per-run no-repeat pool for standard events, and reserve a small separate pool for recurring/chain events.
FLAG: Event counts vary by source and include shrine variants; treat 52 as an order of magnitude, not exact.

FINDING 28 - Crying Suns ships with more than 300 story events.
Source: "Crying Suns," Apple App Store listing - https://apps.apple.com/us/app/crying-suns/id1522331260
SOURCED: The store listing says the game has "More than 300 possible story events" plus a storyline structure.
MY INFERENCE: 300 events is a content-heavy roguelite with a chapter structure - out of scope for a small fleet game's authored spine.
DECISION: SKIP - do not target 300 events; target a small authored spine plus variants.
FLAG: Store listings are marketing copy; the number of events with meaningfully branching outcomes is unverified.

FINDING 29 - Anti-repetition toolkit: variants, flags, per-sector decks, no-repeat pools.
Sources: "Slay the Spire/Event," Namu Wiki - https://en.namu.wiki/w/%EC%8A%AC%EB%A0%88%EC%9D%B4%20%EB%8D%94%20%EC%8A%A4%ED%8C%8C%EC%9D%B4%EC%96%B4 ; "Can the same events reappear in the same expedition?" Steam Community (Worlds Upon The Wind) - https://steamcommunity.com/app/1302830/discussions/0/3824156220925328474/ ; "Update 46: Crying Suns Roadmap," Kickstarter comment - https://www.kickstarter.com/projects/106952529/crying-suns/posts/2636004
SOURCED: In Slay the Spire most events do not recur in the same run (common shrine events are exceptions). In Worlds Upon The Wind, most events can only happen once per expedition, with limited exceptions. The Crying Suns backer argues events need multiple branching outcomes so the player cannot learn the outcome.
MY INFERENCE: The concrete anti-repetition toolkit is: (1) per-run no-repeat pool for most events; (2) per-sector decks so sectors feel distinct; (3) run-flags gating variants and follow-ups; (4) the Nemesis ambush as the one event allowed to repeat - and it is different every time because the rival changed.
DECISION: ADOPT - combine no-repeat pools, per-sector decks, and run-flags; treat the Nemesis ambush as the repetition-breaking device.

## (e) FACTION HOOKS: SMALL CAMPAIGN VERBS

FINDING 30 - XCOM 2 factions grant HQ scan bonuses and Covert Actions.
Sources: "XCOM 2," Steam News - https://store.steampowered.com/news/posts/?feed=steam_community_announcements&appids=268500 ; "Resistance Factions," XCOM Wiki - https://xcom.fandom.com/wiki/Resistance_Factions?veaction=edit&section=1
SOURCED: Finding a faction opens its HQ as a permanent scanning site: Reaper HQ gives a steady increase in intel; Skirmisher HQ gives faster facility construction, and each faction offers Covert Actions - missions that cost a soldier and time and produce strategic resources, recruits, or sabotage.
MY INFERENCE: The faction verb is "spend a scarce slot (soldier/time) on a non-combat action that produces a strategic resource" - directly portable to "spend a ship or intel on a between-battle faction action."
DECISION: ADOPT - each faction gets 2-3 concrete campaign verbs with a cost and a cooldown, plus one passive bonus.
FLAG: XCOM 2's Covert Actions are tied to a monthly refresh and a soldier-allocation system that a fleet roguelite would need to simplify.

FINDING 31 - BattleTech/MechWarrior reputation gives payment and shop modifiers.
Sources: "Factions," BattleTech Wiki - https://battletech.fandom.com/wiki/Factions ; "MechWarrior 5: Mercenaries," Sarna.net - https://www.sarna.net/wiki/MechWarrior_5:_Mercenaries
SOURCED: Reputation effects include a 10% bonus payment and 5% shop discount in systems the faction controls; contract negotiation points are determined by overall Reputation and specific Standing with the hiring faction.
MY INFERENCE: This is the "soft economic" faction hook: the faction does not give you a new button, it modifies existing economic numbers - cheap to implement but invisible unless surfaced.
DECISION: ADAPT - use faction standing to modify existing economic numbers, but pair it with at least one active verb so the faction feels like a choice, not a spreadsheet.
FLAG: BattleTech's exact reputation thresholds and stacking rules vary by source and mod; the percentages are indicative, not exact.

FINDING 32 - Star Traders: Frontiers flows reputation through alliances and gates contracts.
Sources: "Star Traders: Frontiers," Steam News - https://store.steampowered.com/news/posts/?feed=steam_community_announcements&appids=335620 ; "Star Traders: Frontiers," Wikipedia - https://en.wikipedia.org/wiki/Star_Traders:_Frontiers
SOURCED: Positive and negative reputation changes flow through faction alliances (e.g., if Cadar is allied with another faction, gains/losses spill over); captains with a reputation for reliability with a faction receive more jobs from them.
MY INFERENCE: The faction verb here is "choose a side and accept the spillover" - a simple ally/enemy matrix makes every reputation change a strategic decision rather than a free gift.
DECISION: ADOPT - use a simple ally/enemy matrix so reputation changes spill over; this makes faction choice matter on the campaign layer with almost no UI.
FLAG: Star Traders: Frontiers has six factions like the brief, but a much larger economic simulation; the matrix idea ports cleanly, the economy does not.

FINDING 33 - Endless Space 2 minor faction assimilation grants a specific trait.
Sources: "Minor Factions," Endless Space 2 Wiki - https://endless-space-2.fandom.com/wiki/Minor_Factions ; "Endless Space 2 - guide to assimilating minor factions," Rutab.net - https://rutab.net/endless-space-2/guide-to-assimilating-minor-factions.html
SOURCED: Improving relations with a minor faction unlocks higher diplomatic levels that provide more bonuses; assimilating the Mavros gives a bonus to military and technological points, and the player can choose which minor faction traits to adopt.
MY INFERENCE: The faction hook is "assimilate or ally to gain a specific, named modifier" - the key is that the reward is visible before commitment, so the choice is informed.
DECISION: ADOPT - one signature modifier per faction, visible before commitment, so the choice is informed and distinct.
FLAG: Endless Space 2's minor faction system is a 4X diplomacy layer, not a roguelite campaign layer; the reward-visibility principle is what ports.

## (f) ANTI-PATTERNS: WHAT PLAYERS HATED AND WHY

FINDING 34 - XCOM 2 Chosen are hated for interruption and unskippable dialogue.
Sources: "When does War of the Chosen get fun?" Steam Community - https://steamcommunity.com/app/268500/discussions/0/598536819815131874/#1 ; "XCOM 2: War of the Chosen," Steam review - https://steamcommunity.com/id/Robineus/recommended/593380/
SOURCED: A player complains that "every time anything happens, control is taken from me"; a negative review calls the Chosen "really, really irritating" because they "talk alllll the time" with unskippable dialogue.
MY INFERENCE: The anti-pattern is not "a recurring rival" - it is a recurring rival that steals control and airtime. The Nemesis may taunt, but never take control; every line should be skippable and ideally carry information (strengths, adaptation, succession order).
DECISION: ADOPT AS A NEGATIVE CONSTRAINT - taunts are fine, control theft is not; every Nemesis line skippable, every line informative.
FLAG: Steam forum threads are self-selected complaints; they are evidence of a pain point, not a representative survey.

FINDING 35 - Shadow of War's Nemesis system became grindy and repetitive.
Sources: "Comments for 'Shadow Of War's Blade Of Galadriel expansion...'," Rock Paper Shotgun - https://www.rockpapershotgun.com/shadow-of-wars-blade-of-galadriel-expansion-out-today-along-with-fr ; "Shadow of War developers admit microtransactions 'undermined the heart of our game'," Vice - https://www.vice.com/en/article/shadow-of-war-developers-admit-microtransactions-undermined-the-hear
SOURCED: A commenter says the Nemesis system was "grindy as fuck to force MT purchases"; Monolith removed the in-game currency and war chests six months after release, saying they had undermined the heart of the game.
MY INFERENCE: The anti-pattern is repetition of the same personality/trait pool plus a grind treadmill that makes the system feel like a chore - separable from the microtransaction controversy itself.
DECISION: ADAPT - use a small authored trait set for the Nemesis; avoid random cosmetic monologues; keep rival encounters few (once per sector) and meaningful.
FLAG: The microtransaction controversy is specific to Shadow of War's launch; the monotony complaint stands on its own but comes from comment sections, not a systematic study.

FINDING 36 - FTL's unfair events are the ones that kill without warning.
Sources: "too many insta death / insta gib scenarios," Steam Community - https://steamcommunity.com/app/212680/discussions/0/594031066432592842?l=english#1 ; "Losing the game should happen faster," Subset Games forum - https://www.subsetgames.com/forum/viewtopic.php?f=11&t=16537#1
SOURCED: A player describes a random pirate frigate that spawns four units onto the ship and lights fires - effectively an instant loss from one event; another player argues the game can "punish you at will" (e.g., the Engi/Mantis event, warping into an ambush) with no counter-play.
MY INFERENCE: The anti-pattern is a high-variance event with no warning and no counter-play. For a fleet game: no event may destroy a ship without a telegraphed risk and a way to avoid or prepare.
DECISION: ADOPT AS A NEGATIVE CONSTRAINT - telegraph lethal risk in the option text and always offer a way out.
FLAG: FTL's design intentionally includes harsh randomness and some players enjoy it; the brief's game should decide its stance explicitly rather than inherit FTL's.

FINDING 37 - Event fatigue comes from repetition and low-impact rewards.
Source: "Event fatigue," Elder Scrolls Online forums - https://forums.elderscrollsonline.com/en/discussion/672843/event-fatigue
SOURCED: Players describe event fatigue as events feeling like a chore rather than fun, with rewards not worth the interruption.
MY INFERENCE: In a roguelite, fatigue is caused by seeing the same event too often and by events that do not change run state. The fix: state-gated eligibility and every event writing at least one flag or changing run state (a grudge, a debt, a Nemesis adaptation, a faction shift).
DECISION: ADOPT - gate events on state and make every event write at least one flag or change run state.
FLAG: ESO is a live-service MMO, not a roguelite; the fatigue mechanism differs, but the "chore, not fun" dynamic ports.

## CROSS-CUTTING SYNTHESIS FOR THE FLEET GAME (leg's inference from the above)

1. Write 20 core event modules, each with 2-4 options and at least one blue option gated on a ship, system, or faction tag. 2. Always include a non-blue exit; never make an event where the only options are blue. 3. Cost each option in a different currency (hull, fuel, intel, standing, a future ambush timer). 4. Use per-run no-repeat pools for standard events and a separate small pool for recurring/chain events. 5. Gate events on state, not just randomness - a faction event appears only if the player has met that faction; a Nemesis event only if the rivalry flag is set. 6. Faction hooks should be 2-3 active verbs plus one passive modifier per faction, not a wall of stat bonuses. 7. Reputation spills over through a simple ally/enemy matrix. 8. The Nemesis is the repetition-breaking device: the one event allowed to repeat, and it is different each time because the rival changed. 9. No untelegraphed ship-loss events. 10. Keep Nemesis dialogue skippable and informational.

## GLOBAL FLAGS / UNVERIFIED

- The exact XCOM 2 Chosen "adapts to your playstyle" algorithm is undocumented in the sources found; treat it as marketing framing over knowledge-gated power growth plus random strengths/fixed weaknesses.
- Shadow of War sources disagree on succession mechanics (highest-Power bodyguard auto-inherits vs. captains battle for the position).
- No source was found describing a Chosen second-in-command or succession system in XCOM 2.
- Hades' bosses show narrative memory and dialogue callbacks only; no mechanical adaptation source was found.
- FTL's "~320 events" is a player estimate; Slay the Spire's "52 events" varies by source; Crying Suns' "300+ events" is marketing copy.
- Several sources are fan wikis or secondary guides (XCOM Wiki, Shadow of War Wiki, Slay the Spire Wiki, Monster Train Wiki, Darkest Dungeon Wiki, FTL Wiki, TV Tropes, BattleTech Wiki, Endless Space 2 Wiki); they are useful for concrete mechanics but are secondary evidence. Stronger sources used where available: Game Developer articles, Wikipedia, Steam news posts, Failbetter Games blog, Vice, Rock Paper Shotgun.
- XCOM 2 Chosen complaints and Shadow of War grind complaints come from self-selected forum/review posts, not representative samples.
- Nothing in this research required sign-in beyond the pre-existing session; no credentials were used, no account was created, no purchase was made, and no files were attached.
