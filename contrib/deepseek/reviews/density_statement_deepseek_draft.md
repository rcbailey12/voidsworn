# DRAFT - Battle-size density statement for Voidsworn (PC-only)

Model: DeepSeek, DeepThink ON, Search OFF. Filed verbatim from the DeepSeek chat report (chat titled "Density statement draft"); em dashes normalized to hyphens, wording otherwise unchanged. Both granted files (density_statement_brief.txt and CONVERSATION_CONTEXT.md) were attached to the chat; no fallback paste was needed. Process note from the run: existing session signed in as Ryan Bailey, no phone prompt. This draft is a proposal for the owner (Ryan) and for Opus, not a ruling.

DRAFT - not a ruling. PC-only. Nothing here is adopted until Ryan rules. OBSERVED (brief): a prior external draft's heavy-ship number is not Ryan's ruling and is excluded from this draft.

## 1. Density statement

OBSERVED (CONVERSATION_CONTEXT.md §6): Ryan ruled "PC-only in Babylon"; PC headroom goes to "graphics and effects quality, not to much larger battles"; target battle size stays "around 20 ships"; any growth is "modest and secondary." OBSERVED (§9): the feel mix is "BattleTech plus Sins of a Solar Empire 2 plus Rogue Trader space battles"; Rogue Trader supplies "small-fleet turn structure and per-activation decision weight," and "when a choice trades fleet size against per activation decision weight, take the decision weight." PROPOSED density statement (the sentence to quote): Voidsworn PC battles target about 20 ships total on board - PROPOSED reading, Ryan's call, not per side - with density measured as ships on board, activations per round, and decisions per activation, not ship count alone; growth beyond that target is modest, secondary, and allowed only if it passes the performance, readability, and wait gates below without reducing per-activation decision weight.

## 2. PROPOSED testable numbers

All numbers below are PROPOSED; none are adopted by this draft.

| Metric | PROPOSED number | One-line rationale |
| Total ships per battle: target | 20 total on board | PROPOSED operationalization of OBSERVED "around 20 ships"; "total on board" is a PROPOSED reading and Ryan's call. |
| Total ships per battle: hard ceiling | 24 total on board | PROPOSED modest cap above target; OBSERVED growth is "modest and secondary." |
| Per-side split | 10/10 target; 12/12 hard ceiling | PROPOSED symmetric default; asymmetric fights must stay within total and pass gates. |
| Capital/heavy count ceiling | 4 total; max 2 per side; count against total | PROPOSED; OBSERVED §9 cites "one to three player capital ships per battle," so heavies stay scarce. |
| Activations per round | 6-8 total across both sides at target; ≤10 at hard ceiling | PROPOSED; OBSERVED §9: "fewer, heavier activations beat many light ones." |
| Decisions per activation | 2-3 meaningful decisions | PROPOSED; OBSERVED §9 requires "per-activation decision weight"; meaningful = target/facing/system/boarding/officer choice. |
| Animation-wait budget per round | ≤12 s/round target; ≤15 s/round hard gate at target; ≤18 s/round at 24-ship ceiling | PROPOSED; OBSERVED brief: 6.6 rounds average and 95-120 s late-fight wait, so wait must be budgeted per round. |

## 3. Modest growth and gates

PROPOSED: "modest growth" means growth from 20 to no more than 24 total ships, with no increase in the capital/heavy ceiling, no increase in the activation ceiling, and no relaxation of the gates below.

- PROPOSED performance gate: Opus runs a scripted battle at 20 and 24 total ships on the PC reference profile; pass if 95th-percentile frame time at 24 is no more than 10% worse than at 20 and no sustained frame time falls below the project PC floor. Exact ms/hardware are code-truth items for Opus/Ryan, not asserted here.
- PROPOSED readability gate: at 24 total ships, default camera, paused, a reviewer can identify each side's capital/heavy ships, facing/firing arcs, and active critical/system states without tooltips or zoom within 5 seconds; fail if any require lookup.
- PROPOSED wait gate: at 24 total ships, measured animation wait is ≤18 s/round and total battle animation wait is ≤120 s across the OBSERVED 6.6-round average; at 20 ships, ≤15 s/round; fail if growth raises wait beyond the 20-ship baseline.

## 4. Difficulty dial interaction

OBSERVED (brief): the difficulty dial has 5 notches; admiral spread in sector 1 runs from 38% Grax to 98% Maren/Voice. PROPOSED: the density envelope is dial-invariant - total ships, per-side split, capital/heavy ceiling, activations/round, decisions/activation, and wait budget stay the same across all 5 notches. The dial may change decision pressure or enemy composition within those caps, but not raw density; gates run at every notch, with endpoint stress at the Grax 38% and Maren/Voice 98% ends. This does not re-litigate the dial itself.

## 5. Opus verification list

OBSERVED (§1): "Opus codes, verifies and orchestrates, and owns code truth." PROPOSED verification before any number is adopted:

- PROPOSED check: current spawn and fleet sizes, including actual total on board and per-side counts.
- PROPOSED check: how battles are composed - spawn rules, fleet templates, and scenario overrides.
- PROPOSED check: whether heavies/capitals exist as a distinct spawn class, and how they would count against total.
- PROPOSED check: current activation/decision measurement hooks and current animation-wait measurement per round, so the proposed gates are testable.

## Decisions Ryan must make

- PROPOSED decision: whether "about 20 ships" means total on board (PROPOSED reading) or per side.
- PROPOSED decision: whether heavies/capitals count against total, and at what ceiling.
- PROPOSED decision: whether to adopt target 20 / hard ceiling 24 total, with 10/10 target and 12/12 ceiling per side.
- PROPOSED decision: whether to adopt the capital/heavy, activation, decision, and wait numbers in the table.
- PROPOSED decision: whether the performance, readability, and wait gate thresholds are acceptable.
- PROPOSED decision: whether the density envelope should be dial-invariant across all 5 notches as proposed.
