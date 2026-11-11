# The Fable program: one finished battle, and playbooks other models can run

Issue 405. FINDINGS R167. Written by the Board (Fable 5.2), Nov 10 2026.

## What Ryan asked for

"I still have another full fable reset, so we can use fable on the really key stuff. Design, graphics, effects, etc. let's do
everything we can to use the fable resets smart here. Playbooks or recipes, deep reviews and redesign, etc. codebase is yours
with my direction and vision, you bring it to life with the decisions needed from me. I want this to end with something that
opus or other models can run from" (Nov 10 2026, 08:42 CST).

His scope answers:
- Focus, in this order of weight: battle effects, ships, space and the board. Screens and sound still get a playbook, lighter.
- End state: "One finished battle + playbooks".
- Steering: "Options first, then build". He sees two or three options, picks one, then it is built.
- Decisions: "As they come". Two lines and one image, whenever a pick is ready.

## The end state

1. **One finished battle.** A single fight that looks and reads final from the first shot to the last wreck, at the camera the
   game is really played at (camera 170 on the look bench). It is the proof that the recipes work and the reference every
   later job is judged against.
2. **A playbook per area**, written from what that battle needed, so another model can do the next ship, effect, hex or
   screen without asking: docs/playbooks/effects.md, ships.md, space.md, screens.md, sound.md.
3. **The front door**: HANDOFF.md section 0 and AGENTS.md point at the playbooks, and the job board holds the remaining items
   as ready jobs written from each playbook's job template.

## The finished battle (what "final" means here)

- **Board**: the dead-star gravity-well board (owner ruling, Oct 24).
- **Fleets**: about six to eight ships a side. **Sunward Crusade against Eclipse** (Ryan, Nov 11 2026, R180; this replaces the
  first plan of the Hullbreakers plus one other). Both have a settled flagship (docs/playbooks/factions.md) and look nothing
  alike. Each fleet needs one capital, one cruiser or destroyer and one escort through the ship recipe.
- **Ships**: built by tools/recipe with real thickness, break lines and interiors (R98), hard points by hull class and faction
  theme (R164 item 4, issue 363), concepts in three views (issue 398).
- **Effects**: every big moment staged to Muse's table (contrib/muse/design/hit_staging_2026_11/synthesis.md): explosions by
  the picked route (issues 353, 365), deaths in three beats (366), one kit of trails, beams and flares (367), effects that
  start on the ship (370), shields that hug the hull, show four sides and rest invisible (R163 item 2; 371, 372).
- **Space**: nebula and ion storm hexes with depth (368), a board planet and rocks from real data, remixed past recognition
  (R163 item 3; 369), the black hole and sky calm enough that ships and effects win.
- **Screen**: the battle HUD as it is today (Lime Tactical), unless Ryan rules otherwise after he has seen the Briefing map
  in the game (R165).
- **Sound**: outside the finished battle until the sound redo is scoped with him.
- **Done**: a capture of the whole fight and its look bench sheet, and Ryan says yes.

## How every item flows

1. **Options.** Fable makes two or three options: a bench sheet of real captures where the thing exists, a flat mockup where
   it does not. Cheap, fast, and never more than one sheet per decision.
2. **Pick.** Ryan picks, with one image and two lines in front of him. The pick is recorded in FINDINGS with his words.
3. **Build.** The seat the table below names builds it. One worked example first, never the whole set.
4. **Proof.** The look bench before and after, at camera 170 first (bench a commit twice, keep the second run), plus the
   area's own check. Fable looks at the pictures, not the claim.
5. **Recipe.** What worked is written into the area's playbook the same day: target, steps, check, traps, job template.
6. **Roll out.** The rest of that kind (the other 34 hulls, the other weapons, the other hexes) becomes jobs written from the
   playbook's template, for DeepSeek, Codex or Opus. Fable only reviews their pictures.

## Who does what

| Work | Seat |
|---|---|
| Options sheets, art direction, faction theme sheets, picture reviews, the playbooks, picks put to Ryan | Fable 5.2 (the Board, and at most two Fable helpers) |
| The first in-engine build of a new look, where an eye is needed at every step | A Fable helper |
| Well-specified code: services, checks, tables, wiring, the second and later builds from a playbook | DeepSeek workhorse |
| GPU work: bakes, renders, ship recipe runs, bench captures in bulk | Codex on the PC once ChatGPT is back; until then a Fable helper drives the PC queue |
| Reference research, design text, outside checks of Fable-built changes | Muse |
| Picks, looks, money | Ryan |

Fable is never spent on bulk code, bakes, table edits or anything a playbook already covers.

## The tracks, in order

### 1. Battle effects (first)

| Step | Job | Seat | Waits on |
|---|---|---|---|
| Explosion route A or B on one sheet | 353 | Fable helper (running) | nothing |
| Ryan's pick of the route | decision 1 | Ryan | 353 |
| Effects start on the ship: attach point service | 370 | DeepSeek | nothing |
| Rebake every explosion by the picked route | 365 | Codex (GPU) | decision 1 |
| Shield options sheet: resting, hit, down side, at camera 170 | new, under 371 and 372 | Fable (Board), with Muse's reference notes | nothing |
| Shield model and surface, first build | 371, 372 | Fable helper | Ryan's shield pick |
| Trails, beams and flares: options sheet, then one kit | 367 | Fable options, then DeepSeek | decision on the sheet |
| Deaths in three beats to the staging table | 366 | DeepSeek build, Fable review | 365, 370 |
| Every faction readable at the played camera | 362 | Fable helper | the above, last |

