// Battle screen mockups for issue #271 (round 1). One shared component set; three layouts; two materials.
// Query: ?l=1|2|3&v=restrained|bold&n=10|20
const Q = new URLSearchParams(location.search);
const L = Q.get('l') || '1';
const V = Q.get('v') || 'restrained';
const N = parseInt(Q.get('n') || '10', 10);
document.body.classList.add(V);

// ---------------------------------------------------------------- data (one Nemesis fight, round 3, your turn)
const FLEET = [
  { n: 'Long Watch', flag: true, c: 'Daybreak dreadnought', cap: 'Lt. Lucan Wyndham', hp: 312, mx: 370, sh: [24, 32, 18, 32], sm: 32, st: 'Up' },
  { n: 'Debt Paid', c: 'Battleship', cap: 'Cmdr. Ilse Varga', hp: 288, mx: 340, sh: [30, 30, 30, 22], sm: 30, st: 'Ready' },
  { n: 'Oath Flame', c: 'Cruiser', cap: 'Capt. Odile Salo', hp: 96, mx: 160, sh: [12, 20, 20, 20], sm: 20, st: 'Ready' },
  { n: 'Resolve of the Reach', c: 'Carrier', cap: 'Capt. Brann Hollis', hp: 190, mx: 220, sh: [20, 20, 20, 20], sm: 20, st: 'Ready' },
  { n: 'Unyielding Oath', c: 'Destroyer', cap: 'Lt. Mara Kest', hp: 31, mx: 110, sh: [0, 6, 0, 0], sm: 14, st: 'Ready' },
  { n: 'Vigilant Ash', c: 'Destroyer', cap: 'Lt. Corin Dahl', hp: 110, mx: 110, sh: [14, 14, 14, 14], sm: 14, st: 'Done' },
  { n: 'Ashen Vigil', c: 'Frigate', cap: 'Ens. Tamsin Reed', hp: 64, mx: 70, sh: [10, 10, 4, 10], sm: 10, st: 'Done' },
  { n: 'Debt of Vesper', c: 'Frigate', cap: 'Ens. Pell Arno', hp: 70, mx: 70, sh: [10, 10, 10, 10], sm: 10, st: 'Ready' },
  { n: 'Merciless Frost', c: 'Frigate', cap: 'Lt. Hesk Moran', hp: 22, mx: 70, sh: [0, 0, 0, 3], sm: 10, st: 'Braced' },
  { n: 'Dawn of Cinders', c: 'Frigate', cap: 'Ens. Ada Quill', hp: 58, mx: 70, sh: [10, 10, 10, 10], sm: 10, st: 'Done' },
];
const MORE = [ // only for the 20-ship stress render
  ['Ember Tithe', 'Cruiser'], ['Gilded Penance', 'Destroyer'], ['Ninth Lantern', 'Frigate'], ['Sworn Kindling', 'Frigate'],
  ['Pale Vow', 'Destroyer'], ['Hearth of Ruin', 'Battleship'], ['Last Matins', 'Frigate'], ['Cinder Psalm', 'Frigate'],
  ['Unbroken Dusk', 'Cruiser'], ['Witness of Ash', 'Frigate']];
if (N > 10) MORE.slice(0, N - 10).forEach(([n, c], i) => FLEET.push({ n, c, cap: ['Lt. Ros Mallory', 'Ens. Kit Varro', 'Cmdr. Jem Hale', 'Lt. Sefa Orrin', 'Ens. Bo Lark'][i % 5],
  hp: [80, 60, 44, 70, 100, 300, 18, 66, 150, 52][i], mx: [160, 110, 70, 70, 110, 340, 70, 70, 160, 70][i], sh: [10, 10, 10, 10], sm: 10, st: i % 3 ? 'Ready' : 'Done' }));
const ACTED = FLEET.filter(s => s.st === 'Done' || s.st === 'Braced').length;
const SHIP = FLEET[0];
const READY = FLEET.filter(s => s.st === 'Ready'); const NEXT = READY[0];

