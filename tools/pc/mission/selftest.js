'use strict';
// All writes use new TEMP directories. No live jobs, Serve changes or commits.
const assert=require('assert/strict');
const fs=require('fs'),os=require('os'),path=require('path'),http=require('http');
const {createHash}=require('crypto');
const p=require('./publisher'),q=require('./queue');
const {Budget}=require('./budget');
const NOW=new Date(2026,10,16,16,30).getTime(),iso=n=>new Date(n).toISOString();
const lane=(s,id)=>s.lanes.find(l=>l.id===id);
const RUN='0123456789abcdef0123456789abcdef',OLD='0123456789abcdef1111111111111111';
function write(file,text,at=NOW-60000){fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,text);fs.utimesSync(file,new Date(at),new Date(at));}
function copyFixture(root,source=path.join(__dirname,'fixtures/lanes')){
  for(const d of fs.readdirSync(source,{withFileTypes:true})){
    const src=path.join(source,d.name),dest=path.join(root,d.name);
    if(d.isDirectory())copyFixture(dest,src);
    else write(dest,fs.readFileSync(src,'utf8').replaceAll('@ROOT@',root).replaceAll('@STARTED@',iso(NOW-15*60000)).replaceAll('@FINISHED@',iso(NOW-60000)));
  }
}
function githubFixture(needs=false,now=NOW){
  const raw=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/github.json'),'utf8'));
  if(!needs)raw.issues=raw.issues.filter(x=>x.number!==855);
  return p.githubData(raw.issues,raw.pulls,raw.comments,p.emptyGithub(),now);
}
function makeCases(base,revision='working tree'){
  const cases={};
  for(const name of ['overview','running','waiting','blocked','failed','finished','gap','stale','offline','unknown','leftover','ended','github-unread','needs-ryan','no-needs-ryan','night']){
    const root=path.join(base,'display-'+name),night=name==='night',issue=night?928:918;
    const next=night?[929,912,930,920,921]:[920,921];
    write(path.join(root,'codex_chain_fixture.txt'),'start Mon 11/16/2026 16:15:00\n'+issue+' start 16:15:00\n'+(name==='gap'?issue+' end 16:29:00\n':''));
    write(path.join(root,'codex_chain_fixture.bat'),'for %%N in ('+[issue,...next].join(' ')+') do call :one %%N');
    if(!night){write(path.join(root,'codex_chain_next.txt'),'waiting for codex_chain_fixture.txt');write(path.join(root,'codex_chain_next.bat'),'for %%N in (923) do call :one %%N');}
    write(path.join(root,'codex_lane_b.txt'),'waiting for codex_chain_fixture.txt');write(path.join(root,'codex_lane_b.bat'),'for %%N in (922) do call :one %%N');
    for(const [folder,n,state,age,title] of [['board',issue,name==='gap'?'checked_push':'running',15,night?'Hull hit redo: no floating ring':'Mission Control publisher'],['board_c',914,name==='failed'?'failed':'blocked',15,'Stopped predecessor'],['board_d',889,'checked_push',15,'Finished job']]){
      write(path.join(root,folder,'issue-'+n,'status.json'),name==='unknown' && folder==='board'?'{broken':JSON.stringify({run:RUN,status:state,started:iso(NOW-age*60000),reason:state==='blocked'?'chain stopped: predecessor ended unverified':state==='failed'?'runner exit 8':''}));
      write(path.join(root,folder,'issue-'+n,'log.txt'),'Codex job: issue #'+n+', "'+title+'"\nagent running');
    }
    const ds='work217/issue-916-deepseek/20261116_120000/out',ended=name==='ended';
    write(path.join(root,'work217/issue-916-deepseek/latest.txt'),path.join(root,path.dirname(ds)));
    write(path.join(root,ds,'status.json'),JSON.stringify({run:RUN,status:ended?'unverified':'running',started:iso(NOW-45*60000)}),NOW-31*60000);
    write(path.join(root,ds,'events.jsonl'),'Workhorse job: issue #916, "Stage 5 self-test repair"',NOW-31*60000);
    if(ended)write(path.join(root,ds,'result.txt'),'all done 16:29:00',NOW-60000);
    if(name==='leftover')write(path.join(root,'board/issue-944/status.json'),JSON.stringify({run:OLD,status:'running',started:iso(NOW-120*60000)}),NOW-90*60000);
    const snap=p.snapshot(root,NOW,new p.Reader(),name==='github-unread'?p.emptyGithub():githubFixture(name==='needs-ryan'));
    if(name==='offline')snap.generatedAt=iso(NOW-180001);
    snap.fixtureNow=iso(NOW);snap.fixtureRevision=revision;cases[name]=snap;
  }
  return cases;
}
function fingerprints(root){
  const out={};function walk(dir){for(const d of fs.readdirSync(dir,{withFileTypes:true})){const f=path.join(dir,d.name);if(d.isDirectory())walk(f);else out[path.relative(root,f)]=createHash('sha256').update(fs.readFileSync(f)).digest('hex')+':'+fs.statSync(f).mtimeMs;}}walk(root);return out;
}
function chain(name,text,issues=[1],extra='',at=NOW){return q.parseChain({name,text,bat:'for %%N in ('+issues.join(' ')+') do call :one %%N\n'+extra,mtime:at,batMtime:at});}
function nov17(root){
  const f=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/nov17.json'),'utf8')),now=Date.parse(f.now);
  for(const c of f.chains){write(path.join(root,c.name),c.text,c.mtime);if(!c.missingBat)write(path.join(root,c.name.replace(/\.txt$/i,'.bat')),c.bat,c.batMtime);}
  for(const j of f.jobs){
    write(path.join(root,j.out,'status.json'),JSON.stringify(j.status),now-60000);
    write(path.join(root,j.out,'result.txt'),j.result,now-60000);
    write(path.join(root,j.out,j.lane==='deepseek'?'events.jsonl':'log.txt'),j.lane==='deepseek'?'{"type":"step_start"}\n':'agent running\n',now-60000);
    if(j.lane==='deepseek')write(path.join(root,'work217/issue-983-deepseek/latest.txt'),path.dirname(path.join(root,j.out)),now-60000);
  }
  return {now,snapshot:p.snapshot(root,now)};
}
async function test(){
  const base=fs.mkdtempSync(path.join(os.tmpdir(),'mission-r3-'));let count=0;
  const check=(name,fn)=>{fn();count++;console.log('PASS '+name);};
  const pred=chain('codex_chain_16f.txt','start Mon 11/16/2026 16:00:00\n1 start 16:00:00\n1 end 16:28:00\nall done 16:28:00\n');
  const waiter=(name='codex_chain_16g.txt',target='chain 16F')=>chain(name,'waiting for '+target+' from Mon 11/16/2026 16:00:00\n',[2]);
  const resolve=(...cs)=>q.resolveQueue(cs,NOW);
  check('started then cancelled and waiting then paused take priority',()=>{
    for(const [text,state] of [['1 start 16:00:00\ncancelled by the Board 16:01: reason','cancelled'],['waiting for chain 16F\npaused by the Board 16:01: not started, nothing to save','paused'],['1 start 16:00:00\nstopped 16:01','cancelled']])assert.equal(resolve(chain('codex_chain_x.txt',text))[0].state,state);
  });
  check('ended 2 minutes ago is starting; at 40 minutes still listed and amber',()=>{
    let c=resolve(pred,waiter())[1];assert.equal(c.state,'starting');assert.equal(c.amber,false);
    c=q.resolveQueue([pred,waiter()],NOW+38*60000)[1];assert.equal(c.state,'starting');assert(c.amber);assert.match(c.reason,/40 min.*window may be closed/);
  });
  check('all done releases a successor even after failing checks',()=>assert.equal(resolve({...pred,runnerResult:'failed'},waiter())[1].state,'starting'));
  check('cancelled and paused predecessors leave waiters stuck',()=>{for(const terminal of ['cancelled','paused']){const c=resolve({...pred,terminal},waiter())[1];assert.equal(c.state,'stuck');assert.equal(c.reason,'waits on a cancelled chain');}});
  check('zero and multiple matching targets are unknown',()=>{assert.equal(resolve(waiter())[0].reason,'target not found');assert.equal(resolve(pred,{...pred},waiter())[2].reason,'target ambiguous');});
  check('two-chain cycle and its dependent stay unknown for this resolution',()=>{
    const a=waiter('codex_chain_a.txt','codex_chain_b.txt'),b=waiter('codex_chain_b.txt','codex_chain_a.txt'),c=waiter('codex_chain_c.txt','codex_chain_a.txt');
    for(const x of resolve(a,b,c)){assert.equal(x.state,'unknown');assert.equal(x.reason,'cycle');}
  });
  check('two waiters stay separate with their branching note',()=>{const cs=resolve(pred,waiter(),waiter('codex_chain_h.txt'));assert(cs.slice(1).every(c=>c.notes[0]==='2 chains wait on codex_chain_16f.txt'));});
  check('old lane, old chain and exact-file targets, with bat Path winning',()=>{
    for(const [word,file] of [['lane C32','codex_lane_c32.txt'],['chain 16F','codex_chain_16f.txt'],['codex_lane_c32.txt','codex_lane_c32.txt']])assert.equal(waiter('codex_chain_x.txt',word).waitTargets[0],file);
    const bat="powershell -Command \"while(-not (Select-String -Quiet -Path ($env:USERPROFILE+'\\Downloads\\voidsworn_test\\codex_lane_c32.txt') -Pattern 'all done')){Start-Sleep 60}\"";
    const c=chain('codex_chain_x.txt','waiting for chain 16F',[2],bat);assert.deepEqual(c.waitTargets,['codex_lane_c32.txt']);assert.equal(c.waitSource,'bat Select-String -Path');
  });
  check('supersede needs an explicit line, same lane and shared issue',()=>{
    const a=waiter(),b=chain('codex_chain_new.txt','waiting for chain 16F',[2],'',NOW+1);
    assert.equal(resolve(pred,a,b)[1].state,'starting');assert.equal(resolve(pred,a,{...b,replaces:[a.name]})[1].state,'superseded');
    assert.equal(resolve(pred,{...a,supersededBy:b.name})[1].state,'superseded');assert.equal(resolve(pred,a,{...b,id:'b',replaces:[a.name]})[1].state,'starting');
  });
  check('DeepSeek has an own issue start without a waiting line',()=>{const c=resolve(chain('ds_15v.txt','983 start Tue 11/17/2026 9:37:25\n',[983]))[0];assert.equal(c.state,'started');assert.equal(c.current,983);});
  const root=path.join(base,'real'),real=nov17(root),before=fingerprints(root);
  check('Nov 17 real files: main 982, B 975, C 985, D 984 and no phantom Next',()=>{
    for(const [id,issue] of [['main',982],['b',975],['c',985],['d',984],['deepseek',983]]){const row=lane(real.snapshot,id);assert.equal(row.current.issue,issue,id);assert.equal(row.state,'running',id);assert.deepEqual(row.next,[],id);}
    assert(lane(real.snapshot,'deepseek').source.files.includes('events.jsonl'));
  });
  check('closed issue stays listed; unresolved chain flags the lane queue',()=>{
    const r=path.join(base,'closed');write(path.join(r,'codex_chain_a.txt'),'waiting for chain missing');write(path.join(r,'codex_chain_a.bat'),'for %%N in (2) do call :one %%N');
    const g=p.githubData([{number:2,title:'Closed job',state:'closed'}],[],[],p.emptyGithub(),NOW),row=lane(p.snapshot(r,NOW,new p.Reader(),g),'main');
    assert.equal(row.queue.label,'queue unknown');assert.equal(row.next[0].githubState,'closed');assert.match(row.next[0].note,/chain still lists it/);
  });
  const out=path.join(base,'run');
  const status=(extra={})=>write(path.join(out,'status.json'),JSON.stringify({run:RUN,status:'running',started:iso(NOW-60000),...extra}),NOW-50000);
  const result=(text,at=NOW-10000)=>write(path.join(out,'result.txt'),text,at);
  const info=(deep=false)=>p.jobInfo(out,1,deep?'deepseek':'main',new p.Reader(),deep);
  status();result('job claimed: issue #1 by codex, run '+RUN+'\nusage limit hit\n');
  check('matching full run id can prove blocked',()=>assert.equal(p.classify(info()).state,'blocked'));
  result('started Mon 11/16/2026 16:00:00\njob claimed: issue #1 by codex, run '+OLD+'\nusage limit hit\nall done 16:29:00');
  check('same first 8 characters is insufficient; late old result is previous-run evidence',()=>{const j=info();assert.equal(p.classify(j).state,'running');assert.match(j.evidence[1].association,/previous run, ended/);assert.equal(j.activity,NOW-50000);});
  result('usage limit hit');
  check('untagged conflicting result against a run id means unknown',()=>{assert.equal(p.classify(info()).state,'unknown');assert.equal(p.classify(info()).reason,'result has no run id');});
  check('a mismatched result with no proof of an earlier run stays unknown',()=>{
    result('job claimed: issue #1 by codex, run '+OLD+'\nusage limit hit');assert.equal(p.classify(info()).state,'unknown');assert.match(p.classify(info()).reason,/earlier run is not proved/);result('usage limit hit');
  });
  check('DeepSeek result associates by selected directory only',()=>{assert.equal(p.classify(info(true)).state,'blocked');assert.match(info(true).evidence[1].association,/directory; no run id/);});
  result('agent running');write(path.join(out,'log.txt'),'OLD PRIVATE LOG',NOW-120000);write(path.join(out,'checks_node.txt'),'old checks',NOW-120000);
  check('old logs and checks cannot revive a new run',()=>{const j=info();assert.equal(j.activity,NOW-50000);assert(j.evidence.filter(e=>['log.txt','checks_node.txt'].includes(e.source)).every(e=>e.association==='from an earlier run'));});
  check('events after the run start count as activity',()=>{write(path.join(out,'events.jsonl'),'{"type":"step_start"}',NOW-1000);assert.equal(info().activity,NOW-1000);});
  check('checked push remains status evidence, never text alone',()=>{status({status:'checked_push'});assert.equal(p.classify(info()).state,'finished');status({status:'unverified'});assert.equal(p.classify(info()).state,'blocked');});
  check('missing status can prove failure but never checked success',()=>{const j={...info(),status:null,run:null,state:{exists:false},conflict:null,resultState:'failed'};assert.equal(p.classify(j).state,'failed');j.resultState='ended';assert.equal(p.classify(j).state,'unknown');});
  check('invalid DeepSeek latest pointer never falls back to an older run',()=>{
    const r=path.join(base,'pointer');write(path.join(r,'work217/issue-1-deepseek/latest.txt'),'C:\\private\\outside');write(path.join(r,'work217/issue-1-deepseek/20261116_100000/out/status.json'),JSON.stringify({run:RUN,status:'checked_push',started:iso(NOW-3600000)}));assert.equal(lane(p.snapshot(r,NOW),'deepseek').state,'unknown');
  });
  check('a pointer outside the job cannot select a same-named child run',()=>{
    const r=path.join(base,'same-name-pointer'),job=path.join(r,'work217/issue-1-deepseek');
    write(path.join(job,'latest.txt'),path.join(base,'outside','20261116_100000'));
    write(path.join(job,'20261116_100000/out/status.json'),JSON.stringify({run:RUN,status:'running',started:iso(NOW-60000)}));
    assert.equal(lane(p.snapshot(r,NOW),'deepseek').state,'unknown');
  });
  check('runner-managed waits require matching result evidence and can become quiet',()=>{
    const r=path.join(base,'runner-wait'),out=path.join(r,'board/issue-1');
    write(path.join(out,'status.json'),JSON.stringify({run:RUN,status:'running',started:iso(NOW-40*60000)}),NOW-31*60000);
    write(path.join(out,'result.txt'),'job claimed: issue #1 by codex, run '+RUN+'\nchain waiting for C:\\private\\status.json',NOW-31*60000);
    assert.equal(lane(p.snapshot(r,NOW-2*60000),'main').state,'waiting');assert.equal(lane(p.snapshot(r,NOW),'main').state,'quiet');
  });
  check('quiet activity and unconfirmed claim have distinct thresholds',()=>{
    const r=path.join(base,'quiet');write(path.join(r,'board/issue-1/status.json'),JSON.stringify({run:RUN,status:'running',started:iso(NOW-31*60000)}),NOW-30*60000);
    let row=lane(p.snapshot(r,NOW),'main');assert.equal(row.state,'quiet');assert(row.stale);assert.match(row.reason,/process not confirmed/);assert.equal(lane(p.snapshot(r,NOW-1),'main').state,'running');
    const claim=path.join(base,'claim');write(path.join(claim,'codex_chain_a.txt'),'1 start 16:19:00');write(path.join(claim,'codex_chain_a.bat'),'for %%N in (1) do call :one %%N');row=lane(p.snapshot(claim,NOW),'main');assert(row.claim.amber);assert.match(row.reason,/Claim not confirmed/);
  });
  const photoRoot=path.join(base,'picture-run'),repo=path.join(photoRoot,'board/repo'),photoOut=path.join(photoRoot,'board/issue-1');
  const commit='a'.repeat(40),later='b'.repeat(40),photoStart=NOW-31*60000;
  write(path.join(photoOut,'status.json'),JSON.stringify({run:RUN,status:'running',branch:'codex/issue-1',started:iso(photoStart)}),photoStart);
  write(path.join(photoOut,'base_commit.txt'),commit,photoStart+1000);
  write(path.join(photoRoot,'board/issue-2/base_commit.txt'),commit,photoStart-60000);
  function picture(name,{date=NOW-10000,source=commit,dirty=false,hash=true,side=true,extra={}}={}){
    const file=path.join(repo,'docs/shots',name),bytes=Buffer.from('picture fixture '+name);write(file,bytes,NOW-1000);
    if(side)write(file+'.provenance.json',JSON.stringify({schema:1,stage:'installed in game',date:iso(date),source_commit:source,source_dirty:dirty,image_sha256:hash?createHash('sha256').update(bytes).digest('hex'):'0'.repeat(64),...extra}),NOW-1000);
  }
  picture('shared-base.png',{dirty:true});
  check('a fresh shared-base picture stays unverified and cannot revive a quiet run',()=>{
    const row=lane(p.snapshot(photoRoot,NOW),'main');
    assert.equal(row.pictures.length,1);
    assert.equal(row.pictures[0].association,'association unverified');
    assert.equal(row.state,'quiet');
  });
  picture('old.jpg',{date:photoStart-60000});picture('unlinked.webp',{source:'c'.repeat(40)});picture('bad.png',{hash:false});picture('missing.png',{side:false});picture('excluded.gif');picture('later.png',{source:later});picture('diff.png',{source:'d'.repeat(40)});picture('large.png');write(path.join(repo,'docs/shots/large.png'),Buffer.alloc(3*1024*1024+1),NOW);
  write(path.join(photoOut,'diffstat.txt'),' docs/shots/diff.png | Bin 0 -> 100 bytes\n docs/shots/old.jpg | Bin 0 -> 100 bytes\n',NOW-1000);
  const pi=p.jobInfo(photoOut,1,'main',new p.Reader());
  const gitRead=(repo,args)=>args[0]==='symbolic-ref'?'codex/issue-1':args[0]==='log'?`${later} ${(photoStart+1000)/1000}\n${commit} ${(photoStart+1000)/1000}\n${'c'.repeat(40)} ${photoStart/1000}`:'';
  check('pictures require allowed type, size, sidecar and matching hash',()=>assert.equal(p.pictureIndex(repo,pi,new p.Reader(),gitRead).length,5));
  check('run branch and diff prove links; old dates and stages stay explicit',()=>{
    const pics=p.pictureIndex(repo,pi,new p.Reader(),gitRead);assert.deepEqual(pics.filter(x=>x.association==='this run').map(x=>x.evidence).sort(),['run branch commit','run diff']);assert.equal(pics.filter(x=>x.association==='older').length,1);assert.equal(pics.filter(x=>x.association==='association unverified').length,2);
    assert.equal(pics.find(x=>x.revision.includes('working tree')).revision,'a'.repeat(12)+' + working tree');assert(pics.every(x=>x.installedOnPC==='not tracked' && x.acceptedByRyan==='not tracked' && /^[a-f0-9]{64}$/.test(x.id)));assert(!JSON.stringify(pics).includes(repo));
  });
  check('another branch cannot prove a run picture link',()=>assert.equal(p.pictureIndex(repo,pi,new p.Reader(),()=> 'codex/issue-999').filter(x=>x.evidence==='run branch commit').length,0));
  check('cached picture hashes are rechecked after image bytes change',()=>{
    const reader=new p.Reader();assert.equal(p.pictureIndex(repo,pi,reader,gitRead).length,5);
    write(path.join(repo,'docs/shots/shared-base.png'),'changed bytes',NOW);
    assert.equal(p.pictureIndex(repo,pi,reader,gitRead).length,4);
  });
  check('sidecars can prove the run or issue, with an exact run id when given',()=>{
    picture('run.png',{extra:{run:RUN}});
    picture('issue.png',{extra:{issue:1}});
    picture('other-run.png',{extra:{run:OLD,issue:1}});
    picture('other-issue.png',{extra:{issue:2}});
    const pics=p.pictureIndex(repo,pi,new p.Reader());
    assert.deepEqual(pics.filter(x=>x.association==='this run').map(x=>x.evidence).sort(),['run diff','sidecar issue','sidecar run id']);
    assert.equal(lane(p.snapshot(photoRoot,NOW),'main').state,'running');
  });
  check('the first-parent diff of a confirmed push proves a picture link',()=>{
    const pushed='e'.repeat(40),source='f'.repeat(40);
    picture('pushed.png',{source});
    const pushedRun={...pi,status:{...pi.status,status:'unverified',commit:pushed}};
    const readGit=(repo,args)=>{
      if(args[0]==='show')return String((photoStart+1000)/1000);
      if(args[0]!=='diff')return '';
      assert(args.includes(pushed+'^1'));
      return 'docs/shots/pushed.png\0';
    };
    const readPicture=()=>p.pictureIndex(repo,pushedRun,new p.Reader(),readGit).find(x=>x.revision===source.slice(0,12));
    assert.equal(readPicture().association,'association unverified');
    write(path.join(photoOut,'confirmed_commit.txt'),pushed,NOW-1000);
    assert.equal(readPicture().evidence,'run diff');
  });
  check('scans preserve fixture sources and cache repeated bounded reads',()=>{const r=new p.Reader();p.snapshot(root,real.now,r);const bytes=r.readBytes;p.snapshot(root,real.now+1000,r);assert.equal(r.readBytes,bytes);assert.deepEqual(fingerprints(root),before);});
  await budgetTests(check);
  await paginationTests(check);
  check('privacy removes paths, users, secrets, raw logs, folder, marker and full run ids',()=>{
    const r=path.join(base,'privacy');write(path.join(r,'board/issue-1/status.json'),JSON.stringify({run:RUN,status:'failed',started:iso(NOW-60000),folder:'C:\\Users\\PrivatePerson',marker:'PRIVATE-MARKER',title:'C:\\Users\\PrivatePerson ghp_FIXTURESECRET',reason:'runner exit 14 RAW-LOG-SENTINEL',github:{folder:'PRIVATE',marker:'PRIVATE'}}));write(path.join(r,'board/issue-1/log.txt'),'RAW-LOG-SENTINEL ghp_FIXTURESECRET');
    const json=JSON.stringify(p.snapshot(r,NOW));assert(!/C:\\\\|PrivatePerson|\brcbai\b|ghp_|github_pat_|RAW-LOG-SENTINEL|PRIVATE-MARKER|"folder"|"marker"/.test(json));assert(!json.includes(RUN));assert.match(json,/Runner exit 14/);if(process.env.USERNAME)assert.match(p.cleanTitle(process.env.USERNAME+' private notes',1),/withheld/);
  });
  check('runtime hash covers every served asset, dependency, phone and optional manifest',()=>{
    const target=path.join(base,'build/tools/pc/mission');fs.mkdirSync(target,{recursive:true});for(const name of p.RUNTIME_FILES){const src=path.resolve(__dirname,name),dest=path.resolve(target,name);write(dest,fs.existsSync(src)?fs.readFileSync(src):'{}');}
    const initial=p.buildHash(target);for(const name of p.RUNTIME_FILES){const file=path.resolve(target,name),bytes=fs.readFileSync(file);fs.appendFileSync(file,' ');assert.notEqual(p.buildHash(target),initial,name);assert(p.buildInfo({id:initial},target).stale,name);fs.writeFileSync(file,bytes);}assert.equal(p.buildHash(target),initial);assert.equal(p.buildInfo().stale,false);
  });
  check('output paths refuse job roots and junctions',()=>{
    for(const folder of ['board','board_c/issue-1','queue','build_b/tools','work217'])assert.throws(()=>p.options(['--root',base,'--out',path.join(base,folder)]));const link=path.join(base,'link');fs.symlinkSync(root,link,process.platform==='win32'?'junction':'dir');assert.throws(()=>p.writeSnapshot(link,real.snapshot));
  });
  const originalFetch=global.fetch;
  try{global.fetch=async()=>new Response('[]');await httpTests(check,base,root);await require('./phone_selftest').test(check,base,root);}finally{global.fetch=originalFetch;}
  console.log('PASS mission r3: '+count+' checks; fixtures and logs kept in '+base);return {base,cases:makeCases(base)};
}
async function budgetTests(check){
  const requests=[],reader=new p.GithubReader(async(url,opts)=>{requests.push({url,opts});return new Response('[]');});
  for(let minute=0;minute<=3;minute++)await reader.update(NOW+minute*60000);
  check('cold start spreads sources over three minutes using unauthenticated GETs',()=>{assert.equal(requests.length,4);assert(requests[0].url.includes('labels=ryan'));assert(requests.every(r=>r.opts.method==='GET' && !r.opts.headers.Authorization));assert(reader.data.coverageComplete);assert(Object.values(reader.data.sources).every(s=>s.complete && s.lastAttemptAt && s.lastSuccessfulReadAt));});
  let pages=0;const paged=new p.GithubReader(async()=>{pages++;return new Response('[]',{headers:pages<3?{Link:'<https://api.github.com/fixed>; rel="next"'}:{}});});await paged.update(NOW);
  check('three pages spend three requests from the shared budget',()=>{assert.equal(pages,3);assert.equal(paged.data.budget.requestsPastHour,3);assert(paged.data.sources.questions.complete);});
  let calls=0;const initial=p.emptyGithub();initial.needsRyan=[{issue:855,title:'Existing question'}];
  const partial=new p.GithubReader(async url=>{calls++;return !url.includes('labels=ryan')?new Response('[]'):url.endsWith('page=1')?new Response('[]',{headers:{Link:'<https://api.github.com/fixed>; rel="next"'}}):new Response('',{status:500});},initial);await partial.update(NOW);
  check('page two failure leaves questions not fully checked and retains last good questions',()=>{assert.equal(calls,2);assert(!partial.data.coverageComplete);assert.match(partial.data.sources.questions.reason,/not fully checked/);assert.equal(partial.data.needsRyan[0].issue,855);assert.equal(partial.data.sources.questions.lastSuccessfulReadAt,null);});
  await partial.update(NOW+10*60000);
  check('retries spend the same budget; failure backs off 10 then 20 minutes',()=>{assert.equal(partial.budget.requests.length,calls);assert.equal(partial.data.sources.questions.nextAttemptAt,iso(NOW+30*60000));});
  await partial.update(NOW+30*60000);assert.equal(partial.data.sources.questions.nextAttemptAt,iso(NOW+70*60000));await partial.update(NOW+70*60000);
  check('continued failure backs off 40 then 60 minutes',()=>assert.equal(partial.data.sources.questions.nextAttemptAt,iso(NOW+130*60000)));
  let pacedCalls=0;
  const paced=new p.GithubReader(async url=>{pacedCalls++;return new Response('[]',{headers:url.includes('labels=ryan') && !url.endsWith('page=4')?{Link:'<https://api.github.com/fixed>; rel="next"'}:{}});});
  await paced.update(NOW);assert.equal(pacedCalls,3);assert(!paced.data.coverageComplete);
  await paced.update(NOW+60000);
  check('cold pagination stops at three requests per minute and resumes the next page',()=>{assert(paced.data.coverageComplete);assert.equal(pacedCalls,5);});
  let total=0;const hour=new p.GithubReader(async()=>{total++;return new Response('[]',{headers:{Link:'<https://api.github.com/fixed>; rel="next"'}});});for(let minute=0;minute<60;minute++)await hour.update(NOW+minute*60000);
  check('pagination and retries together cannot exceed 30 requests per hour',()=>{assert.equal(total,30);assert.equal(hour.budget.requests.length,30);});
  const b=new Budget();b.spend(NOW);b.headers(new Headers({'x-ratelimit-remaining':'15','x-ratelimit-reset':String((NOW+3600000)/1000)}),200,NOW);
  check('remaining 15 pauses all reads until reset',()=>{assert(!b.canSpend(NOW+3599999));assert(b.canSpend(NOW+3600000));});
  let limitedCalls=0;const limited=new p.GithubReader(async()=>{limitedCalls++;return new Response('',{status:403,headers:{'x-ratelimit-reset':String((NOW+600000)/1000)}});});await limited.update(NOW);await limited.update(NOW+659999);
  check('403 pauses until reset plus a minute and then recovers',()=>{assert.equal(limitedCalls,1);assert(!limited.budget.canSpend(NOW+659999));assert(limited.budget.canSpend(NOW+660000));});limited.fetcher=async()=>new Response('[]');await limited.update(NOW+660000);assert(limited.data.sources.questions.complete);
  const source=new p.GithubReader(async url=>new Response(url.includes('/pulls?')?'':'[]',{status:url.includes('/pulls?')?500:200}));for(let minute=0;minute<=3;minute++)await source.update(NOW+minute*60000);
  check('one failed source does not erase the other source reads',()=>{assert(source.data.sources.questions.complete);assert(source.data.sources.issues.complete);assert(!source.data.sources.pulls.complete);assert(source.data.sources.comments.complete);assert(source.data.coverageComplete);});
  check('per-source ages use twice each source interval',()=>{
    const g=reader.data, snap=p.snapshot(path.join(os.tmpdir(),'mission-no-such-source'),NOW+22*60000,new p.Reader(),g);
    assert(snap.github.sources.questions.stale);assert(!snap.github.sources.comments.stale);
  });
  check('429 also pauses globally, even without reset headers',()=>{
    const budget=new Budget();budget.headers(new Headers(),429,NOW);assert(!budget.canSpend(NOW+3600000));assert(budget.canSpend(NOW+3660000));
  });
  check('encoded credentials in a picture link are withheld',()=>{
    const g=p.githubData([{number:1,title:'Safe',state:'open',labels:['ryan'],body:'Ask Ryan: Pick this? | Picture: https://github.com/rcbailey12/voidsworn/blob/main/%67hp_FIXTURESECRET.png'}],[],[],p.emptyGithub(),NOW);assert.equal(g.needsRyan[0].picture,null);
  });
  check('GitHub crew stays dated, issue state is kept, comments remain private',()=>{const g=githubFixture(true);assert(g.crew.artoo && g.crew.muse && g.crew.claude);assert(!JSON.stringify(g).includes('Private fixture comment'));assert(g.issues.every(i=>['open','closed','unknown'].includes(i.state)));});
  check('Ryan questions require open state, label and an unfenced marker',()=>{const issue={number:1,title:'Question',state:'open',labels:['ryan'],body:'Ask Ryan: Pick this? | Picture: https://github.com/rcbailey12/voidsworn/issues/1'};assert.equal(p.githubData([issue],[],[],p.emptyGithub(),NOW).needsRyan.length,1);for(const extra of [{state:'closed'},{labels:[]},{body:'```\n'+issue.body+'\n```'}])assert.equal(p.githubData([{...issue,...extra}],[],[],p.emptyGithub(),NOW).needsRyan.length,0);});
}
async function paginationTests(check){
  const fixture=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/github.json'),'utf8'));
  for(const name of ['issues','comments']){
    const comments=name==='comments';
    const start=NOW+(comments?3:1)*60000, finish=start+60000, updatedAt=iso(start+30000);
    const existing={...fixture[name][0],updated_at:iso(start-500)};
    const late={...existing,updated_at:updatedAt,...(comments?{id:124,issue_url:existing.issue_url.replace('/937','/996')}:{number:989,title:'Update during sweep'})};
    const duplicate=comments?{...existing,id:125,issue_url:existing.issue_url.replace('/937','/998'),updated_at:iso(start-250)}:existing;
    const repeated=comments?{...duplicate,body:'Ordinary edited comment',updated_at:iso(start+10000)}:{...duplicate,title:'Earlier title',updated_at:iso(start-750)};
    const nextPage={Link:'<https://api.github.com/fixed>; rel="next"'};
    let pages=0;
    const reader=new p.GithubReader(async raw=>{
      const url=new URL(raw);
      const endpoint=url.pathname.endsWith(comments?'/issues/comments':'/issues');
      if(!endpoint || !url.searchParams.has('since'))return new Response('[]');
      const page=Number(url.searchParams.get('page'));
      const since=Date.parse(url.searchParams.get('since'));
      pages++;
      if(pages<=4){
        // The new record moves into page one after we have read it. Page four repeats a record shifted by that insert.
        const items=page===1?(comments?[existing,duplicate]:[existing]):page===4?[repeated]:[];
        return new Response(JSON.stringify(items),{headers:page<4?nextPage:{}});
      }
      return new Response(JSON.stringify([late,existing,repeated].filter(item=>Date.parse(item.updated_at)>since)));
    });
    for(let now=NOW;now<=start;now+=60000)await reader.update(now);
    assert.equal(pages,3);
    assert.equal(reader.data.sources[name].complete,false);
    await reader.update(finish);
    assert.equal(pages,4);
    assert.equal(reader.data.sources[name].lastSuccessfulReadAt,iso(finish));
    check(`the ${name} sweep keeps the newest version when pages repeat an id`,()=>{
      if(comments)assert.equal(reader.data.crew.artoo.number,937);
      else assert.deepEqual(reader.data.issues.filter(x=>x.number===existing.number).map(x=>x.title),[existing.title]);
    });
    const next=finish+reader.data.sources[name].intervalSeconds*1000;
    await reader.update(next);
    if(pages===4)await reader.update(next+60000);
    check(`the next ${name} sweep recovers an update that landed between pages one and four`,()=>{
      assert.equal(pages,5);
      if(comments)assert.deepEqual([reader.data.crew.artoo.number,reader.data.crew.artoo.at],[996,updatedAt]);
      else {
        assert.equal(reader.data.issues.find(x=>x.number===989)?.updatedAt,updatedAt);
        assert.deepEqual(reader.data.issues.filter(x=>x.number===existing.number).map(x=>x.title),[existing.title]);
      }
      assert(reader.data.sources[name].complete);
    });
  }
}
async function httpTests(check,base,root){
  const reserve=http.createServer();await new Promise(r=>reserve.listen(0,'127.0.0.1',r));const port=reserve.address().port;await new Promise(r=>reserve.close(r));
  const server=p.serve(p.options(['--root',root,'--out',path.join(base,'served'),'--port',String(port)]),()=>({host:null}));await new Promise((resolve,reject)=>{server.once('listening',resolve);server.once('error',reject);});
  const request=(route,headers={})=>new Promise((resolve,reject)=>{http.get({host:'127.0.0.1',port,path:route,headers},res=>{let text='';res.on('data',d=>text+=d);res.on('end',()=>resolve({code:res.statusCode,text,headers:res.headers}));}).on('error',reject);});
  try{
    const status=await request('/status.json'),page=await request('/');
    check('loopback server serves schema 2 and the compatibility page accepts both schemas',()=>{assert.equal(JSON.parse(status.text).schemaVersion,2);assert.match(page.text,/!\[1,2\]\.includes\(v.schemaVersion\)/);assert.equal(status.headers['cache-control'],'no-store');assert.equal(server.address().address,'127.0.0.1');});
    for(const route of ['/pic/anything','/../board/issue-1/log.txt','/fixtures/nov17.json'])assert.equal((await request(route)).code,404);check('there is no picture route or arbitrary file route',()=>{});
    assert.equal((await request('/',{Host:'outsider.example'})).code,403);for(const name of ['artoo.svg','ChakraPetch-SemiBold.ttf','Barlow-Regular.ttf','AzeretMono-VF.ttf'])assert.equal((await request('/'+name)).code,200);check('fixed assets render and host checks remain enforced',()=>{});
  }finally{await new Promise(r=>server.close(r));}
}
module.exports={NOW,copyFixture,makeCases,test};
if(require.main===module)test().catch(e=>{console.error('FAIL mission r3: '+e.stack);process.exitCode=1;});
