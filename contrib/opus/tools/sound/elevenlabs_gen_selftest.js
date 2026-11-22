// Offline selftest for elevenlabs_gen.js: a fake API on localhost, no key or network needed.
'use strict';
const http = require('http'), fs = require('fs'), os = require('os'), path = require('path'), { spawn } = require('child_process');
const KEY = 'test_key_123';
const calls = [];
const srv = http.createServer((q, r) => {
  let n = 0; q.on('data', c => n += c.length); q.on('end', () => {
    calls.push(q.method + ' ' + q.url.split('?')[0] + ' key=' + (q.headers['xi-api-key'] === KEY));
    if (q.headers['xi-api-key'] !== KEY) { r.writeHead(401); return r.end('bad key ' + KEY); }
    if (q.url.startsWith('/v1/user/subscription')) { r.writeHead(200, { 'content-type': 'application/json' }); return r.end(JSON.stringify({ tier: 'creator', character_count: calls.length, character_limit: 121000 })); }
    r.writeHead(200, { 'request-id': 'req' + calls.length }); r.end(Buffer.alloc(64, calls.length));
  });
});
srv.listen(0, '127.0.0.1', async () => {
  const base = 'http://127.0.0.1:' + srv.address().port;
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'elgen-'));
  const list = path.join(dir, 'list.json');
  fs.writeFileSync(list, JSON.stringify({ items: [
    { id: 'a', kind: 'sfx', seconds: 1, takes: 2, prompt: 'click' },
    { id: 'm', kind: 'music', seconds: 60, takes: 1, stems: true, prompt: 'song' } ] }));
  const out = path.join(dir, 'out');
  // async child (a sync spawn would block this process's fake server)
  const run = (extra, env) => new Promise(res => {
    const c = spawn(process.execPath, [path.join(__dirname, 'elevenlabs_gen.js'), '--list', list, '--out', out, '--base', base, ...extra],
      { env: Object.assign({}, process.env, env) });
    let o = ''; c.stdout.on('data', d => o += d); c.stderr.on('data', d => o += d); c.on('close', () => res({ stdout: o }));
  });
  const fails = [];
  const ck = (c, m) => { if (!c) fails.push(m); };
  let r = await run(['--max-credits', '300'], { VOIDSWORN_ELEVENLABS_API_KEY: KEY });
  ck(/STOP: the next take would pass/.test(r.stdout), 'cap stop'); ck(fs.existsSync(path.join(out, 'a_t1.mp3')) && !fs.existsSync(path.join(out, 'a_t2.mp3')), 'cap made one');
  r = await run([], { VOIDSWORN_ELEVENLABS_API_KEY: KEY });
  ck(/ELEVENLABS GEN PASS/.test(r.stdout), 'pass: ' + r.stdout);
  ck(fs.existsSync(path.join(out, 'm_t1_stems.zip')), 'stems zip');
  const man = fs.readFileSync(path.join(out, 'manifest.jsonl'), 'utf8').trim().split('\n').map(JSON.parse);
  ck(man.length === 3 && man.every(x => x.sha256 && x.params), 'manifest rows');
  ck(calls.filter(c => c.startsWith('POST /v1/sound-generation')).length === 2, 'sfx calls once each (resume skipped a_t1)');
  r = await run([], { VOIDSWORN_ELEVENLABS_API_KEY: KEY });
  ck(/0 still to make/.test(r.stdout), 'rerun skips all');
  fs.rmSync(out, { recursive: true });
  r = await run([], { VOIDSWORN_ELEVENLABS_API_KEY: 'wrong' });
  ck(/STOP: key or plan problem/.test(r.stdout) && !r.stdout.includes('wrong'), 'bad key stops, key redacted');
  r = await run(['--dry'], { VOIDSWORN_ELEVENLABS_API_KEY: '' });
  ck(/DRY RUN/.test(r.stdout), 'dry run without key');
  srv.close();
  console.log(fails.length ? 'SELFTEST FAIL: ' + fails.join('; ') : 'ELEVENLABS GEN SELFTEST PASS');
  process.exit(fails.length ? 1 : 0);
});
