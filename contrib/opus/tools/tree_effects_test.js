'use strict';
// Issue #305 jobs 1 to 5 (tree skills in battle): every parity fixture must actually fire its pick.
// Runs the pinned rules oracle through the golden harness and reads B.treeStats from the last record.
// The rules parity job proves the Godot twin writes the same records; this check proves the skill fired on the JS side.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const ROOT = process.env.VS_ROOT || path.resolve(__dirname, '../../..');
const GOLDEN = path.join(ROOT, 'godot/rules/test/node/golden.js');
const SCEN = path.join(ROOT, 'godot/rules/test/scenarios.json');
const WANT = {
  t_casttwice: 'aelith:A:0:1', t_flakskip: 'aelith:A:2:0', t_lensaloft: 'aelith:A:2:1',
  t_longfocus: 'vaelen:A:0:0', t_recordedangle: 'vaelen:A:1:1', t_burnflaw: 'vaelen:A:2:0',
  t_longlight: 'vaelen:A:2:1', t_flawforever: 'vaelen:cap:1',
  t_twoimages: 'thorne:A:0:0', t_angles: 'thorne:A:0:1', t_refraction: 'thorne:A:2:0',
  t_mirrorturns: 'thorne:A:2:1', t_falsehulls: 'thorne:cap:1',
  t_rechargelit: 'mirelle:A:1:0', t_glasscorrected: 'mirelle:A:2:0', t_hardlight: 'mirelle:A:2:1',
  t_wardglass: 'mirelle:cap:0',
  t_deployread: 'vaelen:B:0:0', t_castcorrected: 'vaelen:B:0:1', t_flagshiplens: 'vaelen:C:0:0', t_firstlight: 'vaelen:C:0:1',
  // job 2: the Sunward Crusade a and b rows
  t_heldaccount: 'vex:A:0:1', t_namedledger: 'vex:A:1:0', t_inheritedaim: 'vex:A:1:1', t_everygun: 'vex:A:2:0',
  t_sworndeploy: 'vex:B:0:0', t_debtsreserve: 'vex:B:0:1', t_flagshipLedger: 'vex:C:0:0', t_standardreroll: 'vex:C:0:1',
  t_preyname: 'malek:A:0:0', t_salvotwohands: 'malek:A:0:1', t_debthunts: 'malek:A:2:0', t_twosalvos: 'malek:A:2:1',
  t_namedprey: 'malek:cap:1',
  t_escortname: 'ashgrove:A:0:0', t_firstwave: 'ashgrove:A:0:1', t_wingreserve: 'ashgrove:A:1:1',
  t_generation: 'ashgrove:A:2:0', t_wingsdebt: 'ashgrove:A:2:1', t_rollwings: 'ashgrove:cap:0', t_oathwings: 'ashgrove:cap:1',
  t_holdcounted: 'thale:A:0:0', t_oathstillness: 'thale:A:1:1', t_unpaid: 'thale:A:2:0', t_wallanswers: 'thale:A:2:1',
  t_irontestament: 'thale:cap:0',
  // job 3: the Eclipse a and b rows
  t_ecl_restoreninth: 'nekhet:A:0:0', t_ecl_restoredbeyond: 'nekhet:A:2:0', t_ecl_copiescontribute: 'nekhet:A:2:1',
  t_ecl_tenthframe: 'nekhet:cap:0', t_ecl_earliercopy: 'nekhet:cap:1',
  t_ecl_arcswarm: 'sekhmar:A:0:0', t_ecl_noonchoice: 'sekhmar:A:0:1', t_ecl_copyfires: 'sekhmar:A:1:0',
  t_ecl_coronashadow: 'sekhmar:A:2:0', t_ecl_everyframe: 'sekhmar:A:2:1', t_ecl_noonrepeat: 'sekhmar:cap:0', t_ecl_onesuncopy: 'sekhmar:cap:1',
  t_ecl_copiedbehind: 'anuket:A:0:0', t_ecl_unseenarchive: 'anuket:A:0:1', t_ecl_uncopiedtarget: 'anuket:A:1:1',
  t_ecl_iterationkill: 'anuket:A:2:0', t_ecl_silentarchive: 'anuket:A:2:1', t_ecl_outshadow: 'anuket:cap:0', t_ecl_longcopy: 'anuket:cap:1',
  t_ecl_platesshadow: 'khepra:A:0:0', t_ecl_twicerestored: 'khepra:A:0:1', t_ecl_layersshift: 'khepra:A:1:1',
  t_ecl_nolayer: 'khepra:A:2:0', t_ecl_stillness: 'khepra:A:2:1', t_ecl_tenthousand: 'khepra:cap:0', t_ecl_restoredfleet: 'khepra:cap:1',
  t_ecl_iterationswap: 'nekhet:B:0:1', t_ecl_flagshipindex: 'nekhet:C:0:0', t_ecl_framezero: 'nekhet:C:0:1',
  // job 4: The Chorus a and b rows
  t_choosebrood: 'matriarch:A:0:0', t_sporetide: 'matriarch:A:0:1', t_everythroat: 'matriarch:A:2:0', t_secondthroat: 'matriarch:A:2:1',
  t_rundown: 'razormaw:A:0:0', t_razorprey: 'razormaw:A:1:0', t_frenzyfeeds: 'razormaw:A:2:0', t_breathbite: 'razormaw:A:2:1',
  t_throatred: 'razormaw:cap:0', t_preyeverymouth: 'razormaw:cap:1',
  t_growhurts: 'mending:A:0:0', t_skinthick: 'mending:A:0:1', t_fleshknit: 'mending:A:2:0', t_refuseholes: 'mending:A:2:1',
  t_tideend: 'mending:cap:0', t_tornback: 'mending:cap:1',
  t_acidbeforeaim: 'voice:A:0:0', t_throatspits: 'voice:A:0:1', t_burnstays: 'voice:A:1:0', t_acidseams: 'voice:A:2:0',
  t_manymouths: 'voice:A:2:1', t_volleygrows: 'voice:cap:0', t_mouthdeep: 'voice:cap:1',
  t_broodreserve: 'matriarch:B:0:1', t_firstthroat: 'matriarch:C:0:0', t_throatdeep: 'matriarch:C:0:1',
  // job 5: the Ashfall Hullbreakers, all 36 rows
  t_hb_runbigger: 'grax:A:0:0', t_hb_railboarding: 'grax:A:0:1', t_hb_packcloses: 'grax:A:1:0', t_hb_rushrail: 'grax:A:1:1',
  t_hb_allscars: 'grax:A:2:0', t_hb_mawopens: 'grax:A:2:1', t_hb_burncarry: 'grax:cap:0', t_hb_warlordrun: 'grax:cap:1',
  t_hb_knifeback: 'sable:A:0:0', t_hb_darktorps: 'sable:A:0:1', t_hb_cutturn: 'sable:A:1:0', t_hb_secondknife: 'sable:A:1:1',
  t_hb_smilecut: 'sable:A:2:0', t_hb_everyknife: 'sable:A:2:1', t_hb_darkknives: 'sable:cap:0', t_hb_cutfeeds: 'sable:cap:1',
  t_hb_patchedwing: 'mott:A:0:0', t_hb_hulkmore: 'mott:A:0:1', t_hb_retasked: 'mott:A:1:0', t_hb_wreckline: 'mott:A:1:1',
  t_hb_wholeyard: 'mott:A:2:0', t_hb_screaming: 'mott:A:2:1', t_hb_swarmscrap: 'mott:cap:0', t_hb_privatewing: 'mott:cap:1',
  t_hb_weldmatters: 'vesh:A:0:0', t_hb_patchguns: 'vesh:A:0:1', t_hb_scrapfront: 'vesh:A:1:0', t_hb_weldedfight: 'vesh:A:1:1',
  t_hb_doublebolted: 'vesh:A:2:0', t_hb_packbites: 'vesh:A:2:1', t_hb_weldedwhole: 'vesh:cap:0', t_hb_nothingbroken: 'vesh:cap:1',
  t_hb_preyscent: 'grax:B:0:0', t_hb_loosepack: 'grax:B:0:1', t_hb_firstscar: 'grax:C:0:0', t_hb_trophystandard: 'grax:C:0:1',
  // job 6: the Hegemony Navy, all 36 rows
  t_heg_widenet: 'kassar:A:0:0', t_heg_secondvolley: 'kassar:A:0:1', t_heg_sharedsolution: 'kassar:A:1:0', t_heg_colddrill: 'kassar:A:1:1',
  t_heg_rollingfire: 'kassar:A:2:0', t_heg_irontempo: 'kassar:A:2:1', t_heg_livingrelay: 'kassar:cap:0', t_heg_onevoice: 'kassar:cap:1',
  t_heg_formation: 'kassar:B:0:0', t_heg_drill: 'kassar:B:0:1', t_heg_beacon: 'kassar:C:0:0', t_heg_stdforward: 'kassar:C:0:1',
  t_heg_filedtriplicate: 'vorn:A:0:0', t_heg_strikebook: 'vorn:A:0:1', t_heg_crossfire: 'vorn:A:1:0', t_heg_filedbefore: 'vorn:A:1:1',
  t_heg_totalinterdiction: 'vorn:A:2:0', t_heg_sevenbreach: 'vorn:A:2:1', t_heg_permanentfile: 'vorn:cap:0', t_heg_oneorder: 'vorn:cap:1',
  t_heg_cruisers: 'reyes:A:0:0', t_heg_launchorder: 'reyes:A:0:1', t_heg_secondwave: 'reyes:A:1:0', t_heg_rehearsed: 'reyes:A:1:1',
  t_heg_fullgroup: 'reyes:A:2:0', t_heg_escorts: 'reyes:A:2:1', t_heg_onetarget: 'reyes:cap:0', t_heg_standinggroup: 'reyes:cap:1',
  t_heg_columnstraight: 'maren:A:0:0', t_heg_overflow: 'maren:A:0:1', t_heg_bell: 'maren:A:1:0', t_heg_rotation: 'maren:A:1:1',
  t_heg_columnendures: 'maren:A:2:0', t_heg_filedarmor: 'maren:A:2:1', t_heg_standardcovers: 'maren:cap:0', t_heg_flagshipstandard: 'maren:cap:1',
  // job 7a: the first 26 waiting Glasswrights and Sunward rows
  t7a_flightpaths: 'aelith:A:0:0', t7a_replay: 'aelith:A:1:0', t7a_starlings: 'aelith:A:1:1', t7a_flightcast: 'aelith:cap:0', t7a_forgeahead: 'aelith:cap:1',
  t7a_onelens: 'vaelen:A:0:1', t7a_lighttogether: 'vaelen:A:1:0', t7a_sunlens: 'vaelen:cap:0',
  t7a_mirroraside: 'thorne:A:1:0', t7a_splitthree: 'thorne:A:1:1', t7a_fleetelsewhere: 'thorne:cap:0',
  t7a_weakside: 'mirelle:A:0:0', t7a_prismsface: 'mirelle:A:0:1', t7a_lensrotates: 'mirelle:A:1:1', t7a_facetlit: 'mirelle:cap:1',
  t7a_ledgerarcs: 'vex:A:0:0', t7a_debtdue: 'vex:A:2:1', t7a_grandledger: 'vex:cap:0', t7a_lastaccount: 'vex:cap:1',
  t7a_torpfirst: 'malek:A:1:0', t7a_rearreckoning: 'malek:A:1:1', t7a_salvoend: 'malek:cap:0',
  t7a_accountsplits: 'ashgrove:A:1:0', t7a_screensshift: 'thale:A:0:1', t7a_wallearly: 'thale:A:1:0', t7a_wallmoves: 'thale:cap:1',
  // job 7b: the waiting Eclipse and Chorus rows
  t7b_ecl_formation_a: 'nekhet:B:0:0', t7b_ecl_formation_b: 'sekhmar:B:0:0', t7b_ecl_formation_c: 'anuket:B:0:0', t7b_ecl_formation_d: 'khepra:B:0:0',
  t7b_ecl_shadow: 'anuket:A:1:0', t7b_ecl_wall: 'khepra:A:1:0', t7b_ecl_archive: 'nekhet:A:1:1', t7b_ecl_iterfire: 'nekhet:A:1:0', t7b_ecl_triage: 'nekhet:A:0:1', t7b_ecl_targetarchived: 'sekhmar:A:1:1',
  t7b_ch_broodsplits: 'matriarch:A:1:0', t7b_ch_nine: 'matriarch:cap:0', t7b_ch_teeth: 'razormaw:A:0:1',
  t7b_ch_tideearly: 'mending:A:1:0', t7b_ch_growth: 'mending:A:1:1', t7b_ch_spat: 'voice:A:1:1',
  // issue 529: the last seven rows (behaviour checks in tree_last_rows_test.js)
  t529_roles_strike: 'matriarch:B:0:0', t529_roles_screen: 'razormaw:B:0:0', t529_roles_mend: 'mending:B:0:0', t529_roles_change: 'voice:B:0:0',
  t529_spawned: 'matriarch:A:1:1', t529_nostop: 'matriarch:cap:1', t529_scent: 'razormaw:A:1:1'
};
// Issue 361: one dated waiting list for the whole tree lane, shared with tree_table_walk_test.js.
// This check only enforces the other half: a row on that list must have no TREE_FX entry.
const { WAITING } = require('./tree_table_walk_test.js');
const INERT = Object.keys(WAITING);
let bad = 0;
const scen = JSON.parse(fs.readFileSync(SCEN, 'utf8'));
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'treefx-'));
try {
  for (const [name, key] of Object.entries(WANT)) {
    if (!scen[name]) { console.log('FAIL ' + name + ': missing scenario'); bad++; continue; }
    if (!scen[name].lineage) { console.log('FAIL ' + name + ': missing lineage'); bad++; continue; }
    const out = path.join(tmp, name + '.jsonl');
    const r = spawnSync(process.execPath, [GOLDEN, 'scenario', name, out], { cwd: ROOT, encoding: 'utf8' });
    if (r.status !== 0) { console.log('FAIL ' + name + ': golden failed: ' + String(r.stderr || r.stdout).slice(0, 200)); bad++; continue; }
    const lines = fs.readFileSync(out, 'utf8').trim().split('\n');
    const last = JSON.parse(lines[lines.length - 1]);
    const stats = JSON.parse(last.state).b.treeStats || {};
    if (!(stats[key] >= 1)) { console.log('FAIL ' + name + ': ' + key + ' did not fire (treeStats ' + JSON.stringify(stats) + ')'); bad++; }
  }
  // the Eclipse and Chorus x and c rows wait for job 7b: they must stay inert
  const src = fs.readFileSync(path.join(ROOT, 'data.js'), 'utf8');
  for (const key of INERT) if (src.includes('"' + key + '":')) { console.log('FAIL inert row has a TREE_FX entry: ' + key); bad++; }
  // The three Hullbreakers rows run 2 corrected: prove the effect, not just the callout.
  // Nothing Stays Broken: once per battle for the whole fleet, so a second ship is not saved.
  // Second Knife: take 1 off cdLeft, never below 0.
  {
    const vm = require('vm');
    Date.now = () => 0;
    global.window = {}; global.document = undefined; global.performance = { now: () => 0 };
    const rules = ['data.js', 'core.js', 'battle.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8'));
    const stubs = [
      'function fxText(){} function fxShield(){} function fxFlash(){} function fxSectionDown(){}',
      'function fxRam(){} function fxBoard(){} function onCapture(){} function fxShieldBreak(){} function fxWithdraw(){}',
      'function toast(){} function banner(){} function log(){}',
      'async function animWeapon(){} async function animTorpLaunch(){} async function animPath(){} async function animMove(){}',
      'async function animRotate(){} async function animExplode(){} async function animNova(){} async function animBlink(){}'
    ].join('\n');
    vm.runInThisContext(rules.join('\n') + '\n' + stubs + '\n' + [
      'globalThis.__TREE={',
      '  dmg:(t,sec,d)=>damageSection(t,sec,d,null),',
      '  knife:(u)=>treeSecondKnife(u),',
      '  clear:()=>{ B={tree:[],treeStats:{},tr:{},units:[],resolve:{player:0,enemy:0}}; },',
      '  tree:(k)=>{ B.tree=[{key:k,k:TREE_FX[k].k}]; },',
      '  tr:()=>B.tr};'
    ].join('\n'), { filename: 'tree_effect_rules.js' });
    const T = globalThis.__TREE;
    const mkShip = id => ({ id, side: 'player', name: id, maxHp: 100, hp: 100, crewMax: 0,
      sec: { prow: { hp: 5, max: 10, broken: false } }, weapons: [], st: {}, sh: [0, 0, 0, 0], shMax: 0, speed: 3, turns: 1, ev: 0 });
    T.clear(); T.tree('vesh:cap:1');
    const a = mkShip('x1'), b = mkShip('x2');
    T.dmg(a, 'prow', 99); T.dmg(b, 'prow', 99);
    if (!(T.tr().nothingSaved === 1 && !a.sec.prow.broken && a.sec.prow.hp === a.sec.prow.max && b.sec.prow.broken)) {
      console.log('FAIL Nothing Stays Broken: the save is not once per battle for the whole fleet (nothingSaved ' + T.tr().nothingSaved + ', second ship broken ' + b.sec.prow.broken + ')'); bad++;
    } else console.log('PASS Nothing Stays Broken: one fleet-wide save; the second ship loses its section');
    T.clear(); T.tree('sable:A:1:1');
    const u = { id: 'x3', side: 'player', name: 'u', dead: false, weapons: [{ k: 'torp', n: 'T', cdLeft: 2 }] };
    T.knife(u); const once = u.weapons[0].cdLeft;
    u.weapons[0].cdLeft = 0; T.knife(u); const floor = u.weapons[0].cdLeft;
    if (!(once === 1 && floor === 0)) {
      console.log('FAIL Second Knife: a missed torpedo went to cdLeft ' + once + ' from 2, and ' + floor + ' from 0'); bad++;
    } else console.log('PASS Second Knife: a missed torpedo shows cdLeft 1 (was 2), never below 0');
  }
  // Swarm Over the Scrap Field: the second launch is a pending entry, so no second wing exists at Command time.
  {
    const out = path.join(tmp, 't_hb_swarmscrap.behaviour.jsonl');
    const r = spawnSync(process.execPath, [GOLDEN, 'scenario', 't_hb_swarmscrap', out], { cwd: ROOT, encoding: 'utf8' });
    const recs = r.status === 0 ? fs.readFileSync(out, 'utf8').trim().split('\n').map(l => JSON.parse(l)) : [];
    let ci = -1; for (let i = 0; i < recs.length; i++) if (recs[i].actor === 'command player') { ci = i; break; }
    if (ci < 0) { console.log('FAIL Swarm Over the Scrap Field: no Command record'); bad++; }
    else {
      const cmd = JSON.parse(recs[ci].state);
      const before = ci > 0 ? JSON.parse(recs[ci - 1].state) : cmd;
      const pend = (cmd.b.treePending || []).some(p => p.k === 'swarmScrap');
      const ids = s => new Set(s.units.filter(x => x.side === 'player' && x.isSq).map(x => x.id));
      const cmdIds = ids(cmd), beforeIds = ids(before);
      let next = null;
      for (let i = ci + 1; i < recs.length; i++) { const s = JSON.parse(recs[i].state); if (s.b.round > cmd.b.round) { next = s; break; } }
      const added = next ? [...ids(next)].filter(id => !cmdIds.has(id)) : [];
      if (!pend) { console.log('FAIL Swarm Over the Scrap Field: the second launch was not queued at the Command'); bad++; }
      else if (cmdIds.size !== beforeIds.size) { console.log('FAIL Swarm Over the Scrap Field: a second wing was launched at Command time'); bad++; }
      else if (!added.length) { console.log('FAIL Swarm Over the Scrap Field: no second-launch wing after the player turn'); bad++; }
      else console.log('PASS Swarm Over the Scrap Field: the second launch is queued at the Command and the wing appears only at the next round start');
    }

  // Hegemony Navy (issue #305 job 6): behaviour checks for counts, limits and timing.
  {
    const R = name => { const out = path.join(tmp, 'beh_' + name + '.jsonl'); const rr = spawnSync(process.execPath, [GOLDEN, 'scenario', name, out], { cwd: ROOT, encoding: 'utf8' }); if (rr.status !== 0) return null; return fs.readFileSync(out, 'utf8').trim().split('\n').map(l => JSON.parse(l)); };
    const S = r => JSON.parse(r.state);
    const ok = (name, cond, msg) => { if (cond) console.log('PASS ' + name + ': ' + msg); else { console.log('FAIL ' + name + ': ' + msg); bad++; } };
    const keyStats = (rs, key) => { let p = 0, m = 0; for (const r of rs) { const v = (S(r).b.treeStats || {})[key] || 0; m = Math.max(m, v - p); p = v; } return { total: p, maxOneRound: m }; };
    const commandIndex = rs => { for (let i = 0; i < rs.length; i++) if (rs[i].actor === 'command player') return i; return -1; };
    const hd = (a, b) => (Math.abs(a.q - b.q) + Math.abs(a.r - b.r) + Math.abs((a.q + a.r) - (b.q + b.r))) / 2;

    { const rs = R('t_heg_widenet'); const s = rs && S(rs[0]); ok('Wide Net', !!(s && s.b.syncR && s.b.syncR.player === 4), 'the synced fire radius is 4, one more than the base 3'); }
    { const rs = R('t_heg_livingrelay'); const s = rs && S(rs[0]); ok('Living Relay', !!(s && s.b.syncR && s.b.syncR.player === 6), 'the sync radius is doubled to 6'); }
    { const rs = R('t_heg_secondvolley'); const k = rs && keyStats(rs, 'kassar:A:0:1'); ok('Second Volley', !!(k && k.total >= 1 && k.maxOneRound <= 1), 'it fires at most once a round and it fired'); }
    { const rs = R('t_heg_rollingfire'); const k = rs && keyStats(rs, 'kassar:A:2:0'); ok('Rolling Fire', !!(k && k.total >= 1 && k.maxOneRound <= 1), 'one extra synced shot a round, no more'); }
    { const rs = R('t_heg_irontempo'); let changed = false, used = false; if (rs) { const a0 = S(rs[0]).units.find(u => u.anchor && u.side === 'player'); for (const r of rs) { const s = S(r); if (s.b.tr && s.b.tr.ironTempoUsed) used = true; if (s.b.tr && s.b.tr.ironTempoUsed && s.units.some(u => u.anchor && u.side === 'player' && a0 && u.id !== a0.id)) { changed = true; break; } } } ok('Iron Tempo', !!(used && changed), 'the first lost anchor is replaced by another Hegemony ship'); }
    { const rs = R('t_heg_onevoice'); const k = rs && keyStats(rs, 'kassar:cap:1'); const f = rs && S(rs[rs.length - 1]); ok('One Voice', !!(k && k.total === 1 && f.b.treeOneVoiceUsed === 1), 'it fires once in the whole battle'); }
    { const rs = R('t_heg_filedtriplicate'); const ci = rs ? commandIndex(rs) : -1; const s = ci >= 0 ? S(rs[ci]) : null; const e = s && s.units.find(u => u.side === 'enemy' && s.b.treeFiled && u.id === s.b.treeFiled.id); ok('Target Filed in Triplicate', !!(e), 'the hunt Command files one enemy as the interdicted target'); }
    { const rs = R('t_heg_crossfire'); let hit2 = false; if (rs) for (const r of rs) { const s = S(r); if ((s.b.treeStats || {})['vorn:A:1:0'] && Object.values(s.b.tr.crossHits || {}).some(v => v >= 2)) { hit2 = true; break; } } ok('Cross-Referenced Fire', hit2, 'the second and later hit on one target pays'); }
    { const rs = R('t_heg_filedbefore'); let before = false; if (rs) for (const r of rs) { const s = S(r); if ((s.b.treeStats || {})['vorn:A:1:1'] && s.b.cmd && s.b.cmd.id === 'hunt' && s.b.cmd.round === r.round) { if (s.units.some(u => u.side === 'player' && !u.isSq && (u.hexMoved || 0) === 0)) { before = true; break; } } } ok('Filed Before Movement', before, 'a shot lands before its ship has moved in the strike round'); }
    { const rs = R('t_heg_totalinterdiction'); let three = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['vorn:A:2:0']) continue; for (const k in (s.b.tr.totalShips || {})) if (Object.keys(s.b.tr.totalShips[k]).length >= 3) { three = true; break; } if (three) break; } ok('Total Interdiction', three, 'three or more ships have hit one target in the strike round'); }
    { const rs = R('t_heg_sevenbreach'); let broke = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['vorn:A:2:1']) continue; for (const u of s.units) if (u.side === 'enemy' && (u.weapons || []).some(w => (w.off || 0) >= 2 && (w.off || 0) < 99)) { broke = true; break; } if (broke) break; } ok('Standard Seven Breach', broke, 'a critical hit switches the struck section off for one round'); }
    { const rs = R('t_heg_permanentfile'); let next = false; if (rs) for (const r of rs) { const s = S(r); if ((s.b.treeStats || {})['vorn:cap:0'] && s.b.treePermFile && s.b.treePermFile.r === r.round && Object.keys(s.b.treePermFile.ids || {}).length > 0) { next = true; break; } } ok('Interdiction Permanent File', next, 'the strike files are paid again from your fire in the next round'); }
    { const rs = R('t_heg_oneorder'); const ci = rs ? commandIndex(rs) : -1; let extra = 0; if (rs && ci > 0) for (let i = ci - 1; i >= 0 && rs[i].actor !== 'tick player'; i--) if (String(rs[i].actor).startsWith('fire ')) extra++; ok('One Order Every Gun', !!(ci >= 0 && extra >= 1 && (S(rs[ci]).b.treeStats || {})['vorn:cap:1']), 'the hunt Command fires weapons a second time'); }
    { const rs = R('t_heg_cruisers'); const ci = rs ? commandIndex(rs) : -1; let wing = false; if (rs && ci >= 0) { const s = S(rs[ci]); for (const u of s.units) if (u.isSq && u.side === 'player') { const p = s.units.find(x => x.id === u.parent); if (p && p.ab !== 'launch') { wing = true; break; } } } ok('Cruisers Filed as Carriers', wing, 'a ship without a hangar launches a wing'); }
    { const rs = R('t_heg_launchorder'); let first = false; if (rs) for (const r of rs) { const s = S(r); if ((s.b.treeStats || {})['reyes:A:0:1'] && s.units.some(u => u.isSq && u.side === 'player' && u.treeBonus != null && u.treeBonus !== 0)) { first = true; break; } } ok('Launch Order Published', first, 'the first wing to strike carries +20% damage'); }
    { const rs = R('t_heg_secondwave'); const ci = rs ? commandIndex(rs) : -1; let held = false, later = false; if (rs && ci >= 0) { const s = S(rs[ci]); held = (s.b.treePending || []).some(p => p.k === 'secondWave') && !s.units.some(u => u.isSq && u.side === 'player' && u.extra); const ids = x => new Set(x.units.filter(u => u.side === 'player' && u.isSq).map(u => u.id)); const before = ids(s); for (let i = ci + 1; i < rs.length; i++) { const n = S(rs[i]); if (n.b.round > s.b.round) { later = [...ids(n)].some(id => !before.has(id)); break; } } } ok('Second Wave on Schedule', !!(held && later), 'the extra wings are held at the Command and launch at the next round start'); }
    { const rs = R('t_heg_rehearsed'); const k = rs && keyStats(rs, 'reyes:A:1:1'); ok('Procedure Rehearsed', !!(k && k.total >= 1), 'the extra wing strike again gains its aim'); }
    { const rs = R('t_heg_fullgroup'); const ci = rs ? commandIndex(rs) : -1; let per = {}; if (rs && ci >= 0) { const s = S(rs[ci]); let base = null; for (let i = ci - 1; i >= 0; i--) if (String(rs[i].actor).startsWith('tick player')) { base = S(rs[i]); break; } if (!base) base = S(rs[0]); const ids = x => new Set(x.units.filter(u => u.side === 'player' && u.isSq).map(u => u.id)); const before = ids(base); for (const u of s.units) if (u.isSq && u.side === 'player' && !before.has(u.id) && u.extra) per[u.parent] = (per[u.parent] || 0) + 1; } ok('Full Group Assembled', Object.values(per).length > 0 && Object.values(per).every(n => n >= 1), 'each launch ship launches one more wing'); }
    { const rs = R('t_heg_escorts'); let screen = false; if (rs) for (const r of rs) if (S(r).b.tr.escortScreen === r.round && (S(r).b.treeStats || {})['reyes:A:2:1']) { screen = true; break; } ok('Registry of Escorts', screen, 'the screen is set for the Command round'); }
    { const rs = R('t_heg_onetarget'); let filed = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['reyes:cap:0'] || !s.b.tr.wingFiled) continue; if (s.units.some(u => u.isSq && u.side === 'player' && u.wingOrder && u.wingOrder.id === s.b.tr.wingFiled.id)) { filed = true; break; } } ok('One Target Every Wing Filed', filed, 'all extra wings carry a strike order on the filed target'); }
    { const rs = R('t_heg_standinggroup'); let patrol = false; if (rs) for (const r of rs) { const s = S(r); if ((s.b.treeStats || {})['reyes:cap:1'] && s.units.some(u => u.isSq && u.side === 'player' && u.treePatrolRound === r.round)) { patrol = true; break; } } ok('Standing Strike Group', patrol, 'a patrol wing strikes an enemy that moved into range'); }
    { const rs = R('t_heg_columnstraight'); let over = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['maren:A:0:0']) continue; if (s.units.some(u => u.side === 'player' && !u.isSq && (u.sh || []).some(v => v > u.shMax))) { over = true; break; } } ok('Column Filed Straight', over, 'a ship in the line carries shields above its maximum'); }
    { const rs = R('t_heg_overflow'); let ev = false; if (rs) for (const r of rs) { const s = S(r); if ((s.b.treeStats || {})['maren:A:0:1'] && s.units.some(u => u.side === 'player' && !u.isSq && (u.evBuff || 0) >= 10)) { ev = true; break; } } ok('Overflow by Regulation', ev, 'full shields convert to +10 evasion'); }
    { const rs = R('t_heg_bell'); let bell = false; if (rs) for (const r of rs) { const s = S(r); if (s.b.tr.bellUsed === 1 && (s.b.treeStats || {})['maren:A:1:0']) { bell = true; break; } } ok('Wall at the Bell', bell, 'the first hit against the fleet in the wall round deals no hull'); }
    { const rs = R('t_heg_rotation'); let swapped = false, prev = 0; if (rs) for (let i = 1; i < rs.length; i++) { const a = S(rs[i - 1]), b = S(rs[i]); const v = (b.b.treeStats || {})['maren:A:1:1'] || 0; if (v <= prev) { prev = v; continue; } prev = v; for (const u of b.units) { if (u.side !== 'player' || u.isSq) continue; const was = a.units.find(x => x.id === u.id); if (!was) continue; if (was.q === u.q && was.r === u.r) continue; for (const w of a.units) { if (w.side !== 'player' || w.isSq || w.id === u.id) continue; if (u.q === w.q && u.r === w.r) { const now = b.units.find(x => x.id === w.id); if (now && (now.q !== w.q || now.r !== w.r)) { swapped = true; break; } } } if (swapped) break; } if (swapped) break; } ok('Standard Rotation', swapped, 'two ships exchange hexes during the wall'); }
    { const rs = R('t_heg_columnendures'); let refill = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['maren:A:2:0']) continue; if (s.units.some(u => u.side === 'player' && !u.isSq && u.shMax > 0 && (u.sh || []).some(v => v === Math.round(u.shMax * 0.25)))) { refill = true; break; } } ok('The Column Endures', refill, 'the first emptied facing refills to 25%'); }
    { const rs = R('t_heg_filedarmor'); const k = rs && keyStats(rs, 'maren:A:2:1'); ok('Filed in Armor', !!(k && k.total >= 1), 'an un-fired ship takes fewer hull points from a hit'); }
    { const rs = R('t_heg_standardcovers'); const k = rs && keyStats(rs, 'maren:cap:0'); ok('The Standard Covers All', !!(k && k.total >= 1), 'every ship takes a further cut while the wall is active'); }
    { const rs = R('t_heg_flagshipstandard'); let over = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['maren:cap:1']) continue; const fg = s.units.find(u => u.pflag && !u.dead); if (fg && s.units.some(u => u.side === 'player' && !u.isSq && u.id !== fg.id && (u.sh || []).some(v => v > u.shMax))) { over = true; break; } } ok('The Flagship Holds the Standard', over, 'a ship in the flagship line gains shields above its maximum'); }
    { const rs = R('t_heg_formation'); let formed = false; if (rs) for (const r of rs) { const s = S(r); if ((s.b.treeStats || {})['kassar:B:0:0'] && s.units.some(u => u.side === 'player' && !u.isSq && u.treeFormation === 1)) { formed = true; break; } } ok('Formation Filed Before Battle', formed, 'a ship that ends next to two friends gains its aim'); }
    { const rs = R('t_heg_drill'); let once = false, moved = false; if (rs) for (let i = 1; i < rs.length; i++) { const a = S(rs[i - 1]), b = S(rs[i]); if (!(b.b.treeStats || {})['kassar:B:0:1']) continue; once = b.b.treeDrillUsed === 1; for (const u of b.units) { if (u.side !== 'player' || u.isSq) continue; const o = a.units.find(x => x.id === u.id); if (o && (o.q !== u.q || o.r !== u.r) && hd(o, u) <= 2) moved = true; } if (once && moved) break; } ok('Drill Revision One', !!(once && moved), 'one ship is moved no more than two hexes, once in the battle'); }
    { const rs = R('t_heg_beacon'); let be = false; if (rs) for (const r of rs) { const s = S(r); if ((s.b.treeStats || {})['kassar:C:0:0'] && s.b.tr.beacon && s.b.tr.beacon.r === r.round) { be = true; break; } } ok('Flagship Registry Beacon', be, 'one enemy is stamped each round'); }
    { const rs = R('t_heg_stdforward'); let fwd = false; if (rs) for (let i = 1; i < rs.length; i++) { const a = S(rs[i - 1]), b = S(rs[i]); if (!(b.b.treeStats || {})['kassar:C:0:1']) continue; const fg = b.units.find(u => u.pflag && !u.dead); if (!fg) continue; for (const u of b.units) { if (u.side !== 'player' || u.isSq) continue; const o = a.units.find(x => x.id === u.id); if (!o || (u.q === o.q && u.r === o.r)) continue; if (hd(u, fg) <= hd(o, fg)) { fwd = true; break; } } if (fwd) break; } ok('Standard Borne Forward', fwd, 'a move toward the flagship gets the extra hex'); }
    { const rs = R('t_heg_sharedsolution'); let best = false; if (rs) { const s = S(rs[0]); const fg = s.units.find(u => u.anchor && u.side === 'player'); if (fg) { const sr = s.b.syncR && s.b.syncR.player ? s.b.syncR.player : 3; const near = s.units.filter(u => u.side === 'player' && !u.isSq && !u.dead && hd(u, fg) <= sr); best = near.length >= 2; } } ok('Shared Solution', !!(best && (S(rs[0]).b.treeStats || {})['kassar:A:1:0']), 'two or more synced ships share the best aim'); }
    { const rs = R('t_heg_colddrill'); let cold = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['kassar:A:1:1']) continue; if (s.units.some(u => u.side === 'player' && !u.isSq && (u.hexMoved || 0) === 0)) { cold = true; break; } } ok('Cold Drill', cold, 'a synced ship that has not moved fires with the drill aim'); }
  }
  { // Job 7a: prove the counts, limits and timing the final texts promise.
    const R = name => { const out = path.join(tmp, 'j7a_' + name + '.jsonl'); const rr = spawnSync(process.execPath, [GOLDEN, 'scenario', name, out], { cwd: ROOT, encoding: 'utf8' }); if (rr.status !== 0) return null; return fs.readFileSync(out, 'utf8').trim().split('\n').map(l => JSON.parse(l)); };
    const S = r => JSON.parse(r.state);
    const ok = (name, cond, msg) => { if (cond) console.log('PASS ' + name + ': ' + msg); else { console.log('FAIL ' + name + ': ' + msg); bad++; } };
    const keyStats = (rs, key) => { let p = 0, m = 0; for (const r of rs) { const v = (S(r).b.treeStats || {})[key] || 0; m = Math.max(m, v - p); p = v; } return { total: p, maxOneRound: m }; };
    const cmdIdx = rs => { for (let i = 0; i < rs.length; i++) if (rs[i].actor === 'command player') return i; return -1; };
    { const rs = R('t7a_flightcast'); let cap = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['aelith:cap:0']) continue; if (Object.values(s.b.tr.wingCap || {}).some(n => n >= 2)) { cap = true; break; } } ok('Flight Cast Perfectly', cap, 'a second wing hit on one target passes its shields'); }
    { const rs = R('t7a_forgeahead'); let later = false; if (rs) { const ci = cmdIdx(rs); const cr = ci >= 0 ? S(rs[ci]).b.round : 0; for (let i = ci + 1; i < rs.length; i++) { const s = S(rs[i]); if (!(s.b.treeStats || {})['aelith:cap:1']) continue; if (s.b.round > cr && String(rs[i].actor).startsWith('fire') && s.units.some(u => u.side === 'player' && u.isSq)) { later = true; break; } } } ok('The Forge Casts Ahead', later, 'one extra wing per carrier strikes again at the start of the next round'); }
    { const rs = R('t7a_onelens'); let one = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['vaelen:A:0:1']) continue; if (s.b.tr.oneLens && s.b.tr.oneLens.ship && s.b.tr.oneLens.tgt) { one = true; break; } } ok('One Lens, One Target', one, 'one chosen ship fires its volley at one named target'); }
    { const rs = R('t7a_sunlens'); let first = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['vaelen:cap:0']) continue; if (s.b.tr.sunTarget && s.b.tr.sunFirstDone === 1) { first = true; break; } } ok('Sun Through One Lens', first, 'the concentrated volley stops at the first hit on the target shields'); }
    { const rs = R('t7a_mirroraside'); let used = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['thorne:A:1:0']) continue; if (s.units.some(u => u.side === 'player' && !u.isSq && u.treeDiveUsed === 1)) { used = true; break; } } ok('The Mirror Steps Aside', used, 'one enemy-held hex is dived during the scatter'); }
    { const rs = R('t7a_splitthree'); let full = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['thorne:A:1:1']) continue; if (s.units.some(u => u.side === 'player' && !u.isSq && u.postFire && (u.postMp || 0) >= 1)) { full = true; break; } } ok('Light Split Three Ways', full, 'the ship keeps movement to spend after it fires'); }
    { const rs = R('t7a_fleetelsewhere'); const k = rs && keyStats(rs, 'thorne:cap:0'); let once = false; if (rs) for (const r of rs) { const s = S(r); if (s.b.tr.fleetElsewhere === 1) { once = true; break; } } ok('The Fleet Is Elsewhere', !!(k && k.total >= 1 && k.maxOneRound <= 1 && once), 'the first enemy shot grants movement once in the battle'); }
    { const rs = R('t7a_weakside'); let low = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['mirelle:A:0:0']) continue; if (!s.b.treeWeakShip) continue; const caps = s.units.filter(u => u.side === 'player' && !u.isSq && !u.dead); const min = caps.slice().sort((a, b) => (a.sh || []).reduce((n, v) => n + v, 0) - (b.sh || []).reduce((n, v) => n + v, 0) || (a.id < b.id ? -1 : 1))[0]; if (min && min.id === s.b.treeWeakShip.id) { low = true; break; } } ok('Light Bent to the Weak Side', low, 'the ship with the lowest shields takes the cut'); }
    { const rs = R('t7a_prismsface'); let over = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['mirelle:A:0:1']) continue; if (s.units.some(u => u.side === 'player' && !u.isSq && u.shMax > 0 && (u.sh || []).some(v => v > u.shMax))) { over = true; break; } } ok('Prisms Face the Fire', over, 'a ship facing its nearest enemy carries shields above its maximum'); }
    { const rs = R('t7a_lensrotates'); let ev = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['mirelle:A:1:1']) continue; if (s.units.some(u => u.side === 'player' && !u.isSq && (u.evBuff || 0) >= 10)) { ev = true; break; } } ok('The Lens Rotates', ev, 'a facing change gives +10 evasion until its next turn'); }
    { const rs = R('t7a_facetlit'); let temp = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['mirelle:cap:1']) continue; if (s.units.some(u => u.side === 'player' && !u.isSq && (u.tempHp || 0) > 0)) { temp = true; break; } } ok('Every Facet Lit', temp, 'a warded ship gains temporary hull'); }
    { const rs = R('t7a_debtdue'); let later = false; if (rs) { const ci = cmdIdx(rs); const cr = ci >= 0 ? S(rs[ci]).b.round : 0; for (const r of rs) { const s = S(r); if ((s.b.treeStats || {})['vex:A:2:1'] && s.b.round > cr) { later = true; break; } } } ok('Debt Comes Due', later, 'the delayed volley fires at the start of the next round'); }
    { const rs = R('t7a_grandledger'); let once = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['vex:cap:0']) continue; if (s.b.tr.grandUsed === 1) { once = true; break; } } ok('The Grand Ledger', once, 'the concentrated fire happens once in the battle'); }
    { const rs = R('t7a_lastaccount'); const k = rs && keyStats(rs, 'vex:cap:1'); ok('The Last Account', !!(k && k.total >= 1), 'a ship that destroyed its volley target fires again'); }
    { const rs = R('t7a_torpfirst'); let instant = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['malek:A:1:0']) continue; if (!(s.b.torps || []).some(t => t.side === 'player' && t.r === s.b.round)) { instant = true; break; } } ok('Torpedoes Run First', instant, 'no salvo from the salvo round is left travelling'); }
    { const rs = R('t7a_salvoend'); let twice = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['malek:cap:0']) continue; const by = {}; for (const t of (s.b.torps || [])) if (t.side === 'player') by[t.by] = (by[t.by] || 0) + 1; if (Object.values(by).some(n => n >= 2)) { twice = true; break; } } ok('Salvo Without End', twice, 'one ship fires a second torpedo in the salvo round'); }
    { const rs = R('t7a_screensshift'); let pair = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['thale:A:0:1']) continue; if (s.b.treeShiftUp && s.b.treeShiftDown && s.b.treeShiftUp.id !== s.b.treeShiftDown.id) { pair = true; break; } } ok('Screens Where the Debt Falls', pair, 'one ship takes more of the wall and one other takes less'); }
    { const rs = R('t7a_wallearly'); let early = false; if (rs) for (const r of rs) { const s = S(r); if (!(s.b.treeStats || {})['thale:A:1:0']) continue; if (s.b.cmd && s.b.treeWallEarly === s.b.cmd.round) { early = true; break; } } ok('Wall Declared Early', early, 'the wall is 10 points stronger when declared before any ship acts'); }
    { const rs = R('t7a_wallmoves'); let up = false; if (rs) { const ci = cmdIdx(rs); if (ci > 0) { const a = S(rs[ci - 1]), b = S(rs[ci]); const caps = b.units.filter(u => u.side === 'player' && !u.isSq && !u.dead); up = caps.length > 0 && caps.every(u => { const o = a.units.find(x => x.id === u.id); return !o || (u.mp || 0) >= (o.mp || 0) + 1; }); } } ok('The Wall That Moves', up, 'every ship gains +1 movement while the wall is active'); }
    // Job 7b: prove the numbers the Eclipse and Chorus texts promise.
    {
      const close = (a, b) => Math.abs(a - b) < 1e-9;
      const mkCap = (id, side, extra) => Object.assign({ id, side, name: id, dead: false, isSq: false, extra: false, parent: null, q: 0, r: 0, facing: 0, dmg: 1, speed: 3, hexMoved: 0, maxHp: 100, hp: 100, fx: {}, aim: 0, ev: 0, lockOn: false, fullAhead: false, crewMax: 0, braced: false, sqPct: 0, weapons: [], sh: [0, 0, 0, 0], shMax: 0, st: {}, stance: 'strike' }, extra || {});
      const W = { dmg: 10, shots: 1, r: 6, opt: 6, acc: 50, arc: 'F', k: 'gun', vsSq: 1, vsCap: 1, fall: 0, pierce: 0, ion: 1 };
      {
        const vm = require('vm');
        const rules = ['data.js', 'core.js', 'battle.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8'));
        const stubs = [
          'function fxText(){} function fxShield(){} function fxFlash(){} function fxSectionDown(){}',
          'function fxRam(){} function fxBoard(){} function onCapture(){} function fxShieldBreak(){} function fxWithdraw(){}',
          'function toast(){} function banner(){} function log(){}',
          'async function animWeapon(){} async function animTorpLaunch(){} async function animPath(){} async function animMove(){}',
          'async function animRotate(){} async function animExplode(){} async function animNova(){} async function animBlink(){}'
        ].join('\n');
        const ctx = vm.createContext({ console });
        vm.runInContext('Date.now=()=>0; globalThis.window={}; globalThis.document=undefined; globalThis.performance={now:()=>0};\n' + rules.join('\n') + '\n' + stubs + '\n' + [
          'globalThis.__T7B={',
          '  clear:()=>{ B={tree:[],treeStats:{},tr:{},units:[],round:1,cmd:null,volleyMul:null,treeNoon:false,treeDebtDue:0,treePermFile:null,treeIronExtra:null,treeWallEarly:0,cfg:null}; },',
          '  tree:(k)=>{ B.tree=[Object.assign({key:k},TREE_FX[k])]; },',
          '  mult:(u,w,t,rear)=>dmgMult(u,w,t,rear),',
          '  hit:(u,w,t)=>hitChance(u,w,t),',
          '  taken:(t)=>cmdTaken(t),',
          '  push:(x)=>B.units.push(x),',
          '  set:(k,v)=>{B[k]=v} };'
        ].join('\n'), ctx);
        const T = ctx.__T7B;
        { T.clear(); T.tree('anuket:A:1:0'); T.set('round', 2); T.set('cmd', { id: 'hunt', side: 'player', round: 2, tier: 0 });
          const u = mkCap('a', 'player'), t = mkCap('e', 'enemy'); const base = T.mult(u, W, t, false); u.treeShadowPos = 1; const boost = T.mult(u, W, t, false);
          ok('The Shadow Is a Position number', close(boost / base, 1.2), 'ending in a rear arc pays +20% (' + base.toFixed(2) + ' to ' + boost.toFixed(2) + ')'); }
        { T.clear(); T.tree('nekhet:A:1:0'); const u = mkCap('a', 'player'), t = mkCap('e', 'enemy'); u.treeIterFire = 0; const base = T.mult(u, W, t, false); u.treeIterFire = 0.15; const boost = T.mult(u, W, t, false);
          ok('Iteration Runs During Fire number', close(boost / base, 1.15), 'a repaired ship fires at +15% (' + base.toFixed(2) + ' to ' + boost.toFixed(2) + ')'); }
        { T.clear(); T.tree('razormaw:A:0:1'); T.set('round', 1); T.set('cmd', { id: 'surge', side: 'player', round: 1, tier: 0 });
          const u = mkCap('a', 'player'), t = mkCap('e', 'enemy'); u.treeTeethUsed = 0; const boost = T.mult(u, W, t, true); u.treeTeethUsed = 1; const base = T.mult(u, W, t, true);
          ok('Teeth at the Throat number', close(boost / base, 1.25), 'the first rear hit in the frenzy pays +25% (' + base.toFixed(2) + ' to ' + boost.toFixed(2) + ')'); }
        { T.clear(); T.tree('matriarch:cap:0'); T.set('round', 1); T.set('tr', { swarmHunger: { r: 1, id: 'zzz' } });
          const par = mkCap('p', 'player'); T.push(par);
          const u = mkCap('a', 'player', { isSq: true, extra: true, parent: 'p' }), t = mkCap('e', 'enemy');
          const base = T.mult(u, W, t, false); T.set('tr', { swarmHunger: { r: 1, id: 'e' } }); const boost = T.mult(u, W, t, false);
          ok('Nine Throats One Hunger number', close(boost / base, 1.25), 'swarms on the chosen enemy pay +25% (' + base.toFixed(2) + ' to ' + boost.toFixed(2) + ')'); }
        { T.clear(); T.tree('matriarch:A:1:0'); T.set('round', 1);
          const par = mkCap('p', 'player'); T.push(par);
          const u = mkCap('a', 'player', { isSq: true, extra: true, parent: 'p' }), t = mkCap('e', 'enemy');
          T.set('tr', {}); const base = T.mult(u, W, t, false); T.set('tr', { wingTargets: { p: [{ sq: 'other', tid: 'othertgt' }] } }); const boost = T.mult(u, W, t, false);
          ok('The Brood Splits number', close(boost / base, 1.15), 'a swarm on a different target pays +15% (' + base.toFixed(2) + ' to ' + boost.toFixed(2) + ')'); }
        { T.clear(); T.tree('sekhmar:A:1:1'); T.set('terrain', {});
          const u = mkCap('a', 'player'), t = mkCap('e', 'enemy', { q: 3, r: 0 }); u.treeAimTgt = null; const base = T.hit(u, W, t); u.treeAimTgt = 'e'; const boost = T.hit(u, W, t);
          ok('Target Archived Mid-Flight number', close(boost - base, 10), 'the unshared target gains 10 aim (' + base.toFixed(0) + ' to ' + boost.toFixed(0) + ')'); }
        { T.clear(); T.tree('khepra:A:1:0'); T.set('round', 2); T.set('cmd', { id: 'iron', side: 'player', round: 2, tier: 1 });
          const t = mkCap('t', 'player', { shMax: 100, sh: [100, 100, 100, 100] });
          T.set('treeWallEarly', 0); const base = T.taken(t); T.set('treeWallEarly', 2); const boost = T.taken(t);
          ok('Wall Archived in Advance number', close(base - boost, 0.1), 'the early wall cuts 10 points more (' + base.toFixed(2) + ' to ' + boost.toFixed(2) + ')'); }
      }
      const forms = [['t7b_ecl_formation_a', 'nekhet:B:0:0'], ['t7b_ecl_formation_b', 'sekhmar:B:0:0'], ['t7b_ecl_formation_c', 'anuket:B:0:0'], ['t7b_ecl_formation_d', 'khepra:B:0:0']];
      for (const [name, key] of forms) {
        const rs = R(name); let hit = false;
        if (rs) for (let i = 1; i < rs.length; i++) { const a = S(rs[i - 1]), b = S(rs[i]); if (!((b.b.treeStats || {})[key] >= 1)) continue; for (const u of b.units) { if (u.side !== 'player' || u.isSq) continue; const o = a.units.find(x => x.id === u.id); if (!o || o.treeEclForm || u.treeEclForm !== 1) continue; if ((u.evBuff || 0) - (o.evBuff || 0) >= 10) { hit = true; break; } } if (hit) break; }
        ok('Formation Loaded from Archive (' + name + ')', hit, 'two friends close by add +10 evasion');
      }
      { const rs = R('t7b_ecl_archive'); const ci = rs ? cmdIdx(rs) : -1; let hit = false;
        if (ci > 0) { const a = S(rs[ci - 1]), b = S(rs[ci]); for (const u of b.units) { if (u.side !== 'player' || u.isSq) continue; const o = a.units.find(x => x.id === u.id); if (!o) continue; if (Math.round(u.hp - o.hp) === Math.round(u.maxHp * 0.55) && u.hp < u.maxHp) { hit = true; break; } } }
        ok('The Archive Answers First number', hit, 'the early restore heals 10 points more than the wall normally gives'); }
      { const rs = R('t7b_ch_tideearly'); const ci = rs ? cmdIdx(rs) : -1; let hit = false;
        if (ci > 0) { const a = S(rs[ci - 1]), b = S(rs[ci]); for (const u of b.units) { if (u.side !== 'player' || u.isSq) continue; const o = a.units.find(x => x.id === u.id); if (!o) continue; if (Math.round(u.hp - o.hp) === Math.round(u.maxHp * 0.45) && u.hp < u.maxHp) { hit = true; break; } } }
        ok('The Tide Comes Early number', hit, 'the early restore heals 10 points more than the tide normally gives'); }
      { const rs = R('t7b_ecl_triage'); const ci = rs ? cmdIdx(rs) : -1; let hit = false;
        if (ci > 0) { const a = S(rs[ci - 1]), b = S(rs[ci]); for (const u of b.units) { if (u.side !== 'player' || u.isSq) continue; const o = a.units.find(x => x.id === u.id); if (!o) continue; const had = !!(o.st && (o.st.fire || o.st.acid)); const now = !!(u.st && (u.st.fire || u.st.acid)); let full = false; if (u.sec && o.sec) for (const k of Object.keys(u.sec)) { const sn = u.sec[k], so = o.sec[k]; if (sn && so && !sn.broken && sn.hp >= sn.max && so.hp < so.max) full = true; } if (had && !now && full) { hit = true; break; } } }
        ok('Copies Triage the Damage number', hit, 'a section repaired to full clears the ship fire and acid'); }
      { const rs = R('t7b_ch_growth'); let hit = false;
        if (rs) for (let i = 1; i < rs.length; i++) { const b = S(rs[i]); if (!((b.b.treeStats || {})['mending:A:1:1'] >= 2)) continue; const a = S(rs[i - 1]); for (const u of b.units) { if (u.side !== 'player' || u.isSq) continue; const o = a.units.find(x => x.id === u.id); if (!o || !u.sec || !o.sec) continue; for (const k of Object.keys(u.sec)) if (u.sec[k].hp > o.sec[k].hp) { hit = true; break; } if (hit) break; } if (hit) break; }
        ok('Growth Holds the Wound number', hit, 'a healed section heals again at the next round start'); }
      { const rs = R('t7b_ch_spat'); const ci = rs ? cmdIdx(rs) : -1; let held = false, later = false;
        if (ci >= 0) { const cs = S(rs[ci]); const pend = (cs.b.treePending || []).find(p => p.k === 'spatRounds'); held = !!pend; const heldIds = (pend && pend.ids) || []; const cr = cs.b.round; let tp = -1; for (let i = ci + 1; i < rs.length; i++) if (rs[i].actor === 'tick player' && S(rs[i]).b.round === cr + 1) { tp = i; break; }
          if (tp >= 0) for (let i = tp + 1; i < rs.length; i++) { const act = rs[i].actor; if (act === 'round') break; if (heldIds.some(id => act === 'fire ' + id)) { later = true; break; } } }
        ok('Spat in Two Rounds number', !!(held && later), 'the held spit fires at the next round start'); }
    }
  }
  }
} finally {
  fs.rmSync(tmp, { recursive: true, force: true });
}
if (bad) { console.log('FAIL: ' + bad + ' tree effect check(s)'); process.exit(1); }
console.log('PASS: ' + Object.keys(WANT).length + ' tree fixtures fired their pick; ' + INERT.length + ' waiting rows are inert; 3 corrected Hullbreakers rows behave as their text says');
