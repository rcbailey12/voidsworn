'use strict';
// Issue 1335: the janitor's salvage step pipes commands into git. PowerShell 5.1 wrote a UTF-8 byte order mark in front
// of them under code page 65001, git refused '<BOM>create refs/salvage/...', and 11 folders were kept on Nov 20.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const pc = path.join(__dirname, '..', '..', '..', 'tools', 'pc');
const salvage = fs.readFileSync(path.join(pc, 'janitor_salvage.ps1'), 'utf8').replace(/\r\n/g, '\n');
const work = fs.readFileSync(path.join(pc, 'work_issue.ps1'), 'utf8').replace(/\r\n/g, '\n');
for (const [name, text] of [['janitor_salvage.ps1', salvage], ['work_issue.ps1', work]]) {
  assert.match(text, /^function Start-Utf8InputProcess\(\$start\) \{/m, `${name} defines the BOM-free starter`);
  const starts = [...text.matchAll(/\[Diagnostics\.Process\]::Start\(\$start\)/g)].length;
  const helper = /^function Start-Utf8InputProcess[\s\S]*?^\}$/m.exec(text)[0];
  assert.equal(starts, [...helper.matchAll(/\[Diagnostics\.Process\]::Start\(\$start\)/g)].length,
    `${name}: every redirected-stdin start goes through Start-Utf8InputProcess`);
}
assert.match(salvage, /\$child = Start-Utf8InputProcess \$start/);
for (const [name, text] of [['janitor_salvage.ps1', salvage], ['work_issue.ps1', work]]) {
  assert.doesNotMatch(text, /StandardInput\.Write(?:Line)?\(/, `${name}: stdin text goes through Write-Utf8Input, not the console-encoded writer`);
  assert.match(text, /^function Write-Utf8Input\(/m, `${name} defines Write-Utf8Input`);
}
assert.match(work, /\$process = Start-Utf8InputProcess \$start/);

const windows = process.platform === 'win32';
const shell = windows ? 'powershell.exe' : 'pwsh';
if (spawnSync(shell, ['-NoProfile', '-Command', 'exit 0']).error) {
  if (process.env.CI) throw new Error(`${shell} is required in CI for the salvage stdin fixture`);
  console.log(`SKIP salvage stdin fixture: no ${shell} here (CI and the PC run it)`);
  console.log('PASS salvage stdin static checks');
  process.exit(0);
}
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'salvage-stdin-'));
try {
  const repo = path.join(dir, 'repo');
  const git = (...args) => {
    const r = spawnSync('git', ['-C', repo, ...args], { encoding: 'utf8' });
    assert.equal(r.status, 0, r.stderr);
    return r.stdout.trim();
  };
  fs.mkdirSync(repo);
  git('init', '-q');
  fs.writeFileSync(path.join(repo, 'a.txt'), 'a\n');
  git('add', 'a.txt');
  git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'fixture');
  const head = git('rev-parse', 'HEAD');
  // The PC's console code page: force an encoding that carries a BOM, then pipe the exact salvage command through it.
  const script = [
    '. $env:FIX_COMMON cleanup-library',
    '. $env:FIX_SALVAGE',
    "try { [Console]::InputEncoding = New-Object Text.UTF8Encoding($true) } catch { Write-Host 'console encoding fixed by host' }",
    "$null = Salvage-Git @('-C',$env:FIX_REPO,'update-ref','--stdin') @(\"create refs/salvage/fixture $env:FIX_HEAD\")",
    "Write-Host 'salvage ok'"
  ].join('\n');
  const r = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
    { encoding: 'utf8', env: { ...process.env, FIX_REPO: repo, FIX_HEAD: head,
      FIX_COMMON: path.join(pc, 'runner_common.ps1'), FIX_SALVAGE: path.join(pc, 'janitor_salvage.ps1') }, timeout: 60000 });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /salvage ok/, r.stdout + r.stderr);
  assert.equal(git('rev-parse', 'refs/salvage/fixture'), head, 'git took the stdin command without a byte order mark');
  // Artoo on PR 1345: a BOM-free legacy page (437) must not change non-ASCII text. git hashes exactly the bytes it gets.
  const text = 'Glasswright caf\u00e9 \u00fc\u00df \u00e5 salvage';
  const blob = Buffer.from(text + '\n', 'utf8');
  const expected = require('node:crypto').createHash('sha1')
    .update(Buffer.concat([Buffer.from('blob ' + blob.length + '\0'), blob])).digest('hex');
  const legacy = [
    '. $env:FIX_COMMON cleanup-library',
    '. $env:FIX_SALVAGE',
    "try { [Console]::InputEncoding = [Text.Encoding]::GetEncoding(437) } catch { Write-Host 'console encoding fixed by host' }",
    '$text = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:FIX_TEXT))',
    "$out = @(Salvage-Git @('-C',$env:FIX_REPO,'hash-object','--stdin') @($text))",
    "Write-Host ('hash=' + $out[0])"
  ].join('\n');
  const l = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', legacy],
    { encoding: 'utf8', env: { ...process.env, FIX_REPO: repo, FIX_TEXT: Buffer.from(text, 'utf8').toString('base64'),
      FIX_COMMON: path.join(pc, 'runner_common.ps1'), FIX_SALVAGE: path.join(pc, 'janitor_salvage.ps1') }, timeout: 60000 });
  assert.equal(l.status, 0, l.stdout + l.stderr);
  assert.match(l.stdout, new RegExp('hash=' + expected), 'non-ASCII stdin reaches git as UTF-8 under code page 437: ' + l.stdout + l.stderr);
} finally { fs.rmSync(dir, { recursive: true, force: true }); }
console.log('PASS salvage stdin: git gets BOM-free UTF-8 under a BOM page (65001) and a legacy page (437), non-ASCII included');
