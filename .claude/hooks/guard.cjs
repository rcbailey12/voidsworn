'use strict';

const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { createHash } = require('node:crypto');
const { spawnSync } = require('node:child_process');

const fileEdits = new Set(['Edit', 'Write', 'MultiEdit', 'NotebookEdit']);
const shells = new Set(['Bash', 'PowerShell', 'Monitor']);
const directWrites = /^(?:mcp__.*__)(?:push_files|create_or_update_file|create_file|update_file|delete_file|create_branch|create_ref|update_ref|delete_ref)$/;
const boardLogs = new Set(['contrib/opus/LOOP.md', 'contrib/opus/FINDINGS.md']);
const godotCode = /^godot\/(?:.*\.(?:gd|tscn)|project\.godot)$/;
const secretName = /^(?:\.env.*|\.?secrets?(?:\.(?:json|ya?ml|toml|txt))?|\.ssh|\.aws|\.netrc|\.npmrc|\.git-credentials|hosts\.yml|credentials\.json|id_(?:rsa|dsa|ecdsa|ed25519)(?!\.pub$).*|.*\.(?:pem|p12|pfx|key))$/i;

function block(message) {
  process.stderr.write(message + '\n');
  process.exitCode = 2;
}

function git(cwd, args) {
  const result = spawnSync('git', args, {
    cwd, encoding: 'utf8', timeout: 12000, windowsHide: true,
    env: { ...process.env, GIT_TERMINAL_PROMPT: '0', GIT_NO_REPLACE_OBJECTS: '1' }
  });
  if (result.status !== 0) throw new Error('Git could not verify ' + args[0] + '.');
  return result.stdout;
}

function realPath(target) {
  try {
    return fs.realpathSync.native(target);
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    // A dangling link is different from a new path and must not be followed on write.
    if (fs.lstatSync(target, { throwIfNoEntry: false })?.isSymbolicLink()) throw error;
    const parent = path.dirname(target);
    if (parent === target) throw error;
    return path.join(realPath(parent), path.basename(target));
  }
}

function secretPath(target) {
  return target.split(/[\\/]/).some(part => part.split(':').some(name => secretName.test(name.replace(/[. ]+$/, ''))));
}

function isBoard(event) {
  return !event.agent_id && Boolean(event.session_id) &&
    event.session_id === process.env.VOIDSWORN_BOARD_SESSION_ID;
}

function workerArea(root) {
  const seat = process.env.VOIDSWORN_CLAUDE_SEAT || '';
  return /^[a-z][a-z0-9-]*$/.test(seat) ? path.join(root, 'contrib', seat) : null;
}

function inside(root, target) {
  const relative = path.relative(root, target);
  return relative !== '..' && !relative.startsWith('..' + path.sep) && !path.isAbsolute(relative);
}

function projectCheckout(cwd) {
  const project = process.env.CLAUDE_PROJECT_DIR || cwd;
  const root = path.normalize(git(project, ['rev-parse', '--show-toplevel']).trim());
  if (path.relative(root, cwd) === '') return { root, inProject: true };
  let current;
  try {
    current = path.normalize(git(cwd, ['rev-parse', '--show-toplevel']).trim());
  } catch {
    return { root, inProject: false };
  }
  if (path.relative(root, current) === '') return { root, inProject: true };
  const commonDir = dir => git(dir, ['rev-parse', '--path-format=absolute', '--git-common-dir']).trim();
  return path.relative(commonDir(root), commonDir(current)) === ''
    ? { root: current, inProject: true }
    : { root, inProject: false };
}

function ownsFile(root, target) {
  const area = workerArea(root);
  return Boolean(area && target !== area && inside(area, target) && inside(area, realPath(target)));
}

function protectPath(event, root, input) {
  const target = input.file_path || input.notebook_path || input.path;
  if (target) {
    const resolved = path.resolve(event.cwd, target);
    if (secretPath(target) || secretPath(realPath(resolved))) {
      return 'Use the masked key installer for credentials. Claude cannot open protected files.';
    }
    if (fileEdits.has(event.tool_name) && !isBoard(event) && !ownsFile(root, resolved)) {
      return 'Worker edits stay under contrib/<seat>/. Set VOIDSWORN_CLAUDE_SEAT at launch.';
    }
  } else if (fileEdits.has(event.tool_name)) {
    return 'The edit hook needs a file path.';
  }
  const glob = input.glob || (event.tool_name === 'Glob' ? input.pattern : null);
  if (glob && secretPath(glob)) return 'Leave credential paths out of searches.';
}

