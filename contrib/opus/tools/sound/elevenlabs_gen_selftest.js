// Offline selftest for elevenlabs_gen.js: a fake API on loopback, no real key or network.
// Covers Artoo's PR 1577 findings: live base locked, mock never sends the real key, redirects refused, stems resume
// separately, PASS needs files and manifest rows, a 5xx is not retried, the stop reads the account's used credits.
'use strict';
const http = require('http'), fs = require('fs'), os = require('os'), path = require('path'), { spawn } = require('child_process');
const MOCK_KEY = 'mock_key_123', REAL = 'real_key_must_not_leave';
const calls = [];
let used = 0, failStems = false, fail500 = false, truncate = false;
const srv = http.createServer((q, r) => {
  q.on('data', () => {}); q.on('end', () => {
    const route = q.url.split('?')[0];
    calls.push({ route, key: q.headers['xi-api-key'], query: q.url.split('?')[1] || '' });
    if (route === '/v1/redirect') { r.writeHead(302, { location: 'http://127.0.0.1:1/' }); return r.end(); }
    if (q.headers['xi-api-key'] !== MOCK_KEY) { r.writeHead(401); return r.end('bad key'); }
    if (route === '/v1/user/subscription') { r.writeHead(200, { 'content-type': 'application/json' }); return r.end(JSON.stringify({ tier: 'MOCK-not-a-real-account', character_count: used, character_limit: 999999 })); }
    if (route === '/v1/music/stem-separation' && failStems) { r.writeHead(400); return r.end('stems refused'); }
    if (fail500) { r.writeHead(500); return r.end('boom'); }
    if (truncate) { used += 200; r.writeHead(200, { 'request-id': 'trunc', 'character-cost': '40', 'content-length': '5000' }); r.write(Buffer.alloc(10)); return setTimeout(() => r.socket.destroy(), 20); }
    used += route === '/v1/sound-generation' ? 200 : route === '/v1/music' ? 900 : 300;
    r.writeHead(200, { 'request-id': 'req' + calls.length, 'character-cost': '40' }); r.end(Buffer.alloc(64, calls.length % 250));
  });
});
srv.listen(0, '127.0.0.1', async () => {
  const base = 'http://127.0.0.1:' + srv.address().port;
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'elgen-'));
  const list = path.join(dir, 'list.json');
  fs.writeFileSync(list, JSON.stringify({ gate: 3, items: [
    { id: 'a', kind: 'sfx', seconds: 1, takes: 2, prompt: 'click' },
    { id: 'm', kind: 'music', seconds: 60, takes: 1, stems: true, prompt: 'song' } ] }));
  const out = path.join(dir, 'out');
  const gen = path.join(__dirname, 'elevenlabs_gen.js');
  // Offline guard (PILOT4, Nov 22): every generator this test starts is preloaded with a guard that refuses any fetch,
  // socket or DNS lookup that is not loopback, so the test cannot reach ElevenLabs even if the code under test tried.
  const guard = path.join(dir, 'offline_guard.js');
  fs.writeFileSync(guard, `'use strict';
const net = require('net'), tls = require('tls'), dns = require('dns');
const ok = h => h === undefined || h === null || h === '' || h === '127.0.0.1' || h === 'localhost' || h === '::1';
const block = h => { process.stdout.write('OFFLINE GUARD BLOCKED ' + h + '\\n'); process.exitCode = 9; return new Error('offline guard blocked ' + h); };
const f = globalThis.fetch;
globalThis.fetch = (u, o) => { const h = new URL(typeof u === 'string' ? u : u.url || String(u)).hostname.replace(/^\\[|\\]$/g, ''); return ok(h) ? f(u, o) : Promise.reject(block(h)); };
for (const m of [net, tls]) { const c = m.connect; m.connect = m.createConnection = function (...a) { const o = a[0]; const h = typeof o === 'object' ? o.host : (typeof a[1] === 'string' ? a[1] : undefined); if (!ok(h)) throw block(h); return c.apply(this, a); }; }
const l = dns.lookup; dns.lookup = function (h, ...a) { if (!ok(h)) throw block(h); return l.call(this, h, ...a); };
`);
  let guardHits = 0, liveCalls = 0;
  const run = (extra, env) => new Promise(res => {
    const c = spawn(process.execPath, ['-r', guard, gen, '--list', list, '--out', out, ...extra],
      { env: Object.assign({}, process.env, { VOIDSWORN_ELEVENLABS_API_KEY: REAL }, env) });
    let o = ''; c.stdout.on('data', d => o += d); c.stderr.on('data', d => o += d); c.on('close', code => {
      if (/OFFLINE GUARD BLOCKED/.test(o)) guardHits++;
      if (env && env.ELEVENLABS_MOCK === '1' && /account: /.test(o) && !/MOCK MODE: offline test server http:\/\/127\.0\.0\.1:/.test(o)) liveCalls++;
      res({ out: o, code });
    });
  });
  const mock = { ELEVENLABS_MOCK: '1', ELEVENLABS_MOCK_KEY: MOCK_KEY };
  const fails = [];
  const ck = (c, m) => { if (!c) fails.push(m); };
  const count = r => calls.filter(c => c.route === r).length;

  let r = await run(['--base', base, '--dry']);
  ck(/live runs only talk to https:\/\/api\.elevenlabs\.io/.test(r.out) && r.code === 2, 'live mode refuses a custom base');
  r = await run(['--base', 'http://example.com:80', '--dry'], mock);
  ck(/mock mode needs a loopback/.test(r.out), 'mock refuses a non-loopback base');

  failStems = true;
  r = await run(['--base', base], mock);
  ck(r.code === 1 && /INCOMPLETE/.test(r.out) && /not done: m_t1_stems\.zip/.test(r.out), 'failed stems is not a PASS');
  ck(fs.existsSync(path.join(out, 'm_t1.mp3')), 'song kept after stems failed');
  failStems = false;
  const songsBefore = count('/v1/music');
  r = await run(['--base', base], mock);
  ck(r.code === 0 && /ELEVENLABS GEN PASS/.test(r.out), 'resume completes: ' + r.out);
  ck(count('/v1/music') === songsBefore, 'resume made stems from the saved song, no new song');
  const man = fs.readFileSync(path.join(out, 'manifest.jsonl'), 'utf8').trim().split('\n').map(JSON.parse);
  ck(man.length === 4 && man.every(x => x.sha256 && x.bytes), 'one manifest row per output');
  ck(man.every(x => x.charged === 40 && x.cost_headers['character-cost'] === '40'), 'character-cost header logged');
  ck(man.filter(x => x.step === 'sfx').every(x => x.params.model_id === 'eleven_text_to_sound_v3' && x.estimate === 40), 'sfx v3 default, 40 per second');
  ck(man.filter(x => x.step === 'song').every(x => x.params.model_id === 'music_v2' && !('generation_mode' in x.params)), 'music v2 default, no undocumented field');
  ck(calls.some(c => c.route === '/v1/music' && /output_format=auto/.test(c.query)), 'music output_format=auto');
  const bad = path.join(dir, 'bad.json');
  fs.writeFileSync(bad, JSON.stringify({ items: [{ id: 'x', kind: 'music', seconds: 30, stems: true, prompt: 'p' }] }));
  const rb = await new Promise(res => { const c = spawn(process.execPath, ['-r', guard, gen, '--list', bad, '--out', out, '--dry']); let o = ''; c.stdout.on('data', d => o += d); c.on('close', code => res({ out: o, code })); });
  ck(rb.code === 2 && /stems only in a Gate 3 list/.test(rb.out), 'stems refused outside Gate 3');

  fs.unlinkSync(path.join(out, 'manifest.jsonl'));
  r = await run(['--base', base, '--dry'], mock);
  ck(/0 still to make/.test(r.out) && /RECONCILE a_t1\.mp3/.test(r.out), 'paid outputs without manifest rows are held for reconciliation, not paid again');
  fs.unlinkSync(path.join(out, 'receipts.jsonl'));
  r = await run(['--base', base, '--dry'], mock);
  ck(/4 still to make/.test(r.out), 'files without manifest rows are not done');

  fs.rmSync(out, { recursive: true });
  r = await run(['--base', base, '--max-credits', '300'], mock);
  ck(/STOP: the next step would pass 300 credits/.test(r.out) && count('/v1/sound-generation') >= 1, 'stop uses used credits');

  fs.rmSync(out, { recursive: true });
  fail500 = true;
  const sfxBefore = count('/v1/sound-generation');
  r = await run(['--base', base], mock);
  ck(count('/v1/sound-generation') === sfxBefore + 1 && /STOP: an answer was lost or the server failed/.test(r.out), '5xx not retried');
  fail500 = false;

  // Artoo on PR 1590: an accepted call whose body is lost, or whose file cannot be saved, is recorded and never paid again.
  fs.rmSync(out, { recursive: true });
  truncate = true;
  let sfxN = count('/v1/sound-generation');
  r = await run(['--base', base, '--only', 'a'], mock);
  ck(count('/v1/sound-generation') === sfxN + 1 && /STOP: an answer was lost/.test(r.out) && /INCOMPLETE/.test(r.out), 'truncated body stops the run: ' + r.out);
  let rc = fs.readFileSync(path.join(out, 'receipts.jsonl'), 'utf8');
  ck(/"state":"accepted_no_body"/.test(rc) && /"charged":40/.test(rc), 'truncated body leaves a charged receipt');
  truncate = false;
  sfxN = count('/v1/sound-generation');
  r = await run(['--base', base, '--only', 'a'], mock);
  ck(count('/v1/sound-generation') === sfxN + 1 && /RECONCILE a_t1\.mp3/.test(r.out) && /made a_t2\.mp3/.test(r.out), 'rerun skips the receipted take and makes only the other');

  fs.rmSync(out, { recursive: true });
  fs.mkdirSync(path.join(out, 'a_t1.mp3.part'), { recursive: true });
  sfxN = count('/v1/sound-generation');
  r = await run(['--base', base, '--only', 'a'], mock);
  rc = fs.readFileSync(path.join(out, 'receipts.jsonl'), 'utf8');
  ck(count('/v1/sound-generation') === sfxN + 1 && /accepted but could not record or save/.test(r.out) && /"state":"accepted_save_failed"/.test(rc), 'save failure stops and is receipted');
  sfxN = count('/v1/sound-generation');
  r = await run(['--base', base, '--only', 'a'], mock);
  ck(count('/v1/sound-generation') === sfxN + 1 && /RECONCILE a_t1\.mp3/.test(r.out), 'save failure is not paid again on rerun');

  // Artoo's second PR 1590 finding: a receipt write failing at the paid-call boundary must never allow a second payment.
  fs.rmSync(out, { recursive: true });
  sfxN = count('/v1/sound-generation');
  r = await run(['--base', base, '--only', 'a'], Object.assign({ ELEVENLABS_FAULT: 'pending' }, mock));
  ck(count('/v1/sound-generation') === sfxN && /receipts file not writable; nothing was sent/.test(r.out), 'pending write fails: nothing sent');
  r = await run(['--base', base, '--only', 'a'], mock);
  ck(count('/v1/sound-generation') === sfxN + 2 && /ELEVENLABS GEN PASS/.test(r.out), 'after a failed pending write, a rerun makes both takes');

  fs.rmSync(out, { recursive: true });
  sfxN = count('/v1/sound-generation');
  r = await run(['--base', base, '--only', 'a'], Object.assign({ ELEVENLABS_FAULT: 'accepted,accepted_save_failed' }, mock));
  rc = fs.readFileSync(path.join(out, 'receipts.jsonl'), 'utf8').trim().split('\n').map(JSON.parse);
  ck(count('/v1/sound-generation') === sfxN + 1 && /STOP: an answer was lost/.test(r.out) && rc[rc.length - 1].state === 'pending', 'accepted write fails after the paid call: run stops, pending left');
  sfxN = count('/v1/sound-generation');
  r = await run(['--base', base, '--only', 'a'], mock);
  ck(/RECONCILE a_t1\.mp3: .*\(pending\)/.test(r.out) && count('/v1/sound-generation') === sfxN + 1 && /made a_t2\.mp3/.test(r.out), 'a leftover pending forces RECONCILE, only the other take is paid');

  fs.rmSync(out, { recursive: true });
  r = await run(['--base', base, '--only', 'a'], Object.assign({ ELEVENLABS_FAULT: 'done' }, mock));
  sfxN = count('/v1/sound-generation');
  r = await run(['--base', base, '--only', 'a'], mock);
  ck(count('/v1/sound-generation') === sfxN + 1 && !/RECONCILE a_t1/.test(r.out) && /ELEVENLABS GEN PASS/.test(r.out), 'a saved take with its manifest row is done even if the done line failed');

  ck(calls.filter(c => c.route !== '/v1/redirect').every(c => c.key === MOCK_KEY), 'the real key never reached the server');
  ck(!/real_key_must_not_leave/.test(r.out), 'real key not printed');
  const probe = await new Promise(res => { const c = spawn(process.execPath, ['-r', guard, '-e',
    "fetch('https://api.elevenlabs.io/v1/user').then(() => console.log('REACHED'), e => console.log('CAUGHT ' + e.message))"]);
    let o = ''; c.stdout.on('data', d => o += d); c.on('close', () => res(o)); });
  ck(/OFFLINE GUARD BLOCKED api\.elevenlabs\.io/.test(probe) && !/REACHED/.test(probe), 'offline guard blocks api.elevenlabs.io: ' + probe);
  ck(!guardHits, 'no generator run tried to leave loopback');
  ck(liveCalls === 0, 'every paid-looking call went to the mock server');
  let redirectRefused = false;
  try { await fetch(base + '/v1/redirect', { redirect: 'error' }); } catch (e) { redirectRefused = true; }
  ck(redirectRefused, 'redirect: error refuses a redirect');
  console.log(`offline proof: ${calls.length} calls, all to the loopback test server ${base}; guard blocks ElevenLabs; ` +
    '"account: MOCK-not-a-real-account" lines in generator runs come from this fake server');
  srv.closeAllConnections(); srv.close();
  console.log(fails.length ? 'SELFTEST FAIL: ' + fails.join('; ') : 'ELEVENLABS GEN SELFTEST PASS');
  process.exitCode = fails.length ? 1 : 0;   // not process.exit(): see the libuv note in elevenlabs_gen.js
});
