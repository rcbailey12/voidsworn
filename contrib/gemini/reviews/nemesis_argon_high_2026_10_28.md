# Argon blind leg: Nemesis mechanics audit (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (Gemini Argon High; chat https://gemini.google.com/app/6b11c450635ce208). Em dashes and en dashes normalized to hyphens per house rule; inline citation chips omitted as UI markers. In the rendered view, two citation artifacts in Findings 2 and 4 were garbled and obscured intervening words; those artifacts were removed and only the surrounding coherent sentences retained, so those two passages are not a character-perfect transcription. Evidence pack: the Oct 28 battle program Nemesis pack (code slices pinned to main 264f441d). Method notes and screening live outside this file.

## 1. Proof of reading

Pack sections read:

- EVIDENCE PACK title line (EVIDENCE PACK: Nemesis mechanics audit (code slices from the shipped browser build, main 264f441d; the Godot port mirrors this design)).
- THE COMMISSIONER'S QUESTION.
- CHAIR CENSUS (verified from the code in this pack).
- WHAT TO JUDGE.
- Code slices: === data.js 423-562: Nemesis B4 and R42 v2 === and === campaign_run.js 247-300: newNemesis, clock, strike === (noting that campaign_run.js is truncated mid-function at line 300 inside nemAfterBattle).

Overall verdict: A MECHANISM IN A COSTUME - Despite strong per-faction flavor and scar epithets, mandatory end-of-sector spawns make the clock redundant for four of six factions, adaptations automatically cancel out the very weaknesses intel tells the player to exploit, and heavily shared trait/persona pools flatten faction identity into a scheduled stat tax.

## 2. Findings

1. [BLOCKER] Adaptation directly counters and nullifies the Nemesis's own fixed weaknesses.

READ: newNemesis prevents initial traits from canceling weaknesses via clash={slow:'swift',board:'boarders',ion:'shielded'}, but nemAdapt filters candidate adaptations solely by !N.adapt.includes(k) without checking N.weak.

INFERRED: When a player discovers and exploits NEM_WEAK.ion ("Ion and lance hits strip 50% more shield") or NEM_WEAK.torp ("Torpedoes are 15 easier to land"), N.seen accumulates lance/ion (*2) or torp (*2) points and nemAdapt selects shields ("His ships have 20% more shields") or pd ("Two of his ships bolt on point defense"), directly punishing the player for acting on revealed intel.

2. [BLOCKER] Mandatory end-of-sector spawns neutralize the clock for four of six factions and starve Deathless's strike.

READ: nemNodeIs forces a Nemesis encounter whenever N.strike||n.col>=(RUN.map.cols.length-3) if N.met<RUN.sector. After a battle, the Nemesis fight first resets N.clock=0 without ever firing tithe. For Ithar, Chorus, Hegemony, and Voidsworn, filling the clock produces no map strike at all (nemStrike returns '') and only pulls the unavoidable sector fight forward by a few columns.

3. [BLOCKER] Corsair's raid breaks the "no ship loss without warning" guarantee when a ship is crippled during the clock-filling fight.

READ: Code comments promise "no ship loss without warning" and "always announced on his card first". nemWarnLine evaluates RUN.fleet.some(x=>x.uid!==RUN.flagUid&&x.hp<derive(x).maxHp*.25) before the clock-filling win, whereas nemStrike re-evaluates x.hp<derive(x).maxHp*.25 after the win. Neither nemWarnLine nor nemStrike checks N.held in the same way (nemStrike requires !N.held, while nemWarnLine ignores N.held).

INFERRED: If a player with <30 credits enters the clock-filling battle with all ships above 25% hull, nemWarnLine states the Corsair will "find nothing to take", but if an escort drops below 25% hull during that battle, nemStrike immediately steals that ship upon victory without prior warning. Conversely, if N.held is already occupied from a prior sector, nemWarnLine issues a false ship-theft warning when nemStrike will actually do nothing.

4. [FIX] Post-meeting clock overflow pre-fills the next sector's clock and makes Corsair's shake verb penalty-free.

READ: In nemClockAdd, N.clock=clamp(Math.round((N.clock+step)*2)/2,0,NEM_CLOCK) runs unconditionally before checking if(N.clock>=NEM_CLOCK&&N.met<RUN.sector&&!N.strike).

[NOTE] ensureNemesis copies only 10 fields from old (omitting loot, held, riches, fed, honed, and revived). nemClockAdd and nemStrike do not pass their strings through nemSay, and nemWarnLine passes "your next fight will be his" through nemSay. Chair Census states "one at double" clock speed and "5 adaptations".

