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
const runOutcomes = ['won', 'lost', 'bot_concession', 'timeout', 'engine_error'];
const runMetrics = {
  win_pp: row => row.terminal_reason === 'won' ? 100 : 0,
  timeout_pp: metrics.timeout_pp,
  bot_concession_pp: metrics.bot_concession_pp,
  loss_s1_pp: row => row.terminal_reason === 'lost' && row.sector === 1 ? 100 : 0,
  loss_s2_pp: row => row.terminal_reason === 'lost' && row.sector === 2 ? 100 : 0,
  loss_s3_pp: row => row.terminal_reason === 'lost' && row.sector === 3 ? 100 : 0,
  battles_fought: row => row.battles_fought,
  boss_fights: row => row.boss_fights,
};

function cellKey({ faction, difficulty, cell }) {
  return [faction, difficulty, cell.mode, cell.sector, cell.kind, cell.column];
}

function runKey({ faction, difficulty, admiral }) {
  return [faction, difficulty, admiral];
}

function isText(value) {
  return typeof value === 'string' && value.length > 0;
}

function isCount(value) {
  return Number.isSafeInteger(value) && value >= 0;
}

function isCounts(value) {
  return value && typeof value === 'object' && !Array.isArray(value) && Object.values(value).every(isCount);
}

const formats = {
  TRIAL: {
    marker: 'TRIALS_COMPLETE',
    output: 'PAIRED',
    outcomes,
    metrics,
    maps: ['abilities_fired'],
    key: cellKey,
    group: cellKey,
    fields: ({ faction, difficulty, cell }) => ({ faction, difficulty, cell }),
    validKey: ({ cell }) => [cell?.mode, cell?.kind].every(isText) &&
      [cell.sector, cell.column].every(Number.isSafeInteger),
    validMetrics: row => [row.rounds, row.hull, row.lost].every(Number.isFinite),
  },
  RUN: {
    marker: 'RUNS_COMPLETE',
    output: 'PAIRED_RUN',
    outcomes: runOutcomes,
    metrics: runMetrics,
    maps: ['abilities_fired', 'shop_buys'],
    key: runKey,
    group: ({ faction, difficulty }) => [faction, difficulty],
    fields: ({ faction, difficulty }) => ({ faction, difficulty }),
    validKey: ({ admiral }) => isText(admiral),
    validMetrics: row => [1, 2, 3].includes(row.sector) &&
      [row.battles_fought, row.boss_fights].every(isCount) && row.boss_fights <= row.battles_fought &&
      ((row.boss_credits === null && row.boss_biomass === null) ||
        [row.boss_credits, row.boss_biomass].every(Number.isFinite)),
  },
};

function readArm(path) {
  const rows = new Map();
  let arm;
  let type;
  let expectedCount;
  const log = fs.readFileSync(path, 'utf8').replace(/^\uFEFF/, '');
  for (const [index, line] of log.split(/\r?\n/).entries()) {
    const prefix = `${path}:${index + 1}`;
    const token = /^(TRIAL|RUN)( |S_COMPLETE)/.exec(line);
    if (!token) {
      if (/^(SCRIPT ERROR:|Balance sim:)/.test(line)) throw new Error(`${prefix} ${line}`);
      continue;
    }
    type ??= token[1];
    if (type !== token[1]) throw new Error(`${prefix} mixed RUN and TRIAL records`);
    const format = formats[type];
    if (token[2] === 'S_COMPLETE') {
      if (expectedCount !== undefined) throw new Error(`${prefix} duplicate ${format.marker} marker`);
      const match = /^(?:RUNS|TRIALS)_COMPLETE ([1-9]\d*)$/.exec(line);
      expectedCount = Number(match?.[1]);
      if (!Number.isSafeInteger(expectedCount)) throw new Error(`${prefix} invalid ${format.marker} count`);
      continue;
    }
    if (expectedCount !== undefined) throw new Error(`${prefix} ${type} after ${format.marker} marker`);
    let row;
    try {
      row = JSON.parse(line.slice(type.length + 1));
    } catch (error) {
      throw new Error(`${prefix} invalid ${type} JSON: ${error.message}`);
    }
    if (!row || ![row.faction, row.difficulty, row.arm].every(isText) || !Number.isSafeInteger(row.seed) ||
        !format.validKey(row) || !format.outcomes.includes(row.terminal_reason)) {
      throw new Error(`${prefix} invalid ${type} key or terminal reason`);
    }
    const key = JSON.stringify([...format.key(row), row.seed]);
    if (row.terminal_reason === 'engine_error') throw new Error(`${prefix} engine error in ${type} ${key}`);
    if (!format.validMetrics(row) || !format.maps.every(field => isCounts(row[field]))) {
      throw new Error(`${prefix} invalid ${type} metrics`);
    }
    arm ??= row.arm;
    if (arm !== row.arm) throw new Error(`${prefix} expected arm ${arm}, got ${row.arm}`);
    if (rows.has(key)) throw new Error(`${prefix} duplicate ${type} key ${key}`);
    rows.set(key, row);
  }
  if (!type) throw new Error(`${path} missing TRIAL or RUN records and completion marker`);
  if (expectedCount === undefined) throw new Error(`${path} missing ${formats[type].marker} marker`);
  if (rows.size !== expectedCount) throw new Error(`${path} expected ${expectedCount} ${type} records, found ${rows.size}`);
  return { arm, rows, type };
}

function compare(control, treatment) {
  if (control.type !== treatment.type) throw new Error('Both logs must contain the same type of record.');
  const format = formats[control.type];
  for (const [from, to] of [[control, treatment], [treatment, control]]) {
    const missing = [...from.rows.keys()].filter(key => !to.rows.has(key));
    if (missing.length) {
      throw new Error(`${control.type} key sets differ: ${to.arm} is missing ${missing.length} key(s) from ${from.arm}, first ${missing[0]}`);
    }
  }
  if (control.arm === treatment.arm) throw new Error('Set a different SIM_ARM for each input.');

  const cells = new Map();
  for (const [key, before] of control.rows) {
    const after = treatment.rows.get(key);
    const groupKey = JSON.stringify(format.group(before));
    if (!cells.has(groupKey)) {
      const delta = Object.fromEntries(Object.keys(format.metrics).map(metric => [metric, 0]));
      for (const field of format.maps) delta[field] = Object.create(null);
      cells.set(groupKey, { ...format.fields(before), control: control.arm, treatment: treatment.arm, pairs: 0, delta });
    }
    const group = cells.get(groupKey);
    group.pairs++;
    for (const [metric, value] of Object.entries(format.metrics)) group.delta[metric] += value(after) - value(before);
    for (const field of format.maps) {
      const ids = new Set([...Object.keys(before[field]), ...Object.keys(after[field])]);
      for (const id of ids) {
        const start = Object.hasOwn(before[field], id) ? before[field][id] : 0;
        const end = Object.hasOwn(after[field], id) ? after[field][id] : 0;
        group.delta[field][id] = (group.delta[field][id] ?? 0) + end - start;
      }
    }
  }
  for (const group of cells.values()) {
    for (const metric of Object.keys(format.metrics)) group.delta[metric] /= group.pairs;
    for (const field of format.maps) {
      for (const id of Object.keys(group.delta[field])) group.delta[field][id] /= group.pairs;
    }
    console.log(format.output + ' ' + JSON.stringify(group));
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
