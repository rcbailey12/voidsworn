'use strict';
// Self-test for the checks runner's result words (issue 358).
// It never runs a real check: it calls the runner's exported classifiers with
// small synthetic outputs and proves the gating rules. The runner picks this
// file up automatically because its name ends in _tests.js.
const {
  classifyFindings,
  classifyPack,
  classifyDrift,
  classifyGeneric,
  verdictLine,
  exitCodeFor,
} = require('./run_all_checks.js');

const baseline = {
  knownFindingsFailures: ['BF-1', 'NEM-3'],
  checksCeiling: 14,
  driftDifferedCeiling: 12,
};

let pass = 0, fail = 0;
function check(name, ok, detail) {
  if (ok) { pass++; console.log('PASS ' + name); }
  else { fail++; console.log('FAIL ' + name + (detail ? ': ' + detail : '')); }
}
function findsOutput(passIds, failIds) {
  const lines = [];
  for (const id of passIds) lines.push('PASS ' + id + ' some test sentence');
  for (const id of failIds) lines.push('FAIL ' + id + ' some test sentence: a detail');
  lines.push('---');
  lines.push((passIds.length + failIds.length) + ' tests, ' + passIds.length + ' pass, ' + failIds.length + ' fail');
  return lines.join('\n') + '\n';
}

// Case 1 (required): a listed id made to pass gives FAIL.
{
  const r = classifyFindings({ code: 0, output: findsOutput(['BF-1', 'NEM-3'], []) }, baseline);
  check('a listed id made to pass gives FAIL', r.result === 'FAIL' && /take them off the list/.test(r.detail) && /BF-1/.test(r.detail), r.result + ' / ' + r.detail);
}

// Case 2 (required): a new failure gives FAIL.
{
  const r = classifyFindings({ code: 1, output: findsOutput([], ['BF-1', 'NEW-9']) }, baseline);
  check('a new failure gives FAIL', r.result === 'FAIL' && /NEW-9/.test(r.detail), r.result + ' / ' + r.detail);
}

// Case 3 (required): a CHECK count of 15 gives FAIL.
{
  const r = classifyPack({ code: 0, output: 'VOIDSWORN MECHANICAL CHECKS\nSUMMARY: 0 FAIL, 15 CHECK\n' }, baseline);
  check('a CHECK count of 15 gives FAIL', r.result === 'FAIL' && /15 CHECK/.test(r.detail), r.result + ' / ' + r.detail);
}

// The four words in their normal states.
{
  const known = classifyFindings({ code: 1, output: findsOutput([], ['BF-1', 'NEM-3']) }, baseline);
  check('only listed failures is KNOWN with the count', known.result === 'KNOWN' && /^KNOWN: 2 /.test(known.detail), known.result + ' / ' + known.detail);
  const clean = classifyFindings({ code: 0, output: findsOutput(['EVT-2'], []) }, { ...baseline, knownFindingsFailures: [] });
  check('zero findings failures with an empty list is PASS', clean.result === 'PASS' && /^PASS\b/.test(clean.detail), clean.result + ' / ' + clean.detail);
  const gone = classifyFindings({ code: 0, output: findsOutput([], ['NEM-3']) }, baseline);
  check('a listed id that no longer runs is FAIL', gone.result === 'FAIL' && /BF-1/.test(gone.detail), gone.result + ' / ' + gone.detail);
  const mismatch = classifyFindings({ code: 1, output: 'FAIL BF-1 x: y\n---\n2 tests, 1 pass, 1 fail\n' }, baseline);
  check('parsed lines that disagree with the summary is FAIL', mismatch.result === 'FAIL', mismatch.result + ' / ' + mismatch.detail);
}

