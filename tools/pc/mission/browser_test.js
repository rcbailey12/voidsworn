'use strict';
// Run an installed Chromium browser headlessly through CDP. All requests stay on loopback.
const fs = require('fs');
const path = require('path');
const os = require('os');
const http = require('http');
const {spawn, spawnSync} = require('child_process');
const assert = require('assert/strict');
const {makeCases} = require('./selftest');
const {ASSETS} = require('./publisher');

const repo = path.resolve(__dirname,'../../..');
const pageRoot = path.join(repo,'docs/mission');
const pause = ms => new Promise(resolve=>setTimeout(resolve,ms));
const W = 412, H = 670;

function fixtureServer(getFixture) {
  return http.createServer((req,res)=>{
    const fixture = getFixture();
    res.setHeader('Cache-Control','no-store');
    if (req.url.split('?')[0]==='/') return res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'}).end(fs.readFileSync(path.join(pageRoot,'index.html')));
    if (req.url==='/status.json') {
      if (!fixture) return res.writeHead(503).end();
      return res.writeHead(200,{'Content-Type':'application/json'}).end(JSON.stringify(fixture.data));
    }
    const picture = /^\/pic\/([a-f0-9]{64})$/.exec(req.url);
    const indexed = picture && fixture?.pictures.get(picture[1]);
    if (indexed) return res.writeHead(200,{'Content-Type':indexed.type}).end(fs.readFileSync(indexed.file));
    if (Object.hasOwn(ASSETS,req.url)) return res.writeHead(200,{'Content-Type':ASSETS[req.url]}).end(fs.readFileSync(path.join(pageRoot,req.url.slice(1))));
    res.writeHead(404).end();
  });
}

async function devTools(browser, profile) {
  const portFile = path.join(profile,'DevToolsActivePort');
  let port;
  for (let i=0; i<150; i++) {
    try {
      port = Number(fs.readFileSync(portFile,'utf8').split('\n')[0]);
      if (port) break;
    } catch (error) { if (!['ENOENT','EBUSY'].includes(error.code)) throw error; }
    if (browser.exitCode!==null) throw Error('Headless browser exited');
    await pause(100);
  }
  if (!port) throw Error('Headless browser startup timed out');
  const target = (await (await fetch('http://127.0.0.1:'+port+'/json/list')).json()).find(item=>item.type==='page');
  const socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve,reject)=>{
    socket.addEventListener('open',resolve,{once:true});
    socket.addEventListener('error',reject,{once:true});
  });
  const errors = [], pending = new Map();
  let serial = 0;
  socket.addEventListener('message',event=>{
    const reply = JSON.parse(event.data);
    if (reply.method==='Runtime.exceptionThrown') errors.push(reply.params.exceptionDetails.text);
    if (!pending.has(reply.id)) return;
    const {resolve,reject,timer} = pending.get(reply.id);
    clearTimeout(timer);
    pending.delete(reply.id);
    if (reply.error) reject(Error(reply.error.message));
    else resolve(reply.result);
  });
  function send(method,params={}) {
    return new Promise((resolve,reject)=>{
      const id = ++serial;
      const timer = setTimeout(()=>{ pending.delete(id); reject(Error('CDP timed out: '+method)); },12000);
      pending.set(id,{resolve,reject,timer});
      socket.send(JSON.stringify({id,method,params}));
    });
  }
  async function evaluate(expression) {
    const response = await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});
    if (response.exceptionDetails) throw Error(JSON.stringify(response.exceptionDetails));
    return response.result.value;
  }
  async function waitFor(expression) {
    for (let i=0; i<120; i++) {
      if (await evaluate(expression)) return;
      await pause(45);
    }
    throw Error('Page condition timed out: '+expression);
  }
  return {send,evaluate,waitFor,errors,close:()=>socket.close()};
}

