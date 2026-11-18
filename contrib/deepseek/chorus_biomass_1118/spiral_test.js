// spiral_test.js - tiny unit test for the issue 1085 loss spiral recovery test.
// Artoo's example: a 100 hull ship missing 50, with 20 to spend, is recoverable
// because a 25 percent repair is 25 hull and the shipped price is 13. Run 1's
// full repair price of 25 was close enough to make the same case look stuck.
'use strict';
const path=require('path');
const {mcRepairHull,mcRepairCost,mcUnrecoverable}=require(path.join(__dirname,'sim','spiral.js'));

let checks=0, fails=0;
function is(name,cond,detail){
  checks++;
  if(cond) console.log('PASS: '+name+(detail?' ('+detail+')':''));
  else { fails++; console.log('FAIL: '+name+(detail?' ('+detail+')':'')); }
}

// Artoo's example, shipped price at priceMult 1.
is('Artoo example: 100 hull ship missing 50, 20 to spend, is recoverable',
  mcRepairHull(50,100)===25&&mcRepairCost(50,100,1)===13&&mcUnrecoverable(50,100,20,1,90,true)===false,
  'repair hull '+mcRepairHull(50,100)+', cost '+mcRepairCost(50,100,1));
// The same ship with too little money is truly unrecoverable.
is('truly unrecoverable: same ship, 10 to spend, cheapest hull 90',
  mcUnrecoverable(50,100,10,1,90,true)===true,
  'cost '+mcRepairCost(50,100,1)+', money 10, cheapest hull 90');
// A small dent is capped at what is missing, not at a full quarter of the hull.
is('repair is capped at what is missing: 5 missing on a 100 hull ship costs 3',
  mcRepairHull(5,100)===5&&mcRepairCost(5,100,1)===3&&mcUnrecoverable(5,100,3,1,90,true)===false,
  'repair hull '+mcRepairHull(5,100)+', cost '+mcRepairCost(5,100,1));
// The shipped price multiplier applies to the 25 percent repair too.
is('priceMult 1.5 turns the 25 hull repair into 19',
  mcRepairCost(50,100,1.5)===19,
  'cost '+mcRepairCost(50,100,1.5));
// A hull shelf can be the recovery route when the repair alone is not affordable.
is('cheapest hull can recover a fleet that cannot pay the 25 percent repair',
  mcUnrecoverable(50,100,10,1,9,true)===false,
  'cost '+mcRepairCost(50,100,1)+', cheapest hull 9');
// An empty fleet is never a recovery.
is('empty fleet is unrecoverable even with money',mcUnrecoverable(0,0,500,1,90,false)===true);

if(fails){ console.log('FAIL: '+fails+' of '+checks+' spiral checks failed'); process.exit(1); }
console.log('PASS: '+checks+' spiral recovery checks');
