'use strict';
// findings_tests.js - regression tests for the Voidsworn findings-to-tests ledger (wave 5, slate item 4).
// Each test pins one BLOCKER or FIX-level finding from the Oct 27 / Oct 28 / Oct 29 audit programs,
// the wave 3 deep QA sweep, or the wave 5 patch pack, at code pin 264f441d.
// A test that FAILS here is a correct regression test: it means the underlying defect is still
// unfixed in the game data/code. Tests were not weakened to pass. When Opus lands a fix, the
// matching test should flip to PASS without edits; if a fix takes a different shape than the
// finding assumed, update the test and the ledger row together.
// Run: node findings_tests.js [repoDir]   (exit 1 while any pinned defect is unfixed)
// Round 2 (Oct 30, 2026) added eight tests at the end of the file, behind two
// new harnesses in this folder: battle_probe.js (sim3d-style animation hooks,
// so aiUnit runs headlessly) and ui_loader.js (ui3d.js behind a DOM stub, so
// its state functions run headlessly). The runner now also accepts async
// tests; sync tests behave exactly as before.
const path = require('path');
const vm = require('vm');
const fs0 = require('fs');
const LOADER_CANDIDATES = [
  path.join(__dirname, '..', '..', 'voidsworn-harness', 'game_loader.js'),
  path.join(__dirname, '..', 'harness', 'game_loader.js'),
  path.join(__dirname, 'game_loader.js'),
  path.join(process.env.HOME || '', 'workspace', 'voidsworn-harness', 'game_loader.js'),
];
const loaderPath = LOADER_CANDIDATES.find(p => fs0.existsSync(p));
if (!loaderPath) throw new Error('game_loader.js not found in any candidate path');
const { loadGame } = require(loaderPath);
const repoDir = process.argv[2] || path.join(__dirname, '..', '..', 'voidsworn-fresh');
const G = loadGame(repoDir);
const runIn = (code) => vm.runInContext(code, G._sandbox);

let checks = 0, failures = 0;
const results = [];
function record(id, detail) {
  if (detail) { failures++; results.push([id, 'FAIL', detail]); console.log('FAIL ' + id + ': ' + detail); }
  else { results.push([id, 'PASS', '']); console.log('PASS ' + id); }
}
// Tests queue and run strictly in file order from the summary block at the
// end of the file. Round 1's tests are synchronous and behave exactly as
// they did when test() ran them inline; round 2's battle-probe tests are
// async and MUST NOT interleave, because they share one battle context and
// each replaces B for the next.
const queue = [];
function test(id, fn) {
  checks++;
  queue.push([id, fn]);
}
const canon = (o) => { const r = {}; for (const k of Object.keys(o || {}).sort()) r[k] = o[k]; return JSON.stringify(r); };
const cnt = (w) => { const m = {}; for (const pair of w || []) m[pair[0]] = (m[pair[0]] || 0) + 1; return m; };

// ---------- Oct 27 program: kit coherence ----------

test('KIT-1 chorus repair gate exists in FAC_GATES', () => {
  const FG = runIn('FAC_GATES');
  if (!FG.chorus) return 'FAC_GATES has no chorus entry; the approved Chorus shipyard repair prohibition is coded nowhere';
  if (!FG.chorus.noRepair && !/repair/i.test(FG.chorus.d || '')) return 'FAC_GATES.chorus carries no repair prohibition';
  return '';
});

test('KIT-2 ionpulse not dead against two whole factions', () => {
  const AB = runIn('ABILITIES');
  const shieldless = Object.keys(G.FACTIONS).filter(f => {
    const hulls = Object.values(G.HULLS).filter(h => h.fac === f && !h.sq);
    return hulls.length && hulls.every(h => !(h.sh > 0));
  });
  if (AB.ionpulse && shieldless.length >= 2)
    return 'ionpulse only strips shields, and ' + shieldless.join(' + ') + ' have no shielded hull at all';
  return '';
});

test('KIT-3 eclipse not in banned green tomb styling', () => {
  const d = G.FACTIONS.deathless;
  const bad = [];
  if (d.glow === '#3dff6a') bad.push('glow #3dff6a');
  if (d.trim === '#1fbf4a') bad.push('trim #1fbf4a');
  if (d.style === 'tomb') bad.push("style 'tomb'");
  return bad.length ? 'FACTIONS.deathless still uses banned styling: ' + bad.join(', ') : '';
});

test('KIT-4 lance-named renames are lance-kind weapons', () => {
  const FW = runIn('FAC_WNAMES');
  const bad = [];
  for (const fac of Object.keys(FW)) for (const wid of Object.keys(FW[fac])) {
    if (/lance/i.test(FW[fac][wid]) && G.W[wid] && G.W[wid].k !== 'lance') bad.push(fac + ' renames ' + wid + " '" + FW[fac][wid] + "' but its kind is '" + G.W[wid].k + "'");
  }
  return bad.length ? bad.join('; ') : '';
});

// ---------- Oct 27 program: admirals ----------

test('ADM-1 no duplicate admiral passives', () => {
  const byFx = {};
  for (const id of Object.keys(G.ADMIRALS)) { const k = canon(G.ADMIRALS[id].fx); (byFx[k] = byFx[k] || []).push(id); }
  const dups = Object.values(byFx).filter(g => g.length > 1).map(g => g.join(' = '));
  return dups.length ? 'identical fx objects shared by: ' + dups.join('; ') : '';
});

test('ADM-2 hunt Command text consistent across admirals', () => {
  const hunt = Object.values(G.ADMIRALS).filter(a => a.cmd && a.cmd.id === 'hunt');
  const withTorp = hunt.filter(a => /torpedo/i.test(a.cmd.d)).map(a => a.n);
  const without = hunt.filter(a => !/torpedo/i.test(a.cmd.d)).map(a => a.n);
  if (withTorp.length && without.length)
    return "one 'hunt' Command id, two effects: torpedo reload promised by " + withTorp.join(', ') + ' but not by ' + without.join(', ');
  return '';
});

test('ADM-5 shield-refill Command only on shielded factions', () => {
  const bad = [];
  for (const id of Object.keys(G.ADMIRALS)) {
    const a = G.ADMIRALS[id];
    if (a.cmd && /shield/i.test(a.cmd.d) && /refill|restore|recharge/i.test(a.cmd.d)) {
      const anyShield = Object.values(G.HULLS).some(h => h.fac === a.fac && !h.sq && h.sh > 0);
      if (!anyShield) bad.push(id + ' (' + a.fac + ')');
    }
  }
  return bad.length ? 'shield-refill Command text on a shieldless faction: ' + bad.join(', ') : '';
});

test('ADM-6 hidden squadron-hull bonus disclosed in admiral text', () => {
  const bad = [];
  for (const id of Object.keys(G.ADMIRALS)) {
    const a = G.ADMIRALS[id];
    if (a.fx && a.fx.sqHp > 0) {
      const mentions = /squadron|wing|swarm|brood/i.test(a.d) && /hp|health|hull|durab|tough|sturd/i.test(a.d);
      if (!mentions) bad.push(id);
    }
  }
  return bad.length ? 'fx.sqHp present but not disclosed in the card text for: ' + bad.join(', ') : '';
});

// ---------- Oct 27 program: events ----------

test('EVT-2 no event option requires a faction the event excludes', () => {
  const EV = runIn('EVENTS');
  const bad = [];
  for (const e of EV) for (const o of e.o || []) {
    if (o.need && o.need.fac && (e.not || []).includes(o.need.fac)) bad.push(e.id + " option '" + o.l + "' needs fac " + o.need.fac + ' which the event excludes');
  }
  return bad.length ? bad.join('; ') : '';
});

test('EVT-3 ambush and clock outcomes disclosed in option text', () => {
  const EV = runIn('EVENTS');
  const bad = [];
  for (const e of EV) for (const o of e.o || []) {
    const r = o.r; if (!r || typeof r !== 'object') continue;
    const txt = (o.l || '') + ' ' + (o.s || '');
    if (r.ambush && !/ambush/i.test(txt)) bad.push(e.id + " '" + o.l + "' hides ambush:true");
    if (r.nemClock > 0 && !/clock|nemesis/i.test(txt)) bad.push(e.id + " '" + o.l + "' hides nemClock +" + r.nemClock);
  }
  return bad.length ? bad.join('; ') : '';
});

test('EVT-5 every fight-start event has a free exit', () => {
  const EV = runIn('EVENTS');
  const isFree = (o) => {
    if (o.need) return false; const r = o.r; if (!r || typeof r !== 'object') return false;
    return Object.keys(r).every(k => k === 'cred' || k === 'xp');
  };
  const bad = [];
  for (const e of EV) {
    const hasFight = (e.o || []).some(o => o.r && typeof o.r === 'object' && o.r.fight);
    if (hasFight && !(e.o || []).some(isFree)) bad.push(e.id);
  }
  return bad.length ? 'fight-start events with no free exit: ' + bad.join(', ') : '';
});

// ---------- Oct 28 progression program: rewards ----------

test('RWD-2 rarity multiplier scales every core protocol', () => {
  const bad = [];
  const ignoreM = ['i_wall', 's_chain', 'h_brood', 'a_mark', 'r_slip', 'e_spread'];
  const capRare = ['h_hatch', 'e_reload'];
  for (const id of ignoreM) if (canon(G.BOONS[id].fx(2)) === canon(G.BOONS[id].fx(1))) bad.push(id + ' ignores m');
  for (const id of capRare) if (canon(G.BOONS[id].fx(2)) === canon(G.BOONS[id].fx(1.5))) bad.push(id + ' caps at the Rare tier');
  for (const id of Object.keys(G.BOONS)) {
    const b = G.BOONS[id];
    if (b.leg || b.duo || ignoreM.includes(id)) continue;
    if (canon(b.fx(2)) === canon(b.fx(1))) bad.push(id + ' also ignores m (not in the synthesis list)');
  }
  return bad.length ? bad.join('; ') : '';
});

