# DeepSeek blind leg: hull roster identity audit (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (DeepSeek, DeepThink ON + Search ON, verified by toggling). Em dashes and en dashes normalized to hyphens per house rule; wording otherwise unchanged. Chat: https://chat.deepseek.com/a/chat/s/4a99f1ce-dd76-4880-a005-7b440d544a6f. Evidence pack: the Oct 28 battle program roster pack (code slices pinned to main 264f441d). Method notes and screening live outside this file. Chair note on Finding 2: the leg is right and the pack census was wrong; see the screening note.

## Proof of reading

Read: EVIDENCE PACK title line; THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE; code slices HULLS and FACTIONS; hull variants slice.

Overall verdict: DUPLICATES WITH PAINT - the roster has real faction flavor, but several hulls are the same job with different names, launch is over-concentrated, and some variants are strict upgrades.

## Findings

### [BLOCKER] Cross-faction frigate identity duplication: Warden vs Hegemony picket.

READ: both are CP1 frigates with shields 10, range 5, armor .1, speed 5, turn 3, evasion 18-20, ab:'evasive', and a turret flak mount. INFERRED: the only real differences are autocannon vs laser and +5 HP/+2 evasion; at battle distance this is one picket with faction paint, not two identities. Quote: hp:45... ev:20 vs hp:40... ev:18.

### [BLOCKER] The code roster does not match the census's "five-ship ladder plus boss" claim.

READ: Hegemony roster is ['h_picket','h_interdictor','h_vanguard','h_dominion'] plus boss; Corsair, Chorus, and Ithar have four base hulls; Deathless has three. Only Voidsworn has five base hulls plus a boss, and its boss is the ascendant dreadnought. INFERRED: the ladder and boss comparisons in the commission cannot be fully verified from this slice, and five factions lack a separate dreadnought layer.

### [FIX] Same-CP carrier duplication: Reliquary vs Hullbreaker hulk-carrier.

READ: both are CP4, ab:'launch', hangar:2, speed 2, turn 1, evasion 0, with two turret weapons. INFERRED: the difference is a defensive trade - Reliquary has 130 HP/22 shields/.15 armor and flak; c_hulk has 170 HP/16 shields/.2 armor and a second turret - but the job is the same carrier at the same CP. That is rounding-error differentiation, not a clean decision.

### [FIX] launch is over-concentrated, while several abilities are single-hull orphans.

READ: launch appears on reliquary, h_vanguard, h_dominion, c_hulk, c_boss, b_brood, b_boss, and i_carrier. focus, ionpulse, frenzy, and reclaim each appear on exactly one hull. INFERRED: launch is doing too much identity work, including on Hegemony line ships; focus/ionpulse/frenzy/reclaim read as faction signatures without families.

### [FIX] Chorus boss is mechanically a larger brood-sac.

READ: b_boss and b_brood both have ab:'launch', hangar:3, speed 2, turn 1, evasion 0, and the same core bioplasma/spores identity; b_boss adds a tendril and regen:20 instead of regen:8. INFERRED: this is mainly a bigger number plus one extra weapon, not a mechanically distinct boss.

### [FIX] Variants include strict upgrades, not sidegrades.

READ: h_picket_i moves the laser from forward to turret and adds mod:{ev:24} with no listed downside; c_reaver_t moves the scatter from starboard to turret with no listed downside; d_scythe_s adds a gsentry turret with no listed downside. INFERRED: these are strict upgrades, so the variant economy offers a tax/trap rather than a choice. Worst strict upgrade: d_scythe_s, because it simply adds a weapon.

### [FIX] CP value is not honest across hulls.

READ: i_song costs CP4 for 90 HP, 26 shields, and .05 armor; c_hulk costs CP4 for 170 HP, 16 shields, .2 armor, and hangar 2. INFERRED: by raw durability per CP, i_song is the worst-value hull and c_hulk is one of the best non-boss values; CP is not consistently pricing survivability plus hangar capacity.

### [NOTE] Hegemony has two launch line ships with the same hangar-1 carrier-screen ability.

READ: h_vanguard is CP4 with ab:'launch',hangar:1; h_dominion is CP6 with ab:'launch',hangar:1; both carry ion forward. INFERRED: the CP/size difference is a real escalation, but the ability duplication makes the two hulls read as "line ship with a token wing" twice.

### [NOTE] Boss CP honesty is uneven.

