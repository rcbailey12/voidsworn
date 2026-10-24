# Pack I: Enemy AI and Encounter Audit (DeepSeek)

Filed by Rey from Ryan's paste, Oct 23, 2026. Model: DeepSeek (attribution confirmed by Ryan). Charter and pack: contrib/muse/prompts/ (Pack I). Screening: contrib/muse/reviews/packFGHI_screening.md. Filed as returned, with em dash separators normalized to house style; claims are the model's own and are not verified by filing.

---

Voidsworn: Enemy AI & Encounter Audit
Pack audited: battle.js, data.js, core.js, sim3d.js, plus the simulation annex. Every finding names file, line and quoted source. No outside knowledge used.

1. The AI only plays five of eight objectives, and two of those five only on "veteran": OBSERVED
aiObjScore (battle.js:738–752) is the only objective term fed into movement scoring (called at battle.js:1122, score+=aiObjScore(u,v);). It has branches for hunt, defend, break, and (gated) intercept and hold:

battle.js:747: if(vet&&o.type==='intercept'){ let d=99;

battle.js:748: if(vet&&o.type==='hold'){

rout, ambush and flagship have no enemy objective term at all. In Decapitation the enemy does not defend its flagship unless vet and only via the escort-spacing block at battle.js:1108: const flE=vet0&&B.obj&&B.obj.type==='flagship'&&!u.flagship&&!u.isSq?.... On standard, the enemy flagship is just a high-CP ship that fights.

Worse, the objective pull is straight-line, not path-aware: battle.js:742 return -Math.max(0,hdist(v,o.hex)-2)*3*urg; and battle.js:751 return -d*1.6*urg+(held&&d<=1?4:0);. The AI computes pathField for foes (battle.js:1106) but never for the station or relay. On Dense/Archipelago/Colossus maps a rock wall between the enemy and the objective makes it press against the wall rather than route around. Counter the AI never learns: park the relay/station behind terrain and let it grind.

2. Faction doctrine is three scalar knobs in one shared evaluator; range/rw are data-only unless the AI level is veteran: OBSERVED
The six factions do not have six decision procedures. The entire faction-sensitive tactical input is one table, FACTION_AI (data.js:985–991), consumed at a single site:

battle.js:1114: const prof=(!u.isSq&&FACTION_AI[u.fac])||FACTION_AI.voidsworn

battle.js:1116: if(vet&&!u.isSq&&prof.range){

tw and hurt always apply; range and rw are wrapped in vet. RAM_FAC is likewise vet-gated at battle.js:1117, if(vet&&!u.isSq&&RAM_FAC[u.fac]) score+=ramSetup(v,u)*.35;. Locus verdict: the difference lives in the data tables and the hull rosters, not in the decision code. The only genuinely per-faction code branches are:

battle.js:912: if(set&&u.side==='enemy') return own; (enemy carriers never mix wing types),

battle.js:318: cfg.fac==='chorus'?'spores':'flak' (the carrier-adaptation refit).

Everything else (MOVE_RULES (data.js:103–109), FAC_WTRAIT (data.js:54–56), BOARD_MULT/CREW_MULT (battle.js:81–82), BOSS_CMD (battle.js:864), ability sets) is data consumed by a shared path. Data-only doctrine never enforced: on standard AI, FACTION_AI.range and rw are dead code. Hegemony's "hold a gun line at range", Corsair's "close fast", Ithar's "hit and fade" and Deathless's "advance" all collapse to the same tw/hurt weighting. Whether that matters depends on the shipped AI_LEVEL, which is not in this pack (see Questions).

3. Difficulty is multiplicative stat scaling, not decisions: OBSERVED
The AI's competence is a single global boolean (aiVet(), battle.js:993) and never rises with sector, column, elite status or heat. The sector curve is pure numbers:

battle.js:310: const sc=1+.12*(s-1), dm=1+.08*(s-1);

battle.js:133: let budget=[0,4.2,9.5,14][s]+col*(...)

battle.js:313: elite:!!(eliteIdx&&eliteIdx.has(ei)) feeding aim:(opts.elite?6:0) and elite?1.1:1 hull (battle.js:101–102).

The annex bears this out: S1 battle 100% → S1 elite 73% → S2 elite 57% → S3 elite 53%, while bosses read 77/87/100. The "wall" is the elite stat bump (half the fleet gets +10% hull, +6 aim, +5 crit), not a smarter opponent. The annex's own note that S3 boss 100% is "an artifact of the scripted dreadnought fleet" confirms that where the numbers are favourable the AI cannot convert them.

4. The 35% CP auto-rout is a universal attrition win button that bypasses Hold, Break and Relay: OBSERVED
battle.js:786: if(bossDown||sideCP('enemy')<=B.cp0.enemy*.35){ B.over='win'; B.routed=true;

The guard immediately above excludes only two objectives: battle.js:784 if(!B.cp0||(o&&(o.type==='intercept'||o.type==='hunt'))) return;. So in defend, hold, break, rout and flagship, killing 65% of the enemy's starting CP wins outright. You never have to run the Breakthrough gauntlet, never have to hold the relay for three rounds, never have to keep the station's integrity above zero. The AI does not know this rule exists: nothing in aiObjScore or aiUnit prices "don't let CP drop below 35%". Counter it never learns: ignore the objective, kill the cheapest ships.

5. Intercept's win check rewards the enemy convoy escaping: OBSERVED
battle.js:778: if(o.esc>o.total-o.need){ B.over='win'; B.partial=true;

With o.need=Math.max(1,tr.length-1) (battle.js:722), three transports give need=2 and total-need=1. Killing two wins (battle.js:777). Two escaping also wins: the branch sets B.over='win' and logs "Enough transports got through. The escorts break off." in the enemy colour. The only remaining loss path is caps('player').length===0 (battle.js:775). Intercept is therefore close to unloseable unless your fleet dies; the AI escorts' veteran-only screening term (battle.js:747) is irrelevant because the objective decides itself. Whether B.partial downgrades the reward is not determinable from this pack.

6. Enemy boarding is structurally near-unused, and player ships can never be captured: OBSERVED
Three independent gates stack:

Adjacency is required at the moment of boarding, after movement: battle.js:653 filter(t=>!t.isSq&&hdist(u,t)===1), called at battle.js:1135 with no boarding term anywhere in the movement score.

A 70% odds floor: battle.js:685: const v=o.chance>=70?100+t.maxHp/10:0;

Player hulls are immune to capture: battle.js:675: // your ships are never captured: boarders cripple, they don't steal.

The annex confirms the outcome: "player 6, enemy 0" boardings across 432 fmatrix battles, and 0.5 boardings / 0.20 captures per battle in matrix 10 sk. The AI has a boarding tactic that its own movement planner never sets up. Counter it never learns: keep crew high and the enemy will never attempt a capture; it will only ever sabotage.

7. Firing is competent at target re-picking but has two fixed blind spots: flak is never offensive, and torpedoes are never held: OBSERVED
The one genuinely sophisticated piece is per-gun re-selection: battle.js:1048 const primary=aiPickPrimary(u,ws,focus); and the shield-stripper ordering at battle.js:1040. But:

Flak is excluded from all offensive fire: battle.js:456 ||w.k==='flak') return false; and battle.js:1047 w.k!=='flak'. Enemy flak only ever fires as interception (battle.js:574–582) or rocket point-defence (battle.js:590). Your squadrons are safe from enemy flak on the enemy's own turn; they are only at risk when they attack.

Torpedoes (cd:2, evMult:2, data.js:8) are fired at the first legal target with bv>0.5 (battle.js:1057 if(bt && bv>0.5){). No hold-fire, no waiting for a stripped shield or a stationary hull. Counter it never learns: an evasive screen (high ev, doubled against torpedoes) soaks salvos that would otherwise be spent on your line.

8. The enemy flagship has no survival behaviour of its own; in Hunt it kites to a fixed 9 hexes and stops: OBSERVED
battle.js:740: if(o.type==='hunt'&&u.flagship){ const d=Math.min(30,...caps('player').map(p=>hdist(v,p))); return Math.min(d,9)*3; }

The pull saturates at 9 hexes, so the hunted flagship runs to range 9 and then reverts to ordinary offence/threat scoring. It does not head for the map edge; escape is a round-6 scripted removal (battle.js:761), not a destination. In Decapitation there is no term at all. Escort screening exists only on veteran and only for flagship (battle.js:1108). Separately, boss escorts are deleted at 50% boss hull: battle.js:349 if(!boss||boss.hp>boss.maxHp*.5) return;: and the boss loses regen and half its shields (battle.js:351). Counter it never learns: in Hunt, herd the flagship away from its escorts and ignore it until the clock forces it; in Decapitation, kill the boss while its escorts behave like any other ship.

9. The enemy has no Commands except one boss Command, telegraphed a round ahead and cancelled by killing the flagship: OBSERVED
battle.js:846: function canCommand(side){ return !!B&&!B.over&&side==='player'&&...: the enemy can never use the player Command system. Its only equivalent is BOSS_CMD (battle.js:864), fired once at tier 1 via battle.js:869 await runCommand('enemy',c,1);, announced in advance at battle.js:867, and cancelled by the flagship dying first: battle.js:868 if(!boss){ B.cmdEUsed=true; return; }. Non-boss enemy fleets, including elites, have no fleet-wide action at all. Counter it never learns: focus the boss during the telegraph round and the Command never happens.

10. Encounter and map variety are broader on paper than in the AI's hands: OBSERVED
Boss fights collapse to a coin-flip Engagement: battle.js:68 const enc=pick(['rout','rout','ambush','flagship']);: 50% rout.

The first fight of every sector is always a rout: battle.js:69 const enc=col===0?'rout':pick(ENC_POOL);.

Complex geometry can silently become open: battle.js:302–303 for(let k=0;k<6;k++){ T=genTerrain(map,shape,topt); if(terrainConnected(T)) break; T=null; } if(!T){ shape='open'; ...}. The harness has a shapecheck mode (sim3d.js:317) but its fallback counts are not in the annex, so the leak rate is unknown.

The dead-star slingshot is never used deliberately: wellTick grants +1 movement at ≤6 hexes (battle.js:273) but aiWellScore returns only penalties: battle.js:277 return d<=WELL_RIM?-45:d<=WELL_PULL?-6:0;. The AI avoids the well; it never rides it.

SECTOR_CONDS.war promises "reinforcements for one side or the other" (data.js:372) but no code in this pack reads .war; rollBattleEvent is defined (battle.js:26) and never called inside startBattle. Whether the UI sets B.event is outside the pack.

The annex's enccount (near-uniform across eight types) measures the roll, not the fight: three of those eight have no AI objective behaviour (Finding 1), so the effective variety is roughly five.

Not checked
Rendering/UI files: not in the pack. All player-facing prompts, toasts and manual-fire affordances are invisible here.
The shipped value of AI_LEVEL (and whether the browser build defines it at all). aiVet() defaults to 'veteran' when undefined (battle.js:993) and sim3d.js:8 sets it from the environment, but neither is the game's own default.
Whether B.alt (alternating activations) is on by default in the shipped build. Half the AI's threat model (aiGunLive, battle.js:1000) branches on it.
Where B.event is assigned and whether rollBattleEvent is called at all outside the harness.
Everything downstream of battle end: rewards, B.partial, B.withdraw, retreat handling, salvage.
ARCHETYPES display plumbing and the consumers of SECTOR_CONDS.cred: neither is in this pack.
I did not run the simulator; all annex figures are taken as reported.

Questions this pack cannot answer
What is AI_LEVEL in the shipped game, and is it per-difficulty, per-sector, or fixed? Findings 1, 2, 8 and 9 change materially between standard and veteran.
Is B.alt true in normal play, or only in the harness's alt mode? aiGunLive and the "spent gun" threat model assume it.
Where is B.event populated? rollBattleEvent exists but has no call site in startBattle, so mid-battle events may be dead in the shipped build or wired from a file not in this pack.
Does SECTOR_CONDS.war do anything? .war is never read in battle.js, data.js, core.js or sim3d.js.
Is B.over='win' with B.partial=true (Intercept, battle.js:778) treated as a win for progression, a draw, or a loss? The end-of-battle flow is not in the pack.
How often does genTerrain fail terrainConnected six times and fall back to 'open'? shapeCheck measures it (sim3d.js:317–324) but the annex does not report its output.
Does the player UI allow firing flak manually? canFire (battle.js:456) says no; if the UI has a separate path, flak's offensive blindness is an AI-only asymmetry rather than a rules one.
Is the 50%-hull escortsBreak (battle.js:349) intended for every boss encounter, including non-boss flagship objectives where cfg.kind!=='boss' and the function returns early?
Why does the annex's campaign table use fixed per-sector fleets rather than admiral starting fleets? The pack cannot say whether the elite wall (S2 57%, S3 53%) survives with grown fleets.
The annex reports fmatrix Hegemony 100% vs Voidsworn and matrix Hegemony 55% average: is the inversion a fleet-composition artefact (the annex says the two modes draw from different sources) or does it point at the Voidsworn roster's damage profile? Neither table in this pack can settle it.