INFERRED: Migrating an older object via ensureNemesis deletes faction special adaptations (since their IDs are in NEM_ADAPT_FAC, not NEM_ADAPT) and wipes Corsair's loot and held ship. Female (g:'f') and Chorus (g:'n') Nemeses are misgendered as "He/His/him" in nemStrike and nemClockAdd, and "be his" becomes ungrammatical "be her" in nemWarnLine. Finally, Voidsworn's clock is 1.5 (not double), and NEM_ADAPT_FAC[fac].special adds a 6th adaptation per faction.

## 3. Explicit checks

### 1. ADAPTATION

Accuracy of the trigger and why text:

READ: nemAdapt scores five counters from N.seen - shields:(s.lance||0)*2+(s.ion||0)*2, pd:(s.torp||0)*2+(s.sq||0), armor:(s.ram||0)*4+(s.board||0)*4, evasion:(s.battery||0)+(s.broad||0), and aim:(s.evaded||0)*3 - and falls back to NEM_ADAPT_FAC[N.fac].special.id (why:'his own way of war') if all unpicked scores are 0.

INFERRED: The trigger accuracy fails in three ways:

False compound attribution: Four of the five why strings pair two distinct mechanics ("lances and ion fire", "torpedoes and wings", "rammed and boarded", "broadsides and batteries"), naming both habits even when the player used only one.

