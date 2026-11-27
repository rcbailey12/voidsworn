'use strict';
// Issue 1093: exercise the Windows watchdog and OpenCode against a local Responses API.
// Run with node tools/pc/runner_openai_resume_selftest.js on a PC with OpenCode installed.
const assert = require('node:assert/strict');
const { execFileSync, spawn } = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const os = require('node:os');
const path = require('node:path');

if (process.platform !== 'win32') {
  console.log('SKIP runner_openai_resume_selftest: needs the Windows watchdog and OpenCode');
  process.exit(0);
}

const exe = process.argv[2] || path.join(process.env.APPDATA, 'npm', 'opencode.cmd');
const helper = path.join(__dirname, 'work_issue.ps1');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'runner1093 proof '));
const read = file => fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, '');
const key = 'mock-private-key';
const header = 'mock-private-header';
const org = 'org-mock-private';
const initial = 'Read WORK_TASK.md';
const continuation = 'Continue the task from where you stopped';
const resumeWaitSeconds = 16.492;

function run(args, env, cwd) {
  return new Promise((resolve, reject) => {
    const child = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', helper, ...args], {
      cwd, env: { ...process.env, ...env }, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'], timeout: 180000
    });
    let output = '';
    child.stdout.on('data', chunk => output += chunk);
    child.stderr.on('data', chunk => output += chunk);
    child.once('error', reject);
    child.once('close', code => resolve({ code, output }));
  });
}

function complete(res, model, tool) {
  const content = { type: 'output_text', text: 'Mock work finished.', annotations: [] };
  const item = tool ? { type: 'function_call', id: 'fc_proof', call_id: 'call_proof', name: 'bash',
    arguments: JSON.stringify({ command: 'printf done > mock_progress.txt', description: 'Save mock progress' }), status: 'completed' } :
    { type: 'message', id: 'msg_proof', role: 'assistant', status: 'completed', content: [content] };
  const response = { id: tool ? 'resp_first' : 'resp_done', object: 'response', created_at: 1, model, status: 'completed', output: [item],
    usage: { input_tokens: 1000, output_tokens: 100, total_tokens: 1100,
      input_tokens_details: { cached_tokens: 100 }, output_tokens_details: { reasoning_tokens: 10 } } };
  res.writeHead(200, { 'Content-Type': 'text/event-stream' });
  let sequence = 0;
  const send = (type, fields) => res.write('event: ' + type + '\ndata: ' + JSON.stringify({ type, sequence_number: sequence++, ...fields }) + '\n\n');
  send('response.created', { response: { ...response, status: 'in_progress', output: [], usage: null } });
  send('response.output_item.added', { output_index: 0, item: { ...item, status: 'in_progress', ...(tool ? { arguments: '' } : { content: [] }) } });
  if (tool) {
    send('response.function_call_arguments.delta', { item_id: item.id, output_index: 0, delta: item.arguments });
    send('response.function_call_arguments.done', { item_id: item.id, output_index: 0, arguments: item.arguments });
  } else {
    send('response.content_part.added', { item_id: item.id, output_index: 0, content_index: 0, part: { ...content, text: '' } });
    send('response.output_text.delta', { item_id: item.id, output_index: 0, content_index: 0, delta: content.text });
    send('response.output_text.done', { item_id: item.id, output_index: 0, content_index: 0, text: content.text });
    send('response.content_part.done', { item_id: item.id, output_index: 0, content_index: 0, part: content });
  }
  send('response.output_item.done', { output_index: 0, item });
  send('response.completed', { response });
  res.end();
}

