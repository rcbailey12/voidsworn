# Text accuracy audit - 2026-11-01

Report only. Browser source is the rules authority. No game files changed; no commit.

Findings: 54 rows (44 LIVE, 3 STORED ONLY, 3 DISCLOSURE, 4 VOICE). Coverage: 272 description/weapon rows. Godot literal text drift: 0 in either table; generated protocol drift: 0/192. Prior-review counts follow below.

## Method and scope

Read data.js, core.js, battle.js, campaign_run.js and campaign_meta.js, plus the display sites needed to judge the two prior reviews. Executed data.js in an isolated Node VM to enumerate final tables after Object.assign and splices. Compared every literal string leaf against both Godot JSON tables and all four rarity outputs of every protocol against campaign BOON_D. Rule findings below are static source traces, not claims of a played or simulated run.

The requested docs/REVIEW_PROTOCOL.md, docs/ship_pipeline/TEXTURE_PASS.md and docs/ship_pipeline/AUDIT_BRIEF.md are absent from this folder. Their instructions could not be applied. Scope questions were sent; absent an answer, this report includes material omissions, limits flavour checks to gameplay claims except the requested prior-review reconciliation, and uses browser behaviour for corrections.

Percent stat bonuses follow the game's normal additive convention; ordinary rounding, caps and the general distinction between capital ships and wings are not counted repeatedly as defects. Strong claims such as every, always, never, double and exact triggers are checked literally. DISCLOSURE rows identify accurate but underspecified text. VOICE rows are distinct from gameplay contradictions. STORED ONLY rows are incorrect data descriptions bypassed by current generated UI.

Protocol current/corrected text below is Common unless noted. Preserve the d(m) formula and substitute the corresponding rarity value in proposed corrections. For i_brace use 10/15/20% and 18/27/36 damage; s_ion 0.22/0.33/0.44; h_hatch one/two/two wings; a_crit 6/9/12% and x1.75/x1.88/x2; s_regen 18/27/36%; i_still 25/38/50%; e_hunt 20/30/40%. Duo and legendary descriptions are invariant.

## Findings

### M01 - ABILITIES.nova [LIVE]

- Text source: data.js:138.
- Current: "Spinal shell: 40 damage to a hex 3-9 away and 20 to everything adjacent. Hits friends too."
- Code: The aim hex must be in the prow arc. 40/20 are base damage, multiplied by ship damage and by 1.5 against squadrons, then resolved through shields, armor and criticals. Evidence: battle.js:1204-1217, battle.js:1225.
- Corrected: "Spinal shell: base 40 damage in a prow hex 3-9 away, 20 adjacent. Hits friends too."

### M02 - ABILITIES.launch [LIVE]

- Text source: data.js:136.
- Current: "Carriers start each battle with their wings in flight. This launches a replacement for a lost wing into an adjacent hex; each carrier has one spare wing per hangar slot."
- Code: Launch hulls include Hegemony cruisers and battleships. Replacements require an open adjacent hex, a spare, and fewer living wings than capacity. Evidence: data.js:76-77; battle.js:1157-1169.
- Corrected: "Launch ships start with wings in flight. Replace a lost wing in an open adjacent hex; one spare per hangar slot."

### M03 - ADMIRALS.ashgrove [LIVE]

- Text source: data.js:207.
- Current: "Squadrons deal +40% damage and carriers hold +1 wing."
- Code: The passive also gives every newly launched player squadron +25% hull. Hangar capacity is applied to all hulls with a base hangar, not a class filter. Evidence: data.js:204-235; core.js:224; battle.js:1152-1154.
- Corrected: "Squadrons deal +40% damage and launch ships hold +1 wing. Squadron hull +25%."

### M04 - ADMIRALS.reyes [LIVE]

- Text source: data.js:219.
- Current: "Squadrons deal +10% damage and cruisers hold +1 wing."
- Code: The passive also gives every newly launched player squadron +25% hull. Hangar capacity is applied to all hulls with a base hangar, not a class filter. Evidence: data.js:204-235; core.js:224; battle.js:1152-1154.
- Corrected: "Squadrons deal +10% damage and launch ships hold +1 wing. Squadron hull +25%."

### M05 - ADMIRALS.mott [LIVE]

- Text source: data.js:223.
- Current: "Squadrons deal +25% damage and hulks hold +1 wing."
- Code: The passive also gives every newly launched player squadron +25% hull. Hangar capacity is applied to all hulls with a base hangar, not a class filter. Evidence: data.js:204-235; core.js:224; battle.js:1152-1154.
- Corrected: "Squadrons deal +25% damage and hulks hold +1 wing. Squadron hull +25%."

### M06 - ADMIRALS.matriarch [LIVE]

- Text source: data.js:225.
- Current: "Spore swarms deal +25% damage and broods hold +1 swarm."
- Code: The passive also gives every newly launched player squadron +25% hull. Hangar capacity is applied to all hulls with a base hangar, not a class filter. Evidence: data.js:204-235; core.js:224; battle.js:1152-1154.
- Corrected: "Spore swarms deal +25% damage and broods hold +1 swarm. Swarm hull +25%."

### M07 - ADMIRALS.aelith [LIVE]

- Text source: data.js:229.
- Current: "Squadrons deal +25% damage and carriers hold +1 wing."
- Code: The passive also gives every newly launched player squadron +25% hull. Hangar capacity is applied to all hulls with a base hangar, not a class filter. Evidence: data.js:204-235; core.js:224; battle.js:1152-1154.
- Corrected: "Squadrons deal +25% damage and launch ships hold +1 wing. Squadron hull +25%."

### M08 - ADMIRALS.vaelen [LIVE]

- Text source: data.js:230.
- Current: "Lances deal +20% damage and gain +10 aim."
- Code: aim:10 is global; it is not restricted to lance-kind weapons. Evidence: data.js:229; core.js:223; battle.js:641, battle.js:669.
- Corrected: "Lances deal +20% damage; every weapon gains +10 aim."

### M09 - ADMIRALS.vorn.cmd [STORED ONLY]

- Text source: data.js:218.
- Current: "Every ship deals +30% damage this round."
- Code: hunt clears cooldown and fired flags on every torpedo weapon, in addition to the damage boost. These stored descriptions omit the reload. The current UI uses cmdDesc and already discloses it. Evidence: battle.js:1084, battle.js:1106; campaign_meta.js:69; ui3d.js:146.
- Corrected: "Torpedoes reload at once and every ship deals +30% damage this round."

### M10 - ADMIRALS.anuket.cmd [STORED ONLY]

- Text source: data.js:235.
- Current: "Every ship deals +30% damage this round."
- Code: hunt clears cooldown and fired flags on every torpedo weapon, in addition to the damage boost. These stored descriptions omit the reload. The current UI uses cmdDesc and already discloses it. Evidence: battle.js:1084, battle.js:1106; campaign_meta.js:69; ui3d.js:146.
- Corrected: "Torpedoes reload at once and every ship deals +30% damage this round."

### M11 - ADMIRALS.khepra.cmd [STORED ONLY]

- Text source: data.js:236.
- Current: "All shields refill and your ships take 40% less hull damage this round."
- Code: Shieldless hulls receive 50/60/70% hull protection, not 40/50/60%. The own-faction fleet has no shields. cmdDesc already uses the correct faction-specific text. Evidence: battle.js:1086, battle.js:1097, battle.js:1107; data.js:96-101.
- Corrected: "Your ships take 50% less hull damage this round. Gets stronger each round you hold it."

### M12 - ADMIRALS.ashgrove.cmd [LIVE]

- Text source: data.js:214.
- Current: "Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round."
- Code: The launch trigger is ab===launch, including Hegemony Cruiser/Battleship hulls, not Carrier class. The generated cmdDesc also still calls these carriers. An open adjacent hex is required. Evidence: battle.js:1085, battle.js:1110-1111; data.js:76-77.
- Corrected: "Every launch ship sends out an extra wing if there is room, then all squadrons strike again with +50% damage this round."

### M13 - ADMIRALS.reyes.cmd [LIVE]

- Text source: data.js:219.
- Current: "Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round."
- Code: The launch trigger is ab===launch, including Hegemony Cruiser/Battleship hulls, not Carrier class. The generated cmdDesc also still calls these carriers. An open adjacent hex is required. Evidence: battle.js:1085, battle.js:1110-1111; data.js:76-77.
- Corrected: "Every launch ship sends out an extra wing if there is room, then all squadrons strike again with +50% damage this round."

### M14 - ADMIRALS.mott.cmd [LIVE]

- Text source: data.js:223.
- Current: "Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round."
- Code: The launch trigger is ab===launch, including Hegemony Cruiser/Battleship hulls, not Carrier class. The generated cmdDesc also still calls these carriers. An open adjacent hex is required. Evidence: battle.js:1085, battle.js:1110-1111; data.js:76-77.
- Corrected: "Every launch ship sends out an extra wing if there is room, then all squadrons strike again with +50% damage this round."

### M15 - ADMIRALS.aelith.cmd [LIVE]

- Text source: data.js:229.
- Current: "Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round."
- Code: The launch trigger is ab===launch, including Hegemony Cruiser/Battleship hulls, not Carrier class. The generated cmdDesc also still calls these carriers. An open adjacent hex is required. Evidence: battle.js:1085, battle.js:1110-1111; data.js:76-77.
- Corrected: "Every launch ship sends out an extra wing if there is room, then all squadrons strike again with +50% damage this round."

### M16 - MODULES.hangar [LIVE]

- Text source: data.js:165.
- Current: "Carriers only: +1 squadron in flight."
- Code: The installation gate is launch ability plus a positive base hangar, not Carrier class. Evidence: core.js:251; core.js:224.
- Corrected: "Launch ships only: +1 squadron in flight."

### M17 - WTRAITS.plasma [LIVE]

- Text source: data.js:46.
- Current: "a quarter burns through shields"
- Code: The trait also adds 1 damage to every shot. Evidence: data.js:46; battle.js:703-709.
- Corrected: "a quarter burns through shields, +1 damage"

### M18 - WTRAITS.las [DISCLOSURE]

- Text source: data.js:44.
- Current: "holds its aim at long range"
- Code: Qualitative wording omits the +4 aim and the exact falloff reduction. This is a disclosure improvement, not a false claim. Evidence: data.js:44; battle.js:640-641.
- Corrected: "+4 aim, half the long-range aim falloff"

### M19 - WTRAITS.scrap [DISCLOSURE]

- Text source: data.js:47.
- Current: "an extra shot, wild aim, lucky crits"
- Code: The direction is correct, but fitting text hides the exact -12 aim and +3 critical percentage points. Evidence: data.js:47; battle.js:641, battle.js:713.
- Corrected: "an extra shot, -12 aim, +3% crit"

### M20 - WTRAITS.needle [DISCLOSURE]

- Text source: data.js:51.
- Current: "precise: better aim and more criticals"
- Code: The direction is correct; the trait hides +6 aim and +8 critical percentage points. Evidence: data.js:51; battle.js:641, battle.js:713.
- Corrected: "precise: +6 aim, +8% crit"

### M21 - WTRAITS.hellfire [LIVE]

- Text source: data.js:45.
- Current: "sets the target burning"
- Code: Fire is set only by positive hull damage to a non-squadron target. A shield-only hit does not ignite. Base fire is 6 per own-side turn for two ticks. Evidence: battle.js:717; battle.js:388.
- Corrected: "hull hits ignite ships: 6 damage a turn for 2 turns"

### M22 - WTRAITS.spines [LIVE]

- Text source: data.js:49.
- Current: "each hit strips 3% armor (down to 15% less)"
- Code: Armor shred requires positive hull damage on a non-squadron target; 3% and 15% mean armor percentage points. Evidence: battle.js:717-719, battle.js:709.
- Corrected: "hull hits strip 3 armor points, up to 15"

### M23 - WTRAITS.acid [LIVE]

- Text source: data.js:50.
- Current: "acid eats 4 hull a turn for 2 turns, through shields and armor"
- Code: Acid is set only on a positive hull hit to a non-squadron target, not every hit. Evidence: battle.js:717-719; battle.js:387.
- Corrected: "hull hits leave acid: 4 hull a turn for 2 turns, through shields and armor"

### M24 - BOONS.i_still [LIVE]

- Text source: data.js:633.
- Current: "A ship that hasn't moved this activation deals +25% damage with broadsides and batteries."
- Code: Hegemony synchronized damage and Anchored Volley do not stack; only the larger bonus applies. Evidence: battle.js:679.
- Corrected: "Unmoved ships gain +25% broadside and battery damage. Uses the larger of this and synchronized fire."

