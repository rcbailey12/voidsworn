# Leg: DeepSeek (DeepThink on, Search off), issue 2060

Gate record: New chat, account already signed in. DeepThink ON and Search OFF verified by toggle state before sending and again after generation. The first paste became a file chip; the browser used "Paste original" to restore plain text and verified no attachment before sending. Chat: "Faction command sets and deployment", https://chat.deepseek.com/a/chat/s/018add0e-a8b9-4420-ac1e-f6c06e8c3add

Response verbatim:

Question 1: Faction command sets

I keep four distinct commands per faction, because admiral choice should change the plan, not just the rider. Each command is a reskin of an existing template budget, gated by the faction battle rule. Riders stay per admiral. No shield facings. Numbers are starting points.

1. Sunward Crusade

Theme: hold the line, move two, punish the flank.

- Vex, Broadside Order: every ship fires a free flank battery volley at the best target its guns can reach. If the shooter moved at least 2 hexes this round, the line-of-battle side-gun bonus applies. Reuses barrage, line of battle, and the battery rider. Tiers: T1 free volley, T2 volley +10 percent damage, T3 volley +20 percent and battery shots cannot miss. New rule: none, the line check already exists.
- Malek, Lance Pounce: torpedoes and lances reload at once. All lance and battery damage is +15/25/35 percent this round, and ships that moved at least 2 hexes keep their line-of-battle bonus on those shots. Reuses hunt and line of battle. New rule: none.
- Ashgrove, Escort Wings: every launch ship sends an extra wing if there is room. All squadrons strike again with +50 percent damage. Ships that braced this round may cover one adjacent ally facing the same way as normal. Reuses scramble and Brace. Tiers: T1 extra wing, T2 +50 percent squadron damage, T3 +50 percent and braced ships take 10 percent less hull damage this round. New rule: the T3 braced damage reduction is a new small application, flag it.
- Thale, Iron Line: all shields refill and ships take 20/30/40 percent less hull damage this round. Reuses iron. New rule: none.

Balance: each command maps to one current template budget. The line-of-battle condition costs movement and facing, so it is not free power. Riders are unchanged.

Least-sure decision: Ashgrove's T3 braced damage reduction. It may be better to keep Ashgrove as pure scramble plus Brace and avoid a new defensive layer.
Biggest risk: Sunward can double dip line-of-battle with command bonuses and move above the PR 2038 band.

2. Meridian Directorate

Theme: network the fleet, sync the kill.

- Kassar, Sync Volley: every ship fires a free volley. If the target was already fired on by another synced ship this round, the volley gets +10 aim and +10/15/20 percent damage. Reuses barrage and synchronized fire. New rule: none.
- Vorn, Ion Reload: torpedoes reload at once. Ion cannons strip double shields and deal +15/25/35 percent damage this round. Reuses hunt and ion shield strip. New rule: flag double strip if the ion strip amount is not already a parameter.
- Reyes, Drone Screen: every launch ship sends an extra wing. All squadrons strike again with +50 percent damage. Synced ships within 3 hexes of the command ship give enemy called shots -15 accuracy against them this round. Reuses scramble, sync, and the surge accuracy penalty. New rule: flag the called-shot accuracy debuff as a new hook.
- Maren, Command Iron: all shields refill and ships take 20/30/40 percent less hull damage. Synced ships also get +5 aim this round. Reuses iron and sync. New rule: none.

Balance: the set is the current four template budgets with sync as the gate. Sync already requires the command ship and spacing, so the extra aim is paid for by position. Riders stay.

Least-sure decision: Reyes's called-shot accuracy debuff. It touches the called-shot job directly and may be better as a flat enemy accuracy penalty.
Biggest risk: sync plus command bonuses stack too well on the command ship cluster and push Meridian over the band.

3. Ashfall Hullbreakers

Theme: dash in, board hard, salvage out.

