// A3 timing report: enemy think time per activation (the AI's aiUnit only, no snapshots, no startup), Node against Godot.
//   node timing.js <name> <node.jsonl.timing.json> <godot.jsonl.timing.json>
// Report only: the parity check decides PASS or FAIL. Game bar (owner, Oct 25): worst enemy think under about 0.5 s on the PC.
const fs = require('fs'), path = require('path'); const [name, a, b] = process.argv.slice(2);
//   node timing.js all <test folder>   every scenario marked "timing" in scenarios.json
if (name === 'all') { const S = JSON.parse(fs.readFileSync(path.join(a, 'scenarios.json'), 'utf8')); for (const k of Object.keys(S).filter(k => S[k].timing)) { const g = path.join(a, 'golden', k + '.jsonl.timing.json'), o = path.join(a, 'out', k + '.jsonl.timing.json'); if (fs.existsSync(g) && fs.existsSync(o)) require('child_process').execFileSync(process.execPath, [__filename, k, g, o], { stdio: 'inherit' }); } process.exit(0); }
const sum = f => { const t = JSON.parse(fs.readFileSync(f, 'utf8')); const ms = t.acts.map(x => x.ms); const w = t.acts.reduce((m, x) => x.ms > m.ms ? x : m, { ms: 0 });
  const rounds = Object.values(t.rounds); return { n: ms.length, avg: ms.reduce((x, y) => x + y, 0) / Math.max(1, ms.length), worst: w.ms, wturn: w.turn, wround: w.round, rmax: Math.max(...rounds), ravg: rounds.reduce((x, y) => x + y, 0) / Math.max(1, rounds.length) }; };
const N = sum(a), G = sum(b), f = x => (x / 1000).toFixed(3) + ' s';
console.log(`  ${name}: ${G.n} enemy activations`);
console.log(`    Node   think per activation: average ${f(N.avg)}, worst ${f(N.worst)} (turn ${N.wturn}); per round: average ${f(N.ravg)}, worst ${f(N.rmax)}`);
console.log(`    Godot  think per activation: average ${f(G.avg)}, worst ${f(G.worst)} (turn ${G.wturn}); per round: average ${f(G.ravg)}, worst ${f(G.rmax)}`);
console.log(`    Godot/Node: ${(G.avg / N.avg).toFixed(1)}x on average. Worst enemy think ${G.worst <= 500 ? 'is inside' : 'MISSES'} the 0.5 s bar ${G.worst <= 500 ? '' : '(report only)'}`.trimEnd());