// in-world plates, placed where the capture's own plates were (centre x, top y)
const PLATES = [
  { n: 'Debt of Vesper', x: 511, y: 380 }, { n: 'Oath Flame', x: 488, y: 422 },
  { n: 'Long Watch', x: 451, y: 458, up: true, flag: true }, { n: 'Resolve of the Reach', x: 336, y: 502 },
  { n: 'Debt Paid', x: 409, y: 530 }, { n: 'Merciless Frost', x: 372, y: 612 },
  { n: 'Bomber wing (Resolve of the Reach)', x: 717, y: 518, wing: true }, { n: 'Fighter wing (Resolve of the Reach)', x: 740, y: 552, wing: true },
  { n: 'Hullbreaker raider', x: 1369, y: 380, e: true, hp: 0.3 }, { n: 'Hullbreaker gutship', x: 1390, y: 424, e: true, hp: 0.8 },
  { n: 'Hullbreaker wrecker', x: 1512, y: 424, e: true, hp: 0.55, tgt: true },
  { n: "Warlord's Pyre-Barge", x: 1489, y: 464, e: true, flag: true, nem: true, hp: 0.9 },
  { n: 'Bomber wing (Pyre-Barge)', x: 1477, y: 518, e: true, wing: true, hp: 1 }, { n: 'Hullbreaker raider', x: 1442, y: 574, e: true, hp: 1 },
  { n: 'Hullbreaker gutship', x: 1482, y: 652, e: true, hp: 0.95 },
];

const WEAPONS = [
  { k: 1, n: 'Heavy sear broadside', a: 'Port', d: '5 x 7', r: 5, odds: null, why: 'no enemy in the port arc' },
  { k: 2, n: 'Heavy sear broadside', a: 'Starboard', d: '5 x 7', r: 5, odds: 64, exp: '22', armed: true },
  { k: 3, n: 'Sear turret', a: 'Turret', d: '2 x 8', r: 5, odds: 58, exp: '9' },
  { k: 4, n: 'Spark flak', a: 'Turret', d: '3 x 3', r: 2, odds: null, why: 'anti-squadron, range 2' },
];
const ORDERS = [
  { k: 'B', n: 'Brace', t: 'ends this ship, less damage taken' },
  { k: '5', n: 'Spinal cannon', t: '1 x 40, prow, once a battle', lit: true },
  { k: 'X', n: 'Ram', t: 'no enemy adjacent', off: true },
  { k: 'G', n: 'Board', t: 'no enemy adjacent', off: true },
  { k: 'Q', n: 'Turn left', t: '1 turn left' },
  { k: 'E', n: 'Turn right', t: '1 turn left' },
];
const LOG = [
  ['R2', 'p', 'Debt Paid hit Hullbreaker wrecker: 2 of 4 shots, 31 damage. Its prow shield is down.'],
  ['R2', 'e', 'Hullbreaker gutship rammed Unyielding Oath: 46 damage.'],
  ['R2', 's', 'Skarn-Maw: "Lances again? I grew a thicker hide for you."'],
  ['R2', 'e', "Warlord's Pyre-Barge hit Oath Flame: 3 of 5 shots, 38 damage."],
  ['R3', 's', 'Admiral Vex: "Hold the line. Let them come to the broadsides."'],
  ['R3', 'x', 'Merciless Frost braced.'],
  ['R3', 'p', 'Ashen Vigil hit Hullbreaker raider: 18 damage. The raider is crippled.'],
  ['R3', 'p', 'Vigilant Ash hit Hullbreaker raider: 12 damage.'],
];