### M25 - BOONS.i_brace [LIVE]

- Text source: data.js:635.
- Current: "Bracing blocks an extra 10%, and braced ships strike back: every enemy attack that hits one takes 18 damage in return."
- Code: Retaliation is once per direct weapon volley that hits, while neither unit is flagged dead. It can fire on a lethal incoming hit before killUnit runs. Travelling torpedo impacts and point-defense interceptions are excluded. Evidence: battle.js:825; battle.js:1056.
- Corrected: "Bracing blocks an extra 10%. Direct volleys that hit it deal 18 damage back; torpedoes do not."

### M26 - BOONS.s_ion [LIVE]

- Text source: data.js:640.
- Current: "Your weapons strip 22% more shield per hit."
- Code: ionPlus adds 0.22 to the shield multiplier. A base 2.5 ion weapon becomes 2.72, an 8.8% relative increase, not 22%. Evidence: battle.js:665, battle.js:707-708; data.js:13.
- Corrected: "Your weapons gain +0.22 to their shield damage multiplier."

### M27 - BOONS.h_hatch [LIVE]

- Text source: data.js:644.
- Current: "Carriers field an extra wing."
- Code: Capacity is added to any base-hangar hull, including the Hegemony Cruiser/Battleship. Evidence: core.js:224; data.js:76-77.
- Corrected: "Launch ships field an extra wing."

### M28 - BOONS.a_crit [LIVE]

- Text source: data.js:652.
- Current: "+6% critical chance, criticals deal x1.75, and every critical hit wrecks a ship system."
- Code: Critical system damage is attempted at most once per weapon volley, not once per critical hit. systemDamage can also return no system. Evidence: battle.js:806; battle.js:713.
- Corrected: "+6% critical chance, criticals deal x1.75, and a critical volley damages a system where possible."

### M29 - BOONS.d_ionlance [LIVE]

- Text source: data.js:670.
- Current: "Lances strip double shield per hit."
- Code: ionLance adds 1 to the multiplier. An ion cannon goes from 2.5 to 3.5, not 5. Only ordinary multiplier-1 lances literally double. Evidence: battle.js:665; data.js:13.
- Corrected: "Lances gain +1 to their shield damage multiplier."

### M30 - BOONS.d_burnswarm [LIVE]

- Text source: data.js:671.
- Current: "Squadron hits have a 30% chance to start a fire."
- Code: Only positive hull hits on non-squadrons can ignite. Evidence: battle.js:715-716.
- Corrected: "Squadron hull hits on ships have a 30% chance to start a fire."

### M31 - BOONS.d_inferno [LIVE]

- Text source: data.js:673.
- Current: "Broadside hits have a 40% chance to start a fire, and your fires burn hotter (10 a turn) and a turn longer."
- Code: Ignition requires positive hull damage to a non-squadron target. fireDmg/fireLong affect the random-ignition branch, not every source of fire such as hellfire or chain blasts. Evidence: battle.js:715-717; battle.js:957.
- Corrected: "Broadside hull hits have a 40% chance to ignite ships for 10 a turn for 3 turns."

### M32 - BOONS.e_hunt [LIVE]

- Text source: data.js:666.
- Current: "+20% damage against ships below half hull, and ships you hit while below half can no longer regrow hull or reanimate."
- Code: Pyre is checked against hull BEFORE this hit. Its flag blocks passive regeneration, feeding and reassembly, but direct Regrow/Reclaim, Restore and Feast healing do not check it. Evidence: battle.js:677, battle.js:720-721, battle.js:386, battle.js:509-518, battle.js:1193-1194, battle.js:1108, battle.js:953.
- Corrected: "+20% damage against ships already below half hull; hits there stop passive regrowth, feeding and reassembly."

### M33 - BOONS.e_spread [LIVE]

- Text source: data.js:683.
- Current: "Torpedoes that run wide still burst: every enemy within 1 hex of the aim hex takes 30% of one torpedo's damage."
- Code: The burst happens only if NO valid original or stray target is found. A miss roll against a found target causes no burst. The burst excludes squadrons. Evidence: battle.js:842-853.
- Corrected: "If a torpedo finds no target, enemy ships within 1 hex of its aim hex take 30% of one torpedo's damage."

### M34 - BOONS.L_hunger [LIVE]

- Text source: data.js:686.
- Current: "Legendary. Carriers field two more wings and never run out of spares."
- Code: All base-hangar hulls gain capacity, and spares are set to 99, then still decremented and checked. They are very plentiful, not literally endless. Evidence: core.js:224; battle.js:1158, battle.js:1169, battle.js:1201.
- Corrected: "Legendary. Launch ships field two more wings and carry 99 spares."

### M35 - BOONS.L_star [LIVE]

- Text source: data.js:687.
- Current: "Legendary. Lances always hit (95%) and pass straight through shields."
- Code: 95% is the ordinary forced hit chance, but enemy Surge reduces this to 75%. Shield bypass is correct. Evidence: battle.js:655; battle.js:703.
- Corrected: "Legendary. Lances hit at 95% (75% against Full burn) and pass straight through shields."

### M36 - BOONS.L_storm [LIVE]

- Text source: data.js:685.
- Current: "Legendary. Every shield facing on every ship refills completely at the start of each of your turns."
- Code: Storm regeneration is skipped while the shield generator remains disabled, and terrain storm damage is applied after refill. It is not an unconditional full shield at turn start. Evidence: battle.js:384, battle.js:389, battle.js:392.
- Corrected: "Legendary. Working shield generators refill every facing at the start of your turn, before storm damage."

### M37 - BOONS.s_regen [LIVE]

- Text source: data.js:641.
- Current: "Each turn, every shield facing on every ship restores an extra 18% of its strength."
- Code: The additional recharge is skipped while the shield generator remains disabled. Evidence: battle.js:389.
- Corrected: "Each turn, working shield generators restore an extra 18% of each facing's strength."

### M38 - RELICS.cogitator [LIVE]

- Text source: data.js:190.
- Current: "Each ship's first attack in every battle hits 95% of the time."
- Code: The guarantee applies to the first weapon attack, not an entire multiweapon volley. Enemy Surge reduces its hit chance from 95% to 75%. Evidence: battle.js:656, battle.js:763, battle.js:782.
- Corrected: "Each ship's first weapon attack hits at 95% (75% against Full burn)."

### M39 - RELICS.banner [LIVE]

- Text source: data.js:196.
- Current: "Every enemy ship one of your ships destroys gives that ship +15% damage for the rest of the battle (up to +45%)."
- Code: Only non-squadron victims trigger this. A squadron kill of a ship awards the damage stack to its parent launch ship, not the wing. Evidence: battle.js:949, battle.js:686.
- Corrected: "Destroying an enemy ship grants +15% ship damage, up to +45%. Wing kills grant it to their launch ship; downed wings do not count."

### M40 - ASPECTS.hive [LIVE]

- Text source: data.js:694.
- Current: "Your flagship launches a squadron wing at the start of every battle (+1 wing if it is already a carrier), and its wings deal +30% damage."
- Code: The +1 capacity test is base hangar, not Carrier class. Hegemony launch cruisers qualify. A new hive hull gets one opening wing but no Launch ability, so cannot normally replace it. Evidence: core.js:224; battle.js:1157-1169.
- Corrected: "Your flagship starts with a wing (+1 if it has a hangar); its wings deal +30% damage. No new Launch ability."

### M41 - ASPECTS.storm [LIVE]

- Text source: data.js:697.
- Current: "Your flagship's weapons strip 50% more shield per hit, and its shields recharge twice as fast."
- Code: ionPlus adds 0.5 to the shield multiplier, not a relative 50% to weapons already above 1. A Hegemony ion cannon goes from 2.5 to 3.0. Evidence: battle.js:665; core.js:221.
- Corrected: "Your flagship gains +0.5 to weapon shield damage multipliers, and shields recharge twice as fast."

### M42 - MASTERY_PERKS.4 [LIVE]

- Text source: data.js:584.
- Current: "Your flagship starts at Mk II, its captain a Captain with a perk."
- Code: Rank index 2 is Captain only for Crusade/Hegemony. It is Howler, Throat, Facet or Umbra for the others. The earlier review's list of rank names is stale too. Evidence: core.js:359; data.js:520-525.
- Corrected: "Your flagship starts at Mk II, its captain two ranks up with a perk."

### M43 - NEM_TRAITS.brood [LIVE]

- Text source: data.js:450.
- Current: "Enemy carriers field one more wing."
- Code: Trait increases launch capacity and spares after deployWings has already run, so it does not create an extra opening wing. Evidence: battle.js:349, battle.js:354, battle.js:572.
- Corrected: "Enemy launch ships can replace one more wing and carry one more spare."

### M44 - NEM_TRAITS.artillery [LIVE]

- Text source: data.js:450.
- Current: "Enemy guns reach 1 hex further."
- Code: Flak and squadron guns are explicitly excluded. Evidence: battle.js:571.
- Corrected: "Enemy guns other than point defense and squadron weapons reach 1 hex further."

### M45 - NEM_TRAITS.undying [LIVE]

- Text source: data.js:454.
- Current: "One more enemy ship reassembles after falling."
- Code: Adds an Archive return allowance, subject to eligibility, space and Funeral Pyre. Does not guarantee a successful return. Evidence: battle.js:573, battle.js:518-525.
- Corrected: "One more eligible enemy ship can reassemble after falling."

### M46 - NEM_ADAPT.pd [LIVE]

- Text source: data.js:439.
- Current: "Two enemy ships bolt on point defense."
- Code: Adds guns to up to two capital ships lacking flak. Can add fewer than two or none. Evidence: battle.js:575.
- Corrected: "Up to two enemy ships without point defense bolt it on."

### M47 - NEM_ADAPT_FAC.deathless.special [LIVE]

- Text source: data.js:484.
- Current: "One more enemy ship reassembles."
- Code: Adds an allowance, not an unconditional resurrection. Evidence: battle.js:573, battle.js:518-525.
- Corrected: "One more eligible enemy ship can reassemble."

### M50 - NEM_PERSONA.methodical [LIVE]

- Text source: data.js:460.
- Current: "Holds his line and advances only in formation."
- Code: Only threat weighting is changed. No formation-only movement gate exists. Raw male wording also remains. Evidence: battle.js:593; battle.js:1379-1386.
- Corrected: "Advances cautiously under fire."

### M51 - NEM_PERSONA.patient [VOICE]

- Text source: data.js:456.
- Current: "Waits for you to come to him."
- Code: Raw male pronoun remains. This is voice accuracy, not a numerical rules discrepancy. Evidence: data.js:458; campaign_run.js:72-81.
- Corrected: "Waits for you to close in."

### M52 - NEM_PERSONA.proud [VOICE]

- Text source: data.js:459.
- Current: "Leads from the front with his flagship."
- Code: Raw male pronoun remains. flagFront does reduce caution for its flagship. Evidence: data.js:459; battle.js:593.
- Corrected: "Leads from the front, flagship first."

### M53 - NEM_ADAPT_FAC.hegemony.special [VOICE]

- Text source: data.js:487.
- Current: "His synchronized fire reaches one hex further."
- Code: The mechanics are correct, but this description is raw male text for generated female commanders. Evidence: data.js:487-488; campaign_run.js:268, campaign_run.js:294.
- Corrected: "Synchronized fire reaches one hex further."

### M54 - NEM_ADAPT_FAC.voidsworn.special [VOICE]

- Text source: data.js:488.
- Current: "His ships deal 8% more damage."
- Code: The mechanics are correct, but this description is raw male text for generated female commanders. Evidence: data.js:487-488; campaign_run.js:268, campaign_run.js:294.
- Corrected: "Enemy ships deal 8% more damage."

### M55 - WING_STANCES.screen [LIVE]

- Text source: data.js:509.
- Current: "Wings stay within 2 hexes of their carrier, hunt enemy craft first, and shoot down torpedoes aimed at ships beside them."
- Code: The attack-position leash is WING_SCREEN_R+1, or 3 hexes, not 2. Torpedo interception covers targets within 2 hexes of the wing, not only adjacent targets. A moving carrier can also leave a wing temporarily outside its leash. Evidence: battle.js:617, battle.js:627, battle.js:1134-1147.
- Corrected: "Wings fight within 3 hexes of their launch ship, favour enemy craft, and intercept torpedoes aimed within 2 hexes of them."

