# Nemesis faction behaviour review, Qwen leg (brief muse_2026-10-26c, Job 2)

Model: Qwen web chat, Qwen3.8-Max, two-gate verified (selector showed Qwen3.8-Max before submit; chat header still showed Qwen3.8-Max after generation started), Oct 26, 2026. The pack was pasted inline in three parts (Qwen has no usable file attachment in this setup and reported no live web access; its claims about other games are from training knowledge and are marked as such by the model). Filed verbatim below.

---

# Job 2 Review: Nemesis Faction Behaviour (Blind Leg)

## Preamble on sources

I do not have live web access in this session. All claims about Shadow of Mordor, Shadow of War, Hades, XCOM 2: War of the Chosen, and Warframe are from training knowledge and marked as such. I will cite the patent number and known talk titles but cannot verify URLs resolve today. All claims about the Voidsworn implementation cite the pack files and constant names directly.

## 1. Research Findings

### Shadow of Mordor / Shadow of War Nemesis System (Monolith / Warner Bros.)

The core reference. From knowledge:

The Nemesis system generates named orc captains with procedural names, titles, visual traits, and personality-driven behaviour. Each captain remembers encounters with the player. If the player "dies" (is defeated) at the hands of a captain, that captain gains a power, a new trait, and a promotion in Sauron's army hierarchy. If the player kills a captain but the captain was marked with a "cheat death" trait, the captain can return scarred, burned, or maimed, with a new weakness and a taunt referencing the prior encounter. (From knowledge: US Patent 9,289,684 B2, "Nemesis System", filed 2015, granted 2016, assigned to Warner Bros. Interactive Entertainment. The patent describes persistent NPC memory, trait mutation on encounter outcomes, and hierarchical promotion.)

Key design pillars relevant to this review:

- Memory is always surfaced in dialogue. A returning captain says "You burned me last time" or "I remember your blade." The player is never left guessing whether the game tracked the encounter. (From knowledge: Monolith GDC 2015 talk, "The Nemesis System: Creating Dynamic Villains in Shadow of Mordor", presented by Michael de Plater and others.)
- Traits and weaknesses are visible on the captain's intel card before the fight. The player can scout, learn a captain's immunities and vulnerabilities, and plan. This pre-fight readability is a deliberate fairness layer.
- Cheat death is not silent. The captain visibly staggers, the screen acknowledges it, and the captain returns with a visible scar and a new trait. The player knows the kill did not stick.
- The system generates rivalry through repeated encounters with escalating stakes, not through a single scripted boss fight.

