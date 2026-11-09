// #271 identity round: mock2.js (round 2, branch opus/issue-271-r2) fixed to C Glass Shell bold, with the board colours read
// from the identity's CSS variables. Query: ?id=1|2|3 (identity), &n=20 for the 20-ship fleet.
// Battle screen mockups for issue #271, round 2: mockup 2B (Action Column) revised by Muse #292's numbered changes.
// Query: ?v=A|B|C&m=r|b&n=10|20   (variant, material restrained or bold, fleet size)
// A Solid Slab: threat as contour lines, unacted option (a), one solid column.
// B Glass Cards: threat as a tint by count, unacted set (b-set) in roster order, separate glass panes.
// C Glass Shell: threat as hatching by count, unacted set (b-set) led by the ships in reach, glass shell with solid text wells.
const Q = new URLSearchParams(location.search);
const VAR = 'C';  // identity round: C bold only
const ID = Q.get('id') || '1';
const BOLD = true;
const N = parseInt(Q.get('n') || '10', 10);
document.body.classList.add(BOLD ? 'bold' : 'restrained', 'v' + VAR, 'id' + ID);
const CS = getComputedStyle(document.body);
const cv = (n) => CS.getPropertyValue(n).trim();
if (N > 10) document.body.classList.add('n20');

// ---------------------------------------------------------------- data (a Nemesis fight, round 3, your turn, Move step)
const FLEET = [
  { n: 'Long Watch', flag: true, c: 'Daybreak dreadnought', cap: 'Lt. Lucan Wyndham', hp: 312, mx: 370, sh: [24, 32, 18, 32], sm: 32, st: 'Up', dz: 1 },
  { n: 'Debt Paid', c: 'Battleship', cap: 'Cmdr. Ilse Varga', hp: 288, mx: 340, sh: [30, 30, 30, 22], sm: 30, st: 'Ready' },
  { n: 'Oath Flame', c: 'Cruiser', cap: 'Capt. Odile Salo', hp: 96, mx: 160, sh: [12, 20, 20, 20], sm: 20, st: 'Ready' },
  { n: 'Resolve of the Reach', c: 'Carrier', cap: 'Capt. Brann Hollis', hp: 190, mx: 220, sh: [20, 20, 20, 20], sm: 20, st: 'Ready' },
  { n: 'Unyielding Oath', c: 'Destroyer', cap: 'Lt. Mara Kest', hp: 31, mx: 110, sh: [0, 6, 0, 0], sm: 14, st: 'Ready', dz: 3 },
  { n: 'Vigilant Ash', c: 'Destroyer', cap: 'Lt. Corin Dahl', hp: 110, mx: 110, sh: [14, 14, 14, 14], sm: 14, st: 'Done', dz: 1 },
  { n: 'Ashen Vigil', c: 'Frigate', cap: 'Ens. Tamsin Reed', hp: 64, mx: 70, sh: [10, 10, 4, 10], sm: 10, st: 'Done', dz: 2 },
  { n: 'Debt of Vesper', c: 'Frigate', cap: 'Ens. Pell Arno', hp: 70, mx: 70, sh: [10, 10, 10, 10], sm: 10, st: 'Ready' },
  { n: 'Merciless Frost', c: 'Frigate', cap: 'Lt. Hesk Moran', hp: 22, mx: 70, sh: [0, 0, 0, 3], sm: 10, st: 'Braced' },
  { n: 'Dawn of Cinders', c: 'Frigate', cap: 'Ens. Ada Quill', hp: 58, mx: 70, sh: [10, 10, 10, 10], sm: 10, st: 'Done' },
];
const MORE = [['Ember Tithe', 'Cruiser'], ['Gilded Penance', 'Destroyer'], ['Ninth Lantern', 'Frigate'], ['Sworn Kindling', 'Frigate'],
  ['Pale Vow', 'Destroyer'], ['Hearth of Ruin', 'Battleship'], ['Last Matins', 'Frigate'], ['Cinder Psalm', 'Frigate'],
  ['Unbroken Dusk', 'Cruiser'], ['Witness of Ash', 'Frigate']];
if (N > 10) MORE.slice(0, N - 10).forEach(([n, c], i) => FLEET.push({ n, c, cap: '',
  hp: [80, 60, 44, 70, 100, 300, 18, 66, 150, 52][i], mx: [160, 110, 70, 70, 110, 340, 70, 70, 160, 70][i], sh: [10, 10, 10, 10], sm: 10,
  st: i % 3 ? 'Ready' : 'Done', dz: [0, 2, 0, 0, 1, 0, 3, 0, 0, 0][i] }));
const ACTED = FLEET.filter(s => s.st === 'Done' || s.st === 'Braced').length;
const READY = FLEET.filter(s => s.st === 'Ready');
const NEXT = READY[0];

