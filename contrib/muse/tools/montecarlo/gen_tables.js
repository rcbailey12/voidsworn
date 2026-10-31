// gen_tables.js - renders markdown tables from aggregate.json for the reports.
'use strict';
const a = require('./aggregate.json');
const P = x => (x * 100).toFixed(1) + '%';
const CI = c => '[' + (c[0] * 100).toFixed(1) + ', ' + (c[1] * 100).toFixed(1) + ']';

console.log('## Run win rates\n');
console.log('| Slice | Runs | Win rate | 95% CI |');
console.log('|---|---|---|---|');
console.log(`| All runs | ${a.overall.n} | ${P(a.overall.rate)} | ${CI(a.overall.ci)} |`);
for (const [k, v] of Object.entries(a.byAI)) console.log(`| AI: ${k} | ${v.n} | ${P(v.rate)} | ${CI(v.ci)} |`);
for (const [k, v] of Object.entries(a.byFaction)) console.log(`| Faction: ${k} | ${v.n} | ${P(v.rate)} | ${CI(v.ci)} |`);
console.log('\n## Sector reach\n');
console.log('| Reach | Share | 95% CI |');
console.log('|---|---|---|');
for (const [k, v] of Object.entries(a.reach)) console.log(`| ${k} | ${P(v.rate)} | ${CI(v.ci)} |`);
console.log(`| Won the run | ${P(a.overall.rate)} | ${CI(a.overall.ci)} |`);

console.log('\n## Battle classes\n');
console.log('| Class | n | Win rate | 95% CI | Ships lost (mean) | Rounds (mean) |');
console.log('|---|---|---|---|---|---|');
for (const [k, v] of Object.entries(a.battleClasses)) console.log(`| ${k} | ${v.n} | ${P(v.winRate)} | ${CI(v.winCI)} | ${v.lostMean} | ${v.roundsMean} |`);

console.log('\n## Nemesis meetings\n');
for (const [k, v] of Object.entries(a.nemesis)) {
  if (v && v.n != null && v.winRate != null) console.log(`| ${k} | n=${v.n} | win ${P(v.winRate)} ${CI(v.winCI)} | adaptations before ${v.adaptB} after ${v.adaptA} | weakness reveals gained ${v.revGain} | fed before ${v.fedB} |`);
}
console.log('By adaptations carried in:');
for (const [k, v] of Object.entries(a.nemesis.byAdapt || {})) console.log(`| ${k} | n=${v.n} | win ${P(v.winRate)} ${CI(v.winCI)} |`);
console.log('By weaknesses revealed before:');
for (const [k, v] of Object.entries(a.nemesis.byRev || {})) console.log(`| ${k} | n=${v.n} | win ${P(v.winRate)} ${CI(v.winCI)} |`);

console.log('\n## Economy\n');
console.log('Mean credits [95% CI], n:', JSON.stringify(a.economy));
console.log('Regroup:', JSON.stringify(a.regroup));

console.log('\n## Boon utilization (offered at least 20 times)\n');
console.log('| Boon | Offered | Picked | Pick rate | Runs with pick | Win rate in those runs |');
console.log('|---|---|---|---|---|---|');
for (const r of a.boons.filter(r => r.offered >= 20)) console.log(`| ${r.id} | ${r.offered} | ${r.picked} | ${r.pickRate} | ${r.runsWithPick} | ${r.winRateWithPick} |`);
console.log('\nBoons never offered:', a.boons.filter(r => !r.offered).map(r => r.id).join(', ') || 'none');
console.log('Boons offered but never picked:', a.boons.filter(r => r.offered > 0 && !r.picked).map(r => r.id + ' (' + r.offered + ')').join(', ') || 'none');

console.log('\n## Module utilization (offered at least 20 times)\n');
console.log('| Module | Offered | Picked | Pick rate |');
console.log('|---|---|---|---|');
for (const r of a.modules.filter(r => r.offered >= 20)) console.log(`| ${r.id} | ${r.offered} | ${r.picked} | ${r.pickRate} |`);
console.log('Modules offered but never picked:', a.modules.filter(r => r.offered > 0 && !r.picked).map(r => r.id + ' (' + r.offered + ')').join(', ') || 'none');

console.log('\n## Relic utilization\n');
console.log('| Relic | Offered | Picked | Pick rate |');
console.log('|---|---|---|---|');
for (const r of a.relics) console.log(`| ${r.id} | ${r.offered} | ${r.picked} | ${r.pickRate} |`);

console.log('\n## Hull utilization (shipyard stock)\n');
console.log('| Hull | Offered | Bought | Rate |');
console.log('|---|---|---|---|');
for (const r of a.hulls) console.log(`| ${r.id} | ${r.offered} | ${r.picked} | ${r.pickRate} |`);

console.log('\n## Events seen\n');
console.log('| Event | Times | No enabled option |');
console.log('|---|---|---|');
for (const r of a.events) console.log(`| ${r.id} | ${r.times} | ${r.noEnabled} |`);

console.log('\n## Ships fielded (battles)\n');
console.log(a.shipsFielded.map(r => `${r.id}: ${r.battles}`).join(', '));
console.log('\nPrizes:', JSON.stringify(a.prizes), ' Salvage:', JSON.stringify(a.salvage), ' Boon declines:', a.boonDeclines, ' Verb uses:', a.verbUses);
console.log('\nTimeouts:', a.timeouts, ' Runs with harness errors:', a.errors, ' Total runs:', a.totalRuns);
