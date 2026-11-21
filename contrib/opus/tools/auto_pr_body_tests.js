'use strict';
// Issue 1098: exercise both real workflow paths with a fake gh that enforces the body limit.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const workflow = fs.readFileSync(path.join(__dirname, '../../../.github/workflows/auto_pr.yml'), 'utf8');
const run = /^        run: \|\r?\n((?: {10}[^\n]*\n|\r?\n)*)/m.exec(workflow);
assert.ok(run, 'auto_pr.yml is missing its Bash step');
const step = run[1].replace(/\r\n/g, '\n').replace(/^ {10}/gm, '');
const windows = process.platform === 'win32';
const bash = windows ? path.join(process.env.ProgramFiles, 'Git', 'bin', 'bash.exe') : 'bash';
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'auto-pr-1098-'));
const event = path.join(tmp, 'event.json');
const branch = 'work/issue-1098-openai';
// The test runs with the workflow's own STANDING list, so a change there is exercised here (issue 1488 added 906).
const standingMatch = /^ +STANDING: '([0-9 ]+)'/m.exec(workflow);
assert.ok(standingMatch, 'auto_pr.yml is missing its STANDING list');
const standingList = standingMatch[1];
assert.deepEqual(standingList.split(' ').filter(Boolean).sort(), ['256', '906'], 'STANDING must list 256 and 906');

// Issue 1488: the step uses REST (gh api) only. This fake answers exactly the calls it makes and fails any other call,
// so a gh pr (GraphQL) call coming back fails this test.
const fakeGh = [
  'gh() {',
  '  [ "$1" = api ] || return 2',
  '  local body_arg=""',
  '  for a in "$@"; do case "$a" in body=@*) body_arg="${a#body=@}" ;; esac; done',
  '  case "$2 $3 $4" in',
  '    "repos/example/voidsworn/pulls?state=open&head=example:$BRANCH --jq length")',
  '      if [ "$PR_ACTION" = edit ]; then echo 1; else echo 0; fi ;;',
  '    "repos/example/voidsworn/pulls?state=open&head=example:$BRANCH --jq .[0].number") echo 42 ;;',
  '    "repos/example/voidsworn/issues/1098 --jq .title") echo "Fixture title" ;;',
  '    "repos/example/voidsworn/pulls/42 --jq .body") printf "%s\\n" "$EXISTING_PR_BODY" ;;',
  '    "repos/example/voidsworn/pulls -f base=main")',
  '      [ "$PR_ACTION" = create ] && [ "$5 $6" = "-f head=$BRANCH" ] && [ "$body_arg" = body.md ] && [ "${!#}" = --silent ] || return 2',
  '      [ "$(wc -c < "$body_arg")" -le 65536 ] || { echo "Body is too long" >&2; return 1; }',
  '      echo "sent create" ;;',
  '    "-X PATCH repos/example/voidsworn/pulls/42")',
  '      [ "$PR_ACTION" = edit ] && [ "$body_arg" = body.md ] && [ "${!#}" = --silent ] || return 2',
  '      [ "$(wc -c < "$body_arg")" -le 65536 ] || { echo "Body is too long" >&2; return 1; }',
  '      echo "sent edit" ;;',
  '    *) echo "unexpected gh call: $*" >&2; return 2 ;;',
  '  esac',
  '}',
  'sleep() { :; }',
].join('\n');

// Actions has jq. Git for Windows ships Bash and coreutils, and this shim reads the same test payload.
const windowsSetup = [
  'export PATH="/usr/bin:$PATH"',
  'if ! command -v jq >/dev/null; then',
  '  jq() {',
  '    [ "$1 $2" = "-r .head_commit.message" ] || return 2',
  "    node -e 'console.log(JSON.parse(require(\"node:fs\").readFileSync(process.argv[1], \"utf8\")).head_commit.message)' \"$3\"",
  '  }',
  'fi',
].join('\n');

function send(action, message, head = branch, existingBody = '') {
  const payload = JSON.stringify({ head_commit: { message } });
  fs.writeFileSync(event, payload);
  const result = spawnSync(bash, ['--noprofile', '--norc', '-e', '-s'], {
    cwd: tmp,
    input: [windows ? windowsSetup : '', fakeGh, step].join('\n'),
    encoding: 'utf8',
    env: { ...process.env, PR_ACTION: action, BRANCH: head, REPO: 'example/voidsworn',
      STANDING: standingList, GITHUB_EVENT_PATH: 'event.json', EXISTING_PR_BODY: existingBody },
    timeout: 30000,
    windowsHide: true,
  });
  assert.ifError(result.error);
  assert.equal(result.status, 0, action + '\n' + result.stdout + result.stderr);
  assert.match(result.stdout, new RegExp('^sent ' + action + '$', 'm'));
  assert.equal(fs.readFileSync(event, 'utf8'), payload, 'head commit message changed');
  const bytes = fs.readFileSync(path.join(tmp, 'body.md'));
  assert.ok(bytes.length < 65000, action + ': body must be under 65,000 bytes');
  return new TextDecoder('utf-8', { fatal: true }).decode(bytes);
}

const title = 'Workhorse openai arm (issue #1098): Fixture title';
const report = 'Summary of the job\n\n![Review picture](shots/example.png)\n\n## Impact sweep\nReviewed both paths.';
const checks = '## Checks run by the runner\n\n```\n';
const afterChecks = '\n```\n\n## Run stats (runner)\n\n```\nmodel: fixture\n```\n\nRefs #1098\n\n## Runner (issue 377)\n\nRun-Number: 2';

