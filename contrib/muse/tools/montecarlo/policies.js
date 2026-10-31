// policies.js - campaign policy profiles for the policy-sensitivity extension.
// Appended after driver.js by shard.js (same concatenated script). Every
// override is gated on MC_POLICY: with policy 'baseline' each wrapper calls
// the driver original untouched, which is verified by exact-trace comparison
// against the first program's raw shards. The battle pilot (bot.js, sim3d's
// bot) is never touched; profiles differ only in campaign-layer decisions:
// node routing, shipyard spending, event choices, and (hunter) boon picks.
// Aspect picks, prize/salvage/relic/perk picks, and faction-verb use keep the
// baseline rules in every profile, as stated in the report.
var MC_POLICY = 'baseline';
var MC_PEAK = 0; // largest fleet size this run (rusher's replacement target)

const _mcChooseNode = mcChooseNode, _mcShipyard = mcShipyard, _mcEvent = mcEvent,
      _mcPickBoon = mcPickBoon, _mcRewardStep = mcRewardStep, _newRun = newRun;

// Track the run's peak fleet size: at run start, after every reward step
// (prizes and tows can add ships), and inside the policy shipyard.
newRun = function (a, f, o) { const r = _newRun(a, f, o); MC_PEAK = (typeof RUN !== 'undefined' && RUN && RUN.fleet) ? RUN.fleet.length : 0; return r; };
mcRewardStep = function (S) { const r = _mcRewardStep(S); if (typeof RUN !== 'undefined' && RUN && RUN.fleet) MC_PEAK = Math.max(MC_PEAK, RUN.fleet.length); return r; };

const _mcRunOnePol = MC.runOne;
MC.runOne = async function (cfg) { MC_POLICY = cfg.policy || 'baseline'; MC_PEAK = 0; const S = await _mcRunOnePol(cfg); S.policy = MC_POLICY; return S; };

// ---------------- node routing ----------------
function mcPolicyNodeScore(n) {
  const hpF = mcFleetHpFrac(), dmg = 1 - hpF;
  if (MC_POLICY === 'rusher') {
    if (n.type === 'boss') return 1000;
    const owed = MC_PEAK - RUN.fleet.length; // ships lost and not yet replaced
    if (hpF < 0.5) { // damaged: repair stops outrank everything but the boss
      if (n.type === 'drydock') return 300; if (n.type === 'field') return 280; if (n.type === 'shipyard') return 260;
      if (n.type === 'event') return 40; return n.type === 'elite' ? 10 : 20;
    }
    if (owed > 0 && n.type === 'shipyard') return 300; // detour only to replace a loss
    if (n.type === 'event') return 100; if (n.type === 'field') return 90;
    if (n.type === 'drydock') return 80; if (n.type === 'shipyard') return 70;
    return n.type === 'battle' ? 30 : 10; // forced fight: plain battle over elite
  }
  if (MC_POLICY === 'turtle') {
    let s = 0;
    if (n.type === 'elite') s = 38; else if (n.type === 'boss') s = 45; else if (n.type === 'battle') s = 30;
    else if (n.type === 'shipyard') s = 30 + (RUN.credits >= 150 ? 25 : 0); else if (n.type === 'event') s = 34;
    else if (n.type === 'drydock') s = 15; else if (n.type === 'field') s = 15;
    if (dmg > 0.30) { if (n.type === 'drydock') s += 120; else if (n.type === 'field') s += 100; else if (n.type === 'shipyard') s += 90; else if (n.type === 'elite') s -= 25; }
    if (n.rw) { if (n.rw.k === 'cred') s += 60; else if (n.rw.k === 'boon') s += 6; else if (n.rw.k === 'mod') s += 5; else if (n.rw.k === 'repair' && dmg > 0.2) s += 25; }
    return s;
  }
  if (MC_POLICY === 'hunter') {
    let s = 0;
    if (n.type === 'elite') s = 60; else if (n.type === 'boss') s = 45; else if (n.type === 'battle') s = 55;
    else if (n.type === 'event') s = 30; else if (n.type === 'shipyard') s = 18;
    else if (n.type === 'drydock') s = 12; else if (n.type === 'field') s = 12;
    if ((n.type === 'battle' || n.type === 'elite') && nemNodeIs(n)) s += 200; // his node: take the meeting now
    if (dmg > 0.45) { if (n.type === 'drydock') s += 100; else if (n.type === 'field') s += 80; else if (n.type === 'shipyard') s += 70; else if (n.type === 'elite') s -= 10; }
    if (n.rw) { if (n.rw.k === 'boon') s += 6; else if (n.rw.k === 'cred') s += 3; else if (n.rw.k === 'mod') s += 5; else if (n.rw.k === 'repair' && dmg > 0.2) s += 25; }
    return s;
  }
  return mcNodeScore(n);
}
mcChooseNode = function (avail) {
  if (MC_POLICY === 'baseline') return _mcChooseNode(avail);
  let bid = avail[0], bs = -1e18;
  for (const id of avail) { const n = findNode(id); if (!n) continue; const sc = mcPolicyNodeScore(n); if (sc > bs) { bs = sc; bid = id; } }
  return bid;
};

