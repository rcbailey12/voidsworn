#!/usr/bin/env node
// Issue 1572 follow-up (Ryan, Nov 22 2026: ElevenLabs Creator for the sound redo candidates).
// Generates sound effect and music CANDIDATES from a job list. Nothing here touches godot/: picks are wired later,
// after Ryan listens. Runs on Ryan's PC only (the cloud cannot reach elevenlabs.io).
//
//   node elevenlabs_gen.js --list <batch.json> --out <folder> [--dry] [--max-credits N] [--only id,id]
//
// Key: VOIDSWORN_ELEVENLABS_API_KEY (saved by tools/pc/elevenlabs_api_key.bat). If the running process started before
// the key was saved, the script reads it from HKCU\Environment. The key is never written to a file or a log.
// Live requests go only to https://api.elevenlabs.io, with redirects refused (Artoo on PR 1577, finding 1). The offline
// selftest uses ELEVENLABS_MOCK=1, which only allows a loopback base and only the dummy ELEVENLABS_MOCK_KEY, never the
// real key.
// Resume (finding 2): every output is its own step (song, stems zip, sound take) with its own manifest row. A rerun makes
// any missing step, including stems for a song already saved. PASS needs every file AND its manifest row.
// Spending (finding 3): the real ceiling is the credit cap Ryan sets on the key at elevenlabs.io. --max-credits is a
// second stop: it uses the account's own used-credit count (GET /v1/user/subscription) after every paid call, and the
// published estimate (200 per sound effect, 900 per music minute; stem cost unpublished) only if that read fails.
// A paid call is never retried after an error that could mean it ran (5xx, timeout); only 429 (not run) is retried.
// API facts (docs read Nov 22 2026): POST /v1/sound-generation, POST /v1/music, POST /v1/music/stem-separation (zip),
// header xi-api-key. Issue 1585 (Neon pre-flight on PR 1577): defaults are eleven_text_to_sound_v3 and music_v2
// (models page: eleven_text_to_sound_v2 removed Mar 1 2027, music_v1 removed Jan 31 2027); a per-item "model" keeps
// v2 for an A/B. Sound effects with a set duration cost 40 credits a second (capabilities page). Music v2 uses
// output_format=auto. The cost header ElevenLabs returns (character-cost) is logged on every call and counted. Stems
// are allowed only in a list marked "gate": 3 and are estimated at the song's own cost (not published).
// "generation_mode" is NOT in the API reference read Nov 22 2026, so it is sent only when an item sets it.
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');

const LIVE_BASE = 'https://api.elevenlabs.io';
const CREDITS_SFX_AUTO = 200;          // no duration set: flat per generation
const CREDITS_SFX_PER_S = 40;          // duration set
const CREDITS_MUSIC_PER_MIN = 900;

function args(argv) {
  const a = { dry: false, max: 60000, only: null, base: LIVE_BASE, mock: process.env.ELEVENLABS_MOCK === '1' };
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
  if (a.mock) {
    if (!/^http:\/\/(127\.0\.0\.1|localhost):\d+$/.test(a.base)) throw new Error('mock mode needs a loopback --base');
  } else if (a.base !== LIVE_BASE) throw new Error('live runs only talk to ' + LIVE_BASE);
  return a;
}

