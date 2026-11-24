# C27 Nemesis Double Hail Check (Issue #1909, Refs #1407)

**Verdict: The Nemesis hail fires TWICE on `main` (`d610eca2c`), in two different voices.**

`contrib/opus/reviews/council_1120/triage_1123.md` line 82 marked C27 "Likely fixed" on the assumption that retiring browser `data.js` (R405) removed the second hail. A live headless Nemesis battle on `main` disproves that: Godot still logs **both** the story layer hail (`godot/story/data/rival_lines.json` via `battle_voice.gd:opening()`) and the campaign/rules hail (`NEM_VOICE` in `godot/campaign/data/campaign_tables.json` via `campaign.gd:nemOpenLine()` -> `rules.gd:applyNemesis()`).

**Fix issue filed:** [#1911](https://github.com/rcbailey12/voidsworn/issues/1911) (`C27: stop Nemesis double opening hail in battle log`, Owner: `opus`). The C40 admiral wording (PR #1880) and the R85 per-sector hunter call are left untouched.

**Reviewer:** Neon
**Date:** 2026-11-23
**Commit checked:** `d610eca2c` (`main`)
**Engine:** Godot `4.7.2.stable.official.ed1daf0bf` (Windows console exe, `--headless`, throwaway `APPDATA` profile)

---

## 1. Headless Nemesis Battle Log Excerpt

**Setup:** Campaign run seeded with `JSM.rnd_seed(1)`, `C.newRun("vex", "voidsworn")`, Sector 1 Nemesis encounter (`Eclipse-prime Toror`, `fac=deathless`, `persona=patient`, `kind="elite"`, `nemesis=C.nemBattleCfg()`), run through `BattleAPI.new_battle(C.RUN, nc)` and `godot/scenes/battle/battle.gd` (`bot=false`, `showcase=false`, `external=true`, `args={"noworld": true}`), waiting until `_runner()` finished draining the opening batch (`batches[0]`).

### Player-visible battle log (`hud.log_text.get_parsed_text()` and `hud._log_lines`, 6 lines)

```text
R1  Eclipse-prime Toror: "Forty frontier worlds complain of a few cold winters while we endured ten centuries of night. Clear our vector."
R1  Admiral Roderic Vex: "There you are, Eclipse-prime Toror. Chalked your hull code on my bulkhead back home; today I scrub it off."
R1  Eclipse-prime Toror commands this fleet: your Nemesis.
R1  Eclipse-prime Toror: "Take as many turns as you need to close. After a thousand years in the dark, a few extra minutes mean nothing."
R1  Contact: Eclipse. 4 ships on the scanners.
R1  Elite captains command this fleet.
```

### Split by source

- **`recording_cue` voice lines from `battle_voice.gd:opening()` (written first via `battle.gd:678-679`):**
  1. `Eclipse-prime Toror: "Forty frontier worlds complain of a few cold winters while we endured ten centuries of night. Clear our vector."` (Hail #1: `rival_lines.json` -> `deathless.vs_faction.voidsworn`)
  2. `Admiral Roderic Vex: "There you are, Eclipse-prime Toror. Chalked your hull code on my bulkhead back home; today I scrub it off."` (C40 first-meeting reply from `voices.json`, PR #1880)
- **`api.R.B["log"]` entries from `rules.gd:applyNemesis()` and `_finishBattleSetup()` (replayed second by `_runner()` -> `_play_event("log")` at `battle.gd:1479-1480`):**
  1. `Eclipse-prime Toror commands this fleet: your Nemesis.` (`rules.gd:2498`)
  2. `Eclipse-prime Toror: "Take as many turns as you need to close. After a thousand years in the dark, a few extra minutes mean nothing."` (Hail #2: `campaign_tables.json` `NEM_VOICE.deathless.patient.meet[1]` sent in `cfg.nemesis.line` via `campaign.gd:2717,2785` and logged at `rules.gd:2504,2511`)
  3. `Contact: Eclipse. 4 ships on the scanners.` (`rules.gd:1624`)
  4. `Elite captains command this fleet.` (`rules.gd:1626`)

---

## 2. Proof of Reading (`docs/REVIEW_PROTOCOL.md`)

| File | Commit | Total lines | Ranges read | First 40 chars of last line |
|---|---|---|---|---|
| `docs/REVIEW_PROTOCOL.md` | `d610eca2c` | 35 | 1-35 | `- Claude checks every claim against the ` |
| `contrib/opus/reviews/council_1120/triage_1123.md` | `d610eca2c` | 98 | 1-98 | `icon, 28 typefaces, 37 flagship pick loo` |
| `contrib/opus/reviews/council_1120/draft_ranked_list.md` | `d610eca2c` | 263 | 65-90, 250-263 | `| Rival memory is "fixed on paper"; dead` |
| `godot/scenes/battle/battle.gd` | `d610eca2c` | 7143 | 500-740, 815-860, 960-1040, 1450-1525, 1780-1810, 5320-5360, 7130-7143 | `	get_tree().quit(code)` |
| `godot/story/battle_voice.gd` | `d610eca2c` | 526 | 1-526 | `	return "%s: \"%s\"" % [admiral_name(), ` |
| `godot/story/rival.gd` | `d610eca2c` | 198 | 1-198 | `	return line("hail", nem, seed, ctx, spo` |
| `godot/campaign/campaign.gd` | `d610eca2c` | 4139 | 1935-2010, 2705-2840, 3450-3550, 4125-4139 | `		"events": tel_log.slice(max(0, tel_log` |
| `godot/rules/rules.gd` | `d610eca2c` | 7907 | 35-75, 1600-1660, 2470-2550, 7895-7907 | `	B["aiActive"] = null; u["activated"] = ` |
| `godot/ui/battle/hud.gd` | `d610eca2c` | 1536 | 595-655, 1525-1536 | `	ledger.mark()` |

---

## 3. Findings

| # | Finding | OBSERVED/INFERRED | file:line | Exact quote | Why it matters | Your fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | Nemesis opens every campaign battle with two distinct hails from two separate pools (`rival_lines.json` and `NEM_VOICE`) | OBSERVED | `godot/scenes/battle/battle.gd:678-679` and `godot/rules/rules.gd:2504,2511` | `for l in voice.opening():` / `if N.get("line") is String: line = N["line"]` / `if jt(line): logm(String(fl["name"]) + ": \"" + String(line) + "\"", "e")` | The same commander speaks twice on Round 1 in mismatched registers (`Clear our vector.` then `Take as many turns as you need to close.`). | Emit one Nemesis hail per battle (see #1911). Pick pool ownership once (`rival_lines.json` vs `NEM_VOICE`); preserve `B.log` golden hashes unless goldens are intentionally updated. | high |
| 2 | `voice.opening()` appends to `hud.add_log` before `_runner()` drains `batches[0]`, scrambling opening log order | OBSERVED | `godot/scenes/battle/battle.gd:665,678-679,714,1480` | `batches.append({"events": api.take_events(), "view": api.view()})` / `hud.add_log(l["text"], l["kind"])` | The rival hail and admiral reply print above `"commands this fleet: your Nemesis."` and `"Contact: Eclipse. 4 ships on the scanners."`, then Hail #2 drops in the middle. | Queue or emit `voice.opening()` after the setup `"log"` events drain (or in one ordered opening pass). | high |
| 3 | Non-campaign Nemesis battles without `cfg.nemesis.line` still emit a second hail via `TB.NEM_LINES` fallback | INFERRED (from code) | `godot/rules/rules.gd:2499,2505-2511` | `var L = TB.NEM_LINES` / `else: line = L["meet"].get(N.get("persona"))` | Even if `cfg.nemesis.line` is omitted or cleared in `campaign.gd`, `rules.gd` still logs a fallback hail from `tables.json` `NEM_LINES`. | Any fix must handle both `cfg.nemesis.line` and the `TB.NEM_LINES` fallback path so non-campaign/scenario Nemesis fights do not keep double-hailing. | high |
| 4 | Existing story tests (`story_test.gd`) only test `battle_voice.opening()` in isolation, not combined with `battle.gd` replaying `rules.gd` log events | OBSERVED | `godot/story/test/story_test.gd:281,321` | `var op2: Array = vn.opening()` / `var got: Array = rv.opening()` | Explains why `triage_1123.md:82` and PR #1880 saw one hail path in `battle_voice.gd` while live battles still print two. | Add a headless `battle.gd` + campaign Nemesis regression check asserting `hud._log_lines` has exactly one `<Nemesis>: "..."` opening hail. | high |

---

## 4. Recommended Next Step

Run fix issue [#1911](https://github.com/rcbailey12/voidsworn/issues/1911) (small Opus change + headless regression check). My pick for pool ownership is **Option A (keep `rival_lines.json`, suppress the duplicate rules hail on display)** because `rival_lines.json` carries `vs_faction` and persona variety written specifically to supersede `NEM_LINES` (`godot/story/review_incorporation.md:106`), and suppressing the duplicate on display (or via a dedicated event kind) keeps `B.log` rules golden hashes intact unless the Board chooses to refresh them.

---

## 5. Not Checked

- Interactive deployment phase (`interactive_deployment = true` with a deployment skill picker) was not executed separately; code reading (`battle.gd:5337-5340`) confirms it ends by calling the same `_begin(a)` method.
- The standalone `--nemesis` scenario fallback path (Case 2 in the scratch probe) errored on missing `"admiral"` in the custom probe dict before `_begin()`; its `TB.NEM_LINES` fallback behavior is therefore marked **INFERRED** from `rules.gd:2499-2511`.
- Non-headless / GPU rendering of the battle log panel was not run (not requested; headless is sufficient per #1909).