// ---------------------------------------------------------------- builders
const $ = (h) => { const t = document.createElement('template'); t.innerHTML = h.trim(); return t.content.firstChild; };
const ui = document.getElementById('ui');
function pane(x, y, w, h, inner, cls = '', parent = null) {
  const el = $(`<div class="pane ${cls}" style="${parent ? 'position:relative;' : `left:${x}px;top:${y}px;`}width:${w}px;${h ? `height:${h}px;` : ''}"></div>`);
  el.innerHTML = inner + '<i class="reg tr"></i><i class="reg bl"></i>';
  (parent || ui).appendChild(el); return el;
}
function hbar(f, segs = 10) {
  let s = ''; for (let i = 0; i < segs; i++) { const p = Math.max(0, Math.min(1, f * segs - i)); s += `<i><b style="width:${p * 100}%"></b></i>`; }
  return `<div class="hbar ${f < 0.35 ? 'low' : ''}">${s}</div>`;
}
function sbar(sh, mx) { return `<div class="sbar">${sh.map(v => `<i><b style="width:${Math.max(0, Math.min(1, v / mx)) * 100}%"></b></i>`).join('')}</div>`; }
const star = (s) => s.flag ? '&#9733; ' : '';
const key = (k) => `<span class="key">${k}</span>`;
function track() {
  let s = ''; FLEET.forEach((f, i) => { s += `<i class="${f.st === 'Up' ? 'u' : (f.st === 'Done' || f.st === 'Braced') ? 'd' : ''}"></i>`; });
  s += '<span class="sep"></span>'; for (let i = 0; i < 10; i++) s += '<i class="e"></i>';
  return `<div class="track">${s}</div>`;
}
function plates() {
  PLATES.forEach(p => {
    const f = p.e ? null : FLEET.find(s => s.n === p.n);
    const hp = p.e ? p.hp : (f ? f.hp / f.mx : 1);
    const sh = p.e ? [0.6, 1, 1, 0.8] : (f ? f.sh.map(v => v / f.sm) : [1, 1, 1, 1]);
    const cls = ['plate', p.e ? 'e' : '', p.up ? 'sel' : '', p.tgt ? 'tgt' : '', p.nem ? 'nem' : ''].join(' ');
    const [px, py] = T(p.x, p.y);
    const el = $(`<div class="${cls}" style="left:${px}px;top:${py}px"></div>`);
    el.innerHTML = `${p.nem ? '<span class="tag nem nemtag">Nemesis</span>' : ''}<div class="pn">${p.up ? '<span class="tag up" style="height:15px;margin-right:5px">Up</span>' : ''}${p.flag ? '&#9733; ' : ''}${p.n}</div>`
      + (p.wing ? '' : hbar(hp, 8) + sbar(sh, 1)) + (p.tgt ? '<span class="odds">64%  2 guns</span>' : '');
    ui.appendChild(el);
  });
}
function rosterRows(opt = {}) {
  return FLEET.map(s => {
    const f = s.hp / s.mx, up = s.st === 'Up', done = s.st === 'Done' || s.st === 'Braced';
    const stc = up ? 'gilt' : s.st === 'Ready' ? 'verd' : 'dim3';
    const cap = opt.cap === 'all' || (opt.cap === 'sel' && up);
    return `<div class="rr" style="padding:${opt.pad || 6}px 8px;${up ? 'background:rgba(77,61,26,0.45);outline:1px solid var(--gilt);outline-offset:-1px;' : ''}${done ? 'opacity:0.55;' : ''}">
      <div class="row"><span class="grow ell" style="font-weight:600;font-size:15px">${star(s)}${s.n}</span>${f < 0.35 ? '<span class="lowtag">LOW</span>' : ''}<span class="s13 ${stc}" style="font-weight:600">${s.st}</span></div>
      ${opt.cls ? `<div class="s13 dim ell">${s.c}${cap ? ' &middot; ' + s.cap : ''}</div>` : (cap ? `<div class="s13 dim ell">${s.cap}</div>` : '')}
      <div style="margin-top:4px">${hbar(f)}${sbar(s.sh, s.sm)}</div></div>`;
  }).join('');
}
function logLines(list = LOG) { return `<div class="log">${list.map(([r, c, t]) => `<div class="ln"><span class="r">${r}</span><span class="${c}">${t}</span></div>`).join('')}</div>`; }
function weaponTile(w, opt = {}) {
  return `<div class="wpn ${w.armed ? 'armed' : ''} ${w.odds ? '' : 'no'}">
    <div class="wt">${key(w.k)}<span class="grow ell">${w.n}</span>${w.odds ? `<span class="wo gilt">${w.odds}%</span>` : '<span class="wo">--</span>'}</div>
    <div class="wd">${w.a} &middot; ${w.d} &middot; range ${w.r}${w.odds ? ` &middot; about <span class="bone">${w.exp}</span> damage` : ` &middot; ${w.why}`}</div></div>`;
}
function orderBtn(o, wide) {
  return `<div class="btn ${o.off ? 'off' : ''} ${o.lit ? 'lit' : ''}" style="${wide ? 'width:100%;' : ''}">${key(o.k)}<span>${o.n}</span>${wide ? `<span class="s12 dim3 grow ell" style="text-align:right">${o.t}</span>` : ''}</div>`;
}
function stepsHtml() {
  return `<div class="steps">
    <div class="step now"><span class="sn">1 MOVE</span><span>3 of 3 left</span></div>
    <div class="step"><span class="sn">2 FIRE</span><span>2 of 4 guns bear</span></div>
    <div class="step"><span class="sn">3 END</span><span>Space</span></div></div>`;
}
function shipHead(opt = {}) {
  const s = SHIP, f = s.hp / s.mx;
  return `<div class="row"><span class="tag up">Up</span><span class="h-ship ell">&#9733; ${s.n}</span></div>
  <div class="s14 dim" style="margin-top:2px">${s.c} &middot; ${s.cap}</div>
  <div class="row" style="margin-top:8px"><span class="caps" style="width:44px">Hull</span><div class="grow">${hbar(f)}</div><span class="num s14">${s.hp}<span class="dim3">/${s.mx}</span></span></div>
  <div class="row" style="margin-top:5px"><span class="caps" style="width:44px">Shld</span><div class="grow" style="display:flex;gap:3px">${['Prow', 'Stbd', 'Rear', 'Port'].map((nm, i) => `<div style="flex:1"><div class="sbar" style="height:4px">${`<i><b style="width:${s.sh[i] / s.sm * 100}%"></b></i>`}</div><div class="s12 dim3" style="margin-top:2px">${nm} <span class="num" style="color:var(--shield)">${s.sh[i]}</span></div></div>`).join('')}</div></div>
  ${opt.stats === false ? '' : `<div class="row s14" style="margin-top:6px;gap:12px;flex-wrap:wrap"><span><span class="dim3">ARM</span> <span class="num">35%</span></span><span><span class="dim3">EVA</span> <span class="num">0</span></span><span><span class="dim3">MOVE</span> <span class="num gilt">3/3</span></span><span><span class="dim3">TURNS</span> <span class="num">1</span></span><span><span class="dim3">CREW</span> <span class="num">128</span></span></div>`}`;
}
function nemesisHtml(opt = {}) {
  return `<div class="row" style="align-items:flex-start;gap:10px">
    <img class="portrait" src="nem.webp" style="${opt.small ? 'width:40px;height:40px' : ''}">
    <div class="grow">
      ${opt.stack ? `<span class="tag nem">Nemesis</span><div style="font-weight:600;font-size:16px;margin-top:4px">Warlord Skarn-Maw <span class="dim s13" style="font-weight:400">the Uncaught</span></div>`
        : `<div class="row"><span class="tag nem">Nemesis</span><span style="font-weight:600;font-size:16px">Warlord Skarn-Maw</span><span class="dim s13">the Uncaught</span></div>`}
      <div class="s13 dim" style="margin-top:3px">Aboard &#9733; Warlord's Pyre-Barge &middot; flees below 35% hull</div>
      ${opt.lines === false ? '' : `<div class="s13" style="margin-top:5px"><span class="blood">Adapted:</span> enemy shields +20% <span class="dim3">(you leaned on lances)</span></div>
      <div class="s13"><span class="verd">Weakness:</span> rear-arc hits do +25% <span class="dim3">(thin stern plating)</span></div>`}
    </div></div>`;
}
function nextHtml() {
  return `<div class="s14" style="line-height:1.4">
    <div><span class="dim3">Then</span> <span class="friend" style="font-weight:600">${NEXT.n}</span> is up <span class="dim3">(Tab)</span>, ${READY.length - 1} more of yours after it.</div>
    <div><span class="dim3">Then the</span> <span class="foe" style="font-weight:600">enemy turn</span>: 10 ships. <span class="blood">3 can reach Long Watch.</span></div></div>`;
}
const CREST_OWN = '<img class="crest" src="faction_voidsworn.svg">';
const CREST_FOE = '<img class="crest sm" src="faction_corsair.svg">';
const BOLD = V === 'bold';
// camera framing per layout: the same capture, zoomed so the two fleets sit in the open field (screen-space plates keep their size)
const CAM = { 1: [1, 0, 0], 2: [0.9, 16, 52], 3: [0.92, 62, 44] }[L];
const T = (x, y) => [Math.round(CAM[1] + x * CAM[0]), Math.round(CAM[2] + y * CAM[0])];
(function frame() {
  const f = document.getElementById('field');
  if (CAM[0] === 1) return;
  f.style.background = 'none';
  f.innerHTML = `<div style="position:absolute;inset:-40px;background:url(bg.png) center/cover;filter:blur(18px) brightness(0.55)"></div>
    <div style="position:absolute;left:${CAM[1]}px;top:${CAM[2]}px;width:${1920 * CAM[0]}px;height:${1080 * CAM[0]}px;background:url(bg.png) 0 0/100% 100%;
      -webkit-mask-image:linear-gradient(90deg,transparent,#000 4%,#000 96%,transparent),linear-gradient(180deg,transparent,#000 5%,#000 95%,transparent);-webkit-mask-composite:source-in;mask-composite:intersect"></div>`;
})();
function facLine(c) { return BOLD ? `<div class="facline" style="background:${c}"></div>` : ''; }

