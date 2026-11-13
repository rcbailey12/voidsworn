'use strict';
// Issue 656 (Opus, Nov 13 2026): does a reasoning effort setting reach the Kimi Code API, and does it change the model's thinking?
// Runs two (or more) tiny identical OpenCode runs, one per effort, through a local logging relay that sits between OpenCode and
// the Kimi Code endpoint. The relay writes, for every model call: the effort fields OpenCode actually put in the request body
// (reasoning_effort, thinking, and every other non-standard top-level field) and the usage the API sent back (prompt,
// completion and reasoning tokens, plus the length of the streamed thinking text). Authorization headers are never logged.
//
// Usage (Git Bash or cmd, key in KIMI_CODE_API_KEY):
//   node tools/pc/work/kimi_effort_smoke.js [--model kimicode/kimi-for-coding] [--efforts default,low] [--out <folder>]
//        [--config tools/pc/work/opencode_lean.json] [--upstream https://api.kimi.com/coding/v1 | stub] [--puzzle hard|easy] [--cap 300]
//   node tools/pc/work/kimi_effort_smoke.js --direct 4 --efforts low,default   (bare API calls, no OpenCode; see direct())
// --upstream stub answers locally with a fixed reply (free; proves what OpenCode sends without touching the plan).
// "default" means no --variant flag: exactly what the runner sends when WORK_EFFORT is not set.
// Output: <out>/summary.md, <out>/relay_log.jsonl, <out>/events_<effort>.jsonl, <out>/config.json (the relay copy of the config).
const http = require('http');
const https = require('https');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d; };
const here = __dirname;
const MODEL = arg('model', 'kimicode/kimi-for-coding');
const EFFORTS = arg('efforts', 'default,low').split(',').map(s => s.trim()).filter(Boolean);
const UPSTREAM = arg('upstream', 'https://api.kimi.com/coding/v1');
const BASE_CONFIG = arg('config', path.join(here, 'opencode_lean.json'));
const stamp = new Date().toISOString().replace(/[-:]/g, '').replace('T', '_').slice(0, 15);
const OUT = arg('out', path.join(os.tmpdir(), 'kimi_effort_smoke', stamp));
const RUN_CAP_MS = Number(arg('cap', '300')) * 1000;
const PROVIDER = MODEL.split('/')[0];

for (const e of EFFORTS) if (!/^[A-Za-z0-9_-]+$/.test(e)) { console.error('bad effort name: ' + e); process.exit(2); }
if (UPSTREAM !== 'stub' && !process.env.KIMI_CODE_API_KEY) { console.error('KIMI_CODE_API_KEY is not set'); process.exit(3); }
fs.mkdirSync(OUT, { recursive: true });
const relayLog = path.join(OUT, 'relay_log.jsonl');

function findOpencode() {
  const o = arg('opencode', '');
  if (o) return o;
  const exe = path.join(process.env.APPDATA || '', 'npm', 'node_modules', 'opencode-ai', 'bin', process.platform === 'win32' ? 'opencode.exe' : 'opencode');
  return fs.existsSync(exe) ? exe : 'opencode';
}

// The tiny job: one file read, some arithmetic, a one-number answer. Identical for every effort.
// --puzzle hard (the default): answer 19, enough thinking for the effort to show. --puzzle easy: answer 204, so little
// thinking at any effort that the two runs look alike (the first smoke pair, kept for the record).
const PUZZLES = {
  easy: 'A fleet has 7 frigates. Each frigate carries 3 drones. Each drone fires 4 shots per turn, and every second shot misses.\n' +
    'Over 5 turns, how many shots hit? Subtract the number of letters in the word HOLLOW from that total.\n',
  hard: 'How many positive integers less than 1000 have decimal digits that sum to 12 and are divisible by 4?\n',
};
const PUZZLE = arg('puzzle', 'hard');
if (!PUZZLES[PUZZLE]) { console.error('--puzzle must be easy or hard'); process.exit(2); }
const WORK = path.join(OUT, 'work');
fs.mkdirSync(WORK, { recursive: true });
fs.writeFileSync(path.join(WORK, 'puzzle.txt'), PUZZLES[PUZZLE]);
const PROMPT = 'Read puzzle.txt in this folder with the read tool and solve it. Reply with only the final number. Do not edit any file.';

