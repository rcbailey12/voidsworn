#!/usr/bin/env node
'use strict';
/*
 * gate.js - the Voidsworn cutover gate.
 *
 * One runner for every verification tool the audit programs built, with one
 * verdict language. Each component runs as a child process with a timeout;
 * its output is reduced to a signature (the set of things currently failing,
 * the set currently passing, and headline counts) and compared against
 * baseline.json beside this file.
 *
 * Verdicts:
 *   PASS        the component ran and its signature matches the baseline,
 *               and the baseline state is clean for that component.
 *   KNOWN-FAIL  the signature matches the baseline, and the baseline state
 *               contains known failures (for the findings suite, a FAIL is a
 *               pinned, still-unfixed defect: matching the baseline means
 *               nothing moved).
 *   REGRESSION  something that was passing or absent from the failure set
 *               is failing now, or a tracked item vanished entirely.
 *   IMPROVEMENT something in the baseline failure set no longer fails. A
 *               fix landed, or a test rotted: either way a human should
 *               look, then refresh the baseline deliberately.
 *   NOT RUN     the component is missing, cannot run headlessly, timed out,
 *               or errored. Never reported as a pass.
 *
 * Usage:
 *   node gate.js [repoDir] [--update-baseline] [--out <dir>]
 *
 * repoDir defaults to: the repo this gate is installed in (four levels up
 * from contrib/muse/tools/cutover_gate, when battle.js is found there),
 * else ~/workspace/voidsworn-fresh.
 *
 * The baseline is only ever rewritten by an explicit --update-baseline run.
 * Reports (gate_report.md, gate_report.json) are written to --out, default
 * this folder. The gate never modifies the repo it checks; components that
 * write files (the telemetry demo) run from a scratch copy inside this
 * folder.
 *
 * Exit code: 0 when the overall verdict is PASS, NO CHANGE, or IMPROVEMENT;
 * 1 when it is REGRESSION or INCOMPLETE (a component did not run).
 * No dependencies beyond Node itself.
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const GATE_DIR = __dirname;
const SCRATCH = path.join(GATE_DIR, 'scratch');
const BASELINE_PATH = path.join(GATE_DIR, 'baseline.json');

// ------------------------------------------------------------------ helpers

function sanitize(s) {
  // Component output can carry typographic dashes from game strings; the
  // gate's own deliverables are ASCII-dash only.
  return String(s).replace(/[\u2010-\u2015]/g, '-');
}
function uniqSorted(a) { return [...new Set(a)].sort(); }
function diff(a, b) { const s = new Set(b); return a.filter(x => !s.has(x)); }
function run(cmd, args, opts) {
  const started = Date.now();
  const r = spawnSync(cmd, args, Object.assign({
    encoding: 'utf8', maxBuffer: 128 * 1024 * 1024, windowsHide: true,
  }, opts || {}));
  const ms = Date.now() - started;
  if (r.error && r.error.code === 'ETIMEDOUT') {
    return { timedOut: true, ms, stdout: r.stdout || '', stderr: r.stderr || '' };
  }
  if (r.error) return { spawnError: r.error.message, ms, stdout: '', stderr: '', status: null };
  return { status: r.status, ms, stdout: r.stdout || '', stderr: r.stderr || '' };
}
function repoHead(repo) {
  const r = spawnSync('git', ['-C', repo, 'rev-parse', 'HEAD'], { encoding: 'utf8', windowsHide: true });
  if (r.status === 0 && r.stdout) return r.stdout.trim();
  return 'unknown (git unavailable or not a checkout)';
}

// ------------------------------------------------------- component plumbing
// A component returns one of:
//   { notRun: 'reason' }
//   { signature: {...}, badSet: [...], goodSet: [...], watchSet: [...],
//     cleanWhenUnchanged: bool, summary: 'one line' }
// badSet: ids failing right now. goodSet: ids passing right now.
// watchSet: ids worth reporting when they change (warnings, candidates),
//           but which do not drive the verdict on their own.

function classify(cur, base, cleanWhenUnchanged) {
  if (!base) {
    return {
      verdict: cur.badSet.length ? 'KNOWN-FAIL' : 'PASS',
      deltas: { note: 'no baseline recorded for this component; verdict is against an empty baseline. Run --update-baseline to record the current state.' },
    };
  }
  const newBad = diff(cur.badSet, base.badSet || []);
  const fixedBad = diff(base.badSet || [], cur.badSet);
  const lostGood = diff(base.goodSet || [], (cur.goodSet || []).concat(cur.badSet));
  const newGood = diff(cur.goodSet || [], (base.goodSet || []).concat(base.badSet || []));
  const watchNew = diff(cur.watchSet || [], base.watchSet || []);
  const watchGone = diff(base.watchSet || [], cur.watchSet || []);
  const deltas = { newFailures: newBad, fixed: fixedBad, lostPassing: lostGood, newPassing: newGood, watchNew, watchGone };
  if (newBad.length || lostGood.length) return { verdict: 'REGRESSION', deltas };
  if (fixedBad.length || newGood.length) return { verdict: 'IMPROVEMENT', deltas };
  return { verdict: cleanWhenUnchanged ? 'PASS' : 'KNOWN-FAIL', deltas };
}

// ------------------------------------------------------------ the components

function compFindings(ctx) {
  const script = ctx.find('findings_tests', 'findings_tests.js');
  if (!script) return { notRun: 'findings_tests.js not found under any tools root' };
  const r = run(process.execPath, [script, ctx.repo], { timeout: 900000 });
  if (r.timedOut) return { notRun: 'timed out after 900s' };
  if (r.spawnError) return { notRun: 'spawn failed: ' + r.spawnError };
  ctx.lastRun = r;
  const passIds = [], failIds = [];
  let counts = null;
  for (const line of r.stdout.split('\n')) {
    // Test titles are full sentences ("UI-8 auto-facing weighs ..."); the
    // stable identity is the leading ledger code token (UI-8, VAR-1a, W3-1).
    let m = line.match(/^PASS (\S+)\s/); if (m) { passIds.push(m[1]); continue; }
    m = line.match(/^FAIL (\S+)\s/); if (m) { failIds.push(m[1]); continue; }
    m = line.match(/^(\d+) tests, (\d+) pass, (\d+) fail/);
    if (m) counts = { total: +m[1], pass: +m[2], fail: +m[3] };
  }
  if (!counts) return { notRun: 'suite produced no summary line (exit ' + r.status + ')' };
  if (passIds.length !== counts.pass || failIds.length !== counts.fail) {
    return { notRun: 'per-test lines did not parse to the summary counts (' + passIds.length + '/' + failIds.length +
      ' ids vs ' + counts.pass + '/' + counts.fail + ' in the summary); refusing to guess a signature' };
  }
  return {
    signature: { total: counts.total, pass: counts.pass, fail: counts.fail },
    badSet: uniqSorted(failIds), goodSet: uniqSorted(passIds), watchSet: [],
    cleanWhenUnchanged: false,
    summary: counts.total + ' tests, ' + counts.pass + ' pass, ' + counts.fail + ' fail (a fail is a pinned, unfixed defect)',
  };
}

function compDrift(ctx) {
  const script = ctx.find('oracle_drift', 'oracle_drift_guard.js');
  if (!script) return { notRun: 'oracle_drift_guard.js not found under any tools root' };
  const r = run(process.execPath, [script, ctx.repo, '--json'], { timeout: 180000 });
  if (r.timedOut) return { notRun: 'timed out after 180s' };
  if (r.spawnError) return { notRun: 'spawn failed: ' + r.spawnError };
  ctx.lastRun = r;
  if (r.status !== 0) return { notRun: 'drift guard run failed with exit ' + r.status + ' (its exit 2 means the run itself failed)' };
  let j;
  try { j = JSON.parse(r.stdout); } catch (e) { return { notRun: 'drift guard output was not JSON: ' + e.message }; }
  const bad = [];
  for (const f of Object.keys(j.vendored.files)) {
    for (const p of j.vendored.files[f].pairs) if (!p.equal) bad.push(f + ':' + p.a + '-vs-' + p.b);
  }
  for (const s of j.pins.suites) {
    for (const c of s.claims) {
      if (!c.files) continue;
      for (const f of Object.keys(c.files)) {
        const cf = c.files[f];
        if (cf.matchesPinContent === false && !cf.disclosedException) bad.push('pin:' + s.id + ':' + f);
      }
    }
  }
  for (const c of j.constantsCheck.constants) {
    for (const d of c.differed) bad.push('const:' + c.name + ':' + d.key);
  }
  const sm = j.summary;
  return {
    signature: {
      vendoredPairs: sm.vendoredPairs, vendoredDiffering: sm.vendoredDiffering,
      pinClaimsChecked: sm.pinClaimsChecked, pinClaimsHeld: sm.pinClaimsHeld, pinClaimsFailed: sm.pinClaimsFailed,
      constCompared: sm.constCompared, constMatched: sm.constMatched, constDiffered: sm.constDiffered,
      constOnlyBrowser: sm.constOnlyBrowser, constOnlyGodot: sm.constOnlyGodot,
    },
    badSet: uniqSorted(bad), goodSet: [], watchSet: [],
    cleanWhenUnchanged: false,
    summary: 'oracle pins ' + sm.pinClaimsHeld + '/' + sm.pinClaimsChecked + ' held, ' +
      sm.vendoredDiffering + ' of ' + sm.vendoredPairs + ' vendored pairs differ, constants ' +
      sm.constMatched + '/' + sm.constCompared + ' matched (' + sm.constDiffered + ' differed, ' +
      sm.constOnlyBrowser + ' browser-only): the recorded state is staleness, not corruption',
  };
}

function compXref(ctx) {
  const script = ctx.find(path.join('harness', 'validators'), 'table_xref.js');
  if (!script) return { notRun: 'table_xref.js not found under any tools root' };
  const r = run(process.execPath, [script, ctx.repo], { timeout: 120000 });
  if (r.timedOut) return { notRun: 'timed out after 120s' };
  if (r.spawnError) return { notRun: 'spawn failed: ' + r.spawnError };
  ctx.lastRun = r;
  const m = r.stdout.match(/table_xref: (\d+) failures, (\d+) warnings/);
  if (!m) return { notRun: 'validator produced no summary line (exit ' + r.status + ')' };
  const fails = [], warns = [];
  for (const line of r.stdout.split('\n')) {
    if (line.startsWith('FAIL ')) fails.push(sanitize(line.slice(5).trim()));
    if (line.startsWith('WARN ')) warns.push(sanitize(line.slice(5).trim()));
  }
  return {
    signature: { failures: +m[1], warnings: +m[2] },
    badSet: uniqSorted(fails), goodSet: [], watchSet: uniqSorted(warns),
    cleanWhenUnchanged: true,
    summary: m[1] + ' dangling-reference failures, ' + m[2] + ' warnings (warnings are the known watch list)',
  };
}

function compNaming(ctx) {
  const script = ctx.find(path.join('harness', 'validators'), 'naming_lint.js');
  if (!script) return { notRun: 'naming_lint.js not found under any tools root' };
  const targets = [];
  for (const t of ['NEXT.md', 'PROGRESS.md', 'BACKLOG.md', 'HANDOFF.md', 'CLAUDE.md', 'AGENTS.md', 'docs']) {
    const p = path.join(ctx.repo, t);
    if (fs.existsSync(p)) targets.push(p);
  }
  if (!targets.length) return { notRun: 'no current-voice documents found in the repo to lint' };
  const r = run(process.execPath, [script].concat(targets), { timeout: 120000 });
  if (r.timedOut) return { notRun: 'timed out after 120s' };
  if (r.spawnError) return { notRun: 'spawn failed: ' + r.spawnError };
  ctx.lastRun = r;
  const m = r.stdout.match(/naming_lint: (\d+) hard hits, (\d+) current-voice candidates, (\d+) historical\/id mentions/);
  if (!m) return { notRun: 'linter produced no summary line (exit ' + r.status + ')' };
  const hard = [], cand = [];
  for (const line of r.stdout.split('\n')) {
    let mm = line.match(/^HARD (.+):\d+ "([^"]+)"/);
    if (mm) { hard.push(sanitize(mm[2] + ' @ ' + path.relative(ctx.repo, mm[1]))); continue; }
    mm = line.match(/^CANDIDATE (.+):\d+ "([^"]+)"/);
    if (mm) cand.push(sanitize(mm[2] + ' @ ' + path.relative(ctx.repo, mm[1])));
  }
  return {
    signature: { hard: +m[1], candidates: +m[2], historical: +m[3] },
    badSet: uniqSorted(hard), goodSet: [], watchSet: uniqSorted(cand),
    cleanWhenUnchanged: false,
    summary: m[1] + ' hard hits (retired display names in current-voice docs), ' + m[2] +
      ' label candidates for human triage, ' + m[3] + ' historical/id mentions (info)',
  };
}

function compImporter(ctx) {
  const script = ctx.find('importer_reference', 'run_tests.js');
  if (!script) return { notRun: 'importer_reference/run_tests.js not found under any tools root' };
  const r = run(process.execPath, [script, '--game-dir=' + ctx.repo], { timeout: 300000 });
  if (r.timedOut) return { notRun: 'timed out after 300s' };
  if (r.spawnError) return { notRun: 'spawn failed: ' + r.spawnError };
  ctx.lastRun = r;
  const passIds = [], failIds = [];
  let total = null;
  for (const line of r.stdout.split('\n')) {
    let m = line.match(/^PASS (.+?)\s*$/); if (m) { passIds.push(sanitize(m[1])); continue; }
    m = line.match(/^FAIL (.+?)\s*$/); if (m) { failIds.push(sanitize(m[1])); continue; }
    m = line.match(/All checks \(fixtures \+ synthetic\): (\d+)\/(\d+) passing/);
    if (m) total = { passed: +m[1], total: +m[2] };
  }
  if (!total) return { notRun: 'test runner produced no summary line (exit ' + r.status + ')' };
  return {
    signature: total,
    badSet: uniqSorted(failIds), goodSet: uniqSorted(passIds), watchSet: [],
    cleanWhenUnchanged: true,
    summary: total.passed + '/' + total.total + ' converter checks pass (21 fixture cases plus the synthetic repaired-copy fallback)',
  };
}

function compFixtures(ctx) {
  const fixDir = ctx.findDir('importer_fixtures');
  const loader = ctx.find('harness', 'game_loader.js');
  if (!fixDir) return { notRun: 'importer_fixtures tree not found under any tools root' };
  if (!loader) return { notRun: 'harness/game_loader.js not found under any tools root' };
  const checker = path.join(GATE_DIR, 'fixture_check.js');
  const r = run(process.execPath, [checker, ctx.repo, fixDir, loader], { timeout: 300000 });
  if (r.timedOut) return { notRun: 'timed out after 300s' };
  if (r.spawnError) return { notRun: 'spawn failed: ' + r.spawnError };
  ctx.lastRun = r;
  const passIds = [], failIds = [];
  let total = null;
  for (const line of r.stdout.split('\n')) {
    let m = line.match(/^PASS fixture (.+?)\s*$/); if (m) { passIds.push(m[1]); continue; }
    m = line.match(/^FAIL fixture (.+?):/); if (m) { failIds.push(m[1]); continue; }
    m = line.match(/fixture_check: (\d+)\/(\d+) cases passing/);
    if (m) total = { passed: +m[1], total: +m[2] };
  }
  if (!total) return { notRun: 'fixture check produced no summary line (exit ' + r.status + ')' };
  return {
    signature: total,
    badSet: uniqSorted(failIds), goodSet: uniqSorted(passIds), watchSet: [],
    cleanWhenUnchanged: true,
    summary: total.passed + '/' + total.total + ' fixture stores load through the game\'s own loadLocal, pass saneSave, and match their recorded loaded state',
  };
}

function compTelemetry(ctx) {
  const srcDir = ctx.findDir('telemetry_reference');
  if (!srcDir) return { notRun: 'telemetry_reference tree not found under any tools root' };
  // run_demo.js writes dataset.jsonl beside itself; run it from a scratch
  // copy inside the gate folder so the checked tree is never written to.
  const copyDir = path.join(SCRATCH, 'telemetry_reference');
  fs.rmSync(copyDir, { recursive: true, force: true });
  fs.mkdirSync(copyDir, { recursive: true });
  for (const f of fs.readdirSync(srcDir)) {
    if (f.endsWith('.js')) fs.copyFileSync(path.join(srcDir, f), path.join(copyDir, f));
  }
  const r = run(process.execPath, [path.join(copyDir, 'run_demo.js')], { timeout: 120000, cwd: copyDir });
  if (r.timedOut) return { notRun: 'timed out after 120s' };
  if (r.spawnError) return { notRun: 'spawn failed: ' + r.spawnError };
  ctx.lastRun = r;
  const passes = r.status === 0 && /DEMONSTRATION PASSES/.test(r.stdout);
  return {
    signature: { demonstrationPasses: passes },
    badSet: passes ? [] : ['telemetry:lineage-join-demonstration'],
    goodSet: passes ? ['telemetry:lineage-join-demonstration'] : [],
    watchSet: [],
    cleanWhenUnchanged: true,
    summary: passes
      ? 'reference logger demonstration passes: the filed same-run join misses the inherited-weakness violation, the lineage join catches it with no false positive'
      : 'reference logger demonstration did not produce the expected pattern (exit ' + r.status + ')',
  };
}

function compParity(ctx) {
  // PLUG-IN SLOT: the parity vector corpus (beyond-scope slate 3 item) is
  // not built yet. When it lands, its runner is expected at
  // <tools>/parity_vectors/run_vectors.js and must print a summary line of
  // the form:  parity_vectors: <pass> pass, <fail> fail, <total> total
  // Until then this component reports NOT RUN, never a pass.
  const script = ctx.find('parity_vectors', 'run_vectors.js');
  if (!script) {
    return { notRun: 'parity vector corpus not built yet (beyond-scope slate 3 item); this slot activates automatically when parity_vectors/run_vectors.js exists' };
  }
  const r = run(process.execPath, [script, ctx.repo], { timeout: 600000 });
  if (r.timedOut) return { notRun: 'timed out after 600s' };
  if (r.spawnError) return { notRun: 'spawn failed: ' + r.spawnError };
  ctx.lastRun = r;
  const passIds = [], failIds = [];
  let counts = null;
  for (const line of r.stdout.split('\n')) {
    let m = line.match(/^PASS vector (\S+)/); if (m) { passIds.push(m[1]); continue; }
    m = line.match(/^FAIL vector (\S+)/); if (m) { failIds.push(m[1]); continue; }
    m = line.match(/parity_vectors: (\d+) pass, (\d+) fail, (\d+) total/);
    if (m) counts = { pass: +m[1], fail: +m[2], total: +m[3] };
  }
  if (!counts) return { notRun: 'vector runner produced no summary line (exit ' + r.status + ')' };
  return {
    signature: counts,
    badSet: uniqSorted(failIds), goodSet: uniqSorted(passIds), watchSet: [],
    cleanWhenUnchanged: false,
    summary: counts.total + ' parity vectors, ' + counts.pass + ' pass, ' + counts.fail + ' fail',
  };
}

const COMPONENTS = [
  { id: 'findings_tests', title: 'Findings regression suite', run: compFindings,
    proves: 'Every BLOCKER/FIX finding from the audit programs stays pinned by a test that fails while the defect is unfixed and flips when a fix lands.' },
  { id: 'oracle_drift', title: 'Oracle drift guard', run: compDrift,
    proves: 'The Godot port\'s vendored JS oracles and hand-copied constants have not drifted beyond the recorded staleness, and every README pin claim still holds against git history.' },
  { id: 'table_xref', title: 'Validator: table cross-references', run: compXref,
    proves: 'No id in the game data tables dangles: rosters, weapons, patrons, relic names, price and gate rows all resolve.' },
  { id: 'naming_lint', title: 'Validator: naming linter', run: compNaming,
    proves: 'Current-voice documents do not use retired display names (hard hits), and old faction labels are triaged (candidates).' },
  { id: 'importer_fixtures', title: 'Importer fixture loader checks', run: compFixtures,
    proves: 'All 21 recorded browser save stores still load through the game\'s own loadLocal, pass saneSave, and produce exactly their recorded loaded state.' },
  { id: 'importer_reference', title: 'Importer reference converter tests', run: compImporter,
    proves: 'The reference browser-to-portable save converter converts every fixture with complete accounting: no id or value disappears unreported.' },
  { id: 'telemetry_reference', title: 'Telemetry reference demonstration', run: compTelemetry,
    proves: 'The telemetry spec addendum\'s lineage join catches the cross-run Nemesis adaptation clash that the filed same-run join misses.' },
  { id: 'parity_vectors', title: 'Parity vector corpus (plug-in slot)', run: compParity,
    proves: 'When built (beyond-scope slate 3 item): deterministic battle-layer behavior vectors captured from the browser engine match the Godot port\'s replays.' },
];

// --------------------------------------------------------------------- main

function main() {
  const argv = process.argv.slice(2);
  const updateBaseline = argv.includes('--update-baseline');
  let outDir = GATE_DIR;
  const oi = argv.indexOf('--out');
  if (oi >= 0 && argv[oi + 1]) outDir = path.resolve(argv[oi + 1]);
  const positional = argv.filter((a, i) => !a.startsWith('--') && argv[i - 1] !== '--out');

  let repo = positional[0] ? path.resolve(positional[0]) : null;
  if (!repo) {
    const installedRoot = path.resolve(GATE_DIR, '..', '..', '..', '..');
    if (fs.existsSync(path.join(installedRoot, 'battle.js'))) repo = installedRoot;
    else repo = path.join(os.homedir(), 'workspace', 'voidsworn-fresh');
  }
  if (!fs.existsSync(path.join(repo, 'data.js')) || !fs.existsSync(path.join(repo, 'core.js'))) {
    console.error('gate: repo not recognised at ' + repo + ' (needs data.js and core.js at the top level)');
    process.exit(2);
  }

  // Tools roots, in preference order: the tree this gate lives in, the
  // checked repo's own contrib tools, then the chair staging tree.
  const roots = [];
  const addRoot = (p, label) => { if (p && fs.existsSync(p) && !roots.some(r => r.p === p)) roots.push({ p, label }); };
  addRoot(path.resolve(GATE_DIR, '..'), 'the tools tree this gate is installed in');
  addRoot(path.join(repo, 'contrib', 'muse', 'tools'), 'the checked repo\'s contrib/muse/tools');
  addRoot(path.join(os.homedir(), 'workspace', 'voidsworn-reviews-staging', 'contrib', 'muse', 'tools'), 'the chair staging tree');

  const ctx = {
    repo,
    lastRun: null,
    find(sub, file) {
      for (const r of roots) {
        const p = path.join(r.p, sub, file);
        if (fs.existsSync(p)) return p;
      }
      return null;
    },
    findDir(sub) {
      for (const r of roots) {
        const p = path.join(r.p, sub);
        if (fs.existsSync(p)) return p;
      }
      return null;
    },
  };

  let baseline = null;
  if (fs.existsSync(BASELINE_PATH)) {
    try { baseline = JSON.parse(fs.readFileSync(BASELINE_PATH, 'utf8')); }
    catch (e) { console.error('gate: baseline.json is unreadable (' + e.message + '); treating as no baseline'); }
  }

  fs.mkdirSync(SCRATCH, { recursive: true });
  const head = repoHead(repo);
  const startedAt = new Date();
  const results = [];
  for (const comp of COMPONENTS) {
    ctx.lastRun = null;
    const t0 = Date.now();
    let out;
    try { out = comp.run(ctx); }
    catch (e) { out = { notRun: 'component threw: ' + sanitize(e.message) }; }
    const ms = ctx.lastRun ? ctx.lastRun.ms : (Date.now() - t0);
    if (out.notRun) {
      results.push({ id: comp.id, title: comp.title, proves: comp.proves, verdict: 'NOT RUN', reason: sanitize(out.notRun), ms });
      continue;
    }
    const base = baseline && baseline.components ? baseline.components[comp.id] : null;
    const c = classify(out, base, out.cleanWhenUnchanged);
    results.push({
      id: comp.id, title: comp.title, proves: comp.proves,
      verdict: c.verdict, ms, summary: sanitize(out.summary),
      signature: out.signature,
      badSet: out.badSet, goodSet: out.goodSet, watchSet: out.watchSet,
      deltas: c.deltas,
    });
  }
  const totalMs = Date.now() - startedAt.getTime();

  if (updateBaseline) {
    const nb = {
      version: 1,
      note: 'Recorded deliberately by a gate run with --update-baseline. Signatures describe the checked repo at the HEAD below. The gate never rewrites this file on a normal run.',
      recordedAt: startedAt.toISOString(),
      repo, head,
      components: {},
    };
    for (const r of results) {
      if (r.verdict === 'NOT RUN') continue;
      nb.components[r.id] = { signature: r.signature, badSet: r.badSet, goodSet: r.goodSet, watchSet: r.watchSet };
    }
    fs.writeFileSync(BASELINE_PATH, JSON.stringify(nb, null, 2) + '\n');
  }

  const verdicts = results.map(r => r.verdict);
  let overall;
  if (verdicts.includes('REGRESSION')) overall = 'REGRESSION';
  else if (verdicts.includes('IMPROVEMENT')) overall = 'IMPROVEMENT (review, then refresh the baseline)';
  else if (verdicts.includes('NOT RUN')) overall = 'INCOMPLETE (a component did not run)';
  else if (verdicts.includes('KNOWN-FAIL')) overall = 'NO CHANGE (known state)';
  else overall = 'PASS';

  const report = {
    gate: 'voidsworn cutover gate', version: 1,
    ranAt: startedAt.toISOString(), repo, head,
    baselineRecordedAt: baseline ? baseline.recordedAt : null,
    baselineHead: baseline ? baseline.head : null,
    baselineUpdatedThisRun: updateBaseline,
    overall, totalMs,
    components: results,
  };

  // ------------------------------------------------------------- report: md
  const L = [];
  L.push('# Voidsworn cutover gate report');
  L.push('');
  L.push('Ran: ' + report.ranAt);
  L.push('Repo: ' + repo);
  L.push('Clone HEAD: ' + head);
  L.push('Baseline: ' + (baseline ? 'recorded ' + baseline.recordedAt + ' against HEAD ' + baseline.head : 'none recorded') + (updateBaseline ? ' (rewritten by this run)' : ''));
  L.push('Total runtime: ' + (totalMs / 1000).toFixed(1) + 's');
  L.push('');
  L.push('## Overall verdict: ' + overall);
  L.push('');
  L.push('| Component | Verdict | Time | Result |');
  L.push('|---|---|---|---|');
  for (const r of results) {
    L.push('| ' + r.title + ' | ' + r.verdict + ' | ' + (r.ms / 1000).toFixed(1) + 's | ' + (r.reason || r.summary) + ' |');
  }
  L.push('');
  for (const r of results) {
    L.push('## ' + r.title + ': ' + r.verdict);
    L.push('');
    L.push('What it proves: ' + r.proves);
    L.push('');
    if (r.verdict === 'NOT RUN') {
      L.push('Reason: ' + r.reason);
    } else {
      L.push('Result: ' + r.summary);
      const d = r.deltas || {};
      if (d.note) L.push('Note: ' + d.note);
      const show = (label, arr) => { if (arr && arr.length) { L.push(label + ' (' + arr.length + '):'); for (const x of arr) L.push('- ' + x); } };
      show('New failures since baseline', d.newFailures);
      show('No longer failing since baseline', d.fixed);
      show('Passing items that vanished', d.lostPassing);
      show('Newly passing items', d.newPassing);
      show('Watch list additions (warnings/candidates, not verdict-driving)', d.watchNew);
      show('Watch list removals', d.watchGone);
      const anyDelta = (d.newFailures || []).length || (d.fixed || []).length ||
        (d.lostPassing || []).length || (d.newPassing || []).length;
      if (!anyDelta && !d.note) {
        L.push('Signature matches the baseline exactly.');
      }
    }
    L.push('');
  }
  L.push('Verdict key: PASS = clean and unchanged. KNOWN-FAIL = unchanged, and the baseline itself records known failures (pinned defects, recorded drift, one lint hard hit). REGRESSION = something moved for the worse; look before anything ships. IMPROVEMENT = a baseline failure cleared; a fix landed or a test rotted, so look, then refresh the baseline with --update-baseline. NOT RUN = the component could not run; it is never counted as a pass.');
  L.push('');
  const md = sanitize(L.join('\n'));
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, 'gate_report.md'), md);
  fs.writeFileSync(path.join(outDir, 'gate_report.json'), JSON.stringify(report, null, 2) + '\n');

  console.log('Voidsworn cutover gate');
  console.log('Repo: ' + repo + ' @ ' + head);
  for (const r of results) console.log('  ' + r.verdict.padEnd(11) + ' ' + r.title + ' (' + (r.ms / 1000).toFixed(1) + 's)');
  console.log('Overall: ' + overall + ' in ' + (totalMs / 1000).toFixed(1) + 's');
  console.log('Report: ' + path.join(outDir, 'gate_report.md'));
  process.exit((overall === 'REGRESSION' || overall.startsWith('INCOMPLETE')) ? 1 : 0);
}

main();
