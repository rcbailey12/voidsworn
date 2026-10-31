# Port export: validation report

Source: data.js executed in Node (vm) from the clone at pin 264f441d43a54e3679950dcc4457133b40811807. Tools: tools/export_data.js and tools/validate_export.js in this workstream's folder (staged with the export under contrib/muse/tools/port_export/). Machine-readable results: validation.json (in this folder), manifest.json (per-table counts and bytes).

## What was exported

64 files: one JSON per data.js table (62 tables), plus boons_evaluated.json (every boon's fx and description evaluated at all four rarity multipliers, because BOONS stores d and fx as functions of the multiplier m = RARITY[r].m; core.js:172 calls fx(RARITY[b.r||0].m)), wtraits_source.json (the 10 WTRAITS mutator functions exported as source text, because they are code, not data), manifest.json, and this report.

Table counts (entries): W 25, HULLS 51, FACTIONS 6, ABILITIES 13, MODULES 13, PERKS 14, RELICS 12, ADMIRALS 24, LEGACY 12, EVENTS 33, HULL_VARIANTS 18, BOONS 48, PATRONS 6, NEM_WEAK 7, NEM_ADAPT 5, NEM_TRAITS 14, NEM_PERSONA 8, NEM_FAC 6, NEM_ADAPT_FAC 6, ASPECTS 6, HEAT 7, RARITY 4, SHIP_NAMES 28, CAP_FIRST 28, CAP_LAST 28, MORE_SHIP_NAMES 5 faction pools, RELIC_NAMES 5 faction rows, FAC_PRICE 6, FAC_WPOOL 6, FAC_WNAMES 6, FAC_WTRAIT 6, WTRAITS 10, plus the small tables (full list in manifest.json).

Function-valued fields: 106, all in two places: WTRAITS.*.f (10 mutators) and BOONS.*.d / BOONS.*.fx (96, two per boon for 48 boons). Both are fully covered by the two supplementary files above. No other table contains functions, and nothing else was dropped by serialization.

## Checks that pass (19)

- Every hull's faction reference resolves; every hull weapon mount names a defined weapon with a valid arc; every hull ability resolves to ABILITIES.
- Faction rosters: every roster entry exists and its fac matches the faction; every faction boss is a defined hull.
- Admirals: all 24 name a defined faction, every starting-fleet hull exists, every admiral has a cmd.id.
- Boons: every patron and duo patron resolves to PATRONS; every BOON_NEED key is a real boon. Modules: every MOD_NEED key is a real module.
- Nemesis tables: every NEM_FAC key is a faction, every persona named in NEM_FAC exists in NEM_PERSONA, every NEM_ADAPT_FAC key is a faction.
- FAC_WNAMES and FAC_WTRAIT: every renamed weapon exists, every trait id exists in WTRAITS.
- FAC_WPOOL: the shipped computed table matches an independent recomputation from HULLS for all six factions.
- RELIC_NAMES: every renamed relic id exists in RELICS.
- EVENTS: all 33 ids unique. SHIP_NAMES, CAP_FIRST, CAP_LAST: no duplicates.
- fighter and bomber (data.js:70 to 71) are intentionally factionless generic squadron templates (cls Squadron, sq field set); the port must not assume every HULLS entry carries fac.

## Findings (25: 1 FIX, 24 NOTE)

### FIX

1. flak and gsentry are the same weapon. W.flak and W.gsentry are field-identical except the display name (both k:'flak', shots 3, dmg 3, r 2, opt 2, acc 80, fall 10, vsSq 3, vsCap 0.6). Because the kind is 'flak' for both, and flak-kind mounts never fire offensively (see the spec's firing section), a hull mounting both gains nothing from the second mount. Eclipse exposes the pair three times through its rename table. This is the defect underneath the withdrawn battleship entry: the filed d_meridian mounted gauss, gauss, doom (F), gsentry (T), flak (T), which is the d_harvester offensive battery verbatim plus a void second point-defense mount.

### NOTE: known items verified in the export

2. d_boss has no reanimate field. It is the only deathless hull without one; d_scythe, d_jackal, d_harvester and the deathless variants (d_scythe_s, d_harvester_t, d_jackal_h) all carry reanimate: true. Whether the boss should reanimate is a design question the export cannot answer; the asymmetry is now on record with the full list.
3. ascendant vs cathedral inversion (Argon gamedev leg, verified): ascendant cp 8, speed 1, cost 520, weapons hbattery P/S, turret, flak; cathedral cp 5, speed 2, cost 340, weapons hbattery P/S, lance, flak. The cp-8 unique costs more CP, is slower, and mounts a turret where the cp-5 mounts a lance.
4. d_meridian is NOT in HULLS at the pin. The Oct 29 battleship entry is a filed proposal (contrib/muse/reviews/battleship_entry_2026_10_29.md), not shipped data. The export correctly omits it.
5. "Acceptable Loss" is still in the Crusade SHIP_NAMES pool at the pin, despite the Oct 28, 2026 ruling swapping it out.
6. Rear-arc mounts: none. No hull mounts any weapon in arc R at the pin, consistent with the fiction rule that guns never face backward. (The WPN-5 findings-test failure concerns a rear arc defined in a weapon trait context, not a hull mount; the export's mount check is clean.)

### NOTE: variant weapon removals vs base (11 of 18 variants)

Variant w lists replace the base list wholesale. Removals, with the disclosure judged against each variant's own description text:

- Disclosed in the description (7): vs_harrow_t (removes turret, "no turret"), vs_penitent_g (lance to battery, "Swaps the prow lance"), vs_penitent_l (battery to lance, "instead of the broadsides"), b_spitter_s (bioplasma to tendril, "Trades a prow gun"), b_razor_e (tendril to bioplasma, "becomes a second spine volley"), i_wisp_l (shard to pulsar, "in place of the prism shards"), c_marauder_g (flak to torp, "instead of flak").
- Silent (3): b_razor_s removes bioplasma (description cites only tendrils, speed and evasion), i_song_w removes pulsar (description cites only the turret lance and shields), d_harvester_t removes one gauss (description cites only the turret-mounted corona arc). These are exactly the three silent deletions in the findings-to-tests ledger (ROS-2); the export independently reproduces the list.
- Ambiguous (1): c_hulk_g removes one turret and adds two scatter; its description says "No hangar; scatter broadsides, a turret and 20 more hull", which mentions a turret without stating the net mount change. (ROS-3 separately flags c_hulk_g and h_vanguard_g for broken mounts; the export's mount check passes, so the ROS-3 defect is in mount semantics, not id resolution.)

### NOTE: coverage gaps in lookup tables

7. RELIC_NAMES has no row for voidsworn (the Sunward Crusade): all 12 relics display under base names for the player faction. Other rows: Hegemony 11 of 12, Hullbreakers 10, Chorus 11 (no phylactery), Eclipse 10 (lattice also falls back), Glasswrights 8 (missing spore, phylactery, compass, salvage). Counts chair-verified in the relics synthesis; the export reproduces them.
8. FAC_PRICE sparsity: only listed classes deviate from the x1.0 fallback. voidsworn lists only Carrier 1.25; hegemony lists nothing (all x1.0); corsair misses Battle-barge; chorus misses Squadron and Bio-titan (display-renamed Colossus via CLS_NAME); ithar misses Ark; deathless misses Tomb-ark (the boss class, not purchasable). Mostly by design, recorded so the port does not mistake missing keys for missing data. Note the keys are the raw cls strings; display renames (CLS_NAME: Battle-barge to War-barge, Bio-titan to Colossus, Ark to Lattice-ship, Tomb-ark to Archive-ship) apply only at display time.

## Relationship to the Godot tree's own tables

godot/rules/data/tables.json and godot/campaign/data/campaign_tables.json already mirror these tables (plus constants harvested from core.js and battle.js), but the two files disagree with each other on 6 shared tables and the campaign file is one balance pass behind the pin (full numbers in the spec, hazard H2). This export is the single-source, per-table, validated reference generated from the pin; it is the reconciliation target, not a third competitor.
