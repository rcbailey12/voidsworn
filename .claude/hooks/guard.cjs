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
// F9 rollout switch. Turn on only after F6 and the LOOP.md roll have landed.
const BOARD_LOG_TIP_LINTS_ENABLED = false;
const godotCode = /^godot\/(?:.*\.(?:gd|tscn)|project\.godot)$/;
const secretName = /^(?:\.env.*|\.?secrets?(?:\.(?:json|ya?ml|toml|txt))?|\.ssh|\.aws|\.netrc|\.npmrc|\.git-credentials|hosts\.yml|credentials\.json|id_(?:rsa|dsa|ecdsa|ed25519)(?!\.pub$).*|.*\.(?:pem|p12|pfx|key))$/i;

function block(message) {
  process.stderr.write(message + '\n');
  process.exitCode = 2;
}

function git(cwd, args, allowed = [0]) {
  const result = spawnSync('git', args, {
    cwd, encoding: 'utf8', timeout: 12000, windowsHide: true,
    env: { ...process.env, GIT_TERMINAL_PROMPT: '0', GIT_NO_REPLACE_OBJECTS: '1' }
  });
  if (!allowed.includes(result.status)) throw new Error('Git could not verify ' + args[0] + '.');
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

// Main seats (the Board and every Opus project thread) get the credential guard and the main-branch guard only.
// The contrib/<seat>/ fence applies only when a launch names a non-main seat (AGENTS.md "If you are not the main agent").
const mainSeats = new Set(['', 'opus', 'board', 'main', 'claude']);

function seat() {
  return (process.env.VOIDSWORN_CLAUDE_SEAT || '').trim().toLowerCase();
}

function fenced() {
  return !mainSeats.has(seat());
}

function workerArea(root) {
  const name = seat();
  return /^[a-z][a-z0-9-]*$/.test(name) ? path.join(root, 'contrib', name) : null;
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
    const resolved = path.resolve(event.cwd || '.', target);
    if (secretPath(target) || secretPath(realPath(resolved))) {
      return 'Use the masked key installer for credentials. Claude cannot open protected files.';
    }
    if (root && fileEdits.has(event.tool_name) && !ownsFile(root, resolved)) {
      return 'This seat (' + seat() + ') edits only under contrib/' + seat() + '/. Main seats launch without VOIDSWORN_CLAUDE_SEAT.';
    }
  } else if (fileEdits.has(event.tool_name)) {
    return 'The edit hook needs a file path.';
  }
  const glob = input.glob || (event.tool_name === 'Glob' ? input.pattern : null);
  if (glob && secretPath(glob)) return 'Leave credential paths out of searches.';
}

