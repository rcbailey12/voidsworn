'use strict';
// Issue 934. Private Serve only. No login, install, Funnel, or global reset.
const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const { spawn, spawnSync } = require('child_process');
const tailscale = require('./tailscale');
const readline = require('readline');
const TARGET = 'http://127.0.0.1:8918';
const FLAGS = ['--bg', '--https=443'];

function command(executable, args, interactive = false) {
  const result = spawnSync(executable, args, interactive ? { stdio: 'inherit', windowsHide: true } :
    { encoding: 'utf8', windowsHide: true, timeout: 10000, maxBuffer: 4 * 1024 * 1024 });
  if (result.error || result.status !== 0) throw Error('Tailscale could not complete that step. Check that it is connected, then try again.');
  return result.stdout;
}

function configuration(text, host) {
  let config;
  try { config = JSON.parse(text); } catch (_) { throw Error('Could not read the current Serve settings. Nothing was changed.'); }
  if (!config || typeof config !== 'object' || Array.isArray(config)) throw Error('Could not read the current Serve settings. Nothing was changed.');
  if (Object.values(config.AllowFunnel || {}).some(Boolean)) {
    throw Error('Public Funnel is already enabled. Turn it off in Tailscale before using these private phone files. Nothing was changed.');
  }
  const web = config.Web?.[`${host}:443`];
  const tcp = config.TCP?.['443'];
  const otherWeb = Object.keys(config.Web || {}).some(key => key.endsWith(':443') && key !== `${host}:443`);
  const handlers = web?.Handlers;
  const ours = tcp?.HTTPS === true && !tcp.TCPForward && !tcp.TerminateTLS &&
    handlers && Object.keys(handlers).length === 1 && handlers['/']?.Proxy === TARGET &&
    Object.keys(handlers['/']).length === 1;
  if (otherWeb || ((tcp || web) && !ours)) {
    throw Error('Another service is using the private HTTPS address. Nothing was changed. Ask the Board to check it.');
  }
  return Boolean(ours);
}

function probe(headers = {}, target = TARGET) {
  return new Promise((resolve, reject) => {
    const req = http.get(target + '/status.json', { headers, timeout: 1500 }, res => {
      let text = '';
      res.on('data', chunk => { text += chunk; if (text.length > 16 * 1024 * 1024) req.destroy(Error('Page reply was too large.')); });
      res.on('end', () => {
        if (res.statusCode !== 200) { reject(Error('Mission control refused the request.')); return; }
        try {
          const data = JSON.parse(text);
          if (![1,2].includes(data.schemaVersion) || !Array.isArray(data.lanes) || data.lanes.length !== 5) throw Error();
          resolve(data);
        } catch (_) { reject(Error('Port 8918 is being used by another page.')); }
      });
      res.on('error', reject);
    });
    req.on('timeout', () => req.destroy(Error('Mission control did not reply.')));
    req.on('error', reject);
  });
}

function startPublisher() {
  const log = path.join(os.tmpdir(), `voidsworn-mission-phone-${Date.now()}.log`);
  const fd = fs.openSync(log, 'a');
  let child;
  try {
    child = spawn(process.execPath, [path.join(__dirname, 'publisher.js')], {
      detached: true, windowsHide: true, stdio: ['ignore', fd, fd]
    });
  } finally { fs.closeSync(fd); }
  child.unref();
  return new Promise((resolve, reject) => {
    child.once('error', reject);
    child.once('spawn', () => resolve(log));
  });
}

