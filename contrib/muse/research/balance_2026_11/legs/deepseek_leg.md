1. Headline

The 46-point spread is mostly a top tail made by The Chorus and Eclipse and a bottom tail made by the Sunward Crusade. Hegemony Navy sits near the middle, while Ashfall Hullbreakers and The Glasswrights sit in the upper middle. The gap is not one single overpowered weapon; it is the sum of Chorus economy and regeneration, Eclipse reanimate and armour, and Crusade's slow broadside fleet plus the torpedo evasion tax.

2. Why each faction lands where it does

Sunward Crusade

The strongest conclusion is that Crusade loses early and mid. It has the lowest average battles at 7.98, and 21 of its 33 deaths are in sector 2. That is not a late-game scaling problem; it is a run survival problem in the middle sector. The hull table shows why the identity is awkward under the bot: penitent speed 3 and cathedral speed 2 must move 2 or more hexes to use the Crusade movement rule, which gives broadsides 40 percent more damage after moving 2 or more hexes. The AI-1 brace fix cost the Crusade row about 8 points in the faction matrix, from 55.8 without the fix to 47.5 with it. That is a measured split and a strong cause: enemies now brace and survive longer, while the Crusade's moving broadside strength does not gain from bracing.

The second strong cause is torpedo exposure. The weapon table gives torp evMult 2, so the target's evasion counts double. Crusade harrow carries torp, and the faction's heavy hitters are slow and not high-evasion. Against Glasswrights ev 16 to 28 and Hullbreaker raider ev 28, that tax is real. The third cause is economy. Crusade's only FAC_PRICE modifier is Carrier 1.25, which hurts Ashgrove, the admiral at 16 percent in the small per-admiral sample. The starting fleets are CP 6 to 7, not especially low, but the carrier tax and slow hulls make the fleet less forgiving.

As an enemy, Crusade is less common in the sector pools, but the boss evidence matters: step 14 raised the Daybreak's speed from 1 to 2, and the same step took the fight against the Crusade flagship from 81 to 67 percent. That is a measured hardening of a Crusade enemy. Plausible but unproven is the exact size of the broadside movement rule's benefit for the bot; the pack shows the rule, not a measured bot delta for it.

Hegemony Navy

Hegemony lands mid because it has no price penalty and a shielded, armour-heavy line. FAC_PRICE is all 1.0 for Hegemony, and the hull table gives h_interdictor sh18, h_vanguard sh24, and h_dominion sh32. The ion weapon does 2.5 times shield damage, which is a real early edge against shielded enemies. Deaths are 5 / 10 / 8 and average battles 8.66, so Hegemony is neither fragile nor dominant.

The strong negative is that ion loses its special value against the two shieldless factions, Chorus and Eclipse, which appear in sectors 2 and 3. Hegemony also has less zero-CP wing value than Chorus: h_vanguard and h_dominion have hangar1, while Chorus brood has hangar3 and Crusade reliquary has hangar2. As an enemy, Hegemony appears in sectors 1 and 2, so its shielded hulls are a gate for other factions. As a player, it is mid. The per-admiral spread is large, Reyes 92 versus Vorn 25, but those are n=12 or 13 smoke samples. The strong conclusion is the price and shield package; the ion mismatch is plausible and supported by the shieldless hull tables, but the pack does not give a measured ion-only delta.

Ashfall Hullbreakers

Hullbreakers sit at 62 because their cheap aggression works. FAC_PRICE gives Frigate 0.8 and Destroyer 0.85, and the hull table gives c_raider speed 6 and evasion 28. The movement rule makes sideslips cost 1 instead of 2. Deaths are 3 / 9 / 7 and average battles 8.88. As an enemy, Hullbreakers are in sector 1, so their cheap raiders are an early gate. The sector 1 boss matrix also puts Grax at 49 percent after step 14 against a 50 percent floor, which is close to the floor and suggests the Hullbreaker boss is not overperforming.

