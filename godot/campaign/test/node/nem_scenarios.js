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
function state(tag){ rec(tag,{nem:RUN.nem,nemAssign:RUN.nemAssign||null,nems:RUN.nems||null,credits:RUN.credits,fleet:RUN.fleet.map(s=>[s.uid,s.hp]),variants:META.variants,rng:RNG_S>>>0}); }
function setup(seed,fac){ UID=1; rndSeed(seed); META=defaultMeta(); META.backfilled=1; META.wonFix41=1; SAVED_RUN=null; RUN=null; B=null; pickedAdmiral='vex'; pickedFaction='voidsworn'; runOpt.alt=false; runOpt.cmdAlt=false; runOpt.heat=[];
  titleScreen(); ACT.newRunScreen(); ACT.startRun(); ACT.pickAspect(window._aspOffer[0]); ACT.closeModal(); RUN.nemAssign=[fac,fac,fac]; RUN.nems={}; RUN.nem=null; nemActive(); state('new '+fac); }
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
// 8 R1 (Nov 1): a lost meeting teaches one weakness, a battle find counts as it, a full file says so; the clash check; a pre-persona save keeps its state
setup(120,'hegemony'); rec('h1',nemAfterBattle('loss',false,{})); state('h1'); rec('h2',nemAfterBattle('retreat',false,{found:[RUN.nem.weak[1],'nonsense']})); state('h2'); rec('h3',nemAfterBattle('loss',false,{})); state('h3');
setup(121,'chorus'); RUN.nem.revealed=['ion','torp']; RUN.nem.seen={lance:9,ion:9,torp:9,sq:9}; RUN.sector=2; rec('h4',nemAdapt()); rec('h5',nemAdapt(true)); state('h5');
setup(122,'corsair'); RUN.nem={weak:['ion','slow'],revealed:['ion'],adapt:['riches'],clock:2,met:1,beaten:1,scars:1,dead:false,strike:false,seen:{},loot:500,riches:2,fed:3,honed:1,held:RUN.fleet[1],last_beat:'lance'}; rec('h6',ensureNemesis()); state('h6');

// ---------- issue 120: assignment draw, registry, active resolution, migration ----------
function fresh(seed){ UID=1; rndSeed(seed); META=defaultMeta(); META.backfilled=1; META.wonFix41=1; SAVED_RUN=null; RUN=null; B=null; pickedAdmiral='vex'; pickedFaction='voidsworn'; runOpt.alt=false; runOpt.cmdAlt=false; runOpt.heat=[];
  titleScreen(); ACT.newRunScreen(); ACT.startRun(); return RUN.nemAssign; }
function toMap(){ ACT.pickAspect(window._aspOffer[0]); ACT.closeModal(); }
// 9 drawn once at run start, registry empty until a story point resolves
fresh(130); state('i0'); rec('i0a',{len:RUN.nemAssign.length,nems:Object.keys(RUN.nems).length});
toMap(); state('i1'); var IA=canonJ(RUN.nemAssign);
RUN.sector=2; nemActive(); rec('i2',nemAfterBattle('win',false,{})); state('i2');
RUN.sector=3; nemActive(); rec('i3',nemAfterBattle('win',false,{})); state('i3');
rec('i4',canonJ(RUN.nemAssign)===IA);
// 10 the active commander resolves from the assignment, not the legacy foes[3] default
fresh(131); toMap(); const FA=RUN.foes[0], FB=RUN.foes[1], FC=RUN.foes[2], FD=RUN.foes[3];
RUN.nemAssign=[FA,FB,FC]; RUN.nems={}; RUN.nem=null; RUN.sector=1; rec('j1',nemBattleCfg().fac);
RUN.sector=2; rec('j2',nemBattleCfg().fac);
RUN.sector=3; rec('j3',nemBattleCfg().fac);
RUN.sector=1; RUN.foes[3]=FD; rec('j4',nemBattleCfg().fac);
// 11 lazy creation grows the registry by one per new faction; a returning commander keeps his identity and scars
fresh(1); state('k0'); RUN.sector=1; var n1=nemActive(); state('k1');
n1.scars=1; n1.scarKinds=['blast']; RUN.sector=2; var n2=nemActive(); state('k2');
RUN.sector=3; var n3=nemActive(); state('k3');
rec('k4',{fac1:n1.fac,fac2:n2.fac,fac3:n3.fac,same:n1===n3,scars:n3.scars,nems:Object.keys(RUN.nems).length});
// 12 a mid-run legacy save migrates into the current story point's entry
fresh(135); toMap(); const FM=RUN.nemAssign[0]; RUN.nems={}; RUN.nem=null; RUN.nemAssign=[null,null,null]; RUN.sector=2;
RUN.nem={fac:FM,persona:NEM_FAC[FM].personas[0],weak:['ion','slow'],revealed:['ion'],adapt:[],clock:2.5,met:1,beaten:1,scars:1,seen:{lance:2}};
ensureNemesis(); rec('l1',{size:Object.keys(RUN.nems).length,slot:RUN.nemAssign[1],fac:nemActive().fac,weak:RUN.nem.weak,revealed:RUN.nem.revealed,adapt:RUN.nem.adapt,clock:RUN.nem.clock,met:RUN.nem.met,beaten:RUN.nem.beaten,scars:RUN.nem.scars,seen:RUN.nem.seen}); state('l1');
// 13 a pre-persona legacy save rebuilds its identity and lands in the current entry
fresh(136); toMap(); const FP=RUN.nemAssign[0]; RUN.nems={}; RUN.nem=null; RUN.nemAssign=[null,null,null]; RUN.sector=1;
RUN.nem={fac:FP,weak:['ion','slow'],revealed:['ion'],adapt:[],clock:2,met:1,beaten:1,scars:1,dead:false,strike:false,seen:{},loot:500,riches:2,fed:3,honed:1,last_beat:'lance'};
ensureNemesis(); rec('m1',{size:Object.keys(RUN.nems).length,slot:RUN.nemAssign[0],fac:nemActive().fac,weak:RUN.nem.weak,revealed:RUN.nem.revealed,clock:RUN.nem.clock,met:RUN.nem.met,beaten:RUN.nem.beaten,scars:RUN.nem.scars,loot:RUN.nem.loot,riches:RUN.nem.riches,fed:RUN.nem.fed,honed:RUN.nem.honed,last_beat:RUN.nem.last_beat}); state('m1');
// 14 a new-format save round trip keeps the assignment and both commanders
fresh(137); toMap(); RUN.nemAssign=[FA,FB,FA]; RUN.nems={}; RUN.nem=null;
RUN.sector=1; var rA=nemActive(); rA.scars=1; rA.scarKinds=['blast']; rA.epithet='the Scarred';
RUN.sector=2; var rB=nemActive(); rB.revealed=[rB.weak[0]];
var RB=canonJ({a:RUN.nemAssign,n:RUN.nems});
SAVED_RUN=JSON.parse(JSON.stringify(RUN));
RUN=migrateRun(JSON.parse(JSON.stringify(SAVED_RUN))); ensureNemesis();
rec('n1',{same:RB===canonJ({a:RUN.nemAssign,n:RUN.nems}),size:Object.keys(RUN.nems).length,fac:nemBattleCfg().fac,scars:RUN.nems[FA].scars,revealed:RUN.nems[FB].revealed}); state('n1');
globalThis.__OUT=OUT;
`);
fs.writeFileSync(process.argv[2], __OUT.join('\n') + '\n');
console.log(__OUT.length + ' records');
