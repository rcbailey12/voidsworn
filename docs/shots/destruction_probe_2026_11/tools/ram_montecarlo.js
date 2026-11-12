// Issue 234 S-C ram Monte Carlo, built on the G3 campaign harness (Muse's unmodified
// baseline driver, contributing/muse/tools/montecarlo) and the shipped ram rules.
// Two products:
//   1. An exhaustive matchup matrix from the shipped ramEstimate (PF4 damage, PF5 recoil).
//   2. Appetite counts from full G3 campaign runs: every tacticRam opportunity, threshold
//      decision and landed ram, plus the observed outcome of every landed ram.
// No game file is changed. Usage:
//   node ram_montecarlo.js --runs 50 --seed 234000 --out ram_outcomes.json
'use strict';
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '../../../..');
const mc = path.join(root, 'contrib/muse/tools/montecarlo');
const { loadGame } = require(path.join(mc, 'loader_main.js'));

function read(name) { return fs.readFileSync(path.join(mc, name), 'utf8').replace(/^\uFEFF/, ''); }
function arg(name, dflt) { const i = process.argv.indexOf('--' + name); return i >= 0 ? process.argv[i + 1] : dflt; }

const RAM_INSTRUMENT = String.raw`
// Issue 234 S-C: instrument the shipped ram decision and landing. The game files are
// untouched; these are the same function bindings battle.js calls at runtime.
globalThis.__ram = null;
globalThis.__ramReset = function () {
  globalThis.__ram = {
    opportunities: 0, threshold_pass: 0, tactic_true: 0, landed: 0, failed: 0,
    opp_by_fac: {}, opp_by_side: {}, pass_by_fac: {}, pass_by_band: {kill: 0, ram30: 0, other45: 0},
    landed_by_fac: {}, landed_by_side: {}, records: []
  };
};
globalThis.__ramReset();
const __ramOrigTactic = tacticRam;
tacticRam = async function (u) {
  const info = ramInfo(u);
  if (!info || info.path.length < 2) return __ramOrigTactic(u);
  const e = ramEstimate(u, info.t, info.path.length);
  const bold = !!RAM_FAC[u.fac];
  const th = bold ? 0.3 : 0.45;
  const st = globalThis.__ram;
  st.opportunities++;
  st.opp_by_fac[u.fac] = (st.opp_by_fac[u.fac] || 0) + 1;
  st.opp_by_side[u.side || '?'] = (st.opp_by_side[u.side || '?'] || 0) + 1;
  if (e.dmg >= info.t.hp) st.pass_by_band.kill++;
  else if (e.dmg >= info.t.hp * th) st.pass_by_band[bold ? 'ram30' : 'other45']++;
  const pass = e.dmg >= info.t.hp || e.dmg >= info.t.hp * th;
  if (pass) {
    st.threshold_pass++;
    st.pass_by_fac[u.fac] = (st.pass_by_fac[u.fac] || 0) + 1;
  }
  const r = await __ramOrigTactic(u);
  if (r) st.tactic_true++;
  return r;
};
const __ramOrigUnit = ramUnit;
ramUnit = async function (u) {
  const info = ramInfo(u);
  let rec = null;
  if (info) {
    const e = ramEstimate(u, info.t, info.path.length);
    rec = {
      att_tpl: u.tpl || u.name, tgt_tpl: info.t.tpl || info.t.name,
      att_cls: (HULLS[u.tpl] || {}).cls || '?', tgt_cls: (HULLS[info.t.tpl] || {}).cls || '?',
      att_fac: u.fac, tgt_fac: info.t.fac, side: u.side,
      att_hp0: u.hp, att_max: u.maxHp, att_size: u.size, att_armor: u.armor,
      tgt_hp0: info.t.hp, tgt_max: info.t.maxHp, tgt_size: info.t.size, tgt_armor: info.t.armor,
      run: info.path.length, est_dmg: e.dmg, est_recoil: e.recoil, est_soak: e.soak,
      sec: e.sec, quad: shieldQuad(info.t, u), threshold_frac: RAM_FAC[u.fac] ? 0.3 : 0.45
    };
  }
  const r = await __ramOrigUnit(u);
  if (rec) {
    const st = globalThis.__ram;
    rec.landed = !!r;
    rec.att_hp1 = u.hp; rec.tgt_hp1 = info ? info.t.hp : null;
    rec.tgt_dead = info ? !!info.t.dead : null; rec.att_dead = !!u.dead;
    rec.actual_dmg = info ? Math.max(0, rec.tgt_hp0 - info.t.hp) : null;
    rec.actual_recoil = Math.max(0, rec.att_hp0 - u.hp);
    if (r) {
      st.landed++;
      st.landed_by_fac[u.fac] = (st.landed_by_fac[u.fac] || 0) + 1;
      st.landed_by_side[u.side || '?'] = (st.landed_by_side[u.side || '?'] || 0) + 1;
      st.records.push(rec);
    } else st.failed++;
  }
  return r;
};
// Exhaustive matchup matrix through the real ramEstimate. Units are built from HULLS
// (baseline hp/shield/armor/size, no boons), with positions chosen to face the target's
// prow, starboard, rear or port shield.
globalThis.__ramMatrix = function () {
  const hulls = Object.keys(HULLS).filter(id => !HULLS[id].sq);
  const out = [];
  const quads = [
    { q: 0, r: 0, name: 'prow', att: { q: 1, r: 0 } },
    { q: 0, r: 1, name: 'starboard', att: { q: 0, r: 1 } },
    { q: 0, r: 2, name: 'rear', att: { q: -1, r: 0 } },
    { q: 0, r: 3, name: 'port', att: { q: 0, r: -1 } }
  ];
  const runs = [1, 2, 3];
  const hpFracs = [1.0, 0.4];
  for (const aid of hulls) {
    const A = HULLS[aid];
    for (const tid of hulls) {
      const T = HULLS[tid];
      for (const run of runs) {
        for (const qd of quads) {
          for (const shieldOn of [true, false]) {
            for (const frac of hpFracs) {
              const sh = shieldOn && T.sh ? [T.sh, T.sh, T.sh, T.sh] : null;
              const u = { q: qd.att.q, r: qd.att.r, facing: 0, size: A.size, fac: A.fac || 'voidsworn',
                armor: A.ar || 0, shMax: A.sh || 0, sh: A.sh ? [A.sh, A.sh, A.sh, A.sh] : null,
                maxHp: A.hp, hp: A.hp, fx: {}, side: 'player' };
              const t = { q: qd.q, r: qd.r, facing: 0, size: T.size, fac: T.fac || 'voidsworn',
                armor: T.ar || 0, shMax: T.sh || 0, sh: sh, maxHp: T.hp, hp: T.hp * frac, side: 'enemy' };
              const e = ramEstimate(u, t, run);
              out.push({
                att: aid, tgt: tid, att_cls: A.cls, tgt_cls: T.cls,
                att_fac: u.fac, tgt_fac: t.fac, att_size: A.size, tgt_size: T.size,
                run: run, quad: qd.name, shield: shieldOn, hp_frac: frac,
                dmg: e.dmg, dmg_frac_max: e.dmg / T.hp, soak: e.soak,
                recoil: e.recoil, recoil_frac_att: e.recoil / A.hp,
                kills_full: e.dmg >= T.hp, kills_this: e.dmg >= T.hp * frac,
                recoil_kills_full: e.recoil >= A.hp,
                cap_frac: 0.4, shieldless: !T.sh
              });
            }
          }
        }
      }
    }
  }
  return out;
};
globalThis.__ramDump = function () { return globalThis.__ram; };
`;

