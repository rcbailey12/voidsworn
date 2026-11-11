'use strict';
// Node 18+, no dependencies. All child processes run from the repository root.
//
// Issue 358: the table tells the truth. A row has one of four words:
//   PASS  the check found zero failures inside the row
//   KNOWN only failures that sit on the baseline list, with the count
//   FAIL  anything else
//   SKIP  the check could not run on this machine (optional dependency)
// A PASS row never carries a failure count, a CHECK count or a differed count.
// A listed id that passes (or no longer runs) is an error until it is taken
// off the list. The pack CHECK count and the drift differed count are held
// against ceilings in checks_baseline.json that can only go down.
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');

function readBaseline() {
  return JSON.parse(fs.readFileSync(path.join(__dirname, 'checks_baseline.json'), 'utf8'));
}

const ascii = s => String(s).replace(/[^\x20-\x7e\n\r\t]/g, '?');

// ---------- result-word rules (issue 358) ----------

function verdictLine(output) {
  const lines = String(output || '').split(/\r?\n/).map(l => l.trim()).filter(Boolean);
  for (let i = lines.length - 1; i >= 0; i--) if (/^(PASS|FAIL)\b/.test(lines[i])) return lines[i];
  return '';
}

function parseFindings(output) {
  const passIds = [], failIds = [];
  let summary = null;
  for (const raw of String(output || '').split(/\r?\n/)) {
    const line = raw.trim();
    let m = /^PASS\s+(\S+)(?:\s|$)/.exec(line);
    if (m) { passIds.push(m[1]); continue; }
    m = /^FAIL\s+(\S+)(?:\s|$)/.exec(line);
    if (m) { failIds.push(m[1]); continue; }
    m = /^(\d+)\s+tests,\s+(\d+)\s+pass,\s+(\d+)\s+fail/.exec(line);
    if (m) summary = { total: +m[1], pass: +m[2], fail: +m[3] };
  }
  return { passIds, failIds, summary };
}

function classifyFindings(run, baseline) {
  const { passIds, failIds, summary } = parseFindings(run.output);
  if (!summary) return { result: 'FAIL', detail: 'FAIL: missing findings summary' };
  if (passIds.length !== summary.pass || failIds.length !== summary.fail) {
    return { result: 'FAIL', detail: 'FAIL: parsed ' + passIds.length + ' pass / ' + failIds.length + ' fail lines, summary says ' + summary.pass + ' / ' + summary.fail };
  }
  const listed = new Set(baseline.knownFindingsFailures || []);
  const known = failIds.filter(id => listed.has(id));
  const unexpected = failIds.filter(id => !listed.has(id));
  const listedPasses = passIds.filter(id => listed.has(id));
  const seen = new Set([...passIds, ...failIds]);
  const listedMissing = [...listed].filter(id => !seen.has(id));
  if (listedPasses.length) return { result: 'FAIL', detail: 'FAIL: listed id(s) now pass, take them off the list: ' + listedPasses.join(', ') };
  if (unexpected.length) return { result: 'FAIL', detail: 'FAIL: ' + unexpected.length + ' new failure(s): ' + unexpected.join(', ') };
  if (listedMissing.length) return { result: 'FAIL', detail: 'FAIL: listed id(s) no longer run: ' + listedMissing.join(', ') };
  if (known.length) return { result: 'KNOWN', detail: 'KNOWN: ' + known.length + ' listed failure(s): ' + known.join(', ') };
  return { result: 'PASS', detail: 'PASS: all ' + summary.total + ' gated findings tests pass' };
}

function classifyPack(run, baseline) {
  const out = String(run.output || '');
  const m = /SUMMARY:\s*(\d+)\s+FAIL,\s*(\d+)\s+CHECK/.exec(out);
  if (!m) return { result: 'FAIL', detail: 'FAIL: missing check pack summary' };
  const fails = +m[1], checks = +m[2];
  const failLines = (out.match(/^FAIL\b/gm) || []).length;
  const ceiling = Number.isFinite(baseline.checksCeiling) ? baseline.checksCeiling : 0;
  if (run.code !== 0 || fails > 0 || failLines > 0) {
    return { result: 'FAIL', detail: 'FAIL: ' + fails + ' FAIL, ' + checks + ' CHECK' + (run.code !== 0 ? ' (exit ' + run.code + ')' : '') };
  }
  if (checks > ceiling) {
    return { result: 'FAIL', detail: 'FAIL: ' + checks + ' CHECK is above the baseline ceiling of ' + ceiling };
  }
  return { result: 'PASS', detail: 'PASS: within the pack baseline' };
}

