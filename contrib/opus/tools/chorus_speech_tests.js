// Issue 2250: check the live Chorus text, not a second list of approved lines.
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../../..');
const read = file => JSON.parse(fs.readFileSync(path.join(root, 'godot', file), 'utf8'));
const story = name => read('story/data/' + name + '.json');
const MAX_WORDS = 12;

function overlong(text) {
  // Count author-written words. A substitution is one unit, just like a hyphenated word.
  // Ignore a decimal point but not a period after a number.
  return text.replace(/\{[a-z_]+\}/gi, 'token')
    .split(/(?<!\d)\.|\.(?!\d)|[!?\u2026]+|\r?\n/)
    .flatMap(sentence => {
      const count = (sentence.match(/[\p{L}\p{N}]+(?:['\u2019-][\p{L}\p{N}]+|(?<=\d)\.(?=\d)\d+)*/gu) || []).length;
      return count > MAX_WORDS ? [{ sentence: sentence.trim(), count }] : [];
    });
}

assert.deepEqual(overlong('One two three four five six seven eight nine ten eleven twelve. We feed.'), []);
assert.deepEqual(overlong('One two three four five six seven eight nine ten eleven twelve thirteen!'),
  [{ sentence: 'One two three four five six seven eight nine ten eleven twelve thirteen', count: 13 }]);
assert.deepEqual(overlong("Our brood-sac can't hold 1.5 more cores. \"Taste the heat.\"\nFeed now."), []);

const lines = [];
function add(id, value) {
  assert(typeof value === 'string' && value.trim(), 'Missing Chorus text: ' + id);
  lines.push([id, value]);
}

function pool(id, value) {
  if (typeof value === 'string') return add(id, value);
  assert(value && typeof value === 'object' && Object.keys(value).length, 'Missing Chorus pool: ' + id);
  for (const [key, item] of Object.entries(value)) pool(id + '.' + key, item);
}

const t = read('campaign/data/campaign_tables.json').tables;
const voices = story('voices');
const admirals = Object.keys(t.ADMIRALS).filter(id => t.ADMIRALS[id].fac === 'chorus');
assert(admirals.length, 'Missing Chorus admirals');
for (const id of admirals) pool('voices.admirals.' + id, voices.admirals[id]);
pool('voices.factions.chorus', voices.factions.chorus);

const situations = story('situations');
for (const group of ['by_enemy', 'by_objective', 'outcome', 'events', 'by_cond']) {
  pool('situations.' + group + '.chorus', situations[group].chorus);
}
pool('rival_lines.chorus', story('rival_lines').chorus);
add('arcs.chorus.medal.d', story('arcs').chorus.medal.d);

const nem = t.NEM_VOICE.chorus;
for (const [key, value] of Object.entries(nem)) {
  // Lessons are neutral tactical advice about the Chorus, not spoken by it.
  if (key !== 'lessons') pool('NEM_VOICE.chorus.' + key, value);
}
for (const key of Object.keys(t.NEM_LINES.gloat)) {
  assert(Object.hasOwn(nem.gloat, key), 'Missing Chorus gloat: ' + key);
}

for (const event of t.EVENTS) {
  const row = event.v?.chorus;
  const id = 'EVENTS.' + event.id;
  if (row) {
    if (row.t !== undefined) add(id + '.chorus.t', row.t);
    if (row.b !== undefined) add(id + '.chorus.b', row.b);
    for (const [i, option] of (row.o || []).entries()) {
      const fac = option.need?.fac;
      if (fac && !(Array.isArray(fac) ? fac : [fac]).includes('chorus')) continue;
      add(id + '.chorus.o.' + i + '.l', option.l);
      add(id + '.chorus.o.' + i + '.s', option.s);
    }
  } else {
    // A shared event can still have a choice written for, and gated to, the Chorus.
    for (const [i, option] of event.o.entries()) {
      if (option.need?.fac === 'chorus') add(id + '.o.' + i + '.l', option.l);
    }
  }
}

const beat = t.STORY_BEAT3.chorus;
for (const [i, line] of beat.lines.entries()) {
  add('STORY_BEAT3.chorus.lines.' + i, line.replace(/^(Memory|Hunger|The Swarm):\s*/, ''));
}
for (const [i, option] of beat.o.entries()) {
  add('STORY_BEAT3.chorus.o.' + i + '.t', option.t);
  add('STORY_BEAT3.chorus.o.' + i + '.tx', option.tx);
}
for (const key of ['t', 'debrief', 'learning', 'spotlights']) pool('STORY_BEAT3.chorus.' + key, beat[key]);
add('WIN_TITLE.chorus', t.WIN_TITLE.chorus);

// These lines live beside the UI or campaign action that displays them. Read the
// literals there and count each interpolated name as one author-written word.
const literal = /("(?:[^"\\\r\n]|\\.)*")/.source;
const join = String.raw`\s*\+\s*`;
const campaign = 'campaign/campaign.gd';
const ui = 'ui/campaign/campaign_ui.gd';
const sources = new Map();
function code(id, file, pattern, prefix = '') {
  if (!sources.has(file)) sources.set(file, fs.readFileSync(path.join(root, 'godot', file), 'utf8'));
  const matches = [...sources.get(file).matchAll(new RegExp(pattern, 'gm'))];
  assert.equal(matches.length, 1, 'Expected one Chorus line for ' + id + ' in ' + file);
  const text = matches[0].slice(1).map(part => JSON.parse(part)).join('{name}');
  add(id, prefix + text.replace(/%s/g, '{name}'));
}

const chorus = String.raw`"chorus":\s*` + literal;
for (const [variable, ship] of [['r_line', 'sh'], ['p_line', 'sh2']]) {
  code('campaign.' + variable, campaign,
    String.raw`\bvar ${variable}: String = str\(\{${chorus}${join}ship_bare\(str\(${ship}\["name"\]\)\)${join}${literal},`);
}
code('campaign.escape', campaign, String.raw`\bvar esc_tail: String = \{${chorus},`, '{name}');
code('campaign_ui.eatenCore', ui,
  String.raw`if C\.jt\(R\.get\("eatenCore"\)\).*?\blbl\(${literal}${join}str\(C\.PATRONS\[R\["eatenCore"\]\]\["n"\]\)${join}${literal},`);
code('campaign_ui.lineage', ui, String.raw`\bvar _lin_lead: String = \{[^\r\n]*?${chorus},`);
code('campaign_ui.escape', ui, String.raw`\bvar escape_line: String = \{\s*${chorus},`);
code('campaign_ui.eatCore', ui, String.raw`^\s*"eatCore":\r?\n[^\r\n]*\r?\n\s*p\.call\(${literal},`);
code('rename_dialog.subtitle', 'ui/career/rename_dialog.gd',
  String.raw`\bvar _rename_sub := \{[^}]*?${chorus},`);

let errors = 0;
for (const [id, text] of lines) {
  for (const { sentence, count } of overlong(text)) {
    console.error('FAIL ' + id + ' (' + count + '/' + MAX_WORDS + ' words): ' + sentence);
    errors++;
  }
}
if (errors) process.exitCode = 1;
else console.log('PASS: ' + lines.length + ' Chorus text entries, no sentence over ' + MAX_WORDS + ' words');
