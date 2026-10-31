# Red team audit, gamedev persona: Argon leg

Chair header: Argon (Gemini, Argon High) leg for the Oct 30, 2026 red team audit, run from the gamedev evidence pack and the persona leg prompt. Text below is the model report verbatim, with em dashes normalized to ASCII where they appeared.

1. [OBSERVED] Overturn of Wave 5 battleship_entry Verdict: d_meridian Mounts a Dead Fifth Weapon, Duplicates Cruiser Firepower, and Drops Its Capstone Ability

What breaks or underperforms: Prior legs (DeepSeek, Qwen) and the chair cleared d_meridian in battleship_entry_2026_10_29.md as "ENTRY SOUND with no BLOCKER or FIX". That verdict is overturned by battle.js and data.js:

Inert fifth weapon mount and exposed duplicate: d_meridian mounts both gsentry and flak on the same hull. In battle.js, canFire blocks active firing for all flak-kind weapons, and startSideTurn assigns point-defense intercepts using a boolean .some() check rather than counting mounts. Because both gsentry and flak have k:'flak', the second point-defense weapon cannot fire actively and adds zero intercepts (staying capped at 2). Worse, it places both identical point-defense keys side by side on the same ship card.

Flat offensive firepower across the entire Eclipse capital line: d_meridian (cp:6, 590 credits) carries the exact same offensive weapons (2x gauss, 1x doom) as the cp:4 cruiser d_harvester (390 credits) and the cp:12 boss d_boss.

Ability regression: Despite the synthesis direction to give the battleship a distinct Eclipse ability, d_meridian reuses ab:'phase', the baseline frigate and destroyer ability.

Evidence:

battleship_entry_2026_10_29.md: "w:[['gauss','T'],['gauss','T'],['doom','F'],['gsentry','T'],['flak','T']],ab:'phase',regen:6,reanimate:true"

battle.js: "function canFire(u,w,t){ if(u.dead||t.dead||u.side===t.side||u.braced||w.k==='flak') return false;"

battle.js: "u.intercepts = u.weapons.some(w=>w.k==='flak')?2:0;"

weapons_synthesis_2026_10_29.md: "Identical in every field including kind: {shots:3, dmg:3, r:2, opt:2, acc:80, fall:10, vsSq:3, vsCap:.6}."

factionshape_synthesis_2026_10_29.md: "the battleship's signature should be a new ability in Eclipse's idiom"

What it costs the game: Landing d_meridian as written introduces a 590-credit, 6-CP capital ship whose only weapon addition over the 390-credit, 4-CP cruiser is a non-functional fifth slot that exposes the gsentry/flak duplicate directly in the HUD.

2. [OBSERVED / INFERRED] Overturn of Wave 5 patch_pack Section 1: Pre-Move evalOffense Check Causes Moving Veterans to Abort Attacks and Brace in Place

What breaks or underperforms: We confirm the ai_synthesis finding that mid-move firing bypasses the veteran brace check, but we overturn the Chair's fix in patch_pack_2026_10_29.md Section 1. The patch evaluates myOff=evalOffense(u,u.weapons.filter(weaponReady),pf) before calling await moveUnit(u,best,undefined), dismissing the pre-move evaluation as a rare marginal flip. In battle.js, inReach(u,w,t) checks distance (d>w.r) and firing arc (inArc(u,t,w.arc)) from u's current position and facing. (INFERRED from inReach and the diff): Whenever a damaged veteran (u.hp<u.maxHp*.7) under threat (thr>u.hp*.45) starts its turn outside weapon range or with fixed-arc guns (F, P, S) pointed away from the target, its pre-move myOff is 0 (< thr*.35) specifically because it has not moved or turned yet. Under the patch, the ship executes its offensive move best.path into enemy fire, then immediately braces and returns without firing or checking boardTargets(u).

Evidence:

patch_pack_2026_10_29.md: "threat and offense are evaluated from the pre-move position" and "so marginal flips should be rare."

patch_pack_2026_10_29.md: "await moveUnit(u,best,undefined); if(!live()) return; giveOrder(u,'brace'); B.aiActive=null; u.activated=true; return;"

