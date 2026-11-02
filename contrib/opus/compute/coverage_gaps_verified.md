# Coverage gaps verified against the supplied code

Report only. No game files changed. No commit made.

## Scope and limits

CODEX_TASK.md says eleven gaps; coverage_triage.md actually has thirteen bullets in its Gaps section. This report checks all thirteen, in their existing order. A CONFIRMED verdict can mean a missing feature or verification safeguard, not necessarily a combat bug. Mixed bullets are split below rather than treating every older allegation as true.

The required docs/REVIEW_PROTOCOL.md, docs/ship_pipeline/TEXTURE_PASS.md and docs/ship_pipeline/AUDIT_BRIEF.md are absent from this folder. They could not be followed or reconstructed. All reads and writes stayed inside this folder. Only this report was written.

Method: current browser sources, native rules and campaign, title and campaign UI, battle scene, audio code, music manifest, export preset, and the named review claims. Additional render/world files were read to check the copied constants. Small in-memory Node probes exercised the current browser turn-start functions with presentation and unrelated campaign helpers stubbed; these are focused rule checks, not a full battle or Godot execution. In-memory Python comparisons checked hull mappings, lengths and shared colors. No Godot executable was found on PATH. This snapshot has no music Ogg files, so listening, mix capture, a shipping launch and minimum hardware measurement were not performed. No screenshot is applicable to this report-only source audit.

## Verdict table

| # | Gap | Verdict | Current result |
| --- | --- | --- | --- |
| 1 | Turn-boundary state | CONFIRMED, mixed | Shield-disable expiry treats regeneration paths differently; risen ships cannot brace. Movement counter reuse and damage-after-death allegations do not establish additional bugs. |
| 2 | Native save fixtures and copied constants | CONFIRMED, partial | Basic native persistence tests exist, but no native saved-run fixture suite or copied-render-constant comparison guard was found. Shared hull mappings, lengths and colors match now. World presentation has since changed deliberately. |
| 3 | Music credits surface | CONFIRMED | Eight CC BY records exist; no in-game credits surface reads them. |
| 4 | Godot mix, salvos, dispatch and destruction | CONFIRMED, mixed | Dense-cue defer dropping survives; zero volume uses a nonzero gain floor. Reverb routes through Master, dispatch uses events, and destruction layers exist. Listening remains unverified. |
| 5 | Title menu FOCUS_NONE | ALREADY FIXED | Buttons use FOCUS_ALL, initial focus is assigned, and focus has a visible style. |
| 6 | Table-reader scan outside rules | CONFIRMED | The generator's required-reader scan is still rules-only; terrain and wing readers are in the battle scene. No current missing table was found. |
| 7 | Hunt Command card mismatch | ALREADY FIXED | Both live frontends use shared Command descriptions, which include reloads for all hunt users. Old inconsistent raw descriptions remain but do not drive these cards. |
| 8 | Ion pulse against shieldless fleets | CONFIRMED | Ability eligibility accepts nearby shieldless capitals; its effect only halves shield values. |
| 9 | Non-rename text accuracy fixes | CONFIRMED, mixed | Hunt/iron Command descriptions are fixed on the live cards; launch wording and several weapon trait descriptions still need correction. |
| 10 | Browsable reference codex | CONFIRMED | The pack remains a proposal; no title/fleet codex route or entry loader was found. This is missing functionality, not a broken existing screen. |
| 11 | Tutorial clock and retreat gloat copy | NOT A PROBLEM in current game | Both offending strings are in review drafts, not current live text. Correct the drafts before adoption. |
| 12 | Boarding, brace, adaptation cues; Corsair track | CONFIRMED, partial | No distinct cue definitions or battle dispatch calls were found for these actions. The Corsair track is absent here, so its sound and size cannot be judged. |
| 13 | Shipping checklist | CONFIRMED, partial | The checklist exists; copyright is still empty and resource modification is disabled. Exact depot contents, final launch and low-end requirements cannot be certified from this source snapshot. |

## 1. Turn-boundary state: concrete cases checked

### Movement across a side boundary: NOT A PROBLEM established

