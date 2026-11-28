'use strict';
// Seat facts lint. A normal *_tests.js row for contrib/opus/tools/run_all_checks.js.
// Reads repo text only. It FAILs when a document a seat reads says something about the seats that the
// tooling or the newer ruling contradicts:
//   A. the Codex build model named in a doc differs from the one pin (CODEX_MODEL in tools/pc/codex_issue.bat);
//   B. a Codex lane count, or the code-only lane range, differs from the lanes codex_issue.bat knows;
//   C. LOOP.md holds more than LATEST_CAP LATEST lines (RULEBOOK 0.10 target is about 15);
//   D. a line in LOOP.md "The seats" holds a seat OFF or paused "until"/"reset"/"refresh" a date that has passed;
//   E. a FINDINGS row from R281 on says it overrides, replaces or supersedes R<n>, and R<n>'s status cell does
//      not say SUPERSEDED (RULEBOOK 0.10), so the memory lint's superseded-citation check stays blind;
//   F. a branch prefix that auto_pr.yml opens PRs for is missing from RULEBOOK 2.4, or a seat label named in
//      AGENTS.md is missing from the job template's Owner line.
// Text inside double quotes is skipped (Ryan's words are history, not a claim). LATEST lines are dated history
// and skipped by A and B. Usage: node seat_facts_tests.js   (VS_ROOT=<repo> and VS_TODAY=YYYY-MM-DD optional)
const fs = require('fs');
const os = require('os');
const path = require('path');

const LATEST_CAP = 25;
const OVERRIDE_FROM = 281;
const MONTHS = { jan: 0, feb: 1, mar: 2, apr: 3, may: 4, jun: 5, jul: 6, aug: 7, sep: 8, oct: 9, nov: 10, dec: 11 };
const WORDS = { one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8 };

const readIf = (root, rel) => { const f = path.join(root, rel); return fs.existsSync(f) ? fs.readFileSync(f, 'utf8') : null; };
const listMd = (root, dir) => { const d = path.join(root, dir); return fs.existsSync(d) ? fs.readdirSync(d).filter(n => /\.md$/i.test(n)).sort().map(n => dir + '/' + n) : []; };
// Blank out quoted text but keep line breaks, so line numbers stay true.
const unquote = text => text.replace(/"[^"]*"/g, m => m.replace(/[^\n]/g, ' '));

function scannedDocs(root) {
  const files = ['AGENTS.md', 'CLAUDE.md', 'HANDOFF.md', 'GLOSSARY.md', 'docs/RULEBOOK.md', 'contrib/opus/LOOP.md',
    ...listMd(root, '.claude/rules'), ...listMd(root, 'docs/playbooks')];
  const skills = path.join(root, '.agents/skills');
  if (fs.existsSync(skills)) for (const s of fs.readdirSync(skills).sort()) {
    if (fs.existsSync(path.join(skills, s, 'SKILL.md'))) files.push('.agents/skills/' + s + '/SKILL.md');
  }
  return files.filter(f => readIf(root, f) !== null);
}

