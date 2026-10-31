"use strict";

// Synthetic two-run dataset, built to the exact shape of the clash-audit
// defect described in the telemetry spec addendum (section 1).
//
// Story, following the Q5 ruling (a lost Nemesis meeting still teaches a
// weakness on the loss debrief) and the Q4 rule (an adaptation may not
// directly counter a revealed weakness):
//
//   Run 1: the player meets the Nemesis and loses. The loss debrief reveals
//   the weakness "weak_rear_arc". The run ends later without the player ever
//   beating that Nemesis.
//   Run 2: the SAME Nemesis (same nemesis_lineage) returns. The run 1 reveal
//   is inherited knowledge. The Nemesis applies two adaptations:
//     - adapt_rear_screen, which counters weak_rear_arc. The weakness was
//       revealed (in run 1), so this is a true Q4 violation.
//     - adapt_ion_plating, which counters weak_ion_sensitivity. That
//       weakness was never revealed in this lineage, so this is clean.
//
// Ground truth the audits are scored against lives in EXPECTED below, keyed
// by adaptation id. The logged "clashed" boolean on each nemesis_adaptation
// is false for both adaptations, as it would be if the runtime check shared
// the same blind spot; the audits recompute from weakness_revealed rows and
// never trust the logged value (addendum section 2.2).

const { createLogger } = require("./logger");

// Adaptation id -> the weakness id its category counters. In real analysis
// this relation comes from game data (the adaptation id names its category);
// it is pinned here so the synthetic expected outcomes are exact.
const ADAPTATION_COUNTERS = {
  adapt_rear_screen: "weak_rear_arc",
  adapt_ion_plating: "weak_ion_sensitivity",
};

const EXPECTED = {
  adapt_rear_screen: true, // counters a revealed weakness: Q4 violation
  adapt_ion_plating: false, // counters an unrevealed weakness: clean
};

const NEMESIS_ID = "nem_vex";
const LINEAGE = "nl_4f8c2a";

function buildDataset() {
  const log = createLogger({ session: "sess_run1", startTs: 1761900000, tickSeconds: 60 });

  // ---- Run 1: lost meeting, loss debrief teaches a weakness. ----
  log.setRun("run_0001", 1);
  log.emit("run_start", {
    faction: "sunward",
    admiral: "adm_halden",
    renown: 0,
    starting_credits: 120,
  });
  log.emitNemesis("nemesis_meeting", LINEAGE, {
    sector: 2,
    nemesis_id: NEMESIS_ID,
    meeting_number: 1,
    adaptations_count: 0,
    weaknesses_known: 0,
    weaknesses_total: 2,
  });
  log.emit("battle_start", {
    sector: 2,
    node_kind: "nemesis",
    player_cp: 18,
    enemy_cp: 24,
  });
  log.emit("battle_end", { result: "loss", rounds: 7, player_ships_lost: ["h_covenant"] });
  // The Q5 loss debrief reveal. Source value is the spec's own enum entry.
  log.emitNemesis("weakness_revealed", LINEAGE, {
    nemesis_id: NEMESIS_ID,
    weakness_id: "weak_rear_arc",
    source: "loss debrief",
  });
  log.emit("run_end", {
    sector: 2,
    cause: "fleet destroyed",
    battles_fought: 5,
    lessons_named: 1,
    nothing_learned_shown: false,
  });

  // ---- Run 2: same Nemesis lineage, knowledge inherited. ----
  log.setSession("sess_run2");
  log.setRun("run_0002", 2);
  log.emit("run_start", {
    faction: "sunward",
    admiral: "adm_halden",
    renown: 40,
    starting_credits: 120,
  });
  log.emitNemesis("nemesis_meeting", LINEAGE, {
    sector: 2,
    nemesis_id: NEMESIS_ID,
    meeting_number: 1,
    adaptations_count: 0,
    // Lineage-cumulative per addendum section 2.3: the run 1 reveal counts.
    weaknesses_known: 1,
    weaknesses_total: 2,
  });
  // The violation: counters the weakness revealed in run 1.
  log.emitNemesis("nemesis_adaptation", LINEAGE, {
    nemesis_id: NEMESIS_ID,
    adaptation_id: "adapt_rear_screen",
    clashed: false,
  });
  // The clean one: counters a weakness this lineage never revealed.
  log.emitNemesis("nemesis_adaptation", LINEAGE, {
    nemesis_id: NEMESIS_ID,
    adaptation_id: "adapt_ion_plating",
    clashed: false,
  });
  log.emit("battle_start", {
    sector: 2,
    node_kind: "nemesis",
    player_cp: 26,
    enemy_cp: 27,
  });
  log.emit("battle_end", { result: "win", rounds: 9, player_ships_lost: [] });
  log.emit("run_end", {
    sector: 3,
    cause: "abandoned",
    battles_fought: 8,
    lessons_named: 1,
    nothing_learned_shown: false,
  });

  return log.records;
}

module.exports = { buildDataset, ADAPTATION_COUNTERS, EXPECTED, NEMESIS_ID, LINEAGE };
