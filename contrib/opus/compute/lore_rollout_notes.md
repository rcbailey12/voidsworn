# Lore rollout notes (L)

Written by L, the lore rollout helper (R59). This file has three parts: what L delivered, the final sweep for retired display words with every leftover and its owner, and L's read of the Muse naming reviews (findings only; nothing from them has been applied).

## 1. What landed

| Commit | What |
|---|---|
| 0bf2d63 to 1695ea4 | `rename_map_final.md` written in five parts: 348 rows with file:line and owner, 18 vetoable calls. |
| f9ffd62, 762df28, 144dc71 | Opus veto of V14 (relic becomes salvage, section 5b). Salvage kept to one meaning (section 5c: Strip the wrecks, Scrap rig, Recovered refits, Spoils). Where cells re-grepped. |
| fcae7f6 | Section 16: Ryan's rulings of Oct 27 and 28 (Grax Ironmaw, the Eclipse blurb in energy words, three Eclipse Nemesis titles, Thornback and Moonveil swapped, Acceptable Loss swapped). |
| 1e65076 | `godot/story/data/voices.json`: 24 admirals and six enemy flagships in the round 8 voices. |
| b56269f | Story layer: six arcs rewritten (`outlines.md`), plus rival lines, titles, arc rewards and unlock names, the tokens.gd pronoun lists and the test fixtures. |
| 72b1535 | `outlines_variants.md` (B beats, skims, rival incidents), unlocks.md, README; review_incorporation.md marked as history. |

Story checks at fcae7f6: `story_test.gd` PASS (72 checks, 0 failed); `check_outlines.py` 36 cards, 0 fails; `check_personas.py` ok for all six factions. The one "ERROR: Parse JSON failed" line in the test log is expected: it comes from the check that a damaged career file falls back to the backup.

The arc titles are now The Oath at the Hollow Sun, Registry Order 41, Rook's Trail, Eat the Sun, The Last Lens and The Homecoming. Every flag id, hook, outcome key and data shape is unchanged.

## 2. Final sweep (Oct 31, main fcae7f6)

**Method.** Two passes over the game files: the browser JS and head.html, everything under godot/ (code, story, data, scenes, tests; not the oracle copies), and tools/portraits.
1. Every Old string in `rename_map_final.md` was grepped again. A row whose Old text is still present has not been applied.
2. String literals were scanned for the retired words in the brief: Voidsworn, Corsair(s), Ithar, Deathless, Dynasty, Las-, Hellfire, Gauss, Doom arc, Pulsar, Turbolaser, Hive Leviathan, Inquisitor, Overlord, Cryptlord, Grand Admiral, patron, boon, favour, sigil, relic, Ember Choir, Iron Saint, and the church words (saint, hymn, psalm, litany, censer, requiem, benediction, seraph, canticle, choir, martyr, sanctified, absolution, heaven, reliquary, tomb, blessed, pray, tithe).

Ids, save keys, CSS classes, action names, telemetry names and comments were classified and dropped, as the brief allows.

**Status by stream:**
- B landed its strings in 90aaf85.
- G2 landed in 239fdeb.
- Portraits landed in 257de44.
- **G1 and G3 had not landed their strings step at fcae7f6**, so their rows below are still open (pending, not missed).

### G3 (godot/ui/campaign, godot/campaign): 35 map rows open

- **`campaign_ui.gd`, the TERMS line (29).** It still maps every word to itself: patron, sigil, boon, favour, relic. Flipping it to core, signal, protocol, sync and salvage fixes all the `term(...)` text in one edit (map 2.x and 5b). Lines 575 and 662 also need the wording rows in map 10.2.
- **`campaign_ui.gd`, literal text.** Each line maps to a row in the map:
  - 303: tagline.
  - 437: Devoted.
  - 444: "Patrons watching this", and "Win battles marked with their sigil to earn their boons".
  - 584: "Boon of".
  - 939: "Patron favour".
  - 978: favour line.
  - 1010 to 1022: How to play. This covers "Voidsworn is a roguelite", the patrons-and-boons paragraphs, "without boons", "gauss weapons mostly ignore them" and "Relics are fleet-wide bonuses".
  - 1116, 1120: "Long-range auspex confirms" and "Auspex confirms".
  - 1127: sector intro patron/sigil/boons.
  - 1161: "No boon triggered...".
  - 1166, 1199: "Salvage the field".
  - 1167: "offers a boon".
  - 1211: "Salvaged refits".
- **`campaign.gd`:**
  - 1504: "a relic".
  - 1920: "The seer smiles".
  - 1924: "Relic gained:".
  - 1926: "No relics left".
  - 1952: "The saint answers".
  - 2075: "Salvage: +".
- **`map3d.gd`:**
  - 812: "count in its favour", and "relic 4" in the route tooltip. G3 has already moved the item word through `term("relic")`, so this follows the TERMS flip.
  - 817: the route counts.
- **Re-export.** `godot/campaign/data/campaign_tables.json` still carries the pre-rename data text, because it was exported before B's strings step. It follows by itself once G3 re-exports.

### G1 (godot/rules): 8 map rows open

- **`rules.gd`:**
  - 969: "torn apart by the dead star's gravity".
  - 1256: "on the auspex".
  - 1257: "A dead star warps this field".
  - 2733: "Reawakens", and "The phylactery hums ... reawakens at 25% hull".
  - 2736: "Reanimating".
  - 3477: " reanimates ".
  - 3530: "Nova blast hits".
- **Re-export.** `godot/rules/data/tables.json` still carries the old data text (236 retired-word hits). It follows by itself once G1 re-exports after 90aaf85.
- **Test notes.** `godot/rules/test/scenarios.json` has scenario notes that say "Corsair raiders", "dead-star" and similar. These are test labels, not player text; renaming them is optional.

