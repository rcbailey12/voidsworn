'use strict';
// No real Tailscale commands or real PC lane changes in these tests.
const assert = require('assert/strict');
const http = require('http');
const path = require('path');
const tailscale = require('./tailscale');
const publisher = require('./publisher');
const phone = require('./phone');
const HOST = 'mission-pc.example-tail.ts.net';
const STATUS = { BackendState: 'Running', Self: { DNSName: HOST + '.', Online: true } };
const PROXY = { Host: HOST, 'X-Forwarded-Host': HOST, 'X-Forwarded-Proto': 'https', 'X-Forwarded-For': '100.100.1.2' };
const configured = () => ({ TCP: {443: {HTTPS: true}}, Web: {[HOST + ':443']: {Handlers: {'/': {Proxy: phone.TARGET}}}} });

async function test(check, base, root) {
  check('Tailscale lookup includes install folders when absent from PATH', () => {
    const folder = path.join(base, 'Program Files'), expected = path.join(folder, 'Tailscale', 'tailscale.exe');
    assert.equal(tailscale.findTailscale({ProgramFiles: folder, PATH: ''}, candidate => candidate === expected), expected);
    assert.equal(tailscale.findTailscale({PATH: ''}, () => false), null);
    const bin = path.join(base, 'bin');
    assert.equal(tailscale.findTailscale({PATH: bin}, candidate => path.dirname(candidate) === bin), path.join(bin, process.platform === 'win32' ? 'tailscale.exe' : 'tailscale'));
  });
  check('discovery reads only the signed-in PC Self.DNSName and normalizes its dot', () => {
    let called = 0;
    const run = (exe, args, opts) => {
      called++; assert.equal(exe, 'fixture.exe'); assert.deepEqual(args, ['status', '--json']); assert.equal(opts.timeout, 5000);
      return {status: 0, stdout: JSON.stringify(STATUS)};
    };
    assert.equal(tailscale.discover(run, 'fixture.exe').host, HOST); assert.equal(called, 1);
    assert.equal(tailscale.dnsName({...STATUS, Self: {DNSName: HOST.toUpperCase() + '.'}}), HOST);
  });
  check('missing, unsigned, stopped, corrupt or failed Tailscale stays local only', () => {
    assert.equal(tailscale.discover(() => { throw Error('Must not run'); }, null).host, null);
    for (const status of [{}, {...STATUS, BackendState: 'NeedsLogin'}, {...STATUS, BackendState: 'Stopped'},
      {...STATUS, Self: {...STATUS.Self, Online: false}}, {...STATUS, Self: {}, Peer: {x: STATUS.Self}}]) {
      assert.equal(tailscale.discover(() => ({status: 0, stdout: JSON.stringify(status)}), 'fixture.exe').host, null);
    }
    for (const result of [{status: 1, stdout: JSON.stringify(STATUS)}, {status: 0, stdout: '{bad'}]) {
      assert.equal(tailscale.discover(() => result, 'fixture.exe').host, null);
    }
    assert.equal(tailscale.discover(() => { throw Error('Timeout'); }, 'fixture.exe').host, null);
    for (const name of ['outsider.example', '*.example.ts.net', 'https://' + HOST, HOST + ':443', '-pc.example.ts.net', HOST + '.evil']) {
      assert.equal(tailscale.dnsName({...STATUS, Self: {DNSName: name}}), null);
    }
  });
  check('tailnet Host needs loopback Serve headers; arbitrary hosts and Funnel fail', () => {
    const req = (headers, remoteAddress = '127.0.0.1') => ({headers, socket: {remoteAddress}});
    const headers = Object.fromEntries(Object.entries(PROXY).map(([k,v]) => [k.toLowerCase(),v]));
    assert(publisher.allowedHost(req(headers),8918,HOST));
    assert(publisher.allowedHost(req({...headers, 'x-forwarded-for': 'fd7a:115c:a1e0::123'}),8918,HOST));
    assert(publisher.allowedHost(req({...headers, host: HOST + ':443', 'x-forwarded-host': HOST + ':443'}),8918,HOST));
    assert(!publisher.allowedHost(req(headers, '192.168.1.1'),8918,HOST));
    assert(!publisher.allowedHost(req(headers),8918,null));
    for (const change of [{host: 'other.example.ts.net'}, {host: HOST + '.evil'}, {host: HOST + ':8918'},
      {'x-forwarded-host': 'evil'}, {'x-forwarded-proto': 'http'}, {'x-forwarded-for': '100.63.0.1'},
      {'x-forwarded-for': '100.128.0.1'}, {'x-forwarded-for': '8.8.8.8'}, {'x-forwarded-for': '100.64.0.1, 8.8.8.8'},
      {'tailscale-funnel-request': '?1'}]) {
      assert(!publisher.allowedHost(req({...headers, ...change}),8918,HOST), JSON.stringify(change));
    }
    assert(!publisher.allowedHost(req({host: HOST}),8918,HOST));
    for (const host of ['127.0.0.1:8918', 'localhost:8918']) assert(publisher.allowedHost(req({host}),8918,null));
    assert(!publisher.allowedHost(req({host: '127.0.0.1:8918', 'tailscale-funnel-request': '?1'}),8918,HOST));
  });
  check('phone setup preserves other Serve services and refuses public Funnel', () => {
    assert.equal(phone.configuration('{}',HOST), false);
    assert.equal(phone.configuration(JSON.stringify(configured()),HOST), true);
    assert.equal(phone.configuration(JSON.stringify({TCP:{8443:{HTTPS:true}},Web:{[HOST+':8443']:{Handlers:{'/':{Text:'other'}}}}}),HOST),false);
    for (const config of [{AllowFunnel:{[HOST+':443']:true}}, {TCP:{443:{TCPForward:'localhost:22'}}},
      {Web:{[HOST+':443']:{Handlers:{'/':{Proxy:'http://127.0.0.1:1234'}}}}},
      {Web:{['old.example.ts.net:443']:{Handlers:{'/':{Proxy:phone.TARGET}}}}}]) {
      assert.throws(() => phone.configuration(JSON.stringify(config),HOST));
    }
    assert.throws(() => phone.configuration('null',HOST));
    assert.throws(() => phone.configuration('{bad',HOST));
  });

  const calls = [];
  let active = false, starts = 0, probes = 0, running = false;
  const deps = {
    discover: () => ({executable:'fixture.exe',host:HOST}), delay: async () => {},
    command: (exe,args) => {
      assert.equal(exe,'fixture.exe'); calls.push(args);
      if (args[1] === 'status') return JSON.stringify(active ? configured() : {});
      assert.deepEqual(args, ['serve', ...phone.FLAGS, phone.TARGET, ...(args.at(-1)==='off'?['off']:[])]);
      active = args.at(-1) !== 'off';
    },
    probe: async headers => { probes++; if (!running) throw Object.assign(Error('Not running'),{code:'ECONNREFUSED'}); if (headers) assert.deepEqual(headers,{Host:HOST,'X-Forwarded-Host':HOST,'X-Forwarded-Proto':'https','X-Forwarded-For':'100.64.0.1'}); },
    startPublisher: async () => { starts++; running=true; return 'fixture log'; }
  };
  await phone.main('on',deps);
  await phone.main('on',deps);
  check('PHONE_ON starts once, reuses publisher and configures only background private Serve', () => {
    assert.equal(starts,1); assert(probes>=5); assert(active);
    assert(calls.every(args=>args[0]==='serve'));
  });
  await phone.main('off',deps);
  await phone.main('off',deps);
  check('PHONE_OFF disables only this Serve endpoint and leaves publisher running', () => {
    assert(!active); assert(running); assert.equal(starts,1); assert.equal(calls.filter(args=>args.at(-1)==='off').length,1);
  });
  await assert.rejects(phone.main('on',{...deps,discover:()=>({executable:null,host:null})}),/https:\/\/tailscale.com\/download/);
  await assert.rejects(phone.main('on',{...deps,discover:()=>({executable:'fixture.exe',host:null})}),/sign in/);
  await assert.rejects(phone.main('on',{...deps,probe:async()=>{throw Error('Occupied');}}),/Occupied/);
  await assert.rejects(phone.main('on',{...deps,probe:async headers=>{if(headers) throw Error('Old publisher');}}),/restart/);
  check('phone setup explains missing sign-in, occupied ports and an old publisher', () => assert.equal(starts,1));

  // Real HTTP listener with deterministic status discovery, never real Serve.
  const reserve = http.createServer();
  await new Promise(resolve=>reserve.listen(0,'127.0.0.1',resolve));
  const port = reserve.address().port;
  await new Promise(resolve=>reserve.close(resolve));
  const server = publisher.serve(publisher.options(['--root',root,'--out',path.join(base,'tailnet-served'),'--port',String(port)]),
    () => tailscale.discover(() => ({status:0,stdout:JSON.stringify(STATUS)}),'fixture.exe'));
  try {
    await new Promise((resolve,reject)=>{server.once('listening',resolve);server.once('error',reject);});
    const get = headers => new Promise((resolve,reject)=>{
      http.get({host:'127.0.0.1',port:server.address().port,path:'/',headers},res=>{res.resume();res.on('end',()=>resolve(res.statusCode));}).on('error',reject);
    });
    assert.equal(await get(PROXY),200);
    assert.equal(await get({...PROXY,Host:'other.example.ts.net'}),403);
    assert.equal(await get({Host:HOST}),403);
    assert.equal(await get({...PROXY,'Tailscale-Funnel-Request':'?1'}),403);
    assert.equal(await get({Host:`localhost:${server.address().port}`}),200);
    check('real publisher accepts discovered Serve Host, rejects others, keeps localhost and loopback bind',()=>assert.equal(server.address().address,'127.0.0.1'));
  } finally { await new Promise(resolve=>server.close(resolve)); }
}
module.exports = {test};