battle.js: "function inReach(u,w,t){ const d=hdist(u,t); if(d<1||d>w.r) return false; if(!inArc(u,t,w.arc)) return false; return los(u,t); }"

What it costs the game: Damaged veteran hulls using short-range or fixed-arc kits (tendril at r:1, scatter at r:3, or any F/P/S weapon rotating into arc during movement) will drive into close-range kill zones along best.path and forfeit their attack to brace. The brace check must run inside onLate (after movement, before aiVolley) or evaluate from best's destination coordinates and facing.

3. [OBSERVED] Turn-Start State Resets in startSideTurn and roundStartBoth Break motionHit, rakeBonus, r_slip, and Torpedo Defense

What breaks or underperforms: battle.js uses a single property, u.hexMoved, for two opposite timing contracts: motionHit(t) reads t.hexMoved on the target to check whether it sat still on its last turn, while rakeBonus(u,w) reads u.hexMoved on the attacker to check whether it moved at least 2 hexes on its current turn. Meanwhile, startSideTurn(side) resets both u.braced=false and u.hexMoved=0. This causes three systemic bugs:

In roundStartBoth(), startSideTurn('player') and startSideTurn('enemy') both execute at the start of the round before any unit activates. That zeroes hexMoved and braced for every ship on the board, causing motionHit(t) to treat every unactivated ship as having sat still last turn (R.still) and stripping R.evade from ships that burned hard on the previous round.

In both turnStart(side) (phased activation) and roundStartBoth(), startSideTurn wipes u.braced=false and u.hexMoved=0 before resolveTorps runs on the very next line, stripping brace and movement state right before incoming torpedoes resolve.

Because startSideTurn zeroes u.hexMoved=0, the strict-take boon r_slip (move after firing) forces a ship to fire while u.hexMoved is 0, forfeiting rakeBonus ((u.hexMoved||0)<2).

Evidence:

battle.js: "u.braced=false; u.coverBy=null; u.postFire=false;" and "u.hexMoved=0;"

battle.js: "if(t.hexMoved===0) return R.still; if(t.hexMoved>=R.evadeAt) return -R.evade; return 0;"

battle.js: "function rakeBonus(u,w){ if(!u||u.isSq||!(w.arc==='P'||w.arc==='S')||(u.hexMoved||0)<2) return 0; return moveRules(u).rake; }"

battle.js: "async function turnStart(side){ const d=startSideTurn(side); if(d) await d; if(B&&!B.over) await resolveTorps(side); }"

battle.js: "const b0=B, d1=startSideTurn('player'), d2=B.over?null:startSideTurn('enemy');"

boons_synthesis_2026_10_29.md: "r_slip (move after firing, the pool's only activation-order change)"

What it costs the game: Core movement-defense math (motionHit), broadside positioning (rakeBonus), and brace silently break across turn/round boundaries and torpedo phases because hexMoved is not split into lastTurnMoved and thisTurnMoved.

4. [OBSERVED] Broadside rakeBonus is Dead Mechanics for Three of Six Factions and Unreachable on Base Stats for Dreadnoughts

What breaks or underperforms: rakeBonus(u,w) requires a weapon mounted in 'P' or 'S' arc and at least 2 hexes moved ((u.hexMoved||0)<2 returns 0). Auditing all 29 hulls in data.js (plus d_meridian) shows that the hull table barely supports this rule:

Three entire factions (Chorus, Glasswrights, and Eclipse, including d_meridian) have zero 'P' or 'S' weapon mounts across all hulls; every weapon is mounted 'F' or 'T'.

Only 8 hulls in the game carry 'P' or 'S' mounts (penitent, cathedral, ascendant, h_dominion, h_boss, c_reaver, c_marauder, c_boss).

Two of those 8 hulls (ascendant and h_boss) have base speed sp:1, making u.hexMoved >= 2 impossible without external speed buffs. Three more (cathedral, h_dominion, c_boss) have sp:2, losing rakeBonus from a single point of engine damage (u.mp=Math.max(1,u.speed-u.st.engine)).

c_reaver (w:[['torp','F'],['scatter','S']]) is asymmetrically missing a 'P' mount.