function readKey(a) {
  if (a.mock) return (process.env.ELEVENLABS_MOCK_KEY || '').trim();   // never the real key in mock mode
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

// Expands the list into steps: one per output file, with its credit estimate. A song with stems has two steps.
function plan(list, only) {
  const steps = [];
  const ids = new Set();
  for (const it of list.items) {
    if (!/^[a-z0-9_]+$/.test(it.id || '')) throw new Error('bad id ' + it.id);
    if (ids.has(it.id)) throw new Error('duplicate id ' + it.id);
    ids.add(it.id);
    if (it.stems && list.gate !== 3) throw new Error(it.id + ': stems only in a Gate 3 list (issue 1585)');
    if (only && !only.has(it.id)) continue;
    const n = it.takes || 1;
    for (let t = 1; t <= n; t++) {
      const file = `${it.id}_t${t}.mp3`;
      if (it.kind === 'sfx') {
        if (!(it.seconds >= 0.5 && it.seconds <= 30)) throw new Error(it.id + ': seconds must be 0.5..30');
        steps.push({ it, t, step: 'sfx', file, credits: Math.ceil(it.seconds * CREDITS_SFX_PER_S) });
      } else if (it.kind === 'music') {
        if (!(it.seconds >= 3 && it.seconds <= 600)) throw new Error(it.id + ': seconds must be 3..600');
        steps.push({ it, t, step: 'song', file, credits: Math.ceil(it.seconds / 60 * CREDITS_MUSIC_PER_MIN) });
        const songCost = Math.ceil(it.seconds / 60 * CREDITS_MUSIC_PER_MIN);
        if (it.stems) steps.push({ it, t, step: 'stems', file: file.replace(/\.mp3$/, '_stems.zip'), song: file, credits: songCost });
      } else throw new Error(it.id + ': kind must be sfx or music');
    }
  }
  return steps;
}

async function post(base, key, route, body, form) {
  const headers = { 'xi-api-key': key };
  let payload;
  if (form) payload = form;
  else { headers['Content-Type'] = 'application/json'; payload = JSON.stringify(body); }
  for (let attempt = 1; attempt <= 4; attempt++) {
    let r;
    try {
      r = await fetch(base + route, { method: 'POST', headers, body: payload, redirect: 'error', signal: AbortSignal.timeout(900000) });
    } catch (e) {
      const err = new Error('no answer on ' + route + ' (' + e.name + '); not retried, the call may have been charged');
      err.ambiguous = true;
      throw err;
    }
    if (r.ok) {
      const cost = {};
      for (const [k, v] of r.headers) if (/cost|character|credit/i.test(k)) cost[k] = v;
      const n = Number(r.headers.get('character-cost'));
      return { buf: Buffer.from(await r.arrayBuffer()), req: r.headers.get('request-id') || r.headers.get('x-request-id') || '',
        cost, charged: Number.isFinite(n) && r.headers.has('character-cost') ? n : null };
    }
    const text = (await r.text()).slice(0, 400);
    if (r.status === 429 && attempt < 4) { await new Promise(s => setTimeout(s, 10000 * attempt)); continue; }
    const err = new Error(`HTTP ${r.status} on ${route}: ${text}`);
    err.status = r.status;
    err.ambiguous = r.status >= 500;
    throw err;
  }
}

async function usedCredits(base, key) {
  try {
    const r = await fetch(base + '/v1/user/subscription', { headers: { 'xi-api-key': key }, redirect: 'error' });
    if (!r.ok) return null;
    const j = await r.json();
    return Number.isFinite(j.character_count) ? { tier: j.tier, used: j.character_count, limit: j.character_limit } : null;
  } catch (e) { return null; }
}

function sha(buf) { return crypto.createHash('sha256').update(buf).digest('hex'); }

function readManifest(file) {
  const rows = new Map();
  if (!fs.existsSync(file)) return rows;
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    if (!line.trim()) continue;
    try { const r = JSON.parse(line); rows.set(r.file, r); } catch (e) { /* a torn last line is ignored */ }
  }
  return rows;
}

function save(out, name, buf) {
  const file = path.join(out, name);
  fs.writeFileSync(file + '.part', buf);
  fs.renameSync(file + '.part', file);
}

// A step is done only when its file exists and its manifest row matches the file's size.
function done(out, rows, s) {
  const f = path.join(out, s.file);
  const r = rows.get(s.file);
  return fs.existsSync(f) && !!r && r.bytes === fs.statSync(f).size;
}

