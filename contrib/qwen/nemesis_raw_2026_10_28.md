# Qwen blind leg: Nemesis mechanics audit (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (Qwen3.8-Max, both model gates passed; no slider challenge appeared). Em dashes and en dashes normalized to hyphens per house rule; wording otherwise unchanged. Chat: https://chat.qwen.ai/c/4dfcff7c-2a56-4912-8693-43aa61bd72ff. Evidence pack: the Oct 28 battle program Nemesis pack (code slices pinned to main 264f441d). Method notes and screening live outside this file.

# NEMESIS MECHANICS AUDIT - COMMISSIONER'S REPORT

## PROOF OF READING

Sections read:
- EVIDENCE PACK title line and header ("code slices from the shipped browser build, main 264f441d; the Godot port mirrors this design")
- THE COMMISSIONER'S QUESTION (Voidsworn roguelite fleet-tactics; three prior panels listed Nemesis under "not checked")
- CHAIR CENSUS (all verified bullet points: generation, weaknesses, clock, adaptation, survival/escalation, designer rulings of Oct 28 2026, marked fights)
- WHAT TO JUDGE (six numbered questions)
- Code slices: data.js lines 423-562 (NEM_CLOCK, NEM_WEAK, NEM_ADAPT, NEM_TRAITS, NEM_PERSONA, NEM_FAC for all six factions, NEM_ADAPT_FAC, NEM_LINES, NEM_BEAT_WORD, FAC_VERBS, WING_STANCES, WING_PERKS, CAPTAINS, MORE_SHIP_NAMES, FAC_PRICE, FAC_GATES, HULL_VARIANTS) and campaign_run.js lines 247-300 (newNemesis, ensureNemesis, nemGender, nemPr, nemSay, nemFull, nemReveal, nemSignature, nemWarnLine, nemBeh, nemClockAdd, nemStrike, nemNodeIs, nemBattleCfg, nemAdapt, nemAdaptName, nemAdaptDesc, nemAdaptWhy, nemScar, nemAfterBattle)

Overall verdict: A RIVAL.

The system gives the player a named, persistent opponent whose behavior reads their habits back to them, whose weaknesses are discoverable truths rather than arbitrary gates, and whose threat is announced before it lands; it fails in places, but its failures are fixable without redesign.

## FINDINGS

### 1. [FIX] The adaptation cap silently zeroes sector 1, so the Nemesis cannot adapt to anything the player does in the first sector.

READ. The cap formula is Math.max(0,RUN.sector-1), yielding 0 for sector 1. The design document says "ONE capped adaptation per sector," but the code delivers zero adaptations in sector 1, one cumulative by sector 2, two cumulative by sector 3. INFERRED: a player who steamrollers sector 1 with torpedoes faces no point-defense response until sector 2 at the earliest. The "why" text ("you leaned on torpedoes and wings") will then reference a sector the player finished two fights ago, diluting the felt connection between habit and counter. The cap should read RUN.sector if the intent is one adaptation earned per sector completed, or the design doc should say "one adaptation per sector transition."

### 2. [FIX] A player who draws no intel events and never defeats the Nemesis fights him completely blind across the entire run.

READ. Weaknesses are "true from the first meeting" but hidden until nemReveal() fires, which triggers on victory over him ("His captured logs reveal a weakness") or via intel events ("at least six events offer nemIntel"). INFERRED: at the stated 80% loss rate, a large fraction of runs will end in sector 1 or 2 without a single Nemesis victory. If the run's event table also fails to surface an intel event - which is possible since events are drawn, not guaranteed - the player faces a Nemesis with two hidden weaknesses, no adaptation read, and no strategic lever. The information game is fair only if the event table's density guarantees at least one nemIntel opportunity per run, and the pack does not let me verify that guarantee.

### 3. [FIX] The raid strike's "it all comes back when he dies" is stated in design text but the return code is not in the pack.

READ. The strike message says "He holds them; kill him to take them back" and "Kill him and you take her back." The code stores N.loot and N.held. INFERRED: the actual return-on-kill logic must live in the post-battle reward handler, which is not included in these slices. If the return path is bugged or skipped (e.g., the Nemesis dies in a sector where the reward screen takes a different branch), the player permanently loses credits or a ship to a mechanic that was sold as recoverable. This is the single highest-risk "trust the code" gap in the pack.

