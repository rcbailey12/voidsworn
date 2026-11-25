'use strict';
// Stale work sweep (ways-of-working audit, Nov 25 2026). One cheap script instead of another LLM "dropped work" audit:
// it lists work that was done but is not moving, and re-opens the one gap the pipeline itself leaves: a job branch that
// was pushed while auto_pr.yml failed (GitHub outage, Nov 25: codex/issue-2148 and 2149 got no PR) has no second chance,
// because auto_pr only runs on a push.
//
//   node contrib/opus/tools/stale_work.js --github [--dispatch] [--issue N]   live, with gh (Actions or Ryan's PC)
//   node contrib/opus/tools/stale_work.js --data snapshot.json                 offline, from saved data
//   node contrib/opus/tools/stale_work_tests.js                                tests
//
// Rules (each one a list in the report):
//   1 job branch, no PR: a branch that auto_pr.yml's own patterns cover, whose tip commit is the head of no pull request
//     in any state, last pushed between 15 minutes and 14 days ago. With --dispatch these are sent back through auto_pr.
//   2 partial runs: <branch>-partial older than 24 hours with no full branch pushed since.
//   3 open PRs: green and untouched for 12 hours (waiting on a merge), red for 24 hours (waiting on a fix).
//   4 job issues closed as done in the last 7 days that no merged pull request names.
//   5 comments posted on a pull request after it merged (review findings that may never land), last 7 days.
// It only reads, except --dispatch (starts auto_pr for the rule 1 branches) and --issue N (rewrites that one issue's body).
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const HOUR = 3600e3;
const SEAT_PREFIX = /^(codex|work|opus|muse|neon|claude|deepseek|sonnet)\//;
const JOB_LABELS = ['codex', 'opus', 'muse', 'neon', 'deepseek', 'sonnet'];

