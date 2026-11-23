'use strict';

const fs = require('fs');
const path = require('path');
const { gunzipSync } = require('zlib');

const resultsFile = path.join(__dirname, '..', 'map_trial_cases.json.gz');
const pinFile = path.join(__dirname, 'map_trial_pinned.json');
const fixtures = JSON.parse(gunzipSync(fs.readFileSync(resultsFile)).toString('utf8'));
const caseKey = ({ enc, seed }) => enc + '|' + seed;

// Copy the fleet snapshots from the reviewed Godot results. For an approved
// fleet change, map_trial_test.gd -- update refreshes the results and the pin.
if (process.argv.includes('--pin')) {
  const cases = {};
  for (const fixture of fixtures) {
    const { shape, arena, units } = fixture.expected;
    cases[caseKey(fixture)] = { shape, arena, units };
  }
  const pin = {
    revision: 'Godot rules (map_trial_test.gd -- update)',
    note: 'Fleets the map trial expects. A deliberate fleet change refreshes this pin with --pin.',
    cases,
  };
  // Godot stores the whole-number snapshot values with a trailing .0.
  const json = JSON.stringify(pin, (_key, value) =>
    Number.isInteger(value) ? JSON.rawJSON(value.toFixed(1)) : value);
  fs.writeFileSync(pinFile, json + '\n');
  console.error('pinned ' + fixtures.length + ' map trial fleets from the saved Godot results');
} else {
  const pin = JSON.parse(fs.readFileSync(pinFile, 'utf8'));
  for (const fixture of fixtures) {
    fixture.pinned = { revision: pin.revision, ...pin.cases[caseKey(fixture)] };
  }
  process.stdout.write(JSON.stringify(fixtures));
}
