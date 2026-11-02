#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');

const number = x => typeof x === 'number' && Number.isFinite(x);
const fmt = (x, digits = 2) => number(x) ? x.toFixed(digits) : 'not logged';
const safe = x => String(x ?? 'not logged').replace(/[^\x20-\x7e]/g, '?').replace(/\|/g, '\\|');
const auto = a => ['nothing_left', 'rules'].includes(a.end);
const limitations = [
  'Faction means enemy faction. Player faction is not in battle files.',
  'Screen contents, remaining actions at end, and failed fire attempts with no target in arc are not logged.',
  'Plans, targets, inspections and cancels are counts, without timing or contents. Plan changes cannot be reconstructed.',
  'Enemy time is an aggregate per round, not individual enemy turn lengths.',
  'No-action think_ms is time until close, not time to a first action. Think-time totals and rankings exclude these waits.',
  'Auto-end means end=nothing_left or rules; brace is reported separately. Several cancels means at least 3.',
  'Campaign battle_play entries lack battle metadata and a unique battle ID. Campaign entries are used only when no battle files exist; otherwise the save is context only, to avoid guessing matches or double counting.',
  'Campaign keeps only 600 events and removes activations from battle_play entries older than the newest 40.'
];

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''), (_, v) => {
    if (typeof v === 'string' && /^#d:[0-9a-f]{16}$/i.test(v)) {
      return Buffer.from(v.slice(3), 'hex').readDoubleBE();
    }
    return v;
  });
}

function load(folder, campaignFile, explicitCampaign = false) {
  const warnings = [];
  let names = [];
  try { names = fs.readdirSync(folder).filter(n => /^battle_.*\.json$/i.test(n)).sort(); }
  catch (e) { if (e.code !== 'ENOENT') throw e; warnings.push('Battle log folder not found: ' + folder); }
  const battles = names.map(n => ({ source: n, log: readJson(path.join(folder, n)) }));
  let campaign;
  if (fs.existsSync(campaignFile)) campaign = readJson(campaignFile);
  else if (explicitCampaign) throw new Error('Campaign save not found: ' + campaignFile);
  const events = Array.isArray(campaign?.tel) ? campaign.tel : [];
  if (!battles.length) {
    let start = null;
    for (const e of events) {
      if (e.ev === 'run_start' || e.ev === 'run_end') start = null;
      if (e.ev === 'battle_start') start = e;
      if (e.ev === 'battle_play') {
        battles.push({ source: 'campaign battle_play t=' + e.t, log: { ...e,
          battle: { enemy: start?.fac, obj: typeof start?.obj === 'object' ? start.obj?.type : start?.obj } } });
        start = null;
      }
      if (e.ev === 'battle_end') start = null;
    }
  }
  return { battles, warnings, campaignEvents: events.length, campaignTips: events.filter(e => e.ev === 'teaching_tip') };
}

