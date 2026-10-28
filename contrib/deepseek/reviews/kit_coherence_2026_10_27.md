BLIND AUDIT: FACTION KIT COHERENCE

VOIDSWORN / SUNWARD CRUSADE

1. BLOCKER - OBSERVED: The data still gives Voidsworn a carrier, against the recorded carrier gate. HULLS.reliquary is n:'Hearth-class carrier',cls:'Carrier',fac:'voidsworn'; FACTIONS.voidsworn.roster is ['warden','harrow','penitent','reliquary','cathedral']; and ADMIRALS.ashgrove starts ['reliquary','harrow','warden'] with doc:'Carrier doctrine'. INFERRED: if the carrier gate is adopted, the roster and Ashgrove's start fleet are illegal. The bible chapter 2.7 says carriers kept, so the data follows the bible but not the ruling. This conflict must be resolved before playtest.

2. NOTE - OBSERVED: Voidsworn has weapon names in FAC_WNAMES but no MOD_NAMES.voidsworn or RELIC_NAMES.voidsworn. INFERRED: its modules and relics fall back to generic names while other factions get faction-specific naming. This is a coherence gap, not a mechanics breach.

3. NOTE - OBSERVED: WTRAITS.las is applied to Voidsworn sear guns and gives fall=Math.ceil(w.fall/2); w.acc+=4. INFERRED: this long-range accuracy trait is not described in the Voidsworn bible section. It does not contradict the broadside move rule, but it adds an unexplained identity trait.

Verdict: FAIL. The carrier gate is a direct recorded-ruling breach and blocks a clean playtest of the faction roster.

HEGEMONY NAVY

1. BLOCKER - OBSERVED: The synchronized-fire definer is not expressed in the data. The ruling says synchronized fire (Kassar doctrine faction-wide) PRIMARY, pinning (Vorn interdiction) SECONDARY. The only synchronized entry is Kassar's command: n:'Synchronized broadside', d:'Every ship fires a free volley at the best target its guns can reach, right now.' Vorn's command is n:'Interdiction strike', d:'Every ship deals +30% damage this round.' INFERRED: neither entry implements faction-wide synchronized fire or pinning. The flagship-anchor loss, formation dependence, flagship-anchor version TO START, also has no data representation. This is a direct identity and rulings gap.

2. BLOCKER - OBSERVED: Ion suppression is still presented as Hegemony identity. FACTIONS.hegemony.blurb says Ion cannons strip shields; carriers launch fighter screens. The ionpulse ability is d:'Every enemy ship within 4 hexes loses half of each shield facing.' and is assigned to h_interdictor. The ruling says Ion suppression not adopted. Shield-stripping drops to ion weapon flavor, not the identity. INFERRED: the blurb and the ionpulse ability breach that ruling.

3. FIX - OBSERVED: ionpulse is completely dead against the two no-shield factions. Chorus hulls b_drone through b_boss all have sh:0; Eclipse hulls d_scythe through d_boss all have sh:0. INFERRED: a Hegemony h_interdictor loses its faction ability entirely against Chorus and Eclipse. This is both a balance problem and a counter-relationship problem.

4. NOTE - OBSERVED: h_boss uses ab:'nova', the same boss ability as Voidsworn ascendant and Eclipse d_boss. INFERRED: three faction bosses share one generic spinal-cannon job, which blurs boss identity and is not described in the Hegemony bible.

Verdict: FAIL. The definer is absent, the ion identity breach is explicit, and one Hegemony ability is dead against two factions.

ASHFALL HULLBREAKERS / CORSAIR

1. FIX - OBSERVED: The bible promises boarding, but the corsair kit does not deliver it. Chapter 4.5 says rams and boarding; chapter 4.3 says boarding claws at the bow. The corsair hulls have overburn on c_raider and c_marauder, but no boarding weapon or boarding ability. The only boarding-style weapon, tendril, is Chorus-only. INFERRED: the promised corsair boarding tactic is missing from the playable kit.

2. NOTE - OBSERVED: The rocket identity is present: FAC_WTRAIT.corsair assigns rockets to torp and htorp, and WTRAITS.rockets gives w.shots*=3; w.dmg=Math.round(w.dmg/2.9); w.acc+=2; w.evMult=1.5; w.rockets=1. INFERRED: this matches the bible's far too many rockets. The anti-rocket point-defense interaction is not verifiable in this pack.

3. NOTE - OBSERVED: c_boss uses cls:'Battle-barge', but CLS_NAME maps it to War-barge. INFERRED: the display class matches the bible's War-barge class even though the internal key is old.

Verdict: PASS WITH FIX. No direct ruling breach found, but the promised boarding role is absent from the data.

THE CHORUS

1. BLOCKER - OBSERVED: The data contains explicit Chorus repair and regeneration against the no-repair ruling. b_drone has ab:'regrow',regen:4; b_spitter has regen:5; b_razor has regen:7; b_brood has regen:8; b_boss has regen:20. The regrow ability says Regrow 25% of this ship's hull right now. Admiral mending has fx:{hullRegenPct:.04} and cmd:{id:'restore',n:'Regrowth tide'...}. INFERRED: as the prompt states the ruling, these are direct breaches. If the approved scope was shipyard-only, reclassify this finding and check the shipyard, Drydock, and Field repair code separately.