// The relay's copy of the config: identical to the arm's config except the provider's baseURL points at the relay.
let current = 'none';
const STD = new Set(['model', 'messages', 'tools', 'tool_choice', 'stream', 'stream_options', 'max_tokens', 'temperature', 'top_p']);
const server = http.createServer((req, res) => {
  const chunks = [];
  req.on('data', c => chunks.push(c));
  req.on('end', () => {
    const raw = Buffer.concat(chunks);
    let j = {};
    try { j = raw.length ? JSON.parse(raw.toString('utf8')) : {}; } catch (e) { }
    const extra = {};
    for (const k of Object.keys(j)) if (!STD.has(k)) extra[k] = j[k];
    const rec = { t: new Date().toISOString(), run: current, method: req.method, url: req.url, model: j.model, reasoning_effort: j.reasoning_effort === undefined ? null : j.reasoning_effort, thinking: j.thinking === undefined ? null : j.thinking, extra_fields: extra, max_tokens: j.max_tokens, messages: (j.messages || []).length, tools: (j.tools || []).length };
    const done = (status, usage, reasonChars, textChars, errText) => {
      Object.assign(rec, { status, usage, reasoning_chars: reasonChars, text_chars: textChars });
      if (errText) rec.error = errText.slice(0, 600);
      fs.appendFileSync(relayLog, JSON.stringify(rec) + '\n');
    };
    if (UPSTREAM === 'stub') return stub(req, res, j, done);
    const u = new URL(UPSTREAM.replace(/\/$/, '') + req.url.replace(/^\/v1/, ''));
    const headers = Object.assign({}, req.headers);
    delete headers.host; delete headers['accept-encoding']; delete headers['content-length'];
    headers['content-length'] = raw.length;
    const up = https.request({ method: req.method, hostname: u.hostname, port: u.port || 443, path: u.pathname + u.search, headers }, r => {
      res.writeHead(r.statusCode, r.headers);
      let buf = '', usage = null, rc = 0, tc = 0, all = '';
      r.on('data', d => {
        res.write(d);
        const s = d.toString('utf8');
        if (all.length < 20000) all += s;
        buf += s;
        let i;
        while ((i = buf.indexOf('\n')) >= 0) {
          const line = buf.slice(0, i).trim(); buf = buf.slice(i + 1);
          if (!line.startsWith('data:')) continue;
          const p = line.slice(5).trim();
          if (p === '[DONE]') continue;
          try {
            const c = JSON.parse(p);
            if (c.usage) usage = c.usage;
            for (const ch of c.choices || []) {
              const dl = ch.delta || {};
              if (dl.reasoning_content) rc += dl.reasoning_content.length;
              if (dl.reasoning) rc += String(dl.reasoning).length;
              if (dl.content) tc += dl.content.length;
              if (ch.usage) usage = ch.usage;
            }
          } catch (e) { }
        }
      });
      r.on('end', () => {
        res.end();
        if (!usage && !j.stream) { try { const b = JSON.parse(all); usage = b.usage || null; const m = (b.choices || [])[0] && b.choices[0].message || {}; rc = (m.reasoning_content || '').length; tc = (m.content || '').length; } catch (e) { } }
        done(r.statusCode, usage, rc, tc, r.statusCode >= 400 ? all : '');
      });
    });
    up.on('error', e => { done(502, null, 0, 0, e.message); res.writeHead(502); res.end(e.message); });
    up.end(raw);
  });
});

function stub(req, res, j, done) {
  if (!String(req.url).includes('chat/completions')) { res.writeHead(200, { 'Content-Type': 'application/json' }); res.end('{"object":"list","data":[]}'); return done(200, null, 0, 0); }
  const usage = { prompt_tokens: 1000, completion_tokens: 10, total_tokens: 1010 };
  const delta = { role: 'assistant', content: '204' };
  const chunk = (d, f, u) => 'data: ' + JSON.stringify(Object.assign({ id: 'stub', object: 'chat.completion.chunk', created: 1, model: j.model, choices: [{ index: 0, delta: d, finish_reason: f }] }, u ? { usage: u } : {})) + '\n\n';
  res.writeHead(200, { 'Content-Type': 'text/event-stream' });
  res.write(chunk(delta, null)); res.write(chunk({}, 'stop', usage)); res.end('data: [DONE]\n\n');
  done(200, usage, 0, 3);
}