// ---------------- shipyard ----------------
// A line-for-line policy variant of the driver's mcShipyard: identical stats
// recording, identical repair-all first step; only the spend rules differ.
// Hunter never calls this (it keeps the baseline yard via the gate in the
// mcShipyard wrapper below).
function mcPolicyShipyard(n, S) {
  shipyardScreen(n);
  const st = n.stock, pm = priceMult();
  S.hullOffers.push({ offer: st.hulls.slice(), s: RUN.sector });
  S.modOffers.push({ offer: st.mods.slice(), s: RUN.sector, src: 'yard' });
  const missing = mcMissing(), maxTot = RUN.fleet.reduce((a, s) => a + derive(s).maxHp, 0);
  const prices = [...st.hulls.map(h => Math.round(HULLS[h].cost * pm)), ...st.mods.map(m => Math.round(MODULES[m].cost * pm)), ...RUN.fleet.filter(s => s.mk < 3).map(s => mkCost(s))].filter(x => x > 0);
  const reg = { type: 'shipyard', s: RUN.sector, creditsIn: RUN.credits, missing, worstMissing: RUN.fleet.reduce((a, s) => Math.max(a, derive(s).maxHp - s.hp), 0), missingFrac: maxTot ? missing / maxTot : 0, pm, cheapest: prices.length ? Math.min(...prices) : 0, repairCost: Math.ceil(missing / 2 * pm), spendRepair: 0, spendHull: 0, spendMod: 0, spendMk: 0 };
  let c0 = RUN.credits; if (missing > 0) ACT.repairAll(); reg.spendRepair = c0 - RUN.credits;
  const rusher = MC_POLICY === 'rusher';
  for (const h of st.hulls.slice().sort((a, b) => (HULLS[b].cp || 1) - (HULLS[a].cp || 1))) {
    const t = HULLS[h], cost = Math.round(t.cost * pm);
    if (t.unique && RUN.fleet.some(s => s.tpl === h)) continue;
    if (fleetCP() + (t.cp || 1) > RUN.cpCap) continue;
    if (rusher && RUN.fleet.length >= MC_PEAK) continue; // replace losses only
    if (RUN.credits - cost < 0) continue; // rusher and turtle spend to a 0 floor
    c0 = RUN.credits; ACT.buyHull(h); if (RUN.credits < c0) { reg.spendHull += c0 - RUN.credits; S.hullPicks.push({ id: h, s: RUN.sector }); }
  }
  if (!rusher) { // turtle buys every affordable module; rusher buys none
    st.mods.forEach((m, i) => { if (st.sold.includes(i)) return; const cost = Math.round(MODULES[m].cost * pm); if (RUN.credits - cost < 0) return;
      c0 = RUN.credits; ACT.buyMod(i); if (RUN.credits < c0) { reg.spendMod += c0 - RUN.credits; S.modPicks.push({ id: m, src: 'yard' }); mcAutoFit(m); } });
    const order = [...RUN.fleet].sort((a, b) => ((b.uid === RUN.flagUid ? 1 : 0) - (a.uid === RUN.flagUid ? 1 : 0)) || ((HULLS[b.tpl].cp || 1) - (HULLS[a.tpl].cp || 1)));
    for (const s of order) { if (s.mk >= 3) continue; const c = mkCost(s); if (RUN.credits - c < 0) continue; c0 = RUN.credits; ACT.upgradeMk(s.uid); if (RUN.credits < c0) reg.spendMk += c0 - RUN.credits; }
  }
  MC_PEAK = Math.max(MC_PEAK, RUN.fleet.length);
  reg.creditsOut = RUN.credits; reg.missingOut = mcMissing();
  S.regroups.push(reg);
  ACT.leaveYard();
}
mcShipyard = function (n, S) {
  if (MC_POLICY === 'rusher' || MC_POLICY === 'turtle') return mcPolicyShipyard(n, S);
  return _mcShipyard(n, S); // baseline and hunter keep the driver's yard
};