function checkLayout() {
  const color = value => value.match(/[\d.]+/g).map(Number);
  const over = (base,top) => base.map((value,channel)=>value*(1-(top[3] ?? 1))+top[channel]*(top[3] ?? 1));
  const luma = rgb => rgb.map(value=>value/255).map(value=>value<=.04045 ? value/12.92 : ((value+.055)/1.055)**2.4)
    .reduce((sum,value,index)=>sum+value*[.2126,.7152,.0722][index],0);
  function background(node) {
    if (!node) return over([24,35,26],[200,245,58,.045]); // Brightest deck gradient plus the hex stroke.
    const style = getComputedStyle(node);
    let effective = over(background(node.parentElement),color(style.backgroundColor));
    if (node.classList.contains('striped')) effective = over(effective,[255,178,62,.063]);
    return effective;
  }
  const low = [], dimPanels = [];
  const walk = document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT);
  for (let text; (text=walk.nextNode());) {
    const element = text.parentElement;
    if (!text.textContent.trim() || element.closest('script,style') || !element.checkVisibility()) continue;
    const fore = luma(color(getComputedStyle(element).color)), back = luma(background(element));
    const ratio = (Math.max(fore,back)+.05)/(Math.min(fore,back)+.05);
    if (ratio<4.5) low.push([text.textContent.slice(0,60),ratio]);
    if (element.classList.contains('meta') && element.closest('.on-panel') &&
      getComputedStyle(element).color===getComputedStyle(document.querySelector('.brand small')).color) dimPanels.push(text.textContent);
  }
  const targets = [...document.querySelectorAll('a[href],summary,button')].filter(node=>node.checkVisibility());
  return {low,dimPanels,overflow:document.documentElement.scrollWidth>innerWidth,
    small:targets.filter(node=>node.getBoundingClientRect().height<44 || node.getBoundingClientRect().width<44).map(node=>node.textContent)};
}

function stampShots(python, scratch, out, names) {
  if (!python) {
    for (const shot of names) fs.copyFileSync(path.join(scratch,shot),path.join(out,shot));
    return;
  }
  const script = [
    'from pathlib import Path',
    'import sys',
    'from PIL import Image',
    'repo, scratch, out, *names = sys.argv[1:]',
    'sys.path.insert(0, str(Path(repo) / "tools"))',
    'from picture_provenance import save_picture, verify',
    'for name in names:',
    '    source = Image.open(Path(scratch) / name).convert("RGB")',
    '    image = Image.new("RGB", (source.width, 720), "#090c09")',
    '    image.paste(source, (0, 0))',
    '    target = Path(out) / name',
    '    save_picture(image, target, "sheet built", repo=Path(repo))',
    '    verify(target)'
  ].join('\n');
  const run = spawnSync(python,['-B','-c',script,repo,scratch,out,...names],{encoding:'utf8',windowsHide:true});
  if (run.error || run.status!==0) throw Error('Could not stamp review pictures: '+(run.error?.message || run.stderr));
}