### M56 - BOONS.e_reload [LIVE]

- Text source: data.js:663.
- Current: Common "Torpedoes reload 1 turn faster." Rare/Epic "Torpedoes reload 2 turns faster."
- Code: Every torpedo-kind weapon has base cooldown 2. mkWeapon clamps the resulting cooldown to at least 1. Both torpCd:1 and torpCd:2 therefore produce cooldown 1. Rare/Epic do not remove two actual turns, and existing reload bonuses can leave no further benefit. Evidence: data.js:8, data.js:15, data.js:20; core.js:210; godot/rules/rules.gd:387. A Node check executing the real mkWeapon confirmed base/Common/Rare values 2/1/1 for torp, htorp and startorp.
- Corrected: "Torpedo reload time -2 turns, to a minimum of 1. Current torpedoes gain 1 turn."
- Common correction: "Torpedo reload time -1 turn, to a minimum of 1."

## Complete requested-table coverage

Each row records the current description and the code used to compare it. OK means no additional mismatch found beyond the findings already listed. Weapon names and faction aliases have no prose d field; the W rows record the numeric rule record instead. A display name containing lance does not change a weapon's kind (Hegemony plasma lances are battery-kind). This is naming, not a claim of armor piercing.

### W

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| W.autocannon | {"n":"Autocannon","k":"battery","shots":3,"dmg":5,"r":4,"opt":2,"acc":80,"fall":8,"crit":5} | OK | data.js:3; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.flak | {"n":"Flak battery","k":"flak","shots":3,"dmg":3,"r":2,"opt":2,"acc":80,"fall":10,"vsSq":3,"vsCap":0.6} | OK | data.js:4; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.battery | {"n":"Gun battery","k":"battery","shots":4,"dmg":6,"r":5,"opt":3,"acc":72,"fall":8,"crit":5} | OK | data.js:5; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.hbattery | {"n":"Heavy gun battery","k":"battery","shots":5,"dmg":7,"r":5,"opt":3,"acc":72,"fall":8,"crit":6} | OK | data.js:6; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.lance | {"n":"Lance array","k":"lance","shots":1,"dmg":20,"r":7,"opt":6,"acc":82,"fall":6,"pierce":0.6,"crit":10} | OK | data.js:7; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.torp | {"n":"Torpedo salvo","k":"torp","shots":1,"dmg":42,"r":6,"opt":6,"acc":64,"fall":0,"pierce":0.3,"crit":15,"cd":2,"evMult":2} | OK | data.js:8; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.turret | {"n":"Dorsal turret","k":"battery","shots":2,"dmg":8,"r":5,"opt":3,"acc":74,"fall":8,"crit":5} | OK | data.js:9; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.laser | {"n":"Laser cannon","k":"battery","shots":2,"dmg":7,"r":4,"opt":3,"acc":80,"fall":8,"crit":5} | OK | data.js:10; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.turbo | {"n":"Pulse laser","k":"battery","shots":2,"dmg":9,"r":5,"opt":3,"acc":74,"fall":8,"crit":5} | OK | data.js:11; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.hturbo | {"n":"Heavy pulse laser","k":"battery","shots":3,"dmg":9,"r":6,"opt":4,"acc":72,"fall":7,"crit":6} | OK | data.js:12; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.ion | {"n":"Ion cannon","k":"lance","shots":1,"dmg":12,"r":6,"opt":5,"acc":80,"fall":6,"ion":2.5,"crit":4} | OK | data.js:13; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.scatter | {"n":"Scatter cannons","k":"battery","shots":5,"dmg":5,"r":3,"opt":2,"acc":78,"fall":10,"crit":6} | OK | data.js:14; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.htorp | {"n":"Heavy torpedoes","k":"torp","shots":2,"dmg":34,"r":6,"opt":6,"acc":60,"fall":0,"pierce":0.3,"crit":15,"cd":2,"evMult":2} | OK | data.js:15; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.tendril | {"n":"Boarding tendrils","k":"bio","shots":2,"dmg":13,"r":1,"opt":1,"acc":85,"fall":0,"pierce":0.5,"crit":12} | OK | data.js:16; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.bioplasma | {"n":"Bile spray","k":"bio","shots":2,"dmg":12,"r":4,"opt":3,"acc":74,"fall":8,"pierce":0.2,"crit":8} | OK | data.js:17; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.spores | {"n":"Spore drifts","k":"flak","shots":3,"dmg":4,"r":2,"opt":2,"acc":78,"fall":8,"vsSq":3,"vsCap":0.6} | OK | data.js:18; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.pulsar | {"n":"Prism lance","k":"lance","shots":2,"dmg":12,"r":6,"opt":5,"acc":80,"fall":6,"pierce":0.6,"crit":10} | OK | data.js:19; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.startorp | {"n":"Star torpedo","k":"torp","shots":1,"dmg":38,"r":5,"opt":5,"acc":66,"fall":0,"pierce":0.4,"crit":15,"cd":2,"evMult":2} | OK | data.js:20; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.gauss | {"n":"Null cannon","k":"gauss","shots":3,"dmg":6,"r":5,"opt":3,"acc":74,"fall":8,"pierce":0.6,"crit":5} | OK | data.js:21; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.gsentry | {"n":"Null sentries","k":"flak","shots":2,"dmg":4,"r":3,"opt":3,"acc":80,"fall":10,"vsSq":3,"vsCap":0.6} | OK | data.js:22; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.doom | {"n":"Corona arc","k":"lance","shots":1,"dmg":40,"r":5,"opt":4,"acc":78,"fall":6,"pierce":0.6,"crit":12,"cd":2} | OK | data.js:23; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.shard | {"n":"Shard cannon","k":"battery","shots":3,"dmg":6,"r":4,"opt":2,"acc":80,"fall":8,"crit":6,"vsSq":1.6} | OK | data.js:24; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.guns | {"n":"Interceptor guns","k":"sq","shots":3,"dmg":4,"r":1,"opt":1,"acc":82,"fall":0,"vsSq":2.2,"vsCap":0.5} | OK | data.js:25; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.bombs | {"n":"Bomb payload","k":"sq","shots":2,"dmg":9,"r":1,"opt":1,"acc":78,"fall":0,"pierce":0.6,"vsSq":0.2,"crit":10} | OK | data.js:26; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |
| W.sporeb | {"n":"Spore burst","k":"sq","shots":2,"dmg":10,"r":1,"opt":1,"acc":78,"fall":0,"pierce":0.6,"vsSq":0.3,"crit":8} | OK | data.js:27; core.js:207-213; battle.js:634-657, battle.js:666-723, battle.js:829-853 |

### WTRAITS

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| WTRAITS.las | holds its aim at long range | M18 | data.js:44; data.js:43-56; battle.js:641, battle.js:709-719, battle.js:842 |
| WTRAITS.hellfire | sets the target burning | M21 | data.js:45; data.js:43-56; battle.js:641, battle.js:709-719, battle.js:842 |
| WTRAITS.plasma | a quarter burns through shields | M17 | data.js:46; data.js:43-56; battle.js:641, battle.js:709-719, battle.js:842 |
| WTRAITS.scrap | an extra shot, wild aim, lucky crits | M19 | data.js:47; data.js:43-56; battle.js:641, battle.js:709-719, battle.js:842 |
| WTRAITS.rockets | a rocket salvo: hard to dodge, but point defense can shoot rockets down | OK | data.js:48; data.js:43-56; battle.js:641, battle.js:709-719, battle.js:842 |
| WTRAITS.spines | each hit strips 3% armor (down to 15% less) | M22 | data.js:49; data.js:43-56; battle.js:641, battle.js:709-719, battle.js:842 |
| WTRAITS.acid | acid eats 4 hull a turn for 2 turns, through shields and armor | M23 | data.js:50; data.js:43-56; battle.js:641, battle.js:709-719, battle.js:842 |
| WTRAITS.needle | precise: better aim and more criticals | M20 | data.js:51; data.js:43-56; battle.js:641, battle.js:709-719, battle.js:842 |
| WTRAITS.star | fast: hard to dodge | OK | data.js:52; data.js:43-56; battle.js:641, battle.js:709-719, battle.js:842 |
| WTRAITS.gauss | ignores half of armor | OK | data.js:53; data.js:43-56; battle.js:641, battle.js:709-719, battle.js:842 |

### ABILITIES

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| ABILITIES.evasive | +25 evasion until your next turn and +2 movement now. | OK | data.js:133; battle.js:1165-1225 |
| ABILITIES.reload | Torpedo tubes are ready to fire again immediately. | OK | data.js:134; battle.js:1165-1225 |
| ABILITIES.focus | All of this ship's weapons deal +30% damage this turn. | OK | data.js:135; battle.js:1165-1225 |
| ABILITIES.launch | Carriers start each battle with their wings in flight. This launches a replacement for a lost wing into an adjacent hex; each carrier has one spare wing per hangar slot. | M02 | data.js:136; battle.js:1165-1225 |
| ABILITIES.surge | Every shield facing restored to full strength. | OK | data.js:137; battle.js:1165-1225 |
| ABILITIES.nova | Spinal shell: 40 damage to a hex 3-9 away and 20 to everything adjacent. Hits friends too. | M01 | data.js:138; battle.js:1165-1225 |
| ABILITIES.ionpulse | Every enemy ship within 4 hexes loses half of each shield facing. | OK | data.js:140; battle.js:1165-1225 |
| ABILITIES.overburn | +3 movement now, and a ram this turn hits 50% harder. | OK | data.js:141; battle.js:1165-1225 |
| ABILITIES.frenzy | All of this ship's weapons deal +30% damage this turn. | OK | data.js:142; battle.js:1165-1225 |
| ABILITIES.regrow | Regrow 25% of this ship's hull right now. | OK | data.js:143; battle.js:1165-1225 |
| ABILITIES.blink | Jump to any open hex within 3, straight past rocks and ships. Tap the hex. | OK | data.js:144; battle.js:1165-1225 |
| ABILITIES.phase | +25 evasion until your next turn and +2 movement now. | OK | data.js:145; battle.js:1165-1225 |
| ABILITIES.reclaim | Restore 20% hull to your most damaged ship within 3 hexes (this one included). | OK | data.js:146; battle.js:1165-1225 |

### MODULES

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| MODULES.prow | +15% hull, +5% armor. | OK | data.js:154; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.auspex | +10 aim for every weapon. | OK | data.js:155; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.drive | +1 speed. | OK | data.js:156; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.gyro | +1 turn allowance, +5 evasion. | OK | data.js:157; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.capacitor | +30% shield strength. | OK | data.js:158; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.regen | +50% shield regeneration. | OK | data.js:159; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.loaders | Battery weapons fire +1 shot. | OK | data.js:160; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.crystal | Lance damage +25%. | OK | data.js:161; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.magazine | Torpedo reload time -1 turn, +15% torpedo damage. | OK | data.js:162; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.flakplus | Point defense +2 shots and +1 range. | OK | data.js:163; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.damcon | Repair 4% hull at the start of each of your turns. | OK | data.js:164; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.hangar | Carriers only: +1 squadron in flight. | M16 | data.js:165; core.js:207-226, core.js:246-253; battle.js:386 |
| MODULES.cogitator | +10% critical chance. | OK | data.js:166; core.js:207-226, core.js:246-253; battle.js:386 |

### PERKS

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| PERKS.gunnery | +10 aim. | OK | data.js:170; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.killer | +10% critical chance. | OK | data.js:171; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.deflector | +40% shield regeneration. | OK | data.js:172; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.ironhull | +15% max hull. | OK | data.js:173; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.helm | +1 speed. | OK | data.js:174; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.steady | Ignore the first 2 hexes of long-range penalty. | OK | data.js:175; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.broad | Broadside weapons +15% damage. | OK | data.js:176; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.lanceadept | Lance and torpedo damage +15%. | OK | data.js:177; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.stubborn | Brace for impact blocks an extra 15%. | OK | data.js:178; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.rapid | Ability cooldowns -1. | OK | data.js:179; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.wing | Squadrons launched by this ship deal +30% damage. | OK | data.js:180; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.hunter | +20% damage against ships below half hull. | OK | data.js:181; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.laststand | Once per battle, survive a killing blow at 1 hull. | OK | data.js:182; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |
| PERKS.flanker | +20% damage on rear-arc hits. | OK | data.js:183; core.js:217-226; battle.js:640-713, battle.js:940, battle.js:1056-1057 |

