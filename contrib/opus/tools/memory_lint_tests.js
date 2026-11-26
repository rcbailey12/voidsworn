'use strict';
// Issue 837 (issue 788 step 2, Ryan R270: all seven steps): repo memory lint.
// A normal row in contrib/opus/tools/run_all_checks.js (the runner picks up every *_tests.js).
// It reads repo text files only: no game, tool or document file is changed by it.
//
// Checks on every push (checks 1 to 3 and 5 can FAIL; check 4 is a report only):
//   1. every ruling id R<n> cited in docs/RULEBOOK.md, docs/playbooks/*.md, HANDOFF.md and
//      AGENTS.md has a row in contrib/opus/FINDINGS.md;
//   2. a citation of a row whose FINDINGS status column starts with SUPERSEDED is flagged
//      unless the citing line itself says "supersed";
//   3. no scanned file names a ruling range such as "R236 to R257" (the old HANDOFF trap:
//      a range goes stale as soon as the next ruling lands);
//   4. report only, never FAIL: HANDOFF section 0 line count (target about one page) and
//      LOOP.md's number of LATEST lines (target 15 or fewer; main() FAILs past LOOP_HARD, 25).
//   5. every FINDINGS row from R281 on says where the ruling landed: "landed in <repo path>"
//      naming a file that exists (docs/RULEBOOK.md, AGENTS.md, a playbook, contrib/opus/LOOP.md),
//      or the words "one-off job decision" (issue 890, Ryan R291: global fixes).
//
// Each FAIL prints the file, line and id. A planted fixture pair under
// contrib/opus/tools/fixtures/memory_lint/ (bad and good) proves checks 1 to 3 fire on a
// bad file and stay quiet on a good one, and that check 4 reports without failing (check 5 too).
//
// A KNOWN baseline holds the citations and ranges that are already on main (listed in the
// pull request body). A baseline entry that stops firing is an error until it is removed,
// so the list can only shrink (the same ratchet findings_tests uses).
//
// The baseline keys are check|file|id (citations) and range|file|text (ranges).
const fs = require('fs');
const path = require('path');

const ROOT = process.env.VS_ROOT || path.resolve(__dirname, '../../..');
const FIXTURES = path.join(__dirname, 'fixtures', 'memory_lint');
const FINDINGS = 'contrib/opus/FINDINGS.md';
const HANDOFF_TARGET = 50; // "about one page" of markdown
const LOOP_TARGET = 15;
// Ways-of-working audit (Nov 25 2026): LOOP.md is read on every Board turn, so past this many LATEST lines the
// lint FAILs. node contrib/opus/tools/loop_roll.js moves the older lines to contrib/opus/LOOP_LOG.md.
const LOOP_HARD = 25;
const LANDING_FROM = 281; // check 5 starts at R281 (issue 890)

// Empty: the five known items were cleared by issue 865 (Nov 16 2026). A baseline entry
// that stops firing is an error, so the list can only shrink.
const KNOWN_BASELINE = [];

function readIf(root, rel) {
  const full = path.join(root, rel);
  return fs.existsSync(full) ? fs.readFileSync(full, 'utf8') : null;
}

// The scanned documents: the entry documents plus every playbook.
function docFiles(root) {
  const out = [];
  for (const f of ['docs/RULEBOOK.md', 'HANDOFF.md', 'AGENTS.md']) {
    if (fs.existsSync(path.join(root, f))) out.push(f);
  }
  const playbooks = path.join(root, 'docs/playbooks');
  if (fs.existsSync(playbooks)) {
    for (const name of fs.readdirSync(playbooks).filter(n => /\.md$/i.test(n)).sort()) {
      out.push('docs/playbooks/' + name);
    }
  }
  return out;
}

function handoffSection0(text) {
  const start = /^## 0\.[^\r\n]*\r?\n/m.exec(text);
  if (!start) return '';
  const rest = text.slice(start.index + start[0].length);
  const next = /^## /m.exec(rest);
  return next ? rest.slice(0, next.index) : rest;
}

