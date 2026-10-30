# Telemetry spec for the Godot build (savings pass wave 5, Oct 29, 2026)

Merged version: the chair draft as amended by the DeepSeek and Qwen gap-check legs (both filed verbatim under contrib/deepseek/reviews/ and contrib/qwen/reviews/). Every amendment is listed at the end with its source leg. Chair proposal for Opus to verify and implement. Purpose: three designer rulings end with "revisit with actual play data," and play data does not exist unless the build logs it on purpose. This spec names the events, the fields, and the ruling question each event answers. It is written for the playtest phase (Ryan's own runs first, wider testing later), not as a live-service analytics design.

The three questions the log must be able to answer:

- Q-A, regroup tension (economy, ruled ACCEPT AS IS FOR NOW on Oct 29, 2026, revisit with play data): at post-boss regroups, does the player face a real allocation choice, or does the purse always cover everything? The sims said the tension binds in 0.0 percent of 60,000 modeled regroups (median worst-ship damage 19 HP against a median 737-credit purse). Play data either confirms that or shows where real play differs from the model.
- Q-B, Nemesis snowball (battle Q6, ruled MEASURE FIRST): does the Nemesis compound faster than the player across a run? Sims measure the code's growth rates now; play data measures what actually happens across meetings, including the Q5 loss-reveal (a lost meeting still teaches a weakness).
- Q-C, generational payoff (progression rulings, Oct 28): run 1 is near impossible by design and the loss rate near 80 percent is fine; the open question is whether upgrading within and across runs feels rewarding on the way to run 1 and run 5 completions, with the tree traces predicting a first tree pick around run 5 and a capstone around run 14 to 15.

## Shape

- Local only: one JSON object per line appended to a file under user:// (suggested user://telemetry/run_log.jsonl). No network, no account, no identifiers beyond a random install id generated once, so multiple playtesters' files can be merged later without names.
- Every event carries: v (schema version, start at 1), ts (unix seconds), session (random per launch), run (run id or null), run_number (the install's run ordinal: 1 for the install's first run, incrementing per run_start, persisted alongside the install id), and the event name. Sector, node and battle context ride on the events that have them.
- One emit function in the Godot campaign layer (emit(name, fields)) so adding an event is one line at the call site. The browser build's Copy report diagnostic is the precedent for getting the file back out; add a "copy telemetry" button beside it, or export the file with the save.
- Numbers are raw (credits, HP, CP, counts), never pre-aggregated; aggregation happens in analysis, so new questions do not need new instrumentation.
- Keep the log out of the save file itself (the importer fixtures and fuzz work treat saves as game state; telemetry is a side channel).

## Events

Run lifecycle:
- run_start: faction, admiral, meta snapshot (renown balance, mastery levels per admiral line, unlock state incl. whether the baked-in unlock was imported), starting credits.
- node_enter: sector, column, node type, node id.
- run_end: sector and column reached, cause (won, fleet destroyed, flagship lost, abandoned), battles fought, lessons named on the final debrief (count and ids), whether the nothing-learned line was shown.

Battle:
- battle_start: sector, node id, node kind (battle, elite, boss, nemesis), objective, map shape and map kind, player fleet (hull ids, CP total, fleetPower), enemy fleet (faction, hull ids, CP total, fleetPower), heat. fleetPower is the game's own fleetPower function output for each side; any change to that formula is a schema change under the versioning rule below, so cross-session comparisons stay valid.
- battle_end: result, rounds, player ships lost (hull ids), enemy ships lost, flagship damage taken, credits paid.

Nemesis (serves Q-B, and the Q5 implementation):
- nemesis_meeting: sector, nemesis id, meeting number this run, adaptations count at meeting start, weaknesses known count, weaknesses total.
- nemesis_adaptation: nemesis id, adaptation id applied, whether it clashed with a revealed weakness (the Q4 clash check should make this always false; the log proves it). The clash audit joins this event to the same run's earlier weakness_revealed events: the adaptation id names its category, and the revealed set at application time is exactly those earlier rows, so the boolean is fully checkable after the fact without duplicating the inputs on every event.
- weakness_revealed: nemesis id, weakness id, source (win, loss debrief, intel event, triggered in battle). The loss-debrief source existing at all is the Q5 acceptance check. There is exactly one Nemesis per run in the current design; the id is logged anyway so merged analysis never has to assume it.

Economy and the regroup (serves Q-A with the exact state the sims modeled):
- regroup_open: sector, trigger (post-boss), credits balance, per-ship missing HP for the whole fleet, repair price quoted per ship, upgrade offers (ids and prices), ships for sale (ids and prices).
- regroup_choice: what was bought (which ships' repair quotes were paid, upgrades, ships) and the balance after. Repairs are per-ship full quotes (the shipped design has no partial repair: a quote pays for the ship's full missing HP or is not bought), so the allocation is exactly reconstructable from regroup_open's quotes plus this list. Q-A is answered by joining regroup_open to regroup_choice: how often the purse could not cover the full menu.
- shop_visit and purchase: node type, item kind and id, price paid, priceMult in effect. (Also catches pricing anomalies like the capital-class fallback if one ever becomes purchasable.)

Progression (serves Q-C):
- xp_grant: admiral line, amount, source (battle, win bonus, Heat conversion with Heat points spent), shadow pool amount.
- level_up and tree_pick: admiral, level reached, pick id and branch/tier. Q-C reads: at which run number the first pick and the capstone land in real play, against the run 5 and run 14 to 15 predictions.
- boon_offer: offered ids with patron match (on/off) and rarity per pick, the picked id, decline-for-credits taken or not, and the credits granted when decline is taken. This is the play-data half of the Q7 check (offer distribution sims are the code half).
- relic_offer: offered ids, picked id. (Relics have no decline option; if players start wishing for one, relic_offer next to battle outcomes is where the pattern would show.)
- respec: admiral line, picks refunded, renown spent.

Debrief and learning frame:
- debrief_shown: lessons named (ids), core sync change, nemesis adaptation revealed or none, nothing-learned line shown or not. This fires per debrief, including mid-run debriefs (the Q5 loss debrief is one); run_end's lesson fields summarize the final debrief only, and analysis scripts should read debrief_shown for counts to avoid double-counting. This is the honesty-clause check (Oct 28 Q18): the screen must name a real lesson or say it learned nothing; the log records which happened.

## Analysis notes

- Each question above is answerable with a short script over the JSONL (the chair can write these against real files later; the wave 1 harness pattern applies).
- Schema changes bump v and are additive only during the playtest phase; if an event must change meaning, rename it instead.
- Volume is trivial (a run is hundreds of lines); no rotation or sampling needed at this scale.

## Deliberate diagnostic extras

Two events reach slightly past the three ruling questions, on purpose: relic_offer (relic acquisition patterns are cheap to capture now and expensive to retrofit) and the pricing-anomaly use of shop_visit and purchase (the capital-class price fallback defect is the standing example). Both legs flagged the reach; the chair keeps both events and owns the scope call here rather than letting it stay implicit.

## Not in scope

- No live analytics service, no crash reporting, no funnel tooling. Those are launch concerns; this spec exists so the ruled design questions have data when Ryan returns to them.
- No balancing decisions are made here; the log is how the already-ruled revisits get their evidence.

## Amendments from the gap-check legs (Oct 29, 2026)

DeepSeek's verdict was SPEC HAS GAPS (1 BLOCKER, 4 FIX); Qwen's was SPEC COMPLETE (7 NOTE). The legs agreed on the facts and split on severity in one place. Adopted into the text above:

1. run_number added to every event's envelope. Source: both legs (DeepSeek finding 1 as BLOCKER, Qwen finding 3 as NOTE). The draft carried only a run id while its own Q-C analysis promised run numbers; the chair rates it a required fix and buys the explicit field over Qwen's count-the-run_starts derivation, which silently resets if a file is ever cleared or trimmed.
2. Enemy fleetPower added to battle_start. Source: DeepSeek finding 2. The draft logged the metric for the player only; the measurement program used fleetPower throughout, so the comparison needs both sides.
3. Nemesis id added to nemesis_adaptation and weakness_revealed, with the one-Nemesis-per-run invariant stated. Source: DeepSeek finding 3.
4. The anti-clash audit join stated explicitly on nemesis_adaptation. Source: DeepSeek finding 4, adopted as a clarification rather than duplicated input fields: the revealed set is reconstructable from the same run's earlier weakness_revealed rows.
5. Repair wording settled on regroup_choice: per-ship full quotes, no partial repair exists in the shipped design, so allocation is reconstructable. Source: DeepSeek finding 5, resolved against the Oct 29 economy audit rather than by adding fields.
6. Decline credit amount added to boon_offer. Source: DeepSeek finding 6.
7. Sector and trigger added to regroup_open, and node id added to battle_start, so the Q-A filter and the meeting-to-battle join are explicit instead of sequential. Source: Qwen findings 1 and 2.
8. The debrief_shown versus run_end distinction stated (per-debrief versus final summary). Source: Qwen finding 4.
9. fleetPower pinned to the schema versioning rule. Source: Qwen finding 5.
10. relic_offer and the shop pricing-anomaly use marked as deliberate diagnostic extras. Source: Qwen findings 6 and 7, acknowledged rather than removed; DeepSeek's leg independently judged both small and justified.

Nothing else in either leg required a change: both confirmed the three questions are answerable from the amended spec, the boon coverage is complete, no field is impossible to emit, and the identifiers stay anonymous.
