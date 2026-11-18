'use strict';
const fs = require('node:fs'), path = require('node:path');
const R = require('./records');
function check(root, { names, saved = R.HOME, scenarios = R.SCENARIOS, print = console.log } = {}) {
  const start = Date.now(), s = R.json(scenarios);
  names ||= Object.keys(s);
  const lines = ['Saved Godot results: changed battles', 'Later differences count changed records after the first, aligned by turn index.'];
  let failures = 0, changed = 0, filesChanged = 0;
  const fail = (label, detail) => { failures++; lines.push(`FAIL ${label}`, ...detail.map(l => '  ' + l)); };
  let m;
  try { m = R.manifest(saved); } catch (e) { fail('saved results', [e.message]); }
  if (m) {
    let bad;
    try { bad = R.evidence(root, names, s); } catch (e) { bad = Object.fromEntries(names.map(n => [n, e.message])); }
    if (names.length === Object.keys(s).length) {
      for (const n of Object.keys(m.battles).filter(n => !Object.hasOwn(s, n))) fail('battle ' + n, ['removed from scenarios; update the saved results in this pull request']);
    }
    for (const name of names) {
      try {
        if (bad[name]) throw Error(bad[name]);
        const bytes = R.read(path.join(root, 'out', name + '.jsonl'));
        const rows = R.records(bytes), entry = m.battles[name];
        if (!entry) { changed++; fail('battle ' + name, ['new battle; no saved result']); continue; }
        const before = R.unpack(saved, entry);
        if (entry.records !== R.records(before).length) throw Error('saved record count differs from manifest');
        if (R.sha(bytes) !== entry.sha256) { changed++; fail('battle ' + name, R.battleDiff(before, bytes)); }
        else if (entry.scenario_sha256 !== R.sha(R.stable(s[name]))) fail('battle ' + name, ['scenario changed but result is identical; update its saved input hash']);
        if (!rows.length) throw Error('no records');
      } catch (e) { fail('battle ' + name, [e.message]); }
    }
    for (const name of R.FILES) {
      try {
        const bytes = R.auxiliary(root, name), before = R.unpack(saved, m.files[name]);
        if (R.sha(bytes) !== m.files[name].sha256) {
          filesChanged++;
          let detail;
          if (name.startsWith('threat_')) {
            const d = R.diff(JSON.parse(before), JSON.parse(bytes), 'map');
            detail = d ? `${d.field}: ${R.value(d.before)} -> ${R.value(d.after)}` : 'bytes changed; map values identical';
          } else {
            const a = before.toString().split('\n'), b = bytes.toString().split('\n');
            const i = Array.from({ length: Math.max(a.length, b.length) }, (_, j) => j).find(j => a[j] !== b[j]);
            detail = `line ${i + 1}: ${R.value(a[i])} -> ${R.value(b[i])}`;
          }
          fail('file ' + name, [detail]);
        }
      } catch (e) { fail('file ' + name, [e.message]); }
    }
  }
  const seconds = (Date.now() - start) / 1000;
  lines.push(`${failures ? 'FAIL' : 'PASS'}: saved Godot results; ${names.length} battles checked, ${changed} changed, ${filesChanged} other files changed, ${failures} failures; ${seconds.toFixed(3)} s`);
  const report = path.join(root, 'changed-battles.txt');
  fs.writeFileSync(report, lines.join('\n') + '\n');
  const summary = { battles: names.length, changed, files_changed: filesChanged, failures, seconds };
  fs.writeFileSync(path.join(root, 'saved_summary.json'), JSON.stringify(summary, null, 2) + '\n');
  print(lines.join('\n')); print('Changed-battles report: ' + report);
  if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY,
    '\n### Saved Godot results\n\n```text\n' + lines.join('\n') + '\n```\n');
  return summary;
}
function options(args) {
  const o = {};
  for (let i = 0; i < args.length; i++) {
    if (!['--from', '--saved', '--scenarios'].includes(args[i]) || !args[i + 1]) throw Error('usage: check.js [--from <parity run>] [--saved <saved folder>] [--scenarios <file>]');
    o[args[i].slice(2)] = path.resolve(args[++i]);
  }
  return o;
}
module.exports = { check, options };
if (require.main === module) (async () => {
  const o = options(process.argv.slice(2));
  if (o.from) process.exitCode = check(o.from, o).failures ? 1 : 0;
  else {
    if (o.saved || o.scenarios) throw Error('--saved and --scenarios require --from');
    // The fresh check uses parity's own single Godot run, including all existing parity checks.
    process.exitCode = await require('../node/run_parity').run();
  }
})().catch(e => { console.error('FAIL: saved Godot results: ' + e.stack); process.exitCode = 1; });