Shadow of War (2017) extended this with betrayal events, online conquest (your captains invade other players' games), and more granular memory (captains reference specific weapons used, specific locations, and specific humiliations). The "again" taunt in the Voidsworn data echoes this directly.

### XCOM 2: War of the Chosen (Firaxis, 2017)

The Chosen are three persistent enemies (Assassin, Hunter, Warlock) who appear on missions, taunt the player with specific references to prior encounters, retreat when hurt, and grow stronger between appearances. They kidnap soldiers. They have strengths and weaknesses that the player learns over multiple encounters. (From knowledge: Firaxis developer updates and the War of the Chosen design overview on the 2K community site, 2017.)

Relevant here: the Chosen's retreat is always visible and narrated. The player sees them teleport away and hears a line. Their power-ups between missions are shown on the strategy layer (a "Chosen" panel with their current abilities). Nothing is invisible.

### Warframe: Kuva Liches (Digital Extremes, 2019)

Procedurally generated enemies tied to a specific player. They remember encounters, level up when you fail to kill them, gain resistances to the weapon type you used, and taunt you with generated lines. You must discover their weakness (a specific Kuva weapon element) through a trial-and-error process. (From knowledge: Digital Extremes Devstream 131 and 134, and the in-game Codex entries.)

Relevant here: the resistance gain is surfaced immediately ("The Lich now resists your Torid"). The player is never left wondering why the same weapon stopped working.

### Hades (Supergiant Games, 2020)

Not a rival system per se, but a memory system. Every NPC tracks prior interactions and changes dialogue accordingly. The player always hears the acknowledgement. No state change is silent. (From knowledge: Supergiant's GDC 2021 talk by Greg Kasavin, "Building the World of Hades".)

### Summary of design principles from the reference systems

1. Memory must be spoken or shown, not just tracked.
2. Pre-fight readability of strengths, weaknesses, and behaviour is a fairness requirement.
3. Returns from death or retreat are narrated events, not silent state resets.
4. Adaptation to the player's tactics is surfaced as a named, visible change.

## 2. Six Faction Verdicts

### 2.1 Corsair: "raids and flees"

Implemented behaviour.

Strike (raid): port_notes_r42.txt, nemStrike section. When the clock fills, the Corsair takes 25% of credits if the player has 30 or more; otherwise, with 3+ ships, cuts out the lowest-hull non-flagship ship under 25% hull. Data: NEM_FAC.corsair.beh.strike = 'raid'. Each raid also increments riches by 1.

Flee: port_notes_r42.txt, nemFleeCheck. At the enemy turn start, if the Corsair flagship hull is at or below 35%, he and his escorts flee. B.nemFled is set, checkEnd fires, and the player wins. Data: NEM_FAC.corsair.beh.flee = {hull:.35}. Riches increment on flee as well (nemAfterBattle, fled branch). Each riches level adds one cheapHull ship at edgeHex('enemy') in the next fight (applyNemesis, port_notes_r42.txt battle section).

Match to ruling verbs. "Raids" is fully implemented as a map-level resource strike. "Flees" is fully implemented as a mid-battle withdrawal at a hull threshold. Both verbs have matching mechanics, not just text.

Pre-fight readability. The beh.d text in NEM_FAC.corsair describes the raid and the flee. The pack comment on beh says "always announced on his card first" for the raid. However, the pack does not establish where this card is displayed or whether the Godot port surfaces it before the battle loads. The 35% flee threshold is a hidden number. The player learns it only by seeing him flee. The riches count (how many extra ships he will bring) is tracked in RUN.nem.riches but the pack does not establish that the player sees this number before the fight.

Fairness. The raid takes credits or a crippled ship (under 25% hull), never a healthy ship. The pack says it is announced on his card. The flee is a win for the player, not a loss. No control is stolen. This is fair.

Distinctness. No other faction steals resources on the map or flees at a hull threshold to return with more ships. The Corsair loop (fight, he flees, he comes back with an extra ship, repeat) is unique among the six. Distinct in play.

### 2.2 Deathless: "returns once after death"

Implemented behaviour.

Revive: port_notes_r42.txt, nemAfterBattle. If the flagship is destroyed and beh.revive is set and the Deathless has not yet been revived, he is marked revived, gains a scar, and in sector 3 his met value drops back one so he can appear again. Data: NEM_FAC.deathless.beh.revive = 1.

No rout: port_notes_r42.txt, battle section. B.nemNoRout applies to Voidsworn and Deathless. The 35% rout rule never triggers for him. He never flees.

Clock at half speed: NEM_FAC.deathless.beh.clock = .5. nemClockAdd multiplies gains by this. He appears half as often.

Strike (tithe): when his clock fills, every player ship loses 6% max hull, minimum 1. Data: beh.strike = 'tithe'.

Match to ruling verbs. "Returns once after death" is implemented via the revive flag. The "once" constraint is enforced by the revived boolean. The verb has a full mechanic.

Pre-fight readability. The player must know he comes back. The pack does not establish that the revive is telegraphed before the first fight. The epithet and scar change after the revive, but that is after the fact. The beh.d text says "Killed once, he reassembles and comes back scarred," but again, the pack does not confirm the player reads this before engaging. The no-rout behaviour is invisible until the player notices he does not break at 35%.

Fairness. The tithe (6% hull to every ship) is a map-level drain. It is not a ship loss and not a control steal, but it is a fleet-wide punishment. If it is not announced before it happens, it could feel like a hidden tax. The pack says the raid strike is "always announced on his card first" but does not explicitly say the same for tithe. UNSURE whether tithe is pre-announced.

The revive means the player must beat him twice. If the player is not warned, destroying the flagship and then being told "he is back" could feel like a stolen kill. The reference systems (Shadow of Mordor, XCOM Chosen) always narrate the return. The pack does not establish a narration moment for the revive.

Distinctness. No other faction returns from death. The half-speed clock and the no-rout behaviour reinforce a "slow, inevitable, unkillable" feel that is distinct from the other five. Distinct in play.

### 2.3 Ithar: "duels and withdraws"

Implemented behaviour.

Duel fleet: port_notes_r42.txt, applyNemesis. The Ithar fleet is pruned to the flagship and the three biggest ships. All are elite with +6 aim and +5 crit. Data: NEM_FAC.ithar.beh.fleet = 'duel'.

Withdraw: port_notes_r42.txt, nemFleeCheck. Ithar flees when "every flagship shield <= .5 and hull <= 60%". Data: NEM_FAC.ithar.beh.flee = {shields:1, hull:.6}. The beh.d text says "once his flagship's shields are all down and its hull is under 60%."

Match to ruling verbs. "Duels" is implemented as a small elite fleet composition. "Withdraws" is implemented as a conditional flee. Both verbs have mechanics.

Pre-fight readability. The duel fleet is visible in the battle setup (fewer ships, all elite). The withdraw condition is a hidden threshold. The player sees him leave but does not know the exact shield and hull triggers beforehand.

Fairness. The withdrawal is a win for the player. The duel fleet is small and fair. No control is stolen. However, I note a possible text-to-implementation mismatch. The beh.d says "shields are all down" (implying zero shields), but the battle spec says "shield <= .5" (50% or below). The data field shields:1 is ambiguous: it could mean "check shields, threshold 1" or "shields must be fully gone." This needs clarification. If the implementation threshold is 0.5 but the description says "all down," the player reading the description will expect a different trigger than what fires. UNSURE which is canonical.

Distinctness. The small elite fleet, the shield-and-hull withdrawal condition, and the duel framing are unique. No other faction fields exactly four elite ships and leaves based on shield state. Distinct in play.

### 2.4 Chorus: "feeds on your losses"

Implemented behaviour.

Feeding: port_notes_r42.txt, nemFeedLosses. Called from finishBattle for every battle where the player loses ships. Chorus fed increases by n, capped at 8. In applyNemesis, Chorus flagship hull is multiplied by (1 + .04 x fed), max 1.32. Data: NEM_FAC.chorus.beh.feeds = 1.

Fast adaptation: NEM_FAC.chorus.beh.adaptFast = 1. nemAfterBattle calls nemAdapt after every meeting, not just at sector boundaries. Adaptation cap is sector-1 plus beaten plus scars, max 6 (port_notes_r42.txt, nemAdapt).

Strike (swarm): beh.strike = 'swarm'. The pack says "other strikes act in battle," so the swarm strike is the fight itself.

Match to ruling verbs. "Feeds on your losses" is implemented as a hull scaling tied to player ship losses in any battle, not just Chorus battles. The verb has a full mechanic. The fast adaptation reinforces the "grows from you" fantasy.

Pre-fight readability. This is the weakest faction on readability. The fed counter is a number in RUN.nem.fed. The pack does not establish that the player sees this number, sees the hull increase, or is told "your losses in that last fight made the Chorus stronger." The adaptation after every meeting is also invisible unless the adaptation name is displayed. The NEM_ADAPT_FAC.chorus entries have names ("Membrane bloom", "Spore curtains", etc.) but the pack does not confirm these are shown to the player.

Fairness. The feeding punishes the player for losing ships in unrelated fights. If the player loses a ship to a random encounter and then meets the Chorus with 4% more hull and no explanation, that is a hidden punishment. The fairness constraint says no ship loss without warning. The Chorus does not cause ship loss directly, but the invisible power gain from the player's losses elsewhere could feel like a hidden difficulty spike. This is the one faction where the fairness case depends entirely on whether the feeding is surfaced. UNSURE.

Distinctness. No other faction scales from player losses in other fights. The fast adaptation rate is also unique. Distinct in play, but only if the player notices the scaling.

### 2.5 Hegemony: "reinforces"

Implemented behaviour.

Reinforcement: port_notes_r42.txt, campaign section. "Hegemony Nemesis fights force the reinforcement event at round 3." Data: NEM_FAC.hegemony.beh.strike = 'reinforce', beh.formation = 1.

Fleet: 'heavy'. An artillery line around his flagship. The formation special (NEM_ADAPT_FAC.hegemony.special) extends the sync radius by 1 hex.

Match to ruling verbs. "Reinforces" is implemented as a timed mid-battle reinforcement at round 3. The verb has a mechanic. The formation identity supports it.

Pre-fight readability. The reinforcement at round 3 is a fixed, predictable event. If the player has fought the Hegemony Nemesis before (or reads the beh.d text), they know it is coming. However, the pack does not establish that "round 3 reinforcements" is displayed before the battle. The first time, it would be a surprise. After that, it is known.

Fairness. A reinforcement at a fixed round is predictable and planable. The player can burst the flagship before round 3 or prepare for the additions. No control is stolen. This is fair, provided the round number is consistent (it is: always round 3).

Distinctness. No other faction brings mid-battle reinforcements on a fixed timer. The formation and artillery identity reinforce a "structured military" feel. Distinct in play.

### 2.6 Voidsworn: "challenges"

Implemented behaviour.

Challenge: port_notes_r42.txt, battle section, dmgMult. "challenge (+.2 between his flagship and your pflag ship, both ways)." Data: NEM_FAC.voidsworn.beh.strike = 'challenge'.

Fast clock: beh.clock = 1.5. He appears sooner than other factions.

No flee, no rout: beh.noFlee = 1. B.nemNoRout applies. He never retreats.

Anchor weakness removed: port_notes_r42.txt, newNemesis. "anchor removed for Voidsworn and Deathless." He cannot be broken by killing his flagship's escorts.

Fleet: 'line'. Zeal trait pool. Personas favour zealous and cruel.

Match to ruling verbs. "Challenges" is implemented as a mutual damage bonus between the two flagships. The verb has a mechanic. The no-flee, fast-clock, aggressive package supports the "zealot who demands a duel" fantasy.

Pre-fight readability. The +20% mutual damage is a hidden number. The player sees bigger damage numbers in the fight but may not know why. The pack does not establish that "his flagship and yours deal 20% more damage to each other" is displayed before the battle. The no-flee behaviour is invisible until the player notices he does not rout.

Fairness. The mutual damage bonus is symmetric. Both flagships hit harder. No control is stolen. The fast clock means he appears more often, which is a pressure but not unfair. The no-flee means the player must finish him, which is a fair demand. This is fair.

Distinctness. The mutual flagship duel bonus, the fast clock, the no-flee, and the removal of the anchor weakness together create a "must-kill, gets-in-your-face zealot" that is distinct from the other five. Distinct in play.

## 3. Memory System Judgement

### What he remembers (state tracked in RUN.nem)

From port_notes_b4.txt and port_notes_r42.txt:

- beat: the weapon kind that last beat him (lance, torp, sq, battery, ram, board, ion, broad, evaded). Set by nemBeatOf(usage) in nemAfterBattle.
- scars: a count, plus scarList with causes and epithet markers. Incremented by nemScar(cause).
- adaptations: a list of counters picked by nemAdapt. Tracked by seen usage counts.
- met: the sector where he last met the player.
- fed (Chorus), riches (Corsair), revived (Deathless): per-faction state.
- dead, beaten, clock, strike, flags: campaign state.

### What the player sees of it

- The "again" line: NEM_LINES.again = 'Last time you beat me with {beat}. It will not work twice.' This is the strongest memory surface. It names the specific weapon. It fires at the start of a repeat battle (applyNemesis, port_notes_r42.txt: "A log line with his taunt (or the 'again' line if he has been beaten before).").
- Persona meet lines: NEM_LINES.meet, one per persona. These fire on first meeting. They are flavour, not memory.
- Epithets: nemScar picks an unused epithet from the faction's scars list. The epithet is part of nemFull() (title + name + epithet). If the player sees the full name, they see the epithet change. The pack does not establish where nemFull() is displayed (battle screen, campaign card, intel panel). UNSURE.
- Adaptations: NEM_ADAPT_FAC has names and descriptions for each counter ("Stolen shield cells", "Quantum ward", etc.). Whether these are shown to the player before or during the fight is not established in the pack. UNSURE.

### What stays invisible

- The fed counter (Chorus). It changes hull by up to 32%. The player fights a tougher fleet and may not know why. No line says "I fed on your dead at sector 2."
- The riches counter (Corsair). It adds ships. The player sees more ships but may not connect them to prior raids or flees.
- The seen usage table. It drives nemAdapt, but the player is not told "he noticed you use torpedoes." The adaptation name might hint at it ("Chaff launchers" implies torpedo defence) but the causal link is not stated.
- The clock value. NEM_CLOCK = 4. The player does not know how close the Nemesis is to striking. The beh comment says the raid is "always announced on his card first," but the pack does not establish a visible clock or progress bar.
- The revive state (Deathless). Before the first kill, the player does not know he will come back. After the revive, the scar and epithet change, but the pack does not establish a narration moment ("He reassembles!").
- The challenge damage bonus (Voidsworn). It is a flat +20% with no UI callout described in the pack.

### Verdict on memory

The {beat} line is the one clear, player-facing memory moment. It is good. It names the weapon. It is in the Nemesis's voice. It fires at the right time.

Everything else is either behind an epithet change (which requires the player to notice and compare names) or entirely invisible (fed, riches, clock, seen usage, revive foreknowledge). Compared to Shadow of Mordor, where every trait gain, every cheat-death, and every adaptation is narrated and shown on an intel card, this implementation tracks more than it reveals. The memory is real but largely silent.

Judgement: the memory system needs at minimum two or three more surfaces where state is spoken or shown. The {beat} line alone is not enough for the player to feel "he remembers me."

## 4. Every-Run Difference

### Variation space

- Faction: 6 options. Determined by RUN.foes[3], which is itself a draw from the campaign setup. The player does not choose the Nemesis faction.
- Name: 10 pre-parts x 10 post-parts per faction = 100 name combinations per faction, 600 total. Retry logic (up to 12) avoids collisions with admiral names.
- Title: 4 per faction.
- Persona: 8 total, but each faction pool has 4. Effective choice per run: 1 of 4.
- Traits: 14 total, faction pool of 6, pick 2. Combinations per faction: 6 choose 2 = 15.
- Weaknesses: 7 total (6 for Voidsworn and Deathless, since anchor is removed). Pick 2. Combinations: 21 (or 15 for the two restricted factions).
- Portrait: 6 per faction (nem_faction_1 through nem_faction_6).
- Epithet: starts empty, gains one per scar. 6 scar epithets per faction.
- Clock rhythm: 0.5 (Deathless), 1 (four factions), 1.5 (Voidsworn).
- Adaptations: 5 counters plus 1 faction special. Order and selection depend on player behaviour.

### Total combinatorial space (per faction, rough)

4 (persona) x 15 (traits) x 21 (weaknesses) x 100 (name) x 4 (title) x 6 (portrait) = 604,800 combinations per faction, before adaptations and epithets. Across 6 factions, roughly 3.6 million distinct Nemesis identities. This is wide.

### Where consecutive runs feel the same

- The clock threshold is always 4 (modified by the clock multiplier, but the base is fixed). The rhythm of "win four fights, he shows up" is the same shape every run, just faster or slower.
- The "again" line is a single template: 'Last time you beat me with {beat}. It will not work twice.' After a few runs, the player will recognise the structure even if {beat} changes.
- The meet lines are one per persona (8 total). After eight runs, the player has heard them all. There is no variation within a persona's meet line.
- The battle flow is the same: he appears at a node, you fight his fleet, you win or lose. The faction mechanics change the texture but not the shape. It is always "go to node, fight fleet, resolve."
- Adaptations are drawn from a fixed table of 5 plus 1 special. After a few runs, the player will see "Reinforced shields" or its faction equivalent repeatedly. The names change by faction but the effect is the same.
- The weaknesses are 7 fixed entries. After a few runs, "Thin stern plating" and "Brittle shield emitters" will recur.

### Verdict on every-run difference

The identity variation (name, face, traits, weaknesses, persona) is wide enough that two consecutive runs will almost certainly produce a different-feeling Nemesis. The player will meet a different name, a different portrait, a different pair of traits, and a different pair of weaknesses.

However, the structural loop is fixed. The clock fills, he appears, you fight, he adapts or flees or revives based on faction. After three or four runs, the player will recognise the loop even if the skin changes. The meet lines and the "again" line will start to repeat. The adaptation effects will feel familiar.

This is acceptable for a roguelike structure. The reference systems (Shadow of Mordor, XCOM Chosen) also have fixed loops with variable skins. The risk is not that runs feel identical but that the Nemesis feels like a system the player is solving rather than a character they are fighting. The persona lines and the {beat} line help, but they are thin.

## 5. Ranked Fixes

### Fix 1 (highest priority): Surface the invisible state

The fed counter, the riches count, the clock value, and the challenge damage bonus are all tracked but never shown. At minimum:

- Show the Chorus fed count on the Nemesis card or in a pre-battle line: "It has fed on N of your lost ships. Its hull is X% thicker."
- Show the Corsair riches count as visible extra ships in the pre-battle fleet preview, with a note: "He brings N plundered hulls."
- Show the clock as a pips or a progress indicator on the campaign map, so the player knows how close the Nemesis is to striking.
- Show the Voidsworn challenge as a pre-battle note: "He challenges your flagship. Both deal 20% more damage to each other."

This is the single biggest gap versus the reference systems. Shadow of Mordor, XCOM, and Warframe all show the state. This implementation tracks it silently.

### Fix 2: Narrate the Deathless revive before it happens

The player should know before the first fight that the Deathless comes back. Options: a line in the meet taunt ("Kill me and I will return"), a note on the Nemesis card, or a faction intel entry. Without this, the first revive feels like a stolen kill. The reference systems always narrate cheat-death.

### Fix 3: Add a second "again" line template per persona

The current "again" line is one template for all personas. After two or three runs, it will feel canned. Adding one or two variants per persona (16 to 24 total) would keep the memory feeling personal. This is a content fix, not a system fix.

### Fix 4: Clarify the Ithar flee threshold

The beh.d text says "shields are all down" but the battle spec says "shield <= .5". These do not match. Pick one and align the text and the code. If the threshold is 0.5 (50%), the description should say "shields below half." If the threshold is 0 (all down), the battle spec should say <= 0. This is a small fix but it affects whether the player can predict the withdrawal.

### Fix 5: Show adaptation causes

When nemAdapt picks a counter, the player should see not just the adaptation name but the cause. NEM_ADAPT already has a "why" field ("you leaned on lances and ion fire"). This should be displayed: "He adapted: Reinforced shields, because you leaned on lances and ion fire." Without the why, the adaptation feels arbitrary.

### Fix 6: Vary the meet lines by sector or by scar count

Currently, each persona has one meet line. After the first meeting, the "again" line takes over. But if the player has not beaten him, the meet line fires again with no change. Adding a conditional variant for "met before but not beaten" would close this gap. For example, the patient persona could say "I have waited longer than your kind has lived" on first meet and "You return. I have not moved." on second meet without a beat.

### Fix 7 (lowest priority): Add one or two portrait variations per scar

The pack mentions "scars add overlays" in the data.js comment. If implemented, this is good. If not, it should be. A visual scar that matches the epithet ("the Burned" gets a burn overlay) makes the memory visible without words.

## 6. UNSURE List

Items the pack does not establish:

1. UNSURE: Where the Nemesis card is displayed and what it shows. The beh comment says the raid is "always announced on his card first." The pack does not define this card, its location in the UI, or whether the Godot port implements it. Without this, I cannot confirm pre-fight readability for any faction.
2. UNSURE: Whether the Godot port surfaces any of the NEM_FAC beh.d text to the player. The descriptions are rich and informative. If they appear in an intel screen or a pre-battle briefing, readability is much better than if they are data-only. The pack does not say.
3. UNSURE: Whether the epithet change is visible to the player. nemFull() returns title + name + epithet. If this is displayed on the battle screen, the player sees "Reaver-king Kragtooth the Burned" and can notice when "the Burned" changes to "Ironjaw." If it is only in a log, the player will miss it.
4. UNSURE: Whether the Chorus fed hull bonus is visible in the pre-battle fleet preview. If the player can see enemy hull values before the fight, the 4%-per-fed increase is readable. If not, it is invisible.
5. UNSURE: Whether the Hegemony reinforcement at round 3 is announced before the battle or only occurs in battle. A pre-battle note ("reinforcements at round 3") would make this fair. The pack does not confirm one way or the other.
6. UNSURE: Whether the Ithar shield flee threshold is 0 (all down, per beh.d) or 0.5 (half, per the battle spec). The data field flee:{shields:1} is ambiguous. This affects whether the player can predict the withdrawal.
7. UNSURE: Whether the Deathless tithe (6% hull drain) is pre-announced on the Nemesis card, as the raid is. The pack explicitly says the raid is announced. It does not say the same for tithe.
8. UNSURE: Whether nemFeedLosses is called for all player losses or only losses in battles against the Chorus. The pack says "called from finishBattle for every battle with player losses," which implies all battles, but this is a design question worth confirming. If the Chorus grows from losses in unrelated fights, the player needs to be told.
9. UNSURE: Whether the B4-to-R42 save upgrade (ensureNemesis) preserves the player's prior knowledge of the Nemesis. If a player saves under B4 and loads under R42, do they keep their met state, their beat memory, and their adaptations? The pack says ensureNemesis "keeps clock, weaknesses, adaptations" but does not mention beat, scars, or met.
10. UNSURE: How the portrait system works in the Godot port. The pack says 6 portraits per faction (nem_faction_1 through nem_faction_6) and that scars add overlays. Whether these assets exist and are displayed is not in the pack.

End of review. Filed as one message, blind, per commission.