battle.js:389 resets hexMoved at the moving ship's own side start; battle.js:456 accumulates its movement; battle.js:637 uses it for incoming movement evasion and battle.js:638 for the attacker's moving broadside bonus. Native counterparts are godot/rules/rules.gd:1414, :1542, :2203 and :2209. The opposing side's start does not reset this ship's count.

Cases checked: a ship that moved three hexes retains that movement while the opponent acts; at its own next turn start its movement count becomes zero and its prior broadside movement bonus disappears; moving again accumulates new movement for the current attack. The focused probe returned an evasion modifier of -10 and rake 0.15 before the reset, then stationary modifier 8 and rake 0 after reset, using fixed probe movement-rule values. This demonstrates the counter timing, not faction balance. No evidence here requires separate old-turn and current-turn counters: each consumer reads movement since this ship's most recent turn start. Reaction-fire design during the ship's own movement is a separate specification question, not a proven error in this reuse.

### Final disabled-shield turn: CONFIRMED inconsistency

battle.js:384 decrements shieldOff and skips ordinary regeneration when its starting value is 1. It immediately calls ithChargeTurn at :385, whose guard at :506 sees the new zero. Storm Mantle/Eye of the Storm regeneration at :389 also sees zero. Native rules repeat this at godot/rules/rules.gd:1397, :1402 and :1415; ithChargeTurn is at :1642.

Concrete probes: starting with shieldOff=1 and four empty 100-point facings, ordinary regen=10 and stormRegen=0.18 gives [18,18,18,18], not ordinary regeneration. An Ithar ship with the same disabled counter and no recorded facing hits instead refills to [100,100,100,100]. With a counter above 1 the special guards still block. Thus the last disabled boundary has different rules depending on the regeneration source.

Smallest fix if disable is meant to block the entire boundary: capture the pre-decrement disabled flag and use it consistently for normal, Ithar and storm regeneration. If regeneration is meant to resume immediately on expiry, decrement first for all three paths instead. Which expiry contract Ryan intends is not settled by this code; do not silently pick one. Also keep regenLock behavior explicit: normal and Ithar paths honor facing locks, while stormRegen does not (battle.js:384, :506 versus :389). The code does not settle whether a legendary refill is meant to override that lock.

### Acid death followed by fire or gravity: NOT A PROBLEM

battle.js:387 queues acid death immediately; killUnit sets the dead state before awaiting its presentation (battle.js:938). The subsequent fire block explicitly checks !u.dead at :388; wellTick rejects dead ships at :286. Native equivalents: godot/rules/rules.gd:1407, :1408, :1435, :2721 and :962. A probe with 4 HP, acid=1 and fire=1 ended at 0 HP/dead with fire still at 1: fire did not apply after the acid death. Independently, already-dead ships are skipped at the top of both turn loops. Some harmless field resets and shield processing still occur later in the same loop body; that is not additional hull damage or a second death.

### Reassembled ship trying to brace: CONFIRMED restriction

The documented reassembly penalty is inability to fire (battle.js:524). To impose it, battle.js:397 marks every risen ship weapon fired=true. canOrder('brace') at battle.js:1041 rejects any fired non-flak weapon. Native equivalents: godot/rules/rules.gd:1430 and :3043. The probe confirmed fired=[true] and canOrder('brace')=false for an otherwise eligible risen ship with a battery. Ships with only flak do not fail this particular weapon test.

This conflates actual firing with a no-fire penalty, removing a defensive choice from a ship that has not fired. Smallest local fix: allow the current-turn risen marker to bypass this brace rejection while retaining the weapon no-fire flags. A cleaner fix is a separate no-fire flag checked by firing, leaving actual-fired state for brace. If resurrection is intended to forbid brace too, state that explicitly in its rule text; that broader restriction is not established by the current explanation.

## 2. Native saves and render/world constants

CONFIRMED as a remaining verification gap, with important qualifications. godot/campaign/test/save_test.gd:10 exercises a native save path, writes three profile values, checks the previous backup, corrupts the primary file and verifies recovery. This is real coverage, not an absence of all native save testing. It does not provide fixed native saved-run fixtures covering ships, captain progression, inventories, Nemesis, continued run state or supported version handling. The native envelope is emitted in godot/campaign/campaign.gd:378; loading and recovery are at :406 and :424. Smallest addition: native v1 fixtures through load_save_text/save_text with representative run and profile content, plus corrupt primary/backup and unsupported-envelope cases. No browser importer is requested.