### 4. [NOTE] The Chorus's adaptFast flag breaks the "one per sector" contract and is not reflected in the design doc's plain-language description.

READ. The census says "ONE capped adaptation per sector." The code gives the Chorus adaptFast:1, and the cap formula adds N.beaten+N.scars when fast is set, meaning the Chorus can adapt after every meeting, not every sector. The faction description does say "adapts after every meeting, not just every sector," so the code is self-consistent, but the top-level design statement is now a lie for one-sixth of runs. INFERRED: a player who reads the design doc and plans around "one counter per sector" will be blindsided by a Chorus that counters them twice in sector 2. The debrief visibility ruling (Oct 28) mitigates this retroactively but not in the moment.

### 5. [NOTE] Adaptation baiting is possible but expensive; the system does not punish it and does not need to.

INFERRED. Because the adaptation reads the whole sector's seen tallies, a player could fight sector 1 exclusively with lances to guarantee a "Reinforced shields" counter, then switch to torpedoes in sector 2. The cost is a full sector of suboptimal loadout play, and the counter only applies to the next sector. This is a legitimate strategic choice, not an exploit. The "why" text naming the habit back to the player actually makes baiting feel clever rather than cheesy. No change needed, but the debrief should surface the adaptation trigger so the player sees their bait was read.

### 6. [NOTE] The weakness pool's clash exclusion is narrow and leaves one thematic contradiction.

READ. The filter excludes anchor when beh.noFlee||beh.revive and excludes a weakness if the Nemesis drew the clashing trait (slow vs swift, board vs boarders, ion vs shielded). INFERRED: this means a Voidsworn Nemesis (noFlee) can never have "A proud flagship" (anchor), which is correct. But the filter only checks three clashes. A Nemesis with the shielded trait can still roll flank (rear-arc damage), which is fine, but a Nemesis with artillery (guns reach further) can roll brawl ("His ships aim 10 worse at targets 2 hexes away or closer"), which is thematically odd for a faction that fields an "Artillery line." Not a mechanical break, but a flavor crack.

### 7. [NOTE] The Hegemony's reinforce strike is the least strategically interesting of the six.

READ. Reinforce means "his fights always bring reinforcements in round 3." Compare: raid creates a resource-recovery quest, tithe creates fleet-wide attrition pressure, duel creates a single-combat focus, challenge creates a flagship showdown, swarm/feeds creates a scaling threat. Reinforce just adds ships mid-fight. INFERRED: it changes the tactical shape of one battle but creates no campaign-level decision. The player cannot prepare for it differently than for any other fight; they just need to burst the flagship before round 3 or handle the extras. It is the one strike that does not alter the player's strategic calculus on the map.

### 8. [NOTE] The clock's faction scaling creates a wide variance in how often the Nemesis actually appears.

READ. Deathless at clock:0.5 needs 8 wins to fill a clock of 4. Voidsworn at clock:1.5 needs roughly 3. INFERRED: at an 80% loss rate, a Deathless Nemesis may never fire a strike in most runs, making him a distant, almost abstract threat. A Voidsworn Nemesis at 1.5x will appear in nearly every run that survives sector 1. This is likely intentional (Deathless is patient, Voidsworn is zealous), but the design should acknowledge that the Deathless Nemesis's strike, tithe, may be a feature most players never experience.

### 9. [NOTE] Scar epithets are drawn from a per-faction pool of six, typed by cause, and are consumed without replacement.

READ. nemScar filters by cause type (fled, burn, wound) and then by "not already used." INFERRED: after two or three scars of the same type, the pool exhausts and the fallback is F.scars.filter(x=>!N.epithets.includes(x)), which could still exhaust if the Nemesis survives many times. In practice, with three sectors and at most one or two flee/revive cycles, this is unlikely to matter, but the code has no graceful degradation if all six epithets are used. A minor edge case.

