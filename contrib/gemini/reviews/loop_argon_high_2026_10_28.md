Gemini (Argon High) blind leg, Oct 28 program item 3 (gameplay loop and retention review). Filed as a single reviews copy per house rule, with this chair header. Em and en dashes in the original normalized to hyphens; wording otherwise verbatim. Method note from the run: fresh Gemini chat, session signed in as rcbailey12@gmail.com (Google AI Pro), 4 Argon selected with Thinking level High, picker button and prompt bar both verified "Argon High" before sending; both files uploaded together with no error tiles; completed in one chat with no retry, no rate limit and no traffic check. Chat: https://gemini.google.com/app/fb7c6e05463bc7b6

1. PROOF OF READING & OVERALL VERDICT

Brief Section Headings (pack.txt):

EVIDENCE PACK

THE COMMISSIONER'S QUESTION

THE GAME IN ONE LINE

THE CORE LOOP AS BUILT

POWER SCALING AS BUILT (including sub-heading IMPORTANT STATE NOTE)

FAILURE AND STAKES AS BUILT

REFERENCE LOOPS

WHAT TO JUDGE

OVERALL VERDICT:
THE LOOP LEAKS - As shipped, the loop is strongest at Run 1 (when all pre-unlocked admirals and Legacy systems are fresh) and weakest at Run 5 (when a fourth statistical loss pays out currency whose main sinks are already unlocked at boot); as designed, the loop is strongest at Run 3 (when first Legacy and Admiral unlocks come online) and weakest at Run 10 (when post-win Heat pays only +10% renown into a depleted unlock pool across maps with only 3 encounter archetypes and 2 node modifiers).

2. FINDINGS (RANKED MOST SEVERE FIRST)

[BLOCKER] Default unlockAll state guts two-thirds of the Renown meta-economy as shipped.

OBSERVED: At boot, the game "grants all LEGACY items and all admirals unless a saved option (unlockAll) is explicitly false". Renown is built to purchase "LEGACY upgrades (12 items: shipyard hull classes, war chests, command points, price cuts)" alongside "admiral unlocks (cost ladder 0/30/45/80 per faction) and hull variants".

INFERRED: Judging the game as currently shipped, a player starts Run 1 with all 24 admirals and all 12 vertical Legacy upgrades already owned. Renown earned across runs can only buy hull variants (which merely "appear in shipyards" and still require in-run credits to acquire), collapsing the primary meta-reward loop before the player fights a single battle.

[BLOCKER] An 83% failure rate with locked difficulty relies on raw stat inflation (as designed) or empty loss screens (as shipped).

OBSERVED: "Measured across 800 simulated runs, about 17% of runs are won" and "deaths cluster at sector bosses and sector transitions". Furthermore, there is "no difficulty selection before the first win: the AI defaults to veteran for returning players".

INFERRED: A typical player will lose 4 to 5 runs before clearing Sector 3. As shipped, losing those runs grants no Legacy power spikes or new admirals to change the outcome. As designed, locking "war chests, command points, price cuts" and "shipyard hull classes" behind renown means early runs fail largely due to missing baseline math rather than tactical mistakes, while late runs risk trivializing early sectors once all 12 items are bought.

[FIX] Post-win Heat creates a closed dead-end economy by rewarding difficulty exclusively with extra Renown.

OBSERVED: "Heat (unlocked by the first win) adds self-imposed hard rules, each worth +10% renown", and there is "no post-win content beyond Heat and completion across factions and admirals".

INFERRED: Judging both as shipped and as designed, Heat fails its long-tail purpose. As shipped, "+10% renown" only accelerates hull variant unlocks because Legacy items and admirals are already granted. As designed, by the time a player wins a run and climbs Heat, they are already exhausting the finite Legacy and admiral pools, meaning higher Heat levels feed a currency that rapidly loses value instead of unlocking new boss phases, story beats, or unique cosmetics.

[FIX] Sector map routing suffers from low encounter and modifier entropy after a handful of runs.

