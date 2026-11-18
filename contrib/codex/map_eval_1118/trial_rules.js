// Read into the sim's private copy of battle.js. The game never loads this file.
function trialCol(h) { return h.q + Math.floor(h.r / 2); }

function trialFacing(u, target) {
  const x = Math.sqrt(3) * ((target.q - u.q) + (target.r - u.r) / 2);
  const y = 1.5 * (target.r - u.r);
  u.facing = (Math.round(Math.atan2(y, x) / (Math.PI / 3)) + 6) % 6;
}

function trialCenter(units) {
  return {
    q: units.reduce((sum, u) => sum + u.q, 0) / units.length,
    r: units.reduce((sum, u) => sum + u.r, 0) / units.length,
  };
}

// Pick an actual free board hex, never a clipped edge, rock or occupied cell.
function trialSpot(unit, score, facing) {
  const old = occMap();
  const cells = boardHexes().filter(h => !blocks(terr(h.q, h.r)) &&
    (!old.has(hkey(h.q, h.r)) || old.get(hkey(h.q, h.r)) === unit));
  let hex = null, best = -Infinity;
  for (const h of cells) {
    const value = score(h);
    if (value > best) { hex = h; best = value; }
  }
  if (!hex) throw Error('No deployment hex for ' + unit.name);
  Object.assign(unit, hex, {facing});
}

function trialHunt(player, enemy) {
  const bb = boardBounds();
  const row = bb.r0 + 1;
  const [quarry, ...escorts] = enemy.slice().sort((a, b) => b.t.cp - a.t.cp || b.maxHp - a.maxHp);
  for (const [i, u] of player.entries()) {
    const start = offToAx(bb.c0 + i % 2, bb.r1 - Math.floor(i / 2));
    trialSpot(u, h => -hdist(h, start) - 4 * (trialCol(h) - bb.c0), 0);
  }
  trialSpot(quarry, h => -4 * Math.abs(trialCol(h) - (bb.c1 - 1)) - 2 * Math.abs(h.r - row), 3);
  for (const [index, escort] of escorts.slice(0, 2).entries()) {
    const target = {q: quarry.q - 5, r: quarry.r + (index ? 2 : 0)};
    trialSpot(escort, h => {
      const d = hdist(h, quarry);
      return -25 * Math.max(0, 4 - d, d - 6) - 20 * Math.max(0, trialCol(h) - trialCol(quarry) + 3) - hdist(h, target);
    }, 3);
    escort.trialScreen = true;
  }
  for (const [i, escort] of escorts.slice(2).entries()) {
    const target = offToAx(bb.c1 - i % 2, row + 2 * Math.floor(i / 2));
    trialSpot(escort, h => -hdist(h, target) - 5 * Math.max(0, trialCol(quarry) - trialCol(h)), 3);
  }
  B.trialQuarry = quarry;
  B.trialExit = bb.c1;
  B.trialExitHex = boardHexes().filter(h => trialCol(h) === bb.c1 && !blocks(terr(h.q, h.r)))
    .sort((a, b) => hdist(a, quarry) - hdist(b, quarry))[0];
  for (const escort of escorts) escort.trialStation = {q: escort.q, r: escort.r};
}

// Keep the existing six-round jump. The edge is a bearing for the quarry's AI.
function trialHuntScore(u, v) {
  const quarry = B.trialQuarry;
  if (!quarry || quarry.dead) return 0;
  if (u === quarry) {
    const nearest = Math.min(30, ...caps('player').map(p => hdist(v, p)));
    return 3 * Math.min(nearest, 9) - 8 * hdist(v, B.trialExitHex);
  }
  // Hold the opening screen for two rounds. Weapons and turns remain legal.
  if (u.trialStation && B.round < 3) return -80 * hdist(v, u.trialStation);
  return 0;
}

