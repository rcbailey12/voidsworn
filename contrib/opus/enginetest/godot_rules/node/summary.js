// A3 rules parity: a plain-words list of what happened in a golden record file (what the scenario exercised)
const fs = require('fs'); const L = fs.readFileSync(process.argv[2], 'utf8').trim().split('\n').map(JSON.parse); let prev = null; const seen = {};
const note = (k) => { seen[k] = (seen[k] || 0) + 1; };
for (const r of L) { const s = JSON.parse(r.state);
  if (prev) { for (const u of s.units) { const p = prev.units.find(x => x.id === u.id); if (!p) { note('ship joined mid-battle'); continue; }
      if (u.dead && !p.dead) note(u.fled ? 'ship fled' : 'ship destroyed'); for (const k of ['prow', 'mid', 'eng']) if (u.sec && u.sec[k].broken && !p.sec[k].broken) note(k + ' section destroyed');
      if (u.st.fire > p.st.fire) note('set on fire'); if (u.abCd > p.abCd) note('ability: ' + u.ab); if (u.braced && !p.braced) note('braced'); if (u.st.engine > p.st.engine) note('engines hit');
      if ((u.st.shieldOff || 0) > (p.st.shieldOff || 0)) note('shield generator down'); if (u.weapons.some((w, i) => w.off > p.weapons[i].off && w.off < 99)) note('weapon knocked out');
      if (u.rammed && !p.rammed) note('ram'); if (u.hp > p.hp && !u.dead && p.hp > 0) note('hull repaired');
      if (JSON.stringify(u.sh) !== JSON.stringify(p.sh) && u.sh.some((v, i) => typeof v === 'string' || v < p.sh[i])) note('shields hit'); }
    for (const k of Object.keys(s.b.terrain)) if (s.b.terrain[k] === 'hulk' && prev.b.terrain[k] !== 'hulk') note('wreck left as terrain');
    if (s.b.cmdE && !prev.b.cmdE) note('flagship Command: ' + s.b.cmdE.id); if (s.b.escortsFled && !prev.b.escortsFled) note('escorts broke and fled'); if (s.b.cmdENext && !prev.b.cmdENext) note('flagship Command announced'); }
  prev = s; }
const s = JSON.parse(L[L.length - 1].state);
console.log(process.argv[2].split(/[\\/]/).pop() + ': ' + L.length + ' records, ' + (L[L.length - 1].round) + ' rounds, ' + L[L.length - 1].actor + '; map ' + s.b.map.map + ', ' + s.b.arena + ' arena');
console.log('  ' + Object.entries(seen).map(([k, v]) => k + (v > 1 ? ' x' + v : '')).join(', '));
