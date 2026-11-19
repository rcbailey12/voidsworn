'use strict';
// The copied batch files use this client. The parent balances calls over warm
// Windows PowerShell processes, each handling one request at a time.
const net = require('net');
const path = require('path');
const readline = require('readline');
const { randomUUID } = require('crypto');
const { spawn } = require('child_process');

function request(options, env, cwd) {
  return { ...options, env, cwd };
}

if (require.main === module) {
  const [flag, target, ...args] = process.argv.slice(2);
  const invocation = flag === '-File' ? { file: target, args } : { command: target, args };
  const socket = net.createConnection(process.env.RUNNER_FIXTURE_PIPE);
  let output = '';
  socket.setEncoding('utf8');
  socket.on('connect', () => socket.write(JSON.stringify(request(invocation, process.env, process.cwd())) + '\n'));
  socket.on('data', chunk => output += chunk);
  socket.on('end', () => {
    try {
      const { code, stdout, stderr, error } = JSON.parse(output);
      if (error) throw new Error(error);
      for (const line of stdout) console.log(line);
      for (const line of stderr) console.error(line);
      process.exitCode = code;
    } catch (e) {
      console.error('Runner fixture shell: ' + e.message);
      process.exitCode = 125;
    }
  });
}

module.exports = async function startShell(root, size, scriptDirs) {
  const pipe = '\\\\.\\pipe\\voidsworn-runner-selftest-' + randomUUID();
  const allowedFiles = new Set(scriptDirs.flatMap(dir => ['runner_common.ps1', 'codex_issue.ps1', 'work_issue.ps1', 'review_evidence.ps1']
    .map(name => path.join(dir, name).toLowerCase())));
  const allowedCommands = new Set(["(Get-Date).ToString('s')", 'Get-Date -Format yyyyMMdd_HHmmss']);
  const queue = [];
  const hosts = [];
  const clients = new Set();
  let stopped = false;
  let fault;

  function drain() {
    for (const host of hosts) {
      if (stopped || !queue.length) break;
      if (host.pending || host.dead) continue;
      host.pending = queue.shift();
      host.timer = setTimeout(() => {
        host.fail(new Error('PowerShell fixture step timed out: ' + host.pending.input));
        host.child.kill();
      }, 90000);
      host.child.stdin.write(host.pending.payload + '\n');
    }
  }

  // Keep the original launcher paths in child environments so the real helpers
  // still launch their own subprocesses, including the preflight kill test.
  for (let i = 0; i < size; i++) {
    const child = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(__dirname, 'runner_selftest_shell.ps1')], {
      cwd: root, windowsHide: true
    });
    const host = { child };
    let errors = '';
    const closed = new Promise(resolve => child.once('close', resolve));
    host.closed = closed;
    host.fail = error => {
      if (!stopped) fault ??= error;
      host.dead = true;
      clearTimeout(host.timer);
      if (host.pending) host.pending.reject(error);
      host.pending = null;
      if (hosts.every(h => h.dead)) {
        for (const item of queue.splice(0)) item.reject(error);
      } else drain();
    };
    hosts.push(host);
    child.stderr.setEncoding('utf8');
    child.stderr.on('data', chunk => errors += chunk);
    child.on('error', host.fail);
    child.stdin.on('error', host.fail);
    child.once('close', code => host.fail(new Error('PowerShell fixture host exited (' + code + '): ' + errors)));
    readline.createInterface({ input: child.stdout }).on('line', line => {
      if (!host.pending) return;
      const { resolve } = host.pending;
      try {
        const result = JSON.parse(line);
        if (!Number.isInteger(result.code)) throw new Error('Missing PowerShell exit code');
        clearTimeout(host.timer);
        host.pending = null;
        resolve(result);
        drain();
      } catch (e) {
        host.fail(new Error('Invalid PowerShell fixture reply: ' + e.message + '\n' + line));
        child.kill();
      }
    });
  }

  function invoke(input) {
    return new Promise((resolve, reject) => {
      if (stopped || hosts.every(h => h.dead)) return reject(new Error('No PowerShell fixture hosts are available'));
      queue.push({ input: input.file ? path.basename(input.file) + ':' + input.args[0] : '-Command', payload: JSON.stringify(input), resolve, reject });
      drain();
    });
  }

  const server = net.createServer(socket => {
    clients.add(socket);
    socket.on('close', () => clients.delete(socket));
    socket.on('error', () => socket.destroy());
    const input = readline.createInterface({ input: socket });
    input.once('line', async raw => {
      input.close();
      try {
        const call = JSON.parse(raw);
        if (call.file ? !allowedFiles.has(call.file.toLowerCase()) : !allowedCommands.has(call.command)) {
          throw new Error('Unexpected PowerShell fixture command');
        }
        socket.end(JSON.stringify(await invoke(call)));
      }
      catch (e) {
        fault ??= e;
        socket.end(JSON.stringify({ error: e.message }));
      }
    });
  });
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(pipe, resolve);
  });
  return {
    env: { RUNNER_FIXTURE_PIPE: pipe, RUNNER_FIXTURE_PS: __filename },
    assertHealthy() { if (fault) throw fault; },
    async run(file, args, env, cwd) {
      const result = await invoke(request({ file, args }, { ...process.env, ...env }, cwd));
      return { code: result.code, text: [...result.stdout, ...result.stderr].join('\n') };
    },
    async close() {
      stopped = true;
      for (const socket of clients) socket.destroy();
      for (const host of hosts) host.child.stdin.end();
      await Promise.all([new Promise(resolve => server.close(resolve)), ...hosts.map(h => h.closed)]);
    }
  };
};