const WEAPONS = [
  { k: 1, n: 'Heavy sear broadside', tok: 'P 1-5', why: 'no enemy in arc' },
  { k: 2, n: 'Heavy sear broadside', tok: 'S 1-5', hit: 64, exp: 22, armed: true },
  { k: 3, n: 'Sear turret', tok: 'T 1-5', hit: 58, exp: 9 },
  { k: 4, n: 'Spark flak', tok: 'T 1-2', why: 'wings only' },
];
const ORDERS = [
  { k: 'B', n: 'Brace' }, { k: '5', n: 'Spinal cannon', lit: true, cd: 'ready' }, { k: 'X', n: 'Ram', off: true },
  { k: 'G', n: 'Board', off: true }, { k: 'Q', n: 'Turn left' }, { k: 'E', n: 'Turn right' },
];
const LOG = [
  ['R3', 's', 'Admiral Vex: "Hold the line. Let them come to the broadsides."'],
  ['R3', 'x', 'Merciless Frost braced.'],
  ['R3', 'p', 'Ashen Vigil hit Hullbreaker raider: 18 damage. The raider is crippled.'],
  ['R3', 'p', 'Vigilant Ash hit Hullbreaker raider: 12 damage.'],
];

// ---------------------------------------------------------------- the board: the capture's real hex grid (homography fitted to its lines)
// plane -> capture pixels (pointy-top axial hexes, unit circumradius), then the layout's camera framing (0.9 zoom, as in round 1's 2B)
const HM = [41.6106414, -25.2178207, 679.2071546, -0.1411667, 8.9050024, 697.3757004, -0.0002282, -0.0263421, 1.0];
const CAM = [0.9, 16, 52];
const S3 = Math.sqrt(3);
function capt(px, py) { const w = HM[6] * px + HM[7] * py + HM[8]; return [(HM[0] * px + HM[1] * py + HM[2]) / w, (HM[3] * px + HM[4] * py + HM[5]) / w]; }
function scr(px, py) { const [x, y] = capt(px, py); return [CAM[1] + x * CAM[0], CAM[2] + y * CAM[0]]; }
const T = (x, y) => [Math.round(CAM[1] + x * CAM[0]), Math.round(CAM[2] + y * CAM[0])];
const pl = (q, r) => [S3 * (q + r / 2), 1.5 * r];
const CORN = [0, 1, 2, 3, 4, 5].map(i => [Math.cos((60 * i - 30) * Math.PI / 180), Math.sin((60 * i - 30) * Math.PI / 180)]);
const NB = [[1, 0], [0, 1], [-1, 1], [-1, 0], [0, -1], [1, -1]]; // neighbour across edge i (corner i to corner i+1)
const hdist = (a, b) => (Math.abs(a[0] - b[0]) + Math.abs(a[1] - b[1]) + Math.abs(a[0] + a[1] - b[0] - b[1])) / 2;
function hexPoly(q, r, k = 1) { const [cx, cy] = pl(q, r); return CORN.map(([a, b]) => scr(cx + a * k, cy + b * k)); }
function onBoard(q, r) { const [cx, cy] = pl(q, r); const [x, y] = capt(cx, cy); return y > 326 && y < 1075 && x > -40 && x < 1720; }

// enemy reach (move plus longest gun). The capture's fleets stand about 18 hexes apart, farther than any real reach, so these radii are
// stretched to put the bands where they would sit in a closing fight. The rules layer computes the real ones (battle_api threat_map).
const ENEMY = [[17, -10, 13], [16, -8, 16], [18, -8, 11], [16, -6, 12], [15, -5, 17], [13, -3, 14], [11, 0, 11]];
const HERE = [-2, -5], PLAN = [0, -5];
function danger(q, r) { return ENEMY.filter(([eq, er, R]) => hdist([q, r], [eq, er]) <= R).length; }
const HEXES = [];
for (let q = -30; q < 30; q++) for (let r = -16; r < 10; r++) if (onBoard(q, r)) HEXES.push({ q, r, d: danger(q, r) });
const D = {}; HEXES.forEach(h => D[h.q + ',' + h.r] = h.d);
const dAt = (q, r) => D[q + ',' + r] ?? 0;