- Grax, Rocket Dash: every ship gets +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round. Each ship may fire one free rocket salvo at the end of its move. Reuses surge and rocket salvos. Tiers: T1 +1 movement and +1 turn, T2 +2 movement and +1 turn, T3 +2 movement and +1 turn plus the free rocket salvo. New rule: flag the end-of-move salvo timing.
- Sable, Boarding Hunt: torpedoes reload at once. All damage is +15/25/35 percent this round. Boarding crews get extra strength, and torpedoes fired this round ignore point defense. Reuses hunt, boarding, and the torpedo rider. New rule: none.
- Mott, Swarm Raid: every launch ship sends an extra wing. All squadrons strike again with +50 percent damage. Rocket salvos this round thin point defense by 1 for squadron strikes. Reuses scramble and rocket point-defense thinning. New rule: flag the cross-system timing between rockets and squadron strikes.
- Vesh, Salvage Restore: every ship repairs 15/25/30 percent hull and patches damaged sections. If a ship killed or boarded an enemy this round, it repairs an extra 5 percent. Reuses restore and boarding. New rule: flag the conditional repair trigger.

Balance: the set keeps the current surge, hunt, scramble, and restore budgets. Rocket and boarding conditions require close range, which is already the faction's risk. Riders stay.

Least-sure decision: Mott's rocket-to-squadron point-defense thinning. It may be too fiddly for the payoff.
Biggest risk: Grax's free rocket salvo plus surge movement gives Ashfall a strong round 3 alpha that breaks the close-in risk curve.

4. The Chorus

Theme: feed the brood, grow the swarm.

- Matriarch, Brood Surge: every launch ship sends an extra wing. All squadrons strike again with +50 percent damage. Swarm hits heal their parent brood 3/4/5 percent hull. Reuses scramble, Feed, and the swarm rider. New rule: none.
- Razormaw, Frenzy Drift: every ship gets +2 movement and +1 turn, and enemy fire loses 20 accuracy against you. Living ships regrow 5 percent hull at round end. Reuses surge and Feed. Tiers: T1 +1 movement and +1 turn, T2 +2 movement and +1 turn, T3 +2 movement and +1 turn plus the 5 percent regrow. New rule: none.
- Mending, Regrow Carapace: every ship repairs 15/25/30 percent hull and patches damaged sections. At T3 it can patch destroyed sections. Reuses restore and Feed. New rule: none.
- Voice, Feeding Volley: every ship fires a free volley. Kills trigger Feed regrow for the killer and nearby allies as normal. Tiers: T1 free volley, T2 +10 percent volley damage, T3 +20 percent volley damage and the killer regrows 5 percent hull. Reuses barrage and Feed. New rule: none if Feed on kill already exists.

Balance: Chorus has no shields, so no shield refill appears here. All four commands map to current Chorus templates. The set is worth about the same because it uses the same four budgets and Feed is already the faction's repair engine.

Least-sure decision: Voice's T3 killer regrow. It may be cleaner to let Feed on kill do all the healing and keep Voice as pure barrage.
Biggest risk: Feed plus restore plus swarm healing makes Chorus out-sustain the current band in long fights.

5. The Glasswrights

Theme: prism shields, slip away, burn with beams.

- Aelith, Prism Wings: every launch ship sends an extra wing. All squadrons strike again with +50 percent damage. Ships untouched since their last turn gain +10 percent shield recharge at round end. Reuses scramble and prism charge. New rule: none.
- Vaelen, Refraction Volley: every ship fires a free beam volley. Against a shielded target the volley gets +10/20/30 percent damage. Against an unshielded target it gets +5/10/15 crit. Reuses barrage and prism charge. New rule: flag the crit bonus if crit is not already a weapon parameter.
- Thorne, Slipstream: every ship gets +2 movement and +1 turn, and enemy fire loses 20 accuracy against you. After firing, ships may slip away as normal. Reuses surge and prism slip-away. New rule: none.
- Mirelle, Prism Aegis: all shields refill and ships take 20/30/40 percent less hull damage this round. Untouched ships recharge shields at the start of their next turn as normal. Reuses iron and prism charge. No Brace anywhere. New rule: none.

Balance: the set uses the current scramble, barrage, surge, and iron budgets but routes them through shields and slip-away. Glasswrights cannot Brace, so no command depends on Brace. Riders stay.

