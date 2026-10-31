"use strict";

// The two clash audits, old and new, exactly as defined in the spec and in
// the Oct 30, 2026 addendum.
//
// OLD (spec as filed, nemesis_adaptation bullet and amendment 4): the
// revealed set at application time is the same run's earlier
// weakness_revealed rows. "Same run" is the envelope's run id.
//
// NEW (addendum section 2.2): the revealed set is every weakness_revealed
// row with the same nemesis_lineage and an earlier timestamp, across all
// runs and sessions.
//
// Both audits recompute the clash from weakness_revealed rows and ignore
// the boolean logged on the nemesis_adaptation event (addendum 2.2: the
// audit does not trust the logged value).

const { ADAPTATION_COUNTERS } = require("./dataset");

function revealedSet(events, adaptationEvent, scope) {
  const revealed = new Set();
  for (const e of events) {
    if (e.event !== "weakness_revealed") continue;
    if (e.ts >= adaptationEvent.ts) continue; // must be strictly earlier
    if (scope === "run") {
      if (e.run !== adaptationEvent.run) continue;
    } else if (scope === "lineage") {
      if (e.nemesis_lineage !== adaptationEvent.nemesis_lineage) continue;
    } else {
      throw new Error("unknown audit scope: " + scope);
    }
    revealed.add(e.weakness_id);
  }
  return revealed;
}

// Returns one verdict row per nemesis_adaptation event in the log:
// { adaptation_id, run, countered_weakness, clash, revealed_count }.
function clashAudit(events, scope) {
  const rows = [];
  for (const e of events) {
    if (e.event !== "nemesis_adaptation") continue;
    const countered = ADAPTATION_COUNTERS[e.adaptation_id];
    const revealed = revealedSet(events, e, scope);
    rows.push({
      adaptation_id: e.adaptation_id,
      run: e.run,
      run_number: e.run_number,
      countered_weakness: countered || null,
      revealed_count: revealed.size,
      clash: countered ? revealed.has(countered) : false,
    });
  }
  return rows;
}

function oldJoinAudit(events) {
  return clashAudit(events, "run");
}

function newJoinAudit(events) {
  return clashAudit(events, "lineage");
}

module.exports = { oldJoinAudit, newJoinAudit, revealedSet };