// ---------------------------------------------------------------- layout 1: Command Dock (bottom console)
function layout1() {
  // top strip
  pane(0, 0, 1920, 48, `<div class="row" style="height:46px;padding:0 14px;gap:14px">
    <div style="display:flex;flex-direction:column;align-items:center;gap:2px">${CREST_OWN}</div>
    <span class="big-round">ROUND 3</span><span class="caps" style="color:var(--gilt);font-size:13px">Your turn</span>
    ${track()}<span class="s14 dim"><span class="num">${ACTED}</span> of ${FLEET.length} acted, then the enemy</span>
    <span class="grow"></span>
    <span class="s14 gilt">Break their fleet</span><span style="width:1px;height:22px;background:var(--line)"></span>
    ${CREST_FOE}<span class="s14">Ashfall Hullbreakers</span>
    <span style="width:1px;height:22px;background:var(--line)"></span>
    <span class="caps">Heat</span><span class="num ember s17">3</span>
    <span style="width:1px;height:22px;background:var(--line)"></span>
    <div class="btn">${key('Z')}Grid</div><div class="btn">${key('R')}Threat</div><div class="btn">${key('T')}Top-down</div><div class="btn">Speed: normal</div><div class="btn">${key('Esc')}Menu</div>
  </div>${BOLD ? '<div style="position:absolute;left:14px;bottom:-1px;width:34px;height:2px;background:var(--fac-own)"></div>' : ''}`, 'flat');
  // nemesis plate, top centre
  pane(700, 58, 520, 0, `<div style="padding:9px 12px">${nemesisHtml()}</div>`, 'nemb');
  // roster, left
  pane(12, 58, 252, 0, `<div style="padding:8px 4px 6px"><div class="row" style="padding:0 8px 6px"><span class="caps grow" style="color:var(--gilt)">Your fleet</span><span class="s12 dim3 num">${FLEET.length} ships</span></div>${rosterRows({ cap: N > 12 ? 'sel' : 'all', pad: N > 12 ? 2 : 6 })}</div>`, '', null).style.maxHeight = '792px';
  // log, right margin, always present
  pane(1636, 58, 272, 790, `<div style="padding:10px 12px"><div class="row" style="margin-bottom:6px"><span class="caps grow">Battle log</span><span class="s12 dim3">${key('L')} full</span></div>${logLines()}</div>`);
  // dock
  const y = 860, h = 208;
  pane(12, y, 1896, h, `
    <div style="position:absolute;left:0;top:0;bottom:0;width:372px;padding:12px 14px;border-right:1px solid var(--line)">${shipHead()}
      <div class="row s13" style="margin-top:6px;gap:6px">${['Prow', 'Midships', 'Engines'].map((n, i) => `<div style="flex:1"><div class="s12 dim3">${n}</div>${hbar([1, 0.78, 0.92][i], 5)}</div>`).join('')}</div></div>
    <div style="position:absolute;left:372px;top:0;bottom:0;right:420px;padding:12px 16px">
      <div class="row" style="margin-bottom:10px"><span class="caps" style="color:var(--gilt)">Now</span>${stepsHtml()}<span class="grow"></span><span class="s14 dim">Target <span class="foe" style="font-weight:600">Hullbreaker wrecker</span> from the planned hex</span></div>
      <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:6px">${WEAPONS.map(w => weaponTile(w)).join('')}</div>
      <div class="row" style="margin-top:8px;gap:6px;flex-wrap:wrap">${ORDERS.map(o => orderBtn(o)).join('')}<span class="grow"></span><div class="btn lit">${key('C')}Command: Fire for effect</div></div>
    </div>
    <div style="position:absolute;right:0;top:0;bottom:0;width:420px;padding:12px 16px;border-left:1px solid var(--line);display:flex;flex-direction:column">
      <span class="caps">What happens next</span><div style="margin-top:6px">${nextHtml()}</div><span class="grow"></span>
      <div class="row" style="gap:8px"><div class="btn" style="height:44px">${key('Tab')}Next ship</div><div class="btn primary grow" style="height:44px;font-size:17px;justify-content:center">End ship ${key('Space')}</div></div>
    </div>`);
}

