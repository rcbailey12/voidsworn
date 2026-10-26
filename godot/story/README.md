# godot/story: admiral lines, flagship names, titles, career and (later) the faction arcs

Owner: the story and career stream (travel sprint, R37). Folders: `godot/story/` (data, text, logic) and `godot/ui/career/` (screens). This file is the contract with the campaign (G3) and the game shell and battle scene (G2). A change to it lands here in the same commit.

**Rules this layer keeps:**
- It never calls `campaign.act()` and never touches the rules PRNG, so campaign parity and battle parity cannot see it. `story_test.gd` checks that a whole run plays out the same with and without the story attached.
- Career data lives in its own file, `user://voidsworn_career.json` (plus `.bak`), not in the campaign save.
- The one write into the campaign is the flagship's name (`ship.name`), and only when the player renames it.

## Files

| File | What |
|---|---|
| `story.gd` | The layer itself (a Node). Watches the campaign, records battles and runs, gives lines for text boxes, renames the flagship, opens the screens. |
| `career.gd` | The career profile: records per admiral, totals, medals, titles, run history. Pure logic, no nodes. |
| `battle_voice.gd` | Admiral, enemy flagship and Nemesis lines in battle, driven by the rules' event stream. |
| `rival.gd` | The Nemesis's voice (R42): picks his lines by faction, personality, scars and how you beat him; his beat 1 calling card; his beat 3 hail by the run's lean. |
| `tokens.gd` | Story tokens (`{rival}`, `{he}` `{him}` `{his}`, `{rival_deed}`, `{first_lost}` ...) with plain fallbacks. |
| `arc.gd` | The arc engine: beat data, variant pick, conditional lines, event-shaped cards, endings. Arc files come after approval. |
| `data/voices.json` | 24 admirals x 11 moments, and enemy sector flagship lines per faction. |
| `data/rival_lines.json` | The Nemesis's pools per faction: hail, rematch, final, beaten, death, gloat, kill, signature, scars, memory (7 ways you beat him), 6 personalities, calling cards, beat 3 hails. |
| `data/titles.json` | 12 titles earned from how you fight, plus a fallback, each worded per faction, with the rules in plain words. |
| `data/medals.json` | 12 medals. |
| `data/arcs.json` | What finishing each arc pays: medal, arc title, flagship paint, and the hull unlock id. |
| `outlines.md`, `outlines_variants.md` | The six faction story outlines (REVISED after two reviews) and their B versions, skims and rival incidents; waiting for Ryan's approval. |
| `unlocks.md` | Draft hull unlock per faction, for stream B (rules and balance). |
| `test/story_test.gd` | Headless checks (below). `test/check_outlines.py` checks outline word counts, pronoun tokens and dashes. `test/fixture_arc.json` is test data for `arc.gd`. |
| `../ui/career/career_screen.gd` | The Career screen: Records, Medals, Titles, History, Chronicle tabs. |
| `../ui/career/rename_dialog.gd` | "Name your flagship". |
| `../ui/career/crest.gd` | Faction crests and medals drawn as vector strokes (crests instead of portraits). Usable anywhere. |

## Hooks wanted from other streams

Each hook is a few lines, guarded so the game still runs if `godot/story/` is missing. Until a hook lands, that part of step 1 just does not show.

### 1. Campaign host (G2, `godot/main/campaign_host.gd`, in `start()`, before `ui.bind(C)`)

```gdscript
# story layer (godot/story/README.md): admiral lines, flagship name, titles, career records
var story = null
if ResourceLoader.exists("res://story/story.gd"):
	story = load("res://story/story.gd").new()
	story.name = "Story"
	add_child(story)
	story.attach(C, not bot)      # bot runs keep the career in memory only
```

Attaching before `ui.bind(C)` makes the story see each `changed` signal before the UI draws, so any line it offers is ready for that draw. In bot runs, attach it too (it records into memory only), so every full-run bot run also tests the story layer.

Then pass the story into battles, for example `main.play_api(a, {"bot": bot, "can_retreat": C.can_retreat(), "story": story})`.

### 2. Battle scene (G2, `godot/scenes/battle/battle.gd`)

```gdscript
var voice = null   # story layer (godot/story/battle_voice.gd)

# in _begin(a), after V = api.view():
if opts_story != null:    # the "story" option from play_api, or res://story/battle_voice.gd loaded directly
	voice = opts_story.battle_voice()
	voice.setup_from_rules(R, V)
	for l in voice.opening(): hud.add_log(l["text"], l["kind"])

# at the top of _play_event(e):
if voice != null:
	for l in voice.on_event(e): hud.add_log(l["text"], l["kind"])

# in _end_flow(), before hud.show_end(...):
if voice != null:
	var vl: String = voice.closing(win)
	if vl != "": body += "\n\n" + vl
```

Lines go to the existing battle log, with existing colour classes (`"s"` gilt for your admiral, `"e"` red for the enemy). The voice also works in quick battles: `load("res://story/battle_voice.gd").new()` needs no campaign.

What it says, once per battle each: the opening (your admiral; against a sector flagship, its hail first; against the Nemesis, his hail first, his final line in sector III), your flagship below 40% hull, your first ship lost, your Command, the enemy flagship destroyed (its last words, then your admiral), and on the end card your admiral's win or loss line (or the Nemesis's gloat if he beat you).

