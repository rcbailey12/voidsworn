// B1 checks: each fixed bug gets a scripted proof. Run from the repo root: node contrib/opus/tools/b1_tests.js
// Loads data.js, core.js, battle.js, campaign_meta.js and campaign_run.js with a fake page and a fake localStorage.
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const IDS = {}; let LAST_MODAL = '';
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { if (c.id) IDS[c.id] = c; if (c.id === 'modal') LAST_MODAL = c.innerHTML; this.children.push(c); return c; }, remove() { if (this.id && IDS[this.id] === this) delete IDS[this.id]; },
  querySelector() { return null; }, querySelectorAll() { return []; }, addEventListener() {}, setAttribute() {}, focus() {} });
global.document = { createElement: el, getElementById: id => IDS[id] || (id === 'modal' ? null : el()), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; const realTimeout = setTimeout; global.setTimeout = () => 0;
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
let pass = 0, fail = 0;
function check(name, fn) { try { const r = fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
eval(src + `
function log(){} function fxText(){} function fxShield(){} function fxFlash(){} function tel(){} function nodeSeeds(){ return 0; }
var STALL=false; async function animNova(){ if(STALL) B.epoch=(B.epoch||0)+1; } async function animBlink(){ if(STALL) B.epoch=(B.epoch||0)+1; } async function fxBoard(){}
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get META(){ return META; }, get SAVED_RUN(){ return SAVED_RUN; }, set SAVED_RUN(v){ SAVED_RUN=v; }, Persist, migrateRun, migrateMeta, defaultMeta, fleetCP, derive, newShip, ensureFlagship,
  RELICS, ADMIRALS, HULLS, BOONS, MODULES, PATRONS, STORE_KEY, ACT, rewardFlow, resumeReward, genSector, findNode, saveRun, get modalHtml(){ return LAST_MODAL; }, set STALL(v){ STALL=v; }, get B(){ return B; }, startBattle, useAbility, boardUnit, hdist, MOVE_BASE, MOVE_RULES, novaTargets, blinkHexes, systemDamage, captureChance, prizeScrap, salvageYield, PATRONS2: null, get modalOpen(){ return !!IDS.modal; } };
`);
const base = () => ({ fac: 'voidsworn', admiral: 'vex', credits: 50, cpCap: 10, sector: 1, relics: [], inventory: [], boons: [], map: { cols: [] },
  fleet: [{ uid: 1, tpl: 'warden', name: 'Warden', hp: 50, mods: [], mk: 1, cap: { fac: 'voidsworn', name: 'Ada Vey', xp: 0, rank: 0, perks: [], pending: 0 } }] });

// ---- B-1 save-brick class (FINDINGS B-1; evidence rows 1a to 1f) ----
check('B-1a renamed hull: fleetCP and derive no longer throw, ship dropped and counted', () => {
  const r = base(); r.fleet.push({ uid: 2, tpl: 'warden_renamed', name: 'Ghost', hp: 10, mods: [], cap: { name: 'X' } });
  T.RUN = T.migrateRun(r); T.fleetCP(); T.RUN.fleet.forEach(s => T.derive(s));
  return T.RUN.fleet.length === 1 && T.RUN._shipsDropped === 1 && T.RUN._repairs.some(x => /warden_renamed/.test(x));
});
check('B-1c unknown relic id is removed (map screen reads RELICS[r].d)', () => {
  const r = base(); r.relics = [Object.keys(T.RELICS)[0], 'relic_gone']; T.RUN = T.migrateRun(r);
  return T.RUN.relics.length === 1 && T.RUN.relics.every(id => T.RELICS[id].d !== undefined);
});
check('B-1d captain with no name: newShip-style name use works', () => {
  const r = base(); r.fleet[0].cap = {}; T.RUN = T.migrateRun(r); const c = T.RUN.fleet[0].cap;
  return typeof c.name === 'string' && c.name.split(' ')[0].length > 0 && Array.isArray(c.perks);
});
check('B-1e stale admiral id is reset (run summary reads ADMIRALS[RUN.admiral].n)', () => {
  const r = base(); r.admiral = 'adm_renamed'; T.RUN = T.migrateRun(r); return typeof T.ADMIRALS[T.RUN.admiral].n === 'string';
});
check('B-1f meta with stats:null gets real stats (title reads META.stats.best)', () => {
  const m = T.migrateMeta(Object.assign(T.defaultMeta(), { stats: null, opts: null })); return typeof m.stats.best === 'number' && typeof m.opts === 'object';
});
check('B-1f old v1 meta still runs its v2 migration (version is not pre-filled)', () => {
  const m = T.migrateMeta({ renown: 3 }); return m.v === 2 && Array.isArray(m.tel);
});
check('B-1 full load path: a save with every bad id loads, and a raw copy is kept', () => {
  const r = base(); r.admiral = 'nobody'; r.relics = ['gone']; r.fleet.push({ uid: 3, tpl: 'old_hull', cap: null }); r.fleet[0].cap = { name: 7, perks: ['gone'] };
  r.boons = [{ id: 'gone_boon', r: 0 }, null]; r.aspect = 'gone'; r.flagUid = 3;
  localStorage.setItem(T.STORE_KEY, JSON.stringify({ meta: T.defaultMeta(), run: r })); delete STORE[T.STORE_KEY + '.repaired'];
  T.Persist.loadLocal(); const s = T.SAVED_RUN;
  return !!s && s.fleet.length === 1 && s.flagUid === null && s.aspect === null && s.boons.length === 0 && s.fleet[0].cap.name === 'Captain' && s.fleet[0].cap.perks.length === 0 && !!STORE[T.STORE_KEY + '.repaired'];
});
check('B-1 a clean save is left alone (no repairs listed)', () => {
  const r = T.migrateRun(base()); return !r._repairs && r.fleet.length === 1;
});

// helpers: pull one function or one ACT line out of a UI file so it can run against stubs
function grab(file, start, endRe) { const t = fs.readFileSync(path.join(ROOT, file), 'utf8'); const i = t.indexOf(start); if (i < 0) throw new Error('not found: ' + start); const rest = t.slice(i); const m = endRe.exec(rest); return m ? rest.slice(0, m.index + m[0].length) : rest; }

// ---- B-2 retreat dialog ----
check('B-2 "Jump out" after the battle ended does not turn a win into a retreat', () => {
  const code = grab('campaign3d.js', 'ACT.c3retreatYes=', /\n/); let called = null;
  const f = new Function('ACT', 'B', 'closeModal', 'finishBattle', code + '; return ACT.c3retreatYes;');
  const ACT = {}; let B = { campaign: true, over: 'win' }; f(ACT, B, () => {}, r => { called = r; })();
  if (called !== null) return false;
  B = { campaign: true, over: null }; const ACT2 = {}; f(ACT2, B, () => {}, r => { called = r; })(); return called === 'retreat';
});
check('B-2 battle keys do nothing while a dialog is open; Escape answers the retreat question with Stay', () => {
  const code = grab('ui3d.js', 'function onKey(e){', /\n}\n/); let fired = [];
  const doc = open => ({ querySelector: () => null, body: { classList: { contains: () => false } }, getElementById: id => (open && (id === 'modal' || id === 'retreatAsk') ? {} : null) });
  const ACT = { threat: () => fired.push('threat'), c3retreatNo: () => fired.push('stay') };
  const run = (key, open) => new Function('e', 'B', 'document', 'ACT', 'closeModal', 'bRefresh', code + '; return onKey(e);')({ key, target: { tagName: 'DIV' }, preventDefault() {} }, {}, doc(open), ACT, () => fired.push('close'), () => {});
  run('r', true); run('Escape', true); const blocked = fired.join(',') === 'stay'; fired = []; run('r', false); return blocked && fired[0] === 'threat';
});

// ---- B-3 reload bug 1: nothing in the battle code saves the run, so a mid-battle reload restores the pre-node save and replays the seeded node ----
check('B-3 no run save or full save from battle-time code (battle.js, ui3d.js, campaign3d.js battle flow)', () => {
  const bad = [];
  for (const f of ['battle.js', 'ui3d.js']) { const t = fs.readFileSync(path.join(ROOT, f), 'utf8'); if (/saveRun\s*\(/.test(t)) bad.push(f + ' saveRun'); }
  const ui = fs.readFileSync(path.join(ROOT, 'ui3d.js'), 'utf8'); for (const m of ui.matchAll(/Persist\.save\(([^)]*)\)/g)) if (!/meta:true/.test(m[1])) bad.push('ui3d.js full Persist.save');
  if (bad.length) throw new Error(bad.join(', ')); return true;
});

// ---- B-4 reload during the reward screens ----
function rewardSetup() {
  T.RUN = T.migrateRun({ fac: 'voidsworn', admiral: 'vex', credits: 100, cpCap: 10, sector: 1, relics: [], inventory: [], boons: [], map: { cols: [] },
    fleet: [{ uid: 1, tpl: 'warden', name: 'Warden', hp: 50, mods: [], mk: 1, cap: { fac: 'voidsworn', name: 'Ada Vey', xp: 0, rank: 0, perks: [], pending: 0 } }] });
  const R = T.RUN; R.map = T.genSector(1); const node = R.map.cols[1][0]; node.type = 'elite'; node.rw = { k: 'boon', p: Object.keys(T.PATRONS)[0] }; R.patrons = [node.rw.p];
  R.curNode = node.id; R.pos = node.id; T.saveRun();
  return { node, summary: { cfg: { kind: 'elite', node: node.id, col: node.col }, xp: [], lost: [], kills: 3, rounds: 4, boonStats: {},
    wrecks: [{ tpl: 'h_picket', name: 'Wreck', cls: 'Picket', fac: 'hegemony', cp: 1, cause: 'gun', wk: ['battery'] }] } };
}
function reload() { for (const k of ['_rw', '_rewardCfg', '_relicChoice', '_wrecks', '_boonOffer', '_modOffer']) delete window[k]; T.RUN = T.migrateRun(JSON.parse(JSON.stringify(T.SAVED_RUN))); T.resumeReward(); }
check('B-4 rewards survive a reload at every step: node done once, same offers, no double pay', () => {
  const { node, summary } = rewardSetup(); T.rewardFlow(summary);
  const s0 = T.SAVED_RUN; if (!s0.reward || s0.reward.stage !== 'salvage' || !T.findNode.call(null, node.id)) throw new Error('reward not saved at start');
  const banked = s0.credits; if (!(banked > 100)) throw new Error('credits not banked');
  reload(); if (!/Strip the wrecks/.test(T.modalHtml)) throw new Error('salvage not resumed'); // lore r8: the wreck step is Strip
  T.ACT.takeSalvage('0:cred'); const afterSalvage = T.SAVED_RUN.credits; if (T.SAVED_RUN.reward.stage !== 'pick') throw new Error('stage after salvage ' + T.SAVED_RUN.reward.stage);
  const offer = JSON.stringify(T.SAVED_RUN.reward.boonOffer); if (!offer || offer === 'null') throw new Error('boon offer not saved');
  reload(); if (JSON.stringify(T.SAVED_RUN.reward.boonOffer) !== offer) throw new Error('boon offer changed on reload');
  T.ACT.takeBoon('0'); if (T.SAVED_RUN.boons.length !== 1 || T.SAVED_RUN.reward.stage !== 'relic') throw new Error('boon not saved');
  const relics = JSON.stringify(T.SAVED_RUN.reward.relics); reload(); if (JSON.stringify(T.SAVED_RUN.reward.relics) !== relics) throw new Error('relic choice changed');
  const pickR = T.SAVED_RUN.reward.relics[0]; T.ACT.takeRelic(pickR);
  const f = T.SAVED_RUN, n = f.map.cols.flat().find(x => x.id === node.id);
  return f.reward === null && f.boons.length === 1 && f.relics.length === 1 && f.relics[0] === pickR && f.credits === afterSalvage && n.done === true && f.curNode === null;
});
check('B-4 a reload right after the battle does not replay the node (it is already done)', () => {
  const { node, summary } = rewardSetup(); T.rewardFlow(summary); const n = T.SAVED_RUN.map.cols.flat().find(x => x.id === node.id); return n.done === true;
});

// ---- B-5 captured flagship ----
check('B-5 a sector flagship can never be captured (capture chance 0)', () => T.captureChance({ crew: 400, fac: 'corsair', fx: {} }, { boss: true, crew: 0 }) === 0);
check('B-5 every hull has a finite sell and scrap value (no NaN credits)', () => Object.keys(T.HULLS).every(k => Number.isFinite(T.prizeScrap(k))));
check('B-5 a save with NaN credits is repaired to 0', () => { const r = base(); r.credits = NaN; return T.migrateRun(r).credits === 0; });
check('B-5 prize code skips boss hulls and scraps prizes past the command cap', () => {
  const t = fs.readFileSync(path.join(ROOT, 'campaign3d.js'), 'utf8'); return /if\(!H\|\|H\.boss\|\|u\.boss\) continue;/.test(t) && /fleetCP\(\)\+\(H\.cp\|\|1\)>RUN\.cpCap/.test(t);
});
// ---- B-8 towing ----
check('B-8 towing is only offered within the command cap', () => {
  T.RUN = T.migrateRun(Object.assign(base(), { fac: 'corsair' })); const w = { tpl: 'c_raider', cp: 1, cause: 'gun', wk: [] };
  T.RUN.cpCap = 999; const ok = T.salvageYield(w).tow === true; T.RUN.cpCap = T.fleetCP(); return ok && T.salvageYield(w).tow === false;
});
// ---- B-10 reserve captain ----
check('B-10 a hired veteran keeps his ship; a plain new ship gets the reserve captain', () => {
  const code = grab('campaign3d.js', 'const _newShip=newShip;', /\n/); const R = { reserve: [{ cap: { name: 'Old Hand', perks: [], xp: 0, rank: 1 } }] };
  const wrapped = new Function('newShip', 'B', 'RUN', 'derive', 'setTimeout', 'toast', code.replace('const _newShip=newShip; newShip=function', 'const _newShip=newShip; return function'))(
    (t, vet) => ({ tpl: t, hp: 100, cap: { name: vet ? 'Hired Vet' : 'Green' } }), null, R, () => ({ maxHp: 100 }), () => {}, () => {});
  const a = wrapped('warden', true); const b = wrapped('warden', false); return a.cap.name === 'Hired Vet' && R.reserve.length === 0 && b.cap.name === 'Old Hand';
});
// ---- B-9 zero-fleet win ----
check('B-9 a win that cost every ship continues the run with a garrison ship', () => {
  const code = grab('campaign3d.js', "  if(result==='win'&&RUN.fleet.length===0){", /\n/); const R = { fleet: [], fac: 'voidsworn' };
  new Function('result', 'RUN', 'newShip', 'cheapHull', 'ensureFlagship', 'setTimeout', 'toast', 'tel', code)('win', R, t => ({ tpl: t, name: 'Garrison' }), () => 'warden', () => {}, () => {}, () => {}, () => {});
  return R.fleet.length === 1;
});
// ---- B-11, F25, F6: small text and guard changes ----
check('B-11 the direct-fire path respects the alternating guard', () => /if\(set\.length\)\{ if\(!guard\(s\)\) return;/.test(fs.readFileSync(path.join(ROOT, 'ui3d.js'), 'utf8')));
check('F25 fresh profiles start on Standard AI; returning players keep Veteran', () => /let AI_LEVEL='standard';/.test(fs.readFileSync(path.join(ROOT, 'campaign3d.js'), 'utf8')) && /else if\(\(META\.stats&&META\.stats\.runs\)>0\) AI_LEVEL='veteran'/.test(fs.readFileSync(path.join(ROOT, 'main3d.js'), 'utf8')));
check('F6 tutorial no longer says "Cyan is shields" as a world rule', () => !/'Cyan is shields/.test(fs.readFileSync(path.join(ROOT, 'ui3d.js'), 'utf8')));
// ---- F17 crits ----
check('F17 a crit never revives a weapon or shield generator a destroyed section took out', () => {
  T.RUN = T.migrateRun(base()); T.startBattle({ kind: 'battle', fac: 'hegemony', col: 3, enemies: [{ tpl: 'h_vanguard' }] });
  const t = T.B.units.find(u => u.side === 'enemy' && !u.isSq); t.weapons.forEach(w => { w.off = 999; }); t.st.shieldOff = 999;
  for (let i = 0; i < 200; i++) T.systemDamage(t, ['weapons', 'shields', 'prow', 'mid', null][i % 5]);
  return t.weapons.every(w => w.off === 999) && t.st.shieldOff === 999;
});
// ---- B-6, B-7 abilities after a stalled animation (async) ----
// ---- Onboarding 2 to 4 ----
const UI = () => fs.readFileSync(path.join(ROOT, 'ui3d.js'), 'utf8');
const tipText = id => { const m = new RegExp("\\['" + id + "','([^']*)','((?:[^'\\\\]|\\\\.)*)'\\]").exec(UI()); return m ? m[2] : null; };
check('Onboarding 2: the move tip states the real motion rule (numbers from MOVE_BASE)', () => {
  const t = tipText('select'), R = T.MOVE_BASE; if (!t) throw new Error('no select tip');
  return t.includes('+' + R.still) && t.includes(R.evadeAt + ' or more hexes') && t.includes('\\u2212' + R.evade) && /turning in place does not count/.test(t) && /Bracing cancels/.test(t);
});
check('Onboarding 3: a "Turns alternate" tip shows at battle start, once per profile', () => {
  const u = UI(); return !!tipText('turns') && /\['start',[^\n]*\n  \['turns',/.test(u) && /const cond=\{start:true, turns:true,/.test(u);
});
check('Onboarding 5: a Threat tip points at the real Threat toggle (R and the top-bar button)', () => {
  const t = tipText('threat'), u = UI(); return !!t && /Press R/.test(t) && /if\(k==='r'\)\{ ACT\.threat\(\); return; \}/.test(u) && /id="b_threat2"/.test(u) && /threat:\(B\.round\|\|1\)>=2/.test(u);
});
check('Onboarding 4: every reward screen carries its one-line definition', () => {
  const { summary } = rewardSetup(); T.rewardFlow(summary); T.ACT.salvageStep(); const sal = T.modalHtml; T.ACT.takeSalvage('0:cred'); const boon = T.modalHtml; T.ACT.takeBoon('0'); const relic = T.modalHtml;
  const cr = fs.readFileSync(path.join(ROOT, 'campaign_run.js'), 'utf8');
  return /class="dim rdef"[^>]*>Strip:/.test(sal) && /A protocol is/.test(boon) && /Salvage is/.test(relic) && /<h2>Recovered refits<\/h2>\$\{rewardDef\('refit'\)\}/.test(cr) && /Choose one perk\.<\/p>\$\{rewardDef\('promotion'\)\}/.test(cr);
});
// ---- Enemy markers: colour clear of every faction shield and the gold ring, plus a shape cue ----
check('Markers: the enemy colour is far from all six shield colours, the gold ring and friend green, in normal and colour-blind vision', () => {
  const fx = fs.readFileSync(path.join(ROOT, 'fx3d.js'), 'utf8'), sh = fs.readFileSync(path.join(ROOT, 'ships3d.js'), 'utf8'), ui = UI();
  const c3 = str => str.split(',').map(Number); const foe = c3(/FOE_C=new C3\(([^)]*)\)/.exec(fx)[1]), friend = c3(/FRIEND_C=new C3\(([^)]*)\)/.exec(fx)[1]);
  const shields = [...sh.matchAll(/shield:new C3\(([^)]*)\)/g)].map(m => c3(m[1])); if (shields.length !== 6) throw new Error('found ' + shields.length + ' shield colours');
  const gold = c3(/OV\.selRing=ringMesh\(new C3\(([^)]*)\)/.exec(ui)[1]);
  const M = [[[1, 0, 0], [0, 1, 0], [0, 0, 1]], [[0.367, 0.861, -0.228], [0.280, 0.673, 0.047], [-0.012, 0.043, 0.969]], [[0.152, 1.053, -0.205], [0.115, 0.786, 0.099], [-0.004, -0.048, 1.052]], [[1.256, -0.077, -0.179], [-0.078, 0.931, 0.148], [0.005, 0.691, 0.304]]];
  const sim = (c, m) => m.map(r => Math.max(0, Math.min(1, r[0] * c[0] + r[1] * c[1] + r[2] * c[2]))); const dist = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]);
  const worst = Math.min(...[...shields, gold, friend].map(k => Math.min(...M.map(m => dist(sim(foe, m), sim(k, m))))));
  if (worst < 0.35) throw new Error('closest colour distance ' + worst.toFixed(2)); return true;
});
check('Markers: enemy board marks are a broken hex (shape cue), friends keep the solid one', () => {
  const u = UI(); return /function fpHexMeshBroken\(/.test(u) && /FP\.foe=mk\(fpHexMeshBroken\(/.test(u) && /\[\[FP\.fill,FF\],\[FP\.fill2,F\],\[FP\.foe,FE\]\]/.test(u) && /\[\[FF,!foe\],\[FE,foe\]\]/.test(u);
});
check('Markers: no enemy ring still uses the old red', () => { const u = UI(); return !/(insRing|aiRing)=ringMesh\(new C3\(1,\.3,\.25\)/.test(u) && !/rm=ringMesh\(new C3\(1,\.3,\.25\),\.8,R,\.3\); rm\.metadata=\{u:t\}/.test(u); });
check('Onboarding 5: the acting enemy gets a pulsing ring and an "Enemy acting" chip that clears with the battle', () => {
  const u = UI(); return /function aiChip\(\)/.test(u) && /'Enemy acting: '/.test(u) && /OV\.aiRing\.isEnabled\(\)\)\{ const k=1\+/.test(u) && /function clearOverlays\(\)\{ G\.aiChipTxt='';/.test(u);
});

// ---- B2 capture rework (R4): add, strip or ransom ----
check('R23 batched prizes: one screen lists every prize with add, strip and ransom side by side, and sensible defaults', () => {
  const { summary } = rewardSetup(); summary.wrecks = []; summary.prizes = [{ tpl: 'h_picket', name: 'Prize One', hpf: .5, fac: 'hegemony', wk: ['battery'], cp: 1 }, { tpl: 'h_picket', name: 'Prize Two', hpf: 1, fac: 'hegemony', wk: ['battery'], cp: 1 }];
  T.RUN.cpCap = T.fleetCP() + 1; T.rewardFlow(summary); if (T.SAVED_RUN.reward.stage !== 'prize') throw new Error('stage ' + T.SAVED_RUN.reward.stage);
  T.ACT.prizeStep(); const h = T.modalHtml;
  if (!/Prize One/.test(h) || !/Prize Two/.test(h) || (h.match(/data-act="prizeSet"/g) || []).length !== 6 || (h.match(/data-act="prizeConfirm"/g) || []).length !== 1) throw new Error('not one screen with 3 choices per prize');
  /* default: the first fits and is added; the second has no room left, so its Add is disabled and it falls to strip or ransom */
  if (!/class="sel" data-act="prizeSet" data-arg="0:add"/.test(h)) throw new Error('first prize should default to add');
  if (!/data-arg="1:add" disabled/.test(h) || /class="sel" data-act="prizeSet" data-arg="1:add"/.test(h)) throw new Error('second prize add should be disabled');
  const c0 = T.RUN.credits, f0 = T.RUN.fleet.length; T.ACT.prizeConfirm();
  return T.RUN.fleet.length === f0 + 1 && T.RUN.credits > c0 && T.SAVED_RUN.reward.prizes.length === 0 && T.SAVED_RUN.reward.stage !== 'prize';
});
check('R23 batched prizes: picks survive a reload, an Add past the command cap cannot go through, one confirm applies all', () => {
  const { summary } = rewardSetup(); summary.wrecks = []; summary.prizes = [{ tpl: 'h_picket', name: 'Keep A', hpf: 1, fac: 'hegemony', wk: ['battery'], cp: 1 }, { tpl: 'h_picket', name: 'Keep B', hpf: 1, fac: 'hegemony', wk: ['battery'], cp: 1 }];
  T.RUN.cpCap = T.fleetCP() + 1; T.rewardFlow(summary); T.ACT.prizeStep();
  T.ACT.prizeSet('0:ransom'); T.ACT.prizeSet('1:add'); reload();
  const h = T.modalHtml; if (!/class="sel" data-act="prizeSet" data-arg="0:ransom"/.test(h) || !/class="sel" data-act="prizeSet" data-arg="1:add"/.test(h)) throw new Error('picks lost on reload');
  T.ACT.prizeSet('0:add'); /* now A takes the last point, so B must drop off Add */
  const h2 = T.modalHtml; if (!/data-arg="1:add" disabled/.test(h2)) throw new Error('second add still allowed past the cap');
  const f0 = T.RUN.fleet.length, inv = T.RUN.inventory.length, c0 = T.RUN.credits; T.ACT.prizeSet('1:strip'); T.ACT.prizeConfirm();
  return T.RUN.fleet.length === f0 + 1 && T.RUN.inventory.length === inv + 1 && T.RUN.credits > c0 && T.RUN.fleet.some(s => s.name === 'Keep A');
});
check('R23 batched prizes: strip gives a refit and scrap credits', () => {
  const { summary } = rewardSetup(); summary.wrecks = []; summary.prizes = [{ tpl: 'h_vanguard', name: 'Strip Me', hpf: .8, fac: 'hegemony', wk: ['battery', 'lance'], cp: 4 }];
  T.rewardFlow(summary); const inv = T.RUN.inventory.length, c0 = T.RUN.credits; T.ACT.prizeStep(); T.ACT.prizeSet('0:strip'); T.ACT.prizeConfirm(); return T.RUN.inventory.length === inv + 1 && T.RUN.credits > c0;
});
check('B2 capture: ransom pays 15% less for each ransom already taken this run, never below 40%, inside one batch too', () => {
  const { summary } = rewardSetup(); summary.wrecks = []; const pz = n => ({ tpl: 'h_vanguard', name: 'R' + n, hpf: 1, fac: 'hegemony', wk: ['battery'], cp: 4 });
  summary.prizes = [pz(1), pz(2)]; T.RUN.cpCap = 0; T.rewardFlow(summary); T.ACT.prizeStep(); T.ACT.prizeSet('0:ransom'); T.ACT.prizeSet('1:ransom');
  const v = [...T.modalHtml.matchAll(/<b>Ransom<\/b><small>(\d+) credits/g)].map(m => +m[1]); const c0 = T.RUN.credits; T.ACT.prizeConfirm();
  return v.length === 2 && v[0] > 0 && Math.abs(v[1] - v[0] * .85) <= 1 && T.RUN.credits - c0 === v[0] + v[1] && T.RUN.ransoms === 2;
});

const ASYNC = [];
ASYNC.push(['B-7 a Nova cast abandoned by a stall does not spend the cooldown; a landed one does', async () => {
  T.RUN = T.migrateRun(Object.assign(base(), { fleet: [T.newShip('ascendant')] })); T.startBattle({ kind: 'battle', fac: 'hegemony', col: 3, enemies: [{ tpl: 'h_picket' }] });
  const u = T.B.units.find(x => x.side === 'player' && x.ab === 'nova'); u.abCd = 0; const hex = T.novaTargets(u)[0]; if (!hex) throw new Error('no nova target');
  T.STALL = true; const r1 = await T.useAbility(u, { hex }); const cd1 = u.abCd; T.STALL = false; await T.useAbility(u, { hex });
  return r1 === false && cd1 === 0 && u.abCd > 0;
}]);
ASYNC.push(['B-6 a blink whose animation stalled still costs the cooldown (no free repeat jump)', async () => {
  T.RUN = T.migrateRun(Object.assign(base(), { fac: 'ithar', fleet: [T.newShip('i_blade')] })); T.startBattle({ kind: 'battle', fac: 'hegemony', col: 3, enemies: [{ tpl: 'h_picket' }] });
  const u = T.B.units.find(x => x.side === 'player' && x.ab === 'blink'); u.abCd = 0; const hex = T.blinkHexes(u)[0]; if (!hex) throw new Error('no blink hex');
  T.STALL = true; await T.useAbility(u, { hex }); T.STALL = false; return u.abCd > 0 && u.q === hex.q && u.r === hex.r;
}]);

ASYNC.push(['B-5 boarding a sector flagship down to its last crew cripples it but never flips it', async () => {
  T.RUN = T.migrateRun(Object.assign(base(), { fac: 'corsair', fleet: [T.newShip('c_hulk')] })); T.startBattle({ kind: 'boss', fac: 'hegemony', col: 6 });
  const u = T.B.units.find(x => x.side === 'player' && !x.isSq), t = T.B.units.find(x => x.side === 'enemy' && x.boss); if (!t) throw new Error('no boss');
  t.q = u.q + 1; t.r = u.r; if (T.hdist(u, t) !== 1) throw new Error('not adjacent'); u.crew = u.crewMax = 999; t.crew = 1; u.weapons.forEach(w => { w.fired = false; }); u.boarded = false; u.braced = false;
  const r = await T.boardUnit(u, t); return r === true && t.side === 'enemy' && !t.captured;
}]);
module.exports = { check, T: global.T, STORE };
if (require.main === module) (async () => { for (const [n, f] of ASYNC) { try { const r = await f(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + n); } catch (e) { fail++; console.log('FAIL  ' + n + ': ' + (e && e.message)); } } })().then(() => { console.log(`\nB1 tests: ${pass} ok, ${fail} FAIL`); if (fail) process.exitCode = 1; });
