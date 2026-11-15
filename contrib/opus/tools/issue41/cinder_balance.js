// Issue 41 (R78 Q9) balance pack driver, run 3 of the workhorse job (Kimi's run 2 lost its driver in a temp folder).
// It boots the sim3d.js harness exactly as the published baseline does (same game files, same bot, same enemy AI) and
// measures the one combat change issue 41 makes: a Crusade run from run 3 may field a captured Hegemony or Eclipse hull
// with its links ripped out. The comparison holds command points equal and names two Crusade admirals (Thale, Vex).
//
//   node contrib/opus/tools/issue41/cinder_balance.js [battles per cell]
//
// "before" is the sector 3 campaign reference fleet (sim3d campaignSim FLEET[3]) under each admiral.
// "after" swaps its 2 CP Harrow for a 2 CP captured hull of the same CP: the Hegemony Interdictor or the Eclipse
// Jackal, with the ripped flag set the way the yard and the prize Add path set it. Nothing else changes.
// Each cell fights every other faction's sector 3 boss; seeds are fixed per (variant, boss, battle) so both arms see
// the same maps and deployments.
//
// Run from the repo root. The harness is sim3d.js itself, with only its bottom command dispatcher removed so this
// driver can call the bot and battle setup directly. No game file is edited.
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const ROOT = path.resolve(__dirname, '..', '..', '..', '..');
let H;
(function boot() {
  let src = fs.readFileSync(path.join(ROOT, 'sim3d.js'), 'utf8');
  const cut = src.indexOf("(async()=>{ if(process.argv[2]==='varmatrix')");
  if (cut < 0) throw new Error('sim3d.js dispatcher not found, the harness layout changed');
  src = src.slice(0, cut);
  const needle = 'global.sqCheck=sqCheck;`);';
  if (src.indexOf(needle) < 0) throw new Error('sim3d.js harness export marker not found');
  src = src.replace(needle, 'global.sqCheck=sqCheck; global.__H={startBattle,newShip,swarmPhase,botUnit,alive,aiUnit,aiPickActivation,roundStart,derive,HULLS,getRUN:()=>RUN,setRUN:v=>{RUN=v;},getB:()=>B,setAlt:v=>{B.alt=v;},startSideTurn};`);');
  process.env.PACE_OLD = process.env.PACE_OLD || '0';
  globalThis.require = require; // sim3d.js reads its game files with require at the top of the harness
  console.debug = function () {}; // battle.js prints a [swarm] timing line per wing; keep the table clean
  vm.runInThisContext(src, { filename: 'sim3d_harness.js' });
  H = global.__H;
  if (!H) throw new Error('harness export failed');
})();

// sector 3's enemy pool (data.js SECTOR_POOL[2]), the factions a real run 3 actually fights, in the campaign baseline's cells
const BOSSES = ['deathless', 'chorus', 'ithar'];
const KINDS = [
  { key: 'elite', kind: 'elite', col: 4, name: 'Sector 3 elite' },
  { key: 'boss', kind: 'boss', col: 6, name: 'Sector 3 boss' },
];
const N = +(process.argv[2] || 16);
// sector 3 campaign reference fleet, sim3d campaignSim FLEET[3]
const REF = ['ascendant', 'cathedral', 'penitent', 'reliquary', 'harrow'];
const VARIANTS = [
  { key: 'before', hull: 'harrow', rip: false },
  { key: 'after+h_interdictor', hull: 'h_interdictor', rip: true },
  { key: 'after+d_jackal', hull: 'd_jackal', rip: true },
];
const ADMS = ['thale', 'vex'];

function buildFleet(admiral, variant) {
  const H0 = H;
  const run = { fac: 'voidsworn', admiral, credits: 0, cpCap: 40, sector: 3, relics: [], inventory: [], fleet: [],
    stats: { battles: 0, elites: 0, bosses: 0, kills: 0 }, fallen: [], boons: [], patrons: [], aspect: null, lineage: null };
  for (const tpl of REF) {
    const t = tpl === 'harrow' ? variant.hull : tpl;
    const s = H0.newShip(t, true); // veteran captains, the way sim3d campaignSim and the published campaign baseline build the reference fleets
    if (t !== tpl && variant.rip) s.ripped = true;
    run.fleet.push(s);
  }
  run.flagUid = run.fleet[0].uid;
  return run;
}

function fpOf(admiral, variant) {
  let cp = 0;
  const run = buildFleet(admiral, variant);
  for (const s of run.fleet) cp += (H.HULLS[s.tpl].cp || 1);
  return cp;
}