### 10. [NOTE] The nemWarnLine function only warns when the clock is one step from full; earlier clock progress is silent.

READ. The function returns empty string unless N.clock+(nemBeh().clock||1)<NEM_CLOCK is false. INFERRED: the player sees the Nemesis's existence on the map, but the clock's incremental fill (fight wins, loud choices) produces no visible feedback until the strike is imminent. At an 80% loss rate this may not matter - the player is often dead before the clock fills - but for the 20% who survive, the sudden "your next win fills his clock" warning can feel like an ambush of information rather than of ships. A small persistent clock indicator on the Nemesis card would close this gap.

## EXPLICIT CHECKS

### ADAPTATION

Accuracy of the trigger-to-habit mapping. READ. The five counters map cleanly to their triggers: shields fires on lance and ion use ("you leaned on lances and ion fire"); pd on torpedoes and squadrons ("you leaned on torpedoes and wings"); armor on ramming and boarding ("you rammed and boarded"); evasion on batteries and broadsides ("you leaned on broadsides and batteries"); aim on evaded damage ("you won by staying hard to hit"). The score weights are sensible: ram and board get 4x, evaded gets 3x, lance and ion get 2x, torp gets 2x, battery and broad get 1x. The weighting correctly emphasises the most committal playstyles. I find no mismatch between trigger and "why" text.

Visibility in play. READ (designer ruling) / INFERRED (current state). The Oct 28 ruling states adaptation "will be VISIBLE on the end-of-run debrief so the player can learn and attribute." The code already has nemAdaptWhy returning the "why" string, and nemAdaptName and nemAdaptDesc for faction-flavoured naming. But the pack does not include the debrief rendering code, so I cannot confirm the player sees the adaptation during the sector in which it applies. INFERRED: if the only visibility is the end-of-run debrief, the player experiences the adaptation as an unexplained stat bump ("his ships have 20% more shields") without knowing why until the run is over. The mid-run experience is that of an invisible hand adjusting difficulty. The ruling fixes this, but the fix is not yet in the build the pack audits.

Baiting and dodging. INFERRED. A player can bait by committing to a single weapon type for a sector, guaranteeing a known counter, then switching. This costs a full sector of one-dimensional play and is therefore a legitimate strategic trade, not an exploit. Dodging is not possible: if all five scores are zero, the faction's special adaptation fires (pickA=sp), and if that is also taken, the first un-taken generic adaptation is assigned. The player will always be answered. This is correct design: the Nemesis should never be irrelevant.

### WEAKNESSES AND INTEL

Tracing a run with no intel events. READ. Weaknesses are rolled at run start: two from a pool of seven, with clash exclusions. They are "true from the first meeting." Reveals come from two sources: (a) intel events ("at least six events offer nemIntel"), and (b) defeating the Nemesis in battle ("His captured logs reveal a weakness"). INFERRED: in a run where the player draws no intel events and loses every Nemesis engagement (plausible at 80% loss rate), the weaknesses remain hidden for the entire run. The Nemesis is then a stat-bloated enemy with no exploitable seam. He is not unbeatable - the player can still win through superior force - but the information game that makes him a puzzle collapses into a brute-force check. This is the system's most significant fairness gap. The fix is not more intel events but a guaranteed minimum: at least one nemIntel opportunity per sector in the event table, or a free reveal after the first Nemesis encounter regardless of outcome.

Is the information game fair? INFERRED. It is fair when it fires. Two fixed weaknesses that are true from the first meeting mean the Nemesis is never a moving target; the player who learns "rear-arc damage" can build around it for the rest of the run. The reveal economy (event-gated, victory-gated) creates a genuine incentive to engage with the campaign's event layer rather than skipping to fights. The weakness pool exclusions (no anchor on noFlee/revive factions, no clash with drawn traits) prevent nonsense combinations. The system is fair in structure but fragile in delivery: its fairness depends on the event table's density, which this pack cannot verify.

### CLOCK AND STRIKES

