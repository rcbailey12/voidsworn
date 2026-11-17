'use strict';
// Headless, CPU-only phone proof using the installed Edge and the browser's CDP protocol.
// No browser package, GPU work, network upload or changes to a live lane.
const fs=require('fs'), path=require('path'), os=require('os'), http=require('http');
const {spawn,spawnSync}=require('child_process');
const assert=require('assert/strict');
const {makeCases}=require('./selftest');
const {compatiblePage}=require('./publisher');
const pause=ms=>new Promise(r=>setTimeout(r,ms));
async function run(){
  const base=fs.mkdtempSync(path.join(os.tmpdir(),'mission-phone-'));
  const out=process.argv[2]?path.resolve(process.argv[2]):path.join(base,'shots');fs.mkdirSync(out,{recursive:true});
  const revision=spawnSync('git',['rev-parse','--short=12','HEAD'],{encoding:'utf8',windowsHide:true}).stdout.trim()+' + working tree';
  const cases=makeCases(base,revision);
  let live=cases.overview;
  const page=compatiblePage(fs.readFileSync(path.join(__dirname,'../../../docs/mission/index.html'),'utf8'));
  const assets={'/artoo.svg':'image/svg+xml','/ChakraPetch-SemiBold.ttf':'font/ttf','/Barlow-Regular.ttf':'font/ttf','/AzeretMono-VF.ttf':'font/ttf'};
  const server=http.createServer((req,res)=>{
    const m=/^\/fixtures\/([a-z-]+)\.json$/.exec(req.url.split('?')[0]);
    res.setHeader('Cache-Control','no-store');
    if(req.url.split('?')[0]==='/'){res.setHeader('Content-Type','text/html');res.end(page);}
    else if(req.url==='/status.json'){if(live===null){res.writeHead(503).end();}else{res.setHeader('Content-Type','application/json');res.end(JSON.stringify(live));}}
    else if(m && cases[m[1]]){res.setHeader('Content-Type','application/json');res.end(JSON.stringify(cases[m[1]]));}
    else if(Object.hasOwn(assets,req.url)){res.setHeader('Content-Type',assets[req.url]);res.end(fs.readFileSync(path.join(__dirname,'../../../docs/mission',req.url.slice(1))));}
    else res.writeHead(404).end();
  });
  await new Promise(r=>server.listen(0,'127.0.0.1',r));const port=server.address().port;
  const exe=process.env.MISSION_BROWSER || ['C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe','C:/Program Files/Google/Chrome/Application/chrome.exe'].find(f=>fs.existsSync(f));
  if(!exe)throw Error('Installed Edge or Chrome required. Set MISSION_BROWSER to its executable.');
  const browser=spawn(exe,['--headless=new','--disable-gpu','--no-first-run','--disable-extensions','--disable-background-networking','--disable-component-update','--disable-sync','--remote-debugging-address=127.0.0.1','--remote-debugging-port=0','--user-data-dir='+path.join(base,'browser-profile'),'about:blank'],{windowsHide:true,stdio:['ignore','ignore','pipe']});
  let socket, browserLog='';browser.stderr.on('data',d=>browserLog+=d.toString().slice(0,1000));
  try{
    const portFile=path.join(base,'browser-profile','DevToolsActivePort');
    let debugPort;
    for(let i=0;i<150;i++){if(fs.existsSync(portFile)){debugPort=Number(fs.readFileSync(portFile,'utf8').split('\n')[0]);break;}if(browser.exitCode!==null)throw Error('Headless browser exited');await pause(100);}
    if(!debugPort)throw Error('Headless browser startup timed out: '+browserLog.slice(-1000));
    const targets=await (await fetch(`http://127.0.0.1:${debugPort}/json/list`)).json();
    const target=targets.find(t=>t.type==='page');if(!target)throw Error('No headless page');
    socket=new WebSocket(target.webSocketDebuggerUrl);await new Promise((r,j)=>{socket.addEventListener('open',r,{once:true});socket.addEventListener('error',j,{once:true});});
    let serial=0;const pending=new Map();const errors=[];
    socket.addEventListener('message',e=>{const v=JSON.parse(e.data);if(v.method==='Runtime.exceptionThrown')errors.push(v.params.exceptionDetails.text);if(v.id && pending.has(v.id)){const {r,j,t}=pending.get(v.id);clearTimeout(t);pending.delete(v.id);v.error?j(Error(v.error.message)):r(v.result);}});
    const send=(method,params={})=>new Promise((r,j)=>{const id=++serial,t=setTimeout(()=>{pending.delete(id);j(Error('CDP timed out: '+method));},12000);pending.set(id,{r,j,t});socket.send(JSON.stringify({id,method,params}));});
    const evaluate=async expression=>{const r=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result.value;};
    const waitFor=async expression=>{for(let i=0;i<100;i++){if(await evaluate(expression))return;await pause(50);}throw Error('Page condition timed out: '+expression);};
    const goto=async suffix=>{await send('Page.navigate',{url:`http://127.0.0.1:${port}/${suffix}`});await waitFor("document.querySelectorAll('.lane').length===5 && document.querySelector('#signal-title').textContent !== 'Waiting for PC status'");await evaluate('document.fonts.ready');};
    await send('Page.enable');await send('Runtime.enable');
    await send('Emulation.setDeviceMetricsOverride',{width:412,height:720,deviceScaleFactor:1,mobile:true});
    const selected={overview:null,running:'main',waiting:'b',blocked:'c',failed:'c',finished:'d',gap:'main',stale:'deepseek',offline:null,unknown:'main',leftover:null,ended:'deepseek','github-unread':null,'needs-ryan':null,'no-needs-ryan':null,night:null};
    const screenshot=async name=>{const shot=await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});fs.writeFileSync(path.join(out,`MC-951-${name}.png`),Buffer.from(shot.data,'base64'));};
    for(const name of Object.keys(cases)){
      await goto('?fixture='+name);
      if(selected[name])await evaluate(`document.getElementById('lane-${selected[name]}').scrollIntoView({block:'start'});window.scrollBy(0,-52)`);
      const state=await evaluate(`document.getElementById('lane-${selected[name] || 'main'}').dataset.state`);
      if(selected[name])assert.equal(state,({gap:'finished',ended:'blocked'})[name] || name);
      if(name==='gap') {
        await evaluate("document.querySelector('#lane-main button').click()");
        assert.match(await evaluate("document.querySelector('#sheet-content').textContent"),/Checked push confirmed/);
        assert.deepEqual(await evaluate("[...document.querySelectorAll('#sheet-content .queue .number')].map(a=>a.textContent)"),['#920','#921','#923']);
        assert.match(await evaluate("document.querySelector('#sheet-content .source').textContent"),/codex_chain_fixture.txt/);
        await evaluate("document.getElementById('sheet').close()");
      }
      if(name==='offline'){assert.match(await evaluate("document.getElementById('offline').textContent"),/PC FEED LOST/);assert(await evaluate("document.body.classList.contains('last-known')"));}
      if(name==='github-unread'){assert.match(await evaluate("document.getElementById('attention').textContent"),/For you: not checked/);assert.match(await evaluate("document.getElementById('counts').textContent"),/\?FOR YOU/);}
      if(name==='needs-ryan'){assert.match(await evaluate("document.querySelector('#attention .kind').textContent"),/Needs you/);assert.equal(await evaluate("document.querySelector('#attention .picture-link').href"),'https://github.com/rcbailey12/voidsworn/issues/855');}
      if(name==='no-needs-ryan')assert.match(await evaluate("document.getElementById('counts').textContent"),/0FOR YOU/);
      assert.equal(await evaluate("[...document.querySelectorAll('.no-live')].every(n=>n.textContent==='NO LIVE FEED')"),true);
      assert(await evaluate("document.querySelector('#crew-artoo img').naturalWidth>0"));
      assert(await evaluate('document.documentElement.scrollWidth<=412'),'horizontal overflow in '+name);
      await screenshot(name);
      console.log('PASS phone fixture '+name+' at 412 x 720');
    }
    live=structuredClone(cases.overview);live.schemaVersion=1;delete live.build;live.generatedAt=new Date().toISOString();
    await goto('');assert.equal(await evaluate("document.querySelectorAll('.lane').length"),5);
    console.log('PASS compatibility page also renders schema 1');
    await goto('?fixture=night');
    await evaluate("document.getElementById('lane-b').scrollIntoView({block:'start'});window.scrollBy(0,-52)");await screenshot('lanes');
    await evaluate("document.getElementById('crew-heading').scrollIntoView({block:'start'});window.scrollBy(0,-52)");await screenshot('crew');
    await evaluate("document.querySelector('#lane-main button').click()");
    assert.equal(await evaluate("document.querySelectorAll('#sheet-content .queue a').length"),5);
    assert.match(await evaluate("document.getElementById('sheet-title').textContent"),/no floating ring/);
    await screenshot('detail');
    await evaluate("document.getElementById('sheet').scrollTop=document.getElementById('sheet').scrollHeight");await screenshot('detail-queue');
    await send('Input.dispatchKeyEvent',{type:'keyDown',key:'Escape',code:'Escape',windowsVirtualKeyCode:27});await send('Input.dispatchKeyEvent',{type:'keyUp',key:'Escape',code:'Escape',windowsVirtualKeyCode:27});
    await waitFor("!document.getElementById('sheet').open");
    await waitFor("document.activeElement===document.querySelector('#lane-main button')");
    assert.equal(await evaluate("document.activeElement===document.querySelector('#lane-main button')"),true);
    console.log('PASS lane sheet full title, full queue, Escape and return focus');
    // Real clock aging and fetch loss, with no frozen fixture clock.
    live=JSON.parse(JSON.stringify(cases.overview));delete live.fixtureNow;
    live.generatedAt=new Date(Date.now()-179000).toISOString();
    await goto('');
    await evaluate('window.missionClockOffset=0');
    await evaluate('window.originalNow=Date.now;Date.now=()=>window.originalNow()+2000');
    live=null;
    await evaluate("document.getElementById('refresh').click()");
    await waitFor("!document.getElementById('offline').classList.contains('hidden')");
    assert.equal(await evaluate("document.querySelectorAll('.lane').length"),5);
    console.log('PASS phone offline threshold and retained rows after refresh failure');
    // A hostile title is text, and hostile source links cannot become navigation targets.
    live=JSON.parse(JSON.stringify(cases.overview));live.generatedAt=new Date().toISOString();
    live.lanes[0].current.title='<img src=x onerror="window.injected=1">';live.lanes[0].current.url='javascript:alert(1)';live.lanes[0].current.prUrl='javascript:alert(1)';
    await goto('');assert.equal(await evaluate('!!window.injected'),false);await evaluate("document.querySelector('#lane-main button').click()");assert.equal(await evaluate("document.querySelector('#sheet-content .sheet-links a').href"),'https://github.com/rcbailey12/voidsworn/issues/918');
    console.log('PASS phone title escaping and fixed GitHub links');
    await evaluate("document.getElementById('close-sheet').focus();document.dispatchEvent(new Event('visibilitychange'))");
    const focusKept=await evaluate("new Promise(resolve=>setTimeout(()=>resolve(document.getElementById('sheet').open && document.activeElement===document.getElementById('close-sheet')),200))");
    assert(focusKept);console.log('PASS phone refresh preserves open sheet and keyboard focus');
    live.github.ok=false;await evaluate("document.getElementById('sheet').close();document.getElementById('refresh').click()");
    await waitFor("document.getElementById('github-signal').textContent.includes('not read since')");
    assert.equal(await evaluate("document.querySelector('#counts .for-you strong').textContent"),'0');
    console.log('PASS GitHub failure retains dated last good questions');
    // Compact phone and enlarged type must both keep all rows within viewport width.
    for(const width of [320,412]){
      await send('Emulation.setDeviceMetricsOverride',{width,height:720,deviceScaleFactor:1,mobile:true});
      await evaluate("document.documentElement.style.fontSize='21px'");
      assert(await evaluate(`document.documentElement.scrollWidth<=${width}`),'large type overflow');
      await evaluate("document.querySelector('#lane-main button').click()");assert(await evaluate("document.getElementById('sheet').scrollWidth<=document.getElementById('sheet').clientWidth"),'sheet overflow');await evaluate("document.getElementById('sheet').close()");
    }
    assert.deepEqual(errors,[]);
    console.log('PASS phone small screen, enlarged type and no browser exceptions');
    console.log('PASS mission phone browser checks; screenshots in '+out);
    await send('Browser.close');
  }finally{
    if(socket)socket.close();
    if(browser.exitCode===null && browser.signalCode===null){try{browser.kill();}catch(_){console.error('Headless browser process could not be closed by this shell.');}}
    await new Promise(r=>server.close(r));
  }
}
if(require.main===module)run().catch(e=>{console.error('FAIL mission phone: '+e.stack);process.exitCode=1;});
