# Feature checklist: today's game (index_test.html) against the Godot version (G5)

Status words: **done** (works in Godot), **partial** (works, with a gap named), **missing**, and the owner when another stream builds it (G1 rules, G3 campaign, G4 look, A4 ships). Updated by G2 with each commit that changes a row.

Last update: Oct 26 2026, G2.

## The program

| Feature | Status |
|---|---|
| One program: title, campaign, battles, back to title (godot/main) | done |
| Title screen: Continue run, New run, Progression, How to play, wording as the browser | done (title.gd); Quick battle and Settings added |
| Settings: sound on or off, volume, speed, enemy AI (Veteran or Standard), reduce flashing, screen shake, battle tips, full screen, graphics quality | done (saved to user://settings.json). Reduce flashing and shake reach G4 fx once it lands. Graphics quality is stored but does nothing yet |
| Saves: run and profile | done in G3 rules (user://voidsworn_campaign.json with a backup) |
| Windows build (.exe) | partial: tools/pc/jobs/g2_export.bat written, first PC run pending |
| Double-click start for Ryan | done: tools/pc/play_godot.bat (runs the exported .exe when present) |
| Headless full runs with both sides on AI (errors, softlocks, time) | done: --bot-runs N. 1 full campaign run in the sandbox: 2 battles, 1084 clicks, 0 errors. 50+ on the PC pending |
| Report a problem (browser: copy report) | missing |

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
| Ships from the game hulls and the six 8K flagships, faction finish, engine glows | done (G4 and A4 improve) |
| Footprints: green ring under yours, broken violet hex under the enemy's (B1) | done |
| Nameplates with hull and shield bars, gold star on flagships | done |
| Camera: right-drag orbit, left-drag or WASD pan, wheel zoom, T top-down, Home reset, F focus | done |
| Select (click or Tab), move range in gold, best facing per hex, facing arrow and path preview, Q/E to pick the facing | done |
| Turn in place (Q/E on the ship's own hex) | partial: through reach states (rules rotate is not ported yet, G1) |
| Fire: every gun that bears with one click, 1-6 picks one gun, hit chance and expected damage in the tip | done |
| Attack-move (click an enemy out of reach: burn into position and fire) | partial: fires after the burn, not during it (needs the rules' late-fire hook in the API, G1) |
| Why you can't fire (out of range, arc, sight, braced, spent) | done (toast) |
| Brace (B), ram (X), board (G) | done |
| Abilities without a target (evasive, reload, focus, surge, ion pulse, overburn, frenzy, regrow, reclaim, phase) | done |
| Abilities with a target hex (nova, blink, launch) | missing: needs target-hex picking (G2 next) |
| Admiral's Command (player) | missing (rules: G1 not ported; button: G2 after) |
| End activation, Pass, Continue (Enter) | done |
| Enemy turns at B2 pace, Enter or Space hurries, enemy-acting chip, camera follow | done; camera follow is a highlight ring only |
| Threat map (R) | partial: shades hexes enemy guns reach from where they stand; the browser also adds each enemy's movement |
| Firing arcs (V, the fans) | missing |
| Hull and shield bars that change as hits land, floating numbers (shield, hull, Miss, Critical, Shields down) | done |
| Battle log with the browser's lines and colours | done (built from the event stream until G1's log event lands) |
| Round banner, Victory and Defeat card | done |
| Retreat button in campaign battles | done |
| Objective in the top bar (rout, flagship, hunt, defend, intercept, break, hold) | done; objective zones on the board missing |
| Speed: normal or fast | done |
| Onboarding tips one at a time, Got it, Hide tips (B1) | done (9 of the 10 browser tips; the Command tip waits for the Command) |
| Squadrons and carriers | missing (rules: G1) |
| Mid-battle events (reinforcements, warnings) | partial: rules run them; no banner or toast yet |
| Cut-ins (cinematic camera), follow activations toggle, concept-art hulls toggle, temporal AA toggle | missing |
| Legend and command strip help | missing |
| Ship sheet (full stats) | partial: the side panel |

## Battle effects and look (G4)

| Feature | Status |
|---|---|
| Weapon families, impacts, shields per faction, staged damage, deaths, wrecks, trails, shake, hit pause | G4 (godot/fx/API.md); G2 calls it when fx.gd lands, placeholder effects until then |
| Dead-star sky, asteroid field, dust haze | done as interim (render/backdrop.gd); G4 world replaces it |
| Black-hole lensing and accretion disc on the dead-star board | G4 |
| Reduce flashing (WCAG) | G4, the setting is wired |

## Sound (G2)

| Feature | Status |
|---|---|
| The game's cue table, recorded clips and synth cues (rendered offline from sfx.js) | done |
| Buses, compressor and limiter, reverb send, voice caps, round robin, pitch jitter, salvo thinning | done |
| Ambient bed | partial: recorded room tone only (the browser adds a synth bed) |
| Engine cues on moves | done |
