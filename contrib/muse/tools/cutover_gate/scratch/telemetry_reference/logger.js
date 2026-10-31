"use strict";

// Reference event logger for the Voidsworn Godot telemetry spec
// (contrib/muse/reviews/telemetry_spec_2026_10_29.md, plus the Oct 30, 2026
// addendum at contrib/muse/reviews/telemetry_spec_addendum_2026_10_30.md).
//
// Produces spec-shaped envelopes: every event carries v, ts, session, run,
// run_number, and the event name (key: "event"; the spec lists the event name
// as part of every event without naming the key, so this logger picks the
// obvious one). Event-specific fields ride alongside, raw and unaggregated.
//
// The addendum's one new field, nemesis_lineage, is stamped on the three
// Nemesis events (nemesis_meeting, nemesis_adaptation, weakness_revealed)
// via emitNemesis, which refuses to emit a Nemesis event without it.

const SCHEMA_VERSION = 1;

const NEMESIS_EVENTS = new Set([
  "nemesis_meeting",
  "nemesis_adaptation",
  "weakness_revealed",
]);

function createLogger(options) {
  const opts = options || {};
  let clock = opts.startTs || 0;
  const tickSeconds = opts.tickSeconds || 60;

  const logger = {
    session: opts.session || "session",
    run: null,
    runNumber: null,
    records: [],

    // Mirrors the spec: run ids and the install's run ordinal are context,
    // set once per run and stamped on every event until changed.
    setRun(runId, runNumber) {
      this.run = runId;
      this.runNumber = runNumber;
    },

    setSession(sessionId) {
      this.session = sessionId;
    },

    // Deterministic timestamps keep the synthetic dataset reproducible.
    // A real implementation stamps unix seconds at emit time; ordering is
    // all the audits rely on.
    emit(event, fields) {
      clock += tickSeconds;
      const record = {
        v: SCHEMA_VERSION,
        ts: clock,
        session: this.session,
        run: this.run,
        run_number: this.runNumber,
        event: event,
      };
      Object.assign(record, fields || {});
      this.records.push(record);
      return record;
    },

    // Nemesis events must carry nemesis_lineage (addendum section 2.1).
    emitNemesis(event, lineage, fields) {
      if (!NEMESIS_EVENTS.has(event)) {
        throw new Error("emitNemesis used for non-Nemesis event: " + event);
      }
      if (!lineage) {
        throw new Error("Nemesis event " + event + " emitted without nemesis_lineage");
      }
      const stamped = Object.assign({}, fields || {}, { nemesis_lineage: lineage });
      return this.emit(event, stamped);
    },

    toJSONL() {
      return this.records.map((r) => JSON.stringify(r)).join("\n") + "\n";
    },
  };

  return logger;
}

module.exports = { createLogger, SCHEMA_VERSION, NEMESIS_EVENTS };
