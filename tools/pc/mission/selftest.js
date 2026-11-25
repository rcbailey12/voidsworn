'use strict';
// All writes use new TEMP directories. No live jobs, Serve changes or commits.
const assert=require('assert/strict');
const fs=require('fs'),os=require('os'),path=require('path'),http=require('http');
const {createHash}=require('crypto');
const {EventEmitter}=require('events');
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
function chainHistoryFixture(root, now) {
  const old = now-90*60000, current = now-45*60000;
  const clock = timestamp => new Date(timestamp).toTimeString().slice(0,8);
  for (const [issue,at] of [[944,old],[1033,current]]) {
    const stem = path.join(root,`codex_lane_c${issue}`);
    write(stem+'.txt',`${issue} start ${clock(at)}`,at);
    write(stem+'.bat',`for %%N in (${issue}) do call :one %%N`,at);
  }
  write(path.join(root,'board_c/issue-1033/status.json'),JSON.stringify({run:RUN,status:'running',
    title:'Check the lane handoff',started:iso(current)}),current);
  const legacy = path.join(root,'work217/issue-932-deepseek');
  write(path.join(legacy,'latest.txt'),legacy+path.sep,old);
  write(path.join(legacy,'out/result.txt'),'started earlier',old);
  write(path.join(legacy,'out/events.jsonl'),'{}',old);
  const github = githubFixture(false,now);
  for (const source of Object.values(github.sources)) {
    Object.assign(source,{complete:true,lastSuccessfulReadAt:iso(now),lastAttemptAt:iso(now)});
  }
  return {data:p.snapshot(root,now,new p.Reader(),github),pictures:new Map()};
}
function makeCases(base) {
  const deck = require('./fixtures/deck.json');
  const now = Date.parse(deck.now), minute = 60000, repo = path.resolve(__dirname,'../../..');
  const nowText = timestamp => new Date(timestamp).toTimeString().slice(0,8);
  const raw = require('./fixtures/github.json');
  const flight = require('./fixtures/flight_plan.json');
  const sourceNames = ['questions','issues','pulls','comments'];
  const outageCases = sourceNames.map(name=>'github-'+name);
  const values = ['overview','task','decision','failure','offline','unknown','no-picture','missing-picture','queue','queue-photo','crew',
    'blocked','quiet','checked-push','ended','leftover','claim','claim-old','github-unread','legacy','no-build','old-build',
    'starting','long-title','privacy','legacy-listing','pr-only','pr-merged','pr-closed','review','needs-ryan','question-partial',
    'pc-partial','running-closed-issue','running-closed-issue-stale','finished-closed-issue',...outageCases];
  const cases = {};
  for (const name of values) {
    const finishedClosedIssue = name==='finished-closed-issue';
    const staleIssueRead = name==='running-closed-issue-stale';
    const root = path.join(base,'display-'+name);
    const put = (file,contents,at=now-minute) => write(path.join(root,file),contents,at);
    function chainFile(file, log, issues, at = now-minute, bat = '') {
      put(file+'.txt',log,at);
      put(file+'.bat','for %%N in ('+issues.join(' ')+') do call :one %%N\n'+bat,at);
    }
    function runner(folder, issue, title, state, start, reason = '', last = now-minute) {
      const prefix = folder+'/issue-'+issue+'/';
      put(prefix+'status.json',JSON.stringify({title,run:RUN,status:state,started:iso(start),reason,
        finished:state==='running' ? null : iso(last)}),last);
      put(prefix+'log.txt','agent running',last);
    }
    function fixturePicture(folder,key) {
      const {file,issue,decisionOption} = deck.pictures[key], original = path.join(repo,file);
      const destination = folder+'/repo/'+file;
      const stamp = JSON.parse(fs.readFileSync(original+'.provenance.json','utf8'));
      put(destination,fs.readFileSync(original));
      put(destination+'.provenance.json',JSON.stringify({...stamp,issue,decisionOption,
        ...(key==='hero' ? {date:iso(now-4*minute),run:RUN} : {})}));
    }
    const start = Date.parse('2026-11-17T10:21:00Z'), claimStart = now-(name==='claim-old' ? 11 : 9)*minute;
    const chainStart = name.startsWith('claim') ? claimStart : start;
    const chainEnd = name==='queue' ? now-40*minute : name==='queue-photo' || finishedClosedIssue ? now-2*minute : null;
    const chainLog = '970 start '+nowText(chainStart)+(chainEnd ? '\n970 end '+nowText(chainEnd)+'\nall done '+nowText(chainEnd) : '');
    chainFile('codex_chain_fixture',chainLog,[970],chainEnd || chainStart);
    for (const [file,log,list] of [
      ['codex_chain_next','waiting for codex_chain_fixture.txt',name==='queue-photo' ? [923] : [982,923]],
      ['codex_lane_b25','waiting for codex_chain_fixture.txt\ncancelled by the Board',[922]],
      ['codex_lane_d11','waiting for codex_chain_fixture.txt',[984]]
    ]) chainFile(file,log,list);
    if (name==='queue') {
      chainFile('codex_chain_other','920 start '+nowText(now-70*minute),[920],now-70*minute);
      for (const {file,target,issues,alternative} of flight.chains) {
        const command = target => 'findstr /c:"all done" "%V%\\'+target+'" >nul';
        chainFile(file,'waiting for '+target,issues,now-minute,alternative ? [command(target),command(alternative)].join('\n') : command(target));
      }
    }
    if (name==='unknown') chainFile('codex_chain_unclear','waiting for codex_chain_missing.txt',[988]);
    const title = name==='long-title' ? 'L'.repeat(240) : name==='privacy' ?
      (process.env.USERNAME || 'PrivatePerson')+' C:\\Users\\PrivatePerson\\log.txt' : 'Iron Mandate: bow ion gun';
    if (name==='unknown') {
      put('board/issue-970/status.json','{broken');
      put('board/issue-970/log.txt','Codex job: issue #970, "Iron Mandate: bow ion gun"');
    } else if (!name.startsWith('claim')) {
      runner('board',970,title,name==='checked-push' || chainEnd ? 'checked_push' : 'running',start);
    }
    if (name==='failure') {
      runner('board_b',928,'Hull hit redo', 'failed', now-18*minute,'runner exit 8',now-10*minute);
      fixturePicture('board_b','hull');
    } else runner('board_b',975,'Station T2: paint and fine detail','running',now-8*minute);
    runner('board_c',978,'Parity speed-up: parallel battles',name==='blocked' ? 'blocked' : 'running',now-10*minute,
      'chain stopped: predecessor ended unverified',now-2*minute);
    runner('board_d',979,'Rules safety net: cache check','running',now-60*minute,'',now-34*minute);
    if (!['no-picture','long-title','privacy','unknown'].includes(name)) {
      fixturePicture('board','hero');
      fixturePicture('board','unlinked');
    }
    if (name==='decision') {
      fixturePicture('board','egg');
      fixturePicture('board','fitted');
    }
    if (name==='leftover') runner('board',944,'Earlier run','running',now-120*minute,'',now-90*minute);
    if (name==='ended') {
      put('work217/issue-916-deepseek/latest.txt','20261117_120000');
      put('work217/issue-916-deepseek/20261117_120000/out/status.json',
        JSON.stringify({title:'Stage 5 self-test repair',run:RUN,status:'unverified',started:iso(now-45*minute),finished:iso(now-minute)}));
      put('work217/issue-916-deepseek/20261117_120000/out/result.txt','all done '+nowText(now-minute));
    } else {
      put('work217/issue-916-deepseek/latest.txt','20261117_120000');
      put('work217/issue-916-deepseek/20261117_120000/out/status.json',
        JSON.stringify({title:'Stage 5 self-test repair',run:RUN,status:'running',started:iso(now-15*minute)}),now-2*minute);
    }
    if (name==='crew') {
      put('work217/issue-916-openai/latest.txt','20261117_130000');
      put('work217/issue-916-openai/20261117_130000/out/status.json',JSON.stringify({title:'OpenAI workhorse patch',
        branch:'work/issue-916-openai',run:OLD,status:'running',started:iso(now-10*minute)}),now-minute);
    }
    const issues = raw.issues.filter(issue=>issue.number!==855 && issue.number!==929).concat(
      {number:982,title:'Measure storm map cost at 4K',state:name==='queue' ? 'closed' : 'open',updated_at:iso(now-20*minute)},
      {number:970,title:'Iron Mandate: bow ion gun',state:name.includes('closed-issue') ? 'closed' : 'open',
        updated_at:iso(finishedClosedIssue ? now-30000 : now-minute*(staleIssueRead ? 70 : 20))},
      {number:929,title:'Shield hit look',state:'open',labels:name==='decision' ? ['ryan'] : [],
        updated_at:iso(now-41*minute),body:'Ask Ryan: Keep the egg shield as the default, or switch to the fitted skin? | Picture: https://github.com/rcbailey12/voidsworn/issues/929'}
    );
    for (const [number,title] of Object.entries(flight.titles)) issues.push({number:+number,title,state:'open',updated_at:iso(now-minute)});
    if (['needs-ryan','question-partial'].includes(name)) for (const ask of flight.questions) issues.push({...ask,updated_at:iso(now-6*minute)});
    if (name==='privacy') {
      issues.find(issue=>issue.number===970).title = (process.env.USERNAME || 'PrivatePerson')+' C:\\Users\\PrivatePerson\\status.json';
      const folder = 'board/issue-970/';
      const status = JSON.parse(fs.readFileSync(path.join(root,folder,'status.json'),'utf8'));
      put(folder+'status.json',JSON.stringify({...status,folder:'C:\\Private\\FOLDER-SENTINEL',marker:'MARKER-SENTINEL'}));
      put(folder+'log.txt','RAW-LOG-SENTINEL');
    }
    const fixturePull = (number,ref) => ({...raw.pulls[1],number,updated_at:iso(now-4*minute),head:{...raw.pulls[1].head,ref}});
    const pr = fixturePull(1008,'codex/issue-970');
    pr.head.sha = 'b'.repeat(40);
    if (['pr-merged','pr-closed'].includes(name)) pr.state = 'closed';
    if (name==='pr-merged') pr.merged_at = iso(now-2*minute);
    const comments = [...raw.comments];
    if (name==='review') comments.push({id:999,issue_url:'https://api.github.com/repos/rcbailey12/voidsworn/issues/1008',
      body:'Artoo (technical review): read commit bbbbbbbbbbbb.',updated_at:iso(now-minute)});
    const github = p.githubData(issues,[...raw.pulls,pr,fixturePull(1005,'work/issue-1005-openai')],comments,p.emptyGithub(),now);
    for (const source of sourceNames) {
      const incomplete = name==='github-'+source || name==='question-partial' && source==='questions';
      const stale = staleIssueRead && source==='issues';
      const readAt = finishedClosedIssue && source==='issues' ? now-10000 : now-3*minute;
      Object.assign(github.sources[source],{
        complete:!incomplete,
        lastSuccessfulReadAt:iso(incomplete || stale ? now-65*minute : readAt),
        lastAttemptAt:iso(stale ? now-65*minute : readAt),nextAttemptAt:iso(now+7*minute),
        reason:incomplete ? name==='question-partial' ? 'Read incomplete: shared GitHub budget paused' : 'GitHub returned HTTP '+(501+sourceNames.indexOf(source)) : null
      });
    }
    github.lastReadAt = iso(now-3*minute);
    github.budget = {requestsPastHour:12,ceilingPerHour:30};
    const reader = new p.Reader();
    reader.pictureFiles = new Map();
    if (name==='pc-partial') {
      p.snapshot(root,now-3*minute,reader,github);
      put('codex_chain_missing_script.txt','waiting for codex_chain_fixture.txt');
    }
    let data = p.snapshot(root,now,reader,name==='github-unread' ? p.emptyGithub() : github);
    if (name==='legacy-listing') {
      for (const lane of data.lanes) { delete lane.queue; lane.next = []; }
      data.lanes[0].next = [{issue:922,title:'Old station frame listing'}];
    }
    if (name==='legacy') {
      data.schemaVersion = 1;
      delete data.github.sources;
      for (const lane of data.lanes) { delete lane.queue; delete lane.pictures; }
    }
    if (name==='legacy' || name==='no-build') delete data.build;
    if (name==='old-build') data.build.stale = true;
    if (name==='starting') data = {schemaVersion:2,state:'starting',generatedAt:null,lanes:[],build:data.build};
    cases[name] = {data,pictures:name==='missing-picture' ? new Map() : reader.pictureFiles};
    if (name==='offline') cases[name].now = now+19*minute;
  }
  const record = nov17(path.join(base,'display-nov17'));
  cases.nov17 = {data:record.snapshot,pictures:new Map(),now:record.now};
  cases['chain-history'] = chainHistoryFixture(path.join(base,'display-chain-history'),now);
  return {cases,now};
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
  check('cancelled and paused predecessors leave waiters stuck',()=>{for(const terminal of ['cancelled','paused']){const c=resolve({...pred,terminal},waiter())[1];assert.equal(c.state,'stuck');assert.equal(c.reason,'waits on a '+terminal+' chain');}});
  check('zero and multiple matching targets are unknown',()=>{assert.equal(resolve(waiter())[0].reason,'target not found');assert.equal(resolve(pred,{...pred},waiter())[2].reason,'target ambiguous');});
  check('two-chain cycle and its dependent stay unknown for this resolution',()=>{
    const a=waiter('codex_chain_a.txt','codex_chain_b.txt'),b=waiter('codex_chain_b.txt','codex_chain_a.txt'),c=waiter('codex_chain_c.txt','codex_chain_a.txt');
    for(const x of resolve(a,b,c)){assert.equal(x.state,'unknown');assert.equal(x.reason,'cycle');}
  });
  check('two waiters stay separate with their branching note',()=>{const cs=resolve(pred,waiter(),waiter('codex_chain_h.txt'));assert(cs.slice(1).every(c=>c.notes[0]==='2 chains share this predecessor; their order is unverified'));});
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
  check('OpenAI findstr wait names the actual predecessor and keeps the OpenAI lane',()=>{
    const first=chain('oa_1005b.txt','1 start 16:00:00\n1 end 16:28:00\nall done 16:28:00',[1]);
    const next=chain('oa_1021.txt','waiting for oa_1005b',[2],'findstr /c:"all done" "%V%\\oa_1005b.txt" >nul');
    const c=resolve(first,next)[1];
    assert.equal(c.id,'openai');assert.equal(c.state,'starting');assert.equal(c.predecessorIssue,1);assert.equal(c.waitSource,'bat findstr');
  });
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
  check('a later start moves an old chain to history and leaves a genuinely stuck chain in attention',()=>{
    const {data} = chainHistoryFixture(path.join(base,'chain-history'),NOW), row = lane(data,'c');
    assert.deepEqual(row.queue.history.map(h=>[h.chain,h.state]),[['codex_lane_c944.txt','superseded']]);
    assert.deepEqual(row.queue.groups.map(g=>[g.predecessor.issue,g.attention]),[[1033,'Old chain has no recorded ending.']]);
    assert(data.pcSource.complete);
    const legacy = lane(data,'deepseek');
    assert.equal(legacy.current.issue,932);
    assert.equal(legacy.state,'unknown');
    assert(legacy.source.files.includes('events.jsonl'));
  });
  check('old chains need ending evidence for every job and cannot release a text wait without all done',()=>{
    const r = path.join(base,'mixed-endings'), at = NOW-80*60000, finish = NOW-70*60000;
    write(path.join(r,'codex_chain_endings.txt'),'1 start 15:00:00\n1 end 15:05:00\n2 start 15:10:00',at);
    write(path.join(r,'codex_chain_endings.bat'),'for %%N in (1 2 3 4) do call :one %%N',at);
    write(path.join(r,'board/issue-2/status.json'),JSON.stringify({run:RUN,status:'failed',started:iso(at),finished:iso(finish)}),finish);
    write(path.join(r,'codex_lane_b_wait.bat'),'for %%N in (5) do call :one %%N',at);
    write(path.join(r,'codex_lane_b_wait.txt'),'waiting for codex_chain_endings.txt',at);
    const pull = {number:6,state:'closed',merged_at:iso(finish),base:{repo:{full_name:'rcbailey12/voidsworn'}},
      head:{ref:'codex/issue-3',repo:{full_name:'rcbailey12/voidsworn'}}};
    const close = {number:4,state:'closed',closed_at:iso(finish)};
    const snap = (issue,pr) => p.snapshot(r,NOW,new p.Reader(),p.githubData([issue],[pr],[],p.emptyGithub(),NOW));
    for (const data of [snap({...close,state:'open'},pull),snap({...close,closed_at:iso(at-3600000)},pull),
      snap(close,{...pull,merged_at:null}),snap(close,{...pull,merged_at:iso(at-3600000)})]) {
      assert.equal(lane(data,'main').queue.groups[0].attention,'Old chain has no recorded ending.');
    }
    const data = snap(close,pull);
    assert.deepEqual(lane(data,'main').queue.groups,[]);
    assert.equal(lane(data,'main').queue.history[0].reason,'All listed jobs have ending evidence.');
    assert.equal(lane(data,'b').queue.groups[0].state,'unknown');
    assert.match(lane(data,'b').queue.groups[0].reason,/no recorded all done marker/);
  });
  check('independent chains keep distinct predecessors beside an unknown chain on the same lane',()=>{
    const r=path.join(base,'mixed');
    for (const [name,log,issues] of [['root','1 start 16:20:00',[1,2]],['other','3 start 16:20:00',[3]],
      ['first','waiting for chain root',[4]],['second','waiting for chain other',[5]],['missing','waiting for chain missing_target',[6]]]) {
      write(path.join(r,`codex_chain_${name}.txt`),log);
      write(path.join(r,`codex_chain_${name}.bat`),'for %%N in ('+issues.join(' ')+') do call :one %%N');
    }
    const row=lane(p.snapshot(r,NOW),'main'), group=issue=>row.queue.groups.find(g=>g.jobs.some(j=>j.issue===issue));
    assert.equal(row.queue.state,'unknown');
    assert.equal(group(2).state,'started');assert.equal(group(2).predecessor.issue,1);
    assert.equal(group(4).state,'linked');assert.equal(group(4).predecessor.issue,2);
    assert.equal(group(5).predecessor.issue,3);assert.equal(group(5).notes.length,0);
    assert.equal(group(6).reason,'target not found');assert.equal(group(6).after,'codex_chain_missing_target.txt');
    assert.match(row.reason,/same time/);
  });
  check('OpenAI and both DeepSeek folder arms stay isolated even for the same issue',()=>{
    const root=path.join(base,'seats'), stamp='20261116_160000';
    const placed = (arm, branchArm, run, result='agent running') => {
      const job=path.join(root,`work217/issue-37-${arm}`);
      write(path.join(job,'latest.txt'),stamp);
      write(path.join(job,stamp,'out/status.json'),JSON.stringify({run,title:'Run for '+branchArm,status:'running',
        started:iso(NOW-60000),branch:'work/issue-37-'+branchArm}));
      write(path.join(job,stamp,'out/result.txt'),result);
    };
    placed('deepseek','deepseek',RUN); placed('openai','openai',OLD);
    let snap=p.snapshot(root,NOW);
    assert.equal(lane(snap,'openai').current.branch,'work/issue-37-openai');assert.equal(lane(snap,'openai').state,'running');
    assert.equal(lane(snap,'deepseek').current.branch,'work/issue-37-deepseek');assert.equal(lane(snap,'deepseek').state,'running');
    placed('openai','deepseek',RUN);
    snap=p.snapshot(root,NOW);
    assert.equal(lane(snap,'openai').state,'unknown');assert.equal(lane(snap,'openai').run,null);
    placed('openai','openai',OLD,'job claimed: issue #37 by deepseek, run '+OLD);
    assert.equal(lane(p.snapshot(root,NOW),'openai').state,'unknown');
    placed('deepseek','openai',OLD);
    assert.equal(lane(p.snapshot(root,NOW),'deepseek').state,'unknown');
    placed('deepseekpro','deepseekpro',RUN);
    const pro=p.readJobs(root,p.SEATS.find(([id])=>id==='deepseek'),new p.Reader()).find(j=>j.job.branch.endsWith('-deepseekpro'));
    assert.equal(p.classify(pro).state,'running');
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
    const data = p.snapshot(r,NOW);
    assert.equal(lane(data,'deepseek').state,'unknown');
    assert.match(data.pcSource.reason,/work217\/issue-1-deepseek\/latest\.txt: expected the issue folder/);
    assert(!data.pcSource.reason.includes(base));
  });
  check('missing workhorse directories and pointers identify the expected source',()=>{
    const r=path.join(base,'missing-run'), job=path.join(r,'work217/issue-2-openai'), stamp='20261116_100000';
    write(path.join(job,'latest.txt'),path.join(job,stamp));
    fs.mkdirSync(path.join(r,'work217/issue-3-deepseek'));
    const reasons = () => p.snapshot(r,NOW).pcSource.reason;
    assert.match(reasons(),/work217\/issue-2-openai\/20261116_100000: file or folder missing/);
    assert.match(reasons(),/work217\/issue-3-deepseek\/latest\.txt: file or folder missing/);
    fs.mkdirSync(path.join(job,stamp));
    assert.match(reasons(),/work217\/issue-2-openai\/20261116_100000\/out: file or folder missing/);
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
  check('every page icon is a served file on the shared grid',()=>{
    const page = path.resolve(__dirname,'../../../docs/mission');
    const html = fs.readFileSync(path.join(page,'index.html'),'utf8');
    const icons = [...html.matchAll(/['"](\/(?:crew|icons)\/[a-z]+\.svg)['"]/g)].map(match=>match[1]);
    assert.deepEqual([...new Set(icons)].sort(),Object.keys(p.ASSETS).filter(route=>/^\/(?:crew|icons)\//.test(route)).sort());
    assert.equal(icons.length,12);
    for (const route of icons) {
      assert.equal(p.ASSETS[route],'image/svg+xml',route);
      const svg = fs.readFileSync(path.join(page,route.slice(1)),'utf8');
      assert.match(svg,/viewBox="0 0 24 24".*stroke-width="1\.5"/);
    }
  });
  check('deploy backs up both folders, targets the installed Node script and checks the whole HTTP build before keeping it',()=>{
    const deploy = fs.readFileSync(path.join(__dirname,'deploy.ps1'),'utf8');
    assert.match(deploy,/\[string\]\$MainCheckout/);
    assert.match(deploy,/\$pair = @\('tools\\pc\\mission', 'docs\\mission'\)/);
    assert.match(deploy,/Copy-MissionPair \$checkout \$candidate \$true[\s\S]+Copy-MissionPair \$installed[^\n]+[\s\S]+\$stopAttempted = \$true[\s\S]+Stop-InstalledPublisher[\s\S]+::Move\(\$candidate, \$installed\)/);
    assert.match(deploy,/Win32_Process -Filter "Name = 'node\.exe'"[\s\S]+\$words\[1\][\s\S]+GetFullPath\(\$scriptArg\) -eq \$installedPublisher[\s\S]+\$same[\s\S]+Stop-Process -Id \$process\.ProcessId/);
    assert.match(deploy,/rev-parse HEAD[\s\S]+build\.json[\s\S]+id:p\.buildHash\(\), assets:p\.ASSETS/);
    assert.match(deploy,/-WindowStyle Hidden/);
    assert.match(deploy,/GetAsync\("http:\/\/127\.0\.0\.1:\$Port\$Route"[\s\S]+Get-LocalResponse '\/status\.json'/);
    assert.match(deploy,/sourceRevision -ne \$revision[\s\S]+diskSourceAt -ne \$build\.sourceAt[\s\S]+AddSeconds\(150\)[\s\S]+Confirm-BuildStatus \(Wait-Status \$process \$deadline\)[\s\S]+Confirm-ServedFile '\/'[\s\S]+foreach \(\$asset in \$build\.assets\.PSObject\.Properties\)[\s\S]+Confirm-ServedFile \$asset\.Name[\s\S]+lastAttemptAt[\s\S]+source\.refreshedAt -ne \$status\.generatedAt/);
    assert.match(deploy,/catch \{\s+Write-Step \('Failed step:'?[^\n]*[\s\S]+::Move\(\$previous, \$installed\)/);
    assert.match(deploy,/AppendAllText\(\$script:log,[\s\S]+Join-Path \$dated 'deploy\.log'/);
    assert.doesNotMatch(deploy,/Get-NetTCPConnection|Remove-Item|::Delete\(|tailscale|funnel|\bpython\b|Write-Error \$_/i);
  });
  check('PC source failure gives a safe reason and preserves the last complete read',()=>{
    const reader = new p.Reader();
    const healthyRoot = path.join(base,'healthy-pc');
    fs.mkdirSync(healthyRoot);
    const first = p.snapshot(healthyRoot,NOW,reader);
    const failed = p.snapshot(path.join(base,'private-folder'),NOW+60000,reader);
    assert(first.pcSource.complete);
    assert.deepEqual(failed.pcSource,{complete:false,lastSuccessfulReadAt:iso(NOW),lastAttemptAt:iso(NOW+60000),reason:'Folder listing: file or folder missing'});
    assert(!JSON.stringify(failed).includes('private-folder'));
  });
  check('output paths refuse job roots and junctions',()=>{
    for(const folder of ['board','board_c/issue-1','board_e','board_f/issue-1','queue','build_b/tools','work217'])assert.throws(()=>p.options(['--root',base,'--out',path.join(base,folder)]));const link=path.join(base,'link');fs.symlinkSync(root,link,process.platform==='win32'?'junction':'dir');assert.throws(()=>p.writeSnapshot(link,real.snapshot));
  });
  check('Codex E and F publish separate jobs and chain logs',()=>{
    const r = path.join(base,'extra-lanes');
    const at = NOW-60000;
    for (const [id,issue,next] of [['e',2057,2058],['f',2059,2060]]) {
      const stem = path.join(r,`codex_lane_${id}1`);
      write(stem+'.bat',`for %%N in (${issue} ${next}) do call :one %%N`,at);
      write(stem+'.txt',`${issue} start ${new Date(at).toTimeString().slice(0,8)}`,at);
      write(path.join(r,`board_${id}/issue-${issue}/status.json`),JSON.stringify({run:RUN,status:'running',
        title:`Job on lane ${id}`,started:iso(at)}),at);
    }
    const data = p.snapshot(r,NOW);
    for (const [id,issue,next] of [['e',2057,2058],['f',2059,2060]]) {
      const row = lane(data,id);
      assert.equal(row.current.title,`Job on lane ${id}`);
      assert.equal(row.current.issue,issue);
      assert.deepEqual(row.next.map(job=>job.issue),[next]);
      assert.deepEqual(row.source.lanes,[`codex_lane_${id}1.txt`]);
    }
  });
  await startupTests(check,base);
  await httpTests(check,base);
  await require('./phone_selftest').test(check,base,root);
  const {cases} = makeCases(base);
  check('current jobs keep their runner state and closed issue evidence through fresh and stale GitHub reads',()=>{
    for (const [name,state,stale] of [['running-closed-issue','running',false],['running-closed-issue-stale','running',true],
      ['finished-closed-issue','finished',false]]) {
      const {data} = cases[name], row = lane(data,'main');
      assert.equal(row.current.issue,970,name);
      assert.equal(row.current.githubState,'closed',name);
      assert.equal(row.state,state,name);
      assert.equal(row.runnerState,state==='running' ? 'running' : 'checked_push',name);
      assert.equal(data.github.sources.issues.stale,stale,name);
    }
  });
  console.log('PASS mission r3: '+count+' checks; fixtures and logs kept in '+base);return {base,cases};
}
async function budgetTests(check){
  const requests=[],reader=new p.GithubReader(async(url,opts)=>{requests.push({url,opts});return new Response('[]');});
  for(let minute=0;minute<=3;minute++)await reader.update(NOW+minute*60000);
  check('cold start spreads sources over three minutes using unauthenticated GETs',()=>{assert.equal(requests.length,4);assert(requests[0].url.includes('labels=ryan'));assert(requests.every(r=>r.opts.method==='GET' && !r.opts.headers.Authorization));assert(reader.data.coverageComplete);assert(Object.values(reader.data.sources).every(s=>s.complete && s.lastAttemptAt && s.lastSuccessfulReadAt));});
  let pages=0;const paged=new p.GithubReader(async()=>{pages++;return new Response('[]',{headers:pages<3?{Link:'<https://api.github.com/fixed>; rel="next"'}:{}});});await paged.update(NOW);
  check('three pages spend three requests from the shared budget',()=>{assert.equal(pages,3);assert.equal(paged.data.budget.requestsPastHour,3);assert(paged.data.sources.questions.complete);});
  let calls=0;const initial=p.emptyGithub();initial.needsRyan=[{issue:855,title:'Existing question'}];
  const partial=new p.GithubReader(async url=>{calls++;return !url.includes('labels=ryan')?new Response('[]'):url.endsWith('page=1')?new Response('[]',{headers:{Link:'<https://api.github.com/fixed>; rel="next"'}}):new Response('',{status:500});},initial);await partial.update(NOW);
  check('page two failure reports its HTTP status and retains last good questions',()=>{assert.equal(calls,2);assert(!partial.data.coverageComplete);assert.equal(partial.data.sources.questions.reason,'GitHub returned HTTP 500');assert.equal(partial.data.needsRyan[0].issue,855);assert.equal(partial.data.sources.questions.lastSuccessfulReadAt,null);});
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
  const safe = new p.GithubReader(async()=>new Response('[]'));
  await safe.update(NOW);
  safe.fetcher = async url=>{
    if (!url.includes('labels=ryan')) return new Response('[]');
    throw new Error('C:\\private-folder\\github_pat_SECRET and Bearer SECRET',{cause:{code:'ECONNRESET'}});
  };
  await safe.update(NOW+10*60000);
  check('transport failure records the affected source and last success without raw error details',()=>{
    assert.equal(safe.data.sources.questions.reason,'GitHub request: connection reset');
    assert.equal(safe.data.sources.questions.lastSuccessfulReadAt,iso(NOW));
    assert(!/private-folder|SECRET/.test(JSON.stringify(safe.data)));
  });
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
  check('Needs Ryan keeps flagged issues with unavailable questions and follows the label and fence rules',()=>{
    const cue='Ask Ryan: Pick this?', issue={number:1,title:'Question',state:'open',labels:['ryan'],body:cue};
    const asks=extra=>p.githubData([{...issue,...extra}],[],[],p.emptyGithub(),NOW).needsRyan;
    assert.equal(asks({})[0].question,'Pick this?');assert.equal(asks({})[0].picture,null);
    const picture='https://github.com/rcbailey12/voidsworn/issues/1';
    assert.equal(asks({body:cue+' | Picture: '+picture})[0].picture,picture);
    for(const extra of [{state:'closed'},{labels:[]}]) assert.equal(asks(extra).length,0);
    for(const body of ['', '````md\n```\n~~~\n'+cue+'\n````', 'Ask Ryan: | Picture: '+picture]) {
      assert.equal(asks({body})[0].issue,1);assert.equal(asks({body})[0].question,null);
    }
  });
  check('OpenAI PR observations exclude DeepSeek and do not prove a push or review',()=>{
    const raw=require('./fixtures/github.json'), source=raw.pulls[0];
    const pr=(number,ref,updated)=>({...source,number,updated_at:iso(updated),head:{...source.head,ref}});
    const g=p.githubData([], [pr(1027,'work/issue-1006-openai',NOW-60000),pr(1028,'work/issue-1006-deepseek',NOW)],[],p.emptyGithub(),NOW);
    assert.equal(g.crew.openai.number,1027);assert.equal(g.crew.openai.action,'PR activity recorded');assert.equal(g.reviews.length,0);
  });
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
const pause = ms => new Promise(resolve=>setTimeout(resolve,ms));
async function startupTests(check,base) {
  const stalled = new EventEmitter();
  let scans = 0;
  stalled.postMessage = () => { scans++; };
  stalled.terminate = () => {};
  const delayedGithub = {data:p.emptyGithub(),update:()=>new Promise(()=>{})};
  const began = Date.now();
  const opts = {root:base,out:path.join(base,'startup'),port:0};
  const server = p.serve(opts,()=>({host:null}),delayedGithub,()=>stalled);
  await new Promise((resolve,reject)=>{server.once('listening',resolve);server.once('error',reject);});
  try {
    const url = 'http://127.0.0.1:'+server.address().port;
    const boot = await (await fetch(url+'/status.json',{signal:AbortSignal.timeout(3000)})).json();
    check('first listener stays responsive while the PC scan and GitHub read are both stalled',()=>{
      assert(Date.now()-began<30000);
      assert.equal(scans,1);
      assert.equal(boot.schemaVersion,2);
      assert.equal(boot.state,'starting');
      assert.equal(boot.generatedAt,null);
      assert.deepEqual(boot.lanes,[]);
      assert.equal(boot.build.id,p.buildHash());
      assert(!fs.existsSync(path.join(opts.out,'status.json')));
    });
  } finally { await new Promise(resolve=>server.close(resolve)); }
}
async function httpTests(check,base){
  const root = path.join(base,'http-pictures');
  const repo = path.join(root,'board/repo');
  const out = path.join(base,'served');
  const source = path.resolve(__dirname,'../../../docs/ship_pipeline/build_sheets/hegemony_IM5/ion_installed_cam170.jpg');
  const jpeg = fs.readFileSync(source);
  const indexed = path.join(repo,'docs/shots/review.jpg');
  const stamp = path.join(indexed+'.provenance.json');
  const unindexed = path.join(repo,'docs/private.jpg');
  const {source_commit,stage,date} = JSON.parse(fs.readFileSync(source+'.provenance.json','utf8'));
  const makeStamp = bytes => JSON.stringify({source_commit,stage,date,image_sha256:createHash('sha256').update(bytes).digest('hex')});
  const stampBody = makeStamp(jpeg);
  function put(file, bytes = jpeg, sidecar = makeStamp(bytes)) { write(file,bytes); if (sidecar) write(file+'.provenance.json',sidecar); }
  put(indexed);
  put(unindexed);
  put(path.join(repo,'docs/shots/unstamped.jpg'),jpeg,false);
  put(path.join(repo,'docs/shots/malformed.jpg'),jpeg,'{broken');
  put(path.join(repo,'docs/shots/oversized.jpg'),Buffer.alloc(3*1024*1024+1));
  put(path.join(repo,'docs/shots/not-image.jpg'),Buffer.from('Plain text'));
  put(path.join(repo,'docs/shots/no.svg'));
  const other = path.join(base,'outside-pictures');
  put(path.join(other,'inside.jpg'));
  fs.symlinkSync(other,path.join(repo,'docs/shots/linked'),process.platform==='win32'?'junction':'dir');
  const github = {data:p.emptyGithub(),update:()=>new Promise(()=>{})};
  const server = p.serve({root,out,port:0},()=>({host:null}),github);
  await new Promise((resolve,reject)=>{server.once('listening',resolve);server.once('error',reject);});
  const port = server.address().port;
  const request=(route,headers={},method='GET')=>new Promise((resolve,reject)=>{
    http.request({host:'127.0.0.1',port,path:route,headers,method},res=>{
      const chunks=[];res.on('data',chunk=>chunks.push(chunk));
      res.on('end',()=>resolve({code:res.statusCode,bytes:Buffer.concat(chunks),headers:res.headers}));
    }).on('error',reject).end();
  });
  const idFor = file => {
    const relative = path.relative(repo,file).replace(/\\/g,'/');
    const hash = createHash('sha256').update(fs.readFileSync(file)).digest('hex');
    return createHash('sha256').update(repo+'\0'+relative+'\0'+hash).digest('hex');
  };
  try{
    let response, status;
    for (let attempt=0; attempt<80; attempt++) {
      response=await request('/status.json'); status=JSON.parse(response.bytes);
      if (status.lanes.length) break;
      await pause(100);
    }
    const pic = '/pic/'+idFor(indexed);
    const main = lane(status,'main');
    const page = await request('/');
    check('the full PC snapshot and page arrive while the first GitHub read is pending',()=>{
      assert.equal(main.pictures.length,2);
      assert(main.pictures.some(picture=>'/pic/'+picture.id===pic));
      assert.equal(status.github.lastReadAt,null);
      assert.equal(response.headers['cache-control'],'no-store');
      assert.equal(server.address().address,'127.0.0.1');
      assert.match(page.bytes.toString(),/EMBERS OPS/);
      assert(!response.bytes.toString().includes('review.jpg'));
      assert.deepEqual(status,JSON.parse(fs.readFileSync(path.join(out,'status.json'))));
    });
    const picture = await request(pic);
    check('indexed stamped picture uses fixed content and privacy headers',()=>{
      assert.equal(picture.code,200);
      assert.equal(picture.headers['content-type'],'image/jpeg');
      assert.equal(picture.headers['content-length'],String(jpeg.length));
      assert.equal(picture.headers['cache-control'],'no-store');
      assert.equal(picture.headers['x-content-type-options'],'nosniff');
      assert.equal(picture.headers['referrer-policy'],'no-referrer');
      assert.equal(picture.headers['content-disposition'],undefined);
      assert.deepEqual(picture.bytes,jpeg);
    });
    const refused = ['..','%2e%2e','%2f'+pic.slice(5),'%5c'+pic.slice(5),'0'.repeat(64),'','../status.json',
      ...[unindexed,...['unstamped.jpg','malformed.jpg','oversized.jpg','not-image.jpg','no.svg','linked/inside.jpg'].map(file=>path.join(repo,'docs/shots',file))].map(idFor)];
    for (const route of ['/pic',pic+'?x=1',pic+'?',pic+'#fragment','/fixtures/nov17.json',...refused.map(value=>'/pic/'+value)]) {
      assert.equal((await request(route)).code,404,route);
    }
    assert.equal((await request(pic,{},'POST')).code,404);
    assert.equal((await request(pic,{},'HEAD')).code,404);
    assert.equal((await request('/status.json',{},'POST')).code,405);
    check('pictures reject unknown ids, files outside the index, invalid stamps, bad image types, links, traversal, queries and writes',()=>{});
    // Keep the same id in the served snapshot while replacing its on-disk bytes or stamp.
    write(stamp,'{broken');
    assert.equal((await request(pic)).code,404);
    write(stamp,stampBody);
    write(indexed,Buffer.concat([jpeg,Buffer.from('changed')]));
    assert.equal((await request(pic)).code,404);
    put(indexed);
    const activePath = path.dirname(indexed), kept = activePath+'-kept';
    fs.renameSync(activePath,kept);
    fs.symlinkSync(kept,activePath,process.platform==='win32'?'junction':'dir');
    assert.equal((await request(pic)).code,404);
    check('indexed files are refused if the image, sidecar or checkout path changes between scans',()=>{});
    assert.equal((await request(pic,{Host:'outsider.example'})).code,403);
    assert.equal((await request(pic,{'Tailscale-Funnel-Request':'?1'})).code,403);
    for (const name of Object.keys(p.ASSETS)) assert.equal((await request(name)).code,200);
    check('fixed font and crew assets render with the existing private host checks',()=>{});
  }finally{await new Promise(r=>server.close(r));}
}
module.exports={NOW,copyFixture,makeCases,test};
if(require.main===module)test().catch(e=>{console.error('FAIL mission r3: '+e.stack);process.exitCode=1;});
