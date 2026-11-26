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
//     on that branch in any state, with a tip dated 15 minutes to 14 days ago (REST exposes commit time, not push time).
//     Live mode confirms the tip is ahead of the default branch before reporting or dispatching it.
//   2 partial runs: <branch>-partial older than 24 hours whose full branch does not contain the partial tip.
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
function analyze(data, patterns, now, containsPartial = () => false) {
  const localPulls = data.pulls.filter(p => p.local_head !== false);
  const prHeads = new Set(localPulls.map(p => p.head + ':' + p.head_sha));
  const openHeads = new Set(localPulls.filter(p => p.state === 'open').map(p => p.head));
  const out = { noPr: [], unseen: [], partial: [], green: [], red: [], closedNoPr: [], afterMerge: [] };
  const byName = new Map(data.branches.map(b => [b.name, b]));
  for (const b of data.branches) {
    const a = age(now, b.date);
    if (b.name.endsWith('-partial')) {
      if (!SEAT_PREFIX.test(b.name) || !(a > 24)) continue;
      const full = byName.get(b.name.slice(0, -8));
      // Timestamps and PR edits do not prove that the full branch contains the work.
      const recovered = full && (full.sha === b.sha || containsPartial(b, full));
      if (!recovered) out.partial.push({ branch: b.name, age: a });
      continue;
    }
    if (prHeads.has(b.name + ':' + b.sha) || openHeads.has(b.name)) continue;
    if (!Number.isFinite(a) || a < 0.25 || a > 14 * 24) continue;
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
    if (i.state_reason !== 'completed' || !(age(now, i.closed_at) <= 7 * 24)) continue;
    if (!i.labels.some(l => JOB_LABELS.includes(l))) continue;
    if (!mergedIssues.has(i.number)) out.closedNoPr.push({ issue: i.number, title: i.title, age: age(now, i.closed_at) });
  }
  const merged = new Map(data.pulls.filter(p => p.merged_at).map(p => [p.number, p]));
  for (const c of data.comments) {
    const p = merged.get(Number(c.issue));
    if (!p || age(now, c.created_at) > 7 * 24) continue;
    if (Date.parse(c.created_at) > Date.parse(p.merged_at)) out.afterMerge.push({ pr: p.number, user: c.user, at: c.created_at, first: (c.body || '').split('\n')[0].slice(0, 120) });
  }
  out.noPr.sort((x, y) => x.age - y.age);
  return { out, branchCount: byName.size };
}

function report(r, now, dispatched) {
  const o = r.out; const L = [];
  L.push(`# Stale work, ${new Date(now).toISOString().slice(0, 16).replace('T', ' ')} UTC`, '');
  L.push(`Written by contrib/opus/tools/stale_work.js. Each list is work that was done but is not moving.`, '');
  const sec = (title, rows, fmt) => { L.push(`## ${title} (${rows.length})`, ''); for (const x of rows) L.push('- ' + fmt(x)); if (!rows.length) L.push('- none'); L.push(''); };
  sec('Job branches with no pull request', o.noPr, x => `${x.branch} (${x.sha.slice(0, 8)}, tip ${hrs(x.age)} old)${dispatched.includes(x.branch) ? ': sent back through auto-pr' : ''}`);
  sec('Seat branches auto-pr never sees (open a PR by hand or rename)', o.unseen, x => `${x.branch} (${x.sha.slice(0, 8)}, tip ${hrs(x.age)} old)`);
  sec('Partial runs nobody finished', o.partial, x => `${x.branch} (${hrs(x.age)} old)`);
  sec('Green pull requests waiting on a merge', o.green, x => `#${x.pr} ${x.title} (untouched ${hrs(x.age)})`);
  sec('Red pull requests waiting on a fix', o.red, x => `#${x.pr} ${x.title} (untouched ${hrs(x.age)})`);
  sec('Job issues closed as done with no merged pull request', o.closedNoPr, x => `#${x.issue} ${x.title} (closed ${hrs(x.age)} ago)`);
  sec('Comments posted after a merge', o.afterMerge, x => `#${x.pr} ${x.user} at ${x.at.slice(0, 16)}: ${x.first}`);
  return L.join('\n');
}

// ---- live data through gh (REST only, RULEBOOK 2.5)
function gh(args, input) { return execFileSync('gh', args, { input, encoding: 'utf8', maxBuffer: 1 << 28, timeout: 60000, windowsHide: true }); }
const jsonLines = s => s.split('\n').filter(Boolean).map(l => JSON.parse(l));
const autoPrPath = path.join(__dirname, '../../../.github/workflows/auto_pr.yml');