// Pack: ceiling holds at the pin and a FAIL line fails even with exit 0.
{
  const atCeiling = classifyPack({ code: 0, output: 'SUMMARY: 0 FAIL, 14 CHECK\n' }, baseline);
  check('a pack at its CHECK ceiling is PASS', atCeiling.result === 'PASS', atCeiling.result + ' / ' + atCeiling.detail);
  const hidden = classifyPack({ code: 0, output: 'FAIL  a real problem\nSUMMARY: 0 FAIL, 2 CHECK\n' }, baseline);
  check('a pack that prints FAIL and exits 0 is FAIL', hidden.result === 'FAIL', hidden.result + ' / ' + hidden.detail);
  const noSummary = classifyPack({ code: 0, output: 'nothing useful\n' }, baseline);
  check('a pack with no summary is FAIL', noSummary.result === 'FAIL', noSummary.result + ' / ' + noSummary.detail);
}

// Drift: 12 at the pin is KNOWN, zero is PASS, above the ceiling is FAIL.
{
  const known = classifyDrift({ code: 0, output: 'DRIFT SUMMARY: constants 107 compared, 95 matched, 12 differed, 38 browser-only, 0 godot-only\n' }, baseline);
  check('drift at the pin is KNOWN, not PASS', known.result === 'KNOWN' && /12/.test(known.detail), known.result + ' / ' + known.detail);
  const clean = classifyDrift({ code: 0, output: 'DRIFT SUMMARY: constants 107 compared, 107 matched, 0 differed, 38 browser-only, 0 godot-only\n' }, baseline);
  check('zero drift is PASS', clean.result === 'PASS', clean.result + ' / ' + clean.detail);
  const worse = classifyDrift({ code: 0, output: 'DRIFT SUMMARY: constants 107 compared, 94 matched, 13 differed, 38 browser-only, 0 godot-only\n' }, baseline);
  check('drift above the ceiling is FAIL', worse.result === 'FAIL', worse.result + ' / ' + worse.detail);
}

// A PASS detail comes from the check's own verdict line, never a data line.
{
  const out = 'PASS: real campaign picks reach the battle for all six factions:\n  deathless nekhet: restoreNinth, iterationSwap\n';
  check('the verdict line beats the last data line', verdictLine(out) === 'PASS: real campaign picks reach the battle for all six factions:', verdictLine(out));
  const g = classifyGeneric({ code: 0, output: out });
  check('a generic PASS detail is its own PASS line', g.result === 'PASS' && /^PASS\b/.test(g.detail), g.result + ' / ' + g.detail);
  const gf = classifyGeneric({ code: 1, output: 'FAIL: two hand-off checks failed\n' });
  check('a generic FAIL detail is its own FAIL line', gf.result === 'FAIL' && /^FAIL\b/.test(gf.detail), gf.result + ' / ' + gf.detail);
  const gh = classifyGeneric({ code: 0, output: 'FAIL a case failed\nPASS: everything else\n' });
  check('a generic check that prints FAIL and exits 0 is FAIL', gh.result === 'FAIL' && /^FAIL\b/.test(gh.detail), gh.result + ' / ' + gh.detail);
}

// The real baseline carries no opinion or stale id on the gate list.
{
  const real = require('./checks_baseline.json');
  const bad = real.knownFindingsFailures.filter(id => {
    const t = real.knownFindingsTriage && real.knownFindingsTriage[id];
    return t && (t.tag === 'opinion' || t.tag === 'stale');
  });
  check('no opinion or stale id sits on the real known list', bad.length === 0, bad.join(', '));
}

// Exit code: 0 for PASS, KNOWN and SKIP; 1 for FAIL.
{
  const rows = [{ result: 'PASS' }, { result: 'KNOWN' }, { result: 'SKIP' }];
  const withFail = rows.concat([{ result: 'FAIL' }]);
  check('exit code is 0 for PASS, KNOWN and SKIP', exitCodeFor(rows) === 0, String(exitCodeFor(rows)));
  check('exit code is 1 for FAIL', exitCodeFor(withFail) === 1, String(exitCodeFor(withFail)));
}

console.log('---');
console.log((pass + fail) + ' self-tests, ' + pass + ' pass, ' + fail + ' fail');
console.log(fail ? 'FAIL: the checks runner self-test found a broken rule' : 'PASS: the checks runner result words behave as issue 358 requires');
process.exit(fail ? 1 : 0);
