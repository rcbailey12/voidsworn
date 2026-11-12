'use strict';
// Free dry run for the workhorse runner (#217): a stand-in model server so OpenCode's whole headless path can be tested on
// the PC without spending money. It answers like an OpenAI-compatible API and walks a fixed script of tool calls:
// look at the folder, write a file, run the standing checks, run Godot parity, try a push (must be refused), then report.
// Usage: node mock_llm.js <port> <log file> [scenario]. It quits 15 seconds after its final report, or 20 minutes after it starts.
// Scenarios for the runner 2 dry runs (issue 377; the default is the original script above):
//   refuse   copies ship and gen files in and force-adds them, adds a new .uid, re-saves a tracked .import, writes a 9 MB file,
//            edits one Deliver to file of issue 377 and one file outside it (the runner must refuse five and warn on one)
//   timecap  writes half the work, then sleeps until the runner's time cap kills it (a PARTIAL run)
//   merge    merges another branch in with a merge commit (as the issue 541 run did), then edits three files
const http = require('http');
const fs = require('fs');
const port = Number(process.argv[2] || 8765);
const log = process.argv[3] || 'mock_log.txt';
const scenario = process.argv[4] || 'default';
const say = s => fs.appendFileSync(log, new Date().toISOString() + ' ' + s + '\n');
const SCENARIOS = {
  refuse: [
    { cmd: 'mkdir -p godot/assets/ships/B16_23 godot/gen && printf glb > godot/assets/ships/B16_23/B16_23_hull.glb && printf gen > godot/gen/hull_probe.tres && git add -f godot/assets/ships/B16_23/B16_23_hull.glb godot/gen/hull_probe.tres', d: 'copy ship and gen files in and force-add them' },
    { cmd: 'printf "extends Node\\n" > tools/pc/probe377.gd && printf "uid://probe377\\n" > tools/pc/probe377.gd.uid && git add -f tools/pc/probe377.gd.uid', d: 'a new .uid file, force-added' },
    { cmd: 'printf "\\n" >> godot/fx/atlases/weapons/muzzle/muzzle_flow.png.import', d: 're-save a tracked .import file' },
    { cmd: 'head -c 9437184 /dev/zero > contrib/opus/tools/big377.bin && ls -l contrib/opus/tools/big377.bin', d: 'a 9 MB file' },
    { cmd: 'printf "# dry run 377: an edit inside Deliver to\\n" >> tools/pc/work_issue.ps1 && printf "scope probe\\n" > contrib/opus/tools/scope377_probe.txt', d: 'one edit inside Deliver to, one outside' },
    { cmd: 'git status --short', d: 'look' },
  ],
  timecap: [
    { cmd: 'printf "half done\\n" > tools/pc/partial377.txt', d: 'write half the work' },
    { cmd: 'sleep 900', d: 'run past the time cap' },
  ],
  merge: [
    { cmd: 'git fetch -q --deepen=30 origin && git fetch -q --depth=30 origin runner377/side && git merge --no-ff --no-edit FETCH_HEAD && git log --oneline -3', d: 'merge another branch in (a merge commit, as on issue 541)' },
    { cmd: 'printf "# merge case edit 1\\n" >> tools/pc/work_issue.ps1 && printf "rem merge case edit 2\\r\\n" >> tools/pc/codex_issue.bat && printf "merge case note\\n" > tools/pc/work/merge377_note.txt && git status --short', d: 'three edits after the merge' },
  ],
};
const SCRIPT = SCENARIOS[scenario] || [
  { cmd: 'pwd && git status --short --branch && node --version', d: 'look around' },
  { cmd: 'echo dry run probe > dryrun_probe.txt && ls dryrun_probe.txt', d: 'write a file' },
  { cmd: 'node contrib/opus/tools/run_all_checks.js --fast 2>&1 | tail -n 8', d: 'standing checks' },
  { cmd: 'cmd.exe //c "tools\\pc\\parity.bat nopause" 2>&1 | grep -E "PASS|FAIL" | tail -n 12', d: 'rules and campaign parity' },
  { cmd: 'git push origin HEAD', d: 'push (the config must refuse this)' },
  { cmd: 'cd . && git -c core.quotepath=off push origin HEAD', d: 'chained push (the config must refuse this too)' },
  { cmd: 'rm -rf ../dryrun_delete_probe', d: 'delete outside the repo (the config must refuse this)' },
];
say('scenario ' + scenario);
// timecap: the agent is killed mid-sleep and never asks again, so quit early to free the port for the next dry run.
const life = scenario === 'timecap' ? 4 * 60 * 1000 : 20 * 60 * 1000;
setTimeout(() => { say('quit after ' + life / 60000 + ' minutes'); process.exit(0); }, life);
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
      delta = { role: 'assistant', tool_calls: [{ index: 0, id: 'call_' + step, type: 'function', function: { name: 'bash', arguments: JSON.stringify({ command: s.cmd, description: s.d }) } }] };
      fin = 'tool_calls';
    } else {
      delta = { role: 'assistant', content: scenario === 'default' ? 'Dry run report: the stand-in model ran the fixed script (look around, write a file, standing checks, parity, a refused push, a refused chained push, a refused delete). No game files were changed.' : 'Dry run report (issue 377, scenario ' + scenario + '): the stand-in model ran its fixed script. ' + SCRIPT.map(x => x.d).join('; ') + '.' };
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
// An earlier stand-in may still hold the port after its run: retry for up to five minutes until it is free.
let tries = 0;
server.on('error', e => {
  if (e.code === 'EADDRINUSE' && tries++ < 300) { say('port busy, retrying'); setTimeout(() => server.listen(port, '127.0.0.1'), 1000); }
  else { say('cannot listen: ' + e.message); process.exit(1); }
});
server.on('listening', () => say('mock model listening on ' + port));
server.listen(port, '127.0.0.1');
