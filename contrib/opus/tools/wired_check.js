#!/usr/bin/env node
// wired_check.js: what in godot/ is built but not turned on. Node 18+, no packages, read only.
//   node wired_check.js [repo root] [--strict] [--list N]
// Prints: (1) switches whose default is off, (2) godot files the game never reaches and files nothing names,
// (3) sounds on disk that no cue plays, cues no code names, music vs manifest, (4) test scripts missing from the CI list
// and game files the export filter cuts. --strict exits 1 only on hard errors (a listed sound file missing, a test
// missing from godot_checks.txt, a game-reached file cut by export_presets.cfg); the rest is a report.
'use strict';
const fs = require('fs'), path = require('path'), cp = require('child_process');
const args = process.argv.slice(2);
const ROOT = path.resolve(args.find(a => !a.startsWith('--') && !/^\d+$/.test(a)) || '.');
const STRICT = args.includes('--strict');
const LIST = args.includes('--list') ? +args[args.indexOf('--list') + 1] : 12;
const G = path.join(ROOT, 'godot');
const all = cp.execFileSync('git', ['-C', ROOT, 'ls-files', '-z'], { maxBuffer: 1 << 28 }).toString().split('\0').filter(Boolean);
const gfiles = all.filter(f => f.startsWith('godot/')).map(f => f.slice(6));
const read = f => { try { return fs.readFileSync(path.join(G, f), 'utf8'); } catch { return ''; } };
const isTest = f => /(^|\/)test\//.test(f);
const isTooling = f => /^(bench|tools)\//.test(f) || /(_capture|_shots|_shot|_probe|_bench|_bake|_timing|_measure)\.gd$/.test(f);
let hard = 0;
const say = (...a) => console.log(...a);
const head = t => say('\n== ' + t);
const list = (rows, fmt = x => x) => { rows.slice(0, LIST).forEach(r => say('   ' + fmt(r))); if (rows.length > LIST) say(`   ... ${rows.length - LIST} more`); };

