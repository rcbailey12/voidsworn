# DeepSeek faction asymmetry audit (extracted)

Extracted by Rey from the raw DeepSeek transcript (contrib/deepseek/faction_asymmetry_audit.txt). Claims are DeepSeek's, unverified, reproduced for Opus to judge. Quotes are verbatim from the transcript.

Transcript note: the transcript contains one complete answer, reproduced below. After it, the transcript repeats the task prompt and a second round of the model's planning notes, which cuts off mid-draft; there is no second answer, and all planning material is omitted here.

## Part 1: Measure the sameness

Findings in the model's own order, most damning first.

### 1. The bottom price ladder is identical across all six factions
Status: OBSERVED

Every frigate costs 70; every destroyer costs 130. Cruisers cluster at 190 to 250. The model calls this a shared budget script with renamed hulls.

Evidence: data.js:61 "cost:70"; 72 "cost:70"; 78 "cost:70"; 84 "cost:70"; 90 "cost:70"; 96 "cost:70". Destroyers: data.js:62 "cost:130"; 73 "cost:130"; 79 "cost:130"; 85 "cost:130"; 91 "cost:130"; 97 "cost:130".

### 2. Admiral cost curves and the command pool are shared, not faction-shaped
Status: OBSERVED

Each faction has four admirals at 0/30/45/80, and command IDs are recycled among a small shared set (barrage, hunt, scramble, iron, restore, surge across factions), with a shared implementation.

Evidence: data.js:202 "cost:0"; 203 "cost:30"; 204 "cost:45"; 205 "cost:80". Same for Hegemony: data.js:214 "cost:0,cmd:{id:'barrage'"; 215 "cost:30"; 216 "cost:45"; 217 "cost:80". Commands reused across factions: data.js:209-233; shared implementation battle.js:822-862.

### 3. Squadrons are one shared system with cosmetic faction hooks
Status: OBSERVED

The game has one fighter and one bomber template, and Chorus gets one spore variant. A faction's sq field only selects which shared template a carrier launches.

Evidence: data.js:68 "fighter...hp:18...guns:T"; 69 "bomber...hp:28...bombs:T"; 70 "spore...sporeb:T". Faction sq fields: data.js:114 "sq:'fighter'"; 117 "sq:'bomber'"; 120 "sq:'spore'"; 123 "sq:'fighter'"; 126 "sq:null". Launch/control logic: battle.js:904-912.

### 4. Weapon stat lines occupy narrow shared bands
Status: OBSERVED

Before faction traits, capital main guns are mostly expected raw volleys of 18 to 40, range 4 to 6, accuracy 60 to 82. Traits adjust these numbers and add status riders, but do not create different firing decisions.

Evidence: data.js:5 "shots:4,dmg:6,r:5,opt:3,acc:72" = 24 raw; 11 "shots:2,dmg:9,r:5,opt:3,acc:74" = 18 raw; 19 "shots:2,dmg:12,r:6,opt:5,acc:80" = 24 raw; 23 "shots:1,dmg:40,r:5,opt:4,acc:78" = 40 raw. Trait table: data.js:43-53; faction trait map: data.js:54-56.

### 5. Stat bands per class overlap heavily
Status: OBSERVED

Frigates are hp 30 to 56, shields 0 to 12; destroyers hp 60 to 110, shields 0 to 18; cruisers hp 90 to 150, shields 0 to 26. The differences are nudges inside shared bands.

Evidence: data.js:61 "hp:45,sh:10"; 72 "hp:40,sh:10"; 78 "hp:46,sh:8"; 84 "hp:46,sh:0"; 90 "hp:30,sh:12"; 96 "hp:56,sh:0". Destroyers: 62 "hp:78,sh:14"; 73 "hp:74,sh:18"; 79 "hp:68,sh:10"; 85 "hp:82,sh:0"; 91 "hp:60,sh:16"; 97 "hp:110,sh:0".

### 6. Faction-only mechanics exist, but they are single-rule bends or one button
Status: OBSERVED

Each faction gets one movement rule, a small weapon-trait family, and one signature line-ship ability. None is a faction-wide resource, build path, or economy.

Evidence: Movement: data.js:104 "rake:.2"; 105 "rev:1"; 106 "slip:1"; 107 "pivot:1"; 108 "evadeAt:2"; 109 "over:0". Abilities: data.js:138-144: ionpulse, overburn, frenzy, regrow, blink, phase, reclaim. Unique examples: data.js:96 "reanimate:true" only on Deathless hulls; battle.js:702 reanimation check.

### 7. The clearest range identities live in enemy AI only, not in player faction rules
Status: OBSERVED

Hegemony AI holds range 3; Corsair AI closes to -2; Deathless AI advances to -3. A player fleet does not receive those doctrinal rules.

Evidence: battle.js:987 "hegemony...range:3"; 988 "corsair...range:-2"; 989 "chorus...range:-1"; 990 "ithar...range:2"; 991 "deathless...range:-3".

