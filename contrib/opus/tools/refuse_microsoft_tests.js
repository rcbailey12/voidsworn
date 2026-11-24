'use strict';
// Issue 2025 (PR 2020): the API arms twice committed a stray Microsoft/Windows/PowerShell/ModuleAnalysisCache.
// This row runs work_issue.ps1's own Refuse-Reason on staged paths, and checks the root .gitignore names the folder.
// Auto-discovered by run_all_checks.js (every *_tests.js here runs).
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const root = path.join(__dirname, '../../..');
const lines = fs.readFileSync(path.join(root, 'tools/pc/work_issue.ps1'), 'utf8').split(/\r?\n/);
const start = lines.findIndex(l => l.startsWith('function Refuse-Reason('));
assert.ok(start >= 0, 'work_issue.ps1 defines Refuse-Reason');
const end = lines.findIndex((l, i) => i > start && l === '}');
assert.ok(end > start, 'Refuse-Reason ends at a closing brace in column 0');
const fn = lines.slice(start, end + 1).join('\n');
const ignore = fs.readFileSync(path.join(root, '.gitignore'), 'utf8').split(/\r?\n/);
assert.ok(ignore.includes('/Microsoft/'), 'the root .gitignore ignores /Microsoft/');
const ps = process.env.PC_TEST_POWERSHELL || (process.platform === 'win32' ? 'powershell.exe' : 'pwsh');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'refuse microsoft '));
// status, path, refused?
const rows = [
  ['A', 'Microsoft/Windows/PowerShell/ModuleAnalysisCache', true],
  ['M', 'Microsoft/Windows/PowerShell/ModuleAnalysisCache', true],
  ['A', 'microsoft/anything.txt', true],
  ['A', 'Microsoft/x', true],
  ['A', 'godot/gen/x.bin', true],
  ['A', 'docs/Microsoft/notes.md', false],
  ['A', 'MicrosoftNotes/readme.md', false],
  ['A', 'tools/pc/work_issue.ps1', false],
];
const lineOf = ([st, p]) => `${st}|${p}`;
fs.writeFileSync(path.join(tmp, 'rows.txt'), rows.map(lineOf).join('\n') + '\n');
fs.writeFileSync(path.join(tmp, 'run.ps1'), fn + `
$repo = $args[1]
foreach ($l in [IO.File]::ReadAllLines($args[0])) {
  if ($l -eq '') { continue }
  $st, $p = $l.Split([char]'|', 2)
  $why = Refuse-Reason $st $p $repo 100
  [Console]::Out.WriteLine($l + '|' + $(if ($why) { 'refused' } else { 'kept' }))
}
`);
const r = spawnSync(ps, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(tmp, 'run.ps1'), path.join(tmp, 'rows.txt'), tmp],
  { encoding: 'utf8', windowsHide: true, env: { ...process.env, POWERSHELL_TELEMETRY_OPTOUT: '1' } });
if (r.error && r.error.code === 'ENOENT') {
  console.log('SKIP refuse_microsoft_tests: no ' + ps + ' on this host (CI has pwsh)');
  process.exit(0);
}
assert.equal(r.status, 0, r.stderr);
const got = r.stdout.split(/\r?\n/).filter(Boolean);
assert.deepEqual(got, rows.map(row => lineOf(row) + '|' + (row[2] ? 'refused' : 'kept')));

fs.rmSync(tmp, { recursive: true, force: true });
console.log('PASS refuse_microsoft_tests: Refuse-Reason refuses any path under Microsoft/ and the root .gitignore names it');
