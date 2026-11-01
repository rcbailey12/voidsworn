'use strict';
// Node 18+, no dependencies. All child processes run from the repository root.
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');
const baseline = JSON.parse(fs.readFileSync(path.join(__dirname, 'checks_baseline.json'), 'utf8'));
const args = process.argv.slice(2);
let only;
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--only' && args[i + 1] && !args[i + 1].startsWith('--')) only = args[++i];
  else if (!['--json', '--fast'].includes(args[i])) { console.error('Usage: node run_all_checks.js [--json] [--fast] [--only <name>]'); process.exit(1); }
}
const OPUS = 'contrib/opus/tools/';
const MUSE = 'contrib/muse/tools/';
const checks = [];
function add(file, extra = [], kind = 'normal', timeout = 300) {
  checks.push({ name: path.basename(file, '.js'), file, args: extra, kind, timeout });
}
fs.readdirSync(__dirname).filter(f => f.endsWith('_tests.js') || f === 'campaign_start_test.js').sort().forEach(f => add(OPUS + f));
add(OPUS + 'naming_lint_game.test.js');
add(OPUS + 'naming_lint_game.js', [], 'naming');
add(OPUS + 'checkpack/checks.js', [], 'pack');
for (const file of ['fleet_invariants.js', 'save_fuzz.js', 'softlock_sweep.js', 'validators/table_xref.js']) add(MUSE + 'harness/' + file, [ROOT]);
add(MUSE + 'findings_tests/findings_tests.js', ['--repo', ROOT], 'findings');
add(MUSE + 'oracle_drift/oracle_drift_guard.js', [ROOT], 'optional');
add(MUSE + 'cutover_gate/fixture_check.js', [ROOT, path.join(ROOT, MUSE, 'importer_fixtures'), path.join(ROOT, MUSE, 'harness/game_loader.js')], 'optional');
if (only && !checks.some(c => c.name === only || c.file === only)) { console.error('Unknown check: ' + only + '\nNames: ' + checks.map(c => c.name).join(', ')); process.exit(1); }
const ascii = s => String(s).replace(/[^\x20-\x7e\n\r\t]/g, '?');
async function execute(c) {
  const start = Date.now();
  const row = { check: c.name, result: 'FAIL', seconds: 0, detail: '', output: '' };
  let temp;
  try {
    if (args.includes('--fast') && c.timeout > 120) { row.result = 'SKIP'; row.detail = 'fast'; return row; }
    const original = path.join(ROOT, c.file);
    const source = fs.readFileSync(original, 'utf8');
    let childArgs = [original, ...c.args];
    const compact = source.trim().replace(/\s/g, '');
    if (compact.length && compact.length % 4 === 0 && /^[A-Za-z0-9+/]+={0,2}$/.test(compact)) {
      const decoded = Buffer.from(compact, 'base64');
      if (decoded.toString('base64') !== compact) throw new Error('Invalid base64');
      temp = fs.mkdtempSync(path.join(__dirname, '.checks-temp-'));
      const target = path.join(temp, 'decoded.js');
      fs.writeFileSync(target, decoded);
      // Compile the temporary source with the original module location so sibling
      // requires and __dirname keep working without changing the stored tool.
      const bootstrap = "const fs=require('fs'),M=require('module'),p=require('path');const f=process.argv[1],t=process.argv[2];process.argv=[process.execPath,f,...process.argv.slice(3)];const m=new M(f);m.filename=f;m.paths=M._nodeModulePaths(p.dirname(f));require.main=m;m._compile(fs.readFileSync(t,'utf8'),f);";
      childArgs = ['-e', bootstrap, original, target, ...c.args];
    }
    const run = await new Promise(resolve => {
      const child = spawn(process.execPath, childArgs, { cwd: ROOT, env: { ...process.env, VS_ROOT: ROOT }, windowsHide: true });
      let output = '', error, timedOut = false;
      const timer = setTimeout(() => {
        timedOut = true;
        if (process.platform === 'win32') {
          const killer = spawn('taskkill', ['/pid', String(child.pid), '/T', '/F'], { windowsHide: true, stdio: 'ignore' });
          killer.on('error', () => child.kill());
        } else child.kill('SIGKILL');
      }, c.timeout * 1000);
      child.stdout.on('data', b => { output += b; });
      child.stderr.on('data', b => { output += b; });
      child.on('error', e => { error = e.message; });
      child.on('close', code => { clearTimeout(timer); resolve({ output, code, error, timedOut }); });
    });
    row.output = ascii(run.output);
    row.exitCode = run.code;
    if (run.timedOut) { row.detail = 'Timed out after ' + c.timeout + ' s'; return row; }
    if (run.error) throw new Error(run.error);
    row.result = run.code === 0 ? 'PASS' : 'FAIL';
    row.detail = 'exit ' + run.code;
    if (c.kind === 'naming') {
      const m = /naming_lint_game: (\d+) hard, (\d+) word/.exec(run.output);
      if (!m) throw new Error('Missing naming summary');
      row.hardHits = +m[1];
      row.result = [0, 1].includes(run.code) && row.hardHits <= baseline.namingHardHits ? 'PASS' : 'FAIL';
      row.detail = `${m[1]} hard (baseline ${baseline.namingHardHits}), ${m[2]} word`;
    } else if (c.kind === 'pack') {
      const m = /SUMMARY: (\d+) FAIL, (\d+) CHECK/.exec(run.output);
      if (!m) throw new Error('Missing check pack summary');
      const failures = (run.output.match(/^FAIL\s/gm) || []).length;
      row.result = run.code === 0 && +m[1] === 0 && failures === 0 ? 'PASS' : 'FAIL';
      row.detail = `${m[1]} FAIL, ${m[2]} CHECK`;
    } else if (c.kind === 'findings') {
      const summary = /(\d+) tests, (\d+) pass, (\d+) fail/.exec(run.output);
      if (!summary) throw new Error('Missing findings summary');
      const failures = [...run.output.matchAll(/^FAIL\s+(\S+)[^:]*:/gm)].map(m => m[1].trim());
      row.passed = +summary[2]; row.failed = +summary[3];
      row.knownFailures = failures.filter(id => baseline.knownFindingsFailures.includes(id));
      row.unexpectedFailures = failures.filter(id => !baseline.knownFindingsFailures.includes(id));
      row.result = [0, 1].includes(run.code) && failures.length === row.failed && !row.unexpectedFailures.length ? 'PASS' : 'FAIL';
      row.detail = `${row.passed} passed, ${row.failed} failed; known: ${row.knownFailures.join(', ') || 'none'}; unexpected: ${row.unexpectedFailures.join(', ') || 'none'}`;
    } else if (c.kind === 'optional' && run.code !== 0 && /ENOENT|Cannot find module|not recognised|Godot.*(?:not found|required|missing)/i.test(run.output)) {
      row.result = 'SKIP'; row.detail = run.output.split(/\r?\n/).find(l => /ENOENT|Cannot find module|not recognised|Godot/i.test(l)) || 'Missing dependency';
    } else {
      const lines = run.output.trim().split(/\r?\n/);
      row.detail += '; ' + (lines[lines.length - 1] || 'no output');
    }
  } catch (e) {
    row.result = c.kind === 'optional' && e.code === 'ENOENT' ? 'SKIP' : 'FAIL';
    row.detail = e.message;
  } finally {
    if (temp) fs.rmSync(temp, { recursive: true, force: true });
    row.seconds = Math.round((Date.now() - start) / 10) / 100;
    row.detail = ascii(row.detail).replace(/[\r\n\t]+/g, ' ');
  }
  return row;
}
(async () => {
  const report = [];
  for (const c of checks.filter(c => !only || c.name === only || c.file === only)) {
    console.log('Running ' + c.name + ' (limit ' + c.timeout + ' s)...');
    const row = await execute(c); report.push(row);
    console.log(row.result + ': ' + row.detail);
  }
  console.log('\ncheck | result | seconds | detail');
  console.log('--- | --- | --- | ---');
  for (const r of report) console.log(`${r.check} | ${r.result} | ${r.seconds.toFixed(2)} | ${r.detail}`);
  for (const r of report.filter(r => r.result === 'FAIL')) console.log('\nFAIL ' + r.check + ' (first 15 output lines):\n' + r.output.split(/\r?\n/).slice(0, 15).join('\n'));
  if (args.includes('--json')) fs.writeFileSync(path.join(ROOT, 'checks_report.json'), JSON.stringify(report, null, 2) + '\n');
  process.exitCode = report.some(r => r.result === 'FAIL') ? 1 : 0;
})().catch(e => { console.error(ascii(e.stack)); process.exitCode = 1; });