test('RWD-3 shield legendary gated like its shield siblings', () => {
  if (G.BOON_NEED.L_storm !== 'shields')
    return "BOON_NEED has no 'shields' gate for L_storm, so a shieldless fleet can be offered a shield legendary";
  return '';
});

test('RWD-4 legendary does not deterministically overwrite the duo slot', () => {
  const duoId = Object.keys(G.BOONS).find(id => G.BOONS[id].duo);
  const duo = G.BOONS[duoId].duo, p = duo[0], q = duo[1];
  const ofP = Object.keys(G.BOONS).filter(id => G.BOONS[id].p === p && !G.BOONS[id].leg);
  const ofQ = Object.keys(G.BOONS).filter(id => G.BOONS[id].p === q && !G.BOONS[id].leg);
  const fleet = ['warden', 'harrow', 'reliquary', 'penitent', 'h_picket', 'h_vanguard'].map(t => G.newShip(t));
  const run = { fac: 'voidsworn', admiral: 'vex', sector: 2, patrons: [p, q], boons: [{ id: ofP[0], r: 0 }, { id: ofP[1], r: 0 }, { id: ofQ[0], r: 0 }], relics: [], fleet, inventory: [], credits: 0, cpCap: 60 };
  run.flagUid = fleet[0].uid; G.RUN = run;
  let duoSeen = 0;
  for (let s = 1; s <= 300; s++) { G.rndSeed(s * 13 + 5); const offer = runIn("rollBoonOffer('" + p + "', 1)"); if (offer.some(o => o.id === duoId)) duoSeen++; }
  return duoSeen === 0 ? 'in 300 offers with a duo and the patron legendary both eligible, the duo never survives: the legendary always takes the slot' : '';
});

test('RWD-8 off-patron backfill picks get the favour rarity treatment', () => {
  const fleet = ['penitent', 'warden', 'harrow', 'cathedral', 'h_picket', 'h_vanguard', 'h_dominion', 'reliquary', 'i_song', 'c_reaver'].map(t => G.newShip(t));
  const run = { fac: 'voidsworn', admiral: 'vex', sector: 2, patrons: ['iron', 'storm', 'star', 'rook'], boons: ['i_broad', 'i_still', 'i_plate', 'i_brace', 'i_line'].map(id => ({ id, r: 0 })), relics: [], fleet, inventory: [], credits: 0, cpCap: 60 };
  run.flagUid = fleet[0].uid; G.RUN = run; G.META.favour.iron = 25; // favour tier 3: on-patron rolls floor at Rare
  let off = 0, offCommon = 0;
  for (let s = 1; s <= 300; s++) {
    G.rndSeed(s * 17 + 3);
    const offer = runIn("rollBoonOffer('iron', 0)");
    for (const o of offer) { const b = G.BOONS[o.id]; if (b && b.p && b.p !== 'iron' && !b.duo) { off++; if (o.r === 0) offCommon++; } }
  }
  if (!off) return 'setup error: no backfill picks sampled';
  return offCommon > 0 ? offCommon + ' of ' + off + ' off-patron backfill picks rolled Common at favour tier 3, where on-patron picks can never roll Common' : '';
});

test('RWD-9 module pool offers only fleet-usable modules', () => {
  const run = G.runDefaults(); run.fleet = [G.newShip('warden')]; run.flagUid = run.fleet[0].uid; G.RUN = run;
  const kit = runIn('fleetKit()'); const NEED = runIn('MOD_NEED'); const pool = runIn('modulePool()');
  const bad = pool.filter(id => NEED[id] && !kit[NEED[id]]);
  return bad.length ? 'modulePool offers modules the fleet cannot use: ' + bad.join(', ') : '';
});

// ---------- Oct 28 battle-layer program: battlefield ----------

test('BF-3 blocker terrain colors are distinct', () => {
  const TI = runIn('TERRAIN_INFO');
  const seen = {}, bad = [];
  for (const t of ['rock', 'hulk', 'station', 'planet']) {
    if (seen[TI[t].col]) bad.push(t + ' shares ' + TI[t].col + ' with ' + seen[TI[t].col]);
    seen[TI[t].col] = t;
  }
  return bad.length ? bad.join('; ') : '';
});

test('BF-6 every encounter can reach strip arenas', () => {
  const EA = runIn('ENC_ARENA');
  const bad = Object.keys(EA).filter(enc => !EA[enc].some(pair => pair[0] === 'strip' && pair[1] > 0));
  return bad.length ? 'encounters whose arena weights exclude strip shapes entirely: ' + bad.join(', ') : '';
});

test('BF-9 debris is not strictly dominated by nebula', () => {
  const TI = runIn('TERRAIN_INFO');
  const num = (s) => { const m = /(\d+)\s+points harder/.exec(s || ''); return m ? +m[1] : null; };
  const neb = num(TI.neb.fx), deb = num(TI.debris.fx);
  if (neb === null || deb === null) return 'could not parse the to-hit penalties from TERRAIN_INFO text';
  return deb < neb ? 'same rule shape, worse number: debris ' + deb + ' points harder to hit vs nebula ' + neb : '';
});

test('BF-10 no encounter lists a shape twice', () => {
  const bad = [];
  for (const id of Object.keys(G.ENCOUNTERS)) {
    const seen = new Set();
    for (const s of G.ENCOUNTERS[id].shapes) { if (seen.has(s)) bad.push(id + ' (' + G.ENCOUNTERS[id].n + ') lists ' + s + ' twice'); seen.add(s); }
  }
  return bad.length ? bad.join('; ') : '';
});

// ---------- Oct 28 battle-layer program: fights ----------

test('FGT-1 boss fights never roll the Decapitation objective', () => {
  let flagship = 0;
  for (let s = 1; s <= 400; s++) { G.rndSeed(s * 7 + 1); if (runIn('bossEncounter()').enc === 'flagship') flagship++; }
  return flagship > 0 ? 'bossEncounter rolled flagship (Decapitation) in ' + flagship + ' of 400 seeded calls; ruled Oct 29: boss fights get their own objective table' : '';
});

test('FGT-4 carrier preview resolves through the effective archetype', () => {
  const got = G.effArch('carrier', 'deathless');
  return got !== 'heavy' ? "effArch('carrier','deathless') returned " + got + ', expected heavy' : '';
});

// ---------- Oct 28 battle-layer program: roster ----------

test('ROS-1 ascendant can move far enough to trigger Broadside', () => {
  return G.HULLS.ascendant.sp >= 2 ? '' : 'ascendant speed is ' + G.HULLS.ascendant.sp + ' but Broadside doctrine needs a 2+ hex move; ruled fix is speed 2';
});

test('ROS-2 variant weapon deletions are disclosed', () => {
  const syn = { battery: ['broadside'], pulsar: ['pulsar'], gauss: ['gauss', 'null cannon'], bioplasma: ['bioplasma', 'spine'] };
  const trade = ['instead of', 'in place of', 'trades', 'trade ', 'swaps', 'swap ', 'replaces', 'drops', 'loses', 'without'];
  const bad = [];
  for (const id of Object.keys(G.HULL_VARIANTS)) {
    const v = G.HULL_VARIANTS[id]; if (!v.w) continue;
    const base = G.HULLS[v.base]; if (!base) continue;
    const bc = cnt(base.w), vc = cnt(v.w), d = (v.d || '').toLowerCase();
    for (const wid of Object.keys(bc)) {
      if ((vc[wid] || 0) >= bc[wid]) continue;
      const names = [G.W[wid].n.toLowerCase(), wid].concat(syn[wid] || []);
      const disclosed = names.some(n => d.includes(n)) || trade.some(t => d.includes(t));
      if (!disclosed) bad.push(id + ' silently drops a ' + wid);
    }
  }
  return bad.length ? bad.join('; ') : '';
});

test('ROS-3 no variant deletes the hull ability undisclosed', () => {
  const AB = runIn('ABILITIES');
  const bad = [];
  for (const id of Object.keys(G.HULL_VARIANTS)) {
    const v = G.HULL_VARIANTS[id]; const base = G.HULLS[v.base]; if (!base || !base.ab) continue;
    if (!G.HULLS[id].ab) {
      const abName = (AB[base.ab] && AB[base.ab].n || '').toLowerCase();
      const d = (v.d || '').toLowerCase();
      if (!d.includes('ability') && !(abName && d.includes(abName)) && !d.includes(base.ab)) bad.push(id + ' deletes ability ' + base.ab);
    }
  }
  return bad.length ? bad.join('; ') : '';
});

test('ROS-4 eclipse boss is not a rescaled harvester without reanimate', () => {
  const boss = G.HULLS.d_boss, harv = G.HULLS.d_harvester;
  const bad = [];
  if (!boss.reanimate) bad.push('d_boss is the only deathless hull without reanimate');
  const a = cnt(boss.w), b = cnt(harv.w);
  let shared = 0; for (const wid of Object.keys(b)) shared += Math.min(a[wid] || 0, b[wid]);
  const total = (boss.w || []).length;
  if (total && shared / total >= 0.75 && boss.cp >= 3 * harv.cp)
    bad.push('d_boss repeats ' + shared + ' of its ' + total + ' mounts from d_harvester at ' + boss.cp + ' CP vs ' + harv.cp + ' CP');
  return bad.join('; ');
});