function branchPatterns(yml) {
  const block = /^on:\n  push:\n    branches:\n((?:      [^\n]*\n|\s*#[^\n]*\n)*)/m.exec(yml.replace(/\r\n/g, '\n'));
  if (!block) throw new Error('auto_pr.yml: no on.push.branches list');
  return [...block[1].matchAll(/^      - '([^']+)'/gm)].map(m => m[1]);
}
function globRe(glob) {
  const src = glob.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace(/\*\*|\*/g, s => (s === '**' ? '.*' : '[^/]*'));
  return new RegExp('^' + src + '$');
}
// GitHub's filter rules: read in order, the last pattern that matches decides.
function covered(patterns, branch) {
  let on = false;
  for (const p of patterns) {
    const neg = p.startsWith('!');
    if (globRe(neg ? p.slice(1) : p).test(branch)) on = !neg;
  }
  return on;
}
function issueOf(text) {
  const m = /issue-(\d{2,5})\b/.exec(text || '') || /^Issue (\d{2,5}):/.exec(text || '');
  return m ? Number(m[1]) : null;
}
const age = (now, iso) => (now - Date.parse(iso)) / HOUR;
const hrs = h => (h < 48 ? `${Math.round(h)} h` : `${Math.round(h / 24)} days`);

// data: { branches: [{name, sha, date}], pulls: [{number, state, merged_at, updated_at, head, head_sha, title, checks}],
//         issues: [{number, state_reason, closed_at, labels, title}], comments: [{issue, user, created_at, body}] }
function analyze(data, patterns, now) {
  const prHeads = new Set(data.pulls.map(p => p.head_sha));
  const openByHead = new Map(data.pulls.filter(p => p.state === 'open').map(p => [p.head, p]));
  const out = { noPr: [], unseen: [], partial: [], green: [], red: [], closedNoPr: [], afterMerge: [] };
  const names = new Set(data.branches.map(b => b.name));
  for (const b of data.branches) {
    const a = age(now, b.date);
    if (b.name.endsWith('-partial')) {
      const full = data.branches.find(x => x.name === b.name.slice(0, -8));
      const fullNewer = full && Date.parse(full.date) > Date.parse(b.date);
      const prLater = data.pulls.some(p => p.head === b.name.slice(0, -8) && Date.parse(p.updated_at) > Date.parse(b.date));
      if (a > 24 && !fullNewer && !prLater) out.partial.push({ branch: b.name, age: a });
      continue;
    }
    if (prHeads.has(b.sha) || openByHead.has(b.name)) continue;
    if (a < 0.25 || a > 14 * 24) continue;
    if (covered(patterns, b.name)) out.noPr.push({ branch: b.name, sha: b.sha, age: a, issue: issueOf(b.name) });
    // A seat's branch that auto_pr's patterns miss (neon/holistic-and-looks-1123 sat with no PR): listed, never sent.
    else if (SEAT_PREFIX.test(b.name) && !/^muse\/wip-|\/pin-/.test(b.name)) out.unseen.push({ branch: b.name, sha: b.sha, age: a });
  }
  for (const p of data.pulls) {
    if (p.state !== 'open') continue;
    const a = age(now, p.updated_at);
    if (p.checks === 'success' && a > 12) out.green.push({ pr: p.number, title: p.title, age: a });
    if (p.checks === 'failure' && a > 24) out.red.push({ pr: p.number, title: p.title, age: a });
  }
  const mergedIssues = new Set();
  for (const p of data.pulls) {
    if (!p.merged_at) continue;
    for (const t of [p.head, p.title]) { const n = issueOf(t); if (n) mergedIssues.add(n); }
    for (const m of (p.body || '').matchAll(/\bRefs #(\d{2,5})\b/g)) mergedIssues.add(Number(m[1]));
  }
  for (const i of data.issues) {
    if (i.state_reason !== 'completed' || age(now, i.closed_at) > 7 * 24) continue;
    if (!i.labels.some(l => JOB_LABELS.includes(l))) continue;
    if (!mergedIssues.has(i.number)) out.closedNoPr.push({ issue: i.number, title: i.title, age: age(now, i.closed_at) });
  }
  const merged = new Map(data.pulls.filter(p => p.merged_at).map(p => [p.number, p]));
  for (const c of data.comments) {
    const p = merged.get(Number(c.issue));
    if (!p || age(now, c.created_at) > 7 * 24) continue;
    if (Date.parse(c.created_at) > Date.parse(p.merged_at) + 60e3) out.afterMerge.push({ pr: p.number, user: c.user, at: c.created_at, first: (c.body || '').split('\n')[0].slice(0, 120) });
  }
  out.noPr.sort((x, y) => x.age - y.age);
  return { out, branchCount: names.size };
}

function report(r, now, dispatched) {
  const o = r.out; const L = [];
  L.push(`# Stale work, ${new Date(now).toISOString().slice(0, 16).replace('T', ' ')} UTC`, '');
  L.push(`Written by contrib/opus/tools/stale_work.js. Each list is work that was done but is not moving.`, '');
  const sec = (title, rows, fmt) => { L.push(`## ${title} (${rows.length})`, ''); for (const x of rows) L.push('- ' + fmt(x)); if (!rows.length) L.push('- none'); L.push(''); };
  sec('Job branches with no pull request', o.noPr, x => `${x.branch} (${x.sha.slice(0, 8)}, pushed ${hrs(x.age)} ago)${dispatched.includes(x.branch) ? ': sent back through auto-pr' : ''}`);
  sec('Seat branches auto-pr never sees (open a PR by hand or rename)', o.unseen, x => `${x.branch} (${x.sha.slice(0, 8)}, pushed ${hrs(x.age)} ago)`);
  sec('Partial runs nobody finished', o.partial, x => `${x.branch} (${hrs(x.age)} old)`);
  sec('Green pull requests waiting on a merge', o.green, x => `#${x.pr} ${x.title} (untouched ${hrs(x.age)})`);
  sec('Red pull requests waiting on a fix', o.red, x => `#${x.pr} ${x.title} (untouched ${hrs(x.age)})`);
  sec('Job issues closed as done with no merged pull request', o.closedNoPr, x => `#${x.issue} ${x.title} (closed ${hrs(x.age)} ago)`);
  sec('Comments posted after a merge', o.afterMerge, x => `#${x.pr} ${x.user} at ${x.at.slice(0, 16)}: ${x.first}`);
  return L.join('\n');
}

// ---- live data through gh (REST only, RULEBOOK 2.5)
function gh(args) { return execFileSync('gh', args, { encoding: 'utf8', maxBuffer: 1 << 28 }); }
const jsonLines = s => s.split('\n').filter(Boolean).map(l => JSON.parse(l));
function fetchGithub(repo, now) {
  const since = new Date(now - 7 * 24 * HOUR).toISOString();
  const refs = jsonLines(gh(['api', `repos/${repo}/git/matching-refs/heads/`, '--paginate', '--jq', '.[] | {name: (.ref | ltrimstr("refs/heads/")), sha: .object.sha}']));
  const pulls = jsonLines(gh(['api', `repos/${repo}/pulls?state=all&per_page=100&sort=updated&direction=desc`, '--paginate', '--jq',
    '.[] | {number, state, merged_at, updated_at, head: .head.ref, head_sha: .head.sha, title, body}']));
  const patterns = branchPatterns(fs.readFileSync(path.join(__dirname, '../../../.github/workflows/auto_pr.yml'), 'utf8'));
  const prHeads = new Set(pulls.map(p => p.head_sha));
  const partialBases = new Set(refs.filter(r => r.name.endsWith('-partial')).map(r => r.name.slice(0, -8)));
  // Dates only where a rule needs one: branches with no PR at their tip, partial branches and the branches they came from.
  const branches = [];
  for (const r of refs) {
    const need = r.name.endsWith('-partial') || partialBases.has(r.name) || (SEAT_PREFIX.test(r.name) && !prHeads.has(r.sha));
    // A branch no rule needs a date for gets "now"; no rule reads it.
    r.date = need ? gh(['api', `repos/${repo}/commits/${r.sha}`, '--jq', '.commit.committer.date']).trim() : new Date(now).toISOString();
    branches.push(r);
  }
  for (const p of pulls) {
    if (p.state !== 'open') continue;
    const runs = JSON.parse(gh(['api', `repos/${repo}/commits/${p.head_sha}/check-runs?per_page=100`, '--jq', '[.check_runs[] | select(.name == "All checks") | .conclusion]']));
    p.checks = runs.includes('failure') ? 'failure' : runs.includes('success') ? 'success' : 'pending';
  }
  const issues = jsonLines(gh(['api', `repos/${repo}/issues?state=closed&since=${since}&per_page=100`, '--paginate', '--jq',
    '.[] | select(.pull_request == null) | {number, title, state_reason, closed_at, labels: [.labels[].name]}']));
  const comments = jsonLines(gh(['api', `repos/${repo}/issues/comments?since=${since}&per_page=100`, '--paginate', '--jq',
    '.[] | {issue: (.issue_url | split("/") | last), user: .user.login, created_at, body}']));
  return { data: { branches, pulls, issues, comments }, patterns };
}

function main() {
  const argv = process.argv.slice(2);
  const opt = k => { const i = argv.indexOf(k); return i >= 0 ? argv[i + 1] : null; };
  const now = opt('--now') ? Date.parse(opt('--now')) : Date.now();
  let data, patterns, liveRepo = null;
  if (argv.includes('--github')) {
    const repo = process.env.GITHUB_REPOSITORY || opt('--repo');
    if (!repo) throw new Error('--github needs GITHUB_REPOSITORY or --repo owner/name');
    ({ data, patterns } = fetchGithub(repo, now));
    liveRepo = repo;
  } else if (opt('--data')) {
    data = JSON.parse(fs.readFileSync(opt('--data'), 'utf8'));
    patterns = branchPatterns(fs.readFileSync(opt('--auto-pr') || path.join(__dirname, '../../../.github/workflows/auto_pr.yml'), 'utf8'));
  } else { console.error('usage: stale_work.js --github [--dispatch] [--issue N] | --data file.json [--now ISO]'); process.exit(2); }
  const r = analyze(data, patterns, now);
  const dispatched = [];
  if (argv.includes('--dispatch') && liveRepo) {
    for (const x of r.out.noPr.slice(0, 20)) {
      try { gh(['api', '-X', 'POST', `repos/${liveRepo}/actions/workflows/auto_pr.yml/dispatches`, '-f', `ref=${x.branch}`, '--silent']); dispatched.push(x.branch); } catch (e) { console.error(`dispatch ${x.branch}: ${e.message}`); }
    }
  }
  const md = report(r, now, dispatched);
  console.log(md);
  if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, md + '\n');
  if (opt('--issue') && liveRepo) {
    fs.writeFileSync('stale_body.md', md);
    gh(['api', '-X', 'PATCH', `repos/${liveRepo}/issues/${opt('--issue')}`, '-F', 'body=@stale_body.md', '--silent']);
  }
}
if (require.main === module) main();
module.exports = { analyze, branchPatterns, covered, report, issueOf };