// ---------------------------------------------------------------- builders
const $ = (h) => { const t = document.createElement('template'); t.innerHTML = h.trim(); return t.content.firstChild; };
const ui = document.getElementById('ui');
function pane(x, y, w, h, inner, cls = '', parent = null) {
  const el = $(`<div class="pane ${cls}" style="${parent ? 'position:relative;' : `left:${x}px;top:${y}px;`}width:${w}px;${h ? `height:${h}px;` : ''}"></div>`);
  el.innerHTML = inner + '<i class="reg tr"></i><i class="reg bl"></i>';
  (parent || ui).appendChild(el); return el;
}
function hbar(f, segs = 10, ghost = null) {
  let s = ''; for (let i = 0; i < segs; i++) {
    const p = Math.max(0, Math.min(1, f * segs - i)); let g = '';
    if (ghost != null) { const a = Math.max(0, Math.min(1, ghost * segs - i)); if (p > a) g = `<u style="left:${a * 100}%;width:${(p - a) * 100}%"></u>`; }
    s += `<i><b style="width:${(ghost != null ? Math.min(p, Math.max(0, Math.min(1, ghost * segs - i))) : p) * 100}%"></b>${g}</i>`;
  }
  return `<div class="hbar ${f < 0.35 ? 'low' : ''}">${s}</div>`;
}
function sbar(sh, mx, ghost = null, h = null) {
  return `<div class="sbar" ${h ? `style="height:${h}px"` : ''}>${sh.map((v, i) => { const f = Math.max(0, Math.min(1, v / mx));
    const gf = ghost && ghost[i] != null ? ghost[i] / mx : null;
    return gf != null && gf < f ? `<i><b style="width:${gf * 100}%"></b><u style="left:${gf * 100}%;width:${(f - gf) * 100}%"></u></i>` : `<i><b style="width:${f * 100}%"></b></i>`; }).join('')}</div>`;
}
const star = (s) => s.flag ? '&#9733; ' : '';
const key = (k) => `<span class="key">${k}</span>`;
const RET = '<svg viewBox="0 0 10 10"><circle cx="5" cy="5" r="3.6" fill="none" stroke="currentColor" stroke-width="1.3"/><path d="M5 0v3M5 7v3M0 5h3M7 5h3" stroke="currentColor" stroke-width="1.3"/></svg>';
const dng = (n) => `<span class="dng" title="enemies that can reach">${RET}${n}</span>`;
function track() {
  let s = ''; FLEET.forEach(f => { s += `<i class="${f.st === 'Up' ? 'u' : (f.st === 'Done' || f.st === 'Braced') ? 'd' : ''}"></i>`; });
  s += '<span class="sep"></span>'; for (let i = 0; i < 10; i++) s += '<i class="e"></i>';
  return `<div class="track">${s}</div>`;
}
function heatGauge() { let s = ''; for (let i = 0; i < 9; i++) s += `<i class="${i < 3 ? 'f' : ''}"></i>`;
  return `<span class="heat"><span class="caps kword">Heat</span><span class="seg">${s}</span><span class="num ember s14">3</span></span>`; }