Evidence:

battle.js: "function rakeBonus(u,w){ if(!u||u.isSq||!(w.arc==='P'||w.arc==='S')||(u.hexMoved||0)<2) return 0; return moveRules(u).rake; }"

data.js: ascendant has "sp:1,tn:1,ev:0,w:[['hbattery','P'],['hbattery','S'],['turret','T'],['flak','T']]"

data.js: h_boss has "sp:1,tn:1,ev:0,w:[['hturbo','P'],['hturbo','S'],['turbo','T'],['ion','F'],['flak','T']]"

data.js: c_reaver has "w:[['torp','F'],['scatter','S']],ab:'reload'"

What it costs the game: A core v50 combat rule applies reliably to only two symmetric cruisers in the entire game (penitent and c_marauder), while dreadnoughts carrying heavy broadsides (ascendant, h_boss) cannot move far enough to trigger their own broadside bonus.

5. [OBSERVED] Partial Overturn of weapons_synthesis (hbattery Dominance Claim) and Discovery of True Firepower Inversion on ascendant vs cathedral

What breaks or underperforms: We confirm weapons_synthesis on flak/gsentry being identical ({shots:3, dmg:3, r:2, opt:2, acc:80, fall:10, vsSq:3, vsCap:.6}) and on torpedo range drift (battle.js:531-536 uses "range 5" while data.js still lists r:6,opt:6 on torp and htorp versus r:5,opt:5 on startorp). However, we overturn the synthesis claim that "hbattery strictly dominates battery on the table itself" is a weapon-table defect awaiting an Opus check on mounts and CP. Full HULLS data in data.js proves weapons are fixed to hulls by tier: battery mounts only on the cp:3 cruiser penitent (cost:200), while hbattery mounts only on the cp:5 battleship cathedral (cost:340) and cp:8 dreadnought ascendant (cost:520), matching turbo/hturbo and torp/htorp.
Simultaneously, HULLS reveals a real capital-ship inversion that all four legs missed: the unique cp:8 dreadnought ascendant (cost:520, sp:1, slots:3) has strictly weaker direct-fire weaponry than the cp:5 battleship cathedral (cost:340, sp:2, slots:3). ascendant keeps cathedral's two hbattery broadsides and flak, but downgrades cathedral's forward lance (dmg:20, r:7, opt:6, acc:82, pierce:.6) to a single destroyer-grade turret (shots:2, dmg:8, r:5, opt:3, acc:74, no pierce).

Evidence:

weapons_synthesis_2026_10_29.md: "hbattery strictly dominates battery on the table itself (DeepSeek: same envelope, +1 shot, +1 dmg, +1 crit)."

weapons_synthesis_2026_10_29.md: "mount availability and CP may separate the battery pair in the full data"

data.js: cathedral has "cp:5,hp:220,sh:30,rg:12,ar:.3,sp:2,tn:1,ev:0,w:[['hbattery','P'],['hbattery','S'],['lance','F'],['flak','T']],ab:'surge',slots:3,cost:340"

data.js: ascendant has "cp:8,hp:370,sh:32,rg:15,ar:.35,sp:1,tn:1,ev:0,w:[['hbattery','P'],['hbattery','S'],['turret','T'],['flak','T']],ab:'nova',slots:3,cost:520,unique:true"

What it costs the game: Paying +3 CP (+60% fleet budget) and +180 credits for the unique flagship dreadnought ascendant over cathedral cuts speed in half (losing broadside rakeBonus), adds zero module slots, and replaces a range-7 armor-piercing lance with a range-5 unpierced turret.

6. [OBSERVED / INFERRED] startSideTurn Sequencing Bugs Leak stormRegen Through shieldOff/regenLock, Clip Storm Healing, and Lock Risen Ships Out of brace

What breaks or underperforms: Auditing startSideTurn(side) in battle.js (lines 365-394) uncovers four sequencing defects in the turn-boundary loop:

