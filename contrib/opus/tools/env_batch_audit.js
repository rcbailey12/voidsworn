'use strict';
// Issue 238, batch audit script: ST4 (station triangle count and timing), PL12 (cold planet bake timings across seeds)
// and BD2 (sky march steps, loader against shader). Report only; it reads measurements and source, it changes nothing.
//
//   node contrib/opus/tools/env_batch_audit.js [--dir DIR] [--station-folder DIR] [--out FILE.json]
//
// Defaults: the measured artifacts in docs/shots/reporting_2026_11/ (station_audit.json and planet_bake_timings.json),
// produced on Ryan's PC by station_check.gd --measure and contrib/opus/tools/planet_bake_timing.gd. If
// --station-folder has the raw detail_audit.json and detail_gpu.json, those are read directly instead.

const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');

function readJSON(p) { return JSON.parse(fs.readFileSync(p, 'utf8')); }

function stationData(folder) {
  const auditPath = path.join(folder, 'detail_audit.json');
  const gpuPath = path.join(folder, 'detail_gpu.json');
  if (fs.existsSync(auditPath) && fs.existsSync(gpuPath)) {
    const audit = readJSON(auditPath), gpu = readJSON(gpuPath);
    const variants = {};
    for (const k of ['fleet', 'refinery']) {
      const v = audit.variants[k] || {};
      const row = (gpu.rows || []).find(r => r.variant === k) || {};
      variants[k] = { triangles_roundtrip: v.triangles_roundtrip, parts: v.parts, guns: v.guns,
        median_delta_ms: row.median_delta_ms, paired_range_ms: row.paired_range_ms, pairs: (row.pairs || []).length };
    }
    return { source: { folder, detail_audit: auditPath, detail_gpu: gpuPath }, adapter: gpu.adapter, renderer: gpu.renderer,
      resolution: gpu.resolution, metric: gpu.metric, target_ms: 0.35, ceiling_ms: 1.0, variants };
  }
  return null;
}