// ---------------------------------------------------------------- reference graph
const ASSET = /\.(gd|tscn|scn|tres|res|json|gz|ogg|wav|mp3|png|jpg|jpeg|webp|svg|exr|hdr|glb|gltf|ttf|otf|gdshader|gdshaderinc|obj|br)$/i;
const TEXT = /\.(gd|tscn|tres|json|gdshader|gdshaderinc|cfg|godot|txt|sh|py|js|bat|ps1)$/i;
const ignored = gfiles.filter(f => f.endsWith('.gdignore')).map(f => path.posix.dirname(f) + '/');
const uni = new Set(gfiles.filter(f => ASSET.test(f) && !ignored.some(d => f.startsWith(d))));
const byBase = new Map();
for (const f of uni) { const b = path.posix.basename(f); byBase.set(b, (byBase.get(b) || []).concat(f)); }
const classOf = new Map();
for (const f of uni) if (f.endsWith('.gd')) { const m = read(f).match(/^class_name\s+(\w+)/m); if (m) classOf.set(m[1], f); }
const classRe = classOf.size ? new RegExp('\\b(' + [...classOf.keys()].join('|') + ')\\b', 'g') : null;
const edges = new Map(), dyn = new Map();
const add = (m, k, v) => { if (!m.has(k)) m.set(k, new Set()); m.get(k).add(v); };
const hasDir = p => gfiles.some(g => g.startsWith(p));
for (const f of gfiles) {
  if (!TEXT.test(f)) continue;
  const txt = read(f), dir = path.posix.dirname(f);
  for (const m of txt.matchAll(/res:\/\/([^"'\s)\]}>,;]*)/g)) {
    let p = m[1];
    const after = txt.slice(m.index + m[0].length, m.index + m[0].length + 4), before = txt.slice(Math.max(0, m.index - 24), m.index);
    const cut = p.search(/[%{]/); if (cut >= 0) p = p.slice(0, cut);
    if (uni.has(p)) { if (p !== f) add(edges, f, p); continue; }
    // a folder is a load only when the code builds a name on it: "res://x/" + id, "res://x/%s.png" % id, or a const
    const built = cut >= 0 || /^["']?\s*[+%]/.test(after) || /:?=\s*["']$/.test(before);
    const pre = p.endsWith('/') || cut >= 0 ? p : p + '/';
    if (!built || /begins_with\(\s*["']$|dir_exists\w*\(\s*["']$/.test(before) || !hasDir(pre.replace(/[^/]*$/, ''))) continue;
    if (!isTest(f) && /(^|\/)(test|build)\//.test(pre)) continue;   // game code names test folders only to keep them out
    add(dyn, f, pre);
  }
  for (const m of txt.matchAll(/["']([^"'\n]{1,200}\.[A-Za-z0-9]{2,5})["']/g)) {
    const s = m[1]; if (s.startsWith('res://')) continue;
    const hit = [path.posix.normalize(path.posix.join(dir, s)), path.posix.normalize(s)].find(c => uni.has(c));
    if (hit) { if (hit !== f) add(edges, f, hit); continue; }
    for (const t of byBase.get(path.posix.basename(s)) || []) if (t !== f) add(edges, f, t);   // a bare file name in data
  }
  if (classRe && f.endsWith('.gd')) for (const m of txt.matchAll(classRe)) { const t = classOf.get(m[1]); if (t !== f) add(edges, f, t); }
}
const reach = roots => {
  const seen = new Set(), viaDir = new Set(), q = [...roots];
  while (q.length) {
    const f = q.pop(); if (seen.has(f)) continue; seen.add(f);
    for (const t of edges.get(f) || []) q.push(t);
    for (const p of dyn.get(f) || []) for (const u of uni) if (u.startsWith(p) && !seen.has(u) && (!isTest(u) || /test\//.test(p))) { viaDir.add(u); q.push(u); }
  }
  return { seen, viaDir };
};
const proj = read('project.godot');
const game = reach([...proj.matchAll(/res:\/\/([^"]+)/g)].map(m => m[1]).filter(p => uni.has(p)));
const ciRows = read('tools/ci/godot_checks.txt').split('\n').filter(l => l && !l.startsWith('#')).map(l => l.split('|'));
const extNamed = new Map();
for (const f of all.filter(f => /\.(bat|ps1|cmd|sh|js|py|yml|yaml|json|txt)$/i.test(f) && !/^docs\/(archive|shots)\//.test(f))) {
  let t; try { const st = fs.statSync(path.join(ROOT, f)); if (st.size > 4e6) continue; t = fs.readFileSync(path.join(ROOT, f), 'utf8').replace(/\\\\?/g, '/'); } catch { continue; }
  for (const m of t.matchAll(/(?:res:\/\/|godot\/|["' =])((?:[\w-]+\/)+[\w.-]+\.(?:gd|tscn|json|png|glb))\b/g)) if (uni.has(m[1]) && 'godot/' + m[1] !== f) add(extNamed, m[1], f);
}
const tooling = reach([...ciRows.flatMap(r => [r[1], ...[...`${r[2]} ${r[3]}`.matchAll(/res:\/\/([^\s,]+)/g)].map(m => m[1])]).filter(p => uni.has(p)), ...extNamed.keys()]);
const named = new Set();
for (const [, ts] of edges) for (const t of ts) named.add(t);
for (const [, ps] of dyn) for (const p of ps) for (const u of uni) if (u.startsWith(p)) named.add(u);

// ---------------------------------------------------------------- 1. switches that default off
head('1. switches whose default is off (game code, tests and capture tools left out)');
const gameGd = [...game.seen].filter(f => f.endsWith('.gd') && !isTest(f) && !isTooling(f));
const sw = [];
for (const f of gameGd) {
  const t = read(f).split('\n');
  t.forEach((line, i) => {
    const at = `${f}:${i + 1}`;
    let m;
    if ((m = line.match(/ProjectSettings\.get_setting\("([^"]+)",\s*(false|0|"off"|"")\)/)) && !proj.includes(m[1].split('/').pop() + '='))
      sw.push([at, `project setting ${m[1]} defaults ${m[2]} and project.godot does not set it`]);
    for (const e of line.matchAll(/get_environment\("(VS_[A-Z0-9_]*)"(\s*\+\s*\w+)?\)\s*==\s*"(1|true|on)"/g))
      if (!/OLD|PROBE|HIDE|PROFILE|DRAFT|GAS_FLAT/.test(e[1])) sw.push([at, `on only when ${e[1]}${e[2] ? '<flag>' : ''}=${e[3]} is set (off when Ryan double-clicks the game)`]);
    if ((m = line.match(/^(?:static )?(?:var|const) (\w*(?:_on|_ON|enabled|ENABLED|^use_|USE_|_v2|_V2)\w*)\s*(?::\s*bool)?\s*:?=\s*false\b/))) {
      // a setter: in its own file a bare `name = <not false>`; elsewhere `obj.name = <not false>` (a same-named var in
      // another file is that file's own switch)
      const name = m[1];
      const own = new RegExp('^\\s*(?:self\\.)?' + name + '\\s*=\\s*(?!false\\b)\\S', 'm'), other = new RegExp('\\.' + name + '\\s*=\\s*(?!false\\b)\\S');
      const setters = gameGd.filter(g => (g === f ? own : other).test(read(g)) || g === f && other.test(read(g)));
      if (!setters.length) sw.push([at, `${name} starts false and no game file sets it true (tests or tools only)`]);
    }
  });
}
say(`   ${sw.length} found`); list(sw, ([a, w]) => `${a}  ${w}`);

// ---------------------------------------------------------------- 2. files the game never reaches
head('2. godot files by reach (from res://main/main.tscn through res:// paths, file names in data, class_name)');
const cls = f => game.seen.has(f) ? 'game' : tooling.seen.has(f) ? (isTest(f) ? 'test' : 'tool') : named.has(f) ? 'named-by-unreached' : 'orphan';
const counts = {}; const orphans = [], featureOnly = [];
for (const f of [...uni].sort()) { const c = cls(f); counts[c] = (counts[c] || 0) + 1; if (c === 'orphan') orphans.push(f);
  if (c !== 'game' && f.endsWith('.gd') && !isTest(f) && !isTooling(f) && !/^(rules\/sim|rules\/tools|fx\/gallery|scenes\/campaign|render\/build_assets|main\/test_)/.test(f)) featureOnly.push(f); }
say('   ' + JSON.stringify(counts) + ` of ${uni.size}`);
say(`   product scripts no game path reaches (built, not wired): ${featureOnly.length}`); list(featureOnly);
const og = {}; for (const f of orphans) { const k = f.split('/').slice(0, f.split('/').length > 3 ? 3 : 2).join('/'); og[k] = (og[k] || 0) + 1; }
say(`   orphans (no godot file, CI row or script names them): ${orphans.length}`); list(Object.entries(og).sort((a, b) => b[1] - a[1]), ([k, v]) => `${v}  ${k}`);

// ---------------------------------------------------------------- 3. sound and music
head('3. sounds and music');
const J = f => { try { return JSON.parse(read(f)); } catch { return {}; } };
const idx = J('audio/clips/index.json'), cues = J('audio/cues.json');
const sfx = read('audio/sfx.gd');
const gameCode = gameGd.map(read).join('\n');
const disk = d => new Set(gfiles.filter(f => f.startsWith(d) && f.endsWith('.ogg')).map(f => f.slice(d.length)));
const clipDisk = disk('audio/clips/'), synthDisk = disk('audio/synth/');
const layerKeys = new Set(), synthUsed = new Set();
const walk = c => { (c.layers || []).forEach(L => L.s && layerKeys.add(L.s)); (c.synth || []).forEach(s => synthUsed.add(s)); };
for (const c of Object.values(cues)) { walk(c); Object.values(c.variants || {}).forEach(walk); }
for (const m of sfx.matchAll(/"s":\s*"(\w+)"/g)) layerKeys.add(m[1]);              // cue tables written in sfx.gd
for (const m of sfx.matchAll(/clips\["(\w+)"\]/g)) layerKeys.add(m[1]);             // clips read directly
for (const m of sfx.matchAll(/res:\/\/audio\/synth\/([\w.]+\.ogg)/g)) synthUsed.add(m[1]);
const listed = new Set(Object.values(idx).flat());
const deadKeys = Object.keys(idx).filter(k => !layerKeys.has(k));
const deadClipFiles = [...clipDisk].filter(f => !listed.has(f) || deadKeys.some(k => idx[k].includes(f)));
const deadSynth = [...synthDisk].filter(f => !synthUsed.has(f));
const missing = [...listed].filter(f => !clipDisk.has(f)).concat([...synthUsed].filter(f => !synthDisk.has(f)));
const lits = new Set([...gameCode.matchAll(/"(\w+)"/g)].map(m => m[1]));
const prefixes = [...gameCode.matchAll(/"(\w+_)"\s*\+/g)].map(m => m[1]);
const unplayedCues = Object.keys(cues).filter(k => !lits.has(k) && !prefixes.some(p => k.startsWith(p)));
say(`   clips: ${clipDisk.size} files, ${Object.keys(idx).length} clip sets; ${deadKeys.length} sets no cue plays; ${deadClipFiles.length} clip files never played`);
list(deadKeys.map(k => `${k} (${idx[k].length})`));
say(`   synth takes: ${synthDisk.size} files, ${deadSynth.length} listed by no cue`); list(deadSynth);
say(`   cues: ${Object.keys(cues).length}, never named by game code: ${unplayedCues.length} ${JSON.stringify(unplayedCues)}`);
say(`   listed but missing on disk: ${missing.length}`); if (missing.length) { hard++; list(missing); }
const mm = J('music/music.json'), stems = J('music/stem_pairs.json');
const mfiles = new Set([...Object.values(mm.tracks || {}), ...Object.values(stems.tracks || {})].map(t => t.file));
const mdisk = disk('music/tracks/');
const mDead = [...mdisk].filter(f => !mfiles.has(f)), mMiss = [...mfiles].filter(f => !mdisk.has(f));
say(`   music: ${mdisk.size} tracks, ${mDead.length} not in a manifest, ${mMiss.length} in a manifest but missing`);
if (mMiss.length) { hard++; list(mMiss); }

// ---------------------------------------------------------------- 4. CI list and export filter
head('4. CI list and export');
const listedTests = new Set(ciRows.map(r => r[1]));
const testFiles = gfiles.filter(f => isTest(f) && f.endsWith('.gd'));
const notListed = testFiles.filter(f => !listedTests.has(f));
const byClass = {}; for (const r of ciRows) byClass[r[0]] = (byClass[r[0]] || 0) + 1;
say(`   test scripts ${testFiles.length}, missing from godot_checks.txt ${notListed.length}; rows by class ${JSON.stringify(byClass)}`);
if (notListed.length) { hard++; list(notListed); }
const ep = read('export_presets.cfg');
const pat = k => ((ep.match(new RegExp('^' + k + '="([^"]*)"', 'm')) || [])[1] || '').split(',').map(s => s.trim()).filter(Boolean);
const wild = p => new RegExp('^' + p.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*').replace(/\?/g, '.') + '$', 'i');
const hit = (f, ps) => ps.some(p => wild(p).test(f) || wild(p).test('res://' + f));
if (ep) {
  const exc = pat('exclude_filter');
  const cutGame = [...game.seen].filter(f => hit(f, exc));
  say(`   game-reached files the exclude filter cuts: ${cutGame.length}`); if (cutGame.length) { list(cutGame); }
  const deadAudio = new Set([...deadClipFiles.map(f => 'audio/clips/' + f), ...deadSynth.map(f => 'audio/synth/' + f)]);
  const shippedUnused = [...uni].filter(f => !hit(f, exc) && (!game.seen.has(f) || deadAudio.has(f)) && !/\.br$|\.gz$/.test(f));
  say(`   shipped but never reached by the game: ${shippedUnused.length} files`);
  const sg = {}; for (const f of shippedUnused) { const k = f.split('/').slice(0, 2).join('/'); sg[k] = (sg[k] || 0) + 1; }
  list(Object.entries(sg).sort((a, b) => b[1] - a[1]), ([k, v]) => `${v}  ${k}`);
}
say(`\nhard errors: ${hard}`);
process.exit(STRICT && hard ? 1 : 0);
