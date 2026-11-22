'use strict';
// Process/file plumbing only. No browser source, exporter or oracle harness runs.
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn } = require('node:child_process');
const { generate } = require('../node/sweep_gen.js');

function options(args) {
  const o = { godot: process.env.GODOT || 'godot', project: path.resolve(__dirname, '../../..'),
    workers: 4, timeout: 600, out: os.tmpdir(), cache: true, numbers: true };
  for (let i = 0; i < args.length; i++) {
    const key = args[i];
    if (key === '--cache-only') o.numbers = false;
    else if (key === '--numbers-only') o.cache = false;
    else if (key === '--sweep') {
      const count = Number(args[++i]), seed = Number(args[++i]);
      if (!Number.isSafeInteger(count) || count < 1 || !Number.isInteger(seed) || seed < 1 || seed > 0xffffffff)
        throw Error('--sweep needs a positive count and a seed from 1 to 4294967295');
      o.sweep = [count, seed];
    } else if (['--godot', '--project', '--scenarios', '--workers', '--timeout', '--out'].includes(key)) {
      if (!args[i + 1] || args[i + 1].startsWith('--')) throw Error('missing value for ' + key);
      o[key.slice(2)] = args[++i];
    } else throw Error('unknown option ' + key);
  }
  for (const k of ['workers', 'timeout']) {
    o[k] = Number(o[k]);
    if (!Number.isSafeInteger(o[k]) || o[k] < 1) throw Error(k + ' must be a positive integer');
  }
  if (!o.cache && !o.numbers) throw Error('choose at least one check');
  if (o.sweep && (!o.cache || o.scenarios)) throw Error('--sweep requires the cache check and replaces --scenarios');
  o.project = path.resolve(o.project);
  fs.mkdirSync(path.resolve(o.out), { recursive: true });
  // Always a fresh directory. Old records can never make a crashed run pass.
  o.out = fs.mkdtempSync(path.join(path.resolve(o.out), 'rules-safety-'));
  o.scenarios = o.sweep ? path.join(o.out, 'sweep.json') :
    path.resolve(o.scenarios || path.join(o.project, 'rules/test/scenarios.json'));
  return o;
}

function runGodot(o, label, script, args, noMemo, timeout = o.timeout) {
  const dir = path.join(o.out, label);
  const userdir = path.join(dir, 'user');
  fs.mkdirSync(userdir, { recursive: true });
  const log = path.join(dir, 'stdout.log');
  const fd = fs.openSync(log, 'w');
  const env = { ...process.env, XDG_DATA_HOME: userdir, XDG_CONFIG_HOME: userdir,
    XDG_CACHE_HOME: userdir, APPDATA: userdir, LOCALAPPDATA: userdir };
  // Override inherited settings in both arms, including a caller's VS_NO_MEMO=1.
  if (noMemo) env.VS_NO_MEMO = '1';
  else delete env.VS_NO_MEMO;
  const start = Date.now();
  return new Promise(resolve => {
    let child;
    try {
      child = spawn(o.godot, ['--headless', '--path', o.project, '--log-file',
        path.join(dir, 'godot.log'), '--script', script, '--', ...args],
      { env, stdio: ['ignore', fd, fd], windowsHide: true });
    } catch (e) {
      fs.closeSync(fd);
      resolve({ ok: false, reason: e.message, seconds: 0, log });
      return;
    }
    fs.closeSync(fd);
    let timedOut = false;
    let error = '';
    const timer = setTimeout(() => {
      timedOut = true;
      // The Windows console executable can launch the actual engine as a child.
      // Stop that whole worker tree, not just the console wrapper.
      if (process.platform === 'win32') {
        const killer = spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], { stdio: 'ignore', windowsHide: true });
        killer.on('error', () => child.kill('SIGKILL'));
      } else child.kill('SIGKILL');
    }, timeout * 1000);
    child.on('error', e => { error = e.message; });
    child.on('close', (code, signal) => {
      clearTimeout(timer);
      const output = fs.readFileSync(log, 'utf8');
      const scriptError = /SCRIPT ERROR|Parse Error|NOT PORTED:|^ERROR:/m.test(output);
      const reason = timedOut ? 'worker timed out after ' + timeout + ' s' :
        error || (code !== 0 ? 'worker exit ' + code + (signal ? ' (' + signal + ')' : '') :
          scriptError ? 'Godot error in worker log' : '');
      resolve({ ok: !reason, reason, seconds: (Date.now() - start) / 1000, log });
    });
  });
}

function readRecord(file) {
  if (!fs.existsSync(file)) throw Error('missing record ' + file);
  const bytes = fs.readFileSync(file);
  const lines = bytes.toString('utf8').trim().split('\n');
  if (!bytes.length) throw Error('empty record ' + file);
  for (const line of lines) {
    const r = JSON.parse(line);
    if (typeof r.actor !== 'string' || typeof r.hash !== 'string' || !Number.isInteger(r.turn))
      throw Error('invalid record ' + file);
  }
  if (!JSON.parse(lines[lines.length - 1]).actor.startsWith('end '))
    throw Error('incomplete record ' + file);
  return bytes;
}