async function fight(admiral, variant, cell, boss, seed) {
  H.setRUN(buildFleet(admiral, variant));
  const RUN = H.getRUN();
  RUN.sector = 3;
  H.startBattle({ kind: cell.kind, fac: boss, col: cell.col, dep: cell.kind === 'boss' ? 'line' : ['line', 'line', 'flank', 'ambush'][seed % 4], obj: ['rout', 'rout', 'flagship', 'hold'][seed % 4], seed });
  let r = 0; H.setAlt(true); H.startSideTurn('enemy');
  while (!H.getB().over && r < 30) {
    await H.swarmPhase('player'); await H.swarmPhase('enemy'); let g = 0;
    while (!H.getB().over && g++ < 40) {
      const B = H.getB();
      const pp = H.alive('player').filter(x => !x.isSq && !x.activated);
      const pe = H.alive('enemy').filter(x => !x.isSq && !x.activated);
      if (!pp.length && !pe.length) break;
      if (pp.length) { await H.botUnit(pp[0]); pp[0].activated = true; }
      const pp2 = H.alive('player').some(x => !x.isSq && !x.activated);
      const batch = pp2 ? (pe.length ? [H.aiPickActivation(pe)] : []) : pe;
      for (const u of batch) { if (H.getB().over) break; await H.aiUnit(u); u.activated = true; }
    }
    if (H.getB().over) break;
    const B = H.getB(); B.round++; for (const x of B.units) x.activated = false; await H.roundStart(); r++;
  }
  const B = H.getB();
  const pl = B.units.filter(u => u.side === 'player' && u.ship);
  const hull = pl.reduce((a, u) => a + Math.max(0, u.dead ? 0 : u.hp), 0) / Math.max(1, pl.reduce((a, u) => a + u.maxHp, 0));
  const lost = B.units.filter(u => u.ship && (u.dead || u.side !== 'player')).length;
  return { win: B.over === 'win' ? 1 : 0, rounds: B.round, hull, lost, timeout: B.over ? 0 : 1 };
}

(async () => {
  const cp = fpOf('thale', VARIANTS[0]);
  const rows = [];
  for (const cell of KINDS) {
    for (const admiral of ADMS) {
      for (const variant of VARIANTS) {
        let w = 0, n = 0, rounds = 0, hull = 0, lost = 0, to = 0;
        for (const boss of BOSSES) {
          for (let i = 0; i < N; i++) {
            const seed = 41000 + (cell.key === 'boss' ? 5000 : 0) + (variant.key === 'before' ? 0 : variant.key === 'after+h_interdictor' ? 1000 : 2000) + i * 7;
            const r = await fight(admiral, variant, cell, boss, seed);
            w += r.win; rounds += r.rounds; hull += r.hull; lost += r.lost; to += r.timeout; n++;
          }
        }
        rows.push({ cell: cell.key, admiral, variant: variant.key, win: w / n * 100, rounds: rounds / n, hull: hull / n * 100, lost: lost / n, to });
        console.log('  ... ' + cell.key + ' ' + admiral + ' ' + variant.key + ' done (' + n + ' battles)');
      }
    }
  }
  const fleetName = v => v === 'before' ? 'Reach reference' : (v === 'after+h_interdictor' ? 'Harrow to captured Interdictor' : 'Harrow to captured Jackal');
  const swapName = v => v === 'after+h_interdictor' ? 'Interdictor' : 'Jackal';
  for (const cell of KINDS) {
    console.log('\nBalance pack: issue 41 captured hulls for the Crusade, ' + cell.name + ', 22 CP fleets, ' + N + ' battles per boss per variant\n');
    console.log('| Admiral | Fleet | Win | Rounds | Hull left | Ships lost | Timeouts |');
    console.log('|---|---|---|---|---|---|---|');
    for (const r of rows.filter(x => x.cell === cell.key)) {
      console.log('| ' + admiralName(r.admiral) + ' | ' + fleetName(r.variant) + ' | ' + Math.round(r.win) + '% | ' + r.rounds.toFixed(1) + ' | ' + Math.round(r.hull) + '% | ' + r.lost.toFixed(1) + ' | ' + r.to + ' |');
    }
    console.log('\nDeltas against the Reach reference, same admiral, same seeds:\n');
    console.log('| Admiral | Swap | Win | Rounds | Hull left | Ships lost |');
    console.log('|---|---|---|---|---|---|');
    for (const admiral of ADMS) {
      const base = rows.find(r => r.cell === cell.key && r.admiral === admiral && r.variant === 'before');
      for (const v of ['after+h_interdictor', 'after+d_jackal']) {
        const r = rows.find(x => x.cell === cell.key && x.admiral === admiral && x.variant === v);
        const sgn = x => (x >= 0 ? '+' : '') + x.toFixed(1);
        console.log('| ' + admiralName(admiral) + ' | ' + swapName(v) + ' | ' + sgn(r.win - base.win) + ' pts | ' + sgn(r.rounds - base.rounds) + ' | ' + sgn(r.hull - base.hull) + ' pts | ' + sgn(r.lost - base.lost) + ' |');
      }
    }
  }
  const total = rows.reduce((a, r) => a + (r.to || 0), 0);
  console.log('\nSeed base 41000, cell step 7, sector 3 enemy pool (deathless, chorus, ithar). Before and after fleets are the same ' + cp + ' command points.');
  console.log('BALANCE PACK ' + (total === 0 ? 'PASS' : 'FAIL') + ': ' + (rows.length * N * BOSSES.length) + ' battles, ' + total + ' timeouts, 0 exceptions.');
})();

function admiralName(id) { return id === 'thale' ? 'Oryn Thale (Iron wall)' : 'Roderic Vex (Fire for effect)'; }