2. NOTE - OBSERVED: The no-shield roster fact is correct. Every Chorus hull has sh:0. INFERRED: this matches the bible and the observed roster ruling.

3. NOTE - OBSERVED: The acid and spine identities are present. FAC_WTRAIT.chorus assigns spines to bioplasma and acid to tendril and sporeb; WTRAITS.spines sets w.shred=.03; WTRAITS.acid sets w.acid=1. INFERRED: this expresses the bible's armour-stripping spines and acid, subject to battle.js implementation.

Verdict: FAIL. The Chorus repair/regeneration entries are a direct ruling breach on the prompt's wording.

THE GLASSWRIGHTS / ITHAR

1. FIX - OBSERVED: The data has no Glasswright Brace prohibition. ORDERS.brace is global: brace:{n:'Brace for impact'...}. No Ithar hull has a noBrace field or equivalent, and no faction gate appears in data.js. The ruling and bible say the Glasswrights cannot Brace. INFERRED: if canOrder in battle.js does not enforce this, the ruling is breached. The pack does not include canOrder, so this is not fully verified.

2. NOTE - OBSERVED: The Glasswright weapon names and traits match the bible: FAC_WNAMES.ithar maps shard to Prism shards, pulsar to Prism lance, startorp to Star torpedo, turret to Needle beam, and flak to Mirror veil. FAC_WTRAIT.ithar assigns needle to shard and turret, and star to startorp. INFERRED: the precision and hard-to-dodge identities are present.

3. NOTE - OBSERVED: i_boss uses cls:'Ark', displayed as Lattice-ship through CLS_NAME. INFERRED: this is a reasonable display for the flagship built around Lattice wreckage, though chapter 6.10 does not list a separate boss class name.

Verdict: PASS WITH FIX, conditional on the canOrder Brace gate being present in code.

ECLIPSE / DEATHLESS

1. NOTE - OBSERVED: The no-shield rule is correctly observed. All Deathless hulls have sh:0, including d_scythe, d_jackal, d_harvester, and d_boss. INFERRED: this matches the recorded roster fact and the bible.

2. NOTE - OBSERVED: d_scythe, d_jackal, and d_harvester have reanimate:true, but d_boss does not. The bible says the fallen come back and repair swarms rebuild each hull once. INFERRED: the boss may be intentionally excluded, but the data does not state that. Verify whether The Unsetting should also reanimate once.

3. NOTE - OBSERVED: Internal keys still use forbidden Necron-style terms: cls:'Tomb-ark', gauss, doom, reanimate, and RELIC phylactery. Display names are sanitized by CLS_NAME, FAC_WNAMES, and RELICS.phylactery.n:'Eclipse backup frame'. INFERRED: this is not player-facing if no internal key leaks, but it is a lore-hygiene risk in code and tooling.

Verdict: PASS. No direct ruling breach found. The no-shield fact is correct.

CROSS-FACTION

1. NOTE - OBSERVED: Two ability pairs are exact duplicates. ABILITIES.evasive and ABILITIES.phase both say +25 evasion until your next turn and +2 movement now. ABILITIES.focus and ABILITIES.frenzy both say All of this ship's weapons deal +30% damage this turn. INFERRED: these are faction-flavoured names over identical jobs, which blurs identity and makes the entries redundant.

2. NOTE - OBSERVED: ascendant, h_boss, and d_boss all use ab:'nova'. INFERRED: three faction bosses share one generic spinal-cannon ability, which is identity blur and is not supported by the faction chapters.

3. NOTE - OBSERVED: Chorus and Eclipse both field sh:0 hulls and both have self-regeneration or reanimation: Chorus has regen:4 through regen:20; Eclipse has regen:3 through regen:8 and reanimate:true. INFERRED: the two no-shield attrition factions converge in play style even though the bible distinguishes living flesh from machine repair.

4. NOTE - OBSERVED: The promised Hegemony ion counter to shields is dead against Chorus and Eclipse, both of which have sh:0. INFERRED: the counter relationship the Hegemony blurb implies does not exist against two of the six factions.

5. NOTE - OBSERVED: The Glasswright Brace prohibition is not visible in data.js. INFERRED: if code does not enforce it, the faction's promised fragility and no-Brace identity are not delivered.

OVERALL VERDICT

NOT READY for a clean faction-kit playtest. The direct ruling breaches are Voidsworn's retained carrier, Hegemony's missing synchronized fire and retained ion suppression, and Chorus's repair/regeneration entries. The Glasswright Brace prohibition is an unverified code gate. Corsair and Eclipse pass with notes, but cross-faction duplication and missing boarding reduce distinctiveness.

NOT CHECKED

- battle.js mechanics: synchronized-fire radius, flagship anchor, canOrder Brace gate, ion application, Chorus repair scope, reanimation, boarding, and point-defense versus rockets.
- Shipyard, Drydock, and Field repair implementation and scope.
- Full price ladder and costs for many hulls, because the pack only includes data.js lines 1 to 275.
- Draw assets, portraits, and collision or visual identity checks.
- Web collision-style checks were not performed; the report is from the pack alone.
