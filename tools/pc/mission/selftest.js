'use strict';
// Free Windows proof. All mutations are to a new %TEMP% fixture folder, never a real lane.
const assert = require('assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const { spawn } = require('child_process');
const p = require('./publisher');
const NOW = new Date(2026, 10, 16, 16, 30).getTime();
const fixtureDir = path.join(__dirname, 'fixtures', 'lanes');
const write = (f, text, modified = NOW-60000) => {
  fs.mkdirSync(path.dirname(f), {recursive:true}); fs.writeFileSync(f,text);
  fs.utimesSync(f, new Date(modified), new Date(modified));
};
function copyFixture(root, source = fixtureDir) {
  function copy(src, dest) {
    for(const d of fs.readdirSync(src,{withFileTypes:true})) {
      const a=path.join(src,d.name), b=path.join(dest,d.name);
      if(d.isDirectory()) copy(a,b);
      else {
        const stale=b.includes('work217');
        const started=stale?NOW-45*60000:b.includes('board/issue-918') || b.includes('board\\issue-918')?NOW-15*60000:NOW-30*60000;
        const finished=source===fixtureDir?NOW-20*60000:NOW-60000;
        const text=fs.readFileSync(a,'utf8').replaceAll('@ROOT@',root).replaceAll('@STARTED@',new Date(started).toISOString()).replaceAll('@FINISHED@',new Date(finished).toISOString());
        write(b,text,stale?NOW-31*60000:NOW-60000);
      }
    }
  }
  copy(source,root);
}
const lane = (s,id) => s.lanes.find(l=>l.id===id);
function githubFixture(needs = false, now = NOW) {
  const raw=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/github.json'),'utf8'));
  const offset=now-Date.parse('2026-11-17T04:38:00Z');
  for(const record of [...raw.issues,...raw.pulls,...raw.comments])for(const field of ['updated_at','merged_at'])if(record[field])record[field]=new Date(Date.parse(record[field])+offset).toISOString();
  if(!needs)raw.issues=raw.issues.filter(x=>x.number!==855);
  return p.githubData(raw.issues,raw.pulls,raw.comments,p.emptyGithub(),now);
}
function nightFixture(root) {
  const spec=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/night.json'),'utf8')), now=Date.parse(spec.now);
  for(const [name,c] of Object.entries(spec.chains)) {
    write(path.join(root,name+'.txt'),c.text,now-60000);
    write(path.join(root,name.toUpperCase()+'.bat'),'for %%N in ('+c.issues.join(' ')+') do call :one %%N\n',now-60000);
  }
  for(const j of spec.jobs){
    const modified=now-j.age*60000,folder=path.join(root,j.folder);
    if(j.status)write(path.join(folder,'status.json'),JSON.stringify({status:j.status,started:new Date(now-j.startedAgo*60000).toISOString(),finished:j.status==='checked_push'?new Date(modified).toISOString():null,title:j.title}),modified);
    write(path.join(folder,'log.txt'),j.result || 'agent running\n',modified);
    write(path.join(folder,'result.txt'),j.result || 'agent running\n',modified);
    if(j.checksAge)write(path.join(folder,'checks_node.txt'),'runner checks in progress\n',now-j.checksAge*60000);
  }
  write(path.join(root,'work217/issue-932-deepseek/latest.txt'),'issue-932-deepseek\n',now-160*60000);
  return {now,snap:p.snapshot(root,now,new p.Reader(),githubFixture(false,now))};
}
function makeCases(base, revision='working tree') {
  const cases={};
  for(const name of ['overview','running','waiting','blocked','failed','finished','gap','stale','offline','unknown','leftover','ended','github-unread','needs-ryan','no-needs-ryan','night']) {
    const root=path.join(base,name);copyFixture(root);
    if(name==='gap') copyFixture(root,path.join(__dirname,'fixtures','gap'));
    if(name==='failed') write(path.join(root,'board_c/issue-914/status.json'),JSON.stringify({status:'failed',reason:'runner exit 8',started:new Date(NOW-20*60000).toISOString()}));
    if(name==='unknown') write(path.join(root,'board/issue-918/status.json'),'{broken');
    let snap=p.snapshot(root,NOW,new p.Reader(),name==='github-unread'?p.emptyGithub():githubFixture(name==='needs-ryan'));
    let fixtureNow=NOW;
    if(['night','leftover','ended'].includes(name)) {const night=nightFixture(path.join(base,'night-'+name));snap=night.snap;fixtureNow=night.now;}
    // Preserve all five seat labels and ids; feature captures scroll to the actual row.
    if(name==='offline') {
      // This is an older complete snapshot, including every row's refresh/activity time.
      snap=JSON.parse(JSON.stringify(snap),(_,v)=>typeof v==='string' && /^\d{4}-\d\d-\d\dT/.test(v)?new Date(Date.parse(v)-180000).toISOString():v);
    }
    snap.fixtureNow=new Date(fixtureNow).toISOString();snap.fixtureRevision=revision;
    cases[name]=snap;
    p.writeSnapshot(path.join(base,'payloads',name),snap);
  }
  return cases;
}
function fingerprints(root) {
  const all={};
  function scan(dir) { for(const d of fs.readdirSync(dir,{withFileTypes:true})) {
    const f=path.join(dir,d.name);if(d.isDirectory())scan(f);else {const s=fs.statSync(f);all[path.relative(root,f)]=[s.size,s.mtimeMs,fs.readFileSync(f).toString('base64')];}
  }}
  scan(root);return all;
}
function request(port,url='/',headers={}) {
  return new Promise((resolve,reject)=>{http.get({host:'127.0.0.1',port,path:url,headers},r=>{let text='';r.on('data',d=>text+=d);r.on('end',()=>resolve({code:r.statusCode,text,headers:r.headers}));}).on('error',reject);});
}
async function test() {
  const base=fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-mission-'));
  let count=0;
  const check=(name,fn)=>{fn();count++;console.log('PASS '+name);};
  const cases=makeCases(base), root=path.join(base,'overview'), before=fingerprints(root);
  const reader=new p.Reader(), snap=p.snapshot(root,NOW,reader);
  check('five seats, real titles, issue and PR links',()=>{
    assert.deepEqual(snap.lanes.map(l=>l.id),['main','b','c','d','deepseek']);
    assert.equal(lane(snap,'main').current.title,'Mission control: live PC lanes');
    assert.equal(lane(snap,'main').current.url,'https://github.com/rcbailey12/voidsworn/issues/918');
    assert.match(lane(snap,'main').current.prUrl,/head%3Acodex/);
  });
  check('new waiting chain does not hide current job; ordered next jobs',()=>{
    assert.equal(lane(snap,'main').state,'running');assert.equal(lane(snap,'main').current.issue,918);
    assert.deepEqual(lane(snap,'main').next.map(j=>j.issue),[920,921,923]);
    assert.equal(lane(snap,'b').state,'waiting');assert.equal(lane(snap,'b').next[0].issue,922);
  });
  check('between jobs the live chain keeps its finished result, next jobs and source',()=>{
    const row=lane(cases.gap,'main');
    assert.equal(row.state,'finished');assert.equal(row.current.issue,918);
    assert.match(row.reason,/Checked push confirmed/);assert.equal(row.stale,false);
    assert.deepEqual(row.next.map(j=>j.issue),[920,921,923]);
    assert.deepEqual(row.source.lanes,['codex_chain_fixture.txt','codex_chain_next.txt']);
    assert(row.source.runner);assert(row.source.updatedAt);
  });
  const gap=path.join(base,'gap-transitions');copyFixture(gap);copyFixture(gap,path.join(__dirname,'fixtures','gap'));
  check('gap retains an unsuccessful runner result and remaining queue',()=>{
    write(path.join(gap,'board/issue-918/status.json'),JSON.stringify({status:'failed',reason:'runner exit 8',started:new Date(NOW-15*60000).toISOString()}));
    const row=lane(p.snapshot(gap,NOW),'main');
    assert.equal(row.state,'failed');assert.match(row.reason,/Runner exit 8/);
    assert.deepEqual(row.next.map(j=>j.issue),[920,921,923]);
  });
  check('the next start advances the gap queue exactly once',()=>{
    write(path.join(gap,'codex_chain_fixture.txt'),'start Mon 11/16/2026 16:15:00.00\n918 start 16:15:00.00\n918 end 16:29:00.00\n920 start 16:29:30.00\n');
    write(path.join(gap,'board/issue-920/status.json'),JSON.stringify({status:'running',started:new Date(NOW-30000).toISOString()}));
    const row=lane(p.snapshot(gap,NOW),'main');
    assert.equal(row.current.issue,920);assert.equal(row.state,'running');
    assert.deepEqual(row.next.map(j=>j.issue),[921,923]);
  });
  check('newer live and completed chains both replace an abandoned gap',()=>{
    for(const done of [false,true]) {
      const root=path.join(base,'replacement-'+done);copyFixture(root);copyFixture(root,path.join(__dirname,'fixtures','gap'));
      write(path.join(root,'CODEX_CHAIN_REPLACEMENT.bat'),'for %%N in (999 1000) do call :one %%N\n');
      const lines='start Mon 11/16/2026 16:29:00.00\n999 start 16:29:00.00\n';
      write(path.join(root,'codex_chain_replacement.txt'),lines+(done?'999 end 16:29:30.00\nall done 16:29:30.00\n':''));
      write(path.join(root,'board/issue-999/status.json'),JSON.stringify({status:done?'checked_push':'running',started:new Date(NOW-60000).toISOString()}));
      const row=lane(p.snapshot(root,NOW),'main');
      assert.equal(row.current.issue,999);assert.equal(row.state,done?'finished':'running');
      assert(!row.next.some(j=>[920,921].includes(j.issue)));
      assert(!row.source.lanes.includes('codex_chain_fixture.txt'));
      assert.equal(row.next.some(j=>j.issue===1000),!done);
    }
  });
  check('a newer standalone runner replaces the gap chain',()=>{
    const root=path.join(base,'runner-replacement');copyFixture(root);copyFixture(root,path.join(__dirname,'fixtures','gap'));
    write(path.join(root,'board/issue-999/status.json'),JSON.stringify({status:'running',started:new Date(NOW-10000).toISOString()}));
    const row=lane(p.snapshot(root,NOW),'main');
    assert.equal(row.current.issue,999);assert(!row.next.some(j=>[920,921].includes(j.issue)));
    assert(!row.source.lanes.includes('codex_chain_fixture.txt'));
  });
  check('a newer completed chain without runner output cannot revive the gap',()=>{
    const root=path.join(base,'completed-without-output');copyFixture(root);copyFixture(root,path.join(__dirname,'fixtures','gap'));
    write(path.join(root,'CODEX_CHAIN_REPLACEMENT.bat'),'for %%N in (999 1000) do call :one %%N\n');
    write(path.join(root,'codex_chain_replacement.txt'),'start Mon 11/16/2026 16:29:00.00\n999 start 16:29:00.00\n999 end 16:29:30.00\nall done 16:29:30.00\n');
    const row=lane(p.snapshot(root,NOW),'main');
    assert.equal(row.current.issue,999);assert.equal(row.state,'unknown');
    assert(!row.next.some(j=>[920,921,1000].includes(j.issue)));
    assert(!row.source.lanes.includes('codex_chain_fixture.txt'));
  });
  check('blocked runner reason, checked finish, dead running becomes stale',()=>{
    assert.equal(lane(snap,'c').state,'blocked');assert.match(lane(snap,'c').reason,/predecessor/);
    assert.equal(lane(snap,'d').state,'finished');assert.equal(lane(snap,'deepseek').stale,true);
    assert.equal(lane(snap,'deepseek').current.title,'Stage 5 self-test repair');
  });
  check('failed and corrupt status fixtures',()=>{assert.equal(lane(cases.failed,'c').state,'failed');assert.equal(lane(cases.unknown,'main').state,'unknown');});
  check('source and refresh times on every row',()=>{for(const row of snap.lanes){assert(row.source.refreshedAt);assert(row.source.lanes.length || row.source.runner);assert(row.source.updatedAt);}});
  check('fixture source files unchanged by publisher scan',()=>assert.deepEqual(fingerprints(root),before));
  check('stale boundary counts result and checks writes, never publisher refresh',()=>{
    const log=path.join(root,'board/issue-918/log.txt'), status=path.join(root,'board/issue-918/status.json');
    for(const f of [log,status]) fs.utimesSync(f,new Date(NOW-1800000),new Date(NOW-1800000));
    write(path.join(root,'board/issue-918/result.txt'),'agent running\n',NOW-1800000);
    assert.equal(lane(p.snapshot(root,NOW),'main').stale,true);
    assert.equal(lane(p.snapshot(root,NOW-1),'main').stale,false);
    write(path.join(root,'board/issue-918/checks_parity.txt'),'checks running',NOW-60000);
    assert.equal(lane(p.snapshot(root,NOW),'main').stale,false);
    fs.utimesSync(log,new Date(NOW),new Date(NOW));assert.equal(lane(p.snapshot(root,NOW),'main').stale,false);
  });
  // Restore a fresh fixture in a different folder; never remove a file, including test output.
  const fresh=path.join(base,'fresh');copyFixture(fresh);
  check('repeat scan does not mutate sources and caches bounded text reads',()=>{
    const fingerprint=fingerprints(fresh), r=new p.Reader();p.snapshot(fresh,NOW,r);const bytes=r.readBytes;
    p.snapshot(fresh,NOW+60000,r);assert.equal(r.readBytes,bytes);assert.deepEqual(fingerprints(fresh),fingerprint);
    assert(bytes<200000);
  });
  check('missing folders remain unknown',()=>{assert(p.snapshot(path.join(base,'missing'),NOW).lanes.every(l=>l.state==='unknown'));});
  check('text all done or a dry push cannot imply checked success',()=>{
    write(path.join(fresh,'board_c/issue-914/status.json'),JSON.stringify({status:'unverified',reason:'dry/test push or checks did not pass',started:new Date(NOW-30*60000).toISOString()}));
    assert.equal(lane(p.snapshot(fresh,NOW),'c').state,'blocked');
  });
  check('old successful output is not reused for a new run of that issue',()=>{
    write(path.join(fresh,'board/issue-918/status.json'),JSON.stringify({status:'checked_push',started:new Date(NOW-3600000).toISOString()}));
    assert.equal(lane(p.snapshot(fresh,NOW),'main').state,'unknown');
  });
  check('all done after a rerun cannot revive an older checked push',()=>{
    write(path.join(fresh,'codex_lane_c19.txt'),'start Mon 11/16/2026 16:20:00.00\n914 start 16:20:00.00\n914 end 16:21:00.00\nall done 16:21:00.00\n');
    write(path.join(fresh,'board_c/issue-914/status.json'),JSON.stringify({status:'checked_push',started:new Date(NOW-3600000).toISOString()}));
    assert.equal(lane(p.snapshot(fresh,NOW),'c').state,'unknown');
  });
  check('chain-only job without runner life becomes stale',()=>{
    const s=p.snapshot(fresh,NOW+1800000);assert.equal(lane(s,'main').state,'unknown');assert.equal(lane(s,'main').stale,true);
  });
  check('a live started chain wins over a newer unrelated runner folder',()=>{
    write(path.join(fresh,'board/issue-999/status.json'),JSON.stringify({status:'running',started:new Date(NOW-10000).toISOString()}));
    assert.equal(lane(p.snapshot(fresh,NOW),'main').current.issue,918);
    assert(lane(p.snapshot(fresh,NOW),'main').next.some(j=>j.issue===920));
    assert(lane(p.snapshot(fresh,NOW),'main').warnings.some(w=>w.includes('999')));
  });
  check('exact predecessor wait in result stays waiting',()=>{
    const folder=path.join(fresh,'board_d/issue-889');
    write(path.join(folder,'status.json'),JSON.stringify({status:'running',started:new Date(NOW-10*60000).toISOString()}));
    write(path.join(folder,'result.txt'),'chain waiting for C:\\private\\out\\status.json');
    assert.equal(lane(p.snapshot(fresh,NOW),'d').state,'waiting');
  });
  check('old workhorse runs and path escape pointers cannot replace the newest run',()=>{
    const folder=path.join(fresh,'work217/issue-916-deepseek');
    write(path.join(folder,'latest.txt'),'C:\\private\\outside');
    write(path.join(folder,'20261115_120000/out/status.json'),JSON.stringify({status:'checked_push',started:'2026-11-15T12:00:00Z'}));
    assert.equal(lane(p.snapshot(fresh,NOW),'deepseek').state,'running');
  });
  check('parser recognizes issue lists and direct runners, ignores comments',()=>{
    assert.deepEqual(p.parseIssues('rem for %%N in (1) do call :one %%N\nfor %%N in (2 3) do call :one %%N\ncall "%T%\\work_issue.bat" 4 deepseek\ncall "%V%\\RUN_RETRY.bat" 5 deepseek 7200'),[2,3,4,5]);
  });
  check('privacy: paths, users, credentials and arbitrary runner text never escape',()=>{
    write(path.join(fresh,'board_c/issue-914/status.json'),JSON.stringify({status:'failed',started:new Date(NOW-60000).toISOString(),reason:'runner exit 14 C:\\Users\\PrivatePerson\\secret ghp_FIXTURESECRET',title:'C:\\Users\\PrivatePerson\\secret'}));
    const text=JSON.stringify(p.snapshot(fresh,NOW));
    assert(!/PrivatePerson|ghp_FIXTURESECRET|C:\\\\Users|FIXTURESECRET/.test(text));assert.match(text,/Runner exit 14/);
    assert.equal(p.safeReason('password=fixture'),'Runner reason is unrecognized; inspect it locally.');
  });
  check('older runner usage-limit text can report blocked before its state changes',()=>{
    write(path.join(fresh,'board_d/issue-889/result.txt'),'usage limit hit, left on the board to retry\n');
    assert.equal(lane(p.snapshot(fresh,NOW),'d').state,'blocked');
  });
  check('output refuses job and queue folders',()=>{for(const dir of ['board','board_c/issue-1','queue','build_b/tools','work217'])assert.throws(()=>p.options(['--root',base,'--out',path.join(base,dir)]));});
  check('output junction cannot redirect a write into a job',()=>{
    const link=path.join(base,'output-junction');fs.symlinkSync(path.join(root,'board/issue-918'),link,process.platform==='win32'?'junction':'dir');
    assert.throws(()=>p.writeSnapshot(link,snap));
    assert.throws(()=>p.options(['--root',base,'--out',link]));
  });
  check('local snapshot write is complete JSON',()=>{const out=path.join(base,'out');p.writeSnapshot(out,snap);assert.deepEqual(JSON.parse(fs.readFileSync(path.join(out,'status.json'),'utf8')),snap);p.writeSnapshot(out,snap);});
  check('Nov 16 22:38: live main job, exact queue, paused B queues and ended DeepSeek',()=>{
    const s=cases.night, main=lane(s,'main'),ds=lane(s,'deepseek');
    assert.equal(main.current.issue,928);assert.equal(main.state,'running');assert.equal(main.stale,false);
    assert.deepEqual(main.next.map(j=>j.issue),[929,912,930,920,921]);
    assert.deepEqual(main.leftovers.map(x=>x.job.issue),[944]);assert.equal(main.current.title.includes('Hull hit redo'),true);
    assert.deepEqual(lane(s,'b').next,[]);assert.notEqual(lane(s,'b').state,'waiting');
    assert.equal(ds.state,'idle');assert.equal(ds.stale,false);assert(ds.endedWithoutPush);assert.equal(ds.current.issue,932);
    assert.equal(ds.current.prState,'merged');assert.equal(ds.current.prNumber,937);
  });
  check('a paused current chain cannot remain working or feed Next',()=>{
    const root=path.join(base,'paused-current');copyFixture(root);
    write(path.join(root,'codex_chain_fixture.txt'),'918 start Mon 11/16/2026 16:15:00.00\npaused by the Board\n');
    const row=lane(p.snapshot(root,NOW),'main');assert.equal(row.state,'idle');assert(!row.next.some(j=>j.issue===920));
  });
  check('needs-Ryan requires both the label and an unfenced body marker',()=>{
    assert.equal(cases['github-unread'].github.lastReadAt,null);
    assert.equal(cases['no-needs-ryan'].github.needsRyan.length,0);
    assert.equal(cases['needs-ryan'].github.needsRyan.length,1);
    const raw=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/github.json'),'utf8'));
    const issue=raw.issues.find(x=>x.number===855);
    for(const extra of [{labels:[]},{state:'closed'},{body:'A normal comment'},{body:'```\n'+issue.body+'\n```'}]){
      const g=p.githubData([{...issue,...extra}],[],[],p.emptyGithub(),NOW);assert.equal(g.needsRyan.length,0);
    }
    const g=p.githubData([{...issue,body:'Ask Ryan: password=PRIVATE | Picture: https://outsider.example/private'}],[],[],p.emptyGithub(),NOW);
    assert(!JSON.stringify(g).includes('PRIVATE'));assert.equal(g.needsRyan[0].picture,null);
    const cleared=p.githubData([{...issue,labels:[]}],[],[],cases['needs-ryan'].github,NOW+1000);assert.equal(cleared.needsRyan.length,0);
  });
  check('GitHub publishes fixed metadata, branch PR states and Crew records only',()=>{
    const g=cases.night.github;assert(g.crew.claude);assert(g.crew.muse);assert(g.crew.artoo);
    assert(!JSON.stringify(g).includes('Private fixture comment'));
    const raw=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/github.json'),'utf8'));
    const pr=raw.pulls[0], fork={...pr,number:999,head:{ref:pr.head.ref,repo:{full_name:'outsider/voidsworn'}}};
    const g2=p.githubData([], [fork],[],p.emptyGithub(),NOW);assert.equal(g2.pulls.length,0);
    const bad={number:1,title:'C:\\Users\\PrivatePerson ghp_FIXTURESECRET',state:'open',labels:[]};
    assert(!JSON.stringify(p.githubData([bad],[],[],p.emptyGithub(),NOW)).includes('PrivatePerson'));
    assert.equal(p.githubData(Array.from({length:100},(_,i)=>({...bad,number:i+1})),[],[],p.emptyGithub(),NOW).coverageComplete,false);
  });
  check('GitHub can link a chain-only job PR without implying a checked runner finish',()=>{
    const root=path.join(base,'chain-only-pr');
    write(path.join(root,'codex_chain_fixture.txt'),'999 start Mon 11/16/2026 16:29:00.00\n');
    write(path.join(root,'CODEX_CHAIN_FIXTURE.bat'),'for %%N in (999) do call :one %%N\n');
    const raw=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/github.json'),'utf8'));
    const pr={...raw.pulls[0],head:{ref:'codex/issue-999',repo:{full_name:'rcbailey12/voidsworn'}}};
    const g=p.githubData([], [pr],[],p.emptyGithub(),NOW),row=lane(p.snapshot(root,NOW,new p.Reader(),g),'main');
    assert.equal(row.current.prNumber,937);assert.equal(row.current.prState,'merged');assert.equal(row.state,'unknown');
  });
  const rawGithub=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/github.json'),'utf8'));
  const requests=[];let fail=false;
  const remote=new p.GithubReader(async (url,opts)=>{
    requests.push({url,opts});if(fail)return new Response('',{status:429});
    const body=url.includes('/issues/comments?')?rawGithub.comments:url.includes('/pulls?')?rawGithub.pulls:rawGithub.issues;
    return new Response(JSON.stringify(body),{status:200});
  });
  await Promise.all([remote.update(NOW),remote.update(NOW)]);await remote.update(NOW+299999);
  check('GitHub uses at most 3 public GETs per 5 minutes, with no authentication',()=>{
    assert.equal(requests.length,3);
    assert(requests.every(r=>r.opts.method==='GET' && !Object.keys(r.opts.headers).some(k=>/authorization|cookie/i.test(k))));
    assert(requests.some(r=>r.url.includes('state=all&sort=updated')));assert.equal(remote.data.needsRyan.length,1);
  });
  fail=true;await remote.update(NOW+300000);
  check('rate limit preserves last good data and its original read time',()=>{
    assert.equal(requests.length,6);assert.equal(remote.data.ok,false);assert.equal(remote.data.lastReadAt,new Date(NOW).toISOString());assert.equal(remote.data.needsRyan.length,1);
    assert(requests.at(-1).url.includes(encodeURIComponent(new Date(NOW).toISOString())));
  });
  fail=false;await remote.update(NOW+600000);
  check('a later successful GitHub read recovers without extra requests',()=>{assert.equal(requests.length,9);assert(remote.data.ok);});
  const noRead=new p.GithubReader(async()=>{throw Error('offline');});await noRead.update(NOW);
  check('first GitHub failure remains not checked',()=>{assert.equal(noRead.data.lastReadAt,null);assert.equal(noRead.data.ok,false);});
  // Launch the actual entry point and stop its process, proving lifecycle and fixed routes.
  const probe=http.createServer();await new Promise(resolve=>probe.listen(0,'127.0.0.1',resolve));const port=probe.address().port;await new Promise(resolve=>probe.close(resolve));
  const preload=path.join(base,'public-github-fixture.cjs');
  write(preload,"global.fetch=async()=>new Response('[]',{status:200});\n");
  const child=spawn(process.execPath,[...process.execArgv,'--require',preload,path.join(__dirname,'publisher.js'),'--root',root,'--out',path.join(base,'served'),'--port',String(port)],{stdio:['ignore','pipe','pipe'],windowsHide:true});
  let childError='';child.stderr.on('data',d=>childError+=d);
  try {
    await new Promise((resolve,reject)=>{const timeout=setTimeout(()=>reject(Error('server start timed out: '+childError)),10000);child.once('error',reject);child.stdout.on('data',d=>{if(String(d).includes('Mission control:')){clearTimeout(timeout);resolve();}});child.once('exit',code=>{clearTimeout(timeout);reject(Error('server exited '+code+': '+childError));});});
    const status=await request(port,'/status.json'), page=await request(port,'/');
    check('actual localhost publisher serves page and one sanitized JSON',()=>{assert.equal(status.code,200);assert.equal(JSON.parse(status.text).lanes.length,5);assert.match(page.text,/<title>Mission Control/);assert.equal(status.headers['cache-control'],'no-store');});
    const forbidden=await request(port,'/../board/issue-918/log.txt'), host=await request(port,'/',{Host:'outsider.example'});
    check('server does not expose logs, directories, CORS or arbitrary hosts',()=>{assert.equal(forbidden.code,404);assert.equal(host.code,403);assert(!status.headers['access-control-allow-origin']);});
    for(const file of ['artoo.svg','ChakraPetch-SemiBold.ttf','Barlow-Regular.ttf','AzeretMono-VF.ttf']) {
      const asset=await request(port,'/'+file);check('fixed asset route '+file,()=>{assert.equal(asset.code,200);assert.match(asset.headers['content-type'],/font\/ttf|image\/svg/);});
    }
  } finally {
    if(child.exitCode===null && child.signalCode===null){const exited=new Promise(resolve=>child.once('exit',resolve));child.kill();await exited;}
  }
  let connected=true;try{await request(port);}catch(_){connected=false;}
  check('closing the publisher process closes its server',()=>assert.equal(connected,false));
  const originalFetch=global.fetch;
  try { global.fetch=async()=>new Response('[]',{status:200}); await require('./phone_selftest').test(check, base, root); }
  finally { global.fetch=originalFetch; }
  console.log(`PASS mission publisher: ${count} checks; no real lane files touched`);
  console.log('Fixture data and local test output kept in '+base);
  return {base,cases};
}
module.exports={NOW,copyFixture,makeCases,test};
if(require.main===module)test().catch(e=>{console.error('FAIL mission publisher: '+e.stack);process.exitCode=1;});
