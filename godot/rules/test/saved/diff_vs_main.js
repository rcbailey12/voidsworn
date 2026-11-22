'use strict';
// Issue 1654 (Artoo review on PR 1669): the saved-results check proves this checkout reproduces its own saved files.
// It cannot show what a PR changed when the PR also updates those files. This lists every saved battle, rules file
// and campaign file whose saved checksum differs from main, so a deliberate update stays visible to the reviewer.
// Usage: node godot/rules/test/saved/diff_vs_main.js [base-ref] [out-file]   (base defaults to origin/main)
const fs = require('node:fs'), path = require('node:path'), { execFileSync } = require('node:child_process');
const ROOT = path.resolve(__dirname, '../../../..');
const base = process.argv[2] || 'origin/main', out = process.argv[3];
const SETS = [
  ['rules battle', 'godot/rules/test/saved/results.json', 'battles'],
  ['rules file', 'godot/rules/test/saved/results.json', 'files'],
  ['campaign file', 'godot/campaign/test/saved/results.json', 'files'],
];
// Codex review of PR 1669: only a campaign manifest genuinely absent at the base (before the retirement) counts as new.
// A bad ref, a missing rules manifest, a git error or broken JSON stops the report instead of listing everything as added.
const git = (args, opts = {}) => execFileSync('git', args, { cwd: ROOT, encoding: 'utf8', maxBuffer: 64 << 20, ...opts });
let commit;
try { commit = git(['rev-parse', '--verify', '-q', `${base}^{commit}`], { stdio: ['ignore', 'pipe', 'pipe'] }).trim(); }
catch { console.log(`FAIL: ${base} is not a commit here; nothing compared`); process.exit(1); }
function atBase(rel, mayBeAbsent) {
  const ls = git(['ls-tree', '--name-only', commit, '--', rel]).trim();
  if (!ls) {
    if (mayBeAbsent) return {};
    console.log(`FAIL: ${rel} is missing at ${base} (${commit.slice(0, 12)}); nothing compared`); process.exit(1);
  }
  try { return JSON.parse(git(['show', `${commit}:${rel}`])); }
  catch (e) { console.log(`FAIL: cannot read ${rel} at ${base}: ${e.message.split('\n')[0]}`); process.exit(1); }
}
const lines = [];
for (const [label, rel, key] of SETS) {
  const head = JSON.parse(fs.readFileSync(path.join(ROOT, rel), 'utf8'))[key] || {};
  const old = atBase(rel, rel.startsWith('godot/campaign/'))[key] || {};
  for (const name of [...new Set([...Object.keys(old), ...Object.keys(head)])].sort()) {
    if (!old[name]) lines.push(`added    ${label} ${name}`);
    else if (!head[name]) lines.push(`removed  ${label} ${name}`);
    else if (old[name].sha256 !== head[name].sha256) lines.push(`changed  ${label} ${name} (${old[name].sha256.slice(0, 12)} -> ${head[name].sha256.slice(0, 12)})`);
  }
}
const text = [`Saved Godot results changed by this branch compared with ${base}: ${lines.length}`, ...lines].join('\n') + '\n';
process.stdout.write(text);
if (out) fs.writeFileSync(out, text);
if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, '```\n' + text + '```\n');