Playbook: docs/playbooks/effects.md, started when the explosion route is picked. It holds the staging table's numbers, the
bake route, the bench rows for each moment, and the job template for "one more weapon" and "one more death".

### 2. Ships

| Step | Job | Seat | Waits on |
|---|---|---|---|
| Three-view concept standard, tried on C15s | 398 | Muse | nothing |
| Hard point contract: counts by hull class, break lines by faction theme | 363 | DeepSeek, to a Fable spec | nothing |
| Faction theme sheets: one page per faction (shape language, where guns sit, where it breaks, what it never has) | new | Fable (Board) | nothing |
| Ryan's pick of the second fleet for the finished battle | decision 2 | Ryan | the theme sheets |
| Concepts in three views for the finished battle's hulls | 276 | Muse's image models, Fable art direction | 398, decision 2 |
| Hulls through the recipe | tools/recipe | Codex (GPU) | concepts |
| Blob sweep of each hull, as pictures | docs/ship_pipeline/BLOB_SWEEP.md | Fable reviews, Ryan's eye | each hull |
| The station as a built set piece | 373 | Codex | the recipe proven on a second faction |

Playbook: docs/playbooks/ships.md. It starts from tools/recipe and PR 401, adds the concept standard, the hard point
contract and the theme sheets, and ends with the job template for "the next hull". The ship queue (36 hulls) is rolled out
from it by Codex, with Fable reviewing sweeps only.

### 3. Space and the board

| Step | Job | Seat | Waits on |
|---|---|---|---|
| Sky and backdrop strength: one sheet at half, as now, and near black, with ships and effects in frame | new | Fable (Board), from bench captures | nothing |
| Nebula and ion storm hexes with depth: two routes measured against the frame gate | 368 | Fable helper, PC | the sheet |
| Planet and rocks from real data, remixed: three options | 369 | Fable options, Codex build | nothing |
| Environment reconciliation and nebula motion | 230 | DeepSeek, to the picked look | 368 |

Playbook: docs/playbooks/space.md, with the frame gate numbers, the data sources and the remix rules ("Shouldn't be obvious
planets we know").

### 4. Screens (lighter)

The Briefing campaign map is being built on opus/issue-344 to contrib/opus/briefs/campaign_map_briefing.md (R165). When Ryan
has said yes to its captures, docs/playbooks/screens.md is written from it (the type ladder, the two colours, what goes
behind hover, the capture job), and the other screens become DeepSeek jobs from its template. The battle HUD question goes
to Ryan then.

### 5. Sound (lighter)

Ryan: "The sounds that I've heard from the game so far are bad" (R163). The Board owes him scope questions; the redo and
docs/playbooks/sound.md follow his answers.

## The playbook format (every playbook, same headings)

1. **Target**: the pictures to match and Ryan's own words about them.
2. **Inputs**: what must exist before you start.
3. **Steps**: numbered, with the exact job files and commands.
4. **The check that proves it**: bench rows, cameras, numbers, and what a pass looks like.
5. **Traps**: what went wrong before, each with its FINDINGS row.
6. **Worked example**: the pull requests that did it once.
7. **Job template**: the issue block to copy for the next item of this kind.
8. **Seat**: who runs it, and when to hand a picture back to the Board.

A playbook is done when a model that has never seen this repo ships the next item from it and the Board changes nothing.

## Budget and pacing

- The weekly Claude limit stood at 51 percent used at 14:36 UTC on Nov 10 and resets Saturday 18:00 CST. Ryan holds one more
  full Fable reset.
- The Board plus at most two Fable helpers at a time (R167, replacing R166's one-helper rule). A helper is started only for a
  row above that names a Fable seat.
- The Board tells Ryan when the limit is close. The spare reset is his to use; it buys the most when used with at least a
  day left before the Saturday reset.
- If the limit is hit with no reset used, nothing stops: DeepSeek, Muse and Codex keep running the rows that are theirs, and
  the Board's picks wait in LOOP.md.

## Decisions: made, and still owed (Nov 11 2026)

Made (his words are in FINDINGS):
1. Explosions: route B with flash plus hot core (R170). Rebaked and merged; "Explosions are looking much better" (R180).
2. The finished battle's fleets: Sunward against Eclipse (R180).
3. The campaign map: the Briefing layout over the real 3D scene (R165), the approach to the star, routes only, fight stops
   show the enemy, regions as scenery with a landmark and an emblem (R170, R174, R181). "I really like the new map approaches."
4. The interface look: the orders sheet (R176, R177), proven on the map's left rail; "Map first, then all": every other
   screen follows it. Rule: say less.
5. Sound scope: weapons, hits and deaths, buttons and menus, ambience, music; clean and tactical; never thin, cheesy or
   harsh (R171).
6. Flagship directions for Sunward, Hegemony and Eclipse (R180). The four leftover picks of issue 396 (R182).

Owed, in the order they will arrive:
1. Glasswrights, Hullbreakers and Chorus flagships (concept round 4), and the Eclipse ring cruiser.
2. The Sunward and Eclipse fleets (one sheet per class), then each built hull.
3. Death beats: the cruiser and capital deaths (issue 462), with the scene dim on a capital's death on or off.
4. The battle screen in the orders sheet look (options first where the layout is in question).
5. Shield look (from a shield options sheet). 6. Backdrop strength for battles (from a sky sheet). 7. Planet. 8. Trails,
   beams and flares. 9. The sound listening page.

