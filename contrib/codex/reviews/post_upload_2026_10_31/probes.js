'use strict';
// Focused review probes. No game or Muse source files are modified.
const fs = require('fs');
const path = require('path');
const os = require('os');
const vm = require('vm');
const assert = require('assert/strict');
const repo = path.resolve(process.argv[2] || '.');
const tools = path.join(repo, 'contrib/muse/tools');
const proposed = path.join(repo, 'contrib/codex/proposed/contrib/muse/tools');
const results = {};

function gateProbe(dir) {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'voidsworn-gate-probe-'));
  try {
    fs.writeFileSync(path.join(temp, 'data.js'), '');
    fs.writeFileSync(path.join(temp, 'core.js'), '');
    fs.writeFileSync(path.join(temp, 'baseline.json'), JSON.stringify({components:{
      findings_tests:{badSet:['X'],goodSet:[],watchSet:[]}
    }}));
    const context = { require, __dirname:temp, console:{log() {},error() {}},
      process:{execPath:process.execPath, argv:['node','gate.js',temp,'--out',temp],
        exit(code){context.exitCode=code;} } };
    vm.createContext(context);
    const source = fs.readFileSync(path.join(dir,'gate.js'),'utf8');
    const at = source.lastIndexOf('\nmain();');
    assert(at > 0);
    vm.runInContext(source.slice(0,at) + `
      globalThis.disappeared = classify({badSet:[],goodSet:[],watchSet:[]},
        {badSet:['X'],goodSet:[],watchSet:[]},true);
      for (const component of COMPONENTS) component.run = () =>
        component.id === 'findings_tests'
          ? {signature:{},badSet:[],goodSet:['X'],watchSet:[],cleanWhenUnchanged:true,summary:'controlled improvement'}
          : {notRun:'controlled missing required component'};
      main();
    `,context);
    const report = JSON.parse(fs.readFileSync(path.join(temp,'gate_report.json'),'utf8'));
    return {disappearingFailure:context.disappeared.verdict,
      missingPlusImprovement:report.overall,exitCode:context.exitCode};
  } finally {fs.rmSync(temp,{recursive:true,force:true});}
}
results.originalGate = gateProbe(path.join(tools,'cutover_gate'));
results.proposedGate = gateProbe(path.join(proposed,'cutover_gate'));
assert.equal(results.originalGate.disappearingFailure,'IMPROVEMENT');
assert.equal(results.originalGate.exitCode,0);
assert.equal(results.proposedGate.disappearingFailure,'REGRESSION');
assert.equal(results.proposedGate.exitCode,1);

// Stop after newRun, before any battles, to isolate per-run table mutation.
// This still calls the actual mcRunOne entry point and actual data loader.
const {loadGame} = require(path.join(tools,'montecarlo/loader_main.js'));
const extra = ['bot.js','driver.js','policies.js'].map(n=>fs.readFileSync(path.join(tools,'montecarlo',n),'utf8'));
extra.push('aspectScreen = function(){throw new Error("review probe stop after price scaling");};');
const game = loadGame(repo,{extra});
const get = expression => JSON.parse(JSON.stringify(game.api.get(expression)));
(async()=>{
  const initial=get('HULLS.d_scythe.cost');
  const prices=[initial];
  for(let i=0;i<3;i++){
    const run=await game.api.runOne({fac:'deathless',admiral:'nekhet',ai:'veteran',seed:100+i,priceMult:1.25});
    assert(run.errors.some(x=>x.includes('review probe stop')));
    prices.push(get('HULLS.d_scythe.cost'));
  }
  results.priceGrid = {hull:'d_scythe',multiplier:1.25,costsAcrossRuns:prices};
  assert(prices[2]>prices[1]);
  const fixedExtra = ['bot.js','driver.js','policies.js'].map(n=>fs.readFileSync(
    path.join(n === 'driver.js' ? path.join(proposed,'montecarlo') : path.join(tools,'montecarlo'),n),'utf8'));
  fixedExtra.push('aspectScreen = function(){throw new Error("review probe stop after price scaling");};');
  const fixed = loadGame(repo,{extra:fixedExtra});
  const fixedPrices=[fixed.api.get('HULLS.d_scythe.cost')];
  for(let i=0;i<3;i++){
    await fixed.api.runOne({fac:'deathless',admiral:'nekhet',ai:'veteran',seed:100+i,priceMult:1.25});
    fixedPrices.push(fixed.api.get('HULLS.d_scythe.cost'));
  }
  await fixed.api.runOne({fac:'deathless',admiral:'nekhet',ai:'veteran',seed:200,priceMult:1});
  results.proposedPriceGrid={costsAcrossRuns:fixedPrices,baselineRestored:fixed.api.get('HULLS.d_scythe.cost')};
  assert.deepEqual(fixedPrices,[100,125,125,125]);
  assert.equal(results.proposedPriceGrid.baselineRestored,100);
  console.log(JSON.stringify(results,null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
