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
function state(tag){ rec(tag,{nem:RUN.nem,nemClock:RUN.nemClock,nemStrike:RUN.nemStrike,nemAssign:RUN.nemAssign||null,nems:RUN.nems||null,credits:RUN.credits,fleet:RUN.fleet.map(s=>[s.uid,s.hp]),variants:META.variants,rng:RNG_S>>>0}); }
function setup(seed,fac){ UID=1; rndSeed(seed); META=defaultMeta(); META.backfilled=1; META.wonFix41=1; SAVED_RUN=null; RUN=null; B=null; pickedAdmiral='vex'; pickedFaction='voidsworn'; runOpt.alt=false; runOpt.cmdAlt=false; runOpt.heat=[];
  titleScreen(); ACT.newRunScreen(); ACT.startRun(); ACT.pickAspect(window._aspOffer[0]); ACT.closeModal(); RUN.nemAssign=[fac,fac,fac]; RUN.nems={}; RUN.nem=null; nemActive(); state('new '+fac); }
// 1 Deathless: a sector 2 kill scars him; the first sector 3 kill brings him back once; the second kills him and unlocks the arc hull
setup(101,'deathless'); RUN.sector=2; rec('a1',nemAfterBattle('win',true,{cause:'melt'})); state('a1');
RUN.sector=3; rec('a2',nemAfterBattle('win',true,{})); state('a2'); rec('a3',nemAfterBattle('win',true,{})); state('a3');
// 2 Corsair: 10 credits and a crippled ship: a full clock tows her; he flees and keeps her; killed in sector 3 he gives her and the loot back
setup(102,'corsair'); RUN.credits=10; const vic=RUN.fleet.find(s=>s.uid!==RUN.flagUid); vic.hp=1; RUN.nemClock=3; RUN.nem.loot=40; rec('b0',nemWarnLine(RUN.nem).replace(/<[^>]+>/g,'')); rec('b1',nemClockAdd(1)); state('b1');
rec('b2',nemAfterBattle('win',false,{fled:true})); state('b2'); RUN.sector=3; rec('b3',nemAfterBattle('win',true,{})); state('b3');
setup(112,'corsair'); RUN.credits=200; RUN.nemClock=3; rec('b4',nemWarnLine(RUN.nem).replace(/<[^>]+>/g,'')); rec('b5',nemClockAdd(1)); state('b5');
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
for(const [i,f] of ['voidsworn','hegemony','ithar','deathless','chorus','corsair'].entries()){ setup(110+i,f); RUN.nemClock=f==='deathless'?3.5:3; rec('g '+f,nemWarnLine(RUN.nem).replace(/<[^>]+>/g,'')); rec('g2 '+f,nemClockAdd(1)); state('g '+f); }
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
RUN.nem={fac:FM,persona:NEM_FAC[FM].personas[0],weak:['ion','slow'],revealed:['ion'],adapt:[],clock:2.5,met:1,beaten:1,scars:1,seen:{lance:2}}; delete RUN.nemClock; delete RUN.nemStrike; // #121: a save of this age has no run clock
ensureNemesis(); rec('l1',{size:Object.keys(RUN.nems).length,slot:RUN.nemAssign[1],fac:nemActive().fac,weak:RUN.nem.weak,revealed:RUN.nem.revealed,adapt:RUN.nem.adapt,clock:RUN.nemClock,strike:RUN.nemStrike,met:RUN.nem.met,beaten:RUN.nem.beaten,scars:RUN.nem.scars,seen:RUN.nem.seen}); state('l1');
// 13 a pre-persona legacy save rebuilds its identity and lands in the current entry
fresh(136); toMap(); const FP=RUN.nemAssign[0]; RUN.nems={}; RUN.nem=null; RUN.nemAssign=[null,null,null]; RUN.sector=1;
RUN.nem={fac:FP,weak:['ion','slow'],revealed:['ion'],adapt:[],clock:2,met:1,beaten:1,scars:1,dead:false,strike:false,seen:{},loot:500,riches:2,fed:3,honed:1,last_beat:'lance'}; delete RUN.nemClock; delete RUN.nemStrike;
ensureNemesis(); rec('m1',{size:Object.keys(RUN.nems).length,slot:RUN.nemAssign[0],fac:nemActive().fac,weak:RUN.nem.weak,revealed:RUN.nem.revealed,clock:RUN.nemClock,strike:RUN.nemStrike,met:RUN.nem.met,beaten:RUN.nem.beaten,scars:RUN.nem.scars,loot:RUN.nem.loot,riches:RUN.nem.riches,fed:RUN.nem.fed,honed:RUN.nem.honed,last_beat:RUN.nem.last_beat}); state('m1');
// 14 a new-format save round trip keeps the assignment and both commanders
fresh(137); toMap(); RUN.nemAssign=[FA,FB,FA]; RUN.nems={}; RUN.nem=null;
RUN.sector=1; var rA=nemActive(); rA.scars=1; rA.scarKinds=['blast']; rA.epithet='the Scarred';
RUN.sector=2; var rB=nemActive(); rB.revealed=[rB.weak[0]];
var RB=canonJ({a:RUN.nemAssign,n:RUN.nems});
SAVED_RUN=JSON.parse(JSON.stringify(RUN));
RUN=migrateRun(JSON.parse(JSON.stringify(SAVED_RUN))); ensureNemesis();
rec('n1',{same:RB===canonJ({a:RUN.nemAssign,n:RUN.nems}),size:Object.keys(RUN.nems).length,fac:nemBattleCfg().fac,scars:RUN.nems[FA].scars,revealed:RUN.nems[FB].revealed}); state('n1');
// ---------- issue 121: meetings, the run clock, adaptation and lessons per commander, NEM_VOICE ----------
function forced(seed,a){ fresh(seed); toMap(); RUN.nemAssign=a.slice(); RUN.nems={}; RUN.nem=null; RUN.nemClock=0; RUN.nemStrike=false; RUN.sector=1; nemActive(); }
function bnodes(){ const o=[]; for(const c of RUN.map.cols) for(const n of c) if(n.type==='battle'||n.type==='elite') o.push(n); return o; }
function lateN(){ return bnodes().find(n=>n.col>=RUN.map.cols.length-3)||null; }
function earlyN(){ return bnodes().find(n=>n.col<RUN.map.cols.length-3)||null; }
function nodeIsAll(){ return bnodes().map(n=>nemNodeIs(n)); }
function adv(){ RUN.reward=null; window._rewardCfg={kind:'boss'}; afterBattle(); }
// 15 (121-1, 121-2) the meeting targets the active commander, once per sector; the SP1 commander returns at SP3 and is met again
forced(140,['hegemony','corsair','hegemony']); rec('o1',{is:nemNodeIs(lateN()),fac:nemBattleCfg().fac}); rec('o2',nemAfterBattle('win',false,{})); rec('o3',nodeIsAll()); state('o3');
RUN.sector=2; nemActive(); rec('o4',{is:nemNodeIs(lateN()),fac:nemBattleCfg().fac}); rec('o5',nemAfterBattle('win',false,{}));
RUN.sector=3; nemActive(); rec('o6',{is:nemNodeIs(lateN()),fac:nemBattleCfg().fac,met:nemBattleCfg().met,size:Object.keys(RUN.nems).length}); rec('o7',nemAfterBattle('win',false,{})); rec('o8',nodeIsAll()); state('o8');
// 16 (121-3) one run clock with exact half steps at each pace (Eclipse 0.5, Crusade 1.5, others 1)
for(const f of ['deathless','voidsworn','hegemony']){ forced(141,[f,f,f]); for(const x of RUN.fleet) x.hp=9999; const seq=[]; for(let i=0;i<8&&!RUN.nemStrike;i++){ rec('p '+f+' '+i,nemClockAdd(1)); seq.push(RUN.nemClock); } rec('p '+f,seq); state('p '+f); }
// 17 (121-4) a strike brings the sector 2 meeting forward without changing the hunter
forced(142,['hegemony','corsair','ithar']); nemAfterBattle('win',false,{}); RUN.sector=2; nemActive(); RUN.credits=0; rec('q1',{is:nemNodeIs(earlyN()),fac:nemActive().fac});
for(let i=0;i<8&&!RUN.nemStrike;i++) nemClockAdd(1); rec('q2',{is:nemNodeIs(earlyN()),fac:nemActive().fac,assign:RUN.nemAssign,strike:RUN.nemStrike}); state('q2');
// 18 (121-5) a win, a loss and a retreat against the sector 2 commander reset the run clock and strike; the sector 1 commander is untouched
for(const r of ['win','loss','retreat']){ forced(143,['hegemony','corsair','ithar']); nemAfterBattle('win',false,{}); RUN.sector=2; nemActive(); RUN.nemClock=4; RUN.nemStrike=true; rec('r '+r,nemAfterBattle(r,false,{})); state('r '+r); }
// 19 (121-6, A4) the real sector advance adapts the commander who fought the sector just ended, from his own seen
forced(144,['hegemony','corsair','hegemony']); RUN.nems.hegemony.seen={battery:5}; adv(); state('s1'); RUN.nems.corsair.seen={lance:9}; adv(); state('s2');
// 20 (121-8) the Chorus as SP2 adapts with its own beaten and scars, and after every meeting
forced(145,['hegemony','chorus','ithar']); RUN.sector=2; var CH=nemActive(); CH.beaten=1; CH.scars=1; CH.adapt=['armor','aim']; CH.seen={lance:9}; rec('t1',nemAdapt()); CH.seen={torp:9}; rec('t2',nemAdapt());
CH.adapt=['armor']; CH.seen={ram:2}; rec('t3',nemAfterBattle('loss',false,{})); state('t3');
// 21 (121-9) scars on the commander met; lessons from lost meetings on that commander; a full file teaches the strike once; the Crusade fallback
forced(146,['hegemony','corsair','voidsworn']); rec('u1',nemAfterBattle('win',true,{cause:'big'})); RUN.sector=2; nemActive(); rec('u2',nemAfterBattle('loss',false,{})); rec('u3',nemAfterBattle('loss',false,{})); rec('u4',nemAfterBattle('loss',false,{}));
RUN.sector=3; nemActive(); rec('u5',nemAfterBattle('loss',false,{})); state('u5');
// 22 (121-12) Eclipse fall, fall_final and the silent permanent death; opening lines, the gloat, adaptation lines, the Crusade fallback
forced(147,['deathless','deathless','deathless']); RUN.sector=2; rec('v1',nemAfterBattle('win',true,{cause:'big'})); RUN.sector=3; rec('v2',nemAfterBattle('win',true,{})); rec('v3',nemAfterBattle('win',true,{})); state('v3');
forced(148,['hegemony','ithar','corsair']); var VN=nemActive(); rec('v4',nemBattleCfg().line); VN.beaten=1; VN.last_beat='lance'; rec('v5',nemOpenLine(VN)); VN.adapt=['shields']; rec('v6',nemOpenLine(VN)); VN.gloat='loss'; rec('v7',nemOpenLine(VN));
VN.g='f'; rec('v8',nemAdaptLine(VN,'shields')); rec('v9',nemAdaptLine(VN,'formation'));
forced(149,['voidsworn','hegemony','ithar']); rec('v10',{line:nemBattleCfg().line,adapt:nemAdaptLine(nemActive(),'shields')});
// 23 (121-13) a Chorus commander that is not the first one created feeds to the cap of 8
forced(150,['hegemony','chorus','ithar']); RUN.sector=2; nemActive(); rec('w1',[nemFeedLosses(5),nemFeedLosses(9)]); state('w1');
// 24 saves: a pre-#121 save moves the clock and strike onto the run; a round trip keeps them
forced(151,['hegemony','corsair','ithar']); delete RUN.nemClock; delete RUN.nemStrike; RUN.nems.hegemony.clock=2.5; RUN.nems.hegemony.strike=true; nemActive(); state('x1');
SAVED_RUN=JSON.parse(JSON.stringify(RUN)); RUN=migrateRun(JSON.parse(JSON.stringify(SAVED_RUN))); nemActive(); state('x2');
// ---------- issue 122: telemetry (signatures, the run escape counter, the compounding counter), the panel data, saves ----------
function nemTel(){ return (META.tel||[]).filter(e=>/^nem_/.test(e.ev)).map(e=>({ev:e.ev,fac:e.fac,kind:e.kind,how:e.how,n:e.n,cap:e.cap,sector:e.sector})); }
function tstate(tag){ rec(tag,{esc:RUN.nemEscapes,cmd:Object.keys(RUN.nems).sort().map(f=>[f,RUN.nems[f].signatures,RUN.nems[f].fed,RUN.nems[f].scars,!!RUN.nems[f].dead]),tel:nemTel()}); META.tel=[]; }
// 25 (122-1) signatures carry the acting commander's faction and sector; each commander's own list, capped at 40
forced(160,['ithar','corsair','hegemony']); META.tel=[]; tstate('y0'); rec('y1',nemAfterBattle('win',false,{fled:true})); tstate('y1');
RUN.sector=2; nemActive(); RUN.credits=100; for(let i=0;i<8&&!RUN.nemStrike;i++) nemClockAdd(1); tstate('y2');
var YA=RUN.nems.ithar; for(let i=0;i<41;i++) nemSignature('k'+i,YA); rec('y3',{len:YA.signatures.length,first:YA.signatures[0],last:YA.signatures[39],active:nemActive().fac,tagged:nemTel().filter(e=>e.fac==='ithar').length}); META.tel=[];
// 26 (122-2) the run escape counter: escapes before the last sector only (flight or a flagship kill); deaths, revives and sector 3 flights never count
forced(161,['ithar','corsair','hegemony']); tstate('z0'); nemAfterBattle('win',false,{fled:true}); tstate('z1');
RUN.sector=2; nemActive(); nemAfterBattle('win',true,{cause:'big'}); tstate('z2'); RUN.sector=3; nemActive(); nemAfterBattle('win',true,{}); tstate('z3');
forced(162,['ithar','corsair','ithar']); nemAfterBattle('win',false,{fled:true}); tstate('z4'); RUN.sector=2; nemActive(); nemAfterBattle('win',false,{}); tstate('z5'); RUN.sector=3; nemActive(); nemAfterBattle('win',true,{}); tstate('z6');
forced(163,['hegemony','corsair','deathless']); RUN.sector=3; nemActive(); nemAfterBattle('win',true,{}); tstate('z7'); nemAfterBattle('win',true,{}); tstate('z8');
forced(164,['hegemony','corsair','ithar']); RUN.sector=3; nemActive(); nemAfterBattle('win',false,{fled:true}); tstate('z9');
forced(165,['ithar','corsair','ithar']); nemAfterBattle('loss',false,{}); RUN.sector=2; nemActive(); nemAfterBattle('retreat',false,{}); tstate('z10');
// 27 (122-3) the Chorus fed counter is its commander's own: losses to another commander do not feed it; 3, then the cap of 8, then still 8
forced(166,['hegemony','chorus','ithar']); rec('aa1',nemFeedLosses(5)); tstate('aa1'); RUN.sector=2; var AC=nemActive(); rec('aa2',AC.fed);
rec('aa3',[nemFeedLosses(3),nemFeedLosses(10),nemFeedLosses(2)]); tstate('aa3'); rec('aa4',Object.keys(RUN.nems).sort().map(f=>[f,nemCompound(RUN.nems[f])]));
rec('aa5',[nemCompound({fac:'corsair',fed:0,riches:2}),nemCompound({fac:'ithar',honed:1})]); RUN.sector=3; nemActive(); rec('aa6',nemFeedLosses(4)); tstate('aa6'); rec('aa7',nemTelSummary());
// 28 (122-9) the two counters are not merged: the escapes sit on the run, fed on the Chorus commander
forced(167,['ithar','chorus','hegemony']); nemAfterBattle('win',false,{fled:true}); RUN.sector=2; nemActive(); nemFeedLosses(3); tstate('ab1');
rec('ab2',{onRun:'fed' in RUN,onCmd:Object.values(RUN.nems).filter(N=>'nemEscapes' in N).length}); nemAfterBattle('win',true,{cause:'big'}); tstate('ab3');
// 29 (122-4, 122-5) the panel data: first sector, rotated (the earlier hunter still readable), the return with scars and lessons, then his death
forced(168,['ithar','chorus','ithar']); rec('ac1',nemPanelData()); nemAfterBattle('win',false,{fled:true}); adv(); rec('ac2',nemPanelData());
nemAfterBattle('loss',false,{}); rec('ac3',nemPanelData()); adv(); rec('ac4',nemPanelData()); nemAfterBattle('loss',false,{}); rec('ac5',nemPanelData()); nemAfterBattle('win',true,{}); rec('ac6',nemPanelData());
// 30 saves: a save from before the escape counter rebuilds it from the scars (a revive's scar is not an escape); a round trip keeps it
forced(169,['ithar','chorus','deathless']); nemAfterBattle('win',false,{fled:true}); delete RUN.nemEscapes; nemActive(); rec('ad1',RUN.nemEscapes);
forced(170,['hegemony','corsair','deathless']); RUN.sector=3; nemActive(); nemAfterBattle('win',true,{}); delete RUN.nemEscapes; nemActive(); rec('ad2',RUN.nemEscapes);
RUN.nemEscapes=1; SAVED_RUN=JSON.parse(JSON.stringify(RUN)); RUN=migrateRun(JSON.parse(JSON.stringify(SAVED_RUN))); nemActive(); rec('ad3',RUN.nemEscapes);
fresh(171); toMap(); RUN.nems={}; RUN.nem=null; RUN.nemAssign=[null,null,null]; RUN.sector=2; delete RUN.nemClock; delete RUN.nemStrike; delete RUN.nemEscapes;
RUN.nem={fac:'ithar',name:'Calek',title:'First Mirror',persona:NEM_FAC.ithar.personas[0],weak:['ion','slow'],revealed:['ion'],adapt:[],clock:1,met:1,beaten:2,scars:2,seen:{}}; ensureNemesis(); rec('ad4',{esc:RUN.nemEscapes,panel:nemPanelData()});
// 31 the clock-full message through nemSay (an it, a she, and a she's raiders)
forced(172,['chorus','hegemony','chorus']); RUN.nemClock=3; rec('ae1',nemClockAdd(1));
forced(173,['hegemony','chorus','hegemony']); nemActive().g='f'; RUN.nemClock=3; rec('ae2',nemClockAdd(1));
forced(174,['corsair','hegemony','corsair']); nemActive().g='f'; RUN.credits=100; RUN.nemClock=3; rec('ae3',nemClockAdd(1)); tstate('ae3');
globalThis.__OUT=OUT;
`);
fs.writeFileSync(process.argv[2], __OUT.join('\n') + '\n');
console.log(__OUT.length + ' records');