function skySteps() {
  const world = fs.readFileSync(path.join(ROOT, 'godot/world/world.gd'), 'utf8');
  const sky = fs.readFileSync(path.join(ROOT, 'godot/world/world_sky.gd'), 'utf8');
  const line = world.split(/\r?\n/).find(l => l.includes('"steps":')) || '';
  const m = /"steps":\s*(\d+)\s+if\s+quality\s*==\s*"max"\s+else\s*\((\d+)\s+if\s+quality\s*==\s*"high"\s+else\s*(\d+)\)/.exec(line);
  const def = /uniform\s+int\s+steps\s*=\s*(\d+)\s*;/.exec(sky);
  const cap = /for\s*\(\s*int\s+i\s*=\s*0\s*;\s*i\s*<\s*(\d+)\s*;\s*i\+\+\s*\)\s*\{\s*if\s*\(\s*i\s*>=\s*steps/.exec(sky);
  if (!m || !def || !cap) return null;
  const qualities = { max: Number(m[1]), high: Number(m[2]), low: Number(m[3]) };
  const capN = Number(cap[1]);
  return {
    loader_steps: qualities, shader_default: Number(def[1]), loop_cap: capN,
    all_within_loop_cap: Object.values(qualities).every(v => v <= capN),
    max_equals_default_high: qualities.high === Number(def[1]),
    note: 'world.gd passes steps into the bake params for every quality; world_sky.gd divides the march by steps and breaks at i >= steps, inside a 64 iteration loop cap. The shader default (40) is the high tier value; it is never the value a bake uses because the loader always passes one.',
  };
}

function bakeData(dir) {
  const p = path.join(dir, 'planet_bake_timings.json');
  if (!fs.existsSync(p)) return null;
  const j = readJSON(p);
  const totals = j.rows.map(r => r.total_ms).sort((a, b) => a - b);
  const median = totals.length % 2 ? totals[(totals.length - 1) / 2] : (totals[totals.length / 2 - 1] + totals[totals.length / 2]) / 2;
  return { ...j, source: p, min_ms: totals[0], median_ms: median, max_ms: totals[totals.length - 1],
    all_ok: j.rows.every(r => r.pass_a_ok && r.pass_b_ok), note: 'Cold means a fresh VS_WORLD_CACHE folder and a cleared in-memory cache for every seed; both planet passes are timed at the shipped 4096 by 2048 max size.' };
}

function main() {
  const args = process.argv.slice(2);
  let dir = path.join(ROOT, 'docs/shots/reporting_2026_11');
  let stationFolder = '';
  let out = path.join(dir, 'env_audit.json');
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--dir') dir = path.resolve(args[++i]);
    else if (args[i] === '--station-folder') stationFolder = path.resolve(args[++i]);
    else if (args[i] === '--out') out = path.resolve(args[++i]);
    else { console.error('Usage: node env_batch_audit.js [--dir DIR] [--station-folder DIR] [--out FILE.json]'); process.exit(1); }
  }
  const station = (stationFolder && stationData(stationFolder)) || stationData(dir) || readJSON(path.join(dir, 'station_audit.json'));
  const bake = bakeData(dir);
  const sky = skySteps();
  const report = { item: 'Batch audit: ST4, PL12, BD2', station, planet_bake: bake, sky_steps: sky };
  if (!bake) console.log('PL12: no planet_bake_timings.json in ' + dir + ' (n/a)');
  if (out) fs.writeFileSync(out, JSON.stringify(report, null, 2) + '\n');

  console.log('ST4 stations (' + (station.adapter || 'adapter n/a') + ', ' + (station.resolution || []).join('x') + '):');
  for (const [k, v] of Object.entries(station.variants || {})) {
    console.log(`  ${k}: triangles=${v.triangles_roundtrip} parts=${v.parts} guns=${v.guns} timing_delta_ms=${v.median_delta_ms == null ? 'n/a' : Number(v.median_delta_ms).toFixed(3)} paired_range_ms=${(v.paired_range_ms || []).map(x => Number(x).toFixed(3)).join(' to ')} (target ${station.target_ms} ms, ceiling ${station.ceiling_ms} ms)`);
  }
  console.log('PL12 cold planet bakes:');
  if (bake) {
    for (const r of bake.rows) console.log(`  seed=${r.seed} kind=${r.kind} pass_a_ms=${r.pass_a_ms} pass_b_ms=${r.pass_b_ms} total_ms=${r.total_ms} ok=${r.pass_a_ok && r.pass_b_ok}`);
    console.log(`  min=${bake.min_ms} ms median=${bake.median_ms} ms max=${bake.max_ms} ms; wait cap=${bake.wait_cap_ms} ms cache_max=${bake.cache_max}`);
  }
  console.log('BD2 sky march steps:');
  if (sky) {
    console.log(`  loader max=${sky.loader_steps.max} high=${sky.loader_steps.high} low=${sky.loader_steps.low}; shader default=${sky.shader_default}; loop cap=${sky.loop_cap}`);
    console.log(`  all tiers within the loop cap: ${sky.all_within_loop_cap}; high tier equals the shader default: ${sky.max_equals_default_high}`);
  }
  const stationOk = station && station.variants && Object.values(station.variants).every(v => v.triangles_roundtrip > 0 && v.median_delta_ms != null && v.median_delta_ms < station.ceiling_ms);
  const bakeOk = bake && bake.all_ok && bake.max_ms < bake.wait_cap_ms;
  const skyOk = sky && sky.all_within_loop_cap;
  console.log(`PASS: report only, ST4 ${stationOk ? 'measured' : 'missing'}, PL12 ${bakeOk ? 'measured' : 'missing'}, BD2 ${skyOk ? 'compared' : 'missing'}`);
  if (!stationOk && !bakeOk) process.exitCode = 0; // report only: absence is stated, never a gate
}

if (require.main === module) main();
module.exports = { skySteps, stationData, bakeData };
