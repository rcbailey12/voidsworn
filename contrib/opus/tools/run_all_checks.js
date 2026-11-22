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

// Issue 357: the rules math targets V8 in Node 22; another major gives a false parity failure.
if (require.main === module && process.versions.node.split('.')[0] !== '22') {
  console.error('FAIL: Node major 22 is required, found ' + process.versions.node + '. Use the bundled Node 22 at voidsworn_test/node/node.exe.');
  process.exit(1);
}

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
  const add = (file, extra = [], kind = 'normal', timeout = 300, gate = false, fast = false) => {
    checks.push({ name: path.basename(file, '.js'), file, args: extra, kind, timeout, gate, fast });
  };
  // Issue 946: mark fast rows in add() or FAST_AUTO using a complete run under 30 s.
  // A timing must include any platform-specific work. On Windows issue 962 timed
  // runner_selftest at 205 s and stage5_fail_selftest at 126 s, so both stay unmarked.
  // The same run timed the Windows gpu_slots and runner_stall probes under 15 s.
  // Issue 975 timed fx_death_spawn_tests under 5 s with the real hull.
  // Re-time when a row's cost changes. Gate rows always run.
  const FAST_AUTO = new Set([
    'auto_pr_body_tests', 'b1_tests', 'b3_tests', 'b4_tests', 'backlog_tests', 'build_manifest_tests',
    'campaign_saves_1556_tests', 'campaign_start_test', 'capstone_mastery_tests', 'checks_truth_tests',
    'chorus_eat_core_tests', 'chorus_biomass_1484_tests', 'cinder_prizes_tests', 'core_sync_tests', 'doc_check_tests',
    'effect_caps_tests', 'env_reconcile_tests', 'fleet_list_tests', 'free_exit_tests', 'fx_death_spawn_tests',
    'fx_late_shader_tests', 'gen_open_work_tests', 'gpu_slots_tests',
    'hardpoint_contract_tests', 'heat_tests', 'inheritance_tests', 'ion_pulse_ai_tests', 'ion_tests',
    'lineage_tests', 'main_commit_lint_tests', 'memory_lint_tests', 'montecarlo_bot_tests', 'nemesis_121_tests', 'nemesis_122_tests',
    'nemesis_395_tests', 'nemesis_clash_tests', 'nemesis_teach_tests',
    'paint_sheet_camera_tests', 'relic_trade_1449_tests', 'retreat_nemesis_1480_tests', 'event_fight_retreat_1628_tests', 'eclipse_violet_1641_tests', 'reporting_238_tests', 'rules_1479_tests', 'rules_1481_tests', 'rules_1560_tests', 'runner_stall_tests',
    'shadow_xp_tests', 'shield_pool_tests', 'ship_job_tests', 'squadron_auto_tests', 'story_beat3_tests',
    'ui_spec_tests', 'weapon_match_tests', 'workflow_config_tests',
  ]);
  // Every *_tests.js here runs as a row, among them build_manifest_tests.js (#550, R214: each build sheet manifest's routes,
  // library entries and break-piece interiors held against its sheet; docs/ship_pipeline/build_sheets/manifest_schema.md)
  // and the report_paths_tests.js and check_em_dashes_tests.js publication and punctuation fixtures.
  // The glob below runs each one once; a second add() line would run it twice.
  fs.readdirSync(__dirname).filter(f => f.endsWith('_tests.js') || f === 'campaign_start_test.js').sort().forEach(f => add(OPUS + f, [], 'normal', 300, false, FAST_AUTO.has(path.basename(f, '.js'))));
  add(OPUS + 'progression_telemetry_test.js', [], 'normal', 300, false, true); // #27 step 11: per run XP by line and the F1 play log report
  add(OPUS + 'tree_effects_test.js'); // #305 jobs 1 to 4: every Glasswrights, Sunward, Eclipse and Chorus parity fixture actually fires its pick
  add(OPUS + 'tree_handoff_test.js', [], 'normal', 300, false, true); // #335: a tree pick made through the real campaign reaches the battle in both twins
  add(OPUS + 'tree_table_walk_test.js', [], 'normal', 300, false, true); // #361: every LINEAGE_TREES row is hand-off tested through the real functions or on the dated waiting list
  add(OPUS + 'tree_last_rows_test.js', [], 'normal', 300, false, true); // #529: the last seven tree rows and the you-may prompts move their numbers; fixtures carry the real lineage
  add(OPUS + 'oracle_copy_test.js', [], 'normal', 300, false, true); // #335 finding 3: the oracle copies and campaign tables match the root game files (hard, not optional)
  add('contrib/deepseek/map_pace_1117/smoke_safety_test.js', [], 'normal', 300, false, true); // #1019: the documented smoke run leaves the saved 200-sim raw files byte for byte unchanged
  add('contrib/deepseek/chorus_biomass_1118/spiral_test.js', [], 'normal', 300, false, true); // #1085: the loss spiral prices a 25 percent repair of the worst ship, capped at what it is missing
  add('contrib/deepseek/ge_economy_1118/commission_test.js', [], 'normal', 300, false, true); // #1086: one shipyard visit queues at most one Glasswright commission, even with two affordable offers
  add('tools/pc/runner_selftest.js', [], 'normal', 600); // #687: free PC runner fault tests; static contract check on other hosts
  add('tools/pc/g2_export_selftest.js'); // #1100: a stand-in exporter proves only checked builds become live on Windows
  add('tools/pc/pause_all_selftest.js'); // #944: pause waits for runners and verifies each saved commit on GitHub
  add('tools/pc/lane_tools_refresh_selftest.js'); // #1018: lane tools refresh safety checks
  add('tools/recipe/stage5_fail_selftest.js', [], 'normal', 600); // #873: stage 5 and bench 207 stop on a failed step; fake executables, static contract on other hosts
  add('godot/campaign/test/node/nem_assign_enum.js', [], 'normal', 300, true, true); // #120 R-Q1: the exact assignment constraints (quick mode) gate every PR; a gating row never SKIPs under --fast (issue 248 NOTE 4)
  add(OPUS + 'nem_direct_reads_report.js', [], 'normal', 300, false, true); // #364: report only, the count of direct save reads outside godot/campaign/
  add(OPUS + 'naming_lint_game.test.js', [], 'normal', 300, false, true);
  add(OPUS + 'naming_lint_game.js', [], 'naming');
  add(OPUS + 'checkpack/checks.js', [], 'pack', 300, false, true);
  add(OPUS + 'fast_selection_test.js', [], 'normal', 300, false, true); // #946: --fast selects exactly the marked rows plus the gate; a plain run still runs every row
  for (const file of ['fleet_invariants.js', 'save_fuzz.js', 'softlock_sweep.js', 'validators/table_xref.js']) add(MUSE + 'harness/' + file, [ROOT], 'normal', 300, false, file !== 'softlock_sweep.js');
  add(MUSE + 'findings_tests/findings_tests.js', ['--repo', ROOT], 'findings', 300, false, true);
  add(MUSE + 'oracle_drift/oracle_drift_guard.js', [ROOT], 'drift', 300, false, true);
  add(MUSE + 'cutover_gate/fixture_check.js', [ROOT, path.join(ROOT, MUSE, 'importer_fixtures'), path.join(ROOT, MUSE, 'harness/game_loader.js')], 'optional', 300, false, true);
  return checks;
}

