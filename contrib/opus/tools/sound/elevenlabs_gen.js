#!/usr/bin/env node
// Issue 1572 follow-up (Ryan, Nov 22 2026: ElevenLabs Creator for the sound redo candidates).
// Generates sound effect and music CANDIDATES from a job list. Nothing here touches godot/: picks are wired later,
// after Ryan listens. Runs on Ryan's PC only (the cloud cannot reach elevenlabs.io).
//
//   node elevenlabs_gen.js --list <batch.json> --out <folder> [--dry] [--max-credits N] [--only id,id]
//
// Key: VOIDSWORN_ELEVENLABS_API_KEY (saved by tools/pc/elevenlabs_api_key.bat). If the running process started before
// the key was saved, the script reads it from HKCU\Environment. The key is never written to a file or a log.
// Re-running is safe: a take whose file already exists is skipped, so a stopped run resumes where it left off.
// API facts (docs read Nov 22 2026): POST /v1/sound-generation (text, duration_seconds 0.5..30, loop, prompt_influence,
// model_id), POST /v1/music (prompt, music_length_ms 3000..600000, force_instrumental, model_id),
// POST /v1/music/stem-separation (multipart file, returns a zip). Header xi-api-key. Credits (pricing FAQ): sound effect
// 200 per generation, music 900 per minute; stem separation cost is not published, so it is counted as 0 and the
// account balance is read before and after instead.
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');

const CREDITS_SFX = 200;
const CREDITS_MUSIC_PER_MIN = 900;

function args(argv) {
  const a = { dry: false, max: 60000, only: null, base: process.env.ELEVENLABS_BASE || 'https://api.elevenlabs.io' };
  for (let i = 2; i < argv.length; i++) {
    const k = argv[i];
    if (k === '--list') a.list = argv[++i];
    else if (k === '--out') a.out = argv[++i];
    else if (k === '--dry') a.dry = true;
    else if (k === '--max-credits') a.max = Number(argv[++i]);
    else if (k === '--only') a.only = new Set(argv[++i].split(','));
    else if (k === '--base') a.base = argv[++i];
    else throw new Error('unknown argument ' + k);
  }
  if (!a.list || !a.out) throw new Error('need --list and --out');
  if (!(a.max > 0)) throw new Error('--max-credits must be a positive number');
  return a;
}

function readKey() {
  let k = process.env.VOIDSWORN_ELEVENLABS_API_KEY || '';
  if (!k && process.platform === 'win32') {
    try {
      const o = execFileSync('reg', ['query', 'HKCU\\Environment', '/v', 'VOIDSWORN_ELEVENLABS_API_KEY'], { encoding: 'utf8' });
      const m = o.match(/VOIDSWORN_ELEVENLABS_API_KEY\s+REG_\w+\s+(\S+)/);
      if (m) k = m[1];
    } catch (e) { /* not saved */ }
  }
  return k.trim();
}

// Expands the list into takes: one entry per file to make, with its credit estimate.
function plan(list, only) {
  const takes = [];
  const ids = new Set();
  for (const it of list.items) {
    if (!/^[a-z0-9_]+$/.test(it.id || '')) throw new Error('bad id ' + it.id);
    if (ids.has(it.id)) throw new Error('duplicate id ' + it.id);
    ids.add(it.id);
    if (only && !only.has(it.id)) continue;
    const n = it.takes || 1;
    for (let t = 1; t <= n; t++) {
      if (it.kind === 'sfx') {
        if (!(it.seconds >= 0.5 && it.seconds <= 30)) throw new Error(it.id + ': seconds must be 0.5..30');
        takes.push({ it, t, file: `${it.id}_t${t}.mp3`, credits: CREDITS_SFX });
      } else if (it.kind === 'music') {
        if (!(it.seconds >= 3 && it.seconds <= 600)) throw new Error(it.id + ': seconds must be 3..600');
        takes.push({ it, t, file: `${it.id}_t${t}.mp3`, credits: Math.ceil(it.seconds / 60 * CREDITS_MUSIC_PER_MIN) });
      } else throw new Error(it.id + ': kind must be sfx or music');
    }
  }
  return takes;
}

async function post(base, key, route, body, form) {
  const headers = { 'xi-api-key': key };
  let payload;
  if (form) payload = form;
  else { headers['Content-Type'] = 'application/json'; payload = JSON.stringify(body); }
  for (let attempt = 1; attempt <= 4; attempt++) {
    const r = await fetch(base + route, { method: 'POST', headers, body: payload });
    if (r.ok) return { buf: Buffer.from(await r.arrayBuffer()), req: r.headers.get('request-id') || r.headers.get('x-request-id') || '' };
    const text = (await r.text()).slice(0, 400);
    if ((r.status === 429 || r.status >= 500) && attempt < 4) { await new Promise(s => setTimeout(s, 5000 * attempt)); continue; }
    const err = new Error(`HTTP ${r.status} on ${route}: ${text}`);
    err.status = r.status;
    throw err;
  }
}

