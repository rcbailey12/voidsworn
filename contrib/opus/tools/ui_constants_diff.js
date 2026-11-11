'use strict';
// The scripted two-build UI constant diff (UI audit settlement U-B, literal extraction form; issue #231).
// Node 18+, no dependencies. Reads the frozen browser build and the Godot port, extracts their UI literals and writes
// one table: contrib/opus/briefs/ui_spec_constants.md (or prints it with --stdout).
//   node contrib/opus/tools/ui_constants_diff.js [--stdout]
// What it extracts:
//   1. the palette: the browser's CSS variables (head.html :root) and the port's named colour constants;
//   2. every hex colour literal in each build's UI files, marked on-palette or off-palette (with the nearest palette
//      colour and its distance), so a one-off colour can be adopted or replaced on the record (MP3, MP11, IC5, IC8);
//   3. every Color(r, g, b) float literal in the port's UI files, as hex (the transcription drift HD10 found);
//   4. every text size literal: CSS font-size px in the browser, design sizes passed to s(), px(), _label(), lbl(),
//      rich() and the like in the port; anything under the ui_scale.gd text floor is listed (TY6);
//   5. the named pairs the audit found (HD5, HD7, HD9, HD11, HD13, MN7 and more), each read from both builds by a
//      pattern, with SAME or DIFFERENT. A pair whose pattern stops matching prints NOT FOUND, so the table never goes
//      stale silently.
// A difference is a question, not an automatic reversion (audit synthesis 5.3): ui_spec.md section 3 records the choice.
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const OUT = path.join(ROOT, 'contrib/opus/briefs/ui_spec_constants.md');

const JS_FILES = ['head.html', 'ui3d.js', 'campaign_run.js', 'campaign_meta.js', 'campaign3d.js'];
// 3D map scene and crest art: their colours are materials and emblem paint, governed by the R3 map rule
// (ui_spec.md 5.4), not by the UI palette; they are left out of the colour tables, kept in the text size scan
const ART_FILES = /map3d_props\.gd$|map3d_system\.gd$|map3d_shaders\.gd$|crest\.gd$/;
function godotFiles() {
  const out = [];
  const walk = d => {
    for (const e of fs.readdirSync(path.join(ROOT, d), { withFileTypes: true })) {
      const rel = d + '/' + e.name;
      if (e.isDirectory()) { if (!['test', 'fonts'].includes(e.name)) walk(rel); }
      else if (e.name.endsWith('.gd') && !/_shots\.gd$|_test\.gd$|test_/.test(e.name)) out.push(rel);
    }
  };
  walk('godot/ui'); walk('godot/main');
  return out.sort();
}
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
const lineOf = (text, idx) => text.slice(0, idx).split('\n').length;

// ---------------------------------------------------------------- colours
const hex6 = h => {
  h = h.toLowerCase().replace('#', '');
  if (h.length === 3) h = h.split('').map(c => c + c).join('');
  return '#' + h.slice(0, 6);
};
const rgb = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
const dist = (a, b) => { const x = rgb(a), y = rgb(b); return Math.round(Math.hypot(x[0] - y[0], x[1] - y[1], x[2] - y[2])); };
const toHex = v => Math.max(0, Math.min(255, Math.round(v * 255))).toString(16).padStart(2, '0');

