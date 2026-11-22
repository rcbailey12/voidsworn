# Glossary

The words this project uses, so every agent and skill names things the same way (issue 1658). Definitions only: rules
and their reasons live in `docs/RULEBOOK.md`, decisions in `contrib/opus/FINDINGS.md`.

## The game

- **Embers of the Hollow Sun**: the game. The repo is still named voidsworn.
- **Faction id**: the fixed code name of a faction, used in code and saves. It never changes.
- **Display name**: what the player reads. It may change (contrib/opus/compute/rename_map_final.md).

| Faction id | Display name |
| --- | --- |
| `voidsworn` | Sunward Crusade |
| `corsair` | Ashfall Hullbreakers |
| `ithar` | the Glasswrights |
| `deathless` | Eclipse |
| `chorus` | the Chorus |
| `hegemony` | Meridian Directorate |

- **Rules**: the Godot battle and campaign logic (`godot/rules`, `godot/campaign`) and their table files. The only rules
  source since R405.
- **Browser rules** (also "the JS twin"): the frozen root files data.js, core.js, battle.js and the campaign files.
  History, not a source.
- **Saved results**: the reviewed Godot outputs every rules change is compared with (battles, campaign runs, Nemesis
  scenarios). A change that moves them updates them in the same pull request.
- **Cut-in**: the short cinematic close-up the battle shows on key attacks (setting: key moments, all attacks, off).
- **Breach anchor**: a marked point on a hull where breaks, tears and boarding effects start, beside the hard points.
- **Hard point**: a marked mount on a hull for a weapon, engine or effect, matched to the ship's weapon slots.

## Ships

- **Concept**: the approved picture of a ship design (Ryan's pick, listed in docs/ship_pipeline/FLEET.md).
- **Build sheet**: the written and drawn plan a ship is built from in Blender: parts, routes, paint stack, budget.
- **Part kit**: the shared Blender parts a faction's ships are built from, so one fix reaches every ship.
- **Stages**: sheet built, paint proof, installed in game, Ryan accepted. Each picture says which stage it shows.

## Checks and pictures

- **Look bench**: a fixed-camera capture of ships and effects on the PC, for before and after comparisons.
- **Player path**: the recording of Battles 1 to 3 on the installed build with a fresh profile and player defaults, the
  acceptance check for visual and teaching changes (RULEBOOK 12.6).
- **All checks**: the one GitHub check mark to read on a pull request.

## The board and the PC

- **Board**: the one Claude thread that owns the job board, reviews and merges.
- **Seat**: an AI worker (Opus, Codex, Muse, Neon, Artoo) with its own role (RULEBOOK 2.6).
- **Job board**: the open GitHub issues; the label says which seat has each job.
- **Lane**: one of the PC's job queues (lane C and D are code only).
- **Pin**: a full 40-character commit a PC job runs, never a branch tip.
- **Attempt folder**: one run of a PC job, `voidsworn_test\<job>\out_<stamp>_<n>`.
- **Relay**: sending an attempt's results off the PC to the private relay repo, so the job can free its checkouts.
- **tools_live**: the installed copy of the PC tools that jobs run from.
- **Pick Sheet**: the Morning or Evening list of Ryan's non-urgent picks, answered as `1=B, 2=Yes` (RULEBOOK 1.8).
