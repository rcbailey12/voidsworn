Gemini (Argon High) blind leg, Oct 28 program item 2 (rewards audit). Filed as a single reviews copy per house rule, with this chair header. Em and en dashes in the original normalized to hyphens; wording otherwise verbatim. Method note from the run: fresh Gemini chat signed in as rcbailey12@gmail.com (Pro), 4 Argon selected with Thinking level High, picker button and prompt bar both verified "Argon High" before sending and the picker still read "Argon High" after; both files uploaded together with no error tiles; completed in one chat with no retry, no rate limit and no traffic check. Chat: https://gemini.google.com/app/31a98c1712ed34cf

1. Proof of Reading & Overall Verdict

data.js lines 150-200: MODULES and RELICS

data.js lines 617-697: PATRONS intro, BOONS (all 48), ASPECTS (all 6)

core.js lines 175-250: fleetKit, modulePool, relicUseful, rollBoonOffer, rollNodeReward

campaign_run.js lines 390-544: the full post-battle reward flow (rewardFlow, prizeStep, salvage, rewardNext, boonStep, reroll, relicStep, promotions)

OVERALL VERDICT: REWARDS ARE MIXED - Kit-filtered protocol drafting creates genuine fleet-building identity, but dominated node payouts, solved strip-versus-scrap/ransom math, non-scaling rarities on 8 of 36 core protocols, and pool-exhaustion reroll traps reduce several reward steps to solved formalities.

2. Findings (Ranked Most Severe First)

[FIX] Six rule-changing protocols and two Rare-capped protocols ignore rarity scaling (or Epic scaling), breaking the rarity promise.

OBSERVED: REWARD_DEF.boon promises "Rarity sets how strong it is." and data.js states "rarity scales their strength (Common x1, Rare x1.5, Epic x2).". However, the 6 rule-changing protocols (i_wall, s_chain, h_brood, a_mark, r_slip, e_spread) sit in the normal patron pool (!BOONS[id].leg), roll Common/Rare/Epic via rollRarity(minR,s,p), and use zero-argument d:()=> and fx:()=> functions that ignore m completely. Additionally, h_hatch (hangar:m>=1.5?2:1) and e_reload (torpCd:m>=1.5?2:1) cap at m>=1.5, making Epic (m=2) identical to Rare (m=1.5).

INFERRED: Across the 36 non-legendary core protocols, 8 (22.2%) gain zero statistical benefit when upgraded from Rare to Epic, and 6 gain zero benefit from Common to Epic, turning high-rarity rolls at Elite/Boss nodes (min: 1) into visual placebos that only grant extra meta-favour (+1+(o.r||0)).

[FIX] Rerolling a protocol offer when a patron has ≤3 eligible protocols left charges credits to return the exact same 3 protocols.

OBSERVED: boonRerollOk() only checks !!(RUN&&RUN.reward&&!RUN.reward.rerolled&&RUN.credits>=boonRerollCost()) without checking remaining pool depth. Each patron has only 6 non-legendary protocols, and BOON_NEED filters out up to 5 of them (hunger requires 'carrier' or 'sq' on 5 of 6; ember requires 'torp' on 3 of 6). When boonReroll runs for(let k=0;k<4&&off.length&&off.every(o=>old.includes(o.id));k++) off=rollBoonOffer(p,minR);, if pool.length <= 3 and no Duo triggers, all 5 roll attempts return the exact same 3 protocol IDs.

INFERRED: A player without torpedoes at an Ember node (where only e_kindle, e_chain, and e_hunt pass boonUseful), or any player who already holds 3 protocols from a patron, can pay 25 + 15*n credits to reroll and receive the exact same 3 protocols with only re-rolled rarities.

[FIX] Declining a protocol pays 30 + 10*s credits, making cred map nodes (35 + 10*s) nearly strictly dominated by boon nodes.

OBSERVED: In rewardFlow, a cred node pays const v=35+10*s; RUN.credits+=v; (45 / 55 / 65 credits in Sectors 1 / 2 / 3). In boonDeclineCred(), declining a protocol offer pays return 30+10*((RUN&&RUN.sector)||1); (40 / 50 / 60 credits in Sectors 1 / 2 / 3).

INFERRED: Because the map shows node rewards in advance, choosing a cred node over a boon node sacrifices a free look at 3 permanent fleet-wide protocols (and potential Rare/Epic/Duo rolls) for a net gain of just 5 credits.

[FIX] L_storm (Eye of the Storm) is missing from BOON_NEED, so shieldless fleets are force-offered a useless shield Legendary.

OBSERVED: L_storm grants "Legendary. Every shield facing on every ship refills completely at the start of each of your turns." (fx:()=>({stormRegen:1})). While s_cap, s_regen, and d_bastion are gated by 'shields' in BOON_NEED, L_storm is omitted from BOON_NEED.