function aggregateAppetite(perRun) {
  const sum = { runs: perRun.length, battles: 0, rounds: 0, opportunities: 0, threshold_pass: 0, landed: 0, failed: 0,
    opp_by_fac: {}, opp_by_side: {}, pass_by_fac: {}, pass_by_band: {}, landed_by_fac: {}, landed_by_side: {}, records: [] };
  for (const r of perRun) {
    sum.battles += r.battles || 0; sum.rounds += r.rounds || 0;
    for (const k of ['opportunities', 'threshold_pass', 'landed', 'failed']) sum[k] += r.stats[k] || 0;
    for (const map of ['opp_by_fac', 'opp_by_side', 'pass_by_fac', 'landed_by_fac', 'landed_by_side']) {
      for (const [k, v] of Object.entries(r.stats[map] || {})) sum[map][k] = (sum[map][k] || 0) + v;
    }
    for (const [k, v] of Object.entries(r.stats.pass_by_band || {})) sum.pass_by_band[k] = (sum.pass_by_band[k] || 0) + v;
    sum.records.push(...(r.stats.records || []));
  }
  return sum;
}

function rm(v, d = 3) { return +v.toFixed(d); }

function aggRecords(records) {
  const n = records.length;
  if (!n) return { n: 0 };
  let dmg = 0, dmgf = 0, recoil = 0, recoilf = 0, kills = 0, attdead = 0, soak = 0, frac = 0;
  for (const r of records) {
    dmg += r.actual_dmg || 0; dmgf += (r.actual_dmg || 0) / (r.tgt_max || 1);
    recoil += r.actual_recoil || 0; recoilf += (r.actual_recoil || 0) / (r.att_max || 1);
    kills += r.tgt_dead ? 1 : 0; attdead += r.att_dead ? 1 : 0; soak += r.est_soak || 0;
    frac += (r.tgt_hp0 || 0) / (r.tgt_max || 1);
  }
  return { n, mean_dmg: rm(dmg / n, 1), mean_dmg_frac: rm(dmgf / n, 3), mean_recoil: rm(recoil / n, 1),
    mean_recoil_frac: rm(recoilf / n, 3), kill_rate: rm(kills / n, 3), attacker_death_rate: rm(attdead / n, 3),
    mean_target_hp_frac_at_ram: rm(frac / n, 3), mean_soak: rm(soak / n, 1) };
}
function groupAgg(records, key) {
  const groups = {};
  for (const r of records) { const k = key(r) || '?'; (groups[k] = groups[k] || []).push(r); }
  return Object.entries(groups).map(([k, list]) => Object.assign({ key: k }, aggRecords(list))).sort((a, b) => b.n - a.n);
}
function summarizeRecords(records) {
  const byMatch = {};
  for (const r of records) {
    const key = (r.att_tpl || '?') + ' -> ' + (r.tgt_tpl || '?');
    const b = byMatch[key] || (byMatch[key] = { n: 0, dmg: 0, dmg_frac: 0, recoil: 0, recoil_frac: 0, kills: 0, att_dead: 0, soak: 0 });
    b.n++;
    b.dmg += r.actual_dmg || 0; b.dmg_frac += (r.actual_dmg || 0) / (r.tgt_max || 1);
    b.recoil += r.actual_recoil || 0; b.recoil_frac += (r.actual_recoil || 0) / (r.att_max || 1);
    b.kills += r.tgt_dead ? 1 : 0; b.att_dead += r.att_dead ? 1 : 0; b.soak += r.est_soak || 0;
  }
  const rows = Object.entries(byMatch).map(([k, b]) => ({ matchup: k, n: b.n, mean_dmg: rm(b.dmg / b.n, 1),
    mean_dmg_frac: rm(b.dmg_frac / b.n, 3), mean_recoil: rm(b.recoil / b.n, 1),
    mean_recoil_frac: rm(b.recoil_frac / b.n, 3), kill_rate: rm(b.kills / b.n, 3),
    attacker_death_rate: rm(b.att_dead / b.n, 3), mean_soak: rm(b.soak / b.n, 1) }))
    .sort((a, b) => b.n - a.n || a.matchup.localeCompare(b.matchup));
  return rows;
}