### RELICS

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| RELICS.martyr | When one of your ships is destroyed, every other ship repairs 15% of its hull. | OK | data.js:189; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |
| RELICS.cogitator | Each ship's first attack in every battle hits 95% of the time. | M38 | data.js:190; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |
| RELICS.lattice | Shields +15% across the fleet. | OK | data.js:191; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |
| RELICS.spore | Every ship regenerates 3 hull per turn. | OK | data.js:192; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |
| RELICS.phylactery | The first of your ships destroyed each battle restarts at 25% hull. | OK | data.js:193; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |
| RELICS.ledger | +25% credits from battles. | OK | data.js:194; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |
| RELICS.compass | +1 speed across the fleet. | OK | data.js:195; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |
| RELICS.banner | Every enemy ship one of your ships destroys gives that ship +15% damage for the rest of the battle (up to +45%). | M39 | data.js:196; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |
| RELICS.salvage | After each battle, gain 15 credits and repair 8% hull. | OK | data.js:197; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |
| RELICS.coils | Ability cooldowns -1 across the fleet. | OK | data.js:198; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |
| RELICS.logbook | +30% captain experience. | OK | data.js:199; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |
| RELICS.armourweave | +6% armor across the fleet. | OK | data.js:200; core.js:172, core.js:206, core.js:241; battle.js:656, battle.js:940-957; campaign_run.js:414-416 |

### ADMIRALS

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| ADMIRALS.vex | Broadside weapons deal +15% damage. | OK | data.js:205; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.vex.cmd | Every ship fires a free volley at the best target its guns can reach, right now. | OK at tier 1; see Command note | data.js:212; battle.js:1077-1111 |
| ADMIRALS.malek | Torpedoes reload a turn faster. +50% damage on rear-arc hits. | OK | data.js:206; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.malek.cmd | Torpedoes reload at once and every ship deals +30% damage this round. | OK at tier 1; see Command note | data.js:213; battle.js:1077-1111 |
| ADMIRALS.ashgrove | Squadrons deal +40% damage and carriers hold +1 wing. | M03 | data.js:207; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.ashgrove.cmd | Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | M12 | data.js:214; battle.js:1077-1111 |
| ADMIRALS.thale | All ships +15% hull and +10% shields. | OK | data.js:208; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.thale.cmd | All shields refill and your ships take 40% less hull damage this round. | OK at tier 1; see Command note | data.js:215; battle.js:1077-1111 |
| ADMIRALS.kassar | Batteries fire one extra shot per volley, but every gun hits 5% lighter. | OK | data.js:217; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.kassar.cmd | Every ship fires a free volley at the best target its guns can reach, right now. | OK at tier 1; see Command note | data.js:217; battle.js:1077-1111 |
| ADMIRALS.vorn | +10 aim and +10% critical-hit chance. | OK | data.js:218; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.vorn.cmd | Every ship deals +30% damage this round. | M09 | data.js:218; battle.js:1077-1111 |
| ADMIRALS.reyes | Squadrons deal +10% damage and cruisers hold +1 wing. | M04 | data.js:219; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.reyes.cmd | Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | M13 | data.js:219; battle.js:1077-1111 |
| ADMIRALS.maren | All ships +15% hull and +10% shields. | OK | data.js:220; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.maren.cmd | All shields refill and your ships take 40% less hull damage this round. | OK at tier 1; see Command note | data.js:220; battle.js:1077-1111 |
| ADMIRALS.grax | +1 speed for every ship and +10% damage. | OK | data.js:221; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.grax.cmd | Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round. | OK at tier 1; see Command note | data.js:221; battle.js:1077-1111 |
| ADMIRALS.sable | +50% damage on rear-arc hits and +10% crit chance. | OK | data.js:222; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.sable.cmd | Torpedoes reload at once and every ship deals +30% damage this round. | OK at tier 1; see Command note | data.js:222; battle.js:1077-1111 |
| ADMIRALS.mott | Squadrons deal +25% damage and hulks hold +1 wing. | M05 | data.js:223; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.mott.cmd | Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | M14 | data.js:223; battle.js:1077-1111 |
| ADMIRALS.vesh | Ships patch 5% of their hull each round and have +10% armor. | OK | data.js:224; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.vesh.cmd | Every ship repairs 25% of its hull and patches damaged sections, even destroyed ones. | OK at tier 1; see Command note | data.js:224; battle.js:1077-1111 |
| ADMIRALS.matriarch | Spore swarms deal +25% damage and broods hold +1 swarm. | M06 | data.js:225; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.matriarch.cmd | Every brood releases an extra swarm (even past its limit), then all swarms strike again at once with +50% damage this round. | OK at tier 1; see Command note | data.js:225; battle.js:1077-1111 |
| ADMIRALS.razormaw | +1 speed and +15% damage on rear-arc hits. | OK | data.js:226; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.razormaw.cmd | Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round. | OK at tier 1; see Command note | data.js:226; battle.js:1077-1111 |
| ADMIRALS.mending | Ships regrow 4% of their hull each round. | OK | data.js:227; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.mending.cmd | Every ship regrows 25% of its hull and heals damaged sections, even destroyed ones. | OK at tier 1; see Command note | data.js:227; battle.js:1077-1111 |
| ADMIRALS.voice | +15% damage with every weapon. | OK | data.js:228; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.voice.cmd | Every ship spits a free volley at the best target it can reach, right now. | OK at tier 1; see Command note | data.js:228; battle.js:1077-1111 |
| ADMIRALS.aelith | Squadrons deal +25% damage and carriers hold +1 wing. | M07 | data.js:229; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.aelith.cmd | Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round. | M15 | data.js:229; battle.js:1077-1111 |
| ADMIRALS.vaelen | Lances deal +20% damage and gain +10 aim. | M08 | data.js:230; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.vaelen.cmd | Every ship fires a free volley at the best target its guns can reach, right now. | OK at tier 1; see Command note | data.js:230; battle.js:1077-1111 |
| ADMIRALS.thorne | +8 evasion for every ship. | OK | data.js:231; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.thorne.cmd | Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round. | OK at tier 1; see Command note | data.js:231; battle.js:1077-1111 |
| ADMIRALS.mirelle | All ships +15% shields, and shields recharge 20% faster. | OK | data.js:232; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.mirelle.cmd | All shields refill and your ships take 40% less hull damage this round. | OK at tier 1; see Command note | data.js:232; battle.js:1077-1111 |
| ADMIRALS.nekhet | Ships regrow 4% of their hull each round. | OK | data.js:233; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.nekhet.cmd | Every ship rebuilds 25% of its hull and mends damaged sections, even destroyed ones. | OK at tier 1; see Command note | data.js:233; battle.js:1077-1111 |
| ADMIRALS.sekhmar | Corona arcs deal +20% damage and every weapon +10%. | OK | data.js:234; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.sekhmar.cmd | Every ship fires a free volley at the best target its guns can reach, right now. | OK at tier 1; see Command note | data.js:234; battle.js:1077-1111 |
| ADMIRALS.anuket | +20% damage on rear-arc hits and +10 evasion. | OK | data.js:235; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.anuket.cmd | Every ship deals +30% damage this round. | M10 | data.js:235; battle.js:1077-1111 |
| ADMIRALS.khepra | All ships +20% hull. | OK | data.js:236; core.js:172, core.js:217-226; battle.js:641-686, battle.js:1152-1154 |
| ADMIRALS.khepra.cmd | All shields refill and your ships take 40% less hull damage this round. | M11 | data.js:236; battle.js:1077-1111 |

### HULL_VARIANTS

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| HULL_VARIANTS.vs_harrow_t | Twin prow torpedo tubes and no turret: a one-shot assassin. | OK | data.js:552; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.vs_penitent_g | Swaps the prow lance for a dorsal sear battery: guns in every arc. | OK | data.js:553; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.h_picket_i | Turret laser and +6 evasion: screens wherever it points. | OK | data.js:554; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.h_vanguard_g | No hangar and no Launch squadron ability; a third plasma lance turret instead. | OK | data.js:555; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.c_reaver_t | Scatter cannons on a turret instead of one broadside. | OK | data.js:556; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.c_hulk_g | No hangar and no Launch squadron ability; scatter broadsides, a turret and 20 more hull. | OK | data.js:557; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.b_spitter_s | Trades a prow gun for boarding tendrils: brutal up close. | OK | data.js:558; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.b_razor_s | Trades its spine volley for a second tendril cluster: +1 speed and +8 evasion. | OK | data.js:559; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.i_wisp_l | A prism lance in place of the prism shards. | OK | data.js:560; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.i_song_w | One prism lance on a turret in place of the two prow lances, and 30% more shields. | OK | data.js:561; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.d_scythe_s | Adds a null spire: shoots down squadrons and boarders' craft. | OK | data.js:562; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.d_harvester_t | Its corona arc sits on a turret, so it no longer has to turn to fire, but it carries one null cannon instead of two. | OK | data.js:563; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.vs_penitent_l | Two prow lances and a dorsal battery turret instead of the broadsides: its heavy punch points one way. | OK | data.js:567; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.h_interdictor_e | Adds a flak turret, paid for with a lighter hull (60) and one hex of speed. | OK | data.js:568; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.c_marauder_g | A second prow torpedo instead of flak, and one hex slower. | OK | data.js:569; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.b_razor_e | Its tendril cluster becomes a second spine volley on a turret; regrows 9 a round (2 more than the base), one hex slower. | OK | data.js:570; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.i_carrier_a | A third wing, paid for with lighter shields (22) and one hex of speed. | OK | data.js:571; data.js:61-101, data.js:579; core.js:214-226 |
| HULL_VARIANTS.d_jackal_h | Both null cannons on turrets and a null spire, 10 less hull. | OK | data.js:572; data.js:61-101, data.js:579; core.js:214-226 |

### BOONS

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| BOONS.i_broad | Broadside guns deal +20% damage. | OK | data.js:632; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.i_still | A ship that hasn't moved this activation deals +25% damage with broadsides and batteries. | M24 | data.js:633; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.i_plate | +8% armor across the fleet. | OK | data.js:634; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.i_brace | Bracing blocks an extra 10%, and braced ships strike back: every enemy attack that hits one takes 18 damage in return. | M25 | data.js:635; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.i_line | Ships next to another of your ships take 12% less hull damage. | OK | data.js:636; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.s_cap | Shields +20% across the fleet. | OK | data.js:638; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.s_arc | When your fire knocks out an enemy shield facing, its generator shorts for 9 hull damage. | OK | data.js:639; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.s_ion | Your weapons strip 22% more shield per hit. | M26 | data.js:640; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.s_regen | Each turn, every shield facing on every ship restores an extra 18% of its strength. | M37 | data.js:641; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.s_ev | +6 evasion across the fleet. | OK | data.js:642; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.h_hatch | Carriers field an extra wing. | M27 | data.js:644; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.h_wings | Squadrons deal +25% damage. | OK | data.js:645; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.h_chitin | Squadrons have +30% hull. | OK | data.js:646; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.h_board | Boarding parties fight as 25% more crew, and a failed boarding always sabotages a system. | OK | data.js:647; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.h_feast | When your squadron destroys a target, its carrier gains a spare wing and repairs 5% hull. | OK | data.js:648; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.a_lance | Lances deal +35% damage. | OK | data.js:650; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.a_aim | +5 aim for every weapon. | OK | data.js:651; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.a_crit | +6% critical chance, criticals deal x1.75, and every critical hit wrecks a ship system. | M28 | data.js:652; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.a_long | Ignore the first 1 hex of long-range penalty. | OK | data.js:653; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.a_rear | Hits on an enemy's rear arc deal +25% damage. | OK | data.js:654; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.r_burn | +1 speed across the fleet. | OK | data.js:656; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.r_prow | Rams deal +35% damage and can take up to 50% of a ship's hull; recoil halved. | OK | data.js:657; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.r_mom | Ships deal +5% damage for each hex they moved this activation (up to 4). | OK | data.js:658; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.r_jink | Ships that moved 3+ hexes are 15 harder to hit until their next turn. | OK | data.js:659; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.r_shock | Rams also hit every other enemy next to the target for 25% of the ram damage. | OK | data.js:660; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.e_war | Torpedoes deal +25% damage. | OK | data.js:662; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.e_reload | Torpedoes reload 1 turn faster. | M56 (Rare/Epic) | data.js:663; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.e_kindle | Hull hits have a 12% chance to start a fire (fires burn 10 a turn for 2 turns). | OK | data.js:664; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.e_chain | Enemy ships you destroy explode, dealing 20 damage to every enemy within 2 hexes. | OK | data.js:665; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.e_hunt | +20% damage against ships below half hull, and ships you hit while below half can no longer regrow hull or reanimate. | M32 | data.js:666; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.d_jugg | Rams deal +50% damage and the rammer takes no recoil. | OK | data.js:668; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.d_bastion | Bracing also refills every shield facing and blocks an extra 10% of hull damage. | OK | data.js:669; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.d_ionlance | Lances strip double shield per hit. | M29 | data.js:670; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.d_burnswarm | Squadron hits have a 30% chance to start a fire. | M30 | data.js:671; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.d_hunter | Ships that moved 3+ hexes gain +25% critical chance. | OK | data.js:672; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.d_inferno | Broadside hits have a 40% chance to start a fire, and your fires burn hotter (10 a turn) and a turn longer. | M31 | data.js:673; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.i_wall | Bracing covers every ship next to the braced ship too: they take the brace's hull cut until its next turn. | OK | data.js:678; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.s_chain | When your fire knocks out an enemy shield facing, the two facings beside it lose a third of their strength. | OK | data.js:679; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.h_brood | Each enemy capital ship your fleet destroys lets your nearest carrier launch a free wing, if it has a free hex beside it. | OK | data.js:680; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.a_mark | Each round, the first enemy ship your lances hit is marked: your whole fleet aims 10 better against it until the round ends. | OK | data.js:681; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.r_slip | Your ships may move after firing, up to half the movement they had left (without climbing over or diving under). | OK | data.js:682; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.e_spread | Torpedoes that run wide still burst: every enemy within 1 hex of the aim hex takes 30% of one torpedo's damage. | M33 | data.js:683; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.L_iron | Legendary. Every ship survives its first killing blow each battle at 1 hull. | OK | data.js:684; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.L_storm | Legendary. Every shield facing on every ship refills completely at the start of each of your turns. | M36 | data.js:685; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.L_hunger | Legendary. Carriers field two more wings and never run out of spares. | M34 | data.js:686; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.L_star | Legendary. Lances always hit (95%) and pass straight through shields. | M35 | data.js:687; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.L_rook | Legendary. Rams deal 50% more, can take 70% of a ship's hull, and the rammer takes no recoil. | OK | data.js:688; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |
| BOONS.L_ember | Legendary. Every enemy ship you destroy explodes for 40 damage to every enemy within 2 hexes. | OK | data.js:689; core.js:172, core.js:217-226; battle.js:639-957, battle.js:1047-1056 |

