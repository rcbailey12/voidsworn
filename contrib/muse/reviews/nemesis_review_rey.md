# Job 2: Nemesis faction behaviour review, Rey chair audit

Rey (chair), Oct 26, 2026. Written blind: this audit was produced from the evidence pack alone (evidence_pack_job2.md, job2_portnotes_b4.txt, job2_portnotes_r42.txt, job2_data_nemesis.txt) plus public sources on the comparison systems. The three external legs for this job were not consulted; they run separately.

Scope: the Nemesis's faction behaviour, readability before the fight, fairness (no ship loss without warning, no stolen control), and memory. Repo claims cite the pack file and the constant or section they come from.

## Research findings: what the comparison systems actually do

### Shadow of Mordor and Shadow of War (Monolith)

The patent is the cleanest primary source. US Patent 10,926,179, "Nemesis characters, nemesis forts, social vendettas and followers in computer games", granted to Warner Bros. in February 2021, describes NPCs who interact with the player, remember the interaction, and have that memory change their appearance, their behaviour, and their rank among other NPCs on the next meeting (summary at https://dwo.co.il/the-patent-protection-of-the-nemesis-system-of-the-game-middle-earth-shadow-of-mordor/ ; the patent and its August 2036 expiry are also covered at https://www.gamespot.com/articles/monoliths-shadow-of-mordor-nemesis-system-patent-doesnt-expire-for-another-decade/1100-6529722/?utm_source=gamefaqs&utm_medium=partner&utm_content=news_module&utm_campaign=gamespace_news).

Four behaviours in that system matter for this review:

1. Memory is spoken back. An Uruk who killed you, escaped you, or was scarred by you references that specific event when you meet again, and the one who killed you is promoted for it, with a stat boost and sometimes a changed appearance (https://www.destructoid.com/warner-bros-finally-patents-shadow-of-mordor-nemesis-mechanic-after-multiple-attempts/).
2. Damage becomes identity. Survivors come back with scars, burns or prosthetics that match how they were hurt, so the history is visible on the body before a word is spoken (https://thinglabs.io/warner-bros-first-patented-and-has-now-killed-one-of-gamings-best-innovations-the-nemesis-system).
3. Memory runs both ways. Orcs do not only counter you; they gain fears and hatreds from what you did to them, and they can be promoted or demoted by events that do not involve you at all (https://tech4gamers.com/the-nemesis-system-shadow-of-mordors-patent-issues/). The hierarchy itself is made of named soldiers, each with a name, rank, strengths, weaknesses and personality traits (https://omnigameplayer.com/why-has-no-one-stolen-the-nemesis-system/).
4. Death is not a full stop. Enemies who escape or survive a fight return, and the rivalry is the product: one contemporary account describes a lowly guard who killed the writer being promoted, coming back stronger, and mocking the earlier fight (http://www.richardhartley.com/2015/02/in-shadow-of-mordor-revenge-gets-personal/).

The lesson that transfers: Mordor's memory works because it is narrated, visible on the body, and double-edged. The rival does not only get your counter; he gets a scar, a grudge, sometimes a fear, and he tells you about all of it.

### XCOM 2: War of the Chosen (Firaxis)

The Chosen are the closest structural cousin to Voidsworn's Nemesis: a small set of persistent rivals in a turn-based tactics campaign, explicitly built after Firaxis asked how Mordor's persistent rivalries would work in XCOM (https://www.pcgamer.com/xcom-2s-huge-war-of-the-chosen-expansion-detailed/).

Points that sharpen judgements below:

1. They announce themselves. When a Chosen enters a mission they pause, mock you, and then act; the player is never ambushed by an unmarked super-unit (https://www.sockscap64.com/2017/09/14/%e3%80%90xcom-2%e3%80%91-war-of-the-chosen/).
2. Their strengths and weaknesses are known, so the player plans around them: one write-up describes bringing an extra grenadier to every mission where the Assassin was expected, because her weakness to explosives was on record (https://www.sockscap64.com/2017/09/14/%e3%80%90xcom-2%e3%80%91-war-of-the-chosen/).
3. They grow, and the growth is the campaign clock: they gather Knowledge, including by kidnapping your soldiers off the battlefield, and enough Knowledge escalates to an assault on your base (https://www.pcgamer.com/xcom-2s-huge-war-of-the-chosen-expansion-detailed/). Kidnapped soldiers can be rescued, so even the harshest interaction is recoverable (same source).
4. They taunt with reference to previous battles, and they gain new strengths over time, which forces the player to keep adapting rather than solve them once (https://www.pcgamesn.com/xcom-2/xcom-2-war-of-the-chosen-release-date-factions-units-strategy).

### Warframe: Kuva Liches (Digital Extremes)

The Lich is the comparison that matters for theft. A Lich claims territory and taxes rewards earned there, but everything taken is held and returned in full when the Lich is defeated; the tax is a loan, not a loss (https://wiki.warframe.com/w/Adversary_Weapons). The Lich also has a persistent profile the player can open at any time, showing level and the history of attempts against it, and it is created from the player's own actions, including the weapon element it inherits from the Warframe that made it (https://www.thegamer.com/warframe-liches-grineer-corpus-guide). Its personality is drawn from a small typed pool (jovial, mad, logical, flirtatious) and its influence is drawn on the map as a visible cloud, so the threat is spatially readable before the player commits (https://wiki.warframe.com/w/Kuva_Lich/Gameplay).

## The six faction verdicts

Shared base for all six, from job2_portnotes_b4.txt (Campaign, Nemesis) and job2_portnotes_r42.txt (R42 Nemesis v2, Campaign): the clock (NEM_CLOCK, data_nemesis.txt) fills by 1 per player win, multiplied by beh.clock and rounded to halves in v2; at full, strike fires and an unmet battle or elite node in the last columns becomes his fight (nemNodeIs). He is built with two drawn weaknesses (NEM_WEAK), two traits (NEM_TRAITS), one persona (NEM_PERSONA), and he adapts between sectors against whatever the player used most (NEM_ADAPT). Each time he survives, a scar adds damage (+10% per scar, B4 applyNemesis) and a new epithet (nemScar).

### Corsair: raids and flees

Implemented: beh (data_nemesis.txt, NEM_FAC.corsair) sets flee at flagship hull .35 and strike 'raid'. The raid, from job2_portnotes_r42.txt (nemStrike): at full clock he takes 25% of credits if the player holds 30 or more; otherwise, with 3 or more ships, he cuts out the lowest-hull non-flagship ship under 25% hull. Each raid and each flee adds riches +1, and in battle riches converts into extra cheap hulls placed at the enemy edge (job2_portnotes_r42.txt, Battle: Corsair riches). nemFleeCheck ends the fight as a player win when his flagship is at 35% hull or lower at the enemy turn start.

Verb match: exact. This is the only faction where both ruling verbs have a dedicated mechanic each, and the flee feeds the raid economy, so the two verbs reinforce each other.

Readable before the fight: mostly. The beh.d text states the raid terms and the flee plainly, and the data.js comment on beh says the raid is "always announced on his card first", so the design intends a card surface for it. The flee threshold itself (35%) is a hidden number; a player learns it only by watching him run.

Fairness: this is the one faction with a real fairness exposure. Credit theft is announced, gated (30 credits minimum), and modest at 25%. The ship cut is different: it removes a ship permanently, outside battle, triggered by a clock the player fills by winning fights. The gates soften it (fleet of 3 or more, non-flagship, already under 25% hull), and the card announcement is the warning, but the pack does not establish that the player can act on the warning in time, or that stolen credits come back when he finally dies. Judgement: in spirit this is ship loss without a fight, and it is the closest anything in the pack comes to breaching the R7 constraint. The Warframe comparison shows the accepted fix: theft that is held and fully recoverable on the rival's death reads as pressure, not punishment.

Distinct: yes. Only faction whose fleet grows between fights as a direct result of his own behaviour, and the only one who can be beaten by making him run.

### Deathless: returns once after death

Implemented: beh (NEM_FAC.deathless) sets revive 1, clock .5, strike 'tithe'. nemAfterBattle (job2_portnotes_r42.txt): if his flagship dies with the revive unused, he revives with a scar, and in sector 3 his met counter drops back one so he can be met and killed again; a second sector 3 flagship kill sets dead. The tithe drains 6% of max hull from every player ship (minimum 1). nemNoRout is set for Deathless (job2_portnotes_r42.txt, Battle), so the 35% rout rule never applies to his fleet, and beh.d says he never retreats.

Verb match: exact. "Returns once after death" is implemented literally, one revive, then a real death.

Readable before the fight: yes, if the card shows beh.d: "Killed once, he reassembles and comes back scarred." The half-speed clock is also declared. A player who has read the card is never surprised by the return, which is the right way to do a resurrection.

Fairness: two flags. First, the tithe is map damage against every ship with no fight attached; the spec's "min 1" is ambiguous between 1 point of damage minimum and a floor of 1 hull remaining. If the tithe can kill a ship sitting at low hull, that is ship loss without warning in effect, whatever the card says. The pack does not resolve this; flagged UNSURE below. Second, a revived rival who returns scarred is fine, but his damage also rises 10% per scar, so the "second life" fight is strictly harder; that is declared by the scar system and consistent with Mordor's promoted killers, so it passes.

Distinct: yes. Slowest clock, only fleet-wide strike, only true death gate in sector 3. His fights also cannot end by rout, which makes his battles feel committed in a way no other faction's do.

### Ithar: duels and withdraws

Implemented: beh (NEM_FAC.ithar) sets flee {shields:1, hull:.6}, strike 'duel', fleet 'duel'. The duel fleet, from job2_portnotes_r42.txt (Battle): keep the flagship and the three biggest ships, all elite with +6 aim and +5 crit. nemFleeCheck: when the shield and hull conditions are both met, he and all his capital escorts are marked fled and the player wins. Chair note on the shield condition: the pack's two sources disagree. The port notes spec says every flagship shield at or below .5 with hull at 60% or lower; beh.d describes it as shields all down and hull under 60%. Which threshold the code implements is for Opus to confirm; the player-facing text and the test should be aligned either way.

Verb match: half. Withdraws is exact, and more strongly tuned than the Corsair version (he leaves earlier, at 60% hull, once his shields are gone). Duels is carried by fleet shape and text rather than a duel mechanic: a small elite fleet and beh.d's "picks off your weakest ship", which in code is the generic nemTargetBonus granted by the cruel and cunning personas, not an Ithar mechanic. Nothing in the pack gives the player a duel to accept, refuse or read as a duel, the way the Voidsworn challenge pairs the two flagships.

Readable before the fight: the fleet size is visible the moment the fight opens, so the elite duel reads in play. The withdrawal condition is the least readable trigger in the pack: it is compound (all shields down AND hull at or under 60%), so when he vanishes the player may not know which condition fired, or that shields were part of it.

Fairness: clean. His withdrawal hands the player the win and costs the player nothing.

Distinct: mostly. Smallest fleet, only shield-based flee condition. But see the wording collision noted under Voidsworn: two factions are sold to the player as duellists.

### Chorus: feeds on your losses

Implemented: beh (NEM_FAC.chorus) sets feeds 1 and adaptFast 1, strike 'swarm', fleet 'swarm'. nemFeedLosses (job2_portnotes_r42.txt) adds +1 fed per ship the player loses in ANY battle, called from finishBattle for every battle with player losses, capped at 8; fed multiplies his hull by 1 + .04 per point, capped at +32% (job2_portnotes_r42.txt, Battle). adaptFast means nemAdapt runs after every meeting, not just at sector changes, and his adaptation cap rises with beaten + scars, up to 6.

Verb match: exact, and the boldest reading of any verb in the ruling. He does not feed on your losses to him; he feeds on your losses anywhere in the run. That is the Mordor pattern (the world moves without you) applied to a single rival.

Readable before the fight: the rule is declared in beh.d ("every ship you lose anywhere makes his fleet 4% tougher, up to 32%"), but the pack shows no surface where the player watches fed climb at the moment a ship dies in an unrelated battle. The connection between cause (a frigate lost two sectors ago) and effect (his flagship is tougher now) is exactly the kind of memory that goes invisible if it is only a number on a card the player may not reopen. UNSURE whether any feed moment is surfaced.

Fairness: passes the letter (no theft, no surprise ship loss) but carries a spiral risk the other factions do not: the player who is already losing ships makes the recurring boss stronger, up to a third more hull, while also facing his faster adaptation. It is capped hull only, no damage or numbers growth, so it is a difficulty tax on struggle rather than a death spiral. Judgement: keep, but it needs the visibility fix in the ranked list more than any other behaviour.

Distinct: yes, the most distinct of the six. No other faction's power is a function of the player's whole run.

### Hegemony: reinforces

Implemented: beh (NEM_FAC.hegemony) sets strike 'reinforce' and formation 1. campaign3d.js battleScreen forces the reinforcement event at round 3 of his fights (job2_portnotes_r42.txt). His flagship is the formation anchor (B4 applyNemesis), his faction special adaptation 'formation' extends synchronized fire by one hex (NEM_ADAPT_FAC.hegemony), and his trait pool is the artillery and shields end of the table.

Verb match: exact. Reinforcements arriving mid-fight is the behaviour, not a number wearing the behaviour's name.

Readable before the fight: partially. beh.d says "his fights always bring reinforcements in round 3", so a player who reads the card can plan for a fixed, learnable round. The pack does not say whether the battle itself warns at round 2 or on entry. An unannounced round 3 wave against a player who has spent everything by round 2 is a difficulty spike but not a fairness breach: it costs no permanent asset, and after the first meeting it is known.

Fairness: clean. The one caution is composition: reinforcements plus anchor-synced fire plus the formation special can stack in the same fight; that is a balance question for the sims, not a fairness defect.

Distinct: yes. Only faction that changes the shape of a battle already in progress.

### Voidsworn: challenges

Implemented: beh (NEM_FAC.voidsworn) sets strike 'challenge', clock 1.5, noFlee 1. In battle, dmgMult carries the challenge: his flagship and the player's flagship deal 20% more damage to each other, both ways (job2_portnotes_r42.txt, Battle: dmgMult). nemNoRout applies, so his fleet never routs, and the anchor weakness is excluded from his weakness draws in v2 (job2_portnotes_r42.txt, Campaign: weakness shuffle).

Verb match: exact, and the most elegant of the six. "Challenges" is a mutual, symmetric duel buff: it makes his flagship more dangerous to yours and yours more dangerous to his. The player benefits from the same rule that threatens them.

Readable before the fight: the rule is declared in beh.d. In battle, the pack does not establish that the paired ships are marked as duelling; if the +20% is silent, the player feels fights against him as simply hotter around the flagships. UNSURE on the in-battle surface.

Fairness: the fairest strike in the set, because it is symmetric and steals nothing. The fastest clock (1.5) means he also arrives most often; combined with no rout and no anchor weakness, his meetings are the most committal. That is a difficulty identity, not a fairness problem.

Distinct: yes in mechanism, with one nit: Ithar's beh.d also calls him "A duelist" and Ithar's strike is named 'duel', while Voidsworn's challenge is described as challenging "your flagship to a duel". Two factions claim the duel in player-facing words while doing different things. The mechanics differ (small elite fleet and withdrawal versus flagship pair damage), but the vocabulary should be separated before a player has to.

## Memory: what he remembers vs what the player sees

What he remembers, from the pack:

1. What beat him. nemBeatOf (job2_portnotes_r42.txt) reads the battle usage and picks the dominant kind, weighted (torpedoes x2, rams x3, boarding x3, per the port notes), stored as beat.
2. How you fight overall. finishBattle calls nemLearn with the usage counts and an evasive flag (job2_portnotes_b4.txt); nemAdapt turns the highest count into a counter from NEM_ADAPT.
3. That he survived. nemScar records the cause, adds damage, and picks an unused scar epithet (job2_portnotes_r42.txt); scarList keeps causes plus epithet markers.
4. Run state. Chorus fed, Corsair riches, Deathless revived: all remembered, all change later fights.
5. Persona and identity are fixed at creation and never revised by play.

What the player actually sees of it:

1. One spoken recall. NEM_LINES.again: "Last time you beat me with {beat}. It will not work twice." This is a real Mordor move (the rival names the method), backed by NEM_BEAT_WORD's plain-language nouns. It is also a single template with a single slot, and it is the only place his memory becomes speech. The meet lines are persona flavour (NEM_LINES.meet), not memory; none of them reference anything the player did.
2. The epithet. nemFull() is title + name + epithet, and the epithet changes with each scar (job2_portnotes_r42.txt), with six scar epithets per faction in NEM_FAC. This is the body-carries-the-history channel, and the data.js comment says scars add portrait overlays as well. Good, and visible before the fight, which is where it should be.
3. The adaptation, with an explanation available. NEM_ADAPT entries carry a why string ("you leaned on lances and ion fire", "you rammed and boarded"). If the card or a meeting line shows that string, his adaptation reads as memory with a reason, the single strongest readability device in the pack. The pack never states where the why string is displayed; flagged UNSURE.
4. Visible arithmetic. Corsair riches ships and Chorus fed hull are visible inside his fights as fleet composition and toughness, even if their counters are never shown.

What stays invisible:

1. The seen counts themselves (correctly invisible; they are inputs, not story).
2. The moment of feeding and raiding between fights. No line, no notification is specced in the pack for "your losses fed him" or for the tithe landing.
3. Persona AI. nemProf and nemTargetBonus (job2_portnotes_r42.txt, Battle) change his targeting and weights; persona descriptions in NEM_PERSONA declare the intent ("Finishes crippled ships first"), but nothing tells the player mid-run that a behaviour they just watched was his persona remembering nothing, just being himself. That is fine, persona is character, not memory.
4. Any memory of the player's defeats. He remembers how he lost. He has no line, epithet or state for the time he killed your flagship or routed you; nemAfterBattle receives flagshipDead, but no player-facing recall of it is specced. Mordor's rivals remember their wins loudest of all (promotion for killing you). Here a win for him leaves no narrated trace, which is the largest memory gap in the design as packed.

Structural note, judgement: his memory only ever makes him stronger in your counter. Weaknesses are dealt at creation and never change; he never gains a fear, a trauma or a new weakness from what you did to him. Mordor's memory is double-edged (strengths and fears), and that asymmetry is most of why its rivals feel like people rather than difficulty settings.

## Every-run difference

The identity space is wide. Per faction: 10 pre parts x 10 post parts = 100 name bases, retried to avoid admiral collisions, times 4 titles (NEM_FAC). Persona: 1 of a 4-entry faction pool. Traits: 2 drawn from a 6-entry faction pool by shuffle, so 15 unordered pairs. Weaknesses: 2 of 7 (21 pairs), or 2 of 6 for Voidsworn and Deathless with anchor removed (15 pairs). Portraits: 1 of 6 per faction. Scar epithets: 6 per faction, drawn without reuse. Two consecutive runs producing the same rival (faction aside) is very unlikely, and the combination that matters most to play (weakness pair plus trait pair plus persona) has hundreds of live combinations per faction.

Where it collapses:

1. Faction is not drawn per run from all six: newNemesis takes faction RUN.foes[3] (job2_portnotes_b4.txt), so which rival you get is a function of the run's foe list, and how often each faction appears across runs is set outside this pack (UNSURE).
2. The clock rhythm is faction-fixed. beh.clock (0.5, 1, or 1.5) and NEM_CLOCK 4 give every Corsair the same patience and every Voidsworn the same urgency. Rhythm is half of how a rival feels, and it never varies within a faction.
3. Speech is the thinnest layer. Eight meet lines total, one per persona, and personas overlap heavily across pools: proud appears in five of six faction pools, cruel in five, cunning and patient in four each. A player on their third run has heard most of the meet vocabulary, and the again line is one template.
4. The fight shape is constant: elite fleet, biggest ship is him, name on the flagship, fight arrives by node conversion in the last columns or by strike. Identity varies; the encounter grammar does not.
5. Adaptations converge. There are five generic counters plus one special, chosen by the same highest-count rule with the same tie order (B4: shields, pd, armor, evasion, aim). A player with a settled personal style will be countered the same way every run; the faction wording in NEM_ADAPT_FAC changes the label, not the answer.

## Ranked fixes

1. Narrate state changes at the moment they happen. fed gains, raid and tithe landings, adaptation picks (with the existing why strings), and scar causes should each produce one line on the map or at the next meeting. The data already carries the text; the pack just never shows it being surfaced. Highest value per effort, and it fixes the Chorus readability hole and most of the memory invisibility in one move. (Judgement on priority; the missing surfaces themselves are OBSERVED in the pack.)
2. Make Corsair theft recoverable and the ship cut preventable. Hold stolen credits against his death (the Warframe pattern) and either drop the ship cut or convert it to the same recoverable form (the ship is taken and can be won back in his fight). Until then, guarantee the card warning lands with time to act, since the card announcement is the only thing standing between this mechanic and a no-warning ship loss.
3. Resolve the tithe floor in the spec. State plainly that the Deathless tithe cannot reduce a ship below 1 hull, or exempt ships already at critical hull. One sentence removes the only other possible no-fight ship loss.
4. Give memory a second spoken slot. Add recall lines for his wins (your flagship died, you fled, you lost ships feeding the Chorus) keyed to state he already tracks (flagshipDead, scar causes, fed). One template per faction at minimum; Mordor's rivals are remembered for gloating, and this one currently never does.
5. Let play wound him specifically. After a scar, a small chance to gain a related weakness or fear-style trait (for example a burn scar that leaves him worse against the thing that scarred him) would make memory double-edged like the reference system, and would also widen the every-run difference where it matters most, in the fights.
6. Telegraph the two mid-fight events: a round 2 warning for Hegemony reinforcements, and the flee thresholds for Corsair and Ithar shown on the card as numbers, since both flees hand the player a win they may want to play for.
7. Separate the duel vocabulary. Rename one of the two duel framings (Ithar keeps duelist; Voidsworn's challenge can be framed as judgement or single combat in its own words) so the player-facing text matches the mechanical split the code already has.

## UNSURE list

1. What the player-facing card actually shows. The pack references "his card" once, in a data.js comment about the raid. Whether beh.d, weaknesses, traits, persona, weaknesses revealed state, fed and riches all appear there is not established. Every readability verdict above is conditional on the d texts being shown somewhere before the fight.
2. The B4 spec has a revealed list on RUN.nem, suggesting weaknesses are discovered over time, but the v2 notes never describe a reveal flow. Whether the player knows his weaknesses before the first fight is UNSURE.
3. Whether NEM_ADAPT why strings are displayed anywhere.
4. Whether stolen raid credits or the cut ship are recoverable on his death.
5. Whether the tithe can kill a ship at low hull (the "min 1" ambiguity in job2_portnotes_r42.txt).
6. What strike 'duel' (Ithar) and strike 'swarm' (Chorus) do mechanically. job2_portnotes_r42.txt says only that other strikes "act in battle"; the duel fleet and the swarm archetype are described, but no strike-specific battle effect is specced for either.
7. NEM_LINES is marked as placeholder, to be replaced by the story helper's rival line pools (job2_portnotes_r42.txt, Data). The speech thinness finding is therefore provisional against pools this pack does not contain.
8. How RUN.foes is generated, and therefore how the Nemesis faction is distributed across runs.
9. Whether the Godot port surfaces any of this identically; the pack describes the JS oracle, and the Godot UI surface is out of pack scope.