Wrong counter for boarding: Boarding (s.board*4) triggers armor ("His ships have 10% more armor"), which counters hull damage rather than boarding crew (NEM_WEAK.board and NEM_TRAITS.boarders scale crew by 30%, and d_scythe_s uses point defense against boarders' craft).

Multiplier distortion and scope mismatch: Because ram/board (*4) and evaded (*3) are weighted 3x-4x higher than battery/broad/sq (*1), minor secondary actions can outscore the fleet's primary damage source. Moreover, nemAdapt reads sector-wide N.seen, whereas NEM_LINES.again ("Last time you beat me with {beat}. It will not work twice.") claims he countered last_beat from the Nemesis fight itself.

Visibility in play:

READ: Four of the five standard adaptations (+20% more shields, +10% more armor, +8 more evasion, +8 better aim) are passive stat modifiers, while only pd ("Two of his ships bolt on point defense") and faction specials like riches ("One more ship joins his fleet") or legion ("One more of his ships reassembles") alter visible battlefield units. The Oct 28, 2026 ruling makes adaptation visible on the end-of-run debrief.

INFERRED: Without in-combat UI callouts, a +8 evasion/aim or +10% armor shift is difficult to feel mid-battle amidst baseline traits (gunnery +6 aim, armored +8% armor, shielded +20% shields, veil +8 harder to hit) that grant nearly identical modifiers from Sector 1.

Baiting or dodging:

READ: nemAdapt picks the highest-scoring unpicked counter >0, resets N.seen={}, and if no score is >0, picks sp.id and then Object.keys(score).filter(k=>!N.adapt.includes(k))[0].

INFERRED: A player cannot dodge adaptation - even if N.seen is completely empty, the Nemesis takes his faction special adaptation. However, a player who learns the 4x multiplier on ram/board can deliberately bait armor (+10% armor) with a few boardings or rams in Sector 1 so their main broadside/battery guns (*1) are not countered by evasion (+8 evasion) in Sector 2.

### 2. WEAKNESSES AND INTEL

Tracing a run that draws no intel events:

READ: newNemesis rolls two fixed weaknesses (weak:shuffle(weakPool).slice(0,2)) with revealed:[], which are active from the first battle ("true from the first meeting"). While Chair Census mentions only campaign events (nemIntel), line 299 of campaign_run.js shows that winning a battle against the Nemesis (if(result==='win')) also calls const w=nemReveal() and outputs "His captured logs reveal a weakness: ...".

INFERRED: A player who draws zero nemIntel events enters the Sector 1 Nemesis fight completely blind (0 revealed weaknesses) and only benefits from a weakness by pure luck if their starting fleet happens to trigger it. If the player wins the Sector 1 fight, nemAfterBattle reveals 1 weakness for Sector 2, and winning in Sector 2 reveals the 2nd weakness for Sector 3. If the player loses or retreats in Sector 1, they get no log reveal and remain blind.

Is the information game fair?

INFERRED: No, for three reasons:

Unequal usability across factions: Positional/stat weaknesses (flank, brawl, anchor, slow) can be exploited by any fleet, but loadout-specific weaknesses (ion, torp, board) require specific weapons or crew. Notably, FAC_GATES.corsair enforces noKind:['lance'] ("Hullbreakers field no lance weapons"), locking Corsair players out of lances for ion.

Self-canceling adaptation: If a player uncovers ion or torp via intel and exploits it, nemAdapt counters that exact damage type with shields or pd in the next sector.

Late non-event cadence: Relying on post-battle log reveals gives zero information for Sector 1 and withholds the second weakness until Sector 3.

### 3. CLOCK AND STRIKES

Proportionality of all six faction strikes at an 80% loss rate:

READ: NEM_CLOCK=4 scales by beh.clock (0.5 for Deathless, 1.5 for Voidsworn, 1 for others). When N.clock>=NEM_CLOCK&&N.met<RUN.sector&&!N.strike, nemStrike() fires:

1. Corsair (raid): Takes 25% RUN.credits if >=30, or if <30, confiscates the lowest-HP non-flagship under 25% hull from a fleet of >=3 (if !N.held) and increments N.riches++.
2. Deathless (tithe): Drains 6% of maxHp from every ship (Math.max(1, ...)).
3. Ithar (duel): nemStrike() returns '' (no map effect).
4. Chorus (swarm): nemStrike() returns '' (no map effect).
5. Hegemony (reinforce): nemStrike() returns '' (no map effect).
6. Voidsworn (challenge): nemStrike() returns '' (no map effect).

INFERRED: Strike proportionality is heavily skewed across factions:

Corsair (raid) is punitive at an 80% loss rate: confiscating 1 of 3 ships (a 33% fleet reduction) or 25% of credits right before forcing a boss fight - while simultaneously giving the Corsair +1 ship via N.riches++ - accelerates a losing run into an unwinnable state.

Deathless (tithe) is mild (-6% hull), but because clock:0.5 requires 8 clock ticks before col>=(RUN.map.cols.length-3) forces the fight and resets N.clock=0, tithe almost never fires.

Ithar (duel), Chorus (swarm), Hegemony (reinforce), and Voidsworn (challenge) have no map strike at all in nemStrike(); their named mechanics are combat rules that apply even if the player meets them at the end of the sector without filling the clock.

Checking "it all comes back to you when he dies" (raid):

READ: nemStrike records stolen credits in N.loot and a stolen ship in N.held, but campaign_run.js is truncated at line 300 inside nemAfterBattle before the death-payout code appears, and ensureNemesis omits loot and held when copying fields.

INFERRED: Even assuming the truncated lines restore N.loot and N.held when flagDead is true, the design claim fails in practice at an 80% loss rate. Because Corsair has flee:{hull:.35}, he withdraws from losing fights in Sectors 1 and 2, keeping your ship/credits across sectors while gaining N.riches++ (+1 ship per flee and per ship theft). In the 80% of runs where the player dies before killing him in Sector 3, the stolen assets never return; in the 20% of runs where the player kills him in Sector 3, getting a crippled Sector 1 hull or early credits back at the end of the run is too late to help survive Sectors 1-2.

### 4. SIX RIVALS OR ONE

Comparison of the six packages:

READ: Each faction defines personas (4), traits (6), beh (clock, flee/revive/noFlee, strike, fleet, ai), and a NEM_ADAPT_FAC special adaptation. However, gunnery, deadeye, and veterans appear in 5 of 6 trait pools, cruel and proud appear in 5 of 6 persona pools, and the five standard adaptations in NEM_ADAPT have identical mechanics across all six factions (differing only in flavor names in NEM_ADAPT_FAC).

INFERRED: Baseline traits, personas, and standard adaptations play as one rival with six skins; genuine mechanical differentiation comes almost entirely from beh.

Ranking the six packages as designs (1 = strongest, 6 = weakest):

Ithar (Strongest): Cohesive hit-and-run duelist (fleet:'duel', ai:{range:3,focusWeak:1}, flee:{shields:1,hull:.6}) whose survival scales ship quality (N.honed++ for better shields and aim) rather than fleet size, backed by two distinct traits (veil, artillery).

Corsair: High-drama raider (strike:'raid', flee:{hull:.35}, fleet:'swarm') whose escapes and thefts visibly grow his fleet (N.riches++), held back by overtuned ship confiscation and the nemWarnLine warning bug.

Voidsworn: Distinct aggressive charger (clock:1.5, noFlee:1, ai:{hunt:1,charge:1}, flagship +20% damage challenge), weakened by having no map effect on strike:'challenge' and potential brawl/methodical roll clashes.

Deathless: Strong attrition identity (revive:1, tithe, undying, regrowth), undermined by clock:0.5 preventing tithe from firing before the forced end-of-sector fight.

Chorus: Ambitious scaling (feeds:1 granting +4% toughness per player ship lost anywhere up to 32%, adaptFast:1, brood, regrowth), but mechanically broken by adaptFast double-counting N.beaten+N.scars, no map effect for strike:'swarm', patient in its persona pool, and no flee or revive rule in beh to guarantee it survives meetings.

Hegemony (Weakest): Generic heavy line (clock:1, fleet:'heavy', line:1, strike:'reinforce') with no map strike in nemStrike(), no flee or revive mechanic in beh, and 5 of 6 traits shared with almost every other faction (66.7% chance to miss artillery). Its description claims "He adapts by drilling his formation tighter", which is actually special.id:'formation' - a fallback that only triggers when all N.seen scores are 0.

Single change to most improve the weakest package (Hegemony):

INFERRED: Give Hegemony a disciplined withdrawal threshold (flee:{hull:.4}) and make his reinforce strike or post-battle adaptation automatically grant a rank of formation (+1 hex synchronized fire range / round-3 reinforcement wave) rather than locking formation behind an unreachable N.seen === 0 fallback.

### 5. PERSISTENCE

Where the line sits between a rival who learns and a tax that follows you:

INFERRED: A rival who learns responds to the player's specific tactics in ways the player can anticipate, bait, or counter-build around, and can be delayed or finished off through smart play; a tax that follows you arrives on a fixed schedule and extracts resources or adds unavoidable stat buffs regardless of player choices.

Which side this system sits on (with evidence):

INFERRED: This system sits on the tax side, disguised with rival flavor (NEM_LINES, nemScar epithets, and portrait overlays):

Unavoidable scheduling: nemNodeIs guarantees a fight in every sector at n.col>=(RUN.map.cols.length-3) even if the player keeps the clock low.

Unconditional stat inflation: nemAdapt adds a stat buff every sector (even when N.seen is empty via sp.id) and directly erases revealed weaknesses (ion -> shields, torp -> pd).

Passive/compounding extraction: Corsair extracts 25% of credits or a ship before combat and flees at 35% hull with +1 ship (N.riches++), Deathless drains 6% fleet hull (tithe), and Chorus gains +4% fleet toughness (feeds:1, up to 32%) whenever the player loses a ship in any battle across the run.

## 4. Not checked

The truncated remainder of nemAfterBattle (campaign_run.js after line 300): The pack cuts off immediately after if(o.fled){ ... } inside if(result==='win'). This prevents verifying how flagDead (killing the Nemesis), Corsair N.loot/N.held return, Deathless revive:1, non-fleeing survival and wound/burn scars, nemBeatTeach(o.beat), and player defeats/retreats (result !== 'win') are coded.

battle.js combat execution: The pack does not include battle.js, leaving unchecked how N.seen keys (lance, ion, torp, sq, ram, board, battery, broad, evaded) are incremented, how o.beat and o.fled are determined, whether a player can burst Corsair/Ithar from >=35%/60% hull to 0 to prevent fleeing, and how ai weights, honed, fed, riches, line, reinforce, and challenge operate in battle.

Map generation and event frequency: The pack does not show sector column counts, node branching (whether all paths at col >= RUN.map.cols.length - 3 are battle/elite nodes), or the draw rates and costs of the "at least six events" offering nemIntel or clock changes.

End-of-run debrief UI: Ruled on Oct 28, 2026 to display adaptation, but its implementation is not in the code slices.

## 5. Questions for the designer

Should nemAdapt exclude adaptations that directly counter the Nemesis's rolled N.weak vulnerabilities (e.g., blocking shields when weak to ion and pd when weak to torp)?

Stakes: Without this filter, players who invest in intel events and build around a revealed weakness are immediately punished in the next sector when the Nemesis auto-adapts to neutralize that exact weakness.

Is the Nemesis meant to be a mandatory once-per-sector boss (n.col >= RUN.map.cols.length - 3) or a clock-triggered hunter (N.clock >= 4)?

Stakes: Because nemNodeIs currently forces an end-of-sector encounter that resets N.clock = 0, playing quietly never avoids the Nemesis, four factions have no penalty for filling the clock early, and Deathless (clock: 0.5) rarely reaches 4 before the sector ends.

How do Chorus, Hegemony, and Voidsworn (noFlee: 1) survive a Sector 1 or Sector 2 player victory when the player destroys their flagship?

Stakes: If flagship destruction permanently kills non-Deathless Nemeses in Sector 1, Chorus's adaptFast and feeds mechanics and multi-sector rivalry arcs end on the first decisive win; if they automatically survive flagship destruction, Deathless's revive: 1 has no unique function before Sector 3.