async function balance(base, key) {
  try {
    const r = await fetch(base + '/v1/user/subscription', { headers: { 'xi-api-key': key } });
    if (!r.ok) return null;
    const j = await r.json();
    return { tier: j.tier, used: j.character_count, limit: j.character_limit };
  } catch (e) { return null; }
}

function sha(buf) { return crypto.createHash('sha256').update(buf).digest('hex'); }

async function main() {
  const a = args(process.argv);
  const list = JSON.parse(fs.readFileSync(a.list, 'utf8'));
  const takes = plan(list, a.only);
  fs.mkdirSync(a.out, { recursive: true });
  const todo = takes.filter(x => !fs.existsSync(path.join(a.out, x.file)));
  const est = todo.reduce((s, x) => s + x.credits, 0);
  console.log(`list ${path.basename(a.list)}: ${takes.length} takes, ${todo.length} still to make, about ${est} credits (cap ${a.max})`);
  if (a.dry) { for (const x of todo) console.log(`  would make ${x.file} (${x.credits})`); console.log('DRY RUN: nothing sent'); return 0; }
  const key = readKey();
  if (!key) { console.log('FAILED: no key saved. Double-click tools\\pc\\elevenlabs_api_key.bat first.'); return 2; }
  const before = await balance(a.base, key);
  if (before) console.log(`account: ${before.tier}, ${before.used} of ${before.limit} credits used`);
  const manifest = path.join(a.out, 'manifest.jsonl');
  let spent = 0, made = 0, failed = 0;
  for (const x of todo) {
    if (spent + x.credits > a.max) { console.log(`STOP: the next take would pass the ${a.max} credit cap`); break; }
    const it = x.it;
    const started = new Date().toISOString();
    try {
      let res, params;
      if (it.kind === 'sfx') {
        params = { text: it.prompt, duration_seconds: it.seconds, loop: !!it.loop, prompt_influence: it.influence ?? 0.5,
          model_id: it.model || list.sfx_model || 'eleven_text_to_sound_v2' };
        res = await post(a.base, key, '/v1/sound-generation?output_format=mp3_44100_192', params);
      } else {
        params = { prompt: it.prompt, music_length_ms: Math.round(it.seconds * 1000), force_instrumental: it.instrumental !== false,
          model_id: it.model || list.music_model || 'music_v1' };
        res = await post(a.base, key, '/v1/music?output_format=' + (it.format || 'mp3_44100_192'), params);
      }
      const file = path.join(a.out, x.file);
      fs.writeFileSync(file + '.part', res.buf);
      fs.renameSync(file + '.part', file);
      spent += x.credits; made++;
      const rec = { id: it.id, take: x.t, file: x.file, kind: it.kind, cue: it.cue || null, group: it.group || null, params,
        bytes: res.buf.length, sha256: sha(res.buf), request_id: res.req, started, source: 'ElevenLabs API, Creator plan (commercial)' };
      if (it.kind === 'music' && it.stems) {
        const form = new FormData();
        form.append('file', new Blob([res.buf], { type: 'audio/mpeg' }), x.file);
        const st = await post(a.base, key, '/v1/music/stem-separation?output_format=mp3_44100_192', null, form);
        const zip = x.file.replace(/\.mp3$/, '_stems.zip');
        fs.writeFileSync(path.join(a.out, zip), st.buf);
        rec.stems = { file: zip, bytes: st.buf.length, sha256: sha(st.buf) };
      }
      fs.appendFileSync(manifest, JSON.stringify(rec) + '\n');
      console.log(`made ${x.file}${rec.stems ? ' + stems' : ''}`);
    } catch (e) {
      failed++;
      console.log(`FAILED ${x.file}: ${String(e.message).split(key).join('[redacted]')}`);
      if (e.status === 401 || e.status === 402 || e.status === 403) { console.log('STOP: key or plan problem, not retrying'); break; }
    }
  }
  const after = await balance(a.base, key);
  if (after) console.log(`account after: ${after.used} of ${after.limit} credits used` + (before ? ` (this run ${after.used - before.used})` : ''));
  console.log(`made ${made}, failed ${failed}, estimated ${spent} credits`);
  const left = takes.filter(x => !fs.existsSync(path.join(a.out, x.file))).length;
  console.log(left === 0 && failed === 0 ? 'ELEVENLABS GEN PASS' : `ELEVENLABS GEN INCOMPLETE: ${left} takes not made`);
  return left === 0 && failed === 0 ? 0 : 1;
}

if (require.main === module) main().then(c => process.exit(c), e => { console.log('FAILED: ' + e.message); process.exit(2); });
module.exports = { plan, args };
