# Dead data audit: the 41 tables godot/rules does not read (Oct 27 program, item 11)

Pinned to commit 68b42ce406286eb95ea7df6aaf3f683c1231b51d of rcbailey12/voidsworn (HEAD of the fresh clone, verified). Rey lane: external point of view only. Every classification below is an observation for Opus to confirm, not a code claim of record and not an instruction.

## Premise

The G1 parity README (godot/rules/test/README.md, Data check) says, in its own words (short quote): "131 tables are exported and the port reads 90. The other 41 are read by nothing in godot/rules/". It then lists the 41 by name in three groups: JS-only battle UI text (4), battle.js encounter rolls owned by G3 (5), and campaign data (32).

Chair verification of the count: the claim reproduces exactly from the shipped file. godot/rules/data/tables.json holds 131 exported tables; its embedded required list (the tables the exporter found the port reading) holds 89; FNAMES is exported and read optionally (the port falls back to {}), which makes 90 read. 131 minus 90 is 41, and the derived unread set is name-for-name identical to the README list. The 41 figure is correct.

One premise correction matters, though: the README line is narrowly worded (nothing in godot/rules/) and that narrow claim holds for all 41. But two of the 41 are read elsewhere in the Godot app, from this same tables.json, by the G2 battle scene. They are not dead weight, and dropping them on the strength of the README list would break the battle scene's terrain legend and wing perk text. See READER FOUND below.

## Where the tables come from

godot/rules/data/tables.json is generated, never hand-edited: godot/rules/test/node/export_data.js evaluates the pinned oracle copies of data.js, core.js and battle.js (plus FNAMES from oracle/fnames.js) and exports every top-level const or let table holding plain data. There is no allowlist: anything plain-data at top level ships. The same is true on the campaign side: godot/campaign/test/node/export_campaign.js writes godot/campaign/data/campaign_tables.json (133 tables) from the same sources, and godot/campaign/campaign.gd plus the campaign UI scripts read from that file, not from the rules file. Story reads admiral and faction names, and RUN_FACTIONS, from the campaign file too (godot/story/story.gd line 50). So a table can be dead in tables.json while being live data for G3, and most of the 41 are exactly that.

## Method

For each of the 41 names: word-boundary grep across (1) godot/rules code (battle_api.gd, jsm.gd, rules.gd), (2) godot/rules/test excluding the oracle copies and this audit's premise README, (3) the campaign scripts (godot/campaign, godot/ui/campaign, godot/scenes/campaign), including campaign.gd's own REQUIRED_TABLES list, (4) godot/story code, (5) every other Godot script in the repo (this is the scope that caught the battle scene readers), and (6) the browser sources (root .js files and head.html), where a definition line does not count as a read. Follow-up context checks on every ambiguous hit (comment-only mentions, same-name GDScript constants, generator lists). The oracle copies under godot/rules/test/oracle are the generation source, so a name appearing there is a definition, not a read. The built bundle voidsworn-3d.html is generated from the same browser sources and was not counted as a reader. Sizes are the byte length of each table's value as serialized in tables.json, re-measured by the chair.

Classifications: READER FOUND (a reader of the rules tables exists outside godot/rules; premise wrong in effect), RULES-DEAD ONLY (no reader of the rules tables, but campaign, story or browser code reads the table from its own copy), TEST-ONLY (referenced only by tests or fixtures), DEAD EVERYWHERE (no reader anywhere; the definition is the only occurrence).

## Results at a glance

- READER FOUND: 2 (TERRAIN_INFO, WING_PERKS)
- RULES-DEAD ONLY: 34 (29 read by the Godot campaign and, for RUN_FACTIONS, also by story, all from campaign_tables.json; 5 read only by the browser game: CAP_FIRST, CAP_LAST, FAC_PRICE, SAVE_VERSION, STORE_KEY)
- TEST-ONLY: 0
- DEAD EVERYWHERE: 5 (FAC_RULES, CMD_HOLD, KIND_NAME, FIT_SLOTS, FAC_WPOOL)

## The full table

