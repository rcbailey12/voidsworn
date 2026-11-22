#!/usr/bin/env node
// Issue 1585 Gate 1: builds the listening page (today vs free vs ElevenLabs) for Ryan to pick by ear.
//   node listen_page.js --list <pilot.json> --gen <generator out folder> --repo <repo root> --out <page folder> [--free <folder>]
// Today = the clips today's cue is built from (godot/audio/cues.json layers and synth takes), so the column says
// "parts". Free = any file in --free named <pilot id>*.{ogg,wav,mp3} (Sonniss or CC0 picks, pulled separately).
// ElevenLabs = the pilot takes listed in the generator's manifest.jsonl. Audio is copied next to index.html, so the
// folder opens by double-click and can be published as one page. Nothing is written into godot/.
'use strict';
const fs = require('fs');
const path = require('path');

function args(argv) {
  const a = {};
  for (let i = 2; i < argv.length; i += 2) a[argv[i].replace(/^--/, '')] = argv[i + 1];
  for (const k of ['list', 'gen', 'repo', 'out']) if (!a[k]) throw new Error('need --' + k);
  return a;
}
const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

function todayParts(repo, cueName) {
  const cues = JSON.parse(fs.readFileSync(path.join(repo, 'godot/audio/cues.json'), 'utf8'));
  const index = JSON.parse(fs.readFileSync(path.join(repo, 'godot/audio/clips/index.json'), 'utf8'));
  const base = String(cueName || '').split(' ')[0];
  const variant = (String(cueName).match(/\((\w+) variant\)/) || [])[1];
  const c = cues[base];
  if (!c) return [];
  const out = [];
  const layers = variant && c.variants && c.variants[variant] ? [...(c.variants[variant].layers || []), ...c.layers] : c.layers;
  for (const l of layers || []) { const f = (index[l.s] || [])[0]; if (f) out.push({ file: path.join(repo, 'godot/audio/clips', f), label: l.s }); }
  for (const f of (c.synth || []).slice(0, 1)) out.push({ file: path.join(repo, 'godot/audio/synth', f), label: 'synth ' + f });
  return out.filter(x => fs.existsSync(x.file)).slice(0, 4);
}

function main() {
  const a = args(process.argv);
  const list = JSON.parse(fs.readFileSync(a.list, 'utf8'));
  const man = new Map();
  const mf = path.join(a.gen, 'manifest.jsonl');
  if (fs.existsSync(mf)) for (const l of fs.readFileSync(mf, 'utf8').split('\n')) if (l.trim()) { const r = JSON.parse(l); man.set(r.file, r); }
  const audio = path.join(a.out, 'audio');
  fs.mkdirSync(audio, { recursive: true });
  const copy = (src, name) => { fs.copyFileSync(src, path.join(audio, name)); return 'audio/' + name; };
  const player = (src, label) => `<figure><audio controls preload="none" src="${esc(src)}"></audio><figcaption>${esc(label)}</figcaption></figure>`;
  let rows = '', missing = 0, credits = 0;
  for (const it of list.items) {
    const today = it.kind === 'music' ? [] : todayParts(a.repo, it.cue);
    const todayHtml = today.length ? today.map((p, i) => player(copy(p.file, `${it.id}_today${i}${path.extname(p.file)}`), p.label)).join('')
      : `<p class="none">${it.kind === 'music' ? 'today: the current OpenGameArt tracks' : 'no clip today'}</p>`;
    let freeHtml = '<p class="none">not pulled yet</p>';
    if (a.free && fs.existsSync(a.free)) {
      const f = fs.readdirSync(a.free).filter(n => n.startsWith(it.id) && /\.(ogg|wav|mp3)$/i.test(n)).slice(0, 3);
      if (f.length) freeHtml = f.map(n => player(copy(path.join(a.free, n), 'free_' + n), n)).join('');
    }
    const takes = [];
    for (let t = 1; t <= (it.takes || 1); t++) {
      const file = `${it.id}_t${t}.mp3`, r = man.get(file);
      if (r && fs.existsSync(path.join(a.gen, file))) {
        credits += r.charged ?? r.estimate ?? 0;
        takes.push(player(copy(path.join(a.gen, file), 'el_' + file), `${r.params.model_id}, ${r.charged ?? '~' + r.estimate} credits`));
      } else { missing++; takes.push('<p class="none">not made</p>'); }
    }
    rows += `<tr><th><b>${esc(it.id)}</b><br><small>${esc(it.cue || '')}, ${it.seconds} s</small><br><small class="p">${esc(it.prompt)}</small></th>` +
      `<td>${todayHtml}</td><td>${freeHtml}</td><td>${takes.join('')}</td></tr>\n`;
  }
  const html = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Sound pilot listening</title><style>
:root{--bg:#fff;--fg:#1d1d1f;--mut:#6b6b70;--line:#e3e3e6}
@media (prefers-color-scheme:dark){:root{--bg:#141416;--fg:#ececee;--mut:#9a9aa2;--line:#2c2c31}}
body{background:var(--bg);color:var(--fg);font:15px/1.4 system-ui,sans-serif;margin:0;padding:16px;max-width:1100px}
table{border-collapse:collapse;width:100%}th,td{border-top:1px solid var(--line);padding:10px 8px;vertical-align:top;text-align:left}
th{width:28%}small{color:var(--mut)}.p{display:block;margin-top:4px}audio{width:100%;max-width:260px}figure{margin:0 0 8px}
figcaption{font-size:12px;color:var(--mut)}.none{color:var(--mut);font-style:italic}
@media (max-width:700px){table,tr,th,td{display:block;width:auto}th{border:0}}
</style></head><body><h1>Sound pilot: pick by ear</h1>
<p>Issue 1585, Gate 1. Left to right: what the game uses today (its parts), a free Sonniss or CC0 candidate, and the ElevenLabs take.
For each row, say which one wins, or "none". Your picks decide Gate 2. Credits used: ${credits}. Takes missing: ${missing}.</p>
<table><thead><tr><th>Sound</th><th>Today</th><th>Free</th><th>ElevenLabs</th></tr></thead><tbody>
${rows}</tbody></table></body></html>`;
  fs.writeFileSync(path.join(a.out, 'index.html'), html);
  console.log(`LISTEN PAGE written: ${path.join(a.out, 'index.html')} (${list.items.length} rows, ${missing} takes missing, ${credits} credits)`);
}
main();
