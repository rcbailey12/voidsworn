'use strict';
// Runs auto_pr.yml's real step under a workflow_dispatch event (no head_commit) with a fake gh, for a job branch and for
// a branch that must be refused. Proves the stale-work sweep's re-run opens the PR with the branch tip's message.
const fs = require('fs'); const os = require('os'); const path = require('path'); const { spawnSync } = require('child_process');
const wf = fs.readFileSync(process.argv[2], 'utf8');
const run = /^        run: \|\r?\n((?: {10}[^\n]*\n|\r?\n)*)/m.exec(wf)[1].replace(/^ {10}/gm, '');
const fake = `gh() {
  echo "gh $*" >> "$CALLS"
  case "$*" in
    "api repos/acme/vs/pulls?state=open&head=acme:"*) echo 0 ;;
    "api repos/acme/vs/commits/"*" --jq .commit.message") printf 'Issue 2148: FX id table\\n\\nRunner report line\\n' ;;
    "api repos/acme/vs/issues/2148 --jq .title") echo 'FX id table' ;;
    "api repos/acme/vs/pulls -f base=main"*) cp body.md "$BODY_OUT"; return 0 ;;
    *) echo "unexpected gh call: $*" >&2; return 9 ;;
  esac
}
`;
for (const [branch, expectPr] of [['codex/issue-2148', true], ['board/pc-out-1119a', false], ['muse/wip-x', false]]) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'disp-'));
  fs.writeFileSync(path.join(dir, 'event.json'), JSON.stringify({ ref: 'refs/heads/' + branch, inputs: {} }));
  fs.writeFileSync(path.join(dir, 'step.sh'), fake + run);
  const env = { ...process.env, GH_TOKEN: 'x', BRANCH: branch, REPO: 'acme/vs', STANDING: '256 906', GITHUB_EVENT_PATH: path.join(dir, 'event.json'),
    GITHUB_EVENT_NAME: 'workflow_dispatch', CALLS: path.join(dir, 'calls.txt'), BODY_OUT: path.join(dir, 'body_out.md') };
  const r = spawnSync('bash', ['-e', 'step.sh'], { cwd: dir, env, encoding: 'utf8' });
  const calls = fs.existsSync(env.CALLS) ? fs.readFileSync(env.CALLS, 'utf8') : '';
  const opened = /pulls -f base=main/.test(calls);
  const body = fs.existsSync(env.BODY_OUT) ? fs.readFileSync(env.BODY_OUT, 'utf8') : '';
  console.log(`${branch}: exit ${r.status}, PR opened ${opened}${opened ? ', title from tip: ' + /-f title=(Issue 2148: FX id table)/.test(calls) + ', body has report: ' + body.includes('Runner report line') : ''} ${r.stdout.trim().split('\n').pop()}`);
  if (opened !== expectPr || r.status !== 0) { console.log(r.stderr); process.exitCode = 1; }
}
