#!/usr/bin/env node
'use strict';
// Code-level DOM harness, not a browser render or screenshot test.
const fs=require('fs'),path=require('path'),vm=require('vm'),assert=require('assert');
const html=fs.readFileSync(path.resolve(__dirname,'../preview.html'),'utf8'),nodes=new Map();
for(const m of html.matchAll(/\bid="([^"]+)"/g)){
 if(nodes.has(m[1]))continue;
 const classes=new Set();nodes.set(m[1],{value:'',textContent:'',innerHTML:'',disabled:false,className:'',classList:{toggle(k,on){if(on)classes.add(k);else classes.delete(k);},contains:k=>classes.has(k)}});
}
for(const m of html.matchAll(/<input\b([^>]+)>/g)){const id=m[1].match(/id="([^"]+)"/),value=m[1].match(/value="([^"]*)"/);if(id&&value)nodes.get(id[1]).value=value[1];}
for(const m of html.matchAll(/<select\b[^>]*id="([^"]+)"[^>]*>([\s\S]*?)<\/select>/g))nodes.get(m[1]).value=m[2].match(/<option value="([^"]+)"/)[1];
const store=new Map(),sandbox={document:{getElementById:id=>{assert(nodes.has(id),'unknown element '+id);return nodes.get(id);}},localStorage:{getItem:k=>store.get(k)||null,setItem:(k,v)=>store.set(k,v)},console};sandbox.window=sandbox;vm.createContext(sandbox);
for(const script of html.matchAll(/<script>([\s\S]*?)<\/script>/g))vm.runInContext(script[1],sandbox,{timeout:3000});
const get=id=>nodes.get(id),click=id=>{assert(!get(id).disabled,id+' disabled');get(id).onclick();},text=id=>String(get(id).textContent);
assert.equal(text('total'),'75');assert(!get('chooseLong').disabled);assert.equal((get('remaining').innerHTML.match(/Not implemented/g)||[]).length,18);
click('chooseLong');assert(get('longCard').classList.contains('chosen'));assert.equal(text('singleState'),'Excluded by current choice');click('save');
click('respec');assert.equal(text('wallet'),'75');assert.equal(text('total'),'75');click('chooseSingle');assert(get('singleCard').classList.contains('chosen'));assert(text('respec').includes('35'));
get('xp').value='1';click('setXP');assert.equal(text('total'),'75');assert(text('message').includes('Respec'));
click('reset');click('restore');assert(get('longCard').classList.contains('chosen'));assert.equal(text('wallet'),'100');
get('heat').value='4';click('award');assert.equal(text('total'),'84');assert.equal(text('bench'),'2.25');assert(text('pool').includes('4 XP'));
click('export');const before=get('json').value;get('json').value='{';click('import');assert(get('message').className.includes('error'));click('export');assert.equal(get('json').value,before);
const parsed=JSON.parse(before);parsed.state.lines.vaelen.picks=['adm.vaelen.A2.0'];get('json').value=JSON.stringify(parsed);click('import');assert(get('message').className.includes('error'));click('export');assert.equal(get('json').value,before);
console.log('PASS: standalone workbench code loads; choose/exclude/respec/save/restore/Heat/shadow/import controls pass');
console.log('NOT RUN: rendered browser, layout, screenshot and keyboard accessibility checks');