### ASPECTS

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| ASPECTS.lancer | Your flagship's forward guns deal +50% damage and reach 1 hex further, and it can turn once more each round to bring them to bear. | OK | data.js:693; core.js:216-226; battle.js:664-685, battle.js:873-875, battle.js:1078, battle.js:1157, battle.js:1306-1307 |
| ASPECTS.hive | Your flagship launches a squadron wing at the start of every battle (+1 wing if it is already a carrier), and its wings deal +30% damage. | M40 | data.js:694; core.js:216-226; battle.js:664-685, battle.js:873-875, battle.js:1078, battle.js:1157, battle.js:1306-1307 |
| ASPECTS.ram | Your flagship rams for +60% damage, can take up to 60% of a ship's hull, takes no recoil, and has +1 speed. | OK | data.js:695; core.js:216-226; battle.js:664-685, battle.js:873-875, battle.js:1078, battle.js:1157, battle.js:1306-1307 |
| ASPECTS.bulwark | Your flagship has +70% hull and shields, ships next to it take 25% less hull damage, and enemy ships within 4 hexes that can fire on it must. | OK | data.js:696; core.js:216-226; battle.js:664-685, battle.js:873-875, battle.js:1078, battle.js:1157, battle.js:1306-1307 |
| ASPECTS.storm | Your flagship's weapons strip 50% more shield per hit, and its shields recharge twice as fast. | M41 | data.js:697; core.js:216-226; battle.js:664-685, battle.js:873-875, battle.js:1078, battle.js:1157, battle.js:1306-1307 |
| ASPECTS.admiral | Your Admiral's Command starts one power level higher (full power from round 2), and your flagship gets +10 aim. | OK | data.js:698; core.js:216-226; battle.js:664-685, battle.js:873-875, battle.js:1078, battle.js:1157, battle.js:1306-1307 |

### NEM_WEAK

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| NEM_WEAK.flank | Enemy ships take 25% more damage on rear-arc hits. | OK | data.js:430; battle.js:564-565, battle.js:603-607, battle.js:650-673, battle.js:848 |
| NEM_WEAK.ion | Ion and lance hits strip 50% more shield from enemy ships. | OK | data.js:431; battle.js:564-565, battle.js:603-607, battle.js:650-673, battle.js:848 |
| NEM_WEAK.torp | Torpedoes are 15 easier to land on enemy ships. | OK | data.js:432; battle.js:564-565, battle.js:603-607, battle.js:650-673, battle.js:848 |
| NEM_WEAK.board | Enemy ships carry 30% fewer crew to repel boarders. | OK | data.js:433; battle.js:564-565, battle.js:603-607, battle.js:650-673, battle.js:848 |
| NEM_WEAK.brawl | Enemy ships aim 10 worse at targets 2 hexes away or closer. | OK | data.js:434; battle.js:564-565, battle.js:603-607, battle.js:650-673, battle.js:848 |
| NEM_WEAK.anchor | Enemy escorts break and flee once the flagship falls below 60% hull. | OK | data.js:435; battle.js:564-565, battle.js:603-607, battle.js:650-673, battle.js:848 |
| NEM_WEAK.slow | Enemy ships have 1 less movement. | OK | data.js:436; battle.js:564-565, battle.js:603-607, battle.js:650-673, battle.js:848 |

### NEM_TRAITS

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| NEM_TRAITS.gunnery | Enemy ships aim 6 better. | OK | data.js:451; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.armored | Enemy ships have 8% more armor. | OK | data.js:513; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.swift | Enemy ships have 1 more movement. | OK | data.js:450; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.veterans | Enemy ships have 12% more hull. | OK | data.js:452; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.deadeye | Enemy ships have 10% more critical chance. | OK | data.js:450; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.shielded | Enemy ships have 20% more shields. | OK | data.js:450; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.boarders | Enemy ships carry 30% more crew. | OK | data.js:453; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.regrowth | Enemy ships regrow 4 more hull each turn. | OK | data.js:450; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.brood | Enemy carriers field one more wing. | M43 | data.js:450; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.undying | One more enemy ship reassembles after falling. | M45 | data.js:454; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.veil | Enemy ships are 8 harder to hit. | OK | data.js:450; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.artillery | Enemy guns reach 1 hex further. | M44 | data.js:450; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.zeal | Enemy ships deal 12% more damage to a ship next to them. | OK | data.js:455; battle.js:568-575, battle.js:675 |
| NEM_TRAITS.rockets | Enemy torpedoes reload a turn faster. | OK | data.js:450; battle.js:568-575, battle.js:675 |

### NEM_ADAPT

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| NEM_ADAPT.shields | Enemy ships have 20% more shields. | OK | data.js:438; battle.js:566, battle.js:575 |
| NEM_ADAPT.pd | Two enemy ships bolt on point defense. | M46 | data.js:439; battle.js:566, battle.js:575 |
| NEM_ADAPT.armor | Enemy ships have 10% more armor. | OK | data.js:440; battle.js:566, battle.js:575 |
| NEM_ADAPT.evasion | Enemy ships have 8 more evasion. | OK | data.js:441; battle.js:566, battle.js:575 |
| NEM_ADAPT.aim | Enemy ships aim 8 better. | OK | data.js:442; battle.js:566, battle.js:575 |

### NEM_ADAPT_FAC

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| NEM_ADAPT_FAC.corsair | One more ship joins the fleet. | OK | data.js:483; battle.js:559, battle.js:566, battle.js:573-574 |
| NEM_ADAPT_FAC.deathless | One more enemy ship reassembles. | M47 | data.js:484; battle.js:559, battle.js:566, battle.js:573-574 |
| NEM_ADAPT_FAC.ithar | Enemy ships are 6 harder to hit. | OK | data.js:485; battle.js:559, battle.js:566, battle.js:573-574 |
| NEM_ADAPT_FAC.chorus | Enemy ships regrow 3 more hull each turn. | OK | data.js:486; battle.js:559, battle.js:566, battle.js:573-574 |
| NEM_ADAPT_FAC.hegemony | His synchronized fire reaches one hex further. | M53 | data.js:487; battle.js:559, battle.js:566, battle.js:573-574 |
| NEM_ADAPT_FAC.voidsworn | His ships deal 8% more damage. | M54 | data.js:488; battle.js:559, battle.js:566, battle.js:573-574 |

### NEM_PERSONA

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| NEM_PERSONA.cunning | Strikes your flanks and your weakest ship. | OK; flank specificity ambiguous | data.js:457; battle.js:593-595, battle.js:1379-1386 |
| NEM_PERSONA.zealous | Charges in and never backs off. | OK in reachable faction pool | data.js:456; battle.js:593-595, battle.js:1379-1386 |
| NEM_PERSONA.cruel | Finishes crippled ships first. | OK | data.js:458; battle.js:593-595, battle.js:1379-1386 |
| NEM_PERSONA.patient | Waits for you to come to him. | M51 | data.js:456; battle.js:593-595, battle.js:1379-1386 |
| NEM_PERSONA.proud | Leads from the front with his flagship. | M52 | data.js:459; battle.js:593-595, battle.js:1379-1386 |
| NEM_PERSONA.greedy | Goes for your richest prize, your flagship. | OK | data.js:456; battle.js:593-595, battle.js:1379-1386 |
| NEM_PERSONA.methodical | Holds his line and advances only in formation. | M50 | data.js:460; battle.js:593-595, battle.js:1379-1386 |
| NEM_PERSONA.ravenous | Swarms whatever is closest. | OK | data.js:456; battle.js:593-595, battle.js:1379-1386 |

### NEM_FAC

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| NEM_FAC.corsair | Raids your path. When his clock fills he takes 25% of your credits (or, if you have under 30 credits, a ship under 25% hull from a fleet of three or more); he holds what he took, and it all comes back to you when he dies. He flees a fight he is losing and comes back richer, with an extra ship each time. | OK | data.js:462; battle.js:551-590; campaign_run.js:271-318 |
| NEM_FAC.deathless | Patient: his clock moves at half speed. He never retreats. Destroyed early, he simply reassembles; destroyed in the last sector, he rises once more for one final fight. When his clock fills, the hunt drains 6% hull from every ship you have (never below 1 hull). | OK | data.js:465; battle.js:551-590; campaign_run.js:271-318 |
| NEM_FAC.ithar | A duelist: he keeps his range, picks off your most damaged ships, and withdraws to fight again once his flagship has no shields left on any side and its hull is under 60%. His fleet is small and elite, and each time he escapes it comes back honed (better shields and aim), never bigger. | OK | data.js:468; battle.js:551-590; campaign_run.js:271-318 |
| NEM_FAC.chorus | Grows from your losses: every ship you lose anywhere makes his fleet 4% tougher (up to 32%). He swarms, and adapts after every meeting, not just every sector. | OK | data.js:471; battle.js:551-590; campaign_run.js:271-318 |
| NEM_FAC.hegemony | Methodical: his escorts hold an artillery line around his flagship (their guns lose less aim at range, and they keep close to it), and his fights always bring reinforcements in round 3. He adapts by drilling his formation tighter. | OK | data.js:474; battle.js:551-590; campaign_run.js:271-318 |
| NEM_FAC.voidsworn | A zealot: his clock moves fast, he never flees, and his flagship charges yours and challenges it to single combat (the two deal 20% more damage to each other; if your flagship falls, he turns on your strongest ship). | OK | data.js:477; battle.js:551-590; campaign_run.js:271-318 |

### WING_STANCES

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| WING_STANCES.strike | Default. Wings hit the best target in reach, ships first for bombers. | OK | data.js:508; battle.js:617-628, battle.js:651, battle.js:676, battle.js:1122-1149 |
| WING_STANCES.screen | Wings stay within 2 hexes of their carrier, hunt enemy craft first, and shoot down torpedoes aimed at ships beside them. | M55 | data.js:509; battle.js:617-628, battle.js:651, battle.js:676, battle.js:1122-1149 |
| WING_STANCES.hunt | Wings range 4 hexes further and go for crippled ships (+20% damage below half hull), but fly exposed (10 easier to hit). | OK | data.js:510; battle.js:617-628, battle.js:651, battle.js:676, battle.js:1122-1149 |