// Issue 946: under --fast a row runs when it is marked fast or it is the gate.
function fastSelected(checks) {
  return checks.filter(c => c.fast || c.gate);
}

// ---------- running ----------

function printRow(row) {
  console.log(row.result + ': ' + row.check + ' (' + row.seconds.toFixed(2) + ' s) | ' + row.detail);
  if (row.result === 'FAIL') console.log('\nFAIL ' + row.check + ' (first 15 output lines):\n' + row.output.split(/\r?\n/).slice(0, 15).join('\n'));
}

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
      // Issue 1194: tmo.bat hands steps to the installed tools_live copy; a check tests this checkout's own watchdog.
      const child = spawn(process.execPath, childArgs, { cwd: ROOT, env: { ...process.env, VS_ROOT: ROOT, TMO_OWN_COPY: '1' }, windowsHide: true });
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
    // Issue 1530: the auto-discovered job head test can pass its static checks while skipping PowerShell.
    // GitHub's Ubuntu runner includes pwsh. Require the live suite's final verdict in CI.
    if (c.name === 'opus_job_head_tests' && process.env.CI && verdict.result === 'PASS' && !/^PASS ps1 fixtures:/m.test(run.output)) {
      verdict = { result: 'FAIL', detail: 'FAIL: PowerShell job head fixtures did not finish in CI (requires pwsh on Ubuntu)' };
    }
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

