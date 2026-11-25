'use strict';
// Board chains wait for text, independently of the runner's checked-push wait.
const STARTING_GRACE_MS = 3 * 60000;
const fileStem = '(?:codex_chain_[a-z0-9_]+|codex_lane_[b-f][a-z0-9_]*|ds_[a-z0-9_]+|oa_[a-z0-9_]+)';
const filePattern = new RegExp('^'+fileStem+'\\.txt$', 'i');
const laneId = name => /^oa_/i.test(name) ? 'openai' : /^ds_/i.test(name) ? 'deepseek' : (name.match(/^codex_lane_([b-f])/i) || [0, 'main'])[1].toLowerCase();
function normalise(value) {
  const s = String(value || '').trim().toLowerCase();
  const name = s.split(/[\\/]/).at(-1);
  if (filePattern.test(name)) return name;
  if (filePattern.test(name+'.txt')) return name+'.txt';
  const old = /^(lane|chain)\s+([a-z0-9_]+)$/.exec(s);
  return old ? `codex_${old[1]}_${old[2]}.txt` : null;
}
function parseIssues(bat) {
  const found = [];
  for (const line of bat.split(/\r?\n/)) {
    if (/^\s*(rem\b|::)/i.test(line)) continue;
    const loop = /for\s+%%\w\s+in\s*\(([\d\s]+)\)\s+do\s+call\s+:one\s+%%\w/i.exec(line);
    if (loop) found.push(...loop[1].trim().split(/\s+/).map(Number));
    const direct = /\bcall\s+[^\r\n]*?(?:codex_issue|work_issue|RUN_RETRY)\.bat"?\s+([1-9]\d*)/i.exec(line);
    if (direct) found.push(+direct[1]);
  }
  return found.filter(n => Number.isSafeInteger(n) && n > 0);
}
function eventTime(line, anchor) {
  const clock = /\b(\d{1,2}):(\d{2})(?::(\d{2})(?:\.(\d+))?)?/.exec(line);
  if (!clock) return anchor;
  const date = /\b(\d{1,2})\/(\d{1,2})\/(\d{4})\b/.exec(line), d = new Date(anchor);
  if (date) d.setFullYear(+date[3], +date[1] - 1, +date[2]);
  const before = d.getTime();
  d.setHours(+clock[1], +clock[2], +(clock[3] || 0), Number((clock[4] || '').padEnd(3, '0').slice(0, 3)));
  if (!date && d.getTime() < before - 12 * 3600000) d.setDate(d.getDate() + 1);
  return d.getTime();
}
function parseChain({name, text = '', bat = '', mtime = 0, batMtime = 0, missingBat = false, unreadable = false}) {
  let current = null, lastIssue = null, currentAt = 0, startedAt = 0, endedAt = 0, cursor = 0, started = false, done = false, anchor = mtime, waitTarget = null;
  const issues = parseIssues(bat), lines = text.trim().split(/\r?\n/);
  const jobStarts = new Map(), jobEnds = new Map();
  for (const line of lines) {
    const wait = /^waiting for (.+?)(?:\s+from\b.*|\s+(?:\w+\s+)?\d{1,2}\/\d{1,2}\/\d{4}\b.*)?\s*$/i.exec(line);
    if (wait) waitTarget = normalise(wait[1]);
    if (/^(?:start|setup)\s/i.test(line)) { anchor = eventTime(line, anchor); if (/^start\s/i.test(line)) { started = true; startedAt ||= anchor; currentAt = anchor; } }
    const e = /^\s*(\d+)\s+(start|end)\s/i.exec(line);
    if (e) {
      anchor = eventTime(line, anchor);
      const index = issues.indexOf(+e[1], cursor);
      lastIssue = +e[1];
      if (e[2].toLowerCase() === 'start') {
        current = lastIssue; currentAt = anchor; started = true; startedAt ||= anchor;
        if (index >= 0) { cursor = index; jobStarts.set(index,anchor); }
      } else {
        current = null; endedAt = anchor;
        if (index >= 0) { cursor = index + 1; jobEnds.set(index,anchor); }
      }
    }
    if (/^all done\b/i.test(line)) { done = true; current = null; endedAt = eventTime(line, anchor); }
  }
  // Read literal targets on the two Board wait forms. Do not execute the script.
  const commands = bat.split(/\r?\n/).filter(line=>!/^\s*(?:rem\b|::)/i.test(line));
  const expressions = commands.flatMap(line => {
    const ps = /Select-String\b.*?-Path\s+(.+?)\s+-Pattern\b.*?["']all done["']/i.exec(line);
    const cmd = /\bfindstr\s+\/c:"all done"\s+("[^"]+"|\S+)/i.exec(line);
    return ps ? [{path:ps[1],source:'bat Select-String -Path'}] : cmd ? [{path:cmd[1],source:'bat findstr'}] : [];
  });
  const targets = [...new Set(expressions.flatMap(item =>
    [...item.path.matchAll(new RegExp(fileStem+'\\.txt\\b','gi'))].map(x=>x[0].toLowerCase())))];
  const last = lines.at(-1) || '';
  const terminal = /cancelled by the Board/i.test(last) ? 'cancelled' : /paused by the Board/i.test(last) ? 'paused' : /\bstopped\b/i.test(last) ? 'cancelled' : null;
  const supersededBy = normalise((/^superseded by (\S+\.txt)/im.exec(text) || [])[1]);
  const replaces = [...bat.matchAll(/^\s*(?:rem\b|::).*?\breplaces\s+(\S+\.txt)/gim)].map(m => normalise(m[1])).filter(Boolean);
  return {name: name.toLowerCase(), id: laneId(name), issues, current, lastIssue, currentAt, startedAt, endedAt, cursor, started, done, jobStarts, jobEnds,
    terminal, supersededBy, replaces, waitTargets: targets.length ? targets : waitTarget ? [waitTarget] : [],
    waitSource: targets.length ? [...new Set(expressions.map(item=>item.source))].join(' / ') : waitTarget ? 'waiting line' : null,
    mtime, batMtime, missingBat, unreadable};
}
function supersededExplicitly(c, chains) {
  return c.supersededBy || chains.find(n => n.id === c.id && n.batMtime > c.batMtime && n.replaces.includes(c.name) && n.issues.some(i => c.issues.includes(i)))?.name || null;
}
function resolveQueue(input, now, jobsEnded = () => false) {
  const chains = input.map(c => ({...c, state: null, reason: null, targets: [], predecessor: null, notes: []}));
  const latestStarts = new Map();
  for (const c of chains) {
    if (c.unreadable || !c.startedAt) continue;
    if (c.startedAt > (latestStarts.get(c.id)?.startedAt || 0)) latestStarts.set(c.id,c);
  }
  const visiting = [];
  function resolve(c) {
    if (c.state) return c.state;
    if (c.terminal) { c.state = c.terminal; return c.state; }
    if (c.done) { c.state = 'ended'; return c.state; }
    if (c.started) {
      const later = latestStarts.get(c.id);
      if (c.startedAt && later?.startedAt > Math.max(c.startedAt,c.currentAt)) {
        c.state = 'superseded'; c.reason = `later same-lane start in ${later.name}`;
      } else if (!c.unreadable && !c.missingBat && jobsEnded(c)) {
        c.state = 'ended'; c.reason = 'All listed jobs have ending evidence.';
      } else c.state = 'started';
      return c.state;
    }
    const replaced = supersededExplicitly(c, chains);
    if (replaced) { c.state = 'superseded'; c.reason = `superseded by ${replaced}`; return c.state; }
    const cycle = visiting.indexOf(c);
    if (cycle >= 0) {
      for (const item of visiting.slice(cycle)) { item.state = 'unknown'; item.reason = 'cycle'; }
      return c.state;
    }
    if (c.unreadable || c.missingBat) { c.state = 'unknown'; c.reason = c.unreadable ? 'source unreadable' : 'chain script missing'; return c.state; }
    const hits = chains.filter(t => c.waitTargets.includes(t.name));
    c.targets = hits.map(t => t.name);
    if (c.waitTargets.length > 1 || hits.length !== 1) {
      c.state = 'unknown'; c.reason = c.waitTargets.length > 1 || hits.length > 1 ? 'target ambiguous' :
        c.waitTargets.length ? 'target not found' : 'waiting target not recorded';
      return c.state;
    }
    visiting.push(c);
    const target = hits[0], state = resolve(target);
    visiting.pop();
    c.predecessor = target.name;
    c.predecessorIssue = target.issues.at(-1) || target.current || target.lastIssue;
    c.predecessorAt = Math.max(target.mtime, target.batMtime);
    if (c.state === 'unknown') return c.state;
    if (['started', 'linked', 'starting', 'stuck'].includes(state)) {
      c.state = 'linked';
      c.reason = state === 'stuck' || target.blockedByPredecessor ? 'predecessor is also blocked' : 'predecessor has no recorded ending';
      c.blockedByPredecessor = state === 'stuck' || target.blockedByPredecessor;
    }
    else if (state === 'ended' && target.done) {
      c.state = 'starting'; c.readyAt = target.endedAt;
      c.amber = !target.endedAt || now - target.endedAt > STARTING_GRACE_MS;
      c.reason = !target.endedAt ? 'predecessor ended at an unknown time; no start recorded' :
        c.amber ? `no start recorded ${Math.max(0, Math.floor((now - target.endedAt) / 60000))} min after its predecessor ended; the waiting window may be closed` :
          'predecessor ended; no start recorded yet';
    } else if (['cancelled', 'paused'].includes(state)) { c.state = 'stuck'; c.amber = true; c.reason = `waits on a ${state} chain`; }
    else if (['ended', 'superseded'].includes(state)) { c.state = 'unknown'; c.reason = 'predecessor has no recorded all done marker'; }
    else { c.state = 'unknown'; c.reason = state === 'unknown' && target.reason === 'cycle' ? 'cycle' : 'target state unknown'; }
    return c.state;
  }
  for (const c of chains) resolve(c);
  for (const c of chains.filter(x => ['linked', 'starting', 'stuck'].includes(x.state))) {
    const count = chains.filter(x => ['linked', 'starting', 'stuck'].includes(x.state) && x.targets[0] === c.targets[0]).length;
    if (count > 1) c.notes.push(`${count} chains share this predecessor; their order is unverified`);
  }
  return chains;
}
module.exports = {filePattern, laneId, normalise, parseIssues, eventTime, parseChain, resolveQueue, supersededExplicitly, STARTING_GRACE_MS};