READ: ascendant is CP8, 370 HP, 32 shields, .35 armor, nova; h_boss is CP12, 560 HP, 40 shields, .3 armor, nova; c_boss is CP10, 600 HP, 30 shields, hangar 2, launch. INFERRED: h_boss pays +4 CP over ascendant for +190 HP/+8 shields but loses armor and has no hangar; c_boss at CP10 has more HP than h_boss at CP12. Boss CP is not a clean power ladder.

### [NOTE] Faction flavor is real in defenses and movement identity.

READ: Chorus has no shields but regen; Ithar has shields and blink; Deathless has armor, phase, and reanimate; Corsair has speed/evasion and overburn; Voidsworn has armor and broadsides; Hegemony has shields/ion/launch. INFERRED: the roster is not six identical ladders, but the duplication above still muddies fleet-intent readability.

## Explicit checks

### 1. ROLE CLARITY

The code does not contain five base hulls for five of the six factions; I list every base hull present.

Voidsworn
- warden: CP1 evasive screen; forward autocannon, turret flak.
- harrow: CP2 torpedo destroyer; forward torpedo, turret, reload.
- penitent: CP3 broadside cruiser; port/starboard batteries, forward lance, focus.
- reliquary: CP4 carrier; launch, hangar 2, turret/flak defensive carrier.
- cathedral: CP5 battleship; heavy broadsides, lance, flak, surge.
- Boss ascendant: CP8 dreadnought; broadside/turret/flak, nova; also the faction boss.

Hegemony
- h_picket: CP1 evasive laser/flak picket.
- h_interdictor: CP2 ion/turbo destroyer; ionpulse shield-stripper.
- h_vanguard: CP4 cruiser with two turbo turrets, ion, launch, hangar 1.
- h_dominion: CP6 battleship with heavy broadsides, ion, flak, launch, hangar 1.
- No fifth base hull or separate dreadnought in the slice. Flag: h_vanguard and h_dominion both read as "line ship with a token launch wing."

Corsair
- c_raider: CP1 fast overburn raider; turret autocannon.
- c_marauder: CP3 broadside scatter/torp/flak cruiser; overburn.
- c_reaver: CP2 torpedo/scatter destroyer; reload.
- c_hulk: CP4 carrier; launch, hangar 2, turrets.
- No fifth base hull or dreadnought in the slice.

Chorus
- b_drone: CP1 regrowing tendril brawler.
- b_spitter: CP2 regrowing bioplasma destroyer.
- b_razor: CP3 frenzy/regen tendril+bioplasma cruiser.
- b_brood: CP5 carrier; launch, hangar 3, regen.
- No fifth base hull or dreadnought in the slice.

Ithar
- i_wisp: CP1 fast shielded blink shard frigate.
- i_blade: CP2 shielded blink shard/startorp destroyer.
- i_song: CP4 shielded pulsar cruiser; surge.
- i_carrier: CP5 shielded carrier; launch, hangar 2.
- No fifth base hull or dreadnought in the slice.

Deathless
- d_scythe: CP1 phase/reanimate gauss frigate.
- d_jackal: CP2 phase/reanimate gauss destroyer.
- d_harvester: CP4 reclaim/reanimate gauss/doom/gsentry cruiser.
- No carrier, battleship, or dreadnought in the slice.

Flag: no same-faction pair has identical one-liners, but h_vanguard/h_dominion come closest because both are launch-hangar-1 ion line ships.

### 2. DUPLICATION

Three closest pairs:
- warden vs h_picket - closest pair in the roster. Same CP, shields, range, armor, speed, turn, evasion ability, and flak turret; only laser vs autocannon and tiny HP/evasion differences. Rounding error / paint, not a decision.
- reliquary vs c_hulk - both CP4 launch carriers with hangar 2, speed 2, turn 1, evasion 0, two turrets. Difference is HP/armor vs shields/flak. Rounding error / faction paint at the role level.
- h_vanguard vs h_dominion - same faction, both launch with hangar 1 and forward ion; CP4 cruiser vs CP6 battleship. The size/CP difference is a real decision, but the shared launch ability makes it a narrow one.

### 3. THE LADDER

The six ladders are not literally one template: Voidsworn is armor/broadside, Hegemony shields/ion/launch, Corsair speed/overburn, Chorus no-shield/regen, Ithar shields/blink, Deathless armor/phase/reanimate. That is real faction flavor. But the structural spine is the same frigate -> destroyer -> cruiser -> carrier/battleship -> boss, and the code rosters are incomplete, so the claimed five-step ladder is not present for five factions.