async function main() {
  const a = args(process.argv);
  const list = JSON.parse(fs.readFileSync(a.list, 'utf8'));
  const steps = plan(list, a.only);
  fs.mkdirSync(a.out, { recursive: true });
  const manifest = path.join(a.out, 'manifest.jsonl');
  let rows = readManifest(manifest);
  const todo = steps.filter(s => !done(a.out, rows, s));
  const est = todo.reduce((n, s) => n + s.credits, 0);
  console.log(`list ${path.basename(a.list)}: ${steps.length} steps, ${todo.length} still to make, estimate ${est} credits ` +
    `(stems priced at their song's cost; stop at ${a.max} used; the key's own cap at elevenlabs.io is the real ceiling)`);
  if (a.dry) { for (const s of todo) console.log(`  would make ${s.file} (${s.step}, est ${s.credits})`); console.log('DRY RUN: nothing sent'); return 0; }
  const key = readKey(a);
  if (!key) { console.log('FAILED: no key saved. Double-click ELEVENLABS_API_KEY.bat first.'); return 2; }
  const redact = t => String(t).split(key).join('[redacted]');
  const before = await usedCredits(a.base, key);
  if (before) console.log(`account: ${before.tier}, ${before.used} of ${before.limit} credits used`);
  else console.log('account balance unreadable: the stop uses the estimate');
  let estSpent = 0, made = 0, failed = 0, stopped = '';   // estSpent: header cost where given, else the estimate
  for (const s of todo) {
    const now = before ? await usedCredits(a.base, key) : null;
    const spent = now ? now.used - before.used : estSpent;
    if (spent + s.credits > a.max) { stopped = `the next step would pass ${a.max} credits (${spent} used so far)`; break; }
    const it = s.it;
    const started = new Date().toISOString();
    try {
      let res, params;
      if (s.step === 'sfx') {
        params = { text: it.prompt, duration_seconds: it.seconds, loop: !!it.loop, prompt_influence: it.influence ?? 0.5,
          model_id: it.model || list.sfx_model || 'eleven_text_to_sound_v3' };
        res = await post(a.base, key, '/v1/sound-generation?output_format=mp3_44100_192', params);
      } else if (s.step === 'song') {
        params = { prompt: it.prompt, music_length_ms: Math.round(it.seconds * 1000), force_instrumental: it.instrumental !== false,
          model_id: it.model || list.music_model || 'music_v2' };
        if (it.generation_mode) params.generation_mode = it.generation_mode;
        res = await post(a.base, key, '/v1/music?output_format=' + (it.format || 'auto'), params);
      } else {
        const songFile = path.join(a.out, s.song);
        if (!done(a.out, rows, { file: s.song })) { console.log(`SKIP ${s.file}: its song ${s.song} is not made yet`); failed++; continue; }
        params = { from: s.song };
        const form = new FormData();
        form.append('file', new Blob([fs.readFileSync(songFile)], { type: 'audio/mpeg' }), s.song);
        res = await post(a.base, key, '/v1/music/stem-separation?output_format=mp3_44100_192', null, form);
      }
      save(a.out, s.file, res.buf);
      estSpent += res.charged ?? s.credits; made++;
      const rec = { id: it.id, take: s.t, step: s.step, file: s.file, kind: it.kind, cue: it.cue || null, group: it.group || null,
        params, bytes: res.buf.length, sha256: sha(res.buf), request_id: res.req, cost_headers: res.cost, charged: res.charged,
        estimate: s.credits, started,
        source: 'ElevenLabs API, Creator plan (commercial)' };
      fs.appendFileSync(manifest, JSON.stringify(rec) + '\n');
      rows.set(s.file, rec);
      console.log(`made ${s.file}`);
    } catch (e) {
      failed++;
      console.log(`FAILED ${s.file}: ${redact(e.message)}`);
      if (e.status === 401 || e.status === 402 || e.status === 403) { stopped = 'key or plan problem'; break; }
      if (e.ambiguous) { stopped = 'an answer was lost or the server failed; check the balance before rerunning'; break; }
    }
  }
  const after = before ? await usedCredits(a.base, key) : null;
  if (after) console.log(`account after: ${after.used} of ${after.limit} used (this run ${after.used - before.used})`);
  if (stopped) console.log('STOP: ' + stopped);
  rows = readManifest(manifest);
  const left = steps.filter(s => !done(a.out, rows, s));
  console.log(`made ${made}, failed ${failed}, estimate ${estSpent} credits, ${left.length} of ${steps.length} steps not done`);
  for (const s of left.slice(0, 20)) console.log('  not done: ' + s.file);
  console.log(left.length === 0 ? 'ELEVENLABS GEN PASS' : 'ELEVENLABS GEN INCOMPLETE');
  return left.length === 0 ? 0 : 1;
}

if (require.main === module) main().then(c => process.exit(c), e => { console.log('FAILED: ' + e.message); process.exit(2); });
module.exports = { plan, args };
