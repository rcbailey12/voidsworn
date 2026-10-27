# Feature checklist: today's game (index_test.html) against the Godot version (G5)

Status words: **done** (works in Godot), **partial** (works, with a gap named), **missing**, and the owner when another stream builds it (G1 rules, G3 campaign, G4 look, A4 ships). Updated by G2 with each commit that changes a row.

Last update: Oct 26 2026 evening, G2.

## The program

| Feature | Status |
|---|---|
| One program: title, campaign, battles, back to title (godot/main) | done |
| Title screen: Continue run, New run, Progression, How to play, wording as the browser | done (title.gd); Quick battle and Settings added |
| Settings: sound on or off, volume, speed, enemy AI (Veteran or Standard), reduce flashing, screen shake, follow enemy activations, battle tips, full screen, graphics quality | done (saved to user://settings.json, written whole then renamed; the in-battle menu changes them too). Graphics sets MSAA, shadows, SSAO, SSIL and haze. Keyboard and controller reach every title and settings button, with a visible focus ring |
| Saves: run and profile | done in G3 rules (user://voidsworn_campaign.json with a backup) |
| Windows build (.exe) | done on the PC (the preset writes ../export from build\godot, so build\export\Voidsworn.exe); test folders kept out of the package; `--check-export` on the exe checks that; exe smoke test pending |
| Double-click start for Ryan | done: tools/pc/play_godot.bat (runs the exported .exe when present) |
| Headless full runs with both sides on AI (errors, softlocks, time) | done: --bot-runs N (the game's own AI on your side; the smart policy shops like a player); errors counted with a Logger; a log line per battle; --run-timeout hang guard. PC: 8-run batches in lane B |
| Report a problem (browser: copy report) | done: in-battle menu, copies the battle facts, errors and log |
| Shader warm-up on the loading screen, pipeline compiles counted in play | done (0 in sandbox runs) |
| Compatibility renderer launcher (play_godot_safe.bat) | done |

## Campaign screens (rules: G3, done with parity; drawing: G3's ui/campaign, until then the G2 fallback)

| Screen | Rules (G3) | Drawn |
|---|---|---|
| Admiral and faction pick, run options (alternate start, alternate Command, Heat) | done | fallback |
| Aspect pick | done | fallback |
| Intro briefing | done | fallback |
| Sector map, node info, node modifiers | done | fallback (no map picture) |
| Fleet screen: equip, unequip, promote, perks | done | fallback |
| Shipyard: buy hull, buy module, repair, repair all, upgrade, sell | done | fallback |
| Drydock | done | fallback |
| Events and results | done | fallback |
| Battle: real battle in the battle scene, retreat (not against a sector flagship) | done (external mode) | done |
| Victory, prize ships (add, strip or ransom), salvage, module, boon, relic rewards | done | fallback |
| Sector change | done | fallback |
| Progression (renown, hull variants, mastery, patrons) | done | fallback |
| How to play | done | fallback |
| Run end screen | done | fallback |
| Map and title showcase battles (decorative) | missing (G3 left out of parity) | missing |

## Battle: controls and screen (G2)

| Feature | Status |
|---|---|
| Hex board at game scale, terrain (rocks, hulks, debris, nebula, ion storm, station, planet) | done (station as one structure per cluster); dead star picture: G4 world |
| Ships from the game hulls and the six 8K flagships, faction finish, engine glows | done; A4 kit ships with breach skins are used as soon as they are in godot/assets/ships |
| Footprints: green ring under yours, broken violet hex under the enemy's (B1) | done |
| Nameplates with hull and shield bars, gold star on flagships | done |
| Camera: right-drag orbit, left-drag or WASD pan, wheel zoom, T top-down, Home reset, F focus | done |
| Ship movement with weight (R50): mass-scaled burn and braking, hulls swing and bank into turns, big hulls arc, overshoot and settle, engine flare on the burn, RCS puffs on turns and stops, wings trail a beat behind; the settle overlaps the next ship so the pace holds; Movement: Cinematic or Brisk in settings and the battle menu. Measured: the enemy's share of a round is the same in both (within 0.3 s, same seed, same outcomes); every battle report carries `pace` (enemy seconds per round, mean and max) | done (RCS puffs drawn by the scene in G4's puff colour) |
| Select (click or Tab), move range in gold, best facing per hex, facing arrow and path preview, Q/E to pick the facing | done |
| Turn in place (Q/E on the ship's own hex) | done (rules rotate) |
| Fire: every gun that bears with one click, 1-6 picks one gun, hit chance and expected damage in the tip | done |
| Attack-move (click an enemy out of reach: burn into position and fire) | done: fires during the burn (rules attack_move) |
| Why you can't fire (out of range, arc, sight, braced, spent) | done (toast) |
| Brace (B), ram (X), board (G) | done |
| Abilities without a target (evasive, reload, focus, surge, ion pulse, overburn, frenzy, regrow, reclaim, phase) | done |
| Abilities with a target hex (nova, blink, launch) | done (pick the hex) |
| Admiral's Command (player) | done: top-bar button when ready, two clicks to confirm as the game asks |
| End activation, Pass, Continue (Enter) | done |
| Enemy turns at B2 pace, Enter or Space hurries, enemy-acting chip, camera follow | done |
| Threat map (R) | done: the rules' threat_map (byte for byte with the browser), on a worker thread when the board changes |
| Firing arcs (V, the fans) | done: fans under the selected ship, on by default, V toggles |
| Hull and shield bars that change as hits land, floating numbers (shield, hull, Miss, Critical, Shields down) | done |
| Battle log with the browser's lines and colours | done: the rules' own log lines, word for word |
| Round banner, Victory and Defeat card | done |
| Retreat button in campaign battles | done |
| Objective in the top bar (rout, flagship, hunt, defend, intercept, break, hold) | done, with the zones on the board and their tips |
| Speed: normal or fast | done |
| Onboarding tips one at a time, Got it, Hide tips (B1) | done: all 10 browser tips (fix 2 motion rule in the move tip, fix 3 alternating turns at battle start, fix 5 enemy-acting chip; fix 1 Standard AI on a fresh profile) |
| Squadrons and carriers | done: wings drawn as craft formations, wing orders (click your wing, then a target), Strike, Screen and Hunt stances |
| Travelling torpedoes (stream B) | done: lanes, parked salvos, strikes and misses a turn later |
| Move, then fire (stream B) | done: movement left shown after firing |
| Deathless rising wrecks | done |
| Mid-battle events (reinforcements, warnings) | done: the rules log them; reinforcements appear with the next view |
| Cut-ins (cinematic camera), follow activations toggle | done (Key moments, Every attack or Off; follow in settings and the battle menu) |
| Concept-art hulls toggle, temporal AA toggle | missing |
| Legend and command strip help | partial: the controls line under the ship panel lists every key (readable colour now); no legend panel yet |
| Ship sheet (full stats) | partial: the side panel |

## Battle effects and look (G4)

| Feature | Status |
|---|---|
| Weapon families, impacts, shields per faction, staged damage, deaths, wrecks, trails, shake, hit pause | done through G4's fx (G2 calls it per event) |
| Sky, nebula, planet, dead star, asteroid blockers, dressing | done through G4's world |
| Black-hole lensing and accretion disc on the dead-star board | G4 |
| Reduce flashing (WCAG) | done: the setting and Screen shake reach G4's fx live (settings and the battle menu); the scene's own flashes (boarding, ram, blink, risen wrecks, nova, launches) go through fx's 3-per-second budget and reduce mode. Compatibility mode (play_godot_safe.bat) draws no hull damage marks yet (G4: decals are off there) |

## Sound (G2)

| Feature | Status |
|---|---|
| The game's cue table, recorded clips and synth cues (rendered offline from sfx.js) | done |
| Buses, compressor and limiter, reverb send, voice caps, round robin, pitch jitter, salvo thinning | done |
| Ambient bed | partial: recorded room tone only (the browser adds a synth bed) |
| Music (title, map per sector, battle by factions with intensity, stings) | done: the music helper's player and tracks (music.json, CREDITS.md); Music on/off and volume in settings. Licences: see godot/music/CREDITS.md |
| Engine cues on moves | done |
