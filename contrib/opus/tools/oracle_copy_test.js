'use strict';
// Issue 360: one copy of the rules files. The rules and campaign harnesses read the root game
// files directly, so the old pinned oracle folders must not exist. A hard check (a normal row in
// run_all_checks.js): fails when either folder is back, and when either committed table file
// differs from a fresh export from the root files.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
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
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'oracle-copy-test-'));
try {
  for (const dir of GONE) {
    if (fs.existsSync(path.join(ROOT, dir))) fails.push(dir + ' still exists (the root game files are the only copy)');
  }
  const env = { ...process.env };
  delete env.VS_ORACLE;
  TABLES.forEach((t, i) => {
    const fresh = path.join(tmp, 'fresh_' + i + '.json');
    const r = spawnSync(process.execPath, [path.join(ROOT, t.script), fresh], { cwd: ROOT, env, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
    if (r.status !== 0) {
      const detail = ((r.stderr || '') + (r.stdout || '')).trim().split(/\r?\n/).slice(-3).join(' | ');
      fails.push('fresh export of ' + t.name + ' failed: ' + detail);
      return;
    }
    const committedPath = path.join(ROOT, t.committed);
    if (!fs.existsSync(committedPath)) { fails.push(t.committed + ' is missing'); return; }
    const committed = JSON.parse(fs.readFileSync(committedPath, 'utf8'));
    const freshJson = JSON.parse(fs.readFileSync(fresh, 'utf8'));
    if (committed.sha256 !== freshJson.sha256) {
      fails.push(t.committed + ' differs from a fresh export (committed ' + committed.sha256 + ', fresh ' + freshJson.sha256 + '; run node ' + t.script + ' ' + t.committed + ')');
    }
  });
} finally {
  fs.rmSync(tmp, { recursive: true, force: true });
}
if (fails.length) {
  for (const f of fails) console.log('FAIL ' + f);
  console.log('FAIL: ' + fails.length + ' rules copy or table difference(s)');
  process.exit(1);
}
console.log('PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files');
