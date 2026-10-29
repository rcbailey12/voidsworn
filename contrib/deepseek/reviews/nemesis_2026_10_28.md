# DeepSeek blind leg: Nemesis mechanics audit (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (DeepSeek, DeepThink ON + Search ON, verified by toggling; first chat hung with no output for about 14 minutes, one fresh chat used per protocol). Em dashes normalized to hyphens per house rule; wording otherwise unchanged. The model's thinking trace is not model reply text and is excluded. Chat: https://chat.deepseek.com/a/chat/s/e64dfc32-ee38-4ab2-b199-1181c69ce0b5. Evidence pack: the Oct 28 battle program Nemesis pack (code slices pinned to main 264f441d). Method notes and screening live outside this file.

## 1. Proof of reading

I read the EVIDENCE PACK title line; THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE; and the code slices "data.js 423-562: Nemesis B4 and R42 v2" and "campaign_run.js 247-300: newNemesis, clock, strike" (including newNemesis, ensureNemesis, gender/pronoun helpers, nemReveal, nemSignature, nemWarnLine, nemClockAdd, nemStrike, nemNodeIs, nemBattleCfg, nemAdapt, nemScar, and the partial nemAfterBattle).

Overall verdict: A RIVAL - the code builds six faction-specific commanders with fixed weaknesses, habit-read capped adaptations, announced clock pressure, and persistent flee/revive/scar state; the main defects are information drought and raid-warning edge cases, not the absence of a rival.

## 2. Findings, ranked most severe first

### [BLOCKER] Raid can remove a ship on a clock fill before the marked "next fight," and the warning is not guaranteed for loud-event fills.

READ/INFERRED. nemClockAdd calls nemStrike() immediately when the clock fills; nemStrike raid removes a crippled non-flagship if credits are under 30. The warning helper only says "Your next win fills his clock," so an event-driven fill can skip that warning. This conflicts with "no ship loss without warning" and "always announced on his card first." Fix: delay ship seizure to the next marked Nemesis fight or require a pre-commit warning for every fill source.

### [BLOCKER] A player who draws no intel events and loses Nemesis fights may never learn either fixed weakness.

READ/INFERRED. Weaknesses are hidden; nemReveal() is called after a win: "His captured logs reveal a weakness." At the intended 80% loss rate, a player may rarely or never beat him, so two fixed truths remain unanswerable. The event economy is not shown to have pity or a guaranteed first-meeting reveal. Fix: reveal one weakness on first meeting or first loss, or guarantee intel access.

### [FIX] Four faction "strikes" have no branch in the shown strike code.

READ. nemStrike() handles only raid and tithe; duel, reinforce, swarm, and challenge return no strike effect in this slice. If they are implemented in battle code, the pack does not show it; if not, four faction signatures are labels. This directly weakens the "six rivals" claim.

### [FIX] "It all comes back when he dies" is unverified for raid.

READ/INFERRED. N.loot and N.held are set, and the text says "kill him to take them back," but the pack shows no death handler returning credits or the held ship. At 80% loss rate, if the player never kills him, stolen assets are a permanent tax. Fix: show and test the death-return path.

### [FIX] Escape and feed escalation can compound against a losing player.

READ. Corsair "comes back richer, with an extra ship each time"; Chorus gains "4% tougher (up to 32%)" from player losses and "adapts after every meeting." At an 80% loss rate, the player's losses feed the Nemesis while the Nemesis's escapes grow him. Fix: cap extra ships, and add a player-side catch-up or decay when he flees repeatedly.

### [FIX] The adaptation cap does not literally match "ONE capped adaptation per sector."

READ. cap=Math.max(0,RUN.sector-1) is cumulative, so a normal Nemesis can have two adaptations by sector 3, and Chorus's adaptFast adds more after meetings. This may be intended, but the census wording and code should be reconciled in UI and design text.

### [NOTE] Adaptation is deterministic and baitable.

READ/INFERRED. The score weights are explicit: shields from lances/ion, PD from torpedoes/wings, armor from ram/boarding, evasion from batteries/broadsides, aim from evaded play. A player can lean into a habit to force a known counter, then switch. That makes adaptation answerable, but also gameable; if baiting is not intended, add noise or tie-breakers.

### [NOTE] In-play visibility is stat-only until the debrief.

READ. nemBattleCfg passes adapt, but no in-battle UI is shown. The designer ruling says adaptation will be visible on the end-of-run debrief, so this is acceptable against that intent, but the player may feel the stat change without attributing it until run end.

### [NOTE] Hegemony is the weakest faction package as designed.

READ/INFERRED. Its signature is a fixed round-3 reinforcement plus line formation; it has no flee/revive and the least narrative escalation. The single change that would most improve it: make its reinforcement package scale with meetings or clock, so Hegemony's "methodical" identity compounds instead of firing once.

### [NOTE] Weakness-pool exclusions are sensible but shrink variety.

READ. anchor is excluded for noFlee/revive, and clash traits remove slow/board/ion when the opposite strength is present. This prevents cancelling pairs, but reduces the seven-weakness pool in some rolls. No fix required unless the observed pool is too narrow.

## 3. Explicit checks

### ADAPTATION