async function scenario(name, cap, expectedCode, expectedResumes) {
  const home = path.join(root, name);
  const repo = path.join(home, 'job repo');
  const out = path.join(home, 'job out');
  fs.mkdirSync(repo, { recursive: true });
  fs.mkdirSync(out);
  const git = (args, input) => execFileSync('git.exe', args, { cwd: repo, input, encoding: 'utf8', windowsHide: true }).trim();
  git(['init', '-q']);
  const tree = git(['hash-object', '-t', 'tree', '-w', '--stdin'], '');
  const identity = 'Runner fixture <fixture@example.invalid> 1700000000 +0000';
  const head = git(['hash-object', '-t', 'commit', '-w', '--stdin'], `tree ${tree}\nauthor ${identity}\ncommitter ${identity}\n\nFixture\n`);
  git(['update-ref', 'HEAD', head]);
  const attempts = new Set();
  let lastLimitTime;
  let actualWait;
  const server = http.createServer(async (req, res) => {
    let body = '';
    for await (const chunk of req) body += chunk;
    if (req.url !== '/v1/responses') { res.writeHead(404).end(); return; }
    const { input, model, reasoning, tools } = JSON.parse(body);
    const messages = input.filter(item => item.role === 'user').map(item => JSON.stringify(item.content));
    const resumed = messages.filter(message => message.includes(continuation)).length;
    if (!tools?.some(tool => tool.name === 'bash') || !messages.some(message => message.includes(initial))) {
      complete(res, model, false); // Auxiliary title requests do not belong to the agent session.
      return;
    }
    attempts.add(resumed);
    assert.equal(model, 'gpt-6.2-sol');
    assert.equal(reasoning.effort, 'high');
    if (name === 'resume' && !resumed && !input.some(item => item.type === 'function_call_output')) {
      complete(res, model, true);
      return;
    }
    if (name === 'resume' && resumed) {
      actualWait = performance.now() - lastLimitTime;
      complete(res, model, false);
      return;
    }
    const status = name === 'non-429' || (name === 'later failure' && resumed) ? 400 : 429;
    const wait = name === 'budget' ? 300.492 : name === 'resume' ? resumeWaitSeconds : 0.492;
    const message = `Mock provider error for ${org}, ${key}, ${initial}. Please try again in ${wait}s.`;
    res.writeHead(status, { 'Content-Type': 'application/json', 'retry-after-ms': '1', 'x-mock-secret': header });
    res.end(JSON.stringify({ error: { message, type: status === 429 ? 'tokens' : 'invalid_request_error' } }));
    if (status === 429) lastLimitTime = performance.now();
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    const config = JSON.parse(read(path.join(__dirname, 'work', 'opencode_mock.json')));
    config.provider = { openai: config.provider.openai };
    config.provider.openai.options = { baseURL: `http://127.0.0.1:${server.address().port}/v1`, apiKey: key };
    const configPath = path.join(home, 'opencode.json');
    fs.writeFileSync(configPath, JSON.stringify(config));
    const env = {
      XDG_CONFIG_HOME: home, XDG_DATA_HOME: home, XDG_CACHE_HOME: home, XDG_STATE_HOME: home,
      OPENCODE_CONFIG: configPath, OPENCODE_DISABLE_AUTOUPDATE: '1', OPENCODE_DISABLE_MODELS_FETCH: '1',
      OPENCODE_DISABLE_DEFAULT_PLUGINS: '1', OPENCODE_CONFIG_CONTENT: '', SHELL: 'C:\\Program Files\\Git\\bin\\bash.exe',
      VOIDSWORN_OPENAI_API_KEY: key, PC_RUNNER_TEST: '1', PC_TEST_OPENAI_NO_WAIT: name === 'resume' ? '' : '1',
      PC_TEST_TIMEOUT_LOG: path.join(home, 'timeouts.log'), TMO_REPO: repo, TMO_OUT: out,
      TMO_LOG: path.join(out, 'log.txt'), TMO_ERR_LOG: path.join(out, 'stderr.txt'),
      STALL_MIN: name === 'resume' ? '0.25' : '1', PC_TEST_SCAN_S: '0.1'
    };
    fs.writeFileSync(path.join(out, 'result.txt'), '');
    const result = await run(['openai-agent', out, repo, exe, 'openai/gpt-6.2-sol', '--variant high', String(cap)], env, repo);
    const log = read(env.TMO_LOG);
    const report = read(path.join(out, 'result.txt'));
    assert.equal(result.code, expectedCode, result.output + report + log);
    assert.deepEqual([...attempts].sort((a, b) => a - b), Array.from({ length: expectedResumes + 1 }, (_, i) => i));
    assert.deepEqual(report.match(/rate limited, resumed \d+ of 6/g) || [],
      Array.from({ length: expectedResumes }, (_, i) => `rate limited, resumed ${i + 1} of 6`));
    const events = log.trim().split(/\r?\n/).map(JSON.parse);
    assert.equal(new Set(events.map(event => event.sessionID)).size, 1);
    for (const marker of [key, header, org, initial, continuation]) {
      assert(!(log + report + result.output + read(env.TMO_ERR_LOG)).includes(marker), 'private fixture data reached runner output');
    }
    if (name === 'budget') assert(report.includes('too little time left to resume'));
    if (name === 'resume') {
      assert(actualWait >= resumeWaitSeconds * 1000, 'the provider wait must finish even when it exceeds the stall window');
      assert.equal(read(path.join(repo, 'mock_progress.txt')), 'done');
      const steps = events.filter(event => event.type === 'step_finish');
      assert.equal(steps.length, 2);
      assert.equal(new Set(steps.map(event => event.part.id)).size, 2);
      fs.copyFileSync(env.TMO_LOG, path.join(out, 'events.jsonl'));
      const args = ['openai-spend', '1093', out, home, path.join(home, 'settings.txt'), 'openai/gpt-6.2-sol', '0'];
      for (let i = 0; i < 2; i++) assert.equal((await run(args, env, repo)).code, 0);
      const rows = read(path.join(home, 'openai_spend.txt')).trim().split(/\r?\n/).map(JSON.parse);
      assert.equal(rows.length, 1);
      assert.equal(rows[0].input, 1800);
      assert.equal(rows[0].cached_input, 200);
      assert.equal(rows[0].output, 200);
    }
    console.log(`PASS ${name} (${expectedResumes} resumes)`);
  } finally { server.close(); }
}

(async () => {
  assert(fs.existsSync(exe), 'Install OpenCode or pass the path to opencode.cmd');
  console.log('Evidence: ' + root);
  await scenario('resume', 90, 0, 1);
  await scenario('cap', 360, 1, 6);
  await scenario('non-429', 90, 1, 0);
  await scenario('later failure', 90, 1, 1);
  await scenario('budget', 60, 1, 0);
})().catch(error => { console.error(error); process.exitCode = 1; });
