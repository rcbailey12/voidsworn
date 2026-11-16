'use strict';
// Refs #838. Node 18+, no dependencies. Write Markdown only after both lists load.
// Usage: node contrib/opus/tools/gen_open_work.js > contrib/opus/OPEN_WORK.md
// GH_TOKEN, then GITHUB_TOKEN, then the signed-in gh CLI. All calls use REST.
const { execFile } = require('child_process');
const { promisify } = require('util');
const execFileAsync = promisify(execFile);
const REPO = 'repos/rcbailey12/voidsworn';

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

function renderOpenWork(pulls, issues, now = new Date()) {
  const lines = [
    '# Open work (generated from GitHub; FINDINGS R194, issue 788)',
    '',
    `GENERATED ${utcStamp(now)} from the GitHub API by the Board. Do not hand-edit rows: GitHub is the record for what is open and who has it, LOOP.md's newest LATEST line for what is running. The hand-kept ledger it replaces (stale by Nov 15 evening, found by Ryan's dot) is docs/archive/OPEN_WORK_2026-11-15.md. Issue 788 step 5 makes this page regenerate itself nightly.`,
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
  for (const issue of issues.filter(item => !item.pull_request).sort((a, b) => a.number - b.number)) {
    lines.push(`| ${issue.number} | ${cell(issue.labels.map(label => label.name).join(', '))} | ${cell(issue.title)} |`);
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
  async function list(resource) {
    const items = [];
    for (let page = 1; ; page++) {
      const endpoint = `${REPO}/${resource}?state=open&per_page=${perPage}&page=${page}`;
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
        if (!response.ok) throw new Error(`GitHub REST ${resource} page ${page}: HTTP ${response.status}`);
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
          throw new Error(`gh api ${resource} page ${page} failed: ${error.stderr || error.message}`);
        }
        data = JSON.parse(stdout);
      }
      if (!Array.isArray(data)) throw new Error(`GitHub REST ${resource} page ${page}: expected an array`);
      items.push(...data);
      if (data.length < perPage) return items;
    }
  }
  const pulls = await list('pulls');
  const issues = await list('issues');
  return renderOpenWork(pulls, issues, now);
}

if (require.main === module) {
  generateOpenWork().then(markdown => process.stdout.write(markdown)).catch(error => {
    console.error('FAIL: ' + String(error.message).replace(/\u2014/g, '-'));
    process.exitCode = 1;
  });
}

module.exports = { generateOpenWork, renderOpenWork };