### B (browser JS): 0 map rows open, 6 new rows from section 16, 2 notes

- **Section 16 (fcae7f6), not applied yet:**
  - data.js:221 Grax Steelgrin becomes Grax Ironmaw.
  - data.js:127 the Eclipse blurb, "stealing starlight", becomes energy wording.
  - data.js:464 plain "Nadir" is dropped from the Eclipse titles.
  - data.js:254 Acceptable Loss becomes Debt Paid.
  - ui3d.js:21 Thornback becomes Sour Spine.
  - ui3d.js:22 Moonveil becomes Still Glass.
- **Kept on purpose.** `data.js` `cls:'Battle-barge'` and the other three class keys stay, because they are lookup keys; they show through CLS_NAME (map 4.0).
- **Note: sound test labels.** `sfx.js:343-348` (SFX.TESTS) still says "gun: las (Voidsworn)", "Corsair rockets", "lance: Deathless", "Ithar star", "hit: glass (Ithar)". These are sound-test menu labels. If a player can open that menu, rename them to the new faction names.
- **Note: built page.** `voidsworn-3d.html` is a build and still has the old text. It needs a rebuild after the section 16 rows land.

### G2: nothing open

- Kept by the ids-never-change rule: the exe file name `Voidsworn.exe` (export_presets.cfg:12) and the save folder `app_userdata/Voidsworn` (project.godot:7-8).
- Note, owner unclear (music lane or G2): `godot/music/music.json` has "role" descriptions such as "Voidsworn flavour" and "Deathless flavour". They look like internal metadata; rename them if any screen shows them.

### Portraits (P): 1 row open, plus history

- The section 16 Ironmaw row: `make_batches.py:49`, `crests.py:28`, `phone_sheets.py:15` still say Grax Steelgrin.
- Batch history kept by map section 12: `make_batches.py` lines 14, 18, 43, 85-86, 107-109, 139-144, 158 and 178-183 (the old Ithar, Deathless and Voidsworn subject lines), and `tools/portraits/batches/*.json` (old generated batches). These must be renamed before any of those subjects is queued again.
- The words in `make_edits.py` 72, 84, 90 and 123 (censer, reliquary) are inside "remove this" instructions. They are correct as written.
- The C-7 worry from the rollout audit is closed: the template is now `'A Nemesis of %s' % DISP[_fac]` (make_batches.py:194, 206), so it no longer prints "of the the Chorus".

### L (godot/story): nothing open

- The only hits are history and ids. `review_incorporation.md` is marked as history. The outcome key `relic` appears in the README and fixture_arc.json, and the rules id `gauss` in career.gd's lance share; all three are ids.

### Outside the sweep scope, flagged so they are not forgotten

- A4's contact-sheet captions under docs/shots still say "turbolaser" and "Interdictor-class" (rollout audit E-6).
- The admiral crest sheet (crests_all.webp) still shows pre-rollout admiral names (rollout audit E-8). This is already tracked.
- The bible's 2.10 sample ship list still names Acceptable Loss (Opus's file).

## 3. Muse naming reviews: what L would change (not applied)

1. **`contrib/muse/reviews/story_pack_2026_10_30.md` claims to supersede `godot/story/outlines.md` and `outlines_variants.md` as the story source.** It was written against r8 and the map, and it adds debriefs, learning payoffs and admiral spotlights. L's Job 2 rewrite (b56269f, 72b1535) and this pack now overlap. There are two possible story sources, and nothing in FINDINGS rules which one wins. **This needs Opus's call** (and Ryan's, if it changes what he approved). L's suggestion: take the pack as the source if Opus accepts it, keep L's flag ids and outcome keys (which the arc engine and tests use), and have L merge the two in one pass rather than leaving both files live.
2. **`canonical_corrections_2026_10_31.md` has no naming content** (it covers the Chorus feed, the parity oracle, FAC_PRICE, damcon, and retired measurements). Nothing in the map needs to change.
3. **`naming_qa_synthesis_2026_10_29.md`** found no wrong reads from the naming layer. Its two residual risks still stand, and both are listed in section 2: the stale `voidsworn-3d.html`, and the old portrait batch history.
4. **`rollout_audit_2026_10_27.md`.** Ryan's rulings are folded in (section 16). Of the open NOTEs, L would act on two:
   - C-8 possessive apostrophes in item names (for example "Dead captain’s harness", "Warlord’s kill tally", "Founders’ compass"). Bible 1.4 rule 4 is about names a player must say. L would leave possessives in item names, but would rename "Founders’ salvage" (the legacy unlock) to "Founders' cache", so the item type word is not used inside an item name.
   - C-8 "The Archive" as the Eclipse logbook item and also as the place: rename the item to "Archive extract".
5. **`text_overhaul_pack_2026_10_30.md`.** Most of its 96 rows are wording and accuracy fixes outside the rename. On the naming rows:
   - T-01 to T-04: covered by section 16.
   - T-06 Salvage swarm: Ryan ruled keep, so the row is void.
   - T-07 "Eclipse backup frame" to "Backup frame": agree. The base relic name shows for every faction.
   - T-05 drops the name "Archive restore" from the Eclipse verb text: disagree. Keep the name, because the battle rule and the ship panel use it. A clearer form would be "Next battle, Archive restore brings back one more of your destroyed ships."
   - T-30 to T-60 ("His ships" to "Enemy ships"): agree. The Nemesis can be she or it.
   - The pack's "Lantern Gut" question: keep it. The bible's lantern ban is in the Crusade's list only (map 14).
