# Pack F: Save-Integrity Sweep (DeepSeek)

Filed by Rey from Ryan's paste, Oct 23, 2026. Model: DeepSeek (attribution confirmed by Ryan). Charter and pack: contrib/muse/prompts/ (Pack F). Screening: contrib/muse/reviews/packFGHI_screening.md. Filed as returned (final answer only; the paste's reasoning trace is not reproduced), with em dash separators normalized to house style. Claims are the model's own and are not verified by filing.

---

I audited only the supplied pack. Every row and finding below is OBSERVED in the pack unless explicitly marked INFERRED.

Deliverable 1: Save-integrity sweep table
Legend: "Save origin" means the id is read from a persisted run/meta field. "Stock" means it is persisted inside RUN.map nodes (n.stock), not meta.

HULLS / hull templates (including variant hull ids through HULLS)

| # | File:line | Exact dereference quoted | Save origin | Status / guard |
|---|---|---|---|---|
| 1 | core.js:143 | HULLS[sh.tpl].sh / HULLS[sh.tpl].hangar | RUN.fleet[].tpl | UNGUARDED |
| 2 | core.js:155 | HULLS[b.tpl].cp / HULLS[a.tpl].cp | RUN.fleet[].tpl | UNGUARDED |
| 3 | core.js:164 | const t=HULLS[ship.tpl]; | RUN.fleet[].tpl | UNGUARDED |
| 4 | core.js:180 | HULLS[s.tpl].cp | RUN.fleet[].tpl | UNGUARDED |
| 5 | core.js:184 | HULLS[s.tpl].cp | RUN.fleet[].tpl | UNGUARDED |
| 6 | campaign_meta.js:96 | HULLS[f.tpl].n | RUN.fleet[].tpl | UNGUARDED |
| 7 | campaign_meta.js:176 | HULLS[x.tpl].n | RUN.fleet[].tpl | UNGUARDED |
| 8 | campaign_run.js:45 | HULLS[s.tpl].cls | RUN.fleet[].tpl | UNGUARDED |
| 9 | campaign_run.js:89 | const t=HULLS[s.tpl] | RUN.fleet[].tpl | UNGUARDED |
| 10 | campaign_run.js:109 | HULLS[s.tpl].slots / HULLS[s.tpl].ab | RUN.fleet[].tpl | UNGUARDED |
| 11 | campaign_run.js:127 | HULLS[s.tpl].ab | RUN.fleet[].tpl | UNGUARDED |
| 12 | campaign_run.js:150 | const t=HULLS[h] | RUN.map...stock.hulls[] | UNGUARDED |
| 13 | campaign_run.js:155 | HULLS[s.tpl].cost | RUN.fleet[].tpl | UNGUARDED |
| 14 | campaign_run.js:174 | const t=HULLS[h] | saved stock hull via UI arg | UNGUARDED |
| 15 | campaign_run.js:180 | HULLS[s.tpl].cost | RUN.fleet[].tpl | UNGUARDED |
| 16 | campaign_run.js:181 | HULLS[s.tpl].cost | RUN.fleet[].tpl | UNGUARDED |
| 17 | battle.js:97 | const t=HULLS[tpl]; | RUN.fleet[].tpl | UNGUARDED |
| 18 | battle.js:122 | HULLS[sh.tpl].cp | RUN.fleet[].tpl | UNGUARDED |
| 19 | battle.js:316 | HULLS[sh.tpl]&&HULLS[sh.tpl].hangar | RUN.fleet[].tpl | GUARDED by truthy HULLS[sh.tpl]&& |

RELICS

| # | File:line | Exact dereference quoted | Save origin | Status / guard |
|---|---|---|---|---|
| 20 | core.js:136 | RELICS[r]?RELICS[r].fx | RUN.relics[] | GUARDED by truthy RELICS[r]? |
| 21 | core.js:156 | RELICS[r]?RELICS[r].run | RUN.relics[] | GUARDED by truthy RELICS[r]? |
| 22 | core.js:191 | RELICS[r].n | RUN.relics[] via relicName | UNGUARDED |
| 23 | campaign_run.js:46 | RELICS[r].d | RUN.relics[] | UNGUARDED |

