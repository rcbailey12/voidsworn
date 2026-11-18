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
const reviewViewports = [
  {name:'pixel',width:448,height:997,mobile:true},
  {name:'desktop',width:1440,height:900,mobile:false}
];

function fixtureServer(getFixture) {
  return http.createServer((req,res)=>{
    const fixture = getFixture();
    res.setHeader('Cache-Control','no-store');
    if (req.url.split('?')[0]==='/') return res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'}).end(fs.readFileSync(path.join(pageRoot,'index.html')));
    if (req.url==='/status.json') {
      if (!fixture) return res.writeHead(503).end();
      return res.writeHead(200,{'Content-Type':'application/json'}).end(JSON.stringify(fixture.data));
    }
    if (Object.hasOwn(ASSETS,req.url)) return res.writeHead(200,{'Content-Type':ASSETS[req.url]}).end(fs.readFileSync(path.join(pageRoot,req.url.slice(1))));
    res.writeHead(404).end();
  });
}

async function devTools(browser, profile) {
  const portFile = path.join(profile,'DevToolsActivePort');
  let port;
  for (let i=0; i<150; i++) {
    if (fs.existsSync(portFile)) {
      port = Number(fs.readFileSync(portFile,'utf8').split('\n')[0]);
      break;
    }
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
  const targets = [...document.querySelectorAll('a[href],summary')].filter(node=>node.checkVisibility());
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
    async function screen(name,hash,test) {
      live = cases[name];
      await send('Page.removeScriptToEvaluateOnNewDocument',{identifier:clockScript});
      const clock = live.now || now;
      clockScript = (await send('Page.addScriptToEvaluateOnNewDocument',{source:'window.missionClock='+clock+'; Date.now=()=>window.missionClock;'})).identifier;
      // A unique query forces navigation even when only fixture data changed.
      await send('Page.navigate',{url:'http://127.0.0.1:'+server.address().port+'/?case='+name+hash});
      await waitFor(test);
      await evaluate('document.fonts.ready.then(()=>true)');
      await waitFor('[...document.images].every(img=>img.complete && img.naturalWidth>0)');
    }
    const shotNames = [];
    async function capture(name, y = 0) {
      const shot = 'MC-1117-'+name+'.png';
      const revision = live.data.build.sourceRevision;
      assert.match(revision,/^[a-f0-9]{40}$/);
      const code = 'MC-1117 / '+name.toUpperCase()+' / FIXTURE / BUILD '+revision.slice(0,12);
      if (!y) await evaluate('(()=>{const label=document.createElement("p"); label.className="fixture-label"; label.textContent='+JSON.stringify(code)+'; document.querySelector("header").after(label);})()');
      const width = await evaluate('innerWidth');
      // The provenance strip scales up on desktop. Leave room beneath the page for it.
      const ceiling = width>=1440 ? 620 : H;
      const height = y ? Math.min(ceiling,await evaluate('document.documentElement.scrollHeight')-y) : ceiling;
      const image = await send('Page.captureScreenshot',{format:'png',clip:{x:0,y,width,height,scale:1},captureBeyondViewport:!!y});
      fs.writeFileSync(path.join(scratch,shot),Buffer.from(image.data,'base64'));
      shotNames.push(shot);
    }
    async function check(name) {
      const layout = await evaluate('('+checkLayout.toString()+')()');
      assert.deepEqual(layout,{low:[],dimPanels:[],overflow:false,small:[]},name);
      const dom = await evaluate('(()=>{const body=document.body.cloneNode(true); body.querySelectorAll("script").forEach(node=>node.remove()); return body.outerHTML;})()');
      assert(!/\/pic\/|picture-empty|picture-preview|picture-caption|No picture yet/i.test(dom),name+' rendered a picture preview');
      const privacy = dom+'\n'+JSON.stringify(live.data);
      assert(!/(?:^|[^a-z])[a-z]:[\\/]|\\\\Users\\|(?:\\|\/)(?:Users|home)(?:\\|\/)|RAW-LOG-SENTINEL|PrivatePerson|FOLDER-SENTINEL|MARKER-SENTINEL|0123456789abcdef0123456789abcdef/i.test(privacy),name+' leaked PC data');
      if (process.env.USERNAME) {
        const user = process.env.USERNAME.replace(/[.*+?^$(){}|[\]\\]/g,'\\$&');
        assert(!new RegExp('(^|[^a-z0-9_])'+user+'($|[^a-z0-9_])','i').test(privacy),name+' leaked user name');
      }
      assert.equal(await evaluate('document.getAnimations().length'),0);
    }

    const screens = [
      ['overview','',has('.hero-title',/Working.*Iron Mandate/is)],
      ['task','#task/main/970',has('.task-title',/Iron Mandate/)],
      ['decision','',has('.question',/Keep the egg shield/)],
      ['failure','',has('.failure',/Runner exit 8/)],
      ['offline','',has('#alerts',/PC feed lost/i)],
      ['unknown','#task/main/970',has('.task-title',/unreadable or unrecognized/)],
      ['no-picture','#task/main/970',has('.task-title',/Iron Mandate/)],
      ['missing-picture','#task/main/970',has('.task-title',/Iron Mandate/)],
      ['queue','#queue',has('#queue-main',/Ready, start pending/i)],
      ['crew','#crew',has('#crew-artoo',/Last seen on GitHub/)],
      ['blocked','#task/c/978',has('.task-title',/Blocked/i)],
      ['quiet','#task/d/979',has('.task-title',/Quiet/i)],
      ['checked-push','#task/main/970',has('.timeline',/PC confirmed a checked push/)],
      ['ended','#task/deepseek/916',has('.task-title',/Ended without a push/i)],
      ['leftover','',has('#content',/Older Codex main record #944/)],
      ['claim','#task/main/970',has('.task-title',/Claimed/i)],
      ['claim-old','#task/main/970',has('.task-title',/Claim not confirmed/i)],
      ['github-unread','',has('#content',/Checking for questions/)],
      ['legacy','',has('#alerts',/Restart with PHONE_ON/)],
      ['legacy-listing','',has('#content',/Last listed, queue unverified.*#922/)],
      ['pr-only','#task/main/970',has('.timeline',/PR open.*PR #1008 open/s)],
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
      if (name==='failure') await evaluate('document.querySelector(".failure details").open=true');
      if (name==='queue') await evaluate('document.querySelector("#queue-b details").open=true');
      await check(name);
      if (name==='overview') {
        assert.match(await evaluate('document.querySelector("#content").innerText'),/On the queue.*#982/);
        assert(await evaluate('document.fonts.check("700 22px Chakra") && document.fonts.check("800 22px Shoulders")'));
        assert.equal(await evaluate('document.querySelectorAll(".mate-strip .ring.github").length'),4);
        assert.equal(await evaluate('document.querySelectorAll(".mate-strip img").length'),6);
      }
      if (name==='decision') {
        assert.match(await evaluate('document.querySelector(".question").innerText'),/Answer the Board in chat/);
        assert.match(await evaluate('document.querySelector(".question").innerText'),/View Board picture/);
      }
      if (name==='failure') {
        assert.match(await evaluate('document.querySelector(".failure details").innerText'),/Evidence.*status.json/s);
      }
      if (name==='offline') {
        assert.match(await evaluate('document.querySelector(".hero .status").innerText'),/was working/i);
        assert(!await evaluate(has('#content',/On the queue/)));
      }
      if (name==='legacy-listing') assert(!await evaluate(has('#content',/On the queue/)));
      if (name==='pr-only') {
        const stages = await evaluate('[...document.querySelectorAll(".timeline li")].map(stage=>[stage.querySelector("strong").textContent,stage.hasAttribute("data-proved")])');
        assert.deepEqual(stages.slice(2,4),[['Pushed',false],['PR open',true]]);
        assert(!await evaluate(has('.timeline',/Review/i)));
      }
      if (name==='pc-partial') {
        const notes = await evaluate('(()=>{const row = document.querySelector("details[data-keep=now-sources]");row.open=true; return row.innerText;})()');
        assert.match(notes,/PC files incomplete.*last successful scan.*3 min ago.*Chain script missing/s);
      }
      if (name==='unknown') assert.match(await evaluate('document.querySelector(".task-title .status").innerText'),/^unknown$/i);
      if (name==='queue') {
        assert.match(await evaluate('document.querySelector("#queue-main").innerText'),/40 min.*waiting window may be closed/s);
        assert.match(await evaluate('document.querySelector("#queue-main").innerText'),/Closed on GitHub; chain still lists it/);
        assert.match(await evaluate('document.querySelector("#queue-b details").innerText'),/cancelled/);
        assert.match(await evaluate('document.querySelector("#queue-d").innerText'),/Stuck.*target not found/is);
      }
      if (name.startsWith('github-') && name!=='github-unread') {
        assert.match(await evaluate('document.querySelector(".hero .status").innerText'),/working/i);
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
    await screen('overview','',has('.hero-title',/Iron Mandate/));
    await check('320 px overview');
    await evaluate('document.querySelector(".hero-open").click()');
    await waitFor(has('.task-title',/Iron Mandate/));
    assert(await evaluate('document.activeElement.tagName==="H2"'));
    await evaluate('document.querySelector(".back").click()');
    await waitFor(has('.hero-title',/Iron Mandate/));
    await evaluate('document.querySelector("#nav-crew").click()');
    await waitFor(has('#crew-artoo',/Last seen on GitHub/));
    await evaluate('document.querySelector("#nav-queue").click()');
    await waitFor(has('#queue-b',/Codex lane B/));

    await size(W);
    await screen('starting','',has('#content',/Mission Control is starting/i));
    live = cases.overview;
    await waitFor(has('.hero-title',/Iron Mandate/));
    await evaluate('window.missionClock+=181000; document.dispatchEvent(new Event("visibilitychange"))');
    await waitFor(has('#alerts',/PC feed lost/i));
    assert.deepEqual(cdp.errors,[]);
    for (const viewport of reviewViewports) {
      await size(viewport.width,viewport.height,viewport.mobile);
      for (const [name,fixture,hash,ready] of [
        ['now','overview','',has('.hero-title',/Iron Mandate/)],
        ['queue','queue','#queue',has('#queue-main',/Ready, start pending/i)],
        ['crew','crew','#crew',has('#crew-artoo',/Last seen on GitHub/)]
      ]) {
        await screen(fixture,hash,ready);
        await check(name+' '+viewport.name);
        await capture(name+'-'+viewport.name);
        if (name==='crew') {
          const y = await evaluate('Math.floor(document.querySelector("#crew-muse").getBoundingClientRect().top)');
          // Keep the fixed viewport tabs from covering rows in the lower document crop.
          await evaluate('document.querySelector("nav").hidden=true');
          await capture(name+'-'+viewport.name+'-continued',y);
        }
      }
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
