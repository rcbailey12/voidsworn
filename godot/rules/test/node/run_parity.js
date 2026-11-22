// PC/Linux twins share coverage and diagnostics. Browser battles keep separate processes for timing.
'use strict';
const fs = require('fs'), os = require('os'), path = require('path');
const { spawn } = require('child_process');
const T = path.resolve(__dirname, '..'), P = path.resolve(T, '../..');
const S = JSON.parse(fs.readFileSync(path.join(T, 'scenarios.json'), 'utf8'));
const godot = process.env.GODOT || 'godot', windows = process.platform === 'win32';
let root, failures = 0;
// Issue 1654 (R405, Ryan Nov 22 2026): the browser rules twin is retired; Godot is the only rules source. By default
// this runs Godot alone and the saved Godot results in ../saved are the reference. RULES_TWIN=browser runs the old
// side-by-side comparison against the frozen root JS files, for history only (it fails once Godot moves on).
const TWIN = process.env.RULES_TWIN === 'browser';
function say(line) {
  console.log(line);
  fs.appendFileSync(path.join(root, 'parity_log.txt'), line + '\n');
}
function positive(name, fallback) {
  const value = process.env[name] === undefined ? fallback : Number(process.env[name]);
  if (!Number.isSafeInteger(value) || value < 1) throw new Error(`${name} must be a positive integer`);
  return value;
}
function present(file) { return fs.existsSync(file) && fs.statSync(file).size > 0; }
function read(file) { return fs.existsSync(file) ? fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n') : ''; }
function result(r) { return (r.error || r.signal || String(r.code)) + (r.timeout ? ', timeout' : ''); }
function cleanExit(r) { return r.code === 0 && !r.timeout && !r.error; }
async function waitForAll(tasks) {
  const failed = (await Promise.allSettled(tasks)).find(r => r.status === 'rejected');
  if (failed) throw failed.reason;
}
function paused() {
  if (!windows || !process.env.USERPROFILE) return false;
  const file = path.join(process.env.USERPROFILE, 'Downloads', 'voidsworn_test', 'gpu_go.txt');
  try {
    return /^GPU not cleared: paused by the Board\b/i.test(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''));
  } catch (e) {
    if (e.code === 'ENOENT') return false;
    throw e;
  }
}
async function withRunRoot(check) {
  const chosen = process.env.PARITY_RUN_ROOT;
  const temp = path.resolve(process.env.RUNNER_TEMP || os.tmpdir());
  const dir = chosen ? path.resolve(chosen) : fs.mkdtempSync(path.join(temp, 'voidsworn-parity-'));
  // Keep caller-selected output and GitHub's parity evidence available for inspection.
  const owned = !chosen && process.env.GITHUB_ACTIONS !== 'true';
  const created = owned ? fs.lstatSync(dir) : null;
  let code = 1;
  try {
    fs.mkdirSync(dir, { recursive: true });
    if (fs.readdirSync(dir).length) throw new Error(`PARITY_RUN_ROOT must be empty: ${dir}`);
    code = await check(dir);
  } finally {
    if (owned) {
      try {
        if (paused()) console.log(`Parity scratch kept during the PC pause: ${dir}`);
        else {
          const current = fs.lstatSync(dir, { throwIfNoEntry: false });
          if (current) {
            if (!current.isDirectory() || current.dev !== created.dev || current.ino !== created.ino) throw new Error('directory was replaced');
            fs.rmSync(dir, { recursive: true, force: true, maxRetries: 3, retryDelay: 100 });
            console.log(`Parity scratch removed: ${dir}`);
          }
        }
      } catch (e) {
        console.error(`FAIL: could not clean up parity scratch at ${dir}: ${e.message}`);
        code = 1;
      }
    }
  }
  return code;
}
function isolated(dir) {
  fs.mkdirSync(dir, { recursive: true });
  // Windows Godot uses APPDATA rather than XDG_DATA_HOME. Isolate both, including the engine log.
  return { ...process.env, XDG_DATA_HOME: dir, APPDATA: dir };
}
function execute(exe, args, log, env = process.env, seconds = 300, start = false) {
  return new Promise(resolve => {
    const fd = fs.openSync(log, 'w');
    let child, timeout = false, error;
    try {
      if (windows && start) {
        // start /b launches Godot separately; /wait keeps its exit code and lifetime attached to the worker.
        const quote = s => {
          if (/["\r\n%]/.test(s)) throw new Error('unsupported character in Windows worker path');
          return `"${s}"`;
        };
        const script = log + '.cmd';
        fs.writeFileSync(script, '@echo off\r\nstart "" /b /wait ' + [exe, ...args].map(quote).join(' ') + '\r\nexit /b %errorlevel%\r\n');
        child = spawn(process.env.ComSpec || 'cmd.exe', ['/d', '/s', '/c', `call "${script}"`], { env, windowsHide: true, windowsVerbatimArguments: true, stdio: ['ignore', fd, fd] });
      } else child = spawn(exe, args, { env, windowsHide: true, stdio: ['ignore', fd, fd] });
    } catch (e) {
      fs.closeSync(fd); resolve({ code: null, error: e.message }); return;
    }
    const timer = setTimeout(() => {
      timeout = true;
      if (windows) {
        // Stop only this owned worker and its child, then wait for close before inspecting records.
        const killer = spawn('taskkill.exe', ['/pid', String(child.pid), '/t', '/f'], { windowsHide: true, stdio: ['ignore', fd, fd] });
        // If Windows refuses termination, retain the wait handle. Killing only cmd would orphan Godot
        // and let it write records while comparisons or diagnostic reruns are already in progress.
        killer.on('error', e => { error = 'watchdog could not stop worker tree: ' + e.message; });
        killer.on('close', code => { if (code !== 0) error = 'watchdog could not stop worker tree, taskkill exit ' + code; });
      } else child.kill('SIGKILL');
    }, seconds * 1000);
    child.on('error', e => { error = e.message; });
    child.on('close', (code, signal) => {
      clearTimeout(timer); fs.closeSync(fd); resolve({ code, signal, timeout, error });
    });
  });
}
function gd(args, log, env, seconds = 300, start = false) {
  return execute(godot, ['--headless', '--path', P, '--script', 'res://rules/test/parity_main.gd', '--', ...args], log, env, seconds, start);
}
function js(file, args, log) { return execute(process.execPath, [path.join(__dirname, file), ...args], log); }
function checked(label, ok, details = '') {
  say(`  ${label}: ${ok ? 'PASS' : 'FAIL'}${details ? ' (' + details + ')' : ''}`);
  if (!ok) failures++;
}
async function compare(mode, a, b, log) {
  if (!present(a) || !present(b)) {
    fs.writeFileSync(log, `missing or empty record file: ${!present(a) ? a : b}\n`); return false;
  }
  return cleanExit(await js('compare.js', [mode, a, b], log));
}
async function verifyBattles(manifest) {
  const retryDir = path.join(root, 'retries');
  fs.mkdirSync(retryDir, { recursive: true });
  for (const w of manifest.workers) {
    if (!cleanExit(w.godot) || !read(w.log).split('\n').includes(`batch ${w.names.length} battles -> ${path.join(root, 'out')}`)) {
      checked(`worker ${w.id}`, false, `batch exit ${result(w.godot)}; see ${w.log}`);
    }
  }
  for (const name of manifest.names) {
    const w = manifest.workers.find(w => w.names.includes(name));
    const a = path.join(root, 'golden', name + '.jsonl'), b = path.join(root, 'out', name + '.jsonl');
    const cmp = path.join(root, 'out', 'cmp_' + name + '.txt');
    const log = read(w.log), code = log.match(new RegExp(`^batch result ${name} exit ([0-9]+)$`, 'm'));
    const section = log.split(`batch start ${name}\n`)[1]?.split(/^batch (?:start|result) /m)[0] || '';
    if (!present(b) || !code) {
      // Diagnostics never repair the batch result or overwrite its records.
      const retry = path.join(retryDir, name + '.jsonl'), retryLog = path.join(retryDir, name + '.log');
      const r = await gd(['scenario', name, retry, '-1', w.file], retryLog, isolated(path.join(retryDir, 'user_' + name)), manifest.retrySeconds);
      const alone = cleanExit(r) && (TWIN ? present(a) && await compare('scenario', a, retry, cmp) : present(retry));
      checked(`battle ${name}`, false, `never ran in its batch; ${alone ? 'passes alone' : 'fails alone too'}, exit ${result(r)}`);
      if (!alone) say(read(cmp).trim() || read(retryLog).trim());
      continue;
    }
    const same = TWIN ? await compare('scenario', a, b, cmp) : true;
    const ok = same && code[1] === '0' && (!TWIN || cleanExit(w.browser[name])) && !/SCRIPT ERROR|NOT PORTED:/.test(section);
    checked(`battle ${name}`, ok, ok ? (TWIN ? read(cmp).split('\n')[0] : 'Godot ran it cleanly') : `batch exit ${code[1]}${TWIN ? ', browser exit ' + result(w.browser[name]) : ''}`);
    if (!ok) {
      say(read(cmp).trim());
      const errors = section.split('\n').filter(l => /SCRIPT ERROR|NOT PORTED:/.test(l));
      if (errors.length) say(errors.join('\n'));
    }
  }
}
async function run(names = process.argv.slice(2)) {
  if (process.versions.node.split('.')[0] !== '22') throw new Error('Node major 22 is required; use voidsworn_test/node/node.exe');
  const count = positive('PARITY_WORKERS', 4), seconds = positive('PARITY_TIMEOUT_SECONDS', 1200);
  const retrySeconds = positive('PARITY_RETRY_SECONDS', 300);
  if (!names.length) names = Object.keys(S);
  if (new Set(names).size !== names.length || names.some(n => !Object.hasOwn(S, n) || !/^[a-zA-Z0-9_]+$/.test(n))) throw new Error('unknown or duplicate battle name');
  return withRunRoot(dir => {
    root = dir;
    failures = 0;
    return runChecks(names, count, seconds, retrySeconds);
  });
}
async function runChecks(names, count, seconds, retrySeconds) {
  for (const dir of ['golden', 'out', 'workers']) fs.mkdirSync(path.join(root, dir));
  const env = isolated(path.join(root, 'user')), started = Date.now();
  say(`Voidsworn rules ${TWIN ? 'parity against the frozen browser files' : 'check (Godot only, against the saved results)'}: ${names.length} battles, ${Math.min(count, names.length)} workers`);
  say(`Started (UTC): ${new Date(started).toISOString()}; Node ${process.version}; Godot ${godot}`);
  say(`Records and log: ${root}`);
  if (TWIN) {
    say('[1/5] Exporting the game data tables for Godot...');
    checked('data export', cleanExit(await js('export_data.js', [path.join(P, 'rules/data/tables.json')], path.join(root, 'export.log'))));
  } else say('[1/5] Tables: godot/rules/data/tables.json is the source (no export from the browser files)');
  say('[2/5] Random numbers: first 10,000 draws from 3 seeds...');
  for (const seed of ['1001', '7', '4242424242']) {
    const a = path.join(root, 'golden', `prng_${seed}.txt`), b = path.join(root, 'out', `prng_${seed}.txt`), log = b + '.compare.txt';
    const g = await gd(['prng', seed, '10000', b], b + '.log', env);
    if (!TWIN) { checked(`seed ${seed}`, cleanExit(g) && present(b)); continue; }
    const n = await js('golden.js', ['prng', seed, '10000', a], a + '.log');
    const same = await compare('same', a, b, log);
    checked(`seed ${seed}`, cleanExit(n) && cleanExit(g) && same);
    if (!same) say(read(log).trim());
  }
  say('[3/5] Math functions on all 316,090 inputs...');
  const math = path.join(root, 'golden/math.txt'), mathLog = path.join(root, 'out/math.txt');
  // Godot only: the reviewed math inputs and expected values come from the saved results (frozen at retirement).
  if (!TWIN) { const R = require('../saved/records'); fs.writeFileSync(math, R.unpack(R.HOME, R.manifest().files['math.txt'])); }
  const mn = TWIN ? await js('golden.js', ['math', math], math + '.log') : { code: 0 }, mg = await gd(['math', math], mathLog, env);
  checked('math', cleanExit(mn) && cleanExit(mg), read(mathLog).split('\n').find(l => l.startsWith('math ')) || 'see out/math.txt');
  say('[4/5] Seeded battles, every action compared (state hash, PRNG state)...');
  const manifest = { names, retrySeconds, workers: [] };
  for (let id = 0; id < Math.min(count, names.length); id++) {
    const list = names.filter((_, i) => i % Math.min(count, names.length) === id);
    const file = path.join(root, 'workers', `part${id}.json`), log = path.join(root, 'workers', `godot${id}.log`);
    fs.writeFileSync(file, JSON.stringify(Object.fromEntries(list.map(n => [n, S[n]]))));
    manifest.workers.push({ id, names: list, file, log, browser: {} });
  }
  await waitForAll(manifest.workers.map(async w => {
    const browser = async () => {
      if (!TWIN) return;
      for (const name of w.names) w.browser[name] = await js('golden.js', ['scenario', name, path.join(root, 'golden', name + '.jsonl')], path.join(root, 'workers', `browser_${name}.log`));
    };
    const env = isolated(path.join(root, 'workers', `user${w.id}`));
    await waitForAll([browser(), gd(['batch', w.file, path.join(root, 'out')], w.log, env, seconds, true).then(r => { w.godot = r; })]);
    say(`  worker ${w.id}: batch ended (${w.names.length} assigned battles; Godot exit ${result(w.godot)})`);
  }));
  fs.writeFileSync(path.join(root, 'batches.json'), JSON.stringify(manifest, null, 2));
  await verifyBattles(manifest);
  say('[4b] Threat overlay, rounds 1 to 3...');
  for (const name of ['s4', 's19', 's23']) {
    const a = path.join(root, 'golden', `threat_${name}.json`), b = path.join(root, 'out', `threat_${name}.json`);
    const g = await gd(['threat', name, b], b + '.log', env);
    if (!TWIN) { checked(`threat map ${name}`, cleanExit(g) && present(b)); continue; }
    const n = await js('golden.js', ['threat', name, a], a + '.log');
    checked(`threat map ${name}`, cleanExit(n) && cleanExit(g) && present(a) && present(b) && fs.readFileSync(a).equals(fs.readFileSync(b)));
  }
  say('[4c] Threads and the hard stop (s4, s23)...');
  const threadLog = path.join(root, 'out/thread.txt');
  const thread = await execute(godot, ['--headless', '--path', P, '--script', 'res://rules/test/thread_test.gd', '--', 's4', 's23'], threadLog, env);
  checked('threads', cleanExit(thread));
  say(read(threadLog).split('\n').filter(l => /^(thread test|hard stop|  halted)/.test(l)).join('\n'));
  say('[5/5] Enemy think time (report only; game bar: worst under about 0.5 s)...');
  for (const name of TWIN ? names.filter(n => S[n].timing) : []) {
    const a = path.join(root, 'golden', name + '.jsonl.timing.json'), b = path.join(root, 'out', name + '.jsonl.timing.json');
    if (!present(a) || !present(b)) { checked(`timing records ${name}`, false, 'missing file'); continue; }
    const log = path.join(root, 'out', 'timing_' + name + '.txt'), r = await js('timing.js', [name, a, b], log);
    say(read(log).trim());
    if (!cleanExit(r)) checked(`timing report ${name}`, false);
  }
  // Path D step 3: use these very same Godot records. This never replaces a parity comparison.
  const parityFailures = failures;
  say('[saved] Checking Godot results against the reviewed results in the repo...');
  const saved = require('../saved/check').check(root, { names, print: say });
  failures += saved.failures;
  const elapsed = (Date.now() - started) / 1000;
  say(`Whole rules parity step: ${elapsed.toFixed(3)} s`);
  fs.writeFileSync(path.join(root, 'summary.json'), JSON.stringify({ battles: names.length, workers: manifest.workers.length, failures, parity_failures: parityFailures, saved_failures: saved.failures, saved_seconds: saved.seconds, started_at: new Date(started).toISOString(), completed_at: new Date().toISOString(), seconds: elapsed }, null, 2));
  if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, `\nWhole rules parity and saved-results step: ${elapsed.toFixed(3)} s (saved comparison: ${saved.seconds.toFixed(3)} s).\n`);
  say(failures ? `FAIL: ${failures} check(s) differ.` : TWIN ? "PASS: the Godot port matches the frozen browser rules exactly." : 'PASS: every Godot battle matches the reviewed saved results.');
  return failures ? 1 : 0;
}
// Recheck saved batch evidence using the same comparison and missing-file diagnostics.
async function verify(savedRoot) {
  root = path.resolve(savedRoot); failures = 0;
  await verifyBattles(JSON.parse(read(path.join(root, 'batches.json'))));
  return failures ? 1 : 0;
}
module.exports = { run, verify, execute, isolated, withRunRoot };
if (require.main === module) run().then(c => { process.exitCode = c; }).catch(e => { console.error('FAIL: ' + e.stack); process.exitCode = 1; });
