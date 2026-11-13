'use strict';
// Reasoning-effort smoke run for the workhorse runner (issue 656, Opus, Nov 13 2026).
// Proves whether an OpenCode model variant (work_issue.bat WORK_EFFORT, passed as "opencode run --variant <effort>") really
// reaches the Kimi Code API and changes the model's thinking. It runs the same tiny two-step job once per effort, through a
// local logging proxy that sits between OpenCode and api.kimi.com/coding/v1, and logs for every request:
//   what OpenCode sent (model, reasoning_effort, thinking, every other top-level body key) and
//   what the API answered (usage: prompt, completion, reasoning tokens; characters of reasoning text streamed back).
// It also reads OpenCode's own step_finish token counts from each run's events.
// Usage: node effort_smoke.js [--model kimi-for-coding] [--efforts default,low] [--out <folder>] [--config <opencode json>]
//   "default" means no --variant at all, which is how every arm runs when WORK_EFFORT is not set.
//   --config defaults to work\opencode_lean.json (the kimicode arm's config); the script copies it with the kimicode baseURL
//   pointed at the proxy, so the committed config is never changed.
// The key: KIMI_CODE_API_KEY from the environment, else from the user settings (HKCU\Environment), as work_issue.bat reads it.
// Output: <out>\summary.md (the table), <out>\proxy_log.jsonl, <out>\<effort>\events.jsonl and stderr.txt.
// Keep it tiny: each effort is one short session (about two model calls); the plan's 5-hour window is small.
const http = require('http');
const https = require('https');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn, execSync } = require('child_process');

const args = process.argv.slice(2);
const opt = (name, dflt) => { const i = args.indexOf('--' + name); return i >= 0 && args[i + 1] ? args[i + 1] : dflt; };
const MODEL = opt('model', 'kimi-for-coding');
const EFFORTS = opt('efforts', 'default,low').split(',').map(s => s.trim()).filter(Boolean);
const OUT = path.resolve(opt('out', path.join(os.tmpdir(), 'effort_smoke_' + Date.now())));
const CONFIG = path.resolve(opt('config', path.join(__dirname, 'opencode_lean.json')));
// --upstream echo answers every call in the proxy itself with one canned line and never calls Kimi: it shows what OpenCode
// sends for each effort without spending any of the plan's window (run it first when trying a new variant setting).
const UPSTREAM = opt('upstream', 'https://api.kimi.com');
const ECHO = UPSTREAM === 'echo';
const UP = ECHO ? null : new URL(UPSTREAM);
const OC = path.join(process.env.APPDATA || '', 'npm', 'opencode.cmd');
fs.mkdirSync(OUT, { recursive: true });