test('ROS-5 every variant carries a real trade', () => {
  const hasTrade = (v) => {
    const base = G.HULLS[v.base]; if (!base) return true;
    const bc = cnt(base.w), vc = cnt(v.w || base.w);
    for (const wid of Object.keys(bc)) if ((vc[wid] || 0) < bc[wid]) return true;
    if (v.mod) {
      for (const k of Object.keys(v.mod)) {
        if (k === 'ab') { if (v.mod.ab === null || v.mod.ab !== base.ab) return true; }
        else if (typeof v.mod[k] === 'number' && typeof base[k] === 'number' && v.mod[k] < base[k]) return true;
      }
    }
    return false;
  };
  const bad = Object.keys(G.HULL_VARIANTS).filter(id => !hasTrade(G.HULL_VARIANTS[id]));
  return bad.length ? 'strict-upgrade variants with no trade: ' + bad.join(', ') : '';
});

test('ROS-6 warden and picket are not the same ship', () => {
  const a = G.HULLS.warden, b = G.HULLS.h_picket;
  const axes = ['cp', 'sh', 'rg', 'ar', 'sp', 'tn', 'ab', 'hangar'];
  const diff = axes.filter(k => (a[k] || 0) !== (b[k] || 0));
  const kindsA = [...new Set(a.w.map(pair => G.W[pair[0]].k))].sort().join(',');
  const kindsB = [...new Set(b.w.map(pair => G.W[pair[0]].k))].sort().join(',');
  if (kindsA !== kindsB) diff.push('weapon kinds');
  return diff.length ? '' : 'warden and h_picket agree on cp, shields, range, armour, speed, turns, ability and weapon kinds; only hp, evasion and the battery weapon id differ';
});

test('ROS-9 orphan combat abilities are spread beyond one hull', () => {
  const counts = {};
  for (const id of Object.keys(G.HULLS)) {
    if (G.HULL_VARIANTS[id]) continue;
    const h = G.HULLS[id]; if (h.sq || !h.ab) continue;
    counts[h.ab] = (counts[h.ab] || 0) + 1;
  }
  const bad = ['focus', 'ionpulse', 'frenzy'].filter(ab => (counts[ab] || 0) < 2);
  return bad.length ? 'abilities still on exactly one hull (ruled: spread these three; reclaim stays signature): ' + bad.map(ab => ab + ' x' + (counts[ab] || 0)).join(', ') : '';
});

// ---------- Oct 29 program: weapons ----------

test('WPN-1 no two weapons are field-for-field identical', () => {
  const byKey = {};
  for (const id of Object.keys(G.W)) {
    const o = {}; for (const k of Object.keys(G.W[id])) if (k !== 'n') o[k] = G.W[id][k];
    const key = canon(o); (byKey[key] = byKey[key] || []).push(id);
  }
  const dups = Object.values(byKey).filter(g => g.length > 1).map(g => g.join(' = '));
  return dups.length ? 'identical weapon stat blocks: ' + dups.join('; ') : '';
});

test('WPN-2 turbo and gauss are not one damage line split by pierce', () => {
  const t = G.W.turbo, g = G.W.gauss;
  const sameLine = t.shots * t.dmg === g.shots * g.dmg && t.acc === g.acc && t.r === g.r && t.opt === g.opt && t.fall === g.fall && t.crit === g.crit;
  if (sameLine && (g.pierce || 0) > (t.pierce || 0))
    return 'turbo and gauss share shots x dmg (' + (t.shots * t.dmg) + '), accuracy, range, falloff and crit; gauss differs only by kind and pierce ' + g.pierce;
  return '';
});

test('WPN-3 guard: no hull mounts both battery and hbattery', () => {
  const bad = [];
  for (const id of Object.keys(G.HULLS)) {
    const ids = (G.HULLS[id].w || []).map(pair => pair[0]);
    if (ids.includes('battery') && ids.includes('hbattery')) bad.push(id);
  }
  return bad.length ? 'hulls arbitraging the battery/hbattery table gap: ' + bad.join(', ') : '';
});

test('WPN-5 no dead rear arc and no overwritten evMult on startorp', () => {
  const bad = [];
  const ARC = runIn('ARC_NAME');
  if (ARC.R) bad.push("ARC_NAME still defines a 'Rear' arc no weapon can use (guns never face backward)");
  if ('evMult' in G.W.startorp) bad.push('startorp still carries evMult:2, overwritten by the Ithar trait in live play');
  return bad.join('; ');
});

// ---------- Oct 29 program: squadrons ----------

test('SQ-1 spore wing is not a bomber reskin', () => {
  const a = G.W.sporeb, b = G.W.bombs;
  const delivery = ['k', 'shots', 'r', 'acc', 'fall', 'pierce'];
  const diff = delivery.filter(k => a[k] !== b[k]);
  return diff.length ? '' : 'sporeb and bombs agree on kind, shots, range, accuracy, falloff and pierce; only damage, vsSq and crit differ';
});

// ---------- Oct 29 program: modules ----------

test('MOD-2 modules do not duplicate perks or collide with relics', () => {
  const bad = [];
  if (Object.keys(G.MODULES).some(k => G.RELICS[k])) bad.push('key collision: cogitator exists in both MODULES and RELICS');
  const dup = (m, p) => {
    const mf = G.MODULES[m].fx, pf = G.PERKS[p].fx;
    const shared = Object.keys(pf).filter(k => k in mf);
    if (shared.length && shared.every(k => pf[k] === mf[k]) && Object.keys(pf).every(k => k in mf)) return true;
    return canon(mf) === canon(pf);
  };
  for (const pair of [['auspex', 'gunnery'], ['cogitator', 'killer'], ['prow', 'ironhull'], ['drive', 'helm']]) {
    if (dup(pair[0], pair[1])) bad.push('MODULES.' + pair[0] + ' duplicates PERKS.' + pair[1]);
  }
  return bad.join('; ');
});

test('MOD-4 damcon is not dominated by prow on price', () => {
  if (G.MODULES.damcon.cost > G.MODULES.prow.cost)
    return 'damcon costs ' + G.MODULES.damcon.cost + ' for a slow conditional regen while prow costs ' + G.MODULES.prow.cost + ' for an upfront 15% hull buffer plus armour';
  return '';
});

// ---------- Oct 29 program: boons ----------

test('BN-1 the ram block is not one job sold three times', () => {
  const pool = ['ramPct', 'ramCap', 'ramGuard'];
  const sets = ['r_prow', 'd_jugg', 'L_rook'].map(id => Object.keys(G.BOONS[id].fx(1)));
  const anyOutside = sets.some(keys => keys.some(k => !pool.includes(k)));
  return anyOutside ? '' : 'r_prow, d_jugg and L_rook all draw exclusively on ramPct/ramCap/ramGuard with no distinguishing effect';
});

test('BN-2 the legendary explosion is not worse than the epic', () => {
  const leg = G.BOONS.L_ember.fx(1), epic = G.BOONS.e_chain.fx(2);
  if (leg.chainBoom > (epic.chainBoom || 0)) return '';
  if (Object.keys(leg).some(k => !(k in epic))) return '';
  return 'L_ember explodes for ' + leg.chainBoom + ', the same as e_chain at Epic tier (' + epic.chainBoom + '), and the epic also sets fires while the legendary does not';
});

test('BN-5 every patron appears in at least two duos', () => {
  const counts = {};
  for (const id of Object.keys(G.BOONS)) if (G.BOONS[id].duo) for (const p of G.BOONS[id].duo) counts[p] = (counts[p] || 0) + 1;
  const bad = Object.keys(G.PATRONS).filter(p => (counts[p] || 0) < 2);
  return bad.length ? 'patrons in fewer than two duos: ' + bad.map(p => p + ' x' + (counts[p] || 0)).join(', ') : '';
});

// ---------- Oct 29 program: economy and faction shape ----------

const priceFor = (fac, cls, cp) => {
  const base = Math.round((60 * cp + 10) / 5) * 5;
  const pm = (G.FAC_PRICE[fac] && G.FAC_PRICE[fac][cls]) || 1;
  return Math.round(base * pm / 5) * 5;
};

test('ECO-2 the swarm faction carrier is not the most expensive carrier', () => {
  const carriers = Object.keys(G.HULLS).filter(id => G.HULLS[id].cls === 'Carrier' && !G.HULLS[id].boss && !G.HULLS[id].sq)
    .map(id => ({ id, fac: G.HULLS[id].fac, price: priceFor(G.HULLS[id].fac, 'Carrier', G.HULLS[id].cp) }));
  const chorus = carriers.find(c => c.fac === 'chorus');
  if (!chorus) return 'no chorus carrier found';
  const maxOther = Math.max(...carriers.filter(c => c.fac !== 'chorus').map(c => c.price));
  return chorus.price > maxOther ? 'b_brood prices at ' + chorus.price + ', the highest carrier price in the game, against a best rival of ' + maxOther : '';
});

test('FS-2 a cp6 eclipse battleship would not price below the eclipse cruiser', () => {
  const bs = priceFor('deathless', 'Battleship', 6);
  const harv = priceFor('deathless', G.HULLS.d_harvester.cls, G.HULLS.d_harvester.cp);
  return bs > harv ? '' : 'FAC_PRICE.deathless has no Battleship key, so a cp6 battleship falls back to ' + bs + ', below d_harvester at ' + harv + ': the price ladder inverts';
});

// ---------- genSector guarantees: wave 3 deep QA + Oct 28 variety ----------

