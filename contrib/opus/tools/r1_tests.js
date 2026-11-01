// R1 rules fix batch (feel pass, Nov 1 2026): one check per fix. Run from the repo root: node contrib/opus/tools/r1_tests.js
// Covers Codex's five (PR #1), Muse's ruled fixes, the confirmed-bug list (recommendation section 3), no dead star in sector 1,
// and no implant scar for the Crusade Nemesis.
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const IDS = {};
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { if (c.id) IDS[c.id] = c; this.children.push(c); return c; }, remove() { if (this.id && IDS[this.id] === this) delete IDS[this.id]; },
  querySelector() { return null; }, querySelectorAll() { return []; }, addEventListener() {}, setAttribute() {}, focus() {} });
const APP = el('div'); APP.id = 'app'; IDS.app = APP;
global.document = { createElement: el, getElementById: id => IDS[id] || (id === 'modal' ? null : el()), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = f => { Promise.resolve().then(() => { try { f(); } catch (e) {} }); return 0; }; global.clearTimeout = () => {}; global.setInterval = () => 0; global.clearInterval = () => {};
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
const tests = [];
function check(name, fn) { tests.push([name, fn]); }
let LAST_HTML = '', TOASTS = [];
eval(src + `
function log(m){ if(B&&B.log) B.log.push({m}); } function fxText(){} function fxShield(){} function fxFlash(){} function tel(){} function nodeSeeds(){ return 0; }
async function animWeapon(){} async function animExplode(){} function fxShieldBreak(){} function fxCrit(){} function fxWithdraw(){} async function fxRam(){} function fxSectionDown(){} async function fxBoard(){}
async function animPath(u,path,opt){ if(opt&&opt.onLate) await opt.onLate(); } async function animMove(u,q,r,f){ u.q=q; u.r=r; u.facing=f; } async function animRotate(u,f){ u.facing=f; }
async function animNova(){} async function animBlink(){} function fxGravPull(){}
show=h=>{ LAST_HTML=h; }; modal=h=>{ LAST_HTML=h; }; toast=t=>{ TOASTS.push(t); }; saveRun=()=>{}; closeModal=()=>{}; relicStep=()=>{}; mapScreen=()=>{};
SPEED=0;
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get B(){ return B; }, set AI(v){ AI_LEVEL=v; }, runDefaults, newShip, newRun, startBattle, HULLS, W, EVENTS, BOONS, BOON_NEED, PATRONS, MODULES,
  derive, applyOutcome, genSector, canFitModule, ACT, rollBoonOffer, boonStep, boonReroll, boonRerollOk, boonOfferCan, rndSeed, META, needMet, eventFlags, verbFree, FAC_VERBS,
  ensureNemesis, nemAdapt, nemAfterBattle, NEM_ADAPT_FAC, relicUseful, shipyardScreen, endRun, admiralScreen, legacyScreen, ADMIRALS, LEGACY, HEAT, FAC_PRICE, HULL_VARIANTS,
  fitEncounter, rollEncounter, ENCOUNTERS, offToAx, hdist, mkWeapon, DIRS, turnStart, aiUnit, alive, evalThreat, defaultMeta, prizeScrap,
  setProg(t){ progTab=t; }, ownedPick(){ return pickedAdmiral; }, setFac(f){ pickedFaction=f; }, get html(){ return LAST_HTML; }, get toasts(){ return TOASTS; } };
`);
const fresh = (fac, tpls, sector) => { const R = T.runDefaults(); R.fac = fac || 'voidsworn'; R.admiral = 'vex'; R.sector = sector || 1; R.foes = null;
  R.fleet = (tpls || ['warden', 'harrow']).map(t => T.newShip(t)); R.flagUid = R.fleet[0] && R.fleet[0].uid; R.credits = 500; R.flags = {}; T.RUN = R; return R; };
const nemFix = (fac, sector, extra) => { const R = fresh('voidsworn', ['warden', 'harrow', 'penitent'], sector);
  R.nem = Object.assign({ fac, name: 'Test Nem', title: 'First Admiral', persona: 'proud', traits: [], portrait: 'nem_x_1', g: 'm', weak: ['ion', 'torp'], revealed: [], adapt: [], clock: 0, met: 0, beaten: 0, scars: 0,
    scarKinds: [], epithets: [], epithet: null, last_beat: null, fed: 0, riches: 0, loot: 0, held: null, gloat: null, honed: 0, revived: false, dead: false, strike: false, seen: {}, signatures: [] }, extra || {}); return R; };

// ---------- Codex's five ----------
check('TXT-2 the shipwright upgrades the most damaged ship and fully repairs the next most damaged one', () => {
  const R = fresh('voidsworn', ['warden', 'warden', 'warden']); const [A, B, C] = R.fleet; const set = (s, f) => { s.hp = Math.round(T.derive(s).maxHp * f); };
  set(A, .2); set(B, .5); set(C, .8); T.applyOutcome({ upgradeOne: 1, repairOne: 1 }); const full = s => s.hp >= T.derive(s).maxHp;
  return full(A) && A.mk === 2 && full(B) && !full(C); });
check('W3-1 the column before the rest stop always offers an elite (900 maps)', () => {
  let bad = 0; for (let seed = 1; seed <= 300; seed++) for (let s = 1; s <= 3; s++) { const R = T.runDefaults(); R.foes = null; R.condsUsed = []; R.regionsUsed = []; T.RUN = R; T.rndSeed(seed * 31 + s);
    const cols = T.genSector(s).cols; if (!cols[cols.length - 3].some(n => n.type === 'elite')) bad++; } return bad === 0; });
check('MOD-3 a refit fits only where it does something; equip refuses bad fits and bad arguments', () => {
  const R = fresh('voidsworn', ['warden', 'penitent', 'reliquary']); const [w, p, c] = R.fleet;
  const a = !T.canFitModule(w, 'crystal') && T.canFitModule(p, 'crystal') && T.canFitModule(c, 'hangar') && !T.canFitModule(p, 'hangar') && T.canFitModule(w, 'prow') && !T.canFitModule(w, 'nope');
  R.inventory = ['crystal']; const r1 = T.ACT.equip('0:' + w.uid); const r2 = T.ACT.equip('-1:' + p.uid), r3 = T.ACT.equip('01:' + p.uid), r4 = T.ACT.equip('5:' + p.uid);
  const refused = !w.mods.includes('crystal') && r1 === false && r2 === false && r3 === false && r4 === false && R.inventory.length === 1;
  T.ACT.equip('0:' + p.uid); return a && refused && p.mods.includes('crystal') && R.inventory.length === 0; });
check('FR-2 a lost Nemesis meeting reveals exactly one new weakness; a complete file reveals nothing; a battle discovery counts as the one', () => {
  const R1 = nemFix('hegemony', 1); const l1 = T.nemAfterBattle('loss', false, {}); const one = R1.nem.revealed.length === 1 && l1.some(x => /analysts piece together the engagement\. Weakness found: /.test(x));
  const R2 = nemFix('hegemony', 1, { revealed: ['ion', 'torp'] }); const l2 = T.nemAfterBattle('retreat', false, {}); const none = R2.nem.revealed.length === 2 && l2.some(x => /file on Test Nem is complete/.test(x));
  const R3 = nemFix('hegemony', 1); T.nemAfterBattle('loss', false, { found: ['torp'] }); const conf = R3.nem.revealed.length === 1 && R3.nem.revealed[0] === 'torp';
  const R4 = nemFix('hegemony', 1); const l4 = T.nemAfterBattle('win', false, { found: ['torp'] }); const win = R4.nem.revealed.length === 2 && l4.some(x => /Weakness confirmed/.test(x));
  return one && none && conf && win; });
check('NEM-2 an adaptation never counters a revealed weakness (ion blocks shields, torpedoes block point defense), fallback included', () => {
  nemFix('hegemony', 2, { revealed: ['ion'], seen: { lance: 10, ion: 10 } }); const a1 = T.nemAdapt();
  nemFix('hegemony', 2, { revealed: ['torp'], seen: { torp: 10, sq: 10 } }); const a2 = T.nemAdapt();
  const R = nemFix('hegemony', 3, { revealed: ['ion', 'torp'], adapt: ['armor', 'evasion', 'aim'], seen: {} }); const sp = T.NEM_ADAPT_FAC.hegemony.special; R.nem.adapt.push(sp.id); const a3 = T.nemAdapt(true);
  return a1 !== 'shields' && a1 && a2 !== 'pd' && a2 && a3 === null; });
check('boons: L_storm needs shields; no owned, duplicate or useless filler; off-core picks keep the core\'s sync (no Common at tier 3)', () => {
  const R = fresh('voidsworn', ['penitent', 'warden', 'harrow', 'cathedral', 'h_picket', 'h_vanguard', 'h_dominion', 'reliquary', 'i_song', 'c_reaver'], 2);
  R.patrons = ['iron', 'storm', 'star', 'rook']; R.boons = ['i_broad', 'i_still', 'i_plate', 'i_brace', 'i_line'].map(id => ({ id, r: 0 })); T.META.favour = { iron: 25 };
  let off = 0, offCommon = 0, dup = 0, owned = 0;
  for (let s = 1; s <= 300; s++) { T.rndSeed(s * 17 + 3); const o = T.rollBoonOffer('iron', 0); const ids = o.map(x => x.id); if (new Set(ids).size !== ids.length) dup++;
    for (const x of o) { const b = T.BOONS[x.id]; if (R.boons.some(h => h.id === x.id)) owned++; if (b.p && b.p !== 'iron' && !b.duo) { off++; if (x.r === 0) offCommon++; } } }
  return T.BOON_NEED.L_storm === 'shields' && off > 0 && offCommon === 0 && dup === 0 && owned === 0; });
check('boons: with a duo and the core\'s legendary both eligible, either can take the special slot', () => {
  const duoId = Object.keys(T.BOONS).find(id => T.BOONS[id].duo); const [p, q] = T.BOONS[duoId].duo;
  const ofP = Object.keys(T.BOONS).filter(id => T.BOONS[id].p === p && !T.BOONS[id].leg), ofQ = Object.keys(T.BOONS).filter(id => T.BOONS[id].p === q && !T.BOONS[id].leg);
  const R = fresh('voidsworn', ['warden', 'harrow', 'reliquary', 'penitent', 'h_picket', 'h_vanguard'], 2); R.patrons = [p, q]; R.boons = [{ id: ofP[0], r: 0 }, { id: ofP[1], r: 0 }, { id: ofQ[0], r: 0 }];
  let duo = 0, leg = 0; for (let s = 1; s <= 300; s++) { T.rndSeed(s * 13 + 5); const o = T.rollBoonOffer(p, 1); if (o.some(x => x.id === duoId)) duo++; if (o.some(x => T.BOONS[x.id].leg)) leg++; }
  return duo > 60 && leg > 100; });
check('boons (R64): a short offer pays 60 credits once per reward, an empty one pays 60 and moves on', () => {
  const R = fresh('voidsworn', ['warden'], 1); R.patrons = ['iron']; R.credits = 0;
  R.reward = { boonOffer: [{ id: 'i_broad', r: 0 }] }; T.boonStep('iron', 0); const c1 = R.credits; T.boonStep('iron', 0); const c2 = R.credits;
  R.reward = { boonOffer: [] }; R.credits = 0; T.boonStep('iron', 0); const c3 = R.credits;
  R.reward = { boonOffer: [{ id: 'i_broad', r: 0 }, { id: 'i_still', r: 0 }, { id: 'i_plate', r: 0 }] }; R.credits = 0; T.boonStep('iron', 0);
  return c1 === 60 && c2 === 60 && c3 === 60 && R.credits === 0; });
check('RWD-6 a reroll that cannot change the offer is refused and charges nothing; one that can is allowed', () => {
  const R = fresh('voidsworn', ['warden', 'harrow', 'reliquary', 'penitent', 'h_picket', 'h_vanguard'], 1); R.patrons = ['iron']; R.credits = 100; R.boonRerolls = 0;
  const leave = ['i_broad', 'i_still', 'i_plate']; R.boons = Object.keys(T.BOONS).filter(id => T.BOONS[id].p === 'iron' && !T.BOONS[id].leg && !leave.includes(id)).map(id => ({ id, r: 0 }));
  R.reward = { boonOffer: leave.map(id => ({ id, r: 0 })), rerolled: false }; const ok0 = T.boonRerollOk('iron', 0); const res = T.boonReroll('iron', 0);
  const refused = !ok0 && res === null && R.credits === 100;
  R.boons = []; const ok1 = T.boonRerollOk('iron', 0); const res1 = T.boonReroll('iron', 0); return refused && ok1 && Array.isArray(res1) && R.credits === 75; });

// ---------- Muse's ruled fixes ----------
check('EVT-5 every fight-start event has a free way out (haven gets one)', () => {
  const free = o => !o.need && o.r && Object.keys(o.r).every(k => k === 'cred' || k === 'xp');
  const bad = T.EVENTS.filter(e => e.o.some(o => o.r && o.r.fight) && !e.o.some(free)).map(e => e.id); return bad.length === 0 && T.EVENTS.find(e => e.id === 'haven').o.some(o => o.k === 'leave'); });
check('AI-1 a veteran that moves under heavy fire with nothing to shoot braces (mid-move path)', async () => {
  T.AI = 'veteran'; fresh('voidsworn', ['penitent', 'penitent', 'penitent']);
  T.startBattle({ kind: 'battle', fac: 'deathless', col: 3, obj: 'rout', shape: 'open', map: 'storm', dep: 'line', arena: 'strip', seed: 11, enemies: [{ tpl: 'd_jackal' }] });
  const B = T.B; B.terrain = {}; const pens = B.units.filter(u => u.side === 'player'), m = B.units.find(u => u.side === 'enemy');
  [[6, 5], [6, 7], [6, 9]].forEach((p, i) => { const h = T.offToAx(p[0], p[1]); pens[i].q = h.q; pens[i].r = h.r; }); const mh = T.offToAx(14, 7); m.q = mh.q; m.r = mh.r;
  for (const p of pens) { let bf = 0, bd = 1e9; for (let f = 0; f < 6; f++) { const d = T.hdist({ q: p.q + T.DIRS[f][0], r: p.r + T.DIRS[f][1] }, m); if (d < bd) { bd = d; bf = f; } } p.facing = bf; }
  const w = T.mkWeapon('scatter', 'T', {}); w.fired = false; w.cdLeft = 2; w.off = 0; m.weapons = [w]; m.ab = null; m.maxHp = 100; m.hp = 60; m.sh = [0, 0, 0, 0]; m.shMax = 0;
  const d0 = Math.min(...pens.map(p => T.hdist(m, p))); B.side = 'enemy'; await T.turnStart('enemy'); await T.aiUnit(m); const d1 = Math.min(...pens.map(p => T.hdist(m, p)));
  T.AI = 'standard'; return d1 < d0 && m.braced === true; });
check('WPN-1 Null sentries are no longer a copy of the flak battery (and stay point defense)', () => {
  const a = T.W.flak, b = T.W.gsentry; const same = Object.keys(Object.assign({}, a, b)).filter(k => k !== 'n').every(k => a[k] === b[k]); return !same && b.k === 'flak' && b.vsSq > 0; });
check('salvage (relics): none offered that can never act (coils without abilities, logbook at top rank, chalked roll for a lone ship)', () => {
  const R = fresh('voidsworn', ['warden']); const lone = !T.relicUseful('martyr'); R.fleet.push(T.newShip('harrow')); const two = T.relicUseful('martyr');
  R.fleet.forEach(s => { s.cap.rank = 4; }); const top = !T.relicUseful('logbook'); R.fleet[0].cap.rank = 2; const low = T.relicUseful('logbook');
  R.fleet.forEach(s => { s.tpl = 'fighter'; }); const noab = !T.relicUseful('coils'); return lone && two && top && low && noab && T.relicUseful('ledger'); });
check('ROS-2 and ROS-3 every hull variant that drops a gun or the ability says so', () => {
  const V = T.HULL_VARIANTS; return /null cannon instead of two/.test(V.d_harvester_t.d) && /in place of the two prow lances/.test(V.i_song_w.d) && /Trades its spine volley/.test(V.b_razor_s.d)
    && /no Launch squadron ability/.test(V.h_vanguard_g.d) && /no Launch squadron ability/.test(V.c_hulk_g.d); });
check('h_repair is named and described for what it does (free repairs only)', () => T.HEAT.h_repair.n === 'Thin repair crews' && /Shipyard repairs are unaffected/.test(T.HEAT.h_repair.d));
check('FS-2 the Eclipse price table has a battleship key above its cruiser', () => T.FAC_PRICE.deathless.Battleship > T.FAC_PRICE.deathless.Cruiser);

// ---------- the confirmed-bug list ----------
check('TXT-8 the decommission label shows what the button pays, never NaN', () => {
  const R = fresh('voidsworn', ['warden', 'h_boss']); R.credits = 1000; T.shipyardScreen({ id: 'y1', type: 'shipyard', stock: { hulls: [], mods: [], sold: [] } });
  return !T.html.includes('NaN') && T.html.includes('Decommission (+' + T.prizeScrap('h_boss') + ')'); });
check('PROG-5 mastery: 1 per battle, 2 per elite, 5 per flagship, no double count', () => {
  const R = fresh('hegemony', ['h_picket'], 3); R.admiral = 'malek'; R.stats = { battles: 3, elites: 1, bosses: 1, kills: 5, lost: 0 }; R.fallen = []; R.t0 = Date.now();
  T.META.mastery = {}; T.endRun(false, false); return (T.META.mastery.malek || 0) === 1 + 2 + 5; });
check('EVT-1 a flag gate opens only on the choices it names (defector questioned, not sold back)', () => {
  const R = fresh('hegemony', ['h_picket', 'h_vanguard']); const def = T.EVENTS.find(e => e.id === 'defector'), sab = T.EVENTS.find(e => e.id === 'saboteur').o.find(o => o.k === 'face');
  const opt = k => def.o.find(o => o.k === k); T.eventFlags(def, opt('ransom'), 1); const n1 = T.needMet(sab.need), v1 = T.verbFree(T.FAC_VERBS.hegemony);
  R.flags = {}; T.eventFlags(def, opt('question'), 0); const n2 = T.needMet(sab.need), v2 = T.verbFree(T.FAC_VERBS.hegemony);
  const shr = T.EVENTS.find(e => e.id === 'shrine'); R.fac = 'voidsworn'; R.flags = {}; T.eventFlags(shr, shr.o.find(o => o.k === 'leave'), 3); const v3 = T.verbFree(T.FAC_VERBS.voidsworn);
  R.flags = {}; T.eventFlags(shr, shr.o.find(o => o.k === 'offer'), 0); const v4 = T.verbFree(T.FAC_VERBS.voidsworn);
  return !n1 && !v1 && n2 && v2 && !v3 && v4; });
check('EVT-2 the Glasswrights can meet the Glasswright wanderer, so its tone option can appear', () => { const e = T.EVENTS.find(x => x.id === 'seer'); return !(e.not || []).includes('ithar') && e.o.some(o => o.need && o.need.fac === 'ithar'); });
check('NEM-7 a pre-persona save keeps loot, riches, feeding, honing, the held ship and its faction adaptation', () => {
  const R = fresh('voidsworn', ['warden', 'harrow'], 2); R.nem = { weak: ['ion', 'slow'], revealed: ['ion'], adapt: ['riches'], clock: 2, met: 1, beaten: 1, scars: 1, dead: false, strike: false, seen: {}, loot: 500, riches: 2, fed: 3, honed: 1, held: R.fleet[1], last_beat: 'lance' };
  const N = T.ensureNemesis(); return N.persona && N.fac === 'corsair' && N.loot === 500 && N.riches === 2 && N.fed === 3 && N.honed === 1 && !!N.held && N.adapt.includes('riches') && N.last_beat === 'lance'; });
check('PROG-2 locked admirals and Legacy unlocks have a working purchase button', () => {
  T.META.renown = 200; T.META.admirals = { vex: true }; T.META.unlocked = {}; global.pickedFaction = 'voidsworn';
  T.admiralScreen(); const btn = /data-act="buyAdmiral" data-arg="malek"/.test(T.html); T.ACT.buyAdmiral('malek'); const bought = T.META.admirals.malek === true && T.META.renown === 200 - T.ADMIRALS.malek.cost;
  T.setProg('legacy'); T.legacyScreen(); const lb = /data-act="buyLegacy" data-arg="chest1"/.test(T.html) && !/data-arg="chest2"/.test(T.html);
  const r0 = T.META.renown; T.ACT.buyLegacy('chest2'); const reqHeld = !T.META.unlocked.chest2 && T.META.renown === r0; T.ACT.buyLegacy('chest1');
  return btn && bought && lb && reqHeld && T.META.unlocked.chest1 && T.META.renown === r0 - T.LEGACY.chest1.cost; });
check('PROG-6 only an owned admiral (bought, or free) can be picked or launched; every faction keeps a free first admiral', () => {
  T.META.renown = 0; T.META.admirals = { vex: true }; T.setFac('hegemony'); T.admiralScreen();
  const freeOk = /data-act="pickAdmiral" data-arg="kassar"/.test(T.html) && !/data-act="pickAdmiral" data-arg="vorn"/.test(T.html) && /data-act="buyAdmiral" data-arg="vorn"/.test(T.html);
  T.ACT.pickAdmiral('vorn'); T.admiralScreen(); const stayed = T.ownedPick() === 'kassar'; T.setFac('voidsworn');
  const firsts = ['voidsworn', 'hegemony', 'corsair', 'chorus', 'ithar', 'deathless'].every(f => Object.entries(T.ADMIRALS).some(([id, a]) => (a.fac || 'voidsworn') === f && !(a.cost > 0)));
  return freeOk && stayed && firsts; });
check('the Hullbreaker surname pool has no Greyback', () => !/Greyback/.test(fs.readFileSync(path.join(ROOT, 'data.js'), 'utf8')));
check('naming lint: 0 hard hits in R1 files (JS game files, godot/rules, godot/campaign, godot/ui/campaign); the three clashing Hullbreaker surnames are gone', () => {
  const out = require('child_process').spawnSync(process.execPath, [path.join(ROOT, 'contrib/opus/tools/naming_lint_game.js')], { cwd: ROOT, encoding: 'utf8' }).stdout || '';
  const mine = out.split('\n').filter(l => / HARD /.test(l) && (/^[a-z0-9_]+\.(js|html):/.test(l) || /^godot\/(rules|campaign|ui\/campaign)\//.test(l)));
  if (mine.length) console.log('   ' + mine.join('\n   '));
  const d = fs.readFileSync(path.join(ROOT, 'data.js'), 'utf8');
  return /naming_lint_game:/.test(out) && mine.length === 0 && !/Red-Muzzle|Ashfur|Rustcoat/.test(d); });
check('UI-6 the battle hint never says "nothing left" while the ship can move or brace (ui3d.js)', () => {
  const s = fs.readFileSync(path.join(ROOT, 'ui3d.js'), 'utf8'); return /u\.mp>0\?'Tap a gold hex to keep moving/.test(s) && /canOrder\(u,'brace'\)\?'Nothing in range\. Tap Brace/.test(s); });

// ---------- the new rulings ----------
check('no dead star in sector 1: maps (300 runs) and battle setup with cfg.noStar (2,000 fights); later sectors still can', () => {
  let s1 = 0, s23 = 0; for (let seed = 1; seed <= 300; seed++) for (let s = 1; s <= 3; s++) { const R = T.runDefaults(); R.fac = ['ithar', 'deathless', 'chorus'][seed % 3]; R.foes = null; R.condsUsed = []; R.regionsUsed = []; R.sector = s; T.RUN = R; T.rndSeed(seed * 7 + s);
    for (const c of T.genSector(s).cols) for (const n of c) if (n.shape === 'deadstar') { if (s === 1) s1++; else s23++; } }
  const R = fresh('ithar', ['i_wisp', 'i_blade']); let bs = 0, bsOff = 0;
  for (let i = 0; i < 1000; i++) { for (const ns of [true, false]) { T.startBattle({ kind: 'battle', fac: 'chorus', col: 2, obj: 'rout', shape: ['deadstar', 'corridor', 'lanes'][i % 3], map: 'storm', seed: 900 + i, noStar: ns, enemies: [{ tpl: 'b_drone' }] });
    if (T.B.shape === 'deadstar') { if (ns) bs++; else bsOff++; } } }
  return s1 === 0 && s23 > 0 && bs === 0 && bsOff > 0; });
check('no implant scar for the Crusade Nemesis (scars.json: cyber is not a Sunward Crusade scar)', () => {
  const sc = JSON.parse(fs.readFileSync(path.join(ROOT, 'godot/portraits/nemesis/scars/scars.json'), 'utf8')); return !sc.kinds.cyber.includes('voidsworn') && sc.kinds.cyber.includes('hegemony') && sc.kinds.eye.includes('voidsworn'); });

(async () => { let pass = 0, fail = 0;
  for (const [name, fn] of tests) { let ok = false, err = ''; try { ok = await fn(); } catch (e) { err = ' (' + (e && e.message) + ')'; }
    if (ok === true) { pass++; console.log('ok    ' + name); } else { fail++; console.log('FAIL  ' + name + err); } }
  console.log('\nR1 tests: ' + pass + ' ok, ' + fail + ' FAIL'); process.exit(fail ? 1 : 0); })();
