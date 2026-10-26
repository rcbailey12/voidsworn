// G3: Nemesis campaign scenarios (port_notes step 4 "Suggested golden scenarios", campaign side), JS side. The Godot side is
// nem_scenarios.gd; run_nem_scenarios.sh compares the two line by line (canonical state after every step, no tolerance).
//   node nem_scenarios.js <out.txt>
'use strict';
const fs = require('fs');
const env = require('./env.js');
env.load(String.raw`
function canonJ(v){
  if(v===null||v===undefined) return 'null';
  if(typeof v==='boolean') return v?'true':'false';
  if(typeof v==='number'){ if(Number.isInteger(v)&&Math.abs(v)<9007199254740992) return String(v===0?0:v); const b=Buffer.alloc(8); b.writeDoubleBE(v); return '"d:'+b.toString('hex')+'"'; }
  if(typeof v==='string') return JSON.stringify(v);
  if(typeof v==='function') return 'null';
  if(Array.isArray(v)) return '['+Array.from(v,x=>canonJ(x)).join(',')+']';
  const ks=Object.keys(v).filter(k=>v[k]!==null&&v[k]!==undefined&&typeof v[k]!=='function').sort();
  return '{'+ks.map(k=>JSON.stringify(k)+':'+canonJ(v[k])).join(',')+'}';
}
toast=function(){}; show=function(){}; modal=function(){};
const OUT=[];
function rec(tag,x){ OUT.push(tag+' '+canonJ(x)); }
function state(tag){ rec(tag,{nem:RUN.nem,credits:RUN.credits,fleet:RUN.fleet.map(s=>[s.uid,s.hp]),variants:META.variants,rng:RNG_S>>>0}); }
function setup(seed,fac){ UID=1; rndSeed(seed); META=defaultMeta(); META.backfilled=1; META.wonFix41=1; SAVED_RUN=null; RUN=null; B=null; pickedAdmiral='vex'; pickedFaction='voidsworn'; runOpt.alt=false; runOpt.cmdAlt=false; runOpt.heat=[];
  titleScreen(); ACT.newRunScreen(); ACT.startRun(); ACT.pickAspect(window._aspOffer[0]); ACT.closeModal(); RUN.foes[3]=fac; RUN.nem=newNemesis(); state('new '+fac); }
// 1 Deathless: a sector 2 kill scars him; the first sector 3 kill brings him back once; the second kills him and unlocks the arc hull
setup(101,'deathless'); RUN.sector=2; rec('a1',nemAfterBattle('win',true,{cause:'melt'})); state('a1');
RUN.sector=3; rec('a2',nemAfterBattle('win',true,{})); state('a2'); rec('a3',nemAfterBattle('win',true,{})); state('a3');
// 2 Corsair: 10 credits and a crippled ship: a full clock tows her; he flees and keeps her; killed in sector 3 he gives her and the loot back
setup(102,'corsair'); RUN.credits=10; const vic=RUN.fleet.find(s=>s.uid!==RUN.flagUid); vic.hp=1; RUN.nem.clock=3; RUN.nem.loot=40; rec('b0',nemWarnLine(RUN.nem).replace(/<[^>]+>/g,'')); rec('b1',nemClockAdd(1)); state('b1');
rec('b2',nemAfterBattle('win',false,{fled:true})); state('b2'); RUN.sector=3; rec('b3',nemAfterBattle('win',true,{})); state('b3');
setup(112,'corsair'); RUN.credits=200; RUN.nem.clock=3; rec('b4',nemWarnLine(RUN.nem).replace(/<[^>]+>/g,'')); rec('b5',nemClockAdd(1)); state('b5');
// 3 Ithar: he flees: honed, no riches
setup(103,'ithar'); rec('c1',nemAfterBattle('win',false,{fled:true,beat:'torp'})); state('c1'); rec('c1cfg',nemBattleCfg());
// 4 Chorus: feeding and its cap, a loss with your flagship dead, fast adaptation with its reason
setup(104,'chorus'); rec('d1',nemFeedLosses(3)); rec('d2',nemFeedLosses(10)); rec('d3',nemFeedLosses(2)); state('d3');
RUN.nem.seen={ram:3}; rec('d4',nemAfterBattle('loss',false,{myFlagDead:true})); state('d4'); rec('d4cfg',nemBattleCfg());
// 5 Voidsworn: beaten with lances, his next adaptation is the counter
setup(105,'voidsworn'); RUN.nem.seen={battery:5}; rec('e1',nemAfterBattle('win',false,{beat:'lance'})); RUN.sector=2; rec('e2',nemAdapt()); state('e2');
// 6 weaknesses found in battle; pronouns for a she and an it
setup(106,'hegemony'); rec('f1',nemFoundMerge(['flank',RUN.nem.weak[0],RUN.nem.weak[1],'nonsense'])); state('f1');
RUN.nem.g='f'; rec('f2',nemSay('He holds his line; his guns follow him.',RUN.nem)); RUN.nem.g='n'; rec('f3',nemSay('He holds his line; his guns follow him.',RUN.nem));
// 7 every faction's warning line at clock 3, and the tithe
for(const [i,f] of ['voidsworn','hegemony','ithar','deathless','chorus','corsair'].entries()){ setup(110+i,f); RUN.nem.clock=f==='deathless'?3.5:3; rec('g '+f,nemWarnLine(RUN.nem).replace(/<[^>]+>/g,'')); rec('g2 '+f,nemClockAdd(1)); state('g '+f); }
globalThis.__OUT=OUT;
`);
fs.writeFileSync(process.argv[2], __OUT.join('\n') + '\n');
console.log(__OUT.length + ' records');
