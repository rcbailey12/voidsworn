'use strict';
const fs = require('node:fs'), path = require('node:path');
const R = require('./records'), { options, check } = require('./check');
function update(root, { saved = R.HOME, scenarios = R.SCENARIOS } = {}) {
  if (path.resolve(saved) === R.HOME && path.resolve(scenarios) !== R.SCENARIOS)
    throw Error('a diagnostic scenario file cannot replace the repo baseline');
  const s = R.json(scenarios), names = Object.keys(s), summary = R.json(path.join(root, 'summary.json'));
  // A changed baseline fails the new gate. Every original parity check must still pass.
  if ((summary.parity_failures ?? summary.failures) !== 0 || summary.battles !== names.length)
    throw Error('update requires a complete run with every original parity check passing');
  const bad = R.evidence(root, names, s);
  if (Object.keys(bad).length) throw Error('bad Godot evidence: ' + JSON.stringify(bad));
  // Validate everything before writing any tracked result. Report against the previous baseline first.
  for (const n of names) R.records(R.read(path.join(root, 'out', n + '.jsonl')));
  for (const n of R.FILES) R.auxiliary(root, n);
  let review;
  const oldFile = path.join(saved, 'results.json');
  const oldHash = fs.existsSync(oldFile) ? R.sha(fs.readFileSync(oldFile)) : null;
  if (oldHash) {
    const result = check(root, { saved, scenarios });
    if (result.failures) review = fs.readFileSync(path.join(root, 'changed-battles.txt'), 'utf8');
  }
  const m = { version: 1, compression: 'brotli-5-window24', battles: {}, files: {} };
  for (const n of names) {
    const bytes = R.read(path.join(root, 'out', n + '.jsonl'));
    m.battles[n] = { ...R.pack(saved, n + '.jsonl', bytes), records: R.records(bytes).length,
      scenario_sha256: R.sha(R.stable(s[n])) };
  }
  for (const n of R.FILES) m.files[n] = R.pack(saved, n, R.auxiliary(root, n));
  const manifestText = JSON.stringify(m, null, 2) + '\n';
  fs.writeFileSync(path.join(saved, 'results.json'), manifestText);
  // Carry the before/after report in the same PR. A later successful check cannot erase it.
  if (review || !oldHash) fs.writeFileSync(path.join(saved, 'changes.txt'),
    `Saved manifest before: ${oldHash || '<initial baseline>'}\nSaved manifest after: ${R.sha(manifestText)}\n\n` +
    (review || `Initial saved results: ${names.length} battles and ${R.FILES.length} other files. No earlier saved baseline.\n`));
  const size = Buffer.byteLength(JSON.stringify(m, null, 2) + '\n') +
    [...Object.values(m.battles), ...Object.values(m.files)].reduce((sum, e) => sum + fs.statSync(path.join(saved, 'records', e.archive)).size, 0);
  console.log(`Updated saved Godot results: ${names.length} battles, ${R.FILES.length} other files, ${size} bytes in repo.`);
  return m;
}
module.exports = { update };
if (require.main === module) {
  try { const o = options(process.argv.slice(2)); if (!o.from) throw Error('usage: update.js --from <complete parity run>'); update(o.from, o); }
  catch (e) { console.error('FAIL: saved results update: ' + e.message); process.exitCode = 1; }
}
