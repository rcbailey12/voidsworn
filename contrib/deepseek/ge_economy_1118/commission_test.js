// commission_test.js - issue 1086 run 2 regression test for Glasswright G-C.
// Artoo on PR 1102: one shipyard visit could queue several commissions because
// the loop checked "one order in flight" once, before the stock shelf, and
// mcGeBuyHull had no queue check. The purchase point now calls
// mcCommissionCanOrder (sim/commission_policy.js).
//
// Artoo's case: two affordable 4-point offers, fleet 2 of cap 6, 1,000 credits.
// Exactly one order may be queued by the visit. The test runs the real
// mcGeBuyHull through the real loader and driver, then checks the policy alone.
'use strict';
const fs = require('fs');
const path = require('path');
const { loadGame } = require('./sim/loader_main');
const { mcCommissionCanOrder } = require('./sim/commission_policy.js');

const REPO = path.resolve(__dirname, '..', '..', '..');
let checks = 0, fails = 0;
function is(name, cond, detail) {
  checks++;
  if (cond) console.log('PASS: ' + name + (detail ? ' (' + detail + ')' : ''));
  else { fails++; console.log('FAIL: ' + name + (detail ? ' (' + detail + ')' : '')); }
}

// --- the policy on its own ---
is('one pending order refuses a second affordable 4-point offer',
  mcCommissionCanOrder(1, 1000, 290, 2, 4, 6) === false);
is('no pending order allows the first affordable 4-point offer',
  mcCommissionCanOrder(0, 1000, 290, 2, 4, 6) === true);
is('a hull that does not fit the cap is refused',
  mcCommissionCanOrder(0, 1000, 290, 4, 4, 6) === false);
is('a hull that cannot be paid for is refused',
  mcCommissionCanOrder(0, 200, 290, 2, 4, 6) === false);

// --- the real purchase point: two offers, one queue slot ---
const extra = [
  fs.readFileSync(path.join(__dirname, 'sim', 'commission_policy.js'), 'utf8'),
  fs.readFileSync(path.join(__dirname, 'sim', 'driver_ge.js'), 'utf8'),
];
const game = loadGame(REPO, { extra });
const api = game.api;
api.get('META = defaultMeta()');
api.get('mcGeReset({ge:{commission:true}})');
// Fleet 2 of cap 6: two 1-point frigates, 1,000 credits, empty queue.
api.get('RUN = {fleet:[{tpl:"i_wisp",uid:1},{tpl:"i_wisp",uid:2}],credits:1000,cpCap:6,commQueue:[],flagUid:1,fac:"ithar"}');
const buy = api.get('mcGeBuyHull');
const stats = {};
const first = buy('i_song', stats);       // 4 points, 290 credits
const queueAfterFirst = api.get('RUN.commQueue.length');
const creditsAfterFirst = api.get('RUN.credits');
const second = buy('h_vanguard', stats);  // 4 points, 250 credits, also affordable
const queueAfterSecond = api.get('RUN.commQueue.length');
const creditsAfterSecond = api.get('RUN.credits');

is('the first affordable 4-point offer is queued', first === true && queueAfterFirst === 1 && creditsAfterFirst === 710,
  'queued ' + queueAfterFirst + ', credits ' + creditsAfterFirst);
is('the second affordable offer is refused at the purchase point', second === false && queueAfterSecond === 1 && creditsAfterSecond === 710,
  'returned ' + second + ', queued ' + queueAfterSecond + ', credits ' + creditsAfterSecond);
is('exactly one commission is in flight after the visit', queueAfterSecond === 1 && stats.commissionsStarted === 1,
  'queue ' + queueAfterSecond + ', started ' + stats.commissionsStarted);

if (fails) { console.log('FAIL: ' + fails + ' of ' + checks + ' commission checks failed'); process.exit(1); }
console.log('PASS: ' + checks + ' commission checks');