function toolingFacts(root) {
  const bat = readIf(root, 'tools/pc/codex_issue.bat') || '';
  const pin = /set "CODEX_MODEL=gpt-(\d+\.\d+)-([a-z]+)"/i.exec(bat);
  const lanes = [...bat.matchAll(/if \/i "%LANEDIR%"=="build_\w+" set "BOARD=/gi)].length;
  const codeOnly = [...bat.matchAll(/set "PC_GPU_LANE=([A-F])"/g)].map(m => m[1]).sort();
  return { model: pin ? pin[1] : null, family: pin ? pin[2].toLowerCase() : null, lanes, codeOnly };
}

// LOOP.md lines that are dated history (LATEST lines) are not claims about today. Both bulleted
// ("- LATEST", "* LATEST") and unbulleted ("LATEST ...") lines count; origin/main writes the newest ones unbulleted.
const isHistoryLine = (file, line) => file === 'contrib/opus/LOOP.md' && /^\s*(?:[-*]\s+)?LATEST\b/i.test(line);

function checkModelsAndLanes(root, facts) {
  const fails = [];
  const range = facts.codeOnly.length ? facts.codeOnly[0] + '-' + facts.codeOnly[facts.codeOnly.length - 1] : '';
  for (const file of scannedDocs(root)) {
    const lines = unquote(readIf(root, file)).split(/\r?\n/);
    lines.forEach((line, i) => {
      if (isHistoryLine(file, line)) return;
      const at = file + ':' + (i + 1);
      if (facts.model && /codex/i.test(line)) {
        for (const m of line.matchAll(/\b(?:GPT[ -]?)?(\d+\.\d+)[ -]Sol\b|\bgpt-(\d+\.\d+)-sol\b|\bSol (\d+\.\d+)\b/gi)) {
          const v = m[1] || m[2] || m[3];
          if (v !== facts.model) fails.push('A ' + at + ' names Codex model "' + m[0] + '" but tools/pc/codex_issue.bat pins gpt-' + facts.model + '-' + facts.family);
        }
      }
      if (facts.lanes) {
        for (const m of line.matchAll(/\b(up to )?(one|two|three|four|five|six|seven|eight|\d)( local| Codex| code-only| code)? lanes\b/gi)) {
          const before = line.slice(Math.max(0, m.index - 12), m.index).toLowerCase();
          if (/\b(was|with|had|from|then)\s*$/.test(before)) continue; // history or a measurement, not a claim
          const n = WORDS[m[2].toLowerCase()] || Number(m[2]);
          if (/code/i.test(m[3] || '')) continue; // a count of code-only lanes is checked by range below
          if (n !== facts.lanes) fails.push('B ' + at + ' says "' + m[0] + '" but tools/pc/codex_issue.bat knows ' + facts.lanes + ' Codex lanes');
        }
        for (const m of line.matchAll(/\b(?:lanes? )?([A-F])(?:,? (to|and) ([A-F]))? (?:are |stay |is )?code[ -]only\b/g)) {
          if (!m[2] && !/lanes? [A-F] (?:are |stay |is )?code/.test(m[0])) continue;
          const got = m[1] + '-' + (m[3] || m[1]);
          if (range && got !== range) fails.push('B ' + at + ' says code-only lanes "' + m[0] + '" but codex_issue.bat makes lanes ' + range.replace('-', ' to ') + ' code only');
        }
      }
    });
  }
  return fails;
}

function loopSection(text, heading) {
  const start = text.search(new RegExp('^## ' + heading, 'm'));
  if (start < 0) return { body: '', offset: 0 };
  const rest = text.slice(start + 3);
  const next = rest.search(/^## /m);
  const body = text.slice(start, next < 0 ? text.length : start + 3 + next);
  return { body, offset: text.slice(0, start).split('\n').length - 1 };
}

function checkLoop(root, today) {
  const fails = [];
  const loop = readIf(root, 'contrib/opus/LOOP.md');
  if (loop === null) return ['C contrib/opus/LOOP.md is missing'];
  const latest = loop.split(/\r?\n/).filter(l => /^\s*(?:[-*]\s+)?LATEST\b/i.test(l)).length;
  if (latest > LATEST_CAP) fails.push('C contrib/opus/LOOP.md holds ' + latest + ' LATEST lines (cap ' + LATEST_CAP + '; RULEBOOK 0.10 rolls them up at about 15)');
  const { body, offset } = loopSection(unquote(loop), 'The seats');
  body.split('\n').forEach((line, i) => {
    if (!/\b(OFF|off|paused|pause)\b/.test(line)) return;
    for (const m of line.matchAll(/\b(?:until|till|reset|refresh)\b[^.;]{0,60}?\b(?:about |around )?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* (\d{1,2})\b/g)) {
      const when = new Date(Date.UTC(today.getUTCFullYear(), MONTHS[m[1].toLowerCase()], Number(m[2])));
      if (when < today) fails.push('D contrib/opus/LOOP.md:' + (offset + i + 1) + ' holds a seat "' + m[0].slice(0, 60) + '"; that date has passed: rewrite the seat line from the live state');
    }
  });
  return fails;
}

function checkOverrides(root) {
  const fails = [];
  const text = readIf(root, 'contrib/opus/FINDINGS.md');
  if (text === null) return ['E contrib/opus/FINDINGS.md is missing'];
  const rows = new Map();
  text.split(/\r?\n/).forEach((line, i) => {
    const m = /^\|\s*R(\d+)\s*\|/.exec(line);
    if (!m) return;
    const cells = line.split('|').map(c => c.trim()).filter((c, k, a) => !(c === '' && (k === 0 || k === a.length - 1)));
    rows.set(Number(m[1]), { line, n: i + 1, status: cells[cells.length - 1] || '' });
  });
  for (const [id, row] of rows) {
    if (id < OVERRIDE_FROM) continue;
    for (const m of row.line.matchAll(/\b(?:overrides|replaces|supersedes)\s+((?:R\d+[^|.;]{0,40}?(?:,\s*|\s+and\s+)?)+)/gi)) {
      for (const r of m[1].matchAll(/R(\d+)/g)) {
        const target = rows.get(Number(r[1]));
        if (target && !/\bSUPERSEDED\b/i.test(target.status)) { // a partial override may say SUPERSEDED mid-cell
          fails.push('E contrib/opus/FINDINGS.md:' + target.n + ' R' + r[1] + ' is overridden by R' + id + ' but its status cell does not say SUPERSEDED ("' + target.status.slice(0, 50) + '")');
        }
      }
    }
  }
  return fails;
}

function checkBoardShapes(root) {
  const fails = [];
  const autoPr = readIf(root, '.github/workflows/auto_pr.yml') || '';
  const branchBlock = (/branches:\s*\n((?:\s+-[^\n]*\n|\s+#[^\n]*\n)+)/.exec(autoPr) || [, ''])[1];
  const prefixes = [...new Set([...branchBlock.matchAll(/^\s+- '([a-z]+)\//gm)].map(m => m[1]))];
  const rulebook = readIf(root, 'docs/RULEBOOK.md') || '';
  const s24 = (/^2\.4 [\s\S]*?(?=^2\.5 )/m.exec(rulebook) || [''])[0];
  for (const p of prefixes) if (s24 && !s24.includes('`' + p + '/')) fails.push('F docs/RULEBOOK.md 2.4 does not list the ' + p + '/ branch shape that auto_pr.yml opens pull requests for');
  const agents = readIf(root, 'AGENTS.md') || '';
  const labelLine = (/The label says who has it:[^\n]*\n[^\n]*/.exec(agents) || [''])[0];
  const labels = [...labelLine.matchAll(/`([a-z]+)`/g)].map(m => m[1]).filter(l => !['ryan', 'blocked', 'running'].includes(l));
  const template = readIf(root, '.github/ISSUE_TEMPLATE/job.md') || '';
  const owner = (/^Owner:([^\n]*)/m.exec(template) || [, ''])[1];
  for (const l of labels) if (owner && !new RegExp('\\b' + l + '\\b').test(owner)) fails.push('F .github/ISSUE_TEMPLATE/job.md Owner line "' + owner.trim() + '" has no ' + l + ' (AGENTS.md names that label)');
  return fails;
}

function lint(root, today) {
  const facts = toolingFacts(root);
  return [...checkModelsAndLanes(root, facts), ...checkLoop(root, today), ...checkOverrides(root), ...checkBoardShapes(root)];
}

// ---------- self-test on planted fixtures ----------
function plant(files) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'seatfacts-'));
  for (const [rel, text] of Object.entries(files)) { fs.mkdirSync(path.dirname(path.join(dir, rel)), { recursive: true }); fs.writeFileSync(path.join(dir, rel), text); }
  return dir;
}
const BAT = 'if not defined CODEX_MODEL set "CODEX_MODEL=gpt-6.2-sol"\n'
  + ['b', 'c', 'd', 'e', 'f', 'g'].map((x, k) => 'if /i "%LANEDIR%"=="build_' + x + '" set "BOARD=board' + (k ? '_' + 'abcde'[k - 1] : '') + '"').join('\n')
  + '\n' + ['C', 'D', 'E', 'F'].map(x => 'if /i "%BOARD%"=="board_' + x.toLowerCase() + '" set "PC_GPU_LANE=' + x + '"').join('\n') + '\n';
const AUTO = "on:\n  push:\n    branches:\n      - 'codex/issue-*'\n      - 'neon/issue-*'\n      - '!neon/issue-*-partial'\njobs: {}\n";
function fixture(bad, opts = {}) {
  const count = opts.count != null ? opts.count : (bad ? 30 : 10);
  const prefix = opts.unbulleted ? '' : '- ';
  const latest = Array.from({ length: count }, (_, k) => prefix + 'LATEST Nov 25 ' + k + ':00 UTC (Board): merged ' + k);
  // A history line that would fire A (wrong Codex model) and B (wrong lane count) if it were treated as a claim.
  if (opts.historyClaim) latest.push(prefix + 'LATEST Nov 24 23:00 UTC (Board): Codex runs GPT 6.1 Sol in four lanes.');
  return plant({
    'tools/pc/codex_issue.bat': BAT,
    '.github/workflows/auto_pr.yml': AUTO,
    '.github/ISSUE_TEMPLATE/job.md': bad ? 'Owner: codex | muse\n' : 'Owner: codex | muse | neon\n',
    'AGENTS.md': 'The label says who has it: `codex`, `muse`,\n  `ryan`, plus `neon` and `blocked`.\nCodex runs in up to six lanes, C to F code only.\n',
    'docs/RULEBOOK.md': '2.4 **Board.** Agents deliver on `codex/`' + (bad ? '' : ', `neon/`') + ' branches.\n2.5 next\n'
      + (bad ? '2.7 Codex runs GPT 6.1 Sol today. One Codex job per lane (four lanes).\n' : '2.7 Codex runs GPT 6.2 Sol. Ryan: "we usually use Sol 6.1". Was four lanes.\n'),
    'GLOSSARY.md': bad ? '- **Lane**: a queue (lane C and D are code only).\n' : '- **Lane**: a queue (lanes C to F are code only).\n',
    'contrib/opus/LOOP.md': '## The seats\n' + (bad ? '- **API arms: OFF** until the monthly refresh, about Nov 21.\n' : '- **API arms: on** (R446).\n')
      + '## Current state\n' + latest.join('\n') + '\n',
    'contrib/opus/FINDINGS.md': '| ID | Decision | Status |\n|---|---|---|\n'
      + '| R300 | old seat rule | ' + (bad ? 'STANDING' : 'SUPERSEDED by R449') + ' |\n'
      + '| R449 | new seat rule. Overrides R300. | Landed in docs/RULEBOOK.md |\n',
  });
}

if (require.main === module) {
  const today = process.env.VS_TODAY ? new Date(process.env.VS_TODAY + 'T00:00:00Z') : new Date();
  const fixtureDay = new Date('2026-11-25T00:00:00Z');
  const bad = lint(fixture(true), fixtureDay), good = lint(fixture(false), fixtureDay);
  let ok = true;
  for (const check of ['A', 'B', 'C', 'D', 'E', 'F']) {
    const fired = bad.some(f => f.startsWith(check + ' '));
    console.log((fired ? 'PASS' : 'FAIL') + ' fixture check ' + check + ' fires on a bad tree');
    ok = ok && fired;
  }
  console.log((good.length ? 'FAIL' : 'PASS') + ' fixture good tree stays quiet' + (good.length ? ': ' + good.join(' / ') : ''));
  ok = ok && !good.length;
  // The newest lines on origin/main are unbulleted "LATEST ..." lines. They must count toward the cap and read as
  // dated history, not as today's claims, exactly like the older bulleted ones.
  const unbulletedOver = lint(fixture(false, { unbulleted: true, count: 30 }), fixtureDay);
  const unbulletedQuiet = lint(fixture(false, { unbulleted: true, count: 10, historyClaim: true }), fixtureDay);
  const countedUnbulleted = unbulletedOver.some(f => f.startsWith('C '));
  console.log((countedUnbulleted ? 'PASS' : 'FAIL') + ' fixture unbulleted LATEST lines count toward the cap');
  ok = ok && countedUnbulleted;
  const skippedUnbulleted = !unbulletedQuiet.some(f => /^[AB] /.test(f));
  console.log((skippedUnbulleted ? 'PASS' : 'FAIL') + ' fixture unbulleted LATEST lines are skipped by checks A and B'
    + (skippedUnbulleted ? '' : ': ' + unbulletedQuiet.join(' / ')));
  ok = ok && skippedUnbulleted;
  const root = process.env.VS_ROOT || path.resolve(__dirname, '../../..');
  const fails = lint(root, today);
  for (const f of fails) console.log('FAIL ' + f);
  if (!ok || fails.length) { console.log('FAIL: ' + fails.length + ' seat fact problem(s)' + (ok ? '' : ' (and the self-test failed)')); process.exit(1); }
  console.log('PASS: seat facts agree with the tooling and the newest rulings');
}
module.exports = { lint, toolingFacts };
