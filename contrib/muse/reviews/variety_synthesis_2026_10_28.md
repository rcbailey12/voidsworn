Variety synthesis, Oct 28 program item 5 (do runs differ enough, run over run, to carry runs 1, 5, and 10). Chair synthesis of the DeepSeek, Qwen, and Argon (Gemini) blind legs, all pinned to main 264f441d, plus chair repair of a pack defect by direct code read. Verdicts and findings are observations for Opus to confirm, not orders.

## Verdict: RUNS DIFFER AT THE EDGES

Two legs returned RUNS DIFFER AT THE EDGES (DeepSeek, Argon). Qwen returned two complete responses (its UI presented a pair and neither was selected, so both were filed): Response 1 said RUNS CONVERGE, Response 2 said RUNS DIFFER AT THE EDGES. The chair weights Response 2 as the stronger reading of the same evidence, and the verdict follows the majority: the map, the sector conditions, and the faction layer genuinely vary; the battle layer inside a run converges on a small number of shapes.

## Chair erratum and the map evidence the legs could not see

The variety pack had a defect, owned by the chair: it labelled a campaign3d.js slice "map generation," but the generator (genSector) lives in core.js and the pack's core.js slice stopped before it. All three legs flagged the absence (Qwen made it a BLOCKER). The chair repaired it by reading genSector directly at the pin; what follows is the answer the legs were denied, and their map conclusions should be re-read against it.

1. Shape: 7 columns. Column 0 is a single node (a battle in sector 1, a shipyard thereafter); column 6 is the boss; column 5 is always a rest stop (shipyard, drydock, or field); columns 1 to 4 carry 2 to 4 nodes each. Middle-column node types roll battle .48, elite .13, event .17, shipyard .12, drydock .10, with rules that drydocks mostly convert away except pre-boss, at most one rest node per column, and every column keeps a fight. Guarantees: an elite in column 4, a shipyard in column 3, a rest in column 5.
2. Edges: each node links to its nearest node in the next column, plus a 45% chance of a second link; every next-column node is guaranteed at least one inbound link. Routing choices are real but the graph is shallow and convergent by construction.
3. Rewards are rolled at generation (n.rw) and shown on the map. The player routes with full information. (See the tension below.)
4. Battle texture: each battle or elite node rolls an archetype, swarm .25, heavy .22, carrier .15, and none .38. Node modifiers appear only from column 2 and are thin: bounty .14, veteran a further .12, battles only. The legs' shared read (3 archetypes times 2 modifiers is the real variety budget inside battles) is accurate, and if anything generous: 38% of fights roll no archetype at all.
5. The encounter axis the legs could not see at all: every fight node also rolls an encounter type and shape from 8 encounters, every column after the first guarantees at least one non-plain encounter, and adjacent fights in a column cannot share a type. Bosses deploy in line formation; other fights deploy line two times in three, flank one in three (campaign3d.js:54). This axis is doing more variety work than any leg credited, because none of them could see it.
6. Sector conditions: one per sector, drawn without replacement within a run from a pool of 5. The legs are right that this is the strongest per-run variety lever that exists.
7. Patron draw: 4 of 6 cores per run, pure shuffle, no faction weighting (core.js ensurePatrons, also set at newRun).

## Where the legs converge