Comparisons performed:

| Constant family | Current comparison |
| --- | --- |
| AI_HULLS | All 36 key/value pairs match ships3d.js:704 and godot/render/hull_table.gd:8. |
| CLS_LEN | All 13 class lengths match ships3d.js:89 and godot/render/hull_table.gd:27. Godot's SHIP_K=1.6 is a separately documented display scale, not a copied-length mismatch. |
| FAC3D | All 30 shared win/eng/bolt/beam/shield RGB triples match ships3d.js:2 and godot/render/hull_table.gd:37. Browser-only hull/dark/trim/tip fields are not identical schemas. Native effects also use the newer faction look data. |
| FINISH | Six hull colors and metal/roughness pairs in godot/render/hull_table.gd:31 match browser FAC3D hull colors and the material maps at ships3d.js:954. |
| ROCKS | There is no like-named current ROCKS table. The relevant ROCK_SET and ROCK_TINT mappings match scene3d.js:445-446 and godot/render/hull_table.gd:47-48. The current world also has its own generated rock renderer, godot/world/world_rocks.gd. |
| BIOMES | Browser scene3d.js:241 is no longer an equality contract for native sky colors. godot/world/world_sky.gd:85 reads the approved native faction palettes in godot/fx/faction_looks.json. Native REGION_OF at world_sky.gd:21 retains the same region rock/planet-index associations as battle.js:49. |
| PLANETS | These are different presentation schemas. Browser gfx3d.js:286 has eight looks; native world_sky.gd:43 has eight newly specified backdrop planets, render/board.gd:18 has five board looks, and ui/campaign/map3d_system.gd:31 has seven decorative map looks. Numeric kind ids are renderer-specific. Their inequality alone is not a bug. The current world.gd:2 describes the world rebuild explicitly. |

No automated comparison guard for the surviving copied hull/finish mappings was found. Smallest fix: compare the shared fields above in a read-only check and document the native-only presentation exceptions. Do not overwrite the newer world palettes to make an obsolete blanket equality assertion pass.

## 3. Music attributions

CONFIRMED briefly: godot/music/music.json contains eight CC BY track credit records. godot/music/CREDITS.md:9 explicitly says credit.attribution is stored for a credits screen. godot/main/title.gd:87-99 builds the actual menu without Credits; the current main, UI and scene scripts have no attribution renderer or credits route. Smallest fix: an accessible Credits button and scrollable presentation of the manifest attribution strings. This finding is about missing presentation, not a new licence judgment.

## 4. Native audio verification

- Reverb bypass: ALREADY FIXED by architecture. godot/audio/sfx.gd:66 creates category buses sending to Master and places reverb on those buses. The music bus also sends to Master (godot/music/music_player.gd:75). No downstream reverb bypass was found.
- Exact master zero: CONFIRMED source-level residual. sfx.gd:97 converts max(g,1e-5) to dB and adds 2 dB, so vol=0 gives -98 dB rather than a muted bus. set_on(false) uses the same floor. This does not prove audible leakage at ordinary playback levels. Smallest fix: mute Master when off/zero and restore it when enabled. Music already explicitly mutes its own bus at music_player.gd:110. The title Volume setting reaches battle SFX via godot/main/main.gd:208, while music also has its separate setting.
- Dense salvos: CONFIRMED. sfx.gd:154 returns when the stagger exceeds defer. cues.json gun_sq has gap=.05/defer=.08 and gun_shell .045/.14. Simultaneous repeated calls can therefore drop after only a few accepted starts; exact counts depend on random stagger and scheduling. The gain thinning and voice limits are separate mechanisms. Smallest fix: coalesce same-frame repeated gun reports or replace the short defer cutoff for salvo cues with an explicit bounded policy. Listening is still required to pick the result.
- Event dispatch: ALREADY FIXED for the examined paths. battle.gd:1141 matches e['t']; round/launch/torpedo/order/ram/board/command branches are semantic events, not caption matching. Turn sounds also have explicit player dispatch at :2903. Renaming a caption does not select a different cue here.
- Destruction layers: ALREADY PRESENT. sfx.gd:289 chooses boom size and adds bass_drop for size>=1.1 and delayed wreck for size>=1.0. battle.gd:1886 passes 1.2 for big ships, so their intended layers are reachable. Individual layers can still be rate/voice limited. No listening or peak-level certification is possible without the audio assets and a running engine.

