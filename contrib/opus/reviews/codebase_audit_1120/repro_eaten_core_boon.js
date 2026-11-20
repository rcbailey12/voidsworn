// Issue 1333 audit, finding F1 (browser twin). node contrib/opus/reviews/codebase_audit_1120/repro_eaten_core_boon.js
// A Chorus run that ate the Iron core gets a reward whose patron is Iron (the fallback in rewardFlow picks from RUN.patrons,
// eaten core included, e.g. a Nemesis meeting at a column 4 shipyard). The browser's boonStep moves the offer to another patron.
'use strict';
const env = require('../../../../godot/campaign/test/node/env.js');
env.load(String.raw`
var __M=''; modal=function(h){ __M=String(h); }; show=function(){}; toast=function(){};
globalThis.__probe=function(){
  rndSeed(120); META=defaultMeta(); META.admirals.matriarch=true; newRun('matriarch','chorus',{});
  RUN.patrons=['star','rook','storm','iron']; RUN.eatenCore='iron'; RUN.eatCoreSeen=true; RUN.sector=3; RUN.credits=200;
  RUN.reward={kind:'elite',rw:{k:'boon',p:'iron',min:1},stage:'pick',relics:[],wrecks:[],prizes:[],boonOffer:null,modOffer:null};
  boonStep('iron',1);
  const arg=(__M.match(/data-act="boonReroll" data-arg="([^"]*)"/)||[])[1];
  return {patronShown:arg&&arg.split(':')[0], offer:RUN.reward.boonOffer.map(o=>o.id+' ('+BOONS[o.id].p+')')};
};`);
const r = __probe();
console.log('browser: offer patron = ' + r.patronShown + '; offer = ' + r.offer.join(', '));
