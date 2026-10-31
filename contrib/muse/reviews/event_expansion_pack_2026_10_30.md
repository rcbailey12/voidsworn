# Event expansion pack: 33 new events (beyond-scope slate, item 3, Oct 30, 2026)

Chair-authored content pack for Opus. Thirty-three new events in the exact shipped EVENTS shape, doubling the drawable pool from 33 to 66. Data file: `contrib/muse/tools/event_expansion/new_events_data.js` (defines `NEW_EVENTS`; integrate with `EVENTS.push(...NEW_EVENTS)`, or splice into the port's event table). No shipped event is modified, and nothing here is pushed or integrated yet. Game code read at the pin state of the Oct 30 checkout of voidsworn-fresh.

## Method

- The shipped pool was extracted by EXECUTING data.js through the campaign loader (`contrib/muse/tools/findings_tests/campaign_loader.js`), never by bracket matching source text (the Oct 29 chair error that truncated a pool to 11 of 33 is not repeated). Pool at the pin: 33 events, derelict through quiet, including the option splices at data.js:322-333 and the pushed block at data.js:334-421.
- Gate semantics from `eventOptOk` (campaign_run.js:232): an option is enabled only if its object-form `r.cost` is affordable and `needMet(o.need)` passes. Damage, payMod, payXp, payRelic and nemClock prices are NOT gated, so they can ambush a broke or unready player. The exit rule below is built on exactly that.
- Outcome vocabulary from `applyOutcome` (campaign_run.js:347-377): cost, cred, xp, xpLow, xpTop, loseMod, salvage (field `r.relic`), dmgOne, dmgAll, dmgBig, ship, shipRaw, vet, upgradeOne, repairOne, healAll, gamble, mod, modId, ambush, payMod, payXp, payRelic, wingPerk, nemIntel, nemClock, fight, plus the `derelictBoard` string resolver (not used by the new set).
- The free-exit test is the wave 5 event guarantee eval's own test (event_guarantee_eval_2026_10_29.md), replicated mechanically: an option is a free exit iff it has no need, no cost, and its result holds none of dmgOne, dmgAll, dmgBig, payMod, payXp, payRelic, loseMod, gamble, ambush, a positive nemClock, a fight field, or the derelictBoard resolver.
- Balance frame from the real campaign Monte Carlo (montecarlo_evidence_2026_10_30.md): credits run 120 at start to a mean of about 405 at end of sector 1 and 501 at end of sector 2; a run sees at most about 9 events; repairs price at 0.5 credits per HP. New single-event credit moves sit inside the shipped pool's observed envelope (ungated gains 25 to 65, gated or priced gains to 80, one salvage trade at 110 against the shipped lament trade at 120).

## Design rules, and how each was enforced

1. **Every event has an always-enabled exit.** One option per event carries no need, no cost field, and a result of `r:{}` (flavor only). Verified three ways: the eval test over the 66 pool, a worst-case `eventOptOk` run (10 credits, no carrier, no refits, no salvage, no flags, no intel, all six factions), and an `applyOutcome` smoke run of every new option.
2. **No seer defect.** A faction-gated option must sit in an event that faction can actually draw. Checked mechanically: for every option with `need.fac`, the event's `not` list does not bar all named factions. The set's five faction-gated options (Glasswright reading at ev2_starshard and ev2_glassgarden, Eclipse re-streaming at ev2_sickness, Hegemony audit at ev2_factor, Hullbreaker showing at ev2_moot, Crusade/Hullbreaker bluff at ev2_tithefleet) all sit in events open to the gated faction.
3. **No hidden fights, no hidden clock.** Both fight options print "Fight an elite ... battle. Win salvage." in the option text (the shipped moon/tomb/haven phrasing). Every option carrying a positive nemClock says "the Nemesis clock moves on" in its own text; every option carrying damage states the damage. No new option uses `ambush` at all (the beacon/bait pattern is not extended).
4. **Flags name a consumer or are declared flavor.** Every choice already writes `RUN.flags[event id] = option key` via eventFlags; one new option consumes such a flag for real: ev2_factor "oath" needs flag `ev2_oathbound` (set by any choice at ev2_oathbound; consumers test presence only, the CODE-7 behavior, and the option text is written so presence is enough: the survivor exists because the event happened). The `fl` counters used are the shipped counters only: `greed` (read numerically by the Hullbreaker shake verb: +10 credits per greedy choice), and `mercy`, `loud`, `intel`, which have presence readers in the verb and Nemesis systems and are otherwise declared flavor counters, matching the shipped pool's own usage.
5. **Voice.** Current display names only (Sunward Crusade, Hegemony Navy, Ashfall Hullbreakers, the Chorus, the Glasswrights, Eclipse). Per-faction variant bodies (`v` field) on three events, matching the shipped pattern where variants change title and body only, never options. No retired vocabulary: no song words anywhere, no smell motif for the Hullbreakers, the Dead Star appears once as pure backdrop (ev2_starshard, no mechanics), Eclipse text runs on Archive and memory, Hegemony text on the Registry and ledgers, Crusade text on chalked names, the Roll, and the debt.

## The 33 events, by type

Type mix against the shipped pool (chair classification of the shipped 33): exploration and salvage 10 shipped / 11 new; hazard 3 / 4; social and crew 6 / 7; faction-flavoured 7 / 6, including fight-start events (shipped 3: moon, tomb, haven; new 2, both with a free exit haven lacks); Nemesis-adjacent 4 / 2 (the cap for this set); rest and recovery 2 / 3 (the cap for this set).

EV columns use the conversion table in the balance section: best always-available option / best option including blue (need-gated) options / credit delta of the best always-available option.

### Exploration and salvage (11)

| Event | Rationale | EV |
|---|---|---|
| ev2_deadrelay | Derelict-kin: a looped manifest everyone can strip, read, or decode with a held refit. | 40 / 40 / +40 |
| ev2_icewreck | Boarding with disclosed ice damage against a safe slow melt; the derelict risk shape at smaller stakes. | 51 / 51 / +0 |
| ev2_graveyard | The pool's one ship join in this set: a scarred frigate of your own kind (ship `warden`, resolved per faction by equivHull), priced below the shipped destroyer join. Carrier wings are the clean salvage route. | 70 / 70 / +0 |
| ev2_sealedhold | A pure greed gradient: open it, cut it clean with lances, or sell the mystery unopened. | 60 / 80 / +60 |
| ev2_driftmines | Point defense gets a second showcase event (only the shipped bait and moon use flak gates); walking in costs 5 percent fleet hull, stated. | 28 / 55 / +40 |
| ev2_oldprobe | Charts for everyone; the salvage trade mirrors the shipped lament archive play at 110 against its 120. | 55 / 55 / +25 |
| ev2_fuelcache | Small honest money, with a torpedo gate for the armoured tank (torp gates are rare in the shipped pool: cache, scout). | 35 / 60 / +35 |
| ev2_starshard | Dead Star as backdrop only. The Glasswright blue option is the set's cleanest faction read: the light in the shard is their craft. | 55 / 80 / +55 |
| ev2_lostcargo | Carrier value event: wings herd the whole scatter, hands take what drifts close. | 45 / 70 / +45 |
| ev2_silentarray | The strip option is the set's one loud salvage: 50 credits with the clock advance printed in the option text. Eclipse variant body in the Archive register. | 20 / 20 / +0 |
| ev2_brokencairn | A mercy/greed fork on infrastructure: repair the cairn for experience, or take its cell for cash. | 40 / 40 / +40 |

### Hazards (4)

All four hazards carry a genuine free exit (turn back, seal the decks, drift dark), which the shipped hazards pointedly do not: storm, reactor and squall are three of the eval's seven failures. The exit is the Oct 28 ruling applied as written; see the open notes for the design cost of that choice.

| Event | Rationale | EV |
|---|---|---|
| ev2_micromets | The storm shape rebuilt: ride it (6 percent), shield it, or burn a flak lane and profit from the iron. | 0 / 30 / +0 |
| ev2_sickness | A shipboard hazard that is explicitly not the Chorus (the body says so; the Chorus is a weapon, not a disease). Eclipse crews solve it by re-streaming. | 0 / 20 / +0 |
| ev2_flare | The squall shape rebuilt with a purchasable shadow berth and a shields lesson. | 0 / 20 / +0 |
| ev2_breach | The reactor shape rebuilt: weld and risk the big ship, or spend a held refit on the spine. | 0 / 0 / +0 |

### Social and crew (7)

| Event | Rationale | EV |
|---|---|---|
| ev2_stowaway | The pilot event's younger sibling: a ward for the fleet, or a wing prodigy if you fly a carrier. | 35 / 40 / +0 |
| ev2_rollkeeper | The names of the dead, in the Crusade's chalk-and-Roll register without barring the other fleets' grief: barred for the Chorus only (the shrine precedent), with Archive and Registry variant bodies for Eclipse and Hegemony. The paid service is the set's one rest-priced heal outside the rest type. | 30 / 30 / +0 |
| ev2_oathbound | Sets the flag the factor event reads. Waking the sister is the experience play; taking her charts is the cash play; the oath itself is the fiction. | 50 / 50 / +50 |
| ev2_factor | Generational debt, the learning fiction in civilian dress. Three ways out: pay it, have the Registry audit it (Hegemony), or produce the oath-wreck survivor (flag gate, the set's one cross-event consumer). | 0 / 40 / +0 |
| ev2_cartographer | Clock relief for sale at 45 (see open notes), or a lesson for your best captain. | 15 / 15 / +0 |
| ev2_feud | Crew friction with a simulator duel, a fine, or a senior-captain referee; the fleet-internal event the shipped pool lacks. | 40 / 40 / +0 |
| ev2_quartermaster | The hold economy event: sell the surplus, or fence a held refit at double through her network (75 against the module's 60 anchor value). | 40 / 40 / +40 |

### Faction-flavoured (6, two of them fight-start)

| Event | Rationale | EV |
|---|---|---|
| ev2_tithefleet | Hegemony as procedure: comply and learn, bluff in Crusade or Hullbreaker terms, run and be reported (clock printed), or drift dark. Barred for Hegemony, who would be inspecting themselves. | 20 / 30 / +0 |
| ev2_glassgarden | Glasswright light and grief without a trade frame; the tune option is Glasswright-only and reachable (the anti-seer). | 55 / 80 / +55 |
| ev2_moot | The packs at their most social: trade, show (Hullbreaker blue), or put a ship in the scrap pit at stated damage. | 59 / 80 / +65 |
| ev2_silentship | Eclipse horror in the Archive register: a crew restored wrong. Barred for Eclipse, for whom it is not an encounter but a casualty. | 71 / 71 / +0 |
| ev2_pitfight | Fight-start: an elite Ashfall Hullbreaker battle for salvage, a toll that buys clock relief, or a clean walk-away haven never offered. | 120 / 120 / +0 |
| ev2_anchorage | Fight-start: an elite Hegemony Navy battle over a mistaken warrant, talkable by a veteran captain, payable as a fine, or refusable at range. | 120 / 120 / +0 |

### Nemesis-adjacent (2, the cap)

| Event | Rationale | EV |
|---|---|---|
| ev2_witness | Intel with a cross-check blue option (needs one known weakness, pays 30 for precision) and a sell-on option whose clock cost is printed. | 60 / 90 / +0 |
| ev2_falseflag | The Nemesis as framer: hunt the impostor (stated damage, clock back, weakness from her fitting-out), torpedo her clean, pay the convoys off, or let the lie stand for free. | 78 / 90 / +0 |

### Rest and recovery (3, the cap)

| Event | Rationale | EV |
|---|---|---|
| ev2_spring | The quiet event's warmer sibling: soak, bottle, drill, or fill the tanks and go. | 36 / 36 / +0 |
| ev2_longnight | Rest as character: story, sleep shifts, or silence. Chorus and Eclipse variant bodies (the swarm's quiet; backups verified one by one). | 30 / 30 / +0 |
| ev2_waystation | A founders' dock: proper mend at 35 for 30 percent, hand mend free at 15 percent, the dock/wright price shape without the upgrade. | 37 / 37 / -35 |

## Balance summary against the shipped pool

Conversion table (one convention, applied identically to both pools; anchors are the game's own prices where they exist): salvage gain or loss 80 (the game's fallback price for a salvage find); module gain or loss 60 (the convoy event prices a random refit at 60); xp to every captain 2 per point (veterans prices 25 at 50); xp to one captain 1 per point; healing 0.5 credits per HP across a 480 max-HP fleet, useful heal capped at 35 percent; damage at the same rate (dmgOne on a 120 HP ship, dmgBig on a 180 HP ship); a Nemesis weakness 60 (the broker's price); nemClock 30 per step; a joining hull at yard cost; a fight option at a flat 120 (elite battle credits plus salvage, the same value the shipped fight events score); gamble at its coin-flip expectation; ambush at a flat minus 25; derelictBoard at its shipped 60/40 expectation of 62.

Pool results under that convention:

- Mean best-available EV: shipped 43.4, new 42.3. The new set plays at shipped value.
- Median best-available EV: shipped 50, new 40.
- Mean best-with-blue EV: shipped 71.7, new 52.4. The gap is deliberate and is the set's main balance posture: the shipped blue ceiling is set by a destroyer join (merc) and a 120-credit salvage trade (lament); the new set's top blue plays are 80 to 90 (lance-cut goods, Glasswright salvage, pack respect, a cross-checked weakness). The expansion adds breadth at mid value rather than new ceiling plays. If Opus wants the ceiling matched, one destroyer join is the lever.
- Mean credit delta of the best option: shipped +3.6, new +15.6. This is the one real pool shift: the new set offers mid-size cash more often. In the combined 66 pool the mean is +9.6, so a player who always takes the cash-best option across about 9 event nodes a run gains roughly 54 credits more per run than in the shipped pool alone, against a median purse of 405 at end of sector 1. Measured, stated, and left for Opus: shaving ev2_moot "show" (80) and ev2_silentship "strip" (60) by 10 each would halve the shift.
- Damage posture: new hazards are never forced-negative, because the exit exists (best-available EV 0 across all four). Shipped hazards force a price by design. Net effect of doubling: event nodes get safer on average; battle nodes remain the run's attrition source, which matches the Monte Carlo finding that sector 2 elites, not events, carry the attrition.

## Validation (full output)

Scratch build: clone data.js, core.js, battle.js, campaign_meta.js, campaign_run.js copied to a scratch directory, the deliverable file appended to the scratch data.js with `EVENTS.push(...NEW_EVENTS)`, loaded through the campaign loader. The clone itself was never modified (git status clean throughout).

```
POOL: total=66 shipped=33 new=33
ID duplicates within new set: none
ID collisions vs HULLS: none
ID collisions vs MODULES: none
ID collisions vs RELICS: none
ID collisions vs ADMIRALS: none
ID collisions vs FACTIONS: none
ID collisions vs BOONS: none
ID collisions vs ENCOUNTERS: none

FREE-EXIT EVAL (66 pool): PASS=59 FAIL=7
  shipped fails: haven, mutiny, reactor, saboteur, scout, squall, storm
  new fails: NONE
  shipped fail set == known 7: true

VOCABULARY/REACHABILITY problems: none

WORST-CASE eventOptOk on designated exits (6 factions): failures=0
APPLYOUTCOME SMOKE: 345 option runs across 3 factions, throws=0
```

Plus: `table_xref.js` output on the scratch build is byte-identical to its output on the unmodified clone (exit 0 both). A retired-vocabulary scan of the new file hits only the code field names `relic` and `payRelic` inside result objects, which is the shipped convention (the code field is named relic; every player-facing string in the set says salvage). Player text scan: zero hits for warp, auspex, cogitator (as a word in text), psyker, archeotech, xenos, saint, litany, heresy, hive, song, choir, hymn, chant, psalm, rite. Em dash count 0, en dash count 0, in both deliverables.

## Open notes (rules bent, and what could not be fully satisfied)

1. **Flag consumers (rule e), partially satisfied by construction.** The one hard consumer pair is inside the set (ev2_oathbound's flag feeds ev2_factor's oath option). The greed counter has a real numeric reader (the shake verb). Mercy, loud and intel counters have no numeric reader in shipped code; they are presence and flavor counters, exactly as the shipped pool already uses them (beacon's mercy, tithe's loud, broker's intel have the same status). Inventing new consumers would mean inventing systems, which is Opus's call, not a content pack's.
2. **Hazard exits soften hazards, deliberately.** Rule (a) requires an exit in every event; the shipped design gives hazards none, and three of the eval's seven failures are hazards. The new hazards therefore let a player walk away from weather. That is the Oct 28 ruling read as written (the eval's own port recommendation extends leave options to all seven failures), but it is a real design cost: in the combined pool, roughly half of hazard draws become optional. If Ryan wants hazards exempt from the guarantee, the four exits come out in one edit each and the events still pass every other rule.
3. **Clock relief for credits.** Two new options sell nemClock minus 1 (ev2_cartographer at 45 credits, ev2_pitfight tribute at 45 with a fight behind it). The shipped pool sells clock relief only through gated combat-adjacent options (scout, saboteur). This is inside the shipped vocabulary and priced at the dock's repair band, but it is a softening of Nemesis pressure and is flagged rather than buried.
4. **EV is a stated convention, not a simulation.** The balance numbers above come from the conversion table, applied uniformly. The set was not run through the campaign Monte Carlo: the harness exists and the pool loads through it, so a 66-pool sim is a follow-up Opus or a later Rey pass can run if the credit tilt in the balance summary needs a play-measured answer.