## 5. Title focus

ALREADY FIXED. godot/main/title.gd:121 uses Control.FOCUS_ALL; :100 assigns initial menu focus; :140 adds a focus outline. Settings call _focus_first and return focus to the menu. This refutes the specific old FOCUS_NONE claim. It is not a claim that every controller mapping has been tested on hardware.

## 6. Reader scan

CONFIRMED safeguard gap. godot/rules/test/node/export_data.js:36-42 scans only top-level .gd files in godot/rules, matching TB access. It misses scene TBL access. The live scene reads TERRAIN_INFO at godot/scenes/battle/battle.gd:3090 and :3100 and WING_PERKS at :3777. Both tables are still exported, so no present terrain legend or perk-text removal is alleged. The stale claim that these UI tables are not carried remains in godot/rules/test/README.md:22.

Smallest fix: recursively scan runtime Godot consumers, following the rules-table aliases including scene TBL, before making pruning decisions; include both names in the required-reader guard and correct the README. Exclude test/oracle definitions from evidence of runtime consumers. FAC_PRICE is outside this finding.

## 7. Hunt Command cards

ALREADY FIXED in the visible flow. Raw ADMIRALS descriptions still differ (data.js:217 Vorn and :233 anuket/Ostrel omit reloads; Malek and Sable include them). However, browser selection at campaign_meta.js:69 and :94 uses cmdDesc, not those raw descriptions. battle.js:1084 always includes reloads for hunt; :1106 reloads torpedoes for all hunt users without checking admiral identity.

Native selection uses _cmd_text at godot/ui/campaign/campaign_ui.gd:358 and :393, reading C.CMD_TEXT. The current campaign_tables.json CMD_TEXT.hunt has the reload clause for all six factions. Native combat agrees at godot/rules/rules.gd:3081 and :3173. Cleaning the raw descriptions would reduce future confusion but is not needed to fix these current cards.

## 8. Ion pulse

CONFIRMED briefly in both versions. battle.js:1174 allows any nearby enemy capital within four hexes, including Chorus and Eclipse shieldless hulls. :1195 only halves shields and still spends the ability. Native canAbility at godot/rules/rules.gd:3405 and effect at :3478 repeat this. Smallest fix: require at least one eligible target with a positive current shield total, rather than just shMax, so an already depleted shielded fleet also cannot waste the action. New shieldless damage would be a design change, not this minimal fix.

## 9. Non-rename accuracy text

CONFIRMED remaining copy work, not blanket adoption of the old pack.

- Hunt and iron: ALREADY FIXED on the examined cards. battle.js:1084 and :1086 describe reloads and the shieldless iron reduction of 50%; :1097 implements the extra shieldless reduction. Native cmdDesc/cmdTaken at rules.gd:3081, :3083 and :3121 agree. Current CMD_TEXT.iron also has 50% with no shield-refill promise for Chorus/Eclipse.
- Launch family: CONFIRMED. data.js:136 says carriers start with wings and replace them, although data.js:76-77 gives Hegemony cruiser/battleship launch and hangars. MODULES.hangar and raw scramble descriptions use the same loose carrier wording, and campaign_meta.js:170 still teaches 'Carriers' and 'carrier's launch'. Native cmdDesc scramble also uses carrier wording (rules.gd:3076-3082); native launch targeting toast says carrier at battle.gd:3244. Smallest fix: use 'ships with launch bays' or 'launch ships' consistently where the mechanic gates on launch/hangar rather than class.
- Weapon numbers: CONFIRMED. data.js:44 hides las falloff halving/+4 aim; :45 hides the standard fire values; :47 hides scrap +1 shot/-12 aim/+3 crit; :51 hides needle +6 aim/+8 crit. Acid and spines already state useful numbers. Native battle.gd:3702 reads WTRAITS text from its tables, so correcting browser strings alone is insufficient without regenerating the native data.
- Contradictory traits: data.js:48 rockets says hard to dodge but evMult=1.5; :52 star says hard to dodge with evMult=1.2, which increases the target evasion contribution in the hit calculation. Smallest copy-only fix is to state the actual multiplier and remove the hard-to-dodge claim. Changing those numbers is a balance decision. Do not copy old pack numbers over current rules without checking them.

