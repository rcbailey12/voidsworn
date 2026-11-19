'use strict';
// Reproduce the four review cases in small, isolated copies under TEMP. No checkout rules are edited.
const fs = require('node:fs'), os = require('node:os'), path = require('node:path');
const { execFileSync } = require('node:child_process');
const R = require('./records'), { check } = require('./check');
const { execute, isolated } = require('../node/run_parity');
const REPO = path.resolve(__dirname, '../../../..');
const godot = process.env.GODOT || 'godot';
const destination = path.join(REPO, 'docs/shots/saved_results');
function git(...args) { return execFileSync('git', args, { cwd: REPO, maxBuffer: 64 * 1024 * 1024 }); }
function snapshot(ref, dir) {
  const names = git('ls-tree', '-r', '--name-only', ref, '--', 'godot/rules', 'godot/campaign').toString().trim().split('\n');
  for (const f of [...names, 'godot/project.godot', 'data.js', 'core.js', 'battle.js', 'ui3d.js', 'campaign_meta.js', 'campaign_run.js', 'campaign3d.js']) {
    const target = path.join(dir, f);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, git('show', ref + ':' + f));
  }
  // Older harnesses lack PR 988's per-battle completion messages. Add only those messages,
  // keeping the historical rules, tables, scenarios, bot and record writer byte-for-byte.
  const harness = path.join(dir, 'godot/rules/test/parity_main.gd');
  if (!fs.readFileSync(harness, 'utf8').includes('batch result ')) {
    replace(harness, '\tfor name in all.keys():\n\t\tvar c := scenario',
      '\tfor name in all.keys():\n\t\tprint("batch start ", name)\n\t\tvar c := scenario');
    replace(harness, 'worst = max(worst, c); k += 1\n\tprint("batch ",',
      'worst = max(worst, c); k += 1\n\t\tprint("batch result ", name, " exit ", c)\n\tprint("batch ",');
  }
}
function replace(file, before, after) {
  const s = fs.readFileSync(file, 'utf8');
  if (s.split(before).length !== 2) throw Error('expected exactly one fault site in ' + file);
  fs.writeFileSync(file, s.replace(before, after));
}
async function processRun(exe, args, log, env = process.env, start = false) {
  const r = await execute(exe, args, log, env, 1200, start);
  const output = fs.readFileSync(log, 'utf8');
  if (r.code !== 0 || r.error || r.timeout || r.signal || /SCRIPT ERROR|NOT PORTED:|Parse Error|^ERROR:/m.test(output))
    throw Error('pilot process failed: ' + log + '\n' + output.slice(-2000));
  return r;
}
async function run(project, out) {
  const s = R.json(path.join(project, 'godot/rules/test/scenarios.json')), names = Object.keys(s);
  for (const dir of ['out', 'golden', 'workers']) fs.mkdirSync(path.join(out, dir), { recursive: true });
  const started = Date.now(), batch = { names, workers: [] };
  await Promise.all(Array.from({ length: 4 }, async (_, id) => {
    const list = names.filter((_, i) => i % 4 === id), file = path.join(out, 'workers', id + '.json'), log = file + '.log';
    fs.writeFileSync(file, JSON.stringify(Object.fromEntries(list.map(n => [n, s[n]]))));
    const godotResult = await processRun(godot, ['--headless', '--path', path.join(project, 'godot'), '--script',
      'res://rules/test/parity_main.gd', '--', 'batch', file, path.join(out, 'out')], log, isolated(log + '.user'), process.platform === 'win32');
    batch.workers.push({ id, names: list, file, log, godot: godotResult });
    console.log('  pilot worker ' + id + ' finished');
  }));
  batch.workers.sort((a, b) => a.id - b.id);
  fs.writeFileSync(path.join(out, 'batches.json'), JSON.stringify(batch, null, 2));
  const bad = R.evidence(out, names, s);
  if (Object.keys(bad).length) throw Error(JSON.stringify(bad));
  const gd = async (args, log) => processRun(godot, ['--headless', '--path', path.join(project, 'godot'), '--script',
    'res://rules/test/parity_main.gd', '--', ...args], log, isolated(log + '.user'));
  for (const seed of ['1001', '7', '4242424242']) {
    const f = path.join(out, 'out', 'prng_' + seed + '.txt');
    await gd(['prng', seed, '10000', f], f + '.log');
  }
  const math = path.join(out, 'golden/math.txt');
  await processRun(process.execPath, [path.join(project, 'godot/rules/test/node/golden.js'), 'math', math], math + '.log');
  await gd(['math', math], path.join(out, 'out/math.txt'));
  for (const n of ['s4', 's19', 's23']) {
    const f = path.join(out, 'out', 'threat_' + n + '.json');
    await gd(['threat', n, f], f + '.log');
  }
  console.log('  Godot run finished in ' + ((Date.now() - started) / 1000).toFixed(3) + ' s');
  return { scenarios: path.join(project, 'godot/rules/test/scenarios.json'), out, seconds: (Date.now() - started) / 1000 };
}
function saveRun(run, dir) {
  const s = R.json(run.scenarios), m = { version: 1, compression: 'brotli-5-window24', battles: {}, files: {} };
  for (const n of Object.keys(s)) {
    const bytes = R.read(path.join(run.out, 'out', n + '.jsonl'));
    m.battles[n] = { ...R.pack(dir, n + '.jsonl', bytes), records: R.records(bytes).length, scenario_sha256: R.sha(R.stable(s[n])) };
  }
  for (const n of R.FILES) m.files[n] = R.pack(dir, n, R.auxiliary(run.out, n));
  fs.writeFileSync(path.join(dir, 'results.json'), JSON.stringify(m, null, 2));
}
async function parityChanged(project, run, names) {
  await Promise.all(Array.from({ length: 4 }, async (_, id) => {
    for (const n of names.filter((_, i) => i % 4 === id)) {
      const f = path.join(run.out, 'golden', n + '.jsonl');
      await processRun(process.execPath, [path.join(project, 'godot/rules/test/node/golden.js'), 'scenario', n, f], f + '.log');
      await processRun(process.execPath, [path.join(REPO, 'godot/rules/test/node/compare.js'), 'scenario', f,
        path.join(run.out, 'out', n + '.jsonl')], f + '.compare');
    }
  }));
}
async function main() {
  const args = process.argv.slice(2);
  if (args.length && (args.length !== 2 || args[0] !== '--resume')) throw Error('usage: pilot.js [--resume <pilot scratch folder>]');
  const parent = args.length ? path.resolve(args[1]) : fs.mkdtempSync(path.join(os.tmpdir(), 'issue990-pilot-'));
  console.log('Pilot scratch: ' + parent);
  const base = git('rev-parse', 'HEAD').toString().trim();
  const evidence = args.length ? R.json(path.join(destination, 'pilot.json')) : { base, cases: [] };
  if (evidence.base !== base) throw Error('resume source base differs');
  fs.mkdirSync(destination, { recursive: true });
  // Serial cases keep PC load bounded; four headless workers within each case.
  for (const fault of ['F2', 'F5']) {
    if (evidence.cases.some(c => c.name === fault)) continue;
    console.log('Running ' + fault);
    const project = path.join(parent, fault, 'project'); snapshot(base, project);
    if (fault === 'F2') {
      const data = path.join(project, 'data.js'), s = fs.readFileSync(data, 'utf8');
      const re = /(d_jackal:\s*\{[^\n]*?hp:)100\b/;
      if (!re.test(s)) throw Error('F2 hull fault site absent');
      fs.writeFileSync(data, s.replace(re, (_, prefix) => prefix + '90'));
      await processRun(process.execPath, [path.join(project, 'godot/rules/test/node/export_data.js'),
        path.join(project, 'godot/rules/data/tables.json')], path.join(parent, fault, 'export.log'));
      fs.mkdirSync(path.join(project, 'godot/campaign/data'), { recursive: true });
      await processRun(process.execPath, [path.join(project, 'godot/campaign/test/node/export_campaign.js'),
        path.join(project, 'godot/campaign/data/campaign_tables.json')], path.join(parent, fault, 'export_campaign.log'));
    } else {
      replace(path.join(project, 'battle.js'), "hdist(u,t)>w.r/2) m+=treeAddVal", "hdist(u,t)>=w.r/2) m+=treeAddVal");
      replace(path.join(project, 'godot/rules/rules.gd'), 'hdist(u, t) > float(w["r"]) / 2.0: m += treeAddVal',
        'hdist(u, t) >= float(w["r"]) / 2.0: m += treeAddVal');
    }
    const runResult = await run(project, path.join(parent, fault, 'run'));
    const result = check(runResult.out, { scenarios: runResult.scenarios });
    const report = fs.readFileSync(path.join(runResult.out, 'changed-battles.txt'), 'utf8');
    const names = [...report.matchAll(/^FAIL battle (\w+)$/gm)].map(m => m[1]);
    if (!names.length || names.length !== result.changed) throw Error('fault did not produce valid changed battles');
    await parityChanged(project, runResult, names);
    const reportFile = fault.toLowerCase() + '.txt'; fs.writeFileSync(path.join(destination, reportFile), report);
    evidence.cases.push({ name: fault, ...result, report: reportFile, lines: report.trimEnd().split('\n').length,
      bytes: Buffer.byteLength(report), godot_seconds: runResult.seconds, parity_passed_changed_battles: names });
    fs.writeFileSync(path.join(destination, 'pilot.json'), JSON.stringify(evidence, null, 2) + '\n');
  }
  // PR 449 is an extra representation-only control, not one of the two changes to actual play.
  for (const [pr, commit] of [[442, '5120c90325f48943f0d132746412abe6b30d7389'],
    [449, '3e0e015d8c50b6920beeb73514bb56151f7e5d41'], [797, '67b1894912560ccb0eac1ae7d5199713fbafb808']]) {
    if (evidence.cases.some(c => c.commit === commit)) continue;
    console.log('Running historical PR ' + pr);
    const runs = [], projects = [];
    const attempt = fs.mkdtempSync(path.join(parent, 'pr' + pr + '-'));
    for (const [arm, ref] of [['before', commit + '^'], ['after', commit]]) {
      const project = path.join(attempt, arm, 'project'); snapshot(ref, project); projects.push(project);
    }
    // A PR may reseed fixtures as well as change rules. Use its merged suite in BOTH arms,
    // so the measured difference comes from the real before/after rules, never different seeds.
    const scenarioPaths = projects.map(p => path.join(p, 'godot/rules/test/scenarios.json'));
    const oldScenarios = R.json(scenarioPaths[0]), suite = R.json(scenarioPaths[1]);
    const changedInputs = [...new Set([...Object.keys(oldScenarios), ...Object.keys(suite)])]
      .filter(n => R.stable(oldScenarios[n] || null) !== R.stable(suite[n] || null));
    fs.writeFileSync(scenarioPaths[0], fs.readFileSync(scenarioPaths[1]));
    for (let i = 0; i < projects.length; i++) runs.push(await run(projects[i], path.join(attempt, i ? 'after/run' : 'before/run')));
    if (R.stable(R.json(runs[0].scenarios)) !== R.stable(R.json(runs[1].scenarios))) throw Error('historical scenario suite changed');
    const saved = path.join(attempt, 'saved'); saveRun(runs[0], saved);
    const result = check(runs[1].out, { saved, scenarios: runs[1].scenarios });
    const report = fs.readFileSync(path.join(runs[1].out, 'changed-battles.txt'), 'utf8');
    if (!result.changed) throw Error('historical PR did not change any battle');
    const reportFile = 'pr' + pr + '.txt'; fs.writeFileSync(path.join(destination, reportFile), report);
    evidence.cases.push({ name: 'PR ' + pr, commit, before: git('rev-parse', commit + '^').toString().trim(),
      scenario_source: commit, changed_scenario_inputs_held_constant: changedInputs,
      ...result, report: reportFile, lines: report.trimEnd().split('\n').length, bytes: Buffer.byteLength(report),
      godot_before_seconds: runs[0].seconds, godot_after_seconds: runs[1].seconds });
    fs.writeFileSync(path.join(destination, 'pilot.json'), JSON.stringify(evidence, null, 2) + '\n');
  }
  console.log('Pilot complete: ' + destination);
}
main().catch(e => { console.error('FAIL: pilot: ' + e.stack); process.exitCode = 1; });