INFERRED: A shieldless fleet (!kit.shields) that takes two non-shield Vyre protocols (s_ev, s_ion, s_arc, or s_chain) satisfies legendaryFor('storm', minR) at every Vyre Elite or Boss node, permanently locking slot 3 (out[2]) to a completely useless Legendary until taken.

[FIX] legendaryFor is 100% deterministic at Elites/Bosses, silently overwrites Duo rolls in out[2], and ignores rerolls.

OBSERVED: In rollBoonOffer, a Duo roll assigns if(out.length>=3) out[2]=d;, and two lines later legendaryFor(p,minR) assigns if(out.length>=3) out[2]={id:L,r:3};. legendaryFor has no probability check: once a player holds n>=2 non-legendary protocols from patron p, it always returns L when minR>=1.

INFERRED: Once a player holds 2 protocols from patron p, any Duo rolled at an Elite or Boss node for p is silently overwritten by L, and clicking Reroll (boonReroll) only rerolls slots 0 and 1 while keeping L locked in slot 3.

[FIX] Wreck salvage (salvageStep) has a solved Strip-versus-Scrap economy and makes 4 of 13 modules unreachable from wrecks.

OBSERVED: salvageYield computes scrap credits as cred=Math.round((10+9*w.cp)*(intact?1:1.3)) (19, 28, or 37 credits for intact 1-3 CP hulls), whereas MODULES cost 55 to 90 credits. Furthermore, pickM only checks 9 module IDs (crystal, magazine, loaders, flakplus, hangar, cogitator, damcon, capacitor, auspex) and takes m=intact&&pickM.length?pickM[0]:null.

INFERRED: Whenever an intact wreck yields a useful module, stripping a 55-90 credit refit dominates scrapping for 19-37 credits; meanwhile, prow, drive, gyro, and regen can never drop from wrecks, and capacitor/auspex at the end of pickM are shadowed whenever the enemy ship also carried a matched weapon.

[FIX] Prize capture (prizeOffer) guarantees a module on Strip, making Strip dominate decayed Ransom, and applies ransom decay in fixed array order.

OBSERVED: prizeOffer guarantees a module even when salvageYield returns none via mod=y.mod||(pool.length?pool[Math.floor((v*7+(p.cp||1)*13)%pool.length)]:null) plus Math.round(v*.15) credits, while prizeRansom pays Math.round(shipValue(p.tpl)*.55*(.6+.4*(p.hpf||1))*Math.max(.4,Math.pow(.85,n||0))). In prizePlan, R.prizes.map((p,i)=>...) walks prizes in fixed battle order, incrementing nR++ whenever k==='ransom'.

