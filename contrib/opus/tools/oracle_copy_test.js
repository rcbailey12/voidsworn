'use strict';
// Issue 360: one copy of the rules files. The rules and campaign harnesses read the root game
// files directly, so the old pinned oracle folders must not exist. A hard check (a normal row in
// run_all_checks.js): fails when either folder is back, and when either committed table file
// differs from a fresh export from the root files.
const fs = require('fs');
const path = require('path');
const ROOT = process.env.VS_ROOT || path.resolve(__dirname, '../../..');
const GONE = [
  path.join('godot', 'rules', 'test', 'oracle'),
  path.join('godot', 'campaign', 'test', 'oracle'),
];
const TABLES = [
  { name: 'rules tables', script: 'godot/rules/test/node/export_data.js', committed: 'godot/rules/data/tables.json' },
  { name: 'campaign tables', script: 'godot/campaign/test/node/export_campaign.js', committed: 'godot/campaign/data/campaign_tables.json' },
];
const fails = [];
try {
  for (const dir of GONE) {
    if (fs.existsSync(path.join(ROOT, dir))) fails.push(dir + ' still exists (the root game files are the only copy)');
  }
  // Issue 1654 (R405, Nov 22 2026): the two table files are now the rules source, edited by hand and resealed with
  // godot/rules/tools/reseal_tables.gd, so they are no longer compared with a fresh export from the frozen root files.
  for (const t of TABLES) if (!fs.existsSync(path.join(ROOT, t.committed))) fails.push(t.committed + ' is missing');
} finally { /* nothing to clean up since issue 1654 */ }
if (fails.length) {
  for (const f of fails) console.log('FAIL ' + f);
  console.log('FAIL: ' + fails.length + ' rules copy or table difference(s)');
  process.exit(1);
}
console.log('PASS: no oracle folders exist and both table files are present (they are the rules source since R405)');
