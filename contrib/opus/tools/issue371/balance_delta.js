// Issue 371 balance pack: reads the sim3d outputs of a before (main) and an after (branch) run and prints the deltas as
// Markdown tables. Usage: node contrib/opus/tools/issue371/balance_delta.js <dir> <beforeTag> <afterTag>
// The dir holds p_<tag>_fmatrix_24.txt, p_<tag>_bossmatrix_16.txt, p_<tag>_campaign_60.txt and p_<tag>_fuzz_300.txt, each the tail of
//   PAIRSEED=1000 node sim3d.js <mode> <n>      (fuzz: SEED=1; it only has to show 0 exceptions)
// run from the root of that tree. contrib/opus/tools/issue371/run_pack.sh writes them.
const fs = require('fs'), path = require('path');
const [dir, A, Bt] = process.argv.slice(2);
const read = (tag, leg) => { try { return fs.readFileSync(path.join(dir, 'p_' + tag + '_' + leg + '.txt'), 'utf8'); } catch (e) { return ''; } };
const line = (txt, pre) => { const l = txt.split('\n').find(x => x.startsWith(pre)); return l ? JSON.parse(l.slice(pre.length).trim()) : null; };
const F = ['voidsworn', 'hegemony', 'corsair', 'chorus', 'ithar', 'deathless'];
const NAME = { voidsworn: 'Sunward Crusade', hegemony: 'Hegemony Navy', corsair: 'Ashfall Hullbreakers', chorus: 'the Chorus', ithar: 'the Glasswrights', deathless: 'Eclipse' };
const sgn = d => (d > 0 ? '+' : '') + d;
const out = [];
// fmatrix: faction row averages, and the share of damage shields stopped
{ const a = line(read(A, 'fmatrix_24'), 'FM '), b = line(read(Bt, 'fmatrix_24'), 'FM ');
  const fa = line(read(A, 'fmatrix_24'), 'FID '), fb = line(read(Bt, 'fmatrix_24'), 'FID ');
  if (a && b) {
    out.push('### Faction against faction (fmatrix 24: 24 battles a cell, 864 battles, PAIRSEED=1000, 8 command points a side)', '',
      '| Faction | Win rate as the player side, before | after | change | Damage stopped by shields, before | after |', '|---|---|---|---|---|---|');
    for (const f of F) { const av = o => Math.round(F.reduce((s, e) => s + o.out[f][e], 0) / F.length);
      out.push('| ' + NAME[f] + ' | ' + av(a) + '% | ' + av(b) + '% | ' + sgn(av(b) - av(a)) + ' | ' + (fa ? fa[f].shieldPct : '?') + '% | ' + (fb ? fb[f].shieldPct : '?') + '% |'); }
    const cells = []; for (const f of F) for (const e of F) cells.push([f, e, b.out[f][e] - a.out[f][e]]);
    cells.sort((x, y) => Math.abs(y[2]) - Math.abs(x[2]));
    out.push('', 'Largest cell moves: ' + cells.slice(0, 5).map(c => NAME[c[0]] + ' vs ' + NAME[c[1]] + ' ' + a.out[c[0]][c[1]] + ' to ' + b.out[c[0]][c[1]] + '%').join('; ') + '.', '');
  }
}
// bossmatrix: every admiral against a sector 1 flagship
{ const pa = read(A, 'bossmatrix_16'), pb = read(Bt, 'bossmatrix_16'); const a = line(pa, 'bossmatrix s1 '), b = line(pb, 'bossmatrix s1 ');
  if (a && b) {
    const SHIELD = { thale: 'Sunward wall (R93)', mirelle: 'Glasswright wall', maren: 'Hegemony wall', vaelen: 'Glasswright', aelith: 'Glasswright', thorne: 'Glasswright' };
    out.push('### Admirals against a sector 1 flagship (bossmatrix 16: starting fleets only, 16 battles against each other faction\'s boss, PAIRSEED=1000)', '',
      '| Admiral | before | after | change | note |', '|---|---|---|---|---|');
    for (const k of Object.keys(a)) { const x = parseInt(a[k]), y = parseInt(b[k]); const flag = (y < 50 || y > 90) ? 'outside 50 to 90' : '';
      out.push('| ' + k + ' | ' + x + '% | ' + y + '% | ' + sgn(y - x) + ' | ' + [SHIELD[k] ? 'leans on shields: ' + SHIELD[k] : '', flag].filter(Boolean).join('; ') + ' |'); }
    const ba = line(pa, 'by boss '), bb = line(pb, 'by boss ');
    if (ba && bb) out.push('', 'Win rate against each boss faction: ' + F.map(f => NAME[f] + ' ' + ba[f] + ' to ' + bb[f]).join('; ') + '.', '');
  }
}
// campaign nodes
{ const grab = t => t.split('\n').filter(l => /^\s*(s\d|sector)/i.test(l) || /win/i.test(l)).slice(-30);
  const a = grab(read(A, 'campaign_60')), b = grab(read(Bt, 'campaign_60'));
  if (a.length || b.length) out.push('### Campaign nodes (campaign 60 battles a row, PAIRSEED=1000)', '', 'before:', '```', ...a, '```', 'after:', '```', ...b, '```', '');
}
// fuzz
{ const g = t => (t.split('\n').find(l => /^fuzz/.test(l)) || '(no fuzz line)');
  out.push('### Crash test (fuzz 300, SEED=1)', '', '- before: ' + g(read(A, 'fuzz_300')), '- after: ' + g(read(Bt, 'fuzz_300')), '');
}
console.log(out.join('\n'));
