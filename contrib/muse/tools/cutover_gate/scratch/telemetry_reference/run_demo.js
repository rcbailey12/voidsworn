"use strict";

// Demonstration runner: builds the synthetic two-run dataset with the
// reference logger, writes it to dataset.jsonl, then runs both clash
// audits against it and scores them against the dataset's ground truth.
//
// Expected outcome (see dataset.js for the story):
//   - OLD same-run join: misses the Q4 violation (false negative) on
//     adapt_rear_screen, because the weakness it counters was revealed in
//     run 1 and the old join only looks inside run 2.
//   - NEW lineage join: catches adapt_rear_screen, and stays clean on
//     adapt_ion_plating (no false positive).
//
// Exit code is 0 only if both audits behave exactly as expected.

const fs = require("fs");
const path = require("path");
const { buildDataset, EXPECTED } = require("./dataset");
const { oldJoinAudit, newJoinAudit } = require("./audit");

function verdictLabel(row, expected) {
  if (row.clash === expected) return "correct";
  if (expected && !row.clash) return "FALSE NEGATIVE (violation missed)";
  return "FALSE POSITIVE (clean adaptation flagged)";
}

function printAudit(title, rows) {
  console.log(title);
  for (const row of rows) {
    const expected = EXPECTED[row.adaptation_id];
    console.log(
      "  " +
        row.adaptation_id +
        " (run " + row.run_number + ")" +
        ": counters " + row.countered_weakness +
        ", revealed set size " + row.revealed_count +
        ", clash = " + row.clash +
        ", ground truth = " + expected +
        " -> " + verdictLabel(row, expected)
    );
  }
  console.log("");
}

function main() {
  const records = buildDataset();
  const outPath = path.join(__dirname, "dataset.jsonl");
  fs.writeFileSync(outPath, records.map((r) => JSON.stringify(r)).join("\n") + "\n");
  console.log("Wrote " + records.length + " events to " + outPath + "\n");

  const oldRows = oldJoinAudit(records);
  const newRows = newJoinAudit(records);

  printAudit("OLD audit (spec as filed: same-run join)", oldRows);
  printAudit("NEW audit (addendum: lineage join)", newRows);

  const oldMissed = oldRows.some(
    (r) => EXPECTED[r.adaptation_id] && !r.clash
  );
  const oldFalsePositive = oldRows.some(
    (r) => !EXPECTED[r.adaptation_id] && r.clash
  );
  const newAllCorrect = newRows.every((r) => r.clash === EXPECTED[r.adaptation_id]);

  console.log("Summary:");
  console.log("  Old join missed the inherited-weakness violation: " + oldMissed);
  console.log("  Old join raised a false positive: " + oldFalsePositive);
  console.log("  New join verdicts all match ground truth: " + newAllCorrect);

  if (oldMissed && !oldFalsePositive && newAllCorrect) {
    console.log("\nDEMONSTRATION PASSES: the old join has the defect, the lineage join fixes it.");
    process.exit(0);
  }
  console.log("\nDEMONSTRATION FAILED: results differ from the expected pattern.");
  process.exit(1);
}

main();