The main drag is torpedoes. c_reaver and c_marauder carry torp, and torp evMult 2 taxes them against high-evasion targets, especially Glasswrights and mirror raiders. The carrier c_hulk has a 1.15 price multiplier, but that is not a large penalty. The strong conclusions are cheap frigates and destroyers plus high raider evasion. The sideslip synergy is plausible but not measured separately.

The Chorus

Chorus is top for two strong reasons. First, its price multipliers are the lowest: Frigate 0.65, Destroyer 0.75. A drone costs 45 and a spitter 100. Second, its regeneration stacks with numbers. Chorus has no shields, but b_drone regen4, b_spitter regen5, b_razor regen7, b_brood regen8, and b_boss regen20. A five-ship Chorus fleet regrows roughly 25 to 35 hull per round for free, and repair between battles is irrelevant to a faction that heals during them. Deaths are 2 / 4 / 4, the lowest in the table, and average battles are 8.94. The brood carrier has hangar3, so its wings cost 0 CP, and the movement rule gives the first turn each round no movement cost.

As an enemy, Chorus appears in sectors 2 and 3, so its regeneration and swarm numbers are a late gate for other factions. The weakness is focus fire and no shields to buffer burst, but the bot policy is not described as a focus-fire policy. The strong conclusion is that cheap swarm plus per-round regen is the main cause. The exact contribution of the free first turn is plausible but unproven.

The Glasswrights

Glasswrights are upper middle because evasion and shields are strong under this bot. i_wisp has evasion 28, i_blade 24, i_song 16, and shields regen 6 to 10. The movement rule gives enemies minus 18 to hit after the Glasswright moves 2 or more hexes, while other factions need 3 hexes for minus 5. Torpedo evMult 2 also helps them against torpedo-heavy Crusade and Hullbreakers. Deaths are 5 / 7 / 6 and average battles 8.74. As an enemy, Glasswrights appear in sectors 2 and 3, so their evasion is a real gate.

The strong negative is fragility. Their hulls have the lowest hp in the game, 30 to 140, and FAC_GATES says ithar noBrace, so they cannot brace. Their price multipliers are high: Frigate 1.3, Destroyer 1.3, Cruiser 1.15, Carrier 1.1. The strong conclusion is that evasion, shields, and the movement rule carry them. The exact size of the minus 18 rule is not measured in the pack. Saro at 82 is a small-sample admiral high, not proof of a faction-wide problem.

Eclipse

Eclipse is second because reanimate and armour make effective hull much larger than printed hull. Reanimate restores a fallen ship once per battle at 35 percent hull, flagships excluded, and the hull table gives armour 20 to 35 with regen 3 to 4. Gauss has pierce 0.6. Deaths are 3 / 5 / 6. As an enemy, Eclipse appears in sector 3, so its reanimate and armour are a late gate. This is partly by design: R63 says Eclipse ships should be stronger but more expensive, and FAC_PRICE is 1.45 to 1.6. The roster also has only three line hulls and no carrier.

The strong conclusion is that reanimate plus armour is the main cause of the 72 percent rate. The price is already high, so the question is the size of the gap, not whether Eclipse should be cheap. The exact reanimate value is in battle.js, not data.js, so this report does not propose changing it.

3. Ranked changes

I aim at a 52 to 62 point window, center 57. That is below the current 61 overall and well below a human first run, so it respects R62. The Crusade needs to rise about 18 points, Chorus needs to fall about 18, Eclipse about 10, and Glasswrights about 2. Hegemony and Hullbreakers need little. All changes are single data.js numbers.

Weapon table, tendril: dmg per shot 13 to 11. Expected Chorus down 3 to 4 points, because drone and razor rely on tendril. Risk: tendril is range 1, so Chorus may become too weak against armour. Owner call: no.

Hulls, b_drone: regen 4 to 3. Expected Chorus down 2 to 3. Risk: early swarm sustain drops sharply. Owner call: no, this follows R63's weaker Chorus direction.

Hulls, b_spitter: regen 5 to 4. Expected Chorus down about 2. Risk: spitter becomes less able to trade. Owner call: no.

Hulls, b_razor: regen 7 to 6. Expected Chorus down about 2. Risk: the main line hull loses staying power. Owner call: no.