// ---------------- events ----------------
// Same structure as the driver's mcEvent; only the option scorer differs.
function mcEventScore(x, missFrac) {
  const r = x.o.r || {};
  if (MC_POLICY === 'rusher') { // leave fast: no fights, no costs, no damage
    let v = (r.cred || 0) + (r.xp || 0) + (r.xpLow || 0) + (r.xpTop || 0);
    v += (r.healAll || 0) * 300 * missFrac + (r.repairOne ? 80 * missFrac : 0);
    v -= (r.fight ? 10000 : 0) + (r.cost || 0) * 20 + (r.dmgAll || 0) * 600 + (r.dmgOne || 0) * 200 + (r.dmgBig || 0) * 300;
    v -= (r.payRelic ? 200 : 0) + (r.payXp ? 60 : 0) + (r.payMod ? 80 : 0) + (r.loseMod ? 80 : 0) + (r.gamble ? 10 : 0);
    return v;
  }
  if (MC_POLICY === 'turtle') { // net credits dominate everything else
    let v = ((r.cred || 0) - (r.cost || 0)) * 10;
    v += (r.ship || r.shipRaw ? 150 : 0) + (r.relic ? 40 : 0) + ((r.mod || r.modId) ? 20 : 0) + (r.upgradeOne ? 30 : 0) + (r.xp || 0);
    v += (r.healAll || 0) * 200 * missFrac + (r.repairOne ? 40 * missFrac : 0);
    v -= (r.dmgAll || 0) * 400 + (r.dmgOne || 0) * 150 + (r.dmgBig || 0) * 200 + (r.payRelic ? 130 : 0) + (r.payXp ? 50 : 0) + (r.payMod ? 60 : 0) + (r.loseMod ? 70 : 0) + (r.gamble ? 10 : 0);
    if (r.fight) v += mcFleetHpFrac() >= 0.6 ? 20 : -500;
    return v;
  }
  if (MC_POLICY === 'hunter') { // intel first, clock second, then baseline value
    let v = (r.nemIntel ? 500 : 0) + (r.nemClock ? 150 * r.nemClock : 0);
    v += (r.cred || 0) + (r.xp || 0) * 2 + (r.xpLow || 0) + (r.xpTop || 0);
    v += (r.healAll || 0) * 300 * missFrac + (r.repairOne ? 80 * missFrac : 0);
    v += (r.relic ? 60 : 0) + ((r.mod || r.modId) ? 30 : 0) + ((r.ship || r.shipRaw) ? 80 : 0) + (r.upgradeOne ? 50 : 0);
    v -= (r.cost || 0) + (r.dmgAll || 0) * 400 + (r.dmgOne || 0) * 150 + (r.dmgBig || 0) * 200 + (r.payRelic ? 130 : 0) + (r.payXp ? 50 : 0) + (r.payMod ? 60 : 0) + (r.loseMod ? 70 : 0) + (r.gamble ? 10 : 0);
    if (r.fight) v += mcFleetHpFrac() >= 0.55 ? 80 : -100;
    return v;
  }
  // baseline scorer, copied from driver.js mcEvent
  let v = 0;
  v += (r.cred || 0) + (r.xp || 0) * 2 + (r.xpLow || 0) + (r.xpTop || 0);
  v += (r.healAll || 0) * 300 * missFrac + (r.repairOne ? 80 * missFrac : 0);
  v += (r.relic ? 120 : 0) + ((r.mod || r.modId) ? 60 : 0) + ((r.ship || r.shipRaw) ? 150 : 0) + (r.upgradeOne ? 100 : 0) + (r.nemIntel ? 40 : 0);
  v -= (r.cost || 0) + (r.dmgAll || 0) * 400 + (r.dmgOne || 0) * 150 + (r.dmgBig || 0) * 200 + (r.payRelic ? 130 : 0) + (r.payXp ? 50 : 0) + (r.payMod ? 60 : 0) + (r.loseMod ? 70 : 0) + (r.gamble ? 10 : 0);
  if (r.fight) v += mcFleetHpFrac() >= 0.7 ? 60 : -200;
  return v;
}
mcEvent = function (n, S) {
  if (MC_POLICY === 'baseline') return _mcEvent(n, S);
  const ev = nextEvent(); const cur = Object.assign({}, ev, (ev.v && ev.v[RUN.fac]) || {});
  const rec = { id: ev.id, s: RUN.sector, total: cur.o.length, enabled: 0, choice: -1 };
  const opts = cur.o.map((o, i) => ({ o, i })).filter(x => eventOptOk(x.o)); rec.enabled = opts.length; S.events.push(rec);
  if (!opts.length) { completeNode(); return {}; }
  const missFrac = 1 - mcFleetHpFrac();
  let bx = opts[0], bv = -1e18; for (const x of opts) { const v = mcEventScore(x, missFrac); if (v > bv) { bv = v; bx = x; } }
  const o = bx.o; rec.choice = bx.i; eventFlags(cur, o, bx.i);
  if (o.r && o.r.fight) return { battle: { kind: 'elite', fac: o.r.fight, col: n.col + 1, node: n.id, eventRelic: true } };
  applyOutcome(o.r || {}); completeNode(); return {};
};