function regKey(name) {
  try {
    const t = execSync('reg query HKCU\\Environment /v ' + name, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
    const m = t.match(new RegExp(name + '\\s+REG_\\w+\\s+(.+)'));
    return m ? m[1].trim() : '';
  } catch (e) { return ''; }
}
const KEY = process.env.KIMI_CODE_API_KEY || regKey('KIMI_CODE_API_KEY');
if (!KEY && opt('upstream', '') !== 'echo') { console.error('no KIMI_CODE_API_KEY: run KIMI_CODE_KEY.bat first'); process.exit(3); }

let currentEffort = 'none';
const proxyLog = path.join(OUT, 'proxy_log.jsonl');
const rows = [];

// The logging proxy: forwards every request unchanged, records the body keys that matter and the usage that comes back.
const server = http.createServer((req, res) => {
  const chunks = [];
  req.on('data', c => chunks.push(c));
  req.on('end', () => {
    const body = Buffer.concat(chunks);
    let sent = {};
    try { sent = JSON.parse(body.toString('utf8')); } catch (e) { /* not JSON */ }
    const rec = {
      effort: currentEffort, path: req.url, model: sent.model,
      reasoning_effort: sent.reasoning_effort === undefined ? null : sent.reasoning_effort,
      thinking: sent.thinking === undefined ? null : sent.thinking,
      body_keys: Object.keys(sent).filter(k => k !== 'messages' && k !== 'tools').sort(),
      body_rest: JSON.stringify(Object.fromEntries(Object.entries(sent).filter(([k]) => k !== 'messages' && k !== 'tools'))).slice(0, 600),
      messages: Array.isArray(sent.messages) ? sent.messages.length : 0,
    };
    if (ECHO) {
      const usage = { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 };
      const chunk = (d, f, u) => 'data: ' + JSON.stringify(Object.assign({ id: 'echo', object: 'chat.completion.chunk', created: 1,
        model: sent.model, choices: [{ index: 0, delta: d, finish_reason: f }] }, u ? { usage: u } : {})) + '\n\n';
      res.writeHead(200, { 'Content-Type': 'text/event-stream' });
      res.write(chunk({ role: 'assistant', content: 'echo' }, null));
      res.write(chunk({}, 'stop', usage));
      res.end('data: [DONE]\n\n');
      Object.assign(rec, { status: 200, usage, reasoning_chars: 0, text_chars: 4 });
      fs.appendFileSync(proxyLog, JSON.stringify(rec) + '\n');
      rows.push(rec);
      return;
    }
    const headers = Object.assign({}, req.headers, { host: UP.host, 'accept-encoding': 'identity' });
    headers['content-length'] = body.length;
    const up = (UP.protocol === 'http:' ? http : https).request(UPSTREAM + req.url, { method: req.method, headers }, upRes => {
      res.writeHead(upRes.statusCode, upRes.headers);
      let text = '';
      upRes.on('data', c => { res.write(c); text += c.toString('utf8'); });
      upRes.on('end', () => {
        res.end();
        rec.status = upRes.statusCode;
        let usage = null, reasonChars = 0, textChars = 0;
        const take = o => {
          if (o && o.usage) usage = o.usage;
          for (const ch of (o && o.choices) || []) {
            const d = ch.delta || ch.message || {};
            if (typeof d.reasoning_content === 'string') reasonChars += d.reasoning_content.length;
            if (typeof d.reasoning === 'string') reasonChars += d.reasoning.length;
            if (typeof d.content === 'string') textChars += d.content.length;
          }
        };
        if (/^\s*\{/.test(text)) { try { take(JSON.parse(text)); } catch (e) { /* ignore */ } }
        for (const line of text.split('\n')) {
          const m = line.match(/^data:\s*(\{.*\})\s*$/);
          if (m) { try { take(JSON.parse(m[1])); } catch (e) { /* ignore */ } }
        }
        rec.usage = usage;
        rec.reasoning_chars = reasonChars;
        rec.text_chars = textChars;
        if (upRes.statusCode >= 400) rec.error = text.slice(0, 600);
        fs.appendFileSync(proxyLog, JSON.stringify(rec) + '\n');
        rows.push(rec);
      });
    });
    up.on('error', e => { rec.error = String(e); fs.appendFileSync(proxyLog, JSON.stringify(rec) + '\n'); rows.push(rec); res.writeHead(502); res.end(); });
    up.end(body);
  });
});

server.listen(0, '127.0.0.1', () => {
  const port = server.address().port;
  // A copy of the arm's config with the kimicode provider pointed at the proxy.
  const cfg = JSON.parse(fs.readFileSync(CONFIG, 'utf8'));
  cfg.provider.kimicode.options.baseURL = 'http://127.0.0.1:' + port + '/coding/v1';
  const cfgPath = path.join(OUT, 'opencode_smoke.json');
  fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
  // The tiny job: one file to read (one tool call), one short answer. The same words for every effort.
  const work = path.join(OUT, 'job');
  fs.mkdirSync(work, { recursive: true });
  fs.writeFileSync(path.join(work, 'puzzle.txt'),
    'Three ships, Ash, Brand and Cinder, dock in three berths numbered 1 to 3.\n' +
    'Ash is not in berth 1. Brand is in a lower-numbered berth than Cinder. Cinder is not in berth 3.\n' +
    'Which ship is in each berth?\n');
  const prompt = 'Read puzzle.txt in this folder with your read tool, then answer it in one line. Do not run any other tool and do not write any file.';
  const env = Object.assign({}, process.env, {
    KIMI_CODE_API_KEY: KEY || 'echo', OPENCODE_CONFIG: cfgPath,
    OPENCODE_DISABLE_AUTOUPDATE: '1', OPENCODE_DISABLE_MODELS_FETCH: '1',
    SHELL: 'C:\\Program Files\\Git\\bin\\bash.exe', OPENCODE_GIT_BASH_PATH: 'C:\\Program Files\\Git\\bin\\bash.exe',
  });
  const results = [];
  for (const eff of EFFORTS) {
    const d = path.join(OUT, eff);
    fs.mkdirSync(d, { recursive: true });
    const ocArgs = ['run', '--auto', '--format', 'json', '-m', 'kimicode/' + MODEL];
    if (eff !== 'default') ocArgs.push('--variant', eff);
    ocArgs.push('--dir', work, prompt);
    // OpenCode runs as a child process, so this process keeps serving the proxy while it works.
    results.push(runOne(eff, d, ocArgs, env));
  }
  Promise.all(results).then(finish);
});

// Runs are sequential: each starts when the one before it has ended.
let chain = Promise.resolve();
function runOne(eff, d, ocArgs, env) {
  chain = chain.then(() => new Promise(resolve => {
    currentEffort = eff;
    const t0 = Date.now();
    const cmdLine = '"' + OC + '" ' + ocArgs.map(a => /[\s"]/.test(a) ? '"' + a.replace(/"/g, '\\"') + '"' : a).join(' ');
    const ch = spawn(cmdLine, { env, shell: true, windowsHide: true });
    const ev = fs.createWriteStream(path.join(d, 'events.jsonl'));
    const er = fs.createWriteStream(path.join(d, 'stderr.txt'));
    ch.stdout.pipe(ev); ch.stderr.pipe(er);
    const timer = setTimeout(() => { try { execSync('taskkill /T /F /PID ' + ch.pid, { stdio: 'ignore' }); } catch (e) { /* gone */ } }, 300000);
    ch.on('exit', code => {
      clearTimeout(timer);
      setTimeout(() => resolve({ eff, code, secs: Math.round((Date.now() - t0) / 1000), dir: d }), 1500);
    });
  }));
  return chain;
}

function stepTokens(dir) {
  const steps = [];
  let answer = '';
  const f = path.join(dir, 'events.jsonl');
  if (!fs.existsSync(f)) return { steps, answer };
  for (const line of fs.readFileSync(f, 'utf8').split('\n')) {
    let e; try { e = JSON.parse(line); } catch (x) { continue; }
    if (e.type === 'step_finish' && e.part && e.part.tokens) {
      const k = e.part.tokens;
      steps.push({ input: k.input || 0, output: k.output || 0, reasoning: k.reasoning || 0, cache_read: (k.cache && k.cache.read) || 0 });
    }
    if (e.type === 'text' && e.part && e.part.text) answer = e.part.text.trim().replace(/\s+/g, ' ');
  }
  return { steps, answer };
}

function finish(done) {
  const L = [];
  L.push('# Effort smoke run, ' + new Date().toISOString());
  L.push('');
  L.push('Model kimicode/' + MODEL + ', config ' + CONFIG + ', efforts ' + EFFORTS.join(', ') + '.');
  L.push('');
  L.push('## What OpenCode sent and what the API answered (proxy, one row per API call)');
  L.push('');
  L.push('| effort | call | status | reasoning_effort sent | thinking sent | prompt tok | completion tok | reasoning tok (API) | reasoning chars | other body keys |');
  L.push('|---|---|---|---|---|---|---|---|---|---|');
  const n = {};
  for (const r of rows) {
    n[r.effort] = (n[r.effort] || 0) + 1;
    const u = r.usage || {};
    const rt = (u.completion_tokens_details && u.completion_tokens_details.reasoning_tokens);
    L.push('| ' + [r.effort, n[r.effort], r.status, JSON.stringify(r.reasoning_effort), JSON.stringify(r.thinking),
      u.prompt_tokens, u.completion_tokens, rt === undefined ? 'not reported' : rt, r.reasoning_chars,
      r.body_keys.join(' ')].join(' | ') + ' |');
  }
  L.push('');
  L.push('## OpenCode step_finish tokens per step (events.jsonl)');
  L.push('');
  L.push('| effort | exit | seconds | step | input | output | reasoning | cache read | answer |');
  L.push('|---|---|---|---|---|---|---|---|---|');
  for (const d of done) {
    const { steps, answer } = stepTokens(d.dir);
    if (!steps.length) L.push('| ' + [d.eff, d.code, d.secs, '-', '-', '-', '-', '-', answer || '(none)'].join(' | ') + ' |');
    steps.forEach((s, i) => L.push('| ' + [d.eff, d.code, d.secs, i + 1, s.input, s.output, s.reasoning, s.cache_read,
      i === steps.length - 1 ? answer : ''].join(' | ') + ' |'));
  }
  L.push('');
  L.push('## The first request body of each effort, without messages and tools');
  L.push('');
  const seen = {};
  for (const r of rows) if (!seen[r.effort]) { seen[r.effort] = 1; L.push('- ' + r.effort + ': `' + r.body_rest + '`'); }
  for (const r of rows) if (r.error) L.push('\nError on a ' + r.effort + ' call (status ' + r.status + '): ' + r.error.replace(/\s+/g, ' '));
  const text = L.join('\n') + '\n';
  fs.writeFileSync(path.join(OUT, 'summary.md'), text);
  console.log(text);
  console.log('folder: ' + OUT);
  server.close();
  process.exit(0);
}
