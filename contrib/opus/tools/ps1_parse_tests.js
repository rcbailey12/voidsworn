#!/usr/bin/env node
// Every tracked PowerShell script must parse (Board, Nov 21, issue 1530): LOAD11 (issue 1434) reached the PC with one
// ")" too many in contrib/opus/pc/1434/load1434_runs.ps1 and failed after a 30 minute run without its bench ever
// starting. A bat that calls a script that does not parse should fail CI instead.
// Uses PowerShell's own parser ([System.Management.Automation.Language.Parser]::ParseFile) through pwsh, which the
// GitHub ubuntu runner has. A broken fixture is parsed first, so a parser that reports nothing cannot pass the check.
// Without pwsh: FAIL on GitHub Actions, a plain "not run" line elsewhere (a cloud or Linux checkout without pwsh).
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..', '..', '..');

function trackedScripts() {
  const r = spawnSync('git', ['ls-files', '-z', '--', '*.ps1'], { cwd: ROOT, encoding: 'utf8' });
  if (r.status !== 0) throw new Error('git ls-files failed: ' + (r.stderr || '').trim());
  return r.stdout.split('\0').filter(f => f && !f.startsWith('docs/archive/')).sort();
}

function havePwsh() {
  const r = spawnSync('pwsh', ['-NoProfile', '-NonInteractive', '-Command', '$PSVersionTable.PSVersion.ToString()'], { encoding: 'utf8' });
  return r.status === 0 ? r.stdout.trim() : '';
}

const PARSER = `param([string]$List)
$n = 0
foreach ($f in Get-Content -LiteralPath $List) {
  if (-not $f) { continue }
  $n++
  $tokens = $null; $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errors)
  foreach ($e in $errors) { "PARSE|$f|$($e.Extent.StartLineNumber)|$($e.Extent.StartColumnNumber)|$($e.Message)" }
}
"FILES|$n"
`;

function parse(files) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ps1parse-'));
  try {
    const script = path.join(dir, 'parse.ps1');
    const list = path.join(dir, 'list.txt');
    fs.writeFileSync(script, PARSER);
    fs.writeFileSync(list, files.join('\n') + '\n');
    const r = spawnSync('pwsh', ['-NoProfile', '-NonInteractive', '-File', script, '-List', list], { encoding: 'utf8', maxBuffer: 64 << 20 });
    if (r.status !== 0) throw new Error('pwsh exited ' + r.status + ': ' + (r.stderr || '').trim().slice(0, 400));
    const out = r.stdout.split(/\r?\n/);
    const counted = out.find(l => l.startsWith('FILES|'));
    const errors = out.filter(l => l.startsWith('PARSE|')).map(l => {
      const [, file, line, col, ...msg] = l.split('|');
      return { file, line: +line, col: +col, msg: msg.join('|') };
    });
    return { files: counted ? +counted.split('|')[1] : -1, errors };
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function main() {
  const version = havePwsh();
  if (!version) {
    if (process.env.GITHUB_ACTIONS === 'true') {
      console.log('FAIL: pwsh is not on this runner, so no PowerShell script was parsed');
      process.exit(1);
    }
    console.log('ps1_parse_tests: not run here (no pwsh on this machine); GitHub CI parses every tracked .ps1');
    return;
  }
  // the fixture: the LOAD11 mistake, one ")" too many after a $( ) inside a -f argument list
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ps1fix-'));
  const bad = path.join(dir, 'broken.ps1');
  fs.writeFileSync(bad, 'function Say($s) { $s }\nSay ("{0}" -f $(if ($true) { "a" } else { \'\' })))\n');
  const good = path.join(dir, 'fine.ps1');
  fs.writeFileSync(good, 'function Say($s) { $s }\nSay ("{0}" -f $(if ($true) { "a" } else { \'\' }))\n');
  let fx;
  try { fx = parse([bad, good]); } finally { fs.rmSync(dir, { recursive: true, force: true }); }
  const badCaught = fx.errors.some(e => e.file === bad);
  const goodClean = !fx.errors.some(e => e.file === good);
  if (!badCaught || !goodClean) {
    console.log('FAIL: the parser fixture went wrong (broken script caught: ' + badCaught + ', clean script clean: ' + goodClean + ')');
    process.exit(1);
  }
  const files = trackedScripts().map(f => path.join(ROOT, f));
  const r = parse(files);
  if (r.files !== files.length) {
    console.log('FAIL: pwsh parsed ' + r.files + ' of ' + files.length + ' scripts');
    process.exit(1);
  }
  const byFile = new Map();
  for (const e of r.errors) {
    const rel = path.relative(ROOT, e.file).split(path.sep).join('/');
    if (!byFile.has(rel)) byFile.set(rel, []);
    byFile.get(rel).push(e);
  }
  if (byFile.size) {
    for (const [f, es] of byFile) {
      console.log('  ' + f + ': ' + es.slice(0, 3).map(e => 'line ' + e.line + ' char ' + e.col + ': ' + e.msg).join('; ') + (es.length > 3 ? ' (+' + (es.length - 3) + ' more)' : ''));
    }
    console.log('FAIL: ' + byFile.size + ' of ' + files.length + ' PowerShell scripts do not parse (pwsh ' + version + ')');
    process.exit(1);
  }
  console.log('PASS: all ' + files.length + ' tracked PowerShell scripts parse (pwsh ' + version + ', broken fixture caught)');
}

main();
