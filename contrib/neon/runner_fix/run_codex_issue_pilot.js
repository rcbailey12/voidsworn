'use strict';
const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync } = require('child_process');

const repoRoot = path.resolve(__dirname, '..', '..', '..');
const stage = path.join(repoRoot, 'tools', 'pc');
const logOutArg = process.argv[2] || '';
const overrideTemp = process.argv[3] || '';

const baseTmp = overrideTemp || os.tmpdir();
fs.mkdirSync(baseTmp, { recursive: true });
const root = fs.mkdtempSync(path.join(baseTmp, 'neon-live-pilot-'));
const source = path.join(root, 'upstream.git');
const home = path.join(root, 'pilot-home');
fs.mkdirSync(home, { recursive: true });

function run(exe, args, env = {}, cwd = root) {
  const r = spawnSync(exe, args, {
    cwd,
    env: { ...process.env, ...env },
    encoding: 'utf8',
    windowsHide: true,
    timeout: 240000
  });
  if (r.error) throw r.error;
  return r;
}

const lines = [];
function log(s) {
  lines.push(String(s));
}

try {
  run('git', ['init', '--bare', '-q', source]);
  const seed = path.join(root, 'seed');
  run('git', ['init', '-q', seed]);
  fs.writeFileSync(path.join(seed, 'README.md'), 'pilot repo\n');
  const gEnv = {
    GIT_AUTHOR_NAME: 'Pilot',
    GIT_AUTHOR_EMAIL: 'pilot@local',
    GIT_COMMITTER_NAME: 'Pilot',
    GIT_COMMITTER_EMAIL: 'pilot@local'
  };
  run('git', ['-C', seed, 'add', 'README.md'], gEnv);
  run('git', ['-C', seed, 'commit', '-q', '-m', 'init'], gEnv);
  run('git', ['-C', seed, 'branch', '-M', 'main'], gEnv);
  run('git', ['-C', seed, 'remote', 'add', 'origin', source], gEnv);
  run('git', ['-C', seed, 'push', '-q', 'origin', 'main'], gEnv);
  const baseSha = run('git', ['--git-dir', source, 'rev-parse', 'main']).stdout.trim();

  const gh = require(path.join(stage, 'runner_claim_fixture'))(root);
  const db = gh.database(9991, baseSha);
  db.issue.title = 'Controlled runner pilot (harmless dry run)';
  db.issue.body = [
    '```',
    'Owner: codex',
    'Brief: below',
    'Deliver to: pilot_result.txt',
    'Branch: codex/issue-9991',
    'Base: main',
    'Effort (Codex): medium',
    'Done when: pilot_result.txt contains RUNNER_PILOT_OK and report names the short HEAD SHA.',
    '```',
    '',
    '## THIS IS THE JOB NOW (controlled runner pilot)',
    'Run `git rev-parse --short HEAD` using a shell command, write `RUNNER_PILOT_OK` on a single line to `pilot_result.txt`, verify it with a shell command, and report the short SHA in your final message. Do not commit and do not push. Do not edit any other file.'
  ].join('\n');

  const dbPath = path.join(home, 'gh-db.json');
  const ghTrace = path.join(home, 'gh.jsonl');
  fs.writeFileSync(dbPath, JSON.stringify(db));
  fs.writeFileSync(ghTrace, '');

  const bat = path.join(stage, 'codex_issue.bat');
  const childEnv = {
    ...process.env,
    CODEX_TEST_ROOT: home,
    CODEX_TEST_AGENT: '',
    CODEX_CAP: '180',
    TMO_OWN_COPY: '1',
    PC_TEST_SOURCE: source,
    PC_TEST_MIRROR: path.join(home, 'mirror.git'),
    PC_TEST_GH: gh.fake,
    PC_TEST_GH_DB: dbPath,
    PC_TEST_GH_TRACE: ghTrace,
    PC_TEST_PREFLIGHT: '',
    PC_TEST_RETRY_SECONDS: '0',
    PC_TEST_SPACE_FREE_MB: '70000',
    PC_TEST_STOP_BEFORE_PUBLISH: '0'
  };
  if (overrideTemp) {
    childEnv.TEMP = overrideTemp;
    childEnv.TMP = overrideTemp;
    childEnv.TMPDIR = overrideTemp;
  }

  log('Timestamp: ' + new Date().toISOString());
  log('NodeVersion: ' + process.version);
  log('StageTools: ' + stage);
  log('PilotRoot: ' + root);
  log('EffectiveTEMP: ' + (childEnv.TEMP || ''));

  const t0 = Date.now();
  const res = spawnSync(process.env.COMSPEC, ['/d', '/s', '/c', '""' + bat + '" 9991"'], {
    cwd: root,
    windowsVerbatimArguments: true,
    windowsHide: true,
    encoding: 'utf8',
    timeout: 240000,
    env: childEnv
  });
  const elapsed = ((Date.now() - t0) / 1000).toFixed(2);
  const outDir = path.join(home, 'issue-9991');

  log('=== CONTROLLED REAL PILOT exit=' + res.status + ' elapsed=' + elapsed + 's ===');
  log('--- console ---');
  log((res.stdout || '') + (res.stderr || ''));
  for (const f of ['status.json', 'result.txt', 'diffstat.txt', 'last.md', 'preflight_log.txt', 'log.txt']) {
    const p = path.join(outDir, f);
    log('--- ' + f + ' ---');
    log(fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : '(missing)');
  }
  const pf = path.join(home, 'repo', 'pilot_result.txt');
  const pfVal = fs.existsSync(pf) ? JSON.stringify(fs.readFileSync(pf, 'utf8')) : '(missing)';
  const refs = run('git', ['--git-dir', source, 'show-ref']).stdout.trim();
  const runningFlag = JSON.parse(fs.readFileSync(dbPath, 'utf8')).running;

  log('--- repo/pilot_result.txt ---');
  log(pfVal);
  log('--- remote refs (must NOT contain codex/issue-9991) ---');
  log(refs);
  log('--- fake gh DB running flag (must be false) ---');
  log(String(runningFlag));

  const output = lines.join('\n') + '\n';
  if (logOutArg) {
    fs.mkdirSync(path.dirname(path.resolve(logOutArg)), { recursive: true });
    fs.writeFileSync(logOutArg, output, 'utf8');
  }
  console.log('PILOT_SUMMARY exit=' + res.status + ' elapsed=' + elapsed + 's pilot_result=' + pfVal + ' running=' + runningFlag);
  if (res.status !== 0) process.exitCode = res.status || 1;
} finally {
  try { fs.rmSync(root, { recursive: true, force: true }); } catch {}
}
