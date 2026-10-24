# Pack I: Enemy AI and Encounter Design Audit (Qwen)

Filed by Rey from Ryan's paste, Oct 23, 2026. Model: Qwen (attribution confirmed by Ryan). Charter and pack: contrib/muse/prompts/ (Pack I). Screening: contrib/muse/reviews/packFGHI_screening_round2.md. Filed as returned; claims are the model's own and are not verified by filing.

---

Voidsworn Enemy AI and Encounter Design Audit

1. Faction "doctrine" is largely an illusion; behavioral differences are reduced to scalar weights.
File: data.js, Line 111
Quote: blurb:'Gothic crusader battleships. Heavy armor, lance batteries and broadsides that hit like a cathedral falling.'}
File: battle.js, Line 987
Quote: hegemony:{tw:1.15,hurt:1.3,range:3,rw:1.2}, // hold a gun line at range
File: battle.js, Line 1115
Quote: if(prof.range>0) score-=Math.max(0,prof.range-nd2)*prof.rw; else score-=Math.max(0,nd2+prof.range)*prof.rw; }
Status: OBSERVED
Assessment: The rich faction flavor text promises distinct tactical doctrines, but this lives only in the text. The actual AI behavioral differences live in data tables (scalar weights: tw, hurt, range, rw) and are consumed by generic decision code. Aside from MOVE_RULES (e.g., Deathless phasing through rocks), factions do not have unique tactical logic.

2. The "death cliff" penalty creates a rigid, exploitable movement freeze.
File: battle.js, Line 1116
Quote: if(vet&&!u.isSq&&threat>=u.hp) score-=25; // v53-D death cliff: a hex where the expected fire could finish us
Status: OBSERVED
Assessment: The veteran AI applies a massive -25 score penalty to any hex where expected threat >= current HP. A human player can exploit this by positioning a high-damage ship to be exactly lethal to an enemy, freezing the enemy AI in place as it refuses to move into any hex that triggers the penalty, even if that hex offers a winning shot.

3. Overkill-avoidance logic allows players to spoof heavy weapon targeting.
File: battle.js, Line 1048
Quote: if(expectedVs(u,w,primary).hull>=primary.hp*2&&ws.some(x=>x!==w&&canFire(u,x,primary)&&expectedVs(u,x,primary).hull>=primary.hp))
Status: OBSERVED
Assessment: The AI explicitly refuses to fire a heavy gun at a primary target if a lighter gun can finish it. A human player can exploit this fixed pattern by keeping a low-hull, high-evasion ship alive as "bait," effectively neutralizing the enemy's alpha-strike potential as the AI routes heavy weapons elsewhere.

4. AI boarding logic is extremely conservative and easily baited.
File: battle.js, Line 686
Quote: const v=o.chance>=70?100+t.maxHp/10:0; if(v>bv){bv=v;best=t;} }
Status: OBSERVED
Assessment: The AI will only initiate boarding if the calculated capture chance is >= 70%. A human player can deliberately drop their effective crew odds to 69% (e.g., via minor crew damage or hazard positioning) to completely disable the AI's boarding threat, turning a high-risk mechanic into a non-factor.

5. Flagship escort spacing is hardcoded, creating predictable, punishable formations.
File: battle.js, Line 1118
Quote: if(dv<=3) for(const x of escO) if(hdist(x,v)===1) score-=1; }
Status: OBSERVED
Assessment: Escorts are penalized for being >3 hexes from the flagship, and penalized again for stacking. A human player can exploit this by focusing fire on escorts forced into tight, predictable rings. The AI will never break formation to kite or flank, even if it means taking free, uninterrupted shots.

6. Objective play is gated behind "veteran" AI; standard AI merely fights.
File: battle.js, Line 1121
Quote: if(B.obj&&B.obj.type==='hold'&&!u.isSq&&!vet) score-=hdist(v,B.obj.hex)*1.6; // veterans: aiObjScore
Status: OBSERVED
Assessment: Standard AI ignores complex objective scoring (aiObjScore), relying only on flat distance or nothing. It will not actively contest relays or defend stations with urgency, merely treating the objective hex as another combat zone. Only the veteran AI plays the objective.

