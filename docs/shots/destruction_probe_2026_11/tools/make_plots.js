// Issue 234: draws the report's SVG plots from the probe JSON. No dependencies.
// Usage: node make_plots.js
'use strict';
const fs = require('fs');
const path = require('path');
const here = __dirname;
const dataDir = path.resolve(here, '..');
const outDir = path.join(dataDir, 'plots');
fs.mkdirSync(outDir, { recursive: true });

const physics = JSON.parse(fs.readFileSync(path.join(dataDir, 'physics.json'), 'utf8'));
const wrecks = JSON.parse(fs.readFileSync(path.join(dataDir, 'wrecks.json'), 'utf8'));
const ram = JSON.parse(fs.readFileSync(path.join(dataDir, 'ram_outcomes.json'), 'utf8'));

const W = 980, H = 560, PAD = 70;
const COL = { bg: '#0d1117', panel: '#161b22', ink: '#e6edf3', dim: '#8b949e', grid: '#30363d',
  a: '#58a6ff', b: '#f0883e', c: '#3fb950', d: '#db61a2', warn: '#f85149' };
function svg(w, h, body) { return `<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">\n<rect width="${w}" height="${h}" fill="${COL.bg}"/>\n${body}\n</svg>\n`; }
function txt(x, y, s, size = 13, fill = COL.ink, anchor = 'start', weight = 'normal') {
  return `<text x="${x.toFixed(1)}" y="${y.toFixed(1)}" font-family="Consolas,monospace" font-size="${size}" fill="${fill}" text-anchor="${anchor}" font-weight="${weight}">${String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')}</text>`;
}
function line(x1, y1, x2, y2, stroke = COL.grid, width = 1, dash = '') {
  return `<line x1="${x1.toFixed(1)}" y1="${y1.toFixed(1)}" x2="${x2.toFixed(1)}" y2="${y2.toFixed(1)}" stroke="${stroke}" stroke-width="${width}"${dash ? ` stroke-dasharray="${dash}"` : ''}/>`;
}
function rect(x, y, w, h, fill) { return `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${w.toFixed(1)}" height="${h.toFixed(1)}" fill="${fill}"/>`; }
function poly(pts, stroke, width = 2, fill = 'none') {
  return `<polyline points="${pts.map(p => p[0].toFixed(1) + ',' + p[1].toFixed(1)).join(' ')}" fill="${fill}" stroke="${stroke}" stroke-width="${width}"/>`;
}
function circle(x, y, r, fill) { return `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r}" fill="${fill}"/>`; }

function axes(title, xlab, ylab, xs, ys, xmax, ymax, yfmt = v => v.toFixed(2), xmaxTick = xmax, yTicks = 5) {
  let s = rect(PAD, 20, W - PAD * 2, H - PAD - 50, COL.panel);
  s += txt(PAD, 40, title, 16, COL.ink, 'start', 'bold');
  s += txt(PAD, H - 28, xlab, 12, COL.dim);
  s += `<g transform="translate(18,${(H - PAD + 20) / 2}) rotate(-90)">${txt(0, 0, ylab, 12, COL.dim, 'middle')}</g>`;
  const L = PAD + 20, R = W - PAD - 20, T = 62, B = H - PAD - 20;
  for (let i = 0; i <= yTicks; i++) {
    const v = ymax * i / yTicks, y = B - (B - T) * i / yTicks;
    s += line(L, y, R, y, COL.grid, 1);
    s += txt(L - 8, y + 4, yfmt(v), 11, COL.dim, 'end');
  }
  const step = Math.max(1, Math.round(xmaxTick / 10));
  for (let x = 0; x <= xmaxTick; x += step) {
    const px = L + (R - L) * x / xmaxTick;
    s += txt(px, B + 18, String(x), 11, COL.dim, 'middle');
  }
  return { s, L, R, T, B };
}
function mapX(v, xmax, L, R) { return L + (R - L) * v / xmax; }
function mapY(v, ymax, T, B) { return B - (B - T) * v / ymax; }