MODULES

| # | File:line | Exact dereference quoted | Save origin | Status / guard |
|---|---|---|---|---|
| 24 | core.js:166 | MODULES[m]?MODULES[m].fx | RUN.fleet[].mods[] | GUARDED by truthy MODULES[m]? |
| 25 | core.js:190 | MODULES[m].n | RUN.inventory[] / RUN.fleet[].mods[] via modName | UNGUARDED |
| 26 | campaign_run.js:93 | MODULES[m].d | RUN.fleet[].mods[] | UNGUARDED |
| 27 | campaign_run.js:109 | MODULES[m].only | RUN.inventory[] | UNGUARDED |
| 28 | campaign_run.js:110 | MODULES[m].d | RUN.inventory[] | UNGUARDED |
| 29 | campaign_run.js:153 | MODULES[m].cost | saved stock st.mods[] | UNGUARDED |
| 30 | campaign_run.js:154 | MODULES[m].d | saved stock st.mods[] | UNGUARDED |
| 31 | campaign_run.js:175 | MODULES[m].cost | saved stock st.mods[] | UNGUARDED |

PERKS

| # | File:line | Exact dereference quoted | Save origin | Status / guard |
|---|---|---|---|---|
| 32 | core.js:166 | PERKS[p]?PERKS[p].fx | RUN.fleet[].cap.perks[] | GUARDED by truthy PERKS[p]? |
| 33 | campaign_run.js:102 | PERKS[p].d / PERKS[p].n | RUN.fleet[].cap.perks[] | UNGUARDED |
| 34 | campaign_run.js:130 | PERKS[p].n / PERKS[p].d | RUN.fleet[].cap.offer[] | UNGUARDED |

BOONS / RARITY

| # | File:line | Exact dereference quoted | Save origin | Status / guard |
|---|---|---|---|---|
| 35 | core.js:54 | BOONS[e.id].p | META.tel[].id (boon_pick) | GUARDED by &&BOONS[e.id] |
| 36 | core.js:136 | BOONS[b.id] | RUN.boons[].id | GUARDED by if(BOONS[b.id]) |
| 37 | core.js:136 | RARITY[b.r\|\|0].m | RUN.boons[].r | UNGUARDED |
| 38 | core.js:140 | BOONS[b.id]&&BOONS[b.id].p | RUN.boons[].id | GUARDED by truthy BOONS[b.id]&& |
| 39 | campaign_meta.js:98 | BOONS[RUN.giftBoon].p | RUN.giftBoon | UNGUARDED |
| 40 | campaign_meta.js:98 | BOONS[RUN.giftBoon].n | RUN.giftBoon | UNGUARDED |
| 41 | campaign_run.js:22 | const B0=BOONS[b.id]; if(!B0) return '' | RUN.boons[].id | GUARDED by if(!B0) return |
| 42 | campaign_run.js:22 | R=RARITY[b.r\|\|0] | RUN.boons[].r | UNGUARDED |
| 43 | battle.js:124 | (RARITY[b.r\|\|0]\|\|RARITY[0]).m | RUN.boons[].r | GUARDED by fallback \|\|RARITY[0] |
| 44 | campaign3d.js:57 | BOONS[b.id]&&BOONS[b.id].n | RUN.boons[].id | GUARDED by truthy BOONS[b.id]&& |

ADMIRALS

| # | File:line | Exact dereference quoted | Save origin | Status / guard |
|---|---|---|---|---|
| 45 | core.js:136 | ADMIRALS[RUN.admiral] | RUN.admiral | GUARDED by if(ADMIRALS[RUN.admiral]) |
| 46 | campaign_meta.js:196 | ADMIRALS[RUN.admiral].n | RUN.admiral | UNGUARDED |
| 47 | campaign_meta.js:201 | ADMIRALS[RUN.admiral]?ADMIRALS[RUN.admiral].n | RUN.admiral | GUARDED by truthy ADMIRALS[RUN.admiral]? |
| 48 | campaign_run.js:60 | ADMIRALS[RUN.admiral].n / .doc | RUN.admiral | UNGUARDED |
| 49 | battle.js:316 | ADMIRALS[RUN.admiral]&&ADMIRALS[RUN.admiral].cmd | RUN.admiral | GUARDED by truthy ADMIRALS[RUN.admiral]&& |
| 50 | battle.js:844 | ADMIRALS[id] | RUN.admiral | GUARDED by (a&&a.cmd)\|\|COMMANDS[id]\|\|COMMANDS.vex |

