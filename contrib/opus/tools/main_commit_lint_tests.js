'use strict';
// Issue 1488: main_commit_lint.js reads pushed commits from the REST compare API and the STANDING list from auto_pr.yml.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { standingFrom, lint, parseLines, pushedCommits } = require('./main_commit_lint.js');

const repoRoot = path.join(__dirname, '../../..');
const autoPr = fs.readFileSync(path.join(repoRoot, '.github/workflows/auto_pr.yml'), 'utf8');
const standing = standingFrom(autoPr);
assert.deepEqual([...standing].sort(), ['256', '906'], 'the lint reads 256 and 906 from auto_pr.yml');
assert.throws(() => standingFrom('no list here'), /Expected one quoted STANDING/);
assert.throws(() => standingFrom("  STANDING: '1'\n  STANDING: '2'\n"), /Expected one/);

const repo = 'rcbailey12/voidsworn';
const commits = [
  { sha: 'a1', message: 'Fix the thing\n\nRefs #906\nCloses #1488' },
  { sha: 'b2', message: 'Sweep\n\nCLOSES: #906' },
  { sha: 'c3', message: 'fixes rcbailey12/voidsworn#256 and resolves https://github.com/rcbailey12/voidsworn/issues/906' },
  { sha: 'd4', message: 'Closes other/repo#256 (another repository)\nCloses #2560 and #9060' },
];
assert.deepEqual(lint(commits, standing, repo), [
  'Commit b2 uses closing words before standing issue(s) #906. Use Refs instead.',
  'Commit c3 uses closing words before standing issue(s) #256, #906. Use Refs instead.',
]);

// Paged gh api --jq output: one JSON object per line, messages with newlines kept.
const pages = [
  JSON.stringify({ sha: 'p1', message: 'one\n\nCloses #256' }),
  JSON.stringify({ sha: 'p2', message: 'two' }),
  '',
  JSON.stringify({ sha: 'p3', message: 'three' }),
].join('\n');
assert.deepEqual(parseLines(pages).map(c => c.sha), ['p1', 'p2', 'p3']);

// The REST calls it makes: compare with pagination for a normal push, the single commit for a new branch.
const calls = [];
const fakeGh = args => { calls.push(args); return pages; };
assert.equal(pushedCommits(fakeGh, repo, 'aaa', 'bbb').length, 3);
assert.deepEqual(calls[0].slice(0, 3), ['api', '--paginate', 'repos/rcbailey12/voidsworn/compare/aaa...bbb?per_page=100']);
pushedCommits(fakeGh, repo, '0000000000000000000000000000000000000000', 'bbb');
assert.deepEqual(calls[1].slice(0, 2), ['api', 'repos/rcbailey12/voidsworn/commits/bbb']);
assert.ok(calls.every(a => a[0] === 'api' && !a.includes('graphql')), 'REST only');

// The workflow no longer clones all history and runs this script.
const yml = fs.readFileSync(path.join(repoRoot, '.github/workflows/main_commit_lint.yml'), 'utf8');
assert.doesNotMatch(yml, /fetch-depth:\s*0/);
assert.match(yml, /run: node contrib\/opus\/tools\/main_commit_lint\.js/);
assert.match(yml, /sparse-checkout:[^]*contrib\/opus\/tools\/main_commit_lint\.js[^]*\.github\/workflows\/auto_pr\.yml/);

console.log('PASS main_commit_lint_tests: REST compare, STANDING 256 and 906 from auto_pr.yml, closing words caught');
