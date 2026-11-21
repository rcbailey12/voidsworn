// Issue 1393: dumps the opening of teaching Battle 2 for one seed. Usage: node dump.js <this repo> <game checkout> <seed> <out.json>
'use strict';
const fs=require('fs'),path=require('path'),Module=require('module');
const [repo, root, seed, out]=process.argv.slice(2);
const src=path.join(repo,'contrib/muse/tools/montecarlo'); const read=n=>fs.readFileSync(path.join(src,n),'utf8');
let sim=fs.readFileSync(path.join(repo,'tools/teaching_1393/sim_fresh_1393.js'),'utf8');
let shim=sim.slice(sim.indexOf('const shim = `')+14, sim.indexOf('`;\nconst loaderPath'));
shim+=`
var DUMP1393=null;
const _d=mcBattleLoop; mcBattleLoop=async function(){ if(!DUMP1393&&B&&B.cfg&&B.cfg.teachingBattle===2){
  DUMP1393={BW,BH,hexes:boardHexes(),terrain:Object.assign({},B.terrain),shape:B.shape,arena:B.cfg.arena||null,dep:B.deployMode,fac:B.cfg.fac,ev:B.event,
   units:B.units.map(u=>({q:u.q,r:u.r,side:u.side,tpl:u.tpl,cls:HULLS[u.tpl]?HULLS[u.tpl].cls:'',sq:!!u.isSq}))}; }
  return _d.apply(this,arguments); };`;
const lp=path.join(src,'loader_main.js'); const mod=new Module(lp,module); mod.filename=lp; mod.paths=Module._nodeModulePaths(src); mod._compile(read('loader_main.js'),lp);
const game=mod.exports.loadGame(path.resolve(root),{extra:['bot.js','driver.js','policies.js'].map(read).concat([shim])});
(async()=>{ const adm=game.api.get('ADMIRALS'), ids=Object.keys(adm).filter(id=>(adm[id].fac||'voidsworn')==='voidsworn');
  const s=Number(seed); await game.api.runOne({fac:'voidsworn',admiral:ids[(s-1)%ids.length],ai:'standard',seed:s,policy:'baseline',priceMult:1,cpDelta:0,credMult:1});
  fs.writeFileSync(out,JSON.stringify(game.api.get('DUMP1393'))); console.log('ok'); })();
