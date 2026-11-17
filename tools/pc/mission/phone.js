'use strict';
// Issue 934. Private Serve only. No login, install, Funnel, or global reset.
const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const { spawn, spawnSync } = require('child_process');
const tailscale = require('./tailscale');
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

function probe(headers = {}) {
  return new Promise((resolve, reject) => {
    const req = http.get(TARGET + '/status.json', { headers, timeout: 1500 }, res => {
      let text = '';
      res.on('data', chunk => { text += chunk; if (text.length > 1024 * 1024) req.destroy(Error('Page reply was too large.')); });
      res.on('end', () => {
        if (res.statusCode !== 200) { reject(Error('Mission control refused the request.')); return; }
        try {
          const data = JSON.parse(text);
          if (data.schemaVersion !== 1 || !Array.isArray(data.lanes) || data.lanes.length !== 5) throw Error();
          resolve();
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

async function ensurePublisher(host, deps) {
  try { await deps.probe(); }
  catch (e) {
    // Do not start a second publisher over an occupied or unrecognized port.
    if (e.code !== 'ECONNREFUSED') throw e;
    const log = await deps.startPublisher();
    console.log('Mission control started in the background. Log: ' + log);
    let ready = false;
    for (let attempt = 0; attempt < 40; attempt++) {
      await deps.delay(250);
      try { await deps.probe(); ready = true; break; } catch (_) { /* Wait for the local scan and bind. */ }
    }
    if (!ready) throw Error('Mission control did not start. Check its log above.');
  }
  try {
    await deps.probe({ Host: host, 'X-Forwarded-Host': host, 'X-Forwarded-Proto': 'https', 'X-Forwarded-For': '100.64.0.1' });
  } catch (_) {
    throw Error('The running mission control needs a restart for this Tailscale name. Close its window, then double-click PHONE_ON.bat again.');
  }
}

async function main(mode, overrides = {}) {
  const deps = { discover: tailscale.discover, command, probe, startPublisher,
    delay: ms => new Promise(resolve => setTimeout(resolve, ms)), ...overrides };
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

module.exports = { main, configuration, ensurePublisher, probe, TARGET, FLAGS };
if (require.main === module) main(process.argv[2]).catch(e => { console.error(e.message); process.exitCode = 1; });