// ---------- physics step vs body count ----------
{
  const rows = physics.rows.filter(r => r.kind === 'convex');
  const counts = physics.counts;
  const ymax = 1.0;
  const a = axes('Physics step vs body count (convex wreck colliders, Jolt, fixed 60 Hz)',
    'rigid bodies (wreck pieces + debris)', 'physics step, ms (median)', counts, null, 720, ymax, v => v.toFixed(2), 720, 5);
  let s = a.s;
  for (const [damp, col] of [[0.0, COL.a], [0.3, COL.b]]) {
    const pts = counts.map(n => {
      const r = rows.find(x => x.count === n && x.damp === damp);
      return [mapX(n, 720, a.L, a.R), mapY(r.median_ms, ymax, a.T, a.B)];
    });
    s += poly(pts, col, 2.5);
    for (const p of pts) s += circle(p[0], p[1], 2.6, col);
    s += txt(W - PAD - 20, 100 + (damp ? 18 : 0), `damp ${damp.toFixed(1)}`, 12, col, 'end', 'bold');
  }
  // p95 markers at 360 and 720
  for (const n of [360, 720]) {
    const r0 = rows.find(x => x.count === n && x.damp === 0.0);
    const r3 = rows.find(x => x.count === n && x.damp === 0.3);
    const px = mapX(n, 720, a.L, a.R);
    s += line(px, a.T, px, a.B, COL.dim, 1, '4 4');
    s += txt(px + 6, a.B - 8, `n=${n} p95 ${r0.p95_ms.toFixed(2)} / ${r3.p95_ms.toFixed(2)} ms`, 10, COL.dim);
  }
  s += txt(a.L + 8, a.B - 10, 'p95 shown for 360 and 720. R116 gate 12.5 ms is 31x the 360-body damp 0 median (0.400 ms).', 11, COL.dim);
  s += txt(W / 2, H - 10, 'source: destruction_cost_probe.gd, headless, --fixed-fps 60', 10, COL.dim, 'middle');
  fs.writeFileSync(path.join(outDir, 'physics_step_vs_bodies.svg'), svg(W, H, s));
}

// ---------- collider cost ----------
{
  const rows = physics.rows.filter(r => r.damp === 0.0);
  const counts = physics.counts;
  const ymax = 0.9;
  const a = axes('Collider cost vs body count (damp 0.0): convex hull collider vs no collider',
    'rigid bodies', 'physics step, ms (median)', counts, null, 720, ymax, v => v.toFixed(2), 720, 5);
  let s = a.s;
  for (const [kind, col, label] of [['convex', COL.a, 'convex hull, up to 50 points'], ['none', COL.c, 'no collision shape']]) {
    const pts = counts.map(n => {
      const r = rows.find(x => x.count === n && x.kind === kind);
      return [mapX(n, 720, a.L, a.R), mapY(r.median_ms, ymax, a.T, a.B)];
    });
    s += poly(pts, col, 2.5);
    for (const p of pts) s += circle(p[0], p[1], 2.4, col);
    s += txt(W - PAD - 20, 100 + (kind === 'none' ? 18 : 0), label, 12, col, 'end', 'bold');
  }
  const box = rows.find(x => x.count === 360 && x.kind === 'box');
  const bx = mapX(360, 720, a.L, a.R), by = mapY(box.median_ms, ymax, a.T, a.B);
  s += circle(bx, by, 4.5, COL.b);
  s += txt(bx + 8, by - 8, `360 box collider ${box.median_ms.toFixed(3)} ms`, 11, COL.b);
  s += txt(a.L + 8, a.B - 10, `collider build cost: ${physics.collider_build_ms_per_body.toFixed(2)} ms per piece (900-point hull to <=50 points, one-time, worker side)`, 11, COL.dim);
  s += txt(W / 2, H - 10, 'source: destruction_cost_probe.gd', 10, COL.dim, 'middle');
  fs.writeFileSync(path.join(outDir, 'collider_cost_vs_bodies.svg'), svg(W, H, s));
}