OBSERVED: Map nodes reveal their "archetype (swarm, heavy or carrier), any node modifier (only 2 exist: bounty, veteran)", while non-combat nodes draw from "events (33 in the pool) between fights" across three sectors.

INFERRED: Judging both as shipped and as designed, having only three combat archetypes and two node modifiers means tactical map evaluation solves quickly. Once a player learns how their fleet handles swarm, heavy, and carrier nodes, routing reduces to chasing Core signals rather than adapting to varied combat rules or hazards, and a 33-event pool across three sectors will repeat noticeably by Run 5-10 (though the brief does not state how many events trigger per run).

[FIX] Per-admiral Mastery XP wars against the 24-admiral roster breadth.

OBSERVED: The roster contains "24 admirals, 4 per faction, each with a fixed starting fleet and a doctrine". Post-run meta grants "admiral mastery XP for the admiral who led" across 5 levels to unlock an "alternate starting fleet, a fourth aspect offer, a second Command choice and a veteran flag captain".

INFERRED: Judging both as shipped and as designed, locking the best run-customizers (alternate starting fleets, second Command, 4th aspect) behind individual XP ladders on 24 separate admirals creates anti-synergy. Switching to a new admiral to explore the roster forces the player to give up their unlocked loadout options and play a stripped-down baseline run, while grinding one admiral to Level 5 ignores 95% of the roster.

[FIX] Core Sync vertical upgrades incentivize forcing the same Core builds across runs.

OBSERVED: During a run, "Four of the six cores are in range each run", and across runs "core sync (4 tiers per core) improves that core's protocol offers and eventually grants a starting protocol".

INFERRED: Judging both as shipped and as designed, permanently buffing specific cores' protocol offers and granting free starting protocols makes synced cores mathematically superior to unsynced ones. Because 4 of the 6 cores appear in every run, at least two synced cores will always be available once a player levels a few up, encouraging repetitive build forcing rather than experimental pivoting.

[FIX] Permanent hull and captain loss turns narrow boss victories into sector-transition death spirals.

OBSERVED: Inside a run, "Every hull you lose stays lost, and so does its captain", and across 800 simulated runs, "deaths cluster at sector bosses and sector transitions".

INFERRED: Judging both as shipped and as designed, a player who sacrifices hulls and ranked captains to barely defeat the Sector 1 or Sector 2 flagship is immediately dropped into the next sector's opening nodes with depleted firepower and lost captain perks. Although the flagship aspect "transfers to the next-largest ship if the flagship falls", the fleet's net hull and rank deficit explains why deaths cluster at sector transitions - turning a dramatic boss win into a foregone execution one node later.

[NOTE] The Nemesis clock taxes winning battles while gating permanent resolution behind Sector 3.

OBSERVED: Runs feature a "Nemesis who adapts to your build, gathers strength on a clock advanced by loud choices and wins", and who "can be permanently killed only in sector 3".

INFERRED: Judging both as shipped and as designed, advancing an adaptive enemy's strength clock simply for winning battles ("advanced by loud choices and wins") acts as a hidden penalty on success. Furthermore, because 83% of runs fail and deaths cluster at sector bosses and transitions before Sector 3 concludes, the vast majority of runs experience the Nemesis as an unkillable recurring tax rather than a rival they can permanently defeat (the brief is silent on what rewards, if any, driving off the Nemesis in Sectors 1 or 2 provides).

3. EXPLICIT CHECKS

a. THE HOOK
As built, Voidsworn's "one more run" hook is the combinatorial fleet-drafting puzzle: pairing one of 24 admirals and a transferable flagship aspect with captured enemy prize ships and 4-of-6 Core protocol signals while outmaneuvering an adaptive Nemesis. As currently shipped, the meta-progression hook is decorative: because unlockAll grants all 12 Legacy items and all 24 admirals at boot, the meta loop collapses into slow Mastery/Sync bars and shipyard variant unlocks, forcing retention to ride almost entirely on hex-battle quality. As designed (with unlockAll off), the hook is load-bearing for the first 5-10 runs as players chase renown to unlock admirals (at 30/45/80 costs) and Legacy upgrades to survive the 83% failure rate, before decaying into a decorative stat grind once the player notices that map nodes only ever permute 3 archetypes and 2 modifiers.