const sweep = { maps: 0, elite: [], boss: [], yard: [], drydock: [], fightCol: [], encounter: [] };
{
  const SPECIAL = runIn('ENC_SPECIAL');
  for (let seed = 1; seed <= 300; seed++) {
    for (let s = 1; s <= 3; s++) {
      const run = G.runDefaults(); run.foes = null; run.condsUsed = []; run.regionsUsed = [];
      G.RUN = run; G.rndSeed(seed * 31 + s);
      const sec = G.genSector(s); const cols = sec.cols, last = cols.length - 1;
      sweep.maps++;
      if (!cols[cols.length - 3].some(n => n.type === 'elite')) sweep.elite.push(seed + '/' + s);
      if (cols[last].filter(n => n.type === 'boss').length !== 1) sweep.boss.push(seed + '/' + s);
      if (!cols[3].some(n => n.type === 'shipyard')) sweep.yard.push(seed + '/' + s);
      if (!cols[last - 1].every(n => ['shipyard', 'drydock', 'field'].includes(n.type))) sweep.drydock.push(seed + '/' + s);
      for (let c = 1; c <= 4; c++) if (!cols[c].some(n => n.type === 'battle' || n.type === 'elite')) sweep.fightCol.push(seed + '/' + s + ' col ' + c);
      for (let c = 1; c < last; c++) {
        const fights = cols[c].filter(n => n.type === 'battle' || n.type === 'elite');
        if (fights.length && !fights.some(n => SPECIAL.includes(n.enc))) sweep.encounter.push(seed + '/' + s + ' col ' + c + ' no special');
        for (let i = 1; i < fights.length; i++) if (fights[i].enc === fights[i - 1].enc) sweep.encounter.push(seed + '/' + s + ' col ' + c + ' adjacent ' + fights[i].enc);
      }
    }
  }
}
const sweepFail = (list, label) => list.length ? label + ' failed on ' + list.length + ' of ' + sweep.maps + ' maps (first: ' + list.slice(0, 3).join(', ') + ')' : '';

test('W3-1 elite guarantee holds in the pre-boss approach column', () => sweepFail(sweep.elite, 'elite guarantee'));
test('VAR-1a exactly one boss in the final column', () => sweepFail(sweep.boss, 'boss guarantee'));
test('VAR-1b column 3 always offers a shipyard', () => sweepFail(sweep.yard, 'shipyard guarantee'));
test('VAR-1c the pre-boss column is all rest stops', () => sweepFail(sweep.drydock, 'rest-stop guarantee'));
test('VAR-1d every fight column (1 to 4) offers a fight', () => sweepFail(sweep.fightCol, 'fight-per-column guarantee'));
test('VAR-1e encounter variety guarantees hold', () => sweepFail(sweep.encounter, 'encounter guarantee'));

// ---------- Campaign-layer tests (Oct 30 extension) ----------
// These rows were TESTABLE-NOT-WRITTEN because the harness loaded only
// data.js, core.js and battle.js. campaign_loader.js (same folder) now loads
// campaign_meta.js and campaign_run.js into the same context with a DOM stub,
// which unlocks the event, Nemesis, reward, shipyard and progression rows.
// BF-2 and BF-7 stay on the battle loader; PROG-2 and UI-7 are static source
// scans in the validator style. Every test below was probed against the pin
// before being written; the failure messages quote the observed behavior.

const fs = require('fs');
const { loadCampaign } = require(path.join(__dirname, 'campaign_loader.js'));
let GC = null, gcError = '';
try { GC = loadCampaign(repoDir); } catch (e) { gcError = e.message; }
const needGC = () => GC ? '' : 'campaign loader failed to load: ' + gcError;

function cRun(fac, fleetTpls, sector) {
  const run = GC.runDefaults();
  run.fac = fac || 'voidsworn'; run.admiral = 'vex'; run.sector = sector || 1; run.foes = null;
  run.fleet = (fleetTpls || ['warden', 'harrow']).map(t => GC.newShip(t));
  run.flagUid = run.fleet.length ? run.fleet[0].uid : null;
  run.credits = 500; run.flags = {};
  GC.RUN = run; GC.META = GC.defaultMeta();
  return run;
}
function nemFixture(fac, sector, extra) {
  const run = cRun('voidsworn', ['warden', 'harrow', 'penitent'], sector);
  run.nem = Object.assign({
    fac, name: 'Test Nem', title: 'First Admiral', persona: 'proud', traits: [], portrait: 'nem_x_1', g: 'm',
    weak: ['ion', 'torp'], revealed: [], adapt: [], clock: 0, met: 0, beaten: 0, scars: 0, scarKinds: [],
    epithets: [], epithet: null, last_beat: null, fed: 0, riches: 0, loot: 0, held: null, gloat: null,
    honed: 0, revived: false, dead: false, strike: false, seen: {}, signatures: [],
  }, extra || {});
  return run;
}

// ---------- Oct 27 program: campaign rows ----------

test('EVT-1 a defector flag records which option wrote it', () => {
  const bad = needGC(); if (bad) return bad;
  const run = cRun('hegemony', ['h_picket', 'h_vanguard'], 1);
  const def = GC.EVENTS.find(e => e.id === 'defector');
  if (!def) return 'defector event not found in EVENTS';
  GC.eventFlags(def, def.o.find(o => o.k === 'ransom'), 1);
  const ransomNeed = GC.needMet({ flag: 'defector' }), ransomVerb = GC.verbFree(GC.FAC_VERBS.hegemony);
  run.flags = {};
  GC.eventFlags(def, def.o.find(o => o.k === 'question'), 0);
  const questionNeed = GC.needMet({ flag: 'defector' }), questionVerb = GC.verbFree(GC.FAC_VERBS.hegemony);
  if (!questionNeed || !questionVerb) return 'control case broke: questioning the defector no longer satisfies the flag gates';
  return (ransomNeed || ransomVerb)
    ? 'ransoming the defector (he leaves with 70 credits) still satisfies the saboteur intel gate (' + ransomNeed + ') and the Hegemony free verb (' + ransomVerb + '): the flag records presence, not the option that wrote it'
    : '';
});

test('TXT-2 the shipwright option repairs the second most damaged ship', () => {
  const bad = needGC(); if (bad) return bad;
  const run = cRun('voidsworn', ['warden', 'warden', 'warden'], 1);
  const [A, B, C] = run.fleet;
  const setF = (s, f) => { s.hp = Math.round(GC.derive(s).maxHp * f); };
  setF(A, 0.2); setF(B, 0.5); setF(C, 0.8);
  GC.applyOutcome({ upgradeOne: 1, repairOne: 1 }); // the wright event's pay option, data.js
  const full = s => s.hp >= GC.derive(s).maxHp;
  if (!full(A)) return 'control case broke: the most damaged ship was not upgraded and healed';
  return full(B) ? '' : 'the option text promises the second ship is fully repaired, but repairOne re-sorts after upgradeOne healed the first ship, so the repair landed on the third ship instead (second ship left at ' + Math.round(100 * B.hp / GC.derive(B).maxHp) + '%)';
});

test('TXT-8 no NaN reaches a player-facing label', () => {
  const bad = needGC(); if (bad) return bad;
  const run = cRun('voidsworn', [], 1);
  const full = GC.newShip('warden'), hurt = GC.newShip('warden'), boss = GC.newShip('h_boss'); // h_boss has no cost field
  hurt.hp = Math.round(GC.derive(hurt).maxHp * 0.3);
  run.fleet = [full, hurt, boss]; run.flagUid = full.uid; run.credits = 1000;
  GC.shipyardScreen({ id: 'y1', type: 'shipyard', stock: { hulls: [], mods: [], sold: [] } });
  const html = GC.appEl().innerHTML;
  return html.includes('NaN') ? 'the shipyard renders a NaN for a cost-less hull (Decommission (+NaN)): the label path does not reuse the shipValue guard' : '';
});

// ---------- Oct 28 progression program: campaign rows ----------

test('PROG-2 every purchasable thing has a reachable purchase path', () => {
  const files = ['campaign_meta.js', 'campaign_run.js', 'campaign3d.js', 'ui3d.js', 'voidsworn-3d.html'];
  const src = files.map(f => { try { return fs.readFileSync(path.join(repoDir, f), 'utf8'); } catch (e) { return ''; } }).join('\n');
  const missing = ['buyAdmiral', 'buyLegacy'].filter(a => !src.includes('data-act="' + a + '"'));
  return missing.length ? 'ACT.' + missing.join(' and ACT.') + ' charge renown and grant, but no screen renders a button for them (the handlers are dead code; locked admirals point at a Legacy screen that no longer exists under that name)' : '';
});

test('PROG-5 mastery does not double count elite and flagship battles', () => {
  const bad = needGC(); if (bad) return bad;
  const run = cRun('hegemony', ['h_picket'], 3);
  run.admiral = 'malek';
  run.stats = { battles: 1, elites: 1, bosses: 0, kills: 5, lost: 0 }; // one elite battle, nothing else
  run.fallen = []; run.t0 = Date.now();
  GC.META.mastery = {};
  GC.endRun(false, false);
  const got = GC.META.mastery.malek || 0;
  // The Progression screen states the rates as per-type totals (1 per battle
  // won, 2 per elite, 5 per flagship): one elite battle should pay 2. The
  // chair synthesis reads the formula's 3 as the double count; see README.
  return got === 2 ? '' : 'one elite battle paid ' + got + ' mastery, not 2: rewardFlow counts the battle in stats.battles and again in stats.elites, and mxGain adds both';
});

test('PROG-6 an unowned admiral cannot be launched', () => {
  const bad = needGC(); if (bad) return bad;
  GC.META = GC.defaultMeta();
  GC.META.admirals = { vex: true }; // owns only the starter; malek is a renown purchase
  GC.runIn("newRun('malek','hegemony',{})");
  return GC.RUN && GC.RUN.admiral === 'malek'
    ? 'newRun launched the unowned admiral malek: neither the launch path nor newRun checks META.admirals ownership (the UI auto-assigns an owned admiral, the rules function does not)'
    : '';
});