INFERRED: On damaged hulls or after a few prior ransoms (where prizeRansom drops as low as 0.55 * 0.6 * 0.4 = 13.2% of shipValue, less raw cash than Strip's flat 15% before even counting the free 55-90 credit module), Strip strictly dominates Ransom. Additionally, if a player ransoms one ship and strips another in the same multi-prize screen, they cannot control battle order, though nR only increments on ransomed rows; if they ransom two ships of different values, the first in array order always gets the higher multiplier 0.85^nR.

[FIX] Cross-patron spillover in rollBoonOffer drops favourTier rarity bonuses and renders under the wrong patron's header and colour.

OBSERVED: When out.length<3, extra pulls protocols from other active patrons (BOONS[id].p!==p) and calls rollRarity(minR,s) without the third argument p, so const ft=p?favourTier(p):0 evaluates to 0. In boonStep, every non-duo option renders with style="border-left:4px solid ${duo?PATRONS[duo[0]].col:P.col}".

INFERRED: When a non-carrier fleet visits Crucible (hunger, where only 1 of 6 protocols passes boonUseful), 2 of the 3 offered protocols are pulled from other patrons, lose the player's meta-progression favourTier rarity boost (including the guaranteed Rare floor if(ft>=3) r=Math.max(r,1)), and display with Crucible's green border without indicating which patron they actually belong to.

[NOTE] Single-ship modules (MODULES) are numerically outclassed by Common fleet-wide protocols (BOONS), and mod nodes lack Reroll or Decline options.

OBSERVED: MODULES.crystal grants "Lance damage +25%." to a single ship, while Common a_lance grants "Lances deal +35% damage." to the entire fleet; MODULES.drive grants "+1 speed." to one ship, while Common r_burn grants "+1 speed across the fleet". Furthermore, ACT.rewardNext for rw.k==='mod' offers 3 modules with no Reroll and no Decline-for-credits button.

INFERRED: Once a fleet has multiple ships, a mod node (16% of normal nodes) delivers a fraction of the power of a boon node (62%) and cannot be converted into credits if all 3 modules are unwanted.

[NOTE] Incomplete Duo coverage (6 of 15 patron pairs), overlapping ram immunity (ramGuard: 1), and misleading d_inferno fire text.

OBSERVED: Only 6 Duo protocols exist across the 15 possible pairs of 6 patrons, and Crucible (hunger) is only paired with Seren (duo:['hunger','ember']). Meanwhile, ASPECTS.ram, d_jugg, and L_rook all grant ramGuard:1 (no recoil), and d_inferno states "your fires burn hotter (10 a turn)" while adding fireDmg:4 on top of e_kindle's fireDmg:Math.round(4*m).

INFERRED: Builds combining Crucible with Kharon, Vyre, Astra, or Rook have zero Duo payoffs; Rook ram builds hit redundant recoil immunity across Aspect, Duo, and Legendary tiers; and stacking e_kindle with d_inferno produces 14-18 fire damage per turn rather than the 10 stated on the card.

3. Explicit Checks

a. THE OFFER
Within a single patron offer, picking 1 of 3 protocols is usually a real tactical choice between weapon scaling, defense, and positional rules (such as Kharon's i_still stationary bonus versus i_line formation defense), aided by fleetKit() filtering out dead weapon tags. However, the Reroll vs. Decline economy is skewed: normal battles pay Math.round((25+12*s+3*(cfg.col||0))*kindMult*(1+(rf.credPct||0)+((scnd&&scnd.cred)||0))) (~37-52 base credits in Sector 1, ~61-76 in Sector 3), while Declining pays 30 + 10*s (40 / 50 / 60 credits) and Rerolling costs 25 + 15*n (25, 40, 55, 70 credits). Because choosing Reroll over Decline represents a 65-credit net swing on the very first reroll in Sector 1 (and 95+ credits by the second reroll in Sector 2) - and because a 6-protocol patron pool often has only 0 to 3 unseen eligible protocols left to roll into - Declining a weak offer is mathematically strong, whereas Rerolling past the first 25-credit use is a trap unless hunting a specific Epic or Duo.

b. THE DISTRIBUTION
Showing the node reward type (boon with patron sigil, mod, cred, repair) on the map in advance turns routing into a mostly solved hierarchy rather than a balanced four-way trade-off. Because a boon node (62% of normal nodes, 100% of elites/bosses) grants a fleet-wide multiplier and carries a 30 + 10*s credit Decline floor that is only 5 credits less than a cred node's entire 35 + 10*s payout, cred nodes (12%) are strictly inferior to boon nodes on the map. Similarly, mod nodes (16%) upgrade only a single ship with no credit-decline fallback, and repair nodes (10%, healing 25% * repairMult()) pay nothing if the fleet is healthy. Strategic routing only happens when comparing which patron sigil to visit (to hit n>=2 for a Legendary at an upcoming Elite/Boss or unlock one of the 6 Duos) or taking an emergency repair node when low on hull.

c. SOLVED CHOICES
The reward layer shares the events audit's disease in three specific places:

Map Node Types: boon nodes dominate cred nodes (40/50/60 credit decline floor + free look at 3 protocols vs. 45/55/65 flat credits).

Wreck Salvage (salvageStep): On intact wrecks that yield a module, Strip it (a 55-90 credit module) dominates Scrap it (10 + 9*cp = 19-37 credits), and for Corsairs, Tow it home (a 1-2 CP ship joining at 35% hull) dominates scrapping whenever command points allow.

Prize Capture (prizeStep): prizePlan's own default logic (dk=room&&(p.hpf||1)>=.4?'add':sv>=o.ransom?'strip':'ransom') reflects that Add is automatic whenever CP allows on a healthy hull, and Strip (15% hull value in credits + a guaranteed 55-90 credit module) rapidly dominates Ransom (55% * (0.6 + 0.4*hpf) * max(0.4, 0.85^n)), which decays down to 13.2%-22% of hull value after repeated ransoms or battle damage. Within protocol offers, choices are less solved, though L_storm on a shieldless fleet is a dead slot and rule-changing protocols rolled at Rare/Epic waste their rarity multiplier.

d. THE POOL
For a 3-sector run, the pool is too shallow, and repetition sets in by the middle of a single run and across runs by Run 3-5. Although there are 48 protocols total, only 4 of 6 patrons are active per run (24 non-legendary protocols + 4 Legendaries + at most 2-4 Duos), and BOON_NEED filters out 4 to 9 protocols that do not match the fleet's weapons/shields/carriers, leaving only ~15-20 eligible protocols per run. Because each patron has only 6 non-legendary protocols, visiting the same patron 3 times shows nearly its entire kit-eligible roster. Modules (13 total, with 4 unreachable in salvageYield and others filtered by MOD_NEED), Relics (12 total, seeing 2 per Elite and 3 per Boss across 3 sectors with no duplicates), and Aspects (6 total, seeing 3-4 per run) are likewise exhausted within a few runs.

e. THE CHAIN
The post-battle sequence is prizeStep → salvageStep → rewardNext (boonStep or takeMod) → relicStep → promotionsStep. boonStep and relicStep carry the most genuine decision weight (shaping fleet-wide rules and synergies), whereas salvageStep and prizeStep are largely click-throughs (in fact, prizeStep pre-selects the mathematically optimal default via prizePlan so the player only clicks Confirm, and salvageStep comes down to clicking the wreck with the best module). Put in this order, the chain helps in two ways: (1) adding/towing a ship in prizeStep or salvageStep updates RUN.fleet before boonStep or modOffer lazily calls fleetKit(), immediately unlocking new weapon/carrier protocols, and (2) ransoming/scrapping banks credits right before the player needs cash for boonRerollCost(). However, the order hurts when choosing between a module (Strip) and cash (Ransom/Scrap) in steps 1-2 before seeing whether step 3 (boonStep) will demand 25-55 credits for a reroll, and when picking a protocol in boonStep before seeing the 2-3 relics in relicStep.

4. Run 1 / Run 5 / Run 10 Progression

RUN 1: The reward layer feels rich and thematic. Choosing 1 of 3 flagship ASPECTS (lancer, hive, ram, bulwark, storm, admiral) sets an immediate tactical hook, fleetKit() prevents frustrating dead offers, and discovering how two patrons unlock a Duo or how holding 2 protocols from one patron unlocks its Legendary at an Elite/Boss feels rewarding. Because META.favour starts at 0 (favourTier(p) === 0), Sector 1 protocol offers roll mostly Common (70% Common, 24% Rare, 6% Epic).

RUN 5: The seams and solved math become visible. The player has seen all 6 Aspects, all 12 Relics, and all 13 Modules, and realizes that only 9 modules ever drop from wrecks in salvageStep. Meanwhile, picking protocols in earlier runs has accumulated META.favour[p] += 1 + (o.r||0), crossing favourTier(p) >= 1 (+12% Rare, +3% Epic) and eventually favourTier(p) >= 3 (which forces r = Math.max(r, 1), guaranteeing Rare-or-better on every primary patron roll!). Ironically, this makes the non-scaling bug on the 6 rule-changing protocols (i_wall, s_chain, h_brood, a_mark, r_slip, e_spread) and the Rare cap on h_hatch/e_reload much more noticeable.

RUN 10: With favourTier >= 3 on favourite patrons and meta unlocks like META.unlocked.salvagers (+20% battle credits) and META.unlocked.wrights (0.85x shop/track prices), protocol offers are permanently Rare/Epic, and routing is completely solved. The player never routes to cred nodes (knowing boon nodes decline for 5 credits less), always strips cheap prizes instead of ransoming, knows never to click Reroll when a patron's 6-boon pool is down to 3 eligible options, and deliberately forces the guaranteed slot-3 Legendary (legendaryFor) at the first Elite after taking 2 protocols of their primary patron.

5. Not Checked

This evidence pack does not contain and therefore does not allow judging:

Captain Promotion Modal (promoteModal): How many perks from PERKS (14 total) are offered per promotion, whether perks can be rerolled, or whether kit-specific perks (broad, lanceadept, wing, deflector) are filtered by ship/fleet kit.

Missing Constants & Helpers in data.js / core.js: The exact definition of MOD_NEED, FAVOUR_TIERS thresholds and favourTier(p) calculation, HULLS base stats/costs, W weapon stats, KILL_CAUSES (scrap flags), sectorCond(), and factionGate().

Sector Map Topology (genSector): How many total battles, elites, shipyards, and events occur per sector, and how restrictive map branching is when routing around cred or repair nodes.

Combat Resolution (battle.js): How sumFx aggregates non-additive keys like ramGuard or critSys, and whether protocols that rarely trigger in combat (summary.boonStats) underperform their text descriptions.

6. Questions for the Designer

Rule-Changing & Rare-Capped Protocol Rarity: Should the 6 rule-changing protocols (i_wall, s_chain, h_brood, a_mark, r_slip, e_spread) gain numeric scaling with rarity m (and h_hatch/e_reload gain a distinct Epic tier at m=2), or should rule-changing protocols be given a fixed non-scaling rarity tier like Duo protocols so Rare/Epic rolls aren't wasted on them?

Map Node Payout Balance (cred vs. boonDeclineCred): Since declining a protocol pays 30 + 10*s credits and a dedicated cred node pays only 35 + 10*s credits, do you want to raise cred node payouts (e.g., to 75-100+ credits) so cred nodes represent a real economic temptation over a boon node?

Deterministic Legendaries & Duo Collisions: Is legendaryFor intended to be a 100% guaranteed offer in out[2] at every Elite/Boss once n >= 2 (overwriting rolled Duos and persisting through rerolls), or should Legendaries be a weighted roll and/or occupy a separate slot from Duos?