FACTIONS

| # | File:line | Exact dereference quoted | Save origin | Status / guard |
|---|---|---|---|---|
| 51 | core.js:262 | FACTIONS[fac].roster.filter | META.opts.lastFac via saved faction pick | UNGUARDED |
| 52 | campaign_meta.js:104 | const F=FACTIONS[RUN.map.fac]; | RUN.map.fac | UNGUARDED |
| 53 | campaign_meta.js:105 | esc(F.n) / esc(F.blurb) | RUN.map.fac | UNGUARDED |
| 54 | campaign_meta.js:199 | FACTIONS[f].n | META.stats.wonFacs[] | UNGUARDED |
| 55 | campaign_meta.js:201 | FACTIONS[RUN.fac]?FACTIONS[RUN.fac].n | RUN.fac | GUARDED by truthy FACTIONS[RUN.fac]? |
| 56 | campaign_run.js:27 | F=FACTIONS[m.fac] | RUN.map.fac | UNGUARDED |
| 57 | campaign_run.js:51 | esc(F.n) / esc(F.blurb) | RUN.map.fac | UNGUARDED |
| 58 | campaign_run.js:315 | FACTIONS[RUN.map.fac] | RUN.map.fac | UNGUARDED |
| 59 | campaign_run.js:317 | esc(F.n) / esc(F.blurb) | RUN.map.fac | UNGUARDED |
| 60 | campaign3d.js:31 | FACTIONS[RUN.foes[3]].n / FACTIONS[RUN.foes[4]].n | RUN.foes[] | UNGUARDED (only length guard) |
| 61 | campaign3d.js:56 | FACTIONS[cfg.fac].n | cfg.fac from saved map/foes | UNGUARDED |
| 62 | battle.js:130 | const F=FACTIONS[fac]; if(!F\|\|... | cfg.fac / run faction | GUARDED by if(!F\|\|...) |
| 63 | battle.js:133 | const F=FACTIONS[fac]; | cfg.fac | UNGUARDED |
| 64 | battle.js:321 | FACTIONS[cfg.fac].roster | cfg.fac | UNGUARDED |
| 65 | battle.js:341 | const F=FACTIONS[cfg.fac]; | cfg.fac | UNGUARDED |
| 66 | battle.js:912 | FACTIONS[u.fac]&&FACTIONS[u.fac].sq | u.fac | GUARDED by truthy FACTIONS[u.fac]&& |

ASPECTS

| # | File:line | Exact dereference quoted | Save origin | Status / guard |
|---|---|---|---|---|
| 67 | core.js:165 | ASPECTS[RUN.aspect]?[ASPECTS[RUN.aspect].fx]:[] | RUN.aspect | GUARDED by truthy ASPECTS[RUN.aspect]? |
| 68 | campaign_run.js:64 | ASPECTS[RUN.aspect]? | RUN.aspect | GUARDED by truthy ASPECTS[RUN.aspect]? |

LEGACY / HULL_VARIANTS

| # | File:line | Exact dereference quoted | Save origin | Status / guard |
|---|---|---|---|---|
| 69 | campaign_meta.js:136 | const u=LEGACY[id]; | UI data-arg, not directly from save | OUT OF SCOPE / not save-origin |
| 70 | campaign_run.js:150 | const t=HULLS[h] | saved stock hull, may be a variant hull id | UNGUARDED; variant ids enter through HULLS, not HULL_VARIANTS directly |

No direct save-origin dereference of HULL_VARIANTS[...] by a saved id was found; variant ids in saves appear to enter through HULLS[stock.hulls[]].

Additional saved map/node content tables

| # | File:line | Exact dereference quoted | Save origin | Status / guard |
|---|---|---|---|---|
| 71 | campaign_run.js:39 | NODE_INFO[n.type].n | RUN.map.cols[].type | UNGUARDED |
| 72 | campaign_run.js:40 | NODE_INFO[n.type].n | RUN.map.cols[].type | UNGUARDED |
| 73 | campaign_run.js:40 | NODE_INFO[n.type].d | RUN.map.cols[].type | UNGUARDED |
| 74 | campaign_run.js:43 | ENCOUNTERS[n.enc].n | RUN.map.cols[].enc | GUARDED by n.enc&&ENCOUNTERS[n.enc] |
| 75 | campaign_run.js:55 | SHAPES[n.shape].toLowerCase() | RUN.map.cols[].shape | UNGUARDED (only n.shape&&n.shape!=='open') |
| 76 | campaign_run.js:50 | REGIONS[m.region]? | RUN.map.region | GUARDED by truthy REGIONS[m.region]? |
| 77 | campaign_run.js:32 | pickRegion(m.fac) | RUN.map.fac | GUARDED inside pickRegion by FAC_REGION[fac]\|\|... |
| 78 | battle.js:288 | ENCOUNTERS[cfg.obj]?cfg.obj:'rout' | saved node enc via cfg.obj | GUARDED by truthy ENCOUNTERS[cfg.obj]? |
| 79 | battle.js:289 | SHAPES[cfg.shape]?cfg.shape:'open' | saved node shape via cfg.shape | GUARDED by truthy SHAPES[cfg.shape]? |
| 80 | campaign_meta.js:98 | HEAT[k].n | RUN.heat[] | UNGUARDED |
| 81 | core.js:259 | (HEAT[k]&&HEAT[k].w) | RUN.heat[] | GUARDED by truthy HEAT[k]&& |
| 82 | campaign_run.js:18 | PATRONS[rw.p] | saved node rw.p | GUARDED by truthy PATRONS[rw.p] |
| 83 | campaign_run.js:20 | const P=PATRONS[rw.p]; | saved node rw.p | GUARDED by preceding truthy check |
| 84 | campaign_run.js:251 | PATRONS[rw.p]? | saved node rw.p | GUARDED by truthy PATRONS[rw.p]? |
| 85 | campaign_run.js:66 | PATRONS[p].col | RUN.patrons[] | UNGUARDED |
| 86 | campaign_meta.js:98 | PATRONS[BOONS[RUN.giftBoon].p].n | RUN.giftBoon | UNGUARDED |
| 87 | campaign_meta.js:99 | PATRONS[p].col / PATRONS[p].n / PATRONS[p].theme | RUN.patrons[] | UNGUARDED |

Deliverable 2: Findings, most severe first

1. OBSERVED: Unknown fleet hull tpl crashes the core derive/makeUnit path immediately
core.js:164: const t=HULLS[ship.tpl];
battle.js:97: const t=HULLS[tpl];
RUN.fleet[].tpl is persisted. saneRun only checks that fleet is an array; normalizeRun does not validate tpl. Any removed or renamed hull id reaches t.hp, t.sh, t.fac, etc. This is the most direct "load save, crash" path.

2. OBSERVED: Unknown module id crashes modName, fleet screens and shipyard stock
core.js:190: MODULES[m].n
campaign_run.js:93: MODULES[m].d
campaign_run.js:109: MODULES[m].only
campaign_run.js:153: MODULES[m].cost
RUN.inventory[], RUN.fleet[].mods[], and persisted n.stock.mods[] are not id-validated. derive guards MODULES[m]?MODULES[m].fx, but UI/name/cost paths do not.

3. OBSERVED: Unknown relic id crashes relicName and relic UI
core.js:191: RELICS[r].n
campaign_run.js:46: RELICS[r].d
RUN.relics[] is persisted. fleetFxList and runFx use guarded RELICS[r]?RELICS[r]..., but relicName and the relic panel dereference directly.

4. OBSERVED: Unknown perk id crashes ship cards and promotion UI
campaign_run.js:102: PERKS[p].d / PERKS[p].n
campaign_run.js:130: PERKS[p].n / PERKS[p].d
RUN.fleet[].cap.perks[] and persisted cap.offer[] are not validated. derive guards PERKS[p]?PERKS[p].fx; the fleet/promotion screens do not.

5. OBSERVED: Boon rarity r is indexed without bounds guard; saved giftBoon is dereferenced without existence guard
core.js:136: RARITY[b.r||0].m
campaign_run.js:22: R=RARITY[b.r||0]
campaign_meta.js:98: BOONS[RUN.giftBoon].p / BOONS[RUN.giftBoon].n
RUN.boons[].id is often guarded, but b.r is not; an out-of-range rarity crashes. RUN.giftBoon is only truthy-checked, not validated against BOONS.

6. OBSERVED: Unknown patron id crashes map/aspect UI
campaign_run.js:66: PATRONS[p].col
campaign_meta.js:99: PATRONS[p].col / PATRONS[p].n / PATRONS[p].theme
RUN.patrons[] is persisted. Node reward display has some guards; the run patron list does not.

7. OBSERVED: Unknown faction id crashes map, battle setup and post-boss screens
campaign_run.js:27: F=FACTIONS[m.fac]
battle.js:133: const F=FACTIONS[fac];
battle.js:341: const F=FACTIONS[cfg.fac];
campaign3d.js:56: FACTIONS[cfg.fac].n
RUN.map.fac, RUN.foes[], and cfg.fac are persisted or derived without FACTIONS existence checks in these paths. Several later lines then use F.n, F.blurb, F.roster, etc.

8. OBSERVED: Unknown admiral id crashes map/end-run UI
campaign_run.js:60: ADMIRALS[RUN.admiral].n / .doc
campaign_meta.js:196: ADMIRALS[RUN.admiral].n
RUN.admiral is persisted. fleetFxList and battle adaptation guard ADMIRALS[RUN.admiral], but the map sidebar and recap do not.

9. OBSERVED: The validation layer is structural only; it cannot catch deleted content ids
core.js:70: return r==null||!!r.none||(typeof r==='object'&&Array.isArray(r.fleet)&&!!r.map&&Array.isArray(r.map.cols));
core.js:63: for(const k in d) if(r[k]==null) r[k]=d[k];
core.js:98: if(!saneSave(d)){ console.warn('Cloud save malformed; keeping this device's save');
core.js:104: if(takeRun){ SAVED_RUN = migrateRun((d.run && !d.run.none) ? d.run : null);
saneSave checks only top-level shape; saneRun checks fleet array and map.cols array; normalizeRun fills defaults and coerces arrays but never checks tpl, mods, perks, relics, boons, admiral, aspect, fac, patrons, heat, or node stock. Cloud merge chooses newer run/meta by timestamps and then trusts migrateRun; no content-id revalidation occurs.

10. OBSERVED: Persisted map/node ids reach unguarded ancillary tables (NODE_INFO, SHAPES, stock hulls)
campaign_run.js:39: NODE_INFO[n.type].n
campaign_run.js:55: SHAPES[n.shape].toLowerCase()
campaign_run.js:150: const t=HULLS[h]
RUN.map.cols[] and persisted n.stock are saved with the run. Node type/shape and stock hull ids are not validated by saneRun/normalizeRun; these UI paths dereference before any fallback.

Not checked
- Numeric balance, combat formulas, AI scoring correctness, rendering/animation/fx modules, CSS/layout, audio, telemetry payload semantics beyond id indexing.
- Any cloud database implementation or server-side schema for window.claude.use('db'); the pack only shows client calls.
- Any external save editor, browser storage internals, or manual tampering behaviour.
- Full data.js content balance and every non-save runtime use of content tables.

Questions this pack cannot answer
- What does the cloud database store server-side, and does it validate schema there? The pack shows only client calls.
- Can a save be edited externally (localStorage, exported JSON), and is any of it authenticated?
- Are content ids ever intentionally removed or renamed between builds, and is there a migration or remap table outside this pack?
- Which content ids existed in older builds whose saves are still in the wild?
- Is SAVED_RUN ever assigned without passing through migrateRun?
- Are unknown ids meant to be skipped via unknownId everywhere, with the unguarded paths simply missed, or is the guard pattern intentionally partial?
- What happens when localStorage is full or a backup JSON.parse yields a structurally valid but semantically dead save?