### 3. Campaign screens (G3, `godot/ui/campaign/campaign_ui.gd`)

The UI can find the story at `get_parent().get_node_or_null("Story")` (the host adds it as a sibling) and asks for one line for the screen it is drawing:

```gdscript
var st = get_parent().get_node_or_null("Story")
var line: String = st.campaign_line() if st != null else ""
if line != "": v.add_child(lbl(line, 17, GILT))     # plain text, no BBCode
```

| Screen | `campaign_line()` gives |
|---|---|
| page `admiral` | the picked admiral's pick line |
| modal `intro` and `sector` | your admiral's sector line |
| page `end` | your admiral's win or loss line, then "Title earned: ..." on a new line |

Also available:
- `st.titled_name(admiral_id)`: "Warlord Grax Ironjaw the Breaker" (the latest title earned), for the admiral card and the map sidebar.
- `st.open_rename()`: opens "Name your flagship" (a "Rename" button on the fleet screen's flagship card would call this). The story already opens it once by itself over the first sector intro of every run.
- `st.open_career()`: opens the Career screen (a "Career" tab beside the Progression tabs would call this).
- Signals `st.medal_earned(id, name)` and `st.title_earned(row)`, for a toast if wanted.

### 4. Title screen (G2, `godot/main/title.gd`)

```gdscript
if ResourceLoader.exists("res://story/story.gd"):
	menu.add_child(_button("Career", func() -> void: load("res://story/story.gd").open_standalone(self)))
```

## What is recorded

Per battle, from the rules' own `B` after `finish_battle` (no new rules fields): enemy ships destroyed, your ships lost (squadrons and captured prizes not counted), and `B.usage` (guns fired by kind and arc, aimed shots, rams, boardings, captures, orders, abilities, Commands).

Per run, at the end screen: the title earned, the run's line in the history, the admiral's record (runs, wins, best sector, battles, kills, losses, titles, flagship names) and the totals.

**Titles** (`data/titles.json`, rules in plain words in each row): brawler (rams and boardings), prize taker (captures), lancer (lance and gauss share), torpedoer, carrier, broadside (port and starboard share), gunline (battery share), marksman (aimed shots), anvil (braces), unscarred (battles with no loss), butcher (kills per battle), tactician (abilities per battle). A run needs 3 battles. The strongest score wins; otherwise the fallback (the Steadfast).

**Medals** (`data/medals.json`): First Blood, Flagship Breaker, Lightning Strike, Last Stand, Unbroken, Prize Master, Nemesis Slain, Victor, Forged in Heat, Centurion, Long Service, Six Banners.

## Story arcs (step 3, after Ryan approves `outlines.md`)

The plumbing is built and tested (`arc.gd`, `tokens.gd`, `rival.gd`); the arc files (`data/arcs/<faction>.json`) are written once Ryan approves the text.

- `story.arc_beat(n)` returns the card for beat 1, 2 or 3 of the run's faction as an event-shaped dictionary, `{id, t, b, o:[{k, l, s, r, fl, need?}], outs, skim, skim_first, charge, variant, arc: true}`: the same shape as `EVENTS` in data.js, so the existing event screen can draw it and the existing `applyOutcome` and `eventFlags` apply it (each option's story flag rides in `fl`, so `RUN.flags` remembers it). `outs[k]` is the one-sentence result to show after the click. `skim_first` says to open on the short card.
- After the campaign applies the choice: `story.arc_chose(card, key)` (marks the variant seen, keeps the choice for the Chronicle). After beat 3's fight: `story.arc_end(won)` (Chronicle, medal, title, paint, unlock id).
- Outcome keys used by the outlines: `cred`, `cost`, `relic`, `payRelic`, `xp`, `healAll`, `dmgAll`, `dmgOne`, `dmgBig`, `shipRaw` (+`vet`), `mod`, `payMod`, `payXp`, `nemIntel`, `nemClock`, `ambush`. Counters written for the rival's memory: `mercy`, `greed`, `loud`.
- **Hook wanted (G3 with stream B):** show `story.arc_beat(1)` after the sector I intro, and `arc_beat(2)` and `arc_beat(3)` when sectors II and III begin, through the event screen. Until then the arcs do not appear.
- **Asked of stream B (R42):** a gender field on `RUN.nem` (`g`: `m`, `f` or `n`; until then `tokens.gd` guesses from the captain name pools, and a Chorus rival is `it`); personality ids `proud`, `cruel`, `cunning`, `zealous`, `cold`, `mocking` (any other id falls back to the faction pools); optional `last_beat` (how you beat him: `lance`, `torp`, `sq`, `ram`, `board`, `battery`, `evasive`); `beaten` and `scars` carried into the battle's `B.nem`; and an event `{t: "nem_signature"}` when his faction behaviour fires, so the battle voice can speak it.

## Checks

```
godot --headless --path godot --script res://story/test/story_test.gd [-- runs]
python3 godot/story/test/check_outlines.py
```

`story_test.gd`: data complete (24 admirals x 11 moments, faction and Nemesis lines, titles worded for all six factions, no em dashes); 14 hand-made runs earn the expected titles; career records, medals, save, load and backup fallback; the battle voice on scripted events and on a real rules battle played by the game's AI; whole campaign runs with the story attached, recorded, and the campaign state identical with and without it.
