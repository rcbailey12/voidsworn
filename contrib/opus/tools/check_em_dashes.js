'use strict';
const fs = require('fs');
const { execFileSync } = require('child_process');

const revision = process.argv[2] || 'origin/main...HEAD';
const changed = execFileSync('git', ['diff', '--name-only', '-z', '--find-renames', '--diff-filter=ACMRT', revision, '--'],
  { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
// Issue 1488 (audit GH-06) added Godot shader and resource text (.gdshader, .gdshaderinc, .tres), .toml and .cmd.
const text = /\.(?:bat|cfg|cmd|css|csv|gd|gdshader|gdshaderinc|godot|html|import|js|json|jsonl|log|md|mjs|patch|ps1|py|sh|svg|toml|tres|tscn|tsv|txt|uid|ya?ml)$/i;
const mark = String.fromCodePoint(0x2014);
for (const file of changed.split('\0')) {
  if (!text.test(file) || !fs.lstatSync(file).isFile()) continue;
  const bytes = fs.readFileSync(file);
  let content;
  // Windows PowerShell 5.1 can write scripts as UTF-16.
  if (bytes[0] === 0xff && bytes[1] === 0xfe) content = bytes.toString('utf16le');
  else if (bytes[0] === 0xfe && bytes[1] === 0xff) content = new TextDecoder('utf-16be').decode(bytes);
  else content = bytes.toString('utf8');
  if (content.includes(mark)) {
    console.error('Em dash found in ' + JSON.stringify(file));
    process.exitCode = 1;
  }
}
if (!process.exitCode) console.log('No em dashes in changed files.');
