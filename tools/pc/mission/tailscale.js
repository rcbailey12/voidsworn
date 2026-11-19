'use strict';
// Shared by the publisher and phone launcher. Never starts or signs into Tailscale.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

function findTailscale(env = process.env, exists = fs.existsSync) {
  const candidates = [env.ProgramW6432, env.ProgramFiles, env['ProgramFiles(x86)']]
    .filter(Boolean).map(dir => path.join(dir, 'Tailscale', 'tailscale.exe'));
  for (const dir of (env.PATH || env.Path || '').split(path.delimiter).filter(Boolean)) {
    candidates.push(path.join(dir, process.platform === 'win32' ? 'tailscale.exe' : 'tailscale'));
  }
  return candidates.find(exists) || null;
}

function dnsName(status) {
  if (status?.BackendState !== 'Running' || status?.Self?.Online === false) return null;
  const name = status?.Self?.DNSName;
  if (typeof name !== 'string') return null;
  const host = name.replace(/\.$/, '').toLowerCase();
  // Only a full, valid device name in a ts.net tailnet, never a URL or wildcard.
  const label = '[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?';
  return host.length <= 253 && new RegExp(`^${label}\\.${label}\\.ts\\.net$`).test(host) ? host : null;
}

function discover(run = spawnSync, executable = findTailscale()) {
  if (!executable) return { executable: null, host: null };
  try {
    const result = run(executable, ['status', '--json'], { encoding: 'utf8', windowsHide: true, timeout: 5000, maxBuffer: 4 * 1024 * 1024 });
    return { executable, host: result.status === 0 ? dnsName(JSON.parse(result.stdout)) : null };
  } catch (_) { return { executable, host: null }; }
}

module.exports = { findTailscale, dnsName, discover };