function classifyDrift(run, baseline) {
  const out = String(run.output || '');
  let m = /DRIFT SUMMARY:[^\n]*?(\d+)\s+differed/.exec(out);
  if (!m) m = /constants:\s*\d+\s+entries compared,\s*\d+\s+matched,\s*(\d+)\s+differed/.exec(out);
  if (!m) return { result: 'FAIL', detail: 'FAIL: missing drift summary' };
  const differed = +m[1];
  const ceiling = Number.isFinite(baseline.driftDifferedCeiling) ? baseline.driftDifferedCeiling : 0;
  if (differed > ceiling) return { result: 'FAIL', detail: 'FAIL: ' + differed + ' differed is above the baseline ceiling of ' + ceiling };
  if (differed > 0) return { result: 'KNOWN', detail: 'KNOWN: ' + differed + ' constant difference(s) within the baseline' };
  return { result: 'PASS', detail: 'PASS: no constant drift' };
}

function classifyNaming(run, baseline) {
  const m = /naming_lint_game: (\d+) hard, (\d+) word/.exec(String(run.output || ''));
  if (!m) return { result: 'FAIL', detail: 'FAIL: missing naming summary' };
  const hard = +m[1], word = +m[2];
  const ceiling = Number.isFinite(baseline.namingHardHits) ? baseline.namingHardHits : 0;
  if (![0, 1].includes(run.code) || hard > ceiling) {
    return { result: 'FAIL', detail: 'FAIL: ' + hard + ' hard hits above the baseline of ' + ceiling + ', ' + word + ' word hits' };
  }
  return { result: 'PASS', detail: 'PASS: naming lint within the baseline' };
}

function classifyGeneric(run) {
  const out = String(run.output || '');
  const failLine = out.split(/\r?\n/).map(l => l.trim()).find(l => /^FAIL\b/.test(l)) || '';
  const v = verdictLine(out);
  if (run.code !== 0 || failLine) {
    return { result: 'FAIL', detail: failLine || (v && /^FAIL\b/.test(v) ? v : 'FAIL: exit ' + run.code) };
  }
  return { result: 'PASS', detail: v && /^PASS\b/.test(v) ? v : 'PASS: exit 0' };
}

function exitCodeFor(report) {
  return report.some(r => r.result === 'FAIL') ? 1 : 0;
}

// ---------- the checks ----------

function buildChecks() {
  const OPUS = 'contrib/opus/tools/';
  const MUSE = 'contrib/muse/tools/';
  const checks = [];
  const add = (file, extra = [], kind = 'normal', timeout = 300) => {
    checks.push({ name: path.basename(file, '.js'), file, args: extra, kind, timeout });
  };
  fs.readdirSync(__dirname).filter(f => f.endsWith('_tests.js') || f === 'campaign_start_test.js').sort().forEach(f => add(OPUS + f));
  add(OPUS + 'progression_telemetry_test.js'); // #27 step 11: per run XP by line and the F1 play log report
  add(OPUS + 'tree_effects_test.js'); // #305 jobs 1 to 4: every Glasswrights, Sunward, Eclipse and Chorus parity fixture actually fires its pick
  add(OPUS + 'tree_handoff_test.js'); // #335: a tree pick made through the real campaign reaches the battle in both twins
  add(OPUS + 'tree_table_walk_test.js'); // #361: every LINEAGE_TREES row is hand-off tested through the real functions or on the dated waiting list
  add(OPUS + 'oracle_copy_test.js'); // #335 finding 3: the oracle copies and campaign tables match the root game files (hard, not optional)
  add('godot/campaign/test/node/nem_assign_enum.js'); // #120 R-Q1: the exact assignment constraints (quick mode) gate every PR
  add(OPUS + 'nem_direct_reads_report.js'); // #364: report only, the count of direct save reads outside godot/campaign/
  add(OPUS + 'naming_lint_game.test.js');
  add(OPUS + 'naming_lint_game.js', [], 'naming');
  add(OPUS + 'checkpack/checks.js', [], 'pack');
  for (const file of ['fleet_invariants.js', 'save_fuzz.js', 'softlock_sweep.js', 'validators/table_xref.js']) add(MUSE + 'harness/' + file, [ROOT]);
  add(MUSE + 'findings_tests/findings_tests.js', ['--repo', ROOT], 'findings');
  add(MUSE + 'oracle_drift/oracle_drift_guard.js', [ROOT], 'drift');
  add(MUSE + 'cutover_gate/fixture_check.js', [ROOT, path.join(ROOT, MUSE, 'importer_fixtures'), path.join(ROOT, MUSE, 'harness/game_loader.js')], 'optional');
  return checks;
}

