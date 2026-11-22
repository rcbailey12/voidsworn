# OpenAI technical review: issue 1575

**Hold PR 1552 for the battle HUD voice fix.** The arc keys and text-only refresh check out at the pin. Regular weapon hits still bypass the flagship reaction. The browser also has ship-name article drift, and two tests can pass without proving what they claim.

Target: `opus/wip-1551-keys` at `ff37445f`, against `origin/main` at `79fe8d6b` (merge base `66b983f5`). I used the pinned Git objects and scratch exports so the review did not depend on the runner branch's working files.

## 64a6d8e7: Arc usage keys

**OBSERVED: Sound.** `data.js:32` and `godot/rules/rules.gd:19` map `F/P/S/T/R` to `Prow/Port broadside/Starboard broadside/Turret (all arcs)/Rear`, exactly the pre-rename keys in `origin/main:data.js:30`. Both `fireWeapon` paths count player, non-squadron, non-intercept fire and still count called shots. The campaign broadside totals (`campaign_run.js:550`, `godot/campaign/campaign.gd:2924-2925`) and Godot Career (`godot/story/career.gd:371-382`) accept both `flank` and `broadside` spellings, including mixed records. The new display labels stay in `ARC_NAME`.

Godot round resumes have a separate, pre-existing version guard: `godot/rules/battle_api.gd:1100-1117` fingerprints the changed tables and rules and rejects a previous-build round snapshot; `godot/campaign/campaign.gd:1901-1905` falls back to the pre-fight checkpoint and tells the player. Old round snapshots therefore do not need a key migration, but a player updating in the middle of a fight will restart that fight from the checkpoint.

## 9bf8bb54: Ship articles

**OBSERVED: Defect in caller coverage.** The helpers and the reinforcement, pyrrhic, and reserve-captain lines agree for bare names, case variants of `The`, `MDV` and legacy `HNS` names. `shipBare` and `ship_bare` both remove one leading `the ` for `a fresh`. The helpers are read-only; they do not rewrite fleet names in saves. The browser's other matching UI lines still bypass the helper.

| Finding | Evidence | Why it matters | Fix |
|---|---|---|---|
| OBSERVED: Shipyard and reward text still drifts between twins (high confidence). | `campaign_run.js:260`: `The ${s.name} joins the fleet.`; `godot/campaign/campaign.gd:2155`: `ship_with_article(s["name"], true)` | Buying an `MDV` hull in the browser adds `The`; `The Unbroken` becomes `The The Unbroken`. Godot handles both. The browser also adds `The` for core regrowth, event rewards and towing (`campaign_run.js:222,582,597,774`) and uses no shared article rule for flag transfer (`:716`). | Use `shipWithArticle` in the matching browser lines, with sentence-start casing where needed. Apply `esc` after formatting the name for HTML. |

## 85fb4caf: Shipyard repair text test

**OBSERVED: Defect in the assertion.** The test builds real Godot shipyard labels for Crusade and Chorus and is wired into the Godot headless list. Its assertion can accept the wrong body text.

| Finding | Evidence | Why it matters | Fix |
|---|---|---|---|
| OBSERVED: The Crusade case accepts a currency prefix (high confidence). | `godot/campaign/test/shipyard_repair_text_test.gd:46`: `" credit"`; `:53`: `(cost + " per 2 hull").contains(c[1])` | `Repairs cost 1 credit tokens per 2 hull...` passes. The test also appends ` per 2 hull` before matching, so it does not prove the real label contains that unit. | Assert the actual prefix up through `per 2 hull` with a numeric price and the exact currency token; retain the exact new-captain suffix. |

The Godot test targets the Godot UI. The browser shipyard line at `campaign_run.js:244` still says `New hulls come with a fresh lieutenant.` for Chorus as well. Use the faction's first rank in that twin to match the label.

## c51aeeaf: Battle voice

**OBSERVED: Defect in scene integration.** `pflag` is the right player marker (`godot/rules/rules.gd:1282`). `setup_from_rules` resolves the name by `pflag`, then `RUN.flagUid`; live sync reads reinforcements, health, side and deaths. The `exit` guard matches both escape-zone event producers (`godot/rules/rules.gd:4076,4079`), and the admiral and situational emitters suppress empty fills. The story test drives `on_event` directly, so it misses the following real HUD path.

