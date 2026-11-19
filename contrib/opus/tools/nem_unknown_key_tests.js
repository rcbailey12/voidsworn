// Issue 1182, browser side: a save from an older build can name a Nemesis trait or weakness the tables no longer have.
// Every nemEntry caller shows the raw key or skips it, never reads .n or .d of undefined. Twin of
// godot/campaign/test/nem_unknown_key_test.gd (same fixture, same lines).
//   node contrib/opus/tools/nem_unknown_key_tests.js
'use strict';
const path = require('path');
const root = path.resolve(__dirname, '../../..');
process.env.VS_ORACLE = root;
require(path.join(root, 'godot/campaign/test/node/env.js')).load(String.raw`
toast=function(){}; show=function(){}; modal=function(){};
var LOGGED=[]; log=function(m){ LOGGED.push(String(m)); };
const FAC='corsair';
function oldSave(seed){
  UID=1; rndSeed(seed); META=defaultMeta(); META.backfilled=1; META.wonFix41=1; SAVED_RUN=null; RUN=null; B=null; pickedAdmiral='vex'; pickedFaction='voidsworn'; runOpt.alt=false; runOpt.cmdAlt=false; runOpt.heat=[];
  titleScreen(); ACT.newRunScreen(); ACT.startRun(); ACT.pickAspect(window._aspOffer[0]); ACT.closeModal(); RUN.nemAssign=[FAC,FAC,FAC]; RUN.nems={}; RUN.nem=null; nemActive();
  const N=RUN.nem; N.traits.push('old_trait'); for(const w of N.weak) if(!N.revealed.includes(w)) N.revealed.push(w);
  N.weak.push('old_weak'); N.revealed.push('old_weak'); N.weak.push('old_hidden'); N.weak.push('old_late'); N.met=1; N.beaten=1;
  RUN=JSON.parse(JSON.stringify(RUN)); nemActive();   // as a save would come back: plain data
}
globalThis.NK={ oldSave, nemPanel, nemAfterBattle, applyOutcome, nemTrip:(...a)=>nemTrip(...a), factionTraitLines, nemLessonHtml, nemFoundMerge,
  get NEM_TRAITS(){ return NEM_TRAITS; }, get NEM_WEAK(){ return NEM_WEAK; }, get RUN(){ return RUN; }, setB(b){ B=b; }, get LOGGED(){ return LOGGED; } };
`);
const T = globalThis.NK;
let fails = 0;
function check(ok, what) { console.log((ok ? 'PASS ' : 'FAIL ') + what); if (!ok) fails++; }
function tryit(what, fn) { try { return fn(); } catch (e) { check(false, what + ' (' + e.message + ')'); if (process.env.NK_DEBUG) console.log(e.stack); return null; } }

check(!T.NEM_TRAITS.old_trait && !T.NEM_WEAK.old_weak, 'the keys really are missing from the tables');
T.oldSave(1182);
const panel = tryit('campaign panel', () => T.nemPanel());
if (panel != null) check(panel.includes('old_weak') && !panel.includes('old_trait'), 'campaign panel: shows the unknown weakness by its key and skips the unknown trait');

T.setB({ nem: { fac: 'corsair', weak: ['old_weak'], revealed: [] }, units: [], round: 1 });
tryit('battle log', () => T.nemTrip('old_weak'));
check(T.LOGGED.includes('Weakness found: old_weak.'), 'battle log: an unknown weakness found in battle logs its key');
const flag = { nem: true, nemFlag: true, side: 'enemy', t: {}, weapons: [] };
T.setB({ nem: { fac: 'corsair', weak: ['old_weak'], revealed: ['old_weak'] }, units: [flag], round: 1, cfg: {} });
const lines = tryit('battle ship info', () => T.factionTraitLines(flag));
if (lines != null) check(lines.join(' ').includes('Known weaknesses: old_weak ()'), 'battle ship info: the known unknown weakness shows its key');

T.oldSave(1182);
const win = tryit('after battle win', () => T.nemAfterBattle('win', false, {}));
if (win) check(win.join(' ').includes('reveal a weakness: old_hidden.'), 'after battle: a win reveals the unknown hidden weakness by its key');
T.oldSave(1183);
const loss = tryit('after battle loss', () => T.nemAfterBattle('loss', false, { found: ['old_weak'] }));
if (loss) check(loss.join(' ').includes('Weakness found: old_weak.'), 'after battle: a loss that teaches names the unknown weakness by its key');
T.oldSave(1184);
const conf = tryit('after battle confirm', () => T.nemAfterBattle('win', true, { found: ['old_late'] }));
if (conf) check(conf.join(' ').includes('Weakness confirmed: old_late.'), 'after battle: a confirmed unknown weakness shows its key');
T.oldSave(1186);
const intel = tryit('intel reward', () => T.applyOutcome({ nemIntel: 1 }));
if (intel) check(intel.join(' ').includes('Nemesis weakness revealed: old_hidden.'), 'intel: the intel reward names the unknown weakness by its key');
T.oldSave(1187);
const html = tryit('end of run lessons', () => T.nemLessonHtml({ met: 1, lessons: [{ w: 'old_weak', fac: 'corsair', name: 'x' }] }, T.RUN));
if (html != null) check(html.includes('taught you a weakness: the hunter') && !html.includes('old_weak'), 'end of run: a lesson on an unknown weakness falls back to its generic words');

console.log((fails ? 'FAIL' : 'PASS') + ' nem_unknown_key_tests: ' + fails + ' failure(s)');
process.exit(fails ? 1 : 0);
