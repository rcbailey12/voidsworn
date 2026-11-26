'use strict';

const fs = require('node:fs');
const path = require('node:path');
const env = process.env;
const win = process.platform === 'win32';
const slash = p => win ? p.replace(/\\/g, '/') : p;

function shardScratch() {
  // Use native path APIs. Git Bash mkdir can be denied on sandbox paths with doubled backslashes.
  const bases = [env.RUNNER_TEMP, env.TMPDIR, env.TEMP, env.TMP,
    win ? (env.USERPROFILE && path.join(env.USERPROFILE, 'AppData', 'Local', 'Temp')) : '/tmp'];
  for (const base of bases) {
    if (!base || !path.isAbsolute(base)) continue;
    let dir;
    try {
      dir = fs.mkdtempSync(path.join(path.resolve(base), 'godot_checks-'));
    } catch {
      continue;
    }
    for (const child of ['logs', 'fixtures', 'xdg']) fs.mkdirSync(path.join(dir, child));
    return dir;
  }
  throw new Error('no writable temp root');
}

function onboardingAlias() {
  if (!env.GODOT_TEMP_DIR || !path.isAbsolute(env.GODOT_TEMP_DIR)) throw new Error('Godot did not report an absolute temp path');
  const dir = fs.mkdtempSync(path.join(env.GODOT_TEMP_DIR, 'voidsworn-onboarding-ci-'));
  const profile = path.join(dir, 'profile');
  try {
    // A Windows directory junction does not require symlink privileges.
    fs.symlinkSync(env.CHECK_USER_DIR, profile, win ? 'junction' : 'dir');
  } catch (err) {
    fs.rmdirSync(dir);
    throw err;
  }
  return profile;
}

try {
  if (process.argv[2] === 'shard') process.stdout.write(slash(shardScratch()));
  else if (process.argv[2] === 'onboarding') process.stdout.write(slash(onboardingAlias()));
  else if (process.argv[2] === 'unlink-onboarding') {
    fs.unlinkSync(env.CHECK_PROFILE_ALIAS);
    fs.rmdirSync(path.dirname(env.CHECK_PROFILE_ALIAS));
  } else throw new Error('unknown scratch operation');
} catch (err) {
  console.error(err.message);
  process.exitCode = 1;
}