// ---------- wreck cap ----------
{
  const counts = wrecks.counts_after_each_death;
  const ymax = 24;
  const a = axes('Worst-case wipe: visual wreck list against the 24 cap',
    'staged death number', 'wrecks kept (fx.dstate wrecks)', counts, null, counts.length, ymax, v => String(Math.round(v)), counts.length, 6);
  let s = a.s;
  const pts = counts.map((v, i) => [mapX(i + 1, counts.length, a.L, a.R), mapY(v, ymax, a.T, a.B)]);
  s += poly(pts, COL.a, 2.5);
  for (const p of pts) s += circle(p[0], p[1], 2.2, COL.a);
  s += line(a.L, mapY(24, ymax, a.T, a.B), a.R, mapY(24, ymax, a.T, a.B), COL.warn, 2, '6 5');
  s += txt(a.R - 4, mapY(24, ymax, a.T, a.B) - 6, 'cap 24', 12, COL.warn, 'end', 'bold');
  s += txt(a.L + 8, a.B - 10, `final list ${wrecks.final_count}; oldest ids evicted: ${wrecks.ids_when_cap_first_reached ? 'yes' : 'no'}; set-piece hulks are a separate world list`, 11, COL.dim);
  s += txt(W / 2, H - 10, 'source: destruction_wreck_probe.gd, 30 staged deaths', 10, COL.dim, 'middle');
  fs.writeFileSync(path.join(outDir, 'wreck_cap.svg'), svg(W, H, s));
}

// ---------- ram heatmaps ----------
const CLS_ORDER = ['Frigate', 'Destroyer', 'Cruiser', 'Carrier', 'Battleship', 'Dreadnought', 'Battle-barge', 'Bio-titan', 'Ark', 'Tomb-ark', 'Super-dreadnought'];
function heatmap(title, field, max, file, note) {
  const rows = ram.matrix.by_class;
  const val = {};
  for (const r of rows) {
    const [a, b] = r.matchup.split(' -> ');
    val[a + '|' + b] = r[field];
  }
  const cw = 58, ch = 25, left = 150, top = 78;
  const w = left + cw * CLS_ORDER.length + 30, h = top + ch * CLS_ORDER.length + 70;
  let s = `<rect width="${w}" height="${h}" fill="${COL.bg}"/>`;
  s += txt(20, 30, title, 16, COL.ink, 'start', 'bold');
  s += txt(20, 50, note, 11, COL.dim);
  for (let c = 0; c < CLS_ORDER.length; c++) {
    s += `<g transform="translate(${left + c * cw + cw / 2},${top - 6}) rotate(-55)">${txt(0, 0, CLS_ORDER[c], 10, COL.dim, 'start')}</g>`;
  }
  for (let r = 0; r < CLS_ORDER.length; r++) {
    s += txt(left - 8, top + r * ch + ch * 0.68, CLS_ORDER[r], 10, COL.dim, 'end');
    for (let c = 0; c < CLS_ORDER.length; c++) {
      const v = val[CLS_ORDER[r] + '|' + CLS_ORDER[c]];
      if (v == null) continue;
      const t = Math.max(0, Math.min(1, v / max));
      const red = Math.round(30 + 220 * t), green = Math.round(70 + 80 * (1 - Math.abs(t - 0.5) * 2)), blue = Math.round(160 * (1 - t) + 30);
      s += rect(left + c * cw, top + r * ch, cw - 1, ch - 1, `rgb(${red},${green},${blue})`);
      s += txt(left + c * cw + cw / 2, top + r * ch + ch * 0.68, (v * 100).toFixed(0), 10, t > 0.55 ? '#ffffff' : '#e6edf3', 'middle');
    }
  }
  s += txt(20, h - 22, `rows: attacker class. columns: target class. cells: ${field === 'mean_dmg_frac' ? 'mean damage as percent of target max hull' : 'mean recoil as percent of attacker max hull'}. baseline hulls, no boons.`, 10, COL.dim);
  fs.writeFileSync(path.join(outDir, file), svg(w, h, s));
}
heatmap('Ram damage by class matchup (percent of target max hull)', 'mean_dmg_frac', 0.45, 'ram_damage_by_class.svg',
  'shipped ramEstimate; shields averaged; run-up 1, 2 and 3+; full and 40 percent target hull. No cell reaches 100 percent: the cap is 40 percent.');
