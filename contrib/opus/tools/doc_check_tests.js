'use strict';
// Issue 375 (audit pass 1 finding 13, Refs #216): entry documents tell the truth.
// A normal row in contrib/opus/tools/run_all_checks.js (the runner picks up every *_tests.js).
// It checks three things on every pull request:
//   1. every repo path named in AGENTS.md, CLAUDE.md, HANDOFF.md section 0 and the three
//      skills under .claude/skills/ exists (history files are out of scope: they name paths
//      that are gone on purpose);
//   2. a README does not state a scenario or golden battle count that differs from
//      godot/rules/test/scenarios.json, and no README keeps a hand-copied "Latest record"
//      section (counts and records are generated or deleted, never hand-synced);
//   3. the two stale entry-document claims from the audit stay gone: AGENTS.md does not call
//      docs/ship_pipeline/TEXTURE_PASS.md current, and contrib/README.md does not say that
//      nothing in contrib/ is run by the gate.
// Dated result snapshots (paths under results/ or shots/, and dated folder names) are
// records of a past run, so the count and latest-record rules do not apply to them.
const fs = require('fs');
const path = require('path');
const ROOT = process.env.VS_ROOT || path.resolve(__dirname, '../../..');

const fails = [];
const fail = what => fails.push(what);
const read = rel => fs.readFileSync(path.join(ROOT, rel), 'utf8');
const rel = full => path.relative(ROOT, full).split(path.sep).join('/');

// ---------- 1. every repo path named in the entry documents exists ----------

const ENTRY_FILES = [
  { file: 'AGENTS.md' },
  { file: 'CLAUDE.md' },
  { file: 'HANDOFF.md', section0: true },
  { file: '.claude/skills/playtest-and-balance/SKILL.md' },
  { file: '.claude/skills/screenshot-verdict/SKILL.md' },
  { file: '.claude/skills/ship-kit/SKILL.md' },
];

// Built on the PC and never committed: a fresh checkout cannot have it.
const GENERATED = new Set(['godot/gen']);

function handoffSection0(text) {
  const start = /^## 0\.[^\r\n]*\r?\n/m.exec(text);
  if (!start) return '';
  const rest = text.slice(start.index + start[0].length);
  const next = /^## /m.exec(rest);
  return next ? rest.slice(0, next.index) : rest;
}

const ROOT_NAMES = new Set(fs.readdirSync(ROOT));
const paths = new Set();

for (const entry of ENTRY_FILES) {
  const text = entry.section0 ? handoffSection0(read(entry.file)) : read(entry.file);
  if (!text.trim()) { fail(entry.file + ' has no readable text for the path scan'); continue; }
  const lines = text.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const prev = lines[i - 1] || '';
    // A backticked or plain root-relative path: at least one slash, a known first segment.
    const re = /[A-Za-z0-9_.\-]+(?:\/[A-Za-z0-9_.\-]+)+\/?/g;
    let m;
    while ((m = re.exec(line))) {
      const raw = m[0];
      const token = raw.replace(/[),.;:]+$/, '');
      const before = line[m.index - 1] || '';
      const after = line[m.index + m[0].length] || '';
      // Globs and placeholders are not paths (for example c19_*.bat or contrib/<agent>/).
      if (/[*<>{}$]/.test(token) || /[*<>{}$]/.test(before) || /[*<>{}$]/.test(after)) continue;
      // An illustrative path is not a claim that the file exists.
      if (/for example|for instance|e\.g\./i.test(line) || /for example|for instance|e\.g\./i.test(prev)) continue;
      const first = token.split('/')[0];
      // Only root-relative repo paths. A relative path like render/ship_view.gd
      // (relative to godot/) is resolved below, not skipped when it exists.
      if (!ROOT_NAMES.has(first) && !fs.existsSync(path.join(ROOT, 'godot', token))) continue;
      paths.add(token);
    }
  }
}

