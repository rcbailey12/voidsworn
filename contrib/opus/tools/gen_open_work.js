'use strict';
// Refs #838, #890. Node 18+, no dependencies. Write Markdown only after every list loads.
// Usage: node contrib/opus/tools/gen_open_work.js > contrib/opus/OPEN_WORK.md
// GH_TOKEN, then GITHUB_TOKEN, then the signed-in gh CLI. All calls use REST.
const { execFile } = require('child_process');
const { promisify } = require('util');
const execFileAsync = promisify(execFile);
const REPO = 'repos/rcbailey12/voidsworn';
const SEATS = ['codex', 'muse', 'opus', 'ryan'];

function cell(value) {
  return String(value).replace(/\u2014/g, '-').replace(/[\r\n\t]+/g, ' ')
    .replace(/\\/g, '&#92;').replace(/\|/g, '\\|');
}

function utcStamp(date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const pad = n => String(n).padStart(2, '0');
  return `${months[date.getUTCMonth()]} ${date.getUTCDate()} ${date.getUTCFullYear()} ` +
    `${pad(date.getUTCHours())}:${pad(date.getUTCMinutes())} UTC`;
}

// Plain text for a list line: no em dashes, no line breaks.
function plain(value) {
  return String(value).replace(/\u2014/g, '-').replace(/[\r\n\t]+/g, ' ').trim();
}

const labelNames = issue => issue.labels.map(label => label.name);
const byNumber = (a, b) => a.number - b.number;