function palette() {
  const pal = {};
  const css = read('head.html');
  const root = css.slice(css.indexOf(':root{'), css.indexOf('}', css.indexOf(':root{')));
  for (const m of root.matchAll(/--([a-z0-9]+):(#[0-9a-fA-F]{3,6})\b/g)) pal[hex6(m[2])] = (pal[hex6(m[2])] || []).concat('css --' + m[1]);
  for (const f of ['godot/ui/battle/hud.gd', 'godot/ui/campaign/campaign_ui.gd']) {
    for (const m of read(f).matchAll(/^const ([A-Z_0-9]+) := Color\("(#[0-9a-fA-F]{6})"\)/gm)) pal[hex6(m[2])] = (pal[hex6(m[2])] || []).concat(path.basename(f, '.gd') + ' ' + m[1]);
  }
  return pal;
}

function hexUses(files) {
  const uses = {};
  for (const f of files) {
    const t = read(f);
    for (const m of t.matchAll(/#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})(?![0-9a-zA-Z_-])/g)) {
      if (f.endsWith('.html') && /^[0-9a-f]{3}$/i.test(m[1]) && !/[:(,\s"']$/.test(t[m.index - 1] || '')) continue; // not a colour (ids)
      const h = hex6(m[0]);
      (uses[h] = uses[h] || []).push(f + ':' + lineOf(t, m.index));
    }
  }
  return uses;
}

function floatColours(files) {
  const rows = [];
  for (const f of files) {
    const t = read(f);
    for (const m of t.matchAll(/Color\(\s*([01]?\.\d+|[01](?:\.0+)?)\s*,\s*([01]?\.\d+|[01](?:\.0+)?)\s*,\s*([01]?\.\d+|[01](?:\.0+)?)\s*(?:,\s*([01]?\.\d+|[01](?:\.0+)?))?\s*\)/g)) {
      rows.push({ hex: '#' + toHex(+m[1]) + toHex(+m[2]) + toHex(+m[3]), alpha: m[4] === undefined ? '' : m[4], at: f + ':' + lineOf(t, m.index) });
    }
  }
  return rows;
}

// ---------------------------------------------------------------- text sizes
// the argument list of a call starting at text[i] == '(' : split on top-level commas, strings skipped
function args(t, i) {
  const out = []; let depth = 0, cur = '', q = null;
  for (let j = i; j < t.length; j++) {
    const ch = t[j];
    if (q) { cur += ch; if (ch === '\\') { cur += t[++j]; continue; } if (ch === q) q = null; continue; }
    if (ch === '"' || ch === "'") { q = ch; cur += ch; continue; }
    if (ch === '(' || ch === '[' || ch === '{') { depth++; if (depth === 1 && ch === '(') continue; }
    if (ch === ')' || ch === ']' || ch === '}') { depth--; if (depth === 0) { out.push(cur.trim()); return out; } }
    if (ch === ',' && depth === 1) { out.push(cur.trim()); cur = ''; continue; }
    cur += ch;
    if (ch === '\n' && depth === 0) return out;
  }
  return out;
}
const NUM = /^\d+(?:\.\d+)?$/;
// design text sizes in the port: font size overrides through s() or px(), and the size argument of the label helpers
const GD_SIZE_CALLS = { lbl: 1, _label: 1, rich: 1, rich_inline: 1, gothic: 1, caps: 1 };
function godotSizes(files) {
  const rows = [];
  for (const f of files) {
    const t = read(f);
    for (const m of t.matchAll(/font_size[a-z_]*"?\s*,\s*(?:"[A-Za-z]+"\s*,\s*)?(?:[A-Za-z_][A-Za-z0-9_]*\.)?(?:s|px)\((\d+(?:\.\d+)?)/g)) rows.push({ v: +m[1], at: f + ':' + lineOf(t, m.index), how: 'font size' });
    // #282 (N1): the theme default form (`default_font_size = s(15)`) and raw integer overrides were not scanned before
    for (const m of t.matchAll(/default_font_size\s*(?::=|=)\s*(?:(?:[A-Za-z_][A-Za-z0-9_]*\.)?(?:s|px)\(\s*)?(\d+(?:\.\d+)?)/g)) rows.push({ v: +m[1], at: f + ':' + lineOf(t, m.index), how: 'theme default' });
    for (const m of t.matchAll(/(?:add_theme_font_size_override|set_font_size)\(\s*"[a-z_]*font_size"\s*,\s*(?:\s*"[A-Za-z]+"\s*,\s*)?(\d+(?:\.\d+)?)\s*\)/g)) rows.push({ v: +m[1], at: f + ':' + lineOf(t, m.index), how: 'raw font size' });
    for (const m of t.matchAll(/\b(lbl|_label|rich|rich_inline|gothic|caps)\(/g)) {
      if (/func\s+$/.test(t.slice(Math.max(0, m.index - 6), m.index))) continue;
      const a = args(t, m.index + m[0].length - 1);
      const v = a[GD_SIZE_CALLS[m[1]]];
      if (v && NUM.test(v)) rows.push({ v: m[1] === 'gothic' ? +v * 0.7 : +v, at: f + ':' + lineOf(t, m.index), how: m[1] + '()', text: a[0] });
    }
    for (const m of t.matchAll(/\[font_size=%d\][^"]*"\s*%\s*s\((\d+)\)/g)) rows.push({ v: +m[1], at: f + ':' + lineOf(t, m.index), how: 'bbcode font_size' });
  }
  return rows;
}
function jsSizes(files) {
  const rows = [];
  for (const f of files) {
    const t = read(f);
    for (const m of t.matchAll(/font-size\s*:\s*(\d+(?:\.\d+)?)px/g)) rows.push({ v: +m[1], at: f + ':' + lineOf(t, m.index), how: 'css' });
    for (const m of t.matchAll(/font-size="(\d+(?:\.\d+)?)"/g)) rows.push({ v: +m[1], at: f + ':' + lineOf(t, m.index), how: 'svg' });
  }
  return rows;
}

// ---------------------------------------------------------------- named pairs (the audit's items)
// each side: [file, regex]; the first capture group is the value
const PAIRS = [
  ['HD2', 'battle body text size', ['head.html', /body\{[^}]*font-size:(\d+(?:\.\d+)?)px/], ['godot/ui/battle/hud.gd', /default_font_size = s\((\d+)\)/]],
  ['HD2', 'battle button text size', ['head.html', /\nbutton\{[^}]*font-size:(\d+(?:\.\d+)?)px/], ['godot/ui/battle/hud.gd', /set_font_size\("font_size", "Button", s\((\d+)\)\)/]],
  ['HD3', 'top bar height', ['head.html', /#btop\{[^}]*height:(\d+)px/], ['godot/ui/battle/hud.gd', /const TOP_H := (\d+)/]],
  ['HD3', 'top bar title size', ['head.html', /#btop \.t\{[^}]*font-size:(\d+)px/], ['godot/ui/battle/hud.gd', /title_lbl = _label\("[^"]*", (\d+)/]],
  ['HD4', 'fleet roster width', ['head.html', /#roster\{[^}]*width:(\d+)px/], ['godot/ui/battle/hud.gd', /const FLEET_W := (\d+)/]],
  ['HD5', 'selected-ship panel width (outer)', ['head.html', /#panel\{[^}]*width:(\d+)px/], ['godot/ui/battle/hud.gd', /const COL_W := (\d+)/]],
  ['HD6', 'battle log width', ['head.html', /#log\{[^}]*width:(\d+)px/], ['godot/ui/battle/hud.gd', /const LOG_W := (\d+)/]],
  ['HD6', 'battle log height', ['head.html', /#log\{[^}]*height:(\d+)px/], ['godot/ui/battle/hud.gd', /const LOG_H := (\d+)/]],
  ['HD7', 'nameplate bar width', ['head.html', /--bw:(\d+)px/], ['godot/ui/battle/hud.gd', /bars_c\.custom_minimum_size = Vector2\(s\((\d+)\)/]],
  ['HD7', 'nameplate name size', ['head.html', /\.plate \.nm\{[^}]*font-size:(\d+)px/], ['godot/ui/battle/hud.gd', /var nm := _label\("", (\d+)/]],
  ['HD9', 'hull-low threshold (battle roster)', ['campaign_meta.js', /function hpBar[^\n]*f<(\.\d+)/], ['godot/ui/battle/hud.gd', /HULL_LOW if [a-z_]+ < (0\.\d+)/]],
  ['HD9', 'hull-low threshold (campaign bar)', ['campaign_meta.js', /function hpBar[^\n]*f<(\.\d+)/], ['godot/ui/campaign/campaign_ui.gd', /HULL_LOW if f < (0\.\d+)/]],
  ['HD11', 'round banner size', ['head.html', /\.banner\{[^}]*font-size:(\d+)px/], ['godot/ui/battle/hud.gd', /banner_lbl = _label\("", (\d+)/]],
  ['HD13', 'hover tip width', ['head.html', /\.tip\{[^}]*max-width:(\d+)px/], ['godot/ui/battle/hud.gd', /tip_text\.custom_minimum_size = Vector2\(s\((\d+)\)/]],
  ['MN7', 'end card heading size', ['head.html', /#endcard h1\{[^}]*font-size:(\d+)px|\.endcard h2\{[^}]*font-size:(\d+)px/], ['godot/ui/battle/hud.gd', /_label\(title\.to_upper\(\), (\d+), GILT if win/]],
  ['TY3', 'campaign body text size', ['head.html', /\nbody\{margin:0;height:100%;background:var\(--ink\)[^}]*font-size:(\d+)px/], ['godot/ui/campaign/campaign_ui.gd', /GS\.make_theme\(k, font, font_semi, (\d+)\)/]],
  ['TY4', 'scale ceiling (all screens)', ['head.html', null, 'none (fixed px, two media queries)'], ['godot/ui/ui_scale.gd', /const K_MAX := (\d+(?:\.\d+)?)/]],
  ['AC5', 'battle focus ring width', ['head.html', /button:focus-visible\{outline:(\d+)px/], ['godot/ui/theme/glass_shell.gd', /f\.set_border_width_all\(maxi\((\d+)/]],
  ['HD10', 'friend name colour', ['head.html', /(#8ff0a0)/i], ['godot/ui/theme/glass_shell.gd', /const FRIEND := (Color\([^)]*\))/]],
  ['HD10', 'foe name colour', ['head.html', /(#c9a2ff)/i], ['godot/ui/theme/glass_shell.gd', /const FOE := (Color\([^)]*\))/]],
  ['H6', 'blood text colour', ['head.html', /\.blood\{color:(#[0-9a-f]{6})\}/i], ['godot/ui/theme/glass_shell.gd', /const BLOOD := Color\("(#[0-9a-f]{6})"\)/i]],
];
function readPair(side) {
  const [f, re, fixed] = side;
  if (re === null) return { v: fixed, at: f };
  if (!fs.existsSync(path.join(ROOT, f))) return { v: 'NOT FOUND (no file)', at: f };
  const t = read(f); const m = re.exec(t);
  if (!m) return { v: 'NOT FOUND', at: f };
  const v = m.slice(1).find(x => x !== undefined);
  return { v, at: f + ':' + lineOf(t, m.index) };
}
const norm = v => {
  const c = /^Color\(([\d.]+),\s*([\d.]+),\s*([\d.]+)\)$/.exec(v);
  if (c) return '#' + toHex(+c[1]) + toHex(+c[2]) + toHex(+c[3]);
  return /^\d*\.?\d+$/.test(String(v)) ? String(+v) : String(v).toLowerCase();
};

// ---------------------------------------------------------------- report
function build() {
  const MIN = +(/const MIN_TEXT := (\d+)/.exec(read('godot/ui/ui_scale.gd')) || [0, 12])[1];
  const gd = godotFiles();
  const pal = palette();
  const palKeys = Object.keys(pal);
  const near = h => palKeys.map(p => [p, dist(h, p)]).sort((a, b) => a[1] - b[1])[0];
  const L = [];
  L.push('# UI constants: the two-build table (generated)', '');
  L.push('Generated by `node contrib/opus/tools/ui_constants_diff.js` from the files named below. Do not edit by hand: change the code, then run the script again. The choices for each difference are recorded in [ui_spec.md](ui_spec.md) section 3. Browser files: ' + JS_FILES.join(', ') + '. Port files: every .gd under godot/ui and godot/main except tests and capture scripts (' + gd.length + ' files).', '');
  L.push('## 1. Named pairs (the audit items)', '', 'item | what | browser | port | same?', '--- | --- | --- | --- | ---');
  for (const [id, what, a, b] of PAIRS) {
    const x = readPair(a), y = readPair(b);
    const same = /NOT FOUND/.test(x.v + y.v) ? 'NOT FOUND' : (norm(x.v) === norm(y.v) ? 'SAME' : 'DIFFERENT');
    L.push(`${id} | ${what} | ${x.v} (${x.at}) | ${y.v} (${y.at}) | ${same}`);
  }
  L.push('', 'Colour tables below leave out the 3D map scene and crest art files (map3d_props, map3d_system, map3d_shaders, both crest.gd): those are materials and emblem paint under the R3 map rule (ui_spec.md 5.4).');
  L.push('', '## 2. The palette', '', 'Named colours: the browser\'s CSS variables and the port\'s colour constants (hud.gd, campaign_ui.gd).', '', 'hex | named as', '--- | ---');
  for (const h of palKeys.sort()) L.push(`${h} | ${pal[h].join(', ')}`);
  for (const [label, files] of [['browser', JS_FILES], ['port', gd.filter(f => !ART_FILES.test(f))]]) {
    const uses = hexUses(files);
    const rows = Object.entries(uses).sort((a, b) => b[1].length - a[1].length);
    const off = rows.filter(([h]) => !pal[h]);
    L.push('', `## ${label === 'browser' ? 3 : 4}. Hex colours in the ${label} build`, '', `${rows.length} distinct hex colours, ${off.length} of them off the palette. Off-palette colours, most used first (nearest palette colour and its RGB distance; under 20 reads as the same colour):`, '', 'hex | uses | nearest palette colour | distance | first use', '--- | --- | --- | --- | ---');
    for (const [h, at] of off) { const n = near(h); L.push(`${h} | ${at.length} | ${n[0]} (${pal[n[0]][0]}) | ${n[1]} | ${at[0]}`); }
  }
  const fc = floatColours(gd.filter(f => !ART_FILES.test(f)));
  const fcg = {};
  for (const r of fc) { const k = r.hex + (r.alpha ? ' a' + r.alpha : ''); (fcg[k] = fcg[k] || []).push(r.at); }
  L.push('', '## 5. Float colours in the port', '', `${Object.keys(fcg).length} distinct Color(r, g, b) literals, shown as hex with alpha. These were transcribed by eye from the browser's rgba() values (HD10, HD15); a colour that should be a palette entry is marked with its nearest one.`, '', 'colour | uses | nearest palette colour | distance | first use', '--- | --- | --- | --- | ---');
  for (const [k, at] of Object.entries(fcg).sort((a, b) => b[1].length - a[1].length)) { const n = near(k.slice(0, 7)); L.push(`${k} | ${at.length} | ${n[0]} | ${n[1]} | ${at[0]}`); }
  const js = jsSizes(JS_FILES), gs = godotSizes(gd);
  const hist = rows => { const h = {}; for (const r of rows) h[r.v] = (h[r.v] || 0) + 1; return Object.entries(h).sort((a, b) => +a[0] - +b[0]).map(([v, n]) => `${v} (${n})`).join(', '); };
  L.push('', '## 6. Text sizes', '', `Sizes at the 1080 design height. The text floor in godot/ui/ui_scale.gd is ${MIN} (TY6).`, '', `- Browser (${js.length} literals, px): ${hist(js)}`, `- Port (${gs.length} literals): ${hist(gs)}`, '');
  const lowJ = js.filter(r => r.v < MIN), lowG = gs.filter(r => r.v < MIN);
  L.push(`Under the floor in the browser build (frozen; recorded, not changed): ${lowJ.length}.`, '');
  for (const r of lowJ) L.push(`- ${r.v} px, ${r.at}`);
  L.push('', `Under the floor in the port: ${lowG.length}.`, '');
  for (const r of lowG) L.push(`- ${r.v}, ${r.at} (${r.how})` + (r.text && /^"[^\w\s]"$/.test(r.text) ? ', a one-glyph ornament (' + r.text + '), not text: exempt' : ''));
  L.push('');
  return { text: L.join('\n'), lowG, pairs: PAIRS.map(([id, what, a, b]) => ({ id, what, a: readPair(a), b: readPair(b) })) };
}

module.exports = { build, godotFiles, godotSizes, jsSizes, palette, hexUses };
if (require.main === module) {
  const r = build();
  if (process.argv.includes('--stdout')) process.stdout.write(r.text);
  else { fs.writeFileSync(OUT, r.text); console.log('ui_constants_diff: wrote ' + path.relative(ROOT, OUT) + ' (' + r.lowG.length + ' port sizes under the floor)'); }
}