function messageWithChecks(size) {
  const head = `${title}\n\n${report}\n\n${checks}`;
  const log = Array.from({ length: 120 }, (_, i) => `log line ${i + 1}`);
  const extra = size - head.length - log.join('\n').length - afterChecks.length;
  // Put the extra bytes in the middle, in realistic lines short enough to retain either end.
  for (let i = 40; i < 80; i++) {
    log[i] += 'x'.repeat(Math.floor(extra / 40) + Number(i - 40 < extra % 40));
  }
  const message = head + log.join('\n') + afterChecks;
  assert.equal(message.length, size);
  return { message, log };
}

const notice = count => `(${count} check lines cut. Full log is in the head commit message.)`;

for (const action of ['create', 'edit']) {
  const long = messageWithChecks(70000);
  const footer = action === 'create'
    ? `Opened automatically from branch ${branch}. The Board reviews and merges.\n\nCloses #1098\n`
    : `Refreshed from the latest push to branch ${branch}. The Board reviews and merges.\n`;
  assert.equal(send(action, long.message), `\n${report}\n\n${checks}` +
    [...long.log.slice(0, 40), notice(40), ...long.log.slice(-40)].join('\n') +
    afterChecks + '\n\n' + footer);

  const short = messageWithChecks(64000).message;
  assert.equal(send(action, short), short.slice(title.length + 1) + '\n\n' + footer);

  const plain = `${title}\n\n${report}\n\n${'\u{1f525}'.repeat(33000)}\n\nRefs #1098`;
  const cut = send(action, plain);
  const cutNotice = '\n\n(Report cut to fit. Full text is in the head commit message.)\n\n';
  assert.ok(cut.includes(cutNotice));
  assert.ok(plain.slice(title.length + 1).startsWith(cut.split(cutNotice)[0]));
  assert.match(cut, /^Refs #1098$/m);
  if (action === 'create') assert.match(cut, /^Closes #1098$/m);

  const codexLog = ['checks_node.txt', ...long.log];
  const codex = `${title}\n\n${report}\n\nRunner checks:\n\n${codexLog.join('\n')}\n\nRefs #1098`;
  const codexBody = send(action, codex, 'codex/issue-1098');
  const excerpt = [...codexLog.slice(0, 40), notice(41), ...codexLog.slice(-40)].join('\n');
  assert.ok(codexBody.includes(`Runner checks:\n\n${excerpt}\n\nRefs #1098`));

  const wideLog = `${title}\n\n${report}\n\n${checks}${'x'.repeat(70000)}${afterChecks}`;
  const wideBody = send(action, wideLog);
  assert.ok(wideBody.includes(checks + notice(1) + afterChecks));
}

// Issue 906 (Artoo on PR 943): an issue-less Muse branch keeps the report's own issue links when cut, never a bare "Refs #".
for (const action of ['create', 'edit']) {
  const museTitle = 'Muse look pass';
  const muse = `${museTitle}\n\n${report}\n\n${'y'.repeat(70000)}\n\nRefs #726\nCloses #727`;
  const museBody = send(action, muse, 'muse/look-pass-726');
  assert.ok(museBody.includes('\n\n(Report cut to fit. Full text is in the head commit message.)\n\n'));
  assert.match(museBody, /^Refs #726$/m);
  assert.match(museBody, /^Closes #727$/m);
  assert.doesNotMatch(museBody, /#\s*$/m);
  const museShort = `${museTitle}\n\n${report}\n\nRefs #726`;
  assert.match(send(action, museShort, 'muse/look-pass-726'), /^Refs #726$/m);
}

// Issue 1135: a refresh respects the Board's Refs decision for the branch issue.
const refreshMessage = `${title}\n\n${report}`;
const refreshFooter = `Refreshed from the latest push to branch ${branch}. The Board reviews and merges.`;
const refreshed = `\n${report}\n\n${refreshFooter}\n\n`;
assert.equal(send('edit', refreshMessage, branch, 'Older report\n\nRefs #1098\nCloses #727'),
  refreshed + 'Refs #1098\n', 'keep the Board Refs directive for this issue');
assert.equal(send('edit', `${refreshMessage}\n\nFIXES: #1098\nCloses #727`, branch, 'Refs #1098'),
  `\n${report}\n\nRefs #1098\nCloses #727\n\n${refreshFooter}\n`, 'replace a closing word for this issue only');
assert.equal(send('edit', refreshMessage, branch, 'Closes #1098'), refreshed + 'Closes #1098\n');
assert.equal(send('edit', refreshMessage, branch, 'Refs #1098\nFIXES: #1098'), refreshed + 'Closes #1098\n');
assert.equal(send('edit', refreshMessage, branch, 'Older report'), refreshed + 'Closes #1098\n');
assert.equal(send('edit', refreshMessage, branch, 'Older report\n\nRefs #10980'), refreshed + 'Closes #1098\n');

const standingBody = send('edit', `${refreshMessage}\n\nCloses #256`, 'codex/issue-256', 'Closes #256');
assert.match(standingBody, /^Refs #256$/m);
assert.doesNotMatch(standingBody, /^Closes #256$/m);
// Issue 1488: Artoo's standing sweep 906 stays open through every merge, on create and on refresh.
for (const action of ['create', 'edit']) {
  const sweep = send(action, `${refreshMessage}\n\nCloses #906\nfixes: #256`, 'codex/issue-906', 'Closes #906');
  assert.match(sweep, /^Refs #906$/m, action);
  assert.match(sweep, /^Refs #256$/m, action);
  assert.doesNotMatch(sweep, /(close[sd]?|fix(e[sd])?|resolve[sd]?):?\s+#(906|256)\b/i, action);
}

console.log('PASS auto_pr_body_tests: create and edit bound long bodies and refreshes keep the Board Refs directive');
