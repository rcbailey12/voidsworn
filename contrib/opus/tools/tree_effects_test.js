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
  t_hb_preyscent: 'grax:B:0:0', t_hb_loosepack: 'grax:B:0:1', t_hb_firstscar: 'grax:C:0:0', t_hb_trophystandard: 'grax:C:0:1'
};
const INERT = ['aelith:A:0:0', 'aelith:A:1:0', 'aelith:A:1:1', 'aelith:cap:1', 'aelith:cap:0',
  'vaelen:A:0:1', 'vaelen:A:1:0', 'vaelen:cap:0', 'thorne:A:1:0', 'thorne:A:1:1', 'thorne:cap:0',
  'mirelle:A:0:0', 'mirelle:A:0:1', 'mirelle:A:1:1', 'mirelle:cap:1',
  // Sunward x and c rows wait for the Muse text pass (#311)
  'vex:A:0:0', 'vex:A:2:1', 'vex:cap:0', 'vex:cap:1',
  'malek:A:1:0', 'malek:A:1:1', 'malek:cap:0',
  'ashgrove:A:1:0',
  'thale:A:0:1', 'thale:A:1:0', 'thale:cap:1',
  // Eclipse x and c rows wait for the Muse text pass (#311)
  'nekhet:A:0:1', 'nekhet:A:1:0', 'nekhet:A:1:1', 'nekhet:B:0:0',
  'sekhmar:A:1:1', 'sekhmar:B:0:0',
  'anuket:A:1:0', 'anuket:B:0:0',
  'khepra:A:1:0', 'khepra:B:0:0',
  // Chorus x and c rows wait for the Muse text pass (#311)
  'matriarch:A:1:0', 'matriarch:A:1:1', 'matriarch:cap:0', 'matriarch:cap:1',
  'razormaw:A:0:1', 'razormaw:A:1:1',
  'mending:A:1:0', 'mending:A:1:1',
  'voice:A:1:1',
  'matriarch:B:0:0', 'razormaw:B:0:0', 'mending:B:0:0', 'voice:B:0:0'];
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
  // the Glasswrights x and c rows wait for the Muse text pass (#311): they must stay inert
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
  }
} finally {
  fs.rmSync(tmp, { recursive: true, force: true });
}
if (bad) { console.log('FAIL: ' + bad + ' tree effect check(s)'); process.exit(1); }
console.log('PASS: ' + Object.keys(WANT).length + ' tree fixtures fired their pick; ' + INERT.length + ' waiting rows are inert; 3 corrected Hullbreakers rows behave as their text says');