function bareWords(command) {
  // Recognize a single command with literal arguments. The shell must see the same words.
  const token = /(?:[A-Za-z0-9_./:@+=,-]+|'[^'\\%\r\n]*'|"[^"\\\x60$%\r\n]*")(?=[ \t]|$)/y;
  const words = [];
  let index = 0;
  while (index < command.length) {
    if (/[ \t]/.test(command[index])) {
      index++;
      continue;
    }
    token.lastIndex = index;
    const match = token.exec(command);
    if (!match) return null;
    const word = match[0];
    words.push(/^['"]/.test(word) ? word.slice(1, -1) : word);
    index = token.lastIndex;
  }
  return words;
}

function gitPush(cwd, words, board) {
  // Use an explicit destination. Default, wildcard, delete and forced pushes cannot be verified here.
  const args = words.slice(2);
  if (args[0] === '-u' || args[0] === '--set-upstream') args.shift();
  const [remote, ...specs] = args;
  const branch = '(?:refs/heads/)?[A-Za-z0-9][A-Za-z0-9._/-]*';
  const refspec = new RegExp('^(' + branch + ')(?::(' + branch + '))?$');
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(remote || '') || specs.length !== 1 || !refspec.test(specs[0])) {
    return 'Use one explicit refspec with git push origin <branch> or git push origin HEAD:refs/heads/<branch>.';
  }
  const [, source, destination] = refspec.exec(specs[0]);
  const target = (destination || source).replace(/^refs\/heads\//, '');
  if (!destination && target === 'HEAD') return 'Give the push its destination branch explicitly.';
  if (target.toLowerCase() !== 'main') return;
  if (!board) return 'Only the Board can push the two Board logs to main. Push your issue branch.';
  const pushUrl = git(cwd, ['remote', 'get-url', '--push', '--all', remote]).trim();
  if (!pushUrl || /\r?\n/.test(pushUrl)) return 'Use a remote with exactly one push URL.';
  const liveRef = git(cwd, ['ls-remote', '--exit-code', '--', pushUrl, 'refs/heads/main']).trim();
  const base = /^([a-f0-9]{40,64})\trefs\/heads\/main$/.exec(liveRef)?.[1];
  if (!base) return 'Could not verify the remote main. Fetch the remote and retry.';
  const sourceRef = source === 'HEAD' || source.startsWith('refs/heads/') ? source : 'refs/heads/' + source;
  const tip = git(cwd, ['rev-parse', '--verify', sourceRef + '^{commit}']).trim();
  git(cwd, ['merge-base', '--is-ancestor', base, tip]);
  for (const commit of git(cwd, ['rev-list', base + '..' + tip]).trim().split('\n').filter(Boolean)) {
    const parents = git(cwd, ['rev-list', '--parents', '-n', '1', commit]).trim().split(' ');
    const changed = git(cwd, ['diff-tree', '--no-commit-id', '--no-renames', '--name-only', '-r', '-z', commit])
      .split('\0').filter(Boolean);
    if (parents.length !== 2 || !changed.length || changed.some(file => !boardLogs.has(file))) {
      return 'Each commit pushed to main must change only contrib/opus/LOOP.md or contrib/opus/FINDINGS.md.';
    }
  }
}

function workerGit(root, cwd, words) {
  const [, command, ...args] = words;
  if (command === 'status' && args.every(arg => ['--short', '-sb', '--branch', '--porcelain'].includes(arg))) return;
  if (command === 'branch' && args.join(' ') === '--show-current') return;
  if (command === 'diff' && args.every(arg => ['--stat', '--name-only', '--check', '--cached', 'HEAD'].includes(arg))) return;
  if (command === 'switch' && args.length === 2 && args[0] === '-c' &&
      /^(?:opus|work|muse|codex|neon)\/issue-\d+(?:-[a-z0-9-]+)?$/.test(args[1])) return;
  if (command === 'add' && args.length > 1 && args[0] === '--' &&
      args.slice(1).every(file => !file.startsWith(':') && ownsFile(root, path.resolve(cwd, file)))) return;
  if (command === 'commit' && args.length === 2 && args[0] === '-m' &&
      git(cwd, ['diff', '--cached', '--no-renames', '--name-only', '-z'])
        .split('\0').filter(Boolean).every(file => ownsFile(root, path.join(root, file)))) return;
  return 'Worker shell writes are limited to staging and committing your own files. Use Claude file tools for edits.';
}

function shellPolicy(event, root, input) {
  const command = input.command;
  if (typeof command !== 'string') return 'The shell hook needs a command.';
  // Check literal credential names even in compound commands and PowerShell arguments.
  if (command.split(/[\s"'=|&;<>()[\]{},]+/).some(secretPath) ||
      /(?:^|[\s;|&])(?:printenv\b|env\s*(?:$|[;|&])|gh\s+auth\s+token\b|git\s+credential\b|(?:Get-ChildItem|gci|dir|ls)\s+Env:|Get-Item\s+Env:)|(?:\$env:|\$\{?)[\w]*(?:TOKEN|PASSWORD|SECRET|API_KEY)\b/i.test(command)) {
    return 'Use the masked key installer for credentials. Claude cannot read protected files or print credentials.';
  }
  const words = bareWords(command.trim());
  const board = isBoard(event);
  if (/\b(?:git(?:\.exe)?\b[\s\S]*\bpush\b|git[- ]send-pack\b)/i.test(command)) {
    if (!words || !/^git(?:\.exe)?$/i.test(words[0]) || words[1] !== 'push') {
      return 'Run git push as a single plain command so the hook can check its destination.';
    }
    return gitPush(event.cwd, words, board);
  }
  if (/\bgh(?:\.exe)?\s+api\b/i.test(command) &&
      /(?:\/(?:git\/(?:refs|matching-refs)|contents)(?:\/|\b))/i.test(command) &&
      /(?:--method|-X)(?:\s+|=)(?:POST|PATCH|PUT|DELETE)\b|(?:--input|--(?:raw-)?field|-[fF])(?:[\s=]|[A-Z])/i.test(command)) {
    return 'Use the checked git push command for direct file and branch updates.';
  }
  if (board || (words?.length === 1 && words[0] === 'pwd')) return;
  if (words && /^git(?:\.exe)?$/i.test(words[0])) return workerGit(root, event.cwd, words);
  return 'Workers use Claude file tools to read and edit. Run other shell work through the Board.';
}

function preTool(event) {
  const input = event.tool_input || {};
  if (directWrites.test(event.tool_name)) return 'Use the checked git push command for direct file and branch updates.';
  if (isBoard(event)) {
    return shells.has(event.tool_name) ? shellPolicy(event, null, input) : protectPath(event, null, input);
  }
  const { root, inProject } = projectCheckout(event.cwd);
  if (!shells.has(event.tool_name)) return protectPath(event, root, input);
  if (!inProject) return 'Worker shell commands need the project checkout.';
  return shellPolicy(event, root, input);
}

function emDash(event) {
  const input = event.tool_input || {};
  const text = [input.content, input.new_string, input.new_source,
    ...(Array.isArray(input.edits) ? input.edits.map(edit => edit.new_string) : [])];
  if (text.some(value => typeof value === 'string' && value.includes('\u2014'))) {
    process.stdout.write(JSON.stringify({ hookSpecificOutput: {
      hookEventName: 'PostToolUse',
      additionalContext: 'This edit added an em dash. Replace it with plain punctuation before continuing.'
    } }) + '\n');
  }
}

function stateFile(root, sessionId) {
  const id = createHash('sha256').update(JSON.stringify([root, sessionId])).digest('hex');
  return path.join(os.tmpdir(), 'voidsworn-claude-' + id + '.head');
}

function godotCommand() {
  if (process.env.GODOT_EXE || process.env.GODOT) return process.env.GODOT_EXE || process.env.GODOT;
  const installed = path.join(os.homedir(), 'Downloads', 'voidsworn_test', 'godot', 'Godot_v4.7.2-stable_win64_console.exe');
  return process.platform === 'win32' && fs.existsSync(installed) ? installed : 'godot';
}

function godotTurn(event) {
  const { root } = projectCheckout(event.cwd);
  const state = stateFile(process.env.CLAUDE_PROJECT_DIR || root, event.session_id);
  if (event.hook_event_name === 'UserPromptSubmit') {
    fs.writeFileSync(state, git(root, ['rev-parse', 'HEAD']).trim(), { mode: 0o600 });
    return;
  }
  if (event.hook_event_name === 'SessionEnd') {
    fs.rmSync(state, { force: true });
    return;
  }
  const start = fs.existsSync(state) ? fs.readFileSync(state, 'utf8').trim() : 'HEAD';
  if (!/^(?:[a-f0-9]{40,64}|HEAD)$/.test(start)) throw new Error('Invalid Godot check baseline.');
  const changed = [
    git(root, ['diff', '--name-only', '--no-renames', '-z', start, '--', 'godot']),
    git(root, ['ls-files', '--others', '--exclude-standard', '-z', '--', 'godot'])
  ].join('').split('\0');
  if (!changed.some(file => godotCode.test(file))) return;
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'voidsworn-godot-parse-'));
  let check;
  try {
    check = spawnSync(godotCommand(), [
      '--headless', '--path', path.join(root, 'godot'), '--script', 'res://tools/ci/load_all.gd'
    ], {
      cwd: root, encoding: 'utf8', timeout: 90000, maxBuffer: 4 * 1024 * 1024, windowsHide: true,
      env: { ...process.env, APPDATA: profile, LOCALAPPDATA: profile, XDG_DATA_HOME: profile }
    });
  } finally {
    fs.rmSync(profile, { force: true, recursive: true });
  }
  if (check.error) return 'Godot parse check could not run. Set GODOT_EXE or put Godot on PATH. ' + check.error.code;
  const output = check.stdout + '\n' + check.stderr;
  if (check.status !== 0 || /SCRIPT ERROR|Parse Error|load all: FAILED/.test(output) ||
      !/^load all: \d+ scripts, \d+ scenes, 0 failed\r?$/m.test(output)) {
    return 'Godot parse check failed. Fix the errors before ending the turn.\n' + output.trim().slice(0, 4500);
  }
  process.stdout.write('Godot parse check passed.\n');
}

try {
  const event = JSON.parse(fs.readFileSync(0, 'utf8').replace(/^\uFEFF/, ''));
  const hook = process.argv[2];
  const reason = { pre: preTool, 'em-dash': emDash, godot: godotTurn }[hook](event);
  if (reason) block(reason);
} catch (error) {
  block('Voidsworn hook could not verify this action. ' + error.message);
}
