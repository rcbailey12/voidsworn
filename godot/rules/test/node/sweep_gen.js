// Random battle list for the parity sweep: node sweep_gen.js <count> <seed> <out.json>
// Every field the scenarios understand is varied: fight type, field shape and map, deployment, battle kind, sector, column,
// both factions, the admiral (and so the Command), the player fleet, generated enemy fleets (archetype, modifier), boons,
// relics, aspect, heat, veteran captains, AI level, Classic mode, campaign events, the Nemesis (R42 and R49) and the bot. Both sides read the same file.
const fs = require('fs'), path = require('path');
const T = JSON.parse(fs.readFileSync(path.join(__dirname, '..', '..', 'data', 'tables.json'), 'utf8')).tables;
const [n, seed, out] = [+process.argv[2] || 200, +process.argv[3] || 1, process.argv[4] || 'sweep.json'];
let s = seed >>> 0; const r = () => { s = (Math.imul(s, 1664525) + 1013904223) >>> 0; return s / 4294967296; };
const pick = a => a[Math.floor(r() * a.length)], chance = p => r() < p;
const some = (a, k) => { const c = a.slice(), o = []; for (let i = 0; i < k && c.length; i++) o.push(c.splice(Math.floor(r() * c.length), 1)[0]); return o; };
const FACS = Object.keys(T.FACTIONS), ADMS = Object.keys(T.ADMIRALS), ENC = Object.keys(T.ENCOUNTERS);
const MAPS = ['open', 'belt', 'station', 'planet', 'storm', 'graveyard'];
const res = {};
for (let i = 0; i < n; i++) {
  const sector = 1 + Math.floor(r() * 3), adm = pick(ADMS), pf = T.ADMIRALS[adm].fac || 'voidsworn';
  const kind = chance(0.1) ? 'boss' : chance(0.22) ? 'elite' : 'battle';
  const obj = kind === 'boss' ? pick(['rout', 'rout', 'ambush', 'flagship']) : pick(ENC);
  const ros = T.FACTIONS[pf].roster.filter(id => T.HULLS[id] && !T.HULLS[id].boss);
  const cap = [0, 6, 10, 14][sector], fleet = [];
  for (let g = 0; g < 40 && fleet.length < 6; g++) { const id = pick(ros), cp = T.HULLS[id].cp || 1, used = fleet.reduce((a, x) => a + (T.HULLS[x].cp || 1), 0); if (used + cp <= cap || fleet.length < 2) fleet.push(id); if (used + cp >= cap && fleet.length >= 2) break; }
  const S = { note: 'sweep', seed: Math.floor(r() * 4294967295), sector, admiral: adm, fac_player: pf, fleet,
    fac: pick(FACS.filter(f => f !== pf)), obj, shape: pick(T.ENCOUNTERS[obj].shapes), map: pick(MAPS), dep: pick(['line', 'line', 'flank', 'ambush']),
    kind, col: kind === 'boss' ? 6 : Math.floor(r() * 6), rounds: 10, bot: chance(0.85) ? 'full' : 'basic' };
  const arch = pick([null, null, 'swarm', 'heavy', 'carrier']); if (arch) S.arch = arch;
  const mod = pick([null, null, null, 'bounty', 'veteran']); if (mod) S.mod = mod;
  if (chance(0.6)) S.boons = some(Object.keys(T.BOONS), Math.floor(r() * 7)).map(id => ({ id, r: T.BOONS[id].leg ? 3 : Math.floor(r() * 3) }));
  if (chance(0.5)) S.relics = some(Object.keys(T.RELICS), 1 + Math.floor(r() * 4));
  if (chance(0.3)) S.aspect = pick(Object.keys(T.ASPECTS));
  if (chance(0.3)) S.heat = some(Object.keys(T.HEAT), 1 + Math.floor(r() * 3));
  if (chance(0.3)) S.vet = true;
  if (chance(0.25)) S.ai = 'standard';
  if (chance(0.15)) S.alt = false;
  if (chance(0.4)) S.attack_move = true;
  if (kind === 'elite' && chance(0.7)) { // the R42 and R49 Nemesis: persona, traits, faction special, honed, riches, fed, memory lines
    const NF = T.NEM_FAC[S.fac] || { beh: {}, personas: [], traits: [] }, sp = (T.NEM_ADAPT_FAC[S.fac] || {}).special;
    S.nemesis = { name: 'Nemesis', title: 'Admiral', fac: S.fac, weak: some(Object.keys(T.NEM_WEAK), 2), adapt: some(Object.keys(T.NEM_ADAPT).concat(sp ? [sp.id] : []), Math.floor(r() * 4)), scars: Math.floor(r() * 3),
      persona: pick(NF.personas.length ? NF.personas : Object.keys(T.NEM_PERSONA)), traits: some(NF.traits || [], 2), g: NF.g || pick(['m', 'f']) };
    const N = S.nemesis;
    if (chance(0.5)) N.riches = Math.floor(r() * 4); if (chance(0.5)) N.honed = 1 + Math.floor(r() * 3); if (chance(0.4)) N.fed = Math.floor(r() * 9);
    if (chance(0.5)) { N.met = 1 + Math.floor(r() * 2); N.last_beat = pick(['lance', 'torp', 'sq', 'ram', 'board', 'battery', 'evasive']); } else if (chance(0.3)) N.gloat = pick(Object.keys(T.NEM_LINES.gloat)); }
  if (chance(0.3) && T.FAC_VERBS[pf] && T.FAC_VERBS[pf].next) S.verb = T.FAC_VERBS[pf].id;
  if (chance(0.25)) { const cls = ['Frigate', 'Destroyer', 'Cruiser', 'Carrier']; S.class_track = {}; for (const c of some(cls, 2)) S.class_track[c] = 1 + Math.floor(r() * 3); }
  if (chance(0.5)) { S.campaign = true; if (chance(0.3)) S.event_force = pick(Object.keys(T.BEVENTS)); else if (chance(0.3)) S.event_war = true; }
  res['w' + (i + 1)] = S;
}
fs.writeFileSync(out, JSON.stringify(res, null, 1)); console.log('sweep', n, 'battles ->', out);
