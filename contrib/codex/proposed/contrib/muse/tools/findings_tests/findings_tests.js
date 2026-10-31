'use strict';
// findings_tests.js - regression tests for the Voidsworn findings-to-tests ledger (wave 5, slate item 4).
// Each test pins one BLOCKER or FIX-level finding from the Oct 27 / Oct 28 / Oct 29 audit programs,
// the wave 3 deep QA sweep, or the wave 5 patch pack, at code pin 264f441d.
// A test that FAILS here is a correct regression test: it means the underlying defect is still
// unfixed in the game data/code. Tests were not weakened to pass. When Opus lands a fix, the
// matching test should flip to PASS without edits; if a fix takes a different shape than the
// finding assumed, update the test and the ledger row together.
// Run: node findings_tests.js [repoDir]   (exit 1 while any pinned defect is unfixed)
const path = require('path');
const vm = require('vm');
const { loadGame } = require(path.join(__dirname, '..', 'harness', 'game_loader.js'));
const repoDir = process.argv[2] || path.resolve(__dirname, '..', '..', '..', '..');
const G = loadGame(repoDir);
const runIn = (code) => vm.runInContext(code, G._sandbox);

let checks = 0, failures = 0;
const results = [];
function test(id, fn) {
  checks++;
  let detail = '';
  try { detail = fn() || ''; }
  catch (e) { detail = 'threw: ' + e.message; }
  if (detail) { failures++; results.push([id, 'FAIL', detail]); console.log('FAIL ' + id + ': ' + detail); }
  else { results.push([id, 'PASS', '']); console.log('PASS ' + id); }
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

// ---------- summary ----------

console.log('---');
console.log(checks + ' tests, ' + (checks - failures) + ' pass, ' + failures + ' fail');
console.log(failures ? 'Failing tests pin defects that are still unfixed at this pin; see the ledger README.' : 'All pinned findings are fixed at this pin.');
process.exit(failures ? 1 : 0);
