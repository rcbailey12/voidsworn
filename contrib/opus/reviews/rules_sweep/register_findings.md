# Rules sweep, leg A: the findings log (issue 493)

Source: contrib/opus/FINDINGS.md at main 156236a (ends at R190). Every one of its 310 table rows has at least one entry in register_findings.json, checked by script. Rows that hold several rules are split (R76a, R76b and so on). Rows that only record a fact or finished work have one entry with rule "record only" and verdict KEEP. There is no R139 in the log. Verdicts are drafts for the Board. The source has no em or en dashes, so no quote was changed. Quotes are copied exactly, including the source's own spelling ("artifically restricing" in R190).

**Totals:** 310 rows read, 514 entries, of which 119 are record only.

## Counts by verdict

| Verdict | Entries |
|---|---|
| KEEP | 389 |
| KEEP AND ADD THE REASON | 11 |
| REWORD TO ITS PURPOSE | 20 |
| RETIRE | 89 |
| ASK RYAN | 5 |

Most RETIRE entries are spent one-off decisions (the engine test, the old Pyre-Barge rounds, old seat and usage rules) or rulings that Ryan himself replaced later. They go to the archive as history, with nothing to ask him.

## Counts by area

| Area | Entries |
|---|---|
| agents and process | 103 |
| rules of play | 81 |
| ship build pipeline | 51 |
| PC and tools | 49 |
| battle look | 45 |
| ships and concepts | 41 |
| screens and UI | 35 |
| map | 34 |
| lore and names | 28 |
| campaign | 22 |
| movement | 16 |
| battle sound | 9 |

## The twenty most restrictive for the least reason (ranked)

1. **R76a**: "Thruster puffs only on turns, no side-to-side shuffle." Ryan re-read it in R189, but contrib/opus/briefs/movement_spec.md line 7 still says it, plus "no flip-and-burn". This is the rule that cost braking burns and slides.
2. **R49d**: The flash counter (0.12 s merge, 3 a second) counts small and dim flashes that the WCAG guideline it cites would not count. Every hit and light size was tuned just under it (R187). Keep the comfort limit and fix the counting.
3. **R64c**: "Flip-and-burn stays off". A bare ban with no reason, and R189 says braking belongs wherever a ship would need it. ASK RYAN.
4. **R131b**: Movement caps from the spec (bank at most 4 degrees, a 7 s move cap, fixed build and bleed distances). These describe the shipped glide and nobody chose them by eye. They should be tuning values, not caps.
5. **R164d / check_export.py**: Ryan ruled that the hard point count is not fixed, but tools/recipe/check_export.py still fails any hull without exactly six breach anchors. An automatic check enforces a number he ruled out (Codex leg 496).
6. **R79b**: The backdrop rock cap (0.05 rad, planets 4.4 times wider) is enforced by asserts in godot/world/world.gd. The numbers are Muse's; R124 gives the real purpose (scale coherence). ASK RYAN.
7. **R123a**: "The camera is never taken for a capital death." Bans the most cinematic moment and records no reason. ASK RYAN.
8. **R99b**: "Capital hulls break on two transverse lines plus one longitudinal": the straight, even cut R186 rejected.
9. **R98b**: AGENTS.md says "two or three authored break lines" for every hull; factions.md now sets 1 to 4 by class. A fixed count in the agent file.
10. **R172b**: Concept gate lines for symmetry and fixed proportions per class. Symmetry fights the Hullbreaker exception and R180's lopsided outline, and one gate line (R176c) already made every flagship alike.
11. **R147**: A 90 percent outline overlap gate. It passed a hull whose front was wrong (R157 finding 13); the score should be reported, not a bar.
12. **R30a**: A 0.5 s enemy-think bar, still quoted as a bar (G-12). Ryan accepted longer enemy turns in R64 and R67.
13. **G-1**: Ship draw scale 1.6x class length, a Claude call that sets how big every ship looks. R157 found ships are only 60 to 200 px at the play camera.
14. **R90b**: Death effort budget fixed to the first 2 seconds and a 14 s cheap tail. These are Muse numbers; the deaths playbook's three beats should set timing.
15. **R82a**: A fixed violet nebula family with faction tint capped at about 25 percent. R174 lists indigo to purple gradients among the AI tells.
16. **R141**: "Solid or frosted backing behind all text." Ryan relaxed it for the map (R165) and later named frosted glass as an AI tell (R174).
17. **R136b**: Two text floors in force: 12 px (UI spec, screens.md) and 17 px (R176 rail). State one rule by purpose.
18. **R3b**: "Interface shield bars stay cyan." A colour rule with no reason, written before both UI redesigns. ASK RYAN.
19. **R6b**: "No viewer panels." Three words, no reason, unclear scope. ASK RYAN.
20. **R62c**: "Battles start zoomed out (no edge indicators)." No reason recorded. Keep it, but the Board should add the reason before the rulebook.

## Contradiction pairs

