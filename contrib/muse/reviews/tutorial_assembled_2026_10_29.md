# Tutorial copy, campaign layer: assembled set (savings pass wave 4, item 5, Oct 29, 2026)

Chair assembly from the three filed prongs: the DeepSeek draft (primary text, closest to the shipped TIPS register), the Qwen draft, and the blind Rey draft, all filed under contrib/deepseek/reviews/, contrib/qwen/reviews/, and contrib/muse/reviews/. The Argon prong is still outstanding; if it lands stronger texts they arrive as an addendum for Opus, not a rewrite.

The set mirrors the shipped TIPS shape, [id, title, text], ids prefixed c_, for the campaign layer the shipped tutorial cannot reach (its checker only runs inside a battle; that structural gap is the Oct 29 firstrun audit's one systemic teaching failure, and this set is the copy half of the answer).

['c_map', 'Sector map', 'You move on the sector map by choosing a path. You cannot visit every node; you can move only to connected nodes.'],
['c_nodes', 'Node types', 'The map shows node kinds at a glance: battles, elites, the boss, events, rest, and shipyards. Pick the route that gives what your fleet needs.'],
['c_elite', 'Elite fights', 'Elites are harder fights with better rewards. The sector guarantees one elite on your path.'],
['c_clock', 'Nemesis clock', 'The Nemesis clock fills when you win and when you make loud choices. When it fills, the Nemesis comes to you; the meeting is not optional.'],
['c_credits', 'Shipyard credits', 'Credits are for shipyards: ships, repairs, and refits. Credits do not carry power on their own.'],
['c_prize', 'Prize ships', 'When you capture a ship, you can add it, strip it, or ransom it. Owners pay less for each ship you sell back.'],
['c_salvage', 'Strip wrecks', 'At a salvage step, pick one wreck: take a refit, credits, or a tow at 35% hull.'],
['c_boon', 'Boon offers', "Boons are a patron's permanent in-run gifts. Rarity is strength. Declining pays credits, and you get one reroll per reward."],
['c_relic', 'Salvage pieces', 'These are salvage pieces: build pieces that change how your fleet fights, won from elites and bosses. Your fleet can carry only one of each piece, so a choice here is about which build you are making.'], [Rey swap]
['c_shipyard', 'The shipyard', 'Buying a ship costs credits and command points, and your fleet is limited by command points. Repairs are priced per ship and restore that ship in full, and a repair always costs less than replacing the ship. Refits you own are fitted here from your hold.'], [Rey swap]
['c_regroup', 'Regroup choice', 'After a boss, the regroup is a choice under scarcity. You can repair, upgrade, or buy; credits spent on one are not spent on the others.'],
['c_heat', 'Admiral Heat', "Heat is experience for the admiral you flew. It levels them and feeds the faction's shadow pool."],
['c_tree', 'Skill trees', 'You get one skill-tree pick per tree level. Picks change decisions, not just numbers. Respec is between runs, for renown.'],
['c_renown', 'Renown currency', 'Renown is the between-runs currency for unlocks and respecs. You earn it across runs, not within one.'],
['c_verb', 'Faction verb', "You use your faction's campaign verb once per sector, from the map. Some are free after the right event."],
['c_loss', 'Run lost', 'Losing the fleet ends the run, not the war. You carry over renown, favour, and what your faction learned; you do not carry over ships, credits, or boons.'],

## Assembly notes

Swaps (2 of 16; everything else is the DeepSeek draft as filed):
- c_relic: the Rey text replaces DeepSeek's. Both were accurate on the one-copy rule (chair-verified from code: the offer pools exclude owned pieces at campaign_run.js:410 and core.js:240, so a second copy can never be offered), but the Rey text turns the fact into the decision the player is actually making, and its title uses the player-facing word only, where DeepSeek's title mixed in the data word.
- c_shipyard: the Rey text replaces DeepSeek's because it is the only draft that carries the ruled repair rule (a repair always costs less than replacing the ship) into the tip where a player acts on it, alongside the command point limit.

Excluded on accuracy, recorded so Opus does not re-derive them from the filed Qwen draft:
- Qwen's c_clock says the meeting "cannot be delayed." It can: haven's tribute, scout's hunt, and saboteur's quiet catch all push the clock back in the shipped event table. The assembled text states only the mandatory half.
- Qwen's c_salvage implies every wreck can be worked ("for each wreck you pick one take"); the shipped step works one wreck. The assembled text keeps the one-wreck shape.
- Qwen's c_elite says "you will meet it if you keep moving"; the guarantee is placement on a reachable path, not a forced fight.

Reserve line: Qwen's c_clock closing, "decide how quickly you want it to reach full," is the best agency phrasing any draft produced for the clock. It is not assembled because the sentence it closes contains the delay error; if Opus wants it, it splices cleanly onto the assembled c_clock text.

One open shape for Opus: no draft states the Heat split in numbers, because the pack gave none. The ruled split exists (battle-layer Q13: +2 XP per Heat point to the flown admiral, +1 to the faction shadow pool, cap overflow to the line's shadow XP) if he wants c_heat to carry figures.