test('RWD-5 credit nodes are not dominated by the boon decline value', () => {
  const bad = needGC(); if (bad) return bad;
  const mkSummary = () => ({ cfg: { kind: 'battle', col: 0, node: 'n1' }, xp: [], lost: [], kills: 1, rounds: 3, wrecks: [], prizes: [] });
  const measure = (rw) => {
    const run = cRun('voidsworn', ['warden', 'harrow'], 2);
    run.map = { cols: [[{ id: 'n1', type: 'battle', rw }]], edges: [], fac: 'hegemony' };
    run.curNode = 'n1'; run.credits = 0;
    run.stats = { battles: 0, elites: 0, bosses: 0, kills: 0, lost: 0 };
    GC.rewardFlow(mkSummary());
    return run.credits;
  };
  const credNode = measure({ k: 'cred' }), boonNode = measure({ k: 'boon', p: 'iron' });
  cRun('voidsworn', ['warden'], 2);
  const decline = GC.boonDeclineCred();
  const premium = (credNode - boonNode) - decline;
  // Chair-set bar (see README): a credit node must beat the decline value by
  // at least 15 for the map choice to be a choice. At the pin the premium is
  // exactly 5 at every sector (55 node vs 50 decline at sector 2).
  return premium >= 15 ? '' : 'at sector 2 a credit node beats declining a boon by only ' + premium + ' credits (node premium ' + (credNode - boonNode) + ' over the same battle, decline pays ' + decline + '): a boon node dominates a credit node by arithmetic';
});

test('RWD-6 a reroll that cannot change the offer is refused', () => {
  const bad = needGC(); if (bad) return bad;
  const run = cRun('voidsworn', ['warden', 'harrow', 'reliquary', 'penitent', 'h_picket', 'h_vanguard'], 1);
  run.patrons = ['iron']; run.credits = 100; run.boonRerolls = 0;
  const leave = ['i_broad', 'i_still', 'i_plate'];
  run.boons = Object.keys(GC.BOONS).filter(id => GC.BOONS[id].p === 'iron' && !GC.BOONS[id].leg && !leave.includes(id)).map(id => ({ id, r: 0 }));
  run.reward = { boonOffer: leave.map(id => ({ id, r: 0 })), rerolled: false };
  const before = run.credits;
  GC.boonReroll('iron', 0);
  return run.credits < before
    ? 'with exactly three eligible protocols in the whole pool, boonReroll charged ' + (before - run.credits) + ' credits and returned the same three: no pool-depth check before charging'
    : '';
});

test('RWD-7 every module is reachable as salvage', () => {
  const bad = needGC(); if (bad) return bad;
  const run = cRun('corsair', ['warden', 'reliquary', 'i_song', 'c_reaver', 'b_brood'], 1);
  run.flagUid = run.fleet[0].uid;
  const tries = [
    { wk: ['lance'] }, { wk: ['torp'] }, { wk: ['battery'] }, { wk: ['flak'] },
    { ab: 'launch' }, { wk: ['gauss'] }, { regen: 5 }, { sh: 24 }, { wk: ['turret'] }, { wk: ['autocannon'] },
  ];
  const reach = {};
  for (const w of tries) { const y = GC.salvageYield(Object.assign({ cp: 3, cause: 'gun' }, w)); if (y.mod) reach[y.mod] = true; }
  const never = Object.keys(GC.MODULES).filter(m => !reach[m]);
  return never.length ? 'salvageYield reads a fixed nine-module table keyed to the wreck, so these modules can never drop as salvage: ' + never.join(', ') : '';
});

// ---------- Oct 28 battle-layer program: Nemesis rows ----------

test('NEM-2 an adaptation never counters a revealed weakness', () => {
  const bad = needGC(); if (bad) return bad;
  nemFixture('hegemony', 2, { revealed: ['ion'], seen: { lance: 10, ion: 10 } });
  const a1 = GC.nemAdapt();
  nemFixture('hegemony', 2, { revealed: ['torp'], seen: { torp: 10, sq: 10 } });
  const a2 = GC.nemAdapt();
  const hits = [];
  if (a1 === 'shields') hits.push('with the ion weakness revealed, heavy lance and ion fire still earned shields (the direct counter)');
  if (a2 === 'pd') hits.push('with the torp weakness revealed, heavy torpedo fire still earned pd (the direct counter)');
  return hits.length ? hits.join('; ') + ': nemAdapt scores counters without reading N.revealed, against the Oct 29 Q4 ruling' : '';
});

test('NEM-3 at most one adaptation is earned per sector', () => {
  const bad = needGC(); if (bad) return bad;
  const run = nemFixture('hegemony', 3, {});
  const got = [];
  for (let i = 0; i < 4; i++) { run.nem.seen = { lance: 10, ion: 10, torp: 9, ram: 9 }; const a = GC.nemAdapt(); if (a) got.push(a); }
  return got.length <= 1 ? '' : 'a single sector 3 visit granted ' + got.length + ' adaptations (' + got.join(', ') + '): the cap compares total adaptations against a cumulative sector budget instead of one per sector';
});

test('NEM-4 every faction strike does something', () => {
  const bad = needGC(); if (bad) return bad;
  const silent = [];
  { const run = nemFixture('corsair', 1, {}); run.credits = 100; GC.nemStrike(); if (run.credits >= 100 && run.fleet.length === 3) silent.push('corsair raid took nothing from a rich fleet'); }
  { const run = nemFixture('deathless', 1, {}); const hp = run.fleet.reduce((s, x) => s + x.hp, 0); GC.nemStrike(); if (run.fleet.reduce((s, x) => s + x.hp, 0) >= hp) silent.push('deathless tithe cost no hull'); }
  for (const fac of ['ithar', 'chorus', 'hegemony', 'voidsworn']) {
    nemFixture(fac, 1, {});
    if (!GC.nemStrike()) silent.push(fac);
  }
  return silent.length ? 'nemStrike is a no-op for: ' + silent.join(', ') + ' (their strike kinds fall through to return an empty string; only raid and tithe are implemented)' : '';
});

test('NEM-5 a raid warning matches what the strike can take', () => {
  const bad = needGC(); if (bad) return bad;
  const run = nemFixture('corsair', 1, { clock: 3 });
  run.credits = 10; // too poor for the credit raid: the warning evaluates the crippled-ship branch
  run.fleet.forEach(s => { s.hp = GC.derive(s).maxHp; });
  const warn = GC.nemWarnLine(run.nem).replace(/<[^>]+>/g, '');
  run.fleet[1].hp = Math.floor(GC.derive(run.fleet[1]).maxHp * 0.2); // the clock fight itself cripples a ship
  GC.nemClockAdd(1);
  const promisedNothing = /nothing to take/.test(warn);
  return (promisedNothing && run.fleet.length < 3)
    ? 'the warning said the raid would "find nothing to take", but the strike then towed away a ship crippled in the clock fight itself: the warning is computed at warn time, the strike re-evaluates at strike time'
    : '';
});

test('NEM-6 a no-retreat Nemesis flagship kill registers the kill', () => {
  const bad = needGC(); if (bad) return bad;
  const run = nemFixture('voidsworn', 1, {}); // NEM_FAC.voidsworn has beh.noFlee: the card says he never retreats
  const lines = GC.nemAfterBattle('win', true, {});
  const escaped = lines.some(l => /escapes/.test(l));
  return (!run.nem.dead || escaped)
    ? 'sector 1, flagship destroyed: dead=' + run.nem.dead + ' and the debrief says he escapes. In sectors 1 and 2 a flagship kill can never register as a death, even for the no-retreat Nemesis'
    : '';
});

test('NEM-7 legacy Nemesis migration preserves accumulated state', () => {
  const bad = needGC(); if (bad) return bad;
  const run = cRun('voidsworn', ['warden', 'harrow'], 2);
  run.nem = { weak: ['ion', 'slow'], revealed: ['ion'], adapt: ['riches'], clock: 2, met: 1, beaten: 1, scars: 1, dead: false, strike: false, seen: {}, loot: 500, riches: 2, fed: 3, honed: 1, held: run.fleet[1], last_beat: 'lance' };
  const N = GC.ensureNemesis();
  const lost = [];
  if (N.loot !== 500) lost.push('loot ' + N.loot);
  if (N.riches !== 2) lost.push('riches ' + N.riches);
  if (N.fed !== 3) lost.push('fed ' + N.fed);
  if (N.honed !== 1) lost.push('honed ' + N.honed);
  if (!N.held) lost.push('held ship dropped');
  if (!(N.adapt || []).includes('riches')) lost.push('faction special adaptation filtered out of adapt');
  return lost.length ? 'migrating a pre-persona save zeroed or dropped: ' + lost.join(', ') + ' (ensureNemesis copies a fixed field list and filters adapt to the generic table)' : '';
});

test('FR-2 a lost Nemesis meeting reveals exactly one weakness', () => {
  const bad = needGC(); if (bad) return bad;
  const run = nemFixture('hegemony', 1, {});
  GC.nemAfterBattle('loss', false, {});
  const grew = run.nem.revealed.length;
  const run2 = nemFixture('hegemony', 1, { revealed: ['ion', 'torp'] });
  GC.nemAfterBattle('loss', false, {});
  const stable = run2.nem.revealed.length === 2;
  if (!stable) return 'control case broke: a loss with both weaknesses revealed changed the revealed set';
  return grew === 1 ? '' : 'a lost meeting revealed ' + grew + ' weaknesses: nemReveal is called only in the win branch of nemAfterBattle, against the Oct 29 Q5 ruling (a loss still teaches one)';
});

// ---------- Oct 28 battle-layer program: terrain probes (battle loader) ----------