| Finding | Evidence | Why it matters | Fix |
|---|---|---|---|
| OBSERVED: Ordinary weapon hits bypass flagship-hurt voice (high confidence). | `godot/scenes/battle/battle.gd:1283`: `["hit", "system", "shield_down", "burning"]`; `:1287`: `await _play_fire(e, grp)`; `:1294-1295`: `i = j` then `continue`; `godot/story/battle_voice.gd:400`: `"hit":` | Hits grouped under a weapon fire never reach the voice hook at `battle.gd:1375`. Even a correctly marked flagship can fall below 40% without the admiral reacting. | Feed grouped weapon hits to the same voice hook in event order, once per hit. Add coverage through the scene's batch dispatch, not just direct calls to `on_event`. |
| OBSERVED: The exit assertion runs with the taunt budget already spent (high confidence). | `godot/story/test/story_test.gd:372`: `A friendly ship jumps in.`; `:375`: `v.on_event({"t": "risen", "unit": "e3"})`; `godot/story/battle_voice.gd:370`: `if sit_spoken >= 2 or said.has("sit_" + key):` | The two earlier events each spend a situational line. An Intercept exit would therefore also stay silent if the `exit` guard were removed. | Use a fresh voice for the escape check and a separate fresh voice for a real retreat. Assert that only the retreat emits `sit_enemy_flee`. |

## a3b84329: Campaign table export

**OBSERVED: Sound.** At the pinned tip, a fresh export matches both committed tables. The campaign table now includes `ARC_USAGE_KEY`; the rules table already has it, and the GDScript counter uses the matching constant.

## ff37445f: Parity baseline refresh

**OBSERVED: Sound on its parent.** I decompressed and parsed every before/after record (`a3b84329` to `ff37445f`), checked their hashes, and compared the nested fields. Across 288 battles and 30,879 aligned records, 282 battles changed. Only battle-log messages, unit names, weapon names and displayed killer names differed. All `usage.fire` maps were identical, including 24,681 non-empty maps. Scenario hashes, record counts and non-battle result artifacts were unchanged.

**OBSERVED: Merge risk.** Current `origin/main` (`79fe8d6b`) has newer battle rules and baseline commits from PRs 1564, 1566 and 1568. Both sides changed 284 of the same saved paths. For example, `godot/rules/test/saved/results.json:9` is `"records": 170,` on main and `"records": 182,` at the pin for the same `s1` scenario. Do not carry the pinned archives forward as the merged baseline. Regenerate on the combined source and check its decoded diff against the main baseline.

## Impact sweep

- **Callers:** Searched the pinned tree for the arc constants and fire maps, both article helpers, and the voice setup, sync and event paths. The frozen experiment and generated HTML have old inlined code; the active browser oracle loads the root JS. The Godot HUD calls voice for ordinary events but skips grouped hits.
- **Saves:** Loaded synthetic old-schema checkpoints in both twins, retaining the `HNS` name and flagship UID. Loaded a Godot Career profile mixing old broadside keys with a flank key and verified its broadside share. The existing Godot truth-pass test also covered reload and reinforcement for all six factions. The engine's round snapshot guard still falls back on a build change.
- **Twins:** All five keys match. Article helpers returned identical results for the loaded legacy, new-prefix, leading-article and bare names. Remaining caller drift is listed above. Both exported tables match the root source byte for byte.
- **UI:** Traced reinforcement and pyrrhic notices, shipyard joins and repairs, reward and debrief text, Career title inputs, and battle HUD log and end card. Map and intel labels read display data; they do not consume usage keys or article-formatted names.
- **CI:** `.github/workflows/checks.yml:107,134-138,232-235` runs the standing pack, rules parity, campaign parity and the Godot headless list. `godot/tools/ci/godot_checks.txt:48,74` registers both the repair and story tests. The GDScript list is the runner for these tests.

## Verification

Changed only `contrib/openai/reviews/wip_1551_keys_review.md`. Checks below ran on the pin in scratch:

