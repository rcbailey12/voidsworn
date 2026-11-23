'use strict';

const fs = require('node:fs');
const outcomes = ['completed_win', 'completed_loss', 'bot_concession', 'timeout', 'engine_error'];
const metrics = {
  win_pp: row => row.terminal_reason === 'completed_win' ? 100 : 0,
  timeout_pp: row => row.terminal_reason === 'timeout' ? 100 : 0,
  bot_concession_pp: row => row.terminal_reason === 'bot_concession' ? 100 : 0,
  rounds: row => row.rounds,
  hull_pp: row => row.hull * 100,
  lost: row => row.lost,
};

function cellKey({ faction, difficulty, cell }) {
  return [faction, difficulty, cell.mode, cell.sector, cell.kind, cell.column];
}

function readArm(path) {
  const rows = new Map();
  let arm;
  const log = fs.readFileSync(path, 'utf8').replace(/^\uFEFF/, '');
  for (const [index, line] of log.split(/\r?\n/).entries()) {
    const prefix = `${path}:${index + 1}`;
    if (!line.startsWith('TRIAL ')) {
      if (/^(SCRIPT ERROR:|Balance sim:)/.test(line)) throw new Error(`${prefix} ${line}`);
      continue;
    }
    let row;
    try {
      row = JSON.parse(line.slice('TRIAL '.length));
    } catch (error) {
      throw new Error(`${prefix} invalid TRIAL JSON: ${error.message}`);
    }
    const cell = row?.cell;
    if (!row || ![row.faction, row.difficulty, row.arm, cell?.mode, cell?.kind].every(value => typeof value === 'string' && value) ||
        ![cell.sector, cell.column, row.seed].every(Number.isSafeInteger) || !outcomes.includes(row.terminal_reason)) {
      throw new Error(`${prefix} invalid trial key or terminal reason`);
    }
    const key = JSON.stringify([...cellKey(row), row.seed]);
    if (row.terminal_reason === 'engine_error') throw new Error(`${prefix} engine error in trial ${key}`);
    const fired = row.abilities_fired;
    if (![row.rounds, row.hull, row.lost].every(Number.isFinite) || !fired || typeof fired !== 'object' || Array.isArray(fired) ||
        !Object.values(fired).every(count => Number.isSafeInteger(count) && count >= 0)) {
      throw new Error(`${prefix} invalid trial metrics`);
    }
    arm ??= row.arm;
    if (arm !== row.arm) throw new Error(`${prefix} expected arm ${arm}, got ${row.arm}`);
    if (rows.has(key)) throw new Error(`${prefix} duplicate trial key ${key}`);
    rows.set(key, row);
  }
  if (!rows.size) throw new Error(`${path} contains no TRIAL records`);
  return { arm, rows };
}

function compare(control, treatment) {
  for (const [from, to] of [[control, treatment], [treatment, control]]) {
    const missing = [...from.rows.keys()].filter(key => !to.rows.has(key));
    if (missing.length) {
      throw new Error(`Trial key sets differ: ${to.arm} is missing ${missing.length} key(s) from ${from.arm}, first ${missing[0]}`);
    }
  }
  if (control.arm === treatment.arm) throw new Error('Set a different SIM_ARM for each input.');

  const cells = new Map();
  for (const [key, before] of control.rows) {
    const after = treatment.rows.get(key);
    const { faction, difficulty, cell } = before;
    const groupKey = JSON.stringify(cellKey(before));
    if (!cells.has(groupKey)) {
      const delta = Object.fromEntries(Object.keys(metrics).map(metric => [metric, 0]));
      delta.abilities_fired = Object.create(null);
      cells.set(groupKey, { faction, difficulty, cell, control: control.arm, treatment: treatment.arm, pairs: 0, delta });
    }
    const group = cells.get(groupKey);
    group.pairs++;
    for (const [metric, value] of Object.entries(metrics)) group.delta[metric] += value(after) - value(before);
    const ids = new Set([...Object.keys(before.abilities_fired), ...Object.keys(after.abilities_fired)]);
    for (const id of ids) {
      const start = Object.hasOwn(before.abilities_fired, id) ? before.abilities_fired[id] : 0;
      const end = Object.hasOwn(after.abilities_fired, id) ? after.abilities_fired[id] : 0;
      group.delta.abilities_fired[id] = (group.delta.abilities_fired[id] ?? 0) + end - start;
    }
  }
  for (const group of cells.values()) {
    for (const metric of Object.keys(metrics)) group.delta[metric] /= group.pairs;
    for (const id of Object.keys(group.delta.abilities_fired)) group.delta.abilities_fired[id] /= group.pairs;
    console.log('PAIRED ' + JSON.stringify(group));
  }
}

try {
  const args = process.argv.slice(2);
  if (args.length !== 2) throw new Error('Usage: node compare_trials.js <control log> <treatment log>');
  compare(readArm(args[0]), readArm(args[1]));
} catch (error) {
  console.error('Balance comparison: ' + error.message);
  process.exitCode = 1;
}