function bareWords(command) {
  // Recognize a single command with literal arguments. The shell must see the same words.
  const token = /(?:[A-Za-z0-9_./:@+=,~-]+|'[^'\\%\r\n]*'|"[^"\\\x60$%\r\n]*")(?=[ \t]|$)/y;
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

const isMain = name => /^(?:refs\/heads\/)?(?:main|master)$/i.test(name || '');
const branchName = ref => String(ref || '').replace(/^\+/, '').replace(/^refs\/heads\//, '');

function checkMainPush(cwd, remote, source, alone) {
  // A push that lands on main must be a fast-forward whose commits each change only the two Board logs (R102).
  if (fenced()) return 'Only a main seat can push the Board logs to main. Push your issue branch.';
  // The check reads commits that exist now; a commit made earlier in the same command would slip past it.
  if (!alone) return 'Push to main in a Bash call of its own (cd is fine), after the commit, so the hook can check every commit.';
  const pushUrl = git(cwd, ['remote', 'get-url', '--push', '--all', remote]).trim();
  if (!pushUrl || /\r?\n/.test(pushUrl)) return 'Use a remote with exactly one push URL.';
  const liveRef = git(cwd, ['ls-remote', '--exit-code', '--', pushUrl, 'refs/heads/main']).trim();
  const base = /^([a-f0-9]{40,64})\trefs\/heads\/main$/.exec(liveRef)?.[1];
  if (!base) return 'Could not verify the remote main. Fetch the remote and retry.';
  const sourceRef = source === 'HEAD' || source.startsWith('refs/') ? source : 'refs/heads/' + source;
  const tip = git(cwd, ['rev-parse', '--verify', sourceRef + '^{commit}']).trim();
  try {
    git(cwd, ['merge-base', '--is-ancestor', base, tip]);
  } catch {
    return 'A push to main must be a fast-forward of the live main. Fetch, rebase the log commit and retry.';
  }
  for (const commit of git(cwd, ['rev-list', base + '..' + tip]).trim().split('\n').filter(Boolean)) {
    const parents = git(cwd, ['rev-list', '--parents', '-n', '1', commit]).trim().split(' ');
    const changed = git(cwd, ['diff-tree', '--no-commit-id', '--no-renames', '--name-only', '-r', '-z', commit])
      .split('\0').filter(Boolean);
    if (parents.length !== 2 || !changed.length || changed.some(file => !boardLogs.has(file))) {
      return 'Each commit pushed to main must change only contrib/opus/LOOP.md or contrib/opus/FINDINGS.md. ' +
        'Everything else goes through an issue branch and a pull request.';
    }
  }
  if (!BOARD_LOG_TIP_LINTS_ENABLED || base === tip) return;
  const top = git(cwd, ['rev-parse', '--show-toplevel']).trim();
  // Both lints read other tracked documents too. Check the tip, not an unstaged fix or another branch's docs.
  if (git(top, ['diff', '--name-only', tip, '--']).trim() ||
      git(top, ['diff', '--cached', '--name-only', tip, '--']).trim()) {
    return 'Check out the Board log tip with no tracked changes before pushing it to main.';
  }
  for (const lint of ['memory_lint_tests.js', 'doc_check_tests.js']) {
    const run = spawnSync(process.execPath, [path.join(top, 'contrib/opus/tools', lint)], {
      cwd: top, env: { ...process.env, VS_ROOT: top }, encoding: 'utf8', timeout: 10000, windowsHide: true
    });
    if (run.status !== 0) {
      const detail = (run.stderr || run.stdout || run.error?.message || 'No output').trim().split(/\r?\n/).slice(0, 5);
      return 'The Board log tip did not pass ' + lint + ':\n' + detail.join('\n');
    }
  }
}

// Only these flags leave the destination and transport unchanged.
const pushFlags = new Set([
  '-q', '--quiet', '-v', '--verbose', '-u', '--set-upstream', '-n', '--dry-run',
  '--porcelain', '--progress', '--no-progress', '--atomic', '--no-atomic',
  '-d', '--delete', '-f', '--force', '--force-with-lease', '--force-if-includes', '--no-verify',
]);
const literalPush = 'Use plain git push with an explicit remote and named branch or refspec.';
const fullPushRef = /^(?:refs\/heads\/|refs\/tags\/).+/;

function resolvePushSource(cwd, source) {
  if (!/^[A-Za-z0-9_][A-Za-z0-9_./-]*$/.test(source)) return '';
  return git(cwd, ['rev-parse', '--symbolic-full-name', '--verify', '--end-of-options', source], [0, 1, 128]).trim();
}

function gitPush(cwd, words, alone) {
  // Don't guess a destination from Git's defaults, configuration overrides or partial ref names.
  let index = 1;
  while (index < words.length && words[index] !== 'push') {
    if (/^--(?:no-pager|paginate|no-optional-locks)$/.test(words[index])) { index++; continue; }
    if (words[index] !== '-C' || !words[index + 1]) return literalPush;
    cwd = path.resolve(cwd, words[index + 1]);
    index += 2;
  }
  const options = [];
  const positional = [];
  for (index++; index < words.length; index++) {
    const word = words[index];
    if (word === '--') {
      positional.push(...words.slice(index + 1));
      break;
    }
    if (!word.startsWith('-')) {
      positional.push(word);
      continue;
    }
    if (/^--(?:all|mirror|branches)$/.test(word)) {
      return 'Push named branches instead of --all, --mirror or --branches.';
    }
    if (!pushFlags.has(word) && !/^--force-with-lease=/.test(word) && !/^-[quvnfd]{2,}$/.test(word)) return literalPush;
    options.push(word);
  }
  const [remote, ...specs] = positional;
  if (!remote || remote.startsWith('-') || !specs.length) return literalPush;
  if (specs.some(spec => spec.includes('*') || /^\+?:$/.test(spec))) {
    return 'Push named branches instead of a wildcard or matching refspec.';
  }
  const shortFlag = flag => options.some(option => /^-[quvnfd]+$/.test(option) && option.includes(flag));
  const deleting = shortFlag('d') || options.includes('--delete');
  const forced = shortFlag('f') || options.some(option => /^--(?:force|force-with-lease(?:=.*)?|force-if-includes)$/.test(option));
  let configured;
  for (const spec of specs) {
    const force = forced || spec.startsWith('+');
    const body = spec.replace(/^\+/, '');
    const colon = body.indexOf(':');
    let source = deleting ? '' : colon < 0 ? body : body.slice(0, colon);
    let destination = colon < 0 ? body : body.slice(colon + 1);
    if (colon < 0 && !deleting) {
      // Git also applies remote.<name>.push mappings to source-only refspecs.
      configured ??= git(cwd, ['config', '--null', '--get-all', 'remote.' + remote + '.push'], [0, 1]);
      if (configured || source === 'HEAD') return literalPush;
      source = destination = resolvePushSource(cwd, source);
    }
    if (!fullPushRef.test(destination) && !isMain(destination)) return literalPush;
    if (isMain(destination)) {
      if (!source) return 'Main cannot be deleted.';
      if (force) return 'Main takes fast-forward pushes only. Drop the force flag.';
      if (!/^(?:refs\/heads\/)?main$/i.test(destination)) return 'Only main has the Board log exception.';
      if (source !== 'HEAD') source = resolvePushSource(cwd, source);
      if (!fullPushRef.test(source) && source !== 'HEAD') return literalPush;
      const reason = checkMainPush(cwd, remote, source, alone);
      if (reason) return reason;
    } else {
      git(cwd, ['check-ref-format', destination]);
    }
  }
}

function gitSubcommand(words) {
  for (let index = 1; index < words.length; index++) {
    if (/^(?:-C|-c|--config-env|--git-dir|--work-tree|--namespace|--super-prefix|--attr-source)$/.test(words[index])) index++;
    else if (!words[index].startsWith('-')) return words[index];
  }
  return '';
}

// Git builtins take precedence over aliases. Avoid a git config subprocess on
// every ordinary command. Update this list with git --list-cmds=builtins.
const gitBuiltins = new Set((
  'add am annotate apply archive backfill bisect blame branch bugreport bundle cat-file check-attr check-ignore check-mailmap ' +
  'check-ref-format checkout checkout--worker checkout-index cherry cherry-pick clean clone column commit commit-graph ' +
  'commit-tree config count-objects credential credential-cache credential-cache--daemon credential-store describe diagnose ' +
  'diff diff-files diff-index diff-tree difftool fast-export fast-import fetch fetch-pack fmt-merge-msg for-each-ref ' +
  'for-each-repo format-patch fsck fsck-objects fsmonitor--daemon gc get-tar-commit-id grep hash-object help hook index-pack ' +
  'init init-db interpret-trailers last-modified log ls-files ls-remote ls-tree mailinfo mailsplit maintenance merge ' +
  'merge-base merge-file merge-index merge-ours merge-recursive merge-recursive-ours merge-recursive-theirs merge-subtree ' +
  'merge-tree mktag mktree multi-pack-index mv name-rev notes pack-objects pack-redundant pack-refs patch-id pickaxe prune ' +
  'prune-packed pull push range-diff read-tree rebase receive-pack reflog refs remote remote-ext remote-fd repack replace ' +
  'replay repo rerere reset restore rev-list rev-parse revert rm send-pack shortlog show show-branch show-index show-ref ' +
  'sparse-checkout stage stash status stripspace submodule--helper survey switch symbolic-ref tag unpack-file unpack-objects ' +
  'update-index update-ref update-server-info upload-archive upload-archive--writer upload-pack var verify-commit verify-pack ' +
  'verify-tag version whatchanged worktree write-tree'
).split(' '));

function simpleCommands(script) {
  // Break only at unquoted separators and join quoted parts of words, such as
  // --raw-field=body="the /merges endpoint". This is not a shell interpreter.
  const token = /(?:[^ \t\r\n'"\\;&|()]+|'[^']*'|"(?:\\.|[^"\\])*"|\\.)+|[;&|()\r\n]/g;
  const commands = [];
  let words = [];
  for (const raw of script.matchAll(token)) {
    if (/^[;&|()\r\n]$/.test(raw[0])) {
      if (words.length) commands.push(words);
      words = [];
    } else {
      words.push(raw[0].replace(/'([^']*)'|"((?:\\.|[^"\\])*)"|\\(.)/g, (_, single, double, escaped) =>
        single ?? double ?? escaped));
    }
  }
  if (words.length) commands.push(words);
  return commands;
}

function commandArgs(words) {
  const start = words.findIndex(w => !/^(?:do|then|else|elif|if|while|until|time|!|\{|sudo|command|exec)$/.test(w) &&
    !/^[A-Za-z_][A-Za-z0-9_]*=/.test(w));
  return start < 0 ? [] : words.slice(start);
}

const isExecutable = (word, program) => new RegExp('(?:^|[/\\\\])' + program + '(?:\\.exe)?$', 'i').test(word || '');

function hasCommandSubstitution(script) {
  const nonLiteral = script.replace(/"(?:\\.|[^"\\])*"|'[^']*'/g, quoted => quoted[0] === "'" ? '' : quoted);
  return /(?:^|[^\\])(?:\$\(|\x60)/.test(nonLiteral);
}

function shellAliasWrites(expansion) {
  if (hasCommandSubstitution(expansion)) return true;
  return simpleCommands(expansion).some(segment => {
    const words = commandArgs(segment);
    return (isExecutable(words[0], 'git') && /^(?:push|send-pack)$/.test(gitSubcommand(words))) ||
      isExecutable(words[0], 'git-send-pack') || (isExecutable(words[0], 'gh') && words[1] === 'api');
  });
}

function pushAlias(cwd, words, subcommand) {
  if (!/^[a-z][\w-]*$/.test(subcommand) || gitBuiltins.has(subcommand)) return false;
  const prefix = [];
  // Ask Git for the effective alias, including any -C and -c options before the alias name.
  for (let i = 1; i < words.length; i++) {
    if (words[i] === subcommand) break;
    if (words[i] === '-C' || words[i] === '-c' || words[i] === '--config-env') prefix.push(words[i], words[++i]);
    else prefix.push(words[i]);
  }
  const seen = new Set();
  let name = subcommand.toLowerCase();
  while (/^[a-z][\w-]*$/.test(name) && !seen.has(name)) {
    if (name === 'push' || name === 'send-pack') return true;
    if (gitBuiltins.has(name)) return false;
    seen.add(name);
    const alias = spawnSync('git', [...prefix, 'config', '--get', 'alias.' + name], {
      cwd, encoding: 'utf8', timeout: 3000, windowsHide: true
    });
    if (alias.status !== 0) return false;
    const expansion = alias.stdout.trim();
    if (expansion.startsWith('!')) return shellAliasWrites(expansion.slice(1));
    const args = bareWords(expansion);
    name = (args ? gitSubcommand(['git', ...args]) : expansion.split(/\s/, 1)[0]).toLowerCase();
  }
  return false;
}

function shellSegments(command) {
  // Split compound commands and retries, but keep separators inside quoted arguments.
  const segments = [];
  let start = 0;
  for (const match of command.matchAll(/'[^']*'|"(?:\\.|[^"\\])*"|\\.|&&|\|\||[;|\r\n]/g)) {
    if (/^['"\\]/.test(match[0])) continue;
    segments.push(command.slice(start, match.index));
    start = match.index + match[0].length;
  }
  segments.push(command.slice(start));
  return segments.map(part => part.trim()).filter(Boolean);
}

function pushPolicy(cwd, command) {
  let here = cwd;
  const segments = shellSegments(command);
  for (const raw of segments) {
    // Output redirections do not change what is pushed.
    const segment = raw.replace(/(?:^|\s)(?:\d?>>?|&>)\s*(?:&\d|[^\s]+)/g, ' ').trim();
    let words = bareWords(segment);
    let hasEnvironment = false;
    if (words) {
      while (words.length && (/^(?:do|then|else|time|!|\{|\(|sudo)$/.test(words[0]) || /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[0]))) {
        hasEnvironment ||= /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[0]);
        words = words.slice(1);
      }
      if (words[0] === 'cd' && words.length === 2) {
        here = path.resolve(here, words[1].replace(/^~(?=$|\/)/, os.homedir()));
        continue;
      }
    }
    const mentionsPush = /\bgit(?:\.exe)?\b[\s\S]*\bpush\b|\bgit[- ]send-pack\b/i.test(segment);
    if (words && /^git(?:\.exe)?$/i.test(words[0])) {
      const subcommand = gitSubcommand(words);
      if (!/^(?:push|send-pack)$/.test(subcommand)) {
        if (pushAlias(here, words, subcommand)) return 'Run pushes as plain git push commands, not through an alias.';
        continue;
      }
      if (subcommand === 'send-pack') return 'Use plain git push with named branches instead of git send-pack.';
      if (hasEnvironment) return literalPush;
      const others = segments.filter(part => !/^cd\s/.test(part));
      const reason = gitPush(here, words, others.length === 1);
      if (reason) return reason;
    } else if (mentionsPush) {
      // A literal search for "git push main" is not a push. A push whose
      // arguments cannot be parsed as literal words must be written plainly.
      const push = simpleCommands(segment).map(commandArgs).some(args =>
        (isExecutable(args[0], 'git') && /^(?:push|send-pack)$/.test(gitSubcommand(args))) ||
        isExecutable(args[0], 'git-send-pack'));
      if (push || hasCommandSubstitution(segment)) {
        return 'Run this push as a plain git push command with literal names, so the hook can check it does not land on main.';
      }
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
  if (command === 'push') return;
  return 'Fenced seat shell writes are limited to staging, committing and pushing your own files. Use Claude file tools for edits.';
}

const keyFileOnly = /^[^\\/:]+\.(?:pem|p12|pfx|key)$/i;
function shellSecret(word, cwd) {
  // A bare "secret" or "secrets" is an ordinary word in commit messages and searches; only a path is a credential.
  if (/^\.?secrets?$/i.test(word)) return false;
  if (!secretPath(word)) return false;
  // A bare word that matches only by a key file extension is often code, such as board.key( in battle.gd (Fable's
  // audit of PR 1706): it counts only when it names a path (with a slash, backslash or colon) or a file that exists.
  if (keyFileOnly.test(word) && !secretName.test(word.replace(/\.(?:pem|p12|pfx|key)$/i, ''))) {
    try { return fs.existsSync(path.resolve(cwd || '.', word)); } catch { return true; }
  }
  return true;
}

const ghApiValueFlags = new Set([
  '-f', '-F', '--field', '--raw-field', '-X', '--method', '--input', '--cache',
  '-H', '--header', '--hostname', '-q', '--jq', '-p', '--preview', '-t', '--template',
]);

function ghApiPolicy(segment) {
  const words = commandArgs(segment);
  if (!isExecutable(words[0], 'gh') || words[1] !== 'api') return;
  let endpoint, method, hasInput = false;
  const fields = [];
  for (let i = 2; i < words.length; i++) {
    const word = words[i];
    if (word === '--') { endpoint ??= words[i + 1]; break; }
    if (!word.startsWith('-')) { endpoint ??= word; continue; }
    const flag = word.startsWith('--') ? word.split('=', 1)[0] : word.slice(0, 2);
    if (!ghApiValueFlags.has(flag)) continue;
    const value = word === flag ? words[++i] : word.slice(flag.length).replace(/^=/, '');
    if (flag === '-X' || flag === '--method') method = value?.toUpperCase();
    else if (flag === '--input') hasInput = true;
    else if (/^(?:-[fF]|--field|--raw-field)$/.test(flag)) fields.push(value || '');
  }
  const writes = method ? /^(?:POST|PATCH|PUT|DELETE)$/.test(method) : hasInput || fields.length > 0;
  if (!writes) return;
  const route = /^(?:https?:\/\/[^/]+\/)?\/?repos\/[^/]+\/[^/]+(\/[^?#]*)/i.exec(endpoint || '')?.[1] || '';
  if (/^\/merges(?:\/|$)/i.test(route)) {
    return 'Merge through a pull request (pulls/<n>/merge), not the branch merges API.';
  }
  const contents = /^\/contents(?:\/|$)/i.test(route);
  const refs = /^\/git\/(?:refs|matching-refs)(?:\/|$)/i.test(route);
  if (!contents && !refs) return;
  if (fenced()) return 'Fenced seats push their own branch with git push.';
  const branchFields = fields.filter(field => field.startsWith('branch=')).map(field => field.slice(7));
  const mainRef = refs && (/^\/git\/(?:refs|matching-refs)\/heads\/(?:main|master)\/?$/i.test(route) ||
    fields.some(field => /^ref=(?:refs\/)?heads\/(?:main|master)$/i.test(field)));
  if (mainRef || (contents && (!branchFields.length || branchFields.some(isMain)))) {
    return 'Direct writes to main are blocked. Name a branch other than main, or push the Board logs with git push.';
  }
}

function shellPolicy(event, root, input) {
  const command = input.command;
  if (typeof command !== 'string') return 'The shell hook needs a command.';
  // Check literal credential names even in compound commands and PowerShell arguments.
  if (command.split(/[\s"'=|&;<>()[\]{},]+/).some(word => shellSecret(word, event.cwd)) ||
      /(?:^|[\s;|&])(?:printenv\b|env\s*(?:$|[;|&])|gh\s+auth\s+token\b|git\s+credential\b|(?:Get-ChildItem|gci|dir|ls)\s+Env:|Get-Item\s+Env:)|(?:\$env:|\$\{?)[\w]*(?:TOKEN|PASSWORD|SECRET|API_KEY)\b/i.test(command)) {
    return 'Use the masked key installer for credentials. Claude cannot read protected files or print credentials.';
  }
  const pushReason = pushPolicy(event.cwd || '.', command);
  if (pushReason) return pushReason;
  const apiReason = /\bgh(?:\.exe)?\b/i.test(command) && simpleCommands(command).map(ghApiPolicy).find(Boolean);
  if (apiReason) return apiReason;
  if (!root) return;
  const words = bareWords(command.trim());
  if (words?.length === 1 && words[0] === 'pwd') return;
  if (words && /^git(?:\.exe)?$/i.test(words[0])) return workerGit(root, event.cwd, words);
  return 'Fenced seats use Claude file tools to read and edit. Ask the Board for other shell work.';
}

function directWrite(event) {
  const input = event.tool_input || {};
  if (fenced()) return 'Fenced seats push their own branch with git push.';
  const name = event.tool_name.replace(/^mcp__.*__/, '');
  const target = input.branch ?? input.ref ?? input.head;
  if (name === 'create_branch') return isMain(branchName(input.branch)) ? 'Main already exists and cannot be recreated.' : undefined;
  if (target === undefined || target === null || target === '') {
    return 'Name the branch for this direct write. A write without a branch lands on main.';
  }
  if (isMain(branchName(String(target).replace(/^heads\//, '')))) {
    return 'Direct writes to main are blocked. Push the Board logs with git push, everything else through a pull request.';
  }
}

function preTool(event) {
  const input = event.tool_input || {};
  if (directWrites.test(event.tool_name)) return directWrite(event);
  let root = null;
  if (fenced()) {
    const checkout = projectCheckout(event.cwd);
    if (shells.has(event.tool_name) && !checkout.inProject) return 'Fenced seat shell commands need the project checkout.';
    root = checkout.root;
  }
  return shells.has(event.tool_name) ? shellPolicy(event, root, input) : protectPath(event, root, input);
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

function readState(file) {
  try {
    const state = JSON.parse(fs.readFileSync(file, 'utf8'));
    return state && typeof state === 'object' ? state : {};
  } catch {
    return {};
  }
}

function godotCommand() {
  if (process.env.GODOT_EXE || process.env.GODOT) return process.env.GODOT_EXE || process.env.GODOT;
  const installed = path.join(os.homedir(), 'Downloads', 'voidsworn_test', 'godot', 'Godot_v4.7.2-stable_win64_console.exe');
  return process.platform === 'win32' && fs.existsSync(installed) ? installed : 'godot';
}

function note(message) {
  // Shown to the person; never blocks. Used when the check could not run, so a missing setup cannot loop the turn.
  process.stdout.write(JSON.stringify({ systemMessage: message }) + '\n');
}

// Compare what the Godot loader can read at each end of the turn, including untracked scenes.
function dirtyGodotFiles(root, head) {
  const names = [
    git(root, ['diff', '--name-only', '--no-renames', '-z', head, '--', 'godot']),
    git(root, ['ls-files', '--others', '--exclude-standard', '-z', '--', 'godot'])
  ].join('').split('\0').filter(file => godotCode.test(file));
  const dirty = {};
  for (const file of names) {
    const target = path.join(root, file);
    const stat = fs.lstatSync(target, { throwIfNoEntry: false });
    if (stat?.isFile()) dirty[file] = createHash('sha256').update(fs.readFileSync(target)).digest('hex');
    else if (stat?.isSymbolicLink()) dirty[file] = 'link:' + fs.readlinkSync(target);
    else dirty[file] = null;
  }
  return dirty;
}

function godotTurn(event) {
  const { root } = projectCheckout(event.cwd);
  const file = stateFile(process.env.CLAUDE_PROJECT_DIR || root, event.session_id);
  if (event.hook_event_name === 'UserPromptSubmit') {
    const head = git(root, ['rev-parse', 'HEAD']).trim();
    fs.writeFileSync(file, JSON.stringify({ head, dirty: dirtyGodotFiles(root, head) }), { mode: 0o600 });
    return;
  }
  if (event.hook_event_name === 'SessionEnd') {
    fs.rmSync(file, { force: true });
    return;
  }
  const state = readState(file);
  const start = typeof state.head === 'string' ? state.head : 'HEAD';
  if (!/^(?:[a-f0-9]{40,64}|HEAD)$/.test(start)) throw new Error('Invalid Godot check baseline.');
  const before = state.dirty || {};
  const after = dirtyGodotFiles(root, start);
  if (Object.keys(before).length === Object.keys(after).length &&
      Object.keys(after).every(name => before[name] === after[name])) return;
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
  if (check.error) {
    // Missing Godot or a loader timeout is a setup problem the model cannot fix by retrying: never block on it.
    note('Godot parse check skipped: Godot could not run here (' + (check.error.code || check.error.message) +
      '). Set GODOT_EXE or put Godot on PATH. GitHub checks still run the full load.');
    return;
  }
  const output = check.stdout + '\n' + check.stderr;
  if (check.status !== 0 || /SCRIPT ERROR|Parse Error|load all: FAILED/.test(output) ||
      !/^load all: \d+ scripts, \d+ scenes, 0 failed\r?$/m.test(output)) {
    const failure = output.trim().slice(0, 4500);
    const digest = createHash('sha256').update(failure.replace(/\d+(?:\.\d+)?\s*ms\b/g, '')).digest('hex');
    if (event.stop_hook_active && state.failure === digest) {
      // The model already had one turn to fix this exact failure and nothing changed: stop instead of looping.
      note('Godot parse check still fails after one retry. Ending the turn so it does not loop; report the failure.\n' +
        failure.slice(0, 1500));
      return;
    }
    fs.writeFileSync(file, JSON.stringify({ ...state, failure: digest }), { mode: 0o600 });
    return 'Godot parse check failed. Fix the errors before ending the turn.\n' + failure;
  }
  if (state.failure) {
    delete state.failure;
    fs.writeFileSync(file, JSON.stringify(state), { mode: 0o600 });
  }
  process.stdout.write('Godot parse check passed.\n');
}

try {
  const event = JSON.parse(fs.readFileSync(0, 'utf8').replace(/^\uFEFF/, ''));
  const hook = process.argv[2];
  const reason = { pre: preTool, 'em-dash': emDash, godot: godotTurn }[hook](event);
  if (reason) block(reason);
} catch (error) {
  // Tool calls fail closed. The turn hooks (prompt, stop, session end) and the em dash note fail open, so a broken
  // setup can never block a prompt or restart the same turn.
  if (process.argv[2] === 'pre') block('Voidsworn hook could not verify this action. ' + error.message);
  else note('Voidsworn ' + process.argv[2] + ' hook skipped: ' + error.message);
}