// ---------------- boon picks (hunter) ----------------
// Anti-Nemesis set (chair definition, stated in the report): boons that
// concentrate fire on one priority hull or kill a flagship outright, which is
// what a Nemesis fight turns on. a_mark marks one ship for the whole fleet,
// L_star lances always hit and pierce shields, a_lance / a_aim / a_crit raise
// lance damage, aim and crit, d_hunter crits after long moves, e_hunt scales
// damage against a burning target.
const MC_HUNTER_BOONS = new Set(['a_mark', 'L_star', 'a_lance', 'a_aim', 'a_crit', 'd_hunter', 'e_hunt']);
mcPickBoon = function (offer) {
  if (MC_POLICY !== 'hunter') return _mcPickBoon(offer);
  const kit = fleetKit();
  if (offer.every(o => !boonUseful(o.id, kit))) return -1;
  let bi = 0, bs = -1e9;
  offer.forEach((o, i) => { const b = BOONS[o.id]; let sc = (o.r || 0) * 3 + mcFxScore(b.fx(RARITY[o.r || 0].m)) + (b.duo ? 2 : 0) + (b.leg ? 4 : 0); if (MC_HUNTER_BOONS.has(o.id)) sc += 100; if (sc > bs) { bs = sc; bi = i; } });
  return bi;
};
