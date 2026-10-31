# Red team leg: Tactics and roguelike player seat (blind Rey leg, Oct 30, 2026)

Seat: the target customer. I buy tactics roguelikes for decision weight per activation, runs that feel different from each other, and losses that feel earned. Everything below is judged against that. Findings are ranked by what they cost that player. Quotes are exact and under 20 words each.

## Finding 1: The Nemesis learns from you roughly seven times faster than you learn from him, and on the loss path he pays you nothing

OBSERVED. The rival is the run's centerpiece: he adapts between meetings, and the player is supposed to counter-learn his weaknesses. The powered rerun prices both directions. His growth costs the player up to +27.7pp of win rate by sector 3, while the weakness payback is +3.8pp in both measured sectors, and the addendum states it plainly: "At this power no sector shows a significant weakness value." Worse, the intel is not even granted on the path a first-run player is designed to take. The win branch of nemAfterBattle calls nemReveal() ("His captured logs reveal a weakness"), while the loss branch, campaign_run.js:309, returns only: "drove you off. He will remember this." The Oct 29 Q5 ruling (a lost meeting still teaches a weakness) is unbuilt at this pin.
Cost: the feature I would come back for is a one-way ratchet wearing a two-way costume. He visibly adapts and names it; my counterplay is a rumor worth about 4 points. A tactics player does the math after two runs and stops caring about weaknesses entirely, at which point the Nemesis is just a boss with a memory gimmick.

## Finding 2: The campaign layer is untaught by construction, and the generational contract is never stated

OBSERVED. tutorialCheck at ui3d.js:654 returns immediately when there is no battle object: "if(!B||B.showcase||B.over" gates the whole tip system to battle. The map screen nulls the battle object, so routing, patrons, command points, and run structure get zero contextual teaching. The TIPS table (ui3d.js:642-652) is ten battle tips; the first one a new player sees is "Select one of your ships: it has a green ring underneath." Nothing in the opening minutes says runs are generational, loss is the curriculum, or run 1 is near-impossible by design.
Cost: the 80 percent loss rate is a design contract the player never signed. Untaught, it reads as the game being broken or unfair, not as the intended shape. Confirming the firstrun synthesis (ONE SYSTEMIC TEACHING FAILURE) with the code gate in hand. The post-loss "Carried forward" panel pays real rewards, but pays them as currencies; a new player sees a consolation screen, not an inheritance.

## Finding 3: The core verb of the game, activating a ship, is unsafe to click

OBSERVED. From the battle UI synthesis, unrefuted by any leg: "Clicking an out-of-range enemy does not just fire; it attack-moves." The planner picks the destination hex, arrival facing is never previewed, and hover odds are computed from the ship's current hex rather than the arrival hex. Fire-all is the default on that same click, is irreversible, and leaves the ship unable to brace, while the rare admiral Command is the one action that gets a two-tap confirm. Phased activation is the ruled fix (Oct 29) and is not built at this pin, so the shipped game still plays this way.
Cost: decision weight is the product. A tactics player who cannot trust a click stops experimenting, plays the safest line, and blames the interface for every loss the planner's hex choice causes. The information layer is genuinely best in class (per-facing odds, expected damage, kill flags), which makes it worse: the game teaches you to trust the numbers and then fires from a different hex than the numbers described.

## Finding 4: The post-boss regroup, a signature roguelike beat, contains no decision

OBSERVED. The shipyard states its own rate: "Repairs cost 1 credit per 2 hull" (campaign_run.js:183). The chair's sims found the repair-versus-buy tension binds in 0.0 percent of 60,000 modeled regroups, and free healing pre-empts the yard anyway: a 15 percent patch after any won battle, a 40 percent transit patch after a boss, free drydock and field repair nodes. The economy synthesis's shape verdict stands: "the pinch is sector 1 only," after which credits stop being a decision and shopping replaces scarcity. The settled ruling (repair should always beat scrap-and-replace per ship) is not the complaint; the complaint is what it plays like in sequence: the moment the game advertises as a choice among repair, upgrade, and new hulls is bookkeeping with one right answer and several free versions of itself arriving before the bill.
Cost: one of the three beats a roguelike run is built from (fight, choose a route, regroup) is hollow, and the currency that should create late-run tension decorates two of the game's three sectors.

## Finding 5: Difficulty peaks at anonymous sector 2 elites while the bosses are endurance checks

OBSERVED. Wave 3 Monte Carlo, 425 battles inside 60 bot runs: sector 2 elites cost 1.32 ships lost per fight, the highest attrition of any class, and the loop synthesis cites sector 2 elites at a 69.9 percent bot win rate, below the sector 2 boss at 81.5 percent. Bosses run 6.2 to 7.9 rounds at 82 to 92 percent bot win rates: "bosses are long rather than lethal." The plurality of runs in the pooled data end in sector 2 (135 of 400), and the chair's cross-check supports the transition death spiral: exit sector 1 attrited, meet the steepest strength step in the game, die at the boundary.
Cost: I learn to fear a map node type and to relax at the boss. The emotional peaks of a run sit in the wrong chairs, and the wall is placed exactly where a new player's second run goes to die, which reads as a difficulty cliff rather than a curriculum.

## Finding 6: Build variety is paint-deep across three of the four part layers