CP honesty: by raw durability, best non-boss value is c_hulk - CP4 for 170 HP, .2 armor, hangar 2, launch - and worst is i_song - CP4 for 90 HP, 26 shields, .05 armor. The 8-point ascendant has 370 HP, 32 shields, .35 armor, nova; the 12-point h_boss has 560 HP, 40 shields, .3 armor, nova and one more weapon. That is +4 CP for +190 HP and +8 shields but lower armor and no hangar. c_boss at CP10 has 600 HP and hangar 2. CP is not a clean value ladder across bosses.

### 4. ABILITIES

Distribution:
- launch: 8 hulls - reliquary, h_vanguard, h_dominion, c_hulk, c_boss, b_brood, b_boss, i_carrier.
- surge: 3 - cathedral, i_song, i_boss.
- nova: 3 - ascendant, h_boss, d_boss.
- evasive: 2 - warden, h_picket.
- reload: 2 - harrow, c_reaver.
- overburn: 2 - c_raider, c_marauder.
- regrow: 2 - b_drone, b_spitter.
- blink: 2 - i_wisp, i_blade.
- phase: 2 - d_scythe, d_jackal.
- Single-hull/orphan abilities: focus (penitent), ionpulse (h_interdictor), frenzy (b_razor), reclaim (d_harvester).

Hulls whose ability fights their stats: h_vanguard and h_dominion both spend their ability slot on launch for a single hangar while their main payload is guns. Most wasted: h_dominion, a CP6 battleship whose broadsides are the real job; launch on one wing is a token ability and duplicates h_vanguard.

### 5. VARIANTS AND BOSSES

Variants are not consistently sidegrades. Strict upgrades: h_picket_i (forward laser becomes turret laser, +6 evasion), c_reaver_t (starboard scatter becomes turret scatter), d_scythe_s (adds gsentry turret with no downside). Worst strict upgrade: d_scythe_s. No strict downgrade exists in the slice; the worst downgrade-leaning trade is h_vanguard_g, which loses launch/hangar 1 for a third turbo turret, but it still gains a weapon, so it is not strictly worse.

Bosses:
- ascendant vs cathedral: distinct via nova/turret vs surge/lance, but it is also the faction boss and there is no separate Voidsworn dreadnought.
- h_boss vs h_dominion: bigger plus nova instead of launch, extra turret, no hangar; partly distinct, mostly bigger.
- c_boss vs c_hulk: same launch and hangar 2, much bigger plus heavy guns; mostly bigger with the same carrier ability.
- b_boss vs b_brood: same launch, hangar 3, speed, turn, evasion; extra weapons and regen; mainly bigger, the worst boss differentiation.
- i_boss vs i_carrier: distinct - no hangar, surge instead of launch, gun-ark role.
- d_boss vs d_harvester: same gauss/doom core, nova instead of reclaim, flak instead of gsentry; bigger with an ability swap, moderately distinct.

## Not checked

- Exact weapon damage, accuracy, cooldowns, and range behavior; the pack gives weapon ids and mounts, not full weapon tables.
- Full definitions of overburn, ionpulse, frenzy, reclaim, surge, nova, and launch; only evasive, reload, and focus are described in the ability slice.
- Module slot contents and whether slots materially change roles.
- Visual silhouettes and whether faction paint is readable at battle distance.
- Actual battle simulation, AI behavior, and whether CP economy performs as the raw numbers suggest.
- Renown/variant economy beyond listed costs; whether strict upgrades are acceptable because of acquisition cost.
- Hulls or classes omitted from this slice; the census claims more than the code slice shows.

## Questions for the designer

- Are the code rosters intentionally 3-4 base hulls for five factions, or is the slice incomplete? Stakes: the entire ladder and boss audit depends on whether the missing dreadnoughts/carriers exist elsewhere.
- Why do h_vanguard and h_dominion both carry launch with only hangar 1 instead of one dedicated Hegemony carrier? Stakes: launch identity, Hegemony fleet readability, and CP honesty.
- Should variants like h_picket_i, c_reaver_t, and d_scythe_s be strict upgrades, or must every variant carry a real trade? Stakes: whether variants are choices or a tax/trap economy.
