'use strict';
// Issue 1739 (Board, Nov 23 03:22 janitor dry run): the dry run said 49.9 GB would come back and about 4.6 GB did. A
// checkout's hard links shared with the mirror were counted in full, and folders the Codex sandbox account owns were
// counted although the janitor's account cannot remove them. This row runs the janitor's own measure on a fixture:
// a lone file counts, a file whose every link is inside counts once, a link shared outside counts nothing, and a
// folder another account owns is listed as cannot-remove and never counted.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const pc = path.resolve(__dirname, '../../../tools/pc');
const ps = process.env.PC_TEST_POWERSHELL || (process.platform === 'win32' ? 'powershell.exe' : 'pwsh');
if (spawnSync(ps, ['-NoProfile', '-Command', 'exit 0']).error) {
  if (process.env.CI) throw new Error(ps + ' is required in CI');
  console.log('SKIP janitor_free_space_1739_tests: no ' + ps + ' here (CI runs it)');
  process.exit(0);
}
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'free1739-'));
try {
  const dir = path.join(root, 'folder');
  fs.mkdirSync(path.join(dir, 'foreign'), { recursive: true });
  fs.mkdirSync(path.join(root, 'outside'));
  fs.writeFileSync(path.join(dir, 'lone.bin'), Buffer.alloc(1000));
  fs.writeFileSync(path.join(root, 'outside', 'shared.bin'), Buffer.alloc(2000));
  fs.linkSync(path.join(root, 'outside', 'shared.bin'), path.join(dir, 'shared.bin'));
  fs.writeFileSync(path.join(dir, 'pair1.bin'), Buffer.alloc(3000));
  fs.linkSync(path.join(dir, 'pair1.bin'), path.join(dir, 'pair2.bin'));
  fs.writeFileSync(path.join(dir, 'foreign', 'sandbox.bin'), Buffer.alloc(5000));
  const script = path.join(root, 'probe.ps1');
  fs.writeFileSync(script, `
$ErrorActionPreference = 'Stop'
. (Join-Path $env:FIX_PC 'runner_common.ps1') cleanup-library
# Without root to chown it, the fixture stands in for the Codex sandbox account: the folder named foreign has another owner.
if ($env:FIX_MOCK -eq '1') {
  function Select-OtherAccountFolders($directories) { return @(@($directories) | Where-Object { $_.Name -eq 'foreign' }) }
}
$d = Get-Item -LiteralPath $env:FIX_DIR -Force
$s = Measure-CleanupDirectory $d -AllowUnreadable
Write-Output "bytes $($s.Bytes)"
Write-Output "free $($s.FreeBytes)"
Write-Output "shared $($s.SharedBytes)"
Write-Output "unchecked $($s.UncheckedBytes)"
Write-Output "cannot $(@($s.Unreadable | ForEach-Object { $_.Name }) -join ',')"
Write-Output "size $(Format-CleanupSize $s)"
try { $null = Measure-CleanupDirectory $d; Write-Output 'strict counted' } catch { Write-Output "strict $($_.Exception.Message)" }
`);
  // As root (the cloud runner here) the folder really gets another owner, so the real owner check runs too.
  let mock = '1';
  if (process.platform !== 'win32' && process.getuid && process.getuid() === 0) {
    fs.chownSync(path.join(dir, 'foreign'), 4321, 4321);
    mock = '0';
  }
  const r = spawnSync(ps, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script], {
    encoding: 'utf8', windowsHide: true, env: { ...process.env, FIX_PC: pc, FIX_DIR: dir, FIX_MOCK: mock, POWERSHELL_TELEMETRY_OPTOUT: '1' } });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  const got = Object.fromEntries(r.stdout.trim().split(/\r?\n/).map(l => [l.slice(0, l.indexOf(' ')), l.slice(l.indexOf(' ') + 1)]));
  assert.equal(got.bytes, '9000', 'every listed byte outside the other account\'s folder: ' + r.stdout);
  assert.equal(got.free, '4000', 'the lone file plus the inside pair once; the shared link frees nothing: ' + r.stdout);
  assert.equal(got.shared, '2000', r.stdout);
  assert.equal(got.unchecked, '0', r.stdout);
  assert.equal(got.cannot, 'foreign', 'the other account\'s folder is listed as cannot remove: ' + r.stdout);
  assert.equal(got.size, '4000 bytes would be freed, 9000 listed, 2000 in hard links shared outside it', r.stdout);
  assert.match(got.strict, /folder another account owns: .*foreign/, 'a checkout measure refuses it: ' + r.stdout);
} finally {
  fs.rmSync(root, { recursive: true, force: true });
}
// Artoo on PR 1812: the Windows file record must match BY_HANDLE_FILE_INFORMATION (52 bytes, links at offset 40), or the
// link count and file id are read from the wrong fields. The struct compiles on any .NET, so its layout is checked here.
{
  const disk = fs.readFileSync(path.join(pc, 'disk_space.ps1'), 'utf8');
  const struct = /\[StructLayout\(LayoutKind\.Sequential\)\] public struct Info \{[\s\S]*?\n  \}/.exec(disk);
  assert(struct, 'disk_space.ps1 declares the Info struct');
  const probe = path.join(os.tmpdir(), 'free1739-layout-' + process.pid + '.ps1');
  fs.writeFileSync(probe, "Add-Type -TypeDefinition @'\nusing System.Runtime.InteropServices;\npublic static class LayoutProbe1739 {\n" + struct[0] +
    "\n}\n'@\n$t = [LayoutProbe1739+Info]\n" +
    "Write-Output \"$([Runtime.InteropServices.Marshal]::SizeOf((New-Object LayoutProbe1739+Info))) $([Runtime.InteropServices.Marshal]::OffsetOf($t, 'links')) $([Runtime.InteropServices.Marshal]::OffsetOf($t, 'volume'))\"\n");
  const l = spawnSync(ps, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', probe], { encoding: 'utf8', windowsHide: true, env: { ...process.env, POWERSHELL_TELEMETRY_OPTOUT: '1' } });
  fs.rmSync(probe, { force: true });
  assert.equal(l.status, 0, l.stdout + l.stderr);
  assert.equal(l.stdout.trim(), '52 40 28', 'BY_HANDLE_FILE_INFORMATION is 52 bytes, volume at 28, links at 40: ' + l.stdout);
}
// The janitor closes with the honest total, and the helper head's sizes use the same helpers.
const janitor = fs.readFileSync(path.join(pc, 'janitor.ps1'), 'utf8');
assert.match(janitor, /Log \("space \$\{verb\}: \$\(\$script:wouldFreeBytes\) bytes/, 'janitor prints the would-free total');
assert.match(janitor, /cannot remove: \$\(\$u\.FullName\)/, 'janitor names each folder it cannot remove');
const head = fs.readFileSync(path.join(pc, 'jobs', 'opus_job_head.ps1'), 'utf8');
assert.match(head, /if \(\$tally\) \{ return \(Complete-FreeTally \$tally\)\.Free \}/, 'the survey sizes what removal frees');
assert.match(head, /if \(\$id -and \$id\.Links -gt 1\) \{ \$len = 0 \}/, 'a removal counts only the last link of a file');
console.log('PASS janitor_free_space_1739_tests: shared hard links free nothing, an all-inside pair counts once, and another account\'s folder is listed as cannot remove, never counted');