### WING_PERKS

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| WING_PERKS.aces | Wings aim 10 better. | OK | data.js:512; battle.js:627, battle.js:676, battle.js:1154, battle.js:1158 |
| WING_PERKS.armored | Wings have 25% more hull. | OK | data.js:513; battle.js:627, battle.js:676, battle.js:1154, battle.js:1158 |
| WING_PERKS.reserve | The carrier holds one more spare wing. | OK | data.js:514; battle.js:627, battle.js:676, battle.js:1154, battle.js:1158 |
| WING_PERKS.killers | Wings deal 15% more damage to ships. | OK | data.js:515; battle.js:627, battle.js:676, battle.js:1154, battle.js:1158 |
| WING_PERKS.pickets | Screening wings shoot down torpedoes more often. | OK | data.js:516; battle.js:627, battle.js:676, battle.js:1154, battle.js:1158 |
| WING_PERKS.jinkers | Wings are 8 harder to hit. | OK | data.js:517; battle.js:627, battle.js:676, battle.js:1154, battle.js:1158 |

### MASTERY_PERKS

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| MASTERY_PERKS.1 | Choose a second starting fleet for this admiral. | OK | data.js:584; core.js:344-359; campaign_meta.js:92-102 |
| MASTERY_PERKS.2 | Your flagship is offered four aspects instead of three. | OK | data.js:584; core.js:344-359; campaign_meta.js:92-102 |
| MASTERY_PERKS.3 | Choose between two Commands before the run. | OK | data.js:584; core.js:344-359; campaign_meta.js:92-102 |
| MASTERY_PERKS.4 | Your flagship starts at Mk II, its captain a Captain with a perk. | M42 | data.js:584; core.js:344-359; campaign_meta.js:92-102 |

### FAC_VERBS

| Id | Current description / weapon record | Result | Rule evidence |
|---|---|---|---|
| FAC_VERBS.voidsworn | Next battle, ships next to an ally take 15% less hull damage. | OK | data.js:500; battle.js:609-614; campaign_run.js:319-350 |
| FAC_VERBS.hegemony | Next battle, synchronized fire reaches 4 hexes from the flagship and its bonus rises to +20%. | OK | data.js:501; battle.js:609-614; campaign_run.js:319-350 |
| FAC_VERBS.corsair | Gain 30 credits, plus 10 for every greedy choice this run. The Nemesis clock moves on. | OK | data.js:502; battle.js:609-614; campaign_run.js:319-350 |
| FAC_VERBS.chorus | Consume a refit from the hold: every ship regrows 20% of its hull (30% if the fleet has fed at a spawning field). | OK | data.js:503; battle.js:609-614; campaign_run.js:319-350 |
| FAC_VERBS.ithar | Next battle, every shield is 25% stronger. | OK | data.js:504; battle.js:609-614; campaign_run.js:319-350 |
| FAC_VERBS.deathless | Next battle, Archive restore brings back one more ship. | OK | data.js:505; battle.js:609-614; campaign_run.js:319-350 |

### Command interpretation

All 24 Commands were checked. The stored d values describe tier 1; omission of later tiers is not separately counted as 24 errors because the live selector and battle panel use cmdDesc and disclose charging (campaign_meta.js:69, campaign_meta.js:94; ui3d.js:146). Powers: barrage +0/+25/+50% free-volley damage; hunt +30/+45/+60%; scramble +50/+75/+100% and one/one/two extra wings; iron 40/50/60% hull cut, plus 10 points for shieldless hulls; restore 25/35/45% hull and sections; surge +2/+3/+4 movement and +1/+1/+2 turns. Barrage and Restore operate on capital ships; wings have their own scramble. Barrage chooses a best target per weapon, can use reloading guns, restores original fired/cooldown state, and does not make a braced ship fire (battle.js:635, battle.js:1103-1105). These are useful clarifications but not separate contradictions in short baseline cards.

### Cleared edge cases

- WTRAITS.star is correct relative to its base startorp: evMult is reduced from 2 to 1.2 (data.js:20, data.js:52); hitChance subtracts multiplied evasion (battle.js:641). It also tracks a displaced target with smaller penalties (battle.js:842). It remains more evasion-sensitive than multiplier-1 guns, so clearer optional text is "harder to dodge than other torpedoes". No balance change is justified by the prior review.
- ADMIRALS.kassar says "hits 5% lighter", which is damage language, not hit probability. dmgPct:-.05 reduces weapon damage; aim is unchanged (core.js:223; battle.js:641, battle.js:667). The text is substantially correct. "Battery shots +1; weapon damage -5%" is optional clarity.
- NEM_FAC.deathless.beh: no flee object means nemFleeCheck cannot retreat it, and revive sets nemNoRout (battle.js:576, battle.js:588, battle.js:1031). The old review read absence of noFlee without tracing revive. A campaign escape after the flagship is destroyed is not a live ship retreat (campaign_run.js:308-310). Keep "never retreats" in the combat sense.
- Variant weapon deletions are now disclosed: b_razor_s, i_song_w, d_harvester_t (data.js:559, data.js:561, data.js:563). i_song_w rounds shields 26 to 34, which is the usual rounded +30%, not a new mismatch. All 18 variant weapon lists and mods were compared against their bases and the materialization loop at data.js:579.
- Relic repair/credit/XP effects are wired: salvage campaign_run.js:416; ledger campaign_run.js:414; logbook core.js:241; phylactery battle.js:941. Revive is after Last Stand, so "first destroyed" is not necessarily the first lethal hit.

## Godot text parity

- godot/rules/data/tables.json:1: 2968 browser literal string leaves compared, 0 differences. JSON path is the reliable locator because each JSON file is one line.
- Rules tables omit JavaScript function-valued d fields and have no BOON_D table. This is intentional serialization, not a stale wording: the campaign table supplies the rendered protocol text.
- godot/campaign/data/campaign_tables.json:1: 2968 browser literal string leaves compared, 0 differences. JSON path is the reliable locator because each JSON file is one line.
- BOON_D: all 48 x 4 = 192 rarity outputs compared; 0 differences.

Godot rule cross-checks confirm the relevant mechanisms: rules.gd:172 star multiplier; rules.gd:316-358 protocol fx; rules.gd:2249 rangefinder; rules.gd:2385 pre-hit Pyre; rules.gd:2524 critical-system branch; rules.gd:2570 riposte; rules.gd:2777-2778 Feast; rules.gd:3121 cmdTaken. campaign.gd:80 loads BOON_D and campaign.gd:1937 uses the corrected flag comparator. No text drift was found. This is not a full browser/Godot behavioural parity certification.

## Prior review reconciliation

The labels below apply to each specific reviewed complaint, not to the old proposed replacement as a blanket approval. STILL WRONG includes outstanding voice/disclosure requests; those are not all gameplay bugs. ALREADY FIXED means fixed in this working folder before this audit. NOT A PROBLEM means the old claim does not follow from current code or is an optional design preference.

### Text overhaul: all 96 replacement rows