for (const token of [...paths].sort()) {
  const clean = token.replace(/\/$/, '');
  if (GENERATED.has(clean)) continue;
  if (fs.existsSync(path.join(ROOT, token))) continue;
  // A path written relative to the Godot product folder, as the skills often do.
  if (!token.startsWith('godot/') && fs.existsSync(path.join(ROOT, 'godot', token))) continue;
  fail('a path named in an entry document does not exist: ' + token);
}
// Guard against a regex that stops matching and passes silently.
if (paths.size < 20) fail('the entry document path scan found only ' + paths.size + ' paths; the extraction stopped working');

// ---------- 2. no stale scenario, battle or latest-record claims in a README ----------

const datedSnapshot = p => {
  const posix = p.split(path.sep).join('/');
  return /(^|\/)(results|shots)(\/|$)/i.test(posix)
    || /_\d{6,8}(\/|$)/.test(posix)
    || /20\d\d_\d\d/.test(posix);
};

function walkReadmes(dir, out) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name === '.git' || e.name === 'node_modules') continue;
    const full = path.join(dir, e.name);
    if (e.isDirectory()) walkReadmes(full, out);
    else if (/^readme\.md$/i.test(e.name)) out.push(full);
  }
  return out;
}

const scenariosFile = 'godot/rules/test/scenarios.json';
const scenarioCount = Object.keys(JSON.parse(read(scenariosFile))).length;
const COUNT_PATTERNS = [
  /(\d+)\s+of\s+(\d+)\s+golden battles/gi,
  /(\d+)\s+golden battles/gi,
  /the count stays\s+(\d+)/gi,
  /scenarios\.json holds\s+(\d+)/gi,
  /(\d+)\s+scenarios\b/gi,
  /(\d+)\s+of\s+(\d+)\s+battles/gi,
];

const readmes = walkReadmes(ROOT, []).filter(f => !datedSnapshot(rel(f)));
if (readmes.length === 0) fail('the README scan found no files; check datedSnapshot and walkReadmes');

for (const full of readmes) {
  const name = rel(full);
  const text = fs.readFileSync(full, 'utf8');
  for (const re of COUNT_PATTERNS) {
    re.lastIndex = 0;
    let m;
    while ((m = re.exec(text))) {
      const lineNo = text.slice(0, m.index).split(/\r?\n/).length;
      for (const group of m.slice(1)) {
        if (group === undefined) continue;
        if (+group !== scenarioCount) {
          fail(name + ':' + lineNo + ' states "' + m[0] + '", but ' + scenariosFile + ' holds ' + scenarioCount + ' scenarios');
        }
      }
    }
  }
  if (/(^|\n)#{1,6}\s*Latest record\b/i.test(text)) {
    fail(name + ' has a hand-copied "Latest record" section; generate it from the result folder or delete it');
  }
}

// ---------- 3. the two stale entry-document claims stay gone ----------

const agents = read('AGENTS.md');
if (/TEXTURE_PASS\.md[^\r\n]*\(current\)/.test(agents)) {
  fail('AGENTS.md still calls docs/ship_pipeline/TEXTURE_PASS.md current; that file is a historical Oct 22 brief about the browser game');
}

const contrib = read('contrib/README.md');
if (/Nothing in\s+`?contrib\/?`?\s+is built into the game or run by/i.test(contrib)) {
  fail('contrib/README.md still says nothing in contrib/ is run by the gate; the pull request gate is contrib/opus/tools/run_all_checks.js');
}
if (!/run_all_checks\.js/.test(contrib)) {
  fail('contrib/README.md does not name the pull request gate, contrib/opus/tools/run_all_checks.js');
}

// ---------- verdict ----------

if (fails.length) {
  for (const f of fails) console.log('FAIL ' + f);
  console.log('FAIL: ' + fails.length + ' entry document problem(s)');
  process.exit(1);
}
console.log('PASS: ' + paths.size + ' paths named in the entry documents exist, ' + readmes.length
  + ' READMEs state no stale scenario count (' + scenariosFile + ' holds ' + scenarioCount
  + ') or latest record, and the two stale entry-document claims stay gone');