async function main() {
  const runs = Number(arg('runs', '50'));
  const seed0 = Number(arg('seed', '234000'));
  const outPath = path.resolve(arg('out', path.join(__dirname, '..', 'ram_outcomes.json')));
  const started = Date.now();
  const extra = [read('bot.js'), read('driver.js'), read('policies.js'), RAM_INSTRUMENT];
  const game = loadGame(root, { extra });
  const factions = game.api.get('RUN_FACTIONS.slice()');
  const names = game.api.get('FACTIONS');
  const adm = game.api.get('ADMIRALS');
  const perRun = [];
  let index = 0;
  for (const fac of factions) {
    const ids = Object.keys(adm).filter(id => (adm[id].fac || 'voidsworn') === fac);
    for (let i = 0; i < runs; i++) {
      const admiral = ids[i % ids.length];
      game.api.get('globalThis.__ramReset()');
      const S = await game.api.runOne({ fac, admiral, ai: 'veteran', seed: seed0 + index, policy: 'baseline', priceMult: 1, cpDelta: 0, credMult: 1 });
      index++;
      const stats = game.api.get('globalThis.__ramDump()');
      let rounds = 0; for (const b of S.battles) rounds += b.rounds || 0;
      perRun.push({ fac, admiral, seed: seed0 + index - 1, won: !!S.won, sector: S.sectorReached,
        battles: S.battles.length, rounds, errors: S.errors.length, stats });
      if ((i + 1) % 10 === 0) console.error(`${fac}: ${i + 1}/${runs}, ${((Date.now() - started) / 1000).toFixed(1)}s`);
    }
  }
  const appetite = aggregateAppetite(perRun);
  const matrix = game.api.get('globalThis.__ramMatrix()');
  const actual = summarizeRecords(appetite.records);
  // Class-level matrix from the exhaustive cells, used for the plot and the read.
  const byClass = {};
  for (const cell of matrix) {
    const key = cell.att_cls + ' -> ' + cell.tgt_cls;
    const b = byClass[key] || (byClass[key] = { n: 0, dmg: 0, dmg_frac: 0, recoil_frac: 0, kills_full: 0, kills_40: 0, shield_soak: 0 });
    b.n++; b.dmg += cell.dmg; b.dmg_frac += cell.dmg_frac_max; b.recoil_frac += cell.recoil_frac_att;
    b.kills_full += cell.kills_full ? 1 : 0; b.kills_40 += (cell.hp_frac <= 0.4 && cell.kills_this) ? 1 : 0;
    b.shield_soak += cell.soak;
  }
  const classRows = Object.entries(byClass).map(([k, b]) => ({ matchup: k, cells: b.n,
    mean_dmg: rm(b.dmg / b.n, 1), mean_dmg_frac: rm(b.dmg_frac / b.n, 3),
    mean_recoil_frac: rm(b.recoil_frac / b.n, 3),
    kill_rate_at_full: rm(b.kills_full / b.n, 4),
    kill_rate_at_40: rm(b.kills_40 / b.n, 3), mean_soak: rm(b.shield_soak / b.n, 1) }))
    .sort((a, b) => a.matchup.localeCompare(b.matchup));
  const byAttFac = {};
  for (const cell of matrix) {
    const k = cell.att_fac;
    const b = byAttFac[k] || (byAttFac[k] = { key: k, cells: 0, dmg: 0, dmg_frac: 0, recoil_frac: 0, kills_full: 0, kills_40: 0, shield_soak: 0 });
    b.cells++; b.dmg += cell.dmg; b.dmg_frac += cell.dmg_frac_max; b.recoil_frac += cell.recoil_frac_att;
    b.kills_full += cell.kills_full ? 1 : 0; b.kills_40 += (cell.hp_frac <= 0.4 && cell.kills_this) ? 1 : 0;
    b.shield_soak += cell.soak;
  }
  const matrixByAttFac = Object.values(byAttFac).map(b => ({ key: b.key, cells: b.cells,
    mean_dmg: rm(b.dmg / b.cells, 1), mean_dmg_frac: rm(b.dmg_frac / b.cells, 3),
    mean_recoil_frac: rm(b.recoil_frac / b.cells, 3),
    kill_rate_at_full: rm(b.kills_full / b.cells, 4), kill_rate_at_40: rm(b.kills_40 / b.cells, 3),
    mean_soak: rm(b.shield_soak / b.cells, 1) })).sort((a, b) => a.key.localeCompare(b.key));
  const payload = {
    generated: new Date().toISOString(),
    harness: 'contrib/muse/tools/montecarlo (G3 campaign driver, baseline policy, veteran AI)',
    seed0, runs_per_faction: runs, factions,
    appetite: {
      runs: appetite.runs, battles: appetite.battles, rounds: appetite.rounds,
      opportunities: appetite.opportunities, threshold_pass: appetite.threshold_pass,
      landed: appetite.landed, failed: appetite.failed,
      opportunity_rate_per_battle: rm(appetite.opportunities / Math.max(appetite.battles, 1), 3),
      pass_rate_of_opportunities: rm(appetite.threshold_pass / Math.max(appetite.opportunities, 1), 3),
      landed_rate_of_opportunities: rm(appetite.landed / Math.max(appetite.opportunities, 1), 3),
      opp_by_fac: appetite.opp_by_fac, pass_by_fac: appetite.pass_by_fac,
      landed_by_fac: appetite.landed_by_fac, opp_by_side: appetite.opp_by_side,
      landed_by_side: appetite.landed_by_side, pass_by_band: appetite.pass_by_band
    },
    actual_rams: { n: appetite.records.length, matchups: actual.length,
      overall: aggRecords(appetite.records),
      by_att_fac: groupAgg(appetite.records, r => r.att_fac),
      by_att_cls: groupAgg(appetite.records, r => r.att_cls),
      by_tgt_fac: groupAgg(appetite.records, r => r.tgt_fac),
      by_tgt_cls: groupAgg(appetite.records, r => r.tgt_cls),
      by_matchup: actual },
    matrix: { cells: matrix.length, by_class: classRows, by_att_fac: matrixByAttFac },
    per_run: perRun.map(r => ({ fac: r.fac, admiral: r.admiral, seed: r.seed, won: r.won,
      battles: r.battles, rounds: r.rounds, opportunities: r.stats.opportunities,
      threshold_pass: r.stats.threshold_pass, landed: r.stats.landed, failed: r.stats.failed,
      records_len: (r.stats.records || []).length, errors: r.errors }))
  };
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, JSON.stringify(payload, null, 2));
  console.log('RAM_MC runs=' + appetite.runs + ' battles=' + appetite.battles + ' rounds=' + appetite.rounds +
    ' opportunities=' + appetite.opportunities + ' pass=' + appetite.threshold_pass + ' landed=' + appetite.landed +
    ' failed=' + appetite.failed + ' matrix_cells=' + matrix.length);
  console.log('RAM_MC by_fac_opp=' + JSON.stringify(appetite.opp_by_fac) + ' by_fac_pass=' + JSON.stringify(appetite.pass_by_fac));
  console.log('RAM_MC actual_rams=' + actual.length + ' wrote ' + outPath);
  console.log('RAM_MC seconds=' + ((Date.now() - started) / 1000).toFixed(1));
}
async function matrixOnly() {
  const extra = [read('bot.js'), read('driver.js'), read('policies.js'), RAM_INSTRUMENT];
  const game = loadGame(root, { extra });
  const matrix = game.api.get('globalThis.__ramMatrix()');
  let maxRecoil = 0, maxCell = null, fullKills = 0, fullKillCells = 0;
  const byAtt = {};
  for (const c of matrix) {
    if (c.recoil_frac_att > maxRecoil) { maxRecoil = c.recoil_frac_att; maxCell = c; }
    if (c.recoil_kills_full) { fullKills++; if (c.hp_frac === 1) { fullKillCells++; (byAtt[c.att] = byAtt[c.att] || { att_cls: c.att_cls, att_fac: c.att_fac, cells: 0, max_frac: 0 }); byAtt[c.att].cells++; byAtt[c.att].max_frac = Math.max(byAtt[c.att].max_frac, c.recoil_frac_att); } }
  }
  console.log(JSON.stringify({ cells: matrix.length, max_recoil_frac: maxRecoil, max_recoil_cell: maxCell,
    recoil_kills_full_cells: fullKills, recoil_kills_full_at_full_hp_cells: fullKillCells,
    recoil_full_kills_by_attacker: byAtt }, null, 2));
}
if (process.argv.includes('--matrix-only')) matrixOnly().catch(e => { console.error(e && e.stack || e); process.exitCode = 1; });
else main().catch(e => { console.error(e && e.stack || e); process.exitCode = 1; });