// ---------------------------------------------------------------- the board overlay: threat (passive), then the move preview above it
const ENEMY_PLATES = [
  { n: 'Hullbreaker raider', x: 1369, y: 380, hp: 0.3 }, { n: 'Hullbreaker gutship', x: 1390, y: 424, hp: 0.8 },
  { n: 'Hullbreaker wrecker', x: 1512, y: 424, hp: 0.55, tgt: true },
  { n: "Warlord's Pyre-Barge", x: 1489, y: 464, flag: true, nem: true, hp: 0.9 },
  { n: 'Bomber wing (Pyre-Barge)', x: 1477, y: 518, wing: true }, { n: 'Hullbreaker raider', x: 1442, y: 574, hp: 1 },
  { n: 'Hullbreaker gutship', x: 1482, y: 652, hp: 0.95 },
];
const OWN_PLATES = [
  { n: 'Debt of Vesper', x: 511, y: 380 }, { n: 'Oath Flame', x: 488, y: 422 },
  { n: 'Long Watch', x: 451, y: 458, up: true, flag: true }, { n: 'Resolve of the Reach', x: 336, y: 502 },
  { n: 'Debt Paid', x: 409, y: 530 }, { n: 'Merciless Frost', x: 372, y: 612 },
  { n: 'Bomber wing (Resolve of the Reach)', x: 717, y: 518, wing: true }, { n: 'Fighter wing (Resolve of the Reach)', x: 740, y: 552, wing: true },
];
const P2 = (pts) => pts.map(p => p[0].toFixed(1) + ',' + p[1].toFixed(1)).join(' ');
function threatSvg() {
  const FOE = cv('--board-foe'), FOE2 = cv('--board-foe2');
  let defs = '', g = '';
  const glow = BOLD ? 'filter="url(#gl)"' : '';
  defs += `<filter id="gl" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="2.2" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>`;
  // band boundary edges for each level k: edges between a hex at >=k and a neighbour below k (or off the board)
  const edges = (k) => { const out = []; HEXES.forEach(h => { if (h.d < k) return; const poly = hexPoly(h.q, h.r);
    NB.forEach(([dq, dr], i) => { const nq = h.q + dq, nr = h.r + dr; const nd = (D[nq + ',' + nr] ?? -1); if (nd >= k || nd === -1) return; out.push([poly[i], poly[(i + 1) % 6]]); }); }); return out; };
  const path = (es) => es.map(([a, b]) => `M${a[0].toFixed(1)} ${a[1].toFixed(1)}L${b[0].toFixed(1)} ${b[1].toFixed(1)}`).join('');
  if (VAR === 'A') {
    // contour lines: a dashed line where reach begins, solid at two, double at three or more; band numbers sit on the lines
    const op = BOLD ? 0.9 : 0.7;
    g += `<path d="${path(edges(1))}" stroke="${FOE2}" stroke-opacity="${op * 0.8}" stroke-width="1.4" stroke-dasharray="5 4" fill="none" ${glow}/>`;
    g += `<path d="${path(edges(2))}" stroke="${FOE}" stroke-opacity="${op}" stroke-width="1.6" fill="none" ${glow}/>`;
    const e3 = path(edges(3));
    g += `<path d="${e3}" stroke="${FOE}" stroke-opacity="${op}" stroke-width="4.4" fill="none" ${glow}/><path d="${e3}" stroke="#0b0f1a" stroke-width="1.6" fill="none"/>`;
    [1, 2, 3].forEach(k => { // label each band once, on its boundary edge nearest a spot low in the open field
      const es = edges(k).filter(([a, b]) => (a[0] + b[0]) / 2 > 560 && (a[0] + b[0]) / 2 < 1300); if (!es.length) return;
      let best = es[0], bd = 1e9; es.forEach(e => { const mx = (e[0][0] + e[1][0]) / 2, my = (e[0][1] + e[1][1]) / 2; const dd = Math.abs(my - 740) * 2 + Math.abs(mx - 900) * 0.05; if (dd < bd) { bd = dd; best = e; } });
      const mx = (best[0][0] + best[1][0]) / 2, my = (best[0][1] + best[1][1]) / 2;
      g += `<g transform="translate(${mx.toFixed(1)},${my.toFixed(1)})"><rect x="-9" y="-9" width="18" height="18" fill="#0b0f1a" stroke="${FOE}" stroke-width="1"/><text x="0" y="4.5" text-anchor="middle" font-family="Oxanium" font-weight="700" font-size="13" fill="#e2d2ff">${k === 3 ? '3+' : k}</text></g>`;
    });
  } else if (VAR === 'B') {
    // tint: lavender fill whose strength steps with how many enemies can reach; the 3+ band gets an edge line as its second channel
    const al = BOLD ? [0, 0.06, 0.11, 0.17] : [0, 0.05, 0.09, 0.14];
    HEXES.forEach(h => { if (!h.d) return; g += `<polygon points="${P2(hexPoly(h.q, h.r, 0.97))}" fill="${FOE}" fill-opacity="${al[Math.min(3, h.d)]}"/>`; });
    g += `<path d="${path(edges(1))}" stroke="${FOE2}" stroke-opacity="0.45" stroke-width="1" fill="none"/>`;
    g += `<path d="${path(edges(3))}" stroke="${FOE}" stroke-opacity="${BOLD ? 0.95 : 0.75}" stroke-width="2" fill="none" ${glow}/>`;
  } else {
    // hatching: sparse lines for one enemy, dense for two, cross-hatch for three or more (count carried by pattern, not colour)
    const st = BOLD ? 0.42 : 0.34;
    defs += `<pattern id="h1" width="11" height="11" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><line x1="0" y1="0" x2="0" y2="11" stroke="${FOE2}" stroke-opacity="${st}" stroke-width="1.2"/></pattern>`;
    defs += `<pattern id="h2" width="5.5" height="5.5" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><line x1="0" y1="0" x2="0" y2="5.5" stroke="${FOE2}" stroke-opacity="${st}" stroke-width="1.2"/></pattern>`;
    defs += `<pattern id="h3" width="5.5" height="5.5" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><line x1="0" y1="0" x2="0" y2="5.5" stroke="${FOE}" stroke-opacity="${st + 0.1}" stroke-width="1.1"/><line x1="0" y1="0" x2="5.5" y2="0" stroke="${FOE}" stroke-opacity="${st + 0.1}" stroke-width="1.1"/></pattern>`;
    HEXES.forEach(h => { if (!h.d) return; g += `<polygon points="${P2(hexPoly(h.q, h.r, 0.98))}" fill="url(#h${Math.min(3, h.d)})"/>`; });
    g += `<path d="${path(edges(1))}" stroke="${FOE2}" stroke-opacity="0.55" stroke-width="1" fill="none"/>`;
  }
  return { defs, g };
}
// arcs: a wedge on the board plane (the rules' 120 degree cones), drawn through the same projection as the hexes
function wedge(q, r, faceDeg, a0, a1, R) {
  const [cx, cy] = pl(q, r); const pts = [scr(cx, cy)];
  for (let a = a0; a <= a1 + 0.01; a += 6) { const t = (faceDeg + a) * Math.PI / 180; pts.push(scr(cx + R * Math.cos(t), cy + R * Math.sin(t))); }
  return P2(pts);
}
function moveSvg() {
  // Long Watch faces east now (0 deg); the hovered hex is 2 east, then one turn left to face north-east (-60 deg)
  const R = 5 * S3, AMB = '#f0b35a', TEAL = '#5fb3a6', GILT = cv('--board-accent');
  const glow = BOLD ? 'filter="url(#gl)"' : '';
  let g = '';
  // current position, first and faint: prow amber, broadsides teal (the game's own arc colours), outline only
  g += `<polygon points="${wedge(HERE[0], HERE[1], 0, -60, 60, R)}" fill="none" stroke="${AMB}" stroke-opacity="0.45" stroke-width="1.2" stroke-dasharray="3 4"/>`;
  g += `<polygon points="${wedge(HERE[0], HERE[1], 0, 60, 180, R)}" fill="none" stroke="${TEAL}" stroke-opacity="0.38" stroke-width="1.2" stroke-dasharray="3 4"/>`;
  g += `<polygon points="${wedge(HERE[0], HERE[1], 0, -180, -60, R)}" fill="none" stroke="${TEAL}" stroke-opacity="0.38" stroke-width="1.2" stroke-dasharray="3 4"/>`;
  // hovered destination, second and stronger: starboard cone (the one that bears) filled lightly
  g += `<polygon points="${wedge(PLAN[0], PLAN[1], -60, -60, 60, R)}" fill="${AMB}" fill-opacity="0.05" stroke="${AMB}" stroke-opacity="0.85" stroke-width="1.6" ${glow}/>`;
  g += `<polygon points="${wedge(PLAN[0], PLAN[1], -60, 60, 180, R)}" fill="${TEAL}" fill-opacity="0.10" stroke="${TEAL}" stroke-opacity="0.95" stroke-width="1.8" ${glow}/>`;
  g += `<polygon points="${wedge(PLAN[0], PLAN[1], -60, -180, -60, R)}" fill="none" stroke="${TEAL}" stroke-opacity="0.55" stroke-width="1.2"/>`;
  // path and destination hex
  const path = [HERE, [-1, -5], PLAN].map(([q, r]) => scr(...pl(q, r)));
  g += `<polyline points="${P2(path)}" fill="none" stroke="${GILT}" stroke-width="2" stroke-dasharray="6 4" ${glow}/>`;
  path.slice(1, 2).forEach(([x, y]) => g += `<circle cx="${x}" cy="${y}" r="3" fill="${GILT}"/>`);
  g += `<polygon points="${P2(hexPoly(PLAN[0], PLAN[1], 0.94))}" fill="${GILT}" fill-opacity="0.16" stroke="${GILT}" stroke-width="2" ${glow}/>`;
  // ghost hull marker: a chevron at the destination pointing along the new facing
  const [cx, cy] = pl(PLAN[0], PLAN[1]); const f = -60 * Math.PI / 180;
  const tip = scr(cx + 0.75 * Math.cos(f), cy + 0.75 * Math.sin(f));
  const l = scr(cx + 0.55 * Math.cos(f + 2.4), cy + 0.55 * Math.sin(f + 2.4)), rr = scr(cx + 0.55 * Math.cos(f - 2.4), cy + 0.55 * Math.sin(f - 2.4));
  const c0 = scr(cx + 0.2 * Math.cos(f + Math.PI), cy + 0.2 * Math.sin(f + Math.PI));
  g += `<polygon points="${P2([tip, l, c0, rr])}" fill="${GILT}" stroke="${cv('--on-gilt')}" stroke-width="1"/>`;
  return g;
}
function boardOverlay() {
  const t = threatSvg();
  const svg = $(`<svg style="position:absolute;left:0;top:0" width="1920" height="1080"><defs>${t.defs}</defs><g>${t.g}</g><g>${moveSvg()}</g></svg>`);
  ui.appendChild(svg);
  // cursor on the hovered hex, and the hex's own reach badge (threat lives on the board, change 17)
  const [hx, hy] = scr(...pl(PLAN[0], PLAN[1]));
  ui.appendChild($(`<svg style="position:absolute;left:${hx + 6}px;top:${hy + 4}px" width="22" height="26"><path d="M1 1 L1 19 L6 14.5 L9.5 22 L12.5 20.6 L9 13.3 L15.5 13.3 Z" fill="#f4efe2" stroke="#0b0f1a" stroke-width="1.4"/></svg>`));
  const d = dAt(PLAN[0], PLAN[1]);
  ui.appendChild($(`<div class="hexbadge" style="left:${hx + 22}px;top:${hy + 82}px">${dng(d)}<span>${d} enemies can reach this hex</span><span class="dim3">now ${dAt(HERE[0], HERE[1])}</span></div>`));
  ui.appendChild($(`<div class="movebadge" style="left:${hx + 22}px;top:${hy + 54}px"><span class="gilt" style="font-weight:600">2 hexes, turn to NE</span> <span class="dim">&middot; 2 of 4 guns bear</span></div>`));
}
function plates() {
  ENEMY_PLATES.forEach(p => {
    const sh = [0, 1, 1, 1]; const [px, py] = T(p.x, p.y);
    const cls = ['plate', 'e', p.tgt ? 'tgt' : '', p.nem ? 'nem' : ''].join(' ');
    const el = $(`<div class="${cls}" style="left:${px}px;top:${py}px"></div>`);
    const bars = p.wing ? '' : (p.tgt ? hbar(0.55, 8, 0.47) + sbar([0, 18, 18, 18], 18, [null, null, null, 0]) : hbar(p.hp, 8) + sbar(sh, 1));
    el.innerHTML = `${p.nem ? '<span class="tag nem nemtag">Nemesis</span>' : ''}<div class="pn">${p.flag ? '&#9733; ' : ''}${p.n}</div>${bars}${p.tgt ? '<span class="odds">64%  2 guns</span>' : ''}`;
    ui.appendChild(el);
  });
  OWN_PLATES.forEach(p => {
    const f = FLEET.find(s => s.n === p.n); const hp = f ? f.hp / f.mx : 1; const sh = f ? f.sh.map(v => v / f.sm) : [1, 1, 1, 1];
    const [px, py] = T(p.x, p.y);
    const el = $(`<div class="plate ${p.up ? 'sel' : ''}" style="left:${px}px;top:${py}px"></div>`);
    el.innerHTML = `<div class="pn">${p.up ? '<span class="tag up" style="height:15px;margin-right:5px">Up</span>' : ''}${p.flag ? '&#9733; ' : ''}${p.n}</div>` + (p.wing ? '' : hbar(hp, 8) + sbar(sh, 1));
    ui.appendChild(el);
  });
}