## 10. Reference codex

CONFIRMED feature gap. contrib/muse/reviews/codex_pack_2026_10_30.md:3 identifies a draft and its 191-entry JSON companion. No runtime script loads that companion or offers its categories from the title/fleet UI. Current alternatives are title How to play (godot/main/title.gd:94) and the native help page (godot/ui/campaign/campaign_ui.gd:1047), plus contextual ship details. These do not implement a browsable reference collection.

Smallest implementation: a title/fleet reference route, category list and entry view, after validating old pack ids and values against current tables. Missing codex is an outstanding proposal, not proof that combat or an existing help screen crashes.

## 11. Clock tip and retreat gloat

NOT A PROBLEM in the current live game for these two exact allegations. The 'meeting is not optional' tip is at contrib/muse/reviews/tutorial_assembled_2026_10_29.md:10. The reversed spacecraft orientation line is at contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:39. Searching current browser sources, native runtime and native data did not find either phrase or the draft c_clock tip wired in.

Live NEM_LINES.gloat.retreat instead says 'You ran from me last time. Run again.' (data.js:494). campaign_run.js:316 assigns that gloat after the player's retreat, so speaker and target agree. Negative clock event choices exist in current data, including haven tribute at data.js:416. The drafts still need correction before use: explain that some events delay the meeting; replace the orientation line with 'You turned away from me.' No live game edit is justified by these exact draft-only strings.

## 12. Distinct action cues and the Corsair file

CONFIRMED missing distinct cues, with an unavailable listening check. godot/audio/cues.json has no board/boarding, brace or adaptation cue keys. The order branch at battle.gd:1291 displays Brace without an action cue; the board branch at :1308 logs and flashes without a sound call. Nemesis adaptation is reported at battle setup in rules.gd:1252, but no dedicated adaptation cue or dispatch was found. Generic UI confirmation is not a distinct action cue and does not cover enemy actions by itself.

Smallest fix: define three cue ids and dispatch them from order=brace, board and an explicit adaptation event. Avoid adding caption-dependent matching. Audition them in context before choosing sounds.

godot/music/music.json:331 defines fac_corsair and its source credit, but godot/music/tracks/fac_corsair.ogg is absent in this folder, along with all other music Oggs. Its older reported small size cannot establish bad content, and no listening verdict is possible here. Recover the actual selected file and compare duration/listen before deciding whether to replace it.

## 13. Shipping checklist

CONFIRMED remaining release verification, not a proven current build-launch failure. The checklist is already retained at contrib/muse/reviews/steam_readiness_2026_10_27.md:54-71. The current preset godot/export_presets.cfg uses embed_pck=false, so a candidate must ship its matching PCK as well as its executable. file_version/product_version remain 0.9.0.0; copyright remains empty; application/modify_resources=false means configured resource strings must not be assumed to have been stamped into the executable. See godot/export_presets.cfg:32, :36 and :41.

Smallest concrete configuration fix: decide the release version/copyright, enable resource modification if these executable metadata fields are intended, and inspect the actual exported EXE resources. Smallest verification completion: record the candidate export's exact file inventory, install that inventory in a clean location and launch it, then measure a representative low-end PC before making minimum-spec claims. This folder contains no export candidate or low-end results sufficient to close those checks. An RTX 5080 result cannot substitute for that measurement.

## Outstanding ambiguities

- Thirteen input bullets versus the task's eleven: all thirteen were covered.
- Missing mandatory review documents prevent claiming protocol compliance.
- Intended shield-disable expiry and whether resurrection should also forbid brace need a rule decision; the current observable inconsistencies/restriction are established above.
- New native world palettes and planet schemas are intentional presentation changes, so old blanket browser equality is not a valid acceptance rule.
- Listening, Corsair-file quality, exact depot contents, final exported launch and low-end requirements remain unverified with this snapshot.
