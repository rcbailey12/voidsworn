'use strict';
// Issue 238, BD6: report only. A star density count for the per-frame sky shader's three star layers.
//
// The shader (godot/world/world_sky.gd, SKY) tests one candidate per cell of a 3D grid laid over the unit sphere:
//   layer scale 120, threshold 0.955, gain 1.00, band density 0.03
//   layer scale 300, threshold 0.985, gain 0.55, band density 0.012
//   layer scale 650, threshold 0.994, gain 0.35, band density 0.004
// A cell is kept when h.x >= threshold - density, where density = exp(-(y/0.25)^2) * region band * layer factor and
// y is the direction's galactic latitude. This script counts the cells whose unit cube around radius `scale` a view
// direction can test, multiplies each by that pass probability, and reports stars per steradian and per battle view.
// It also counts a relaxed set (each threshold 0.01 lower) so the size of a threshold change is visible before the
// owner review round. No game file is changed.

const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');

const LAYERS = [
  { scale: 120, thr: 0.955, gain: 1.0, dens: 0.03 },
  { scale: 300, thr: 0.985, gain: 0.55, dens: 0.012 },
  { scale: 650, thr: 0.994, gain: 0.35, dens: 0.004 },
];
// WorldSky.REGION: the per-region galactic band brightness (the other per-region values do not enter the star count).
const REGIONS = { frontier: 0.6, nebula: 0.4, world: 0.8, boneyard: 0.45, deep: 1.0, deadstar: 0.7 };
const BATTLE_VIEW_SR = 1.14; // about 0.8 rad vertical by 16:9 at 1920x1080, the default camera's sky footprint

function interval(a) { const lo = Math.min(Math.abs(a), Math.abs(a + 1)); const hi = Math.max(Math.abs(a), Math.abs(a + 1)); return [lo * lo, hi * hi]; }

// Every integer cell whose box intersects the sphere of radius `scale`, with its unit direction.
function shell(scale) {
  const R = Math.ceil(scale + 1);
  const out = [];
  const s2 = scale * scale;
  for (let x = -R; x <= R; x++) {
    const [x0, x1] = interval(x);
    for (let y = -R; y <= R; y++) {
      const [y0, y1] = interval(y);
      const minXY = x0 + y0, maxXY = x1 + y1;
      if (minXY > s2) continue;
      const zlo = Math.sqrt(Math.max(0, s2 - maxXY));
      const zhi = Math.sqrt(Math.max(0, s2 - minXY));
      const z0 = Math.floor(zlo) - 1, z1 = Math.ceil(zhi) + 1;
      for (let z = -z1; z <= z0; z++) addCell(out, x, y, z, scale, s2);
      for (let z = Math.max(0, z0); z <= z1; z++) addCell(out, x, y, z, scale, s2);
    }
  }
  return out;
}

function addCell(out, x, y, z, scale, s2) {
  const [x0, x1] = interval(x), [y0, y1] = interval(y), [z0, z1] = interval(z);
  const min = x0 + y0 + z0, max = x1 + y1 + z1;
  if (min > s2 || max < s2) return;
  const len = Math.hypot(x + 0.5, y + 0.5, z + 0.5);
  if (len === 0) return;
  out.push({ y: (y + 0.5) / len });
}

function count(scale, thr, dens, band, relaxed) {
  const t = relaxed ? thr - 0.01 : thr;
  let expected = 0;
  for (const c of scale.cells) {
    const bd = Math.exp(-Math.pow(c.y / 0.25, 2)) * band;
    const p = Math.min(1, Math.max(0, 1 - (t - bd * dens)));
    expected += p;
  }
  return expected;
}

function main() {
  const args = process.argv.slice(2);
  let out = '';
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--out') out = path.resolve(args[++i]);
    else { console.error('Usage: node star_count_report.js [--out FILE.json]'); process.exit(1); }
  }
  for (const l of LAYERS) l.cells = shell(l.scale);

  const rows = [];
  for (const [region, band] of Object.entries(REGIONS)) {
    const byLayer = LAYERS.map(l => ({ scale: l.scale, thr: l.thr, gain: l.gain, dens: l.dens,
      stars: +count(l, l.thr, l.dens, band, false).toFixed(1),
      stars_relaxed: +count(l, l.thr, l.dens, band, true).toFixed(1) }));
    const total = byLayer.reduce((s, r) => s + r.stars, 0);
    const relaxed = byLayer.reduce((s, r) => s + r.stars_relaxed, 0);
    rows.push({ region, band, by_layer: byLayer, stars_total: +total.toFixed(1),
      stars_per_sr: +(total / (4 * Math.PI)).toFixed(2), stars_in_battle_view: +(total / (4 * Math.PI) * BATTLE_VIEW_SR).toFixed(1),
      relaxed_total: +relaxed.toFixed(1), relaxed_per_sr: +(relaxed / (4 * Math.PI)).toFixed(2),
      relaxed_in_battle_view: +(relaxed / (4 * Math.PI) * BATTLE_VIEW_SR).toFixed(1),
      relaxed_change_pct: +((relaxed / total - 1) * 100).toFixed(1) });
  }
  const report = { item: 'BD6 star density count', method: 'expected kept grid cells, one per 3D cell whose cube intersects the layer sphere; pass probability 1-(threshold-density)',
    battle_view_sr: BATTLE_VIEW_SR, layers: LAYERS.map(l => ({ scale: l.scale, threshold: l.thr, gain: l.gain, band_density: l.dens, cells_near_sphere: l.cells.length })), regions: rows };
  if (out) fs.writeFileSync(out, JSON.stringify(report, null, 2) + '\n');
  for (const l of report.layers) console.log(`BD6 layer scale=${l.scale} threshold=${l.threshold} gain=${l.gain} band_density=${l.band_density} candidate_cells=${l.cells_near_sphere}`);
  for (const r of rows) console.log(`BD6 region=${r.region} band=${r.band} stars=${r.stars_total} per_sr=${r.stars_per_sr} battle_view=${r.stars_in_battle_view} relaxed=${r.relaxed_total} (${r.relaxed_change_pct}%)`);
  console.log('PASS: report only, BD6 star count ran');
}

if (require.main === module) main();
module.exports = { shell, count, LAYERS, REGIONS };
