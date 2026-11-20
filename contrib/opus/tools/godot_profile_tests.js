'use strict';
// Issue 1194: test this checkout's tmo.bat, never the PC's installed tools_live copy.
process.env.TMO_OWN_COPY = '1';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

if (process.platform !== 'win32') {
  console.log('SKIP: Godot profile launch test needs the Windows watchdog');
  process.exit(0);
}

const repo = path.resolve(__dirname, '../../..');
const pc = path.join(repo, 'tools/pc');
const home = fs.mkdtempSync(path.join(os.tmpdir(), 'profile 1228 '));
const scratch = path.join(home, 'voidsworn-run-' + 'a'.repeat(32));
const owner = '.voidsworn-run-owner';
const godot = path.join(home, 'Godot-fake.exe');
const script = path.join(home, 'print-profile.js');
const callerAppData = path.join(home, 'caller appdata');
const callerLocalAppData = path.join(home, 'caller local appdata');
const env = {
  ...process.env,
  APPDATA: callerAppData, LOCALAPPDATA: callerLocalAppData,
  TEMP: home, TMP: home, PC_RUN_SCRATCH: scratch, PC_REAL_PROFILE: '',
  TMO_REPO: '', TMO_OUT: '', TMO_LOG: '', TMO_ERR_LOG: '',
  PC_GPU_MODE: '', PC_RUNNER_TEST: '1', PC_TEST_TIMEOUT_LOG: path.join(home, 'timeouts.log'),
  PC_GODOT_EXPORT_TEMPLATES: '',
};

function launch(entry, overrides = {}, extra = '') {
  const command = `30 "${godot}" "${script}" --headless ${extra}`;
  const batch = entry === 'batch';
  const result = spawnSync(batch ? 'cmd.exe' : 'powershell.exe', batch
    ? ['/d', '/s', '/c', `call "${path.join(pc, 'tmo.bat')}" ${command}`]
    : ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, 'run_timeout.ps1')], {
    cwd: home, windowsVerbatimArguments: batch, windowsHide: true,
    env: { ...env, ...overrides, TMO_ARGS: command },
    encoding: 'utf8', timeout: 40000,
  });
  assert.ifError(result.error);
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  const appData = /^APPDATA=(.*)$/m.exec(output)?.[1];
  const localAppData = /^LOCALAPPDATA=(.*)$/m.exec(output)?.[1];
  assert.ok(appData && localAppData, output);
  return { appData, localAppData, output };
}

function checkIsolated(result, kept = false) {
  const { appData, localAppData, output } = result;
  assert.notEqual(appData, callerAppData);
  assert.notEqual(localAppData, callerLocalAppData);
  assert.equal(localAppData, appData);
  assert.ok(output.includes('Godot profile: ' + appData), output);
  // Issue 1180: the throwaway profile goes when its process ends, unless the job asked to keep it.
  if (kept) assert.ok(fs.statSync(appData).isDirectory(), appData);
  else {
    assert.ok(!fs.existsSync(appData), `profile left behind: ${appData}`);
    assert.ok(output.includes('Godot profile removed: ' + appData), output);
  }
}

try {
  fs.mkdirSync(scratch);
  fs.writeFileSync(path.join(scratch, owner), 'b'.repeat(32));
  fs.copyFileSync(process.execPath, godot);
  // The fake Godot leaves a cache file and a junction to a folder outside the profile: removal must not follow it.
  const outside = path.join(home, 'outside shared');
  fs.mkdirSync(outside);
  fs.writeFileSync(path.join(outside, 'keep.txt'), 'never removed');
  fs.writeFileSync(script, `
const fs = require('fs'), path = require('path');
fs.mkdirSync(path.join(process.env.APPDATA, 'Godot', 'shader_cache'), { recursive: true });
fs.writeFileSync(path.join(process.env.APPDATA, 'Godot', 'shader_cache', 'x.cache'), 'cache');
fs.symlinkSync(${JSON.stringify(outside)}, path.join(process.env.APPDATA, 'link-out'), 'junction');
console.log('APPDATA=' + process.env.APPDATA);
console.log('LOCALAPPDATA=' + process.env.LOCALAPPDATA);
`);

  const batch = launch('batch');
  const direct = launch('direct', { PC_REAL_PROFILE: 'true' });
  const watch = launch('direct', { TMO_REPO: repo, TMO_OUT: home, TMO_LOG: path.join(home, 'watch.log') });
  for (const result of [batch, direct, watch]) {
    checkIsolated(result);
    assert.equal(path.dirname(result.appData), scratch);
  }
  assert.equal(new Set([batch.appData, direct.appData, watch.appData]).size, 3);
  assert.equal(fs.readFileSync(path.join(scratch, owner), 'utf8'), 'b'.repeat(32));

  assert.equal(fs.readFileSync(path.join(outside, 'keep.txt'), 'utf8'), 'never removed', 'a junction in the profile is never followed');

  const standalone = launch('batch', { PC_RUN_SCRATCH: '' });
  checkIsolated(standalone);
  const standaloneScratch = path.dirname(standalone.appData);
  assert.equal(path.dirname(standaloneScratch), home);
  assert.match(path.basename(standaloneScratch), /^voidsworn-run-[a-f0-9]{32}$/);
  assert.ok(!fs.existsSync(standaloneScratch), 'the voidsworn-run folder this launch made is removed with its profile');

  const keptLaunch = launch('batch', { PC_RUN_SCRATCH: '', PC_KEEP_GODOT_PROFILE: '1' });
  checkIsolated(keptLaunch, true);
  assert.match(fs.readFileSync(path.join(path.dirname(keptLaunch.appData), owner), 'utf8'), /^[a-f0-9]{32}$/);

  // The Board's PC pause removes nothing (Artoo on PR 1280): the profile is kept for a later janitor pass.
  const pauseFile = path.join(home, 'gpu_go.txt');
  fs.writeFileSync(pauseFile, 'GPU not cleared: paused by the Board at 12:30\n');
  const pausedLaunch = launch('batch', { PC_RUN_SCRATCH: '', PC_CLEANUP_PAUSE_FILE: pauseFile });
  checkIsolated(pausedLaunch, true);
  assert.ok(pausedLaunch.output.includes('Godot profile kept for the janitor') && pausedLaunch.output.includes('PC pause is active'), pausedLaunch.output);

  const inherited = launch('batch', { PC_REAL_PROFILE: '1' });
  assert.equal(inherited.appData, callerAppData);
  assert.equal(inherited.localAppData, callerLocalAppData);

  const templates = path.join(home, 'templates', '4.7.2.stable');
  const names = ['windows_release_x86_64.exe', 'windows_release_x86_64_console.exe'];
  fs.mkdirSync(templates, { recursive: true });
  for (const name of names) fs.writeFileSync(path.join(templates, name), name);
  const exported = launch('batch', { PC_GODOT_EXPORT_TEMPLATES: templates, PC_KEEP_GODOT_PROFILE: '1' }, '--export-release "Windows Desktop" out.exe');
  checkIsolated(exported, true);
  for (const name of names) {
    assert.equal(fs.readFileSync(path.join(exported.appData, 'Godot', 'export_templates', path.basename(templates), name), 'utf8'), name);
  }
  console.log('PASS: fresh owned profiles for wrapped Godot starts, removed when the process ends (links never followed, keep on request), explicit opt-in, and staged export templates');
} finally {
  fs.rmSync(home, { recursive: true, force: true });
}