OBSERVED (claims register, four prongs each). Weapons: DUPLICATES WITH PAINT (4 of 4). Squadrons: DUPLICATES WITH PAINT. Boons: DUPLICATES WITH PAINT (3 of 4). Modules: MOSTLY DISTINCT JOBS with no build layer, the one healthy layer. Only four of six patron cores appear per run (core.js ensurePatrons), which narrows a given run's space further.
Cost: a roguelike lives on runs feeling different. If three of four part types differ by numbers and names, then faction plus admiral carries all the variety the game has, and a veteran player has seen the build space by run 4. That is the loop synthesis's leak point, and from this seat the two findings are the same finding: the loop leaks at run 4 because there is less underneath the parts than the part count promises.

## Finding 7: The boon system taxes the exact behavior roguelikes reward: committing to a build

OBSERVED. The measurements addendum: offers draw zero off-patron fillers while the patron fields 3 or more useful boons, then exactly 1 filler per offer at 4 held and 2 at 5 held, and the favour sweep prices the rarity side as a staircase, about 15pp of Rare-or-better chance at favour tiers 1 and 2 and about 52pp at tier 3, worst for the most invested players. A kit trigger taxes some builds from the first node: a gun-only fleet under Hunger starts with 2 fillers in its first offer.
Cost: deepening a build degrades the slot machine that is supposed to complete it. Late in a run, boon nodes, the campaign's most frequent reward stop, routinely offer filler to the players who engaged most with the system. Combined with Finding 6, the late run's reward texture is the thinnest part of the game, exactly where a roguelike needs its richest draws.

## Finding 8: The swarm faction's identity discount vanishes at the purchase it matters most

OBSERVED. From the economy synthesis findings that stand: "The Chorus carrier at 370 is the most expensive carrier in the game." Chorus small hulls carry the ruled discount (cheaper and weaker across stats, price, and CP); the capstone hull does not. The per-CP spread runs from 45 credits (Chorus frigate) to 100 (Eclipse frigate), so the Chorus player's early game is honestly the cheapest in the game, which makes the 370 carrier a broken promise at the top of the tree.
Cost: a Chorus run is a saving plan aimed at a swarm capstone. Reaching the yard and finding your faction's discount does not apply to the one hull you saved for feels like the game moving the price after you earned the credits. Faction identity should be loudest at the capstone, not absent.

## Finding 9: The AI quietly gets better after your first run and the game never mentions it

OBSERVED. main3d.js:11, in the startup options block: "else if((META.stats&&META.stats.runs)>0) AI_LEVEL='veteran';" From run 2 onward the opponent plays at veteran level unless the player has set the level themselves. The loop synthesis notes the Settings screen exposes the level, so it is discoverable, but nothing announces the change at the moment it happens.
Cost: run 2's fights feel mysteriously harder on top of everything else changing, and a player who reads that jump as personal regression learns the wrong lesson from the loss, in a game whose whole contract is that losses teach true lessons. One line on the run 2 start screen ("the enemy has studied your generation too") would convert a hidden tax into fiction. Unannounced, it is a fairness smell a tactics player will find, because tactics players find these.

## Finding 10: Seven of 33 events still have no free exit, so the map's core decision can be a trap

OBSERVED. The event free-exit eval: 26 of 33 events pass, 7 fail (haven among them). The Oct 28 ruling is that every fight-start event guarantees a free exit; at this pin seven events can still commit the player to a fight or a cost with no walk-away. Routing is the campaign layer's core decision, and it is only a decision if declining is real.
Cost: modest per incident, corrosive in aggregate. A player burned once by a no-exit node stops trusting the map's information and routes defensively, which flattens the risk-taking the event system exists to provoke. The fix is ruled and known; the cost is that it is still live in the build a new player meets today.

## Verdict

Verdict: as the customer, I would respect this game's information layer, fear its sector 2 elites more than its bosses, and quietly stop believing its two biggest promises. The single most important attack: the Nemesis system is a one-way ratchet (Finding 1). He adapts for up to 27.7 points of win rate while your hard-won weakness intel is worth about 4, is statistically indistinguishable from nothing at measurement power, and is not even paid out on the loss path the game is designed to send you down. A roguelike can survive an 80 percent loss rate; it cannot survive its centerpiece learning loop being decorative in one direction and real in the other.

## Not checked

- Human play. Every number in this pack is bot-piloted (the pack's own caveat: an informed human likely sits above the bot at full strength and below it when battered). Whether the sector 2 wall, the boss length, and the Nemesis slope feel the same at a human's hands is untested by anything in the pack.
- The Godot build. The pack describes its migration state but contains no playable Godot evidence; whether phased activation, once built, actually restores click trust is the game's biggest open player question and cannot be judged here.
- Moment-to-moment battle feel: animation, sound, camera, and ship readability in play. The pack's evidence is structural and numerical; nothing here lets this seat judge whether a battle is fun to watch unfold.
- Event text and Nemesis line quality in situ. The eval counts exits; it does not let me judge whether the 33 events are worth reading the second time, which is a real roguelike cost.
- The alternate fleets and mastery perks as run 2 content. The pack states the first threshold is 6 XP and unlocks an alternate fleet; whether that fleet plays differently enough to carry run 2 is asserted, not evidenced.