// A ruling row is `| R<n> | ... |`. Its status column is the last cell. A row is superseded
// only when that status cell itself starts with SUPERSEDED; a mention inside the decision
// text (for example R5's "test scope superseded by R20") does not make the whole row dead.
function parseFindings(text) {
  const rows = new Map();
  for (const line of text.split(/\r?\n/)) {
    const m = /^\|\s*(R\d+)\s*\|/.exec(line);
    if (!m) continue;
    let cells = line.split('|');
    cells.shift();
    if (cells.length && cells[cells.length - 1].trim() === '') cells.pop();
    cells = cells.map(c => c.trim());
    const status = cells[cells.length - 1] || '';
    rows.set(m[1], { status, superseded: /^SUPERSEDED\b/i.test(status) });
  }
  return rows;
}

function scanCitations(root, rows) {
  const fails = [];
  const cited = new Set();
  const seen = new Set();
  for (const file of docFiles(root)) {
    const text = readIf(root, file);
    if (text === null) continue;
    const lines = text.split(/\r?\n/);
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      for (const m of line.matchAll(/\bR(\d+)\b/g)) {
        const id = 'R' + m[1];
        cited.add(id);
        const lineNo = i + 1;
        const dedupe = file + '|' + lineNo + '|' + id;
        if (seen.has(dedupe)) continue;
        seen.add(dedupe);
        const row = rows.get(id);
        if (!row) {
          fails.push({
            check: 'missing', file, line: lineNo, id,
            key: 'missing|' + file + '|' + id,
            message: file + ':' + lineNo + ' cites ' + id + ', which has no row in ' + FINDINGS,
          });
          continue;
        }
        if (row.superseded && !/supersed/i.test(line)) {
          fails.push({
            check: 'superseded', file, line: lineNo, id,
            key: 'superseded|' + file + '|' + id,
            message: file + ':' + lineNo + ' cites ' + id + ', whose FINDINGS status says SUPERSEDED ('
              + row.status.slice(0, 60) + '); cite the live row or say superseded on the line',
          });
        }
      }
    }
  }
  return { fails, cited };
}

const RANGE_PATTERNS = [
  /\bR\d+\s*(?:to|through)\s*R\d+\b/gi,
  /\bR\d+\s*-\s*R\d+\b/g,
];

function scanRanges(root) {
  const fails = [];
  for (const file of docFiles(root)) {
    const text = readIf(root, file);
    if (text === null) continue;
    const lines = text.split(/\r?\n/);
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      for (const re of RANGE_PATTERNS) {
        re.lastIndex = 0;
        let m;
        while ((m = re.exec(line))) {
          const range = m[0].replace(/\s+/g, ' ');
          const key = 'range|' + file + '|' + range;
          if (fails.some(f => f.key === key && f.line === i + 1)) continue;
          fails.push({
            check: 'range', file, line: i + 1, id: range,
            key,
            message: file + ':' + (i + 1) + ' names the ruling range "' + range
              + '"; name one ruling or point at the FINDINGS rows instead',
          });
        }
      }
    }
  }
  return fails;
}

// Check 5: a row from R281 on names the document it landed in, or says it was a one-off job call.
function scanLandings(root, findingsText) {
  const fails = [];
  let checked = 0;
  const lines = findingsText.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const m = /^\|\s*R(\d+)\s*\|/.exec(lines[i]);
    if (!m || Number(m[1]) < LANDING_FROM) continue;
    const id = 'R' + m[1];
    const line = lines[i];
    checked++;
    if (/one-off job decision/i.test(line)) continue;
    const landed = /landed in ([^|]*)/i.exec(line);
    const paths = landed ? [...landed[1].matchAll(/[\w./-]+\.(?:md|js|ps1|bat|yml|gd|py|json)\b/g)].map(p => p[0]) : [];
    if (paths.some(p => fs.existsSync(path.join(root, p)))) continue;
    const why = paths.length
      ? 'its "landed in" path (' + paths.join(', ') + ') is not a file in the repo'
      : 'it names no document it landed in';
    fails.push({
      check: 'landing', file: FINDINGS, line: i + 1, id,
      key: 'landing|' + id,
      message: FINDINGS + ':' + (i + 1) + ' row ' + id + ': ' + why
        + '; add "landed in <repo path>" or "one-off job decision" (issue 890)',
    });
  }
  return { fails, checked };
}

