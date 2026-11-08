'use strict';
// Free dry run for the workhorse runner (#217): a stand-in model server so OpenCode's whole headless path can be tested on
// the PC without spending money. It answers like an OpenAI-compatible API and walks a fixed script of tool calls:
// look at the folder, write a file, run the standing checks, run Godot parity, try a push (must be refused), then report.
// Usage: node mock_llm.js <port> <log file>. It quits 15 seconds after its final report, or 20 minutes after it starts.
const http = require('http');
const fs = require('fs');
const port = Number(process.argv[2] || 8765);
const log = process.argv[3] || 'mock_log.txt';
const say = s => fs.appendFileSync(log, new Date().toISOString() + ' ' + s + '\n');
const SCRIPT = [
  { cmd: 'pwd && git status --short --branch && node --version', d: 'look around' },
  { cmd: 'echo dry run probe > dryrun_probe.txt && ls dryrun_probe.txt', d: 'write a file' },
  { cmd: 'node contrib/opus/tools/run_all_checks.js --fast 2>&1 | tail -n 8', d: 'standing checks' },
  { cmd: 'cmd.exe //c "tools\\pc\\parity.bat nopause" 2>&1 | grep -E "PASS|FAIL" | tail -n 12', d: 'rules and campaign parity' },
  { cmd: 'git push origin HEAD', d: 'push (the config must refuse this)' },
];
setTimeout(() => { say('quit after 20 minutes'); process.exit(0); }, 20 * 60 * 1000);
const server = http.createServer((req, res) => {
  let b = '';
  req.on('data', c => b += c);
  req.on('end', () => {
    let j = {};
    try { j = b ? JSON.parse(b) : {}; } catch (e) { }
    const msgs = j.messages || [];
    const toolMsgs = msgs.filter(m => m.role === 'tool');
    if (toolMsgs.length) say('tool result: ' + JSON.stringify(toolMsgs[toolMsgs.length - 1].content).slice(0, 1500));
    say(req.method + ' ' + req.url + ' model=' + j.model + ' tools=' + (j.tools || []).length + ' messages=' + msgs.length);
    if (!req.url.includes('chat/completions')) { res.writeHead(200, { 'Content-Type': 'application/json' }); return res.end('{"object":"list","data":[]}'); }
    let delta, fin;
    const step = toolMsgs.length;
    if (!(j.tools || []).length) { delta = { role: 'assistant', content: 'Dry run' }; fin = 'stop'; }
    else if (step < SCRIPT.length) {
      const s = SCRIPT[step];
      delta = { role: 'assistant', tool_calls: [{ index: 0, id: 'call_' + step, type: 'function', function: { name: 'bash', arguments: JSON.stringify({ command: s.cmd, description: s.d, timeout: 900000 }) } }] };
      fin = 'tool_calls';
    } else {
      delta = { role: 'assistant', content: 'Dry run report: the stand-in model ran the fixed script (look around, write a file, standing checks, parity, a refused push). No game files were changed.' };
      fin = 'stop';
      setTimeout(() => { say('script finished, quitting'); process.exit(0); }, 15000);
    }
    const usage = { prompt_tokens: 1000, completion_tokens: 100, total_tokens: 1100 };
    const chunk = (d, f, u) => 'data: ' + JSON.stringify(Object.assign({ id: 'mock', object: 'chat.completion.chunk', created: 1, model: j.model, choices: [{ index: 0, delta: d, finish_reason: f }] }, u ? { usage: u } : {})) + '\n\n';
    if (j.stream) {
      res.writeHead(200, { 'Content-Type': 'text/event-stream' });
      res.write(chunk(delta, null));
      res.write(chunk({}, fin, usage));
      res.end('data: [DONE]\n\n');
    } else {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ id: 'mock', object: 'chat.completion', created: 1, model: j.model, choices: [{ index: 0, message: delta, finish_reason: fin }], usage }));
    }
  });
});
// An earlier stand-in may still hold the port for a few seconds after its run: retry until it is free.
let tries = 0;
server.on('error', e => {
  if (e.code === 'EADDRINUSE' && tries++ < 60) { say('port busy, retrying'); setTimeout(() => server.listen(port, '127.0.0.1'), 1000); }
  else { say('cannot listen: ' + e.message); process.exit(1); }
});
server.on('listening', () => say('mock model listening on ' + port));
server.listen(port, '127.0.0.1');