test('BF-2 boss fights keep the map terrain budget', () => {
  const rocks = () => Object.values(G.B.terrain).filter(t => t === 'rock').length;
  let battle = 0, boss = 0; const N = 12;
  for (let s = 1; s <= N; s++) {
    const run = G.runDefaults();
    run.fac = 'voidsworn'; run.admiral = 'vex'; run.sector = 2; run.foes = null;
    run.fleet = ['warden', 'harrow', 'penitent', 'h_picket'].map(t => G.newShip(t));
    run.flagUid = run.fleet[0].uid; G.RUN = run;
    G.startBattle({ kind: 'battle', fac: 'hegemony', col: 3, obj: 'rout', shape: 'dense', map: 'storm', seed: 5000 + s });
    battle += rocks();
    const run2 = G.runDefaults();
    run2.fac = 'voidsworn'; run2.admiral = 'vex'; run2.sector = 2; run2.foes = null;
    run2.fleet = ['warden', 'harrow', 'penitent', 'h_picket'].map(t => G.newShip(t));
    run2.flagUid = run2.fleet[0].uid; G.RUN = run2;
    G.startBattle({ kind: 'boss', fac: 'hegemony', col: 6, obj: 'rout', shape: 'dense', map: 'storm', seed: 5000 + s });
    boss += rocks();
  }
  const ratio = boss / Math.max(1, battle);
  return ratio >= 0.8 ? '' : 'across ' + N + ' seed pairs the boss board keeps only ' + Math.round(ratio * 100) + '% of the rock a normal dense board has (' + (boss / N).toFixed(1) + ' vs ' + (battle / N).toFixed(1) + '): startBattle deletes 45% of rock for kind boss after generation';
});

test('BF-7 the lanes barrier crosses the advance axis', () => {
  let rowSum = 0, colSum = 0; const N = 12;
  const BH = runIn('BH'), midR = Math.floor(BH / 2);
  for (let s = 1; s <= N; s++) {
    G.rndSeed(s * 101);
    const T = runIn("genTerrain('storm','lanes',{})");
    const rows = {}, cols = {};
    for (const k of Object.keys(T)) {
      if (T[k] !== 'rock') continue;
      const [q, r] = k.split(',').map(Number);
      rows[r] = (rows[r] || 0) + 1;
      const c = q + Math.floor(r / 2); cols[c] = (cols[c] || 0) + 1;
    }
    rowSum += rows[midR] || 0;
    colSum += Math.max(...Object.values(cols));
  }
  return colSum > rowSum ? '' : 'the lanes barrier runs along the middle row (avg ' + (rowSum / N).toFixed(1) + ' rock) while no single column holds more than ' + (colSum / N).toFixed(1) + ': on a left-to-right strip the wall is parallel to the advance, not across it';
});

test('BF-8 reinforcements arrive on their own side of the field', () => {
  const errs = [];
  for (let s = 1; s <= 12; s++) {
    const run = G.runDefaults();
    run.fac = 'voidsworn'; run.admiral = 'vex'; run.sector = 2; run.foes = null;
    run.fleet = ['warden', 'harrow', 'penitent'].map(t => G.newShip(t));
    run.flagUid = run.fleet[0].uid; G.RUN = run;
    G.rndSeed(31000 + s);
    G.startBattle({ kind: 'battle', fac: 'hegemony', col: 3, obj: 'rout', shape: 'open', map: 'storm', arena: 'round', approach: 'headon', seed: 31000 + s });
    const B = G.B;
    if (!B || B.arena !== 'round' || !B.approach) continue;
    const cen = runIn('(()=>{ const hs=boardHexes(); let x=0,z=0; for(const h of hs){ const p=hexXZ(h); x+=p.x; z+=p.z; } return {x:x/hs.length, z:z/hs.length}; })()');
    const ang = (u) => { const p = runIn('hexXZ({q:' + u.q + ',r:' + u.r + '})'); return Math.atan2(p.z - cen.z, p.x - cen.x); };
    const es = B.units.filter(u => u.side === 'enemy' && !u.isSq && !u.transport);
    if (!es.length) continue;
    const ea = Math.atan2(es.reduce((a, u) => a + Math.sin(ang(u)), 0), es.reduce((a, u) => a + Math.cos(ang(u)), 0));
    B.event = { k: 'reinf_enemy', r: 1, warnR: 0, warned: true, done: false }; B.round = 2;
    const before = B.units.length;
    runIn('eventTick()');
    const nu = B.units.slice(before).find(u => u.reinf);
    if (!nu) continue;
    let d = Math.abs(ang(nu) - ea) * 180 / Math.PI; if (d > 180) d = 360 - d;
    errs.push(d);
  }
  if (errs.length < 8) return 'probe produced too few reinforcement spawns (' + errs.length + ')';
  const mean = errs.reduce((a, b) => a + b, 0) / errs.length;
  return mean < 60 ? '' : 'on round arenas the enemy reinforcement spawns on average ' + Math.round(mean) + ' degrees away from the direction the enemy fleet approached from (' + errs.filter(x => x > 90).length + ' of ' + errs.length + ' in the wrong half): edgeHex reads the board bounding columns and never the approach angle';
});

// ---------- Oct 29 program: campaign rows ----------

test('MOD-3 a module cannot be fitted to a ship it cannot affect', () => {
  const bad = needGC(); if (bad) return bad;
  const run = cRun('voidsworn', ['warden'], 1); // warden mounts battery and turret kinds, no lance
  run.inventory = ['crystal']; // Lance focusing crystal: fx lancePct, no only field, no kind field
  const s = run.fleet[0];
  GC.ACT.equip('0:' + s.uid);
  return s.mods.includes('crystal')
    ? 'ACT.equip fitted the Lance focusing crystal to a ship with no lance: equip has no guard at all, and the fit filter cannot see weapon-kind modules because they carry no only field'
    : '';
});

test('ECO-3 decommission value scales with the ship condition', () => {
  const bad = needGC(); if (bad) return bad;
  const run = cRun('voidsworn', [], 1);
  const full = GC.newShip('warden'), hurt = GC.newShip('warden');
  hurt.hp = Math.round(GC.derive(hurt).maxHp * 0.3);
  run.fleet = [full, hurt]; run.flagUid = full.uid; run.credits = 1000;
  GC.shipyardScreen({ id: 'y1', type: 'shipyard', stock: { hulls: [], mods: [], sold: [] } });
  const sells = [...GC.appEl().innerHTML.matchAll(/Decommission \(\+([0-9]+)\)/g)].map(m => +m[1]);
  if (sells.length < 2) return 'could not read two decommission labels from the shipyard render';
  return sells[1] < sells[0] ? '' : 'a warden at 30% hull decommissions for ' + sells[1] + ', the same as a full-hull warden (' + sells[0] + '): the payout is prizeScrap, a function of template only';
});

test('ECO-4 prize money uses the same price rules as the shop', () => {
  const bad = needGC(); if (bad) return bad;
  const run = cRun('voidsworn', ['warden'], 1);
  run.heat = ['h_coffers']; // Coffers heat: shop prices x1.25 through priceMult
  const pm = GC.runIn('priceMult()');
  if (!(pm > 1)) return 'control case broke: priceMult did not rise under the coffers heat';
  const prize = { tpl: 'warden', hpf: 1, cp: 4, wk: [], ab: null, regen: 0, sh: 10 };
  const got = GC.prizeRansom(prize, 0);
  const want = Math.round(GC.runIn("shipValue('warden')") * 0.55 * pm);
  return got === want ? '' : 'with shop prices scaled x' + pm + ', a full-hull warden prize ransoms for ' + got + ' instead of ' + want + ': prizeRansom never passes through priceMult, so the two directions of the same market price differently';
});

test('DRIFT-5 touch text variants are reachable', () => {
  const bad = needGC(); if (bad) return bad;
  GC.setGlobal('G', { mobile: true });
  const out = GC.touchWords('Click a gold hex to move');
  GC.setGlobal('G', undefined);
  return out === 'Tap a gold hex twice to move' ? '' : 'on touch, "Click a gold hex to move" becomes ' + JSON.stringify(out) + ': the chain looks for the already-tapped wording before the generic Click replacement runs, so the double-tap instruction can never be produced';
});

test('UI-7 the help line lists every working key', () => {
  const src = fs.readFileSync(path.join(repoDir, 'ui3d.js'), 'utf8');
  const handled = [...new Set([...src.matchAll(/k==='([a-z])'/g)].map(m => m[1]))];
  const helpM = src.match(/function keysHelp\(\)\{ return `([\s\S]*?)`; \}/);
  if (!helpM) return 'could not locate keysHelp() in ui3d.js';
  const help = helpM[1].toLowerCase();
  const missing = handled.filter(k => !help.includes('<kbd>' + k + '</kbd>'));
  return missing.length ? 'the in-battle help line omits working keys: ' + missing.join(', ') + ' (handled in onKey; some are discoverable only from button titles or not at all)' : '';
});

// ---------- Wave 5 patch pack section 2: hive wings and point defense ----------

test('PP-2 hive wings count toward the enemy point-defense adaptation', () => {
  const run = G.runDefaults();
  run.fac = 'voidsworn'; run.admiral = 'vex'; run.aspect = 'hive'; run.sector = 2; run.foes = null;
  run.fleet = ['warden', 'warden', 'harrow'].map(t => G.newShip(t));
  run.flagUid = run.fleet[0].uid; G.RUN = run;
  G.rndSeed(12345);
  G.startBattle({ kind: 'battle', fac: 'hegemony', col: 3, obj: 'rout', shape: 'open', map: null });
  const B = G.B;
  if (!B) return 'startBattle produced no battle state';
  const pd = B.units.filter(u => u.pdRefit).length;
  return (B.adapt || pd > 0) ? '' : 'a pure-hive fleet (wings only from the flagship aspect) counted as zero carriers: no point-defense adaptation armed';
});