function buildReports(root) {
  const reports = [];
  const handoff = readIf(root, 'HANDOFF.md');
  const section = handoff === null ? '' : handoffSection0(handoff);
  const handoffLines = section.split(/\r?\n/).filter(l => l.trim()).length;
  reports.push({
    name: 'handoff-section-0',
    value: handoffLines,
    target: HANDOFF_TARGET,
    ok: handoffLines <= HANDOFF_TARGET,
    text: 'HANDOFF section 0 holds ' + handoffLines + ' lines (target about ' + HANDOFF_TARGET + ', one page)',
  });
  const loop = readIf(root, 'contrib/opus/LOOP.md');
  const latest = loop === null
    ? 0
    : loop.split(/\r?\n/).filter(l => /^\s*[-*]\s*LATEST\b/i.test(l)).length;
  reports.push({
    name: 'loop-latest',
    value: latest,
    target: LOOP_TARGET,
    ok: latest <= LOOP_TARGET,
    text: 'LOOP.md holds ' + latest + ' LATEST lines (target ' + LOOP_TARGET + ' or fewer)',
  });
  return reports;
}

// Pure lint of one root. No baseline is applied here, so the fixtures see every hit.
function lint(root) {
  const fails = [];
  const findingsText = readIf(root, FINDINGS);
  let rows = new Map();
  if (findingsText === null) {
    fails.push({
      check: 'setup', file: FINDINGS, line: 0, id: '',
      key: 'setup|findings', message: FINDINGS + ' is missing, so no citation can be checked',
    });
  } else {
    rows = parseFindings(findingsText);
    if (rows.size === 0) {
      fails.push({
        check: 'setup', file: FINDINGS, line: 0, id: '',
        key: 'setup|findings-rows', message: FINDINGS + ' has no R ruling rows, so no citation can be checked',
      });
    }
  }
  if (docFiles(root).length === 0) {
    fails.push({
      check: 'setup', file: '(documents)', line: 0, id: '',
      key: 'setup|docs', message: 'no scanned documents were found; check docFiles()',
    });
  }
  const landings = findingsText === null ? { fails: [], checked: 0 } : scanLandings(root, findingsText);
  for (const f of landings.fails) fails.push(f);
  const cites = scanCitations(root, rows);
  for (const f of cites.fails) fails.push(f);
  for (const f of scanRanges(root)) fails.push(f);
  return {
    fails,
    cited: cites.cited,
    rowCount: rows.size,
    landingRows: landings.checked,
    reports: buildReports(root),
  };
}

// A real run moves baselined hits to KNOWN. A baseline key that no longer fires is an error,
// so a fixed item cannot stay silently hidden.
function applyBaseline(result) {
  const allowed = new Set(KNOWN_BASELINE);
  const known = [];
  const unexpected = [];
  const fired = new Set();
  for (const f of result.fails) {
    if (allowed.has(f.key)) {
      known.push(f);
      fired.add(f.key);
    } else {
      unexpected.push(f);
    }
  }
  const stale = KNOWN_BASELINE.filter(k => !fired.has(k));
  return { known, unexpected, stale };
}

function hasFail(result, check) {
  return result.fails.some(f => f.check === check);
}