function fetchGithub(repo, now, request = gh) {
  const since = new Date(now - 7 * 24 * HOUR).toISOString();
  const defaultBranch = request(['api', `repos/${repo}`, '--jq', '.default_branch']).trim();
  if (!defaultBranch) throw new Error('Could not read the default branch for ' + repo);
  const refs = jsonLines(request(['api', `repos/${repo}/branches?per_page=100`, '--paginate', '--jq', '.[] | {name, sha: .commit.sha}']));
  const pulls = jsonLines(request(['api', `repos/${repo}/pulls?state=all&per_page=100&sort=updated&direction=desc`, '--paginate', '--jq',
    `.[] | {number, state, merged_at, updated_at, head: .head.ref, head_sha: .head.sha, title, body, local_head: (((.head.repo.full_name // "") | ascii_downcase) == ${JSON.stringify(repo.toLowerCase())})}`]));
  const patterns = branchPatterns(fs.readFileSync(autoPrPath, 'utf8'));
  const coveredHeads = new Set(pulls.filter(p => p.local_head).map(p => p.head + ':' + (p.state === 'open' ? '' : p.head_sha)));
  // Dates only where a rule needs one: branches with no PR at their tip, and partial branches.
  const branches = [];
  for (const r of refs) {
    const need = r.name.endsWith('-partial') || (SEAT_PREFIX.test(r.name) &&
      !coveredHeads.has(r.name + ':') && !coveredHeads.has(r.name + ':' + r.sha));
    // A branch no rule needs a date for gets "now"; no rule reads it.
    r.date = need ? request(['api', `repos/${repo}/commits/${r.sha}`, '--jq', '.commit.committer.date']).trim() : new Date(now).toISOString();
    branches.push(r);
  }
  for (const p of pulls) {
    if (p.state !== 'open') continue;
    p.checks = request(['api', `repos/${repo}/commits/${p.head_sha}/check-runs?check_name=All%20checks&filter=latest`,
      '--jq', '[.check_runs[] | select(.app.slug == "github-actions")] | sort_by(.started_at, .id) | last | .conclusion // "pending"']).trim();
  }
  const issues = jsonLines(request(['api', `repos/${repo}/issues?state=closed&since=${since}&per_page=100`, '--paginate', '--jq',
    '.[] | select(.pull_request == null) | {number, title, state_reason, closed_at, labels: [.labels[].name]}']));
  const comments = jsonLines(request(['api', `repos/${repo}/issues/comments?since=${since}&per_page=100`, '--paginate', '--jq',
    '.[] | {issue: (.issue_url | split("/") | last), user: .user.login, created_at, body}']));
  const r = analyze({ branches, pulls, issues, comments }, patterns, now, (partial, full) => {
    // Compare immutable SHAs in this order: an "ahead" full head contains the partial tip.
    // If the compare cannot establish that, keep the partial visible.
    try {
      return request(['api', `repos/${repo}/compare/${partial.sha}...${full.sha}?per_page=1`, '--jq', '.status']).trim() === 'ahead';
    } catch {
      return false;
    }
  });
  const base = encodeURIComponent(defaultBranch);
  const compare = x => {
    const raw = request(['api', `repos/${repo}/compare/${base}...${x.sha}?per_page=1`, '--jq', '.ahead_by']).trim();
    if (!/^\d+$/.test(raw)) throw new Error('Could not check whether ' + x.branch + ' is ahead of ' + defaultBranch);
    return Number(raw) > 0;
  };
  r.out.noPr = r.out.noPr.filter(compare);
  return { ...r, defaultBranch };
}

function dispatch(repo, defaultBranch, candidates, request = gh) {
  const sent = [];
  const failed = [];
  for (const x of candidates.slice(0, 20)) {
    try {
      // Run main's workflow. The orphaned branch may predate workflow_dispatch and must not supply its own workflow.
      request(['api', '-X', 'POST', `repos/${repo}/actions/workflows/auto_pr.yml/dispatches`,
        '-f', `ref=${defaultBranch}`, '-f', `inputs[branch]=${x.branch}`, '--silent']);
      sent.push(x.branch);
    } catch (error) {
      failed.push(x.branch + ': ' + error.message);
    }
  }
  return { sent, failed };
}

function main() {
  const argv = process.argv.slice(2);
  const opt = k => { const i = argv.indexOf(k); return i >= 0 ? argv[i + 1] : null; };
  const now = opt('--now') ? Date.parse(opt('--now')) : Date.now();
  if (!Number.isFinite(now)) throw new Error('--now requires a valid date');
  const issue = opt('--issue');
  if (argv.includes('--issue') && !/^[1-9]\d*$/.test(issue || '')) throw new Error('--issue requires a positive issue number');
  let result, liveRepo = null;
  if (argv.includes('--github')) {
    const repo = process.env.GITHUB_REPOSITORY || opt('--repo');
    if (!repo) throw new Error('--github needs GITHUB_REPOSITORY or --repo owner/name');
    result = fetchGithub(repo, now);
    liveRepo = repo;
  } else if (opt('--data')) {
    const data = JSON.parse(fs.readFileSync(opt('--data'), 'utf8'));
    const patterns = branchPatterns(fs.readFileSync(opt('--auto-pr') || autoPrPath, 'utf8'));
    result = analyze(data, patterns, now);
  } else { console.error('usage: stale_work.js --github [--dispatch] [--issue N] | --data file.json [--now ISO]'); process.exit(2); }
  const { sent, failed } = argv.includes('--dispatch') && liveRepo
    ? dispatch(liveRepo, result.defaultBranch, result.out.noPr) : { sent: [], failed: [] };
  const md = report(result, now, sent);
  console.log(md);
  if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, md + '\n');
  if (issue && liveRepo) {
    gh(['api', '-X', 'PATCH', `repos/${liveRepo}/issues/${issue}`, '-F', 'body=@-', '--silent'], md);
  }
  for (const failure of failed) console.error('Dispatch failed: ' + failure);
  if (failed.length) process.exitCode = 1;
}
if (require.main === module) main();
module.exports = { analyze, branchPatterns, covered, report, fetchGithub, dispatch };