function runOne(effort, port, cfgPath) {
  return new Promise(resolve => {
    current = effort;
    const ev = path.join(OUT, 'events_' + effort + '.jsonl');
    const args = ['run', '--auto', '--format', 'json', '-m', MODEL];
    if (effort !== 'default') args.push('--variant', effort);
    args.push('--dir', WORK, PROMPT);
    const env = Object.assign({}, process.env, { OPENCODE_CONFIG: cfgPath, OPENCODE_DISABLE_AUTOUPDATE: '1', OPENCODE_DISABLE_MODELS_FETCH: '1' });
    if (UPSTREAM === 'stub') env.KIMI_CODE_API_KEY = env.KIMI_CODE_API_KEY || 'stub';
    const t0 = Date.now();
    // stdin closed: OpenCode run reads a piped stdin as part of the message and would wait for it forever
    const p = spawn(findOpencode(), args, { env, cwd: WORK, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
    const out = fs.createWriteStream(ev);
    let err = '';
    p.stdout.pipe(out);
    p.stderr.on('data', d => { err += d.toString(); });
    const kill = setTimeout(() => { err += '\n(killed at the cap)'; p.kill(); }, RUN_CAP_MS);
    p.on('close', code => {
      clearTimeout(kill);
      out.end(() => resolve({ effort, code, secs: ((Date.now() - t0) / 1000).toFixed(1), events: ev, stderr: err.trim().slice(-800), args: args.slice(0, -1).join(' ') }));
    });
  });
}

function readSteps(ev) {
  const steps = []; let text = '';
  for (const line of fs.readFileSync(ev, 'utf8').split(/\r?\n/)) {
    if (!line.trim()) continue;
    let e; try { e = JSON.parse(line); } catch (x) { continue; }
    if (e.type === 'step_finish' && e.part && e.part.tokens) { const k = e.part.tokens; steps.push({ input: k.input || 0, output: k.output || 0, reasoning: k.reasoning || 0, cache_read: (k.cache && k.cache.read) || 0 }); }
    if (e.type === 'text' && e.part && e.part.text) text = e.part.text;
  }
  return { steps, text: text.trim().slice(0, 200) };
}

// --direct N: no OpenCode. N rounds of one bare API call per effort, interleaved (low, default, low, default, ...), with the
// puzzle text as the only message, so the thinking each effort spends is measured without the agent's 6k-token system prompt.
// The effort goes in reasoning_effort ("default" sends none). Writes <out>/direct.md and direct.jsonl.
async function direct(n) {
  const m = MODEL.split('/').slice(1).join('/');
  const call = effort => new Promise(resolve => {
    const body = { model: m, messages: [{ role: 'user', content: PUZZLES[PUZZLE] + 'Reply with only the number.' }], max_tokens: 16000 };
    if (effort !== 'default') body.reasoning_effort = effort;
    const raw = JSON.stringify(body);
    const u = new URL(UPSTREAM.replace(/\/$/, '') + '/chat/completions');
    const t0 = Date.now();
    const r = https.request({ method: 'POST', hostname: u.hostname, path: u.pathname, headers: { 'content-type': 'application/json', authorization: 'Bearer ' + process.env.KIMI_CODE_API_KEY, 'user-agent': 'opencode/1.19.5', 'content-length': Buffer.byteLength(raw) } }, x => {
      let s = ''; x.on('data', d => s += d);
      x.on('end', () => {
        let j = {}; try { j = JSON.parse(s); } catch (e) { }
        const msg = ((j.choices || [])[0] || {}).message || {}; const us = j.usage || {};
        resolve({ effort, status: x.statusCode, secs: ((Date.now() - t0) / 1000).toFixed(1), prompt: us.prompt_tokens, completion: us.completion_tokens, reasoning: (us.completion_tokens_details || {}).reasoning_tokens ?? null, thinking_chars: (msg.reasoning_content || '').length, answer: String(msg.content || '').trim().slice(0, 30), error: x.statusCode >= 400 ? s.slice(0, 300) : undefined });
      });
    });
    r.on('error', e => resolve({ effort, status: 0, error: e.message }));
    r.end(raw);
  });
  const rows = [];
  for (let i = 0; i < n; i++) for (const e of EFFORTS) { const x = await call(e); rows.push(x); fs.appendFileSync(path.join(OUT, 'direct.jsonl'), JSON.stringify(x) + '\n'); console.log(JSON.stringify(x)); }
  const L = ['# Kimi effort smoke, direct API calls, ' + new Date().toISOString(), '', 'puzzle ' + PUZZLE + ', model ' + m + ', ' + n + ' rounds', '', '| effort | calls | reasoning tokens each | mean | right answers |', '|---|---|---|---|---|'];
  for (const e of EFFORTS) {
    const xs = rows.filter(x => x.effort === e); const rs = xs.map(x => x.reasoning == null ? 0 : x.reasoning);
    const right = xs.filter(x => x.answer === (PUZZLE === 'hard' ? '19' : '204')).length;
    L.push('| ' + e + ' | ' + xs.length + ' | ' + rs.join(', ') + ' | ' + Math.round(rs.reduce((a, b) => a + b, 0) / Math.max(1, rs.length)) + ' | ' + right + ' of ' + xs.length + ' |');
  }
  fs.writeFileSync(path.join(OUT, 'direct.md'), L.join('\n') + '\n');
  console.log(L.join('\n') + '\n\nsmoke folder: ' + OUT);
}

(async () => {
  const n = Number(arg('direct', '0'));
  if (n > 0) { if (UPSTREAM === 'stub') { console.error('--direct needs the real upstream'); process.exit(2); } return direct(n); }
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const port = server.address().port;
  const cfg = JSON.parse(fs.readFileSync(BASE_CONFIG, 'utf8'));
  if (!cfg.provider || !cfg.provider[PROVIDER]) { console.error('provider ' + PROVIDER + ' is not in ' + BASE_CONFIG); process.exit(2); }
  cfg.provider[PROVIDER].options = Object.assign({}, cfg.provider[PROVIDER].options, { baseURL: 'http://127.0.0.1:' + port + '/v1' });
  const cfgPath = path.join(OUT, 'config.json');
  fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
  const results = [];
  for (const e of EFFORTS) { console.log('run ' + e + ' ...'); results.push(await runOne(e, port, cfgPath)); }
  server.close();
  const relay = fs.existsSync(relayLog) ? fs.readFileSync(relayLog, 'utf8').split(/\r?\n/).filter(Boolean).map(l => JSON.parse(l)) : [];
  const L = [];
  L.push('# Kimi effort smoke, ' + new Date().toISOString());
  L.push('');
  L.push('puzzle ' + PUZZLE + ', model ' + MODEL + ', upstream ' + UPSTREAM + ', base config ' + path.basename(BASE_CONFIG) + ', OpenCode ' + findOpencode());
  L.push('');
  L.push('| run | exit | seconds | steps | input | output | reasoning (OpenCode) | answer |');
  L.push('|---|---|---|---|---|---|---|---|');
  const sum = {};
  for (const r of results) {
    const s = readSteps(r.events);
    const t = s.steps.reduce((a, b) => ({ input: a.input + b.input, output: a.output + b.output, reasoning: a.reasoning + b.reasoning }), { input: 0, output: 0, reasoning: 0 });
    sum[r.effort] = { exit: r.code, secs: r.secs, steps: s.steps, totals: t, answer: s.text, stderr: r.stderr, args: r.args };
    L.push('| ' + r.effort + ' | ' + r.code + ' | ' + r.secs + ' | ' + s.steps.length + ' | ' + t.input + ' | ' + t.output + ' | ' + t.reasoning + ' | ' + s.text.replace(/\|/g, '/').replace(/\n/g, ' ') + ' |');
  }
  L.push('');
  L.push('Per step (OpenCode step_finish tokens):');
  for (const e of Object.keys(sum)) sum[e].steps.forEach((s, i) => L.push('- ' + e + ' step ' + (i + 1) + ': input ' + s.input + ', output ' + s.output + ', reasoning ' + s.reasoning + ', cache read ' + s.cache_read));
  L.push('');
  L.push('Per API call, as the relay saw it (what OpenCode sent, what the API returned):');
  L.push('');
  L.push('| run | call | status | reasoning_effort sent | thinking sent | other extra fields | prompt tokens | completion tokens | reasoning tokens (API) | thinking chars | text chars |');
  L.push('|---|---|---|---|---|---|---|---|---|---|---|');
  for (const x of relay) {
    if (!String(x.url).includes('chat/completions')) continue;
    const u = x.usage || {};
    const rt = (u.completion_tokens_details && u.completion_tokens_details.reasoning_tokens) ?? u.reasoning_tokens ?? '';
    const ex = Object.keys(x.extra_fields || {}).filter(k => k !== 'reasoning_effort' && k !== 'thinking');
    L.push('| ' + x.run + ' | ' + (x.tools ? 'agent step' : 'session title (no tools)') + ' | ' + x.status + ' | ' + JSON.stringify(x.reasoning_effort) + ' | ' + JSON.stringify(x.thinking) + ' | ' + (ex.map(k => k + '=' + JSON.stringify(x.extra_fields[k])).join('; ') || '-') + ' | ' + (u.prompt_tokens ?? '') + ' | ' + (u.completion_tokens ?? '') + ' | ' + rt + ' | ' + x.reasoning_chars + ' | ' + x.text_chars + ' |');
    if (x.error) L.push('|  |  | error: ' + x.error.replace(/\|/g, '/').replace(/\s+/g, ' ').slice(0, 300) + ' | | | | | | | | |');
  }
  for (const e of Object.keys(sum)) if (sum[e].exit !== 0 && sum[e].stderr) { L.push(''); L.push(e + ' stderr tail: ' + sum[e].stderr.replace(/\s+/g, ' ')); }
  fs.writeFileSync(path.join(OUT, 'summary.md'), L.join('\n') + '\n');
  fs.writeFileSync(path.join(OUT, 'summary.json'), JSON.stringify({ model: MODEL, upstream: UPSTREAM, runs: sum, relay }, null, 2));
  console.log(L.join('\n'));
  console.log('\nsmoke folder: ' + OUT);
})();
