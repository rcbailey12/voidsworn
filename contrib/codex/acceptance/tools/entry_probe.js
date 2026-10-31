'use strict';
const C=require('./common');
const env=require(C.path.join(C.ROOT,'godot/campaign/test/node/env.js'));
env.load(`
RUN=runDefaults();RUN.fac='voidsworn';RUN.admiral='vex';RUN.fleet=[newShip('warden'),newShip('harrow')];RUN.flagUid=RUN.fleet[0].uid;
var prepCount=0;prepBattle=function(){prepCount++;};
battleScreen({seed:1357,kind:'battle',fac:'hegemony',col:0,obj:'rout',shape:'open',map:'open',dep:'line',enemies:[{tpl:'h_picket'},{tpl:'h_picket'}]});
globalThis.__entry={prepCount,setupMs:META.tel.filter(x=>x.ev==='battle_start').at(-1).setupMs,units:B.units.length};`);
console.log(JSON.stringify(globalThis.__entry));