Cadence at 80% loss rate. READ. Clock is 4, filled by wins and loud choices, scaled by faction (0.5x Deathless, 1.5x Voidsworn, 1x others). INFERRED: at an 80% loss rate, the median run probably produces 3-6 fight wins before ending. A 1x clock fills once per run in a good run; a 0.5x Deathless clock may never fill; a 1.5x Voidsworn clock fills in roughly 3 wins, meaning he appears in almost every surviving run. This distribution is appropriate: the Nemesis is a reward for surviving, not a punishment for losing. The player who is already losing never meets him; the player who is winning gets a rival to test them. The "no ambush" guarantee (fights marked on the map, nemNodeIs check, nemWarnLine warning) means the strike is a scheduled escalation, not a surprise.

Proportionality of each strike.

Raid (Corsair). READ. Takes 25% of credits, or a crippled ship if credits < 30 and fleet >= 3. Returned on kill. INFERRED: proportionate. 25% credits is a meaningful setback but not run-ending, and the recovery quest ("kill him to take them back") gives the player agency. The ship-theft branch is harsher but has two guards (credits < 30, ship < 25% hull, fleet >= 3) and is also recoverable.

Tithe (Deathless). READ. Drains 6% hull from every ship, never below 1. INFERRED: proportionate but insidious. At 6% per strike, a fleet of five ships loses 30% of its total hull budget in one event. The "never below 1" floor prevents ship loss, but the cumulative attrition across a long run is real. This is the most "tax-like" strike, but the Deathless's half-speed clock means it fires rarely.

Duel (Ithar). READ. A flagship challenge; the Ithar Nemesis "keeps his range, picks off your most damaged ships." INFERRED: proportionate. It is a focused tactical problem, not a resource drain. The player can prepare by repairing damaged ships before the fight.

Swarm (Chorus). READ. The Chorus "swarms" and "grows from your losses: every ship you lose anywhere makes his fleet 4% tougher (up to 32%)." INFERRED: the strike itself is less defined than the others (the pack does not detail a unique strike effect beyond the swarm fleet archetype), but the feeds mechanic is the real threat. At 80% loss rate, the player is losing ships frequently, and each loss feeds the Chorus. This is the most punishing strike for the intended loss rate, and it is the one I would watch most carefully for death-spiral risk.

Reinforce (Hegemony). READ. "His fights always bring reinforcements in round 3." INFERRED: the least proportionate in the sense of being the least interesting. It adds ships but creates no strategic decision. It is not unfair, but it is flat.

Challenge (Voidsworn). READ. "His flagship charges yours and challenges it to single combat (the two deal 20% more damage to each other; if your flagship falls, he turns on your strongest ship)." INFERRED: proportionate and dramatic. The 1.5x clock means it happens often, and the noFlee flag means the fight is decisive. This is the most "rival-like" strike.

"It all comes back when he dies." READ (design text). The raid strike messages state "He holds them; kill him to take them back" and "Kill him and you take her back." The code stores N.loot and N.held. INFERRED: the return logic is not in the provided slices. The design intent is clear and the data fields exist, but I cannot verify the return path from this pack. This is flagged as Finding 3.

### SIX RIVALS OR ONE

The six packages are genuinely distinct. Comparing behavior, flee/revive, fleet archetype, persona pools, and trait pools:

| Faction | Clock | Flee/Revive | Strike | Fleet | Distinct Mechanic |
|---|---|---|---|---|---|
| Corsair | 1x | Flee at 35% hull, returns with extra ship | Raid | Swarm | Escalating fleet size, resource theft |
| Deathless | 0.5x | No flee, revive once | Tithe | Heavy | Attrition hunt, reassembly |
| Ithar | 1x | Flee at shields gone + 60% hull, returns honed | Duel | Duel (small, elite) | Quality escalation, range control |
| Chorus | 1x | Not specified | Swarm | Swarm | Feeds on player losses, fast adapt |
| Hegemony | 1x | Not specified | Reinforce | Heavy, line | Artillery formation, round-3 reinforcements |
| Voidsworn | 1.5x | No flee | Challenge | Line | Flagship duel, zealot charge |