// Issue 1489 (audit GH-07): --jobs N runs up to N rows at once (GitHub passes --jobs 4). Each row still prints its
// "Running" line when it starts and its result line, with any failure detail, in one piece when it ends; the final table
// keeps the list order, so the table and exit code are the same as a serial run. Without --jobs it stays serial (1),
// so a PC run reads its log live row by row as before (issue 962).
async function main() {
  const args = process.argv.slice(2);
  let only, jobs = 1;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--only' && args[i + 1] && !args[i + 1].startsWith('--')) only = args[++i];
    else if (args[i] === '--jobs' && /^[1-9][0-9]?$/.test(args[i + 1] || '')) jobs = Number(args[++i]);
    else if (!['--json', '--fast'].includes(args[i])) { console.error('Usage: node run_all_checks.js [--json] [--fast] [--only <name>] [--jobs <1-99>]'); process.exit(1); }
  }
  const baseline = readBaseline();
  const checks = buildChecks();
  if (only && !checks.some(c => c.name === only || c.file === only)) { console.error('Unknown check: ' + only + '\nNames: ' + checks.map(c => c.name).join(', ')); process.exit(1); }
  const selected = checks.filter(c => !only || c.name === only || c.file === only);
  const report = new Array(selected.length);
  const runOne = async (c, i) => {
    // A gating row is never downgraded to SKIP: --fast still runs it, and a SKIP that still happens is a FAIL.
    // Issue 946: --fast selects by the fast mark from the timed run, not by the limit.
    if (args.includes('--fast') && !c.fast && !c.gate) {
      const row = { check: c.name, result: 'SKIP', seconds: 0, detail: 'SKIP: fast', output: '' };
      report[i] = row;
      console.log('Running ' + c.name + ' (limit ' + c.timeout + ' s)...');
      printRow(row);
      return;
    }
    console.log('Running ' + c.name + ' (limit ' + c.timeout + ' s)...');
    const row = await execute(c, baseline);
    if (c.gate && row.result === 'SKIP') { row.result = 'FAIL'; row.detail = 'FAIL: gating row would skip: ' + row.detail; }
    report[i] = row;
    printRow(row);
  };
  // With more than one job, the slow rows start first (600 s limit, then rows without the fast mark), so one long row
  // does not start last and hold the run; the table order does not change.
  const rank = c => (c.timeout > 300 ? 0 : c.fast ? 2 : 1);
  const order = selected.map((c, i) => i);
  if (jobs > 1) order.sort((a, b) => rank(selected[a]) - rank(selected[b]) || a - b);
  let next = 0;
  const worker = async () => { while (next < order.length) { const i = order[next++]; await runOne(selected[i], i); } };
  await Promise.all(Array.from({ length: Math.min(jobs, selected.length || 1) }, worker));
  console.log('\ncheck | result | seconds | detail');
  console.log('--- | --- | --- | ---');
  for (const r of report) console.log(`${r.check} | ${r.result} | ${r.seconds.toFixed(2)} | ${r.detail}`);
  const skipped = report.filter(r => r.result === 'SKIP').map(r => r.check);
  if (skipped.length) console.log('\nSKIP: ' + skipped.join(', '));
  if (args.includes('--json')) fs.writeFileSync(path.join(ROOT, 'checks_report.json'), JSON.stringify(report, null, 2) + '\n');
  process.exitCode = exitCodeFor(report);
}

if (require.main === module) {
  main().catch(e => { console.error(ascii(e.stack)); process.exitCode = 1; });
}

module.exports = { classifyFindings, classifyPack, classifyDrift, classifyNaming, classifyGeneric, verdictLine, parseFindings, exitCodeFor, ROOT, buildChecks, fastSelected };