async function run() {
  const base = fs.mkdtempSync(path.join(os.tmpdir(),'mission-deck-'));
  const out = process.argv[2] ? path.resolve(process.argv[2]) : path.join(base,'shots');
  const scratch = path.join(base,'captures');
  fs.mkdirSync(out,{recursive:true});
  fs.mkdirSync(scratch);
  const {cases,now} = makeCases(base);
  let live = cases.overview;
  const server = fixtureServer(()=>live);
  const exe = process.env.MISSION_BROWSER ||
    ['C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe','C:/Program Files/Google/Chrome/Application/chrome.exe'].find(file=>fs.existsSync(file));
  if (!exe) throw Error('Installed Edge or Chrome required. Set MISSION_BROWSER to its executable.');
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const profile = path.join(base,'browser-profile');
  const browser = spawn(exe,['--headless=new','--disable-gpu','--no-first-run','--disable-extensions',
    '--disable-background-networking','--disable-component-update','--disable-sync','--remote-debugging-address=127.0.0.1',
    '--remote-debugging-port=0','--user-data-dir='+profile,'about:blank'],{windowsHide:true,stdio:['ignore','ignore','pipe']});
  let cdp, browserLog = '', browserError;
  browser.on('error',error=>{browserError=error;});
  browser.stderr.on('data',chunk=>{browserLog=(browserLog+chunk.toString()).slice(-2000);});
  try {
    cdp = await devTools(browser,profile);
    const {send,evaluate,waitFor} = cdp;
    await send('Page.enable');
    await send('Runtime.enable');
    const size = (width,height = H,mobile = true) => send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile});
    await size(W);
    await send('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-motion',value:'reduce'}]});
    const injected = await send('Page.addScriptToEvaluateOnNewDocument',{source:'window.missionClock='+now+'; Date.now=()=>window.missionClock;'});
    let clockScript = injected.identifier;
    function has(selector,pattern) {
      return '('+pattern+').test(document.querySelector('+JSON.stringify(selector)+')?.innerText || "")';
    }
    async function screen(name,hash,test,project) {
      live = project ? {...cases[name],data:project(structuredClone(cases[name].data))} : cases[name];
      await send('Page.removeScriptToEvaluateOnNewDocument',{identifier:clockScript});
      const clock = live.now || now;
      clockScript = (await send('Page.addScriptToEvaluateOnNewDocument',{source:'window.missionClock='+clock+'; Date.now=()=>window.missionClock;'})).identifier;
      // A unique query forces navigation even when only fixture data changed.
      await send('Page.navigate',{url:'http://127.0.0.1:'+server.address().port+'/?case='+name+hash});
      await waitFor(test);
      await evaluate('document.fonts.ready.then(()=>true)');
      await waitFor('[...document.images].every(img=>img.complete && (img.closest("figure") || img.naturalWidth>0))');
    }
    const shotNames = [];
    async function capture(name) {
      const shot = 'MC-1118-'+name+'-pixel.png';
      const revision = live.data.build.sourceRevision;
      assert.match(revision,/^[a-f0-9]{40}$/);
      const code = 'MC-1118 / '+name.toUpperCase()+' / SAMPLE DATA / '+revision.slice(0,12);
      await evaluate('(()=>{const label=document.createElement("p"); label.className="fixture-label"; label.textContent='+JSON.stringify(code)+'; document.querySelector("header").after(label);})()');
      const width = await evaluate('innerWidth');
      assert.equal(width,W);
      const image = await send('Page.captureScreenshot',{format:'png',clip:{x:0,y:0,width,height:H,scale:1}});
      fs.writeFileSync(path.join(scratch,shot),Buffer.from(image.data,'base64'));
      shotNames.push(shot);
    }
    async function check(name) {
      const layout = await evaluate('('+checkLayout.toString()+')()');
      assert.deepEqual(layout,{low:[],dimPanels:[],overflow:false,small:[]},name);
      const dom = await evaluate('(()=>{const body=document.body.cloneNode(true); body.querySelectorAll("script").forEach(node=>node.remove()); return body.outerHTML;})()');
      assert(!/picture-empty|No picture yet/i.test(dom),name+' rendered a picture placeholder');
      const privacy = dom+'\n'+JSON.stringify(live.data);
      assert(!/(?:^|[^a-z])[a-z]:[\\/]|\\\\Users\\|(?:\\|\/)(?:Users|home)(?:\\|\/)|RAW-LOG-SENTINEL|PrivatePerson|FOLDER-SENTINEL|MARKER-SENTINEL|0123456789abcdef0123456789abcdef/i.test(privacy),name+' leaked PC data');
      if (process.env.USERNAME) {
        const user = process.env.USERNAME.replace(/[.*+?^$(){}|[\]\\]/g,'\\$&');
        assert(!new RegExp('(^|[^a-z0-9_])'+user+'($|[^a-z0-9_])','i').test(privacy),name+' leaked user name');
      }
      assert.equal(await evaluate('document.getAnimations().length'),0);
    }

    const screens = [
      ['overview','',has('#now-main .now',/Iron Mandate.*Running/is)],
      ['task','#task/main/970',has('.task-title',/Iron Mandate/)],
      ['decision','',has('.question',/Keep the egg shield/)],
      ['failure','#task/b/928',has('.task-title',/Runner exit 8/)],
      ['offline','',has('#alerts',/PC feed lost/i)],
      ['unknown','#task/main/970',has('.task-title',/unreadable or unrecognized/)],
      ['no-picture','#task/main/970',has('.task-title',/Iron Mandate/)],
      ['missing-picture','#task/main/970',has('.task-title',/Iron Mandate/)],
      ['queue','#queue',has('#queue-main',/Ready, start pending/i)],
      ['crew','#crew',has('#crew-artoo',/Last seen on GitHub/)],
      ['blocked','#task/c/978',has('.task-title',/Blocked/i)],
      ['quiet','#task/d/979',has('.task-title',/Quiet/i)],
      ['checked-push','#task/main/970',has('.timeline',/Checked push confirmed/)],
      ['ended','#task/deepseek/916',has('.task-title',/run ended without a confirmed push/i)],
      ['leftover','',has('#now-main',/Details/)],
      ['claim','#task/main/970',has('.task-title',/Claimed/i)],
      ['claim-old','#task/main/970',has('.task-title',/Claim not confirmed/i)],
      ['github-unread','',has('#content',/Checking for questions/)],
      ['legacy','',has('#alerts',/Restart with PHONE_ON/)],
      ['legacy-listing','',has('#now-main',/#922.*Last listed, queue unverified/is)],
      ['legacy-listing','#queue',has('#queue-main',/#922.*Last listed, queue unverified/is)],
      ['legacy-listing','#task/main/922',has('.task-title',/Last listed, queue unverified/i)],
      ['pr-only','#task/main/970',has('.timeline',/PR recorded.*#1008.*open/s)],
      ['pr-merged','#task/main/970',has('.timeline',/PR recorded.*#1008.*merged/s)],
      ['pr-closed','#task/main/970',has('.timeline',/PR recorded.*#1008.*closed/s)],
      ['review','#task/main/970',has('.timeline',/Technical review recorded.*recorded PR head/s)],
      ['needs-ryan','',has('#content',/Keep the blue glow on the bow gun/)],
      ['question-partial','',has('#content',/Needs Ryan check incomplete/)],
      ['pc-partial','',has('#alerts',/Chain script missing/)],
      ['no-build','',has('#alerts',/Restart with PHONE_ON/)],
      ['old-build','',has('#alerts',/Restart with PHONE_ON/)],
      ['starting','',has('#content',/first read of PC files is in progress/)],
      ['long-title','#task/main/970',has('.task-title',/L{240}/)],
      ['privacy','#task/main/970',has('.task-title',/title withheld/)],
      ...['questions','issues','pulls','comments'].map(source=>['github-'+source,'',has('#alerts',/GitHub unavailable/i)]),
      ['nov17','#queue',has('#queue-d',/Codex lane D/)]
    ];
    for (const [name,hash,test] of screens) {
      await screen(name,hash,test);
      if (name==='failure') await evaluate('document.querySelector("details[data-keep=run-b]").open=true');
      if (name==='queue') await evaluate('document.querySelector("#queue-b details").open=true');
      await check(name);
      if (name==='overview') {
        assert.match(await evaluate('document.querySelector("#now-main .next").innerText'),/After #970.*#982/is);
        assert.match(await evaluate('document.querySelector("#queue-count").innerText'),/3 recorded waiting jobs/);
        assert(await evaluate('document.fonts.check("700 22px Chakra") && document.fonts.check("800 22px Shoulders")'));
        assert.equal(await evaluate('document.querySelectorAll(".mate-strip .ring.github").length'),3);
        assert.equal(await evaluate('document.querySelectorAll(".mate-strip img").length'),6);
      }
      if (name==='decision') {
        assert.match(await evaluate('document.querySelector(".question").innerText'),/Answer the Board in chat/);
        assert.match(await evaluate('document.querySelector(".question").innerText'),/View Board picture/);
      }
      if (name==='failure') {
        assert.match(await evaluate('document.querySelector("details[data-keep=run-b]").innerText'),/Evidence.*status.json/s);
      }
      if (name==='offline') {
        assert.match(await evaluate('document.querySelector("#now-main .status").innerText'),/last known.*running/i);
        assert(!await evaluate(has('#content',/Nothing waiting on you/)));
      }
      if (name==='legacy-listing') assert(!await evaluate(has('#queue-count',/recorded waiting jobs?/)));
      if (['pr-only','pr-merged','pr-closed'].includes(name)) {
        const stages = await evaluate('[...document.querySelectorAll(".timeline li")].map(stage=>[stage.querySelector("strong").textContent,stage.hasAttribute("data-proved")])');
        assert.deepEqual(stages.slice(1),[['Checked push unconfirmed',false],['PR recorded',true],['Review evidence unavailable',false]]);
        assert(!await evaluate(has('.timeline',/reviewed|checked push confirmed/i)));
      }
      if (name==='task') {
        assert(await evaluate('document.querySelector("figure.job-picture").checkVisibility()'));
        await evaluate('(()=>{Object.defineProperty(navigator,"clipboard",{value:undefined});document.querySelector(".copy-button").click();})()');
        assert.match(await evaluate('document.querySelector(".check-in").value'),/Check-in for the Board.*#970/s);
        assert(await evaluate('document.querySelector(".check-in").selectionEnd>0'));
      }
      if (name==='no-picture' || name==='missing-picture') assert(!await evaluate('document.querySelector("figure.job-picture")?.checkVisibility() || false'));
      if (name==='needs-ryan' || name==='question-partial') {
        assert(await evaluate(has('#content',/Needs Ryan flagged; question unavailable/)));
        assert(await evaluate(has('#content',/Open issue #931/)));
        assert(!await evaluate(has('#content',/Nothing waiting on you|just a draft|View Board picture/)));
        if (name==='question-partial') assert(await evaluate(has('.question',/Needs Ryan · last known.*1 h 5 min ago/is)));
      }
      if (name==='crew') {
        assert(await evaluate(has('#crew-openai',/OpenAI workhorse patch/)));
        assert(await evaluate(has('#crew-deepseek',/Stage 5 self-test repair/)));
        assert(!await evaluate(has('#crew-openai',/Stage 5 self-test repair/)));
        assert(!await evaluate(has('#crew-deepseek',/OpenAI workhorse patch/)));
      }
      if (name==='leftover') {
        assert(!await evaluate(has('#now-main',/Older Codex main record #944/)));
        assert.match(await evaluate('(()=>{const d=document.querySelector("#now-main details");d.open=true;return d.innerText;})()'),/Older Codex main record #944/);
      }
      if (name==='pc-partial') {
        const notes = await evaluate('(()=>{const row = document.querySelector("details[data-keep=now-sources]");row.open=true; return row.innerText;})()');
        assert.match(notes,/PC files incomplete.*last successful scan.*3 min ago.*Chain script missing/s);
      }
      if (name==='unknown') assert.match(await evaluate('document.querySelector(".task-title .status").innerText'),/^unknown$/i);
      if (name==='queue') {
        assert.match(await evaluate('document.querySelector("#queue-main").innerText'),/40 min.*waiting window may be closed/s);
        assert.match(await evaluate('document.querySelector("#queue-main").innerText'),/Closed on GitHub; chain still lists it/);
        assert.equal(await evaluate('document.querySelectorAll("#queue-main .next .chain-group").length'),2);
        assert(await evaluate(has('#queue-main .next',/After #970.*#923.*After #920.*#921/s)));
        assert(await evaluate(has('#queue-main .attention',/Old .*no recorded ending.*target not found.*#988/s)));
        assert(!await evaluate(has('#queue-main',/codex_chain_.*\.txt/)));
        assert.match(await evaluate('document.querySelector("#queue-b details").innerText'),/cancelled/);
        assert.match(await evaluate('document.querySelector("#queue-d").innerText'),/cancelled chain.*target not found.*target ambiguous/is);
      }
      if (name.startsWith('github-') && name!=='github-unread') {
        assert.match(await evaluate('document.querySelector("#now-main .status").innerText'),/running/i);
        const source = name.slice(7);
        const label = {questions:'Questions',issues:'Issues',pulls:'Pull requests',comments:'Comments'}[source];
        assert((await evaluate('document.querySelector("#alerts h2").textContent')).endsWith(label));
        assert.equal(await evaluate(has('#content',/Nothing waiting on you/)),source!=='questions');
        const rows = await evaluate('(()=>{const d=document.querySelector("details[data-keep=now-sources]");d.open=true;return [...d.querySelectorAll("li")].map(row=>row.innerText);})()');
        const index = ['questions','issues','pulls','comments'].indexOf(source);
        assert.match(rows[index],new RegExp('last known.*1 h 5 min ago.*GitHub returned HTTP '+(501+index),'s'));
        assert.equal(rows.filter(row=>row.includes('GitHub returned HTTP')).length,1);
      }
      console.log('PASS 412 px · '+name);
    }

    await size(320);
    await screen('long-title','#task/main/970',has('.task-title',/L{240}/));
    await check('320 px title');
    await screen('overview','',has('#now-main',/Iron Mandate/));
    await check('320 px overview');
    await evaluate('document.querySelector("#now-main .now a").click()');
    await waitFor(has('.task-title',/Iron Mandate/));
    assert(await evaluate('document.activeElement.tagName==="H2"'));
    await evaluate('document.querySelector(".back").click()');
    await waitFor(has('#now-main',/Iron Mandate/));
    await evaluate('document.querySelector("#nav-crew").click()');
    await waitFor(has('#crew-artoo',/Last seen on GitHub/));
    await evaluate('document.querySelector("#nav-queue").click()');
    await waitFor(has('#queue-b',/Codex lane B/));

    await size(W);
    await screen('starting','',has('#content',/Mission Control is starting/i));
    live = cases.overview;
    await waitFor(has('#now-main',/Iron Mandate/));
    await evaluate('window.missionClock+=181000; document.dispatchEvent(new Event("visibilitychange"))');
    await waitFor(has('#alerts',/PC feed lost/i));
    assert.deepEqual(cdp.errors,[]);
    for (const [name,fixture,hash,seat,ready] of [
      ['running','overview','#now','main',has('#now-main',/Running/i)],
      ['queued','queue-photo','#queue','main',has('#queue-main',/Ready, start pending/i)],
      ['blocked','blocked','#now','c',has('#now-c',/Blocked/i)],
      ['unknown','unknown','#now','main',has('#now-main',/target not found/i)],
      ['offline','offline','#now','main',has('#alerts',/PC feed lost/i)],
      ['needs-ryan','needs-ryan','#now','main',has('#content',/question unavailable/i)]
    ]) {
      await screen(fixture,hash,ready,data=>{
        data.lanes = data.lanes.filter(lane=>lane.id===seat);
        const lane = data.lanes[0];
        if (name==='unknown') lane.queue.groups = lane.queue.groups.filter(group=>group.state==='unknown');
        if (name==='offline') for (const group of lane.queue.groups) group.jobs = group.jobs.slice(0,1);
        return data;
      });
      await check(name+' capture');
      await capture(name);
    }
    assert.deepEqual(cdp.errors,[]);
    stampShots(process.env.MISSION_STAMP_PYTHON,scratch,out,shotNames);
    console.log('PASS Mission Control browser: '+screens.length+' states, narrow layout, startup, and '+shotNames.length+' fixture captures.');
  } catch (error) {
    console.error(browserError?.message || browserLog);
    throw error;
  } finally {
    cdp?.close();
    browser.kill();
    await new Promise(resolve=>server.close(resolve));
  }
}
run().catch(error=>{console.error('FAIL browser: '+error.stack);process.exitCode=1;});