These are six rivals, not one rival in six skins. The persona pools overlap (cunning, proud, cruel appear in four factions) but the behavioral packages - flee conditions, escalation paths, strike effects, fleet composition, clock speed - are structurally different. A Corsair run plays as a resource-recovery chase; a Deathless run as a slow attrition war; an Ithar run as a duel of quality; a Chorus run as a race against a growing enemy; a Hegemony run as a formation puzzle; a Voidsworn run as a head-on collision.

Ranking (strongest to weakest design):
1. Chorus - the feeds mechanic is the most original; the Nemesis literally grows from your failures, making every loss a double punishment and every victory over him a reclamation.
2. Corsair - the flee-and-return-richer loop creates a genuine campaign arc; raid gives the player a concrete recovery quest.
3. Voidsworn - the 1.5x clock and noFlee create urgency; the challenge strike is the most dramatic.
4. Ithar - the honed-not-bigger escalation is elegant; the duel strike is a clean tactical problem. Slightly lower because the flee condition (shields gone AND hull < 60%) is very specific and may rarely trigger.
5. Deathless - the half-speed clock and revive are atmospheric, but the tithe strike is the most tax-like, and the slow clock means many runs never experience him.
6. Hegemony - the weakest package. Reinforce is the least interesting strike. The artillery line is a good formation mechanic, but the package lacks a unique escalation path: no flee, no revive, no resource interaction, no scaling. "He adapts by drilling his formation tighter" is a flavour line, not a mechanic visible in the code.

Single change to improve Hegemony: give the Hegemony a strike that creates a campaign-level decision, not just a battle-level complication. For example: "Requisition - the Hegemony Nemesis's reinforcements are drawn from a convoy visible on the map; if the player intercepts the convoy before the Nemesis fight, the reinforcements do not arrive." This turns reinforce from a flat "+ships in round 3" into a strategic choice with a visible, answerable counter.

### PERSISTENCE

Fleeing. READ. Corsair flees at 35% flagship hull; Ithar flees when flagship shields are gone on all sides and hull < 60%. Both return escalated: Corsair with an extra ship, Ithar honed (better shields and aim, never bigger). INFERRED: fleeing creates a three-act structure (meet, beat, finish) that gives the Nemesis a story arc within the run. The escalation is proportionate: one extra ship or a stat bump is a real increase but not a wall. The player who beat him once can beat him again, but must adapt. This is rival behaviour.

Scars. READ. Each survival adds a scar with a typed epithet (fled, burn, wound) drawn from a faction pool of six. Portrait overlays accumulate. INFERRED: scars are a visual narrative device. They tell the player "you have hurt this person before" without changing the mechanics. The epithet system ("Krag Tooth the Burned," then "Krag Tooth Broken-Jaw") creates a name that grows across the run. This is story, not tax.

Revival. READ. Deathless revive once; the census notes "the Eclipse Nemesis revives once." INFERRED: revival is the highest-risk persistence mechanic because it can feel like the game is refusing to let the player win. The Deathless's half-speed clock mitigates this: the player who destroys the Deathless early has likely been winning consistently, and one revival is a final test, not a repeated denial. The key constraint is "once." A second revival would cross the line into tax.

Where is the line between rival and tax? INFERRED. The line is: a rival teaches you something and can be beaten with the knowledge you gained; a tax takes from you and gives back only if you jump through a hoop. This system sits on the rival side, with two caveats. First, the Chorus's feeds mechanic ("every ship you lose anywhere makes his fleet 4% tougher, up to 32%") punishes the player for losing in any fight, not just Nemesis fights. At 80% loss rate, this means the Chorus is often buffed by the time the player reaches him, through no fault of the Nemesis engagement. This is the closest the system comes to a tax. Second, the tithe strike's fleet-wide hull drain is a tax in all but name: it takes resources without creating a decision. Both are mitigated by the "announced beforehand" guarantee and the debrief visibility ruling, but they are the two pressure points where the design should be watched.

What ends a Nemesis arc well? INFERRED. The best ending is the one the code already supports: the player kills the Nemesis, recovers any raided loot or held ships, sees the scars and epithets that accumulated, and the debrief names what the run taught. The worst ending is the one the 80% loss rate makes most common: the run ends in defeat, the Nemesis is never killed, and the player sees neither the debrief nor the recovery. The design should ensure that the debrief fires even on defeat, so the 80% who lose still learn what the Nemesis adapted and why.