async function cacheCheck(o) {
  if (o.sweep) {
    const tables = JSON.parse(fs.readFileSync(path.join(o.project, 'rules/data/tables.json'), 'utf8')).tables;
    fs.writeFileSync(o.scenarios, JSON.stringify(generate(...o.sweep, tables), null, 1));
  }
  const scenarios = JSON.parse(fs.readFileSync(o.scenarios, 'utf8'));
  if (!scenarios || Array.isArray(scenarios) || typeof scenarios !== 'object')
    throw Error('scenarios must be a nonempty object');
  const names = Object.keys(scenarios);
  if (!names.length) throw Error('no battles in ' + o.scenarios);
  for (const name of names) if (!/^[a-zA-Z0-9_-]+$/.test(name)) throw Error('unsafe battle name ' + name);
  const parts = Array.from({ length: Math.min(o.workers, names.length) }, () => Object.create(null));
  names.forEach((name, i) => { parts[i % parts.length][name] = scenarios[name]; });
  const files = parts.map((part, i) => {
    const file = path.join(o.out, 'part-' + i + '.json');
    fs.writeFileSync(file, JSON.stringify(part));
    return file;
  });
  const arms = {};
  console.log('Cache check: ' + names.length + ' battles, ' + parts.length + ' workers per arm');
  for (const arm of ['on', 'off']) {
    const start = Date.now();
    arms[arm] = await Promise.all(parts.map((part, i) => {
      const label = arm + '/worker-' + i;
      const out = path.join(o.out, label, 'records');
      fs.mkdirSync(out, { recursive: true });
      return runGodot(o, label, 'res://rules/test/parity_main.gd', ['batch', files[i], out], arm === 'off')
        .then(result => {
          // Some Windows console wrappers return 0 even if the engine dies.
          // Records alone cannot prove that a worker reached the end of batch().
          const complete = new RegExp('^batch ' + Object.keys(part).length + ' battles -> ', 'm');
          if (result.ok && !complete.test(fs.readFileSync(result.log, 'utf8'))) {
            result.ok = false;
            result.reason = 'worker did not complete its batch';
          }
          console.log('Cache ' + arm + ' worker ' + (i + 1) + ': ' + (result.ok ? 'finished' : result.reason) +
            ', ' + Object.keys(part).length + ' battles, ' + result.seconds.toFixed(3) + ' s');
          return result;
        });
    }));
    console.log('Cache ' + arm + ': ' + ((Date.now() - start) / 1000).toFixed(3) + ' s');
  }
  let failures = 0;
  parts.forEach((part, i) => {
    for (const name of Object.keys(part)) {
      const reasons = [];
      const records = {};
      for (const arm of ['on', 'off']) {
        const worker = arms[arm][i];
        if (!worker.ok) reasons.push('cache ' + arm + ': ' + worker.reason + '; log ' + worker.log);
        try { records[arm] = readRecord(path.join(o.out, arm, 'worker-' + i, 'records', name + '.jsonl')); }
        catch (e) { reasons.push('cache ' + arm + ': ' + e.message); }
      }
      if (records.on && records.off && !records.on.equals(records.off)) reasons.push('cache on/off records differ');
      if (reasons.length) { failures++; console.error('FAIL: battle ' + name + ': ' + reasons.join('; ')); }
      else console.log('PASS: battle ' + name + ': byte-identical');
    }
  });
  console.log('Cache check: ' + names.length + ' battles, ' + failures + ' failures');
  return { battles: names.length, failures, workers: arms };
}

async function main() {
  const o = options(process.argv.slice(2));
  const start = Date.now();
  const summary = { project: o.project, scenarios: o.scenarios, output: o.out };
  console.log('Rules safety net output: ' + o.out);
  // A failed cache arm never suppresses the independent numbers check.
  if (o.cache) {
    try { summary.cache = await cacheCheck(o); }
    catch (e) { summary.cache = { failures: 1, error: e.message }; console.error('FAIL: cache check: ' + e.message); }
  }
  if (o.numbers) {
    summary.numbers = await runGodot(o, 'numbers', 'res://rules/test/safety/ruled_numbers_test.gd', [], false, 60);
    const output = fs.readFileSync(summary.numbers.log, 'utf8');
    process.stdout.write(output);
    // Catch an early quit(0) or script that never reaches its summary as well.
    if (!/^ruled numbers: [1-9][0-9]* checks, 0 failures\r?$/m.test(output)) {
      summary.numbers.ok = false;
      summary.numbers.reason ||= 'missing successful ruled numbers summary';
    }
    if (!summary.numbers.ok) console.error('FAIL: ruled numbers: ' + summary.numbers.reason);
  }
  summary.seconds = (Date.now() - start) / 1000;
  summary.ok = (!summary.cache || summary.cache.failures === 0) && (!summary.numbers || summary.numbers.ok);
  fs.writeFileSync(path.join(o.out, 'summary.json'), JSON.stringify(summary, null, 2) + '\n');
  console.log((summary.ok ? 'PASS' : 'FAIL') + ': Rules safety net (Godot only), ' + summary.seconds.toFixed(3) + ' s');
  process.exitCode = summary.ok ? 0 : 1;
}

main().catch(e => { console.error('FAIL: rules safety net: ' + e.message); process.exitCode = 1; });
