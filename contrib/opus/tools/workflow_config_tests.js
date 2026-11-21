'use strict';
// Issue 1488 (audit GH-06): hold the workflow settings that each fix added, and keep the branch lists of auto_pr.yml
// (opens the pull request) and checks.yml (runs the checks) in step, using GitHub's own filter rules: patterns are read
// in order, the last one that matches decides, '*' stops at '/', '**' does not.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const dir = path.join(__dirname, '../../../.github/workflows');
const read = name => fs.readFileSync(path.join(dir, name), 'utf8').replace(/\r\n/g, '\n');
const autoPr = read('auto_pr.yml');
const checks = read('checks.yml');

function branchPatterns(text) {
  const block = /^on:\n  push:\n    branches:\n((?:      [^\n]*\n|\s*#[^\n]*\n)*)/m.exec(text);
  assert.ok(block, 'no on.push.branches list');
  return [...block[1].matchAll(/^      - '([^']+)'/gm)].map(m => m[1]);
}
function globRe(glob) {
  const src = glob.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace(/\*\*|\*/g, s => (s === '**' ? '.*' : '[^/]*'));
  return new RegExp('^' + src + '$');
}
function triggers(patterns, branch) {
  let on = false;
  for (const p of patterns) {
    const neg = p.startsWith('!');
    if (globRe(neg ? p.slice(1) : p).test(branch)) on = !neg;
  }
  return on;
}

const pr = branchPatterns(autoPr);
const ck = branchPatterns(checks);
// [branch, opens a pull request, runs the checks]
const cases = [
  ['codex/issue-12', true, true],
  ['work/issue-12-openai', true, true],
  ['opus/issue-12', true, true],
  ['opus/issue-12-arm', true, true],
  ['neon/issue-12', true, true],
  ['muse/issue-12', true, true],
  ['muse/look-pass-726', true, true],
  // Scratch and partial branches: no pull request and no checks (the issue 1488 fix).
  ['muse/wip-glass', false, false],
  ['muse/wip-glass/try2', false, false],
  ['codex/issue-12-partial', false, false],
  ['work/issue-12-openai-partial', false, false],
  ['opus/issue-12-partial', false, false],
  ['neon/issue-12-partial', false, false],
  // A nested Muse branch gets checks but no pull request (auto_pr.yml opens PRs for one-level muse/<name> only).
  ['muse/a/b', false, true],
  ['claude/project-thread-x', false, false],
  ['main', false, false],
];
for (const [branch, wantPr, wantChecks] of cases) {
  assert.equal(triggers(pr, branch), wantPr, `auto_pr.yml on ${branch}`);
  assert.equal(triggers(ck, branch), wantChecks, `checks.yml on ${branch}`);
}
// Any branch that opens a pull request also gets its checks, so no PR sits without a pass or fail mark.
for (const [branch] of cases) if (triggers(pr, branch)) assert.ok(triggers(ck, branch), `PR without checks: ${branch}`);

// checks.yml runs with a read-only token.
assert.match(checks, /^permissions:\n  contents: read\n(?!  \S)/m, 'checks.yml needs a top-level permissions: contents: read');
// auto_pr.yml has a short job timeout and uses REST only (RULEBOOK 2.5).
assert.match(autoPr, /^    timeout-minutes: 5$/m, 'auto_pr.yml needs timeout-minutes: 5 on its job');
for (const name of fs.readdirSync(dir).filter(f => /\.ya?ml$/.test(f))) {
  const text = read(name).split('\n').filter(l => !/^\s*#/.test(l)).join('\n');
  assert.doesNotMatch(text, /\bgh (pr|issue) |graphql/i, `${name} must use gh api REST calls, not gh pr/issue (GraphQL)`);
}
// Standing issues 256 (outside check) and 906 (Artoo's sweep) never close on a merge.
assert.match(autoPr, /^ +STANDING: '256 906'/m);

console.log('PASS workflow_config_tests: auto_pr and checks branch lists agree, read-only checks token, REST only, 5 min auto_pr timeout');
