(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.VSLineagePilot=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const KEYS=['adm.vaelen.A1.0','adm.vaelen.A1.1'];
function snapshot(meta,id){
 if(id!=='vaelen'||!meta||!meta.opts||meta.opts.lineagePilot!==true)return null;
 const state=meta.lineageV1,line=state&&state.lines&&state.lines.vaelen;
 if(!state||state.version!==1||!line||!Number.isSafeInteger(line.xpQ)||line.xpQ<0||line.xpQ>2400||!Array.isArray(line.picks)||line.picks.length>1||line.capstone!=='')return null;
 if(line.picks.length&&(line.xpQ<300||!KEYS.includes(line.picks[0])))return null;
 return {version:1,admiral:id,xpQ:line.xpQ,picks:line.picks.slice()};
}
function mode(run,side,c){
 const s=run&&run.lineagePilot;
 if(side!=='player'||!run||run.admiral!=='vaelen'||run.cmdOverride||!c||c.id!=='barrage'||!s||s.version!==1||s.admiral!=='vaelen'||!Number.isSafeInteger(s.xpQ)||s.xpQ<300||s.xpQ>2400||!Array.isArray(s.picks)||s.picks.length!==1)return null;
 return KEYS.includes(s.picks[0])?s.picks[0]:null;
}
function intent(run,side,c,battle){
 const selected=mode(run,side,c),raw=battle&&battle.lineageIntent;
 if(selected!==KEYS[1])return {ok:true,mode:selected,weapons:{}};
 if(raw===undefined||raw===null)return {ok:true,mode:selected,weapons:{}};
 if(typeof raw!=='object'||Array.isArray(raw))return {ok:false};
 const weapons={};
 for(const [id,index] of Object.entries(raw)){
  const u=battle.units.find(x=>x.id===id&&x.side==='player'&&!x.dead&&!x.isSq);
  if(!u||index!==null&&(!Number.isSafeInteger(index)||index<0||index>=u.weapons.length||u.weapons[index].k==='flak'||(u.weapons[index].off||0)>0))return {ok:false};
  weapons[id]=index;
 }
 return {ok:true,mode:selected,weapons};
}
function allows(context,u,index){return context.mode!==KEYS[1]||context.weapons[u.id]===undefined||context.weapons[u.id]===null||context.weapons[u.id]===index;}
function factor(context,u,w,t,distance){
 if(context.mode===KEYS[0])return distance>w.r/2?1.2:1;
 if(context.mode===KEYS[1]&&context.weapons[u.id]!==undefined&&context.weapons[u.id]!==null)return 1.25;
 return 1;
}
return {KEYS,snapshot,mode,intent,allows,factor};
});