function needsRestart(data, expected) {
  return !data || data.schemaVersion!==2 || !data.build || data.build.stale || data.build.id!==expected;
}
function matchingPublishers(processes, target = path.join(__dirname,'publisher.js')) {
  const normal = p => path.resolve(p).replace(/\\/g,'/').toLowerCase();
  return processes.filter(p => {
    if (!/^node(?:\.exe)?$/i.test(p.Name || '') || !Number.isSafeInteger(p.ProcessId) || p.ProcessId<=0) return false;
    const words=[...String(p.CommandLine || '').matchAll(/"([^"]*)"|(\S+)/g)].map(m=>m[1] ?? m[2]);
    return words.length>=2 && normal(words[1])===normal(target);
  });
}
function localPublishers() {
  const r=spawnSync('powershell.exe',['-NoProfile','-NonInteractive','-Command',
    'Get-CimInstance Win32_Process -Filter "Name=\'node.exe\'" | Select-Object ProcessId,Name,CommandLine | ConvertTo-Json -Compress'],
    {encoding:'utf8',windowsHide:true,timeout:10000,maxBuffer:1024*1024});
  if (r.error || r.status!==0) throw Error('Could not identify this publisher. Nothing was stopped.');
  const parsed=JSON.parse(r.stdout.trim() || '[]');
  return matchingPublishers(Array.isArray(parsed) ? parsed : [parsed]);
}
function stopPublisher() {
  const candidates=localPublishers();
  if (candidates.length!==1) throw Error('Could not identify exactly one publisher in this folder. Nothing was stopped.');
  const pid=candidates[0].ProcessId;
  // Recheck identity before stopping one PID. No child tree and no job process is targeted.
  if (!localPublishers().some(p=>p.ProcessId===pid)) throw Error('Publisher changed. Nothing was stopped.');
  const r=spawnSync('powershell.exe',['-NoProfile','-NonInteractive','-Command','Stop-Process -Id '+pid+' -ErrorAction Stop'],{encoding:'utf8',windowsHide:true,timeout:10000});
  if (r.error || r.status!==0) throw Error('This publisher could not be stopped. No jobs were touched.');
}
function confirmRestart() {
  const rl=readline.createInterface({input:process.stdin,output:process.stdout});
  return new Promise(resolve=>rl.question('Mission Control is running an older version. Restart this publisher now? Y/N: ',answer=>{rl.close();resolve(/^y$/i.test(answer.trim()));}));
}
async function ensurePublisher(host, deps) {
  let data, start = false;
  try { data=await deps.probe(); }
  catch (e) { if (e.code!=='ECONNREFUSED') throw e; start=true; }
  if (!start && needsRestart(data,deps.buildHash())) {
    console.log('The running publisher is older than these files. Jobs are separate.');
    if (!await deps.confirmRestart()) throw Error('The older publisher was kept. Run PHONE_ON again when ready to restart it.');
    await deps.stopPublisher(); start=true;
  }
  if (start) {
    const log=await deps.startPublisher();
    console.log('Mission control started in the background. Log: '+log);
    const deadline=deps.now()+90000;
    let ready=false;
    while (deps.now()<deadline) {
      await deps.delay(250);
      try { data=await deps.probe(); if (!needsRestart(data,deps.buildHash())) { ready=true; break; } } catch (_) { /* Await the local scan and bind. */ }
    }
    if (!ready) throw Error('Mission control did not start. Check its log above.');
  }
  try { await deps.probe({Host:host,'X-Forwarded-Host':host,'X-Forwarded-Proto':'https','X-Forwarded-For':'100.64.0.1'}); }
  catch (_) { throw Error('The running mission control needs a restart for this Tailscale name. Close its window, then double-click PHONE_ON.bat again.'); }
}

async function main(mode, overrides = {}) {
  const deps = { discover: tailscale.discover, command, probe, startPublisher, stopPublisher, confirmRestart,
    buildHash: () => require('./publisher').buildHash(),
    now: Date.now, delay: ms => new Promise(resolve => setTimeout(resolve, ms)), ...overrides };
  if (!['on', 'off'].includes(mode)) throw Error('Use PHONE_ON.bat or PHONE_OFF.bat.');
  const { executable, host } = deps.discover();
  if (!executable) throw Error('Install Tailscale on this PC and the Pixel: https://tailscale.com/download\nSign in with the same account on both devices, then try again.');
  if (!host) throw Error('Open Tailscale on this PC and sign in, then connect. Use the same account on the Pixel.\nTailscale download: https://tailscale.com/download');
  const configured = configuration(deps.command(executable, ['serve', 'status', '--json']), host);
  if (mode === 'off') {
    if (configured) deps.command(executable, ['serve', ...FLAGS, TARGET, 'off'], true);
    const remains = configuration(deps.command(executable, ['serve', 'status', '--json']), host);
    if (remains) throw Error('The phone link is still on. Check Tailscale, then try PHONE_OFF.bat again.');
    console.log('Phone link is off. Mission control on this PC still works. Tailscale stays signed in.');
    return;
  }
  await ensurePublisher(host, deps);
  // Keep Tailscale's first-use HTTPS approval instructions visible in this window.
  deps.command(executable, ['serve', ...FLAGS, TARGET], true);
  if (!configuration(deps.command(executable, ['serve', 'status', '--json']), host)) throw Error('The phone link was not enabled. Check the Tailscale message above.');
  console.log(`\nOn the Pixel, connect Tailscale and open:\nhttps://${host}/\nBookmark that address. PHONE_OFF.bat turns the phone link off.\nPrivate tailnet only. Keep this PC awake. You can close this window.`);
}

module.exports = { main, configuration, ensurePublisher, probe, needsRestart, matchingPublishers, TARGET, FLAGS };
if (require.main === module) main(process.argv[2]).catch(e => { console.error(e.message); process.exitCode = 1; });
