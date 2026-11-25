'use strict';
// Tests for stale_work.js: each rule fires on a planted case and stays quiet on its twin.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { analyze, branchPatterns, covered, report } = require('./stale_work.js');

const patterns = branchPatterns(fs.readFileSync(path.join(__dirname, '../../../.github/workflows/auto_pr.yml'), 'utf8'));
const now = Date.parse('2026-11-25T18:00:00Z');
const t = h => new Date(now - h * 3600e3).toISOString();

// auto_pr's own patterns decide which branches are job branches.
assert.equal(covered(patterns, 'codex/issue-2148'), true);
assert.equal(covered(patterns, 'codex/issue-2148-partial'), false);
assert.equal(covered(patterns, 'muse/wip-notes'), false);
assert.equal(covered(patterns, 'board/pc-out-1119a'), false);

const data = {
  branches: [
    { name: 'codex/issue-2148', sha: 'a1', date: t(2) },          // rule 1: pushed 2 h ago, no PR
    { name: 'codex/issue-2142', sha: 'a2', date: t(2) },          // has PR 2166 at its tip
    { name: 'codex/issue-2150', sha: 'a3', date: t(0.1) },        // 6 minutes old: auto_pr may still be running
    { name: 'work/issue-900-sonnet', sha: 'a4', date: t(24 * 20) }, // 20 days old: too old to send back
    { name: 'opus/issue-777', sha: 'a5b', date: t(5) },           // PR 700 was at an older tip: new work, no PR
    { name: 'board/pc-out-x', sha: 'a6', date: t(3) },            // not a job branch
    { name: 'neon/holistic-and-looks-1123', sha: 'n1', date: t(40) }, // a seat branch auto_pr never sees
    { name: 'muse/wip-scratch', sha: 'n2', date: t(4) },           // opted out on purpose
    { name: 'codex/issue-500-partial', sha: 'p1', date: t(48) },  // rule 2: nobody finished it
    { name: 'codex/issue-501-partial', sha: 'p2', date: t(48) },  // finished later on the full branch
    { name: 'codex/issue-501', sha: 'p3', date: t(30) },
    { name: 'codex/issue-502-partial', sha: 'p4', date: t(3) },   // too fresh to call stale
  ],
  pulls: [
    { number: 2166, state: 'open', merged_at: null, updated_at: t(1), head: 'codex/issue-2142', head_sha: 'a2', title: 'Issue 2142: x', checks: 'success' },
    { number: 700, state: 'closed', merged_at: null, updated_at: t(50), head: 'opus/issue-777', head_sha: 'a5', title: 'Issue 777: y' },
    { number: 801, state: 'open', merged_at: null, updated_at: t(13), head: 'codex/issue-801', head_sha: 'z1', title: 'Issue 801: green', checks: 'success' },
    { number: 802, state: 'open', merged_at: null, updated_at: t(30), head: 'codex/issue-802', head_sha: 'z2', title: 'Issue 802: red', checks: 'failure' },
    { number: 803, state: 'open', merged_at: null, updated_at: t(10), head: 'codex/issue-803', head_sha: 'z3', title: 'Issue 803: red but fresh', checks: 'failure' },
    { number: 810, state: 'closed', merged_at: t(40), updated_at: t(40), head: 'codex/issue-810', head_sha: 'm1', title: 'Issue 810: merged', body: 'Refs #811' },
    { number: 501, state: 'closed', merged_at: t(28), updated_at: t(28), head: 'codex/issue-501', head_sha: 'p3', title: 'Issue 501: done' },
  ],
  issues: [
    { number: 810, title: 'merged one', state_reason: 'completed', closed_at: t(39), labels: ['codex'] },
    { number: 811, title: 'named by Refs', state_reason: 'completed', closed_at: t(39), labels: ['codex'] },
    { number: 812, title: 'closed, nothing merged', state_reason: 'completed', closed_at: t(20), labels: ['opus'] },
    { number: 813, title: 'not planned', state_reason: 'not_planned', closed_at: t(20), labels: ['opus'] },
    { number: 814, title: 'not a job issue', state_reason: 'completed', closed_at: t(20), labels: ['ryan'] },
  ],
  comments: [
    { issue: '810', user: 'artoo-review', created_at: t(30), body: 'Two fixes still needed: ...' }, // after the merge
    { issue: '810', user: 'board', created_at: t(41), body: 'before the merge' },
  ],
};

const { out } = analyze(data, patterns, now);
assert.deepEqual(out.noPr.map(x => x.branch), ['codex/issue-2148', 'opus/issue-777']);
assert.deepEqual(out.unseen.map(x => x.branch), ['neon/holistic-and-looks-1123']);
assert.deepEqual(out.partial.map(x => x.branch), ['codex/issue-500-partial']);
assert.deepEqual(out.green.map(x => x.pr), [801]);
assert.deepEqual(out.red.map(x => x.pr), [802]);
assert.deepEqual(out.closedNoPr.map(x => x.issue), [812]);
assert.deepEqual(out.afterMerge.map(x => x.pr), [810]);
const md = report({ out }, now, ['codex/issue-2148']);
assert.match(md, /codex\/issue-2148 \(a1, pushed 2 h ago\): sent back through auto-pr/);
assert.doesNotMatch(md, /—/, 'no em dashes in the report');
console.log('stale_work_tests: PASS (7 rules, planted and clean cases)');