Starting fleets are fixed per admiral, so run openings converge until mastery unlocks alternate fleets. Heat is difficulty, not variety: it changes pressure, not content, and all three legs refuse to count it as variety (this is the factual floor under Argon's loop-leg proposal to rebuild Heat as a content ladder). Sector conditions are real variety. And run 5 freshness, such as it is, rests overwhelmingly on switching faction or admiral, which is the player manufacturing variety the generator does not provide.

## Exposure accounting (Argon's estimate, screened)

Argon estimated what fraction of each content pool a single run exposes: about 50% of aspects, 67% of cores (chair note: exactly 4 of 6 by the patron draw), 60% of sector conditions (3 of 5, without replacement, so this one is exact), 100% of archetypes and node modifiers, and nearly all 8 encounters per run. DeepSeek cautioned that it had no node counts to audit exposure claims against. The chair's genSector read supports Argon's shape: with roughly 25 to 30 fight nodes in a run and the encounter guarantees above, a player plausibly meets most encounter types every run, and certainly every archetype. Consequence: content novelty is exhausted early; what varies late is combination and route, not inventory. Variety at run 10 is combinatorial or it is absent.

## The pivot question (Argon, the item's sharpest single finding)

Argon's variety leg argued that the offer system's kit filtering (see the rewards synthesis: offers are drawn from what the current build can use) means a build can only deepen, never pivot: once the run commits to a patron and a shape, every subsequent offer reinforces it. Its designer question deserves to survive verbatim in spirit: should one offer slot per screen be reserved as a pivot slot, drawn from outside the current build's kit, so a run can change its mind at a price? The chair notes this interacts with the rewards synthesis finding that the legendary assignment can overwrite a duo in the third slot; the offer screen's slot discipline is becoming a theme across items.

## A genuine tension, surfaced not settled

DeepSeek's variety leg asked whether node reward labels should be partly hidden, to restore exploration. The loop legs list visible routing as a protect item: the game's planning pleasure depends on routing with full information. Both are right about different goods (exploration vs planning), and the chair does not paper over it. If the designer ever wants a middle position, hiding rewards only on event nodes (the one node type whose content is already a gamble) is the smallest version of DeepSeek's idea that leaves the protect list intact. That is a chair suggestion, not a leg finding.

## Schema note (observation for Opus)

Hull variants carry a fit-slots field (FIT_SLOTS) that exists in the data schema with no mechanical consumer found by the legs or the chair. Filed as an observation only: it connects to the Oct 26 customization brainstorm's reserve list (schema items worth reserving now for possible flagship-layer customization later). It is not a scope change and not a finding against the current game; unexamined schema is how future options stay cheap.

## Run 1 / Run 5 / Run 10

RUN 1: Variety is the least of run 1's problems; everything is new once. The fixed starting fleet means the opening is identical on every retry until mastery intervenes, which matters by run 3, not run 1.

RUN 5: The exposure math lands here. By run 5 the player has seen every archetype, modifier, condition, and nearly every encounter; freshness is coming from faction and admiral switches (six factions, four admirals each) and from mastery alternate fleets, i.e., from the player's own rotation discipline. If the designer wants run 5 freshness to be the game's job rather than the player's, the variety budget has to grow in the battle layer (archetypes and modifiers), not the map layer, which is already doing its share.

RUN 10: Combinatorial variety only: routes, conditions in combination, faction-admiral-core permutations. That is a legitimate long tail for this genre, but it is finite, and it is the factual basis for Argon's loop argument that the late game needs a content ladder (new conditions, new Nemesis behaviors) rather than more numbers.

## Questions for the designer (collected, per program rules)

1. The pivot slot: should one slot in each boon offer be reserved for an off-kit option, so builds can pivot mid-run at an opportunity cost? (Argon)
2. Reward labels: full information everywhere (protecting the planning game), or hidden on event nodes only (buying a little exploration back)? (DeepSeek vs the loop protect list; the chair's middle version is above.)
3. Should the battle-layer variety budget (archetypes beyond three, node modifiers beyond two) grow before launch, accepting the encounter axis already carries more than players will credit it for?

## Addendum: designer rulings (Oct 28, 2026)

(1) The pivot slot: RULED against (chair reading of the designer's answer, flagged to him for correction). He endorsed the deepening model: kit-filtered offers plus RNG in what is offered, building run on run, is what makes each run feel unique. No reserved off-kit slot. (2) Reward labels: RULED, hidden on event nodes only (the chair's middle version); full information everywhere else, protecting visible routing. (3) Battle-layer variety budget: RULED deferred. Factions, build types, and admirals carry variety for now; growing archetypes and modifiers waits, with the Godot playtest the natural revisit point.
