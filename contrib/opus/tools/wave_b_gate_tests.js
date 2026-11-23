'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const manifest = require('../sound/elevenlabs_pilot_v2.json');
const plan = fs.readFileSync(path.join(__dirname, '../plans/cohesive_audio_v2.md'), 'utf8');

assert.match(manifest.note, /Wave B stays held until Wave A3 clears Ryan's ear check\./);
assert.doesNotMatch(manifest.note, /Wave B[^.]*until Wave A2/);
const command = plan.split(/\r?\n/).find(line => line.includes('--max-credits 9600'));
assert.match(command, /after Wave A3 clears Ryan's ear check/);
const history = /### Historical Wave A2 Calibration Command([\s\S]*?)(?=^## 8\.)/m.exec(plan);
assert.ok(history, 'the Wave A2 recipe is labeled historical');
assert.match(history[1], /manifest at commit `[a-f0-9]{40}`/);
assert.match(history[1], /--list <wave_a2_manifest_from_pinned_commit>/);
console.log('PASS wave_b_gate_tests: the plan and manifest require the A3 ear check, and the A2 recipe is pinned');