Hulls, b_brood: regen 8 to 6. Expected Chorus down 2 to 3. Risk: the brood carrier becomes fragile for its 375 cost. Owner call: no.

Weapon table, bioplasma: dmg per shot 12 to 10. Expected Chorus down 2 to 3. Risk: spitter and razor damage may fall too far against armour. Owner call: no.

MOVE_RULES, Crusade broadside bonus: 40 percent to 50 percent after moving 2 or more hexes. Expected Crusade up 4 to 6 points. Risk: rewards positioning in a swingy way, and the bot may not use it consistently. Owner call: no.

Hulls, warden: hp 45 to 52. Expected Crusade up 2 to 3. Risk: cheap cp1 hull becomes too efficient. Owner call: no.

Hulls, harrow: hp 78 to 88. Expected Crusade up 2 to 3. Risk: harrow plus torpedo tax may still be weak. Owner call: no.

Hulls, penitent: hp 120 to 135. Expected Crusade up 2 to 3. Risk: slow line hull becomes a better damage sponge but not a damage dealer. Owner call: no.

Hulls, reliquary: hp 130 to 145. Expected Crusade up 1 to 2. Risk: carrier durability may help Ashgrove more than other admirals. Owner call: no.

Hulls, cathedral: hp 220 to 245. Expected Crusade up 1 to 2. Risk: late Crusade may become too durable. Owner call: no.

FAC_PRICE, Crusade Carrier: 1.25 to 1.10. Expected Crusade up 1 to 3 average, more for Ashgrove. Risk: still a carrier premium, but less identity. Owner call: no.

FAC_PRICE, Eclipse Frigate: 1.45 to 1.60. Expected Eclipse down 2 to 3. Risk: early Eclipse purchases and repairs become painful. Owner call: yes, because R63 fixes the direction but not the size.

FAC_PRICE, Eclipse Destroyer: 1.50 to 1.65. Expected Eclipse down about 3. Risk: d_jackal fleets like Ostrel and Seveth may fall too far. Owner call: yes, same reason.

FAC_PRICE, Eclipse Cruiser: 1.55 to 1.70. Expected Eclipse down 3 to 4. Risk: d_harvester fleets become expensive to repair and replace. Owner call: yes, same reason.

Hulls, i_blade: sh 16 to 15. Expected Glasswrights down 1 to 2. Risk: small shield loss on a low-hp hull; could make focus fire too strong against them. Owner call: no.

Admirals, Chorus Voice: all weapons +15 percent damage to +10 percent. Admiral-targeted, expected average Chorus down about 1 and Voice down 2 to 3. Risk: Voice loses some identity. Owner call: no.

The central estimate for the package is Crusade 52, Hegemony 54, Hullbreakers 60, Glasswrights 62, Eclipse 62, Chorus 62. That is a 10-point window centered at 57. The package does not make Chorus expensive and does not make Eclipse cheap, so it stays inside R63. It keeps the overall bot rate below the current 61, which is consistent with R62's warning against pushing the bot rate high.

4. Out-of-scope or rejected levers

RAMP in battle.js is out of scope. If the enemy budget curve is the real problem, the pack says to report it here rather than propose a RAMP change.

Changing reanimate's 35 percent value is out of scope because the pack places it in battle.js, not data.js. Changing AI brace behavior is also out of scope.

Making Chorus more expensive would fight R63. Making Eclipse cheaper would also fight R63. I rejected both.

Changing every faction's torpedo evMult would flatten a weapon interaction and would not be faction appropriate. I left it as a diagnosis, not a proposal.

Cutting Chorus regeneration to zero or removing carrier wings would be a system change, not a small number change. I rejected those.

5. Not checked

I could not run the simulator, so all effect sizes are predicted, not measured. The pack's per-admiral rates are n=12 or 13 and should be read as smoke, not signal. The pack does not give a measured bot delta for the Crusade broadside rule alone, for the Glasswright minus 18 movement rule alone, or for Chorus free first turn alone. The pack also does not give exact repair purchase behavior by faction, so price changes are less predictable than hull changes. I did not verify human first-run difficulty directly; I only checked the bot overall rate against R62.