| Row | Status | Evidence and disposition |
|---|---|---|
| T-01 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:21; data.js:254 removes Acceptable Loss and contains Debt Paid. |
| T-02 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:22; data.js:128 says siphoning stellar energy. It need not exactly match the old replacement to resolve stealing starlight. |
| T-03 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:23; data.js:221 now says Grax Ironmaw. |
| T-04 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:24; data.js:465 deathless titles contain High Nadir, Eclipse-prime and Archivist, not plain Nadir. |
| T-05 | NOT A PROBLEM | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:25; Archive restore is an actual named rule at battle.js:485 and battle.js:531. The earlier claim that the mechanic name exists nowhere is false. FAC_VERBS.deathless at data.js:505 correctly adds an allowance via battle.js:613. Clearer optional wording may still help. |
| T-06 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:26; data.js:272 still has RELIC_NAMES.deathless.salvage=Salvage swarm. A name collision/voice request, not a changed effect. |
| T-07 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:27; data.js:193 now names the base relic Backup frame. |
| T-08 | NOT A PROBLEM | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:35; Hits lighter describes damage, not accuracy. data.js:217; core.js:223; battle.js:641, battle.js:667. The replacement all damage would overstate the scope: rams use ramPct, not dmgPct (battle.js:873-875). |
| T-09 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:36; data.js:229 and battle.js:641: aim is global, while the passive still says lances gain it; M08. |
| T-10 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:37; data.js:207, data.js:219, data.js:223, data.js:225, data.js:228: all five passive strings still omit sqHp:.25; battle.js:1152-1154; M03-M07. |
| T-11 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:38; data.js:207, data.js:219, data.js:223, data.js:225, data.js:228: all five passive strings still omit sqHp:.25; battle.js:1152-1154; M03-M07. |
| T-12 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:39; data.js:207, data.js:219, data.js:223, data.js:225, data.js:228: all five passive strings still omit sqHp:.25; battle.js:1152-1154; M03-M07. |
| T-13 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:40; data.js:207, data.js:219, data.js:223, data.js:225, data.js:228: all five passive strings still omit sqHp:.25; battle.js:1152-1154; M03-M07. |
| T-14 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:41; data.js:207, data.js:219, data.js:223, data.js:225, data.js:228: all five passive strings still omit sqHp:.25; battle.js:1152-1154; M03-M07. |
| T-15 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:42; data.js:559, data.js:561, data.js:563 explicitly disclose the removed weapon; compared with bases at data.js:85, data.js:92, data.js:100. |
| T-16 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:43; data.js:559, data.js:561, data.js:563 explicitly disclose the removed weapon; compared with bases at data.js:85, data.js:92, data.js:100. |
| T-17 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:44; data.js:559, data.js:561, data.js:563 explicitly disclose the removed weapon; compared with bases at data.js:85, data.js:92, data.js:100. |
| T-18 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:45; data.js:589 still says Captain. core.js:359 sets rank index 2; actual faction ranks data.js:520-525; M42. The old review itself used obsolete non-Crusade rank names. |
| T-19 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:53; data.js:136, data.js:165, data.js:215, data.js:219, data.js:223, data.js:228, data.js:694 retain carrier wording. Hegemony launch hulls are Cruiser/Battleship (data.js:76-77); core.js:224, core.js:251; M02, M12-M16, M40. |
| T-20 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:54; data.js:136, data.js:165, data.js:215, data.js:219, data.js:223, data.js:228, data.js:694 retain carrier wording. Hegemony launch hulls are Cruiser/Battleship (data.js:76-77); core.js:224, core.js:251; M02, M12-M16, M40. |
| T-21 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:55; data.js:136, data.js:165, data.js:215, data.js:219, data.js:223, data.js:228, data.js:694 retain carrier wording. Hegemony launch hulls are Cruiser/Battleship (data.js:76-77); core.js:224, core.js:251; M02, M12-M16, M40. |
| T-22 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:56; data.js:136, data.js:165, data.js:215, data.js:219, data.js:223, data.js:228, data.js:694 retain carrier wording. Hegemony launch hulls are Cruiser/Battleship (data.js:76-77); core.js:224, core.js:251; M02, M12-M16, M40. |
| T-23 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:57; data.js:136, data.js:165, data.js:215, data.js:219, data.js:223, data.js:228, data.js:694 retain carrier wording. Hegemony launch hulls are Cruiser/Battleship (data.js:76-77); core.js:224, core.js:251; M02, M12-M16, M40. |
| T-24 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:58; data.js:136, data.js:165, data.js:215, data.js:219, data.js:223, data.js:228, data.js:694 retain carrier wording. Hegemony launch hulls are Cruiser/Battleship (data.js:76-77); core.js:224, core.js:251; M02, M12-M16, M40. |
| T-25 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:59; data.js:136, data.js:165, data.js:215, data.js:219, data.js:223, data.js:228, data.js:694 retain carrier wording. Hegemony launch hulls are Cruiser/Battleship (data.js:76-77); core.js:224, core.js:251; M02, M12-M16, M40. |
| T-26 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:60; data.js:136, data.js:165, data.js:215, data.js:219, data.js:223, data.js:228, data.js:694 retain carrier wording. Hegemony launch hulls are Cruiser/Battleship (data.js:76-77); core.js:224, core.js:251; M02, M12-M16, M40. |
| T-27 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:61; campaign_meta.js:170 still uses carriers and carrier in the launch explanation. Hegemony counters at data.js:76-77. |
| T-28 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:62; campaign_meta.js:170 still uses carriers and carrier in the launch explanation. Hegemony counters at data.js:76-77. |
| T-29 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:63; ui3d.js:545 quickLaunch still says no open hex next to the carrier; launch ships need not be Carrier class. |
| T-30 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:73; data.js:429-435 NEM_WEAK descriptions now use Enemy ships/escorts instead of His. |
| T-31 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:74; data.js:429-435 NEM_WEAK descriptions now use Enemy ships/escorts instead of His. |
| T-32 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:75; data.js:429-435 NEM_WEAK descriptions now use Enemy ships/escorts instead of His. |
| T-33 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:76; data.js:429-435 NEM_WEAK descriptions now use Enemy ships/escorts instead of His. |
| T-34 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:77; data.js:429-435 NEM_WEAK descriptions now use Enemy ships/escorts instead of His. |
| T-35 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:78; data.js:429-435 NEM_WEAK descriptions now use Enemy ships/escorts instead of His. |
| T-36 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:79; data.js:429-435 NEM_WEAK descriptions now use Enemy ships/escorts instead of His. |
| T-37 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:85; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-38 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:86; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-39 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:87; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-40 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:88; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-41 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:89; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-42 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:90; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-43 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:91; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-44 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:92; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-45 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:93; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-46 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:94; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-47 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:95; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-48 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:96; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-49 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:97; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-50 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:98; data.js:450-454 NEM_TRAITS descriptions now use Enemy. Remaining effect issues are separately M43-M45. |
| T-51 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:104; data.js:437-441 NEM_ADAPT descriptions now use Enemy. Exact two-ship claim is separately M46. |
| T-52 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:105; data.js:437-441 NEM_ADAPT descriptions now use Enemy. Exact two-ship claim is separately M46. |
| T-53 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:106; data.js:437-441 NEM_ADAPT descriptions now use Enemy. Exact two-ship claim is separately M46. |
| T-54 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:107; data.js:437-441 NEM_ADAPT descriptions now use Enemy. Exact two-ship claim is separately M46. |
| T-55 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:108; data.js:437-441 NEM_ADAPT descriptions now use Enemy. Exact two-ship claim is separately M46. |
| T-56 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:114; data.js:483-486: Bigger fleet, fleet, enemy ship, 6 harder to hit and Enemy ships are present. The old crew/grammar/pronoun defects are resolved. |
| T-57 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:115; data.js:483-486: Bigger fleet, fleet, enemy ship, 6 harder to hit and Enemy ships are present. The old crew/grammar/pronoun defects are resolved. |
| T-58 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:116; data.js:483-486: Bigger fleet, fleet, enemy ship, 6 harder to hit and Enemy ships are present. The old crew/grammar/pronoun defects are resolved. |
| T-59 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:117; data.js:483-486: Bigger fleet, fleet, enemy ship, 6 harder to hit and Enemy ships are present. The old crew/grammar/pronoun defects are resolved. |
| T-60 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:118; data.js:483-486: Bigger fleet, fleet, enemy ship, 6 harder to hit and Enemy ships are present. The old crew/grammar/pronoun defects are resolved. |
| T-61 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:119; data.js:487-488 still have His in special descriptions. battle.js:574 or battle.js:566 verifies the effect; M53-M54 flag the voice only. |
| T-62 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:120; data.js:487-488 still have His in special descriptions. battle.js:574 or battle.js:566 verifies the effect; M53-M54 flag the voice only. |
| T-63 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:128; data.js:458-459 and campaign_run.js:76: persona descriptions are rendered raw, so him/his still reaches female/neuter rivals. M50-M52. |
| T-64 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:129; data.js:458-459 and campaign_run.js:76: persona descriptions are rendered raw, so him/his still reaches female/neuter rivals. M50-M52. |
| T-65 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:130; data.js:458-459 and campaign_run.js:76: persona descriptions are rendered raw, so him/his still reaches female/neuter rivals. M50-M52. |
| T-66 | NOT A PROBLEM | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:136; Eclipse has no flee trigger and revive disables normal rout: data.js:466; battle.js:576, battle.js:588, battle.js:1031. Commander escape after destruction (campaign_run.js:308-310) does not make a living ship retreat. |
| T-67 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:144; campaign_run.js:80, campaign_run.js:280, campaign_run.js:301, campaign_run.js:284-285 retain raw male literals. nemSay exists at campaign_run.js:268 but these literals are not passed through it. |
| T-68 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:145; campaign_run.js:80, campaign_run.js:280, campaign_run.js:301, campaign_run.js:284-285 retain raw male literals. nemSay exists at campaign_run.js:268 but these literals are not passed through it. |
| T-69 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:146; campaign_run.js:80, campaign_run.js:280, campaign_run.js:301, campaign_run.js:284-285 retain raw male literals. nemSay exists at campaign_run.js:268 but these literals are not passed through it. |
| T-70 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:147; campaign_run.js:80, campaign_run.js:280, campaign_run.js:301, campaign_run.js:284-285 retain raw male literals. nemSay exists at campaign_run.js:268 but these literals are not passed through it. |
| T-71 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:148; campaign_run.js:80, campaign_run.js:280, campaign_run.js:301, campaign_run.js:284-285 retain raw male literals. nemSay exists at campaign_run.js:268 but these literals are not passed through it. |
| T-72 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:149; campaign_run.js:80, campaign_run.js:280, campaign_run.js:301, campaign_run.js:284-285 retain raw male literals. nemSay exists at campaign_run.js:268 but these literals are not passed through it. |
| T-73 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:157; The requested numeric disclosure is still absent: data.js:44; see M18. Existing direction is accurate. |
| T-74 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:158; The requested numeric disclosure is still absent: data.js:47; see M19. Existing direction is accurate. |
| T-75 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:159; The requested numeric disclosure is still absent: data.js:51; see M20. Existing direction is accurate. |
| T-76 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:160; data.js:46 omits the +1 damage side effect; M17. |
| T-77 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:161; data.js:45 still hides duration and damage and omits the hull-hit condition; battle.js:717, battle.js:388; M21. |
| T-78 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:169; data.js:282 and data.js:325: 100-credit choice promises only an escort that might remember, but sets ambush and +1 clock. applyOutcome sets ambush at campaign_run.js:378; campaign_run.js:96 upgrades the next eligible ordinary battle to an elite Hegemony encounter. |
| T-79 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:170; data.js:322 still says founders tech and salvage. The outcome is mod:1, cred:40, not relic. campaign_run.js:368-369 separates those reward types. |
| T-80 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:171; data.js:284 retains smell old metal. This is an outstanding voice request; the supplied source folder does not contain the cited lore bible to independently validate its ban. |
| T-81 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:177; data.js:232 retains regrow for Nekhet. Behaviour is correctly 4% hull regeneration (core.js:225); rebuild is a voice choice. |
| T-82 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:178; data.js:529 retains Last Scent. Same unverified lore-ban dependency as T-80. |
| T-83 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:179; ui3d.js tutorial close tip still says sends crews. Gameplay uses a numeric crew abstraction for every capital hull (battle.js:123); this is a species/register request, not a functional contradiction. |
| T-84 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:180; campaign3d.js:93 still says before anyone signs for her; the variable names changed but the ship-gender phrase did not. |
| T-85 | NOT A PROBLEM | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:181; Optional capitalization preference, not a rules mismatch; data.js:273. |
| T-86 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:189; campaign_meta.js:155 still promises every admiral and ship from the start. admiralOwned checks cost at campaign_meta.js:60; shipyard hulls are gated at campaign_run.js:158. |
| T-87 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:190; campaign_meta.js:156 retains guaranteed post-flagship shipyard. campaign_run.js afterBattle/reward flow at 411-438 has no such mandatory step. |
| T-88 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:191; campaign_meta.js:172 lists only Common/Rare/Epic, but data.js:621 has Legendary and core.js:189-198 offers it. |
| T-89 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:192; campaign_meta.js:172 says three; campaign_meta.js:101 offers four at mastery 2. |
| T-90 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:193; campaign_meta.js:176 still teaches A for arcs. ui3d.js onKey uses V; ram X and board G are available. |
| T-91 | ALREADY FIXED | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:194; campaign_meta.js:70 now has a real Unlock for N renown purchase button. campaign_meta.js:149 spends renown. The old Legacy pointer is gone. |
| T-92 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:195; ui3d.js:62, campaign3d.js:116 and campaign3d.js copy-report callback still name Claude. Voice/UI cleanup, not a rules defect. |
| T-93 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:196; ui3d.js:62, campaign3d.js:116 and campaign3d.js copy-report callback still name Claude. Voice/UI cleanup, not a rules defect. |
| T-94 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:197; ui3d.js:62, campaign3d.js:116 and campaign3d.js copy-report callback still name Claude. Voice/UI cleanup, not a rules defect. |
| T-95 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:203; battle.js:591 still says his fleet / He will be back. The variable is f, rather than fl in the old quote; the defect remains. |
| T-96 | STILL WRONG | contrib/muse/reviews/text_overhaul_pack_2026_10_30.md:204; battle.js:605 still says His escorts lose their nerve and flee. |

Replacement-row totals: 40 ALREADY FIXED, 4 NOT A PROBLEM, 52 STILL WRONG.

### Text overhaul: all code flags, decisions and notes

| Item | Status | Evidence and disposition |
|---|---|---|
| CODE-1 | ALREADY FIXED | Real purchase button campaign_meta.js:70; handler campaign_meta.js:149. Godot UI also has it at godot/ui/campaign/campaign_ui.gd:363. |
| CODE-2 | STILL WRONG | needText campaign_run.js:227 and reward promotion campaign_run.js:425 still use RANKS rather than faction ranks. core.js:162 already provides rankName. |
| CODE-3 | STILL WRONG | Raw persona/special and strike/flee strings remain (T-61-T-72, T-95-T-96); NEM_WEAK/NEM_TRAITS/NEM_ADAPT were neutralized. The main behaviour card is already routed through nemSay at campaign_run.js:78. |
| CODE-4 | ALREADY FIXED | campaign_run.js:374 saves upgradedUid; campaign_run.js:383 excludes it from repair candidates where there is a second ship. |
| CODE-5 | STILL WRONG | campaign_run.js:170 and campaign_meta.js:126 still render W[id].n instead of wName. The old Gauss cannon example is stale: W.gauss.n now is Null cannon (data.js:21), but laser/Plasma cannon and bioplasma/Spine volley still differ (data.js:10, data.js:17, data.js:36-38). |
| CODE-6 | STILL WRONG | campaign_meta.js:212-213 still force the article; campaign3d.js:28 still builds rival faction text with it. This is lore grammar, not an effect mismatch. |
| CODE-7 | ALREADY FIXED | campaign_run.js:223 now calls flagIs(nd.flag,nd.flagK); verbFree uses flagIs with freeK. Current FAC_VERBS.hegemony freeK is question/enlist at data.js:501, not selling the defector back. Godot campaign.gd:1937 agrees. |
| CODE-8 | ALREADY FIXED | data.js:293 no longer excludes ithar; its faction option remains at data.js:327. |
| CODE-9 | ALREADY FIXED | data.js:418 adds Give the den a wide berth with empty outcome. |
| CODE-10 | NOT A PROBLEM | Internal legacy class ids are translated through clsName (data.js:60). The review itself cleared the player-facing allegation. |
| CODE-11 | NOT A PROBLEM | The cost-less boss/squadron paths are excluded from normal fleet decommission. The claim was already recorded as latent; no newly reachable path found. campaign_run.js:176 and battle.js:914 show the relevant path/flagship capture exclusion. |
| CODE-12 | NOT A PROBLEM | Whether diagnostics belong in Settings is a UI choice, not a false rules description. The concrete Claude copy defects remain T-92-T-94; ui3d.js:62. |
| DEC-1 | NOT A PROBLEM | The shipped Chorus admiral is Mending Throng (data.js:226). The complaint concerns unimplemented drafts, not an effect described by this data. The referenced lore bible is absent, so its broader ban cannot be independently adjudicated here. |
| DEC-2 | ALREADY FIXED | Acceptable Loss is absent and Debt Paid is present in SHIP_NAMES (data.js:254). Any requested edit to an absent bible is outside this task. |
| DEC-3 | NOT A PROBLEM | The comparison must be to startorp base evMult:2, not an assumed baseline of 1; trait 1.2 improves evasion resistance (data.js:20, data.js:52; battle.js:641, battle.js:842). |
| DEC-4 Reclamation swarm | STILL WRONG | RELIC_NAMES.deathless.salvage remains Salvage swarm (data.js:272); proposed new name has not shipped. |
| DEC-4 Backup frame | ALREADY FIXED | RELICS.phylactery.n is Backup frame (data.js:193). |
| DEC-4 Last Trail | STILL WRONG | MORE_SHIP_NAMES.corsair still contains Last Scent (data.js:529); lore dependency noted at T-80. |
| DEC-4 homecoming | NOT A PROBLEM | Optional capitalization is not a code/text contradiction; data.js:273. |
| Note: Godot story stream | NOT A PROBLEM | A draft-workstream complaint is not a rules description mismatch in the named source files. No conclusion about those drafts is asserted. |
| Note: firstrun Crusade register | NOT A PROBLEM | This concerns proposed wording, not the current data.js descriptions. Lore adjudication would require the absent bible. |
| Cleared 1 Lantern Gut | NOT A PROBLEM | Present at data.js:523; a proper name supplies no false gameplay claim. The review itself says the faction-specific ban does not apply. |
| Cleared 2 Mending Choir | ALREADY FIXED | Current data.js:226 has The Mending Throng; the stale name is absent from its player-facing admiral row. |
| Cleared 3 terrain numbers | NOT A PROBLEM | battle.js:643-645 and data.js:603-607 agree on -15 nebula and -10 debris aim penalties. |
| Cleared 4 adaptation why | NOT A PROBLEM | NEM_ADAPT.why is already neutral at data.js:438-442. The male fallback remains T-69. |