// ---------- round 2 (Oct 30, 2026): battle-probe and UI-state harnesses ----------
//
// The two harnesses round 1 lacked, built the same day. battle_probe.js
// installs sim3d-style animation hooks into the base context so aiUnit can
// run headlessly; ui_loader.js loads ui3d.js behind a registry DOM stub so
// its state functions run for real. The probe install happens at load, so
// the hooks are live while the queued tests run; the round 1 tests were
// re-run against this exact setup and their results are unchanged (the same
// 8 passes), because none of them drive animated movement. Every fixture
// below was validated as a standalone probe first (probes_r2 in the wave 5
// working papers): each scenario either pins its defect at this pin or
// reports that it did not construct, never a silent pass.

const { installBattleProbe, setAiLevel, probeBattle, place, clearTerrain, activateEnemy } = require(path.join(__dirname, 'battle_probe.js'));
const { loadUI } = require(path.join(__dirname, 'ui_loader.js'));
installBattleProbe(G);
setAiLevel(G, 'veteran');
let GU = null, guError = '';
try { GU = loadUI(repoDir); } catch (e) { guError = e.message; }
const needGU = () => GU ? '' : 'UI loader failed to load: ' + guError;

const offH = (c, r) => runIn('offToAx(' + c + ',' + r + ')');
const hdist2 = (a, b) => runIn('hdist({q:' + a.q + ',r:' + a.r + '},{q:' + b.q + ',r:' + b.r + '})');
function faceTowardG(u, t) {
  let bf = 0, bd = 1e9;
  for (let f = 0; f < 6; f++) { const d = runIn('hdist({q:' + (u.q + runIn('DIRS[' + f + '][0]')) + ',r:' + (u.r + runIn('DIRS[' + f + '][1]')) + '},{q:' + t.q + ',r:' + t.r + '})'); if (d < bd) { bd = d; bf = f; } }
  u.facing = bf;
}
function mkWG(id, arc, cdLeft) {
  G._sandbox.__wid = id; G._sandbox.__arc = arc;
  const w = runIn('mkWeapon(__wid, __arc, {})');
  w.fired = false; w.cdLeft = cdLeft || 0; w.off = 0;
  return w;
}

test('BF-1 clearSpawns preserves shape-defining center terrain', () => {
  const BW2 = runIn('BW'), BH2 = runIn('BH'), midR2 = Math.floor(BH2 / 2);
  const mid = runIn('offToAx(' + Math.floor(BW2 / 2) + ',' + midR2 + ')');
  const setup = (dep, shape, map, seed) => {
    const run = G.runDefaults();
    run.fac = 'voidsworn'; run.admiral = 'vex'; run.sector = 2; run.foes = null;
    run.fleet = ['cathedral', 'penitent', 'penitent', 'harrow', 'warden', 'warden'].map(t => G.newShip(t));
    run.flagUid = run.fleet[0].uid; G.RUN = run;
    G.startBattle({ kind: 'battle', fac: 'hegemony', col: 3, obj: 'rout', shape, map, seed, arena: 'strip', dep, enemies: ['h_dominion', 'h_vanguard', 'h_vanguard', 'h_interdictor', 'h_picket', 'h_picket'].map(tpl => ({ tpl })) });
    return G.B;
  };
  const survival = (shape, map, dep, defFn) => {
    let sum = 0, n = 0;
    for (let s = 1; s <= 16; s++) {
      const seed = 4000 + s;
      G.rndSeed(seed);
      const T0 = runIn("genTerrain('" + map + "','" + shape + "',{enc:'rout'})");
      const def = Object.keys(T0).filter(k => T0[k] === 'rock' && defFn(k));
      const B = setup(dep, shape, map, seed);
      if (B.shape !== shape || !def.length) continue;
      sum += def.filter(k => B.terrain[k] === 'rock').length / def.length; n++;
    }
    return n >= 12 ? sum / n : null;
  };
  const ringDef = (k) => { const [q, r] = k.split(',').map(Number); return hdist2({ q, r }, mid) <= 2; };
  const lanesDef = (k) => { const r = +k.split(',')[1]; return r === midR2 || r === midR2 - 1; };
  const ctrl = survival('ring', 'storm', 'line', ringDef);
  const amb = survival('ring', 'storm', 'ambush', ringDef);
  const lanes = survival('lanes', 'storm', 'line', lanesDef);
  if (ctrl == null || amb == null || lanes == null) return 'probe produced too few shape-verified trials';
  if (ctrl < 0.9) return 'control case broke: even line deployment keeps only ' + Math.round(ctrl * 100) + '% of the ring center, so the probe no longer isolates the clearing step';
  const bad = [];
  if (amb < 0.9) bad.push('under ambush deployment the ring center keeps only ' + Math.round(amb * 100) + '% of its defining rock through startBattle (same-seed line control: ' + Math.round(ctrl * 100) + '%)');
  if (lanes < 0.9) bad.push('the lanes barrier keeps only ' + Math.round(lanes * 100) + '% of its rock through startBattle under plain line deployment, eaten from both deployment ends inward');
  return bad.length ? bad.join('; ') + ': clearSpawns deletes terrain around and ahead of wherever the fleets start, so the shapes whose defining terrain sits near a start zone lose it (the Oct 29 Q11 shape-aware clearing is unimplemented)' : '';
});

test('AI-1 veteran brace decision survives the mid-move volley path', async () => {
  setAiLevel(G, 'veteran');
  const B = probeBattle(G, { player: ['penitent', 'penitent', 'penitent'], enemies: ['d_jackal'], fac: 'deathless', seed: 11, arena: 'strip' });
  clearTerrain(G);
  const pens = B.units.filter(u => u.side === 'player');
  [[6, 5], [6, 7], [6, 9]].forEach((p, i) => { const h = offH(p[0], p[1]); place(pens[i], h.q, h.r); });
  const m = B.units.find(u => u.side === 'enemy');
  const mh = offH(14, 7); place(m, mh.q, mh.r);
  pens.forEach(p => faceTowardG(p, m));
  // one spent scattergun (never ready this activation), shields stripped, hull 60%:
  // the ship must move to engage, its volley can never fire, and its numbers meet
  // the veteran brace rule (threat over 45% of hp, no offense, hp under 70%)
  // while missing the volley-path fallback's hp-under-50% gate.
  m.weapons = [mkWG('scatter', 'T', 2)]; m.ab = null; m.maxHp = 100; m.hp = 60; m.sh = [0, 0, 0, 0]; m.shMax = 0;
  const d0 = Math.min(...pens.map(p => hdist2(m, p)));
  await activateEnemy(G, m);
  const d1 = Math.min(...pens.map(p => hdist2(m, p)));
  if (!(d1 < d0)) return 'scenario did not construct: the veteran ship never moved (distance ' + d0 + ' to ' + d1 + '), so the mid-move volley path was not taken';
  if (m.weapons.some(w => w.fired)) return 'scenario did not construct: the ship fired on the move, after which brace is legally impossible in both paths';
  if (m.braced) return '';
  G._sandbox.__u = m;
  const threat = runIn('evalThreat(__u, alive("player"))');
  return 'a veteran ship at ' + Math.round(m.hp / m.maxHp * 100) + '% hull moved ' + d0 + ' to ' + d1 + ' hexes from the enemy line, fired nothing, and ended unbraced under ' + Math.round(threat) + ' expected threat: the mid-move volley path returns before the veteran brace decision, whose conditions its numbers meet (threat over 45% of its ' + m.hp + ' hp, own offense nil), and the volley path\'s own fallback brace demands hp under 50%';
});

test('AI-3 death-cliff weight scales with ship value', async () => {
  setAiLevel(G, 'veteran');
  const C = offH(10, 7);
  const sweep = async (tpl) => {
    let first = null;
    for (const M of [0, 40, 80, 120, 200, 300]) {
      const B = probeBattle(G, { player: ['penitent', 'penitent', 'penitent', 'cathedral'], enemies: [tpl], fac: 'voidsworn', seed: 14, arena: 'strip' });
      clearTerrain(G);
      const p0 = B.units.find(u => u.side === 'player' && u.tpl === 'cathedral');
      const p0h = offH(6, 7); place(p0, p0h.q, p0h.r);
      p0.weapons = []; p0.maxHp = M; p0.hp = 1; p0.ev = 0; p0.ab = null; p0.sh = [0, 0, 0, 0]; p0.shMax = 0;
      const escs = B.units.filter(u => u.side === 'player' && u.tpl === 'penitent');
      [[-3, -2], [-2, -3], [5, -3]].forEach((o, i) => { place(escs[i], C.q + o[0], C.r + o[1]); faceTowardG(escs[i], C); escs[i].ab = null; });
      const m = B.units.find(u => u.side === 'enemy');
      const mh = offH(13, 7); place(m, mh.q, mh.r); faceTowardG(m, C);
      // identical normalised hull numbers for both movers (same gun, speed, hp,
      // shields, armor, evasion): the only difference left is the hull's value
      m.weapons = [mkWG('battery', 'T', 0)]; m.speed = 3; m.maxHp = 100; m.hp = 30; m.sh = [0, 0, 0, 0]; m.shMax = 0; m.armor = .1; m.ev = 10; m.ab = null;
      await activateEnemy(G, m);
      if (first == null && m.q === C.q && m.r === C.r) first = M;
    }
    return first;
  };
  const cheap = await sweep('warden');
  const expensive = await sweep('cathedral');
  if (cheap == null) return 'scenario did not construct: even the cp1 frigate never took the death-cliff hex in the sweep, so there is no switch point to compare';
  if (expensive == null || expensive > cheap) return '';
  return 'the death-cliff switch point is identical for a cp1 frigate and a cp5 battleship (both first accept a hex where expected fire exceeds their hull once the kill behind it is worth ' + cheap + '): the cliff weight is a flat 25, unscaled to the value of the hull put at risk';
});