stormRegen bypasses 1-turn shieldOff and regenLock: Line 378 decrements u.st.shieldOff (if(u.st.shieldOff>0) u.st.shieldOff--;) and skips normal shield regen. Line 379 clears u.regenLock=null. Five lines later, Line 383 checks !(u.st.shieldOff>0) for stormRegen. When shieldOff begins the turn at 1, Line 378 decrements it to 0 before Line 383 runs, allowing stormRegen to heal shields while offline and ignore regenLock.

Cap-before-drain ordering on ion storms: Shield regeneration (Lines 378 and 383) caps shields at u.shMax before Line 387 drains -10 for terr(u.q,u.r)==='storm'. A ship starting its turn in a storm at u.shMax loses all regeneration to the cap and then drops to u.shMax - 10.

Missing !u.dead guard on storm tick: Line 381 (acid) and Line 382 (fire) can kill a ship mid-loop, but Line 387 (terr(u.q,u.r)==='storm') checks only !u.isSq&&u.shMax>0 without !u.dead, popping 'Ion storm' floating text on a dead ship.

Risen Deathless hulls locked out of brace (INFERRED from battle.js + patch_pack): Line 392 stops risen ships from firing by setting w.fired=true on all weapons. Because canOrder('brace') requires no weapon fired (battle.js:1036), setting w.fired=true masquerades as having already fired, blocking risen ships from bracing on the vulnerable turn they reassemble.

Evidence:

battle.js: "if(u.st.shieldOff>0) u.st.shieldOff--; else if(u.shMax>0)" and "u.regenLock=null;"

battle.js: "if(u.fx&&u.fx.stormRegen&&u.shMax>0&&!(u.st.shieldOff>0))"

battle.js: "if(terr(u.q,u.r)==='storm'&&!u.isSq&&u.shMax>0){ for(let i=0;i<4;i++) u.sh[i]=Math.max(0,u.sh[i]-10);"

battle.js: "for(const u of risen) for(const w of u.weapons) w.fired=true;"

patch_pack_2026_10_29.md: "once the volley has fired, canOrder('brace') is closed anyway (battle.js:1036 requires no weapon fired)"

What it costs the game: Status effects (shieldOff, regenLock, storm, and reanimate) violate their own rules at turn start, either leaking healing when disabled or locking newly risen unshielded Eclipse hulls out of defensive bracing.

7. [OBSERVED] Uncapped Additive Effect Pool and Zero-Cost Refitting Collapse Build Layers into a Checklist (modules_synthesis and boons_synthesis Confirmed)

What breaks or underperforms: We confirm modules_synthesis (MOSTLY DISTINCT JOBS, NO BUILD LAYER) and boons_synthesis (DUPLICATES WITH PAINT) as two sides of one architectural defect:

Single uncapped additive dictionary: Relics, admiral perks, modules, and boons all fold into one flat additive pool with no caps or exclusions. Five modules duplicate five captain perks verbatim (gunnery/auspex +10 aim, killer/cogitator +10% crit, ironhull/prow +15% hull, helm/drive +1 speed, deflector/regen), and MODULES.cogitator collides on the same key name as RELICS.cogitator. Inside boons, the ram trio (r_prow, d_jugg, L_rook) and chain-explosion pair (Pyre of Stars and Chain Reaction) stack the same keys linearly.

Zero-friction refits and missing compatibility gates: Module equip/unequip is free and instant before every battle, turning fitting into a pre-battle checklist. Meanwhile, only hangar has an only guard in data, allowing weapon-specific modules (crystal, magazine, capacitor, loaders, flakplus) to be fitted onto hulls lacking those weapon kinds for zero effect. Similarly, BOON_NEED omits L_storm, offering shield refills (Eye of the Storm) to shieldless fleets (such as Chorus and Eclipse, whose hulls in data.js all have sh:0,rg:0).

Evidence:

boons_synthesis_2026_10_29.md: "One function folds relics, the admiral, and every boon into a single effect object by adding numbers"

boons_synthesis_2026_10_29.md: "L_storm is absent from the table, so a shieldless fleet holding two ungated storm boons"

modules_synthesis_2026_10_29.md: "Equip and unequip carry no cost, cooldown, or location restriction, and refitting between battles is always available"

modules_synthesis_2026_10_29.md: "Only hangar carries an only field in the data"