b. POWER SCALING
Inside a run, power scaling is visceral and highly plan-able: because nodes reveal their encounter, archetype, modifier, reward label, and Core signal in advance, players can actively route to stack core protocols, budget credits vs. paid rerolls, and weigh capturing prize hulls against stripping wrecks for salvage - combining FTL's legible route tension with BattleTech's salvage incentives. Across runs, however, scaling splits between felt structural options (Admiral Mastery's alternate starting fleets and Core Sync's starting protocols, akin to FTL's ship quests) and blunt stat inflation (12 Legacy upgrades adding war chests, command points, and price cuts). As shipped, unlockAll dumps all Legacy math onto Run 1 so across-run power scaling feels flat until late Mastery/Sync tiers; as designed, Legacy mimics Hades' Mirror, but unlike Slay the Spire's 20-step Ascension ladder or Hades' Pact of Punishment, Voidsworn's Heat only pays "+10% renown" into a finite shop rather than evolving the strategic puzzle.

c. RUN 1 / RUN 5 / RUN 10
At Run 1, the player masters hex positioning, prize capture vs. salvage, and Core signal routing before statistically dying at the Sector 1 boss or Sector 2 transition (given the 17% win rate and default "veteran" AI), with the game asking: "Can you build a synergistic fleet without losing hulls?" At Run 5, the player has statistically endured 4 losses and approaches their first win: as designed, they have unlocked early Legacy boosts (war chests/CP), a 30-renown admiral, and Tier 1-2 Core Syncs, shifting the question to "Which core signals and admiral doctrines break the sector bosses?" - whereas as shipped, Run 5 fails to land because unlockAll already gave away all admirals and Legacy perks at boot, leaving the player with only partial XP bars after four losses. At Run 10, the player has statistically won at least once (unlocking Heat) and neared max Mastery/Sync on a favored setup, prompting the question "Can you conquer Heat rules or master a new faction?" - but Run 10 fails to land both as shipped and as designed because Heat only pays "+10% renown" (useless as shipped, redundant as designed), switching admirals resets Mastery perks to zero, and the map still offers only 3 archetypes, 2 modifiers ("bounty, veteran"), and the same 33 events.

d. THE LEAK
The loop most likely loses a player who genuinely liked the battles at Run 4, immediately after dying in the opening nodes of Sector 2 following a costly Sector 1 boss victory. Having fought hard to beat the Sector 1 flagship but lost a key hull and its promoted captain ("Every hull you lose stays lost, and so does its captain"), the player crosses into Sector 2 crippled right where "deaths cluster at sector bosses and sector transitions" and gets wiped out by a veteran/bounty node or an adapting Nemesis. When the post-run screen appears after this fourth consecutive defeat, as shipped the player sees renown that can only buy shipyard hull variants (since unlockAll gave them all admirals and Legacy items at boot) and an un-incremented Heat menu (still locked behind a first win) - offering zero immediate mechanical hook to justify starting Run 5 against the exact same 3 encounter archetypes.

e. FAILURE'S PAYOFF
A failed Voidsworn run pays out a memorial entry in the "Hall of the Fallen", run stats, renown, admiral mastery XP for the single admiral who led, and core sync progress. As currently shipped, this is not enough to make an 83% failure rate feel like progress: with all 12 Legacy upgrades and 24 admirals already unlocked at boot, a losing player gets only fractional Mastery/Sync progress and hull variants they still have to buy with in-run credits at shipyards. As designed, failure pays adequately across Runs 1-5 by funding Legacy power spikes and 30/45-renown admirals, but unlike Hades - where every death advances narrative arcs, unlocks combinatorial keepsakes, and treats failure as the core progression engine - Voidsworn offers no story progression on death and relies on vertical stat upgrades that stop feeling rewarding once bought.

4. THE ONE CHANGE & PROTECT

THE ONE CHANGE (Ranked):

Disable unlockAll at boot AND convert Heat + Faction Mastery from a closed "+10% renown" loop into an Encounter & Loadout Expansion Ladder.

What to do: First, set unlockAll to false by default so the 0/30/45/80 admiral ladder and Legacy progression actually exist as shipped. Second, make Admiral Mastery share milestone perks per faction (4 admirals per faction) rather than per single admiral so exploring the roster isn't punished. Third, replace Heat's "+10% renown" reward with a structured progression ladder (like Slay the Spire's Ascension) where clearing runs and Heat tiers injects new node modifiers (expanding beyond just "bounty, veteran"), new Nemesis behaviors, and cross-faction starting protocols into the run pool.

Cost: Flipping unlockAll and pooling Mastery XP by faction (6 factions instead of 24 isolated tracks) is low code cost; authoring 4-6 additional node modifiers and re-hooking Heat rewards to content unlocks requires moderate design and balancing work, plus tuning Sector 1 so Run 1 is winnable without mandatory Legacy stat inflation.

PROTECT (Ranked up to 3):

The In-Run Post-Battle Capture & Salvage Chain ("captured prize ships (add, strip or ransom), strip the wrecks for salvage"): This directly connects tactical execution inside hex battles to strategic fleet building between battles, giving Voidsworn the same compelling salvage tension as BattleTech.

Flagship Aspect Inheritance ("transfers to the next-largest ship if the flagship falls") paired with Hull/Captain Permadeath: Keeping lost hulls and captains dead creates high tactical stakes, while transferring the build-defining flagship aspect prevents flagship destruction from causing an instant, anticlimactic Game Over.

4-of-6 Visible Core Signal Routing ("Four of the six cores are in range each run; routing toward a core's signals builds that core's protocols into the fleet"): Showing node rewards and core signals in advance while restricting each run to 4 of the 6 cores ensures players must plan routes strategically and prevents every run from converging on the exact same 6-core build.

5. NOT CHECKED

The brief (pack.txt) does not cover and does not let this review judge:

Hex-battle tactical quality and run duration: How long a single battle or full 3-sector run takes in minutes, and whether turn-by-turn hex combat remains intrinsically engaging across 10+ runs.

Economy and XP pacing math: Exact renown payouts per win/loss, shipyard credit prices, Legacy item costs, protocol drop rates, or how many runs are required to reach Admiral Mastery Level 5 or Core Sync Tier 4.

Mechanical specificity of builds and Heat: What the 24 admiral doctrines, flagship aspects, protocols, hull variants, and Heat rules actually do mechanically inside combat (whether they change playstyles or just add flat percentages).

Pre-Sector-3 Nemesis resolution: What happens when the player encounters the Nemesis in Sectors 1 or 2, what constitutes the "loud choices" that advance its clock, and what rewards (if any) are granted for surviving or winning early Nemesis fights before it can be permanently killed in Sector 3.

Root cause of sector-transition deaths: Whether deaths cluster at sector transitions due to lack of automatic post-boss hull repairs, sudden enemy stat jumps, or snowballed CP deficits from Sector 1/2 boss losses (noted as measured separately in program item 4).

6. QUESTIONS FOR THE DESIGNER

Should a skilled player be able to win Run 1 with zero Legacy upgrades, or is Run 1 intended to be a statistical loss until Legacy stats are bought? (If Run 1 should be winnable by skill, Legacy upgrades like extra Command Points, war chests, and price cuts should be redesigned into horizontal flexibility - like shop rerolls or salvage conversion - so they neither gate early wins nor trivialize late runs.)

At Run 10, do you want the player going wide (winning once with all 24 admirals) or going deep (climbing Heat on 1-2 favorite admirals)? (Currently, locking Mastery unlocks to individual admirals punishes going wide, while Heat only paying "+10% renown" fails to reward going deep.)

When a player beats a sector boss at the cost of half their fleet, what is the intended Sector 2/3 experience? (Because lost hulls and captains stay lost and deaths cluster at sector transitions, a human designer must decide whether to add a post-boss recovery safety net - such as free transition hull patching or distress-beacon recruits when below a minimum CP threshold - or keep pyrrhic boss wins nearly fatal.)