// Issue numbers a merged PR names: "Issue N" in its title or "#N" in its body.
function namedIssues(pr) {
  const out = new Set();
  for (const m of String(pr.title || '').matchAll(/\bIssue\s+(\d+)\b/gi)) out.add(Number(m[1]));
  for (const m of String(pr.body || '').matchAll(/#(\d+)\b/g)) out.add(Number(m[1]));
  return out;
}

function renderLiveStatus(pulls, openIssues, closedPulls) {
  const lines = ['## Live status', '', '### Open jobs by seat', '',
    'The seat label says who has the job; running means a seat has claimed it and is working on it now.', ''];
  for (const seat of SEATS) {
    const jobs = openIssues.filter(issue => labelNames(issue).includes(seat));
    if (!jobs.length) {
      lines.push(`- ${seat}: no open jobs.`);
      continue;
    }
    const running = jobs.filter(issue => labelNames(issue).includes('running')).map(issue => issue.number);
    const waiting = jobs.filter(issue => !labelNames(issue).includes('running')).map(issue => issue.number);
    lines.push(`- ${seat}: ${jobs.length} open. Running now: ${running.join(', ') || 'none'}. ` +
      `Not running: ${waiting.join(', ') || 'none'}.`);
  }

  // A PR waits on the Board when it is not a draft and its issue is not still running.
  const runningIssues = new Set(openIssues.filter(issue => labelNames(issue).includes('running')).map(issue => issue.number));
  const issueOf = pr => {
    const m = /^[a-z]+\/issue-(\d+)/.exec(pr.head.ref);
    return m ? Number(m[1]) : null;
  };
  const waitingPulls = [...pulls].filter(pr => !pr.draft && !runningIssues.has(issueOf(pr))).sort(byNumber);
  lines.push('', '### Pull requests waiting on the Board', '',
    'Open, not drafts, and their issue does not carry running.', '');
  if (!waitingPulls.length) lines.push('- none');
  for (const pr of waitingPulls) lines.push(`- PR ${pr.number}: ${plain(pr.title)}`);

  // Open issues named by a merged PR: check the scope and close them if done (RULEBOOK 2.4, R288).
  const mergedBy = new Map();
  for (const pr of closedPulls) {
    if (!pr.merged_at) continue;
    for (const n of namedIssues(pr)) {
      if (!mergedBy.has(n)) mergedBy.set(n, []);
      mergedBy.get(n).push(pr.number);
    }
  }
  const named = openIssues.filter(issue => mergedBy.has(issue.number)).sort(byNumber);
  lines.push('', '### Open issues that a merged pull request names', '',
    'From the last 100 closed pull requests ("Issue N" in the title or "#N" in the body). Check whether the scope is done, ' +
    'then close the issue (RULEBOOK 2.4).', '');
  if (!named.length) lines.push('- none');
  for (const issue of named) {
    const prs = [...mergedBy.get(issue.number)].sort((a, b) => a - b).join(', ');
    lines.push(`- Issue ${issue.number}: ${plain(issue.title)} (merged PR ${prs})`);
  }
  return lines;
}

function renderOpenWork(pulls, issues, now = new Date(), closedPulls = []) {
  const openIssues = issues.filter(item => !item.pull_request);
  const lines = [
    '# Open work (generated from GitHub; FINDINGS R194, issue 788)',
    '',
    `GENERATED ${utcStamp(now)} from the GitHub API by contrib/opus/tools/gen_open_work.js. Do not hand-edit rows: GitHub is the record for what is open and who has it, LOOP.md's newest LATEST line for what is running on the PC. The hand-kept ledger it replaces (stale by Nov 15 evening, found by Ryan's dot) is docs/archive/OPEN_WORK_2026-11-15.md. The open work nightly workflow (.github/workflows/open_work_nightly.yml, issue 890) regenerates this page every night.`,
    '',
    ...renderLiveStatus(pulls, openIssues, closedPulls),
    '',
    '## Open pull requests',
    '',
    '| PR | Branch | Title |',
    '|---|---|---|',
  ];
  for (const pr of [...pulls].sort((a, b) => b.number - a.number)) {
    lines.push(`| ${pr.number} | ${cell(pr.head.ref)} | ${cell(pr.title)} |`);
  }
  lines.push('', '## Open issues', '', '| Issue | Seat labels | Title |', '|---|---|---|');
  for (const issue of [...openIssues].sort(byNumber)) {
    lines.push(`| ${issue.number} | ${cell(labelNames(issue).join(', '))} | ${cell(issue.title)} |`);
  }
  return lines.join('\n') + '\n';
}

async function generateOpenWork({
  env = process.env,
  fetchImpl = globalThis.fetch,
  runGh = execFileAsync,
  perPage = 100,
  now = new Date(),
} = {}) {
  const token = env.GH_TOKEN || env.GITHUB_TOKEN;
  // onePage: read only page 1 (the recent closed PRs).
  async function list(resource, { state = 'open', size = perPage, onePage = false } = {}) {
    const items = [];
    const name = state === 'open' ? resource : `${state} ${resource}`;
    for (let page = 1; ; page++) {
      const sortBy = state === 'closed' ? '&sort=updated&direction=desc' : '';
      const endpoint = `${REPO}/${resource}?state=${state}${sortBy}&per_page=${size}&page=${page}`;
      let data;
      if (token) {
        const response = await fetchImpl(`https://api.github.com/${endpoint}`, {
          headers: {
            Authorization: `Bearer ${token}`,
            Accept: 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'voidsworn-gen-open-work',
          },
          signal: AbortSignal.timeout(30000),
        });
        if (!response.ok) throw new Error(`GitHub REST ${name} page ${page}: HTTP ${response.status}`);
        data = await response.json();
      } else {
        let stdout;
        try {
          ({ stdout } = await runGh('gh', ['api', '--hostname', 'github.com', '--method', 'GET', endpoint], {
            env, windowsHide: true, timeout: 30000, maxBuffer: 32 * 1024 * 1024,
          }));
        } catch (error) {
          if (error.code === 'ENOENT') {
            throw new Error('Set GH_TOKEN or GITHUB_TOKEN, or install gh and sign in with gh auth login.');
          }
          throw new Error(`gh api ${name} page ${page} failed: ${error.stderr || error.message}`);
        }
        data = JSON.parse(stdout);
      }
      if (!Array.isArray(data)) throw new Error(`GitHub REST ${name} page ${page}: expected an array`);
      items.push(...data);
      if (onePage || data.length < size) return items;
    }
  }
  const pulls = await list('pulls');
  const issues = await list('issues');
  const closedPulls = await list('pulls', { state: 'closed', size: 100, onePage: true });
  return renderOpenWork(pulls, issues, now, closedPulls);
}

if (require.main === module) {
  generateOpenWork().then(markdown => process.stdout.write(markdown)).catch(error => {
    console.error('FAIL: ' + String(error.message).replace(/\u2014/g, '-'));
    process.exitCode = 1;
  });
}

module.exports = { generateOpenWork, renderOpenWork };