function trialAmbush(enemy, player) {
  const bb = boardBounds();
  const mid = (bb.r0 + bb.r1) / 2;
  const ranked = enemy.slice().sort((a, b) => b.size - a.size);
  const fleet = trialCenter(player);
  for (const [index, u] of ranked.entries()) {
    const row = index % 2 ? bb.r1 - 1 : bb.r0 + 1;
    const col = 17 + 2 * Math.floor(index / 2);
    const bank = ranked.filter((v, j) => j < index && j % 2 === index % 2);
    trialSpot(u, h => {
      const wrongBank = index % 2 ? h.r < mid + 2 : h.r > mid - 2;
      const spacing = Math.min(2, ...bank.map(v => hdist(v, h)));
      return -30 * Number(wrongBank) + 3 * spacing - Math.abs(trialCol(h) - col) - 2 * Math.abs(h.r - row);
    }, 3);
    trialFacing(u, fleet);
  }
  const boss = ranked.find(u => u.t.boss);
  const bank = boss && ranked.filter(u => u !== boss && (u.r < mid) === (boss.r < mid));
  if (bank && bank.length) {
    const escort = bank.reduce((front, u) => hdist(u, fleet) < hdist(front, fleet) ? u : front);
    const target = {q:escort.q + 4, r:escort.r};
    trialSpot(boss, h => -hdist(h,target) - 30 * Number((h.r < mid) !== (escort.r < mid)), 3);
    trialFacing(boss, fleet);
  }
}

function trialDefend(player) {
  const station = B.map.station;
  const pickets = player.slice().sort((a, b) => b.speed - a.speed || a.t.cp - b.t.cp).slice(0, 2);
  for (const [index, u] of pickets.entries()) {
    const target = {q: station.q + 3, r: station.r + (index ? 2 : -4)};
    trialSpot(u, h => -hdist(h, target) - 4 * Math.abs(hdist(h, station) - (B.map.stationR + 2)), 0);
  }
}

function trialIntercept(enemy, transports) {
  // Let the convoy enter behind its escorts. Keep the same transport exit edge.
  const row = Math.max(...transports.map(t => t.r));
  const mid = Math.round(trialCenter(transports).q + row / 2);
  for (const [index, u] of enemy.entries()) {
    const target = offToAx(mid + 3 + 2 * Math.floor(index / 2), row + (index % 2 ? 5 : 3));
    trialSpot(u, h => -hdist(h, target) * 3 + Math.min(2, ...enemy.slice(0, index).map(v => hdist(v, h))), 2);
  }
}

function trialBreak(player, enemy) {
  const bb = boardBounds();
  const mid = Math.floor((bb.r0 + bb.r1) / 2);
  const wrongSide = h => Math.max(0, 8 + CX - trialCol(h), trialCol(h) - (10 + CX));
  const gap = h => Math.min(...enemy.map(u => hdist(u, h)));
  for (const u of player) {
    if (!wrongSide(u) && gap(u) >= 5) continue;
    trialSpot(u, h => -80 * Math.max(0, 5 - gap(h)) - 12 * wrongSide(h) - Math.abs(h.r - mid), 0);
  }
  for (const u of enemy) if (trialCol(u) < 8 + CX) trialFacing(u, trialCenter(player));
}

function trialBehind(target, escorts, hunters) {
  if (!target || escorts.length < 2) return;
  const front = trialCenter(escorts);
  const n = trialCenter(hunters);
  const away = DIRS.reduce((best, d) => {
    const dot = v => (front.q - n.q) * (v[0] + v[1] / 2) + (front.r - n.r) * (v[0] / 2 + v[1]);
    return dot(d) > dot(best) ? d : best;
  });
  const goal = {q: Math.round(front.q) + 4 * away[0], r: Math.round(front.r) + 4 * away[1]};
  const frontGap = hdist(front, n);
  trialSpot(target, h => -3 * hdist(h, goal) - 8 * Math.max(0, frontGap + 2 - hdist(h, n)), 3);
  trialFacing(target, n);
}