function runSelfTest() {
  let checks = 0;
  let bad = 0;
  const assert = (id, ok, detail) => {
    checks++;
    if (ok) {
      console.log('PASS ' + id);
    } else {
      bad++;
      console.log('FAIL ' + id + ': ' + detail);
    }
  };
  const good = lint(path.join(FIXTURES, 'good'));
  const planted = lint(path.join(FIXTURES, 'bad'));

  assert('fixture check 1 fires on a missing ruling id',
    hasFail(planted, 'missing'), 'the bad fixture cites R999 but no missing-id FAIL was reported');
  assert('fixture check 1 stays quiet on a good file',
    !hasFail(good, 'missing'), 'the good fixture reported a missing ruling id');

  assert('fixture check 2 fires on a superseded citation',
    hasFail(planted, 'superseded'), 'the bad fixture cites the superseded R2 without the word superseded');
  assert('fixture check 2 stays quiet on a good file',
    !hasFail(good, 'superseded'), 'the good fixture reported a superseded citation');

  assert('fixture check 3 fires on a ruling range',
    hasFail(planted, 'range'), 'the bad fixture names the range R1 to R3');
  assert('fixture check 3 stays quiet on a good file',
    !hasFail(good, 'range'), 'the good fixture reported a ruling range');

  const landing = planted.fails.filter(f => f.check === 'landing').map(f => f.id).sort().join(',');
  assert('fixture check 5 fires on rows with no landing document or a missing path',
    landing === 'R281,R283', 'expected R281 (nothing named) and R283 (missing path), got "' + landing + '"');
  assert('fixture check 5 stays quiet on a landed row and a one-off row',
    !hasFail(good, 'landing'), 'the good fixture reported a landing failure');

  const plantedHandoff = planted.reports.find(r => r.name === 'handoff-section-0');
  const goodHandoff = good.reports.find(r => r.name === 'handoff-section-0');
  assert('fixture check 4 reports the HANDOFF section 0 count without failing',
    plantedHandoff && !plantedHandoff.ok && goodHandoff && goodHandoff.ok
      && !hasFail(planted, 'report') && !hasFail(good, 'report'),
    'expected an oversized HANDOFF section 0 in the bad fixture and a small one in the good fixture');

  const plantedLoop = planted.reports.find(r => r.name === 'loop-latest');
  const goodLoop = good.reports.find(r => r.name === 'loop-latest');
  assert('fixture check 4 reports the LOOP LATEST count without failing',
    plantedLoop && !plantedLoop.ok && goodLoop && goodLoop.ok,
    'expected too many LATEST lines in the bad fixture and 15 or fewer in the good fixture');

  return { checks, bad };
}

function main() {
  const self = runSelfTest();

  const result = lint(ROOT);
  const { known, unexpected, stale } = applyBaseline(result);

  for (const f of known) console.log('KNOWN ' + f.message);
  for (const r of result.reports) console.log('NOTE ' + r.text);

  const loopNow = result.reports.find(r => r.name === 'loop-latest');
  const loopOver = loopNow && loopNow.value > LOOP_HARD ? 1 : 0;
  if (loopOver) {
    console.log('FAIL LOOP.md holds ' + loopNow.value + ' LATEST lines (limit ' + LOOP_HARD
      + '); run node contrib/opus/tools/loop_roll.js');
  }
  const problems = unexpected.length + stale.length + loopOver;
  for (const f of unexpected) console.log('FAIL ' + f.message);
  for (const k of stale) {
    console.log('FAIL the baseline entry "' + k + '" no longer fires; take it off KNOWN_BASELINE');
  }

  if (self.bad || problems) {
    const parts = [];
    if (self.bad) parts.push(self.bad + ' of ' + self.checks + ' self-test assertions failed');
    if (problems) parts.push(problems + ' ruling memory problem(s) outside the baseline');
    console.log('FAIL: ' + parts.join(' and '));
    process.exitCode = 1;
    return;
  }

  const handoff = result.reports.find(r => r.name === 'handoff-section-0');
  const loop = result.reports.find(r => r.name === 'loop-latest');
  console.log('PASS: ' + result.cited.size + ' cited ruling ids all have a ' + FINDINGS + ' row; '
    + result.landingRows + ' rows from R' + LANDING_FROM + ' on name where they landed; '
    + known.length + ' known baseline item(s); ' + self.checks + ' fixture assertions pass; '
    + 'HANDOFF section 0 ' + handoff.value + ' lines (target about ' + handoff.target + '); '
    + 'LOOP ' + loop.value + ' LATEST lines (target ' + loop.target + ' or fewer)');
}

if (require.main === module) {
  main();
}

module.exports = { lint, applyBaseline, parseFindings, handoffSection0, docFiles, KNOWN_BASELINE };