function report({ battles, warnings = [], campaignEvents = 0, campaignTips = [] }) {
  const out = ['# Battle play report', '', '## Overview', '',
    'Battles played: ' + battles.length + '. Campaign events available: ' + campaignEvents + '.', '',
    '| Battle | Enemy faction | Objective | Result | Rounds | Real minutes |',
    '| --- | --- | --- | --- | --- | --- |'];
  const thinks = [], hesitations = [];
  let activations = 0, automatic = 0, cancels = 0, covered = 0;
  battles.forEach(({ source, log: b }, i) => {
    out.push(`| ${i + 1}: ${safe(source)} | ${safe(b.battle?.enemy)} | ${safe(b.battle?.obj)} | ${safe(b.result)} | ${safe(b.rounds)} | ${fmt(number(b.secs) ? b.secs / 60 : null)} |`);
  });
  battles.forEach(({ source, log: b }, i) => {
    out.push('', `## Battle ${i + 1}: ${safe(source)}`, '');
    if (!Array.isArray(b.acts)) out.push('Activation details not retained.');
    else {
      covered++;
      out.push('| Round | Ship | Selected by | Think seconds | Actions (seconds after selection) | End | Cancels | Plans / targets / inspections |',
        '| --- | --- | --- | --- | --- | --- | --- | --- |');
      for (const a of b.acts) {
        const acts = Array.isArray(a.acts) ? a.acts : [];
        activations++; automatic += Number(auto(a)); cancels += number(a.cancels) ? a.cancels : 0;
        if (acts.length && number(a.think_ms)) {
          thinks.push(a.think_ms);
          hesitations.push({ a, battle: i + 1 });
        }
        const actions = acts.map(e => {
          const details = Object.entries(e).filter(([k]) => !['k', 'at'].includes(k)).map(([k, v]) => `${safe(k)}=${safe(v)}`).join(', ');
          return `${safe(e.k)} @ ${fmt(number(e.at) ? e.at / 1000 : null)}s${details ? ' (' + details + ')' : ''}`;
        }).join('; ') || (String(a.end).endsWith('_pass') ? 'pass' : 'no action recorded');
        const end = auto(a) ? 'auto-end (' + a.end + ')' : a.end;
        out.push(`| ${safe(a.r)} | ${safe(a.name || a.ship)} [${safe(a.ship)}] | ${safe(a.how)} | ${fmt(number(a.think_ms) ? a.think_ms / 1000 : null)}${acts.length ? '' : ' (until close)'} | ${actions} | ${safe(end)} | ${safe(a.cancels)} | ${safe(a.plans)} / ${safe(a.targets)} / ${safe(a.inspects)} |`);
      }
    }
    const enemy = Object.entries(b.enemy_s || {});
    out.push('', 'Enemy time per round: ' + (enemy.length ? enemy.map(([r, s]) => `round ${safe(r)}: ${fmt(s)}s`).join('; ') : 'not logged') + '.',
      'Enemy hurries: ' + safe(b.hurries) + '.');
  });
  const tips = [...battles.flatMap(({ log: b }, i) => (b.tips || []).map(e => ({ ...e, place: `Battle ${i + 1}, round ${safe(e.r)}, ${safe(e.activation)}` }))),
    ...campaignTips.map(e => ({ ...e, place: e.screen || 'campaign' }))];
  out.push('', '## Teaching cards', '');
  const counts = { show: 0, dismiss: 0, retire: 0 };
  for (const e of tips) if (Object.hasOwn(counts, e.k)) counts[e.k]++;
  out.push(`Shows: ${counts.show}; dismissals: ${counts.dismiss}; action retirements: ${counts.retire}.`, '');
  if (tips.length) {
    out.push('| Location | Event | Card | Reason | Time |', '| --- | --- | --- | --- | --- |');
    for (const e of tips) out.push(`| ${safe(e.place)} | ${safe(e.k)} | ${safe(e.id)} | ${safe(e.why || '')} | ${number(e.at) ? fmt(e.at / 1000) + 's in battle' : number(e.t) ? safe(e.t) + 'ms timestamp' : 'not logged'} |`);
  } else out.push('No teaching-card events recorded (older logs do not contain them).');
  out.push('', '## Where Ryan hesitated', '');
  hesitations.sort((x, y) => y.a.think_ms - x.a.think_ms).slice(0, 10).forEach(({ a, battle }, i) => {
    out.push(`${i + 1}. Battle ${battle}, round ${safe(a.r)}, ${safe(a.name || a.ship)} [${safe(a.ship)}]: ${fmt(a.think_ms / 1000)}s; first action ${safe(a.acts[0].k)}. Screen: not logged.`);
  });
  if (!hesitations.length) out.push('No timed first actions recorded.');
  out.push('', '## Possible confusion', '');
  let flags = 0;
  battles.forEach(({ log: b }, i) => (b.acts || []).forEach(a => {
    if (a.cancels >= 3) { flags++; out.push(`- Battle ${i + 1}, round ${safe(a.r)}, ${safe(a.name || a.ship)}: ${a.cancels} cancels; ${safe(a.plans)} move previews and ${safe(a.targets)} targets. This is a review cue, not proof of confusion.`); }
  }));
  if (!flags) out.push('No activations with at least 3 cancels.');
  out.push('Unused actions and no-target-in-arc fire attempts: not logged.', '', '## Totals', '');
  const sorted = thinks.slice().sort((a, b) => a - b), n = sorted.length;
  const median = n ? (sorted[Math.floor((n - 1) / 2)] + sorted[Math.floor(n / 2)]) / 2 : null;
  out.push(`- Activations: ${activations}; battles with activation details: ${covered}/${battles.length}.`,
    `- Timed first actions: ${n}. Average think time: ${fmt(n ? thinks.reduce((a, b) => a + b, 0) / n / 1000 : null)}s. Median: ${fmt(n ? median / 1000 : null)}s.`,
    `- Auto-ended ships (activation share): ${automatic}/${activations} (${activations ? fmt(automatic / activations * 100) + '%' : 'not logged'}).`,
    `- Cancels: ${cancels}; average per battle with activation details: ${fmt(covered ? cancels / covered : null)}.`);
  battles.forEach(({ log: b }, i) => out.push(`- Battle ${i + 1} cancels: ${Array.isArray(b.acts) ? b.acts.reduce((s, a) => s + (number(a.cancels) ? a.cancels : 0), 0) : 'not retained'}.`));
  out.push('', '## Format limits and definitions', '', ...limitations.map(s => '- ' + s), ...warnings.map(s => '- Warning: ' + safe(s)), '');
  return out.join('\n');
}

function main(args) {
  const positional = []; let output;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--out') { output = args[++i]; if (!output) throw new Error('--out requires a file'); }
    else if (args[i].startsWith('--')) throw new Error('Unknown option: ' + args[i]);
    else positional.push(args[i]);
  }
  if (positional.length > 2) throw new Error('Usage: node playlog_report.js [log-folder] [campaign-save] [--out report.md]');
  const base = path.join(process.env.APPDATA || path.join(process.env.USERPROFILE || '', 'AppData', 'Roaming'), 'Godot', 'app_userdata', 'Voidsworn');
  const result = report(load(positional[0] || path.join(base, 'play_logs'), positional[1] || path.join(base, 'voidsworn_campaign.json'), !!positional[1]));
  if (output) fs.writeFileSync(output, result, 'utf8');
  process.stdout.write(result);
}
module.exports = { load, report, readJson };
if (require.main === module) {
  try { main(process.argv.slice(2)); } catch (e) { console.error('playlog_report: ' + e.message); process.exitCode = 1; }
}