// ---------------------------------------------------------------- panels
function rosterRows() {
  const tight = N > 10;
  return FLEET.map(s => {
    const f = s.hp / s.mx, up = s.st === 'Up', done = s.st === 'Done' || s.st === 'Braced';
    const stc = up ? 'gilt' : s.st === 'Ready' ? 'verd' : 'dim3';
    return `<div class="rr" style="padding:${tight ? 3 : 5}px 8px;${up ? 'background:var(--up-bg);outline:1px solid var(--gilt);outline-offset:-1px;' : ''}${done ? 'opacity:0.55;' : ''}">
      <div class="row" style="gap:6px"><span class="grow ell" style="font-weight:600;font-size:15px">${star(s)}${s.n}</span>${f < 0.35 ? '<span class="lowtag">LOW</span>' : ''}${s.dz ? dng(s.dz) : ''}<span class="s13 ${stc}" style="font-weight:600;${s.st === 'Braced' ? '' : ''}">${s.st}</span></div>
      ${up && !tight ? `<div class="s13 dim ell">${s.cap}</div>` : ''}
      <div style="margin-top:${tight ? 2 : 4}px">${hbar(f)}${sbar(s.sh, s.sm)}</div></div>`;
  }).join('');
}
function logLines(list = LOG) { return `<div class="log">${list.map(([r, c, t]) => `<div class="ln"><span class="r">${r}</span><span class="${c}">${t}</span></div>`).join('')}</div>`; }
function weaponRows(hov = false) {
  return `<div class="wtab hd"><span></span><span>Weapon</span><span style="text-align:center">Arc</span><span style="text-align:right">Hit</span><span style="text-align:right">Dmg</span><span style="text-align:right">Cost</span></div>`
    + WEAPONS.map(w => `<div class="wtab wrow ${w.armed ? 'armed' : ''} ${w.hit ? '' : 'no'}">${key(w.k)}<span class="wn">${w.n}</span><span class="tok ${hov && w.k === 2 ? 'hov' : ''}">${w.tok}</span>`
      + (w.hit ? `<span class="hit">${w.hit}%</span><span class="exp">~${w.exp}</span>` : `<span class="why">${w.why}</span>`)
      + `<span class="cost">${w.cd ? `<span class="cd">CD ${w.cd}</span>` : 'free'}</span></div>`).join('');
}
function orderBtns() {
  return ORDERS.map(o => `<div class="btn ${o.off ? 'off' : ''} ${o.lit ? 'lit' : ''}" style="height:30px">${key(o.k)}<span class="grow">${o.n}</span>${o.cd ? `<span class="s12 dim3">${o.cd}</span>` : ''}</div>`).join('');
}
function nemesisHtml() {
  return `<div class="row" style="align-items:flex-start;gap:10px">
    <img class="portrait" src="nem.webp">
    <div class="grow">
      <div class="row"><span class="tag nem">Nemesis</span><span style="font-weight:600;font-size:16px">Warlord Skarn-Maw</span><span class="dim s13">the Uncaught</span></div>
      <div class="s13 dim" style="margin-top:3px">Aboard &#9733; Warlord's Pyre-Barge &middot; flees below 35% hull</div>
      <div class="s13" style="margin-top:5px"><span class="blood kword">Adapted</span>: enemy shields +20% <span class="dim3">(you leaned on lances)</span></div>
      <div class="s13"><span class="verd kword">Weakness</span>: rear-arc hits do +25% <span class="dim3">(thin stern plating)</span></div>
    </div></div>`;
}
function shipHtml() {
  const s = FLEET[0], f = s.hp / s.mx;
  return `<div class="row"><span class="tag up">Up</span><span class="h-ship ell grow">&#9733; ${s.n}</span>${dng(s.dz)}</div>
  <div class="s14 dim" style="margin-top:2px">${s.c} &middot; ${s.cap}</div>
  <div class="row" style="margin-top:8px"><span class="caps" style="width:44px">Hull</span><div class="grow">${hbar(f)}</div><span class="num s14">${s.hp}<span class="dim3">/${s.mx}</span></span></div>
  <div class="row" style="margin-top:5px"><span class="caps" style="width:44px">Shld</span><div class="grow" style="display:flex;gap:3px">${['Prow', 'Stbd', 'Rear', 'Port'].map((nm, i) => `<div style="flex:1"><div class="sbar" style="height:4px"><i><b style="width:${s.sh[i] / s.sm * 100}%"></b></i></div><div class="s12 dim3" style="margin-top:2px">${nm} <span class="num" style="color:var(--shield)">${s.sh[i]}</span></div></div>`).join('')}</div></div>
  <div class="row s14" style="margin-top:6px;gap:14px"><span><span class="dim3 kword">ARM</span> <span class="num">35%</span></span><span><span class="dim3">MOVE</span> <span class="num gilt">2/2</span></span><span><span class="dim3">TURNS</span> <span class="num">1</span></span><span class="grow"></span><span class="s12 dim3">more on hover</span></div>`;
}
function moveHtml() {
  return `<div class="row"><span class="caps grow" style="color:var(--gilt)">1 Move</span><span class="s14">2 of 2 hexes left</span></div>
    <div class="s14" style="margin-top:3px">Planned: <span class="gilt">2 east, turn to NE</span>. <span class="dim">Click again or Enter to go; Q / E turn.</span></div>`;
}
function fireHtml(hov) {
  return `<div class="row" style="margin-bottom:5px"><span class="caps grow" style="color:var(--bone)">2 Fire</span><span class="s14 dim">from the planned hex, at <span class="foe" style="font-weight:600">Hullbreaker wrecker</span></span></div>${weaponRows(hov)}`;
}
function ordersHtml() {
  return `<div class="row"><span class="caps grow" style="color:var(--bone)">Orders</span><div class="btn lit" style="height:26px">${key('C')}Command: Fire for effect</div></div>
    <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:5px;margin-top:7px">${orderBtns()}</div>`;
}
function targetHtml() {
  return `<div class="row"><span class="caps grow">Target</span><span class="s12 dim" style="margin-right:6px"><span class="ghostkey"></span> expected</span><span class="tag foe">Enemy</span></div>
    <div class="row" style="margin-top:4px"><span class="foe grow" style="font-weight:600;font-size:16px">Hullbreaker wrecker</span><span class="num s14">88<span class="dim3">/160</span> <span class="dim3">to about</span> 75</span></div>
    <div style="margin-top:5px">${hbar(0.55, 10, 0.47)}${sbar([0, 18, 18, 18], 18, [null, null, null, 0], 4)}</div>
    <div class="row s12 dim3" style="margin-top:2px"><span style="flex:1">Prow 0</span><span style="flex:1">Stbd 18</span><span style="flex:1">Rear 18</span><span style="flex:1">Port 18 <span class="dim">to about 0</span></span></div>
    <div class="s14" style="margin-top:5px">Both bearing guns: about <span class="gilt num">31</span> damage, about 18 on its port shield and 13 on hull.</div>`;
}
function endHtml() {
  const ready = READY.length;
  const counted = ready ? `<span class="verd" style="font-weight:600">${ready} ships still Ready</span>${VAR === 'C' ? ` <span class="dim">&middot;</span> ${key('Tab')} <span class="dim">jumps to the next</span>` : ''}` : '';
  return `<span class="caps">3 End, and what happens next</span>
    <div class="counted" style="margin-top:5px">${counted}</div>
    <div class="s14" style="line-height:1.4"><span class="dim3">Then</span> <span class="friend" style="font-weight:600">${NEXT.n}</span> is up <span class="dim3">(Tab)</span>. <span class="dim3">After your ships, the</span> <span class="foe" style="font-weight:600">enemy turn</span>: 10 ships.</div>
    <div class="row" style="gap:8px;margin-top:10px"><div class="btn" style="height:46px">${key('Tab')}Next ship</div><div class="btn primary grow" style="height:46px;font-size:17px;justify-content:center">End ship ${key('Space')}</div></div>`;
}