### Admirals synthesis: every text finding and carried text item

| Item | Status | Evidence and disposition |
|---|---|---|
| 1 duplicate passives | NOT A PROBLEM | The duplicates are real in data.js:205-235, but identical descriptions of identical rules are accurate. Distinguishing 24 characters is a roster design request, not a false tooltip. Cost differences are unlock prices, not a stated power guarantee. |
| 2 hunt split | STILL WRONG | Vorn and Anuket stored cmd.d omit the shared reload at battle.js:1106. M09-M10. Already fixed on live cards because campaign_meta.js:69 and ui3d.js:146 call cmdDesc, not cmd.d. |
| 3 Vorn Interdiction | STILL WRONG | data.js:218 still has Interdiction doctrine and Interdiction strike name, with aim/crit and hunt. No extra interdiction/status mechanic is applied. This remains the review's packaging concern, not proof that the numerical passive lies. |
| 4 Grax Ram and board | STILL WRONG | data.js:221 still uses Ram and board. His own effects are speed and weapon damage, and surge is movement/evasion. No boardPct or ramPct is added; battle.js:873-875, battle.js:911. Mobility helps close distance but supplies no special boarding or ram modifier. |
| 5 Khepra iron | STILL WRONG | Stored description remains wrong and hides shieldless 50% protection, M11. Live generated card already says 50% and omits refill (battle.js:1086, battle.js:1097; campaign_meta.js:69). No change to the mechanic is needed to make its live effect useful. |
| 6 hidden sqHp | STILL WRONG | All five data.js passive descriptions omit +25% wing hull, M03-M07; battle.js:1152-1154 applies it. |
| 6 Vaelen aim | STILL WRONG | Global aim is described as lance aim; M08, core.js:223 and battle.js:641. |
| 6 Kassar accuracy claim | NOT A PROBLEM | Hits lighter describes lower damage. It does not say accuracy drops; data.js:217, core.js:223; cleared above. |
| 7 Chorus first-person voice | STILL WRONG | data.js:491-494 NEM_LINES still contains I/me singular; battle.js:579-580 inserts those lines raw. Grammar/register request; no rules effect. |
| 7 patient immortality line | STILL WRONG | data.js:491 retains I have waited longer than your kind has lived and Chorus still permits patient at data.js:471. Whether this implies forbidden immortality is lore interpretation, not a computable effect. |
| 7 behaviour his for neuter | ALREADY FIXED | campaign_run.js:78 applies nemSay to behaviour, and campaign_run.js:268 substitutes neuter pronouns. Raw persona and battle-dialogue issues are separate. |
| Downgrade: Interdictor display | ALREADY FIXED | Hull display is Cordon destroyer (data.js:75) and Cordon column escort (data.js:566). Internal h_interdictor does not need renaming. |
| Downgrade: CAP_LAST overlap | NOT A PROBLEM | Shared name fragments are not a false rule description; data.js:256, data.js:480. This review already downgraded the allegation. |
| Downgrade: cost-band power verdicts | NOT A PROBLEM | No current description promises that renown price is a combat power rating. Historical measurement claims are not re-run or certified by this text audit. |
| Downgrade: Eclipse-prime | NOT A PROBLEM | Still in data.js:465 as permitted by the quoted owner ruling in the review; it describes no false mechanic. Plain Nadir is already removed. |
| Note: Duelist / High Nadir titles | NOT A PROBLEM | Proper title choices in data.js:465, data.js:468 make no numerical gameplay claim. |
| Note: Corin name overlap | NOT A PROBLEM | Corin Reyes remains data.js:219. A name overlapping a lore example is not an effect mismatch; the missing lore text prevents a separate lore ruling. |
| Note: Mending Throng formula | NOT A PROBLEM | Current name data.js:226 and its 4% regeneration passive agree with core.js:225. The claimed bible-internal tension cannot be checked without that bible. |
| Note: scarBy.fled on nonflee factions | NOT A PROBLEM | Unused pool entries do not promise that a faction will flee. data.js:466, data.js:472, data.js:480; flee is gated by battle.js:588. |
| Note: absent admiral epithets | NOT A PROBLEM | A request for more identity text, not a false mechanical description. ADMIRALS data.js:204-235. |
| Negative name assembly result | NOT A PROBLEM | No contrary full-name collision is claimed here. The review's name-assembly test is historical evidence, not re-certified by this rules audit. |

Additional flag/decision/note/admiral dispositions: 46 items: 10 ALREADY FIXED, 14 STILL WRONG, 22 NOT A PROBLEM. These are subitems, not additional unique gameplay mismatches.



## Admiral identity fields and residual ambiguity

Names, doctrine labels and Command names were also checked. They are not separate numerical effects. All current fields are listed here so the passive/Command coverage above does not silently omit doctrine text.

| Id | Admiral | Doctrine | Command name | Disposition |
|---|---|---|---|---|
| vex | Admiral Roderic Vex | Line of battle | Fire for effect | No additional false rule claim found. |
| malek | Oath-Captain Malek Draven | Hunter-killer | Hunter's salvo | No additional false rule claim found. |
| ashgrove | Commodore Sera Ashgrove | Carrier doctrine | Scramble all wings | No additional false rule claim found. |
| thale | High Admiral Oryn Thale | Iron doctrine | Iron wall | No additional false rule claim found. |
| kassar | First Admiral Ilsa Kassar | Fire discipline | Synchronized broadside | No additional false rule claim found. |
| vorn | Commodore Dace Vorn | Interdiction | Interdiction strike | Prior review packaging concern remains; effect text traced above. |
| reyes | Fleet Marshal Corin Reyes | Strike group | Launch the strike group | No additional false rule claim found. |
| maren | Line Admiral Oskar Maren | Armored column | Shield wall order | No additional false rule claim found. |
| grax | Warlord Grax Ironmaw | Ram and board | Full burn | Prior review packaging concern remains; effect text traced above. |
| sable | Sable the Smiling Knife | Knife work | Knife in the dark | No additional false rule claim found. |
| mott | Old Mott | Junkyard carriers | Release the swarm | No additional false rule claim found. |
| vesh | Vesh the Collector | Scrap armor | Patch and weld | No additional false rule claim found. |
| matriarch | The Matriarch of Nine Throats | Brood swarm | Spawning surge | No additional false rule claim found. |
| razormaw | Razormaw | Hunter pack | Blood frenzy | No additional false rule claim found. |
| mending | The Mending Throng | Regrowth | Regrowth tide | No additional false rule claim found. |
| voice | Voice of the Deep | Acid tide | Spitting volley | No additional false rule claim found. |
| aelith | Tamsa of the Clear Aperture | Wing-mistress | Starling flight | No additional false rule claim found. |
| vaelen | Saro of Long Focus | Focused lances | Burning glass | No additional false rule claim found. |
| thorne | Vell of the Third Mirror | Refraction tactics | Scatter the light | No additional false rule claim found. |
| mirelle | Brin of the Fourth Lens | Prism hulls | Prism ward | No additional false rule claim found. |
| nekhet | Nadir Aurex, Ninth Frame | Endless restoration | Release the repair swarms | No additional false rule claim found. |
| sekhmar | Umbra Vessane, Third-Housed | Corona strikes | Noon volley | No additional false rule claim found. |
| anuket | Ostrel of the Long Copy | Silent hunters | Out of the shadow | No additional false rule claim found. |
| khepra | Seveth, Twice-Restored | Layered plates | Sunshade wall | No additional false rule claim found. |

Cunning persona ambiguity: ai.rear is not consumed, but ordinary damage scoring already rewards rear hits (battle.js:691-700, battle.js:1290-1292). The short flavour claim about striking flanks is not enough to prove a false guarantee. Zealous is only selected by the no-flee Crusade pool (data.js:479-480), so its never-backs-off claim is correct in reachable generation even though the persona alone does not set noFlee. No mismatch is counted for either.

The report cannot independently settle the absent lore bible's smell/song/name restrictions. Those prior requests are preserved as outstanding voice items with that limitation, not asserted as newly proven gameplay defects. The phrase "never retreats" is interpreted as live battle withdrawal, not the commander surviving destruction in campaign fiction. Stored Command descriptions remain inaccurate where flagged, but hunt and shieldless iron already render correctly through cmdDesc.

## Fifteen most misleading findings

1. M56 Hot Tubes: Rare/Epic promise two turns faster; all current torpedoes improve only one.
2. M29 Ion Lance: adds 1 to the multiplier; an ion cannon does not double its shield damage.
3. M26 Ion Lash: adds 0.22 to the multiplier, not 22% more shield stripping for an ion cannon.
4. M41 Aspect of the Storm: adds 0.5 to the multiplier, not a universal relative +50%.
5. M25 Iron Discipline: torpedo impacts do not trigger the promised retaliation.
6. M28 Killing Light: system damage is once per critical volley, not every critical hit.
7. M32 Funeral Pyre: does not prevent all direct hull healing; threshold is checked before the hit.
8. M33 Spread Pattern: no burst on an ordinary accuracy miss against a valid target.
9. M38 Rangefinder: first weapon attack only; enemy Surge reduces 95% to 75%.
10. M35 One Clean Line: enemy Surge also reduces its stated 95% hit chance to 75%.
11. M03-M07 Five launch admirals: hide a full +25% wing hull bonus.
12. M08 Vaelen: hides +10 aim for non-lance weapons.
13. M09-M10 Hunt: Vorn/Ostrel omit the reload in stored descriptions; current generated UI is correct.
14. M11 Khepra: stored text promises irrelevant shields and understates shieldless protection; generated UI is correct.
15. M43 Swollen broods: adds capacity/spare after opening wings were deployed, rather than fielding an extra opening wing.

## Verification and final counts

- 54 finding rows: 44 live behaviour/scope/trigger/disclosure mismatches, 3 stored-only Command rows, 3 explicitly marked optional numeric disclosures, and 4 voice rows. Repeated admiral strings are counted per id, not as a single family. IDs M48 and M49 were withdrawn after reachability checks; stable IDs are intentionally not renumbered.
- 272 requested/adjacent description and weapon rows in the coverage matrix, plus all 24 admiral identity/Command-name sets. All 18 variants checked; no remaining variant weapon-loss mismatch found.
- Godot: 2,968 literal string leaves compared independently in each JSON table, zero differences; 192 generated protocol strings compared with campaign BOON_D, zero differences. Counts include ids, names and other literal leaves, not only player-facing prose.
- Prior reviews: 142 separately classified rows/subitems total: 66 STILL WRONG, 50 ALREADY FIXED, 26 NOT A PROBLEM. This includes all 96 numbered replacement rows (52/40/4 respectively), all 12 CODE flags, all four decisions with DEC-4 split into its four proposals, all notes/cleared items, and the admirals text findings and carried text items. Historical balance measurements and absent drafts were not re-audited as gameplay facts.
- Ran Node assertions on actual data.js/nameWeapons and the actual core.js mkWeapon function: all torpedoes base/Common/Rare cooldowns 2/1/1; star trait multiplier 1.2. Static findings otherwise come from the cited source, not a gameplay run.
- Only this report was created/edited. No game source, assets, tables or prior reviews changed. No commit.
