// boongrid.js - phase 3c: boon offer / favour rarity curves by direct sampling
// of the shipped rollBoonOffer, plus two what-if variants applied as exact-once
// in-memory source replacements (files on disk untouched):
//   fixA: off-patron backfill rolls rarity WITH the patron favour argument
//   fixAB: fixA plus same-patron junk backfill also gets the favour argument
//   fixDuo: duo boons roll rarity instead of entering at fixed Common (r:0)
'use strict';
const fs = require('fs');
const path = require('path');
const { loadGame } = require('./loader_main');
const REPO = process.env.MC_REPO || path.resolve(__dirname, '../../../..');

const VARIANTS = {
  base: {},
  fixA: { 'core.js': [['out.push({id:extra.pop(),r:rollRarity(minR,s)})', 'out.push({id:extra.pop(),r:rollRarity(minR,s,p)})']] },
  fixAB: { 'core.js': [['out.push({id:extra.pop(),r:rollRarity(minR,s)})', 'out.push({id:extra.pop(),r:rollRarity(minR,s,p)})'],
                        ['out.push({id:junk.pop(),r:rollRarity(minR,s)})', 'out.push({id:junk.pop(),r:rollRarity(minR,s,p)})']] },
  fixDuo: { 'core.js': [['const d={id:pick(duos),r:0}', 'const d={id:pick(duos),r:rollRarity(minR,s,p)}']] },
};

function runVariant(name) {
  const extra = [fs.readFileSync(path.join(__dirname, 'bot.js'), 'utf8'), fs.readFileSync(path.join(__dirname, 'driver.js'), 'utf8')];
  const G = loadGame(REPO, { replace: VARIANTS[name], extra });
  const sample = G.api.sampleBoons;
  const tiers = G.api.get('FAVOUR_TIERS');
  const patrons = Object.keys(G.api.get('PATRONS'));
  const cells = [];
  for (const sector of [1, 2, 3]) for (const tier of [0, 1, 2, 3]) for (const minR of [0, 1]) for (const holds of ['none', 'two']) {
    const agg = { patron: { 0: 0, 1: 0, 2: 0, 3: 0 }, backfill: { 0: 0, 1: 0, 2: 0, 3: 0 }, duo: 0, leg: 0, offers: 0, slots: 0 };
    patrons.forEach((p, pi) => {
      const r = sample({ patron: p, sector, favourPts: tiers[tier].at, minR, holds, n: 2500, seed: 7000 + sector * 1000 + tier * 100 + minR * 10 + pi });
      for (const k of ['0', '1', '2', '3']) { agg.patron[k] += r.patron[k]; agg.backfill[k] += r.backfill[k]; }
      agg.duo += r.duo; agg.leg += r.leg; agg.offers += r.offers; agg.slots += r.slots;
    });
    cells.push({ variant: name, sector, tier, minR, holds, ...agg });
  }
  // duo incidence needs holds='duo' scaffolding (a held boon from the partner patron)
  for (const sector of [1, 2, 3]) for (const tier of [0, 1, 2, 3]) {
    const agg = { patron: { 0: 0, 1: 0, 2: 0, 3: 0 }, backfill: { 0: 0, 1: 0, 2: 0, 3: 0 }, duo: 0, leg: 0, offers: 0, slots: 0 };
    patrons.forEach((p, pi) => {
      const r = sample({ patron: p, sector, favourPts: tiers[tier].at, minR: 0, holds: 'duo', n: 2500, seed: 9000 + sector * 1000 + tier * 100 + pi });
      for (const k of ['0', '1', '2', '3']) { agg.patron[k] += r.patron[k]; agg.backfill[k] += r.backfill[k]; }
      agg.duo += r.duo; agg.leg += r.leg; agg.offers += r.offers; agg.slots += r.slots;
    });
    cells.push({ variant: name, sector, tier, minR: 0, holds: 'duo', ...agg });
  }
  return cells;
}

const which = process.argv[2] || 'base';
const cells = runVariant(which);
fs.writeFileSync(path.join(__dirname, 'raw', 'boongrid_' + which + '.json'), JSON.stringify(cells));
console.log(which, 'cells', cells.length, 'total offers', cells.reduce((a, c) => a + c.offers, 0));