What it costs the game: Customization lacks committed trade-offs while unguarded modules and missing BOON_NEED entries trap players with dead picks.

8. [OBSERVED] The Settled CP Principle and Repair Ruling Collide With Flat Early-Tier CP, Credit-Blind Enemy Generation, and 0.0% Repair Binding

What breaks or underperforms: Treating the CP principle and repair ruling as fixed constraints, the shipped data and campaign math fail to express them:

Enemy fleets never see faction price asymmetry, and early CP is flat: In data.js, all six frigates (warden, h_picket, c_raider, b_drone, i_wisp, d_scythe) cost cp:1, and all six destroyers (harrow, h_interdictor, c_reaver, b_spitter, i_blade, d_jackal) cost cp:2. Because genEnemyFleet spends only CP and ignores FAC_PRICE, an enemy Eclipse fleet fields the exact same hull count at early budgets as an enemy Chorus swarm, despite d_scythe (hp:56, ar:.2, regen:3, reanimate:true) vastly out-statting b_drone (hp:46, ar:.05, r:1). Even if Chorus CP were discounted, RAMP.ceil converts lower hull CP into heavier hulls rather than larger swarms.

Non-binding repairs shift all economic pressure onto spiky taxes: With repair always beating scrap-and-replace by design, "repair tension binds in 0.0 percent of 60,000 modeled regroups", while a top module (80-90 credits) costs more than a warden frigate (cost:70) and the boon tax staircase jumps from ~15pp at tiers 1-2 to ~52pp at tier 3.

Evidence:

factionshape_synthesis_2026_10_29.md: "genEnemyFleet spends CP only; FAC_PRICE is never consulted."

factionshape_synthesis_2026_10_29.md: "all six frigates cost 1 CP and all destroyers 2 CP"

factionshape_synthesis_2026_10_29.md: "the board ceiling (RAMP.ceil minus live player ships) silently converts any swarm CP discount into heavier hulls"

Claims register: "repair tension binds in 0.0 percent of 60,000 modeled regroups (ruled accept as is)"

modules_synthesis_2026_10_29.md: "the hull cost formula puts a cp1 hull at 70 credits, so a top module at 80-90 credits"

What it costs the game: The ruled faction identity (elite Eclipse vs swarm Chorus) is invisible in enemy fleet counts during early sectors, and the campaign economy has zero attrition sink between free refits and non-binding repairs.

9. [OBSERVED] Squadron Reskins, Carrier Value Inversions, Pre-Battle Recon Lies, and Missing d_boss Reanimation (squadrons_synthesis and factionshape_synthesis Confirmed)

What breaks or underperforms: Confirming squadrons_synthesis (DUPLICATES WITH PAINT) and factionshape_synthesis (SHAPES PARTIAL) directly from data.js and battle.js:

Spore wing is a numerical clone of bomber: In data.js, bomber (hp:28, sp:5, ev:25, sq:'bomber') and spore (hp:26, sp:5, ev:25, sq:'bomber') fire near-identical weapons (bombs: shots:2, dmg:9, r:1, acc:78, pierce:.6, crit:10; sporeb: shots:2, dmg:10, r:1, acc:78, pierce:.6, crit:8) with no distinct delivery rule.

Severe carrier hull inversions: Player carrier reliquary (cp:4, hp:130, sh:22, ar:.15, hangar:2, w:[['turret','T'],['flak','T']]) has 40 less HP, lower armor, and weaker direct firepower than c_hulk (cp:4, hp:170, sh:16, ar:.2, hangar:2, w:[['turret','T'],['turret','T']]), while h_dominion (cp:6) gives up its battleship ability slot (ab:'launch') for hangar:1.

False carrier recon preview and hidden wing rules: When effArch remaps a carrier roll to heavy for launch-less factions (battle.js:138), the UI preview still warns the player to prepare anti-wing defenses against a fleet that cannot spawn wings. Meanwhile, torpedo screen stance hides its one-kill-per-wing cap from UI text, and wing XP perks on the 3/8/15 ladder are unsteerable random rolls.

Boss faction-trait drop: In data.js, d_scythe, d_jackal, and d_harvester all carry reanimate:true, but d_boss (The Unsetting) omits reanimate:true.