// ---------------------------------------------------------------- layout 2: Action Column (one right-hand column in decision order)
function layout2() {
  pane(0, 0, 1440, 40, `<div class="row" style="height:38px;padding:0 12px;gap:12px">
    ${CREST_OWN.replace('class="crest"', 'class="crest sm"')}<span class="big-round" style="font-size:18px">ROUND 3</span><span class="caps" style="color:var(--gilt)">Your turn</span>${track()}
    <span class="s13 dim"><span class="num">${ACTED}</span>/${FLEET.length} acted &middot; then enemy</span><span class="grow"></span>
    <span class="s13 gilt">Break their fleet</span><span style="width:1px;height:18px;background:var(--line)"></span>${CREST_FOE.replace('crest sm', 'crest sm')}<span class="s13">Ashfall Hullbreakers</span>
    <span style="width:1px;height:18px;background:var(--line)"></span><span class="caps">Heat</span><span class="num ember">3</span>
    <span style="width:1px;height:18px;background:var(--line)"></span>
    <div class="btn ico" style="height:28px">Z</div><div class="btn ico" style="height:28px">R</div><div class="btn ico" style="height:28px">T</div><div class="btn" style="height:28px">1x</div><div class="btn" style="height:28px">${key('Esc')}Menu</div></div>`, 'flat');
  // roster, slim left rail
  pane(12, 52, 226, 0, `<div style="padding:8px 2px 6px"><div class="row" style="padding:0 8px 6px"><span class="caps grow" style="color:var(--gilt)">Fleet</span><span class="s12 dim3 num">${FLEET.length}</span></div>${rosterRows({ cap: 'sel', pad: N > 10 ? 3 : 5 })}</div>`);
  // log ticker, bottom left, always present
  pane(12, 928, 620, 140, `<div style="padding:8px 12px"><div class="row" style="margin-bottom:3px"><span class="caps grow">Log</span><span class="s12 dim3">${key('L')} open the full log</span></div>${logLines(LOG.slice(-4))}</div>`);
  // the column: one stack in decision order, the commit button pinned to the bottom corner
  const x = 1452, w = 456;
  const col = $(`<div style="position:absolute;left:${x}px;top:12px;width:${w}px;height:1056px;display:flex;flex-direction:column;gap:10px"></div>`);
  ui.appendChild(col);
  pane(0, 0, w, 0, `<div style="padding:10px 12px">${nemesisHtml()}</div>`, 'nemb', col);
  pane(0, 0, w, 0, `<div style="padding:10px 14px">${shipHead()}</div>`, '', col);
  pane(0, 0, w, 0, `<div style="padding:10px 14px">
    <div class="row"><span class="caps grow" style="color:var(--gilt)">1 Move</span><span class="s14">3 of 3 hexes left</span></div>
    <div class="s13 dim" style="margin-top:3px">Click a hex to plan; click again or Enter to go. Q / E turn.</div>
    <div class="rule"></div>
    <div class="row"><span class="caps grow" style="color:var(--bone)">2 Fire</span><span class="s14 dim">at <span class="foe" style="font-weight:600">Hullbreaker wrecker</span></span></div>
    <div style="display:grid;gap:5px;margin-top:6px">${WEAPONS.map(w => weaponTile(w)).join('')}</div>
    <div class="rule"></div>
    <div class="row"><span class="caps grow" style="color:var(--bone)">Orders</span><div class="btn lit" style="height:26px">${key('C')}Command: Fire for effect</div></div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:5px;margin-top:6px">${ORDERS.map(o => orderBtn(o)).join('')}</div>
  </div>`, '', col);
  pane(0, 0, w, 0, `<div style="padding:10px 14px"><div class="row"><span class="caps grow">Target</span><span class="tag foe">Enemy</span></div>
    <div class="row" style="margin-top:4px"><span class="foe grow" style="font-weight:600;font-size:16px">Hullbreaker wrecker</span><span class="num s14">88<span class="dim3">/160</span></span></div>
    <div style="margin-top:4px">${hbar(0.55)}${sbar([0, 18, 18, 18], 18)}</div>
    <div class="s14" style="margin-top:6px">Both bearing guns: about <span class="gilt num">31</span> damage. <span class="dim">Its prow shield is down, so every hit lands on hull.</span></div></div>`, '', col);
  pane(0, 0, w, 0, `<div style="padding:10px 14px"><span class="caps">3 End, and what happens next</span><div style="margin-top:5px">${nextHtml()}</div>
    <div class="row" style="gap:8px;margin-top:12px"><div class="btn" style="height:46px">${key('Tab')}Next ship</div><div class="btn primary grow" style="height:46px;font-size:17px;justify-content:center">End ship ${key('Space')}</div></div></div>`, '', col).style.marginTop = 'auto';
}

