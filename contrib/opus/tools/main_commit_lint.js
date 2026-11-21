'use strict';
// Main commit message lint (audit 706 finding 4; issue 1488 moved it to the REST compare API, so the workflow no longer
// clones the whole history). Reports every pushed commit on main whose message puts a GitHub closing word before a
// standing issue. It cannot undo an issue GitHub already closed; it makes the miss visible.
// Usage on Actions: node main_commit_lint.js (reads GITHUB_REPOSITORY, BEFORE, AFTER, GH_TOKEN; calls gh api).
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

// One source of truth: adding an issue to STANDING in auto_pr.yml also protects it here.
function standingFrom(autoPrText) {
  const lists = [...autoPrText.matchAll(/^\s+STANDING:\s*['"]([0-9 ]+)['"]\s*(?:#.*)?$/gm)];
  if (lists.length !== 1) throw new Error('Expected one quoted STANDING issue list in auto_pr.yml');
  return new Set(lists[0][1].split(/\s+/).filter(Boolean));
}

function escapeRe(s) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

// All nine GitHub closing words, any case, optional colon, subject or body. Local references and explicit references to
// this repository count; another repository's issue does not.
function lint(commits, standing, repo) {
  const r = escapeRe(repo);
  const closing = new RegExp(String.raw`\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?):?\s+` +
    String.raw`(?:#|${r}#|https://github\.com/${r}/issues/)([0-9]+)\b`, 'gi');
  const failures = [];
  for (const { sha, message } of commits) {
    const hits = new Set();
    for (const m of message.matchAll(closing)) if (standing.has(m[1])) hits.add(m[1]);
    if (hits.size) {
      const refs = [...hits].sort((a, b) => a - b).map(n => '#' + n).join(', ');
      failures.push(`Commit ${sha} uses closing words before standing issue(s) ${refs}. Use Refs instead.`);
    }
  }
  return failures;
}

// gh api --paginate --jq prints one JSON line per commit across every page.
function parseLines(out) {
  return out.split('\n').filter(l => l.trim()).map(l => JSON.parse(l));
}

function pushedCommits(gh, repo, before, after) {
  if (/^0+$/.test(before)) {
    // A new branch has no "before". Main is never created by a push, but if it were, check the head commit.
    return parseLines(gh(['api', `repos/${repo}/commits/${after}`, '--jq', '{sha: .sha, message: .commit.message} | @json']));
  }
  // Compare lists the commits reachable from AFTER and not from BEFORE (also right after a force push), 250 per page.
  return parseLines(gh(['api', '--paginate', `repos/${repo}/compare/${before}...${after}?per_page=100`,
    '--jq', '.commits[] | {sha: .sha, message: .commit.message} | @json']));
}

function main() {
  const repo = process.env.GITHUB_REPOSITORY;
  const before = process.env.BEFORE;
  const after = process.env.AFTER;
  const gh = args => execFileSync('gh', args, { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  const config = fs.readFileSync(path.join(__dirname, '../../../.github/workflows/auto_pr.yml'), 'utf8');
  const standing = standingFrom(config);
  const commits = pushedCommits(gh, repo, before, after);
  const failures = lint(commits, standing, repo);
  for (const f of failures) console.log('::error::' + f);
  const summary = ['### Main commit message lint', ...(failures.length
    ? failures.map(f => '- ' + f)
    : [`PASS: checked all ${commits.length} pushed commit(s) against STANDING in auto_pr.yml.`])].join('\n') + '\n';
  if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, summary);
  else process.stdout.write(summary);
  process.exitCode = failures.length ? 1 : 0;
}

if (require.main === module) main();
module.exports = { standingFrom, lint, parseLines, pushedCommits };