// ---------- running ----------

async function execute(c, baseline) {
  const start = Date.now();
  const row = { check: c.name, result: 'FAIL', seconds: 0, detail: '', output: '' };
  let temp;
  try {
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
    if (run.timedOut) { row.detail = 'FAIL: timed out after ' + c.timeout + ' s'; return row; }
    if (run.error) throw new Error(run.error);
    if (c.kind === 'optional' && run.code !== 0 && /ENOENT|Cannot find module|not recognised|Godot.*(?:not found|required|missing)/i.test(run.output)) {
      row.result = 'SKIP';
      row.detail = 'SKIP: ' + (run.output.split(/\r?\n/).find(l => /ENOENT|Cannot find module|not recognised|Godot/i.test(l)) || 'Missing dependency');
      return row;
    }
    let verdict;
    if (c.kind === 'naming') verdict = classifyNaming(run, baseline);
    else if (c.kind === 'pack') verdict = classifyPack(run, baseline);
    else if (c.kind === 'findings') verdict = classifyFindings(run, baseline);
    else if (c.kind === 'drift') verdict = classifyDrift(run, baseline);
    else verdict = classifyGeneric(run);
    row.result = verdict.result;
    row.detail = verdict.detail;
  } catch (e) {
    row.result = c.kind === 'optional' && e.code === 'ENOENT' ? 'SKIP' : 'FAIL';
    row.detail = (row.result === 'SKIP' ? 'SKIP: ' : 'FAIL: ') + e.message;
  } finally {
    if (temp) fs.rmSync(temp, { recursive: true, force: true });
    row.seconds = Math.round((Date.now() - start) / 10) / 100;
    row.detail = ascii(row.detail).replace(/[\r\n\t]+/g, ' ');
  }
  return row;
}

async function main() {
  const args = process.argv.slice(2);
  let only;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--only' && args[i + 1] && !args[i + 1].startsWith('--')) only = args[++i];
    else if (!['--json', '--fast'].includes(args[i])) { console.error('Usage: node run_all_checks.js [--json] [--fast] [--only <name>]'); process.exit(1); }
  }
  const baseline = readBaseline();
  const checks = buildChecks();
  if (only && !checks.some(c => c.name === only || c.file === only)) { console.error('Unknown check: ' + only + '\nNames: ' + checks.map(c => c.name).join(', ')); process.exit(1); }
  const report = [];
  for (const c of checks.filter(c => !only || c.name === only || c.file === only)) {
    if (args.includes('--fast') && c.timeout > 120) {
      const row = { check: c.name, result: 'SKIP', seconds: 0, detail: 'SKIP: fast', output: '' };
      report.push(row);
      console.log('Running ' + c.name + ' (limit ' + c.timeout + ' s)...');
      console.log(row.detail);
      continue;
    }
    console.log('Running ' + c.name + ' (limit ' + c.timeout + ' s)...');
    const row = await execute(c, baseline);
    report.push(row);
    console.log(row.detail);
  }
  console.log('\ncheck | result | seconds | detail');
  console.log('--- | --- | --- | ---');
  for (const r of report) console.log(`${r.check} | ${r.result} | ${r.seconds.toFixed(2)} | ${r.detail}`);
  for (const r of report.filter(r => r.result === 'FAIL')) console.log('\nFAIL ' + r.check + ' (first 15 output lines):\n' + r.output.split(/\r?\n/).slice(0, 15).join('\n'));
  const skipped = report.filter(r => r.result === 'SKIP').map(r => r.check);
  if (skipped.length) console.log('\nSKIP: ' + skipped.join(', '));
  if (args.includes('--json')) fs.writeFileSync(path.join(ROOT, 'checks_report.json'), JSON.stringify(report, null, 2) + '\n');
  process.exitCode = exitCodeFor(report);
}

if (require.main === module) {
  main().catch(e => { console.error(ascii(e.stack)); process.exitCode = 1; });
}

module.exports = { classifyFindings, classifyPack, classifyDrift, classifyNaming, classifyGeneric, verdictLine, parseFindings, exitCodeFor, ROOT };