- Rules: `PASS: the Godot port matches the game's rules exactly.` All 288 battles, the threat maps and thread check passed. The first wrapper run timed out during threads; the retry passed all rules and saved results before the wrapper timed out during its campaign hand-off.
- Campaign, run separately: `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.`
- Live records against pinned baseline: `PASS: saved Godot results; 288 battles checked, 0 changed, 0 other files changed, 0 failures; 16.128 s`
- Offline archive comparison: `PASS: saved baseline changes only display text and preserves usage.fire` (relative to its parent). Comparing directly to current main was different, as explained above.
- Shipyard: `PASS: shipyard repair text names credits and a fresh lieutenant, and biomass and a fresh spawn-mind for the Chorus`
- Story: `story_test: PASS (0 failed)`
- Truth pass (exit 0): `PASS: a purchased ship with The in its name joins with one article`
- Save probes: `PASS: Godot loads legacy fleet names, flagship id and mixed arc counters`; `PASS: JS loads legacy fleet names and flagship id; article outputs match expected`
- Voice contrast probe: `PASS: a fresh voice distinguishes exit from retreat; the spent budget masks both`
- Exported both tables to scratch and compared bytes: `PASS: fresh export matches byte for byte: godot/rules/data/tables.json`; `PASS: fresh export matches byte for byte: godot/campaign/data/campaign_tables.json`
- Last branch check, `oracle_copy_test.js`: `PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files`

**Recommended next step:** Fix the HUD event hand-off on PR 1552, then rerun the checks on that branch with current main and refresh the two tables and saved records there.

<details>
<summary>Source readback at ff37445f</summary>

Line totals and the first 40 characters (or fewer) of the last line, from raw Git blobs. Tabs are shown as `\t`. The ranges identify the relevant review hunks and caller paths.

| File | Lines | Last line start | Reviewed ranges or scope |
|---|---:|---|---|
| `data.js` | 5350 | `};` | 28-34; export inputs evaluated by Node |
| `battle.js` | 2371 | `}` | 970-977, 1275 |
| `campaign3d.js` | 160 | blank | 61-74, 119-137 |
| `campaign_run.js` | 851 | `}` | 222-260, 544-550, 582-597, 685-716, 774 |
| `core.js` | 525 | `function findNode(id){ for(const c of RU` | 78-112, 119-145, 519 |
| `godot/rules/rules.gd` | 7198 | `\tB["aiActive"] = null; u["activated"] = ` | 16-20, 1282, 3234-3241, 3733-3779, 3819-3836, 3872-3879, 4075-4079 |
| `godot/rules/battle_api.gd` | 1169 | `\treturn why` | 245-276, 393-400, 919-938, 1095-1125 |
| `godot/campaign/campaign.gd` | 4003 | `\t\t"events": tel_log.slice(max(0, tel_log` | 164-173, 325-372, 407-448, 475-516, 571-575, 1889-1920, helper callers listed above |
| `godot/campaign/test/shipyard_repair_text_test.gd` | 60 | `\tquit(1)` | Full test |
| `godot/ui/campaign/campaign_ui.gd` | 2535 | `\t\t\t\tC.act(on[n][0], on[n][1]); get_viewp` | 1698, 2360, 2374 |
| `godot/story/battle_voice.gd` | 526 | `\treturn "%s: \"%s\"" % [admiral_name(), ` | Full file |
| `godot/story/test/story_test.gd` | 531 | `\tok(battles_seen > 0 and recorded_runs =` | 319-386 and test output |
| `godot/story/career.gd` | 474 | `\treturn row` | 15-43, 155-184, 369-388 |
| `godot/story/data/situations.json` | 727 | `}` | Crusade's `reinf_ally`, `enemy_risen` and `enemy_flee` pools |
| `godot/scenes/battle/battle.gd` | 6307 | `\tget_tree().quit(code)` | 624-645, 919-976, 979-994, 1111-1125, 1270-1306, 1342-1378, 2081-2264, 2634-2660, 4191 |
| `godot/tools/ci/godot_checks.txt` | 204 | `gpu\|ui/test/front_end_shots.gd\|-\|{out}\|i` | 24, 48, 54, 74 |
| `godot/campaign/data/campaign_tables.json` | 1 | `{"sha256":"486b3670aefbbfe47f758ffdcc4a8` | Whole-file export comparison |
| `godot/rules/data/tables.json` | 1 | `{"sha256":"79114c770cdd031f2bedb51734a52` | Whole-file export comparison |
| `godot/rules/test/saved/changes.txt` | 1134 | `FAIL: saved Godot results; 288 battles c` | Header, examples and final count; verified by decoded records |
| `godot/rules/test/saved/results.json` | 2064 | `}` | Whole manifest and its 288 Brotli battle archives |

</details>

**Not checked:** The full standing pack (runner-owned), visual captures (this is a text and code review), or the final combined PR 1552 tree. A headless import in scratch crashed during font import; the listed source and headless checks subsequently ran. No real player save or installed game was opened.
