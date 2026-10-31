'use strict';
// Compare complete, unique vector sets and enforce the expected bug contracts.
// node compare_vectors.js <js.jsonl> <gd.jsonl> baseline|candidate
const fs=require('fs'),assert=require('assert/strict');
const [aPath,bPath,mode]=process.argv.slice(2);
if(!aPath||!bPath||!['baseline','candidate'].includes(mode))throw Error('Provide JS output, Godot output and baseline|candidate');
const read=p=>fs.readFileSync(p,'utf8').trim().split('\n').filter(Boolean).map(x=>JSON.parse(x));
const a=read(aPath),b=read(bPath);
assert.equal(a.length,4506);assert.equal(b.length,4506);
assert.deepEqual(b,a,'Godot and JavaScript vectors differ');
const maps=b.filter(x=>x.kind==='map'),ships=b.filter(x=>x.kind==='shipwright');
assert.equal(maps.length,4500);assert.equal(ships.length,6);
assert.equal(new Set(maps.map(x=>x.seed+'/'+x.sector)).size,4500);
assert.equal(new Set(ships.map(x=>x.label)).size,6);
for(let i=0;i<4500;i++){
  assert.equal(maps[i].seed,Math.floor(i/3)+1);assert.equal(maps[i].sector,i%3+1);
  assert.match(maps[i].hash,/^[a-f0-9]{64}$/);assert(Number.isInteger(maps[i].rng));
  assert.equal(typeof maps[i].elite,'boolean');
}
const eliteFailures=maps.filter(x=>!x.elite).length;
const shipFailures=ships.filter(x=>!x.contractHolds).map(x=>x.label);
assert.equal(eliteFailures,mode==='baseline'?84:0);
assert.deepEqual(shipFailures,mode==='baseline'?['three identical names','two ships','max Mark']:[]);
console.log(JSON.stringify({mode,exactMatches:4506,mapMatches:4500,shipwrightMatches:6,
  eliteFailures,shipwrightContractFailures:shipFailures.length,expectedContractsVerified:true},null,2));