// ---------------------------------------------------------------- layout 3: Chart Frame (ruled margins, order card on the ship)
function layout3() {
  // top margin: initiative strip
  const order = FLEET.filter(s => s.st !== 'Done' && s.st !== 'Braced');
  const shown = order.slice(0, 6), extra = order.length - shown.length;
  const chips = shown.map((s, i) => `<div style="padding:2px 7px;border:1px solid ${i === 0 ? 'var(--gilt)' : 'rgba(143,240,160,0.4)'};${i === 0 ? 'background:rgba(77,61,26,0.6);' : ''}font-size:13px;font-weight:600;color:${i === 0 ? 'var(--gilt)' : 'var(--friend)'};white-space:nowrap">${i === 0 ? '&#9733; ' : ''}${s.n}</div>`).join('') + (extra > 0 ? `<div class="s13 dim" style="padding:2px 6px;border:1px solid var(--line)">+${extra} more</div>` : '');
  pane(0, 0, 1920, 56, `<div class="row" style="height:54px;padding:0 14px;gap:12px">
    ${CREST_OWN}<div style="line-height:1.05"><div class="big-round" style="font-size:20px">ROUND 3</div><div class="caps" style="color:var(--gilt)">Your turn</div></div>
    <span style="width:1px;height:32px;background:var(--line)"></span>
    <span class="caps">Order</span><div class="row" style="gap:3px">${chips}</div>
    <span class="dim3">&#8250;</span><div style="padding:2px 8px;border:1px solid var(--foe-ring);color:#e2d2ff;font-size:13px;font-weight:600;background:rgba(40,14,70,0.55)">Enemy turn &middot; 10</div>
    <span class="dim3">&#8250;</span><span class="s13 dim">Round 4</span>
    <span class="grow"></span>
    <span class="caps">Heat</span><span class="num ember s17">3</span><span style="width:1px;height:28px;background:var(--line)"></span>
    <div class="btn">${key('Z')}Grid</div><div class="btn">${key('R')}Threat</div><div class="btn">${key('T')}Top</div><div class="btn">Speed 1x</div><div class="btn">${key('Esc')}Menu</div></div>`, 'flat');
  // left margin: roster as a ruled table
  pane(0, 56, 300, 1024, `<div style="padding:10px 6px">
    <div class="row" style="padding:0 6px 4px"><span class="caps grow" style="color:var(--gilt)">Your fleet</span><span class="s12 dim3 num">${ACTED}/${FLEET.length} acted</span></div>
    <div class="row caps" style="padding:0 8px 4px;font-size:12px;border-bottom:1px solid var(--line)"><span class="grow">Ship</span><span style="width:46px;text-align:right">Hull</span><span style="width:48px;text-align:right">State</span></div>
    ${FLEET.map(s => { const f = s.hp / s.mx, up = s.st === 'Up', done = s.st === 'Done' || s.st === 'Braced';
      return `<div style="padding:${N > 10 ? 3 : 5}px 8px;border-bottom:1px solid rgba(230,220,196,0.06);${up ? 'background:rgba(77,61,26,0.45);box-shadow:inset 2px 0 0 var(--gilt);' : ''}${done ? 'opacity:0.55;' : ''}">
        <div class="row"><span class="grow ell" style="font-weight:600">${star(s)}${s.n}</span><span class="num s13" style="width:46px;text-align:right;color:${f < 0.35 ? 'var(--hull-low)' : 'var(--bone)'}">${Math.round(f * 100)}%</span><span class="s13 ${up ? 'gilt' : s.st === 'Ready' ? 'verd' : 'dim3'}" style="width:48px;text-align:right;font-weight:600">${s.st}</span></div>
        ${N > 10 && !up ? '' : `<div class="s12 dim ell">${s.c} &middot; ${s.cap}</div>`}
        <div style="margin-top:3px">${hbar(f)}${sbar(s.sh, s.sm)}</div></div>`; }).join('')}
  </div>`, 'flat');
  // right margin: Nemesis dossier on top of the log
  pane(1620, 56, 300, 1024, `<div style="padding:10px 12px">
    <div class="nemb" style="padding:2px 0 8px 10px;margin-bottom:8px">${nemesisHtml({ small: true, stack: true })}
      <div class="row s12" style="margin-top:6px;gap:6px"><span class="dim3">His clock</span><span class="clock"><i class="f"></i><i class="f"></i><i class="f"></i><i class="f"></i></span><span class="dim">full: this is his fight</span></div></div>
    <div class="rule"></div>
    <div class="row" style="margin-bottom:4px"><span class="caps grow">Battle log</span><span class="s12 dim3">${key('L')}</span></div>${logLines()}
    <div class="rule"></div>
    <div class="row s13" style="gap:8px">${CREST_FOE}<span>Ashfall Hullbreakers</span><span class="grow"></span><span class="gilt">Break their fleet</span></div>
  </div>`, 'flat');
  // chart rulers along the field's edges (A to N, 1 to 12)
  const cols = 'ABCDEFGHJKLMN'.split(''); let rx = '';
  cols.forEach((c, i) => { const x = 300 + (i + 0.5) * (1320 / cols.length); rx += `<span style="position:absolute;left:${x}px;top:58px;transform:translateX(-50%)" class="s12 dim3 num">${c}</span><span style="position:absolute;left:${300 + i * (1320 / cols.length)}px;top:56px;width:1px;height:6px;background:var(--reg)"></span>`; });
  for (let i = 0; i < 12; i++) { const y = 76 + (i + 0.5) * (1004 / 12); rx += `<span style="position:absolute;left:1600px;top:${y - 8}px" class="s12 dim3 num">${i + 1}</span><span style="position:absolute;left:1614px;top:${76 + i * (1004 / 12)}px;width:6px;height:1px;background:var(--reg)"></span>`; }
  ui.appendChild($(`<div style="position:absolute;inset:0;pointer-events:none">${rx}</div>`));
  // the order card, docked beside the ship that is up, with a leader line
  const cx = 640, cy = 590, cw = 560;
  const [ax, ay] = T(451, 458); const sx = ax + 78, sy = ay + 14;
  ui.appendChild($(`<svg style="position:absolute;left:0;top:0" width="1920" height="1080"><polyline points="${sx},${sy} ${cx - 34},${cy + 30} ${cx},${cy + 30}" fill="none" stroke="#d0a64b" stroke-width="1.5" stroke-dasharray="${BOLD ? '0' : '4 3'}"/><circle cx="${sx}" cy="${sy}" r="3" fill="#d0a64b"/></svg>`));
  pane(cx, cy, cw, 0, `<div style="padding:10px 14px">
    <div class="row" style="align-items:flex-start"><div class="grow">${shipHead({ stats: false })}</div></div>
    <div class="row" style="margin-top:10px">${stepsHtml()}</div>
    <div class="s13 dim" style="margin-top:6px">Planned hex: 2 of 4 guns bear on <span class="foe" style="font-weight:600">Hullbreaker wrecker</span>. Click again or Enter to move.</div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:5px;margin-top:8px">${WEAPONS.map(w => weaponTile(w)).join('')}</div>
    <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:5px;margin-top:6px">${ORDERS.map(o => orderBtn(o)).join('')}</div>
    <div class="rule"></div>
    <div class="row" style="align-items:flex-end;gap:10px"><div class="grow">${nextHtml()}</div></div>
  </div>`);
  // fixed commit corner, bottom right of the field
  pane(1330, 1000, 280, 68, `<div class="row" style="height:66px;padding:0 10px;gap:8px"><div class="btn" style="height:46px">${key('Tab')}Next</div><div class="btn primary grow" style="height:46px;font-size:17px;justify-content:center">End ship ${key('Space')}</div></div>`);
  pane(1330, 950, 280, 40, `<div class="row" style="height:38px;padding:0 10px;gap:8px"><div class="btn lit grow" style="height:28px">${key('C')}Command: Fire for effect</div></div>`);
}

plates();
({ 1: layout1, 2: layout2, 3: layout3 })[L]();