The trigger is real: nemAdapt reads N.seen and scores lances/ion, torpedoes/wings, ram/boarding, batteries/broadsides, and evaded play. The why text matches those counters, so the counter-read is accurate. Visibility is incomplete in play: the battle config carries adapt, but the shown UI does not; the designer ruling moves attribution to the end-of-run debrief. A player can deliberately bait: the highest positive score wins, so leaning on lances can force "Reinforced shields," then switching habits can force another counter later. A player can dodge by avoiding scored habits, but then the faction special or first remaining adaptation may fire. The cap is real, but cumulative (sector-1) and Chorus-fast, not literally one per sector. Verdict: real and answerable, but more deterministic than adaptive.

### WEAKNESSES AND INTEL

Two fixed weaknesses are rolled at run start and are true from first meeting; weakPool excludes anchor for no-flee/revive commanders and cancels strength/weakness pairs. Hidden until revealed. nemReveal() reveals one after a win; events can also offer nemIntel. Trace with no intel events: if the player beats him, first win reveals one weakness, second win reveals the other. If the player loses at the intended 80% rate, no reveal occurs, and the Nemesis remains an unknown fixed stat block. That is not a fair information game for a losing player: fixed truths are not answerable if the only reliable reveal is winning. The event economy may save it, but the pack does not show frequency or pity. Verdict: unfair in the no-intel, losing branch.

### CLOCK AND STRIKES

Clock is 4; fills from wins and loud choices; faction speed is 0.5 for Deathless, 1.5 for Voidsworn, 1 otherwise. The next Nemesis fight is marked via N.strike and nemNodeIs, and nemWarnLine warns before a win that would fill the clock. But nemStrike() executes raid/tithe immediately on fill, not at the marked fight. Raid: 25% credits if at least 30, otherwise a crippled non-flagship if fleet size is at least 3 and hull under 25%; the ship is held. Proportionality at 80% loss rate: the clock fills slowly for losing players, so strikes are rarer; credit theft is economic, not lethal; ship seizure is the harsh branch and has the warning gap in finding 1. Tithe: 6% hull from every ship, never below 1; chip damage, unavoidable but announced, and less severe than ship loss. Duel/reinforce/swarm/challenge are not implemented in nemStrike; only their descriptions exist, so their proportionality cannot be judged from this pack. "All comes back when he dies" is only half-shown: N.loot/N.held are set, but no death-return handler is in the slice. Verdict: raid/tithe are proportionate in magnitude, but raid timing and return are not proven fair.

### SIX RIVALS OR ONE

They are not six skins: clock speed, flee/revive rules, strike type, fleet archetype, AI weights, persona pools, trait pools, and scar epithets differ. Rank as designs: 1 Chorus (strongest: adaptFast plus feeds, compounding at 80% loss rate), 2 Corsair (raid plus flee plus extra ship each return), 3 Voidsworn (fast clock, no flee, flagship challenge), 4 Ithar (duelist flee and honing), 5 Deathless (slow clock, revive, tithe), 6 Hegemony (weakest: fixed round-3 reinforce, line formation, no flee/revive, least escalation). The single change that would most improve Hegemony: make its reinforcements scale with meetings or clock, so "methodical" becomes a persistent pressure rather than a one-time round-3 add.

### PERSISTENCE

Flee, scars, revival, and per-return escalation create a story: corsair returns richer with an extra ship, Ithar returns honed, Deathless revives, scars add epithets, and gloat lines remember how the player won. The line between "rival who learns" and "tax that follows you" is whether persistence is bounded, telegraphed, and answerable. This system mostly sits on the rival side because fights are marked, adaptations are capped, strikes are announced, and weaknesses are fixed truths. But it drifts toward tax when Corsair's extra ship is uncapped, Chorus feeds on player losses at an 80% loss rate, and raid loot/held ships are not shown returning on death. A good Nemesis arc ends with a marked, answerable kill that returns held assets and closes the scar/epithet story; Deathless's final revive is a good capstone if the death handler is complete.

### CONTRADICTIONS WITH STATED INTENT

Marked fights: mostly held by nemNodeIs, but raid can seize a ship on clock fill before the marked fight. Capped adaptation: code is cumulative and Chorus-fast, not literally one per sector. True weaknesses: fixed and true, but the reveal economy can leave a losing player without any reveal. "No ship loss without warning": the raid ship-seizure branch can fire from a loud-event clock fill without the "next win" warning. "It all comes back when he dies": unverified in the shown code.

## 4. Not checked

Event frequency and pity for nemIntel; actual UI/debrief rendering; battle application of adaptations, weaknesses, traits, and AI weights; implementation of duel/reinforce/swarm/challenge outside nemStrike; death-return handler for N.loot/N.held; map generation and node-marking edge cases; actual 80% loss-rate simulation; save migration behavior; portrait/scar overlays; and whether faction verbs interact with the Nemesis clock as described.

## 5. Questions for the designer

1. Should a raid ever seize a crippled ship on an event-driven clock fill without a map-marked pre-commit warning, or is that a bug against "no ship loss without warning"? Stakes: whether the core fairness promise holds.
2. If a player draws no nemIntel events and loses every Nemesis fight at the intended 80% loss rate, how are they supposed to learn the two fixed weaknesses? Stakes: whether the information game is answerable for the majority experience.
3. Are duel, reinforce, swarm, and challenge implemented outside nemStrike, and does death return N.loot/N.held? Stakes: whether four faction signatures and the raid economy are real mechanics or only descriptions.
