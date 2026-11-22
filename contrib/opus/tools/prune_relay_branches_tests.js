'use strict';
// Issue 1657: tools/pc/prune_relay_branches.ps1. The dry run (default) lists stale board/pc-out-* and board/pin-* branches
// and deletes nothing; it keeps branches in keep.txt, named by a queued job, newer than 3 days, used by an open PR, or
// still needed to prove a relay before a PC job frees its checkout. live deletes from the newest list only a branch
// still at the listed commit that still passes every keep rule now. Needs pwsh (Linux CI has it); skipped without it.
const assert = require('assert');
const fs = require('fs'), os = require('os'), path = require('path');
const { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../..', '..');
const shell = ['pwsh', 'powershell'].find(s => !spawnSync(s, ['-NoProfile', '-Command', 'exit 0']).error);
if (!shell) { console.log('SKIP prune_relay_branches fixtures: they need pwsh (Linux CI runs them)'); process.exit(0); }
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'prune-relay-'));
const vt = path.join(tmp, 'vt'), source = path.join(tmp, 'source.git'), work = path.join(tmp, 'work');
const env = { ...process.env, PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: vt, PC_TEST_SOURCE: source, PC_TEST_OPEN_HEADS: 'board/pin-pr' };
const write = (f, t) => { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, t); };
const git = (args, cwd = tmp, extra = {}) => { const r = spawnSync('git', args, { cwd, encoding: 'utf8', env: { ...process.env, ...extra } }); assert.equal(r.status, 0, `git ${args.join(' ')}: ${r.stderr}`); return r.stdout.trim(); };
const run = (...a) => { const r = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(ROOT, 'tools', 'pc', 'prune_relay_branches.ps1'), ...a], { env, encoding: 'utf8', timeout: 120000 }); return { status: r.status, out: `${r.stdout}\n${r.stderr}` }; };
const branches = () => git(['--git-dir', source, 'for-each-ref', '--format=%(refname:lstrip=2)', 'refs/heads/']).split('\n').filter(Boolean).sort();
try {
  git(['init', '-q', '--bare', source]);
  git(['init', '-q', '-b', 'main', work]);
  const old = '2026-11-10T10:00:00Z';
  const make = (name, date) => {
    write(path.join(work, name.replace(/\//g, '_') + '.txt'), name);
    git(['add', '-A'], work);
    git(['-c', 'user.name=t', '-c', 'user.email=t@example.invalid', 'commit', '-qm', name], work, { GIT_COMMITTER_DATE: date, GIT_AUTHOR_DATE: date });
    git(['push', '-q', source, `HEAD:refs/heads/${name}`], work);
  };
  make('main', old);
  for (const b of ['board/pc-out-stale', 'board/pin-stale', 'board/pin-queued', 'board/pin-keep', 'board/pin-pr', 'board/pc-out-opusbusy', 'board/pc-out-named', 'board/pin-keeplate', 'board/pc-out-queuelate']) make(b, old);
  make('board/pin-fresh', new Date().toISOString());
  make('board/other-old', old);
  git(['clone', '-q', '--mirror', source, path.join(vt, 'repo-mirror.git')]);
  write(path.join(vt, 'queue_b', 'job1.bat'), 'git fetch origin board/pin-queued\r\n');
  write(path.join(vt, 'prune', 'keep.txt'), 'board/pin-keep\r\n');
  // a job whose attempt still holds a checkout: its job-name branch and the branch its relay_branch.txt names stay
  write(path.join(vt, 'opusbusy', 'out_1', 'checkouts.txt'), 'new ' + 'a'.repeat(40) + '\r\n');
  write(path.join(vt, 'opusbusy', 'out_1', 'new', 'x.txt'), 'checkout');
  write(path.join(vt, 'opusbusy', 'out_1', 'relay_branch.txt'), 'board/pc-out-named out_1\r\n');
  const before = branches();
  let r = run();
  assert.equal(r.status, 0, r.out);
  assert(/would delete 4 branch\(es\)/.test(r.out) && /Nothing was deleted/.test(r.out), 'dry run counts: ' + r.out);
  assert.deepEqual(branches(), before, 'a dry run deletes nothing');
  const list = fs.readdirSync(path.join(vt, 'prune')).filter(f => /^prune_list_/.test(f));
  assert.equal(list.length, 1);
  const rows = fs.readFileSync(path.join(vt, 'prune', list[0]), 'utf8').trim().split(/\r?\n/).map(l => l.split(' ')[0]).sort();
  assert.deepEqual(rows, ['board/pc-out-queuelate', 'board/pc-out-stale', 'board/pin-keeplate', 'board/pin-stale'], 'only the stale ones are listed: ' + rows);
  const log = fs.readFileSync(path.join(vt, 'prune', fs.readdirSync(path.join(vt, 'prune')).find(f => /^prune_dry_/.test(f))), 'utf8');
  for (const [b, why] of [['board/pin-queued', 'named by queued job'], ['board/pin-keep', 'in keep.txt'], ['board/pin-pr', 'open pull request'], ['board/pin-fresh', 'newer than 3 days'], ['board/pc-out-opusbusy', 'still holds a checkout'], ['board/pc-out-named', 'still holds a checkout']]) {
    assert(new RegExp(`keep ${b} \\(.*${why}`).test(log), `${b} kept (${why}): ` + log);
  }
  assert(!/other-old/.test(log), 'other branches are never considered');
  assert.notEqual(run('now').status, 0, 'only live is a mode');
  // the stale pin moves after the dry run: live keeps it; the other goes
  write(path.join(work, 'moved.txt'), 'moved'); git(['add', '-A'], work);
  git(['-c', 'user.name=t', '-c', 'user.email=t@example.invalid', 'commit', '-qm', 'moved'], work);
  git(['push', '-q', '-f', source, 'HEAD:refs/heads/board/pin-stale'], work);
  // Artoo on PR 1672: a keep.txt line or a queued job added after the dry run keeps an unmoved listed branch
  fs.appendFileSync(path.join(vt, 'prune', 'keep.txt'), 'board/pin-keeplate\r\n');
  write(path.join(vt, 'queue_c', 'job2.bat'), 'git fetch origin board/pc-out-queuelate\r\n');
  r = run('live');
  assert.equal(r.status, 0, r.out);
  assert(/deleted 1 branch\(es\), kept 3/.test(r.out) && /kept \(moved or already gone since the dry run\): board\/pin-stale/.test(r.out), 'live: ' + r.out);
  assert(/kept \(now protected: in keep\.txt\): board\/pin-keeplate/.test(r.out) && /kept \(now protected: named by queued job queue_c.*\): board\/pc-out-queuelate/.test(r.out), 'live rechecks every keep rule: ' + r.out);
  const after = branches();
  assert(!after.includes('board/pc-out-stale') && after.includes('board/pin-stale') && after.includes('board/pin-keep') && after.includes('board/pin-keeplate') && after.includes('board/pc-out-queuelate') && after.includes('board/pc-out-opusbusy') && after.includes('main'), 'after: ' + after);
  assert(fs.existsSync(path.join(vt, 'opusbusy', 'out_1', 'new', 'x.txt')), 'nothing on the PC is touched');
  console.log('PASS: prune_relay_branches lists only stale relay and pin branches, a dry run deletes nothing, live deletes only unmoved listed branches that still pass every keep rule');
} finally { fs.rmSync(tmp, { recursive: true, force: true }); }