test('AI-4 a ship with no bearing guns kites instead of closing', async () => {
  setAiLevel(G, 'veteran');
  const B = probeBattle(G, { player: ['warden', 'warden'], enemies: ['warden'], fac: 'voidsworn', seed: 12, arena: 'strip' });
  clearTerrain(G);
  const ps = B.units.filter(u => u.side === 'player');
  ps.forEach((p, i) => { const h = offH(5, 6 + i * 2); place(p, h.q, h.r); p.weapons = []; });
  const m = B.units.find(u => u.side === 'enemy');
  const mh = offH(14, 7); place(m, mh.q, mh.r);
  m.weapons = [mkWG('torp', 'F', 2)]; m.ab = null;
  const d0 = Math.min(...ps.map(p => hdist2(m, p)));
  await activateEnemy(G, m);
  const d1 = Math.min(...ps.map(p => hdist2(m, p)));
  if (m.weapons[0].cdLeft <= 0 && !m.weapons[0].fired) return 'scenario did not construct: the torpedo became ready during the activation, so the ship had a bearing gun after all';
  if (d1 >= d0) return '';
  return 'a ship whose only gun is a reloading torpedo closed from ' + d0 + ' to ' + d1 + ' hexes against unarmed targets: the approach leash (-4 per hex beyond the spent gun\'s minimum range) drags a ship with no bearing guns toward the enemy instead of letting it kite while it reloads';
});

test('AI-5 wing launches account for the launch hex threat', async () => {
  setAiLevel(G, 'veteran');
  const B = probeBattle(G, { player: ['penitent', 'penitent'], enemies: ['reliquary'], fac: 'voidsworn', seed: 13, arena: 'strip' });
  clearTerrain(G);
  const ps = B.units.filter(u => u.side === 'player');
  ps.forEach((p, i) => { const h = offH(6, 6 + i * 2); place(p, h.q, h.r); });
  const c = B.units.find(u => u.side === 'enemy');
  const ch = offH(13, 7); place(c, ch.q, ch.r);
  ps.forEach(p => faceTowardG(p, c));
  B.units.filter(u => u.isSq && u.side === 'enemy').forEach(w => { w.dead = true; }); // the opening wings are gone; this launch replaces them
  G._sandbox.__u = c;
  const hexes = runIn('launchHexes(__u)').map(h => ({ q: h.q, r: h.r, th: runIn('evalThreat(stateView(__u, {q:' + h.q + ',r:' + h.r + ',f:__u.facing}), alive("player"))') }));
  if (!hexes.length) return 'scenario did not construct: the carrier has no launch hexes';
  if (!hexes.some(h => h.th <= 0.01)) return 'scenario did not construct: every launch hex is under fire, so there is no safe choice to prefer';
  await activateEnemy(G, c);
  const wing = B.units.find(u => u.isSq && u.side === 'enemy' && !u.dead);
  if (!wing) return 'scenario did not construct: the carrier never launched during its activation';
  const chosen = hexes.find(h => h.q === wing.q && h.r === wing.r);
  if (!chosen) return 'scenario did not construct: the wing did not launch from a launch hex of the carrier\'s start position';
  if (chosen.th <= 0.01) return '';
  return 'the carrier launched its wing into ' + Math.round(chosen.th) + ' expected threat while launch hexes with no incoming fire existed: aiAbilities launches before moving, from the launch hex nearest the enemy, sorted by distance only, so a launch can be baited into a kill zone';
});

function uiBattle(playerTpls, enemyTpls) {
  const run = GU.runDefaults();
  run.fac = 'voidsworn'; run.admiral = 'vex'; run.sector = 1; run.foes = null;
  run.fleet = playerTpls.map(t => GU.newShip(t));
  run.flagUid = run.fleet[0].uid; GU.RUN = run;
  GU._sandbox.__cfg = { kind: 'battle', fac: 'hegemony', col: 3, obj: 'rout', shape: 'open', map: 'storm', dep: 'line', arena: 'strip', seed: 99, enemies: enemyTpls.map(tpl => ({ tpl })) };
  GU.runInUI('startBattle(__cfg);');
  return GU.B;
}

test('UI-5 cancel paths clear the sticky wing selection', () => {
  const bad = needGU(); if (bad) return bad;
  const B = uiBattle(['reliquary', 'warden', 'warden'], ['h_picket']);
  const wing = B.units.find(u => u.isSq && u.side === 'player');
  const ship = B.units.find(u => !u.isSq && u.side === 'player' && u.tpl === 'warden');
  if (!wing || !ship) return 'scenario did not construct: no player wing or ship in the fixture battle';
  const stuck = [];
  B.wingSel = wing;
  GU.runInUI('selectUnit(B.units.find(u => u.tpl === "warden" && u.side === "player"))');
  if (B.wingSel) stuck.push('selectUnit');
  B.wingSel = wing;
  GU.ACT.rosterPick(ship.id);
  if (B.wingSel) stuck.push('rosterPick');
  B.wingSel = wing; B.sel = ship; B.mode = null; B.armed = null;
  for (let i = 0; i < 3; i++) GU.runInUI('onKey({ key: "Escape", target: { tagName: "DIV" }, preventDefault() {} })');
  if (B.wingSel) stuck.push('Escape through the full cancelAction chain');
  return stuck.length ? 'wingSel survives ' + stuck.join(', ') + ': with a wing selected, switching ships or cancelling leaves the wing order armed, so the next board tap assigns a wing order the player no longer means to give' : '';
});

test('UI-6 the hint line never declares a ship finished while it can still act', () => {
  const bad = needGU(); if (bad) return bad;
  const B = uiBattle(['warden'], ['h_picket', 'h_picket']);
  const u = B.units.find(x => x.side === 'player');
  B.units.filter(x => x.side === 'enemy').forEach((e, i) => { e.q = 20; e.r = 3 + i; });
  GU.runInUI('OV.targets = [];');
  B.reach = null; B.wingSel = null; B.why = null; B.mode = null; B.sel = u;
  const hint = () => { const h = GU.runInUI('actionStrip(B.units.find(x => x.side === "player"))'); const mm = h.match(/<div class="striphint">([\s\S]*?)<\/div>/); return mm ? mm[1] : ''; };
  const badCases = [];
  u.mp = 2; // moved some, most of its 6 movement remains, nothing in range
  if (hint().includes('Nothing left to do') && u.mp > 0) badCases.push('movement remaining (' + u.mp + ' of ' + u.speed + ' points)');
  u.mp = 0; // fully moved, weapons unfired, Brace still open
  if (hint().includes('Nothing left to do') && GU.runInUI('canOrder(B.units.find(x => x.side === "player"), "brace")')) badCases.push('an unspent Brace');
  return badCases.length ? "the hint line reads 'Nothing left to do: tap Done with ship.' while the ship still has " + badCases.join(' and ') + ': the hint chain checks ram, targets and first-move only, never remaining movement or the Brace order' : '';
});

test('UI-8 auto-facing weighs shield facings, and arming recomputes reach', () => {
  const bad = needGU(); if (bad) return bad;
  const parts = [];
  {
    const B = uiBattle(['penitent'], ['h_picket']);
    B.terrain = {};
    const u = B.units.find(x => x.side === 'player');
    const foe = B.units.find(x => x.side === 'enemy');
    GU._sandbox.__wid = 'turret'; GU._sandbox.__arc = 'T';
    const w = GU.runInUI('mkWeapon(__wid, __arc, {})'); w.fired = false; w.cdLeft = 0; w.off = 0;
    u.weapons = [w]; // a turret bears from every facing, so gun count ties across facings
    u.sh = [40, 4, 40, 40]; u.shMax = 40;
    const dest = { q: u.q + 2, r: u.r }; foe.q = dest.q + 2; foe.r = dest.r;
    let fWeak = -1, fStrong = -1;
    for (let f = 0; f < 6; f++) {
      GU._sandbox.__f = f; GU._sandbox.__d = dest;
      const q = GU.runInUI('shieldQuad(stateView(B.units.find(x => x.side === "player"), { q: __d.q, r: __d.r, f: __f }), B.units.find(x => x.side === "enemy"))');
      if (q === 1 && fWeak < 0) fWeak = f;
      if (q === 0 && fStrong < 0) fStrong = f;
    }
    if (fWeak < 0 || fStrong < 0) return 'scenario did not construct: no facing pair exposes the weak and strong shields to the enemy';
    GU._sandbox.__R = { states: [{ q: dest.q, r: dest.r, f: fWeak, cost: 2, t: 0, path: [] }, { q: dest.q, r: dest.r, f: fStrong, cost: 2, t: 0, path: [] }], map: new Map() };
    const chosenF = GU.runInUI('bestFacingReach(B.units.find(x => x.side === "player"), __R).map.get(hkey(__R.states[0].q, __R.states[0].r)).f');
    if (chosenF !== fStrong) parts.push('on a gun-count tie bestFacingReach keeps the facing that exposes the 4-point shield over the one presenting the 40-point shield: its score is gun count, cost and turns only, never the ship\'s own shield facings');
  }
  {
    uiBattle(['penitent'], ['h_picket']);
    GU.runInUI('selectUnit(B.units.find(x => x.side === "player"))');
    const before = GU.B.reach;
    GU.ACT.arm(1);
    if (GU.B.reach === before) parts.push('ACT.arm leaves B.reach as the same object, so after arming a single weapon the reach overlay still shows gun counts computed for the whole battery');
  }
  return parts.join('; ');
});

// ---------- summary ----------

(async () => {
  for (const [id, fn] of queue) {
    let detail;
    try { detail = await fn(); }
    catch (e) { detail = 'threw: ' + e.message; }
    record(id, detail || '');
  }
  console.log('---');
  console.log(checks + ' tests, ' + (checks - failures) + ' pass, ' + failures + ' fail');
  console.log(failures ? 'Failing tests pin defects that are still unfixed at this pin; see the ledger README.' : 'All pinned findings are fixed at this pin.');
  process.exit(failures ? 1 : 0);
})();
