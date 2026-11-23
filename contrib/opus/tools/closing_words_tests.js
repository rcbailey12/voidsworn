'use strict';
// Board, Nov 23 (RULEBOOK 2.5, R288): runner commits and PR bodies say "Refs #N", never a GitHub closing word.
// Codex PRs 1758, 1759 and 1784 opened with "Closes #N" and the Board edited each by hand. auto_pr_body_tests.js covers
// the PR body (auto_pr.yml refs_only); this row runs work_issue.ps1's own Refs-Only on a runner commit message.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const script = fs.readFileSync(path.join(__dirname, '../../../tools/pc/work_issue.ps1'), 'utf8');
const fn = script.split(/\r?\n/).find(l => l.startsWith('function Refs-Only('));
assert.ok(fn, 'work_issue.ps1 defines Refs-Only');
assert.match(script, /\$final = Refs-Only \(\$msg\.TrimEnd\(\) \+ "`n`n" \+ \$block\)/, 'the commit step passes the whole message through Refs-Only');
const ps = process.env.PC_TEST_POWERSHELL || (process.platform === 'win32' ? 'powershell.exe' : 'pwsh');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'closing words '));
const input = 'Fix the export\n\nCloses #1784\nFIXES: #1500\nresolved #12 and fixed  #7\nCloses issue 9\nRefs #42\nSee #300\nprefix#5\n';
const expected = 'Fix the export\n\nRefs #1784\nRefs #1500\nRefs #12 and Refs #7\nCloses issue 9\nRefs #42\nSee #300\nprefix#5\n';
fs.writeFileSync(path.join(tmp, 'in.txt'), input);
fs.writeFileSync(path.join(tmp, 'run.ps1'), fn + '\n[Console]::Out.Write((Refs-Only ([IO.File]::ReadAllText($args[0]))))\n');
const r = spawnSync(ps, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(tmp, 'run.ps1'), path.join(tmp, 'in.txt')],
  { encoding: 'utf8', windowsHide: true, env: { ...process.env, POWERSHELL_TELEMETRY_OPTOUT: '1' } });
if (r.error && r.error.code === 'ENOENT') {
  console.log('SKIP closing_words_tests: no ' + ps + ' on this host (CI has pwsh)');
  process.exit(0);
}
assert.equal(r.status, 0, r.stderr);
assert.equal(r.stdout, expected);
fs.rmSync(tmp, { recursive: true, force: true });
console.log('PASS closing_words_tests: a runner commit turns every closing word before an issue number into Refs');