| Table | Classification | Evidence | Bytes in tables.json |
|---|---|---|---|
| TERRAIN_INFO | READER FOUND | godot/scenes/battle/battle.gd lines 2379 and 2389 read TBL.get("TERRAIN_INFO") through battle_api tables(); also read by the browser battle UI (ui3d.js, fx3d.js) | 644 |
| WING_PERKS | READER FOUND | godot/scenes/battle/battle.gd line 2895 reads TBL.get("WING_PERKS"); also in campaign.gd REQUIRED_TABLES and read by browser campaign_run.js | 412 |
| DEEP_MAPS | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser battle.js reads it (defined battle.js line 52) | 21 |
| ENC_POOL | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser battle.js and core.js read it | 71 |
| ENC_SPECIAL | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser core.js and sim3d.js read it (defined on battle.js line 67, same line as ENC_POOL; also named in export_data.js's hand list, which is generation, not a read) | 64 |
| FAC_REGION | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser battle.js reads it | 186 |
| REGIONS | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd reads; browser battle.js and campaign_run.js read it | 388 |
| ARCHETYPES | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd and map3d.gd read; browser campaign_run.js reads it | 719 |
| ARC_VARIANT | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser campaign_run.js reads it | 151 |
| BOON_NEED | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser core.js and sim3d.js read it | 367 |
| CAP_FIRST | RULES-DEAD ONLY | Browser only: defined data.js line 255, read at data.js line 520 (captain name assembly). The godot/story/tokens.gd hit is a comment (line 18), not a read. No Godot reader; the campaign uses CAPTAINS instead | 252 |
| CAP_LAST | RULES-DEAD ONLY | Browser only: defined data.js line 256, read at data.js line 520. No Godot reader | 265 |
| CLASS_TRACK_MAX | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd reads; browser campaign_run.js and core.js read it | 1 |
| EVENTS | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser data.js and campaign_run.js read it. The single biggest table of the 41 | 18727 |
| EVENT_FALLBACK | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser campaign_run.js reads it | 7 |
| FAC_PRICE | RULES-DEAD ONLY | Browser only: defined data.js line 538, applied at data.js line 546 (faction price multipliers). No Godot reader found, so the Godot campaign prices without it | 576 |
| FAVOUR_TIERS | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd reads; browser campaign_meta.js, campaign_run.js and core.js read it | 236 |
| HEAT | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd reads; browser campaign_meta.js and core.js read it. Also named once in godot/rules/test/node/sweep_gen.js (scenario field), which is test scaffolding on top of a live table | 584 |
| HULL_VARIANTS | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd reads; browser campaign_meta.js, campaign_run.js, data.js and sim3d.js read it. Matches the README note: variants reach battle merged into HULLS | 3609 |
| KILL_CAUSES | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser campaign_run.js and sim3d.js read it (defined battle.js line 925) | 265 |
| LEGACY | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser campaign3d.js, campaign_meta.js and main3d.js read it | 1301 |
| MASTERY_PERKS | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd reads; browser campaign_meta.js reads it | 335 |
| MASTERY_XP | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd reads; browser campaign_meta.js and core.js read it | 14 |
| MOD_NAMES | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser core.js reads it | 1907 |
| MOD_NEED | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser core.js reads it | 131 |
| NEM_CLOCK | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd reads; browser campaign_run.js reads it | 1 |
| NEM_TRAITS | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd and map3d.gd read; browser campaign_run.js reads it | 1022 |
| NODE_MODS | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd and map3d.gd read; browser campaign_run.js reads it | 215 |
| RANKS | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd reads; browser campaign_run.js, core.js and data.js read it | 64 |
| RELIC_NAMES | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser core.js reads it | 1636 |
| RUN_FACTIONS | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads, campaign_ui.gd reads; story.gd line 50 reads it from campaign_tables.json; browser campaign_meta.js, core.js and sim3d.js read it | 63 |
| RUN_WORD | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser core.js reads it | 121 |
| SAVE_VERSION | RULES-DEAD ONLY | Browser only: defined core.js line 49, read at core.js line 50 (defaultMeta). The campaign.gd hits are its own GDScript const SAVE_VERSION := 2 (line 197), a same-name constant, not a read of this table | 1 |
| SECTOR_POOL | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser core.js and sim3d.js read it | 85 |
| STORE_KEY | RULES-DEAD ONLY | Browser only: defined core.js line 48, read across core.js and campaign_meta.js (localStorage key). No Godot reader | 14 |
| WING_XP | RULES-DEAD ONLY | campaign.gd REQUIRED_TABLES plus TB reads; browser campaign_run.js reads it | 8 |
| FAC_RULES | DEAD EVERYWHERE | Defined at battle.js line 476 and never read: no hit in any Godot script, test, story file, or browser source beyond the definition. The README calls it faction rule text the port does not carry; the current browser sources do not read it either | 1193 |
| CMD_HOLD | DEAD EVERYWHERE | Defined at battle.js line 1088 (Command tooltip text) and never read anywhere; the built bundle holds only a copy of the same definition | 173 |
| KIND_NAME | DEAD EVERYWHERE | Defined at data.js line 30 and never read anywhere. Note the near-twin KIND_WORD is a different, live table read by the campaign | 128 |
| FIT_SLOTS | DEAD EVERYWHERE | Defined at data.js line 577 and never read anywhere | 178 |
| FAC_WPOOL | DEAD EVERYWHERE | Defined at data.js line 580 (a table computed from FACTIONS and HULLS at load) and never read anywhere | 348 |

## Byte cost

tables.json is 106,727 bytes on disk. The 41 unread-by-rules tables account for 36,483 bytes of serialized value, about 37,038 bytes (34.7 percent) once keys and punctuation are counted. That headline overstates the waste, because most of it is live data for someone else:

- READER FOUND (must stay): 1,056 bytes of value.
- RULES-DEAD ONLY (live for campaign, story or browser): 33,407 bytes of value, dominated by EVENTS at 18,727 bytes and HULL_VARIANTS at 3,609 bytes. Both are duplicated by design in campaign_tables.json, which is where their Godot readers actually read them.
- DEAD EVERYWHERE (waste in every build): 2,020 bytes of value, about 2.2 KB with keys. Small, but it is the only slice that is dead in the browser game too.

## Recommendation (proposal for Opus, not an order)

Split the 41 three ways rather than treating the README list as one drop set:

1. Fix the blind spot before dropping anything. The exporter's required scan reads only godot/rules/*.gd, which is why two live tables (TERRAIN_INFO, WING_PERKS) read by godot/scenes/battle/battle.gd through the API present as dead. Extend the scan in export_data.js to the TBL consumers outside godot/rules (today just the battle scene), or add an explicit optional list next to FNAMES for tables read outside the port. Until then, the "41 unread" count will keep naming live tables.
2. Drop the 5 DEAD EVERYWHERE tables at generation time, or delete them at the source. They are dead in the browser too, so the honest fix is removing FAC_RULES, CMD_HOLD, KIND_NAME, FIT_SLOTS and FAC_WPOOL from battle.js and data.js; if Opus wants the JS untouched for parity reasons, a skip list in export_data.js next to the existing STATE list gets the same file result. Either way it only saves about 2.2 KB; the value is hygiene, not size.
3. Keep the 34 RULES-DEAD ONLY tables in the export for now. The rules file is 107 KB total, the campaign and browser genuinely read this data from their own copies, and the re-pin regenerates both exports from the same sources anyway. A per-consumer split (rules export carries only what Godot reads) is the cleaner end state, but it should only happen after a reader scan that covers every consumer of tables.json, scenes included, which is exactly the scan fix in point 1. Done in the wrong order, the split silently deletes the terrain legend.

## Not checked

- The shipped Godot export itself (export_presets.cfg and any built binary) was not inspected; classifications rest on the source tree at the pinned commit.
- godot/story's data files (arcs.json, medals.json, rival_lines.json, titles.json, voices.json) were treated as authored content, not code readers; a table name appearing as content text there would not be a read of tables.json.
- contrib/ was out of scope, as were the oracle copies (generation source) and the stale built bundle voidsworn-3d.html (a generated artifact; it carries copies of the same definitions).
- Fully dynamic table access (a name built by string concatenation at runtime) would evade a word grep. The scan covered the TB.NAME, TB["NAME"], TB.get("NAME") and TBL.get("NAME") styles the codebase actually uses, and plain word search would still catch a quoted full name, but a split-string construction cannot be excluded by this method.
- Whether the Godot campaign's pricing should also apply FAC_PRICE (browser-only today) is a G3 parity question this audit only surfaces; no judgement made.
- The campaign parity test and sweep generator references were recorded where they occur, but test scaffolding never decided a classification on its own: no table came out TEST-ONLY, because every test-referenced candidate also has a campaign or browser reader.