heatmap('Ram recoil by class matchup (percent of attacker max hull)', 'mean_recoil_frac', 0.65, 'ram_recoil_by_class.svg',
  'shipped ramEstimate recoil; no boons. RAM_FAC factions use the 0.35 recoil factor, others 0.5.');

// ---------- appetite ----------
{
  const ap = ram.appetite;
  const rows = Object.keys(ap.opp_by_fac).sort();
  const W2 = 980, H2 = 460, left = 80, top = 70, right = 940, bottom = H2 - 70;
  let s = `<rect width="${W2}" height="${H2}" fill="${COL.bg}"/>`;
  s += txt(20, 30, 'Ram appetite in the G3 campaign harness', 16, COL.ink, 'start', 'bold');
  s += txt(20, 50, `${ap.runs} runs, ${ap.battles} battles, ${ap.rounds} rounds. ${ap.opportunities} ram opportunities, ${ap.threshold_pass} threshold passes, ${ap.landed} landed.`, 11, COL.dim);
  const maxV = Math.max(...rows.map(f => ap.opp_by_fac[f]));
  const groupW = (right - left) / rows.length;
  const barW = groupW * 0.24;
  for (let i = 0; i <= 4; i++) {
    const y = bottom - (bottom - top) * i / 4;
    s += line(left, y, right, y, COL.grid, 1);
    s += txt(left - 8, y + 4, String(Math.round(maxV * i / 4)), 11, COL.dim, 'end');
  }
  rows.forEach((f, i) => {
    const x0 = left + i * groupW + groupW * 0.12;
    const vals = [[ap.opp_by_fac[f], COL.a, 'opportunities'], [ap.pass_by_fac[f], COL.b, 'pass'], [ap.landed_by_fac[f], COL.c, 'landed']];
    vals.forEach(([v, col], j) => {
      const h = (bottom - top) * v / maxV;
      s += rect(x0 + j * barW, bottom - h, barW - 2, h, col);
    });
    s += txt(left + i * groupW + groupW / 2, bottom + 18, f, 10, COL.dim, 'middle');
  });
  s += txt(right - 8, top - 8, 'opportunities = a legal run-up; pass = AI threshold; landed = ram resolved', 10, COL.dim, 'end');
  const bands = ap.pass_by_band;
  const bandRows = [['kill', bands.kill, COL.d], ['ram faction 30%', bands.ram30, COL.b], ['other 45%', bands.other45, COL.a]];
  let by = top + 8;
  for (const [k, v, col] of bandRows) {
    s += rect(right - 300, by, 16, 16, col);
    s += txt(right - 278, by + 13, `${k}: ${v} (${(100 * v / Math.max(ap.threshold_pass, 1)).toFixed(1)}%)`, 11, COL.ink);
    by += 22;
  }
  s += txt(W2 / 2, H2 - 8, 'source: ram_montecarlo.js on contrib/muse/tools/montecarlo (baseline policy, veteran AI, seed 234000)', 10, COL.dim, 'middle');
  fs.writeFileSync(path.join(outDir, 'ram_appetite.svg'), svg(W2, H2, s));
}

console.log('plots written to ' + outDir);