### 8. Boss scaling is one of the few truly faction-specific numeric tables, and it is enemy-side only
Status: OBSERVED

Corsair bosses scale 1.45; Ithar bosses scale .80.

Evidence: battle.js:127 "corsair:1.45,voidsworn:1.40,hegemony:.95,chorus:1.10,deathless:1,ithar:.80".

### 9. No faction economy exists in the pack
Status: INFERRED

Credits, renown, shipyard discounts, and repair are global. There is no per-faction resource, price curve, salvage rule, or repair rule, and no faction-specific credit/repair/reward table appears.

Evidence: data.js:247 "Shipyard prices −15%." is a global legacy upgrade; campaign_meta.js:187 "META.renown=(META.renown||0)+ren;" is global.

### 10. The class ladder is not literally identical, but the exceptions do not create asymmetry
Status: OBSERVED

Hegemony has no dedicated carrier hull, and Deathless has only three hulls and no squadron field. Those are roster gaps, not different decision systems.

Evidence: data.js:114 "roster:['h_picket','h_interdictor','h_vanguard','h_dominion']"; 126 "roster:['d_scythe','d_jackal','d_harvester']"; 126 "sq:null".

## Part 2: Propose asymmetry

Shared engine note from the model: the pack has no per-faction economy hook. To make the economies below real: ENGINE CHANGE, add a faction economy modifier table read by shipyard price, repair cost, and battle reward code. In the model's words: "this system reads a faction id and applies different credit gain, repair, and purchase modifiers."

### Voidsworn Crusade — armored line-breaker, elite
- Unit-count profile: elite. Few capital hulls, frigates are escorts, not the plan.
- Range profile: mid-range broadside and lance; strong at 3 to 5 hexes, poor at knife range and poor while chasing.
- Shield/survivability: shields plus armor; survives by facing and bracing, not evasion.
- Movement: slow, deliberate, broadside-facing. Keep rake and low speed; make turning the central decision.
- Economy: gains normal battle credits but pays premium for hull repair and armor refits; no cheap replacement swarm.
- Win condition: break the enemy command ship or flagship in a decisive line fight.
- Lose condition: gets flanked, rear-arc hit, or forced to chase fast targets.
- Prohibition: cannot blink, phase, or ignore terrain; Ithar and Deathless can.
- Smallest changes: keep broadside rake data.js:104; push frigate cost above 70 and restrict frigate count; give line cruisers focus/surge only; keep no blink/phase. Use existing focus data.js:133, surge data.js:135, and armor modules data.js:152.

### Hegemony Navy — disciplined long-range shield-stripper, standard
- Unit-count profile: standard. A gun line with escorts and launch-capable cruisers/battleships, not a dedicated carrier fleet.
- Range profile: long. Prefer 3 to 6 hexes; punish close brawlers before they arrive.
- Shield/survivability: shield-heavy, hull-fragile when shields fail; relies on facings and shield refill.
- Movement: reverse thrusters and formation discipline. Keep rev:1 data.js:105.
- Economy: gains extra from station-defence and relay objectives; pays less for shield refits, more for hull replacement.
- Win condition: strip shields with ion fire, hold range, and win by station/relay control or fleet break.
- Lose condition: closed on by ram/boarding or forced to chase.
- Prohibition: cannot fire torpedoes; Hegemony rosters contain no torpedo weapon.
- Smallest changes: keep ion data.js:13, ionpulse data.js:138, and reverse movement; remove any torpedo access; make h_vanguard/h_dominion launch the only squadron source. Use CMD_POW battle.js:827 to make iron stronger for Hegemony.

### Ashfall Corsairs — close-range raider swarm
- Unit-count profile: swarm. Cheap raiders and reavers; cruisers are support, not the core.
- Range profile: close. Scatter, rockets, torpedoes, boarding, and ram pressure.
- Shield/survivability: thin shields, high evasion, low armor; survive by not being hit and by trading cheap hulls.
- Movement: sideslip and overburn. Keep slip:1 data.js:106 and overburn data.js:139.
- Economy: gains extra credits from boarding captures and salvage; loses value when hulls are destroyed without capture.
- Win condition: close, board or ram a key ship, and break the enemy before repairs matter.
- Lose condition: long-range gun line holds them off or point defence strips rockets.
- Prohibition: cannot use lance weapons; Corsair rosters have no lance.
- Smallest changes: keep scrap and rockets data.js:47-48; lower raider/reaver costs; raise BOARD_MULT battle.js:82; keep no lance. Use existing reload data.js:132 and overburn data.js:139.