### CONTRADICTIONS WITH STATED DESIGN INTENT

I checked the code against the three stated commitments: "marked fights," "capped adaptation," and "true weaknesses."

Marked fights. READ. nemNodeIs checks whether a battle node is the Nemesis's; nemWarnLine prints a warning when the clock is about to fill; the design comment states "no ship loss without warning." The code supports this. No contradiction found. The tithe strike drains hull but is announced in nemWarnLine before it fires. The raid strike is announced on the Nemesis's card. No ambush exists in the code.

Capped adaptation. READ with caveat. The cap formula limits adaptations to min(sector-1, 6) (or more for Chorus with adaptFast). The design doc says "ONE capped adaptation per sector." The code delivers zero in sector 1, which is a stricter cap than stated, not a looser one. The Chorus exception is documented in the faction description but not in the top-level design statement. No mechanical contradiction, but a documentation gap (Finding 4).

True weaknesses. READ. Weaknesses are rolled at run start in newNemesis and stored in N.weak. They are never re-rolled or modified. The clash exclusion filter prevents logical contradictions. No code path alters weaknesses after generation. No contradiction.

## NOT CHECKED

The following cannot be judged from this pack:
1. The event table's density and distribution. The pack states "at least six events offer nemIntel" but does not include the event table, its draw weights, or its sector distribution. I cannot verify whether a run is guaranteed to see at least one intel event.
2. The actual return-on-kill logic for raided credits and held ships. The data fields (N.loot, N.held) and the design text exist, but the post-battle reward handler that returns them is not in the slices.
3. The battle resolution code. The pack includes the Nemesis's fleet composition, AI weights, and adaptation stats, but not the battle engine that applies them. I cannot verify that "aim 8 better" or "20% more shields" translates correctly into combat outcomes.
4. The Godot port's fidelity. The pack states "the Godot port mirrors this design" but provides no Godot code. I am judging the browser build only.
5. The debrief UI. The Oct 28 ruling says adaptation will be visible on the debrief, but the debrief rendering code is not in the pack. I am judging the mechanics against the stated intent, as instructed.
6. The story helper's rival line pools. NEM_LINES contains placeholder text ("placeholders until the story helper's rival line pools arrive"). I cannot judge the narrative voice.
7. The map generation code. I cannot verify how often Nemesis-adjacent nodes appear, whether the player can route around them, or how the "last fight before the rest stop" fallback (n.col>=(RUN.map.cols.length-3)) interacts with map shape.
8. Telemetry and balance data. nemSignature logs to telemetry (tel('nem_signature',...)), but no telemetry results are provided. I cannot check actual clock-fill rates, adaptation frequencies, or strike impacts at the 80% loss rate.

## QUESTIONS FOR THE DESIGNER

1. Is the event table guaranteed to surface at least one nemIntel event per run, and if not, what is the intended experience of a player who fights the Nemesis three times without ever learning a weakness? The stakes: without a guaranteed reveal path, the weakness system is invisible to the majority of runs at the 80% loss rate, and the Nemesis is a stat block rather than a puzzle.
2. The Chorus's feeds mechanic scales with every ship the player loses anywhere, not just in Nemesis fights; at the intended 80% loss rate, is there a risk that the Chorus is already at or near the 32% cap by the time the player first meets him, making the encounter feel pre-decided? The stakes: if the player has already lost four ships in sector 1, the Chorus is 16% tougher before the first meeting, and the player may experience this as a punishment for earlier losses rather than as a rival's adaptation.
3. The Hegemony's reinforce strike adds ships in round 3 but creates no campaign-level decision; is there a plan to give the player a way to prevent or reduce the reinforcements (intercepting a convoy, bribing a defector, using the faction verb "Fleet drill"), or is the flat addition intentional? The stakes: if reinforce is the only strike the player cannot prepare for or mitigate, the Hegemony Nemesis reads as a difficulty spike rather than a rival, and the "methodical" persona is undermined by an unanswerable mechanic.