// ---------------------------------------------------------------- the layout (2B, revised)
function topBar() {
  pane(0, 0, 1440, 40, `<div class="row" style="height:38px;padding:0 12px;gap:12px">
    <img class="crest sm" src="faction_voidsworn.svg"><span class="big-round" style="font-size:18px">ROUND 3</span><span class="caps" style="color:var(--gilt)">Your turn</span>${track()}
    <span class="s13 dim"><span class="num">${ACTED}</span>/${FLEET.length} acted &middot; then enemy</span><span class="grow"></span>
    <span class="s13 gilt">Break their fleet</span><span style="width:1px;height:18px;background:var(--line)"></span><img class="crest sm" src="faction_corsair.svg"><span class="s13">Ashfall Hullbreakers</span>
    <span style="width:1px;height:18px;background:var(--line)"></span>${heatGauge()}
    <span style="width:1px;height:18px;background:var(--line)"></span>
    <div class="btn ico" style="height:28px">Z</div><div class="btn ico" style="height:28px">R</div><div class="btn ico" style="height:28px">T</div><div class="btn" style="height:28px">1x</div><div class="btn" style="height:28px">${key('Esc')}Menu</div></div>`, 'flat');
  if (VAR === 'C') { const tb = ui.lastChild; tb.firstChild.classList.add('wellin'); tb.firstChild.style.cssText += 'margin:3px;height:34px'; }
  if (VAR === 'A') return; // option (a): no set display; the End box's next-ship line carries it
  const un = READY.length;
  let names;
  if (VAR === 'B') names = READY.slice(0, 3).map(s => `<span class="chip">${star(s)}${s.n}</span>`);
  else names = READY.filter(s => s.dz).sort((a, b) => b.dz - a.dz).concat(READY.filter(s => !s.dz)).slice(0, 3).map(s => `<span class="chip">${s.n}${s.dz ? dng(s.dz) : ''}</span>`);
  const more = un - 3;
  pane(196, 44, 0, 0, `<div class="unacted"><span class="s13" style="font-weight:600"><span class="num">${un}</span> unacted</span>${VAR === 'C' ? '<span class="s12 dim3">in reach first:</span>' : ''}${names.join('')}${more > 0 ? `<span class="s13 dim">+${more}</span>` : ''}</div>`, 'flat lite').style.width = 'auto';
}
function roster() {
  const p = pane(12, VAR === 'A' ? 52 : 80, VAR === 'C' ? 240 : 226, 0, `<div style="padding:8px 2px 6px"><div class="row" style="padding:0 8px 6px"><span class="caps grow" style="color:var(--gilt)">Fleet</span><span class="s12 dim3 num">${FLEET.length}</span></div>${rosterRows()}</div>`);
  if (VAR === 'C') { p.classList.add('lite'); p.firstChild.classList.add('wellin'); p.firstChild.style.margin = '6px'; }
}
function ticker() {
  const p = pane(12, 928, 620, 140, `<div style="padding:8px 12px"><div class="row" style="margin-bottom:3px"><span class="caps grow">Log</span><span class="s12 dim3">${key('L')} open the full log</span></div>${logLines()}</div>`);
  if (VAR === 'C') { p.classList.add('lite'); p.style.padding = '6px'; p.firstChild.classList.add('wellin'); p.style.height = '140px'; p.firstChild.style.height = '126px'; }
}
function column() {
  const x = 1452, w = 456;
  const blocks = [
    { id: 'nem', html: nemesisHtml(), cls: 'nemb' }, { id: 'ship', html: shipHtml() }, { id: 'move', html: moveHtml() },
    { id: 'fire', html: fireHtml(false) }, { id: 'orders', html: ordersHtml() }, { id: 'target', html: targetHtml() }, { id: 'end', html: endHtml(), bottom: true },
  ];
  if (VAR === 'B') {
    // separate glass panes (round 1's construction); Move and Fire and Orders share one pane as in 2B
    const col = $(`<div style="position:absolute;left:${x}px;top:12px;width:${w}px;height:1056px;display:flex;flex-direction:column;gap:10px"></div>`); ui.appendChild(col);
    pane(0, 0, w, 0, `<div style="padding:10px 12px">${blocks[0].html}</div>`, 'nemb', col);
    pane(0, 0, w, 0, `<div style="padding:10px 14px">${blocks[1].html}</div>`, '', col);
    pane(0, 0, w, 0, `<div style="padding:10px 14px">${blocks[2].html}<div class="rule"></div>${blocks[3].html}<div class="rule"></div>${blocks[4].html}</div>`, '', col);
    pane(0, 0, w, 0, `<div style="padding:10px 14px">${blocks[5].html}</div>`, '', col);
    pane(0, 0, w, 0, `<div style="padding:10px 14px">${blocks[6].html}</div>`, '', col).style.marginTop = 'auto';
  } else if (VAR === 'A') {
    // one solid slab, full height, sections divided by rules; End pinned to the bottom
    const p = pane(x, 12, w, 1056, `<div style="display:flex;flex-direction:column;height:100%">${blocks.map(b => `<div class="sec ${b.cls || ''}" style="${b.bottom ? 'margin-top:auto;' : ''}${b.id === 'nem' ? 'border-left:3px solid var(--alert);' : ''}">${b.html}</div>`).join('')}</div>`, 'slab');
  } else {
    // glass shell, every block on its own solid well
    const p = pane(x, 12, w, 1056, `<div class="shell" style="height:100%">${blocks.map(b => `<div class="well ${b.cls || ''}" style="${b.bottom ? 'margin-top:auto;' : ''}">${b.html}</div>`).join('')}</div>`, 'shellp');
  }
}

if (Q.get('pieces')) { /* the close-up sheet builds its own page (pieces.js) */ } else {
  plates(); boardOverlay();
  // plates over the overlay: move them to the end so they draw above the threat and arcs
  [...ui.querySelectorAll('.plate')].forEach(p => ui.appendChild(p));
  [...ui.querySelectorAll('.hexbadge,.movebadge')].forEach(p => ui.appendChild(p));
  topBar(); roster(); ticker(); column();
}