### The Chorus — short-range attrition swarm
- Unit-count profile: swarm. Many cheap drone-spawn and spitters; brood-mothers are mobile spawners.
- Range profile: close. Tendrils and bio-plasma; spores for defence.
- Shield/survivability: no shields at all; hull regeneration and section repair. Survives by outlasting, not by avoiding.
- Movement: free first pivot. Keep pivot:1 data.js:107.
- Economy: converts battle damage into free regeneration; pays full price for new hulls and cannot buy shield refits.
- Win condition: grind enemy hulls down and win by rout/attrition.
- Lose condition: burst damage kills a ship before regeneration matters, or fire/acid bypasses the grind.
- Prohibition: cannot use shields; all Chorus hulls have sh:0.
- Smallest changes: keep no shields data.js:84-88; keep regrow, frenzy, regen data.js:84-87; keep pivot; make shield modules unavailable to Chorus. Use existing regrow data.js:141 and frenzy data.js:140.

### The Ithar — long-range shield-skirmisher, elite
- Unit-count profile: elite. Few, expensive, high-shield ships.
- Range profile: long. Pulsar lances, star torpedoes, and blink to keep distance.
- Shield/survivability: strong shields, weak hull and little armor; survives by shield cycling and evasion.
- Movement: blink and fan sails. Keep evadeAt:2 data.js:108 and blink data.js:142.
- Economy: pays premium for hull replacement, but shield repair/recharge is cheap; gains by avoiding hull damage.
- Win condition: skirmish, strip shields, and kill a flagship in a Hunt or Decapitation fight.
- Lose condition: shields are broken and the fragile hull is caught.
- Prohibition: cannot passively regrow hull; Ithar hulls have no regen or reanimate.
- Smallest changes: keep high shields and low hull data.js:90-94; keep blink and surge; remove hull-regeneration access; raise costs and lower hull counts. Use existing surge data.js:135 and blink data.js:142.

### The Deathless Dynasty — armored grinding advance, standard/elite
- Unit-count profile: standard to elite. Few, tough, expensive hulls.
- Range profile: mid to close. Gauss and doom arcs; no torpedo reliance.
- Shield/survivability: no shields; high armor, regeneration, and reanimation. Survives by refusing to die.
- Movement: phase through terrain and ships. Keep over:0 data.js:109.
- Economy: pays less for repair/reanimation, more for new hulls; losses are partly recovered through reanimation.
- Win condition: advance, grind, and win defend/attrition fights.
- Lose condition: focused fire kills sections before reanimation, or fast fleets avoid the grind.
- Prohibition: cannot launch squadrons; data.js:126 "sq:null" and Deathless hulls have no launch.
- Smallest changes: keep "reanimate:true" data.js:96, phase data.js:143, reclaim data.js:144, and over:0; remove squadron access entirely; keep no shields. Use existing gsentry/gauss data.js:21-22.

### Three changes the model would make first
1. Replace the shared price/class ladder with faction roster gates and cost curves. Data-only: change hull costs, roster access, and class counts so Voidsworn/Ithar are elite, Corsair/Chorus are swarm, Hegemony/Deathless are standard. This attacks findings 1, 5, and 10.
2. Replace the recycled command pool with six faction-specific commands and admiral curves. Data-only: new ADMIRALS.cmd entries and CMD_POW values in battle.js:827. This attacks finding 2.
3. Add the per-faction economy hook. ENGINE CHANGE, a faction economy table read by shipyard, repair, and reward code. Without it, "economy" remains a proposal, not a game rule. This attacks finding 9.

### How the model would prove the factions became different
Use fixed battle seeds (battle.js:287) and fixed fleet-power budgets (battle.js:133) to run mirror matches and cross-faction matches. Collect the existing telemetry: B.usage already records fire arcs, aimed shots, abilities, orders, commands, moves, and failed actions (battle.js:336); tel('command') records command use (battle.js:849); run_end records faction, sector, and fleet stats (campaign_meta.js:185). Prove difference with distributions, not just win rates:

- Range histogram: distance at firing should separate Hegemony/Ithar (long) from Corsair/Chorus (close).
- Unit-count profile: average hulls and squadron share per battle should separate elite, standard, and swarm factions.
- Survivability split: percentage of damage absorbed by shields vs armor vs regeneration/reanimation should separate Ithar/Hegemony from Chorus/Deathless.
- Action entropy: distribution of fire arcs, moves, abilities, and commands should differ; if every faction uses the same command at the same round, the change failed.
- Economy ledger: credits gained, repair spend, hull losses, and replacement spend should diverge by faction.
- Win/loss cause: routed, flagship killed, station lost, transports escaped, and reanimation count should map to each faction's stated win/lose condition.

Acceptance criterion: pairwise metric vectors diverge beyond noise while mirror win rates remain roughly balanced. If a faction only wins more but uses the same range, same command timing, and same hull-count curve, it is still a costume.

## Not checked

I did not examine shipyard purchase code, repair implementation, map/sector UI code, save/load, rendering/animation code, event resolver code, full boon/relic effect application beyond battle references, squadron UI control code, persistence, or any player-side autoplay/simulation harness. The pack contains no explicit player-policy simulator; the proof method above would need one or would need to reuse the enemy AI with a new harness.