Least-sure decision: Vaelen's split bonus against shielded and unshielded targets. It may be better as one clean shield-strip or beam-damage bonus.
Biggest risk: prism recharge plus iron plus fragile hulls creates a feast-or-famine defense that is hard to keep inside 3 points at both difficulties.

6. Eclipse

Theme: archive armor, fold strike, reassemble.

- Nekhet, Archive Restore: every ship repairs 15/25/30 percent hull and patches damaged sections. An eligible fallen non-flagship reassembles next round at 35 percent hull as normal. Reuses restore and Archive restore. New rule: none.
- Sekhmar, Null Volley: every ship fires a free volley. Null weapons ignore armor as normal. Tiers: T1 free volley, T2 +10 percent damage, T3 +20 percent damage. Reuses barrage and null weapons. New rule: none.
- Anuket, Fold Hunt: torpedoes reload at once. All damage is +15/25/35 percent this round. Fold drives pass through ships, rocks, and wrecks at no extra cost this round. Reuses hunt and fold drives. New rule: none.
- Khepra, Layered Armor: all ships take 20/30/40 percent less hull damage this round. No shield refill. Reuses the iron damage-reduction half only. New rule: confirm the engine treats shield refill on a no-shield hull as a no-op, or add a guard.

Balance: Eclipse has no shields, so Khepra keeps only the part of iron that already worked today. The other three commands map to current restore, barrage, and hunt budgets. The set should be close to today because it removes dead shield refill rather than adding power.

Least-sure decision: Khepra's tier shape. I would keep it identical to today's effective iron and not add section patching unless testing shows Eclipse is under the band.
Biggest risk: Archive restore plus restore command plus Fold movement makes Eclipse recover too well and outlast the current band.

Question 2: Deployment step

Scores are 1 to 5, 5 is best or cheapest. Build cost is estimated agent build runs.

Option Player value AI handling Teaching load Build cost Estimated runs
A: none 1 5 5 5 0 to 1
B: place in zone 4 3 4 3 4 to 6
C: formation pick 3 4 3 2 6 to 8

Pick: B, a simple place-in-zone step.

B gives the player real opening agency without teaching named formations. It reuses existing ship placement and hex selection. The AI can keep its current deployment or use a small set of placement rules. C is easier to teach than manual placement but adds formation definitions, auto-arrange logic, and edge cases for blocked hexes and ship sizes.

Strongest argument against B: if the enemy is already placed, the player gets counter-deployment and a round 1 alpha advantage. That can break the PR 2038 faction band more than any command change. If the AI cannot place after seeing the player, A is safer.

Least-sure decision: whether deployment is simultaneous hidden placement or enemy-first. I would test simultaneous hidden placement first.
Biggest risk: deployment lets fragile factions hide or stack, changing win rates without touching commands.

Question 3: Called shots interaction

Command-fired attacks should not become free called shots. Rule: a barrage, free volley, or hunt torpedo honors the shooter's called section only if the player had already set that section on that target before the command fired. Otherwise the command uses default section routing and gets no +15 crit. This keeps barrage from being a free crit engine.

Commands that modify a normal shot should carry the called section through. Hunt, ion strip, null volley, and similar effects share the called section and do not roll a second section. Scramble squadron strikes cannot call sections unless squadrons get their own target bar; treat them as default. Surge's accuracy penalty applies to hit chance, not to crit after a hit.

Combos needing a ruling: restore patches a section destroyed by a called shot but does not clear forced system damage in the same round. Iron and Layered Armor reduce hull damage after section routing, and shield refill happens before section damage. If a command auto-targets a different ship than the player's called target, no called section applies. Least-sure decision: whether barrage should inherit a fleet-wide called section or per-target only. Biggest risk: free volleys plus called shots create a hidden crit multiplier that is hard to see in the target bar.

Single strongest objection to this brief: it bundles faction command identity, deployment, and called shots in one leg, which confounds balance. I would ship the command sets and called-shot rules first and defer deployment to a separate balance window.