Evidence:

data.js: bombs has "shots:2,dmg:9,r:1,opt:1,acc:78,fall:0,pierce:.6,vsSq:.2,crit:10" vs sporeb "shots:2,dmg:10,r:1,opt:1,acc:78,fall:0,pierce:.6,vsSq:.3,crit:8"

squadrons_synthesis_2026_10_29.md: "what remains wrong is the preview layer still advising anti-wing preparation against fleets that will not have wings."

squadrons_synthesis_2026_10_29.md: "each wing caps at one kill per salvo. The stance text never states the cap."

data.js: d_boss has "w:[['gauss','T'],['gauss','T'],['doom','F'],['flak','T']],ab:'nova',regen:8,boss:true"

What it costs the game: Combined with free pre-battle module swapping, the false carrier preview actively baits players into equipping dead flakplus loadouts against wingless fleets.

10. [OBSERVED / INFERRED] Gating Veteran AI Behind Profile Progression Undercuts the First-Run Generational Learning Loop (ai_synthesis Confirmed)

What breaks or underperforms: Standing constraints specify that ~80% of runs are lost by design, Run 1 is near-impossible, and each generation inherits what the last learned. However, ai_synthesis confirms that new profiles begin on Standard AI with sticky focus fire, the death-cliff check, and veteran bracing disabled. In addition, enemy fleet generation fills everything after the single archetype seed via weighted random CP draws with no screen or escort roles, targeting uses an unreadable blended scalar, and carriers launch wings before moving onto hexes sorted strictly by distance. (INFERRED): When Run 1 is designed as a near-mandatory loss to kick off generational learning, gating the AI's tactical behaviors (aiVet()) off on fresh profiles means new players lose to opaque stat/economy walls while fighting a hollow AI that does not brace or focus-fire, then face a different ruleset once Veteran AI unlocks.

Evidence:

Core pack: "about 80 percent of runs are lost by design; run 1 is near-impossible; each generation inherits what the last learned"

ai_synthesis_2026_10_29.md: "Fresh profiles start on Standard AI with the focus, death-cliff, and brace machinery off"

ai_synthesis_2026_10_29.md: "Offense minus threat-weighted terms produces focus that works but cannot be anticipated"

ai_synthesis_2026_10_29.md: "the AI launches wings before moving, from launch hexes sorted only by distance"

What it costs the game: The first-run onboarding loop teaches players bad positioning habits against an intentionally lobotomized AI while concealing the tactical behaviors they are supposed to learn to counter.

Verdict

SYSTEMS FRACTURED AT TURN AND TABLE BOUNDARIES: The single most important attack is that both Wave 5 "ready-to-land" deliverables in this pack are mechanically broken against the live battle.js code: the ENTRY SOUND Eclipse battleship (d_meridian) mounts a dead fifth weapon (flak alongside gsentry when canFire blocks k:'flak' and startSideTurn caps intercepts via .some(w=>w.k==='flak')?2:0) with zero offensive gun gain over the CP 4 cruiser, and the Wave 5 veteran-brace diff evaluates evalOffense before moveUnit, causing damaged veterans with range- or arc-limited weapons (inReach) to move into close range and brace without firing.

Not checked

evalOffense, evalThreat, aiVolley, resolveTorps, and moveRules internals: battle.js was sliced only at lines 365-396, 628-634, and 853-856, plus the short diff snippets in patch_pack_2026_10_29.md.

MODULES, RELICS, EVENTS, ADMIRALS, FAC_PRICE, and BOON_NEED raw tables: data.js was sliced only at lines 2-28 (W) and 61-104 (HULLS), so module, boon, and relic interactions could only be verified where quoted in the syntheses.

The godot/ migration tree, save importer fixtures, and the 48 findings-to-tests regression suite: None of the GDScript files, campaign_run.js, campaign_meta.js, core.js, or test files were included in gamedev_pack.txt.

The Oct 30 b_razor_s silent weapon deletion and the 216 skill-tree / event / Nemesis text drafts: Listed in the claims register, but their data definitions and text assemblies were not sliced in this pack.
