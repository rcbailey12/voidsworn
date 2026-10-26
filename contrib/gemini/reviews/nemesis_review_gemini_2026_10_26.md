# Nemesis faction behaviour review, Argon leg (brief muse_2026-10-26c, Job 2)

Model: Gemini web chat, 4 Argon with Thinking level High ("Argon High" verified in the picker button and the prompt bar dropdown before submitting), fresh chat, Oct 26, 2026. All five pack files attached via Upload files. Method note: the first chat attempt stalled partway through generation and was lost on reload; the review below is from a second fresh chat run with the same verification and attachments, completed in full. The model's bracketed cite markers refer to its attached sources and are preserved as returned. Filed verbatim below.

---

1. Research Findings: Comparison Systems
Shadow of Mordor and Shadow of War (Monolith Productions)

Monolith's Nemesis system is documented in Warner Bros. US Patent US10926179B2 (filed as US20160279522A1, https://patents.google.com/patent/US10926179B2/en), in Michael de Plater and Bob Roberts' GDC 2015 postmortem (https://www.gamedeveloper.com/design/gdc-2015-how-monolith-built-shadow-of-mordor-s-nemesis-system), and in Mark Brown's Game Maker's Toolkit breakdown (https://www.youtube.com/watch?v=Lm_AzK27mZY). Four mechanical pillars in Monolith's system directly test Voidsworn's implementation[cite: 1, 2]:

Event-Specific Encounter Memory: In Shadow of Mordor, the hierarchy state machine logs the exact outcome of the previous encounter: whether the player fled, whether the rival killed the player, whether the rival fled in terror, or which specific damage type (fire, poison, stealth, beasts, execution) wounded or killed the rival (https://patents.google.com/patent/US10926179B2/en). At the start of the next fight, the camera interrupts combat for a brief confrontation where the rival's dialogue bark references that exact past event (https://www.youtube.com/watch?v=Lm_AzK27mZY). In Voidsworn, NEM_LINES.again (data_nemesis.txt) only records how the player beat the Nemesis via {beat}, using one template string regardless of whether the Nemesis fled, had his flagship blown up, or beat the player[cite: 4, 5].

Causal Scars and Titles: When an Uruk cheats death in Shadow of Mordor, the damage type that killed him determines both his visual scar (burn tissue, wraith scars, metal jaw, stitch work) and his new epithet, such as "the Flame of War" or "the Stitch" (https://www.gamedeveloper.com/design/gdc-2015-how-monolith-built-shadow-of-mordor-s-nemesis-system). In Voidsworn (port_notes_r42.txt Campaign section, data_nemesis.txt NEM_FAC), nemScar(cause) logs the cause in scarList, but picks any random unused epithet from the faction's six-item scars list[cite: 4, 5]. A Corsair who simply fled at 35% hull can return titled "the Burned"[cite: 4, 5].

Actionable Retreats: When an Uruk captain breaks and flees in Shadow of Mordor, a skull retreat icon appears over his head and he physically runs toward the map edge, giving the player a tactical window to chase, pin, or execute him (https://www.youtube.com/watch?v=Lm_AzK27mZY). In Voidsworn (port_notes_r42.txt Battle section, nemFleeCheck()), when a Corsair or Ithar flagship starts the enemy turn below its threshold, the flagship and all capital escorts instantly become fled and checkEnd terminates the battle immediately[cite: 4].

Intel and Pre-Fight Readability: In Shadow of Mordor, a rival's strengths are visible on the Army screen, while weaknesses start hidden until revealed by interrogating Worms or triggering them in combat (https://patents.google.com/patent/US10926179B2/en). Voidsworn tracks weaknesses and revealed [] on RUN.nem alongside an event outcome key nemIntel (port_notes_b4.txt Campaign section)[cite: 3], giving it the data hooks for pre-fight scouting if the UI surfaces them.

XCOM 2: War of the Chosen (Firaxis Games)

Jake Solomon's design interviews on XCOM 2: War of the Chosen explain how three faction-styled rivals (Assassin, Hunter, Warlock) pressure the player on both the strategic map and the tactical grid (https://www.pcgamer.com/xcom-2-war-of-the-chosen-interview-jake-solomon/). On the strategic map, the Chosen sabotage supplies and gather knowledge, but they never permanently delete a player soldier from the barracks through a passive strategic clock tick; capturing a soldier happens only inside a tactical mission with turn warnings and a rescue mission afterward (https://www.pcgamer.com/xcom-2-war-of-the-chosen-interview-jake-solomon/). This sharpens the fairness review of Voidsworn's Corsair raid strike (port_notes_r42.txt Campaign section), which can permanently remove a damaged player ship on the campaign map when the clock fills[cite: 4, 5].

Warframe: Kuva Liches (Digital Extremes)

Digital Extremes introduced Kuva Liches in Warframe Update 26: The Old Blood (https://www.warframe.com/updates/pc/26-0-0). Liches tax resources from player missions and build a rage meter until they ambush the player. Crucially, every credit and resource stolen by a Lich is stored in a visible pot and returned to the player when the Lich is finally killed (https://www.warframe.com/updates/pc/26-0-0). In Voidsworn (port_notes_r42.txt Campaign and Battle sections), the Corsair Nemesis takes 25% of the player's credits (or a crippled ship) and converts riches +1 into an extra cheapHull enemy ship in battle, with no documented payout to recover the stolen wealth when the player defeats him[cite: 4].

Hades (Supergiant Games)

Greg Kasavin's GDC 2021 talk on Hades details how recurring bosses like Megaera and Theseus maintain the illusion of long-term memory across dozens of runs by checking a prioritized condition queue at the start of each fight (https://gdcvault.com/play/1027193/Designing-the-Narrative-of-Hades). Dialogue lines filter by both boss identity and specific last-fight state. This highlights the narrow bottleneck in Voidsworn's NEM_LINES (data_nemesis.txt), where all six factions share eight generic persona opening lines and one single rematch string[cite: 5].

2. Six Faction Verdicts
Corsair: "raids and flees"

What is implemented: In data_nemesis.txt (NEM_FAC.corsair.beh and NEM_ADAPT_FAC.corsair), the Corsair has clock: 1, flee: {hull: .35}, strike: 'raid', fleet: 'swarm', and a faction special adaptation riches ('Bigger crew', adding one ship)[cite: 5]. In port_notes_r42.txt (Campaign section, nemStrike()), filling the clock triggers raid: if the player has 30 or more credits, he takes 25% of the player's credits; otherwise, if the player has 3 or more ships, he cuts out the lowest-hull non-flagship ship that is under 25% hull and gains riches +1[cite: 4]. In port_notes_r42.txt (Battle section, applyNemesis and nemFleeCheck()), he spawns one extra cheapHull ship at edgeHex('enemy') per riches level (plus one if he has the 'riches' special), and at the start of the enemy turn, if his flagship hull is <= 35%, he and all capital escorts become fled, setting B.nemFled and ending the battle as a player win while granting him the 'fled' scar and riches +1 in nemAfterBattle[cite: 4].

Matches the ruling's verbs?: Yes. Both "raids" (nemStrike on clock fill) and "flees" (nemFleeCheck at <= 35% hull, returning with extra ships via riches) have direct mechanical teeth[cite: 2, 4, 5].

Readable before the fight?: Yes on the campaign card, no at the moment of retreat in battle. NEM_FAC.corsair.beh.d (data_nemesis.txt) explicitly states the 25% credit raid, the under-30-credits / under-25%-hull ship loss rule, the retreat behaviour, and the extra ship return[cite: 5]. A code comment in data_nemesis.txt notes that raid is "always announced on his card first"[cite: 5]. However, in battle, nemFleeCheck() triggers instantly at the start of the enemy turn with no prior warning round[cite: 4].

Fairness (R7 constraints): Fails the "no ship loss without warning" constraint in edge cases (Design judgement). Although NEM_FAC.corsair.beh.d describes the rule in text[cite: 5], nemClockAdd(n) fills the clock at the end of a regular battle (finishBattle in port_notes_b4.txt), via an event (nemClock), or when the player clicks the Corsair shake verb (FAC_VERBS.corsair in data_nemesis.txt)[cite: 3, 5]. If the player wins a tough normal fight that leaves a ship below 25% hull while holding under 30 credits, and that win ticks the clock from 3 to 4, nemStrike() immediately deletes that crippled ship on the campaign layer before the player has a chance to repair it or defend it in combat[cite: 3, 4]. Furthermore, nemFleeCheck() firing at enemy turn start (port_notes_r42.txt Battle section) abruptly ends the battle the moment the player passes turn with the Corsair flagship at 35% hull, denying the player a final turn to chase down a fleeing target[cite: 4].

Distinct in play?: Strongly distinct. He is the only Nemesis who attacks the player's wallet on the map, turns escapes into extra hull spawns (riches), and ends fights early by running away[cite: 4, 5].

Deathless: "returns once after death"

What is implemented: In data_nemesis.txt (NEM_FAC.deathless.beh and NEM_ADAPT_FAC.deathless), Deathless has clock: .5, revive: 1, strike: 'tithe', fleet: 'heavy', and the special adaptation legion ('Wider legion', legion +1)[cite: 5]. In port_notes_r42.txt (Campaign and Battle sections), newNemesis() strips anchor from his weakness pool, nemClockAdd multiplies clock gains by 0.5 (rounded to halves), and B.nemNoRout disables the 35% rout rule[cite: 4]. When his clock fills, nemStrike() executes tithe: every player ship loses 6% max hull (min 1)[cite: 4]. In nemAfterBattle, if flagDead is true with beh.revive and not yet revived, it sets revived, adds a scar, and in Sector 3 drops met back one (met = 2) so he can fight the player again in Sector 3[cite: 4].

Matches the ruling's verbs?: Compromised by base survival rules, plus adds an unrequested verb. Look at how nemAfterBattle handles flagDead across all factions (port_notes_b4.txt Golden Scenario 7; port_notes_r42.txt Campaign section): "flagDead with beh.revive and not yet revived (revived, scar, and in sector 3 met drops back one so he can meet you again); flagDead in sector 3 (dead); flagDead earlier (scar)"[cite: 3, 4]. Because flagDead earlier (scar) applies to every faction in Sectors 1 and 2, every Nemesis returns after having his flagship destroyed in Sectors 1 and 2[cite: 4]! Worse, if the player destroys the Deathless flagship in Sector 1, that consumes his revived flag in a sector where he would have survived anyway[cite: 4]. Then, when the player kills him in Sector 3, not yet revived is false, so he dies on the first kill in Sector 3 just like every other faction[cite: 4]! His revive: 1 rule only does something unique if the player failed to kill his flagship in Sectors 1 and 2 and kills it for the first time in Sector 3[cite: 4]. Meanwhile, R42 added strike: 'tithe' (6% hull drain) and clock: .5, neither of which was in the ruling ("Deathless: returns once after death")[cite: 2, 4, 5].

Readable before the fight?: Yes. NEM_FAC.deathless.beh.d (data_nemesis.txt) states his half-speed clock, no retreat, reassembling once after death, and 6% hull drain[cite: 5].

Fairness (R7 constraints): Fair, provided every ship loses 6% max hull, min 1 (port_notes_r42.txt Campaign section) means player ships are clamped to a minimum of 1 hull remaining rather than taking a minimum of 1 damage that could destroy a ship at 1 HP[cite: 4]. No control is stolen.

Distinct in play?: Weakly distinct in Sectors 1 and 2 (Design judgement). Because all six factions survive flagship destruction in Sectors 1 and 2 (port_notes_r42.txt Campaign section)[cite: 4], "returns once after death" is not unique to Deathless until Sector 3 (and even then, only if he was never killed in Sectors 1 or 2)[cite: 4]. His clock: .5 also requires 8 player wins to fill (NEM_CLOCK = 4)[cite: 4, 5], meaning his tithe strike rarely triggers.

Ithar: "duels and withdraws"

What is implemented: In data_nemesis.txt (NEM_FAC.ithar.beh and NEM_ADAPT_FAC.ithar), Ithar has clock: 1, flee: {shields: 1, hull: .6}, strike: 'duel', fleet: 'duel', and the special adaptation veil (+6 evasion)[cite: 5]. In port_notes_r42.txt (Battle section, applyNemesis), the Ithar duel fleet prunes the enemy roster to keep only the flagship and the three biggest ships (max 4 ships), promoting all of them to elite with +6 aim and +5 crit[cite: 4]. In nemFleeCheck(), at the start of the enemy turn, if every flagship shield is <= .5 and flagship hull is <= 60%, he and all capital escorts become fled, setting B.nemFled and ending the battle as a player win[cite: 4].

Matches the ruling's verbs?: Yes. "Duels" creates a small, four-ship all-elite fleet (applyNemesis), and "withdraws" pulls the fleet out once the flagship's shields are down and hull reaches 60% (nemFleeCheck)[cite: 2, 4, 5].

Readable before the fight?: Mostly yes, with two mismatches between the card text and the code. First, NEM_FAC.ithar.beh.d (data_nemesis.txt) says he withdraws "once his flagship's shields are all down and its hull is under 60%" (matching flee: {shields: 1, hull: .6})[cite: 5], whereas port_notes_r42.txt (Battle section) triggers nemFleeCheck() when every flagship shield <= .5 and hull <= 60%[cite: 4]. Second, beh.d promises that he "picks off your weakest ship"[cite: 5], but in port_notes_r42.txt (Battle section, nemTargetBonus) and data_nemesis.txt (NEM_PERSONA), weak-ship targeting (focusWeak: 1) only happens if he rolls the cunning or cruel persona; if he rolls proud or patient from NEM_FAC.ithar.personas, he has no bonus to target weak ships[cite: 4, 5].

Fairness (R7 constraints): Fair. No map-level damage or ship loss, and withdrawing at 60% hull rewards the player with a clean battle win (checkEnd in port_notes_r42.txt) without requiring a full fleet wipe[cite: 4].

Distinct in play?: Very distinct. Facing at most four high-accuracy, high-crit elite ships where stripping the flagship's shields and dropping it to 60% hull wins the battle creates a completely different tactical puzzle from swarm or heavy fleets[cite: 4, 5]. Note one dead state variable: nemAfterBattle in port_notes_r42.txt increments riches +1 "for factions with a flee rule", which includes Ithar, even though Ithar never uses riches[cite: 4].

Chorus: "feeds on your losses"

What is implemented: In data_nemesis.txt (NEM_FAC.chorus.beh and NEM_ADAPT_FAC.chorus), Chorus has clock: 1, feeds: 1, adaptFast: 1, strike: 'swarm', fleet: 'swarm', and the special adaptation hunger (+3 hull regen per turn)[cite: 5]. In port_notes_r42.txt (Campaign and Battle sections), finishBattle calls nemFeedLosses(n) after every battle with player ship losses, adding +n to fed (capped at 8)[cite: 4]. In applyNemesis, Chorus ships multiply max hull by 1 + .04 * fed (up to +32%)[cite: 4]. Because of adaptFast, nemAfterBattle triggers nemAdapt() after every meeting with the Nemesis in addition to sector transitions, raising the adaptation cap to (sector - 1) + beaten + scars (max 6)[cite: 4].

Matches the ruling's verbs?: Weakly. It matches the literal words by scaling max hull (+4% per player ship lost anywhere, up to +32%) and adding adaptFast[cite: 2, 4, 5], but strike: 'swarm' has no active map or battle trigger beyond setting the fleet archetype[cite: 4, 5].

Readable before the fight?: Partially. NEM_FAC.chorus.beh.d (data_nemesis.txt) states the +4% per lost ship (up to 32%) and post-meeting adaptation rules[cite: 5]. However, port_notes_r42.txt does not mention any campaign notification when nemFeedLosses(n) increments fed after a normal battle, nor whether the current fed bonus (+X% hull) is shown dynamically on the Nemesis card[cite: 4].

Fairness (R7 constraints): Complies with R7 (no sudden ship loss or stolen control), but creates a punishing snowball loop (Design judgement). A player who is already losing ships in regular battles is punished with a tougher Nemesis (up to +32% hull), whereas a winning player who loses zero ships faces a Chorus Nemesis whose primary ruling verb (feeds: 1) sits at fed = 0 and does nothing at all[cite: 4, 5].

Distinct in play?: Poorly distinct in battle (Design judgement). In a clean run with zero player ship losses, fed stays at 0, making the Chorus Nemesis indistinguishable from a baseline fleet except for having one or two extra adaptations via adaptFast[cite: 4]. Even when fed is active, a flat max-hull multiplier feels like passive stat inflation (overlapping with the veterans trait at +12% hull in NEM_TRAITS) rather than an active "feeding" behaviour in combat[cite: 4, 5].

Hegemony: "reinforces"

What is implemented: In data_nemesis.txt (NEM_FAC.hegemony.beh and NEM_ADAPT_FAC.hegemony), Hegemony has clock: 1, strike: 'reinforce', fleet: 'heavy', formation: 1, and the special adaptation formation ('Tight formation', sync radius +1)[cite: 5]. In port_notes_b4.txt (Battle section, applyNemesis), the Nemesis flagship is designated as the Hegemony anchor[cite: 3]. In port_notes_r42.txt (Campaign and Battle sections), Hegemony Nemesis fights force the battle reinforcement event at round 3 (campaign3d.js battleScreen), and the formation special increases enemy sync radius by +1[cite: 4].

Matches the ruling's verbs?: Yes. Every Hegemony Nemesis fight guarantees a round 3 reinforcement wave[cite: 2, 4, 5].

Readable before the fight?: Yes. NEM_FAC.hegemony.beh.d (data_nemesis.txt) explicitly warns the player that "his fights always bring reinforcements in round 3"[cite: 5].

Fairness (R7 constraints): Fair. Because the round 3 timing is disclosed in beh.d before the battle[cite: 5], the player can plan positioning and cooldowns around turn 3. No ships are lost without warning and no control is stolen.

Distinct in play?: Moderately distinct. The guaranteed round 3 arrival creates a clear tactical clock inside the battle: either burst down the anchor flagship before round 3 or prepare for a second wave[cite: 3, 4, 5]. Note a minor code mismatch: NEM_FAC.hegemony.beh sets formation: 1 as an innate behaviour key in data_nemesis.txt, whereas port_notes_r42.txt (Battle section) applies formation enemy sync radius +1 only under specials (NEM_ADAPT_FAC.hegemony.special)[cite: 4, 5].

Voidsworn: "challenges"

What is implemented: In data_nemesis.txt (NEM_FAC.voidsworn.beh and NEM_ADAPT_FAC.voidsworn), Voidsworn has clock: 1.5, noFlee: 1, strike: 'challenge', fleet: 'line', and the special adaptation zeal ('Fervour', +8% damage)[cite: 5]. In port_notes_r42.txt (Campaign and Battle sections), newNemesis() strips anchor from his weakness pool, nemClockAdd multiplies clock gains by 1.5 (rounded to halves), B.nemNoRout prevents the 35% rout rule from applying, and dmgMult adds +.2 (+20% damage) between his flagship (u.nemFlag) and the player's flagship (pflag) in both directions[cite: 4].

Matches the ruling's verbs?: Half-implemented (math modifier works, AI behaviour is missing). While dmgMult gives +20% damage between the two flagships (port_notes_r42.txt Battle section)[cite: 4], the Voidsworn flagship has no AI targeting rule directing it to attack the player's flagship! Look at port_notes_r42.txt (Battle section, nemTargetBonus(u,t) in aiPickPrimary) and data_nemesis.txt (NEM_PERSONA): the +25 target weight on the player's flagship (focusFlag: 1) belongs exclusively to the greedy persona[cite: 4, 5]. Yet NEM_FAC.voidsworn.personas (data_nemesis.txt) is ['zealous', 'proud', 'cruel', 'methodical'][cite: 5]. A Voidsworn Nemesis can never roll greedy, and if he rolls cruel (focusWeak: 1), his AI actively ignores your flagship to hunt crippled escorts (+20 x missing hull share) while supposedly "challenging" your flagship to a duel[cite: 4, 5]!

Readable before the fight?: Yes. NEM_FAC.voidsworn.beh.d (data_nemesis.txt) clearly explains the fast clock, no fleeing, and the symmetric +20% damage modifier between flagships[cite: 5].

Fairness (R7 constraints): Fair. The +20% flagship-vs-flagship damage bonus works both ways, rewarding a player who accepts the duel, and causes no unannounced ship loss or stolen control[cite: 4, 5].

Distinct in play?: Distinct on the campaign map (clock: 1.5 fills in just 3 wins instead of 4), but flat in battle (Design judgement)[cite: 4, 5]. Without AI targeting (focusFlag) to make the Voidsworn flagship steer toward and fire on pflag, "challenge" is just a passive +20% damage multiplier whenever the two flagships happen to trade shots[cite: 4, 5].

3. Memory System Judgement
What He Remembers (Tracked State)

Across port_notes_b4.txt, port_notes_r42.txt, and data_nemesis.txt, RUN.nem records[cite: 3, 4, 5]:

Campaign weapon tallies (seen {}): fireWeapon (port_notes_b4.txt Battle section) records player weapon usage (B.usage.kind, B.usage.ion) and finishBattle passes B.usage and the evasive flag into nemLearn[cite: 3].

Counter adaptations (adapt []): nemAdapt() (port_notes_b4.txt and port_notes_r42.txt Campaign sections) picks counters to the highest-scoring entry in seen (lance/ion -> shields, torp/sq -> pd, ram/board -> armor, battery/broadside -> evasion, evasive fleet -> aim), or falls back to the faction special in NEM_ADAPT_FAC[cite: 3, 4, 5].

What beat him (beat): nemAfterBattle (port_notes_r42.txt Campaign section) calls nemBeatOf(usage) from the Nemesis battle (lance, torp x2, sq, battery, ram x3, board x3, ion) and maps it via NEM_BEAT_WORD (data_nemesis.txt)[cite: 4, 5].

Survival history (scars, scarList, epithet, beaten, revived, dead): nemScar(cause) (port_notes_r42.txt Campaign section) increments scars, appends cause and 'ep:' markers to scarList, and picks an unused epithet from NEM_FAC[fac].scars[cite: 4, 5].

Faction counters (fed, riches): fed tracks total player ships lost across all battles (Chorus, max 8), and riches tracks raids and escapes (Corsair)[cite: 4].

What the Player Notices

The {beat} Rematch Bark: When fighting a previously beaten Nemesis (port_notes_r42.txt Battle section), the battle log replaces his opening persona taunt with NEM_LINES.again (data_nemesis.txt): "Last time you beat me with {beat}. It will not work twice."[cite: 4, 5].

Epithets and Scar Overlays: Each survival adds visual overlays to his portrait (data_nemesis.txt R42 header comment) and updates nemFull() (title + name + epithet in port_notes_r42.txt) with a faction scar title such as 'the Burned' or 'the Twice-Dead'[cite: 4, 5].

Named Adaptations with Reasons: NEM_ADAPT (data_nemesis.txt) provides a player-facing why string for each counter (for example, 'you leaned on torpedoes and wings'), and NEM_ADAPT_FAC translates each counter into faction vocabulary (such as 'Spore curtains' or 'Censer flak')[cite: 5].

Where the Memory Breaks or Stays Invisible

The {beat} Bark Contradicts nemAdapt(): This is the biggest crack in the memory illusion. beat is computed by nemBeatOf(usage) from the Nemesis fight alone, heavily weighting ram x3, board x3, and torp x2 (port_notes_r42.txt Campaign section)[cite: 4]. However, nemAdapt() picks adaptations based on RUN.nem.seen, which accumulates usage across every battle in the run (port_notes_b4.txt Campaign section, finishBattle), and only runs at sector transitions (except for Chorus adaptFast)[cite: 3, 4]. Consequently:

If you beat the Nemesis in Sector 1 by boarding him (beat = 'board'), but used lances in your other three Sector 1 fights, at the start of Sector 2 he adapts shields (lance/ion -> shields)[cite: 3, 4, 5]. When you meet him in Sector 2, he announces, "Last time you beat me with boarding parties. It will not work twice" (NEM_LINES.again), while having zero boarding/ramming counter (armor)[cite: 4, 5]!

Worse, if a Deathless Nemesis is killed and revives within Sector 3 (met drops to 2 in port_notes_r42.txt), or if any Nemesis flees mid-sector and is met again before a sector transition, nemAdapt() has not even run between the two fights (except for Chorus), so he claims "It will not work twice" without having adapted at all[cite: 3, 4, 5]!

Epithets Ignore cause: nemScar(cause) records cause (such as 'fled') into scarList, but picks a random unused epithet from NEM_FAC[fac].scars (port_notes_r42.txt Campaign section)[cite: 4]. A Nemesis who fled cleanly with 55% hull (Ithar) can return titled 'the Cracked Prism' or 'Ashwake', while one whose flagship blew up to boarding parties can return titled 'the Unsunk'[cite: 4, 5].

One-Sided Encounter Memory: NEM_LINES.again (data_nemesis.txt) assumes the player beat him ("Last time you beat me with {beat}")[cite: 4, 5]. He has no memory line for when he raided your fleet on the map, when he fled at 35% hull versus when his flagship was destroyed (flagDead), or when the player retreated from him[cite: 4, 5].

Silent Flagship Damage Scaling: Every scar gives the Nemesis flagship dmg *= 1 + .1 * scars (port_notes_b4.txt Battle section, applyNemesis)[cite: 3]. Nothing in data_nemesis.txt describes this +10% flagship damage buff per scar to the player[cite: 5].

Combat Does Not Reveal Weaknesses: RUN.nem initializes revealed [] (port_notes_b4.txt Campaign section) for weaknesses, and events can grant nemIntel[cite: 3]. However, port_notes_b4.txt and port_notes_r42.txt never add a weakness to revealed when the player triggers it in battle (for example, landing a rear-arc hit against flank, stripping shields with ion, or triggering anchor below 60% hull)[cite: 3, 4].

4. Every-Run Difference Judgement
Width of the Combinatorial Space

On paper, R42 (port_notes_r42.txt and data_nemesis.txt) expands the generator substantially[cite: 4, 5]:

Identity: 6 factions x 10 pre name roots x 10 post name roots x 4 titles = 2,400 possible name/title combinations, plus 6 portraits per faction (36 portraits total) and 6 scar epithets per faction[cite: 4, 5].

Build: Each faction draws 1 of 4 personas (from 8 in NEM_PERSONA), 2 of 6 strength traits (6 choose 2 = 15 trait pairs per faction, from 14 in NEM_TRAITS), and 2 of 7 weaknesses (7 choose 2 = 21 pairs for four factions; 6 choose 2 = 15 pairs for Voidsworn and Deathless with anchor removed)[cite: 4, 5].

Where Consecutive Runs Collapse and Feel the Same

The Sector Pacing Lock (cols - 3 Override): In port_notes_b4.txt (Campaign section), nemNodeIs(n) turns an unmet battle or elite node into the Nemesis fight whenever strike is true OR column >= cols - 3, and only if he was not met this sector[cite: 3]. This rule flattens the three clock speeds (0.5 Deathless, 1.0 standard, 1.5 Voidsworn in data_nemesis.txt) into the exact same macro-rhythm[cite: 3, 5]:

You fight the Nemesis once in Sector 1, once in Sector 2, and once in Sector 3 in almost every run (twice in Sector 3 only for Deathless if he hasn't used revive yet)[cite: 3, 4].

For Deathless (clock: .5), each player win adds 0.5 to the clock (port_notes_r42.txt Campaign section)[cite: 4]. Unless the player wins 8 battles inside a single sector before reaching cols - 3, the Deathless clock never reaches 4 in Sector 1, yet column >= cols - 3 forces him to spawn at the end of Sector 1 anyway[cite: 3, 4]! His half-speed clock does not actually delay his appearance across sectors; it only stops nemStrike() (tithe) from firing early[cite: 3, 4].

Immortal Until Sector 3: Because nemAfterBattle (port_notes_b4.txt and port_notes_r42.txt) only sets dead if flagDead happens in Sector 3, while flagDead earlier merely gives a scar[cite: 3, 4], the player can never permanently kill any Nemesis in Sector 1 or Sector 2, nor can a Nemesis survive Sector 3 to end the run undefeated if his flagship is destroyed there. Every run follows the same three-sector survival script.

Self-Canceling Traits and Weaknesses: newNemesis() (port_notes_r42.txt Campaign section) only removes anchor for Voidsworn and Deathless; it does not filter out weaknesses from NEM_WEAK that directly contradict the strength traits drawn from NEM_TRAITS (data_nemesis.txt)[cite: 4, 5]:

swift (+1 movement) + slow (-1 movement) = 0 net movement change[cite: 3, 4, 5].

boarders (x1.3 crew) + board (x0.7 crew) = 0.91x crew (nearly cancels out)[cite: 3, 4, 5].

shielded (x1.2 shields) + ion (x1.5 shield strip from ion/lance) blurs the shield identity[cite: 3, 4, 5].
Furthermore, 10 of the 14 NEM_TRAITS (gunnery, armored, veterans, deadeye, shielded, boarders, regrowth, veil, zeal, rockets) are passive stat modifiers across all ships rather than behaviour changes[cite: 4, 5].

Overlapping Persona Pools and Shared Lines: In NEM_FAC (data_nemesis.txt), the 4-persona pools per faction overlap heavily: proud and cruel appear in 5 of the 6 factions, while cunning and patient appear in 4 of the 6[cite: 5]. Worse, NEM_LINES.meet (data_nemesis.txt) has only 1 line per persona (8 lines total) and NEM_LINES.again has only 1 line for the entire game[cite: 5]. Two different factions rolling proud or cruel speak the exact same line on encounter 1 and the exact same {beat} line on encounters 2 and 3[cite: 5].

5. Ranked Fixes and UNSURE List
Ranked Fixes

Fix Deathless revive vs Global Sector 1-2 Immortality (port_notes_r42.txt Campaign section, nemAfterBattle): Right now, every faction survives flagDead in Sectors 1 and 2 (flagDead earlier (scar)), which robs Deathless of its core identity and wastes its revived flag if killed before Sector 3[cite: 4]. Either (a) make non-Deathless flagships auto-withdraw at 1% hull in Sectors 1 and 2 (framing survival as an escape rather than resurrection) while only Deathless is actually destroyed and reassembled, OR (b) make beh.revive resurrect the Deathless flagship inside the battle (or immediately spawn a second encounter in whichever sector he dies, not just Sector 3, without consuming revived on normal sector transitions) (Design judgement)[cite: 4, 5].

Give Voidsworn challenge AI Flagship Targeting (port_notes_r42.txt Battle section, nemTargetBonus in aiPickPrimary): Add a targeting bonus toward pflag (similar to greedy's +25 on your flagship in nemTargetBonus) whenever beh.strike === 'challenge' (or for the Voidsworn flagship u.nemFlag), so the Voidsworn Nemesis actively hunts the player's flagship to make use of the symmetric +.2 dmgMult bonus[cite: 4, 5].

Sync {beat} with nemAdapt() (port_notes_r42.txt Campaign section, nemAfterBattle and nemAdapt): When the player beats the Nemesis and sets beat via nemBeatOf(usage), force his next adaptation (or an immediate post-defeat adaptation) to counter beat directly rather than picking from sector-wide RUN.nem.seen totals[cite: 3, 4, 5]. If he says "Last time you beat me with {beat}. It will not work twice" (NEM_LINES.again), he must actually equip the counter to {beat}[cite: 4, 5].

Protect the Player from Unwarned Corsair Ship Deletion (port_notes_r42.txt Campaign section, nemStrike raid): To uphold R7 ("no ship loss without warning")[cite: 1, 2], never delete a player ship on a passive clock tick when credits < 30 and hull < 25%[cite: 4, 5]. Instead, let raid below 30 credits either put the player into credit debt, steal a refit mod from the hold (payMod exists in port_notes_b4.txt), or apply a repair-cost/hull tax that clamps hull at 1 HP, reserving ship loss exclusively for combat[cite: 3, 4].

Give Chorus an Active In-Battle "Feeding" Mechanic (port_notes_r42.txt Battle section, NEM_FAC.chorus.beh): So that Chorus still behaves distinctly when the player has lost 0 ships on the campaign map (fed === 0), let Chorus ships also heal hull or gain a temporary damage/hull buff during battle whenever any ship or wing on either side is destroyed, in addition to the campaign nemFeedLosses tracker (Design judgement)[cite: 4, 5].

Block Contradictory Trait/Weakness Pairs (port_notes_r42.txt Campaign section, newNemesis): When shuffling NEM_WEAK in newNemesis(), exclude slow if the Nemesis rolled swift, exclude board if he rolled boarders, exclude brawl if he rolled zeal, and exclude torp if he rolled brood[cite: 4, 5].

Fix the Ithar Description and AI Mismatch (data_nemesis.txt NEM_FAC.ithar.beh.d and port_notes_r42.txt nemFleeCheck): Align the shield threshold between beh.d ("shields are all down", shields: 1) and nemFleeCheck() (every flagship shield <= .5), and either grant Ithar innate focusWeak in nemTargetBonus or remove "picks off your weakest ship" from NEM_FAC.ithar.beh.d so it doesn't lie when he rolls proud or patient[cite: 4, 5].

Auto-Reveal Weaknesses When Triggered in Battle (port_notes_b4.txt Campaign/Battle sections): Push a weakness key into RUN.nem.revealed the first time the player triggers it in combat (for example, landing a rear hit on flank, hitting shields with ion/lance on ion, or triggering anchor at < 60% hull) so the player sees the memory card update after discovering a weakness in play[cite: 3, 5].

UNSURE List (Not Established by the Evidence Pack)

UNSURE (Godot UI Card & Telegraphs): How and when the Godot client displays RUN.nem on the campaign map (NEM_FAC[fac].beh.d, traits, revealed vs unrevealed weaknesses, adapt, fed, riches, and the NEM_CLOCK meter) before the player enters a node is not shown in the JS rules oracle files[cite: 2, 3, 4, 5].

UNSURE (Corsair raid and Deathless tithe vs Battle Node Spawn): In port_notes_b4.txt, reaching clock 4 sets strike, and nemNodeIs(n) turns the next unmet battle/elite node into the Nemesis battle[cite: 3]. In port_notes_r42.txt, "On filling: nemStrike(): raid (Corsair...), tithe (Deathless...); other strikes act in battle"[cite: 4]. The pack does not establish whether raid and tithe happen in addition to turning the next battle/elite node into the Nemesis fight, or whether they consume strike and reset the clock without spawning a battle until column >= cols - 3[cite: 3, 4].

UNSURE (Deathless tithe Floor at 1 Hull): port_notes_r42.txt states "tithe (Deathless: every ship loses 6% max hull, min 1)"[cite: 4]. It is unsure whether min 1 means each ship loses at least 1 HP (which could destroy a ship sitting at 1 HP on the campaign map, violating R7) or whether each ship's remaining hull is clamped to a minimum of 1 HP (matching speed -1, min 1 in port_notes_b4.txt)[cite: 1, 2, 3, 4].

UNSURE (Hegemony formation: 1 Innate vs Special): data_nemesis.txt sets formation: 1 inside NEM_FAC.hegemony.beh AND defines special: {id: 'formation', ...} in NEM_ADAPT_FAC.hegemony[cite: 5], while port_notes_r42.txt only mentions formation enemy sync radius +1 under specials[cite: 4]. It is unsure whether Hegemony gets +1 sync radius innately, only from the special adaptation, or both (+2 total)[cite: 4, 5].

UNSURE (Story Helper's Rival Line Pools): Both port_notes_r42.txt and data_nemesis.txt note that NEM_LINES are placeholders until "the story helper's rival line pools arrive"[cite: 4, 5]. The pack does not include those expanded pools or establish whether they branch by faction, scar cause, or prior fight outcome[cite: 4, 5].