- R54b (real thrusters, RCS sidesteps) against R76a (puffs only on turns, no shuffle): settled by R189 for R54b's purpose.
- R189 (thrusters on braking, smooth slides) against contrib/opus/briefs/movement_spec.md line 7 (R131a): LIVE: the spec still states the old letter.
- R16a ("fire and other damage") against R88b (fire "wrong for space", flash and snuff out): settled by R88b and R158.
- R79a (procedural planets, no photo textures) against R163b (real NASA and USGS data, remixed): settled by R163b.
- R92 (old C19_51 concept outdated) against R180b (back to the original concept, "much stronger"): settled by R180b; Ryan reversed himself.
- R183d (scrap every Glasswright crystal and prism route) against R184a and R185b (G9 wedge stays; Mirror Deck made prismatic): settled by the later rows.
- R169b (Eclipse ships keep green) against lore_bible_r8.md Eclipse ship colour line (white-gold corona, violet-white glow): settled by R169b; the bible line needs a note.
- R164d (no fixed hard point count) against tools/recipe/check_export.py (exactly six hp_breach anchors): LIVE in code.
- R98b as written in AGENTS.md ("two or three" break lines) against docs/playbooks/factions.md (1 to 4 by class): LIVE in docs.
- R99b (two transverse plus one longitudinal break line) against R186 (no straight line across the hull, uneven pieces): LIVE tension.
- R141 (backing behind all text) against R165b (plain text with a halo on the map) and R174c (frosted glass is an AI tell): LIVE wording.
- R149 (lime is the one accent) against R176a (ember replaces neon lime, for every screen): LIVE: docs/playbooks/screens.md still says lime.
- R136b (text floor 12) against R176a (nothing read below 17 px at 1080): LIVE: two floors.
- F2 and F4 (12 s round target, 15 s limit) against R64b (both retired): settled by R64; the old rows still read as decided.
- R172b (symmetry gate line) against AGENTS.md Hullbreaker exception and R180b (stepped lopsided outline): LIVE tension.
- R123a (camera never taken for a capital death) against R136 finding MN6 (Key moments cut-ins take the camera for capital kills): LIVE in code.
- R159a (real screenshots, no mockup step) against R176a (the readability pass was done as a mockup): settled by R176.
- R25 (concepts are inspiration, nothing bent to match) against R140, R145, R147 (hull scored against the concept): settled by R169 (old concepts are history) and R156 (the score never bends the guns).
- R11a (go-forward-plan.md is the approved plan; CLAUDE.md still says so) against R167b (docs/playbooks/PROGRAM.md is the plan): LIVE in CLAUDE.md.
- D3 (AGENTS.md names barge_v15.py as the live worked example) against R150a and R158 (the recipe is the route; the old barge is retired): LIVE in AGENTS.md.

Rules whose only stated reason is another rule: R60a ("relic" is a lore bible never-say word), D4 (R3), D5 (R111), K1c (R3), R169e (R49). None looks harmful while the parent rule stands.

## ASK RYAN (his own calls the leg would change)

**R3b** (contrib/opus/FINDINGS.md line 28 (row R3)). Rule: Shield bars in the interface stay cyan.
- His words: none in the row (his ruling is recorded without his words)
- Why ask: A bare colour rule with no reason, written before both UI redesigns. Ask whether shields still need their own fixed colour on screen.
- Proposed: Shield state on every screen uses one colour reserved for shields and nothing else, chosen in the current UI palette (screens.md), so shields read the same everywhere.

**R6b** (contrib/opus/FINDINGS.md line 31 (row R6)). Rule: No viewer panels.
- His words: none in the row (his ruling is recorded without his words)
- Why ask: A bare three-word prohibition with no reason and an unclear meaning. Ask what it guarded against before carrying it.
- Proposed: Ryan judges from screenshots and sheets sent to him; he is never asked to open a viewer or debug panel to check work.

**R64c** (contrib/opus/FINDINGS.md line 92 (row R64)). Rule: Flip-and-burn stays off.
- His words: none in the row (his ruling is recorded without his words)
- Why ask: A bare prohibition with no reason written down. R189 says braking thrusters belong wherever a ship in space needs them; a flip-and-burn on long moves may be exactly that. Ask before the movement fixes are picked.
- Proposed: No flip-and-burn on ordinary moves, where it would make ships spin about; a big hull may turn and burn to brake only on a long move where it reads as space flight and stays smooth.

**R79b** (contrib/opus/FINDINGS.md line 107 (row R79)). Rule: Strict rock cap: no single backdrop rock wider than 0.05 rad, planets at least 4.4 times wider.
- His words: none in the row (his ruling is recorded without his words)
- Why ask: Ryan "picked" it from a Muse pack, but the numbers are Muse's. R124 names the purpose. Ask him to let the purpose replace the numbers.
- Proposed: Backdrop rocks never read as bigger than a planet or as looming over the fleet; size is judged on the loom turntable at the battle camera, and the code assert only guards the turntable's chosen value.

**R123a** (contrib/opus/FINDINGS.md line 151 (row R123)). Rule: The camera is never taken for a capital death; punch and slow motion are the only accents (reopens only if deaths read flat).
- His words: none in the row (his ruling is recorded without his words)
- Why ask: The cinematic audit (R187) asks for more cinematic battles; this bans camera moves for the biggest moments with no reason written. Ask whether it was about comfort or control.
- Proposed: The player keeps control of the camera during a capital death; any cinematic accent must be short, never block input, and be switchable off with reduce motion.

Ryan's calls that were already reworded by Ryan himself (R76a by R189, R141 by R165 and R174, R149 by R176) are marked REWORD or RETIRE without a new question.

## Could not be determined from the log alone

- Whether some UI colour rules (R3b, F6a, F12, R125b) still match the game after the ember look; the code was not read for each.
- Whether R74c's Nemesis ring survives on the Briefing map.
- Whether R82e (static kit parts merged at export) holds in tools/recipe.
- Whether G-1's 1.6x draw scale is still in the code.
- Reasons for R62c, R78b and R80b: none recorded anywhere in the log.