7. Difficulty derives primarily from multiplicative stat scaling, not decision complexity.
File: battle.js, Line 313
Quote: scale:sc*(HULLS[e.tpl].boss?BOSS_SCALE[s]*bossFit*(BOSS_FAC[cfg.fac]||1)*(heatOn('h_flag')?1.2:1):1), dmg:dm*(HULLS[e.tpl].boss?BOSS_DMG[s]:1)
Status: OBSERVED
Assessment: Enemy scale and dmg multiply by sector (sc=1+.12*(s-1), dm=1+.08*(s-1)). The annex bossmatrix shows win rates swinging wildly (38% to 98%) based purely on the player's admiral/fleet pick, indicating player build dictates the outcome far more than the AI outsmarting the player.

8. Squadron targeting is rigidly bound to "fleet focus" and easily spoofed.
File: battle.js, Line 876
Quote: if(s&&s.side==='enemy'&&t===B.aiFocus&&aiVet()) v*=1.3;
Status: OBSERVED
Assessment: Enemy squadrons apply a 1.3x value multiplier to the fleet focus target. A human player can exploit this by deploying a cheap, high-evasion, or high-hull ship as "focus bait," drawing all enemy squadron attacks while the real damage dealers operate safely outside the squadron leash.

9. Retreat logic is binary and artificially gates player progression/salvage.
File: battle.js, Line 786
Quote: if(bossDown||sideCP('enemy')<=B.cp0.enemy*.35){ B.over='win'; B.routed=true;
Status: OBSERVED
Assessment: Once the 35% CP threshold is crossed, the entire remaining enemy fleet instantly flees. A human player can exploit this by alpha-striking to cross the threshold exactly, denying the player the chance to farm kills, captain XP, or salvage from the remaining 35% of the fleet.

10. Encounter variety is high, but map generation assembles fights with dissonant terrain.
File: battle.js, Line 193
Quote: const m=kinds.includes(map)?map:pick(kinds); TERRAIN_META={map:m};
Status: OBSERVED
Assessment: While there are 8 encounter types and 12 shapes, map generation often picks terrain kinds (belt, station, planet, etc.) independently of the objective. This leads to dissonant fights (e.g., a "Breakthrough" or "Intercept" objective spawning on a "Ring" or "Dense" map), undermining the tactical fantasy of the encounter type.

Not checked
Human playtesting data (all annex win rates, loss figures, and round counts are strictly bot-vs-bot simulations).
The visual/audio presentation layer (e.g., scene3d.js, animation timings, VFX).
The meta-progression economy balance (credit costs, relic drop rates, and shipyard pricing outside of battle simulations).
The underlying Node.js test harness code itself (the annex notes harness defects like campaignSim crashing on unregistered objectives, but the harness code was not audited for correctness).
Heat level scaling above 0 (the annex explicitly states "No mode was run at Heat above 0").

Questions this pack cannot answer
Does the "veteran" AI actually provide a satisfying challenge to human players, or do the "death cliff" and "overkill avoidance" mechanics make it trivially exploitable by competent humans?
How do the faction blurbs affect player perception and immersion if the actual AI behavior is nearly identical across factions aside from scalar weights and movement flags?
Does the 35% CP rout threshold feel rewarding to human players, or is it frustrating for those who want to salvage the remaining enemy fleet for credits and XP?
Are the animation wait times (95 to 120 seconds of pure animation time for elite/boss fights in sectors 2 and 3) acceptable to human players, or do they cause significant churn?
How does the AI perform when the player uses unconventional, non-bot-like builds (e.g., full ram, full boarding, or nova-spam) that the bot-vs-bot matrix did not simulate?
Does the "focus bait" exploit render enemy squadrons irrelevant in human play, breaking the intended counter-play for carrier-heavy factions?
